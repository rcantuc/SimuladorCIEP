# Changelog del Simulador Fiscal CIEP

Este archivo registra los cambios de cada versión publicada del Simulador Fiscal CIEP.

Las versiones se numeran siguiendo el esquema descrito en `governance/convenciones-git.md` §3:
mayor cuando hay cambio metodológico o institucional de fondo, menor cuando hay datos nuevos
o funcionalidad nueva compatible, patch para correcciones sobre versión publicada.

**A partir de v8.0, todas las versiones son reproducibles end-to-end** — código + datos +
endpoint publicados en la misma versión, referenciables mediante `git checkout v8.x`.

Formato de cada entrada:
- **Institucional:** cambios de governance, infraestructura, arquitectura de publicación
- **Comandos:** cambios que afectan cómo se usa el Simulador desde Stata (nuevas opciones,
  comandos agregados o modificados, comandos deprecados)
- **Datos:** cambios en fuentes, actualizaciones de PEFs, LIFs, ENIGH, u otras fuentes
- **Correcciones:** bugs corregidos que afectaban resultados o funcionamiento

## [v8.0.5] — 2026-07-04

Nuevo Gate 4 en pipeline de publicación: validación de existencia de archivos
declarados en manifest-endpoint.toml. Antes de crear la Release en GitHub,
publicar.sh verifica que cada archivo declarado como ado_files, sthlp_files,
y pkg_files existe físicamente en el filesystem del repo. Si algún archivo
falta, aborta con error informativo. Habría atrapado el bug de AccesoBIE.pkg
(v8.0.3 fix).

### Institucional
- Nuevo Gate 4 en publicar.sh valida existencia de archivos declarados en
  manifest-endpoint.toml antes de crear Release GitHub y rsync al endpoint.
- Los gates semánticos candidatos (autoría, URLs, prueba de humo automatizada)
  se descartan formalmente. Revisión visual del .sthlp por el investigador
  cubre autoría y URLs. Prueba de humo manual desde Stata externo (net from +
  net describe) es el gate humano institucional para validación semántica de
  paquetes publicados.

### Comandos
- Sin cambios de comportamiento en los comandos del canon.

### Datos
- Sin cambios respecto a v8.0.4.

## [v8.0.4] — 2026-07-04

