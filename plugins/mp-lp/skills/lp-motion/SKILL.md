---
name: lp-motion
description: Guía de animaciones y microinteracciones para landing pages en Astro - CSS primero, GSAP/ScrollTrigger cuando hace falta, reduced-motion, rendimiento y limpieza con View Transitions. Referencia interna del agente lp-motion y de ui-designer; no activar para otras tareas.
---

# Movimiento en un landing Astro

El movimiento comunica (jerarquía, causa y efecto, foco) o no se hace. Cada animación debe responder "¿qué le dice esto a la persona?". Referencia para `lp-motion` (implementar) y `ui-designer` (definir el lenguaje de movimiento).

## Orden de preferencia

1. **CSS** (transiciones, `@keyframes`, `:hover`/`:focus-visible`) para microinteracciones.
2. **CSS scroll-driven** (`animation-timeline: view()` / `scroll()`) para reveals simples, como mejora progresiva con `@supports`.
3. **IntersectionObserver** propio y pequeño para "aparecer al entrar" si no hay soporte suficiente.
4. **GSAP (+ ScrollTrigger)** solo para secuencias, scrub o pin que lo anterior no resuelve. Se carga en la sección que lo usa, no globalmente. Consulta la documentación vigente de la librería antes de escribir su API.

## Reglas de rendimiento

- Anima **solo `transform` y `opacity`** (y `filter` con cuidado). Nunca `top/left/width/height/margin`.
- Reserva el espacio (alto/aspect-ratio) de todo lo que aparece para no provocar **CLS**.
- `will-change` solo durante la animación, nunca permanente ni en muchos elementos.
- Nada de animar sobre el contenido del LCP en la carga inicial: el elemento principal debe pintarse sin esperar a JS.
- El contenido nunca debe quedar oculto si el JS falla: el estado inicial "invisible" se aplica con una clase que pone el propio script (`js-enabled`), no en el CSS base.
- Presupuesto: sin librería de animación si la sección se resuelve con CSS; si usas GSAP, importa solo los módulos necesarios.

## Accesibilidad (obligatoria)

- `@media (prefers-reduced-motion: reduce)`: elimina o reduce a un fundido; sin parallax, sin autoplay con movimiento, sin scroll-jacking.
- Nada que parpadee más de 3 veces por segundo.
- Contenido en movimiento automático > 5 s necesita pausa. El foco visible no se anima ni se oculta.
- Las animaciones no cambian el orden de lectura ni la navegación por teclado.

## Astro: islas, scripts y transiciones

- Un `<script>` de Astro se empaqueta y se ejecuta una vez; para componentes que se repiten, selecciona por atributo (`data-reveal`), no por id.
- Con View Transitions (`<ClientRouter />` en Astro 5, `<ViewTransitions />` en Astro 4) los scripts no se reejecutan solos: inicializa en `astro:page-load` y limpia (`ScrollTrigger.kill()`, `observer.disconnect()`) en `astro:before-swap`.
- Prefiere `client:visible` o `client:idle` para islas con animación; `client:load` solo si lo exige la interacción inicial.

## Qué entregar (`lp-motion`)

Un archivo/ módulo por sección (`src/scripts/` o junto al componente), tokens de duración y easing compartidos (variables CSS) y la lista de qué se anima, con su motivo y su versión con movimiento reducido.
