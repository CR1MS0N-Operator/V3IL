---
name: infrastructure-operations-standard
description: Use when Darrius asks Claude to help with any work on Cerberus, NightForge, Tairn, or Hermes — service changes, config edits, Quadlet deployments, NixOS changes, firewall rules, WireGuard, or troubleshooting. Enforces node-specific rules, command format, verification steps, and commit standards.
---

# Azrael Security Skill — Infrastructure Operations Standard
**Version:** 1.0
**Date:** 2026-03-19
**Purpose:** Define consistent patterns for commands, config changes, commits, and documentation when working on Veil infrastructure.
**Use when:** Darrius asks Claude to help with any work on Cerberus, NightForge, or Tairn — service changes, config edits, Quadlet deployments, NixOS changes, firewall rules, or troubleshooting.

---

## Node Reference

| Node | OS | Container Runtime | Shell | Config Repo |
|---|---|---|---|---|
| Cerberus | Arch Linux (headless) | Podman rootless Quadlets | Bash + Starship | `~/veil/` |
| NightForge | Arch Linux | Podman rootless | Zsh + Starship | `~/Github/nightforge/` |
| Tairn | NixOS 24.11 | Docker (Mythic only) | Zsh + Starship | `/etc/nixos/configuration.nix` |

---

## Node-Specific Rules

**Cerberus:**
- Search with `grep`, not `rg` — ripgrep is not installed
- User Quadlets live in `~/.config/containers/systemd/` — managed as `foreverlx` user
- System Quadlets live in `/etc/containers/systemd/` — managed as root
- Always use `systemctl --user` for user-level Quadlets; `sudo systemctl` for system-level
- Real SSH is on port 2121. Port 22 is Cowrie honeypot — never SSH to port 22
- WireGuard hub: `10.0.0.1`. All mesh traffic routes through Cerberus

**NightForge:**
- Search with `rg` — ripgrep is installed and aliased
- Podman rootless only — no root containers
- WireGuard bring-up: `sudo resolvconf -u && sudo wg-quick up wg0`
- VM storage: `~/lab/VMs/`
- All repos under `~/Github/`

**Tairn:**
- Every config change goes in `/etc/nixos/configuration.nix` — no manual state outside of it
- Apply changes: `sudo nixos-rebuild switch`
- Verify after rebuild: `systemctl status <service>`
- Mythic CLI: `mythic <command>` (zsh alias) or `cd ~/Mythic && sudo ./mythic-cli`
- Mythic UI access: `https://10.0.0.4:7443` — WireGuard only, never exposed to LAN or WAN
- Docker is present for Mythic only — do not use Docker for anything else on Tairn

---

## Command Style Rules

Always provide:
1. The exact command with full path or explicit working directory when ambiguity exists
2. The verification step immediately after — show how to confirm the change took effect
3. The rollback path if the change can be reversed

Never:
- Show a command without context for where it runs (which node, which user)
- Leave a change unverified — every change gets a verification command
- Assume a service is running after a config edit without confirming

Example format:
```bash
# On Cerberus, as foreverlx
sudo cp /path/to/new.conf /etc/nftables.conf
sudo nft -c -f /etc/nftables.conf          # dry-run check
sudo systemctl restart nftables
sudo nft list ruleset | grep <changed_rule> # verify
```

---

## NixOS Change Workflow (Tairn)

Every change to Tairn follows this sequence without exception:

```
1. Edit:    sudo nvim /etc/nixos/configuration.nix
2. Check:   sudo nixos-rebuild dry-build          # optional but recommended for large changes
3. Apply:   sudo nixos-rebuild switch
4. Verify:  systemctl status <affected_service>
5. Commit:  cd /etc/nixos && sudo git add -A && sudo git commit -m "<type>: <description>"
```

If `nixos-rebuild switch` fails, the system remains on the previous generation. Roll back explicitly if needed:
```bash
sudo nixos-rebuild switch --rollback
```

