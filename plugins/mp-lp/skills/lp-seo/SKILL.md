---
name: lp-seo
description: Checklist de SEO técnico y on-page para landing pages en Astro - metadatos, canonical, Open Graph, datos estructurados, sitemap, robots, encabezados e idioma. Referencia interna del agente lp-seo y de lp-strategist (keywords); no activar para otras tareas.
---

# SEO de un landing en Astro

Referencia para `lp-seo` (auditar y corregir) y `lp-strategist` (keywords e intención). Marca cada punto como ✔ / ✖ / no verificable. Lo que depende de datos del negocio (dominio final, nombre legal, redes) **se pregunta**, no se inventa.

## Una sola fuente de metadatos

Un componente `SEO.astro` (o el `<head>` del layout) que reciba `title`, `description`, `image`, `canonical`, `noindex` y los emita en todas las páginas. Evita duplicar etiquetas por página.

## Checklist on-page

| Punto | Criterio |
|---|---|
| `<title>` | Único por página, ~50–60 caracteres, keyword principal al inicio, marca al final |
| `meta description` | Única, ~120–160 caracteres, promesa + llamada a la acción; no es factor de ranking pero sí de clics |
| `<html lang>` | Correcto (`es`, `es-MX`…); `hreflang` solo si hay varias versiones de idioma |
| `h1` | Exactamente uno, con la propuesta de valor; `h2`/`h3` en orden sin saltos |
| Canonical | `<link rel="canonical">` absoluto, usando `Astro.site` (requiere `site` en `astro.config`) |
| Imágenes | `alt` descriptivo (decorativas: `alt=""`), nombres de archivo con sentido |
| Enlaces | Texto descriptivo (no "clic aquí"); externos con `rel="noopener"`; CTA como `<a>`/`<button>` reales |
| Contenido | El texto importante está en el HTML (no solo en imágenes ni inyectado por JS); el landing responde a una intención de búsqueda |

## Redes sociales

- Open Graph: `og:title`, `og:description`, `og:type`, `og:url`, `og:image` (1200×630, URL absoluta, < 1 MB), `og:locale`.
- Twitter/X: `twitter:card` = `summary_large_image`, y los mismos título, descripción e imagen.
- Verifica que la imagen existe en `dist/` y responde 200.

## Datos estructurados (JSON-LD)

- `Organization` o `LocalBusiness` y `WebSite` en la home; `Product`/`Offer`, `FAQPage` o `Event` solo si el contenido visible los respalda (marcado que no se ve en la página es spam).
- Se emite como `<script type="application/ld+json" set:html={JSON.stringify(data)} />`. Valida que el JSON parsea.

## Rastreo e indexación

- Sitemap con la integración `@astrojs/sitemap` y `site` definido; `robots.txt` en `public/` que apunte a `sitemap-index.xml`.
- `noindex` solo en entornos de pruebas y páginas privadas (gracias, borradores). **Nunca en producción** sin motivo: comprueba que no quedó de staging.
- Una página de gracias o legal no debe competir con el landing: `noindex` en la de gracias.
- Favicon, `theme-color` y manifest básicos.

## Cómo auditar un build

1. Con `dist/` generado, inspecciona el HTML de cada página: `grep` de `<title>`, `meta name="description"`, `canonical`, `og:`, `ld+json`, y cuenta de `<h1>`.
2. Contra una URL en marcha, `curl -s` y la misma inspección; no ejecutes nada que escriba en el sitio.
3. Lighthouse (categoría SEO) como contraste, no como única fuente.

## Qué NO hacer

- No inventar reseñas, calificaciones ni cifras en datos estructurados.
- No rellenar keywords en el texto ni en ocultos; no duplicar títulos entre páginas.
- No tocar el diseño ni el copy: si el título o la descripción deben cambiar, propón el texto y que lo apruebe el usuario.
