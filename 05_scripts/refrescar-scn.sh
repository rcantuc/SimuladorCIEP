#!/usr/bin/env bash
# refrescar-scn.sh — compara las celdas del SCN que lee el motor contra el BIE/INEGI SIN tocar raw/ ni el manifest.
#
# Política de fuente SCN (CUAD-0 §4 bis, firmada 2026-10-30): canal BIE por API; cada descarga queda congelada en raw/;
# nunca hay lectura en caliente; un cambio de INEGI entra solo por PR de datos. Este script es el paso 1-5 de esa spec
# (v8.15b-pre, 2026-10-31): el inventario de celdas vive en 02_governance/scn-celdas.md y en SCN.ado (UpdateSCN), lo
# congelado hoy es lo que el motor leyó la última vez (raw/temp/AccesoBIE/<serie>.csv, la copia exacta de la descarga, y
# master/SCN.dta como respaldo), y el reporte dice celda, valor congelado, valor BIE, Δ, Δ % PIB, etiqueta INEGI y fecha.
#
# Uso:
#   bash 05_scripts/refrescar-scn.sh --comparar [--series "724014 724025 …"] [--todas] [--csi] [--salida <dir>] [--repo <root>] [--anio AAAA]
#   bash 05_scripts/refrescar-scn.sh --congelar [--todas] [--salida <dir>] [--repo <root>] [--anio AAAA]   # v8.15b (E4): escribe los assets
#
#   --comparar   Descarga por API las series del inventario (las que llegan a un escalar que algún módulo lee: ~90) a un
#                directorio temporal, calcula sha256 de la serie congelada y de la descargada y compara valor a valor con
#                tolerancia CERO sobre el valor publicado. Solo lee raw/ y master/; escribe únicamente en --salida (default:
#                un directorio temporal) y en stdout.
#   --todas      Las 525 series que UpdateSCN descarga (SCN.ado), no solo las del inventario.
#   --series     Lista explícita de claves BIE (sustituye al inventario).
#   --csi        Además baja tabulados_CSI.zip (cuentas por sector institucional) a un temporal y compara el sha256 de los
#                cuadros que lee el motor (CSI_103/106/109/112/115/118) y, celda a celda, las filas del inventario.
#   --salida     Carpeta para refrescar-scn-<fecha>.md y .json (nunca raw/).
#   --anio       Año de referencia. Default: `scalar anioenigh` de SIM.do (el año ENIGH con el que corrió el motor), sin escalar
#                nuevo. Se comparan los años ≤ referencia; los posteriores (p. ej. «2025 p1») se listan como «fuera del año de
#                referencia»: no son revisión ni cuentan como celdas distintas.
#
# Token: global BIE_API_TOKEN de set_token.do (raíz del repo) o variable de entorno BIE_API_TOKEN. Sin token NO se compara:
# «no comparado» nunca equivale a «sin revisión» (spec, paso 9).
#
# Exit: 0 = sin revisión INEGI (todas las celdas iguales); 1 = hay diferencias (tabla impresa); 3 = no comparado (sin token,
# sin red, el BIE no respondió alguna serie, o falta lo congelado); 2 = uso / modo deshabilitado.
#
# Modo --congelar (v8.15b, sesion 2026-10-31; spec pasos 6-7, CUAD-0 §4 bis): hace lo mismo que --comparar (con --csi forzado) y ADEMAS
# escribe los assets congelados en raw/SCN/: bie/<serie>.csv (periodo,valor; solo los años ≤ año de referencia: los posteriores se listan
# «fuera del año de referencia» y NO se incorporan) para las series del inventario (--todas: las 525 de UpdateSCN) y los siete cuadros
# CSI_1xx.xlsx que lee SCN.ado, y los registra en 05_scripts/manifest.json bajo `scn_vintage`: fecha de consulta, año de referencia,
# canal (API | exportación pública), y por serie variable, uso, sha256, n, etiqueta INEGI del último dato y vía; por cuadro CSI sha256 y
# las celdas del inventario (cuadro, fila, columna, código, variable, valor del año de referencia). SCN.ado (UpdateSCN, SCNHogaresS14) y
# AccesoBIE.ado leen esos assets cuando existen y los verifican contra el sha256 del manifest (sello verde); sin asset, descargan y lo
# declaran (sello amarillo). data_updated y el CHANGELOG los mueve el PR de datos (runbook-actualizar-assets.md), no este script.
# raw/SCN/ no se versiona (como el resto de raw/): el asset viaja con la Release; `assets` del manifest lo gana con el bump de version.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODO=""; SERIES=""; TODAS=0; CSI=0; SALIDA=""; ANIO=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --comparar) MODO="comparar"; shift ;;
        --congelar) MODO="congelar"; shift ;;
        --series)   SERIES="$2"; shift 2 ;;
        --todas)    TODAS=1; shift ;;
        --csi)      CSI=1; shift ;;
        --salida)   SALIDA="$2"; shift 2 ;;
        --repo)     REPO_ROOT="$2"; shift 2 ;;
        --anio)     ANIO="$2"; shift 2 ;;
        -h|--help)  sed -n '2,40p' "$0"; exit 0 ;;
        *) echo "refrescar-scn: argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
CONGELAR=0
if [[ "$MODO" == "congelar" ]]; then
    CONGELAR=1
    CSI=1
    [[ -n "$SALIDA" ]] || SALIDA="$REPO_ROOT/raw/SCN"
