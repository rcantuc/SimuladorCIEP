# Análisis: gate semántico para el pipeline de publicación

**Estado:** propuesta para revisión del investigador principal — NO implementado.
**Fecha:** 2026-07-04.
**Origen:** los 3 defectos destapados por la prueba de humo del 4 de julio de 2026 (v8.0.2, v8.0.3, v8.0.4).

Este documento analiza cómo podría el pipeline de publicación (`05_scripts/publicar.sh` + `05_scripts/publicar-endpoint.sh`) validar el **contenido** de lo que publica, no solo su **estructura**. No propone código; propone opciones con costos y modos de falla para que la decisión sea explícita.

---

## 1. El problema, con los 3 casos concretos

El 4 de julio de 2026, una prueba de humo manual (`net from https://ciep.mx/simuladorfiscal/` + `net describe <PKG>` desde un Stata externo al CIEP) destapó en un día tres defectos que existían silenciosamente desde v8.0 (18 de junio) — es decir, sobrevivieron a **tres publicaciones** sin que ningún gate los detectara:

| # | Defecto | Desde cuándo | Quién lo corrigió |
|---|---|---|---|
| 1 | Los 11 `.sthlp` del canon no declaraban autoría ni correo institucional | v8.0 | v8.0.2 (`4d22efa`) |
| 2 | `AccesoBIE` anunciado en el `stata.toc` del endpoint, pero `AccesoBIE.pkg` nunca existió en el filesystem — `net describe AccesoBIE` fallaba con 404 para cualquier usuario externo | v8.0 | v8.0.3 (`8f45013`) |
| 3 | El link para obtener el token BIE/INEGI apuntaba a una página obsoleta (`api_biinegi.html` en vez de `app/api/denue/v1/tokenVerify.aspx`) | anterior a v8.0 | v8.0.4 (`b712d4b`) |

Los tres comparten una raíz: son defectos de **contenido semántico** (lo que los archivos dicen), no de **estructura** (que los archivos existan y las versiones cuadren). El pipeline actual solo valida lo segundo.

## 2. Qué valida hoy el pipeline — y qué no

### 2.1 Lo que SÍ valida

**`publicar.sh --check` (3 gates):**

| Gate | Valida |
|---|---|
| Gate 1 | `02_governance/CHANGELOG.md` tiene entrada `## [vX.Y] — YYYY-MM-DD` para la versión |
| Gate 2 | El tag Git existe, es anotado y tiene mensaje |
| Gate 3 | `05_scripts/manifest.json` (data sidecar) sincronizado con la versión |

**`publicar.sh` (flujo completo, además de los gates):** working tree limpio y alineado con `origin/master`; assets del data sidecar existen localmente antes de subir; verificación SHA-256 post-Release.

**`publicar-endpoint.sh` (Fase 1):** parseo del `manifest-endpoint.toml`; **existencia en filesystem de cada archivo declarado** en `ado_files`, `sthlp_files` y `pkg_files`; conectividad SSH; conteo de archivos remotos post-deploy; `curl` al `stata.toc` remoto verificando que contiene la versión.

### 2.2 Lo que NO valida (y por eso pasaron los 3 defectos)

