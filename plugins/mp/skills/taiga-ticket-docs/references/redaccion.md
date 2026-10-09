# Reglas de redacción: tono, jerga e idioma

## Jerga mínima

- Prefiere palabras comunes sobre términos técnicos: "guardar" en vez de "persistir", "enviar" en
  vez de "disparar/triggerear", "usuario" en vez de "entidad".
- Si un término técnico es imprescindible (nombre de API, protocolo, patrón), inclúyelo pero:
  - explícalo en una frase breve la primera vez, o
  - déjalo en su forma original entre paréntesis después de la palabra en español:
    `inicio de sesión único (SSO)`.
- No mezcles niveles de detalle: una user story no necesita nombrar tablas de base de datos,
  endpoints o nombres de funciones — eso va en una task técnica, no en la historia visible al PO.

## Audiencia: funcional e informativa, no técnica ni de proceso

Taiga es documentación **funcional e informativa para personas no técnicas de otras áreas** (negocio,
marketing, QA, PO), no un registro técnico ni del proceso de desarrollo. Cada texto cuenta **qué cambia o
qué queda disponible para la persona o el negocio**, y nada más. Aplica a asuntos, descripciones,
criterios y comentarios.

No incluyas, aunque sea cierto:

- **El proceso de trabajo ni el comportamiento de agentes o herramientas**: quién decidió algo (diseñador,
  arquitecto, orquestador, agente), que "se registra en el brief/documento de diseño", que algo "lo decide
  el equipo de diseño", fases del flujo, aprobaciones internas, revisiones o rondas de corrección. Es
  irrelevante para un flujo Scrum. Si una decisión importa a negocio, di la decisión, no quién la tomó ni
  cómo.
- **Artefactos y herramientas internas**: OpenSpec, specs, propuesta, tareas, brief, `DESIGN.md`, `flow`,
  git, ramas, commits, PR.
- **Detalle de implementación o de calidad técnica**: nombres de archivos, componentes o funciones; pruebas
  automáticas, cobertura, build, lint; estructura de código.
- **Promesas de verificación que no son del negocio** (p. ej. "tiene pruebas automáticas"). Los criterios
  describen lo que la persona puede comprobar al usarlo.

Autocomprobación antes de entregar un texto: "¿alguien de negocio o marketing notaría o necesitaría saber
esto para entender qué recibe?". Si no, se quita.

## Orientado a valor y a la persona

- Cada ticket responde primero "¿qué gana quién?" antes de "¿cómo se hace?".
- Evita descripciones puramente de implementación en el `subject`; el subject describe el resultado
  visible, no el mecanismo interno.

## Escaneable

- Frases cortas. Un ítem por bullet, no combines dos ideas en una línea de checklist.
- Secciones separadas con encabezados `##` (ver [templates.md](templates.md)) — nunca un bloque de
  texto corrido de varios párrafos.
- Máximo 2-3 frases por párrafo antes de pasar a lista o subsección.

## Detección de idioma predominante

1. Antes de redactar, lee 2-3 tickets existentes del proyecto (`list_userstories`, `list_issues`,
   `list_epics`, o `search`) para ver en qué idioma están `subject`/`description`.
2. Si predomina español → escribe en español, con términos técnicos en inglés entre paréntesis
   cuando aporten precisión (nombres de librerías, protocolos, siglas establecidas como "API",
   "SSO", "JWT").
3. Si predomina inglés → escribe en inglés, sin forzar traducciones.
4. Proyecto nuevo sin tickets previos → sigue el idioma en que el usuario formuló la petición; si
   no es claro, usa español por defecto.
5. No mezcles idiomas dentro de un mismo ticket salvo los términos técnicos entre paréntesis
   explícitamente permitidos arriba.
