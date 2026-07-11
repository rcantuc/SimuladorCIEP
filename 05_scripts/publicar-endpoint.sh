#!/usr/bin/env bash
# publicar-endpoint.sh — Publica el sub-canal Stata del Simulador Fiscal CIEP
# al endpoint público https://ciep.mx/simuladorfiscal/.
#
# Reemplaza el flujo manual histórico (staging en Stata net/ + SCP manual).
# Lee 05_scripts/manifest-endpoint.toml para saber qué archivos publicar.
#
# Uso: publicar-endpoint.sh [opciones] <version>
# Ver --help para detalles.

set -euo pipefail

# ═══ HEADER, DEFAULTS, CONSTANTES ═══

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TIMESTAMP_FILENAME="$(date -u +%Y%m%d-%H%M%S)"

DRY_RUN=false
SKIP_BACKUP=false
FORCE=false
VERSION=""

# Colores
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

# ═══ FUNCIONES DE UTILIDAD ═══

log_info()  { printf "${GREEN}[INFO]${NC} %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log_step()  { printf "\n${GREEN}═══${NC} %s ${GREEN}═══${NC}\n" "$*"; }

abort() {
    log_error "$1"
    exit "${2:-1}"
}

usage() {
    cat <<EOF
Uso: $(basename "$0") [opciones] <version>

Publica el sub-canal Stata del Simulador Fiscal CIEP al endpoint público.

Opciones:
  --dry-run        Verifica y muestra qué cambiaría sin tocar el servidor
  --skip-backup    Omite el backup pre-deploy del estado actual del endpoint
  --force          Permite republish ignorando "tag existe en remoto"
  -h, --help       Esta ayuda

Argumento:
  <version>        Etiqueta de versión (ej. v8.0, v7.0.1)

Ejemplos:
  $(basename "$0") --dry-run v8.0
  $(basename "$0") v8.0
EOF
}

# ═══ PARSING DE ARGUMENTOS ═══

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)      DRY_RUN=true; shift ;;
        --skip-backup)  SKIP_BACKUP=true; shift ;;
        --force)        FORCE=true; shift ;;
        -h|--help)      usage; exit 0 ;;
        v*)             VERSION="$1"; shift ;;
        *)              log_error "Argumento desconocido: $1"; usage; exit 1 ;;
    esac
done

[[ -z "$VERSION" ]] && { log_error "Falta argumento <version>."; usage; exit 1; }
[[ -z "$REPO_ROOT" ]] && abort "No se pudo detectar root del repo Git."

cd "$REPO_ROOT"

# ═══ FASE 0: SETUP ═══

log_step "Fase 0: Setup"

if [[ ! -f 05_scripts/endpoint-credentials.sh ]]; then
    abort "05_scripts/endpoint-credentials.sh no existe. Copia 05_scripts/endpoint-credentials.template.sh y rellena valores."
fi
# shellcheck source=/dev/null
source ./05_scripts/endpoint-credentials.sh

[[ -z "${SSH_ALIAS:-}" ]] && abort "SSH_ALIAS no está definido en endpoint-credentials.sh"
[[ -z "${REMOTE_PATH:-}" ]] && abort "REMOTE_PATH no está definido en endpoint-credentials.sh"
[[ -z "${ENDPOINT_URL:-}" ]] && abort "ENDPOINT_URL no está definido en endpoint-credentials.sh"

for cmd in git rsync ssh python3 curl awk; do
    command -v "$cmd" >/dev/null 2>&1 || abort "Herramienta faltante: $cmd"
done

PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
if ! python3 -c 'import tomllib' 2>/dev/null; then
    abort "Python $PYTHON_VERSION no tiene tomllib. Necesitas Python 3.11+."
fi

log_info "Versión a publicar: $VERSION"
log_info "Modo: dry-run=$DRY_RUN, skip-backup=$SKIP_BACKUP, force=$FORCE"
log_info "Python: $PYTHON_VERSION (tomllib disponible)"