Fix: corrige link para obtener el token del BIE/INEGI. El link anterior
(https://www.inegi.org.mx/servicios/api_biinegi.html) era una página obsoleta.
El link correcto es el generador de tokens de INEGI:
https://www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx
(compartido con DENUE, ya que INEGI usa un único sistema de tokens).

### Institucional
- 03_help/Stata/AccesoBIE.sthlp: link del {browse} corregido al generador
  de tokens vigente.
- AccesoBIE.ado: mensaje de error apunta al link correcto.
- set_token.template.do: comentario del template apunta al link correcto.

### Comandos
- Sin cambios de comportamiento. AccesoBIE mantiene sintaxis y datasets.

### Datos
- Sin cambios respecto a v8.0.3.

## [v8.0.3] — 2026-07-04

Fix: agrega 05_scripts/AccesoBIE.pkg que estaba declarado en el manifest del
sub-canal Stata público pero nunca existió en el filesystem. Este bug estaba
presente silenciosamente desde v8.0 y solo se destapó al probar
`net describe AccesoBIE` desde Stata externo tras la publicación de v8.0.2.

### Institucional
- Nuevo 05_scripts/AccesoBIE.pkg permite que investigadores externos hagan
  `net describe AccesoBIE` y `net install AccesoBIE` correctamente.
- manifest-endpoint.toml actualizado para incluir AccesoBIE.pkg en pkg_files.
- Corrección de typo en los 8 .pkg: "finanzas púbicas" → "finanzas públicas"
  (texto visible para investigadores externos en `net describe`).

### Comandos
- Sin cambios de comportamiento. Los comandos mantienen sintaxis y datasets.

### Datos
- Sin cambios respecto a v8.0.2.

## [v8.0.2] — 2026-07-04

Cambio menor de metadata: los 11 archivos .sthlp del canon (AccesoBIE,
DatosAbiertos, LIF, PEF, PIBDeflactor, Poblacion, SCN, SHRFSP, GastoPC,
TasasEfectivas, sim_changelog) ahora incluyen autoría del investigador
principal + correo institucional clicable en el encabezado.

### Institucional
- Encabezado de los .sthlp muestra ahora: "Centro de Investigación Económica
  y Presupuestaria, A.C. | ciep.mx" seguido de "Ricardo Cantú Calderón |
  ricardocantu@ciep.mx" (correo abre cliente de mail al hacer clic).

### Comandos
- Sin cambios respecto a v8.0.1. Los comandos mantienen sintaxis, opciones,
  resultados y datasets.

### Datos
- Sin cambios respecto a v8.0.1. Assets del data sidecar son idénticos.

## [v8.0.1] — 2026-07-03

Cleanup documental. La ayuda de comandos institucionales del canon queda consolidada
en archivos .sthlp como fuente única de verdad. Los .md descriptivos que vivían en
paralelo desde febrero 2026 fueron migrados (contenido metodológico que sobrevivió
la auditoría de sincronía .ado/.sthlp) o eliminados. El manual del investigador se
movió de manuales/ a help/.

### Institucional
- Los .md de ayuda de los 8 comandos del canon (AccesoBIE, DatosAbiertos, LIF, PEF,
  PIBDeflactor, Poblacion, SCN, SHRFSP) fueron consolidados en sus respectivos .sthlp
  y eliminados. Nueva subsección 2.7 en governance/arquitectura-distribucion.md
  formaliza el principio "la ayuda de comandos vive en .sthlp".
- Manual del investigador movido de manuales/ a help/ (unifica dominio "help").
- README.md corregido: rutas de imágenes rotas apuntan a help/images/; bloques con
  imágenes fantasma eliminados; entrada canónica a la ayuda ahora es help <comando>.
- Hallazgo #3 de governance/auditoria-drift-sthlp.md marcado como resuelto.

### Comandos
- Sin cambios respecto a v8.0. Los comandos mantienen la misma sintaxis, opciones,
  resultados y datasets. Solo cambia el contenido de la ayuda (más rico, sin drift).

### Datos
- Sin cambios respecto a v8.0. Las fuentes y assets del data sidecar son idénticos.

## [v8.0] — 2026-05-29

**Primera versión bajo arquitectura institucional completa.** Marca el inicio de la era
reproducible: a partir de v8.0 cualquiera puede reconstruir código + datos exactos usados
para producir un resultado citado del Simulador.

### Institucional
- Data sidecar publicado en GitHub Release v8.0 con 23 archivos de fuentes (PEFs, LIFs,
  ENIGH, CuotasISSSTE, ISRInformesTrimestrales, CP históricos).
- Sub-canal Stata público automatizado: `net from https://ciep.mx/simuladorfiscal/`
  sirve los 8 paquetes principales sin necesidad de tener acceso al repo.
- `manifest.json` en la raíz del repo declara el Catálogo de datos asociados con
  huellas digitales SHA-256 y URLs de descarga.
- `publicar.sh` publica una versión nueva al endpoint público en un solo comando.
- Governance formal documentada en el directorio `governance/`.
- Convenciones de Git, versionado y publicación formalizadas en `governance/convenciones-git.md`.

### Comandos
- Sin cambios respecto a v7.0. Los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`,
  `SHRFSP`, `DatosAbiertos`, `AccesoBIE` mantienen la misma sintaxis y opciones.
- `GastoPC` y `TasasEfectivas` continúan en desarrollo, no publicados oficialmente.

### Datos
- Las fuentes de datos son las mismas que v7.0. La ruptura de v8.0 es institucional
  (reproducibilidad, publicación formal), no metodológica ni de fuentes.

## [v7.0] — 2026-05-23

**Última versión del Simulador como proyecto personal del investigador principal.**
Transición del Simulador desde código operativo con conocimiento metodológico
principalmente tácito hacia infraestructura institucional. El mensaje del tag lo captura:
"Data sidecar publicado (transición v7.x → v8.0)."

### Institucional
- Migración inicial de datos: de URLs personales de Dropbox a assets de GitHub Release v7.0.
- `manifest.json` inicial (23 assets con SHA-256).
- Introducción de `ensure_asset.ado` para descarga verificada de fuentes.
- Rewrite de historia Git para purgar credenciales expuestas y binarios pesados
  (repo: 5.1 GB → 49 MB).
- Externalización del token BIE/INEGI mediante `set_token.do` gitignored + plantilla
  `set_token.template.do` versionada.
- Cierre del canal manual `Stata net/`: los `.ado` viven solo en el root del repo.

### Comandos
- Los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`, `SHRFSP`, `DatosAbiertos`,
  `AccesoBIE` están disponibles y funcionales.
- Refactor de los `.ado` para usar `ensure_asset` en lugar de URLs hardcoded a Dropbox.

### Datos
- Fuentes: PEFs (2013-2026), CPs, ENIGH (2014-2024), LIFs, CuotasISSSTE,
  ISRInformesTrimestrales.
