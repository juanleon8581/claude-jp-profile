# Changelog — mp

## [3.0.0] - 2026-11-03

### Changed
- **Incompatible:** se elimina la skill `flow`; su contenido pasa entero a `flow-auto`, que ahora es la única skill del flujo (`/flow` queda como alias) (6b8ed89).
- `flow-auto` separa `explore` de `propose`: explore es solo conversación, se ejecuta `/opsx:explore` de forma explícita con el arquitecto y el diseñador, y los artefactos de OpenSpec los construye `opsx:propose` solo por orden del usuario (6b8ed89).
- Los agentes `flow-*`, `/mp:init`, `project-check` y `flow-architecture` hablan solo de `flow-auto` (6b8ed89).

### Added
- Subcomando `flow-auto propose` (6b8ed89).

## [2.0.0] - 2026-10-22

### Changed
- **Incompatible:** los comandos de commit, release, doctor y promote pasan de `/mp:*` a `/mp-core:*`. `mp` declara `mp-core` como dependencia. `/mp:init` y `/mp:flow-auto` no cambian.
- Los agentes de UI y de pruebas manuales (`flow-designer`, `flow-ui-coder`, `flow-ui-refiner`, `flow-manual-tester`) pasan a `mp-core` como `ui-designer`, `ui-coder`, `ui-refiner` y `manual-tester`; `flow-auto` los invoca con su nuevo nombre.
- `flow-documenter` redacta con la skill `humanizer`.

## [1.7.0]

Última línea 1.x: el comando promote llevaba a un PR los cambios hechos en caliente. Historial anterior en `git log -- plugins/mp`.
