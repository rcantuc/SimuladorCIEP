#!/usr/bin/env python3
"""perfilar-web.py — auxiliar de perfilar-web.sh (v8.12 fase 1: medición, cero optimización).

Subcomandos (los orquesta perfilar-web.sh; no se corren a mano normalmente):

  escenario  <root>                      -> JSON {llave: valor} del escenario default nacional,
                                            leído de users/ricardo/output.txt con el MISMO mapeo
                                            que hace el sitio (cargaDefault.php + stataCalcula.js
                                            + index.php) antes de que el usuario pulse «Calcular».
  generar    <template> <out> <root> <id> <escenario.json> [--instrumentar] [--traza]
                                         -> el .do de la sesión: la misma sustitución {{llave}}
                                            que calculaStata.php, con SITE = <root>/ (equivale al
                                            /SIM/OUT/current/ del VPS). --instrumentar inserta
                                            los hooks de tiempo (timer por sección, rmsg,
                                            profiler) en la COPIA; Web.Stata.do versionado no
                                            se toca. --traza activa set trace (inventario I/O).
  inventario <traza.log> <out.json> <piso-io.do> <root> <id>
                                         -> archivos leídos/escritos por el flujo (parseo de la
                                            traza) + un .do que mide el piso de I/O (use/save
                                            aislados de cada archivo, 3 repeticiones).
  resumen    <evidencia> <n_runs>        -> resumen.md (tabla sección × corrida, media ± DE, %,
                                            rmsg por comando, profiler por programa, piso I/O).
"""
import json
import os
import re
import statistics
import sys

# ---------------------------------------------------------------------------
# Llaves del formulario (copia literal de $llaves en calculaStata.php). La
# sustitución se hace SOLO sobre estas llaves, en este orden, como el PHP.
# ---------------------------------------------------------------------------
LLAVES = (
    ['idSession']
    + ['INGRESOS%d' % i for i in (0, 1, 2, 4, 5, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17)]
    + ['CRECPIB%d' % a for a in range(2026, 2033)]
    + ['CRECDEF%d' % a for a in range(2026, 2033)]
    + ['iniciaA', 'basica', 'medsup', 'superi', 'posgra', 'eduadu', 'otrose', 'invere', 'cultur', 'invest',
       'ssa', 'imssbien', 'imss', 'issste', 'pemex', 'issfam', 'invers',
       'bienestar', 'penims', 'peniss', 'penpeme', 'penotr',
       'gascfe', 'gaspemex', 'gassener', 'gasinverf', 'gascosdeue',
       'gasinfra', 'gasotros', 'gasfeder', 'gascosto',
       'IngBas', 'ingbasico18', 'ingbasico65', 'gasmadres', 'gascuidados']
    + ['ISRTASA%d' % i for i in range(11)]
    + ['SE%d' % i for i in range(11)]
    + ['DED%d' % i for i in range(4)]
    + ['ISRMORA0', 'ISRMORA1']
    + ['CSSIMSS%d' % i for i in range(21)]
    + ['CSSISSSTE%d' % i for i in range(24)]
    + ['IVAT%d' % i for i in range(13)]
    + ['DEUDA0', 'moduloCambio', 'moduloCambioIva']
)

# Orden DOM de los <input class="GASTOS"> en index.php (40 elementos; los None son
# los subtotales sin id). stataCalcula.js hace $(".GASTOS").each(i -> GASTOS[i]).
GASTOS_DOM = ['iniciaA', 'basica', 'medsup', 'superi', 'posgra', 'eduadu', 'otrose', 'invere', 'cultur', 'invest',
              None, 'ssa', 'imssbien', 'imss', 'issste', 'pemex', 'issfam', 'invers',
              None, 'bienestar', 'penims', 'peniss', 'penpeme', 'penotr',
              None, 'gascfe', 'gaspemex', 'gassener', 'gasinverf', 'gascosdeue',
              None, 'gasinfra', 'gasotros', 'gasfeder', 'gascosto',
              None, 'IngBas', 'gasmadres', 'gascuidados', None]

# ISRTASA0..10: el JS hace .html() (no .val()) sobre esos inputs, así que el
# formulario conserva el value= del HTML (index.php). Son los de output.txt.
ISRTASA_HTML = ['1.92', '6.40', '10.88', '16.00', '17.92', '21.36', '23.52', '30.00', '32.00', '34.00', '35.00']

