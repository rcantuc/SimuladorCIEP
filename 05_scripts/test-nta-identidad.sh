#!/usr/bin/env bash
# test-nta-identidad.sh — gate de sesión de la cuenta NTA por individuo (NTA-1, 2026-10-27; NTA-1b: sin tapón; NTA-3: v3 y panel; NTA-4: % del PIB).
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
#   C. Python (sin Stata; NTA-3, v8.12.6; NTA-4, v8.13.0): el Sankey v3 (sankey-v3-grupoedad.json) conserva en todo nodo
#      intermedio EN AMBAS UNIDADES (value en MXN y pctpib en % del PIB; pctpib = value / PIB × 100 a 1e-12 con el PIB que
#      declara el panel), sin negativos ni duplicados, SIN nodos «Ingreso <g>»/«Consumo <g>»/«Familias» ni (NTA-4) «Desahorro
#      <g>»/«Futuro <g>», «Salud pública»/«Educación pública»/«Otros en especie» ni «Ancla S14 recorte»/«complemento» (las
#      edades solo al inicio y al final: 5 fuentes «De <g>» y 5 sinks « De <g>»), con los hubs del contrato v3 («Ing nacional»,
#      «Gobierno», «Activos», «Transferencias en efectivo»), «Colectivo» y «Futuro» terminales, «Desahorro» fuente única y, con
#      ancla, «Ajuste a cuentas nacionales S14» con el neto; y contra nta-grupoedad.json: lo que llega a cada grupo consumidor =
#      Cpriv + CpubInd del grupo, Colectivo, Futuro, Desahorro, la especie por categoría y el ajuste neto = la cuenta (1e-9).
#      El panel (NTA/nta-panel-grupoedad-sexo.json, esquema nta-panel/v2) trae 15 celdas (5 grupos × T/H/M) cuyas entradas =
#      salidas a 1e-9 relativo a C en ambas unidades, pctpib por celda a 1e-12, nacional_pctpib = cuenta / PIB × 100 y = hubs
#      del v3, Σ S (Total) = Σ S (H) + Σ S (M) y, si hay ancla, Σ S (Total) = B.8n. Conteos impresos (35/99 en 2024).
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

# --- C. Sankey v3 y panel grupo × sexo (Python, sin Stata; NTA-3; NTA-4: nodos fundidos, % del PIB, un nodo de ancla) ---
python3 - "$JSON3" "$PANEL" "$CUENTA" <<'PYEOF' || rojo=1
import re, sys, json, collections
p3, pp, pc = sys.argv[1:4]
rojo = False
t = open(p3, encoding='utf-8').read()
nodes = re.findall(r'\{label:"([^"]*)"\}', t)
links = re.findall(r'\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"(?:,pctpib:"([^"]*)")?\}', t)
vals = [float(v) for _, v, _, _ in links]
if any(v < 0 for v in vals):
    print(f'ROJO   Sankey v3: {sum(1 for v in vals if v < 0)} enlace(s) con valor negativo'); rojo = True
dup = [k for k, n in collections.Counter((f, to) for to, _, f, _ in links).items() if n > 1]
if dup:
    print(f'ROJO   Sankey v3: enlaces duplicados {dup[:5]}'); rojo = True
sinpct = [(f, to) for to, _, f, p in links if p == '']
if sinpct:
    print(f'ROJO   Sankey v3: {len(sinpct)} enlace(s) sin pctpib (NTA-4: value y pctpib en todos): {sinpct[:3]}'); rojo = True
# el panel declara el PIB (pib.valor) con el que NTA.do dividió; pctpib = value / PIB × 100 a 1e-12 en cada enlace
d = json.load(open(pp, encoding='utf-8'))
pib = (d.get('pib') or {}).get('valor')
if not pib or pib <= 0:
    print(f'ROJO   panel: sin pib.valor > 0 (NTA-4: denominador de pctpib declarado en el JSON)'); rojo = True
