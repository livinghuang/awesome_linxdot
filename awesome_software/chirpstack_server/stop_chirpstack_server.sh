#!/bin/sh

# Linxdot OpenSource 專案
# 用途：關閉 ChirpStack 服務（透過 docker-compose）並移除 init.d 啟動腳本
# 作者：Living Huang
# 日期：2025-07-08

set -e  # 一旦有任何指令錯誤即中止腳本執行
set -u  # 使用未定義的變數會導致錯誤

# === 設定變數 ===
system_dir="/opt/awesome_linxdot/awesome_software/chirpstack_server/chirpstack_docker"  # docker-compose 資料夾
init_script="/etc/init.d/linxdot_chirpstack_service"  # init.d 啟動服務腳本位置

echo "步驟 1：正在停止 ChirpStack Docker 服務..."

# 檢查 docker-compose 目錄是否存在
if [ ! -d "$system_dir" ]; then
    echo "❌ 錯誤：找不到目錄 $system_dir"
    logger -t "chirpstack" "錯誤：找不到 $system_dir，無法關閉 ChirpStack"
    exit 1
fi

# 切換到該目錄
cd "$system_dir" || {
    echo "❌ 錯誤：切換目錄到 $system_dir 失敗"
    logger -t "chirpstack" "錯誤：無法切換目錄"
    exit 1
}

# 停止 Docker Compose 所有容器（忽略網路不存在的警告）
if docker-compose down 2>&1 | grep -v 'Network .* not found'; then
    echo "✅ 成功關閉 ChirpStack Docker 容器"
    logger -t "chirpstack" "ChirpStack Docker 服務已關閉"
else
    echo "⚠️ 警告：docker-compose down 傳回非 0，可能部分容器未正常關閉"
    logger -t "chirpstack" "警告：docker-compose down 執行失敗"
fi

echo "步驟 2：停止並移除 init.d 啟動服務腳本..."

# 檢查啟動腳本是否存在
if [ -f "$init_script" ]; then
    echo "→ 嘗試停止 init.d 服務..."
    if "$init_script" stop; then
        echo "✅ init.d 服務成功停止"
        logger -t "chirpstack" "init.d 服務成功停止"
    else
        echo "⚠️ 警告：停止 init.d 服務失敗，將繼續移除"
        logger -t "chirpstack" "警告：停止 init.d 服務失敗"
    fi

    # 先移除執行權限再刪除腳本
    chmod -x "$init_script"
    if rm "$init_script"; then
        echo "✅ 成功移除 init.d 啟動腳本"
        logger -t "chirpstack" "已移除 init.d 腳本：$init_script"
    else
        echo "❌ 錯誤：無法移除 $init_script"
        logger -t "chirpstack" "錯誤：無法刪除 $init_script"
        exit 1
    fi
else
    echo "ℹ️  通知：找不到 $init_script，略過移除動作"
    logger -t "chirpstack" "通知：$init_script 不存在，略過移除"
fi

echo "✅ 步驟 3：ChirpStack 停止程序已完成"
