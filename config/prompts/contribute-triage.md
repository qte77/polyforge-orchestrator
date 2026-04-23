You are triaging issue(s) {{ISSUES}} in the {{UPSTREAM}} repository ({{TECH_STACK}} stack).

## Objective

Explore the codebase, understand the issue(s), assess complexity, and post a triage comment.

## Steps

1. Use /codebase-tools:researching-codebase to explore the repo structure, dependencies, and conventions
2. Read the issue description and any existing comments via `gh issue view {{ISSUES}} -R {{UPSTREAM}}`
3. Identify the relevant source files and understand the root cause or feature scope
4. Assess complexity (low/medium/high) and estimate effort
5. Draft a triage comment with:
   - Root cause analysis or feature scope breakdown
   - Proposed implementation approach
   - Files that need changes
   - Test strategy
6. Post the comment: `gh issue comment <number> -R {{UPSTREAM}} --body "<comment>"`

## Constraints

- Do NOT make code changes — this is read-only triage
- Do NOT create branches or commits
- Use /cc-meta:compacting-context if context exceeds 50%
