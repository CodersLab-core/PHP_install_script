#!/usr/bin/env bash

echo
echo "Hello!"
echo
echo "This script will update your system, and it will install all software needed during course."
echo "During instalation process you will see lots of information on screen - do not worry about that."
echo "For instalation process to succeed you have to have internet connection all the time. "
read -n1 -r -p "Press any key to continue." 

echo
echo "Installing Xcode..."
# install Command Line Tools for Xcode
xcode-select --install


echo
echo "Installing homebrew..."
# install brew package manager
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo
echo "Adding homebrew repositories..."
# add external taps
#brew tap homebrew/dupes #deprecated
#brew tap homebrew/versions #deprecated
#brew tap homebrew/php
brew tap homebrew/services

echo
echo "Installing curl, vim, git, mc and wget..."
#install all used tools
brew tap caskroom/cask
#brew install caskroom/cask/brew-cask #deprecated

brew install curl vim git mc wget

brew install brew-cask-completion
brew cask install java
#brew install phpize

echo
echo "Removing apache - if installed previously..."
# install clean apache from brew tap
sudo apachectl stop
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist

echo
echo "Installing php 7.1..."
# install php 7.1
brew install --without-mssql --without-httpd22 --without-httpd24 php71
mkdir -p ~/Library/LaunchAgents
ln -sfv /usr/local/opt/php@7.1/homebrew.mxcl.php@7.1.plist ~/Library/LaunchAgents
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php@7.1.plist

echo
echo "Installing MySQL 5.7..."
# install mysql 5.7
brew install mysql
ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist

echo
echo "Fixing mysql socket"
sudo mkdir /var/mysql
sudo ln -s /tmp/mysql.sock /var/mysql/mysql.sock

echo
echo "Installing nginx..."
#install nginx

