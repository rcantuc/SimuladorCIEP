# Runbook de publicación — Simulador Fiscal CIEP

Guía operativa para publicar un release a las tres caras (Git → endpoint Stata →
VPS web). Complementa la governance (`02_governance/`); aquí van los comandos.

---

## 0. ¿Qué tipo de release es?

| Pregunta | Patch (v8.1.x) | Minor (v8.x.0) |
|---|---|---|
| ¿Qué cambió? | Fixes acotados de código; datos sin cambio estructural | Rediseño, reclasificación, cambios grandes de datos o esquema |
| Deployment VPS | **El mismo directorio** (rsync incremental sobre `v8.1`) | **Directorio NUEVO** (`v8.2`) — deja el anterior como rollback |
| Rollback disponible | El backup de Fase 0 (solo config Apache) | **El deployment anterior completo** — un comando de symlink |
| Ejemplo | v8.0.12 → v8.0.13 | v8.0.13 → v8.1.0 |

Regla de bolsillo: **si los números publicados cambian de forma visible o el
esquema de datos cambió, merece deployment nuevo.** El costo es una
transferencia completa (GB, tarda); el beneficio es rollback instantáneo real.

Recordatorio commit ≠ versión: solo hay release si cambió **lo distribuido**
(.ado publicados o motor/datos del sitio). Governance/docs/profile.do se
commitean sin bump.

---

## 1. Pre-flight (siempre, antes de todo)

Todo se corre desde la raíz del **worktree de publicación** (fuera de Dropbox;
qué es y cómo se pone en el commit correcto: §10):

```bash
cd "$HOME/CIEP_Simuladores/SimuladorCIEP-release-vX.Y.Z"   # el worktree de publicación, NO el clon de Dropbox
git status          # ¿árbol limpio? ¿HEAD es el commit de master que se publica?
git log --oneline -3
```

### Los tres artefactos que hay que conocer

**`02_governance/CHANGELOG.md`** — la historia pública de qué cambió en cada
versión, en formato "Keep a Changelog": una sección `[vX.Y.Z]` por release con
sus cambios en prosa. El Gate 1 de `publicar.sh` **aborta si no existe la
sección de la versión que se está publicando** — el CHANGELOG se escribe ANTES
de publicar, no después. Las notas del GitHub Release se generan de aquí.

**`05_scripts/manifest.json`** — la fuente de verdad de qué se distribuye:
la versión del motor (`version`), el tag del Release (`release_tag`), la URL
base de los assets (`release_url_prefix`), la fecha de frescura de los datos
(`data_updated`), y la lista de **assets del sidecar de datos** (los .xlsx/.zip
de ENIGH, PEFs, LIFs...) con su **SHA-256** — el hash con que `ensure_asset`
verifica cada descarga. Reglas:
- `version`/`release_tag`/`release_url_prefix` deben decir la versión nueva
  (el Gate 3 lo verifica).
- `data_updated` SOLO se cambia si hubo reprocesamiento real de datos (nuevo
  Paquete Económico, corrección de bases) — no en cada release de código.
- Si un asset cambió (se editó un .xlsx), su SHA debe recalcularse
  (`shasum -a 256 archivo`) y actualizarse aquí, o la verificación
  post-Release fallará.

**`05_scripts/manifest-endpoint.toml`** — qué archivos de CÓDIGO viajan al
endpoint Stata (.ado, .sthlp, .pkg). Solo se toca si se agrega/quita un
comando publicado. El Gate 4 verifica que todos existan.

### Checklist

- [ ] **Working tree limpio o solo con lo del release.** Si hay cambios míos
      mezclados: identificarlos (`git diff --stat`) y decidir si entran.
      El tag debe apuntar al árbol **que se probó** — si excluyo archivos que
      estaban presentes durante los tests, lo probado ≠ lo publicado.
- [ ] **CHANGELOG** tiene la sección `[vX.Y.Z]` escrita.
- [ ] **manifest.json** sincronizado (versión/tag/prefix; `data_updated` y
      SHAs solo si aplica — ver arriba).
- [ ] **SIM.do completo corrido en local** si los datos/master cambiaron —
      regenera `master/`, `users/ricardo/bootstraps/` y el manifiesto del
      default (`output.txt` + `sankey-*.json`). El gate de frescura
      (Fase 3b-ter del deploy) aborta si el default es más viejo que
      `master/PEF.dta`.
      **La corrida que alimenta el sitio tiene tres condiciones** (incidente
      del deploy v8.4, 2026-10-01: la página abrió con valores vacíos):
      (1) `global output "output"` activa; (2) llega hasta `TOUCH-DOWN`
      — si se interrumpe en Perfiles, `output.txt` queda con 11 llaves y
      sin `GASTOS`/`INGRESOS`/`PIBY` (el gate de contenido de la Fase
      3b-ter lo detiene: 15 llaves obligatorias); (3) `set linesize 255`
      antes del `log using` (ya está en `SIM.do`) o en batch, para que
      Stata no parta las líneas con `> `. **La corrida que se publica** se hace
      desde estado cero (`global update`), en StataNow 19.5 y con `set processors 1`
      (§9); las fuentes INEGI/SHCP son las del día. Para una corrida rápida de
      desarrollo, descomenta `global nographs` y `global output` en `SIM.do` §0.4
      (o genera una copia con ellos, como hacen los scripts: §9.5) y corre en batch:
      ```bash
      printf 'capture set processors 1\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\ndo SIM.do\n' "$PWD" "$PWD" > /tmp/wrap.do
      /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se -b do /tmp/wrap.do   # ~11 min con cachés
      grep -c '^>' users/ricardo/output.txt      # debe ser 0
      ```
- [ ] Cruce de cifras hecho (si el release corrige datos): las series nuevas
      contra publicaciones CIEP / fuentes oficiales. **Sin este sí, no hay tag.**
- [ ] **El sitio está en git y coincide con el docroot** (desde v8.11a el
      `04_1_simuladorfiscal.ciep.mx/` completo se versiona — PHP, `css/`, `js/`,
      `images/`, `plugins/`, `favicon.ico`, `.htaccess`; fuera quedan `ssl/`,
      `logs/`, `*.log` y `simuladorfiscalv7.png`). Si editaste el sitio, va en
      el commit del release; el Gate 7 de `publicar-vps.sh` aborta si el docroot
      trae archivos sin versionar o si falta alguno versionado. **Nunca** se
      completa un docroot copiando de Dropbox a mano: esa práctica causó los
      fantasmas de v8.8–v8.10.

### Gráficas del sitio (`images/TE_*.png`, `images/GastoPC_*.png`)

