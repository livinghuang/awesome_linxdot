#!/bin/sh

if ! pgrep -f "reverse_ssh.sh" > /dev/null; then
  echo "[$(date)] Reverse SSH not running, restarting..." >> /var/log/reverse_ssh_watchdog.log
  /opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.sh &
fi