mxp = 0.0
if pib and not sinpct:
    for to, v, f, p in links:
        esp = float(v) / pib * 100
        mxp = max(mxp, abs(float(p) - esp) / esp if esp else abs(float(p)))
    if mxp > 1e-12:
        print(f'ROJO   Sankey v3: pctpib ≠ value / PIB × 100 (reldif máx {mxp:.3e} > 1e-12)'); rojo = True
inn = {}; out = {}
for u, idx in (('MXN', 1), ('% PIB', 3)):
    inn[u] = collections.defaultdict(float); out[u] = collections.defaultdict(float)
    for l in links:
        x = float(l[idx]) if l[idx] != '' else 0.0
        inn[u][l[0]] += x; out[u][l[2]] += x
I, O = inn['MXN'], out['MXN']
faltan = [n for n in nodes if not I[n] and not O[n]] + [n for n in set(list(I) + list(O)) if n not in nodes]
if faltan:
    print(f'ROJO   Sankey v3: nodos sin enlaces o enlaces a nodos inexistentes: {faltan[:5]}'); rojo = True
retirados = [n for n in nodes if n.startswith(('Ingreso ', 'Consumo ', 'Desahorro ', 'Futuro ', 'Ancla S14'))
             or n in ('Familias', 'Colectivo per cápita', 'Educación pública', 'Salud pública', 'Otros en especie')]
if retirados:
    print(f'ROJO   Sankey v3: nodos que el contrato v3 (NTA-4) retira: {retirados}'); rojo = True
fuentes_g = [n for n in nodes if n.startswith('De ') and not I[n]]
sinks_g = [n for n in nodes if n.startswith(' De ') and not O[n]]
if len(fuentes_g) != 5 or len(sinks_g) != 5:
    print(f'ROJO   Sankey v3: esperaba 5 grupos perceptores y 5 consumidores, hay {len(fuentes_g)}/{len(sinks_g)}'); rojo = True
cats = ['Alimentos', 'Vestido', 'Salud', 'Educación', 'Vivienda', 'Transporte', 'Otros gastos']
contrato = ['Ing laboral', 'Ing capital', 'Alquiler propio', 'Impuestos a productos', 'Derechos de pensión D8', 'Remesas', 'Ing nacional', 'Gobierno', 'Activos', 'Transferencias en efectivo', 'Colectivo', 'Futuro'] + cats
faltan_c = [n for n in contrato if n not in nodes]
if faltan_c:
    print(f'ROJO   Sankey v3: faltan nodos del contrato v3: {faltan_c}'); rojo = True
for n, tipo in (('Colectivo', 'sink'), ('Futuro', 'sink'), ('Desahorro', 'fuente')):
    if n in nodes and ((tipo == 'sink' and O[n]) or (tipo == 'fuente' and I[n])):
        print(f'ROJO   Sankey v3: «{n}» debe ser {tipo} (un solo nodo, terminal)'); rojo = True
for h in ['Ing nacional', 'Gobierno', 'Activos', 'Transferencias en efectivo']:
    if not (I[h] and O[h]):
        print(f'ROJO   Sankey v3: hub {h} sin entradas o sin salidas'); rojo = True
mx = {}; peor = {}
for u in ('MXN', '% PIB'):
    mx[u], peor[u] = 0.0, ''
    for n in nodes:
        if inn[u][n] and out[u][n]:
            dd = abs(inn[u][n] - out[u][n]) / max(inn[u][n], out[u][n])
            if dd > mx[u]: mx[u], peor[u] = dd, n
    if mx[u] > 1e-9:
        print(f'ROJO   Sankey v3: nodo {peor[u]} no conserva en {u} (|in−out|/max = {mx[u]:.3e})'); rojo = True
