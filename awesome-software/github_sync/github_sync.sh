#!/bin/sh
#
# github_sync.sh
#
# 這支腳本會：
# 1. 進入 Linxdot 上的本地 Git 專案資料夾（/opt/awesome_linxdot）
# 2. 使用 git fetch 取得 GitHub 上的最新變更（不影響目前目錄內容）
# 3. 使用 git diff --quiet 判斷目前版本與 GitHub 上的最新版本是否不同
# 4. 如果有更新：
#    - 執行 git pull 拉下最新版本
#    - 執行自定義腳本 ./do_something.sh（你可以在這裡重啟服務、套用設定等）
# 5. 如果沒更新：寫入 log 表示無變化
#
# 用法建議：搭配 cron job 每 5 分鐘執行（可見下方說明）
# Log 位置：/var/log/linxdot_sync.log
#
# 建議 crontab 設定（每 5 分鐘執行一次）：
# */5 * * * * /opt/awesome_linxdot/github_sync.sh
#

# 移動到指定的 repo 目錄，若不存在就退出
cd /opt/awesome_linxdot || exit 1

# 取得遠端（origin/main）的最新資訊，但不合併
git fetch origin main

# 檢查本地 HEAD（當前版本）與遠端 origin/main 是否不同
if ! git diff --quiet HEAD origin/main; then
    # 有變更，記錄時間與訊息到 log
    echo "$(date): New update found" >> /var/log/linxdot_sync.log

    # 拉下更新（合併進來）
    git pull

    # 執行你自定義的操作，例如：
    # - 重新啟動服務：systemctl restart xxx
    # - 套用新配置：cp config.json /etc/
    # - 更新腳本：./install.sh
    ./do_something.sh
else
    # 沒有變更，紀錄時間與訊息到 log
    echo "$(date): No change" >> /var/log/linxdot_sync.log
fi
