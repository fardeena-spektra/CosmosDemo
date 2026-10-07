using namespace System.Net

param($Request, $TriggerMetadata)

Import-Module AWS.Tools.Common
Import-Module AWS.Tools.Lambda
Import-Module AWS.Tools.S3
Import-Module AWS.Tools.IdentityManagement
Import-Module AWS.Tools.SecurityToken

# CloudLabs supplies these values. Keep the aliases for reference-style validators.
$DID = $deploymentid
$awsRegion = $region
$functionName = "pn-notify-$DID"

function New-ValidatorResponse {
    param([string]$Status, [string]$Message)
    if ($Status -eq 'Succeeded') {
        $body = @{ Status = "Succeeded"; Message = $Message } | ConvertTo-Json -Compress
    }
    else {
        $body = @{ Status = "Failed"; Message = $Message } | ConvertTo-Json -Compress
    }
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $body
        Headers = @{ 'Content-Type' = 'application/json' }
    })
}

function Get-PolicyStatements {
    param([string]$RoleName, [string]$PolicyName)
    $rolePolicy = Get-IAMRolePolicy -RoleName $RoleName -PolicyName $PolicyName -Region $awsRegion -ErrorAction Stop
    $documentText = [System.Uri]::UnescapeDataString([string]$rolePolicy.PolicyDocument)
    $document = $documentText | ConvertFrom-Json
    if ($null -eq $document.Statement) { return @() }
    return @($document.Statement)
}

$count = 0
$found = $false
$failureMessage = "Validation did not complete."
do {
    $count++
    try {
        $accountId = (Get-STSCallerIdentity -Region $awsRegion -ErrorAction Stop).Account
        # $sub is retained as the account context used by this AWS validator.
        $sub = $accountId
        $bucketName = "pn-statements-$DID-$accountId"
        $configuration = Get-LMFunctionConfiguration -FunctionName $functionName -Region $awsRegion -ErrorAction Stop
    }
    catch {
        $failureMessage = "Lambda function '$functionName' or its deployment account could not be resolved in region '$awsRegion'. Confirm the injected deployment ID and region. Details: $($_.Exception.Message)"
        if ($count -lt 3) { Start-Sleep -Seconds 10 }
        continue
    }

    if ($configuration.Handler -ne 'index.lambda_handler') {
        $failureMessage = "Handler check failed: '$functionName' uses '$($configuration.Handler)'; change Runtime settings > Handler to index.lambda_handler and save."
        break
    }

    $configuredBucket = $null
    if ($null -ne $configuration.Environment -and $null -ne $configuration.Environment.Variables) {
        $configuredBucket = $configuration.Environment.Variables['BUCKET_NAME']
    }
    if ($configuredBucket -ne $bucketName) {
        $failureMessage = "BUCKET_NAME is '$configuredBucket', but the deployment bucket is '$bucketName'. Set the Lambda environment variable to the StatementsBucket value."
        break
    }

    $roleName = ([System.Uri]$configuration.Role).Segments[-1]
    $permissionFound = $false
    try {
        $policyNames = @(Get-IAMRolePolicyList -RoleName $roleName -Region $awsRegion -ErrorAction Stop).PolicyNames
        foreach ($policyName in $policyNames) {
            foreach ($statement in @(Get-PolicyStatements -RoleName $roleName -PolicyName $policyName)) {
                $actions = @($statement.Action)
                $resources = @($statement.Resource)
                $actionMatches = ($actions -contains 's3:PutObject' -or $actions -contains 's3:*' -or $actions -contains '*')
                $objectArn = "arn:aws:s3:::$bucketName/notifications/latest.json"
                $resourceMatches = ($resources -contains $objectArn -or $resources -contains "arn:aws:s3:::$bucketName/notifications/*" -or $resources -contains "arn:aws:s3:::$bucketName/*" -or $resources -contains '*')
                if ([string]$statement.Effect -eq 'Allow' -and $actionMatches -and $resourceMatches) { $permissionFound = $true }
            }
        }
    }
    catch {
        $failureMessage = "Could not inspect inline policies on Lambda role '$roleName'. Confirm an Allow s3:PutObject permission for notifications/latest.json. Details: $($_.Exception.Message)"
        break
    }
    if (-not $permissionFound) {
        $failureMessage = "Role '$roleName' lacks an Allow s3:PutObject permission for 'arn:aws:s3:::$bucketName/notifications/latest.json'. Add the pn-notify-s3-write inline policy for notifications/*."
        break
    }

    try {
        $payload = [System.Text.Encoding]::UTF8.GetBytes('{"customer":"validator-customer"}')
        $invokeResult = Invoke-LMFunction -FunctionName $functionName -InvocationType RequestResponse -Payload $payload -Region $awsRegion -ErrorAction Stop
        if ([int]$invokeResult.StatusCode -ne 200 -or $null -ne $invokeResult.FunctionError) {
            $failureMessage = "Invocation of '$functionName' did not succeed: HTTP status $($invokeResult.StatusCode), FunctionError '$($invokeResult.FunctionError)'. Review the Lambda test result and CloudWatch logs."
            break
        }
    }
    catch {
        $failureMessage = "Invocation of '$functionName' failed. Confirm the handler, BUCKET_NAME, and S3 role permission, then invoke again. Details: $($_.Exception.Message)"
        break
    }

    try {
        $notification = Get-S3Object -BucketName $bucketName -Key 'notifications/latest.json' -Region $awsRegion -ErrorAction Stop
        if ($null -eq $notification) { throw 'object was not returned' }
    }
    catch {
        $failureMessage = "Invocation returned HTTP 200, but s3://$bucketName/notifications/latest.json was not found. Confirm the function writes that exact key. Details: $($_.Exception.Message)"
        break
    }

    $found = $true
    New-ValidatorResponse -Status 'Succeeded' -Message "Lambda '$functionName' is repaired: handler index.lambda_handler, BUCKET_NAME '$bucketName', role '$roleName' allows s3:PutObject for notifications/latest.json, invocation returned HTTP 200, and the notification object exists."
} while ($count -lt 3 -and -not $found)

if (-not $found) {
    New-ValidatorResponse -Status 'Failed' -Message $failureMessage
}
