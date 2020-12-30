#!/bin/ash

## username to be created
echo "Enter name for normal user with sudo:"
read newuser

## activate community repo
sed -i '/^#.*\/v.*\/community/s/^#//' /etc/apk/repositories

## add programs
apk update && apk upgrade
apk add bash curl iptables ip6tables htop nano open-vm-tools screen sudo vlan

## change default shell for root
sed -i 's/\/bin\/ash/\/bin\/bash/g' /etc/passwd

## setup skel and cron folders
mkdir -p /etc/skel/
mkdir -p /etc/skel/.cronjobs/periodic/15min
mkdir -p /etc/skel/.cronjobs/periodic/hourly
mkdir -p /etc/skel/.cronjobs/periodic/4aday
mkdir -p /etc/skel/.cronjobs/periodic/daily
mkdir -p /etc/skel/.cronjobs/periodic/monthly
mkdir -p /etc/skel/.cronjobs/startup
mkdir -p /etc/startup

## add screen autoconnect
cat <<EOF > /etc/skel/.bash_profile
# test if you are not in screen session, then reattaches first available or creates new session
if [ -z "$STY" ]; then screen -RR; fi
EOF

## set motd
echo "Welcome to $(hostname)!" > /etc/motd

## set motd to display on entering bash (also works in screen)
echo "cat /etc/motd" > /etc/skel/.bashrc

## create .ssh folder for skel
mkdir -p /etc/skel/.ssh

# setup user cron
cat <<EOF > /etc/skel/usercron
# do daily/weekly/monthly maintenance
# min	hour	day	month	weekday	command
*/15	*	*	*	*	run-parts ~/.cronjobs/periodic/15min
0	*	*	*	*	run-parts ~/.cronjobs/periodic/hourly
0	*/6	*	*	*	run-parts ~/.cronjobs/periodic/4aday
0	2	*	*	*	run-parts ~/.cronjobs/periodic/daily
0	3	*	*	6	run-parts ~/.cronjobs/periodic/weekly
0	5	1	*	*	run-parts ~/.cronjobs/periodic/monthly
@reboot					run-parts ~/.cronjobs/startup

# custom cronjobs:
EOF

## setup root cron
cat <<EOF > rootcron
# do daily/weekly/monthly maintenance
# min	hour	day	month	weekday	command
*/15	*	*	*	*	run-parts /etc/periodic/15min
0	*	*	*	*	run-parts /etc/periodic/hourly
0	*/6	*	*	*	run-parts /etc/periodic/4aday
0	2	*	*	*	run-parts /etc/periodic/daily
0	3	*	*	6	run-parts /etc/periodic/weekly
0	5	1	*	*	run-parts /etc/periodic/monthly
@reboot					run-parts /etc/startup

# custom cronjobs:
EOF

crontab rootcron
rm rootcron

## add user
adduser -s /bin/bash $newuser
adduser $newuser wheel

## add wheel group to sudoers
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel


## execute as new user
su $newuser -c "cd ~; curl -sSL https://raw.githubusercontent.com/NiiWiiCamo/ssh/master/get-keys.bash | tee ~/.cronjobs/periodic/4aday/get-ssh-keys | bash; chmod +x ~/.cronjobs/periodic/4aday/*; crontab ~/usercron; rm ~/usercron"

## setup sshd_config
sed -i 's/\#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/\#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/\#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/\#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config

## setup iptables
cat <<EOF > /etc/startup/00_iptables
#!/bin/bash
iptables-restore /etc/iptables/rules-save
ip6tables-restore /etc/iptables/rules6-save
EOF
chmod +x /etc/startup/*

cat <<EOF > /etc/iptables/rules-base
# iptables base config
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
[0:0] -A INPUT -i lo -j ACCEPT
[0:0] -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
[0:0] -A INPUT -p tcp --dport 22 -j ACCEPT
COMMIT
EOF

cp /etc/iptables/rules-base /etc/iptables/rules-save
cp /etc/iptables/rules-base /etc/iptables/rules6-save
