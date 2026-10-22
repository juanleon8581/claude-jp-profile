# Changelog — mp-lp

## [0.1.1] - 2026-10-22

### Fixed
- La comprobación del proyecto recomienda `typescript@6`, porque `astro check` aún no soporta TypeScript 7 (b227da6).

## [0.1.0] - 2026-10-22

### Added
- Flujo `lp` para landing pages (Astro + TypeScript + Tailwind + shadcn) sin OpenSpec y con Taiga opcional por flujo.
- Brief como entrevista guiada: rondas con opciones, profundidad adaptativa, escalado de preguntas al cliente con cuestionario y resumen para `/impeccable init`.
- Agentes `lp-strategist`, `lp-motion`, `lp-media`, `lp-seo` y `lp-documenter`; skills de SEO, movimiento, medios y rendimiento; medición con Lighthouse sobre el build de producción.
- Comandos `init` y `audit`.
