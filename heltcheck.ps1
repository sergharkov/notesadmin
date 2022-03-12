$SiteLinks = "http://172.27.140.63:8081"

foreach($url in $SiteLinks) {

   try {
      Write-host "Verifying $url" -ForegroundColor Yellow
      $checkConnection = Invoke-WebRequest -Uri $url -UseBasicParsing
      if ($checkConnection.StatusCode -eq 200) {
         Write-Host "Connection Verified!" -ForegroundColor Green
         Exit 0
      }
   } 
   catch [System.Net.WebException] {
      $exceptionMessage = $Error[0].Exception
      if ($exceptionMessage -match "503") {
         Write-Host "Server Unavaiable" -ForegroundColor Red
         Exit 503
      }
      elseif ($exceptionMessage -match "404") {
         Write-Host "Page Not found" -ForegroundColor Red
         Exit 404
      }
      elseif ($exceptionMessage -match "500") {
         Write-Host "Internal Server Error" -ForegroundColor Red
         Exit 500
      }
   }
}
