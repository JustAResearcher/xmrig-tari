#!/usr/bin/env bash
# HiveOS run script for xmrig-tari custom miner v8
# CLI args only - no config file needed

SCRIPT_VERSION="tari11"

[[ -z $CUSTOM_MINER ]] && CUSTOM_MINER="xmrig"
[[ -z $CUSTOM_LOG_BASENAME ]] && CUSTOM_LOG_BASENAME="/var/log/miner/custom/xmrig"

MINER_DIR="/hive/miners/custom/$CUSTOM_MINER"
MINER_BIN="$MINER_DIR/xmrig"
LOG_FILE="$CUSTOM_LOG_BASENAME.log"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

# Debug logging
echo "=== h-run.sh $SCRIPT_VERSION started $(date) ===" >> "$LOG_FILE"
echo "MINER_BIN=$MINER_BIN size=$(stat -c%s "$MINER_BIN" 2>/dev/null)" >> "$LOG_FILE"
echo "CPU: $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2)" >> "$LOG_FILE"
echo "CUSTOM_URL=$CUSTOM_URL" >> "$LOG_FILE"
echo "CUSTOM_TEMPLATE=$CUSTOM_TEMPLATE" >> "$LOG_FILE"
echo "CUSTOM_USER_CONFIG=$CUSTOM_USER_CONFIG" >> "$LOG_FILE"
echo "WORKER_NAME=$WORKER_NAME" >> "$LOG_FILE"

# Verify binary
if [[ ! -f "$MINER_BIN" ]]; then
    echo "FATAL: Binary not found: $MINER_BIN" | tee -a "$LOG_FILE"
    sleep 10
    exit 1
fi
chmod +x "$MINER_BIN" 2>/dev/null

# Quick smoke test
echo "Running smoke test..." >> "$LOG_FILE"
"$MINER_BIN" --version >> "$LOG_FILE" 2>&1
SMOKE_RC=$?
echo "Smoke test exit code: $SMOKE_RC" >> "$LOG_FILE"

if [[ $SMOKE_RC -ne 0 ]]; then
    echo "FATAL: Binary smoke test failed (exit $SMOKE_RC)" | tee -a "$LOG_FILE"
    sleep 10
    exit 1
fi

# Enable 1GB pages if available
if [[ -d /sys/kernel/mm/hugepages/hugepages-1048576kB ]]; then
    _current=$(cat /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages 2>/dev/null)
    if [[ "$_current" == "0" ]]; then
        echo 4 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages 2>/dev/null
        echo "1GB pages: requested 4" >> "$LOG_FILE"
    fi
fi

# Flight sheet params with defaults
BRIDGE="${CUSTOM_URL:-192.168.68.78:18180}"
WALLET="${CUSTOM_TEMPLATE:-default}"
PASS="${CUSTOM_PASS:-x}"

echo "Launching: algo=rx/tari bridge=$BRIDGE wallet=$WALLET" >> "$LOG_FILE"

cd "$MINER_DIR"
exec "$MINER_BIN" \
    --no-color \
    --no-config \
    --algo rx/tari \
    --url "$BRIDGE" \
    --user "$WALLET" \
    --pass "$PASS" \
    --daemon \
    --daemon-poll-interval 1000 \
    --donate-level 0 \
    --print-time 30 \
    --coin TARI \
    --threads $(nproc) \
    --randomx-1gb-pages \
    --http-port 18088 \
    --http-access-token hiveos \
    --log-file "$LOG_FILE" \
    $CUSTOM_USER_CONFIG
