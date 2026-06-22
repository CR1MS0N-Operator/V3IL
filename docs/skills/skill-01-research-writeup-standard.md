---
name: research-writeup-standard
description: Use when Darrius asks Claude to help write, review, structure, or improve any security research artifact — RE writeup, container boundary finding, CVE analysis, vulnerability research note, or technique documentation. Governs section order, tone, redaction standards, and the publication-ready checklist.
---

# Azrael Security Skill — Research Writeup Standard
**Version:** 1.0
**Date:** 2026-03-19
**Purpose:** Define the structure, quality bar, and publication standards for all security research writeups produced under the Azrael Security brand.
**Use when:** Darrius asks Claude to help write, review, structure, or improve any security research artifact — RE writeup, container boundary finding, CVE analysis, vulnerability research note, or technique documentation.

---

## Quality Bar

The re-1 and re-2 writeups in `security-research/techniques/linux/re/` are the reference standard. Every writeup Claude helps produce must match or exceed that bar before it is considered publication-ready. A draft becomes publication-ready when it passes all criteria in the checklist at the end of this file.

---

## Standard Structure

Every writeup follows this section order. Do not reorder, do not skip sections. A section may be brief — it may not be absent.

### 1. Metadata Block

```
**Challenge / Target:** [name]
**Platform / Context:** [stacksmash.io / pwn.college / CVE-XXXX / Cerberus live infra / etc.]
**Category:** [RE / pwn / web / container / kernel / infra]
**Difficulty:** [Easy / Medium / Hard / or platform rating if available]
**Tools Used:** [comma-separated list]
**Date:** YYYY-MM-DD
**Time Spent:** [honest estimate — "~2 hours" is fine]
**ATT&CK Mapping:** [T-number and technique name, or "N/A" — never omit the field]
```

### 2. Objective

One to three sentences. State what the challenge or research question asks you to do, or what vulnerability class is being examined. Do not state the answer here. Do not pad.

### 3. Reconnaissance / Initial Analysis

What you observed before you knew how to solve it. What the binary, system, or target looks like from the outside. Static analysis output, file type, protections, surface area. This section should be reproducible — someone following along should be able to reach the same starting observations.

### 4. Analysis

The main technical work. Walk through the mechanism being exploited or studied. Explain *why* it works, not just *what* you did. Show relevant disassembly, code, or command output inline using code blocks. Annotate snippets — do not paste raw output without explanation. If the path had dead ends, include them briefly with why they failed. Dead ends are signal.

### 5. Outcome / Exploit / Finding

What the result was. Flag value, proof of concept, confirmed behavior, or confirmed vulnerability. Keep this brief — the analysis section carries the weight.

### 6. Key Takeaways

Two to five bullet points. What does this writeup teach a practitioner? State the generalizable principle, not just what happened in this specific case. This is the section other engineers will skim first — make it worth their time.

### 7. Defensive Notes

One to four sentences. How would a defender detect or prevent this? If not applicable (pure RE challenge with no defensive angle), write "N/A — challenge context only." Never omit the section.

### 8. References

Link anything cited or used: man pages, CVE advisories, tool documentation, prior research. No minimum count. No invented citations.

---

## Tone and Voice

- Audience: security engineers. Assume they know what GDB is. Do not define ELF.
- Write in first person past tense for the narrative sections (Analysis, Outcome). Use present tense for facts and principles (Key Takeaways, Defensive Notes).
- One idea per sentence. No compound sentences that obscure causality.
- Technical precision over approachability. If a term has a correct name, use it.
- No filler phrases: "interesting," "fascinating," "it's worth noting that," "as we can see."

---

## Redaction Standards

Apply before any public commit. These rules are non-negotiable.

| What | How |
|---|---|
| Flag / answer value | `[REDACTED]` inline, note "flag redacted" in a comment if needed |
| Specific input that triggers the vulnerability (if writeup is for a live/unreleased challenge) | Replace with description of input class, not the value |
| IP addresses beyond what's already public in the Veil docs | `[IP_REDACTED]` |
| Internal hostnames not already in public Veil documentation | `[HOST_REDACTED]` |
| Credentials of any kind | Never appear, not even as examples |
| Client identifiers | Never appear |
| Personal email or contact info beyond what's on the GitHub profile | Never appear |

Do not redact: tool names, technique names, CVE numbers, MITRE ATT&CK IDs, general system architecture, or anything already in public Veil documentation.

---

## What Never Appears in a Public Writeup

- Live system credentials or tokens
- Internal network topology beyond what Veil documentation already discloses
- Client names, client infrastructure, or details from paid engagements
- Unreleased vulnerability details before responsible disclosure is complete
- Writeups for active CTF competitions while they are running (only after the competition closes)

---

## Writeup Skeleton

Use this as the starting template. Fill every section before considering a writeup complete.

```markdown
**Challenge / Target:**
**Platform / Context:**
**Category:**
**Difficulty:**
**Tools Used:**
**Date:**
**Time Spent:**
**ATT&CK Mapping:**

## Objective

## Reconnaissance / Initial Analysis

## Analysis

## Outcome

## Key Takeaways

-
-
-

## Defensive Notes

## References

-
```

---

## Publication-Ready Checklist

Claude should run this before marking any writeup as ready to commit.

- [ ] All eight sections present and non-empty
- [ ] Metadata block complete — no blank fields
- [ ] ATT&CK mapping field populated (even if N/A)
- [ ] No filler language
- [ ] All code blocks annotated — no unexplained raw output
- [ ] Redaction pass complete
- [ ] Key Takeaways state generalizable principles, not just what happened
- [ ] Defensive Notes present
- [ ] File path follows `security-research/techniques/[category]/[name]/README.md`
- [ ] Ready to commit with message: `docs: add [name] writeup ([category])`
