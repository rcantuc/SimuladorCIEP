# Reconocimiento del VPS de simuladorfiscal.ciep.mx (IONOS)

**Fecha:** 2026-07-09
**Ejecutado por:** Devin (bajo dirección de Ricardo Cantú)
**Modo:** solo lectura (SSH read-only, sin escritura ni modificación)
**Duración:** ~12 minutos (03:45:07 a 03:57:11, hora del servidor)
**Timestamp de acceso registrado:** 2026-07-09T03:45:07-06:00 (inicio) → 2026-07-09T03:57:11-06:00 (última lectura)

---

## Índice

1. [Contexto y método](#1-contexto-y-método)
2. [Inventario de /var/www/html/](#2-inventario-de-varwwwhtml)
3. [Inventario de /SIM/](#3-inventario-de-sim)
4. [Cómo corre Stata](#4-cómo-corre-stata)
5. [Arquitectura del sitio](#5-arquitectura-del-sitio)
6. [Diff local ↔ remoto](#6-diff-local--remoto-04_simuladorfiscalciepmx-vs-varwwwhtmlv7)
7. [Observaciones operativas](#7-observaciones-operativas)
8. [Fingerprint del estado actual](#8-fingerprint-del-estado-actual)
9. [Anexo: comandos ejecutados](#9-anexo-comandos-ejecutados)

---

## 1. Contexto y método

*Qué aprendes en esta sección:* por qué se hizo este reconocimiento y bajo qué reglas.

Este reporte es el producto de la **Fase 2 del roadmap de deployment automatizado** al VPS que sirve `simuladorfiscal.ciep.mx`. La Fase 1 (reconocimiento institucional del estado de las credenciales) cerró en el commit `0b43117`. El objetivo aquí es la primera radiografía objetiva del servidor de producción: qué hay, dónde vive, cómo corre, y qué tan desfasado está respecto al repo (v8.0.6).

**Método:** conexión SSH con las credenciales del investigador principal, tecleadas por él directamente en la terminal (nunca almacenadas en archivos ni logs). Se usó una conexión maestra de SSH (multiplexada) para no re-autenticar en cada comando. **Cero comandos de escritura**: solo navegación, lectura, metadata, hashes y consulta de procesos. La sesión se cerró explícitamente al terminar y el investigador principal rota la password en el panel de IONOS después de esta sesión.

**Sistema base encontrado:**

| Atributo | Valor |
|---|---|
| Sistema operativo | Ubuntu 22.04.2 LTS (Jammy Jellyfish) |
| Kernel | Linux 5.15.0-164-generic x86_64 |
| Usuario de trabajo | `ciepmx` (uid 1000; grupos: `ciepmx`, `sudo`, `web`) |
| Home / shell | `/home/ciepmx` / `/bin/bash` |
| Zona horaria | America/Mexico_City (CST, -0600), NTP activo |
| RAM / disco | 8 GB / 232 GB (12.3% usado) |
| Uptime | 161 días (desde ~enero 28 de 2026) |
| Único usuario humano en `/etc/passwd` | `ciepmx` |

**Señales de mantenimiento pendiente del OS** (no bloquean, pero se registran): el sistema pide reinicio (`*** System restart required ***`), hay 98 actualizaciones aplicables, y existe upgrade disponible a Ubuntu 24.04.4 LTS.

---

## 2. Inventario de /var/www/html/

*Qué aprendes en esta sección:* qué sitios viven en el docroot del servidor y cómo está compuesto el del Simulador Fiscal.

`/var/www/html/` (133 MB) no es solo el Simulador Fiscal — es el docroot compartido de **los tres Simuladores CIEP**:

| Directorio | Sitio que sirve | Notas |
|---|---|---|
| `v7/` | `simuladorfiscal.ciep.mx` (HTTPS) | **El Simulador Fiscal en producción.** 44 MB, 2,110 archivos |
| `v6/` | `develop.ciep.mx` | Versión anterior, usada como ambiente de desarrollo |
| `tabaco/` | `iepsaltabaco.ciep.mx` | Simulador IEPS al tabaco |
| `tenencia/` | `tenencia.ciep.mx` | Simulador de tenencia (modificado hoy 00:10 por cron de logs) |
| `HTML Tenencia/` | — | Copia de trabajo de tenencia + `HTML-Tenencia.zip` y `tabaco.tgz` sueltos |

**Versiones del Fiscal presentes:** solo `v6/` y `v7/`. No existe `v5.3/` en el filesystem (aunque un vhost viejo lo referencia, ver §7) ni `v8/`.

**Composición de `v7/` por extensión** (dominada por assets de plugins):

```
1436 svg   243 html   186 js   60 png   48 css   21 gif
  18 scss   18 less    15 json 14 php   10 map    5 yml
   5 jpg  (resto: fuentes woff/ttf/eot, md, 2 key, 1 log, ...)
```

**Actividad reciente:** el único archivo modificado en los últimos 30 días es `logs/calcular_clicks.log` (bitácora de clicks del botón Calcular, escrita por el servidor web). El código no se toca desde el 29 de marzo de 2026 (`index.php`, `index-en.php`) y el resto mayormente desde el 29 de enero.

**Los 14 archivos PHP de `v7/`** (el corazón dinámico del sitio):

```
calculaStata.php          cargaDefault-local.php    cargaDefault.php
checkStataStatus.php      config.php                index-en.php
index.php                 jsonSankey.php            jsonSankeyEscol.php
jsonSankeyGrupoedad.php   jsonSankeyRural.php       jsonSankeySexo.php
logCalcular.php           test_log.php
```

**Hallazgo de seguridad dentro del docroot:** `v7/ssl/` contiene dos llaves privadas SSL (`simuladorfiscal.ciep.mx_private_key.key` y `iepsaltabaco.ciep.mx_private_key.key`) con permisos `664` (legibles por cualquier usuario del sistema) y **dentro del directorio público del sitio web**. Ver observación §7.2. No se leyó el contenido de las llaves.

---

## 3. Inventario de /SIM/

*Qué aprendes en esta sección:* dónde vive el motor Stata del Simulador en el servidor y qué tan desfasado está respecto al repo.

`/SIM/` (8.9 GB) es el directorio del motor de cálculo, con esta estructura:

```
/SIM/OUT/7/          ← motor del Simulador Fiscal (5.5 GB) — LA versión activa
/SIM/OUT/Tenencia/   ← motor del simulador de tenencia
/SIM/OUT/tabaco/     ← motor del simulador de tabaco (subcarpetas 1, Feb2025, Nov2025, Mayo2026)
/SIM/OUT/log/        ← logs de sesión archivados por cron (6, 7, Tenencia, tabaco)
```

**Versiones OUT/N del Fiscal:** solo existe `7`. No hay `OUT/8` (el repo va en v8.0.6) ni versiones anteriores archivadas — `OUT/log/6` sugiere que la 6 existió y fue retirada.

**`/SIM/OUT/7/` es un snapshot completo del repo de la era v7** (equivalente a `c(sysdir_site)` local): los `.ado` del canon, decenas de `.do` de análisis en el root (la estructura previa a la reorganización v1.12 del repo), `01_modulos/` con los subdirectorios viejos, los schemes con nombres pre-renombrado (`scheme-ciepingresos`, `scheme-ciepdeuda`, etc.), `simulador.stpr`, `profile.do`, `SIM.do`, `Web.Stata.do` — más las carpetas de operación:

| Carpeta | Tamaño | Contenido |
|---|---|---|
| `master/` | 5.0 GB | Datasets maestros: `PEF.dta` (1.6 GB), `DatosAbiertos.dta` (545 MB), `perfiles2026.dta` (128 MB), `Poblacion.dta` (41 MB), etc. Fechados 19-mar-2026 |
| `users/` | 561 MB | Sesiones de usuarios web. Hoy casi vacío: `ciepmx/` + restos de una sesión con id vacío (`.do`, `.log`, `output.txt` del 15-abr) |
| `graphs/` | — | Vestigio (el repo v8 lo eliminó en v1.13) |
| `01_modulos/` | — | 7 subdirectorios, estructura pre-v1.12 |

**Los 25 `.ado` presentes** (fechados 19-mar-2026 los del canon; el repo tiene 27):

```
AccesoBIE  CICLO  CuentasGeneracionales  DatosAbiertos  Distribucion
FiscalGap  GastoPC  Gini  INCI  LIF  PC  PEF  PERF  PIBDeflactor
Perfiles  Poblacion  REC  SCN  SHRFSP  SankeySumLoop  SankeySumSim
Simulador  TasasEfectivas  claude  scalarlatex
```

- **Faltan respecto al repo v8.0.6:** `ensure_asset.ado` y `sim_changelog.ado` (ambos nacieron con v8).
- **Extra respecto al repo:** `claude.ado` (+ `Web.Claude.do` y `js/chatbot.js` en el sitio) — experimento de chatbot de marzo de 2026 que no está versionado en el repo.
- **No hay `.sthlp`, `.pkg` ni `.toc`** en `/SIM/OUT/7/` (la documentación de ayuda y el canal `net from` viven en Cloudways, no en este VPS — consistente con la arquitectura documentada).
- **Sí hay `.do`:** `SIM.do`, `Web.Stata.do` (plantilla del canal web), `profile.do`, y ~40 `.do` de análisis de la era v7.

**Desfase de cartuchos de versión** (la línea `*!` al inicio de cada `.ado`): los 10 `.ado` que en el repo v8.0.6 llevan `*! version 8.0 CIEP 03jul2026` **no tienen cartucho en el servidor** (o tienen uno viejo):

| `.ado` | Repo v8.0.6 (local) | VPS `/SIM/OUT/7/` |
|---|---|---|
| AccesoBIE | `*! version 8.0 CIEP 03jul2026` | `*! AccesoBIE v2.0` (formato viejo) |
| DatosAbiertos, GastoPC, LIF, PEF, PIBDeflactor, Poblacion, SCN, SHRFSP, TasasEfectivas | `*! version 8.0 CIEP 03jul2026` | sin cartucho |
| ensure_asset | `*! ensure_asset v1.1` | **no existe** |
| sim_changelog | `*! version 8.0 CIEP 03jul2026` | **no existe** |
| resto del canon | sin cartucho (igual que remoto) | sin cartucho |

**Conclusión del inventario:** el servidor corre un snapshot congelado del 19-21 de marzo de 2026 — anterior al nacimiento institucional de v8 (mayo-julio). Todo el arco de governance del repo (cartuchos, data sidecar, reorganización estructural, changelog) **no ha llegado a producción**.

---

## 4. Cómo corre Stata

*Qué aprendes en esta sección:* dónde está Stata en el servidor, quién lo invoca y qué deja como rastro.

- **Binario:** `/usr/local/stata17/stata-mp` (Stata 17 MP; `installed.170` presente en el directorio). **No está en el PATH** — `which stata` no lo encuentra; el PHP lo invoca con ruta absoluta. No se ejecutó Stata durante este reconocimiento.
- **Configuración de SITE:** no hay `profile.do` a nivel sistema en `/usr/local/stata17/` ni `/usr/local/ado/`. El SITE se fija **dentro de `Web.Stata.do`**: `sysdir set SITE "/SIM/OUT/7/"` (con rama para la Mac del investigador principal cuando corre localmente). **Este hardcode del `7` es una de las dos anclas de versión del deployment** (la otra es `config.php`, §5).
- **Invocación:** `calculaStata.php` ejecuta vía `shell_exec()`:

```
cd /SIM/OUT/7/users/<idSession> && "/usr/local/stata17/stata-mp" -b do <idSession>.do 2>&1
```

- **Procesos activos:** ningún proceso Stata corriendo al momento del reconocimiento.
- **Cron del usuario `ciepmx`** (3 entradas, todas de archivado de logs de sesión a medianoche):

```
10 0 * * * /usr/bin/mv /var/www/html/tenencia/0* /SIM/OUT/log/Tenencia/
5 0 * * *  /usr/bin/mv /var/www/html/tabaco/0*   /SIM/OUT/log/tabaco/
0 0 * * *  /usr/bin/mv /var/www/html/v6/0*       /SIM/OUT/log/7/
```

  Nota: la tercera entrada recoge sesiones de **`v6/`** y las guarda en `log/7/` — vestigio de cuando las sesiones se creaban dentro del docroot. Las sesiones de v7 se crean en `/SIM/OUT/7/users/` y **ningún cron visible las limpia** (ver pregunta abierta en §7.6).
- **No hay cronjob que ejecute Stata.** Stata solo corre bajo demanda del sitio web.
- **Logs de ejecución:** `/SIM/OUT/log/7/` acumula 927 logs de sesión (`0XXXX.log`). Cada sesión también deja `<id>_execution.log` dentro de su carpeta en `users/`. El sitio escribe `logs/calcular_clicks.log` (60 KB, activo — última escritura 8-jul 15:17).

---

## 5. Arquitectura del sitio

*Qué aprendes en esta sección:* cómo viaja una simulación desde el navegador del usuario hasta Stata y de regreso.

**Flujo completo de una simulación:**

```
Usuario (navegador)
   │  mueve sliders/campos y pulsa "Calcular"
   ▼
index.php (frontend monolítico, 192 KB; index-en.php versión en inglés)
   │  js/stataCalcula.js arma el POST con ~150 parámetros (idSession + llaves)
   ▼
calculaStata.php
   │  1. limpia y recrea /SIM/OUT/7/users/<idSession>/
   │  2. lee la plantilla /SIM/OUT/7/Web.Stata.do
   │  3. sustituye los placeholders {{LLAVE}} por los valores del usuario
   │  4. escribe <idSession>.do y ejecuta:  stata-mp -b do <idSession>.do
   ▼
Stata 17 MP  (SITE = /SIM/OUT/7/, datasets de master/, .ado del root)
   │  corre el pipeline completo y, vía output.do, escribe output.txt
   │  (log Stata con pares NOMBRE:valor y NOMBRE:[array])
   ▼
calculaStata.php (continuación)
   │  parsea output.txt con regex → arma JSON → registra <id>_execution.log
   ▼
JSON → js/stataCalcula.js → actualiza gráficas (apexcharts/flot) → Usuario
```

**Piezas de soporte:**

- **`config.php`** — variables globales: `$TMP_PATH = /SIM/OUT/7/users/`, `$calcula_ruta = /SIM/OUT/7/Web.Stata.do`, `$stata_exe = /usr/local/stata17/stata-mp`, generador de `idSession` (`'0'` + 4 caracteres aleatorios), detección local/servidor. **Segunda ancla de versión** (`7` hardcodeado dos veces). No contiene secretos.
- **`cargaDefault.php`** — al abrir la página, genera los valores default ejecutando Stata del mismo modo (en servidor; en localhost lee un `output.txt` precalculado).
- **`checkStataStatus.php`** — endpoint de polling que espera archivos `<id>.done` y `<id>.pid`... que **nada escribe hoy**: `calculaStata.php` es síncrono. Resto de una arquitectura asíncrona abandonada (ver §7.7).
- **`jsonSankey*.php`** (5 endpoints) — sirven los datos de los diagramas Sankey por decil, grupo de edad, sexo, rural y escolaridad, leyendo los CSV/outputs de la sesión.
- **`logCalcular.php` / `test_log.php`** — bitácora de clicks y página de debug del sistema de logs (pública, ver §7.8).

**Lo que NO hay:** base de datos (ningún puerto 3306/5432 escuchando; solo 22, 80 y 443), caché de resultados (cada corrida recalcula todo), colas de trabajo, contenedores. La sesión del usuario es una carpeta en el filesystem.

**Servidor web:** Apache 2.4 + PHP 8.1.2. Vhosts activos: HTTPS `simuladorfiscal.ciep.mx → /var/www/html/v7/` (el nombre del archivo de config es `simuladorfiscal5.3-ssl.conf`, herencia), `iepsaltabaco → tabaco/`, `tenencia → tenencia/`, `develop.ciep.mx → v6/`. El vhost HTTP redirige todo a HTTPS (`Redirect permanent`), aunque declara un `DocumentRoot /var/www/html/v5.3` que ya no existe (inofensivo por el redirect, ver §7.9). El `.htaccess` de v7 solo fija CORS abierto (`Access-Control-Allow-Origin *`).

---

## 6. Diff local ↔ remoto (04_simuladorfiscal.ciep.mx/ vs /var/www/html/v7/)

*Qué aprendes en esta sección:* la primera medición objetiva de la sincronía entre el clon local del sitio (en la Mac del investigador principal, gitignored) y producción.

Se calcularon SHA-256 de **todos** los archivos de ambos lados (2,109 locales; 2,110 remotos) y se compararon por ruta relativa. Ningún archivo fue tocado.

### 6.1 Solo en local (4 archivos)

```
calcular_clicks.log                                (log suelto en raíz — residuo de prueba local)
ssl/2026a/simuladorfiscal.ciep.mx_private_key.key  ┐
ssl/2026a/simuladorfiscal.ciep.mx_ssl_certificate.cer │ material de renovación SSL 2026
ssl/2026a/simuladorfiscal5.3-ssl.conf              ┘
```

Interpretación: no hay *features* de código sin propagar. Lo único local-solamente es el material de la renovación SSL 2026 (`ssl/2026a/`) — **pregunta abierta: ¿ya se aplicó en el servidor?** El `ssl/` remoto solo tiene llaves de enero (§7.10).

### 6.2 Solo en remoto (5 archivos)

```
.DS_Store              (basura de Finder de macOS)
js/chatbot.js          (widget de chat que invoca claude.ado — experimento no versionado)
ssl/iepsaltabaco.ciep.mx_private_key.key
ssl/simuladorfiscal.ciep.mx_private_key.key
test_log.php           (página de debug del sistema de logs)
```

Interpretación: dos artefactos de runtime/secretos (las llaves), basura (.DS_Store), y **dos piezas de código que existen solo en producción** (`chatbot.js`, `test_log.php`) — modificaciones directas en el servidor que nunca bajaron a local.

### 6.3 Contenido distinto (1 archivo)

```
logs/calcular_clicks.log
```

Interpretación: esperado — es el log vivo de producción; el local es una copia vieja.

### 6.4 Magnitud del drift

| Métrica | Valor |
|---|---|
| Archivos idénticos (ruta + SHA-256) | 2,104 |
| Con contenido distinto | 1 (log de runtime) |
| Solo local | 4 |
| Solo remoto | 5 |
| **Sincronía global** | **2,104 / 2,114 = 99.5%** |

**Conclusión:** el código del sitio (PHP/JS/HTML/CSS) está **100% sincronizado** — las 10 diferencias son runtime (logs), secretos (llaves SSL), basura (.DS_Store) y dos archivos experimentales/debug solo-remotos. El modelo mental de Ricardo ("está sincronizado") se confirma para el código; el drift real está en los bordes.

---

## 7. Observaciones operativas

*Qué aprendes en esta sección:* riesgos, vestigios y preguntas abiertas que las Fases 3-6 deben tomar en cuenta.

### 7.1 Proceso zombi consumiendo un núcleo completo desde mayo

El PID 1975745 (`root`) ejecuta `more /etc/apache2/sites-available/simuladorfiscal5.3-ssl.conf` al **100% de CPU desde el 11 de mayo** (~58 días-CPU acumulados; explica el load average constante de 1.0). Es un `more` lanzado con `sudo` que quedó colgado sin terminal — no parece malicioso (comando de inspección inocuo, coincide con la sesión `pts/1` del 11-may desde 132.248.237.220 que sigue abierta). **Acción sugerida:** Ricardo lo mata con `sudo kill 1975745` y cierra la sesión colgada. No se tocó por la regla de solo-lectura.

### 7.2 Llaves privadas SSL dentro del docroot y legibles por todos

`/var/www/html/v7/ssl/*.key` con permisos 664 dentro del directorio público. Si Apache no bloquea explícitamente la extensión `.key`, cualquiera podría descargarlas por HTTP. **Acción sugerida:** verificar si `https://simuladorfiscal.ciep.mx/ssl/simuladorfiscal.ciep.mx_private_key.key` responde, moverlas fuera del docroot y restringir permisos (Fase 3+; si responden por HTTP, rotación de certificado).

### 7.3 El deployment tiene exactamente dos anclas de versión

Para pasar de v7 a v8 hay que tocar: (a) `sysdir set SITE "/SIM/OUT/7/"` en `Web.Stata.do`, y (b) `$TMP_PATH` y `$calcula_ruta` en `config.php`. Todo lo demás (PHP, JS, cron) es agnóstico a la versión. Esto simplifica el diseño de `publicar-vps.sh` (Fase 5): el switch de versión es un cambio de dos archivos + poblar `/SIM/OUT/8/` + `/var/www/html/v8/` (o mantener el docroot y solo actualizar el motor).

### 7.4 Producción está congelada en la era pre-v8

Snapshot del 19-21 de marzo: sin cartuchos v8, sin `ensure_asset.ado`/`sim_changelog.ado`, estructura de `01_modulos/` y schemes pre-reorganización v1.12. La cadena institucional de reproducibilidad (manifest, changelog, releases) **no existe en el VPS**. La Fase 5 debe decidir si `/SIM/OUT/8/` se puebla desde el repo Git (ideal: `git archive` o rsync desde clon) o manualmente.

### 7.5 Datasets maestros pesados fuera de todo versionado

`master/` (5 GB: `PEF.dta` 1.6 GB, `DatosAbiertos.dta` 545 MB...) se subió manualmente en marzo. El data sidecar de GitHub Releases (v8) cubre los **insumos crudos**, pero estos `.dta` **procesados** no tienen canal de deployment definido. Pieza crítica para Fase 5: ¿el VPS los regenera corriendo `SIM.do` o se suben procesados?

### 7.6 Limpieza de sesiones: mecanismo no identificado

Las sesiones web se crean en `/SIM/OUT/7/users/` pero hoy solo existe `ciepmx/` (y `users/` fue modificado hoy a las 01:00:01, patrón de cron). El crontab de `ciepmx` no la explica; ver el de `www-data` o `root` requiere `sudo` (no ejercido). **Pregunta abierta:** ¿qué limpia `users/`? Documentarlo antes de Fase 5 para no romperlo.

### 7.7 Arquitectura asíncrona abandonada a medias

`checkStataStatus.php` espera `<id>.done`/`<id>.pid` que ningún código actual escribe (`calculaStata.php` es síncrono). Código muerto que confundirá a quien diseñe el deployment. Candidato a retiro en el próximo deploy.

### 7.8 Artefactos de debug/experimento en producción

`test_log.php` (página pública de debug) y el par `chatbot.js` + `claude.ado` + `Web.Claude.do` (experimento de chatbot, no referenciado por `index.php`, no versionado en el repo). Decisión pendiente: versionar o retirar.

### 7.9 Vestigios de configuración

El vhost HTTP declara `DocumentRoot /var/www/html/v5.3` (inexistente — inofensivo porque redirige a HTTPS antes de servir nada); el conf SSL activo se llama `simuladorfiscal5.3-ssl.conf` pero apunta a `v7/`; el cron nocturno recoge sesiones de `v6/` hacia `log/7/`. Nada roto, pero nomenclatura engañosa para un mantenedor nuevo.

### 7.10 Preguntas abiertas para Ricardo

1. ¿La renovación SSL `ssl/2026a/` local ya está aplicada en el servidor? (El `ssl/` remoto solo tiene material de enero.)
2. ¿Qué mecanismo limpia `/SIM/OUT/7/users/`? (§7.6 — requiere `sudo crontab -l -u www-data` o revisar `/etc/cron.*` con sudo.)
3. ¿La sesión SSH `pts/1` del 11-may desde 132.248.237.220 (rango UNAM) es tuya? ¿Autorizas matar el `more` zombi (§7.1)?
4. ¿`claude.ado`/`chatbot.js` se versionan en el repo o se retiran de producción?
5. ¿Los `.dta` de `master/` deben regenerarse en el VPS o subirse procesados en cada deploy (§7.5)?

### 7.11 Estado del bus factor

Confirmado en el servidor: **bus factor 1**. Un solo usuario humano (`ciepmx`), credenciales solo en poder del investigador principal, sin llaves SSH autorizadas de terceros observadas en el flujo de trabajo actual (autenticación por password).

**No se encontró evidencia de compromiso:** un solo usuario en `/etc/passwd` con uid ≥ 1000, cron limpio, procesos explicables (el zombi de §7.1 tiene explicación benigna), puertos esperados (22/80/443).

---

## 8. Fingerprint del estado actual

*Qué aprendes en esta sección:* la línea base criptográfica para detectar cualquier cambio futuro en el servidor.

**Tamaños exactos (du -sb):**

| Directorio | Bytes |
|---|---|
| `/var/www/html/v7/` | 39,814,353 |
| `/SIM/OUT/7/` | 5,900,270,520 |

**Timestamps de última modificación de los directorios principales:**

```
2026-03-29 17:28:43 -0600  /var/www/html/v7
2026-03-21 02:31:05 -0600  /SIM/OUT/7
2026-03-19 21:08:51 -0600  /SIM/OUT/7/master
2026-07-09 01:00:01 -0600  /SIM/OUT/7/users      (runtime)
2026-03-19 21:16:55 -0600  /SIM/OUT/7/01_modulos
```

**SHA-256 de los 14 PHP de `/var/www/html/v7/`:**

```
99f214e70742f57329b6db5e9857b1d5acc0404643a854f4927e02648f1c6336  calculaStata.php
bacfb0c2929e846e3a4bf5b1259e1c0ca1065569d99db8655dc9e9241572d2f0  cargaDefault-local.php
5f70b5238611085878a9f295e3e4cf08296d66470400e5d955e1e68338fb0d64  cargaDefault.php
d3dae1199ba4b8b7a6d48df1abe449ff13a596019f09eb2d4272ec27a978539b  checkStataStatus.php
395c58f69ce0e9b619d0188b40f4672bfcd3a6941c6cc898307412f8ad540e39  config.php
fd0a7d6be1484644e627f48ae269bbe2c1a5897667fe36bbdf94fe596394b83c  index-en.php
6983bc459ae4ad54eda5f58786d333143e3167a07a611727e400306f2abf173d  index.php
3fe3ddfc5162fab9ecfce0cd56ef3a4fc280563b5d770432ec8c55adfd446541  jsonSankey.php
caf4a5e7d465bea290bd03edb3377af59219b499d03c5ed8d5cfcfe2bb439b87  jsonSankeyEscol.php
975982d30b280c1171e7d1ada9ea9199a993472b4ca0c9ea512afb894e689ff7  jsonSankeyGrupoedad.php
7655841d5237f57ebf0cbd835940a3b05ce198e66f48153420e43a2f51bfdecd  jsonSankeyRural.php
674acd3151ffb8c46a75527941b68a88c3c924dc59c70588df842c0f7bdcee5b  jsonSankeySexo.php
c6aa3d6b74a0aeb0af881589b1ac441943c6a9620cd77d52d025c6fdb7e00b23  logCalcular.php
3cd0dd5f49013123d675878daf16aff192f0dc037a88b5419bc897756f4a9289  test_log.php
```

**SHA-256 de los 25 `.ado` + 3 `.do` clave de `/SIM/OUT/7/`:**

```
6e729a1ed20c34d17a1f5a0de4755e57e1e312e1e10e47bc7542983868e26afb  AccesoBIE.ado
16038de6fc415e919965c503636263340253aa672cc97792a2582413e6a0c139  CICLO.ado
b918500df7a88a52b5c1b016b517a2a81ee3c3d6cca8be23ccff555ae20287a2  CuentasGeneracionales.ado
08b3fb3a5038684e04aed19e89940e642f813912788f5d59db6bf4253d888aef  DatosAbiertos.ado
ca3c50b6a22409156a596e70ca9869b9e4eee84cce1bf65f8a28833713ab2120  Distribucion.ado
a6d17b987f94ebae90f1cb59ec2ff9766f10846f046e7d4df942298be23b7b0e  FiscalGap.ado
1b8ef0c7dd2b898d93274acb3f26732536cffce58cd12d666113f2efb8dfd2fb  GastoPC.ado
783109e1c9cffe3627dad6022a3ae36cf0efef94708aa23d66a66cd8e6cdc686  Gini.ado
9c505c6b957497261ea46b12cf78b3a32fd2229191dec45c26d8c8698c0afade  INCI.ado
5459a022d6bcab268ac3b038f7e0fd773f0c25eb648c69ae38cff1d39b8901b7  LIF.ado
7f67c31230da70313b6456eb08493e0db98e89cef6e2f7eb283d4333d129704f  PC.ado
9e5e82397be952cc301d3b1ab21dccd7a646e9704fbc52e1f9779c88917a8961  PEF.ado
88a127f71253df71c58c2cf7f82d2d6e44df42d9452d329422beb13eeacc39d1  PERF.ado
fa19f41a3bdd68d8332ebd8e3b082c13ca469da5855a067f7faa99be6405f3df  PIBDeflactor.ado
4283cbc39c1bb673e80650c3e065cffa3a7044b0e1a65423714fe9e56f2cb4ff  Perfiles.ado
fe7cb37d5ac620cd0ae3d3d1b0bb3ac47359fd5db00a1ab9d3875eb402ac31dc  Poblacion.ado
8dbfbd8f41f5d0edc647eb779d7dedc08ce02cbc0dc91237905c83fc9c005554  REC.ado
c38e217efeb39a5c57c904d2bf16e56d4eb86e5ed4dcacbef56b65bb01666357  SCN.ado
fe7dfea1528143ea4a31b0298467f32dc7ab584f52ea1466a24512089355ceb6  SHRFSP.ado
730aabf764aa738ea14092dfe84db700b1c9452863b3b376f7a740f5f6e91040  SankeySumLoop.ado
b682485546ec674df066845e7ba86cd89253c20196b1ab22e9a5b165f9c89b3d  SankeySumSim.ado
b389ac233efc8722e0a709298bbdaadf607ce681254182a353771949dfc3bb0a  Simulador.ado
51f63285c79965cee9843633743c4fbb1bdce5c869dc2e43cc43bbb21c3d04e9  TasasEfectivas.ado
69cabb1353a0f0ad211450660aa4e182ae8e352a355e1955ae5c5ee7f2bae5d0  claude.ado
ba9948f9e1ddc008c81fa26e0bbe28ba622d51b672e0309ece05a663c550d863  scalarlatex.ado
92ada34d5b44c9c6db456a0ed2a6a7bce3758c7b06fdac73b78d9cf7036201b4  Web.Stata.do
52127b7edb9ea0d86f1e663b6323416949559f62a17d1ffc5e5f681cc4b3f667  profile.do
5303d83aa2b710e9ec323777f4885394d0c90bd337dc1a5cbaba1bdbff0d9b5e  SIM.do
```

Además, el diff de §6 implica que existe el SHA-256 de **los 2,110 archivos** de `/var/www/html/v7/` (calculados durante esta sesión). Los hashes completos no se copian aquí por volumen; cualquier verificación futura puede regenerarlos con el mismo comando del anexo y comparar contra los 14 PHP de arriba como testigos.

---

## 9. Anexo: comandos ejecutados

*Qué aprendes en esta sección:* traza completa de lo que Devin corrió en el VPS — todo de lectura pura.

**Conexión (la password la tecleó el investigador principal en la terminal, nunca se almacenó):**

```bash
ssh -o StrictHostKeyChecking=accept-new -o ControlMaster=auto \
    -o ControlPath=/tmp/vps-ssh-%C -o ControlPersist=2h ciepmx@66.179.250.191
# huella del host registrada: SHA256:DwpkMowjCFANUEDVE8yVTiYP8cSG7/MV60fsxlL818A (ED25519)
ssh -MN ...   # conexión maestra dedicada (re-lanzada tras caída de la primera)
ssh -O exit ... # cierre explícito al terminar
```

**Reconocimiento (agrupados; todos read-only):**

```bash
# Sistema base (A)
cat /etc/os-release; uname -a; whoami; id; pwd; echo $HOME $SHELL; date; date -Iseconds; timedatectl

# Inventario web (B)
find /var/www/html/ -maxdepth 3 -type d; ls -la /var/www/html/ /var/www/html/v7/ ...
du -sh /var/www/html/ /var/www/html/v7/; find /var/www/html/v7/ -type f | wc -l
find /var/www/html/v7/ -type f -mtime -30 | head -20
find /var/www/html/v7/ -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
cat /var/www/html/v7/{config,calculaStata,checkStataStatus,cargaDefault}.php
cat "/var/www/html/v7/.htaccess"; head js/chatbot.js test_log.php

# Inventario motor (C)
find /SIM/ -maxdepth 3 -type d; ls -la /SIM/OUT/ /SIM/OUT/7/ ...; du -sh /SIM/ /SIM/OUT/7/
find /SIM/OUT/7/ -maxdepth 1 -name "*.ado" (y .sthlp, .pkg, .toc)
for f in /SIM/OUT/7/*.ado; do grep -m1 '^\*!' "$f"; done

# Stata (D)
which stata stata-mp stata-se; ls /usr/local/stata17/; crontab -l
ps aux | grep -i stata; find /usr/local/stata17/ -iname "*profile*"
head -60 /SIM/OUT/7/Web.Stata.do; head -40 /SIM/OUT/7/profile.do; tail -25 /SIM/OUT/7/Web.Stata.do

# Arquitectura (E)
ss -tulpn; systemctl status apache2 nginx; php -v
ls /etc/apache2/sites-enabled/; grep -E "ServerName|DocumentRoot|Redirect" sites-enabled/*.conf
grep -rn "stata" /var/www/html/v7/ --include="*.php"
grep -rhoE "(calculaStata|cargaDefault|...)\.php" js/ index.php
top -bn1; ps aux --sort=-%cpu; uptime; who; awk -F: '$3>=1000' /etc/passwd
ls -la /etc/cron.d/; cat /etc/crontab; sudo -n true  # (falló como se esperaba: sin elevar)

# Diff (E') y fingerprint (G)
cd /var/www/html/v7 && find . -type f -exec sha256sum {} +   # → comparado localmente vs
cd <local>/04_simuladorfiscal.ciep.mx && find . -type f -exec shasum -a 256 {} +
du -sb /var/www/html/v7/ /SIM/OUT/7/; sha256sum *.php *.ado ...; stat -c "%y %n" <dirs>
```

**Lo que NO se ejecutó:** ningún comando de escritura, edición, permisos, instalación ni reinicio. `sudo` solo se sondeó con `sudo -n true` para confirmar que exige password (no se elevó). El contenido de las llaves privadas SSL no se leyó.
