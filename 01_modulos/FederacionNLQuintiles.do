*! FederacionNLQuintiles.do  v0.1.0 (C1, sprint NL-0.6.0 "Ida y vuelta por quintil") — capa de datos del Sankey ida-y-vuelta por QUINTIL ESTATAL: lado paga abierto por quintil donde la muestra aguanta (ISR PM + ISR PF sin abrir, con banda S1–S3 y concTop1), lado recibe por quintil (FONE vía alumnos de básica pública; FASSA+PSS vía afiliación SSA; caja gris declarada) para el año de referencia (observado) y el año de política (Paquete). Contrato hermano: users/$id/nodos/federacion-nl-quintiles.json
*
* QUÉ ES ESTO (DIAGNOSTICO_NL.md, F0 Sankey por decil 2026-10-08 y decisiones cerradas de Ricardo):
*   D1 eje = quintiles ESTATALES (re-ranking dentro de la muestra NL con el criterio exacto de
*      Households.do:2591-2599: ingreso bruto total del hogar per cápita, xtile ponderado por
*      factor/integrantes, todas las personas del hogar heredan el quintil del hogar);
*   D2 capital SIN abrir: ISR PM e ISR PF van en nodo "sin abrir por quintil" con banda S1–S3 y
*      sello concTop1; ni enlace al quintil V ni exclusión: el total cierra;
*   D3 salud: clave = afiliación SSA (inst_6); divergencia con la clave del motor (benef_ssa =
*      gasto privado en salud) DECLARADA, el motor no se toca;
*   D4 quintiles en ambos extremos; D5 solo anio_referencia (observado) y anio_politica (Paquete).
*   Regla n≥100 por celda quintil×flujo abierta: las celdas que no la cumplen NO se abren por
*   defecto (IEPS petrolero e ISAN: Q3–Q4) y viajan como alternativa declarada; FONE Q5 (<100
*   alumnos) se exporta abierto con cumpleN = false y una alternativa Q4–Q5 colapsada (FLAG).
*
* ENTRADAS (solo lectura; CERO descargas; el motor no se modifica):
*   users/$id/aportaciones.dta                (objeto del pipeline, corte entidad 19)
*   users/$id/nodos/statajson_entidad-nl.json (compuertas Q.1–Q.3 y vintage ENIGH)
*   users/$id/nodos/federacion-nl.json        (montos por año: paga por impuesto, recibe por fondo)
*   master/PEF.dta                            (PPEF/PEF del año de política por programa pp: FONE, FASSA)
* SALIDA: users/$id/nodos/federacion-nl-quintiles.json + federacion-nl-quintiles.log (gitignored).
*
* COMPUERTAS (abortan):
*   Q.0 muestra: n≥100 personas y hogares por quintil estatal.
*   Q.1 construcción: participación por DECIL estatal de AlTrabajo/AlCapital/AlConsumo/ImpAport/
*       IVA/IEPSNP/IEPSP/ISAN/IMPORT = dis<fam>nle<dec> del statajson (reldif 1e-6, 90 celdas).
*   Q.2 coherencia: Σ <X>_Sim×factor (NL) vs Rec<X>nl del statajson. Causa identificada (C1, q2-diag.log):
*       <X>_Sim = <X> × (<X>PIB/100 × pibY) / ILIF_<X> (TasasEfectivas.ado §7.1: reescalado nacional al parámetro
*       *PIB de SIM.do §4.1, declarado con 3 decimales de % del PIB), mientras Rec<X>nl suma <X> (perfiles = ILIF
*       en pesos). Cociente uniforme persona a persona (sd 0), misma muestra y factor: NO es bootstrap
*       (bootstrap(1), pesos originales) ni base. reldif = |<X>PIB·pibY/100 − ILIF|/ILIF; máximo ISAN 4.7e-3
*       (0.044 % vs 0.04421 %). Las participaciones por quintil son invariantes a ese factor. Tol 1e-2, declarado.
*   Q.3 concTop1<X> recalculado = statajson (1e-6).
*   Q.4 identidad: federacion-nl.json y statajson de la misma capa, motor y año de política.
*   Q.5 PEF.dta: Σ pp del ramo 33 (entidad 19, año de política) = anclaR33 del JSON (1e-9);
*       pp 13/15 son FONE y pp 2 es FASSA por su descripción.
*   Q.6 cierres contables: Σ quintiles + sin abrir = pagaS0 de la tarjeta; Σ cuotas por quintil =
*       cuotas; FONE + FASSA/PSS + caja gris = recibe de la tarjeta (ambos años, reldif 1e-6).
*
* USO: do "${SIMROOT}/01_modulos/FederacionNLQuintiles.do"   (tras FederacionNL.do en la misma máquina)
*   global fuentes "AAAA-MM-DD"    -> declara las fuentes congeladas del motor (procedencia)
*   global nlfuentes "AAAA-MM-DD"  -> declara las fuentes congeladas de la capa (procedencia)
* OJO: destruye los datos en memoria.

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
run `"`site'/01_modulos/nl-assets/nl-identidad.do"'
_NLidentidad, modulo("La Federación y Nuevo León — ida y vuelta por quintil")
local nl_producto `"`r(producto)'"'
local nl_titulo `"`r(titulo)'"'
local nl_subtitulo `"`r(subtitulo)'"'
local nl_vmotor `"`r(version_motor)'"'
local nl_vnl `"`r(version_nl)'"'
local nl_repo `"`r(repositorio)'"'
if "`nl_vnl'" == "" | "`nl_vmotor'" == "" {
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
	local s = subinstr(`"`s'"', char(10), " ", .)
	local s = subinstr(`"`s'"', char(13), "", .)
	local s = trim(`"`s'"')
	return local t `"`s'"'
end

local impuestos "ISRAS ISRPF ISRPM IVA IEPSNP IEPSP ISAN IMPORT"	// nodos del lado paga de la vista (federacion-nl.json alcance.incluye_paga)
local extras "CUOTAS"												// aparte, no sumadas (también por quintil)
local sinabrirD2 "ISRPM ISRPF"										// D2: capital sin abrir por decisión
local umbral = 100

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
_NLjsonget using `"`fedjson'"', keys(anio_referencia anio_politica procedencia.version_capa_nl procedencia.version_motor procedencia.generado_en procedencia.modo cifras.pagaS0NL cifras.recibeNL cifras.pagaPES0NL cifras.recibePENL cifras.cuotasIMSSNL cifras.cuotasPENL esquema)
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
if "`fed_vnl'" != "`nl_vnl'" | "`fed_vmotor'" != "`nl_vmotor'" {
	di as err "FederacionNLQuintiles: federacion-nl.json es de la capa `fed_vnl' / motor `fed_vmotor'; la sesión es `nl_vnl' / `nl_vmotor'. Re-corre FederacionNL.do. No se exporta."
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
if `ent_anio' != `aniope' | "`ent_vnl'" != "`nl_vnl'" | "`ent_vmotor'" != "`nl_vmotor'" | "`enigh'" == "" {
	di as err "FederacionNLQuintiles: statajson_entidad-nl.json es de PE `ent_anio' / capa `ent_vnl' / motor `ent_vmotor' (ENIGH '`enigh''); la sesión es `aniope' / `nl_vnl' / `nl_vmotor'. No se exporta."
	exit 459
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
noisily di in g "  Compuerta Q.4 (identidad: capa `nl_vnl', motor `nl_vmotor', PE `aniope', ENIGH `enigh'; federacion-nl.json modo `fed_modo' de `fed_gen'): " in y "PASÓ" in g "."
noisily di in g "  Año de referencia " in y "`anioref'" in g " (observado) · año de política " in y "`aniope'" in g " (Paquete) · tarjetas: paga " in y %10.1fc `tj_paga_ref'/1e6 in g " / " in y %10.1fc `tj_paga_pe'/1e6 in g " · recibe " in y %10.1fc `tj_rec_ref'/1e6 in g " / " in y %10.1fc `tj_rec_pe'/1e6 in g " mdp"

* Escalares del statajson: Rec<X>nl, dis<fam>nle<dec>, concTop1<X>nl *
quietly {
	_NLjsonesc using `"`entjson'"', prefijos(Rec dis concTop1)
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
	_NLjsonarr using `"`fedjson'"', array(anual) fields(anio tipoRecibe tipoPaga fuenteAncla nlR28 nlR33 nlCD nlCR nlR23 nlPSS nlTot anclaR28 anclaR33 anclaConv anclaSubs anclaSalud anclaTot recibePaq pagaISRAS pagaISRPF pagaISRPM pagaIVA pagaIEPSNP pagaIEPSP pagaISAN pagaIMPORT pagaCUOTAS pagaS0 pagaS1 pagaS3 pagaLifISRAS pagaLifISRPF pagaLifISRPM pagaLifIVA pagaLifIEPSNP pagaLifIEPSP pagaLifISAN pagaLifIMPORT pagaLifCUOTAS pagaLifS0 pagaLifS1 pagaLifS3 pobNL)
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
	keep if anio == `anioref' & grupo == "R33"
	tempfile SF
	save `SF'
	_NLjsonarr using `"`fedjson'"', array(definiciones.subfondos) fields(clave grupo nombre)
	forvalues i = 1/`=_N' {
		local nom`=clave[`i']' `"`=nombre[`i']'"'
	}
}
noisily di in g "  Montos del contrato vigente leídos: anual (`anioref', `aniope'), subfondos R33 `anioref' (" in y "`=_N'" in g " claves con nombre)."

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

