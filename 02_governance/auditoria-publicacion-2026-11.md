# Auditoría de publicación — noviembre de 2026

**Dos gates previos a la doctrina «todo lo versionado es público por diseño»: secretos en la historia (Gate 1) y seguridad del PHP del endpoint (Gate 2).**

| | |
|---|---|
| Fecha | 2026-11-18 |
| Punto de partida | `master` = `e2e3f0d` (v8.18.2) |
| Rama | `docs/auditoria-publicacion-2026-11` (el reporte; desde la adenda del 18-nov, también la decisión B y la fila del runbook: §8) |
| Naturaleza | Solo lectura y reporte. No cambia código, no toca el VPS ni el endpoint, no implementa ningún fix. La adenda del 18-nov (§8) sí cambia tres archivos versionados. |
| Evidencia | `~/CIEP_Simuladores/diag-auditoria-publicacion-2026-11-18/` (scripts, salidas, espejos; fuera de Dropbox y de git) |
| Herramientas | gitleaks 8.30.1, `barrido.py` / `barrido2.py` (barrido manual por blobs), php 8.5.3 local para las pruebas del Gate 2 |

> **Antes de subir este archivo a GitHub:** describe exposiciones que siguen abiertas en un repositorio que ya es público (§0). La sesión lo dejó commiteado en local y **sin push**; cuándo y cómo se publica es la decisión 1 de §6. **Actualización 2026-11-18:** Ricardo autorizó un solo push, con el expediente resuelto, cuando cierre el gemelo tenencia/v6 (§8); hasta entonces sigue sin push.

## 0. Resumen y una premisa que no se sostiene

**El repositorio ya es público y el PHP ya está en él.** `gh repo view rcantuc/SimuladorCIEP` devuelve `visibility: PUBLIC`; la API anónima responde 200; existe desde 2018-10-30 y tiene un fork. El PHP del sitio está versionado desde `69988b3` (2026-10-16); hoy son 81 archivos `.php`. La frase del encargo, «el PHP corre en el servidor y hoy nadie lo ve», no describe el estado actual: cualquiera lo lee hoy, incluida la versión sin validación (`69988b3`) y el commit que la corrige y la describe (`1e84789`, «calculaStata.php validaba cero entradas — inyeccion de codigo Stata y traversal de idSession; endurecimiento de los 13 PHP»). Los dos gates no son previos a una publicación: auditan lo que ya está expuesto.

| Gate | Resultado | Lo que lo decide |
|---|---|---|
| **1. Secretos en la historia** | **No limpio**: 1 crítico, 3 altos, 2 bajos | El token del BIE que la reescritura de mayo sacó de la historia sigue descargable de GitHub sin autenticarse, y es el mismo que hoy usa `-datos` (G1-1). |
| **2. PHP del endpoint** | **Sin caminos clase (c)** en el código vivo de `master`; 4 hallazgos medios y 5 bajos | Ningún input llega a shell, Stata o rutas sin validación de tipo estricta. Los medios son de integridad del default, entorno y disponibilidad. |
| **Fuera del repo, mismo VPS** | **Crítico por confirmar** (L-1) | La copia local del sitio de tabaco pasa input crudo a `shell_exec`; es la clase de fallo que la historia pública de este repo documenta. |

## 1. Gate 1 — Secretos en la historia completa

### 1.1 Qué se barrió

| Superficie | Cómo se obtuvo | Commits | Blobs | gitleaks | Barrido manual |
|---|---|---:|---:|---|---|
| `origin` completo | `git clone --mirror`: 6 ramas, 61 tags, 78 refs de PR | 1,649 | 9,243 | 11 hallazgos, los 11 falsos positivos | sí |
| Fork público `JuanPabloSantisteban/SimuladorCIEP` | `git clone --mirror` (historia anterior a la reescritura, hasta 2025-02-21) | 915 | 4,195 | 0 | sí |
| Historia anterior a la reescritura que GitHub aún sirve | `git fetch origin 2f46d92…` con `--filter=blob:limit=3m` (71 blobs mayores de 3 MB no se bajaron) | 1,077 | 4,799 | 0 (ver G1-7) | sí |
| Clon local de Dropbox | en sitio, solo lectura: ramas locales, 3 stashes y 232 blobs inalcanzables | 1,814 | 9,064 | los mismos 11 | sí |
| Assets de las Releases (`datos-*.zip`, `fuentes-*`, `scn-congelado-*`, `itan-congelado`, `manifest-datos.json`) | 20 assets distintos; 16 zips con 5,682 archivos | — | — | — | token vivo, UUID, llaves, usuario@host, rutas: 0 |

gitleaks recorre `git log -p --all` e informó 1,508 commits de los 1,649 de `origin`; entre los que no recorre están los 113 merges. El barrido manual lee **cada blob** de cada almacén de objetos, así que cubre también lo que un merge haya introducido y lo inalcanzable (en el fork, 19 blobs de más de 30 MB solo pasaron por la búsqueda de valores vivos). Busca: llaves privadas (`BEGIN … PRIVATE KEY`), URLs con `usuario:clave@`, asignaciones de password/token/key/secret/clave/credencial, formatos de proveedor (AWS, GitHub, Slack, Google, Stripe, JWT…), UUID, IPv4, `usuario@IP`, `sshpass`, `mysql -p`, `define('DB_…')`, macros de Stata con nombre de secreto, tokens en URL, y todo nombre de archivo de credenciales (`*credentials.sh`, `set_token.do`, `wp-config.php`, `.env`, `*.pem`, `*.key`, `id_rsa`, `*.sql`, `/ssl/`…) en cualquier árbol de la historia.

Además se buscaron por **coincidencia exacta** los valores que hoy viven en archivos ignorados (nunca se imprimen; solo nombre y `sha256[:10]`): los dos `BIE_API_TOKEN` (clon de Dropbox y `-datos`), `VPS_USER`, `VPS_HOST`, `SSH_ALIAS`, `REMOTE_PATH`, `ENDPOINT_URL`, usuario, contraseña y salts de MySQL/WordPress (`04_4`, `04_5`), la contraseña de aplicación de Gmail y las cinco llaves de Twitter (`06_libro/*/.env`), y dos líneas de la llave privada SSL de 2026.

### 1.2 Hallazgos

