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

## [Unreleased]

Trabajo en `master` sin versión asignada.

## [v8.2.3] — 2026-09-12

**El ciclo de edición diaria de `raw/` gana un modo de trabajo con tres fases:
actuar rápido → declarar → publicar.** Con `$update` cada corrida re-lee los
archivos que Ricardo edita a diario (LIFs, PEFs, CuotasISSSTE) y el candado
bloqueaba en cada edición. Se descartó, tras estresarla, la idea de saltar la
verificación cuando hay `update`: habría dejado ciego al candado en el único
momento en que alguien toca `raw/` a propósito (el incidente del 8-sep no se
habría detectado), habría dejado pasar raw corrupto con `update` en la Carpeta
y en el endpoint, y habría vuelto incoherente `LIF, update` frente a `$update`.
La solución separa intención de mecanismo: un global propio, `rawwip`, que
solo pone quien opera el manifest. Patch nuevo porque toca `ensure_asset`.

### Comandos
- **`ensure_asset.ado` v1.5 — modo WIP de raw.** Con `global rawwip "rawwip"`
  definido y repo local, un SHA distinto **no bloquea**: imprime una línea
  (`[RAW WIP] LIFs.xlsx: SHA difiere del manifest (real 84f5…, 48966 bytes) —
  se usa el archivo local. Decláralo antes del release`) y anota el asset en
  `raw/temp/assets-wip.txt` (nombre, ruta, SHA real, tamaño, SHA esperado,
  hora; última captura gana). Sin el global, la verificación es estricta con
  el mensaje-runbook de v1.4, que ahora menciona el modo. **En modo endpoint
  (sin repo) el global se ignora siempre.** Un archivo ausente se descarga y
  verifica en cualquier modo. Probado en batch contra SITE falso: con el
  global avisa y sigue (`rc=0`, archivo de pendientes escrito); sin él
  bloquea (`r(198)`).
- **`SIM.do` §0.4:** una línea comentada `//global rawwip "rawwip"` junto a
  `$update`, con la instrucción de quitarla para declarar y publicar. Nada
  más de `SIM.do` cambia en este release (el trabajo del día de Ricardo en el
  working tree no se tocó: solo esta línea entró al commit).

### Institucional
- **`publicar.sh` Gate 5 — raw declarado (~6 s).** Antes de cualquier acción
  (también en `--check`): (a) SIM.do no puede tener `global rawwip` activo —
  todo el equipo correría con el candado en modo aviso; (b) **todo asset del
  manifest presente en disco debe coincidir en SHA** — sin esto `publicar.sh`
  subiría al Release un archivo que el propio manifest rechaza y el
  post-verify lo cazaría después de subir ~1.3 GB; (c) lista
  `raw/temp/assets-wip.txt` si quedó de la Fase 1. **Primera corrida del gate
  cazó un asset real sin declarar:** `raw/PEFs/CuotasISSSTE.xlsx` (disco
  `11836aa9…`, 10,858 B; manifest `bffce255…`, 10,838 B) — la edición en
  curso de Ricardo. Queda como **pendiente de Fase 2 antes del tag v8.2.3**.
- **`runbook-actualizar-assets.md` §2c "Modo WIP de raw: las tres fases":**
  la tabla de fases, por qué no se ligó a `update`, y las reglas (solo repo
  local; nunca se commitea activo; el aviso no es opcional; `update` y
  `rawwip` son independientes).
- Se descartó el banner en `profile.do`: el global se define en `SIM.do`,
  después de que `profile.do` corre, así que ahí nunca sería visible. El
  aviso por asset de `ensure_asset` y el Gate 5 cumplen esa función.

### Hallazgo registrado (no corregido aquí; lo resuelve Ricardo)
- **El Release `v8.2.2` sirve 23 de 24 assets: falta `LIFs.xlsx`.** Un
  `gh release delete-asset` sin el `publicar.sh` posterior (o abortado)
  dejó el Release sin el archivo; una máquina virgen hoy no puede construir
  `master/LIF.dta` desde v8.2.2. Como el `LIFs.xlsx` en disco SÍ coincide con
  el manifest, el fix inmediato es `gh release upload v8.2.2 raw/LIFs/LIFs.xlsx`;
  el fix estructural es el release v8.2.3 completo tras declarar CuotasISSSTE.

## [v8.2.2] — 2026-09-09

**Día 2 del Paquete 2027: el flujo de actualización de assets se vuelve
AUTOSERVICIO.** La cadencia de ediciones diarias del `LIFs.xlsx` llegó para
quedarse durante septiembre (rev1 el 8, rev2 y rev3 el 9), y cada una dispara
el candado con razón. La respuesta no es aflojar el candado sino que su
mensaje traiga la secuencia completa para resolver sin ayuda. Como eso toca
un `.ado` publicado (`ensure_asset`), es patch nuevo — no reemplazo de asset
sobre v8.2.1. **Deja atrás la deriva de v8.2.1:** el Release `v8.2.1` sirve
el `LIFs.xlsx` rev2 (`a29070bf…`, reemplazado post-tag) mientras el manifest
del commit etiquetado declara rev1 (`81bef034…`) — válido para un parcial,
pero v8.2.2 nace alineado: tag, manifest y Release con la rev3. El VPS sigue
sin redeploy hasta v8.3.0.

### Datos
- **`raw/LIFs/LIFs.xlsx` rev3 (edición de Ricardo, 2026-09-09):** `sha256`
  `a29070bf…` → **`84f5605c…`**, `size_bytes` 48,877 → **48,966**,
  `data_updated` → 2026-09-09. Gate de contenido: la edición es del propio
  Ricardo. **Corrida `LIF, anio(2027) update` en batch:** el candado pasa,
  `master/LIF.dta` regenerado; **total ILIF 2027 rev3 = 9,156,528.9 mdp =
  23.228% del PIB** (PIB 2027 de `SIM.do` = 39,419,415 mdp). Frente a la
  rev1 del día anterior (9,038,576.6 mdp): OTROSK +1,800.0 mdp y PEMEX
  +116,152.3 mdp; los 13 conceptos restantes idénticos. Nota de registro: el
  brief del ciclo citaba una rev intermedia `d06f4614…` que ya no estaba en
  disco; se declaró la que sí (decisión de Ricardo).

### Comandos
- **`ensure_asset.ado` v1.4 — el mensaje-runbook.** El caso (a) no cambia. El
  caso (b) pasa de "ver el runbook" a la **secuencia completa numerada, con
  comandos pegables y los valores YA CALCULADOS** del archivo real y del
  manifest (SHA nuevo, tamaño, `release_tag`, fecha de hoy, número de
  assets): (1) validar CONTENIDO — si no eres Ricardo, avisar antes; (2) cd
  al clon de DESARROLLO, no la Carpeta, con `git rev-parse --show-toplevel`
  para confirmarlo; (3) shasum/stat con el resultado impreso; (4) las líneas
  exactas del manifest; (5) re-correr; (6) `git add/commit/push`; (7)
  `gh release delete-asset <tag> <archivo> -y || true` +
  `bash 05_scripts/publicar.sh <tag>`; (8) avisar a Ricardo para el pull en
  la Carpeta. Marcado "solo equipo CIEP con el repo"; **en modo endpoint
  (instalación sin repo) el caso (b) se reduce a una línea** porque ahí no
  hay manifest que editar. Se eligió la variante completa sobre la mínima
  (pasos 1–5 + referencia): un `errprintln` no tiene límite práctico, el
  mensaje es ~30 líneas, y la mitad del valor está en imprimir los valores
  calculados — con la variante mínima el operador tendría que abrir el
  runbook precisamente para los pasos que más se equivocan (borrar el asset
  del Release antes de re-publicar). Verificado contra un SITE falso con el
  manifest de rev2: reproduce el bloqueo de hoy con los valores de rev3 y
  sale `r(198)`. Refactor: el mensaje vive en `_sha_mismatch_msg()`.