if max(mx.values()) <= 1e-9:
    print(f'OK     Sankey v3: {len(nodes)} nodos / {len(links)} enlaces; conservación en nodos intermedios ≤ 1e-9 en MXN (máx {mx["MXN"]:.1e} en {peor["MXN"] or "—"}) y en % del PIB (máx {mx["% PIB"]:.1e}); pctpib = value / PIB × 100 (reldif máx {mxp:.1e}); hubs balanceados; sin Ingreso g / Consumo g / Familias / especie aparte / Desahorro g / Futuro g / Ancla recorte+complemento')
# lo que el v3 reparte, contra la cuenta por grupo (nta-grupoedad.json, 4 decimales de MXN): fundir nodos no mueve lo que recibe cada edad
try:
    cu = json.load(open(pc, encoding='utf-8'))
except FileNotFoundError:
    cu = None
    print(f'       sin {pc}: no se comparan sinks ni especie con la cuenta')
def rd(a, b):
    return abs(a - b) / abs(b) if b else abs(a)
aj = 'Ajuste a cuentas nacionales S14'
if cu:
    G = {g['g']: g for g in cu['grupos']}
    peorsink = 0.0
    for g in range(1, 6):
        lab = ' ' + G[g]['grupo']
        peorsink = max(peorsink, rd(I[lab], G[g]['Cpriv'] + G[g]['CpubInd']))
    esp_ancla = -cu['S_vs_B8n']['S_ajuste']   # > 0: recorte neto (Activos → ajuste); < 0: complemento neto (ajuste → Activos)
    def enlace(f, to):
        return next((float(v) for t_, v, f_, _ in links if f_ == f and t_ == to), 0.0)
    comp = [('Σ entradas « De g» = Cpriv + CpubInd del grupo', peorsink),
            ('Colectivo = CpubCol nacional', rd(I['Colectivo'], G[0]['CpubCol'])),
            ('Futuro = Σ_g max(S_g, 0)', rd(I['Futuro'], sum(max(G[g]['S'], 0) for g in range(1, 6)))),
            ('Desahorro = Σ_g max(−S_g, 0)', rd(O['Desahorro'], sum(max(-G[g]['S'], 0) for g in range(1, 6)))),
            ('Gobierno → Salud = congob.salud', rd(enlace('Gobierno', 'Salud'), cu['congob']['salud'])),
            ('Gobierno → Educación = congob.educacion', rd(enlace('Gobierno', 'Educación'), cu['congob']['educacion'])),
            ('Gobierno → Otros gastos = congob.resto_individual_per_capita', rd(enlace('Gobierno', 'Otros gastos'), cu['congob']['resto_individual_per_capita']))]
    if cu['parametros']['nta_anclaS'] != 'off':
        if aj not in nodes:
            print(f'ROJO   Sankey v3: con ancla {cu["parametros"]["nta_anclaS"]} falta el nodo «{aj}»'); rojo = True
        else:
            obs = I[aj] - O[aj]   # entra desde Activos (recorte neto) o sale hacia Activos (complemento neto)
            comp.append(('Ajuste S14 = −S_ajuste nacional (neto recorte − complemento)', rd(obs, esp_ancla)))
            if I[aj] and O[aj]:
                print(f'ROJO   Sankey v3: «{aj}» debe ser terminal (sink o fuente, no ambos)'); rojo = True
    malos = [(k, v) for k, v in comp if v > 1e-9]
    for k, v in malos:
        print(f'ROJO   Sankey v3 vs cuenta: {k} (reldif {v:.3e})'); rojo = True
    if not malos:
        print(f'OK     Sankey v3 vs cuenta: lo que llega a cada grupo consumidor = Cpriv + CpubInd del grupo; Colectivo, Futuro, Desahorro, la especie de Gobierno por categoría y el ajuste S.14 neto = la cuenta (reldif máx {max(v for _, v in comp):.1e})')
    if aj in nodes:
        print(f'       ajuste S.14 neto en el v3: {I[aj] - O[aj]:,.0f} MXN ({(I[aj] - O[aj])/1e9:,.1f} bn; {inn["% PIB"][aj] - out["% PIB"][aj]:.4f} % del PIB); recorte {-sum(min(G[g]["S_ajuste"], 0) for g in range(1, 6))/1e9:,.1f} bn y complemento {sum(max(G[g]["S_ajuste"], 0) for g in range(1, 6))/1e9:,.1f} bn por separado en la cuenta y el panel')
