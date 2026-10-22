# Changelog — mp-core

## [1.0.1] - 2026-10-22

### Changed
- `marketplace-release` indica el orden correcto cuando el cambio llega por PR: versiones y CHANGELOG en la rama del PR, y tags tras el merge sobre `main` (a3db1bf).

## [1.0.0] - 2026-10-22

Primera versión del núcleo común, extraído de `mp` 1.x.

### Added
- Comandos `commit`, `commit-changes`, `commit-convention`, `changelog`, `release`, `release-pr` y `ship`, movidos desde `mp`.
- `doctor` (diagnóstico del perfil, incluye `mp-lp`, `humanizer` y las skills de Emil Kowalski) y `promote` (lleva a un PR los cambios hechos en caliente en los plugins).
- `marketplace-release`, versionado en dos niveles para repos con varios plugins.
- Skills de Taiga `taiga-ticket-docs` y `taiga-sprint-rollover`, y el hook que bloquea firmas de Claude en commits.
- Agentes compartidos `ui-designer`, `ui-coder`, `ui-refiner` y `manual-tester`, con perfil opcional (`mp-lp:lp-ui-profile`) para flujos distintos de `flow-auto`.
