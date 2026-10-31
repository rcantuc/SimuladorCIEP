#!/usr/bin/env python3
"""contrato-32.py — consolida el contrato de entidad de las 32 (v8.13a). Lo llama contrato-32.sh.

Lee lo que dejó la sesión (users/<id>/<ABREV>/{sankey-*.json, ciclo-vida.json, tasas-efectivas.json},
<evidencia>/contrato-32.tsv) y escribe <evidencia>/contrato-32.md con:
  (a) PARIDAD: output.txt y sankey-*.json nacionales byte-idénticos a --refs (sha256).
  (b) ADITIVIDAD de lo aditivo: ciclo de vida (Σ32 pct_nac celda a celda = APORT* del output.txt,
      tolerancia 0.0005 = medio milésimo del %8.3f; Σ32 neto = neto nacional a 1e-9) — port de
      gate-aditividad.py (F3, 2026-10-11). Los Sankeys los compara compuertas-entidad.py (reuso).
  (c) TASAS EFECTIVAS (no aditivas): PROPUESTA de gate de consistencia, con FLAG — los montos sí son
      aditivos (Σ32 rec = rec nacional, Σ32 base = base nacional, a 1e-9) y por tanto la tasa nacional
      micro/micro se reproduce como promedio de las 32 ponderado por su base. Se mide y se reporta;
      Ricardo firma si se vuelve gate.
  (d) SELLOS, solo reportados: por entidad, celdas n < sello_n y el top-1 de concentración de la
      muestra (Sankeys: enlaces micro; ciclo: celdas; TE: impuestos).
  (e) La TABLA DE LAS 32: corrió/falló por paso, tiempo, productos presentes, sellos, top-1, notas.
Salida: 0 si paridad y aditividad pasan (la TE y los sellos no bloquean: se reportan); 1 si no.
"""
import argparse, csv, glob, hashlib, json, os, re, sys

import importlib.util
_spec = importlib.util.spec_from_file_location('compuertas_entidad', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'compuertas-entidad.py'))
_ce = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_ce)
leer_sankey = _ce.leer_sankey   # el mismo lector de los Sankeys de FusionCharts (reuso, no copia)


def sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def reldif(a, b):
    return abs(a - b) / max(abs(a), abs(b), 1e-300) if (a != 0 or b != 0) else 0.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', required=True); ap.add_argument('--id', required=True)
    ap.add_argument('--evidencia', required=True); ap.add_argument('--refs')
    ap.add_argument('--tol-add', type=float, default=1e-9); ap.add_argument('--tol-ciclo', type=float, default=0.0005)
    a = ap.parse_args()
    U = os.path.join(a.root, 'users', a.id)
    md = []; fallas = []; flags = []
    P = lambda s='': md.append(s)
    P('# Contrato de entidad para las 32 (contrato-32.py, v8.13a)'); P()

    # ---------------- (a) paridad ----------------
    P('## 1 Paridad: el flujo nacional no cambia un byte')
    prods = ['output.txt'] + [f'sankey-{k}.json' for k in ('decil', 'grupoedad', 'sexo', 'rural', 'escol')]
    if a.refs:
        # v8.15a: --refs acepta los dos layouts: plano (sankey-*.json junto a output.txt) o el de correr-sim.sh (SankeySF/; SankeyNTA/ trae los mismos nombres y no se compara aquí)
        dir_sk = a.refs if glob.glob(os.path.join(a.refs, 'sankey-*.json')) else os.path.join(a.refs, 'SankeySF')
        P(f'- Referencia: `{a.refs}`; Sankeys en `{dir_sk}`')
        P(); P('| producto | sha256 sesión | sha256 referencia | |'); P('|---|---|---|---|')
        for p in prods:
            r1 = os.path.join(U, p); r2 = os.path.join(a.refs if p == 'output.txt' else dir_sk, p)
            s1 = sha(r1) if os.path.isfile(r1) else '(ausente)'
            s2 = sha(r2) if os.path.isfile(r2) else '(ausente)'
            if s2 == '(ausente)': fallas.append(f'referencia ausente: {r2}')
            if s1 == '(ausente)': fallas.append(f'producto de la sesión ausente: {r1}')
            ausente = '(ausente)' in (s1, s2)
            if not ausente and s1 != s2: fallas.append(f'paridad: {p} difiere de la referencia')
            P(f'| {p} | `{s1[:16]}…` | `{s2[:16]}…` | {"✗ AUSENTE" if ausente else ("✓ byte-idéntico" if s1 == s2 else "✗ DIFIERE")} |')
    else:
        P('- (sin --refs: se registran los sha256 de la sesión, sin comparar)')
        for p in prods:
            if os.path.isfile(os.path.join(U, p)): P(f'  - {p}: `{sha(os.path.join(U, p))}`')
        flags.append('paridad sin referencia (--refs): registrada, no verificada')
    P()

    # ---------------- (e) tabla base: tsv de la sesión ----------------
    tsv = os.path.join(a.evidencia, 'contrato-32.tsv')
    filas = list(csv.DictReader(open(tsv, encoding='utf-8'), delimiter='\t')) if os.path.isfile(tsv) else []
    if not filas: fallas.append('no existe contrato-32.tsv (el recorrido de Stata no llegó a la tabla)')
    por_abrev = {f['abrev']: f for f in filas}

    # ---------------- (b) ciclo de vida ----------------
    P('## 2 Aditividad del ciclo de vida: Σ32 pct_nac = APORT* del output.txt')
    out_txt = os.path.join(U, 'output.txt')
    apv = {}
    txt = open(out_txt, encoding='utf-8', errors='replace').read() if os.path.isfile(out_txt) else ''
    txt = re.sub(r'\n>\s*', '', txt)
    for l in txt.splitlines():
        m = re.match(r'^(APORT\w+):\s*\[(.*)\]', l)
        if m: apv[m.group(1)] = [float(x) for x in m.group(2).split(',')]
    names = {('Hombres', 'Deciles I-V'): 'APORTHIV', ('Hombres', 'VI-IX'): 'APORTHVIIX', ('Hombres', 'X'): 'APORTHX',
             ('Mujeres', 'Deciles I-V'): 'APORTMIV', ('Mujeres', 'VI-IX'): 'APORTMVIIX', ('Mujeres', 'X'): 'APORTMX'}
    ciclos = {}
    for f in sorted(glob.glob(os.path.join(U, '*', 'ciclo-vida.json'))):
        try:
            d = json.load(open(f, encoding='utf-8')); ciclos[d['entidad']['abrev']] = d
        except Exception as e:
            fallas.append(f'ciclo-vida ilegible: {f}: {e}')
    suma = {}; netos = 0.0; netonac = None; fc = []
    for ab, d in ciclos.items():
        c = d['celdas']; T = d['totales']
        if netonac is None: netonac = T['nacional']['neto']
        netos += T['entidad']['neto']
        if len(c) != 46: fc.append(f'{ab}: rejilla incompleta ({len(c)})')
        if abs(sum(x['pct'] for x in c) - 100) > 1e-4: fc.append(f'{ab}: Σ pct != 100')
        for x in c:
            esperado = 1 if (x['n'] < d['parametros']['sello_n'] or x['top1_aporta'] > d['parametros']['sello_top1'] or x['top1_recibe'] > d['parametros']['sello_top1']) else 0
            if esperado != x['sello']: fc.append(f'{ab}: regla del sello {x["sexo"]} {x["quinquenio"]}')
            for g in x['grupos']:
                k = (x['sexo'], g['grupo'], x['g']); suma[k] = suma.get(k, 0.0) + g['pct_nac']
    worst = 0.0; det = []
    if apv and ciclos:
        for (sexo, grupo), nm in names.items():
            vals = apv.get(nm, []); L = len(vals)
            mine = [suma.get((sexo, grupo, k), 0.0) for k in range(L, 0, -1)]
            w = max([abs(x - y) for x, y in zip(vals, mine)] or [0]); worst = max(worst, w); det.append((nm, L, w))
    ok_ciclo = len(ciclos) == 32 and worst <= a.tol_ciclo and not fc and netonac and reldif(netos, netonac) < a.tol_add
    P(); P(f'- JSON de ciclo de vida: **{len(ciclos)}/32**')
    if apv: P(f'- Σ32 pct_nac vs APORT* (6 vectores, celda a celda): diferencia máxima **{worst:.6f}** (tolerancia {a.tol_ciclo}): ' + ', '.join(f'{n} L={L} máx {w:.6f}' for n, L, w in det))
    if netonac: P(f'- Σ32 neto = {netos/1e6:,.2f} mdp vs nacional {netonac/1e6:,.2f} mdp (reldif {reldif(netos, netonac):.2e}, tol {a.tol_add})')
    for x in fc[:20]: P(f'- ✗ {x}')
    P(f'- **{"PASÓ" if ok_ciclo else "FALLÓ"}**')
    if not ok_ciclo: fallas.append('aditividad del ciclo de vida')
    P()

    # ---------------- (c) tasas efectivas ----------------
    P('## 3 Tasas efectivas micro/micro: consistencia (PROPUESTA de gate, FLAG)')
    tes = {}
    for f in sorted(glob.glob(os.path.join(U, '*', 'tasas-efectivas.json'))):
        try:
            d = json.load(open(f, encoding='utf-8')); tes[d['entidad']['abrev']] = d
        except Exception as e:
            fallas.append(f'tasas-efectivas ilegible: {f}: {e}')
    P(); P(f'- JSON de tasas efectivas: **{len(tes)}/32**')
    if tes:
        imp = [i['impuesto'] for i in next(iter(tes.values()))['impuestos']]
        BASE_DE = {'ISRAS': 'Sal', 'CUOTAS': 'Sal', 'ISRPF': 'Mix', 'ISRPM': 'KPriv', 'OTROSK': 'KPriv', 'IVA': 'Consu', 'IMPORT': 'Consu', 'ISAN': 'Vehic', 'IEPSNP': 'AlcTaba', 'IEPSP': 'Combu'}
        P(); P('| impuesto | base | Σ32 rec vs nacional (reldif) | Σ32 base vs nacional (reldif) | Σ32 rec / Σ32 base vs te nacional micro (reldif; informativo, te va con 6 decimales en el JSON) | te nacional micro (%) | rango de las 32 (%) | entidades con sello |')
        P('|---|---|---:|---:|---:|---:|---|---:|')
        worst_te = 0.0
        for k in imp:
            b = BASE_DE[k]; rec_e = []; te_e = []; base_e = []; rec_nac = None; te_nac = None; base_nac = None; sell = 0
            for ab, d in tes.items():
                i = next(x for x in d['impuestos'] if x['impuesto'] == k)
                rec_e.append(i['rec']); te_e.append(i['te']); rec_nac = i['rec_nacional']; te_nac = i['te_nacional_micro']; sell += i['sello']
                base_e.append(d['bases'][b]['entidad']); base_nac = d['bases'][b]['nacional']
            srec = sum(rec_e); sbase = sum(base_e)
            te_pond = srec / sbase * 100 if sbase else float('nan')   # = Σ base_e·te_e / Σ base_e
            r1 = reldif(srec, rec_nac); r2 = reldif(sbase, base_nac); r3 = reldif(te_pond, te_nac)
            worst_te = max(worst_te, r1, r2)   # r3 está limitado por los 6 decimales con que el JSON escribe te (~1e-7 relativo): informativo
            if max(te_e) - min(te_e) < 1e-9: flags.append(f'TE {k}: la tasa es IDÉNTICA en las 32 ({te_nac:.3f} %): numerador y denominador se imputan con el mismo relativo (Distribucion); por entidad no aporta información — metodología, Ricardo decide si se publica')
            P(f'| {k} | {b} | {r1:.2e} | {r2:.2e} | {r3:.2e} | {te_nac:.3f} | {min(te_e):.3f} – {max(te_e):.3f} | {sell} |')
        P(); P(f'- reldif máximo de los MONTOS (Σ32 rec, Σ32 base vs nacional): **{worst_te:.2e}** (tolerancia propuesta 1e-9; los montos son sumas [aw=factor] de la misma base por residencia, así que Σ32 = nacional salvo coma flotante; la tasa nacional micro = Σ32 rec / Σ32 base = promedio ponderado por base; el JSON escribe los montos con 2 decimales, 1e-14 relativo).')
        P('- FLAG (metodología, Ricardo firma): las tasas no son aditivas; lo que propongo como gate es que los MONTOS lo sean (Σ32 rec = rec nacional, Σ32 base = base nacional) y, en consecuencia, que la tasa nacional micro/micro sea el promedio de las 32 ponderado por su base. Hoy se mide y se reporta; no bloquea.')
        if worst_te > a.tol_add: flags.append(f'TE: reldif máximo {worst_te:.2e} > 1e-9 (ver §3)')
    P()

    # ---------------- (d)+(e) tabla de las 32 ----------------
    P('## 4 Tabla de las 32 (insumo de v8.13b; aquí solo se mide y se declara)')
    P(); P('Sellos: n < 100 o top-1 > 25 % (regla P5). «top-1 (n ≥ 100)» = mayor concentración en una celda NO delgada: el patrón del 47.9 % de NL (ISRPM) — una sola persona pone esa fracción del numerador. Las celdas con n = 1 valen 100 % por construcción y ya cuentan como selladas.')
    P(); P('| # | entidad | corrió | s | sankeys | ciclo | tasas ef. | población | PIB/Defl. | n (TE) | selladas: sankeys micro / ciclo / TE | top-1 TE (impuesto) | top-1 (n ≥ 100) dónde | notas |')
    P('|---:|---|---|---:|---|---|---|---|---|---:|---|---|---|---|')
    tot_ok = 0
    for f in filas:
        ab = f['abrev']; d = os.path.join(U, ab)
        sk_files = [os.path.join(d, f'sankey-{k}.json') for k in ('quintil', 'grupoedad', 'sexo', 'rural', 'escol')]
        sk_ok = sum(os.path.isfile(p) for p in sk_files)
        n_micro = 0; n_sell = 0; top1 = (0.0, '')   # top-1 solo en celdas con n >= 100 (las delgadas ya van selladas)
        for p in sk_files:
            if not os.path.isfile(p): continue
            try:
                sk = leer_sankey(p)
            except Exception:
                continue
            for l in sk['links']:
                if 'sello' in l:
                    n_micro += 1; n_sell += int(l.get('sello', 0) or 0)
                    t1 = float(l.get('top1', 0) or 0); nn = int(float(l.get('n', 0) or 0))
                    if nn >= 100 and t1 > top1[0]: top1 = (t1, f'{os.path.basename(p)[7:-5]} {l["from"].strip()}→{l["to"].strip()} (n={nn})')
        cic = ciclos.get(ab); te = tes.get(ab)
        c_sell = cic['totales']['entidad']['celdas_con_sello'] if cic else None
        if cic:
            for x in cic['celdas']:
                for key in ('top1_aporta', 'top1_recibe'):
                    if x['n'] >= 100 and x.get(key, 0) > top1[0]: top1 = (x[key], f'ciclo {x["sexo"]} {x["quinquenio"]} {key[5:]} (n={x["n"]})')
        t_sell = te['muestra']['impuestos_con_sello'] if te else None
        te_top = (0.0, '')
        if te:
            for i in te['impuestos']:
                if i['top1'] > te_top[0]: te_top = (i['top1'], i['impuesto'])
                if te['muestra']['n'] >= 100 and i['top1'] > top1[0]: top1 = (i['top1'], f'TE {i["impuesto"]} (n={te["muestra"]["n"]})')
            if te_top[0] > 100: flags.append(f'{ab}: top-1 de {te_top[1]} = {te_top[0]:.1f} % > 100 % (hay valores negativos en el numerador)')
        corrio = f['poblacion_rc'] == '0' and sk_ok == 5 and f['ciclo_rc'] == '0' and f['te_rc'] == '0'
        tot_ok += corrio
        notas = []
        if f['pib_rc'] not in ('0', '.'): notas.append(f'PIBDeflactor rc={f["pib_rc"]}')
        if f['pib_rc'] == '.': notas.append('PIB sin base (receta en tsv)')
        if f['sankeys_rc']: notas.append(f'sankeys {f["sankeys_rc"]}')
        if f['ciclo_rc'] != '0': notas.append(f'ciclo rc={f["ciclo_rc"]}')
        if f['te_rc'] != '0': notas.append(f'TE rc={f["te_rc"]}')
        if f['banda'] != 'si': notas.append('sin banda de vintages')
        P(f'| {f["pos"]} | {f["nombre"]} ({ab}) | {"✓" if corrio else "✗"} | {float(f["segundos"]):.0f} | {sk_ok}/5 | {"sí" if cic else "no"} | {"sí" if te else "no"} | {"sí" if f["poblacion_rc"] == "0" else "rc " + f["poblacion_rc"]} | {"sí" if f["pib_rc"] == "0" else ("sin base" if f["pib_rc"] == "." else "rc " + f["pib_rc"])} | {te["muestra"]["n"] if te else "—"} | {n_sell}/{n_micro} / {c_sell if c_sell is not None else "—"}/46 / {t_sell if t_sell is not None else "—"}/10 | {te_top[0]:.1f} % ({te_top[1]}) | {top1[0]:.1f} % {top1[1]} | {"; ".join(notas)} |')
    P(); P(f'- Entidades con el contrato completo (población + 5 sankeys + ciclo + tasas efectivas): **{tot_ok}/32**')
    if tot_ok < 32: flags.append(f'{32 - tot_ok} entidad(es) con algún paso fallido (ver tabla)')
    P()

    # ---------------- (f) PIBE por entidad: base presente y «% del PIBE» (vista previa para v8.13b) ----------------
    con_base = [f for f in filas if f['pib_rc'] == '0']
    sin_base = [f['abrev'] for f in filas if f['pib_rc'] != '0']
    P('## 4b PIB estatal (PIBE): bases `master/PIBDeflactor<ABREV>.dta` y «% del PIBE» (vista previa de v8.13b)')
    P(); P(f'- Entidades con base y `PIBDeflactor` por entidad sin error: **{len(con_base)}/32**' + (f' (sin base o con rc: {", ".join(sin_base)})' if sin_base else ''))
    if len(con_base) < 32: fallas.append(f'PIBE: {32 - len(con_base)} entidad(es) sin base o con rc != 0 en PIBDeflactor ({", ".join(sin_base)})')
    P('- Los productos JSON de entidad aún NO escriben «% del PIBE» (`CicloEntidad.do` y `SankeySF.do` llaman `PIBDeflactor` nacional: `pibY` del `nacional`); eso es v8.13b. Esta tabla solo prueba que la base lo permite: neto del ciclo de vida de la entidad (`ciclo-vida.json` `totales.entidad.neto`, pesos → mdp) ÷ `pibY<ABREV>` (escalar de `PIBDeflactor` por entidad, año de valor presente).')
    P(); P('| # | entidad | PIBE (mdp) | share PIBE / Σ32 | neto ciclo (mdp) | neto / PIBE (%) | share población |'); P('|---:|---|---:|---:|---:|---:|---:|')
    pibes = {f['abrev']: float(f['pibe_pesos']) / 1e6 for f in filas if f.get('pibe_pesos', '.') not in ('.', '')}
    sp = sum(pibes.values())
    for f in filas:
        ab = f['abrev']; cic = ciclos.get(ab); pb = pibes.get(ab)
        net = cic['totales']['entidad']['neto'] / 1e6 if cic else None   # el JSON va en pesos; aquí mdp, como el PIBE
        shp = cic['totales']['nacional']['share_pob'] if cic else None
        P(f'| {f["pos"]} | {f["nombre"]} ({ab}) | {f"{pb:,.0f}" if pb else "—"} | {f"{pb / sp * 100:.2f} %" if pb else "—"} | {f"{net:,.0f}" if net is not None else "—"} | {f"{net / pb * 100:.3f}" if (net is not None and pb) else "—"} | {f"{shp * 100:.2f} %" if shp is not None else "—"} |')
    P(); P(f'- Σ32 PIBE = {sp:,.0f} mdp (año de valor presente; informativo: no se gatea contra el PIB nacional de `output.txt`).')
    P()

    # ---------------- veredicto ----------------
    P('## 5 Veredicto')
    P()
    for x in fallas: P(f'- ✗ {x}')
    for x in flags: P(f'- FLAG {x}')
    ok = not fallas
    P(f'- **{"PASÓ" if ok else "FALLÓ"}** (paridad + aditividad del ciclo de vida; los Sankeys los dicta compuertas-entidad.md; TE y sellos solo se reportan)')
    open(os.path.join(a.evidencia, 'contrato-32.md'), 'w', encoding='utf-8').write('\n'.join(md) + '\n')
    print('\n'.join(md[-6:]))
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
