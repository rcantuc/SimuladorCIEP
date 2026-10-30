#!/usr/bin/env bash
# publicar.sh — Publica una versión nueva al endpoint público del Simulador Fiscal CIEP
#
# Qué hace:
#   1. Verifica precondiciones (master, working tree limpio, alineación con origin/master)
#   2. Gates de validación: entrada en 02_governance/CHANGELOG.md, tag anotado con mensaje,
#      raw declarado (Gate 5: assets locales = manifest, SIM.do sin rawwip activo),
#      cobertura de assets (Gate 6: todo asset del manifest lo solicita algun modulo),
#      clausura transitiva de los .pkg (Gate 7: cada .pkg lista los .ado que invoca),
#      05_scripts/manifest.json sincronizado con la versión, y existencia en filesystem de
#      cada archivo declarado en 05_scripts/manifest-endpoint.toml, y Release remota
#      completa (Gate 8: si la Release ya existe, trae todos los assets del manifest).
#      Fuente remota (2026-10-06, v8.8.0): si un asset del manifest NO esta en raw/ local pero
#      la Release ya lo trae con el digest sha256 del manifest, cuenta como verificado y no se
#      re-sube: la maquina de produccion ya no necesita raw/ completo (los Releases son la
#      fuente de verdad). --poblar-raw baja a raw/ local los que falten, verificando SHA.
#      Si algo falla, aborta ANTES de cualquier acción con efectos (push, Release, rsync).
#   3. Si la etiqueta de versión no existe localmente, ofrece crearla (interactivo o por flag)
#   4. Push del tag a origin si aún no está allá
#   5. Crea la GitHub Release <VERSION> (si no existe) con las notas extraídas del
#      02_governance/CHANGELOG.md, y sube los assets del data sidecar declarados en 05_scripts/manifest.json
#   5b. (v8.14b) Data sidecar citable: empaqueta users/ricardo/{output.txt, 10 sankeys, NTA/*,
#      SankeyNTA/sankey-v3-grupoedad.json, <ABREV>/ ×32, entidades.json} en datos-<VERSION>.zip con
#      manifest-datos.json (sha256 por archivo, commit, data_updated, vintages que registró el motor)
#      y los sube a la Release como assets; Gate 9 exige que exista y cuadre (desde v8.14.0),
#      Gate 10 que CITATION.cff lleve la versión y la fecha del manifest.
#   6. Verifica integridad post-Release: descarga cada asset y compara su SHA-256
#      contra el manifest (--skip-post-verify lo salta; son ~1.3 GB de descarga)
#   7. Invoca publicar-endpoint.sh con la versión, que sincroniza el sub-canal Stata al
#      servidor Cloudways (ver §3.2 y §6.6 de 02_governance/arquitectura.md)
#
# Orden deliberado: primero la Release inmutable en GitHub (código + datos versionados),
# después el endpoint operativo. Así el endpoint nunca apunta a una versión sin Release.
#
# Modo --check: ejecuta SOLO los gates (sin crear tag, sin push, sin Release, sin rsync).
# Reporta todas las fallas acumuladas. Exit 0 si todos pasan, 1 si alguno falla.
#
# La sincronización de la Carpeta del Simulador para investigadores (Dropbox-CIEP/SimuladorCIEP)
# NO es responsabilidad de este script. La maneja manualmente el investigador principal
# mediante `git pull` en su clon local. Ver §6.7 de arquitectura.md.

set -euo pipefail

# ═══ CONFIGURACIÓN ═══

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

VERSION=""
TAG_MESSAGE=""
ENDPOINT_DRY_RUN=false
FORCE=false
CHECK_MODE=false
CI_MODE=false
SKIP_POST_VERIFY=false
SOLO_ASSETS=false
POBLAR_RAW=false
EMPAQUETAR_DATOS=false
CITATION_ONLY=false

# Colores (desactivados si stdout no es tty)
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

# ═══ FUNCIONES UTILITARIAS ═══

