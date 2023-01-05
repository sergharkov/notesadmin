$Sub='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
az account set --subscription $Sub
########################################################

function Get-AzADApplicationsSecrets {
    $azADApplications = Get-AzADApplication
    if (-not $azADApplications) {
        Write-Warning "No Azure AD Applications found."
        return $null
    }
    Write-Warning "Azure AD Applications found."
    $allAzADApplicationsSecrets = New-Object -TypeName System.Collections.Generic.List[PSCustomObject]
    foreach ($adApp in $azADApplications) {
        foreach ($keyCred in $adApp.KeyCredentials) {
            $keySecretObject = New-SecretCredentialObject -AzADApplication $adApp -Secret $keyCred
            $allAzADApplicationsSecrets.Add($keySecretObject)
        }
        foreach ($passwordCred in $adApp.PasswordCredentials) {
            $passwordSecretObject = New-SecretCredentialObject -AzADApplication $adApp -Secret $passwordCred
            $allAzADApplicationsSecrets.Add($passwordSecretObject)
        }
    }
    return $allAzADApplicationsSecrets
}

# workaround for Powershell 5 since ConvertTo-Json works differently for DateTime than in Powershell 7
function Convert-SecretEndDateTimePropertyToString {
    param (
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[PSCustomObject]] $NearToExpiredSecretsList
    )
    foreach ($secret in $NearToExpiredSecretsList) {
        $secret.SecretEndDateTime = $secret.SecretEndDateTime.DateTime
    }
}

$allApplicationsSecretsList = Get-AzADApplicationsSecrets
$expireCandidateSecrets = Find-AboutToExpiredAzADApplicationsSecrets -AzADApplicationSecretsList $allApplicationsSecretsList
$closeToExpiredApplicationsSecretsList = $expireCandidateSecrets.CloseToExpiredSecretsList
$nearToExpiredSecretsList = New-Object -TypeName System.Collections.Generic.List[PSCustomObject]

if ($closeToExpiredApplicationsSecretsList) {
    Write-Output "Sending Pager Duty alert(s) with close-to-expired (within 5 days) secrets information..."
    Convert-SecretEndDateTimePropertyToString -NearToExpiredSecretsList $closeToExpiredApplicationsSecretsList

    Write-Output $closeToExpiredApplicationsSecretsList | Select-Object ApplicationDisplayName, SecretEndDateTime | Format-Table

    foreach ($secret in $closeToExpiredApplicationsSecretsList) {
        $pagerDutyMessage += $secret | Select-Object ApplicationDisplayName, SecretEndDateTime | Format-Table # | ConvertTo-Json
   }

Write-Output $pagerDutyMessageTotal # | ConvertTo-Json
 #       Send-PagerDutyAlert -SeverityMessageText "warning" -BodyMessageText $pagerDutyMessage -SummaryMessageText "Close-to-expired (within 5 days) secrets has been found"
#Start-sleep -Seconds 5
    Write-Output "alert(s) with close-to-expired (within 5 days) secrets information has(ve) been sent."

} else {
    Write-Output "No close-to-expired (within 5 days) secrets has been found. Sending a corresponding alert..."
}
