---
name: learning-session-standard
description: Use when Darrius asks Claude to help plan a learning session, work through a challenge or course module, document progress, or decide what to study next. Enforces the write-first rule, the three-condition completion standard, and the no-documentation-debt rule.
---

# Azrael Security Skill — Learning Session Standard
**Version:** 1.1
**Date:** 2026-03-19
**Purpose:** Define structure, sequencing, and output standards for learning sessions so every hour spent studying produces both retained understanding and a public artifact.
**Use when:** Darrius asks Claude to help plan a learning session, work through a challenge or module, document progress, or decide what to study next.

---

## Core Principle

Depth over breadth. Every learning session produces a public artifact or it did not happen.

Completing exercises is not the goal. Understanding the mechanism well enough to explain it, reproduce it, and write about it is the goal. A topic is done when three conditions are met:

1. You can explain why it works, not just what you did
2. You can reproduce it from scratch without notes
3. You have a written artifact committed to `security-research/`

If any of the three are missing, the topic is not done.

---

## Write-First Rule

For any session that builds a programming skill — Python scripting, Go challenges, C exercises — write the first attempt yourself before asking Claude to review or improve it. Even if it's wrong or ugly. Claude is a reviewer in these sessions, not a generator. The gap closes through writing, not through reading Claude's output and understanding it.

This rule applies to Bash as well. If Veil infrastructure needs a new script, write it yourself first.

---

## Session Structure

Every learning session follows this sequence:

```
1. Goal      — State one specific thing you intend to understand by the end
2. Work      — Do the challenge, lab, or module
3. Document  — Write the artifact before closing the session
4. Commit    — Push to security-research/ before moving on
```

Do not carry documentation debt forward. If a session ends without a committed artifact, the next session starts by writing that artifact — not by starting new material.

Claude's role in a learning session: help work through the mechanism, not hand over the answer. If Darrius is stuck, Claude explains the underlying concept and asks a clarifying question before showing a solution. Understanding is the output, not completion.

---

## What Counts as a Public Artifact

In order of value:

1. **A writeup** in `security-research/techniques/[category]/[name]/README.md` — follows the Research Writeup Standard (Skill 1). This is the target output for every completed challenge or research finding.
2. **A technique note** — shorter than a full writeup, but documents the mechanism, the tool invocation, and the MITRE ATT&CK mapping. Acceptable for course modules where a full writeup would be disproportionate.
3. **Committed code** — a working exploit, PoC, or tool committed to a repo with a meaningful commit message and inline comments explaining the why.
4. **A research question** — a documented open question that becomes the next session's goal. Acceptable only when the session surfaced something genuinely new that needs more investigation before it can be written up.

What does not count:
- Notes in a local file that are not committed
- Screenshots with no written explanation
- "I'll write it up later"

---

## Q1 Simultaneous Track Structure (March 20 – May 31, 2026)

Q1 runs three foreground tracks simultaneously. This is an explicit exception to sequential-within-quarter — the tracks reinforce each other and are scheduled on different days to prevent shallow attention splitting.

**Foreground tracks:**

| Track | Days | Target |
|---|---|---|
| Python offensive scripting | Tuesday + Thursday Block 1 | Write from scratch: port scanner → HTTP fuzzer → Impacket modification → custom tool |
| Networking hands-on | Monday + Wednesday Block 1 | Wireshark + tcpdump against live Veil infrastructure. Weekly capture targets. |
| CWL / CRTA | Friday Block 1 | One technique per session, reproduced end-to-end on Tairn, writeup committed to `security-research/techniques/ad/` |

**Background track (Block 2, same days):**

OST2 Arch1001 → OST2 Dbg1012 → Nightmare → pwn.college fundamentals. Sequential within the background track. Given existing asm/GDB exposure, Arch1001 + Dbg1012 combined is 4–6 weeks. Nightmare and pwn.college fundamentals begin by mid-to-late May.

Container boundary research runs Wednesday and Friday Block 2 as the Q1 project deliverable track.

**Early warning flag:** If any one of the three foreground tracks has zero sessions for two consecutive weeks, flag it at the Saturday review. Do not push through silently — reassess whether that track needs to be sequenced instead.

---

## Sequenced Learning Track (Q2 onward)

After Q1, tracks return to sequential-within-quarter unless the quarterly review explicitly overrides it. Phases are ordered by dependency — do not skip ahead.