SECCIONES = [
    # (regex de la línea ancla en Web.Stata.do, etiqueta de la sección que EMPIEZA ahí)
    (r'^\*\*# 2\. ECONOM', '2 ECONOMIA: globals pib/def/inf'),
    (r'^\*\* 3\.1 Ley de Ingresos', '3.1 LIF + collapse + save LIF.dta'),
    (r'^\*\* 3\.1\.1 Par', '3.1.1-3.1.7 parametros (scalars, matrices; submodulos apagados)'),
    (r'^\*\* 3\.1\.8 Tasas Efectivas', '3.1.8 TasasEfectivas (save ingresos.dta)'),
    (r'^\*\* 3\.2 Presupuesto', '3.2 PEF (dentro de /** ... **/: no corre)'),
    # la línea "** 3.2.1 ... **/" CIERRA el bloque /** abierto tras 3.2: la marca va DESPUÉS de ella
    (r'^\*\* 3\.2\.1 Par', '3.2.1 parametros gasto (scalars)', 'despues'),
    (r'^\*\* 3\.2\.2 Gasto per c', '3.2.2 GastoPC (save gastos.dta)'),
    (r'^\*\* 3\.3 Saldo Hist', '3.3 matrices deuda + globals + tasaEfectiva'),
    (r'^\*\*# 6\. CICLO DE VIDA', '6 use ingresos + merge gastos + save aportaciones'),
    (r'^\*\* 7\.1 \(\+\) Impuestos', '6.7 egen + Simulador(reboot, B=1) + save aportaciones'),
    (r'^\*\* 7\.1 Brecha fiscal', '7.1 FiscalGap'),
    (r'^\*\* 7\.2 Sankey', '7.2 SankeySF x5 (decil grupoedad sexo rural escol)'),
    (r'^\*\*\*\* Touchdown', '8 output.do (log on -> output.txt + filefilter)'),
]

PROG_PERF = r'''
* ---- hooks de perfilado (perfilar-web.sh; NO viven en Web.Stata.do) ----
* _perf_mark: cierra el timer y el profiler de la sección anterior (imprime el
* reporte del profiler DE ESA SECCIÓN) y abre los de la siguiente. Timers 51..
* para no chocar con los de los ado (1-15, 33). Sin efecto en los números: solo
* timer/rmsg/profiler, y rmsg se apaga antes de output.do.
program define _perf_mark
	args lbl
	if "$perf_n" == "" global perf_n = 0
	if $perf_n > 0 _perf_cierra
	global perf_n = $perf_n + 1
	global perf_lbl_$perf_n `"`lbl'"'
	noisily di in g "PERF_MARK|" $perf_n "|`lbl'|" c(current_time)
	profiler on
	timer on `=50+$perf_n'
end
program define _perf_cierra
	timer off `=50+$perf_n'
	profiler off
	noisily di in g "PERF_PROFILER_BEGIN|" $perf_n
	noisily profiler report
	noisily di in g "PERF_PROFILER_END"
	profiler clear
end
program define _perf_report
	_perf_cierra
	quietly timer list 1
	noisily di in g "PERF_T1|" r(t1)
	forvalues k = 1/$perf_n {
		quietly timer list `=50+`k''
		noisily di in g "PERF|`k'|${perf_lbl_`k'}|" %12.4f r(t`=50+`k'')
	}
	noisily di in g "PERF_STATA|" c(stata_version) "|" c(edition) "|" c(processors) "|" c(os) "|" c(machine_type) "|" c(born_date)
end
_perf_mark "0 SET UP (sysdir, cd, scalars, log using)"
'''


def fail(msg):
    sys.exit('perfilar-web.py: ' + msg)


# ---------------------------------------------------------------------------
def leer_output(path):
    """output.txt (log de Stata) -> {NOMBRE: [valores]} con la misma unión de
    continuaciones '\\n> ' que hace cargaDefault.php."""
    t = open(path, encoding='utf-8', errors='replace').read()
    t = re.sub(r'\n>\s*', '', t)
    datos = {}
    for linea in t.split('\n'):
        linea = linea.strip()
        if not linea or linea.startswith('.') or ':' not in linea:
            continue
        k, v = linea.split(':', 1)
        v = v.strip()
        m = re.match(r'^\[(.*)\]$', v, re.S)
        datos[k.strip()] = [x.strip() for x in m.group(1).split(',')] if m else [v]
    return datos


