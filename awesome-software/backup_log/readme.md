# Awesome Linxdot Backup

This project provides a one-key setup for system log backup, docker container log backup, system health checking, and scheduled maintenance for Linxdot devices running OpenWrt.

## Features
- Backup system logs (`/overlay/log/messages`)
- Backup Docker container logs
- Disk space auto-check and cleanup
- Crontab auto-setup
- Easy install and uninstall scripts

## Install
```bash
wget https://raw.githubusercontent.com/your_github_account/awesome-linxdot-backup/main/install.sh
chmod +x install.sh
./install.sh
