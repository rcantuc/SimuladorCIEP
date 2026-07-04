#!/usr/bin/env bash
# publicar.sh — Publica una versión nueva al endpoint público del Simulador Fiscal CIEP
#
# Qué hace:
#   1. Verifica precondiciones (master, working tree limpio, alineación con origin/master)
#   2. Gates de validación: entrada en CHANGELOG.md, tag anotado con mensaje,
#      manifest.json sincronizado con la versión. Si algo falla, aborta ANTES de
#      cualquier acción con efectos (push, Release, rsync).
#   3. Si la etiqueta de versión no existe localmente, ofrece crearla (interactivo o por flag)
#   4. Push del tag a origin si aún no está allá
#   5. Invoca publicar-endpoint.sh con la versión, que sincroniza el sub-canal Stata al
#      servidor Cloudways (ver §3.2 y §6.6 de governance/arquitectura-distribucion.md)
#
# Modo --check: ejecuta SOLO los gates (sin crear tag, sin push, sin Release, sin rsync).
# Reporta todas las fallas acumuladas. Exit 0 si todos pasan, 1 si alguno falla.
#
# La sincronización de la Carpeta del Simulador para investigadores (Dropbox-CIEP/SimuladorCIEP)
# NO es responsabilidad de este script. La maneja manualmente el investigador principal
# mediante `git pull` en su clon local. Ver §6.7 de arquitectura-distribucion.md.

set -euo pipefail

# ═══ CONFIGURACIÓN ═══

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

VERSION=""
TAG_MESSAGE=""
ENDPOINT_DRY_RUN=false
FORCE=false
CHECK_MODE=false

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
                        manifest sincronizado) sin acciones con efectos. Exit 0 si
                        todos pasan, 1 si alguno falla.
  --tag-message=MSG     Mensaje del tag inline (evita abrir editor)
  --endpoint-dry-run    Dry-run del endpoint (no toca el servidor)
  --force               Permite republish de versión existente
  -h, --help            Ayuda

Ejemplos:
  $(basename "$0") v8.1
  $(basename "$0") v8.1 --check
  $(basename "$0") v8.1 --tag-message="Fix bug en LIF"
  $(basename "$0") v8.2 --endpoint-dry-run

La sincronización de la Carpeta para investigadores (Dropbox-CIEP/SimuladorCIEP)
NO la hace este script. La maneja manualmente el investigador principal con
'git pull' en su clon local. Ver governance/arquitectura-distribucion.md §6.7.

Configuración: requiere endpoint-credentials.sh con SSH_ALIAS, REMOTE_PATH y
ENDPOINT_URL definidos.
EOF
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
# Los tres gates corren ANTES de cualquier acción con efectos (push, Release, rsync).
# Cada gate imprime su resultado y devuelve 0 (pasa) o 1 (falla).

gate_changelog() {
    local version="$1"
    local ver_re="${version//./\\.}"
    if grep -qE "^## \[${ver_re}\] (—|-) [0-9]{4}-[0-9]{2}-[0-9]{2}" CHANGELOG.md 2>/dev/null; then
        log_info "✓ Gate 1: CHANGELOG.md contiene entrada para $version"
        return 0
    fi
    log_error "Gate 1: CHANGELOG.md no contiene entrada para $version. Edítalo antes de publicar."
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
    if [[ ! -f manifest.json ]]; then
        log_error "Gate 3: manifest.json no existe en el root del repo."
        return 1
    fi
    local errors
    errors="$(python3 - "$version" <<'PYEOF'
import json, sys
version = sys.argv[1]
try:
    with open("manifest.json", encoding="utf-8") as f:
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
        log_error "Gate 3: manifest.json no está sincronizado con $version:"
        while IFS= read -r line; do
            log_error "        - $line"
        done <<< "$errors"
        log_error "        Actualiza version, release_tag y release_url_prefix en manifest.json"
        log_error "        (y regenera los assets si la versión trae datos nuevos)."
        return 1
    fi
    log_info "✓ Gate 3: manifest.json sincronizado con $version"
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

# ═══ PARSING DE ARGUMENTOS ═══

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)                CHECK_MODE=true; shift ;;
        --tag-message=*)        TAG_MESSAGE="${1#*=}"; shift ;;
        --endpoint-dry-run)     ENDPOINT_DRY_RUN=true; shift ;;
        --force)                FORCE=true; shift ;;
        -h|--help)              usage; exit 0 ;;
        v*)                     VERSION="$1"; shift ;;
        *)                      log_error "Argumento desconocido: $1"; usage; exit 1 ;;
    esac
done

[[ -z "$VERSION" ]] && { log_error "Falta <version>"; usage; exit 1; }
[[ -z "$REPO_ROOT" ]] && abort "No se pudo detectar root del repo Git."

cd "$REPO_ROOT"

# ═══ EJECUCIÓN ═══

log_info "publicar.sh — versión: $VERSION"

# ─── Modo --check: solo gates, sin acciones, fallas acumuladas ───
if [[ "$CHECK_MODE" == "true" ]]; then
    log_step "Modo --check: gates de validación (sin acciones)"
    GATE_FAILURES=0
    gate_changelog "$VERSION"      || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_tag_annotated "$VERSION"  || GATE_FAILURES=$((GATE_FAILURES+1))
    gate_manifest_sync "$VERSION"  || GATE_FAILURES=$((GATE_FAILURES+1))
    if (( GATE_FAILURES > 0 )); then
        log_error "--check: $GATE_FAILURES gate(s) fallaron para $VERSION."
        exit 1
    fi
    log_info "--check: los 3 gates pasaron para $VERSION."
    exit 0
fi

verify_repo_state

# ─── Gates baratos ANTES de crear el tag ───
log_step "Gates de validación pre-publicación"
GATE_FAILURES=0
gate_changelog "$VERSION"      || GATE_FAILURES=$((GATE_FAILURES+1))
gate_manifest_sync "$VERSION"  || GATE_FAILURES=$((GATE_FAILURES+1))
if (( GATE_FAILURES > 0 )); then
    abort "$GATE_FAILURES gate(s) fallaron. Corrige antes de publicar."
fi

log_step "Publicación al endpoint"

ensure_tag_exists "$VERSION"
# Gate 2 corre después de ensure_tag_exists: valida tanto tags preexistentes
# como el recién creado (crear un tag local es reversible con git tag -d).
gate_tag_annotated "$VERSION" || abort "Gate 2 falló. Corrige el tag antes de publicar."
ensure_tag_pushed "$VERSION"

log_info "Invocando publicar-endpoint.sh..."
endpoint_args=()
[[ "$ENDPOINT_DRY_RUN" == "true" ]] && endpoint_args+=("--dry-run")
[[ "$FORCE" == "true" ]] && endpoint_args+=("--force")
endpoint_args+=("$VERSION")

"$REPO_ROOT/publicar-endpoint.sh" "${endpoint_args[@]}"

log_info ""
log_info "publicar.sh: publicación completada para $VERSION"

exit 0
