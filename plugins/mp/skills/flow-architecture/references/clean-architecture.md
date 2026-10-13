# Clean Architecture como lista de revisión

Lente por defecto. Aplica la precedencia y la proporcionalidad de `SKILL.md` antes de usarla.

## Regla de dependencia

Las dependencias de código apuntan hacia adentro: frameworks y drivers → adaptadores → casos de uso → entidades. Lo interno no conoce nombres, clases ni formatos de lo externo. El número de círculos es flexible; la regla no.

| Qué verificar en los artefactos | Hallazgo si falla |
|---|---|
| `design.md` nombra las capas del change y la dirección de las dependencias | Falta declarar el modelo de capas: no se puede verificar la regla |
| Lo interno define los contratos (interfaces) y lo externo los implementa | Dependencia invertida: el núcleo depende del detalle |
| Los datos que cruzan un límite son estructuras simples (DTO), no modelos del ORM ni objetos del framework | Filtración del framework o del esquema al núcleo |
| Las tareas ubican cada pieza en una capa concreta | Tarea ambigua: riesgo de que la lógica acabe en el borde |

## Entidades y casos de uso

- **Entidad:** regla de negocio que existiría aunque no hubiera software. No es una fila de BD ni depende de HTTP, ORM o framework.
- **Caso de uso:** una operación de aplicación (`CrearPedido`, `AprobarGasto`). Recibe un modelo de solicitud y devuelve un modelo de respuesta, nunca objetos del framework.
- Un cambio en un caso de uso no debe obligar a cambiar una entidad. Si pasa, la regla está en el sitio equivocado.

| Verificar | Hallazgo si falla |
|---|---|
| Las reglas de negocio de los specs tienen un dueño identificable en el núcleo | Regla sin dueño: tenderá a quedar en controller o servicio |
| Los casos de uso son operaciones separadas, no un orquestador gigante por feature | Caso de uso inflado, difícil de probar y de cambiar |
| Los casos de uso no conocen el canal de entrega (HTTP, CLI, cola, mensaje de extensión) | Núcleo acoplado a la entrega |

## Adaptadores y frameworks

- Controladores traducen la entrada externa a la entrada del caso de uso; presentadores traducen la salida a la vista.
- Gateways implementan los contratos de persistencia o de servicios externos que define el núcleo.
- El framework es un detalle del círculo exterior. Quien llama es el framework hacia el código propio, no al revés.
- La composición (quién construye qué) ocurre en un solo punto, en el borde. Las clases internas no instancian implementaciones concretas.

| Verificar | Hallazgo si falla |
|---|---|
| El núcleo no importa nada del framework, del ORM ni del SDK externo | Acoplamiento al framework: cambiar de proveedor implica reescribir reglas |
| Hay un único punto de composición | Dependencias concretas repartidas por el núcleo |
| Se puede probar la lógica de negocio sin BD, servidor ni framework | Lógica acoplada a infraestructura |

## Límites

- Un límite es una línea entre lo que importa y los detalles; la dependencia lo cruza hacia adentro, el control puede cruzarlo en ambos sentidos.
- **Límite completo:** contratos a ambos lados. **Parcial:** una estrategia o una fachada, más barato y suficiente si la volatilidad es baja.
- **Humble Object:** separa el código difícil de probar (vista, envío, persistencia) de la lógica testeable que lo alimenta.
- Un servicio o microservicio **no** es un límite arquitectónico por sí solo: con un modelo de datos compartido es un monolito con red de por medio.
- Dibuja límites donde hay volatilidad probable; omitirlos por "es simple" acumula acoplamiento, pero crearlos de más también cuesta (ver proporcionalidad).

| Verificar | Hallazgo si falla |
|---|---|
| Cada integración externa tiene un límite proporcional a su volatilidad | Integración incrustada en el núcleo, o límite completo donde bastaba una estrategia |
| El design no presenta "servicios" como arquitectura sin definir qué datos comparten | Monolito distribuido encubierto |

## Principios SOLID como chequeos

| Principio | Qué buscar | Señal de falla |
|---|---|---|
| SRP | Un módulo responde a un solo actor (quién pide los cambios), no solo "hace una cosa" | Un módulo que cambia por pagos, reportes y persistencia a la vez |
| OCP | Comportamiento nuevo por código nuevo (estrategia, plugin) | Cada variante nueva obliga a editar un `if/switch` central |
| LSP | Los subtipos funcionan tras la interfaz base sin sorpresas | Subtipo que lanza excepciones inesperadas o ignora métodos |
| ISP | Interfaces pequeñas por rol | Clientes que dependen de métodos que no usan |
| DIP | Alto nivel define la abstracción, bajo nivel la implementa | El caso de uso depende de un cliente concreto (`StripeClient`) |

Úsalos como diagnóstico de un hallazgo concreto, no como lista a recitar.

## Componentes (solo si el change crea o parte módulos desplegables)

- **Cohesión:** lo que cambia junto vive junto (CCP); no obligues a depender de lo que no se usa (CRP); lo que se libera junto es versionable junto (REP).
- **Acoplamiento:** el grafo de componentes no tiene ciclos (ADP); depende en dirección de la estabilidad (SDP); lo estable es abstracto (SAP).
- Si el design introduce un ciclo entre módulos, la salida es invertir una dependencia o extraer una abstracción compartida.

## Errores frecuentes a cazar

| Error | Cómo se ve en los artefactos |
|---|---|
| ORM filtrado al negocio | El spec o design habla de "tabla" donde debería hablar de concepto |
| Reglas en controllers | Tareas que ponen validaciones de negocio en el handler |
| Framework primero | El design empieza por la estructura del framework, no por las capacidades |
| Ciclos entre módulos | Dos módulos que se mencionan mutuamente como dependencia |
| Caso de uso gigante | Una tarea "implementar el flujo completo de X" sin partir |
| Microservicios por moda | Separación en servicios sin justificación de despliegue o equipo |