log_info()  { printf "${GREEN}[INFO]${NC} %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log_step()  { printf "\n${GREEN}═══${NC} %s ${GREEN}═══${NC}\n" "$*"; }

abort() {
    log_error "$1"
    exit "${2:-1}"
}

# ═══ USAGE ═══

usage() {
    cat <<EOF
Uso: $(basename "$0") [opciones] <version>

Publica una versión nueva del Simulador Fiscal CIEP al endpoint público
(https://ciep.mx/simuladorfiscal/).

Argumento:
  <version>             Etiqueta de versión (ej. v8.1, v9.0)

Opciones:
  --check               Ejecuta SOLO los gates de validación (CHANGELOG, tag anotado,
                        manifest sincronizado, archivos del manifest-endpoint existen)
                        sin acciones con efectos. Exit 0 si todos pasan, 1 si alguno falla.
  --ci                  (v8.11c) Variante de --check para GitHub Actions: sin el marker
                        .clon-desarrollo, con <version> opcional (default: la del
                        manifest.json) y SIN el Gate 2 (el tag lo crea publicar.sh al
                        publicar; un PR de release lleva el manifest bumpeado antes del tag).
                        Gates 1, 3, 4, 5 (solo rawwip: en CI no hay raw/), 6, 7 y 8 (lectura
                        de la Release con gh; necesita GH_TOKEN). Exit 0/1 como --check.
  --tag-message=MSG     Mensaje del tag inline (evita abrir editor)
  --endpoint-dry-run    Dry-run del endpoint (no toca el servidor)
  --skip-post-verify    Salta la verificación SHA-256 post-Release (descarga ~1.3 GB).
  --empaquetar-datos    (v8.14b) Solo construye el data sidecar citable (users/_sidecar/<VERSION>/
                        datos-<VERSION>.zip + manifest-datos.json) desde users/ricardo/ de este
                        clon, sin tag, push ni Release. publicar.sh lo hace solo al publicar; este
                        modo sirve para dejarlo listo antes de --check (que lo exige desde v8.14.0).
  --citation            (v8.14b) Regenera CITATION.cff desde 05_scripts/manifest.json (versión y
                        data_updated) y termina. El Gate 10 exige que esté sincronizado.
  --poblar-raw          Descarga a raw/ local, desde la Release <VERSION>, los assets del manifest
                        que falten (verifica SHA-256; no toca los presentes). Sin tag, sin push.
  --solo-assets         Reparación: sube a la Release <VERSION> ya existente los assets del
                        manifest que falten y verifica (sin tag, sin push, sin endpoint).
                        Para Releases creadas a mano desde el tag (incidente v8.7.1).
  --force               Permite republish de versión existente
  -h, --help            Ayuda

Ejemplos:
  $(basename "$0") v8.1
  $(basename "$0") v8.1 --check
  $(basename "$0") v8.1 --tag-message="Fix bug en LIF"
  $(basename "$0") v8.2 --endpoint-dry-run

La sincronización de la Carpeta para investigadores (Dropbox-CIEP/SimuladorCIEP)
NO la hace este script. La maneja manualmente el investigador principal con
'git pull' en su clon local. Ver 02_governance/arquitectura.md §6.7.

Configuración: requiere 05_scripts/endpoint-credentials.sh con SSH_ALIAS, REMOTE_PATH y
ENDPOINT_URL definidos.
EOF
}

# Candado del ritual (v8.14, 2026-10-30). Nada se publica mientras una corrida de evidencia esté
# viva o su log no haya cerrado: el ritual (runbook §1) corre SIM.do completo ANTES de publicar y
# el deploy embarca lo que esa corrida dejó en users/ricardo/; publicar con Stata a medias (o con
# una corrida que murió en r(###)) embarcaría un escenario base incompleto. Dos comprobaciones:
#   (a) pgrep: ningún correr-sim.sh / contrato-32.sh / compuertas-entidad.sh / pibe-32.sh /
#       test-maquina-virgen.sh / vintage-aportaciones ni ningún Stata en batch (stata-se|mp -b);
#   (b) el wrap*.log / SIM*.log más reciente bajo la carpeta de evidencia (SIM_EVIDENCIA, default
#       ~/CIEP_Simuladores, profundidad 3) y bajo la raíz del repo debe terminar en «end of do-file»
#       (un do-file en batch que muere termina en «r(###);»; uno vivo no ha escrito el cierre).
# Se omite en --ci (el runner no tiene corridas). No hay bandera para saltarlo: si el candado
# aborta, se espera a la corrida o se revisa su log.
gate_corridas_vivas() {
    local vivos
    vivos="$(pgrep -fl 'correr-sim\.sh|contrato-32\.sh|compuertas-entidad\.sh|pibe-32\.sh|test-maquina-virgen\.sh|vintage-aportaciones|stata-(se|mp) -b' 2>/dev/null | grep -v "$$" || true)"
    if [[ -n "$vivos" ]]; then
        log_error "Candado del ritual: hay corridas de Stata/evidencia vivas; no se publica con una corrida a medias:"
        while IFS= read -r l; do log_error "        $l"; done <<< "$vivos"
        return 1
    fi
    local raiz="${SIM_EVIDENCIA:-$HOME/CIEP_Simuladores}"
    local ultimo=""
    if [[ -d "$raiz" ]]; then
        ultimo="$( { find "$raiz" -maxdepth 3 -type f \( -name 'wrap*.log' -o -name 'SIM*.log' \) -print0 2>/dev/null; find "$REPO_ROOT" -maxdepth 1 -type f \( -name 'wrap*.log' -o -name 'SIM*.log' \) -print0 2>/dev/null; } | xargs -0 ls -t 2>/dev/null | head -n 1)"
    fi
    if [[ -n "$ultimo" ]]; then
        local fin
        fin="$(grep -v '^[[:space:]]*$' "$ultimo" | tail -n 1)"
        if [[ "$fin" != *"end of do-file"* ]]; then
            log_error "Candado del ritual: el log de corrida más reciente no termina en «end of do-file» (termina en: ${fin:0:80})."
            log_error "        $ultimo"
            log_error "        Si la corrida sigue viva, espera; si murió, repítela antes de publicar (runbook §1)."
            return 1
        fi
        log_info "✓ Candado del ritual: sin corridas vivas; último log de corrida cerrado ($ultimo)"
    else
        log_info "✓ Candado del ritual: sin corridas vivas (sin logs de corrida bajo $raiz)"
    fi
    return 0
}

# Gate 5 — Raw declarado (2026-09-12). Cierra la Fase 1 del ciclo de edición de raw/
# (runbook-actualizar-assets.md §2c): (a) SIM.do NO puede publicarse con
# `global rawwip` activo — todo el equipo correría con el candado en modo aviso;
# (b) cada asset del manifest PRESENTE en disco debe tener el SHA declarado —
# si no, publicar subiría al Release un archivo que el propio manifest rechaza
# (el post-verify lo cazaría, pero después de subir ~1.3 GB). Además lista
# raw/temp/assets-wip.txt si quedó de corridas en Fase 1.
gate_raw_declarado() {
    local failed=0
    if grep -qE '^[[:space:]]*global[[:space:]]+rawwip([[:space:]]|$)' SIM.do; then
        log_error "Gate 5 FALLO: SIM.do tiene 'global rawwip' ACTIVO (modo aviso del candado)."
        log_error "        Coméntalo (//global rawwip ...) y corre SIM.do: es la Fase 2 — cada asset"
        log_error "        no declarado bloqueará con sus valores para el manifest."
        failed=1
    fi
    local mismatches=0 checked=0
    while IFS=$'\t' read -r name local_path sha; do
        [[ -f "$local_path" ]] || continue
        checked=$((checked+1))
        local actual
        actual="$(shasum -a 256 "$local_path" | awk '{print $1}')"
        if [[ "$actual" != "$sha" ]]; then
            log_error "Gate 5 FALLO: $name en disco ($local_path) no coincide con el manifest."
            log_error "        manifest: $sha"
            log_error "        disco:    $actual  ($(stat -f%z "$local_path") bytes)"
            mismatches=$((mismatches+1))
        fi
    done < <(manifest_assets)
    if (( mismatches > 0 )); then
        log_error "        $mismatches asset(s) sin declarar. Secuencia: runbook-actualizar-assets.md §2b."
        failed=1
    fi
    if [[ -f raw/temp/assets-wip.txt ]]; then
        log_warn "Gate 5: raw/temp/assets-wip.txt existe (assets corridos en Fase 1):"
        while IFS=$'\t' read -r name lp actual size expected when; do
            log_warn "  - $name  real ${actual:0:12}...  $size bytes  ($when)"
        done < raw/temp/assets-wip.txt
        if (( mismatches == 0 && failed == 0 )); then
            log_warn "        Todos ya declarados; puedes borrar el archivo: rm raw/temp/assets-wip.txt"
        fi
    fi
    if (( failed == 0 )); then
        log_info "✓ Gate 5: raw declarado — $checked asset(s) locales coinciden con el manifest; SIM.do sin rawwip activo"
    fi
    return $failed
}

# Gate 6 — Cobertura de assets (2026-09-14). Cada asset del manifest debe ser
# SOLICITADO por algun modulo: por nombre (ensure_asset "X") o por directorio
# (ensure_asset, dir(D) con local_path bajo D/). Es la version estatica del test
# de maquina virgen: en v8.3.0 PPEF.2027.xlsx y Diccionario.csv estaban en el
# manifest y en la Release pero ningun modulo los pedia (lista tecleada a mano
# en PEF.ado desde v7.0), y una reconstruccion desde cero los omitia SIN error.
# Delegado a 05_scripts/test-maquina-virgen.sh --cobertura (misma logica, un
# solo lugar).
gate_cobertura_assets() {
    if [[ ! -x 05_scripts/test-maquina-virgen.sh ]]; then
        log_error "Gate 6 FALLO: falta 05_scripts/test-maquina-virgen.sh (o no es ejecutable)."
        return 1
    fi
    local out
    if out="$(bash 05_scripts/test-maquina-virgen.sh --cobertura 2>&1)"; then
        log_info "✓ Gate 6: cobertura de assets — $(tail -n 1 <<< "$out")"
        return 0
    fi
    log_error "Gate 6 FALLO: assets del manifest que ningun modulo solicita:"
    while IFS= read -r line; do log_error "        $line"; done <<< "$out"
    return 1
}

# Gate 7 — Clausura transitiva de los .pkg (2026-09-23, v8.4.2). Cada .pkg del
# endpoint debe listar TODOS los .ado que su comando invoca, directa o
# transitivamente, entre los publicados (manifest-endpoint.toml). Regla de
# v8.0.11 que solo se verificaba a mano: en v8.4.1 Poblacion empezo a llamar
# ensure_asset y Poblacion.pkg (y PIBDeflactor/SCN, que llaman Poblacion) no lo
# traian; `net install Poblacion` en maquina virgen tronaba con "command
# ensure_asset is unrecognized". Deteccion estatica: grep de cada comando
# publicado al inicio de linea (con prefijos noisily/quietly/capture) en cada
# .ado, cierre transitivo, y comparacion con las lineas `f X.ado` del .pkg.
gate_pkg_clausura() {
    local report
    report="$(python3 <<'PYEOF'
import re, os, sys
try:
    import tomllib
except ImportError:
    print("PARSE_ERROR: tomllib no disponible (Python 3.11+)"); sys.exit(0)
d = tomllib.load(open("05_scripts/manifest-endpoint.toml", "rb"))
cmds = [os.path.basename(f)[:-4] for f in d["package"]["ado_files"]]
def calls(cmd):
    s = open(cmd + ".ado", encoding="utf-8", errors="replace").read()
    return {c for c in cmds if c != cmd and
            re.search(r"(?m)^\s*(?:(?:noisily|quietly|capture|noi|qui)\s+)*" + re.escape(c) + r"\b", s)}
def closure(cmd, seen):
    for x in calls(cmd):
        if x not in seen:
            seen.add(x); closure(x, seen)
    return seen
fallas = []
for pkg in d["package"]["pkg_files"]:
    name = os.path.basename(pkg)[:-4]
    listed = {l.split()[1][:-4] for l in open(pkg, encoding="utf-8")
              if l.startswith("f ") and l.strip().endswith(".ado")}
    faltan = (closure(name, set()) | {name}) - listed
    if faltan:
        fallas.append(f"{pkg}: faltan {', '.join(sorted(f + '.ado' for f in faltan))}")
print("OK" if not fallas else "FALLA")
for f in fallas: print(f)
print(f"{len(d['package']['pkg_files'])} .pkg verificados")
PYEOF
)"
    local status
    status="$(head -n 1 <<< "$report")"
    if [[ "$status" == PARSE_ERROR* ]]; then
        log_error "Gate 7 FALLO: ${status#PARSE_ERROR: }"
        return 1
    fi
    if [[ "$status" == "FALLA" ]]; then
        log_error "Gate 7 FALLO: .pkg sin clausura transitiva (agrega las lineas 'f X.ado'):"
        while IFS= read -r line; do log_error "        $line"; done < <(sed -n '2,$p' <<< "$report" | sed '$d')
        return 1
    fi
    log_info "✓ Gate 7: clausura transitiva de los .pkg — $(tail -n 1 <<< "$report")"
    return 0
}

# ═══ FUNCIONES DE FLUJO ═══

verify_repo_state() {
    log_step "Verificación de estado del repo"

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$current_branch" != "master" ]] && abort "No estás en master (estás en: $current_branch)"
    log_info "✓ En master"

    if [[ -n "$(git status --porcelain)" ]]; then
        abort "Working tree no está limpio. Commitea cambios antes de publicar."
    fi
    log_info "✓ Working tree limpio"

    git fetch origin master --quiet
    local local_head remote_head
    local_head="$(git rev-parse HEAD)"
    remote_head="$(git rev-parse origin/master)"
    [[ "$local_head" != "$remote_head" ]] && abort "HEAD local difiere de origin/master. Pull o push primero."
    log_info "✓ Local alineado con origin/master (${local_head:0:7})"
}

# ═══ GATES DE VALIDACIÓN PRE-PUBLICACIÓN ═══
# Los cuatro gates corren ANTES de cualquier acción con efectos (push, Release, rsync).
# Cada gate imprime su resultado y devuelve 0 (pasa) o 1 (falla).

gate_changelog() {
    local version="$1"
    local ver_re="${version//./\\.}"
    if grep -qE "^## \[${ver_re}\] (—|-) [0-9]{4}-[0-9]{2}-[0-9]{2}" 02_governance/CHANGELOG.md 2>/dev/null; then
        log_info "✓ Gate 1: 02_governance/CHANGELOG.md contiene entrada para $version"
        return 0
    fi
    log_error "Gate 1: 02_governance/CHANGELOG.md no contiene entrada para $version. Edítalo antes de publicar."
    log_error "        Se espera una sección '## [$version] — YYYY-MM-DD'."
    log_error "        Cadena de reproducibilidad rota — el banner del profile.do no podrá mostrar cambios."
    return 1
}

gate_tag_annotated() {
    local version="$1"
    if ! git rev-parse --verify "refs/tags/$version" >/dev/null 2>&1; then
        log_error "Gate 2: tag $version no existe localmente."
        log_error "        Créalo anotado y con mensaje: git tag -a $version -m \"<mensaje>\""
        return 1
    fi
    local objecttype subject
    objecttype="$(git for-each-ref "refs/tags/$version" --format='%(objecttype)')"
    subject="$(git for-each-ref "refs/tags/$version" --format='%(subject)')"
    if [[ "$objecttype" != "tag" ]]; then
        log_error "Gate 2: tag $version es ligero (lightweight), no anotado. No lleva mensaje ni autor."
        log_error "        Recréalo: git tag -d $version && git tag -a $version -m \"<mensaje>\""
        return 1
    fi
    if [[ -z "$subject" ]]; then
        log_error "Gate 2: tag $version es anotado pero su mensaje está vacío."
        log_error "        Recréalo: git tag -d $version && git tag -a $version -m \"<mensaje>\""
        return 1
    fi
    log_info "✓ Gate 2: tag $version es anotado y con mensaje: \"$subject\""
    return 0
}

gate_manifest_sync() {
    local version="$1"
    if [[ ! -f 05_scripts/manifest.json ]]; then
        log_error "Gate 3: 05_scripts/manifest.json no existe en el repo."
        return 1
    fi
    local errors
    errors="$(python3 - "$version" <<'PYEOF'
import json, sys
version = sys.argv[1]
try:
    with open("05_scripts/manifest.json", encoding="utf-8") as f:
        m = json.load(f)
except Exception as e:
    print(f"manifest.json no es JSON válido: {e}")
    sys.exit(0)
if m.get("version") != version:
    print(f"manifest.version es '{m.get('version')}', esperaba '{version}'")
if m.get("release_tag") != version:
    print(f"manifest.release_tag es '{m.get('release_tag')}', esperaba '{version}'")
prefix = m.get("release_url_prefix", "")
if not prefix.endswith(f"/{version}/"):
    print(f"manifest.release_url_prefix es '{prefix}', esperaba que terminara en '/{version}/'")
PYEOF
)"
    if [[ -n "$errors" ]]; then
        log_error "Gate 3: 05_scripts/manifest.json no está sincronizado con $version:"
        while IFS= read -r line; do
            log_error "        - $line"
        done <<< "$errors"
        log_error "        Actualiza version, release_tag y release_url_prefix en 05_scripts/manifest.json"
        log_error "        (y regenera los assets si la versión trae datos nuevos)."
        return 1
    fi
    log_info "✓ Gate 3: 05_scripts/manifest.json sincronizado con $version"
    return 0
}

