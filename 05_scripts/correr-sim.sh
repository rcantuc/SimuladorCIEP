#!/usr/bin/env bash
# =============================================================================
# correr-sim.sh — SIM.do completo (nographs + output) sobre un clon y snapshot de sus salidas (8.18a-1)
# =============================================================================
# Es el correr-sim.sh que cada sesión copiaba a su carpeta diag-* desde REPRO-FIX (2026-10-29), ahora
# versionado: el paso `sim` de ritual.sh lo llama y la evidencia ya no depende de una copia suelta. Mismo
# comportamiento que la copia de diag-v8.15.1-2026-11-01; lo único que cambia es que la carpeta de
# evidencia es un argumento (antes era la ruta fija de la sesión + <nombre>).
#
#   1. SIM_run.do = SIM.do con `global SIMROOT` = <root>; `global nographs`/`global output` tras
#      `macro drop _all` (antes de §0.7, que abre el log output) y los globals extra tras los defaults
#      de §0.8 (así `global cap4 "fuera"` manda; `global hasta "3"` corta tras PerfilesSim);
#   2. wrap.do: set processors 1, SITE = <root>, y `do SIM_run.do` en batch (StataNow SE);
#   3. copia a la evidencia output.txt, SankeySF/ (5), SankeyNTA/ (5), NTA/, sha256.txt, commit.txt
#      (hash corto + `git status --short`), tiempo.txt, households-sumas.txt (Σ expandidas, para el Δ);
#   4. gate-numeros.sh sobre users/ricardo → gate-numeros.txt (no decide: ritual.sh lo re-corre y lee el exit).
#
# Uso: bash 05_scripts/correr-sim.sh <root> <evidencia> [global ...]
#   <root>       clon con master/, raw/, set_token.do (sin set_token.do SIM.do aborta al instante)
#   <evidencia>  carpeta de salida (se crea); en el ritual, ~/CIEP_Simuladores/diag-<v>-<fecha>/01-ritual
#   global ...   líneas literales, p. ej. 'global cap4 "fuera"'
# Stata: variable STATA (default StataNow SE). ~33 min; ~4.8 GB en users/. Máximo 3 a la vez (memoria
# corridas-worktree-desechable: con 4 sube a 55 min).
# =============================================================================
set -uo pipefail
[[ $# -ge 2 ]] || { echo "Uso: $0 <root> <evidencia> [global ...]" >&2; exit 2; }
ROOT="$(cd "$1" && pwd)" || exit 2
EVID="$2"; shift 2
STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
[[ -x "$STATA" ]] || { echo "correr-sim: no encuentro Stata en $STATA (usa la variable STATA)" >&2; exit 2; }
[[ -f "$ROOT/SIM.do" ]] || { echo "correr-sim: no hay $ROOT/SIM.do" >&2; exit 2; }
mkdir -p "$EVID"
EVID="$(cd "$EVID" && pwd)"
cd "$ROOT" || exit 2
git rev-parse --short HEAD > "$EVID/commit.txt"; git status --short >> "$EVID/commit.txt"
printf '%s\n' "$@" > "$EVID/globals-extra.txt"
python3 - "$ROOT/SIM.do" "$EVID/SIM_run.do" "$ROOT" 'global nographs "nographs"' 'global output "output"' "$@" <<'PYEOF'
import re, sys
src, dst, root, *globs = sys.argv[1:]
t = open(src, encoding="utf-8").read()
t, n = re.subn(r'^global SIMROOT ".*?"', 'global SIMROOT "%s"' % root, t, count=1, flags=re.M)
assert n == 1
# nographs/output van tras `macro drop _all` (antes de §0.7, que abre el log output); los globals extra (parámetros
# CUAD-0, hasta) van tras §0.8, después de los defaults, para que el valor alterno mande sobre el default
base = [g for g in globs if g.startswith(('global nographs', 'global output'))]
extra = [g for g in globs if g not in base]
marca0 = "macro drop _all\n"
t = t.replace(marca0, marca0 + "".join(g + "\n" for g in base), 1)
marca = 'global oye_en_hub "off"'
i = t.index(marca); j = t.index('\n', i) + 1
t = t[:j] + "".join(g + "\n" for g in extra) + t[j:]
open(dst, "w", encoding="utf-8").write(t)
PYEOF
printf 'capture set processors 1\nset linesize 200\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\ndi "STATA_VERSION=" c(stata_version) " PROCESSORS=" c(processors)\ndo "%s/SIM_run.do"\n' "$ROOT" "$ROOT" "$EVID" > "$EVID/wrap.do"
T0=$(date +%s)
( cd "$EVID" && "$STATA" -b "do" "$EVID/wrap.do" < /dev/null )
echo "Stata: $((($(date +%s)-T0)/60)) min" | tee "$EVID/tiempo.txt"
grep -E '^r\([0-9]+\);' "$EVID/wrap.log" | head -3 >> "$EVID/tiempo.txt"
U="$ROOT/users/ricardo"
cp "$U/output.txt" "$EVID/" 2>/dev/null
mkdir -p "$EVID/SankeySF" "$EVID/SankeyNTA"
cp "$U"/sankey-*.json "$EVID/SankeySF/" 2>/dev/null
cp "$U"/SankeyNTA/sankey-*.json "$EVID/SankeyNTA/" 2>/dev/null
[[ -d "$U/NTA" ]] && cp -R "$U/NTA" "$EVID/NTA"
shasum -a 256 "$EVID"/output.txt "$EVID"/SankeySF/*.json "$EVID"/SankeyNTA/*.json > "$EVID/sha256.txt" 2>/dev/null
# resumen de Households.do (sumas expandidas de la base recién escrita) para el Δ; informativo: sin pandas no se escribe
python3 -I - "$ROOT/master/2024/households.dta" "$EVID/households-sumas.txt" <<'PYEOF' || echo "correr-sim: households-sumas.txt no se escribió (informativo)" >&2
import sys, pandas as pd
p, out = sys.argv[1:3]
vs = 'Yl Yk ing_subor ing_mixto ing_mixtoL ing_mixtoK ing_capital ing_estim_alqu ing_t4_cap3 ing_remesas ing_t4_cap1 ing_t4_cap4 ing_jubila gasto_anualDepreciacion ingbrutotot ISR isrE ISR_asalariados ISR_PF ISR_PM cuotasTPF ImpNetProductos ImpNetProduccion ing_d4_rel'.split()
d = pd.read_stata(p, columns=vs + ['factor'], convert_categoricals=False)
with open(out, 'w') as f:
    for v in vs:
        f.write('%-26s %18.3f\n' % (v, float((d[v].fillna(0) * d.factor).sum()) / 1e9))
print(open(out).read())
PYEOF
if [[ -f "$U/output.txt" ]]; then bash "$ROOT/05_scripts/gate-numeros.sh" "$U" | tee "$EVID/gate-numeros.txt"; fi
cat "$EVID/tiempo.txt"