* Pesos monetarios por persona (pesos del año de política) y claves en especie *
foreach k in `impuestos' `extras' {
	g double w_`k' = `k'_Sim*factor
	g byte p_`k' = `k'_Sim > 0 & `k'_Sim != .
	egen byte hp_`k' = max(p_`k'), by(folioviv foliohog)
	replace hp_`k' = hp_`k'*hog1
}
g double w_AlTrabajo = AlTrabajo*factor
g double w_AlConsumo = AlConsumo*factor
g double w_AlCapital = AlCapital*factor
g double w_ImpAport = ImpuestosAportaciones*factor
g byte p_FONE = alum_basica == 1							// alumno de educación básica pública (GastoPC.ado: asiste, pública, nivel 01–07, edad ≤ 15)
g byte p_SALUD = inst_6 == "6"								// afiliación a institución federal/estatal de salud (SSA / IMSS-Bienestar federal) — D3
g double w_FONE = p_FONE*factor
g double w_SALUD = p_SALUD*factor
foreach k in FONE SALUD {
	egen byte hp_`k' = max(p_`k'), by(folioviv foliohog)
	replace hp_`k' = hp_`k'*hog1
}
quietly {
	summarize w_FONE, meanonly
	local unidFONE = r(sum)										// alumnos de básica pública expandidos
	summarize w_SALUD, meanonly
	local unidSALUD = r(sum)									// afiliados SSA expandidos
}
tempfile BASE
quietly save `BASE'

*** 3 COMPUERTAS Q.1 (construcción = statajson por decil), Q.2 (totales = Rec<X>nl), Q.3 (concTop1) ***
noisily di _newline in g "{bf:3. Compuertas de construcción contra statajson_entidad-nl.json}"
quietly {
	collapse (sum) w_AlTrabajo w_AlConsumo w_AlCapital w_ImpAport w_IVA w_IEPSNP w_IEPSP w_ISAN w_IMPORT, by(decilE)
	foreach f in AlTrabajo AlConsumo AlCapital ImpAport IVA IEPSNP IEPSP ISAN IMPORT {
		egen double t = total(w_`f')
		g double sh_`f' = w_`f'/t*100
		drop t w_`f'
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
	quietly summarize w_`k', meanonly
	local tot`k' = r(sum)
	local c = cond(r(sum) != 0, r(max)/r(sum)*100, .)
	local conc`k' = `c'
	local rd = reldif(`tot`k'', `vRec`k'nl')
	local rdQ2 = max(`rdQ2', `rd')
	local q2txt "`q2txt'`k' `=string(`rd', "%8.1e")'; "
	if `rd' > 1e-2 {
		local ++nf
		noisily di as err "  `k': Σ `k'_Sim×factor = `tot`k'' vs Rec`k'nl = `vRec`k'nl'"
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

*** 4 CLAVES POR QUINTIL: participación, n, hogares, concTop1, cumpleN ***
noisily di _newline in g "{bf:4. Claves de reparto por quintil estatal (ENIGH `enigh', corrida PE `aniope')}"
local claves "`impuestos' `extras' FONE SALUD"
quietly {
	local cs ""
	local cm ""
	local cn ""
	local ch ""
	foreach k of local claves {
		local cs "`cs' s_`k'=w_`k'"
		local cm "`cm' m_`k'=w_`k'"
		local cn "`cn' n_`k'=p_`k'"
		local ch "`ch' h_`k'=hp_`k'"
	}
	collapse (sum) `cs' `cn' `ch' (max) `cm', by(quintilE)
	foreach k of local claves {
		egen double t = total(s_`k')
		g double sh_`k' = s_`k'/t
		g double c_`k' = cond(s_`k' != 0, m_`k'/s_`k'*100, .)
		drop t m_`k' s_`k'
	}
	rename quintilE q
	reshape long sh_ c_ n_ h_, i(q) j(k) string
	rename (sh_ c_ n_ h_) (share concTop1 n nHog)
	g byte cumpleN = n >= `umbral'
	sort k q
	tempfile CL
	save `CL'
	* Resumen por clave: celdas que fallan y nodo abierto por defecto *
	collapse (min) nMin = n cumpleTodas = cumpleN, by(k)
	g byte d2 = 0
	foreach x of local sinabrirD2 {
		replace d2 = 1 if k == "`x'"
	}
	g byte abierto = cumpleTodas & !d2
	replace abierto = 1 if k == "FONE"						// D4 + resolución 2026-10-08: cinco quintiles; Q5 viaja con cumpleN = false y sello visible n = 79 (no se colapsa)
	g razon = cond(d2, "D2: capital sin abrir por quintil (concTop1 alto; n por celda insuficiente)", ///
		cond(!cumpleTodas & k != "FONE", "n<" + string(`umbral') + " personas en al menos una celda: no se abre por defecto; alternativa declarada", ///
		cond(k == "FONE" & !cumpleTodas, "abierto en cinco quintiles (D4; resolución 2026-10-08): la celda Q5 tiene menos de " + string(`umbral') + " alumnos y lleva sello visible con su n (cumpleN = false); no se colapsa", "n≥" + string(`umbral') + " en las 5 celdas")))
	tempfile ND
	save `ND'
}
noisily di in g "  Clave" _col(10) %8s "mín n" _col(20) %8s "abierto" _col(30) "razón"
forvalues i = 1/`=_N' {
	noisily di in g "  `=k[`i']'" _col(10) in y %8.0fc nMin[`i'] _col(20) in y %8s cond(abierto[`i'], "sí", "no") _col(30) in g "`=razon[`i']'"
}
quietly use `CL', clear
noisily di _newline in g "  Participación por quintil (%) · n personas con la clave · concTop1 (%)"
noisily di in g "  Clave" _col(10) %12s "Q1" _col(24) %12s "Q2" _col(38) %12s "Q3" _col(52) %12s "Q4" _col(66) %12s "Q5"
foreach k of local claves {
	forvalues qq = 1/5 {
		quietly summarize share if k == "`k'" & q == `qq', meanonly
		local s`qq' = r(mean)*100
		quietly summarize n if k == "`k'" & q == `qq', meanonly
		local n`qq' = r(mean)
		quietly summarize concTop1 if k == "`k'" & q == `qq', meanonly
		local c`qq' = r(mean)
	}
	noisily di in g "  `k'" _col(10) in y %12.2f `s1' _col(24) %12.2f `s2' _col(38) %12.2f `s3' _col(52) %12.2f `s4' _col(66) %12.2f `s5'
	noisily di in g "    n" _col(10) in y %12.0f `n1' _col(24) %12.0f `n2' _col(38) %12.0f `n3' _col(52) %12.0f `n4' _col(66) %12.0f `n5'
	noisily di in g "    top-1" _col(10) in y %12.1f `c1' _col(24) %12.1f `c2' _col(38) %12.1f `c3' _col(52) %12.1f `c4' _col(66) %12.1f `c5'
}
noisily di in g "  Unidades expandidas: alumnos de básica pública " in y %12.0fc `unidFONE' in g " · afiliados SSA (inst_6) " in y %12.0fc `unidSALUD' in g "."

