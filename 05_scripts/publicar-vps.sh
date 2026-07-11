#!/usr/bin/env bash
# =============================================================================
# publicar-vps.sh — Pipeline de deployment al VPS de simuladorfiscal.ciep.mx
# =============================================================================
#
# Qué hace: respalda la config Apache del VPS (Fase 0, vía backup-vps.sh),
# propaga el código local (PHP del sitio + motor Stata + .dta procesados)
# al VPS IONOS, hace cutover atómico vía symlink `current`, verifica el
# sitio con un health check y hace rollback automático si falla.
#
# Diseño registrado en 02_governance/arquitectura-y-bitacoras.md §7.1-§7.2
# (decisiones D.1-D.9, bitácoras v1.20-v1.21). Estructura del VPS documentada
# en 02_governance/reconocimiento-vps.md.
#
# Uso:
#   ./publicar-vps.sh <version-deployment> [--dry-run] [--force] [--skip-health]
#   ./publicar-vps.sh <version-deployment> --limpiar-master-vps
#
# Ejemplos:
#   ./publicar-vps.sh v8.0            # deploy real, con confirmación
#   ./publicar-vps.sh v8.0 --dry-run  # simula: muestra qué haría, no cambia nada
#   ./publicar-vps.sh v8.1 --force    # deploy real sin pausa de confirmación
#   ./publicar-vps.sh v8.0 --limpiar-master-vps  # propone (NO ejecuta) la
#                                     # limpieza de años/perfiles no vigentes
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

# -----------------------------------------------------------------------------
# Whitelist del canon web (decisión 2026-07-09, bitácora v1.27)
# -----------------------------------------------------------------------------
# El flujo WEB solo consume el año ENIGH vigente (master/2024/) y el perfil
# vigente (perfiles2026.dta). Los años previos (2014-2022) y sus perfiles son
# insumos SOLO-LOCALES (trabajo del investigador en su Mac): no viajan al VPS.
# El VPS solo aloja lo que el web sirve.
#
# ACTUALIZAR ESTAS 2 VARIABLES cuando avance el ENIGH vigente (~cada 2 años).
# Es intencional que la regla viva explícita aquí, no en symlinks ni en
# infraestructura: un cambio de vigencia es una decisión editable en el código
# y auditable en Git. Las leen la Fase 3b (deploy) y el modo
# --limpiar-master-vps (limpieza), de la MISMA fuente: nunca se contradicen.
#
# INVARIANTE (bitácora v1.36 — leer antes de tocar esta whitelist): el VPS
# NUNCA debe arrancar con master/ vacío. Los Update* de los .ado se disparan
# solos cuando master/ está vacío (o con la global $update, que el VPS jamás
# setea): si esta whitelist dejara de garantizar los master/*.dta, el motor
# reconstruiría EN PRODUCCIÓN (descargas en vivo de SHCP/INEGI a media
# petición web). El guard c(console) que antes bloqueaba eso por accidente se
# retiró en v8.0.11 por redundante con ESTA garantía — quien modifique la
# whitelist hereda la responsabilidad de mantenerla.
WEB_MASTER_YEAR="2024"
WEB_PERFIL="perfiles2026.dta"

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
  ./publicar-vps.sh <version-deployment> --limpiar-master-vps

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
  --limpiar-master-vps  NO despliega. Inspecciona master/ en el VPS y propone
                        (imprime, NUNCA ejecuta) los comandos rm para borrar
                        años y perfiles que NO están en la whitelist vigente
                        (WEB_MASTER_YEAR / WEB_PERFIL). Borrar en producción
                        es acción manual del operador.
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
LIMPIAR_MASTER=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=1 ;;
        --force)       FORCE=1 ;;
        --skip-health) SKIP_HEALTH=1 ;;
        --limpiar-master-vps) LIMPIAR_MASTER=1 ;;
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

