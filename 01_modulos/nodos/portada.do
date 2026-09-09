*! portada.do  v2.0.0 — driver de la portada del Paquete (ecuación fundamental, multi-año)
*
* QUÉ ES ESTO
* El driver de la portada: corre los módulos de ingresos (LIF) y gasto (PEF)
* del motor PARA CADA AÑO 2013-<aniovp>, toma las cifras que ELLOS producen,
* deriva los tres totales de la ecuación fundamental por año y escribe el
* contrato statajson_portada.json (esquema ciep.nodo.portada/v1, multi-año).
*
*   GASTO NETO  =  INGRESOS (sin deuda)  +  FINANCIAMIENTO      (por año)
*
* TIEMPO ESPERADO DE CORRIDA: ~2 minutos (PEF tarda ~8.6 s por año sobre
* master/PEF.dta de 3.4M filas; LIF es despreciable). La regla 3 del
* verificador corre el driver DOS veces: ~5 minutos. No está colgado.
*
* ESQUEMA ciep.nodo.portada/v1 — decisión de versionado (2026-08-02):
* el multi-año extiende el bloque `ecuacion` único a `ecuaciones` por año
* SIN subir a v2: el contrato es pre-publicación y no tiene consumidor
* externo. v2 solo cuando exista consumidor externo publicado.
*
* Es el ÚNICO lugar donde la portada calcula algo, y calcula exactamente
* tres cosas POR AÑO, las tres sumas declaradas en la orden de trabajo:
*   1. ingresos  = suma de las 7 familias del display B de LIF.ado
*                  (divResumido: las familias SIN la familia Deuda)
*   2. gasto     = suma de las 10 divisiones del display B de PEF.ado
*                  (Resumido: incluye la resta de Cuotas ISSSTE, como el
*                  display del motor) — verificada contra r(Gasto_netoPIB)
*   3. financiamiento = gasto - ingresos (cierre por construcción)
* La familia "Deuda" de la LIF se declara como REFERENCIA con su brecha
* contra el cierre: son dos medidas del mismo término y no coinciden al
* centavo; la brecha viaja declarada en el JSON en lugar de esconderse.
*
* TIPO DE DATO por año Y POR LADO, leído de los datos (no de una tabla
* tecleada):
*   gasto:    la regla del motor (PEF.ado:1295-97) es ejercido si existe,
*             si no aprobado, si no proyecto. Se lee de master/PEF.dta qué
*             columna trae datos cada año.
*   ingresos: master/LIF.dta trae por año 54 filas observadas (mes
*             acumulado) y 10 filas de ley (ILIF). Años con mes máximo 12
*             = cierre observado; con mes máximo < 12 el display del motor
*             usa la ley -> "ley".
*
* DÓNDE VIVE CADA COSA (mismo patrón que nodo-deuda.do)
*   FUENTE (versionada, aquí):  01_modulos/nodos/portada.do
*                               01_modulos/nodos/portada.html
*   SALIDA (ignorada, generada):
*     CIEP_Micrositios/Paquete Económico/public_html/nodos/statajson_portada.json
*     CIEP_Micrositios/Paquete Económico/public_html/nodos/index.html (copia servible)
* La copia servible se llama index.html a propósito: /nodos/ ES la portada.
*
* CAPA CGPE (patrón del nodo de deuda): SOLO para el año de referencia
* (aniovp), y solo si los globals de política fiscal de SIM.do están
* cargados; sin ellos la capa sale disponible:false. Los demás años no
* llevan capa: el CGPE es la proyección del paquete vigente, no un dato
* histórico por año.
*
* USO:  do "`c(sysdir_site)'/01_modulos/nodos/portada.do"
* Requiere: aniovp (profile.do), master/ poblado, LIF y PEF invocables.
* Override de destino para verify_nodo.sh (regla 3): global nodo_saving.

*** 0 PRELIMINARES ***
local site `"`c(sysdir_site)'"'

capture confirm scalar aniovp
if _rc {
	di as err "portada: falta scalar aniovp (lo fija profile.do). No se exporta."
	exit 198
}
local anioref = scalar(aniovp)
local aniomin = 2013
* Censo 2026-08-02: los 14 años 2013-2026 corren completos con etiquetas
* estables (7 familias, 10 divisiones idénticas). Si un año nuevo cojea,
* los guards de abajo abortan en vez de exportar un hueco en silencio.

