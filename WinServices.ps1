$list_running_veeam_services=(Get-Service -Name "veeam*"| Where-Object {$_.Status -eq "Running"}).Name 


write-host $list_veeam_services

$manual_veeam_services = @('VeeamBackupCdpSvc',`
'VeeamAzureSvc',`
'VeeamFilesysVssSvc')

foreach ($service in $list_running_veeam_services) {
write-host $service
Stop-Service $service
}



$list_all_veeam_services=(Get-Service -Name "veeam*").Name 

foreach ($service in $list_all_veeam_services) {
write-host $service
Set-Service -Name $service -StartupType manual
Stop-Service $service
}


foreach ($service in $list_all_veeam_services) {
write-host $service
Set-Service -Name $service -StartupType Automatic
Start-Service $service
}


