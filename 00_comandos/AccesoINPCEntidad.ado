*! version 1.0 CIEP 17oct2026
*!*******************************************
*!***                                    ****
*!***    AccesoINPCEntidad               ****
*!***    INPC por entidad federativa     ****
*!***    (programa INPC de INEGI)        ****
*!***    Autor: Ricardo                  ****
*!***                                    ****
*!***    Sintaxis:                       ****
*!***    AccesoINPCEntidad cc, NOMbre(v) ****
*!*******************************************
*
* ARCHIVO PROPIO (v8.10.1, 2026-10-17): este programa y su bloque python vivían
* dentro de PIBDeflactor.ado (deff8c9, v8.10.0). Un bloque `python:` de nivel
* superior se ejecuta al CARGAR el .ado, así que el run nacional del sitio (que
* nunca usa INPC por entidad) también lo enviaba a Python; en el VPS (Stata/MP
* 17.0 rev. 17ene2022 + Python 3.10) ese parseo truena con r(7102)
* IndentationError y tumbaba "Calcular". Separado en su propio .ado, Stata solo
* lo carga —y solo manda el bloque a Python— cuando UpdatePIBDeflactor lo invoca,
* es decir, con una entidad federativa. La lógica es la misma, byte a byte.
*
* Dependencias Python: requests (misma que AccesoBIE).
*********************************************************
**** INPC por entidad federativa (programa INPC INEGI) ***
*********************************************************
* AccesoINPCEntidad cc, NOMbre(var)
*   Deja en memoria anio mes <var> (mensual) con el índice general del INPC de
*   la entidad cc (01-32), base 2Q jul 2018, Actualización de Canasta y
*   Ponderadores 2024. El INPC estatal no está en el BIE: se exporta en CSV del
*   programa INPC de INEGI (app/indicesdeprecios, estructura 112001700070 "por
*   entidad federativa"). Las 32 series del índice general van en bloques de 430
*   (una por cada nivel de la canasta): serie = 894950 + (cc-1)*430, verificado
*   contra el título de la exportación para las 32 entidades (16oct2026); el
*   título descargado se vuelve a verificar aquí y se aborta si no coincide.
*   Caché por sesión en raw/temp/AccesoBIE/inpc_<cc>.csv (+ .meta), misma
*   carpeta y disciplina (escritura atómica) que AccesoBIE.
program define AccesoINPCEntidad
	syntax anything(name=clave) , NOMbre(name)
	local clave : di %02.0f `clave'
	local serie = 894950 + (`clave' - 1)*430
	capture mkdir "${SIMROOT}/raw/"
	capture mkdir "${SIMROOT}/raw/temp/"
	capture mkdir "${SIMROOT}/raw/temp/AccesoBIE/"
	local csv "${SIMROOT}/raw/temp/AccesoBIE/inpc_`clave'.csv"
	global INEGI_INPC_ERR ""
	python: inegi_inpc_entidad("`clave'", "`serie'", r"""`csv'""")
	if "$INEGI_INPC_ERR" != "" {
		noisily display as error "AccesoINPCEntidad: $INEGI_INPC_ERR"
		global INEGI_INPC_ERR ""
		exit 459
	}
	import delimited "`csv'", clear varnames(1) encoding(utf-8)
	rename valor `nombre'
	noisily display as text "  INPC entidad " as result "`clave'" as text " | Variable: " as result "`nombre'" as text " | serie `serie' (INEGI/INPC, estructura 112001700070): `=_N' meses, {c u'}ltimo `=anio[_N]'/`=string(mes[_N], "%02.0f")'"
end


python:
import os
import re
import requests
from sfi import Macro

INPC_URL = 'https://www.inegi.org.mx/app/indicesdeprecios/Exportacion.aspx?INPtipoExporta=CSV'
INPC_ESTRUCTURA = '112001700070'
INPC_MESES = {'Ene': 1, 'Feb': 2, 'Mar': 3, 'Abr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Ago': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dic': 12}


def inegi_inpc_entidad(clave, serie, csv_path):
    """Exporta el índice general mensual del INPC de la entidad `clave` desde
    el programa INPC de INEGI y lo cachea en csv_path (anio,mes,valor) + .meta.
    Verifica que el título de la serie sea el índice general de la entidad
    pedida; cualquier falla deja el último caché bueno intacto y publica el
    error en INEGI_INPC_ERR."""
    meta_path = csv_path[:-4] + '.meta'
    if Macro.getGlobal(f'INEGI_INPC_{clave}') == '1' and os.path.exists(csv_path):
        return
    form = {'idEstructura': INPC_ESTRUCTURA, '_formato': 'CSV', '_anioI': '1969', '_anioF': '2099',
            '_meta': '0', '_tipo': 'Niveles', '_info': 'Indices', '_orient': 'vertical', 'esquema': '',
            'cvEstructura': INPC_ESTRUCTURA, 'pf': 'inp', 'cuadro': INPC_ESTRUCTURA, '_series': f'c|{serie},'}
    try:
        response = requests.post(INPC_URL, data=form, timeout=120)
        response.raise_for_status()
        texto = response.content.decode('windows-1252', 'replace')
        if '<html' in texto[:300].lower():
            raise ValueError('la exportación devolvió HTML en lugar de CSV (formato inesperado)')
        titulo, fecha, filas = '', '', []
        for line in texto.splitlines():
            cells = [c.strip().strip('"') for c in line.split('","')]
            if len(cells) >= 2 and cells[0] == 'Título':
                titulo = cells[1]
            fm = re.search(r'Fecha de consulta:\s*([0-9/]+\s+[0-9:]+)', line)
            if fm:
                fecha = fm.group(1)
            mm = re.match(r'^([A-Z][a-z][a-z])\s+(\d{4})$', cells[0]) if cells else None
            if mm and len(cells) >= 2 and mm.group(1) in INPC_MESES:
                valor = cells[1].replace(',', '').strip()
                if valor not in ('', 'ND', 'N/E', '-'):
                    filas.append((int(mm.group(2)), INPC_MESES[mm.group(1)], float(valor)))
        esperado = rf'por entidad federativa, {clave} [^,]+, .ndice de precios al consumidor, por objeto del gasto, .ndice general$'
        if not re.search(esperado, titulo):
            raise ValueError(f'la serie {serie} no es el índice general de la entidad {clave}: "{titulo}"')
        if not filas:
            raise ValueError(f'la serie {serie} no trae observaciones')
        filas.sort()
        tmp = csv_path + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write('anio,mes,valor\n')
            for anio, mes, valor in filas:
                f.write(f'{anio},{mes},{valor!r}\n')
        os.replace(tmp, csv_path)
        with open(meta_path, 'w', encoding='utf-8') as f:
            f.write(f'titulo={titulo}\nfecha_consulta={fecha}\nserie={serie}\nestructura={INPC_ESTRUCTURA}\n')
            f.write(f'ultimo={filas[-1][0]}/{filas[-1][1]:02d}\nn={len(filas)}\nurl={INPC_URL}\n')
        Macro.setGlobal(f'INEGI_INPC_{clave}', '1')
        print(f'  Fuente: INEGI, programa INPC (exportación CSV); consulta {fecha}')
        print(f'  Indicador: {titulo}')
    except Exception as e:
        Macro.setGlobal('INEGI_INPC_ERR', f'INPC entidad {clave} (serie {serie}): {e}; se conserva el último caché.')
end
