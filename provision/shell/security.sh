#!/bin/bash
# Provision script for Ubuntu 16.04

# Setup firewall

# iptables-persistent + netfilter-persistent (rename)
apt-get -y install iptables-persistent
# TODO Missing cp
iptables-restore -t $SCRIPT_PATH/files/etc/iptables/rules.v4
ip6tables-restore -t $SCRIPT_PATH/files/etc/iptables/rules.v6
service netfilter-persistent reload
iptables -S
ip6tables -S

# Uninstall AppArmor (security Linux kernel module). Reason being, its security features can get
# in the way of legitimate applications operation.
service apparmor stop
update-rc.d -f apparmor remove
apt-get remove apparmor apparmor-utils

# Install RKHunter to Guard Against Rootkits
# Logs are stored in /var/log/rkhunter.log
# Note: Configure postfix as "Local Only" (installed through mailutils)
apt-get install binutils libreadline5 mailutils rkhunter
rkhunter --versioncheck
rkhunter --update
rkhunter --propupd
rkhunter -c --enable all --disable none

# Install Anti-Virus
apt-get install clamav clamav-daemon
freshclam
service clamav-daemon restart

# Install ModSecurity: a free web application firewall (WAF). 
# Rules for SQL injection, cross site scripting, Trojans, bad user agents, session hijacking and a lot of other exploits.
apt-get -y install libapache2-mod-security2
apachectl -M | grep --color security2 # Verify if running. Should output: security2_module (shared)
mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
service apache2 reload
# Logs stored in /var/log/apache2/modsec_audit.log
# Out of the box, ModSecurity doesn't do anything because it needs rules to work
sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf
sed -i "s/SecResponseBodyAccess On/SecResponseBodyAccess Off/" /etc/modsecurity/modsecurity.conf
# Missing config file: /etc/apache2/mods-enabled/security2.conf
cd /usr/share/modsecurity-crs/base_rules/
for f in * ; do ln -s /usr/share/modsecurity-crs/base_rules/$f /usr/share/modsecurity-crs/activated_rules/$f ; done
cd $SCRIPT_PATH
a2enmod headers security2
service apache2 reload
# Test if mod_security is working: go to http|s://{your-domain}/?abc=../../. You should receive "Access Denied" and see it in the log.

# Setup cronjobs
crontab $SCRIPT_PATH/files/cronjobs/main.jobs
