# 02_governance — Cómo se gobierna el Simulador Fiscal CIEP

Esta carpeta contiene las normas vivas del Simulador Fiscal CIEP (arquitectura, versionado, publicación, secretos), el registro de cambios por versión y una guía pedagógica que explica los principios detrás de esas normas. Este índice dice qué documento abrir según quién eres y qué necesitas. Si una línea de este índice deja de ser cierta, el índice está mal: corrígelo en el mismo commit que el cambio que la invalidó.

## Empieza aquí

| Si eres… | Abre |
|---|---|
| **Alumno o colega que va a construir su propio simulador** | `guia-simulador-bien-gobernado.md` — doce principios, cada uno con el incidente que lo originó y la ruta donde se ve funcionando aquí. |
| **Investigador CIEP que va a usar el Simulador** | `03_help/manual-investigador-ciep.md` (fuera de esta carpeta) y después `arquitectura.md` §2. |
| **Quien va a publicar una versión** | `CHANGELOG.md` (escribe la entrada primero), `runbook-deploys-ciep.md` (comandos; el ritual hasta `--check` es `05_scripts/ritual.sh`, §14), `versionado-y-git.md` §3 (qué número). |
| **Quien va a escribir el prompt de una sesión** | `prompts/README.md` y la plantilla que toque (`memo.md`, `implementacion.md`, `ritual.md`). |
| **Quien tocó un archivo de `raw/` y el candado lo detuvo** | `runbook-actualizar-assets.md`. |
| **Quien maneja credenciales del CIEP** | `politicas-institucionales.md` Parte I. |

## Documentos de norma (vivos)

Se reescriben en su lugar cuando la realidad cambia. La historia de cada uno está en `git log --follow <archivo>`; los cambios al Simulador se registran solo en `CHANGELOG.md` (la bitácora interna que conservan `versionado-y-git.md` y `politicas-institucionales.md` registra cambios al propio documento, nunca al Simulador).

| Documento | Qué responde |
|---|---|
| `arquitectura.md` | Cómo está organizado el Simulador como sistema de cuatro capas (desarrollo, distribución a investigadores, reproducción histórica, web pública); qué es una versión publicada; cómo se reproduce un análisis; el principio «Stata produce los números» con su límite y sus puntos de control (§6.3.1); infraestructura (Cloudways / IONOS); lo que sigue pendiente (§7); apéndice de comportamientos no obvios del entorno. |
| `versionado-y-git.md` | Parte I: convenciones de commits, ramas, etiquetas, reescritura de historia, `.gitignore`. Parte II: historia de versiones (era v7.x vs. v8.0+) y contexto de los releases. |
| `politicas-institucionales.md` | Parte I: gestión de secretos y credenciales (qué es secreto, dónde vive, qué hacer si se compromete). Parte II: ciclo de vida de productos del Ecosistema CIEP. |
| `runbook-deploys-ciep.md` | Comandos para publicar un release a las tres caras (Git → endpoint Stata → VPS web), por tipo de release, con rollback. |
| `runbook-actualizar-assets.md` | Qué es el manifiesto, por qué existe el candado `ensure_asset` y los pasos exactos para actualizar un archivo de datos sin romperlo. |

## Registro y datos operativos

| Archivo | Qué es |
|---|---|
| `CHANGELOG.md` | Registro de cambios por versión publicada. **Único** registro: ningún otro documento de esta carpeta lleva bitácora. El gate 1 de `publicar.sh` exige una entrada por versión. |
| `scalarlatex-baseline.txt` | No es documento: es dato. Lista auditada de escalares sin registrar que `scalarlatex.ado` lee en tiempo de ejecución para detectar deriva. Cómo actualizarla legítimamente está en su encabezado. |
| `scn-celdas.md` | Inventario de las celdas del SCN que lee el motor (series BIE con consumidor, filas de los tabulados CSI que el BIE no tiene, escalares derivados, vintage que registra cada archivo). Es lo que recorre `05_scripts/refrescar-scn.sh --comparar` (política de fuente SCN, CUAD-0 §4 bis). Lo genera `05_scripts/gen-scn-celdas.py` (anclas en `anioenigh`, marco del Paquete desde el último año congelado del asset); `--check` exige 0 diferencias con el repo. |
| `deploys/` | Log local del pipeline de publicación al endpoint (`endpoint-stata.log`); no se versiona y no existe en git: `publicar.sh` y `publicar-endpoint.sh` crean la carpeta al escribir. |

## Subcarpetas

**`paquete-economico/`** — Expediente de diseño del rediseño de `paqueteeconomico.ciep.mx` (nodos temáticos, independencia metodológica, piloto del nodo de deuda). Es un proyecto hermano que consume el Simulador, no una norma del Simulador. Tiene su propio README.

**`perf/`** — Perfiles de rendimiento fechados del flujo web «Calcular» (dónde se va el tiempo, qué es invariante al escenario, metas propuestas). Son medición, no norma ni decisión; el instrumento es `05_scripts/perfilar-web.sh`. Tiene su propio README.