*** 5 MONTOS POR AÑO: PAGA (contrato vigente) Y RECIBE (EOFP vía contrato; PPEF vía PEF.dta por pp) ***
noisily di _newline in g "{bf:5. Montos por año y fondo}"
* 5.1 PEF.dta: ramo 33 por programa presupuestario, entidad 19, año de política (y CP del año de referencia, informativo) *
noisily di in g "  Leyendo master/PEF.dta (ramo 33 por pp, entidad 19)..."
quietly {
	use anio ramo pp desc_pp entidad divFEDE gasto if entidad == 19 & inlist(anio, `anioref', `aniope') & divFEDE == "Aportaciones" & ramo == 33 using `"`pef'"', clear
	collapse (sum) gasto, by(anio pp desc_pp)
	g lpp = lower(desc_pp)
	g fondoQ = cond(inlist(pp, 13, 15), "FONE", cond(pp == 2, "FASSA", "RESTO"))
	count if fondoQ == "FONE" & strpos(lpp, "fone") == 0
	local nf = r(N)
	count if fondoQ == "FASSA" & strpos(lpp, "fassa") == 0
	local nf = `nf' + r(N)
	count if fondoQ == "RESTO" & (strpos(lpp, "fone") > 0 | strpos(lpp, "fassa") > 0)
	local nf = `nf' + r(N)
	tempfile PP
	save `PP'
	foreach t in `anioref' `aniope' {
		summarize gasto if anio == `t' & fondoQ == "FONE", meanonly
		local pefFONE_`t' = cond(r(N) > 0, r(sum), .)
		summarize gasto if anio == `t' & fondoQ == "FASSA", meanonly
		local pefFASSA_`t' = cond(r(N) > 0, r(sum), .)
		summarize gasto if anio == `t', meanonly
		local pefR33_`t' = cond(r(N) > 0, r(sum), .)
	}
}
if `nf' > 0 {
	noisily list anio pp desc_pp gasto fondoQ, noobs clean
	di as err "FederacionNLQuintiles: los programas pp 13/15 (FONE) y pp 2 (FASSA) del ramo 33 no corresponden a su descripción en PEF.dta. No se exporta."
	exit 459
}
quietly {
	use `AN', clear
	summarize anclaR33 if anio == `aniope', meanonly
	local anclaR33pe = r(mean)
}
if reldif(`pefR33_`aniope'', `anclaR33pe') > 1e-9 {
	di as err "FederacionNLQuintiles: Σ pp del ramo 33 en PEF.dta (`pefR33_`aniope'') ≠ anclaR33 `aniope' del contrato (`anclaR33pe'). No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.5 (PEF.dta ramo 33 `aniope' por pp = anclaR33 del contrato; pp 13/15 = FONE, pp 2 = FASSA): " in y "PASÓ" in g " (FONE " in y %10.1fc `pefFONE_`aniope''/1e6 in g " · FASSA " in y %8.1fc `pefFASSA_`aniope''/1e6 in g " mdp)."

* 5.2 Montos por año: locals pg<X>_<t>, tot_<t>, S1/S3, cuotas; recibe_<t>, FONE_<t>, FASSA_<t>, PSS_<t> *
quietly use `AN', clear
foreach t in `anioref' `aniope' {
	local pre = cond(`t' == `anioref', "paga", "pagaLif")
	foreach k in `impuestos' `extras' S0 S1 S3 {
		quietly summarize `pre'`k' if anio == `t', meanonly
		local pg`k'_`t' = r(mean)
	}
	quietly levelsof tipoPaga if anio == `t', clean
	local tipoPaga_`t' = cond(`t' == `anioref', "`r(levels)'", "Paquete")
	quietly levelsof fuenteAncla if anio == `t', clean
	local fuenteAncla_`t' "`r(levels)'"
	if `t' == `anioref' {
		foreach v in nlTot nlR28 nlR33 nlCD nlCR nlR23 nlPSS {
			quietly summarize `v' if anio == `t', meanonly
			local `v'_`t' = r(mean)
		}
		local recibe_`t' = `nlTot_`t''
		local fuenteRecibe_`t' "EOFP"
		local tipoRecibe_`t' "observado"
		quietly {
			use `SF', clear
			summarize nl if clave == "XAC33A", meanonly
			local FONE_`t' = r(mean)
			summarize nl if clave == "XAC33B", meanonly
			local FASSA_`t' = r(mean)
			use `AN', clear
		}
		local PSS_`t' = `nlPSS_`t''
		local pssFlag_`t' = 0
	}
	else {
		foreach v in anclaR28 anclaR33 anclaConv anclaSubs anclaSalud anclaTot recibePaq {
			quietly summarize `v' if anio == `t', meanonly
			local `v'_`t' = cond(r(N) > 0, r(mean), .)
		}
		local recibe_`t' = `recibePaq_`t''
		local fuenteRecibe_`t' "`fuenteAncla_`t''"
		local tipoRecibe_`t' "Paquete"
		local FONE_`t' = `pefFONE_`t''
		local FASSA_`t' = `pefFASSA_`t''
		* PSS (R47 salud federalizado) no viene por entidad en el PPEF: el nodo salud del Paquete es solo FASSA (FLAG) *
		local PSS_`t' = cond(`anclaSalud_`t'' == ., 0, `anclaSalud_`t'')
		local pssFlag_`t' = (`anclaSalud_`t'' == .)
	}
	local SALUD_`t' = `FASSA_`t'' + `PSS_`t''
	local gris_`t' = `recibe_`t'' - `FONE_`t'' - `SALUD_`t''
	local grisPct_`t' = `gris_`t''/`recibe_`t''*100
	local costoFONE_`t' = `FONE_`t''/`unidFONE'
	local costoSALUD_`t' = `SALUD_`t''/`unidSALUD'
	* Banda del ISR PM (sustituye solo ese componente) *
	local pgISRPMS1_`t' = `pgS1_`t'' - `pgS0_`t'' + `pgISRPM_`t''
	local pgISRPMS3_`t' = `pgS3_`t'' - `pgS0_`t'' + `pgISRPM_`t''
	noisily di in g "  `t' (`tipoPaga_`t'' / `tipoRecibe_`t''): paga S0 " in y %10.1fc `pgS0_`t''/1e6 in g " [" %8.1fc `pgS1_`t''/1e6 ", " %8.1fc `pgS3_`t''/1e6 "]" in g " · cuotas " in y %8.1fc `pgCUOTAS_`t''/1e6 in g " · recibe " in y %8.1fc `recibe_`t''/1e6 in g " = FONE " in y %7.1fc `FONE_`t''/1e6 in g " + FASSA " in y %6.1fc `FASSA_`t''/1e6 in g " + PSS " in y %6.1fc `PSS_`t''/1e6 in g " + caja gris " in y %7.1fc `gris_`t''/1e6 in g " (" in y %5.1f `grisPct_`t'' in g " %) mdp"
}
* Informativo: FONE del CP `anioref' (PEF.dta pp 13+15) vs FAEB EOFP (XAC33A) *
local rdFONEcp = cond(`pefFONE_`anioref'' != ., reldif(`pefFONE_`anioref'', `FONE_`anioref''), .)
local rdFASSAcp = cond(`pefFASSA_`anioref'' != ., reldif(`pefFASSA_`anioref'', `FASSA_`anioref''), .)
noisily di in g "  Informativo: Cuenta Pública `anioref' (PEF.dta) vs EOFP — FONE pp 13+15 vs FAEB XAC33A reldif " in y %9.2e `rdFONEcp' in g " · FASSA pp 2 vs XAC33B reldif " in y %9.2e `rdFASSAcp' in g "."

* 5.3 Componentes de la caja gris por año *
quietly {
	clear
	set obs 0
	g int anio = .
	g clave = ""
	g lab = ""
	g double v = .
	tempfile GR
	save `GR'
	* anioref: R28, CD, CR, R23 (agregados EOFP) + subfondos R33 distintos de FAEB/FASSA (claves totales: C F J K L O) + residuo R33 *
	use `AN', clear
	keep if anio == `anioref'
	keep anio nlR28 nlCD nlCR nlR23 nlR33
	rename (nlR28 nlCD nlCR nlR23) (vR28 vCD vCR vR23)
	g double vR33resto = nlR33
	reshape long v, i(anio) j(clave) string
	g lab = cond(clave == "R28", "Participaciones (R28)", cond(clave == "CD", "Convenios de descentralización", cond(clave == "CR", "Convenios de reasignación", cond(clave == "R23", "Gasto federalizado del R23", "Ramo 33 no desglosado (residuo XAC33 − Σ subfondos)"))))
	keep anio clave lab v
	tempfile G1
	save `G1'
	use `SF', clear
	keep if inlist(clave, "XAC33C", "XAC33F", "XAC33J", "XAC33K", "XAC33L", "XAC33O")
	rename nl v
	g lab = ""
	forvalues i = 1/`=_N' {
		replace lab = `"`nom`=clave[`i']''"' in `i'
	}
	keep anio clave lab v
	append using `G1'
	* residuo R33 = XAC33 − (A + B + C + F + J + K + L + O) *
	summarize v if inlist(clave, "XAC33C", "XAC33F", "XAC33J", "XAC33K", "XAC33L", "XAC33O"), meanonly
	replace v = v - r(sum) - `FONE_`anioref'' - `FASSA_`anioref'' if clave == "R33resto"
	drop if clave == "R33resto" & abs(v) < 0.5
	save `G1', replace
	* aniope: anclas PPEF (R28, convenios, subsidios) + pp del ramo 33 distintos de FONE/FASSA *
	use `PP', clear
	keep if anio == `aniope' & fondoQ == "RESTO"
	g clave = "pp" + string(pp)
	rename (gasto desc_pp) (v lab)
	keep anio clave lab v
	tempfile G2
	save `G2'
	use `AN', clear
	keep if anio == `aniope'
	keep anio anclaR28 anclaConv anclaSubs
	rename (anclaR28 anclaConv anclaSubs) (vR28 vConv vSubs)
	reshape long v, i(anio) j(clave) string
	g lab = cond(clave == "R28", "Participaciones (R28, `fuenteAncla_`aniope'')", cond(clave == "Conv", "Convenios (`fuenteAncla_`aniope'')", "Subsidios R23 (`fuenteAncla_`aniope'')"))
	drop if v == . | v == 0
	append using `G2'
	append using `G1'
	sort anio clave
	save `GR', replace
	* Cierre de la caja gris por componentes *
	foreach t in `anioref' `aniope' {
		summarize v if anio == `t', meanonly
		local grisComp_`t' = r(sum)
	}
}
foreach t in `anioref' `aniope' {
	if reldif(`grisComp_`t'', `gris_`t'') > 1e-6 {
		noisily list if anio == `t', noobs clean
		di as err "FederacionNLQuintiles: los componentes de la caja gris `t' (`grisComp_`t'') no suman la caja gris (`gris_`t''). No se exporta."
		exit 459
	}
}
noisily di in g "  Caja gris por componentes = recibe − FONE − FASSA − PSS en ambos años: " in y "OK" in g "."

