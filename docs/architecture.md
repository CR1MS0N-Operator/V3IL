# Veil Architecture

## System Overview

Veil operates as a two-tier architecture:

- **Edge Node (Cerberus):** Google Chromebook running Arch Linux. Handles all sensor, detection, blocking, and homelab services. Constrained to 8GB RAM.
- **NightForge workstation:** Workstation running Arch Linux (32GB RAM). Handles Mythic C2, LLM inference, and heavy compute.

---

## Network Topology

```
                    Internet
                       │
              ┌────────┴────────┐
              │   Home Router   │
              └────────┬────────┘
                       │
          ─────────────────────────
          │        LAN            │
          │   10.10.10.0/24       │
          │                       │
    ┌─────┴──────┐         ┌──────┴──────┐
    │  Cerberus     │         │  NightForge workstation   │
    │ .251       │◄───────►│  Workstation│
    │ Edge Node  │ WireGuard│  C2 Backend │
    └────────────┘ 10.10.10.x └─────────────┘
          │
          │ Tailscale (remote access)
```

### Network Interfaces (Edge Node)

| Interface | Address | Role |
|---|---|---|
| enp0s21f0u2c2 | 10.10.10.1/24 | Primary LAN (USB Ethernet) |
| wg0 | 10.10.10.1/24 | WireGuard VPN mesh |
| tailscale0 | 100.x.x.x/32 | Tailscale remote access |
| podman0 | 10.88.0.1/16 | Container bridge |

---

## Detection Pipeline

```
enp0s21f0u2c2 (all traffic)
       │
       ├──────────────────────┐
       │                      │
       ▼                      ▼
 ┌──────────┐          ┌──────────┐
 │ Suricata │          │  Cowrie  │
 │  8.0.3   │          │  2.9.13  │
 │ fast.log │          │cowrie.json│
 └────┬─────┘          └────┬─────┘
      └──────────┬──────────┘
                 │
                 ▼
       ┌──────────────────┐
       │ NightForge Shield│
       │                  │
       │ Scoring:         │
       │ suricata_exploit → +3  │
       │ suricata_c2     → +5  │
       │ suricata_scan   → +1  │
       │ suricata_alert  → +2  │
       │ cowrie_login    → +4  │
       │ cowrie_command  → +3  │
       │ cowrie_download → +5  │
       │                  │
       │ Block threshold: ≥ 4  │
       └────────┬─────────┘
                │
       ┌────────┴─────────┐
       │                  │
       ▼                  ▼
 ┌──────────┐    ┌──────────────┐
 │ nftables │    │  Scan Queue  │
 │blackhole │    │ (Nuclei -rl10│
 │ 1hr TTL  │    │ every 5 min) │
 └──────────┘    └──────────────┘
```

---

## Container Management Model

### Cerberus Components — Rootless Podman Quadlets

```
~/.config/containers/systemd/
└── nightforge-cowrie.container   → systemctl --user start nightforge-cowrie

~/.config/systemd/user/
└── nightforge-shield.service     → systemctl --user start nightforge-shield
```

### Legacy Homelab Services — System-level

```
/etc/systemd/system/
├── container-gitea.service       → hand-written unit
├── container-pihole.service      → podman generate systemd
└── container-vaultwarden.service → podman generate systemd
```

> ⚠️ **Gap:** Legacy services use inconsistent management patterns. Migration to user Quadlets is planned in Phase S1.

---

## Firewall Architecture

nftables with a dynamic IP blackhole set:

```
table inet filter {
  set blackhole {
    type ipv4_addr
    flags timeout          # entries auto-expire after 1 hour
  }

  chain input {
    policy drop            # default deny everything
    ip saddr @blackhole drop              # blocked IPs dropped first
    ct state established,related accept   # allow existing connections
    iif "lo" accept
    tcp dport { 22, 53, 80, 443 } accept  # honeypot + DNS + web
    tcp dport { 2121, 2222 } accept       # real SSH + Gitea SSH
    tcp dport { 3000, 8080, 8282 } accept # Gitea web, Vaultwarden, Homepage
    tcp dport { 9090, 19999 } accept      # Prometheus, Netdata
    udp dport { 53, 67, 123 } accept      # DNS, DHCP, NTP
  }
}
```

Tailscale manages its own iptables-nft chains separately (`table ip filter`).

---

## Planned Phases

| Phase | Description | Status |
|---|---|---|
| Phase 3 | Cowrie honeypot + Shield scoring pipeline | ✅ Complete |
| Phase S1 | Service cleanup — Quadlet migration, Caddy TLS | Queued |
| Phase 4 | Feyra LLM tool integration, NOC dashboard (name TBD) | Planned |
| Phase 5 | Mythic C2 integration, eBPF research | Planned |