*** 1 TIPO DE DATO POR AÑO Y POR LADO (leído de los datos) ***
preserve
quietly use anio ejercido aprobado proyecto using `"`site'/master/PEF.dta"', clear
forvalues y = `aniomin'/`anioref' {
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
forvalues y = `aniomin'/`anioref' {
	quietly summ mes if anio == `y' & mes != .
	local ti_`y' = cond(r(max) == 12, "observado", "ley")
}
restore

*** 2 BLUEPRINTS (espejo EXACTO de los displays B; el display ES la spec) ***
local ing_n = 7
local ing_etq_1 "Energía"
local ing_esc_1 "Energía"
local ing_etq_2 "IEPS"
local ing_esc_2 "IEPS"
local ing_etq_3 "IMSS e ISSSTE"
local ing_esc_3 "IMSS_e_ISSSTE"
local ing_etq_4 "ISR"
local ing_esc_4 "ISR"
local ing_etq_5 "IVA"
local ing_esc_5 "IVA"
local ing_etq_6 "No tributarios"
local ing_esc_6 "No_tributarios"
local ing_etq_7 "Otros tributarios"
local ing_esc_7 "Otros_tributarios"

local gas_n = 10
local gas_etq_1  "Costo de la deuda"
local gas_ret_1  "Costo_de_la_deuda"
local gas_etq_2  "Cuotas ISSSTE"
local gas_ret_2  "Cuotas_ISSSTE"
local gas_etq_3  "Educación"
local gas_ret_3  "Educacion"
local gas_etq_4  "Energía"
local gas_ret_4  "Energia"
local gas_etq_5  "Federalizado"
local gas_ret_5  "Federalizado"
local gas_etq_6  "Otras inversiones"
local gas_ret_6  "Otras_inversiones"
local gas_etq_7  "Otros gastos"
local gas_ret_7  "Otros_gastos"
local gas_etq_8  "Pensiones"
local gas_ret_8  "Pensiones"
local gas_etq_9  "Pensión AM"
local gas_ret_9  "Pension_AM"
local gas_etq_10 "Salud"
local gas_ret_10 "Salud"

*** 3 CORRIDA POR AÑO: capturar las cifras del motor AL VUELO ***
* Los escalares de LIF se pisan en cada año (last wins) y los r() de PEF
* mueren con el siguiente comando r-class: TODO se copia a locales por año
* inmediatamente después de cada llamada. *
* TODO se captura en SCALARS (__prt*), nunca en locals: `local x = exp'
* guarda el resultado como texto con menos dígitos y el cierre por
* construcción pierde los centavos (la regla 4 lo cazó: residuos de 1e-4
* pesos). Los MONTOS se publican en MILLONES de MXN ENTEROS (round(x/1e6)):
* los montos de Cuenta Pública traen centavos y NO son bit-estables entre
* corridas (mismo ruido de ordenamiento que el ulp de los % PIB); el
* millón entero está 6 órdenes por encima del ruido y el financiamiento
* se deriva DESPUÉS del redondeo, así que el cierre en montos es EXACTO
* en enteros. *
forvalues y = `aniomin'/`anioref' {

	quietly LIF, anio(`y') nographs

	tempname ingPIB ingMXN
	scalar `ingPIB' = 0
	scalar `ingMXN' = 0
	forvalues i = 1/`ing_n' {
		capture confirm scalar `ing_esc_`i''PIB
		if _rc {
			di as err "portada: LIF `y' no registró el escalar `ing_esc_`i''PIB. El censo de familias cambió; actualiza el blueprint."
			exit 459
		}
		scalar __prtI`y'_`i'  = scalar(`ing_esc_`i''PIB)
		scalar __prtIM`y'_`i' = round(scalar(`ing_esc_`i'')/1e6)
		scalar `ingPIB' = `ingPIB' + scalar(`ing_esc_`i''PIB)
		scalar `ingMXN' = `ingMXN' + scalar(`ing_esc_`i'')
	}
	capture confirm scalar DeudaPIB
	if _rc {
		di as err "portada: LIF `y' no registró DeudaPIB (familia Deuda de divPE)."
		exit 459
	}
	scalar __prtDL`y'  = scalar(DeudaPIB)
	scalar __prtIT`y'  = `ingPIB'
	scalar __prtITM`y' = round(`ingMXN'/1e6)

	quietly PEF, anio(`y') nographs

	tempname gasPIB gasMXN
	scalar `gasPIB' = 0
	scalar `gasMXN' = 0
	forvalues i = 1/`gas_n' {
		if r(`gas_ret_`i''PIB) == . {
			di as err "portada: PEF `y' no retornó r(`gas_ret_`i''PIB). El censo de divisiones cambió; actualiza el blueprint."
			exit 459
		}
		scalar __prtG`y'_`i'  = r(`gas_ret_`i''PIB)
		scalar __prtGM`y'_`i' = round(r(`gas_ret_`i'')/1e6)
		scalar `gasPIB' = `gasPIB' + r(`gas_ret_`i''PIB)
		scalar `gasMXN' = `gasMXN' + r(`gas_ret_`i'')
	}
	if abs(`gasPIB' - r(Gasto_netoPIB)) > 1e-6 {
		di as err "portada: la suma de divisiones de `y' (" scalar(`gasPIB') ") no cuadra con r(Gasto_netoPIB) (" r(Gasto_netoPIB) "). No se exporta."
		exit 459
	}
	scalar __prtGT`y'  = `gasPIB'
	scalar __prtGTM`y' = round(`gasMXN'/1e6)

	* cierre por construcción (montos: DESPUÉS del redondeo -> exacto en
	* enteros) y brecha contra la familia Deuda de la LIF *
	scalar __prtFT`y'  = __prtGT`y' - __prtIT`y'
	scalar __prtFTM`y' = __prtGTM`y' - __prtITM`y'
	scalar __prtBR`y'  = __prtFT`y' - __prtDL`y'
}

