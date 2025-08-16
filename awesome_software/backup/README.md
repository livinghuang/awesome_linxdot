# Linxdot Backup Suite (OpenWrt / BusyBox friendly)

This suite provides safe, disk-friendly log backups for a Linxdot box (OpenWrt, Rockchip ARM, Docker preinstalled).  
Focus: avoid filling eMMC with logs, provide retention & space guards, and a simple test mode.

## Components

- `backup_run.sh` — Orchestrator with lock, ordered tasks, summary log.
- `backup_syslog.sh` — Rotate `/overlay/log/messages` into `/root/backup/`, restart log service.
- `backup_docker.sh` — Pack `/opt/docker/containers/*.log` into `/root/docker_log_backup/`, keep last N days.
- `backup_etc.sh` — Archive `/etc` to `/root/backup/etc_YYYYmmdd_HHMMSS`, keep last N days.
- `backup_full.sh` — Full diagnostics/log bundle with retention and overlay free-space guard.
- `backup_pack.sh` — Pack `/root/backup` into `/root/backup_YYYYmmdd_HHMMSS.tar.gz`, keep last N days.
- `backup_clean_old_record.sh` — Final sweeper to remove old files; prints deleted items and totals.
- `backup_test.sh` — Lightweight test: appends a timestamp to `/var/log/backup_test.log` and logs to syslog.
- `set_backup_test_in_cron.sh` — Add per-minute test cron.
- `remove_backup_test_from_cron.sh` — Remove the test cron.
- `set_backup_daily_in_cron.sh` — Add daily (03:00) production cron.

> NOTE: `set_backup_in_cron.sh` from earlier versions is omitted to avoid duplication. Use `set_backup_daily_in_cron.sh`.

## Install

Copy the folder to your device, e.g. `/opt/awesome_linxdot/awesome_software/backup`, then:

```sh
chmod +x /opt/awesome_linxdot/awesome_software/backup/*.sh
```

## Quick start

- One-off test:  
  `./backup_run.sh --test`  → check `/var/log/backup_test.log` and `/var/log/backup_summary.log`
- Add daily cron (03:00):  
  `./set_backup_daily_in_cron.sh`
- (Optional) Add per-minute test cron:  
  `./set_backup_test_in_cron.sh` ; remove with `./remove_backup_test_from_cron.sh`

## Where files go

- Full bundles: `/root/log_backup/logs_*.tar.gz` (auto-pruned)
- Docker log bundles: `/root/docker_log_backup/docker_logs_*.tar.gz` (auto-pruned)
- Syslog copies: `/root/backup/messages_*.log` (then messages is truncated)
- `/etc` snapshots: `/root/backup/etc_*/`
- Packed `/root/backup` snapshots: `/root/backup_*.tar.gz`

All scripts write to `/var/log/*.log` (tmpfs) so they won't fill eMMC.