Las 10 gráficas históricas que `index.php` abre en lightbox (4 tasas efectivas, 6
gastos per cápita) **no** las produce la corrida estándar de `SIM.do`: salen de
`01_modulos/visualizations/Graphs_TE.do` y `Graphs_PC.do`, cuyas líneas `do` están
**comentadas** en `SIM.do` (§4.6 justo antes de «4.7 Tasas Efectivas», y §5.1 antes
de «5.2 Gasto per cápita»; la de PC es muy tardada). Viven en git como **snapshot**
(`04_1_simuladorfiscal.ciep.mx/images/`), así que un checkout fresco despliega sin
abortar; la Fase 1b de `publicar-vps.sh` las sustituye por las de
`users/ricardo/graphs/` cuando existen y avisa cuántas salen del snapshot.

Receta para refrescarlas (cuando cambian los datos que grafican — nueva LIF/PEF,
nueva ENIGH — o al menos una vez por Paquete):

```bash
# 1. En SIM.do, descomenta las dos líneas (quita el * inicial):
#      do "${SIMROOT}/01_modulos/visualizations/Graphs_TE.do"
#      do "${SIMROOT}/01_modulos/visualizations/Graphs_PC.do"
# 2. Corre SIM.do completo SIN `global nographs` (las gráficas necesitan ventana
#    de gráficos; en batch funciona igual, solo no actives nographs).
#    → escribe users/<id>/graphs/TE_Trabajo|Capital|Consumo|Organismos.png
#      y GastoPC_Educacion|Salud|Pensiones|Energia|Otros|Transferencias.png
# 3. Vuelve a comentar las dos líneas antes de commitear SIM.do.
# 4. El deploy (Fase 1b) copia las 10 al docroot y te recuerda commitearlas:
git add 04_1_simuladorfiscal.ciep.mx/images && git commit -m "chore(sitio): gráficas TE_/GastoPC_ de la corrida <fecha>"
```

---

## 2. Commit + tag

```bash
# el commit del release (manifest, CHANGELOG, ...) entra a master por PR, como todo (branch
# protection: no hay push directo). Candado: jamás `git add -A` — siempre archivos explícitos.
git add 05_scripts/manifest.json 02_governance/CHANGELOG.md <lo demás del release>
git commit -m "release(vX.Y.Z): ..."
git push -u origin release/vX.Y.Z && gh pr create --base master   # CI (gates-sin-stata) se pone verde/rojo aquí
# tras el merge, en el worktree de publicación (§10.3):
git fetch origin && git checkout --detach origin/master
git tag -a vX.Y.Z -m "vX.Y.Z: resumen del release"
git push origin vX.Y.Z
```

Los tags son **inmutables** una vez publicado el Release: si algo se olvidó,
es commit nuevo y (si amerita) versión nueva — el tag no se mueve.

> **El tag NO es el release.** `05_scripts/manifest.json` apunta
> `release_url_prefix` a `releases/download/vX.Y.Z/`: desde que `master`
> lleva ese manifest, **toda** máquina sin `raw/` (instalación limpia, clon
> nuevo, caché borrada, el runner) descarga los assets de la Release
> `vX.Y.Z`. Si la Release no existe o está vacía, `ensure_asset` da 404 y
> `SIM.do` aborta. Por eso el paso §3 (`publicar.sh`) es **obligatorio e
> inmediato** tras el tag, y **nunca** se crea la Release a mano
> (`gh release create`, botón "Draft a new release"): eso deja una Release
> sin assets que parece terminada. Incidente 2026-10-05: v8.6.1, v8.7.0 y
> v8.7.1 se crearon desde los tags sin assets; el `SIM.do` nacional pidió
> los ZIP de la ENIGH a v8.7.1 y recibió 404 hasta espejar los 26 assets.

---

## 3. Endpoint Stata (Cloudways) — siempre ANTES que el VPS

El sitio enlaza al Release tag, que debe existir primero.

```bash
bash 05_scripts/publicar.sh vX.Y.Z
```

Hace: gates 1-9 → Release en GitHub + **los 27 assets del data sidecar**
(todos, en cada versión: el Release es inmutable y autocontenido, código +
datos) → verificación SHA-256 post-Release → rsync al endpoint con pin de
versión inyectado. **Es idempotente**: si falla a medias (p. ej. SSH),
re-correr salta lo ya hecho; si la Release ya existe la respeta y solo sube
los assets que falten.

**Gate 8 — Release remota completa** (`--check` y publicación): si la Release
`vX.Y.Z` ya existe en GitHub pero le falta algún asset del manifest (o difiere
el tamaño), aborta y dice cómo repararlo. Reparación de una Release creada a
mano o interrumpida:
```bash
bash 05_scripts/publicar.sh vX.Y.Z --solo-assets   # sube lo que falta y verifica SHA; sin tag, sin push, sin endpoint
```
Antes de dar por cerrado cualquier release: `bash 05_scripts/publicar.sh vX.Y.Z --check`
debe decir "los 8 gates pasaron" (el 8 consulta GitHub).

**Modo fuente remota (desde v8.8.0).** `publicar.sh` ya no exige `raw/` local
completo: la máquina de producción puede no tenerlo (los Releases son la fuente de
verdad). Para cada asset del manifest, si no está en `raw/` local pero la Release
ya lo trae con el **digest sha256 que GitHub calcula al subir** igual al del
manifest, cuenta como verificado y no se re-sube; solo aborta lo que falta en los
dos lados. El Gate 8 y la verificación post-Release también comparan ese digest
(descargan únicamente los assets de Releases antiguas sin digest). Para volver a
tener los archivos en la máquina:
```bash
bash 05_scripts/publicar.sh vX.Y.Z --poblar-raw     # baja a raw/ los assets del manifest que falten, verifica SHA; sin tag, sin push
```
Prueba 2026-10-06: 26/26 assets de v8.7.2 coinciden por digest con el manifest;
un digest adulterado se detecta; `--poblar-raw` restauró `LIFs.xlsx` y
`Diccionario.csv` con el SHA del manifest.

**Secuencia completa de un release, de punta a punta** (la que falló en
v8.6.1–v8.7.1 por saltarse el paso 4):

| # | Paso | Comando / artefacto | Quién |
|---|---|---|---|
| 1 | CHANGELOG + manifest (`version`, `release_tag`, `release_url_prefix`) en el PR | §1 pre-flight | autor del cambio |
| 2 | Merge a `master` | GitHub | Ricardo |
| 3 | Tag anotado + push del tag | §2 | Ricardo |
| 4 | **Release + 27 assets + verificación SHA + endpoint** | `bash 05_scripts/publicar.sh vX.Y.Z` (en el clon de desarrollo, no en la Carpeta de investigadores; sin `raw/` completo, los assets ya publicados se verifican por digest) | Ricardo, **inmediatamente después del tag** |
| 5 | Prueba de la promesa pública | `bash 05_scripts/test-maquina-virgen.sh --download` (N/N assets desde la Release) | Ricardo |
| 6 | VPS según tipo de release | §4 | Ricardo |
| 7 | «Calcular» de humo automático (Fase 6) + gate humano de lo que el humo no prueba | §6 | pipeline + Ricardo |
| 8 | Pull en la Carpeta de investigadores (Dropbox) | manual | Ricardo |

