#!/usr/bin/env bash
# test-nta-identidad.sh — gate de sesión de la cuenta NTA por individuo (NTA-1, 2026-10-27; NTA-1b: sin tapón; NTA-3: v3 y panel).
#
# Dos mitades:
#   A. Stata (test-nta-identidad.do): identidad SIN ancla C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − YA_ajuste − S_sinancla) − intra = 0
#      por grupo de edad y por quinquenio × sexo (1e-9 relativo; con ancla, el residual con ancla = S_ajuste declarado),
#      Σ intra-hogar = 0 (nacional y por hogar), Σ S sin ancla vs B.8n S.14 (factor y brecha; con ancla Σ S = B.8n), las anclas
#      S.14 por construcción (Σ CpubInd = D.63, Σ ImpProd = D.21 − D.31, Σ YA_d8 = D.8, Σ τ⁺ efectivo = D.62 + D.759 si
#      nta_anclaTau = on, Σ YA_base = B.2n + ⅓B.3n + D.4 neto si nta_YA = S14) y
#      el JSON por grupo igual a la base. Requiere Stata y master/SCN.dta: por eso NO va en publicar.sh --ci
#      (runbook §11: gate de sesión).
#   B. Python (sin Stata): el Sankey v2 (users/<id>/SankeyNTA/sankey-v2-grupoedad.json) conserva flujo en TODO nodo
#      intermedio (entradas = salidas a 1e-9 relativo), no tiene enlaces negativos ni duplicados, los nodos de grupo
#      (Ingreso <g>, Consumo <g>) balancean, trae los nodos del contrato v2.1 («Impuestos a productos», «Derechos de
#      pensión D8», «Otros en especie», «Colectivo per cápita»; con ancla multiplicativa «Ancla S14 recorte» / «complemento»)
#      y se imprime el conteo nodos/enlaces (aparte del 31/79 de v1).
#   C. Python (sin Stata; NTA-3, v8.12.6): el Sankey v3 (sankey-v3-grupoedad.json) conserva en todo nodo intermedio, sin
#      negativos ni duplicados, SIN nodos «Ingreso <g>»/«Consumo <g>»/«Familias» (las edades solo al inicio y al final:
#      5 fuentes «De <g>» y 5 sinks « De <g>»), con los hubs del contrato v3 («Ing nacional», «Gobierno», «Activos»,
#      «Transferencias en efectivo», «Colectivo» terminal); y el panel (NTA/nta-panel-grupoedad-sexo.json, esquema
#      nta-panel/v1) trae 15 celdas (5 grupos × T/H/M) cuyas entradas = salidas a 1e-9 relativo a C, con Σ S (Total) =
#      Σ S (H) + Σ S (M) y, si hay ancla, Σ S (Total) = B.8n leído del nta-grupoedad.json de al lado. Conteos impresos (42/118 en 2024).
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
JSON3="$DIR/SankeyNTA/sankey-v3-grupoedad.json"
PANEL="$DIR/NTA/nta-panel-grupoedad-sexo.json"
CUENTA="$DIR/NTA/nta-grupoedad.json"
[[ -f "$DTA" ]] || { echo "test-nta-identidad: no existe $DTA (corre SIM.do hasta §3 o NTA.do)" >&2; exit 2; }
[[ -f "$JSON" ]] || { echo "test-nta-identidad: no existe $JSON" >&2; exit 2; }
[[ -f "$JSON3" ]] || { echo "test-nta-identidad: no existe $JSON3 (NTA.do §7b, NTA-3)" >&2; exit 2; }
[[ -f "$PANEL" ]] || { echo "test-nta-identidad: no existe $PANEL (NTA.do §7c, NTA-3)" >&2; exit 2; }
rojo=0

