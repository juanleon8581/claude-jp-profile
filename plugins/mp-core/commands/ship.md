---
argument-hint: <generate-changelog> (e.g., true)
description: Promote a release branch to main/master with a changelog-based PR
model: sonnet
---

# Ship: Release → Main

Arguments: `$ARGUMENTS`

## Step 1 — Validate & Gather

**First**, check the current branch:

```bash
git branch --show-current
```

If the current branch does **NOT** match the pattern `release/<version>`, **STOP immediately**:

> Error: `/ship` must be run from a `release/*` branch. Current branch is not a release branch.

Extract `version` from the branch name (everything after `release/`).

Parse arguments:

- If `$ARGUMENTS` is exactly `true`, set `generate = true`. Otherwise `generate = false`.

Determine the default branch:

```bash
git remote show origin | grep "HEAD branch" | awk '{print $NF}'
```

Store as `main_branch`. If this command fails, try `main` and `master` in that order and use whichever exists remotely.

Store:

- `current_branch` = current branch name
- `version` = extracted from branch name
- `main_branch` = default branch (e.g., `main` or `master`)
- `generate` = `true` | `false`

## Step 2 — Changelog

**If `generate = true`:**

Invoke the `changelog` skill with arguments: `<version> origin/<main_branch>`

Wait for user confirmation from the changelog skill's review checkpoint before continuing to Step 3.

**If `generate = false` (default):**

Check whether `docs/changelog/<version>/CHANGELOG.md` exists.

If it does **NOT** exist, **STOP**:

> Error: `docs/changelog/<version>/CHANGELOG.md` not found.
> Run `/ship true` to generate it first, or create it manually.

Display the full existing CHANGELOG contents and say:

> Using existing CHANGELOG for `<version>`. Review the entries above and confirm to proceed with PR creation, or tell me what to change.

**Do not proceed until the user explicitly confirms.**

## Step 3 — Create PR

Invoke the `release-pr` skill with arguments: `ship <version> <current_branch> <main_branch>`

## Important Notes

- **MUST BE ON RELEASE BRANCH**: Stops immediately if current branch is not `release/*` — no exceptions
- **GENERATE DEFAULTS TO FALSE**: Assumes changelog already exists unless `true` is passed
- **REVIEW GATE**: Never creates the PR without explicit user confirmation
- **NO COMMIT SIGNATURES**: PR body must not include "Generated with..." footers