| Id | Severidad | Tipo | Commit / archivo | ¿Historia o árbol vivo? |
|---|---|---|---|---|
| **G1-1** | **Crítico** | Token API del BIE/INEGI (UUID, `sha256[:10]` = `b2454eaa3e`) | `AccesoBIE.ado:13` y `Stata net/AccesoBIE.ado:13`, de `464741d` (2025-12-11) a `2f46d92` (2026-04-30), commits **anteriores a la reescritura** | Fuera de las refs del repo (la reescritura lo sustituyó por `[REDACTED_TOKEN]`), pero **GitHub lo sigue sirviendo**: `raw.githubusercontent.com/rcantuc/SimuladorCIEP/2f46d92…/AccesoBIE.ado` responde 200 sin autenticación, y `git fetch origin 2f46d92…` entrega los 1,077 commits viejos. |
| G1-2 | Alto | Usuario SSH + IP del VPS: `<USUARIO>` @ `<IP_VPS>` (los valores, en la carpeta de evidencia) | Desde `94a2089` (2026-07-09); 101 blobs | **Árbol vivo**: `05_scripts/publicar-vps-credentials.template.sh:7,10`, `02_governance/runbook-deploys-ciep.md:316,318,337,465`, `02_governance/historico/reconocimiento-vps.md`, `02_governance/historico/bitacora-arquitectura.md`. |
| G1-3 | Alto | Mapa del servidor (no es credencial) | `02_governance/historico/reconocimiento-vps.md`, desde `94a2089` | **Árbol vivo**: Ubuntu 22.04.2 con 98 actualizaciones pendientes y reinicio requerido (L40–49), Apache 2.4 + PHP 8.1.2 y los cuatro vhosts (L211), puertos abiertos (L209), usuario con grupo `sudo` (L42), crons (L161–163), y la IP de la sesión SSH de un colaborador con su nombre (L310, L465). |
| G1-4 | Alto (dato personal, no credencial) | Bitácoras del simulador de tabaco con IP, fecha, hora y un campo de texto libre donde los visitantes escribieron nombres | `tabaco/{1,1.0,1.1,1.2}/calcula.log` y `descargas.log` (`cccdebf` 2022-11-10 → `220082a` 2023-11-15): hasta 3,275 líneas y 915 IP distintas por archivo; 572 valores distintos de texto libre en `tabaco/1/calcula.log` | Solo historia: la del **fork público** y la anterior a la reescritura. El repo actual no las tiene (la reescritura purgó `tabaco/`). |
| G1-5 | Bajo | IP del servidor Cloudways del endpoint Stata, sin usuario: `104.248.223.143` | `02_governance/runbook-deploys-ciep.md:262` | Árbol vivo. Es la IP a la que resuelve `ciep.mx` por DNS. El alias SSH y la ruta remota reales: 0 coincidencias en toda la historia. |
| G1-6 | Bajo | Rutas de la máquina de Ricardo (`/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/…`) | `05_scripts/publicar-vps-credentials.template.sh:26,29`, `01_modulos/Web.Stata.do:20`, `04_1…/cargaDefault.php:22`, `04_3_anteriores/v1/derechos-hidrocarburos.php.html:7` | Árbol vivo. Ruido: revela el nombre de usuario local y la estructura de carpetas. |
| G1-7 | Proceso | gitleaks **no detecta** el token en sintaxis de Stata | `local token "<uuid>"` no lleva operador de asignación; corrido sobre los 3,852 blobs de texto anteriores a la reescritura devolvió 0 | — El secret scanning y la push protection de GitHub están deshabilitados en el repo (`security_and_analysis`: todo `disabled`). |

**Sobre G1-1.** Tres hechos verificados y uno que no se pudo verificar:

1. El token expuesto es **byte a byte** el `BIE_API_TOKEN` de `~/CIEP_Simuladores/SimuladorCIEP-datos/set_token.do` (archivo del 2026-10-16): es el token con el que corre hoy el worktree desde el que se publica. El clon de Dropbox usa otro (`9170596f05`), que no aparece en ninguna historia.
2. El SHA `2f46d92` se cita en el propio árbol vivo (`02_governance/versionado-y-git.md:223,233,378`), así que encontrarlo no requiere adivinar nada.
3. GitHub también sirve `464741d` y `499a06f`, los dos commits que tocan la línea del token.
4. **POR CONFIRMAR: si INEGI dio de baja el token.** `politicas-institucionales.md:205` registra la solicitud del 2026-05-12, no la respuesta. Desde fuera no se puede saber: el servicio BISE respondió 200 con observaciones al token expuesto **y también** a `abc` y a un UUID inventado (`prueba-token-bie.txt`); hoy no valida el token en esa ruta.

Por la escala del encargo es crítico (credencial en uso, sin baja confirmada). El daño posible es acotado: el BIE sirve datos públicos; lo que está en juego es la identidad institucional ante INEGI y que una baja tardía del token corte `pibe-32.sh` y `AccesoBIE` en `-datos`.

**Resolución de G1-1 (2026-11-18).** Decisión de Ricardo, textual:

> RESUELTO CON RIESGO RESIDUAL ACEPTADO: token rotado el 18-nov; el pipeline opera con el nuevo en `-datos/set_token.do` (fuera de git, por diseño). INEGI no ofrece mecanismo de revocación, por lo que el token expuesto en `2f46d92` queda posiblemente vivo. Riesgo aceptado por Ricardo: la API del BIE es gratuita y de datos públicos; el peor caso es consumo de cuota a nombre ajeno, sin acceso a sistemas ni datos. La purga de historia procede como higiene (sesión planeada), no como emergencia.

*Verificación al commit de esta adenda (misma comparación por `sha256[:10]`, sin imprimir el valor):* `~/CIEP_Simuladores/SimuladorCIEP-datos/set_token.do` no ha cambiado: es el archivo del 2026-10-16 y su token sigue siendo `b2454eaa3e`, el expuesto. El clon de Dropbox y `Tabaco/Mayo2026/set_token.do` usan `9170596f05`, que ya estaba el 31-oct. La frase «el pipeline opera con el nuevo en `-datos/set_token.do`» queda **POR CONFIRMAR** hasta que ese archivo cambie; se vuelve a comprobar antes del push. El resto de la resolución no depende de esa frase.

**Cierre del capítulo del token (2026-11-18, tarde).** Resuelto 2026-11-18 — el token históricamente expuesto no es revocable (INEGI no ofrece revocación); se adoptó diseño de token de cortesía público dedicado (`info@ciep.mx`) + override opcional. Riesgo residual aceptado.

Lo verificado al cerrar, por `sha256[:10]` o prefijo y sin imprimir ningún valor personal:

1. **La frase pendiente queda confirmada.** `~/CIEP_Simuladores/SimuladorCIEP-datos/set_token.do` cambió el 18-nov a las 12:24 y ya trae `9170596f05`, el mismo que el clon de Dropbox y `Tabaco/Mayo2026/set_token.do`. Ningún `set_token.do` conserva `b2454eaa3e`. `9170596f05` responde 200 en los catálogos de la API de Indicadores: está enrolado.
2. **El token expuesto seguía en disco, fuera de git, en tres copias de `AccesoBIE.ado` v2.0** que esta auditoría no había visto (hardcodeado en la línea 13): `04_5_ciep.mx/simuladorfiscal/` (ignorado), `CIEP_Micrositios/ciep.mx/simuladorfiscal/` y `Tabaco/Mayo2026/` (los dos sin git). Las dos primeras se sustituyeron por la versión de la rama y la tercera recibió un parche mínimo. Barrido posterior de los archivos de texto de `CIEP_Simuladores` (Dropbox) y de `~/CIEP_Simuladores`: ningún UUID con ese prefijo. Quedan fuera del barrido los espejos de evidencia de §7 (lo contienen, como ya se dijo) y el historial de versiones de Dropbox.
3. **El diseño adoptado** (rama `sesion/token-cortesia`): `AccesoBIE` busca el token en tres niveles —opción `token()`, global `$BIE_API_TOKEN`, token de cortesía CIEP— y la consulta pública .aspx queda como respaldo en runtime. El token de cortesía se versiona a propósito; la excepción, sus cuatro condiciones, el registro cerrado y la reposición están en `politicas-institucionales.md` Parte I §3.4. Los tokens personales siguen solo en `set_token.do`, ignorado. En los archivos versionados de la rama no hay ningún UUID con el prefijo del token expuesto ni del personal; el de cortesía aparece en uno solo, `AccesoBIE.ado` (la plantilla y la política remiten a esa constante sin repetir el valor).
4. **Precisión al punto 4 de arriba y a la fila 1 de §4.** Que «el BISE no valida el token» es cierto del servicio de datos `INDICATOR`, con cualquier fuente: entrega la serie con cualquier cadena. Los catálogos `CL_*` sí validan y responden 401 a un token no enrolado. Con eso hay prueba de vida: `CL_UNIT` con fuente `BISE`, 200 = activo. El token de cortesía dio 401 a las 12:55 (estaba registrado solo en el DENUE; el INEGI enrola por servicio) y 200 desde las 13:05, con un token inventado como control negativo en 401.
5. **Un hallazgo que no era de secretos.** `AccesoBIE` pedía la fuente `BIE`, que la API responde con 400 a cualquier token; las fuentes documentadas son `BIE-BISE` y `BISE`. Las series nacionales salían siempre por la consulta pública, hubiera token o no. La rama lo corrige; `refrescar-scn.sh` tiene el mismo patrón y queda para un cambio aparte.

**Copia del motor de tabaco en el VPS (confirmado por Ricardo el 2026-11-18):** `/SIM/OUT/tabaco/Mayo2026/AccesoBIE.ado` en el servidor es la copia vieja con el token expuesto hardcodeado, igual que lo era la copia local. Se corrige cuando se despliegue el `v1.0.0` de tabaco desde su repo nuevo. Riesgo aceptado, sin acción: el historial de versiones de Dropbox y los espejos de evidencia conservan el token expuesto, que ya es público e irrevocable en la historia de git.

**Sobre G1-2.** Los valores de la plantilla son idénticos a los de los dos `publicar-vps-credentials.sh` reales (comparación directa: `VPS_USER`, `VPS_HOST`, `VPS_HTML_ROOT`, `VPS_SIM_ROOT`). El archivo ignorado ya no protege nada de eso. La IP sola es pública (DNS de `simuladorfiscal`, `iepsaltabaco` y `tenencia`); lo que el repo agrega es el usuario SSH, que pertenece al grupo `sudo`, y el nombre sugerido de la llave (`~/.ssh/ionos_ciepmx`, L37). Ninguna contraseña ni llave en ninguna historia.

**Resolución de G1-2 (2026-11-18), decisión B: salen del árbol vivo.** `05_scripts/publicar-vps-credentials.template.sh` lleva marcadores (`<USUARIO>`, `<IP_VPS>`, `<RUTA_AL_REPO>`, `<LLAVE_SSH>`) y la advertencia de no escribir valores reales, como la plantilla del endpoint; las cuatro líneas del runbook y la entrada 1.18 de `historico/bitacora-arquitectura.md` dicen `<USUARIO>@<IP_VPS>`. El `git grep` de `<usuario>@` y de la IP da un solo resultado en el árbol: `historico/reconocimiento-vps.md:407`, que se resuelve en la purga junto con G1-3. Los dos `publicar-vps-credentials.sh` reales conservan sus valores y `publicar-vps.sh` no lee la plantilla (solo la nombra en un mensaje de error). Lo que no cambia: los 101 blobs de la historia siguen teniendo los valores hasta la purga, y el nombre del usuario sigue en el árbol donde es código o receta (`05_scripts/vps/crear-deployment:22`, `ciepmx-deploy.sudoers`, los `chown` del runbook).

### 1.3 Falsos positivos

- **gitleaks, 10 de 11** — `05_scripts/ancla-reproducibilidad.json` L12–16 en `9a85862e` y `a58b60c4`: son los sha256 de los cinco sankeys.
- **gitleaks, 1 de 11** — `02_governance/CHANGELOG.md` L99 en `5ad6e400`: la prosa «sankeys: SankeySF/decil…» junto a la palabra «key».
- **Asignaciones (1,259 en `origin`)** — `clave_de_concepto = "XNA0120"` en `DatosAbiertos.ado`, `"clave": "anclas"` en `metodo.json`, `clave:` en `js/entidad.js`, `credentials: 'same-origin'` en `fetch`, `token = os.environ['BIE_API_TOKEN']` en `refrescar-scn.sh` (lo lee del entorno), y `\lst@token=\toks53` en logs de LaTeX del fork.
- **Marcadores** — `[REDACTED_TOKEN]`, `[NUEVO-TOKEN-ROTADO-AQUI]`, `tu-token-aqui`: lo que dejó la reescritura y las plantillas.
- **UUID (8)** — jQuery, SVG de `images/` y un `.sln` de `plugins/idle-timer`.
- **Hexadecimales largos** — sha256 de `manifest.json` (9,522), `nl-manifest.json`, `itan-catalogo.json`, CHANGELOG.
- **IPv4** — `53.40.86.88` es el teléfono del pie de página; `8.1.0.3` un ejemplo de versión; `3.2.3.1`–`3.2.3.4` numeración de secciones; `1.2.3.4` un fixture de `test-sitio-seguridad.sh`; `127.0.0.1`.
- **Valores vivos genéricos** — `VPS_HTML_ROOT` (`/var/www/html`), `VPS_SIM_ROOT` (`/SIM/OUT`), `ENDPOINT_URL` (URL pública) y `DB_NAME` del libro (`libro_local`, base de desarrollo que el CHANGELOG nombra en prosa). `DB_USER`, `DB_PASSWORD` y los salts: 0 coincidencias.
- **`windows/instalar-runner.ps1`** (historia, borrado en `5a00db0`) — `IdentityFile $KeyPath`: script parametrizado, sin llave dentro.
- **Nombres de archivo** — solo las tres plantillas, `politica-gestion-secretos.md` y un ícono `user-secret.svg`. Ningún `*credentials.sh` real, `set_token.do`, `wp-config.php`, `.env`, `.pem`, `.key` ni `.sql` entró jamás a ninguna de las cuatro historias.

