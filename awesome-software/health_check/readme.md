# Linxdot 系統健康監控腳本（health_check）

本資料夾包含 Linxdot 系統磁碟使用率與備份數量的監控與測試腳本，設計用於 OpenWrt 系統上，協助監控 `/overlay` 分區空間狀況，並自動清理過多的備份檔案。

---

## 📁 腳本說明

| 檔案名稱                     | 功能描述 |
|------------------------------|----------|
| `system_health_check.sh`     | 檢查 `/overlay` 使用率，若空間不足或備份過多，自動發出警告並清理舊備份檔案。 |
| `system_health_check_test.sh`| 執行測試流程，顯示 overlay 空間、備份數變化、刪除結果與 log 輸出。 |

---

## 🛠 使用方法

### 執行一次檢查：

```sh
sh system_health_check.sh