# Gate 4 — Existencia de archivos declarados en manifest-endpoint.toml.
# Cada archivo de ado_files, sthlp_files y pkg_files debe existir en el filesystem
# del repo (path relativo a REPO_ROOT). Motivador: el bug de AccesoBIE.pkg (v8.0.3)
# — un .pkg ausente del filesystem llegó anunciado al endpoint público.
# Gate 8 — Release remota completa (2026-10-05, incidente v8.6.1/v8.7.0/v8.7.1).
# ensure_asset descarga de manifest.release_url_prefix = Release <VERSION>. Si esa
# Release ya existe en GitHub (creada a mano desde el tag, sin pasar por este
# script) pero no trae los assets del manifest, TODA instalacion limpia y toda
# maquina sin raw/ queda con 404 ("descarga fallo ... verifica que el release
# este publicado"). En --check: FALLA si la Release existe y le falta algun asset
# o difiere el tamano; si la Release aun no existe, informa (la creara este script).
# Reparacion: re-correr `publicar.sh <VERSION>` (release_create se omite y
# assets_upload sube solo lo que falta) o `publicar.sh <VERSION> --solo-assets`.
gate_release_remota() {
    local version="$1"
    if ! command -v gh >/dev/null 2>&1; then
        log_warn "Gate 8: gh no esta instalado; no se puede verificar la Release remota."
        return 0
    fi
    local remote
    if ! gh release view "$version" >/dev/null 2>&1; then
        log_info "Gate 8: la Release $version aun no existe en GitHub (la creara publicar.sh con sus assets)."
        return 0
    fi
    remote="$(remote_assets "$version")"
    local missing="" name local_path sha why con_digest=0
    while IFS=$'\t' read -r name local_path sha; do
        if ! why="$(remote_asset_ok "$name" "$sha" "$local_path" "$remote")"; then
            missing+=$'\n'"  - $name ($why)"
        fi
        [[ -n "$(awk -F'\t' -v n="$name" '$1==n{print $3}' <<< "$remote")" ]] && con_digest=$((con_digest+1))
    done < <(manifest_assets)
    if [[ -n "$missing" ]]; then
        log_error "Gate 8 FALLO: la Release $version existe pero no trae los assets del manifest:$missing"
        log_error "        ensure_asset descargara de releases/download/$version/ y recibira 404 o un SHA que rechazara."
        log_error "        Reparacion: bash 05_scripts/publicar.sh $version --solo-assets"
        return 1
    fi
    log_info "✓ Gate 8: Release $version remota completa — $(manifest_assets | wc -l | tr -d ' ') assets presentes; $con_digest con digest sha256 igual al manifest"
}

