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

---

## 3. Endpoint Stata (Cloudways) — siempre ANTES que el VPS

El sitio enlaza al Release tag, que debe existir primero.

```bash
bash 05_scripts/publicar.sh vX.Y.Z
```

Hace: gates 1-4 → Release en GitHub + assets con SHA-256 → rsync al endpoint
con pin de versión inyectado. **Es idempotente**: si falla a medias (p. ej.
SSH), re-correr salta lo ya hecho.

Verificación:
```bash
curl -sI https://ciep.mx/simuladorfiscal/PEF.ado | head -1     # HTTP 200
```

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

**Paso 1 — Crear la estructura en el VPS (SSH interactivo, obligatorio).**
El pipeline NO crea el deployment nuevo: el Gate 4 solo verifica que exista y
aborta si no (con esta misma receta en su mensaje). Los directorios requieren
`sudo` (viven en rutas de root) y el `chown` a `ciepmx` es indispensable — sin
él, el rsync del pipeline no puede escribir:

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
