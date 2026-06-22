---
name: container-boundary-research-methodology
description: Use when Darrius is working on any container boundary research session — scoping a research question, running lab work, reproducing a behavior, writing up a finding, or deciding whether a result meets the publication threshold.
---

# Azrael Security Skill — Container Boundary Research Methodology
**Version:** 1.0
**Date:** 2026-03-19
**Purpose:** Define the research methodology, finding standards, and publication threshold for container boundary research conducted under the Azrael Security brand.
**Use when:** Darrius is working on any container boundary research session — scoping a new question, reproducing a behavior, writing up a finding, or deciding whether something is publication-ready.

---

## Research Direction

The flagship research track investigates Linux container isolation boundaries as they apply to real offensive infrastructure. Three tracks in order of priority:

1. **Filesystem and mount abuse** — overlayfs behavior, bind mount escapes, volume permission misconfigurations in rootless Podman and Docker contexts
2. **Namespace privilege boundaries** — user namespace privilege mapping, PID/mount namespace isolation failures, capability leakage across namespace transitions
3. **Process visibility leaks** — `/proc` exposure from within containers, cross-container PID visibility under different namespace configurations

All research runs on live Veil infrastructure — Cerberus (rootless Podman, Arch Linux) and Tairn (Docker, NixOS 24.11). Not synthetic lab VMs. This is the differentiator and must be reflected in every writeup.

---

## The Research Question Standard

Every research session starts with a single, answerable question. Not a topic — a question.

**Good research questions:**
- "Does overlayfs in rootless Podman expose host mount points to a container process when the host path is bind-mounted with `:z` relabeling?"
- "Can a process inside a rootless Podman container enumerate PIDs from the host via `/proc` when `--pid=host` is not set?"
- "Does a user namespace mapping in rootless Podman prevent capability escalation if the container runs as UID 0 inside but maps to UID 1000 outside?"

**Bad research questions (too broad, not answerable in one session):**
- "How does overlayfs work?"
- "What are namespace vulnerabilities?"
- "Is rootless Podman secure?"

The test: can you state what a positive result looks like and what a negative result looks like before you start the lab work? If not, the question isn't scoped tightly enough.

Write the research question at the top of every session's goal before touching the lab. If the session doesn't answer the question, the next session either answers it or explicitly reframes it — it does not silently move on.

---

## Observation vs. Finding

Not every lab result is a finding. Claude should apply this distinction before any writeup begins.

**An observation** is a behavior you noticed that may or may not be significant. It requires more investigation before it can be stated as a finding. Observations get documented in a research note committed to `security-research/research/container-boundaries/notes/` — not published as findings.

**A finding** meets all four criteria:
1. **Reproducible** — the behavior occurs consistently under defined conditions, not just once
2. **Attributable** — you can identify the specific kernel feature, configuration, or runtime behavior that causes it
3. **Scoped** — you know the exact conditions under which it occurs and the conditions under which it does not
4. **Impactful** — there is a concrete consequence: information disclosure, privilege boundary violation, isolation bypass, or exploitation primitive

If any of the four are missing, it is an observation. Document it, continue investigating, do not publish it as a finding.

---

## Reproduction Standard

A behavior is not confirmed until it is reproduced under controlled conditions. Reproduction requires:

1. **Defined environment:** kernel version, container runtime version, configuration flags, user namespace state. Record these exactly — a finding that only reproduces on kernel 6.x with a specific Podman version is still a valid finding, but the scope must be stated.
2. **Minimal reproduction case:** strip the reproduction down to the smallest set of conditions that still trigger the behavior. If it requires a 20-step setup, keep reducing until you have the minimum. The minimal case is what goes in the writeup.
3. **Negative control:** confirm the behavior does not occur when the relevant condition is absent. A finding without a negative control is an observation.
4. **Cross-runtime check where applicable:** if the finding is in rootless Podman, check whether it reproduces in Docker on Tairn. Document both results. A finding that reproduces across runtimes is higher impact than one that is runtime-specific.

Record the exact commands used to reproduce. These go verbatim into the writeup — no paraphrasing reproduction steps.

---

## CWE Mapping Standard

Every published finding maps to a CWE. This is non-negotiable — it connects the finding to the broader vulnerability taxonomy and is required for the CVE analysis track that builds on this work.

