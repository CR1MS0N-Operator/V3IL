# Veil Troubleshooting Runbook

Documented issues, root causes, and resolutions encountered during Veil
infrastructure builds. Maintained as an operational reference and
portfolio artifact demonstrating systematic debugging methodology.

---

## DNS & Networking

### Issue: .local.lan domains not resolving in browser
**Symptom:** Browser ignores system DNS for .local TLD, DNS_PROBE_POSSIBLE
**Root cause:** Browsers treat .local as mDNS (RFC 6762), bypassing system DNS
**Resolution:** Migrate all domains to .lan TLD — Pi-hole hosts file updated,
Caddyfile updated, all service URLs updated
**Lesson:** Never use .local for homelab DNS — use .lan, .home.arpa, or .internal

---

### Issue: NightForge loses all DNS when Cerberus goes offline
**Symptom:** All DNS resolution fails on NightForge including public internet
**Root cause:** Single DNS server (Pi-hole on Cerberus) with no fallback configured
**Resolution:** Added dual Cloudflare fallback to systemd-resolved drop-in at
/etc/systemd/resolved.conf.d/20-pihole.conf — DNS=192.168.0.251,
FallbackDNS=1.1.1.1 1.0.0.1, Domains=~lan
**Lesson:** Always configure fallback DNS — single point of failure for DNS
is unacceptable even in a homelab

---

### Issue: Cerberus not using its own Pi-hole for DNS
**Symptom:** curl https://search.lan fails on Cerberus, resolves fine externally
**Root cause:** /etc/resolv.conf managed by NetworkManager, pointing to 1.1.1.1
**Resolution:** Manually set resolv.conf to 192.168.0.251 as primary nameserver,
then used chattr +i to prevent NetworkManager from overwriting it
**Lesson:** Always verify the node hosting DNS is also using it

---

### Issue: Pasta container networking — containers cannot reach host services
**Symptom:** Homepage widgets returning errors, curl to host LAN IP fails
from inside container
**Root cause:** Pasta networking (rootless Podman default) — containers cannot
reach the host via its own LAN IP
**Resolution:** Use host.containers.internal for all intra-host container
communication. Added pasta rules to nftables for 169.254.0.0/16 in both
input and forward chains
**Lesson:** rootless Podman pasta networking requires host.containers.internal,
not the host LAN IP

---

### Issue: Mixed content blocking Netdata iframe
**Symptom:** Iframe blank, browser console shows Mixed Content error
**Root cause:** dash.lan served over HTTPS, Netdata iframe src was HTTP
**Resolution:** Point iframe src to https://netdata.lan via Caddy TLS proxy
**Lesson:** All resources on an HTTPS page must also be HTTPS

---

### Issue: Homepage SearXNG autocomplete failing
**Symptom:** No suggestions appearing, Homepage logs show httpProxy errors
**Root cause:** Homepage proxies suggestionUrl through its own backend container.
Container DNS could not resolve search.lan.
**Resolution:** Use host.containers.internal for suggestionUrl —
http://host.containers.internal:8888/autocompleter?q=
**Lesson:** Homepage proxies suggestion requests server-side — use internal
addressing, not .lan domains for widget URLs

---

### Issue: libvirt VMs cannot get DHCP lease after nftables migration
**Symptom:** VM gets no IP, DHCP discover packets visible on virbr0 via tcpdump
but dnsmasq never responds. journalctl shows no DHCPDISCOVER entries.
**Root cause:** nftables input chain policy DROP with no rule allowing UDP port 67
(DHCP). DHCP discover packets from VMs (source 0.0.0.0) don't match the existing
`ip saddr 192.168.122.0/24 iif "virbr0" accept` rule because they have no IP yet.
libvirt also defaults to iptables backend — must explicitly set nftables backend.
**Resolution:**
- Set firewall_backend = "nftables" in /etc/libvirt/network.conf
- Add `iif "virbr0" udp dport 67 accept` to nftables input chain
- Restart libvirtd after backend change
**Lesson:** When migrating to nftables, audit all services that inject firewall
rules (libvirt, Docker, etc.) and ensure backend alignment. DHCP is stateless
and pre-IP — it will never match source IP rules.

