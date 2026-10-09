---
description: Conventional commit format reference with emojis and best practices
---

# Conventional Commit Format

Use the format `<emoji> <type>: <description>` where type and emoji are chosen from the table below.

## Emoji & Type Reference

| Emoji | Type | When to use |
|-------|------|-------------|
| ✨ | feat | A new feature |
| 🐛 | fix | Bug fix |
| 📝 | docs | Documentation changes |
| 💄 | style | Code style changes (formatting, etc) |
| ♻️ | refactor | Code refactoring |
| ⚡️ | perf | Performance improvements |
| ✅ | test | Adding or fixing tests |
| 🔧 | chore | Changes to the build process, tools, etc. |
| 🚀 | ci | CI/CD improvements |
| 🗑️ | revert | Reverting changes |
| 🧪 | test | Add a failing test |
| 🚨 | fix | Fix compiler/linter warnings |
| 🔒️ | fix | Fix security issues |
| 👥 | chore | Add or update contributors |
| 🚚 | refactor | Move or rename resources |
| 🏗️ | refactor | Make architectural changes |
| 🔀 | chore | Merge branches |
| 📦️ | chore | Add or update compiled files or packages |
| ➕ | chore | Add a dependency |
| ➖ | chore | Remove a dependency |
| 🌱 | chore | Add or update seed files |
| 🧑‍💻 | chore | Improve developer experience |
| 🧵 | feat | Add or update code related to multithreading or concurrency |
| 🔍️ | feat | Improve SEO |
| 🏷️ | feat | Add or update types |
| 💬 | feat | Add or update text and literals |
| 🌐 | feat | Internationalization and localization |
| 👔 | feat | Add or update business logic |
| 📱 | feat | Work on responsive design |
| 🚸 | feat | Improve user experience / usability |
| 🩹 | fix | Simple fix for a non-critical issue |
| 🥅 | fix | Catch errors |
| 👽️ | fix | Update code due to external API changes |
| 🔥 | fix | Remove code or files |
| 🎨 | style | Improve structure/format of the code |
| 🚑️ | fix | Critical hotfix |
| 🎉 | chore | Begin a project |
| 🔖 | chore | Release/Version tags |
| 🚧 | wip | Work in progress |
| 💚 | fix | Fix CI build |
| 📌 | chore | Pin dependencies to specific versions |
| 👷 | ci | Add or update CI build system |
| 📈 | feat | Add or update analytics or tracking code |
| ✏️ | fix | Fix typos |
| ⏪️ | revert | Revert changes |
| 📄 | chore | Add or update license |
| 💥 | feat | Introduce breaking changes |
| 🍱 | assets | Add or update assets |
| ♿️ | feat | Improve accessibility |
| 💡 | docs | Add or update comments in source code |
| 🗃️ | db | Perform database related changes |
| 🔊 | feat | Add or update logs |
| 🔇 | fix | Remove logs |
| 🤡 | test | Mock things |
| 🥚 | feat | Add or update an easter egg |
| 🙈 | chore | Add or update .gitignore file |
| 📸 | test | Add or update snapshots |
| ⚗️ | experiment | Perform experiments |
| 🚩 | feat | Add, update, or remove feature flags |
| 💫 | ui | Add or update animations and transitions |
| ⚰️ | refactor | Remove dead code |
| 🦺 | feat | Add or update code related to validation |
| ✈️ | feat | Improve offline support |

## Golden Rule

> **NEVER sign commits as Claude.** No `Co-Authored-By: Claude`, no `Generated with Claude Code`, no `🤖`, no AI attribution of any kind — in subject, body, or trailer. This applies to every commit, every project, no exceptions.

## Best Practices

- **Present tense, imperative mood**: Write as commands ("add feature" not "added feature")
- **Concise first line**: Keep under 72 characters
- **Atomic commits**: Each commit should contain related changes that serve a single purpose
- **NO SIGNATURES**: Clean commit messages — no "Generated with..." or "Co-authored-by" tags

## Examples

- ✨ feat: add user authentication system
- 🐛 fix: resolve memory leak in rendering process
- 📝 docs: update API documentation with new endpoints
- ♻️ refactor: simplify error handling logic in parser
- 🚨 fix: resolve linter warnings in component files
- 👔 feat: implement business logic for transaction validation
- 🩹 fix: address minor styling inconsistency in header
- 🚑️ fix: patch critical security vulnerability in auth flow
- 🎨 style: reorganize component structure for better readability
- 🔥 fix: remove deprecated legacy code
- 🦺 feat: add input validation for user registration form
- 📈 feat: implement analytics tracking for user engagement
- 🔒️ fix: strengthen authentication password requirements
- ♿️ feat: improve form accessibility for screen readers
