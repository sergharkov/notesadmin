#I use it for clearing in TFS server 

$PHpath = "c:\.....\$(dropbuild)"
$splitPath = Split-Path $PHpath

Get-Item $PHpath
$RetentionPolicy = 5
Write-Host "Current build artifact retention policy is $RetentionPolicy days."

$FoldersCheck = Get-ChildItem -Directory $splitPath | Where {$_.LastWriteTime -le (Get-Date).AddDays(-$RetentionPolicy)}
Write-Host "`nThe following outdated build folders will be removed:"
$FoldersCheck | % {Write-Host $_.FullName}
$FoldersCheck | Remove-Item -Recurse -Force
