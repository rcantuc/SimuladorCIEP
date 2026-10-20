#!/usr/bin/env python3
"""pibe-32.py — compuertas, sellos, diff y reporte de las 32 bases master/PIBDeflactor<ABREV>.dta (v8.13a-2).

Subcomandos (los invoca 05_scripts/pibe-32.sh; todos aceptan --root y --evidencia):
  gate      compuerta de arranque: catálogo SIMentidad con 32, set_token.do presente y válido (una
            consulta BISE de prueba responde), master/PIBDeflactorNL.dta existe. El token NUNCA se imprime.
  fallidas  imprime las abreviaturas sin base fresca (para la pasada de reintento).
  sellar    escribe master/PIBDeflactor<ABREV>.meta (+ copia en <evidencia>/sellos/) por base: series
            BISE/BIE, estructura, fecha de consulta, último periodo, n; y <evidencia>/sellos.tsv.
  reporte   pibe-32.md: tabla de procedencia de las 32, diff de las bases previas (NL/Jal/Camp) y SHA/tamaño.
Solo biblioteca estándar + pandas. Fuentes vivas: se declara la fecha de consulta, no se congela nada.
"""
import argparse, csv, hashlib, math, os, re, sys, time
from datetime import datetime

BISE_URL = 'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml'
SERIES_BIE = {'pibe': '750453', 'deflactor': '753357'}
OCUPADOS, DESOCUPADOS = '6200093954', '6200093973'
INPC_ESTRUCTURA = '112001700070'


def catalogo(root):
    t = open(os.path.join(root, 'SIMentidad.ado'), encoding='utf-8').read()
    nombres = re.search(r'global entidadesL `"(.*?)"\'', t, re.S).group(1)
    nombres = re.findall(r'"([^"]+)"', nombres)
    abrevs = re.search(r'global entidadesC "([^"]+)"', t).group(1).split()
    nombres = [n for n in nombres if n != 'Nacional']
    abrevs = [a for a in abrevs if a != 'Nac']
    return nombres, abrevs


def token(root):
    f = os.path.join(root, 'set_token.do')
    if not os.path.isfile(f):
        return None
    m = re.search(r'BIE_API_TOKEN\s+"([^"]+)"', open(f, encoding='utf-8').read())
    return m.group(1) if m and m.group(1) != 'tu-token-aqui' else None


def meta_leer(path):
    d = {}
    if os.path.isfile(path):
        for line in open(path, encoding='utf-8'):
            if '=' in line:
                k, v = line.rstrip('\n').split('=', 1)
                d[k] = v
    return d


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def iso(ts):
    return datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')


def cmd_gate(a):
    import requests
    nombres, abrevs = catalogo(a.root)
    ok = True
    print(f'SIMentidad: {len(nombres)} entidades, {len(abrevs)} abreviaturas ->', 'OK' if len(nombres) == len(abrevs) == 32 else 'FALLA')
    ok &= len(nombres) == len(abrevs) == 32
    tk = token(a.root)
    if not tk:
        print('set_token.do: AUSENTE o sin token real -> FALLA')
        return 1
    print('set_token.do: presente (token no impreso)')
    try:
        r = requests.get(f'{BISE_URL}/INDICATOR/{OCUPADOS}/es/19/false/BISE/2.0/{tk}?type=json', timeout=60)
        d = r.json()
        if isinstance(d, list):
            raise ValueError('la API respondió ' + '; '.join(str(x) for x in d).replace(tk, '<TOKEN>'))
        s = d['Series'][0]
        obs = [(o['TIME_PERIOD'], o['OBS_VALUE']) for o in s['OBSERVATIONS']]
        print(f'consulta BISE de prueba (serie {OCUPADOS}, área 19): HTTP {r.status_code}, {len(obs)} obs, último {max(obs)[0]}, LASTUPDATE {s.get("LASTUPDATE")} -> OK')
    except Exception as e:
        print('consulta BISE de prueba -> FALLA:', str(e).replace(tk, '<TOKEN>')[:300])
        ok = False
    nl = os.path.join(a.root, 'master', 'PIBDeflactorNL.dta')
    print(f'master/PIBDeflactorNL.dta (referencia): {"existe" if os.path.isfile(nl) else "NO existe"}')
    ok &= os.path.isfile(nl)
    print('COMPUERTA DE ARRANQUE:', 'PASÓ' if ok else 'FALLÓ')
    return 0 if ok else 1


