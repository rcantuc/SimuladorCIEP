*! nl-flujos-herencia.do  v0.1.0 (C4, sprint NL-0.6.x) — HERENCIA: la paleta de NL se genera desde la configuración del Sankey nacional.
*
* Lee (solo lectura, con file read + regex; el motor no se toca):
*   01_modulos/visualizations/SankeySF.do   → eje 1 (ingreso) y eje 4 (gasto): collapse (sum) <ing_|gas_><etiqueta>=<variable>
*                                             [fw=factor] by(<corte>) + renglones macro (replace profile = <expr> in -k con sus
*                                             label define) + sumas previas (replace <var> = <var> + <var2>);
*   SIM.do §7.1                             → familias del ingreso: egen Al<X> = rsum(<componentes>_Sim …);
*   users/$id/sankey-decil.json             → los enlaces del Sankey nacional vigente (verificación H.1).
* Emite, con _nlflujo (definido por FederacionNLQuintiles.do), una fila de paleta por flujo nacional: mismos ids (variable en
* mayúsculas o etiqueta nacional normalizada), etiquetas, lados y agrupación (nodo nacional), con abrir 0 (inventario) y
* ancla `suma suma` (SUPUESTO) — las anclas de total NL las fija Ricardo en nl-flujos.do (overrides). La restricción a la
* muestra NL y el colapso a quintil estatal los hace el driver, igual que para cualquier fila.
* Renglones macro del nacional (IMSS+ISSSTE, Pemex+CFE, FMP, Part y otras Aport, Otros gastos, Energía, Costo de la deuda):
* no se colapsan por persona en el nacional; aquí se les asigna la distribución por persona de aportaciones.dta cuya Σ
* nacional REPRODUCE el enlace del JSON nacional (compuerta H.1, reldif 1e-6); si ninguna lo reproduce, la fila queda sin
* distribución en pesos (ind:persona = per cápita, como el nacional) y con ancla `pendiente`.
* COMPUERTA H.1 (aborta): cada fila heredada con distribución por persona reproduce, sobre TODA la muestra nacional y por
* decil nacional (filas micro) o en total (filas macro), el valor del enlace de sankey-decil.json.
* Uso: run desde FederacionNLQuintiles.do (requiere ${SIMROOT}, $id, _nlflujo y el frame nlq_pal).

local site `"${SIMROOT}"'
local sfdo `"`site'/01_modulos/visualizations/SankeySF.do"'
local simdo `"`site'/SIM.do"'
local sjson `"`site'/users/$id/sankey-decil.json"'
local aport `"`site'/users/$id/aportaciones.dta"'
foreach f in sfdo simdo sjson aport {
	capture confirm file `"``f''"'
	if _rc {
		di as err `"nl-flujos-herencia: falta ``f''. No se hereda."'
		exit 601
	}
}

