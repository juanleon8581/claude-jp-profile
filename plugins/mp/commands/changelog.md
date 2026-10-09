---
argument-hint: <version> <compare-branch>
description: Generate or update CHANGELOG for a version from commits between two branches
model: sonnet
---

# Generate CHANGELOG

Arguments: `$ARGUMENTS`

Parse arguments:
- First argument = `version` (e.g., `1.2.0`) — **required**
- Second argument = `compare-branch` (e.g., `origin/release/1.2.0`) — **required**

If either is missing, **STOP** with:
> Error: Usage: `/changelog <version> <compare-branch>`

## Step 1 — Gather Commits

Run:

```bash
git log --pretty=format:"%h %s" <compare-branch>..HEAD
git diff --stat <compare-branch>..HEAD
```

If the git log output is empty or errors, **STOP**: no commits found between branches.

Store:
- `commits` = output of git log

## Step 2 — Categorize Commits

Using commit-convention emoji/type mapping:

| keepachangelog section | commit types |
|---|---|
| Added | feat, db, ➕ |
| Changed | refactor, perf, style, chore |
| Removed | fix with 🔥, commits with "remove" or "delete" in subject |
| Fixed | fix (except 🔒 and 🔥) |
| Security | 🔒, commits with "security" in subject |
| Deprecated | contextual only — include if a commit explicitly mentions deprecation |

For each commit, produce a candidate entry: `- <imperative-mood description> (<hash>)` — strip emoji/type prefix, write user-facing prose. Store the short hash for each entry.

### Check for existing CHANGELOG

Check whether `docs/changelog/<version>/CHANGELOG.md` already exists.

- **If it does NOT exist** → go to **2a (Fresh)**.
- **If it DOES exist** → go to **2b (Merge)**.

### 2a — Fresh CHANGELOG (file does not exist)

Create `docs/changelog/<version>/CHANGELOG.md` with:
- Header: `# Changelog` + blank line + `## [<version>] - <today's date YYYY-MM-DD>`
- One section per category that has entries — **omit empty sections entirely**
- Each entry on its own line
- Footer: `[<version>]: https://keepachangelog.com/en/1.1.0/`

### 2b — Merge into existing CHANGELOG

1. **Read** the entire contents of `docs/changelog/<version>/CHANGELOG.md`.
2. **Extract existing hashes**: scan every line matching the pattern `(<hash>)` at end of line and collect those hashes into a set called `existing_hashes`.
3. **Filter new entries**: from the candidate entries, discard any whose hash is already in `existing_hashes`. Call the remaining entries `new_entries`.
4. **If `new_entries` is empty**, tell the user "No new commits to add — CHANGELOG is already up to date" and skip to Step 3 (review only).
5. **Update the date**: in the `## [<version>] - YYYY-MM-DD` line, replace the date with today's date.
6. **Merge entries section by section**:
   - For each section that has `new_entries`:
     - If that `### <Section>` heading already exists, append new entries immediately after the last existing entry in that section (before the next `###` or end of file).
     - If that `### <Section>` heading does NOT exist, insert it in standard keepachangelog order: Added → Changed → Deprecated → Removed → Fixed → Security.
7. **Write** the updated content back to `docs/changelog/<version>/CHANGELOG.md`.

## Step 3 — Review Checkpoint

Display the full contents of the generated CHANGELOG and say:

> CHANGELOG written to `docs/changelog/<version>/CHANGELOG.md`. Review the entries above and confirm to proceed, or tell me what to change.

**Do not proceed until the user explicitly confirms.**

## Important Notes

- **OMIT EMPTY SECTIONS**: Don't include keepachangelog sections with no entries
- **NO COMMIT SIGNATURES**: Do not add "Generated with..." footers