**`metodo/`** — Fuente de la página `/metodo` (prevista para v8.18): plantilla de capítulo y requerimientos del capítulo 0. El primer capítulo, `Households`, es `CUAD-0.md` (en la raíz de esta carpeta), memo de Cuadratura firmado por Ricardo el 2026-10-31 (la firma está en su §4.0, §4 y §10 bis) e implementado en v8.15b; `metodo/fuentes/` guarda los PDF citados con sha256. Los capítulos siguientes son `CUAD-1.md` (`Expenditure` y `TasasEfectivas`: Cuadratura II, 8.16; borrador para firma) y `CUAD-2.md` (Sankey de la economía completa, 8.17; borrador para firma), escritos en la misma plantilla y pendientes de firma de Ricardo.

**`prompts/`** — Plantillas de prompt de sesión (`memo.md`, `implementacion.md`, `ritual.md`) con los bloques fijos de las sesiones de octubre y noviembre de 2026 y un bloque `<<CONTENIDO>>` para lo específico. Todo prompt de sesión nace de una de ellas. Tiene su propio README.

**`historico/`** — Documentos congelados que un documento vigente o el código todavía cita: reportes fechados ya ejecutados, auditorías, la bitácora v1.0–v1.57 del documento de arquitectura. No se editan. Cada uno abre con una nota de cuándo se retiró, por qué y qué documento vigente lo reemplaza, y tiene una línea en `historico/README.md` (índice).

## Vocabulario

Los términos de los documentos de esta carpeta (antes `glosario-ciep.md`, de mayo de 2026, fundido aquí en 8.18a-2). Registro formal en la documentación; en conversación y presentaciones se aceptan las formas coloquiales.

| Concepto | Término formal | Coloquial aceptable |
|---|---|---|
| Quien desarrolla y mantiene el Simulador | **Investigador principal** | |
| Co-desarrolladores futuros | **Investigadores colaboradores** | |
| Equipo CIEP que usa el Simulador como herramienta | **Investigadores** | |
| Personas que usan la herramienta web pública | **Usuarios externos** | |
| Release | **Publicación** (verbo: «publicar una versión») | release |
| Tag | **Etiqueta de versión** | tag |
| Repositorio Git en GitHub | **Código del Simulador** | repo |
| Carpeta Dropbox que recibe la versión publicada | **Carpeta del Simulador para investigadores** | |
| Rama Git de desarrollo | **Rama de trabajo** | |
| Archivo manifest con SHA-256 de datos | **Catálogo de datos asociados** | manifest |
| Los tres simuladores web del CIEP (Fiscal, IEPS al tabaco, tenencia vehicular) | **Simuladores CIEP** (cuando se dice así, una política aplica a los tres; «el Simulador Fiscal CIEP» aplica solo a ese) | Simuladores fiscales CIEP |
| Productos digitales + infraestructura (hosting, VPS) + dominios `*.ciep.mx` | **Ecosistema CIEP** | Ecosistema digital del CIEP |
| Productos narrativos vinculados a proyectos bandera, sin código de cálculo | **Micrositios** | Micrositios narrativos |
| Herramienta donde viven los valores reales de las credenciales | **Gestor de secretos institucional** (adopción formal pendiente: `politicas-institucionales.md` A.3) | |

Se conservan en inglés, con explicación la primera vez: `Git`, `GitHub`, `commit`, `push`, `pull`, `branch` (junto a «rama»), `merge`, `rewrite`, `SHA`. No se usan: «mantenedor» (→ investigador principal / colaborador) ni «audit trail», «single source of truth», «build artifact» (se describen en español llano). «Canónico» y «sidecar» sí se usan desde v8.14 (datos canónicos de `-datos`, sidecar de datos de la Release): la prohibición del glosario de mayo se retiró al fundirlo.

## Política de higiene de esta carpeta

- **Los documentos vivos se reescriben en su lugar.** No hay archivos `_v1`, `_v2` en el directorio actual; las versiones viejas viven en la historia de Git (`git log --follow <archivo>`).
- **Los documentos que dejan de aplicar y que un documento vigente cita se archivan en `historico/`**, con una nota corta al inicio que diga por qué se retiraron y qué documento vigente los reemplaza; los que nadie cita se borran (regla siguiente).
- **Git conserva la historia; el árbol vivo solo contiene lo que algo referencia; `historico/` guarda solo lo que un documento vigente cita, con nota de retiro e índice.** Lo que nada referencia se borra: `git log --follow <archivo>` lo recupera. (Decisión de Ricardo, 2026-11-01; sustituye a «No se borra nada permanentemente».)
- **Ningún documento de norma registra cambios del Simulador.** Eso es exclusivo de `CHANGELOG.md`. Una bitácora interna, si existe, anota solo ediciones del propio documento; no se abren bitácoras nuevas. (Regla desde 2026-10-03, cuando la bitácora del documento de arquitectura —que había crecido a 57 filas duplicando al CHANGELOG— se congeló en `historico/bitacora-arquitectura.md`.)
- **Los documentos de diseño de otros productos** van en subcarpeta propia con README, no en la raíz.
- **Este índice se actualiza en el mismo commit** que agrega, mueve o archiva un documento.
