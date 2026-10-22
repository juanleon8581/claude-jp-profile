---
name: lp-ui-profile
description: Perfil de landing pages para los agentes compartidos mp-core:ui-designer, ui-coder y ui-refiner - stack Astro + TypeScript + Tailwind, mapa de secciones, ganchos para movimiento y medios, reglas de contenido y formatos de informe. Lo carga el agente cuando el orquestador lp se lo indica; no activar para otras tareas.
---

# Perfil `lp` para los agentes de UI compartidos

Los agentes `ui-designer`, `ui-coder` y `ui-refiner` (plugin `mp-core`) trabajan igual en `flow-auto` y en `lp`. Esta skill concentra lo propio de un **landing en Astro**. Se **suma** a las reglas del agente: no relaja ninguna regla dura. En el formato de informe, **reemplaza** al formato por defecto donde lo indica.

Contexto del flujo `lp`: el brief aprobado es `lp/brief.md`, la dirección aprobada es `lp/direction.md`, la unidad de trabajo es una **sección** (`lp/sections.md`), y el movimiento y los medios los trabajan otros agentes (`lp-motion`, `lp-media`). No existe OpenSpec ni `tasks.md`.

## Stack (aplica a los tres roles)

- **Astro + TypeScript estricto + Tailwind.** Las secciones estáticas son componentes `.astro` con Tailwind y **cero JavaScript de cliente**. Props tipadas con `interface Props`.
- **shadcn solo donde hay interacción** (formulario, acordeón, diálogo, menú móvil). Cada isla se hidrata con `client:visible` o `client:idle`; `client:load` únicamente si la interacción inicial lo exige, y se justifica en el informe. Requiere `@astrojs/react`; si falta, se reporta, no se instala.
- Tokens de Tailwind (`@theme`) en vez de valores sueltos. Semántica HTML correcta; **un solo `h1` en toda la página**.
- Comandos de tipos y build: los de `CLAUDE.md` (`astro check`, `astro build`).
- **Contenido:** nada de marca, textos legales, precios, testimonios ni datos de contacto inventados. Usa el copy del brief/dirección; lo que falta queda como texto neutro con `TODO(lp):` y se reporta como `_pendiente_`.

## Rol `ui-designer`

Tu entregable es el contenido de `lp/direction.md`. Además de las decisiones por defecto, define:

- **Mapa de secciones** en el orden de la página, con composición (layout, jerarquía, foco), el mensaje y CTA del brief, y por sección si lleva **movimiento** y si lleva **medios**.
- **Medios:** dirección de arte de imágenes/video, relaciones de aspecto y cuál es el **elemento LCP** (normalmente el hero). Carga `mp-lp:lp-media` para que lo decidido sea viable en peso y formato.
- **Lenguaje de movimiento:** duración, easing, qué entra y cómo, y la versión con `prefers-reduced-motion`. Carga `mp-lp:lp-motion`. Nómbralo con `animation-vocabulary` para que `lp-motion` lo implemente sin ambigüedad.
- **Componentes:** cuáles son `.astro` + Tailwind y cuáles son islas shadcn.

**Formato de informe (reemplaza al por defecto):**

```
## Resumen
<dirección en una frase y modo(s)>

## Fuentes consultadas
<brief / PRODUCT.md / DESIGN.md / skills, y qué decidió cada una>

## Sistema de diseño
<tokens y reglas; qué se hereda y qué es nuevo>

## Lenguaje de movimiento
<principios, duraciones/easings, versión reduced-motion>

## Mapa de secciones
### <n>. <Sección> — movimiento: sí/no · medios: sí/no
- Objetivo y CTA (del brief):
- Composición, jerarquía y foco:
- Componentes: .astro/Tailwind · islas shadcn:
- Medios y elemento LCP (si aplica):
- Estados, responsive y accesibilidad:

## Textos de UI a validar
- <texto — dónde>

## Preguntas de negocio / marca para el usuario
- <con la opción que recomiendas>

## Checklist para ui-coder, lp-motion, lp-media, lp-seo y la QA visual
- [ ] <criterios verificables derivados de esta dirección>

## No verificado
- <lo que no pudiste comprobar>
```

## Rol `ui-coder`

Construyes **una sección**. Además de lo anterior:

- **Imágenes y video:** usa los componentes y rutas que deje `lp-media`; si todavía no existen, deja el componente con la ruta prevista y un comentario `TODO(lp-media)`. No optimices medios tú.
- **Movimiento:** no escribas la animación. Deja ganchos limpios (`data-reveal`, clases) y estructura estable para `lp-motion`.
- **Lógica de negocio:** formularios y envíos a un backend quedan con el contrato claro (props, acción esperada) y se reportan; no los implementes.

**Añade a tu informe** (después de "Verificación propia"):

```
## Ganchos para lp-motion y lp-media
- <selectores/atributos, medios esperados con su ruta prevista>

## Pendientes
- <_pendiente_ y TODO(lp)>
```

## Rol `ui-refiner`

Una pasada al final de la sección, **después** de `lp-media` y `lp-motion`:

- Audita contra la dirección y corrige accesibilidad, responsive, estados, foco, contraste y uso de tokens.
- **No toques la implementación del movimiento ni de los medios**: si encuentras un problema ahí (CLS por una animación, un `loading` incorrecto), repórtalo con el agente dueño (`lp-motion` o `lp-media`) para la ronda de corrección. Sí puedes corregir el `prefers-reduced-motion` o el `alt` si falta, porque son de accesibilidad.
- Los números de rendimiento (Lighthouse) no son tuyos: los mide el script `measure.sh` en la auditoría.