*** 6 FLUJOS QUINTIL→NODO→QUINTIL, ALTERNATIVAS Y CIERRES (compuerta Q.6) ***
noisily di _newline in g "{bf:6. Flujos por quintil y cierres contables}"
quietly {
	use `CL', clear
	merge m:1 k using `ND', nogen keepusing(abierto)
	expand 2, g(dup)
	g int anio = cond(dup == 0, `anioref', `aniope')
	drop dup
	g lado = cond(inlist(k, "FONE", "SALUD"), "recibe", cond(k == "CUOTAS", "aparte", "paga"))
	g double total = .
	g double totalS1 = .
	g double totalS3 = .
	foreach t in `anioref' `aniope' {
		foreach x in `impuestos' `extras' {
			replace total = `pg`x'_`t'' if anio == `t' & k == "`x'"
		}
		replace totalS1 = `pgISRPMS1_`t'' if anio == `t' & k == "ISRPM"
		replace totalS3 = `pgISRPMS3_`t'' if anio == `t' & k == "ISRPM"
		replace total = `FONE_`t'' if anio == `t' & k == "FONE"
		replace total = `SALUD_`t'' if anio == `t' & k == "SALUD"
	}
	g double v = total*share
	* default = nodo abierto; alternativa = cerrado por n (vehicular: IEPS P/ISAN), elegible; informativa = cerrado por D2 (capital), NO elegible *
	g variante = cond(abierto, "default", cond(inlist(k, "ISRPM", "ISRPF"), "informativa", "alternativa"))
	sort anio lado k variante q
	tempfile FL
	save `FL'
}
* Cierres *
local nf = 0
foreach t in `anioref' `aniope' {
	quietly {
		use `FL', clear
		keep if anio == `t' & variante == "default"
		summarize v if lado == "paga", meanonly
		local sumAb_`t' = r(sum)
		local sumNA_`t' = 0
		foreach x of local impuestos {
			summarize v if lado == "paga" & k == "`x'", meanonly
			if r(N) == 0 local sumNA_`t' = `sumNA_`t'' + `pg`x'_`t''
		}
		local sumPaga_`t' = `sumAb_`t'' + `sumNA_`t''
		local tj = cond(`t' == `anioref', `tj_paga_ref', `tj_paga_pe')
		local rdPaga_`t' = reldif(`sumPaga_`t'', `tj')
		local tjPaga_`t' = `tj'
		summarize v if lado == "aparte", meanonly
		local sumCuo_`t' = r(sum)
		local tj = cond(`t' == `anioref', `tj_cuo_ref', `tj_cuo_pe')
		local rdCuo_`t' = reldif(`sumCuo_`t'', `tj')
		local tjCuo_`t' = `tj'
		summarize v if lado == "recibe", meanonly
		local sumRec_`t' = r(sum) + `gris_`t''
		local tj = cond(`t' == `anioref', `tj_rec_ref', `tj_rec_pe')
		local rdRec_`t' = reldif(`sumRec_`t'', `tj')
		local tjRec_`t' = `tj'
	}
	foreach c in Paga Cuo Rec {
		if `rd`c'_`t'' > 1e-6 local ++nf
	}
	noisily di in g "  `t' paga: Σ quintiles abiertos " in y %12.1fc `sumAb_`t''/1e6 in g " + sin abrir " in y %10.1fc `sumNA_`t''/1e6 in g " = " in y %12.1fc `sumPaga_`t''/1e6 in g " vs tarjeta " in y %12.1fc `tjPaga_`t''/1e6 in g " mdp · reldif " in y %9.2e `rdPaga_`t''
	noisily di in g "  `t' cuotas IMSS (aparte): Σ quintiles " in y %12.1fc `sumCuo_`t''/1e6 in g " vs tarjeta " in y %12.1fc `tjCuo_`t''/1e6 in g " · reldif " in y %9.2e `rdCuo_`t''
	noisily di in g "  `t' recibe: FONE + FASSA/PSS por quintil + caja gris " in y %12.1fc `sumRec_`t''/1e6 in g " vs tarjeta " in y %12.1fc `tjRec_`t''/1e6 in g " · reldif " in y %9.2e `rdRec_`t''
}
if `nf' > 0 {
	di as err "FederacionNLQuintiles: `nf' cierres contables fallan (reldif > 1e-6). No se exporta."
	exit 459
}
noisily di in g "  Compuerta Q.6 (cierres contables, ambos años, 1e-6): " in y "PASÓ" in g "."

