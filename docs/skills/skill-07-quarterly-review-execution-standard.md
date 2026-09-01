---
name: quarterly-review-execution-standard
description: Use when the operator initiates a quarterly review or the quarterly review calendar event fires. Governs the ten-question sequence, gap table update, upcoming quarter milestone map, calendar generation, and the Q4 hard rebuild protocol.
---

# CR1MS0N Skill — Quarterly Review Execution Standard
**Version:** 1.1
**Date:** 2026-04-01
**Purpose:** Define exactly how Claude executes the quarterly review so it produces a recalibrated plan, updated gap table, and rebuilt calendar — not just a summary of what happened.
**Use when:** the operator initiates a quarterly review, references the Phase 4 template, or the quarterly review calendar event fires.

---

## When to Run

Quarterly reviews run the first week of each new quarter:

| Review | Quarter | Window | Calendar Event |
|---|---|---|---|
| Q1 Review | January – March | First week of April | April 1, 2026 |
| Q2 Review | April – June | First week of July | July 1, 2026 |
| Q3 Review | July – September | First week of October | October 1, 2026 |
| Q4 Hard Rebuild | October – December | First week of January | January 1, 2027 |

The Q4 review is a hard rebuild — the entire 12-month plan gets rewritten from scratch based on actual state, not patched. Every other quarterly review recalibrates the upcoming quarter only.

---

## Pre-Review Checklist

Before asking the ten questions, Claude runs this check silently:

- Is the handoff document current? If the last session log is more than two weeks old, flag it: "The handoff hasn't been updated since [date] — any state changes to capture before we run the review?"
- Is the container boundary research deliverable committed to `security-research/`? If not, surface it: "The Q[N] project deliverable hasn't been committed — is it complete or still in progress?"
- Are there any unresolved items from Section 5 (Next Session) of the handoff that should be addressed before the review resets priorities?

If any of these surface a gap, address it before starting the ten questions — not after.

---

## The Ten Questions

Ask all ten before generating any output. Do not interpret or respond to individual answers as they come in — collect all ten, then process together. Partial answers produce partial recalibration.

**Section 1 — Progress Assessment**

1. Which milestones from last quarter did you fully complete, partially complete, or miss entirely? For any miss, one sentence on the actual constraint — not justification, just the specific thing that blocked it.

2. For each active track last quarter, what was your actual average sessions per week versus the target? Be specific — "roughly kept up" is not an answer.

3. Did you produce and publish the planned project deliverable? If yes, link it. If no, what is the current state and what specifically remains before it can be committed?

**Section 2 — State Change Assessment**

4. What is your current professional experience state? Contract active, hours per week, nature of the work, and whether it's generating signal toward the north star or keeping the clock running.

5. What is one thing you can do now that you couldn't do at the start of last quarter — demonstrated by doing it, not by having learned about it? If the answer is weak or vague, that is the most important data point from the review.

**Section 3 — Gap Recalibration**

6. Pull up the Phase 1 gap table. Which two gaps moved the most last quarter and which one gap didn't move at all? What drove the movement and what drove the stall?

7. Did any new gap surface — from an interview, from a piece of work you couldn't complete, from something you tried to build and couldn't? New gaps get added to the table immediately.

**Section 4 — Next Quarter Targeting**

8. Given actual state, what is the single most important gap to close next quarter? Not the most interesting — the most important given where the job search and research track actually are.

9. What is the one project deliverable for next quarter? Concrete, verifiable, and public. State it in one sentence with a specific output. If it can't be stated that way, it isn't scoped tightly enough yet.

10. What is the job tier you're actively targeting this quarter, and what is the one thing that would make you more competitive for it by end of quarter than you are today?

---

## How Claude Processes the Answers

Once all ten answers are received, Claude runs this sequence in order. Do not skip steps.

**Step 1 — Milestone assessment**
Map answers 1–3 against last quarter's plan. State explicitly: which milestones are complete, which are partial, which are missed. One sentence per milestone — no padding. If the deliverable isn't published, it is incomplete regardless of how much work went into it.

