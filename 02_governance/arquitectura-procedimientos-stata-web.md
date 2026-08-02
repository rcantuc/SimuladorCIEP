# Arquitectura global de procedimientos

**De Stata a la página**
Agosto 2026

---

## 1. El principio

**Stata produce todos los números. Nada más los produce.**

La página no calcula. La infografía no calcula. El video no calcula. La hoja de cálculo de nadie calcula. Todos **renderizan** lo que el motor ya produjo, con su tipo, su unidad, su fuente y su log.

Es la extensión natural de la regla que ya existe —*todo lo que alimenta el libro pasa por `escalar`*— a un segundo destino: *todo lo que alimenta la web pasa por `escalar`*.

La consecuencia de no sostener esto es conocida y ya la viviste: cuando aparece una segunda fuente de verdad, funciona bien un tiempo, diverge en silencio, y para cuando alguien nota la diferencia nadie recuerda de dónde salió el número.

---

## 2. La cadena completa

```
Fuentes oficiales
   SHCP, INEGI, CONEVAL, CONAC, IMSS, ISSSTE, CONAPO
        │
        ▼
Importación
   Rutinas de actualización + catálogo de datos asociados con hash
   Punto de control: verificador de deriva, error si el catálogo no cuadra
        │
        ▼
Motor de cálculo — Stata
   Simulador.ado y rutinas asociadas
   Punto de control: prueba dorada contra resultados conocidos
        │
        ▼
Registro escalar
   Valores numéricos con tipo, unidad y metadatos
   Punto de control: línea base de nombres auditados, detección de deriva
        │
        ├──────────────┬──────────────────┐
        ▼              ▼                  ▼
   Exportador      Exportador         Exportador
   LaTeX           web                datos abiertos
   statalatex_*    statajson_*        CSV con diccionario
        │              │                  │
        ▼              ▼                  ▼
   Documento       Sitio de nodos     Portal de datos
   bandera         y calculadoras     y réplica externa
```

**Un registro, varios exportadores.** Esa es la decisión de arquitectura que carga todo el peso. El formato se aplica al exportar, nunca al almacenar —igual que ya funciona hoy con LaTeX.

**Lo que hay que evitar a toda costa:** una tubería paralela para la web. En el momento en que exista una segunda ruta de Stata a la página que no pase por el registro, el sistema tiene dos verdades.

---

## 3. El contrato de exportación web

Espejo exacto del contrato LaTeX que ya opera.

**Nombre propuesto para el comando:** `exportar web <nodo>`
**Archivo producido:** `statajson_<nodo>.json`

Evita deliberadamente el verbo *publicar*, que en el vocabulario CIEP ya significa liberar una versión.

**Contenido mínimo del archivo:**

| Campo | Contenido |
|---|---|
| `nodo` | Identificador del concepto |
| `version_simulador` | Versión que produjo las cifras |
| `corte_datos` | Fecha del catálogo de datos asociados |
| `generado` | Marca de tiempo de la corrida |
| `log` | Ruta del log de la ejecución que produjo esto |
| `valores` | Lista de escalares con nombre, valor, tipo, unidad, año |
| `series` | Series históricas por lente |
| `criterios` | Los siete campos de conciliación |
| `fuentes` | Referencia exacta por valor |

**Cuatro reglas del contrato:**

1. **La web solo lee archivos exportados.** No consulta Stata en vivo, no consulta la base de datos original, no interpola.
2. **Todo archivo declara su procedencia**: versión, corte, log. Sin esos tres campos, no se publica.
3. **El formato se aplica al exportar.** El JSON lleva el valor numérico y su tipo; la presentación decide si se muestra como porcentaje, como pesos o como personas.
4. **Ningún valor se teclea en la web.** Si un número no está en un archivo exportado, no aparece en la página.

---

## 4. Las seis vistas del nodo

Aquí es donde la filosofía del Simulador Fiscal se convierte en producto público. El motor ya sabe hacer estos cálculos; hoy solo alimentan documentos. Cada nodo declara qué vistas soporta y el sitio las renderiza.

| Vista | Qué muestra | Aplica a |
|---|---|---|
| **1 · Magnitud** | Monto y proporción del PIB | Todos |
| **2 · Per cápita** | Por persona, por población objetivo, por edad | Gasto y transferencias |
| **3 · Tasa efectiva** | Lo que se paga de verdad frente a la tasa estatutaria, por decil y tipo de contribuyente | Ingresos |
| **4 · Distribución e incidencia** | Quién paga y quién recibe, por decil, por sexo, por tipo de hogar | Ingresos y gasto |
| **5 · Territorio** | Distribución entre entidades federativas | Gasto federalizado, recaudación local |
| **6 · Proyección** | Trayectoria demográfica, sostenibilidad, valor presente | Pensiones, salud, deuda, educación |

**Ninguna vista aplica a todos los nodos.** Un nodo de deuda no tiene vista de tasa efectiva; uno de IVA no tiene proyección demográfica. La ficha lo declara y el sitio no muestra pestañas vacías.

**Por qué esto es el diferenciador.** Cualquiera puede publicar cuánto se gasta en salud. Muy pocos pueden publicar cuánto se gasta en salud por persona, por decil, por entidad y proyectado a treinta años con la transición demográfica. **Esa capacidad ya existe en el motor.** Hoy termina su vida en documentos que lee poca gente. Exponerla como vista pública por nodo es el mayor apalancamiento disponible: no hay que construir capacidad, hay que conectar la que ya está.

