# 🔄 Linxdot Backup Log Scripts

這個資料夾包含了一系列用於 Linxdot 系統的備份與清理腳本，協助你管理 Docker 日誌、系統設定、以及自動化打包備份等工作。

---

## 📁 檔案說明

| 檔案名稱 | 功能簡述 |
|----------|----------|
| `backup_docker_log.sh` | 備份 Docker log 資料，用於避免日誌爆量。 |
| `backup_etc.sh` | 備份 `/etc` 資料夾中的系統設定檔。 |
| `backup_log_install.sh` | 安裝備份系統（加入 crontab 自動備份）。 |
| `backup_log_uninstall.sh` | 卸載備份系統（移除 crontab 任務）。 |
| `backup_pack.sh` | 將所有備份資料打包成壓縮檔案。 |
| `cleanup_old_backup.sh` | 自動刪除超過七天的備份檔案，避免空間佔滿。 |
| `linxdot_integrated_test.sh` | 整合測試腳本，用於驗證備份與還原功能是否正常。 |
| `log_backup.sh` | 主備份腳本，會執行相關子腳本以完成完整備份流程。 |

---

## 🛠️ 安裝方式

```bash
chmod +x *.sh
./backup_log_install.sh
````

---

## 🔁 自動排程

安裝後會自動將備份任務加入 crontab：

* 每天凌晨 3:00 執行備份
* 每週日凌晨 4:00 清理舊備份

你可以使用以下指令檢查排程內容：

```bash
crontab -l
```

---

## 🧹 備份清理

若需要手動清除舊備份檔案，可以執行：

```bash
./cleanup_old_backup.sh
```

---

## 📦 備份檔案格式

* 格式：`backup_YYYYMMDD_HHMMSS.tar.gz`
* 路徑：`/root/backup/`

---

## 🧪 測試腳本

`linxdot_integrated_test.sh` 可用於模擬備份與清理流程，方便驗證腳本是否正常運作。

---

## 📜 備註

* 所有腳本皆以 root 權限執行為主。
* 請確認目錄 `/root/backup/` 可正常寫入。
* 若搭配 Watchdog 或其他守護進程，建議留意重開機時的 cron 初始化時機。