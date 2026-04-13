# Contribution Sprint 1 — Full Plan

21 repos cloned at `/workspaces/external/`, all with upstream remotes. Verified 2026-04-13.

## Registry Submissions (5 repos, low effort)

| Registry | Stars | PR Title | Format | Section |
| -------- | ----- | -------- | ------ | ------- |
| VoltAgent/awesome-agent-skills | 14,420 | `Add skill: qte77/cc-utils-plugin` | `- **[qte77/cc-utils-plugin](url)** - desc` | Community Skills |
| BehiSecc/awesome-claude-skills | 8,411 | `Add claude-code-utils-plugin` | `- [cc-utils-plugin](url) - desc.` | Development & Code Tools |
| ComposioHQ/awesome-claude-plugins | 1,294 | `Add cc-utils-plugin plugin` | Table row or `- [name](url) - desc` | Developer Productivity |
| rohitg00/awesome-claude-code-toolkit | 1,228 | `Add cc-utils-plugin plugin` | Table row | All Plugins |
| jeremylongshore/claude-code-plugins-plus-skills | 1,856 | `Add claude-code-utils-plugin` | YAML in `sources.yaml` | External sync |

**Description**: 26 plugins, 45+ skills for TDD, compound learning, context management, multi-repo orchestration. Compatible with Claude Code.

**Dropped**: ccplugins/awesome-claude-code-plugins (0 merges ever), VoltAgent/awesome-claude-code-subagents (requires agent `.md` file, heavier effort).

## Contribution Targets (14 repos + 2 GHA)

### Quick Wins (parallel, all independent)

| Repo | Issue | Stack | Branch | Skills | Effort |
| ---- | ----- | ----- | ------ | ------ | ------ |
| claude-reflect | #25 pytest CI fix | Python | `contrib/25-ci-pytest-fix` | researching-codebase, python-dev | Trivial |
| SWE-bench | #472 eval output JSON docs | Python | `contrib/472-eval-output-docs` | researching-codebase, python-dev | Trivial |

**claude-reflect PR format**: `## Summary` + `## Changes` + `## Test plan`, conventional commit (`ci:`/`fix:`), `Generated with Claude Code` footer.

**SWE-bench PR format**: loose `## Summary`, `Fixes #NNN`, no strict template.

### Medium — Parallelizable Batch

| Repo | Issue | Stack | Branch | Skills | Effort |
| ---- | ----- | ----- | ------ | ------ | ------ |
| SimpleAgents | #23 complexity CI | Rust | `contrib/23-complexity-ci` | rust-dev, gha-dev, de-vibing | Low |
| SimpleAgents | #44 CC skills | Rust | `contrib/44-cc-skills` | rust-dev, researching-codebase | Medium |
| compass-mcp | Tests+CI+list_contexts | TypeScript | `contrib/tests-ci-list-contexts` | typescript-dev, tdd-core, gha-dev | Medium |
| epo-ops | #2 XML parsing | Go | `contrib/2-xml-parsing` | go-dev, tdd-core | Low |
| epo-ops | #1 proxy cache | Go | `contrib/1-version-bump` | go-dev | Low |
| bulk-file-loader | Test coverage | Go | `contrib/test-coverage` | go-dev, tdd-core | Low |
| uspto-odp | Test coverage | Go | `contrib/test-coverage` | go-dev, tdd-core | Low |
| dpma-connect-plus | Test coverage | Go | `contrib/test-coverage` | go-dev, tdd-core | Low |
| epo-bdds | Test coverage | Go | `contrib/test-coverage` | go-dev, tdd-core | Low |

### Medium-High — Require Full Attention

| Repo | Issue | Stack | Branch | Skills | Effort |
| ---- | ----- | ----- | ------ | ------ | ------ |
| openclaude | #448 status line 0% | TypeScript | `contrib/448-status-line` | typescript-dev, de-vibing | Low |
| openclaude | #433 Ollama raw JSON | TypeScript | `contrib/433-ollama-adapter` | typescript-dev, security-audit | Medium |
| openclaude | #664 Gemini regression | TypeScript | `contrib/664-gemini-regression` | typescript-dev | Medium |
| agent-flow | #35 SSE viz | TypeScript | `contrib/35-sse-viz` | typescript-dev, tdd-core | Medium |
| agent-flow | #4 Windows path | TypeScript | `contrib/4-windows-path` | typescript-dev, tdd-core | Low |
| claude-forge | #19 marketplace schema | Shell | `contrib/19-marketplace-schema` | gha-dev | Medium |
| claude-forge | #15 hook paths | Shell | `contrib/15-hook-paths` | tdd-core | Medium |
| multi-swe-bench | #89 data quality | Python | `contrib/89-data-quality` | python-dev | Medium |
| multi-swe-bench | #97 test infra | Python | `contrib/97-test-infra` | python-dev, tdd-core | Medium |
| SWE-bench_Pro-os | #85 stale test names | Python | `contrib/85-stale-test-names` | python-dev | Low |
| SWE-bench_Pro-os | #87 missing file | Python | `contrib/87-missing-file` | python-dev | Trivial |
| paths-filter | #266 any/all boolean | TypeScript | `contrib/266-any-all-boolean` | typescript-dev, tdd-core, security-audit | Medium |
| action-gh-release | #772 draft/publish bug | TypeScript | `contrib/772-draft-publish-bug` | typescript-dev, security-audit | Medium-High |

