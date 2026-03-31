---
name: azrael-project
description: >
  Lightweight project execution skill for personal/side project builds in Claude Code.
  Trigger phrases: "azrael-project init", "azrael-project execute", "azrael-project complete",
  "/project init", "/project execute", "/project complete".
  Not for Veil infra or security research work.
context: fork
tools:
  - Read
  - Write
  - Bash
  - Grep
model: claude-sonnet-4-5
---

# azrael-project Skill

Lightweight execution loop for personal/side project builds. Three commands: `init`, `execute`, `complete`.
Not for Veil infra, security research, or anything in `~/Github/veil/` or `~/Github/security-research/`.

---

## Command: init

**Invocation:** `azrael-project init <project description>`

**Behavior:**

1. Parse `<project description>` from the argument.
2. Ask the following clarifying questions before proceeding — wait for answers:
   - What is the primary deliverable? (binary, library, web app, script, etc.)
   - What is explicitly out of scope for this build?
   - What does "done" look like — what can you verify by running or inspecting?
   - Any hard constraints? (language, dependencies, runtime, file layout)
3. Using answers, populate `templates/SPEC.md` into `.planning/SPEC.md` in the project root.
4. Populate `templates/STATE.md` into `.planning/STATE.md` with empty task history.
5. Create the `.planning/` directory if it does not exist.
6. Stage `.planning/SPEC.md` and `.planning/STATE.md`.
7. Commit: `chore: init azrael-project scaffold`

**Rules:**
- Do not begin implementation during init.
- SPEC.md must include at least 3 numbered acceptance criteria and at least 2 verification test cases.
- STATE.md status field must be `active` at init.

---

## Command: execute

**Invocation:** `azrael-project execute <inline task-spec>`

The `<inline task-spec>` argument IS the complete task specification. No separate file.

**Behavior:**

1. Read `.planning/SPEC.md` as `<project_context>`.
2. Derive a `<task-slug>` from the task-spec (kebab-case, ≤40 chars).
3. Fork a subagent via `context: fork`. Inject the following into the subagent prompt:

```
<project_context>
{{contents of .planning/SPEC.md}}
</project_context>

Task: {{inline task-spec}}

Implement the task atomically. On completion, commit with message:
  feat(<task-slug>)-attempt-1: <one-line description>

Do not touch scope listed under "Out of Scope" in SPEC.md.
After implementation, self-check: does the output satisfy the task-spec
AND align with the Verification Test Cases in SPEC.md?
Report: PASS or FAIL with specific evidence.
```

4. Receive subagent result.
5. **Collect telemetry before verify:**
   - Run `git diff --no-ext-diff` from project root — capture all file changes (lines added/removed/modified)
   - Detect test harness: check for `package.json` (npm/yarn test), `pytest.ini`/`conftest.py` (pytest), 
     `Makefile` (make test), `go.mod` (go test ./...), `Cargo.toml` (cargo test)
   - Execute tests if found; skip gracefully if no harness detected
   - Capture full test stdout and stderr
6. **Verify with hard telemetry signals:**
   - Does the output satisfy the task-spec? (reference task-spec text)
   - Does it stay within SPEC.md scope? (reference Out of Scope section)
   - Do SPEC.md Verification Test Cases that overlap this task pass? (reference test case blocks)
   - Are tests passing? (reference git diff and test output — non-negotiable signal)
   - Report: PASS or FAIL with specific evidence tying to git diff and test telemetry
7. **Ratchet loop — on FAIL (attempt counter):**
   - **Attempts 1-3:** Generate fix task from failure signal (git diff + test output + SPEC.md misalignment). 
     Re-invoke subagent with enhanced prompt containing `<failure_signals>` block:
     ```
     <failure_signals>
     Original task-spec: {{task-spec}}
     Attempt N failure: {{prior failure report}}
     git diff: {{output of git diff --no-ext-diff}}
     test output: {{captured test stdout/stderr, or "no tests found"}}
     Verify report: {{specific evidence of what failed}}
     </failure_signals>
     ```
     Subagent attempts fix and re-submits. Commit each attempt:
     `feat(<task-slug>)-attempt-{{N}}: <description of fix approach>`
   - **Attempt 4 (synthesis pass):** Subagent reads ALL 3 prior failure signals together + original task + SPEC.md.
     Identifies the pattern in what isn't working (not superficial fixes, but fundamental architectural or 
     design mismatch). Produces a fundamentally different implementation approach. Commit:
     `feat(<task-slug>)-synthesis: <description of rethought approach>`
8. **On PASS at any attempt:**
   - Append to `.planning/STATE.md` Completed Tasks:
     ```
     - [x] {{task-slug}}: {{task-spec}} — verify: PASS at attempt {{N}}
     ```
   - Update `Last Updated` and `Current Branch`.
9. **On FAIL after all 4 attempts:**
   - Append to `.planning/STATE.md` Active Blockers:
     ```
     {{task-slug}}: All 4 attempts exhausted.
     - Attempt 1-3: [list approaches tried]
     - Attempt 4 (synthesis): [description of rethought approach]
     - Persistent signal: [what failed across all attempts — architectural mismatch, missing dependency, scope conflict, etc.]
     - Evidence: [git diff showing attempted changes, test failures, SPEC.md misalignment]
     ```
   - Do NOT populate "Next Task" — surface full failure report to operator with all telemetry.
   - Do NOT auto-retry further.

**Rules:**
- One task-spec per execute invocation — do not batch.
- Never modify `.planning/SPEC.md` during execute.
- Subagent commits use `feat(<task-slug>)-attempt-N:` or `feat(<task-slug>)-synthesis:` prefix.
- Ratchet loop runs up to 4 attempts atomically (verify after each, commit each attempt).
- Telemetry (git diff, test output) is hard signal — mandatory in verify reasoning, not optional.
- Synthesis pass (attempt 4) is architectural rethink, not another incremental fix.

---

## Command: complete

**Invocation:** `azrael-project complete`

**Behavior:**

1. Read `.planning/SPEC.md` acceptance criteria.
2. Read full project codebase relevant to those criteria.
3. **Final verify:** Does the full codebase satisfy every numbered acceptance criterion in SPEC.md?
   - For each criterion: PASS or FAIL with file:line evidence.
   - If any criterion FAILs: surface to user, do not proceed. Write failures to STATE.md Active Blockers.
4. **On all PASS:**
   a. Read project name from SPEC.md.
   b. Call `scripts/vault-log.sh` with collected project metadata.
   c. Update `.planning/STATE.md` status to `complete`.
   d. Stage all changes.
   e. Commit: `chore: project complete <project-name>`
   f. Tag: `git tag v1.0.0`
5. Report tag and vault note path to user.

**Rules:**
- Do not tag if any acceptance criterion fails.
- Do not call vault-log.sh before the final verify passes.
- Never force-push or push directly to main — user approves push separately.