* Tablas quintil × flujo (mdp) para el reporte *
foreach t in `anioref' `aniope' {
	noisily di _newline in g "{bf:  `t' — lado paga por quintil estatal (mdp; `tipoPaga_`t'')}"
	noisily di in g "  Flujo" _col(12) %10s "Q1" _col(24) %10s "Q2" _col(36) %10s "Q3" _col(48) %10s "Q4" _col(60) %10s "Q5" _col(72) %10s "Total"
	foreach x in `impuestos' `extras' {
		quietly use `FL', clear
		quietly keep if anio == `t' & k == "`x'" & inlist(variante, "default", "alternativa", "informativa")
		local l "  `x'"
		if "`=variante[1]'" != "default" local l "  `x'*"
		forvalues qq = 1/5 {
			quietly summarize v if q == `qq', meanonly
			local f`qq' = r(mean)/1e6
		}
		noisily di in g "`l'" _col(12) in y %10.1fc `f1' _col(24) %10.1fc `f2' _col(36) %10.1fc `f3' _col(48) %10.1fc `f4' _col(60) %10.1fc `f5' _col(72) %10.1fc `pg`x'_`t''/1e6
	}
	noisily di in g "  (* = sin abrir: ISR PM/ISR PF por D2, reparto solo informativo; IEPS P/ISAN por n<`umbral', reparto como alternativa elegible) · banda ISR PM [S1, S3] = [" in y %8.1fc `pgISRPMS1_`t''/1e6 ", " %8.1fc `pgISRPMS3_`t''/1e6 in g "] mdp"
	noisily di _newline in g "{bf:  `t' — lado recibe por quintil estatal (mdp; `tipoRecibe_`t'', `fuenteRecibe_`t'')}"
	noisily di in g "  Flujo" _col(12) %10s "Q1" _col(24) %10s "Q2" _col(36) %10s "Q3" _col(48) %10s "Q4" _col(60) %10s "Q5" _col(72) %10s "Total"
	foreach x in FONE SALUD {
		quietly use `FL', clear
		quietly keep if anio == `t' & k == "`x'" & variante == "default"
		local l "  `x'"
		forvalues qq = 1/5 {
			quietly summarize v if q == `qq', meanonly
			local f`qq' = r(mean)/1e6
		}
		noisily di in g "`l'" _col(12) in y %10.1fc `f1' _col(24) %10.1fc `f2' _col(36) %10.1fc `f3' _col(48) %10.1fc `f4' _col(60) %10.1fc `f5' _col(72) %10.1fc cond("`x'" == "FONE", `FONE_`t'', `SALUD_`t'')/1e6
	}
	noisily di in g "  Caja gris (sin etiqueta de persona)" _col(72) in y %10.1fc `gris_`t''/1e6 in g "  = " in y %5.1f `grisPct_`t'' in g " % del recibe"
	noisily di in g "  Costo de provisión: FONE " in y %8.0fc `costoFONE_`t'' in g " MXN por alumno de básica pública · FASSA+PSS " in y %8.0fc `costoSALUD_`t'' in g " MXN por afiliado SSA (aportación = proxy parcial)"
}

