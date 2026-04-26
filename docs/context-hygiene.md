# Context Hygiene

How to keep CC context clean when orchestrating across repos. Polyforge
ships the **mechanism** to isolate sessions (per-repo spawning, worktree
isolation); this doc covers **why** and **how** to use it.

## The cascade problem

CC auto-discovers `CLAUDE.md`, `AGENTS.md`, and every `.claude/rules/*.md`
in any repo it reads from. When a parent session reads a sibling repo's
file — even a single README via the `Read` tool — that sibling's full
rule set silently loads into the parent's context.

The fire path is **the `Read` tool**, not shell commands. `gh` and `git`
operations leave context untouched; opening a file with `Read` triggers
the cascade.

### Observed example (2026-04-26)

In the qte77 orchestrator session, a single `Read` of
`/workspaces/polyforge-orchestrator/config/contributions.json` was
enough to load polyforge's `CLAUDE.md` plus three `.claude/rules/*.md`
files into the parent's context. Pure verification of one config file's
existence pulled in ~140 lines of rule prose. The pollution was harmless
in that case (rules matched the parent's), but the mechanism is real
and load-bearing — exactly the failure mode this doc addresses.

## Rules of thumb

- **Plumbing** (PRs, merges, status checks) — CLI-only. Use `gh` and
  `git`. Never `Read` a sibling repo's files.
- **Content editing** — dedicated session per target, OR subagent
  delegation. Don't mix targets in one session unless you've explicitly
  taken steps below.
- **Never sacrifice rule enforcement for clean context.** If you need
  both, use separate sessions or subagent-in-nested-worktree. Don't
  reach for `--bare --add-dir` on mission-critical edits.

## Mitigation ladder — `--bare` is a dial, not a switch

`--bare` kills CLAUDE.md auto-discovery entirely. That's sometimes
right, often wrong — you usually *want* a target repo's rules loaded
(permissions, skills, hooks). Choose the rung that matches your
scenario:

| Scenario | Recommendation |
|---|---|
| **Single-repo work** | Open session inside the repo. Default cascade. Full context. |
| **Multi-repo plumbing** (PRs, merges, metadata) | `--bare` + `gh`/`git` only. No `Read`. |
| **Multi-repo targeted edits** (rules-light) | `--bare --add-dir /workspaces/A --add-dir /workspaces/B` — scope filesystem without auto-loading the whole tree. |
| **Multi-repo edits requiring rule enforcement** | Separate sessions per target repo (one per repo, parallel via `cc-parallel.sh`). The cleanest path when rules matter. |
| **One-off peek into a sibling** | Spawn a subagent — child's cascade stays in *its* context, not yours. |

`--bare` is a floor, not a default. Combine with `--add-dir` when you
*do* want selective filesystem reach. For mission-critical edits where
both clean context and rule enforcement matter, prefer separate
sessions or the nested-worktree subagent pattern documented in
[`subagent-dispatch.md`](subagent-dispatch.md).

### CLI flags that affect context

| Flag | Helps with cascade? | Use case |
|---|---|---|
| `--bare` | ✅ Direct kill switch | Batch/CI, multi-repo orchestration |
| `--add-dir` | Partial (expands reach, doesn't stop auto-load) | Combine with `--bare` |
| `--agents` / `--agent` | Indirect (delegate to tight subagents) | Pre-wired read-only reporters |
| `--allowedTools` | Indirect (restrict `Read`, force `gh`/`git`) | Enforce CLI-only rule |
| `--append-system-prompt` | Weak (fires too late) | Reinforce only |

## Recipes

### Interactive multi-repo orchestration

Work from a parent that owns no child contents (e.g. `.github/` repo).
Add only the targets you intend to touch:

```bash
claude --bare \
  --add-dir /workspaces/.github \
  --add-dir /workspaces/<target>
```

### Batch operations

Use `cc-parallel.sh --bare` (the pass-through described below). Each
spawned `claude` runs without auto-loaded rules, suitable for plumbing
work like cross-repo PR triage.

### One-off peek

Spawn a `general-purpose` subagent with a narrow prompt asking it to
read or summarize a single sibling. The child's cascade stays in the
subagent's context — your parent stays clean.

## `cc-parallel.sh --bare` pass-through

`scripts/cc-parallel.sh` accepts an opt-in `--bare` flag that forwards
to every spawned `claude -p` invocation. Default behavior is unchanged
(presets like `validate` and `security` legitimately want each repo's
rules loaded). Use `--bare` for plumbing presets where you want clean
context across the fan-out.

```bash
./scripts/cc-parallel.sh --bare --preset contribute --mode triage
```

## See also

- [`subagent-dispatch.md`](subagent-dispatch.md) — nested-worktree
  pattern for in-context dispatch
- [`codespaces.md`](codespaces.md) — devcontainer lifecycle and
  per-repo settings
- Original tracking issue: [polyforge#51](https://github.com/qte77/polyforge-orchestrator/issues/51)
