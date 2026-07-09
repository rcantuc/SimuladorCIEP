#!/usr/bin/env bash
# =============================================================================
# publicar-vps.sh — Pipeline de deployment al VPS de simuladorfiscal.ciep.mx
# =============================================================================
#
# Qué hace: propaga el código local (PHP del sitio + motor Stata + .dta
# procesados) al VPS IONOS, hace cutover atómico vía symlink `current`,
# verifica el sitio con un health check y hace rollback automático si falla.
#
# Diseño registrado en 02_governance/arquitectura-y-bitacoras.md §7.1-§7.2
# (decisiones D.1-D.9, bitácoras v1.20-v1.21). Estructura del VPS documentada
# en 02_governance/reconocimiento-vps.md.
#
# Uso:
#   ./publicar-vps.sh <version-deployment> [--dry-run] [--force] [--skip-health]
#
# Ejemplos:
#   ./publicar-vps.sh v8.0            # deploy real, con confirmación
#   ./publicar-vps.sh v8.0 --dry-run  # simula: muestra qué haría, no cambia nada
#   ./publicar-vps.sh v8.1 --force    # deploy real sin pausa de confirmación
#
# La versión es de DEPLOYMENT (v8.0, v8.1), no de código (v8.0.6 se rechaza).
# Un deployment agrupa múltiples releases del código; el commit exacto queda
# registrado en el archivo DEPLOYED_COMMIT que este script escribe en el VPS.
#
# Precondición de infraestructura (el operador la crea UNA vez por versión,
# respetando la convención asimétrica de paths: sitio CON "v", canon SIN "v"):
#   sudo mkdir /var/www/html/vN.M /SIM/OUT/N.M
#   sudo chown ciepmx:ciepmx /var/www/html/vN.M /SIM/OUT/N.M
#
# Credenciales: viven en publicar-vps-credentials.sh (gitignored), junto a
# este script. Plantilla: publicar-vps-credentials.template.sh.
# =============================================================================

set -euo pipefail

# =============================================================================
# CONVENCIÓN INSTITUCIONAL DE PATHS EN EL VPS
# =============================================================================
# El VPS de IONOS tiene inconsistencia histórica preservada por decisión firme
# del investigador principal el 2026-07-10:
#   - /var/www/html/ usa nombres CON "v" (v6/, v7/, v8.0/, ...)
#   - /SIM/OUT/ usa nombres SIN "v" (7/, 8.0/, ...)
#
# Este script traduce el argumento del usuario (vN.M) a los 2 formatos:
#   VPS_HTML_VERSION="${VERSION_ARG}"      # v8.0 (para el sitio)
#   VPS_SIM_VERSION="${VERSION_ARG#v}"     # 8.0 (para el canon)
# =============================================================================

# -----------------------------------------------------------------------------
# Constantes y setup
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDENTIALS_FILE="${SCRIPT_DIR}/publicar-vps-credentials.sh"
LOG_FILE="/tmp/publicar-vps-$(date +%Y%m%d-%H%M%S).log"

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
  ./publicar-vps.sh <version-deployment> [--dry-run] [--force] [--skip-health]

Argumentos:
  <version-deployment>  Requerido. Formato vN.M (semver de deployment: v8.0,
                        v8.1). NO es la versión de código (v8.0.6 se rechaza).

Opciones:
  --dry-run             Simula todo sin ejecutar cambios. Los rsync corren con
                        su propio --dry-run (muestran qué transferirían); el
                        swap del symlink y el health check solo se imprimen.
  --force               Salta la confirmación interactiva antes del swap del
                        symlink.
  --skip-health         Salta la verificación post-deploy (el rollback
                        automático también se salta). Solo para debugging,
                        NUNCA en producción real.
EOF
    exit 1
}

# -----------------------------------------------------------------------------
# Parseo de argumentos
# -----------------------------------------------------------------------------
VERSION_ARG=""
DRY_RUN=0
FORCE=0
SKIP_HEALTH=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=1 ;;
        --force)       FORCE=1 ;;
        --skip-health) SKIP_HEALTH=1 ;;
        --help|-h)     usage ;;
        -*)            log_error "Opción desconocida: $arg"; usage ;;
        *)
            if [[ -n "$VERSION_ARG" ]]; then
                log_error "Solo se acepta un argumento de versión (recibido: '$VERSION_ARG' y '$arg')."
                usage
            fi
            VERSION_ARG="$arg"
            ;;
    esac