def cmd_escenario(root):
    """root = raíz del repo (lee users/ricardo/output.txt) o, desde v8.12.1, un ARCHIVO: un output.txt
    o el JSON que devuelve cargaDefault.php ({NOMBRE: [valores]}) — así humo-calcular.sh arma el
    escenario default exactamente como lo hace el JS del sitio, a partir de lo que el sitio sirve."""
    if os.path.isfile(root):
        src = root
    else:
        src = os.path.join(root, 'users', 'ricardo', 'output.txt')
        if not os.path.isfile(src):
            fail('no existe ' + src + ' (escenario default publicado; publicar-vps.sh Fase 3b-ter lo copia a users/ciepmx/)')
    if src.endswith('.json'):
        d = json.load(open(src, encoding='utf-8'))
        d = {k: ([str(x) for x in v] if isinstance(v, list) else [str(v)]) for k, v in d.items()}
    else:
        d = leer_output(src)
    for k in ('INGRESOS', 'GASTOS', 'CRECPIB', 'CRECDEF', 'DEUDAPARAM', 'ISRSUBS', 'ISRDEDU', 'ISRMORA',
              'CSSIMSS', 'CSSISSSTE', 'IVA', 'GASTOSPC'):
        if k not in d:
            fail('output.txt sin la llave %s' % k)
    e = {}
    for i in (0, 1, 2, 4, 5, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17):
        e['INGRESOS%d' % i] = d['INGRESOS'][i]              # id INGRESOSk <- INGRESOS[k] (stataCalcula.js 514-555)
    for j, a in enumerate(range(2026, 2033)):
        e['CRECPIB%d' % a] = d['CRECPIB'][j]
        e['CRECDEF%d' % a] = d['CRECDEF'][j]
    for i, nombre in enumerate(GASTOS_DOM):                   # $(".GASTOS").each(i -> GASTOS[i])
        if nombre:
            e[nombre] = d['GASTOS'][i]
    e['ingbasico18'] = '1' if d['GASTOSPC'][38] not in ('0', '0.0', '') else '0'   # checkbox -> +is(":checked")
    e['ingbasico65'] = '1' if d['GASTOSPC'][39] not in ('0', '0.0', '') else '0'
    for i in range(11):
        e['ISRTASA%d' % i] = ISRTASA_HTML[i]
        e['SE%d' % i] = d['ISRSUBS'][i]
    for i in range(4):
        e['DED%d' % i] = d['ISRDEDU'][i]
    e['ISRMORA0'], e['ISRMORA1'] = d['ISRMORA'][0], d['ISRMORA'][1]
    for i in range(21):
        e['CSSIMSS%d' % i] = d['CSSIMSS'][i]
    for i in range(24):
        e['CSSISSSTE%d' % i] = d['CSSISSSTE'][i]
    for i in range(13):
        v = d['IVA'][i]
        e['IVAT%d' % i] = v if i in (0, 12) else str(int(float(v)))   # radios 1/2/3
    e['DEUDA0'] = d['DEUDAPARAM'][0]
    e['moduloCambio'] = '0'                                    # hidden value="" -> lee_numero -> "0"
    e['moduloCambioIva'] = '0'
    # misma normalización que lee_numero(): vacío -> "0", "12%" -> "12"
    for k, v in list(e.items()):
        v = v.strip()
        if v.endswith('%'):
            v = v[:-1].strip()
        e[k] = v or '0'
    print(json.dumps(e, indent=1, sort_keys=True))


