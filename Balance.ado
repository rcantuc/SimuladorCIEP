program define Balance
quietly {



	syntax [, Graphs]



	*********
	** PIB **
	*********
	PIBDeflactor
	tempfile PIB
	save `PIB'



	*********
	** LIF **
	*********
	LIF
	collapse (sum) recaudacion if divLIF != 10 & anio == $anioVP, by(anio)
	tempfile LIF
	save `LIF'

	LIF
	collapse (sum) endeudamiento=recaudacion if divLIF == 10 & anio == $anioVP, by(anio)
	tempfile endeudamiento
	save `endeudamiento'



	*********
	** PEF **
	*********
	PEF if capitulo != 9 & transf_gf == 0 & ramo != -1
	collapse (sum) gastoneto if anio == $anioVP, by(anio)
	tempfile PEF
	save `PEF'

	PEF if capitulo == 9 & transf_gf == 0 & ramo != -1
	collapse (sum) costodeuda=gastoneto if anio == $anioVP, by(anio)
	tempfile costodeuda
	save `costodeuda'



	*************
	** Balance **
	*************
	use `LIF', clear
	append using `endeudamiento'
	g origen = "ILIF $anioVP"
	
	append using `PEF'
	append using `costodeuda'
	replace origen = "PPEF $anioVP" if origen == ""

	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator productivity var_pibY) update replace //keep(matched)
	foreach k of varlist recaudacion endeudamiento gastoneto costodeuda {
		g `k'PIB = `k'/pibY*100
	}
	format *PIB %7.3fc



	************
	** Graphs **
	************
	if "`graphs'" == "graphs" {
		graph bar (sum) recaudacionPIB endeudamientoPIB gastonetoPIB costodeudaPIB, ///
			over(origen, descending) ///
			stack asyvars ///
			title("{bf:Balance p{c u'}blico}") ///
			/// subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(6) rows(1) ///
			label(1 "Recaudaci{c o'}n") label(2 "Endeudamiento") ///
			label(3 "Gasto neto") label(4 "Costo financiero de la deuda")) ///
			name(balances, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
	
		gr_edit .plotregion1.barlabels[1].Delete
		gr_edit .plotregion1.barlabels[2].Delete
		gr_edit .plotregion1.barlabels[7].Delete
		gr_edit .plotregion1.barlabels[8].Delete
	}
}
end
