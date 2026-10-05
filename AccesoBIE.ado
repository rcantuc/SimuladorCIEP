*! version 8.1 CIEP 04oct2026
*! AccesoBIE - Acceso al Banco de Indicadores del INEGI via API oficial
*! (con respaldo automático vía la consulta pública de exportación .aspx)
*! Sintaxis: AccesoBIE serie1 [serie2 ...] [, nombres(string) token(string) area(##)]
*! Ejemplo: AccesoBIE 628194              <- obtiene serie con nombre automático
*! Ejemplo: AccesoBIE 628194 444612, nombres(PIB Desempleo)
*! Ejemplo: AccesoBIE 750453, nombres(PIBE) area(19)   <- indicador estatal, Nuevo León

program define AccesoBIE
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
	version 17.0
	
	syntax anything(name=series) [, Nombres(string) Token(string) AREa(string)]

	// area() (v8.1): el BIE exporta cada indicador con las 33 áreas geográficas
	// apiladas en la columna "Área geográfica" (00 nacional, 01-32 entidades).
	// Sin area() el comando lee periodo/valor como siempre (correcto para las
	// series nacionales, que solo traen el área 00). Con area(##) descarga la
	// TABLA COMPLETA del indicador una vez por sesión, la cachea en
	// raw/temp/AccesoBIE/<serie>_areas.csv (+ .meta: título, fecha de consulta
	// INEGI, áreas, n) con escritura atómica y filtra el área pedida al cargar.
	if "`area'" != "" {
		capture confirm integer number `area'
		local ok = _rc == 0
		if `ok' local ok = `area' >= 0 & `area' <= 32
		if !`ok' {
			display as error "AccesoBIE: area() debe ser la clave de dos d{c i'}gitos del {c a'}rea geogr{c a'}fica del BIE (00 nacional, 01-32 entidades); recibi{c o'} `area'."
			exit 198
		}
		local area : di %02.0f `area'
	}
	
	// Token vía global Stata $BIE_API_TOKEN. Sin token NO se aborta: se salta
	// la API oficial y se usa la consulta pública de exportación (.aspx) del
	// INEGI, avisando al usuario por cuál vía obtuvo los datos.
	local sintoken = 0
	if "`token'" == "" {
		if "$BIE_API_TOKEN" == "" {
			local sintoken = 1
			display as text "AccesoBIE: sin token del BIE/INEGI — usando la consulta p{c u'}blica (.aspx) del INEGI."
			display as text "Para la v{c i'}a oficial (recomendada), configura tu token gratuito:"
			display as text `"  global BIE_API_TOKEN "tu-token"  — solicita el tuyo en: https://www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx"'
			display as text "(Investigadores CIEP: corre set_token.do o reinicia Stata; profile.do lo carga al arranque.)"
		}
		local token "$BIE_API_TOKEN"
	}
	
	quietly {
		// Crear directorios temporales (mkdir no es recursivo: nivel por nivel;
		// una instalación fresca no trae ni el directorio site/)
		capture mkdir "${SIMROOT}"
		capture mkdir "${SIMROOT}/raw/"
		capture mkdir "${SIMROOT}/raw/temp/"
		capture mkdir "${SIMROOT}/raw/temp/AccesoBIE/"
		
		// Tokenizar las series
		local nseries : word count `series'
		
		// Tokenizar los nombres si se proporcionaron
		local nnames : word count `nombres'
		
		// Procesar cada serie
		local j = 1
		foreach serie of local series {
			
			if "`area'" != "" {
				// Modo area(): tabla completa del indicador (consulta pública),
				// cacheada una vez por sesión; aquí se filtra el área pedida.
				local csvareas "${SIMROOT}/raw/temp/AccesoBIE/`serie'_areas.csv"
				global INEGI_AREAS_ERR_`serie' ""
				python: inegi_area("`serie'")
				if "${INEGI_AREAS_ERR_`serie'}" != "" {
					noisily display as error "AccesoBIE: ${INEGI_AREAS_ERR_`serie'}"
					global INEGI_AREAS_ERR_`serie' ""
					exit 459
				}
				checksum "`csvareas'"
				local chk = r(checksum)
				import delimited "`csvareas'", clear varnames(1) encoding(utf-8) stringcols(1 2 4)
				local nfilas = _N
				keep if area == "`area'"
				if _N == 0 {
					noisily display as error "AccesoBIE: el indicador `serie' no trae filas para el {c a'}rea `area'. {c A'}reas disponibles: ${INEGI_AREAS_LIST_`serie'}"
					exit 459
				}
				drop area
				capture drop nota
				noisily display as text "  {c A'}rea " as result "`area'" as text " de `serie' | tabla completa: `nfilas' filas, consulta INEGI ${INEGI_AREAS_FECHA_`serie'}, checksum `chk'"
			}
			else {
				// Llamar a Python para obtener datos via API oficial
				python: inegi_api("`serie'", "`token'")
				
				// Importar los datos
				import delimited "${SIMROOT}/raw/temp/AccesoBIE/`serie'.csv", clear varnames(1) encoding(utf-8)
			}
			
			// Verificar que hay datos. Si una serie no se obtuvo por NINGUNA
			// vía, el error truena aquí, claro y en su origen — no después,
			// como error críptico del merge/use con tempfiles indefinidos.
			if _N == 0 {
				noisily display as error "AccesoBIE: no se pudo obtener la serie `serie' por ninguna v{c i'}a (API oficial y consulta p{c u'}blica agotadas)."
				noisily display as error "Verifica tu conexi{c o'}n a internet y la clave de la serie."
				if `sintoken' {
					noisily display as error "Sin token solo se intenta la consulta p{c u'}blica. Para la v{c i'}a oficial (API), configura tu token gratuito:"
					noisily display as error `"  global BIE_API_TOKEN "tu-token"  — solicita el tuyo en: https://www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx"'
					noisily display as error "(Investigadores CIEP: corre set_token.do o reinicia Stata; profile.do lo carga al arranque.)"
				}
				exit 198
			}
			
			// Obtener el nombre de la variable
			if `j' <= `nnames' {
				local varname : word `j' of `nombres'
			}
			else {
				// Usar el nombre obtenido de los metadatos (guardado por Python)
				local varname = "${INEGI_VARNAME_`serie'}"
				if "`varname'" == "" local varname "v`serie'"
			}
			
			// Obtener la etiqueta (<= 80 bytes, para label var) y la
			// descripción completa (jerarquía del indicador, para pantalla)
			local varlabel = "${INEGI_LABEL_`serie'}"
			local vardesc = "${INEGI_DESC_`serie'}"
			if "`vardesc'" == "" local vardesc "`varlabel'"
			
			// Mostrar información de descarga
			noisily display as text "  Serie: " as result "`serie'" as text " | Variable: " as result "`varname'" as text " | " as text "`vardesc'"
			
			// Limpiar el nombre de la variable (solo caracteres válidos)
			local varname = ustrregexra("`varname'", "[^a-zA-Z0-9_]", "_")
			local varname = substr("`varname'", 1, 32)
			if regexm("`varname'", "^[0-9]") local varname "v`varname'"
			
			// Renombrar la variable de valor
			capture rename valor `varname'
			if _rc != 0 {
				capture rename value `varname'
				if _rc != 0 {
					capture rename variable `varname'
				}
			}
		
			// Aplicar etiqueta de los metadatos
			if "`varlabel'" != "" {
				capture label var `varname' "`varlabel'"
			}
			
			// Limpiar periodo: siempre string (si ninguna observación trae
			// nota, import delimited lo lee numérico y el merge entre series
			// de la misma llamada choca) y sin las notas al pie del BIE:
			// "2025 p1", "2026/01 r1", "2024/p1", "2023 /a". Una nota que
			// sobreviva impide destring y anio queda str7, con lo que los
			// merge 1:1 anio de SCN y compañía truenan con r(106).
			capture tostring periodo, replace
			replace periodo = ustrregexra(periodo, "\s*/?\s*[A-Za-z]+\d*\s*$", "")
			replace periodo = strtrim(periodo)
			
			// Eliminar columna extra si existe
			capture drop extra
			
			// Guardar temporalmente
			tempfile serie`j'
			save `serie`j''
			local ++j
		}
		
		// Combinar todas las series
		if `nseries' > 1 {
			use `serie1', clear
			forvalues k = 2/`nseries' {
				merge 1:1 periodo using `serie`k'', nogen
			}
		}
		else {
			use `serie1', clear
		}
		
		// Formatear variables numéricas
		foreach k of varlist _all {
			if "`k'" != "periodo" {
				capture confirm string variable `k'
				if _rc != 0 {
					format `k' %20.0fc
				}
				else {
					replace `k' = "" if `k' == "ND"
					destring `k', replace ignore("N/E")
				}
			}
		}
		
		// Procesar periodo (anual, trimestral, mensual)
		capture split periodo, destring p("/")
		if _rc == 0 {
			rename periodo1 anio
			label var anio "Año"
			
			capture confirm string variable periodo2
			if _rc == 0 {
				replace periodo2 = substr(periodo2,1,2)
				destring periodo2, replace
			}

			capture confirm variable periodo2
			if _rc == 0 {
				qui tabstat periodo2, stat(max) save
				if r(StatTotal)[1,1] == 12 {
					rename periodo2 mes
					label var mes "Mes"
				}
				else if r(StatTotal)[1,1] == 4 {
					rename periodo2 trimestre
					label var trimestre "Trimestre"
				}
				else {
					rename periodo2 subperiodo
					label var subperiodo "Subperiodo"
				}
			}
		}
		else {
			rename periodo anio
			destring anio, replace
			label var anio "Año"
		}

		// anio debe salir numérico: aguas arriba (SCN, PIBDeflactor, ...) se
		// cruza con merge 1:1 anio contra bases con anio int, y Stata no
		// cruza string con numérico (r(106)). Mejor tronar aquí, en el
		// origen, mostrando los periodos que no se pudieron convertir.
		capture confirm numeric variable anio
		if _rc {
			noisily display as error "AccesoBIE: anio qued{c o'} como texto; el BIE trae periodos con un formato no previsto:"
			noisily levelsof anio if !ustrregexm(anio, "^[0-9]+$"), clean
			exit 109
		}
		
		// Limpiar variables globales temporales (INEGI_AREAS_<serie> = 1 se
		// conserva: marca que la tabla completa ya se descargó en esta sesión)
		foreach serie of local series {
			global INEGI_VARNAME_`serie' ""
			global INEGI_LABEL_`serie' ""
			global INEGI_DESC_`serie' ""
			global INEGI_AREAS_LIST_`serie' ""
			global INEGI_AREAS_FECHA_`serie' ""
		}
	}
	
	noisily display as text "Serie(s) descargada(s) exitosamente."
