#!/usr/bin/env bash
# HiveOS install/diagnostic helper for xmrig-tari
# Run on HiveOS rig: bash /hive/miners/custom/xmrig-tari/install.sh
# Or download and run:
#   wget -qO- https://github.com/JustAResearcher/xmrig-tari/releases/download/v6.25.0-tari6/xmrig-tari.tar.gz | tar xz --strip-components=1 -C /hive/miners/custom/xmrig-tari/

MINER_DIR="/hive/miners/custom/xmrig-tari"
BIN="$MINER_DIR/xmrig"

echo "=== xmrig-tari diagnostic ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Arch: $(uname -m)"

echo ""
echo "=== CPU ==="
grep -m1 'model name' /proc/cpuinfo 2>/dev/null || echo "unknown"
grep -m1 'flags' /proc/cpuinfo 2>/dev/null | tr ' ' '\n' | grep -E '^(aes|avx|avx2|avx512|sse4)' | sort | tr '\n' ' '
echo ""

echo ""
echo "=== Files ==="
ls -la "$MINER_DIR/" 2>/dev/null || echo "MINER DIR NOT FOUND"

echo ""
echo "=== Binary ==="
if [ -f "$BIN" ]; then
    echo "Size: $(stat -c%s "$BIN" 2>/dev/null || echo unknown) bytes"
    file "$BIN" 2>/dev/null || echo "file command not available"
    echo ""
    echo "=== Version test ==="
    "$BIN" --version 2>&1
    RC=$?
    echo "Exit code: $RC"
    if [ $RC -ne 0 ]; then
        echo ""
        echo "=== Trying with strace ==="
        strace -f "$BIN" --version 2>&1 | tail -20
    fi
else
    echo "BINARY NOT FOUND at $BIN"
fi

echo ""
echo "=== h-run.sh header ==="
head -5 "$MINER_DIR/h-run.sh" 2>/dev/null || echo "h-run.sh not found"

echo ""
echo "=== Log ==="
tail -30 /var/log/miner/xmrig-tari/xmrig-tari.log 2>/dev/null || echo "No log file"

echo ""
echo "=== Network test (bridge proxy) ==="
timeout 3 bash -c 'echo | /dev/tcp/192.168.68.78/18180' 2>/dev/null && echo "Bridge REACHABLE" || echo "Bridge UNREACHABLE"