### 1.4 El presente

- `bash 05_scripts/verify_gitignore.sh`: 88/88 en `master` (`e2e3f0d`), 108/108 en el clon de Dropbox, 91/91 en `-datos`; 0 fallas. En el clon de Dropbox hay 20 archivos con forma de credencial (llave SSL de 2026, dos `wp-config.php`, `wp-salt.php`, dos `.env`, las dos credenciales de publicación, `set_token.do` y material de plugins), todos ignorados y ninguno trackeado.
- Ningún archivo versionado contiene una credencial viva: de los valores buscados por coincidencia exacta, los únicos presentes en `master` son `VPS_USER` y `VPS_HOST` (G1-2).
- Los `.sh` de operación leen de los archivos ignorados (`source` de `publicar-vps-credentials.sh` y `endpoint-credentials.sh`); `backup-vps.sh` pide la contraseña de `sudo` y la passphrase de gpg por teclado. Lo único real escrito en ellos es `OWNER="ciepmx"` en `05_scripts/vps/crear-deployment:22` y la regla de `05_scripts/vps/ciepmx-deploy.sudoers:6`.
- El rsync del sitio excluye `ssl/` y `logs/` (`publicar-vps.sh:682–690`), y no hay PHP sin versionar en ninguno de los dos docroots locales.

### 1.5 Recomendación, en este orden

1. **Rotar primero.** Poner en `-datos/set_token.do` el token vigente y pedir a INEGI confirmación escrita de la baja del viejo. Purgar antes de eso no sirve.
2. **Después, la historia colgante.** Pedir a GitHub Support que recolecte los commits inalcanzables de la red del repo. El fork pertenece a esa misma red y conserva la historia hasta 2025-02 (G1-4): hace falta que su dueño lo borre o que GitHub lo retire por datos personales.
3. **G1-2 y G1-3 son una decisión, no una purga.** La IP está en el DNS; reescribir historia por el usuario SSH no compensa. O se aceptan como públicos y se endurece `sshd` (solo llaves, sin contraseña, `fail2ban`) y se parchea el servidor, o salen del árbol vivo (plantilla con marcadores, runbook con `$VPS_USER@$VPS_HOST`, el reconocimiento redactado).
4. Activar secret scanning y push protection de GitHub, y agregar a gitleaks una regla para `local|global <nombre> "<valor>"` de Stata antes de usarlo como gate de CI.

## 2. Gate 2 — Seguridad del PHP del endpoint

La pregunta: **¿puede algún input del usuario alcanzar un shell, el filesystem o Stata sin pasar por lista blanca?** En el código vivo de `master`, no. Las llamadas a shell vivas son dos (`calculaStata.php:144` y `checkStataStatus.php:87`) y ambas reciben datos ya validados y pasados por `escapeshellarg`. Lo que sigue son los defectos de esa validación y lo que queda alrededor.

### 2.1 Inventario

81 archivos `.php`, todos bajo `04_1_simuladorfiscal.ciep.mx/`; ninguno fuera.

| Grupo | Archivos | Entradas del usuario |
|---|---|---|
| Endpoint de cálculo | `config.php`, `calculaStata.php`, `checkStataStatus.php`, `logCalcular.php` | sí |
| Lectura de resultados | `cargaDefault.php`, `jsonSankey.php`, `jsonSankeyEscol.php`, `jsonSankeyGrupoedad.php`, `jsonSankeyRural.php`, `jsonSankeySexo.php`, `jsonSankeyNTA.php`, `jsonEntidad.php` | sí |
| Páginas | `index.php`, `index-en.php`, `plantilla-metodo.php`, `NTA/index.php`, `metodo/index.php`, `entidades/index.php`, `entidades/_entidad.php` | solo `?lang=` |
| Parciales y datos | `NTA/_cuerpo-{en,es}.php`, `entidades/_cuerpo-{entidad,indice}-{en,es}.php`, `entidades/_catalogo.php` | no |
| Generados | 21 `metodo/<capítulo>/index.php` y 32 `entidades/<ABREV>/index.php` | no |
| Sin entradas | `health.php`, `cargaDefault-local.php` | no |

**Código no versionado.** En el docroot del Simulador, ninguno: los dos orígenes del rsync (clon de Dropbox y `-datos`) no tienen PHP fuera de git; lo no versionado que hay ahí es `ssl/`, `logs/`, `calcular_clicks.log` (excluidos del rsync) y `simuladorfiscalv7.png`. En el **mismo VPS** sí hay PHP que este repo no versiona: ver L-1 en §2.6.

### 2.2 Matriz input → destino → clase

Clases: **(a)** lista blanca, rango o tipo estricto; **(b)** saneado por lista negra, escape o una condición frágil; **(c)** llega a shell, Stata o una ruta sin validación estricta.

