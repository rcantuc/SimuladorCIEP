# Marco de ciclo de vida de productos del Ecosistema CIEP

**Versión:** v1.0 — punto de partida, pendiente de validación de dirección del CIEP  
**Fecha:** 2026-05-15  
**Estado:** marco de decisión. NO es política ratificada. La autoridad de decisión definida en la sección 5 requiere validación de dirección del CIEP antes de ejercerse caso por caso.

---

**Qué resuelve este marco.** Antes de este documento, las decisiones sobre qué hacer con un producto del Ecosistema CIEP cuando envejece o se descontinúa se tomaban caso por caso, sin criterio escrito. Este marco formaliza el criterio: qué se conserva, qué se puede retirar, y quién tiene la autoridad para decidirlo en cada caso concreto.

---

## Tabla de contenido

1. [Ubicación en el Ecosistema CIEP](#1-ubicación-en-el-ecosistema-ciep)
2. [La distinción central: documento bandera vs. micrositio](#2-la-distinción-central-documento-bandera-vs-micrositio)
3. [El marco de decisión](#3-el-marco-de-decisión)
4. [Autoridad de decisión](#4-autoridad-de-decisión)
5. [Productos pendientes de clasificar](#5-productos-pendientes-de-clasificar)
6. [Estado del documento](#6-estado-del-documento)
7. [Bitácora de cambios](#7-bitácora-de-cambios)

---

## 1. Ubicación en el Ecosistema CIEP

*Qué aprendes en esta sección:* cómo encaja este marco en la arquitectura general del Ecosistema CIEP.

El **Ecosistema CIEP** es el conjunto completo de productos digitales, infraestructura y dominios del CIEP (definición formal en el Glosario CIEP institucional). Sus componentes incluyen los Simuladores CIEP (herramientas interactivas de análisis fiscal), los Micrositios (sitios web narrativos que presentan estudios y análisis al público general), el sitio principal `ciep.mx`, y la infraestructura compartida.

La arquitectura y la distribución de los **Simuladores CIEP** están descritas en `arquitectura-distribucion.md`. Este documento aplica a un conjunto más amplio: todos los productos del Ecosistema CIEP, incluyendo los Micrositios, cuando enfrentan la decisión de qué hacer con ellos al envejecer o descontinuarse.

---

## 2. La distinción central: documento bandera vs. micrositio

*Qué aprendes en esta sección:* por qué el activo con valor citable no es el micrositio, y qué consecuencias prácticas tiene esa distinción.

Antes de decidir el destino de cualquier producto del CIEP, hay que tener clara una distinción que cambia por completo el análisis:

### El documento bandera

El **documento bandera** es el estudio, análisis o informe del CIEP en sí: el texto con la metodología, los datos y los hallazgos. Es lo que se cita en artículos académicos, lo que aparece referenciado en prensa, lo que tiene valor de conservación permanente. Una vez publicado, su acceso debe mantenerse indefinidamente en `ciep.mx`.

### El micrositio

El **micrositio** es el contenedor web que explica el documento bandera de manera visual e interactiva para una audiencia más amplia. Es la capa de presentación: lo que un ciudadano ve cuando entra a `nombredelestudio.ciep.mx`. El micrositio no es la fuente citable — es la interfaz didáctica hacia el documento bandera.

### Un ejemplo concreto

Imagina un estudio del CIEP sobre pensiones publicado en 2017. El **documento bandera** es el PDF del informe con el análisis, los datos y las conclusiones: ese documento se cita, se referencia, se descarga. El **micrositio** `pensionesenmexico.ciep.mx` es el sitio web que explica visualmente ese mismo informe con gráficas interactivas.

Con el tiempo, los datos del micrositio envejecen. Pero el documento bandera no pierde valor porque sigue siendo la fuente original citada. La pregunta de governance no es "¿conservamos el producto?", sino "¿de cuál de los dos estamos hablando?".

### Por qué esta distinción importa

Disuelve la tensión entre "conservar lo citable" y "limpiar productos viejos":

- El **documento bandera** se conserva permanente e inmutable en `ciep.mx`. Punto. No hay decisión que tomar.
- El **micrositio** es reemplazable. Se puede mantener con un aviso de desactualización, archivar, o dar de baja, sin destruir el valor citable que vive en el documento bandera.

---

## 3. El marco de decisión

*Qué aprendes en esta sección:* las cuatro reglas que determinan el destino de cada elemento del Ecosistema CIEP.

| Elemento | Destino | Razón |
|---|---|---|
| **Documento bandera** (el estudio, análisis o informe del CIEP) | Permanece accesible de forma permanente en `ciep.mx`. Inmutable. | Es el activo citable. Romper su acceso daña la credibilidad institucional del CIEP como think tank. Un artículo que lo cita y encuentra un enlace roto manda la señal de que el CIEP no cuida su producción intelectual. |
| **Micrositio con datos viejos, pero cuyo documento bandera sigue vigente y accesible** | Se mantiene en vivo con un aviso visible en la página de inicio: "Datos de [año]. Este micrositio no se actualiza actualmente." | Bajo costo de mantenimiento. No rompe los enlaces históricos que circulan en redes, prensa y documentos externos. El valor citable está protegido aparte, en el documento bandera. El aviso de desactualización es transparencia institucional, no debilidad. |
| **Micrositio sin documento bandera asociado, o producto técnico descontinuado** | Se da de baja del aire. El código y el contenido se conservan en el repositorio institucional o en Dropbox, según corresponda. | No hay activo citable que proteger. Mantener el producto vivo solo suma deuda operativa sin beneficio institucional. La baja es limpieza, no pérdida. |
| **Cualquier decisión de descontinuar un producto del Ecosistema CIEP** | El investigador principal propone; la dirección del CIEP valida. | Descontinuar un producto no es una decisión técnica de infraestructura. Es una decisión sobre qué representa públicamente el CIEP. Requiere validación institucional explícita. (Ver sección 4.) |

---

## 4. Autoridad de decisión

*Qué aprendes en esta sección:* quién decide qué, y por qué la cadena de autoridad es la que es.

Para **cualquier decisión de descontinuar un producto** del Ecosistema CIEP, el proceso es:

1. El **investigador principal** documenta la propuesta: qué producto, por qué, qué destino propone (baja, archivo, mantener con aviso), y si hay documento bandera asociado vigente.
2. La **dirección del CIEP** revisa y valida antes de que se ejecute cualquier acción.

**Por qué este proceso.** La tentación de tratar la descontinuación como decisión técnica ("ya no lo mantenemos, lo bajamos") es comprensible, pero equivocada. Los productos del CIEP tienen presencia pública: están referenciados en prensa, en notas de política, en presentaciones de terceros, en documentos de otros think tanks. Dar de baja un producto sin validación institucional puede crear inconsistencias públicas que el CIEP no anticipó. La dirección tiene el contexto institucional para evaluar ese riesgo.

La validación técnica (¿existe el documento bandera?, ¿qué enlaces externos apuntan a este producto?) la hace el investigador principal. La validación institucional (¿es prudente para el CIEP?, ¿hay compromisos externos que considerar?) la hace la dirección.

---

## 5. Productos pendientes de clasificar

*Qué encuentras en esta sección:* la lista de productos cuyo destino bajo este marco aún no ha sido determinado, con las razones por las que la clasificación está pendiente.

El marco de decisión está definido. Su aplicación caso por caso requiere dos confirmaciones que aún no se tienen:

1. **Confirmación de qué micrositios tienen documento bandera asociado vigente y accesible en `ciep.mx`.** La mayoría de los micrositios narrativos probablemente tienen uno, pero no está verificado producto por producto.
2. **Validación de la dirección del CIEP** para cualquier descontinuación concreta.

Hasta que ambas confirmaciones existan para cada producto, **ningún destino está pre-decidido aquí**. La siguiente tabla registra los productos que requieren clasificación, con la información disponible:

| Producto | Datos aproximados | Situación conocida |
|---|---|---|
| Las pensiones en México | 2017 | Micrositio activo o archivado; clasificación pendiente |
| Gasto educativo | 2015 | Micrositio activo o archivado; clasificación pendiente |
| Ingresos públicos en México | 2021 | Micrositio activo o archivado; clasificación pendiente |
| La Vacuna Contra la Desigualdad | 2021 | Micrositio activo o archivado; clasificación pendiente |
| Energía y Finanzas Públicas | 2023 | Micrositio activo o archivado; clasificación pendiente |
| Desarrollo Sostenible | 2023 | Micrositio activo o archivado; clasificación pendiente |
| Aportación fiscal PEMEX | — | Clasificación pendiente |
| Simulador Singapur | — | Clasificación pendiente |
| Tu dinero tu gobierno | — | Clasificación pendiente |
| ITED | — | Producto mencionado en sesión como descontinuado; requiere validación de dirección para ejecutar la baja formal |
| Comunidad CIEP | — | Producto mencionado en sesión como descontinuado; requiere validación de dirección para ejecutar la baja formal |

**Nota sobre ITED y Comunidad CIEP.** Ambos fueron mencionados en la sesión de trabajo donde se construyó este marco como ejemplos del caso "micrositio sin documento bandera asociado o producto técnico descontinuado". Sin embargo, la baja formal de cualquier producto —aunque técnicamente ya no esté activo— requiere la validación de dirección del CIEP establecida en la sección 4. El criterio técnico ya existe; la validación institucional está pendiente.

**Esta sección es negative documentation** — documenta explícitamente lo que no se sabe y lo que no se ha decidido. Es trabajo pendiente, no omisión.

---

## 6. Estado del documento

- **Versión:** v1.0
- **Naturaleza:** marco de decisión, punto de partida. NO es política ratificada.
- **Pendiente:** validación de dirección del CIEP antes de que la autoridad de decisión definida en la sección 4 se ejerza en cualquier caso concreto.
- **Próximos pasos:** (1) verificar qué micrositios de la lista de la sección 5 tienen documento bandera asociado vigente en `ciep.mx`; (2) presentar el marco a la dirección del CIEP para validación; (3) aplicar el marco producto por producto con la autorización correspondiente.

---

## 7. Bitácora de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| v1.0 | 2026-05-15 | Creación del documento. Marco de cuatro reglas; distinción documento bandera vs. micrositio; autoridad de decisión; once productos listados como pendientes de clasificar. |
