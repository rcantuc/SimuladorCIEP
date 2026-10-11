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
*      (testigo: compuertas-entidad.py las compara con statajson_entidad-nl.json a 1e-14).
*   Los números se comparan en compuertas-entidad.py (lee los JSON); aquí solo se producen.
*
* USO: do "${SIMROOT}/05_scripts/compuertas-entidad.do" "<carpeta de evidencia>"
* OJO: destruye los datos en memoria; respeta los globals de la sesión (entidad_macro, entidad_cuotas, sello_*).

local evidencia `"`1'"'
if `"`evidencia'"' == "" {
	di as err "compuertas-entidad: indica la carpeta de evidencia."
	exit 198
}
capture mkdir `"`evidencia'"'
timer clear 8
timer on 8
SIMentidad
local vint_sesion "$entidad_vintages"

*** 1 Las 32 entidades × 5 cortes ***
noisily di _newline in g "{bf:compuertas-entidad 1/2: Sankey de entidad para las 32 entidades (quintil estatal, grupoedad, sexo, rural, escol)}"
local j = 1
foreach ent of global entidadesL {
	if `j' > 32 continue, break
	if `"`ent'"' == `"$entidad"' global entidad_vintages "`vint_sesion'"
	else global entidad_vintages "0"
	foreach k in quintil grupoedad sexo rural escol {
		quietly run "${SIMROOT}/01_modulos/visualizations/SankeySF.do" `k' `=anioPE' `"`ent'"'
	}
	noisily di in g "  `j'/32 " in y `"`ent'"' in g " listo."
	local ++j
}
global entidad_vintages "`vint_sesion'"

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
	export delimited using `"`evidencia'/nl-dis-nle-recalc.csv"', replace
}
noisily di in g "  90 celdas exportadas a " in y `"`evidencia'/nl-dis-nle-recalc.csv"' in g "; quintil ≠ ceil(decil/2) en " in y "`nq'" in g " personas (debe ser 0)."

timer off 8
quietly timer list 8
noisily di _newline in g "compuertas-entidad: " in y "LISTO" in g " en " in y round(r(t8), 1) in g " s."
