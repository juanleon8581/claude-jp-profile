---
argument-hint: <type> <version> <source-branch> <target-branch>
description: Create a release PR using an existing CHANGELOG as body
model: sonnet
---

# Create Release PR

Arguments: `$ARGUMENTS`

Parse arguments:
- `type` = first arg — `"release"` (feature→release) or `"ship"` (release→main) — **required**
- `version` = second arg (e.g., `1.2.0`) — **required**
- `source-branch` = third arg — **required**
- `target-branch` = fourth arg — **required**

If any required argument is missing, **STOP**:
> Error: Usage: `/release-pr <type> <version> <source-branch> <target-branch>`
> Valid types: `release`, `ship`

## Step 1 — Read CHANGELOG

Read `docs/changelog/<version>/CHANGELOG.md`. If the file does not exist, **STOP**:
> Error: `docs/changelog/<version>/CHANGELOG.md` not found.
> Generate it first with `/changelog <version> <compare-branch>`.

Extract the sections content: everything between the `## [<version>]` heading and the footer link line. This is the `changelog_body`.

Generate a 2–3 sentence overview summarizing the most significant changes from the changelog entries.

## Step 2 — Create PR

**If type = `release`:**

```bash
gh pr create \
  --base <target-branch> \
  --head <source-branch> \
  --title "🔖 release: <version>" \
  --body "$(cat <<'EOF'
## Release <version>

### Overview
<2-3 sentence overview>

### Changes
<changelog_body verbatim>

### Checklist
- [ ] CHANGELOG reviewed
- [ ] Tests passing
- [ ] No breaking changes undocumented
EOF
)"
```

**If type = `ship`:**

```bash
gh pr create \
  --base <target-branch> \
  --head <source-branch> \
  --title "🚢 ship: <version>" \
  --body "$(cat <<'EOF'
## Ship <version> to production

### Overview
<2-3 sentence overview>

### Changes
<changelog_body verbatim>

### Checklist
- [ ] CHANGELOG reviewed
- [ ] Release branch is up to date with target
- [ ] Deployment plan confirmed
- [ ] Rollback plan ready
EOF
)"
```

If `gh pr create` fails because a PR already exists, run `gh pr view` and show the user the existing PR URL.

## Important Notes

- **NO COMMIT SIGNATURES**: PR body must not include "Generated with..." footers
- **OMIT EMPTY SECTIONS**: Don't include changelog sections with no entries in the body