done

[[ -n "$VERSION_ARG" ]] || usage

# Gate 3 (adelantado al parseo) — Formato de versión válido: vN.M exactamente.
# Se valida antes que las credenciales para que el error de formato sea
# siempre el primero que ve el operador (no depende del entorno).
if [[ ! "$VERSION_ARG" =~ ^v[0-9]+\.[0-9]+$ ]]; then
    die "Versión inválida: '$VERSION_ARG'. El formato es vN.M (ej. v8.0, v8.1).
        Recuerda: es la versión de DEPLOYMENT, no la del código.
        v8.0.6 es versión de código; el deployment que la sirve es v8.0."
fi

# Traducción a los 2 formatos de la convención asimétrica del VPS (ver bloque
# de comentario al inicio del script): sitio CON "v", canon Stata SIN "v".
VPS_HTML_VERSION="${VERSION_ARG}"      # v8.0 -> /var/www/html/v8.0/
VPS_SIM_VERSION="${VERSION_ARG#v}"     # 8.0  -> /SIM/OUT/8.0/

log_info "Log de esta corrida: $LOG_FILE"
log_info "Deployment solicitado: $VERSION_ARG (motor Stata: $VPS_SIM_VERSION)"
[[ $DRY_RUN -eq 1 ]] && log_warn "MODO DRY-RUN: ningún cambio se aplicará al VPS."

# -----------------------------------------------------------------------------
# Gate 1 — Credenciales cargadas
# -----------------------------------------------------------------------------
if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    die "No existe $CREDENTIALS_FILE.
        Crea el archivo copiando la plantilla y llenando tus valores:
          cp '${SCRIPT_DIR}/publicar-vps-credentials.template.sh' '$CREDENTIALS_FILE'
        El archivo real está gitignored: nunca entra a Git."
fi
# shellcheck source=/dev/null
source "$CREDENTIALS_FILE"

for var in VPS_USER VPS_HOST VPS_HTML_ROOT VPS_SIM_ROOT VPS_HEALTH_URL LOCAL_SITE_ROOT LOCAL_REPO_ROOT; do
    [[ -n "${!var:-}" ]] || die "La variable $var no está definida en $CREDENTIALS_FILE."
done
log_ok "Gate 1: credenciales cargadas ($VPS_USER@$VPS_HOST)."

# Opciones SSH compartidas por TODAS las conexiones (ssh y rsync).
# ControlMaster reusa una sola conexión autenticada: si la autenticación es
# por password, se teclea una vez y las demás llamadas la reutilizan.
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

# rsync usando las mismas opciones SSH (misma conexión maestra)
RSYNC_SSH="ssh $(printf '%q ' "${SSH_OPTS[@]}")"

