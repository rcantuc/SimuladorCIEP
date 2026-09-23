*! micrositio-pe.do  v1.0.0 — driver de las gráficas del micrositio paqueteeconomico.ciep.mx
*
* QUÉ ES ESTO
* El driver de las gráficas de la página de inicio del micrositio del
* Paquete Económico: corre los módulos de ingresos (LIF) y gasto (PEF)
* del motor PARA CADA AÑO 2013-<aniomax>, toma las cifras que ELLOS
* producen (mismo blueprint que 01_modulos/nodos/portada.do) y escribe:
*
*   1. pe-data.json    (esquema ciep.micrositio.pe/v1) — lo consume
*                      wp-content/pe-charts/pe-charts.js (ApexCharts)
*   2. pe-ingresos.csv (datos abiertos, formato largo)
*   3. pe-gasto.csv    (datos abiertos, formato largo)
*
* Sustituye los datos PRELIMINARES transcritos a mano de las imágenes
* ingresosdivPEPIB-1.png / gastosdivCIEPPIB-2.png (pe-data.js, 2026-08-28).
*
* AÑO MÁXIMO: min(anioPE, último año con filas en master/LIF.dta y
* master/PEF.dta). Cuando el PPEF del año siguiente entre al motor
* (UpdateLIF/UpdatePEF + anioPE en profile.do), re-correr este driver
* extiende las gráficas SIN tocar la página.
*
* DÓNDE VIVE CADA COSA (mismo patrón que portada.do)
*   FUENTE (versionada, aquí): 01_modulos/nodos/micrositio-pe.do
*   SALIDA (generada, desechable):
*     CIEP_Micrositios/Paquete Económico/public_html/wp-content/pe-charts/
*       pe-data.json  pe-ingresos.csv  pe-gasto.csv
*   Override de destino: global pe_charts_dir
*
* USO:  do "`c(sysdir_site)'/01_modulos/nodos/micrositio-pe.do"
* Requiere: aniovp y anioPE (profile.do), master/ poblado, LIF y PEF
* invocables. Tiempo esperado: ~2-3 min (PEF ~9 s por año).

*** 0 PRELIMINARES ***
local site `"`c(sysdir_site)'"'

capture confirm scalar aniovp
if _rc {
	di as err "micrositio-pe: falta scalar aniovp (lo fija profile.do). No se exporta."
	exit 198
}
capture confirm scalar anioPE
if _rc {
	di as err "micrositio-pe: falta scalar anioPE (lo fija profile.do). No se exporta."
	exit 198
}
local aniomin = 2013
local aniope = scalar(anioPE)

local pecharts `"`site'/../CIEP_Micrositios/Paquete Económico/public_html/wp-content/pe-charts"'
if `"$pe_charts_dir"' != "" {
	local pecharts `"$pe_charts_dir"'
}

*** 1 AÑO MÁXIMO CON DATOS + TIPO DE DATO POR AÑO Y POR LADO ***
* (leído de los datos, mismo criterio que portada.do §1) *
preserve
quietly use anio ejercido aprobado proyecto using `"`site'/master/PEF.dta"', clear
quietly summarize anio, meanonly
local maxpef = r(max)
forvalues y = `aniomin'/`aniope' {
	quietly count if anio == `y' & !missing(ejercido)
	if r(N) > 0 {
		local tg_`y' "ejercido"
	}
	else {
		quietly count if anio == `y' & !missing(aprobado)
		if r(N) > 0 {
			local tg_`y' "aprobado"
		}
		else {
			local tg_`y' "proyecto"
		}
	}
}
quietly use anio mes using `"`site'/master/LIF.dta"', clear
quietly summarize anio, meanonly
local maxlif = r(max)
* Lado ingresos: cierre observado si el año trae los 12 meses; si no, rige la
* ley. La ley es LIF (aprobada) salvo cuando el gasto del año es todavía
* PPEF (proyecto): en la ventana sep-nov del paquete, la iniciativa ILIF
* aún no se aprueba y se etiqueta como tal. *
forvalues y = `aniomin'/`aniope' {
	quietly summ mes if anio == `y' & mes != .
	if r(max) == 12 {
		local ti_`y' "observado"
	}
	else if "`tg_`y''" == "proyecto" {
		local ti_`y' "iniciativa"
	}
	else {
		local ti_`y' "ley"
	}
}
restore

