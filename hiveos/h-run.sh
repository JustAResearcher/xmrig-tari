#!/usr/bin/env bash
# HiveOS run script for xmrig-tari custom miner

[[ -z $CUSTOM_MINER ]] && CUSTOM_MINER="xmrig-tari"
[[ -z $CUSTOM_LOG_BASENAME ]] && CUSTOM_LOG_BASENAME="/var/log/miner/$CUSTOM_MINER/$CUSTOM_MINER"
[[ -z $CUSTOM_CONFIG_FILENAME ]] && CUSTOM_CONFIG_FILENAME="/hive/miners/custom/$CUSTOM_MINER/config.json"

MINER_DIR="/hive/miners/custom/$CUSTOM_MINER"
MINER_BIN="$MINER_DIR/xmrig"
MINER_LOG_DIR=$(dirname "$CUSTOM_LOG_BASENAME")

mkdir -p "$MINER_LOG_DIR"

# Ensure executable
chmod +x "$MINER_BIN" 2>/dev/null

# Generate config from flight sheet variables if config doesn't exist
if [[ ! -f "$CUSTOM_CONFIG_FILENAME" ]]; then
    # Source h-config.sh if it exists
    if [[ -f "$MINER_DIR/h-config.sh" ]]; then
        source "$MINER_DIR/h-config.sh"
    fi
fi

# If config STILL doesn't exist, generate inline
if [[ ! -f "$CUSTOM_CONFIG_FILENAME" ]]; then
    BRIDGE_URL="${CUSTOM_URL:-192.168.68.78:18180}"
    WALLET="${CUSTOM_TEMPLATE:-default}"
    PASS="${CUSTOM_PASS:-x}"
    WORKER_NAME="${WORKER_NAME:-$(hostname)}"
    THREADS=$(nproc 2>/dev/null || echo 16)

    THREAD_ARRAY="["
    for ((i=0; i<THREADS; i++)); do
        [[ $i -gt 0 ]] && THREAD_ARRAY="$THREAD_ARRAY,"
        THREAD_ARRAY="$THREAD_ARRAY$i"
    done
    THREAD_ARRAY="$THREAD_ARRAY]"

    cat > "$CUSTOM_CONFIG_FILENAME" <<CONFIGEOF
{
    "autosave": false,
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": true,
        "hw-aes": null,
        "priority": null,
        "memory-pool": false,
        "max-threads-hint": 100,
        "asm": true,
        "argon2-impl": null,
        "rx": $THREAD_ARRAY
    },
    "donate-level": 1,
    "donate-over-proxy": 1,
    "log-file": "$CUSTOM_LOG_BASENAME.log",
    "pools": [
        {
            "url": "$BRIDGE_URL",
            "user": "$WALLET",
            "pass": "$PASS",
            "coin": "TARI",
            "algo": "rx/tari",
            "daemon": true,
            "daemon-poll-interval": 1000,
            "self-select": null
        }
    ],
    "print-time": 30,
    "retries": 5,
    "retry-pause": 3,
    "api": {
        "id": "$WORKER_NAME",
        "worker-id": "$WORKER_NAME",
        "port": 18088,
        "access-token": "hiveos"
    },
    "randomx": {
        "init": -1,
        "init-avx2": -1,
        "mode": "auto",
        "1gb-pages": true,
        "rdmsr": true,
        "wrmsr": true,
        "cache_qos": false,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    }
}
CONFIGEOF
    echo "Generated config: $CUSTOM_CONFIG_FILENAME"
    echo "Bridge: $BRIDGE_URL | Wallet: $WALLET | Threads: $THREADS"
fi

# Build command line
MINER_ARGS="--config=$CUSTOM_CONFIG_FILENAME"
MINER_ARGS="$MINER_ARGS --api-port=18088 --api-access-token=hiveos"
MINER_ARGS="$MINER_ARGS --no-color"
MINER_ARGS="$MINER_ARGS --log-file=$CUSTOM_LOG_BASENAME.log"

# Apply Flight Sheet extra config arguments if set
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
    MINER_ARGS="$MINER_ARGS $CUSTOM_USER_CONFIG"
fi

echo "Starting $CUSTOM_MINER..."
echo "Command: $MINER_BIN $MINER_ARGS"

cd "$MINER_DIR"
exec "$MINER_BIN" $MINER_ARGS
