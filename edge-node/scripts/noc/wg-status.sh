#!/bin/bash
# wg-status.sh -- WireGuard peer health for NOC dashboard
# Requires: NOPASSWD sudo for /usr/bin/wg show (see sudoers)

PEERS='{"peers":['
FIRST=1

declare -A NAMES
NAMES["10.10.10.3"]="NightForge"
NAMES["10.10.10.4"]="Tairn"
NAMES["10.10.10.5"]="Hermes"
NAMES["10.10.10.2"]="iPhone"

THRESHOLD=300

current_peer=""
handshake_seconds=""
allowed_ip=""

while IFS= read -r line; do
    if [[ "$line" =~ ^peer: ]]; then
        current_peer=""
        handshake_seconds=""
        allowed_ip=""
    elif [[ "$line" =~ allowed\ ips:\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
        allowed_ip="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ latest\ handshake:\ (.+) ]]; then
        hs="${BASH_REMATCH[1]}"
        seconds=0
        [[ "$hs" =~ ([0-9]+)\ day ]] && seconds=$((seconds + ${BASH_REMATCH[1]} * 86400))
        [[ "$hs" =~ ([0-9]+)\ hour ]] && seconds=$((seconds + ${BASH_REMATCH[1]} * 3600))
        [[ "$hs" =~ ([0-9]+)\ minute ]] && seconds=$((seconds + ${BASH_REMATCH[1]} * 60))
        [[ "$hs" =~ ([0-9]+)\ second ]] && seconds=$((seconds + ${BASH_REMATCH[1]}))
        handshake_seconds=$seconds

        name="${NAMES[$allowed_ip]:-$allowed_ip}"
        status="healthy"
        [[ $seconds -gt $THRESHOLD ]] && status="stale"

        [[ $FIRST -eq 0 ]] && PEERS+=","
        PEERS+="{\"name\":\"$name\",\"ip\":\"$allowed_ip\",\"handshake_seconds\":$handshake_seconds,\"status\":\"$status\"}"
        FIRST=0
    elif [[ -n "$allowed_ip" && -z "$handshake_seconds" ]] && [[ "$line" =~ allowed\ ips: ]]; then
        name="${NAMES[$allowed_ip]:-$allowed_ip}"
        [[ $FIRST -eq 0 ]] && PEERS+=","
        PEERS+="{\"name\":\"$name\",\"ip\":\"$allowed_ip\",\"handshake_seconds\":null,\"status\":\"no_handshake\"}"
        FIRST=0
    fi
done < <(sudo /usr/bin/wg show)

PEERS+="]}"
echo "$PEERS"
