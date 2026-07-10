#!/usr/bin/env bash
# =============================================================================
# backup-vps.sh — Backup del VPS de simuladorfiscal.ciep.mx (Fase 4 roadmap)
# =============================================================================
#
# Qué hace: respalda la configuración de Apache del VPS (cada deploy, modo
# default) y, bajo demanda, las llaves SSL cifradas con gpg (modo --llaves,
# manual, ~2 veces al año cuando rotan). Aplica la retención de 90 backups
# con poda automática (D.4).
#
# Diseño registrado en 02_governance/arquitectura-y-bitacoras.md §7.2
# (decisiones D.1-D.8 con el ajuste I.1 del 2026-07-09: las llaves SSL salen
# del ciclo automático porque no cambian entre deploys y su lectura requiere
# sudo — automatizar sudo era superficie innecesaria).
#
# Uso:
#   ./backup-vps.sh              # backup automático: config Apache
#   ./backup-vps.sh --llaves     # adicional manual: llaves SSL cifradas gpg
#                                # (pide password de sudo del VPS y passphrase
#                                # gpg de forma interactiva)
#   ./backup-vps.sh --dry-run    # simula sin escribir nada
#   ./backup-vps.sh --solo-poda  # solo aplica la retención de 90 backups
#                                # (mantenimiento; no contacta al VPS)
#
# Invocado por publicar-vps.sh como Fase 0 (pre-deploy, modo default): si este
# script falla, el deploy aborta — sin backup exitoso no hay deploy.
#
# Credenciales: publicar-vps-credentials.sh (gitignored), junto a este script.
# Requiere la variable BACKUP_ROOT (destino local del backup, típicamente en
# el Dropbox institucional). El path puede contener espacios y "+": todas las
# expansiones van citadas.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Constantes y setup
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDENTIALS_FILE="${SCRIPT_DIR}/publicar-vps-credentials.sh"
LOG_FILE="/tmp/backup-vps-$(date +%Y%m%d-%H%M%S).log"

# Timestamp del backup (estructura D.7: un directorio por corrida)
TS="$(date +%Y-%m-%d-%H%M%S)"

# Glob que identifica los directorios de backup bajo BACKUP_ROOT (solo la
# poda toca lo que embone con este patrón; cualquier otra cosa se respeta)
TS_GLOB='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]'

# Retención (D.4): se conservan los N backups más recientes
RETENTION=90

# Colores solo si stdout es una terminal
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi

# -----------------------------------------------------------------------------
# Helpers de logging (pantalla + archivo de log)
# -----------------------------------------------------------------------------
log()       { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }
log_info()  { log "${BLUE}[INFO]${NC} $*"; }
log_ok()    { log "${GREEN}[OK]${NC}   $*"; }
log_warn()  { log "${YELLOW}[WARN]${NC} $*"; }
log_error() { log "${RED}[ERROR]${NC} $*"; }
die()       { log_error "$*"; exit 1; }

usage() {
    cat <<'EOF'
Uso:
  ./backup-vps.sh [--llaves] [--dry-run] [--solo-poda]

Opciones:
  --llaves     Además de la config Apache, respalda las llaves SSL del VPS
               cifradas con gpg. Requiere teclear interactivamente la password
               de sudo del VPS y la passphrase gpg (entrada "GPG - Backup
               llaves SSL VPS CIEP" en el Firefox de Ricardo). Usar solo
               cuando las llaves rotan (~2 veces/año).
  --dry-run    Simula: muestra qué haría, no escribe nada (ni local ni VPS).
  --solo-poda  Solo aplica la retención de 90 backups bajo BACKUP_ROOT y
               termina. No contacta al VPS. Modo de mantenimiento.
EOF
    exit 1
}

# -----------------------------------------------------------------------------
# Parseo de argumentos
# -----------------------------------------------------------------------------
DRY_RUN=0
LLAVES=0
SOLO_PODA=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --llaves)    LLAVES=1 ;;
        --solo-poda) SOLO_PODA=1 ;;
        --help|-h)   usage ;;
        *)           log_error "Opción desconocida: $arg"; usage ;;
    esac
done

log_info "Log de esta corrida: $LOG_FILE"
[[ $DRY_RUN -eq 1 ]] && log_warn "MODO DRY-RUN: nada se escribirá (ni local ni VPS)."