*** 7 EXPORTACIÓN JSON (contrato hermano nl.federacion-quintiles/v1) ***
noisily di _newline in g "{bf:7. Exportación}"
local json `"`site'/users/$id/nodos/federacion-nl-quintiles.json"'
local sellocorrida = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
tempname fh
capture erase `"`json'"'
file open `fh' using `"`json'"', write text replace
file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'nl.federacion-quintiles/v1`q',"' _n
file write `fh' `"  `q'contrato_base`q': {`q'esquema`q': `q'`fed_esq'`q', `q'archivo`q': `q'federacion-nl.json`q', `q'sha256`q': `q'`fed_sha'`q', `q'generado_en`q': `q'`fed_gen'`q', `q'modo`q': `q'`fed_modo'`q'},"' _n
file write `fh' `"  `q'producto`q': `q'`nl_producto'`q',"' _n
file write `fh' `"  `q'titulo`q': `q'`nl_titulo'`q',"' _n
file write `fh' `"  `q'subtitulo`q': `q'`nl_subtitulo'`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
file write `fh' `"  `q'anio_politica`q': `aniope',"' _n
file write `fh' `"  `q'eje`q': {`q'tipo`q': `q'quintil`q', `q'ambito`q': `q'estatal`q', `q'etiquetas`q': [`q'Q1`q', `q'Q2`q', `q'Q3`q', `q'Q4`q', `q'Q5`q'], `q'ingreso`q': `q'ingreso bruto total del hogar (ingbrutotot post-ajuste a Cuentas Nacionales) dividido entre los integrantes del hogar (ing_decil_pc del motor, Households.do:2591-2596)`q', `q'unidad`q': `q'persona: todas las personas del hogar heredan el quintil del hogar`q', `q'ponderacion`q': `q'xtile n(5) con pw = factor/integrantes (peso de hogar), re-rankeado dentro de la muestra NL (entidad 19); idéntico a ceil(decil estatal/2) y a la familia nle de EntidadNL.do`q', `q'comparacion_nacional`q': `q'D1: los deciles/quintiles nacionales (familia nl) quedan como nota, no como eje`q', `q'umbral_n`q': `umbral', `q'enigh`q': `enigh'},"' _n
file write `fh' `"  `q'procedencia`q': {"' _n
file write `fh' `"    `q'version_motor`q': `q'`nl_vmotor'`q', `q'version_capa_nl`q': `q'`nl_vnl'`q', `q'repositorio`q': `q'`nl_repo'`q',"' _n
file write `fh' `"    `q'driver`q': `q'01_modulos/FederacionNLQuintiles.do v0.1.0`q', `q'log`q': `q'`logfile'`q', `q'generado_en`q': `q'`sellocorrida'`q',"' _n
file write `fh' `"    `q'fuentes_congeladas_motor`q': `q'$fuentes`q', `q'fuentes_congeladas_capa`q': `q'$nlfuentes`q',"' _n
file write `fh' `"    `q'frontera`q': `q'producto de la capa NL sobre el canal del motor y el contrato federacion-nl.json: reparte por quintil estatal los montos ya publicados; ningún monto nuevo se calcula fuera del canal; el motor no se modifica`q',"' _n
file write `fh' `"    `q'fuentes`q': ["' _n
file write `fh' `"      {`q'id`q': `q'aportaciones`q', `q'fuente`q': `q'users/$id/aportaciones.dta (objeto del pipeline SIM.do §7, corte entidad 19): <X>_Sim, alum_basica, inst_6, factor, ingbrutotot`q', `q'mtime`q': `q'`aport_mtime'`q', `q'sha256`q': `q'`aport_sha'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'entidad_nl`q', `q'fuente`q': `q'statajson_entidad-nl.json (EntidadNL.do): compuertas Q.1–Q.3 (dis<fam>nle<dec>, Rec<X>nl, concTop1<X>nl)`q', `q'generado_en`q': `q'`ent_gen'`q', `q'sha256`q': `q'`ent_sha'`q', `q'enigh`q': `enigh'},"' _n
file write `fh' `"      {`q'id`q': `q'federacion_nl`q', `q'fuente`q': `q'federacion-nl.json (FederacionNL.do): paga por impuesto y año (observado / ILIF), recibe por fondo (EOFP) y anclas del Paquete (PEF.dta divFEDE)`q', `q'generado_en`q': `q'`fed_gen'`q', `q'sha256`q': `q'`fed_sha'`q', `q'modo`q': `q'`fed_modo'`q'},"' _n
file write `fh' `"      {`q'id`q': `q'pef_dta`q', `q'fuente`q': `q'master/PEF.dta del motor: ramo 33 por programa presupuestario (pp 13 y 15 = FONE, pp 2 = FASSA), entidad 19, `fuenteAncla_`aniope'' `aniope' y CP `anioref'`q', `q'mtime`q': `q'`pef_mtime'`q'}"' _n
file write `fh' "    ]," _n
file write `fh' `"    `q'compuertas`q': {"' _n
file write `fh' `"      `q'Q0_muestra`q': `q'n≥`umbral' personas y hogares por quintil estatal: mín `nPersMin' personas, `nHogMin' hogares`q',"' _n
file write `fh' `"      `q'Q1_construccion`q': `q'participación por decil estatal de AlTrabajo/AlCapital/AlConsumo/ImpAport/IVA/IEPSNP/IEPSP/ISAN/IMPORT = dis<fam>nle<dec> del statajson en `nQ1' celdas, reldif máx `=string(`rdQ1', "%9.2e")' (tol 1e-6)`q',"' _n
file write `fh' `"      `q'Q2_coherencia`q': `q'Σ <X>_Sim×factor en NL (aportaciones.dta) vs Rec<X>nl del statajson (Σ <X> de perfiles = ILIF en pesos): <X>_Sim = <X> × (<X>PIB/100 × pibY)/ILIF (TasasEfectivas.ado §7.1), cociente uniforme por persona, misma muestra y factor; causa = redondeo del parámetro *PIB de SIM.do §4.1 a 3 decimales de % del PIB (ISAN 0.044 % vs ILIF 0.04421 %); las participaciones por quintil son invariantes. reldif máx `=string(`rdQ2', "%9.2e")' (tol 1e-2): `q2txt'`q',"' _n
file write `fh' `"      `q'Q3_concTop1`q': `q'concTop1<X> recalculado = statajson, reldif máx `=string(`rdQ3', "%9.2e")' (tol 1e-6)`q',"' _n
file write `fh' `"      `q'Q4_identidad`q': `q'federacion-nl.json y statajson de la capa `nl_vnl', motor `nl_vmotor', PE `aniope', ENIGH `enigh'`q',"' _n
file write `fh' `"      `q'Q5_pef_pp`q': `q'Σ pp ramo 33 entidad 19 `aniope' = anclaR33 del contrato (1e-9); pp 13/15 FONE y pp 2 FASSA verificados por descripción; informativo CP `anioref': FONE pp13+15 vs FAEB EOFP reldif `=string(`rdFONEcp', "%9.2e")', FASSA pp2 vs XAC33B reldif `=string(`rdFASSAcp', "%9.2e")'`q',"' _n
file write `fh' `"      `q'Q6_cierres`q': `q'`anioref': paga reldif `=string(`rdPaga_`anioref'', "%9.2e")', cuotas `=string(`rdCuo_`anioref'', "%9.2e")', recibe `=string(`rdRec_`anioref'', "%9.2e")'; `aniope': paga `=string(`rdPaga_`aniope'', "%9.2e")', cuotas `=string(`rdCuo_`aniope'', "%9.2e")', recibe `=string(`rdRec_`aniope'', "%9.2e")' (tol 1e-6; tarjetas = cifras.pagaS0NL/recibeNL/cuotasIMSSNL y pagaPES0NL/recibePENL/cuotasPENL)`q'"' _n
file write `fh' "    }," _n
file write `fh' `"    `q'supuestos`q': {"' _n
file write `fh' `"      `q'claves_un_vintage`q': `q'las participaciones por quintil salen de la corrida vigente (ENIGH `enigh', PE `aniope', aportaciones.dta) y se aplican a los montos de ambos años; para `anioref' el monto ya lleva Part<X>nl del vintage asignado por federacion-nl.json`q',"' _n
file write `fh' `"      `q'paga_reparto`q': `q'flujo quintil→impuesto = paga del impuesto (contrato vigente) × participación del quintil en Σ <X>_Sim×factor de NL (misma rutina de distribución que INCI/dis<fam>: hogar→quintil→suma); ISR PM e ISR PF no se abren (D2) y viajan como nodo sin abrir con banda [S1, S3] y concTop1; IEPS petrolero e ISAN no se abren por defecto (n<`umbral' en Q3–Q4) y viajan como alternativa`q',"' _n
file write `fh' `"      `q'recibe_fone`q': `q'incidencia en especie a costo de provisión: FONE (FAEB XAC33A en EOFP; pp 13+15 del ramo 33 en el Paquete) repartido por alumnos de educación básica pública expandidos (alum_basica de GastoPC.ado); costo por alumno = FONE / alumnos; la aportación es proxy parcial del costo (el estado añade nómina y gasto propio)`q',"' _n
file write `fh' `"      `q'recibe_salud`q': `q'FASSA (XAC33B; pp 2 en el Paquete) + PSS (XACPSS) repartidos por afiliación a institución federal/estatal de salud (inst_6, D3); DIVERGENCIA DECLARADA: la clave del motor para Salud (benef_ssa) reparte por gasto privado en salud del hogar, no por afiliación; el motor no se toca (issue aparte)`q',"' _n
file write `fh' `"      `q'caja_gris`q': `q'participaciones R28, FAIS, FORTAMUN, FAFEF, FASP, FAETA, FAM, convenios, R23 y todo lo sin clave de incidencia: UN nodo con su % del recibe calculado; sin etiqueta de persona — el estado decide su destino; fase 2 CONAC/EFIPEM`q',"' _n
file write `fh' `"      `q'pss_paquete`q': `q'`=cond(`pssFlag_`aniope'', "el PPEF `aniope' no trae PSS (R47 salud federalizado) por entidad: el nodo salud del Paquete es solo FASSA. NOTA DE COMPOSICIÓN obligatoria en el alcance (resolución 2026-10-08): salud `anioref' (FASSA + PSS) y `aniope' (solo FASSA) no son comparables entre años", "el Paquete trae salud federalizado por entidad")'`q',"' _n
file write `fh' `"      `q'fone_q5`q': `q'resolución 2026-10-08: FONE en cinco quintiles; la celda Q5 (n < `umbral' alumnos) se dibuja con sello visible de su n (cumpleN = false); no se colapsa`q',"' _n
file write `fh' `"      `q'reglas_vista`q': `q'(1) NO existirá una neta por quintil: el saldo se muestra solo agregado como aportación neta en flujos identificables, los quintiles no se netean; (2) IEPS gasolinas + ISAN quedan sin abrir por defecto (la variante alternativa viaja en el JSON sin dibujarse); (3) la celda FONE Q5 lleva sello n visible; (4) unidades: los montos están en pesos, la vista los presenta en mdp (÷1e6) o mdp (÷1e9), nunca etiqueta ÷1e6 como mdp`q',"' _n
file write `fh' `"      `q'anios`q': `q'D5: solo anio_referencia (observado, EOFP y recaudación a diciembre) y anio_politica (Paquete: PPEF por pp e ILIF); la serie histórica sigue agregada en federacion-nl.json`q',"' _n
file write `fh' `"      `q'unidades`q': `q'todos los montos (v, total, paga*, recibe, FONE, FASSA, PSS, SALUD, gris, tj*, sum*) en pesos corrientes; costoFONE/costoSALUD en pesos por unidad; share en fracción 0–1; concTop1 y grisPct en %`q'"' _n
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

