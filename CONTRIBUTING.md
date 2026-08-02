# Contributing to Veil

## Scope

Veil is a **single-operator infrastructure repository**: WireGuard mesh configuration, Cerberus edge-node configs (Quadlets, Caddy, nftables), libvirt VM definitions, and operational documentation. Everything in this repo is production — changes have real consequences on a live mesh.

This is not an application codebase. Contributions are configuration, documentation, and operational procedure. Keep changes conservative, evidence-based, and scoped to what the task asks for.

## Node Ownership

| Node | Changes live in | Applied by |
|------|-----------------|------------|
| Cerberus | `configs/`, `edge-node/` | Operator (or documented procedure) |
| NightForge | `dotfiles/`, docs | Operator |
| Tairn | `configs/nixos/` (documented only — not committed) | Operator: `sudo nixos-rebuild switch` |
| Hermes | `configs/libvirt/`, docs | Operator: rebuild from XML |

- One commit touches **one node's config only**. Never mix Cerberus and Tairn changes in one commit.
- Tairn config is documented, never executed from this repo. The operator runs `nixos-rebuild switch` after reviewing the diff.

## Prerequisites

- `git`, `bash`
- For config changes: `nft` (ruleset dry-run), `caddy` (Caddyfile validation)
- For script changes: `shellcheck`

## Sensitive Content — Read First

This repo is **public** (portfolio). Committing real operational data is the one unforgivable error:

- **Never commit:** real IPs (the mesh, LAN, and libvirt NAT ranges — see SECURITY.md), WireGuard public/private keys, credentials, API keys, tokens, usernames tied to hosts, engagement details, or real `.lan` hostnames with real addresses.
- **Use the placeholder scheme:** `10.10.10.x` (mesh/LAN), `10.10.11.x` (libvirt NAT). See [SECURITY.md](SECURITY.md#sanitization-scheme).
- When a real value must be referenced, write `[REDACTED - operator-specific]` and keep the detail out of the repo.
- Existing docs under `docs/` predating the sanitization pass still contain real addresses. Do not copy from them into new content; do not redact them without operator approval — flag instead.
- CI runs an IP-leak check on `.md/.yaml/.yml/.conf` pushes. Assume it is watching.

## Verification Before Committing

| Change | Required check |
|--------|----------------|
| `Caddyfile` | `caddy validate --config Caddyfile` |
| nftables rules | `nft -c -f <ruleset>` (dry-run), then `nft list ruleset` on node |
| Shell scripts | `shellcheck -x -S warning <file>` |
| WireGuard configs | Visual review only — never applied from this repo |
| Docs | Grep for real-IP patterns; confirm placeholder scheme |

## Commit Conventions

- **Conventional Commits:** `feat`, `fix`, `docs`, `chore`, `ci`, `ops`, `security`, `refactor` — see `git log`.
- **Micro-commits:** one logical change per commit, meaningful message.
- **Multi-line bodies explaining *why*, not *what*** (repo convention).
- **Branch policy:** work on `review/*` branches; the operator reviews before merge to `main`.
- **Never add Co-Authored-By trailers.**
- **No push without explicit operator approval.**

## What Agents May / Must Never Do

**May:**
- Read any config file for context and debugging
- Suggest edits to WireGuard configs, NixOS config, nftables, Quadlet units — with the failure mode of the change explained
- Update docs: `troubleshooting.md`, skill files, README, this file
- Generate commits and stage changes

**Must never:**
- Edit `wg0.conf` on any node — suggest only; the operator applies
- Edit `configuration.nix` on Tairn — suggest only
- Run `sudo nixos-rebuild switch`, `sudo wg-quick`, or `wg` commands
- Run `sudo systemctl` commands touching WireGuard services
- Remove existing nftables ACCEPT rules without explicit instruction
- Modify WireGuard public keys, endpoints, or AllowedIPs without operator confirmation
- Assume a topology change is safe — always surface the failure mode first
- Write outside the repo, or modify `~/.ssh`, `/etc/wireguard`, or credentials

## Documentation Conventions

- Docs must match actual config: update README/ARCHITECTURE whenever structure changes.
- New content uses the placeholder IP scheme and never names real usernames or engagement details.
- Keep docs project-specific and concise — no boilerplate.
- Active work: update `docs/known-gaps.md`; operational fixes: `docs/troubleshooting.md`.

## Reporting Problems

- Operational issues: open an issue with the `ops` label, or add a `docs/troubleshooting.md` entry with root cause + resolution.
- Security issues: see [SECURITY.md](SECURITY.md#reporting-a-vulnerability) — do not file public issues for security-sensitive items.
