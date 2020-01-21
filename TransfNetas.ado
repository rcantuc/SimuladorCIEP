program TransfNetas, return
quietly {
	syntax [, Anio(int $anioVP) Update Graphs Noisily Fast ID(string) REMAKE REBOOT]





	*****************
	*** 1. SANKEY ***
	*****************
	if `anio' >= 2016 {
		local enigh = "ENIGH"
		local enighanio = 2016
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}
	if `anio' == 2015 {
		local enigh = "ENIGH"
		local enighanio = 2014
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}

	if `anio' == 2014 {
		local enigh = "ENIGH"
		local enighanio = 2014
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}

	if `anio' == 2013 {
		local enigh = "ENIGH"
		local enighanio = 2012
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}

	use "`c(sysdir_personal)'/users/`id'/Sankey`anio'.dta", clear
	keep folio* numren edad decil sexo edad escol rec_* uso_* ing_anual tot_integ factor_hog formal

	foreach k of varlist uso_* {
		replace `k' = -`k'
	}

	if "`id'" != "" {
		local uso_IngBasi0 "uso_IngBasi0"
		Simulador uso_IngBasi0 [fw=factor_hog], base("ENIGH 2016") `reboot' nokernel
	}





	*******************************
	*** 2. TRANSFERENCIAS NETAS ***
	*******************************
	egen double TN = rsum( ///
		rec_ISR__asalariados rec_ISR__PF ///
		/*rec_ISR__PM*/ ///
		rec_CuotasT /*rec_CuotasP*/ ///
		rec_FMP /*rec_IMSSISSSTE rec_Pemex*/ rec_CFE_PF /*rec_CFE_PM*/ ///
		rec_IVA rec_IEPS__n rec_IEPS__p rec_ISAN rec_Importaciones ///
		/*uso_Gobierno5*/ ///
		uso_Educaci uso_Pension uso_Salud ///
		/*uso_Otros__*/ ///
		uso_IMSSISSSTE_resto ///
		/*uso_Pemex_resto*/ ///
		/*uso_CFE_resto*/ ///
		/*uso_neto_Transfe*/ ///
		/*uso_neto_Transac*/ ///
		`uso_IngBasi0')
	label var TN "Transferencias netas"
	*label var TN "Net public transfers"


	* Decil I-V *
	g double TNIVDeciles = TN if decil <= 5
	*label var TNIVDeciles "Transferencias netas (decil I-V)"
	label var TNIVDeciles "Net public transfers (decil I-V)"

	* Decil VI-X *
	g double TNVIXDeciles = TN if decil >= 6
	*label var TNVIXDeciles "Transferencias netas (decil VI-X)"
	label var TNVIX "Net public transfers (decil VI-X)"


	* Formal *
	g double TNFormalFormalidad = TN if formal != 0
	*label var TNFormalFormalidad "Transferencias netas (formales)"
	label var TNFormalFormalidad "Net public transfers (formals)"

	* Informal *
	g double TNInformalFormalidad = TN if formal == 0
	*label var TNInformalFormalidad "Transferencias netas (informales)"
	label var TNInformalFormalidad "Net public transfers (informals)"


	* Edad < 18 *
	g double TN017Edades = TN if edad < 18
	*label var TN017Edades "Transferencias netas (0-17 a${ni}os)"
	label var TN017Edades "Net public transfers (0-17 years)"

	g double TN1864Edades = TN if edad >= 18 & edad < 65
	*label var TN1864Edades "Transferencias netas (18-64 a${ni}os)"
	label var TN1864Edades "Net public transfers (18-64 years)"

	g double TN65Edades = TN if edad >= 65
	*label var TN65Edades "Transferencias netas (65 y m${a}s a${ni}os)"
	label var TN65Edades "Net public transfers (65+ years)"





	**********************************/
	*** 3. PERFILES Y SIMULADOR.ado ***
	***********************************
	foreach k of varlist TN* {
		capture confirm file "`c(sysdir_personal)'/users/`id'/bootstraps/1/`k'REC.dta"
		if _rc != 0 | "`reboot'" == "reboot" {
			if "`k'" == "TN" {
				local TNgraphs = "graphs"
				local TNnoisily = "noisily"
			}
			`TNnoisily' Simulador `k' [fw=factor_hog], ///
				base("`enigh' `enighanio'") `reboot' id(`id') nokernel `TNgraphs'
			local TNgraphs = ""
			local TNnoisily = ""
		}
	}
	foreach k of varlist rec_* uso_* {
		capture confirm file "`c(sysdir_personal)'/users/bootstraps/1/`k'REC.dta"
		if _rc != 0 {
			noisily Simulador `k' [fw=factor_hog], ///
				base("`enigh' `enighanio'") nokernel graphs
		}
	}

	PIBDeflactor
	tempfile PIBbase
	save `PIBbase'





	*******************
	*** 4. GRÁFICAS ***
	*******************
	if "`graphs'" == "graphs" {




		******************
		** 4.1. Deciles **
		use `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TNIVDecilesREC"', clear
		append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TNVIXDecilesREC"'
		g id = "`id'"
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TNIVDecilesREC"'
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TNVIXDecilesREC"'
		merge m:1 (anio) using `PIBbase', nogen keepus(indiceY pibY* deflator productivity)

		if "`id'" != "" {
			drop if anio < $anioVP & id != ""
			drop if anio >= $anioVP & id == ""
		}

		g TNIVDeciles = estimacion*deflator*productivity/pibY*100 if modulo == "TNIVDeciles"
		g TNVIXDeciles = estimacion*deflator*productivity/pibY*100 if modulo == "TNVIXDeciles"
		
		tempvar profileproj
		collapse *Deciles pibY, by(anio aniobase)
		tsset anio

		egen total = rsum(*Deciles)

		label var TNIVDeciles "{bf:Decil I-V}"
		label var TNVIXDeciles "{bf:Decil VI-X}"
		label var total "{bf:Total}"	

		twoway connected *Deciles total anio if anio >= 1993, ///
			/*ytitle(% PIB)*/ ///
			ytitle(% GDP) ///
			/*yscale(range(-2(1)5))*/ ///
			/*ylabel(-5(1)8, format(%5.1fc) labsize(small))*/ ///
			xtitle("") ///
			/*title("Transferencias netas proyecciones de largo plazo")*/ ///
			title("Long-term Net Public Transfers") ///
			/*caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")*/ ///
			caption("Source: Made by CIEP, using CIEP's Fiscal Simulator $simuladorCIEP. Date: `c(current_date)', `c(current_time)'.") ///
			name(ProyeccionLP`id', replace)
		graph save ProyeccionLP`id' `"`c(sysdir_personal)'/users/`id'/ProyeccionLP`id'.gph"', replace




		********************/
		** 4.2. Formalidad **
		use `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TNFormalFormalidadREC"', clear
		append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TNInformalFormalidadREC"'
		g id = "`id'"
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TNFormalFormalidadREC"'
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TNInformalFormalidadREC"'
		merge m:1 (anio) using `PIBbase', nogen keepus(indiceY pibY* deflator productivity)

		if "`id'" != "" {
			drop if anio < $anioVP & id != ""
			drop if anio >= $anioVP & id == ""
		}

		g TNFormalFormalidad = estimacion*deflator*productivity/pibY*100 if modulo == "TNFormalFormalidad"
		g TNInformalFormalidad = estimacion*deflator*productivity/pibY*100 if modulo == "TNInformalFormalidad"

		tempvar profileproj
		collapse *Formalidad pibY, by(anio aniobase)
		tsset anio

		egen total = rsum(*Formalidad)

		*label var TNFormalFormalidad "{bf:Formales}"
		label var TNFormalFormalidad "{bf:Formals}"
		*label var TNInformalFormalidad "{bf:Informales}"
		label var TNInformalFormalidad "{bf:Informals}"
		label var total "{bf:Total}"

		twoway connected *Formalidad total anio if anio >= 1993, ///
			/*ytitle(% PIB)*/ ///
			ytitle(% GDP) ///
			/*yscale(range(-2(1)5))*/ ///
			/*ylabel(-5(1)8, format(%5.1fc) labsize(small))*/ ///
			xtitle("") ///
			/*title("Transferencias netas proyecciones de largo plazo")*/ ///
			title("Long-term Net Public Transfers") ///
			/*caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")*/ ///
			caption("Source: Made by CIEP, using CIEP's Fiscal Simulator $simuladorCIEP. Date: `c(current_date)', `c(current_time)'.") ///
			name(ProyeccionLP2`id', replace)
		graph save ProyeccionLP2`id' `"`c(sysdir_personal)'/users/`id'/ProyeccionLP2`id'.gph"', replace





		****************/
		** 4.3. Edades **
		use `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TN017EdadesREC"', clear
		append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TN1864EdadesREC"'
		append using `"`c(sysdir_personal)'/users/`id'/bootstraps/1/TN65EdadesREC"'
		g id = "`id'"
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TN017EdadesREC"'
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TN1864EdadesREC"'
		append using `"`c(sysdir_personal)'/users/bootstraps/1/TN65EdadesREC"'
		merge m:1 (anio) using `PIBbase', nogen keepus(indiceY pibY* deflator productivity)

		if "`id'" != "" {
			drop if anio < $anioVP & id != ""
			drop if anio >= $anioVP & id == ""
		}

		g TN017Edades = estimacion*deflator*productivity/pibY*100 if modulo == "TN017Edades"
		g TN1864Edades = estimacion*deflator*productivity/pibY*100 if modulo == "TN1864Edades"
		g TN65Edades = estimacion*deflator*productivity/pibY*100 if modulo == "TN65Edades"

		tempvar profileproj
		collapse *Edades pibY, by(anio aniobase)
		tsset anio

		egen total = rsum(*Edades)

		label var TN017Edades "{bf:0-17}"
		label var TN1864Edades "{bf:18-64}"
		label var TN65Edades "{bf:65+}"
		label var total "{bf:Total}"

		twoway connected *Edades total anio if anio >= 1993, ///
			legend(cols(4)) ///
			/*ytitle(% PIB)*/ ///
			ytitle(% GDP) ///
			/*yscale(range(-2(1)5))*/ ///
			/*ylabel(-5(1)8, format(%5.1fc) labsize(small))*/ ///
			xtitle("") ///
			/*title("Transferencias netas proyecciones de largo plazo")*/ ///
			title("Long-term Net Public Transfers") ///
			/*caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")*/ ///
			caption("Source: Made by CIEP, using CIEP's Fiscal Simulator $simuladorCIEP. Date: `c(current_date)', `c(current_time)'.") ///
			name(ProyeccionLP3`id', replace)
		graph save ProyeccionLP3`id' `"`c(sysdir_personal)'/users/`id'/ProyeccionLP3`id'.gph"', replace
	}




	****************/
	*** 5. Sankey ***
	*****************
	foreach j in decil sexo edad escol formal {
		noisily Sankey, by(`j') anio(`anio') id(`id')
	}
}
end
