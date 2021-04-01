#!/bin/bash

(

set -x

RHN_ACCOUNT=THEACCOUNT
RHN_PASSWORD=THEPASSWORD
cd /tmp
curl "https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz" | tar xz
cd ansible-tower*
mv inventory inventory.bak
cat << 'EOF' >inventory
[tower]
localhost ansible_connection=local

[database]

[all:vars]
admin_password='Password1'

pg_host=''
pg_port=''

pg_database='awx'
pg_username='awx'
pg_password='Password1'
EOF
./setup -i inventory 


sed -i  -e 's/PasswordAuthentication no/PasswordAuthentication yes/1' /etc/ssh/sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.redhat
systemctl restart sshd
cat << 'EOF' >/bin/restoremyssh
rm -rf /etc/ssh/sshd_config
cp /etc/ssh/sshd_config.redhat /etc/ssh/sshd_config
systemctl restart sshd.service
EOF
chmod +x /bin/restoremyssh

#fix for ansible broken winrm
dnf install python3-pip -y
pip3 install pywinrm
cp -r /usr/local/lib/python3.6/site-packages/* /usr/lib/python3.6/site-packages/

# Set dns=none for NetworkManager which then do not break the next step by overwring the resolv.conf
sed -i -e "s/\[main\]/\[main\]\\ndns=none/" /etc/NetworkManager/NetworkManager.conf
systemctl restart NetworkManager

#This sets the Active directory domain controller as primary DNS
DNSIP=ADIPADDRESS
#sed -i -e "s/# Generated by NetworkManager/nameserver $DNSIP/g" /etc/resolv.conf
sed -i -e "s/nameserver/nameserver $DNSIP\\nnameserver/1" /etc/resolv.conf

#prep for lab 6
sed -i 's/iburst/ibarst/g' /etc/chrony.conf
systemctl restart chronyd  >/dev/null 2>&1

#protect ourselfs from network outages
LOOP=0
while true; do
        ping -c1 subscription.rhn.redhat.com >/dev/null
        if [ "$?" -eq 0 ]; then
                echo "We can reach Red Hat Network"
                break
        else
                LOOP=$(expr $LOOP +1)
                if [ "$LOOP" -eq 120 ]; then
                        echo "We've waited for 2 minutes... exiting."
                        exit 1
                fi
        fi
done

subscription-manager register --username=$RHN_ACCOUNT --password=$RHN_PASSWORD --force --auto-attach
if [ "$?" -ne 0 ]; then
        sleep 5
        subscription-manager register --username=$RHN_ACCOUNT --password=$RHN_PASSWORD --force --auto-attach
        if [ "$?" -ne 0 ]; then
                sleep 5
                subscription-manager register --username=$RHN_ACCOUNT --password=$RHN_PASSWORD --force --auto-attach
                if [ "$?" -eq 0 ]; then
                        rm -f /etc/yum.repos.d/*rhui*
                else
                        echo "I tried 3 times, I'm giving up."
                        exit 1
                fi
        else
                rm -f /etc/yum.repos.d/*rhui*
        fi
else
        rm -f /etc/yum.repos.d/*rhui*
fi

) >/tmp/user-data.log 2>&1
subscription-manager repos --enable ansible-2-for-rhel-8-x86_64-rpms

# fix for corrupt rpm db
rpmdb --rebuilddb

# Install and register Red Hat Insight
dnf install -y insights-client
insights-client --register

# FIXME: Cockpit app fix requires clean cache and rebuild rpm db
dnf clean all
rpmdb --rebuilddb

#comment out in case of debug
rm -rf /var/lib/cloud/instance
rm -f /tmp/user-data.log