end


python:
import requests
import json
import re
import os
import time
import unicodedata
from bs4 import BeautifulSoup
from sfi import Macro

MAX_RETRIES = 3
RETRY_DELAY = 2  # segundos entre reintentos

EXPORT_URL = 'https://www.inegi.org.mx/app/indicadores/exportacion.aspx'


def inegi_area(serie):
    """Modo area() (v8.1): tabla COMPLETA del indicador (las 33 áreas
    geográficas apiladas) desde la consulta pública de exportación, cacheada
    por indicador una vez por sesión en raw/temp/AccesoBIE/<serie>_areas.csv
    (+ .meta). El filtro por área lo hace Stata al cargar. Escritura atómica:
    si la respuesta no trae tabla, ni columna de área, ni filas, se publica el
    error en INEGI_AREAS_ERR_<serie> y el último caché bueno queda intacto."""
    root = Macro.getGlobal('SIMROOT') + '/raw/temp/AccesoBIE/'
    csv_path = root + serie + '_areas.csv'
    meta_path = root + serie + '_areas.meta'

    if Macro.getGlobal(f'INEGI_AREAS_{serie}') == '1' and os.path.exists(csv_path) and os.path.exists(meta_path):
        meta = read_meta(meta_path)
        set_metadata(serie, meta.get('titulo', f'Serie {serie}'))
        Macro.setGlobal(f'INEGI_AREAS_LIST_{serie}', meta.get('areas', ''))
        Macro.setGlobal(f'INEGI_AREAS_FECHA_{serie}', meta.get('fecha_consulta', ''))
        return

    error = ''
    for intento in range(1, MAX_RETRIES + 1):
        try:
            tabla = fetch_area_table(serie)
            write_area_cache(serie, tabla, csv_path, meta_path)
            Macro.setGlobal(f'INEGI_AREAS_{serie}', '1')
            Macro.setGlobal(f'INEGI_AREAS_LIST_{serie}', tabla['areas'])
            Macro.setGlobal(f'INEGI_AREAS_FECHA_{serie}', tabla['fecha'])
            set_metadata(serie, tabla['titulo'])
            print(f"  Fuente: Portal web (tabla completa por área geográfica)")
            print(f"  Indicador: {tabla['titulo']}")
            print(f"  Observaciones: {len(tabla['filas'])} en {tabla['nareas']} área(s); consulta INEGI {tabla['fecha']}")
            return
        except FormatoInesperado as e:
            error = str(e)
            break
        except Exception as e:
            error = f'error de conexión con el INEGI ({e})'
            if intento < MAX_RETRIES:
                print(f"  Reintentando ({intento}/{MAX_RETRIES})...")
                time.sleep(RETRY_DELAY)
    Macro.setGlobal(f'INEGI_AREAS_ERR_{serie}', f'indicador {serie}: {error}; se conserva el último caché.')


