#!/bin/bash
#### PREPARATION
#apt install gpw -y
echo "" > /ar-src/list_USER_PASS_DB

#################################################################################
SITES_PATH="/var/www"
WP_EMAIL="ksi@gmail.com"
SQL_root="root"
SQL_root_pass="MyN3wP4ssw0rd"
SQL_dump="./firm13_hitech20_online.sql"
list_file="/ar-src/site.list"
listsites=$(cat $list_file)
echo $listsites
#################################################################################
FIRST_install (){
##############  FIST INSATALL  ############################
##### PHP
##### NGINX
##### CertBOT-nginx
#################################################################################
apt-get install curl htop git wget gnupg gnupg2 nginx -y || apk add curl \
&& curl -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x /tmp/wp-cli.phar \
&& mv /tmp/wp-cli.phar /usr/local/bin/wp

apt-get -y install software-properties-common
apt-get update
add-apt-repository ppa:ondrej/php -y
apt-get update
apt-get -y install php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline  php7.4-imap php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-imagick php7.4-dev php7.4-opcache php7.4-soap php7.4-gd php7.4-zip php7.4-intl php7.4-curl
sed -i 's/;cgi.fix_pathinfo=0/	cgi.fix_pathinfo=1/g' /etc/php/7.4/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 300M/g' /etc/php/7.4/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 300M/g' /etc/php/7.4/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/7.4/fpm/php.ini
sed -i 's/max_input_time = 60/max_input_time = 600/g' /etc/php/7.4/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/fpm/php.ini
cat << 'eof' >> /etc/php/7.4/fpm/php-fpm.conf

pm = dynamic
    pm.max_children = 97
    pm.start_servers = 20
    pm.min_spare_servers = 10
    pm.max_spare_servers = 20
    pm.max_requests = 200

eof
sudo apt-get -y install certbot
apt install -y python-certbot-nginx || apt-get -y install python3-certbot-nginx
mkdir -p /var/www/default

#################################################################################
cat ./nginx_template_default_wellcome.conf > /etc/nginx/sites-available/default

cat ./nginx_template_default_wellcome.php  > /var/www/html/index.nginx-debian.php
rm -f /var/www/html/index.nginx-debian.html
#################################################################################
}
#################################################################################
GENERATE_NGINX_CONF() {
SITE=$1
	echo "generate config for $SITE"
	sed "s/WPDOMAINSITE/$SITE/g" nginx_template.conf >  /etc/nginx/sites-available/$SITE.conf 
	cat /etc/nginx/sites-available/$SITE.conf
	ln /etc/nginx/sites-available/$SITE.conf /etc/nginx/sites-enabled/$SITE.conf
}
#################################################################################
SQLcreate (){
	SITE=$1
	SQL_user=$(echo $1 | tr "." "_" | tr "-" "_")
	SQL_db=$(echo $1 | tr "." "_" | tr "-" "_")
	SQL_pass=$(echo $2 | tr "." "_" | tr "-" "_")
	echo "SQL_user === $SQL_user"
	echo "SQL_db   === $SQL_db"
	echo "SQL_pass === $SQL_pass"
echo "==============================================="
SQL_create_user_db="CREATE USER IF NOT EXISTS '$SQL_user'@'%' IDENTIFIED WITH mysql_native_password BY '$SQL_pass'; \
                    GRANT USAGE ON *.* TO '$SQL_user'@'%'; \
                    ALTER USER '$SQL_user'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0; \
                    CREATE DATABASE IF NOT EXISTS $SQL_db; \
                    GRANT ALL PRIVILEGES ON $SQL_db.* TO '$SQL_user'@'%';"
echo "==============================================="
#	echo "$SQL_create_user_db"
wp_admin=root
wp_pass=$(date +%s|sha256sum|base64|head -c 20)

echo "SITE= $SITE  SQL_user= $SQL_user  SQL_db= $SQL_db  SQL_pass= $SQL_pass wp_pass= $SQL_pass wp_admin= $wp_admin"  >> /ar-src/list_USER_PASS_DB
mysql -u$SQL_root -p$SQL_root_pass -e "$SQL_create_user_db" 

mkdir -p $SITES_PATH/$SITE
chown -R www-data:www-data $SITES_PATH/$SITE

#WP deploy clear WP from default template
wp core download --path=$SITES_PATH/$SITE --locale=en_US --allow-root \
&& wp config create --path=$SITES_PATH/$SITE --dbname=$SQL_user --dbuser=$SQL_user --dbpass=$SQL_pass --dbhost=localhost --allow-root --skip-check \
&& wp core install --skip-email --url=$SITE --title=$SITE --admin_user=$wp_admin --admin_password=$SQL_pass --admin_email=$WP_EMAIL --allow-root --path=$SITES_PATH/$SITE

####### RESTORE DUMP from SQL-template #######
mysql -u$SQL_user -p$SQL_pass $SQL_user < ./$SQL_dump
##############################################

chown -R www-data:www-data $SITES_PATH/$SITE
}
#################################################################################
echo "===========================================================
Prepearing server:
------------------------------------------------------------"
	read -r -p "Do you want first install infra? ? [y/N]  :" Yes_No 
	if [[ "$Yes_No" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
		FIRST_install
	else 
		echo "continue without prepearing"
	fi
#################################################################################
   for listsite in ${listsites[*]}
	do
		echo -e "###################" $listsite "#####################\n"
		SQLpass=$(echo "$(< /dev/urandom tr -dc _A-Z-a-z-0-9- | head -c30)_.=")
		echo $SQLpass
		SQLcreate $listsite $SQLpass
#################################################################################
echo "===========================================================
Prepearing NGINX domains:
------------------------------------------------------------"

GENERATE_NGINX_CONF $listsite

	# read -r -p "Do you want generate sites configs for $listsite ? [y/N]  : " Yes_No
	# if [[ "$Yes_No" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
	# 	GENERATE_NGINX_CONF $listsite
	# else
	# 	echo "continue without generate sites configs "
	# fi
  done
ls -la $SITES_PATH
nginx -t
nginx -s reload


# rm -rf /var/www/*.ksi.kiev.ua
# rm -rf /etc/nginx/sites-enabled/*.ksi.kiev.ua.conf
# rm -rf /etc/nginx/sites-available/*.ksi.kiev.ua.conf 