### Institucional
- **Guard de identidad de clon en `publicar.sh`.** El 2026-09-08 se lanzó
  `publicar.sh` sin querer desde la Carpeta del Simulador para
  investigadores — también es un clon git, así que `git rev-parse` no la
  distingue — y el pre-chequeo de assets falló de forma confusa. Ahora, antes
  de cualquier gate (incluido `--check`), el script exige el marker
  gitignored **`.clon-desarrollo`** en la raíz; si falta, aborta con "Estás
  en `<ruta>`…" y, si la ruta termina en `Dropbox-CIEP/SimuladorCIEP`, lo
  nombra: "Esta ruta es la Carpeta: aquí NO se publica ni se opera git
  (§6.7)". El marker no viaja por git, así que la Carpeta nunca lo tiene; se
  crea una vez con `touch .clon-desarrollo` (creado en el clon de desarrollo
  de Ricardo en este ciclo). `.gitignore` y `verify_gitignore.sh` lo cubren
  (**93/93, 0 FAILS**). Probado en un clon temporal en ruta genérica y en
  una ruta `…/Dropbox-CIEP/SimuladorCIEP`.
- **`runbook-actualizar-assets.md` §2b "Comandos exactos":** la misma
  secuencia parametrizada (`<archivo>`, `<nombre>`, `<tag>`), pegable,
  incluida la prueba del candado en batch sin abrir Stata; la trampa de los
  dos clones documentada con el guard; y la regla del paso 7: `publicar.sh`
  es idempotente por nombre, por eso el `delete-asset` va antes;
  **reemplazar un asset en un Release existente es válido para un parcial**
  (deriva conocida y aceptada durante el Paquete) y **la reconciliación
  formal llega con el minor v8.3.0**; cuando el cambio toca código
  distribuido, se corta patch nuevo. §3 gana "nunca commitear ni publicar
  desde la Carpeta".

## [v8.2.1] — 2026-09-08

**Release PARCIAL del Paquete 2027: el `LIFs.xlsx` del data sidecar carga la
ILIF 2027 y el manifest la declara; el resto de las bases 2027 (PPEF, CGPE)
llega en v8.3.0, el release formal.** Es un patch porque lo que cambia de lo
distribuido es un asset de datos y el mensaje de un `.ado` de
infraestructura; el motor, el sitio y el endpoint no cambian de
comportamiento. **El VPS NO se redeploya en este parcial** — el web sigue
sirviendo el PE2026 correctamente hasta v8.3.0.

**GATE DE CONTENIDO PENDIENTE (registrado explícitamente):** el SHA-256 del
`LIFs.xlsx` 2027 quedó declarado en el manifest ANTES de que Ricardo validara
con el ojo que la ILIF 2027 está bien vaciada. El hash certifica identidad
del archivo, no corrección de los datos. El tag `v8.2.1` y `publicar.sh`
(que re-sube los 24 assets al Release con el LIFs nuevo) quedan bloqueados
hasta que Ricardo confirme ese gate; si el contenido falla, el fix es un
LIFs corregido + SHA nuevo, no revertir este release.

### Datos
- **`raw/LIFs/LIFs.xlsx` → ILIF 2027 (actualización parcial del Paquete
  2027).** Vaciado por el equipo CIEP el 2026-09-08 en su máquina.
  `manifest.json`: `sha256` `a145d8f5…` → `81bef034…`, `size_bytes`
  47,910 → 48,875, `data_updated` 2026-07-19 → 2026-09-08. Corrección en
  este ciclo: el commit `3f33f8a` había declarado el SHA nuevo con el tamaño
  viejo (47,910); `ensure_asset` no valida tamaño, así que pasaba, pero el
  manifest quedaba a medias.
