#!/usr/bin/env python3
"""metodo.py — /metodo generado del repo (sesión 8.18, v8.18.0). El generador LEE, no redacta.

Un capítulo por módulo, en el orden en que SIM.do los invoca, con las diez secciones de
02_governance/metodo/plantilla-capitulo.md, más el capítulo 0 (metodo/cap0-requerimientos.md). Ninguna frase del
método nace aquí: cada celda, párrafo y cifra se copia de un archivo del repo y la sección 10 («Procedencia») dice
de cuál y de qué líneas. Lo único que este script aporta son los rótulos estructurales (títulos de sección, nombres de
columna de las tablas derivadas, la etiqueta «sin protección automática — gate humano» de la plantilla §6) y el orden.

Qué lee, por capítulo:
  - el header del módulo (bloque de comentarios antes del primer comando): secciones marcadas «§N Título» o «N. Título»
    (1 Propósito, 2 Entradas, 3 Procedimiento, 4 Decisiones, 5 Anclas, 6 Salidas, 7 Identidades, 8 Límites, 9 Específico
    de México); tablas en comentarios (filas «| … |», continuación con la primera celda vacía); «procedencia: …» y
    «texto de …» como procedencia; los parámetros «nombre = valor «título» — descripción» de §4 y las líneas FLAG;
  - SIM.do §0.8–§0.8c: una línea por parámetro firmado («global x "v" // DOC · lee: módulos») y la línea en que SIM.do
    invoca cada módulo (orden_en_SIM);
  - los memos 02_governance/CUAD-*.md (su «Encabezado» dice a qué módulo documentan; MEMOS abajo declara el reparto de
    las tablas de CUAD-1 entre Expenditure y TasasEfectivas): §1–§10 como texto y tablas;
  - 02_governance/scn-celdas.md (tablas A–D: celdas BIE/CSI que lee SCN.ado) y 05_scripts/scn-cuentas.csv (nombres INEGI);
  - 05_scripts/manifest.json (version, enigh_vintage, data_updated, baseline, assets con «desde», scn_vintage) y
    05_scripts/itan-catalogo.json (fuente, rangos, archivos congelados);
  - 05_scripts/fixtures/nta-identidad.txt y 05_scripts/fixtures/gate-numeros.txt (resultado de los gates de la última
    corrida completa, con su commit), y qué script de 05_scripts/ protege cada salida (grep del nombre del archivo);
  - el código de cada módulo: secciones numeradas «** N.N Título **» (§3 Procedimiento: qué hace y en qué líneas),
    ensure_asset / use master/ (§2 Entradas) y save / file open / scalarjson / SankeySumSim (§6 Salidas);
  - 05_scripts/manifiesto-default.py --tsv (qué página del sitio pide cada salida).

Qué emite (04_1_simuladorfiscal.ciep.mx/metodo/):
  - metodo.json: {version, anios, secciones, capitulos: [...], cap0, bibliografia}; un objeto por capítulo con los
    campos del esquema de la plantilla (proposito, entradas, pasos, decisiones, anclas, salidas, identidades, limites,
    especifico_mx, procedencia) y, para la página, `secciones[n] = {texto, tablas, lista, vacia, flag}`;
  - metodo-en.json (8.19): el mismo JSON con cada cadena de texto pasada por 02_governance/metodo/traduccion-en.json (memoria
    de traducción revisable en PR; --check falla si falta una cadena, --pendientes-en <ruta> vuelca las que faltan); la página
    lo lee con ?lang=en;
  - index.php, cap0/index.php y <Modulo>/index.php: cascarones PHP sobre plantilla-metodo.php; TODO el contenido lo pinta
    js/metodo-capitulo.js desde metodo.json (cero literales de 4+ dígitos en PHP/JS: test-sitio-metodo.sh lo exige).
Sello de cada capítulo: rojo si falta alguna de las secciones 1, 3, 6 o 9 (FLAG «header incompleto: §n»); si no, el
peor sello declarado en sus entradas (§2) y anclas (§5); «sin sello» si ninguna fila lo declara.

Uso:
  python3 -I 05_scripts/metodo.py [--root <repo>]            genera metodo.json y las páginas (escribe en el repo)
  python3 -I 05_scripts/metodo.py --check                     regenera a un temporal y compara byte a byte (exit 1 si difiere)
  python3 -I 05_scripts/metodo.py --reporte                   imprime capítulos, sello, secciones vacías y FLAGs (no escribe)
  python3 -I 05_scripts/metodo.py --json-a <ruta>             solo el JSON, a otra ruta (para pruebas)
  python3 -I 05_scripts/metodo.py --pendientes-en <ruta>      vuelca (JSON) las cadenas sin traducción al inglés
Determinista: no lee la fecha ni el commit (el hash de cada archivo fuente sí, sha256 del contenido); así CI puede
regenerar y exigir bytes idénticos a lo commiteado.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

VERSION_SCRIPT = 'metodo.py v1.0 (8.18)'
SITE = '04_1_simuladorfiscal.ciep.mx'
SALIDA = SITE + '/metodo'
PLANTILLA_MD = '02_governance/metodo/plantilla-capitulo.md'
CAP0_MD = '02_governance/metodo/cap0-requerimientos.md'
FUENTES_MD = '02_governance/metodo/fuentes/README.md'

# Módulos del motor: archivos que forman cada capítulo y la línea de SIM.do que los invoca (el orden sale de SIM.do).
# `pagina`: la salida del capítulo ya es una página del sitio (el capítulo enlaza, no la sustituye).
MODULOS = [
    dict(slug='Poblacion', archivos=['Poblacion.ado'], invoca=r'^\s*noisily Poblacion\b'),
    dict(slug='PIBDeflactor', archivos=['PIBDeflactor.ado'], invoca=r'^\s*noisily PIBDeflactor\b'),
    dict(slug='SCN', archivos=['SCN.ado'], invoca=r'^\s*noisily SCN\b'),
    dict(slug='Expenditure', archivos=['01_modulos/Expenditure.do'], invoca=r'01_modulos/Expenditure\.do'),
    dict(slug='Households', archivos=['01_modulos/Households.do'], invoca=r'01_modulos/Households\.do'),
    dict(slug='NTA', archivos=['01_modulos/NTA.do'], invoca=r'01_modulos/NTA\.do', pagina='/NTA/'),
    dict(slug='PerfilesSim', archivos=['01_modulos/PerfilesSim.do'], invoca=r'01_modulos/PerfilesSim\.do'),
    dict(slug='LIF', archivos=['LIF.ado'], invoca=r'^\s*noisily LIF\b'),
    dict(slug='ISR_Mod', archivos=['01_modulos/ISR_Mod.do'], invoca=r'01_modulos/ISR_Mod\.do'),
    dict(slug='IVA_Mod', archivos=['01_modulos/IVA_Mod.do'], invoca=r'01_modulos/IVA_Mod\.do'),
    dict(slug='TasasEfectivas', archivos=['TasasEfectivas.ado'], invoca=r'^\s*noisily TasasEfectivas\b'),
    dict(slug='PEF', archivos=['PEF.ado'], invoca=r'^\s*noisily PEF\b'),
    dict(slug='Precache', archivos=['Precache.ado'], invoca=r'^\s*noisily Precache\b'),
    dict(slug='GastoPC', archivos=['GastoPC.ado'], invoca=r'^\s*noisily GastoPC\b'),
    dict(slug='SHRFSP', archivos=['SHRFSP.ado'], invoca=r'^\s*noisily SHRFSP\b'),
    dict(slug='Simulador', archivos=['Simulador.ado'], invoca=r'^\s*noisily Simulador\b'),
    dict(slug='FiscalGap', archivos=['FiscalGap.ado'], invoca=r'^\s*noisily FiscalGap\b'),
    dict(slug='SankeySF', archivos=['01_modulos/visualizations/SankeySF.do'], invoca=r'visualizations/SankeySF\.do'),
    dict(slug='Entidades', archivos=['05_scripts/contrato-32.do', '01_modulos/TasasEfectivasEntidad.do',
                                      '01_modulos/visualizations/CicloEntidad.do'],
         invoca=r'visualizations/CicloEntidad\.do', pagina='/entidades/'),
    dict(slug='output', archivos=['01_modulos/output.do'], invoca=r'01_modulos/output\.do'),
]
# Qué memo documenta qué capítulo (el «Encabezado» de cada memo lo dice en prosa; aquí la lectura mecánica). Una tabla
# cuyo subtítulo empiece con la clave del diccionario va solo a ese módulo (CUAD-1: Tabla 1 consumo / Tabla 1b impuestos).
MEMOS = [
    ('02_governance/CUAD-0.md', ['Households'], {}),
    ('02_governance/CUAD-1.md', ['Expenditure', 'TasasEfectivas'], {'Tabla 1 —': ['Expenditure'], 'Tabla 1b': ['TasasEfectivas']}),
    ('02_governance/CUAD-2.md', ['NTA'], {}),
    ('02_governance/CUAD-3.md', ['Households'], {}),
]
# Secciones de la plantilla (los títulos se leen de plantilla-capitulo.md; estas son las claves del esquema).
CLAVES = {1: 'proposito', 2: 'entradas', 3: 'pasos', 4: 'decisiones', 5: 'anclas', 6: 'salidas', 7: 'identidades',
          8: 'limites', 9: 'especifico_mx', 10: 'procedencia'}
OBLIGATORIAS = (1, 3, 6, 9)
PALABRA_SECCION = {1: r'prop[oó]sito', 2: r'entradas|qu[eé] lee', 3: r'procedimiento', 4: r'decisiones|par[aá]metros',
                   5: r'anclas', 6: r'salidas', 7: r'identidad', 8: r'l[ií]mites|flags', 9: r'espec[ií]fico'}
SELLOS = {'rojo': 3, 'amarillo': 2, 'verde': 1}
GATE_HUMANO = 'sin protección automática — gate humano'   # plantilla-capitulo.md §6


def leer(ruta):
    with open(ruta, encoding='utf-8') as f:
        return f.read()


def sha(ruta):
    return hashlib.sha256(open(ruta, 'rb').read()).hexdigest()[:12]


def md_tabla(lineas):
    """Filas «| a | b |» → (columnas, filas). La segunda fila es el separador. Celdas con la primera vacía continúan la fila
    anterior (tablas de comentarios partidas en varias líneas)."""
    filas = []
    for l in lineas:
        s = l.strip()
        if not s.startswith('|'):
            continue
        celdas = [c.strip() for c in s.strip('|').split('|')]
        if all(re.fullmatch(r':?-{2,}:?', c) for c in celdas if c) and any(celdas):
            continue
        if filas and celdas and celdas[0] == '' and len(filas) > 1 and any(celdas):
            prev = filas[-1]
            for i, c in enumerate(celdas):
                if c and i < len(prev):
                    prev[i] = (prev[i] + ' ' + c).strip()
            continue
        filas.append(celdas)
    if not filas:
        return None
    columnas, cuerpo = filas[0], filas[1:]
    ancho = len(columnas)
    cuerpo = [(f + [''] * ancho)[:ancho] for f in cuerpo]
    return columnas, cuerpo


def sello_de(texto):
    t = (texto or '').lower()
    for s in ('rojo', 'amarillo', 'verde'):
        if s in t:
            return s
    return ''


class Repo:
    def __init__(self, root):
        self.root = root
        self.manifest = json.loads(leer(os.path.join(root, '05_scripts/manifest.json')))
        self.itan = json.loads(leer(os.path.join(root, '05_scripts/itan-catalogo.json')))
        self.sim = leer(os.path.join(root, 'SIM.do')).splitlines()
        self.scripts = self._scripts()
        self.manifiesto = self._manifiesto_default()
        self.secciones_plantilla = self._secciones_plantilla()

    def p(self, rel):
        return os.path.join(self.root, rel)

    def _scripts(self):
        """Nombre → contenido de los scripts que pueden proteger una salida (05_scripts/*.sh|py|js|do y el workflow)."""
        out = {}
        d = self.p('05_scripts')
        for f in sorted(os.listdir(d)):
            if re.search(r'\.(sh|py|js|do)$', f):
                out['05_scripts/' + f] = leer(os.path.join(d, f))
        w = self.p('.github/workflows/gates-sin-stata.yml')
        if os.path.exists(w):
            out['.github/workflows/gates-sin-stata.yml'] = leer(w)
        return out

    def _manifiesto_default(self):
        """archivo (relativo a users/<id>/) → páginas que lo piden, según manifiesto-default.py --tsv."""
        out = {}
        try:
            r = subprocess.run([sys.executable, '-I', self.p('05_scripts/manifiesto-default.py'), '--root', self.root, '--tsv',
                                '--entidades', 'NL'], capture_output=True, text=True, timeout=120)
            if r.returncode == 0:
                for l in r.stdout.splitlines():
                    partes = l.split('\t')
                    if len(partes) >= 3:
                        out.setdefault(partes[0], [])
                        if partes[2] not in out[partes[0]]:
                            out[partes[0]].append(partes[2])
        except Exception:
            pass
        return out

    def _secciones_plantilla(self):
        """Títulos «## N. Título» de plantilla-capitulo.md."""
        out = {}
        for l in leer(self.p(PLANTILLA_MD)).splitlines():
            m = re.match(r'^## (\d+)\. (.+?)\s*$', l)
            if m:
                out[int(m.group(1))] = m.group(2)
        return out

    # --- SIM.do -------------------------------------------------------------------------------------------------------
    def invocacion(self, patron):
        """(número de línea, sección «**# N. TÍTULO» vigente) de la primera línea no comentada de SIM.do que casa."""
        seccion = ''
        for i, l in enumerate(self.sim, 1):
            m = re.match(r'^\*\*# (\d+\. .*?)\s*$', l)
            if m:
                seccion = m.group(1)
            if re.match(r'^\s*(\*|//)', l):
                continue
            if re.search(patron, l):
                return i, seccion
        return None, ''

    def parametros_firmados(self):
        """SIM.do §0.8–§0.8c: nombre → {valor, documento, lee, linea}."""
        out = {}
        for i, l in enumerate(self.sim, 1):
            m = re.match(r'^global (\w+) "([^"]*)"\s*//\s*(.*?)\s*·\s*lee:\s*(.*?)\s*$', l)
            if m:
                out[m.group(1)] = dict(parametro=m.group(1), firmado=m.group(2), documento=m.group(3), lee=m.group(4), linea=i)
        return out


# ---------------------------------------------------------------------------------------------------------------------
# Header de un módulo
# ---------------------------------------------------------------------------------------------------------------------
def quita_prefijo(l):
    return re.sub(r'^\s*(?:\*+!?#?|//)\s?', '', l.rstrip('\n'))


def header_lineas(texto):
    """Líneas (1-based) del bloque de comentarios inicial: hasta la primera línea con código."""
    n = 0
    for l in texto.splitlines():
        s = l.strip()
        if s == '' or s.startswith('*') or s.startswith('//'):
            n += 1
            continue
        break
    return n


def parse_header(archivo, texto):
    """Secciones §N del header con texto, tablas, procedencia y rango de líneas."""
    n_head = header_lineas(texto)
    lineas = texto.splitlines()[:n_head]
    secciones = {}
    actual = None
    for i, raw in enumerate(lineas, 1):
        s = quita_prefijo(raw)
        if s.strip() == '' and actual is None:
            continue
        m = re.match(r'^\s*(?:§\s*(\d+)|(\d+)\.)\s+(.*)$', s)
        if m:
            n = int(m.group(1) or m.group(2))
            resto = m.group(3)
            if n in PALABRA_SECCION and re.match(PALABRA_SECCION[n], resto, re.I):
                actual = n
                sec = secciones.setdefault(n, dict(lineas=[], ini=i, fin=i, procedencia=[]))
                # texto tras el título y los dos puntos
                mm = re.match(r'^[^:(]*?(?:\(([^)]*)\))?\s*:?\s*(.*)$', resto)
                if mm and mm.group(1):
                    sec['procedencia'].append(mm.group(1))
                if mm and mm.group(2):
                    sec['lineas'].append(mm.group(2))
                continue
        if actual is not None:
            sec = secciones[actual]
            sec['lineas'].append(s)
            sec['fin'] = i
            for mp in re.finditer(r'procedencia:\s*([^)\n]+)', s):
                sec['procedencia'].append(mp.group(1).strip())
    out = {}
    for n, sec in secciones.items():
        cuerpo = sec['lineas']
        tabla = md_tabla(cuerpo)
        texto_libre = [l for l in cuerpo if not l.strip().startswith('|')]
        parrafos = juntar_parrafos(texto_libre)
        out[n] = dict(archivo=archivo, ini=sec['ini'], fin=sec['fin'], texto=parrafos,
                      tablas=([dict(titulo='', columnas=tabla[0], filas=tabla[1], fuente='%s l. %d–%d' % (archivo, sec['ini'], sec['fin']))] if tabla else []),
                      crudo=cuerpo, procedencia=sec['procedencia'])
    return out, n_head


def juntar_parrafos(lineas):
    """Líneas de comentario → párrafos. Sangría ≥ 20 = continuación de la entrada anterior; sangría 2–19 = entrada nueva
    (los «nombre = valor …» de §4 y las filas de FLAG); sangría 0 = continuación del párrafo corrido anterior, o párrafo
    nuevo si lo anterior era una entrada sangrada o una línea en blanco."""
    parrafos = []
    ultima = None   # 'corrido' | 'entrada' | None
    for l in lineas:
        s = l.rstrip()
        if s.strip() == '':
            if parrafos and parrafos[-1] != '':
                parrafos.append('')
            ultima = None
            continue
        sangria = len(s) - len(s.lstrip())
        if sangria >= 20 and parrafos and parrafos[-1] != '':
            parrafos[-1] = (parrafos[-1] + ' ' + s.strip()).strip()
            continue
        if sangria >= 2:
            # línea cortada a media frase (el párrafo anterior no cierra con . : ; ? ) …) y que no empieza como una entrada
            # (viñeta, «nombre = valor», FLAG): continuación del mismo párrafo, no un párrafo nuevo (8.19: el Propósito salía
            # con un salto de línea en cada renglón del header).
            if (parrafos and parrafos[-1] != '' and ultima in ('corrido', 'continuacion')
                    and (parrafos[-1][-1] not in '.;?!…' or re.search(r'(?:^|\s)(?:vs|etc|pp?|fig|cap|art|núm)\.$', parrafos[-1]))
                    and (parrafos[-1][-1] != ':' or (s.strip()[0].islower() and parrafos[-1].startswith('Propósito')))
                    and not re.match(r'^(?:[-•*·]\s|\d+[.)]\s|FLAG\b|[A-Za-z_][\w.$-]*\s*=)', s.strip())):
                parrafos[-1] = (parrafos[-1] + ' ' + s.strip()).strip()
                ultima = 'continuacion'
                continue
            parrafos.append(s.strip())
            ultima = 'entrada'
            continue
        if ultima == 'corrido' and parrafos and parrafos[-1] != '':
            parrafos[-1] = (parrafos[-1] + ' ' + s.strip()).strip()
        else:
            parrafos.append(s.strip())
        ultima = 'corrido'
    return [p for p in parrafos if p]


def texto_sin_entradas(parrafos):
    """Quita de §4/§8 los párrafos que ya viajan como entradas tipadas (parámetros y FLAGs)."""
    return [p for p in parrafos if not re.match(r'^(\w+\s*=\s*\S+\s+«|nta_\w+\s+\(|FLAGs?\b)', p)]


def decisiones_de_texto(crudo, archivo, ini, firmados=()):
    """«nombre = valor «título» — descripción», «nta_x ("default") …» y, para parámetros firmados en SIM.do, el estilo
    «nombre   valor (qué hace) | alternativa (…)» del header de NTA.do."""
    out = []
    for k, l in enumerate(crudo):
        m = re.match(r'^\s*(\w+)\s*=\s*(\S+?)\s+«([^»]+)»\s*(.*)$', l)
        if m:
            out.append(dict(parametro=m.group(1), default=m.group(2), flag=m.group(3), texto=m.group(4).lstrip('—- ').strip(),
                            fuente='%s l. %d' % (archivo, ini + k)))
            continue
        m = re.match(r'^\s*(nta_\w+)\s+\("([^"]*)"\)\s*(.*)$', l)
        if m:
            out.append(dict(parametro=m.group(1), default=m.group(2), flag='', texto=m.group(3).strip(),
                            fuente='%s l. %d' % (archivo, ini + k)))
            continue
        m = re.match(r'^\s{1,6}(\w+)\s{2,}(\S+)\s+(\(.*)$', l)
        if m and m.group(1) in firmados:
            out.append(dict(parametro=m.group(1), default=m.group(2), flag='', texto=m.group(3).strip(),
                            fuente='%s l. %d' % (archivo, ini + k)))
            continue
        if out and re.match(r'^\s{20,}\S', l):
            out[-1]['texto'] = (out[-1]['texto'] + ' ' + l.strip()).strip()
    return out


def flags_de_texto(crudo, archivo, ini):
    out = []
    for k, l in enumerate(crudo):
        m = re.match(r'^\s*(FLAGs?\s+\S+(?:\s+[A-Z]\w*)?(?:\s*\([^)]*\))?)\s*:?\s+(.*)$', l)
        if m:
            out.append(dict(flag=m.group(1), texto=m.group(2).strip(), fuente='%s l. %d' % (archivo, ini + k)))
        elif out and re.match(r'^\s{20,}\S', l):
            out[-1]['texto'] = (out[-1]['texto'] + ' ' + l.strip()).strip()
    return out


# ---------------------------------------------------------------------------------------------------------------------
# Memos CUAD-*
# ---------------------------------------------------------------------------------------------------------------------
def parse_memo(ruta, texto):
    """Secciones «## §N …» → bloques (texto / tabla con subtítulo) y rango de líneas."""
    lineas = texto.splitlines()
    secciones = {}
    n_act = None
    sub = ''
    bloque = []

    def cierra(hasta):
        nonlocal bloque
        if n_act is None or not bloque:
            bloque = []
            return
        sec = secciones[n_act]
        ini = bloque[0][0]
        fin = bloque[-1][0]
        tabla = md_tabla([b[1] for b in bloque])
        if tabla:
            sec['bloques'].append(dict(tipo='tabla', titulo=sub, columnas=tabla[0], filas=tabla[1],
                                       fuente='%s l. %d–%d' % (ruta, ini, fin)))
        else:
            parr = ' '.join(b[1].strip() for b in bloque if b[1].strip())
            if parr:
                sec['bloques'].append(dict(tipo='texto', titulo=sub, texto=parr, fuente='%s l. %d–%d' % (ruta, ini, fin)))
        bloque = []

    for i, l in enumerate(lineas, 1):
        m2 = re.match(r'^## (.*)$', l)
        m3 = re.match(r'^### (.*)$', l)
        if m2:
            cierra(i)
            mn = re.match(r'^§(\d+)\b', m2.group(1))
            n_act = int(mn.group(1)) if mn else None
            sub = ''
            if n_act is not None:
                secciones.setdefault(n_act, dict(titulo=m2.group(1), ini=i, fin=i, bloques=[]))
            continue
        if m3:
            cierra(i)
            sub = m3.group(1)
            continue
        if n_act is None:
            continue
        secciones[n_act]['fin'] = i
        es_tabla = l.strip().startswith('|')
        if bloque and (es_tabla != bloque[-1][1].strip().startswith('|')):
            cierra(i)
        if l.strip() == '':
            cierra(i)
            continue
        bloque.append((i, l))
    cierra(len(lineas))
    return secciones


# ---------------------------------------------------------------------------------------------------------------------
# Derivaciones desde el código
# ---------------------------------------------------------------------------------------------------------------------
def secciones_codigo(archivo, texto, desde):
    """«** N.N Título **» del cuerpo del módulo (tras el header) → pasos con programa y líneas."""
    lineas = texto.splitlines()
    pasos = []
    programa = ''
    for i, l in enumerate(lineas, 1):
        if i <= desde:
            continue
        mp = re.match(r'^\s*program\s+(?:define\s+)?(\w+)', l)
        if mp:
            programa = mp.group(1)
            continue
        m = re.match(r'^\s*\*{1,4}#?\s*(\d+(?:\.\d+)?)\.?\s+([^\s*].*?)\s*\**\s*$', l)
        if m and not re.match(r'^\d', m.group(2)) and len(m.group(2)) > 2:
            pasos.append(dict(programa=programa, n=m.group(1), hace=m.group(2).strip(), ini=i))
    for k, p in enumerate(pasos):
        fin = pasos[k + 1]['ini'] - 1 if k + 1 < len(pasos) else len(lineas)
        p['lineas'] = 'l. %d–%d' % (p['ini'], fin) if fin > p['ini'] else 'l. %d' % p['ini']
        p['archivo'] = archivo
        del p['ini']
    return pasos


def entradas_codigo(archivos_texto, repo, todos):
    """ensure_asset y use/merge de master/ → filas de §2 (base, fuente, vintage, sha, sello vacío)."""
    filas = []
    vistos = set()
    assets = {a['name']: a for a in repo.manifest.get('assets', [])}
    for archivo, texto in archivos_texto:
        for i, l in enumerate(texto.splitlines(), 1):
            if re.match(r'^\s*\*', l):
                continue
            for m in re.finditer(r'ensure_asset\s+"([^"]+)"', l):
                a = assets.get(m.group(1))
                if a and m.group(1) not in vistos:
                    vistos.add(m.group(1))
                    filas.append(fila_asset(a, repo, '%s l. %d' % (archivo, i)))
            m = re.search(r'ensure_asset,\s*dir\(([^)]+)\)', l)
            if m:
                for a in repo.manifest.get('assets', []):
                    if a.get('local_path', '').startswith(m.group(1).strip('/') + '/') and a['name'] not in vistos:
                        vistos.add(a['name'])
                        filas.append(fila_asset(a, repo, '%s l. %d' % (archivo, i)))
            for m in re.finditer(r'(?:use|using)\s+(?:[^`"\']*\s+using\s+)?[`"\']*\$?\{?SIMROOT\}?/((?:master|users/\$id)/[^"\s,]+?\.dta)', l):
                nombre = m.group(1)
                if nombre in vistos:
                    continue
                vistos.add(nombre)
                patron = regex_nombre(os.path.basename(nombre))
                if any(re.search(r'save\s+[^\n]*' + (patron or re.escape(nombre)), tx) for a2, tx in archivos_texto):
                    continue
                productor = [s for s, tx in todos if s not in [a for a, _ in archivos_texto] and s != 'SIM.do' and re.search(r'save\s+[^\n]*' + (patron or re.escape(nombre)), tx)]
                filas.append(dict(base=nombre, fuente='producto del motor' + (' (' + ', '.join(sorted(set(productor))) + ')' if productor else ''),
                                  vintage=repo.manifest.get('data_updated', ''), variables='', llave='', sello='', fuente_fila='%s l. %d' % (archivo, i)))
    return filas


def fila_asset(a, repo, fuente):
    enigh = re.fullmatch(r'(\d{4})\.zip', a['name'])
    vintage = a.get('desde') or (('ENIGH ' + enigh.group(1)) if enigh else repo.manifest.get('data_updated', ''))
    if a['name'].startswith('scn-congelado'):
        sv = repo.manifest.get('scn_vintage', {})
        vintage = 'consulta %s; año de referencia %s; %s series' % (sv.get('consulta', ''), sv.get('anio_referencia', ''), sv.get('series_congeladas', ''))
    if a['name'].startswith('itan-congelado'):
        g = repo.itan.get('generado', {})
        vintage = '%s archivos, %s … %s' % (g.get('archivos', ''), g.get('primero', ''), g.get('ultimo', ''))
    return dict(base=a['name'], fuente=a.get('local_path', '') + (' — ' + a['regla'][:120] if a.get('regla') else ''),
                vintage=str(vintage), variables='sha256 ' + a.get('sha256', '')[:12], llave='', sello='', fuente_fila=fuente + '; manifest.json assets')


def salidas_codigo(archivos_texto, repo, todos, slug):
    """save/file open/scalarjson/SankeySumSim/export/log using → filas de §6 con consumidores y check."""
    filas = []
    vistos = set()
    propios = {a for a, _ in archivos_texto}
    for archivo, texto in archivos_texto:
        for i, l in enumerate(texto.splitlines(), 1):
            if re.match(r'^\s*\*', l) or re.match(r'^\s*//', l):
                continue
            candidatos = []
            m = re.search(r'\b(?:save|saveold)\s+[`"\']+([^"\n]*(?:SIMROOT|users/|master/)[^"\n]*)"', l)
            if m:
                candidatos.append(m.group(1))
            m = re.search(r'file open\s+\S+\s+using\s+[`"\']+([^"\n]+)"', l)
            if m:
                candidatos.append(m.group(1))
            m = re.search(r'export (?:delimited|excel)\s+(?:using\s+)?[`"\']+([^"\n]+)"', l)
            if m:
                candidatos.append(m.group(1))
            m = re.search(r'\blog using\s+[`"\']+([^"\n]+)"', l)
            if m and 'tempfile' not in l:
                candidatos.append(m.group(1))
            m = re.search(r'SankeySum(?:Sim|Loop)\b.*?name\(([^)]+)\)', l)
            if m:
                mf = re.search(r'folder\((\w+)\)', l)
                candidatos.append('users/$id/%ssankey-%s.json' % ((mf.group(1) + '/') if mf else '', m.group(1)))
            m = re.search(r'\bscalarjson\b.*?(?:file|using)\(([^)]+)\)', l)
            if m:
                candidatos.append(m.group(1))
            for c in candidatos:
                c = re.sub(r'\$\{SIMROOT\}/|\$SIMROOT/', '', c).strip().rstrip("'")
                c = re.sub(r"^(\w+)'", r"`\1'", c)   # «`"`dir'/x"'»: la apertura `"` se comió el acento de la macro
                if not c or c in vistos or c.endswith('/'):
                    continue
                vistos.add(c)
                base = os.path.basename(c)
                patron = regex_nombre(base)
                consumidores = []
                if patron:
                    for s, tx in todos:
                        if s not in propios and s != 'SIM.do' and re.search(patron, tx):
                            consumidores.append(s)
                paginas = []
                for arch, pags in repo.manifiesto.items():
                    if patron and re.fullmatch(patron, os.path.basename(arch)):
                        paginas += pags
                checks = []
                if patron:
                    for s, tx in repo.scripts.items():
                        if os.path.basename(s) != 'metodo.py' and re.search(patron, tx):
                            checks.append(os.path.basename(s))
                filas.append(dict(archivo=c, contiene='', consume='; '.join(sorted(set(consumidores + paginas))),
                                  check='; '.join(sorted(set(checks))) if checks else GATE_HUMANO, fuente_fila='%s l. %d' % (archivo, i)))
    return filas


def regex_nombre(base):
    r"""Nombre de archivo con macros de Stata → regex: `x' y $x/${x} valen por \w+; exige la extensión."""
    if not base or '.' not in base:
        return None
    partes = re.split(r"(`[^']*'|\$\{?\w+\}?)", base)
    out = ''
    for p in partes:
        if not p:
            continue
        if p.startswith('`') or p.startswith('$'):
            out += r'[\w-]+'
        else:
            out += re.escape(p)
    if len(re.sub(r'\\.|\[\\w-\]\+', '', out)) < 4:
        return None
    return out


def identidades_fixtures(repo, slug):
    """GATE del fixture nta-identidad.txt (NTA) y líneas de gate-numeros.txt (output, SankeySF, NTA) con su commit."""
    filas = []
    fx = repo.p('05_scripts/fixtures/gate-numeros.txt')
    commit = ''
    if os.path.exists(fx):
        for l in leer(fx).splitlines():
            m = re.match(r'^commit:\s*(\S+)', l)
            if m:
                commit = m.group(1)
                continue
            m = re.match(r'^(OK|ROJO|AUSENTE|RESULTADO):?\s+(.*)$', l)
            if not m:
                continue
            txt = m.group(2)
            va = ('output.txt' in txt and slug == 'output') or ('SankeySF/' in txt and slug == 'SankeySF') or \
                 ('SankeyNTA/' in txt and slug == 'NTA') or (m.group(1) == 'RESULTADO' and slug in ('output', 'SankeySF', 'NTA'))
            if va:
                tol = 'byte a byte' if 'byte' in txt else ('1e-9 relativo' if '1e-9' in txt else '')
                filas.append(dict(nombre='gate-numeros.sh: ' + re.sub(r'\s*\(.*$', '', txt), tolerancia=tol, resultado=m.group(1) + (' — ' + txt if m.group(1) == 'RESULTADO' else ''), hash=commit, fuente='05_scripts/fixtures/gate-numeros.txt'))
    fi = repo.p('05_scripts/fixtures/nta-identidad.txt')
    if slug == 'NTA' and os.path.exists(fi):
        for i, l in enumerate(leer(fi).splitlines(), 1):
            m = re.match(r'^GATE\s+(\S+)\s+(.*?)\s{2,}(\S+)\s*$', l)
            if m:
                filas.append(dict(nombre=m.group(2).strip(), tolerancia=m.group(1), resultado=m.group(3), hash=commit, fuente='05_scripts/fixtures/nta-identidad.txt l. %d' % i))
            m = re.match(r'^RESULTADO de los gates\s+(\S+)\s*$', l)
            if m:
                filas.append(dict(nombre='nta-identidad.txt: resultado de los gates', tolerancia='', resultado=m.group(1), hash=commit, fuente='05_scripts/fixtures/nta-identidad.txt l. %d' % i))
    return filas


def scn_celdas(repo):
    """Tablas A–D de scn-celdas.md (las celdas que lee SCN.ado) como tablas de §5 del capítulo SCN."""
    texto = leer(repo.p('02_governance/scn-celdas.md'))
    lineas = texto.splitlines()
    out = []
    titulo = ''
    bloque = []
    ini = 0

    def cierra(fin):
        nonlocal bloque
        if bloque:
            t = md_tabla(bloque)
            if t:
                out.append(dict(titulo=titulo, columnas=t[0], filas=t[1], fuente='02_governance/scn-celdas.md l. %d–%d' % (ini, fin)))
        bloque = []
    for i, l in enumerate(lineas, 1):
        m = re.match(r'^## (.*)$', l)
        if m:
            cierra(i - 1)
            titulo = m.group(1)
            continue
        if l.strip().startswith('|') and titulo and not titulo.startswith('E.'):
            if not bloque:
                ini = i
            bloque.append(l)
        elif bloque:
            cierra(i - 1)
    cierra(len(lineas))
    return out


def ultima_fecha(texto):
    fechas = re.findall(r'\b(20\d{2}-\d{2}-\d{2})\b', texto)
    meses = dict(jan='01', feb='02', mar='03', apr='04', may='05', jun='06', jul='07', aug='08', sep='09', oct='10', nov='11', dec='12')
    for m in re.finditer(r'\b(\d{2})(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(20\d{2})\b', texto):
        fechas.append('%s-%s-%s' % (m.group(3), meses[m.group(2)], m.group(1)))
    return max(fechas) if fechas else ''


# ---------------------------------------------------------------------------------------------------------------------
# El capítulo
# ---------------------------------------------------------------------------------------------------------------------
def construir_capitulo(mod, repo, memos, todos, firmados):
    slug = mod['slug']
    archivos_texto = [(a, leer(repo.p(a))) for a in mod['archivos']]
    linea_sim, seccion_sim = repo.invocacion(mod['invoca'])
    cap = dict(modulo=slug, archivos=[dict(ruta=a, sha256=sha(repo.p(a)), lineas=len(t.splitlines())) for a, t in archivos_texto],
               orden_en_SIM=0, sim_linea=linea_sim, sim_seccion=seccion_sim, pagina=mod.get('pagina', ''),
               desde_version='', ultima_decision='', sello='', flags=[], secciones={}, procedencia=[])
    # versión y fecha del header (determinista: lo que dice el archivo, no git)
    for a, t in archivos_texto:
        m = re.search(r'^\*!\s*version\s+(\S+)', t, re.M)
        if m and not cap['desde_version']:
            cap['desde_version'] = m.group(1)
        n_head = header_lineas(t)
        f = ultima_fecha('\n'.join(t.splitlines()[:n_head]))
        if f > cap['ultima_decision']:
            cap['ultima_decision'] = f
    sec = {n: dict(texto=[], tablas=[], lista=[], vacia=True, flag='') for n in range(1, 11)}
    proc = []

    # 1) headers
    headers = []
    for a, t in archivos_texto:
        h, n_head = parse_header(a, t)
        headers.append((a, t, h, n_head))
        for n, s in h.items():
            sec[n]['texto'] += s['texto']
            sec[n]['tablas'] += s['tablas']
            proc.append(dict(seccion=n, archivo=a, lineas='l. %d–%d' % (s['ini'], s['fin']), nota='header' + ('; ' + '; '.join(s['procedencia']) if s['procedencia'] else '')))
            if n == 4:
                for d in decisiones_de_texto(s['crudo'], a, s['ini'], set(firmados)):
                    sec[4]['lista'].append(d)
                for f in flags_de_texto(s['crudo'], a, s['ini']):
                    sec[8]['lista'].append(f)
    # 2) SIM.do §0.8: parámetros firmados que este módulo lee
    for nombre, f in firmados.items():
        if re.search(r'\b' + re.escape(slug) + r'\b', f['lee']) or (slug == 'NTA' and 'Sankey' in f['lee'] and False):
            d = next((x for x in sec[4]['lista'] if x['parametro'] == nombre), None)
            if d is None:
                d = dict(parametro=nombre, default=f['firmado'], flag='', texto='', fuente='SIM.do l. %d' % f['linea'])
                sec[4]['lista'].append(d)
            d['firmado'] = f['firmado']
            d['documento'] = f['documento']
            d['lee'] = f['lee']
            d['sim_linea'] = f['linea']
    if any('firmado' in d for d in sec[4]['lista']):
        proc.append(dict(seccion=4, archivo='SIM.do', lineas='§0.8–§0.8c (l. %d–%d)' % (min(f['linea'] for f in firmados.values()), max(f['linea'] for f in firmados.values())), nota='parámetros firmados: valor, documento, quién lo lee'))
    # 3) memos
    for ruta, mods, reparto in memos:
        if slug not in mods:
            continue
        for n, s in memos_parsed[ruta].items():
            if n not in sec:
                continue
            for b in s['bloques']:
                destino = mods
                for clave, quien in reparto.items():
                    if (b.get('titulo') or '').startswith(clave):
                        destino = quien
                if slug not in destino:
                    continue
                etiqueta = os.path.basename(ruta).replace('.md', '') + (' · ' + b['titulo'] if b.get('titulo') else '')
                if b['tipo'] == 'tabla':
                    sec[n]['tablas'].append(dict(titulo=etiqueta, columnas=b['columnas'], filas=b['filas'], fuente=b['fuente']))
                else:
                    sec[n]['texto'].append('[%s] %s' % (etiqueta, b['texto']))
            proc.append(dict(seccion=n, archivo=ruta, lineas='l. %d–%d' % (s['ini'], s['fin']), nota=s['titulo']))
            # alternativas de los parámetros desde las tablas §4 del memo
            if n == 4:
                for b in s['bloques']:
                    if b['tipo'] != 'tabla' or not b['columnas']:
                        continue
                    cols = [c.lower() for c in b['columnas']]
                    i_alt = next((i for i, c in enumerate(cols) if 'alternativ' in c), None)
                    for fila in b['filas']:
                        m = re.match(r'^`(\w+)`', fila[0])
                        if not m:
                            continue
                        d = next((x for x in sec[4]['lista'] if x['parametro'] == m.group(1)), None)
                        if d is not None and i_alt is not None and not d.get('alternativas'):
                            d['alternativas'] = fila[i_alt]
                            d['memo'] = os.path.basename(ruta).replace('.md', '') + ' §4'
    # 4) derivaciones de código
    for a, t, h, n_head in headers:
        pasos = secciones_codigo(a, t, n_head)
        if pasos:
            sec[3]['lista'] += pasos
            proc.append(dict(seccion=3, archivo=a, lineas='secciones «** N.N … **» del cuerpo (l. %d–%d)' % (n_head + 1, len(t.splitlines())), nota='qué hace = título de la sección; líneas = su extensión'))
    ent = entradas_codigo(archivos_texto, repo, todos)
    if ent:
        sec[2]['tablas'].append(dict(titulo='Derivado del código: assets del manifest (ensure_asset) y productos de otros módulos (use master/)', columnas=['Base', 'Fuente / institución', 'Vintage usado', 'Variables clave', 'Llave única', 'Sello', 'Fuente de la fila'],
                                   filas=[[e['base'], e['fuente'], e['vintage'], e['variables'], e['llave'], e['sello'], e['fuente_fila']] for e in ent], fuente='05_scripts/manifest.json; ' + '; '.join(mod['archivos'])))
        proc.append(dict(seccion=2, archivo='05_scripts/manifest.json', lineas='assets, scn_vintage, enigh_vintage, data_updated', nota='derivado: ensure_asset y use master/ en ' + ', '.join(mod['archivos'])))
    if slug == 'SCN':
        for tb in scn_celdas(repo):
            sec[5]['tablas'].append(tb)
            proc.append(dict(seccion=5, archivo='02_governance/scn-celdas.md', lineas=tb['fuente'].split(' l. ')[-1], nota=tb['titulo']))
        proc.append(dict(seccion=5, archivo='05_scripts/scn-cuentas.csv', lineas='catálogo completo', nota='nombres INEGI y SNA 2008 de las cuentas que anclan al motor'))
    if slug == 'Households':
        # ITAN: fuente externa de la calibración de altimir_elasticidad (CUAD-3)
        g = repo.itan.get('generado', {})
        sec[2]['tablas'].append(dict(titulo='itan-catalogo.json (ITAN, SHCP): registros fiscales por rango', columnas=['Fuente', 'Archivos congelados', 'Primero', 'Último', 'Rangos', 'Unidades'],
                                   filas=[[repo.itan.get('fuente', ''), str(g.get('archivos', '')), g.get('primero', ''), g.get('ultimo', ''), '; '.join(repo.itan.get('rangos', [])), repo.itan.get('unidades', '')]], fuente='05_scripts/itan-catalogo.json'))
        proc.append(dict(seccion=2, archivo='05_scripts/itan-catalogo.json', lineas='fuente, rangos, generado', nota='ITAN 4T: calibración de altimir_elasticidad (CUAD-3 §4.3)'))
    sal = salidas_codigo(archivos_texto, repo, todos, slug)
    if sal:
        sec[6]['tablas'].append(dict(titulo='Derivado del código: lo que el módulo escribe, quién lo lee (módulos y páginas) y qué script lo protege', columnas=['Archivo / JSON / figura', 'Qué contiene', 'Quién lo consume', 'Check de CI que lo protege', 'Fuente de la fila'],
                                   filas=[[s['archivo'], s['contiene'], s['consume'], s['check'], s['fuente_fila']] for s in sal], fuente='; '.join(mod['archivos']) + '; 05_scripts/manifiesto-default.py --tsv; grep en 05_scripts/'))
        proc.append(dict(seccion=6, archivo='05_scripts/manifiesto-default.py', lineas='--tsv', nota='qué página pide cada salida; checks = scripts de 05_scripts/ y el workflow que nombran el archivo'))
    if mod.get('pagina'):
        sec[6]['lista'].append(dict(archivo=mod['pagina'], contiene='página del sitio que publica las salidas de este capítulo', consume='sitio', check=''))
    idf = identidades_fixtures(repo, slug)
    if idf:
        sec[7]['tablas'].append(dict(titulo='Última corrida completa (fixtures del repo)', columnas=['Identidad', 'Tolerancia', 'Resultado', 'Hash'], filas=[[i['nombre'], i['tolerancia'], i['resultado'], i['hash']] for i in idf], fuente='; '.join(sorted(set(i['fuente'].split(' l. ')[0] for i in idf)))))
        proc.append(dict(seccion=7, archivo='05_scripts/fixtures/gate-numeros.txt; 05_scripts/fixtures/nta-identidad.txt', lineas='GATE / OK / RESULTADO', nota='resultado de la última corrida completa, con su commit'))

    sec[4]['texto'] = texto_sin_entradas(sec[4]['texto'])
    sec[8]['texto'] = texto_sin_entradas(sec[8]['texto'])
    # vacías y FLAGs
    for n in range(1, 10):
        s = sec[n]
        s['vacia'] = not (s['texto'] or s['tablas'] or s['lista'])
        if s['vacia'] and n in OBLIGATORIAS:
            s['flag'] = 'header incompleto: §%d %s' % (n, repo.secciones_plantilla.get(n, ''))
            cap['flags'].append(s['flag'])
    # sello
    peor = 0
    for n in (2, 5):
        for tb in sec[n]['tablas']:
            cols = [c.lower() for c in tb['columnas']]
            i_s = next((i for i, c in enumerate(cols) if c.startswith('sello')), None)
            if i_s is None:
                continue
            for fila in tb['filas']:
                peor = max(peor, SELLOS.get(sello_de(fila[i_s] if i_s < len(fila) else ''), 0))
    if cap['flags']:
        cap['sello'] = 'rojo'
    else:
        cap['sello'] = {3: 'rojo', 2: 'amarillo', 1: 'verde'}.get(peor, 'sin sello')
    # esquema de la plantilla (campos tipados) + secciones para la página
    cap['proposito'] = ' '.join(sec[1]['texto'])
    cap['entradas'] = filas_tipadas(sec[2]['tablas'], ['base', 'fuente', 'vintage', 'variables', 'llave', 'sello'])
    cap['pasos'] = [dict(n=p['n'], hace=p['hace'], conserva='', lineas=p['lineas'], programa=p['programa'], archivo=p['archivo']) for p in sec[3]['lista']]
    cap['decisiones'] = sec[4]['lista']
    cap['anclas'] = filas_tipadas(sec[5]['tablas'], ['variable', 'celda_scn', 'valor_scn', 'suma_motor', 'factor', 'regla', 'sello'])
    cap['salidas'] = filas_tipadas([tb for tb in sec[6]['tablas'] if not tb['titulo'].startswith('Derivado del código')], ['archivo', 'contiene', 'consume', 'check']) + [dict(archivo=s['archivo'], consume=s['consume'], check=s['check']) for s in sal] + sec[6]['lista']
    cap['identidades'] = filas_tipadas([tb for tb in sec[7]['tablas'] if not tb['titulo'].startswith('Última corrida')], ['nombre', 'tolerancia', 'resultado', 'hash']) + idf
    cap['limites'] = sec[8]['lista']
    cap['especifico_mx'] = filas_tipadas(sec[9]['tablas'], ['elemento', 'requerimiento', 'por_que_mx'])
    sec[10]['lista'] = proc
    sec[10]['vacia'] = not proc
    cap['procedencia'] = proc
    # las listas tipadas de §3, §4, §8 y §10 viajan una sola vez (en pasos/decisiones/limites/procedencia); la página las lee de ahí
    for n in (3, 4, 8, 10):
        sec[n]['lista'] = []
    cap['secciones'] = {str(n): sec[n] for n in range(1, 11)}
    cap['conteos'] = dict(entradas=len(cap['entradas']), anclas=len(cap['anclas']), decisiones=len(cap['decisiones']),
                          salidas=len(cap['salidas']), identidades=len(cap['identidades']), pasos=len(cap['pasos']))
    return cap


def filas_tipadas(tablas, campos):
    out = []
    for tb in tablas:
        for fila in tb['filas']:
            d = dict(zip(campos, (fila + [''] * len(campos))[:len(campos)]))
            d['tabla'] = tb.get('titulo', '')
            out.append(d)
    return out


# ---------------------------------------------------------------------------------------------------------------------
# Capítulo 0 y bibliografía
# ---------------------------------------------------------------------------------------------------------------------
def construir_cap0(repo):
    texto = leer(repo.p(CAP0_MD))
    lineas = texto.splitlines()
    titulo = next((l[2:] for l in lineas if l.startswith('# ')), 'Capítulo 0')
    cap = dict(titulo=titulo, intro='', secciones=[], archivo=CAP0_MD, sha256=sha(repo.p(CAP0_MD)))
    actual = None
    bloque = []
    sub = ''

    def cierra(fin):
        nonlocal bloque
        if not bloque:
            return
        destino = actual if actual is not None else None
        t = md_tabla([b[1] for b in bloque])
        ini = bloque[0][0]
        if t:
            columnas, filas = t
            item = dict(tipo='tabla', columnas=columnas, filas=filas, fuente='%s l. %d–%d' % (CAP0_MD, ini, fin))
            # tabla de requerimientos: la columna del otro país se publica VACÍA (la candidata del documento se queda en el .md)
            if any(c.lower().startswith('colombia') for c in columnas):
                i_c = next(i for i, c in enumerate(columnas) if c.lower().startswith('colombia'))
                item['columnas'] = columnas[:i_c] + ['Otro país'] + columnas[i_c + 1:]
                item['filas'] = [f[:i_c] + [''] + f[i_c + 1:] for f in filas]
                item['nota'] = 'La columna «Otro país» se publica vacía para que la llene quien replica; la candidata del documento fuente (%s) no se publica.' % CAP0_MD
        else:
            item = dict(tipo='texto', texto=' '.join(b[1].strip() for b in bloque), fuente='%s l. %d–%d' % (CAP0_MD, ini, fin))
        if destino is None:
            cap['intro'] = (cap['intro'] + ' ' + item.get('texto', '')).strip() if item['tipo'] == 'texto' else cap['intro']
        else:
            destino['bloques'].append(item)
        bloque = []

    for i, l in enumerate(lineas, 1):
        if l.startswith('# '):
            continue
        m = re.match(r'^## (.*)$', l)
        if m:
            cierra(i - 1)
            actual = dict(titulo=m.group(1), bloques=[])
            cap['secciones'].append(actual)
            continue
        if l.strip() == '':
            cierra(i - 1)
            continue
        if bloque and (l.strip().startswith('|') != bloque[-1][1].strip().startswith('|')):
            cierra(i - 1)
        bloque.append((i, l))
    cierra(len(lineas))
    return cap


def construir_bibliografia(repo):
    t = md_tabla(leer(repo.p(FUENTES_MD)).splitlines())
    out = []
    if t:
        for fila in t[1]:
            out.append(dict(zip([c.lower() for c in t[0]], fila)))
    return dict(fuente=FUENTES_MD, columnas=(t[0] if t else []), filas=(t[1] if t else []))


# ---------------------------------------------------------------------------------------------------------------------
# Páginas
# ---------------------------------------------------------------------------------------------------------------------
PHP_INDICE = """<?php
// /metodo — índice del método del Simulador Fiscal CIEP: un capítulo por módulo, en el orden de SIM.do, generado del repo.
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => array('es' => 'Método', 'en' => 'Method'), 'lang' => 'es',
\t'descripcion' => array('es' => 'Cómo calcula el Simulador Fiscal CIEP: un capítulo por módulo, generado del repositorio.',
\t\t'en' => 'How the Simulador Fiscal CIEP computes: one chapter per module, generated from the repository.')));
?>
\t\t<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="indice" data-metodo-estado="cargando">
\t\t\t<p class="metodo-cargando"><?= metodo_lang() === 'es' ? 'Cargando el método…' : 'Loading the method…' ?></p>
\t\t</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "indice"});'));
"""

PHP_CAPITULO = """<?php
// /metodo/%(slug)s — capítulo «%(slug)s» del método (%(archivos)s).
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__, 2) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => '%(slug)s', 'lang' => 'es',
\t'descripcion' => array('es' => 'Capítulo %(slug)s del método del Simulador Fiscal CIEP, generado del repositorio.',
\t\t'en' => 'Chapter %(slug)s of the method of the Simulador Fiscal CIEP, generated from the repository.'),
\t'migas' => array(array('href' => '/metodo/%(slug)s/', 'texto' => '%(slug)s'))));
?>
\t\t<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="capitulo" data-metodo-capitulo="%(slug)s" data-metodo-estado="cargando">
\t\t\t<p class="metodo-cargando"><?= metodo_lang() === 'es' ? 'Cargando el capítulo…' : 'Loading the chapter…' ?></p>
\t\t</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "capitulo", "capitulo": "%(slug)s"});'));
"""

PHP_CAP0 = """<?php
// /metodo/cap0 — capítulo 0 del método: requerimientos para replicar el simulador (02_governance/metodo/cap0-requerimientos.md).
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__, 2) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => array('es' => 'Capítulo 0', 'en' => 'Chapter 0'), 'lang' => 'es',
\t'descripcion' => array('es' => 'Capítulo 0 del método del Simulador Fiscal CIEP: requerimientos para replicarlo en otro país.',
\t\t'en' => 'Chapter 0 of the method of the Simulador Fiscal CIEP: requirements to replicate it in another country.'),
\t'migas' => array(array('href' => '/metodo/cap0/', 'texto' => array('es' => 'Capítulo 0', 'en' => 'Chapter 0')))));
?>
\t\t<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="cap0" data-metodo-estado="cargando">
\t\t\t<p class="metodo-cargando"><?= metodo_lang() === 'es' ? 'Cargando el capítulo…' : 'Loading the chapter…' ?></p>
\t\t</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "cap0"});'));
"""


# ---------------------------------------------------------------------------------------------------------------------
# Traducción al inglés (8.19): metodo-en.json = metodo.json con cada cadena de texto pasada por la memoria de traducción
# 02_governance/metodo/traduccion-en.json ({"cadena en español": "cadena en inglés"}). El generador sigue sin redactar:
# la memoria es un archivo del repo, revisable en PR, y una cadena sin traducción se queda en español y se cuenta
# (--check falla; --pendientes-en <ruta> la vuelca para traducirla). Los números de una cadena pueden cambiar entre
# corridas (fixtures): si la cadena exacta no está, se busca la misma con otros números y se sustituyen en orden.
# ---------------------------------------------------------------------------------------------------------------------
TRADUCCION_EN = '02_governance/metodo/traduccion-en.json'
NO_TRADUCIR = {'sha256', 'sello', 'modulo', 'clave', 'tipo', 'parametro', 'programa', 'n', 'lineas', 'generador',
               'plantilla', 'version', 'baseline', 'data_updated', 'enigh_vintage', 'desde_version', 'ultima_decision',
               'ruta', 'pagina', 'hash', 'celda_scn', 'variable', 'llave'}
_RE_LETRAS = re.compile(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{2,}')
_RE_IDENT = re.compile(r'^[\w./$<>{}()\[\]\-*:#@=+,|~%^&!?\'"]+$')


def traducible(t):
    """¿Lleva prosa? No: vacía, solo código entre comillas invertidas, números, rutas o identificadores sin espacios."""
    resto = re.sub(r'`[^`]*`', '', t)
    resto = re.sub(r'\bl\.\s*\d+(?:\s*[–-]\s*\d+)?', '', resto)               # «l. 30–35»
    resto = re.sub(r'\S*(?:/|\.(?:ado|do|dta|json|csv|md|py|sh|js|php|txt|zip|xlsx?|pdf|sthlp)\b)\S*', '', resto)   # rutas y archivos
    resto = re.sub(r'§\s*[\d.]+[a-z]?', '', resto).strip()
    if not _RE_LETRAS.search(resto) or not re.search(r'[a-záéíóúñ]{2,}', resto):
        return False
    if ' ' not in resto and _RE_IDENT.match(resto) and (re.search(r'[/_.$\d]', resto) or resto.isupper()):
        return False
    return True


class Traductor:
    def __init__(self, memoria):
        self.m = memoria
        self.faltan = []
        self._vistas = set()
        self.plantillas = {}
        for es, en in memoria.items():
            self.plantillas.setdefault(re.sub(r'\d+', '\x00', es), (es, en))

    def cadena(self, t, forzar=False):
        # forzar: rótulos en mayúsculas (las secciones de SIM.do, «2. ECONOMÍA») que el filtro de prosa no reconoce
        if not isinstance(t, str) or not (traducible(t) or (forzar and _RE_LETRAS.search(t))):
            return t
        if t in self.m:
            return self.m[t]
        par = self.plantillas.get(re.sub(r'\d+', '\x00', t))
        if par:
            es, en = par
            viejos, nuevos = re.findall(r'\d+', es), re.findall(r'\d+', t)
            if re.findall(r'\d+', en) == viejos:
                it = iter(nuevos)
                return re.sub(r'\d+', lambda _: next(it), en)
        if t not in self._vistas:
            self._vistas.add(t)
            self.faltan.append(t)
        return t

    def valor(self, x, clave=None):
        if isinstance(x, str):
            return x if clave in NO_TRADUCIR else self.cadena(x)
        if isinstance(x, list):
            return [self.valor(v, clave) for v in x]
        if isinstance(x, dict):
            if isinstance(x.get('columnas'), list) and isinstance(x.get('filas'), list):
                # tabla: la columna «Sello» lleva el valor del sello (verde/amarillo/rojo), que la página traduce al pintarlo
                sello_cols = {i for i, c in enumerate(x['columnas']) if isinstance(c, str) and c.lower().startswith('sello')}
                out = {k: self.valor(v, k) for k, v in x.items() if k != 'filas'}
                out['filas'] = [[(v if i in sello_cols and self._sello_puro(v) else self.valor(v)) for i, v in enumerate(f)] if isinstance(f, list) else self.valor(f)
                                for f in x['filas']]
                return out
            return {k: (self.cadena(v, forzar=True) if k == 'sim_seccion' else self.valor(v, k)) for k, v in x.items()}
        return x

    @staticmethod
    def _sello_puro(v):
        # el valor del sello solo (verde/amarillo/rojo, con o sin asteriscos): lo traduce la página; con texto extra, se traduce aquí
        return not isinstance(v, str) or re.sub(r'[*\s]', '', v).lower() in ('', 'verde', 'amarillo', 'rojo', 'sinsello')


def traducir_salida(repo, salida):
    ruta = repo.p(TRADUCCION_EN)
    memoria = json.loads(leer(ruta)) if os.path.exists(ruta) else {}
    tr = Traductor(memoria)
    en = tr.valor(salida)
    en['idioma'] = 'en'
    return en, tr.faltan


def generar(repo):
    global memos_parsed
    memos_parsed = {ruta: parse_memo(ruta, leer(repo.p(ruta))) for ruta, _, _ in MEMOS}
    firmados = repo.parametros_firmados()
    todos = [(a, leer(repo.p(a))) for m in MODULOS for a in m['archivos']] + [('SIM.do', '\n'.join(repo.sim))]
    capitulos = [construir_capitulo(m, repo, MEMOS, todos, firmados) for m in MODULOS]
    capitulos.sort(key=lambda c: (c['sim_linea'] is None, c['sim_linea'] or 0))
    for i, c in enumerate(capitulos, 1):
        c['orden_en_SIM'] = i
    m = repo.manifest
    anios = {}
    for l in repo.sim:
        mm = re.match(r'^scalar (aniovp|anioPE|anioenigh) = (\d+)', l)
        if mm:
            anios[mm.group(1)] = int(mm.group(2))
    salida = dict(
        generador=VERSION_SCRIPT,
        plantilla=PLANTILLA_MD,
        version=m.get('version', ''), baseline=m.get('baseline', ''), data_updated=m.get('data_updated', ''),
        enigh_vintage=m.get('enigh_vintage', ''), anios=anios,
        secciones=[dict(n=n, titulo=repo.secciones_plantilla.get(n, ''), clave=CLAVES[n]) for n in range(1, 11)],
        obligatorias=list(OBLIGATORIAS),
        gate_humano=GATE_HUMANO,
        capitulos=capitulos,
        cap0=construir_cap0(repo),
        bibliografia=construir_bibliografia(repo),
        resumen=dict(capitulos=len(capitulos),
                     sellos={s: sum(1 for c in capitulos if c['sello'] == s) for s in ('verde', 'amarillo', 'rojo', 'sin sello')},
                     flags=sum(len(c['flags']) for c in capitulos)),
    )
    paginas = {'index.php': PHP_INDICE, 'cap0/index.php': PHP_CAP0}
    for c in capitulos:
        paginas['%s/index.php' % c['modulo']] = PHP_CAPITULO % dict(slug=c['modulo'], archivos=', '.join(a['ruta'] for a in c['archivos']))
    return salida, paginas


def escribir(destino, salida, paginas, salida_en):
    os.makedirs(destino, exist_ok=True)
    for nombre, obj in (('metodo.json', salida), ('metodo-en.json', salida_en)):
        with open(os.path.join(destino, nombre), 'w', encoding='utf-8') as f:
            json.dump(obj, f, ensure_ascii=False, indent=1)
            f.write('\n')
    for rel, contenido in paginas.items():
        ruta = os.path.join(destino, rel)
        os.makedirs(os.path.dirname(ruta), exist_ok=True)
        with open(ruta, 'w', encoding='utf-8') as f:
            f.write(contenido)


def archivos_generados(paginas):
    return ['metodo.json', 'metodo-en.json'] + sorted(paginas)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--root', default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--reporte', action='store_true')
    ap.add_argument('--json-a', default=None)
    ap.add_argument('--pendientes-en', default=None, help='vuelca a esta ruta (JSON) las cadenas sin traducción al inglés')
    a = ap.parse_args()
    repo = Repo(os.path.abspath(a.root))
    salida, paginas = generar(repo)
    salida_en, faltan = traducir_salida(repo, salida)
    if a.pendientes_en:
        with open(a.pendientes_en, 'w', encoding='utf-8') as f:
            json.dump(faltan, f, ensure_ascii=False, indent=1)
            f.write('\n')
        print('metodo.py: %d cadenas sin traducción al inglés → %s' % (len(faltan), a.pendientes_en))
        return 0
    if a.reporte:
        print('%s · %d capítulos · sellos %s · FLAGs %d' % (VERSION_SCRIPT, salida['resumen']['capitulos'], salida['resumen']['sellos'], salida['resumen']['flags']))
        for c in salida['capitulos']:
            vacias = [n for n in range(1, 10) if c['secciones'][str(n)]['vacia']]
            print('%2d %-15s sello %-9s SIM.do l.%-4s  vacías: %-22s flags: %s  (%s)' % (
                c['orden_en_SIM'], c['modulo'], c['sello'], c['sim_linea'], ','.join('§%d' % n for n in vacias) or '—',
                '; '.join(c['flags']) or '—', ' '.join('%s=%d' % kv for kv in c['conteos'].items())))
        return 0
    if a.json_a:
        with open(a.json_a, 'w', encoding='utf-8') as f:
            json.dump(salida, f, ensure_ascii=False, indent=1)
            f.write('\n')
        return 0
    destino = repo.p(SALIDA)
    if a.check:
        tmp = tempfile.mkdtemp(prefix='metodo-check-')
        try:
            escribir(tmp, salida, paginas, salida_en)
            dif = []
            for rel in archivos_generados(paginas):
                g = os.path.join(tmp, rel)
                r = os.path.join(destino, rel)
                if not os.path.exists(r):
                    dif.append('falta en el repo: %s/%s' % (SALIDA, rel))
                elif open(g, 'rb').read() != open(r, 'rb').read():
                    dif.append('difiere: %s/%s' % (SALIDA, rel))
            esperados = set(archivos_generados(paginas))
            for raiz, dirs, files in os.walk(destino):
                for f in files:
                    rel = os.path.relpath(os.path.join(raiz, f), destino)
                    if rel not in esperados and not f.startswith('.'):
                        dif.append('sobra en el repo: %s/%s' % (SALIDA, rel))
            if faltan:
                dif.append('%d cadena(s) sin traducción al inglés en %s (vuélcalas con --pendientes-en <ruta>); la primera: %s' % (
                    len(faltan), TRADUCCION_EN, faltan[0][:100]))
            if dif:
                print('metodo.py --check: %d diferencia(s); regenera con `python3 -I 05_scripts/metodo.py` y commitea:' % len(dif))
                for d in dif:
                    print('  ' + d)
                return 1
            print('metodo.py --check: %d archivos generados = commiteados (metodo.json, metodo-en.json + %d páginas); traducción al inglés completa' % (len(esperados), len(paginas)))
            return 0
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    # limpiar páginas de capítulos que ya no existen y escribir
    if os.path.isdir(destino):
        esperados = set(archivos_generados(paginas))
        for raiz, dirs, files in os.walk(destino, topdown=False):
            for f in files:
                rel = os.path.relpath(os.path.join(raiz, f), destino)
                if rel not in esperados and not f.startswith('.'):
                    os.remove(os.path.join(raiz, f))
            if raiz != destino and not os.listdir(raiz):
                os.rmdir(raiz)
    escribir(destino, salida, paginas, salida_en)
    if faltan:
        print('metodo.py: AVISO %d cadena(s) sin traducción al inglés (--pendientes-en <ruta> las vuelca)' % len(faltan))
    print('metodo.py: %s/metodo.json + metodo-en.json + %d páginas (%d capítulos; sellos %s; FLAGs %d)' % (
        SALIDA, len(paginas), salida['resumen']['capitulos'], salida['resumen']['sellos'], salida['resumen']['flags']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
