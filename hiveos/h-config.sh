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

# Detect ALL online logical CPUs from sysfs (most reliable on Linux)
# This correctly returns all hyperthreads/SMT siblings, not just physical cores
if [[ -f /sys/devices/system/cpu/online ]]; then
    ONLINE=$(cat /sys/devices/system/cpu/online)
    # Parse range format like "0-95" or "0-3,8-11" into individual CPU IDs
    THREAD_ARRAY="["
    FIRST=1
    IFS=',' read -ra RANGES <<< "$ONLINE"
    THREAD_COUNT=0
    for range in "${RANGES[@]}"; do
        if [[ "$range" == *-* ]]; then
            IFS='-' read -r start end <<< "$range"
            for ((i=start; i<=end; i++)); do
                [[ $FIRST -eq 0 ]] && THREAD_ARRAY="$THREAD_ARRAY,"
                THREAD_ARRAY="$THREAD_ARRAY$i"
                FIRST=0
                ((THREAD_COUNT++))
            done
        else
            [[ $FIRST -eq 0 ]] && THREAD_ARRAY="$THREAD_ARRAY,"
            THREAD_ARRAY="$THREAD_ARRAY$range"
            FIRST=0
            ((THREAD_COUNT++))
        fi
    done
    THREAD_ARRAY="$THREAD_ARRAY]"
    THREADS=$THREAD_COUNT
else
    # Fallback to nproc
    THREADS=$(nproc 2>/dev/null || echo 16)
    THREAD_ARRAY="["
    for ((i=0; i<THREADS; i++)); do
        [[ $i -gt 0 ]] && THREAD_ARRAY="$THREAD_ARRAY,"
        THREAD_ARRAY="$THREAD_ARRAY$i"
    done
    THREAD_ARRAY="$THREAD_ARRAY]"
fi

# Generate config.json
# CRITICAL: Use "rx/tari" as the thread profile key (exact algo match)
# so XMRig picks up our explicit thread list instead of auto-detecting.
# Also include "rx" and "*" as fallback keys for maximum compatibility.
# Do NOT include "max-threads-hint" — it can limit auto-detection.
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
        "yield": false,
        "asm": true,
        "argon2-impl": null,
        "rx/tari": $THREAD_ARRAY,
        "rx": $THREAD_ARRAY,
        "*": $THREAD_ARRAY
    },
    "donate-level": 0,
    "donate-over-proxy": 0,
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
        "cache_qos": true,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    }
}
CONFIGEOF

echo "Config generated: $CUSTOM_CONFIG_FILENAME"
echo "Bridge: $BRIDGE_URL"
echo "Threads: $THREADS (from $(if [[ -f /sys/devices/system/cpu/online ]]; then echo sysfs; else echo nproc; fi))"
echo "Thread array: $THREAD_ARRAY"
