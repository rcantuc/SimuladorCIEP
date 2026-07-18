# Changelog del Simulador Fiscal CIEP

Este archivo registra los cambios de cada versión publicada del Simulador Fiscal CIEP.

Las versiones se numeran siguiendo el esquema descrito en `02_governance/versionado-y-git.md` §3:
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

## [v8.0.12] — 2026-07-18

Pipeline textbook declarativo: los ~670 scalars que alimentan los documentos
LaTeX internos dejan de definirse con `noisily di %fmt` + relectura de logs de
pantalla (patrón fósil, frágil ante cualquier cambio cosmético de impresión) y
pasan a declararse con el nuevo comando `escalar <tipo> <nombre> = <exp>`,
que registra nombre y tipo semántico; `scalarlatex` exporta desde ese registro
con formato canónico por tipo. Cero impacto en el endpoint público. Los `.tex`
internos sí cambian de valores: la precisión completa y dos bugs corregidos
(ver Correcciones) mueven los agregados por decil de los módulos ENIGH.

### Comandos
- Nuevo `escalar.ado` (solo-repo): define el scalar y lo registra para
  exportación textbook con el catálogo de tipos pctpib, pct, mxn, mxnpc,
  personas, anio y custom(%fmt). Ver `03_help/PROGRAMAS_AUXILIARES.md` §16.
- `scalarlatex.ado` reescrito: aplica el formato canónico del registro
  `$scalarlatex_reg` en vez de releer `users/$id/*.txt`; ya no depende de
  `log on/off` ni de formatos de impresión. Los scalars sin registrar se
  exportan tal cual y se reportan (drift visible). Interfaz intacta
  (`log()`, `alt()`).
- Migrados los 17 archivos productores textbook (~670 sitios): PIBDeflactor, Poblacion,
  SCN, SHRFSP, TasasEfectivas, GastoPC, LIF, FiscalGap y módulos Households,
  PerfilesSim, Expenditure, ISR_Mod, IVA_Mod, output, Sankey(SF), Graphs_TE.
- El censo de cierre cazó 17 sitios omitidos en `Expenditure.do` (incluidos los
  round-trips `DifIVA`/`DifIEPSNP`, misma clase del bug del arrendamiento) y 10 en
  `FiscalGap.ado` (`tt*/td*/tn*` + años): migrados. El `real()` de FiscalGap:132
  sobre los params `*PIB` de SIM.do queda con comentario-INVARIANTE: son strings
  por diseño (interfaz web), igual que en SankeySF — no migrar.
- `Simulador.ado` (9 sitios `string()`, nombres dinámicos por decil) NO se migra
  en v8.0.12: corre en el VPS por cada simulación y exige ciclo propio con
  validación web. Registrado en bitácora v1.38 como candidato.

### Correcciones
- Cierra el AGUJERO CONOCIDO de v8.0.11: PIBDeflactor, Poblacion, SCN y SHRFSP
  publicados ahora hacen `capture which scalarlatex` bajo `textbook` y avisan
  amablemente que la opción es solo-repo, en vez de tronar con "command
  scalarlatex is unrecognized" en el endpoint.
- Los `\def` LaTeX con dígitos en el nombre (p.ej. `\dConsPriv21PIBscn`) se
  generaban rotos en silencio; `escalar` convierte dígitos a letras (0→A…9→J)
  y ahora esas macros son válidas.
- Los scalars "% del PIB" del SHRFSP se exportaban con 1 decimal (formato de
  pantalla); ahora 3 decimales canónicos. Padding accidental de `%07.1fc` y
  redondeos compuestos de la relectura de logs eliminados.
- BUG NUMÉRICO corregido (silencioso desde el origen del patrón): en
  `Households.do` el split arrendamiento pf/PM (`ing_t4_cap3pf`/`PM`) usaba
  `real(scalar(AlojT))` sin quitar comas; `real("940,573.4")` = missing, así
  que TODO el capítulo 3 (arrendamiento) se caía en silencio del ingreso mixto
  y del ingreso de capital (`rsum` trata missing como 0). Con el valor real,
  el ingreso mixto captado sube ~30% (MixLHHSPIB 1.861→2.421% PIB;
  DifMixL −86.5→−82.5%) y se recorren deciles, ahorro, cortes de formalidad
  ISR y la brecha fiscal (diffs de ±1–4% en fiscalgap/gastopc/households/
  perfiles/shrfsp/tasasEfectivas del test dorado).
  Causalidad DEMOSTRADA por prueba de aislamiento: código viejo + únicamente
  el fix del `subinstr` reproduce 4,315 de los ~4,900 valores que cambian
  (base→viejo+parche); el resto es precisión/formato del pipeline nuevo
  (viejo+parche→nuevo: 96 diffs = 16 escalares×6 alias, todos auditados:
  mismo valor con decimal nuevo o fin del redondeo a 0.1 mdp de la
  relectura). Residuo inexplicado: 0.