Y las vistas 3, 4 y 6 son las que sostienen el argumento democrático completo. La incidencia responde *a quién le toca*, que es la pregunta política real detrás de cualquier decisión fiscal. La proyección responde *quién lo paga después*, que es la pregunta intergeneracional que la discusión pública nunca hace.

---

## 5. Puntos de control

Cada eslabón tiene una verificación que detiene la cadena si falla:

| Eslabón | Verificación | Qué pasa si falla |
|---|---|---|
| Importación | Catálogo de datos con hash | Error, no se procesa |
| Cálculo | Prueba dorada contra resultados conocidos | Error, no se registra |
| Registro | Línea base de nombres auditados | Alerta de deriva |
| Exportación | Campos obligatorios de procedencia completos | No se genera archivo |
| Publicación web | Todo valor en pantalla tiene origen en archivo exportado | No se publica |

Ninguna es nueva en concepto: son la misma disciplina que ya opera en el Simulador, extendida al nuevo destino.

---

## 6. El límite: qué corre en Stata y qué no

Conviene decirlo explícito para que nadie lo negocie caso por caso.

**En Stata:** toda producción de cifras. Microdatos, ponderadores, incidencia, tasas efectivas, proyecciones, series, simulaciones.

**Fuera de Stata:** servir páginas, renderizar gráficas interactivas, atender usuarios concurrentes, generar HTML, manejar la calculadora del deflactor en el navegador.

Esto no es una concesión ni una etapa de transición. **Es el límite correcto**, y coincide con lo que cada herramienta hace bien. Stata es excelente en microdatos con ponderadores y tiene quince años de lógica probada encima; no es un servidor web y no tiene por qué serlo.

---

## 7. La pregunta de R, respondida

Planteas bien la condición: una migración a R tendría que resolver todas las herramientas, filosofías y usos de datos y páginas que ya existen. Esa condición es correcta y hoy no se cumple.

Pero la conclusión útil no es "todavía no". Es esta:

> **El contrato de exportación *es* la estrategia de migración.**

Si todo consumidor —libro, documento, sitio, datos abiertos, terceros— lee artefactos exportados en lugar de tocar Stata directamente, entonces **el lenguaje del motor se vuelve un detalle de implementación.** Un motor en R que produzca `statajson_*` y `statalatex_*` con el mismo contrato es intercambiable sin que ningún consumidor se entere.

Eso convierte una decisión difusa y lejana en una medida concreta y presente:

**¿Cuántos consumidores hoy leen del motor sin pasar por el contrato?**

Cada uno de ellos es una cadena que habría que reescribir en una eventual migración. Cada consumidor que pasa por el contrato tiene costo cero de migración. Reducir ese número es trabajo que paga hoy —elimina fuentes de verdad duplicadas— y paga después, si algún día la migración conviene.

**Recomendación:** no planear la migración. Levantar el inventario de consumidores que hoy no pasan por el contrato y cerrarlos uno por uno. Si en dos años ese número es cero, la decisión sobre R se toma por sus méritos técnicos y no por costo de salida. Si nunca llega a cero, la decisión ya está tomada por default y conviene saberlo.

---

## 8. La ficha del nodo, ampliada

```yaml
nodo: gasto-salud
titulo: Gasto público en salud
rama: gasto
definicion: >
  Recursos públicos destinados a la prestación de servicios de salud...

vistas: [magnitud, per_capita, incidencia, territorio, proyeccion]

criterios:
  cobertura: sector público presupuestario, incluye FASSA
  clasificacion: finalidad 2, función 3 (CONAC)
  momento: aprobado
  deflactor: INPC, base según serie transversal
  denominador: PIB de CGPE del año correspondiente
  fuente: PPEF, anexos, corte declarado en catálogo
  consolidacion: sin netear transferencias entre entes

conciliacion:
  cifra_oficial: referencia exacta al documento y cuadro
  razones: [cobertura, clasificacion]
  dimension: nota sobre la magnitud relativa de la diferencia

disyuntiva: >
  Pregunta de política que este nodo pone sobre la mesa...

acervo: [lista de documentos CIEP asociados, con vigencia]
vecinos: [gasto-federalizado, pensiones, gasto-programable]

procedencia:
  version_simulador: ...
  corte_datos: ...
  log: ...
```

Los campos de `criterios` y `conciliacion` no son documentación: **son datos**, y por eso se pueden auditar, comparar entre nodos y exportar como bien público.

---

## 9. Orden de construcción

1. **Inventario de consumidores** que hoy no pasan por el contrato. Es diagnóstico, no construcción, y ordena todo lo demás.
2. **Comando `exportar web`** para un solo nodo, de punta a punta. Prueba el contrato contra un caso real.
3. **Página de nodo** que renderiza ese archivo y nada más. Si un valor no está en el JSON, no aparece.
4. **Vistas 1 y 2** —magnitud y per cápita— en ese nodo. Son las más simples y prueban el patrón de series.
5. **Vistas 3, 4 y 6** conforme se enciendan nodos que las requieran.
6. **Series transversales** —INPC, deflactor, PIB, población— exportadas una sola vez y consumidas por todo.
7. **Calculadora del deflactor** sobre esas series.

El paso 1 es el único que conviene hacer esta semana. Todo lo demás depende de saber cuántas tuberías paralelas existen hoy.

---

*Documento de trabajo.*
