*! compuertas-entidad.do  v1.0 (global entidad, 2026-10-10) — compuertas de salida 2–4 del Sankey de entidad
*
* QUÉ HACE (corre DENTRO de la sesión de SIM.do, con sus escalares vivos, después de §8.2;
* lo invoca 05_scripts/compuertas-entidad.sh tras `do SIM.do`):
*   1. Genera el Sankey de entidad de las 32 entidades × 5 cortes (quintil estatal, grupoedad,
*      sexo, rural, escol) en users/$id/<ABREV>/, sin banda de vintages salvo para $entidad
*      (que conserva la configuración de la corrida). Es la materia prima de la compuerta 2
*      (aditividad: Σ 32 entidades = nacional) y de la 4 (segundo estado: sellos de muestra).
*   2. Para Nuevo León (si $entidad lo es o existe su base), reconstruye las 90 celdas
*      dis<fam>nle<dec> (participación por DECIL estatal de 9 familias) con el criterio de
*      Households.do §12 y las exporta a <evidencia>/nl-dis-nle-recalc.csv para la compuerta 3
*      (testigo: compuertas-entidad.py las compara con 05_scripts/fixtures/statajson_entidad-nl.json a 1e-13) y, desde v8.14,
*      las escribe tambien como testigo JSON (<evidencia>/statajson_entidad-nl.json) para regenerar esa referencia.
*   Los números se comparan en compuertas-entidad.py (lee los JSON); aquí solo se producen.
*
* USO: do "${SIMROOT}/05_scripts/compuertas-entidad.do" "<carpeta de evidencia>"
* OJO: destruye los datos en memoria.

local evidencia `"`1'"'
if `"`evidencia'"' == "" {
	di as err "compuertas-entidad: indica la carpeta de evidencia."
	exit 198
}
capture mkdir `"`evidencia'"'
timer clear 8
timer on 8
SIMentidad

*** 1 Las 32 entidades × 5 cortes ***
* La banda de vintages (4.º argumento de SankeySF.do) solo se calcula para la entidad de la
* sesión; las otras 31 van sin banda ("0") para no recorrer los cinco vintages 31 veces. *
noisily di _newline in g "{bf:compuertas-entidad 1/2: Sankey de entidad para las 32 entidades (quintil estatal, grupoedad, sexo, rural, escol)}"
local j = 1
foreach ent of global entidadesL {
	if `j' > 32 continue, break
	local vint = cond(`"`ent'"' == `"$entidad"', "", "0")
	foreach k in quintil grupoedad sexo rural escol {
		quietly run "${SIMROOT}/01_modulos/visualizations/SankeySF.do" `k' `=anioPE' `"`ent'"' "`vint'"
	}
	noisily di in g "  `j'/32 " in y `"`ent'"' in g " listo."
	local ++j
}

