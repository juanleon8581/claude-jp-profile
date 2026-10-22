---
name: lp-performance
description: Presupuestos y método de auditoría de rendimiento y accesibilidad para landing pages en Astro - Core Web Vitals, Lighthouse sobre un build de producción, presupuesto de JavaScript y checklist de accesibilidad. Referencia interna del flujo lp (script measure.sh y manual-tester); no activar para otras tareas.
---

# Rendimiento y accesibilidad de un landing Astro

Referencia para quien interprete las métricas (el orquestador `lp` y los agentes que corrigen). Las métricas las produce `scripts/measure.sh`; el recorrido visual lo ejecuta `mp-core:manual-tester`. Mide siempre un **build de producción** (`astro build` + `astro preview`, puerto 4321 por defecto), nunca `astro dev`. Reporta lo que mediste; si no pudiste medir algo, dilo.

## Presupuestos

| Métrica | Objetivo (móvil, p. 75) |
|---|---|
| LCP | ≤ 2.5 s |
| INP | ≤ 200 ms (en laboratorio, usa TBT como proxy: ≤ 200 ms) |
| CLS | ≤ 0.1 |
| Lighthouse Performance (móvil) | ≥ 90 |
| Lighthouse Accesibilidad / SEO / Buenas prácticas | ≥ 95 / ≥ 95 / ≥ 95 |
| JavaScript inicial | ≤ ~100 KB comprimido (Astro envía 0 por defecto; cada isla suma) |
| Peso total de la página | ≤ ~1.5 MB en la carga inicial |

Son objetivos, no dogmas: una desviación se reporta con su causa y el costo/beneficio de arreglarla.

## Cómo medir

1. Build y preview en segundo plano; espera a que responda. Al terminar, detén el proceso.
2. Lighthouse (necesita Chrome o Chromium; si falta, repórtalo y no inventes números):

```bash
npx --yes lighthouse http://localhost:4321/ --quiet --chrome-flags="--headless=new" \
  --output=json --output-path=./lh-mobile.json
npx --yes lighthouse http://localhost:4321/ --quiet --chrome-flags="--headless=new" \
  --preset=desktop --output=json --output-path=./lh-desktop.json
```

   Por defecto Lighthouse emula móvil. Escribe los JSON en un directorio temporal, no en el repo. Extrae con `jq` las categorías (`.categories.*.score`), las métricas (`.audits["largest-contentful-paint"].numericValue`, `cumulative-layout-shift`, `total-blocking-time`) y los audits fallidos (`score < 1`). Corre 2–3 veces si el resultado es borderline: hay varianza.
3. Contra la URL publicada usa la misma orden; los datos de laboratorio no sustituyen a los de campo.

## Causas típicas y dónde se arreglan

| Síntoma | Causa frecuente | Quién lo arregla |
|---|---|---|
| LCP alto | Hero sin `fetchpriority`, imagen sin optimizar, fuente bloqueante, animación de entrada | `lp-media`, `ui-coder` |
| CLS | Medios sin dimensiones, fuentes sin ajuste, contenido que aparece sin espacio reservado | `lp-media`, `ui-coder`, `lp-motion` |
| TBT / JS alto | `client:load` innecesario, GSAP global, scripts de terceros | `ui-coder`, `lp-motion` |
| Peso | Video de fondo, imágenes grandes, fuentes completas | `lp-media` |
| Terceros | Analítica/chat/píxeles síncronos | Diferirlos (`defer`, tras interacción) y consultarlo con el usuario |

## Accesibilidad (checklist)

- Contraste AA (4.5:1 texto normal, 3:1 grande y componentes de UI); revisa también sobre imágenes/gradientes.
- Todo interactivo alcanzable y operable con teclado, con **foco visible**; orden de tabulación lógico; sin trampas de foco.
- Un `h1`, jerarquía de encabezados sin saltos; landmarks (`header`, `main`, `nav`, `footer`); enlace "saltar al contenido".
- Formularios: `label` asociado a cada campo, errores descritos en texto (no solo color), `autocomplete`, objetivo táctil ≥ 44×44 px.
- Imágenes con `alt` correcto; video con alternativa; nada comunica solo con color.
- `prefers-reduced-motion` respetado; `lang` correcto; zoom hasta 200 % sin pérdida de contenido; sin `user-scalable=no`.
- Lighthouse cubre una parte; complementa con la inspección del DOM y la prueba visual con `terminal-browser`.

## Responsive y visual

Viewports mínimos: 360×800, 768×1024, 1280×800 y 1920×1080. En cada uno: sin scroll horizontal, texto legible, CTA visible sin esfuerzo, imágenes sin deformar, menús operables. Usa `terminal-browser` y no declares verificación visual que no hiciste.