- Durante la migración, `SCN.ado` registraba `PIB` en millones con tipo
  `pctpib` mientras sus consumidores (Households, Expenditure, ISR_Mod)
  esperan pesos: ratios `*HHSPIB` salían 1e6 veces más grandes. Corregido a
  `escalar mxn PIB = PIB[obs]` (pesos, display idéntico al histórico).

## [v8.0.11] — 2026-07-10

El endpoint público se vuelve autosuficiente: un usuario externo que instala
un comando vía `net install` puede reconstruir los datos desde cero en SU
máquina, sin repo ni clone. Corrige un bug de arquitectura presente desde el
primer deploy del endpoint: los comandos publicados invocaban helpers y
dependencias que el endpoint no entregaba — nunca funcionó para un externo;
solo parecía funcionar porque siempre se probó desde el repo. Cero impacto
en resultados numéricos.

### Institucional
- Decisión de arquitectura: el endpoint DEBE permitir reconstruir datos desde
  cero — es abierto, reconstruir es la gracia. La solución es un ensure_asset
  de doble entorno con pin de versión quemado al publicar (ver Comandos), de
  modo que código y datos del externo siempre casan: reconstruye contra los
  assets del Release de SU versión instalada.
- AGUJERO CONOCIDO PENDIENTE (no corregido en este bump): `scalarlatex` es
  invocado por PIBDeflactor, Poblacion, SCN y SHRFSP bajo la opción `textbook`
  (insumos LaTeX internos CIEP) y NO se publica al endpoint — un externo que
  active esa opción verá "command scalarlatex is unrecognized". Fix futuro:
  `capture which scalarlatex` + aviso amable de que textbook es solo-repo.

### Comandos
- ensure_asset ahora funciona sin repo (doble entorno): si encuentra
  `05_scripts/manifest.json` en el site (caso repo), comportamiento intacto;
  si no, usa el pin de versión que publicar-endpoint.sh quema en la copia
  publicada para descargar el manifest de GitHub por tag
  (raw.githubusercontent.com/<repo>/<tag>/05_scripts/manifest.json), lo
  cachea por versión en `raw/temp/manifest-<tag>.json`, valida que la
  versión del manifest coincida con el pin (drift → error ruidoso nombrando
  la URL) y continúa con la descarga de assets ya existente. El .ado del
  REPO lleva el pin VACÍO — solo la copia publicada lo lleva relleno.
- ensure_asset se publica al endpoint (sale de la lista de exclusión de
  manifest-endpoint.toml); viaja dentro de los .pkg que lo necesitan, sin
  paquete propio de cara al usuario.

### Datos
- Sin cambios respecto a v8.0.10.

### Correcciones
- Clausura transitiva de dependencias en 6 .pkg: cada paquete ahora declara
  TODAS sus dependencias .ado (quien instala PEF recibe también
  DatosAbiertos, AccesoBIE, Poblacion y ensure_asset; análogo para
  DatosAbiertos, LIF, PIBDeflactor, SCN y SHRFSP). Antes, instalar un
  paquete individual dejaba fuera eslabones de su cadena de reconstrucción
  y el comando tronaba con "command ... is unrecognized".
- publicar-endpoint.sh verifica la inyección del pin y ABORTA si el marcador
  no está — imposible publicar un ensure_asset sin pin por accidente.
- Hallazgos del test de "máquina virgen" (instalar SOLO desde el endpoint y
  reconstruir), corregidos de paso — tres bugs que solo muerden fuera del
  repo:
  - ensure_asset descarga con `requests` en lugar de `urllib`: urllib truena
    con CERTIFICATE_VERIFY_FAILED en Pythons sin certificados configurados
    (caso típico de instalación de python.org en macOS); requests trae sus
    propios certificados (certifi) y ya es dependencia dura de la suite
    (AccesoBIE la importa).
  - `mkdir master/` antes de cada save de la cadena de reconstrucción (LIF,
    PEF ×2, SCN, SHRFSP, Deflactor): en una máquina sin repo el directorio
    no existe y el save tronaba con r(603) — mismo bug de instalación fresca
    que v8.0.9/v8.0.10, en otra capa.
  - Eliminado un guard `if c(console)==console { exit }` en
    UpdateDatosAbiertos que abortaba la reconstrucción EN SILENCIO en Stata
    console/batch — el comando anunciaba "ACTUALIZANDO..." y salía sin
    hacer nada, dejando un r(601) críptico aguas abajo. Hacía imposible
    reconstruir en batch (p.ej. servidores).

## [v8.0.10] — 2026-07-10

