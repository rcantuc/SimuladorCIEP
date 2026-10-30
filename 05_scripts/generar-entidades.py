#!/usr/bin/env python3
"""generar-entidades.py — el andamiaje de las 32 entidades del sitio (v8.13.0, «template estatal»).

Dos trabajos, uno por subcomando; ninguno toca el motor (.do/.ado) ni teclea un número en el sitio.

  paginas  [--check]
      Genera, desde el catálogo SIMentidad.ado (única fuente de verdad de nombres, abreviaturas y claves),
      las 32 páginas estáticas 04_1_simuladorfiscal.ciep.mx/entidades/<ABREV>/index.php y el catálogo PHP
      entidades/_catalogo.php. Cada página es un stub de tres líneas que fija $ENTIDAD_ABREV y carga la
      plantilla única entidades/_entidad.php: así las 32 son iguales por construcción y el contenido vive
      en un solo archivo. Idempotente y determinista (misma entrada → mismos bytes). --check no escribe:
      compara lo que generaría con lo commiteado (y detecta carpetas <ABREV>/ sobrantes) y sale 1 si
      difieren — es el gate «generado == commiteado» de test-sitio-entidades.sh y de CI.

  meta --users <users/<id>> [--tabla <contrato-32.tsv>] [--tabla-md <contrato-32.md>]
      Lee lo que contrato-32 dejó en users/<id>/<ABREV>/ (los 5 sankey-<corte>.json de SankeySF.do, el
      ciclo-vida.json de CicloEntidad.do y el tasas-efectivas.json de TasasEfectivasEntidad.do) y escribe,
      por entidad, users/<id>/<ABREV>/meta.json (esquema entidad-meta/v1) y el índice users/<id>/entidades.json
      (esquema entidades-indice/v1). Es lo que la página lee en runtime para los SELLOS (qué celdas tienen
      n < sello_n o top-1 > sello_top1, con su n: cada marca de la gráfica y cada nota al pie sale de aquí,
      nada se cablea en PHP/JS) y para el producto «neto del ciclo como % del PIBE»: el PIBE (pesos, año de
      valor presente) viene de la columna pibe_pesos de contrato-32.tsv (escalar pibY<ABREV> de PIBDeflactor
      por entidad; sin --tabla el bloque pibe queda null y la página lo declara), el neto de
      ciclo-vida.json totales.entidad.neto y el cociente se calcula aquí, igual que contrato-32.py §4b
      (FLAG declarado en el CHANGELOG: es la única división fuera de Stata; lo limpio es que CicloEntidad.do
      lo emita en una sesión del motor). La discrepancia Σ32 PIBE vs PIB nacional (totales.nacional.pibY)
      se registra como informativa. Con --tabla-md se cotejan los conteos de sellos contra la tabla de las
      32 de esa corrida (§4) y la diferencia, si la hay, se declara en meta.json (tabla_32.coincide).

Lo llama contrato-32.sh al final del recorrido (meta) y test-sitio-entidades.sh / CI (paginas --check).
"""
import argparse, csv, datetime, glob, json, os, re, subprocess, sys

VERSION = 'generar-entidades.py v1.0 (v8.13.0)'
CORTES = ['quintil', 'grupoedad', 'sexo', 'rural', 'escol']
# Enlaces «micro» de los Sankeys de entidad (los que llevan n/top1/sello): mismas familias que
# compuertas-entidad.py (FAM1 = destinos de los ingresos de los hogares; FAM4 = fuentes del gasto).
FAM1 = ['Imp al trabajo', ' Imp al consumo', '  Imp al capital', '   Cuotas IMSS']
FAM4 = ['Educación', 'Salud', '  Pensiones', '   Transferencias', '   Inversión']


