# Runbook — Actualizar un asset de datos (`raw/…`) sin romper el candado

Audiencia: todo el equipo que toca archivos bajo `raw/` (LIFs.xlsx, PEFs, ENIGH,
Cuenta Pública…). Una página. Complementa `runbook-deploys-ciep.md` (ahí van los
comandos de release) y `versionado-y-git.md` (ahí va el flujo de ramas).

---

## 1. Qué es el manifest y por qué existe el candado

`05_scripts/manifest.json` declara, para cada archivo de datos que el Simulador
necesita, **su nombre, su ruta local, su SHA-256 y su tamaño en bytes**, más la
fecha `data_updated` de los datos precargados y el `release_tag` del GitHub
Release donde viven los archivos.

`ensure_asset.ado` (el candado) corre cada vez que un módulo pide un asset:

- Si el archivo **no está** en tu máquina → lo descarga del Release y verifica su SHA.
- Si el archivo **sí está** → calcula su SHA y lo compara con el manifest.
  **Si no coincide, aborta.** No adivina: no sabe si el archivo está corrupto o
  si alguien lo actualizó a propósito. Solo sabe que el archivo y su declaración
  ya no dicen lo mismo.

Eso es lo que pasó el 2026-09-08: el equipo cargó la ILIF 2027 en `LIFs.xlsx`,
el archivo cambió, el manifest no, y el candado detuvo la corrida. **El candado
funcionó** — una modificación legítima pero no declarada es exactamente lo que
debe detener. La lección es que actualizar el archivo es la mitad del trabajo;
la otra mitad es declararlo.

## 2. El flujo (en este orden, sin saltar pasos)

| Paso | Quién | Qué |
|---|---|---|
| 1. Avisar | quien actualiza | Antes de tocar el archivo, avisa a Ricardo: qué asset, qué fuente (p.ej. ILIF 2027, Gaceta), qué hojas/años cambian. |
| 2. Actualizar | quien actualiza | Vacía los datos en el archivo. Conserva nombre y ruta (`raw/LIFs/LIFs.xlsx`); no crees copias `LIFs (2).xlsx` ni `LIFs.xlsx_`. |
| 3. Validar CONTENIDO | **Ricardo** | Revisa con el ojo que los datos estén bien vaciados (totales, años, unidades). **El hash no sustituye esta revisión**: un SHA nuevo solo dice "el archivo cambió", no "el archivo está bien". Nada avanza sin este gate. |
| 4. shasum + size | Ricardo (o quien él delegue) | `shasum -a 256 raw/LIFs/LIFs.xlsx` y `stat -f '%z' raw/LIFs/LIFs.xlsx`. |
| 5. manifest | idem | En `05_scripts/manifest.json`, en la entrada del asset: `sha256` y `size_bytes` nuevos. **Los dos**: `ensure_asset` solo valida el SHA, pero `publicar.sh` y la auditoría usan el tamaño; un manifest a medias es un manifest mentiroso. |
| 6. data_updated | idem | Si los DATOS precargados cambiaron (nuevo Paquete, nueva ENIGH), `data_updated` = fecha de hoy. No se bumpea por releases de código. |
| 7. Probar | idem | En Stata: `ensure_asset "LIFs.xlsx"` debe pasar en silencio. |
| 8. Commit + push | idem | Commit que diga qué asset, qué fuente, qué SHA. Entrada en `CHANGELOG.md`. |
| 9. Release | **Ricardo** | Tag + `publicar.sh vX.Y.Z` re-sube los assets al Release para que las máquinas vírgenes y los compañeros descarguen el archivo nuevo. Hasta ese momento el Release sirve el archivo viejo — por eso el paso 10 importa. |
| 10. Pull en la carpeta compartida | **una sola persona** | `git pull` en la Carpeta del Simulador para investigadores (Dropbox). Ver §4. |

## 2b. Comandos exactos (autoservicio)

Es la misma secuencia de §2, pegable. Sustituye `<archivo>` por la ruta
relativa del asset (p.ej. `raw/LIFs/LIFs.xlsx`), `<nombre>` por su `name` en el
manifest (`LIFs.xlsx`) y `<tag>` por el `release_tag` que trae el manifest hoy.
Cuando `ensure_asset` te detiene, su mensaje ya trae estos valores calculados
(SHA, tamaño, tag, fecha): cópialos de ahí.

**Dónde se ejecuta — la trampa del 2026-09-08.** Hay DOS clones del repo en tu
Mac que se ven idénticos: el **clon de desarrollo** (donde se edita, commitea y
publica) y la **Carpeta del Simulador para investigadores**
(`…/Dropbox-CIEP/SimuladorCIEP`, clon que Dropbox replica al equipo y donde
git lo opera solo Ricardo con `git pull`). Todo lo que sigue va en el clon de
desarrollo. `publicar.sh` lo verifica: aborta si la raíz no tiene el marker
`.clon-desarrollo` (gitignored; se crea una vez con `touch .clon-desarrollo` en
el clon correcto). Confirma dónde estás con `git rev-parse --show-toplevel`.

