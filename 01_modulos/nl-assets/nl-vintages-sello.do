*! nl-vintages-sello.do  v1.0.0 (NL-0.5.0) — sello de participaciones por vintage ENIGH (2016–2024) para FederacionNL
*
* QUÉ ES ESTO (DIAGNOSTICO_NL.md, anexo Participaciones históricas; resoluciones F0 §0.8)
*   Lee los cinco statajson_entidad-nl.json producidos por nl-vintage.do (uno por ENIGH
*   bienal: users/<usuario>-v<t>/nodos/), verifica cada uno contra el canal del motor y
*   escribe el EXTRACTO SELLADO 01_modulos/nl-assets/participaciones-vintages.json
*   (arquitectura B: el runner de CoNL lo consume; ningún número se teclea).
*
* COMPUERTAS (abortan):
*   (1) los cinco JSON existen y son de la misma capa y motor que la sesión; anio_referencia
*       = presentacion.enigh_vintage = vintage (calibración contemporánea);
*   (2) Rec<X>nac de cada vintage = recaudación observada del año en master/LIF.dta
*       (mes 12; filtro sin financiamiento de PerfilesSim §2), reldif 1e-6, 10 impuestos;
*   (3) Part<X>nl = Rec<X>nl/Rec<X>nac recalculado, reldif 1e-9;
*   (4) muestra: mínimo de hogares NL por decil nacional >= umbral (100; F0 §0.3);
*   (5) log de procedencia activo.
* INFORMATIVO (va al sello y al log, no aborta): saltos de participación entre vintages
*   consecutivos; concentración top-1 por impuesto y vintage (sensibilidad muestral,
*   resolución F0 §0.8-2); ligadura vintage 2024 vs corrida vigente (si existe
*   users/<usuario>/nodos/statajson_entidad-nl.json), que FederacionNL vuelve vinculante.
*
* USO (Mac, tras correr nl-vintage.do para 2016 2018 2020 2022 2024):
*   do "${SIMROOT}/01_modulos/nl-assets/nl-vintages-sello.do"
*   global nlvint_usuario <usuario>   -> usuario base de las corridas (default c(username))
*   global nlvint_vintages "2022 2024" -> solo desarrollo: sello parcial (avisa; no publicar)
* OJO: destruye los datos en memoria.

version 17

*** 0 RAÍZ, LOG, IDENTIDAD ***
SIMroot
local site `"${SIMROOT}"'
if "$id" == "" global id = "`c(username)'"
local usuario = cond("$nlvint_usuario" == "", "`c(username)'", "$nlvint_usuario")
local vintages "2016 2018 2020 2022 2024"
if "$nlvint_vintages" != "" {
	local vintages "$nlvint_vintages"								// solo desarrollo: sello parcial (la vista y la asignación lo declaran)
	noisily di as err "nl-vintages-sello: AVISO — sello PARCIAL con vintages `vintages' (global nlvint_vintages); no es el sello de publicación."
}
local umbral = 100
local impuestos "ISRAS ISRPF ISRPM IVA IEPSNP IEPSP ISAN IMPORT CUOTAS OTROSK"
local q = char(34)
capture mkdir `"`site'/users/$id"'
capture mkdir `"`site'/users/$id/nodos"'

capture log close nlvsello
quietly log using `"`site'/users/$id/nodos/nl-vintages-sello.log"', replace text name(nlvsello)
capture quietly log query nlvsello
if `"`r(filename)'"' == "" {
	di as err "nl-vintages-sello: no pudo abrirse el log de procedencia; sin procedencia no hay sello válido."
	exit 459
}

run `"`site'/01_modulos/nl-assets/nl-identidad.do"'
_NLidentidad, modulo("Participaciones por vintage ENIGH")
local nl_vmotor `"`r(version_motor)'"'
local nl_vnl `"`r(version_nl)'"'
if "`nl_vnl'" == "" | "`nl_vmotor'" == "" {
	di as err "nl-vintages-sello: sin versión de capa o de motor declarada no puede sellarse. No se exporta."
	exit 459
}
run `"`site'/01_modulos/nl-assets/nl-fed.do"'

capture program drop _nlvnum
program define _nlvnum, rclass
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

