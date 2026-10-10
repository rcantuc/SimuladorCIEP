*! FederacionNLQuintiles.do  v0.2.0 (C3, sprint NL-0.6.x "Ida y vuelta por quintil") — capa de datos del Sankey ida-y-vuelta por QUINTIL ESTATAL dirigida por la PALETA de flujos (01_modulos/nl-flujos.do): qué flujos entran, de qué lado, si van abiertos, cerrados o solo en inventario, con qué variable se reparten y con qué ancla cierran lo decide Ricardo en la paleta; este driver reparte, cierra, sella y exporta. Contrato hermano: users/$id/nodos/federacion-nl-quintiles.json (esquema nl.federacion-quintiles/v2)
*
* QUÉ ES ESTO (DIAGNOSTICO_NL.md; C1 2026-10-08, C2 2026-10-08, C3 2026-10-09):
*   D1 eje = quintiles ESTATALES (re-ranking dentro de la muestra NL con el criterio exacto de
*      Households.do:2591-2599: ingreso bruto total del hogar per cápita, xtile ponderado por
*      factor/integrantes, todas las personas del hogar heredan el quintil del hogar);
*   C3 (decisión de Ricardo 2026-10-09): el capital SE ABRE por quintil con la distribución que el objeto
*      de incidencia ya trae (conciliada macro-micro); sus limitaciones se MUESTRAN por celda (halo de la
*      banda [S1, S3] y sello concTop1), no lo cierran. El lado recibe se abre con lo que el motor ya
*      distribuyó (perfiles<PE>.dta): esas variables se inventarían TODAS y entran a la página solo cuando
*      Ricardo las enciende en la paleta. Nada se re-imputa.
*   D3 salud: clave = afiliación SSA (inst_6); divergencia con la clave del motor DECLARADA.
*   D4 quintiles en ambos extremos; D5 solo anio_referencia (observado) y anio_politica (Paquete).
*   La PALETA (nl-flujos.do) es el único bloque editable: abrir 0 = inventario (no entra a la página ni al
*   balance), 1 = en página sin abrir (nodo cerrado con sellos), 2 = abierto por quintil (celdas con sellos).
*   Anclas de total por flujo y año: fed:<campo> | eofp:<clave> | pef:[<ramo>/]<pp> | statajson:<escalar> | suma (SUPUESTO).
*   La caja gris se CALCULA: tarjeta recibe − Σ flujos recibe con abrir ≥ 1.
*
* ENTRADAS (solo lectura; CERO descargas; el motor no se modifica):
*   01_modulos/nl-flujos.do                   (paleta de flujos y parámetros)
*   users/$id/aportaciones.dta                (objeto del pipeline, corte entidad 19)
*   master/perfiles<PE>.dta                   (objeto del motor; solo las variables que la paleta pida con perfiles:)
*   users/$id/nodos/statajson_entidad-nl.json (compuertas Q.1–Q.3 y vintage ENIGH; anclas statajson:)
*   users/$id/nodos/federacion-nl.json        (montos por año: paga por impuesto, recibe por fondo; anclas fed:/eofp:)
*   master/PEF.dta                            (PPEF/PEF del año de política por ramo y pp; anclas pef:)
* SALIDA: users/$id/nodos/federacion-nl-quintiles.json + federacion-nl-quintiles.log (gitignored).
*
* COMPUERTAS (abortan):
*   P.0 paleta: ids únicos, lado ∈ {paga, recibe, aparte}, abrir ∈ {0, 1, 2}, variable y anclas parseables; flujos con
*       abrir ≥ 1 con ancla resoluble en ambos años (eofp solo en el observado; statajson con prefijo cargado).
*   Q.0 muestra: n≥umbral personas y hogares por quintil estatal.
*   Q.1 construcción: participación por DECIL estatal de AlTrabajo/AlCapital/AlConsumo/ImpAport/
*       IVA/IEPSNP/IEPSP/ISAN/IMPORT = dis<fam>nle<dec> del statajson (reldif 1e-6, 90 celdas).
*   Q.2 coherencia: Σ <X>_Sim×factor (NL) vs Rec<X>nl del statajson. Causa identificada (C1, q2-diag.log):
*       <X>_Sim = <X> × (<X>PIB/100 × pibY) / ILIF_<X> (TasasEfectivas.ado §7.1): redondeo del parámetro *PIB de
*       SIM.do §4.1 a 3 decimales de % del PIB; cociente uniforme persona a persona. Tol 1e-2, declarado.
*   Q.3 concTop1<X> recalculado = statajson (1e-6).
*   Q.4 identidad: federacion-nl.json y statajson de la MISMA capa y motor entre sí y del motor de la sesión; el
*       hermano hereda la versión de capa de su contrato base (version_capa_nl) y declara la del manifest de la
*       sesión aparte (version_capa_driver): así el hermano se puede regenerar sin re-sellar el contrato base.
*   Q.5 PEF.dta: Σ pp del ramo 33 (entidad 19, año de política) = anclaR33 del JSON (1e-9);
*       pp 13/15 son FONE y pp 2 es FASSA por su descripción (cuando la paleta los usa).
*   Q.6 cierres contables: Σ flujos paga (abiertos + cerrados) = tarjeta paga; Σ aparte = tarjeta cuotas;
*       Σ flujos recibe + caja gris = tarjeta recibe (ambos años, reldif 1e-6); Σ celdas = total por flujo;
*       Σ componentes de la caja gris = caja gris; caja gris ≥ 0 salvo parámetro.
*   Q.7 perfiles<PE>.dta (si la paleta pide perfiles:): mismas personas que aportaciones.dta (folioviv foliohog
*       numren), mismo factor e ingbrutotot (reldif 1e-9); para cada variable presente en ambos objetos se exporta
*       la Σ de cada uno y su reldif (inventario), sin elegir.
*
* USO: do "${SIMROOT}/01_modulos/FederacionNLQuintiles.do"   (tras FederacionNL.do en la misma máquina)
*   global fuentes "AAAA-MM-DD"    -> declara las fuentes congeladas del motor (procedencia)
*   global nlfuentes "AAAA-MM-DD"  -> declara las fuentes congeladas de la capa (procedencia)
* OJO: destruye los datos en memoria y los frames nlq_*.

version 17

*** 0 RAÍZ, LOG, IDENTIDAD ***
SIMroot
local site `"${SIMROOT}"'
if "$id" == "" global id = "`c(username)'"
capture mkdir `"`site'/users"'
capture mkdir `"`site'/users/$id"'
capture mkdir `"`site'/users/$id/nodos"'
local q = char(34)
capture log close nlfq
quietly log using `"`site'/users/$id/nodos/federacion-nl-quintiles.log"', replace text name(nlfq)
capture quietly log query nlfq
if `"`r(filename)'"' == "" {
	di as err "FederacionNLQuintiles: no pudo abrirse el log de procedencia; sin procedencia no hay exportación válida."
	exit 459
}
local logfile "federacion-nl-quintiles.log"
local driver_v "0.2.0"
run `"`site'/01_modulos/nl-assets/nl-identidad.do"'
_NLidentidad, modulo("La Federación y Nuevo León — ida y vuelta por quintil")
local nl_producto `"`r(producto)'"'
local nl_titulo `"`r(titulo)'"'
local nl_subtitulo `"`r(subtitulo)'"'
local nl_vmotor `"`r(version_motor)'"'
local nl_vdriver `"`r(version_nl)'"'
local nl_repo `"`r(repositorio)'"'
if "`nl_vdriver'" == "" | "`nl_vmotor'" == "" {
	di as err "FederacionNLQuintiles: sin versión de capa o de motor declarada. No se exporta."
	exit 459
}
run `"`site'/01_modulos/nl-assets/nl-fed.do"'