def inicio_epoch(a):
    f = os.path.join(a.evidencia, 'inicio-epoch.txt')
    return float(open(f).read().strip()) if os.path.isfile(f) else 0.0


def fresca(a, abrev):
    p = os.path.join(a.root, 'master', f'PIBDeflactor{abrev}.dta')
    return os.path.isfile(p) and os.path.getmtime(p) >= inicio_epoch(a)


def cmd_fallidas(a):
    _, abrevs = catalogo(a.root)
    print(' '.join(x for x in abrevs if not fresca(a, x)))
    return 0


def tabla_areas(root, serie, clave):
    """filas (periodo, valor) del área `clave` en la tabla completa cacheada, sin faltantes"""
    f = os.path.join(root, 'raw', 'temp', 'AccesoBIE', f'{serie}_areas.csv')
    out = []
    if os.path.isfile(f):
        for r in csv.DictReader(open(f, encoding='utf-8')):
            if r['area'] == clave and r['valor'] not in ('', None):
                out.append((r['periodo'], r['valor']))
    return out


def sello(a, abrev, nombre, clave, df):
    r = os.path.join(a.root, 'raw', 'temp', 'AccesoBIE')
    ini = inicio_epoch(a)
    s = {'sello': 'pibe-32 v8.13a-2', 'entidad': nombre, 'abrev': abrev, 'clave': clave}
    dta = os.path.join(a.root, 'master', f'PIBDeflactor{abrev}.dta')
    s['base_fresca'] = 'si' if os.path.getmtime(dta) >= ini else 'NO (base de una corrida anterior)'
    s['base_generada'] = iso(os.path.getmtime(dta))
    for nom, serie in SERIES_BIE.items():
        m = meta_leer(os.path.join(r, f'{serie}_areas.meta'))
        filas = tabla_areas(a.root, serie, clave)
        s[f'{nom}_serie'] = f'BIE {serie} (consulta pública exportacion.aspx, área {clave})'
        s[f'{nom}_fecha_consulta'] = m.get('fecha_consulta', '?')
        s[f'{nom}_ultimo'] = max(p for p, _ in filas) if filas else '?'
        s[f'{nom}_n'] = str(len(filas))
        s[f'{nom}_titulo'] = m.get('titulo', '?')
    for nom, serie in (('ocupados', OCUPADOS), ('desocup', DESOCUPADOS)):
        f = os.path.join(r, f'{serie}_{clave}.csv')
        filas = [x for x in csv.DictReader(open(f, encoding='utf-8')) if x['valor'] != ''] if os.path.isfile(f) else []
        s[f'{nom}_serie'] = f'BISE {serie} (API oficial INDICATOR/BISE/2.0, área {clave}, requiere token)'
        s[f'{nom}_fecha_consulta'] = iso(os.path.getmtime(f)) if filas else '?'
        s[f'{nom}_ultimo'] = max(x['periodo'] for x in filas) if filas else '?'
        s[f'{nom}_n'] = str(len(filas))
    it = next(((x, tabla_areas(a.root, x, clave)) for x in ('741177', '741180') if tabla_areas(a.root, x, clave)), None)
    if it:
        m = meta_leer(os.path.join(r, f'{it[0]}_areas.meta'))
        s['itaee_serie'] = f'BIE {it[0]} (consulta pública, área {clave})'
        s['itaee_fecha_consulta'] = m.get('fecha_consulta', '?')
        s['itaee_ultimo'] = max(p for p, _ in it[1])
        s['itaee_n'] = str(len(it[1]))
    else:
        s['itaee_serie'] = 'ninguna (sin nowcast)'
    m = meta_leer(os.path.join(r, f'inpc_{clave}.meta'))
    s['inpc_serie'] = f'INPC INEGI {m.get("serie", "?")} (programa INPC, estructura {m.get("estructura", INPC_ESTRUCTURA)})'
    s['inpc_fecha_consulta'] = m.get('fecha_consulta', '?')
    s['inpc_ultimo'] = m.get('ultimo', '?')
    s['inpc_n'] = m.get('n', '?')
    if df is not None:
        v = df.dropna(subset=['pibQ'])
        s['base_filas'] = str(len(df))
        s['base_periodo'] = f'{int(df.anio.min())}q{int(df.trimestre[df.anio == df.anio.min()].min())} a {int(df.anio.max())}q{int(df.trimestre[df.anio == df.anio.max()].max())}'
        s['base_ultimo_pibe'] = f'{int(v.anio.iloc[-1])}' if len(v) else '?'
        s['base_n_pibe'] = str(len(v))
        s['base_ultimo_ocupados'] = (lambda z: f'{int(z.anio.iloc[-1])}/{int(z.trimestre.iloc[-1]):02d}' if len(z) else '?')(df.dropna(subset=['PoblacionOcupada']))
        s['base_ultimo_inpc'] = (lambda z: f'{int(z.anio.iloc[-1])}q{int(z.trimestre.iloc[-1])}' if len(z) else '?')(df.dropna(subset=['inpc']))
        s['base_itaee'] = 'si' if 'var_itaee' in df and df.var_itaee.notna().any() else 'no'
    return s