noisily di _newline in g "{bf:nl-vintages-sello: " in y "`vintages'" in g " · usuario de las corridas " in y "`usuario'" in g " · capa `nl_vnl' · motor `nl_vmotor'}"

*** 1 RECAUDACIÓN OBSERVADA DEL MOTOR (compuerta 2) ***
capture confirm file `"`site'/master/LIF.dta"'
if _rc {
	di as err "nl-vintages-sello: falta master/LIF.dta (canal del motor). El sello solo se escribe en el Mac."
	exit 601
}
quietly {
	use anio mes divSIM divLIF divCIEP monto if divLIF != 10 | divCIEP == 8 using `"`site'/master/LIF.dta"', clear
	decode divSIM, g(impuesto)
	g byte sel = 0
	foreach x of local impuestos {
		replace sel = 1 if impuesto == "`x'"
	}
	keep if sel
	collapse (sum) lifObs = monto (min) mes, by(anio impuesto)
	keep if mes == 12
	tempfile LIFOBS
	save `LIFOBS'
	_NLfileinfo `"`site'/master/LIF.dta"'
	local lif_mtime "`r(mtime)'"
}

*** 2 UN VINTAGE A LA VEZ: identidad, escalares, compuertas ***
tempfile V P
quietly {
	clear
	set obs 0
	g int enigh = .
	g int anioPE = .
	g int aniovp = .
	g str40 generado_en = ""
	g str64 sha = ""
	g str200 json = ""
	g double nHognl = .
	g double nPersnl = .
	g double nHogDecMinnl = .
	g double pobnl = .
	g double pobnac = .
	g double concTop1KPrivnl = .
	g double partImp = .
	g double partImpS1 = .
	g double partImpS3 = .
	save `V', emptyok
	clear
	set obs 0
	g int enigh = .
	g str8 impuesto = ""
	g double part = .
	g double partS1 = .
	g double partS2 = .
	g double partS3 = .
	g double recNac = .
	g double recNL = .
	g double lifObs = .
	g double concTop1 = .
	g double nPos = .
	save `P', emptyok
}
local nfail2 = 0
local nfail3 = 0
foreach t of local vintages {
	local json `"`site'/users/`usuario'-v`t'/nodos/statajson_entidad-nl.json"'
	capture confirm file `"`json'"'
	if _rc {
		di as err "nl-vintages-sello: falta `json' (corre nl-vintage.do `t'). No se exporta."
		exit 601
	}
	_NLjsonget using `"`json'"', keys(anio_referencia presentacion.enigh_vintage presentacion.version_capa_nl presentacion.version_motor procedencia.generado_en)
	local j_anio = `r(v1)'
	local j_enigh "`r(v2)'"
	local j_vnl "`r(v3)'"
	local j_vmotor "`r(v4)'"
	local j_gen `"`r(v5)'"'
	if `j_anio' != `t' | "`j_enigh'" != "`t'" {
		di as err "nl-vintages-sello: `json' es PE `j_anio' / ENIGH `j_enigh'; se esperaba `t'/`t' (calibración contemporánea). No se exporta."
		exit 459
	}
	if "`j_vnl'" != "`nl_vnl'" | "`j_vmotor'" != "`nl_vmotor'" {
		di as err "nl-vintages-sello: `json' es de la capa `j_vnl' / motor `j_vmotor'; la sesión es `nl_vnl' / `nl_vmotor'. Re-corre nl-vintage.do `t'. No se exporta."
		exit 459
	}
	_NLsha256 `"`json'"'
	local sha "`r(sha256)'"
	quietly {
		_NLjsonesc using `"`json'"', prefijos(Rec Part Pob nHog nPers concTop1 nPos)
		forvalues i = 1/`=_N' {
			local v`=nombre[`i']' = valor[`i']
		}
		foreach s in nHognl nPersnl nHogDecMinnl concTop1KPrivnl PartImpnl PartImpnlS1 PartImpnlS3 Pobnl Pobnac {
			if "`v`s''" == "" {
				noisily di as err "nl-vintages-sello: `json' no trae el escalar `s' (EntidadNL.do < v1.4.0). Re-corre nl-vintage.do `t'. No se exporta."
				exit 459
			}
		}
		* Compuerta 4: muestra *
		if `vnHogDecMinnl' < `umbral' {
			noisily di as err "nl-vintages-sello: ENIGH `t' tiene `vnHogDecMinnl' hogares NL en su decil nacional más delgado (< `umbral'). Decisión requerida (F0 §0.3). No se exporta."
			exit 459
		}
		* Filas de participaciones por impuesto *
		use `P', clear
		local n0 = _N
		set obs `=`n0' + wordcount("`impuestos'")'
		local i = `n0'
		foreach x of local impuestos {
			local ++i
			replace enigh = `t' in `i'
			replace impuesto = "`x'" in `i'
			replace recNac = `vRec`x'nac' in `i'
			replace recNL = `vRec`x'nl' in `i'
			replace part = `vRec`x'nl'/`vRec`x'nac' in `i'
			replace concTop1 = `vconcTop1`x'nl' in `i'
			replace nPos = `vnPos`x'nl' in `i'
			* Compuerta 3: Part exportada = Rec/Rec *
			if reldif(`vPart`x'nl'/100, `vRec`x'nl'/`vRec`x'nac') > 1e-9 local ++nfail3
			if "`x'" == "ISRPM" {
				forvalues s = 1/3 {
					replace partS`s' = `vRecISRPMnlS`s''/`vRecISRPMnac' in `i'
				}
			}
		}
		replace partS1 = part if partS1 == . & enigh == `t'
		replace partS2 = part if partS2 == . & enigh == `t'
		replace partS3 = part if partS3 == . & enigh == `t'
		save `P', replace
		* Compuerta 2: Rec<X>nac = LIF observada del año *
		use `LIFOBS', clear
		keep if anio == `t'
		foreach x of local impuestos {
			summarize lifObs if impuesto == "`x'", meanonly
			if r(N) != 1 {
				noisily di as err "nl-vintages-sello: LIF.dta sin observado a diciembre de `t' para `x'. No se exporta."
				exit 459
			}
			if reldif(r(mean), `vRec`x'nac') > 1e-6 {
				local ++nfail2
				noisily di as err "  `t' `x': LIF observada = `r(mean)' vs Rec`x'nac = `vRec`x'nac'"
			}
			local lo`x' = r(mean)
		}
		use `P', clear
		foreach x of local impuestos {
			replace lifObs = `lo`x'' if enigh == `t' & impuesto == "`x'"
		}
		save `P', replace
		* Fila del vintage *
		use `V', clear
		local n0 = _N
		set obs `=`n0' + 1'
		replace enigh = `t' in `=_N'
		replace anioPE = `j_anio' in `=_N'
		replace aniovp = `j_anio' in `=_N'
		replace generado_en = `"`j_gen'"' in `=_N'
		replace sha = "`sha'" in `=_N'
		replace json = subinstr(`"`json'"', `"`site'/"', "", .) in `=_N'
		replace nHognl = `vnHognl' in `=_N'
		replace nPersnl = `vnPersnl' in `=_N'
		replace nHogDecMinnl = `vnHogDecMinnl' in `=_N'
		replace pobnl = `vPobnl' in `=_N'
		replace pobnac = `vPobnac' in `=_N'
		replace concTop1KPrivnl = `vconcTop1KPrivnl' in `=_N'
		replace partImp = `vPartImpnl'/100 in `=_N'
		replace partImpS1 = `vPartImpnlS1'/100 in `=_N'
		replace partImpS3 = `vPartImpnlS3'/100 in `=_N'
		save `V', replace
	}
	noisily di in g "  ENIGH `t': PE `j_anio' · corrida `j_gen' · sha " in y "`=substr("`sha'",1,12)'" in g " · hogares NL " in y %5.0fc `vnHognl' in g " (mín. por decil " in y %3.0f `vnHogDecMinnl' in g ") · ISR PM " in y %6.2f `vPartISRPMnl' in g " % [S1 " %5.2f `vPartISRPMnlS1' ", S3 " %5.2f `vPartISRPMnlS3' "] · top-1 " in y %5.1f `vconcTop1ISRPMnl' in g " %"
}
if `nfail2' > 0 {
	di as err "nl-vintages-sello: Rec<X>nac no es la recaudación observada del año en `nfail2' impuesto-vintage (1e-6). No se exporta."
	exit 459
}
if `nfail3' > 0 {
	di as err "nl-vintages-sello: Part<X>nl exportada ≠ Rec<X>nl/Rec<X>nac en `nfail3' impuesto-vintage (1e-9). No se exporta."
	exit 459
}
noisily di in g "  Compuerta 1 (identidad y calibración contemporánea, `=wordcount("`vintages'")' vintages): " in y "PASÓ" in g "."
noisily di in g "  Compuerta 2 (Rec<X>nac = LIF observada del año, `=10*wordcount("`vintages'")' celdas, 1e-6): " in y "PASÓ" in g "."
noisily di in g "  Compuerta 3 (Part = Rec/Rec, 1e-9): " in y "PASÓ" in g "."
noisily di in g "  Compuerta 4 (mínimo de hogares NL por decil nacional ≥ `umbral'): " in y "PASÓ" in g "."

