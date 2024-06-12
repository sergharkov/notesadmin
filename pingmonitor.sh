#!/bin/bash
DESTIP="home.ksi.kiev.ua"

status=""
prevstatus=""
logfile="/var/log/HomeTumaniana.log"


prevstatus=$(tail -n 1 /var/log/HomeTumaniana.log  | awk '{print $8}')
echo "previouse status ==  $prevstatus"
echo 'Begin ping'

ping -c 2 $DESTIP > /dev/null
if [ $? -eq 0 ]
  then
    status="OK-OK-OK"
    echo " $(date)  [info] $status HomeTumaniana ping to $DESTIP " >> $logfile  
    if [ "$prevstatus" != "$status" ]
      then
          curl -s -X POST https://api.telegram.org/bot7482410376:AAFua_zEhM3nW2dEiVtBJuGWJ7GPE7UBLc0/sendMessage -d chat_id=517090498 -d text="Tumaniana Inet is ON-ONNNN"
          echo " "
          echo -e "prev__status  \t!!!==!!!  current__status"  
          echo "$prevstatus   \t!!!==!!!   $status"       
      else 
          echo -e "prev__status   \t===  current__status"  
          echo -e "$prevstatus   \t===  $status"  
    fi

  else
    status="NO-NO-NO"
    echo " $(date)  [error] $status HomeTumaniana ping to $DESTIP " >> $logfile

    if [ "$prevstatus" != "$status" ]
      then
          curl -s -X POST https://api.telegram.org/bot7482410376:AAFua_zEhM3nW2dEiVtBJuGWJ7GPE7UBLc0/sendMessage -d chat_id=517090498 -d text="Tumaniana Inet is OFF"
          echo " "
          echo -e "prev__status  \t!!!==!!!  current__status"  
          echo "$prevstatus   \t!!!==!!!   $status"       
      else 
          echo -e "prev__status   \t===  current__status"  
          echo -e "$prevstatus   \t===  $status" 
    fi

fi

echo "current__status ===================== $status"