def leer_dta(path):
    import pandas as pd
    return pd.read_stata(path, convert_dates=False, convert_categoricals=False).sort_values(['anio', 'trimestre']).reset_index(drop=True)


def cmd_sellar(a):
    nombres, abrevs = catalogo(a.root)
    os.makedirs(os.path.join(a.evidencia, 'sellos'), exist_ok=True)
    filas, claves = [], None
    for i, (n, ab) in enumerate(zip(nombres, abrevs), 1):
        dta = os.path.join(a.root, 'master', f'PIBDeflactor{ab}.dta')
        if not os.path.isfile(dta):
            print(f'{ab}: SIN BASE')
            continue
        if os.path.getmtime(dta) < inicio_epoch(a):
            print(f'{ab}: base de una corrida anterior (no fresca); no se sella')
            continue
        s = sello(a, ab, n, f'{i:02d}', leer_dta(dta))
        txt = ''.join(f'{k}={v}\n' for k, v in s.items())
        for d in (os.path.join(a.root, 'master', f'PIBDeflactor{ab}.meta'), os.path.join(a.evidencia, 'sellos', f'{ab}.meta')):
            open(d, 'w', encoding='utf-8').write(txt)
        claves = claves or list(s)
        filas.append(s)
        print(f'{ab}: sello escrito (fresca: {s["base_fresca"]})')
    if filas:
        with open(os.path.join(a.evidencia, 'sellos.tsv'), 'w', encoding='utf-8', newline='') as f:
            w = csv.DictWriter(f, fieldnames=list(dict.fromkeys(k for s in filas for k in s)), delimiter='\t', restval='')
            w.writeheader(); w.writerows(filas)
    return 0


def fmt(x):
    return '' if x is None else str(x)