# Corre una vez por invocación, tanto en --check como en la publicación real
# (son procesos separados sin estado compartido; saltarlo en la publicación real
# abriría el hueco de publicar sin haber corrido --check).
gate_endpoint_files() {
    if [[ ! -f 05_scripts/manifest-endpoint.toml ]]; then
        log_error "Gate 4 FALLO: 05_scripts/manifest-endpoint.toml no existe en el repo."
        return 1
    fi
    local report
    report="$(python3 <<'PYEOF'
import os, sys
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("PARSE_ERROR: ni tomllib (Python 3.11+) ni tomli disponibles")
        sys.exit(0)
try:
    with open("05_scripts/manifest-endpoint.toml", "rb") as f:
        data = tomllib.load(f)
except Exception as e:
    print(f"PARSE_ERROR: {e}")
    sys.exit(0)
package = data.get("package", {})
missing = []
counts = []
for kind in ("ado_files", "sthlp_files", "pkg_files"):
    files = package.get(kind, [])
    for f in files:
        if not os.path.isfile(f):
            missing.append(f)
    counts.append(f"{kind}: {len(files)} archivos verificados")
if missing:
    print("MISSING")
    for f in missing:
        print(f)
else:
    print("OK")
    for c in counts:
        print(c)
PYEOF
)"
    local status
    status="$(head -n 1 <<< "$report")"
    if [[ "$status" == PARSE_ERROR* ]]; then
        log_error "Gate 4 FALLO: no se pudo leer 05_scripts/manifest-endpoint.toml:"
        log_error "        ${status#PARSE_ERROR: }"
        return 1
    fi
    if [[ "$status" == "MISSING" ]]; then
        log_error "Gate 4 FALLO: archivos declarados en manifest-endpoint.toml no existen en filesystem:"
        while IFS= read -r line; do
            log_error "  - $line"
        done < <(tail -n +2 <<< "$report")
        log_error "Accion: crea los archivos faltantes o corrige el manifest antes de publicar."
        return 1
    fi
    log_info "✓ Gate 4: Todos los archivos declarados en manifest-endpoint.toml existen"
    while IFS= read -r line; do
        log_info "  $line"
    done < <(tail -n +2 <<< "$report")
    return 0
}

ensure_tag_exists() {
    local version="$1"

    if git rev-parse --verify "refs/tags/$version" >/dev/null 2>&1; then
        log_info "✓ Tag $version ya existe localmente"
        return 0
    fi

    log_info "Creando tag $version..."

    local msg_file
    msg_file="$(mktemp)"

    if [[ -n "$TAG_MESSAGE" ]]; then
        printf '%s\n' "$TAG_MESSAGE" > "$msg_file"
    else
        cat > "$msg_file" <<MSGEOF
Simulador Fiscal CIEP $version — <título corto del cambio>

<Descripción del cambio: qué se modificó, por qué, qué impacto tiene para
investigadores y usuarios externos.>

# Líneas iniciadas con # serán ignoradas.
# El primer renglón es el subject (lo que aparece en git log).
# Deja una línea en blanco entre subject y body.
MSGEOF
        "${EDITOR:-vim}" "$msg_file"

        local content
        content="$(grep -v '^#' "$msg_file" | grep -v '^$' || true)"
        if [[ -z "$content" ]]; then
            rm -f "$msg_file"
            abort "Mensaje del tag vacío o solo comentarios. Cancelado."
        fi
    fi

    git tag -a "$version" -F "$msg_file"
    rm -f "$msg_file"
    log_info "✓ Tag $version creado"
}

ensure_tag_pushed() {
    local version="$1"

    if git ls-remote --tags origin "refs/tags/$version" 2>/dev/null | grep -q "$version"; then
        log_info "✓ Tag $version ya está en origin"
        return 0
    fi

    log_info "Pusheando tag $version a origin..."
    git push origin "$version"
    log_info "✓ Tag $version pusheado"
}

# ═══ GITHUB RELEASE ═══

require_gh() {
    command -v gh >/dev/null 2>&1 || abort "gh CLI no está instalado. Instálalo con: brew install gh"
    gh auth status >/dev/null 2>&1 || abort "gh CLI no está autenticado. Corre: gh auth login"
}

# Extrae la sección del CHANGELOG.md de una versión: desde '## [<VERSION>]' (inclusivo)
# hasta el siguiente '## [' (exclusivo).
extract_changelog_section() {
    local version="$1" outfile="$2"
    awk -v ver="$version" '
        /^## \[/ {
            if (found) exit
            if (index($0, "## [" ver "]") == 1) found = 1
        }
        found { print }
    ' 02_governance/CHANGELOG.md > "$outfile"
}

# Emite los assets del manifest como líneas "name<TAB>local_path<TAB>sha256".
manifest_assets() {
    python3 <<'PYEOF'
import json
with open("05_scripts/manifest.json", encoding="utf-8") as f:
    m = json.load(f)
for a in m.get("assets", []):
    print(f"{a['name']}\t{a['local_path']}\t{a['sha256']}")
PYEOF
}

# Assets de la Release remota: "name<TAB>size<TAB>sha256" (digest que GitHub calcula
# al subir; vacio en assets antiguos sin digest). Fuente de verdad del modo remoto.
remote_assets() {
    gh release view "$1" --json assets \
        --jq '.assets[] | "\(.name)\t\(.size)\t\(.digest // "" | sub("^sha256:"; ""))"' 2>/dev/null
}

# ¿El asset remoto coincide con el manifest? 0 = si (digest igual; o, sin digest,
# tamano igual), 1 = no. Imprime el motivo en caso negativo.
remote_asset_ok() {
    local name="$1" sha="$2" local_path="$3" remote="$4" rsize rsha
    rsize="$(awk -F'\t' -v n="$name" '$1==n{print $2}' <<< "$remote")"
    rsha="$(awk -F'\t' -v n="$name" '$1==n{print $3}' <<< "$remote")"
    [[ -z "$rsize" ]] && { echo "ausente en la Release"; return 1; }
    if [[ -n "$rsha" ]]; then
        [[ "$rsha" == "$sha" ]] || { echo "digest remoto ${rsha:0:12}... != manifest ${sha:0:12}..."; return 1; }
    elif [[ -f "$local_path" ]]; then
        [[ "$(stat -f%z "$local_path" 2>/dev/null || stat -c%s "$local_path")" == "$rsize" ]] || { echo "tamano remoto $rsize != local"; return 1; }
    fi
    return 0
}

release_create() {
    local version="$1"
    log_step "GitHub Release: creación"

    if gh release view "$version" >/dev/null 2>&1; then
        log_info "Release $version ya existe en GitHub — se omite la creación (no se sobrescribe)"
        return 0
    fi

    local notes_file
    notes_file="$(mktemp)"
    extract_changelog_section "$version" "$notes_file"
    if [[ ! -s "$notes_file" ]]; then
        rm -f "$notes_file"
        abort "No se pudo extraer la sección de $version del 02_governance/CHANGELOG.md (Gate 1 debería haberlo detectado)."
    fi

    log_info "Creando Release $version con notas del CHANGELOG..."
    gh release create "$version" --title "Simulador Fiscal CIEP $version" --notes-file "$notes_file" \
        || { rm -f "$notes_file"; abort "gh release create falló para $version."; }
    rm -f "$notes_file"
    log_info "✓ Release $version creada"
}

assets_upload() {
    local version="$1"
    log_step "GitHub Release: subida de assets del data sidecar"

    # Assets ya presentes en la Release, con digest (idempotencia: no se re-suben).
    local remote
    remote="$(remote_assets "$version" || true)"

    # Pre-chequeo (modo fuente remota, v8.8.0): cada asset del manifest debe estar
    # en raw/ local O en la Release con el digest sha256 del manifest. Lo que falte
    # en los dos lados aborta ANTES de subir nada; lo que solo esta remoto cuenta
    # como verificado (para traerlo a raw/: --poblar-raw).
    local missing="" remotos=0 name local_path sha why
    while IFS=$'\t' read -r name local_path sha; do
        [[ -f "$local_path" ]] && continue
        if why="$(remote_asset_ok "$name" "$sha" "$local_path" "$remote")"; then
            remotos=$((remotos+1))
        else
            missing+=$'\n'"  - $name ($local_path; Release: $why)"
        fi
    done < <(manifest_assets)
    if [[ -n "$missing" ]]; then
        abort "Assets del manifest que no estan ni en raw/ local ni en la Release $version con su SHA:$missing"
    fi
    if (( remotos > 0 )); then
        log_info "✓ $remotos asset(s) sin copia local verificados en la Release por digest sha256 (fuente remota; --poblar-raw los trae a raw/)"
    else
        log_info "✓ Todos los assets del manifest existen localmente"
    fi

    local uploaded=0 skipped=0
    while IFS=$'\t' read -r name local_path sha; do
        if [[ -n "$(awk -F'\t' -v n="$name" '$1==n{print $2}' <<< "$remote")" ]]; then
            skipped=$((skipped+1))
            continue
        fi
        log_info "Subiendo $name ($local_path)..."
        gh release upload "$version" "$local_path" \
            || abort "Falló la subida de $local_path. Re-corre el script: los ya subidos se omiten."
        uploaded=$((uploaded+1))
    done < <(manifest_assets)
    log_info "✓ Assets: $uploaded subidos, $skipped ya estaban en la Release"

    # Verificación de conteo: Release vs manifest
    local manifest_count release_count
    manifest_count="$(manifest_assets | wc -l | tr -d ' ')"
    release_count="$(gh release view "$version" --json assets --jq '.assets | length')"
    if (( release_count < manifest_count )); then
        abort "La Release tiene $release_count assets pero el manifest declara $manifest_count. Faltan assets."
    elif (( release_count > manifest_count )); then
        log_warn "La Release tiene $release_count assets; el manifest declara $manifest_count (hay extras no declarados)."
    else
        log_info "✓ Cantidad de assets verificada: $release_count == manifest"
    fi
}

