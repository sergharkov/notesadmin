[string]$string = "$(ReleaseVersion)"
$Corepath = "$(build.sourcesdirectory)\src"


#variables for AssemblyInfo
$AssemplyFile = "CommonAssemblyInfo.cs"
$AssemblyVersionPattern = '\[assembly: AssemblyVersion\("(.*)"\)\]'
$AssemblyFileVersionPattern = '\[assembly: AssemblyFileVersion\("(.*)"\)\]'

#variables for App.xaml
$AppXMLFile = "App.xaml.cs"
$CurrentDay = (Get-Date).Day
$CurrentMonth = (Get-Date).Month
$CurrentYear = (Get-Date).Year

#variabl for Docugenerator config file
$AppConfigFile = "$Corepath\ENV1\App.config"


$AssemplyFileLocation = @('ENV1',`
'ENV2',`
'ENV3')

$AppXamlLocation = @('ENV1',`
'ENV2',`
'ENV3')


###############################################
############### AssemplyFile ##################
###############################################
foreach ($path in $AssemplyFileLocation) {
 
 $VersionFile = "$Corepath\$path\$AssemplyFile"

 (Get-Content $VersionFile) | ForEach-Object{
    if($_ -match $AssemblyVersionPattern){
        # We have found the matching line
        # Edit the version number and put back.
        $Version = [version]$matches[1]
         $AssemblyVersion = "{0}.{1}.{2}.{3}" -f $string.Split(".")[0], $string.Split(".")[1], $string.Split(".")[2], ($Version.Revision + 1)
        '[assembly: AssemblyVersion("{0}")]' -f $AssemblyVersion
    } else {
        # Output line as is
        $_
    }
} | Set-Content $VersionFile


(Get-Content $VersionFile) | ForEach-Object{
    if($_ -match $AssemblyFileVersionPattern){
        # We have found the matching line
        # Edit the version number and put back.
        $fileVersion = [version]$matches[1]
        $AssemblyFileVersion = "{0}.{1}.{2}.{3}" -f $string.Split(".")[0], $string.Split(".")[1], $string.Split(".")[2], ($fileVersion.Revision + 1)
       '[assembly: AssemblyFileVersion("{0}")]' -f $AssemblyFileVersion
    } else {
        # Output line as is
        $_
   }
} | Set-Content $VersionFile
Write-Host "New PACE Suite version: $AssemblyFileVersion"
Write-host "####################### AFTER ######################################"
Get-Content -path $VersionFile -Raw
######################
git add  $VersionFile
}

###############################################
############### XML app config file ###########
###############################################
foreach ($path in $AppXamlLocation) {
$AppXamlCsFile = "$Corepath\$path\$AppXMLFile"
(Get-Content $AppXamlCsFile) `
     -replace 'uildTimeDay = "(.*)"', "uildTimeDay = `"$CurrentDay`"" `
     -replace 'uildTimeMonth = "(.*)"', "uildTimeMonth = `"$CurrentMonth`"" `
     -replace 'uildTimeYear = "(.*)"', "uildTimeYear = `"$CurrentYear`"" | Set-Content $AppXamlCsFile
######################
Get-Content -path $AppXamlCsFile -Raw
git add $AppXamlCsFile
}

###############################################
#######Config File DocuGenerator###############
###############################################
[xml]$AppConf = Get-Content $AppConfigFile
$AppConf.configuration.configSections.section[0].type = "Docu_Generator.Common.Configuration.CustomSectionConfiguration, Docu-Generator.Common, Version=$AssemblyVersion, Culture=neutral, PublicKeyToken=xxxxxxxxxx "
$AppConf.Save($AppConfigFile)
Write-Host "New PACE Suite version: $AssemblyFileVersion"
######################
Get-Content -path $AppConfigFile -Raw
git add  $AppConfigFile

git commit -m "update AutoIncrement"
git push origin $(Build.SourceBranchName)