* 7.2 nodos *
quietly {
	use `ND', clear
	g lado = cond(inlist(k, "FONE", "SALUD"), "recibe", cond(k == "CUOTAS", "aparte", "paga"))
	g lab = ""
	replace lab = "ISR a asalariados" if k == "ISRAS"
	replace lab = "ISR de personas físicas" if k == "ISRPF"
	replace lab = "ISR de personas morales" if k == "ISRPM"
	replace lab = "IVA" if k == "IVA"
	replace lab = "IEPS no petrolero" if k == "IEPSNP"
	replace lab = "IEPS petrolero (gasolinas)" if k == "IEPSP"
	replace lab = "ISAN" if k == "ISAN"
	replace lab = "impuestos a la importación" if k == "IMPORT"
	replace lab = "cuotas IMSS (aparte, no sumadas)" if k == "CUOTAS"
	replace lab = "FONE: educación básica (alumnos de escuela pública)" if k == "FONE"
	replace lab = "FASSA + PSS: salud (afiliación SSA)" if k == "SALUD"
	g fondos = cond(k == "FONE", "XAC33A | pp 13+15", cond(k == "SALUD", "XAC33B + XACPSS | pp 2", ""))
	g grupoSinAbrir = cond(inlist(k, "ISRPM", "ISRPF"), "capital", cond(inlist(k, "IEPSP", "ISAN") & !abierto, "vehicular", ""))
	sort lado k
	save `ND', replace
}
file write `fh' `"  `q'nodos`q': ["' _n
forvalues i = 1/`=_N' {
	_nlqtxt `"`=razon[`i']'"'
	file write `fh' `"    {`q'lado`q': `q'`=lado[`i']'`q', `q'k`q': `q'`=k[`i']'`q', `q'lab`q': `q'`=lab[`i']'`q', `q'abierto`q': `=cond(abierto[`i'], "true", "false")', `q'nMin`q': `=nMin[`i']', `q'grupoSinAbrir`q': `q'`=grupoSinAbrir[`i']'`q', `q'fondos`q': `q'`=fondos[`i']'`q', `q'razon`q': `q'`r(t)'`q'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "  ]," _n
