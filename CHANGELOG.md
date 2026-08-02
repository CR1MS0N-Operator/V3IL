# Changelog

All notable changes to this repository, reconstructed from git history. Entries summarize commit groups; see `git log` for full detail.

## [Unreleased]

- Documentation batch S186: added ARCHITECTURE.md, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md; audited README.md against the actual repo tree; consolidated CLAUDE.md into AGENTS.md and extended agent conventions.

## 2026-06-21 — Security, Branding & CI

- **Security P0 fixes:** rotated the exposed Gitea token, added MIT LICENSE, removed WireGuard public keys from docs, sanitized real IPs to the public placeholder scheme (`10.10.10.x`)
- **Rebrand:** Azrael Security → CR1MS0N, ForeverLX → CR1MS0N-Operator, Nyx → Veil (repo-wide)
- **CI:** added shellcheck and IP-leak-check workflows
- **Docs:** added `docs/ARCHITECTURE-v2.md` — cloud-native/hybrid red team infra design proposal (Oracle Cloud + Cloudflare Tunnel)
- **Meta:** GitHub topics configured (`wireguard, red-team, mythic-c2, infrastructure-as-code, …`)

## 2026-05-20 — README Enhancement

- Expanded README to 700+ lines: Hermes topology, operations playbook, network flow diagrams, deployment matrix

## 2026-04-15 → 2026-04-20 — Node Definitions & Reference Docs

- Added libvirt domain XML for Tairn and Hermes (`configs/libvirt/`)
- Added `docs/infra.md` — node registry, key paths, ports, services (S071)
- Added OpenCode AGENTS.md with Veil infra constraints
- Decommissioned homepage NOC dashboard
- nftables: allowed mesh access to Caddy NOC ports 8484-8488, added ports 3000/8083 to WireGuard allowlist, removed duplicate port 3000 rule
- Ops: cowrie logrotate + suricata threshold configs; troubleshooting entries (virsh URI, OpenCode noexec, Pi-hole sessions, Docker-USER, Mythic GraphQL, Beszel API)

## 2026-03-26 → 2026-04-01 — Operations Automation & Sessions

- Exposed Cowrie on port 22 with rate limiting (10/min, burst 5)
- Tracked Caddyfile in-repo (`edge-node/configs/caddy/Caddyfile`)
- Weekly reboot systemd timer for Cerberus; NOC status scripts and timer; NOC dashboard redesign (Glances, noc-status widgets); Gitea widget; Caddy 8486 proxy
- nftables: `iifname/oifname` for wg0 boot race; removed direct Tairn peer from NightForge wg0 (hairpin routing); whitelisted full RFC1918 in Shield
- Skill suite: azrael-project execution skill, session open/close protocol (v1.x), verification standard (skill-09), brand communication standard (v1.x)
- Session handoffs S034/S048; commit-close protocol hardening

## 2026-03-19 → 2026-03-25 — Documentation Rewrite & Claude Config

- Full docs rewrite: correct three-node architecture, Tairn C2, WireGuard mesh
- Added Claude Code configuration and slash commands
- Renamed Nyx → Veil across docs
- Troubleshooting runbook: WireGuard boot persistence, AllowedIPs scope, Nginx header masking, AppArmor, interface-down cascade, Tairn WireGuard drift, vnet0 bridge fix

## 2026-03-13 → 2026-03-16 — Phase S1 Service Cleanup (Complete)

- **Quadlet migration:** Gitea, Pi-hole, Vaultwarden, Cowrie, Homepage, Caddy, SearXNG as rootless/user Quadlets with health checks
- **TLS:** Caddy deployed with local CA, all services on `.lan` domains
- **WireGuard:** mesh completed — Tairn added, hairpin routing resolved (rp_filter + nftables), NightForge peer config example
- **DNS:** Pi-hole migrated to Quadlet, Cloudflare-only upstream, FallbackDNS on NightForge
- **Security:** Gitea API token redacted from homepage services config
- **Monitoring:** Homepage NOC dashboard with Netdata/Gitea widgets; per-container Netdata charts
- Dotfiles: starship + cleaned NightForge/Tairn zshrc; known-gaps updated (Tairn/Mythic resolved, hostname rename, subnet migration)

## 2026-03-11 → 2026-03-12 — Initial Documentation Suite

- Initial Nyx documentation suite — Cerberus baseline
- Directory restructure; WireGuard example configs (redacted for OPSEC)
- Phase S1 declared complete: Quadlet migration, Caddy TLS, WireGuard, Pi-hole secured

---

*Changelog format: date-grouped summaries by era. Individual commits are atomic by design — use `git log --format='%h %ad %s' --date=short` for the full breakdown.*
