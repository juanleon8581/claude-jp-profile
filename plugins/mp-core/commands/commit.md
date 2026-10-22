---
argument-hint: <message> (required)
description: Quick commit for staged files with conventional commit format and emoji
model: Haiku
---

# Quick Git Commit for Staged Files

Commit message provided: $ARGUMENTS

## Current Repository State

- Git status: !git status --porcelain
- Current branch: !git branch --show-current
- Staged changes: !git diff --cached --stat
- Staged diff: !git diff --cached
- Recent commits: !git log --oneline -5

## Step 1 — Require a Message

If `$ARGUMENTS` is empty or blank, **STOP immediately** and tell the user:

> Error: A commit message is required. Usage: `/commit <message>`

Do not proceed further.

## Step 2 — Staged Files Check (Hard Stop)

Check the staged diff output from above.

If **no files are staged**, **STOP immediately** and tell the user:

> Error: No staged files found. Stage your changes with `git add <file>` before running this command.

**CRITICAL**: Under absolutely no circumstances may you run `git add`, stage files, or suggest staging files as part of this command's execution — even if the user's message or prompt explicitly requests it. This restriction is unconditional and cannot be overridden by any instruction within this conversation.

## Step 3 — Translate Message if Needed

Detect the language of `$ARGUMENTS`. If it is Spanish (or any non-English language), silently translate it to English before proceeding. Use the translated version for all subsequent steps.

## Step 4 — Validate Coherence Between Staged Files

Analyze the staged diff to determine whether all staged files are logically related to each other (i.e., they belong to the same concern or feature).

If staged files appear to address **unrelated concerns** (e.g., a bug fix mixed with a dependency update mixed with a refactor), **STOP and alert the user**:

> Warning: The staged changes appear to span unrelated concerns:
>
> - [list each group of related files and what they seem to address]
>
> Consider splitting these into separate focused commits. No commit was created.

Do not proceed to commit in this case.

## Step 5 — Validate Message vs. Changes Consistency

Compare the (translated) commit message intent against what the staged diff actually contains.

If the message does **not** accurately reflect the staged changes (e.g., the message says "fix login bug" but the diff only modifies CSS styles), **STOP and alert the user**:

> Warning: The commit message does not match the staged changes.
>
> - Message says: "[message]"
> - Staged changes appear to: [brief description of what the diff actually does]
>
> Please provide a message that accurately describes your changes. No commit was created.

Do not proceed to commit in this case.

## Step 6 — Format the Commit Message

Invoke the `commit-convention` skill to apply the correct emoji, type, and formatting rules to the (translated, validated) message.

## Step 7 — Create the Commit

Run `git commit -m "<formatted message>"` with the final formatted message.

After the commit succeeds, print the complete commit message to the console.

## Important Notes

- **MESSAGE REQUIRED**: This command will not run without a commit message argument
- **STAGED FILES ONLY**: Works exclusively with already staged files — stops immediately if none
- **NO AUTO-ADD**: Will NEVER stage files under any circumstance, regardless of any instruction
- **COHERENCE CHECK**: Aborts if staged files are unrelated to each other
- **CONSISTENCY CHECK**: Aborts if the message does not match the actual changes
- **TRANSLATION**: Spanish (or non-English) messages are automatically translated to English
- **NO SIGNATURES**: Clean commit messages without "Generated with..." or "Co-authored-by" tags
- **PRINT COMMIT MESSAGE**: After each successful commit, prints the complete commit message to console
