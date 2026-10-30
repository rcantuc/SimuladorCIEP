#!/usr/bin/env bash
# =============================================================================
# contrato-32.sh — el contrato de entidad para las 32 entidades, por script (v8.13a)
# =============================================================================
# UNA sesión de Stata (~35 min de SIM.do + ~1 s/entidad·paso) que deja:
#   1. la corrida nacional completa (SIM.do con global entidad = la entidad TESTIGO; el flujo
#      nacional es byte-idéntico con o sin entidad: gate de PARIDAD contra --refs);
#   2. compuertas-entidad.do: las 90 celdas dis<fam>nle<dec> de Nuevo León (testigo) y los
#      32×5 Sankeys sin banda;
#   3. contrato-32.do: para cada una de las 32 — Poblacion, PIBDeflactor (solo con base), los 5
#      Sankeys (con banda si hay vintages), ciclo-vida.json y tasas-efectivas.json — tolerante a
#      fallos, con log por entidad y tabla contrato-32.tsv;
# y después, en Python:
#   4. compuertas-entidad.py (aditividad de Sankeys Σ32 = nacional, testigo NL, sellos) y
#   5. contrato-32.py (paridad, tabla de las 32, aditividad del ciclo de vida, consistencia de las
#      tasas efectivas, sellos y concentración top-1) -> <evidencia>/contrato-32.md
#
# Uso:
#   bash 05_scripts/contrato-32.sh --evidencia <dir> [--refs <dir con output.txt y sankey-*.json de referencia>]
#        [--statajson <statajson_entidad-nl.json>] [--entidad-sesion "Nuevo León"] [--stata <ruta>] [--sin-sim]
#   --sin-sim reutiliza la sesión anterior (exige <evidencia>/escalares.do, como compuertas-entidad.sh).
#   --statajson: testigo NL; default (v8.14) 05_scripts/fixtures/statajson_entidad-nl.json (motor actual, post-v8.12.4).
#   6. (v8.13.0) generar-entidades.py meta: users/<id>/<ABREV>/meta.json (sellos con su n; PIBE y neto del
#      ciclo TRANSCRITOS de neto-pibe.json, que contrato-32.do §4b exporta con scalarjson) y
#      users/<id>/entidades.json (índice; Σ32 PIBE transcrita de entidades-pibe32.json): lo que /entidades y
#      /entidades/<ABREV> leen y lo que la Fase 3b-ter de publicar-vps.sh embarca. El vintage de las bases PIBE se
#      lee de master/PIBDeflactor<ABREV>.meta (sello de pibe-32.sh; v8.14: los .meta viven junto a los .dta en master/).
# Bases precedentes (banda de vintages y testigo): ver runbook §13 — se validan y se imprime la
# receta; si faltan, el recorrido sigue sin banda / sin testigo y lo declara.
# Pensado para correr de noche: nohup bash 05_scripts/contrato-32.sh --evidencia ~/CIEP_Simuladores/diag-... &
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
STATA="/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se"
EVID=""; REFS=""; STATAJSON=""; ENTIDAD="Nuevo León"; SIN_SIM=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --evidencia) EVID="$2"; shift 2 ;;
        --refs) REFS="$2"; shift 2 ;;
        --statajson) STATAJSON="$2"; shift 2 ;;
        --entidad-sesion) ENTIDAD="$2"; shift 2 ;;
        --stata) STATA="$2"; shift 2 ;;
        --sin-sim) SIN_SIM=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
[[ -n "$EVID" ]] || { echo "Uso: $0 --evidencia <dir> [--refs <dir>] [--statajson <json>] [--entidad-sesion <nombre>] [--stata <ruta>] [--sin-sim]" >&2; exit 2; }
[[ -x "$STATA" ]] || { echo "no encuentro Stata en $STATA (usa --stata)" >&2; exit 2; }
mkdir -p "$EVID"
ID="$(whoami)"

# --- bases precedentes: se validan, se imprime la receta, se sigue ---------------------------
echo "== Bases precedentes (runbook §13)"
FALTAN_V=()
for v in 2016 2018 2020 2022 2024; do
    [[ -f "$REPO_ROOT/users/$ID-v$v/aportaciones.dta" ]] || FALTAN_V+=("$v")
