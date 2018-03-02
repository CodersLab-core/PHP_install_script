#!/usr/bin/env bash

echo
echo "Witaj w CodersLab!"
echo
echo "Ten skrypt zaktualizuje Twój system, zainstaluje kilka niezbędnych programów,"
echo "których będziesz potrzebować podczas kursu oraz skonfiguruje bazę danych MySQL."
echo "W tym czasie na ekranie pojawi się wiele komunikatów."
echo "ABY INSTALACJA SIĘ POWIODŁA MUSISZ MIEĆ DOSTĘP DO INTERNETU W TRAKCIE TRWANIA "
echo "INSTALACJI!"
read -n1 -r -p "Naciśnij dowolny klawisz, by kontynuować."

echo
echo "Instaluję narzędzia konsolowe..."
# install Command Line Tools for Xcode
xcode-select --install


echo
echo "Instaluję homebrew..."
# install brew package manager
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo
echo "Dodaje niezbędne repozytoria homebrew..."
# add external taps
#brew tap homebrew/dupes #deprecated
#brew tap homebrew/versions #deprecated
brew tap homebrew/php

echo
echo "Instaluję curl, vim, git, mc oraz wget..."
#install all used tools
brew tap caskroom/cask
#brew install caskroom/cask/brew-cask #deprecated

brew install curl vim git mc wget

brew install brew-cask-completion
brew cask install java

echo
echo "Usuwam apache - jeśli istnieje..."
# install clean apache from brew tap
sudo apachectl stop
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist

echo
echo "Instaluję php 7.0..."
# install php 7.0
brew install --without-mssql --without-httpd22 --without-httpd24 php70
mkdir -p ~/Library/LaunchAgents
ln -sfv /usr/local/opt/php70/homebrew.mxcl.php70.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist

echo
echo "Instaluję MySQL 5.7..."
# install mysql 5.7
brew install mysql
ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist

echo
echo "Instaluję phpmyadmina..."
# install phpmyadmin in /usr/local/share/phpmyadmin

brew install autoconf
brew install phpmyadmin

echo
echo "Instaluję nginx..."
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
#sudo mkdir -p /var/www
#sudo chown :staff /var/www
#sudo chmod 775 /var/www

rm /usr/local/etc/nginx/nginx.conf

echo
echo "Tworzę katalog Workspace"
mkdir ~/Workspace
chmod 777 ~/Workspace
sudo ln -s ~/Workspace /var/www

echo
echo "Dodaję plik phpinfo.php..."
touch ~/Workspace/phpinfo.php
PHPINFO=$(cat <<EOF
<?php
phpinfo();
EOF
)

echo "${PHPINFO}" >> /var/www/phpinfo.php
echo
echo "Dodaję plik test_error.php..."
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
echo "Dodaję konfigurację nginx..."

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
echo "Dodaję konfigurację php-fpm..."
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
echo "Tworzę domyślny host..."
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
        autoindex on;
        include   /usr/local/etc/nginx/conf.d/php-fpm;
    }
}
EOF
)

echo "${NGINXDEFAULT}" >> /usr/local/etc/nginx/sites-available/default

echo
echo "Aktywuję domyślny host..."
# enable default
ln -sfv /usr/local/etc/nginx/sites-available/default /usr/local/etc/nginx/sites-enabled/default

sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

echo
echo "Instaluję xdebug..."
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
sudo echo "${XDEBUG}" >> /usr/local/etc/php/7.0/php.ini

echo
echo "Ustawiam strefę czasową dla php..."
#setup php.ini files
sudo sed -i -e "s/;date.timezone =/date.timezone = Europe\/Warsaw/" /usr/local/etc/php/7.0/php.ini


echo
echo "Instaluję Composera..."
# install Composer
cd /tmp
sudo curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

echo
echo "Instaluję Symfony..."
#install symfony2
sudo curl -LsS http://symfony.com/installer -o /usr/local/bin/symfony
sudo chmod a+x /usr/local/bin/symfony

echo
echo "Aktualizuję paczki homebrew..."
#update and upgrade all packages
brew update
brew upgrade

echo
echo "Restartuję nginx..."
#restart nginx
sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

echo
echo "Restart php-fpm..."
# restart php-fpm
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php70.plist

echo
echo "Zmieniam hasło root dla MySQL na coderslab..."
mysqladmin -u root password coderslab

echo
echo "Tworzę skróty do sterowania nginx, php-fpm oraz mysql..."

# add bash aliases for start/stop nginx/php-fpm/mysql

BASH_ALIASES=$(cat <<EOF
#only for macOS
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
echo "${BASH_ALIASES}" >> ~/.bash_profile

echo
echo "Dodaję uzytkownika do grupy www-data..."

sudo dseditgroup -o edit -a $USER -t user www-data

echo "#############################"
echo "####INSTALACJA ZAKOŃCZONA####"
echo "#############################"
echo "SPRAWDŹ JEJ POPRAWNOŚĆ WYKONUJĄC KROKI PRZEDSTAWIONE NA PREZENTACJI"
