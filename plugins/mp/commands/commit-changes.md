---
argument-hint: [message]
description: Analyze, categorize and split all pending changes into separate commits with conventional commit format and emoji
model: sonnet
---

# Split All Pending Changes Into Commits

Analyze and categorize all pending changes into separate commits: $ARGUMENTS

## Current Repository State

- Git status: !git status --porcelain
- Current branch: !git branch --show-current
- Unstaged changes: !git diff --stat
- Staged changes: !git diff --cached --stat
- Recent commits: !git log --oneline -5

## What This Command Does

1. **ALL PENDING CHANGES**: Analyzes ALL modified files (both staged and unstaged)
2. **CATEGORIZATION**: Groups related changes together based on:
   - File types and directories (e.g., tests go with production code)
   - Functional areas (e.g., auth-related, UI, API, config)
   - Change types (feat, fix, refactor, docs, etc.)
3. **SMART SPLITTING**: Creates separate commits for each logical group
4. **STAGE AND COMMIT**: For each group:
   - Stages the relevant files
   - Creates a commit with an appropriate emoji conventional commit message
5. **NO SIGNATURES**: Commit messages are clean without any "Generated with..." or "Co-authored-by..." signatures
6. **PRINT OUTPUT**: After each commit, print the complete commit message to console

## Categorization Logic

The command will group changes by the following criteria:

**By Domain/Feature:**

- Authentication & Authorization (auth, login, user, permission, roles)
- UI Components (components, views, pages, screens)
- API & Routes (api, routes, controllers, handlers)
- Database (models, migrations, seeds, db)
- Tests (test, spec, **tests**)
- Configuration (config, env, settings)
- Documentation (docs, readme, changelog)
- Build & CI (build, ci, workflow, github actions, dockerfile)
- Dependencies (package.json, requirements.txt, go.mod, Cargo.toml)

**By Change Type:**

- Feature additions (new files, major functionality)
- Bug fixes (error handling, edge cases)
- Refactoring (code restructuring, no functional change)
- Documentation (comments, README changes)
- Styling/formatting (linting, prettier)
- Tests (new tests, test fixes)
- Configuration (env vars, build configs)

## Conventional Commit Format

For each commit message, invoke the `commit-convention` skill to apply the correct emoji, type, and formatting rules.

## Commit Execution Order

The command will create commits in the following logical order:

1. **Configuration & Dependencies** (build files, package managers)
2. **Database Changes** (migrations, schema updates)
3. **Tests** (test additions/fixes before production code)
4. **Features** (new functionality)
5. **Bug Fixes** (issue resolutions)
6. **Refactoring** (code restructuring)
7. **Documentation** (README, inline docs)
8. **CI/CD** (workflow changes)

## Best Practices

- **Atomic commits**: Each commit should contain related changes that serve a single purpose
- **Logical ordering**: Commits should be orderable (no circular dependencies between commits)
- See `commit-convention` skill for full formatting rules and best practices

## Examples

Good grouped commit messages:

**Feature addition:**

- ✨ feat: add user authentication system
- 📝 docs: update API documentation with auth endpoints
- ✅ test: add authentication unit tests

**Bug fix:**

- 🐛 fix: resolve memory leak in rendering process
- 🚑️ fix: patch critical security vulnerability in auth flow

**Refactoring:**

- ♻️ refactor: simplify error handling logic in parser
- ⚰️ refactor: remove dead code from legacy module

**Multiple domains:**

- 🗃️ db: add user preferences table
- ✨ feat: implement user settings API
- 📱 feat: add settings UI screen

## Important Notes

- **ALL PENDING CHANGES**: Analyzes and commits both staged and unstaged files
- **AUTOMATIC STAGING**: Automatically stages files for each commit group
- **NO VERIFICATION**: Skips all pre-commit checks (lint, build, format) for speed
- **NO DOCUMENTATION**: Skips documentation checking for speed
- **NO SIGNATURES**: Clean commit messages without "Generated with..." or "Co-authored-by" tags
- **PRINT COMMIT MESSAGE**: After each successful commit, prints the complete commit message to console
- If no changes are pending, the command will inform you and exit