*** 1 Parse de SankeySF.do ***
tempname fh
file open `fh' using `"`sfdo'"', read text
local eje = 0
local encom = 0
local blk = 0
local cont = char(47) + char(47) + char(47)			// "///" literal: no puede escribirse en el do-file (el preprocesador lo toma como continuación)
local acc ""
local nmic = 0
local nmac = 0
local nadd = 0
file read `fh' line
while r(eof) == 0 {
	local L `"`macval(line)'"'
	* comentarios de bloque /* ... */ *
	if `encom' {
		if strpos(`"`macval(L)'"', "*/") > 0 local encom = 0
		file read `fh' line
		continue
	}
	if regexm(`"`macval(L)'"', "^[ 	]*/\*") & strpos(`"`macval(L)'"', "*/") == 0 {
		local encom = 1
		file read `fh' line
		continue
	}
	if regexm(`"`macval(L)'"', "Eje 1:") local eje = 1
	if regexm(`"`macval(L)'"', "Eje 4:") local eje = 4
	if regexm(`"`macval(L)'"', "DEUDA o AHORRO|Eje 2:|Eje 3:") local eje = 0
	if `eje' == 1 | `eje' == 4 {
		* collapse (sum) … con continuaciones (tres diagonales) *
		if regexm(`"`macval(L)'"', "^[ 	]*collapse \(sum\)") | "`acc'" != "" {
			local acc `"`macval(acc)' `macval(L)'"'
			if !regexm(`"`macval(L)'"', "`cont'[ 	]*$") {
				local s `"`macval(acc)'"'
				local acc ""
				* quitar comentarios /* … */ en línea *
				while regexm(`"`macval(s)'"', "/\*[^*]*\*/") {
					local s = subinstr(`"`macval(s)'"', regexs(0), " ", 1)
				}
				while regexm(`"`macval(s)'"', "(ing_|gas_)([^ =]+)=([^ \[]+)") {
					local pre = regexs(1)
					local nom = regexs(2)
					local var = regexs(3)
					local s = subinstr(`"`macval(s)'"', regexs(0), " ", 1)
					local ++nmic
					local mic_eje`nmic' = `eje'
					local mic_var`nmic' "`var'"
					local lab = subinstr("`nom'", "_", " ", .)
					local mic_lab`nmic' = trim("`lab'")
					local mic_orden`nmic' = strlen("`nom'") - strlen(ltrim(subinstr("`nom'", "_", " ", .)))	// guiones bajos iniciales = orden nacional
				}
			}
		}
		* sumas previas al collapse: replace X = X + Y *
		if regexm(`"`macval(L)'"', "^[ 	]*replace ([^ ]+) = ([^ ]+) \+ ([^ ]+)[ 	]*$") {
			if regexs(1) == regexs(2) {
				local ++nadd
				local add_var`nadd' = regexs(1)
				local add_plus`nadd' = regexs(3)
				local add_eje`nadd' = `eje'
			}
		}
		* etiquetas: label define <from|to|`1'> NN "txt" *
		if regexm(`"`macval(L)'"', `"^[ 	]*label define ([^ ]+) ([0-9]+) "([^"]+)""') {
			local lv = regexs(1)
			local ln = regexs(2)
			local lt = regexs(3)
			local tipo = cond("`lv'" == "to", "to", cond("`lv'" == "from", "from", cond(`eje' == 1, "from", "to")))		// `1' = corte: eje 1 lado from, eje 4 lado to
			local lab_`tipo'_`eje'_`ln' "`lt'"
		}
		* renglones macro: cada `set obs` abre un bloque; replace from|profile|to = … in -k *
		if regexm(`"`macval(L)'"', "^[ 	]*set obs ") local ++blk
		if regexm(`"`macval(L)'"', "^[ 	]*replace (from|profile|to) = (.+) in -([0-9]+)[ 	]*$") {
			local campo = regexs(1)
			local val = regexs(2)
			local k = regexs(3)
			local mac_`campo'_`eje'_`blk'_`k' `"`macval(val)'"'
			local mac_keys "`mac_keys' `eje'_`blk'_`k'"
		}
	}
	file read `fh' line
}
file close `fh'
local mac_keys : list uniq mac_keys
foreach key of local mac_keys {
	if `"`mac_profile_`key''"' == "" | "`mac_from_`key''" == "" | "`mac_to_`key''" == "" continue
	local e = substr("`key'", 1, 1)
	local ++nmac
	local mac_eje`nmac' = `e'
	local mac_expr`nmac' `"`mac_profile_`key''"'
	local mac_from`nmac' = "`lab_from_`e'_`mac_from_`key'''"
	local mac_to`nmac' = "`lab_to_`e'_`mac_to_`key'''"
}
if `nmic' == 0 | `nmac' == 0 {
	di as err "nl-flujos-herencia: no pude leer los collapse o los renglones macro de SankeySF.do (`nmic' micro, `nmac' macro). No se hereda."
	exit 459
}

*** 2 Familias del ingreso en SIM.do §7.1: egen Al<X> = rsum(<componentes>) ***
file open `fh' using `"`simdo'"', read text
local nfam = 0
file read `fh' line
while r(eof) == 0 {
	if regexm(`"`macval(line)'"', "^[ 	]*egen (Al[A-Za-z]+) = rsum\(([^)]+)\)") {
		local ++nfam
		local fam_var`nfam' = regexs(1)
		local fam_comp`nfam' = trim(regexs(2))
	}
	file read `fh' line
}
file close `fh'

*** 3 Enlaces del Sankey nacional vigente (sankey-decil.json: nodes [{label:"…"}], links [{to:"<nombre>",value:"v",from:"<nombre>"}]) ***
file open `fh' using `"`sjson'"', read text
local js ""
file read `fh' line
while r(eof) == 0 {
	local js `"`macval(js)'`macval(line)'"'
	file read `fh' line
}
file close `fh'
local nn = 0
local s `"`macval(js)'"'
while regexm(`"`macval(s)'"', `"\{label:"([^"]*)"\}"') {
	local nod`nn' = regexs(1)
	local ++nn
	local s = subinstr(`"`macval(s)'"', regexs(0), "", 1)
}
local nl = 0
local s `"`macval(js)'"'
while regexm(`"`macval(s)'"', `"\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"\}"') {
	local ++nl
	local lk_to`nl' = regexs(1)
	local lk_v`nl' = real(regexs(2))
	local lk_from`nl' = regexs(3)
	local s = subinstr(`"`macval(s)'"', regexs(0), "", 1)
}
if `nl' == 0 | `nn' == 0 {
	di as err "nl-flujos-herencia: no pude leer nodos/enlaces de sankey-decil.json (`nn' nodos, `nl' enlaces). No se hereda."
	exit 459
}
capture program drop _nlhnorm
program define _nlhnorm, rclass
	args s
	local s = ustrlower(ustrnormalize("`s'", "nfd"))
	local s = ustrregexra("`s'", "[^a-z0-9]", "")
	local s = substr("`s'", 1, 12)										// nombres de macro ≤ 31 caracteres: LK_<12>_<12>
	return local s "`s'"
end
* valor del enlace nacional por (from, to) normalizados y por from *
forvalues i = 1/`nl' {
	_nlhnorm "`lk_from`i''"
	local f "`r(s)'"
	_nlhnorm "`lk_to`i''"
	local t "`r(s)'"
	local LK_`f'_`t' = `lk_v`i''
	if "`LKF_`f''" == "" local LKF_`f' = 0
	if "`LKT_`t''" == "" local LKT_`t' = 0
	local LKF_`f' = `LKF_`f'' + `lk_v`i''
	local LKT_`t' = `LKT_`t'' + `lk_v`i''
}

*** 4 Candidatas de distribución por persona para los renglones macro (se verifican en H.1; tabla documentada) ***
* (claves = _nlhnorm del nodo origen o del nodo destino, 12 caracteres; se prueban primero contra el enlace y luego contra el total del nodo origen)
local cand_imssissste "IMSS_Sim+ISSSTE_Sim"
local cand_pemexcfe "PEMEX_Sim+CFE_Sim"
local cand_fmp "FMP_Sim"
local cand_partyotrasap "Federalizado"
local cand_otrosgastos "OtrosGastosT Otros_gastos"
local cand_energia "Energia"
local cand_costodeladeu ""
* anclas candidatas (texto del inventario, de C3/C4; Ricardo las escribe en la línea cuando decida) *
local anc_ALTRABAJO "fed:pagaISRAS+fed:pagaISRPF+fed:pagaCUOTAS (contrato; cuotas aparte en el alcance NL) · statajson:RecISRASnl+RecISRPFnl+RecCUOTASnl"
local anc_ALCAPITAL "fed:pagaISRPM+fed:pagaOTROSK (OTROSK = aparte_no_sumado en la tarjeta) · statajson:RecISRPMnl+RecOTROSKnl"
local anc_ALCONSUMO "fed:pagaIVA+fed:pagaIEPSNP+fed:pagaIEPSP+fed:pagaISAN+fed:pagaIMPORT · statajson:RecIVAnl+…"
local anc_OTROSK "fed:pagaOTROSK / fed:pagaLifOTROSK · statajson:RecOTROSKnl (aparte, no sumado en la tarjeta paga)"
local anc_IMSS_ISSSTE "ninguna en el contrato (ingresos de organismos: alcance.excluye) · statajson no trae Rec IMSS/ISSSTE nl: HUECO"
local anc_PEMEX_CFE "ninguna en el contrato (ingresos de empresas: alcance.excluye): HUECO"
local anc_FMP "ninguna en el contrato (petroleros fuera del lado paga): HUECO"
local anc_EDUCACION "eofp:XAC33A (FAEB) · eofp:XAC33L (FAETA) · eofp:XAC33G+XAC33H (FAM educación) · fed:nlCD (convenios SEP) · pef:13+15 (FONE) · pef:9 (FAETA) · pef:11/6 (ODES) · becas pef:11/72, 11/311 fuera de la tarjeta"
local anc_SALUD "eofp:XAC33B (FASSA) · fed:nlPSS · pef:2 · gasto directo IMSS pef:50/31, ISSSTE pef:51/31, ramo 56: fuera de la tarjeta"
local anc_PENSIONES "ninguna en EOFP (gasto directo) · PEF.dta NL: pef:50/13, pef:50/15, pef:50/14, pef:51/17, pef:53/22: fuera de la tarjeta"
local anc_INGBASICO "ninguna: HUECO (en perfiles<PE>.dta es un marcador)"
local anc_OTRASINVERSIONES "ninguna en EOFP · PEF.dta NL no federalizado pef:9/19, pef:9/40: fuera de la tarjeta"
local anc_FEDERALIZADO "es el universo de la tarjeta recibe (fed:nlTot / fed:recibePaq): con esa ancla la caja gris queda en cero por construcción; FONE y SALUDFED son hijos"
local anc_OTROSGASTOS "ninguna: HUECO (gasto no distribuible por entidad)"
local anc_ENERGIA "ninguna en EOFP · CFE/PEMEX en NL son gasto no federalizado (pef:53/37…): fuera de la tarjeta; subsidio eléctrico no viene por entidad: HUECO"
local anc_COSTODEUDA "ninguna: HUECO (costo financiero de la deuda, per cápita en el nacional; sin ancla NL)"

*** 5 Compuerta H.1: reproducir los enlaces nacionales desde aportaciones.dta (toda la muestra, por decil nacional) ***
preserve
use `"`aport'"', clear
local rdH1 = 0
local nH1 = 0
local nfallo = 0
* 5.1 filas micro por decil *
forvalues i = 1/`nmic' {
	local v "`mic_var`i''"
	local plus ""
	forvalues a = 1/`nadd' {
		if "`add_var`a''" == "`v'" & `add_eje`a'' == `mic_eje`i'' local plus "`add_plus`a''"
	}
	capture confirm variable `v'
	if _rc {
		noisily di as err "nl-flujos-herencia (H.1): la variable `v' de SankeySF.do no existe en aportaciones.dta."
		exit 459
	}
	tempvar w
	quietly g double `w' = (`v'`=cond("`plus'" != "", "+`plus'", "")')*factor
	quietly levelsof decil, local(decs)
	foreach d of local decs {
		local dl : label (decil) `d'
		quietly summarize `w' if decil == `d', meanonly
		local sm = r(sum)
		_nlhnorm "`dl'"
		local f "`r(s)'"
		_nlhnorm "`mic_lab`i''"
		local t "`r(s)'"
		local key = cond(`mic_eje`i'' == 1, "`f'_`t'", "`t'_`f'")
		if "`LK_`key''" == "" {
			local ++nfallo
			noisily di as err "  H.1: no hay enlace nacional para `mic_lab`i'' / decil `dl'."
			continue
		}
		local rd = reldif(`sm', `LK_`key'')
		local rdH1 = max(`rdH1', `rd')
		local ++nH1
		if `rd' > 1e-6 {
			local ++nfallo
			noisily di as err "  H.1: `mic_lab`i'' decil `dl': Σ `v' = `sm' vs enlace nacional `LK_`key'' (reldif `rd')."
		}
	}
	quietly summarize `w', meanonly
	local mic_tot`i' = r(sum)
	local mic_plus`i' "`plus'"
	drop `w'
}
* 5.2 renglones macro: distribución por persona candidata cuya Σ nacional reproduce el enlace *
forvalues i = 1/`nmac' {
	_nlhnorm "`mac_from`i''"
	local f "`r(s)'"
	_nlhnorm "`mac_to`i''"
	local t "`r(s)'"
	local e = `mac_eje`i''
	local key = cond(`e' == 1, "`f'_`t'", "`f'_`t'")
	local vnac = "`LK_`key''"
	local tnac = cond(`e' == 1, "`LKF_`f''", "`LKF_`f''")		// total del nodo origen (suma de sus enlaces)
	if "`vnac'" == "" {
		noisily di as err "  H.1: no hay enlace nacional para el renglón macro `mac_from`i'' → `mac_to`i''."
		local ++nfallo
		continue
	}
	local mac_vnac`i' = `vnac'
	local mac_tnac`i' = `vnac'
	local mac_var`i' ""
	local mac_ok`i' = 0
	local mac_scope`i' "link"
	* (a) el enlace (from → to) contra candidatas del origen y del destino; (b) el total del nodo origen contra candidatas del origen *
	foreach intento in link from {
		if `mac_ok`i'' continue
		local objetivo = cond("`intento'" == "link", `vnac', cond("`tnac'" == "", `vnac', `tnac'))
		local cands = cond("`intento'" == "link", "`cand_`f'' `cand_`t''", "`cand_`f''")
		foreach c of local cands {
			capture {
				tempvar w
				g double `w' = (`c')*factor
				summarize `w', meanonly
				local sN = r(sum)
				drop `w'
			}
			if _rc continue
			if reldif(`sN', `objetivo') <= 1e-6 {
				local mac_var`i' "`c'"
				local mac_ok`i' = 1
				local mac_scope`i' "`intento'"
				local mac_tnac`i' = `objetivo'
				local rdH1 = max(`rdH1', reldif(`sN', `objetivo'))
				local ++nH1
				continue, break
			}
		}
	}
}
* 5.3 Σ nacional de los componentes de las familias (informativo) *
forvalues a = 1/`nfam' {
	foreach c of local fam_comp`a' {
		quietly summarize `c' [fw=factor], meanonly
		local comp_tot_`c' = r(sum)
	}
}
restore
if `nfallo' > 0 {
	di as err "nl-flujos-herencia (H.1): `nfallo' enlaces del Sankey nacional no se reproducen desde aportaciones.dta con la configuración leída de SankeySF.do. No se hereda."
	exit 459
}
noisily di in g "  Compuerta H.1 (herencia: `nH1' enlaces/renglones nacionales reproducidos desde aportaciones.dta con la configuración de SankeySF.do; reldif máx " in y %9.2e `rdH1' in g "): " in y "PASÓ" in g "."
_NLsha256 `"`sfdo'"'
global NLQH_sfdo_sha "`r(sha256)'"
_NLsha256 `"`sjson'"'
global NLQH_sjson_sha "`r(sha256)'"
global NLQH_nmic = `nmic'
global NLQH_nmac = `nmac'
global NLQH_nfam = `nfam'
global NLQH_rdH1 = `rdH1'

*** 6 Emisión de filas heredadas (abrir 0, ancla suma = SUPUESTO; ids = variable en mayúsculas o etiqueta nacional normalizada) ***
* 6.1 micro: familias del ingreso y rubros del gasto, en el orden nacional (guiones bajos) *
foreach e in 1 4 {
	local lado = cond(`e' == 1, "paga", "recibe")
	forvalues o = 0/9 {
		forvalues i = 1/`nmic' {
			if `mic_eje`i'' != `e' | `mic_orden`i'' != `o' continue
			local v "`mic_var`i''"
			local id = upper(subinstr("`v'", "_", "", .))
			local id = ustrregexra(ustrregexra(ustrnormalize("`id'", "nfd"), "\p{M}", ""), "[^A-Z0-9]", "")
			local var = "aport:`v'" + cond("`mic_plus`i''" != "", "+`mic_plus`i''", "")
			local nodo = cond(`e' == 1, "`mic_lab`i'' → $paqueteEconomico", "$paqueteEconomico → `mic_lab`i'' → corte")
			_nlflujo `id' `lado' 0 `var' suma suma "`mic_lab`i''", origen(nacional) eje(`e') nodo("`nodo'") totalnac(`mic_tot`i'') clave("heredado del Sankey nacional (SankeySF.do eje `e': collapse (sum) `v'`=cond("`mic_plus`i''" != "", "+`mic_plus`i''", "")' [fw=factor] por corte)") anclas("`anc_`id''")
			* componentes de la familia (SIM.do §7.1) *
			forvalues a = 1/`nfam' {
				if "`fam_var`a''" != "`v'" continue
				foreach c of local fam_comp`a' {
					local cid = upper(subinstr("`c'", "_Sim", "", .))
					_nlflujo `cid' `lado' 0 aport:`c' suma suma "`cid'", origen(nacional) eje(`e') padre(`id') totalnac(`comp_tot_`c'') nodo("componente de `mic_lab`i'' (SIM.do §7.1)") clave("componente de la familia `v' = rsum(`fam_comp`a'') del motor; <X>_Sim conciliado macro-micro") anclas("`anc_`cid''")
				}
			}
		}
	}
	* 6.2 macro del mismo eje *
	forvalues i = 1/`nmac' {
		if `mac_eje`i'' != `e' continue
		_nlhnorm "`mac_from`i''"
		local f "`r(s)'"
		if "`idmac_`f''" != "" & "`mac_scope`i''" == "from" {
			* mismo nodo origen con otro destino y distribución única (Energía → CFE Pemex SENER y → Sistema financiero): se acumula en la fila ya emitida (nota) *
			frame nlq_pal {
				replace nota = nota + " · también → `mac_to`i'' (`=string(`mac_vnac`i''/1e6, "%14.1fc")' mdp nacional)" if id == "`idmac_`f''"
			}
			continue
		}
		local base = cond("`idmac_`f''" != "", "`mac_to`i''", "`mac_from`i''")		// segundo destino con distribución propia (Pemex, CFE → FMP): id del destino
		local id = upper(ustrregexra(ustrregexra(ustrnormalize("`base'", "nfd"), "\p{M}", ""), "[^A-Za-z0-9]+", "_"))
		local id = ustrregexra("`id'", "^_|_$", "")
		if "`id'" == "COSTO_DE_LA_DEUDA" local id "COSTODEUDA"
		if "`id'" == "PART_Y_OTRAS_APORT" local id "FEDERALIZADO"
		if "`id'" == "OTROS_GASTOS" local id "OTROSGASTOS"
		if "`idmac_`f''" == "" local idmac_`f' "`id'"
		if `mac_ok`i'' {
			local var "aport:`mac_var`i''"
			local anc "suma suma"
			local cl "renglón macro del Sankey nacional (SankeySF.do eje `e': profile = `mac_expr`i'' → nodo `mac_to`i''); distribución por persona de aportaciones.dta cuya Σ nacional reproduce el enlace (H.1): `mac_var`i''"
		}
		else {
			local var "ind:persona"
			local anc "pendiente pendiente"
			local cl "renglón macro del Sankey nacional (SankeySF.do eje `e': profile = `mac_expr`i'' → nodo `mac_to`i''); per cápita en el nacional y SIN distribución en pesos por persona en aportaciones.dta: clave ind:persona (población), ancla pendiente"
		}
		_nlflujo `id' `lado' 0 `var' `anc' "`base'", origen(nacional) eje(`e') nodo("`mac_from`i'' → `mac_to`i''") totalnac(`mac_tnac`i'') clave("`cl'") anclas("`anc_`id''")
	}
}
noisily di in g "  Herencia: " in y "`nmic'" in g " rubros micro (+ componentes de `nfam' familias) y " in y "`nmac'" in g " renglones macro leídos de SankeySF.do; sankey-decil.json `=substr("$NLQH_sjson_sha", 1, 12)'… · SankeySF.do `=substr("$NLQH_sfdo_sha", 1, 12)'…"
