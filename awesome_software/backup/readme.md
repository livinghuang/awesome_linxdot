# Linxdot 備份系統

本資料夾提供一組 Shell Script，專門在 **OpenWrt / Linxdot** 環境下執行各類備份與清理。
核心入口為 `backup_run.sh`，其餘為子模組腳本。

---

## 目錄結構

```text
awesome_software/
└── backup/
    ├── backup_clean_old_record.sh   # 清理超過 7 天的備份檔
    ├── backup_docker.sh             # 備份 Docker 容器 log
    ├── backup_etc.sh                # 備份 /etc 設定檔
    ├── backup_full.sh               # 完整系統備份（logread, dmesg, /var/log, Docker log）
    ├── backup_pack.sh               # 打包 /root/backup 整份資料夾
    ├── backup_syslog.sh             # 備份 /overlay/log/messages → /root/backup
    ├── backup_test.sh               # 測試用途腳本
    ├── backup_run.sh                # **統一入口腳本**
    └── readme.md                    # 文件說明
```

---

## 檔案說明

| 檔名                           | 功能                                                          |
| ---------------------------- | ----------------------------------------------------------- |
| `backup_syslog.sh`           | 備份 `/overlay/log/messages` → `/root/backup`，並清空原檔           |
| `backup_docker.sh`           | 打包 `/opt/docker/containers/*.log`，保留 7 天                    |
| `backup_etc.sh`              | 備份 `/etc` 設定檔，方便快速還原系統                                      |
| `backup_pack.sh`             | 將 `/root/backup` 資料夾整體打包成 `backup_YYYYMMDD_HHMMSS.tar.gz`   |
| `backup_full.sh`             | 全系統日誌備份（logread、dmesg、/var/log、/tmp/log、Docker log），保留 14 天 |
| `backup_clean_old_record.sh` | 清理超過 7 天的備份與 log 檔，保持磁碟乾淨                                   |
| `backup_test.sh`             | 測試用腳本，驗證功能                                                  |
| `backup_run.sh`              | **統一入口腳本**，依序執行以上腳本並輸出 summary log                          |
| `readme.md`                  | 文件說明                                                        |

---

## 使用方式

### 1. 權限設定

確保腳本可執行：

```sh
chmod +x /root/backup/*.sh
```

### 2. 單次執行

手動觸發：

```sh
/root/backup/backup_run.sh
```

### 3. 排程 (cron)

建議每天凌晨 2 點執行一次：

```cron
0 2 * * * root /root/backup/backup_run.sh
```

---

## Log 紀錄

* 總結紀錄：`/var/log/backup_summary.log`
* 子腳本紀錄：

  * Docker log 備份 → `/var/log/docker_log_backup.log`
  * 清理紀錄 → `/var/log/backup_cleanup.log`

檢視最近狀況：

```sh
tail -n 50 /var/log/backup_summary.log
```