| Archivo | Input | Destino | Clase |
|---|---|---|---|
| `config.php` | cabecera `Host` (L7) | elige `$TMP_PATH`, `$calcula_ruta` y `$stata_exe` (L8–20): las rutas con las que después se arma el comando | **(b)** — H-3 |
| `config.php` | `idSession` GET/POST (L38–46) | regex `/^[A-Za-z0-9]{1,32}$/` (L33); después nombre de directorio, del `.do` y `global id` | (a) con dos defectos — H-1, H-2 |
| `config.php` | 154 llaves numéricas (L52–64) | `is_numeric` + solo `[0-9eE+\-.]`; después `{{llave}}` del `.do` | (a) |
| `config.php` | `REMOTE_ADDR` (L142) | `sha1` → nombre de archivo del freno | (a) |
| `config.php` | `X-Forwarded-For`, `Client-IP`… (L81–98) | `get_client_ip()` no tiene ningún uso vivo | — |
| `calculaStata.php` | `idSession` (L56) | `glob` + `unlink` (L100–102), `mkdir` (L104), `fopen` del `.do` (L114, L130), `shell_exec` con `escapeshellarg` (L143–144) | (a) — H-1, H-2 |
| `calculaStata.php` | 154 llaves (L65–73) | `str_replace` en la plantilla (L125–128) → Stata | (a) |
| `checkStataStatus.php` | `idSession` (L12) | rutas de `.done`, `output.txt`, `.log`, `.pid` (L14–17, L79) → `file_get_contents` → respuesta | (a) — H-6 |
| `checkStataStatus.php` | contenido de `<id>.pid` (no es input directo) | `exec("ps -p …")` tras `ctype_digit` y `escapeshellarg` (L86–87) | (a) |
| `logCalcular.php` | `sessionId`, `pageVersion` (L43–46) | una línea de `logs/calcular_clicks.log` (L66) | (a) con defecto — H-2 |
| `logCalcular.php` | `User-Agent` (L37, L47, L62) | misma línea; se sustituyen los no imprimibles y se corta a 100 | (b), suficiente: no puede meter saltos |
| `cargaDefault.php` | cabecera `Host` (L7, comparación exacta) | elige entre `users/ciepmx/output.txt` local y el del servidor (L331) | (a) |
| `cargaDefault.php` | `idSession` y 14 llaves crudas (L245–256) | `shell_exec("rm '…{$idSession}/*' -f")` (L269–271), `.do` y `shell_exec` de Stata (L306–308) | **(c) latente**: código dentro de dos comentarios de bloque (L242–277, L278–314). Hoy no se ejecuta — H-7 |
| `jsonSankey{,Escol,Grupoedad,Rural,Sexo}.php` | `idSession`; si es inválido, `ciepmx` | ruta `users/<id>/sankey-<corte>.json` con el corte fijo en el archivo → `fopen` | (a) — H-6 |
| `jsonSankey{…}.php`, `jsonSankeyNTA.php`, `jsonEntidad.php` | cabecera `Host` | elige la base `users/` | **(b)** — H-3 |
| `jsonSankeyNTA.php` | `cuenta` ∈ 4 valores (L74–75), `corte` ∈ 8 (L91–93), `idSession` | ruta → `readfile` / `fopen` | (a) |
| `jsonEntidad.php` | `producto` ∈ 6 (L60–62), `abrev` ∈ catálogo de 32 + regex (L74), `corte` ∈ 5 (L96–98), `idSession` | ruta → `readfile` / `file_get_contents` | (a) |
| `plantilla-metodo.php` | `?lang=` ∈ {`es`, `en`} (L35–36) | `require … '_cuerpo-' . metodo_lang() . '.php'` (`NTA/index.php:25`, `entidades/index.php:20`, `entidades/_entidad.php:63`) | (a) |
| `index.php`, `index-en.php` | cabecera `Host` (L879, L891) | escoge entre dos `href` constantes; no se imprime | (a) |
| `health.php`, `cargaDefault-local.php`, 53 generados | ninguno | — | — |

### 2.3 Traversal, archivos, límites y errores

- **Traversal.** Cerrado en las cuatro llaves que forman rutas (`idSession`, `corte`, `cuenta`, `abrev`); `test-sitio-seguridad.sh` lo ejercita y pasa (0 fallos sobre `e2e3f0d`).
- **Archivos con nombre derivado de input.** Solo `users/<idSession>/…` y `_ratelimit/ip-<sha1>`. El primero es el origen de H-1 y H-2.
- **Límites.** Hay freno desde v8.11c (`config.php:100–171`): 3 Stata simultáneos y 100 corridas por IP cada 600 s, con IP = `REMOTE_ADDR`. Protege la CPU; no protege la disponibilidad (H-4). `logCalcular.php` no tiene freno (H-5).
- **Errores.** `calculaStata.php` apaga `display_errors` y responde JSON. Lo que sí se filtra está en H-6.

Las pruebas P1–P8 corren en una copia temporal con Stata falso y `php -S` en `localhost`, con el mismo montaje que `test-sitio-seguridad.sh` (`poc-gate2.sh`, salida en `poc-gate2.txt`). Nada se probó contra producción.

### 2.4 Hallazgos

| Id | Severidad | Hallazgo | Fix propuesto |
|---|---|---|---|
| **H-1** | Medio | `idSession` no tiene nombres reservados ni forma fija: `ciepmx` y `ricardo` pasan el regex, y `calculaStata.php:100–104,130–139` borra y escribe en `users/<id>/`. Lo único que protege al escenario default es que la Fase 3c deja `users/ciepmx` como de `ciepmx` con `o=rX` (`publicar-vps.sh:1057`). P2: con el directorio escribible, un POST con `idSession=ciepmx` borró los cinco sankeys del default y `cargaDefault.php` pasó a servir los números del atacante; con el directorio de solo lectura respondió 500 sin correr Stata. Además, los ids que no empiezan con `0` no los recoge el cron (`reconocimiento-vps.md:463`). | En `calculaStata.php`, aceptar solo la forma que produce `generaId()`: `/\A0[A-Za-z0-9]{4}\z/`, y dar esa forma al id de `humo-calcular.sh` (`publicar-vps.sh:1436` usa `humo<fecha>`). |
| **H-2** | Bajo | `$` sin modificador `D` acepta un salto de línea final. P1: `idSession="0nl01\n"` respondió 200, creó el directorio `0nl01\n` y partió la línea 34 del `.do` (`global id = "0nl01` / `"`); `sessionId="abc\n"` partió el renglón de la bitácora que `logCalcular.php:40–42` dice proteger. No da control sobre lo que sigue al salto. | Cambiar `$` por `\z` en `config.php:33` y `logCalcular.php:45–46`, y agregar el caso a `test-sitio-seguridad.sh`. |
| **H-3** | Medio | El modo «local» lo decide la cabecera `Host`, que escribe el cliente, y con `strpos`: basta que contenga `localhost` (`config.php:7` y otros diez archivos). En ese modo las rutas pasan a `dirname(docroot)/users/` y el freno, si no puede crear su carpeta, deja pasar (`config.php:127–135`). P3: con otra cabecera `Host` la misma petición cambió de rama y el freno quedó abierto. En el VPS es inocuo mientras `/var/www/html/` no sea escribible por `www-data`. | Decidir el entorno con `PHP_SAPI === 'cli-server'` o una variable del vhost, nunca con una cabecera; y que el freno cierre, no abra, cuando no puede escribir su estado. |
| **H-4** | Medio | Una sola IP puede ocupar los tres slots sin llegar a su tope: 3 × 600 s ÷ ~35 s ≈ 51 corridas, contra un límite de 100 (`config.php:112–115`). P8: con tres peticiones en vuelo desde una IP, la cuarta recibió 429. `.htaccess` abre CORS a `*` y el endpoint acepta GET, así que se puede disparar desde el navegador de terceros. Stata corre sin límite de tiempo (`calculaStata.php:5,143–144`) y un slot deja de contar a los 600 s aunque el proceso siga vivo. | Una corrida simultánea por IP, y `timeout 120` delante de `$stata_exe`. |
| **H-5** | Medio; alto si Apache lo sirve | `logs/calcular_clicks.log` vive **dentro del docroot** (`logCalcular.php:10–11`) y guarda IP, User-Agent y hora de cada clic. El `.htaccess` versionado solo fija CORS, y la Fase 3c crea `logs/` con 777 (`publicar-vps.sh:1112`). P5: 300 POST seguidos escribieron 300 líneas, sin 429, y `php -S` entregó el archivo por GET. | Escribir el log en `/SIM/OUT/current/logs/` (fuera del docroot) o agregar `RedirectMatch 404 ^/logs/` al `.htaccess`; y pasar `logCalcular.php` por el freno por IP. |
| **H-6** | Bajo | Fugas en respuestas: (i) los cinco `jsonSankey*.php` de la portada devuelven la ruta absoluta en `chart.nombre` (L68, L54, L67, L54, L54; `jsonSankeyNTA.php:140–144` ya lo corrigió); (ii) `logCalcular.php:83–90` devuelve `debug` con rutas y `error_get_last()` cuando falla (P5); (iii) `checkStataStatus.php:70–72` devuelve el log completo de Stata si existe `<id>.done` y falta `output.txt` (P7; nada del repo escribe `.done`, así que hoy la rama no se alcanza); (iv) los 404 de `jsonSankeyNTA.php:66` y `jsonEntidad.php:48` nombran la fase del deploy. | Devolver `users/<rel>` relativo como en `jsonSankeyNTA.php`; quitar `debug` y `error_details`; quitar el campo `log`. |
| **H-7** | Bajo | `cargaDefault.php:242–314` conserva entre dos comentarios de bloque el flujo viejo con `idSession` crudo en `shell_exec`. Quitar un `*/` lo vuelve ejecución de comandos. También L22 (ruta de la Mac) y L234. | Borrar los dos bloques comentados (L242–314) y `$bases` (L234–239), conservando `$debug` (L240); git guarda la historia. |
| **H-8** | Bajo | El id de sesión lo elige el cliente y es predecible (`srand(make_seed())` + `str_shuffle`, `config.php:70–79`; 62·61·60·59 ≈ 13.4 millones). Quien lo conozca o lo adivine lee (`jsonSankey*.php`) o pisa (`calculaStata.php`) la sesión de otro. La sesión no guarda datos personales. | Generar el id con `bin2hex(random_bytes(8))` y aceptar solo ese formato. |
| **H-9** | Bajo | Parciales y un stub alcanzables por URL: `NTA/_cuerpo-*.php` y `entidades/_cuerpo-*.php` responden 200 con HTML truncado (P6), y `cargaDefault-local.php`, un stub de desarrollo con datos ficticios, viaja a producción. | `RedirectMatch 404 /_[^/]+\.php$` en `.htaccess` y sacar `cargaDefault-local.php` del rsync. |

