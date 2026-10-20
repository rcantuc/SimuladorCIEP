#!/usr/bin/env bash
# =============================================================================
# pibe-32.sh — las 32 bases master/PIBDeflactor<ABREV>.dta, con la receta de Ricardo (v8.13a-2)
# =============================================================================
# Una sesión de Stata (las tablas BIE por área se bajan UNA vez y sirven a las 32: vintage
# uniforme) que recorre el catálogo SIMentidad e invoca, por entidad,
#     PIBDeflactor if entidad == "<nombre>", update ...      (la receta; no se toca)
# con pausa entre entidades (cortesía con la API de INEGI), tolerante a fallos (rc por entidad,
# log por entidad). Después:
#   1. segunda sesión solo con las entidades que no quedaron frescas (reintento, una vez);
#   2. pibe-32.py sellar  -> master/PIBDeflactor<ABREV>.meta (serie, estructura, fecha de consulta,
#                            último periodo, n) + sellos.tsv;
#   3. sellar-pibe-32.do  -> el mismo sello como `char _dta[sello_*]` dentro de cada .dta;
#   4. pibe-32.py reporte -> pibe-32.md: tabla de las 32, diff de las bases previas, SHA y tamaño.
# Antes de pisar bases existentes, las copia a <evidencia>/bases-previas/ (nunca se borran aquí).
# El token (set_token.do, gitignored) se carga dentro de Stata: no se imprime ni se escribe en la
# evidencia (el wrapper de Stata solo hace `run set_token.do`).
#
# Uso:
#   bash 05_scripts/pibe-32.sh --evidencia <dir> [--entidades "NL Jal"] [--pausa 5] [--sin-reintento] [--stata <ruta>]
# Pensado para correr de noche: nohup bash 05_scripts/pibe-32.sh --evidencia ~/CIEP_Simuladores/diag-... &
# Prerrequisitos: python3 con requests y pandas; Stata con Python (los de AccesoBIE).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
STATA="/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se"
EVID=""; SOLO=""; PAUSA=5; REINTENTO=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --evidencia) EVID="$2"; shift 2 ;;
        --entidades) SOLO="$2"; shift 2 ;;
        --pausa) PAUSA="$2"; shift 2 ;;
        --sin-reintento) REINTENTO=false; shift ;;
        --stata) STATA="$2"; shift 2 ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
[[ -n "$EVID" ]] || { echo "Uso: $0 --evidencia <dir> [--entidades \"NL Jal\"] [--pausa 5] [--sin-reintento] [--stata <ruta>]" >&2; exit 2; }
[[ -x "$STATA" ]] || { echo "no encuentro Stata en $STATA (usa --stata)" >&2; exit 2; }
mkdir -p "$EVID/entidades" "$EVID/bases-previas"
ID="$(whoami)"
PY=(python3 "$REPO_ROOT/05_scripts/pibe-32.py" --root "$REPO_ROOT" --evidencia "$EVID")

echo "== Compuerta de arranque"
"${PY[@]}" gate 2>&1 | tee "$EVID/compuerta-arranque.txt" || { echo "pibe-32: la compuerta de arranque falló; no se corre nada." >&2; exit 1; }

# --- primera pasada: respalda las bases existentes y fija el inicio (frescura = mtime >= inicio) ---
if [[ ! -f "$EVID/inicio-epoch.txt" ]]; then
    for f in "$REPO_ROOT"/master/PIBDeflactor[A-Z]*.dta; do
        [[ -f "$f" ]] && cp -pn "$f" "$EVID/bases-previas/"
    done
    ( cd "$EVID/bases-previas" && shasum -a 256 *.dta > SHA256.txt 2>/dev/null )
    date +%s > "$EVID/inicio-epoch.txt"
    echo "   bases previas respaldadas: $(ls "$EVID/bases-previas"/*.dta 2>/dev/null | wc -l | tr -d ' ') (en $EVID/bases-previas)"
fi

corre() {  # $1 = lista de abreviaturas ("" = las 32), $2 = etiqueta de la pasada
    local W="$EVID/wrap-pibe-32-$2.do"
    {
        printf 'capture set processors 1\nset linesize 200\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\n' "$REPO_ROOT" "$REPO_ROOT"
        printf 'global SIMROOT "%s"\nglobal id "%s"\nrun "%s/set_token.do"\n' "$REPO_ROOT" "$ID" "$REPO_ROOT"
        printf 'di "STATA_VERSION=" c(stata_version)\n'
        printf 'do "%s/05_scripts/pibe-32.do" "%s" "%s" %s\n' "$REPO_ROOT" "$EVID" "$1" "$PAUSA"
    } > "$W"
    ( "$STATA" -b do "$W" < /dev/null )
    [[ -f "$REPO_ROOT/wrap-pibe-32-$2.log" ]] && mv -f "$REPO_ROOT/wrap-pibe-32-$2.log" "$EVID/wrap-pibe-32-$2.log"
}

echo "== Stata: PIBDeflactor × ${SOLO:-32} entidades (pausa ${PAUSA} s) → $EVID"
T0=$(date +%s)
corre "$SOLO" pasada1
echo "   pasada 1: $((($(date +%s)-T0)/60)) min $((($(date +%s)-T0)%60)) s."

if [[ "$REINTENTO" == "true" ]]; then
    FALLAN="$("${PY[@]}" fallidas)"
    if [[ -n "$SOLO" ]]; then  # con subconjunto, solo se reintentan las pedidas
        F2=""; for x in $FALLAN; do [[ " $SOLO " == *" $x "* ]] && F2="$F2 $x"; done; FALLAN="${F2# }"
    fi
    if [[ -n "$FALLAN" ]]; then
        echo "== Reintento (una vez) de: $FALLAN"
        corre "$FALLAN" pasada2
    fi
fi
echo "   Stata total: $((($(date +%s)-T0)/60)) min."

echo "== Sellos (.meta + char _dta[sello_*])"
"${PY[@]}" sellar | tail -40
SEL="$EVID/wrap-sellar.do"
printf 'sysdir set SITE "%s/"\nadopath ++SITE\nglobal SIMROOT "%s"\ndo "%s/05_scripts/sellar-pibe-32.do"\n' "$REPO_ROOT" "$REPO_ROOT" "$REPO_ROOT" > "$SEL"
( "$STATA" -b do "$SEL" < /dev/null )
[[ -f "$REPO_ROOT/wrap-sellar.log" ]] && mv -f "$REPO_ROOT/wrap-sellar.log" "$EVID/wrap-sellar.log"
tail -3 "$EVID/wrap-sellar.log"

echo "== Reporte"
"${PY[@]}" reporte
RC=$?
echo "== $EVID/pibe-32.md (rc=$RC; 0 = 32/32 frescas con sello)"
exit $RC