def diff_base(prev, nueva, nombre):
    import numpy as np
    A, B = leer_dta(prev), leer_dta(nueva)
    out = [f'### {nombre}', '']
    ca, cb = list(A.columns), list(B.columns)
    out.append(f'- Columnas: previa {len(ca)}, nueva {len(cb)}; solo en previa: {sorted(set(ca)-set(cb)) or "ninguna"}; solo en nueva: {sorted(set(cb)-set(ca)) or "ninguna"}')
    out.append(f'- Filas: previa {len(A)} ({int(A.anio.min())}q{int(A.trimestre.iloc[0])}–{int(A.anio.max())}q{int(A.trimestre.iloc[-1])}), nueva {len(B)} ({int(B.anio.min())}q{int(B.trimestre.iloc[0])}–{int(B.anio.max())}q{int(B.trimestre.iloc[-1])})')
    clave = ['anio', 'trimestre']
    M = A.merge(B, on=clave, how='outer', suffixes=('_a', '_b'), indicator=True)
    out.append(f'- Periodos: solo previa {int((M._merge=="left_only").sum())}, solo nueva {int((M._merge=="right_only").sum())}, comunes {int((M._merge=="both").sum())}')
    ult = lambda df, c: (lambda z: f'{int(z.anio.iloc[-1])}q{int(z.trimestre.iloc[-1])}' if len(z) else '—')(df.dropna(subset=[c])) if c in df else 'n/a'
    out += ['', '| serie | último periodo previa | último periodo nueva | celdas distintas (comunes) | máx. dif. relativa | primeros periodos que cambian |', '|---|---|---|---:|---:|---|']
    tot = 0
    for c in [c for c in ca if c in cb and c not in clave and c not in ('periodo', 'aniotrimestre', 'currency')]:
        both = M[M._merge == 'both']
        x, y = both[c + '_a'], both[c + '_b']
        if x.dtype.kind in 'fiu' and y.dtype.kind in 'fiu':
            dif = ~(np.isclose(x.astype(float), y.astype(float), rtol=1e-9, atol=0, equal_nan=True))
            rel = (abs(x - y) / abs(x).where(abs(x) > 0))[dif]
            mx = f'{rel.max():.3e}' if len(rel.dropna()) else ('nuevo/faltante' if dif.any() else '0')
        else:
            dif = (x.astype(str) != y.astype(str)); mx = '—'
        tot += int(dif.sum())
        pers = ', '.join(f'{int(r.anio)}q{int(r.trimestre)}' for r in both[dif].head(4).itertuples())
        out.append(f'| {c} | {ult(A, c)} | {ult(B, c)} | {int(dif.sum())} | {mx} | {pers} |')
    out += ['', f'- **Total de celdas con valor distinto en periodos comunes: {tot}**', '']
    return out


