# SPEC — {{project-name}}

## Project Name
{{project-name}}

## Description
{{one-to-three sentence description of what is being built and why}}

## Definition of Done
{{single sentence — what state must exist for this project to be considered finished}}

## Acceptance Criteria

1. {{criterion — specific, verifiable, not vague}}
2. {{criterion}}
3. {{criterion}}
<!-- Add more as needed. Each criterion must be independently verifiable. -->

## Out of Scope

- {{explicit exclusion — name the thing, not a category}}
- {{explicit exclusion}}
- {{explicit exclusion}}
<!-- Scope creep prevention. Be specific. "Performance optimization" is vague. "Redis caching layer" is not. -->

## Verification Test Cases

These are machine-readable self-checks. A subagent executing a task MUST evaluate
applicable cases and report PASS or FAIL with evidence.

```
VERIFY-001
  description: {{what is being verified}}
  command: {{shell command or manual inspection step}}
  expected: {{exact output or condition that constitutes PASS}}
  scope: [{{acceptance-criteria-numbers this covers}}]

VERIFY-002
  description: {{what is being verified}}
  command: {{shell command or manual inspection step}}
  expected: {{exact output or condition that constitutes PASS}}
  scope: [{{acceptance-criteria-numbers this covers}}]
```
<!-- Add one VERIFY block per distinct testable behavior.
     command may be a shell one-liner, a file existence check, or an HTTP call.
     expected must be unambiguous — no "should work" or "looks correct". -->