*** 3 INFORMATIVO: saltos entre vintages consecutivos y ligadura con la corrida vigente ***
quietly {
	use `P', clear
	sort impuesto enigh
	by impuesto: g double salto = (part - part[_n-1])*100
	g double asalto = abs(salto)
	collapse (max) saltoMax = asalto (max) concTop1Max = concTop1, by(impuesto)
	tempfile S
	save `S'
}
noisily di _newline in g "  Saltos máximos entre vintages consecutivos (pp) y concentración top-1 máxima (%) — informativo:"
forvalues i = 1/`=_N' {
	noisily di in g "  `=impuesto[`i']'" _col(12) in y %6.2f saltoMax[`i'] in g " pp" _col(26) in y %5.1f concTop1Max[`i'] in g " %"
}
local vigente `"`site'/users/`usuario'/nodos/statajson_entidad-nl.json"'
local lig_txt "sin corrida vigente en users/`usuario'/nodos (no se verificó la ligadura)"
local ligMax = .
capture confirm file `"`vigente'"'
if _rc == 0 {
	quietly {
		_NLjsonget using `"`vigente'"', keys(anio_referencia presentacion.enigh_vintage criterios.momento_de_registro)
		local vig_pe = `r(v1)'
		local vig_enigh "`r(v2)'"
		if "`vig_enigh'" == "" & regexm(`"`r(v3)'"', "ENIGH ([0-9][0-9][0-9][0-9])") local vig_enigh = regexs(1)
		_NLjsonesc using `"`vigente'"', prefijos(Part)
		forvalues i = 1/`=_N' {
			local g`=nombre[`i']' = valor[`i']
		}
		use `P', clear
		keep if enigh == 2024
		local ligMax = 0
		foreach x of local impuestos {
			summarize part if impuesto == "`x'", meanonly
			local d = reldif(r(mean), `gPart`x'nl'/100)
			if `d' > `ligMax' local ligMax = `d'
		}
	}
	local lig_txt "vintage 2024 (PE 2024) vs corrida vigente (PE `vig_pe', ENIGH `vig_enigh'): reldif máx `=string(`ligMax', "%9.2e")' en los 10 impuestos (FederacionNL exige ≤ 1e-3)"
}
noisily di in g "  Ligadura: " in y "`lig_txt'"