fi
if [[ "$MODO" != "comparar" && "$MODO" != "congelar" ]]; then
    echo "refrescar-scn: indica --comparar o --congelar. Ver --help." >&2
    exit 2
fi
# token: set_token.do o entorno; nunca se imprime
TOKEN="${BIE_API_TOKEN:-}"
if [[ -z "$TOKEN" && -f "$REPO_ROOT/set_token.do" ]]; then
    TOKEN="$(sed -nE 's/^[[:space:]]*global[[:space:]]+BIE_API_TOKEN[[:space:]]+"([^"]*)".*/\1/p' "$REPO_ROOT/set_token.do" | head -n 1)"
fi
if [[ -z "$TOKEN" || "$TOKEN" == "tu-token-aqui" ]]; then
    echo "refrescar-scn: sin token del BIE (set_token.do o BIE_API_TOKEN): NO COMPARADO (exit 3). Sin token no se sustituye por la consulta pública: la comparación es contra la API." >&2
    exit 3
fi
[[ -n "$SALIDA" ]] || SALIDA="$(mktemp -d -t refrescar-scn-XXXXXX)"
mkdir -p "$SALIDA"
BIE_API_TOKEN="$TOKEN" python3 -I - "$REPO_ROOT" "$SALIDA" "$TODAS" "$CSI" "$SERIES" "$ANIO" "$CONGELAR" <<'PYEOF'
import datetime, hashlib, io, json, os, re, ssl, sys, tempfile, time, urllib.request, urllib.error, zipfile
root, salida, todas, csi, series_arg, anio_arg = sys.argv[1], sys.argv[2], sys.argv[3] == '1', sys.argv[4] == '1', sys.argv[5], sys.argv[6]
congelar = sys.argv[7] == '1'
# Año de referencia: anioenigh del motor (SIM.do), sin escalar nuevo; --anio lo sobreescribe
if anio_arg.strip():
    ANIO_REF, anio_fuente = int(anio_arg), '--anio'
else:
    m_anio = re.search(r'^\s*scalar\s+anioenigh\s*=\s*(\d{4})', open(os.path.join(root, 'SIM.do'), encoding='utf-8').read(), flags=re.M)
    if not m_anio:
        print('refrescar-scn: no encuentro `scalar anioenigh = AAAA` en SIM.do; indica --anio (NO COMPARADO, exit 3)'); sys.exit(3)
    ANIO_REF, anio_fuente = int(m_anio.group(1)), 'scalar anioenigh de SIM.do'
def anio_de(p):
    m = re.match(r'\d{4}', p); return int(m.group(0)) if m else None
# TLS: el python.org de macOS no trae las CA del sistema; se usa el bundle de certifi (el mismo que requests en AccesoBIE.ado)
try:
    import certifi
    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:
    SSL_CTX = ssl.create_default_context()
def abrir(url, timeout):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'SimuladorCIEP refrescar-scn'}), timeout=timeout, context=SSL_CTX)
token = os.environ['BIE_API_TOKEN']
hoy = datetime.datetime.now(datetime.timezone.utc)
fecha = hoy.strftime('%Y-%m-%dT%H:%M:%SZ')

# ── 1. Inventario: las series que UpdateSCN descarga (SCN.ado) y las que llegan a un escalar que algún módulo lee ──
ado = open(os.path.join(root, 'SCN.ado'), encoding='utf-8').read()
calls = re.findall(r'AccesoBIE\s+((?:\d+\s*(?:///\s*)?)+),\s*(?:///\s*)?nombres\(([^)]*)\)', ado, flags=re.S)
nombre = {}
for s, n in calls:
    ss, nn = re.findall(r'\d+', s), re.sub(r'///', ' ', n).split()
    assert len(ss) == len(nn), 'SCN.ado: AccesoBIE con series y nombres desparejos'
    nombre.update(dict(zip(ss, nn)))
