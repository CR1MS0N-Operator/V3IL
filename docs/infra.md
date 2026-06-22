# Veil Infrastructure Reference
**Last updated:** 2026-04-19 S071
**Update when:** topology changes, node added/removed, service added/removed, port assigned.

---

## Node Registry

| Name | Role | OS | WireGuard IP | LAN IP | SSH |
|---|---|---|---|---|---|
| **Cerberus** | Edge / infra node | Arch Linux (headless) | 10.0.0.1 (hub) | 192.168.1.251 (static) | `ssh cerberus` or `ssh -p 2121 foreverlx@192.168.1.251` |
| **NightForge** | Operator workstation | Arch Linux | 10.0.0.3 | 192.168.1.156 (DHCP) | `ssh nightforge` |
| **Tairn** | Attack node / C2 | NixOS 24.11 | 10.0.0.4 | 192.168.122.230 (libvirt NAT) | `ssh tairn` (WireGuard only) |
| **Hermes** | Redirector VM | Alpine Linux 3.23.3 | 10.0.0.5 | 192.168.122.200 (static, libvirt NAT) | `ssh foreverlx@10.0.0.5` (WireGuard only) |
| **iPhone** | Mobile WireGuard client | iOS | 10.0.0.2 | -- | -- |

---

## WireGuard

**Topology:** Hub-and-spoke via Cerberus. Hairpin routing enabled.
**Ports:** 51820 (Cerberus), 51821 (NightForge), 50555 (Tairn), dynamic (Hermes).

**Public keys:** REDACTED — removed from public docs for OPSEC

**Topology rules (locked):**
- Tairn initiates to Cerberus only -- Cerberus has no endpoint for Tairn in wg0.conf
- NightForge SSH config uses 10.0.0.4 (WireGuard), not 192.168.122.230 (libvirt NAT)
- Cerberus cannot reach 192.168.122.x -- libvirt NAT is only reachable from NightForge
- All spokes must have AllowedIPs = 10.0.0.0/24 for Cerberus peer, not 10.0.0.1/32

---

## Key Paths

**Cerberus:**
```
~/veil/
~/.config/containers/systemd/
/etc/containers/systemd/
~/caddy/Caddyfile
~/homepage/config/
/etc/wireguard/wg0.conf
/etc/nftables.conf
~/.config/systemd/user/nightforge-shield.service
~/scripts/suricata/suricata-shield.sh
~/scripts/noc/
~/noc-status/
/etc/pihole/hosts/local.lan
/etc/containers/secrets/pihole.env
~/.ssh/config
~/homepage/config/homepage.env
~/scripts/noc/noc-update.sh
~/.config/systemd/user/noc-update.service
~/.config/systemd/user/noc-update.timer
/etc/systemd/system/weekly-reboot.service
/etc/systemd/system/weekly-reboot.timer
```

**NightForge:**
```
~/Github/
~/Github/veil/
~/Github/veil/docs/skills/
~/Github/veil/docs/infra.md
~/Github/veil/docs/troubleshooting.md
~/Github/security-research/
~/Github/nightforge/
~/Github/azraelsec.dev/
~/Documents/azrael-ops/
~/Documents/azrael-vault/
~/lab/VMs/
~/Repos/3rd-party/
~/Repos/3rd-party/ccsm/
~/Repos/3rd-party/llmfit/
/etc/wireguard/wg0.conf
/etc/nftables.conf
/etc/systemd/system/vnet0-bridge-fix.service
~/.ssh/config
~/.claude/settings.json
~/.claude/CLAUDE.md
~/.claude/hooks/block-destructive.sh
~/.claude/agents/
~/.claude/skills/strategic-compact/
~/.claude/skills/azrael-project/
~/.claude/commands/
~/.claude/plugins/cache/trailofbits/
~/.claude/plugins/claude-hud/config.json
~/.claude.json
~/.config/Claude/claude_desktop_config.json
~/.config/fastfetch/config.jsonc
~/.config/starship.toml
~/.config/operator-terminal/operator-init.sh
```

**Tairn:**
```
/etc/nixos/configuration.nix
~/Mythic/
```

**Hermes:**
```
/etc/wireguard/wg0.conf
/etc/nginx/nginx.conf
/etc/network/interfaces
```

---

## Caddy Proxy Port Registry (Cerberus)

| Port | Service | Target |
|---|---|---|
| 8484 | noc-status JSON file server | /noc-status/ |
| 8486 | Gitea API | 127.0.0.1:3000 |
| 8489 | CR1MS0N-ops-dashboard | 10.0.0.3:9090 via WireGuard |

---

## Cerberus Service Inventory

**Podman rootless Quadlets (~/.config/containers/systemd/):**
- caddy.container -- TLS reverse proxy, local CA, .lan virtual hosts
- gitea.container -- private Git server (git.lan, port 3000)
- glances.container -- system monitor (glances.lan, port 61208)
- homepage.container -- NOC dashboard (dash.lan, port 8282)
- nightforge-cowrie.container -- Cowrie SSH honeypot (port 22, real SSH on 2121)
- searxng.container -- private search engine (search.lan, port 8888)
- vaultwarden.container -- password manager (vault.lan, port 8081)

**System Quadlets (/etc/containers/systemd/):**
- pihole.container -- DNS sinkhole (pihole.lan, port 8083), network=host

**Systemd user services:**
- nightforge-shield.service -- nftables-based connection tracking and rate limiting

**NOC scripts (~/scripts/noc/):** wg-status.sh, cowrie-status.sh, suricata-status.sh, nftables-status.sh -- cron every 5 min, output to ~/noc-status/*.json

---

## libvirt Networks (NightForge)

| Network | Bridge | Subnet | Mode | Purpose |
|---|---|---|---|---|
| default | virbr0 | 192.168.122.0/24 | NAT | Tairn, Hermes VMs |
| isolated | virbr1 | 10.10.10.0/24 | air-gapped | AD labs |
| lab | virbr2 | 10.20.20.0/24 | NAT | general lab |

Domain XML committed to veil configs/libvirt/ (tairn.xml, hermes.xml).

---

## Naming Convention

| Artifact | Format |
|---|---|
| Claude AI conversation | S0NN -- [Session Name] -- YYYY-MM-DD |
| Obsidian learning capture | S0NN -- [Session Name] -- YYYY-MM-DD |
| Handoff document | CR1MS0N-handoff-q1-s0NN.md |
| Git commit | docs: session handoff YYYY-MM-DD S0NN |