release_post_verify() {
    local version="$1"
    log_step "GitHub Release: verificación SHA-256 post-Release"

    local log_file="$REPO_ROOT/02_governance/deploys/endpoint-stata.log"
    mkdir -p "$(dirname "$log_file")"
    local short_head
    short_head="$(git rev-parse --short HEAD)"

    if [[ "$SKIP_POST_VERIFY" == "true" ]]; then
        log_warn "--skip-post-verify activo: se omite la verificación de integridad (~1.3 GB de descarga)"
        echo "$TIMESTAMP $version $short_head $(whoami) RELEASE-VERIFY SKIPPED" >> "$log_file"
        return 0
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d -t publicar-verify-XXXXXX)"

    # Digest sha256 que GitHub calcula al subir: verificacion sin descargar (v8.8.0).
    # Solo se descarga el asset que no traiga digest (Releases antiguas).
    local remote
    remote="$(remote_assets "$version" || true)"

    local drift=() verified=0 por_digest=0 name local_path sha actual rsha
    while IFS=$'\t' read -r name local_path sha; do
        rsha="$(awk -F'\t' -v n="$name" '$1==n{print $3}' <<< "$remote")"
        if [[ -n "$rsha" ]]; then
            if [[ "$rsha" == "$sha" ]]; then verified=$((verified+1)); por_digest=$((por_digest+1)); else drift+=("$name"); fi
            continue
        fi
        log_info "Verificando $name (sin digest remoto: descarga)..."
        rm -f "$tmp_dir/$name"
        if ! gh release download "$version" --pattern "$name" --dir "$tmp_dir" 2>/dev/null; then
            log_warn "No se pudo descargar $name para verificación"
            drift+=("$name(descarga-fallida)")
            continue
        fi
        actual="$(shasum -a 256 "$tmp_dir/$name" | awk '{print $1}')"
        if [[ "$actual" != "$sha" ]]; then
            drift+=("$name")
        else
            verified=$((verified+1))
        fi
        rm -f "$tmp_dir/$name"
    done < <(manifest_assets)
    rm -rf "$tmp_dir"

    if (( ${#drift[@]} > 0 )); then
        local drift_list
        drift_list="$(IFS=,; echo "${drift[*]}")"
        log_warn "Assets con drift de SHA-256 (no coinciden con manifest.json): $drift_list"
        log_warn "La Release quedó publicada; investiga el drift antes de anunciar la versión."
        echo "$TIMESTAMP $version $short_head $(whoami) RELEASE-VERIFY DRIFT:$drift_list" >> "$log_file"
    else
        log_info "✓ $verified assets verificados contra manifest.json ($por_digest por digest sha256 de GitHub, $((verified-por_digest)) por descarga)"
        echo "$TIMESTAMP $version $short_head $(whoami) RELEASE-VERIFY OK" >> "$log_file"
    fi
}


# ═══ DATA SIDECAR CITABLE (v8.14b, punto 13) ═══
# Un corte de datos citable por versión: lo que el motor dejó en users/ricardo/ y el sitio sirve
# (output.txt, los 10 sankeys, NTA/*, SankeyNTA/sankey-v3-grupoedad.json, las 32 carpetas
# users/ricardo/<ABREV>/ y entidades.json + entidades-pibe32.json) empaquetado en
# users/_sidecar/<version>/datos-<version>.zip, con manifest-datos.json al lado: sha256 y bytes
# por archivo, versión, commit, data_updated y los vintages que leyó la corrida TAL COMO LOS
# REGISTRA EL MOTOR (manifest.json enigh_vintage; users/ricardo/cache/sello.txt; la procedencia y
# las anclas de NTA/nta-grupoedad.json; base_generada de master/PIBDeflactor<ABREV>.meta; los
# vintages de la banda ENIGH que declara <ABREV>/sankey-quintil.json). Los dos archivos suben a la
# Release como assets y se verifican por sha256 como los 26 crudos (release_post_verify). Nada
# externo (sin Zenodo): la cita es la Release. Gate 9: desde v8.14.0, publicar.sh --check exige
# que el sidecar exista y cuadre (zip ↔ manifest ↔ users/ricardo). CITATION.cff en la raíz
# (Gate 10, también en --ci) lleva versión y fecha del manifest.
SIDECAR_ROOT="$REPO_ROOT/users/_sidecar"
SIDECAR_DESDE="v8.14.0"          # primera versión con sidecar obligatorio

sidecar_aplica() {   # 0 si <version> >= SIDECAR_DESDE (orden de versión), 1 si no
    [[ "$(printf '%s\n%s\n' "$SIDECAR_DESDE" "$1" | sort -V | head -n 1)" == "$SIDECAR_DESDE" ]]
}

# Lista de archivos del corte, relativa a users/ricardo/ (una ruta por línea). El catálogo de las 32
# se lee de SIMentidad.ado (global entidadesC sin «Nac»), como en publicar-vps.sh Fase 3b-ter.
sidecar_lista() {
    local ab f abrevs
    echo "output.txt"
    for f in decil grupoedad sexo rural escol; do echo "sankey-$f.json"; echo "SankeyNTA/sankey-$f.json"; done
    echo "SankeyNTA/sankey-v3-grupoedad.json"
    ( cd "$REPO_ROOT/users/ricardo/NTA" 2>/dev/null && ls -1 | sed 's#^#NTA/#' ) || true
    abrevs="$(sed -nE 's/^[[:space:]]*global entidadesC "([^"]*)".*/\1/p' "$REPO_ROOT/SIMentidad.ado" | head -1 | sed -E 's/ Nac$//')"
    for ab in $abrevs; do
        for f in sankey-quintil.json sankey-grupoedad.json sankey-sexo.json sankey-rural.json sankey-escol.json ciclo-vida.json tasas-efectivas.json neto-pibe.json meta.json; do
            echo "$ab/$f"
        done
    done
    echo "entidades.json"
    echo "entidades-pibe32.json"
}

sidecar_empaquetar() {
    local version="$1"
    log_step "Data sidecar citable: datos-$version.zip + manifest-datos.json"
    local base="$REPO_ROOT/users/ricardo"
    [[ -d "$base" ]] || abort "No existe $base: el sidecar se empaqueta desde la corrida completa de SIM.do + contrato-32.sh (runbook §1)."
    local faltan="" f
    while IFS= read -r f; do [[ -f "$base/$f" ]] || faltan+=$'\n'"  - users/ricardo/$f"; done < <(sidecar_lista)
    [[ -z "$faltan" ]] || abort "Faltan archivos del corte en users/ricardo/ (¿corrió SIM.do completo y contrato-32.sh?):$faltan"
    [[ -n "$(ls -1 "$base/NTA" 2>/dev/null)" ]] || abort "users/ricardo/NTA/ está vacío: el sidecar exige la cuenta NTA (SIM.do §3.2b)."
    local dir="$SIDECAR_ROOT/$version" commit
    mkdir -p "$dir"
    commit="$(git rev-parse --short HEAD)"
    local lista
    lista="$(mktemp -t sidecar-lista-XXXXXX)"
    sidecar_lista > "$lista"
    python3 - "$REPO_ROOT" "$version" "$commit" "$dir" "$lista" <<'PYEOF'
import hashlib, json, os, re, sys, zipfile, datetime
root, version, commit, outdir, lista = sys.argv[1:6]
base = os.path.join(root, 'users', 'ricardo')
archivos = [l.strip() for l in open(lista, encoding='utf-8') if l.strip()]
def sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for b in iter(lambda: fh.read(1 << 20), b''): h.update(b)
    return h.hexdigest()
man = json.load(open(os.path.join(root, '05_scripts', 'manifest.json'), encoding='utf-8'))
# vintages tal como los registra el motor (se copian, no se calculan)
vint = {'enigh_vintage': man.get('enigh_vintage'), 'data_updated': man.get('data_updated')}
sello = os.path.join(base, 'cache', 'sello.txt')
if os.path.isfile(sello):
    vint['cache_sello'] = {}
    insumos = []
    for l in open(sello, encoding='utf-8', errors='replace'):
        c = l.rstrip('\n').split('\t')
        if c[0] == 'sello' and len(c) >= 3: vint['cache_sello'][c[1]] = c[2]
        elif c[0] == 'insumo' and len(c) >= 4: insumos.append({'item': c[1], 'ruta': c[2], 'bytes': c[3]})
    vint['cache_insumos'] = insumos
nta = os.path.join(base, 'NTA', 'nta-grupoedad.json')
if os.path.isfile(nta):
    d = json.load(open(nta, encoding='utf-8'))
    vint['nta_anio'] = d.get('anio')
    vint['nta_procedencia'] = d.get('procedencia')
    vint['nta_anclas'] = d.get('anclas')
pibe = {}
mdir = os.path.join(root, 'master')
if os.path.isdir(mdir):
    for f in sorted(os.listdir(mdir)):
        m = re.match(r'PIBDeflactor(\w+)\.meta$', f)
        if m:
            for l in open(os.path.join(mdir, f), encoding='utf-8', errors='replace'):
                if l.startswith('base_generada='): pibe[m.group(1)] = l.split('=', 1)[1].strip()
vint['pibe_base_generada'] = pibe
nl = os.path.join(base, 'NL', 'sankey-quintil.json')
if os.path.isfile(nl):
    s = open(nl, encoding='utf-8').read()
    m = re.search(r'vintages:"([^"]*)"', s); mo = re.search(r'vintagesOmitidos:"([^"]*)"', s)
    vint['banda_enigh_vintages'] = m.group(1) if m else ''
    vint['banda_enigh_omitidos'] = mo.group(1) if mo else ''
entradas = []
zpath = os.path.join(outdir, 'datos-%s.zip' % version)
with zipfile.ZipFile(zpath, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for rel in archivos:
        p = os.path.join(base, rel)
        entradas.append({'path': 'users/ricardo/' + rel, 'sha256': sha(p), 'bytes': os.path.getsize(p)})
        zi = zipfile.ZipInfo('users/ricardo/' + rel, date_time=(1980, 1, 1, 0, 0, 0))   # fecha fija: zip reproducible
        zi.compress_type = zipfile.ZIP_DEFLATED
        with open(p, 'rb') as fh: z.writestr(zi, fh.read())
anio = (man.get('data_updated') or '')[:4]
manifest = {
    'esquema': 'ciep.datos-sidecar/v1',
    'version': version, 'release_tag': man.get('release_tag'), 'commit': commit,
    'data_updated': man.get('data_updated'), 'enigh_vintage': man.get('enigh_vintage'),
    'descripcion': 'Corte de datos citable del Simulador Fiscal CIEP: lo que el motor dejó en users/ricardo/ (escenario default del sitio, cuenta NTA, Sankeys, las 32 entidades) en la corrida que publicó esta versión.',
    'cita': 'CIEP (%s). Simulador Fiscal CIEP %s, datos al %s. https://github.com/rcantuc/SimuladorCIEP/releases/tag/%s' % (anio, version, man.get('data_updated'), version),
    'zip': {'name': os.path.basename(zpath), 'sha256': sha(zpath), 'bytes': os.path.getsize(zpath)},
    'archivos': entradas,
    'vintages': vint,
    'generado_en': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
}
json.dump(manifest, open(os.path.join(outdir, 'manifest-datos.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('%d archivos, %.1f MB sin comprimir, zip %.1f MB (%s)' % (len(entradas), sum(e['bytes'] for e in entradas) / 1e6, os.path.getsize(zpath) / 1e6, manifest['zip']['sha256'][:12]))
PYEOF
    rm -f "$lista"
    log_info "✓ Sidecar en $dir: datos-$version.zip + manifest-datos.json"
}

# Gate 9 — el sidecar existe y cuadra: manifest-datos.json ↔ zip ↔ users/ricardo/ (sha256 por archivo) y
# el sha256 del zip es el que declara el manifest. Solo desde SIDECAR_DESDE; se omite en --ci (sin users/).
gate_sidecar_datos() {
    local version="$1"
    if ! sidecar_aplica "$version"; then
        log_info "Gate 9: el sidecar de datos aplica desde $SIDECAR_DESDE; $version queda fuera."
        return 0
    fi
    local dir="$SIDECAR_ROOT/$version" zip="$SIDECAR_ROOT/$version/datos-$version.zip" man="$SIDECAR_ROOT/$version/manifest-datos.json"
    if [[ ! -f "$zip" || ! -f "$man" ]]; then
        log_error "Gate 9 FALLO: no existe el sidecar de datos de $version ($dir/{datos-$version.zip, manifest-datos.json})."
        log_error "        Constrúyelo desde la corrida completa: bash 05_scripts/publicar.sh $version --empaquetar-datos"
        return 1
    fi
    local out
    if ! out="$(python3 - "$REPO_ROOT" "$version" "$zip" "$man" <<'PYEOF'
import hashlib, json, os, sys, zipfile
root, version, zpath, mpath = sys.argv[1:5]
def sha_bytes(b): return hashlib.sha256(b).hexdigest()
def sha_file(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for b in iter(lambda: fh.read(1 << 20), b''): h.update(b)
    return h.hexdigest()
m = json.load(open(mpath, encoding='utf-8'))
fallas = []
if m.get('version') != version: fallas.append('manifest-datos.version %s != %s' % (m.get('version'), version))
if m['zip']['sha256'] != sha_file(zpath): fallas.append('sha256 del zip != manifest-datos.zip.sha256')
with zipfile.ZipFile(zpath) as z:
    nombres = set(z.namelist())
    for e in m['archivos']:
        if e['path'] not in nombres: fallas.append('falta en el zip: ' + e['path']); continue
        if sha_bytes(z.read(e['path'])) != e['sha256']: fallas.append('sha256 en el zip != manifest: ' + e['path'])
        local = os.path.join(root, e['path'])
        if not os.path.isfile(local): fallas.append('no existe en el clon: ' + e['path'])
        elif sha_file(local) != e['sha256']: fallas.append('users/ricardo cambió desde el empaquetado: ' + e['path'])
    extra = nombres - {e['path'] for e in m['archivos']}
    if extra: fallas.append('el zip trae archivos que el manifest no declara: ' + ', '.join(sorted(extra)[:5]))
if fallas:
    print('\n'.join(fallas)); sys.exit(1)
print('%d archivos cuadran (zip %.1f MB, commit %s, data_updated %s)' % (len(m['archivos']), m['zip']['bytes'] / 1e6, m.get('commit'), m.get('data_updated')))
PYEOF
)"; then
        log_error "Gate 9 FALLO: el sidecar de $version no cuadra:"
        while IFS= read -r l; do log_error "        $l"; done <<< "$out"
        log_error "        Re-empaqueta desde la corrida vigente: bash 05_scripts/publicar.sh $version --empaquetar-datos"
        return 1
    fi
    log_info "✓ Gate 9: sidecar de datos de $version — $out"
    return 0
}

# Gate 10 — CITATION.cff sincronizado con el manifest (version y date-released = data_updated; URL de la Release).
# Estático: corre también en --ci. --citation lo regenera.
citation_render() {
    python3 - "$REPO_ROOT" <<'PYEOF'
import json, sys, os
root = sys.argv[1]
m = json.load(open(os.path.join(root, '05_scripts', 'manifest.json'), encoding='utf-8'))
v, d = m['version'], m['data_updated']
url = 'https://github.com/rcantuc/SimuladorCIEP/releases/tag/' + v
L = [
'# CITATION.cff — cómo citar el Simulador Fiscal CIEP (lo lee GitHub: botón «Cite this repository»).',
'# GENERADO por 05_scripts/publicar.sh --citation desde 05_scripts/manifest.json (version y data_updated);',
'# el Gate 10 de publicar.sh (--check y --ci) exige que esté sincronizado. No editar a mano version, date-released',
'# ni la URL de la Release: cambia el manifest y regenera.',
'cff-version: 1.2.0',
'message: "Si usas el Simulador Fiscal CIEP o su corte de datos, cita la versión y la fecha de los datos: CIEP (%s). Simulador Fiscal CIEP %s, datos al %s. %s"' % (d[:4], v, d, url),
'type: software',
'title: "Simulador Fiscal CIEP"',
'abstract: "Motor de simulación fiscal del Centro de Investigación Económica y Presupuestaria (CIEP): armoniza la ENIGH con el Sistema de Cuentas Nacionales, la Ley de Ingresos y el Presupuesto de Egresos de la Federación, y publica el escenario default del sitio, la cuenta de Transferencias Nacionales por individuo y el contrato de las 32 entidades. Cada versión publica en su Release de GitHub el código, los insumos crudos verificados por SHA-256 y el corte de datos citable datos-<version>.zip con su manifest-datos.json."',
'authors:',
'  - name: "Centro de Investigación Económica y Presupuestaria, A.C. (CIEP)"',
'    city: "Ciudad de México"',
'    country: MX',
'    website: "https://ciep.mx"',
'  - family-names: "Cantú Calderón"',
'    given-names: "Ricardo"',
'    affiliation: "Centro de Investigación Económica y Presupuestaria, A.C. (CIEP)"',
'    email: "ricardocantu@ciep.mx"',
'version: "%s"' % v,
'date-released: "%s"' % d,
'repository-code: "https://github.com/rcantuc/SimuladorCIEP"',
'url: "https://simuladorfiscal.ciep.mx"',
'keywords:',
'  - "política fiscal"',
'  - "incidencia fiscal"',
'  - "National Transfer Accounts"',
'  - "ENIGH"',
'  - "Stata"',
'  - "México"',
'identifiers:',
'  - type: url',
'    value: "%s"' % url,
'    description: "Release de esta versión: código, insumos crudos (SHA-256) y el corte de datos citable (datos-%s.zip + manifest-datos.json)."' % v,
'preferred-citation:',
'  type: software',
'  title: "Simulador Fiscal CIEP %s, datos al %s"' % (v, d),
'  authors:',
'    - name: "Centro de Investigación Económica y Presupuestaria, A.C. (CIEP)"',
'    - family-names: "Cantú Calderón"',
'      given-names: "Ricardo"',
'  version: "%s"' % v,
'  date-released: "%s"' % d,
'  url: "%s"' % url,
'  year: %s' % d[:4],
]
sys.stdout.write('\n'.join(L) + '\n')
PYEOF
}

gate_citation() {
    local f="$REPO_ROOT/CITATION.cff"
    if [[ ! -f "$f" ]]; then
        log_error "Gate 10 FALLO: no existe CITATION.cff en la raíz. Genéralo: bash 05_scripts/publicar.sh --citation"
        return 1
    fi
    local esperado
    esperado="$(citation_render)"
    if [[ "$(cat "$f")" != "$esperado" ]]; then
        log_error "Gate 10 FALLO: CITATION.cff no está sincronizado con 05_scripts/manifest.json (version / data_updated / URL de la Release)."
        log_error "        Regenera y commitea: bash 05_scripts/publicar.sh --citation"
        diff <(echo "$esperado") "$f" | head -n 8 | while IFS= read -r l; do log_error "        $l"; done
        return 1
    fi
    log_info "✓ Gate 10: CITATION.cff sincronizado con el manifest ($(sed -nE 's/^version: "(.*)"/\1/p' "$f"), datos al $(sed -nE 's/^date-released: "(.*)"/\1/p' "$f"))"
    return 0
}

# Assets del sidecar en la Release: subir los dos (idempotente) y verificar por digest sha256.
sidecar_upload() {
    local version="$1" dir="$SIDECAR_ROOT/$1"
    sidecar_aplica "$version" || return 0
    local remote f
    remote="$(remote_assets "$version" || true)"
    for f in "datos-$version.zip" "manifest-datos.json"; do
        if [[ -n "$(awk -F'\t' -v n="$f" '$1==n{print $2}' <<< "$remote")" ]]; then
            log_info "Sidecar: $f ya está en la Release $version"
            continue
        fi
        log_info "Subiendo sidecar $f..."
        gh release upload "$version" "$dir/$f" || abort "Falló la subida de $dir/$f. Re-corre el script: los ya subidos se omiten."
    done
}

sidecar_post_verify() {
    local version="$1" dir="$SIDECAR_ROOT/$1"
    sidecar_aplica "$version" || return 0
    local remote zsha msha rz rm_
    remote="$(remote_assets "$version" || true)"
    zsha="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["zip"]["sha256"])' "$dir/manifest-datos.json")"
    msha="$(shasum -a 256 "$dir/manifest-datos.json" | awk '{print $1}')"
    rz="$(awk -F'\t' -v n="datos-$version.zip" '$1==n{print $3}' <<< "$remote")"
    rm_="$(awk -F'\t' -v n="manifest-datos.json" '$1==n{print $3}' <<< "$remote")"
    if [[ "$rz" == "$zsha" && "$rm_" == "$msha" ]]; then
        log_info "✓ Sidecar verificado en la Release por digest sha256: datos-$version.zip (${zsha:0:12}…) y manifest-datos.json (${msha:0:12}…)"
    else
        log_warn "Sidecar: digest remoto distinto o ausente (zip ${rz:0:12}… vs ${zsha:0:12}…; manifest ${rm_:0:12}… vs ${msha:0:12}…). Investiga antes de anunciar."
    fi
}

# ═══ PARSING DE ARGUMENTOS ═══

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)                CHECK_MODE=true; shift ;;
        --ci)                   CHECK_MODE=true; CI_MODE=true; shift ;;
        --tag-message=*)        TAG_MESSAGE="${1#*=}"; shift ;;
        --endpoint-dry-run)     ENDPOINT_DRY_RUN=true; shift ;;
        --skip-post-verify)     SKIP_POST_VERIFY=true; shift ;;
        --solo-assets)          SOLO_ASSETS=true; shift ;;
        --poblar-raw)           POBLAR_RAW=true; shift ;;
        --empaquetar-datos)     EMPAQUETAR_DATOS=true; shift ;;
        --citation)             CITATION_ONLY=true; shift ;;
        --force)                FORCE=true; shift ;;
        -h|--help)              usage; exit 0 ;;
        v*)                     VERSION="$1"; shift ;;
        *)                      log_error "Argumento desconocido: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$VERSION" && ( "$CI_MODE" == "true" || "$CITATION_ONLY" == "true" ) && -f "$REPO_ROOT/05_scripts/manifest.json" ]]; then
    VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$REPO_ROOT/05_scripts/manifest.json")"