AccesoBIE deja de exigir token para funcionar: sin token, usa la consulta
pública de exportación (.aspx) del INEGI — una vía que YA existía como
respaldo automático cuando la API falla, pero que era inalcanzable sin
token porque el comando abortaba antes de intentarla. Los comandos
publicados del Simulador dejan de depender de que el usuario externo
tenga token. Cero impacto en resultados numéricos.

### Institucional
- Nota de diseño sobre la vía pública (.aspx), con honestidad sobre su
  fragilidad: el *mecanismo* es oficial y abierto (el endpoint de
  exportación a Excel del propio portal del BIE, sin auth), pero la
  *implementación* parsea la tabla HTML de la respuesta con
  BeautifulSoup — más frágil que el JSON de la API: se rompe si INEGI
  cambia el layout de esa tabla. Es aceptable distribuirla porque (a) ya
  era camino de producción activo (corría cada vez que la API fallaba),
  (b) no introduce dependencias nuevas, y (c) el fallo es visible, no
  silencioso. Por esa fragilidad, la API con token sigue siendo la vía
  recomendada.

### Comandos
- AccesoBIE sin token: ya no aborta con exit 198 inmediato. Usa la
  consulta pública (.aspx) como vía única, con aviso visible de por cuál
  vía se obtuvieron los datos y de cómo conseguir el token gratuito.
  Sin token NO se golpea la API (no se hacen requests con token vacío).
  Ambas vías entregan exactamente el mismo formato de salida.
- AccesoBIE: exit 198 pasa a ser el fallo FINAL — solo cuando una serie
  no se pudo obtener por ninguna vía — con mensaje que nombra la serie y,
  si no hay token, explica que solo se intentó la vía pública.

### Datos
- Sin cambios respecto a v8.0.9.

### Correcciones
- AccesoBIE: si una serie no se obtenía (p.ej. clave inexistente), el
  comando mostraba un error y seguía (continue), dejando tempfiles
  indefinidos que después tronaban en el use/merge con un error críptico
  lejos de la causa. Ahora el error truena en su origen, claro y
  nombrando la serie.
- AccesoBIE: mismo bug de instalación fresca que v8.0.9 en DatosAbiertos
  — mkdir no recursivo —: el árbol site/raw/temp/AccesoBIE/ ahora se crea
  nivel por nivel.

## [v8.0.9] — 2026-07-10

DatosAbiertos aprende a descargar con respaldos: la opción `update` ahora
intenta el zip (dos veces, por errores transitorios de conexión), si falla
cae al csv directo, y si también falla usa los archivos locales de
`raw/temp/`. Antes, `update` sin más opciones ni siquiera descargaba —
leía los archivos locales en silencio. La opción `files` se renombra a
`local` y los 33 bloques repetidos de descarga se colapsan en un programa
auxiliar. Cero impacto en resultados numéricos.

### Institucional
- DatosAbiertos.ado: los 33 bloques idénticos `csvfile/zipfile/else`
  (~550 líneas, uno por base del portal SHCP) se colapsan en el programa
  auxiliar `_DAdescarga`, que concentra la cadena de respaldos en un solo
  lugar. Arreglar un problema de descarga ahora es un cambio de una línea,
  no de 33.

### Comandos
- DatosAbiertos, `update`: ahora descarga de verdad, con cadena de
  respaldos automática (zip con reintento → csv directo → archivos
  locales). Cada caída de la cadena se anuncia en pantalla; si tampoco hay
  archivo local, el error truena en su origen.
- DatosAbiertos, `zipfile`: se conserva por compatibilidad; hoy equivale a
  la cadena completa de `update`.
- DatosAbiertos, `csvfile`: brinca el zip y va directo al csv en línea;
  si falla, usa los archivos locales.
- DatosAbiertos, `local` (nueva): reconstruye la base desde los archivos
  ya descargados en `raw/temp/`, sin internet. Sustituye a `files`, que
  se retira — quien la use recibirá el error estándar "option files not
  allowed".

### Datos
- Sin cambios respecto a v8.0.8.

### Correcciones
- DatosAbiertos: la primera corrida en una instalación fresca tronaba con
  r(170) — `mkdir` de Stata no es recursivo y el árbol
  `site/raw/temp/Datos Abiertos/` no se creaba si faltaba algún nivel
  (una instalación nueva no trae ni `site/`). Ahora el árbol se crea
  nivel por nivel antes de usarse.
- DatosAbiertos: las descargas ahora van con `copy` (que acepta URLs en
  cualquier versión de Stata) en lugar de `unzipfile`/`import delimited`
  con URL directa, que no son portables entre versiones — en algunas, el
  intento de zip fallaba al instante sin llegar a la red. Los mensajes de
  la cadena de respaldos ahora incluyen el código de error de Stata para
  poder diagnosticar la causa (conexión, servidor, archivo inexistente).

