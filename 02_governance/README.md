# 02_governance — Cómo se gobierna el Simulador Fiscal CIEP

Esta carpeta contiene las normas vivas del Simulador Fiscal CIEP (arquitectura, versionado, publicación, secretos), el registro de cambios por versión y una guía pedagógica que explica los principios detrás de esas normas. Este índice dice qué documento abrir según quién eres y qué necesitas. Si una línea de este índice deja de ser cierta, el índice está mal: corrígelo en el mismo commit que el cambio que la invalidó.

## Empieza aquí

| Si eres… | Abre |
|---|---|
| **Alumno o colega que va a construir su propio simulador** | `guia-simulador-bien-gobernado.md` — doce principios, cada uno con el incidente que lo originó y la ruta donde se ve funcionando aquí. |
| **Investigador CIEP que va a usar el Simulador** | `03_help/manual-investigador-ciep.md` (fuera de esta carpeta) y después `arquitectura.md` §2. |
| **Quien va a publicar una versión** | `CHANGELOG.md` (escribe la entrada primero), `runbook-deploys-ciep.md` (comandos), `versionado-y-git.md` §3 (qué número). |
| **Quien tocó un archivo de `raw/` y el candado lo detuvo** | `runbook-actualizar-assets.md`. |
| **Quien maneja credenciales del CIEP** | `politicas-institucionales.md` Parte I. |

## Documentos de norma (vivos)

Se reescriben en su lugar cuando la realidad cambia. La historia de cada uno está en `git log --follow <archivo>`; los cambios al Simulador se registran solo en `CHANGELOG.md` (la bitácora interna que conservan `versionado-y-git.md`, `politicas-institucionales.md` y `glosario-ciep.md` registra cambios al propio documento, nunca al Simulador).

| Documento | Qué responde |
|---|---|
| `arquitectura.md` | Cómo está organizado el Simulador como sistema de cuatro capas (desarrollo, distribución a investigadores, reproducción histórica, web pública); qué es una versión publicada; cómo se reproduce un análisis; infraestructura (Cloudways / IONOS); lo que sigue pendiente (§7); apéndice de comportamientos no obvios del entorno. |
| `principio-stata-produce-los-numeros.md` | El principio transversal al ecosistema: Stata produce todos los números y los demás destinos (web, PDF, infografía) solo renderizan. Cadena completa con sus puntos de control. |
| `versionado-y-git.md` | Parte I: convenciones de commits, ramas, etiquetas, reescritura de historia, `.gitignore`. Parte II: historia de versiones (era v7.x vs. v8.0+) y contexto de los releases. |
| `politicas-institucionales.md` | Parte I: gestión de secretos y credenciales (qué es secreto, dónde vive, qué hacer si se compromete). Parte II: ciclo de vida de productos del Ecosistema CIEP. |
| `runbook-deploys-ciep.md` | Comandos para publicar un release a las tres caras (Git → endpoint Stata → VPS web), por tipo de release, con rollback. |
| `runbook-actualizar-assets.md` | Qué es el manifiesto, por qué existe el candado `ensure_asset` y los pasos exactos para actualizar un archivo de datos sin romperlo. |
| `glosario-ciep.md` | Vocabulario formal del CIEP, equivalencias formal/coloquial y términos en inglés que se conservan. |

## Registro y datos operativos

| Archivo | Qué es |
|---|---|
| `CHANGELOG.md` | Registro de cambios por versión publicada. **Único** registro: ningún otro documento de esta carpeta lleva bitácora. El gate 1 de `publicar.sh` exige una entrada por versión. |
| `scalarlatex-baseline.txt` | No es documento: es dato. Lista auditada de escalares sin registrar que `scalarlatex.ado` lee en tiempo de ejecución para detectar deriva. Cómo actualizarla legítimamente está en su encabezado. |
| `deploys/` | Log local del pipeline de publicación al endpoint (`endpoint-stata.log`); no se versiona. |

## Subcarpetas

**`paquete-economico/`** — Expediente de diseño del rediseño de `paqueteeconomico.ciep.mx` (nodos temáticos, independencia metodológica, piloto del nodo de deuda). Es un proyecto hermano que consume el Simulador, no una norma del Simulador. Tiene su propio README.

**`historico/`** — Documentos congelados: reportes fechados ya ejecutados, auditorías, la bitácora v1.0–v1.57 del documento de arquitectura. No se editan. Cada uno abre con una nota de cuándo se retiró, por qué y qué documento vigente lo reemplaza.

## Política de higiene de esta carpeta

- **Los documentos vivos se reescriben en su lugar.** No hay archivos `_v1`, `_v2` en el directorio actual; las versiones viejas viven en la historia de Git (`git log --follow <archivo>`).
- **Los documentos que dejan de aplicar se archivan en `historico/`**, con una nota corta al inicio que diga por qué se retiraron y qué documento vigente los reemplaza.
- **No se borra nada permanentemente.** Lo obsoleto queda en `historico/` para que el contexto de las decisiones siga consultable.
- **Ningún documento de norma registra cambios del Simulador.** Eso es exclusivo de `CHANGELOG.md`. Una bitácora interna, si existe, anota solo ediciones del propio documento; no se abren bitácoras nuevas. (Regla desde 2026-10-03, cuando la bitácora del documento de arquitectura —que había crecido a 57 filas duplicando al CHANGELOG— se congeló en `historico/bitacora-arquitectura.md`.)
- **Los documentos de diseño de otros productos** van en subcarpeta propia con README, no en la raíz.
- **Este índice se actualiza en el mismo commit** que agrega, mueve o archiva un documento.
