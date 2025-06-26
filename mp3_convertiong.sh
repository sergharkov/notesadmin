#!/bin/sh
echo "starting......"
#####################################################
# docker-compose -f docker-compose.yml stop callrecordssheduler \
# && docker-compose -f docker-compose.yml build callrecordssheduler \
# && docker-compose -f docker-compose.yml up -d callrecordssheduler \
# && docker exec -it callrecordssheduler bash
# needed:
# --lame
# --awscli
#####################################################
# https://ourcodeworld.com/articles/read/1402/how-to-convert-wav-files-to-mp3-with-the-command-line-using-lame-like-a-boss-in-windows-10
# wget -O lame-3.99.5.tar.gz https://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download
# tar -xvf lame-3.99.5.tar.gz 
# rm lame-3.99.5.tar.gz 
# cd lame-3.99.5 
# ./configure
# make 
# make install
#####################################################
# Prepearing SQL DB
# USE asterisk;
# SHOW TABLES;

# CREATE TABLE records (
#     callid CHAR(80) NOT NULL default '',
# 	uniqueid CHAR(180) NOT NULL default '',
# 	timestamp CHAR(180) NOT NULL default '',	
# 	filefullname CHAR(180) NOT NULL default '',
# 	filefullnamepath CHAR(180) NOT NULL default '',
# 	dst_url CHAR(255) NOT NULL default ''
# );
#####################################################
echo "######### Will Use system Variables for AWS S3"
echo "######### AWSS3 bucket== $AWSS3"
echo "#############################################"
awss3bucket="$(echo "$AWSS3")"
deltatime="$(echo "$PERIODTIME")" # in minutes (-mmin)
DB_URL="$(echo "$MARIADB_URL")"
DB_ROOT_PASSWORD="$(echo "$MARIADB_ROOT_PASSWORD")"
DB_DATABASE="$(echo "$MARIADB_DATABASE")"
DB_USER="$(echo "$MARIADB_USER")"
DB_PASSWORD="$(echo "$MARIADB_PASSWORD")"
DB_TABLE="records"
########################  check #####################
echo $DB_URL
echo $DB_ROOT_PASSWORD
echo $DB_DATABASE
echo $DB_USER
echo $DB_PASSWORD
########################  check #####################
bitrate_to_mp3="32"
requiredsizewavfile=100
records_path="/tmp/callsrecords"
wav_records="$records_path/wav"
datepath="$(date +"%Y")/$(date +"%m")/$(date +"%d")"
mp3_records="$records_path/mp3/$datepath"

echo "=================  awss3bucket   $awss3bucket "

mkdir -p $wav_records

ls -la $wav_records
#ls -la $mp3_records

list_wav_files=$(find $wav_records/* -mmin +$deltatime | sed 's/.*\///' | grep -v mp3)
#list_mp3_files=$(find $mp3_records/* -mmin +$deltatime | sed 's/.*\///')

echo $list_wav_files
#echo $list_mp3_files

echo "Start converting and moving to AWS S3 storage......................."
for wav_file in $list_wav_files;
do
  echo "----------------------"
  printf "   %s\n" $wav_records/$wav_file
  mp3_file="$(echo $wav_file | sed 's/.wav//g').mp3"
  if [[ $(stat -c%s $wav_records/$wav_file) -lt $requiredsizewavfile ]]
  then
    echo "-------------- file $wav_records/$wav_file LESSSSSSSSSSSS then $requiredsizewavfile "
  else
    mkdir -p $mp3_records
    echo "-------------- full way to mp3 file  -------- $mp3_records/$mp3_file-- ---------------------"
    echo "-------------- file $wav_records/$wav_file BIGGERRRRRRRRR then $requiredsizewavfile "
    echo "++++++++++++++ size of file  $wav_records/$wav_file   is $(stat -c%s $wav_records/$wav_file) "
    lame -b $bitrate_to_mp3 $wav_records/$wav_file $wav_records/$mp3_file
    mv -f $wav_records/$mp3_file $mp3_records/$mp3_file
    aws s3 cp $mp3_records/$mp3_file $awss3bucket/$datepath/$mp3_file
    callid_val=$(echo $mp3_file | awk  -F '-' '{print $5 }')
    uniqueid_val=$(echo $mp3_file | awk  -F '-' '{print $1 }')
    timestamp_val=$(echo $mp3_file | awk  -F '-' '{print $2 }')
    filefullname_val="$mp3_file"
    filefullnamepath_val="$datepath"
    dst_url_val="$awss3bucket/$datepath/$mp3_file"
    # SQL запрос для вставки данных
    INSERT_QUERY="INSERT INTO $DB_TABLE (callid, uniqueid, timestamp, filefullname, filefullnamepath, dst_url) VALUES ('$callid_val', '$uniqueid_val', '$timestamp_val', '$filefullname_val', '$filefullnamepath_val', '$dst_url_val');"
    echo $INSERT_QUERY
    # Выполнение запроса через mysql client
    mysql -h "$DB_URL" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_DATABASE" -e "$INSERT_QUERY" --skip-ssl
    rm -f $mp3_records/$mp3_file
  fi
  echo "!!!!!!!!!!!!! will remove file =========== $wav_records/$wav_file   ======================"
  echo "+++++++++++++ size of file  $wav_records/$wav_file   is $(stat -c%s $wav_records/$wav_file) "
  rm -f $wav_records/$wav_file
done
echo "==============SHOW local files==============="
echo "==============  Wav records  ==============="
ls -la $wav_records
echo "==============  Mp3 records  ==============="
ls -la $mp3_records
echo "================ AWS S3 list ================"
aws s3 ls $awss3bucket/$datepath/
#####################################################
echo "///////////////////////--END SCRIPT--///////////////////////"