**Step 2 — Capability check**
Answer 5 is the most important signal in the review. If the operator can point to something concrete and demonstrable — wrote a port scanner from scratch, reproduced a Kerberoasting attack end-to-end on Tairn, captured and explained a TCP handshake at the packet level — the quarter produced retained capability. If the answer is vague, state it directly: "The quarter produced effort but the capability demonstration is unclear — this becomes the primary focus of next quarter."

**Step 3 — Update the gap table**
Using answers 6 and 7, update the Phase 1 gap table with current honest assessments. Format:

| Gap | Previous Level | Current Level | What Changed | What's Next |
|---|---|---|---|---|
| Binary exploitation | None → Awareness | Awareness → Early hands-on | Completed pwn.college fundamentals intro, two writeups committed | Continue pwn.college intermediate track |

Add any new gaps from answer 7 as new rows. Never remove a gap from the table — mark it closed only when the exit condition is demonstrably met.

**Step 4 — Recalibrate the upcoming quarter**
Using answers 8–10, write the upcoming quarter's milestone map. Format matches the Phase 2 structure:

- Primary gap being closed
- Learning track (foreground, sequential or simultaneous based on what the gaps require)
- Background track
- Project deliverable (one sentence, specific output, verifiable)
- Job tier being actively targeted
- Monthly checkpoints (three months, specific targets per month)

If the answer to question 5 was weak, the upcoming quarter's primary focus is the capability demonstration gap — regardless of what the original plan said was next.

**Step 5 — Flag trajectory changes**
Compare actual Q[N] state against where the original 12-month plan expected the operator to be. State the delta honestly:

- Ahead: name what accelerated and whether the Q4 targets can be pulled forward
- On track: confirm the original trajectory holds
- Behind: name the specific slippage, identify whether it's recoverable within the 12-month window or requires the hard rebuild now rather than waiting for Q4

Do not soften trajectory assessments. A quarter that produced less than planned is information, not failure — but it needs to be stated accurately to produce a useful recalibration.

**Step 6 — Generate calendar updates**
Based on the recalibrated upcoming quarter, generate the new daily and weekly calendar events for the CR1MS0N Google Calendar. Format matches the Q1 structure:

- Recurring weekly blocks for the new track structure
- Specific daily task events for the first month of the new quarter
- End-of-quarter review event with updated Phase 4 template in the description

Ask before creating: "Ready to update the calendar for Q[N+1]?" Do not create events without confirmation.

---

## Q4 Hard Rebuild Protocol

The Q4 review is different from the other three. It does not patch the existing plan — it rebuilds from scratch.

When Q4 review fires (March 1, 2027), run the ten questions as normal, then:

1. Pull the original Phase 1 gap table from March 2026 and the current updated version. State what closed, what moved, what didn't move in 12 months.
2. Rebuild the north star assessment — is runZero still the destination, or has professional experience revealed a more specific or different target?
3. Rebuild the tier structure — based on actual roles landed, interviews completed, and professional experience gained, what tier is realistic to compete for in the next 12 months?
4. Write a full new 12-month plan from current state. Do not reference the old plan as the baseline — use actual state as the baseline.
5. Update the handoff document Section 1 (Who the Operator Is) if the north star, philosophy, or target roles have materially changed based on a year of experience.

The hard rebuild is the most important review of the four. It's where the plan stops being a projection made in March 2026 and becomes a plan grounded in 12 months of actual data.

---

## What Claude Never Does During a Quarterly Review

- Answers the ten questions before all ten are received
- Softens a missed milestone into "partially achieved" without the operator explicitly framing it that way
- Skips the capability check (answer 5) — this is the most important question and cannot be glossed over
- Generates calendar events without confirmation
- Treats the Q4 review as a standard quarterly recalibration — it is always a full rebuild
- Closes the review without updating the handoff document

---

## Output at Review Close

When the review is complete, produce in this order:

1. Updated gap table (full table, not just the changed rows)
2. Upcoming quarter milestone map with monthly checkpoints
3. Confirmation of calendar update readiness
4. Updated handoff sections (Section 3, Section 5, Section 7 minimum — Section 1 if Q4 rebuild)
5. Commit command for the updated handoff
