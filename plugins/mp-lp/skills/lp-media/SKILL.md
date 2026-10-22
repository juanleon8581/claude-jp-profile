---
name: lp-media
description: Guía de manejo de multimedia para landing pages en Astro - imágenes con astro:assets, formatos AVIF/WebP, tamaños y carga, video, fuentes e iconos. Referencia interna del agente lp-media y de ui-coder; no activar para otras tareas.
---

# Medios en un landing Astro

Los medios son la mayor parte del peso de un landing y casi siempre mandan el LCP. Referencia para `lp-media`. No instales herramientas: usa lo que hay (Astro trae `sharp`) y, si falta algo como `ffmpeg`, repórtalo.

## Imágenes

- Los originales viven en `src/assets/` y se importan: `import hero from "../assets/hero.jpg"`. Así `astro:assets` los optimiza y conoce sus dimensiones. Lo que está en `public/` no se optimiza (solo para favicon, OG y cosas que necesitan URL fija).
- Usa `<Image />` / `<Picture />` de `astro:assets`: `formats={["avif","webp"]}` con el original como respaldo, `widths` y `sizes` realistas según el layout.
- **Nunca omitas `width`/`height`** (o deja que Astro los infiera del import) para evitar CLS.
- **La imagen LCP** (normalmente la del hero): `loading="eager"`, `fetchpriority="high"`, `decoding="async"` y sin lazy. **Todas las demás**: `loading="lazy"`.
- `alt` en cada imagen: descriptivo si informa, vacío (`alt=""`) si es decorativa.
- Calidad por defecto ~75–80 en AVIF/WebP; las fotos de fondo oscuras toleran menos. Entrega nunca > 200 KB en móvil para una imagen normal ni > 400 KB para el hero salvo motivo.
- Fondos CSS pesados: mejor `<Picture>` con `object-fit` que `background-image` (no se optimiza ni se prioriza bien).

## Ilustraciones, logos e iconos

- SVG inline o importado para logos e iconos (`currentColor` para tematizar); optimizados (sin metadatos de editor). Un solo set de iconos coherente (`lucide` con shadcn, por ejemplo), importando solo los usados.
- No uses PNG para iconos ni logos.

## Video

- Formatos: `<source>` en **WebM (VP9/AV1) y MP4 (H.264)**; MP4 como respaldo.
- Fondo/decorativo: `muted autoplay loop playsinline`, `preload="none"` o `metadata`, sin audio, y con `poster` (imagen optimizada). Respeta `prefers-reduced-motion` mostrando solo el poster.
- Con contenido y sonido: `controls`, sin autoplay, `preload="none"`, poster y subtítulos (`<track>`) cuando haya voz.
- Presupuesto orientativo: video de fondo < 2–3 MB, 5–10 s, ≤ 1080p; si no, cárgalo tras la interacción o `IntersectionObserver`.
- Compresión con `ffmpeg` solo si está instalado, y como paso explícito reportado (comando usado). Los originales pesados no entran al repo sin avisar.
- Embeds (YouTube/Vimeo): fachada (poster + botón) que carga el iframe al hacer clic; nunca el iframe en la carga inicial.

## Fuentes

- `woff2`, autoalojadas (no CDN de terceros), subconjunto latino, 1–2 familias y pocos pesos; mejor fuente variable.
- `font-display: swap` y `<link rel="preload" as="font" type="font/woff2" crossorigin>` solo para la fuente del texto del LCP. Ajusta métricas de fallback para evitar saltos de CLS.

## Qué entregar (`lp-media`)

Tabla de cada medio: ruta, formato final, dimensiones, peso antes/después, cómo se carga (eager/lazy/poster) y componente que lo usa. Lista de lo que no pudiste optimizar y por qué. Cualquier asset de marca o foto que falte se marca `_pendiente_`; no uses imágenes de stock ni las generes sin que el usuario lo pida.
