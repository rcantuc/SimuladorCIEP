#!/usr/bin/env bash
# gate-numeros.sh — el gate de números declarado en v8.12.0, como script con baseline versionado.
#
# Contrato (CHANGELOG v8.12.0, «Correcciones — sankeys con orden de acumulación determinista»):
#   1. users/<id>/output.txt del batch default (SIM.do con nographs + output) BYTE-IDÉNTICO al baseline;
#   2. los 5 sankey-*.json del sistema fiscal (SankeySF) y los 5 de SankeyNTA/ dentro de 1e-9 relativo
#      por enlace (mismo número de enlaces, mismos pares from→to).
# Baseline: 05_scripts/fixtures/output-default.txt (ya era la copia del output.txt publicado: lo usa
# test-sitio-transitorios.sh como Stata falso) y 05_scripts/fixtures/sankeys-default/{SankeySF,SankeyNTA}/.
# Se actualiza SOLO en una «corrección de datos» declarada en el CHANGELOG, con commit propio
# ("baseline: vX.Y.Z …"); un refactor que lo ponga ROJO es una regresión.
#
# Uso: bash 05_scripts/gate-numeros.sh [<dir con output.txt, sankey-*.json y SankeyNTA/>]
#      default: users/<usuario>/ del repo. Exit 0 = VERDE; 1 = ROJO; 2 = faltan archivos.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$REPO_ROOT/users/$(whoami)}"
FIX="$REPO_ROOT/05_scripts/fixtures"
rojo=0
[[ -f "$DIR/output.txt" ]] || { echo "gate-numeros: no existe $DIR/output.txt" >&2; exit 2; }
if cmp -s "$FIX/output-default.txt" "$DIR/output.txt"; then
    echo "OK     output.txt byte-idéntico al baseline ($(wc -c < "$DIR/output.txt" | tr -d ' ') bytes)"
else
    n=$(diff "$FIX/output-default.txt" "$DIR/output.txt" | grep -c '^>')
    echo "ROJO   output.txt difiere del baseline: $n línea(s) distintas (diff $FIX/output-default.txt $DIR/output.txt)"
    rojo=1
fi
python3 - "$FIX/sankeys-default" "$DIR" <<'PYEOF' || rojo=1
import re, sys, os
base, d = sys.argv[1], sys.argv[2]
def links(p):
    t = open(p, encoding='utf-8').read()
    return {(m[2], m[0]): float(m[1]) for m in re.findall(r'\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"\}', t)}
rojo = False
for fam, sub in (('SankeySF', ''), ('SankeyNTA', 'SankeyNTA/')):
    for k in ('decil', 'grupoedad', 'sexo', 'rural', 'escol'):
        pb, pd = f'{base}/{fam}/sankey-{k}.json', f'{d}/{sub}sankey-{k}.json'
        if not os.path.exists(pb): print(f'ROJO   falta el baseline {pb}'); rojo = True; continue
        if not os.path.exists(pd): print(f'ROJO   falta {pd}'); rojo = True; continue
        a, b = links(pb), links(pd)
        if set(a) != set(b):
            print(f'ROJO   {fam}/{k}: enlaces distintos ({len(a)} baseline, {len(b)} corrida; {len(set(a) ^ set(b))} no coinciden)'); rojo = True; continue
        mx = max((abs(b[e] - a[e]) / abs(a[e]) if a[e] else (0.0 if b[e] == 0 else float('inf'))) for e in a)
        mov = sum(1 for e in a if (abs(b[e] - a[e]) / abs(a[e]) if a[e] else (0.0 if b[e] == 0 else float('inf'))) > 1e-9)
        if mov: print(f'ROJO   {fam}/{k}: {mov} de {len(a)} enlaces fuera de 1e-9 (Δ rel. máx {mx:.3e})'); rojo = True
        else: print(f'OK     {fam}/{k}: {len(a)} enlaces dentro de 1e-9 (Δ rel. máx {mx:.1e})')
sys.exit(1 if rojo else 0)
PYEOF
if (( rojo )); then echo "RESULTADO: gate de números ROJO (los números publicados cambiaron respecto al baseline)"; exit 1; fi
echo "RESULTADO: gate de números VERDE (output.txt byte-idéntico; 10 sankeys dentro de 1e-9)"