```bash
# 0. Clon de DESARROLLO, master limpio y alineado
cd "<ruta-del-clon-de-desarrollo>"
git rev-parse --show-toplevel          # NO debe terminar en Dropbox-CIEP/SimuladorCIEP
git checkout master && git pull --ff-only origin master
git status --porcelain                 # vacío

# 1. Gate de contenido: quien edita, valida. Si no eres Ricardo, avísale ANTES.

# 3. Identidad del archivo nuevo
shasum -a 256 "<archivo>"
stat -f%z "<archivo>"

# 4. Declararlo: en 05_scripts/manifest.json, entrada "<nombre>":
#      "sha256": "<sha>",  "size_bytes": <bytes>
#    y, si cambiaron los datos, arriba: "data_updated": "AAAA-MM-DD"

# 5. El candado debe pasar en silencio (batch, sin abrir Stata):
printf 'sysdir set SITE "%s"\nadopath ++SITE\nensure_asset "<nombre>"\n' "$PWD" > /tmp/ea.do
/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se -b do /tmp/ea.do < /dev/null; tail -5 ea.log

# 6. Commit + push (solo el manifest)
git add 05_scripts/manifest.json
git commit -m "fix(assets): <nombre> -> <qué cambió> (SHA <sha8>, contenido validado por <quién>)"
git push origin master

# 7. Reemplazar el asset en el Release vigente y verificar los 24
gh release delete-asset "<tag>" "<nombre>" -y || true
bash 05_scripts/publicar.sh "<tag>"

# 8. Avisar a Ricardo: pull en la Carpeta de investigadores (solo él, §6.7)
```

Notas sobre el paso 7:

- `publicar.sh` es idempotente por NOMBRE: un asset que ya está en el Release
  se omite. Por eso hay que borrarlo primero; sin el `delete-asset` el Release
  seguiría sirviendo el archivo viejo con el manifest nuevo, y las máquinas
  vírgenes descargarían algo que el candado rechazaría.
- **Reemplazar un asset en un Release existente es válido para un parcial**
  (cadencia diaria de septiembre): el tag sigue apuntando al mismo commit y
  el manifest de ese commit queda desalineado con el asset del Release — una
  deriva conocida y aceptada mientras dura el Paquete. **La reconciliación
  formal llega con el minor (v8.3.0)**: Release nuevo, assets completos,
  manifest y tag alineados byte a byte. Cuando el asset cambia junto con
  código distribuido (un `.ado` publicado), no se reemplaza: se corta patch
  nuevo (así nació v8.2.2).
- Si en vez de reemplazar vas a cortar versión nueva: CHANGELOG con la
  entrada `## [vX.Y.Z] — AAAA-MM-DD`, manifest con `version`, `release_tag`
  y `release_url_prefix` nuevos, `bash 05_scripts/publicar.sh --check vX.Y.Z`
  (Gates 1, 3, 4 en verde), y Ricardo crea el tag anotado y lanza
  `publicar.sh vX.Y.Z` (Gate 2). Ver `runbook-deploys-ciep.md`.

## 3. Qué NUNCA hacer

- **Borrar el archivo y volver a correr después de actualizarlo.** Es el consejo
  correcto para un archivo corrupto y el consejo destructivo para un archivo
  actualizado: `ensure_asset` re-descargará el archivo **viejo** del Release y
  pisará los datos nuevos. Si el candado te detuvo y tú (o alguien del equipo)
  acabas de actualizar ese archivo, el archivo está bien — lo que falta es el
  manifest (pasos 3–8). El mensaje de error de `ensure_asset` lista los dos casos.
- **Editar el manifest para "que pase" sin el gate de contenido de Ricardo.** El
  SHA declara que el archivo es el canónico; declararlo sin revisarlo convierte
  al candado en decoración.
- **Actualizar el manifest a medias** (SHA sin `size_bytes`, o sin `data_updated`
  cuando los datos cambiaron).
- **Renombrar o duplicar el asset** (`LIFs_2027.xlsx`, `LIFs.xlsx_`). El manifest
  y los módulos buscan el nombre exacto; los renombres truncados de Dropbox están
  excluidos por regla del manifest.
- **Commitear o publicar desde la Carpeta de investigadores.** Es un clon git
  idéntico al de desarrollo y por eso engaña (pasó el 2026-09-08). `publicar.sh`
  ahora aborta ahí; para git no hay guard: mira `git rev-parse --show-toplevel`
  antes de cualquier `git add`.

## 4. Regla de la carpeta compartida (Dropbox)

La Carpeta del Simulador para investigadores es **un clon de git que se replica a
todas las máquinas del equipo**. Dropbox sincroniza los archivos, incluida la
carpeta `.git/`. Si dos personas corren `git pull`, `git add` o editan a mano
archivos versionados desde máquinas distintas, Dropbox mezcla estados y el clon
queda en un estado que git no puede reconciliar.

Por eso: **git en la carpeta compartida lo opera UNA sola persona** (hoy, Ricardo;
modelo y comandos en `arquitectura-y-bitacoras.md` §6.7).
El resto del equipo puede *leer* y *correr* el Simulador ahí; los datos que
actualiza el equipo (`raw/…`) están ignorados por git, así que actualizarlos no
toca `.git/` — pero sí dispara el candado hasta que el manifest se actualice
(§2). Cualquier cambio a archivos versionados (`.ado`, `.do`, `manifest.json`,
documentación) se propone por el flujo de ramas de `versionado-y-git.md` §2, no
editando la carpeta compartida.

Regla hermana, para ciclos delegados (2026-09-08): **un ciclo, un operador por
juego de archivos**. Si un ciclo de trabajo está delegado (a un colaborador o a un
agente) y alguien va a editar a mano un archivo de ese ciclo, lo declara antes —
dos manos sobre `manifest.json` o `SIM.do` sin avisar es el mismo incidente que
el candado acaba de contener, pero sin candado que lo detenga.

## 5. A quién avisar

- **Ricardo Cantú** (investigador principal) — valida contenido (paso 3), autoriza
  el SHA, dispara el release y opera git en la carpeta compartida.
- Si el candado te detuvo y no sabes si el archivo fue actualizado a propósito:
  **no borres nada**; pregunta primero.
