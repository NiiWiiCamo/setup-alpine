#!/bin/ash

# add programs
apk update && apk upgrade
apk add bash curl iptables ip6tables htop nano

# change default shell for root
sed -i 's/\/bin\/ash/\/bin\/bash/g' /etc/passwd

# setup skel and cron folders
mkdir -p /etc/skel/
mkdir -p /etc/skel/.cronjobs/periodic/15min
mkdir -p /etc/skel/.cronjobs/periodic/hourly
mkdir -p /etc/skel/.cronjobs/periodic/4aday
mkdir -p /etc/skel/.cronjobs/periodic/daily
mkdir -p /etc/skel/.cronjobs/periodic/monthly
mkdir -p /etc/skel/.cronjobs/startup
mkdir -p /etc/startup

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

# setup root cron
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

# ask for username
echo "Enter name for sudo user: "
read newuser

# add user
adduser -s /bin/bash $newuser
adduser $newuser wheel

# add wheel group to sudoers
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel

# ask for ssh script
echo "Enter ssh update script link: "
read sshlink

# execute as new user
su $newuser -c "curl -sSL ${sshlink} | tee ~/.cronjobs/periodic/4aday/get-ssh-keys | bash; crontab usercron"

# setup sshd_config
sed -i 's/\#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/\#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/\#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/\#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