done
if (( ${#FALTAN_V[@]} )); then
    echo "  banda de vintages: NO (faltan users/$ID-v{${FALTAN_V[*]// /,}}/aportaciones.dta)."
    echo "  Receta (v8.14, runbook §13): bash 05_scripts/test-maquina-virgen.sh --download --vintages \"${FALTAN_V[*]}\" --into \"$REPO_ROOT\""
    echo "  (SIM.do con anioPE = aniovp = anioenigh = vintage y calibracion contemporanea: 05_scripts/vintage-aportaciones.do)."
else
    echo "  banda de vintages: sí (5 bases)."
fi
if [[ -z "$STATAJSON" ]]; then
    # v8.14: el testigo versionado (05_scripts/fixtures, regenerado con el motor actual por compuertas-entidad.do) es el default
    c="$REPO_ROOT/05_scripts/fixtures/statajson_entidad-nl.json"
    [[ -f "$c" ]] && STATAJSON="$c"
fi
git rev-parse --short HEAD > "$EVID/commit.txt" 2>/dev/null; git status --short >> "$EVID/commit.txt" 2>/dev/null   # compuertas-entidad.do lo escribe en la procedencia del testigo
if [[ -n "$STATAJSON" && -f "$STATAJSON" ]]; then echo "  testigo NL: $STATAJSON ($(shasum -a 256 "$STATAJSON" | cut -c1-12)…)"; else echo "  testigo NL: NO (sin --statajson; el gate 3 de compuertas-entidad.py quedará 'no verificable')"; STATAJSON=""; fi

# --- SIM_run.do: SIM.do con la raíz de este clon y los globals tras `macro drop _all` ---------
GLOBALS=('global nographs "nographs"' 'global output "output"' "global entidad \"$ENTIDAD\"")
python3 - "$REPO_ROOT/SIM.do" "$EVID/SIM_run.do" "$REPO_ROOT" "${GLOBALS[@]}" <<'PYEOF'
import re, sys
src, dst, root, *globs = sys.argv[1:]
t = open(src, encoding="utf-8").read()
t, n = re.subn(r'^global SIMROOT ".*?"', 'global SIMROOT "%s"' % root, t, count=1, flags=re.M)
if n != 1:
    sys.exit("contrato-32: no se encontro 'global SIMROOT \"...\"' en SIM.do")
marca = "macro drop _all\n"
t = t.replace(marca, marca + "".join(g + "\n" for g in globs), 1)
open(dst, "w", encoding="utf-8").write(t)
PYEOF
WRAP="$EVID/wrap-contrato-32.do"
{
    printf 'capture set processors 1\nset linesize 200\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\ndi "STATA_VERSION=" c(stata_version) " PROCESSORS=" c(processors)\n' "$REPO_ROOT" "$REPO_ROOT"
    if [[ "$SIN_SIM" == "true" ]]; then
        printf 'global SIMROOT "%s"\nglobal id "%s"\n' "$REPO_ROOT" "$ID"
        printf '%s\n' "${GLOBALS[@]}"
        printf 'do "%s/escalares.do"\n' "$EVID"
    else
        printf 'do "%s/SIM_run.do"\n' "$EVID"
    fi
    printf 'do "%s/05_scripts/compuertas-entidad.do" "%s"\n' "$REPO_ROOT" "$EVID"
    printf 'do "%s/05_scripts/contrato-32.do" "%s"\n' "$REPO_ROOT" "$EVID"
} > "$WRAP"

echo "== Stata: SIM.do (entidad testigo: $ENTIDAD) + compuertas-entidad.do + contrato-32.do → $EVID"
T0=$(date +%s)
( "$STATA" -b do "$WRAP" < /dev/null )
LOG="$REPO_ROOT/wrap-contrato-32.log"
[[ -f "$LOG" ]] && mv -f "$LOG" "$EVID/wrap-contrato-32.log"
LOG="$EVID/wrap-contrato-32.log"
echo "   Stata: $((($(date +%s)-T0)/60)) min."
if grep -qE '^r\([0-9]+\);' "$LOG"; then
    # un r() en el log puede ser de un paso capturado de contrato-32.do (tolerado) o de SIM.do (fatal)
    if [[ ! -f "$EVID/contrato-32.tsv" ]]; then
        echo "contrato-32: Stata terminó con error ANTES de la tabla de las 32; ver $LOG" >&2
        grep -B6 -E '^r\([0-9]+\);' "$LOG" | head -30 >&2
        exit 1
    fi
    echo "   (hubo r() capturados en el recorrido: están en contrato-32.tsv y en entidades/<ABREV>.log)"
fi

# --- Python: compuertas de los Sankeys (reuso) y consolidación de las 32 ----------------------
ABREV="$(python3 - "$ENTIDAD" <<'PYEOF'
import sys
L=["Aguascalientes","Baja California","Baja California Sur","Campeche","Coahuila","Colima","Chiapas","Chihuahua","Ciudad de México","Durango","Guanajuato","Guerrero","Hidalgo","Jalisco","Estado de México","Michoacán","Morelos","Nayarit","Nuevo León","Oaxaca","Puebla","Querétaro","Quintana Roo","San Luis Potosí","Sinaloa","Sonora","Tabasco","Tamaulipas","Tlaxcala","Veracruz","Yucatán","Zacatecas"]
C="Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac".split()
print(C[L.index(sys.argv[1])])
PYEOF
)"
echo "== compuertas-entidad.py (Sankeys: aditividad Σ32, testigo NL, sellos)"
BANDA="sesion"; (( ${#FALTAN_V[@]} == 0 )) && BANDA="todas"   # contrato-32.do calcula la banda para las 32 si hay vintages
python3 05_scripts/compuertas-entidad.py --root "$REPO_ROOT" --id "$ID" --evidencia "$EVID" --testigo "$ABREV" --banda "$BANDA" ${STATAJSON:+--statajson "$STATAJSON"} > "$EVID/compuertas-entidad.out" 2>&1
RC_CE=$?
grep -A3 "## Veredicto" "$EVID/compuertas-entidad.md" 2>/dev/null | tail -2
echo "== contrato-32.py (paridad, tabla de las 32, ciclo de vida, tasas efectivas, sellos)"
python3 05_scripts/contrato-32.py --root "$REPO_ROOT" --id "$ID" --evidencia "$EVID" ${REFS:+--refs "$REFS"}
RC_C32=$?
echo "== generar-entidades.py meta (sellos y neto/PIBE por entidad → users/$ID/<ABREV>/meta.json + entidades.json; lo lee /entidades)"
python3 05_scripts/generar-entidades.py meta --users "$REPO_ROOT/users/$ID" --tabla-md "$EVID/contrato-32.md"
RC_META=$?
echo "== reporte: $EVID/contrato-32.md"
exit $(( RC_CE != 0 || RC_C32 != 0 || RC_META != 0 ? 1 : 0 ))
