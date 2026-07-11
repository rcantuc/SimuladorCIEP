*! version 8.0 CIEP 03jul2026
*! AccesoBIE - Acceso al Banco de Indicadores del INEGI via API oficial
*! (con respaldo automático vía la consulta pública de exportación .aspx)
*! Sintaxis: AccesoBIE serie1 [serie2 ...] [, nombres(string) token(string)]
*! Ejemplo: AccesoBIE 628194              <- obtiene serie con nombre automático
*! Ejemplo: AccesoBIE 628194 444612, nombres(PIB Desempleo)

program define AccesoBIE
	version 17.0
	
	syntax anything(name=series) [, Nombres(string) Token(string)]
	
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
		capture mkdir "`c(sysdir_site)'"
		capture mkdir "`c(sysdir_site)'/raw/"
		capture mkdir "`c(sysdir_site)'/raw/temp/"
		capture mkdir "`c(sysdir_site)'/raw/temp/AccesoBIE/"
		
		// Tokenizar las series
		local nseries : word count `series'
		
		// Tokenizar los nombres si se proporcionaron
		local nnames : word count `nombres'
		
		// Procesar cada serie
		local j = 1
		foreach serie of local series {
			
			// Llamar a Python para obtener datos via API oficial
			python: inegi_api("`serie'", "`token'")
			
			// Importar los datos
			import delimited "`c(sysdir_site)'/raw/temp/AccesoBIE/`serie'.csv", clear varnames(1) encoding(utf-8)
			
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
			
			// Obtener la etiqueta/descripción de los metadatos
			local varlabel = "${INEGI_LABEL_`serie'}"
			
			// Mostrar información de descarga
			noisily display as text "  Serie: " as result "`serie'" as text " | Variable: " as result "`varname'" as text " | " as text "`varlabel'"
			
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
			
			// Limpiar periodo
			*capture replace periodo = subinstr(periodo, "/p1", "", .)
			capture replace periodo = subinstr(periodo, "r1", "", .)
			*capture replace periodo = subinstr(periodo, "/p", "", .)
			*capture replace periodo = subinstr(periodo, "/r", "", .)
			replace periodo = substr(periodo,1,7)
			
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
		
		// Limpiar variables globales temporales
		foreach serie of local series {
			global INEGI_VARNAME_`serie' ""
			global INEGI_LABEL_`serie' ""
		}
	}
	
	noisily display as text "Serie(s) descargada(s) exitosamente."
end


python:
import requests
import json
import re
import time
import unicodedata
from bs4 import BeautifulSoup
from sfi import Macro

MAX_RETRIES = 3
RETRY_DELAY = 2  # segundos entre reintentos

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
    csv_path = Macro.getGlobal('c(sysdir_site)') + '/raw/temp/AccesoBIE/' + serie + '.csv'
    with open(csv_path, 'w', encoding='utf-8') as f:
        f.write('periodo,valor\n')
    Macro.setGlobal(f'INEGI_VARNAME_{serie}', f'v{serie}')
    Macro.setGlobal(f'INEGI_LABEL_{serie}', f'Serie {serie}')


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
    indicator_name_clean = clean_varname(indicator_name)
    
    Macro.setGlobal(f'INEGI_VARNAME_{serie}', indicator_name_clean)
    # Guardar los últimos 80 caracteres (donde está la info relevante)
    label_base = indicator_name.replace('(Millones de Precios corrientes) Anual', '').strip()
    label = label_base[-80:] if len(label_base) > 80 else label_base
    Macro.setGlobal(f'INEGI_LABEL_{serie}', label)
    
    csv_path = Macro.getGlobal('c(sysdir_site)') + '/raw/temp/AccesoBIE/' + serie + '.csv'
    
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
    indicator_name_clean = clean_varname(indicator_name)
    
    Macro.setGlobal(f'INEGI_VARNAME_{serie}', indicator_name_clean)
    # Guardar los últimos 80 caracteres (donde está la info relevante)
    label_base = indicator_name.replace('(Millones de Precios corrientes) Anual', '').strip()
    label = label_base[-80:] if len(label_base) > 80 else label_base
    Macro.setGlobal(f'INEGI_LABEL_{serie}', label)
    
    csv_path = Macro.getGlobal('c(sysdir_site)') + '/raw/temp/AccesoBIE/' + serie + '.csv'
    
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
