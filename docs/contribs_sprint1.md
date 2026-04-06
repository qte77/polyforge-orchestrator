# Contribution Sprint 1 — Verified Targets

Verified 2026-04-06 by 3 independent agents. Zero discrepancies across all claims.

## Tier 1 — Fork + Add to Workflow

High alignment, active issues, high visibility. These join the existing 8 as primary contribution targets.

| # | Project | Stars | Issues | Category | Entry Point |
| - | ------- | ----- | ------ | -------- | ----------- |
| 1 | BayramAnnakov/claude-reflect | 881 | 7 | CC compound learning | Promotion hierarchy, multi-repo sync |
| 2 | disler/claude-code-hooks-multi-agent-observability | 1,342 | 26 | CC observability | Hook patterns for multi-repo agents |
| 3 | SWE-bench/SWE-bench | 4,626 | open | Agent evaluation | Test reliability (#545, #530) |
| 4 | tj-actions/changed-files | 2,684 | open | GHA OBSERVE | Deployment event support (#2631) |
| 5 | googleapis/release-please | 6,672 | open | GHA DISTRIBUTE | YAML/TOML config (#2710) |

## Existing Targets (8 repos, cloned)

| # | Project | Stack | Key Issues | Score |
| - | ------- | ----- | ---------- | ----- |
| 1 | CraftsMan-Labs/SimpleAgents | Rust | #23 (complexity CI), #42 (approval), #44 (CC skills) | 4/5 |
| 2 | richlira/compass-mcp | TypeScript | Tests+CI, list_contexts, agent identity | 4/5 |
| 3 | Gitlawb/openclaude | TypeScript | #448 (status 0%), #433 (Ollama), #430 (validation) | 5/5 |
| 4 | patent-dev/epo-ops | Go | #1 (proxy cache), #2 (XML parsing) | 4/5 |
| 5 | patent-dev/bulk-file-loader | Go | Test coverage, docs | 3/5 |
| 6 | patent-dev/uspto-odp | Go | Test coverage, docs | 3/5 |
| 7 | patent-dev/dpma-connect-plus | Go | Test coverage, docs | 3/5 |
| 8 | patent-dev/epo-bdds | Go | Test coverage, docs | 3/5 |

## New Targets — CC Plugins & Orchestration

| # | Project | Stars | Issues | CONTRIBUTING | Score | Entry Point |
| - | ------- | ----- | ------ | ------------ | ----- | ----------- |
| 9 | BayramAnnakov/claude-reflect | 881 | 7 | No | 5/5 | Compound learning promotion hierarchy, multi-repo sync |
| 10 | disler/claude-code-hooks-multi-agent-observability | 1,342 | 26 | No | 4/5 | Hook patterns for multi-repo agent coordination |
| 11 | patoles/agent-flow | 607 | 16 | Yes | 4/5 | Polyrepo topology visualization |
| 12 | sangrokjung/claude-forge | 641 | 21 | Yes | 4/5 | Port skills as forge plugins |

## New Targets — Agent Evaluation

| # | Project | Stars | Issues | Score | Entry Point |
| - | ------- | ----- | ------ | ----- | ----------- |
| 13 | SWE-bench/SWE-bench | 4,626 | #548, #545, #530 | 5/5 | Test reliability (#545, #530) |
| 14 | multi-swe-bench/multi-swe-bench | 330 | #98, #97, #94, #89, #84 | 4/5 | Data quality (#89, #84), test infra (#97) |
| 15 | scaleapi/SWE-bench_Pro-os | 335 | #89, #87, #85 | 4/5 | Stale test names (#85), missing file (#87) |

## New Targets — GHA Pipeline

| # | Project | Stars | Layer | Issues | Score | Entry Point |
| - | ------- | ----- | ----- | ------ | ----- | ----------- |
| 16 | tj-actions/changed-files | 2,684 | OBSERVE | #2835, #2631 | 5/5 | Deployment event support (#2631) |
| 17 | googleapis/release-please | 6,672 | DISTRIBUTE | #2710, #2714 | 5/5 | YAML/TOML config (#2710) |
| 18 | dorny/paths-filter | 3,051 | OBSERVE | #266, #261 | 4/5 | Any/all boolean (#266) |
| 19 | softprops/action-gh-release | 5,525 | DISTRIBUTE | #772, #770 | 4/5 | Draft/publish bug (#772) |

## Catalog Submissions (low effort, high visibility)

| # | Project | Stars | Action |
| - | ------- | ----- | ------ |
| 20 | VoltAgent/awesome-agent-skills | 14,420 | Submit tdd-core + compound-learning skills |
| 21 | jeremylongshore/claude-code-plugins-plus-skills | 1,856 | Package for CCPI marketplace |
| 22 | ccplugins/awesome-claude-code-plugins | 669 | List polyforge + cc-utils-plugin |

## Sprint 1 Priority

```text
WEEK 1 — Trust builders (parallel)
├── openclaude #448 (status line bug, small focused fix)
├── SimpleAgents: add PR template + #23 (complexity CI)
├── compass-mcp: vitest + CI + list_contexts
├── epo-ops #2 (XML parsing, proposed fix exists)
├── claude-reflect: compound learning promotion hierarchy [TIER 1]
├── hooks-observability: pick from 26 open issues [TIER 1]
└── Catalog: submit to VoltAgent + ccplugins (visibility)

WEEK 2 — High value
├── openclaude #433 (Ollama tool calling)
├── SWE-bench #545 (test reliability) [TIER 1]
├── multi-swe-bench #89 (data quality)
├── tj-actions/changed-files #2631 (deployment events) [TIER 1]
└── googleapis/release-please #2710 (yaml config) [TIER 1]

WEEK 3 — Strategic
├── SimpleAgents #44 (CC skills interop)
├── compass-mcp agent identity + multi-workspace
├── disler/hooks-observability (pick from 26 issues)
└── sangrokjung/claude-forge (port skills)
```

## Merge Patterns (how to get PRs accepted)

| Project | Template | Strategy | Key Requirement |
| ------- | -------- | -------- | --------------- |
| openclaude | Summary/Impact/Testing/Notes | Small focused fixes only | `bun run build` + `bun run smoke`, state provider tested |
| SimpleAgents | None (use CONTRIBUTING.md) | Branch-name title, CodeRabbit summaries | Update TODO.md, run tests |
| compass-mcp | None | Direct to main (we set the norms) | Be the founding contributor |
| patent-dev | None | Direct to main (first PR ever) | Tests + clear rationale |
| SWE-bench | Standard | Focused fixes | Harness test coverage |
| tj-actions | Standard | Feature PRs welcome | Well-scoped, one feature per PR |
| release-please | Standard | Google CLA required | Sign CLA first |

## Deferred TODOs

### BayramAnnakov/claude-reflect

- [x] #25 — pytest not found in CI (quick win, DOING NOW)
- [ ] Review + improve PR #26 — CLAUDE_PLUGIN_ROOT fallback (fixes #17)
- [ ] PR #27 — SessionEnd hook (stalled 3 weeks, revive + add tests)
- [ ] Multi-project reflection aggregation — reflect across repos not just one (strategic)

### SWE-bench/SWE-bench

- [x] #472 — clarify eval output JSON docs (quick win, DOING NOW)
- [ ] #474 — check_fail_only evaluates fatal errors as resolved (bug fix, no competing PR)
- [ ] #410 — clarify patch_is_None vs patch_exists (docs)
- [ ] #502 — missing django-7530 test case (dataset fix)
- [ ] #513 — matplotlib large UID files breaking podman (bug fix)

### disler/claude-code-hooks-multi-agent-observability

Demoted — 0 PRs ever merged, 15 stalled. Adopt patterns instead of contributing upstream.
See qte77/Agents-eval#104, #105, #106 for our approach (extract into cc-meta skill).

### tj-actions/changed-files

Demoted — solo maintainer ignores external PRs for months.

- [ ] #2839 — newline separator option (if maintainer becomes responsive)

### googleapis/release-please

Demoted — Google CLA + 20 stalled external PRs.

- [ ] #2696 — `||` vs `??` for header/footer (one-line fix, if CLA signed)

## Workflow

All contributions follow fork-first:

1. Branch on our fork (never push to main)
2. Strict TDD (Red-Green-Refactor)
3. Conventional commits
4. PR to upstream following their template/conventions
