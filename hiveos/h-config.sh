#!/usr/bin/env bash
# HiveOS config script for xmrig-tari custom miner
# Generates config.json from flight sheet parameters

[[ -z $CUSTOM_MINER ]] && CUSTOM_MINER="xmrig"
MINER_DIR="/hive/miners/custom/$CUSTOM_MINER"
CUSTOM_CONFIG_FILENAME="$MINER_DIR/config.json"

# Flight sheet variables:
#   CUSTOM_URL     = bridge proxy address, e.g. "192.168.1.100:18180"  
#   CUSTOM_TEMPLATE = wallet address (Tari wallet)
#   CUSTOM_PASS    = password (unused, can be worker name)
#   CUSTOM_USER_CONFIG = extra JSON overrides

# Default bridge URL if not set
BRIDGE_URL="${CUSTOM_URL:-192.168.68.78:18180}"
WALLET="${CUSTOM_TEMPLATE:-default}"
PASS="${CUSTOM_PASS:-x}"

# Worker name from HiveOS
WORKER_NAME="${WORKER_NAME:-$(hostname)}"

# Detect thread count
THREADS=$(nproc 2>/dev/null || echo 16)

# Build thread affinity array for all cores
THREAD_ARRAY="["
for ((i=0; i<THREADS; i++)); do
    [[ $i -gt 0 ]] && THREAD_ARRAY="$THREAD_ARRAY,"
    THREAD_ARRAY="$THREAD_ARRAY$i"
done
THREAD_ARRAY="$THREAD_ARRAY]"

# Generate config.json
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
    "log-file": "/var/log/miner/$CUSTOM_MINER/$CUSTOM_MINER.log",
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
    "http": {
        "enabled": true,
        "host": "127.0.0.1",
        "port": 18088,
        "access-token": "hiveos",
        "restricted": false
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

echo "Config generated: $CUSTOM_CONFIG_FILENAME"
echo "Bridge: $BRIDGE_URL"
echo "Threads: $THREADS"