## Pre-Contribution Checklist (every repo)

1. `/codebase-tools:researching-codebase` — understand structure before touching code
2. Read CONTRIBUTING.md + PR template (if exists)
3. `/cc-meta:compacting-context` — after exploration, before coding
4. Branch on fork (never main)
5. Strict TDD where applicable
6. `/code-quality:de-vibing` — before committing (catches AI-generated smells)
7. Conventional commits + Co-Authored-By
8. PR to upstream following their conventions

## Merge Patterns

| Project | Template | Key Requirement |
| ------- | -------- | --------------- |
| claude-reflect | Summary+Changes+Test plan | Conventional commits, Generated with Claude Code |
| SWE-bench | Loose Summary, Fixes #NNN | Doc PRs merge fast, harness fixes accepted |
| openclaude | **Summary/Impact/Testing/Notes (enforced)** | `bun build` + `bun smoke`, state provider tested, small PRs only |
| SimpleAgents | Branch-name title, CodeRabbit | Update TODO.md, run tests |
| compass-mcp | None (we set norms) | Be the founding contributor |
| patent-dev | None (first external PR ever) | Tests + clear rationale |
| agent-flow | Has CONTRIBUTING.md | Follow their guidelines |
| claude-forge | Has CONTRIBUTING.md | Follow their guidelines |
| multi-swe-bench | Standard | Focused fixes |
| SWE-bench_Pro-os | Standard | Focused fixes |
| paths-filter | Standard | Well-scoped, one feature per PR |
| action-gh-release | Standard | Security-sensitive, thorough testing |

## Research Insights to Apply

### Per Target

| Target | Key Insight | Source |
| ------ | ----------- | ------ |
| claude-reflect | Use `additionalContext` in PreToolUse for reflection injection | agents-skills/CC-hooks-system-analysis |
| claude-reflect | Target auto memory layer (MEMORY.md), not CLAUDE.md | context-memory/CC-memory-system-analysis |
| SWE-bench | Structured output schemas in `-p` mode (v2.1.22) | ci-remote/CC-version-pinning-resilience |
| SWE-bench | `tmp_path` fixture isolation, `pytest --lf` for pollution | learnings/per-repo/agents-eval |
| openclaude | OTel has no trace spans — parse raw_stream.jsonl | learnings/cross-repo-digest |
| openclaude | Worktree+team_name bug documented (issues #38949, #33045) | agents-skills/CC-agent-teams-orchestration |
| SimpleAgents | CLAUDECODE=1 must be cleared for recursive spawning | agents-skills/CC-ralph-enhancement-research |
| SimpleAgents | 50K token subprocess tax — use --no-plugins in CI | agents-skills/CC-ralph-enhancement-research |
| compass-mcp | Teams artifacts ephemeral — parse JSONL not filesystem | learnings/cross-repo-digest |
| patent-dev | `gh pr edit` broken → use GraphQL mutations | learnings/cross-repo-digest |
| patent-dev | Pipe-into-while subshell bug (ShellCheck SC2031) | learnings/cross-repo-digest |
| agent-flow | raw_stream.jsonl event types are the parsing basis | agents-skills/CC-agent-teams-orchestration |
| claude-forge | Minimal plugin manifest avoids double-fire hook bug | plugins-ecosystem/CC-plugin-packaging-research |
| paths-filter | CodeQL `actions` language for shell+GHA repos | learnings/cross-repo-digest |
| action-gh-release | PAT scrubbing: `_main()` + `sed` pipe pattern | learnings/cross-repo-digest |

## Parallelization

```text
Batch A (all independent, start simultaneously):
├── claude-reflect #25
├── SWE-bench #472
├── Registry: 5 README/YAML edits
├── patent-dev: 5 Go repos test coverage
└── SWE-bench_Pro-os #87 (trivial)

Batch B (after Batch A learnings):
├── SimpleAgents #23
├── compass-mcp tests+CI
├── epo-ops #2 XML parsing
├── agent-flow #4 Windows path
└── SWE-bench_Pro-os #85

Batch C (require full attention, sequential):
├── openclaude #448, #433, #664 (strict review, one at a time)
├── SimpleAgents #44 (after #23 triage)
├── paths-filter #266
└── action-gh-release #772 (security-sensitive)

Batch D (medium-high, parallel where independent):
├── agent-flow #35 SSE viz
├── claude-forge #19, #15
└── multi-swe-bench #89, #97
```

## Workflow

All contributions follow fork-first:

1. Branch on our fork (never push to main, even if upstream does)
2. Strict TDD (Red-Green-Refactor)
3. Conventional commits with Co-Authored-By
4. PR to upstream following their template/conventions
5. Delete fork after merge (attribution survives)
