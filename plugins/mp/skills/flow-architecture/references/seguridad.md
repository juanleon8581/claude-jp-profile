# Seguridad: mini threat-check para un change

Es un chequeo acotado al change, no un modelo de amenazas del repositorio completo. No escribas archivos ni te detengas a esperar respuestas: lo que no puedas confirmar va a "No verificado" o a "Preguntas de negocio".

Método adaptado de `security-threat-model` (OpenAI, Apache-2.0).

## Pasos

1. **Límites de confianza.** Lista los bordes concretos entre componentes que toca el change (por ejemplo página anfitriona → content script → background → red → almacenamiento). Para cada uno anota qué protocolo cruza, qué autenticación hay, si se valida la entrada y si hay límite de tasa.
2. **Activos.** Qué datos o capacidades vale la pena proteger aquí: credenciales, tokens, datos personales, estado cuya integridad es crítica, configuración, permisos del manifest.
3. **Puntos de entrada.** Endpoints, mensajes entre contextos, subida o lectura de archivos, parsers de HTML o URLs, disparadores de tareas, herramientas de administración, logs y mensajes de error que se muestran.
4. **Atacante realista.** Quién puede llegar a cada entrada según la exposición. Anota también lo que **no** puede hacer, para no inflar la severidad.
5. **Rutas de abuso.** Pocas, de calidad: objetivo del atacante, entrada, activo afectado. Ejemplos: exfiltración, escalada de privilegios, alteración de integridad, denegación de servicio.
6. **Prioridad.** Probabilidad × impacto (baja/media/alta) con una justificación corta, ajustada por los controles que ya existen y se pueden ver en el código.

## Qué verificar contra los artefactos

| Verificar | Hallazgo si falla |
|---|---|
| Todo dato externo (HTML, URL, esquema, mensaje) se valida o sanea antes de llegar a la lógica o al DOM | Entrada sin validar: inyección, XSS, redirecciones |
| Cada punto de entrada declara quién puede invocarlo y qué comprueba | Autorización implícita |
| Los permisos pedidos (manifest, scopes, roles) son los mínimos necesarios | Permisos de más |
| Los secretos no aparecen en specs, tasks, logs ni en código de ejemplo | Secreto expuesto o mal ubicado |
| Los fallos (red, parser, datos corruptos) no exponen datos ni dejan estado inconsistente | Fallo inseguro |
| El contexto de ejecución correcto (content script, background, página) recibe solo lo que necesita | Contexto con más privilegio o datos de los debidos |

## Severidad de referencia

- **Alta:** ejecución remota sin autenticación, bypass de autenticación, acceso entre inquilinos, exfiltración de datos sensibles, robo de claves o tokens, alteración de la integridad de configuración.
- **Media:** denegación de servicio dirigida a un componente crítico, exposición parcial de datos, bypass de límite de tasa con impacto medible, envenenamiento de logs que afecta la detección.
- **Baja:** fugas de información poco sensible, denegación de servicio ruidosa y fácil de mitigar, casos que exigen condiciones improbables.

## Cuándo es una pregunta de negocio

Sensibilidad real de los datos, exposición a internet, multi-inquilino y quién es el atacante esperable no se deducen del código. Si cambian la severidad, formúlalas como pregunta al usuario y marca la recomendación como **condicional** a la respuesta.