*** 4 CAPA CGPE (solo año de referencia; declarada, jamás mezclada) ***
local cgpe_disp "false"
local cgpe_rfsp "null"
local cgpe_ing  "null"
local cgpe_gas  "null"
capture confirm existence ${rfsp`anioref'}
if _rc == 0 {
	local cgpe_disp "true"
	local cgpe_rfsp = ${rfsp`anioref'}
	capture confirm existence ${ingresos`anioref'}
	if _rc == 0 local cgpe_ing = ${ingresos`anioref'}
	capture confirm existence ${egresos`anioref'}
	if _rc == 0 local cgpe_gas = ${egresos`anioref'}
}

*** 5 PROCEDENCIA (espejo de scalarjson: manifest + log basename) ***
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
if "`cgpe_disp'" == "false" local faltantes "`faltantes' capa.escenario_cgpe"

*** 6 ESCRITURA DEL CONTRATO ***
* Mini-emisores locales (espejo de _sjnum/_sjesc de scalarjson.ado; se
* definen aquí porque scalarjson no exporta este esquema y sus helpers no
* existen si scalarjson no ha corrido).
* PRECISIÓN, dos emisores — decisión documentada:
*   _pjnum  %25.17g  para MONTOS: ya redondeados a MILLONES ENTEROS en la
*                    captura (los montos de Cuenta Pública traen centavos y
*                    no son bit-estables); un entero en double viaja exacto.
*   _pjpib  %16.9g   para % del PIB: los agregados de LIF/PEF no son
*                    bit-estables entre corridas (los sort con empates no
*                    son estables y el orden de la suma mueve el último ulp
*                    del double — la regla 3 del verificador lo cazó en la
*                    primera corrida doble, y con 12 dígitos el margen
*                    seguía siendo delgado). 9 dígitos significativos dejan
*                    ~5 órdenes de margen sobre el ruido y siguen MUY por
*                    encima del display (3 decimales): se publica el dato,
*                    no el ruido. El nodo de deuda sí usa %25.17g en todo
*                    porque lee un .dta congelado, que es bit-estable. *
capture program drop _pjnum
program define _pjnum, rclass
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
capture program drop _pjpib
program define _pjpib, rclass
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
capture program drop _pjesc
program define _pjesc, rclass
	args s
	local s = subinstr(`"`s'"', char(96), "", .)
	local s = subinstr(`"`s'"', char(92), char(92) + char(92), .)
	local s = subinstr(`"`s'"', char(34), char(92) + char(34), .)
	return local s `"`s'"'
end

local saving `"`site'/../CIEP_Micrositios/Paquete Económico/public_html/nodos/statajson_portada.json"'
if `"$nodo_saving"' != "" {
	local saving `"$nodo_saving"'
}
else {
	capture mkdir `"`site'/../CIEP_Micrositios/Paquete Económico/public_html/nodos"'
}

local q = char(34)
tempname fh
file open `fh' using `"`saving'"', write replace text

file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'ciep.nodo.portada/v1`q',"' _n
file write `fh' `"  `q'nodo`q': `q'portada`q',"' _n
file write `fh' `"  `q'titulo`q': `q'Paquete Económico`q',"' _n
file write `fh' `"  `q'anio_default`q': `anioref',"' _n
local anioslist ""
forvalues y = `aniomin'/`anioref' {
	local anioslist "`anioslist'`y'`=cond(`y' < `anioref', ", ", "")'"
}
file write `fh' `"  `q'anios`q': [`anioslist'],"' _n

