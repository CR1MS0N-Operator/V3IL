#!/bin/bash
# noc-update.sh -- write all NOC status JSON files
OUTDIR="$HOME/noc-status"

python3 $HOME/scripts/noc/cowrie-status.sh   > "$OUTDIR/cowrie.json"
python3 $HOME/scripts/noc/suricata-status.sh > "$OUTDIR/suricata.json"
python3 $HOME/scripts/noc/nftables-status.sh > "$OUTDIR/nftables.json"
bash    $HOME/scripts/noc/wg-status.sh       > "$OUTDIR/wg.json"
