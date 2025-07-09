#!/bin/sh

# 嘗試最多 30 次，每次間隔 10 秒
for i in $(seq 1 30); do
    gateway_id=$(logread | grep -i 'gateway id' | grep -oE '[0-9a-f]{16}' | tail -n1)
    
    if [ -n "$gateway_id" ]; then
        echo "$gateway_id" > /tmp/gateway_id
        logger -t get_gateway_id "Gateway ID found: $gateway_id"
        exit 0
    fi

    sleep 10
done

logger -t get_gateway_id "Gateway ID not found after 30 attempts"
exit 1