local aniomax = min(`aniope', `maxpef', `maxlif')
if `aniomax' < `aniope' {
	noisily di in g "micrositio-pe: anioPE = " in y `aniope' in g " pero el último año con datos en master/ es " in y `aniomax' in g "."
	noisily di in g "  Se exporta hasta `aniomax'. Al cargar el paquete `aniope' al motor, re-correr este driver."
}

*** 2 BLUEPRINTS (espejo EXACTO de los displays del motor; orden = display de la gráfica) ***
* Ingresos: las 7 familias del display B de LIF.ado + la familia Deuda
* (escalar DeudaPIB del display A por divPE), en el orden de la gráfica. *
local ing_n = 8
local ing_etq_1 "ISR"
local ing_esc_1 "ISR"
local ing_etq_2 "Energía"
local ing_esc_2 "Energía"
local ing_etq_3 "IVA"
local ing_esc_3 "IVA"
local ing_etq_4 "Deuda"
local ing_esc_4 "Deuda"
local ing_etq_5 "No tributarios"
local ing_esc_5 "No_tributarios"
local ing_etq_6 "IEPS"
local ing_esc_6 "IEPS"
local ing_etq_7 "IMSS e ISSSTE"
local ing_esc_7 "IMSS_e_ISSSTE"
local ing_etq_8 "Otros tributarios"
local ing_esc_8 "Otros_tributarios"

local gas_n = 10
local gas_etq_1  "Cuotas ISSSTE"
local gas_ret_1  "Cuotas_ISSSTE"
local gas_etq_2  "Energía"
local gas_ret_2  "Energia"
local gas_etq_3  "Pensiones"
local gas_ret_3  "Pensiones"
local gas_etq_4  "Federalizado"
local gas_ret_4  "Federalizado"
local gas_etq_5  "Educación"
local gas_ret_5  "Educacion"
local gas_etq_6  "Salud"
local gas_ret_6  "Salud"
local gas_etq_7  "Otros gastos"
local gas_ret_7  "Otros_gastos"
local gas_etq_8  "Costo de la deuda"
local gas_ret_8  "Costo_de_la_deuda"
local gas_etq_9  "Otras inversiones"
local gas_ret_9  "Otras_inversiones"
local gas_etq_10 "Pensión AM"
local gas_ret_10 "Pension_AM"

*** 3 CORRIDA POR AÑO: capturar las cifras del motor AL VUELO ***
* Igual que portada.do: TODO a scalars (__mp*) inmediatamente después de
* cada llamada (los escalares de LIF se pisan por año; los r() de PEF
* mueren con el siguiente comando r-class). MONTOS en millones de MXN
* ENTEROS (round(x/1e6)): los centavos de Cuenta Pública no son
* bit-estables entre corridas. *
forvalues y = `aniomin'/`aniomax' {

	quietly LIF, anio(`y') nographs

	forvalues i = 1/`ing_n' {
		capture confirm scalar `ing_esc_`i''PIB
		if _rc {
			di as err "micrositio-pe: LIF `y' no registró el escalar `ing_esc_`i''PIB. El censo de familias cambió; actualiza el blueprint."
			exit 459
		}
		scalar __mpI`y'_`i'  = scalar(`ing_esc_`i''PIB)
		scalar __mpIM`y'_`i' = round(scalar(`ing_esc_`i'')/1e6)
	}

	quietly PEF, anio(`y') nographs

	tempname gasPIB
	scalar `gasPIB' = 0
	forvalues i = 1/`gas_n' {
		if r(`gas_ret_`i''PIB) == . {
			di as err "micrositio-pe: PEF `y' no retornó r(`gas_ret_`i''PIB). El censo de divisiones cambió; actualiza el blueprint."
			exit 459
		}
		scalar __mpG`y'_`i'  = r(`gas_ret_`i''PIB)
		scalar __mpGM`y'_`i' = round(r(`gas_ret_`i'')/1e6)
		scalar `gasPIB' = `gasPIB' + r(`gas_ret_`i''PIB)
	}
	if abs(`gasPIB' - r(Gasto_netoPIB)) > 1e-6 {
		di as err "micrositio-pe: la suma de divisiones de `y' (" scalar(`gasPIB') ") no cuadra con r(Gasto_netoPIB) (" r(Gasto_netoPIB) "). No se exporta."
		exit 459
	}
}

