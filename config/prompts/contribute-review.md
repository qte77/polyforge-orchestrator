You are reviewing an open PR in {{UPSTREAM}} ({{TECH_STACK}} stack).

## Objective

Provide a thorough, constructive code review.

## Steps

1. List open PRs: `gh pr list -R {{UPSTREAM}} --json number,title,author`
2. Check out the PR locally: `gh pr checkout <number> -R {{UPSTREAM}}`
3. Use /codebase-tools:researching-codebase to understand the context of the changes
4. Review the diff: `git diff main...HEAD`
5. Run tests if a test suite exists
6. Assess:
   - Correctness: Does it fix the stated issue?
   - Style: Does it follow project conventions?
   - Tests: Are changes adequately tested?
   - Security: Any OWASP concerns?
7. Post review via `gh pr review <number> -R {{UPSTREAM}} --comment --body "<review>"`

## Constraints

- Be constructive and specific — reference file:line
- Do NOT approve or request changes — comment only (we are external contributors)
- Use /cc-meta:compacting-context if context exceeds 50%
