#!/usr/bin/env bash
# HiveOS stats script for xmrig-tari custom miner
# This script is SOURCED by the HiveOS agent - must set $khs and $stats variables

#MINER_API_PORT is already set from h-manifest.conf (18088)
[[ -z $MINER_API_PORT ]] && MINER_API_PORT=18088

stats_raw=$(curl -s --connect-timeout 2 --max-time 5 http://127.0.0.1:$MINER_API_PORT/1/summary 2>/dev/null)

if [[ -z "$stats_raw" ]] || [[ "$stats_raw" == "null" ]]; then
    khs=0
    stats='{}'
    return 0 2>/dev/null || exit 0
fi

# Parse JSON using jq
local local_ver=$(echo "$stats_raw" | jq -r '.version // empty' 2>/dev/null)
local local_algo=$(echo "$stats_raw" | jq -r '.algo // empty' 2>/dev/null)
local local_uptime=$(echo "$stats_raw" | jq -r '.uptime // 0' 2>/dev/null)
local local_hs=$(echo "$stats_raw" | jq '[.hashrate.threads[][0] // 0]' 2>/dev/null)
local local_ac=$(echo "$stats_raw" | jq '.results.shares_good // 0' 2>/dev/null)
local local_rj=$(echo "$stats_raw" | jq '((.results.shares_total // 0) - (.results.shares_good // 0))' 2>/dev/null)

# CPU temperature
local local_temp=[]
local local_fan=[]
if command -v sensors &>/dev/null; then
    local_temp=$(sensors -j 2>/dev/null | jq '[.. | .temp1_input? // empty | select(. > 0)]' 2>/dev/null || echo '[]')
fi

# khs MUST be set - total hashrate in kH/s
khs=$(echo "$stats_raw" | jq '(.hashrate.total[0] // 0) / 1000' 2>/dev/null)
[[ -z $khs ]] && khs=0

# stats MUST be set - JSON object with standard fields
stats=$(jq -nc \
    --argjson hs "${local_hs:-[]}" \
    --arg hs_units "hs" \
    --argjson temp "${local_temp:-[]}" \
    --argjson fan "${local_fan:-[]}" \
    --arg uptime "${local_uptime:-0}" \
    --arg ver "${local_ver:-}" \
    --arg algo "${local_algo:-}" \
    --argjson ac "${local_ac:-0}" \
    --argjson rj "${local_rj:-0}" \
    '{
        hs: $hs,
        hs_units: $hs_units,
        temp: $temp,
        fan: $fan,
        uptime: ($uptime | tonumber),
        ver: $ver,
        algo: $algo,
        ar: [$ac, $rj],
        bus_numbers: []
    }' 2>/dev/null)

[[ -z $stats ]] && stats='{}'
