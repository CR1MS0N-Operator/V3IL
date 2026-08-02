# veil — Infrastructure Agent Rules

## Purpose
Infrastructure configuration repository for Veil (WireGuard mesh + Alpine redirector). No application code.
All changes are configuration files — treat every edit as production infra.
# Veil Infrastructure — Agent Rules

## Scope
Infrastructure configuration repository. No application code.
All changes are configuration files — treat every edit as production infra.

## Node boundaries
- Cerberus changes: Quadlet files in configs/, Caddyfile, nftables.conf
- NightForge changes: documented only — no remote execution from this repo
- Tairn changes: configs/nixos/ only — operator runs nixos-rebuild switch manually
- Never suggest imperative changes as alternatives to declarative config

## Critical constraints
- nftables rules: never remove existing ACCEPT rules without explicit instruction
- WireGuard: never modify public keys, endpoints, or AllowedIPs without operator confirmation
- Caddy: always validate Caddyfile syntax before committing — caddy validate --config Caddyfile
- Pi-hole DNS records: /etc/pihole/hosts/local.lan — operator applies via podman exec

## Commit scope
Each commit touches one node's config only. Never mix Cerberus and Tairn changes in one commit.

## Commands
```bash
# Search — NightForge only (find is aliased to fd)
rg <pattern> <path>

# NixOS changes — Tairn only
nixos-rebuild switch   # MUST run after every configuration.nix change
```

## Stack
- Languages: C, Go (Rust deferred to Q4 review)
- Go: MUST use absolute paths — relative paths cause invocation-dir drift
- All Tairn config: MUST go in configuration.nix, never imperative changes

## Infrastructure
Cerberus   10.0.0.1  edge node, Podman rootless Quadlets
NightForge 10.0.0.3  operator workstation, all code written here
Tairn      10.0.0.4  NixOS, Mythic C2, WireGuard-only access
Hermes     10.0.0.5  Alpine redirector, disposable

## Model Mappings
- **plan**: openrouter/deepseek/deepseek-v3.2 (reasoning)
- **build**: openrouter/mistralai/codestral-2508 (execution)
- **review**: openrouter/nvidia/nemotron-3-super-120b-a12b:free (agentic)
- **commit**: openrouter/google/gemini-2.5-flash (qa/ci)

