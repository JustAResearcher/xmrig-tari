#!/usr/bin/env bash
# HiveOS stats script for xmrig-tari custom miner
# Reads from XMRig HTTP API on port 18088

MINER_API_PORT=18088

stats_raw=$(curl -s http://127.0.0.1:$MINER_API_PORT/1/summary 2>/dev/null)

if [[ -z "$stats_raw" ]] || [[ "$stats_raw" == "null" ]]; then
    echo '{"hs":[],"hs_units":"hs","algo":"","temp":[],"fan":[],"uptime":0,"ver":"","ar":[],"bus_numbers":[]}'
    exit 0
fi

# Parse JSON using jq
local_ver=$(echo "$stats_raw" | jq -r '.version // empty')
local_algo=$(echo "$stats_raw" | jq -r '.algo // empty')
local_uptime=$(echo "$stats_raw" | jq -r '.uptime // 0')

# Hashrate per thread
local_hs=$(echo "$stats_raw" | jq '[.hashrate.threads[][0] // 0]')
local_total_hs=$(echo "$stats_raw" | jq '.hashrate.total[0] // 0')

# Accepted/Rejected shares
local_ac=$(echo "$stats_raw" | jq '.results.shares_good // 0')
local_rj=$(echo "$stats_raw" | jq '(.results.shares_total // 0) - (.results.shares_good // 0)')

# CPU temperature (if available via lm-sensors)
local_temp=[]
local_fan=[]

if command -v sensors &>/dev/null; then
    local_temp=$(sensors -j 2>/dev/null | jq '[.. | .temp1_input? // empty | select(. > 0)] | if length > 0 then . else [] end' 2>/dev/null || echo "[]")
fi

# Build khs value
local_khs=$(echo "$stats_raw" | jq '(.hashrate.total[0] // 0) / 1000')

# Build stats JSON
stats=$(jq -n \
    --argjson hs "$local_hs" \
    --arg hs_units "hs" \
    --argjson temp "$local_temp" \
    --argjson fan "$local_fan" \
    --arg uptime "$local_uptime" \
    --arg ver "$local_ver" \
    --arg algo "$local_algo" \
    --argjson ac "$local_ac" \
    --argjson rj "$local_rj" \
    --argjson khs "$local_khs" \
    --argjson total_khs "$local_khs" \
    '{
        hs: $hs,
        hs_units: $hs_units,
        temp: $temp,
        fan: $fan,
        uptime: ($uptime | tonumber),
        ver: $ver,
        algo: $algo,
        ar: [$ac, $rj],
        bus_numbers: [],
        khs: $khs,
        total_khs: $total_khs
    }')

echo "$stats"
