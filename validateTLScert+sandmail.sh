#!/bin/bash
tomail="ksi@ksi.kiev.ua"
SITE_SSL_PORT="443"
DAYS="14"

declare -a arr_sites=(\
"ksi.kiev.ua" \
"cven.ksi.kiev.ua" \
)

## now loop through the above array
ArrSitesEndCert+=$(echo "---------check expired after  >>$DAYS<< days-----------------------------")
ArrSitesEndCert+=$(echo "\n\n")

####------for every in string ------####

for SITE_URL in "${arr_sites[@]}"
do
DateSert=$(: | openssl s_client -connect  $SITE_URL:${SITE_SSL_PORT} -servername ${SITE_URL} 2>/dev/null \
                   | openssl x509 -text \
                   | grep 'Not After' \
                   |awk '{print $4,$5,$7}')
expirationdate=$(date -d "$DateSert" '+%s');
inPlusDays=$(($(date +%s) + (86400*DAYS)));

####------if expire in nearest days ------####

  if [ "$(($(date +%s) + (86400*DAYS)))" -gt "$expirationdate" ]; then

####------if expired yet ------####

        if [ "$(date +%s)" -gt "$expirationdate" ]; then
           ArrSitesEndCert+=$(echo "!!!!!!!!!!!!!     ")
           ArrSitesEndCert+=$(echo "$SITE_URL \t---  !!!!!!!!! - Cert has expired  $(date -d @"$expirationdate" '+%Y-%m-%d') and is not yet valid")
           ArrSitesEndCert+=$(echo "     !!!!!!!!!!!!!")
           ArrSitesEndCert+=$(echo "\n\n")
        else
           ArrSitesEndCert+=$(echo "$SITE_URL \t--- !!WARNING!! - Cert expires in less than $DAYS days, on $(date -d @"$expirationdate" '+%Y-%m-%d')")
           ArrSitesEndCert+=$(echo "\n\n")
        fi;
  else
      ArrSitesEndCert+=$(echo "$SITE_URL \t--- OK - Certificate expire on $DateSert")
      ArrSitesEndCert+=$(echo "\n\n")
  fi;
done
echo -e  "$ArrSitesEndCert"

mail -s 'Check KSI status Cert' $tomail << EOF
$(echo -e  "$ArrSitesEndCert")