# ---------------------------------------------------------------------------
def cmd_generar(template, out, root, sid, esc_json, instrumentar=False, traza=False):
    t = open(template, encoding='utf-8').read()
    e = json.load(open(esc_json, encoding='utf-8'))
    e['idSession'] = sid
    # SITE del Mac -> raíz elegida (el VPS usa /SIM/OUT/current/). Es la ÚNICA
    # edición fuera de la sustitución {{llave}}; aplica igual al baseline.
    t, n = re.subn(r'^(\tsysdir set SITE ")/Users/ricardo/[^"]*/SimuladorCIEP/(")', r'\g<1>%s/\2' % root.rstrip('/'), t, count=1, flags=re.M)
    if n != 1:
        fail('no se encontró la línea sysdir set SITE del Mac en ' + template)
    for k in LLAVES:                                           # mismo orden y mismo str_replace que calculaStata.php
        t = t.replace('{{' + k + '}}', e.get(k, '0'))
    rest = sorted(set(re.findall(r'\{\{(\w+)\}\}', t)))
    if rest:
        fail('placeholders sin sustituir (no están en $llaves del PHP): ' + ' '.join(rest))
    if instrumentar:
        t, n = re.subn(r'^timer on 1\n', 'timer on 1\n' + PROG_PERF + ('set trace on\nset tracedepth 3\nset tracenumber off\nset traceexpand on\nset tracesep off\nset traceindent off\n' if traza else ''), t, count=1, flags=re.M)
        if n != 1:
            fail('no se encontró "timer on 1"')
        lines = t.split('\n')
        outl = []
        pend = list(SECCIONES)
        for ln in lines:
            if pend and re.match(pend[0][0], ln):
                sec = pend.pop(0)
                hook = []
                if sec[1].startswith('2 '):
                    hook.append('set rmsg on')               # tras el log using/log off de §0: el r; de `log using` entraba a output.txt
                if sec[1].startswith('8 '):
                    hook.append('set rmsg off')              # rmsg no debe entrar a output.txt
                    if traza:
                        hook.append('set trace off')
                hook.append('_perf_mark "%s"' % sec[1])
                if len(sec) > 2 and sec[2] == 'despues':
                    outl.append(ln)
                    outl.extend(hook)
                    continue
                outl.extend(hook)
            outl.append(ln)
        if pend:
            fail('anclas no encontradas en el template: ' + '; '.join(p[1] for p in pend))
        t = '\n'.join(outl)
        if not t.endswith('\n'):
            t += '\n'
        t += '_perf_report\n'
    open(out, 'w', encoding='utf-8').write(t)


# ---------------------------------------------------------------------------
VERBOS_IO = re.compile(r'^\s*(?:(?:qui(?:etly)?|noi(?:sily)?|cap(?:ture)?)\s+)*'
                       r'(use|merge|append|save|saveold|import|export|insheet|outsheet|copy|erase|filefilter|file open|'
                       r'confirm file|graph export|graph save|findfile|include|run|do)\b(.*)$')


def _paths_de(cmd, resto):
    # extrae rutas con /; descarta tempfiles (viven en /var/folders, /tmp) para el inventario de disco real
    cands = re.findall(r'"([^"]+)"|`"([^"]+)"\'|(\S+)', resto)
    out = []
    for a, b, c in cands:
        p = a or b or c
        p = p.strip('`\'",')
        if '/' in p and not p.startswith(('/var/folders', '/tmp', '//', '/*')):
            out.append(p)
    return out


