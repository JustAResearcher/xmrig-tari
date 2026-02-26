#!/usr/bin/env bash
# HiveOS run script for xmrig-tari custom miner v8
# CLI args only - no config file needed

SCRIPT_VERSION="tari19"

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

# Allocate 2MB hugepages: need 1024 for RandomX dataset (2048MB) + 1 per thread for scratchpads
# On NUMA systems, distribute across nodes for optimal performance
THREADS=$(nproc)
NUMA_NODES=$(lscpu 2>/dev/null | grep "^NUMA node(s):" | awk '{print $NF}')
NUMA_NODES=${NUMA_NODES:-1}
DATASET_PAGES=1040  # 2080MB dataset / 2MB per page
PAGES_NEEDED=$(( (DATASET_PAGES + THREADS) * NUMA_NODES ))
CURRENT_PAGES=$(cat /proc/sys/vm/nr_hugepages 2>/dev/null)
CURRENT_PAGES=${CURRENT_PAGES:-0}

# Check available RAM (leave 4GB free for system)
AVAIL_MB=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null)
AVAIL_MB=${AVAIL_MB:-0}
MAX_PAGES=$(( (AVAIL_MB - 4096) / 2 ))
if [[ $MAX_PAGES -lt 0 ]]; then MAX_PAGES=0; fi

# Cap hugepages to available memory
if [[ $PAGES_NEEDED -gt $MAX_PAGES ]]; then
    # Fall back to 1 dataset + all scratchpads
    PAGES_NEEDED=$(( DATASET_PAGES + THREADS ))
    if [[ $PAGES_NEEDED -gt $MAX_PAGES ]]; then
        PAGES_NEEDED=$MAX_PAGES
    fi
fi

echo "NUMA nodes: $NUMA_NODES, threads: $THREADS, hugepages: current=$CURRENT_PAGES needed=$PAGES_NEEDED" >> "$LOG_FILE"

if [[ $PAGES_NEEDED -gt $CURRENT_PAGES ]]; then
    # Drop caches first to free contiguous memory
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    sleep 1
    echo $PAGES_NEEDED > /proc/sys/vm/nr_hugepages 2>/dev/null
    ACTUAL=$(cat /proc/sys/vm/nr_hugepages 2>/dev/null)
    echo "Hugepages: requested=$PAGES_NEEDED actual=$ACTUAL" >> "$LOG_FILE"
fi

# Load MSR module for RandomX performance boost
modprobe msr 2>/dev/null
echo "MSR module: $(lsmod | grep -c msr) loaded" >> "$LOG_FILE"

# Flight sheet params with defaults
BRIDGE="${CUSTOM_URL:-192.168.68.78:18180}"
WALLET="${CUSTOM_TEMPLATE:-default}"
PASS="${CUSTOM_PASS:-x}"

echo "Launching: algo=rx/tari bridge=$BRIDGE wallet=$WALLET threads=$(nproc)" >> "$LOG_FILE"

cd "$MINER_DIR"

# Delete any config.json so CLI args are the sole source of truth
# h-config.sh generates a config.json that XMRig auto-loads from cwd,
# overriding our CLI thread count. We want --threads $(nproc) to win.
rm -f "$MINER_DIR/config.json" 2>/dev/null

exec "$MINER_BIN" \
    --no-color \
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
