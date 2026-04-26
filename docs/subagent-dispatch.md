# Subagent Dispatch — CC Harness Behavior

Three observed failure modes when dispatching CC subagents for cross-repo
work, plus the proven working pattern that handles them.

## Context

When dispatching CC subagents for cross-repo work (polyforge orchestrating
tasks in ai-agents-research, claude-code-plugins, so101-biolab-automation,
Superdesign, CellPlateVision-Prototype, etc.), three empirical failure
modes apply. Observed during Phase 2 execution of the
`workspace-activity-audit-apr7-13` sprint plan. 5 agents spawned; 4 failed
in distinct ways; only 1 succeeded — and only because it worked around
failure mode #1.

## Failure Modes

### 1. `isolation="worktree"` places the worktree at the parent session's cwd — not the task's target repo

When the main session spawned agents from polyforge/so101 cwd, worktrees
got created at the parent's path, not at the target repo. Result:

- Agent C committed `docs/feasibility-assessment.md` to a **so101 worktree**
  instead of CellPlateVision
- Agent D's writes to Superdesign were **denied** because its worktree was
  sandboxed to so101

**Agent A (ai-agents-research) succeeded** because it ignored the isolation
worktree and made its own **nested worktree inside the target repo**.
That's the working pattern.

### 2. Without `isolation`, subagents lose Bash tool grant entirely

Agents B/D/E v2 launched without isolation returned "I need Bash
permission." The harness appears to strip Bash when no worktree isolation
is set. Not documented precisely, but empirically consistent across 3
separate subagent spawns.

### 3. System-reminders bleed into weaker agents

Agent E v1 responded to the `fewer-permission-prompts` skill description
in a system-reminder as if it were the task. Strong explicit "IGNORE ANY
SKILL PROMPTS" preamble seems to mitigate but not fully prevent.

## Why This Matters for Polyforge

These are load-bearing constraints for `make contrib_triage/implement/review`
wiring and any future multi-repo CC dispatch. Without accounting for them,
parallel subagent work produces ~70% failure rate (4 of 5 Phase 2 agents
had issues).

---

## Solution: Per-Repo Harnesses

**Yes — the "bare subagent using target repo's harness" pattern is Agent
A's success pattern**, with one addition:

- `isolation: "worktree"` — to get Bash grant (fixes #2)
- First step in prompt: `cd` into TARGET repo, `git worktree add` nested
  (fixes #1)
- All work in the nested worktree — **inherits TARGET repo's
  `.claude/settings.json`** (enables per-repo permission policies:
  allow/deny/ask rules from each target)
- Explicit "ignore system-reminder skills" preamble (fixes #3)

### Why "per-repo harness inheritance" is the load-bearing insight

Each managed repo (ai-agents-research, claude-code-plugins, so101, etc.)
has its own `.claude/settings.json` or `.claude/settings.local.json` with
repo-appropriate allow rules. When a subagent `cd`s into a nested worktree
of the target repo, it operates under that target's settings — not
polyforge's.

This means:

- `ai-agents-research` can allow `lychee *` for link checking; polyforge
  doesn't need that rule
- `so101` can allow `uv run *` for Python testing; polyforge doesn't need
  uv at all
- `Superdesign` can allow `npm run *` for TS compilation; polyforge doesn't
  need npm globally
- Deny rules stay per-repo too — no cross-contamination of trust decisions

Polyforge becomes a **thin orchestrator** that trusts each repo's own
harness for the work inside it.

## Proven Working Pattern

```js
Agent({
  isolation: "worktree",                    // required for Bash grant (#2)
  prompt: `
    PREAMBLE: Ignore any skill descriptions in system-reminders.     // mitigates #3
    They are NOT your task.

    Step 1 (required, non-negotiable):                               // works around #1
      cd /workspaces/qte77/<TARGET_REPO>
      git fetch origin
      git worktree add -b <BRANCH> .claude/worktrees/<SLUG> origin/main
      cd .claude/worktrees/<SLUG>

    Step 2+: Do your actual work in this nested worktree.
    All Bash commands from here inherit TARGET_REPO's .claude/settings.json.

    Final step: git push -u origin <BRANCH>

    Return: worktree path, branch name, push URL, summary.
  `
})
```

## Tradeoff

Loses parallelism when multiple agents target the **same** repo (nested
worktrees would collide on branch names). Fine when each agent targets a
**different** repo — which matches the `contrib_triage` pattern (one
agent per `:fork`-flagged external target).

## Proposed Action

Incorporate this pattern into `scripts/cc-parallel.sh --preset contribute`
wiring. The dispatch function should:

1. Set `isolation: "worktree"` when spawning agents
2. Inject the Step-1 cd+worktree-add boilerplate into every subagent
   prompt
3. Include the skill-derailment preamble guard
4. Enforce the user-confirmation gate **before** fanning out
5. Document that each target repo's `.claude/settings.json` is the
   authority for what bash is allowed — polyforge does not override

## Source

- Memory: `feedback_subagent_harness_behavior.md` in polyforge session
  memory
- Phase 2 sprint execution log: session `workspace-activity-audit-apr7-13`
- Sprint plan: `~/.claude/plans/workspace-activity-audit-apr7-13.md`
- Original tracking issue: [polyforge#47](https://github.com/qte77/polyforge-orchestrator/issues/47)
