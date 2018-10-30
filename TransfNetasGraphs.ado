program define TransfNetasGraphs
quietly {
	syntax [, ID(string)]

	** Formales vs. Informales **
	PIBDeflactor
	tempfile PIBbase
	save `PIBbase'

	/*use `"`c(sysdir_personal)'/users/`id'/bootstraps/1/transfNetasIVREC"', clear
	append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/transfNetasVIXREC"'
	g id = "`id'"
	append using `"`c(sysdir_personal)'/users/bootstraps/1/transfNetasIVREC"'
	append using `"`c(sysdir_personal)'/users/bootstraps/1/transfNetasVIXREC"'
	merge m:1 (anio) using `PIBbase', nogen keepus(indiceY pibY* deflator productivity)*/

	use `"`c(sysdir_personal)'/users/`id'/bootstraps/1/transfFormalREC"', clear
	append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/transfInformalREC"'
	g id = "`id'"
	append using `"`c(sysdir_personal)'/users/bootstraps/1/transfFormalREC"'
	append using `"`c(sysdir_personal)'/users/bootstraps/1/transfInformalREC"'
	merge m:1 (anio) using `PIBbase', nogen keepus(indiceY pibY* deflator productivity)

	if "`id'" != "" {
		drop if anio < $anioVP & id != ""
		drop if anio >= $anioVP & id == ""
	}

	*g decilIV = estimacion*deflator*productivity/pibY*100 if modulo == "transfNetasIV"
	*g decilVIX = estimacion*deflator*productivity/pibY*100 if modulo == "transfNetasVIX"

	g Formal = estimacion*deflator*productivity/pibY*100 if modulo == "transfFormal"
	g Informal = estimacion*deflator*productivity/pibY*100 if modulo == "transfInformal"

	tempvar profileproj
	*collapse decilIV decilVIX pibY, by(anio aniobase)
	collapse Formal Informal pibY, by(anio aniobase)
	tsset anio

	*g total = decilIV + decilVIX
	g total = Formal + Informal

	/*label var decilIV "{bf:Decil I-V}"
	label var decilVIX "{bf:Decil VI-X}"
	label var total "{bf:Total}"*/

	label var Formal "{bf:Formales}"
	label var Informal "{bf:Informales}"
	label var total "{bf:Total}"

	/*twoway connected decilIV decilVIX total anio, ///
		ytitle(% PIB) ///
		/*yscale(range(-2(1)5))*/ ///
		ylabel(-5(1)8, format(%5.1fc) labsize(small)) ///
		xtitle("") ///
		title("Transferencias netas proyecciones de largo plazo") ///
		caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
		name(ProjInfvsFor`id', replace)*/

	twoway connected Formal Informal total anio, ///
		ytitle(% PIB) ///
		/*yscale(range(-2(1)5))*/ ///
		ylabel(-5(1)8, format(%5.1fc) labsize(small)) ///
		xtitle("") ///
		title("Transferencias netas proyecciones de largo plazo") ///
		caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
		name(ProjInfvsFor`id', replace)


	graph export `"`c(sysdir_personal)'/users/`id'/ProjInfvsFor`id'.eps"', replace name(ProjInfvsFor`id')
	*graph export `"`c(sysdir_personal)'/users/`id'/ProjInfvsFor`id'.png"', replace name(ProjInfvsFor`id')
}
end
