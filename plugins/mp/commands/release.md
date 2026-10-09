---
argument-hint: <target-branch> (e.g., release/1.2.0 or just 1.2.0)
description: Generate CHANGELOG from branch commits and create PR to target branch
model: sonnet
---

# Release: CHANGELOG + PR

Target branch: $ARGUMENTS

## Repository State

- Current branch: !git branch --show-current
- Remote release branches: !git branch -r --list "origin/release/*" | head -10

## Step 1 — Validate & Normalize

If `$ARGUMENTS` is empty, **STOP**:
> Error: A target branch is required. Usage: `/release release/1.2.0` or `/release 1.2.0`

Normalize the target:
- If `$ARGUMENTS` contains no `/`, prepend `release/` → `release/$ARGUMENTS`
- Strip any leading `origin/` if present
- Extract the version number (everything after the last `/`)

Store:
- `current_branch` = output of `!git branch --show-current`
- `target_branch` = normalized target (e.g., `release/1.2.0`)
- `version` = extracted version string (e.g., `1.2.0`)

## Step 2 — Generate CHANGELOG

Invoke the `changelog` skill with arguments: `<version> origin/<target_branch>`

Wait for user confirmation from the changelog skill's review checkpoint before continuing to Step 3.

## Step 3 — Create PR

Invoke the `release-pr` skill with arguments: `release <version> <current_branch> <target_branch>`

## Important Notes

- **ARGUMENT REQUIRED**: Stops immediately if no target branch is provided
- **NO EMPTY RELEASES**: Stops if there are no commits between branches
- **REVIEW GATE**: Never creates the PR without explicit user confirmation
