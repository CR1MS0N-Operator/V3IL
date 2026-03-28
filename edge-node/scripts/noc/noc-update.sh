#!/bin/bash
# noc-update.sh -- write all NOC status JSON files
OUTDIR="/home/foreverlx/noc-status"

python3 /home/foreverlx/scripts/noc/cowrie-status.sh   > "$OUTDIR/cowrie.json"
python3 /home/foreverlx/scripts/noc/suricata-status.sh > "$OUTDIR/suricata.json"
python3 /home/foreverlx/scripts/noc/nftables-status.sh > "$OUTDIR/nftables.json"
bash    /home/foreverlx/scripts/noc/wg-status.sh       > "$OUTDIR/wg.json"
