param (
    [Parameter(Mandatory = $true)][string]$product,
    [Parameter(Mandatory = $true)][string]$client,
    [Parameter(Mandatory = $true)][string]$environment,
    [Parameter(Mandatory = $true)][string]$subscriptionId
)

$ErrorActionPreference = "Stop"
Import-Module DBcreapt_utils.ps1 -Force

$tenantId = "d5564c63-fe88-47f5-bb3a-e857c6a12ad0"
$keyVaultName = $product.ToUpper() + (Get-Culture).TextInfo.ToTitleCase("-$client-$environment")
Select-AzSubscription -Subscription $subscriptionId

function Get-SqlEncryptedColumns {
    param (
        [Parameter(Mandatory = $true)][string]$app
    )

    try {
        $sqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "PhysicalSqlServerName" -AsPlainText) 
    }
    catch {
        utils-printLog 'Info' "PhysicalSqlServerName not found"
    }

    if (!$sqlServerName) {
        utils-printLog 'Info' "Get $($app)PhysicalSqlServerName"
        $sqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $app"SqlServerName" -AsPlainText)
    }

    $sqlDatabaseName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $app"SqlDatabaseName" -AsPlainText)
    $sqlServerPassword = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $app"SqlServerPassword" -AsPlainText)
    if ([string]::IsNullOrEmpty($sqlServerPassword)) {
        Write-Error "sqlServerPassword is null or empty"
    }
    $serverInstance = $sqlServerName + ".database.windows.net"

    utils-printLog 'Info' "##### Get $app encrypted columns #####"
    $sqlGetEncryptedColumns = 'SELECT name FROM sys.columns WHERE encryption_type IS NOT NULL'
    $sqlQuery = $ExecutionContext.InvokeCommand.ExpandString($sqlGetEncryptedColumns)
    Invoke-Sqlcmd -ServerInstance $serverInstance -Database $sqlDatabaseName -Username 'sql.admin' -Password $sqlServerPassword -Query $sqlQuery
}

#############################################################################
utils-printLog 'Warning' "Run script in Powershell 5.1 as Administrator`nFor the DBs in Elastic pool:`nAdd PhysicalSqlServerName secret to the AKV`nUpdate [app]SqlServerName secrets"

if ([version]::new($PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor) -ne [Version]'5.1') {
    Write-Error "Run script in Powershell 5.1 as Administrator"
}
utils-printLog 'Warning' "# 0 Review all Uptake requirements before running the script and make sure it contains all changes #`nhttps://confluence.revenuegrid.com/display/SDOL/RI+2206+Uptakes"
$confirmation = Read-Host "Are You Sure You Want To Proceed? (y/n)"
if ($confirmation -ne 'y') {
    exit 0
}

#############################################################################
utils-printLog 'Info' "# 1 Create Encryption Key and update KV permissions #"

if ($client -contains "ambu") {
    Write-Error "Set Ambu's environments secrets manualy"
}

# Create a new Key, type – RSA, size - 2048
$encryptedKey = utils-CreateKeyVaultKey -KeyName "AlwaysEncryptedKey" -KeyVaultName $KeyVaultName

# Add next permissions for the %product%-%client%-%environment%-Sync-Runtime application
$permissions = @("Get", "Decrypt", "Encrypt", "WrapKey", "UnwrapKey", "Sign", "Verify")

