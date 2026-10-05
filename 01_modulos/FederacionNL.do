*! FederacionNL.do  v1.1.0 (NL-0.4.1: participacionesAnual con vintage ENIGH; v1.0.0 NL-0.4.0) — La Federación y Nuevo León: transferencias, carga federal de residentes y balanza de flujos identificables (capa NL-0.4.0)
*
* QUÉ ES ESTO (DIAGNOSTICO_NL.md, anexo Federación↔NL; F0 aprobado 2026-10-04)
*   Tercer endpoint de la capa NL. Tres preguntas:
*     RECIBE  cuánto paga la Federación a NL por gasto federalizado identificable
*             por entidad: R28 (participaciones), R33 (aportaciones), convenios
*             de descentralización y reasignación, gasto federalizado del R23 y
*             recursos para protección social en salud. Fuente oportuna: SHCP,
*             Estadísticas Oportunas de Finanzas Públicas (lector propio _NLeopf,
*             patrón _NLbie). Ancla anual: Cuenta Pública por entidad (PEF.dta
*             del motor, divFEDE) y, para el año de política, PEF/PPEF por entidad.
*     PAGA    cuánto pagan los RESIDENTES de NL en impuestos federales según la
*             incidencia micro de la capa (EntidadNL.do, ENIGH): pesos pagados =
*             Part<X>nl (participación de NL en cada impuesto) × recaudación
*             observada del impuesto (LIF.dta del motor). JAMÁS recaudación por
*             domicilio fiscal. Impuestos federales stricto sensu: sin OTROSK y
*             con cuotas IMSS en renglón aparte NO sumado (su contraparte de
*             gasto, IMSS, está fuera del alcance). La banda [S1, S3] del ISR PM
*             se propaga al total y a la balanza; S0 = método vigente, dentro.
*     BALANZA recibe − paga, como banda, en nominal / real / per cápita / % PIBE.
*
* ALCANCE DECLARADO (visible en el endpoint, no en el pie): balanza de FLUJOS
*   IDENTIFICABLES. Excluye el gasto federal directo ejercido en NL (pensiones
*   contributivas, IMSS/ISSSTE, CFE, inversión física federal, sueldos
*   federales): fase futura explícita.
*
* SUPUESTO DECLARADO: la participación de NL en cada impuesto se toma CONSTANTE
*   en el tiempo (vintage ENIGH / año de política de la corrida de EntidadNL):
*   es una retropolación de incidencia, no una serie observada ("incidencia fija").
*
* ARQUITECTURA B (resolución 2026-10-04): el lado "paga" y las anclas dependen de
*   cachés del motor que solo tiene el Mac (statajson_entidad-nl.json ← SIM.do;
*   master/LIF.dta; master/PEF.dta). Cuando existen (modo CANAL) el driver los
*   lee, VERIFICA el sello commiteado nl-assets/federacion-sello.json (reldif
*   1e-9; si difiere aborta salvo global nlfed_sellar 1, que lo reescribe) o lo
*   crea si no existe. Cuando no existen (modo SELLO: runner Windows) lee el
*   sello y exige misma versión de capa, de motor y mismo anioPE que la sesión;
*   si no, aborta. Los números siguen saliendo del canal: el sello es un extracto
*   con procedencia y SHA, nunca se teclea. Frontera motor/producto: el runner
*   de CoNL no construye derivados de la ENIGH.
*
* DENOMINADORES CON PROCEDENCIA: población = master/Poblacion.dta (CONAPO, la
*   misma de PoblacionNL) con compuerta contra poblacion-nl.json de la MISMA
*   corrida; PIBE y deflactor implícito = actividad-nl.json (PIBDeflactorNL).
*   Reales con el deflactor implícito del PIBE NL (convención fiscal del motor;
*   el INPC no se usa en flujos fiscales).
*
* COMPUERTAS (abortan; ver §9 del anexo): (1) Σ 32 entidades + No distribuible =
*   total nacional por fondo y año; (2) ancla CP: R28 EOFP = CP (0.1 %) y R33
*   (2.5 %), convenios reportado; (3) recaudación = la del motor y Rec<X>nac de
*   EntidadNL = ILIF del año de política; (4) Part = Rec/Rec recalculado; (5)
*   vintage compatible (EntidadNL / sello / sidecars = versión de capa, motor y
*   anioPE de la sesión); (6) rejillas sin huecos; (7) total GF de SHCP = Σ
*   agregados; (8) denominador: población del JSON de Población = Poblacion.dta;
*   (9) log activo.
*
* SALIDAS (generadas, gitignored): users/$id/nodos/federacion-nl.json,
*   federacion-nl.log (y federacion-nl.html cuando exista la plantilla, F2).
*   Commiteado (modo canal): 01_modulos/nl-assets/federacion-sello.json.
* USO:  do "${SIMROOT}/01_modulos/FederacionNL.do"
*   global nlbie_offline 1  -> reutiliza la caché EOPF sin descargar (desarrollo)
*   global nlfed_sellar 1   -> reescribe el sello desde el canal (Mac, release)
* OJO: destruye los datos en memoria.

version 17										// candado: misma interpretación en Stata 17 (Mac) y 19.5 (runner Windows)

*** 0 RAÍZ, LOG, IDENTIDAD ***
SIMroot
local site `"${SIMROOT}"'
if "$id" == "" global id = "`c(username)'"
capture mkdir `"`site'/users"'
capture mkdir `"`site'/users/$id"'
capture mkdir `"`site'/users/$id/nodos"'
local q = char(34)
local off = cond("$nlbie_offline" == "1", "offline", "")
local sellar = ("$nlfed_sellar" == "1")

capture confirm scalar aniovp
if _rc == 0 local aniovp = scalar(aniovp)
else local aniovp = year(date("$S_DATE", "DMY"))
capture confirm scalar anioPE
if _rc == 0 local aniope = scalar(anioPE)
else local aniope = `aniovp'
local anio0 = 2000									// año de arranque común de los seis agregados EOFP

capture log close nlfed
quietly log using `"`site'/users/$id/nodos/federacion-nl.log"', replace text name(nlfed)
capture quietly log query nlfed
if `"`r(filename)'"' == "" {
	di as err "FederacionNL: no pudo abrirse el log de procedencia; sin procedencia no hay exportación válida."
	exit 459
}
local logfile "federacion-nl.log"

run `"`site'/01_modulos/nl-assets/nl-identidad.do"'
_NLidentidad, modulo("La Federación y Nuevo León")
local nl_producto `"`r(producto)'"'
local nl_titulo `"`r(titulo)'"'
local nl_subtitulo `"`r(subtitulo)'"'
local nl_vmotor `"`r(version_motor)'"'
local nl_vnl `"`r(version_nl)'"'
local nl_repo `"`r(repositorio)'"'
if "`nl_vnl'" == "" | "`nl_vmotor'" == "" {
	di as err "FederacionNL: sin versión de capa o de motor declarada no puede verificarse el vintage. No se exporta."
	exit 459
}
run `"`site'/01_modulos/nl-assets/nl-fed.do"'

* Número a JSON con precisión completa (espejo de _sjnum de scalarjson.ado) *
capture program drop _nlnum
program define _nlnum, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	local s = trim(string(`e', "%25.17g"))
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end
* Texto a JSON (comillas dobles -> simples; sin saltos) *
capture program drop _nltxt
program define _nltxt, rclass
	gettoken s : 0				// quita las comillas compuestas envolventes del argumento
	local s = subinstr(`"`s'"', `"""', "'", .)
	local s = subinstr(`"`s'"', char(10), " ", .)
	local s = subinstr(`"`s'"', char(13), "", .)
	local s = trim(`"`s'"')
	return local t `"`s'"'
end

* Entidades en orden INEGI (profile.do:209); fallback idéntico si no se cargó *
if `"$entidadesL"' == "" {
	local entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
}
else local entidadesL `"$entidadesL"'

* Fondos: lista EXPLÍCITA de claves SHCP (nunca substring) y clave corta del JSON *
local agregados "XAC28 XAC33 XACCD XACCR XAC23 XACPSS"
local kXAC28 "R28"
local kXAC33 "R33"
local kXACCD "CD"
local kXACCR "CR"
local kXAC23 "R23"
local kXACPSS "PSS"
local sub28 "XAC28A XAC28B XAC28C XAC28D XAC28E XAC28F XAC28G XAC28H XAC28I XAC28J XAC28K XAC28L XAC28M"
local sub33 "XAC33A XAC33B XAC33C XAC33D XAC33E XAC33F XAC33G XAC33H XAC33I XAC33J XAC33K XAC33L XAC33M XAC33N XAC33O"
local subCD "XACCDA XACCDD XACCDE"
local sub23 "XAC23A XAC23B XAC23C"
local subfondos "`sub28' `sub33' `subCD' `sub23'"
local todos "`agregados' `subfondos' XACGF"
local impuestos "ISRAS ISRPF ISRPM IVA IEPSNP IEPSP ISAN IMPORT"	// impuestos federales stricto sensu
local extras "CUOTAS OTROSK"												// aparte, nunca sumados

*** 1 RECIBE: ESTADÍSTICAS OPORTUNAS (fetcher propio) ***
noisily di _newline in g "{bf:1. Transferencias federales por fondo y entidad (SHCP, Estadísticas Oportunas)}"
_NLeopf, fondos(`todos') `off'
local eopf_fecha `"`r(fecha)'"'
local eopf_lastmod `"`r(lastmod)'"'
local eopf_pf `"`r(periodo_final)'"'
local eopf_n = r(n)
local eopf_chk = r(checksum)
local eopf_fondos `"`r(fondos)'"'
quietly {
	compress
	tempfile E
	save `E'
	import delimited `"`eopf_fondos'"', clear varnames(1) encoding(utf-8) stringcols(1 2)
	forvalues i = 1/`=_N' {
		local nom`=fondo[`i']' `"`=subinstr(nombre[`i'], char(13), "", .)'"'
	}
	use `E', clear
	* Último mes publicado (del total nacional de participaciones) *
	summarize anio if fondo == "XAC28" & ent == "00", meanonly
	local anio1 = r(max)
	summarize mes if fondo == "XAC28" & ent == "00" & anio == `anio1', meanonly
	local mes1 = r(max)
	local anioult = cond(`mes1' == 12, `anio1', `anio1' - 1)		// último año completo EOFP
	* Anual por fondo × entidad *
	collapse (sum) monto (count) nmeses = monto, by(anio fondo ent)
	tempfile A
	save `A'
}
noisily di in g "  Periodo final publicado: " in y "`eopf_pf'" in g " · último año completo: " in y "`anioult'" in g " · año en curso `anio1' acumulado a mes " in y "`mes1'"

** 1.1 Compuerta 1: Σ(32 entidades) + No distribuible = total nacional, por fondo y año **
quietly {
	use `A', clear
	g double t00 = monto if ent == "00"
	g double tE = monto if ent != "00"
	collapse (sum) t00 tE, by(anio fondo)
	g double rd = reldif(tE, t00)
	summarize rd if anio >= `anio0' & t00 != 0, meanonly
	local rdmax = r(max)
	count if anio >= `anio0' & t00 != 0 & rd > 1e-4
	local nfail = r(N)
}
if `nfail' > 0 {
	noisily list fondo anio t00 tE rd if anio >= `anio0' & t00 != 0 & rd > 1e-4, noobs clean
	di as err "FederacionNL: la suma de las 32 entidades + No distribuible no reproduce el total nacional en `nfail' fondo-año (tolerancia 1e-4). No se exporta."
	exit 459
}
noisily di in g "  Compuerta 1 (Σ32 + ND = total nacional, `anio0'-`anio1'): " in y "PASÓ" in g " (reldif máx " in y %9.2e `rdmax' in g ")."

** 1.2 Compuerta 7: total gasto federalizado de SHCP = Σ seis agregados (nacional y NL) **
quietly {
	use `A', clear
	keep if inlist(ent, "00", "19") & anio >= `anio0'
	g byte agg = 0
	foreach f of local agregados {
		replace agg = 1 if fondo == "`f'"
	}
	g double sAgg = monto if agg
	g double sGF = monto if fondo == "XACGF"
	collapse (sum) sAgg sGF, by(anio ent)
	g double rd = reldif(sAgg, sGF)
	summarize rd, meanonly
	local rdGF = r(max)
	count if rd > 1e-6
	local nfail = r(N)
}
if `nfail' > 0 {
	noisily list anio ent sAgg sGF rd if rd > 1e-6, noobs clean
	di as err "FederacionNL: el total de gasto federalizado de SHCP no es la suma de R28+R33+CD+CR+R23+PSS en `nfail' año-entidad (1e-6). No se exporta."
	exit 459
}
noisily di in g "  Compuerta 7 (GF = Σ agregados, nacional y NL): " in y "PASÓ" in g " (reldif máx " in y %9.2e `rdGF' in g ")."

** 1.3 Rejilla anual NL/nacional de los seis agregados (`anio0'..`anio1'); 0 solo donde el nacional es 0 **
quietly {
	use `A', clear
	keep if inlist(ent, "00", "19") & anio >= `anio0'
	g byte agg = 0
	foreach f of local agregados {
		replace agg = 1 if fondo == "`f'"
	}
	keep if agg
	drop agg
	reshape wide monto nmeses, i(anio fondo) j(ent) string
	fillin anio fondo
	count if _fillin & (monto00 == . | monto00 != 0)
	if r(N) > 0 {
		noisily list anio fondo monto00 monto19 if _fillin, noobs clean
		noisily di as err "FederacionNL: hueco en la serie anual EOFP (nacional ≠ 0 y sin fila). No se exporta."
		exit 459
	}
	replace monto19 = 0 if monto19 == . & monto00 == 0
	count if monto19 == . & anio <= `anio1'
	if r(N) > 0 {
		noisily list anio fondo monto00 monto19 if monto19 == ., noobs clean
		noisily di as err "FederacionNL: NL sin dato donde el nacional ≠ 0. No se exporta."
		exit 459
	}
	replace nmeses00 = 12 if nmeses00 == . & anio < `anio1'
	replace nmeses19 = 12 if nmeses19 == . & anio < `anio1'
	drop _fillin
	* Clave corta por fondo *
	g key = ""
	foreach f of local agregados {
		replace key = "`k`f''" if fondo == "`f'"
	}
	drop fondo
	rename (monto19 monto00 nmeses19 nmeses00) (nl nac m19 m00)
	reshape wide nl nac m19 m00, i(anio) j(key) string
	egen double nlTot = rowtotal(nlR28 nlR33 nlCD nlCR nlR23 nlPSS)
	egen double nacTot = rowtotal(nacR28 nacR33 nacCD nacCR nacR23 nacPSS)
	egen int nmeses = rowmin(m19R28 m00R28)
	drop m19* m00*
	g tipoRecibe = cond(nmeses == 12, "observado", "parcial")
	tsset anio
	if r(tmax) - r(tmin) + 1 != _N {
		noisily di as err "FederacionNL: la rejilla anual EOFP tiene huecos. No se exporta."
		exit 459
	}
	tempfile R
	save `R'
}
noisily di in g "  Compuerta 6a (rejilla anual `anio0'-`anio1', seis agregados, NL y nacional): " in y "PASÓ" in g "."