etiqueta = dict(re.findall(r'label var (\S+)\s+"([^"]*)"', ado))
# Escalares que consumen los módulos (grep scalar(...) en 01_modulos y .ado; 02_governance/scn-celdas.md) y la serie BIE
# de la que nacen. Los derivados (MixL, ExNOpSoc, ImpNetProduccionL/K, Yl, CapIncImp, AhorroN, PIN calculado) dependen de
# estas mismas series más las celdas CSI (IngMixto, DepMix, SSImputada, Sub*, ExBOp*/ExNOp* por sector).
INVENTARIO = {
    # Cuenta de generación del ingreso (§1.1)
    '724014': 'RemSalSS: Households (via RemSal), TasasEfectivas, SCN B.1', '724015': 'RemSal: Households §1.1/§9, PerfilesSim, TasasEfectivas',
    '724016': 'SSEmpleadores: Households §1.1/§9, TasasEfectivas', '724017': 'Imp: ImpuestosNetos', '724018': 'ImpProductos: ImpNetProductos (Households §9 Altimir)',
    '724022': 'ImpProduccion: ImpNetProduccion → ImpNetProduccionL/K (Households)', '724023': 'Sub: ImpuestosNetos',
    '724024': 'ExBOp: ExNOpSoc residuo (Households §9 TaltimirCap)', '724025': 'PIB: todos los módulos (escalar PIB / pibY)',
    # Producción bruta (§2.1): impuestos netos a los productos y agregados
    '723656': 'ImpNet: Households §9 Altimir, NTA, PerfilesSim', '723657': 'ImpProd (cuadre)', '723658': 'SubProd: ImpNetProductos',
    '723663': 'ConsInt (cuenta A)', '723652': 'ProdT (cuenta A)',
    # Ingreso nacional disponible (§3.1)
    '724028': 'CapFij: Households §11.3 (depreciación ∝ ing_capital), NTA', '724029': 'PIN: PerfilesSim, SCN C',
    '724030': 'ROWRemR → ROWRem: Households §12 ing_suborROW, Sankey', '724031': 'ROWRemP → ROWRem',
    '724032': 'ROWPropR → ROWProp: Households ing_capitalROW, Sankey', '724033': 'ROWPropP → ROWProp',
    '724034': 'ROWTransR → ROWTrans: Households §9 TaltimirROWTrans (remesas), Sankey', '724035': 'ROWTransP → ROWTrans',
    # Consumo de hogares (§4.1): ConHog y las categorías que Expenditure.do ancla (TT*) y TasasEfectivas lee
    '724771': 'GastPrivT (SCN D)', '724777': 'ComprasN: Households, NTA (gasto_anualComprasN), Sankey',
    '724959': 'ConGob: Households gasto_anualGobierno, NTA (colectivo), Sankey',
    # Consumo privado por actividad (§8.1)
    '725116': 'ConsPriv_21 → ConsPriv21PIB: TasasEfectivas (IEPS petrolero)', '725126': 'ConsPriv_54 → ConsPriv54: Households §1.2 (honorarios pf/PM)',
    '725130': 'ConsPriv_62 → ConsPriv62: Households §1.2 (salud pf/PM)',
}
for s, n in nombre.items():
    if 724600 <= int(s) <= 724656: INVENTARIO.setdefault(s, f'{n}: Expenditure.do (anclas TT* de consumo) / TasasEfectivas')
    if n in ('Prof541_T', 'Salud6211', 'Salud6212', 'Salud6213', 'Salud6216', 'Inmob5311', 'Inmob5312'): INVENTARIO.setdefault(s, f'{n}: Households §1.2 (shares pf/PM de honorarios y rentas)')
    if n == 'Recre7132': INVENTARIO.setdefault(s, f'{n}: TasasEfectivas (IEPS no petrolero: juegos)')
if series_arg.strip(): series = series_arg.split()
elif todas: series = sorted(nombre)
else: series = sorted(INVENTARIO)
faltan = [s for s in series if s not in nombre]
if faltan: print('AVISO  series que SCN.ado no descarga (no son del motor): ' + ' '.join(faltan))

# ── 2. Lo congelado: raw/temp/AccesoBIE/<serie>.csv (copia exacta de la descarga) o master/SCN.dta (×1e6; con pastcast) ──
def sha_bytes(b): return hashlib.sha256(b).hexdigest()
def leer_csv(p):
    # AccesoBIE.ado guarda el periodo tal como lo exporta el BIE («2025 p1»); el sufijo lo quita Stata al cargar. Aquí se
    # normaliza igual (misma regex) para que «2025 p1» congelado y «2025» del BIE sean el mismo año; el sufijo se conserva como nota.
    d = {}
    for l in open(p, encoding='utf-8').read().splitlines()[1:]:
        if ',' in l:
            per_raw, val = l.split(',', 1)
            per = re.sub(r'\s*/?\s*[A-Za-z]+\d*\s*$', '', per_raw.strip()).strip()
            d[per] = (float(val) if val.strip() not in ('', 'None') else None)
            suf = per_raw.strip()[len(per):].strip()
            if suf: CNOTAS.setdefault(os.path.basename(p), {})[per] = suf
    return d
CNOTAS = {}
scn = None
def leer_dta():
    global scn
    if scn is None:
        try:
            import pandas as pd
            scn = pd.read_stata(os.path.join(root, 'master', 'SCN.dta'), convert_categoricals=False)
        except Exception as e:
            scn = False; print(f'AVISO  master/SCN.dta no legible ({e}); solo se compara con raw/temp/AccesoBIE/*.csv')
    return scn
def congelado(s):
    p = os.path.join(root, 'raw', 'temp', 'AccesoBIE', f'{s}.csv')
    if os.path.isfile(p):
        b = open(p, 'rb').read()
        return leer_csv(p), f'raw/temp/AccesoBIE/{s}.csv', sha_bytes(b), datetime.datetime.fromtimestamp(os.path.getmtime(p), datetime.timezone.utc).strftime('%Y-%m-%d')
    d = leer_dta()
    if d is not False and d is not None and nombre.get(s) in d.columns:
        col = nombre[s]
        vals = {str(int(a)): (float(v) / 1e6 if v == v else None) for a, v in zip(d['anio'], d[col])}
        p2 = os.path.join(root, 'master', 'SCN.dta')
        return vals, f'master/SCN.dta:{col} (÷1e6; años sin dato BIE vienen del pastcast)', sha_bytes(open(p2, 'rb').read()), datetime.datetime.fromtimestamp(os.path.getmtime(p2), datetime.timezone.utc).strftime('%Y-%m-%d')
    return None, None, None, None

