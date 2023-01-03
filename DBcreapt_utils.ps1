function utils-printLog {
    param (
        [ValidateSet("Info", "OK", "Warning", "Error")]
        [string] $status = "Error",
        [string] $text
    )

    $timestamp = Get-Date -UFormat %H:%M:%S
    Write-Host "$timestamp " -NoNewline
    switch ($status) {
        'Info' { Write-Host "[Info] " -NoNewline -ForegroundColor Cyan }
        'OK' { Write-Host "[ OK ] " -NoNewline -ForegroundColor Green }
        'Warning' { Write-Host "[Warning] " -NoNewline -ForegroundColor Yellow }
        'Error' { Write-Host "[ Error ] " -NoNewline -ForegroundColor Red }
    }
    Write-Host $text
}

function utils-collectEnviromentParameters {
    param ( 
        [Parameter(Mandatory = $True)]  [string] $enviromentsFilePath
    )

    utils-printLog 'Warning' "resourceGroup and/or SubscriptionId wheren't provided directly"
    utils-printLog 'Info' "Collecting Enviroment parameters from $enviromentsFilePath file"

    $enviromentsFile = Import-Excel $enviromentsFilePath
    $enviromentData = $enviromentsFile | Where-Object { ($_.Client -eq $client) -and ($_.Application -eq $application) -and ($_.Environment -eq $enviroment) }
    if (!$enviromentData) {
        utils-printLog 'Error' "There are no records in Enviroments.xlsx for Client: $client Application: $application Environment: $enviroment"
        utils-printLog 'Error' "Stop processing"
        exit
    }
    else {
        switch (($enviromentData.gettype()).BaseType.Name) {
            'Array' {
                utils-printLog 'Error' "More than one records was found in $enviromentsFilePath file for Client: $client Application: $application Environment: $enviroment"
                utils-printLog 'Error' "Stop processing"
                exit
            }
            'Object' {
                utils-printLog 'OK' "Next parameters will be used for deployment:"
                return $enviromentData
            }
        }
    }
}

function utils-createSite24Monitor {
    param ( 
        $monitorName,
        $Headers,
        $tamplateData
    )

    try {
        $monitorId = (Invoke-RestMethod -Uri "https://www.site24x7.eu/api/monitors/name/$monitorName" `
                -Method Get `
                -Headers $Headers `
                -ErrorAction SilentlyContinue `
        ).data.monitor_id
    }
    catch { utils-printLog 'Info' "New Monitor should be created" }

    if ($monitorId) {
        Invoke-RestMethod -Uri "https://www.site24x7.eu/api/monitors/$monitorId" `
            -Method Put `
            -Headers $Headers `
            -Body ($tamplateData | ConvertTo-Json) `
        | Out-Null
        utils-printLog 'OK' "Existing Monitor has been updated"
    }
    else {
        Invoke-RestMethod -Uri "https://www.site24x7.eu/api/monitors" `
            -Method Post `
            -Headers $Headers `
            -Body ($tamplateData | ConvertTo-Json) `
        | Out-Null
        utils-printLog 'OK' "New Monitor has been created"
    }
}

function utils-createDiskEncryptionSet ($diskEncryptionSetName, $keyVaultName, $key) {

    utils-printLog 'Info' "Creating a new diskEncryptionSet using a custom key"

    $desConfig = New-AzDiskEncryptionSetConfig -Location $environmentParams.location -SourceVaultId $keyVaultName.ResourceId -KeyUrl $key.Key.Kid -IdentityType SystemAssigned
    $des = New-AzDiskEncryptionSet -Name $diskEncryptionSetName -ResourceGroupName $environmentParams.resourceGroupName -InputObject $desConfig
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName.VaultName -ObjectId $des.Identity.PrincipalId -PermissionsToKeys wrapkey, unwrapkey, get
    $customDiskEncryptionSetID = $des.Id

    return $customDiskEncryptionSetID
}

