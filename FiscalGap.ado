program define FiscalGap
quietly {

	syntax [, Graphs Anio(int -1)]


	***********
	** 1 PIB **
	***********
	PIBDeflactor
	tempfile PIB
	save `PIB'


	***********
	** 2 LIF **
	***********
	LIF, anio(`anio')
	collapse (sum) recaudacion if divLIF != 10 & anio == `anio', by(anio)
	tempfile LIF
	save `LIF'

	LIF, anio(`anio')
	capture collapse (sum) endeudamiento=recaudacion if divLIF == 10 & anio == `anio', by(anio)
	if _rc == 0 {
		format endeudamiento %20.0fc
		tempfile endeudamiento
		save `endeudamiento'
	}


	***********
	** 3 PEF **
	***********
	PEF if desc_funcion != 1 & transf_gf == 0, anio(`anio')
	collapse (sum) gastoneto if anio == `anio', by(anio)
	format gastoneto %20.0fc
	tempfile PEF
	save `PEF'

	PEF if desc_funcion == 1 & transf_gf == 0, anio(`anio')
	collapse (sum) costodeuda=gastoneto if anio == `anio', by(anio)
	format costodeuda %20.0fc
	tempfile costodeuda
	save `costodeuda'


	***************
	** 4 Balance **
	***************
	use `LIF', clear
	capture append using `endeudamiento'
	if _rc != 0 {
		local sindeuda = "yes"
	}
	g origen = " Ingresos "

	append using `PEF'
	append using `costodeuda'
	replace origen = "Gastos" if origen == ""
	
	* Calcular deuda, en caso de no estar presente en la LIF *
	if "`sindeuda'" == "yes" {
		tabstat recaudacion gastoneto costodeuda, f(%20.0fc) save
		tempname DEUDA
		matrix `DEUDA' = r(StatTotal)
		
		set obs `=_N+1'
		replace anio = `anio' in -1
		g endeudamiento = `DEUDA'[1,2] + `DEUDA'[1,3] - `DEUDA'[1,1] in -1
		replace origen = " Ingresos " in -1
		format endeudamiento %20.0fc
	}

	* Unir PIB *
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator lambda var_pibY) ///
		keep(matched)
	foreach k of varlist recaudacion endeudamiento gastoneto costodeuda {
		g `k'PIB = `k'/pibY*100
	}
	format *PIB %7.3fc

	****************
	** 4.1 Graphs **
	if "`graphs'" == "graphs" {
		graph bar (sum) endeudamientoPIB recaudacionPIB costodeudaPIB gastonetoPIB, ///
			over(origen, descending) ///
			stack asyvars ///
			title("{bf:Balance p{c u'}blico `anio'}") ///
			subtitle("$pais") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(6) rows(1) ///
			label(2 "Recaudaci{c o'}n") label(1 "Endeudamiento") ///
			label(4 "Gasto neto") label(3 "Costo financiero de la deuda")) ///
			name(balances, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}")
		gr_edit .plotregion1.barlabels[1].Delete
		gr_edit .plotregion1.barlabels[2].Delete
		gr_edit .plotregion1.barlabels[7].Delete
		gr_edit .plotregion1.barlabels[8].Delete
	}
}
end
