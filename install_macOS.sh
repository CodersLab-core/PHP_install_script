#!/usr/bin/env bash

# install Command Line Tools for Xcode
xcode-select --install

# install brew package manager
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

#install all used tools
brew install curl vim git mc wget

# add external taps
brew tap homebrew/dupes
brew tap homebrew/versions
brew tap homebrew/php
#brew tap homebrew/apache

# install clean apache from brew tap
sudo apachectl stop
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
#brew install httpd24 --with-privileged-ports --with-http2

# install php 7.0
brew install --without-mssql --without-httpd22 --without-httpd24 php70
mkdir -p ~/Library/LaunchAgents
ln -sfv /usr/local/opt/php70/homebrew.mxcl.php70.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist

# install mysql 5.7
brew install mysql
ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
mysqladmin -u root password coderslab

# install phpmyadmin in /usr/local/share/phpmyadmin

brew install autoconf
brew install phpmyadmin

#install nginx

brew install nginx
sudo cp -v /usr/local/opt/nginx/*.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

mkdir -p /usr/local/etc/nginx/logs
mkdir -p /usr/local/etc/nginx/sites-available
mkdir -p /usr/local/etc/nginx/sites-enabled
mkdir -p /usr/local/etc/nginx/conf.d
mkdir -p /usr/local/etc/nginx/ssl
sudo mkdir -p /var/www
sudo chown :staff /var/www
sudo chmod 775 /var/www

rm /usr/local/etc/nginx/nginx.conf

touch /var/www/phpinfo.php
PHPINFO=$(cat <<EOF
<?php
phpinfo();
EOF
)

echo "${PHPINFO}" >> /var/www/phpinfo.php

touch /var/www/test_error.php
PHPERROR=$(cat <<EOF
<?php
$hello = 'Hi';
echo $hello . ' John';
echo Mark;
EOF
)

echo "${PHPINFO}" >> /var/www/test_error.php

NGINXCONF=$(cat <<EOF
worker_processes  1;

error_log  /usr/local/etc/nginx/logs/error.log debug;

events {
    worker_connections  1024;
}

http {
    include             mime.types;
    default_type        application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /usr/local/etc/nginx/logs/access.log  main;

    sendfile            on;

    keepalive_timeout   65;

    index index.html index.php;

    include /usr/local/etc/nginx/sites-enabled/*;
}
EOF
)

touch /usr/local/etc/nginx/nginx.conf
echo "${NGINXCONF}" >> /usr/local/etc/nginx/nginx.conf

PHPFPM=$(cat <<EOF
location ~ \.php$ {
    try_files      \$uri = 404;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}
EOF
)

touch /usr/local/etc/nginx/conf.d/php-fpm
echo "${PHPFPM}" >> /usr/local/etc/nginx/conf.d/php-fpm

NGINXDEFAULT=$(cat <<EOF
server {
    listen       80;
    server_name  localhost;
    root       /var/www/;

    access_log  /usr/local/etc/nginx/logs/default.access.log  main;

    location /phpmyadmin {
        root    /usr/local/share;

        error_log /usr/local/etc/nginx/logs/phpmyadmin.error.log;
        access_log  /usr/local/etc/nginx/logs/phpmyadmin.access.log main;

        include   /usr/local/etc/nginx/conf.d/php-fpm;
    }

    location / {
        include   /usr/local/etc/nginx/conf.d/php-fpm;
    }
}
EOF
)

echo "${NGINXDEFAULT}" >> /usr/local/etc/nginx/sites-available/default

# enable default and phpmyadmin
ln -sfv /usr/local/etc/nginx/sites-available/default /usr/local/etc/nginx/sites-enabled/default

sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

#install xdebug

brew install php70-xdebug
XDEBUG=$(cat <<EOF
[xdebug]
xdebug.remote_enable=1
xdebug.remote_handler=dbgp
xdebug.remote_host=127.0.0.1
xdebug.remote_port=9000
xdebug.remote_autostart=0
xdebug.remote_connect_back=0
EOF
)
echo "${XDEBUG}" >> /usr/local/etc/php/7.0/php.ini

# restart php-fpm
sudo launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist
sudo launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist

#setup php.ini files
sed -i -e "s/;date.timezone =/date.timezone = Europe\/Warsaw" /usr/local/etc/php/7.0/php.ini

# install Composer
cd /tmp
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#install symfony2
sudo curl -LsS http://symfony.com/installer -o /usr/local/bin/symfony
sudo chmod a+x /usr/local/bin/symfony

#update and upgrade all packages
brew update
brew upgrade

#restart nginx
sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

# add bash aliases for start/stop nginx/php-fpm/mysql

BASH_ALIASES=$(cat <<EOF
alias nginx.start='sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist'
alias nginx.stop='sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist'
alias nginx.restart='nginx.stop && nginx.start'
alias php-fpm.start="launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist"
alias php-fpm.stop="launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist"
alias php-fpm.restart='php-fpm.stop && php-fpm.start'
alias mysql.start="launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist"
alias mysql.stop="launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist"
alias mysql.restart='mysql.stop && mysql.start'
EOF
)

echo ${BASH_ALIASES} >> ~/.bash_profile && . ~/.bash_profile

echo "INSTALACJA UDANA, SPRAWDŹ JEJ POPRAWNOŚĆ WYKONUJĄC KROKI PRZEDSTAWIONE NA PREZENTACJI"