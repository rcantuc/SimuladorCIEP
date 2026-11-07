#!/usr/bin/env python3
# itan-catalogo.py — catálogo de ubicación de las celdas del ISR por rango de ingreso en los Informes Trimestrales (ITAN)
# de la SHCP (sesión 8.16a, 2026-11-07). Recorre los itanfp02_<AAAA><TT>.xlsx congelados en raw/ITAN/ y escribe
# 05_scripts/itan-catalogo.json: por trimestre, nombre exacto de la hoja, fila/columna de cada celda que AccesoITAN.ado
# lee (rangos × tipo de contribuyente, totales por concepto, número de contribuyentes), sha256 y URL. Las tablas se
# mueven entre años (el bloque de rangos empieza en la fila 18 en 2019-2021/1 y 2023/4-2026, y en la 19 en 2021/2-2023/2),
# así que las celdas se localizan aquí por el TEXTO de sus rótulos y el .ado solo lee celdas fijas y verifica los rótulos.
#
# Uso: python3 05_scripts/itan-catalogo.py [--dir raw/ITAN] [--out 05_scripts/itan-catalogo.json] [--zip raw/ITAN/itan-congelado.zip] [--check]
#   --check  no escribe: compara el JSON regenerado con el del repo (exit 0 = igual, 1 = difiere).
#   --zip    empaqueta los .xlsx del catálogo (ordenados, fecha fija) y reporta sha256 y bytes para manifest.json.
# Todo número del motor sigue naciendo en Stata (AccesoITAN.ado lee las celdas con import excel): este script solo localiza.
import argparse, datetime, hashlib, json, os, re, sys, zipfile
import openpyxl

PREFIJO = 'https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/congreso/infotrim/'
CARPETA = {'1': 'it', '2': 'iit', '3': 'iiit', '4': 'ivt'}
RANGOS = ['0 ≤ 250', '250 ≤ 500', '500 ≤ 750', '750 ≤ 1,000', '1,000 ≤ 5,000', '5,000 ≤ 10,000', '10,000 ≤ 20,000',
          '20,000 ≤ 50,000', '50,000 ≤ 100,000', '100,000 ≤ 500,000', 'Más de 500 mil', 'Resto']
TIPOS = {'P': 'total', 'Q': 'pm', 'R': 'pfae', 'S': 'pfsae', 'T': 'ret_ss_pm', 'U': 'ret_ss_pf', 'V': 'aux'}
TIPOS_DESC = {'total': 'Total', 'pm': 'Personas morales', 'pfae': 'Personas físicas con actividad empresarial',
              'pfsae': 'Personas físicas sin actividad empresarial', 'ret_ss_pm': 'Retenciones por sueldos y salarios: personas morales',
              'ret_ss_pf': 'Retenciones por sueldos y salarios: personas físicas', 'aux': 'Otros auxiliares (aduanas, entidades federativas, Tesofe)'}
CONCEPTOS = {'Total': 'total_concepto', 'Personas morales': 'pm_concepto', 'Personas físicas': 'pf_concepto',
             'Retenciones a residentes en el extranjero': 'ret_extranjero', 'Retenciones por salarios': 'ret_salarios'}
CONTRIB = {'Total': 'total', 'Personas morales': 'pm', 'Personas físicas': 'pf', 'Otras Personas físicas y morales': 'otros_pfpm'}


def limpia(s):
    """Rótulo sin pie de nota («Resto 3_/», «Personas morales 1/», «Más de 500 mil») y sin blancos sobrantes."""
    s = str(s).replace('\xa0', ' ').strip()
    s = re.sub(r'\s*\d+_?/\s*$', '', s)
    return re.sub(r'\s+', ' ', s).strip()


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for ch in iter(lambda: f.read(65536), b''):
            h.update(ch)
    return h.hexdigest()


