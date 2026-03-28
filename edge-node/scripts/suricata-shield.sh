#!/bin/bash
# NightForge Shield v2 — Suricata + Cowrie → nftables scoring + scan queue

SURICATA_LOG="/var/log/suricata/fast.log"
COWRIE_LOG="/var/nightforge/cowrie-logs/cowrie.json"
QUEUE="/var/nightforge/scan-queue.txt"
WHITELIST="169\.254\.|192\.168\.|10\.0\.0\.|127\.|100\.86\."

declare -A IP_SCORE

touch "$QUEUE"

score_and_act() {
    local ip="$1"
    local reason="$2"
    local points="$3"

    echo "$ip" | grep -qE "$WHITELIST" && return

    IP_SCORE[$ip]=$(( ${IP_SCORE[$ip]:-0} + points ))
    local score=${IP_SCORE[$ip]}

    echo "[NightForge] $ip | reason=$reason | score=$score | $(date -u +%H:%M:%SZ)"

    if [ "$score" -ge 4 ]; then
        sudo /usr/bin/nft add element inet filter blackhole "{ $ip timeout 1h }" 2>/dev/null
        echo "$ip|$score|$(date +%s)|$reason" >> "$QUEUE"
        echo "[NightForge] BLOCKED+QUEUED $ip (score: $score)"
    fi
}

# Monitor Suricata fast.log
tail -Fn0 "$SURICATA_LOG" 2>/dev/null | while read -r line; do
    ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+ ->' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
    [ -z "$ip" ] && continue

    if echo "$line" | grep -qi "exploit\|shellcode\|injection\|rce"; then
        score_and_act "$ip" "suricata_exploit" 3
    elif echo "$line" | grep -qi "brute\|scan\|probe\|sweep"; then
        score_and_act "$ip" "suricata_scan" 1
    elif echo "$line" | grep -qi "c2\|beacon\|callback"; then
        score_and_act "$ip" "suricata_c2" 5
    else
        score_and_act "$ip" "suricata_alert" 2
    fi
done &

# Monitor Cowrie JSON log
tail -Fn0 "$COWRIE_LOG" 2>/dev/null | while read -r line; do
    eventid=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('eventid',''))" 2>/dev/null)
    ip=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('src_ip',''))" 2>/dev/null)

    [ -z "$ip" ] && continue
    echo "$ip" | grep -qE "$WHITELIST" && continue

    case "$eventid" in
        cowrie.login.success)   score_and_act "$ip" "cowrie_login_success" 4 ;;
        cowrie.login.failed)    score_and_act "$ip" "cowrie_login_failed" 2 ;;
        cowrie.command.input)   score_and_act "$ip" "cowrie_command" 3 ;;
        cowrie.session.file_download) score_and_act "$ip" "cowrie_download" 5 ;;
    esac
done &

wait
