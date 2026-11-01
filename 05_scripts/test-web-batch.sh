#!/usr/bin/env bash
# =============================================================================
# test-web-batch.sh — paridad web/batch del «Calcular» default (FLAG-5, v8.14)
# =============================================================================
# El sitio arma el escenario default con users/ricardo/output.txt (lo que escribió SIM.do con
# nographs + output) y Web.Stata.do lo devuelve al motor como {{llaves}}. La promesa es que ese
# «Calcular» default reproduce EXACTAMENTE el output.txt del batch: las 47 llaves que publica
# output.do, idénticas como cadena. En v8.12.4 diferían 5 (CRECPIB/CRECDEF redondeados a un decimal,
# la tasa efectiva a tres, y el `if k != 0` de SIM.do §7 que el web no tenía). SIM.do es canónico;
# el web se alinea; este gate lo mide.
#
# Qué hace (lo mismo que calculaStata.php, sin PHP; receta de perfilar-web.sh):
#   1. escenario.json = el formulario default leído de <root>/users/ricardo/output.txt
#      (perfilar-web.py escenario: mismo mapeo que stataCalcula.js y mismo lee_numero del PHP);
#   2. <root>/users/<id>/<id>.do = Web.Stata.do con las {{llaves}} sustituidas en el orden del PHP
#      (perfilar-web.py generar) y el SITE apuntando a <root>;
#   3. cd users/<id> && stata -b do <id>.do  (TOUCH-DOWN obligatorio);
#   4. compara users/<id>/output.txt con users/ricardo/output.txt llave por llave (misma unión de
#      continuaciones que cargaDefault.php): mismo conjunto de llaves y cada vector idéntico como
#      cadena. Escribe <evidencia>/test-web-batch.md con la tabla (llave, posiciones distintas,
#      Δ relativo máximo).
#
# Uso: bash 05_scripts/test-web-batch.sh [--root <clon con master/, raw/, users/ricardo/>] [--id <usuario web>]
#        [--stata <ruta stata-se>] [--evidencia <dir>] [--conservar]
#   --root       default: este clon. Exige users/ricardo/{output.txt, bootstraps/<B>/*RECprom.dta, cache/sello.txt}
#                y master/ (una corrida completa de SIM.do, como la del ritual).
#   --id         usuario de la corrida web (default webbatch); se borra al final salvo --conservar.
#   --evidencia  default <root>/users/_perf/test-web-batch-<fecha>/.
# Exit 0 = 47/47 llaves idénticas (46 + CUADRATURA desde v8.15.0; v8.15.1: Web.Stata.do §7.3 carga master/<anioenigh>/cuadratura.do); 1 = alguna difiere o la corrida no llegó al TOUCH-DOWN; 2 = faltan insumos.
# Gate de sesión (runbook §11): necesita Stata; no corre en CI.
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || dirname "$HERE")"
ROOT="$REPO_ROOT"; ID="webbatch"; EVID=""; CONSERVAR=false
STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root) ROOT="$2"; shift 2 ;;
        --id) ID="$2"; shift 2 ;;
        --stata) STATA="$2"; shift 2 ;;
        --evidencia) EVID="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
ROOT="$(cd "$ROOT" && pwd)"
PY="$HERE/perfilar-web.py"
TEMPLATE="$ROOT/01_modulos/Web.Stata.do"
die() { echo "test-web-batch: $*" >&2; exit 2; }
[[ -x "$STATA" ]] || die "no hay Stata en $STATA (usa --stata o la variable STATA)"
[[ -f "$TEMPLATE" ]] || die "no existe $TEMPLATE"
[[ -f "$ROOT/master/LIF.dta" && -f "$ROOT/master/perfiles2027.dta" ]] || die "falta master/ en $ROOT (LIF.dta, perfiles2027.dta): corre SIM.do completo primero"
BATCH="$ROOT/users/ricardo/output.txt"
[[ -s "$BATCH" ]] || die "falta $BATCH (el output.txt del batch; SIM.do con nographs + output)"
B_WEB="$(sed -nE 's/^global bootstrap "([0-9]+)".*/\1/p' "$TEMPLATE" | head -1)"
N_PROM="$(find "$ROOT/users/ricardo/bootstraps/${B_WEB:-250}" -maxdepth 1 -name '*RECprom.dta' 2>/dev/null | wc -l | tr -d ' ')"
[[ "$N_PROM" -gt 0 ]] || die "no hay $ROOT/users/ricardo/bootstraps/${B_WEB:-250}/*RECprom.dta (escenario base de FiscalGap)"
[[ -f "$ROOT/users/ricardo/cache/sello.txt" ]] || die "no hay $ROOT/users/ricardo/cache/sello.txt (Precache, SIM.do §5.1b)"
[[ "$ID" != "ricardo" ]] || die "--id no puede ser ricardo (es el batch de referencia)"
[[ -z "$EVID" ]] && EVID="$ROOT/users/_perf/test-web-batch-$(date +%Y-%m-%d)"
mkdir -p "$EVID"
log() { echo "[test-web-batch $(date +%H:%M:%S)] $*"; }
log "root=$ROOT  id=$ID  evidencia=$EVID  RECprom=$N_PROM  stata=$STATA"