---

## Containers & Quadlets

### Issue: Podman socket missing after container restart
**Symptom:** Homepage docker integration failing, ENOENT podman.sock errors
**Root cause:** Podman socket service stopped, socket file removed
**Resolution:** systemctl --user start podman.socket and add
After=podman.socket + Requires=podman.socket to dependent Quadlets
**Lesson:** Podman socket is ephemeral — dependent services must declare it

---

### Issue: Quadlet health checks not evaluating
**Symptom:** Containers show "Up X minutes" without healthy/unhealthy status
**Root cause:** HealthCmd keys appended after [Install] section instead of
inside [Container] section — Quadlet generator silently ignored them
**Resolution:** Health check keys must be inside [Container] section.
Always verify with: /usr/lib/systemd/system-generators/podman-system-generator
--user --dryrun to confirm flags appear in generated ExecStart
**Lesson:** Always verify Quadlet output with --dryrun before restarting services

---

### Issue: Cowrie container has no shell utilities for health checks
**Symptom:** All health check commands fail — no curl, bash, ps, or pgrep
**Root cause:** Cowrie uses a minimal distroless-style image
**Resolution:** Skip health check for Cowrie. Monitor via
docker_local.containers_state chart in Netdata instead
**Lesson:** Not all containers support health checks — document as known
limitation rather than forcing an inappropriate solution

---

### Issue: SearXNG ownership conflict after first container run
**Symptom:** sed/chmod on config files returns "Operation not permitted"
**Root cause:** Container ran as UID 100976, took ownership of mounted config files
**Resolution:** sudo chown -R foreverlx:foreverlx ~/searxng/config/
Stop container before editing mounted config files
**Lesson:** Stop containers before editing their mounted config volumes

---

## WireGuard

### Issue: wg-quick fails with resolvconf signature mismatch
**Symptom:** wg-quick up/down fails, interface deleted immediately on exit
**Root cause:** /etc/resolv.conf modified outside resolvconf control
**Resolution:** sudo resolvconf -u then retry wg-quick up
**Lesson:** Run resolvconf -u before bringing up WireGuard if resolv.conf
was manually modified

---

### Issue: WireGuard hub-and-spoke peers cannot reach each other through hub
**Symptom:** NightForge cannot ping Tairn via 10.0.0.4, packets arrive at
Cerberus but are never forwarded. tcpdump on wg0 shows requests with no replies.
**Root cause:** Two compounding issues:
1. Kernel rp_filter (Reverse Path Filter) drops packets that arrive and would
   be forwarded back out the same interface — a security feature that treats
   same-interface forwarding as spoofing
2. nftables forward chain missing an explicit iif "wg0" oif "wg0" accept rule
   for same-interface forwarding (hairpin traffic)
**Resolution:**
- Set rp_filter=0 on wg0 and all interfaces via /etc/sysctl.d/99-wireguard.conf
- Add `iif "wg0" oif "wg0" accept` to nftables forward chain
- Add explicit host routes for each spoke: `ip route add 10.0.0.x/32 dev wg0`
  via PostUp in wg0.conf on Cerberus
**Lesson:** WireGuard hub-and-spoke requires explicit kernel configuration for
hairpin forwarding. rp_filter is a legitimate security control — document the
tradeoff. Cryptographic peer authentication in WireGuard mitigates the spoofing
risk that rp_filter normally guards against.

---

### Issue: Tairn WireGuard peer config drift after reboot

