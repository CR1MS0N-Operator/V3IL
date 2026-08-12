# V3IL

**CR1MS0N Security — Continuous Adversarial Validation Infrastructure**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/CR1MS0N-Operator/veil)](https://github.com/CR1MS0N-Operator/veil)
[![Repo Size](https://img.shields.io/github/repo-size/CR1MS0N-Operator/veil)](https://github.com/CR1MS0N-Operator/veil)

Built and operated by [CR1MS0N-Operator](https://github.com/CR1MS0N-Operator) | CR1MS0N Security™

V3IL is the operational infrastructure layer of the CR1MS0N Security portfolio: a production-grade offensive security homelab built entirely as code. Four nodes on a WireGuard hub-and-spoke mesh — an Arch edge node running honeypot + IDS, a declarative NixOS host running Mythic C2, a disposable Alpine redirector, and an operator workstation — continuously discover, attack and score the exposure of operator-owned infrastructure under real adversary TTPs.

This is not a simulation environment. Veil operationalizes the CTEM **Validate** phase: sensor telemetry (Suricata, Cowrie) and emulation traffic are scored continuously, risk is quantified in loss-event frequency terms (FAIR), and blocked actors are pushed to an nftables blackhole in real time. The standing story of the CR1MS0N platform: *exposure is continuously validated, not tested point-in-time.*

---

## Infrastructure Overview

| Node | Role | OS | WireGuard IP | LAN IP (placeholder) |
|------|------|----|-------------|--------|
| **Cerberus** | Edge node — services, detection, honeypot | Arch Linux (headless) | `10.10.10.1` (hub) | `10.10.10.251` (static) |
| **NightForge** | Operator workstation — tooling, compute, development | Arch Linux + Niri WM | `10.10.10.3` | `10.10.10.156` (DHCP) |
| **Tairn** | Attack node — Mythic C2, agent staging, lab targets | NixOS 24.11 (declarative) | `10.10.10.4` | `10.10.11.230` (libvirt NAT) |
| **Hermes** | Redirector VM — C2 egress, traffic forwarding, disposable | Alpine Linux 3.23.3 | `10.10.10.5` | `10.10.11.200` (libvirt NAT) |
| **iPhone** | Mobile WireGuard client | iOS | `10.10.10.2` | — |

All inter-node communication runs exclusively over a WireGuard hub-and-spoke mesh. No node is directly reachable from WAN. All addresses use the public placeholder scheme — see [SECURITY.md](SECURITY.md#sanitization-scheme).

---

## Architecture

```
                        Internet
                            │
                            ▼
             ┌──────────────────────────────┐
             │           Cerberus           │
             │  10.10.10.1 · edge · hub     │
             │                              │
             │  Cowrie SSH honeypot         │
             │  Suricata IDS → Shield       │
             │  Pi-hole DNS · Caddy TLS     │
             │  Gitea · Vaultwarden ·       │
             │  Netdata · Homepage NOC      │
             └──────────────┬───────────────┘
                            │
             WireGuard mesh · 10.10.10.0/24
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  NightForge   │   │    Tairn      │   │    Hermes     │
│  10.10.10.3   │   │  10.10.10.4   │   │  10.10.10.5   │
│ operator WS   │   │  Mythic C2    │   │  redirector   │
│  VM host      │   │  NixOS 24.11  │   │  Alpine       │
│  libvirt NAT  │   │  libvirt NAT  │   │  libvirt NAT  │
│  10.10.11.x   │   │ 10.10.11.230  │   │ 10.10.11.200  │
└───────────────┘   └───────────────┘   └───────────────┘
```

**WireGuard topology:** Hub-and-spoke via Cerberus. Cerberus is the always-on edge node and mesh hub. NightForge, Tairn, and Hermes peer exclusively through Cerberus. Hairpin routing enabled for node-to-node communication across the mesh. NightForge hosts Tairn and Hermes as VMs under its local libvirt NAT (`10.10.11.0/24`); the VMs are reachable on the mesh via their WireGuard addresses.

---

## Topology

The V3IL network spans two physical subnets bridged by WireGuard:

### Physical Network (10.10.10.0/24)

```
  Internet ─── Home Router ─── LAN (10.10.10.0/24)
                                   │
                    ┌──────────────┴──────────────┐
                    │                              │
          Cerberus (10.10.10.251)      NightForge (10.10.10.156)
          Edge node, always-on          Operator workstation
```

### Virtual Network (10.10.11.0/24 — libvirt NAT on NightForge)

```
                     NightForge
                     ┌──────────────────┐
                     │  virbr0 bridge   │
                     │ 10.10.11.1    │
                     └──┬───────────┬───┘
                        │           │
                   Tairn VM    Hermes VM
                   10.10.11.230     10.10.11.200
                   NixOS       Alpine
```

### WireGuard Mesh (10.10.10.0/24)

```
       Cerberus (10.10.10.1) ─── hub, always-on
           │     │     │
           │     │     └── Hermes (10.10.10.5) — C2 redirector
           │     │
           │     └──────── Tairn (10.10.10.4) — Mythic C2
           │
           └────────────── NightForge (10.10.10.3) — operator workstation

           iPhone (10.10.10.2) — mobile client (connects to Cerberus only)
```

### Mesh Rules

- All spoke-to-spoke traffic routes through Cerberus (hairpin forwarding)
- Tairn initiates to Cerberus only — no endpoint configured on Cerberus for Tairn
- Cerberus cannot reach `10.10.11.x` — libvirt NAT is NightForge-local only
- Hermes and Tairn are WireGuard-only accessible; no direct LAN path
- NightForge SSH config uses WireGuard IPs (`10.10.10.4`, `10.10.10.5`), not libvirt NAT IPs

---

## Network Flow

How traffic routes through the Veil mesh from each node's perspective.

### Operator to C2 (NightForge → Tairn)

```
NightForge ──wg0──▶ Cerberus ──wg0──▶ Tairn
10.10.10.3            10.10.10.1       10.10.10.4
                          │
                          │  nftables forward: iif "wg0" oif "wg0" accept
                          │  rp_filter=0 on wg0
```

The Mythic C2 web UI (`https://10.10.10.4:7443`) is accessed exclusively over WireGuard. Tairn's DOCKER-USER iptables chain restricts port 7443 to `10.10.10.0/24`.

### C2 Agent Callback (Internet → Hermes → Tairn)

```
WAN ──(router port-forward 443)──▶ Cerberus ──▶ Hermes (10.10.10.5)
                                                   │  Nginx TLS termination
                                                   ▼
                                              Tairn (10.10.10.4)
                                              Mythic C2 · :7443
```

Hermes acts as the C2 redirector. Nginx on Hermes terminates the external-facing TLS and forwards traffic to Mythic on Tairn. Hermes is disposable — recreated on demand from the committed libvirt XML (see [Deployment](#deployment)). This is an operational security control: the redirector is burned and replaced at configurable intervals or after compromise indicators, and holds no persistent secrets.

### Internet Threat Hunting (Cerberus)

```
  WAN ─── Cerberus (enp0s21f0u2c2)
           │
           ├── Suricata (af-packet, all traffic) → fast.log → Shield scoring → nftables blackhole
           │
           └── Cowrie (port 22, fake SSH) → cowrie.json → Shield scoring → nftables blackhole

  Shield scoring:
    suricata_exploit → +3    | cowrie_login    → +4
    suricata_c2      → +5    | cowrie_command  → +3
    suricata_scan    → +1    | cowrie_download → +5
    suricata_alert   → +2    | Block threshold: ≥ 4 → 1hr blackhole
```

The Shield scoring engine reads Suricata alerts and Cowrie events simultaneously. Any source IP exceeding a cumulative score of 4 is added to the nftables blackhole set with a 1-hour TTL. Blocked IPs are also enqueued to `/var/nightforge/scan-queue.txt` for optional follow-up Nuclei recon.

### Service Access (NightForge → Cerberus .lan services)

```
  NightForge ──wg0── Cerberus:8489 (Caddy reverse proxy)
                             │
                    ┌────────┴────────┐
                    │                 │
              git.lan:8486    dash.lan:8282
              gitea.lan:3000  vault.lan:8081
              search.lan:8888 pihole.lan:8083
```

All `.lan` services are served over TLS via Caddy local CA. NightForge has the CA root certificate installed. WireGuard hairpin routing plus Pi-hole `.lan` DNS resolution make services available at their domain names from any mesh node.

---

## Node Detail

### Cerberus — Edge Node

Chromebook running headless Arch Linux. Serves as the perimeter sensor platform and homelab services hub. All services run as rootless Podman Quadlets under systemd.

**Detection stack:**
- **Cowrie 2.9.13** — SSH honeypot on port 22. Captures attacker TTPs, credentials, and session data.
- **Suricata 8.0.3** — Network IDS with live rule updates.
- **Pi-hole** — DNS sinkhole + `.lan` domain resolution for all nodes.

**Services:**
- **Gitea** — Self-hosted Git server (primary remote for all Veil repos)
- **Vaultwarden** — Self-hosted password manager
- **Caddy** — Reverse proxy with automatic local CA TLS for all `.lan` domains
- **Netdata** — Real-time performance monitoring
- **Homepage** — NOC dashboard

**Firewall:** nftables. WireGuard hairpin routing via `iif "wg0" oif "wg0" accept`. rp_filter=0 on wg0 interface. Dynamic blackhole set for blocked IPs (1hr TTL).

### NightForge — Operator Workstation

Primary operator environment. Arch Linux with Niri Wayland compositor. All offensive tooling, development, and infrastructure management runs here.

- **Hardware:** i3-10105F, 32GB RAM, GTX 1650
- **Compositor:** Niri (Wayland, scrolling tiling layout)
- **Container runtime:** Podman rootless (ad, re, web, toolbox profiles)
- **Editor:** Neovim with LSP
- **Shell:** Zsh + Starship
- **VM management:** libvirt (Tairn, Hermes hosted here as NAT VMs)
- **Local AI:** Ollama (`qwen2.5:14b` for RAG pipeline)
- **Dashboard:** beszel agent (CR1MS0N-ops-dashboard) reporting to Cerberus on port 8489

See [nightforge](https://github.com/CR1MS0N-Operator/nightforge) for full workstation configuration and operator framework.

### Tairn — Attack Node

NixOS 24.11 VM hosted on NightForge via libvirt NAT. Declarative configuration — entire system state is version controlled in `configuration.nix`. Dedicated to offensive operations and course lab work.

- **C2 framework:** Mythic (Docker-based)
- **Primary agent:** Poseidon (Go, Linux)
- **C2 profile:** HTTP C2
- **Operation:** Operation CR1MS0N
- **Access:** WireGuard-only (`10.10.10.4`). Mythic UI locked to mesh via DOCKER-USER iptables chain
- **Courses:** Certified Red Team Analyst (CRTA), Certified Red Team Infrastructure Developer (CRT-ID) via CyberWarfare Labs — all technique work documented with MITRE ATT&CK mapping

### Hermes — Redirector VM

Alpine Linux 3.23.3 VM hosted on NightForge via libvirt NAT. Serves as the C2 egress redirector and traffic forwarding layer.

- **Role:** C2 redirector — terminates external-facing TLS, proxies to Mythic on Tairn
- **OS:** Alpine Linux (minimal, ~150MB footprint)
- **Proxy:** Nginx reverse proxy (TLS termination + stream forwarding)
- **Networking:** Nginx listens on port 443, upstream to `10.10.10.4:7443`
- **Disposable:** VM definition captured in `configs/libvirt/hermes.xml`; rebuilt in minutes (Terraform/Ansible planned — see [docs/ARCHITECTURE-v2.md](docs/ARCHITECTURE-v2.md))
- **Lifecycle:** Static config in `/etc/nginx/nginx.conf`, `/etc/wireguard/wg0.conf`, `/etc/network/interfaces`
- **Access:** WireGuard-only (`10.10.10.5`). No direct LAN path.
- **Monitoring:** Netdata agent reporting to Cerberus

---

## Security Posture

| Control | Implementation |
|---------|---------------|
| Network segmentation | WireGuard mesh — no node directly reachable from WAN |
| C2 access control | iptables DOCKER-USER — port 7443 restricted to `10.10.10.0/24` |
| C2 redirector | Hermes — disposable Alpine Nginx proxy between WAN and Mythic |
| Traffic flow isolation | Hub-and-spoke mesh; all spoke-to-spoke traffic routes through Cerberus |
| Container isolation | Rootless Podman Quadlets (Cerberus), Docker (Tairn — Mythic requirement) |
| VM isolation | Air-gapped libvirt network (virbr1) for AD labs; Tairn/Hermes on NightForge-local NAT planes |
| Secret management | Vaultwarden + `/etc/containers/secrets/` for Quadlet env injection |
| DNS security | Pi-hole (`.lan` resolution + ad/tracker sinkhole) |
| TLS | Caddy local CA (all `.lan` services), Nginx TLS termination (Hermes redirector) |
| SSH hardening | Key-only auth, no root password login, port 22 is Cowrie honeypot |
| Intrusion detection | Suricata 8.0.3 (network IDS), Cowrie 2.9.13 (SSH honeypot) |
| Automated blocking | NightForge Shield — scores threats, blackholes IPs for 1hr via nftables |
| Declarative infra | Tairn entire OS state in `configuration.nix` — reproducible from scratch |
| Firewall default-deny | nftables input policy DROP; explicit allow rules only |
| Audit logging | auditd on Cerberus, Suricata EVE JSON, Cowrie JSON session logs |
| Remote access | Tailscale (authenticated overlay), no port forwarding |
| libvirt backend | nftables — consistent with host firewall, avoids iptables/nftables mismatch |
| Mesh partitioning | Tairn and NightForge have no direct WireGuard endpoint — Cerberus learns them dynamically |

---

## Monitoring

### NOC Dashboard (Homepage)

The primary operational dashboard runs on Cerberus at `dash.lan:8282`. It provides real-time visibility into:

- **Threat intel:** Suricata alert counts, Cowrie session stats, Shield blackhole drops
- **Node metrics:** CPU, memory for Cerberus (via Netdata), Tairn, and Hermes (via beszel agents)
- **Network health:** WireGuard peer status with handshake timestamps; stale peers flagged after 300s
- **Service links:** Gitea, Vaultwarden, Pi-hole, SearXNG with live widgets

NOC data is sourced from:
- `~/noc-status/*.json` — refreshed every 5 minutes by systemd timer `noc-update.timer`
- NOC scripts in `~/scripts/noc/`: `wg-status.sh`, `cowrie-status.sh`, `suricata-status.sh`, `nftables-status.sh`
- Data served by Caddy on port 8484 (`/noc-status/` file server)

### CR1MS0N-ops-dashboard

| Service | Port | Endpoint |
|---------|------|----------|
| CR1MS0N-ops-dashboard | 9090 | `10.10.10.3:9090` via Cerberus Caddy proxy `:8489` |

This provides:
- Multi-node system metrics (CPU, RAM, disk, uptime)
- Agent status (beszel agents on Cerberus, NightForge, Tairn, Hermes)
- Historical performance graphs

### NOC Scripts

All scripts in `edge-node/scripts/noc/`:

| Script | Output | Description |
|--------|--------|-------------|
| `wg-status.sh` | `wg.json` | WireGuard peer health — handshake time, status per peer |
| `cowrie-status.sh` | `cowrie.json` | Honeypot session stats — connections, unique IPs, top attacking IP |
| `suricata-status.sh` | `suricata.json` | IDS alert stats — high/critical alerts, persistent sources |
| `nftables-status.sh` | `nftables.json` | Firewall stats — blackhole drops, input drops |
| `noc-update.sh` | all of above | Orchestrator — runs all status scripts, writes to `~/noc-status/` |

---

## Deployment

Veil uses a hybrid deployment model combining declarative configuration, infrastructure-as-code, and manual setup for constrained hardware.

### Node Deployment Matrix

| Node | Method | Tooling | Provisioning |
|------|--------|---------|-------------|
| Cerberus | Manual + Podman Quadlets | systemd, nftables, Caddy | Chromebook (ARM) — limited IaC support |
| NightForge | Manual + dotfiles | Niri, Podman, Neovim, Zsh | Desktop, see [nightforge](https://github.com/CR1MS0N-Operator/nightforge) |
| Tairn | Declarative | NixOS `configuration.nix` | `nixos-rebuild switch` — full OS state in VCS |
| Hermes | Manual (IaC planned) | libvirt XML + manual Alpine install | rebuild from `configs/libvirt/hermes.xml` |

### Hermes Provisioning (Planned IaC)

Hermes is the target for full IaC coverage (Terraform + Ansible), but those
playbooks are **not yet committed to this repo** — `terraform/` and `ansible/`
do not exist here yet. Today the redirector is recreated from the committed
libvirt XML plus a manual Alpine install:

- `configs/libvirt/hermes.xml` (and `tairn.xml`) — VM definitions
- `edge-node/configs/wireguard/` — example WireGuard configs
- `edge-node/configs/caddy/Caddyfile` — redirector proxy config

Planned pipeline (tracked in `docs/ARCHITECTURE-v2.md`):

1. Provision the VM (`terraform apply` on the libvirt provider)
2. Install Alpine (manual ISO mount + `setup-alpine` via virt-viewer)
3. Configure the redirector (`ansible-playbook playbooks/hermes.yml`)

### NixOS Deployment (Tairn)

```bash
# Apply configuration changes
ssh tairn  # 10.10.10.4 via WireGuard
sudo nixos-rebuild switch --show-trace

# Config lives at /etc/nixos/configuration.nix (tracked on Tairn — not committed to this repo)
```

### Cerberus Quadlet Deployment

```bash
# See Quickstart section below
# Quadlet files in edge-node/containers/
# nftables config in configs/nftables.conf
```

### Hermes Disposable Lifecycle

```
  1. Recreate VM          → libvirt XML (configs/libvirt/hermes.xml)
  2. Alpine setup-alpine   → OS installed
  3. Manual config        → Nginx + WireGuard + Netdata configured (Terraform/Ansible planned)
  4. wg-quick up          → Connects to Veil mesh (10.10.10.5)
  5. ── active ──         → Redirecting C2 traffic for Tairn
  6. Destroy VM           → redirector burned
  7. Return to step 1     → New VM, new SSH keys, new WireGuard keys
```

This burn-and-rebuild cycle is an operational security control: even if the redirector is compromised, it contains no persistent secrets and can be replaced from scratch in under 5 minutes.

---

## Repository Structure

```
veil/
├── README.md                        # Overview, quickstart, operations playbook
├── ARCHITECTURE.md                  # Topology, node roles, security boundaries, ecosystem
├── CONTRIBUTING.md                  # Contribution workflow and conventions
├── SECURITY.md                      # Public/private boundary, sanitization scheme
├── CHANGELOG.md                     # History of notable changes
├── AGENTS.md                        # Agent commands and infrastructure constraints
├── configs/
│   ├── nftables.conf                # nftables ruleset (Cerberus)
│   ├── sysctl/
│   │   └── 99-nightforge.conf       # Kernel tuning for WireGuard hairpin
│   ├── homepage-*.yaml              # Homepage dashboard widgets and bookmarks
│   ├── threshold.config             # Suricata threshold overrides
│   ├── cowrie                       # Cowrie logrotate config
│   └── libvirt/                     # Tairn/Hermes libvirt domain XML
├── edge-node/
│   ├── configs/                     # Caddyfile, nftables, WireGuard examples, Homepage
│   ├── containers/                  # Podman Quadlet unit files
│   ├── systemd/                     # systemd units and timers
│   └── scripts/                     # Shield + NOC automation scripts
├── dotfiles/                        # Shared shell/prompt configs (Starship, zsh)
├── .github/workflows/               # IP-leak-check CI
└── docs/
    ├── architecture.md              # Legacy architecture (superseded by ARCHITECTURE.md)
    ├── services.md                  # Full service reference
    ├── ops.md                       # Operations runbook
    ├── troubleshooting.md           # Issue catalog
    ├── known-gaps.md                # Active and resolved gaps
    ├── edge-node-setup.md           # Cerberus setup walkthrough
    ├── nightforge-shield.md         # Shield scoring engine reference
    ├── infra.md                     # Node registry, key paths, port map (internal)
    ├── ARCHITECTURE-v2.md           # Cloud-native/hybrid design proposal
    └── skills/                      # Operational skill files
```

---

## Quickstart — Cerberus Edge Node

```bash
# 1. Apply sysctl settings
sudo cp configs/sysctl/99-nightforge.conf /etc/sysctl.d/
sudo sysctl -p /etc/sysctl.d/99-nightforge.conf

# 2. Create data directories
sudo mkdir -p /var/nightforge/{cowrie-logs,cowrie-lib,scan-queue}
sudo chown -R $USER:$USER /var/nightforge/
sudo chown -R 100998:100998 /var/nightforge/cowrie-logs /var/nightforge/cowrie-lib

# 3. Deploy Cowrie honeypot
cp edge-node/containers/nightforge-cowrie.container ~/.config/containers/systemd/
systemctl --user daemon-reload
systemctl --user start nightforge-cowrie.service

# 4. Enable linger
loginctl enable-linger $USER
```

---

## Operations Playbook

Common operational tasks for maintaining the Veil mesh and Cerberus edge node.

### Health Checks

```bash
# Overall node health
systemctl --user status nightforge-cowrie nightforge-shield
sudo systemctl status suricata container-pihole container-gitea container-vaultwarden

# WireGuard mesh health
sudo wg show
sudo nft list set inet filter blackhole

# Scan queue depth
wc -l /var/nightforge/scan-queue.txt
tail -5 /var/nightforge/scan-queue.txt
```

### Service Restarts

```bash
# NightForge Shield (scoring engine)
systemctl --user restart nightforge-shield
journalctl --user -u nightforge-shield -f --output=cat

# Cowrie honeypot
systemctl --user restart nightforge-cowrie
journalctl --user -u nightforge-cowrie -n 50

# Suricata IDS
sudo systemctl restart suricata
sudo journalctl -u suricata -n 30

# Manual services (until Quadlet migration complete)
podman restart homepage
podman restart vaultwarden
```

### WireGuard Management

```bash
# View mesh status
sudo wg show

# Add new peer to mesh
# 1. Generate keys on new node: wg genkey | tee privatekey | wg pubkey > publickey
# 2. Add peer to Cerberus wg0.conf:
#   [Peer]
#   PublicKey = <new-node-pubkey>
#   AllowedIPs = 10.10.10.x/32   # hub side; spokes use the full mesh prefix 10.10.10.0/24
# 3. Restart WireGuard on Cerberus: sudo systemctl restart wg-quick@wg0
# 4. Configure new node to peer with Cerberus

# Force re-handshake (troubleshoot stale peer)
sudo wg set wg0 peer <pubkey> endpoint <ip>:<port>

# Reload after config change
sudo systemctl restart wg-quick@wg0
```

### Firewall Operations

```bash
# View full ruleset
sudo nft list ruleset

# View blackhole set (currently blocked IPs)
sudo nft list set inet filter blackhole

# Manually block an IP (1 hour)
sudo nft add element inet filter blackhole '{ 1.2.3.4 timeout 1h }'

# Manually unblock an IP
sudo nft delete element inet filter blackhole '{ 1.2.3.4 }'

# Reload nftables from config
sudo systemctl restart nftables
```

### NOC Dashboard

```bash
# View NOC status files
cat ~/noc-status/wg.json
cat ~/noc-status/cowrie.json
cat ~/noc-status/suricata.json
cat ~/noc-status/nftables.json

# Force NOC update
systemctl --user start noc-update.service

# NOC update timer runs every 5 minutes
systemctl --user status noc-update.timer

# Watch WireGuard peer health
watch -n 5 sudo wg show
```

### Backup Procedures

```bash
# Automated: daily at 02:00 UTC via cron
# Backups Vaultwarden SQLite → ~/backups/vaultwarden/ → Gitea repo

# Manual backup
bash ~/backup-script.sh
cat ~/backup.log

# Verify backup repo latest commit
curl -s http://git.lan/foreverlx/backups | grep "commit"
```

### Maintenance

```bash
# Weekly automated maintenance (Sunday 03:00 UTC)
#   - pacman -Syu (full system update)
#   - Logs to /var/log/security-updates.log

# Manual maintenance
bash ~/scripts/maintenance.sh
#   - Suricata rule update
#   - Log rotation (removes cowrie.json entries >3 days)
#   - Vaultwarden SQLite backup
#   - Homepage config backup
#   - Arch package cache pre-download
```

### Reboot Procedure

After a Cerberus reboot, verify the following in order:

```bash
# 1. Core services
systemctl --user status nightforge-cowrie nightforge-shield
sudo systemctl status suricata container-pihole container-gitea container-vaultwarden

# 2. Manual starts (until Quadlet migration)
podman start homepage
podman start vaultwarden

# 3. Firewall operational
sudo nft list ruleset | grep policy
sudo nft list set inet filter blackhole

# 4. Cowrie on port 22
ss -tlnp | grep :22

# 5. WireGuard mesh
sudo wg show
```

### Troubleshooting

```bash
# Cowrie not logging
ls -la /var/nightforge/cowrie-logs/   # should be owned by UID 100998
sudo chown -R 100998:100998 /var/nightforge/cowrie-logs /var/nightforge/cowrie-lib

# Shield not blocking
systemctl --user status nightforge-shield
sudo nft list sets | grep blackhole

# Vaultwarden not accessible
podman ps | grep vault
ss -tlnp | grep 8081
sudo nft list ruleset | grep 8081

# User Quadlets missing after reboot
systemctl --user daemon-reload
```

See `docs/troubleshooting.md` for the complete issue catalog with root causes and resolutions.

---

## Known Gaps

Active gaps tracked in the Veil infrastructure. See `docs/known-gaps.md` for full details including resolved gaps.

### Active Gaps

| Gap | Severity | Phase | Effort |
|-----|----------|-------|--------|
| Netdata not monitoring containers (Podman socket not mounted) | Medium | D1 | Low |
| NightForge not integrated into centralized monitoring | Medium | N1 | Medium |
| Homepage Netdata service widgets show identical data | Low | D1 | Low |
| SearXNG autocomplete not working | Low | D1 | Low |
| Scan queue has no worker consuming the queue | Low | 4 | High |
| No network segmentation (VLANs) — flat 10.10.10.0/24 | Enhancement | 6 | Very High |

### Gap Detail

**Gap 1 — Homepage Netdata Service Widgets Show Identical Data**
Suricata, Cowrie, and Netdata cards all display the same Netdata CPU chart. Fix: assign distinct metrics — Suricata → `suricata.alerts`, Cowrie → container cgroup chart, Netdata → `system.cpu`.

**Gap 2 — SearXNG Autocomplete Not Working**
Homepage search `suggestionUrl` points to SearXNG autocompleter but suggestions do not appear. Likely CORS or endpoint format issue.

**Gap 3 — Netdata Not Monitoring Containers**
Netdata sees host metrics but container-level metrics are invisible. Podman socket not mounted into the Netdata container. Fix: add `Volume=/run/user/1000/podman/podman.sock:/var/run/docker.sock:ro` to the Netdata Quadlet.

**Gap 4 — No Scan Queue Worker**
Blocked IPs accumulate in the scan queue but no worker performs Nuclei recon. Planned: `nightforge-recon.timer` every 5 minutes running `recon-worker.sh`.

**Gap 5 — NightForge Not Integrated into Centralized Monitoring**
NightForge is connected to the mesh (10.10.10.3) but not reporting to the NOC dashboard. Planned: Netdata agent, Homepage service cards, centralized log aggregation.

**Gap 6 — No Network Segmentation (VLANs)**
Network is flat 10.10.10.0/24. Proposed zones: DMZ (honeypots), Ops (services), Red/C2 (NightForge, Mythic), Management (OOB). Prerequisites: managed switch, pfSense/OPNsense router.

### Resolved Gaps

The following gaps were closed during Phase S1 (Service Cleanup):

- Pi-hole password in plaintext → system Quadlet with secrets file
- Vaultwarden competing services → single user Quadlet on port 8081
- No TLS frontend → Caddy deployed with local CA
- Homepage no auto-start → user Quadlet + linger enabled
- WireGuard reboot persistence → wg-quick@wg0 enabled
- WireGuard mesh incomplete → Tairn added, hairpin routing resolved
- Caddy/Gitea/Vaultwarden/Pi-hole hand-written units → Quadlet migration
- NightForge DNS single point of failure → Cloudflare fallback DNS
- Cerberus hostname b-k3s → renamed to cerberus
- Tairn/Mythic C2 deployment → NixOS + Mythic + Poseidon deployed
- Subnet migration → all configs updated to 10.10.10.0/24 after ISP change

---

## Related Projects

Veil is the infrastructure backbone of the CR1MS0N Security project family. See [ARCHITECTURE.md §7](ARCHITECTURE.md#7-ecosystem) for integration details.

| Project | Role in the Platform |
|---------|---------------------|
| [nightforge](https://github.com/CR1MS0N-Operator/nightforge) | Measurement & mobilization — 10-layer harness turns validation evidence into proposals, gates, and FAIR benefit measurement |
| [c4](https://github.com/CR1MS0N-Operator/c4) | Validation engine — C2 Control Center deploys/manages/destroys Mythic/Sliver for CTEM Validate-phase emulation |
| [Lantern](https://github.com/CR1MS0N-Operator/ACLGuard-Active-Directory-Permission-Auditor) | Identity exposure validation — AD permission auditing feeding CTEM Discover/Prioritize/Validate and FAIR loss-magnitude inputs |
| [security-research](https://github.com/CR1MS0N-Operator/security-research) | Technique writeups, labs, CVE research |

---

## Disclaimer

All tooling is deployed on infrastructure owned and operated by the author for authorized security research and portfolio development. Authorized use only.

---

**Author:** Darrius Grate (CR1MS0N-Operator) | CR1MS0N Security™
**License:** MIT
