$ftp_host="ftp.com"
$ftp_user=""
$ftp_pass=""
$list_file="ip.txt"
$path="path_run_script"


if (-not (Test-Path -Path $path)) {
    New-Item -Path $path -ItemType Directory
    Write-Output "Folder Created Successfully!"
}
else {
    Write-Output "Folder already exists!"
}


$host_public_ip=(Invoke-WebRequest ifconfig.me/ip).Content.Trim()
$host_public_ip_mask="$host_public_ip/24"
write-host "host public ip is : $host_public_ip"
write-host "host public ip is : $host_public_ip_mask"

$ftp_file = "ftp://$ftp_user`:$ftp_pass@$ftp_host/" + $list_file

$webclient = New-Object System.Net.WebClient
$uri = New-Object System.Uri($ftp_file)
"Download $ftp_file..."
$list_file_to = "path_run_script\$list_file"
$webclient.DownloadFile($uri, $list_file_to)


    if (-not (Select-String -Path "$list_file_to" -Pattern "$host_public_ip")) {
        Write-Output "IP in list not exist"
        Add-Content -Path "$list_file_to" -Value "$host_public_ip_mask"
    }
    else {
        Write-Output "IP in list already exist"
    }

"Uploading $ftp_file..."
$webclient.UploadFile($uri, $list_file_to)
