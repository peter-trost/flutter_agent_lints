# Rulesets

`main.json` is the ruleset applied to the default branch: pull requests only,
both check jobs green and the branch up to date, every review thread resolved,
squash or rebase merges, linear history, no force pushes or deletions, no
bypass for anyone. Zero required approvals because the sole maintainer cannot
approve their own pull requests; merging is the approval.

The API is the source of truth; this file is how it was applied and how to
re-apply it:

```bash
gh api --method POST repos/peter-trost/flutter_agent_lints/rulesets --input .github/rulesets/main.json
```

To update an existing ruleset, use `--method PUT` on `rulesets/<id>`.
