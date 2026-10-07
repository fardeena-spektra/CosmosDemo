using namespace System.Net

param($Request, $TriggerMetadata)

Import-Module AWS.Tools.Common
Import-Module AWS.Tools.Lambda
Import-Module AWS.Tools.S3
Import-Module AWS.Tools.IdentityManagement
Import-Module AWS.Tools.SecurityToken

$DID = $deploymentid
$awsRegion = if ([string]::IsNullOrWhiteSpace($region)) { 'us-east-1' } else { $region }
$sub = (Get-STSCallerIdentity -Region $awsRegion -ErrorAction SilentlyContinue).Account

function Add-Check {
    param(
        [System.Collections.Generic.List[string]]$Checks,
        [System.Collections.Generic.List[string]]$Fixes,
        [bool]$Passed,
        [string]$Check,
        [string]$Fix
    )
    if ($Passed) { [void]$Checks.Add($Check) }
    else { [void]$Fixes.Add($Fix) }
}

$count = 0
$found = $false
$checksPassed = 0
$totalChecks = 5
$fixes = @()

do {
    $count++
    $checks = [System.Collections.Generic.List[string]]::new()
    $fixes = [System.Collections.Generic.List[string]]::new()
    $functionName = "pn-notify-$DID"
    $bucketName = $null

    try {
        $accountId = (Get-STSCallerIdentity -Region $awsRegion -ErrorAction Stop).Account
        $sub = $accountId
        $bucketName = "pn-statements-$DID-$accountId"
        $configuration = Get-LMFunctionConfiguration -FunctionName $functionName -Region $awsRegion -ErrorAction Stop

        Add-Check $checks $fixes ($configuration.Handler -eq 'index.lambda_handler') 'Handler is index.lambda_handler.' 'Set the Lambda handler to index.lambda_handler.'

        $configuredBucket = $null
        if ($null -ne $configuration.Environment -and $null -ne $configuration.Environment.Variables) {
            $configuredBucket = $configuration.Environment.Variables['BUCKET_NAME']
        }
        Add-Check $checks $fixes ($configuredBucket -eq $bucketName) "BUCKET_NAME is $bucketName." "Set BUCKET_NAME to $bucketName."

        $roleName = ([System.Uri]$configuration.Role).Segments[-1]
        $permissionFound = $false
        $policyNames = @(Get-IAMRolePolicyList -RoleName $roleName -Region $awsRegion -ErrorAction Stop).PolicyNames
        foreach ($policyName in $policyNames) {
            $rolePolicy = Get-IAMRolePolicy -RoleName $roleName -PolicyName $policyName -Region $awsRegion -ErrorAction Stop
            $documentText = [System.Uri]::UnescapeDataString([string]$rolePolicy.PolicyDocument)
            $document = $documentText | ConvertFrom-Json
            foreach ($statement in @($document.Statement)) {
                $actions = @($statement.Action | ForEach-Object { [string]$_ })
                $resources = @($statement.Resource | ForEach-Object { [string]$_ })
                $actionMatches = $actions -contains 's3:PutObject' -or $actions -contains 's3:*' -or $actions -contains '*'
                $objectArn = "arn:aws:s3:::$bucketName/notifications/latest.json"
                $resourceMatches = $resources -contains $objectArn -or $resources -contains "arn:aws:s3:::$bucketName/notifications/*" -or $resources -contains "arn:aws:s3:::$bucketName/*" -or $resources -contains '*'
                if ([string]$statement.Effect -eq 'Allow' -and $actionMatches -and $resourceMatches) { $permissionFound = $true }
            }
        }
        Add-Check $checks $fixes $permissionFound "Role $roleName allows s3:PutObject for notifications/latest.json." "Add an Allow s3:PutObject permission for arn:aws:s3:::$bucketName/notifications/* to role $roleName."

        $payload = [System.Text.Encoding]::UTF8.GetBytes('{"customer":"validator-customer"}')
        $invokeResult = Invoke-LMFunction -FunctionName $functionName -InvocationType RequestResponse -Payload $payload -Region $awsRegion -ErrorAction Stop
        $invocationPassed = ([int]$invokeResult.StatusCode -eq 200 -and $null -eq $invokeResult.FunctionError)
        Add-Check $checks $fixes $invocationPassed 'Invocation returned HTTP 200 without a function error.' "Invoke $functionName successfully after correcting the handler, bucket, and role permission."

        $notification = Get-S3Object -BucketName $bucketName -Key 'notifications/latest.json' -Region $awsRegion -ErrorAction SilentlyContinue
        Add-Check $checks $fixes ($null -ne $notification) "notifications/latest.json exists in $bucketName." "Run the function successfully and verify notifications/latest.json exists in $bucketName."
    }
    catch {
        [void]$fixes.Add("Resolve the Lambda configuration and complete all five checks. Details: $($_.Exception.Message)")
    }

    $checksPassed = $checks.Count
    if ($checksPassed -eq $totalChecks) { $found = $true }
    elseif (-not $found -and $count -lt 3) { Start-Sleep -Seconds 10 }
} while ($count -lt 3 -and -not $found)

if ($found) {
    $responseBody = @{ Status = "Succeeded"; Message = "$checksPassed of $totalChecks checks passed." } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Headers = @{ 'Content-Type' = 'application/json' }; Body = $responseBody })
}
else {
    $responseBody = @{ Status = "Failed"; Message = "$checksPassed of $totalChecks checks passed. To fix:`n- $($fixes -join "`n- ")" } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Headers = @{ 'Content-Type' = 'application/json' }; Body = $responseBody })
}
