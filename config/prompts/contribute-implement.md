You are implementing a fix/feature for issue(s) {{ISSUES}} in a fork of {{UPSTREAM}} ({{TECH_STACK}} stack).

## Setup

1. Ensure you are on a clean branch: `git checkout -b contrib/{{ISSUES}}-work`
2. Use /codebase-tools:researching-codebase to understand the codebase before making changes

## Implementation (Strict TDD — tests first)

3. Use /tdd-core:testing-tdd with strict Red-Green-Refactor:
   a. RED: Write failing tests that define the expected behavior FIRST
   b. GREEN: Write the minimal implementation to make tests pass
   c. REFACTOR: Clean up while keeping tests green
4. Use {{SKILLS}} for language-specific best practices
5. Run the full test suite after each cycle to ensure no regressions
6. NEVER write implementation code before its corresponding test exists

## Context Management

7. Use /cc-meta:compacting-context at these milestones:
   - After initial exploration (before coding)
   - After implementation (before testing)
   - After testing (before PR creation)

## Commit and PR

8. Stage and commit with /commit-helper:committing-staged-with-message (conventional commits)
9. Push the branch: `git push -u origin contrib/{{ISSUES}}-work`
10. Create PR to upstream:
    ```
    gh pr create --repo {{UPSTREAM}} \
      --title "<concise title>" \
      --body "Fixes #{{ISSUES}}\n\n## Summary\n<description>\n\n## Test plan\n<how to verify>"
    ```

## Constraints

- Follow CONTRIBUTING.md if present
- Do not introduce new dependencies without justification
- Keep changes minimal and focused on the issue