# -----------------------------------------------------------------------------
# Gate 1 — Credenciales cargadas (mismo gate que publicar-vps.sh)
# -----------------------------------------------------------------------------
if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    die "No existe $CREDENTIALS_FILE.
        Crea el archivo copiando la plantilla y llenando tus valores:
          cp '${SCRIPT_DIR}/publicar-vps-credentials.template.sh' '$CREDENTIALS_FILE'
        El archivo real está gitignored: nunca entra a Git."
fi
# shellcheck source=/dev/null
source "$CREDENTIALS_FILE"

for var in VPS_USER VPS_HOST; do
    [[ -n "${!var:-}" ]] || die "La variable $var no está definida en $CREDENTIALS_FILE."
done

# BACKUP_ROOT es requisito propio de este script (no del deploy): mensaje
# dedicado que explica cómo agregarla.
if [[ -z "${BACKUP_ROOT:-}" ]]; then
    die "La variable BACKUP_ROOT no está definida en $CREDENTIALS_FILE.
        Es el directorio raíz donde se guardan los backups del VPS (Dropbox
        institucional u otro storage local). Agrégala al credentials:
          export BACKUP_ROOT=\"/ruta/a/tu/carpeta/de/backups\"
        (la plantilla publicar-vps-credentials.template.sh trae el ejemplo).
        PRECAUCIÓN: si el path tiene espacios, no quites las comillas."
fi
log_ok "Gate 1: credenciales cargadas ($VPS_USER@$VPS_HOST; destino: $BACKUP_ROOT)."

# -----------------------------------------------------------------------------
# Gate 2 — gpg disponible (solo modo --llaves)
# -----------------------------------------------------------------------------
# Se verifica ANTES de tocar el VPS: en la primera ejecución real (2026-07-09)
# el script asumió gpg instalado y reventó a mitad de la operación con
# "gpg: command not found" — las precondiciones se validan antes de empezar,
# no se descubren a medio camino (bitácora v1.24).
if [[ $LLAVES -eq 1 ]]; then
    if ! command -v gpg >/dev/null 2>&1; then
        die "gpg no está instalado y el modo --llaves lo necesita para cifrar.
        En macOS: brew install gnupg
        Nada se ha tocado (ni local ni VPS)."
    fi
    log_ok "Gate 2: gpg disponible ($(command -v gpg))."
fi

# -----------------------------------------------------------------------------
# Conexión SSH — comparte el ControlPath de publicar-vps.sh
# -----------------------------------------------------------------------------
# Mismo ControlPath que publicar-vps.sh: cuando este script corre como Fase 0
# del deploy, reutiliza la conexión maestra ya autenticada (la password se
# teclea una sola vez). Por lo mismo, este script NO cierra la conexión al
# salir (cerraría la del deploy padre); ControlPersist=10m la expira sola y
# el trap de publicar-vps.sh la cierra al final del deploy.
SSH_CONTROL_PATH="/tmp/publicar-vps-ssh-%C"
SSH_OPTS=(
    -o ConnectTimeout=10
    -o ControlMaster=auto
    -o "ControlPath=$SSH_CONTROL_PATH"
    -o ControlPersist=10m
)
[[ -n "${SSH_KEY_PATH:-}" ]] && SSH_OPTS+=(-i "$SSH_KEY_PATH")

ssh_vps() {
    ssh "${SSH_OPTS[@]}" "${VPS_USER}@${VPS_HOST}" "$@"
}

RSYNC_SSH="ssh $(printf '%q ' "${SSH_OPTS[@]}")"

# Directorio de esta corrida (estructura D.7)
TS_DIR="${BACKUP_ROOT}/${TS}"

