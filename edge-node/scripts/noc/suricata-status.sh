#!/usr/bin/env python3
# suricata-status.sh -- Suricata alert summary for NOC dashboard

import json
from datetime import datetime, timezone, timedelta
from collections import Counter

LOG = "/var/log/suricata/eve.json"
WINDOW = timedelta(hours=24)

now = datetime.now(timezone.utc)
alert_count = 0
signatures = []
source_ips = []
last_sig = None

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
            if ev.get("event_type") != "alert":
                continue
            ts_str = ev.get("timestamp", "")
            try:
                ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
            except ValueError:
                continue
            if now - ts > WINDOW:
                continue
            severity = ev.get("alert", {}).get("severity", 99)
            if severity > 2:
                continue
            alert_count += 1
            sig = ev.get("alert", {}).get("signature", "unknown")
            last_sig = sig
            src = ev.get("src_ip")
            if src:
                source_ips.append(src)
except FileNotFoundError:
    pass

counter = Counter(source_ips)
persistent = [ip for ip, count in counter.items() if count >= 3]

result = {
    "window": "24h",
    "high_critical_alerts": alert_count,
    "last_signature": last_sig,
    "persistent_sources": persistent
}
print(json.dumps(result))