# ── 3. BIE: API oficial (la misma URL que AccesoBIE.ado try_api) y, si la API no responde (HTTP 400 con el token
#       configurado, 2026-10-31), la consulta pública de exportación del BIE (.aspx), el mismo respaldo de AccesoBIE.ado.
#       La vía usada se declara por serie. Los sufijos del periodo («2025 p1», «r1») son la etiqueta INEGI (preliminar/revisada). ──
BASE = 'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml'
EXPORT = 'https://www.inegi.org.mx/app/indicadores/exportacion.aspx'
import html as _html, urllib.parse
def bie_api(s):
    err = ''
    for banco in ('BIE', 'BISE'):
        url = f'{BASE}/INDICATOR/{s}/es/00/false/{banco}/2.0/{token}?type=json'
        for intento in range(2):
            try:
                with abrir(url, 60) as r:
                    data = json.loads(r.read().decode('utf-8'))
                if isinstance(data, dict) and data.get('Series'):
                    se = data['Series'][0]
                    vals, notas = {}, {}
                    for o in se.get('OBSERVATIONS') or []:
                        per = str(o.get('TIME_PERIOD', '')).strip()
                        v = o.get('OBS_VALUE')
                        vals[per] = (float(v) if v not in (None, '', 'N/E') else None)
                        et = ' '.join(str(o.get(k)) for k in ('OBS_STATUS', 'OBS_EXCEPTION', 'OBS_NOTE', 'OBS_SOURCE') if o.get(k) not in (None, '', 'null'))
                        if et: notas[per] = et
                    meta = {k: se.get(k) for k in ('INDICADOR', 'FREQ', 'UNIT', 'UNIT_MULT', 'LASTUPDATE', 'STATUS', 'NOTE', 'SOURCE') if se.get(k) not in (None, '')}
                    return vals, notas, meta, f'API {banco}', None
                err = f'{banco}: respuesta sin Series'; break
            except urllib.error.HTTPError as e:
                err = f'{banco}: HTTP {e.code}'; break          # 4xx es definitivo: no se reintenta
            except Exception as e:
                err = f'{banco}: {e}'; time.sleep(2)
    return None, None, None, None, err
def bie_export(s):
    params = {'cveser': s, 'bie': 'false', 'aamin': '1980', 'aamax': '9999', 'ordena': 'a', 'ordenaPeriodo': 'ap', 'orientacion': 'v',
              'frecuencia': 'Todo', 'estadistico': 'false', 'FileFormat': 'iqy', 'ag': '0', 'subapp': 'BIE', 'tematica': '3', 'tyExp': '1', 'view': 'filas'}
    err = ''
    for intento in range(3):
        try:
            with abrir(EXPORT + '?' + urllib.parse.urlencode(params), 90) as r:
                b = r.read().decode('utf-8', 'replace')
            i = b.find('tableContainerSinScroll')
            if i < 0: return None, None, None, None, 'exportación: la página no trae tabla (¿clave inexistente?)'
            tab = b[i:b.find('</table>', i)]
            rows = re.findall(r'<tr[^>]*>(.*?)</tr>', tab, flags=re.S)
            vals, notas, titulo = {}, {}, ''
            for k, row in enumerate(rows):
                cells = [_html.unescape(re.sub(r'<[^>]+>', '', c)).strip() for c in re.findall(r'<t[dh][^>]*>(.*?)</t[dh]>', row, flags=re.S)]
                if k == 0:
                    titulo = cells[2] if len(cells) >= 3 else ''; continue
                if len(cells) < 3 or not cells[0]: continue
                per_raw, val = cells[0], cells[2].replace(',', '').strip()
                per = re.sub(r'\s*/?\s*[A-Za-z]+\d*\s*$', '', per_raw).strip()     # como AccesoBIE.ado: «2025 p1» → «2025»
                suf = per_raw[len(per):].strip()
                vals[per] = (float(val) if val not in ('', 'ND', 'N/E', '-') else None)
                if suf: notas[per] = suf + ' (etiqueta INEGI en el periodo: p = preliminar, r = revisada)'
            m = re.search(r'Fecha de consulta:\s*([0-9/]+\s+[0-9:]+)', b)
            meta = {'INDICADOR': s, 'TITULO': re.sub(r'\s*/[A-Za-z]\d*', '', titulo), 'NOTAS_TITULO': ' '.join(re.findall(r'/[A-Za-z]\d*', titulo)), 'FECHA_CONSULTA_INEGI': m.group(1) if m else ''}
            return vals, notas, meta, 'exportación pública (.aspx)', None
        except Exception as e:
            err = f'exportación: {e}'; time.sleep(3)
    return None, None, None, None, err
api_fallas = {}
def bie(s):
    vals, notas, meta, via, err = bie_api(s)
    if vals is not None: return vals, notas, meta, via, None
    api_fallas[s] = err
    vals, notas, meta, via, err2 = bie_export(s)
    if vals is not None: return vals, notas, meta, via + f' [API: {err}]', None
    return None, None, None, None, f'API: {err}; {err2}'

