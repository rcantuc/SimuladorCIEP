#!/bin/bash
# test-precache-manifest.sh — regresión del hotfix fix/precache-manifest (2026-10-31, v8.15.0).
#
# _precache_manifest.ado lee version, data_updated y baseline de 05_scripts/manifest.json sin parser
# JSON. La versión 8.12 pasaba CADA línea por regexm(`"`linea'"', ...) y Stata expandía el texto
# libre (acentos graves, comillas simples, paréntesis de *_regla y assets.<id>.regla) como macro:
# r(132) «too few quotes» en cuanto el manifest trajo «`desde` = version en que entra…» (v8.15b E4).
#
#   A. manifest de prueba con texto hostil (acentos graves, comillas simples y dobles escapadas,
#      paréntesis, "version_regla" antes de "version", "version" anidada en un asset):
#      el .ado del repo devuelve version/data_updated/baseline exactos (Stata, exit 0).
#   B. el manifest REAL del repo: r(version) = "version" del JSON (python), ídem data_updated y
#      baseline; y ninguna línea aborta.
#   C. (--con-antes) el .ado de e47a7af contra el manifest de prueba debe dar r(132): documenta
#      la regresión que este test vigila.
#
# Requiere Stata: NO va en publicar.sh --ci. Uso: bash 05_scripts/test-precache-manifest.sh [--stata <ruta>] [--con-antes]
# Exit 0 = VERDE; 1 = ROJO; 2 = no hay Stata.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
CON_ANTES=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stata) STATA="$2"; shift 2 ;;
        --con-antes) CON_ANTES=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
[[ -x "$STATA" ]] || { echo "test-precache-manifest: no encuentro Stata en $STATA (usa --stata)" >&2; exit 2; }
TMP="$(mktemp -d)"
mkdir -p "$TMP/hostil/05_scripts"
cat > "$TMP/hostil/05_scripts/manifest.json" <<'JSON'
{
  "version_regla": "no es la version: texto con 'comillas' y (paréntesis) y `acento`",
  "version": "v9.9.9",
  "data_updated": "2026-12-31",
  "data_updated_regla": "la pinta el hero como 'Última actualización' (no es deploy); `desde` = version; comillas \"escapadas\" y `"`macro`"'",
  "baseline_regla": "Tag (commit 'baseline: vX.Y.Z'); el Gate 11 exige que exista `baseline`.",
  "baseline": "v8.15.0",
  "assets": {
    "x.zip": {
      "regla": "Asset (refrescar-scn.sh --congelar): `desde` = version en que entra a la Release 'ok' (Gate 8)",
      "version": "no-es-de-primer-nivel",
      "desde": "v8.15.0"
    }
  }
}
JSON
rojo=0
correr() {   # $1 nombre, $2 SIMROOT, $3 adopath extra (vacío = el repo), $4 rc esperado
    local nombre="$1" root="$2" ado="$3" esperado="$4"
    local dir="$TMP/$nombre"; mkdir -p "$dir"
    printf 'capture set processors 1\nset linesize 200\nglobal SIMROOT "%s"\nadopath ++ "%s"\ncapture noisily _precache_manifest\ndi "rc = " _rc\ndi "version = [`r(version)'"'"']"\ndi "data_updated = [`r(data_updated)'"'"']"\ndi "baseline = [`r(baseline)'"'"']"\n' \
        "$root" "${ado:-$REPO_ROOT}" > "$dir/wrap.do"
    ( cd "$dir" && "$STATA" -b do "$dir/wrap.do" < /dev/null )
    local rc; rc="$(grep -E '^rc = ' "$dir/wrap.log" | head -1 | sed 's/rc = //')"
    if [[ "$rc" != "$esperado" ]]; then
        echo "ROJO   $nombre: rc = ${rc:-?} (esperado $esperado) — ver $dir/wrap.log"; rojo=1; return 1
    fi
    return 0
}
valor() { grep -E "^$2 = \[" "$TMP/$1/wrap.log" | head -1 | sed -E 's/^[a-z_]+ = \[(.*)\]$/\1/'; }

# --- A. manifest hostil, .ado del repo ---
if correr hostil "$TMP/hostil" "" 0; then
    v="$(valor hostil version)"; d="$(valor hostil data_updated)"; b="$(valor hostil baseline)"
    if [[ "$v" == "v9.9.9" && "$d" == "2026-12-31" && "$b" == "v8.15.0" ]]; then
        echo "OK     A. manifest hostil: version $v, data_updated $d, baseline $b (texto libre con acentos graves, comillas y paréntesis no se expande)"
    else
        echo "ROJO   A. manifest hostil: version [$v] data_updated [$d] baseline [$b] — ver $TMP/hostil/wrap.log"; rojo=1
    fi
fi

# --- B. manifest real del repo ---
if correr real "$REPO_ROOT" "" 0; then
    read -r pv pd pb < <(python3 -I -c 'import json,sys; m=json.load(open(sys.argv[1])); print(m["version"], m["data_updated"], m.get("baseline",""))' "$REPO_ROOT/05_scripts/manifest.json")
    v="$(valor real version)"; d="$(valor real data_updated)"; b="$(valor real baseline)"
    if [[ "$v" == "$pv" && "$d" == "$pd" && "$b" == "$pb" ]]; then
        echo "OK     B. manifest del repo: version $v, data_updated $d, baseline $b = json (python)"
    else
        echo "ROJO   B. manifest del repo: Stata [$v|$d|$b] vs python [$pv|$pd|$pb]"; rojo=1
    fi
fi

# --- C. el .ado de e47a7af debe fallar con r(132) sobre el manifest hostil ---
if [[ "$CON_ANTES" == "true" ]]; then
    mkdir -p "$TMP/ado-antes"
    if git -C "$REPO_ROOT" show e47a7af:_precache_manifest.ado > "$TMP/ado-antes/_precache_manifest.ado" 2>/dev/null; then
        if correr antes "$TMP/hostil" "$TMP/ado-antes" 132; then
            echo "OK     C. el .ado de e47a7af aborta con r(132) sobre el manifest hostil (la regresión que vigila este test)"
        fi
    else
        echo "SKIP   C. git show e47a7af:_precache_manifest.ado no disponible"
    fi
fi

if [[ $rojo -eq 0 ]]; then echo "test-precache-manifest: VERDE"; else echo "test-precache-manifest: ROJO"; fi
exit $rojo