def raiz_repo():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# ----------------------------------------------------------------------------------------------
# Catálogo: SIMentidad.ado (global entidadesL / entidadesC). Posición = clave INEGI 01..32.
# ----------------------------------------------------------------------------------------------
def leer_catalogo(ruta):
    t = open(ruta, encoding='utf-8').read()
    mL = re.search(r'global entidadesL `"(.*?)"\'', t, re.S)
    mC = re.search(r'global entidadesC "([^"]*)"', t)
    if not mL or not mC:
        sys.exit(f'generar-entidades: no encontré global entidadesL / entidadesC en {ruta}')
    nombres = re.findall(r'"([^"]+)"', mL.group(1))
    abrevs = mC.group(1).split()
    if len(nombres) < 32 or len(abrevs) < 32:
        sys.exit(f'generar-entidades: el catálogo trae {len(nombres)} nombres y {len(abrevs)} abreviaturas; esperaba 32 + Nacional')
    cat = []
    for i in range(32):
        cat.append({'pos': i + 1, 'clave': f'{i + 1:02d}', 'abrev': abrevs[i], 'nombre': nombres[i]})
    return cat


# ----------------------------------------------------------------------------------------------
# paginas: el catálogo PHP y los 32 stubs (bytes deterministas)
# ----------------------------------------------------------------------------------------------
def php_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def render_catalogo_php(cat):
    L = ['<?php',
         '// entidades/_catalogo.php — catálogo de las 32 entidades federativas del sitio.',
         '// GENERADO por 05_scripts/generar-entidades.py desde SIMentidad.ado (única fuente de verdad del',
         '// catálogo: posición = clave INEGI, abreviatura = la de Poblacion.ado). No editar a mano: el gate',
         '// «generado == commiteado» (test-sitio-entidades.sh, CI) lo regenera y compara byte a byte.',
         '// Lo leen entidades/_entidad.php (nombre, clave y validación de $ENTIDAD_ABREV), entidades/index.php',
         '// (las 32 filas) y jsonEntidad.php (lista blanca estricta de abrev: harness de seguridad).',
         'return array(']
    for e in cat:
        L.append(f"\t{php_str(e['abrev'])} => array('pos' => {php_str(str(e['pos']))}, 'clave' => {php_str(e['clave'])}, 'nombre' => {php_str(e['nombre'])}),")
    L.append(');')
    return '\n'.join(L) + '\n'


def render_stub_php(e):
    return ('<?php\n'
            f"// /entidades/{e['abrev']} — {e['nombre']} (clave {e['clave']}). GENERADO por 05_scripts/generar-entidades.py\n"
            '// desde SIMentidad.ado: no editar a mano (gate «generado == commiteado»). Toda la página vive en\n'
            '// entidades/_entidad.php; aquí solo se fija la entidad. Cero números: las cifras llegan en runtime\n'
            '// de /jsonEntidad.php (users/<id>/<ABREV>/*.json del motor y meta.json del generador).\n'
            f"$ENTIDAD_ABREV = {php_str(e['abrev'])};\n"
            "require dirname(__DIR__) . '/_entidad.php';\n")


def esperados(cat, sitio_entidades):
    out = {os.path.join(sitio_entidades, '_catalogo.php'): render_catalogo_php(cat)}
    for e in cat:
        out[os.path.join(sitio_entidades, e['abrev'], 'index.php')] = render_stub_php(e)
    return out


def cmd_paginas(a):
    cat = leer_catalogo(a.catalogo)
    esp = esperados(cat, a.sitio)
    abrevs = {e['abrev'] for e in cat}
    sobran = [d for d in sorted(os.listdir(a.sitio)) if os.path.isdir(os.path.join(a.sitio, d)) and d not in abrevs] if os.path.isdir(a.sitio) else []
    if a.check:
        difieren = []
        for ruta, contenido in esp.items():
            actual = open(ruta, encoding='utf-8', newline='').read() if os.path.isfile(ruta) else None
            if actual != contenido:
                difieren.append(os.path.relpath(ruta, raiz_repo()) + (' (ausente)' if actual is None else ' (difiere)'))
        for d in sobran:
            difieren.append(os.path.relpath(os.path.join(a.sitio, d), raiz_repo()) + ' (carpeta sobrante: no está en el catálogo)')
        if difieren:
            print('generar-entidades --check: lo commiteado NO es lo generado:')
            for x in difieren: print('  ' + x)
            print('  Corre: python3 05_scripts/generar-entidades.py paginas   (y commitea el resultado)')
            return 1
        print(f'generar-entidades --check: OK — {len(esp) - 1} páginas + _catalogo.php idénticos a lo generado desde {os.path.relpath(a.catalogo, raiz_repo())}; sin carpetas sobrantes.')
        return 0
    n_nuevos = 0; n_cambios = 0
    for ruta, contenido in esp.items():
        os.makedirs(os.path.dirname(ruta), exist_ok=True)
        actual = open(ruta, encoding='utf-8', newline='').read() if os.path.isfile(ruta) else None
        if actual == contenido: continue
        open(ruta, 'w', encoding='utf-8', newline='').write(contenido)
        if actual is None: n_nuevos += 1
        else: n_cambios += 1
    print(f'generar-entidades paginas: {len(esp) - 1} páginas + _catalogo.php en {os.path.relpath(a.sitio, raiz_repo())}/ ({n_nuevos} nuevas, {n_cambios} cambiadas, {len(esp) - n_nuevos - n_cambios} sin cambio).')
    for d in sobran: print(f'  AVISO: carpeta {d}/ no está en el catálogo (sobrante; bórrala si no es tuya)')
    return 0