class FormatoInesperado(Exception):
    pass


def fetch_area_table(serie):
    """Consulta pública del indicador (mismos parámetros que try_scraping);
    devuelve la tabla completa parseada."""
    params = {
        'cveser': serie, 'bie': 'false', 'aamin': '1980', 'aamax': '9999',
        'ordena': 'a', 'ordenaPeriodo': 'ap', 'orientacion': 'v',
        'frecuencia': 'Todo', 'estadistico': 'false', 'FileFormat': 'iqy',
        'ag': '0', 'subapp': 'BIE', 'tematica': '3', 'tyExp': '1', 'view': 'filas'}
    response = requests.get(EXPORT_URL, params=params, timeout=60)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, 'html.parser')
    table = soup.find('table', {'id': 'tableContainerSinScroll'})
    if not table:
        raise FormatoInesperado('la consulta pública no devolvió tabla (¿clave inexistente?)')
    rows = table.find_all('tr')
    header = [th.get_text(strip=True) for th in rows[0].find_all('th')] if rows else []
    if len(header) < 3 or 'rea geogr' not in header[1].lower():
        raise FormatoInesperado('la tabla no trae la columna "Área geográfica"; este indicador no se exporta por área')
    titulo = re.sub(r'\s*/[fp]\d+', '', header[2])
    fm = re.search(r'Fecha de consulta:\s*([0-9/]+\s+[0-9:]+)', response.text)
    fecha = fm.group(1) if fm else ''
    filas = []
    areas = {}
    for row in rows[1:]:
        cells = [td.get_text(strip=True) for td in row.find_all('td')]
        if len(cells) < 3:
            continue
        periodo, ageo, valor = cells[0], cells[1], cells[2]
        nm = re.search(r'\s*/?\s*([A-Za-z]+\d*)\s*$', periodo)
        nota = nm.group(1) if nm else ''
        periodo = re.sub(r'\s*/?\s*[A-Za-z]+\d*\s*$', '', periodo).strip()
        valor = valor.replace(',', '').replace(' ', '')
        if valor in ['ND', 'N/E', 'N/D', '-']:
            valor = ''
        areas[ageo[:2]] = ageo
        filas.append((periodo, ageo[:2], valor, nota))
    if not filas:
        raise FormatoInesperado('la tabla no trae filas')
    return {'titulo': titulo, 'fecha': fecha, 'filas': filas, 'nareas': len(areas),
            'areas': ' '.join(sorted(areas)), 'url': response.url}


