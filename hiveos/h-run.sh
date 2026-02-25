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
