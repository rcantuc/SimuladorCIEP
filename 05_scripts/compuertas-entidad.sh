#!/usr/bin/env bash
# compuertas-entidad.sh — compuertas de salida 2–4 del PR global entidad (2026-10-10).
#
# Corre SIM.do con un SIM-local.do temporal {nographs, output, fuentes = la del ancla,
# entidad = <nombre>} sobre ESTE clon (usa sus master/, raw/ y users/<id>/ existentes;
# no es la receta desde estado cero: esa es --reproducibilidad), y en la MISMA sesión
# de Stata corre 05_scripts/compuertas-entidad.do (32 entidades × 5 cortes + celdas NL).
# Después compuertas-entidad.py compara los JSON y escribe <evidencia>/compuertas-entidad.md.
#
# Uso: bash 05_scripts/compuertas-entidad.sh --evidencia <dir> [--entidad "Nuevo León"]
#        [--statajson <users/.../statajson_entidad-nl.json>] [--stata <ruta stata-se>]
#        [--sin-sim]   (reutiliza la sesión: solo compuertas-entidad.do + .py; exige un
#                       escalares.do en <evidencia> con los escalares de SIM.do — desarrollo)
# Exit 0 si todo pasa.
set -uo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
[[ -z "$REPO_ROOT" ]] && { echo "No se pudo detectar root del repo Git." >&2; exit 1; }
cd "$REPO_ROOT"
EVID=""; ENTIDAD="Nuevo León"; STATAJSON=""; SIN_SIM=false
STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --evidencia) EVID="$2"; shift 2 ;;
        --entidad) ENTIDAD="$2"; shift 2 ;;
        --statajson) STATAJSON="$2"; shift 2 ;;
        --stata) STATA="$2"; shift 2 ;;
        --sin-sim) SIN_SIM=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 1 ;;
    esac
done
[[ -z "$EVID" ]] && { echo "Uso: $0 --evidencia <dir> [--entidad <nombre>] [--statajson <json>] [--stata <ruta>] [--sin-sim]" >&2; exit 1; }
mkdir -p "$EVID"
ID="$(whoami)"
FUENTES="$(python3 -c "import json;print(json.load(open('05_scripts/ancla-reproducibilidad.json')).get('fuentes',''))")"
if [[ -f SIM-local.do ]]; then cp SIM-local.do "$EVID/SIM-local.do.bak"; fi
cat > SIM-local.do <<EOF2
global nographs "nographs"
global output "output"
global fuentes "$FUENTES"
global entidad "$ENTIDAD"
EOF2
ABREV="$(python3 - "$ENTIDAD" <<'PYEOF'
import sys
L=["Aguascalientes","Baja California","Baja California Sur","Campeche","Coahuila","Colima","Chiapas","Chihuahua","Ciudad de México","Durango","Guanajuato","Guerrero","Hidalgo","Jalisco","Estado de México","Michoacán","Morelos","Nayarit","Nuevo León","Oaxaca","Puebla","Querétaro","Quintana Roo","San Luis Potosí","Sinaloa","Sonora","Tabasco","Tamaulipas","Tlaxcala","Veracruz","Yucatán","Zacatecas"]
C="Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac".split()
print(C[L.index(sys.argv[1])])
PYEOF
)"
WRAP="$EVID/wrap-compuertas.do"
{
    printf 'capture set processors 1\nset linesize 200\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\ndi "STATA_VERSION=" c(stata_version) " PROCESSORS=" c(processors)\n' "$REPO_ROOT" "$REPO_ROOT"
    if [[ "$SIN_SIM" == "true" ]]; then
        printf 'SIMroot\nglobal id "%s"\nrun "%s/SIM-local.do"\ndo "%s/escalares.do"\n' "$ID" "$REPO_ROOT" "$EVID"
    else
        printf 'do "%s/SIM.do"\n' "$REPO_ROOT"
    fi
    printf 'do "%s/05_scripts/compuertas-entidad.do" "%s"\n' "$REPO_ROOT" "$EVID"
} > "$WRAP"
echo "Stata: SIM.do (entidad $ENTIDAD, fuentes $FUENTES) + compuertas-entidad.do → $EVID (~30 min)..."
T0=$(date +%s)
( "$STATA" -b do "$WRAP" < /dev/null )
LOG="$REPO_ROOT/wrap-compuertas.log"
[[ -f "$LOG" ]] && mv -f "$LOG" "$EVID/wrap-compuertas.log"
LOG="$EVID/wrap-compuertas.log"
if grep -qE '^r\([0-9]+\);' "$LOG"; then
    echo "compuertas-entidad: Stata terminó con error; ver $LOG" >&2
    grep -B6 -E '^r\([0-9]+\);' "$LOG" | head -30 >&2
    [[ -f "$EVID/SIM-local.do.bak" ]] && mv -f "$EVID/SIM-local.do.bak" SIM-local.do
    exit 1
fi
[[ -f "$EVID/SIM-local.do.bak" ]] && mv -f "$EVID/SIM-local.do.bak" SIM-local.do
echo "Stata: $((($(date +%s)-T0)/60)) min. Verificando JSON..."
python3 05_scripts/compuertas-entidad.py --root "$REPO_ROOT" --id "$ID" --evidencia "$EVID" --testigo "$ABREV" ${STATAJSON:+--statajson "$STATAJSON"}