# ── 4. Comparar ──
filas, resumen, nocomp = [], [], []
BVALS = {}
pib_cong = congelado('724025')[0] or {}
for s in series:
    if s not in nombre: continue
    cvals, cfuente, csha, cfecha = congelado(s)
    bvals, bnotas, bmeta, via, err = bie(s)
    if err or bvals is None:
        nocomp.append((s, nombre[s], f'BIE no respondió: {err}')); continue
    canon = 'periodo,valor\n' + ''.join(f'{p},{"" if v is None else str(v)}\n' for p, v in bvals.items())
    bsha = sha_bytes(canon.encode('utf-8'))
    if cvals is None:
        nocomp.append((s, nombre[s], 'sin serie congelada (ni raw/temp/AccesoBIE ni master/SCN.dta)')); continue
    en_ref = lambda p: anio_de(p) is not None and anio_de(p) <= ANIO_REF
    fuera = sorted({p for p in set(cvals) | set(bvals) if not en_ref(p)}, key=lambda x: (len(x), x))
    comunes = sorted({p for p in set(cvals) & set(bvals) if en_ref(p)}, key=lambda x: (len(x), x))
    solo_bie = sorted({p for p in set(bvals) - set(cvals) if en_ref(p)}, key=lambda x: (len(x), x))
    solo_cong = sorted({p for p in set(cvals) - set(bvals) if en_ref(p)}, key=lambda x: (len(x), x))
    dif = []
    for p in comunes:
        a, b = cvals[p], bvals[p]
        if a is None and b is None: continue
        if a is None or b is None or a != b:
            pib = pib_cong.get(p)
            d = (None if a is None or b is None else b - a)
            dpib = (None if d is None or not pib else d / pib * 100)
            dif.append((p, a, b, d, dpib, bnotas.get(p, '')))
            filas.append((s, nombre[s], p, a, b, d, dpib, bnotas.get(p, ''), cfuente))
    etiqueta_ult = ''
    dentro = [p for p in bvals if en_ref(p)]
    if dentro:
        ult = max(dentro, key=lambda x: (len(x), x))
        etiqueta_ult = f'{ult}: {bnotas.get(ult, "sin sufijo ni nota: cifra definitiva")}'
    if fuera:
        etiqueta_ult += ' · fuera de referencia: ' + '; '.join(f'{p} {bnotas.get(p, "")}'.strip() for p in fuera if p in bvals)
    BVALS[s] = (bvals, bnotas, bmeta, via)
    resumen.append({'serie': s, 'nombre': nombre[s], 'etiqueta': etiqueta.get(nombre[s], ''), 'uso': INVENTARIO.get(s, '(solo UpdateSCN)'),
                    'congelado': {'fuente': cfuente, 'sha256': csha, 'fecha_archivo': cfecha, 'n': len(cvals)},
                    'bie': {'via': via, 'sha256_canonico': bsha, 'n': len(bvals), 'lastupdate': (bmeta or {}).get('LASTUPDATE') or (bmeta or {}).get('FECHA_CONSULTA_INEGI'), 'nota_serie': (bmeta or {}).get('NOTE') or (bmeta or {}).get('NOTAS_TITULO'), 'etiqueta_ultimo': etiqueta_ult, 'consulta': fecha},
                    'comparacion': {'anio_referencia': ANIO_REF, 'anios_comunes': len(comunes), 'diferencias': len(dif), 'solo_bie': solo_bie, 'solo_congelado': solo_cong, 'fuera_referencia': fuera,
                                    'dmax': max((abs(x[3]) for x in dif if x[3] is not None), default=0.0)}})

