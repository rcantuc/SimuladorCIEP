*! contrato-32.do  v1.0 (v8.13a, 2026-10-19) — el contrato de entidad para las 32 entidades federativas
*
* QUÉ HACE (corre DENTRO de la sesión de SIM.do, con sus escalares y users/$id/aportaciones.dta
* vivos, después de §8.2; lo invoca 05_scripts/contrato-32.sh). Recorre el catálogo SIMentidad y,
* para cada entidad, produce en users/$id/<ABREV>/ lo que el motor produce para $entidad:
*   §1  Poblacion if entidad == "<nombre>"          (escalares pobtot<ABREV>…; pirámide)
*   §2  PIBDeflactor if entidad == "<nombre>"       SOLO si existe master/PIBDeflactor<ABREV>.dta
*                                                   (construirla baja series del BISE con token:
*                                                   no se hace aquí; se registra "sin base" + receta)
*   §8.2 SankeySF.do × 5 cortes (quintil estatal, grupoedad, sexo, rural, escol), con banda de
*        vintages si existen las bases users/$id-v{2016..2024}/aportaciones.dta ("" ) y sin ella ("0")
*   §8.2 CicloEntidad.do                           ciclo-vida.json
*   §4.7 TasasEfectivasEntidad.do                  tasas-efectivas.json (TasasEfectivasMicro)
*   §4b  (v8.13.0) neto del ciclo / PIBE EN STATA:  neto-pibe.json (scalarjson): NetoCicloPIBE<ABREV> =
*        NetoCiclo<ABREV> (registro de CicloEntidad.do) / pibY<ABREV> (PIBDeflactor por entidad) x 100, con
*        NetoCiclo, Aporta, Recibe, Pob y pibY de la entidad; solo si hay base PIBE. Y al final del recorrido,
*        users/$id/entidades-pibe32.json: pibYSum32 (suma de los 32 pibY<ABREV>), pibeDiscrepancia32 (% vs pibY
*        nacional) y NetoCicloPIBNac (neto nacional / PIB nacional). Es lo que la pagina /entidades/<ABREV>
*        muestra como producto 4 y la nota de la discrepancia: generar-entidades.py meta solo lo transcribe
*        (regla: ningun numero de la pagina nace fuera de Stata).
* Tolerante a fallos: cada paso va en `capture noisily`; el rc, el tiempo y la nota se registran
* por entidad en <evidencia>/contrato-32.tsv y el recorrido sigue con la siguiente. Un reporte
* parcial vale más que nada. El log de cada entidad queda en <evidencia>/entidades/<ABREV>.log.
* No toca el flujo nacional: los productos nacionales ya están escritos cuando esto corre.
*
* USO: do "${SIMROOT}/05_scripts/contrato-32.do" "<carpeta de evidencia>"
* OJO: destruye los datos en memoria.
local evidencia `"`1'"'
if `"`evidencia'"' == "" {
	di as err "contrato-32: indica la carpeta de evidencia."
	exit 198
}

