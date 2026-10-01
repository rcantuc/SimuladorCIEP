#!/usr/bin/env bash
# =============================================================================
# publicar-anteriores.sh — Publica el museo de versiones del Simulador Fiscal
# CIEP (04_3_anteriores/) a https://simuladorfiscal.ciep.mx/anteriores/
# =============================================================================
#
# El museo es un CUARTO canal, con ciclo de vida propio (decisión 2026-10-01,
# bitácora v1.57): Apache lo sirve con `Alias /anteriores /var/www/anteriores`
# (estático puro, PHP deshabilitado), FUERA del deployment `current`. Por eso
# no viaja en publicar-vps.sh: cambiar una pieza de museo no es un release del
# motor, y un release del motor no toca el museo.
#
# Fases:
#   Gate 1  credenciales (publicar-vps-credentials.sh, las mismas del VPS)
#   Gate 2  auditoría estática: 0 recursos rotos y 0 hosts de desarrollo
#           (05_scripts/verify_anteriores.py)
#   Gate 3  el destino existe y ciepmx puede escribir (una vez, Ricardo:
#           sudo chown -R ciepmx:web /var/www/anteriores)
#   Fase 1  rsync --delete de 04_3_anteriores/ → /var/www/anteriores/
#   Fase 2  permisos legibles para Apache (dir 755, archivos 644)
#   Fase 3  verificación HTTP: index y las 4 portadas responden 200
#
# Uso: publicar-anteriores.sh [--dry-run] [--skip-audit]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CREDENTIALS_FILE="$SCRIPT_DIR/publicar-vps-credentials.sh"
LOCAL_DIR="$REPO_ROOT/04_3_anteriores"
REMOTE_DIR="/var/www/anteriores"
URL="https://simuladorfiscal.ciep.mx/anteriores"
LOG_FILE="/tmp/publicar-anteriores-$(date +%Y%m%d-%H%M%S).log"

DRY_RUN=0; SKIP_AUDIT=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=1 ;;
        --skip-audit) SKIP_AUDIT=1 ;;
        -h|--help)    sed -n '2,24p' "$0"; exit 0 ;;
        *) echo "Argumento desconocido: $arg" >&2; exit 2 ;;
    esac
done

if [[ -t 1 ]]; then G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; else G=''; Y=''; R=''; N=''; fi
log_info() { printf "${G}[INFO]${N} %s\n" "$*" | tee -a "$LOG_FILE"; }
log_ok()   { printf "${G}[OK]${N}   %s\n" "$*" | tee -a "$LOG_FILE"; }
log_warn() { printf "${Y}[WARN]${N} %s\n" "$*" | tee -a "$LOG_FILE" >&2; }
die()      { printf "${R}[ERROR]${N} %s\n" "$*" | tee -a "$LOG_FILE" >&2; exit 1; }

log_info "Log de esta corrida: $LOG_FILE"
[[ $DRY_RUN -eq 1 ]] && log_warn "MODO DRY-RUN: ningún cambio se aplicará al VPS."

# ─── Gate 1: credenciales ───
[[ -f "$CREDENTIALS_FILE" ]] || die "No existe $CREDENTIALS_FILE (plantilla: publicar-vps-credentials.template.sh)."
# shellcheck source=/dev/null
source "$CREDENTIALS_FILE"
for var in VPS_USER VPS_HOST; do [[ -n "${!var:-}" ]] || die "La variable $var no está definida en $CREDENTIALS_FILE."; done
log_ok "Gate 1: credenciales cargadas ($VPS_USER@$VPS_HOST)."

SSH_OPTS=(-o ConnectTimeout=10 -o BatchMode=yes)
ssh_vps() { ssh "${SSH_OPTS[@]}" "${VPS_USER}@${VPS_HOST}" "$@"; }

# ─── Gate 2: auditoría estática ───
[[ -d "$LOCAL_DIR" && -f "$LOCAL_DIR/index.html" ]] || die "No existe $LOCAL_DIR/index.html."
if [[ $SKIP_AUDIT -eq 0 ]]; then
    if python3 "$SCRIPT_DIR/verify_anteriores.py" | tee -a "$LOG_FILE" | tail -n 1 | grep -q "TOTAL fallas: 0"; then
        log_ok "Gate 2: auditoría estática sin fallas (recursos locales completos, sin hosts de desarrollo)."
    else
        die "Gate 2: la auditoría estática reporta fallas. Corrige o usa --skip-audit (solo para piezas declaradas incompletas a sabiendas)."
    fi
else
    log_warn "Gate 2 omitido (--skip-audit)."
fi

# ─── Gate 3: destino escribible ───
if ! ssh_vps "test -d '$REMOTE_DIR' && test -w '$REMOTE_DIR'"; then
    die "Gate 3: $REMOTE_DIR no existe o $VPS_USER no puede escribir. Una vez, en el VPS (requiere sudo):
        sudo chown -R ${VPS_USER}:web '$REMOTE_DIR' && sudo chmod -R u+rwX,go+rX '$REMOTE_DIR'"
fi
log_ok "Gate 3: $REMOTE_DIR existe y es escribible por $VPS_USER."

# ─── Fase 1: rsync ───
log_info "Fase 1: rsync de $LOCAL_DIR/ → $REMOTE_DIR/"
RSYNC_OPTS=(-az --delete --itemize-changes --exclude='.DS_Store' --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r)
[[ $DRY_RUN -eq 1 ]] && RSYNC_OPTS+=(--dry-run)
_n="$(rsync "${RSYNC_OPTS[@]}" -e "ssh ${SSH_OPTS[*]}" "$LOCAL_DIR/" "${VPS_USER}@${VPS_HOST}:$REMOTE_DIR/" | tee -a "$LOG_FILE" | grep -c '^[<>c]' || true)"
log_ok "Fase 1: rsync completado ($_n archivo(s) transferido(s)$( [[ $DRY_RUN -eq 1 ]] && echo ', simulado' ))."

# ─── Fase 2: permisos (openrsync de macOS ignora --chmod; ver publicar-vps.sh) ───
if [[ $DRY_RUN -eq 0 ]]; then
    ssh_vps "find '$REMOTE_DIR' -user '$VPS_USER' -type d -exec chmod 755 {} + ; find '$REMOTE_DIR' -user '$VPS_USER' -type f -exec chmod 644 {} +"
    log_ok "Fase 2: permisos normalizados (dir 755, archivos 644)."
fi

# ─── Fase 3: verificación HTTP ───
if [[ $DRY_RUN -eq 0 ]]; then
    fallas=0
    for p in "" "v1/index.php.html" "v2/index.php.html" "v3/index.php.html" "v4/index.php.html"; do
        code="$(curl -s -o /dev/null -w '%{http_code}' "$URL/$p")"
        if [[ "$code" == "200" ]]; then log_ok "Fase 3: $URL/$p → 200"; else log_warn "Fase 3: $URL/$p → $code"; fallas=$((fallas+1)); fi
    done
    (( fallas == 0 )) || die "Fase 3: $fallas URL(s) no responden 200."
fi

log_ok "Museo publicado: $URL/"
