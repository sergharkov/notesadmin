#!/bin/bash
host="0.0.0.0"
port="5433"
dbuser="xxxx"
dbname="xxxx"
dbpass="xxxx"
envdomain=$(hostname)
OUTSIDEneedBackUP=""
alertdiskspace=""
result_parth_over=""
remoteBackUpIP="xxx.xxx.xxx.xxx"
remoteBackUpPath="/home/services/mysql_dump/rrrrrrrr/"


current_folder="/autostart/postgreSQL/backup/$(date +%Y-%m-%d)/$(date +%H-%M-%S)"
#current_folder="/autostart/postgreSQL/backup/$(date +%Y)/$(date +%m)/$(date +%d-%m-%Y)"
mkdir -p $current_folder
backupfile="$current_folder/$envdomain-$(date +%d-%m-%Y--%H-%M).dump"

HoursBackUP=$(date +%H)
PGPASSWORD=$dbpass pg_dump -Fc --host=$host --port=$port --username=$dbuser $dbname --file=$backupfile

if (( $HoursBackUP % 4  == 0 ))           # no need for backups
then
	echo $HoursBackUP
	OUTSIDEneedBackUP="and backup replicas to outside server"
	echo "$(date +%d-%m-%Y--%H-%M)  PostgreSQL DB:$dbname need backup from env:$envdomain TO OUTSIDE server $remoteBackUpIP" >> /var/log/postgreSQLbackup.log
	scp $backupfile $remoteBackUpIP:$remoteBackUpPath
else
	echo "simple permanenly bachUP to local PATH"
fi

result_parth_over=$(df -h --output=source,pcent | awk '0+$2 >= 75 {print}')
if [ -z "$result_parth_over" ]
then
      echo "$result_parth_over is NOT full"
else
      alertdiskspace=$(echo "!!!!! $result_parth_over is full")
      echo "$result_parth_over is full"
fi
curl -s -X POST https://api.telegram.org/bot6040401992:AAEQM0olDtE3eDh5a2asoAtuH7hHYsrhCYQ/sendMessage -d chat_id=-808288196 -d text="PostgreSQL DB:$dbname backup from env:$envdomain done $OUTSIDEneedBackUP"
echo "$(date +%d-%m-%Y--%H-%M)  PostgreSQL DB:$dbname backup from env:$envdomain done" >> /var/log/postgreSQLbackup.log
