# Verificación de estado del repositorio — previa a la Entrega 3

**Fecha:** 2026-08-01
**Alcance:** solo lectura. Sin commits, sin cambios a `.gitignore`, sin des-trackear nada.
**Pregunta central (A):** ¿la Entrega 2 se hizo sobre una copia atrasada?

---

# A · Estado del clon

## A.1 Dónde está parado el árbol de trabajo

| Verificación | Resultado |
|---|---|
| Rama actual | `master` |
| Último commit | `dc12cee` 2026-07-19 — "docs(governance): runbook de deploys" |
| `git describe --tags` | **`v8.2.0` exacto** (el tag apunta al HEAD) |
| `manifest.json` | `version: v8.2.0`, `release_tag: v8.2.0`, `data_updated: 2026-07-19` |
| ¿Coincide con v8.2.0? | **Sí, en los tres registros** (HEAD, tag, manifest) |
| ¿Detrás del remoto? | **No.** Tras `git fetch origin`: `master...origin/master = 0 / 0` — ni un commit de diferencia en ninguna dirección |
| Ramas con trabajo no integrado | **Ninguna.** Solo existen `master` y `origin/master` (+ `origin/HEAD`). Sin stashes. Las únicas modificaciones locales son las tres de la Entrega 1.5, aún sin commitear |

**Conclusión A.1: el clon está al día.** El análisis de la Entrega 2 se hizo sobre v8.2.0 = `origin/master`, la versión vigente. (Nota: la Entrega 1 reportó desde el inicio "último tag `v8.2.0`"; en ningún entregable se afirmó v8.1.0.)

## A.2 Reconciliación del hallazgo de `PEF.ado`

Verificado contra el código vigente y contra **toda la historia de todas las ramas**:

| Verificación | Resultado |
|---|---|
| `PEF.ado` (working tree) invoca `escalar` | **0 veces** (case-insensitive) |
| `PEF.ado` en `HEAD` (v8.2.0) | **0 veces** |
| `git diff HEAD -- PEF.ado` | vacío (la copia local = la commiteada) |
| ¿Algún commit de alguna rama/tag tocó `escalar` en PEF.ado? (`git log --all -S"escalar" -- PEF.ado`) | **Ninguno, nunca** |
| Último commit que tocó PEF.ado | `ca03041` (v8.1.0) — "reclasificación CONAC + catálogo estable", sin escalares |
| ¿Escalares de gasto neto/programable/anexos/ramo en otro módulo? | **No** — grep de registros `escalar` con `prog|neto|ramo|anexo|federali` en todos los `.ado`/`.do`: 0 |

**El hallazgo NO fue producto de una copia atrasada.** En v8.2.0 —y en toda la historia publicada del repo— `PEF.ado` no registra escalares.

**Reconciliación con lo que recuerda el investigador principal.** Dos hipótesis compatibles con la evidencia, en orden de probabilidad:

1. **La migración que ya se hizo es la de `GastoPC.ado`**, no la de PEF.ado. `GastoPC.ado` consume `master/PEF.dta` (el producto de PEF.ado) y registra **128 escalares de gasto** (funcional: salud, educación, pensiones, energía, federalizado, inversión, cuidados — montos, PIB, PC, Pob). Además fue justo el módulo protagonista de v8.2.0 (CHANGELOG: harness, conteos de población `GASTOSPOB`, PC de salud por personas). Es decir: **el gasto funcional SÍ está bajo contrato**; lo que no tiene productor de escalares es la capa PEF no-funcional (neto/programable/no programable, variaciones vs aprobado, anexos transversales, programas presupuestarios individuales, Ramo 33 por fondo/entidad).
2. La migración de PEF.ado existe en otro clon y no se ha pusheado. Desde este repo no es verificable; si es el caso, hay que pushearla antes de la Entrega 3.

## A.3 Alcance del daño al análisis — lo que más importa

**El clon estaba al día, así que ninguna conclusión de la Entrega 2 proviene de código atrasado.** Revisión pieza por pieza:

| Pieza de la Entrega 2 | ¿Queda en duda? | Detalle |
|---|---|---|
| **Censo de literales 2026 (2.5) y los tres números (42/34/13)** | **No.** | La clasificación ⚙ de programas/anexos/neto-programable es correcta: no hay productor de esos escalares en ningún módulo (verificado de nuevo hoy). Si la hipótesis 2 de A.2 resultara cierta (migración sin push), bajaría el bloque ⚙ a favor de ✔ — mejoraría el calendario, no lo empeoraría |
| **Enunciado del cuello de botella #2 (2.3)** | **Matiz, sí.** | Decía "PEF.ado registra 0 escalares → sin él no hay capítulo de gasto bajo contrato". La primera mitad es exacta; la segunda es demasiado fuerte: el gasto **funcional** ya está bajo contrato vía GastoPC.ado. Reformulación correcta: *"la capa PEF no-funcional (neto/programable, variaciones, anexos, PPs, Ramo 33) no tiene productor de escalares; el gasto funcional ya lo tiene en GastoPC"*. El esfuerzo estimado (alto) y el calendario no cambian, porque los grupos ⚙ del censo son exactamente esa capa |
| Conteo de línea base (228) y catálogo (701 registrados) | No | Extraídos de v8.2.0 |
| Cobertura de las tres series (SHRFSP 1990–2026, etc.) | No | Leídas de `master/*.dta` regenerados el 2026-07-18/19 con v8.2.0 |
| Caso 2021 (2.4) | No | Evidencia documental + historia git, independiente de la versión del motor |
| 2.6 / 2.7 / 2.8 | No | Análisis de web y sitios, sin dependencia de PEF |