# ----------------------------------------------------------------------------------------------
# meta: sellos y neto/PIBE por entidad + índice de las 32, desde los JSON del motor y la tabla
# ----------------------------------------------------------------------------------------------
def leer_sankey(path):
    """El JSON de FusionCharts que escribe SankeySF.do es un fragmento JS con claves sin comillas (misma
    gramática y mismo lector que compuertas-entidad.py); devuelve dict(entidad, nodes, links) con los
    valores tal cual (cadenas)."""
    s = open(path, encoding='utf-8').read()
    m = re.search(r'const dataSource=(\{.*\});\s*FusionCharts', s, re.S)
    if not m:
        raise ValueError(f'{path}: no se encontró dataSource')
    js = re.sub(r'([{,\[])\s*([A-Za-z0-9]+)\s*:', r'\1"\2":', m.group(1))
    d = json.loads(js)
    return {'entidad': d.get('entidad'), 'nodes': [n['label'] for n in d['nodes']], 'links': d['links']}


def es_micro(l):
    return l['to'] in FAM1 or l['from'] in FAM4


def num(x, default=None):
    try:
        return float(x)
    except (TypeError, ValueError):
        return default


def leer_tabla_tsv(ruta):
    if not ruta: return {}
    filas = list(csv.DictReader(open(ruta, encoding='utf-8'), delimiter='\t'))
    return {f['abrev']: f for f in filas}


def leer_tabla_md(ruta):
    """Columna «selladas: sankeys micro / ciclo / TE» de la tabla de las 32 (contrato-32.md §4) por abrev."""
    if not ruta: return {}
    out = {}
    for l in open(ruta, encoding='utf-8'):
        m = re.match(r'^\|\s*\d+\s*\|\s*(.+?) \((\w+)\)\s*\|', l)
        if not m: continue
        celdas = [c.strip() for c in l.strip().strip('|').split('|')]
        if len(celdas) < 11: continue
        if re.match(r'^\d+/\d+ / \d+/\d+ / \d+/\d+$', celdas[10]):
            out[m.group(2)] = celdas[10]
    return out