# =============================================================================
# MODO --limpiar-master-vps — propone la limpieza de años/perfiles no vigentes
# =============================================================================
# Contexto (bitácora v1.27): la Fase 3b recursiva original subió TODOS los
# años (2014-2024) y TODOS los perfiles*.dta al VPS. La whitelist de la Fase
# 3b previene FUTURAS subidas, pero no borra lo ya presente. Este modo lista
# lo sobrante y propone los rm exactos — NUNCA los ejecuta: borrar en
# producción es acción manual del operador (mismo principio que el cutover).
#
# Qué CONSERVAR se deriva de las MISMAS variables que usa el deploy
# (WEB_MASTER_YEAR, WEB_PERFIL): limpieza y deploy no pueden contradecirse.
# Los .dta planos de la raíz jamás se proponen: los patrones solo capturan
# subdirectorios de 4 dígitos y archivos perfiles*.dta.
if [[ $LIMPIAR_MASTER -eq 1 ]]; then
    MASTER_REMOTO="$VPS_SIM_ROOT/$VPS_SIM_VERSION/master"
    log_info "Modo limpieza: inspeccionando $MASTER_REMOTO/ en el VPS."
    log_info "Whitelist vigente: año $WEB_MASTER_YEAR, perfil $WEB_PERFIL."

    # ls -1p: una entrada por línea; los directorios llevan '/' al final.
    LISTADO_MASTER=$(ssh_vps "ls -1p '$MASTER_REMOTO/'") \
        || die "No se pudo listar $MASTER_REMOTO/ en el VPS.
        Verifica que la versión exista (¿ya corriste un deploy de $VERSION_ARG?)
        y que el VPS responda: ssh ${VPS_USER}@${VPS_HOST} ls '$MASTER_REMOTO/'"

    PROPUESTA_RM=()
    while IFS= read -r entrada; do
        [[ -n "$entrada" ]] || continue
        # GUARD: el año y el perfil VIGENTES jamás entran a la propuesta,
        # aunque los patrones de abajo cambien en el futuro.
        case "$entrada" in
            "${WEB_MASTER_YEAR}/"|"$WEB_PERFIL") continue ;;
        esac
        if [[ "$entrada" =~ ^[0-9]{4}/$ ]]; then
            PROPUESTA_RM+=("rm -rf '$MASTER_REMOTO/${entrada%/}'")
        elif [[ "$entrada" =~ ^perfiles.*\.dta$ ]]; then
            PROPUESTA_RM+=("rm -f '$MASTER_REMOTO/$entrada'")
        fi
    done <<< "$LISTADO_MASTER"

    if [[ ${#PROPUESTA_RM[@]} -eq 0 ]]; then
        log_ok "Nada que limpiar: master/ en el VPS ya coincide con la whitelist."
    else
        log_warn "Encontrados ${#PROPUESTA_RM[@]} sobrantes (años/perfiles NO vigentes)."
        log ""
        log "Ejecuta estos comandos por SSH para limpiar:"
        for cmd_rm in "${PROPUESTA_RM[@]}"; do
            log "  $cmd_rm"
        done
        log ""
        log_info "Este modo NUNCA borra por sí mismo. Copia los comandos en una"
        log_info "sesión SSH (ssh ${VPS_USER}@${VPS_HOST}) tras verificarlos."
    fi
    exit 0
fi

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
[[ -d "$LOCAL_REPO_ROOT/users/ricardo/bootstraps" ]] || die "No existe $LOCAL_REPO_ROOT/users/ricardo/bootstraps (el escenario base que consume el motor web). Sin él, el motor truena con r(601) — falla 6 del debugging 2026-07-09."
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
# FASE 0 — Backup pre-deploy (config Apache, vía backup-vps.sh)
# =============================================================================
# Regla institucional (D.3 del diseño de backup, §7.2): sin backup exitoso no
# hay deploy. El backup automático cubre SOLO la config Apache; las llaves SSL
# se respaldan manualmente con backup-vps.sh --llaves cuando rotan (I.1).
log_info "Fase 0: backup pre-deploy (config Apache)."

BACKUP_SCRIPT="${SCRIPT_DIR}/backup-vps.sh"
[[ -x "$BACKUP_SCRIPT" ]] || die "No existe o no es ejecutable: $BACKUP_SCRIPT
        El backup pre-deploy es obligatorio (sin backup no hay deploy).
        Verifica el repo o restaura el archivo: git checkout -- 05_scripts/backup-vps.sh"

BACKUP_ARGS=()
[[ $DRY_RUN -eq 1 ]] && BACKUP_ARGS+=(--dry-run)

if "$BACKUP_SCRIPT" ${BACKUP_ARGS[@]+"${BACKUP_ARGS[@]}"} 2>&1 | tee -a "$LOG_FILE"; then
    log_ok "Fase 0: backup pre-deploy completado$( [[ $DRY_RUN -eq 1 ]] && echo ' (simulado)' )."
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "Fase 0: el backup simulado falló. Dry-run continúa, pero revisa
el mensaje de arriba — en un deploy real esto ABORTARÍA el pipeline."
    else
        die "Fase 0: el backup pre-deploy falló. SIN BACKUP EXITOSO NO HAY DEPLOY.
        Nada se ha transferido ni activado. Revisa el mensaje del backup arriba
        (causas típicas: BACKUP_ROOT sin definir en el credentials, VPS sin red,
        ningún .conf descargado) y vuelve a correr el script."
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
#
# --chmod (SIEMPRE después de -a, para que gane sobre el -p implícito de -a):
# declara directorios 775 y archivos 664 en el destino, sin importar los
# permisos del origen (Mac/Dropbox). Es la protección contra el HTTP 403 del
# primer deploy (2026-07-09), cuando rsync preservó permisos 700/600 y Apache
# (www-data) no pudo leer el sitio — mismo patrón ya documentado en
# arquitectura-y-bitacoras.md §troubleshooting "Permisos rsync --chmod".
# DOS advertencias del rsync de macOS (que en realidad es openrsync de Apple,
# anunciado como "2.6.9 compatible"; verificado con pruebas locales 2026-07-09):
#   1. La sintaxis octal (D775,F664) la rechaza con "invalid argument";
#      por eso se usa la forma simbólica.
#   2. openrsync ACEPTA la forma simbólica pero la IGNORA en silencio.
#      Por eso la garantía real contra el 403 es la Fase 3c (chmod remoto
#      post-transferencia). El --chmod se conserva declarativo: aplica si el
#      cliente es un rsync 3.x real (p. ej. Homebrew) y no estorba en openrsync.
RSYNC_SITE_OPTS=(
    -avz
    --chmod=Du=rwx,Dg=rwx,Do=rx,Fu=rw,Fg=rw,Fo=r
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
# --chmod después de -a, forma simbólica = 775/664 (ver nota completa en la
# Fase 2; la garantía real es la Fase 3c porque openrsync ignora --chmod).
# Los --exclude explícitos de abajo son redundantes con el catch-all final
# (--exclude='*' ya protege todo lo no incluido de la transferencia Y del
# --delete), pero se listan para autodocumentar qué vive en el destino sin
# venir de este rsync: users/ (sesiones + escenario base, Fase 3b-bis),
# raw/ (temporales de runtime), master/ (Fase 3b) y DEPLOYED_COMMIT (Fase 4).
RSYNC_ENGINE_OPTS=(
    -avz
    --chmod=Du=rwx,Dg=rwx,Do=rx,Fu=rw,Fg=rw,Fo=r
    --delete
    --exclude='/users/'
    --exclude='/raw/'
    --exclude='/master/'
    --exclude='/DEPLOYED_COMMIT'
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

# Alcance WHITELIST (refinado 2026-07-09, bitácora v1.27): el alcance
# recursivo total (fix de la falla 5) sobre-aprovisionaba — subía TODAS las
# subcarpetas de año (2014-2024) y TODOS los perfiles*.dta, pero el flujo web
# solo consume el año ENIGH vigente y su perfil (hoy: master/2024/ y
# perfiles2026.dta; ver WEB_MASTER_YEAR/WEB_PERFIL al inicio del script).
# Los años previos son insumos solo-locales: el VPS solo aloja lo que el web
# sirve. La Mac sigue siendo la fuente de verdad (D.3, R.5).
#
# LOS FILTROS SE EVALÚAN EN ORDEN, PRIMER MATCH GANA — los --include
# específicos van ANTES de los --exclude generales:
#   1. /$WEB_MASTER_YEAR/***   el año vigente completo SÍ viaja
#   2. /[0-9][0-9][0-9][0-9]/  los demás años NO (el vigente ya matcheó arriba)
#   3. /$WEB_PERFIL            el perfil vigente SÍ
#   4. /perfiles*.dta          los demás perfiles NO
#   5. /*.dta                  los .dta PLANOS de la raíz SÍ (DatosAbiertos,
#                              PEF, Poblacion, Poblaciontot, SCN, SHRFSP, LIF,
#                              Deflactor, PIBDeflactor — ninguno matchea los
#                              patrones de años ni de perfiles)
#   6. *                       catch-all: nada más viaja, y protege del
#                              --delete lo excluido en el receptor (los años
#                              viejos ya subidos NO se borran: para eso está
#                              el modo --limpiar-master-vps)
# --progress (no --info=progress2): el rsync de macOS es 2.6.9 y no conoce
# la sintaxis moderna. --progress funciona en ambos extremos.
# --chmod después de -a, forma simbólica = 775/664 (ver nota completa en la
# Fase 2; la garantía real es la Fase 3c porque openrsync ignora --chmod).
RSYNC_MASTER_OPTS=(
    -az
    --chmod=Du=rwx,Dg=rwx,Do=rx,Fu=rw,Fg=rw,Fo=r
    --progress
    --delete
    --exclude='.DS_Store'
    --include="/${WEB_MASTER_YEAR}/***"
    --exclude='/[0-9][0-9][0-9][0-9]/'
    --include="/${WEB_PERFIL}"
    --exclude='/perfiles*.dta'
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
# FASE 3b-bis — Rsync del escenario base (users/ricardo/bootstraps/)
# =============================================================================
# Falla 6 del debugging 2026-07-09: users/ricardo/bootstraps/1/ (~5 MB, 217
# archivos: CFEREC.dta etc.) es el ESCENARIO BASE que el motor web consume en
# cada simulación — NO son datos de sesión, son un asset de deployment que el
# pipeline no llevaba (el motor tronaba con r(601)). Convención v8: el motor
# busca users/ricardo/ (el snapshot v7 usaba users/ciepmx/).
# Tras el rsync: chmod -R con o=rX sobre users/ricardo/ — www-data solo LEE
# el escenario base (las sesiones de escritura viven en users/0*/, no aquí).
log_info "Fase 3b-bis: rsync del escenario base → $VPS_SIM_ROOT/$VPS_SIM_VERSION/users/ricardo/bootstraps/"

RSYNC_BOOTSTRAPS_OPTS=(
    -az
    --chmod=Du=rwx,Dg=rwx,Do=rx,Fu=rw,Fg=rw,Fo=r
    --progress
    --delete
    --exclude='.DS_Store'
)
[[ $DRY_RUN -eq 1 ]] && RSYNC_BOOTSTRAPS_OPTS+=(--dry-run)

run_rsync_bootstraps() {
    # rsync no crea los directorios padre del destino: se garantizan primero.
    if [[ $DRY_RUN -eq 0 ]]; then
        ssh_vps "mkdir -p '$VPS_SIM_ROOT/$VPS_SIM_VERSION/users/ricardo/bootstraps'" || return 1
    fi
    rsync "${RSYNC_BOOTSTRAPS_OPTS[@]}" -e "$RSYNC_SSH" \
        "$LOCAL_REPO_ROOT/users/ricardo/bootstraps/" \
        "${VPS_USER}@${VPS_HOST}:$VPS_SIM_ROOT/$VPS_SIM_VERSION/users/ricardo/bootstraps/" 2>&1 | tee -a "$LOG_FILE"
}
if run_rsync_bootstraps; then
    if [[ $DRY_RUN -eq 0 ]]; then
        ssh_vps "chmod -R u=rwX,g=rwX,o=rX '$VPS_SIM_ROOT/$VPS_SIM_VERSION/users/ricardo'"
    fi
    log_ok "Fase 3b-bis: escenario base propagado$( [[ $DRY_RUN -eq 1 ]] && echo ' (simulado)' )."
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "Fase 3b-bis: rsync simulado no pudo conectar al VPS. Dry-run continúa."
    else
        die "Fase 3b-bis: rsync del escenario base falló. Nada se ha activado."
    fi
fi

# =============================================================================
# FASE 3c — Normalización de permisos en el VPS (garantía anti-403)
# =============================================================================
# El rsync de macOS (openrsync) ignora --chmod en silencio (verificado con
# transferencias locales el 2026-07-09), así que los permisos restrictivos del
# origen pueden llegar intactos (700/600) y Apache no podría leer — el HTTP 403
# del primer deploy. Este chmod remoto replica el fix manual que dejó a v8.0
# sirviendo en producción y es determinista sin importar el cliente rsync.
#
# SOLO SOBRE LO QUE EL DEPLOY POSEE (fix 2026-07-09, segundo re-deploy): el
# chmod -R ciego original tronaba con "Operation not permitted" — el árbol
# mezcla dos poblaciones con dueños distintos: las fuentes que sube el deploy
# (${VPS_USER}) y el runtime que crea Apache (www-data: sesiones en users/0*,
# sankeys, logs, raw/temp). ${VPS_USER} no puede chmodear lo de www-data, y
# con set -e el deploy abortaba a medias ANTES del swap. El find -user filtra
# por dueño: solo toca lo de ${VPS_USER} y es autoajustable — cualquier
# archivo runtime futuro queda excluido por ownership, sin mantener listas.
# Con -exec … {} + no se invoca chmod si no hay matches (exit 0 limpio).
FASE3C_CHMOD_CMD="find '$VPS_HTML_ROOT/$VPS_HTML_VERSION' '$VPS_SIM_ROOT/$VPS_SIM_VERSION' -user '$VPS_USER' -exec chmod u=rwX,g=rwX,o=rX {} +"
log_info "Fase 3c: normalización de permisos en el VPS (u=rwX,g=rwX,o=rX, solo archivos de ${VPS_USER})."
if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Se ejecutaría:"
    log_info "  $FASE3C_CHMOD_CMD"
else
    ssh_vps "$FASE3C_CHMOD_CMD"
    log_ok "Fase 3c: permisos normalizados (runtime de www-data intacto por diseño)."
fi

# Lista de ESCRITURA de www-data (fallas 1-3 del debugging 2026-07-09).
# Patrón raíz: todo lo creado en el VPS después del chmod de arriba nace
# ilegible o inescribible para Apache (www-data corre como "others": o=rX).
# Estos son los ÚNICOS directorios donde www-data escribe, y se re-fuerzan
# 777 al final de la fase para que el orden de operaciones no importe:
#   $VPS_SIM_ROOT/$VPS_SIM_VERSION/users/    sesiones web (mkdir de calculaStata.php)
#   $VPS_SIM_ROOT/$VPS_SIM_VERSION/raw/temp/ temporales de .ado (AccesoBIE, DatosAbiertos)
#   $VPS_HTML_ROOT/$VPS_HTML_VERSION/logs/   bitácoras de runtime (logCalcular.php)
# El 777 de users/ NO es recursivo: users/ricardo/ (escenario base, solo
# lectura) conserva el o=rX que le dejó la Fase 3b-bis.
WWWDATA_WRITE_DIRS_CMD="mkdir -p '$VPS_SIM_ROOT/$VPS_SIM_VERSION/users' '$VPS_SIM_ROOT/$VPS_SIM_VERSION/raw/temp' '$VPS_HTML_ROOT/$VPS_HTML_VERSION/logs' && chmod 777 '$VPS_SIM_ROOT/$VPS_SIM_VERSION/users' '$VPS_SIM_ROOT/$VPS_SIM_VERSION/raw/temp' '$VPS_HTML_ROOT/$VPS_HTML_VERSION/logs'"
if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[dry-run] Se ejecutaría (directorios de escritura de www-data):"
    log_info "  $WWWDATA_WRITE_DIRS_CMD"
else
    ssh_vps "$WWWDATA_WRITE_DIRS_CMD"
    log_ok "Fase 3c: directorios de escritura de www-data garantizados (users/, raw/temp/, logs/)."
fi

# =============================================================================
# FASE 4 — Escribir DEPLOYED_COMMIT en el VPS
# =============================================================================
log_info "Fase 4: escribir DEPLOYED_COMMIT."

# Versión del MOTOR (bitácora v1.30) y fecha de los DATOS (bitácora v1.31):
# ambas salen de 05_scripts/manifest.json — la fuente de verdad que valida el
# Gate 3 de publicar.sh. `version` → línea "Version:" (el hero y el footer la
# pintan como "Versión del simulador": "qué versión del modelo produjo estos
# números"). `data_updated` (ISO YYYY-MM-DD) → línea "DataUpdated:" (el hero
# la pinta como "Última actualización", reformateada por idioma: frescura de
# los DATOS precargados; se bumpea solo al reprocesar datos, no en releases
# de código). "Qué deploy es este" lo siguen diciendo Commit: y Deployment:.
# Parseo con python3 + json (patrón de casa, mismo del Gate 3): parser real,
# inmune a formato/orden de campos. Cualquier falla (archivo ausente, JSON
# inválido, campo faltante) colapsa a cadena vacía SIN abortar el deploy —
# el sitio no pinta versión y usa su fecha de respaldo; nunca rompe.
# Una sola pasada: imprime tres líneas (version, data_updated, release_url_prefix).
MANIFEST_FIELDS=$(python3 - "$LOCAL_REPO_ROOT/05_scripts/manifest.json" <<'PYEOF' 2>/dev/null || printf '\n\n\n'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        m = json.load(f)
except Exception:
    m = {}
print(m.get("version", "") or "")
print(m.get("data_updated", "") or "")
print(m.get("release_url_prefix", "") or "")
PYEOF
)
ENGINE_VERSION=$(printf '%s\n' "$MANIFEST_FIELDS" | sed -n '1p')
DATA_UPDATED=$(printf '%s\n' "$MANIFEST_FIELDS" | sed -n '2p')
RELEASE_PREFIX=$(printf '%s\n' "$MANIFEST_FIELDS" | sed -n '3p')

# URL del GitHub Release de la versión del motor (bitácora v1.32): el número
# de versión del hero/footer enlaza a su release exacto — señal de código
# abierto. Derivada de release_url_prefix (que el Gate 3 de publicar.sh
# garantiza terminado en /<version>/): se recorta el sufijo
# 'releases/download/<version>/' y se arma 'releases/tag/<version>' — el tag
# real de los releases usa el MISMO formato que manifest.version (con 'v';
# publicar.sh hace gh release create "$version"). Si el prefix no tiene la
# forma esperada, queda vacía: el sitio pinta la versión como texto plano,
# nunca un link roto.
RELEASE_URL=""
if [[ -n "$ENGINE_VERSION" && "$RELEASE_PREFIX" == https://github.com/*/releases/download/* ]]; then
    RELEASE_URL="${RELEASE_PREFIX%releases/download/*}releases/tag/${ENGINE_VERSION}"
elif [[ -n "$ENGINE_VERSION" ]]; then
    log_warn "Fase 4: release_url_prefix del manifest no tiene la forma esperada
(https://github.com/<owner>/<repo>/releases/download/…) — la línea ReleaseUrl:
queda VACÍA y el sitio mostrará la versión sin link. El deploy continúa."
fi

# Formato: la línea "Version:" convive con las demás — health.php vuelca el
# archivo completo (no parsea por claves) y health_commit_matches() busca el
# substring "Commit: <hash>", así que ningún consumidor se rompe.
DEPLOYED_COMMIT_TMP=$(mktemp /tmp/DEPLOYED_COMMIT.XXXXXX)
cat > "$DEPLOYED_COMMIT_TMP" <<EOF
Commit: $CURRENT_COMMIT
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Deployment: $VERSION_ARG
Version: $ENGINE_VERSION
DataUpdated: $DATA_UPDATED
ReleaseUrl: $RELEASE_URL
Deployed by: ${VPS_USER} via publicar-vps.sh
EOF

if [[ -z "$ENGINE_VERSION" ]]; then
    log_warn "Fase 4: no pude leer 'version' de 05_scripts/manifest.json — la línea
Version: queda VACÍA (el sitio no pintará versión). El deploy continúa, pero
revisa el manifest: ¿existe, es JSON válido, tiene el campo 'version'?"
fi
if [[ -z "$DATA_UPDATED" ]]; then
    log_warn "Fase 4: no pude leer 'data_updated' de 05_scripts/manifest.json — la línea
DataUpdated: queda VACÍA (el hero usará su fecha de respaldo hardcodeada, que
puede estar VIEJA). El deploy continúa, pero revisa el campo en el manifest."
fi

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
    # chmod explícito (falla 1 del debugging 2026-07-09): este archivo se
    # escribe DESPUÉS del chmod masivo de la Fase 3c, así que nació 600 (el
    # mktemp local es 600 y rsync -a preserva permisos) → health.php no pudo
    # leerlo y el health check disparó un rollback falso. La garantía es este
    # chmod explícito, independiente del orden de fases.
    ssh_vps "chmod 664 '$VPS_HTML_ROOT/$VPS_HTML_VERSION/DEPLOYED_COMMIT' '$VPS_SIM_ROOT/$VPS_SIM_VERSION/DEPLOYED_COMMIT'"
    if [[ -n "$ENGINE_VERSION" && -n "$DATA_UPDATED" ]]; then
        log_ok "Fase 4: DEPLOYED_COMMIT escrito y legible ($CURRENT_COMMIT_SHORT, motor $ENGINE_VERSION, datos $DATA_UPDATED)."
    else
        log_warn "Fase 4: DEPLOYED_COMMIT escrito y legible ($CURRENT_COMMIT_SHORT) — [WARN] motor '${ENGINE_VERSION:-VACÍA}', datos '${DATA_UPDATED:-VACÍA}' (manifest.json ilegible o campo faltante)."
    fi
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
# HEALTH_LAST_CODE guarda el último código HTTP visto, para que el mensaje de
# fallo distinga entre "no conecta" (000) y "el servidor respondió con error"
# (403/404/500). En el primer deploy (2026-07-09) el curl con -f colapsó un
# 403 real (permisos) a 000 y el diagnóstico se fue por red/SSL: bug corregido.
HEALTH_LAST_CODE="000"
health_check() {
    # Reintentos: 3 intentos con 2s de espera (da margen a Apache/caché).
    # curl SIN -f (para capturar el código real en vez de colapsar a 000) y
    # con -L (el puerto 80 hace 301 a HTTPS).
    local attempt http_code
    for attempt in 1 2 3; do
        http_code=$(curl -sL -o /dev/null -w "%{http_code}" --max-time 10 "$VPS_HEALTH_URL" 2>/dev/null || echo "000")
        HEALTH_LAST_CODE="$http_code"
        if [[ "$http_code" == "200" ]]; then
            return 0
        fi
        log_warn "Health check intento $attempt/3: HTTP $http_code (esperaba 200)."
        sleep 2
    done
    return 1
}

health_commit_matches() {
    curl -sL --max-time 10 "$VPS_HEALTH_URL" 2>/dev/null | grep -q "Commit: $CURRENT_COMMIT"
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
        if [[ "$HEALTH_LAST_CODE" == "000" ]]; then
            log_error "Health check falló: no se pudo conectar (red, SSL o timeout). Verifica conectividad y el certificado."
        else
            log_error "Health check falló: el sitio respondió HTTP $HEALTH_LAST_CODE. Revisa permisos y contenido del deployment en $VPS_HTML_ROOT/$VPS_HTML_VERSION."
            log_error "(El bug de permisos del 2026-07-09 daba exactamente 403.)"
        fi
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