**Qué hay que rehacer: nada. Qué hay que corregir: una oración** (el enunciado del punto #2 de la tabla 2.3 del plan, en el sentido de arriba). Queda pendiente de la autorización de commits; no la he tocado en esta pasada.

**Acción sugerida antes de la Entrega 3:** confirmar con una palabra si la migración recordada es la de GastoPC (hipótesis 1) o si existe un clon con PEF.ado migrado sin push (hipótesis 2). Si es la 2, pushear y re-correr solo la sección 2.5 sobre esa versión.

---

# B · Auditoría de lo que está en git

## B.1 Inventario de lo trackeado

**131 archivos, 19.1 MB.** El repo versiona código y governance, casi sin excepción.

**Por extensión:** do 31 · ado 27 · md 20 · scheme 12 · sthlp 11 · pkg 8 · sh 7 · png 4 · gif 2 · txt 1 · toml 1 · stpr 1 · json 1 · (resto: config puntual).

**Por carpeta de primer nivel:** 01_modulos 33 · 03_help 23 · 05_scripts 17 · 02_governance 15 · raíz ~42 (los `.ado` del motor, `SIM.do`, `profile.do`, schemes, plantillas) · 04_simuladorfiscal.ciep.mx 1 (`health.php`).

**Los 20 trackeados más pesados:**

| KB | Archivo |
|---:|---|
| 11,529 | `03_help/images/Video2.gif` |
| 4,915 | `03_help/images/Video3.gif` |
| 633 | `03_help/images/Ventana de Resultados.png` |
| 254 | `02_governance/arquitectura-y-bitacoras.md` |
| 186 | `03_help/images/Paso1.png` |
| 115 | `01_modulos/Households.do` |
| 107 | `SCN.ado` |
| 97 | `03_help/images/Paso2.png` |
| 91 | `03_help/images/Paso3.png` |
| 82 | `01_modulos/legacy/coneval.do` |
| 55 | `GastoPC.ado` |
| 54 | `SHRFSP.ado` |
| 49 | `05_scripts/publicar-vps.sh` |
| 48 | `01_modulos/legacy/Expenditure_PTLAC.do` |
| 47 | `PEF.ado` |
| 46 | `01_modulos/Expenditure.do` |
| 45 | `02_governance/versionado-y-git.md` |
| 43 | `02_governance/politicas-institucionales.md` |
| 41 | `02_governance/historico/fase-0-reconocimiento.md` |
| 38 | `PIBDeflactor.ado` |

## B.2 Lo que no debería estar

La higiene es notablemente buena — la purga de binarios del rewrite pre-v7/v8 funcionó. Solo hay un candidato real:

| Ruta | Peso | Tipo | ¿Dejar de trackear? |
|---|---:|---|---|
| `03_help/images/Video2.gif` + `Video3.gif` | 16.4 MB (86% del peso del repo) | Binario pesado de documentación (videos de ayuda como GIF) | **Candidato, no urgente.** Opciones: (a) moverlos al data sidecar de GitHub Releases como los assets de `raw/` y referenciarlos; (b) recomprimir a mp4/webp (una fracción del peso); (c) dejarlos — 16 MB no rompe nada hoy. Decisión de estilo, no de riesgo |
| `03_help/images/*.png` (4) | ~1 MB | Capturas de documentación | Se quedan: documentación legítima, peso razonable |

**No hay** logs, temporales de LaTeX, compilados, datos crudos ni copias duplicadas trackeadas. `simulador.stpr` está trackeado por decisión institucional documentada (2026-07-04, en el propio `.gitignore`). Los `.pkg`/`.toc` de `05_scripts/` son fuente del endpoint Stata, no artefactos.

## B.3 Páginas y contenido web — verificado con `git check-ignore -v`

Consistente con lo que indica el investigador principal (nada de esa carpeta corre en producción desde ahí; localhost + deploy por script):

**Trackeado (1 archivo):**
- `04_simuladorfiscal.ciep.mx/health.php` — excepción deliberada (`!**/04_simuladorfiscal.ciep.mx/health.php`), infraestructura del pipeline de deploy.

**Ignorado (verificado, regla exacta):**

| Ruta | Regla que la atrapa |
|---|---|
| `04_1_paqueteeconomico.ciep.mx/**` (incl. `6yt5ppa3hb/`, `app/*.apk`, `wp-config.php`) | `.gitignore:153` → `04_1_paqueteeconomico.ciep.mx/` |
| `04_2_documentos_latex/**` (incl. "Paquete Económico 2027") | `.gitignore:154` → `04_2_documentos_latex/` |
| `04_simuladorfiscal.ciep.mx/**` (todo salvo health.php) | `.gitignore:164` → `**/04_simuladorfiscal.ciep.mx/**` |
| `06_libro/**` (incl. `public_html/`, `maindoc.tex`) | `.gitignore:166` → `06_libro/` |

⚠️ **Las reglas de las líneas 153–154 son las de la Entrega 1.5 y siguen SIN commitear** (`.gitignore` aparece como ` M `). La protección es real en esta máquina pero no viaja: otro clon del repo NO la tiene. Es el argumento más fuerte para autorizar ya el commit de la 1.5.

**Sin trackear y sin ignorar (el estado peligroso):** hoy solo quedan los 4 documentos de governance previos y los 3 entregables de este proyecto (`reporte-inventario…`, `plan-integracion…`, y este archivo) — **ninguno es contenido web ni contiene secretos**; todos son candidatos a commit, no a ignore.

## B.4 Lo ignorado que quizá debería versionarse

El criterio: **sitio como fuente** (código que alguien edita y despliega) versus **sitio como instalación** (BD, uploads, credenciales, caches). Hoy el `.gitignore` trata tres cosas muy distintas con la misma brocha:

| Contenido ignorado | Naturaleza | Recomendación |
|---|---|---|
| `04_simuladorfiscal.ciep.mx/` — `index.php`, `index-en.php`, `js/stataCalcula*.js`, `calculaStata.php`, `css/`, `jsonSankey*.php` | **FUENTE.** Es el código del sitio que `publicar-vps.sh` propaga al VPS. Hoy el código desplegado no tiene historial: un bug introducido localmente no es diffeable ni reversible por git (el rollback depende de tars `_backups/`) | **Versionar la fuente** (PHP/JS/CSS), manteniendo ignorados `ssl/`, `logs/`, `*.log`, `images/` pesadas si las hay. Es el candidato más claro de todo el análisis — y la corrección del §2.7 (etiquetas) lo necesita para hacerse con PR auditable |
| `06_libro/` — `maindoc.tex`, capítulos `0_Prologo`…`4_Balance`, `pandoc_export.py` | **FUENTE.** Es el documento bandera institucional; hoy su LaTeX no tiene historial de cambios | **Versionar el `.tex` + scripts**, manteniendo ignorados `images/` (628 PNG generados + statalatex — se regeneran), `Back up/`, `public_html/` (instalación), PDFs compilados y auxiliares |
| `06_libro/images/statalatex_*.tex` | Generado (salida del contrato) | Seguir sin versionar: se regenera con la corrida; su procedencia es el log |
| `04_1_paqueteeconomico.ciep.mx/` | **INSTALACIÓN** (WordPress: core, plugins, uploads, credenciales) | Seguir ignorada completa. La "fuente" de ese sitio vive en la BD (Elementor); no hay nada versionable ahí. Los nodos 2027 nacerán como fuente en el repo (plan §2.6-A), no dentro del WP |
| `04_2_documentos_latex/` | **ARCHIVO histórico** (2013–2026) + futura fuente 2027 | El histórico sigue ignorado (8.5 GB, inmutable). El documento 2027, si se quiere bajo contrato, debería nacer como fuente versionada — decisión a tomar en la Entrega 3/ciclo 2027, no ahora |
| `users/`, `master/`, `raw/`, `graphs/` | Datos y salidas de corrida | Correctamente ignorados (raw/ tiene su catálogo con SHA-256 en `manifest.json`) |

## B.5 Coherencia del `.gitignore`

**Reglas que no atrapan nada hoy** (candidatas a limpiar, todas de costo cero):
- `ado/personal/`, `ado/plus/` — no existe `ado/` en el árbol (los ado del perfil viven fuera del repo). Inofensivas como seguro.
- `!.env.example` — no existe ningún `.env.example`. Inofensiva.
- `Thumbs.db`, `ehthumbs.db`, `Desktop.ini`, `*~`, `*.stsem`, `hs_err_pid*.log` — higiene multiplataforma sin coincidencias actuales; convención estándar, se quedan.
- El assert del verificador para `"Stata net/SIM.ado"` referencia una carpeta que ya no existe (legacy eliminada en `2daadf8`) — el assert sigue pasando por ser hipotético, pero es candidato a actualizarse cuando se toque el verificador.

**Solapamientos / duplicados:**
- `06_libro/` **y** `**/06_libro/**` (líneas contiguas): duplicado real — la segunda es redundante con la primera para este repo (y viceversa). Una sola basta; consolidar cuando se edite.
- `.env` + `**/.env` y `wp-config.php` + `**/wp-config.php`: redundancia **deliberada y documentada** en la Entrega 1.5 (un patrón sin slash ya matchea a cualquier profundidad; el `**/` se dejó como declaración de intención). No es contradicción.
- `**/graphs/**` solapa con `**/users/**` para `users/*/graphs/`; sigue siendo útil para un `graphs/` extraviado en otra ruta.
- No se encontraron reglas que se contradigan (negaciones rotas): la única negación activa (`!health.php`) funciona, verificado.

**Rutas que deberían ignorarse y no lo están:** ninguna encontrada. Los 7 untracked actuales son documentos por commitear, no material para ignore.

---

## Síntesis

1. **El clon está al día (v8.2.0 = origin/master).** El hallazgo de PEF.ado es correcto sobre la versión vigente y toda la historia publicada; la migración recordada es con toda probabilidad la de **GastoPC.ado** (gasto funcional bajo contrato desde hace tiempo, reforzado en v8.2.0), o bien vive en un clon sin pushear.
2. **La Entrega 2 se usa como está**, con una sola corrección de redacción (cuello #2 de la tabla 2.3: es la capa PEF no-funcional la que no tiene productor, no "el capítulo de gasto" completo). Los tres números del censo (42/34/13) no cambian.
3. **El repo trackeado está limpio** (131 archivos, 19 MB); el único peso injustificado son dos GIFs de ayuda (16 MB).
4. **Las protecciones de la Entrega 1.5 siguen sin commitear** — viajan solo en esta máquina. Es el pendiente de mayor riesgo/beneficio inmediato.
5. **Dos fuentes viven fuera de git y no deberían**: el código del sitio del Simulador (se despliega sin historial) y el LaTeX del libro. Propuesta para cuando se autorice tocar `.gitignore`.

---

*Fin de la verificación. Nada commiteado, nada des-trackeado, `.gitignore` intacto en esta pasada.*
