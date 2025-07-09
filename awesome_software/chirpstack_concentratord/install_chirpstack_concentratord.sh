#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INITD_SRC="$SCRIPT_DIR/linxdot_chirpstack_concentratord.initd"
INITD_DEST="/etc/init.d/linxdot_chirpstack_concentratord"
UCI_SCRIPT="$SCRIPT_DIR/uci-defaults/90-chirpstack-concentratord"

echo "Step 1: Installing init.d service..."

if [ ! -f "$INITD_SRC" ]; then
    echo "Error: $INITD_SRC not found!"
    exit 1
fi

cp "$INITD_SRC" "$INITD_DEST"
chmod +x "$INITD_DEST"
"$INITD_DEST" enable
"$INITD_DEST" start
echo "Service installed and started."

echo "Step 2: Installing LuCI files..."

if [ -f "$UCI_SCRIPT" ]; then
    chmod +x "$UCI_SCRIPT"
    sh "$UCI_SCRIPT"
    echo "LuCI files installed."
else
    echo "Warning: LuCI uci-defaults script not found: $UCI_SCRIPT"
fi

echo "Installation complete. Please open LuCI → 狀態 → ChirpStack 查看狀態。"