**¿Por qué no anclar los assets a una Release fija y dejar de subir 1.3 GB
por versión?** Se evaluó el 2026-10-05 y se descartó por ahora: (i) el
contrato de v8.0 es "código + datos + endpoint reproducibles en la misma
versión" (`git checkout vX.Y.Z` basta), y el modo *pinned* de `ensure_asset`
lee el manifest del tag instalado — una Release de datos aparte añade un
segundo eje de versiones (datos vs código) que hoy nadie gobierna y que
`publicar.sh` (gate de prefix, post-verify), `test-maquina-virgen.sh` y el
endpoint tendrían que aprender; (ii) el costo real es ~10 min de subida
idempotente por release y GitHub no cobra ni limita el almacenamiento de
assets (2 GB por archivo); (iii) el fallo no fue de diseño sino de proceso: el
paso existía y no se ejecutó. Si en el futuro los assets crecen (varias ENIGH
nuevas, >5 GB) se reabre con una propuesta formal: campo
`assets_release_tag` en el manifest, bumpeado solo cuando cambia
`data_updated`, con los tres scripts adaptados en el mismo PR.

Verificación:
```bash
curl -sI https://ciep.mx/simuladorfiscal/PEF.ado | head -1     # HTTP 200
bash 05_scripts/test-maquina-virgen.sh --download              # N/N assets desde la Release, SHA ok
```
El segundo comando es la promesa pública del endpoint hecha prueba: SITE
falso en `/tmp`, `raw/` vacío, y las invocaciones reales de `ensure_asset`
de los módulos contra la Release recién publicada (~1.3 GB). Su capa
estática (`--cobertura`: todo asset del manifest lo pide algún módulo) ya
corre como Gate 6 dentro de `publicar.sh`; en v8.3.0 habría atrapado el
`PPEF.2027.xlsx` publicado que ningún módulo solicitaba.

**Durante un release en curso** (el manifest ya dice vX.Y.Z pero la Release
aún no existe — el huevo-y-gallina del 2026-10-16) o para poblar el `raw/` de
un worktree sin copiar nada de otro clon:
```bash
bash 05_scripts/test-maquina-virgen.sh --download --from v8.9.0               # prueba: ¿los assets de la Release anterior siguen siendo los del manifest?
bash 05_scripts/test-maquina-virgen.sh --download --from v8.9.0 --into "$PWD"  # además los deja en raw/<local_path> del worktree
```
Sin Stata (usa `gh`); cada asset se deposita en su `local_path` del manifest y
se verifica con el SHA del manifest **local**: un asset que cambió entre la
Release `--from` y el manifest de hoy se reporta y no se instala.

### Si falla la conexión SSH a Cloudways
Cloudways **whitelistea IPs** para SSH. Síntoma: `Operation timed out` al 22.
```bash
curl -sI https://ciep.mx/simuladorfiscal/ | head -1   # ¿servidor vivo? (415/200 = sí)
nc -zv 104.248.223.143 22                             # ¿puerto bloqueado?
curl -4 -s ifconfig.me                                # mi IPv4 actual (¡-4! la v6 no cuenta)
```
Panel Cloudways → servidor → **Security** → agregar la IPv4 actual. Esperar
~1 min y reintentar.

---

## 4. VPS (IONOS) — según el tipo de release

Gates locales que `publicar-vps.sh` corre antes de tocar el VPS (abortan con la
receta en el mensaje; todos corren también en `--dry-run`):

| Gate | Qué exige | Incidente que lo originó |
|---|---|---|
| 2 | working tree sin cambios | — |
| 6 | `manifest.json` `version` = vN.M.x del deployment pedido (`v8.10` sirve `v8.10.x`) | deploy v8.8 que shipeó código v8.7.2 (2026-10-07) |
| 5 | `master/`, `users/ricardo/bootstraps/<B>/*RECprom.dta`, `health.php` | r(601) del 2026-07-09; v8.10.0 |
| 7 | docroot = `git ls-files 04_1/` (nada versionado falta, nada sin versionar sobra) + activos de humo presentes | deploy v8.10 sin css/js/plugins (2026-10-16) |
| 4 | estructura `vN.M` / `N.M` en el VPS (o la crea con `crear-deployment`) | — |

Y tras el cutover, la **Fase 6** exige HTTP 200 de `health.php`, el commit
desplegado **y un activo por clase del esqueleto** (css, js, plugins, imagen,
favicon, `cargaDefault.php`, `jsonSankey.php`); si alguno falla, rollback
automático. Correr desde el clon cuyo `04_1_simuladorfiscal.ciep.mx/` es el
del repo (credentials `LOCAL_SITE_ROOT` = `LOCAL_REPO_ROOT/04_1_…`); si
apunta a otro sitio, el Gate 7 solo verifica existencia y lo avisa.

### 4a. Patch (mismo deployment)

```bash
bash 05_scripts/publicar-vps.sh vA.B      # el deployment vigente, p. ej. v8.1
```
Password al pedirlo; **de corrido, sin interrumpir** (una interrupción a media
Fase 3 deja permisos rotos → 403). El swap preguntará `current: vA.B → vA.B`
(mismo destino): confirmar.

### 4b. Minor (deployment nuevo) — TRES pasos, el primero DENTRO del VPS

**Paso 1 — Crear la estructura en el VPS.** Los directorios viven en rutas
de root y el `chown` a `ciepmx` es indispensable (sin él, el rsync no puede
escribir). Hay dos caminos:

**1a. Automático (I.4, desde 2026-10-01), si el VPS tiene instalado
`crear-deployment`:** no haces nada; el Gate 4 de `publicar-vps.sh` detecta
que el deployment no existe y lo crea con `sudo -n crear-deployment vA.B`
— el único comando que `ciepmx` puede correr con `sudo` sin contraseña.
Salta al Paso 2.

*Instalación única de `crear-deployment` (requiere tu contraseña de `sudo`;
la contraseña NO se comparte ni se guarda en credentials):*
```bash
# desde el clon de desarrollo: sube el script a tu home del VPS
scp 05_scripts/vps/crear-deployment 05_scripts/vps/ciepmx-deploy.sudoers ciepmx@66.179.250.191:~/

ssh ciepmx@66.179.250.191
sudo install -o root -g root -m 0755 ~/crear-deployment /usr/local/sbin/crear-deployment
sudo visudo -cf ~/ciepmx-deploy.sudoers                 # valida sintaxis: debe decir "parsed OK"
sudo install -o root -g root -m 0440 ~/ciepmx-deploy.sudoers /etc/sudoers.d/ciepmx-deploy
sudo -n /usr/local/sbin/crear-deployment v0.0           # prueba sin contraseña: crea v0.0 y 0.0
sudo rm -r /var/www/html/v0.0 /SIM/OUT/0.0              # limpia la prueba
sudo -n true                                            # debe seguir diciendo "a password is required"
rm ~/crear-deployment ~/ciepmx-deploy.sudoers
exit
```
Qué queda autorizado: exactamente `/usr/local/sbin/crear-deployment`, que
solo acepta `vN.M` (regex estricta, sin rutas ni patch) y solo hace `mkdir` +
`chown ciepmx` de `/var/www/html/vN.M` y `/SIM/OUT/N.M`. Todo lo demás sigue
pidiendo contraseña. Para revocarlo: `sudo rm /etc/sudoers.d/ciepmx-deploy`.