# ── 5. CSI (opcional): cuadros y filas que lee el motor (SCN.ado §9-§25b y SCNHogaresS14) ──
csi_rep = None
if csi:
    CELDAS = [('CSI_103', 60, 'IngMixto B.3b (U/A)'), ('CSI_103', 41, 'SSImputada D.122 (U/A)'), ('CSI_103', 54, 'SubProductos D.31 (U/A)'),
              ('CSI_103', 58, 'SubProduccion D.39 (U/A)'), ('CSI_103', 62, 'DepMix P.51c mixto (U/A)'), ('CSI_106', 59, 'ExBOpNoFin B.2b (U/A)'),
              ('CSI_109', 59, 'ExBOpFin B.2b (U/A)'), ('CSI_118', 59, 'ExBOpISFLSH B.2b (U/A)'), ('CSI_115', 59, 'ExBOpHog B.2b (U/A)'),
              ('CSI_112', 59, 'ExBOpGob B.2b (U/A)'), ('CSI_106', 63, 'ExNOpNoFin B.2n (U/A)'), ('CSI_109', 63, 'ExNOpFin B.2n (U/A)'),
              ('CSI_118', 63, 'ExNOpISFLSH B.2n (U/A)'), ('CSI_115', 63, 'ExNOpHog B.2n (U/A)'), ('CSI_112', 63, 'ExNOpGob B.2n (U/A)'),
              ('CSI_103', 170, 'AhorroB B.8b (U/A)'), ('CSI_103', 152, 'IngDisp B.6b (U/A)'),
              ('CSI_115', 170, 'AhorroHogB B.8b'), ('CSI_115', 171, 'AhorroHogN B.8n'), ('CSI_115', 166, 'ConHogS14 P.3'), ('CSI_115', 176, 'ConEfecHogS14 P.4'),
              ('CSI_115', 117, 'ContribSocHog D.61'), ('CSI_115', 127, 'ContribComplHog D.614'), ('CSI_103', 25, 'ImpProductosS1 D.21 (R/P)'),
              ('CSI_103', 26, 'SubProductosS1 D.31 (R/P)'), ('CSI_115', 169, 'AjustePensHog D.8 (R/P)'), ('CSI_115', 131, 'PrestSocHog D.62 (R/P)'),
              ('CSI_115', 151, 'OtrasTransfHog D.759 (R/P)'), ('CSI_115', 69, 'ExNOpHogS14 B.2n (R/P)'), ('CSI_115', 70, 'MixNHogS14 B.3n (R/P)'),
              ('CSI_115', 95, 'RentaPropHog D.4 (R/P y U/A)'), ('CSI_115', 157, 'D.63 (verificación P.4 − P.3)'),
              # v8.15b (E1/E3): anclas firmadas y filas de sector de la identidad del PIB (SCNHogaresS14)
              ('CSI_115', 71, 'D1HogS14 D.1 (R/P)'), ('CSI_115', 103, 'D442Hog D.442 (R/P)'), ('CSI_115', 150, 'RemesasHogS14 D.752 (R/P)'),
              ('CSI_115', 114, 'ImpIngHog D.5 (U/A)'), ('CSI_115', 139, 'OtrasTransfHogR/U D.7 (R/P y U/A)'),
              ('CSI_106', 110, 'B5nNoFin B.5n (U/A)'), ('CSI_109', 110, 'B5nFin B.5n (U/A)'), ('CSI_112', 110, 'B5nGob B.5n (U/A)'), ('CSI_118', 110, 'B5nISFLSH B.5n (U/A)'),
              ('CSI_112', 80, 'ImpProdGobR D.2 (R/P)'), ('CSI_112', 89, 'SubGobR D.3 (R/P)'), ('CSI_112', 95, 'RentaPropGob D.4 (R/P y U/A)'),
              ('CSI_121', 71, 'RemRowU D.1 (U/A)'), ('CSI_121', 95, 'RentaPropRow D.4 (U/A y R/P)'),
              ('CSI_103', 27, 'PIBCSI B.1b (U/A)'), ('CSI_103', 28, 'CapFijCSI P.51c (U/A)'), ('CSI_103', 110, 'B5nS1 B.5n (U/A)')]
    csi_rep = {'zip': 'https://www.inegi.org.mx/contenidos/programas/si/2018/tabulados/ori/tabulados_CSI.zip', 'cuadros': {}, 'celdas': []}
    try:
        import openpyxl
        tmp = tempfile.mkdtemp(prefix='refrescar-csi-')
        zp = os.path.join(tmp, 'tabulados_CSI.zip')
        with abrir(csi_rep['zip'], 300) as r:
            open(zp, 'wb').write(r.read())
        csi_rep['zip_sha256'] = sha_bytes(open(zp, 'rb').read())
        csi_rep['zip_local'] = zp
        z = zipfile.ZipFile(zp)
        for c in sorted({c for c, _, _ in CELDAS}):
            nuevo = z.read(f'{c}.xlsx')
            viejo_p = os.path.join(root, 'raw', 'temp', 'SCN', f'{c}.xlsx')
            viejo = open(viejo_p, 'rb').read() if os.path.isfile(viejo_p) else None
            csi_rep['cuadros'][c] = {'sha256_congelado': sha_bytes(viejo) if viejo else None, 'sha256_bie': sha_bytes(nuevo), 'igual': (viejo is not None and sha_bytes(viejo) == sha_bytes(nuevo))}
            if viejo is None: continue
            wa = openpyxl.load_workbook(io.BytesIO(viejo), read_only=True, data_only=True).active
            wb = openpyxl.load_workbook(io.BytesIO(nuevo), read_only=True, data_only=True).active
            for cu, fila, desc in CELDAS:
                if cu != c: continue
                ra = [x.value for x in next(wa.iter_rows(min_row=fila, max_row=fila, min_col=1, max_col=45))]
                rb = [x.value for x in next(wb.iter_rows(min_row=fila, max_row=fila, min_col=1, max_col=45))]
                difs = [(i, ra[i], rb[i]) for i in range(1, 45) if ra[i] != rb[i]]
                # columnas del año de referencia: pares (U/A, R/P) desde B = 2003; U/A = 2 + 2*(anio−2003), R/P = la siguiente (1-based)
                cu_ = 2 + 2*(ANIO_REF - 2003)
                csi_rep['celdas'].append({'cuadro': c, 'fila': fila, 'descripcion': desc, 'rotulo_congelado': ra[0], 'rotulo_bie': rb[0], 'columnas_distintas': len(difs),
                                          'anio_referencia': ANIO_REF, 'UA': rb[cu_ - 1] if cu_ - 1 < len(rb) else None, 'RP': rb[cu_] if cu_ < len(rb) else None,
                                          'detalle': [{'col': i + 1, 'congelado': a, 'bie': b} for i, a, b in difs][:50]})
    except Exception as e:
        csi_rep['error'] = str(e)

# ── 6. Reporte ──
dif_tot = sum(r['comparacion']['diferencias'] for r in resumen)
sellos = sum(1 for r in resumen if r['comparacion']['diferencias'] or r['comparacion']['solo_bie'] or r['comparacion']['solo_congelado'])
con_fuera = sum(1 for r in resumen if r['comparacion']['fuera_referencia'])
md = [f'# refrescar-scn --comparar — {fecha}', '', f'Repo: `{root}` · series pedidas: {len(series)} · comparadas: {len(resumen)} · no comparadas: {len(nocomp)} · con celdas distintas: {sum(1 for r in resumen if r["comparacion"]["diferencias"])} · con años ≤ referencia solo en un lado: {sum(1 for r in resumen if r["comparacion"]["solo_bie"] or r["comparacion"]["solo_congelado"])} · celdas distintas: {dif_tot}', '',
      f'Año de referencia: **{ANIO_REF}** ({anio_fuente}); se comparan los años ≤ {ANIO_REF}. Series con años posteriores: {con_fuera} (sección «Fuera del año de referencia»; no son revisión).', '',
      'Tolerancia cero sobre el valor publicado. «Congelado» = lo que el motor leyó la última vez (raw/temp/AccesoBIE/<serie>.csv; si falta, master/SCN.dta). Nada se escribe en raw/ ni en el manifest.', '',
      '## Resumen por serie', '', '| Serie | Variable | Uso en el motor | Congelado (fuente, fecha, sha256) | BIE (vía; LASTUPDATE o fecha de consulta INEGI; sha256 canónico) | Años comunes (≤ ref) | Distintos | Solo BIE (≤ ref) | Fuera de referencia | Etiqueta INEGI último dato (≤ ref) |', '|---|---|---|---|---|---:|---:|---|---|---|']