def write_area_cache(serie, tabla, csv_path, meta_path):
    """Escribe <serie>_areas.csv y .meta de forma atómica (.tmp -> os.replace)."""
    tmp = csv_path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        f.write('periodo,area,valor,nota\n')
        for periodo, area, valor, nota in tabla['filas']:
            f.write(f'{periodo},{area},{valor},{nota}\n')
    os.replace(tmp, csv_path)
    tmp = meta_path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        f.write(f"titulo={tabla['titulo']}\nfecha_consulta={tabla['fecha']}\nareas={tabla['areas']}\n")
        f.write(f"n={len(tabla['filas'])}\nurl={tabla['url']}\n")
    os.replace(tmp, meta_path)


def read_meta(meta_path):
    meta = {}
    with open(meta_path, encoding='utf-8') as f:
        for line in f:
            if '=' in line:
                k, v = line.rstrip('\n').split('=', 1)
                meta[k] = v
    return meta

def inegi_api(serie, token):
    """
    Descarga datos del INEGI con reintentos automáticos.
    1. Intenta primero con la API oficial (BIE, BISE)
    2. Si falla, usa scraping del portal de exportación
    3. Reintenta hasta 3 veces si hay errores de conexión
    """
    
    for intento in range(1, MAX_RETRIES + 1):
        # Intentar con API oficial (solo si hay token; sin token no se
        # golpea la API y se va directo a la consulta publica .aspx)
        if token and try_api(serie, token):
            return
        
        # Si la API falla (o no hay token), usar el portal de exportacion
        if intento == 1 and token:
            print("  API no disponible, usando portal web...")
        if try_scraping(serie):
            return
        
        # Si falló, reintentar (excepto en el último intento)
        if intento < MAX_RETRIES:
            print(f"  Reintentando ({intento}/{MAX_RETRIES})...")
            time.sleep(RETRY_DELAY)
    
    # Si todo falla después de todos los reintentos, crear archivo vacío
    print(f"  Error: No se encontraron datos para la serie {serie} después de {MAX_RETRIES} intentos")
    csv_path = Macro.getGlobal('SIMROOT') + '/raw/temp/AccesoBIE/' + serie + '.csv'
    with open(csv_path, 'w', encoding='utf-8') as f:
        f.write('periodo,valor\n')
    Macro.setGlobal(f'INEGI_VARNAME_{serie}', f'v{serie}')
    Macro.setGlobal(f'INEGI_LABEL_{serie}', f'Serie {serie}')
    Macro.setGlobal(f'INEGI_DESC_{serie}', f'Serie {serie}')


