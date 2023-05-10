#!/bin/bash
tel_report="1"
svcs=$(docker service ls --format "{{.Name}}" | grep -v portainer | grep -v sql | grep -v red) && echo $svcs
echo "============================================================================================"
arr_total_error=("")

for svc in ${svcs[*]}
do

echo -e "###################" $svc "#####################\n"
logresult=$(timeout -v 3 docker service logs --raw --since 2m -f --no-trunc $svc 2>&1)

echo "======================================================================================"
if [[ $(echo $logresult | grep 'error') ]]; then
      status="HAS error!!!!!"
      echo "====================$svc deploy $status =======!!!!!!!!!!!!!!!!!!!!!!!!!======="
      timeout -v 5 docker service logs --raw --since 2m -f --no-trunc $svc 2>&1

arr_total_error+=("$svc")

else
      status="NO error"
      echo "====================$svc deploy $status"; fi
done
echo "=======total======="

echo  "This svc has error ${arr_total_error[@]}"

tel_report=$(echo ${arr_total_error[@]})
echo "pre validation ===================== $tel_report"

if [ "$tel_report" != "1" ]; then
        echo "has erro in $tel_report"
  curl -s -X POST https://api.telegram.org/bot0000000:0000000000000000000000000/sendMessage -d chat_id=-00000000 -d text="Current PROD svc has error $tel_report"
  echo  "$(date +%d-%m-%Y-%M:%H)  [error] this svc has error $tel_report"  >>  /var/log/swsvc_check_error.log
else
  echo  "$(date +%d-%m-%Y-%M:%H)  [ok-ok-ok] this svc hasn't error $tel_report"  >>  /var/log/swsvc_check_error.log
fi