print(f'       fuentes ({len([n for n in nodes if not I[n]])}): {", ".join(n for n in nodes if not I[n])}')
print(f'       sinks ({len([n for n in nodes if not O[n]])}): {", ".join(n for n in nodes if not O[n])}')
print('       hubs en % del PIB: ' + '; '.join(f'{h} {inn["% PIB"][h]:.2f}' for h in ['Ing nacional', 'Gobierno', 'Activos', 'Transferencias en efectivo']))
# panel (nta-panel/v2: doble unidad)
celdas = d.get('celdas', [])
if d.get('esquema') != 'nta-panel/v2' or len(celdas) != 15:
    print(f'ROJO   panel: esquema {d.get("esquema")} con {len(celdas)} celdas (esperaba nta-panel/v2 con 15)'); rojo = True
mxc = 0.0; mxpp = 0.0; mxcp = 0.0
for c in celdas:
    e = sum(c['entradas_flujos'].values()); s = sum(c['salidas_flujos'].values())
    r = abs(e - s) / c['C'] if c['C'] else abs(e - s)
    mxc = max(mxc, r)
    if any(v < 0 for v in list(c['entradas_flujos'].values()) + list(c['salidas_flujos'].values())):
        print(f'ROJO   panel: flujo negativo en la celda g={c["g"]} s={c["s"]}'); rojo = True
    pcb = c.get('pctpib')
    if not pcb or 'entradas_flujos' not in pcb or 'salidas_flujos' not in pcb:
        print(f'ROJO   panel: la celda g={c["g"]} s={c["s"]} no trae el bloque pctpib (NTA-4)'); rojo = True; continue
    if pib:
        for k, v in c.items():
            if isinstance(v, (int, float)) and k in pcb and k not in ('g', 'pob'):
                esp = v / pib * 100
                mxpp = max(mxpp, abs(pcb[k] - esp) / abs(esp) if esp else abs(pcb[k]))
        for lado in ('entradas_flujos', 'salidas_flujos'):
            for k, v in c[lado].items():
                esp = v / pib * 100
                mxpp = max(mxpp, abs(pcb[lado][k] - esp) / abs(esp) if esp else abs(pcb[lado][k]))
        ep = sum(pcb['entradas_flujos'].values()); sp = sum(pcb['salidas_flujos'].values())
        mxcp = max(mxcp, abs(ep - sp) / pcb['C'] if pcb['C'] else abs(ep - sp))
if mxc > 1e-9:
    print(f'ROJO   panel: alguna celda no balancea (|entradas − salidas|/C máx {mxc:.3e})'); rojo = True
if mxcp > 1e-9:
    print(f'ROJO   panel: alguna celda no balancea en % del PIB (máx {mxcp:.3e})'); rojo = True
if mxpp > 1e-12:
    print(f'ROJO   panel: pctpib ≠ valor / PIB × 100 en alguna celda (reldif máx {mxpp:.3e} > 1e-12)'); rojo = True
ST = sum(c['S'] for c in celdas if c['s'] == 'T'); SHM = sum(c['S'] for c in celdas if c['s'] in ('H', 'M'))
if ST and abs(ST - SHM) / abs(ST) > 1e-9:
    print(f'ROJO   panel: Σ S Total {ST:,.0f} ≠ Σ S Hombres + Mujeres {SHM:,.0f}'); rojo = True