# --- A. Stata --------------------------------------------------------------------------------
if [[ "$SIN_STATA" == "false" ]]; then
    if [[ ! -x "$STATA" ]]; then
        echo "test-nta-identidad: no encuentro Stata en $STATA (usa --stata o --sin-stata)" >&2; exit 2
    fi
    TMP="$(mktemp -d)"
    printf 'capture set processors 1\nset linesize 200\nglobal SIMROOT "%s"\nadopath ++ "${SIMROOT}"\ncapture run "${SIMROOT}/set_token.do"\nglobal id "%s"\nscalar aniovp = 2024\nscalar anioenigh = 2024\nset scheme ciep\ndo "${SIMROOT}/05_scripts/test-nta-identidad.do" "%s"\n' "$REPO_ROOT" "$ID" "$DTA" > "$TMP/wrap.do"
    ( cd "$TMP" && "$STATA" -b do "$TMP/wrap.do" < /dev/null )
    grep -E '^\s+(identidad|Σ intra|Σ S|Σ CpubInd|Σ ImpProd|Σ YA_d8|Σ TpubEf|Σ YA_base|nta-grupoedad)' "$TMP/wrap.log" | sed 's/^/  /'
    if grep -qE '^r\([0-9]+\);' "$TMP/wrap.log"; then
        echo "ROJO   Stata: $(grep -E '^r\([0-9]+\);' "$TMP/wrap.log" | head -1) — ver $TMP/wrap.log"
        grep -B4 -E '^r\([0-9]+\);' "$TMP/wrap.log" | head -12
        rojo=1
    elif grep -q "test-nta-identidad: VERDE" "$TMP/wrap.log"; then
        echo "OK     identidad sin ancla por grupo y quinquenio×sexo, Σ intra = 0, Σ S vs B.8n, anclas S.14 por construcción, JSON = base (Stata)"
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
contrato = ['Impuestos a productos', 'Derechos de pensión D8', 'Educación pública', 'Salud pública', 'Otros en especie', 'Colectivo per cápita', 'Ing laboral', 'Ing capital', 'Gobierno', 'Familias', 'Activos', 'Ing nacional']
faltan_c = [n for n in contrato if n not in nodes]
if faltan_c:
    print(f'ROJO   Sankey v2: faltan nodos del contrato v2.1: {faltan_c}'); rojo = True
ancla = [n for n in nodes if n.startswith('Ancla S14') or n.startswith('Ajuste ancla')]
if ancla:
    print(f'       ancla de S declarada en el Sankey: {", ".join(ancla)} ({", ".join(f"{(inn[n] or out[n])/1e9:,.1f} bn" for n in ancla)})')
if mx > 1e-9:
    print(f'ROJO   Sankey v2: nodo {peor} no conserva (|in−out|/max = {mx:.3e})'); rojo = True
else:
    print(f'OK     Sankey v2: {len(nodes)} nodos / {len(links)} enlaces; conservación en nodos intermedios ≤ 1e-9 (máx {mx:.1e} en {peor or "—"}); 10 nodos de grupo balanceados')
fuentes = [n for n in nodes if not inn[n]]; sinks = [n for n in nodes if not out[n]]
print(f'       fuentes ({len(fuentes)}): {", ".join(fuentes)}')
print(f'       sinks ({len(sinks)}): {", ".join(sinks)}')
sys.exit(1 if rojo else 0)
PYEOF

# --- C. Sankey v3 y panel grupo × sexo (Python, sin Stata; NTA-3) -----------------------------
python3 - "$JSON3" "$PANEL" "$CUENTA" <<'PYEOF' || rojo=1
import re, sys, json, collections
p3, pp, pc = sys.argv[1:4]
rojo = False
t = open(p3, encoding='utf-8').read()
nodes = re.findall(r'\{label:"([^"]*)"\}', t)
links = re.findall(r'\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"\}', t)
vals = [float(v) for _, v, _ in links]
if any(v < 0 for v in vals):
    print(f'ROJO   Sankey v3: {sum(1 for v in vals if v < 0)} enlace(s) con valor negativo'); rojo = True
dup = [k for k, n in collections.Counter((f, to) for to, _, f in links).items() if n > 1]
if dup:
    print(f'ROJO   Sankey v3: enlaces duplicados {dup[:5]}'); rojo = True
inn = collections.defaultdict(float); out = collections.defaultdict(float)
for to, v, f in links:
    inn[to] += float(v); out[f] += float(v)
faltan = [n for n in nodes if not inn[n] and not out[n]] + [n for n in set(list(inn) + list(out)) if n not in nodes]
if faltan:
    print(f'ROJO   Sankey v3: nodos sin enlaces o enlaces a nodos inexistentes: {faltan[:5]}'); rojo = True
prohibidos = [n for n in nodes if n.startswith('Ingreso ') or n.startswith('Consumo ') or n in ('Familias', 'Colectivo per cápita')]
if prohibidos:
    print(f'ROJO   Sankey v3: nodos que el contrato v3 retira: {prohibidos}'); rojo = True
fuentes_g = [n for n in nodes if n.startswith('De ') and not inn[n]]
sinks_g = [n for n in nodes if n.startswith(' De ') and not out[n]]
if len(fuentes_g) != 5 or len(sinks_g) != 5:
    print(f'ROJO   Sankey v3: esperaba 5 grupos perceptores y 5 consumidores, hay {len(fuentes_g)}/{len(sinks_g)}'); rojo = True