def localiza(path):
    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    for ws in wb.worksheets:
        if 'ISR' not in ws.title.upper():
            continue
        celdas = {}
        for row in ws.iter_rows(min_row=1, max_row=min(ws.max_row, 60)):
            for c in row:
                if isinstance(c.value, str):
                    celdas[(c.row, c.column_letter)] = c.value
        rang = [k for k, v in celdas.items() if limpia(v).startswith('Rangos de ingreso')]
        if not rang:
            continue
        col_r = rang[0][1]
        filas_O = {r: limpia(v) for (r, col), v in celdas.items() if col == col_r}
        f_total = min(r for r, v in filas_O.items() if v == 'Total' and r > rang[0][0])
        f_ini = f_total + 1
        f_fin = max(r for r, v in filas_O.items() if v.startswith('Resto'))
        etiquetas = [filas_O[r] for r in range(f_ini, f_fin + 1)]
        if etiquetas != RANGOS:
            raise SystemExit(f'{os.path.basename(path)}: rangos {etiquetas} no son los 12 canónicos')
        # encabezados de las columnas P..V (filas 13-16): se registran tal cual para que el .ado los verifique
        enc = {}
        for col in TIPOS:
            enc[col] = ' '.join(limpia(celdas.get((r, col), '')) for r in range(rang[0][0] - 1, rang[0][0] + 3) if celdas.get((r, col)))
        periodo = next((limpia(v) for (r, col), v in sorted(celdas.items()) if col == col_r and limpia(v).lower().startswith('enero')), '')
        # bloque de conceptos (col B/C) y de contribuyentes (col E/F): rótulos «Total», «Personas morales», …
        def bloque(col_lab, nombres):
            filas = {r: limpia(v) for (r, col), v in celdas.items() if col == col_lab}
            f0 = min(r for r, v in filas.items() if v == 'Total' and r > rang[0][0])
            out = []
            r = f0
            while r in filas and filas[r] in nombres:
                out.append(filas[r]); r += 1
            return f0, f0 + len(out) - 1, out
        c0, c1, c_et = bloque('B', CONCEPTOS)
        k0, k1, k_et = bloque('E', CONTRIB)
        return {'hoja': ws.title, 'periodo': periodo,
                'rangos': {'col_rango': col_r, 'fila_total': f_total, 'fila_ini': f_ini, 'fila_fin': f_fin, 'cols': TIPOS, 'encabezados': enc, 'etiquetas': etiquetas},
                'conceptos': {'col_label': 'B', 'col_valor': 'C', 'fila_ini': c0, 'fila_fin': c1, 'etiquetas': c_et, 'tipos': [CONCEPTOS[e] for e in c_et]},
                'contribuyentes': {'col_label': 'E', 'col_valor': 'F', 'fila_ini': k0, 'fila_fin': k1, 'etiquetas': k_et, 'tipos': [CONTRIB[e] for e in k_et]}}
    raise SystemExit(f'{os.path.basename(path)}: sin hoja de ISR con «Rangos de ingreso»')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', default='raw/ITAN'); ap.add_argument('--out', default='05_scripts/itan-catalogo.json')
    ap.add_argument('--zip', default=''); ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    archivos = {}
    for f in sorted(os.listdir(a.dir)):
        m = re.fullmatch(r'itanfp02_(\d{4})0(\d)\.xlsx', f)
        if not m:
            continue
        anio, tri = m.group(1), m.group(2)
        p = os.path.join(a.dir, f)
        loc = localiza(p)
        archivos[f'{anio}-{tri}'] = {'archivo': f, 'anio': int(anio), 'trimestre': int(tri),
                                     'url': f'{PREFIJO}{anio}/{CARPETA[tri]}/04afp/{f}', 'sha256': sha256(p), 'size_bytes': os.path.getsize(p), **loc}
    if not archivos:
        raise SystemExit(f'sin itanfp02_*.xlsx en {a.dir}')
    ultimo = max(archivos, key=lambda k: (archivos[k]['anio'], archivos[k]['trimestre']))
    cat = {
        'regla': 'Catálogo de celdas del ISR por rango de ingreso del contribuyente en los Informes Trimestrales de la SHCP (anexo de finanzas públicas itanfp02, hoja I.II RecGobFed a) ISR). Lo genera 05_scripts/itan-catalogo.py sobre los .xlsx congelados en raw/ITAN/ (asset itan-congelado.zip, manifest.json); AccesoITAN.ado lee SOLO estas celdas, verifica el sha256 de cada archivo y el texto de cada rótulo, y produce master/itan-isr-rangos.dta. Se regenera solo con refrescar-scn.sh --itan --congelar (PR de datos).',
        'fuente': 'SHCP, Informes sobre la Situación Económica, las Finanzas Públicas y la Deuda Pública (informes trimestrales al Congreso), anexo de finanzas públicas; cifras del SAT, preliminares sujetas a revisión.',
        'url_prefijo': PREFIJO, 'url_patron': PREFIJO + '<AAAA>/<it|iit|iiit|ivt>/04afp/itanfp02_<AAAA>0<T>.xlsx', 'trimestre_carpeta': CARPETA,
        'unidades': 'mdp = millones de pesos corrientes, acumulado de enero al trimestre; rangos = ingreso anual declarado por el contribuyente, miles de pesos (RIF: declaraciones bimestrales); contribuyentes = número que presentó declaración con pago, por régimen (uno puede contar en varios).',
        'rangos': RANGOS + ['Total'], 'tipos': TIPOS_DESC,
        'no_disponible': {'2013-2018': 'itanfp02_<AAAA><TT>.xlsx existe para 2013/3-2015/4 pero es otro anexo (donativos otorgados, calendario de presupuesto) y en 2016-2018 no existe con ese nombre; ningún anexo .xlsx de los IV trimestres 2015-2018 trae la tabla de ISR por rango (revisados itanfp01-21 de 2015, 2016, 2017 y 2018). La tabla por rango en .xlsx empieza en 2019/1. Para 2012-2018 la captura manual ISRInformesTrimestrales.xlsx (asset) sigue siendo la única fuente en el repo.'},
        'generado': {'script': '05_scripts/itan-catalogo.py', 'fecha': datetime.date.today().isoformat(), 'archivos': len(archivos), 'primero': min(archivos), 'ultimo': ultimo},
        'archivos': archivos}
    if a.zip:
        with zipfile.ZipFile(a.zip, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for k in sorted(archivos):
                p = os.path.join(a.dir, archivos[k]['archivo'])
                zi = zipfile.ZipInfo(archivos[k]['archivo'], date_time=(2020, 1, 1, 0, 0, 0))
                zi.compress_type = zipfile.ZIP_DEFLATED
                with open(p, 'rb') as f:
                    z.writestr(zi, f.read())
        cat['asset'] = {'name': os.path.basename(a.zip), 'sha256': sha256(a.zip), 'size_bytes': os.path.getsize(a.zip)}
        print(f'zip {a.zip}: {cat["asset"]["size_bytes"]} bytes sha256 {cat["asset"]["sha256"]}')
    txt = json.dumps(cat, ensure_ascii=False, indent=1) + '\n'
    if a.check:
        if not os.path.isfile(a.out):
            print(f'--check: no existe {a.out}'); sys.exit(1)
        viejo = json.load(open(a.out, encoding='utf-8'))
        nuevo = json.loads(txt)
        for d in (viejo, nuevo):
            d.get('generado', {}).pop('fecha', None)
            d.pop('asset', None)   # el sha del zip solo se escribe con --zip; --check compara celdas y archivos
        if viejo == nuevo:
            print(f'--check: {a.out} coincide con los {len(archivos)} archivos de {a.dir} (0 diferencias, salvo la fecha)'); sys.exit(0)
        dif = [k for k in nuevo['archivos'] if nuevo['archivos'].get(k) != viejo.get('archivos', {}).get(k)] + [k for k in viejo.get('archivos', {}) if k not in nuevo['archivos']]
        print(f'--check: DIFIERE en {len(dif)} trimestre(s): {dif}' if dif else '--check: DIFIERE en metadatos'); sys.exit(1)
    open(a.out, 'w', encoding='utf-8').write(txt)
    print(f'{a.out}: {len(archivos)} trimestres, {min(archivos)} … {ultimo}')


if __name__ == '__main__':
    main()