# -----------------------------------------------------------------------------
# Poda de retención (D.4): conserva los RETENTION backups más recientes
# -----------------------------------------------------------------------------
# Los nombres de directorio son timestamps de formato controlado (sin espacios
# ni caracteres raros), así que se itera sobre basenames ordenados y se
# reconstruye el path completo SIEMPRE citado — BACKUP_ROOT sí tiene espacios.
prune_backups() {
    local -a names=()
    local name
    while IFS= read -r name; do
        [[ -n "$name" ]] && names+=("$name")
    done < <(find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -name "$TS_GLOB" -exec basename {} \; | sort)

    local total=${#names[@]}
    local excess=$(( total - RETENTION ))
    if (( excess <= 0 )); then
        log_info "Poda: $total backups (límite $RETENTION), nada que podar."
        BACKUPS_AFTER_PRUNE=$total
        return 0
    fi

    log_info "Poda: $total backups, se eliminan los $excess más viejos (límite $RETENTION)."
    local i
    for (( i = 0; i < excess; i++ )); do
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[dry-run] Se eliminaría: ${BACKUP_ROOT}/${names[$i]}"
        else
            rm -rf "${BACKUP_ROOT}/${names[$i]}"
            log_info "Eliminado: ${names[$i]}"
        fi
    done
    if [[ $DRY_RUN -eq 1 ]]; then
        BACKUPS_AFTER_PRUNE=$total
    else
        BACKUPS_AFTER_PRUNE=$RETENTION
    fi
}
BACKUPS_AFTER_PRUNE=0

# Modo --solo-poda: aplica retención y termina (no contacta al VPS)
if [[ $SOLO_PODA -eq 1 ]]; then
    [[ -d "$BACKUP_ROOT" ]] || die "No existe BACKUP_ROOT: $BACKUP_ROOT"
    prune_backups
    log_ok "Poda completada. Backups existentes: $BACKUPS_AFTER_PRUNE."
    exit 0
fi

# =============================================================================
# PASO 1 — Directorio del backup con timestamp (D.7)
# =============================================================================
if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Se crearía: $TS_DIR/"
else
    mkdir -p "${TS_DIR}"
    log_ok "Directorio del backup: $TS_DIR/"
fi

# =============================================================================
# PASO 2 — Config Apache (modo default, corre siempre)
# =============================================================================
log_info "Paso 2: backup de la config Apache (/etc/apache2/sites-available/)."

# Se traen los *.conf y también los *.backup-pre-cutover-* (son parte de la
# historia de la config: ver §7.3 de arquitectura-y-bitacoras.md). El pull es
# legible sin sudo (los .conf son world-readable).
RSYNC_APACHE_OPTS=(
    -az
    --include='*.conf'
    --include='*.backup-pre-cutover-*'
    --exclude='*'
)

if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Se ejecutaría:"
    log_info "  rsync ${RSYNC_APACHE_OPTS[*]} ${VPS_USER}@${VPS_HOST}:/etc/apache2/sites-available/ '${TS_DIR}/apache-config/'"
else
    mkdir -p "${TS_DIR}/apache-config"
    if ! rsync "${RSYNC_APACHE_OPTS[@]}" -e "$RSYNC_SSH" \
        "${VPS_USER}@${VPS_HOST}:/etc/apache2/sites-available/" \
        "${TS_DIR}/apache-config/" 2>&1 | tee -a "$LOG_FILE"; then
        die "Paso 2: el rsync de la config Apache falló. Sin backup no hay deploy."
    fi

    # Verificación: al menos 1 .conf con tamaño > 0
    CONF_COUNT=$(find "${TS_DIR}/apache-config" -type f -name '*.conf' -size +0c | wc -l | tr -d ' ')
    if [[ "$CONF_COUNT" -lt 1 ]]; then
        die "Paso 2: no se descargó ningún .conf con contenido a ${TS_DIR}/apache-config/.
        El backup NO es válido. Revisa la conexión y el contenido de
        /etc/apache2/sites-available/ en el VPS."
    fi
    log_ok "Paso 2: $CONF_COUNT archivos .conf respaldados en ${TS_DIR}/apache-config/."
fi

# =============================================================================
# PASO 3 — Llaves SSL cifradas (solo con --llaves; manual, ~2 veces/año)
# =============================================================================
if [[ $LLAVES -eq 1 ]]; then
    log_info "Paso 3: backup de llaves SSL (modo --llaves)."
    log_warn "Este paso requiere teclear la password de sudo del VPS y después"
    log_warn "la passphrase gpg (entrada 'GPG - Backup llaves SSL VPS CIEP' en Firefox)."

    REMOTE_TAR="/tmp/ssl-backup-${TS}.tar.gz"
    LOCAL_TAR="/tmp/ssl-backup-${TS}.tar.gz"
    GPG_OUT="${TS_DIR}/llaves-cifradas/ssl-${TS}.tar.gz.gpg"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[dry-run] Se ejecutaría:"
        log_info "  ssh -t ${VPS_USER}@${VPS_HOST} \"sudo tar czf '$REMOTE_TAR' -C /etc/ssl/private . && sudo chown ${VPS_USER} '$REMOTE_TAR'\""
        log_info "  rsync ${VPS_USER}@${VPS_HOST}:$REMOTE_TAR '$LOCAL_TAR'"
        log_info "  gpg --symmetric --cipher-algo AES256 --output '$GPG_OUT' '$LOCAL_TAR'"
        log_info "  rm -f '$LOCAL_TAR' ; ssh ${VPS_USER}@${VPS_HOST} \"rm -f '$REMOTE_TAR'\""
    else
        # Empaquetar en el VPS con sudo interactivo (-t asigna terminal).
        # Con ssh -t el exit code que llega es el del comando remoto: si sudo
        # falla (3 intentos de password devuelven 1), el tar NUNCA se creó y
        # hay que abortar AQUÍ — no seguir al cifrado (bug del 2026-07-09).
        if ! ssh -t "${SSH_OPTS[@]}" "${VPS_USER}@${VPS_HOST}" \
            "sudo tar czf '$REMOTE_TAR' -C /etc/ssl/private . && sudo chown ${VPS_USER} '$REMOTE_TAR'"; then
            die "Paso 3: el empaquetado remoto falló — probablemente password de
        sudo incorrecta. No se creó ningún tar, no hay nada que limpiar.
        Vuelve a correr ./backup-vps.sh --llaves cuando tengas la password."
        fi

        # Descargar el tar (aún sin cifrar) a local
        rsync -az -e "$RSYNC_SSH" \
            "${VPS_USER}@${VPS_HOST}:$REMOTE_TAR" "$LOCAL_TAR" 2>&1 | tee -a "$LOG_FILE" \
            || die "Paso 3: la descarga del tar de llaves falló."

        # Cifrar con gpg simétrico (passphrase interactiva, D.6). Si falla,
        # el mensaje de limpieza solo menciona tars que EXISTEN de verdad
        # (en el intento fallido del 2026-07-09 el mensaje genérico instruyó
        # borrar tars que nunca se crearon).
        mkdir -p "${TS_DIR}/llaves-cifradas"
        if ! gpg --symmetric --cipher-algo AES256 --output "$GPG_OUT" "$LOCAL_TAR"; then
            log_error "Paso 3: el cifrado gpg falló."
            if [[ -e "$LOCAL_TAR" ]]; then
                log_error "Queda un tar SIN cifrar en local: $LOCAL_TAR — bórralo manualmente."
            fi
            if ssh_vps "test -e '$REMOTE_TAR'" 2>/dev/null; then
                log_error "Queda un tar SIN cifrar en el VPS: $REMOTE_TAR — bórralo por SSH."
            fi
            exit 1
        fi

        # Borrar los tar SIN cifrar en ambos lados
        rm -f "$LOCAL_TAR"
        ssh_vps "rm -f '$REMOTE_TAR'"

        # Verificar que no quedó copia plana en ningún lado
        if [[ -e "$LOCAL_TAR" ]]; then
            die "Paso 3: quedó una copia SIN cifrar en local: $LOCAL_TAR. Bórrala manualmente."
        fi
        if ssh_vps "ls '$REMOTE_TAR'" >/dev/null 2>&1; then
            die "Paso 3: quedó una copia SIN cifrar en el VPS: $REMOTE_TAR. Bórrala manualmente."
        fi

        # Verificar el resultado cifrado
        [[ -s "$GPG_OUT" ]] || die "Paso 3: el archivo cifrado no existe o está vacío: $GPG_OUT"
        log_ok "Paso 3: llaves SSL cifradas en $GPG_OUT (sin copias planas en ningún lado)."
    fi
fi

# =============================================================================
# PASO 4 — Poda de retención (D.4)
# =============================================================================
if [[ -d "$BACKUP_ROOT" ]]; then
    prune_backups
else
    # En dry-run BACKUP_ROOT puede no existir todavía (nada se creó)
    log_warn "Poda: BACKUP_ROOT no existe aún ($BACKUP_ROOT); nada que podar."
fi

# =============================================================================
# PASO 5 — Resumen
# =============================================================================
log ""
log_ok "=============================================="
log_ok " Backup completado$( [[ $DRY_RUN -eq 1 ]] && echo ' (DRY-RUN: nada se escribió)' )"
log_ok "=============================================="
log_ok " Config Apache:      ${TS_DIR}/apache-config/"
if [[ $LLAVES -eq 1 ]]; then
    log_ok " Llaves SSL (gpg):   ${TS_DIR}/llaves-cifradas/"
else
    log_ok " Llaves SSL:         no incluidas (usa --llaves cuando roten)"
fi
log_ok " Backups existentes: ${BACKUPS_AFTER_PRUNE} (retención: ${RETENTION})"
log_ok " Log de la corrida:  $LOG_FILE"
exit 0
