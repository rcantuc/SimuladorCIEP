*! portada.do  v1.0.0 — driver de la portada del Paquete (ecuación fundamental)
*
* QUÉ ES ESTO
* El driver de la portada: corre los módulos de ingresos (LIF) y gasto (PEF)
* del motor, toma las cifras que ELLOS producen, deriva los tres totales de
* la ecuación fundamental y escribe el contrato statajson_portada.json.
*
*   GASTO NETO  =  INGRESOS (sin deuda)  +  FINANCIAMIENTO
*
* Es el ÚNICO lugar donde la portada calcula algo, y calcula exactamente
* tres cosas, las tres sumas declaradas en la orden de trabajo:
*   1. ingresos  = suma de las familias de ingreso que registra LIF.ado
*                  (divResumido: las familias SIN la familia Deuda)
*   2. gasto     = suma de las divisiones de gasto que retorna PEF.ado
*                  (Resumido: incluye la resta de Cuotas ISSSTE, como el
*                  display del motor) — verificada contra r(Gasto_netoPIB)
*   3. financiamiento = gasto - ingresos (cierre por construcción)
* La familia "Deuda" de la LIF se declara como REFERENCIA con su brecha
* contra el cierre: son dos medidas del mismo término y no coinciden al
* centavo (LIF y PEF difieren en su total); la brecha viaja declarada en el
* JSON en lugar de esconderse.
*
* DÓNDE VIVE CADA COSA (mismo patrón que nodo-deuda.do)
*   FUENTE (versionada, aquí):  01_modulos/nodos/portada.do
*                               01_modulos/nodos/portada.html
*   SALIDA (ignorada, generada):
*     04_1_paqueteeconomico.ciep.mx/public_html/nodos/statajson_portada.json
*     04_1_paqueteeconomico.ciep.mx/public_html/nodos/index.html (copia servible)
* La copia servible se llama index.html a propósito: /nodos/ ES la portada.
*
* CAPA CGPE (patrón del nodo de deuda): los globals de política fiscal de
* SIM.do (matrix rfsp/ingresos/egresos -> global rfsp2026 etc.) solo existen
* si la sesión cargó el bloque de política. Sin ellos la capa sale
* disponible:false — publicar el observado con etiqueta de escenario sería
* la costura falsa que el nodo ya vetó.
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