fi
[[ -z "$VERSION" ]] && { log_error "Falta <version>"; usage; exit 1; }
[[ -z "$REPO_ROOT" ]] && abort "No se pudo detectar root del repo Git."

cd "$REPO_ROOT"

# ─── Modo --citation (v8.14b): regenerar CITATION.cff desde el manifest y terminar ───
if [[ "$CITATION_ONLY" == "true" ]]; then
    citation_render > "$REPO_ROOT/CITATION.cff"
    log_info "CITATION.cff regenerado desde 05_scripts/manifest.json ($VERSION). Commitéalo."
    exit 0
fi

# ─── Guard de identidad de clon (2026-09-09) ───
# Se publica SOLO desde el clon de desarrollo. La Carpeta del Simulador para
# investigadores (Dropbox-CIEP/SimuladorCIEP) también es un clon git, así que
# `git rev-parse` no distingue uno del otro: el 2026-09-08 se lanzó publicar.sh
# desde la Carpeta sin querer y el pre-chequeo de assets falló de forma
# confusa. El clon de desarrollo se identifica con un marker gitignored en su
# raíz (.clon-desarrollo); la Carpeta nunca lo tiene porque git no lo propaga.
CLON_MARKER="$REPO_ROOT/.clon-desarrollo"
if [[ ! -f "$CLON_MARKER" && "$CI_MODE" != "true" ]]; then   # --ci: el runner no es ningún clon; solo corre gates de lectura
    log_error "Estás en $REPO_ROOT"
    log_error "y este clon NO está marcado como clon de desarrollo (falta .clon-desarrollo)."
    if [[ "$REPO_ROOT" == */Dropbox-CIEP/SimuladorCIEP ]]; then
        log_error "Esta ruta es la Carpeta del Simulador para investigadores: aquí NO se publica"
        log_error "ni se opera git (§6.7 de arquitectura.md). Ve al clon de desarrollo."
    else
        log_error "Publica desde el clon de desarrollo (el que tiene el marker). Si ESTE es el"
        log_error "clon de desarrollo y solo falta el marker, créalo una vez:"
        log_error "    touch \"$CLON_MARKER\""
    fi
    exit 1