contrato = ['Ing laboral', 'Ing capital', 'Alquiler propio', 'Impuestos a productos', 'Derechos de pensión D8', 'Remesas', 'Ing nacional', 'Gobierno', 'Activos', 'Transferencias en efectivo', 'Educación pública', 'Salud pública', 'Otros en especie', 'Colectivo', 'Alimentos', 'Vestido', 'Salud', 'Educación', 'Vivienda', 'Transporte', 'Otros gastos']
faltan_c = [n for n in contrato if n not in nodes]
if faltan_c:
    print(f'ROJO   Sankey v3: faltan nodos del contrato v3: {faltan_c}'); rojo = True
if out['Colectivo']:
    print('ROJO   Sankey v3: «Colectivo» debe ser terminal (sin edad)'); rojo = True
for h in ['Ing nacional', 'Gobierno', 'Activos', 'Transferencias en efectivo']:
    if not (inn[h] and out[h]):
        print(f'ROJO   Sankey v3: hub {h} sin entradas o sin salidas'); rojo = True
mx, peor = 0.0, ''
for n in nodes:
    if inn[n] and out[n]:
        d = abs(inn[n] - out[n]) / max(inn[n], out[n])
        if d > mx: mx, peor = d, n
if mx > 1e-9:
    print(f'ROJO   Sankey v3: nodo {peor} no conserva (|in−out|/max = {mx:.3e})'); rojo = True
else:
    print(f'OK     Sankey v3: {len(nodes)} nodos / {len(links)} enlaces; conservación en nodos intermedios ≤ 1e-9 (máx {mx:.1e} en {peor or "—"}); hubs Ing nacional / Gobierno / Activos / Transferencias en efectivo balanceados; sin Ingreso g / Consumo g / Familias')
ancla = [n for n in nodes if n.startswith('Ancla S14')]
if ancla:
    print(f'       ancla de S declarada en el v3: {", ".join(ancla)} ({", ".join(f"{(inn[n] or out[n])/1e9:,.1f} bn" for n in ancla)})')
print(f'       fuentes ({len([n for n in nodes if not inn[n]])}): {", ".join(n for n in nodes if not inn[n])}')
print(f'       sinks ({len([n for n in nodes if not out[n]])}): {", ".join(n for n in nodes if not out[n])}')
# panel
d = json.load(open(pp, encoding='utf-8'))
celdas = d.get('celdas', [])
if d.get('esquema') != 'nta-panel/v1' or len(celdas) != 15:
    print(f'ROJO   panel: esquema {d.get("esquema")} con {len(celdas)} celdas (esperaba nta-panel/v1 con 15)'); rojo = True
mxp = 0.0
for c in celdas:
    e = sum(c['entradas_flujos'].values()); s = sum(c['salidas_flujos'].values())
    r = abs(e - s) / c['C'] if c['C'] else abs(e - s)
    mxp = max(mxp, r)
    if any(v < 0 for v in list(c['entradas_flujos'].values()) + list(c['salidas_flujos'].values())):
        print(f'ROJO   panel: flujo negativo en la celda g={c["g"]} s={c["s"]}'); rojo = True
if mxp > 1e-9:
    print(f'ROJO   panel: alguna celda no balancea (|entradas − salidas|/C máx {mxp:.3e})'); rojo = True
ST = sum(c['S'] for c in celdas if c['s'] == 'T'); SHM = sum(c['S'] for c in celdas if c['s'] in ('H', 'M'))
if ST and abs(ST - SHM) / abs(ST) > 1e-9:
    print(f'ROJO   panel: Σ S Total {ST:,.0f} ≠ Σ S Hombres + Mujeres {SHM:,.0f}'); rojo = True
try:
    cu = json.load(open(pc, encoding='utf-8'))
    if cu['parametros']['nta_anclaS'] != 'off':
        b8 = cu['anclas']['AhorroHog_B8n']
        if abs(ST - b8) / abs(b8) > 1e-9:
            print(f'ROJO   panel: Σ S Total {ST:,.0f} ≠ B.8n {b8:,.0f} (con ancla {cu["parametros"]["nta_anclaS"]})'); rojo = True
        else:
            print(f'       panel: Σ S Total = B.8n ({b8/1e9:,.1f} bn; ancla {cu["parametros"]["nta_anclaS"]})')
except FileNotFoundError:
    print(f'       panel: sin {pc} para comparar Σ S con B.8n')
if mxp <= 1e-9 and len(celdas) == 15:
    print(f'OK     panel grupo × sexo: {len(celdas)} celdas balanceadas (|entradas − salidas|/C máx {mxp:.1e}); Σ S Total = Σ S H + M')
sys.exit(1 if rojo else 0)
PYEOF

if (( rojo )); then echo "RESULTADO: test-nta-identidad ROJO"; exit 1; fi
echo "RESULTADO: test-nta-identidad VERDE"