* --- presentación común de la ecuación --- *
file write `fh' `"  `q'presentacion`q': {"' _n
file write `fh' `"    `q'regla`q': `q'gasto = ingresos + financiamiento`q',"' _n
file write `fh' `"    `q'unidad_pib`q': `q'% del PIB del año propio`q',"' _n
file write `fh' `"    `q'unidad_monto`q': `q'millones de MXN corrientes del año propio (redondeados a enteros)`q',"' _n
file write `fh' `"    `q'formato_pib`q': `q'%7.1f`q',"' _n
file write `fh' `"    `q'formato_pib_detalle`q': `q'%7.3f`q',"' _n
file write `fh' `"    `q'formato_monto`q': `q'%12.0fc`q',"' _n
file write `fh' `"    `q'fuente_gasto`q': `q'PEF.ado — gasto neto: suma de las divisiones del display B (Resumido); verificada contra r(Gasto_netoPIB)`q',"' _n
file write `fh' `"    `q'fuente_ingresos`q': `q'LIF.ado — suma de las familias del display B (divResumido, sin la familia Deuda)`q',"' _n
file write `fh' `"    `q'fuente_financiamiento`q': `q'cierre por construcción: gasto - ingresos (derivado en 01_modulos/nodos/portada.do)`q',"' _n
file write `fh' `"    `q'nota_referencia_lif`q': `q'La familia Deuda de la LIF es otra medida del mismo término; la brecha contra el cierre viaja declarada.`q',"' _n
file write `fh' `"    `q'tipo_dato_leyenda`q': {`q'ejercido`q': `q'Cuenta Pública (gasto ejercido)`q', `q'aprobado`q': `q'PEF aprobado`q', `q'proyecto`q': `q'PPEF proyecto`q', `q'observado`q': `q'recaudación observada al cierre`q', `q'ley`q': `q'Ley de Ingresos (ILIF)`q'}"' _n
file write `fh' "  }," _n

* --- ecuaciones por año --- *
file write `fh' `"  `q'ecuaciones`q': ["' _n
forvalues y = `aniomin'/`anioref' {
	file write `fh' "    {" _n
	file write `fh' `"      `q'anio`q': `y',"' _n
	file write `fh' `"      `q'tipo_dato`q': {`q'gasto`q': `q'`tg_`y''`q', `q'ingresos`q': `q'`ti_`y''`q'},"' _n
	_pjpib __prtGT`y'
	local vg "`r(n)'"
	_pjnum __prtGTM`y'
	local mg "`r(n)'"
	_pjpib __prtIT`y'
	local vi "`r(n)'"
	_pjnum __prtITM`y'
	local mi "`r(n)'"
	_pjpib __prtFT`y'
	local vf "`r(n)'"
	_pjnum __prtFTM`y'
	local mf "`r(n)'"
	_pjpib __prtDL`y'
	local vd "`r(n)'"
	_pjpib __prtBR`y'
	local vb "`r(n)'"
	file write `fh' `"      `q'terminos`q': {"' _n
	file write `fh' `"        `q'gasto`q': {`q'etiqueta`q': `q'Gasto`q', `q'pib`q': `vg', `q'monto`q': `mg'},"' _n
	file write `fh' `"        `q'ingresos`q': {`q'etiqueta`q': `q'Ingresos`q', `q'pib`q': `vi', `q'monto`q': `mi'},"' _n
	file write `fh' `"        `q'financiamiento`q': {`q'etiqueta`q': `q'Financiamiento`q', `q'pib`q': `vf', `q'monto`q': `mf', `q'referencia_lif`q': {`q'escalar`q': `q'DeudaPIB`q', `q'pib`q': `vd', `q'brecha_pib`q': `vb'}}"' _n
	file write `fh' "      }," _n
	file write `fh' `"      `q'desagregaciones`q': {"' _n
	file write `fh' `"        `q'ingresos`q': ["' _n
	forvalues i = 1/`ing_n' {
		_pjesc `"`ing_etq_`i''"'
		local e `"`r(s)'"'
		_pjpib __prtI`y'_`i'
		local v "`r(n)'"
		_pjnum __prtIM`y'_`i'
		local m "`r(n)'"
		local coma = cond(`i' < `ing_n', ",", "")
		file write `fh' `"          {`q'etiqueta`q': `q'`e'`q', `q'escalar`q': `q'`ing_esc_`i''PIB`q', `q'pib`q': `v', `q'monto`q': `m'}`coma'"' _n
	}
	file write `fh' "        ]," _n
	file write `fh' `"        `q'gasto`q': ["' _n
	forvalues i = 1/`gas_n' {
		_pjesc `"`gas_etq_`i''"'
		local e `"`r(s)'"'
		_pjpib __prtG`y'_`i'
		local v "`r(n)'"
		_pjnum __prtGM`y'_`i'
		local m "`r(n)'"
		local coma = cond(`i' < `gas_n', ",", "")
		file write `fh' `"          {`q'etiqueta`q': `q'`e'`q', `q'retorno`q': `q'r(`gas_ret_`i''PIB)`q', `q'pib`q': `v', `q'monto`q': `m'}`coma'"' _n
	}
	file write `fh' "        ]" _n
	file write `fh' "      }" _n
	file write `fh' `"    }`=cond(`y' < `anioref', ",", "")'"' _n
}
file write `fh' "  ]," _n

* --- capa CGPE declarada (solo el año de referencia) --- *
_pjpib `cgpe_rfsp'
local cr "`r(n)'"
_pjpib `cgpe_ing'
local ci "`r(n)'"
_pjpib `cgpe_gas'
local cg "`r(n)'"
local pe = trim("$paqueteEconomico")
_pjesc `"`pe'"'
local pee `"`r(s)'"'
file write `fh' `"  `q'capas_declaradas`q': ["' _n
file write `fh' `"    {`q'id`q': `q'escenario_cgpe`q', `q'anio`q': `anioref', `q'etiqueta`q': `q'Escenario `pee': RFSP, la medida amplia oficial`q', `q'disponible`q': `cgpe_disp', `q'unidad`q': `q'% del PIB`q', `q'valores`q': {`q'rfsp`q': `cr', `q'ingresos`q': `ci', `q'gasto`q': `cg'}, `q'procedencia`q': {`q'origen`q': `q'`=cond("`cgpe_disp'"=="true","global_politica_fiscal","no_disponible")'`q', `q'definida_en`q': `q'SIM.do:361-405 (matrix rfsp/ingresos/egresos) -> global rfsp`anioref' ingresos`anioref' egresos`anioref'`q', `q'tipo_dato`q': `q'exogeno_politica_fiscal`q'}}"' _n
file write `fh' "  ]," _n

