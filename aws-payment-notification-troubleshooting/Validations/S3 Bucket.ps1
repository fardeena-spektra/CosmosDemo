using namespace System.Net

param($Request, $TriggerMetadata)

Import-Module AWS.Tools.S3 -ErrorAction Stop

function Send-ValidationResponse {
    param(
        [ValidateSet('Succeeded', 'Failed')][string]$Status,
        [string]$Message
    )

    $body = @{ Status = $Status; Message = $Message } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers = @{ 'Content-Type' = 'application/json' }
        Body = $body
    })
}

$count = 0
$found = $false
$lastFailures = @()
$bucket = $null

# CloudLabs supplies $deploymentid and $region.
do {
    $count++
    $failures = [System.Collections.Generic.List[string]]::new()
    $bucket = $null

    try {
        $prefix = "pn-statements-$deploymentid-"
        $matches = @(Get-S3Bucket -Region $region -ErrorAction Stop | Where-Object { $_.BucketName -like "$prefix*" })
        if ($matches.Count -eq 0) {
            [void]$failures.Add("No deployment-specific statements bucket was found with prefix '$prefix'. Confirm deployment ID '$deploymentid' and AWS region '$region'.")
        }
        elseif ($matches.Count -gt 1) {
            [void]$failures.Add("Multiple buckets match '$prefix*'. The deployment must expose exactly one statements bucket; contact the lab administrator.")
        }
        else {
            $bucket = $matches[0].BucketName
        }
    }
    catch {
        [void]$failures.Add("Could not list S3 buckets in region '$region'. Check the validation role's S3 permissions and region. Details: $($_.Exception.Message)")
    }

    if ($null -ne $bucket) {
        try {
            $publicAccessResult = Get-S3PublicAccessBlock -BucketName $bucket -Region $region -ErrorAction Stop
            $config = if ($null -ne $publicAccessResult.PublicAccessBlockConfiguration) { $publicAccessResult.PublicAccessBlockConfiguration } else { $publicAccessResult }
            foreach ($name in @('BlockPublicAcls', 'IgnorePublicAcls', 'BlockPublicPolicy', 'RestrictPublicBuckets')) {
                if (-not [bool]$config.$name) {
                    [void]$failures.Add("Block Public Access setting '$name' is disabled on '$bucket'. Enable all four settings.")
                }
            }
        }
        catch {
            [void]$failures.Add("Block Public Access settings could not be read for '$bucket'. Enable all four settings and retry. Details: $($_.Exception.Message)")
        }

        try {
            $versioning = Get-S3BucketVersioning -BucketName $bucket -Region $region -ErrorAction Stop
            if ([string]$versioning.Status -ne 'Enabled') {
                [void]$failures.Add("Versioning on '$bucket' is '$($versioning.Status)'. Set bucket versioning to Enabled.")
            }
        }
        catch {
            [void]$failures.Add("Bucket versioning could not be read for '$bucket'. Enable versioning and retry. Details: $($_.Exception.Message)")
        }

        try {
            $policyResult = Get-S3BucketPolicy -BucketName $bucket -Region $region -ErrorAction Stop
            $policyText = if ($policyResult -is [string]) { $policyResult } elseif ($null -ne $policyResult.Policy) { [string]$policyResult.Policy } else { [string]($policyResult | ConvertTo-Json -Depth 20) }
            $policy = ([uri]::UnescapeDataString($policyText)) | ConvertFrom-Json -ErrorAction Stop
            foreach ($statement in @($policy.Statement)) {
                $actions = @($statement.Action | ForEach-Object { [string]$_ })
                $deniesPut = ([string]$statement.Effect -ieq 'Deny') -and (($actions -contains '*') -or ($actions -contains 's3:PutObject'))
                if ($deniesPut -or [string]$statement.Sid -ieq 'FreezeStatementUploads') {
                    [void]$failures.Add("Policy statement '$($statement.Sid)' still denies s3:PutObject. Delete the bucket policy, including FreezeStatementUploads.")
                }
            }
        }
        catch {
            $errorCode = [string]$_.Exception.ErrorCode
            if ($errorCode -notmatch 'NoSuchBucketPolicy|NoSuchBucketPolicyException|NoSuchPolicy') {
                [void]$failures.Add("Bucket '$bucket' still has a policy that cannot be inspected. Delete the bucket policy so no s3:PutObject deny remains. Details: $($_.Exception.Message)")
            }
        }

        try {
            $statementObject = Get-S3Object -BucketName $bucket -Key 'statements/test-statement.txt' -Region $region -ErrorAction Stop
            if ($null -eq $statementObject) {
                [void]$failures.Add("Object 'statements/test-statement.txt' is missing from '$bucket'. Upload test-statement.txt under the statements folder.")
            }
        }
        catch {
            [void]$failures.Add("Object 'statements/test-statement.txt' is missing from '$bucket'. Create the statements folder and upload the file with that exact key.")
        }
    }

    $lastFailures = @($failures)
    if ($lastFailures.Count -eq 0) {
        $found = $true
    }
    elseif (-not $found -and $count -lt 3) {
        Start-Sleep -Seconds 10
    }
} while ($count -lt 3 -and -not $found)

if ($found) {
    $successMessage = "Validation 1 passed: '$bucket' has all four Block Public Access settings enabled, versioning Enabled, no s3:PutObject deny policy, and object 'statements/test-statement.txt'."
    $responseBody = @{ Status = "Succeeded"; Message = $successMessage } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Headers = @{ 'Content-Type' = 'application/json' }; Body = $responseBody })
}
else {
    $failureMessage = "Validation 1 failed after $count attempt(s):`n- " + ($lastFailures -join "`n- ")
    $responseBody = @{ Status = "Failed"; Message = $failureMessage } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Headers = @{ 'Content-Type' = 'application/json' }; Body = $responseBody })
}