**Symptom:** Cerberus wg show shows Tairn endpoint as 192.168.1.145:50555 (NightForge's LAN IP), no handshake
**Root cause:** Stale endpoint cached from prior session, wrong IP written into Cerberus wg0.conf. Tairn config also had allowedIPs = 10.0.0.0/24 on Cerberus peer instead of 10.0.0.1/32, causing route conflict
**Resolution:** Corrected Cerberus wg0.conf — removed Tairn endpoint entirely (Tairn initiates). Corrected Tairn configuration.nix — 10.0.0.1/32 on Cerberus peer, removed direct endpoint from NightForge peer
**Lesson:** In hub-and-spoke, spokes initiate to hub only. Hub should have no endpoint for spokes — WireGuard learns it dynamically. Never set a spoke-to-spoke direct endpoint.

---

### Issue: vnet0 not attached to virbr0 after reboot (Tairn unreachable)

**Symptom:** ssh tairn fails, bridge link show empty, virbr0 shows NO-CARRIER, Tairn has no default route
**Root cause:** nftables failed at boot (referenced virbr0 before it existed), leaving libvirt without NAT rules. Race condition between libvirt VM start and bridge attachment — vnet0 created but never added to virbr0
**Resolution:** Removed virbr0 references from /etc/nftables.conf (libvirt manages its own rules). Created /etc/systemd/system/vnet0-bridge-fix.service — oneshot after libvirtd.service that runs ip link set vnet0 master virbr0 && ip link set vnet0 up
**Lesson:** When two subsystems have implicit ordering dependencies (libvirt bridge attachment vs nftables load), enforce it explicitly with a oneshot systemd service. After= is the correct tool, not manual intervention.

---

## TLS & Caddy

### Issue: Caddy CA certificate not trusted on Cerberus itself
**Symptom:** curl returns empty for https://*.lan from Cerberus
**Root cause:** Local CA cert installed on NightForge but not on Cerberus
**Resolution:** Copy root.crt from Caddy container to
/etc/ca-certificates/trust-source/anchors/ then run update-ca-trust run
**Lesson:** Install local CA on every node including the node running Caddy

---

## Pi-hole

### Issue: Pi-hole v6 Homepage widget incompatible
**Symptom:** Pi-hole widget shows no data
**Root cause:** Pi-hole v6 changed to session-based API authentication.
Homepage widget not updated for v6 API.
**Resolution:** Remove Pi-hole widget, monitor via direct link to pihole.lan/admin
**Lesson:** Check widget compatibility before upgrading self-hosted services

---

## System

### Issue: User Quadlets not starting after reboot on headless node
**Symptom:** All user services down after reboot with no active SSH session
**Root cause:** systemd user session not started without active login
**Resolution:** loginctl enable-linger foreverlx
**Lesson:** Always enable linger for headless nodes running user Quadlets

---

### Issue: Pi-hole slow to start after reboot
**Symptom:** DNS resolution unavailable for several minutes post-boot
**Root cause:** Hand-written systemd unit with no proper dependency ordering,
replaced by Quadlet with correct After= directives
**Resolution:** Migrate to system Quadlet — faster startup, proper dependency
management, consistent with rest of stack
**Lesson:** Hand-written podman-generate-systemd units are fragile —
always use Quadlets for new deployments

---

### Issue: Cerberus soft/hard lockups — raydium_ts touchscreen IRQ storm (Chromebook hardware)
**Symptom:** Kernel watchdog fires repeatedly across multiple CPUs. Escalation pattern: soft lockups on one CPU after hours of uptime → hard LOCKUPs on multiple CPUs within seconds of boot. Watchdog points at Podman PID — misleading.
**Root cause:** raydium_ts touchscreen hardware on the Chromebook generates a sustained IRQ storm (~425 interrupts/sec on IRQ 117) regardless of whether the driver is bound. Unbinding the driver stops the driver from handling interrupts but does not stop the hardware from firing them. The unhandled IRQ storm saturates whichever CPU IRQ 117 is affinitized to, eventually cascading to hard lockups across all CPUs.
**Resolution — three-layer fix (all three required):**
1. Blacklist the driver: `echo "blacklist raydium_ts" | sudo tee /etc/modprobe.d/disable-raydium.conf` — prevents driver from attaching, but insufficient alone due to mkinitcpio autodetect hook baking the module into initramfs
2. Udev unbind rule: `/etc/udev/rules.d/99-disable-raydium.rules` with `ACTION=="add", SUBSYSTEM=="i2c", KERNELS=="i2c-RAYD0001:00", ATTR{driver/unbind}="i2c-RAYD0001:00"` — unbinds device at boot, removes it from interrupt table in most cases
3. IRQ affinity pin: `echo 8 | sudo tee /proc/irq/117/smp_affinity` persisted via `/etc/tmpfiles.d/mask-raydium-irq.conf` with `w /proc/irq/117/smp_affinity - - - - 8` — pins IRQ 117 to CPU3 only if hardware fires anyway, containing the storm to one CPU
**Verification:** After reboot, `cat /proc/interrupts | grep RAYD` should return empty. `cat /proc/irq/117/smp_affinity` should return `8`. No lockup entries in `sudo journalctl -k -b 0 | grep -iE "lockup|hard LOCKUP"`.
**Lesson:** Unbinding a driver does not silence the hardware IRQ. On misbehaving embedded hardware (touchscreens, sensors), check `/proc/interrupts` for the IRQ counter even after unbind — if it's still climbing, the hardware is firing and IRQ affinity pinning is required. Watchdog PID is never the root cause — check `irq/` threads and `/proc/interrupts` first.

---

### Issue: User Quadlets not starting after reboot — degraded session state
**Symptom:** All user Quadlets show as not registered after reboot. `systemctl --user list-units` returns nothing for container services. No failed units — services simply absent.
**Root cause:** Linger is enabled but the user session came up in a degraded state after multiple hard crashes. The Quadlet generator did not run automatically, so no units were generated or registered.
**Resolution:** `systemctl --user daemon-reload` triggers the Quadlet generator to scan `~/.config/containers/systemd/`, generate units, and auto-start them.
**Lesson:** If user Quadlets are missing entirely (not failed, not inactive — absent), daemon-reload is the fix. Distinct from the linger issue where services fail to start — this is a generator registration failure.

---

### Issue: Gitea SSH push hangs or permission denied from NightForge
**Symptom:** `git push` to git.lan hangs or returns permission denied
**Root cause:** Two compounding issues:
1. git.lan resolves to LAN IP (192.168.1.251) — Gitea SSH port 2222 is
   WireGuard-only per nftables access model, not accessible via LAN
2. Remote URL had `foreverlx` as SSH user — Gitea requires `git` as the
   system SSH user regardless of account name
**Resolution:** SSH config Host git.lan must use HostName 10.0.0.1 (WireGuard).
Remote URL format: ssh://git@git.lan:2222/<account>/<repo>.git
**Lesson:** Gitea SSH user is always `git`. WireGuard-only services are not
reachable via LAN IP — use WireGuard IP in SSH config HostName.

---

## libvirt / VMs

### Issue: virsh shows empty VM list despite VMs existing
**Symptom:** `virsh list --all` returns empty, VMs visible in virt-manager
**Root cause:** virsh defaults to `qemu:///session` (user session libvirt). VMs are defined under `qemu:///system` (system libvirt). Different URI, different domain registry.
**Resolution:** Set `LIBVIRT_DEFAULT_URI="qemu:///system"` in `~/.config/environment.d/99-nightforge.conf`
**Lesson:** Always specify `--connect qemu:///system` or set the env var permanently. Domain XML definitions should be committed to veil repo to survive definition loss.

---

## OpenCode

### Issue: OpenCode TUI hangs on launch with no output
**Symptom:** `opencode` command hangs silently, no TUI renders, no stderr output
**Root cause:** `/tmp` mounted with `noexec` — OpenCode extracts a `.so` render library to `/tmp` at startup and dlopen()s it. noexec prevents the kernel from mapping executable segments from tmpfs.
**Resolution:** `sudo mount -o remount,exec /tmp` — make permanent via `sudo systemctl edit tmp.mount` adding `Options=rw,nosuid,nodev,noatime,inode64,huge=within_size`
**Diagnosis:** `opencode --print-logs 2>&1` reveals the actual error inline
**Lesson:** Always run `--print-logs` first when a TUI tool hangs silently. noexec on /tmp breaks any tool that extracts and loads native libraries at runtime.`

---

## Dashboard / API Integration

### Issue: Pi-hole v6 API returns api_seats_exceeded
**Symptom:** Dashboard Pi-hole collector returns null, Pi-hole API returns
`{"error": {"key": "api_seats_exceeded"}}` on auth attempts
**Root cause:** Pi-hole v6 has a max_sessions limit. Collector was
authenticating on every collectOps() cycle (~every 30s), exhausting the
session table. Sessions accumulate until the limit is hit — subsequent
auth attempts are rejected entirely.
**Resolution:** Cache the session SID at the package level with a 10-minute
TTL. On 401 response, clear the cache and re-authenticate once, then retry.
This reduces session creation from ~120/hour to ~6/hour.
**Lesson:** Pi-hole v6 uses session-based auth with a hard session limit.
Any automated collector must cache and reuse the SID. sqlite3 is not
available in the Pi-hole container to manually clear sessions. Restart the
container to flush all sessions if the table is exhausted.

---

### Issue: NixOS docker-firewall rules not applying — DOCKER-USER chain missing at boot
**Symptom:** DOCKER-USER iptables rules added via `networking.firewall.extraCommands`
have no effect. `iptables -L DOCKER-USER` shows only the default RETURN rule.
**Root cause:** NixOS firewall service starts at boot before Docker. The
DOCKER-USER chain is created by Docker at runtime. When extraCommands runs,
the chain does not yet exist — rule insertion fails silently.
**Resolution:** Create a dedicated systemd oneshot service with
`After=docker.service` that inserts DOCKER-USER rules after Docker starts.
Include a retry loop waiting for the chain to exist before inserting rules.
```nix
systemd.services.docker-firewall = {
  after = [ "docker.service" ];
  requires = [ "docker.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStart = pkgs.writeShellScript "docker-firewall-start" ''
      for i in $(seq 1 10); do
        ${pkgs.iptables}/bin/iptables -L DOCKER-USER -n &>/dev/null && break
        sleep 1
      done
      ${pkgs.iptables}/bin/iptables -I DOCKER-USER 1 -p tcp --dport 7443 -j DROP
      ${pkgs.iptables}/bin/iptables -I DOCKER-USER 1 -s 10.0.0.0/24 -p tcp --dport 7443 -j ACCEPT
    '';
  };
};
```
**Lesson:** NixOS `networking.firewall.extraCommands` runs at firewall service
start — before Docker creates its chains. Never use extraCommands for
Docker-specific firewall rules. Always use a post-Docker oneshot service.

---

### Issue: Mythic GraphQL endpoint returns 301
**Symptom:** POST to `https://10.0.0.4:7443/graphql` returns 301 Moved Permanently
**Root cause:** Mythic nginx requires trailing slash on the GraphQL endpoint.
Without it nginx redirects, which breaks POST requests (redirect changes POST
to GET).
**Resolution:** Use `https://10.0.0.4:7443/graphql/` (trailing slash). If using
curl, add -L to follow redirects during debugging but fix the URL in code.
**Lesson:** Always verify GraphQL endpoint URLs with a direct curl before
writing collector code. Trailing slash requirements are nginx config-specific.

---

### Issue: Mythic GraphQL c2profile query fails — server_type field missing
**Symptom:** GraphQL query `{ c2profile { name running server_type } }` returns
validation error: "field 'server_type' not found in type: 'c2profile'"
**Root cause:** server_type field does not exist on the c2profile type in
Mythic v3.4.x. The field was either removed or never existed in this version.
**Resolution:** Remove server_type from the query. Correct query:
`{ c2profile { name running } }`
**Lesson:** Always introspect the GraphQL schema before writing queries against
a specific Mythic version. Field availability varies by version.

---

### Issue: Beszel API returns abbreviated field names in info blob
**Symptom:** Beszel `/api/collections/systems/records` returns metrics as
single-letter abbreviated keys (cpu, mp, dp, g, u, la) not descriptive names
**Root cause:** Beszel stores metrics as a compact JSON blob using abbreviated
keys to minimize storage. The schema is internal and not documented publicly.
**Resolution:** Decode from a live API response before writing any collector
code. Confirmed mapping:
  cpu → CPU usage %
  mp  → memory used %
  dp  → disk used %
  g   → GPU usage % (absent if no GPU)
  u   → uptime seconds
  la  → load average array [1m, 5m, 15m]
  v   → agent version
  status field (top-level) → "up" | "down" | "paused"
Metrics are returned inline in the systems collection — no separate
system_stats fetch needed for current values.
**Lesson:** Always curl the live API and inspect the actual response before
writing struct definitions. Do not assume field names from documentation.