nac = d.get('nacional_pctpib') or {}
if cu and pib:
    pares = [('S_sin_ajuste', cu['S_vs_B8n']['S_sin_ajuste']), ('AhorroHog', cu['S_vs_B8n']['AhorroHog']), ('S_final', cu['S_vs_B8n']['S_final']), ('S_ajuste', cu['S_vs_B8n']['S_ajuste']),
             ('YA_motor', cu['ya_s14']['YA_motor']), ('YAHogS14', cu['ya_s14']['YAHogS14']), ('TpubEf', G[0]['TpubEf']), ('Tmen', G[0]['Tmen']), ('OyE', cu['anclas']['OyE']),
             ('InterOtor', G[0]['InterOtor']), ('InterRec', G[0]['InterRec']), ('Remesas', G[0]['Remesas']), ('Cpriv', G[0]['Cpriv']), ('ConHogS14_P3', cu['anclas']['ConHogS14_P3']),
             ('ConHog', cu['anclas']['ConHog']), ('Cpub', G[0]['Cpub']), ('individual_D63', cu['congob']['individual_D63']), ('colectivo', cu['congob']['colectivo_per_capita']), ('CapFij', cu['anclas']['CapFij'])]
    faltan_n = [k for k, _ in pares if k not in nac] + [k for k in ('hub_Ing_nacional', 'hub_Gobierno', 'hub_Activos', 'hub_Transferencias_efectivo', 'Futuro', 'Desahorro', 'ancla_recorte', 'ancla_complemento', 'ancla_neto', 'PIN') if k not in nac]
    if faltan_n:
        print(f'ROJO   panel: nacional_pctpib sin {faltan_n}'); rojo = True
    else:
        mxn = max(rd(nac[k], v / pib * 100) for k, v in pares)
        hubs = [('hub_Ing_nacional', 'Ing nacional'), ('hub_Gobierno', 'Gobierno'), ('hub_Activos', 'Activos'), ('hub_Transferencias_efectivo', 'Transferencias en efectivo'), ('Futuro', 'Futuro'), ('Desahorro', 'Desahorro')]
        mxh = max(rd(nac[k], inn['% PIB'][n] or out['% PIB'][n]) for k, n in hubs)
        if mxn > 1e-9 or mxh > 1e-9:
            print(f'ROJO   panel: nacional_pctpib no coincide con la cuenta (reldif máx {mxn:.3e}) o con los hubs del v3 ({mxh:.3e})'); rojo = True
        else:
            print(f'OK     panel: nacional_pctpib = cuenta / PIB × 100 ({len(pares)} cifras, reldif máx {mxn:.1e}) y = hubs del v3 en % del PIB (reldif máx {mxh:.1e}); PIB {pib:,.0f} MXN')
try:
    if cu and cu['parametros']['nta_anclaS'] != 'off':
        b8 = cu['anclas']['AhorroHog_B8n']
        if abs(ST - b8) / abs(b8) > 1e-9:
            print(f'ROJO   panel: Σ S Total {ST:,.0f} ≠ B.8n {b8:,.0f} (con ancla {cu["parametros"]["nta_anclaS"]})'); rojo = True
        else:
            print(f'       panel: Σ S Total = B.8n ({b8/1e9:,.1f} bn; ancla {cu["parametros"]["nta_anclaS"]})')
except (KeyError, TypeError):
    print('       panel: sin cuenta para comparar Σ S con B.8n')
if mxc <= 1e-9 and mxcp <= 1e-9 and mxpp <= 1e-12 and len(celdas) == 15:
    print(f'OK     panel grupo × sexo (nta-panel/v2): {len(celdas)} celdas balanceadas en MXN (|entradas − salidas|/C máx {mxc:.1e}) y en % del PIB (máx {mxcp:.1e}); pctpib = valor / PIB × 100 (reldif máx {mxpp:.1e}); Σ S Total = Σ S H + M')
sys.exit(1 if rojo else 0)
PYEOF

if (( rojo )); then echo "RESULTADO: test-nta-identidad ROJO"; exit 1; fi
echo "RESULTADO: test-nta-identidad VERDE"