### 2.5 Veredicto por archivo

Como los 81 ya son públicos, **PUBLICABLE TRAS FIX** se lee «ya está publicado; el fix está pendiente».

| Archivo | Veredicto | Por |
|---|---|---|
| `config.php` | **PUBLICABLE TRAS FIX** | H-1, H-2, H-3, H-4, H-8 |
| `calculaStata.php` | **PUBLICABLE TRAS FIX** | H-1, H-4 |
| `logCalcular.php` | **PUBLICABLE TRAS FIX** | H-2, H-5, H-6 |
| `checkStataStatus.php` | **PUBLICABLE TRAS FIX** | H-6 |
| `cargaDefault.php` | **PUBLICABLE TRAS FIX** | H-7 |
| `jsonSankey.php`, `jsonSankeyEscol.php`, `jsonSankeyGrupoedad.php`, `jsonSankeyRural.php`, `jsonSankeySexo.php` | **PUBLICABLE TRAS FIX** | H-6; heredan H-3 |
| `jsonSankeyNTA.php`, `jsonEntidad.php` | PUBLICABLE | todas sus entradas en lista blanca; heredan H-3 |
| `plantilla-metodo.php`, `index.php`, `index-en.php`, `NTA/index.php`, `metodo/index.php`, `entidades/index.php`, `entidades/_entidad.php`, `entidades/_catalogo.php`, `health.php` | PUBLICABLE | — |
| `NTA/_cuerpo-{en,es}.php`, los cuatro `entidades/_cuerpo-*.php`, `cargaDefault-local.php` | PUBLICABLE | H-9, cosmético |
| 21 `metodo/<capítulo>/index.php` y 32 `entidades/<ABREV>/index.php` | PUBLICABLE | generados, sin entradas |

Ningún archivo queda en **NO PUBLICAR AÚN**: no hay un solo camino clase (c) vivo.

### 2.6 Fuera del repo, en el mismo VPS

**L-1 — Crítico, por confirmar en el servidor.** `iepsaltabaco.ciep.mx` y `tenencia.ciep.mx` resuelven a la misma IP que el Simulador, y sus sitios corren con el mismo `www-data`. Este repo no versiona su PHP. La copia local del sitio de tabaco (`../Tabaco/Mayo2026/02_website/calculaTabaco.php`, de mayo de 2026) toma `idSession` y los valores del formulario crudos de GET/POST y los pasa a `shell_exec` y al `.do` sin ninguna validación. Es la clase de fallo que `1e84789` describe en su mensaje y que `69988b3` muestra completa, los dos en la historia pública. Si lo desplegado coincide con esa copia, es ejecución de comandos como `www-data` en la máquina que comparte con el Simulador, y la carpeta `users/` del Simulador tiene 777. No se verificó contra el servidor; el sitio de tenencia no se revisó (no hay PHP suyo en la carpeta local).

Segundo punto del mismo tipo: `reconocimiento-vps.md:211` registra en julio un vhost `develop.ciep.mx → v6/` y el docroot `v7/` con `test_log.php` (§7.8). `develop.ciep.mx` ya no resuelve por DNS; si `v6/` y `v7/` siguen en disco con el PHP anterior a v8.11a y algún vhost los alcanza, tienen el mismo fallo.

**Estado de la familia pre-v8 al 2026-11-18 (adenda).** L-1 se confirmó en el servidor y se atendió el mismo día, fuera de este repo. Evidencia en `~/CIEP_Simuladores/diag-tabaco-rce-2026-11-18/` y `diag-tenencia-v6-2026-11-18/`.

| Sitio | Estado | Detalle |
|---|---|---|
| `tabaco/` (`iepsaltabaco.ciep.mx`) | **Parchado, forense limpio, en producción desde el 18-nov** | Lo desplegado era la copia local (11 PHP con el mismo sha256). Parche de 7 archivos con `seguridad.php`; batería de 253 comprobaciones; los 7 `OK` de `sha256sum -c` en el VPS. Forense: sin evidencia de explotación en bitácoras, artefactos y procesos; el barrido de los logs de Apache lo corrió Ricardo y sus secciones [1]–[4] salieron vacías. |
| `tenencia/` (`tenencia.ciep.mx`) | **Abajo; gemelo en curso** | Mismo fallo en `calculaStata.php`, más un `eval()` sobre la salida de Stata. Vhosts `003-tenencia` y `tenencia-ssl` deshabilitados. Parche de 3 archivos entregado (batería de 170), sin desplegar. |
| `v6/` (vhost `002-develop`) | **Abajo; gemelo en curso** | Era alcanzable por la IP con la cabecera `Host: develop.ciep.mx` aunque el nombre no resuelva. Corrió Stata hasta el 28-ene-2026. Vhost deshabilitado; retiro del docroot propuesto, sin ejecutar. |

