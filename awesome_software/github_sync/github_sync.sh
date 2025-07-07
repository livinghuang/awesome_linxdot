#!/bin/sh
#
# github_sync.sh - 自動從 GitHub 拉更新（強制覆蓋本地改動）
#
# 用法：搭配 crontab 每 5 分鐘執行
# crontab: */5 * * * * /opt/awesome_linxdot/github_sync.sh
#
# 請注意：本版本會強制 reset 當前目錄回到 GitHub 上的最新狀態！

cd /opt/awesome_linxdot || exit 1

# 抓取 GitHub 上最新的 commit（不會改動目錄）
git fetch origin main

# 判斷是否有變更（HEAD vs origin/main）
if ! git diff --quiet HEAD origin/main; then
    echo "$(date): Update detected. Forcing reset to origin/main." >> /var/log/linxdot_sync.log

    # 強制還原到 GitHub 上的最新版本（清除本地更改）
    git reset --hard origin/main

    # 執行更新後的操作
    if [ -x ./do_something.sh ]; then
        ./do_something.sh
    else
        echo "$(date): do_something.sh not found or not executable." >> /var/log/linxdot_sync.log
    fi
else
    echo "$(date): No change." >> /var/log/linxdot_sync.log
fi