$ADServicePrincipalApplicationId = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalApplicationId" -AsPlainText)
$ADServicePrincipal = (Get-AzADServicePrincipal -ApplicationId $ADServicePrincipalApplicationId)
Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName `
    -ObjectId $ADServicePrincipal.Id `
    -PermissionsToKeys $permissions `
    -PassThru

###################################################################
utils-printLog 'Info' "# 2 Add Secrets to KeyVault $keyVaultName #"

utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "ADServicePrincipalTenantId" $tenantId $false

utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "EncryptionKeyPath" $encryptedKey.Id $false
utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "EncryptionKeyName" $keyVaultName $false
utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "EncryptionMasterKeyName" $keyVaultName $false

# Set secrets for the AMBU's envs manually
$ADServicePrincipalApplicationId = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalApplicationId" -AsPlainText)
$ADServicePrincipalSecret = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalSecret" -AsPlainText)
$ADServicePrincipalTenantId = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalTenantId" -AsPlainText)

utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "AlwaysEncryptedADClientId" $ADServicePrincipalApplicationId $false
utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "AlwaysEncryptedADClientSecret" $ADServicePrincipalSecret $true
utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "AlwaysEncryptedADTenantId" $ADServicePrincipalTenantId $false

###################################################################
utils-printLog 'Info' "# 3 SQL Encrypt columns in Addin database #"

Import-Module SqlServer

# Set up connection and database SMO objects
$AddinSqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "AddinSqlServerName" -AsPlainText)
$AddinSqlDatabaseName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "AddinSqlDatabaseName" -AsPlainText)
$AddinSqlServerPassword = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "AddinSqlServerPassword" -AsPlainText)
$sqlConnectionString = "Data Source=$AddinSqlServerName.database.windows.net;Initial Catalog=$AddinSqlDatabaseName;User Id=sql.admin;Password=$AddinSqlServerPassword;"
# If your encryption changes involve keys in Azure Key Vault, uncomment one of the lines below in order to authenticate:
#   * Prompt for a username and password:
#Add-SqlAzureAuthenticationContext -Interactive

#   * Enter a Client ID, Secret, and Tenant ID:
$ADServicePrincipalApplicationId = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalApplicationId" -AsPlainText)
$ADServicePrincipalSecret = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalSecret" -AsPlainText)
$ADServicePrincipalTenantId = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ADServicePrincipalTenantId" -AsPlainText)

Add-SqlAzureAuthenticationContext -ClientID $ADServicePrincipalApplicationId -Secret $ADServicePrincipalSecret -Tenant $ADServicePrincipalTenantId

# Connect to your database
$smoDatabase = Get-SqlDatabase -ConnectionString $sqlConnectionString

# Creates a SqlColumnMasterKeySettings object for a column master key with the specified provider and key path.
$EncryptionKeyPath = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "EncryptionKeyPath" -AsPlainText)
$CmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyUrl $EncryptionKeyPath

# Creates a column master key object in the database.
New-SqlColumnMasterKey -Name "$keyVaultName-Master-Key" -ColumnMasterKeySettings $CmkSettings -InputObject $smoDatabase
Get-SqlColumnMasterKey -InputObject $smoDatabase

# Create a column encryption key object in the database.
New-SqlColumnEncryptionKey -Name "$keyVaultName-Encryption-Key" -ColumnMasterKeyName "$keyVaultName-Master-Key" -InputObject $smoDatabase

# Change encryption schema
$encryptionChanges = @()
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName dbo.Connections.ConnectionToken -EncryptionType Deterministic -EncryptionKey "$keyVaultName-Encryption-Key"
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName dbo.Connections.JsonWebToken -EncryptionType Deterministic -EncryptionKey "$keyVaultName-Encryption-Key"
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName dbo.Credentials.RefreshToken -EncryptionType Deterministic -EncryptionKey "$keyVaultName-Encryption-Key"
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName dbo.SecurityTokens.Key -EncryptionType Deterministic -EncryptionKey "$keyVaultName-Encryption-Key"

# Proceed encryption
$addinEncryptedColumns = Get-SqlEncryptedColumns -app Addin
if ($addinEncryptedColumns) {
    utils-printLog 'Warning' "# Addin DB already contains encrypted colums:"
    $addinEncryptedColumns
} else {
    utils-printLog 'Info' "Proceed encryption"
    Set-SqlColumnEncryption -ColumnEncryptionSettings $encryptionChanges -InputObject $smoDatabase
}

######################################################################################
utils-printLog 'Info' "# 4 GET SQL Encrypted columns and update External User roles #"

$apps = ("Addin", "Sync")
foreach ($app in $apps) {
    Get-SqlEncryptedColumns -app $app
    
    try {
        $sqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "PhysicalSqlServerName" -AsPlainText) 
    }
    catch {
        utils-printLog 'Info' "PhysicalSqlServerName not found"
    }

    if (!$sqlServerName) {
        utils-printLog 'Info' "Get $($app)SqlServerName"
        $sqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $app"SqlServerName" -AsPlainText)
    }

    $sqlDatabaseName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $app"SqlDatabaseName" -AsPlainText)
    $sqlServerPassword = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $app"SqlServerPassword" -AsPlainText)
    if ([string]::IsNullOrEmpty($sqlServerPassword)) {
        Write-Error "sqlServerPassword is null or empty"
    }
    $serverInstance = $sqlServerName + ".database.windows.net"

    # Get all External DB users to update roles
    $sqlGetExternalUsers = "SELECT name FROM sys.database_principals WHERE type_desc = 'EXTERNAL_GROUP'  OR name LIKE '%-svc'"
    $sqlQuery = $ExecutionContext.InvokeCommand.ExpandString($sqlGetExternalUsers)
    $externalUsers = Invoke-Sqlcmd -ServerInstance $serverInstance -Database $sqlDatabaseName -Username 'sql.admin' -Password $sqlServerPassword -Query $sqlQuery

    foreach ($user in $externalUsers) {
        $user = $user.name
        utils-printLog 'Info' "# Update roles for $user #"
        $sqlUpdateUserRole = @'
        IF EXISTS (SELECT *
        FROM sys.database_principals
        WHERE name = '$user')
        BEGIN
            GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO [$user]
            GRANT VIEW ANY COLUMN ENCRYPTION KEY DEFINITION TO [$user]
        END
        GO
'@
        $sqlQuery = $ExecutionContext.InvokeCommand.ExpandString($sqlUpdateUserRole)
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $sqlDatabaseName -Username 'sql.admin' -Password $sqlServerPassword -Query $sqlQuery
    }
}

######################################################################################
utils-printLog 'Info' "# 5 Create Sync-deploy user #"

$user = "Sync-deploy"
$sqlUserPassword = $(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SyncDeploySqlUserPassword" -AsPlainText -ErrorAction SilentlyContinue)

if($(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SyncDeploySqlUserName") -eq $user) {
    utils-printLog 'Info' "# [SyncDeploySqlUserName] already exists in $keyVaultName"
} else {
    utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "SyncDeploySqlUserName" $user $false
}

if ($sqlUserPassword) {
    utils-printLog 'Info' "# [SyncDeploySqlUserPassword] already exists in $keyVaultName"
} else {
    $sqlUserPassword = utils-PasswordGenerator
    utils-CreateKeyVaultSecret $keyVaultName $subscriptionId "SyncDeploySqlUserPassword" $sqlUserPassword $true
}

try {
    $sqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "PhysicalSqlServerName" -AsPlainText) 
}
catch {
    utils-printLog 'Info' "PhysicalSqlServerName not found"
}

if (!$sqlServerName) {
    utils-printLog 'Info' "Get SyncSqlServerName"
    $sqlServerName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SyncSqlServerName" -AsPlainText)
}

$sqlDatabaseName = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SyncSqlDatabaseName" -AsPlainText)
$sqlServerPassword = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SyncSqlServerPassword" -AsPlainText)
if ([string]::IsNullOrEmpty($sqlServerPassword)) {
    Write-Error "sqlServerPassword is null or empty"
}
$serverInstance = $sqlServerName + ".database.windows.net"
$sqlQuerySyncDeploy = $ExecutionContext.InvokeCommand.ExpandString($(Get-Content ..\..\SqlDatabase\AddUser_Sync_deploy.sql | Out-String))
Invoke-Sqlcmd -ServerInstance $serverInstance -Database $sqlDatabaseName -Username 'sql.admin' -Password $sqlServerPassword -Query $sqlQuerySyncDeploy
