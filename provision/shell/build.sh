#!/bin/bash
# Provision script for Ubuntu 16.04

# TOOLS
# apt-cache search {some-string}

#HOSTNAME="$1"
HOSTNAME="littleoldvm"
SCRIPT_PATH="/vagrant/provision/shell"

# Update VM & add some needed apps & dependencies
apt-get -y update
apt-get -y upgrade
apt-get -y install wget vim git curl htop tmux ruby python-software-properties

# Setup locale
apt-get -y install language-pack-en-base
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Synchronize the System Clock
apt-get -y install ntp ntpdate

# Install MySQL 5.7
# Luckily MySql 5.7 is available in the default repositories. 5.7 IS NOT BACKWARD COMPATIBLE
#apt-get install mysql-server
apt-get install software-properties-common
add-apt-repository -y ppa:ondrej/mysql-5.6
apt-get update
apt-get install mysql-server-5.6
mysql --version

# Install Apache 2 
# The mpm_worker module is included by default when you install Apache on 16.04
apt-get -y install apache2 libapache2-mod-fastcgi
service apache2 start

# Install PHP 5.6
add-apt-repository ppa:ondrej/php
apt-get -y update
apt-get -y install php5.6-fpm
a2enmod proxy_fcgi setenvif
a2enmod php5.6-fpm
php5 -v

# On Ubuntu 16+ package installs both php5.6 & php5.7. REMOVE php5.7
apt-get purge php7.*

# Install some PHP extensions
apt-get -y install php5.6-cli php5.6-common php5.6-curl php5.6-gd php5.6-intl php5.6-json php5.6-mcrypt php5.6-memcached php5.6-mysqlnd php5.6-xmlrpc php5.6-zip php5.6-mbstring php5.6-xml
phpenmod zip mbstring

# @note PHP 5.5 ships with its own built-in opcache.

# Install redis
apt-get install redis-server

# Configure everything

mkdir /var/www/cgi-bin
mkdir /var/www/.socks

cp -R $SCRIPT_PATH/files/var/www/default /var/www/ 
#chown -R vagrant:vagrant /var/www/default
chown -R www-data:www-data /var/www/default
chmod -R 755 /var/www/default

mv /etc/apache2/mods-available/fastcgi.conf /etc/apache2/mods-available/fastcgi.conf.orig
cp $SCRIPT_PATH/files/etc/apache2/mods-available/fastcgi.conf /etc/apache2/mods-available/fastcgi.conf

#mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig
#cp files/etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf
cp $SCRIPT_PATH/files/etc/php/5.6/fpm/pool.d/default.conf /etc/php/5.6/fpm/pool.d/default.conf
cp $SCRIPT_PATH/files/etc/apache2/sites-available/default.conf /etc/apache2/sites-available/default.conf

# Replace any hostname variables in virtual directories
find /etc/apache2/sites-available/ -type f -exec sed -i "s/{hostname}/$1/g" {} +

# Enable mods : fastcgi & php5-fpm
a2enmod actions fastcgi alias rewrite ssl include

# Enable site(s)
a2ensite default

service php5.6-fpm restart
service apache2 restart

# Instal ProFTP
apt-get install proftpd

apt-get -y install vsftpd
cp /etc/vsftpd.conf /etc/vsftpd.conf.orig

# TODO Copy over config
service proftpd restart

# Install composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Setup cronjobs
crontab $SCRIPT_PATH/files/cronjobs/main.jobs
