# Sesión <id> — <tema> (solo lectura: <memo | inventario | diagnóstico>)

**Punto de partida:** `master` = `<hash corto>` (<versión>, <estado de producción: deployment, Release>). Rama `<docs/… | sesion/…>`, un PR, checks de `gates-sin-stata` verdes. **Un agente por repo.** Esta sesión **no modifica ningún `.do`, `.ado` ni número publicado**: `output.txt`, los 10 sankeys y las 32 entidades siguen byte-idénticos. Si algo te obliga a tocar el motor, para y reporta.

<Adjuntos de Ricardo que van al repo tal cual, con su ruta destino; o «sin adjuntos».>

## Entregables

<<CONTENIDO>>

<Por cada entregable: archivo destino, secciones obligatorias, qué tabla lleva una fila por qué, y de dónde sale cada cifra (archivo del repo, memo previo, corrida con su ruta).>

## Reglas del documento

- **Toda cifra sale del repo o de una corrida con evidencia.** Si no está, se marca «(no en repo)» o «(no en <fuente>)» y no se inventa ni se estima.
- **Procedencia:** archivo y rango de líneas de cada afirmación sobre el código.
- **Se propone, no se ejecuta.** Nada de lo que el documento propone (borrar, mover, cambiar un default) se hace en esta sesión: Ricardo decide fila por fila.
- **Contradicciones:** si dos documentos vigentes dicen cosas distintas sobre lo mismo, van en una lista al final, con las dos rutas.

## Lo que NO entra

<Lista explícita: código, parámetros, datos, lo que es de la sesión siguiente y por qué.>

## Corrida

No aplica: sin Stata. <O, si un diagnóstico necesita Stata: una sola corrida, en tu worktree o en `diag-*`, nunca en `-datos`; anunciada antes de lanzarla.>

## Evidencia

`~/CIEP_Simuladores/diag-<tema>-<AAAA-MM-DD>/`: los scripts de diagnóstico, sus salidas y `pr-body.md`.

## CHANGELOG / README

`## [Unreleased]`: una línea por documento nuevo. `02_governance/README.md`: el índice se actualiza en el mismo commit que agrega el documento. Sin bump de manifest: esta sesión no publica.

## Reporte final

- PR, hash y checks del commit final.
- Por entregable: qué quedó y qué quedó «(no en repo)».
- <Las tablas o totales que Ricardo necesita leer sin abrir el PR.>
- **Lista cerrada de lo que decide Ricardo**, una por renglón, antes de la sesión siguiente.