** 1.4 Rejilla mensual (últimos 24 meses, total GF NL y nacional) **
quietly {
	use `E', clear
	keep if fondo == "XACGF" & inlist(ent, "00", "19")
	g aniomes = ym(anio, mes)
	format aniomes %tm
	keep if aniomes > ym(`anio1', `mes1') - 24
	reshape wide monto, i(anio mes aniomes fondo) j(ent) string
	rename (monto19 monto00) (nlTot nacTot)
	tsset aniomes
	if r(tmax) - r(tmin) + 1 != _N | _N != 24 {
		noisily di as err "FederacionNL: la rejilla mensual (24 meses) tiene huecos. No se exporta."
		exit 459
	}
	* Agregados mensuales NL *
	tempfile Mt
	save `Mt'
	use `E', clear
	keep if ent == "19"
	g byte agg = 0
	foreach f of local agregados {
		replace agg = 1 if fondo == "`f'"
	}
	keep if agg
	g aniomes = ym(anio, mes)
	keep if aniomes > ym(`anio1', `mes1') - 24
	g key = ""
	foreach f of local agregados {
		replace key = "`k`f''" if fondo == "`f'"
	}
	keep anio mes aniomes key monto
	reshape wide monto, i(anio mes aniomes) j(key) string
	rename monto* nl*
	merge 1:1 aniomes using `Mt', nogen assert(match)
	format aniomes %tm
	sort aniomes
	tempfile M
	save `M'
}
noisily di in g "  Compuerta 6b (rejilla mensual, 24 meses): " in y "PASÓ" in g "."

*** 2 DENOMINADORES CON PROCEDENCIA: POBLACIÓN (CONAPO) Y PIBE/DEFLACTOR (sidecar) ***
noisily di _newline in g "{bf:2. Denominadores: población CONAPO y PIBE/deflactor del sidecar}"
capture confirm file `"`site'/master/Poblacion.dta"'
if _rc {
	di as err "FederacionNL: falta master/Poblacion.dta (la construye Poblacion.ado / PoblacionNL.do). No se exporta."
	exit 601
}
quietly {
	use entidad anio poblacion using `"`site'/master/Poblacion.dta"', clear
	collapse (sum) pob = poblacion, by(entidad anio)
	g ent = ""
	local k = 0
	foreach e of local entidadesL {
		local ++k
		if `k' <= 32 replace ent = string(`k', "%02.0f") if entidad == "`e'"
	}
	replace ent = "00" if entidad == "Nacional"
	count if ent == ""
	if r(N) > 0 {
		noisily levelsof entidad if ent == "", clean
		noisily di as err "FederacionNL: entidades de master/Poblacion.dta sin clave INEGI. No se exporta."
		exit 459
	}
	keep anio ent pob
	* Compuerta: Σ 32 entidades = Nacional, por año *
	g double p00 = pob if ent == "00"
	g double pE = pob if ent != "00"
	egen double s00 = total(p00), by(anio)
	egen double sE = total(pE), by(anio)
	count if reldif(sE, s00) > 1e-9
	if r(N) > 0 {
		noisily di as err "FederacionNL: la suma de las 32 entidades no reproduce la población nacional en `r(N)' filas. No se exporta."
		exit 459
	}
	drop p00 pE s00 sE
	tempfile POB POBnl POBnac
	save `POB'
	preserve
	keep if ent == "19"
	keep anio pob
	rename pob pobNL
	save `POBnl'
	restore
	preserve
	keep if ent == "00"
	keep anio pob
	rename pob pobNac
	save `POBnac'
	restore
	_NLfileinfo `"`site'/master/Poblacion.dta"'
	local pob_mtime "`r(mtime)'"
}
* Compuerta 8: el JSON de Población de ESTA corrida usa la misma población *
local pobjson `"`site'/users/$id/nodos/poblacion-nl.json"'
capture confirm file `"`pobjson'"'
if _rc {
	di as err "FederacionNL: falta users/$id/nodos/poblacion-nl.json (corre PoblacionNL.do primero): el denominador debe ser de la misma corrida. No se exporta."
	exit 601
}
_NLjsonget using `"`pobjson'"', keys(cifras.anio cifras.nl.pobtot cifras.nac.pobtot procedencia.version_capa_nl procedencia.generado_en)
local pobj_anio = `r(v1)'
local pobj_nl = `r(v2)'
local pobj_nac = `r(v3)'
local pobj_vnl "`r(v4)'"
local pobj_gen `"`r(v5)'"'
quietly {
	use `POB', clear
	summarize pob if anio == `pobj_anio' & ent == "19", meanonly
	local pnl = r(mean)
	summarize pob if anio == `pobj_anio' & ent == "00", meanonly
	local pnac = r(mean)
}
if reldif(`pnl', `pobj_nl') > 1e-9 | reldif(`pnac', `pobj_nac') > 1e-9 {
	di as err "FederacionNL: la población de master/Poblacion.dta (`pobj_anio': NL `pnl', nac `pnac') no coincide con poblacion-nl.json (`pobj_nl', `pobj_nac'): denominador de otra corrida. No se exporta."
	exit 459
}
if "`pobj_vnl'" != "`nl_vnl'" {
	di as err "FederacionNL: poblacion-nl.json es de la capa `pobj_vnl' y la sesión es `nl_vnl'. Regenera los sidecars (actualizar-nl) antes. No se exporta."
	exit 459
}
noisily di in g "  Compuerta 8 (denominador = PoblacionNL de la misma corrida, `pobj_anio'): " in y "PASÓ" in g " (NL " in y %12.0fc `pnl' in g ", nacional " in y %14.0fc `pnac' in g ")."

* PIBE nominal y deflactor implícito NL (base aniovp = 1) del sidecar de actividad *
local actjson `"`site'/users/$id/nodos/actividad-nl.json"'
capture confirm file `"`actjson'"'
if _rc {
	di as err "FederacionNL: falta users/$id/nodos/actividad-nl.json (corre PIBDeflactorNL.do primero). No se exporta."
	exit 601
}
_NLjsonget using `"`actjson'"', keys(procedencia.version_capa_nl procedencia.generado_en anio_politica)
local actj_vnl "`r(v1)'"
local actj_gen `"`r(v2)'"'
local actj_pe = `r(v3)'
if "`actj_vnl'" != "`nl_vnl'" | `actj_pe' != `aniope' {
	di as err "FederacionNL: actividad-nl.json es de la capa `actj_vnl' / año de política `actj_pe'; la sesión es `nl_vnl' / `aniope'. No se exporta."
	exit 459
}
quietly {
	_NLjsonarr using `"`actjson'"', array(anual) fields(anio tipoCrec tipoDefl pibeNnl pibeNnac deflatornl deflatornac)
	destring anio pibeNnl pibeNnac deflatornl deflatornac, replace
	replace pibeNnl = pibeNnl*1e6								// millones -> pesos
	replace pibeNnac = pibeNnac*1e6
	rename tipoCrec tipoPIBE
	keep anio tipoPIBE tipoDefl pibeNnl pibeNnac deflatornl deflatornac
	count if anio == `aniovp' & reldif(deflatornl, 1) > 1e-9
	if r(N) > 0 {
		noisily di as err "FederacionNL: el deflactor NL del sidecar no vale 1 en aniovp (`aniovp'). No se exporta."
		exit 459
	}
	tempfile PIBE
	save `PIBE'
	summarize anio, meanonly
	local pibe0 = r(min)
}
noisily di in g "  PIBE y deflactor implícito NL (sidecar actividad, `pibe0'-`aniope', base `aniovp' = 1): " in y "OK" in g " (corrida `actj_gen')."