## [v8.0.8] — 2026-07-10

La cadena del token BIE/INEGI se endurece de punta a punta: SIM.do deja
de tragarse errores reales al cargar el token, profile.do lo carga al
abrir Stata (los investigadores CIEP ya no necesitan correr SIM.do para
usar AccesoBIE), y el mensaje de error de AccesoBIE ahora dice qué hacer
según quién seas. Cero impacto en resultados numéricos.

### Institucional
- SIM.do: el `capture do set_token.do` ciego (que ocultaba errores de un
  token mal configurado) se reemplaza por `confirm file` + `run` sin
  capture. Ahora distingue archivo ausente (aviso amable con el camino:
  copiar `set_token.template.do` a `set_token.do`) de archivo roto (el
  error se ve en su origen). SIM.do sigue siendo autocontenido: carga su
  propio token después del `macro drop _all` del arranque.
- profile.do: carga el token al arranque interactivo con el mismo patrón.
  Si falta, la bienvenida incluye una nota amable con el camino para
  configurarlo — sin error rojo, el arranque no se interrumpe.

### Comandos
- AccesoBIE: mensaje de error mejorado cuando falta el token. Ahora sirve
  a dos audiencias: usuario externo (cómo fijar `global BIE_API_TOKEN` y
  el link del INEGI para obtener token) e investigadores CIEP (correr
  set_token.do o reiniciar Stata). La validación con `exit 198` ya
  existía; solo cambió la redacción. Sin cambios en sintaxis ni
  resultados.

### Datos
- Sin cambios respecto a v8.0.7.

## [v8.0.7] — 2026-07-09

SCN deja de depender de un directorio externo para su intermedio de PIB:
el archivo temporal `raw/temp/basepib.dta` se reemplaza por un `tempfile`
de Stata. En instalaciones donde `raw/temp/` no existía (por ejemplo, un
deployment limpio del servidor web), SCN tronaba con r(603) al intentar
guardar ahí. Cero impacto en resultados numéricos.

### Institucional
- SCN.ado: el intermedio `basepib` ahora vive en un `tempfile` (Stata lo
  crea donde corresponde y lo limpia solo), en lugar de escribir y leer
  `raw/temp/basepib.dta`. Mismo principio que `ensure_asset`: los comandos
  no asumen estado de directorios externo.
- Detectado durante el debugging del primer deploy del motor web v8.0 al
  VPS (2026-07-09); el pipeline de deployment también se endureció en el
  mismo commit (fases de permisos y assets — no afecta a los comandos).

### Comandos
- Sin cambios en sintaxis, opciones ni resultados de SCN. El cambio es
  interno (dónde vive un archivo temporal).

### Datos
- Sin cambios respecto a v8.0.6.

## [v8.0.6] — 2026-07-07

Fixes estéticos coherentes en las gráficas de dos comandos del canon
(PIBDeflactor y SCN): eliminar del eje temporal los años que solo contenían
datos missing, que hacían que las gráficas se vieran incompletas y con
huecos visuales. Cero impacto en resultados numéricos.

### Institucional
- PIBDeflactor.ado (gráfica de Productividad): filtro del `if` y del `tlabel`
  ajustados para mostrar solo años con datos válidos. Bloque `yline` + `text`
  de diferencia 2005-aniofinal preservado comentado (decisión del
  investigador principal para posible reactivación futura).
- SCN.ado (2 gráficas): `xlabel` del eje X ahora llega hasta `latest`
  (último año con datos reales) en lugar de `aniomax` (año máximo teórico).
- SIM.do: cambio de comportamiento default — por defecto muestra gráficas
  (`global nographs` comentado). Antes suprimía gráficas por default.
  Solo afecta a investigadores CIEP internos que corren SIM.do.

### Comandos
- Sin cambios en sintaxis, opciones ni datasets de PIBDeflactor y SCN.
  Los cambios son puramente visuales en las gráficas generadas.

### Datos
- Sin cambios respecto a v8.0.5.

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
  y eliminados. Nueva subsección 2.7 en 02_governance/arquitectura-y-bitacoras.md
  formaliza el principio "la ayuda de comandos vive en .sthlp".
- Manual del investigador movido de manuales/ a help/ (unifica dominio "help").
- README.md corregido: rutas de imágenes rotas apuntan a help/images/; bloques con
  imágenes fantasma eliminados; entrada canónica a la ayuda ahora es help <comando>.
- Hallazgo #3 de 02_governance/historico/auditoria-drift-sthlp.md marcado como resuelto.

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
- Convenciones de Git, versionado y publicación formalizadas en `02_governance/versionado-y-git.md`.

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