def meta_entidad(e, U, tabla, tabla_md, generado_el, commit, pibe_vintage=None):
    d = os.path.join(U, e['abrev'])
    ciclo = json.load(open(os.path.join(d, 'ciclo-vida.json'), encoding='utf-8'))
    tasas = json.load(open(os.path.join(d, 'tasas-efectivas.json'), encoding='utf-8'))
    sello_n = ciclo['parametros']['sello_n']; sello_top1 = ciclo['parametros']['sello_top1']

    def motivo(n, top1s):
        r = []
        if n < sello_n: r.append('n')
        if any(t > sello_top1 for t in top1s): r.append('top1')
        return '+'.join(r)

    # --- Sankeys: enlaces micro con sello ---
    sk = {}; n_micro = 0; n_sell = 0; n_menor = 0; top1 = (0.0, '')
    for k in CORTES:
        p = os.path.join(d, f'sankey-{k}.json')
        if not os.path.isfile(p): continue
        s = leer_sankey(p)
        lista = []
        for l in s['links']:
            if 'sello' not in l: continue
            n_micro += 1
            n = int(num(l.get('n'), 0)); t1 = num(l.get('top1'), 0.0)
            if n < sello_n: n_menor += 1
            if l.get('sello') == '1':
                n_sell += 1
                lista.append({'from': l['from'], 'to': l['to'], 'n': n, 'top1': t1, 'motivo': motivo(n, [t1])})
            if n >= 100 and t1 > top1[0]:
                top1 = (t1, f"{k} {l['from'].strip()}→{l['to'].strip()} (n={n})")
        sk[k] = {'corte': (s['entidad'] or {}).get('corte', k), 'enlaces_micro': sum(1 for l in s['links'] if 'sello' in l),
                 'sellados': lista, 'celdas': (s['entidad'] or {}).get('celdas', [])}

    # --- Ciclo de vida: celdas quinquenio × sexo con sello ---
    ci = []; ci_menor = 0
    for x in ciclo['celdas']:
        if x['n'] < sello_n: ci_menor += 1
        if x['sello']:
            ci.append({'sexo': x['sexo'], 's': x['s'], 'g': x['g'], 'quinquenio': x['quinquenio'], 'n': x['n'],
                       'top1_aporta': x['top1_aporta'], 'top1_recibe': x['top1_recibe'], 'motivo': motivo(x['n'], [x['top1_aporta'], x['top1_recibe']])})
        for key in ('top1_aporta', 'top1_recibe'):
            if x['n'] >= 100 and x.get(key, 0) > top1[0]:
                top1 = (x[key], f"ciclo {x['sexo']} {x['quinquenio']} {key[5:]} (n={x['n']})")

    # --- Tasas efectivas: impuestos con sello (n = muestra de la entidad) ---
    te = []; n_te = tasas['muestra']['n']; te_top = (0.0, '')
    for i in tasas['impuestos']:
        if i['sello']:
            te.append({'impuesto': i['impuesto'], 'n': n_te, 'top1': i['top1'], 'motivo': motivo(n_te, [i['top1']])})
        if i['top1'] > te_top[0]: te_top = (i['top1'], i['impuesto'])
        if n_te >= 100 and i['top1'] > top1[0]: top1 = (i['top1'], f"TE {i['impuesto']} (n={n_te})")
    te_menor = len(tasas['impuestos']) if n_te < sello_n else 0

    # --- PIBE y neto del ciclo (vista §4b de contrato-32.py) ---
    fila = tabla.get(e['abrev'], {})
    pibe = None
    pp = num(fila.get('pibe_pesos')) if fila else None
    neto = ciclo['totales']['entidad']['neto']
    if pp:
        vint = pibe_vintage
        meta_dta = os.path.join(U, '..', '..', 'master', f"PIBDeflactor{e['abrev']}.meta")
        if not vint and os.path.isfile(meta_dta):
            for l in open(meta_dta, encoding='utf-8', errors='replace'):
                if l.startswith('base_generada='): vint = l.split('=', 1)[1].strip()[:10]
        pibe = {'pibe_pesos': pp, 'neto_pesos': neto, 'neto_pct_pibe': neto / pp * 100, 'vintage': vint or 'not declared in this run (no master/PIBDeflactor<ABREV>.meta beside users/ and no --pibe-vintage)',
                'fuente_vintage': 'master/PIBDeflactor<ABREV>.meta base_generada (sello pibe-32) o --pibe-vintage',
                'anio_vp': ciclo['anio_vp'], 'fuente_pibe': 'contrato-32.tsv pibe_pesos = scalar pibY<ABREV> de PIBDeflactor por entidad (base master/PIBDeflactor<ABREV>.dta)',
                'fuente_neto': 'ciclo-vida.json totales.entidad.neto (pesos de anio_vp)',
                'calculo': 'neto_pct_pibe = neto_pesos / pibe_pesos * 100, dividido en generar-entidades.py (igual que contrato-32.py §4b); FLAG v8.13.0: única división fuera de Stata'}
    nac = ciclo['totales']['nacional']
    nacional = {'neto_pesos': nac['neto'], 'pib_pesos': nac['pibY'], 'neto_pct_pib': nac['neto'] / nac['pibY'] * 100 if nac.get('pibY') else None,
                'share_pob': nac['share_pob'], 'share_neto': nac['share_neto'], 'n': nac['n'], 'pob': nac['pob']}

    conteo = {'sankeys_micro': [n_sell, n_micro], 'ciclo': [len(ci), len(ciclo['celdas'])], 'tasas': [len(te), len(tasas['impuestos'])]}
    texto_conteo = f'{n_sell}/{n_micro} / {len(ci)}/{len(ciclo["celdas"])} / {len(te)}/{len(tasas["impuestos"])}'
    tabla_32 = None
    if tabla_md:
        ref = tabla_md.get(e['abrev'])
        tabla_32 = {'fuente': 'contrato-32.md §4, columna «selladas: sankeys micro / ciclo / TE»', 'tabla': ref, 'corrida': texto_conteo, 'coincide': (ref == texto_conteo) if ref else None}

    return {
        'esquema': 'entidad-meta/v1',
        'entidad': {'nombre': e['nombre'], 'clave': e['clave'], 'abrev': e['abrev'], 'pos': e['pos']},
        'muestra': {'n': n_te, 'n_ciclo': ciclo['totales']['entidad']['n'], 'pob': tasas['muestra']['pob'], 'anio_enigh': ciclo['anio_enigh'],
                    'anio_politica': ciclo['anio_politica'], 'anio_vp': ciclo['anio_vp'], 'paquete': ciclo['paquete']},
        'parametros': {'sello_n': sello_n, 'sello_top1': sello_top1, 'regla': ciclo['parametros']['regla_sello']},
        'sellos': {'conteo': conteo, 'texto': texto_conteo,
                   'celdas_n_menor': {'sankeys_micro': n_menor, 'ciclo': ci_menor, 'tasas': te_menor, 'total': n_menor + ci_menor + te_menor},
                   'sankeys': sk, 'ciclo': ci, 'tasas': te,
                   'top1_n100': {'pct': top1[0], 'donde': top1[1]}, 'top1_te': {'pct': te_top[0], 'impuesto': te_top[1]}},
        'ciclo': {'neto_pesos': neto, 'aporta_pesos': ciclo['totales']['entidad']['aporta'], 'recibe_pesos': ciclo['totales']['entidad']['recibe'], 'pob': ciclo['totales']['entidad']['pob']},
        'pibe': pibe,
        'nacional': nacional,
        'tabla_32': tabla_32,
        'procedencia': {'generador': VERSION, 'commit': commit, 'insumos': ['ciclo-vida.json', 'tasas-efectivas.json'] + [f'sankey-{k}.json' for k in sk] + (['contrato-32.tsv'] if fila else []),
                        'modulos': {'ciclo': ciclo['procedencia']['modulo'], 'tasas': tasas['procedencia']['modulo']},
                        'generado_el': generado_el},
    }