*** 2 Testigo NL: 90 celdas dis<fam>nle<dec> por decil estatal ***
noisily di _newline in g "{bf:compuertas-entidad 2/2: reconstrucción de dis<fam>nle<dec> (Nuevo León, decil estatal)}"
quietly {
	use folioviv foliohog factor edad ingbrutotot AlTrabajo AlConsumo AlCapital ImpuestosAportaciones ///
		IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim using `"${SIMROOT}/users/$id/aportaciones.dta"', clear
	keep if substr(folioviv, 1, 2) == "19"
	tempvar toti ingh ingpc wh
	egen `toti' = count(edad), by(folioviv foliohog)
	egen double `ingh' = total(ingbrutotot), by(folioviv foliohog)
	g double `ingpc' = `ingh'/`toti'
	g double `wh' = factor/`toti'
	xtile decilE = `ingpc' [pw=`wh'], n(10)
	xtile quintilE = `ingpc' [pw=`wh'], n(5)
	count if quintilE != ceil(decilE/2)
	local nq = r(N)
	local fams "AlTrabajo AlConsumo AlCapital ImpAport IVA IEPSNP IEPSP ISAN IMPORT"
	local vars "AlTrabajo AlConsumo AlCapital ImpuestosAportaciones IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim"
	local cs ""
	forvalues i = 1/9 {
		local v : word `i' of `vars'
		g double w_`i' = `v'*factor
		local cs "`cs' w_`i'"
	}
	collapse (sum) `cs', by(decilE)
	forvalues i = 1/9 {
		egen double t = total(w_`i')
		replace w_`i' = w_`i'/t*100
		drop t
	}
	reshape long w_, i(decilE) j(i)
	g fam = ""
	forvalues i = 1/9 {
		replace fam = "`: word `i' of `fams''" if i == `i'
	}
	g dec = word("I II III IV V VI VII VIII IX X", decilE)
	g nombre = "dis" + fam + "nle" + dec
	rename w_ share
	format share %21.17g
	keep nombre share
	sort nombre
	export delimited using `"`evidencia'/nl-dis-nle-recalc.csv"', replace

	* v8.14: las mismas 90 celdas como TESTIGO versionable (JSON de escalares, esquema ciep.testigo.entidad-nl/v1). El testigo
	* del sprint NL (statajson_entidad-nl-2026-10-08.json, motor v8.8.1) quedo obsoleto con la correccion de datos v8.12.4; este
	* lo regenera el motor actual y se versiona en 05_scripts/fixtures/statajson_entidad-nl.json (lo lee compuertas-entidad.py
	* gate 3). Numeros nacidos aqui, en Stata; el .py solo compara. Determinismo: generado_en es la ULTIMA clave de procedencia. *
	local commit ""
	capture confirm file `"`evidencia'/commit.txt"'
	if _rc == 0 {
		tempname fc
		file open `fc' using `"`evidencia'/commit.txt"', read text
		file read `fc' commit
		file close `fc'
		local commit = word(`"`commit'"', 1)
	}
	local q = char(34)
	tempname fj
	file open `fj' using `"`evidencia'/statajson_entidad-nl.json"', write replace text
	file write `fj' `"{"esquema":"ciep.testigo.entidad-nl/v1","nodo":"entidad-nl","titulo":"Testigo NL: participacion (%) de cada decil estatal en 9 familias de impuestos de residentes de Nuevo Leon (dis<fam>nle<dec>)","' _n
	file write `fj' `""definicion":"decil estatal = xtile de ingbrutotot per capita del hogar con pw = factor/tot_integ sobre users/<id>/aportaciones.dta filtrado a folioviv 19 (Households.do §12); share = sum(var*factor del decil)/sum(var*factor de NL)*100; familias: AlTrabajo AlConsumo AlCapital ImpAport (ImpuestosAportaciones) IVA IEPSNP IEPSP ISAN IMPORT (*_Sim)","' _n
	file write `fj' `""procedencia":{"origen":"05_scripts/compuertas-entidad.do §2 (sesion de SIM.do)","anioPE":`=anioPE',"anioenigh":`=anioenigh',"commit":"`commit'","quintil_distinto_de_ceil_decil_entre_2":`nq',"generado_en":"`c(current_date)' `c(current_time)'"},"' _n
	file write `fj' `""escalares":{"' _n
	forvalues i = 1/`=_N' {
		* string() omite el cero inicial (.1528…), que no es JSON válido: se repone (misma cifra, otra escritura) *
		local v = trim(string(share[`i'], "%21.17g"))
		if substr("`v'", 1, 1) == "." local v = "0`v'"
		if substr("`v'", 1, 2) == "-." local v = "-0" + substr("`v'", 2, .)
		file write `fj' `"`=cond(`i' > 1, ",", "")'"`=nombre[`i']'":{"valor":`v',"tipo":"pct"}"' _n
	}
	file write `fj' "}}" _n
	file close `fj'
}
noisily di in g "  90 celdas exportadas a " in y `"`evidencia'/nl-dis-nle-recalc.csv"' in g " y como testigo a " in y `"`evidencia'/statajson_entidad-nl.json"' in g "; quintil ≠ ceil(decil/2) en " in y "`nq'" in g " personas (debe ser 0)."

timer off 8
quietly timer list 8
noisily di _newline in g "compuertas-entidad: " in y "LISTO" in g " en " in y round(r(t8), 1) in g " s."