function utils-CreateKeyVaultSecret ($keyVaultName, $keyVaultSubscriptionId, $secretName, $secretValue, $secretIsProtected) {
    $currentSubscriptionId = (Get-AzContext).Subscription.id

    utils-SwitchSubscriptions $currentSubscriptionId $keyVaultSubscriptionId
        
    $secretNewValue = ConvertTo-SecureString -String $secretValue -AsPlainText -Force
    $secretCurrentValue = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -AsPlainText -ErrorAction SilentlyContinue)
        
    switch ($secretIsProtected) {
        $true { $secretContentType = '**********' }
        $false { $secretContentType = $secretValue }
    }

    if ($secretValue -ne $secretCurrentValue) {
        utils-printLog 'Info' "Adding or replacing [$secretName] secret in KeyVault $keyVaultName"
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretNewValue -ContentType $secretContentType | Out-Null
    }
    else {
        utils-printLog 'Info' "[$secretName] secret already exist with the same value in KeyVault $keyVaultName"
    }

    utils-SwitchSubscriptions $currentSubscriptionId $keyVaultSubscriptionId -SwitchBack
}


function Get-KeyVaultAccessPolicies ($keyVaultName) {
    $AccessPolicies = (Get-AzKeyVault -VaultName $keyVaultName).accessPolicies
    $ArmAccessPolicies = @{
        "list" = @()
    }

    if ($AccessPolicies) {
        foreach ($AccessPolicy in $AccessPolicies) {
            $ArmAccessPolicy = @{
                "tenantId"    = $AccessPolicy.TenantId
                "objectId"    = $AccessPolicy.objectId
                "permissions" = @{
                    "keys"         = $AccessPolicy.PermissionsToKeys
                    "secrets"      = $AccessPolicy.PermissionsToSecrets
                    "certificates" = $AccessPolicy.PermissionsToCertificates
                    "storage"      = $AccessPolicy.PermissionsToStorage
                }
            }
            $ArmAccessPolicies["list"] += $ArmAccessPolicy
        }
    }
    else {
        $ArmAccessPolicy = @(@{
                "tenantId"    = (Get-AzSubscription -SubscriptionId $SubscriptionId).TenantId
                #"objectId" = '73e6bef5-ded9-4158-ac36-f26421e96d68' ` # [RG] DevOps LinkPoint
                "objectId"    = '1f1c3fcb-6eb7-4498-8ad6-d0c4147d3d2e' ` # [RG] DevOps Invisible
                "permissions" = @{
                    "keys"         = @("encrypt", "decrypt", "wrapKey", "unwrapKey", "sign", "verify", "get", "list", "create", "update", "import", "delete", "backup", "restore", "recover", "purge")
                    "secrets"      = @("get", "list", "set", "delete", "backup", "restore", "recover", "purge")
                    "certificates" = @("get", "list", "delete", "create", "import", "update", "managecontacts", "getissuers", "listissuers", "setissuers", "deleteissuers", "manageissuers", "recover", "purge", "backup", "restore")
                    "storage"      = @("get", "list", "delete", "set", "update", "regeneratekey", "recover", "purge", "backup", "restore", "setsas", "listsas", "getsas", "deletesas")
                }
            }
            #            ,@{
            #                "tenantId" = (Get-AzSubscription -SubscriptionId $SubscriptionId).TenantId
            #                "objectId" = 'd50ecb97-9743-4077-980d-6a95e4b27621' ` # TeamCity-Deployment
            #                "permissions" = @{
            #                    "keys" = @()
            #                    "secrets" = @("get","list")
            #                    "certificates" = @("get","list")
            #                    "storage" = @()
            #                }
            #            }
        )
        $ArmAccessPolicies["list"] += $ArmAccessPolicy
    }

    return $ArmAccessPolicies
}

function utils-CreateKeyVaultCertificate ($product, $client, $environment, $keyVaultName, $CertificateSuffix) {
    if ($keyVaultName -like "*-DR") {
        utils-printLog 'Info' "Skipping secret creation for DR environment."
    }
    else {
        $CertificateName = "$product-$client-$environment-$CertificateSuffix"
        
        utils-printLog 'Info' "Verifying that the certificate with name $CertificateName already exist in Key Vault $keyVaultName"
        $CertificateThumbprint = (Get-AzKeyVaultCertificate -VaultName $keyVaultName -Name $CertificateName).Thumbprint


        if (!$CertificateThumbprint) {
            utils-printLog 'Info' "Certificate doesn't exist, creating the new one"
            $CertificatePolicy = New-AzKeyVaultCertificatePolicy `
                -SubjectName "CN=$CertificateName" `
                -KeyUsage 16, 128 `
                -Ekus "1.3.6.1.5.5.7.3.2", "1.3.6.1.5.5.7.3.1" `
                -ValidityInMonths 1200 `
                -KeySize 2048 `
                -IssuerName Self `
                -SecretContentType "application/x-pkcs12"

            $CertResult = Add-AzKeyVaultCertificate -VaultName $keyVaultName -Name $CertificateName -CertificatePolicy $CertificatePolicy
            while ($CertResult.Status -ne "completed") {
                Start-Sleep -Seconds 3
                $CertResult = Get-AzKeyVaultCertificateOperation -VaultName $KeyVaultName -Name $CertificateName
            }
            $CertificateThumbprint = (Get-AzKeyVaultCertificate -VaultName $keyVaultName -Name $CertificateName).Thumbprint                       
        }

        utils-CreateKeyVaultSecret $keyVaultName $keyVaultSubscriptionId "Sync$($CertificateSuffix)CertificateThumbprint" $CertificateThumbprint $false
    }
}

function utils-AddVMSSCertificate($CertificateName, $KeyVault, $VMSS) {
    $KeyVaultCertificate = Get-AzKeyVaultCertificate -VaultName $environmentParams.keyVaultName -Name $CertificateName
    $SourceVaultAlreadyExist = $false
    $CertificateAlreadyExist = $false
    $VMSS.VirtualMachineProfile.OsProfile.Secrets | ForEach-Object {
        if ($_.SourceVault.Id -eq $KeyVault.ResourceId) {
            $SourceVaultAlreadyExist = $true
            $SourceVaultId = $VMSS.VirtualMachineProfile.OsProfile.Secrets.IndexOf($_)

            $_.VaultCertificates | ForEach-Object {
                if ($_.CertificateUrl -eq $KeyVaultCertificate.SecretId) {
                    $CertificateAlreadyExist = $true
                }
            }

            if (!$CertificateAlreadyExist) {
                $Certificate = New-Object Microsoft.Azure.Management.Compute.Models.VaultCertificate
                $Certificate.CertificateStore = "My"
                $Certificate.CertificateUrl = $KeyVaultCertificate.SecretId
                $VMSS.VirtualMachineProfile.OsProfile.Secrets[$SourceVaultId].VaultCertificates.Add($Certificate)
            }
        }
    }

    if (!$SourceVaultAlreadyExist -and !$CertificateAlreadyExist) {
        $Secrets = New-Object System.Collections.Generic.List[Microsoft.Azure.Management.Compute.Models.VaultSecretGroup]
        $Secret = New-Object Microsoft.Azure.Management.Compute.Models.VaultSecretGroup
        $Secret.SourceVault = $KeyVault.ResourceId
        $Certificates = New-Object System.Collections.Generic.List[Microsoft.Azure.Management.Compute.Models.VaultCertificate]
        $Certificate = New-Object Microsoft.Azure.Management.Compute.Models.VaultCertificate
        $Certificate.CertificateStore = "My"
        $Certificate.CertificateUrl = $KeyVaultCertificate.SecretId
        $Certificates.Add($Certificate)
        $Secret.VaultCertificates = $Certificates
        $Secrets.Add($Secret)
        $VMSS.VirtualMachineProfile.OsProfile.Secrets = $Secrets
    }
    $VMSS | Update-AzVmss | Out-Null
}

function utils-CreateKeyVaultKey {
    param (
        [Parameter(Mandatory = $true)][String]$KeyName,
        [Parameter(Mandatory = $true)][String]$KeyVaultName
    )

    if ($KeyVaultName -like "*-DR") {
        utils-printLog 'Info' "Skipping TDE key creation for DR environment."
    }
    else {
        $keyObject = Get-AzKeyVaultKey -VaultName $keyVaultName -Name $keyName

        if (!$keyObject) {
            utils-printLog 'Info' "[$keyName] key doesn't exist, creating the new one"
            $keyObject = Add-AzKeyVaultKey `
                -VaultName $keyVaultName `
                -Name $keyName `
                -Destination "Software" `
                -Size 2048 `
                -KeyOps @("encrypt", "decrypt", "wrapKey", "unwrapKey", "sign", "verify") `
                
            if ($keyObject) {
                utils-printLog 'Info' "[$($keyObject.Name)] key has been created."
            }
            else {
                utils-printLog 'Warning' "[$keyName] key hasn't been created."
            }     
        }
        else {
            utils-printLog 'Info' "[$keyName] key already exist."
        }
        return $keyObject
    }
}

# Function will generate a password using a-z,A-Z,0-9 characters. Password length 20. It also validates that there is at least one digit, one lower- and uppercase characters
function utils-PasswordGenerator {
    do {
        $randompassword = -join (48..57 + 65..90 + 97..122 | ForEach-Object { [char]$_ } | Get-Random -Count 20)
    }
    until ($randompassword -cmatch '(\d+[A-Z]+[a-z]+)')
    return $randompassword
}

function utils-GuidGenerator {
    $guid = (New-Guid).Guid
    return $guid
}

function utils-JWTGenerator {
    $RSA = "$env:USERPROFILE/.ssh/id_rsa_for_private_jwt"
    ssh-keygen -b 2048 -t rsa -f $RSA -q -N '""'
    $RSA = ((Get-Content -Path $RSA -Raw) -split "(\r*\n){2,}") -replace '\r*\n', '' -replace '-----BEGIN OPENSSH PRIVATE KEY-----' -replace '-----END OPENSSH PRIVATE KEY-----'
    return $RSA
}

function utils-CreatePassword ($keyVaultName, $keyVaultSubscriptionId, $secretName, $propertyName) {

    if (!$environmentParams.$propertyName) {
        if (!(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "$secretName")) {            
            utils-printLog 'Info' "[$secretName] secret does not exist in $keyVaultName. New one will be generated."         
            $environmentParams | Add-Member -NotePropertyName $propertyName -NotePropertyValue (utils-PasswordGenerator) | Out-Null
            utils-CreateKeyVaultSecret $keyVaultName $keyVaultSubscriptionId $secretName $environmentParams.$propertyName $true       
        }
        else {
            utils-printLog 'Info' "[$secretName] already exists in $keyVaultName. No action taken."
            $environmentParams | Add-Member -NotePropertyName $propertyName -NotePropertyValue (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "$secretName" -AsPlainText) | Out-Null
        }
    }
    else {
        utils-printLog 'Info' "[$propertyName] will be used from config file: $($environmentParams.$propertyName)"
    }    
}

function utils-CheckAzModule {
    $targetVersion = "6.3.0"
    $currentVersion = (Get-InstalledModule Az).Version
    if ([version]$currentVersion -lt [version]"$targetVersion") {
        Write-Host "##### Updating/Installing Az module version to $targetVersion #####"
        Update-Module -Name Az -RequiredVersion "$targetVersion" -Force
    }
    else {
        $targetVersion = $currentVersion.ToString()
    }
    Write-Host "##### Import Az module version $targetVersion #####"
    Import-Module -Name Az -RequiredVersion $targetVersion -Force
}

function utils-CreatePoolSqlServerPassword {
    param(
        [string]$propertyName
    )
    $pool = $(utils-GetElasticPoolConfiguration $environmentParams).Primary

    utils-SwitchSubscriptions $environmentParams.subscriptionId $pool.subscriptionId
    if (!(Get-AzKeyVault -VaultName $pool.keyVaultName)) {
        $environmentParams | Add-Member -NotePropertyName $propertyName -NotePropertyValue (utils-PasswordGenerator) | Out-Null
    }
    else {
        $environmentParams | Add-Member -NotePropertyName $propertyName -NotePropertyValue (Get-AzKeyVaultSecret -VaultName $pool.keyVaultName -Name $pool.keyVaultSecretName -AsPlainText) | Out-Null
    }
    utils-SwitchSubscriptions $environmentParams.subscriptionId $pool.subscriptionId -SwitchBack
}

function utils-GetElasticPoolConfiguration {
    param (
        [PSCustomObject]$environmentParams,
        [string]$elasticPoolName = $environmentParams.elasticPoolName,
        [string]$location = $environmentParams.location
    )

    process {
        $config = $(Get-Content "$PSScriptRoot\..\ElasticPool\ElasticPool_ConfigGlobal.json" | ConvertFrom-Json).$elasticPoolName
        switch ($config.Count) {
            0 { throw "An elsatic pool configuration has not been found <elasticPoolName>:$($elasticPoolName)" }
            1 { 
                $primary = $config[0]
                $secondary = $null
                $fog = $primary
            }
            2 {
                $primary = $config | Where-Object { $_.location -eq $location }
                $secondary = $config | Where-Object { $_.location -ne $location }
                $fog = "$($environmentParams.product)-$($environmentParams.client)-$($environmentParams.environment)".ToLower()
            }
            Default {
                utils-printLog 'Error' "Elastic pools with more than two locations are not supported"
            }
        }
    }

    end {
        Write-Output @{
            Primary   = $primary
            Secondary = $secondary
            All       = @(@($primary, $secondary) | Where-Object { $_ })
            Fog       = $fog
        }
    }
}

function utils-SwitchSubscriptions {
    param (
        [string]$deploymentSubscriptionId,
        [string]$targetSubscriptionId,
        [switch]$SwitchBack
    )

    $switchSubscription = if ($SwitchBack) { $deploymentSubscriptionId } else { $targetSubscriptionId }
    
    if ($deploymentSubscriptionId -ne $targetSubscriptionId) {
        utils-printLog 'Info' "Switching $(if($SwitchBack){'back'} 'to') appropriate Subscription: $($switchSubscription)"
        Select-AzSubscription -SubscriptionId $switchSubscription | Out-Null
    }
}

function utils-GetADServicePrincipal {
    if (!$environmentParams.ADServicePrincipalName) {
        $environmentParams | Add-Member -NotePropertyName ADServicePrincipalName -NotePropertyValue "$product-$client-$environment-Runtime"
        #$environmentParams | Add-Member -NotePropertyName ADServicePrincipalName -NotePropertyValue "$sharedResourcesNaming-Runtime"
        utils-printLog 'Info' "Naming pattern has been used to construct ADServicePrincipalName: $($environmentParams.ADServicePrincipalName)"
    }
    else {
        utils-printLog 'Info' "ADServicePrincipalName will be used from config file: $($environmentParams.ADServicePrincipalName)"
    }

    utils-printLog 'Info' "Verifying that ADServicePrincipal already exists"
    $ADServicePrincipal = Get-AzADServicePrincipal -DisplayName $environmentParams.ADServicePrincipalName |
    Where-Object { $( -join $_.ServicePrincipalNames) -notmatch "https://identity.azure.net/" }  # <<<<----- This is a dirty hack to handle naming pattern as App Service create service principal in AD by itself
    
    if ($ADServicePrincipal) {
        return $ADServicePrincipal
    }
    else {
        utils-printLog 'Warning' "ADServicePrincipal $($environmentParams.ADServicePrincipalName) does not exist"
    }
}

function utils-AddWebAppSettings {
    param (
        [Parameter(Mandatory = $true)] [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)] [string]$WebAppName,
        [Parameter(Mandatory = $true)] [string]$Name,
        [Parameter(Mandatory = $true)] [string]$Value
    )

    $webApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
    $appSettings = $webApp.SiteConfig.AppSettings
    $newAppSettings = @{}
    ForEach ($item in $appSettings) {
        $newAppSettings[$item.Name] = $item.Value
    }
    utils-printLog 'Info' "Add $Name to the WebApp Settings"
    $newAppSettings["$Name"] = $Value
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -AppSettings $newAppSettings | Out-Null
}