Process:
1. Identify the root cause category — is this an improper isolation, an information exposure, a privilege boundary failure, a configuration weakness?
2. Search the CWE database for the most specific applicable weakness. Do not default to broad parent CWEs when a specific child CWE exists.
3. State the CWE number and name explicitly in the writeup: "CWE-250: Execution with Unnecessary Privileges" not just "privilege issue."
4. If no single CWE maps cleanly, use the closest match and note the gap — do not force a fit.

Common CWEs for this research track:
- CWE-250: Execution with Unnecessary Privileges
- CWE-269: Improper Privilege Management
- CWE-284: Improper Access Control
- CWE-200: Exposure of Sensitive Information to an Unauthorized Actor
- CWE-668: Exposure of Resource to Wrong Sphere
- CWE-732: Incorrect Permission Assignment for Critical Resource

---

## Impact Analysis Standard

Every published finding includes an impact analysis. Format:

**Confidentiality impact:** Does this expose data or system state that should be isolated? What specifically can be read?
**Integrity impact:** Does this allow modification of host or container state that should be protected? What specifically can be written or changed?
**Availability impact:** Does this create a denial of service condition or resource exhaustion vector?
**Exploitation context:** Under what real-world conditions would an attacker reach this primitive? What does it enable — information gathering, lateral movement, privilege escalation, persistence?

Do not overstate impact. A `/proc` visibility leak that exposes PIDs is not a container escape — state exactly what it is and what it enables. Overstated impact undermines credibility. Understated impact leaves value on the table. State it precisely.

---

## Publication Threshold

A finding is ready to publish when it passes all of the following:

- [ ] Research question answered with a definitive result (positive or negative)
- [ ] Reproduction confirmed under defined conditions with exact commands documented
- [ ] Negative control confirmed
- [ ] Minimal reproduction case identified
- [ ] CWE mapped
- [ ] Impact analysis complete — no overstating, no understating
- [ ] Environment documented: kernel version, runtime version, configuration
- [ ] Writeup follows the Research Writeup Standard (Skill 1) — all eight sections present
- [ ] Redaction pass complete — no internal IPs, hostnames, or credentials beyond what Veil docs already disclose
- [ ] Committed to `security-research/research/container-boundaries/` with path `[track]/[finding-name]/README.md`

A negative result — a behavior that does not occur — is also publishable if the question was well-formed and the investigation was rigorous. "Rootless Podman does not expose host PIDs via /proc under default configuration" is a valid finding. It closes a question and provides signal to defenders and other researchers.

---

## File Structure

```
security-research/research/container-boundaries/
├── README.md                          # Research overview, active questions, published findings index
├── notes/                             # Observations not yet confirmed as findings
│   └── YYYY-MM-DD-[observation].md
├── filesystem-mounts/                 # Track 1
│   └── [finding-name]/
│       └── README.md
├── namespace-analysis/                # Track 2
│   └── [finding-name]/
│       └── README.md
└── proc-visibility/                   # Track 3
    └── [finding-name]/
        └── README.md
```

The `README.md` at the root of `container-boundaries/` is a living index. Update it every time a finding is published or a new observation is added to notes. It should always reflect the current state of the research track accurately — no aspirational entries.

---

## Connecting Findings to the Broader Research Track

Individual findings compound. After two or three findings are published, look for the pattern:

- Do the findings share a root cause? (e.g., multiple findings that trace back to overlayfs layer handling)
- Do they form an attack chain? (e.g., a PID leak enables targeted signal injection via a mount abuse primitive)
- Do they identify a specific kernel subsystem or runtime component as the locus of weakness?

When a pattern emerges, document it in the `container-boundaries/README.md` as a research thread — not a finding, but a direction for the next set of research questions. This is what turns a collection of individual writeups into a body of research with a coherent argument. That body of research is what HackSpaceCon and future conference abstracts are built from.

---

## When Claude Is Helping With Container Research

1. Ask for the research question before any lab work starts — it must be stated in answerable form before Claude engages with the technical details.
2. Apply the observation vs. finding distinction before any writeup begins — if the four criteria aren't met, the session produces a research note, not a finding.
3. Confirm the reproduction standard is met before the writeup draft starts — exact commands, negative control, minimal case.
4. Run the publication threshold checklist before marking any finding as ready to commit.
5. Never overstate impact in draft copy — if a draft says "container escape" when the finding is a visibility leak, correct it before delivering.
6. When a pattern across findings starts to emerge, surface it explicitly: "This is the second finding that traces back to overlayfs layer handling — worth documenting as a research thread in the index."