*** 3 PAGA Y ANCLAS: CANAL (Mac) O SELLO (runner) ***
noisily di _newline in g "{bf:3. Lado paga y anclas: canal del motor o sello de corrida}"
local entjson `"`site'/users/$id/nodos/statajson_entidad-nl.json"'
local sello `"`site'/01_modulos/nl-assets/federacion-sello.json"'
local canal = 1
foreach f in `"`entjson'"' `"`site'/master/LIF.dta"' `"`site'/master/PEF.dta"' {
	capture confirm file `"`f'"'
	if _rc local canal = 0
}
capture confirm file `"`sello'"'
local haysello = (_rc == 0)
if !`canal' & !`haysello' {
	di as err "FederacionNL: ni canal (statajson_entidad-nl.json + LIF.dta + PEF.dta) ni sello (nl-assets/federacion-sello.json). No se exporta."
	exit 601
}
local modo = cond(`canal', "canal", "sello")
noisily di in g "  Modo: " in y "`modo'" in g cond(`haysello', " (sello presente)", " (sin sello: se creará)")

if `canal' {
	** 3.1 EntidadNL: identidad y escalares **
	_NLjsonget using `"`entjson'"', keys(anio_referencia presentacion.version_capa_nl presentacion.version_motor procedencia.generado_en presentacion.enigh_vintage criterios.momento_de_registro)
	local ent_anio = `r(v1)'
	local ent_vnl "`r(v2)'"
	local ent_vmotor "`r(v3)'"
	local ent_gen `"`r(v4)'"'
	* Vintage ENIGH de la incidencia: clave presentacion.enigh_vintage (EntidadNL v1.3.1+) o, en
	* corridas anteriores, el criterio momento_de_registro ("... ENIGH 2024 ...") del mismo JSON. *
	local enigh ""
	if "`r(ok5)'" == "1" & "`r(v5)'" != "" local enigh = "`r(v5)'"
	else if regexm(`"`r(v6)'"', "ENIGH ([0-9][0-9][0-9][0-9])") local enigh = regexs(1)
	if "`enigh'" == "" {
		di as err "FederacionNL: no pudo determinarse el vintage ENIGH de la incidencia (ni presentacion.enigh_vintage ni criterios.momento_de_registro). No se exporta."
		exit 459
	}
	if `ent_anio' != `aniope' | "`ent_vnl'" != "`nl_vnl'" | "`ent_vmotor'" != "`nl_vmotor'" {
		di as err "FederacionNL: statajson_entidad-nl.json es de PE `ent_anio' / capa `ent_vnl' / motor `ent_vmotor'; la sesión es `aniope' / `nl_vnl' / `nl_vmotor'. Re-corre SIM.do + EntidadNL.do. No se exporta."
		exit 459
	}
	_NLsha256 `"`entjson'"'
	local ent_sha "`r(sha256)'"
	quietly {
		_NLjsonesc using `"`entjson'"', prefijos(Rec Part)
		forvalues i = 1/`=_N' {
			local v`=nombre[`i']' = valor[`i']
		}
		* Participaciones por impuesto (compuerta 4: Part = Rec/Rec si EntidadNL ya las exporta) *
		local nfail = 0
		clear
		set obs 10
		g impuesto = ""
		g double part = .
		g double partS1 = .
		g double partS2 = .
		g double partS3 = .
		g double recNac = .
		g double recNL = .
		local i = 0
		foreach x in `impuestos' `extras' {
			local ++i
			replace impuesto = "`x'" in `i'
			replace recNac = `vRec`x'nac' in `i'
			replace recNL = `vRec`x'nl' in `i'
			replace part = `vRec`x'nl'/`vRec`x'nac' in `i'
			if "`vPart`x'nl'" != "" {
				if reldif(`vPart`x'nl'/100, `vRec`x'nl'/`vRec`x'nac') > 1e-9 local ++nfail
			}
			if "`x'" == "ISRPM" {
				forvalues s = 1/3 {
					replace partS`s' = `vRecISRPMnlS`s''/`vRecISRPMnac' in `i'
				}
			}
		}
		replace partS1 = part if partS1 == .
		replace partS2 = part if partS2 == .
		replace partS3 = part if partS3 == .
		tempfile PART
		save `PART'
	}
	if `nfail' > 0 {
		di as err "FederacionNL: Part<X>nl exportada por EntidadNL ≠ Rec<X>nl/Rec<X>nac en `nfail' impuestos. No se exporta."
		exit 459
	}
	noisily di in g "  Compuerta 4 (Part = Rec/Rec): " in y "PASÓ" in g "."

	** 3.2 LIF.dta: recaudación observada por impuesto y año (canal del motor, no re-descargada) **
	quietly {
		* Mismo filtro que PerfilesSim.do §2 (v8.3.0): sin financiamiento (divLIF 10),
		* salvo diferimiento de pagos (divCIEP 8); si no, OTROSK absorbe el endeudamiento *
		use anio mes divSIM divLIF divCIEP monto ILIF if divLIF != 10 | divCIEP == 8 using `"`site'/master/LIF.dta"', clear
		decode divSIM, g(impuesto)
		g byte sel = 0
		foreach x in `impuestos' `extras' {
			replace sel = 1 if impuesto == "`x'"
		}
		keep if sel & anio >= `anio0'
		drop sel
		collapse (sum) observado = monto lif = ILIF (min) mes (max) mesmax = mes, by(anio impuesto)
		count if mes != mesmax & mes != .
		if r(N) > 0 {
			noisily di as err "FederacionNL: series de un mismo impuesto con distinto mes de corte en LIF.dta. No se exporta."
			exit 459
		}
		drop mesmax
		replace observado = . if mes == .
		g tipoPaga = cond(mes == 12, "observado", cond(mes < 12, "parcial", "sin dato"))
		tempfile REC
		save `REC'
		_NLfileinfo `"`site'/master/LIF.dta"'
		local lif_mtime "`r(mtime)'"
		summarize anio if tipoPaga == "observado", meanonly
		local lif_ult = r(max)
		* Compuerta 3: Rec<X>nac (EntidadNL) = ILIF del año de política en LIF.dta *
		local nfail = 0
		foreach x in `impuestos' `extras' {
			summarize lif if anio == `aniope' & impuesto == "`x'", meanonly
			if reldif(r(mean), `vRec`x'nac') > 1e-6 {
				local ++nfail
				noisily di as err "  `x': ILIF `aniope' = `r(mean)' vs Rec`x'nac = `vRec`x'nac'"
			}
		}
	}
	if `nfail' > 0 {
		di as err "FederacionNL: la recaudación nacional de EntidadNL no es la ILIF `aniope' del motor en `nfail' impuestos. No se exporta."
		exit 459
	}
	noisily di in g "  Compuerta 3 (Rec<X>nac = ILIF `aniope' de LIF.dta): " in y "PASÓ" in g " · recaudación observada hasta " in y "`lif_ult'" in g "."

	** 3.3 PEF.dta: anclas CP / PEF / PPEF por entidad y divFEDE **
	noisily di in g "  Leyendo master/PEF.dta (Cuenta Pública por entidad)..."
	quietly {
		use anio entidad divFEDE gasto ejercido aprobado proyecto using `"`site'/master/PEF.dta"', clear
		keep if inlist(divFEDE, "Participaciones", "Aportaciones", "Convenios", "Subsidios", "Salud (federalizado)")
		g fuente = cond(ejercido != ., "CP", cond(aprobado != ., "PEF", "PPEF"))
		g byte nl = entidad == 19
		g byte nd = entidad == 34
		collapse (sum) gasto, by(anio divFEDE fuente nl nd)
		g double vnl = gasto if nl
		g double vnd = gasto if nd
		collapse (sum) nacional = gasto nl = vnl nodist = vnd, by(anio divFEDE fuente)
		duplicates report anio divFEDE
		if r(unique_value) != r(N) {
			noisily di as err "FederacionNL: PEF.dta mezcla fuentes (CP/PEF/PPEF) en un mismo año. No se exporta."
			exit 459
		}
		tempfile ANC
		save `ANC'
		_NLfileinfo `"`site'/master/PEF.dta"'
		local pef_mtime "`r(mtime)'"
		levelsof anio if fuente == "CP", clean
		local pef_cp "`r(levels)'"
		levelsof anio if fuente == "PEF", clean
		local pef_pef "`r(levels)'"
		levelsof anio if fuente == "PPEF", clean
		local pef_ppef "`r(levels)'"
	}
	noisily di in g "  Anclas PEF.dta: CP " in y "`=word("`pef_cp'",1)'-`=word("`pef_cp'",wordcount("`pef_cp'"))'" in g " · PEF " in y "`pef_pef'" in g " · PPEF " in y "`pef_ppef'" in g "."

	** 3.4 Sello: verificar (reldif 1e-9) o escribir **
	local escribir = 0
	if !`haysello' local escribir = 1
	if `haysello' {
		_NLjsonget using `"`sello'"', keys(identidad.version_capa_nl identidad.version_motor identidad.anioPE identidad.entidadnl_sha256 identidad.generado_en identidad.enigh)
		local s_vnl "`r(v1)'"
		local s_vmotor "`r(v2)'"
		local s_pe "`r(v3)'"
		local s_sha "`r(v4)'"
		local s_gen `"`r(v5)'"'
		local s_enigh "`r(v6)'"
		local difs = 0
		if "`s_vnl'" != "`nl_vnl'" | "`s_vmotor'" != "`nl_vmotor'" | "`s_pe'" != "`aniope'" | "`s_sha'" != "`ent_sha'" | "`s_enigh'" != "`enigh'" local ++difs
		quietly {
			_NLjsonarr using `"`sello'"', array(participaciones) fields(impuesto part partS1 partS2 partS3 recNac recNL)
			rename (part partS1 partS2 partS3 recNac recNL) (s_part s_partS1 s_partS2 s_partS3 s_recNac s_recNL)
			merge 1:1 impuesto using `PART'
			count if _merge != 3
			local difs = `difs' + r(N)
			foreach v in part partS1 partS2 partS3 recNac recNL {
				count if _merge == 3 & reldif(s_`v', `v') > 1e-9
				local difs = `difs' + r(N)
			}
			_NLjsonarr using `"`sello'"', array(recaudacion) fields(anio impuesto mes observado lif)
			rename (mes observado lif) (s_mes s_observado s_lif)
			merge 1:1 anio impuesto using `REC'
			count if _merge != 3
			local difs = `difs' + r(N)
			count if _merge == 3 & (s_mes != mes | reldif(s_observado, observado) > 1e-9 | reldif(s_lif, lif) > 1e-9)
			local difs = `difs' + r(N)
			_NLjsonarr using `"`sello'"', array(anclas) fields(anio divFEDE fuente nl nacional nodist)
			rename (fuente nl nacional nodist) (s_fuente s_nl s_nacional s_nodist)
			merge 1:1 anio divFEDE using `ANC'
			count if _merge != 3
			local difs = `difs' + r(N)
			count if _merge == 3 & (s_fuente != fuente | reldif(s_nl, nl) > 1e-9 | reldif(s_nacional, nacional) > 1e-9 | reldif(s_nodist, nodist) > 1e-9)
			local difs = `difs' + r(N)
		}
		if `difs' > 0 & !`sellar' {
			di as err "FederacionNL: el sello nl-assets/federacion-sello.json (corrida `s_gen', capa `s_vnl', PE `s_pe') difiere del canal vivo en `difs' elementos. Si el canal es el bueno, re-corre con global nlfed_sellar 1 y commitea el sello; si no, revisa SIM.do/EntidadNL. No se exporta."
			exit 459
		}
		if `difs' > 0 & `sellar' {
			noisily di in g "  Sello: " in y "`difs' diferencias" in g " con el canal; se REESCRIBE (nlfed_sellar = 1)."
			local escribir = 1
		}
		if `difs' == 0 noisily di in g "  Compuerta 5b (sello = canal, reldif 1e-9): " in y "PASÓ" in g " (sello de `s_gen')."
	}
	if `escribir' {
		local sello_gen = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
		tempname sh
		file open `sh' using `"`sello'"', write text replace
		file write `sh' "{" _n
		file write `sh' `"  `q'esquema`q': `q'nl.federacion-sello/v1`q',"' _n
		file write `sh' `"  `q'nota`q': `q'Extracto SELLADO del canal del motor para el endpoint Federación↔NL (arquitectura B). Lo escribe FederacionNL.do en el Mac desde statajson_entidad-nl.json, master/LIF.dta y master/PEF.dta; el runner lo consume solo si versión de capa, de motor y anioPE coinciden con su sesión. Ningún número se teclea.`q',"' _n
		file write `sh' `"  `q'identidad`q': {`q'version_capa_nl`q': `q'`nl_vnl'`q', `q'version_motor`q': `q'`nl_vmotor'`q', `q'anioPE`q': `aniope', `q'aniovp`q': `aniovp', `q'enigh`q': `enigh', `q'generado_en`q': `q'`sello_gen'`q', `q'entidadnl_generado_en`q': `q'`ent_gen'`q', `q'entidadnl_sha256`q': `q'`ent_sha'`q', `q'lif_dta_mtime`q': `q'`lif_mtime'`q', `q'lif_observado_hasta`q': `lif_ult', `q'pef_dta_mtime`q': `q'`pef_mtime'`q', `q'pef_cp`q': `q'`pef_cp'`q', `q'pef_pef`q': `q'`pef_pef'`q', `q'pef_ppef`q': `q'`pef_ppef'`q'},"' _n
		quietly use `PART', clear
		file write `sh' `"  `q'participaciones`q': ["' _n
		forvalues i = 1/`=_N' {
			file write `sh' `"    {`q'impuesto`q': `q'`=impuesto[`i']'`q'"'
			foreach v in part partS1 partS2 partS3 recNac recNL {
				_nlnum "`v'[`i']"
				file write `sh' `", `q'`v'`q': `r(n)'"'
			}
			file write `sh' "}`=cond(`i' < _N, ",", "")'" _n
		}
		file write `sh' "  ]," _n
		quietly use `REC', clear
		quietly sort anio impuesto
		file write `sh' `"  `q'recaudacion`q': ["' _n
		forvalues i = 1/`=_N' {
			file write `sh' `"    {`q'anio`q': `=anio[`i']', `q'impuesto`q': `q'`=impuesto[`i']'`q'"'
			foreach v in mes observado lif {
				_nlnum "`v'[`i']"
				file write `sh' `", `q'`v'`q': `r(n)'"'
			}
			file write `sh' "}`=cond(`i' < _N, ",", "")'" _n
		}
		file write `sh' "  ]," _n
		quietly use `ANC', clear
		quietly sort anio divFEDE
		file write `sh' `"  `q'anclas`q': ["' _n
		forvalues i = 1/`=_N' {
			file write `sh' `"    {`q'anio`q': `=anio[`i']', `q'divFEDE`q': `q'`=divFEDE[`i']'`q', `q'fuente`q': `q'`=fuente[`i']'`q'"'
			foreach v in nl nacional nodist {
				_nlnum "`v'[`i']"
				file write `sh' `", `q'`v'`q': `r(n)'"'
			}
			file write `sh' "}`=cond(`i' < _N, ",", "")'" _n
		}
		file write `sh' "  ]" _n
		file write `sh' "}" _n
		file close `sh'
		noisily di in g "  Sello escrito: " in y `"`sello'"' in g " (commitéalo con esta corrida)."
	}
	local sello_desc "canal del motor verificado contra el sello"
	if `escribir' local sello_gen_use `"`sello_gen'"'
	else local sello_gen_use `"`s_gen'"'
}
else {
	** 3.5 Modo sello (runner): identidad compatible o abortar **
	_NLjsonget using `"`sello'"', keys(identidad.version_capa_nl identidad.version_motor identidad.anioPE identidad.generado_en identidad.entidadnl_generado_en identidad.entidadnl_sha256 identidad.lif_dta_mtime identidad.lif_observado_hasta identidad.pef_dta_mtime identidad.pef_cp identidad.pef_pef identidad.pef_ppef identidad.enigh)
	local enigh "`r(v13)'"
	if "`enigh'" == "" {
		di as err "FederacionNL: el sello no trae identidad.enigh (vintage de la incidencia); hay que re-sellar en el Mac (NL-0.4.1). No se exporta."
		exit 459
	}
	local s_vnl "`r(v1)'"
	local s_vmotor "`r(v2)'"
	local s_pe "`r(v3)'"
	local s_gen `"`r(v4)'"'
	local ent_gen `"`r(v5)'"'
	local ent_sha "`r(v6)'"
	local lif_mtime "`r(v7)'"
	local lif_ult = `r(v8)'
	local pef_mtime "`r(v9)'"
	local pef_cp "`r(v10)'"
	local pef_pef "`r(v11)'"
	local pef_ppef "`r(v12)'"
	if "`s_vnl'" != "`nl_vnl'" | "`s_vmotor'" != "`nl_vmotor'" | "`s_pe'" != "`aniope'" {
		di as err "FederacionNL: el sello es de la capa `s_vnl' / motor `s_vmotor' / PE `s_pe' y la sesión es `nl_vnl' / `nl_vmotor' / `aniope'. Hay que re-sellar en el Mac. No se exporta."
		exit 459
	}
	quietly {
		_NLjsonarr using `"`sello'"', array(participaciones) fields(impuesto part partS1 partS2 partS3 recNac recNL)
		tempfile PART
		save `PART'
		_NLjsonarr using `"`sello'"', array(recaudacion) fields(anio impuesto mes observado lif)
		g tipoPaga = cond(mes == 12, "observado", cond(mes < 12, "parcial", "sin dato"))
		tempfile REC
		save `REC'
		_NLjsonarr using `"`sello'"', array(anclas) fields(anio divFEDE fuente nl nacional nodist)
		tempfile ANC
		save `ANC'
	}
	local sello_desc "sello de corrida (sin cachés del motor en esta máquina)"
	local sello_gen_use `"`s_gen'"'
	noisily di in g "  Compuerta 5 (sello compatible: capa `s_vnl', motor `s_vmotor', PE `s_pe'): " in y "PASÓ" in g " (sello de `s_gen')."
}

*** 4 SERIES ANUALES: RECIBE, ANCLAS, PAGA, BALANZA Y TRANSFORMACIONES ***
noisily di _newline in g "{bf:4. Series anuales `anio0'-`aniope'}"
quietly {
	* 4.1 Anclas en ancho *
	use `ANC', clear
	g key = cond(divFEDE == "Participaciones", "R28", cond(divFEDE == "Aportaciones", "R33", ///
		cond(divFEDE == "Convenios", "Conv", cond(divFEDE == "Subsidios", "Subs", "Salud"))))
	drop divFEDE nodist
	rename (nl nacional) (ancla anclaNac)
	reshape wide ancla anclaNac, i(anio fuente) j(key) string
	rename fuente fuenteAncla
	egen double anclaTot = rowtotal(anclaR28 anclaR33 anclaConv anclaSubs anclaSalud)
	egen double anclaNacTot = rowtotal(anclaNacR28 anclaNacR33 anclaNacConv anclaNacSubs anclaNacSalud)
	tempfile ANCw
	save `ANCw'

	* 4.2 Paga en ancho: part × recaudación (observada y LIF) *
	use `REC', clear
	merge m:1 impuesto using `PART', nogen keep(match) keepusing(part partS1 partS3 recNac)
	g double paga = part*observado
	g double pagaLif = part*lif
	g double pagaS1 = partS1*observado
	g double pagaS3 = partS3*observado
	g double pagaLifS1 = partS1*lif
	g double pagaLifS3 = partS3*lif
	g double recNacObs = observado
	g double recNacLif = lif
	keep anio impuesto mes tipoPaga paga pagaLif pagaS1 pagaS3 pagaLifS1 pagaLifS3 recNacObs recNacLif
	reshape wide paga pagaLif pagaS1 pagaS3 pagaLifS1 pagaLifS3 recNacObs recNacLif mes tipoPaga, i(anio) j(impuesto) string
	local mesvars ""
	local tipovars ""
	foreach x in `impuestos' `extras' {
		local mesvars `mesvars' mes`x'
		local tipovars `tipovars' tipoPaga`x'
	}
	egen int mesPaga = rowmin(`mesvars')
	g tipoPaga = cond(mesPaga == 12, "observado", cond(mesPaga < 12 & mesPaga != ., "parcial", "sin dato"))
	drop `mesvars' `tipovars'
	* Totales: impuestos stricto sensu; S1/S3 sustituyen solo el ISR PM *
	foreach s in "" Lif {
		egen double paga`s'S0 = rowtotal(paga`s'ISRAS paga`s'ISRPF paga`s'ISRPM paga`s'IVA paga`s'IEPSNP paga`s'IEPSP paga`s'ISAN paga`s'IMPORT)
		g double paga`s'S1t = paga`s'S0 - paga`s'ISRPM + paga`s'S1ISRPM
		g double paga`s'S3t = paga`s'S0 - paga`s'ISRPM + paga`s'S3ISRPM
	}
	egen double recNacS0 = rowtotal(recNacObsISRAS recNacObsISRPF recNacObsISRPM recNacObsIVA recNacObsIEPSNP recNacObsIEPSP recNacObsISAN recNacObsIMPORT)
	egen double recNacLifS0 = rowtotal(recNacLifISRAS recNacLifISRPF recNacLifISRPM recNacLifIVA recNacLifIEPSNP recNacLifIEPSP recNacLifISAN recNacLifIMPORT)
	drop pagaS1ISRAS pagaS1ISRPF pagaS1IVA pagaS1IEPSNP pagaS1IEPSP pagaS1ISAN pagaS1IMPORT pagaS1CUOTAS pagaS1OTROSK ///
		pagaS3ISRAS pagaS3ISRPF pagaS3IVA pagaS3IEPSNP pagaS3IEPSP pagaS3ISAN pagaS3IMPORT pagaS3CUOTAS pagaS3OTROSK ///
		pagaLifS1ISRAS pagaLifS1ISRPF pagaLifS1IVA pagaLifS1IEPSNP pagaLifS1IEPSP pagaLifS1ISAN pagaLifS1IMPORT pagaLifS1CUOTAS pagaLifS1OTROSK ///
		pagaLifS3ISRAS pagaLifS3ISRPF pagaLifS3IVA pagaLifS3IEPSNP pagaLifS3IEPSP pagaLifS3ISAN pagaLifS3IMPORT pagaLifS3CUOTAS pagaLifS3OTROSK
	rename (pagaS1t pagaS3t pagaLifS1t pagaLifS3t) (pagaS1 pagaS3 pagaLifS1 pagaLifS3)
	replace pagaS0 = . if tipoPaga == "sin dato"
	replace pagaS1 = . if tipoPaga == "sin dato"
	replace pagaS3 = . if tipoPaga == "sin dato"
	replace recNacS0 = . if tipoPaga == "sin dato"
	tempfile PAGw
	save `PAGw'

	* 4.3 Tabla maestra anual *
	use `R', clear
	merge 1:1 anio using `ANCw', nogen
	merge 1:1 anio using `PAGw', nogen
	merge 1:1 anio using `PIBE', nogen keep(master match)
	merge 1:1 anio using `POBnl', nogen keep(master match)
	merge 1:1 anio using `POBnac', nogen keep(master match)
	keep if anio >= `anio0' & anio <= `aniope'
	sort anio
	tsset anio
	if r(tmax) - r(tmin) + 1 != _N {
		noisily di as err "FederacionNL: la tabla anual tiene huecos. No se exporta."
		exit 459
	}
	* Población en todos los años; PIBE y deflactor desde que existe el PIBE (`pibe0'): antes, reales y % PIBE quedan vacíos y se declara *
	count if pobNL == . | pobNac == . | ((pibeNnl == . | deflatornl == .) & anio >= `pibe0')
	if r(N) > 0 {
		noisily list anio pobNL pobNac pibeNnl deflatornl if pobNL == . | pobNac == . | ((pibeNnl == . | deflatornl == .) & anio >= `pibe0'), noobs clean
		noisily di as err "FederacionNL: denominadores faltantes en la tabla anual. No se exporta."
		exit 459
	}
	replace tipoRecibe = "sin dato" if tipoRecibe == ""
	replace tipoPaga = "sin dato" if tipoPaga == ""
	* Recibe del Paquete (PEF/PPEF por entidad) para el año de política y el año en curso *
	g double recibePaq = anclaTot if inlist(fuenteAncla, "PEF", "PPEF")
	g double recibePaqNac = anclaNacTot if inlist(fuenteAncla, "PEF", "PPEF")
	* Balanza observada (ambos lados completos) y del Paquete (PEF/PPEF vs LIF/ILIF) *
	foreach s in S0 S1 S3 {
		g double balanza`s' = nlTot - paga`s' if tipoRecibe == "observado" & tipoPaga == "observado"
		g double balanzaPaq`s' = recibePaq - pagaLif`s' if recibePaq != .
	}
	g tipoBalanza = cond(balanzaS0 != ., "observado", cond(balanzaPaqS0 != ., "Paquete", "sin dato"))
	* Compuerta 2: ancla CP vs EOFP (años completos con CP) *
	g double rdR28 = reldif(anclaR28, nlR28) if fuenteAncla == "CP" & tipoRecibe == "observado"
	g double rdR33 = reldif(anclaR33, nlR33) if fuenteAncla == "CP" & tipoRecibe == "observado"
	g double difConv = (anclaConv + anclaSubs + anclaSalud)/(nlCD + nlCR + nlR23 + nlPSS) - 1 if fuenteAncla == "CP" & tipoRecibe == "observado"
	summarize rdR28, meanonly
	local rdR28max = r(max)
	summarize rdR33, meanonly
	local rdR33max = r(max)
	summarize difConv, meanonly
	local difConvMin = r(min)
	local difConvMax = r(max)
	count if rdR28 > 1e-3 & rdR28 != .
	local f28 = r(N)
	count if rdR33 > 0.025 & rdR33 != .
	local f33 = r(N)
	levelsof anio if rdR28 != ., clean
	local anclaAnios "`r(levels)'"
	tempfile T
	save `T'
}
if `f28' > 0 | `f33' > 0 {
	noisily list anio nlR28 anclaR28 rdR28 nlR33 anclaR33 rdR33 if rdR28 > 1e-3 | rdR33 > 0.025, noobs clean
	di as err "FederacionNL: la ancla de Cuenta Pública no reproduce la Estadística Oportuna (R28 > 0.1 % en `f28' años; R33 > 2.5 % en `f33'). No se exporta."
	exit 459
}
noisily di in g "  Compuerta 2 (ancla CP `=word("`anclaAnios'",1)'-`=word("`anclaAnios'",wordcount("`anclaAnios'"))'): " in y "PASÓ" in g " — R28 reldif máx " in y %8.2e `rdR28max' in g " (tol 1e-3); R33 " in y %6.4f `rdR33max' in g " (tol 0.025); convenios+subsidios CP vs EOFP entre " in y %6.3f `difConvMin' in g " y " in y %6.3f `difConvMax' in g " (informativo)."

** 4.4 Transformaciones: per cápita, real (deflactor implícito PIBE NL), % PIBE; comparativo nacional per cápita **
quietly {
	use `T', clear
	local nivelesNL nlR28 nlR33 nlCD nlCR nlR23 nlPSS nlTot pagaS0 pagaS1 pagaS3 pagaCUOTAS pagaOTROSK balanzaS0 balanzaS1 balanzaS3 ///
		pagaLifS0 pagaLifS1 pagaLifS3 pagaLifCUOTAS recibePaq balanzaPaqS0 balanzaPaqS1 balanzaPaqS3 anclaTot ///
		pagaISRAS pagaISRPF pagaISRPM pagaIVA pagaIEPSNP pagaIEPSP pagaISAN pagaIMPORT
	foreach v of local nivelesNL {
		g double `v'Pc = `v'/pobNL
		g double `v'R = `v'/deflatornl
		g double `v'PIBE = `v'/pibeNnl*100
	}
	local nivelesNac nacR28 nacR33 nacCD nacCR nacR23 nacPSS nacTot recNacS0 recNacLifS0 recibePaqNac
	foreach v of local nivelesNac {
		g double `v'Pc = `v'/pobNac
	}
	g double partRecibe = nlTot/nacTot*100
	g double partPaga = pagaS0/recNacS0*100
	tempfile T
	save `T'
}

** 4.5 Lugar de NL entre las 32 entidades, per cápita (R28, R33, total), por año **
quietly {
	use `A', clear
	keep if inlist(fondo, "XAC28", "XAC33", "XACGF") & anio >= `anio0' & ent != "00" & ent != "33"
	merge m:1 anio ent using `POB', keep(match) nogen
	g double pc = monto/pob
	egen nE = count(pc), by(anio fondo)
	bysort anio fondo (pc): g lugar = nE - _n + 1 if pc != .		// 1 = mayor per cápita entre las 32
	keep if ent == "19"
	g key = cond(fondo == "XAC28", "R28", cond(fondo == "XAC33", "R33", "Tot"))
	keep anio key lugar
	reshape wide lugar, i(anio) j(key) string
	merge 1:1 anio using `T', nogen
	sort anio
	tempfile T
	save `T'
}

** 4.6 Subfondos: NL, nacional, participación, per cápita y lugar por año **
quietly {
	use `A', clear
	g byte sub = 0
	foreach f of local subfondos {
		replace sub = 1 if fondo == "`f'"
	}
	keep if sub & anio >= `anio0' & ent != "33"
	merge m:1 anio ent using `POB', keep(match master) nogen
	g double pc = monto/pob
	g double pcE = pc if ent != "00"
	egen nE = count(pcE), by(anio fondo)
	bysort anio fondo (pcE): g lugar = nE - _n + 1 if pcE != .		// 1 = mayor per cápita entre las 32
	g double nac = monto if ent == "00"
	egen double nacT = max(nac), by(anio fondo)
	g double pcNac = nacT/pob if ent == "00"
	egen double pcNacT = max(pcNac), by(anio fondo)
	keep if ent == "19"
	rename (monto pc) (nl pcNL)
	g double partNL = nl/nacT*100
	keep anio fondo nl nacT partNL pcNL pcNacT lugar nmeses
	rename (nacT pcNacT) (nac pcNac)
	* Año de inicio del fondo (primer año con dato nacional ≠ 0) *
	g double nz = anio if nac != 0 & nac != .
	egen inicio = min(nz), by(fondo)
	drop nz
	g grupo = cond(substr(fondo, 1, 5) == "XAC28", "R28", cond(substr(fondo, 1, 5) == "XAC33", "R33", cond(substr(fondo, 1, 5) == "XACCD", "CD", "R23")))
	sort fondo anio
	tempfile S
	save `S'
}
noisily di in g "  Series listas: anual `anio0'-`aniope', subfondos (`=wordcount("`subfondos'")'), mensual (24 meses)."

*** 5 CIFRAS DEL AÑO DE REFERENCIA Y DEL AÑO DE POLÍTICA (escalares, registro aditivo) ***
quietly {
	use `T', clear
	summarize anio if tipoBalanza == "observado", meanonly
	local anioref = r(max)								// último año con AMBOS lados observados completos
	summarize anio if tipoRecibe == "parcial", meanonly
	local anioparcial = cond(r(N) > 0, r(max), .)
}
noisily di _newline in g "{bf:5. Cifras: año de referencia " in y "`anioref'" in g " (ambos lados observados) · año de política " in y "`aniope'" in g " (Paquete)}"
capture program drop _nlget
program define _nlget, rclass
	args var anio
	quietly summarize `var' if anio == `anio', meanonly
	return scalar v = cond(r(N) == 0, ., r(mean))
end
quietly {
	use `T', clear
	* Año de referencia *
	foreach v in nlTot nlR28 nlR33 nlCD nlCR nlR23 nlPSS nacTot pagaS0 pagaS1 pagaS3 pagaCUOTAS pagaOTROSK balanzaS0 balanzaS1 balanzaS3 recNacS0 ///
		nlTotPc nacTotPc pagaS0Pc pagaS1Pc pagaS3Pc pagaCUOTASPc balanzaS0Pc balanzaS1Pc balanzaS3Pc recNacS0Pc ///
		nlTotPIBE pagaS0PIBE pagaS1PIBE pagaS3PIBE balanzaS0PIBE balanzaS1PIBE balanzaS3PIBE partRecibe partPaga lugarTot lugarR28 lugarR33 pobNL pobNac pibeNnl deflatornl {
		_nlget `v' `anioref'
		local ref_`v' = r(v)
	}
	* Año de política (Paquete: PPEF/PEF vs ILIF/LIF) *
	foreach v in recibePaq recibePaqNac pagaLifS0 pagaLifS1 pagaLifS3 pagaLifCUOTAS balanzaPaqS0 balanzaPaqS1 balanzaPaqS3 recNacLifS0 ///
		recibePaqPc recibePaqNacPc pagaLifS0Pc pagaLifS1Pc pagaLifS3Pc balanzaPaqS0Pc balanzaPaqS1Pc balanzaPaqS3Pc ///
		recibePaqPIBE pagaLifS0PIBE pagaLifS1PIBE pagaLifS3PIBE balanzaPaqS0PIBE balanzaPaqS1PIBE balanzaPaqS3PIBE fuenteAncla pobNL {
		capture confirm numeric variable `v'
		if _rc == 0 {
			_nlget `v' `aniope'
			local pe_`v' = r(v)
		}
		else {
			levelsof `v' if anio == `aniope', clean
			local pe_`v' "`r(levels)'"
		}
	}
}
* Registro (sin guion bajo; mxn / mxnpc / pctpib / pct / anio / custom) *
escalar anio anioRefFed = `anioref'
escalar anio anioPEFed = `aniope'
escalar anio anioParcialFed = `anioparcial'
escalar custom(%2.0f) mesUltFed = `mes1'
escalar mxn recibeNL = `ref_nlTot'
escalar mxn recibeNac = `ref_nacTot'
escalar mxn recibeR28NL = `ref_nlR28'
escalar mxn recibeR33NL = `ref_nlR33'
escalar mxn recibeConvNL = `ref_nlCD' + `ref_nlCR'
escalar mxn recibeOtrosNL = `ref_nlR23' + `ref_nlPSS'
escalar mxn pagaS0NL = `ref_pagaS0'
escalar mxn pagaS1NL = `ref_pagaS1'
escalar mxn pagaS3NL = `ref_pagaS3'
escalar mxn cuotasIMSSNL = `ref_pagaCUOTAS'
escalar mxn otrosKNL = `ref_pagaOTROSK'
escalar mxn pagaNac = `ref_recNacS0'
escalar mxn balanzaS0NL = `ref_balanzaS0'
escalar mxn balanzaS1NL = `ref_balanzaS1'
escalar mxn balanzaS3NL = `ref_balanzaS3'
escalar mxnpc recibeNLpc = `ref_nlTotPc'
escalar mxnpc recibeNacpc = `ref_nacTotPc'
escalar mxnpc pagaS0NLpc = `ref_pagaS0Pc'
escalar mxnpc pagaS1NLpc = `ref_pagaS1Pc'
escalar mxnpc pagaS3NLpc = `ref_pagaS3Pc'
escalar mxnpc cuotasIMSSNLpc = `ref_pagaCUOTASPc'
escalar mxnpc pagaNacpc = `ref_recNacS0Pc'
escalar mxnpc balanzaS0NLpc = `ref_balanzaS0Pc'
escalar mxnpc balanzaS1NLpc = `ref_balanzaS1Pc'
escalar mxnpc balanzaS3NLpc = `ref_balanzaS3Pc'
escalar pctpib recibeNLpibe = `ref_nlTotPIBE'
escalar pctpib pagaS0NLpibe = `ref_pagaS0PIBE'
escalar pctpib pagaS1NLpibe = `ref_pagaS1PIBE'
escalar pctpib pagaS3NLpibe = `ref_pagaS3PIBE'
escalar pctpib balanzaS0NLpibe = `ref_balanzaS0PIBE'
escalar pctpib balanzaS1NLpibe = `ref_balanzaS1PIBE'
escalar pctpib balanzaS3NLpibe = `ref_balanzaS3PIBE'
escalar pct partRecibeNL = `ref_partRecibe'
escalar pct partPagaNL = `ref_partPaga'
escalar custom(%2.0f) lugarRecibePc = `ref_lugarTot'
escalar custom(%2.0f) lugarR28Pc = `ref_lugarR28'
escalar custom(%2.0f) lugarR33Pc = `ref_lugarR33'
escalar personas pobNLFed = `ref_pobNL'
escalar personas pobNacFed = `ref_pobNac'
escalar mxn pibeNLFed = `ref_pibeNnl'
escalar custom(%8.6f) deflatorNLFed = `ref_deflatornl'
escalar mxn recibePENL = `pe_recibePaq'
escalar mxn recibePENac = `pe_recibePaqNac'
escalar mxn pagaPES0NL = `pe_pagaLifS0'
escalar mxn pagaPES1NL = `pe_pagaLifS1'
escalar mxn pagaPES3NL = `pe_pagaLifS3'
escalar mxn cuotasPENL = `pe_pagaLifCUOTAS'
escalar mxn balanzaPES0NL = `pe_balanzaPaqS0'
escalar mxn balanzaPES1NL = `pe_balanzaPaqS1'
escalar mxn balanzaPES3NL = `pe_balanzaPaqS3'
escalar mxnpc recibePENLpc = `pe_recibePaqPc'
escalar mxnpc recibePENacpc = `pe_recibePaqNacPc'
escalar mxnpc pagaPES0NLpc = `pe_pagaLifS0Pc'
escalar mxnpc pagaPES1NLpc = `pe_pagaLifS1Pc'
escalar mxnpc pagaPES3NLpc = `pe_pagaLifS3Pc'
escalar mxnpc balanzaPES0NLpc = `pe_balanzaPaqS0Pc'
escalar mxnpc balanzaPES1NLpc = `pe_balanzaPaqS1Pc'
escalar mxnpc balanzaPES3NLpc = `pe_balanzaPaqS3Pc'
escalar pctpib recibePENLpibe = `pe_recibePaqPIBE'
escalar pctpib pagaPES0NLpibe = `pe_pagaLifS0PIBE'
escalar pctpib balanzaPES0NLpibe = `pe_balanzaPaqS0PIBE'
escalar pctpib balanzaPES1NLpibe = `pe_balanzaPaqS1PIBE'
escalar pctpib balanzaPES3NLpibe = `pe_balanzaPaqS3PIBE'
local cifras anioRefFed anioPEFed anioParcialFed mesUltFed recibeNL recibeNac recibeR28NL recibeR33NL recibeConvNL recibeOtrosNL ///
	pagaS0NL pagaS1NL pagaS3NL cuotasIMSSNL otrosKNL pagaNac balanzaS0NL balanzaS1NL balanzaS3NL ///
	recibeNLpc recibeNacpc pagaS0NLpc pagaS1NLpc pagaS3NLpc cuotasIMSSNLpc pagaNacpc balanzaS0NLpc balanzaS1NLpc balanzaS3NLpc ///
	recibeNLpibe pagaS0NLpibe pagaS1NLpibe pagaS3NLpibe balanzaS0NLpibe balanzaS1NLpibe balanzaS3NLpibe ///
	partRecibeNL partPagaNL lugarRecibePc lugarR28Pc lugarR33Pc pobNLFed pobNacFed pibeNLFed deflatorNLFed ///
	recibePENL recibePENac pagaPES0NL pagaPES1NL pagaPES3NL cuotasPENL balanzaPES0NL balanzaPES1NL balanzaPES3NL ///
	recibePENLpc recibePENacpc pagaPES0NLpc pagaPES1NLpc pagaPES3NLpc balanzaPES0NLpc balanzaPES1NLpc balanzaPES3NLpc ///
	recibePENLpibe pagaPES0NLpibe balanzaPES0NLpibe balanzaPES1NLpibe balanzaPES3NLpibe

noisily di _newline in g "{bf:  Nuevo León `anioref' — balanza de flujos identificables (año completo observado)}"
noisily di in g "  " _col(34) %14s "mmdp" _col(50) %12s "MXN por hab." _col(64) %9s "% PIBE"
noisily di in g _dup(74) "-"
noisily di in g "  (+) Recibe (R28+R33+conv.+R23+PSS)" _col(34) in y %14.1fc scalar(recibeNL)/1e6 _col(50) in y %12.0fc scalar(recibeNLpc) _col(64) in y %9.3fc scalar(recibeNLpibe)
noisily di in g "      de los cuales R28 / R33" _col(34) in y %14.1fc scalar(recibeR28NL)/1e6 in g " / " in y %10.1fc scalar(recibeR33NL)/1e6
noisily di in g "      per cápita nacional de referencia" _col(50) in y %12.0fc scalar(recibeNacpc) in g "  lugar " in y %2.0f scalar(lugarRecibePc) in g " de 32"
noisily di in g "  (−) Pagan los residentes, S0" _col(34) in y %14.1fc scalar(pagaS0NL)/1e6 _col(50) in y %12.0fc scalar(pagaS0NLpc) _col(64) in y %9.3fc scalar(pagaS0NLpibe)
noisily di in g "      banda [S1, S3]" _col(34) in y "[" %12.1fc scalar(pagaS1NL)/1e6 ", " %12.1fc scalar(pagaS3NL)/1e6 "]"
noisily di in g "  (·) Cuotas IMSS (aparte, no sumadas)" _col(34) in y %14.1fc scalar(cuotasIMSSNL)/1e6 _col(50) in y %12.0fc scalar(cuotasIMSSNLpc)
noisily di in g _dup(74) "-"
noisily di in g "{bf:  (=) Aportación neta en flujos identificables, S0" _col(34) in y %14.1fc scalar(balanzaS0NL)/1e6 _col(50) in y %12.0fc scalar(balanzaS0NLpc) _col(64) in y %9.3fc scalar(balanzaS0NLpibe) "}"
noisily di in g "{bf:      banda [S1, S3]" _col(34) in y "[" %12.1fc scalar(balanzaS3NL)/1e6 ", " %12.1fc scalar(balanzaS1NL)/1e6 "]" in g " mmdp · por habitante [" in y %8.0fc scalar(balanzaS3NLpc) ", " %8.0fc scalar(balanzaS1NLpc) "]}"
noisily di in g "  Participación de NL: recibe " in y %5.2f scalar(partRecibeNL) in g " % del gasto federalizado · paga " in y %5.2f scalar(partPagaNL) in g " % de los impuestos federales"
noisily di _newline in g "  Año de política `aniope' (`pe_fuenteAncla' vs ILIF): recibe " in y %10.1fc scalar(recibePENL)/1e6 in g " · paga S0 " in y %10.1fc scalar(pagaPES0NL)/1e6 in g " [" %8.1fc scalar(pagaPES1NL)/1e6 ", " %8.1fc scalar(pagaPES3NL)/1e6 "]" in g " · neto " in y %10.1fc scalar(balanzaPES0NL)/1e6 in g " mmdp"

*** 6 EXPORTACIÓN JSON ***
noisily di _newline in g "{bf:6. Exportación}"
local json `"`site'/users/$id/nodos/federacion-nl.json"'
local sellocorrida = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
tempname fh
file open `fh' using `"`json'"', write text replace
file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'nl.federacion/v1`q',"' _n
file write `fh' `"  `q'producto`q': `q'`nl_producto'`q',"' _n
file write `fh' `"  `q'titulo`q': `q'`nl_titulo'`q',"' _n
file write `fh' `"  `q'subtitulo`q': `q'`nl_subtitulo'`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
file write `fh' `"  `q'anio_politica`q': `aniope',"' _n
file write `fh' `"  `q'anio_vp`q': `aniovp',"' _n
file write `fh' `"  `q'anio_parcial`q': `=cond(`anioparcial' == ., "null", "`anioparcial'")',"' _n
file write `fh' `"  `q'mes_ultimo`q': `mes1',"' _n
file write `fh' `"  `q'alcance`q': {"' _n
file write `fh' `"    `q'declarado`q': `q'balanza de flujos identificables`q',"' _n
file write `fh' `"    `q'leyenda`q': `q'Flujos identificables: gasto federalizado pagado a Nuevo León (participaciones R28, aportaciones R33, convenios de descentralización y reasignación, gasto federalizado del R23 y recursos para protección social en salud) menos impuestos federales pagados por los residentes de Nuevo León según la incidencia del Simulador. Excluye el gasto federal directo ejercido en NL (pensiones contributivas, IMSS/ISSSTE, CFE, inversión física federal, sueldos federales) — fase futura. Por simetría, las cuotas IMSS se muestran aparte y no se suman: su contraparte de gasto (IMSS) está fuera del alcance.`q',"' _n
file write `fh' `"    `q'incluye_recibe`q': [`q'R28`q', `q'R33`q', `q'CD`q', `q'CR`q', `q'R23`q', `q'PSS`q'],"' _n
file write `fh' `"    `q'incluye_paga`q': [`q'ISRAS`q', `q'ISRPF`q', `q'ISRPM`q', `q'IVA`q', `q'IEPSNP`q', `q'IEPSP`q', `q'ISAN`q', `q'IMPORT`q'],"' _n
file write `fh' `"    `q'aparte_no_sumado`q': [`q'CUOTAS`q', `q'OTROSK`q'],"' _n
file write `fh' `"    `q'excluye`q': `q'gasto federal directo ejercido en NL: pensiones contributivas, IMSS/ISSSTE patronal, CFE, inversión física federal directa, sueldos federales; petroleros y no tributarios no atribuibles (derechos/ISR Pemex, aprovechamientos) fuera del lado paga`q',"' _n
file write `fh' `"    `q'nodo_saldo`q': `q'aportación neta en flujos identificables`q'"' _n
file write `fh' "  }," _n
file write `fh' `"  `q'procedencia`q': {"' _n
file write `fh' `"    `q'version_motor`q': `q'`nl_vmotor'`q',"' _n
file write `fh' `"    `q'version_capa_nl`q': `q'`nl_vnl'`q',"' _n
file write `fh' `"    `q'repositorio`q': `q'`nl_repo'`q',"' _n
file write `fh' `"    `q'driver`q': `q'01_modulos/FederacionNL.do v1.1.0`q',"' _n
file write `fh' `"    `q'log`q': `q'`logfile'`q',"' _n
file write `fh' `"    `q'generado_en`q': `q'`sellocorrida'`q',"' _n
file write `fh' `"    `q'modo`q': `q'`modo'`q',"' _n
file write `fh' `"    `q'frontera`q': `q'producto de la capa NL sobre el canal del motor: lector propio de SHCP para el lado recibe; incidencia de EntidadNL.do y recaudación LIF.dta para el lado paga; el motor no se modifica`q',"' _n
file write `fh' `"    `q'fuentes`q': ["' _n
_nltxt `"`eopf_lastmod'"'
file write `fh' `"      {`q'id`q': `q'eopf_transferencias`q', `q'fuente`q': `q'SHCP, Estadísticas Oportunas de Finanzas Públicas, datos abiertos: transferencias_entidades_fed.zip + _hist.zip (flujo pagado, mensual, por fondo y entidad)`q', `q'lector`q': `q'_NLeopf (nl-assets/nl-fed.do)`q', `q'descarga`q': `q'`eopf_fecha'`q', `q'last_modified`q': `q'`r(t)'`q', `q'periodo_final`q': `q'`eopf_pf'`q', `q'n`q': `eopf_n', `q'checksum`q': `eopf_chk'},"' _n
file write `fh' `"      {`q'id`q': `q'pef_dta`q', `q'fuente`q': `q'SHCP/Transparencia Presupuestaria, Cuenta Pública (ejercido) por entidad y divFEDE; PEF aprobado y PPEF proyecto para el año de política; master/PEF.dta del motor (UpdatePEF, assets del sidecar)`q', `q'vintage`q': `q'`pef_mtime'`q', `q'cp`q': `q'`pef_cp'`q', `q'pef`q': `q'`pef_pef'`q', `q'ppef`q': `q'`pef_ppef'`q', `q'via`q': `q'`sello_desc'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'lif_dta`q', `q'fuente`q': `q'recaudación observada por impuesto (divSIM) y LIF/ILIF; master/LIF.dta del motor (UpdateLIF vía DatosAbiertos)`q', `q'vintage`q': `q'`lif_mtime'`q', `q'observado_hasta`q': `lif_ult', `q'via`q': `q'`sello_desc'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'entidad_nl`q', `q'fuente`q': `q'statajson_entidad-nl.json (EntidadNL.do sobre SIM.do): participación de NL en cada impuesto por incidencia micro (ENIGH), banda S1/S3 del ISR PM`q', `q'generado_en`q': `q'`ent_gen'`q', `q'sha256`q': `q'`ent_sha'`q', `q'via`q': `q'`sello_desc'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'sello`q', `q'fuente`q': `q'01_modulos/nl-assets/federacion-sello.json`q', `q'generado_en`q': `q'`sello_gen_use'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'poblacion`q', `q'fuente`q': `q'CONAPO (pry23) vía master/Poblacion.dta, la misma de PoblacionNL.do; 32 entidades + nacional`q', `q'vintage`q': `q'`pob_mtime'`q', `q'poblacion_nl_json`q': `q'`pobj_gen'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'actividad`q', `q'fuente`q': `q'actividad-nl.json (PIBDeflactorNL.do): PIBE nominal NL y nacional y deflactor implícito del PIBE NL base `aniovp' = 1, con tipo por año`q', `q'generado_en`q': `q'`actj_gen'`q'}"' _n
file write `fh' "    ]," _n
file write `fh' `"    `q'compuertas`q': {"' _n
file write `fh' `"      `q'suma32`q': `q'Σ 32 entidades + No distribuible = total nacional por fondo y año `anio0'-`anio1', tolerancia 1e-4; reldif máx `=string(`rdmax', "%9.2e")'`q',"' _n
file write `fh' `"      `q'ancla_cp`q': `q'R28 EOFP = Cuenta Pública (PEF.dta) con reldif máx `=string(`rdR28max', "%8.2e")' (tol 1e-3); R33 reldif máx `=string(`rdR33max', "%6.4f")' (tol 0.025); convenios+subsidios+salud CP vs CD+CR+R23+PSS EOFP entre `=string(`difConvMin', "%6.3f")' y `=string(`difConvMax', "%6.3f")' (informativo: clasificaciones distintas); años `=word("`anclaAnios'",1)'-`=word("`anclaAnios'",wordcount("`anclaAnios'"))'`q',"' _n
file write `fh' `"      `q'recaudacion_motor`q': `q'lado paga con master/LIF.dta (no re-descargada); Rec<X>nac de EntidadNL = ILIF `aniope' del motor, reldif 1e-6, 10 impuestos`q',"' _n
file write `fh' `"      `q'part_igual_rec`q': `q'Part<X>nl = Rec<X>nl/Rec<X>nac recalculado, reldif 1e-9`q',"' _n
file write `fh' `"      `q'vintage`q': `q'EntidadNL/sello, poblacion-nl.json y actividad-nl.json con la misma versión de capa (`nl_vnl'), motor (`nl_vmotor') y año de política (`aniope') que la sesión; modo `modo'`q',"' _n
file write `fh' `"      `q'rejillas`q': `q'anual `anio0'-`anio1' seis agregados NL y nacional sin huecos (0 solo donde el nacional es 0); mensual 24 meses sin huecos`q',"' _n
file write `fh' `"      `q'identidad_gf`q': `q'total gasto federalizado SHCP = R28+R33+CD+CR+R23+PSS, nacional y NL, reldif máx `=string(`rdGF', "%9.2e")' (tol 1e-6)`q',"' _n
file write `fh' `"      `q'denominador`q': `q'población `pobj_anio' de master/Poblacion.dta = poblacion-nl.json de la misma corrida (NL y nacional, reldif 1e-9); Σ 32 entidades = nacional en todos los años`q'"' _n
file write `fh' "    }," _n
file write `fh' `"    `q'supuestos`q': {"' _n
file write `fh' `"      `q'incidencia_fija`q': `q'la participación de NL en cada impuesto (Part<X>nl, corrida PE `aniope' sobre ENIGH) se aplica a la recaudación observada de cada año: retropolación de incidencia, no serie observada; tipo = incidencia fija`q',"' _n
file write `fh' `"      `q'paga_definicion`q': `q'pesos pagados por residentes = Part<X>nl × recaudación nacional observada del impuesto (LIF.dta); nunca recaudación por domicilio fiscal`q',"' _n
file write `fh' `"      `q'banda`q': `q'S1 y S3 sustituyen solo el ISR PM (prorrateo a capital sin cut-off; pago esperado p×potencial); S0 = método vigente, dentro de la banda; los totales y la balanza se reportan como [S1, S3] con S0 marcado`q',"' _n
file write `fh' `"      `q'deflactor`q': `q'reales con el deflactor implícito del PIBE NL (actividad-nl.json), base `aniovp' = 1; coherente con % PIBE y con la convención fiscal del motor; el INPC no se usa en flujos fiscales`q',"' _n
file write `fh' `"      `q'poblacion`q': `q'per cápita con población CONAPO a mitad de año (master/Poblacion.dta), no la ENIGH expandida de EntidadNL (Pobnl)`q',"' _n
file write `fh' `"      `q'anio_parcial`q': `q'el año en curso lleva EOFP acumulado al mes `mes1' (tipoRecibe parcial) y recaudación acumulada (tipoPaga parcial): no se calcula balanza observada; se calcula balanza del Paquete (PEF aprobado vs LIF)`q',"' _n
file write `fh' `"      `q'paquete`q': `q'año de política: recibe = PPEF/PEF por entidad (PEF.dta, divFEDE); paga = Part<X>nl × ILIF; etiquetado Paquete`q',"' _n
file write `fh' `"      `q'anio_referencia`q': `q'último año con ambos lados observados completos (12 meses EOFP y recaudación a diciembre)`q',"' _n
file write `fh' `"      `q'participaciones_por_anio`q': `q'participaciones estimadas con ENIGH `enigh' (corrida PE `aniope'), supuestas constantes en todos los años (metodo = constante); el arreglo participacionesAnual lleva una fila por año con enigh/metodo para que, cuando existan estimaciones por ENIGH bienal, cambien los datos y no el HTML`q',"' _n
file write `fh' `"      `q'ieps_petrolero_negativo`q': `q'cuando el IEPS a gasolinas es negativo (estímulo fiscal) el paga de ese renglón es negativo ese año; se declara, no se trunca`q'"' _n
file write `fh' "    }" _n
file write `fh' "  }," _n

** 6.1 Definiciones: fondos, subfondos, impuestos, escenarios, tipos, denominadores **
file write `fh' `"  `q'definiciones`q': {"' _n
file write `fh' `"    `q'fondos`q': {"' _n
local i = 0
foreach f of local agregados {
	local ++i
	_nltxt `"`nom`f''"'
	file write `fh' `"      `q'`k`f''`q': {`q'clave`q': `q'`f'`q', `q'nombre`q': `q'`r(t)'`q'}`=cond(`i' < wordcount("`agregados'"), ",", "")'"' _n
}
file write `fh' "    }," _n
file write `fh' `"    `q'subfondos`q': ["' _n
quietly {
	use `S', clear
	keep fondo grupo inicio
	duplicates drop
	sort fondo
}
forvalues i = 1/`=_N' {
	_nltxt `"`nom`=fondo[`i']''"'
	file write `fh' `"      {`q'clave`q': `q'`=fondo[`i']'`q', `q'grupo`q': `q'`=grupo[`i']'`q', `q'nombre`q': `q'`r(t)'`q', `q'inicio`q': `=cond(inicio[`i'] == ., "null", string(inicio[`i']))'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "    ]," _n
