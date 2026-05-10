# Fase 0.5 — Git Hygiene Audit

**Fecha:** 2026-05-09  
**Commit de referencia:** `2f46d92` (HEAD, `master`)  
**Decisiones tomadas en Fase 0:** confirmadas por Ricardo el 2026-05-09  
**Naturaleza:** diagnóstico técnico + plan secuenciado de fixes. **No ejecuta nada.** Cada acción se construye en un turno posterior.

> Audit dirigido a un lector externo: alguien que se sumará al mantenimiento del repo y necesita entender qué está mal hoy y en qué orden se arregla, antes de tocar el código del Simulador.

---

## 1. Decisiones de Fase 0 que enmarcan este audit

| #   | Decisión                                                                                            | Implicación operativa para Fase 0.5                                                                                                                                                                                                                                                                                                                   |
| -----| -----------------------------------------------------------------------------------------------------| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1   | **Archivar `Stata net/` como distribución histórica v7.** Canal oficial = repo Git.                 | El paquete `Stata net/` deja de mantenerse. Los `.ado` divergentes en su interior son **estado v7 congelado**. Hay que: (a) marcarlo explícitamente como histórico; (b) corregir el README para que no instruya `net install`; (c) decidir si se queda en tronco o se mueve a `legacy/`.                                                              |
| 2   | **Data Sidecar pattern con GitHub Releases** para insumos binarios pesados. **LFS descartado.**     | Los binarios (`raw/*.xlsx`, etc.) salen del Git (vía `git filter-repo`) y se republican como assets del release `v7.0`. El repo contiene un manifiesto (`raw/manifest.json`) con SHA-256 de cada asset y un script de descarga que los baja on-demand. **Detalle conceptual y operativo pendiente** — se documentará junto con `governance/convenciones-git.md` (Acción 8) y/o en su propio archivo cuando manifest, script y release v7.0 existan operativamente. |
| 3   | **Análisis legacy** (`01_modulos/análisis/*` no invocado por `SIM.do`) → mover a rama/tag `legacy`. | Confirmado por `grep_search`: ningún `01_modulos/análisis/*.do` es referenciado desde otro `.do`/`.ado` del repo. Tambien son legacy: `01_modulos/visualizations/Graphs_*.do`, `01_modulos/households/Expenditure_PTLAC.do`, `01_modulos/profiles/PerfilesGasto.do`, y 5 de 6 `01_modulos/visualizations/sankey/*.do` (sólo `SankeySF.do` se invoca). |

---

## 2. Diagnóstico técnico del estado Git actual

### 2.1 Identidad y autoría

**Hallazgo confirmado:** 1,031 / 1,077 commits son de Ricardo bajo **8 identidades distintas** (4 nombres × emails diversos).

Emails detectados en la historia:

```
51425712+JuanPabloSantisteban@users.noreply.github.com
60672234+erikciep@users.noreply.github.com
60672443+18-carlos@users.noreply.github.com
90220294+Jotapelopez3696@users.noreply.github.com
erik.covarru@gmail.com
juanpablo.loprey@gmail.com
lesliebadillo-ciep@users.noreply.github.com
rcantuc@gmail.com
```

Faltan emails de Ricardo bajo varios alias (probablemente también con `noreply.github.com`). El email institucional `ricardocantu@ciep.mx` que aparece en el header del código **no aparece como autor de ningún commit**. Hallazgo subyacente: **la autoría Git y la identidad institucional están desconectadas**.

**Riesgo:** un co-mantenedor que llega a hacer `git blame Households.do` ve 4 nombres distintos para una sola persona y no sabe a quién preguntar. Trazabilidad debilitada.

### 2.2 Ramas, tags, remotes

```
remote: origin → https://github.com/rcantuc/SimuladorCIEP.git
ramas:  master (local)  +  origin/master  +  origin/HEAD
tags:   (ninguno)
hooks:  (ninguno custom; sólo *.sample por defecto)
```

**Implicaciones:**

