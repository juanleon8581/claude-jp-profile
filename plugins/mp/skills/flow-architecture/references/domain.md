# Modelo de dominio: chequeos sobre los artefactos

Cárgala solo si los specs definen reglas o invariantes de negocio, hay varios conceptos de negocio relacionados, o una integración externa alimenta el modelo. En CRUD, UI o configuración, no aplica.

Esta referencia dice **cómo se modela** lo que va en la capa de dominio. **Dónde** va (capas, repositorios como contrato) lo cubre `clean-architecture.md`; no lo repitas.

## Los seis chequeos

| # | Tema | Qué verificar | Hallazgo si falla |
|---|---|---|---|
| 1 | Lenguaje ubicuo | Los nombres en specs, design y tasks son términos que el negocio reconoce. Un mismo término no significa dos cosas en dos specs | Nombres genéricos (`Manager`, `Processor`, `Helper`, `Utils`) o término ambiguo: el modelo oculta el negocio. Si un concepto cuesta nombrarlo, el modelo puede estar mal |
| 2 | Invariantes | Cada regla de negocio de los specs tiene un dueño claro dentro del modelo (entidad o agregado) | Reglas repartidas en servicios sobre estructuras de datos sin comportamiento (modelo anémico): se duplican y se contradicen |
| 3 | Entidad vs valor | Lo que tiene identidad que persiste se distingue de lo que se define solo por sus atributos. Los valores son inmutables | Todo modelado como entidad mutable: estado enredado. Preferir valores por defecto |
| 4 | Agregados | Si hay consistencia que garantizar entre objetos, hay un agregado con raíz única, frontera definida y tamaño mínimo. Se referencian entre sí por identificador | Agregado enorme (conflictos de concurrencia, cargas lentas) o consistencia pretendida entre objetos sin frontera |
| 5 | Capa anticorrupción | Cada integración externa (API, almacenamiento, mensajes de otra extensión) se traduce al modelo propio en el borde | El esquema externo aparece en el núcleo: cualquier cambio del proveedor rompe reglas de negocio |
| 6 | Contextos | Un concepto que significa cosas distintas según el área se modela por separado en cada una, con traducción explícita | Un solo modelo para todos (p. ej. un `Cliente` único para facturación, envíos y marketing), cada vez más contradictorio |

## Aclaraciones para no sobre-exigir

- Un contexto delimitado es una frontera de **modelo y lenguaje**, no un microservicio ni una unidad de despliegue. En un monolito basta con módulos separados.
- Un servicio de dominio solo orquesta; si contiene las reglas, es el síntoma del chequeo 2.
- Eventos de dominio: evalúalos solo si hay efectos entre agregados que no deben acoplarse de forma síncrona. No los pidas por defecto, y no propongas event sourcing salvo que el negocio necesite el historial como fuente de verdad.
- Una fábrica se justifica con reglas de creación complejas; un valor de dos campos solo necesita un constructor.
- Si el dominio resulta pobre (casi todo es almacenar y mostrar), dilo: es un hallazgo válido que el modelado profundo no aplica.

## Decisiones que no son del arquitecto

Qué parte del negocio es el núcleo diferencial, qué construir frente a comprar, y cómo se nombra un concepto en el lenguaje del negocio son **gaps de negocio**: formúlalos como preguntas al usuario con tu recomendación.
