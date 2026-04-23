# CC Web Cloud Workflows

## Local vs Cloud

| Aspect | Local | Cloud |
| --- | --- | --- |
| **Execution** | Local, blocking | VM, fire-and-forget |
| **Output** | JSON to stdout | Branch + PR |
| **Parallel** | Processes + `wait` | Independent sessions |
| **Auth** | Local credentials | GitHub App |
| **Monitoring** | PID tracking, logs | `/tasks`, web UI |
| **Multi-repo** | `additionalDirs` | `additionalDirs` |

## Cloud Usage

```bash
claude --remote "Run make validate" \
  --repo github.com/qte77/Agents-eval
```

Monitor via `/tasks` in Claude Code, `claude.ai/code`,
or Claude mobile app.

## Known Limitations

<!-- All verified against first-party docs as of 2026-03 -->

1. **No per-session budget/turn caps** — shared
   account rate limits only
   ([docs](https://code.claude.com/docs/en/claude-code-on-the-web#pricing-and-rate-limits))
1. **No JSON output** — results are branches + diff
   view + optional PR
   ([docs](https://code.claude.com/docs/en/claude-code-on-the-web#review-changes-with-diff-view))
1. **GitHub only** — GitLab and other non-GitHub
   repos cannot be used
   ([docs](https://code.claude.com/docs/en/claude-code-on-the-web#limitations))

## References

- [CC on the Web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [CC GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [Scheduled Tasks](https://code.claude.com/docs/en/web-scheduled-tasks)
