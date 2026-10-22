# Changelog — mp

## [2.0.0] - 2026-10-22

### Changed
- **Incompatible:** los comandos de commit, release, doctor y promote pasan de `/mp:*` a `/mp-core:*`. `mp` declara `mp-core` como dependencia. `/mp:init`, `/mp:flow` y `/mp:flow-auto` no cambian.
- Los agentes de UI y de pruebas manuales (`flow-designer`, `flow-ui-coder`, `flow-ui-refiner`, `flow-manual-tester`) pasan a `mp-core` como `ui-designer`, `ui-coder`, `ui-refiner` y `manual-tester`; `flow-auto` los invoca con su nuevo nombre.
- `flow-documenter` redacta con la skill `humanizer`.

## [1.7.0]

Última línea 1.x: el comando promote llevaba a un PR los cambios hechos en caliente. Historial anterior en `git log -- plugins/mp`.