cleanup() {
    # Cierra la conexión SSH maestra si quedó abierta
    ssh -O exit -o "ControlPath=$SSH_CONTROL_PATH" "${VPS_USER}@${VPS_HOST}" 2>/dev/null || true
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Gate 2 — Working tree limpio
# -----------------------------------------------------------------------------
if ! git -C "$LOCAL_REPO_ROOT" diff --quiet || ! git -C "$LOCAL_REPO_ROOT" diff --cached --quiet; then
    die "El working tree del repo tiene cambios sin commit.
        No se despliega código no versionado: commitea o descarta los cambios
        y vuelve a correr el script.
        Revisa con: git -C '$LOCAL_REPO_ROOT' status"
fi
log_ok "Gate 2: working tree limpio."

# -----------------------------------------------------------------------------
# Gate 5 — Fuente local existe (antes que el gate remoto: falla rápido y barato)
# -----------------------------------------------------------------------------
[[ -d "$LOCAL_SITE_ROOT" ]]         || die "No existe LOCAL_SITE_ROOT: $LOCAL_SITE_ROOT"
[[ -d "$LOCAL_REPO_ROOT" ]]         || die "No existe LOCAL_REPO_ROOT: $LOCAL_REPO_ROOT"
[[ -d "$LOCAL_REPO_ROOT/master" ]]  || die "No existe $LOCAL_REPO_ROOT/master (los .dta procesados). ¿Corriste el pipeline local?"
[[ -f "$LOCAL_SITE_ROOT/health.php" ]] || die "No existe $LOCAL_SITE_ROOT/health.php. El health check post-deploy depende de él."
log_ok "Gate 5: fuentes locales verificadas."

# -----------------------------------------------------------------------------
# Gate 4 — Estructura VPS existe
# -----------------------------------------------------------------------------
# En dry-run la verificación remota se intenta igual (es de solo lectura),
# pero si el VPS no es alcanzable se degrada a warning para poder simular
# el resto del pipeline sin red.
check_vps_structure() {
    ssh_vps "test -d '$VPS_HTML_ROOT/$VPS_HTML_VERSION' && test -d '$VPS_SIM_ROOT/$VPS_SIM_VERSION'"
}
if check_vps_structure; then
    log_ok "Gate 4: estructura del VPS verificada ($VPS_HTML_ROOT/$VPS_HTML_VERSION y $VPS_SIM_ROOT/$VPS_SIM_VERSION)."
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "Gate 4: no se pudo verificar la estructura del VPS (¿sin red o no existe aún?). Dry-run continúa."
    else
        die "Estructura VPS faltante (o el VPS no responde). Ejecuta en el VPS:
          sudo mkdir '$VPS_HTML_ROOT/$VPS_HTML_VERSION'
          sudo mkdir '$VPS_SIM_ROOT/$VPS_SIM_VERSION'
          sudo chown ${VPS_USER}:${VPS_USER} '$VPS_HTML_ROOT/$VPS_HTML_VERSION' '$VPS_SIM_ROOT/$VPS_SIM_VERSION'
        y vuelve a correr el script.
        Ojo con la convención asimétrica: sitio CON 'v' ($VPS_HTML_VERSION), canon SIN 'v' ($VPS_SIM_VERSION)."
    fi
fi

# =============================================================================
# FASE 1 — Snapshot pre-deploy
# =============================================================================
log_info "Fase 1: snapshot pre-deploy."

CURRENT_COMMIT=$(git -C "$LOCAL_REPO_ROOT" rev-parse HEAD)
CURRENT_COMMIT_SHORT=$(git -C "$LOCAL_REPO_ROOT" rev-parse --short HEAD)
log_info "Commit local a desplegar: $CURRENT_COMMIT_SHORT ($CURRENT_COMMIT)"

# Deployment previo = destino actual del symlink `current` en el VPS.
# En el PRIMER deploy el symlink no existe todavía: no habrá rollback posible
# y el vhost de Apache seguirá sirviendo la versión vieja hasta que apunte
# a `current` (cutover del vhost: tarea manual documentada, Fase 5 del roadmap).
PREVIOUS_DEPLOYMENT=""
if PREVIOUS_DEPLOYMENT=$(ssh_vps "readlink '$VPS_HTML_ROOT/current'" 2>/dev/null); then
    PREVIOUS_DEPLOYMENT="$(basename "$PREVIOUS_DEPLOYMENT")"
    log_info "Deployment previo (destino de rollback): $PREVIOUS_DEPLOYMENT"
else
    PREVIOUS_DEPLOYMENT=""
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "No se pudo leer el symlink current (¿sin red o primer deploy?). Dry-run continúa."
    else
        log_warn "No existe symlink current en el VPS: este es el PRIMER deploy."
        log_warn "No habrá rollback automático posible (no hay deployment previo)."
        log_warn "Recuerda: el sitio público NO cambia hasta que el vhost de Apache apunte a $VPS_HTML_ROOT/current."
    fi
fi
PREVIOUS_SIM="${PREVIOUS_DEPLOYMENT#v}"

# =============================================================================
# FASE 2 — Rsync del sitio PHP
# =============================================================================
log_info "Fase 2: rsync del sitio PHP → $VPS_HTML_ROOT/$VPS_HTML_VERSION/"

# Exclusiones (revisadas contra el diff local↔remoto de reconocimiento-vps.md §6):
#   ssl/                 el clon local aún contiene material SSL de renovación;
#                        NUNCA se propaga (incidente registrado en
#                        politicas-institucionales.md §6)
#   logs/                bitácoras de runtime del servidor, no código
#   calcular_clicks.log  log suelto en la raíz del clon local
#   .DS_Store            basura de Finder
#   DEPLOYED_COMMIT      lo escribe la Fase 4, no el rsync
#   0*/                  sesiones web efímeras, por si existieran en el docroot
RSYNC_SITE_OPTS=(
    -avz
    --delete
    --exclude='.DS_Store'
    --exclude='ssl/'
    --exclude='logs/'
    --exclude='calcular_clicks.log'
    --exclude='DEPLOYED_COMMIT'
    --exclude='0*/'
)
[[ $DRY_RUN -eq 1 ]] && RSYNC_SITE_OPTS+=(--dry-run)

run_rsync_site() {
    rsync "${RSYNC_SITE_OPTS[@]}" -e "$RSYNC_SSH" \
        "$LOCAL_SITE_ROOT/" \
        "${VPS_USER}@${VPS_HOST}:$VPS_HTML_ROOT/$VPS_HTML_VERSION/" 2>&1 | tee -a "$LOG_FILE"
}
if run_rsync_site; then
    log_ok "Fase 2: rsync del sitio completado$( [[ $DRY_RUN -eq 1 ]] && echo ' (simulado)' )."
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "Fase 2: rsync simulado no pudo conectar al VPS. Dry-run continúa."
    else
        die "Fase 2: rsync del sitio falló. Nada se ha activado (el symlink no se ha tocado)."
    fi
fi

# =============================================================================
# FASE 3 — Rsync del motor Stata y de los .dta procesados
# =============================================================================
log_info "Fase 3a: rsync del motor Stata → $VPS_SIM_ROOT/$VPS_SIM_VERSION/"

# Alcance del motor (aprobado 2026-07-10): árbol completo que el canal web
# necesita para correr — .ado/.do/.scheme del root del repo + 01_modulos/
# (incluye Web.Stata.do y output.do). NO se propaga governance, help, sitio,
# scripts, users/ ni raw/.
RSYNC_ENGINE_OPTS=(
    -avz
    --delete
    --include='/*.ado'
    --include='/*.do'
    --include='/*.scheme'
    --include='/01_modulos/***'
    --exclude='*'
)
[[ $DRY_RUN -eq 1 ]] && RSYNC_ENGINE_OPTS+=(--dry-run)

run_rsync_engine() {
    rsync "${RSYNC_ENGINE_OPTS[@]}" -e "$RSYNC_SSH" \
        "$LOCAL_REPO_ROOT/" \
        "${VPS_USER}@${VPS_HOST}:$VPS_SIM_ROOT/$VPS_SIM_VERSION/" 2>&1 | tee -a "$LOG_FILE"
}
if run_rsync_engine; then
    log_ok "Fase 3a: rsync del motor completado$( [[ $DRY_RUN -eq 1 ]] && echo ' (simulado)' )."
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "Fase 3a: rsync simulado no pudo conectar al VPS. Dry-run continúa."
    else
        die "Fase 3a: rsync del motor falló. Nada se ha activado."
    fi
fi

log_info "Fase 3b: rsync de .dta procesados → $VPS_SIM_ROOT/$VPS_SIM_VERSION/master/"

# Alcance mínimo aprobado 2026-07-10: SOLO los .dta de primer nivel de master/
# (~2.7 GB). Los subdirectorios anuales (2014/…2024/) NO se propagan para
# eficientar red y disco del VPS. La Mac es la fuente de verdad (D.3, R.5).
# --progress (no --info=progress2): el rsync de macOS es 2.6.9 y no conoce
# la sintaxis moderna. --progress funciona en ambos extremos.
RSYNC_MASTER_OPTS=(
    -az
    --progress
    --delete
    --include='/*.dta'
    --exclude='*'
)
[[ $DRY_RUN -eq 1 ]] && RSYNC_MASTER_OPTS+=(--dry-run)

run_rsync_master() {
    rsync "${RSYNC_MASTER_OPTS[@]}" -e "$RSYNC_SSH" \
        "$LOCAL_REPO_ROOT/master/" \
        "${VPS_USER}@${VPS_HOST}:$VPS_SIM_ROOT/$VPS_SIM_VERSION/master/" 2>&1 | tee -a "$LOG_FILE"
}
if run_rsync_master; then
    log_ok "Fase 3b: rsync de master/ completado$( [[ $DRY_RUN -eq 1 ]] && echo ' (simulado)' )."
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "Fase 3b: rsync simulado no pudo conectar al VPS. Dry-run continúa."
    else
        die "Fase 3b: rsync de master/ falló. Nada se ha activado."
    fi
fi

# =============================================================================
# FASE 4 — Escribir DEPLOYED_COMMIT en el VPS
# =============================================================================
log_info "Fase 4: escribir DEPLOYED_COMMIT."

DEPLOYED_COMMIT_TMP=$(mktemp /tmp/DEPLOYED_COMMIT.XXXXXX)
cat > "$DEPLOYED_COMMIT_TMP" <<EOF
Commit: $CURRENT_COMMIT
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Deployment: $VERSION_ARG
Deployed by: ${VPS_USER} via publicar-vps.sh
EOF

if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Se escribiría en $VPS_HTML_ROOT/$VPS_HTML_VERSION/DEPLOYED_COMMIT y $VPS_SIM_ROOT/$VPS_SIM_VERSION/DEPLOYED_COMMIT:"
    tee -a "$LOG_FILE" < "$DEPLOYED_COMMIT_TMP"
else
    # Se escribe en ambos directorios de deployment (D.7): el del sitio (lo lee
    # health.php) y el del motor (trazabilidad del lado Stata).
    rsync -az -e "$RSYNC_SSH" "$DEPLOYED_COMMIT_TMP" \
        "${VPS_USER}@${VPS_HOST}:$VPS_HTML_ROOT/$VPS_HTML_VERSION/DEPLOYED_COMMIT" 2>&1 | tee -a "$LOG_FILE"
    rsync -az -e "$RSYNC_SSH" "$DEPLOYED_COMMIT_TMP" \
        "${VPS_USER}@${VPS_HOST}:$VPS_SIM_ROOT/$VPS_SIM_VERSION/DEPLOYED_COMMIT" 2>&1 | tee -a "$LOG_FILE"
    log_ok "Fase 4: DEPLOYED_COMMIT escrito ($CURRENT_COMMIT_SHORT)."
fi
rm -f "$DEPLOYED_COMMIT_TMP"

# =============================================================================
# FASE 5 — Swap del symlink (cutover atómico)
# =============================================================================
log_info "Fase 5: swap del symlink current."

if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Se ejecutaría:"
    log_info "  ln -sfn '$VPS_HTML_ROOT/$VPS_HTML_VERSION' '$VPS_HTML_ROOT/current'"
    log_info "  ln -sfn '$VPS_SIM_ROOT/$VPS_SIM_VERSION' '$VPS_SIM_ROOT/current'"
else
    if [[ $FORCE -eq 0 ]]; then
        log_warn "A punto de cambiar el symlink current: ${PREVIOUS_DEPLOYMENT:-"(ninguno — primer deploy)"} → $VERSION_ARG"
        answer=""
        read -r -p "¿Continuar con el cutover? [y/N] " answer || true
        if [[ ! "$answer" =~ ^[yY]$ ]]; then
            die "Cutover cancelado por el operador. El código ya está en el VPS pero NO activado (symlink intacto)."
        fi
    fi
    # ln -sfn (no -sf): sin -n, si current ya es symlink a un directorio, ln
    # crearía el symlink nuevo DENTRO del directorio apuntado en vez de
    # reemplazar el symlink. -n trata el destino como el symlink mismo.
    ssh_vps "ln -sfn '$VPS_HTML_ROOT/$VPS_HTML_VERSION' '$VPS_HTML_ROOT/current' && ln -sfn '$VPS_SIM_ROOT/$VPS_SIM_VERSION' '$VPS_SIM_ROOT/current'"
    log_ok "Fase 5: symlinks current → $VERSION_ARG activados."
fi

# =============================================================================
# FASE 6 — Verificación post-deploy (health check)
# =============================================================================
health_check() {
    # Reintentos: 3 intentos con 2s de espera (da margen a Apache/caché)
    local attempt http_code
    for attempt in 1 2 3; do
        http_code=$(curl -sf -o /dev/null --max-time 10 -w "%{http_code}" "$VPS_HEALTH_URL" 2>/dev/null) || http_code="000"
        if [[ "$http_code" == "200" ]]; then
            return 0
        fi
        log_warn "Health check intento $attempt/3: HTTP $http_code (esperaba 200)."
        sleep 2
    done
    return 1
}

health_commit_matches() {
    curl -s --max-time 10 "$VPS_HEALTH_URL" 2>/dev/null | grep -q "Commit: $CURRENT_COMMIT"
}

HEALTH_PASSED=1
if [[ $SKIP_HEALTH -eq 1 ]]; then
    log_warn "Fase 6: SALTADA por --skip-health. El rollback automático también queda saltado."
    log_warn "Verifica el sitio manualmente: $VPS_HEALTH_URL"
elif [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Fase 6: se verificaría HTTP 200 y 'Commit: ${CURRENT_COMMIT_SHORT}...' en $VPS_HEALTH_URL"
else
    log_info "Fase 6: verificación post-deploy contra $VPS_HEALTH_URL"
    if health_check; then
        log_ok "Health check: HTTP 200."
        if health_commit_matches; then
            log_ok "Health check: el sitio reporta el commit desplegado ($CURRENT_COMMIT_SHORT)."
        else
            log_error "El sitio responde 200 pero NO reporta el commit esperado."
            log_error "Posibles causas: DEPLOYED_COMMIT no se propagó, o el vhost de Apache no apunta a current todavía."
            HEALTH_PASSED=0
        fi
    else
        log_error "Health check falló (sin HTTP 200 tras 3 intentos)."
        HEALTH_PASSED=0
    fi
fi

# =============================================================================
# FASE 7 — Rollback automático si la verificación falló
# =============================================================================
if [[ $HEALTH_PASSED -eq 0 ]]; then
    if [[ -n "$PREVIOUS_DEPLOYMENT" ]]; then
        log_warn "Fase 7: rollback automático al deployment anterior ($PREVIOUS_DEPLOYMENT)."
        ssh_vps "ln -sfn '$VPS_HTML_ROOT/$PREVIOUS_DEPLOYMENT' '$VPS_HTML_ROOT/current' && ln -sfn '$VPS_SIM_ROOT/$PREVIOUS_SIM' '$VPS_SIM_ROOT/current'"
        if health_check; then
            log_ok "Rollback verificado: el sitio responde HTTP 200 con $PREVIOUS_DEPLOYMENT."
        else
            log_error "El sitio NO responde tras el rollback. INTERVENCIÓN MANUAL REQUERIDA."
            log_error "Revisa por SSH: readlink $VPS_HTML_ROOT/current ; systemctl status apache2"
        fi
        die "Deploy de $VERSION_ARG revertido. Revisa el log: $LOG_FILE"
    else
        # Primer deploy: no hay deployment anterior al cual regresar. Los
        # symlinks recién creados se dejan como están para inspección manual.
        log_warn "ADVERTENCIA: No hay deployment anterior. Rollback imposible."
        log_warn "El sitio queda en estado post-fallo. Investigación manual requerida."
        die "Health check falló en el primer deploy (sin rollback posible).
        Nota: si el vhost de Apache aún no apunta a $VPS_HTML_ROOT/current,
        el health check por dominio NO puede pasar todavía (ver bitácora v1.21).
        Opciones: ajustar el vhost (cutover, Fase 5 del roadmap) o correr con
        --skip-health y verificar manualmente. Log: $LOG_FILE"
    fi
fi

# =============================================================================
# FASE 8 — Reporte de éxito
# =============================================================================
log ""
log_ok "=============================================="
log_ok " Deployment $VERSION_ARG completado$( [[ $DRY_RUN -eq 1 ]] && echo ' (DRY-RUN: nada se aplicó)' )"
log_ok "=============================================="
log_ok " Commit desplegado:  $CURRENT_COMMIT_SHORT"
log_ok " Deployment previo:  ${PREVIOUS_DEPLOYMENT:-"(ninguno — primer deploy)"}"
log_ok " Health check URL:   $VPS_HEALTH_URL"
log_ok " Log de la corrida:  $LOG_FILE"
if [[ -n "$PREVIOUS_DEPLOYMENT" && $DRY_RUN -eq 0 ]]; then
    log_info "Rollback manual si lo necesitas después:"
    log_info "  ssh ${VPS_USER}@${VPS_HOST} \"ln -sfn '$VPS_HTML_ROOT/$PREVIOUS_DEPLOYMENT' '$VPS_HTML_ROOT/current' && ln -sfn '$VPS_SIM_ROOT/$PREVIOUS_SIM' '$VPS_SIM_ROOT/current'\""
fi
exit 0