fi

# ═══ EJECUCIÓN ═══

log_info "publicar.sh — versión: $VERSION"

# ─── Modo --check: solo gates, sin acciones, fallas acumuladas ───
if [[ "$CHECK_MODE" == "true" ]]; then
    log_step "Modo --check: gates de validación (sin acciones)"
    GATE_FAILURES=0
    if [[ "$CI_MODE" == "true" ]]; then
        log_warn "Candado del ritual omitido en --ci (el runner no tiene corridas de evidencia)."
    else
        gate_corridas_vivas        || GATE_FAILURES=$((GATE_FAILURES+1))
    fi
    gate_changelog "$VERSION"      || GATE_FAILURES=$((GATE_FAILURES+1))
    if [[ "$CI_MODE" == "true" ]]; then
        log_warn "Gate 2 omitido en --ci: el tag $VERSION lo crea publicar.sh al publicar (gate de sesión)."
    else
        gate_tag_annotated "$VERSION"  || GATE_FAILURES=$((GATE_FAILURES+1))
    fi
    gate_manifest_sync "$VERSION"  || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_endpoint_files            || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_raw_declarado             || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_cobertura_assets          || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_pkg_clausura              || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_release_remota "$VERSION" || GATE_FAILURES=$((GATE_FAILURES+1))
    if [[ "$CI_MODE" == "true" ]]; then
        log_warn "Gate 9 (sidecar de datos) omitido en --ci: el runner no tiene users/ricardo/."
    else
        gate_sidecar_datos "$VERSION" || GATE_FAILURES=$((GATE_FAILURES+1))
    fi
    gate_citation                  || GATE_FAILURES=$((GATE_FAILURES+1))
    if (( GATE_FAILURES > 0 )); then
        log_error "--check: $GATE_FAILURES gate(s) fallaron para $VERSION."   # también en --ci
        exit 1
    fi
    if [[ "$CI_MODE" == "true" ]]; then
        log_info "--ci: los 8 gates sin Stata ni assets pasaron para $VERSION (Gates 2 y 9 omitidos)."
    else
        log_info "--check: los 10 gates pasaron para $VERSION."
    fi
    exit 0
