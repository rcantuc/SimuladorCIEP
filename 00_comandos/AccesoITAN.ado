*! version 1.0.0  CIEP 07nov2026 (sesion 8.16a) — ISR por rango de ingreso y tipo de contribuyente desde los Informes Trimestrales de la SHCP (ITAN)
*! AccesoITAN [, VALidar NOGraphs]
*
* Misma familia que AccesoBIE/SCNCongelado (CUAD-0 §4 bis, politica congelada): el motor lee SOLO el asset raw/ITAN/
* (itanfp02_<AAAA><TT>.xlsx, empaquetados en raw/ITAN/itan-congelado.zip, declarado en manifest.json con sha256 y
* `desde`), nunca la red. Las celdas vienen del catalogo 05_scripts/itan-catalogo.json (itan-catalogo.py): hoja, fila y
* columna de cada celda, sha256 de cada archivo y URL. Por archivo se verifica el sha256 (sello verde; distinto: aborta,
* salvo global rawwip, que avisa: amarillo) y el TEXTO de cada rotulo antes de leer (exit 459 si se movio la tabla).
* Produce master/itan-isr-rangos.dta (anio, trimestre, rango, tipo, mdp, contribuyentes; acumulado enero-trimestre,
* millones de pesos corrientes) con chars de sello, catalogo y ultimo trimestre. Todo numero nace en Stata (import excel).
*
*   validar   compara, por anio y trimestre, los totales por tipo extraidos (fila «Total» del bloque de rangos) con la
*             captura manual raw/ISRInformesTrimestrales.xlsx (hoja TipoDeContribuyente, la que hoy lee DatosAbiertos.ado)
*             e imprime capturado, extraido y delta; r(maxdelta) = max |delta| en mdp. El ITAN manda.
* En 8.16a el motor sigue leyendo ISRInformesTrimestrales.xlsx: este .dta se produce en paralelo (plan de retiro: CUAD-1 §8 ter).

