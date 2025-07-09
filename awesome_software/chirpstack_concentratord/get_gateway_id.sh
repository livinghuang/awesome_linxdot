#!/bin/sh

# 儲存在暫存區的 gateway_id
CACHE_FILE="/tmp/gateway_id"

# 若存在就顯示
if [ -s "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    exit 0
fi

# 否則從 log 裡即時撈取
logread | grep -i "gateway id" | grep -oE '[0-9a-f]{16}' | tail -n1