* --- §4b: exportadores scalarjson (v8.13.0). Un dataset de serie de una fila (anio = aniovp) con las variables
*     canonicas que aplican (saldo_nominal = neto en pesos, saldo_pib = % del PIBE, poblacion) y los metadatos
*     minimos; los escalares viajan con su tipo del registro. Nada se calcula aqui: scalarjson solo lee. ---
* Dataset largo bloque/clave/texto para metadatos() a partir de argumentos "bloque|clave|texto" (input no lee
* lineas de datos dentro de un program; cada argumento va entre comillas y se parte por la barra). *
capture program drop _c32_metadatos
program define _c32_metadatos
	local n : word count `0'
	clear
	quietly set obs `n'
	quietly g str16 bloque = ""
	quietly g str24 clave = ""
	quietly g str244 texto = ""
	forvalues i = 1/`n' {
		local trio : word `i' of `0'
		gettoken b resto : trio, parse("|")
		gettoken bar resto : resto, parse("|")
		gettoken c resto : resto, parse("|")
		gettoken bar resto : resto, parse("|")
		quietly replace bloque = "`b'" in `i'
		quietly replace clave = "`c'" in `i'
		quietly replace texto = trim(`"`resto'"') in `i'
	}
end

capture program drop _c32_neto_pibe
program define _c32_neto_pibe
	args abrev ent
	clear
	set obs 1
	g int anio = aniovp
	g double saldo_nominal = NetoCiclo`abrev'
	g double saldo_pib = NetoCicloPIBE`abrev'
	g double poblacion = PobCiclo`abrev'
	tempfile serie
	quietly save `serie'
	_c32_metadatos ///
		"unidad|saldo_nominal|pesos corrientes de anio_vp (neto del ciclo de vida de la entidad: aporta - recibe)" ///
		"unidad|saldo_pib|% del PIBE de la entidad (anio_vp)" ///
		"unidad|poblacion|personas (factor ENIGH, residentes de la entidad)" ///
		"formato|saldo_nominal|%14.1fc" ///
		"formato|saldo_pib|%7.3fc" ///
		"formato|poblacion|%15.0fc" ///
		"divisor|saldo_nominal|1000000" ///
		"criterio|denominador_pib|PIBE de la entidad: scalar pibY<ABREV> de PIBDeflactor por entidad (base master/PIBDeflactor<ABREV>.dta, BIE 750453), anio de valor presente" ///
		"criterio|cobertura_institucional|hogares residentes en la entidad (substr(folioviv,1,2) == clave INEGI), corte por residencia del flujo nacional" ///
		"criterio|moneda_y_valuacion|pesos corrientes de anio_vp (AportacionesNetas de aportaciones.dta, Simulador.ado)" ///
		"fuente|saldo_nominal|users/<id>/<ABREV>/ciclo-vida.json totales.entidad.neto (CicloEntidad.do; registro NetoCiclo<ABREV>)" ///
		"fuente|saldo_pib|NetoCicloPIBE<ABREV> = NetoCiclo<ABREV> / pibY<ABREV> * 100 (05_scripts/contrato-32.do §4b)" ///
		"fuente|poblacion|users/<id>/<ABREV>/ciclo-vida.json totales.entidad.pob (registro PobCiclo<ABREV>)" ///
		"presentacion|entidad|`ent'" ///
		"presentacion|abrev|`abrev'"
	tempfile meta
	quietly save `meta'
	scalarjson, nodo("neto-pibe-`abrev'") titulo("Neto del ciclo de vida de `ent' como % de su PIBE") medida("saldo_pib") ///
		anioref(`=aniovp') piso(`=aniovp') corteanio(`=aniovp') cortetexto("anio de valor presente") ///
		serie(`serie') metadatos(`meta') origenserie("users/$id/`abrev'/ciclo-vida.json + PIBDeflactor `ent'") ///
		escalares(NetoCiclo`abrev' AportaCiclo`abrev' RecibeCiclo`abrev' PobCiclo`abrev' pibY`abrev' NetoCicloPIBE`abrev') ///
		saving("${SIMROOT}/users/$id/`abrev'/neto-pibe.json")
end

capture program drop _c32_pibe32
program define _c32_pibe32
	clear
	set obs 1
	g int anio = aniovp
	g double saldo_nominal = pibYSum32
	g double saldo_pib = pibeDiscrepancia32
	tempfile serie
	quietly save `serie'
	_c32_metadatos ///
		"unidad|saldo_nominal|pesos corrientes de anio_vp: suma de los 32 PIBE (pibY<ABREV>)" ///
		"unidad|saldo_pib|% de discrepancia: (suma de los 32 PIBE / PIB nacional pibY - 1) x 100, informativa" ///
		"formato|saldo_nominal|%14.1fc" ///
		"formato|saldo_pib|%7.2fc" ///
		"divisor|saldo_nominal|1000000" ///
		"criterio|denominador_pib|PIB nacional de la corrida: scalar pibY de PIBDeflactor nacional, anio de valor presente" ///
		"fuente|saldo_nominal|pibYSum32 = suma de pibY<ABREV> de las 32 (05_scripts/contrato-32.do)" ///
		"fuente|saldo_pib|pibeDiscrepancia32 (05_scripts/contrato-32.do); NetoCicloPIBNac = NetoCicloNac / pibY * 100 (neto nacional del ciclo, CicloEntidad.do)"
	tempfile meta
	quietly save `meta'
	scalarjson, nodo("entidades-pibe32") titulo("Suma de los 32 PIBE vs PIB nacional y neto nacional del ciclo como % del PIB") medida("saldo_pib") ///
		anioref(`=aniovp') piso(`=aniovp') corteanio(`=aniovp') cortetexto("anio de valor presente") ///
		serie(`serie') metadatos(`meta') origenserie("PIBDeflactor por entidad (32) + PIBDeflactor nacional + CicloEntidad.do") ///
		escalares(pibYSum32 pibY pibeDiscrepancia32 NetoCicloNac NetoCicloPIBNac) ///
		saving("${SIMROOT}/users/$id/entidades-pibe32.json")
end
capture mkdir `"`evidencia'"'
capture mkdir `"`evidencia'/entidades"'
timer clear 9
timer on 9
SIMentidad

** Bases precedentes (banda de vintages): las cinco o ninguna **
local vint "0"
local faltan ""
foreach v in 2016 2018 2020 2022 2024 {
	capture confirm file "${SIMROOT}/users/$id-v`v'/aportaciones.dta"
	if _rc local faltan "`faltan' `v'"
}
if "`faltan'" == "" local vint ""
noisily di _newline in g "{bf:contrato-32: las 32 entidades}" _newline in g "  banda de vintages: " in y `"`=cond("`vint'" == "", "sí (5 bases users/$id-v<anio>/aportaciones.dta)", "no — faltan vintages:`faltan' (receta en runbook §13)")'"'

tempname tsv
file open `tsv' using `"`evidencia'/contrato-32.tsv"', write replace text
file write `tsv' "pos" _tab "abrev" _tab "clave" _tab "nombre" _tab "poblacion_rc" _tab "pib_rc" _tab "pib_nota" _tab "sankeys_ok" _tab "sankeys_rc" _tab "ciclo_rc" _tab "te_rc" _tab "segundos" _tab "banda" _tab "pibe_pesos" _tab "neto_rc" _n

local j = 1
foreach ent of global entidadesL {
	if `j' > 32 continue, break
	SIMentidad `"`ent'"'
	local abrev "`r(abrev)'"
	local clave "`r(clave)'"
	local t0 = clock("$S_DATE $S_TIME", "DMYhms")
	capture mkdir "${SIMROOT}/users/$id/`abrev'"
	capture log close ent32
	quietly log using `"`evidencia'/entidades/`abrev'.log"', replace text name(ent32)
	noisily di _newline in g "  `j'/32 " in y `"`ent'"' in g " (`abrev', clave `clave')"

	* §1 Población *
	capture noisily Poblacion if entidad == `"`ent'"', anioi(`=aniovp') aniofinal(2070) nographs
	local rc_pob = _rc

	* §2 PIB/Deflactor: solo con base; la fracción SCN y el BISE quedan fuera (declarado) *
	local rc_pib = .
	local pibe_pesos "."
	local nota_pib "sin base master/PIBDeflactor`abrev'.dta (receta: PIBDeflactor if entidad == \"`ent'\", update  — baja series del BISE con token)"
	capture confirm file "${SIMROOT}/master/PIBDeflactor`abrev'.dta"
	if _rc == 0 {
		* comillas simples, no compuestas: PIBDeflactor extrae el `if entidad == "..."` con una regex antes de syntax *
		capture noisily PIBDeflactor if entidad == "`ent'", aniovp(`=aniovp') aniomax(2032) nographs nooutput
		local rc_pib = _rc
		local nota_pib "con base"
		capture confirm scalar pibY`abrev'
		if _rc == 0 local pibe_pesos = trim(string(scalar(pibY`abrev'), "%20.0f"))
	}

	* §8.2 Sankeys (5 cortes) *
	local ok_sk = 0
	local rc_sk ""
	foreach k in quintil grupoedad sexo rural escol {
		capture noisily run "${SIMROOT}/01_modulos/visualizations/SankeySF.do" `k' `=anioPE' `"`ent'"' "`vint'"
		if _rc == 0 local ++ok_sk
		else local rc_sk "`rc_sk' `k':`=_rc'"
	}

	* §8.2 Ciclo de vida *
	capture noisily run "${SIMROOT}/01_modulos/visualizations/CicloEntidad.do" `=anioPE' `"`ent'"'
	local rc_ciclo = _rc

	* §4.7 Tasas efectivas micro/micro *
	capture noisily run "${SIMROOT}/01_modulos/TasasEfectivasEntidad.do" `=anioPE' `"`ent'"'
	local rc_te = _rc

	* §4b Neto del ciclo / PIBE, en Stata (v8.13.0): solo con base PIBE y con el registro de CicloEntidad.do *
	local rc_neto = .
	capture confirm scalar pibY`abrev'
	local hay_pib = (_rc == 0)
	capture confirm scalar NetoCiclo`abrev'
	if `hay_pib' & _rc == 0 {
		capture noisily {
			escalar pctpib NetoCicloPIBE`abrev' = NetoCiclo`abrev'/pibY`abrev'*100
			_c32_neto_pibe "`abrev'" `"`ent'"'
		}
		local rc_neto = _rc
	}

	local seg = (clock("$S_DATE $S_TIME", "DMYhms") - `t0')/1000
	quietly log close ent32
	file write `tsv' "`j'" _tab "`abrev'" _tab "`clave'" _tab `"`ent'"' _tab "`rc_pob'" _tab "`rc_pib'" _tab `"`nota_pib'"' _tab "`ok_sk'" _tab "`=trim("`rc_sk'")'" _tab "`rc_ciclo'" _tab "`rc_te'" _tab "`seg'" _tab "`=cond("`vint'" == "", "si", "no")'" _tab "`pibe_pesos'" _tab "`rc_neto'" _n
	noisily di in g "     poblacion rc=" in y "`rc_pob'" in g "  pib rc=" in y "`rc_pib'" in g "  sankeys " in y "`ok_sk'/5" in g "  ciclo rc=" in y "`rc_ciclo'" in g "  te rc=" in y "`rc_te'" in g "  neto/PIBE rc=" in y "`rc_neto'" in g "  (" in y "`seg'" in g " s)"
	local ++j
}
file close `tsv'

** Σ32 PIBE vs PIB nacional y neto nacional / PIB, en Stata (v8.13.0) → users/$id/entidades-pibe32.json **
local sum32 = 0
local n32 = 0
local k = 1
foreach ab of global entidadesC {
	if `k' > 32 continue, break
	capture confirm scalar pibY`ab'
	if _rc == 0 {
		local sum32 = `sum32' + scalar(pibY`ab')
		local ++n32
	}
	local ++k
}
capture confirm scalar pibY
local hay_pibnac = (_rc == 0)
capture confirm scalar NetoCicloNac
if `n32' == 32 & `hay_pibnac' & _rc == 0 {
	capture noisily {
		escalar mxn pibYSum32 = `sum32'
		escalar pct pibeDiscrepancia32 = (pibYSum32/pibY - 1)*100
		escalar pctpib NetoCicloPIBNac = NetoCicloNac/pibY*100
		_c32_pibe32
	}
	if _rc noisily di as err "contrato-32: entidades-pibe32.json no se escribio (rc=`=_rc')"
}
else noisily di in g "contrato-32: entidades-pibe32.json omitido (pibY en `n32'/32 entidades; pibY nacional: `hay_pibnac')"
timer off 9
noisily di _newline in g "contrato-32: listo. Tabla: " in y `"`evidencia'/contrato-32.tsv"'
timer list 9
