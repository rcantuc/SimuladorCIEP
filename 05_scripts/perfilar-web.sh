#!/usr/bin/env bash
# perfilar-web.sh — perfil de tiempo del flujo web «Calcular» (v8.12 fase 1: SOLO medición).
#
# Reproduce localmente lo que dispara calculaStata.php cuando el usuario pulsa «Calcular»
# con el escenario default nacional: el mismo .do (01_modulos/Web.Stata.do con las {{llaves}}
# sustituidas por los valores que el sitio carga de users/ciepmx/output.txt), los mismos
# globals (bootstrap 250, idbase ricardo, seed 1111 por default de Simulador), los mismos
# <var>RECprom.dta precomputados, y la misma invocación: cd users/<id> && stata -b do <id>.do.
#
# Produce, en <evidencia>/:
#   escenario.json            valores del formulario (mapeo de output.txt -> inputs, como el JS)
#   perfbase/                 corrida SIN hooks (output.txt de referencia)
#   perfrun1..N/              corridas CON hooks: timer por sección, rmsg por comando, profiler
#   perftraza/                (--traza) una corrida con set trace -> inventario-io.json + piso-io.do
#   piso-io/                  (--traza) use/save aislado de cada archivo que toca el flujo
#   wall.txt                  tiempo de pared por corrida (shell)
#   resumen.md                tablas (sección × corrida, media ± DE, %, rmsg, profiler, piso I/O)
#   identicos.txt             cmp de output.txt de cada corrida contra perfbase (medir no mueve números)
#
# La instrumentación vive en la COPIA de trabajo del .do de la sesión (perfilar-web.py generar
# --instrumentar); Web.Stata.do y los .ado versionados NO se tocan. Los .ado ya traen
# timer on/off propios (LIF 4, PEF 5, Simulador 7, TasasEfectivas 8, GastoPC 9, FiscalGap 11):
# se dejan como están; el profiler los desglosa.
#
# Uso: bash 05_scripts/perfilar-web.sh [--root <clon con master/ raw/ users/ricardo/>]
#        [--runs 3] [--evidencia <dir>] [--stata <ruta stata>] [--traza] [--sin-base] [--limpiar]
#   --root      raíz que hará de /SIM/OUT/current/ (default: este clon). Debe tener
#               master/, raw/, users/ricardo/output.txt y users/ricardo/bootstraps/250/*RECprom.dta.
#   --evidencia default: <root>/users/_perf/<fecha>/ (users/ está en .gitignore).
#   --traza     añade la corrida con set trace (lenta, log grande) y el piso de I/O.
#   --sin-base  no corre el baseline sin hooks (y no compara output.txt).
#   --limpiar   borra los .dta de cada users/perf*/ al final (quedan logs y output.txt).
# Local = StataNow 19.5 (Mac). Producción = Stata/MP 17 (VPS): los absolutos difieren, el
# reparto relativo por sección es lo transferible. Este script NO toca el VPS.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || dirname "$HERE")"
ROOT="$REPO_ROOT"; RUNS=3; EVID=""; TRAZA=false; SIN_BASE=false; LIMPIAR=false
STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root) ROOT="$2"; shift 2 ;;
        --runs) RUNS="$2"; shift 2 ;;
        --evidencia) EVID="$2"; shift 2 ;;
        --stata) STATA="$2"; shift 2 ;;
        --traza) TRAZA=true; shift ;;
        --sin-base) SIN_BASE=true; shift ;;
        --limpiar) LIMPIAR=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 1 ;;
    esac
done
ROOT="$(cd "$ROOT" && pwd)"
PY="$HERE/perfilar-web.py"
TEMPLATE="$ROOT/01_modulos/Web.Stata.do"
FECHA="$(date +%Y-%m-%d)"
[[ -z "$EVID" ]] && EVID="$ROOT/users/_perf/$FECHA"
die() { echo "perfilar-web: $*" >&2; exit 1; }
log() { echo "[perfilar-web $(date +%H:%M:%S)] $*"; }
now() { python3 -c 'import time; print("%.3f" % time.time())'; }

