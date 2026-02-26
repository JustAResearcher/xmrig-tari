#!/usr/bin/env bash
# HiveOS stats script for xmrig-tari custom miner v6
# This script is SOURCED by the HiveOS agent - must set $khs and $stats variables

[[ -z $MINER_API_PORT ]] && MINER_API_PORT=18088

stats_raw=$(curl -s --connect-timeout 2 --max-time 5 http://127.0.0.1:$MINER_API_PORT/1/summary 2>/dev/null)

if [[ -z "$stats_raw" ]] || [[ "$stats_raw" == "null" ]]; then
    khs=0
    stats='{}'
    return 0 2>/dev/null || exit 0
fi

# Parse JSON using jq (no 'local' keyword — this runs in sourced context)
_ver=$(echo "$stats_raw" | jq -r '.version // empty' 2>/dev/null)
_algo=$(echo "$stats_raw" | jq -r '.algo // empty' 2>/dev/null)
_uptime=$(echo "$stats_raw" | jq -r '.uptime // 0' 2>/dev/null)
_hs=$(echo "$stats_raw" | jq '[.hashrate.threads[][0] // 0]' 2>/dev/null)
_ac=$(echo "$stats_raw" | jq '.results.shares_good // 0' 2>/dev/null)
_rj=$(echo "$stats_raw" | jq '((.results.shares_total // 0) - (.results.shares_good // 0))' 2>/dev/null)

# CPU temperature
_temp="[]"
_fan="[]"
if command -v sensors &>/dev/null; then
    _temp=$(sensors -j 2>/dev/null | jq '[.. | .temp1_input? // empty | select(. > 0)]' 2>/dev/null || echo '[]')
fi

# khs MUST be set - total hashrate in kH/s
khs=$(echo "$stats_raw" | jq '(.hashrate.total[0] // 0) / 1000' 2>/dev/null)
[[ -z $khs ]] && khs=0

# stats MUST be set - JSON object with standard fields
stats=$(jq -nc \
    --argjson hs "${_hs:-[]}" \
    --arg hs_units "hs" \
    --argjson temp "${_temp:-[]}" \
    --argjson fan "${_fan:-[]}" \
    --arg uptime "${_uptime:-0}" \
    --arg ver "${_ver:-}" \
    --arg algo "${_algo:-}" \
    --argjson ac "${_ac:-0}" \
    --argjson rj "${_rj:-0}" \
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