python3 "$PY" escenario "$BATCH" > "$EVID/escenario.json" || die "no se pudo construir el escenario default desde $BATCH"
DIR="$ROOT/users/$ID"
rm -rf "$DIR"; mkdir -p "$DIR"
python3 "$PY" generar "$TEMPLATE" "$DIR/$ID.do" "$ROOT" "$ID" "$EVID/escenario.json" || die "generar $ID"
T0=$(date +%s)
( cd "$DIR" && "$STATA" -b do "$ID.do" < /dev/null >/dev/null 2>&1 )
WALL=$(( $(date +%s) - T0 ))
cp "$DIR/$ID.do" "$DIR/$ID.log" "$EVID/" 2>/dev/null
if ! grep -q "TOUCH-DOWN" "$DIR/$ID.log" || [[ ! -s "$DIR/output.txt" ]]; then
    echo "ROJO   la corrida web no llegó al TOUCH-DOWN (${WALL}s); ver $EVID/$ID.log" >&2
    grep -B4 -E '^r\([0-9]+\);' "$DIR/$ID.log" | head -12 >&2
    exit 1
fi
cp "$DIR/output.txt" "$EVID/output-web.txt"; cp "$BATCH" "$EVID/output-batch.txt"
log "corrida web: ${WALL}s de pared; comparando con el batch"

python3 - "$EVID/output-batch.txt" "$EVID/output-web.txt" "$EVID/test-web-batch.md" "$WALL" <<'PYEOF' || exit 1
import re, sys
pb, pw, md, wall = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
def leer(path):
    """output.txt (log de Stata) -> {LLAVE: [valores como cadena]} con la misma unión de continuaciones '\\n> ' que cargaDefault.php."""
    t = open(path, encoding='utf-8', errors='replace').read()
    t = re.sub(r'\n>\s*', '', t)
    d = {}
    for linea in t.split('\n'):
        linea = linea.strip()
        if not linea or linea.startswith('.') or ':' not in linea:
            continue
        k, v = linea.split(':', 1)
        v = v.strip()
        m = re.match(r'^\[(.*)\]$', v, re.S)
        d[k.strip()] = [x.strip() for x in m.group(1).split(',')] if m else [v]   # la última aparición gana (cargaDefault.php)
    return d
b, w = leer(pb), leer(pw)
filas, rojo = [], False
llaves = sorted(set(b) | set(w))
for k in llaves:
    if k not in w: filas.append((k, 'solo en batch', '', '')); rojo = True; continue
    if k not in b: filas.append((k, 'solo en web', '', '')); rojo = True; continue
    if b[k] == w[k]: filas.append((k, 'idéntica', '', '')); continue
    rojo = True
    pos = [i for i, (x, y) in enumerate(zip(b[k], w[k])) if x != y]
    if len(b[k]) != len(w[k]): pos.append('n:%d/%d' % (len(b[k]), len(w[k])))
    drel = 0.0
    for i in [p for p in pos if isinstance(p, int)]:
        try:
            x, y = float(b[k][i]), float(w[k][i]); drel = max(drel, abs(y - x) / abs(x) if x else (0.0 if y == 0 else float('inf')))
        except ValueError: drel = float('inf')
    filas.append((k, 'DISTINTA', ','.join(str(p + 1) if isinstance(p, int) else p for p in pos), '%.2e' % drel))
ident = sum(1 for f in filas if f[1] == 'idéntica')
L = ['# test-web-batch — paridad web/batch del «Calcular» default (FLAG-5)', '',
     f'Batch: `{pb}`  ·  Web: `{pw}`  ·  corrida web: {wall} s', '',
     f'**{ident}/{len(llaves)} llaves idénticas como cadena** ({"VERDE" if not rojo else "ROJO"}).', '',
     '| llave | resultado | posiciones distintas (1-based) | Δ rel máx |', '|---|---|---|---:|']
L += [f'| {k} | {r} | {p} | {d} |' for k, r, p, d in filas]
open(md, 'w', encoding='utf-8').write('\n'.join(L) + '\n')
for k, r, p, d in filas:
    if r != 'idéntica': print(f'ROJO   {k}: {r} {p} {d}')
print(f'{"ROJO  " if rojo else "OK    "} {ident}/{len(llaves)} llaves de output.txt idénticas web vs batch (tabla: {md})')
sys.exit(1 if rojo else 0)
PYEOF
RC=$?
$CONSERVAR || rm -rf "$DIR"
if (( RC == 0 )); then echo "RESULTADO: test-web-batch VERDE (el «Calcular» default reproduce el output.txt del batch)"; else echo "RESULTADO: test-web-batch ROJO (ver $EVID/test-web-batch.md)"; fi
exit $RC