def try_api(serie, token):
    """Intenta obtener datos de la API oficial del INEGI."""
    base_url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml"
    
    for banco in ['BIE', 'BISE']:
        url = f"{base_url}/INDICATOR/{serie}/es/00/false/{banco}/2.0/{token}?type=json"
        
        try:
            response = requests.get(url, timeout=30)
            data = response.json()
            
            if isinstance(data, list):  # Error response
                continue
            
            if isinstance(data, dict) and 'Series' in data and len(data['Series']) > 0:
                serie_data = data['Series'][0]
                observations = serie_data.get('OBSERVATIONS', [])
                
                if observations:
                    indicator_name = f"Indicador {serie}"
                    save_data_api(serie, observations, indicator_name, banco)
                    return True
                    
        except:
            continue
    
    return False


def try_scraping(serie):
    """Obtiene datos mediante scraping del portal de exportación."""
    url = 'https://www.inegi.org.mx/app/indicadores/exportacion.aspx'
    params = {
        'cveser': serie,
        'bie': 'false',
        'aamin': '1980',
        'aamax': '9999',
        'ordena': 'a',
        'ordenaPeriodo': 'ap',
        'orientacion': 'v',
        'frecuencia': 'Todo',
        'estadistico': 'false',
        'FileFormat': 'iqy',
        'ag': '0',
        'subapp': 'BIE',
        'tematica': '3',
        'tyExp': '1',
        'view': 'filas'
    }
    
    try:
        response = requests.get(url, params=params, timeout=60)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        table = soup.find('table', {'id': 'tableContainerSinScroll'})
        
        if not table:
            return False
        
        rows = table.find_all('tr')
        if len(rows) < 2:
            return False
        
        # Obtener nombre del indicador del encabezado
        indicator_name = None
        header_cells = rows[0].find_all('th')
        if len(header_cells) >= 3:
            indicator_name = header_cells[2].get_text(strip=True)
            # Limpiar sufijos como /f1 /p1
            indicator_name = re.sub(r'\s*/[fp]\d+', '', indicator_name)
        
        if not indicator_name:
            indicator_name = f"Serie {serie}"
        
        # Extraer datos
        data_rows = []
        for row in rows[1:]:
            cells = row.find_all('td')
            if len(cells) >= 3:
                periodo = cells[0].get_text(strip=True)
                valor = cells[2].get_text(strip=True)  # Tercera columna es el valor
                if periodo and valor:
                    data_rows.append((periodo, valor))
        
        if data_rows:
            save_data_scraping(serie, data_rows, indicator_name)
            return True
        
        return False
        
    except Exception as e:
        print(f"  Error scraping: {e}")
        return False


def save_data_api(serie, observations, indicator_name, banco):
    """Guarda datos obtenidos de la API."""
    set_metadata(serie, indicator_name)
    
    csv_path = Macro.getGlobal('SIMROOT') + '/raw/temp/AccesoBIE/' + serie + '.csv'
    
    with open(csv_path, 'w', encoding='utf-8') as f:
        f.write('periodo,valor\n')
        for obs in observations:
            periodo = obs.get('TIME_PERIOD', '')
            valor = obs.get('OBS_VALUE', '')
            if valor is None or valor == 'N/E':
                valor = ''
            else:
                try:
                    valor = str(float(valor))
                except:
                    pass
            f.write(f'{periodo},{valor}\n')
    
    print(f"  Fuente: API ({banco})")
    print(f"  Indicador: {indicator_name}")
    print(f"  Observaciones: {len(observations)}")