*** 3.5 DEFLACTOR (poder adquisitivo INPC, base = aniomax) ***
* Misma convención que las series reales del motor (LIF.ado:recaudacionR y
* los crecimientos "C" de PEF.ado): deflatorpp = inpc/inpc[base]. La página
* lo usa para convertir mdp corrientes a MXN constantes de `aniomax' y
* desplegar crecimientos REALES año contra año. *
quietly PIBDeflactor, anio(`aniomax') nographs nooutput
forvalues y = `aniomin'/`aniomax' {
	quietly summ deflatorpp if anio == `y', meanonly
	if r(N) == 0 {
		di as err "micrositio-pe: PIBDeflactor no trae deflatorpp para `y'. No se exporta."
		exit 459
	}
	scalar __mpDEF`y' = r(mean)
}

*** 4 PROCEDENCIA (espejo de portada.do: manifest + log basename) ***
local mversion ""
local mcorte ""
local faltantes ""
local manifest `"`site'/05_scripts/manifest.json"'
capture confirm file `"`manifest'"'
if _rc == 0 {
	tempname mh
	file open `mh' using `"`manifest'"', read text
	file read `mh' mline
	while r(eof) == 0 {
		if regexm(`"`mline'"', `""version"[ ]*:[ ]*"([^"]*)""') & "`mversion'" == "" {
			local mversion = regexs(1)
		}
		if regexm(`"`mline'"', `""data_updated"[ ]*:[ ]*"([^"]*)""') & "`mcorte'" == "" {
			local mcorte = regexs(1)
		}
		file read `mh' mline
	}
	file close `mh'
}
if "`mversion'" == "" local faltantes "`faltantes' procedencia.version_simulador"
if "`mcorte'"   == "" local faltantes "`faltantes' procedencia.corte_datos"

local logfile ""
capture quietly log query
local lf `"`r(filename)'"'
if `"`lf'"' != "" & `"`lf'"' != "." {
	local logfile = substr(`"`lf'"', length(`"`lf'"') - strpos(reverse(`"`lf'"'), "/") + 2, .)
}
if `"`logfile'"' == "" local faltantes "`faltantes' procedencia.log"

*** 5 EMISORES LOCALES (espejo de portada.do; misma decisión de precisión) ***
* _mjpib %16.9g para % del PIB (los agregados de LIF/PEF no son bit-estables
* al último ulp); _mjnum %25.17g para montos ya redondeados a enteros. *
capture program drop _mjnum
program define _mjnum, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	capture local s = trim(string(`e', "%25.17g"))
	if _rc exit
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end
capture program drop _mjpib
program define _mjpib, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	capture local s = trim(string(`e', "%16.9g"))
	if _rc exit
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end
capture program drop _mjesc
program define _mjesc, rclass
	args s
	local s = subinstr(`"`s'"', char(96), "", .)
	local s = subinstr(`"`s'"', char(92), char(92) + char(92), .)
	local s = subinstr(`"`s'"', char(34), char(92) + char(34), .)
	return local s `"`s'"'
end

*** 6 ESCRITURA: pe-data.json ***
capture mkdir `"`pecharts'"'
local q = char(34)
local pe = trim("$paqueteEconomico")
_mjesc `"`pe'"'
local pee `"`r(s)'"'

tempname fh
file open `fh' using `"`pecharts'/pe-data.json"', write replace text

file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'ciep.micrositio.pe/v1`q',"' _n
file write `fh' `"  `q'titulo`q': `q'Paquete Económico `aniomax'`q',"' _n
file write `fh' `"  `q'paquete`q': `q'`pee'`q',"' _n
file write `fh' `"  `q'anio_default`q': `aniomax',"' _n
local anioslist ""
forvalues y = `aniomin'/`aniomax' {
	local anioslist "`anioslist'`y'`=cond(`y' < `aniomax', ", ", "")'"
}
file write `fh' `"  `q'anios`q': [`anioslist'],"' _n

* --- tipo de dato por año y por lado --- *
file write `fh' `"  `q'tipo_dato`q': {"' _n
forvalues y = `aniomin'/`aniomax' {
	file write `fh' `"    `q'`y'`q': {`q'ingresos`q': `q'`ti_`y''`q', `q'gasto`q': `q'`tg_`y''`q'}`=cond(`y' < `aniomax', ",", "")'"' _n
}
file write `fh' "  }," _n
file write `fh' `"  `q'tipo_dato_leyenda`q': {`q'ejercido`q': `q'Cuenta Pública (gasto ejercido)`q', `q'aprobado`q': `q'PEF aprobado`q', `q'proyecto`q': `q'PPEF (proyecto)`q', `q'observado`q': `q'recaudación observada al cierre`q', `q'ley`q': `q'Ley de Ingresos (LIF)`q', `q'iniciativa`q': `q'Iniciativa de Ley de Ingresos (ILIF)`q'},"' _n

* --- unidades --- *
file write `fh' `"  `q'unidades`q': {`q'pib`q': `q'% del PIB del año propio`q', `q'mdp`q': `q'millones de MXN corrientes del año propio (redondeados a enteros)`q', `q'mdp_real`q': `q'millones de MXN constantes de `aniomax' (mdp / deflactor)`q'},"' _n

