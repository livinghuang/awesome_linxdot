#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC=/root/backup
DST=/root
DATE=$(date +%Y%m%d_%H%M%S)
[ -d "$SRC" ] || exit 0
tar -C "$SRC" -czf "$DST/backup_$DATE.tar.gz" .