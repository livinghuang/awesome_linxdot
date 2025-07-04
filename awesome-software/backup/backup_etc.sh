#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
LOG_FILE="/overlay/log/messages"
BACKUP_DIR="/root/backup"
DATE=$(date +%Y%m%d_%H%M%S)
OVERLAY_DIR=$(mount | awk '$3=="/overlay"{print $3}')
[ -z "$OVERLAY_DIR" ] && OVERLAY_DIR="/"
USED=$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","");print $(NF-1)}')
FREE=$((100-USED))
[ "$FREE" -lt 5 ] && logger -t log_backup "[WARN] Low disk space ($FREE%)" && \
    ls -1t "$BACKUP_DIR"/messages_*.log 2>/dev/null | tail -n 1 | xargs -r rm -f
mkdir -p "$BACKUP_DIR"
[ -f "$LOG_FILE" ] && cp "$LOG_FILE" "$BACKUP_DIR/messages_$DATE.log" && : > "$LOG_FILE"
/etc/init.d/log restart
root@Linxdot:/opt/awesome_linxdot/awesome-software/backup_log# cat /usr/bin/backup_etc.sh
#!/bin/sh
DATE=$(date +%Y%m%d_%H%M%S)
DIR="/root/backup/etc_$DATE"
mkdir -p "$DIR"
cp -r /etc/* "$DIR/"