* --- el nodo que cuelga del término financiamiento --- *
file write `fh' `"  `q'nodo_deuda`q': {`q'href`q': `q'nodo-deuda.html`q', `q'contrato`q': `q'statajson_deuda-publica.json`q'},"' _n

* --- procedencia y sello (generado_en AL FINAL de su bloque, aislado) --- *
file write `fh' `"  `q'procedencia`q': {"' _n
_pjesc `"`mversion'"'
file write `fh' `"    `q'version_simulador`q': `q'`r(s)'`q',"' _n
_pjesc `"`mcorte'"'
file write `fh' `"    `q'corte_datos`q': `q'`r(s)'`q',"' _n
_pjesc `"`logfile'"'
file write `fh' `"    `q'log`q': `q'`r(s)'`q',"' _n
file write `fh' `"    `q'origen`q': `q'LIF.ado + PEF.ado via 01_modulos/nodos/portada.do`q',"' _n
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

noisily di in g "portada: contrato multi-año escrito -> " in y `"`saving'"'

* Limpieza de los escalares de captura (__prt*): son artefactos de esta
* exportación, no del registro del motor. *
forvalues y = `aniomin'/`anioref' {
	foreach p in IT ITM GT GTM FT FTM DL BR {
		capture scalar drop __prt`p'`y'
	}
	forvalues i = 1/`ing_n' {
		capture scalar drop __prtI`y'_`i'
		capture scalar drop __prtIM`y'_`i'
	}
	forvalues i = 1/`gas_n' {
		capture scalar drop __prtG`y'_`i'
		capture scalar drop __prtGM`y'_`i'
	}
}

*** 7 DESTINO SERVIBLE ***
* La copia servible se llama index.html: /nodos/ ES la portada. *
if `"$nodo_saving"' == "" {
	capture copy `"`site'/01_modulos/nodos/portada.html"' ///
		`"`site'/../CIEP_Micrositios/Paquete Económico/public_html/nodos/index.html"', replace
	if _rc {
		noisily di in g "portada: no se pudo copiar la página al destino de render."
	}
}
