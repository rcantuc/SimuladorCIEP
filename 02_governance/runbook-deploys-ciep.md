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

Todo se corre desde la raíz del repo (el clon de desarrollo):

```bash
cd "$HOME/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"
git status          # ¿qué hay sin commitear? ¿todo es del release?
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
      Stata no parta las líneas con `> `. **La corrida que se publica es la de
      la receta canónica de §9** (estado cero, fuentes congeladas, StataNow 19.5,
      `set processors 1`): su SHA debe coincidir con
      `05_scripts/ancla-reproducibilidad.json`. Para una corrida rápida de
      desarrollo, sin tocar tu `SIM.do`, usa `SIM-local.do` (§9.5):
      ```bash
      printf 'global nographs "nographs"\nglobal output "output"\n' > SIM-local.do   # toggles personales, gitignored
      printf 'set processors 1\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\ndo SIM.do\n' "$PWD" "$PWD" > /tmp/wrap.do
      /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se -b do /tmp/wrap.do   # ~11 min con cachés
      grep -c '^>' users/ricardo/output.txt      # debe ser 0
      ```
- [ ] Cruce de cifras hecho (si el release corrige datos): las series nuevas
      contra publicaciones CIEP / fuentes oficiales. **Sin este sí, no hay tag.**

---

## 2. Commit + tag

```bash
git add -A                      # o selectivo, según el pre-flight
git commit -m "feat(...): descripcion (vX.Y.Z)"
git push
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
debe decir "los 9 gates pasaron" (el 8 consulta GitHub; el 9 exige el ancla de
reproducibilidad de la versión, §9).

**Secuencia completa de un release, de punta a punta** (la que falló en
v8.6.1–v8.7.1 por saltarse el paso 4):

