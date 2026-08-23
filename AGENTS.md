# veil — Agent Rules

## Purpose
Veil is the **validation substrate** of the CR1MS0N continuous adversarial validation platform — a 4-node WireGuard hub-and-spoke mesh (Cerberus edge, NightForge operator workstation, Tairn Mythic C2, Hermes redirector) that operationalizes the CTEM **Validate** phase. Sensor telemetry (Suricata, Cowrie) and emulation traffic are scored continuously, risk quantified in loss-event frequency terms (FAIR), blocked actors pushed to nftables blackhole in real time.

Pairs with [[nightforge]] (measurement/mobilization), [[c4]] (C2 control), and [[Lant3rn]] (identity exposure validation).

## Stack
- **Mesh:** WireGuard (hub-and-spoke, 10.10.10.0/24)
- **Edge node (Cerberus):** Arch Linux, Suricata IDS, Cowrie honeypot
- **Operator (NightForge):** Arch Linux + Niri WM
- **Attack node (Tairn):** NixOS 24.11 (declarative), Mythic C2
- **Redirector (Hermes):** Alpine 3.23.3, disposable
- **Mobile:** iOS WireGuard client
- **Risk model:** FAIR (loss-event frequency)

## Agent Architecture
- **Brain:** Hermes Desktop (planning, review, security analysis)
- **Executor:** dsh web API (deepseek) — infra automation, config generation
- **Local:** Pi Agent (Qwen3.8-27B) — for sensitive security configs
- **Subagent pattern:** Read spec → draft config → test in sandbox → deploy to staging → operator approval → promote to prod

## Commands
```bash
# WireGuard
wg show
wg-quick up wg0

# Suricata
systemctl status suricata
tail -f /var/log/suricata/eve.json

# Cowrie
systemctl status cowrie
ls /srv/cowrie/log/

# Mythic (Tairn)
systemctl status mythic-server
mythic-cli status

# nftables blacklist
nft list set inet filter blackhole
nft add element inet filter blackhole { <ip> }
```

## Node Roles
| Node | IP | OS | Purpose |
|------|----|----|---------|
| Cerberus | 10.10.10.1/251 | Arch | Edge: services, detection, honeypot |
| NightForge | 10.10.10.3/156 | Arch + Niri | Operator workstation, tooling |
| Tairn | 10.10.10.4/11.230 | NixOS | Attack: Mythic C2, agent staging |
| Hermes | 10.10.10.5/11.200 | Alpine | Redirector, C2 egress |
| iPhone | 10.10.10.2 | iOS | Mobile client |

All inter-node comms over WireGuard only. No node reachable from WAN.

## Conventions
- **Infra as code:** All config in Nix (Tairn) or shell-validated (others)
- **Sanitization:** Public placeholders only — see SECURITY.md
- **No secrets in repo:** WireGuard keys, API tokens in Bitwarden + nix secrets
- **Telemetry:** Suricata eve.json, Cowrie logs, Mythic events — all logged to central store
- **Risk scoring:** FAIR model, loss-event frequency, quantified exposure

## Guardrails
- **Never** commit real IPs, keys, or operator data — sanitized placeholders only
- **Never** modify WireGuard mesh topology without operator approval
- **Never** push to Tairn (NixOS) without `nix flake check` passing
- **Never** disable Suricata/Cowrie (sensor continuity is critical)
- **Never** add a new node without updating SECURITY.md sanitization scheme
- **Documentation-only tasks** stay documentation-only

## Subagent-Driven Development
For infra changes (NixOS config, WireGuard updates, nftables rules):
1. **Decompose:** Plan into nodes (Tairn, Cerberus, Hermes) + cross-cutting (mesh, policies)
2. **Spawn per-node leaves:** Each node's config is independent — dispatch parallel dsh sessions
3. **Test in sandbox:** Never deploy to live mesh without staging test
4. **Operator approval:** All prod deployments require operator sign-off
5. **Rollback plan:** Document nix rollback / nftables restore before deploy

## Escalation Triggers
- WireGuard mesh topology change
- Node addition/removal
- Sensor (Suricata/Cowrie) failure
- Mythic C2 compromise
- nftables blacklist bypass
- New vulnerability in mesh software (wireguard, suricata, cowrie, mythic)
- NixOS system update affecting C2 infrastructure

## Reference
- Platform context: [[ai-lab-vault|AGENTS.md]]
- NightForge: [[nightforge]]
- C4: [[c4]]
- Lant3rn: [[Lant3rn]]
- Security model: [[veil|SECURITY.md]]