def save_data_scraping(serie, data_rows, indicator_name):
    """Guarda datos obtenidos por scraping."""
    set_metadata(serie, indicator_name)
    
    csv_path = Macro.getGlobal('SIMROOT') + '/raw/temp/AccesoBIE/' + serie + '.csv'
    
    with open(csv_path, 'w', encoding='utf-8') as f:
        f.write('periodo,valor\n')
        for periodo, valor in data_rows:
            valor = valor.replace(',', '').replace(' ', '')
            if valor in ['ND', 'N/E', '-']:
                valor = ''
            f.write(f'{periodo},{valor}\n')
    
    print(f"  Fuente: Portal web")
    print(f"  Indicador: {indicator_name}")
    print(f"  Observaciones: {len(data_rows)}")


FRECUENCIA = r'(?:Anual|Semestral|Cuatrimestral|Trimestral|Bimestral|Mensual|Quincenal|Semanal|Diaria)'
UNIDAD = r'(?:millones|miles|pesos|precios|[ií]ndice|porcentaje|por ciento|unidades|personas|toneladas|d[oó]lares|base \d{4})'
NIVELES_DESC = 4  # niveles finales de la jerarquía que se muestran en pantalla


def set_metadata(serie, indicator_name):
    """Publica como globals de Stata el nombre de variable, la descripción
    (últimos niveles de la jerarquía, para pantalla) y la etiqueta de
    <= 80 bytes (para label var)."""
    desc = clean_label(indicator_name)
    Macro.setGlobal(f'INEGI_VARNAME_{serie}', clean_varname(indicator_name))
    Macro.setGlobal(f'INEGI_DESC_{serie}', desc)
    Macro.setGlobal(f'INEGI_LABEL_{serie}', label80(desc))


def clean_label(name):
    """Quita lo repetitivo del nombre de indicador del BIE: al final, notas al
    pie, unidad entre paréntesis y frecuencia ("... > Total (Millones de pesos
    a precios corrientes) Anual  /f1 /p1"); al inicio, los niveles genéricos
    de la jerarquía ("Cuentas nacionales > Cuentas de bienes y servicios, base
    2018 > A precios corrientes > ..."). Se conservan los últimos NIVELES_DESC
    niveles, que son los que identifican la serie."""
    name = re.sub(r'(?<![A-Za-z])/[a-z]\d*(?=\s|$)', '', name)
    name = re.sub(r'\s*\([^()]*\)\s*' + FRECUENCIA + r'\s*$', '', name, flags=re.I)
    name = re.sub(r'\s*\([^()]*' + UNIDAD + r'[^()]*\)\s*$', '', name, flags=re.I)
    name = re.sub(r'\s+' + FRECUENCIA + r'\s*$', '', name, flags=re.I)
    name = re.sub(r'\s+', ' ', name).strip()
    niveles = [p.strip() for p in name.split('>') if p.strip()]
    return ' > '.join(niveles[-NIVELES_DESC:])


def label80(desc):
    """Recorta la descripción a <= 80 bytes (límite de label var) quitando
    niveles de la jerarquía desde la raíz, que es la parte genérica."""
    partes = [p.strip() for p in desc.split('>')]
    while len(partes) > 1 and len(' > '.join(partes).encode('utf-8')) > 80:
        partes.pop(0)
    label = ' > '.join(partes)
    while len(label.encode('utf-8')) > 80:
        label = label[1:]
    return label.strip()


def clean_varname(name):
    """Limpia un nombre para usarlo como variable de Stata."""
    name_clean = unicodedata.normalize('NFKD', name)
    name_clean = name_clean.encode('ASCII', 'ignore').decode('ASCII')
    name_clean = re.sub(r'[^a-zA-Z0-9]', '_', name_clean)
    name_clean = re.sub(r'_+', '_', name_clean)
    name_clean = name_clean.strip('_')[:32]
    
    if name_clean and name_clean[0].isdigit():
        name_clean = 'v' + name_clean
    
    return name_clean if name_clean else 'valor'

end