fi

# ─── Modo --empaquetar-datos (v8.14b): solo el sidecar, desde users/ricardo/ de este clon ───
if [[ "$EMPAQUETAR_DATOS" == "true" ]]; then
    sidecar_empaquetar "$VERSION"
    gate_sidecar_datos "$VERSION" || exit 1
    exit 0
fi

# ─── Candado del ritual (v8.14): también antes de --poblar-raw, --solo-assets y la publicación real ───
gate_corridas_vivas || abort "Candado del ritual: no se publica con corridas vivas o con el último log de corrida sin cerrar."

# ─── Modo --poblar-raw: traer a raw/ local los assets que falten, desde la Release ───
if [[ "$POBLAR_RAW" == "true" ]]; then
    log_step "Modo --poblar-raw: assets del manifest ausentes en raw/ local, desde la Release $VERSION"
    require_gh
    gh release view "$VERSION" >/dev/null 2>&1 || abort "La Release $VERSION no existe en GitHub."
    tmp_dir="$(mktemp -d -t publicar-poblar-XXXXXX)"
    bajados=0 presentes=0 fallas=0
    while IFS=$'\t' read -r name local_path sha; do
        if [[ -f "$local_path" ]]; then presentes=$((presentes+1)); continue; fi
        log_info "Descargando $name -> $local_path ..."
        rm -f "$tmp_dir/$name"
        if ! gh release download "$VERSION" --pattern "$name" --dir "$tmp_dir" 2>/dev/null; then
            log_error "  - $name: no se pudo descargar de la Release $VERSION"; fallas=$((fallas+1)); continue
        fi
        actual="$(shasum -a 256 "$tmp_dir/$name" | awk '{print $1}')"
        if [[ "$actual" != "$sha" ]]; then
            log_error "  - $name: SHA descargado ${actual:0:12}... != manifest ${sha:0:12}... (no se instala)"; fallas=$((fallas+1)); rm -f "$tmp_dir/$name"; continue
        fi
        mkdir -p "$(dirname "$local_path")"
        mv "$tmp_dir/$name" "$local_path"
        bajados=$((bajados+1))
    done < <(manifest_assets)
    rm -rf "$tmp_dir"
    log_info "--poblar-raw: $bajados descargados y verificados, $presentes ya estaban, $fallas fallas."
    (( fallas > 0 )) && exit 1
    gate_raw_declarado || exit 1
    exit 0
fi

# ─── Modo --solo-assets: reparar una Release existente sin assets ───
if [[ "$SOLO_ASSETS" == "true" ]]; then
    log_step "Modo --solo-assets: subir a la Release $VERSION los assets del manifest que falten"
    gh release view "$VERSION" >/dev/null 2>&1 || abort "La Release $VERSION no existe en GitHub; usa publicar.sh $VERSION completo."
    gate_raw_declarado || abort "Gate 5 falló: los assets locales no coinciden con el manifest."
    assets_upload "$VERSION"
    if sidecar_aplica "$VERSION"; then
        gate_sidecar_datos "$VERSION" || abort "Gate 9 falló: el sidecar de datos no existe o no cuadra (publicar.sh $VERSION --empaquetar-datos)."
        sidecar_upload "$VERSION"
    fi
    if [[ "$SKIP_POST_VERIFY" == "true" ]]; then log_warn "--skip-post-verify activo"; else release_post_verify "$VERSION"; sidecar_post_verify "$VERSION"; fi
    gate_release_remota "$VERSION" || exit 1
    exit 0
fi

verify_repo_state
require_gh

# ─── Gates baratos ANTES de crear el tag ───
log_step "Gates de validación pre-publicación"
GATE_FAILURES=0
gate_changelog "$VERSION"      || GATE_FAILURES=$((GATE_FAILURES+1))
gate_manifest_sync "$VERSION"  || GATE_FAILURES=$((GATE_FAILURES+1))
gate_endpoint_files            || GATE_FAILURES=$((GATE_FAILURES+1))
gate_raw_declarado             || GATE_FAILURES=$((GATE_FAILURES+1))
gate_cobertura_assets          || GATE_FAILURES=$((GATE_FAILURES+1))
gate_pkg_clausura              || GATE_FAILURES=$((GATE_FAILURES+1))
gate_citation                  || GATE_FAILURES=$((GATE_FAILURES+1))
if (( GATE_FAILURES > 0 )); then
    abort "$GATE_FAILURES gate(s) fallaron. Corrige antes de publicar."
fi

# ─── Fase data sidecar (v8.14b): se empaqueta desde users/ricardo/ de este worktree y debe cuadrar ───
if sidecar_aplica "$VERSION"; then
    sidecar_empaquetar "$VERSION"
    gate_sidecar_datos "$VERSION" || abort "Gate 9 falló: el sidecar de datos no cuadra."
fi

log_step "Tag de versión"

ensure_tag_exists "$VERSION"
# Gate 2 corre después de ensure_tag_exists: valida tanto tags preexistentes
# como el recién creado (crear un tag local es reversible con git tag -d).
gate_tag_annotated "$VERSION" || abort "Gate 2 falló. Corrige el tag antes de publicar."
ensure_tag_pushed "$VERSION"

# ─── Release inmutable primero, endpoint operativo después ───
release_create "$VERSION"
assets_upload "$VERSION"
sidecar_upload "$VERSION"
release_post_verify "$VERSION"
sidecar_post_verify "$VERSION"

log_step "Publicación al endpoint"

log_info "Invocando publicar-endpoint.sh..."
endpoint_args=()
[[ "$ENDPOINT_DRY_RUN" == "true" ]] && endpoint_args+=("--dry-run")
[[ "$FORCE" == "true" ]] && endpoint_args+=("--force")
endpoint_args+=("$VERSION")

"$REPO_ROOT/05_scripts/publicar-endpoint.sh" "${endpoint_args[@]}"

log_info ""
log_info "publicar.sh: publicación completada para $VERSION"

exit 0