for r in resumen:
    c, b, k = r['congelado'], r['bie'], r['comparacion']
    md.append(f"| {r['serie']} | `{r['nombre']}` {r['etiqueta']} | {r['uso']} | {c['fuente']}, {c['fecha_archivo']}, `{(c['sha256'] or '')[:12]}` | {b['via']}; {b['lastupdate']}; `{b['sha256_canonico'][:12]}` | {k['anios_comunes']} | {k['diferencias']} | {' '.join(k['solo_bie']) or '—'} | {' '.join(k['fuera_referencia']) or '—'} | {b['etiqueta_ultimo']} |")
if api_fallas:
    md += ['', f'**API oficial del BIE:** no respondió en {len(api_fallas)} serie(s) con el token configurado (p. ej. {sorted(api_fallas.items())[0][1]}); se usó la consulta pública de exportación del BIE (.aspx), el mismo respaldo de `AccesoBIE.ado`. Revisar el token (set_token.do) o la API antes de 8.15b.']
md += ['', '## Celdas distintas (serie, año, congelado, BIE, Δ, Δ % del PIB del año, etiqueta INEGI)', '']
if filas:
    md += ['| Serie | Variable | Año | Congelado | BIE | Δ | Δ % PIB | Etiqueta | Fuente congelada |', '|---|---|---|---:|---:|---:|---:|---|---|']
    for s, n, p, a, b, d, dp, et, f in filas:
        md.append(f"| {s} | `{n}` | {p} | {a if a is not None else 'N/E'} | {b if b is not None else 'N/E'} | {'' if d is None else f'{d:,.3f}'} | {'' if dp is None else f'{dp:.4f}'} | {et} | {f} |")
else:
    md.append('Ninguna: sin revisión INEGI en las celdas comparadas.')
if con_fuera:
    md += ['', f'## Fuera del año de referencia ({ANIO_REF})', '', 'Años que el BIE o lo congelado traen después del año ENIGH del motor. No se comparan ni cuentan como revisión; un refresco los incorporaría y movería el pastcast/forecast de SCN.ado (entra solo por PR de datos).', '']
    for r in resumen:
        if r['comparacion']['fuera_referencia']:
            cn = CNOTAS.get(f"{r['serie']}.csv", {})
            md.append(f"- {r['serie']} `{r['nombre']}`: " + ', '.join(f"{a}{' (congelado: ' + cn[a] + ')' if a in cn else ''}" for a in r['comparacion']['fuera_referencia']))
if nocomp:
    md += ['', '## No comparadas', ''] + [f'- {s} `{n}`: {m}' for s, n, m in nocomp]
if csi_rep is not None:
    md += ['', '## CSI (tabulados por sector institucional)', '', f"zip: {csi_rep['zip']} sha256 `{csi_rep.get('zip_sha256', '')[:12]}`" + (f" · ERROR: {csi_rep['error']}" if 'error' in csi_rep else ''), '']
    for c, v in csi_rep['cuadros'].items():
        md.append(f"- {c}.xlsx: congelado `{(v['sha256_congelado'] or 'ausente')[:12]}` vs descargado `{v['sha256_bie'][:12]}` → {'igual' if v['igual'] else 'DISTINTO (o sin congelado)'}")
    cd = [x for x in csi_rep['celdas'] if x['columnas_distintas']]
    md.append(f"- filas del inventario comparadas: {len(csi_rep['celdas'])}; con celdas distintas: {len(cd)}")
    for x in cd: md.append(f"  - {x['cuadro']} f.{x['fila']} {x['descripcion']}: {x['columnas_distintas']} columna(s) distintas; rótulo `{x['rotulo_congelado']}` → `{x['rotulo_bie']}`")