file write `fh' `"    `q'gris`q': {`q'k`q': `q'GRIS`q', `q'lado`q': `q'recibe`q', `q'lab`q': `q'sin etiqueta de persona — el estado decide su destino; fase 2 CONAC/EFIPEM`q', `q'abierto`q': false},"' _n

* 7.3 claves (participaciones por quintil, independientes del año) *
quietly use `CL', clear
file write `fh' `"  `q'claves`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'k`q': `q'`=k[`i']'`q', `q'q`q': `=q[`i']'"'
	foreach v in share n nHog concTop1 {
		_nlqnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' `", `q'cumpleN`q': `=cond(cumpleN[`i'], "true", "false")'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "  ]," _n
file write `fh' `"  `q'unidades`q': {`q'alumnosBasicaPublica`q': `=string(`unidFONE', "%25.17g")', `q'afiliadosSSA`q': `=string(`unidSALUD', "%25.17g")', `q'poblacionENIGH`q': `=string(`pobNL_enigh', "%25.17g")', `q'nota`q': `q'personas expandidas (factor) de la muestra NL de la ENIGH `enigh'; los per cápita del contrato base usan CONAPO, no esta población`q'},"' _n

* 7.4 anual *
file write `fh' `"  `q'anual`q': ["' _n
local j = 0
foreach t in `anioref' `aniope' {
	local ++j
	file write `fh' `"    {`q'anio`q': `t', `q'tipoPaga`q': `q'`tipoPaga_`t''`q', `q'tipoRecibe`q': `q'`tipoRecibe_`t''`q', `q'fuenteRecibe`q': `q'`fuenteRecibe_`t''`q'"'
	foreach x in `impuestos' `extras' {
		_nlqnum "`pg`x'_`t''"
		file write `fh' `", `q'paga`x'`q': `r(n)'"'
	}
	foreach s in S0 S1 S3 ISRPMS1 ISRPMS3 {
		_nlqnum "`pg`s'_`t''"
		file write `fh' `", `q'paga`s'`q': `r(n)'"'
	}
	foreach v in recibe FONE FASSA PSS SALUD gris grisPct costoFONE costoSALUD tjPaga tjCuo tjRec sumPaga sumCuo sumRec rdPaga rdCuo rdRec {
		_nlqnum "``v'_`t''"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' `", `q'pssFlag`q': `=cond(`pssFlag_`t'', "true", "false")'}`=cond(`j' < 2, ",", "")'"' _n
}
file write `fh' "  ]," _n

* 7.5 flujos (default + alternativas) *
quietly use `FL', clear
file write `fh' `"  `q'flujos`q': ["' _n
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'lado`q': `q'`=lado[`i']'`q', `q'k`q': `q'`=k[`i']'`q', `q'q`q': `=q[`i']', `q'variante`q': `q'`=variante[`i']'`q'"'
	foreach v in v share n nHog concTop1 total totalS1 totalS3 {
		_nlqnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' `", `q'cumpleN`q': `=cond(cumpleN[`i'], "true", "false")'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "  ]," _n

* 7.6 sin abrir (lado paga) por año *
file write `fh' `"  `q'sinAbrir`q': ["' _n
local rows ""
quietly use `ND', clear
local j = 0
local nsa = 0
foreach t in `anioref' `aniope' {
	foreach x of local impuestos {
		quietly summarize abierto if k == "`x'", meanonly
		if r(mean) == 0 local ++nsa
	}
}
foreach t in `anioref' `aniope' {
	foreach x of local impuestos {
		quietly summarize abierto if k == "`x'", meanonly
		if r(mean) == 0 {
			local ++j
			quietly levelsof grupoSinAbrir if k == "`x'", clean
			local g "`r(levels)'"
			_nlqnum "`pg`x'_`t''"
			local vv "`r(n)'"
			local s1 "null"
			local s3 "null"
			if "`x'" == "ISRPM" {
				_nlqnum "`pgISRPMS1_`t''"
				local s1 "`r(n)'"
				_nlqnum "`pgISRPMS3_`t''"
				local s3 "`r(n)'"
			}
			_nlqnum "`conc`x''"
			file write `fh' `"    {`q'anio`q': `t', `q'lado`q': `q'paga`q', `q'k`q': `q'`x'`q', `q'grupo`q': `q'`g'`q', `q'v`q': `vv', `q'vS1`q': `s1', `q'vS3`q': `s3', `q'concTop1NL`q': `r(n)'}`=cond(`j' < `nsa', ",", "")'"' _n
		}
	}
}
file write `fh' "  ]," _n

* 7.7 componentes de la caja gris *
quietly use `GR', clear
file write `fh' `"  `q'grisComponentes`q': ["' _n
forvalues i = 1/`=_N' {
	_nlqtxt `"`=lab[`i']'"'
	local labT `"`r(t)'"'
	_nlqnum "v[`i']"
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'clave`q': `q'`=clave[`i']'`q', `q'lab`q': `q'`labT'`q', `q'v`q': `r(n)'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `fh' "  ]" _n
file write `fh' "}" _n
file close `fh'

*** 8 RESUMEN ***
quietly checksum `"`json'"'
local kbj = string(r(filelen)/1024, "%9.0fc")
noisily di _newline in g "{bf:FederacionNLQuintiles: listo.}"
noisily di in g "  JSON: " in y `"`json'"' in g " (`kbj' KB) · esquema nl.federacion-quintiles/v1 · capa `nl_vnl' · motor `nl_vmotor' · ENIGH `enigh' · años `anioref' / `aniope'"
noisily di in g "  Sin HTML: la vista (SVG a 5 columnas) es la sesión C2."
quietly log close nlfq
