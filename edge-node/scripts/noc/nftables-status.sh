#!/usr/bin/env python3
# nftables-status.sh -- nftables drop counter for NOC dashboard

import subprocess
import re
import json

try:
    out = subprocess.check_output(
        ["sudo", "/usr/sbin/nft", "list", "ruleset"],
        stderr=subprocess.DEVNULL,
        text=True,
        errors="replace"
    )
except subprocess.CalledProcessError:
    print(json.dumps({"blackhole_drops": None, "input_drops": None, "error": "nft failed"}))
    raise SystemExit

counters = re.findall(r'counter packets (\d+) bytes \d+ drop', out)

blackhole = int(counters[0]) if len(counters) > 0 else 0
input_drops = int(counters[1]) if len(counters) > 1 else 0

result = {
    "blackhole_drops": blackhole,
    "input_drops": input_drops
}
print(json.dumps(result))