**1b. Manual (si `crear-deployment` no está instalado):** el Gate 4 aborta
con esta misma receta en su mensaje:

```bash
ssh ciepmx@66.179.250.191
sudo mkdir /var/www/html/vA.B
sudo mkdir /SIM/OUT/A.B
sudo chown ciepmx:ciepmx /var/www/html/vA.B /SIM/OUT/A.B
ls -ld /var/www/html/vA.B /SIM/OUT/A.B    # verificar: owner ciepmx en ambos
exit
```

**Convención asimétrica de nombres (no es typo):**
`/var/www/html/` lleva prefijo "v" (`v8.1`); `/SIM/OUT/` no (`8.1`).

**Paso 2 — Deploy** (transferencia COMPLETA: sitio + motor + master de GB —
tarda mucho más que un patch; no interrumpir):

```bash
bash 05_scripts/publicar-vps.sh vA.B
```

**Paso 3 — El cutover.** El swap preguntará
`current: v<anterior> → vA.B` — es el cambio real de producción; confirmar
con `y`. El pipeline imprime al final el **comando de rollback** al
deployment anterior: guardarlo hasta pasar el gate humano (§6). Qué es y
cómo usar ese rollback: §7.

---

## 5. Verificación post-deploy

```bash
curl -s https://simuladorfiscal.ciep.mx/health.php | grep -i "version\|commit"
# → Version: vX.Y.Z y el commit del HEAD tagueado

curl -s https://simuladorfiscal.ciep.mx/cargaDefault.php | head -c 300
# → JSON con los números de MI corrida local fresca (no fósiles)

curl -s https://simuladorfiscal.ciep.mx/jsonSankey.php | head -c 300
# → JSON no vacío del escenario fresco

for p in css/custom.css js/stataCalcula.js plugins/bootstrap/css/bootstrap.min.css images/TE_Trabajo.png favicon.ico; do
  printf '%-45s %s\n' "$p" "$(curl -sL -o /dev/null -w '%{http_code}' "https://simuladorfiscal.ciep.mx/$p")"
done
# → 200 en todos (la Fase 6 ya lo exige; aquí es la comprobación a ojo del esqueleto)
```

---

## 6. Gate humano (navegador) — desde v8.12.1 el «Calcular» lo da el pipeline

**El clic «Calcular» ya es automático**: la Fase 6 de `publicar-vps.sh` corre
`05_scripts/humo-calcular.sh` tras el swap (y tras 125 s de espera por el caché de
realpath de PHP): POST del escenario default a `calculaStata.php` como lo hace el
JS, números en la respuesta (el `output.txt` de la sesión) y los 5 `jsonSankey*.php`
de ESA sesión (no el fallback `ciepmx`). Si falla → rollback automático (Fase 7) con
la cola del log de Stata de la sesión en pantalla. Lo que sigue abajo es lo que el
humo NO prueba (interacción, módulos, brecha fiscal con inputs distintos al default).

En Chrome (o Firefox sin VPN):
1. **Abrir la página**: los defaults y Sankeys iniciales muestran la corrida
   fresca.
2. **Simulación completa** que toque la **brecha fiscal** (ejercita
   FiscalGap → escalar → contrato de params en producción).
3. **Módulos de gasto** (perfiles, incidencia) — la ruta de PEF/Simulador.
4. Health de rutina ya cubierto por el paso 5.

Si truena → correr el **rollback impreso** por el pipeline, y diagnosticar
con el sitio anterior sirviendo.

---

## 7. Rollback — qué es, cuándo, y cómo

### Qué significa

El VPS sirve el sitio a través de dos **symlinks** (accesos directos a nivel
de sistema de archivos): `/var/www/html/current` apunta al deployment del
sitio activo, y `/SIM/OUT/current` al del motor Stata. Apache y los PHP solo
conocen `current` — nunca una versión concreta. **Hacer rollback = re-apuntar
esos dos symlinks al deployment anterior.** Es instantáneo (no copia nada),
no borra el deployment nuevo (queda ahí para diagnóstico), y es reversible
(re-apuntar de vuelta).

### Cuándo hacerlo

Cuando el gate humano falla tras un cutover: el sitio no carga, las
simulaciones truenan, los números salen absurdos — y el diagnóstico no es
obvio en minutos. **Regla: producción sana primero, diagnóstico después.**
Con el rollback hecho, el sitio anterior sirve mientras se investiga el nuevo
con calma.

### Cómo (el comando exacto)

