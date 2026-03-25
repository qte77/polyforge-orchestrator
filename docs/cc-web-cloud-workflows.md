# CC Web Cloud Workflows

> Adapting polyforge's multi-repo parallel execution for Claude Code on the Web.

## Context

polyforge orchestrates local `claude -p` sessions across N repos via `cc-parallel.sh`. Claude Code on the Web (`claude.ai/code`) offers cloud-hosted, fire-and-forget execution with native GitHub integration. This document maps polyforge's local patterns to cloud equivalents and identifies gaps.

## Local vs Cloud Execution Model

| Aspect | Local (`claude -p`) | Cloud (`claude --remote`) |
|---|---|---|
| **Execution** | Local machine, blocking | Anthropic VM, fire-and-forget |
| **Keep-alive** | Requires terminal/tmux | Not needed — survives disconnect |
| **Output** | JSON to stdout | Git branch + PR on GitHub |
| **Parallel** | Background processes + `wait` | Independent cloud sessions |
| **Auth** | Local credentials | GitHub App (proxy-managed) |
| **Monitoring** | PID tracking, log files | `/tasks`, web UI, mobile app |
| **Budget control** | `--max-turns`, local cost tracking | Account rate limits only |
| **Multi-repo context** | `additionalDirectories` | Not supported (1 repo/session) |

## Mapping polyforge Scripts to Cloud

### cc-parallel.sh (core adaptation)

Replace `claude -p` with `claude --remote` for cloud execution:

```bash
#!/bin/bash
# cc-parallel-web.sh — Fire-and-forget cloud sessions across repos
source "$(dirname "$0")/repos.conf"

PROMPT="${1:?Usage: $0 <prompt>}"

for repo in "${REPOS[@]}"; do
  name=$(basename "$repo")
  # Derive GitHub org/repo from git remote
  github_repo=$(git -C "$repo" remote get-url origin | sed 's#.*github.com[:/]##;s#\.git$##')

  echo "Launching cloud session: ${name}"
  claude --remote "${PROMPT}" --repo "github.com/${github_repo}" &
done

echo ""
echo "All sessions launched. Monitor via:"
echo "  - /tasks (in Claude Code terminal)"
echo "  - claude.ai/code (web UI)"
echo "  - Claude mobile app"
```

**Key differences from local `cc-parallel.sh`**:

- No `--output-format json` — results are commits on GitHub branches
- No `wait $pid` + JSON collection — poll via `/tasks` or GitHub API
- No `--max-turns` / `--max-budget` — cloud sessions use account rate limits
- No `$OUTPUT_DIR` — results live as PRs on each repo

### cc-status.sh (works as-is)

The status dashboard uses `git` and `gh` CLI, which work regardless of whether tasks ran locally or in the cloud. Cloud sessions push branches, so `git fetch --all` + `gh pr list` captures results.

### cc-repos.sh (not needed for cloud)

tmux windows are unnecessary — cloud sessions don't require a terminal. Repurpose for monitoring:

```bash
# Monitor cloud sessions instead of launching tmux windows
for repo in "${REPOS[@]}"; do
  name=$(basename "$repo")
  github_repo=$(git -C "$repo" remote get-url origin | sed 's#.*github.com[:/]##;s#\.git$##')
  echo "=== ${name} ==="
  gh pr list --repo "${github_repo}" --label "claude-code" --limit 3
done
```

### cc-credential-setup.sh (not needed for cloud)

Cloud sessions authenticate via the Claude GitHub App — no local credential management required.

## GitHub Actions Alternative (Durable Scheduling)

For scheduled, unattended execution that survives everything:

```yaml
# .github/workflows/polyforge-validate.yml
name: Polyforge Validate All Repos
on:
  schedule:
    - cron: "0 9 * * 1-5"  # Weekdays at 9am
  workflow_dispatch: {}

jobs:
  validate:
    strategy:
      matrix:
        repo: [Agents-eval, RAPID-spec-forge, ai-agents-research]
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "Run make validate and report results"
          claude_args: "--max-turns 5"
```

## Result Collection

### Local (current)

```
$OUTPUT_DIR/
├── Agents-eval.json
├── RAPID-spec-forge.json
└── cc-research.json
```

### Cloud (adapted)

Results are GitHub PRs. Collect programmatically:

```bash
for repo in "${REPOS[@]}"; do
  name=$(basename "$repo")
  echo "=== ${name} ==="
  github_repo=$(git -C "$repo" remote get-url origin | sed 's#.*github.com[:/]##;s#\.git$##')
  gh pr list --repo "${github_repo}" --state open --json number,title,createdAt \
    --jq '.[] | "\(.number): \(.title) (\(.createdAt))"'
done
```

## Known Limitations

1. **One repo per session** — no cross-repo context sharing. Each `--remote` session sees only its own repo. [Feature request: #23627](https://github.com/anthropics/claude-code/issues/23627)
2. **No budget/turn caps** — cloud sessions consume account rate limits, no per-session `--max-budget`
3. **No JSON output** — results are git commits, not structured JSON. Parse via `gh` CLI
4. **GitHub only** — no GitLab, Bitbucket, or local-only repos
5. **Research preview** — `--remote` flag and CC Web are still in preview

## Decision

| Workflow | Use local (`cc-parallel.sh`) | Use cloud (`--remote`) | Use GitHub Actions |
|---|---|---|---|
| Quick validation | When repos are local | When on mobile/no terminal | Scheduled (daily/weekly) |
| Security audit | Budget-constrained runs | Fire-and-forget, async review | Periodic automated audits |
| Status check | Always (instant, no API cost) | N/A | N/A |
| Long-running tasks | Needs tmux keep-alive | Built-in persistence | Durable, survives restarts |
| Cross-repo context | Supported (additionalDirs) | Not supported | Not supported |

## References

- [Claude Code on the Web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [Scheduled Tasks](https://code.claude.com/docs/en/scheduled-tasks)
- [Multi-repo feature request #23627](https://github.com/anthropics/claude-code/issues/23627)