| # | Paso | Comando / artefacto | Quién |
|---|---|---|---|
| 1 | CHANGELOG + manifest (`version`, `release_tag`, `release_url_prefix`) en el PR | §1 pre-flight | autor del cambio |
| 2 | Merge a `master` | GitHub | Ricardo |
| 3 | Tag anotado + push del tag | §2 | Ricardo |
| 4 | **Release + 27 assets + verificación SHA + endpoint** | `bash 05_scripts/publicar.sh vX.Y.Z` (en el clon de desarrollo, no en la Carpeta de investigadores) | Ricardo, **inmediatamente después del tag** |
| 5 | Prueba de la promesa pública | `bash 05_scripts/test-maquina-virgen.sh --download` (N/N assets desde la Release); en release de datos además `--reproducibilidad` (§9.3) | Ricardo |
| 6 | VPS según tipo de release | §4 | Ricardo |
| 7 | Gate humano | §6 | Ricardo |
| 8 | Pull en la Carpeta de investigadores (Dropbox) y aviso a la capa NL (merge de cadencia) | manual | Ricardo |

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
```

---

## 6. Gate humano (navegador — el release NO está cerrado sin esto)

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

## 9. Reproducibilidad del ancla (`output.txt` canónico) — desde v8.8.0

La paridad al byte de `users/ricardo/output.txt` es el contrato de verificación de
cada release. Hasta v8.7.2 el "ancla" (`ae624b98…`) era el output de un estado
congelado de una máquina (cachés del 22-sep anteriores a `perfilpc`, descargas de
ese día), no de una receta: ninguna máquina limpia podía reproducirlo
(diagnóstico F0, 2026-10-06, en el PR de v8.8.0). Desde v8.8.0 el ancla nace de una
receta y se verifica con ella.

### 9.1 La receta canónica

`output.txt` canónico = el que produce `SIM.do` (PE 2027) con este `SIM-local.do`:

```stata
global nographs "nographs"
global output "output"
global update "update"             // estado cero: también borra master/<anioenigh>/*_pc y deducciones
global fuentes "AAAA-MM-DD"        // fuentes vivas congeladas = fecha del release de datos (manifest.fuentes_congeladas_al)
```

desde **estado cero** (sin `master/`, `users/<id>/`, `raw/temp/`; `raw/` solo con
los assets del Release), en **StataNow 19.5** con **`set processors 1`**, en batch
(`stata-se -b do wrap.do`, con `cd` a la raíz y `sysdir set SITE`). Lo que fija cada
pieza, medido en F0:

| Pieza | Por qué | Si se cambia |
|---|---|---|
| Fuentes congeladas (`fuentes-<fecha>.zip`: ~540 csv del BIE, tabulados CSI, 10 csv de la SHCP) | INEGI revisa el PIB y la SHCP agrega meses: entre el 22-sep y el 5-oct cambiaron INCD, INGRESOSTEF, DEUDAPARAM | otra fecha = otro `output.txt` (release de datos) |
| Estado cero | `master/<anioenigh>/*_pc` y `deducciones` solo se creaban si faltaban: el ancla vieja arrastraba cachés pre-`perfilpc` | cachés viejos = números viejos sin aviso |
| StataNow 19.5 | Stata 17 vs 19.5 difieren en 52 de ~5,000 valores (xtile/probit/Mata) y Stata 17 no descarga de la SHCP | otra versión = otro `output.txt` |
| `set processors 1` | MP suma en paralelo: `collapse (sum)` depende del número de hilos; con 1, MP = SE al bit | solo mueve los `sankey-*.json` (16 dígitos), no `output.txt` |
| Batch `do` + `quietly { log using }` | con `do` el eco del comando caía dentro del log (`.quietlylogoffoutput`) y con `run` no | desde v8.8.0 `do` y `run` dan los mismos bytes |
| `bootstrap 1`, PE 2027, IVAT y escalares de `SIM.do` | parámetros del motor | cambio de código → re-anclar |

Ruido de último bit que **no** se fija por construcción (sí por la receta):
`sort` rompe empates con un RNG propio (`sortseed`) que avanza con cada `sort` de la
sesión, así que `collapse (sum)` devuelve bits distintos según qué corrió antes;
`output.txt` (3 decimales) lo absorbe; los sankeys a 16 dígitos no. Por eso el
ancla de los sankeys solo vale bajo la receta exacta (misma versión, misma ruta de
ejecución). Mejora futura anotada: `sort …, stable` antes de cada `collapse`/`egen sum`.

### 9.2 El ancla

`05_scripts/ancla-reproducibilidad.json`: versión, fecha de fuentes, Stata
(versión, edición, procesadores), receta, SHA-256 de `output.txt` y de los 5
`sankey-*.json`, commit y fecha. **Solo la escribe la receta**
(`test-maquina-virgen.sh --reproducibilidad --anclar`): nunca se edita a mano ni se
copia de una corrida de escritorio. El Gate 9 de `publicar.sh` exige que el ancla sea
de la versión que se publica y apunte a la misma fecha de fuentes que el manifest.

### 9.3 Verificar y re-anclar

```bash
# Verificar (máquina virgen o tu clon; ~80 min; sin red si --assets-locales y los 27 assets están en raw/)
bash 05_scripts/test-maquina-virgen.sh --reproducibilidad --assets-locales
bash 05_scripts/test-maquina-virgen.sh --reproducibilidad                  # tras publicar: assets desde la Release

# Re-anclar (SOLO en release de datos o cambio de código que mueve números; nunca en silencio)
bash 05_scripts/test-maquina-virgen.sh --reproducibilidad --assets-locales --anclar
git add 05_scripts/ancla-reproducibilidad.json 02_governance/CHANGELOG.md
```

Política: el ancla se re-declara **en cada release de datos** (nueva fecha de
fuentes, nueva ENIGH, nuevo Paquete) y cuando un cambio de código mueva números
(`perfilpc`, parámetros de `SIM.do`…). Cada re-anclaje lleva en el CHANGELOG el
delta por familia de llaves (`INCD`, `APORT*`, `PROY`, `INGRESOSTEF`, `DEUDAPARAM`…)
y su causa (revisión de fuente vs. cambio de código). Si `--reproducibilidad` falla
sin que haya release de datos ni cambio de código, es un bug: no se re-ancla, se
investiga.

### 9.4 Congelar fuentes nuevas (release de datos)

1. Corre `SIM.do` con `global update` y `global fuentes` **vacío** (descarga en vivo,
   StataNow 19.5): deja en `raw/temp/` los csv del BIE (+ `.meta`), los `CSI_*.xlsx`
   y los csv de la SHCP.
2. Empaca: `cd raw/temp && zip -r ../fuentes/fuentes-AAAA-MM-DD.zip AccesoBIE/*.csv AccesoBIE/*.meta SCN/ "Datos Abiertos"/*.csv`
   (~70 MB). El zip es un asset más: `shasum -a 256`, `stat -f%z`, entrada en el
   manifest (`name`, `local_path raw/fuentes/…`, `sha256`, `size_bytes`),
   `fuentes_congeladas_al` y `data_updated` = esa fecha. Las fechas anteriores se
   quedan en el manifest mientras alguna versión publicada las use.
3. `SIM.do` §0.4: `global fuentes "AAAA-MM-DD"` sigue comentado en el repo (vacío =
   en vivo); la receta lo activa vía `SIM-local.do`.
4. Re-ancla (§9.3) y documenta el delta. Cierre del IVA (§9.6).

Las tres guardas del motor (`AccesoBIE` → usa `raw/temp/AccesoBIE/<serie>.csv` +
`.meta`; `DatosAbiertos` → modo `local`; `SCN` → no re-baja `tabulados_CSI.zip`)
solo actúan con `$fuentes` definido; sin él, el motor es byte-idéntico al de antes.
Con fuentes congeladas no hace falta token del BIE ni red (salvo los assets).

### 9.5 `SIM-local.do`: el panel local

`SIM.do` §0.5 ejecuta `SIM-local.do` (raíz del simulador, **gitignored**) si existe,
después de los defaults de §0.4 y antes de usarlos. Ahí viven los toggles de quien
corre (`output`, `bootstrap`, `nographs`, `update`, `fuentes`, `hasta` = paro temprano
tras la sección 1-7, `textbook`, `export`); plantilla en `SIM-local.template.do`.
Sin el archivo, `SIM.do` es byte-idéntico. Reglas: (a) solo globals de §0.4 — un
parámetro del modelo (IVAT, escalares) es cambio del motor y va por commit; (b) el
`SIM.do` versionado y el de la Carpeta de investigadores se quedan limpios
(`git diff SIM.do` vacío); (c) la receta canónica es un `SIM-local.do` concreto
(§9.1), así que "lo que corre el gate" y "lo que corre Ricardo" difieren solo en ese
archivo.

### 9.6 Reglas de calibración del IVA (desde v8.8.0)

- **Informalidad/evasión (`IVAT[13]`, `SIM.do` §4.5)** es la fila "Informalidad %"
  que imprime `Expenditure.do` §5: (IVA potencial ENIGH − IVA observado)/potencial,
  ambos en % del PIB del año de la ENIGH. **Se recalibra y documenta cada vez que
  cambie lo que mueve ese cierre** — los perfiles (`perfilpc`, nueva ENIGH) o las
  fuentes (PIB del SCN, recaudación observada) — y **nunca se hereda a ciegas**: al
  congelar fuentes nuevas, se lee la fila y, si cambia el redondeo a un decimal, se
  commitea con su causa (2026-10-06: 22.96 % → 23.14 % por la revisión del PIB 2024
  de INEGI; perfiles 5.443 → 5.441).
- **Brecha simulación vs. proyección LIF (`IVA_Mod.do`)**: el IVA simulado del año
  del Paquete (potencial ENIGH a precios del Paquete × (1 − informalidad)) **no se
  fuerza** a la recaudación proyectada de la LIF. La diferencia se declara como
  residuo documentado (CHANGELOG, y `IVA_Mod.do` la imprime: "brecha … pp (residuo
  documentado)"); nunca se absorbe con factores silenciosos como el `4.249/4.495`
  que v8.8.0 retiró (calibración ad hoc del Paquete 2022).

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
| Paridad medida contra un estado, no contra una receta | El ancla sale SOLO de `test-maquina-virgen.sh --reproducibilidad --anclar` (§9); un `output.txt` de escritorio que "coincide" no prueba nada si sus cachés no nacieron del código vigente (F0 2026-10-06: `ae624b98` arrastraba `master/2024/*_pc` pre-`perfilpc`). |
| `global update` en Stata 17 | No descarga de la SHCP (r(603)); la regeneración viva exige StataNow 19.5 o fuentes congeladas (`global fuentes`). |
| Release creada a mano desde el tag (sin assets) | NUNCA: el manifest ya apunta a ella y `ensure_asset` da 404 en toda máquina sin `raw/`. Siempre `publicar.sh vX.Y.Z`; si ya pasó, `publicar.sh vX.Y.Z --solo-assets` (incidente v8.6.1/v8.7.0/v8.7.1, 2026-10-05). |