- El repo es **público en GitHub bajo cuenta personal de Ricardo (`rcantuc`)**, no bajo organización CIEP. Para gobernanza institucional eventualmente conviene migrar a `github.com/CIEPmx/...` o equivalente.
- Sin tags = sin "v7" navegable. La afirmación de versión existe en código (`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:5`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/stata.toc:3`) pero no en historia.
- Sin hooks = sin pre-commit checks. Cualquier commit con basura, parámetros mal o conflict markers entra a `master`.

### 2.3 Working tree y staging actual

```
 M .DS_Store                                                  ← sistema, no debería trackearse
 D "01_modulos/análisis/InformesTrimestrales.do"              ← borrado sin commit
 M simulador.stpr                                             ← Stata project, contenido cambia con cada sesión
?? .windsurfrules                                             ← nuevo (este proyecto de governance)
?? governance/                                                ← nuevo (los artefactos producidos)
```

**Diagnóstico:** el árbol está sucio. Tres distintos tipos de problemas:

1. **Drift accidental (`.DS_Store`):** macOS lo modifica al abrir Finder. El `.gitignore` actual tiene un patrón `**.DS_Store**` mal formado (no es glob válido) y este archivo está siendo tracked.
2. **Decisión pendiente (`InformesTrimestrales.do`):** lo borraste pero no commiteaste. ¿Era basura o se borró por error?
3. **Ruido editorial (`simulador.stpr`):** el archivo de proyecto Stata se modifica al abrir/cerrar la app. Probablemente no debería trackearse, o debería trackearse una versión "canónica" sin estado de sesión.

### 2.4 `.gitignore`: efectivo vs. necesario

**Estado actual** (`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/.gitignore:1-7`):

```
**/temp/**
**/master/**
**/graphs/**
**/users/**
**/simuladorfiscal.ciep.mx/**
**.DS_Store**
```

**Problemas:**

- **`**.DS_Store**` es un glob mal formado.** Lo correcto: `**/.DS_Store` o simplemente `.DS_Store`. Por eso `.DS_Store` aparece como modificado en `git status`.
- No excluye **logs Stata**: `*.smcl`, `*.log`. Estos se generan en cada corrida. Hoy escapan porque viven en `temp/` y `users/` (gitignored) — pero si alguien corre algo desde otro directorio, entran al tronco.
- No excluye **archivos de sesión Stata**: `*.stswp` (workspace), `*.stbak`, `*.stsem`. El `simulador.stpr` modificado en el working tree es exactamente este síntoma.
- No excluye **conflictos Dropbox**: archivos como `nombre (rcantucs-MacBook conflicted copy 2024-XX-XX).do` que Dropbox crea en sincronizaciones simultáneas. Riesgo real porque el repo vive en Dropbox.
- No excluye **carpetas de IDEs**: `.vscode/`, `.idea/`, `.windsurf/cache/`.
- No excluye **`ado/personal/`** ni **`ado/plus/`** (carpetas que Stata crea automáticamente).
- **`raw/` no está ignorado** y pesa 607 MB.

### 2.5 Tamaño del repo, blobs históricos, deuda en `.git`

**Cifras críticas:**

| Métrica | Valor |
|---|---:|
| Tamaño del working tree (excl `.git`) | ~18 GB |
| Tamaño de `.git/` | **5.1 GB** |
| Pack files | 1.48 GiB en disco (3.63 GiB descomprimido) |
| Objetos totales | 7,184 |
| `raw/` actual | 607 MB (versionado) |
| `master/` | 5.3 GB (gitignored, OK) |

**Lo crítico: `.git` contiene 5.1 GB de historia, no sólo el `raw/` actual.** Hay carpetas borradas hace tiempo que siguen pesando en historia. Top blobs en historia:

| Tamaño | Path histórico | Estado actual |
|---:|---|---|
| 99 MB | `tabaco/Nov2022/Datos.dta` | **borrado** (carpeta `tabaco/` ya no existe) |
| 81 MB | `tabaco/Nov2022/bases/ENIGH 2020/concentrado.dta` | **borrado** |
| 64 MB | `raw/PEFs/CP 2022.xlsx` | actual (raw/ activo) |
| 52 MB | `bases/PEFs/CP 2014.xlsx` | **borrado** (carpeta `bases/` renombrada a `raw/` aparentemente) |
| 49 MB | `bases/PEFs/CP 2015.xlsx` | **borrado** |
| 47 MB | `help/images/Video1.mov` | **borrado** |
| 47 MB | `bases/PEFs/CP 2016.xlsx` | **borrado** |
| 46 MB | `raw/PEFs/CP 2019.xlsx` | actual |
| ... | múltiples `bases/PEFs/CP*.xlsx` y `raw/PEFs/CP*.xlsx` | mezclados actuales y borrados |

Adicionalmente, `git log --diff-filter=D --summary` lista borrados de:
- Manuales completos `00_manuales/ManualSimuladorCIEP/*.pdf` (eliminada toda la carpeta)
- Carpeta `2008/*.xlsx` con cientos de archivos (probablemente snapshot de un fork antiguo de la base SHCP)

**Implicación operativa decisiva:**

Migrar a Git LFS **sólo go-forward** (modo simple) **no reduce el tamaño del repo**. Quien clone seguirá descargando 1.48 GB. Para reducir el `.git` se necesita **reescribir la historia** con `git lfs migrate import --everything` o `git filter-repo`. Eso es **destructivo** (todos los SHAs cambian).

Esta decisión no la tomo aquí. La planteo como bifurcación en §4.

### 2.6 Calidad de mensajes de commit

Muestra de los 50 más recientes (extracto):

```
Update SIM.do                  ← 4 ocurrencias en 50 commits
Update profile.do              ← 3 ocurrencias
Update PIBDeflactor.ado        ← 3 ocurrencias seguidas
Major update                   ← qué cambió, qué se rompió: imposible saberlo
Carpeta Raw
LibroCIEP
Simulador del libro.
Refactor graph export paths and update data import logic
```

**Patrones identificados:**

- ~60 % son `Update <archivo>` o variantes de "Update X". No describen el porqué.
- ~10 % son referencias temáticas vagas ("LibroCIEP", "Simulador del libro").
- ~25 % sí tienen descripción accionable ("Refactor fiscal gap projections and encoding fixes", "Add 2025 budget assignment and update data import paths").
- ~5 % son merge commits automáticos.

Para un repo con bus factor 1, esto significa: **el historial Git no funciona como memoria institucional**. `git log -- archivo.ado` no permite reconstruir el porqué de una decisión metodológica.

### 2.7 Distribución pública (`Stata net/`) y dependencias on-the-fly

`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/stata.toc` declara la suite como instalable vía `net from`/`net install`. La URL pública NO está documentada en el README ni en este archivo, pero el patrón estándar Stata es servirla desde un endpoint web. Pendiente de verificar contigo: **¿hay un servidor público en `simuladorfiscal.ciep.mx` o equivalente que sirva estos `.ado`?**

Independiente de eso, **dentro del código** hay tres `net install` on-the-fly hacia Boston College Statistical Software Components:

- `labutil.pkg` (en `LIF.ado:609`, `PEF.ado:771`)
- `grc1leg2.pkg` (en `FiscalGap.ado:197`)

Cualquier corrida fresca depende de que `fmwww.bc.edu` esté disponible en ese momento. Sin pin de versión.

---

## 3. Acciones de higiene: secuencia priorizada

Cada acción es candidata a **un turno** futuro. Aquí sólo la justifico, defino su alcance y dependencias. Las marco con criticidad y reversibilidad.

### Acción 1 — Normalizar identidad (`.mailmap`)

| | |
|---|---|
| **Objetivo** | Hacer que `git log`, `git blame` y `git shortlog` muestren a Ricardo como una sola persona. |
| **Criticidad** | Alta (es prerrequisito para cualquier diagnóstico de bus factor con métricas creíbles). |
| **Reversibilidad** | Total (el `.mailmap` no toca historia, sólo cambia presentación). |
| **Dependencias** | Ninguna. |
| **Decisión pendiente** | Cuál es el "email canónico" de Ricardo: ¿`ricardocantu@ciep.mx` (institucional) o `rcantuc@gmail.com` (el que usaste en commits)? |
| **Output esperado** | `.mailmap` en raíz, con consolidación de los ≥4 alias actuales bajo un único `Ricardo Cantú <email-canónico>`. |

### Acción 2 — Cerrar el working tree sucio

| | |
|---|---|
| **Objetivo** | Repo en estado limpio antes de hacer cualquier cambio mayor. |
| **Criticidad** | Alta. Sin esto, los siguientes commits arrastran ruido. |
| **Reversibilidad** | Total mientras no se commitee. |
| **Decisiones pendientes** | (a) Recuperar o aceptar la baja de `01_modulos/análisis/InformesTrimestrales.do`. (b) ¿`simulador.stpr` debería trackearse (versión canónica sin estado) o ignorarse? (c) Asegurar que `.DS_Store` realmente queda fuera tras corregir `.gitignore`. |
| **Output esperado** | `git status` sólo muestra los nuevos artefactos de `governance/` y de la suite de fixes. |

### Acción 3 — Ampliar `.gitignore` para Stata + macOS + Dropbox + IDEs + secretos + raw/

| | |
|---|---|
| **Objetivo** | Prevenir que entre al repo lo que no debe. |
| **Criticidad** | Alta. Bloqueante para Acción 6 (rewrite). |
| **Reversibilidad** | Total. |
| **Dependencias** | Acción 2. |
| **Patrones a añadir** | `.DS_Store` (corregido), `*.smcl`, `*.log`, `*.stswp`, `*.stbak`, `*.stsem`, conflict files Dropbox (`* (*conflicted copy*).*`), `*[Recovered]*`, `hs_err_pid*.log`, `.vscode/`, `.idea/`, `.windsurf/cache/`, `ado/personal/`, `ado/plus/`, **`*.key`**, **`*.pem`**, **`*.p12`**, **`*.pfx`**, **`*.crt`**, **`**/ssl/**`** (refuerzo de auditoría de seguridad), **`**/raw/**`** *(NUEVO bajo el patrón Data Sidecar — los binarios de raw/ viven en GitHub Releases, no en Git)*. **Excepción:** `!raw/manifest.json` (el manifiesto sí se versiona). |
| **Output esperado** | `.gitignore` con secciones comentadas por categoría. |

### Acción 4 — Archivar `Stata net/` como `legacy/stata-net-v7/`

| | |
|---|---|
| **Objetivo** | Dejar explícito que `Stata net/` es **estado v7 congelado**, no código activo. |
| **Criticidad** | Media (no rompe nada hoy, pero perpetúa la divergencia mientras siga ahí). |
| **Reversibilidad** | Alta (el `git mv` se puede deshacer). |
| **Dependencias** | Acción 1, 2, 3. **Bloquea** la Acción 6 si quieres que LFS no tenga que mover archivos en `Stata net/` por separado. |
| **Pasos** | (a) `git mv "Stata net" legacy/stata-net-v7`. (b) Crear `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/legacy/stata-net-v7/README.md` que declare versión congelada, fecha de archivado, motivo, no editar. (c) Actualizar README principal para retirar instrucciones `net install` y declarar canal Git como oficial. (d) Si hay un servidor sirviendo el `stata.toc` (a confirmar), congelar su contenido o redirigir. |
| **Output esperado** | Carpeta `Stata net/` deja de existir en tronco; nueva `legacy/stata-net-v7/` con README de archivado. |

### Acción 5 — Mover `01_modulos/análisis/*` y otros legacy a una rama/tag

| | |
|---|---|
| **Objetivo** | Reducir la superficie de onboarding sin perder código. |
| **Criticidad** | Media-alta para gobernanza (colaboradores nuevos no leen 5,000 líneas legacy creyéndolas vivas). |
| **Reversibilidad** | Total (rama/tag preserva todo). |
| **Dependencias** | Acción 4 (para no mezclar dos movimientos grandes en commits revueltos). |
| **Alcance confirmado** | 9 archivos en `01_modulos/análisis/`, 2 en `01_modulos/visualizations/Graphs_*.do`, 1 en `01_modulos/households/Expenditure_PTLAC.do`, 1 en `01_modulos/profiles/PerfilesGasto.do`, 5 archivos en `01_modulos/visualizations/sankey/` (todos excepto `SankeySF.do`). Más posibles en raíz: `CensoEconomico.do` (stub 52 líneas). **Total ≈ 7,000 líneas legacy a mover.** |
| **Decisión pendiente** | ¿Estrategia rama (`legacy/v7-analisis-historicos`) o carpeta en tronco (`legacy/01_modulos_analisis/`)? Yo recomiendo carpeta en tronco con rama de respaldo (te explico por qué en concepto §6). |
| **Output esperado** | Tronco más delgado; `legacy/...` con índice de qué hay y por qué se archivó. |

### Acción 6 — Rewrite con `git filter-repo` + publicar binarios como assets del release v7.0

| | |
|---|---|
| **Objetivo** | Sacar binarios de `.git` (5.1 GB → ~250 MB esperado) y republicarlos como assets de un release inmutable. **Sin LFS.** |
| **Criticidad** | Alta. Es la mayor reducción de fricción para futuros `git clone`. |
| **Reversibilidad** | **Baja.** Reescribe historia (todos los SHAs cambian). Backup integral obligatorio antes. |
| **Dependencias** | (a) `git filter-repo` instalado (`brew install git-filter-repo`). (b) Acciones 1-5 y 7 ya completadas. (c) Manifest `raw/manifest.json` y script `download_data` ya construidos y probados. (d) Backup `git clone --mirror` realizado en disco externo. |
| **Pasos** | (1) Backup. (2) `git filter-repo --invert-paths` con todos los patrones de purga (carpetas borradas + `raw/` actual + basura — ver §5 del audit de seguridad). (3) `git push --force-with-lease origin master` (re-emite SHAs en GitHub). (4) Recrear tags `v7.0` post-rewrite. (5) Crear GitHub Release `v7.0` y subir todos los `.xlsx` actuales como assets. (6) Verificar que `download_data` corre limpio en clone fresco. |
| **Output esperado** | `.git` ~250 MB. `raw/` vacío en repo (sólo manifiesto). Release `v7.0` en GitHub con ~30 assets binarios. |

### Acción 7 — Crear tag `v7.0` sobre el estado "estable" pre-fixes

| | |
|---|---|
| **Objetivo** | Que la "Versión 7" mencionada en código y `stata.toc` exista como ancla Git navegable. |
| **Criticidad** | Media. No bloqueante, pero permite hablar de "antes" y "después" de Fase 0.5. |
| **Reversibilidad** | Total. |
| **Dependencias** | Decisión sobre history rewrite. Si se rewrite, los SHAs cambian y el tag se aplica al nuevo commit equivalente. |
| **Output esperado** | `git tag -a v7.0 -m "Estado pre-governance 2026-04-30"` en el SHA `2f46d92` (o su equivalente post-rewrite). Push de tag a origen. |

### Acción 8 — Convención de commits + estrategia de ramas

| | |
|---|---|
| **Objetivo** | Que los próximos commits tengan calidad para servir como memoria institucional. |
| **Criticidad** | Alta a futuro, no inmediata. |
| **Reversibilidad** | Total (es documental). |
| **Dependencias** | Ninguna técnica. |
| **Output esperado** | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/convenciones-git.md` con: (a) plantilla de commits (recomiendo Conventional Commits adaptado al contexto: `data:`, `model:`, `docs:`, `infra:`, `fix:`, `chore:`); (b) estrategia de ramas mínima (`master` + ramas de feature short-lived + opcional `develop`); (c) política de release (cuándo se etiqueta, cómo); (d) regla: no se hace push directo a `master` para cambios metodológicos. |

---

## 4. Decisión consolidada (2026-05-09): rewrite + Data Sidecar (sin LFS)

> Esta sección originalmente planteaba 3 opciones (LFS go-forward, LFS rewrite, híbrido). El usuario las descartó todas en favor de un patrón distinto. Mantengo el registro de la deliberación abajo para trazabilidad.

**Decisión final:** rewrite total con `git filter-repo` + publicación de binarios en GitHub Releases (no en LFS).

**Mecánica resumida:**

1. Se purgan TODOS los binarios del histórico Git con `git filter-repo --invert-paths` aplicando los patrones de §5 del audit de seguridad. No se migra nada a LFS.
2. Los binarios actuales (≈700 MB de `raw/PEFs/*.xlsx` y similares) se suben como assets del GitHub Release `v7.0` que se creará en Acción 7.
3. El repo contiene un manifiesto `raw/manifest.json` con la URL de cada asset, su SHA-256 y su tamaño esperado.
4. Un script (`download_data.do` o equivalente) lee el manifiesto y descarga lo que falte localmente, verificando hashes.
5. `raw/` queda gitignored (excepto el manifiesto). Releases publicados son inmutables: correcciones se publican como `v7.0.1`, `v8.0`, etc.

**Por qué se descartó LFS** (resumen ejecutivo, detalle se ampliará en `convenciones-git.md` Acción 8):

- **Cero costo recurrente** vs $5/mes Data Pack de GitHub LFS para >1 GB.
- **URLs inmutables** atadas a tags Git → atomicidad código↔datos garantizada por manifest + SHA-256.
- **Portabilidad alta**: los assets son `.xlsx` puros, no punteros LFS que dependen de un servidor.
- **Stack homogéneo Stata**: descargador puede ser `.do` puro con `copy` + `hashfile`, sin `git-lfs` como prerrequisito en cada máquina.
- **Versionado nativo por release** (cada `v7.0`, `v7.0.1`, `v8.0` es un snapshot inmutable de datos).

**Resultado esperado del rewrite:**

| Métrica | Antes | Después |
|---|---:|---:|
| Tamaño `.git` | 5.1 GB | ~250 MB |
| Pack | 1.48 GB | ~100 MB |
| Tiempo de `git clone` fresh | ~10-15 min | ~1 min |
| Storage extra requerido | 0 | ~700 MB en GitHub Releases (gratis hasta 2 GB por release; sin recurring) |
| Costo recurrente | $0 | $0 |

### Histórico de la deliberación (descartado pero registrado)

Las tres opciones que se evaluaron antes del cambio de estrategia:

- **A (LFS go-forward):** descartada — no reduce los 5.1 GB del `.git`.
- **B (LFS rewrite total):** descartada — costo recurrente ($5/mes Data Pack), dependencia de servidor LFS, los punteros LFS son frágiles si GitHub cambia política.
- **C (LFS híbrido):** descartada por el mismo motivo de B, sólo reducía el problema sin resolverlo conceptualmente.

La nueva opción D (Data Sidecar) supera a las tres en gobernanza: el repo Git contiene únicamente código, los datos son artefactos versionados separados con anclaje criptográfico (SHA-256), y el costo es cero.

---

## 5. Orden de ejecución actualizado (2026-05-09)

```
Acción 1 (.mailmap)                                          ✅ HECHO
Acción 2 (cerrar working tree sucio)                         ← siguiente
Acción 3 (.gitignore Stata + secretos + raw/ + conflicts)
Acción 8 (convenciones-git.md + política de releases inmutables)
─────────── COMMIT MILESTONE: tag v7.0 sobre estado pre-fixes (Acción 7) ───────────
Acción 4 (Stata net/ → legacy/stata-net-v7/ + actualizar README)
Acción 5 (01_modulos/análisis/* y otros legacy → legacy/)
Acción extra: rotar token BIE de INEGI + actualizar help docs + governance/secretos.md
─────────── COMMIT MILESTONE: tag v7.1-cleanup ───────────
Construir manifest raw/manifest.json + script download_data
Backup integral pre-rewrite (disco externo + git clone --mirror)
Acción 6 (rewrite con git filter-repo, sin LFS)
Crear GitHub Release v7.0 y subir todos los assets de raw/
Verificar end-to-end: clone fresco + download_data + corrida exitosa de SIM.do
─────────── COMMIT MILESTONE: tag v8.0-governance-ready ───────────
```

El milestone `v7.0` se hace **antes** del rewrite. Después del rewrite el SHA original `2f46d92` deja de existir, pero el tag `v7.0` se reaplica al commit equivalente post-rewrite, preservando la referencia simbólica.

**Token BIE rotado ANTES del rewrite** porque está en código (`AccesoBIE.ado`), no en binarios. El rewrite no limpia texto dentro de `.ado`. La protección real es revocar con INEGI; reescribir la historia con el token nuevo deja el repo consistente desde el primer commit post-rewrite.

---

## 6. 🧠 Concepto: rama de respaldo vs. carpeta `legacy/` en tronco

Cuando se quiere "archivar" código sin tirarlo, hay dos estrategias canónicas, y la elección importa:

**Rama de respaldo** (`git branch legacy/v7-analisis-historicos` y borrar del tronco): el código deja de aparecer en el tronco. Su existencia es invisible para alguien que abra el repo en GitHub: no lo verá hasta que recuerde cambiar a esa rama. Ventaja: tronco completamente limpio. Desventaja: **invisibilidad = olvido garantizado**. En 2 años nadie sabrá que existió `coneval.do`.

**Carpeta `legacy/` en tronco**: el código se mueve a una subcarpeta marcada explícitamente. Permanece visible y navegable en GitHub. Tiene un README que dice "esto es histórico, no se mantiene, no se ejecuta desde el pipeline". Ventaja: descubribilidad. Desventaja: ocupa espacio mental cuando se navega el tronco.

**Para gobernanza con bus factor que estamos subiendo de 1 a 2, recomiendo la segunda.** Un nuevo co-mantenedor que esté explorando el repo en su primer mes va a *querer* tropezar con el código legacy y decidir por sí mismo si vale la pena mirarlo. La rama escondida es una bomba de tiempo.

Una variante sensata: **carpeta `legacy/` en tronco + rama de respaldo (etiquetada con tag) por seguridad**. Si en 6 meses decidimos eliminar también la carpeta, el tag preserva el contenido.

## 6.5 🧠 Concepto: bus factor y reescritura de historia

Si haces history rewrite (Opciones B o C de §4), todos los SHAs cambian. Esto es problemático cuando hay muchos colaboradores con clones locales. **Aquí no es problema** porque:

- 96 % de los commits son tuyos.
- Los pocos colaboradores externos no tienen ramas pendientes ni PRs abiertos (verificado: no hay PRs en `origin/`).
- Nadie depende del SHA de `2f46d92` para nada externo (no hay CI, no hay packages versionados por SHA).

Bus factor 1 es malo para mantenimiento, pero es **bueno para reescritura de historia**: nadie más se entera. Esta ventana se cierra el día que un segundo colaborador empieza a trabajar en serio. **Si vamos a hacer history rewrite, hacerlo ahora.**

---

## 7. Preguntas críticas para Ricardo antes de seguir

Tres bloqueantes para Acción 6 y operativos para Acciones 1, 4:

**P1 — Email canónico para `.mailmap`**:
- (a) `ricardocantu@ciep.mx` (institucional, coherente con el header del código)
- (b) `rcantuc@gmail.com` (el que ya usas en commits, sin ruptura)
- (c) Otro

**P2 — Modo de migración a Git LFS** (la grande):
- (a) Go-forward (Opción A): conservador, no reduce los 5.1 GB del `.git`, sin riesgo de coordinación.
- (b) History rewrite total (Opción B): reduce el `.git` a ~300 MB, requiere GitHub LFS de pago o backend propio.
- (c) Híbrido (Opción C, mi recomendación): purga sólo carpetas hoy borradas (`tabaco/`, `bases/`, `2008/`, `00_manuales/`); LFS go-forward para los `raw/PEFs/*.xlsx` vivos.

**P3 — `Stata net/` como `legacy/stata-net-v7/`**:
- ¿Existe un servidor público (probablemente en `simuladorfiscal.ciep.mx` o similar) que sirve el `stata.toc` para `net install`? Si sí, declarar el endpoint que se va a congelar / dar de baja. Si no estás seguro, lo investigo con un `read_url_content`.

---

## 8. Próximo paso

Con tus respuestas a P1–P3 ejecuto la **Acción 1 (.mailmap)** como primer artefacto-código de Fase 0.5. Es el más pequeño, el más reversible, y el que más rápido te muestra el efecto en `git log` / `git shortlog`. Después seguimos con Acción 2 → 3 → 8 → 7 → 4 → 5 → 6, en ese orden.