def cmd_inventario(trazalog, outjson, pisodo, root='', sid=''):
    inv = {}
    seccion = '(antes de la primera marca)'
    # el log parte las líneas largas en linesize y continúa con "> ": se unen antes de parsear
    texto = re.sub(r'\n> ', '', open(trazalog, encoding='utf-8', errors='replace').read())
    for ln in texto.split('\n'):
        m = re.match(r'^PERF_MARK\|\d+\|([^|]*)\|', ln)
        if m:
            seccion = m.group(1)
            continue
        # líneas de traza: '- cmd' (sin expandir) y '= cmd' (expandida). Preferimos '='.
        # Los comandos de PRIMER nivel del .do no se trazan: van como eco '. cmd' con
        # ${SIMROOT}/$id sin expandir; se expanden a mano (root e id de la corrida).
        m = re.match(r'^\s*([=.-])\s(.*)$', ln)
        if not m:
            continue
        body = m.group(2)
        if m.group(1) == '.':
            body = body.replace('${SIMROOT}', root).replace('$id', sid)
            if re.match(r'^\s*(?:noisily\s+|capture\s+)*(run|do|include)\b', body):
                continue                                        # el eco de un bloque if {...} de primer nivel sale completo aunque no corra
        if m.group(1) == '-' and ('`' in body or '$' in body):
            continue                                            # vendrá su versión '=' expandida
        mv = VERBOS_IO.match(body)
        if not mv:
            continue
        verbo = mv.group(1)
        for p in _paths_de(verbo, mv.group(2)):
            if verbo in ('erase', 'findfile', 'confirm file'):
                continue
            modo = 'escribe' if verbo in ('save', 'saveold', 'export', 'outsheet', 'copy', 'filefilter', 'graph export', 'graph save') else 'lee'
            if verbo == 'merge' or verbo == 'append':
                mu = re.search(r'using\s+`?"?([^",\s`\']+)', body)
                if mu:
                    p = mu.group(1)
            if not p.endswith(('.dta', '.csv', '.xlsx', '.xls', '.json', '.txt', '.do', '.ado')):
                p = p + '.dta' if verbo in ('use', 'merge', 'append', 'save') else p
            if not os.path.isabs(p) or not os.path.isfile(p):
                continue                                        # capture merge de archivos que no existen (isr_mod/iva_mod)
            k = (modo, p)
            ent = inv.setdefault(k, {'modo': modo, 'archivo': p, 'veces': 0, 'secciones': [], 'bytes': os.path.getsize(p) if os.path.isfile(p) else None})
            ent['veces'] += 1
            if seccion not in ent['secciones']:
                ent['secciones'].append(seccion)
    lista = sorted(inv.values(), key=lambda x: (-(x['bytes'] or 0), x['archivo']))
    json.dump(lista, open(outjson, 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    # piso de I/O: use (lectura completa) de cada .dta leído y save de uno equivalente
    # a cada .dta escrito (a un tempfile), 3 repeticiones, timers 1..n
    do = ['* piso-io.do — generado por perfilar-web.py: tiempo de use/save AISLADO por archivo',
          'clear all', 'set more off', 'set linesize 255', 'timer clear', 'local n = 0']
    for ent in lista:
        if not ent['archivo'].endswith('.dta') or not os.path.isfile(ent['archivo']):
            continue
        do.append('local n = `n\' + 1')
        do.append('forvalues r = 1/3 {')
        do.append('\ttimer on `n\'')
        do.append('\tuse "%s", clear' % ent['archivo'])
        if ent['modo'] == 'escribe':
            do.append('\ttempfile w')
            do.append('\tsave `w\', replace')
        do.append('\ttimer off `n\'')
        do.append('}')
        do.append('quietly timer list `n\'')
        do.append('noisily di "PERF_IO|%s|%s|%s|" %%12.4f r(t`n\')/3' % (ent['modo'], ent['archivo'], ent['bytes']))
    open(pisodo, 'w', encoding='utf-8').write('\n'.join(do) + '\n')


# ---------------------------------------------------------------------------
def parse_log(path):
    """log de una corrida instrumentada -> dict con secciones, rmsg por comando, profiler, t1."""
    res = {'secciones': [], 'rmsg': [], 'profiler': [], 't1': None, 'stata': None}
    cmd, in_prof, eco, psec = None, False, False, 0
    for raw in open(path, encoding='utf-8', errors='replace'):
        ln = raw.rstrip('\n')
        if eco and not ln.startswith('> '):
            eco = False
        m = re.match(r'^PERF\|(\d+)\|([^|]*)\|\s*([\d.]+)$', ln)
        if m:
            res['secciones'].append((int(m.group(1)), m.group(2), float(m.group(3))))
            continue
        m = re.match(r'^PERF_T1\|([\d.]+)', ln)
        if m:
            res['t1'] = float(m.group(1))
            continue
        m = re.match(r'^PERF_STATA\|(.*)$', ln)
        if m:
            res['stata'] = m.group(1)
            continue
        m = re.match(r'^PERF_PROFILER_BEGIN\|(\d+)', ln)
        if m:
            in_prof, psec = True, int(m.group(1))
            continue
        if ln == 'PERF_PROFILER_END':
            in_prof = False
            continue
        if in_prof:
            m = re.match(r'^\s+(\d+)\s+([\d.]+)\s+(\S+)\s*$', ln)
            if m:
                res['profiler'].append((psec, m.group(3), int(m.group(1)), float(m.group(2))))
            continue
        if ln.startswith('. '):
            # rmsg se atribuye al PRIMER eco no-comentario desde el r; anterior: los
            # ecos posteriores son de do-files anidados (p.ej. TarjetaRFSP.do dentro
            # de FiscalGap), que no reciben r; propio
            x = ln[2:].strip()
            if cmd is None and x and not x.startswith(('*', '//')):
                cmd, eco = x, True
            continue
        if ln.startswith('> ') and eco:
            cmd += ' ' + ln[2:].strip()
            continue
        m = re.match(r'^r; t=([\d.]+)\s', ln)
        if m and cmd is not None:
            res['rmsg'].append((cmd, float(m.group(1))))
            cmd = None
    return res


def fmt(x, nd=2):
    return ('%.' + str(nd) + 'f') % x


def cmd_resumen(evid, nruns):
    runs = []
    for i in range(1, nruns + 1):
        p = os.path.join(evid, 'perfrun%d' % i, 'perfrun%d.log' % i)
        if os.path.isfile(p):
            runs.append(parse_log(p))
    if not runs:
        fail('sin logs instrumentados en ' + evid)
    wall = {}
    pw = os.path.join(evid, 'wall.txt')
    if os.path.isfile(pw):
        for ln in open(pw):
            k, v = ln.split()[:2]
            wall[k] = float(v)
    out = []
    out.append('## Resumen generado por perfilar-web.sh\n')
    if runs[0]['stata']:
        out.append('Stata: `%s` (stata_version|edition|processors|os|machine_type|born_date)\n' % runs[0]['stata'])
    out.append('Corridas instrumentadas: %d. Baseline no instrumentado: %s.\n' % (len(runs), 'sí' if 'perfbase' in wall else 'no'))
    # --- pared
    out.append('### Tiempo de pared (shell, `stata -b do`, incluye arranque de Stata y sysprofile)\n')
    out.append('| corrida | pared (s) | timer 1 de Web.Stata.do (s) | arranque + cierre (s) |')
    out.append('|---|---:|---:|---:|')
    if 'perfbase' in wall:
        out.append('| perfbase (sin hooks) | %s | — | — |' % fmt(wall['perfbase']))
    for i, r in enumerate(runs, 1):
        w = wall.get('perfrun%d' % i)
        out.append('| perfrun%d | %s | %s | %s |' % (i, fmt(w) if w else '—', fmt(r['t1']) if r['t1'] else '—',
                                                      fmt(w - r['t1']) if (w and r['t1']) else '—'))
    # --- secciones
    out.append('\n### Secciones de Web.Stata.do (timer de Stata, segundos de pared)\n')
    labels = [s[1] for s in runs[0]['secciones']]
    tot = [sum(s[2] for s in r['secciones']) for r in runs]
    out.append('| # | sección | ' + ' | '.join('run%d' % i for i in range(1, len(runs) + 1)) + ' | media | DE | % del total |')
    out.append('|---|---|' + '---:|' * (len(runs) + 3))
    for k, lbl in enumerate(labels):
        vals = [r['secciones'][k][2] for r in runs if k < len(r['secciones'])]
        mu = statistics.mean(vals)
        sd = statistics.pstdev(vals) if len(vals) > 1 else 0.0
        out.append('| %d | %s | %s | %s | %s | %s |' % (k + 1, lbl, ' | '.join(fmt(v) for v in vals), fmt(mu), fmt(sd), fmt(100 * mu / statistics.mean(tot), 1)))
    out.append('| | **total secciones** | %s | %s | %s | 100 |' % (' | '.join(fmt(v) for v in tot), fmt(statistics.mean(tot)), fmt(statistics.pstdev(tot) if len(tot) > 1 else 0)))
    # --- rmsg por comando
    out.append('\n### Comandos de primer nivel con rmsg (media de las corridas; ≥ 0.05 s)\n')
    out.append('| comando (truncado) | media (s) | min | max |')
    out.append('|---|---:|---:|---:|')
    n = min(len(r['rmsg']) for r in runs)
    filas = []
    for k in range(n):
        cmds = {r['rmsg'][k][0] for r in runs}
        if len(cmds) != 1:
            continue
        vals = [r['rmsg'][k][1] for r in runs]
        mu = statistics.mean(vals)
        if mu >= 0.05:
            c = runs[0]['rmsg'][k][0].replace('|', '\\|')
            filas.append((mu, '| `%s` | %s | %s | %s |' % (c[:90], fmt(mu), fmt(min(vals)), fmt(max(vals)))))
    for _, f in filas:
        out.append(f)
    # --- profiler (tiempo PROPIO de cada programa, excluye subprogramas; por sección)
    out.append('\n### Profiler de Stata por sección (tiempo propio por programa, media de las corridas; ≥ 0.10 s)\n')
    out.append('El profiler reporta tiempo *propio* (sin subprogramas): la suma de los programas de una sección ≈ su timer. '
               'Los comandos builtin (use, save, replace, generate, sort…) no aparecen: quedan en el propio del programa que los llama.\n')
    out.append('| sección | programa | llamadas | segundos (media) | % de la sección |')
    out.append('|---|---|---:|---:|---:|')
    acc = {}
    for r in runs:
        for sec, prog, calls, secs in r['profiler']:
            a = acc.setdefault((sec, prog), [0, 0.0])
            a[0] += calls
            a[1] += secs
    nr = len(runs)
    tot_sec = {}
    for (sec, prog), (calls, secs) in acc.items():
        tot_sec[sec] = tot_sec.get(sec, 0.0) + secs / nr
    for sec in sorted(tot_sec):
        if tot_sec[sec] < 0.5:
            continue
        filas = sorted(((p, c, s) for (s_, p), (c, s) in acc.items() if s_ == sec), key=lambda x: -x[2])
        for prog, calls, secs in filas:
            if secs / nr >= 0.10:
                out.append('| %d %s | %s | %d | %s | %s |' % (sec, labels[sec - 1][:28] if sec - 1 < len(labels) else '', prog, round(calls / nr), fmt(secs / nr), fmt(100 * secs / nr / tot_sec[sec], 0)))
    out.append('\n### Profiler de Stata, total del flujo (tiempo propio por programa, media; ≥ 0.10 s)\n')
    out.append('| programa | llamadas | segundos (media) | % del total |')
    out.append('|---|---:|---:|---:|')
    accp = {}
    for (sec, prog), (calls, secs) in acc.items():
        a = accp.setdefault(prog, [0, 0.0])
        a[0] += calls
        a[1] += secs
    gt = sum(v[1] for v in accp.values()) / nr
    for prog, (calls, secs) in sorted(accp.items(), key=lambda kv: -kv[1][1]):
        if secs / nr >= 0.10:
            out.append('| %s | %d | %s | %s |' % (prog, round(calls / nr), fmt(secs / nr), fmt(100 * secs / nr / gt, 0)))
    # --- piso I/O
    pio = os.path.join(evid, 'piso-io', 'piso-io.log')
    if os.path.isfile(pio):
        out.append('\n### Piso de I/O (use/save aislado, media de 3; mismos archivos que toca el flujo)\n')
        out.append('| modo | archivo | MB | s | MB/s |')
        out.append('|---|---|---:|---:|---:|')
        tot_io, chicos, t_chicos = 0.0, 0, 0.0
        for ln in open(pio, encoding='utf-8', errors='replace'):
            m = re.match(r'^PERF_IO\|(\w+)\|([^|]*)\|(\d+|None)\|\s*([\d.]+)', ln)
            if m:
                mb = int(m.group(3)) / 1e6 if m.group(3) != 'None' else 0
                s = float(m.group(4))
                tot_io += s
                if mb < 1:
                    chicos, t_chicos = chicos + 1, t_chicos + s
                    continue
                out.append('| %s | %s | %s | %s | %s |' % (m.group(1), m.group(2), fmt(mb, 1), fmt(s, 3), fmt(mb / s, 0) if s > 0 else '—'))
        out.append('| | otros %d archivos < 1 MB (RECprom, PIBDeflactor, LIF, SHRFSP, bootstraps/1) | | %s | |' % (chicos, fmt(t_chicos, 3)))
        out.append('| | **suma** | | %s | |' % fmt(tot_io))
    inv = os.path.join(evid, 'inventario-io.json')
    if os.path.isfile(inv):
        lista = json.load(open(inv, encoding='utf-8'))
        out.append('\n### Inventario de archivos (traza; `veces` = aperturas en una corrida)\n')
        out.append('| modo | archivo | MB | veces | secciones |')
        out.append('|---|---|---:|---:|---|')
        for ent in lista:
            out.append('| %s | %s | %s | %d | %s |' % (ent['modo'], ent['archivo'], fmt((ent['bytes'] or 0) / 1e6, 1), ent['veces'], '; '.join(ent['secciones'])))
    txt = '\n'.join(out) + '\n'
    open(os.path.join(evid, 'resumen.md'), 'w', encoding='utf-8').write(txt)
    print(txt)


if __name__ == '__main__':
    a = sys.argv[1:]
    if not a:
        fail(__doc__)
    if a[0] == 'escenario':
        cmd_escenario(a[1])
    elif a[0] == 'generar':
        cmd_generar(a[1], a[2], a[3], a[4], a[5], instrumentar='--instrumentar' in a, traza='--traza' in a)
    elif a[0] == 'inventario':
        cmd_inventario(*a[1:6])
    elif a[0] == 'resumen':
        cmd_resumen(a[1], int(a[2]))
    else:
        fail('subcomando desconocido: ' + a[0])