*** 4 SELLO ***
local sello `"`site'/01_modulos/nl-assets/participaciones-vintages.json"'
local gen = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
tempname sh
file open `sh' using `"`sello'"', write text replace
file write `sh' "{" _n
file write `sh' `"  `q'esquema`q': `q'nl.participaciones-vintages/v1`q',"' _n
file write `sh' `"  `q'nota`q': `q'Extracto SELLADO de las corridas del motor sobre cada ENIGH bienal (nl-vintage.do: anioPE = aniovp = anioenigh = vintage, sin los parámetros del Paquete, EntidadNL en la misma sesión). Lo escribe nl-vintages-sello.do en el Mac desde users/<usuario>-v<vintage>/nodos/statajson_entidad-nl.json y master/LIF.dta; FederacionNL lo consume para participacionesAnual. Ningún número se teclea.`q',"' _n
file write `sh' `"  `q'identidad`q': {`q'version_capa_nl`q': `q'`nl_vnl'`q', `q'version_motor`q': `q'`nl_vmotor'`q', `q'generado_en`q': `q'`gen'`q', `q'usuario`q': `q'`usuario'`q', `q'vintages`q': `q'`vintages'`q', `q'lif_dta_mtime`q': `q'`lif_mtime'`q', `q'umbral_hogares_decil`q': `umbral', `q'driver_vintage`q': `q'01_modulos/nl-assets/nl-vintage.do`q', `q'driver_sello`q': `q'01_modulos/nl-assets/nl-vintages-sello.do v1.0.0`q', `q'log`q': `q'nl-vintages-sello.log`q'},"' _n
file write `sh' `"  `q'asignacion`q': {`q'regla`q': `q'escalonada sin interpolación: cada ENIGH cubre su bienio (2016→2016–2017, 2018→2018–2019, 2020→2020–2021, 2022→2022–2023, 2024→2024 en adelante hasta el año de la corrida); años < 2016 = ENIGH 2016 con metodo extrapolado; años con ENIGH propia = metodo bienal; jamás se interpola entre vintages; la ENIGH 2014 queda fuera por el cambio de diseño 2016`q', `q'primer_vintage`q': 2016, `q'ultimo_vintage`q': 2024, `q'sello_2020`q': `q'ENIGH 2020 pandémica: levantamiento ago–nov 2020; posibles atipicidades; se usa tal cual para 2020–2021`q', `q'sensibilidad_muestral`q': `q'concTop1 = participación de la persona de NL con mayor impuesto simulado x factor en el total del impuesto de NL; la ENIGH es representativa por entidad en ingresos corrientes, no en la cola de ingresos de capital: el ISR PM de NL puede depender de una observación (F0 §0.5-B); se declara, no se corrige`q'},"' _n
_nlvnum "`ligMax'"
file write `sh' `"  `q'ligadura`q': {`q'texto`q': `q'`lig_txt'`q', `q'reldif_max`q': `r(n)'},"' _n
quietly use `V', clear
quietly sort enigh
file write `sh' `"  `q'vintages`q': ["' _n
forvalues i = 1/`=_N' {
	local selloT = cond(enigh[`i'] == 2020, "pandémica: levantamiento ago–nov 2020; posibles atipicidades", "")
	file write `sh' `"    {`q'enigh`q': `=enigh[`i']', `q'anioPE`q': `=anioPE[`i']', `q'aniovp`q': `=aniovp[`i']', `q'generado_en`q': `q'`=generado_en[`i']'`q', `q'statajson_sha256`q': `q'`=sha[`i']'`q', `q'statajson`q': `q'`=json[`i']'`q', `q'd1`q': `q'PASÓ (EntidadNL.do aborta si falla)`q', `q'sello`q': `q'`selloT'`q'"'
	foreach v in nHognl nPersnl nHogDecMinnl pobnl pobnac concTop1KPrivnl partImp partImpS1 partImpS3 {
		_nlvnum "`v'[`i']"
		file write `sh' `", `q'`v'`q': `r(n)'"'
	}
	file write `sh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `sh' "  ]," _n
quietly use `P', clear
quietly sort enigh impuesto
file write `sh' `"  `q'participaciones`q': ["' _n
forvalues i = 1/`=_N' {
	file write `sh' `"    {`q'enigh`q': `=enigh[`i']', `q'impuesto`q': `q'`=impuesto[`i']'`q'"'
	foreach v in part partS1 partS2 partS3 recNac recNL lifObs concTop1 nPos {
		_nlvnum "`v'[`i']"
		file write `sh' `", `q'`v'`q': `r(n)'"'
	}
	file write `sh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `sh' "  ]," _n
quietly use `S', clear
quietly sort impuesto
file write `sh' `"  `q'saltos`q': ["' _n
forvalues i = 1/`=_N' {
	_nlvnum "saltoMax[`i']"
	local a `r(n)'
	_nlvnum "concTop1Max[`i']"
	file write `sh' `"    {`q'impuesto`q': `q'`=impuesto[`i']'`q', `q'saltoMaxPp`q': `a', `q'concTop1Max`q': `r(n)'}`=cond(`i' < _N, ",", "")'"' _n
}
file write `sh' "  ]" _n
file write `sh' "}" _n
file close `sh'
quietly checksum `"`sello'"'
noisily di _newline in g "{bf:nl-vintages-sello: listo.} Sello: " in y `"`sello'"' in g " (" in y %6.0fc r(filelen)/1024 in g " KB; commitéalo con las corridas)."
quietly log close nlvsello