program define AccesoITAN, rclass
	version 17.0
	syntax [, VALidar NOGraphs]
	local cat "${SIMROOT}/05_scripts/itan-catalogo.json"
	capture confirm file "`cat'"
	if _rc != 0 {
		di as err "AccesoITAN: no existe `cat' (lo genera 05_scripts/itan-catalogo.py; se regenera con refrescar-scn.sh --itan --congelar)."
		exit 601
	}
	capture mkdir "${SIMROOT}/raw"
	capture mkdir "${SIMROOT}/raw/ITAN"
	capture mkdir "${SIMROOT}/master"

	* 1. Asset: si falta algun .xlsx del catalogo, ensure_asset baja el zip de la Release (sha256) y se desempaca *
	python: itan_faltan("`cat'")
	if `itan_faltan' > 0 {
		noisily _log aviso, tipo(UPDATE) texto("AccesoITAN: faltan `itan_faltan' archivos del catálogo en raw/ITAN/; se pide el asset itan-congelado.zip") ref("runbook §9")
		capture noisily ensure_asset "itan-congelado.zip"
		if _rc == 0 {
			local cwd0 "`c(pwd)'"
			cd "${SIMROOT}/raw/ITAN"
			capture noisily unzipfile "itan-congelado.zip", replace
			cd "`cwd0'"
		}
	}

	* 2. Catalogo -> locals (python solo parsea JSON y calcula sha256; ningun numero del ISR pasa por python) *
	python: itan_catalogo("`cat'", "$rawwip")
	if "`itan_sello'" == "rojo" {
		di as err "AccesoITAN: `itan_res'"
		di as err "  Si no editaste raw/ITAN/, borra la carpeta y vuelve a correr (se re-descarga del Release); si la actualizaste a proposito: refrescar-scn.sh --itan --congelar (PR de datos)."
		exit 198
	}
	noisily _log aviso, tipo(Sello) texto("`itan_sello' · ITAN congelado en raw/ITAN, catálogo `itan_cat_fecha': `itan_res'") ref("CUAD-1 §8 ter")

	* 3. Extraccion celda a celda, con verificacion de rotulos *
	quietly {
		tempfile acc
		local first = 1
		forvalues i = 1/`itan_n' {
			local f "${SIMROOT}/raw/ITAN/`itan_`i'_archivo'"
			local hoja `"`itan_`i'_hoja'"'
			* 3a. Rangos x tipo: col O (rotulo) y P..V (7 tipos), de la fila Total a la fila Resto *
			import excel using "`f'", sheet("`hoja'") cellrange(O`itan_`i'_rt':V`itan_`i'_r1') clear
			rename O rango
			local k = 1
			foreach c in P Q R S T U V {
				capture confirm string variable `c'
				if _rc == 0 destring `c', replace force
				rename `c' mdp_`: word `k' of `itan_tipos''
				local ++k
			}
			replace rango = ustrregexra(ustrtrim(rango), "\s*[0-9]+_?/\s*$", "")
			replace rango = ustrregexra(rango, "\s+", " ")
			if rango[1] != "Total" {
				noisily _log aviso, tipo(FLAG) texto(`"AccesoITAN: `itan_`i'_archivo' fila `itan_`i'_rt' dice "`=rango[1]'" y se esperaba Total; la tabla se movió, regenera el catálogo"') ref("itan-catalogo.py") rojo
				exit 459
			}
			local nr = _N
			forvalues r = 2/`nr' {
				local esperado : word `=`r'-1' of `itan_rangos'
				if "`=rango[`r']'" != "`esperado'" {
					noisily _log aviso, tipo(FLAG) texto(`"AccesoITAN: `itan_`i'_archivo' fila `=`itan_`i'_rt'+`r'-1' dice "`=rango[`r']'" y se esperaba "`esperado'"; regenera el catálogo"') rojo
					exit 459
				}
			}
			g int anio = `itan_`i'_anio'
			g byte trimestre = `itan_`i'_trim'
			g double contribuyentes = .
			reshape long mdp_, i(rango) j(tipo) string
			rename mdp_ mdp
			tempfile rangos
			save `rangos'
			* 3b. Totales por concepto (col B rotulo, C mdp) *
			import excel using "`f'", sheet("`hoja'") cellrange(B`itan_`i'_c0':C`itan_`i'_c1') clear
			rename B etiqueta
			capture confirm string variable C
			if _rc == 0 destring C, replace force
			rename C mdp
			replace etiqueta = ustrregexra(ustrtrim(etiqueta), "\s*[0-9]+_?/\s*$", "")
			g str24 tipo = ""
			forvalues r = 1/`=_N' {
				local esperado : word `r' of `itan_`i'_cet'
				if "`=etiqueta[`r']'" != "`esperado'" {
					noisily _log aviso, tipo(FLAG) texto(`"AccesoITAN: `itan_`i'_archivo' concepto fila `=`itan_`i'_c0'+`r'-1' dice "`=etiqueta[`r']'" y se esperaba "`esperado'"; regenera el catálogo"') rojo
					exit 459
				}
				replace tipo = "`: word `r' of `itan_`i'_ctipos''" in `r'
			}
			g str40 rango = "Concepto"
			g int anio = `itan_`i'_anio'
			g byte trimestre = `itan_`i'_trim'
			g double contribuyentes = .
			drop etiqueta
			tempfile conceptos
			save `conceptos'
			* 3c. Numero de contribuyentes que presentaron declaracion con pago (col E rotulo, F numero) *
			import excel using "`f'", sheet("`hoja'") cellrange(E`itan_`i'_k0':F`itan_`i'_k1') clear
			rename E etiqueta
			capture confirm string variable F
			if _rc == 0 destring F, replace force
			rename F contribuyentes
			replace etiqueta = ustrregexra(ustrtrim(etiqueta), "\s*[0-9]+_?/\s*$", "")
			g str24 tipo = ""
			forvalues r = 1/`=_N' {
				local esperado : word `r' of `itan_`i'_ket'
				if "`=etiqueta[`r']'" != "`esperado'" {
					noisily _log aviso, tipo(FLAG) texto(`"AccesoITAN: `itan_`i'_archivo' contribuyentes fila `=`itan_`i'_k0'+`r'-1' dice "`=etiqueta[`r']'" y se esperaba "`esperado'"; regenera el catálogo"') rojo
					exit 459
				}
				replace tipo = "`: word `r' of `itan_`i'_ktipos''" in `r'
			}
			g str40 rango = "Contribuyentes"
			g int anio = `itan_`i'_anio'
			g byte trimestre = `itan_`i'_trim'
			g double mdp = .
			drop etiqueta
			append using `conceptos'
			append using `rangos'
			if `first' == 0 append using `acc'
			save `acc', replace
			local first = 0
		}
		use `acc', clear
		g str40 periodo = ""
		forvalues i = 1/`itan_n' {
			replace periodo = `"`itan_`i'_periodo'"' if anio == `itan_`i'_anio' & trimestre == `itan_`i'_trim'
		}
		order anio trimestre periodo rango tipo mdp contribuyentes
		sort anio trimestre rango tipo
		format mdp %16.3fc
		format contribuyentes %14.0fc
		label var anio "Año del informe"
		label var trimestre "Trimestre (acumulado enero-trimestre)"
		label var periodo "Periodo tal como lo escribe la SHCP"
		label var rango "Rango de ingreso anual declarado (miles de pesos) | Concepto | Contribuyentes"
		label var tipo "Tipo de contribuyente (total pm pfae pfsae ret_ss_pm ret_ss_pf aux; *_concepto; ret_*; otros_pfpm)"
		label var mdp "Recaudación de ISR (millones de pesos corrientes, acumulado)"
		label var contribuyentes "Contribuyentes que presentaron declaración con pago (solo rango = Contribuyentes)"
		char _dta[itan_sello] "`itan_sello'"
		char _dta[itan_catalogo_sha256] "`itan_cat_sha'"
		char _dta[itan_catalogo_fecha] "`itan_cat_fecha'"
		char _dta[itan_ultimo] "`itan_ultimo'"
		char _dta[itan_fuente] "SHCP, Informes Trimestrales (anexo itanfp02, hoja I.II RecGobFed a) ISR); cifras SAT preliminares"
		compress
		save "${SIMROOT}/master/itan-isr-rangos.dta", replace
		count if rango != "Concepto" & rango != "Contribuyentes"
		local nrangos = r(N)
	}
	noisily _log aviso, tipo(Salida) texto("master/itan-isr-rangos.dta: `itan_n' trimestres (`itan_primero' … `itan_ultimo'), `nrangos' celdas rango × tipo; sello `itan_sello'")
	return local sello "`itan_sello'"
	return local ultimo "`itan_ultimo'"
	return scalar n_archivos = `itan_n'

	* 4. Validacion contra la captura manual (ISRInformesTrimestrales.xlsx: acumulados por trimestre, misma unidad) *
	if "`validar'" != "" {
		quietly {
			ensure_asset "ISRInformesTrimestrales.xlsx"
			import excel "${SIMROOT}/raw/ISRInformesTrimestrales.xlsx", clear sheet("TipoDeContribuyente") firstrow case(lower)
			keep anio trimestre total pm pfae pfsae ret_ss_pm ret_ss_pf aux
			rename (total pm pfae pfsae ret_ss_pm ret_ss_pf aux) (cap_total cap_pm cap_pfae cap_pfsae cap_ret_ss_pm cap_ret_ss_pf cap_aux)
			tempfile cap
			save `cap'
			use if rango == "Total" using "${SIMROOT}/master/itan-isr-rangos.dta", clear
			keep anio trimestre tipo mdp
			reshape wide mdp, i(anio trimestre) j(tipo) string
			rename mdp* itan_*
			merge 1:1 anio trimestre using `cap', keep(match) nogen
			g double itan_ss = itan_ret_ss_pm + itan_ret_ss_pf
			g double cap_ss = cap_ret_ss_pm + cap_ret_ss_pf
			g double itan_pf = itan_pfae + itan_pfsae
			g double cap_pf = cap_pfae + cap_pfsae
			g double itan_pmaux = itan_pm + itan_aux
			g double cap_pmaux = cap_pm + cap_aux
			local maxd = 0
			foreach k in total pm pfae pfsae ret_ss_pm ret_ss_pf aux {
				g double d_`k' = itan_`k' - cap_`k'
				summ d_`k'
				local maxd = max(`maxd', abs(r(min)), abs(r(max)))
			}
			sort anio trimestre
		}
		noisily _log cuadro clear
		noisily _log cuadro col, titulo("Año") ancho(4)
		noisily _log cuadro col, titulo("Tri") ancho(3)
		noisily _log cuadro col, titulo("SyS captura") fmt(%12.1fc)
		noisily _log cuadro col, titulo("SyS ITAN") fmt(%12.1fc)
		noisily _log cuadro col, titulo("Δ") fmt(%9.1fc)
		noisily _log cuadro col, titulo("PF captura") fmt(%11.1fc)
		noisily _log cuadro col, titulo("PF ITAN") fmt(%11.1fc)
		noisily _log cuadro col, titulo("Δ") fmt(%9.1fc)
		noisily _log cuadro col, titulo("PM+aux capt.") fmt(%12.1fc)
		noisily _log cuadro col, titulo("PM+aux ITAN") fmt(%12.1fc)
		noisily _log cuadro col, titulo("Δ") fmt(%9.1fc)
		forvalues r = 1/`=_N' {
			noisily _log cuadro fila "`=anio[`r']'" "`=trimestre[`r']'" "cap_ss[`r']" "itan_ss[`r']" "itan_ss[`r']-cap_ss[`r']" "cap_pf[`r']" "itan_pf[`r']" "itan_pf[`r']-cap_pf[`r']" "cap_pmaux[`r']" "itan_pmaux[`r']" "itan_pmaux[`r']-cap_pmaux[`r']"
		}
		noisily _log cuadro print, titulo("Validación: ISRInformesTrimestrales.xlsx capturado vs ITAN extraído; Δ = ITAN − captura") unidad("mdp acumulados") nota("máximo |Δ| en las 7 columnas capturadas (total pm pfae pfsae ret_ss_pm ret_ss_pf aux): `=strtrim(string(`maxd', "%12.3fc"))' mdp en `=_N' trimestres comunes")
		return scalar maxdelta = `maxd'
		return scalar n_validados = _N
	}
end


python:
import hashlib, json, os
from sfi import Macro

def _sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for ch in iter(lambda: f.read(65536), b''):
            h.update(ch)
    return h.hexdigest()

def _cat(cat):
    return json.load(open(cat, encoding='utf-8'))

def itan_faltan(cat):
    root = Macro.getGlobal('SIMROOT')
    c = _cat(cat)
    n = sum(1 for v in c['archivos'].values() if not os.path.isfile(os.path.join(root, 'raw', 'ITAN', v['archivo'])))
    Macro.setLocal('itan_faltan', str(n))

def itan_catalogo(cat, rawwip):
    root = Macro.getGlobal('SIMROOT')
    c = _cat(cat)
    keys = sorted(c['archivos'], key=lambda k: (c['archivos'][k]['anio'], c['archivos'][k]['trimestre']))
    ok = falta = 0
    malos = []
    i = 0
    for k in keys:
        v = c['archivos'][k]
        p = os.path.join(root, 'raw', 'ITAN', v['archivo'])
        if not os.path.isfile(p):
            falta += 1
            continue
        if _sha(p) != v['sha256']:
            malos.append(v['archivo'])
            continue
        ok += 1
        i += 1
        Macro.setLocal(f'itan_{i}_archivo', v['archivo'])
        Macro.setLocal(f'itan_{i}_hoja', v['hoja'])
        Macro.setLocal(f'itan_{i}_anio', str(v['anio']))
        Macro.setLocal(f'itan_{i}_trim', str(v['trimestre']))
        Macro.setLocal(f'itan_{i}_periodo', v['periodo'])
        Macro.setLocal(f'itan_{i}_rt', str(v['rangos']['fila_total']))
        Macro.setLocal(f'itan_{i}_r1', str(v['rangos']['fila_fin']))
        Macro.setLocal(f'itan_{i}_c0', str(v['conceptos']['fila_ini']))
        Macro.setLocal(f'itan_{i}_c1', str(v['conceptos']['fila_fin']))
        Macro.setLocal(f'itan_{i}_cet', ' '.join('"' + e + '"' for e in v['conceptos']['etiquetas']))
        Macro.setLocal(f'itan_{i}_ctipos', ' '.join(v['conceptos']['tipos']))
        Macro.setLocal(f'itan_{i}_k0', str(v['contribuyentes']['fila_ini']))
        Macro.setLocal(f'itan_{i}_k1', str(v['contribuyentes']['fila_fin']))
        Macro.setLocal(f'itan_{i}_ket', ' '.join('"' + e + '"' for e in v['contribuyentes']['etiquetas']))
        Macro.setLocal(f'itan_{i}_ktipos', ' '.join(v['contribuyentes']['tipos']))
    Macro.setLocal('itan_n', str(i))
    Macro.setLocal('itan_tipos', ' '.join(c['archivos'][keys[0]]['rangos']['cols'][col] for col in 'PQRSTUV'))
    Macro.setLocal('itan_rangos', ' '.join('"' + r + '"' for r in c['rangos'] if r != 'Total'))
    Macro.setLocal('itan_primero', keys[0] if keys else '')
    Macro.setLocal('itan_ultimo', c.get('generado', {}).get('ultimo', keys[-1] if keys else ''))
    Macro.setLocal('itan_cat_sha', _sha(cat))
    Macro.setLocal('itan_cat_fecha', str(c.get('generado', {}).get('fecha', '')))
    res = f'{ok} archivo(s) verificados por sha256; {falta} ausente(s); {len(malos)} con sha distinto'
    if malos:
        res += ' (' + ', '.join(malos[:4]) + ('…' if len(malos) > 4 else '') + ')'
        sello = 'amarillo' if rawwip else 'rojo'
    else:
        sello = 'verde' if (ok and not falta) else 'amarillo'
    Macro.setLocal('itan_sello', sello)
    Macro.setLocal('itan_res', res)
end