Never make manual changes outside `configuration.nix` that you intend to persist. If something was set manually for testing, move it into `configuration.nix` before the session closes.

---

## Podman Quadlet Workflow (Cerberus)

For user Quadlets:

```
1. Edit:    nvim ~/.config/containers/systemd/<service>.container
2. Reload:  systemctl --user daemon-reload
3. Start:   systemctl --user start <service>
4. Verify:  systemctl --user status <service>
            podman ps | grep <container_name>
5. Logs:    journalctl --user -u <service> -n 50
6. Commit:  cd ~/veil && git add edge-node/containers/<service>.container
            git commit -m "<type>: <description>"
```

For system Quadlets:

```
1. Edit:    sudo nvim /etc/containers/systemd/<service>.container
2. Reload:  sudo systemctl daemon-reload
3. Start:   sudo systemctl start <service>
4. Verify:  sudo systemctl status <service>
5. Commit:  same as above
```

Health check verification (after deploying a Quadlet with `HealthCmd`):
```bash
# Confirm health check is wired correctly before assuming it works
/usr/lib/systemd/system-generators/podman-system-generator --user --dryrun 2>&1 | grep -A5 <service>
```

---

## Git Commit Format

All infrastructure commits follow conventional commits. Examples:

```
feat: add searxng Quadlet with autocomplete endpoint
fix: correct nftables WireGuard hairpin forward rule
docs: document Tairn WireGuard peer configuration
refactor: migrate gitea from hand-written unit to user Quadlet
security: lock Mythic port 7443 to WireGuard subnet via DOCKER-USER
```

Rules:
- Subject line: imperative mood, under 72 characters, no period
- Body (optional): explain *why*, not *what* — the diff shows what
- Never include IPs, tokens, keys, or internal hostnames in commit messages beyond what's already in public documentation
- Reference the troubleshooting doc in commit body if the change resolves a documented issue: `Resolves: docs/troubleshooting.md — <issue title>`

---

## What Never Goes in a Public Commit

| Category | Rule |
|---|---|
| Private keys, tokens, passwords | Never. Not even as examples or placeholders with "replace this" comments |
| Internal IPs beyond what Veil docs already disclose | Redact or use the documented names (cerberus, nightforge, tairn) |
| Internal hostnames not in public Veil documentation | Redact |
| Mythic operator credentials | Never |
| WireGuard private keys | Never — public keys only |
| Client or engagement identifiers | Never |

The Veil public documentation already discloses: node names, WireGuard IPs (10.0.0.x), LAN IP for Cerberus (192.168.1.251), service ports, and public keys. Everything else is internal.

---

## Troubleshooting Pattern

Work through this sequence before escalating or asking Claude to debug blind:

```
1. systemctl status <service>                    # is it running, what's the exit code
2. journalctl -u <service> -n 50 --no-pager      # last 50 log lines
   (use --user flag for user services)
3. Review the config file for the service        # look for syntax errors, wrong paths
4. Check ~/Github/veil/docs/troubleshooting.md   # documented issues and resolutions
5. Check for related system state:
   - nft list ruleset                            # firewall blocking?
   - ss -tlnp | grep <port>                      # port already in use?
   - podman ps -a                                # container exited?
   - wg show                                     # WireGuard connected?
```

If a new issue is resolved through debugging, add it to `docs/troubleshooting.md` before the session closes. Format: Issue → Root cause → Resolution → Lesson.

---

## Session Close Triggers

Suggest a session close with "Natural stopping point — session close?" when:

- A major infrastructure change is complete and verified (new service deployed, firewall rule change, WireGuard peer added)
- A NixOS rebuild completes successfully with verified service state
- A significant milestone is reached (first Mythic callback, new node integrated into mesh)
- The current task is done and the next task is a different domain

Do not suggest session close mid-task or when the current change is unverified.