# --- compuertas de arranque ---------------------------------------------------------------
[[ -x "$STATA" ]] || die "no hay Stata en $STATA (usa --stata o la variable STATA)"
[[ -f "$TEMPLATE" ]] || die "no existe $TEMPLATE"
[[ -f "$ROOT/master/LIF.dta" && -f "$ROOT/master/perfiles2027.dta" ]] || die "falta master/ en $ROOT (LIF.dta, perfiles2027.dta)"
[[ -f "$ROOT/users/ricardo/output.txt" ]] || die "falta $ROOT/users/ricardo/output.txt (escenario default publicado)"
N_PROM="$(find "$ROOT/users/ricardo/bootstraps/250" -maxdepth 1 -name '*RECprom.dta' 2>/dev/null | wc -l | tr -d ' ')"
[[ "$N_PROM" -gt 0 ]] || die "no hay $ROOT/users/ricardo/bootstraps/250/*RECprom.dta (escenario base de FiscalGap)"
if [[ "$ROOT" != "$REPO_ROOT" ]]; then
    if ! diff -q "$TEMPLATE" "$REPO_ROOT/01_modulos/Web.Stata.do" >/dev/null; then
        log "AVISO: Web.Stata.do de --root difiere del de este clon; se perfila el de --root."
    fi
fi
mkdir -p "$EVID"
log "root=$ROOT  evidencia=$EVID  runs=$RUNS  RECprom=$N_PROM  stata=$STATA"
python3 "$PY" escenario "$ROOT" > "$EVID/escenario.json" || die "no se pudo construir el escenario default"
: > "$EVID/wall.txt"

# --- una corrida = lo que hace calculaStata.php -------------------------------------------
correr() {   # correr <id> [flags de generar]
    local id="$1"; shift
    local dir="$ROOT/users/$id"
    rm -rf "$dir"; mkdir -p "$dir"
    python3 "$PY" generar "$TEMPLATE" "$dir/$id.do" "$ROOT" "$id" "$EVID/escenario.json" "$@" || die "generar $id"
    local t0 t1
    t0="$(now)"
    ( cd "$dir" && "$STATA" -b do "$id.do" >/dev/null 2>&1 )
    t1="$(now)"
    local rc=1
    grep -q "TOUCH-DOWN" "$dir/$id.log" && [[ -s "$dir/output.txt" ]] && rc=0
    [[ $rc -eq 0 ]] || { tail -40 "$dir/$id.log" >&2; die "la corrida $id no llegó al TOUCH-DOWN (ver $dir/$id.log)"; }
    local wall; wall="$(python3 -c "print('%.2f' % ($t1 - $t0))")"
    echo "$id $wall" >> "$EVID/wall.txt"
    mkdir -p "$EVID/$id"
    cp "$dir/$id.do" "$dir/$id.log" "$dir/output.txt" "$EVID/$id/"
    log "$id: ${wall}s de pared"
}

$SIN_BASE || correr perfbase
for ((i = 1; i <= RUNS; i++)); do correr "perfrun$i" --instrumentar; done

if $TRAZA; then
    correr perftraza --instrumentar --traza
    python3 "$PY" inventario "$EVID/perftraza/perftraza.log" "$EVID/inventario-io.json" "$EVID/piso-io.do" "$ROOT" perftraza || die "inventario"
    mkdir -p "$EVID/piso-io"; cp "$EVID/piso-io.do" "$EVID/piso-io/piso-io.do"
    ( cd "$EVID/piso-io" && "$STATA" -b do piso-io.do >/dev/null 2>&1 )
    log "piso de I/O medido ($EVID/piso-io/piso-io.log)"
fi

# --- compuerta: medir no mueve números ------------------------------------------------------
: > "$EVID/identicos.txt"
if ! $SIN_BASE; then
    # perftraza queda fuera: set trace ecoa los comandos dentro de cualquier log abierto
    # (Simulador hace log on output para INCD/APORT*), así que su output.txt no es comparable
    for d in "$EVID"/perfrun*; do
        [[ -f "$d/output.txt" ]] || continue
        if cmp -s "$EVID/perfbase/output.txt" "$d/output.txt"; then
            echo "$(basename "$d") output.txt byte-identico a perfbase: SI" >> "$EVID/identicos.txt"
        else
            echo "$(basename "$d") output.txt byte-identico a perfbase: NO" >> "$EVID/identicos.txt"
        fi
    done
    cat "$EVID/identicos.txt"
fi

[[ "$RUNS" -gt 0 ]] && { python3 "$PY" resumen "$EVID" "$RUNS" || die "resumen"; }
if $LIMPIAR; then
    for d in "$ROOT"/users/perfbase "$ROOT"/users/perfrun* "$ROOT"/users/perftraza; do
        [[ -d "$d" ]] && find "$d" -name '*.dta' -delete
    done
fi
grep -q ": NO" "$EVID/identicos.txt" 2>/dev/null && { log "FALLO: algún output.txt instrumentado difiere del baseline"; exit 2; }
log "listo: $EVID/resumen.md"