# ═══ FASE 1: VERIFICACIONES PRE-DEPLOY ═══

log_step "Fase 1: Verificaciones pre-deploy"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$CURRENT_BRANCH" != "master" ]] && abort "No estás en branch master (estás en: $CURRENT_BRANCH)"
log_info "✓ En branch master"

if [[ -n "$(git status --porcelain)" ]]; then
    abort "Working tree no está limpio. Commitea o stashea cambios antes de publicar."
fi
log_info "✓ Working tree limpio"

git fetch origin master --quiet
LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/master)"
[[ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]] && abort "HEAD local difiere de origin/master. Pull o push primero."
log_info "✓ Local alineado con origin/master (${LOCAL_HEAD:0:7})"

if ! git rev-parse --verify "refs/tags/$VERSION" >/dev/null 2>&1; then
    if [[ "$FORCE" == "false" ]]; then
        abort "Tag $VERSION no existe localmente. Crea el tag o usa --force."
    fi
    log_warn "Tag $VERSION no existe localmente (--force activo)"
fi

if ! git ls-remote --tags origin "refs/tags/$VERSION" 2>/dev/null | grep -q "$VERSION"; then
    if [[ "$FORCE" == "false" ]]; then
        abort "Tag $VERSION no existe en origin. Push del tag primero, o usa --force."
    fi
    log_warn "Tag $VERSION no existe en origin (--force activo)"
else
    log_info "✓ Tag $VERSION existe en local y remoto"
fi

[[ ! -f 05_scripts/manifest-endpoint.toml ]] && abort "05_scripts/manifest-endpoint.toml no existe en el repo."

MANIFEST_JSON="$(python3 <<'PYEOF'
import tomllib, json, sys
try:
    with open('05_scripts/manifest-endpoint.toml', 'rb') as f:
        data = tomllib.load(f)
    print(json.dumps(data))
except Exception as e:
    sys.stderr.write(f"PARSE_ERROR: {e}\n")
    sys.exit(1)
PYEOF
)"
[[ -z "$MANIFEST_JSON" ]] && abort "Error parseando 05_scripts/manifest-endpoint.toml"
log_info "✓ Manifest parseado correctamente"

