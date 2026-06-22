# CR1MS0N — Skill Files Creation

## What We're Building

Skill files are structured markdown documents uploaded to the CR1MS0N Claude project. Claude references them automatically in every conversation, giving persistent, consistent behavior without repeating context. They are not Claude Code plugins — they are knowledge files that teach Claude how to work with you specifically.

Each skill file should be:
- Focused on one domain or workflow
- Written as instructions Claude follows, not documentation you read
- Concrete enough that Claude produces consistent outputs without prompting
- Under ~500 lines so it loads efficiently

## Skill Files to Create

Work through these one at a time. For each skill, produce a complete, ready-to-save markdown file. Pause after each one and wait for approval before proceeding to the next.

---

### Skill 1 — Research Writeup Standard

**Purpose:** Every RE writeup, container boundary finding, CVE analysis, or vulnerability research artifact Claude helps produce should follow the same format and quality bar as re-1 and re-2.

Produce a skill file that defines:
- The standard structure for a security research writeup (metadata block, objective, recon, analysis, outcome, key takeaways, defensive notes, references)
- Quality criteria: what makes a writeup publication-ready vs. a draft
- Redaction standards: what gets redacted and how (flags, specific inputs, IP addresses)
- Tone and voice: technical but readable, assumes security engineer audience
- What should never appear in a public writeup (credentials, live system details, client identifiers)
- Example skeleton Claude should use as a starting template

Reference the re-1 and re-2 writeups as the quality standard without reproducing them. Claude should match or exceed that bar.

---

### Skill 2 — Infrastructure Operations Standard

**Purpose:** When working on Veil infrastructure (Cerberus, NightForge, Tairn), Claude should follow consistent patterns for commands, config changes, commits, and documentation.

Produce a skill file that defines:
- Node-specific rules (rg vs grep, NixOS rebuild requirement, Podman vs Docker per node)
- Command style: always show full paths, always show verification step after a change
- NixOS change workflow: edit configuration.nix → nixos-rebuild switch → verify
- Podman Quadlet workflow: edit .container file → daemon-reload → start/verify
- Git commit format for infrastructure changes (with examples per type: feat/fix/docs/refactor/security)
- What never goes in a public commit (IPs, tokens, keys, internal hostnames beyond what's already documented)
- Troubleshooting pattern: check service status → check logs → check config → check troubleshooting.md
- When to suggest a session close (major infra change complete, significant milestone reached)

---

### Skill 3 — Job Application & Career Filter

**Purpose:** When evaluating job postings or drafting application materials, Claude should apply a consistent filter and produce consistent output quality.

Produce a skill file that defines:
- The north star role: Vulnerability Researcher at runZero-level companies (Go-heavy, Linux-native, research-focused, ideally founded by practitioner)
- Application rule: sub-3-years experience requirement + north star alignment check
- The 60-second filter: questions to ask of any job posting to decide apply now / save for later / skip
- Tier definitions:
  - Tier 1 (apply now): contract/entry roles that build experience and pay; Alignerr-type
  - Tier 2 (3-6 months): junior pentest, associate security analyst, security engineer
  - Tier 3 (12+ months): vulnerability researcher, red team engineer, security researcher at product companies
- Company watchlist and why each matters (runZero, Red Siege, Sprocket, Scythe, Nvidia)
- Resume framing principles: lead with infrastructure (Veil, Mythic C2, WireGuard mesh), then research (RE writeups, container boundary research), then certifications
- Cover letter / application tone: direct, no filler, let the work speak, reference specific technical artifacts
- What to never include in an application: CTF rankings as primary credential, generic objective statements, skills lists without context

---

### Skill 4 — Learning Session Standard

**Purpose:** When working through learning resources (OST2, pwn.college, iximiuz, etc.), Claude should help structure sessions for maximum retention and portfolio output.

Produce a skill file that defines:
- The learning principle: depth over breadth, one platform per phase, every learning session should produce a public artifact
- Session structure: goal → work → document → commit
- What counts as a public artifact: a writeup in security-research/techniques/, a commit to a repo, a documented finding
- How to document a completed challenge or module (mirrors the re-1/re-2 format)
- The sequenced learning track: C foundation → OST2 assembly/GDB → Nightmare → pwn.college → container boundary research → kernel research
- Platform-specific notes:
  - pwn.college: track dojo progress, document each module with a technique note
  - iximiuz: connect every lab to a container boundary research question
  - OST2: follow the Vulnerability Hunting & Exploitation learning path sequentially
  - protohackers: each challenge produces Go code committed to a private repo
- When to move on: a topic is done when you can explain the mechanism, reproduce it, and have a written artifact — not when you've completed the exercises

---

### Skill 5 — CR1MS0N Brand & Communication Standard

**Purpose:** All public-facing content (GitHub READMEs, research writeups, LinkedIn posts, conference abstracts, personal site copy) should follow a consistent voice and positioning.

Produce a skill file that defines:
- Brand positioning: Red Team Infrastructure Engineer + Vulnerability Researcher. Building CR1MS0N. Quality over ease.
- Voice: direct, technically precise, no filler, no hype. Write like a practitioner for practitioners.
- What CR1MS0N is and is not: it is a professional offensive security research brand, not a generic "cybersecurity" brand
- GitHub README standard: executive summary first, then architecture/state, then usage, then honest status (no "coming soon" placeholders)
- What to never write publicly: inflated claims about tool maturity, CTF rankings as primary credential, vague "passionate about security" language
- Research publication framing: infrastructure as the differentiator (live C2, real honeypot data, WireGuard mesh) — not "I completed X challenges"
- Conference abstract formula: research question + why it matters + what you found/built + what practitioners can take away
- LinkedIn/social principle: post about what you built or found, not about what you're learning or planning

---

## Output Format for Each Skill File

Each skill file should be saved as:
- `azrael-skill-01-research-writeup.md`
- `azrael-skill-02-infrastructure-ops.md`
- `azrael-skill-03-job-filter.md`
- `azrael-skill-04-learning-sessions.md`
- `azrael-skill-05-brand-communication.md`

Header format for each file:
```
# CR1MS0N Skill — [Name]
**Version:** 1.0
**Date:** 2026-03-19
**Purpose:** [one sentence]
**Use when:** [trigger conditions — when should Claude load this]
```

## Rules for This Conversation

- Produce one complete skill file at a time
- Each file should be immediately uploadable to the Claude project — no placeholders, no "TBD" sections
- Write the files as instructions Claude follows, not documentation for Darrius to read
- Be specific: generic advice ("write clearly") is useless; concrete rules ("always include a metadata block with challenge name, platform, difficulty, tools used, date, time spent") are useful
- After all five files are produced, suggest 2-3 additional skill files that would add value based on patterns you've observed in this work — don't produce them without confirmation
