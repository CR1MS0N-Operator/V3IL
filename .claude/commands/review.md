Review the specified file or diff for correctness, safety, and alignment with Veil
infrastructure standards.

For config files (WireGuard, NixOS, nftables, Quadlets, Caddyfile):
- Identify any syntax errors or misconfigurations
- Flag anything that could break mesh connectivity
- Flag anything that violates the hub-and-spoke topology rules
- Explain what each changed block does mechanically
- Surface failure modes before suggesting any change
- Never suggest applying changes — operator applies all infra changes manually

For documentation (troubleshooting.md, skill files, README):
- Check for accuracy against current node state
- Flag anything stale or contradicted by recent changes
- Suggest specific corrections with reasoning

Output: structured findings with severity (critical / warning / info), explanation
of the mechanism, and suggested correction if applicable. No filler.
