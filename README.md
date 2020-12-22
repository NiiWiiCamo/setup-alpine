# setup-alpine
Alpine Linux setup script
This script sets up alpine ready for use. This setup is mainly for my own use, as it automatically sets up openssh with my ssh keys. You can substitute your own, the username gets read. Look at the script to see what actually happens ;=

1. install alpine and do setup-alpine (openssh)
2. reboot
3. wget -O https://raw.githubusercontent.com/NiiWiiCamo/setup-alpine/main/customize.sh && ash customize.sh
