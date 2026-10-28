#!/usr/bin/env bash
# test-nta-identidad.sh — gate de sesión de la cuenta NTA por individuo (NTA-1, 2026-10-27).
#
# Dos mitades:
#   A. Stata (test-nta-identidad.do): identidad C − YL − (τ⁺ − τ⁻) − (YA − S) − intra = 0 por grupo de edad y por
#      quinquenio × sexo (1e-9 relativo), Σ intra-hogar = 0 (nacional y por hogar), Σ S = AhorroHog (B.8n S.14) y
#      el JSON por grupo igual a la base. Requiere Stata y master/SCN.dta: por eso NO va en publicar.sh --ci
#      (runbook §11: gate de sesión).
#   B. Python (sin Stata): el Sankey v2 (users/<id>/SankeyNTA/sankey-v2-grupoedad.json) conserva flujo en TODO nodo
#      intermedio (entradas = salidas a 1e-9 relativo), no tiene enlaces negativos ni duplicados, los nodos de grupo
#      (Ingreso <g>, Consumo <g>) balancean, y se imprime el conteo nodos/enlaces (contrato nuevo, aparte del 31/79 de v1).
#
# Uso: bash 05_scripts/test-nta-identidad.sh [--dir <users/<id>>] [--stata <ruta stata-se>] [--sin-stata]
#      Exit 0 = VERDE; 1 = ROJO; 2 = faltan archivos.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$REPO_ROOT/users/$(whoami)"
STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
SIN_STATA=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir) DIR="$2"; shift 2 ;;
        --stata) STATA="$2"; shift 2 ;;
        --sin-stata) SIN_STATA=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
ID="$(basename "$DIR")"
DTA="$DIR/NTA/nta-persona.dta"
JSON="$DIR/SankeyNTA/sankey-v2-grupoedad.json"
[[ -f "$DTA" ]] || { echo "test-nta-identidad: no existe $DTA (corre SIM.do hasta §3 o NTA.do)" >&2; exit 2; }
[[ -f "$JSON" ]] || { echo "test-nta-identidad: no existe $JSON" >&2; exit 2; }
rojo=0

# --- A. Stata --------------------------------------------------------------------------------
if [[ "$SIN_STATA" == "false" ]]; then
    if [[ ! -x "$STATA" ]]; then
        echo "test-nta-identidad: no encuentro Stata en $STATA (usa --stata o --sin-stata)" >&2; exit 2
    fi
    TMP="$(mktemp -d)"
    printf 'capture set processors 1\nset linesize 200\nglobal SIMROOT "%s"\nadopath ++ "${SIMROOT}"\ncapture run "${SIMROOT}/set_token.do"\nglobal id "%s"\nscalar aniovp = 2024\nscalar anioenigh = 2024\nset scheme ciep\ndo "${SIMROOT}/05_scripts/test-nta-identidad.do" "%s"\n' "$REPO_ROOT" "$ID" "$DTA" > "$TMP/wrap.do"
    ( cd "$TMP" && "$STATA" -b do "$TMP/wrap.do" < /dev/null )
    grep -E '^\s+(identidad|Σ intra|Σ S|nta-grupoedad)' "$TMP/wrap.log" | sed 's/^/  /'
    if grep -qE '^r\([0-9]+\);' "$TMP/wrap.log"; then
        echo "ROJO   Stata: $(grep -E '^r\([0-9]+\);' "$TMP/wrap.log" | head -1) — ver $TMP/wrap.log"
        grep -B4 -E '^r\([0-9]+\);' "$TMP/wrap.log" | head -12
        rojo=1
    elif grep -q "test-nta-identidad: VERDE" "$TMP/wrap.log"; then
        echo "OK     identidad por grupo y quinquenio×sexo, Σ intra = 0, Σ S = AhorroHog, JSON = base (Stata)"
    else
        echo "ROJO   Stata no llegó a VERDE — ver $TMP/wrap.log"; rojo=1
    fi
else
    echo "SKIP   mitad Stata (--sin-stata)"
fi

# --- B. Sankey v2: conservación por nodo (Python, sin Stata) ---------------------------------
python3 - "$JSON" <<'PYEOF' || rojo=1
import re, sys, collections
p = sys.argv[1]
t = open(p, encoding='utf-8').read()
nodes = re.findall(r'\{label:"([^"]*)"\}', t)
links = re.findall(r'\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"\}', t)
rojo = False
vals = [float(v) for _, v, _ in links]
if any(v < 0 for v in vals):
    print(f'ROJO   Sankey v2: {sum(1 for v in vals if v < 0)} enlace(s) con valor negativo'); rojo = True
pares = collections.Counter((f, to) for to, _, f in links)
dup = [k for k, n in pares.items() if n > 1]
if dup:
    print(f'ROJO   Sankey v2: enlaces duplicados {dup[:5]}'); rojo = True
inn = collections.defaultdict(float); out = collections.defaultdict(float)
for to, v, f in links:
    inn[to] += float(v); out[f] += float(v)
faltan = [n for n in nodes if not inn[n] and not out[n]] + [n for n in set(list(inn) + list(out)) if n not in nodes]
if faltan:
    print(f'ROJO   Sankey v2: nodos sin enlaces o enlaces a nodos inexistentes: {faltan[:5]}'); rojo = True
mx, peor = 0.0, ''
for n in nodes:
    if inn[n] and out[n]:
        d = abs(inn[n] - out[n]) / max(inn[n], out[n])
        if d > mx: mx, peor = d, n
grupos = [n for n in nodes if n.startswith('Ingreso ') or n.startswith('Consumo ')]
if len(grupos) != 10:
    print(f'ROJO   Sankey v2: esperaba 10 nodos de grupo (Ingreso/Consumo × 5), hay {len(grupos)}'); rojo = True
for n in grupos:
    if not (inn[n] and out[n]):
        print(f'ROJO   Sankey v2: nodo de grupo {n} sin entradas o sin salidas'); rojo = True
if mx > 1e-9:
    print(f'ROJO   Sankey v2: nodo {peor} no conserva (|in−out|/max = {mx:.3e})'); rojo = True
else:
    print(f'OK     Sankey v2: {len(nodes)} nodos / {len(links)} enlaces; conservación en nodos intermedios ≤ 1e-9 (máx {mx:.1e} en {peor or "—"}); 10 nodos de grupo balanceados')
fuentes = [n for n in nodes if not inn[n]]; sinks = [n for n in nodes if not out[n]]
print(f'       fuentes ({len(fuentes)}): {", ".join(fuentes)}')
print(f'       sinks ({len(sinks)}): {", ".join(sinks)}')
sys.exit(1 if rojo else 0)
PYEOF

if (( rojo )); then echo "RESULTADO: test-nta-identidad ROJO"; exit 1; fi
echo "RESULTADO: test-nta-identidad VERDE"
