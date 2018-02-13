#!/bin/bash

SCRIPT_PATH="/vagrant/provision/shell"

# ---------------------------------------
#          Filewall Setup
# ---------------------------------------

# iptables-persistent + netfilter-persistent (rename)
apt-get install -y iptables-persistent
iptables-restore -t $SCRIPT_PATH/files/iptables/rules.v4
ip6tables-restore -t $SCRIPT_PATH/files/iptables/rules.v6
service netfilter-persistent reload
iptables -S
ip6tables -S

# ---------------------------------------
#          AppArmor Purge
# ---------------------------------------

# Uninstall AppArmor (security Linux kernel module). Reason being, its security features can get
# in the way of legitimate applications operation.
service apparmor stop
update-rc.d -f apparmor remove
apt-get remove apparmor apparmor-utils

# ---------------------------------------
#          RootKit Guard Setup
# ---------------------------------------

# Install RKHunter to Guard Against Rootkits
# Logs are stored in /var/log/rkhunter.log
# Note: Configure postfix as "Local Only" (installed through mailutils)
apt-get install -y binutils libreadline5 mailutils rkhunter
rkhunter --versioncheck
rkhunter --update
rkhunter --propupd
rkhunter -c --enable all --disable none

cat > ~/security.jobs << EOF
0 0 * * * /usr/bin/rkhunter --cronjob --update --quiet
EOF

crontab ~/security.jobs

# ---------------------------------------
#          Anti-Virus Setup
# ---------------------------------------

# Install packages.
apt-get install -y clamav clamav-daemon
freshclam
service clamav-daemon restart

# Install ModSecurity: a free web application firewall (WAF). 
# Rules for SQL injection, cross site scripting, Trojans, bad user agents, session hijacking and a lot of other exploits.
apt-get install -y libapache2-mod-security2
apachectl -M | grep --color security2 # Verify if running. Should output: security2_module (shared)
mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
service apache2 reload
# Logs stored in /var/log/apache2/modsec_audit.log
# Out of the box, ModSecurity doesn't do anything because it needs rules to work
sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf
sed -i "s/SecResponseBodyAccess On/SecResponseBodyAccess Off/" /etc/modsecurity/modsecurity.conf
# Missing config file: /etc/apache2/mods-enabled/security2.conf
for f in /usr/share/modsecurity-crs/base_rules/* ; do ln -s /usr/share/modsecurity-crs/base_rules/$f /usr/share/modsecurity-crs/activated_rules/$f ; done
a2enmod headers security2
service apache2 reload
# Test if mod_security is working: go to http|s://{your-domain}/?abc=../../. You should receive "Access Denied" and see it in the log.
