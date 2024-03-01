$listsites = Get-Content "E:\listSites\listsites.txt"
$outfile   = "E:\listSites\DNXrecords.txt"
$CNAMErecords  = "apps.ksi.kiev.ua"
"List with needed DNS records" | out-file -FilePath $outfile 

foreach( $site in $listsites ){

    $Command = 'ping.exe ' + $($site) + ' -n 1'

    Invoke-Expression -Command $Command -OutVariable PingResult | Out-Null

    #Split Ping Reply to see if it was successful or not

        if (($PingResult.count -gt 1) -and ($PingResult[2].StartsWith('Reply'))){
            Write-Host 'Ping to' $site 'Successful!' -ForegroundColor Green
            } 
        else {
            Write-Host 'Ping to' $site 'Failed!' -ForegroundColor Red
            "$site `t --CNAME->>`t  $CNAMErecords" | Out-File -append -FilePath $outfile;
            }
}
