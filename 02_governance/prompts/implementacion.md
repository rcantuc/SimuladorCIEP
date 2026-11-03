# Sesión <id> — <tema>

**Punto de partida:** `master` = `<hash corto>` (<versión>, <estado de producción>). Rama `<sesion/… | fix/… | datos/…>`, un PR, checks de `gates-sin-stata` verdes. **Un agente por repo.** Insumos: <memos firmados, adjuntos; el que manda donde difieran>. Toda cifra que cites sale del repo o de la corrida de la sesión.

**Regla de números (elige una y borra la otra):**
- *No mueve números.* Al cerrar, `output.txt`, los 10 sankeys y las 32 entidades son **byte-idénticos** al baseline (`gate-numeros` VERDE contra `-datos/users/ricardo`). Todo parámetro nuevo nace con default = comportamiento actual. Si algo mueve un número, lo reviertes y lo reportas: no se negocia.
- *Mueve números.* `baseline` = `<vX.Y.Z>` en `manifest.json` y `manifest-datos.json`; `gate-numeros` **ROJO esperado**: adjunta su salida con la tabla de Δ por llave y marca toda llave que se mueva sin que <la firma o el memo> lo explique.

## Paso 0 — <verificación previa, si la hay>

<Lo que se comprueba antes de tocar código, y qué hace la sesión si sale distinto: parar y reportar.>

## Entregables

<<CONTENIDO>>

<Por cada entregable: archivos que toca, parámetros (nombre ∈ {valores}, default, FLAG en el header del módulo), y el gate que lo prueba: tolerancia, número esperado, exit code.>

## Reglas de código

- Todo número nace en Stata (`principio-stata-produce-los-numeros.md`): ni Python ni PHP calculan lo que se publica.
- Tocar `output.do` exige `test-web-batch.sh` N/N antes de cerrar la rama (runbook §14.1, lección 7). Tocar un texto de `manifest.json` o un lector `.ado` de archivos externos exige `Precache` o `test-precache-manifest.sh` con Stata.
- Un commit por punto, con mensajes `tipo(<id>/<punto>): …`.
- Si es un hotfix o un PR de datos que se publica, el **release commit va en el PR** (CHANGELOG `[vX.Y.Z]`, manifest `version`/`release_tag`/`release_url_prefix`, `publicar.sh --citation`): el hash que se fusiona es el que se tagea (runbook §14.1, lección 8).

## Lo que NO entra

<Lista explícita, con la sesión a la que pertenece cada cosa.>

## Corrida (una sola, completa, al final, anunciada)

Avisa antes de lanzarla. `bash 05_scripts/correr-sim.sh <tu worktree> <diag>/<n>-sim-completo` en un worktree desechable con `raw/` y `master/` de `-datos` (memoria `corridas-worktree-desechable`; nunca en `-datos`); después `test-web-batch.sh --root <worktree>` y, si la sesión toca entidades, `contrato-32.sh --evidencia <diag>/c32 --refs <diag>/<n>-sim-completo`. Corridas cortas de una rama alterna (`global hasta`) solo si un entregable lo pide, y nunca en paralelo con la completa.

## Evidencia

`~/CIEP_Simuladores/diag-<tema>-<AAAA-MM-DD>/`: `commit.txt`, `wrap.log`, `gate-numeros.txt`, `test-web-batch.md`, `contrato-32.md`, los scripts de la sesión y `pr-body.md`. El worktree se borra al cerrar (`git worktree remove --force`); se conserva la carpeta diag.

## CHANGELOG / README

`## [Unreleased]` con lo de esta sesión (o `[vX.Y.Z]` si el PR lleva release commit). Sin bump de manifest salvo release commit. Runbook y README: en el mismo commit que el cambio que los invalida.

## Reporte final

- PR, hash y checks del commit final; ruta de la evidencia.
- `gate-numeros` (VERDE, o ROJO con la tabla de Δ), `test-web-batch` N/N y `contrato-32` si corrió.
- Por entregable: qué quedó y qué quedó «(no en repo)».
- Hallazgos laterales con magnitud: Δ, sha, conteos.
- Si algo rojo te detuvo, el reporte abre con eso.
- **Lista cerrada de lo que decide Ricardo**, una por renglón, antes del merge o del ritual.
