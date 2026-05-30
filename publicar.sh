#!/usr/bin/env bash
# publicar.sh — Wrapper de publicación del Simulador Fiscal CIEP
#
# Orquesta los dos canales de publicación del simulador:
#   - "internos": copia a Carpeta del Simulador para investigadores (Dropbox)
#   - "release":  deploy al endpoint público https://ciep.mx/simuladorfiscal/
#   - "todo":     ambos en orden (internos primero, después release)
#
# Crea el tag annotated automáticamente si no existe (interactivo o por flag).

set -euo pipefail

# ═══ CONFIGURACIÓN ═══

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TIMESTAMP_FILENAME="$(date -u +%Y%m%d-%H%M%S)"

SUBCOMMAND=""
VERSION=""
TAG_MESSAGE=""
SKIP_BACKUP=false
ENDPOINT_DRY_RUN=false
FORCE=false

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

# stat portable entre macOS (-f%z) y Linux (-c%s)
file_size() {
    local file="$1"
    stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || wc -c < "$file"
}

# ═══ USAGE ═══

usage() {
    cat <<EOF
Uso: $(basename "$0") [opciones] <sub-comando> <version>

Sub-comandos:
  release    Crea tag → push → deploy al endpoint público
  internos   Crea tag → push → backup + rsync a Carpeta para investigadores
  todo       Crea tag → push → internos + release (en ese orden)

Opciones:
  --tag-message=MSG     Mensaje del tag inline (evita abrir editor)
  --skip-backup         Sin backup pre-rsync (solo internos/todo)
  --endpoint-dry-run    Dry-run del endpoint (solo release/todo)
  --force               Permite republish de versión existente
  -h, --help            Ayuda

Argumento:
  <version>             Etiqueta de versión (ej. v8.1, v9.0)

Ejemplos:
  $(basename "$0") release v8.1
  $(basename "$0") internos v8.1 --tag-message="Fix bug en LIF"
  $(basename "$0") todo v8.2

Configuración: requiere endpoint-credentials.sh con SSH_ALIAS, REMOTE_PATH,
ENDPOINT_URL y CARPETA_INVESTIGADORES_PATH definidos.
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

do_release() {
    local version="$1"
    log_step "Sub-comando: release"

    ensure_tag_exists "$version"
    ensure_tag_pushed "$version"

    log_info "Invocando publicar-endpoint.sh..."
    local endpoint_args=()
    [[ "$ENDPOINT_DRY_RUN" == "true" ]] && endpoint_args+=("--dry-run")
    [[ "$FORCE" == "true" ]] && endpoint_args+=("--force")
    endpoint_args+=("$version")

    "$REPO_ROOT/publicar-endpoint.sh" "${endpoint_args[@]}"
}

do_internos() {
    local version="$1"
    log_step "Sub-comando: internos"

    if [[ ! -f endpoint-credentials.sh ]]; then
        abort "endpoint-credentials.sh no existe. Copia endpoint-credentials.template.sh y rellena."
    fi
    # shellcheck source=/dev/null
    source ./endpoint-credentials.sh

    # Resolución de CARPETA_INVESTIGADORES_PATH (prioridad descendente):
    # 1. Si está definida en endpoint-credentials.sh → usar ese override.
    # 2. Si no → buscar automáticamente Dropbox-CIEP/SimuladorCIEP dentro de $HOME.
    # El sufijo "Dropbox-CIEP/SimuladorCIEP" es estable; lo que varía entre
    # usuarios/sistemas es el path raíz (Mac usa Library/CloudStorage/, Linux usa
    # directamente $HOME/, etc.). El find con maxdepth 6 cubre los casos típicos.
    if [[ -z "${CARPETA_INVESTIGADORES_PATH:-}" ]]; then
        log_info "CARPETA_INVESTIGADORES_PATH no definida, buscando automáticamente..."
        CARPETA_INVESTIGADORES_PATH="$(find "$HOME" -maxdepth 6 -type d -path '*/Dropbox-CIEP/SimuladorCIEP' 2>/dev/null | head -1)"

        if [[ -z "$CARPETA_INVESTIGADORES_PATH" ]]; then
            abort "No se encontró Dropbox-CIEP/SimuladorCIEP en \$HOME. Define CARPETA_INVESTIGADORES_PATH en endpoint-credentials.sh, o asegúrate que Dropbox-CIEP esté sincronizado en tu máquina."
        fi

        log_info "✓ Auto-detectado: $CARPETA_INVESTIGADORES_PATH"
    else
        log_info "✓ Override desde endpoint-credentials.sh: $CARPETA_INVESTIGADORES_PATH"
    fi

    [[ ! -d "$CARPETA_INVESTIGADORES_PATH" ]] && abort "La Carpeta no existe: $CARPETA_INVESTIGADORES_PATH"

    log_info "Carpeta destino: $CARPETA_INVESTIGADORES_PATH"

    ensure_tag_exists "$version"
    ensure_tag_pushed "$version"

    # Backup pre-rsync
    local backup_path="-"
    if [[ "$SKIP_BACKUP" == "false" ]]; then
        log_info "Creando backup pre-rsync..."
        local backups_dir="$CARPETA_INVESTIGADORES_PATH/_backups"
        mkdir -p "$backups_dir"

        local backup_name="carpeta-backup-${version}-${TIMESTAMP_FILENAME}.tar.gz"
        backup_path="$backups_dir/$backup_name"

        # Crear tar en tmp primero (evita problema de "tar dentro de su CWD"), después mover
        local tmp_backup
        tmp_backup="$(mktemp).tar.gz"

        (cd "$CARPETA_INVESTIGADORES_PATH" && tar czf "$tmp_backup" --exclude='./_backups' . 2>/dev/null)

        mv "$tmp_backup" "$backup_path"

        local backup_size
        backup_size="$(file_size "$backup_path")"
        log_info "✓ Backup creado: $backup_name ($backup_size bytes)"

        # Rotación: mantener últimos 5 backups
        local backups_count
        backups_count="$(ls -1 "$backups_dir"/carpeta-backup-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "$backups_count" -gt 5 ]]; then
            log_info "Rotando backups antiguos (manteniendo últimos 5)..."
            ls -1t "$backups_dir"/carpeta-backup-*.tar.gz | tail -n +6 | xargs rm -f
            log_info "✓ Rotación completada"
        fi
    else
        log_warn "--skip-backup activo: no se hizo backup pre-rsync"
    fi

    # Rsync con exclude list completa
    log_info "Sincronizando repo → Carpeta..."
    rsync -a --delete \
        --exclude='.git/' \
        --exclude='.gitignore' \
        --exclude='.gitattributes' \
        --exclude='.mailmap' \
        --exclude='.windsurf/' \
        --exclude='.windsurfrules' \
        --exclude='.DS_Store' \
        --exclude='governance/' \
        --include='raw/' \
        --include='raw/manifest.json' \
        --exclude='raw/*' \
        --exclude='Stata net/' \
        --exclude='manifest-endpoint.toml' \
        --exclude='publicar.sh' \
        --exclude='publicar-endpoint.sh' \
        --exclude='endpoint-credentials.sh' \
        --exclude='endpoint-credentials.template.sh' \
        --exclude='set_token.template.do' \
        --exclude='*.tar.gz' \
        --exclude='endpoint-backup-*' \
        --exclude='carpeta-backup-*' \
        --exclude='_backups/' \
        "$REPO_ROOT/" "$CARPETA_INVESTIGADORES_PATH/"

    log_info "✓ Rsync completado"

    # Registrar en log institucional
    local log_file="$REPO_ROOT/governance/deploys/carpeta-investigadores.log"
    mkdir -p "$(dirname "$log_file")"

    local commit_short operator
    commit_short="$(git rev-parse --short HEAD)"
    operator="$(whoami)"

    echo "$TIMESTAMP $version $commit_short $operator OK $backup_path" >> "$log_file"
    log_info "✓ Registrado en governance/deploys/carpeta-investigadores.log"

    log_info ""
    log_info "Sincronización de Carpeta completada exitosamente."
    log_info "Carpeta: $CARPETA_INVESTIGADORES_PATH"
    [[ "$backup_path" != "-" ]] && log_info "Backup:  $backup_path"
}

do_todo() {
    local version="$1"
    log_step "Sub-comando: todo (internos → release)"
    do_internos "$version"
    do_release "$version"
}

# ═══ PARSING DE ARGUMENTOS ═══

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag-message=*)        TAG_MESSAGE="${1#*=}"; shift ;;
        --skip-backup)          SKIP_BACKUP=true; shift ;;
        --endpoint-dry-run)     ENDPOINT_DRY_RUN=true; shift ;;
        --force)                FORCE=true; shift ;;
        -h|--help)              usage; exit 0 ;;
        release|internos|todo)  SUBCOMMAND="$1"; shift ;;
        v*)                     VERSION="$1"; shift ;;
        *)                      log_error "Argumento desconocido: $1"; usage; exit 1 ;;
    esac
done

[[ -z "$SUBCOMMAND" ]] && { log_error "Falta sub-comando (release|internos|todo)"; usage; exit 1; }
[[ -z "$VERSION" ]] && { log_error "Falta <version>"; usage; exit 1; }
[[ -z "$REPO_ROOT" ]] && abort "No se pudo detectar root del repo Git."

cd "$REPO_ROOT"

# ═══ FLUJO COMÚN A TODOS LOS SUB-COMANDOS ═══

log_info "publicar.sh — sub-comando: $SUBCOMMAND, versión: $VERSION"

verify_repo_state

# ═══ EJECUCIÓN ═══

case "$SUBCOMMAND" in
    release)   do_release "$VERSION" ;;
    internos)  do_internos "$VERSION" ;;
    todo)      do_todo "$VERSION" ;;
esac

log_info ""
log_info "publicar.sh: sub-comando '$SUBCOMMAND' completado para $VERSION"

exit 0
