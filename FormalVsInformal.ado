program define TransfNetasGraphs
quietly {
	syntax [, ID(string)]

	** Formales vs. Informales **
	PIBDeflactor
	tempfile PIBbase
	save `PIBbase'

	use `"`c(sysdir_personal)'/users/`id'/bootstraps/1/transfNetasFormalesREC"', clear
	append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/transfNetasInformalesREC"'
	g id = "`id'"
	append using `"`c(sysdir_personal)'/users/bootstraps/1/transfNetasFormalesREC"'
	append using `"`c(sysdir_personal)'/users/bootstraps/1/transfNetasInformalesREC"'
	merge m:1 (anio) using `PIBbase', nogen keepus(indiceY pibY* deflator productivity)

	if "`id'" != "" {
		drop if anio < $anioVP & id != ""
		drop if anio >= $anioVP & id == ""
	}

	g formal = estimacion*deflator*productivity/pibY*100 if modulo == "transfNetasFormales"
	g informal = estimacion*deflator*productivity/pibY*100 if modulo == "transfNetasInformales"

	tempvar profileproj
	collapse formal informal pibY, by(anio aniobase)
	tsset anio

	g total = formal + informal

	label var formal "{bf:Formales}"
	label var informal "{bf:Informales}"
	label var total "{bf:Total}"

	twoway connected formal informal total anio, ///
		ytitle(% PIB) ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(, format(%5.1fc) labsize(small)) ///
		xtitle("") ///
		title("Transferencias netas proyecciones de largo plazo") ///
		caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
		name(ProjInfvsFor`id', replace)

	graph export `"`c(sysdir_personal)'/users/`id'/ProjInfvsFor`id'.eps"', replace name(ProjInfvsFor`id')
}
end