def cmd_meta(a):
    cat = leer_catalogo(a.catalogo)
    U = a.users
    tabla = leer_tabla_tsv(a.tabla)
    tabla_md = leer_tabla_md(a.tabla_md)
    generado_el = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    try:
        commit = subprocess.run(['git', '-C', raiz_repo(), 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        commit = ''
    metas = []; faltan = []
    for e in cat:
        d = os.path.join(U, e['abrev'])
        if not (os.path.isfile(os.path.join(d, 'ciclo-vida.json')) and os.path.isfile(os.path.join(d, 'tasas-efectivas.json'))):
            faltan.append(e['abrev']); continue
        metas.append(meta_entidad(e, U, tabla, tabla_md, generado_el, commit, a.pibe_vintage))
    if not metas:
        sys.exit(f'generar-entidades meta: ninguna entidad con ciclo-vida.json + tasas-efectivas.json en {U}')
    # índice de las 32 (y la discrepancia Σ32 PIBE vs PIB nacional, informativa)
    pibes = [m['pibe']['pibe_pesos'] for m in metas if m['pibe']]
    pib_nac = metas[0]['nacional']['pib_pesos']
    suma = sum(pibes) if len(pibes) == 32 else None
    filas = []
    for m in metas:
        filas.append({'pos': m['entidad']['pos'], 'abrev': m['entidad']['abrev'], 'clave': m['entidad']['clave'], 'nombre': m['entidad']['nombre'],
                      'n': m['muestra']['n'], 'anio_enigh': m['muestra']['anio_enigh'], 'share_pob': m['nacional']['share_pob'],
                      'sellos_conteo': m['sellos']['conteo'], 'sellos_texto': m['sellos']['texto'], 'celdas_n_menor': m['sellos']['celdas_n_menor'],
                      'top1_n100': m['sellos']['top1_n100'], 'top1_te': m['sellos']['top1_te'],
                      'neto_pct_pibe': m['pibe']['neto_pct_pibe'] if m['pibe'] else None, 'pibe_pesos': m['pibe']['pibe_pesos'] if m['pibe'] else None,
                      'neto_pesos': m['ciclo']['neto_pesos'],
                      'tabla_32_coincide': m['tabla_32']['coincide'] if m['tabla_32'] else None,
                      'url': f"/entidades/{m['entidad']['abrev']}"})
    pibe_32 = {'suma_pesos': suma, 'pib_nacional_pesos': pib_nac, 'discrepancia_pct': (suma / pib_nac - 1) * 100 if (suma and pib_nac) else None,
               'entidades_con_pibe': len(pibes), 'nota': 'Σ32 PIBE (año de valor presente) vs PIB nacional de la corrida (ciclo-vida.json totales.nacional.pibY): informativa, no se gatea (contrato-32.md §4b)'}
    for m in metas:   # cada meta.json lleva también la discrepancia Σ32 (la página la cita en la nota al pie del producto neto/PIBE)
        m['pibe_32'] = pibe_32
        json.dump(m, open(os.path.join(U, m['entidad']['abrev'], 'meta.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    indice = {
        'esquema': 'entidades-indice/v1',
        'entidades': filas,
        'parametros': metas[0]['parametros'],
        'nacional': {'n': metas[0]['nacional']['n'], 'pob': metas[0]['nacional']['pob'], 'neto_pesos': metas[0]['nacional']['neto_pesos'], 'pib_pesos': pib_nac,
                     'neto_pct_pib': metas[0]['nacional']['neto_pct_pib'], 'anio_enigh': metas[0]['muestra']['anio_enigh'], 'anio_vp': metas[0]['muestra']['anio_vp'], 'paquete': metas[0]['muestra']['paquete']},
        'pibe_32': pibe_32,
        'faltan': faltan,
        'procedencia': {'generador': VERSION, 'commit': commit, 'tabla': os.path.basename(a.tabla) if a.tabla else None, 'tabla_md': os.path.basename(a.tabla_md) if a.tabla_md else None, 'generado_el': generado_el},
    }
    json.dump(indice, open(os.path.join(U, 'entidades.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'generar-entidades meta: {len(metas)}/32 meta.json + entidades.json en {U}' + (f' (faltan: {", ".join(faltan)})' if faltan else ''))
    if tabla_md:
        dif = [m['entidad']['abrev'] + f" (tabla {m['tabla_32']['tabla']} vs corrida {m['tabla_32']['corrida']})" for m in metas if m['tabla_32'] and m['tabla_32']['coincide'] is False]
        print('  sellos vs tabla de las 32: ' + ('coinciden en las ' + str(len(metas)) if not dif else f'{len(dif)} difieren: ' + '; '.join(dif)))
    if suma: print(f"  Σ32 PIBE = {suma/1e6:,.0f} mdp vs PIB nacional {pib_nac/1e6:,.0f} mdp ({indice['pibe_32']['discrepancia_pct']:+.2f} %, informativo)")
    else: print(f'  PIBE: {len(pibes)}/32 con pibe_pesos' + ('' if a.tabla else ' (sin --tabla: el producto neto/PIBE queda declarado como no disponible)'))
    return 0 if not faltan else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--catalogo', default=os.path.join(raiz_repo(), 'SIMentidad.ado'))
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('paginas'); p.add_argument('--check', action='store_true')
    p.add_argument('--sitio', default=os.path.join(raiz_repo(), '04_1_simuladorfiscal.ciep.mx', 'entidades'))
    m = sub.add_parser('meta'); m.add_argument('--users', required=True); m.add_argument('--tabla'); m.add_argument('--tabla-md'); m.add_argument('--pibe-vintage', help='fecha (AAAA-MM-DD) de las bases PIBDeflactor<ABREV>.dta si no hay master/PIBDeflactor<ABREV>.meta junto a users/')
    a = ap.parse_args()
    sys.exit(cmd_paginas(a) if a.cmd == 'paginas' else cmd_meta(a))


if __name__ == '__main__':
    main()
