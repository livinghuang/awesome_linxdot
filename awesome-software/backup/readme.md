# Linxdot 備份腳本套件

此目錄包含一組針對 Linxdot 裝置設計的備份與維護自動化 Shell 腳本，適用於運行 OpenWrt 的環境，支援定期備份、打包、清理、整合測試等功能。

---

## 📦 檔案說明

| 檔名                         | 說明                                                         |
|------------------------------|--------------------------------------------------------------|
| `backup_log.sh`              | 備份 `/overlay/log/messages` 系統 log，並清空原始檔。        |
| `backup_docker_log.sh`       | 備份 `/opt/docker/containers` 下的 `.log` 檔案。             |
| `backup_etc.sh`              | 備份 `/etc` 下所有設定檔，複製至 `/root/backup/etc_時間戳`。 |
| `backup_pack.sh`             | 將 `/root/backup` 資料夾整體壓縮為 `backup_時間戳.tar.gz`。 |
| `backup_clean_old_record.sh`| 刪除超過 7 天的 `.tar.gz`、log 與 `/etc` 備份資料。          |
| `backup_test.sh`             | 整合測試腳本，會依序執行以上所有流程並進行驗證與 log 紀錄。 |

---

## 🧪 測試方式

執行整合測試：

```sh
sh backup_test.sh
