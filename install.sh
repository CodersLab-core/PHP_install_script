#!/usr/bin/env bash
 
echo
echo "Witaj w Coders Lab!"
echo
echo "Ten skrypt zaktualizuje Twój system, zainstaluje kilka niezbędnych programów,"
echo "których będziesz potrzebować podczas kursu oraz skonfiguruje bazę danych MySQL."
echo "W tym czasie na ekranie pojawi się wiele komunikatów."
echo "ABY INSTALACJA SIĘ POWIODŁA MUSISZ MIEĆ DOSTĘP DO INTERNETU W TRAKCIE TRWANIA "
echo "INSTALACJI!"
read -n1 -r -p "Naciśnij dowolny klawisz, by kontynuować." 

mkdir ~/.coderslab

linuxsysversion=$(lsb_release -rs)

echo "Twoje wersja systemu:"
echo $linuxsysversion
 
if [[ `lsb_release -rs` != "18.04" ]]
then
    echo "Twoje wersja systemu jest niezgodna z wymaganą 18.04"
    exit 1
fi 
 
# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='coderslab'
HOSTNAME='student.edu'

#pausing updating grub as it might triger ui
sudo apt-mark hold grub*

#add ppa for phpmyadmin
sudo add-apt-repository -y ppa:nijel/phpmyadmin

#add ppa for tlp
sudo add-apt-repository -y ppa:linrunner/tlp

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade
 
#install all used tools
sudo apt-get install -y curl vim git

#install tlp
sudo apt-get install -y tlp tlp-rdw tp-smapi-dkms acpi-call-dkms
 
#install apache2
sudo apt-get install -y apache2
 
# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get install -y mysql-server
 
#install php7 and libs
sudo apt-get install -y php php-mysql php-curl php-gd php-json php-cgi php-cli php-soap
sudo apt-get install -y libapache2-mod-php

#install xdebug
sudo apt-get install -y php-xdebug
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
echo "${XDEBUG}" | sudo tee -a /etc/php/7.2/apache2/php.ini
echo "${XDEBUG}" | sudo tee -a /etc/php/7.2/cli/php.ini

#setup php.ini files
sudo sed -i '/error_reporting = /c\error_reporting = E_ALL' /etc/php/7.2/apache2/php.ini
sudo sed -i '/display_errors = /c\display_errors = On' /etc/php/7.2/apache2/php.ini
sudo sed -i "s/^;date.timezone =$/date.timezone = \"Europe\/Warsaw\"/" /etc/php/7.2/apache2/php.ini
sudo sed -i "s/^;date.timezone =$/date.timezone = \"Europe\/Warsaw\"/" /etc/php/7.2/cli/php.ini

#install papmyadmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get install -y phpmyadmin php-mbstring php-gettext
sudo phpenmod mcrypt
sudo phpenmod mbstring

sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin.conf
sudo service apache2 reload

# install Composer
sudo curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
 
#install symfony2
sudo curl -LsS http://symfony.com/installer -o /usr/local/bin/symfony
sudo chmod a+x /usr/local/bin/symfony

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html"
    <Directory "/var/www/html">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" | sudo tee /etc/apache2/sites-available/000-default.conf

# install postfix
sudo debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo apt-get install -y postfix

#creating and linkng Workspace
sudo mkdir ~/Workspace
sudo chmod 777 ~/Workspace
sudo rm -r /var/www/html
sudo ln -s ~/Workspace /var/www/html
sudo chmod 777 -R ~/Workspace

#update and upgrade all packages
sudo apt-get update -y
sudo apt-get upgrade -y

#restart apache
sudo systemctl restart apache2

echo "Twój użytkownik to $USER"
echo "Dodaję użytkownika do grupy www-data"

#add current user to www-data group
sudo usermod -a -G www-data $USER
read -n1 -r -p "Naciśnij dowolny klawisz, by kontynuować." 

sudo snap install phpstorm --classic

DESKTOP=$(cat <<EOF
[Desktop Entry]
Name=PhpStorm
Comment=IDE używane podczas kursu w Coders Lab
Exec=/snap/bin/phpstorm
Terminal=false
Type=Application
StartupNotify=true
Categories=Utility;Application
EOF
)
touch ~/.coderslab/PhpStorm.desktop
echo "${DESKTOP}" > ~/.coderslab/PhpStorm.desktop
sudo cp ~/.coderslab/phpstorm.desktop /usr/share/applications/PhpStorm.desktop
rm ~/.coderslab/PhpStorm.desktop

#unpausing updating grub
sudo apt-mark unhold grub*

echo "INSTALACJA ZAKOŃCZONA"
echo "WYLOGUJ I PONOWNIE ZALOGUJ SIĘ NA SWOJE KONTO"