*** 1 INGRESOS — LIF (registra escalares por familia vía `escalar') ***
quietly LIF, anio(`anioref') nographs

* Blueprint de familias: espejo EXACTO del display B de LIF.ado ("Ingresos
* presupuestarios (divResumido)", el bloque que suma a Ingresos sin deuda).
* El display ES la especificación; si LIF cambia sus familias, el guard de
* abajo truena en vez de exportar un censo viejo en silencio.
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

tempname ingPIB ingMXN
scalar `ingPIB' = 0
scalar `ingMXN' = 0
forvalues i = 1/`ing_n' {
	capture confirm scalar `ing_esc_`i''PIB
	if _rc {
		di as err "portada: LIF no registró el escalar `ing_esc_`i''PIB. El censo de familias cambió; actualiza el blueprint."
		exit 459
	}
	scalar `ingPIB' = `ingPIB' + scalar(`ing_esc_`i''PIB)
	scalar `ingMXN' = `ingMXN' + scalar(`ing_esc_`i'')
}

* La familia Deuda de la LIF (referencia del financiamiento, NO sumada) *
capture confirm scalar DeudaPIB
if _rc {
	di as err "portada: LIF no registró DeudaPIB (familia Deuda de divPE)."
	exit 459
}

*** 2 GASTO — PEF (retorna r(); el driver los captura al vuelo) ***
quietly PEF, anio(`anioref') nographs

* Blueprint de divisiones: espejo EXACTO del display B de PEF.ado ("Gasto
* bruto (Resumido)", que suma a Gasto neto: Cuotas ISSSTE entra NEGATIVA).
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

tempname gasPIB gasMXN
scalar `gasPIB' = 0
scalar `gasMXN' = 0
forvalues i = 1/`gas_n' {
	if r(`gas_ret_`i''PIB) == . {
		di as err "portada: PEF no retornó r(`gas_ret_`i''PIB). El censo de divisiones cambió; actualiza el blueprint."
		exit 459
	}
	local gpib_`i' = r(`gas_ret_`i''PIB)
	local gmxn_`i' = r(`gas_ret_`i'')
	scalar `gasPIB' = `gasPIB' + r(`gas_ret_`i''PIB)
	scalar `gasMXN' = `gasMXN' + r(`gas_ret_`i'')
}

* Guard de integridad: la suma de divisiones ES el gasto neto del motor.
* Si difieren, el blueprint quedó viejo o PEF cambió su agregación. *
if abs(`gasPIB' - r(Gasto_netoPIB)) > 1e-6 {
	di as err "portada: la suma de divisiones (" scalar(`gasPIB') ") no cuadra con r(Gasto_netoPIB) (" r(Gasto_netoPIB) "). No se exporta."
	exit 459
}

*** 3 FINANCIAMIENTO — cierre por construcción ***
tempname finPIB finMXN brechaPIB
scalar `finPIB' = `gasPIB' - `ingPIB'
scalar `finMXN' = `gasMXN' - `ingMXN'
scalar `brechaPIB' = `finPIB' - scalar(DeudaPIB)

*** 4 CAPA CGPE (declarada, jamás mezclada con el universo del motor) ***
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
*   _pjnum  %25.17g  para MONTOS: son enteros exactos en double (muy por
*                    debajo de 2^53), el orden de la suma no los mueve.
*   _pjpib  %20.12g  para % del PIB: los agregados de LIF/PEF no son
*                    bit-estables entre corridas (los sort con empates no
*                    son estables y el orden de la suma mueve el último ulp
*                    del double — la regla 3 del verificador lo cazó en la
*                    primera corrida doble). 12 dígitos significativos están
*                    MUY por encima del display (3 decimales) y por debajo
*                    del ruido de ulp (~dígito 16): se publica el dato, no
*                    el ruido. El nodo de deuda sí usa %25.17g en todo
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
	capture local s = trim(string(`e', "%20.12g"))
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

local saving `"`site'/04_1_paqueteeconomico.ciep.mx/public_html/nodos/statajson_portada.json"'
if `"$nodo_saving"' != "" {
	local saving `"$nodo_saving"'
}
else {
	capture mkdir `"`site'/04_1_paqueteeconomico.ciep.mx/public_html/nodos"'
}

local q = char(34)
tempname fh
file open `fh' using `"`saving'"', write replace text

file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'ciep.nodo.portada/v1`q',"' _n
file write `fh' `"  `q'nodo`q': `q'portada`q',"' _n
file write `fh' `"  `q'titulo`q': `q'Paquete Económico`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n

* --- ecuación --- *
file write `fh' `"  `q'ecuacion`q': {"' _n
file write `fh' `"    `q'regla`q': `q'gasto = ingresos + financiamiento`q',"' _n
file write `fh' `"    `q'unidad_pib`q': `q'% del PIB`q',"' _n
file write `fh' `"    `q'unidad_monto`q': `q'MXN corrientes`q',"' _n
file write `fh' `"    `q'formato_pib`q': `q'%7.1f`q',"' _n
file write `fh' `"    `q'formato_pib_detalle`q': `q'%7.3f`q',"' _n
file write `fh' `"    `q'formato_monto`q': `q'%20.0fc`q',"' _n
file write `fh' `"    `q'terminos`q': {"' _n
_pjpib scalar(`gasPIB')
local vg "`r(n)'"
_pjnum scalar(`gasMXN')
local mg "`r(n)'"
file write `fh' `"      `q'gasto`q': {`q'etiqueta`q': `q'Gasto`q', `q'pib`q': `vg', `q'monto`q': `mg', `q'fuente`q': `q'PEF.ado — gasto neto: suma de las divisiones del display B (Resumido); verificada contra r(Gasto_netoPIB)`q'},"' _n
_pjpib scalar(`ingPIB')
local vi "`r(n)'"
_pjnum scalar(`ingMXN')
local mi "`r(n)'"
file write `fh' `"      `q'ingresos`q': {`q'etiqueta`q': `q'Ingresos`q', `q'pib`q': `vi', `q'monto`q': `mi', `q'fuente`q': `q'LIF.ado — suma de las familias del display B (divResumido, sin la familia Deuda)`q'},"' _n
_pjpib scalar(`finPIB')
local vf "`r(n)'"
_pjnum scalar(`finMXN')
local mf "`r(n)'"
_pjpib scalar(DeudaPIB)
local vd "`r(n)'"
_pjpib scalar(`brechaPIB')
local vb "`r(n)'"
file write `fh' `"      `q'financiamiento`q': {`q'etiqueta`q': `q'Financiamiento`q', `q'pib`q': `vf', `q'monto`q': `mf', `q'fuente`q': `q'cierre por construcción: gasto - ingresos (derivado en 01_modulos/nodos/portada.do)`q', `q'referencia_lif`q': {`q'escalar`q': `q'DeudaPIB`q', `q'pib`q': `vd', `q'brecha_pib`q': `vb', `q'nota`q': `q'La familia Deuda de la LIF es otra medida del mismo término; la brecha contra el cierre viaja declarada.`q'}}"' _n
file write `fh' "    }" _n
file write `fh' "  }," _n

* --- desagregaciones (nivel hover) --- *
file write `fh' `"  `q'desagregaciones`q': {"' _n
file write `fh' `"    `q'ingresos`q': ["' _n
forvalues i = 1/`ing_n' {
	_pjesc `"`ing_etq_`i''"'
	local e `"`r(s)'"'
	_pjpib scalar(`ing_esc_`i''PIB)
	local v "`r(n)'"
	_pjnum scalar(`ing_esc_`i'')
	local m "`r(n)'"
	local coma = cond(`i' < `ing_n', ",", "")
	file write `fh' `"      {`q'etiqueta`q': `q'`e'`q', `q'escalar`q': `q'`ing_esc_`i''PIB`q', `q'pib`q': `v', `q'monto`q': `m'}`coma'"' _n
}
file write `fh' "    ]," _n
file write `fh' `"    `q'gasto`q': ["' _n
forvalues i = 1/`gas_n' {
	_pjesc `"`gas_etq_`i''"'
	local e `"`r(s)'"'
	_pjpib `gpib_`i''
	local v "`r(n)'"
	_pjnum `gmxn_`i''
	local m "`r(n)'"
	local coma = cond(`i' < `gas_n', ",", "")
	file write `fh' `"      {`q'etiqueta`q': `q'`e'`q', `q'retorno`q': `q'r(`gas_ret_`i''PIB)`q', `q'pib`q': `v', `q'monto`q': `m'}`coma'"' _n
}
file write `fh' "    ]" _n
file write `fh' "  }," _n

* --- capa CGPE declarada --- *
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
file write `fh' `"    {`q'id`q': `q'escenario_cgpe`q', `q'etiqueta`q': `q'Escenario `pee': RFSP, la medida amplia oficial`q', `q'disponible`q': `cgpe_disp', `q'unidad`q': `q'% del PIB`q', `q'valores`q': {`q'rfsp`q': `cr', `q'ingresos`q': `ci', `q'gasto`q': `cg'}, `q'procedencia`q': {`q'origen`q': `q'`=cond("`cgpe_disp'"=="true","global_politica_fiscal","no_disponible")'`q', `q'definida_en`q': `q'SIM.do:361-405 (matrix rfsp/ingresos/egresos) -> global rfsp`anioref' ingresos`anioref' egresos`anioref'`q', `q'tipo_dato`q': `q'exogeno_politica_fiscal`q'}}"' _n
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

noisily di in g "portada: contrato escrito -> " in y `"`saving'"'

*** 7 DESTINO SERVIBLE ***
* La copia servible se llama index.html: /nodos/ ES la portada. *
if `"$nodo_saving"' == "" {
	capture copy `"`site'/01_modulos/nodos/portada.html"' ///
		`"`site'/04_1_paqueteeconomico.ciep.mx/public_html/nodos/index.html"', replace
	if _rc {
		noisily di in g "portada: no se pudo copiar la página al destino de render."
	}
}
