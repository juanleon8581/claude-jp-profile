# Datos: chequeos cuando el change toca esquema, consultas o almacenamiento

Aquí solo revisas la **coherencia arquitectónica** de lo documentado. El detalle de Postgres lo cubre la skill `postgres-best-practices:supabase-postgres-best-practices`: si el proyecto usa Postgres o Supabase y el change toca tablas, migraciones, RLS, índices o consultas, cárgala con el tool `Skill` y úsala como autoridad en esos temas.

## Chequeos

| Verificar | Hallazgo si falla |
|---|---|
| El modelo de persistencia está separado del modelo de dominio y hay un mapeo explícito en el adaptador | El esquema dicta las reglas de negocio |
| El acceso a datos pasa por un contrato que define el núcleo; la implementación vive en el borde | Consultas esparcidas por la lógica |
| Cada cambio de esquema tiene migración, estrategia de compatibilidad (datos existentes, despliegue gradual) y reversa o plan de recuperación | Cambio destructivo o no reversible sin declararlo |
| Las reglas de acceso (quién lee o escribe qué) están declaradas en el design y se aplican en la capa de datos cuando el motor lo permite | Autorización solo en la aplicación, sin segunda barrera |
| Los casos de datos vacíos, primera ejecución, concurrencia y relojes están cubiertos en los specs | Caso borde sin definir |
| Las consultas críticas tienen un criterio de volumen y rendimiento esperado | Riesgo de consulta lenta no evaluado |
| El almacenamiento local (storage de la extensión, cachés) declara dónde vive el dato, su tamaño esperado, su caducidad y qué pasa con varias pestañas o procesos | Estado compartido sin reglas de concurrencia |

## Gaps de negocio frecuentes

Retención y borrado de datos, datos personales, auditoría y volúmenes esperados no se deciden aquí: pregúntalos al usuario con tu recomendación.