file write `fh' `"    `q'impuestos`q': {`q'ISRAS`q': `q'ISR a asalariados`q', `q'ISRPF`q': `q'ISR de personas físicas`q', `q'ISRPM`q': `q'ISR de personas morales`q', `q'IVA`q': `q'IVA`q', `q'IEPSNP`q': `q'IEPS no petrolero`q', `q'IEPSP`q': `q'IEPS petrolero (gasolinas)`q', `q'ISAN`q': `q'ISAN`q', `q'IMPORT`q': `q'impuestos a la importación`q', `q'CUOTAS`q': `q'cuotas IMSS (aparte, no sumadas)`q', `q'OTROSK`q': `q'productos, derechos y aprovechamientos (aparte, no sumados)`q'},"' _n
file write `fh' `"    `q'escenarios`q': {`q'S0`q': `q'método vigente: ISR PM a perceptores de ingreso de capital con ranking probit y cut-off LIF`q', `q'S1`q': `q'cota inferior: ISR PM prorrateado a ingreso de capital sin cut-off`q', `q'S3`q': `q'cota superior: pago esperado = p(probit) × impuesto potencial`q'},"' _n
file write `fh' `"    `q'tipo`q': {`q'observado`q': `q'año completo publicado (12 meses EOFP; recaudación a diciembre)`q', `q'parcial`q': `q'año en curso acumulado al último mes publicado`q', `q'Paquete`q': `q'PEF/PPEF por entidad vs LIF/ILIF: cifras del Paquete Económico, no observadas`q', `q'incidencia fija`q': `q'participación de NL de la corrida vigente aplicada a otro año`q', `q'sin dato`q': `q'sin fuente para ese año`q'},"' _n
file write `fh' `"    `q'denominadores`q': {`q'pobNL`q': `q'población NL a mitad de año, CONAPO (master/Poblacion.dta)`q', `q'pobNac`q': `q'población nacional, misma fuente`q', `q'pibeNnl`q': `q'PIBE nominal NL en pesos (actividad-nl.json; tipo por año)`q', `q'deflatornl`q': `q'deflactor implícito PIBE NL, `aniovp' = 1`q'},"' _n
file write `fh' `"    `q'unidades`q': {`q'niveles`q': `q'pesos corrientes`q', `q'Pc`q': `q'pesos corrientes por habitante`q', `q'R`q': `q'pesos de `aniovp' (deflactor implícito PIBE NL)`q', `q'PIBE`q': `q'% del PIBE nominal de NL`q', `q'lugar`q': `q'posición de NL entre las 32 entidades por monto per cápita (1 = mayor)`q'}"' _n
file write `fh' "  }," _n

** 6.2 Presentación: patrones del canon (nl-estilo.md) y tokens parametrizados **
file write `fh' `"  `q'presentacion`q': {"' _n
file write `fh' `"    `q'registro_default`q': `q'pc`q',"' _n
file write `fh' `"    `q'patrones`q': ["' _n
file write `fh' `"      {`q'vista`q': `q'tarjetas`q', `q'patron`q': `q'familia per cápita del motor (PIBDeflactor pib_pc, GastoPC, columna MXN PC de PEF/LIF); doctrina de registro nl-estilo.md §1`q'},"' _n
file write `fh' `"      {`q'vista`q': `q'balanza_sankey`q', `q'patron`q': `q'Sankey Sistema Fiscal (SankeySF.do + SankeySumSim.ado): nodo central, flujos de ida y vuelta, saldo como nodo visible; precedente bidireccional SankeyPemex/CFE`q'},"' _n
file write `fh' `"      {`q'vista`q': `q'balanza_serie`q', `q'patron`q': `q'barras del nivel + variación punteada con tramos observado/Paquete/proyección (PIBDeflactor pib_pc; SHRFSP xline antes del Paquete); banda = fintensity del motor`q'},"' _n
file write `fh' `"      {`q'vista`q': `q'recibe`q', `q'patron`q': `q'barras apiladas por año con grupos de mayor a menor y agrupación de los menores (LIF/PEF graph bar over(resumido, sort(1) descending) over(anio) stack asyvars; highlight atenúa al 30 %)`q'},"' _n
file write `fh' `"      {`q'vista`q': `q'paga`q', `q'patron`q': `q'tabla de conciliación (+)/(−)/(=) de LIF/PEF con renglón (·) aparte para cuotas IMSS; barras apiladas por impuesto; banda [S1, S3] sombreada`q'}"' _n
file write `fh' "    ]," _n
file write `fh' `"    `q'tokens`q': `q'parametrizados en nl-assets/nl-datos.js (NLEstilo); los colores definitivos se fijan tras la pasada de estilo de nl-estilo.md`q',"' _n
file write `fh' `"    `q'letrero_alcance`q': `q'Balanza de flujos identificables: excluye el gasto federal directo ejercido en NL (pensiones contributivas, IMSS/ISSSTE, CFE, inversión física federal, sueldos federales). Cuotas IMSS aparte, no sumadas, por simetría.`q',"' _n
file write `fh' `"    `q'nodo_saldo`q': `q'aportación neta en flujos identificables`q'"' _n
file write `fh' "  }," _n

** 6.3 Cifras (escalares del año de referencia y del año de política) **
file write `fh' `"  `q'cifras`q': {"' _n
local n : word count `cifras'
local j = 0
foreach s of local cifras {
	local ++j
	_nlnum "scalar(`s')"
	file write `fh' `"    `q'`s'`q': `r(n)'`=cond(`j' < `n', ",", "")'"' _n
}
file write `fh' `"    , `q'fuenteAnclaPE`q': `q'`pe_fuenteAncla'`q'"' _n
file write `fh' "  }," _n

** 6.4 Participaciones por impuesto (insumo del lado paga) **
quietly use `PART', clear
file write `fh' `"  `q'participaciones`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'impuesto`q': `q'`=impuesto[`i']'`q'"'
	foreach v in part partS1 partS2 partS3 recNac recNL {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

** 6.4b Participaciones por año (estructura estable: hoy constantes = corrida vigente, con su vintage ENIGH) **
quietly {
	use `PART', clear
	foreach x in `impuestos' `extras' {
		summarize part if impuesto == "`x'", meanonly
		local pa`x' = r(mean)
	}
	summarize partS1 if impuesto == "ISRPM", meanonly
	local paS1 = r(mean)
	summarize partS2 if impuesto == "ISRPM", meanonly
	local paS2 = r(mean)
	summarize partS3 if impuesto == "ISRPM", meanonly
	local paS3 = r(mean)
	use `T', clear
}
file write `fh' `"  `q'participacionesAnual`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'enigh`q': `enigh', `q'metodo`q': `q'constante`q'"'
	foreach x in `impuestos' `extras' {
		_nlnum "`pa`x''"
		file write `fh' `", `q'`x'`q': `r(n)'"'
	}
	foreach sfx in S1 S2 S3 {
		_nlnum "`pa`sfx''"
		file write `fh' `", `q'ISRPM`sfx'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

** 6.5 Series: anual **
quietly use `T', clear
file write `fh' `"  `q'anual`q': ["' _n
local vars nmeses nlR28 nlR33 nlCD nlCR nlR23 nlPSS nlTot nacR28 nacR33 nacCD nacCR nacR23 nacPSS nacTot ///
	anclaR28 anclaR33 anclaConv anclaSubs anclaSalud anclaTot anclaNacR28 anclaNacR33 anclaNacConv anclaNacSubs anclaNacSalud anclaNacTot rdR28 rdR33 difConv ///
	recibePaq recibePaqNac mesPaga pagaISRAS pagaISRPF pagaISRPM pagaIVA pagaIEPSNP pagaIEPSP pagaISAN pagaIMPORT pagaCUOTAS pagaOTROSK pagaS0 pagaS1 pagaS3 ///
	pagaLifISRAS pagaLifISRPF pagaLifISRPM pagaLifIVA pagaLifIEPSNP pagaLifIEPSP pagaLifISAN pagaLifIMPORT pagaLifCUOTAS pagaLifOTROSK pagaLifS0 pagaLifS1 pagaLifS3 ///
	recNacS0 recNacLifS0 recNacObsISRAS recNacObsISRPF recNacObsISRPM recNacObsIVA recNacObsIEPSNP recNacObsIEPSP recNacObsISAN recNacObsIMPORT recNacObsCUOTAS recNacObsOTROSK balanzaS0 balanzaS1 balanzaS3 balanzaPaqS0 balanzaPaqS1 balanzaPaqS3 ///
	pobNL pobNac pibeNnl pibeNnac deflatornl deflatornac partRecibe partPaga lugarR28 lugarR33 lugarTot
foreach v of local nivelesNL {
	local vars `vars' `v'Pc `v'R `v'PIBE
}
foreach v of local nivelesNac {
	local vars `vars' `v'Pc
}
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'tipoRecibe`q': `q'`=tipoRecibe[`i']'`q', `q'tipoPaga`q': `q'`=tipoPaga[`i']'`q', `q'tipoBalanza`q': `q'`=tipoBalanza[`i']'`q', `q'fuenteAncla`q': `q'`=fuenteAncla[`i']'`q', `q'tipoPIBE`q': `q'`=tipoPIBE[`i']'`q', `q'tipoDefl`q': `q'`=tipoDefl[`i']'`q'"'
	foreach v of local vars {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

** 6.6 Series: subfondos **
quietly use `S', clear
file write `fh' `"  `q'subfondos`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'clave`q': `q'`=fondo[`i']'`q', `q'grupo`q': `q'`=grupo[`i']'`q'"'
	foreach v in nmeses nl nac partNL pcNL pcNac lugar {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

** 6.7 Series: mensual (24 meses) **
quietly use `M', clear
file write `fh' `"  `q'mensual`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'mes`q': `=mes[`i']'"'
	foreach v in nlR28 nlR33 nlCD nlCR nlR23 nlPSS nlTot nacTot {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]" _n
file write `fh' "}" _n
file close `fh'

*** 7 HTML AUTOCONTENIDO (F2: plantilla nl-assets/federacion-nl.html) ***
local tpl `"`site'/01_modulos/nl-assets/federacion-nl.html"'
local html `"`site'/users/$id/nodos/federacion-nl.html"'
capture confirm file `"`tpl'"'
if _rc == 0 {
	run `"`site'/01_modulos/nl-assets/nl-html.do"'
	local js `"`site'/01_modulos/nl-assets/nl-datos.js"'
	capture confirm file `"`js'"'
	if _rc {
		di as err "FederacionNL: falta el componente 01_modulos/nl-assets/nl-datos.js."
		exit 601
	}
	local assets `"`site'/01_modulos/nl-assets/nl-estilo-assets.js"'
	capture confirm file `"`assets'"'
	if _rc {
		di as err "FederacionNL: falta 01_modulos/nl-assets/nl-estilo-assets.js (generar con nl-estilo-build.py)."
		exit 601
	}
	mata: nlhtml_inject(st_local("tpl"), st_local("json"), st_local("js"), st_local("html"), "/*__NLFED_DATA__*/", st_local("assets"))
	if r(hits_data) != 1 | r(hits_js) != 1 | r(hits_assets) != 1 {
		di as err "FederacionNL: la plantilla debe tener exactamente una marca /*__NLFED_DATA__*/, una /*__NL_DATOS_JS__*/ y una /*__NL_ESTILO_ASSETS__*/ (encontradas: `r(hits_data)', `r(hits_js)' y `r(hits_assets)')."
		exit 459
	}
	quietly checksum `"`html'"'
	local kb = string(r(filelen)/1024, "%9.0fc")
	local htmltxt `"`html' (`kb' KB)"'
}
else {
	capture erase `"`html'"'
	local htmltxt "sin plantilla federacion-nl.html en nl-assets (F2 pendiente): solo JSON"
}

*** 8 RESUMEN ***
quietly checksum `"`json'"'
local kbj = string(r(filelen)/1024, "%9.0fc")
noisily di _newline in g "{bf:FederacionNL: listo.}"
noisily di in g "  JSON: " in y `"`json'"' in g " (`kbj' KB)"
noisily di in g "  HTML: " in y `"`htmltxt'"'
noisily di in g "  `nl_titulo' — `nl_subtitulo' · capa `nl_vnl' · modo `modo' · EOFP hasta `eopf_pf' · año de referencia `anioref' · Paquete `aniope'"
quietly log close nlfed
