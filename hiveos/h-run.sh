#!/usr/bin/env bash
# HiveOS run script for xmrig-tari custom miner
# Uses CLI args only - no config file generation needed

[[ -z $CUSTOM_MINER ]] && CUSTOM_MINER="xmrig-tari"
[[ -z $CUSTOM_LOG_BASENAME ]] && CUSTOM_LOG_BASENAME="/var/log/miner/$CUSTOM_MINER/$CUSTOM_MINER"

MINER_DIR="/hive/miners/custom/$CUSTOM_MINER"
MINER_BIN="$MINER_DIR/xmrig"
LOG_FILE="$CUSTOM_LOG_BASENAME.log"

mkdir -p "$(dirname "$LOG_FILE")"
chmod +x "$MINER_BIN" 2>/dev/null

# Debug log
echo "=== xmrig-tari h-run.sh $(date) ===" >> "$LOG_FILE"
echo "MINER_BIN=$MINER_BIN exists=$(test -f "$MINER_BIN" && echo yes || echo no)" >> "$LOG_FILE"
echo "CUSTOM_URL=$CUSTOM_URL" >> "$LOG_FILE"
echo "CUSTOM_TEMPLATE=$CUSTOM_TEMPLATE" >> "$LOG_FILE"

# Check binary exists
if [[ ! -f "$MINER_BIN" ]]; then
    echo "ERROR: Binary not found: $MINER_BIN" | tee -a "$LOG_FILE"
    exit 1
fi

# Flight sheet params with defaults
BRIDGE="${CUSTOM_URL:-192.168.68.78:18180}"
WALLET="${CUSTOM_TEMPLATE:-default}"
PASS="${CUSTOM_PASS:-x}"

echo "Starting: $MINER_BIN --algo rx/tari --url $BRIDGE --daemon" >> "$LOG_FILE"

cd "$MINER_DIR"
exec "$MINER_BIN" \
    --no-color \
    --algo rx/tari \
    --url "$BRIDGE" \
    --user "$WALLET" \
    --pass "$PASS" \
    --daemon \
    --daemon-poll-interval 1000 \
    --donate-level 1 \
    --print-time 30 \
    --api-port 18088 \
    --api-access-token hiveos \
    --log-file "$LOG_FILE" \
    $CUSTOM_USER_CONFIG