## Git
- Commit messages: multi-line, bullet breakdown explaining why not what
- Branch policy: MUST use review/* prefix — operator reviews before merge to main
- NEVER add Co-Authored-By trailers

## NEVER
- Write outside the scoped project directory
- Modify ~/.ssh, /etc/wireguard, or WireGuard keys without explicit instruction
- Commit tokens, keys, passwords, or credentials
- Push directly to main
- Generate code the operator should be writing themselves (write-first rule applies to skill work)

## Output Rules (All Agents)
- Output diffs only unless prose explanation is explicitly requested
- Limit explanations to 3 bullets maximum
- Never summarize what you just did — the diff is the summary
- Prefer single atomic commits over batched multi-concern commits
- Format code output as fenced blocks with language tag always

## Token Constraints
- Maximum 32K tokens input context per call
- If context approaches limit, summarize prior tool outputs before continuing
- Do not re-read files already in context — reference by filename only

## OPSEC Rules (All Agents)
- Never write credentials, API keys, or tokens to any file
- Never commit files in ~/.ssh/, /etc/wireguard/, or /etc/nftables.conf
- Always confirm before any destructive bash operation
- Redact IP addresses in the 10.0.0.0/24 and 192.168.1.0/24 ranges from any output intended for external submission

## Extracted from CLAUDE.md
# Veil — Infrastructure CLAUDE.md

## What This Repo Is
Veil is Darrius's three-node WireGuard mesh infrastructure. Everything in this repo
is production — changes have real consequences on a live mesh. Treat it accordingly.

## Node Registry
| Node | Role | OS | WireGuard IP | SSH |
|---|---|---|---|---|
| Cerberus | Edge / hub | Arch Linux (headless) | 10.0.0.1 | `ssh cerberus` or `ssh -p 2121 foreverlx@192.168.1.251` |
| NightForge | Operator workstation | Arch Linux | 10.0.0.3 | `ssh nightforge` |
| Tairn | Attack node / C2 | NixOS 24.11 | 10.0.0.4 | `ssh tairn` (WireGuard only) |

## Key Paths
**Cerberus:**
- `~/veil/` — primary config dir
- `~/.config/containers/systemd/` — Podman rootless Quadlets
- `~/caddy/Caddyfile` — Caddy reverse proxy
- `~/homepage/config/` — Homepage dashboard
- `/etc/wireguard/wg0.conf` — WireGuard config
- `/etc/nftables.conf` — firewall rules

**NightForge:**
- `~/Github/veil/` — this repo
- `~/Github/veil/docs/skills/` — skill files
- `~/Github/veil/docs/troubleshooting.md` — operational runbook
- `/etc/wireguard/wg0.conf` — WireGuard config
- `/etc/nftables.conf` — firewall rules
- `/etc/systemd/system/vnet0-bridge-fix.service` — libvirt bridge race fix

**Tairn:**
- `/etc/nixos/configuration.nix` — NixOS declarative config
- `~/Mythic/` — Mythic C2 installation

## Topology Rules (Hard)
- Hub-and-spoke via Cerberus — all traffic routes through 10.0.0.1
- Tairn initiates to Cerberus only — Cerberus has no endpoint entry for Tairn
- NightForge reaches Tairn via WireGuard (10.0.0.4) — never via 192.168.122.230
- Cerberus cannot reach 192.168.122.x — libvirt NAT is NightForge-only
- WireGuard on NightForge: `sudo resolvconf -u && sudo wg-quick up wg0`
- Tairn config changes always require `sudo nixos-rebuild switch` — Darrius executes only

## Container Runtime Split
- **Cerberus:** Podman rootless Quadlets (no daemon, security-first)
- **Tairn:** Docker (Mythic requires it)
- Never suggest switching either node's runtime

## What Claude Code May Do in This Repo
- Read any config file for context and debugging
- Suggest edits to WireGuard configs, NixOS config, nftables, Quadlet units
- Explain what a config change will do and what the failure mode is before suggesting it
- Update docs: `troubleshooting.md`, skill files, README
- Generate conventional commits and stage changes

## What Claude Code Must Never Do in This Repo
- Edit `wg0.conf` directly on any node — suggest the change, Darrius applies it
- Edit `configuration.nix` directly — suggest only, Darrius reviews and applies
- Run `sudo nixos-rebuild switch` — Darrius executes after reviewing diff
- Run `sudo wg-quick` or any `wg` command — Darrius executes manually
- Run `sudo systemctl` commands touching WireGuard services
- Assume a topology change is safe — always surface the failure mode first

## Locked Technical Decisions
| Decision | Choice | Rationale |
|---|---|---|
| C2 framework | Mythic | Industry recognized, rich agent ecosystem |
| Primary agent | Poseidon (Go, Linux) | Aligns with Linux/kernel focus |
| C2 network access | WireGuard-only (10.0.0.x) | Mirrors real engagement OPSEC |
| C2 VM OS | NixOS 24.11 | Declarative, reproducible, portfolio signal |
| Container runtime (Cerberus) | Podman rootless Quadlets | Security, no daemon |
| Container runtime (Tairn) | Docker | Mythic officially supports Docker |
| DNS | Pi-hole on Cerberus | .lan domains + ad blocking |
| TLS | Caddy local CA | Simple, automatic for .lan |

## Gitea Remote
`ssh://git@192.168.1.251:2222/foreverlx/veil.git`
Sync to both GitHub and Gitea on every push.

## Name History
This infrastructure was previously called "Nyx." It is now "Veil." Never reference Nyx
in any new work, commits, or documentation.

## Agent Routing
- Use `infra-auditor` for all read-only config review
- Use `router-escalation` for any topology changes or multi-node coordination

## Commands
```bash
# Search (NightForge only — find is aliased to fd)
rg <pattern> <path>

# Validate a Caddyfile before proposing changes (Cerberus)
caddy validate --config Caddyfile

# Dry-run nftables ruleset before proposing firewall changes
nft -c -f <ruleset.conf>

# Shell scripts
shellcheck -x -S warning <file>

# Redaction self-check before any commit touching docs/configs
rg -n '10\.0\.0\.|192\.168\.|@[a-z]+\.[a-z]+:' . --glob '!nightforge-vpn-tui/**'
```

## Conventions
- Micro-commits: one logical change per commit, one node per commit, Conventional Commits (`docs:`, `fix:`, `ops:`, `ci:`, `security:`)
- Work on `review/*` branches; operator reviews before merge to `main`; never push to `main` directly
- Multi-line commit bodies explain **why**, not what
- Public docs use the placeholder IP scheme (`10.10.10.x`) — real addresses (mesh, LAN, libvirt NAT — see SECURITY.md) must never be committed
- `docs/` files predating the 2026-06 sanitization pass still contain real addresses — do not copy from them into new content, do not redact without operator approval
- Never edit `wg0.conf` or `configuration.nix` directly — suggest changes and the operator applies them

## Standard Docs
- [ARCHITECTURE.md](ARCHITECTURE.md) — topology, node roles, services, security boundaries, ecosystem
- [CONTRIBUTING.md](CONTRIBUTING.md) — contribution workflow, verification, commit rules
- [SECURITY.md](SECURITY.md) — public/private boundary, sanitization scheme, credential handling
- [CHANGELOG.md](CHANGELOG.md) — history of notable changes
- [README.md](README.md) — overview, quickstart, operations playbook
- `docs/` — services, ops, troubleshooting, known-gaps, infra (internal), ARCHITECTURE-v2 (design)