* --- deflactor (poder adquisitivo INPC, base = aniomax) --- *
local defs ""
forvalues y = `aniomin'/`aniomax' {
	local sep = cond(`y' < `aniomax', ", ", "")
	_mjnum __mpDEF`y'
	local defs "`defs'`r(n)'`sep'"
}
file write `fh' `"  `q'deflactor`q': {`q'base`q': `aniomax', `q'fuente`q': `q'PIBDeflactor.ado — deflatorpp (INPC, poder adquisitivo), misma convención que las series reales de LIF/PEF`q', `q'valores`q': [`defs']},"' _n

* --- bloque de series: ingresos y gasto --- *
foreach lado in ing gas {
	if "`lado'" == "ing" {
		file write `fh' `"  `q'ingresos`q': {"' _n
		file write `fh' `"    `q'titulo`q': `q'Ingresos presupuestarios`q',"' _n
		file write `fh' `"    `q'fuente`q': `q'LIF.ado — familias del display por divPE (la familia Deuda es el financiamiento de la LIF)`q',"' _n
		local n = `ing_n'
	}
	else {
		file write `fh' `"  `q'gasto`q': {"' _n
		file write `fh' `"    `q'titulo`q': `q'Gasto público`q',"' _n
		file write `fh' `"    `q'fuente`q': `q'PEF.ado — divisiones del display B (Resumido, divCIEP); Cuotas ISSSTE resta como en el motor`q',"' _n
		local n = `gas_n'
	}
	file write `fh' `"    `q'series`q': ["' _n
	forvalues i = 1/`n' {
		if "`lado'" == "ing" {
			_mjesc `"`ing_etq_`i''"'
			local e `"`r(s)'"'
			local ref "`ing_esc_`i''PIB"
			local P "I"
		}
		else {
			_mjesc `"`gas_etq_`i''"'
			local e `"`r(s)'"'
			local ref "r(`gas_ret_`i''PIB)"
			local P "G"
		}
		local pibs ""
		local mdps ""
		forvalues y = `aniomin'/`aniomax' {
			local sep = cond(`y' < `aniomax', ", ", "")
			_mjpib __mp`P'`y'_`i'
			local pibs "`pibs'`r(n)'`sep'"
			_mjnum __mp`P'M`y'_`i'
			local mdps "`mdps'`r(n)'`sep'"
		}
		file write `fh' `"      {`q'name`q': `q'`e'`q', `q'origen`q': `q'`ref'`q', `q'pib`q': [`pibs'], `q'mdp`q': [`mdps']}`=cond(`i' < `n', ",", "")'"' _n
	}
	file write `fh' "    ]" _n
	file write `fh' "  }," _n
}

* --- descargas (datos abiertos) --- *
file write `fh' `"  `q'descargas`q': {`q'ingresos`q': `q'pe-ingresos.csv`q', `q'gasto`q': `q'pe-gasto.csv`q'},"' _n

* --- procedencia y sello (generado_en AL FINAL, aislado) --- *
file write `fh' `"  `q'procedencia`q': {"' _n
_mjesc `"`mversion'"'
file write `fh' `"    `q'version_simulador`q': `q'`r(s)'`q',"' _n
_mjesc `"`mcorte'"'
file write `fh' `"    `q'corte_datos`q': `q'`r(s)'`q',"' _n
_mjesc `"`logfile'"'
file write `fh' `"    `q'log`q': `q'`r(s)'`q',"' _n
file write `fh' `"    `q'origen`q': `q'LIF.ado + PEF.ado via 01_modulos/nodos/micrositio-pe.do`q',"' _n
file write `fh' `"    `q'generado_en`q': `q'`c(current_date)'T`c(current_time)'`q'"' _n
file write `fh' "  }," _n

local faltantes = trim("`faltantes'")
local flist ""
local nfal : word count `faltantes'
local i = 0
foreach f of local faltantes {
	local i = `i' + 1
	local flist `"`flist'`q'`f'`q'`=cond(`i' < `nfal', ", ", "")'"'
}
file write `fh' `"  `q'faltantes`q': [`flist']"' _n
file write `fh' "}" _n
file close `fh'

noisily di in g "micrositio-pe: contrato escrito -> " in y `"`pecharts'/pe-data.json"'

*** 7 ESCRITURA: CSVs de datos abiertos (formato largo) ***
preserve
quietly {
	clear
	local nyears = `aniomax' - `aniomin' + 1
	set obs `=`ing_n'*`nyears''
	g int anio = .
	g str40 componente = ""
	g double pct_pib = .
	g double mdp = .
	g double mdp_real`aniomax' = .
	g str12 tipo_dato = ""
	local r = 0
	forvalues i = 1/`ing_n' {
		forvalues y = `aniomin'/`aniomax' {
			local ++r
			replace anio = `y' in `r'
			replace componente = `"`ing_etq_`i''"' in `r'
			replace pct_pib = scalar(__mpI`y'_`i') in `r'
			replace mdp = scalar(__mpIM`y'_`i') in `r'
			replace mdp_real`aniomax' = round(scalar(__mpIM`y'_`i')/scalar(__mpDEF`y')) in `r'
			replace tipo_dato = "`ti_`y''" in `r'
		}
	}
	format pct_pib %9.3f
	format mdp mdp_real`aniomax' %14.0f
	export delimited using `"`pecharts'/pe-ingresos.csv"', replace datafmt

	clear
	set obs `=`gas_n'*`nyears''
	g int anio = .
	g str40 componente = ""
	g double pct_pib = .
	g double mdp = .
	g double mdp_real`aniomax' = .
	g str12 tipo_dato = ""
	local r = 0
	forvalues i = 1/`gas_n' {
		forvalues y = `aniomin'/`aniomax' {
			local ++r
			replace anio = `y' in `r'
			replace componente = `"`gas_etq_`i''"' in `r'
			replace pct_pib = scalar(__mpG`y'_`i') in `r'
			replace mdp = scalar(__mpGM`y'_`i') in `r'
			replace mdp_real`aniomax' = round(scalar(__mpGM`y'_`i')/scalar(__mpDEF`y')) in `r'
			replace tipo_dato = "`tg_`y''" in `r'
		}
	}
	format pct_pib %9.3f
	format mdp mdp_real`aniomax' %14.0f
	export delimited using `"`pecharts'/pe-gasto.csv"', replace datafmt
}
restore

noisily di in g "micrositio-pe: datos abiertos -> " in y `"`pecharts'/pe-ingresos.csv"' in g " y " in y `"`pecharts'/pe-gasto.csv"'

*** 8 LIMPIEZA de los escalares de captura (__mp*) ***
forvalues y = `aniomin'/`aniomax' {
	capture scalar drop __mpDEF`y'
	forvalues i = 1/`ing_n' {
		capture scalar drop __mpI`y'_`i'
		capture scalar drop __mpIM`y'_`i'
	}
	forvalues i = 1/`gas_n' {
		capture scalar drop __mpG`y'_`i'
		capture scalar drop __mpGM`y'_`i'
	}
}