# Verificar que cada archivo del manifest existe en el repo
log_info "Verificando existencia de archivos del manifest..."
MISSING=""
ALL_FILES=()
for kind in ado_files sthlp_files pkg_files; do
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        if [[ ! -f "$REPO_ROOT/$f" ]]; then
            MISSING="$MISSING $f"
        else
            ALL_FILES+=("$f")
        fi
    done < <(echo "$MANIFEST_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for f in d.get('package', {}).get('$kind', []):
    print(f)
")
done
if [[ -n "$MISSING" ]]; then
    abort "Archivos del manifest faltan en el repo:$MISSING"
fi
log_info "✓ ${#ALL_FILES[@]} archivos del manifest existen en el repo"

# Conectividad SSH
log_info "Verificando conectividad SSH a $SSH_ALIAS..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$SSH_ALIAS" "echo OK" >/dev/null 2>&1; then
    abort "No se pudo conectar al servidor vía $SSH_ALIAS. Verifica ~/.ssh/config y que la SSH key esté autorizada."
fi
log_info "✓ Conectividad SSH OK"

# Path remoto existe y es escribible
REMOTE_CHECK="$(ssh "$SSH_ALIAS" "[ -d '$REMOTE_PATH' ] && [ -w '$REMOTE_PATH' ] && echo OK || echo FAIL")"
[[ "$REMOTE_CHECK" != "OK" ]] && abort "REMOTE_PATH ($REMOTE_PATH) no existe o no es escribible"
log_info "✓ Path remoto existe y es escribible"

# ═══ FASE 2: PREPARACIÓN ═══

log_step "Fase 2: Preparación"

TMP_DIR="$(mktemp -d -t publicar-endpoint-XXXXXX)"
trap "rm -rf '$TMP_DIR'" EXIT
log_info "Directorio temporal: $TMP_DIR"

# Copiar archivos del manifest al tmp dir
for f in "${ALL_FILES[@]}"; do
    cp "$REPO_ROOT/$f" "$TMP_DIR/"
done

FILE_COUNT="${#ALL_FILES[@]}"
log_info "✓ $FILE_COUNT archivos copiados al tmp dir"

# Inyectar el PIN de versión en la COPIA publicada de ensure_asset.ado.
# El archivo del repo queda intacto (pin vacío): solo la copia distribuida
# lleva la versión quemada, para que un usuario sin repo reconstruya datos
# contra los assets del Release de SU versión instalada.
if [[ ! -f "$TMP_DIR/ensure_asset.ado" ]]; then
    abort "ensure_asset.ado no está en el tmp dir. ¿Falta en ado_files de manifest-endpoint.toml?"
fi
sed -i '' "s|^\([[:space:]]*\)local PINNED_VERSION \"\"|\1local PINNED_VERSION \"$VERSION\"|" "$TMP_DIR/ensure_asset.ado"
if ! grep -q "local PINNED_VERSION \"$VERSION\"" "$TMP_DIR/ensure_asset.ado"; then
    abort "Inyección del pin falló: el marcador 'local PINNED_VERSION \"\"' no está en ensure_asset.ado. ¿Se renombró la línea en el repo?"
fi
log_info "✓ Pin de versión $VERSION inyectado en ensure_asset.ado (solo copia publicada)"

# Generar stata.toc
TODAY="$(date -u +%Y-%m-%d)"
TITLE="$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['toc']['title'])")"
DESC_TEMPLATE="$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['toc']['description_template'])")"
DESC="$(echo "$DESC_TEMPLATE" | sed "s/{VERSION}/$VERSION/g; s/{DATE}/$TODAY/g")"

{
    echo "v 3"
    echo "d $TITLE"
    echo "d $DESC"
    echo ""
    echo "$MANIFEST_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for k, v in d.get('toc', {}).get('packages', {}).items():
    print(f'p {k}')
    print(f'd {v}')
    print()
"
} > "$TMP_DIR/stata.toc"

log_info "✓ stata.toc generado"