`v7/` y `v8.0`–`v8.9` conservan en disco el `idSession` crudo; ningún vhost los sirve.

## 3. Semáforo

| Capa | Color | Razón |
|---|---|---|
| **1. HTML / JS / CSS / JSON** | **Verde** | Ya es pública de facto. En los 250 archivos de texto propios que se sirven (sitio sin `plugins/`, `04_3_anteriores/`, `nl-assets/`) no hay rutas internas, credenciales ni comentarios sensibles; `metodo.json` no trae rutas absolutas; no hay `console.log` en el JS propio. Una excepción cosmética: `04_3_anteriores/v1/derechos-hidrocarburos.php.html:7` es una página de error de PHP capturada con la ruta de la Mac. Las fugas en tiempo de ejecución son H-6. |
| **2. `.sh` de operación** | **Verde** (2026-11-18; era Rojo) | El rojo venía de G1-1 y de G1-2, y los dos quedaron decididos el 18-nov: G1-1, resuelto con riesgo residual aceptado; G1-2, decisión B, usuario e IP fuera de la plantilla y del runbook. Los scripts nunca llevaron credenciales. Un pendiente verificado al commit: `-datos/set_token.do` aún no trae el token nuevo (ver la resolución de G1-1). **Cerrado el mismo 18-nov:** ya lo trae (nota de cierre de G1-1). Antes: «Rojo. La regla es "verde solo si Gate 1 limpio", y no lo está (G1-1). […] Pasa a verde con el token rotado y G1-2 decidido.» |
| **3. `.php` del endpoint** | **Ámbar** | Veredicto por archivo en §2.5: 10 en PUBLICABLE TRAS FIX, 71 en PUBLICABLE, ninguno en NO PUBLICAR AÚN. |

La doctrina describe un hecho, no una decisión futura: las tres capas ya están publicadas. Lo que queda por decidir es el orden en que se cierra lo abierto, y L-1 va antes que todo lo demás porque no depende de este repo.

## 4. POR CONFIRMAR

Lo que esta sesión no pudo verificar, con la razón y cómo se confirma.

| # | Qué | Por qué no se pudo | Cómo |
|---|---|---|---|
| 1 | Si INEGI dio de baja el token expuesto | El BISE no valida el token; no hay forma externa de saberlo | Respuesta de `atencion.usuarios@inegi.org.mx` a la solicitud del 2026-05-12 |
| 2 | Que el token del clon de Dropbox (`9170596f05`) sea el emitido tras la rotación | Solo se comparó su hash | Ricardo |
| 3 | Si Apache sirve `/logs/calcular_clicks.log` | La sesión no toca el endpoint | `curl -sI https://simuladorfiscal.ciep.mx/logs/calcular_clicks.log` |
| 4 | Dueño y permisos reales de `users/ciepmx`, y grupos de `www-data` | No se entra al VPS | `stat -c '%U:%G %a' /SIM/OUT/current/users/ciepmx; id www-data` |
| 5 | Si una petición con `Host` arbitrario llega al vhost del Simulador, y si `/var/www/html/` es escribible por `www-data` | Idem | Configuración de Apache y `ls -ld /var/www/html` |
| 6 | Versión desplegada y PHP del VPS (julio: 8.1.2) | Idem | `health.php`; `php -v` |
| 7 | Si `v6/`, `v7/`, `test_log.php` y el vhost `develop` siguen en el VPS | Idem | `ls /var/www/html; ls /etc/apache2/sites-enabled` |
| 8 | Que el PHP desplegado de tabaco sea el de la copia local, y el estado del de tenencia | Idem; tenencia no tiene copia local | Comparar en el VPS |
| 9 | Si `sshd` acepta contraseña | Idem | `sshd -T \| grep -i passwordauth` |
| 10 | Qué cron limpia `users/0*` y qué pasa con `users/humo*` | `reconocimiento-vps.md:463` lo dejó pendiente | `sudo crontab -l -u www-data; cat /etc/crontab` |
| 11 | Qué contiene el log batch de Stata que `checkStataStatus.php` devolvería (H-6 iii) | No se corrió Stata | Leer un `<id>.log` del VPS |
| 12 | Otros commits colgantes en GitHub | No se pueden enumerar; se probaron `2f46d92`, `464741d`, `499a06f` | GitHub Support |
| 13 | Los 71 blobs mayores de 3 MB de la historia vieja, los `.xlsx` dentro de los zips y los assets grandes de las Releases | No se bajaron o no se abrieron; son binarios de fuentes públicas | Solo si se quiere cerrar por completo |
| 14 | A qué se refiere «Bitácora» en el encargo | `02_governance/README.md` dice que el único registro es `CHANGELOG.md`; el encargo dice «nada más se toca» | Se interpretó como §7 de este documento; ver decisión 9 |

Fuera del alcance: el JavaScript del sitio (XSS en cliente) no se auditó; el gate es del PHP.

## 5. Contradicciones entre documentos vigentes

1. **El SHA viejo «ya no existe».** `02_governance/versionado-y-git.md:223,233,378` y `02_governance/historico/fase-0-5-git-hygiene-audit.md:3` dicen que `2f46d92` ya no es referenciable. GitHub lo sirve por API, por web y por `git fetch`.
2. **Ventana y cierre del incidente del token.** `02_governance/politicas-institucionales.md:205` dice que estuvo expuesto del 2018-10-29 al 2026-05-12 y que la sustitución y la reescritura están hechas. En la historia vieja `AccesoBIE.ado` entra el 2025-03-29 y la línea con el token el 2025-12-11 (`464741d`); el fork de 2025-02 no lo tiene; y `-datos/set_token.do` sigue con ese token. `.gitignore:111` habla del «token BIE post-rotación».
3. **Las dos plantillas de credenciales se contradicen.** `05_scripts/endpoint-credentials.template.sh` dice «NUNCA reemplaces los valores en esta plantilla» y viene vacía; `05_scripts/publicar-vps-credentials.template.sh` trae el usuario y la IP reales.
4. **La bitácora de clics.** `logCalcular.php:40–42` dice «sin inyección de renglones falsos» y `test-sitio-seguridad.sh:174–176` lo prueba con un salto intermedio; el salto final pasa (H-2).

## 6. Lo que decide Ricardo