El pipeline lo imprime al final de cada corrida ("Rollback manual si lo
necesitas"). Su forma general — re-apuntar AMBOS symlinks al deployment
anterior:

```bash
ssh ciepmx@66.179.250.191 "ln -sfn '/var/www/html/v<ANTERIOR>' '/var/www/html/current' && ln -sfn '/SIM/OUT/<ANTERIOR>' '/SIM/OUT/current'"
```

(ejemplo real tras el cutover v8.0 → v8.1: `v<ANTERIOR>` = `v8.0` y
`<ANTERIOR>` = `8.0`). Verificar de inmediato:

```bash
curl -sI https://simuladorfiscal.ciep.mx/health.php | head -1     # 200
curl -s https://simuladorfiscal.ciep.mx/health.php | grep -i version  # la versión ANTERIOR
```

### El límite que hay que tener claro

El rollback de symlink **solo existe entre deployments distintos** (tras un
minor). En un release **patch**, el rsync escribe **sobre el mismo
directorio**: no hay "anterior" completo al cual volver — solo el backup de
Fase 0, que cubre únicamente la config de Apache, no el sitio ni los datos.
Esa es exactamente la razón de la regla del §0: cambios grandes → deployment
nuevo. Si un patch sale mal, el camino es fix-forward (corregir y
re-desplegar), no rollback.

### Después de un rollback

1. Diagnosticar el deployment nuevo (sigue intacto en su directorio).
2. Corregir → commit → (si amerita) versión nueva.
3. Re-desplegar y re-apuntar `current` con el mismo mecanismo.

---

## 8. Después del deploy (según el release)

- Regenerar `.tex` (`$export`) + **compilar el libro** si los números del
  libro cambiaron; pasada de prosa donde las cifras se movieron.
- Comunicado/nota de corrección si aplica (decisión institucional).
- Bitácora del deploy queda en `02_governance/deploys/`.

---

## 9. Fuentes vivas y reproducibilidad — decisión 2026-10-15

`AccesoBIE`, `SCN` y `DatosAbiertos` bajan **en vivo** del BIE de INEGI, de los
tabulados CSI y de la SHCP cada vez que corre `SIM.do`. INEGI y la SHCP revisan sus
series (el PIB 2024 cambió entre el 22-sep y el 6-oct de 2026; la SHCP agrega meses),
así que dos corridas en fechas distintas pueden dar `output.txt` distintos sin que el
código cambie. **Se asume esa consecuencia:** el `output.txt` que se publica es el del
INEGI/SHCP del día en que se corrió, y no se garantiza regenerarlo al byte después.

Entre v8.2 y v8.9 existió un mecanismo de "fuentes congeladas" (`global fuentes`,
asset `fuentes-AAAA-MM-DD.zip`, `05_scripts/ancla-reproducibilidad.json`, modo
`test-maquina-virgen.sh --reproducibilidad`, Gate 9 de `publicar.sh`) que fijaba esas
descargas a una fecha para reproducir el ancla publicada. Se retiró por decisión de
Ricardo (minimalismo): el motor siempre descarga en vivo; el asset
`fuentes-2026-10-06.zip` sigue en la Release v8.9.0 solo como histórico. Lo que sí se
conserva de aquella etapa, porque mueve números con independencia de las fuentes:

| Pieza | Por qué importa |
|---|---|
| Estado cero al publicar (`global update`: borra `raw/temp/` y `master/<anioenigh>/*_pc`, `deducciones`) | los cachés micro solo se crean si faltan; sin `update` se heredan de versiones anteriores del código |
| StataNow 19.5 | Stata 17 vs 19.5 difieren en ~52 de ~5,000 valores (xtile/probit/Mata) y Stata 17 no descarga de la SHCP |
| `set processors 1` en batch | `collapse (sum)` en MP depende del número de hilos; con 1, MP = SE al bit (solo afecta los `sankey-*.json` a 16 dígitos) |
| `quietly { log using … log off }` en bloque | con `do`, el eco del comando caía dentro de `output.txt` |

### 9.5 Toggles en batch: la copia `SIM_run.do`

Los toggles de `SIM.do` §0.4 (`nographs`, `output`, `update`, `entidad`, `hasta`,
`textbook`, `export`) se activan descomentando la línea en `SIM.do`. Los scripts que
corren en batch **no tocan `SIM.do`**: generan una copia `SIM_run.do` con (a) la ruta
de la copia/clon en la línea `global SIMROOT` y (b) los globals que necesitan
insertados justo después de `macro drop _all` (así sobreviven al borrado de macros y
mandan sobre los `//global` comentados). Lo hacen `test-maquina-virgen.sh` (`sim_run`,
modo `--zip`) y `compuertas-entidad.sh`. (Hasta 2026-10-15 esto se hacía con un
`SIM-local.do` gitignored que `SIM.do` §0.5 ejecutaba; se retiró.)

### 9.6 Reglas de calibración del IVA (desde v8.8.0)

- **Informalidad/evasión (`IVAT[13]`, `SIM.do` §4.5)** es la fila "Informalidad %"
  que imprime `Expenditure.do` §5: (IVA potencial ENIGH − IVA observado)/potencial,
  ambos en % del PIB del año de la ENIGH. **Se recalibra y documenta cada vez que
  cambie lo que mueve ese cierre** — los perfiles (`perfilpc`, nueva ENIGH) o las
  fuentes (PIB del SCN, recaudación observada) — y **nunca se hereda a ciegas**: al
  actualizar las fuentes, se lee la fila y, si cambia el redondeo a un decimal, se
  commitea con su causa (2026-10-06: 22.96 % → 23.14 % por la revisión del PIB 2024
  de INEGI; perfiles 5.443 → 5.441).
- **Brecha simulación vs. proyección LIF (`IVA_Mod.do`)**: el IVA simulado del año
  del Paquete (potencial ENIGH a precios del Paquete × (1 − informalidad)) **no se
  fuerza** a la recaudación proyectada de la LIF. La diferencia se declara como
  residuo documentado (CHANGELOG, y `IVA_Mod.do` la imprime: "brecha … pp (residuo
  documentado)"); nunca se absorbe con factores silenciosos como el `4.249/4.495`
  que v8.8.0 retiró (calibración ad hoc del Paquete 2022).

---

### 9.7 `global entidad`: el motor entidad-consciente (2026-10-10)

`SIM.do` §0.4 trae `//global entidad "Nuevo León"` comentado y se activa descomentándolo
(o en la copia `SIM_run.do` de los scripts, §9.5). **Regla de oro:** todo lo de
entidad vive dentro de `if "$entidad" != ""`; con el global vacío no corre ni una línea
nueva ni se escribe un archivo nuevo, así que los archivos nacionales no cambian. Con el global puesto:

| Pieza | Qué hace | Dónde escribe |
|---|---|---|
| `SIM.do` §0.6 | `SIMentidad` valida el nombre contra el catálogo (`$entidadesL`; posición = clave INEGI de la ENIGH, `substr(folioviv,1,2)`) y deriva la abreviatura (`$entidadesC`, la misma que `Poblacion.ado` usa en sus escalares). Nombre mal escrito = error accionable con el catálogo | `users/<id>/<ABREV>/` |
| `SIM.do` §1 | `Poblacion if entidad == "<nombre>"` (CONAPO): tarjeta demográfica y escalares `pob*<ABREV>` | `graphs/` (si hay gráficas) |
| `SIM.do` §8.2 → `SankeySF.do` | tras los 5 Sankeys nacionales, los de la entidad: `keep if` por clave INEGI sobre `aportaciones.dta`; corte **quintil estatal** (re-ranking dentro de la entidad con el criterio de ingreso de `Households.do` §12, el mismo del sprint NL) en lugar del decil nacional, más grupoedad, sexo, rural y escol; renglones per cápita con la población ENIGH de la entidad (fórmula actual) y renglones `% PIB × pibY` repartidos por población (`entidad_macro`, supuesto declarado en el CHANGELOG); banda de vintages ENIGH y sellos de muestra como campos del JSON | `users/<id>/<ABREV>/sankey-{quintil,grupoedad,sexo,rural,escol}.json` |
| `SIM.do` §8.2 → `CicloEntidad.do` (2026-10-11) | tras los Sankeys de entidad, la gráfica "La carga fiscal por edades" del sitio nacional (`Simulador.ado` `graphpiramide` → `APORT*` de `output.txt`) filtrada a la entidad: `AportacionesNetas = ImpuestosAportaciones − Transferencias` por quinquenio × sexo × grupo de deciles nacionales, en % del neto total de la entidad (`pct`) y del nacional (`pct_nac`: Σ de las 32 entidades = `APORT*`), con `n`, `pob`, `aporta`, `recibe`, `top1_*` y `sello` por celda; rejilla completa (46 celdas), nada se suaviza | `users/<id>/<ABREV>/ciclo-vida.json` (JSON plano) |

Reglas fijas (2026-10-15, antes globals de SIM.do §0.4): banda de vintages ENIGH 2016-2024
(los que existan en `users/<id>-v<t>/aportaciones.dta`; `compuertas-entidad.do` la omite para
las 31 entidades que no son la de la sesión pasando `"0"` como 4.º argumento de `SankeySF.do`),
renglones macro repartidos por población (`pob`), cuotas IMSS dentro de "Imp al trabajo" como el
nacional, sellos n < 100 personas y top1 > 25 %, series de `ciclo-vida.json` por grupos de deciles
nacionales. El JSON de entidad lleva
un bloque `entidad:{nombre, clave, abrev, corte, pobEnt, pobNac, macro, cuotas, selloN,
selloTop1, vintages, celdas:[{celda, n, hog, pob}]}` y, en cada enlace micro, `n`, `top1`,
`sello` (0/1), `bmin`, `bmax` y `v<t>` (valor de la celda con cada vintage: participación
de la celda de la entidad en el total nacional de la familia × total nacional vigente).

Compuertas de salida del PR (evidencia en `diag-pivote-entidad-2026-10-10/F1/`):
1. paridad nacional con `entidad` vacío: `test-maquina-virgen.sh --zip`;
2. aditividad: Σ de los 32 Sankeys de entidad = Sankey nacional (`05_scripts/compuertas-entidad.sh`, que corre
   `SIM.do` + `compuertas-entidad.do` en una sesión y verifica con `compuertas-entidad.py`);
3. testigo: NL por quintil estatal reproduce las participaciones selladas del sprint (`dis<fam>nle<dec>` del
   `statajson_entidad-nl.json`, 90 celdas, reldif ~1e-15);
4. segundo estado (Jalisco u otro): produce outputs y sus sellos de muestra se activan donde n < umbral.

## 10. Topología de trabajo: dónde vive cada cosa y el «baile de master»

Lo que hubo que preguntar tres veces la semana del 13 al 18 de octubre de 2026; queda escrito.
Un solo repositorio git con **varios árboles de trabajo** (`git worktree`): comparten objetos,
ramas y tags (un commit o un tag hecho en cualquiera lo ven todos al instante, sin fetch),
pero cada uno tiene su propio checkout y **una rama no puede estar extraída en dos árboles a
la vez** — de ahí el baile.

### 10.1 Los tres tipos de árbol

| Árbol | Dónde | Qué tiene extraído | Para qué sirve | Qué NO se hace ahí |
|---|---|---|---|---|
| **Clon de Dropbox — la casa de `master`** | `~/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP` (el repo principal: su `.git` es el de todos los worktrees) | la rama `master`, siempre | ser la copia de referencia que Dropbox mantiene sincronizada (la que abre el IDE y la opción 1 «master, Dropbox» del `sysprofile.do`); `git pull --ff-only` después de cada merge; leer, buscar, consultar | **ninguna operación pesada**: Dropbox sube en vivo cada archivo que cambia (una corrida de `SIM.do` escribe GB en `users/`, `publicar.sh` baja/sube assets, los worktrees de sesión generan logs). Tampoco credenciales (`publicar-vps-credentials.sh`, `endpoint-credentials.sh`, `set_token.do` con token real): Dropbox las copiaría a la nube. Tampoco commits de trabajo ni `git add -A` (archivos `conflicted copy`, `.DS_Store`). |
| **Worktree de publicación** | fuera de Dropbox: `~/CIEP_Simuladores/SimuladorCIEP-release-vX.Y.Z` | **HEAD desprendido** (`detached`) en el commit de `master` que se publica, o en el tag | correr los rituales que necesitan Stata, assets o credenciales: `SIM.do` completo, `publicar.sh vX.Y.Z` (`--check` y real), `publicar-vps.sh`, `test-maquina-virgen.sh --download`, `perfilar-web.sh`, `compuertas-entidad.sh`. Tiene el marker `.clon-desarrollo`, los dos `*-credentials.sh`, `raw/`, `master/` y `users/ricardo/` (bootstraps, `*RECprom.dta`). Es el único árbol que habla con el VPS y con Cloudways. | extraer `master` (está en Dropbox: git lo rechaza, y así debe ser); editar código a mano (si hay que corregir, es un PR desde un worktree de sesión). |
| **Worktrees de sesión** (agentes y ramas de Ricardo) | fuera de Dropbox: `~/CIEP_Simuladores/SimuladorCIEP-<tema>` | una rama propia (`perf/...`, `fix/...`, `ci/...`) creada desde `origin/master` | desarrollar, probar, abrir el PR. Desechables: no tienen `raw/` ni `users/` ni credenciales; si la sesión necesita assets, los pide con `test-maquina-virgen.sh --download --into "$PWD"` o apunta `--root` al worktree de publicación (como hace `perfilar-web.sh`). | tocar `master`; publicar; copiar credenciales. Se borran al mergear (`git worktree remove`). |

> Pendiente (FLAG, 2026-10-18): `Web.Stata.do` §0.1 y el `sysprofile.do` de la Mac todavía apuntan
> el SITE de Stata al clon de Dropbox; mientras no se muevan al worktree de publicación, una corrida
> local del flujo web escribe `users/<id>/` (≈ 900 MB) dentro de Dropbox. `perfilar-web.sh --root`
> ya lo evita para el perfilado; el resto es decisión de Ricardo.

Regla de bolsillo: **Dropbox = leer; publicación = rituales; sesión = cambiar.** `master` solo se
mueve en GitHub, por PR (branch protection); ningún árbol local hace `git push origin master`.

### 10.2 Crear y tirar un worktree de sesión

```bash
cd "$HOME/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"   # cualquier árbol del repo sirve
git fetch origin
git worktree add -b fix/<tema> "$HOME/CIEP_Simuladores/SimuladorCIEP-<tema>" origin/master
cd "$HOME/CIEP_Simuladores/SimuladorCIEP-<tema>"       # trabajar, commitear (archivos explícitos), push, gh pr create
# al terminar (PR mergeado o descartado):
git worktree remove "$HOME/CIEP_Simuladores/SimuladorCIEP-<tema>"
git branch -d fix/<tema>                                   # -D si se descartó sin mergear
git worktree list                                          # inventario: qué árboles existen y en qué están
```

### 10.3 El «baile de master» (cada vez que un PR entra)

1. **GitHub**: el PR se mergea a `master` (con el check `gates-sin-stata` verde, §11).
2. **Clon de Dropbox** (casa de `master`): traer el merge, nada más.
   ```bash
   cd "$HOME/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"
   git status                       # debe estar limpio; si Dropbox dejó basura, NO se commitea
   git pull --ff-only origin master # ff-only: si no avanza en línea recta, algo se commiteó aquí por error
   ```
3. **Worktree de publicación**: ponerlo en ese mismo commit **sin extraer la rama** (la rama
   vive en Dropbox; aquí siempre HEAD desprendido).
   ```bash
   cd "$HOME/CIEP_Simuladores/SimuladorCIEP-release-vX.Y.Z"
   git status                       # limpio (lo que generan los rituales está en .gitignore: users/, raw/, master/, logs)
   git fetch origin --tags
   git checkout --detach origin/master      # o: git checkout --detach vX.Y.Z, si el tag ya existe
   git log --oneline -1                     # debe ser el mismo hash que acaba de llegar a Dropbox
   ```
   Desde aquí corren §1–§5 (pre-flight, tag, `publicar.sh`, `publicar-vps.sh`). El tag creado
   aquí (`git tag -a ... && git push origin vX.Y.Z`) lo ven todos los árboles: no hay que
   repetirlo en Dropbox.
4. **Minor con deployment nuevo**: en vez de reutilizar el worktree anterior, se crea uno
   (`git worktree add --detach "$HOME/CIEP_Simuladores/SimuladorCIEP-release-vX.Y.0" origin/master`)
   y se le copian a mano, **una vez**, `.clon-desarrollo` y los dos `*-credentials.sh` del
   anterior (gitignored; no viajan solos). `raw/` se puebla con `test-maquina-virgen.sh --download --into "$PWD"`;
   `master/` y `users/ricardo/` los produce `SIM.do`. El worktree viejo se queda como rollback
   local hasta que el deployment nuevo esté verificado (§5–§6); después, `git worktree remove`.
5. **Worktrees de sesión** abiertos: no se tocan; cada rama se rebasa o se vuelve a crear desde
   `origin/master` cuando toque.

Síntomas y causa:

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `fatal: 'master' is already checked out at '…/Dropbox-CIEP/…'` | se intentó extraer `master` en un worktree | usar `git checkout --detach origin/master` (10.3.3); `master` solo vive en Dropbox |
| `git pull` en Dropbox dice "Not possible to fast-forward" | alguien commiteó en el clon de Dropbox | `git log origin/master..master` para ver qué es; moverlo a una rama (`git branch rescate/<tema>`) y `git reset --hard origin/master` |
| `publicar.sh` aborta "NO está marcado como clon de desarrollo" | se corrió desde Dropbox o desde un worktree de sesión | ir al worktree de publicación; si es uno nuevo, `touch .clon-desarrollo` (10.3.4) |
| El sitio o `raw/` están incompletos en el worktree de publicación | se creó el worktree y se copió a mano | `git checkout -- 04_1_simuladorfiscal.ciep.mx` (nunca copiar de Dropbox); `test-maquina-virgen.sh --download --into "$PWD"` |

---

## 11. Qué gate corre dónde: CI (GitHub Actions) vs. sesión

Desde v8.11c, `.github/workflows/gates-sin-stata.yml` corre en **cada PR a `master`** (y en cada
push a `master`) todo lo que se puede verificar sin Stata, sin assets pesados y sin
credenciales. Lo demás sigue siendo ritual de sesión (Stata no está en CI: licencia).

| Gate | En CI | Fuera de CI (sesión / ritual) | Por qué |
|---|---|---|---|
| `shellcheck` de `05_scripts/*.sh` | **sí**, severidad `error` bloquea; `warning` se imprime y no bloquea (17 avisos heredados, la mayoría falsos positivos: comas dentro de `--chmod=…`, `do` literal en strings) | — | estático |
| `verify_gitignore.sh` (85 casos) | **sí** | — | estático |
| `php -l` de los PHP del sitio | **sí** | — | estático |
| Harness de seguridad del sitio (`test-sitio-seguridad.sh`: `php -S` + Stata falso; payloads de inyección/traversal → 400, válido → 200 con `.do` limpio) | **sí** | — | no necesita Stata: el falso registra la llamada y el `.do` nunca se ejecuta |
| Sitio auto-contenido (`verify_sitio_autocontenido.sh`: docroot == `git ls-files 04_1/`, sin fantasmas, activos referenciados existen; roturas conocidas en `05_scripts/sitio-referencias-rotas-conocidas.txt`) | **sí** | el Gate 7 de `publicar-vps.sh` lo repite sobre el worktree de publicación antes del rsync | estático; en CI protege contra el enlace a un archivo que no viaja en git |
| `publicar.sh` Gate 1 (CHANGELOG tiene la versión del manifest) | **sí** (`--ci`) | — | estático |
| `publicar.sh` Gate 2 (tag anotado) | **no** | `publicar.sh vX.Y.Z --check` en el worktree de publicación, tras crear el tag | el tag lo crea el ritual; un PR de release lleva el manifest bumpeado antes del tag |
| `publicar.sh` Gate 3 (manifest sincronizado) | **sí** | — | estático |
| `publicar.sh` Gate 4 (archivos del manifest-endpoint existen) | **sí** | — | estático |
| `publicar.sh` Gate 5 (raw declarado) | **parcial**: solo `SIM.do` sin `global rawwip` activo | SHA de cada asset presente en `raw/`: `--check` en el worktree de publicación | en CI no hay `raw/` |
| `publicar.sh` Gate 6 (cobertura de assets, `test-maquina-virgen.sh --cobertura`) | **sí** | — | estático (grep de `ensure_asset`) |
| `publicar.sh` Gate 7 (clausura transitiva de los `.pkg`) | **sí** | — | estático |
| `publicar.sh` Gate 8 (Release remota completa) | **sí** (solo lectura con `gh` y el token del workflow) | — | red, sin descarga; si la Release aún no existe, pasa |
| Corridas: `SIM.do`, `Web.Stata.do`, `perfilar-web.sh`, `compuertas-entidad.sh` | **no** | worktree de publicación | Stata |
| Paridad local/web, aditividad de entidades, byte-identidad de `output.txt` y de los escalares (`scalarlatex-baseline.txt`) | **no** | sesión, con su evidencia en `diag-*/` y en el PR | Stata |
| `test-maquina-virgen.sh --download` (1.3 GB desde la Release) | **no** | después de `publicar.sh`, antes de anunciar | assets |
| `publicar-vps.sh` (gates con VPS, rsync, health) | **no** | ritual de deploy | credenciales, SSH, producción |
| «Calcular» de humo (`humo-calcular.sh`, Fase 6 de `publicar-vps.sh`) | rojo/verde con Stata falso (`test-humo-calcular.sh`, job `sitio-seguridad`) | el real, contra el VPS, en cada deploy | Stata + producción |
| Gate humano del navegador (§6, lo que el humo no prueba) | **no** | Ricardo | humano |

Correr lo mismo que CI, localmente, antes de abrir el PR (todo en segundos):
```bash
shellcheck -S error 05_scripts/*.sh && bash 05_scripts/verify_gitignore.sh && \
for f in 04_1_simuladorfiscal.ciep.mx/*.php; do php -l "$f" >/dev/null || echo "ERR $f"; done && \
bash 05_scripts/test-sitio-seguridad.sh && bash 05_scripts/test-humo-calcular.sh && bash 05_scripts/verify_sitio_autocontenido.sh && bash 05_scripts/publicar.sh --ci
```

**Branch protection (lo hace Ricardo, a mano, una vez que vea el check verde en un PR):** Settings →
Branches → `master` → *Require status checks to pass before merging* → marcar los seis checks de
`gates-sin-stata` (`shellcheck`, `gitignore`, `php-lint`, `sitio-seguridad`, `sitio-autocontenido`, `publicar-check`).

---

## 12. Regla: el motor solo lee lo que `publicar-vps.sh` embarca (v8.12.1)

**Incidente 2026-10-18 (deploy v8.12).** `_precache_manifest.ado` (candado 2 del cache de
Precache) lee `data_updated` de `${SIMROOT}/05_scripts/manifest.json`. En el VPS `SIMROOT` es el
deployment (`/SIM/OUT/8.12`) y `publicar-vps.sh` nunca había embarcado `05_scripts/`: «Calcular»
abortó con `r(601)` — el candado hizo lo correcto — hasta copiar el archivo a mano. Health check
y esqueleto habían pasado. Segundo deploy consecutivo (v8.10: sitio sin css/js; v8.12: motor sin su
insumo) que rompe el run interactivo y solo lo cacha un clic humano. Los candados se habían
probado en el worktree del agente, nunca contra el layout del deployment.

**Regla.** Un `.ado`/`.do` del motor web solo puede leer, bajo `${SIMROOT}/`, lo que la Fase 3
(motor), 3b (`master/`), 3b-bis (`users/ricardo/bootstraps`, `users/ricardo/cache`) y 3b-ter
(`users/ciepmx`) de `publicar-vps.sh` embarcan. Lo que no embarca, **se embarca** (se añade a la
fase y a `MOTOR_LECTURAS_VPS`) **o no se lee**. El **Gate 5-remoto** de `publicar-vps.sh` comprueba
en el destino, antes del swap, que cada ruta de `MOTOR_LECTURAS_VPS` existe (y que
`05_scripts/manifest.json` es idéntico al local); la Fase 6 da el clic «Calcular» real.

**Inventario (2026-10-18)** — `grep -rnoE '\$\{?SIMROOT\}?/…' *.ado *.do 01_modulos/` excluyendo
`master/`, `users/`, `raw/`:

| Ruta bajo `${SIMROOT}/` | Quién la lee | Flujo | Decisión |
|---|---|---|---|
| `05_scripts/manifest.json` | `_precache_manifest.ado` | **web** y batch | **embarcar** (Fase 3a, v8.12.1) |
| `01_modulos/{ISR_Mod,IVA_Mod,output}.do`, `01_modulos/visualizations/SankeySF.do` | `Web.Stata.do` | **web** | ya embarcado (Fase 3a `01_modulos/***`) |
| `*.ado`, `*.scheme` del root | `Web.Stata.do` vía SITE | **web** | ya embarcado (Fase 3a) |
| `01_modulos/PerfilesSim.do` | `GastoPC.ado`, `TasasEfectivas.ado` | solo si falta `master/perfiles<año>.dta` (en el VPS existe: Fase 3b) | ya embarcado; no debe correr en el VPS |
| `01_modulos/{Expenditure,Households,PerfilesSim,…}.do`, `visualizations/{Graphs_*,CicloEntidad}.do`, `nodos/*.do` | `SIM.do`, batch | batch | embarcado por `01_modulos/***`; no se leen en web |
| `set_token.do`, `simulador.stpr` | `SIM.do`, `profile.do` | batch / GUI local | **no se lee** en web; `set_token.do` es secreto y no viaja (correcto) |
| `01_raw/CONEVAL/2022/Base` | `Expenditure.do` | batch | no se lee en web (FLAG: ruta `01_raw/`, ¿alias viejo de `raw/`?) |
| `02_governance/scalarlatex-baseline.txt` | `scalarlatex.ado` | solo con `$textbook` (documentación) | **no se lee** en web |
| `05_scripts/compuertas-entidad.do` | sesión `compuertas-entidad.sh` | sesión | no se lee en web |

FLAG (hallazgo del humo): `checkStataStatus.php` solo reporta `completed` cuando existe
`<id>.done`, y nada en el motor ni en `Web.Stata.do` lo escribe; el JS no lo consulta (el POST a
`calculaStata.php` es síncrono). `humo-calcular.sh` hace lo que el JS: espera el POST y usa
`checkStataStatus.php` solo como señal de vida (`process_alive`).

---

## Gotchas de deploy (los que ya mordieron)

| Gotcha | Regla |
|---|---|
| Interrumpir `publicar-vps.sh` a media fase | NUNCA — deja permisos sin normalizar (403). Si pasó: re-correr completo (idempotente). |
| `rsync --delete` no borra excluidos | La limpieza de material retirado del árbol es manual en el VPS. |
| Material fuente en el árbol deployable | El árbol del sitio contiene SOLO el sitio; fuentes/archivo viven fuera (lección legacy/, v1.41). |
| Logs de sesión del VPS | Los borra un cron nocturno — diagnóstico comparativo el mismo día, o reconstruir desde git. |
| Todo lo creado post-normalización | Nace ilegible para Apache: chmod explícito siempre. |
| SSH Cloudways | Whitelist por IPv4 — ver §3. |
| Mtime del default | Si el gate de frescura aborta: correr SIM.do completo primero (no tocar el mtime a mano). |
| `global update` en Stata 17 | No descarga de la SHCP (r(603)); la regeneración exige StataNow 19.5. |
| Release creada a mano desde el tag (sin assets) | NUNCA: el manifest ya apunta a ella y `ensure_asset` da 404 en toda máquina sin `raw/`. Siempre `publicar.sh vX.Y.Z`; si ya pasó, `publicar.sh vX.Y.Z --solo-assets` (incidente v8.6.1/v8.7.0/v8.7.1, 2026-10-05). |
| Deploy desde un worktree o clon con el docroot incompleto | El sitio vive en git (v8.11a): un checkout fresco trae el `04_1` completo. Si el Gate 7 aborta, se restaura con `git checkout -- 04_1_simuladorfiscal.ciep.mx`, **nunca** copiando de Dropbox a mano (deploy v8.10, 2026-10-16: sitio sin css/js/plugins con health check verde). |
| Deployment vN.M con código de otra versión | El Gate 6 aborta si `manifest.version` no es vN.M.x (deploy v8.8 que shipeó v8.7.2). Si el código es el correcto, el deployment pedido está mal, no al revés. |
| `.git/info/exclude` o gitignore global con reglas sobre `04_1/` | Ocultan fantasmas a `git status` solo en esa máquina. Bórralas: el `.gitignore` versionado es la única fuente de reglas (el Gate 7 las ignora a propósito con `--exclude-per-directory=.gitignore`). |