**Phase 1 — Assembly and GDB (completes in Q1)**
Platform: OST2 Arch1001 → OST2 Dbg1012
Exit condition: Can read x86-64 disassembly without a decompiler, set breakpoints and inspect memory in GDB, and explain what happens at the stack frame level during a function call. Technique notes committed for each major concept.
Note: Given existing exposure, this phase moves fast. Don't linger on review material.

**Phase 2 — Binary Exploitation Foundations (Q1 end → Q2)**
Platform: Nightmare (bridge) → pwn.college fundamentals
Exit condition: Has completed at least one pwn.college dojo with all solutions documented. Can explain stack smashing, ret2win, and basic ROP from first principles. Writeups committed for representative challenges in each category.
Note: Nightmare is challenge-driven — it runs alongside early pwn.college naturally. Start by mid-May.

**Phase 3 — AD Hands-On Reproduction (Q2 foreground)**
Platform: CRTA continued — every technique reproduced end-to-end on Tairn before moving to the next
Exit condition: CRTA complete. Every technique has a lab reproduction and committed writeup in `security-research/techniques/ad/`. Theory you already have — this phase is the hands-on repetition pass.

**Phase 4 — CVE Root Cause Analysis (Q3)**
Platform: pwn.college (continued) + explorar.dev for kernel source navigation
Exit condition: Two published CVE root cause analyses in `security-research/`. Each mapped to CWE, CVSS scored manually, exploitability assessed, root cause traced in source. Pick CVEs from the container/namespace/Linux privilege boundary space.

**Phase 5 — Kernel Research (Q4+)**
Platform: OST2 Vulnerability Hunting & Exploitation learning path + explorar.dev
Exit condition: At least one published kernel-adjacent finding or CVE root cause analysis in `security-research/research/kernel/`.

**Go gap (runs alongside any phase):**
Platform: Protohackers — one challenge per week, written from scratch, committed to a private repo. Background work. Do not let it become the primary focus. Goal: 4–5 challenges by end of Q2, 8–10 by end of Q3.

---

## Platform-Specific Notes

**pwn.college:**
- Track dojo progress explicitly — which dojo, which module, which challenges completed
- Every module gets a technique note minimum; representative challenges get full writeups
- Do not move to the next dojo until the current one has committed documentation
- Follow pwn.college's policy on solution publication — writeups go public only after the dojo permits it

**OST2:**
- Follow the Vulnerability Hunting & Exploitation learning path sequentially — do not skip modules
- Each module produces a technique note committed to `security-research/techniques/`
- OST2 content is not public — technique notes document your understanding, not reproduced course material

**CWL / CRTA:**
- Every technique gets reproduced in the lab on Tairn before it counts as done
- Writeup committed to `security-research/techniques/ad/` for every technique — even short ones
- Theory without hands-on reproduction is not progress

**iximiuz.com:**
- Every lab must connect to a specific container boundary research question before starting it
- State the question at the top of the session goal before touching the lab
- If the lab does not answer a research question, deprioritize it

**Protohackers:**
- Each challenge produces a standalone Go file committed with a comment block explaining the protocol mechanic
- Write-first rule applies — no Claude-generated Go
- The goal is idiomatic Go under constraint, not just passing tests

**Networking hands-on:**
- Use live Veil infrastructure as the lab — Suricata alerts, Cowrie logs, WireGuard traffic, your own Python tool's traffic
- Weekly capture target goes in the session goal before opening Wireshark
- Document findings in a committed note — what you captured, what it means, what a defender sees

---

## When to Move On

A topic is ready to move on from when:
- The mechanism is understood well enough to explain it to another engineer without notes
- At least one artifact is committed
- The next phase's prerequisite is clearly met

A topic is not ready to move on from when:
- The exercises are complete but the writeup is not
- The solution worked but you cannot explain why
- There is documentation debt from this phase

When Darrius asks "should I move on," Claude checks these three conditions explicitly before answering.

---

## When Claude Is Helping With a Learning Session

1. Ask for the session goal before doing anything else — what specific mechanism or challenge is being worked on today?
2. Apply the write-first rule — do not generate code, scripts, or solutions for anything building a programming skill. Explain the concept, ask what Darrius has tried, point toward the mechanism.
3. If the session is ending, ask: "What's the artifact for this session?" If there isn't one, help write it before closing.
4. If documentation debt exists from a prior session, surface it at the start: "Last session covered X — is that writeup committed?"
5. When a phase exit condition is met, flag it explicitly and confirm before moving to the next phase.
6. For the Q1 simultaneous tracks specifically: if one track has been absent from recent sessions, name it before starting work on another track.
