$WebsiteName="dotnettestqa6"
$Webname = $WebsiteName.tolower()
# file parameters.xml must be like this structure
# <settings>
# 	<Environments>
# 		<Environment envname="DotNetTestQA6">
# 			<InstanceKey>DotNetTest</InstanceKey>
# 			<BranchPrefix>QA6</BranchPrefix>
# 			<Certificate>*.ksiqa.internal.ksiqa.com</Certificate>
# 			<DBDataSource>ksiqa</DBDataSource>
# 			<Location>ksiqaksiqa</Location>
# 			<DBFilesLocation>ksiqa</DBFilesLocation>
# 			<SourceDB>ksiqa</SourceDB>
# 			<RelatedDocsContainer>na1data</RelatedDocsContainer>
# 			<DNSDomain>internal.ksi.com</DNSDomain>
# 			<AzureMapsKey>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</AzureMapsKey>
# 			<DBRestoreDisk>F</DBRestoreDisk>
# 			<WebDataDisk>F</WebDataDisk>
# 			<WebConfigServerLocationCode>NA</WebConfigServerLocationCode>
# 			<WebConfigPolicyCode>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</WebConfigPolicyCode>
# 			<WebConfigInstanceCode>null</WebConfigInstanceCode>
# 			<ODS>N</ODS>
# 			<QlikServer>scscum.ksiqa.internal.ksiqa.com</QlikServer>
# 			<DefaultLocationCode>EU</DefaultLocationCode>
# 			<MungLocationCode>NA</MungLocationCode>
# 			<SessionStateMode>Custom</SessionStateMode>
# 			<RedisHost>ksiRedisCache.redis.cache.windows.net</RedisHost>
# 			<RedisAccessKey>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</RedisAccessKey>
# 			<StorageConnectionString>DefaultEndpointsProtocol=https;AccountName=ksi.kiev.ua;AccountKey=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==;EndpointSuffix=core.windows.net</StorageConnectionString>
# 			<SpeechToTextSubscriptionKey>dfgdfgdfgdfgdfgdfg</SpeechToTextSubscriptionKey>
# 			<SpeechToTextRegion>dfdfgdfgdfgdfgdfgdfg</SpeechToTextRegion>
# 			<TranslateSubscriptionKey>dfgdfgdfgdfg</TranslateSubscriptionKey>
# 			<TranslateRegion>dgdfgdfgdfgdfg</TranslateRegion>
#             <EntitlementsAPIUrl>null</EntitlementsAPIUrl>
#             <TranslateUrl>https://api.ksi.microsofttranslator.com</TranslateUrl>
# 		</Environment>
# 	</Environments>
# </settings>


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
########################################################################################################
function GetXMLValue {

	param ($XMLSection)
	
    $Webname = $WebsiteName.tolower()
    $sectionCount = $ConfigFile.SelectNodes("/settings/Environments/Environment[translate(@envname, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ='$Webname']").count
    if($sectionCount -eq 0){ throw "No sections found in config file 'parameters.xml' for website name '$WebsiteName'" }
    if($sectionCount -gt 1){ throw "$sectionCount sections found in config file 'parameters.xml' for website name '$WebsiteName'" }

	if($ConfigFile.SelectSingleNode("/settings/Environments/Environment[translate(@envname, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ='$Webname']/$XMLSection") -eq $null){throw "$XMLSection section does not exist"}

    $result = $ConfigFile.SelectSingleNode("/settings/Environments/Environment[translate(@envname, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ='$Webname']/$XMLSection").'#text'
    if(!$result){throw "Env:$WebsiteName - $XMLSection has no value"}

	return $result
}
########################################################################################################

# get parameters from Xml file
[xml]$ConfigFile            = Get-Content "Parameters.xml"
# set variables 
$StorageConnectionString    = GetXMLValue StorageConnectionString
# Write-Output  $StorageConnectionString.Split(";")[1]  

#get DEVstoraccount
$slashes_DEVstoraccount     = $StorageConnectionString.IndexOf("AccountName=") + ("AccountName=").Length
$suffix_DEVstoraccount      = $StorageConnectionString.IndexOf(";AccountKey=") - $slashes_DEVstoraccount
$DEVstoraccount             = $StorageConnectionString.Substring($slashes_DEVstoraccount, $suffix_DEVstoraccount)
Write-Output    "DEVstoraccount             --------- $DEVstoraccount"