* Número a JSON con precisión completa (espejo de _nlnum de FederacionNL.do) *
capture program drop _nlqnum
program define _nlqnum, rclass
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
capture program drop _nlqtxt
program define _nlqtxt, rclass
	gettoken s : 0
	local s = subinstr(`"`s'"', `"""', "'", .)
	local s = subinstr(`"`s'"', "\", "/", .)
	local s = subinstr(`"`s'"', char(10), " ", .)
	local s = subinstr(`"`s'"', char(13), "", .)
	local s = trim(`"`s'"')
	return local t `"`s'"'
end

*** 0.1 PALETA: programas _nlparam / _nlflujo y lectura de nl-flujos.do ***
capture frame drop nlq_pal
frame create nlq_pal int orden str32 id str8 lado byte abrir str80 variable str200 ancla_ref str200 ancla_pe str244 etiqueta str32 grupo byte banda str80 unidad str2045 clave str2045 nota str2045 anclas
global NLQ_npal = 0
global NLQ_params ""
capture program drop _nlparam
program define _nlparam
	gettoken nombre 0 : 0
	gettoken valor 0 : 0
	gettoken marca 0 : 0
	if "`nombre'" == "" | "`valor'" == "" {
		di as err "nl-flujos (P.0): _nlparam requiere <nombre> <valor>."
		exit 198
	}
	global NLQP_`nombre' = `valor'
	global NLQPS_`nombre' = ("`marca'" == "supuesto")
	global NLQ_params "$NLQ_params `nombre'"
end
capture program drop _nlflujo
program define _nlflujo
	gettoken id 0 : 0
	gettoken lado 0 : 0
	gettoken abrir 0 : 0
	gettoken variable 0 : 0
	gettoken ancla_ref 0 : 0
	gettoken ancla_pe 0 : 0
	gettoken etiqueta 0 : 0
	syntax [, GRupo(string) BANda UNidad(string) CLave(string) NOta(string) ANclas(string)]
	if "`id'" == "" | "`lado'" == "" | "`abrir'" == "" | "`variable'" == "" | "`ancla_ref'" == "" | "`ancla_pe'" == "" | `"`etiqueta'"' == "" {
		di as err "nl-flujos (P.0): _nlflujo requiere <id> <lado> <abrir> <variable> <ancla_ref> <ancla_pe> " `"""' "<etiqueta>" `"""' " (flujo `id')."
		exit 198
	}
	if !inlist("`lado'", "paga", "recibe", "aparte") {
		di as err "nl-flujos (P.0): lado '`lado'' del flujo `id' no es paga | recibe | aparte."
		exit 198
	}
	if !inlist("`abrir'", "0", "1", "2") {
		di as err "nl-flujos (P.0): abrir '`abrir'' del flujo `id' no es 0 | 1 | 2."
		exit 198
	}
	global NLQ_npal = $NLQ_npal + 1
	frame post nlq_pal ($NLQ_npal) ("`id'") ("`lado'") (`abrir') ("`variable'") ("`ancla_ref'") ("`ancla_pe'") (`"`etiqueta'"') ("`grupo'") (`=("`banda'" != "")') (`"`unidad'"') (`"`clave'"') (`"`nota'"') (`"`anclas'"')
end
local paleta `"`site'/01_modulos/nl-flujos.do"'
capture confirm file `"`paleta'"'
if _rc {
	di as err "FederacionNLQuintiles: falta la paleta 01_modulos/nl-flujos.do. No se exporta."
	exit 601
}
noisily di _newline in g "{bf:0. Paleta de flujos: 01_modulos/nl-flujos.do}"
run `"`paleta'"'
_NLsha256 `"`paleta'"'
local paleta_sha "`r(sha256)'"
_NLfileinfo `"`paleta'"'
local paleta_mtime "`r(mtime)'"
local NP = $NLQ_npal
if `NP' == 0 {
	di as err "FederacionNLQuintiles (P.0): la paleta no declara ningún flujo. No se exporta."
	exit 459
}
* Parámetros con default (si la paleta no los declara, default marcado supuesto) *
foreach p in umbral_n:100 sello_top1:25 neta_por_quintil:0 gris_negativo:0 {
	local pn = substr("`p'", 1, strpos("`p'", ":") - 1)
	local pv = substr("`p'", strpos("`p'", ":") + 1, .)
	if "${NLQP_`pn'}" == "" {
		global NLQP_`pn' = `pv'
		global NLQPS_`pn' = 1
		global NLQ_params "$NLQ_params `pn'"
	}
}
local umbral = ${NLQP_umbral_n}
local selloTop1 = ${NLQP_sello_top1}
local netaQ = ${NLQP_neta_por_quintil}
local grisNeg = ${NLQP_gris_negativo}
* La paleta a locals: pal_<campo><i> *
frame nlq_pal {
	sort orden
	forvalues i = 1/`NP' {
		foreach c in id lado abrir variable ancla_ref ancla_pe etiqueta grupo banda unidad clave nota anclas {
			local pal_`c'`i' = `c'[`i']
		}
	}
	quietly duplicates report id
	if r(unique_value) != r(N) {
		di as err "FederacionNLQuintiles (P.0): ids repetidos en la paleta. No se exporta."
		exit 459
	}
}
* Parse de variable: fuente:nombre *
local usaPerfiles = 0
forvalues i = 1/`NP' {
	local v "`pal_variable`i''"
	local pos = strpos("`v'", ":")
	if `pos' == 0 {
		di as err "FederacionNLQuintiles (P.0): variable '`v'' del flujo `pal_id`i'' no tiene la forma fuente:nombre."
		exit 459
	}
	local pal_vfuente`i' = substr("`v'", 1, `pos' - 1)
	local pal_vnombre`i' = substr("`v'", `pos' + 1, .)
	if !inlist("`pal_vfuente`i''", "aport", "perfiles", "ind") {
		di as err "FederacionNLQuintiles (P.0): fuente '`pal_vfuente`i''' del flujo `pal_id`i'' no es aport | perfiles | ind."
		exit 459
	}
	if "`pal_vfuente`i''" == "ind" & !inlist("`pal_vnombre`i''", "alum_basica", "afil_ssa") {
		di as err "FederacionNLQuintiles (P.0): indicador '`pal_vnombre`i''' del flujo `pal_id`i'' no está definido (alum_basica | afil_ssa)."
		exit 459
	}
	if "`pal_vfuente`i''" == "perfiles" local usaPerfiles = 1
	local pal_estado`i' = cond(`pal_abrir`i'' == 2, "abierto", cond(`pal_abrir`i'' == 1, "cerrado", "inventario"))
}
noisily di in g "  Paleta: " in y "`NP'" in g " flujos (sha256 `=substr("`paleta_sha'", 1, 12)'…) · parámetros:" in y "$NLQ_params" in g " · umbral n = `umbral' · sello top-1 ≥ `selloTop1' % · neta por quintil = `netaQ' · gris negativo = `grisNeg'"
noisily di in g "  id" _col(16) "lado" _col(24) "estado" _col(36) "variable" _col(62) "ancla observado" _col(88) "ancla Paquete" _col(112) "grupo/banda"
forvalues i = 1/`NP' {
	noisily di in y "  `pal_id`i''" _col(16) "`pal_lado`i''" _col(24) "`pal_estado`i''" _col(36) "`pal_variable`i''" _col(62) "`pal_ancla_ref`i''" _col(88) "`pal_ancla_pe`i''" _col(112) "`pal_grupo`i''" cond(`pal_banda`i'', " banda", "")
}

local impuestos "ISRAS ISRPF ISRPM IVA IEPSNP IEPSP ISAN IMPORT"	// compuertas Q.2/Q.3 contra el statajson (no dependen de la paleta)
local extras "CUOTAS"

*** 1 INSUMOS DEL CANAL E IDENTIDAD (compuerta Q.4) ***
noisily di _newline in g "{bf:1. Insumos del canal: federacion-nl.json, statajson_entidad-nl.json, aportaciones.dta, PEF.dta}"
local fedjson `"`site'/users/$id/nodos/federacion-nl.json"'
local entjson `"`site'/users/$id/nodos/statajson_entidad-nl.json"'
local aport `"`site'/users/$id/aportaciones.dta"'
local pef `"`site'/master/PEF.dta"'
foreach f in `"`fedjson'"' `"`entjson'"' `"`aport'"' `"`pef'"' {
	capture confirm file `"`f'"'
	if _rc {
		di as err `"FederacionNLQuintiles: falta `f'. No se exporta."'
		exit 601
	}
}
_NLjsonget using `"`fedjson'"', keys(anio_referencia anio_politica procedencia.version_capa_nl procedencia.version_motor procedencia.generado_en procedencia.modo cifras.pagaS0NL cifras.recibeNL cifras.pagaPES0NL cifras.recibePENL cifras.cuotasIMSSNL cifras.cuotasPENL esquema alcance.excluye alcance.nodo_saldo)
local anioref = `r(v1)'
local aniope = `r(v2)'
local fed_vnl "`r(v3)'"
local fed_vmotor "`r(v4)'"
local fed_gen `"`r(v5)'"'
local fed_modo "`r(v6)'"
local tj_paga_ref = `r(v7)'
local tj_rec_ref = `r(v8)'
local tj_paga_pe = `r(v9)'
local tj_rec_pe = `r(v10)'
local tj_cuo_ref = `r(v11)'
local tj_cuo_pe = `r(v12)'
local fed_esq "`r(v13)'"
local fed_excluye `"`r(v14)'"'
local fed_saldo `"`r(v15)'"'
local nl_vnl "`fed_vnl'"
if "`fed_vmotor'" != "`nl_vmotor'" {
	di as err "FederacionNLQuintiles: federacion-nl.json es del motor `fed_vmotor'; la sesión es `nl_vmotor'. Re-corre FederacionNL.do. No se exporta."
	exit 459
}
capture confirm scalar anioPE
if _rc == 0 {
	if scalar(anioPE) != `aniope' {
		di as err "FederacionNLQuintiles: anio_politica del JSON (`aniope') ≠ anioPE de la sesión (`=scalar(anioPE)'). No se exporta."
		exit 459
	}
}
_NLjsonget using `"`entjson'"', keys(anio_referencia presentacion.version_capa_nl presentacion.version_motor procedencia.generado_en presentacion.enigh_vintage)
local ent_anio = `r(v1)'
local ent_vnl "`r(v2)'"
local ent_vmotor "`r(v3)'"
local ent_gen `"`r(v4)'"'
local enigh "`r(v5)'"
if `ent_anio' != `aniope' | "`ent_vnl'" != "`fed_vnl'" | "`ent_vmotor'" != "`nl_vmotor'" | "`enigh'" == "" {
	di as err "FederacionNLQuintiles: statajson_entidad-nl.json es de PE `ent_anio' / capa `ent_vnl' / motor `ent_vmotor' (ENIGH '`enigh''); federacion-nl.json es de la capa `fed_vnl' y la sesión del motor `nl_vmotor' / PE `aniope'. No se exporta."
	exit 459
}
local perfiles `"`site'/master/perfiles`aniope'.dta"'
if `usaPerfiles' {
	capture confirm file `"`perfiles'"'
	if _rc {
		di as err `"FederacionNLQuintiles: la paleta pide perfiles: y falta `perfiles'. No se exporta."'
		exit 601
	}
}
_NLsha256 `"`fedjson'"'
local fed_sha "`r(sha256)'"
_NLsha256 `"`entjson'"'
local ent_sha "`r(sha256)'"
_NLsha256 `"`aport'"'
local aport_sha "`r(sha256)'"
_NLfileinfo `"`aport'"'
local aport_mtime "`r(mtime)'"
_NLfileinfo `"`pef'"'
local pef_mtime "`r(mtime)'"
local perf_sha ""
local perf_mtime ""
if `usaPerfiles' {
	_NLsha256 `"`perfiles'"'
	local perf_sha "`r(sha256)'"
	_NLfileinfo `"`perfiles'"'
	local perf_mtime "`r(mtime)'"
}
noisily di in g "  Compuerta Q.4 (identidad: contrato base y statajson de la capa `nl_vnl' y motor `nl_vmotor', PE `aniope', ENIGH `enigh'; manifest de la sesión `nl_vdriver'; federacion-nl.json modo `fed_modo' de `fed_gen'): " in y "PASÓ" in g "."
if "`nl_vdriver'" != "`nl_vnl'" noisily di in g "  Aviso: el manifest de la sesión dice capa " in y "`nl_vdriver'" in g " y el contrato base es de la capa " in y "`nl_vnl'" in g ": el hermano hereda la del contrato base (version_capa_nl) y declara la del manifest como version_capa_driver."
noisily di in g "  Año de referencia " in y "`anioref'" in g " (observado) · año de política " in y "`aniope'" in g " (Paquete) · tarjetas: paga " in y %10.1fc `tj_paga_ref'/1e6 in g " / " in y %10.1fc `tj_paga_pe'/1e6 in g " · recibe " in y %10.1fc `tj_rec_ref'/1e6 in g " / " in y %10.1fc `tj_rec_pe'/1e6 in g " mdp"

* Escalares del statajson: Rec<X>nl, dis<fam>nle<dec>, concTop1<X>nl *
local sj_prefijos "Rec dis concTop1"
quietly {
	_NLjsonesc using `"`entjson'"', prefijos(`sj_prefijos')
	destring valor, replace force
	forvalues i = 1/`=_N' {
		local v`=nombre[`i']' = valor[`i']
	}
	keep if substr(nombre, 1, 3) == "dis" & strpos(nombre, "nle") > 0 & strpos(nombre, "nleS") == 0
	keep nombre valor
	rename valor disjson
	tempfile DISJ
	save `DISJ'
}

* Montos anuales del contrato vigente (anual) y subfondos del año de referencia *
quietly {
	_NLjsonarr using `"`fedjson'"', array(anual) fields(anio tipoRecibe tipoPaga fuenteAncla nlR28 nlR33 nlCD nlCR nlR23 nlPSS nlTot anclaR28 anclaR33 anclaConv anclaSubs anclaSalud anclaTot recibePaq pagaISRAS pagaISRPF pagaISRPM pagaIVA pagaIEPSNP pagaIEPSP pagaISAN pagaIMPORT pagaCUOTAS pagaOTROSK pagaS0 pagaS1 pagaS3 pagaLifISRAS pagaLifISRPF pagaLifISRPM pagaLifIVA pagaLifIEPSNP pagaLifIEPSP pagaLifISAN pagaLifIMPORT pagaLifCUOTAS pagaLifOTROSK pagaLifS0 pagaLifS1 pagaLifS3 pobNL)
	foreach v of varlist nlR28-pobNL {
		capture confirm string variable `v'
		if _rc == 0 destring `v', replace force
	}
	keep if inlist(anio, `anioref', `aniope')
	count
	if r(N) != 2 {
		noisily di as err "FederacionNLQuintiles: anual no trae exactamente una fila para `anioref' y `aniope'. No se exporta."
		exit 459
	}
	tempfile AN
	save `AN'
	_NLjsonarr using `"`fedjson'"', array(subfondos) fields(anio clave grupo nl nac)
	destring anio nl nac, replace force
	keep if inlist(anio, `anioref', `aniope')
	tempfile SF
	save `SF'
	_NLjsonarr using `"`fedjson'"', array(definiciones.subfondos) fields(clave grupo nombre)
	forvalues i = 1/`=_N' {
		local nom`=clave[`i']' `"`=nombre[`i']'"'
	}
}
noisily di in g "  Montos del contrato vigente leídos: anual (`anioref', `aniope'), subfondos (" in y "`=_N'" in g " claves con nombre)."

*** 2 MUESTRA NL Y QUINTILES ESTATALES (compuerta Q.0) ***
noisily di _newline in g "{bf:2. Quintiles estatales (criterio Households.do:2591-2599 re-rankeado en la muestra NL)}"
use `"`aport'"', clear
g entidad = real(substr(folioviv, 1, 2))
keep if entidad == 19
tempvar toti dechog
egen `toti' = count(edad), by(folioviv foliohog)
egen double `dechog' = sum(ingbrutotot), by(folioviv foliohog)
g double ingpc = `dechog'/`toti'							// ingreso bruto total del hogar por integrante (ing_decil_pc del motor)
g double wh = factor/`toti'									// peso de hogar: factor / integrantes (pw del motor)
xtile decilE = ingpc [pw=wh], n(10)
xtile quintilE = ingpc [pw=wh], n(5)
count if quintilE != ceil(decilE/2)
if r(N) > 0 {
	di as err "FederacionNLQuintiles: el quintil (xtile n=5) no coincide con ceil(decil/2) en `r(N)' personas: revisar pesos. No se exporta."
	exit 459
}
bysort folioviv foliohog: g byte hog1 = _n == 1
g byte one = 1
quietly {
	preserve
	collapse (sum) nPers = one nHog = hog1 pob = factor (min) ingpcMin = ingpc (max) ingpcMax = ingpc, by(quintilE)
	rename quintilE q
	summarize nPers, meanonly
	local nPersMin = r(min)
	summarize nHog, meanonly
	local nHogMin = r(min)
	tempfile MU
	save `MU'
	restore
	count
	local nPersNL = r(N)
	count if hog1
	local nHogNL = r(N)
	summarize factor, meanonly
	local pobNL_enigh = r(sum)
}
if `nPersMin' < `umbral' | `nHogMin' < `umbral' {
	di as err "FederacionNLQuintiles: algún quintil estatal tiene menos de `umbral' personas (`nPersMin') u hogares (`nHogMin'). No se exporta."
	exit 459
}
noisily di in g "  Muestra NL: " in y %6.0fc `nPersNL' in g " personas · " in y %5.0fc `nHogNL' in g " hogares · " in y %12.0fc `pobNL_enigh' in g " expandidas (ENIGH `enigh')."
noisily di in g "  Compuerta Q.0 (n≥`umbral' por quintil: mín " in y "`nPersMin'" in g " personas, " in y "`nHogMin'" in g " hogares): " in y "PASÓ" in g "."

* 2.1 perfiles<PE>.dta: mismas personas; variables pedidas por la paleta (compuerta Q.7) *
local rdQ7 = .
local perfVars ""
forvalues i = 1/`NP' {
	if "`pal_vfuente`i''" == "perfiles" local perfVars "`perfVars' `pal_vnombre`i''"
}
local perfVars : list uniq perfVars
* variables de gasto presentes en ambos objetos (inventario: Σ de cada fuente y reldif, sin elegir) *
local invVars "Educacion Salud Pension_AM Pensiones infra_entidad Otras_inversiones Otros_gastos Energia Federalizado IngBasico"
forvalues i = 1/`NP' {
	if inlist("`pal_vfuente`i''", "aport", "perfiles") local invVars "`invVars' `pal_vnombre`i''"
}
local invVars : list uniq invVars
if `usaPerfiles' | "`invVars'" != "" {
	quietly {
		preserve
		describe using `"`perfiles'"', varlist
		local pfvl "`r(varlist)'"
		local pv ""
		foreach v of local invVars {
			if strpos(" `pfvl' ", " `v' ") > 0 local pv "`pv' `v'"
		}
		local pv : list uniq pv
		local faltan : list perfVars - pv
		if "`faltan'" != "" {
			noisily di as err "FederacionNLQuintiles (P.0): la paleta pide perfiles:`faltan' y perfiles`aniope'.dta no trae esa(s) variable(s). No se exporta."
			exit 459
		}
		use folioviv foliohog numren factor ingbrutotot `pv' using `"`perfiles'"', clear
		g entidad = real(substr(folioviv, 1, 2))
		keep if entidad == 19
		drop entidad
		rename factor pf_factor
		rename ingbrutotot pf_ingbrutotot
		foreach v of local pv {
			rename `v' pf_`v'
		}
		tempfile PF
		save `PF'
		restore
		merge 1:1 folioviv foliohog numren using `PF', keep(match master using) gen(_mpf)
		count if _mpf != 3
		local nQ7 = r(N)
		g double rdf = reldif(factor, pf_factor)
		g double rdi = reldif(ingbrutotot, pf_ingbrutotot)
		summarize rdf, meanonly
		local rdQ7 = r(max)
		summarize rdi, meanonly
		local rdQ7 = max(`rdQ7', r(max))
		drop rdf rdi
	}
	if `nQ7' > 0 | `rdQ7' > 1e-9 {
		di as err "FederacionNLQuintiles (Q.7): perfiles`aniope'.dta (entidad 19) no trae las mismas personas que aportaciones.dta (`nQ7' sin pareja) o difiere en factor/ingbrutotot (reldif máx `rdQ7'). No se exporta."
		exit 459
	}
	noisily di in g "  Compuerta Q.7 (perfiles`aniope'.dta entidad 19 = aportaciones.dta: mismas personas, factor e ingbrutotot; reldif máx " in y %9.2e `rdQ7' in g "): " in y "PASÓ" in g "."
	* inventario: Σ en cada objeto *
	noisily di in g "  Variable" _col(22) %22s "Σ aportaciones.dta" _col(46) %22s "Σ perfiles`aniope'.dta" _col(70) %10s "reldif" _col(82) "n>0 aport / perfiles"
	foreach v of local invVars {
		capture confirm variable `v'
		local hayA = (_rc == 0)
		capture confirm variable pf_`v'
		local hayP = (_rc == 0)
		local sA = .
		local sP = .
		local nA = .
		local nPp = .
		if `hayA' {
			quietly summarize `v' [fw=factor], meanonly
			local sA = r(sum)
			quietly count if `v' > 0 & `v' != .
			local nA = r(N)
		}
		if `hayP' {
			quietly summarize pf_`v' [fw=factor], meanonly
			local sP = r(sum)
			quietly count if pf_`v' > 0 & pf_`v' != .
			local nPp = r(N)
		}
		local inv_sA_`v' = `sA'
		local inv_sP_`v' = `sP'
		local inv_nA_`v' = `nA'
		local inv_nP_`v' = `nPp'
		local inv_rd_`v' = cond(`hayA' & `hayP', reldif(`sA', `sP'), .)
		noisily di in g "  `v'" _col(22) in y %22.0fc `sA' _col(46) %22.0fc `sP' _col(70) %10.2e `inv_rd_`v'' _col(82) %6.0f `nA' " / " %6.0f `nPp'
	}
}

* 2.2 Pesos de reparto por flujo (w_<id> = variable × factor; p_<id> = tiene la clave) *
forvalues i = 1/`NP' {
	local id "`pal_id`i''"
	local f "`pal_vfuente`i''"
	local vn "`pal_vnombre`i''"
	if "`f'" == "aport" {
		capture confirm variable `vn'
		if _rc {
			di as err "FederacionNLQuintiles (P.0): la variable aport:`vn' del flujo `id' no existe en aportaciones.dta. No se exporta."
			exit 459
		}
		g double w_`id' = `vn'*factor
		g byte p_`id' = `vn' > 0 & `vn' != .
	}
	else if "`f'" == "perfiles" {
		g double w_`id' = pf_`vn'*factor
		g byte p_`id' = pf_`vn' > 0 & pf_`vn' != .
	}
	else if "`vn'" == "alum_basica" {
		g byte p_`id' = alum_basica == 1							// alumno de educación básica pública (GastoPC.ado)
		g double w_`id' = p_`id'*factor
	}
	else if "`vn'" == "afil_ssa" {
		g byte p_`id' = inst_6 == "6"								// afiliación a institución federal/estatal de salud — D3
		g double w_`id' = p_`id'*factor
	}
	egen byte hp_`id' = max(p_`id'), by(folioviv foliohog)
	replace hp_`id' = hp_`id'*hog1
	quietly summarize w_`id', meanonly
	local suma_`id' = r(sum)
	local conc_`id' = cond(r(sum) != 0, r(max)/r(sum)*100, .)
	quietly summarize p_`id' [fw=factor], meanonly
	local unid_`id' = r(sum)										// unidades expandidas con la clave (alumnos, afiliados…)
	quietly count if p_`id'
	local nNL_`id' = r(N)
}
* compuertas Q.2/Q.3 sobre <X>_Sim (independientes de la paleta) *
foreach k in `impuestos' `extras' {
	g double wq_`k' = `k'_Sim*factor
}
g double w_AlTrabajo = AlTrabajo*factor
g double w_AlConsumo = AlConsumo*factor
g double w_AlCapital = AlCapital*factor
g double w_ImpAport = ImpuestosAportaciones*factor
tempfile BASE
quietly save `BASE'

*** 3 COMPUERTAS Q.1 (construcción = statajson por decil), Q.2 (totales = Rec<X>nl), Q.3 (concTop1) ***
noisily di _newline in g "{bf:3. Compuertas de construcción contra statajson_entidad-nl.json}"
quietly {
	collapse (sum) w_AlTrabajo w_AlConsumo w_AlCapital w_ImpAport wq_IVA wq_IEPSNP wq_IEPSP wq_ISAN wq_IMPORT, by(decilE)
	foreach f in AlTrabajo AlConsumo AlCapital ImpAport {
		egen double t = total(w_`f')
		g double sh_`f' = w_`f'/t*100
		drop t w_`f'
	}
	foreach f in IVA IEPSNP IEPSP ISAN IMPORT {
		egen double t = total(wq_`f')
		g double sh_`f' = wq_`f'/t*100
		drop t wq_`f'
	}
	g dec = word("I II III IV V VI VII VIII IX X", decilE)
	drop decilE
	reshape long sh_, i(dec) j(fam) string
	g nombre = "dis" + fam + "nle" + dec
	merge 1:1 nombre using `DISJ', keep(match master)
	count if _merge != 3
	local nf = r(N)
	g double rd = reldif(sh_, disjson)
	summarize rd, meanonly
	local rdQ1 = r(max)
	count if rd > 1e-6
	local nf = `nf' + r(N)
	local nQ1 = _N
}
if `nf' > 0 {
	noisily list nombre sh_ disjson rd if rd > 1e-6 | _merge != 3, noobs clean
	di as err "FederacionNLQuintiles: la construcción de deciles/quintiles estatales no reproduce dis<fam>nle<dec> del statajson en `nf' celdas (1e-6). No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.1 (participación por decil estatal = dis<fam>nle<dec>, `nQ1' celdas): " in y "PASÓ" in g " (reldif máx " in y %9.2e `rdQ1' in g ")."
use `BASE', clear
local nf = 0
local rdQ2 = 0
local rdQ3 = 0
local q2txt ""
foreach k in `impuestos' `extras' {
	quietly summarize wq_`k', meanonly
	local c = cond(r(sum) != 0, r(max)/r(sum)*100, .)
	local rd = reldif(r(sum), `vRec`k'nl')
	local rdQ2 = max(`rdQ2', `rd')
	local q2txt "`q2txt'`k' `=string(`rd', "%8.1e")'; "
	if `rd' > 1e-2 {
		local ++nf
		noisily di as err "  `k': Σ `k'_Sim×factor = `r(sum)' vs Rec`k'nl = `vRec`k'nl'"
	}
	local rd = reldif(`c', `vconcTop1`k'nl')
	local rdQ3 = max(`rdQ3', `rd')
	if `rd' > 1e-6 {
		local ++nf
		noisily di as err "  `k': concTop1 recalculado = `c' vs concTop1`k'nl = `vconcTop1`k'nl'"
	}
}
if `nf' > 0 {
	di as err "FederacionNLQuintiles: totales o concTop1 de NL no coinciden con el statajson en `nf' casos. No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.2 (Σ <X>_Sim×factor vs Rec<X>nl: cociente = <X>PIB·pibY/100 / ILIF, redondeo del parámetro §4.1 a 3 decimales de % PIB; tol 1e-2): " in y "PASÓ" in g " (reldif máx " in y %9.2e `rdQ2' in g "; por impuesto: `q2txt')."
noisily di in g "  Compuerta Q.3 (concTop1<X> recalculado = statajson): " in y "PASÓ" in g " (reldif máx " in y %9.2e `rdQ3' in g ")."

*** 4 CLAVES POR QUINTIL: participación, n, hogares, concTop1, cumpleN, sello top-1 (todos los flujos de la paleta) ***
noisily di _newline in g "{bf:4. Claves de reparto por quintil estatal (ENIGH `enigh', corrida PE `aniope') — todos los flujos de la paleta}"
quietly {
	local cs ""
	local cm ""
	local cn ""
	local ch ""
	forvalues i = 1/`NP' {
		local id "`pal_id`i''"
		local cs "`cs' sumq_`id'=w_`id'"
		local cm "`cm' con_`id'=w_`id'"
		local cn "`cn' n_`id'=p_`id'"
		local ch "`ch' h_`id'=hp_`id'"
	}
	collapse (sum) `cs' `cn' `ch' (max) `cm', by(quintilE)
	forvalues i = 1/`NP' {
		local id "`pal_id`i''"
		egen double t = total(sumq_`id')
		g double shr_`id' = cond(t != 0, sumq_`id'/t, .)
		replace con_`id' = cond(sumq_`id' != 0, con_`id'/sumq_`id'*100, .)
		drop t
	}
	rename quintilE q
	reshape long sumq_ shr_ con_ n_ h_, i(q) j(id) string
	rename (sumq_ shr_ con_ n_ h_) (sumaQ share concTop1 n nHog)
	g byte cumpleN = n >= `umbral'
	g byte selloTop1 = concTop1 >= `selloTop1' & concTop1 != .
	sort id q
	tempfile CL
	save `CL'
	forvalues i = 1/`NP' {
		local id "`pal_id`i''"
		summarize n if id == "`id'", meanonly
		local nMin_`id' = r(min)
		local bajo_`id' ""
		local top_`id' ""
		forvalues qq = 1/5 {
			summarize n if id == "`id'" & q == `qq', meanonly
			if r(mean) < `umbral' local bajo_`id' "`bajo_`id'' `qq'"
			summarize selloTop1 if id == "`id'" & q == `qq', meanonly
			if r(mean) == 1 local top_`id' "`top_`id'' `qq'"
		}
		local bajo_`id' = trim("`bajo_`id''")
		local top_`id' = trim("`top_`id''")
	}
}
noisily di in g "  Participación por quintil (%) · n personas con la clave · concTop1 (%) · Σ en la muestra NL (mdp, pesos PE `aniope')"
noisily di in g "  Flujo" _col(16) %12s "Q1" _col(30) %12s "Q2" _col(44) %12s "Q3" _col(58) %12s "Q4" _col(72) %12s "Q5" _col(86) %14s "Σ NL (mdp)" _col(102) "celdas n<`umbral' | top-1≥`selloTop1'%"
forvalues i = 1/`NP' {
	local id "`pal_id`i''"
	forvalues qq = 1/5 {
		quietly summarize share if id == "`id'" & q == `qq', meanonly
		local s`qq' = r(mean)*100
		quietly summarize n if id == "`id'" & q == `qq', meanonly
		local n`qq' = r(mean)
		quietly summarize concTop1 if id == "`id'" & q == `qq', meanonly
		local c`qq' = r(mean)
	}
	noisily di in g "  `id'" _col(16) in y %12.2f `s1' _col(30) %12.2f `s2' _col(44) %12.2f `s3' _col(58) %12.2f `s4' _col(72) %12.2f `s5' _col(86) %14.1fc `suma_`id''/1e6 _col(102) in g "[`bajo_`id'']" " | [" "`top_`id''" "]"
	noisily di in g "    n" _col(16) in y %12.0f `n1' _col(30) %12.0f `n2' _col(44) %12.0f `n3' _col(58) %12.0f `n4' _col(72) %12.0f `n5' _col(86) in g %14s "NL top-1 " in y %5.1f `conc_`id'' in g " %"
	noisily di in g "    top-1" _col(16) in y %12.1f `c1' _col(30) %12.1f `c2' _col(44) %12.1f `c3' _col(58) %12.1f `c4' _col(72) %12.1f `c5' _col(86) in g %14s "unidades " in y %12.0fc `unid_`id''
}

*** 5 ANCLAS Y MONTOS POR AÑO: paga (contrato), recibe (EOFP / PPEF por pp / statajson / suma), caja gris CALCULADA ***
noisily di _newline in g "{bf:5. Anclas de total por flujo y año (paleta) y caja gris calculada}"
* 5.1 PEF.dta: entidad 19, ambos años, por ramo y pp (compuerta Q.5 sobre el ramo 33 del año de política) *
noisily di in g "  Leyendo master/PEF.dta (entidad 19, `anioref' y `aniope', por ramo y pp)..."
quietly {
	use anio ramo pp desc_pp entidad divFEDE gasto if entidad == 19 & inlist(anio, `anioref', `aniope') using `"`pef'"', clear
	g int ramoN = ramo
	collapse (sum) gasto, by(anio ramoN pp desc_pp divFEDE)
	g lpp = lower(desc_pp)
	tempfile PP
	save `PP'
	summarize gasto if anio == `aniope' & ramoN == 33 & divFEDE == "Aportaciones", meanonly
	local pefR33_`aniope' = cond(r(N) > 0, r(sum), .)
	count if ramoN == 33 & inlist(pp, 13, 15) & strpos(lpp, "fone") == 0
	local nf = r(N)
	count if ramoN == 33 & pp == 2 & strpos(lpp, "fassa") == 0
	local nf = `nf' + r(N)
	count if ramoN == 33 & !inlist(pp, 13, 15, 2) & (strpos(lpp, "fone") > 0 | strpos(lpp, "fassa") > 0)
	local nf = `nf' + r(N)
	use `AN', clear
	summarize anclaR33 if anio == `aniope', meanonly
	local anclaR33pe = r(mean)
}
if `nf' > 0 {
	di as err "FederacionNLQuintiles (Q.5): los programas pp 13/15 (FONE) y pp 2 (FASSA) del ramo 33 no corresponden a su descripción en PEF.dta. No se exporta."
	exit 459
}
if reldif(`pefR33_`aniope'', `anclaR33pe') > 1e-9 {
	di as err "FederacionNLQuintiles (Q.5): Σ pp del ramo 33 en PEF.dta (`pefR33_`aniope'') ≠ anclaR33 `aniope' del contrato (`anclaR33pe'). No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.5 (PEF.dta ramo 33 `aniope' por pp = anclaR33 del contrato; pp 13/15 = FONE, pp 2 = FASSA): " in y "PASÓ" in g "."

* 5.2 Escalares anuales del contrato (tarjetas, S0/S1/S3, pobNL, tipo/fuente) *
quietly use `AN', clear
foreach t in `anioref' `aniope' {
	local pre_`t' = cond(`t' == `anioref', "paga", "pagaLif")
	foreach s in S0 S1 S3 {
		quietly summarize `pre_`t''`s' if anio == `t', meanonly
		local pg`s'_`t' = r(mean)
	}
	quietly summarize pobNL if anio == `t', meanonly
	local pobNL_`t' = r(mean)
	quietly levelsof tipoPaga if anio == `t', clean
	local tipoPaga_`t' = cond(`t' == `anioref', "`r(levels)'", "Paquete")
	quietly levelsof fuenteAncla if anio == `t', clean
	local fuenteAncla_`t' "`r(levels)'"
	if `t' == `anioref' {
		quietly summarize nlTot if anio == `t', meanonly
		local recibe_`t' = r(mean)
		local fuenteRecibe_`t' "EOFP"
		local tipoRecibe_`t' "observado"
		local pssFlag_`t' = 0
	}
	else {
		quietly summarize recibePaq if anio == `t', meanonly
		local recibe_`t' = r(mean)
		local fuenteRecibe_`t' "`fuenteAncla_`t''"
		local tipoRecibe_`t' "Paquete"
		quietly summarize anclaSalud if anio == `t', meanonly
		local pssFlag_`t' = (r(N) == 0 | r(mean) == .)			// el PPEF no trae PSS (R47 salud federalizado) por entidad
	}
	local tjPaga_`t' = cond(`t' == `anioref', `tj_paga_ref', `tj_paga_pe')
	local tjCuo_`t' = cond(`t' == `anioref', `tj_cuo_ref', `tj_cuo_pe')
	local tjRec_`t' = cond(`t' == `anioref', `tj_rec_ref', `tj_rec_pe')
}

* 5.3 Resolución de anclas: total_<id>_<t>, sup (supuesto), det (detalle), claims (componentes EOFP/PPEF reclamados) *
noisily di in g "  Flujo" _col(16) "año" _col(22) "ancla" _col(50) %16s "total (mdp)" _col(68) "detalle"
forvalues i = 1/`NP' {
	if `pal_abrir`i'' == 0 continue
	local id "`pal_id`i''"
	foreach t in `anioref' `aniope' {
		local spec = cond(`t' == `anioref', "`pal_ancla_ref`i''", "`pal_ancla_pe`i''")
		local terms = subinstr("`spec'", "+", " ", .)
		local tipo ""
		local val = 0
		local sup = 0
		local det ""
		local claims ""
		local sj = 0
		foreach term of local terms {
			local pos = strpos("`term'", ":")
			if `pos' > 0 {
				local tipo = substr("`term'", 1, `pos' - 1)
				local ref = substr("`term'", `pos' + 1, .)
			}
			else {
				local ref "`term'"
				if "`term'" == "suma" local tipo "suma"
			}
			if "`tipo'" == "" {
				di as err "FederacionNLQuintiles (P.0): el término '`term'' del ancla `spec' (flujo `id', `t') no tiene tipo y no hereda ninguno. No se exporta."
				exit 459
			}
			local x = .
			if "`tipo'" == "fed" {
				quietly use `AN', clear
				capture confirm numeric variable `ref'
				if _rc {
					di as err "FederacionNLQuintiles (P.0): fed:`ref' (flujo `id') no es un campo numérico del arreglo anual de federacion-nl.json. No se exporta."
					exit 459
				}
				quietly summarize `ref' if anio == `t', meanonly
				local x = cond(r(N) > 0, r(mean), .)
				local claims "`claims' fed:`ref'"
			}
			else if "`tipo'" == "eofp" {
				if `t' != `anioref' {
					di as err "FederacionNLQuintiles (P.0): eofp:`ref' (flujo `id') solo existe para el año observado `anioref'; para `t' usa pef:/fed:/statajson:/suma. No se exporta."
					exit 459
				}
				quietly use `SF', clear
				quietly summarize nl if anio == `t' & clave == "`ref'", meanonly
				local x = cond(r(N) > 0, r(mean), .)
				local claims "`claims' eofp:`ref'"
			}
			else if "`tipo'" == "pef" {
				local ramo = 33
				local ppn "`ref'"
				local sl = strpos("`ref'", "/")
				if `sl' > 0 {
					local ramo = real(substr("`ref'", 1, `sl' - 1))
					local ppn = substr("`ref'", `sl' + 1, .)
				}
				capture confirm integer number `ppn'
				if _rc | `ramo' == . {
					di as err "FederacionNLQuintiles (P.0): pef:`ref' (flujo `id') no tiene la forma pef:<pp> o pef:<ramo>/<pp>. No se exporta."
					exit 459
				}
				quietly use `PP', clear
				quietly summarize gasto if anio == `t' & ramoN == `ramo' & pp == `ppn', meanonly
				local x = cond(r(N) > 0, r(sum), .)
				quietly levelsof desc_pp if anio == `t' & ramoN == `ramo' & pp == `ppn', clean
				local ref "`ramo'/`ppn'"
				local claims "`claims' pef:`ramo'/`ppn'"
				local det "`det'[`r(levels)'] "
			}
			else if "`tipo'" == "statajson" {
				local ok = 0
				foreach pf of local sj_prefijos {
					if substr("`ref'", 1, strlen("`pf'")) == "`pf'" local ok = 1
				}
				if !`ok' | "`v`ref''" == "" {
					di as err "FederacionNLQuintiles (P.0): statajson:`ref' (flujo `id') no está entre los escalares cargados (prefijos `sj_prefijos'). No se exporta."
					exit 459
				}
				local x = `v`ref''
				local sj = 1
			}
			else if "`tipo'" == "suma" {
				local x = `suma_`id''
				local sup = 1
			}
			else {
				di as err "FederacionNLQuintiles (P.0): tipo de ancla '`tipo'' (flujo `id') no es fed | eofp | pef | statajson | suma. No se exporta."
				exit 459
			}
			if `x' == . {
				di as err "FederacionNLQuintiles (P.0): el ancla `tipo':`ref' del flujo `id' no tiene valor para `t'. No se exporta."
				exit 459
			}
			local val = `val' + `x'
			local det "`det'`tipo':`ref' = `=string(`x'/1e6, "%14.1fc")' mdp; "
		}
		local total_`id'_`t' = `val'
		local sup_`id'_`t' = `sup'
		local sj_`id'_`t' = `sj'
		local det_`id'_`t' = trim("`det'")
		local claims_`id'_`t' = trim("`claims'")
		local spec_`id'_`t' "`spec'"
		if `pal_banda`i'' {
			local totalS1_`id'_`t' = `val' - `pgS0_`t'' + `pgS1_`t''
			local totalS3_`id'_`t' = `val' - `pgS0_`t'' + `pgS3_`t''
		}
		else {
			local totalS1_`id'_`t' = .
			local totalS3_`id'_`t' = .
		}
		noisily di in g "  `id'" _col(16) in y "`t'" _col(22) "`spec'" _col(50) %16.1fc `val'/1e6 _col(68) in g cond(`sup', "SUPUESTO (Σ muestra, pesos PE) · ", cond(`sj', "vintage PE · ", "")) "`det_`id'_`t''"
	}
}

* 5.4 Sumas por lado, caja gris calculada, cierres de cada lado (compuerta Q.6a) *
local nf = 0
foreach t in `anioref' `aniope' {
	local sumPaga_`t' = 0
	local sumCuo_`t' = 0
	local sumRecF_`t' = 0
	local sumInv_`t' = 0
	forvalues i = 1/`NP' {
		local id "`pal_id`i''"
		if `pal_abrir`i'' == 0 {
			if "`pal_lado`i''" == "recibe" local sumInv_`t' = `sumInv_`t'' + `suma_`id''
			continue
		}
		if "`pal_lado`i''" == "paga" local sumPaga_`t' = `sumPaga_`t'' + `total_`id'_`t''
		if "`pal_lado`i''" == "aparte" local sumCuo_`t' = `sumCuo_`t'' + `total_`id'_`t''
		if "`pal_lado`i''" == "recibe" local sumRecF_`t' = `sumRecF_`t'' + `total_`id'_`t''
	}
	local gris_`t' = `tjRec_`t'' - `sumRecF_`t''
	local grisPct_`t' = `gris_`t''/`tjRec_`t''*100
	local grisTodos_`t' = `gris_`t'' - `sumInv_`t''							// aritmética: si se encendieran todos los del inventario con ancla suma
	local grisTodosPct_`t' = `grisTodos_`t''/`tjRec_`t''*100
	local sumRec_`t' = `sumRecF_`t'' + `gris_`t''
	local rdPaga_`t' = reldif(`sumPaga_`t'', `tjPaga_`t'')
	local rdCuo_`t' = reldif(`sumCuo_`t'', `tjCuo_`t'')
	local rdRec_`t' = reldif(`sumRec_`t'', `tjRec_`t'')
	noisily di in g "  `t' (`tipoPaga_`t'' / `tipoRecibe_`t''): Σ paga (abiertos + cerrados) " in y %12.1fc `sumPaga_`t''/1e6 in g " vs tarjeta " in y %12.1fc `tjPaga_`t''/1e6 in g " mdp · reldif " in y %9.2e `rdPaga_`t''
	noisily di in g "  `t' aparte: Σ " in y %12.1fc `sumCuo_`t''/1e6 in g " vs tarjeta " in y %12.1fc `tjCuo_`t''/1e6 in g " · reldif " in y %9.2e `rdCuo_`t''
	noisily di in g "  `t' recibe: Σ flujos etiquetados " in y %12.1fc `sumRecF_`t''/1e6 in g " + caja gris CALCULADA " in y %12.1fc `gris_`t''/1e6 in g " (" in y %5.1f `grisPct_`t'' in g " %) = tarjeta " in y %12.1fc `tjRec_`t''/1e6 in g " mdp · reldif " in y %9.2e `rdRec_`t''
	noisily di in g "  `t' aritmética del inventario: si se encendieran TODOS los flujos recibe en inventario con ancla suma (Σ " in y %12.1fc `sumInv_`t''/1e6 in g " mdp, pesos PE), la caja gris quedaría en " in y %12.1fc `grisTodos_`t''/1e6 in g " mdp = " in y %6.1f `grisTodosPct_`t'' in g " % del recibe (solo aritmética)."
	if `rdPaga_`t'' > 1e-6 {
		local ++nf
		noisily di as err "  `t': Σ flujos paga de la paleta ≠ tarjeta paga (cifras.pagaS0NL / pagaPES0NL): la tarjeta es la suma de los 8 impuestos del contrato; un flujo paga con otra ancla rompe la identidad."
	}
	if `rdCuo_`t'' > 1e-6 {
		local ++nf
		noisily di as err "  `t': Σ flujos aparte ≠ tarjeta cuotas."
	}
	if `gris_`t'' < 0 & !`grisNeg' {
		local ++nf
		noisily di as err "  `t': la caja gris queda NEGATIVA (`=string(`gris_`t''/1e6, "%14.1fc")' mdp): los flujos recibe etiquetados superan la tarjeta recibe. Revisa las anclas (parámetro gris_negativo 1 para exportar con aviso)."
	}
}
if `nf' > 0 {
	di as err "FederacionNLQuintiles (Q.6a): `nf' cierres de lado fallan. No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.6a (Σ paga = tarjeta, Σ aparte = tarjeta, caja gris = tarjeta − Σ recibe etiquetados; 1e-6): " in y "PASÓ" in g "."

* 5.5 Componentes de la caja gris por año: componentes EOFP (observado) / PPEF (Paquete) menos los reclamados por las anclas *
quietly {
	clear
	set obs 0
	g int anio = .
	g clave = ""
	g lab = ""
	g double v = .
	g reclamadoPor = ""
	tempfile GR
	save `GR'
	* observado: agregados EOFP + subfondos R33 de primer nivel + residuo R33 *
	use `AN', clear
	keep if anio == `anioref'
	keep anio nlR28 nlCD nlCR nlR23 nlPSS nlR33
	rename (nlR28 nlCD nlCR nlR23 nlPSS) (vR28 vCD vCR vR23 vPSS)
	g double vR33resto = nlR33
	reshape long v, i(anio) j(clave) string
	g lab = cond(clave == "R28", "Participaciones (R28)", cond(clave == "CD", "Convenios de descentralización", cond(clave == "CR", "Convenios de reasignación", cond(clave == "R23", "Gasto federalizado del R23", cond(clave == "PSS", "Recursos para protección social en salud (PSS)", "Ramo 33 no desglosado (residuo XAC33 − Σ subfondos de primer nivel)")))))
	g claveAncla = cond(clave == "R33resto", "", "fed:nl" + clave)
	keep anio clave lab v claveAncla
	tempfile G1
	save `G1'
	use `SF', clear
	keep if anio == `anioref' & inlist(clave, "XAC33A", "XAC33B", "XAC33C", "XAC33F", "XAC33J", "XAC33K", "XAC33L", "XAC33O")
	rename nl v
	g lab = ""
	forvalues i = 1/`=_N' {
		replace lab = `"`nom`=clave[`i']''"' in `i'
	}
	g claveAncla = "eofp:" + clave
	keep anio clave lab v claveAncla
	append using `G1'
	summarize v if substr(clave, 1, 5) == "XAC33", meanonly
	replace v = v - r(sum) if clave == "R33resto"
	drop if clave == "R33resto" & abs(v) < 0.5
	save `G1', replace
	* Paquete: anclas PPEF (R28, convenios, subsidios, salud) + pp del ramo 33 *
	use `PP', clear
	keep if anio == `aniope' & ramoN == 33 & divFEDE == "Aportaciones"
	g clave = "pp" + string(pp)
	g claveAncla = "pef:33/" + string(pp)
	rename (gasto desc_pp) (v lab)
	keep anio clave lab v claveAncla
	tempfile G2
	save `G2'
	use `AN', clear
	keep if anio == `aniope'
	keep anio anclaR28 anclaConv anclaSubs anclaSalud
	rename (anclaR28 anclaConv anclaSubs anclaSalud) (vR28 vConv vSubs vSalud)
	reshape long v, i(anio) j(clave) string
	g lab = cond(clave == "R28", "Participaciones (R28, `fuenteAncla_`aniope'')", cond(clave == "Conv", "Convenios (`fuenteAncla_`aniope'')", cond(clave == "Subs", "Subsidios R23 (`fuenteAncla_`aniope'')", "Salud federalizado (`fuenteAncla_`aniope'')")))
	g claveAncla = "fed:ancla" + clave
	drop if v == . | v == 0
	append using `G2'
	append using `G1'
	g reclamadoPor = ""
	sort anio clave
	save `GR', replace
}
* reclamos de las anclas de los flujos recibe en página; lo no reclamable (suma, statajson, pef fuera del ramo 33 del Paquete…) entra como línea negativa *
quietly {
	use `GR', clear
	forvalues i = 1/`NP' {
		if `pal_abrir`i'' == 0 | "`pal_lado`i''" != "recibe" continue
		local id "`pal_id`i''"
		foreach t in `anioref' `aniope' {
			local reclamado = 0
			foreach c of local claims_`id'_`t' {
				count if anio == `t' & claveAncla == "`c'" & reclamadoPor == ""
				if r(N) == 1 {
					summarize v if anio == `t' & claveAncla == "`c'", meanonly
					local reclamado = `reclamado' + r(mean)
					replace reclamadoPor = "`id'" if anio == `t' & claveAncla == "`c'"
				}
				else {
					count if anio == `t' & claveAncla == "`c'" & reclamadoPor != ""
					if r(N) == 1 {
						noisily di as err "FederacionNLQuintiles (Q.6b): el componente `c' de `t' lo reclaman dos flujos (`=reclamadoPor[1]' y `id'). No se exporta."
						exit 459
					}
				}
			}
			local resto = `total_`id'_`t'' - `reclamado'
			if abs(`resto') >= 0.5 {
				local N1 = _N + 1
				set obs `N1'
				replace anio = `t' in `N1'
				replace clave = "menos_`id'" in `N1'
				replace lab = "− `pal_etiqueta`i'' (parte anclada fuera de los componentes `=cond(`t' == `anioref', "EOFP", "PPEF")': `spec_`id'_`t'')" in `N1'
				replace v = -`resto' in `N1'
				replace claveAncla = "" in `N1'
				replace reclamadoPor = "`id'" in `N1'
			}
		}
	}
	drop if reclamadoPor != "" & substr(clave, 1, 6) != "menos_"
	sort anio clave
	save `GR', replace
	foreach t in `anioref' `aniope' {
		summarize v if anio == `t', meanonly
		local grisComp_`t' = r(sum)
	}
}
foreach t in `anioref' `aniope' {
	if reldif(`grisComp_`t'', `gris_`t'') > 1e-6 {
		noisily list if anio == `t', noobs clean
		di as err "FederacionNLQuintiles (Q.6b): los componentes de la caja gris `t' (`grisComp_`t'') no suman la caja gris calculada (`gris_`t''). No se exporta."
		exit 459
	}
}
noisily di in g "  Compuerta Q.6b (Σ componentes de la caja gris = caja gris calculada, ambos años): " in y "PASÓ" in g "."

*** 6 FLUJOS POR CELDA, CIERRES (compuerta Q.6c) Y TABLAS ***
noisily di _newline in g "{bf:6. Flujos por quintil (abiertos), nodos cerrados y cierres contables}"
quietly {
	use `CL', clear
	expand 2, g(dup)
	g int anio = cond(dup == 0, `anioref', `aniope')
	drop dup
	g lado = ""
	g byte abrir = .
	g int orden = .
	g double total = .
	g double totalS1 = .
	g double totalS3 = .
	forvalues i = 1/`NP' {
		local id "`pal_id`i''"
		replace lado = "`pal_lado`i''" if id == "`id'"
		replace abrir = `pal_abrir`i'' if id == "`id'"
		replace orden = `i' if id == "`id'"
		if `pal_abrir`i'' == 0 continue
		foreach t in `anioref' `aniope' {
			replace total = `total_`id'_`t'' if id == "`id'" & anio == `t'
			replace totalS1 = `totalS1_`id'_`t'' if id == "`id'" & anio == `t'
			replace totalS3 = `totalS3_`id'_`t'' if id == "`id'" & anio == `t'
		}
	}
	g double v = total*share
	g double vS1 = totalS1*share
	g double vS3 = totalS3*share
	sort anio orden q
	tempfile FL
	save `FL'
}
* Q.6c: Σ celdas = total por flujo abierto *
local nf = 0
local rdCel = 0
quietly {
	use `FL', clear
	keep if abrir == 2
	collapse (sum) v (first) total, by(anio id)
	g double rd = reldif(v, total)
	summarize rd, meanonly
	local rdCel = r(max)
	count if rd > 1e-9
	local nf = r(N)
}
if `nf' > 0 {
	noisily list, noobs clean
	di as err "FederacionNLQuintiles (Q.6c): Σ celdas ≠ total en `nf' flujos abiertos. No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.6c (Σ celdas por quintil = total del flujo, flujos abiertos, 1e-9; reldif máx " in y %9.2e `rdCel' in g "): " in y "PASÓ" in g "."
noisily di in g "  Compuerta Q.6 (cierres contables, ambos años): " in y "PASÓ" in g "."

* Tablas quintil × flujo (mdp) para el reporte *
foreach t in `anioref' `aniope' {
	foreach lado in paga aparte recibe {
		noisily di _newline in g "{bf:  `t' — lado `lado' por quintil estatal (mdp; `=cond("`lado'" == "recibe", "`tipoRecibe_`t'', `fuenteRecibe_`t''", "`tipoPaga_`t''")')}"
		noisily di in g "  Flujo" _col(14) %10s "Q1" _col(26) %10s "Q2" _col(38) %10s "Q3" _col(50) %10s "Q4" _col(62) %10s "Q5" _col(74) %12s "Total" _col(88) "estado · ancla · sellos"
		forvalues i = 1/`NP' {
			if "`pal_lado`i''" != "`lado'" | `pal_abrir`i'' == 0 continue
			local id "`pal_id`i''"
			quietly use `FL', clear
			quietly keep if anio == `t' & id == "`id'"
			forvalues qq = 1/5 {
				quietly summarize v if q == `qq', meanonly
				local f`qq' = r(mean)/1e6
			}
			if `pal_abrir`i'' == 2 noisily di in g "  `id'" _col(14) in y %10.1fc `f1' _col(26) %10.1fc `f2' _col(38) %10.1fc `f3' _col(50) %10.1fc `f4' _col(62) %10.1fc `f5' _col(74) %12.1fc `total_`id'_`t''/1e6 _col(88) in g "abierto · `spec_`id'_`t''" cond(`sup_`id'_`t'', " (SUPUESTO)", "") " · n<`umbral': [`bajo_`id'']" " · top-1≥`selloTop1'%: [`top_`id'']" cond(`pal_banda`i'', " · banda [S1, S3] = [" + string(`totalS1_`id'_`t''/1e6, "%10.1fc") + ", " + string(`totalS3_`id'_`t''/1e6, "%10.1fc") + "]", "")
			else noisily di in g "  `id'*" _col(14) in y %10s "—" _col(26) %10s "—" _col(38) %10s "—" _col(50) %10s "—" _col(62) %10s "—" _col(74) %12.1fc `total_`id'_`t''/1e6 _col(88) in g "SIN ABRIR (`pal_grupo`i'') · `spec_`id'_`t''" cond(`sup_`id'_`t'', " (SUPUESTO)", "") " · NL top-1 " string(`conc_`id'', "%5.1f") " % · n<`umbral': [`bajo_`id'']"
		}
		if "`lado'" == "recibe" {
			noisily di in g "  Caja gris CALCULADA (tarjeta − Σ etiquetados)" _col(74) in y %12.1fc `gris_`t''/1e6 in g "  = " in y %5.1f `grisPct_`t'' in g " % del recibe"
			noisily di in g "  Σ recibe" _col(74) in y %12.1fc `sumRec_`t''/1e6 in g " = tarjeta " in y %12.1fc `tjRec_`t''/1e6
		}
		if "`lado'" == "paga" noisily di in g "  Σ paga" _col(74) in y %12.1fc `sumPaga_`t''/1e6 in g " = tarjeta " in y %12.1fc `tjPaga_`t''/1e6 in g " · banda [S1, S3] = [" in y %10.1fc `pgS1_`t''/1e6 ", " %10.1fc `pgS3_`t''/1e6 in g "]"
	}
}
* Inventario (abrir 0): Σ muestra NL por quintil (mdp, pesos PE), n, top-1 *
noisily di _newline in g "{bf:  Inventario (abrir 0): gasto distribuido por el motor en la muestra NL — Σ por quintil (mdp, pesos PE `aniope'), n por celda, top-1 por celda}"
noisily di in g "  Flujo" _col(16) %10s "Q1" _col(28) %10s "Q2" _col(40) %10s "Q3" _col(52) %10s "Q4" _col(64) %10s "Q5" _col(76) %12s "Σ NL" _col(90) "variable · fuentes alternas"
forvalues i = 1/`NP' {
	if `pal_abrir`i'' != 0 continue
	local id "`pal_id`i''"
	quietly use `CL', clear
	quietly keep if id == "`id'"
	forvalues qq = 1/5 {
		quietly summarize sumaQ if q == `qq', meanonly
		local f`qq' = r(mean)/1e6
		quietly summarize n if q == `qq', meanonly
		local n`qq' = r(mean)
		quietly summarize concTop1 if q == `qq', meanonly
		local c`qq' = r(mean)
	}
	local vn "`pal_vnombre`i''"
	local alt ""
	if "`inv_rd_`vn''" != "" & "`inv_rd_`vn''" != "." local alt "aport `=string(`inv_sA_`vn''/1e6, "%12.1fc")' / perfiles `=string(`inv_sP_`vn''/1e6, "%12.1fc")' mdp, reldif `=string(`inv_rd_`vn'', "%8.1e")'"
	noisily di in g "  `id'" _col(16) in y %10.1fc `f1' _col(28) %10.1fc `f2' _col(40) %10.1fc `f3' _col(52) %10.1fc `f4' _col(64) %10.1fc `f5' _col(76) %12.1fc `suma_`id''/1e6 _col(90) in g "`pal_variable`i'' · `alt'"
	noisily di in g "    n" _col(16) in y %10.0f `n1' _col(28) %10.0f `n2' _col(40) %10.0f `n3' _col(52) %10.0f `n4' _col(64) %10.0f `n5' _col(76) in g %12s "n<`umbral': " "[`bajo_`id'']"
	noisily di in g "    top-1" _col(16) in y %10.1f `c1' _col(28) %10.1f `c2' _col(40) %10.1f `c3' _col(52) %10.1f `c4' _col(64) %10.1f `c5' _col(76) in g %12s "NL top-1 " in y %5.1f `conc_`id'' in g " % · anclas candidatas: `pal_anclas`i''"
}

* 6.1 Neta por quintil (solo si el parámetro está encendido: juicio de cobertura de Ricardo) *
if `netaQ' {
	quietly {
		use `FL', clear
		keep if abrir == 2 & inlist(lado, "paga", "recibe")
		g double sgn = cond(lado == "recibe", v, -v)
		collapse (sum) neta = sgn, by(anio q)
		tempfile NQ
		save `NQ'
	}
	noisily di _newline in g "  Neta por quintil (parámetro neta_por_quintil = 1): recibe abierto − paga abierto, mdp (los flujos cerrados y la caja gris NO entran)"
	foreach t in `anioref' `aniope' {
		local l "  `t'"
		forvalues qq = 1/5 {
			quietly summarize neta if anio == `t' & q == `qq', meanonly
			local l "`l'" + " Q`qq' " + string(r(mean)/1e6, "%12.1fc")
		}
		noisily di in y "`l'"
	}
}

*** 7 EXPORTACIÓN JSON (contrato hermano nl.federacion-quintiles/v2, dirigido por la paleta) ***
noisily di _newline in g "{bf:7. Exportación}"
local json `"`site'/users/$id/nodos/federacion-nl-quintiles.json"'
local sellocorrida = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
* listas del alcance *
foreach l in pagaAb pagaCe aparte recAb recCe inv supAnc grupos {
	local L_`l' ""
}
local gruposVistos ""
forvalues i = 1/`NP' {
	local id "`pal_id`i''"
	local lado "`pal_lado`i''"
	local ab = `pal_abrir`i''
	if `ab' == 0 local L_inv `"`L_inv', "`id'""'
	else if "`lado'" == "aparte" local L_aparte `"`L_aparte', "`id'""'
	else if "`lado'" == "paga" & `ab' == 2 local L_pagaAb `"`L_pagaAb', "`id'""'
	else if "`lado'" == "paga" & `ab' == 1 local L_pagaCe `"`L_pagaCe', "`id'""'
	else if "`lado'" == "recibe" & `ab' == 2 local L_recAb `"`L_recAb', "`id'""'
	else if "`lado'" == "recibe" & `ab' == 1 local L_recCe `"`L_recCe', "`id'""'
	if `ab' >= 1 {
		foreach t in `anioref' `aniope' {
			if `sup_`id'_`t'' local L_supAnc `"`L_supAnc', {"id": "`id'", "anio": `t', "ancla": "`spec_`id'_`t''"}"'
		}
	}
	if "`pal_grupo`i''" != "" & `ab' >= 1 {
		local g "`pal_grupo`i''"
		if strpos(" `gruposVistos' ", " `g' ") == 0 {
			local gruposVistos "`gruposVistos' `g'"
			local ids ""
			forvalues j = 1/`NP' {
				if "`pal_grupo`j''" == "`g'" & `pal_abrir`j'' >= 1 local ids `"`ids', "`pal_id`j''""'
			}
			local ids = substr(`"`ids'"', 3, .)
			local L_grupos `"`L_grupos', {"grupo": "`g'", "ids": [`ids']}"'
		}
	}
}
foreach l in pagaAb pagaCe aparte recAb recCe inv supAnc grupos {
	local L_`l' = substr(`"`L_`l''"', 3, .)
}
local L_params ""
local L_paramsSup ""
foreach p of global NLQ_params {
	local L_params `"`L_params', "`p'": ${NLQP_`p'}"'
	if ${NLQPS_`p'} local L_paramsSup `"`L_paramsSup', "`p'""'
}
local L_params = substr(`"`L_params'"', 3, .)
local L_paramsSup = substr(`"`L_paramsSup'"', 3, .)

tempname fh
capture erase `"`json'"'
file open `fh' using `"`json'"', write text replace
file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'nl.federacion-quintiles/v2`q',"' _n
file write `fh' `"  `q'contrato_base`q': {`q'esquema`q': `q'`fed_esq'`q', `q'archivo`q': `q'federacion-nl.json`q', `q'sha256`q': `q'`fed_sha'`q', `q'generado_en`q': `q'`fed_gen'`q', `q'modo`q': `q'`fed_modo'`q'},"' _n
file write `fh' `"  `q'producto`q': `q'`nl_producto'`q',"' _n
file write `fh' `"  `q'titulo`q': `q'`nl_titulo'`q',"' _n
file write `fh' `"  `q'subtitulo`q': `q'`nl_subtitulo'`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
file write `fh' `"  `q'anio_politica`q': `aniope',"' _n
file write `fh' `"  `q'eje`q': {`q'tipo`q': `q'quintil`q', `q'ambito`q': `q'estatal`q', `q'etiquetas`q': [`q'Q1`q', `q'Q2`q', `q'Q3`q', `q'Q4`q', `q'Q5`q'], `q'ingreso`q': `q'ingreso bruto total del hogar (ingbrutotot post-ajuste a Cuentas Nacionales) dividido entre los integrantes del hogar (ing_decil_pc del motor, Households.do:2591-2596)`q', `q'unidad`q': `q'persona: todas las personas del hogar heredan el quintil del hogar`q', `q'ponderacion`q': `q'xtile n(5) con pw = factor/integrantes (peso de hogar), re-rankeado dentro de la muestra NL (entidad 19); idéntico a ceil(decil estatal/2) y a la familia nle de EntidadNL.do`q', `q'comparacion_nacional`q': `q'D1: los deciles/quintiles nacionales (familia nl) quedan como nota, no como eje`q', `q'umbral_n`q': `umbral', `q'enigh`q': `enigh'},"' _n
file write `fh' `"  `q'parametros`q': {`L_params', `q'supuestos`q': [`L_paramsSup'], `q'nota`q': `q'parámetros de la paleta (01_modulos/nl-flujos.do, _nlparam); los marcados supuesto llevan default del agente y los fija Ricardo`q'},"' _n
file write `fh' `"  `q'procedencia`q': {"' _n
file write `fh' `"    `q'version_motor`q': `q'`nl_vmotor'`q', `q'version_capa_nl`q': `q'`nl_vnl'`q', `q'version_capa_driver`q': `q'`nl_vdriver'`q', `q'repositorio`q': `q'`nl_repo'`q',"' _n
file write `fh' `"    `q'driver`q': `q'01_modulos/FederacionNLQuintiles.do v`driver_v'`q', `q'paleta`q': {`q'archivo`q': `q'01_modulos/nl-flujos.do`q', `q'sha256`q': `q'`paleta_sha'`q', `q'mtime`q': `q'`paleta_mtime'`q', `q'flujos`q': `NP'}, `q'log`q': `q'`logfile'`q', `q'generado_en`q': `q'`sellocorrida'`q',"' _n
file write `fh' `"    `q'fuentes_congeladas_motor`q': `q'$fuentes`q', `q'fuentes_congeladas_capa`q': `q'$nlfuentes`q',"' _n
file write `fh' `"    `q'frontera`q': `q'producto de la capa NL sobre el canal del motor y el contrato federacion-nl.json, dirigido por la paleta de flujos: reparte por quintil estatal los montos anclados que la paleta declare; ningún monto nuevo se calcula fuera del canal salvo las anclas suma (marcadas supuesto); el motor no se modifica; la metodología (qué flujos, qué claves, qué anclas) la fija Ricardo en la paleta`q',"' _n
file write `fh' `"    `q'fuentes`q': ["' _n
file write `fh' `"      {`q'id`q': `q'aportaciones`q', `q'fuente`q': `q'users/$id/aportaciones.dta (objeto del pipeline SIM.do §7, corte entidad 19): <X>_Sim, alum_basica, inst_6, factor, ingbrutotot y las variables aport: de la paleta`q', `q'mtime`q': `q'`aport_mtime'`q', `q'sha256`q': `q'`aport_sha'`q'},"' _n
if `usaPerfiles' file write `fh' `"      {`q'id`q': `q'perfiles`q', `q'fuente`q': `q'master/perfiles`aniope'.dta (objeto del motor, corte entidad 19; compuerta Q.7 = mismas personas, factor e ingbrutotot que aportaciones.dta): variables perfiles: de la paleta`q', `q'mtime`q': `q'`perf_mtime'`q', `q'sha256`q': `q'`perf_sha'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'entidad_nl`q', `q'fuente`q': `q'statajson_entidad-nl.json (EntidadNL.do): compuertas Q.1–Q.3 (dis<fam>nle<dec>, Rec<X>nl, concTop1<X>nl) y anclas statajson:`q', `q'generado_en`q': `q'`ent_gen'`q', `q'sha256`q': `q'`ent_sha'`q', `q'enigh`q': `enigh'},"' _n
file write `fh' `"      {`q'id`q': `q'federacion_nl`q', `q'fuente`q': `q'federacion-nl.json (FederacionNL.do): paga por impuesto y año (observado / ILIF), recibe por fondo (EOFP) y anclas del Paquete (PEF.dta divFEDE); anclas fed: y eofp:`q', `q'generado_en`q': `q'`fed_gen'`q', `q'sha256`q': `q'`fed_sha'`q', `q'modo`q': `q'`fed_modo'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'pef_dta`q', `q'fuente`q': `q'master/PEF.dta del motor: por ramo y programa presupuestario, entidad 19, `fuenteAncla_`aniope'' `aniope' y CP `anioref'; anclas pef:`q', `q'mtime`q': `q'`pef_mtime'`q'}"' _n
file write `fh' "    ]," _n
file write `fh' `"    `q'compuertas`q': {"' _n
file write `fh' `"      `q'P0_paleta`q': `q'`NP' flujos con id único, lado y abrir válidos, variable fuente:nombre y anclas resolubles en ambos años para abrir ≥ 1`q',"' _n
file write `fh' `"      `q'Q0_muestra`q': `q'n≥`umbral' personas y hogares por quintil estatal: mín `nPersMin' personas, `nHogMin' hogares`q',"' _n
file write `fh' `"      `q'Q1_construccion`q': `q'participación por decil estatal de AlTrabajo/AlCapital/AlConsumo/ImpAport/IVA/IEPSNP/IEPSP/ISAN/IMPORT = dis<fam>nle<dec> del statajson en `nQ1' celdas, reldif máx `=string(`rdQ1', "%9.2e")' (tol 1e-6)`q',"' _n
file write `fh' `"      `q'Q2_coherencia`q': `q'Σ <X>_Sim×factor en NL (aportaciones.dta) vs Rec<X>nl del statajson: <X>_Sim = <X> × (<X>PIB/100 × pibY)/ILIF (TasasEfectivas.ado §7.1), cociente uniforme por persona; causa = redondeo del parámetro *PIB de SIM.do §4.1 a 3 decimales de % del PIB; las participaciones por quintil son invariantes. reldif máx `=string(`rdQ2', "%9.2e")' (tol 1e-2): `q2txt'`q',"' _n
file write `fh' `"      `q'Q3_concTop1`q': `q'concTop1<X> recalculado = statajson, reldif máx `=string(`rdQ3', "%9.2e")' (tol 1e-6)`q',"' _n
file write `fh' `"      `q'Q4_identidad`q': `q'federacion-nl.json y statajson de la capa `nl_vnl', motor `nl_vmotor', PE `aniope', ENIGH `enigh'; manifest de la sesión `nl_vdriver' (version_capa_driver)`q',"' _n
file write `fh' `"      `q'Q5_pef_pp`q': `q'Σ pp ramo 33 entidad 19 `aniope' = anclaR33 del contrato (1e-9); pp 13/15 FONE y pp 2 FASSA verificados por descripción`q',"' _n
file write `fh' `"      `q'Q6_cierres`q': `q'`anioref': paga reldif `=string(`rdPaga_`anioref'', "%9.2e")', aparte `=string(`rdCuo_`anioref'', "%9.2e")', recibe `=string(`rdRec_`anioref'', "%9.2e")'; `aniope': paga `=string(`rdPaga_`aniope'', "%9.2e")', aparte `=string(`rdCuo_`aniope'', "%9.2e")', recibe `=string(`rdRec_`aniope'', "%9.2e")' (tol 1e-6; tarjetas = cifras.pagaS0NL/recibeNL/cuotasIMSSNL y pagaPES0NL/recibePENL/cuotasPENL); Σ celdas = total por flujo abierto (reldif máx `=string(`rdCel', "%9.2e")'); Σ componentes de la caja gris = caja gris calculada`q',"' _n
file write `fh' `"      `q'Q7_perfiles`q': `q'`=cond(`usaPerfiles', "perfiles" + "`aniope'" + ".dta entidad 19 = aportaciones.dta en personas, factor e ingbrutotot (reldif máx " + string(`rdQ7', "%9.2e") + ", tol 1e-9); Σ por fuente y reldif en paleta[].fuentes_alternas, sin elegir", "la paleta no pide perfiles:")'`q'"' _n
file write `fh' "    }," _n
file write `fh' `"    `q'supuestos`q': {"' _n
file write `fh' `"      `q'claves_un_vintage`q': `q'las participaciones por quintil salen de la corrida vigente (ENIGH `enigh', PE `aniope', aportaciones.dta / perfiles`aniope'.dta) y se aplican a los montos de ambos años`q',"' _n
file write `fh' `"      `q'reparto`q': `q'flujo quintil→nodo = total anclado del flujo (paleta) × participación del quintil en Σ variable×factor de la muestra NL (hogar→quintil→suma); abierto = cinco celdas con sellos (n, hogares, concTop1, cumpleN, selloTop1); cerrado = nodo sin abrir con sellos de NL; inventario = solo cifras`q',"' _n
file write `fh' `"      `q'capital_abierto`q': `q'C3 (decisión 2026-10-09): ISR PM e ISR PF se abren por quintil con la distribución del objeto de incidencia; sus límites se muestran por celda (halo de la banda [S1, S3] = share × banda del contrato; badge concTop1 por celda ≥ sello_top1 %; n < umbral)`q',"' _n
file write `fh' `"      `q'caja_gris`q': `q'CALCULADA = tarjeta recibe − Σ flujos recibe con abrir ≥ 1; sus componentes son los agregados EOFP/PPEF no reclamados por ninguna ancla, más una línea negativa por cada parte anclada fuera de esos componentes (suma, statajson, pef fuera del ramo 33 del Paquete); si Ricardo abre más flujos, el gris encoge solo`q',"' _n
file write `fh' `"      `q'anclas_suma`q': `q'ancla suma = Σ variable×factor de la muestra NL en pesos del PE `aniope', aplicada a ambos años: SUPUESTO editable, marcado en flujos[].ancla.supuesto y en alcance.anclas_supuesto; los flujos del inventario arrancan con suma hasta que Ricardo fije el ancla`q',"' _n
file write `fh' `"      `q'recibe_fone`q': `q'incidencia en especie a costo de provisión: FONE repartido por alumnos de educación básica pública expandidos; costo por alumno = total / alumnos; la aportación es proxy parcial`q',"' _n
file write `fh' `"      `q'recibe_salud`q': `q'FASSA (+ PSS en el observado) por afiliación a institución federal/estatal de salud (inst_6, D3); DIVERGENCIA DECLARADA: la clave del motor (benef_ssa) reparte por gasto privado en salud; el motor no se toca`q',"' _n
file write `fh' `"      `q'pss_paquete`q': `q'`=cond(`pssFlag_`aniope'', "el PPEF `aniope' no trae PSS (R47 salud federalizado) por entidad: el nodo salud del Paquete es solo FASSA; nota de composición obligatoria (resolución 2026-10-08)", "el Paquete trae salud federalizado por entidad")'`q',"' _n
file write `fh' `"      `q'neta_por_quintil`q': `q'`=cond(`netaQ', "ENCENDIDA por parámetro: recibe abierto − paga abierto por quintil (los flujos cerrados y la caja gris no entran)", "apagada (resolución 2026-10-08): no existe neta por quintil; el saldo se muestra solo agregado")'`q',"' _n
file write `fh' `"      `q'version_capa`q': `q'el hermano hereda version_capa_nl del contrato base (`nl_vnl') y declara el manifest de la sesión como version_capa_driver (`nl_vdriver'): regenerable sin re-sellar el contrato base`q',"' _n
file write `fh' `"      `q'anios`q': `q'D5: solo anio_referencia (observado, EOFP y recaudación a diciembre) y anio_politica (Paquete: PPEF por pp e ILIF)`q',"' _n
file write `fh' `"      `q'unidades`q': `q'todos los montos (v, vS1, vS3, total, totalS1, totalS3, paga*, recibe, gris, tj*, sum*, sumaNL, sumaQ, grisComponentes.v, netaQuintil.neta) en pesos corrientes del año (sumaNL/sumaQ en pesos del PE); costoUnidad en pesos por unidad; share en fracción 0–1; concTop1 y grisPct en %; ÷1e6 = mdp`q'"' _n
file write `fh' "    }" _n
file write `fh' "  }," _n

* 7.1 muestra *
quietly use `MU', clear
file write `fh' `"  `q'muestra`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'q`q': `=q[`i']'"'
	foreach v in nPers nHog pob ingpcMin ingpcMax {
		_nlqnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

* 7.2 unidades en especie *
file write `fh' `"  `q'unidades`q': {`q'poblacionENIGH`q': `=string(`pobNL_enigh', "%25.17g")', `q'nota`q': `q'personas expandidas (factor) de la muestra NL de la ENIGH `enigh'; los per cápita del contrato base usan CONAPO, no esta población`q', `q'flujos`q': ["'
local j = 0
forvalues i = 1/`NP' {
	if `"`pal_unidad`i''"' == "" continue
	local ++j
	_nlqtxt `"`pal_unidad`i''"'
	file write `fh' `"`=cond(`j' > 1, ", ", "")'{`q'id`q': `q'`pal_id`i''`q', `q'unidad`q': `q'`r(t)'`q', `q'n`q': `=string(`unid_`pal_id`i''', "%25.17g")'}"'
}
file write `fh' "]}," _n

* 7.3 paleta *
file write `fh' `"  `q'paleta`q': ["' _n
forvalues i = 1/`NP' {
	local id "`pal_id`i''"
	_nlqtxt `"`pal_etiqueta`i''"'
	local tEt `"`r(t)'"'
	_nlqtxt `"`pal_clave`i''"'
	local tCl `"`r(t)'"'
	_nlqtxt `"`pal_nota`i''"'
	local tNo `"`r(t)'"'
	_nlqtxt `"`pal_anclas`i''"'
	local tAn `"`r(t)'"'
	local bajo = subinstr(trim("`bajo_`id''"), " ", ", ", .)
	local top = subinstr(trim("`top_`id''"), " ", ", ", .)
	local vn "`pal_vnombre`i''"
	local alt "null"
	if "`inv_rd_`vn''" != "" & "`inv_rd_`vn''" != "." {
		_nlqnum "`inv_sA_`vn''"
		local a1 "`r(n)'"
		_nlqnum "`inv_sP_`vn''"
		local a2 "`r(n)'"
		_nlqnum "`inv_rd_`vn''"
		local alt `"{`q'aport`q': `a1', `q'perfiles`q': `a2', `q'reldif`q': `r(n)', `q'nPosAport`q': `inv_nA_`vn'', `q'nPosPerfiles`q': `inv_nP_`vn''}"'
	}
	_nlqnum "`suma_`id''"
	local sN "`r(n)'"
	_nlqnum "`conc_`id''"
	local cN "`r(n)'"
	_nlqnum "`unid_`id''"
	local uN "`r(n)'"
	file write `fh' `"    {`q'orden`q': `i', `q'id`q': `q'`id'`q', `q'lado`q': `q'`pal_lado`i''`q', `q'abrir`q': `pal_abrir`i'', `q'estado`q': `q'`pal_estado`i''`q', `q'grupo`q': `q'`pal_grupo`i''`q', `q'banda`q': `=cond(`pal_banda`i'', "true", "false")', `q'etiqueta`q': `q'`tEt'`q', `q'variable`q': {`q'fuente`q': `q'`pal_vfuente`i''`q', `q'nombre`q': `q'`pal_vnombre`i''`q'}, `q'clave`q': `q'`tCl'`q', `q'nota`q': `q'`tNo'`q', `q'anclas_candidatas`q': `q'`tAn'`q', `q'ancla_ref`q': `q'`pal_ancla_ref`i''`q', `q'ancla_pe`q': `q'`pal_ancla_pe`i''`q', `q'unidad`q': `q'`pal_unidad`i''`q', `q'sumaNL`q': `sN', `q'concTop1NL`q': `cN', `q'nMin`q': `nMin_`id'', `q'nNL`q': `nNL_`id'', `q'unidades`q': `uN', `q'celdasBajoUmbral`q': [`bajo'], `q'celdasTop1`q': [`top'], `q'fuentes_alternas`q': `alt'}`=cond(`i' < `NP', ",", "")'"' _n
}
file write `fh' "  ]," _n

* 7.4 claves (participaciones por quintil, todos los flujos, independientes del año) *
quietly use `CL', clear
quietly {
	g int orden = .
	forvalues i = 1/`NP' {
		replace orden = `i' if id == "`pal_id`i''"
	}
	sort orden q
}
file write `fh' `"  `q'claves`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'id`q': `q'`=id[`i']'`q', `q'q`q': `=q[`i']'"'
	foreach v in share sumaQ n nHog concTop1 {
		_nlqnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' `", `q'cumpleN`q': `=cond(cumpleN[`i'], "true", "false")', `q'selloTop1`q': `=cond(selloTop1[`i'], "true", "false")'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "  ]," _n

* 7.5 anual *
file write `fh' `"  `q'anual`q': ["' _n
local j = 0
foreach t in `anioref' `aniope' {
	local ++j
	file write `fh' `"    {`q'anio`q': `t', `q'tipoPaga`q': `q'`tipoPaga_`t''`q', `q'tipoRecibe`q': `q'`tipoRecibe_`t''`q', `q'fuenteRecibe`q': `q'`fuenteRecibe_`t''`q'"'
	foreach v in pagaS0 pagaS1 pagaS3 {
		local s = substr("`v'", 5, 2)
		_nlqnum "`pg`s'_`t''"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	foreach v in pobNL recibe gris grisPct sumInv grisTodos grisTodosPct tjPaga tjCuo tjRec sumPaga sumCuo sumRec rdPaga rdCuo rdRec {
		_nlqnum "``v'_`t''"
		local vn = cond("`v'" == "sumInv", "sumInventario", cond("`v'" == "grisTodos", "grisSiTodos", cond("`v'" == "grisTodosPct", "grisSiTodosPct", "`v'")))
		file write `fh' `", `q'`vn'`q': `r(n)'"'
	}
	file write `fh' `", `q'pssFlag`q': `=cond(`pssFlag_`t'', "true", "false")'}`=cond(`j' < 2, ",", "")'"' _n
}
file write `fh' "  ]," _n

* 7.6 flujos (por año y flujo en página: totales, ancla, celdas si abierto) *
file write `fh' `"  `q'flujos`q': ["' _n
local first = 1
foreach t in `anioref' `aniope' {
	forvalues i = 1/`NP' {
		if `pal_abrir`i'' == 0 continue
		local id "`pal_id`i''"
		_nlqtxt `"`pal_etiqueta`i''"'
		local tEt `"`r(t)'"'
		_nlqtxt `"`det_`id'_`t''"'
		local tDet `"`r(t)'"'
		local recl ""
		foreach c of local claims_`id'_`t' {
			local recl `"`recl', "`c'""'
		}
		local recl = substr(`"`recl'"', 3, .)
		_nlqnum "`total_`id'_`t''"
		local tot "`r(n)'"
		_nlqnum "`totalS1_`id'_`t''"
		local t1 "`r(n)'"
		_nlqnum "`totalS3_`id'_`t''"
		local t3 "`r(n)'"
		_nlqnum "`conc_`id''"
		local cNL "`r(n)'"
		local costo "null"
		if `"`pal_unidad`i''"' != "" & `unid_`id'' > 0 {
			_nlqnum "`=`total_`id'_`t''/`unid_`id'''"
			local costo "`r(n)'"
		}
		if !`first' file write `fh' "," _n
		local first = 0
		file write `fh' `"    {`q'anio`q': `t', `q'id`q': `q'`id'`q', `q'lado`q': `q'`pal_lado`i''`q', `q'abrir`q': `pal_abrir`i'', `q'estado`q': `q'`pal_estado`i''`q', `q'abierto`q': `=cond(`pal_abrir`i'' == 2, "true", "false")', `q'grupo`q': `q'`pal_grupo`i''`q', `q'banda`q': `=cond(`pal_banda`i'', "true", "false")', `q'etiqueta`q': `q'`tEt'`q', `q'total`q': `tot', `q'totalS1`q': `t1', `q'totalS3`q': `t3', `q'ancla`q': {`q'spec`q': `q'`spec_`id'_`t''`q', `q'valor`q': `tot', `q'supuesto`q': `=cond(`sup_`id'_`t'', "true", "false")', `q'vintagePE`q': `=cond(`sj_`id'_`t'', "true", "false")', `q'detalle`q': `q'`tDet'`q', `q'reclama`q': [`recl']}, `q'costoUnidad`q': `costo', `q'unidad`q': `q'`pal_unidad`i''`q', `q'concTop1NL`q': `cNL', `q'nMin`q': `nMin_`id'', `q'celdas`q': ["'
		if `pal_abrir`i'' == 2 {
			quietly use `FL', clear
			quietly keep if anio == `t' & id == "`id'"
			quietly sort q
			forvalues r = 1/`=_N' {
				file write `fh' `"`=cond(`r' > 1, ", ", "")'{`q'q`q': `=q[`r']'"'
				foreach v in v vS1 vS3 share n nHog concTop1 {
					_nlqnum "`v'[`r']"
					file write `fh' `", `q'`v'`q': `r(n)'"'
				}
				file write `fh' `", `q'cumpleN`q': `=cond(cumpleN[`r'], "true", "false")', `q'selloTop1`q': `=cond(selloTop1[`r'], "true", "false")'}"'
			}
		}
		file write `fh' "]}"
	}
}
file write `fh' _n "  ]," _n

* 7.7 componentes de la caja gris *
quietly use `GR', clear
file write `fh' `"  `q'grisComponentes`q': ["' _n
forvalues i = 1/`=_N' {
	_nlqtxt `"`=lab[`i']'"'
	local labT `"`r(t)'"'
	_nlqnum "v[`i']"
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'clave`q': `q'`=clave[`i']'`q', `q'lab`q': `q'`labT'`q', `q'v`q': `r(n)'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "  ]," _n

* 7.8 neta por quintil (solo si el parámetro está encendido) *
if `netaQ' {
	quietly use `NQ', clear
	quietly sort anio q
	file write `fh' `"  `q'netaQuintil`q': ["' _n
	forvalues i = 1/`=_N' {
		_nlqnum "neta[`i']"
		file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'q`q': `=q[`i']', `q'neta`q': `r(n)'}`=cond(`i' < _N, ",", "")'"' _n
	}
	file write `fh' "  ]," _n
}

* 7.9 alcance derivado de la paleta *
_nlqtxt `"`fed_excluye'"'
local tEx `"`r(t)'"'
_nlqtxt `"`fed_saldo'"'
local tSa `"`r(t)'"'
file write `fh' `"  `q'alcance`q': {`q'paga_abiertos`q': [`L_pagaAb'], `q'paga_cerrados`q': [`L_pagaCe'], `q'aparte`q': [`L_aparte'], `q'recibe_abiertos`q': [`L_recAb'], `q'recibe_cerrados`q': [`L_recCe'], `q'inventario`q': [`L_inv'], `q'grupos`q': [`L_grupos'], `q'anclas_supuesto`q': [`L_supAnc'], `q'neta_por_quintil`q': `=cond(`netaQ', "true", "false")', `q'nodo_saldo`q': `q'`tSa'`q', `q'excluye`q': `q'`tEx'`q', `q'nota`q': `q'listas derivadas de la paleta: la vista arma el letrero de alcance con ellas y no puede decir una lista distinta de la que dibuja`q'}"' _n
file write `fh' "}" _n
file close `fh'

*** 8 RESUMEN ***
quietly checksum `"`json'"'
local kbj = string(r(filelen)/1024, "%9.0fc")
noisily di _newline in g "{bf:FederacionNLQuintiles: listo.}"
noisily di in g "  JSON: " in y `"`json'"' in g " (`kbj' KB) · esquema nl.federacion-quintiles/v2 · capa `nl_vnl' (driver `nl_vdriver') · motor `nl_vmotor' · ENIGH `enigh' · años `anioref' / `aniope'"
foreach l in pagaAb pagaCe aparte recAb recCe inv {
	local D_`l' = subinstr(subinstr(`"`L_`l''"', char(34), "", .), ",", "", .)
}
local nSup : list sizeof L_supAnc
noisily di in g "  Paleta: `NP' flujos — paga abiertos [`D_pagaAb'] cerrados [`D_pagaCe'] · aparte [`D_aparte'] · recibe abiertos [`D_recAb'] cerrados [`D_recCe'] · inventario [`D_inv']"
noisily di in g "  Caja gris calculada: " in y %5.1f `grisPct_`anioref'' in g " % (`anioref') · " in y %5.1f `grisPct_`aniope'' in g " % (`aniope') del recibe. Anclas supuesto en página: " in y "`=cond(`"`L_supAnc'"' == "", "ninguna", `"`L_supAnc'"')'"
noisily di in g "  Sin HTML: la vista itera el contrato (nl-fedq-html.do inyecta este JSON tras FederacionNL.do)."
capture frame drop nlq_pal
quietly log close nlfq