# Normalizar permisos en el tmp dir ANTES del rsync (dir 755, archivos 644).
# Razón: el rsync que trae macOS moderno es openrsync, que IGNORA --chmod
# silenciosamente y copia los permisos de origen (-a implica --perms). Como
# mktemp crea el tmp dir con 700 y los .ado del repo pueden estar en 600,
# sin esta normalización el servidor queda ilegible para Apache (HTTP 403,
# "Server unable to read htaccess file"). Ocurrió en el deploy de v8.0.1.
# El flag --chmod del rsync se conserva como refuerzo para rsync genuino.
chmod 755 "$TMP_DIR"
chmod 644 "$TMP_DIR"/*
log_info "✓ Permisos normalizados en tmp dir (dir 755, archivos 644)"

# ═══ DRY-RUN: salir aquí ═══

if [[ "$DRY_RUN" == "true" ]]; then
    log_step "Dry-run: simulación de rsync"
    rsync -avzn --delete --itemize-changes \
        --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r \
        "$TMP_DIR/" "$SSH_ALIAS:$REMOTE_PATH/"
    log_info ""
    log_info "Dry-run completado. No se tocó el servidor."
    log_info "Para ejecutar el deploy real: $(basename "$0") $VERSION"
    exit 0
fi

# ═══ FASE 3: BACKUP ═══

if [[ "$SKIP_BACKUP" == "false" ]]; then
    log_step "Fase 3: Backup pre-deploy"

    BACKUP_NAME="endpoint-backup-${VERSION}-${TIMESTAMP_FILENAME}.tar.gz"
    BACKUP_REMOTE_DIR="$(dirname "$REMOTE_PATH")"
    BACKUP_REMOTE_PATH="$BACKUP_REMOTE_DIR/$BACKUP_NAME"

    ssh "$SSH_ALIAS" "cd '$REMOTE_PATH' && tar czf '$BACKUP_REMOTE_PATH' . 2>/dev/null"

    BACKUP_SIZE="$(ssh "$SSH_ALIAS" "stat -c%s '$BACKUP_REMOTE_PATH' 2>/dev/null || echo 0")"
    [[ "$BACKUP_SIZE" -lt 100 ]] && abort "Backup remoto vacío o no creado: $BACKUP_REMOTE_PATH"
    log_info "✓ Backup creado: $BACKUP_REMOTE_PATH ($BACKUP_SIZE bytes)"
else
    BACKUP_REMOTE_PATH="-"
    log_warn "--skip-backup activo: no se hizo backup pre-deploy"
fi

# ═══ FASE 4: DEPLOY ═══

log_step "Fase 4: Deploy (rsync)"

if ! rsync -avz --delete \
    --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r \
    "$TMP_DIR/" "$SSH_ALIAS:$REMOTE_PATH/"; then
    log_error "rsync falló. Servidor puede estar en estado intermedio."
    log_error "Revisar log y considerar restaurar desde: $BACKUP_REMOTE_PATH"

    LOG_FILE="$REPO_ROOT/02_governance/deploys/endpoint-stata.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$TIMESTAMP $VERSION $(git rev-parse --short HEAD) $(whoami) PARTIAL $BACKUP_REMOTE_PATH" >> "$LOG_FILE"
    exit 2
fi
log_info "✓ rsync completado"

# ═══ FASE 5: VERIFICACIÓN POST-DEPLOY ═══

log_step "Fase 5: Verificación post-deploy"

sleep 2  # margen para que el endpoint refresque

TOC_REMOTE="$(curl -sf "${ENDPOINT_URL%/}/stata.toc" 2>/dev/null || echo '')"
if [[ -z "$TOC_REMOTE" ]]; then
    log_warn "No se pudo hacer GET a ${ENDPOINT_URL%/}/stata.toc. Posible cache/CDN."
elif echo "$TOC_REMOTE" | grep -q "$VERSION"; then
    log_info "✓ Endpoint sirve stata.toc con versión $VERSION"
else
    log_warn "stata.toc remoto NO contiene versión $VERSION. Posible cache/CDN; verificar manualmente en unos minutos."
fi

REMOTE_COUNT="$(ssh "$SSH_ALIAS" "ls -1 '$REMOTE_PATH' | wc -l" | tr -d ' ')"
EXPECTED_COUNT=$((FILE_COUNT + 1))  # +1 por stata.toc
if [[ "$REMOTE_COUNT" -eq "$EXPECTED_COUNT" ]]; then
    log_info "✓ Conteo de archivos remoto: $REMOTE_COUNT (esperado: $EXPECTED_COUNT)"
else
    log_warn "Conteo remoto ($REMOTE_COUNT) difiere del esperado ($EXPECTED_COUNT)"
fi

# ═══ FASE 6: REGISTRO ═══

log_step "Fase 6: Registro"

LOG_FILE="$REPO_ROOT/02_governance/deploys/endpoint-stata.log"
mkdir -p "$(dirname "$LOG_FILE")"

COMMIT_SHORT="$(git rev-parse --short HEAD)"
OPERATOR="$(whoami)"
RESULT="OK"

echo "$TIMESTAMP $VERSION $COMMIT_SHORT $OPERATOR $RESULT $BACKUP_REMOTE_PATH" >> "$LOG_FILE"
log_info "✓ Registrado en $LOG_FILE"

log_info ""
log_info "Deploy de $VERSION completado exitosamente."
log_info "Endpoint público: ${ENDPOINT_URL%/}/"
log_info "Backup remoto:    $BACKUP_REMOTE_PATH"

exit 0
