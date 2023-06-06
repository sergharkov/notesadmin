#!/bin/bash
#### PREPARATION
#apt install gpw -y
echo "" > /ar-src/list_USER_PASS_DB

#################
SITES_PATH="/var/www"
WP_EMAIL="alina.m.giese@gmail.com"
SQL_root="root"
SQL_root_pass="MyN3wP4ssw0rd"

list_file="/ar-src/site.list"

listsites=$(cat $list_file)
echo $listsites

FIRST_install (){
##############  FIST INSATALL  ############################
##### PHP
##### NGINX
##### CertBOT-nginx

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
cat << EOF > /var/www/default/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to EXP!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body style="background-color:white;">
<h1 style="color:black;">Welcome to EXP!</h1>
</body>
</html>
EOF


}

GENERATE_NGINX_CONF() {

SITE=$1
echo "generate config rot $SITE"

cat << EOF > /etc/nginx/sites-available/$SITE.conf
### Configuration ###
    server {
        listen 80;
        listen [::]:80;
        listen 443;
        listen [::]:443;
        server_name $SITE www.$SITE;
        root /var/www/$SITE;
        index index.php index.html index.htm index.nginx-debian.html;

        location / {
            try_files $uri $uri/ /index.php$is_args$args;
        }

        proxy_connect_timeout 3600;
        proxy_send_timeout 3600;
        proxy_read_timeout 3600;
        send_timeout 3600;
        client_max_body_size 100M;

        location ~ "^\/([a-z0-9]{{28,32}})\.html" {
            add_header Content-Type text/plain;
            return 200 $1;
        }

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param REMOTE_ADDR $remote_addr;
            fastcgi_param HTTP_X_FORWARDED_FOR $http_x_forwarded_for;
            fastcgi_param HTTP_X_REAL_IP $http_x_real_ip;
            fastcgi_param HTTP_CF_CONNECTING_IP $http_cf_connecting_ip;
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_read_timeout 3600;
        }

        location ~* \.(jpg|jpeg|png|gif|ico|css|js|mp4|svg|woff|woff2|ttf)$ {
            expires 365d;
        }

        location ~* /(?:uploads|files)/.*.php$ {
            deny all;
        }

        location ~* /*.sql {
            deny all;
        }

        location ~* /.git/* {
            deny all;
        }
        location  ^~ /wp-cron.php {
               allow 127.0.0.1;
        }

        location ~ /\.ht {
                deny all;
        }

        location = /xmlrpc.php {
            deny all;
        }

        location ~ /\. {
            deny all;
        }
    }
EOF
cat /etc/nginx/sites-available/$SITE.conf


}



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

echo "SITE= $SITE  SQL_user= $SQL_user  SQL_db= $SQL_db  SQL_pass= $SQL_pass wp_pass= $wp_pass  wp_admin= $wp_admin"  >> /ar-src/list_USER_PASS_DB

mysql -u$SQL_root -p$SQL_root_pass -e "$SQL_create_user_db" 
mkdir -p $SITES_PATH/$SITE
chown -R www-data:www-data $SITES_PATH/$SITE


#cp /tmp/wp-cli.phar  $SITES_PATH/$SITE/ 
wp core download --path=$SITES_PATH/$SITE --locale=en_US --allow-root \
&& wp config create --path=$SITES_PATH/$SITE --dbname=$SQL_user --dbuser=$SQL_user --dbpass=$SQL_pass --dbhost=localhost --allow-root --skip-check \
&& wp core install --skip-email --url=$SITE --title=$SITE --admin_user=$wp_admin --admin_password=$SQL_pass --admin_email=$WP_EMAIL --allow-root --path=$SITES_PATH/$SITE

}



echo "===========================================================
Prepearing server:
------------------------------------------------------------"

read -r -p "Do you want first install infra? ? [y/N]  :" Yes_No 
if [[ "$Yes_No" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
	FIRST_install
else 
	echo "continue without prepearing"

fi


for listsite in ${listsites[*]}
do
echo -e "###################" $listsite "#####################\n"
SQLpass=$(echo "$(< /dev/urandom tr -dc _A-Z-a-z-0-9- | head -c30)_.=")
echo $SQLpass
SQLcreate $listsite $SQLpass


echo "===========================================================
Prepearing NGINX domains:
------------------------------------------------------------"
read -r -p "Do you want generate sites configs for $listsite ? [y/N]  : " Yes_No
if [[ "$Yes_No" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
        GENERATE_NGINX_CONF $listsite
else
        echo "continue without generate sites configs "
fi


done

ls -la $SITES_PATH
