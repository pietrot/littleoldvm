#!/bin/bash
#
# NOTES
# apt-cache search {some-string}

# ---------------------------------------
#          Virtual Machine Setup
# ---------------------------------------

if [ -z "$1" ]
then
    HOSTNAME="littleoldvm"
else
    HOSTNAME="$1"
fi

SCRIPT_PATH="/vagrant/provision/shell"

USERNAME="vagrant"
USERGROUP="vagrant"

# Install repositories.
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/apache2
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php # Most requested extensions (supports php 7.0).

# Update VM & add some needed apps & dependencies.
apt-get -y update
apt-get -y --allow-unauthenticated upgrade
apt-get -y --allow-unauthenticated install wget vim git curl htop tmux ruby python-software-properties

# Setup locale.
apt-get -y --allow-unauthenticated install language-pack-en-base
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Synchronize the System Clock.
apt-get -y --allow-unauthenticated install ntp ntpdate

# ---------------------------------------
#          MySQL Setup
# ---------------------------------------

# Setting MySQL root user password root/root.
debconf-set-selections <<< 'mysql-server mysql-server/root_password password littleoldvm'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password littleoldvm'

# Install MySQL 5.7.
# Luckily MySql 5.7 is available in the default repositories. 5.7 IS NOT BACKWARD COMPATIBLE.
# Ensure to enter a root password otherwise a temporary one is created - 5.7 requirement.
apt-get install -y --allow-unauthenticated mysql-server mysql-client
mysql --version

# ---------------------------------------
#          Apache Setup
# ---------------------------------------

# Install packages.
apt-get install -y --allow-unauthenticated apache2

# See available mods.
#ll /etc/apache2/mods-available | grep proxy

# Install mods.
# https://wiki.apache.org/httpd/PHP-FPM
apt-get install -y --allow-unauthenticated mod_proxy proxy mod_proxy_fcgi

# Enable mods.
a2enmod actions alias rewrite ssl include headers setenvif proxy_fcgi

# Trigger changes.
service apache2 restart

# ---------------------------------------
#          PHP Setup
# ---------------------------------------

# Install packages.
apt-get install -y --allow-unauthenticated php7.0 php7.0-fpm
php -v

sed -i "s/user =.*/user = $USERNAME/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/group =.*/group = $USERGROUP/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/listen =.*/listen = \/var\/run\/php7.0-fpm.sock/" /etc/php/7.0/fpm/pool.d/www.conf

# Install extensions.
apt-get install -y --allow-unauthenticated php7.0-cli php7.0-common php7.0-curl php7.0-gd php7.0-intl php7.0-json php7.0-mcrypt php-memcached php7.0-xmlrpc php7.0-zip php7.0-mbstring php7.0-xml php7.0-mysql
phpenmod zip mbstring

# Trigger changes.
a2enconf php7.0-fpm
service php7.0-fpm restart
service apache2 restart

# ---------------------------------------
#          Default Website Setup
# ---------------------------------------

mkdir -p /var/www/default/public

cat > /var/www/default/public/index.php << EOF
<?php phpinfo();
EOF

chown -R $USERNAME:$USERGROUP /var/www/default
chmod -R 755 /var/www/default

cat > /etc/apache2/sites-available/default.conf << EOF
<VirtualHost *:80>

    ServerName $HOSTNAME.test
    ServerAlias *.$HOSTNAME.test
    
    ServerAdmin webmaster@$HOSTNAME.test
    
    DocumentRoot /var/www/default/public

    <Directory "/var/www/default/public">
        # Apache 2.2
        # Order allow,deny
        # allow from all
        
        # Apache 2.4
        Require all granted
        
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>
    
    <FilesMatch \.php$>
        # 2.4.10+ can proxy to unix socket
        SetHandler "proxy:unix:/var/run/php7.0-fpm.sock|fcgi://localhost/"

        # Else we can just use a tcp socket:
        #SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>

    # Logs    
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    # Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
    LogLevel warn

</VirtualHost>
EOF

# Enable virtual host & trigger changes.
a2ensite default
service apache2 restart

# ---------------------------------------
#          Redis Setup
# ---------------------------------------

# Install packages.
apt-get install -y --allow-unauthenticated redis-server

# Install NodeJS & NPM.
apt-get install -y --allow-unauthenticated nodejs nodejs-legacy npm

# Install composer.
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
