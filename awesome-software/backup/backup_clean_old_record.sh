#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
KEEP_DAYS=7
find /root              -name "backup_*.tar.gz"      -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;
find /root/backup       -name "messages_*.log"       -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;
find /root/backup       -name "etc_*"                -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;
find /root/docker_log_backup -name "docker_logs_*.tar.gz" -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;