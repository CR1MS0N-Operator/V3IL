#!/usr/bin/env python3
# cowrie-status.sh -- Cowrie honeypot activity for NOC dashboard

import json
import sys
from datetime import datetime, timezone, timedelta
from collections import Counter

LOG = "/var/nightforge/cowrie-logs/cowrie.json"
WINDOW = timedelta(hours=24)
INTERNAL = {"169.254.1.2", "127.0.0.1"}

now = datetime.now(timezone.utc)
connections = 0
ips = []

try:
    with open(LOG, "r", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            ts_str = ev.get("timestamp", "")
            try:
                ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
            except ValueError:
                continue
            if now - ts > WINDOW:
                continue
            src = ev.get("src_ip", "")
            if src in INTERNAL or not src:
                continue
            if ev.get("eventid", "").startswith("cowrie.session") or \
               ev.get("eventid", "").startswith("cowrie.login"):
                connections += 1
                ips.append(src)
except FileNotFoundError:
    pass

counter = Counter(ips)
top_ip = counter.most_common(1)[0][0] if counter else None

result = {
    "window": "24h",
    "connections": connections,
    "unique_ips": len(set(ips)),
    "top_ip": top_ip
}
print(json.dumps(result))