def cmd_reporte(a):
    nombres, abrevs = catalogo(a.root)
    L = ['# PIBDeflactor × 32 entidades (pibe-32, v8.13a-2)', '']
    ini = inicio_epoch(a)
    L.append(f'Inicio de la corrida: {iso(ini) if ini else "?"}. Fuentes vivas (D3a): la fecha de consulta de cada fuente va en la tabla; nada se congela.')
    L.append('')
    tsv = os.path.join(a.evidencia, 'pibe-32.tsv')
    rcs = {}
    if os.path.isfile(tsv):
        for r in csv.DictReader(open(tsv, encoding='utf-8'), delimiter='\t'):
            rcs.setdefault(r['abrev'], []).append(r)
    sel = {}
    f = os.path.join(a.evidencia, 'sellos.tsv')
    if os.path.isfile(f):
        sel = {r['abrev']: r for r in csv.DictReader(open(f, encoding='utf-8'), delimiter='\t')}
    L += ['## 1 Tabla de procedencia de las 32', '',
          '| # | entidad | base | fresca | rc (pasadas) | s | PIBE 750453 consulta / último / n | deflactor 753357 último | ocupados 6200093954 consulta / último / n | desocup. 6200093973 último / n | ITAEE | INPC consulta / último / n | base: filas / periodo | último PIBE |',
          '|---:|---|---|---|---|---:|---|---|---|---|---|---|---|---|']
    ok = 0
    for i, (n, ab) in enumerate(zip(nombres, abrevs), 1):
        s = sel.get(ab)
        rr = rcs.get(ab, [])
        rc = '/'.join(r['rc'] for r in rr) or '—'
        seg = sum(float(r['segundos']) for r in rr) if rr else 0
        if not s:
            ex = os.path.isfile(os.path.join(a.root, 'master', f'PIBDeflactor{ab}.dta'))
            L.append(f'| {i} | {n} ({ab}) | {"**base vieja, sin sello**" if ex else "**SIN BASE**"} | **NO** | {rc} | {seg:.0f} |' + ' — |' * 8)
            continue
        fr = s['base_fresca'] == 'si'
        ok += fr
        itx = s['itaee_serie'].split(' ')[1] if s['itaee_serie'].startswith('BIE') else 'ninguna'
        L.append(f'| {i} | {n} ({ab}) | sí | {"sí" if fr else "**NO**"} | {rc} | {seg:.0f} | {s["pibe_fecha_consulta"]} / {s["pibe_ultimo"]} / {s["pibe_n"]} | {s["deflactor_ultimo"]} | '
                 f'{s["ocupados_fecha_consulta"]} / {s["ocupados_ultimo"]} / {s["ocupados_n"]} | {s["desocup_ultimo"]} / {s["desocup_n"]} | {itx} ({s.get("itaee_ultimo", "—")}) | '
                 f'{s["inpc_fecha_consulta"]} / {s["inpc_ultimo"]} / {s["inpc_n"]} | {s["base_filas"]} / {s["base_periodo"]} | {s["base_ultimo_pibe"]} |')
    L += ['', f'**{ok}/32 bases frescas con sello** (generadas en esta corrida; sello en `master/PIBDeflactor<ABREV>.meta` y como `char _dta[sello_*]` dentro del .dta).', '']
    prev = os.path.join(a.evidencia, 'bases-previas')
    L += ['## 2 Diff de las bases previas (NL, Jal, Camp) contra las regeneradas', '',
          'Las copias viejas viven en `bases-previas/` (no se borran hasta que Ricardo vea este diff). Comparación por periodo (anio, trimestre) con tolerancia relativa 1e-9; el sello `char` del .dta nuevo no entra al diff.', '']
    for ab in ('NL', 'Jal', 'Camp'):
        p, nn = os.path.join(prev, f'PIBDeflactor{ab}.dta'), os.path.join(a.root, 'master', f'PIBDeflactor{ab}.dta')
        if os.path.isfile(p) and os.path.isfile(nn):
            L += diff_base(p, nn, f'PIBDeflactor{ab}')
        else:
            L += [f'### PIBDeflactor{ab}', '', '- sin par previa/nueva para comparar', '']
    L += ['## 3 Archivos (SHA-256, tamaño)', '', '| archivo | bytes | sha256 |', '|---|---:|---|']
    for ab in abrevs:
        p = os.path.join(a.root, 'master', f'PIBDeflactor{ab}.dta')
        L.append(f'| master/PIBDeflactor{ab}.dta | {os.path.getsize(p)} | `{sha(p)}` |' if os.path.isfile(p) else f'| master/PIBDeflactor{ab}.dta | — | **ausente** |')
    open(os.path.join(a.evidencia, 'pibe-32.md'), 'w', encoding='utf-8').write('\n'.join(L) + '\n')
    with open(os.path.join(a.evidencia, 'sha256-pibe-32.txt'), 'w', encoding='utf-8') as f:
        for ab in abrevs:
            p = os.path.join(a.root, 'master', f'PIBDeflactor{ab}.dta')
            if os.path.isfile(p):
                f.write(f'{sha(p)}  {os.path.getsize(p)}  master/PIBDeflactor{ab}.dta\n')
    print(f'reporte: {os.path.join(a.evidencia, "pibe-32.md")} ({ok}/32 frescas con sello)')
    return 0 if ok == 32 else 1


def main():
    p = argparse.ArgumentParser()
    p.add_argument('cmd', choices=['gate', 'fallidas', 'sellar', 'reporte'])
    p.add_argument('--root', default=os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    p.add_argument('--evidencia', required=True)
    a = p.parse_args()
    sys.exit({'gate': cmd_gate, 'fallidas': cmd_fallidas, 'sellar': cmd_sellar, 'reporte': cmd_reporte}[a.cmd](a))


if __name__ == '__main__':
    main()