texto = '\n'.join(md) + '\n'
stamp = hoy.strftime('%Y-%m-%d')
open(os.path.join(salida, f'refrescar-scn-{stamp}.md'), 'w', encoding='utf-8').write(texto)
json.dump({'consulta': fecha, 'anio_referencia': ANIO_REF, 'anio_referencia_fuente': anio_fuente, 'series': resumen, 'celdas_distintas': [dict(zip(('serie', 'nombre', 'anio', 'congelado', 'bie', 'delta', 'delta_pct_pib', 'etiqueta', 'fuente_congelada'), f)) for f in filas],
           'no_comparadas': nocomp, 'csi': csi_rep}, open(os.path.join(salida, f'refrescar-scn-{stamp}.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(texto)
print(f'Reporte: {salida}/refrescar-scn-{stamp}.md (+ .json)')

# ── 7. --congelar (v8.15b, E4): assets en raw/SCN/ y registro scn_vintage en el manifest ──
if congelar:
    if nocomp or csi_rep is None or 'error' in csi_rep:
        print('refrescar-scn --congelar: NO se congela (hay series no comparadas o la CSI falló): «no comparado» no es «sin revisión» (exit 3).'); sys.exit(3)
    dest = os.path.join(root, 'raw', 'SCN')
    os.makedirs(os.path.join(dest, 'bie'), exist_ok=True)
    reg_bie = {}
    for r in resumen:
        s = r['serie']
        bvals, bnotas, bmeta, via = BVALS[s]
        pers = [p for p in bvals if anio_de(p) is not None and anio_de(p) <= ANIO_REF]
        pers.sort(key=lambda x: (len(x), x))
        canon = 'periodo,valor\n' + ''.join(f'{p},{"" if bvals[p] is None else repr(bvals[p])}\n' for p in pers)
        fp = os.path.join(dest, 'bie', f'{s}.csv')
        open(fp, 'w', encoding='utf-8', newline='\n').write(canon)
        ult = max(pers, key=lambda x: (len(x), x)) if pers else ''
        reg_bie[s] = {'variable': r['nombre'], 'etiqueta': r['etiqueta'], 'uso': r['uso'], 'archivo': f'raw/SCN/bie/{s}.csv',
                      'sha256': sha_bytes(canon.encode('utf-8')), 'n': len(pers), 'ultimo': ult,
                      'etiqueta_inegi_ultimo': bnotas.get(ult, 'sin sufijo ni nota: cifra definitiva'),
                      'fuera_de_referencia': r['comparacion']['fuera_referencia'], 'via': via, 'lastupdate': r['bie']['lastupdate'], 'consulta': fecha}
    reg_csi = {'zip': csi_rep['zip'], 'zip_sha256': csi_rep['zip_sha256'], 'consulta': fecha, 'cuadros': {}, 'celdas': []}
    z = zipfile.ZipFile(csi_rep['zip_local'])
    for c in sorted(csi_rep['cuadros']):
        b = z.read(f'{c}.xlsx')
        open(os.path.join(dest, f'{c}.xlsx'), 'wb').write(b)
        reg_csi['cuadros'][c] = {'archivo': f'raw/SCN/{c}.xlsx', 'sha256': sha_bytes(b), 'igual_al_anterior': csi_rep['cuadros'][c]['igual']}
    for x in csi_rep['celdas']:
        lim = lambda v: (None if v is None or (isinstance(v, str) and not v.strip()) else v)
        reg_csi['celdas'].append({'cuadro': x['cuadro'], 'fila': x['fila'], 'descripcion': x['descripcion'], 'rotulo': (x['rotulo_bie'] or '').strip(),
                                  'anio': x['anio_referencia'], 'UA': lim(x['UA']), 'RP': lim(x['RP'])})
    mp = os.path.join(root, '05_scripts', 'manifest.json')
    man = json.load(open(mp, encoding='utf-8'))
    man_new = {}
    for k, v in man.items():
        if k == 'assets':
            man_new['scn_vintage'] = {
                'regla': 'Assets congelados del SCN (CUAD-0 §4 bis, v8.15b E4): raw/SCN/bie/<serie>.csv (periodo,valor; solo años <= anio_referencia) y raw/SCN/CSI_1xx.xlsx. SCN.ado (UpdateSCN, SCNHogaresS14) y AccesoBIE.ado los leen cuando existen y verifican su sha256 (sello verde); sin asset descargan en caliente y lo declaran (sello amarillo). Se reescriben SOLO con refrescar-scn.sh --congelar en un PR de datos (data_updated y CHANGELOG declaran el delta). raw/SCN/ no se versiona: viaja con la Release.',
                'consulta': fecha, 'anio_referencia': ANIO_REF, 'anio_referencia_fuente': anio_fuente,
                'canal': 'API oficial del BIE con respaldo en la consulta pública de exportación (.aspx); la vía real de cada serie va en bie.<serie>.via',
                'series_congeladas': len(reg_bie), 'bie': reg_bie, 'csi': reg_csi}
        man_new[k] = v
    if 'scn_vintage' not in man_new:
        man_new['scn_vintage'] = man.get('scn_vintage')
    json.dump(man_new, open(mp, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    open(mp, 'a', encoding='utf-8').write('\n')
    print(f'CONGELADO: {len(reg_bie)} series en {dest}/bie/ (años <= {ANIO_REF}), {len(reg_csi["cuadros"])} cuadros CSI en {dest}/, registro scn_vintage en {mp}')
csi_dist = bool(csi_rep) and ('error' in csi_rep or any(not v['igual'] for v in csi_rep['cuadros'].values()))
if nocomp or (csi_rep and 'error' in csi_rep):
    print(f'RESULTADO: NO COMPARADO en {len(nocomp)} serie(s)' + (' y CSI con error' if csi_rep and 'error' in csi_rep else '') + ' (exit 3): «no comparado» no es «sin revisión».'); sys.exit(3)
if dif_tot or csi_dist:
    print('RESULTADO: INEGI REVISÓ (exit 1): hay celdas distintas; el refresco entra solo por PR de datos (--congelar sigue deshabilitado).'); sys.exit(1)
anios_fuera = sorted({a for r in resumen for a in r['comparacion']['fuera_referencia']})
extra = f'; {con_fuera} serie(s) con años fuera del año de referencia {ANIO_REF} ({", ".join(anios_fuera)}): no se comparan' if con_fuera else ''
print(f'RESULTADO: sin revisión INEGI (exit 0): las celdas congeladas coinciden con el BIE hasta {ANIO_REF}' + extra + '.')
PYEOF
