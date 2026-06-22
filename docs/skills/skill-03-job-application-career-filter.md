---
name: job-application-career-filter
description: Use when Darrius asks Claude to evaluate a job posting, help draft application materials, review a resume or cover letter, or think through career positioning relative to the Azrael Security trajectory.
---

# Azrael Security Skill — Job Application & Career Filter
**Version:** 1.1
**Date:** 2026-03-19
**Purpose:** Define a consistent filter and output standard for evaluating job postings and producing application materials aligned with the Azrael Security career trajectory.
**Use when:** Darrius asks Claude to evaluate a job posting, help draft application materials, review a resume or cover letter, or think through career positioning.

---

## North Star Role

**Vulnerability Researcher** at a company with these characteristics:
- Founded or led by practitioners, not pure business executives
- Culture of creative, unconventional thinking — willing to challenge how the industry frames problems
- Research-oriented, not compliance-oriented
- Small to mid-size — boutique firm or focused product company where individual contribution is visible
- Reference company: runZero. The north star is not the tech stack — it is the culture ("dreamers and creative thinkers who aren't afraid to shake up the status quo") and the nature of the work (vulnerability research, exposure management, building tools that matter). This is the destination. Every decision should move toward this tier.

If a role does not directionally point toward this target, it needs a clear reason to pursue it (pays bills, builds a specific missing skill, opens a specific door).

---

## Application Rule

Before spending time on any application, check both:

1. **Experience filter:** Does the posting require 3 years or fewer? If it requires 4+, skip unless there is an explicit exception reason.
2. **Alignment filter:** Does the role build toward vulnerability research, red team infrastructure, or offensive security engineering? If it builds toward compliance, GRC, or generic IT security, skip.

Both must pass. One out of two is a skip.

---

## The 60-Second Filter

Ask these questions of any job posting in order. Stop and decide at the first hard no.

1. **Experience gate:** Sub-3-years requirement? → Yes: continue. No: skip.
2. **Domain gate:** Offensive security, vulnerability research, red team, or security engineering? → Yes: continue. No: skip.
3. **Tier check:** Which tier does this map to? (See tier definitions below.)
4. **Skill gap check:** Does this role require something missing from the current stack? If yes, is that gap closeable in the time before interview, or is it a disqualifier?
5. **Portfolio fit:** Can Veil, the RE writeups, or the container boundary research be cited as directly relevant? If nothing in the portfolio maps to the role's core requirements, the application will be weak regardless of resume quality.

If it passes all five, decide tier and act accordingly.

---

## Tier Definitions

**Tier 1 — Apply Now**
Contract or entry roles that pay and build experience. Low bar, fast cycle, learn the environment.
- Examples: Alignerr Offensive Security Analyst ($40-60/hr contract), junior SOC with offensive component, security analyst contract roles
- Action: Apply within the week. These do not require a tailored cover letter — a direct, factual note and resume is enough.
- Mindset: These pay the clock while building toward Tier 3. Not the destination.

**Tier 2 — 3-6 Month Horizon**
Junior pentest, associate security analyst, security engineer at a company with an offensive practice.
- Examples: Junior penetration tester at a boutique firm, associate red team analyst, security engineer with CVE research component
- Action: Apply when the portfolio has one complete public research artifact (container boundary writeup or equivalent). Resume needs to lead with Veil and research, not certifications.
- Mindset: These are bridge roles. Acceptable if they build craft, not just resume lines.

**Tier 3 — 12+ Month Horizon**
Vulnerability researcher, red team engineer, security researcher at product companies.
- Examples: Vulnerability Researcher at runZero, Red Team Engineer at Red Siege, Security Researcher at Scythe
- Action: Apply when container boundary research is public, HackSpaceCon talk is delivered or submitted, and at least one Tier 2 role or equivalent experience is in place.
- Mindset: This is the destination tier. Do not apply prematurely — a weak application to runZero costs more than waiting six months.

---

## Company Watchlist

| Company | Why It Matters | When to Apply |
|---|---|---|
| **runZero** | North star. HD Moore founded. Practitioner-led, research-driven culture that values unconventional thinking. The work — vulnerability research, exposure management, building tools that change how the industry operates — is the draw, not the stack. | Tier 3. Not before container research is public and a talk is delivered. |
| **Red Siege** | Tim Medin's boutique. Quality-over-volume culture. Craft-building environment. Aligns with Azrael Security philosophy more than any corporate team. | Tier 2-3 boundary. Apply when portfolio has depth, not just certs. |
| **Sprocket Security** | Continuous automated pentesting. Offensive automation intersection. Good signal for offensive engineering roles. | Tier 2. Apply when Veil automation work is demonstrable. |
| **Scythe** | Jorge Orchilles. Adversary emulation platform. MITRE ATT&CK deeply integrated. Mythic C2 experience is directly relevant. | Tier 2-3. Apply when Mythic operational experience is documented. |
| **Nvidia** | Serious internal offensive team doing firmware and GPU driver vulnerability research. Linux-kernel adjacent. Long-term target. | Tier 3. Not before kernel research track has public output. |

*Watchlist has an open slot. Add companies as conviction is established — not before.*

---

## Resume Framing Principles

Lead order matters. Structure the resume in this order:

1. **Infrastructure first:** Veil — three-node WireGuard mesh, Mythic C2 on NixOS, Podman rootless Quadlets, Cowrie honeypot, Suricata IDS, NightForge Shield. This is the differentiator. It demonstrates operational maturity that CTF players do not have.
2. **Research second:** RE writeups (re-1, re-2), container boundary research (when public), MITRE ATT&CK technique documentation from course work.
3. **Certifications third:** AD-RTS, CAPT, COSJ, CRTA (when complete), CRT-ID (when complete). Certs are supporting evidence, not the headline.
4. **Tools last:** Tool lists with no context are noise. Every tool mentioned should be tied to a specific use in Veil or research.

What never leads a resume:
- A skills matrix as the first section
- "Passionate about cybersecurity" or equivalent
- CTF rankings or platform scores as the primary credential
- An objective statement

---

## Cover Letter / Application Note Standard

For Tier 1: No cover letter required. A two-paragraph direct note is enough.
- Paragraph 1: What you built (one sentence on Veil, one on research direction).
- Paragraph 2: Why this role specifically, tied to a concrete requirement in the posting.

For Tier 2 and 3: A focused cover letter, not a form letter.
- Open with the most relevant technical artifact. Not "I am excited to apply." Open with what you built or found.
- Reference a specific aspect of the company's work — not their mission statement, their actual technical work or published research.
- For runZero specifically: the culture alignment is as important as the technical fit. The cover letter should reflect that Azrael Security is built on the same philosophy — practitioner-led, unconventional, building things that matter.
- Close with a concrete ask: a conversation, not "I look forward to hearing from you."
- Maximum one page. If it runs long, cut — do not compress font or margins.

What never appears in an application:
- "I am passionate about..."
- "I am a fast learner"
- Generic objective statements
- CTF rankings as the primary credential without context
- Skills lists without demonstrated use

---

## When Claude Is Helping With an Application

1. Ask for the job posting text before producing anything.
2. Run the 60-second filter explicitly — state which questions pass and which fail.
3. Identify which portfolio artifacts map directly to the role's core requirements.
4. Flag any requirements that are genuine gaps — do not paper over them.
5. Produce resume bullets or cover letter copy only after the filter and mapping are done.
6. All produced copy should reference specific Veil components or research artifacts by name — no generic security language.
