#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC=/opt/docker/containers
DST=/root/docker_log_backup
DATE=$(date +%Y%m%d_%H%M%S)
KEEP=7
mkdir -p "$DST"
[ -d "$SRC" ] || exit 0
cd "$SRC" || exit 1
find . -name "*.log" -print0 | tar --null -czf "$DST/docker_logs_$DATE.tar.gz" --files-from=-
find "$DST" -name "docker_logs_*.tar.gz" -mtime +$KEEP -exec rm -f {} \;