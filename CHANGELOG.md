# Changelog

Versión del repo `mp-marketplace` (SemVer). Cada entrada es una instantánea: qué versión de cada plugin iba junta. El detalle de cada plugin está en su propio `CHANGELOG.md`. Tags: `v<x.y.z>` para el repo y `<plugin>-v<x.y.z>` para cada plugin.

## [2.0.0] - 2026-10-22

Separa `mp` en un núcleo común y perfiles, y añade el perfil de landing pages.

| Plugin | Versión | Cambio |
|---|---|---|
| [mp-core](plugins/mp-core/CHANGELOG.md) | 1.0.0 | nuevo — commits, releases, promote, doctor, Taiga y agentes de UI compartidos |
| [mp](plugins/mp/CHANGELOG.md) | 2.0.0 | major — comandos de utilidades pasan a `/mp-core:*`; depende de `mp-core` |
| [mp-lp](plugins/mp-lp/CHANGELOG.md) | 0.1.0 | nuevo — flujo `lp` para landing pages |

Antes de esta versión el repo no tenía versión propia; `v1.7.0` fue la última de `mp` como plugin único (ver tag `backup/pre-mp-core-20261022`).
