#!/bin/bash

echo "Hostname : $1"

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

# Uninstall AppArmor (security Linux kernel module). Reason being, its security features can get
# in the way of legitimate applications operation.
service apparmor stop
update-rc.d -f apparmor remove
apt-get --purge remove apparmor apparmor-utils libapparmor-perl libapparmor1

# Install RKHunter to Guard Against Rootkits
# Logs are stored in /var/log/rkhunter.log
# Note: Configure postfix as "Local Only" (installed through mailutils)
#apt-get install binutils libreadline5 mailutils rkhunter
#rkhunter --versioncheck
#rkhunter --update
#rkhunter --propupd
#rkhunter -c --enable all --disable none

# Install Anti-Virus
#apt-get install clamav clamav-daemon
#freshclam
#service clamav-daemon restart

# Install ModSecurity
# TODO

# Install MySQL 5.6
# Luckily MySql 5.6 is available in the default repositories.
apt-get install mysql-server-5.6
mysql --version

# Install Apache 2 
apt-get -y install apache2 apache2-mpm-worker libapache2-mod-fastcgi
service apache2 start

# Install PHP 5.6
add-apt-repository ppa:ondrej/php
apt-get -y update
apt-get -y install php5-fpm
php5 -v

# Install some PHP extensions
apt-get -y install php5-cli php5-common php5-curl php5-gd php5-intl php5-json php5-mcrypt php5-memcached php5-mysqlnd php5-xmlrpc
php5enmod opcache mcrypt

# @note PHP 5.5 ships with its own built-in opcache.


# Configure everything

mkdir /var/www/cgi-bin
mkdir /var/www/.socks

cp -R files/var/www/default /var/www/ 
chown -R vagrant:vagrant /var/www/default
chmod -R 755 /var/www/default

mv /etc/apache2/mods-available/fastcgi.conf /etc/apache2/mods-available/fastcgi.conf.orig
cp files/etc/apache2/mods-available/fastcgi.conf /etc/apache2/mods-available/fastcgi.conf

#mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig
#cp files/etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf
cp files/etc/php5/fpm/pool.d/default.conf /etc/php5/fpm/pool.d/default.conf
cp files/etc/apache2/sites-available/default.conf /etc/apache2/sites-available/default.conf

# Replace any hostname variables in virtual directories
find /etc/apache2/sites-available/ -type f -exec sed -i "s/{hostname}/$1/g" {} +

# Enable mods : fastcgi & php5-fpm
a2enmod actions fastcgi alias rewrite ssl include

# Enable site(s)
a2ensite default

service php5-fpm restart
service apache2 restart

# Instal ProFTP
apt-get install proftpd
# TODO Copy over config
service proftpd restart

# Install composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Setup cronjobs
crontab files/cronjobs/main.jobs