- **Consistencia cruzada dentro del `manifest-endpoint.toml`.** El defecto #2 NO fue "archivo declarado que no existe" (eso sí lo atrapa la Fase 1). Fue lo contrario: `AccesoBIE` estaba en `[toc.packages]` — y su `.ado`/`.sthlp` en las listas — pero su `.pkg` **no estaba declarado** en `pkg_files`. El check de existencia pasó limpio, el `stata.toc` generado anunció `p AccesoBIE`, y el `.pkg` nunca llegó al servidor. Nadie compara las secciones del manifest entre sí.
- **Contenido de los `.pkg`.** Cada `.pkg` lista con líneas `F` los archivos que `net install` descargará. Nadie verifica que esas líneas apunten a archivos que el manifest realmente publica.
- **Metadata de los `.sthlp`.** Nadie verifica que cada help tenga autoría, correo, título (defecto #1).
- **Vigencia de URLs.** Nadie verifica que los enlaces `{browse "..."}` de los `.sthlp` respondan (defecto #3).
- **La experiencia real del usuario externo.** Nadie ejecuta `net from` + `net describe` contra el endpoint publicado; solo un `curl` superficial al `stata.toc`.

En una frase: `--check` responde "¿está todo en su lugar?", pero nadie responde "¿lo que está en su lugar dice lo correcto?".

## 3. Gates semánticos candidatos

Cada candidato se evalúa en: qué atrapa, costo de implementación, costo de ejecución, modo de falla y compatibilidad con el pipeline actual. Todos se conciben como funciones `gate_*` adicionales dentro de `publicar.sh`, corriendo en `--check` y antes de acciones con efectos — el mismo patrón de los gates 1–3.

### Gate α — Consistencia interna del manifest y de los `.pkg`

**Qué hace.** Tres verificaciones cruzadas, todas locales:
1. Cada paquete en `[toc.packages]` tiene su `.pkg` correspondiente declarado en `pkg_files` (y viceversa).
2. Cada línea `F` de cada `.pkg` apunta a un archivo que existe en el repo y que está declarado en `ado_files`/`sthlp_files`.
3. Cada `.ado`/`.sthlp` declarado aparece en algún `.pkg` (nada publicado queda inalcanzable para `net install`).

**Qué atrapa.** El defecto #2 exactamente (verificación 1), más su familia completa: `.pkg` que referencia archivos renombrados (riesgo real tras la reorganización v1.12), archivos publicados que ningún paquete instala.

| Dimensión | Evaluación |
|---|---|
| Costo de implementación | Bajo: ~60–80 líneas de bash+python3 (el pipeline ya parsea el TOML con `tomllib`; los `.pkg` son texto plano con prefijos `F`/`d`/`v`). Cero dependencias nuevas. |
| Costo de ejecución | Despreciable (<1 segundo, sin red). |
| Falso positivo | Casi imposible: las tres verificaciones son igualdades de conjuntos sobre archivos locales. |
| Falso negativo | No atrapa defectos de contenido (autoría, URLs). |
| Compatibilidad | Total: un `gate_manifest_consistency` más en la secuencia de `--check`. |

### Gate β — Metadata mínima de los `.sthlp`

**Qué hace.** Para cada `.sthlp` declarado en `sthlp_files`, verifica con regex la presencia de: bloque de autoría con el nombre del investigador principal, correo institucional (`@ciep.mx`), directiva `{smcl}` inicial, y sección de título. La lista de campos obligatorios vive en una sección nueva del `manifest-endpoint.toml` (p. ej. `[quality.sthlp]`) para que sea declarativa y expandible sin tocar el script.

**Qué atrapa.** El defecto #1 exactamente. Expandible: defaults documentados, secciones obligatorias, sintaxis SMCL rota (llaves sin cerrar).

| Dimensión | Evaluación |
|---|---|
| Costo de implementación | Medio: ~80–120 líneas. Regex sobre SMCL, no un parser completo. Cero dependencias nuevas. |
| Costo de ejecución | Despreciable (<1 segundo, sin red). |
| Falso positivo | Posible si un `.sthlp` legítimo formatea la autoría distinto al patrón esperado. Mitigación: el patrón se calibra contra los 11 `.sthlp` ya consistentes tras v8.0.2 — son el gold standard. |
| Falso negativo | Verifica presencia, no corrección (un correo con typo pasa). |
| Compatibilidad | Total: mismo patrón `gate_*`. |

### Gate γ — Vigencia de URLs en los `.sthlp`

**Qué hace.** Extrae todos los `{browse "URL"}` de los `.sthlp` del canon y hace `curl -sI --max-time 10` a cada URL única, aceptando 200/301/302.

**Qué atrapa.** El defecto #3 — con matiz importante: lo atrapa solo si la URL obsoleta devuelve error HTTP. Si el sitio viejo del INEGI respondía 200 con contenido obsoleto (frecuente en portales gubernamentales que redirigen a home), este gate **no lo habría atrapado**.

| Dimensión | Evaluación |
|---|---|
| Costo de implementación | Medio: ~60 líneas (extracción regex + loop de curl con timeout). Cero dependencias nuevas, pero sí lógica de reintentos. |
| Costo de ejecución | Alto relativo: requiere red; ~10–30 segundos con timeouts; depende de servidores de terceros (INEGI, SHCP). |
| Falso positivo | **Probable**: URLs gubernamentales temporalmente caídas, bloqueos por User-Agent, mantenimientos nocturnos. Un falso positivo en un gate bloqueante detiene una publicación legítima. |
| Falso negativo | Probable en el caso que motivó el gate (páginas obsoletas que responden 200). |
| Compatibilidad | Compatible, pero por su fragilidad debería ser **advertencia (WARN), no bloqueo** — lo que reduce su valor como gate. |

### Gate δ — Prueba de humo automatizada post-publicación

**Qué hace.** Después del rsync, ejecuta `stata -b` (batch) con un do-file que corre `net from <ENDPOINT_URL>` + `net describe <PKG>` para cada paquete, y verifica en el log la ausencia de errores.

**Qué atrapa.** Los 3 defectos de hoy... con asterisco: #2 completo (el 404 de `net describe`); #1 y #3 solo si el do-file además inspecciona el contenido descargado — con lo cual reimplementa a β y γ por la vía cara.

| Dimensión | Evaluación |
|---|---|
| Costo de implementación | Alto: requiere Stata invocable desde el shell del publicador (licencia, path), parseo de logs de Stata en bash, y decisión sobre qué hacer si falla *después* de que el servidor ya cambió (¿rollback con el backup de Fase 3?). |
| Costo de ejecución | Medio: ~30–60 segundos, requiere red y Stata local. |
| Falso positivo | Medio: cache/CDN puede servir contenido viejo minutos después del rsync (el pipeline ya documenta ese fenómeno en su Fase 5). |
| Falso negativo | Bajo para defectos de disponibilidad; alto para defectos de contenido si solo corre `net describe`. |
| Compatibilidad | Media: es un gate *post*-efectos, distinto en naturaleza a los gates 1–3 (que corren antes de tocar nada). Rompe la semántica actual de "gate = aborta antes de efectos". |

### Gate ε — Prueba de humo HTTP sin Stata (variante barata de δ)

**Qué hace.** Post-rsync, replica con `curl` lo que hace `net from`/`net describe` por dentro (son solo GETs HTTP): descarga `stata.toc`, extrae cada `p <PKG>`, descarga cada `<PKG>.pkg`, y verifica que cada archivo listado en líneas `F` responde 200 en el endpoint.

**Qué atrapa.** El defecto #2 completo (el `stata.toc` anunciaba un `.pkg` inexistente) y toda la clase "el endpoint anuncia algo que no sirve" — sin necesitar Stata, licencias ni parseo de logs.

| Dimensión | Evaluación |
|---|---|
| Costo de implementación | Bajo-medio: ~50–70 líneas de bash con `curl` (el pipeline ya usa `curl` en su Fase 5; esto la profundiza). |
| Costo de ejecución | Bajo: ~5–15 segundos, solo HEADs/GETs pequeños al propio servidor del CIEP. |
| Falso positivo | Bajo: mismo riesgo de cache/CDN que la Fase 5 actual; mitigable con reintento tras espera. |
| Falso negativo | No valida contenido de los archivos (autoría, URLs), solo disponibilidad y coherencia toc↔pkg↔archivos. |
| Compatibilidad | Alta: es extensión natural de la Fase 5 de `publicar-endpoint.sh`, que ya hace la versión superficial de esto. |

## 4. Recomendación

**Primera ola (viable ya): α + β como gates bloqueantes en `--check`.** Son locales, deterministas, sin red, sin dependencias nuevas, y entre los dos habrían atrapado los defectos #1 y #2 *antes* de publicar. El costo conjunto estimado es de ~150–200 líneas siguiendo el patrón `gate_*` existente. α es el más urgente: la reorganización v1.12 demostró que los renames masivos son parte de la vida del repo, y α es la red que detecta un `.pkg` desalineado tras el siguiente rename.

**Segunda ola: ε como profundización de la Fase 5.** Convierte la verificación post-deploy superficial (un `curl` al `stata.toc`) en una verificación de la cadena completa toc → pkg → archivos, con costo bajo. No bloquea la publicación (ya ocurrió), pero convierte el "verificar manualmente en unos minutos" actual en un reporte automático.

**No recomendado por ahora: γ como gate bloqueante y δ.** γ tiene la peor relación señal/ruido (falsos positivos probables, falso negativo en el caso que lo motiva); si se quiere, como WARN informativo. δ agrega la dependencia institucional más pesada (Stata en el pipeline) para atrapar casi lo mismo que ε + β combinados.

**Lo que ningún gate sustituye:** el defecto #3 (link obsoleto que quizá respondía 200) es del tipo que solo un humano usando el producto detecta. De ahí la §5.

## 5. Alternativa institucional: la prueba de humo como paso formal del checklist

Independientemente de lo que se automatice, la prueba de humo del 4 de julio demostró un valor que ningún gate replica por completo: un humano siguiendo el camino del usuario externo real. Propuesta mínima, sin código:

1. Agregar a la documentación de publicación (§ correspondiente de `arquitectura-distribucion.md`) un **checklist de prueba de humo post-publicación**: desde un Stata que NO sea el del publicador, correr `net from https://ciep.mx/simuladorfiscal/`, `net describe <PKG>` para al menos 2 paquetes (uno estable + el que cambió en la versión), abrir el help de cada uno y verificar autoría, y hacer clic en los links críticos (token INEGI).
2. Registrar el resultado como una línea en `02_governance/deploys/endpoint-stata.log` (`SMOKE-TEST OK` / `SMOKE-TEST FAIL:<detalle>`), igual que ya se registran deploys y verificaciones de Release.
3. La publicación no se considera cerrada (ni se anuncia al equipo) hasta esa línea.

Costo: cero código, ~5 minutos por publicación. Es el gate humano que hoy funcionó — solo que documentado y obligatorio en vez de fortuito.

---

*Documento de análisis producido para revisión del investigador principal. Ninguna propuesta está implementada; cualquier implementación requiere decisión explícita y su propia entrada en la bitácora de `arquitectura-distribucion.md`.*
