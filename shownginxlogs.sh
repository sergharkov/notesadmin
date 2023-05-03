#!/bin/bash
#vi  ./shownginxlogs.sh
#chmod +x ./shownginxlogs.sh

cd /home/services/nginx/logs

listsites=$(ls | grep .443.access.log | sed "s/.443.access.log//g")
echo $listsites

for listsite in ${listsites[*]}
do
echo -e "###################" $listsite "#####################\n"
datef=$(date +%d/%b/%Y)
cat $listsite.443.access.log | grep $datef | awk '{print  $1}' |  sort |  uniq -c | sort -rn
echo -e "##############################################################\n"
done
