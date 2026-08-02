# Security Policy

## Repository Visibility

**This repository is PUBLIC** and intentionally remains public as a portfolio asset. Everything committed to `main` is visible to anyone with access to the remote. Treat committed content as public:

- No credentials, API keys, tokens, or secrets — ever
- No real infrastructure addresses: WireGuard mesh, LAN, libvirt NAT, or WAN IPs
- No WireGuard public or private keys
- No engagement details: target identities, operation timelines, credential material from lab environments
- No operator usernames bound to host addresses
- Redact anything operator-specific with `[REDACTED - operator-specific]`

## What Is Public vs. Private

| Category | Public (this repo) | Private (never committed) |
|----------|-------------------|---------------------------|
| Topology | Node names, roles, placeholder IPs (`10.10.10.x`) | Real mesh/LAN/libvirt addresses |
| Services | Names, versions, ports (already disclosed) | Bind credentials, admin passwords |
| Config | nftables rules, Quadlet units, Caddyfile, libvirt XML | WireGuard keys, secrets files, `.env` |
| Operations | Runbook procedures, troubleshooting | Live session data, scan queue contents, incident telemetry |
| Research | Technique writeups (in `security-research/`) | Engagement-shaped data, lab credentials |
| Docs | Architecture, contributing, changelog | Session handoffs with operational detail |

## Sanitization Scheme

Public docs use a fixed placeholder mapping. Real values exist only on the nodes.

| Real network | Public placeholder |
|--------------|--------------------|
| WireGuard mesh | `10.10.10.0/24` |
| Home LAN | `10.10.10.0/24` (shared placeholder with mesh) |
| libvirt NAT (VMs) | `10.10.11.0/24` |
| Air-gapped lab (virbr1) | Described functionally, no subnet |

Known limitation: the shared `10.10.10.0/24` placeholder for mesh and LAN collides with the real virbr1 lab subnet. A future sanitization pass should introduce distinct placeholders per plane; until then, never assume a `10.10.x.x` value in public docs is fictional.

**Legacy debt:** docs under `docs/` created before the sanitization pass (2026-06) still contain real addresses (the mesh, LAN, and libvirt NAT ranges) and the operator username. These are slated for a redaction pass; until then they are the primary leak vector — do not copy from them into new content, and treat any push of those files as CI-flagged.

## Credential Handling

- **Never commit credentials.** Not even to a private branch. Rotating a leaked credential is the remediation; not committing is the prevention.
- Secrets in configs use environment-variable references, `/etc/containers/secrets/` injection, or the literal placeholder `ROTATED` (see `configs/homepage-services.yaml`).
- WireGuard example configs use `REDACTED` for keys. A real public key in an example file is a leak — see the report history for the one that slipped through.
- Vaultwarden is the operator's secret store. This repo is not a secret store.

## Engagement Boundaries

Veil hosts offensive tooling (Mythic C2 on Tairn, redirector, honeypots) for **authorized security research, course labs, and portfolio development on operator-owned infrastructure**. The repository:

- Never contains target identities, engagement names (beyond the public operation name), credential dumps, or captured session material
- Never references third-party systems
- Documents technique and procedure, not live operation state
- Follows the learning-track rule: a technique is "done" only when reproduced in the lab (Tairn) and written up in `security-research/`

## Reporting a Vulnerability

For operational security reasons, **do not file public issues** for security vulnerabilities in this infrastructure.

- **Low-sensitivity items** (config hygiene, doc leaks): GitHub issue tagged `security`
- **Sensitive disclosures** (credential exposure, live-infrastructure risk): direct message CR1MS0N-Operator on GitHub

## OPSEC Commitments

- CI gates: `.github/workflows/ip-leak-check.yml` (real-IP / private-key / API-token patterns on `.md/.yaml/.yml/.conf`) and `shellcheck.yml` (all `.sh`)
- WireGuard public keys were removed from docs in 2026-06; example configs carry `REDACTED`
- Real IPs were sanitized to the placeholder scheme in 2026-06 (README); `docs/` debt tracked above
- A previously exposed Gitea API token (2026-03) was redacted and rotated; the config now holds `"ROTATED"`

## Known Security Considerations

- `edge-node/configs/wireguard/*.example` — example WireGuard configs; keep keys `REDACTED` and addresses placeholder
- `configs/nftables.conf` and `edge-node/configs/nftables.conf` — real firewall rules, real subnets; these are operational configs, review before pushing
- `docs/infra.md` — internal reference with real addresses; most sensitive file in the repo
- The untracked `nightforge-vpn-tui/` tree at the repo root is an unrelated in-progress project (Mullvad TUI fork); do not commit it

## Supported Versions

Rolling infrastructure configuration. No versioned releases — fixes land on `main` after `review/*` branch review.