1. Este reporte: ¿se sube al repo público ahora, después de los fixes, o resumido? La sesión no hizo push.
2. Token del BIE: quién cambia `-datos/set_token.do` y quién pide a INEGI la confirmación de la baja.
3. Historia colgante y fork: ¿se pide la purga a GitHub Support y el borrado del fork, o se acepta con el token rotado y solo se gestionan las bitácoras con nombres e IP?
4. Usuario e IP del VPS: ¿se aceptan como públicos y se endurece `sshd`, o salen del árbol vivo?
5. `historico/reconocimiento-vps.md`: ¿se queda, se redacta o se retira?
6. Fixes del PHP: ¿H-1 a H-9 en una sola sesión `fix/`? Orden sugerido: H-1, H-5, H-3, H-4, H-2 y después los bajos.
7. Tabaco y tenencia (L-1): ¿se auditan y endurecen ya, o se bajan mientras tanto?
8. ¿Se activan secret scanning y push protection, y entra gitleaks con la regla de Stata al CI?
9. `02_governance/README.md` pide actualizar el índice en el mismo commit que agrega un documento, y la plantilla `memo.md` pide una línea en `[Unreleased]`. El encargo decía «nada más se toca» y no se tocaron. ¿Se agregan al PR?

## 7. Bitácora de la sesión

**Qué se hizo, en orden.**

1. Reconocimiento del repo: ramas, 61 tags, worktrees, `.gitignore`, `02_governance/README.md`, plantillas de `prompts/`. `gh repo view` → público. `git fetch --all --tags --prune` en el clon de Dropbox (movió `origin/master` de `9eb0585` a `e2e3f0d` y podó una rama remota borrada; no tocó el árbol de trabajo).
2. `brew install gitleaks` (8.30.1). No estaba instalado; la limpieza automática de Homebrew borró dos carpetas vacías de logs suyas.
3. Espejos en la carpeta de evidencia: `origin`, el fork, y la historia anterior a la reescritura a partir de `2f46d92`.
4. gitleaks sobre los tres espejos y el clon local; `barrido.py` y `barrido2.py` sobre los cuatro almacenes de objetos; búsqueda por coincidencia exacta de los valores vivos; barrido de 20 assets de Releases.
5. Prueba del token contra la API de indicadores de INEGI con `curl`: seis GET del dato más reciente de un indicador (una con el token expuesto, cinco con tokens inválidos de control). Resultado no discriminante.
6. Worktree `~/CIEP_Simuladores/wt-auditoria-publicacion` desde `origin/master`. `verify_gitignore.sh` ahí, en el clon de Dropbox y en `-datos` (solo lee).
7. Lectura de los 28 PHP no generados (los que reciben entradas, completos; `index.php`, `index-en.php` y los parciales, por sus bloques PHP) y comparación de los 53 generados; `php -w` para separar código vivo de comentarios; `test-sitio-seguridad.sh` (0 fallos); `poc-gate2.sh` con las pruebas P1–P8 en una copia temporal.
8. Lectura, sin modificar, de `../Tabaco/Mayo2026/02_website/` (fuera del repo) y cuatro consultas DNS.
9. Este documento, commiteado en la rama local. Sin push ni PR.

**Qué no se hizo.** Ninguna petición a `simuladorfiscal.ciep.mx`, al VPS ni al endpoint Stata. Ningún cambio de código, de `.gitignore`, de README ni de CHANGELOG. Ningún fix. Nada escrito en el clon de Dropbox ni en `-datos`; el clon de Dropbox sigue en `ricardo/piramide-sexo` con su `simulador.stpr` modificado, como estaba.

**Lo que queda en disco.** La carpeta de evidencia (1.0 GB) contiene los espejos del fork y de la historia vieja, que incluyen el token y las bitácoras con datos de visitantes; son copias de material ya público y se pueden borrar al cerrar la decisión 3. Los JSON de los barridos se guardaron con el token y las IP de visitantes enmascarados. El worktree y la rama local quedan en pie hasta la decisión 1.

## 8. Adenda del 2026-11-18 — lo que se resolvió después de la auditoría

Las secciones anteriores quedan como se escribieron, salvo las notas fechadas (G1-1 y su cierre, G1-2, §2.6 y el semáforo) y el valor de G1-2 en la tabla de hallazgos, que ya no va en claro.

| Punto de la auditoría | Qué pasó |
|---|---|
| G1-1; §4 fila 1; §6 decisión 2 | Resuelto con riesgo residual aceptado. INEGI no revoca: la fila 1 de §4 deja de estar pendiente de su respuesta. Falta que `-datos/set_token.do` traiga el token nuevo. |
| G1-1, cierre (misma fecha, tarde) | `-datos/set_token.do` ya trae el token nuevo. Diseño adoptado: token de cortesía público dedicado (`info@ciep.mx`) + override opcional, en la rama `sesion/token-cortesia`; política en `politicas-institucionales.md` Parte I §3.4. El token expuesto salió de las tres copias de `AccesoBIE.ado` fuera de git que aún lo traían. Detalle en la nota de cierre de G1-1. |
| G1-1, VPS de tabaco (Ricardo, 2026-11-18) | `/SIM/OUT/tabaco/Mayo2026/AccesoBIE.ado` en el servidor conserva el token expuesto hardcodeado (copia vieja). Se corrige con el despliegue del `v1.0.0` de tabaco desde su repo nuevo. El diseño de cortesía se publicó en el Simulador como `v8.19.0` (PR #79). |
| G1-2; §5 contradicción 3; §6 decisión 4 | Decisión B: marcadores en la plantilla, el runbook y la bitácora. Las dos plantillas de credenciales ya dicen lo mismo. |
| G1-3; §6 decisión 5 | `historico/reconocimiento-vps.md` no se toca aquí; va a la sesión de purga de historia (§6 decisión 3), planeada como higiene. |
| L-1; §4 filas 7 y 8; §6 decisión 7 | Confirmado y atendido: tabaco en producción con parche; tenencia y `v6` abajo, con el gemelo en curso (§2.6). `v6/`, `v7/` y el vhost `develop` seguían en el VPS. |
| L-1, tabaco: verificación en producción (Ricardo, 2026-11-18) | Tabaco: parche RCE verificado en producción el 2026-11-18. Flujo legítimo completo en navegador (POST a `calculaTabacoBis.php` con 200) y lectura del código desplegado: whitelist en `lee_idSession()`, revalidación en `prepara_sesion()`, `borra_arbol()` nativo en lugar de `rm -rf`, `escapeshellarg` en `cmd_stata()`. |
| Semáforo | Capa 2 pasa a Verde. Capa 1 sigue Verde y Capa 3, Ámbar (H-1 a H-9 sin tocar). |
| §6 decisión 1 | Un solo push de esta rama cuando cierre el gemelo. |

Cambios versionados de la adenda, fuera de este archivo: `05_scripts/publicar-vps-credentials.template.sh`, `02_governance/runbook-deploys-ciep.md` (cuatro líneas con `<USUARIO>@<IP_VPS>` y una fila nueva en «Gotchas de deploy» con el inventario de la familia pre-v8 y la regla de `seguridad.php`) y `02_governance/historico/bitacora-arquitectura.md` (una línea). Siguen pendientes de decisión: §6 puntos 3, 6, 8 y 9.