- **El candado contuvo el incidente — primer evento multi-usuario del repo.**
  `ensure_asset` detuvo la corrida en la máquina de los compañeros ("SHA real
  `81bef034…` vs manifest `a145d8f5…`"): una modificación legítima pero no
  declarada. Es exactamente lo que el candado existe para detener. Lo que
  falló fue el mensaje (siguiente sección) y la ausencia de un procedimiento
  escrito para el equipo (runbook nuevo).

### Comandos
- **`ensure_asset.ado` v1.3 — el error de SHA distingue los dos casos.** El
  mensaje anterior ("Archivo corrupto o desactualizado. Bórralo y vuelve a
  correr") es correcto para corrupción y DESTRUCTIVO para actualización
  intencional: borrar re-descarga el archivo VIEJO del Release y pisa los
  datos nuevos. El mensaje nuevo enumera (a) si NO modificaste el archivo:
  bórralo y re-corre; (b) si lo actualizaste a propósito: el manifest debe
  declararlo (shasum, `size_bytes`, `data_updated`), ver el runbook, y **NO
  borres el archivo**. Añade la ruta del archivo al mensaje. Verificado
  contra un SITE falso con manifest desalineado: reproduce el incidente
  palabra por palabra y sale con `r(198)`. Sin cambios de comportamiento:
  misma verificación, misma descarga, mismo código de error.

### Institucional
- **`02_governance/runbook-actualizar-assets.md` (nuevo, una página, para el
  equipo):** qué es el manifest y por qué existe el candado; el flujo en
  diez pasos (avisar → Ricardo valida CONTENIDO → shasum + size → manifest
  → `data_updated` → probar → commit + push → release → pull en la Carpeta
  de investigadores); qué NUNCA hacer (borrar-y-recorrer tras actualizar;
  manifest a medias; renombrar el asset); y la regla de la carpeta
  compartida: **git ahí lo opera UNA sola persona** (§6.7 de arquitectura).
- **Regla nueva de operación: un ciclo, un operador por juego de archivos.**
  Durante la auditoría de este ciclo (delegado), `manifest.json` y `SIM.do`
  cambiaron en el working tree a las 20:57–20:58 sin aviso: era Ricardo
  ejecutando el desbloqueo a mano en paralelo (commit `3f33f8a`). Near-miss
  sin daño — pero dos manos sobre los mismos archivos sin declararlo es el
  mismo incidente que el candado acaba de contener, sin candado. Si Ricardo
  va a editar a mano archivos de un ciclo delegado, se declara antes.
  Registrada en el runbook §4.
- **Rename `04_simuladorfiscal.ciep.mx/` → `04_1_simuladorfiscal.ciep.mx/`
  (commit `360ebae` del 2026-09-08), documentado aquí porque no lo estaba
  en ningún lado.** Renumeración, no colisión: la semilla
  `04_1_paqueteeconomico.ciep.mx/` se RETIRÓ del repo hacia
  `../CIEP_Micrositios/Paquete Económico/` (hermana del repo, con
  `DEPLOY-semilla-04_1-legado.md` como acta; el render de los nodos la siguió
  ahí — `scalarjson.ado:70`, `nodo-deuda.do`, `portada.do`, `verify_nodo.sh`
  ya apuntan a ese destino), lo que liberó el slot `04_1` para el sitio del
  Simulador. Mapa `04_*` vigente: `04_1_simuladorfiscal.ciep.mx/`,
  `04_2_documentos_latex/`, `04_4_libro.ciep.mx/`, `04_5_ciep.mx/` (04_3
  cerrado el 2026-08-02). **Fallout censado y cerrado en este release:**
  `05_scripts/publicar-vps-credentials.template.sh` (`LOCAL_SITE_ROOT` a la
  ruta nueva, con nota para credenciales anteriores);
  `05_scripts/verify_gitignore.sh` (93/94 con 1 FAIL → **92/92, 0 FAILS**:
  la ruta nueva en las 2 aserciones del sitio, retiro de las 5 aserciones
  fantasma sobre `04_1_paqueteeconomico…`, y 3 aserciones nuevas —
  `config.php` del sitio ignorado, plantilla VPS versionada, `health.php`
  versionado); `.gitignore` (reglas muertas de `04_1_paqueteeconomico…`
  retiradas con nota; el clon del sitio comentado en su sección); docs vivas
  `arquitectura-y-bitacoras.md` §2.8 y D.1, `verificacion-estado-repo.md`,
  `reporte-inventario-paquete2027.md`, `manual-investigador-ciep.md`
  (tabla "no borres" con el mapa 04_* completo). Las bitácoras y
  `reconocimiento-vps.md` (2026-07-09) conservan la ruta vieja como
  histórico. **Pendiente de Ricardo:** la línea 23 de su
  `publicar-vps-credentials.sh` (gitignored) sigue en la ruta vieja — el
  Gate 5 de `publicar-vps.sh` aborta con `die` si no existe, así que un
  deploy no puede subir vacío, pero tampoco puede correr hasta editarla.

### Correcciones
- **`SIM.do`: el estado Pre-CGPE 2027 y el freno declarado.** El commit
  `4b047ae` subió `aniovp` 2026→2027, actualizó los inputs macro
  (`pib2027` 2.1→2.4, `def2026` 4.8→3.8, `def2027` 4.2→4.0, `inf2026`
  3.54→3.8, `inf2027` 3.0→3.2; filas 2025 retiradas), descomentó §2.4
  `PIBDeflactor` y dejó un `exit` sin comentario tras él; `3f33f8a` subió
  `anioPE` 2026→2027 y retiró el `exit`. **Corrida completa de
  verificación (2026-09-08, batch, `$id` scratch, `$export` a scratch, SIN
  `update`, `master/` intacto):** §2.4 PIBDeflactor 2027, §2.5 SCN 2027 y
  §4.1–4.6 (LIF 2027 con la ILIF nueva — 9,038,576.6 mdp, 22.641% del PIB —
  ISR, IMSS/ISSSTE, IVA, IEPS) pasan; **§4.7 `TasasEfectivas, anio(2027)
  enigh` truena con `r(601)`**: no existe `master/perfiles2027.dta` (§3
  Hogares está comentado, así que nadie lo construye) y el fallback de
  `TasasEfectivas.ado:308` corre `"<site>/PerfilesSim.do"` — ruta muerta
  desde la reorganización del 2026-07-04 (el archivo vive en
  `01_modulos/PerfilesSim.do`). **Fallback aprobado aplicado:** el `exit`
  vuelve a su posición tras `PIBDeflactor`, ahora DECLARADO ("WIP Pre-CGPE
  2027: la cadena termina aquí A PROPÓSITO hasta v8.3.0") con el diagnóstico
  en el comentario. Verificado: SIM.do corre limpio hasta el freno. El mix
  `aniovp = anioPE = 2027` con bases 2026 NO es estado válido de corrida
  completa; lo es de la cadena §0–§2.4.

### Candidatos registrados (no corregidos en este ciclo)
- **Dos rutas muertas a `PerfilesSim.do` en el motor**, destapadas por el
  mix: `TasasEfectivas.ado:308` (`<site>/PerfilesSim.do`) y `GastoPC.ado:74`
  (`<site>/01_modules/profiles/PerfilesSim.do`, anterior incluso a la
  reorganización). Ambas son fallbacks que solo corren cuando falta
  `master/perfiles<anio>.dta`, por eso sobrevivieron desde julio. Van en el
  ciclo v8.3.0 junto con la construcción de `perfiles2027.dta`.
- **La opción de mover el freno a antes de §4.7** (conservando SCN 2027 y
  LIF 2027 verificados) queda para decisión de Ricardo; este release respeta
  el fallback aprobado.

### Trabajo acumulado en `master` desde v8.2.0 (nodos y micrositio)

Lo que sigue estaba registrado bajo `[Unreleased]` y queda incluido en el tag
`v8.2.1` porque el tag es un punto de `master`. **Nada de esto cambia el
paquete distribuido** (`05_scripts/manifest-endpoint.toml` no incluye
`scalarjson.ado`, igual que nunca incluyó `scalarlatex.ado`): el endpoint
público y el VPS corren el mismo motor que en v8.2.0. Los nodos se publican
en su propio ciclo.

### Institucional
- **Primer corte vertical de un nodo: un número sale de Stata y llega a una
  página sin que nadie lo teclee.** Nodo de deuda pública, año de referencia
  2026. Tres piezas versionadas — el exportador (`scalarjson.ado`), el driver
  (`01_modulos/nodos/nodo-deuda.do`) y la página
  (`01_modulos/nodos/nodo-deuda.html`) — y un destino de render generado,
  `04_3_nodos/`, con el contrato (`statajson_deuda-publica.json`) y la copia
  servible de la página.
- **`04_3_nodos/` se ignora (decisión de Ricardo, 2026-08-01).** Es un destino
  de render desechable, reconstruible con una corrida: el mismo estatus que
  los `statalatex_*.tex` de `06_libro/images`, que tampoco se versionan. Se
  versiona lo que PRODUCE el artefacto, no el artefacto. **Consecuencia
  registrada:** el JSON no tiene historial en git, así que su diff entre
  cortes no es auditable desde el repo — para comparar en septiembre hay que
  guardar el corte anterior a mano antes de re-exportar.
- **`05_scripts/verify_nodo.sh`:** seis reglas con exit ≠ 0. (1) la página no
  contiene literales numéricos fuera de `<style>` — el verificador anti-fósil,
  la clase que este repo acaba de extinguir en v1.42/v1.44 y v8.2.0; (2)
  procedencia completa en el JSON; (3) exportación determinista, comprobada
  corriendo Stata dos veces (no se salta en silencio: sin Stata y sin
  `--sin-stata` sale con exit 2); (4) sin huecos de año no declarados; (5)
  toda serie declara unidad y formato; (6) la raíz no contiene `.md`.
  Audita la FUENTE de la página (`01_modulos/nodos/`), no la copia de render:
  auditar copias es auditar el pasado. Si el contrato no existe todavía (clone
  limpio), sale con exit 2 explicando cómo producirlo.
- **Regla nueva: la raíz del repo no contiene archivos `.md`.** La
  documentación vive en `02_governance/` o `03_help/`. Excepción única y
  confirmada: `README.md` (portada convencional de GitHub; ya tratada como
  institucional por `verify_gitignore.sh:180`). Movidos en este ciclo:
  `plan-integracion-paquete2027.md`, `reporte-inventario-paquete2027.md` y
  `verificacion-estado-repo.md` → `02_governance/` (cero referencias en el
  repo, el movimiento no rompe ninguna ruta).
- **Mapa 04_\* (2026-08-02): cada sitio web tiene su semilla local con
  anatomía estándar** — `public_html/` (código desplegable) + `db/` (dumps
  fechados) + `local/` (utilería) + `DEPLOY.md`. Estado: 04_1
  paqueteeconomico corre en `localhost:8892` (BD `paqueteeconomico_local`),
  04_4 libro corre en `localhost:8888` (BD `libro_local`), 04_5 ciep.mx tiene
  BD importada y código pendiente de reorganizar a `public_html/`; 04_2 es el
  archivo histórico LaTeX. Todas gitignored; ningún `wp-config.php`,
  `wp-salt.php` ni dump está trackeado (verificado con `git ls-files`).
  Residuo eliminado: `wp-admin/`/`wp-content/` sueltas en la raíz de 04_1
  (placeholders de 0 bytes, sobras de la reorganización).
- **Regla de dumps fechados (2026-08-02, aplica a toda semilla):** toda BD
  activada en local deja su dump fechado en el `db/` de su semilla
  (`<base>-AAAAMMDD.sql[.gz]`). Cumplen 04_1 (`emepykgvhz-20260802.sql`) y
  04_4 (`libro_local-20260802.sql.gz`, generado en este ciclo); 04_5 cuando
  se active. Los dumps contienen datos reales (hashes de usuarios, pedidos
  WooCommerce): NUNCA van a git ni salen de la máquina.
- **Cierre de `04_3_nodos/` (decisión de Ricardo, 2026-08-02):** el destino
  de render de los nodos se muda BAJO EL DOCROOT del WordPress local del
  Paquete — `04_1_…/public_html/nodos/` (patrón 6yt5ppa3hb: estáticos
  servidos junto al sitio, jamás dentro de Elementor). El nodo de deuda es
  visible en el MISMO localhost del sitio:
  `http://localhost:8892/nodos/nodo-deuda.html`. Piezas movidas: default de
  `scalarjson`, driver (mkdir antes de exportar + copia servible),
  `verify_nodo.sh` (todas las reglas pasan contra el destino nuevo, exit 0) y
  `nodo-deuda-vista-previa.md`; `.gitignore` gana el cinturón explícito con
  sus aserciones. `04_3_nodos/` se eliminó tras mover el corte vigente
  (byte-idéntico). El estatus no cambia: render desechable, sin historial en
  git — el corolario de guardar el corte anterior a mano antes de re-exportar
  sigue vigente.
- **El "header doble" del sitio local NO es un defecto del local (auditado
  2026-08-02):** el header rosa del tema (hello-elementor default) aparece
  también en producción. Evidencia: el HTML de producción emite
  `<header id="site-header">` con y sin el caché de WP Rocket, las 17 hojas
  CSS son byte-idénticas entre producción y local y ninguna lo oculta, y los
  screenshots headless (Chrome 151) de producción y de `:8892` salen
  byte-idénticos. La paridad local–producción está demostrada; quitar el
  header rosa es una decisión de DISEÑO que aplicaría a ambos lados, y las
  opciones quedaron documentadas en el `DEPLOY.md` de la semilla.
  **Segunda verificación y parche local (mismo día):** re-verificado en vivo
  con cache-buster — producción HOY muestra el header rosa; NO existe
  mecanismo de producción que emular. Por decisión de Ricardo el local lo
  oculta con CSS del Customizer (`.site-header { display: none; }`, aplicado
  vía `wp_update_custom_css_post`, vive en la BD local); el `DEPLOY.md` lo
  registra como PARCHE LOCAL con la instrucción explícita de NO portarlo en
  deploys de código (es estado de BD y lleva su propio gate).
- **La página del nodo de deuda adopta el lenguaje ultra-austero (variante A
  de la ronda de estilo, veredicto de Ricardo 2026-08-02):** título, la
  tabla y el sello; la costura CGPE y la procedencia viven en un `<details>`
  plegado de una línea; cero texto explicativo suelto. La regla 1 del
  verificador cazó la fecha de la ronda en un comentario del `<script>`
  durante la promoción — el anti-fósil funcionando contra su propio autor.
- **La portada del Paquete: la ecuación fundamental con cifras del motor
  (`/nodos/` en el localhost del sitio).** Referencia CONCEPTUAL: la sección
  "La ecuación fundamental" de libro.ciep.mx (tres términos con jerarquía
  visual y operadores); re-implementada al estilo nodo, no copiada: aquí los
  términos llevan el número del motor. `01_modulos/nodos/portada.do` corre
  LIF y PEF y deriva EXACTAMENTE tres cosas — ingresos = suma de las 7
  familias del display B de LIF (divResumido, sin la familia Deuda); gasto =
  suma de las 10 divisiones del display B de PEF (Resumido, Cuotas ISSSTE
  negativa), verificada contra `r(Gasto_netoPIB)`; financiamiento = cierre
  por construcción (gasto − ingresos). La familia Deuda de la LIF viaja como
  REFERENCIA con su brecha declarada contra el cierre (LIF y PEF no
  coinciden al centavo; la brecha se publica en vez de esconderse). Capa
  CGPE declarada con el patrón del nodo (RFSP/ingresos/gasto de las matrices
  de `SIM.do:361-405`; sin los globals de política, `disponible:false`).
  Esquema propio `ciep.nodo.portada/v1`; página en el lenguaje A con hover
  (desktop) / tap (móvil) para desagregar cada término, el término
  Financiamiento enlaza al nodo de deuda, y la línea personal (año de
  nacimiento) lee el per cápita real del CONTRATO DEL NODO — la portada no
  calcula ni inventa. La copia servible se llama `index.html`: `/nodos/` ES
  la portada. `router.php` local sirve `index.html` de directorios estáticos
  antes de caer a WordPress (equivalente del `DirectoryIndex` de producción).
- **Precisión declarada de la portada: `%20.12g` para % del PIB, `%25.17g`
  para montos.** Los agregados de LIF/PEF no son bit-estables entre corridas
  (sorts con empates no estables mueven el último ulp de la suma — la regla
  3 del verificador lo cazó en la primera corrida doble); 12 dígitos
  significativos publican el dato sin el ruido. Los montos son enteros
  exactos en double y conservan round-trip completo. El nodo de deuda sigue
  en `%25.17g` porque lee un `.dta` congelado, que sí es bit-estable.
- **`verify_nodo.sh` extendido a la portada:** `bash 05_scripts/verify_nodo.sh
  portada`. Reglas 1-3 y 6 idénticas (la 3 corre el driver dos veces: LIF y
  PEF incluidos); las reglas 4/5 se sustituyen por sus equivalentes
  estructurales — cierre de la ecuación (montos exactos; % PIB a la
  precisión emitida), sumas de desagregaciones contra los
  totales, brecha LIF declarada, y unidades/formatos/fuentes por término más
  procedencia de capas. Ambos nodos: todas las reglas pasan, exit 0.
- **La portada se vuelve MULTI-AÑO: selector 2013–2026 (v2.0 del driver,
  mismo esquema `ciep.nodo.portada/v1`).** Censo previo (2026-08-02): los 14
  años corren completos y las etiquetas son ESTABLES — las mismas 7 familias
  de ingreso y 10 divisiones de gasto en todos los años, así que el
  blueprint del driver es único, sin ramas por año. El bloque `ecuacion` se
  extiende a `ecuaciones[]` por año SIN subir a v2: contrato pre-publicación
  sin consumidor externo (decisión documentada en el header del driver: "v2
  solo cuando exista consumidor externo publicado"). **`tipo_dato` por año Y
  POR LADO, leído de los datos, no de una tabla tecleada:** gasto = qué
  columna trae datos en `master/PEF.dta` según la regla del motor
  (`PEF.ado:1295-97`: ejercido → aprobado → proyecto — 2013-2025 ejercido/CP,
  2026 aprobado/PEF); ingresos = mes máximo observado en `master/LIF.dta`
  (12 → observado; menor → ley/ILIF — 2026). La página lo muestra como marca
  discreta bajo el selector ("gasto: aprobado · ingresos: ley"), sin
  párrafos. La capa CGPE viaja SOLO en el año de referencia. Deep-link por
  año: `/nodos/#2016`. Tiempo de corrida declarado en el header del driver:
  ~2 min el export (PEF ~8.6 s × 14 años), ~5 min la regla 3.
- **Dos lecciones de precisión más, cazadas por las reglas 3 y 4 en la
  primera corrida multi-año:** (a) los MONTOS de Cuenta Pública traen
  centavos y tampoco son bit-estables entre corridas — los montos ahora
  viajan en MILLONES DE MXN ENTEROS (`round(x/1e6)`), seis órdenes por
  encima del ruido, y el financiamiento se deriva DESPUÉS del redondeo, así
  que el cierre en montos es exacto en enteros; los % del PIB bajan a
  `%16.9g` (9 dígitos: ~5 órdenes de margen sobre el ruido, y el display usa
  3 decimales). (b) `local x = exp` guarda el resultado como TEXTO con menos
  dígitos — el cierre por construcción perdía los centavos al pasar por
  locals; toda la captura del driver vive ahora en scalars (`__prt*`,
  limpiados al final). La regla 4 verifica el cierre POR AÑO en los 14 años.
- **Integración (a) ejecutada en el WP local (2026-08-02):** item de menú
  "La ecuación" → `/nodos/` en `menu-paquete` (posición 1, vía
  `wp menu item add-custom`). El hero quedó DESCARTADO por escrito (regla:
  nada de los nodos vive dentro de Elementor). Es estado de BD: documentado
  en el `DEPLOY.md` de la semilla como PENDIENTE DE PORTAR con el comando
  exacto (mismo `wp` por SSH + purga de WP Rocket, prerrequisito: `/nodos/`
  desplegada).
- **Tercer nodo: los indicadores de los hashtags de ciep.mx (2026-08-03,
  esquema `ciep.nodo.indicadores/v1`).** Los 26 hashtags del home de ciep.mx
  son anclas a `/category/<slug>/` — el slug es la llave del censo: **13
  disponibles y 11 declarados no disponibles con su razón** (FiscalGap
  registra tasas y no niveles; y 7 hashtags sin correspondencia hoy). Un
  **decorador estático** (`indicadores-decorador.js`, auditado por la regla 1
  como cualquier página de nodo) lee el contrato y añade la cifra al ancla
  cuyo slug tiene dato — los demás quedan intactos; se encola con un
  **mu-plugin de una línea** (`indicadores-muplugin.php`, fuente versionada;
  instalado como `wp-content/mu-plugins/ciep-indicadores.php` en la semilla:
  viaja con el rsync, no vive en la BD). WordPress jamás guarda un número; la
  actualización mensual es re-exportar el JSON y re-publicar un archivo.
- **Indicadores v2 (mismo día, decisión de Ricardo tras ver v1): ÚNICAMENTE
  datos abiertos como lo oficial, con el último mes como corte de cada
  concepto.** v1 usaba LIF/PEF anual (ley/aprobado); v2 mapea cada slug a su
  serie de SHCP Estadísticas Oportunas vía `DatosAbiertos.ado` con claves
  verificadas contra `master/DatosAbiertos.dta` (XAB ingresos, XAC gasto
  neto pagado, XAB11 tributarios, XAB12 no tributarios, XDA12 contribuciones
  SS, XAC21 costo financiero, XOA0135 pensiones, XOA0417/XOA0419 funciones
  Salud/Educación — los frames viejos XOA0316/XOA0315 ya no traen 2026 y el
  guard truena si una clave se queda sin dato; `energia` = balance XAB21 −
  XOA0425; `endeudamiento` = XAC − XAB, el cierre de siempre). **Convención
  de % PIB del MOTOR, no inventada:** flujos con la opción `proyeccion` de
  `DatosAbiertos.ado` (acumulado observado anualizado con `acum_prom` ÷ PIB
  anual), `tipo_dato = proyectado_observado`; el saldo de deuda no se
  proyecta (`observado_mensual`). Todos los conceptos cortan en **mayo de
  2026**; guard de cortes mixtos incluido. **Ronda visual aplicada:** junto
  al hashtag SOLO el número y el `%` (columna angosta), todo en blanco con
  sombra sutil; la unidad y el corte NO se repiten — viven una sola vez en
  una nota fija en la esquina superior derecha, leída del contrato; el
  detalle por concepto (clave SHCP, fuente, tipo de dato) va al tooltip.
  La regla 1 volvió a cazar dos fósiles del propio autor durante la ronda
  (una fecha en comentario y un `12px/1.4`). `verify_nodo.sh indicadores`:
  reglas 4/5 propias (cierre del endeudamiento re-derivado del contrato,
  `ingresos == ingresospublicos`, slugs únicos, disponibles con
  pib/corte/tipo_dato/fuente y ausentes con razón); los TRES nodos en exit 0.
- **El decorador gana el conteo de investigaciones por hashtag (2026-08-04):**
  dato VIVO de la API REST de WordPress (`/wp-json/wp/v2/categories`, campo
  `count`), pintado junto a la cifra del motor (`#Salud 3.1% (122)`); los
  hashtags sin cifra llevan solo su conteo. Nada tecleado: si la API falla,
  no hay conteos y la página queda tal cual. El decorador ahora exige que el
  ancla SEA un hashtag (texto que inicia con `#`) para no decorar menú/footer.
  Los cambios de LAYOUT del home de ciep.mx (hero 2/3 + destacadas 1/3
  vertical cuadrada a la altura del hero; Venn a columna completa con offsets
  escalados ×1.39; las 3 secciones de /investigaciones insertadas bajo el
  Venn con filtros colapsados a 5 items + "Más…", 9 por página, ancla
  `#investigaciones`, y el botón "Investigaciones" fuera del menú del header)
  viven en la BD LOCAL (`_elementor_data` + menús), documentados en el
  DEPLOY.md de la semilla con su hallazgo crítico: el auto-update del primer
  arranque subió Elementor a 3.35.5 y desactivó elementor-pro (por eso el
  widget de posts salía vacío); producción sirve Elementor 4.2.1 — NO rsync
  de plugins sin reconciliar versiones.

### Comandos
- **`scalarjson.ado` v1.0.0 — exportador de nodos a JSON, hermano de SOLO
  LECTURA de `scalarlatex`.** Espeja tres pasos y solo tres: enumeración de
  escalares vivos, mapa nombre→tipo desde `$scalarlatex_reg` con last-wins, y
  el catálogo de tipos. NO espeja el dígitos→letras (restricción de nombres de
  macro de LaTeX) ni el alias. NO toca `scalarlatex`, ni el registro, ni
  `02_governance/scalarlatex-baseline.txt` (no lo lee siquiera: ese baseline
  gobierna la cobertura del libro, no la de un nodo). **NO CALCULA:** todo
  valor que escribe ya existe en el registro o en el dataset de serie que
  recibe; lo que no existe es un faltante declarado. Donde `scalarlatex`
  escribe strings ya formateados, `scalarjson` escribe NÚMEROS de precisión
  completa más `formato_sugerido`/`divisor_sugerido` — el formato es una
  sugerencia de presentación, no el dato.
- **`SHRFSP.ado`:** la invocación del nodo entra al bloque `$textbook`
  existente, junto a `scalarlatex`, con la misma clausura (lección v8.0.11).
  Tres guards en serie: `$textbook` (solo-repo) + `capture which scalarjson` +
  `capture confirm file` del driver. Degradación silenciosa si falta
  cualquiera. `scalarjson.ado` NO se publica al endpoint: en el VPS el comando
  no existe y el bloque solo imprime la nota.
- **`scalarjson.ado` v1.1 — el contrato lleva el espejo del display.** Opción
  `tabla()` nueva y dos bloques nuevos en el JSON: `presentacion` (lo que la
  página necesita para renderizar y no es una cifra: etiqueta de moneda,
  escala, encabezados y formatos de columna, denominadores por bloque) y
  `tabla` (la ESTRUCTURA del display que la página espeja: qué filas, en qué
  orden, con qué etiqueta, prefijo, familia y énfasis). Viven en el contrato
  y no en la página para que la tabla del sitio no pueda divergir en silencio
  de la que imprime el módulo en Stata. En el driver, los 72 escalares salen
  de la MISMA tabla (19 filas, 5 bloques): contrato y display no pueden
  desincronizarse porque no hay dos listas que mantener. La página
  (`nodo-deuda.html`) se reescribió como espejo del display.
- **`scalarjson` escribe números con `%25.17g` (antes `%22.15g`).** 17
  dígitos significativos garantizan round-trip exacto de un double IEEE 754;
  con 15, el JSON perdía el último bit y la página redondeaba a un peso de
  distancia del display de Stata (`SHRFSPMonto` …533 vs …534).

### Correcciones
- **`scalarjson` sanea backticks al escribir (clase: inyección de macro desde
  datos).** Las líneas de datos de `input` no expanden macros, así que un
  `` `anioref' `` quedó guardado literal en un `.dta` de metadatos — y al
  escribirse desde `scalarjson` se re-expandió contra las **locales de ese
  programa**, saliendo como `2026` en el JSON. Texto de un dataset
  ejecutándose como código. `_sjkv`/`_sjesc` eliminan `char(96)` antes de
  escribir; los drivers construyen todo lo dinámico con `replace`, que sí
  expande. (De paso, dos gotchas de Stata registrados: un backtick sin cerrar
  dentro de un comentario se traga el resto del archivo sin error, y `\` no
  puede viajar por macro a un literal entrecomillado — escapa la expansión y
  truena con `r(198)`; el escape JSON usa `char(92)`/`char(34)` dentro de la
  expresión.)

### Correcciones — escenario de política fiscal
- **`SIM.do:389`: el mapeo de columnas le daba a cada año la columna del año
  ANTERIOR, y nunca leía la columna 2031.** Las matrices de política fiscal
  (`SIM.do:361-405`) tienen 7 columnas rotuladas 2025-2031, pero el
  `forvalues k = 2026(1)2031` calculaba `j = k - 2026 + 1`: 2026 leía la
  columna 2025, 2027 la 2026, y así hasta 2031, que leía la 2030 — la columna
  2031 quedaba muerta. Corregido a `j = k - 2025 + 1`. Una línea.
- **El rótulo estaba bien y el motor mal; el fósil tecleado fue el testigo.**
  `04_2_documentos_latex/PE2026/…/3_Deuda/deuda.tex:39` —cifras tecleadas a
  mano, sin getters— dice *"4.1% del PIB"* tanto para el costo financiero
  como para el endeudamiento neto de 2026. El motor producía 3.8 y 4.30. Tras
  el fix produce **4.100 y 4.100**: coinciden con el documento publicado. El
  número que un humano escribió a mano validó al motor, no al revés.
- **Test dorado (2 corridas del flujo textbook, `$export` a scratch, mismo
  `master/`):** de 110 getters de `statalatex_shrfsp.tex`, **51 cambian y 59
  no**; cero getters nuevos, cero perdidos. Los 51 caen todos en la clase
  predicha por el triage: `CostoFinanciero*` (3.800→4.100), `RFSP*`
  (4.300→4.100), `SHRFSPInterno*` (40.500→41.500), `SHRFSPExterno*`
  (12.100→11.000), `rfspPIDIREGAS*`/`rfspIPAB*` (0.150→0.100),
  `rfspAdecuaciones*` (0.400→0.300), `SHRFSPLIF` (240.2→233.8) y las familias
  `Deuda*` por el tipo de cambio (19.6→18.9). Quedan intactos —como se
  predijo— `SHRFSP{PIB,Monto,PC,PorTot}` (52.6 en ambas columnas),
  `SHRFSPlast*`, `rfspBalance{PIB,Monto}` y los `rfsp*` en cero.
- **Detectado por el nodo de deuda:** el patrón anti-fósil cazando su primer
  bug de motor. El nodo obliga a declarar de dónde sale cada número, y al
  declarar la procedencia de la capa de escenario (`SIM.do:362 -> global
  shrfsp<año>`) el mapeo quedó a la vista.
- **Archivos del libro que Ricardo debe regenerar y repasar en prosa:**
  `06_libro/images/statalatex_{shrfsp,perfiles,fiscalgap}.tex` (el registro es
  global-acumulado: los tres cargan escalares de SHRFSP) y los capítulos que
  los consumen, `06_libro/4_Balance/costofinanciero.tex` y
  `costofinancieroi.tex`.

### Candidatos registrados (no corregidos en este ciclo)
- **`master/SHRFSP.dta` carga derivados 1990-1999 contaminados.** Esas filas
  traen `unidad_de_medida == "Dólares"`: `monto_pc` son dólares per cápita
  deflactados con un índice de precios MEXICANO y `monto_pib` es un cociente
  dólares/pesos (0.23% del PIB en 1999). El saldo en pesos simplemente no
  existe antes de 2000. El nodo lo esquiva con piso 2000 + un guard de unidad
  que verifica el piso en cada corrida; la limpieza a missing explícito
  corresponde a un ciclo futuro de `UpdateSHRFSP`.
- **La columna "Total" de la matriz `rfsp` de `SIM.do` es decorativa.**
  `global rfsp<año>` se define en `SIM.do:393` y no lo consume nadie:
  `SHRFSP.ado:131` recalcula `rfsp` como la suma de sus siete componentes.

## [v8.2.0] — 2026-07-19

**Cambio de metodología del PC de salud: el denominador pasa de
hogares-equivalentes a PERSONAS para mantener consistencia con los demás
rubros del gasto.** Y unificación de los conteos de población del sitio: los
19 `data-pop`/columnas quemados en el HTML migran a viajar por `output.txt`
(bloques nuevos `GASTOSPOB1`/`GASTOSPOB2`).

### Comandos
- `GastoPC.ado`: conteos de PERSONAS para display/PC/web (matriz `SaludPer`,
  ENIGH 2024 con el factor de perfiles ya proyectado a población CONAPO del
  año PE — reescalado calculado en la corrida, no hardcodeado). Definiciones
  documentadas en el código: SSA/Inversión/Total = población CONAPO
  (coherente con Energía/Cultura); IMSS `inst_1`; ISSSTE `inst_2`;
  Pemex/ISSFAM `inst_4` partido con el ancla administrativa 602513/1169476;
  otros `inst_6`; IMSS-Bienestar = residuo sin seguridad social, con `inst_3`
  (ISSSTE estatal, ~2.0M personas) DENTRO del residuo por continuidad
  metodológica — candidato de refinamiento registrado en bitácora. La doble
  afiliación declarada (0.7%) se cuenta en AMBAS instituciones, como en los
  registros administrativos. Los `*Pob`/`*PC` de salud pasan a personas
  (IMSS: 12,091,141 hogares-eq → 55,311,028 personas; PC 43,008 → 9,402);
  los `*PIB` no cambian.
- **Desacople de la incidencia**: la imputación por persona
  (`Salud = Σ PC×benef_*`) conserva el cociente hogares-equivalentes como
  tempname scalar interno (`*PCinc`, double exacto — un local stringifica y
  mueve el último bit); `benef_*` INTACTOS. Guardián: Sankeys y deciles
  byte-idénticos.
- `01_modulos/output.do`: bloques `GASTOSPOB1`/`GASTOSPOB2` con los 42 conteos
  (indexado espejo de `GASTOSPC`; en DOS bloques porque el linesize máximo de
  Stata (255) partiría la línea con `> ` y `checkStataStatus.php` no maneja
  continuaciones). Parser PHP genérico: cero cambios en PHP.
- Display de `GastoPC`: header "Asegurados" → "Derechohabientes".
- TODOs sembrados en las anclas administrativas sin fuente/corte documentados
  (`602513/1169476` salud Pemex/ISSFAM; `110000/181290` pensiones Pemex).

### Correcciones
- **Bug vivo del botón ± de Salud**: el HTML traía conteos quemados grandes
  (`data-pop`) mientras el PC publicado usaba denominador chico
  (hogares-equivalentes): un click de +$1,000 en IMSS saltaba el gasto de
  1.374% a ~6.4% del PIB. Con el PC por persona y `data-pop` del motor:
  1.374% → 1.520% (Δ +0.146 pp), verificado con la aritmética exacta del
  handler.
- **Procedencia de los fósiles del sitio RECUPERADA**: los conteos quemados
  (IMSS 55,311,028; IMSS-B 57,363,801; ISSSTE 7,171,893; Pemex 619,741;
  ISSFAM 583,175) eran exactamente esta misma construcción — personas ENIGH
  con el factor proyectado a CONAPO — y el motor nuevo los reproduce dígito
  por dígito (ese era el test de la construcción). La clase de fósil HTML
  muere: `poblarConteos()` en ambos JS sobreescribe la columna visible
  (spans `.pob-value`) y los `data-pop` desde `GASTOSPOB` en cada carga y en
  cada simulación; los números del HTML quedan como placeholder-snapshot con
  guard para motores sin el bloque.
- Sitio (ambos index): etiqueta "Asegurados"/"Insured" → "Derechohabientes
  (ENIGH 2024)"/"Beneficiaries (ENIGH 2024)" con tooltip ("Estimación ENIGH
  2024 ajustada a población CONAPO"); los 6 links de headers que apuntaban a
  ENIGH 2022 → 2024; el JS inglés NO tenía el handler del ± (gap preexistente
  del tablero) — portado idéntico al español.

### Datos
- Sin cambios de fuentes: misma ENIGH 2024 / CGPE 2026 (`data_updated`
  intacto — cambia la metodología de un derivado, no los datos).

Tests (todas las clases esperadas verificadas con harness batch old-vs-new,
ids aislados `users/cbase820`/`users/cnew820`): (a) conteos y PC de salud
según la tabla aprobada; (b) 5 `sankey-*.json` BYTE-IDÉNTICOS
(incidencia/deciles intactos) y `output.txt` byte-idéntico salvo los 8 PC de
salud de `GASTOSPC`; (c) par de `statalatex_gastopc` harness: SOLO los 16
getters `*Pob/*PC` de salud cambian, `*PIBgpc` intactos — el `.tex` trackeado
del libro (registro global-acumulado de la corrida textbook completa, ~4,400
líneas vs 368 del harness) se refresca en la próxima corrida real del libro;
(d) bloques `GASTOSPOB` bien formados (196/193 chars, 21+21 slots, cero
elementos no numéricos) y digeridos por los parsers de
`cargaDefault.php`/`checkStataStatus.php` simulados en PHP; (e) test del ±
declarado y observado: 1.520% (Δ +0.146 pp).

## [v8.1.0] — 2026-07-19

Reprocesamiento completo de PEF.dta (2013-2026) y rediseño de `UpdatePEF`:
las divisiones (divCIEP/divSIM/divFEDE) se anclan a códigos oficiales de la
Clasificación Funcional del Gasto del CONAC (pares finalidad/función) y a
texto normalizado de TIPOGASTO, con verificador de deriva año-por-año que
DETIENE el proceso ante cualquier mismatch (jamás clasificar en silencio).
Motivador: los selectores por códigos de `encode` (alfabéticos) derivaron con
cada categoría nueva — `desc_funcion==21` ("salud" al escribirse) apuntaba a
"cuotas a organismos internacionales de energía" y `desc_funcion==10`
("educación") a "asuntos financieros y hacendarios".

### Datos
- **CP 2013 entra completa por primera vez** (308,454 obs; antes 1 obs): el
  xlsx de SHCP trae una hoja pivote antes de la hoja de datos y el import
  tomaba la primera. `UpdatePEF` ahora detecta la hoja de datos (la de más
  filas) sin depender de xlsx curados a mano.
- **2025 pasa de PEF (aprobado) a Cuenta Pública** (`CP 2025.xlsx`, 210,459
  obs con ejercido/modificado/devengado/pagado; el asset `PEF.2025.xlsx`
  queda superseded y se elimina localmente). Gasto total 2025:
  10,940.5 → 11,417.7 mmdp (aprobado→ejercido).
- CP 2025 llega con esquema nuevo de SHCP (columnas sin prefijo `ID_`; el
  ramo viene en la columna `R` — el `Diccionario.csv` de SHCP la documenta
  como `RAMO`; discrepancia documentada en el código). El drop de columnas
  de 2 caracteres (hack para las ~180 columnas fantasma de CP 2022) se
  reemplaza por detección de columnas 100% vacías, que no mata UR/AI/PP/FF.
- `manifest.json`: SHAs nuevos de `CP.2013.xlsx` (sin hoja pivote) y
  `CuotasISSSTE.xlsx`; alta de `CP.2025.xlsx` y `Diccionario.csv`; baja de
  `PEF.2025.xlsx`. `data_updated` → 2026-07-19.

### Correcciones
- **(a3) Reclasificación Salud/Educación/Energía**: con las reglas CONAC,
  Salud pasa de 133.7→489.3 (2014) … 255.6→959.6 (2024) mmdp; Educación de
  451.7→712.5 (2014) … 620.9→1,124.1 (2024) mmdp — recuperan la función
  salud/educación en IMSS/ISSSTE/ramo 33 que la regla muerta perdía, y sale
  de Educación el gasto hacendario (41-244 mmdp/año) que la deriva le metió.
  Contraparte: divCIEP "Federalizado" y "Otros gastos" disminuyen en lo
  mismo. **El gasto total por año NO cambia** (verificado al peso, 2014-2024
  y 2026).
- **(a4) Comparaciones muertas por mayúsculas** (la limpieza pasa todo a
  minúsculas): FEIEF `modalidad=="Y"` (1.8-25.9 mmdp/año), INSABI/IMSS-B
  federalizado `modalidad=="U"` (67.8-105.3 mmdp/año, divFEDE "Salud
  (federalizado)" revive desde 2019), cuidados `ur=="V3A"/"V00"`
  (~0.3-0.8 mmdp/año), y `ur=="TZZ"/"TOQ"` en la homologación de ramo.
- Basura del pivote de CP 2013 eliminada: 66 obs sin año, variable
  `combustiblesyenergía`, y los labels fantasma "row labels"/"total result"
  en `desc_funcion`. Se limpia también la redundancia
  `desc_entidad_federativa` (quedaba junto a `entidad`).
- Evidencia contra anclar TIPOGASTO por id ("doble llave"): el id 4 fue
  "participaciones" en 2013-2015 y "pensiones y jubilaciones" desde 2016
  (SHCP renumeró el catálogo). El ancla correcta es el texto normalizado.

### Comandos
- `PEF.ado` v8.1: verificador de deriva (sección 4.0) corre en cada
  `UpdatePEF` — asserts por año de los pares CONAC (salud, educación,
  combustibles y energía) y whitelist de textos TIPOGASTO; mismatch → error
  459 con año y texto encontrado.
- Secciones 3.1/3.2 (series de Estadísticas Oportunas por códigos de encode)
  congeladas junto con la 3.3: el bloque completo se comenta y revive junto.
  `PEF.dta` pierde las variables muertas `serie_desc_funcion`/`serie_ramo`.
- `SubnacionalGasto.do` (legacy): comentario de advertencia — selecciona por
  códigos de encode que ya no significan lo que significaban.
- Contrato r() intacto: batería dorada con los nombres que consumen
  `GastoPC`/`Households`/`PerfilesSim`/`FiscalGap` corrida contra base vieja
  y nueva — ningún nombre se pierde; totales (`Gasto_neto`) idénticos; solo
  cambian los valores de las divisiones reclasificadas. Las etiquetas de los
  encodes se mantienen en minúsculas: los nombres de r() derivan del texto
  de las etiquetas y los consumidores dependen de su case exacto
  (`r(educacion_basica)` y `r(Baja_California)` conviven) — el plan de
  "etiquetas bonitas" queda diferido a un ciclo con migración de
  consumidores.

### Contrato de params de interfaz: string → NUMÉRICO
- Los 15 params de ingresos (`ISRASPIB`…`IMPORTPIB`) que `Web.Stata.do`
  declaraba entre comillas (string scalars) pasan a declararse SIN comillas,
  igual que las 5 reasignaciones de los submódulos ISR/IVA
  (`round(<Mod>, 0.001)` en vez de `"\`=round(...)'"`). Ambos flujos hablan
  igual: local vía `escalar` (SIM.do) y web vía template — y los `real()` a
  la lectura mueren con razón (FiscalGap:132 y los 4 sitios de SankeySF ya
  consumían numérico directo; sin esta migración el flujo web tronaba con
  type mismatch). Censo repo: cero `real()` sobre params restantes; los
  `real()` de parsing legítimo (`PEF.ado:678` regex, `TarjetaRFSP.do:25`
  fecha) no son params y quedan.
- **Mejora del modo de falla**: un placeholder `{{X}}` sin sustituir antes
  producía `real("{{X}}") = missing` — cero silencioso que se propagaba;
  ahora truena en SINTAXIS (r(198), visible en el log de sesión con el
  nombre del placeholder en la línea). Verificado con harness del contrato
  web (positivo: 155/155 sustituidos, corrida completa sin errores, bloques
  de `output.txt` idénticos en forma a la referencia; negativo: r(198)
  visible, cero bloques de datos producidos). Matiz registrado sin tocar:
  `calculaStata.php:63` sustituye `0` por default para params ausentes del
  POST — ese modo de falla silencioso es preexistente y de otro ciclo.
- Strings por diseño conservan comillas con comentario: `{{idSession}}`
  (id de sesión: paths) y `{{moduloCambio}}`/`{{moduloCambioIva}}` (flags en
  igualdad de strings; sin sustituir el módulo queda apagado — degradación
  intencional). `calculaStata.php` no se toca: `str_replace` es textual y
  las comillas vivían solo en el template.

## [v8.0.13] — 2026-07-18

Cierra la migración a `escalar` con `Simulador.ado` (excluido explícitamente
en v8.0.12): sus 9 sitios `string()` alimentan el alias `perf`, el mayor
consumidor del libro (414 usos). Con esto queda vigente el CONTRATO de
governance: **todo lo que alimenta el libro pasa por `escalar`** (regla
escrita donde vive el catálogo: header de `escalar.ado` y
`03_help/PROGRAMAS_AUXILIARES.md` §16). Cobertura verificada con censo
contra el libro: los 17 productores textbook + `Simulador.ado` registran
todo lo que el libro consume con formato; el residual "sin registrar" del
resumen (228 scalars en memoria) se auditó nombre por nombre — 211 son
scalars de trabajo internos que el libro NO referencia y 17 los consume
as-is numéricos con valor correcto (años de sesión `aniovp/anioPE/anioenigh/
aniofinal` y agregados `RFSPmax*`, `*gene*`, `pibVECES*`) — candidatos a
migración puntual en un ciclo futuro para dejar el resumen en 0 real.

### Comandos
- `Simulador.ado`: migrados los 9 sitios `string()` → `escalar` con tipos del
  catálogo: `<var>GPIB`→pctpib; `<var><decil>` (pesos por hogar)→mxnpc;
  `dis/inc<var><decil>`→pct; `<var>GIV/GVIIX/GX`→pct; `<var>GH/GM`→pct.
  Estos sitios corren también en cada simulación web (secciones 2, 4 y
  `poblaciongini` son incondicionales), no solo bajo textbook.
- `scalarlatex.ado` v2.1.0: el resumen de cobertura compara los sin-registrar
  contra el baseline auditado `02_governance/scalarlatex-baseline.txt` (228
  nombres) — dentro del baseline, línea informativa sin dump; nombres NUEVOS,
  aviso en rojo solo con esos nombres (la señal ya no se ahoga en 228 líneas
  permanentes). Procedimiento de actualización legítima en el header del
  baseline; sin el archivo (repo incompleto), cae al listado histórico.

### Correcciones
- Hallazgo de Fase A: `Simulador.ado:469` leía el scalar por-decil con
  `subinstr()` (función de strings) para armar la línea `INCD:` del flujo
  web — con el scalar ya numérico habría tronado con r(109) en CADA
  simulación web. Adaptado a `string(<scalar>,"%10.0f")`, que produce el
  mismo entero sin comas. Equivalencia demostrada empíricamente (lección del
  incidente v1.39): corrida batch con `$output=="output"` antes y después de
  la migración — líneas `INCD:`/`INCD2:`/`INCD3:` (y `APORT*`/`PROY*`)
  byte-idénticas.

### Test dorado (perfiles + acumulación)
- Los 9 `.tex` regenerados (corrida textbook completa, export a /tmp) y
  comparados getter por getter contra los vigentes: **519 getters cambiados,
  el 100% de la clase esperada** `*GIV/*GVIIX/*GX` entero → 1 decimal (108 en
  perfiles/fiscalgap/shrfsp, 90 en gastopc/tasas, 15 en households, por
  acumulación del registro global); **cero diffs de valor, cero getters
  nuevos**. Los 414 getters `perf` que usa el libro: 380 existen con el mismo
  nombre; los 34 restantes (`OtrosGastos*` sin T, `GATA*`) ya faltaban en el
  baseline — drift libro↔modelo preexistente, no regresión.
- Nota del test batch: `aniotdmin/aniotdmax` no se generan bajo `nographs`
  (se definen dentro del bloque de gráficas de `Poblacion.ado:197`) — artefacto
  del harness, preexistente; la corrida real del libro va con gráficas.

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