brew install nginx
sudo cp -v /usr/local/opt/nginx/*.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

echo
echo "Configuring nginx..."
sudo chown root:wheel /usr/local/opt/nginx-full/bin/nginx
sudo chmod u+s /usr/local/opt/nginx-full/bin/nginx

sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

mkdir -p /usr/local/etc/nginx/logs
mkdir -p /usr/local/etc/nginx/sites-available
mkdir -p /usr/local/etc/nginx/sites-enabled
mkdir -p /usr/local/etc/nginx/conf.d
mkdir -p /usr/local/etc/nginx/ssl
#sudo mkdir -p /var/www
#sudo chown :staff /var/www
#sudo chmod 775 /var/www

rm /usr/local/etc/nginx/nginx.conf

echo
echo "Creating Workspace"
mkdir ~/Workspace
chmod 777 ~/Workspace
sudo ln -s ~/Workspace /var/www


echo
echo "Installing phpmyadmina..."
# install phpmyadmin in /usr/local/share/phpmyadmin

cd /tmp
wget https://files.phpmyadmin.net/phpMyAdmin/4.8.1/phpMyAdmin-4.8.1-all-languages.zip
unzip phpMyAdmin-4.8.1-all-languages.zip
mv phpMyAdmin-4.8.1-all-languages ~/Workspace/phpmyadmin


echo
echo "Adding phpinfo.php..."
touch ~/Workspace/phpinfo.php
PHPINFO=$(cat <<EOF
<?php
phpinfo();
EOF
)

echo "${PHPINFO}" >> /var/www/phpinfo.php
echo
echo "Adding test_error.php..."
touch ~/Workspace/test_error.php
PHPERROR=$(cat <<EOF
<?php
\$hello = 'Hi';
echo \$hello . ' John';
echo Mark;
EOF
)

echo "${PHPERROR}" >> /var/www/test_error.php

echo
echo "Configuring nginx..."

NGINXCONF=$(cat <<EOF
worker_processes  1;

error_log  /usr/local/etc/nginx/logs/error.log debug;

events {
    worker_connections  1024;
}

http {
    include             mime.types;
    default_type        application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

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

echo
echo "Configuring php-fpm..."
PHPFPM=$(cat <<EOF
location ~ [^/]\.php(/|\$) {
    fastcgi_split_path_info ^(.+?\.php)(/.*)\$;
    if (!-f \$document_root\$fastcgi_script_name) {
        return 404;
    }
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_param  PATH_INFO \$fastcgi_path_info;
    include        fastcgi_params;
}
EOF
)

touch /usr/local/etc/nginx/conf.d/php-fpm
echo "${PHPFPM}" >> /usr/local/etc/nginx/conf.d/php-fpm

echo
echo "Adding dewfault host..."
NGINXDEFAULT=$(cat <<EOF
server {
    listen       80;
    server_name  localhost;
    root       /var/www/;

    access_log  /usr/local/etc/nginx/logs/default.access.log  main;

    location / {
        autoindex on;
        include   /usr/local/etc/nginx/conf.d/php-fpm;
    }
}
EOF
)

echo "${NGINXDEFAULT}" >> /usr/local/etc/nginx/sites-available/default

echo
echo "Activating default host..."
# enable default
ln -sfv /usr/local/etc/nginx/sites-available/default /usr/local/etc/nginx/sites-enabled/default

sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

echo
echo "Installing xdebug..."
#install xdebug

cd /tmp
wget https://xdebug.org/files/xdebug-2.7.0alpha1.tgz
tar -xvzf xdebug-2.7.0alpha1.tgz
cd xdebug-2.7.0alpha1
phpize
./configure
make
cp modules/xdebug.so /usr/local/opt/php@7.1

XDEBUG=$(cat <<EOF
zend_extension = /usr/local/opt/php@7.1/xdebug.so

[xdebug]
xdebug.remote_enable=1
xdebug.remote_handler=dbgp
xdebug.remote_host=127.0.0.1
xdebug.remote_port=9000
xdebug.remote_autostart=0
xdebug.remote_connect_back=0
EOF
)
sudo echo "${XDEBUG}" >> /usr/local/etc/php/7.1/php.ini

echo
echo "Setting timezone for php..."
#setup php.ini files
sudo sed -i -e "s/;date.timezone =/date.timezone = Europe\/Warsaw/" /usr/local/etc/php/7.1/php.ini


echo
echo "Installing Composera..."
# install Composer
cd /tmp
sudo curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

echo
echo "Installing Symfony..."
#install symfony
sudo curl -LsS http://symfony.com/installer -o /usr/local/bin/symfony
sudo chmod a+x /usr/local/bin/symfony

echo
echo "Updating homebrew..."
#update and upgrade all packages
brew update
brew upgrade

echo
echo "Restarting nginx..."
#restart nginx
sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

echo
echo "Restarting php-fpm..."
# restart php-fpm
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php@7.1.plist
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php@7.1.plist

echo
echo "Changing root paswor for mySQL database. New password: coderslab..."
mysqladmin -u root password 'coderslab'

echo
echo "Adding bash aliases for start/stop nginx/php-fpm/mysql..."

# add bash aliases for start/stop nginx/php-fpm/mysql

BASH_ALIASES=$(cat <<EOF
#only for macOS
alias nginx.start='sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist'
alias nginx.stop='sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist'
alias nginx.restart='nginx.stop && nginx.start'
alias php-fpm.start="launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php@7.1.plist"
alias php-fpm.stop="launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php@7.1.plist"
alias php-fpm.restart='php-fpm.stop && php-fpm.start'
alias mysql.start="launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist"
alias mysql.stop="launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist"
alias mysql.restart='mysql.stop && mysql.start'
EOF
)
echo "${BASH_ALIASES}" >> ~/.bash_profile

#echo
#echo "Dodaję uzytkownika do grupy www-data..."

#sudo dseditgroup -o edit -a $USER -t user www-data

echo "#############################"
echo "#### Instalation finised ####"
echo "#############################"
