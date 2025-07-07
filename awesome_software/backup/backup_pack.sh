#!/bin/sh
###############################################################################
# 備份打包封存腳本
# 功能：
#   - 將 /root/backup 資料夾內容整個壓縮成 backup_時間戳.tar.gz
#   - 存放至 /root 目錄下
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC=/root/backup            # 備份來源資料夾
DST=/root                   # 壓縮檔儲存位置
DATE=$(date +%Y%m%d_%H%M%S) # 時間戳記

# 若來源資料夾不存在則退出
[ -d "$SRC" ] || exit 0

# 將整個 /root/backup 打包為 backup_YYYYMMDD_HHMMSS.tar.gz
tar -C "$SRC" -czf "$DST/backup_$DATE.tar.gz" .
