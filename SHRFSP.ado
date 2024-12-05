program define SHRFSP, return
quietly {

	timer on 5

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}	
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	***********************
	***                 ***
	**# 1 BASE DE DATOS ***
	***                 ***
	***********************
	capture confirm file `"`c(sysdir_personal)'/SIM/SHRFSP.dta"'
	if _rc != 0 {
		noisily UpdateSHRFSP
	}



	****************
	***          ***
	**# 2 SYNTAX ***
	***          ***
	****************
	use in 1 using `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', clear
	syntax [if] [, ANIO(int `aniovp' ) DEPreciacion(int 5) ///
		NOGraphs UPDATE Base ///
		ULTAnio(int 2001) TEXTbook]
	
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: DEUDA $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`=aniovp') nographs nooutput `update'
	local currency = currency[1]
	g Poblacion_ajustada = Poblacion*lambda
	tempfile PIB
	save `PIB'

	** 2.3 Update SHRFSP **
	if "`update'" == "update" {
		noisily UpdateSHRFSP
	}

	** 2.4 Bases RAW **
	use `if' using `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', clear
	if "`base'" == "base" {
		exit
	}
	local aniofin = anio[_N]
	local mesfin = mes[_N]



	***************
	***         ***
	**# 3 MERGE ***
	***         ***
	***************
	sort anio
	merge m:1 (anio) using `PIB', nogen keepus(pibY pibYR var_* Poblacion* deflator lambda currency) update replace
	capture sort anio mes
	capture keep `if'
	local aniofirst = anio[1]
	local aniolast = anio[_N]
	local meslast = mes[_N]

	* 3.1 Anio, mes y observaciones iniciales y finales de la serie *
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local obsvp = `k'		
		}
		if shrfsp[`k'] == . & shrfsp[`k'-1] != . {
			local lastexo = anio[`k'-1]
		}
	}
	local obsfin = _N



	*****************************
	***                       ***
	**# 4 PARÁMETROS EXÓGENOS ***
	***                       ***
	*****************************
	tsset anio
	forvalues j = 1(1)`=_N' {
		* Política fiscal *
		foreach k of varlist shrfspInterno shrfspExterno ///
			rfspBalance rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones ///
			balprimario {
			capture confirm existence ${`k'`=anio[`j']'}
			if _rc == 0 {
				replace `k' = ${`k'`=anio[`j']'}/100*pibY if anio == `=anio[`j']'
				local lastexo = `=anio[`j']'
				local obslastexo = `j'
			}
		}
		
		* Costos financieros *
		replace porInterno = shrfspInterno/(shrfspInterno+shrfspExterno) if porInterno == .
		replace porExterno = shrfspExterno/(shrfspInterno+shrfspExterno) if porExterno == .
		capture confirm existence ${costodeudaInterno`=anio[`j']'}
		if _rc == 0 {
			replace costodeudaInterno = ${costodeudaInterno`=anio[`j']'}/100*porInterno*pibY if anio == `=anio[`j']'
		}		
		capture confirm existence ${costodeudaExterno`=anio[`j']'}
		if _rc == 0 {
			replace costodeudaExterno = ${costodeudaExterno`=anio[`j']'}/100*porExterno*pibY if anio == `=anio[`j']'
		}
		format costodeuda* %20.0fc
		
		* Tipo de cambio *
		capture confirm existence ${tipoDeCambio`=anio[`j']'}
		if _rc == 0 {
			replace tipoDeCambio = ${tipoDeCambio`=anio[`j']'} if anio == `=anio[`j']'
		}
		replace rfsp = rfspBalance + rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones if anio == `=anio[`j']'
		replace shrfsp = shrfspInterno + shrfspExterno if anio == `=anio[`j']'
		replace costofinanciero = costodeudaInterno + costodeudaExterno
	}



	*****************
	***           ***
	**# 5 DISPLAY ***
	***           ***
	*****************
	noisily di _newline in g "{bf: " ///
		_col(33) in g %20s "`currency'" ///
		_col(55) %7s "% PIB" ///
		_col(66) %7s "% Tot" "}"

	egen rfspOtros = rowtotal(rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones)
	tabstat rfspBalance rfspOtros rfsp shrfspInterno shrfspExterno shrfsp ///
		rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones if anio == `anio', stat(sum) format(%20.0fc) save
	if _rc != 0 {
		noisily di in r "No hay informaci{c o'}n para el a{c n~}o `anio'"
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)

	tabstat pibY Poblacion_ajustada if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot2
	matrix `mattot2' = r(StatTotal)

	scalar rfspBalance = string(rfspBalance[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspBalancePIB = rfspBalance[`obsvp']/pibY[`obsvp']*100

	scalar rfspPIDIREGAS = string(rfspPIDIREGAS[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspPIDIREGASPIB = rfspPIDIREGAS[`obsvp']/pibY[`obsvp']*100

	scalar rfspIPAB = string(rfspIPAB[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspIPABPIB = rfspIPAB[`obsvp']/pibY[`obsvp']*100

	scalar rfspFONADIN = string(rfspFONADIN[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspFONADINPIB = rfspFONADIN[`obsvp']/pibY[`obsvp']*100

	scalar rfspDeudores = string(rfspDeudores[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspDeudoresPIB = rfspDeudores[`obsvp']/pibY[`obsvp']*100

	scalar rfspBanca = string(rfspBanca[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspBancaPIB = rfspBanca[`obsvp']/pibY[`obsvp']*100

	scalar rfspAdecuaciones = string(rfspAdecuaciones[`obsvp']/rfsp[`obsvp']*100,"%5.1f")
	scalar rfspAdecuacionesPIB = rfspAdecuaciones[`obsvp']/pibY[`obsvp']*100

	scalar RFSP = rfsp[`obsvp']
	scalar RFSPPIB = rfsp[`obsvp']/pibY[`obsvp']*100
	scalar RFSPlastPIB = rfsp[`obslastexo']/pibY[`obslastexo']*100

	scalar SHRFSPInterno = shrfspInterno[`obsvp']/shrfsp[`obsvp']*100
	scalar SHRFSPExterno = shrfspExterno[`obsvp']/shrfsp[`obsvp']*100
	scalar SHRFSP = shrfsp[`obsvp']
	scalar SHRFSPPIB = shrfsp[`obsvp']/pibY[`obsvp']*100
	scalar SHRFSPlastPIB = shrfsp[`obslastexo']/pibY[`obslastexo']*100
	scalar SHRFSPPC = shrfsp[`obsvp']/Poblacion_ajustada[`obsvp']
	scalar SHRFSPlastPC = shrfsp[`obslastexo']/Poblacion_ajustada[`obslastexo']

	noisily di in g "  (+) Balance presupuestario" ///
		_col(33) in y %20.0fc `mattot'[1,1] ///
		_col(55) in y %7.1fc `mattot'[1,1]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot'[1,3]*100
	noisily di in g "  (+) PIDIREGAS" ///
		_col(33) in y %20.0fc `mattot'[1,7] ///
		_col(55) in y %7.1fc `mattot'[1,7]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,7]/`mattot'[1,3]*100
	noisily di in g "  (+) IPAB" ///
		_col(33) in y %20.0fc `mattot'[1,8] ///
		_col(55) in y %7.1fc `mattot'[1,8]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,8]/`mattot'[1,3]*100
	noisily di in g "  (+) FONADIN" ///
		_col(33) in y %20.0fc `mattot'[1,9] ///
		_col(55) in y %7.1fc `mattot'[1,9]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,9]/`mattot'[1,3]*100
	noisily di in g "  (+) Programa de Deudores" ///
		_col(33) in y %20.0fc `mattot'[1,10] ///
		_col(55) in y %7.1fc `mattot'[1,10]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,10]/`mattot'[1,3]*100
	noisily di in g "  (+) Banca de Desarrollo" ///
		_col(33) in y %20.0fc `mattot'[1,11] ///
		_col(55) in y %7.1fc `mattot'[1,11]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,11]/`mattot'[1,3]*100
	noisily di in g "  (+) Adecuaciones" ///
		_col(33) in y %20.0fc `mattot'[1,12] ///
		_col(55) in y %7.1fc `mattot'[1,12]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,12]/`mattot'[1,3]*100
	noisily di in g _dup(72) "-"
	noisily di in g "  {bf:(=) RFSP" ///
		_col(33) in y %20.0fc `mattot'[1,3] ///
		_col(55) in y %7.1fc `mattot'[1,3]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,3]/`mattot'[1,3]*100 "}"
	noisily di in g _dup(72) "="
	noisily di in g "  (+) SHRFSP Interna" ///
		_col(33) in y %20.0fc `mattot'[1,4] ///
		_col(55) in y %7.1fc `mattot'[1,4]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,4]/`mattot'[1,6]*100
	noisily di in g "  (+) SHRFSP Externa" ///
		_col(33) in y %20.0fc `mattot'[1,5] ///
		_col(55) in y %7.1fc `mattot'[1,5]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,5]/`mattot'[1,6]*100
	noisily di in g _dup(72) "-"
	noisily di in g "  {bf:(=) SHRFSP" ///
		_col(33) in y %20.0fc `mattot'[1,6] ///
		_col(55) in y %7.1fc `mattot'[1,6]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,6]/`mattot'[1,6]*100 "}"

	* Micrositio *
	return scalar rfspBalance = `mattot'[1,1]
	return scalar rfspBalancePIB = `mattot'[1,1]/`mattot2'[1,1]*100
	return scalar rfspBalancePC = `mattot'[1,1]/`mattot2'[1,2]

	return scalar rfspOtros = `mattot'[1,2]
	return scalar rfspOtrosPIB = `mattot'[1,2]/`mattot2'[1,1]*100
	return scalar rfspOtrosPC = `mattot'[1,2]/`mattot2'[1,2]

	return scalar rfsp = `mattot'[1,3]
	return scalar rfspPIB = `mattot'[1,3]/`mattot2'[1,1]*100
	return scalar rfspPC = `mattot'[1,3]/`mattot2'[1,2]

	return scalar shrfspInterno = `mattot'[1,4]
	return scalar shrfspInternoPIB = `mattot'[1,4]/`mattot2'[1,1]*100
	return scalar shrfspInternoPC = `mattot'[1,4]/`mattot2'[1,2]

	return scalar shrfspExterno = `mattot'[1,5]
	return scalar shrfspExternoPIB = `mattot'[1,5]/`mattot2'[1,1]*100
	return scalar shrfspExternoPC = `mattot'[1,5]/`mattot2'[1,2]

	return scalar shrfsp = `mattot'[1,6]
	return scalar shrfspPIB = `mattot'[1,6]/`mattot2'[1,1]*100
	return scalar shrfspPC = `mattot'[1,6]/`mattot2'[1,2]
	
	** 4.2.1 Gráfica generales **
	if "`nographs'" != "nographs" & "$nographs" == "" {

		tempvar shrfsp_pib interno externo interno_label
		g `shrfsp_pib' = shrfsp/pibY*100
		g `externo' = shrfspExterno/1000000000000/deflator
		g `interno' = `externo' + shrfspInterno/1000000000000/deflator
		g `interno_label' = shrfspInterno/1000000000000/deflator
		format `shrfsp_pib' %7.1fc
		format `interno' `externo' `interno_label' %10.1fc

		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		tabstat `interno' `shrfsp_pib', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway (bar `interno' anio if anio > 2000 & anio <= 2024, barwidth(.75)) ///
			(bar `externo' anio if anio > 2000 & anio <= 2024, barwidth(.75) pstyle(p1) fintensity(50) lcolor(none)) ///
			(bar `interno' anio if anio > 2024 & anio <= 2030, barwidth(.75) pstyle(p2) lcolor(none)) ///
			(bar `externo' anio if anio > 2024 & anio <= 2030, barwidth(.75) pstyle(p2) fintensity(50) lcolor(none)) ///
			(connected `shrfsp_pib' anio if anio > 2000 & anio <= 2024, ///
				yaxis(2) mlabel(`shrfsp_pib') mlabposition(12) mlabcolor(black) pstyle(p1) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(connected `shrfsp_pib' anio if anio > 2024 & anio <= 2030, ///
				yaxis(2) mlabel(`shrfsp_pib') mlabposition(12) mlabcolor(black) pstyle(p2) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(scatter `interno' anio if anio > 2000 & anio <= 2030, ///
				mlabel(`interno') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(vlarge)) ///
			if `externo' != . & anio > `ultanio', ///
			title(`graphtitle') ///
			///subtitle("Monto reportado (billones `currency' `aniovp') y como % del PIB") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			yscale(range(0 `=`rango'[2,1]*1.65') axis(1) noline) ///
			yscale(range(-10 `=`rango'[2,2]*1.45') axis(2) noline) ///
			text(`=`shrfsp_pib'[24]' `=`ultanio'+1' "{bf:% PIB}", ///
				place(6) yaxis(2) size(large) color("111 111 111")) ///
			text(`=`interno'[24]' `=`ultanio'+1' "{bf:billones}" "{bf:`currency' `aniovp'}", ///
				place(6) size(large) color("111 111 111")) ///
			///text(`=(`interno'[41]-`externo'[41])*.5+`externo'[41]' 2030 "Interno", ///
			///	place(0) size(large) color("111 111 111") justification(center)) ///
			///text(`=`externo'[41]*.5' 2030 "Externo", ///
			///	place(0) size(large) color("111 111 111") justification(center)) ///
			///text(`=`rango'[2,2]*1.45' `=2001+2.5' "{bf:Dif. `=anio[11]'-`=anio[17]':} `=string(`shrfsp_pib'[17]-`shrfsp_pib'[11],"%5.1f")' puntos PIB", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.45' `=2007+2.5' "{bf:Dif. `=anio[17]'-`=anio[23]':} `=string(`shrfsp_pib'[23]-`shrfsp_pib'[17],"%5.1f")' puntos PIB", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.45' `=2013+2.5' "{bf:Dif. `=anio[23]'-`=anio[29]':} `=string(`shrfsp_pib'[29]-`shrfsp_pib'[23],"%5.1f")' puntos PIB", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.45' `=2019+2.5' "{bf:Dif. `=anio[29]'-`=anio[35]':} `=string(`shrfsp_pib'[35]-`shrfsp_pib'[29],"%5.1f")' puntos PIB", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.45' `=2025+2.5' "{bf:Dif. `=anio[35]'-`=anio[41]':} `=string(`shrfsp_pib'[41]-`shrfsp_pib'[35],"%5.1f")' puntos PIB", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'. Las diferencias en puntos PIB se hacen con respecto al último año de la serie anterior.") ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			legend(off) ///
			name(shrfsp, replace)

		graph save shrfsp `"`c(sysdir_personal)'/SIM/graphs/shrfsp.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}

		** Por persona **
		tempvar shrfsp_pc
		g `shrfsp_pc' = shrfsp/Poblacion_ajustada/deflator/1000
		format `shrfsp_pc' %10.0fc

		tabstat `interno' `shrfsp_pc', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway (bar `interno' anio if anio > 2000 & anio <= 2024, barwidth(.75)) ///
			(bar `externo' anio if anio > 2000 & anio <= 2024, barwidth(.75) pstyle(p1) fintensity(50) lcolor(none)) ///
			(bar `interno' anio if anio > 2024 & anio <= 2030, barwidth(.75) pstyle(p2) lcolor(none)) ///
			(bar `externo' anio if anio > 2024 & anio <= 2030, barwidth(.75) pstyle(p2) fintensity(50) lcolor(none)) ///
			(connected `shrfsp_pc' anio if anio > 2000 & anio <= 2024, ///
				yaxis(2) mlabel(`shrfsp_pc') mlabposition(12) mlabcolor(black) pstyle(p1) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(connected `shrfsp_pc' anio if anio > 2024 & anio <= 2030, ///
				yaxis(2) mlabel(`shrfsp_pc') mlabposition(12) mlabcolor(black) pstyle(p2) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(scatter `interno' anio if anio > 2000 & anio <= 2030, ///
				mlabel(`interno') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(vlarge)) ///
			if `externo' != . & anio > `ultanio', ///
			title(`graphtitle') ///
			///subtitle("Monto reportado (billones `currency' `aniovp') y como % del PIB") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			yscale(range(0 `=`rango'[2,1]*1.5') axis(1) noline) ///
			yscale(range(-10 `=`rango'[2,2]*1.25') axis(2) noline) ///
			text(`=`shrfsp_pc'[24]' `=`ultanio'+1' "{bf:miles `currency' `aniovp'}" "{bf:por persona}", ///
				place(6) yaxis(2) size(medium) color("111 111 111")) ///
			text(`=`interno'[24]' `=`ultanio'+1' "{bf:billones}" "{bf:`currency' `aniovp'}", ///
				place(6) size(large) color("111 111 111")) ///
			///text(`=(`interno'[41]-`externo'[41])*.5+`externo'[41]' 2030 "Interno", ///
			///	place(0) size(large) color("111 111 111") justification(center)) ///
			///text(`=`externo'[41]*.5' 2030 "Externo", ///
			///	place(0) size(large) color("111 111 111") justification(center)) ///
			///text(`=`rango'[2,2]*1.15' `=2001+2.5' "{bf:Dif. `=anio[11]'-`=anio[17]':} `=string(`shrfsp_pc'[17]-`shrfsp_pc'[11],"%5.1f")' miles `currency' `aniovp'", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.15' `=2007+2.5' "{bf:Dif. `=anio[17]'-`=anio[23]':} `=string(`shrfsp_pc'[23]-`shrfsp_pc'[17],"%5.1f")' miles `currency' `aniovp'", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.15' `=2013+2.5' "{bf:Dif. `=anio[23]'-`=anio[29]':} `=string(`shrfsp_pc'[29]-`shrfsp_pc'[23],"%5.1f")' miles `currency' `aniovp'", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.15' `=2019+2.5' "{bf:Dif. `=anio[29]'-`=anio[35]':} `=string(`shrfsp_pc'[35]-`shrfsp_pc'[29],"%5.1f")' miles `currency' `aniovp'", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(`=`rango'[2,2]*1.15' `=2025+2.5' "{bf:Dif. `=anio[35]'-`=anio[41]':} `=string(`shrfsp_pc'[41]-`shrfsp_pc'[35],"%5.1f")' miles `currency' `aniovp'", ///
			///	place(0) size(large) color("111 111 111") justification(center) yaxis(2)) ///
			///text(0 `=2024+(2025-2024)/2' "{bf:$paqueteEconomico}", ///
			///	place(12) size(medsmall) color("111 111 111") justification(center) bcolor(white) box) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'. Las diferencias en puntos PIB se hacen con respecto al último año de la serie anterior.") ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			legend(off) ///
			name(shrfsppc, replace)

		graph save shrfsppc `"`c(sysdir_personal)'/SIM/graphs/shrfsppc.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsppc.png", replace name(shrfsppc)
		}
	}



	*************************
	***                   ***
	**# 6 TASAS EFECTIVAS ***
	***                   ***
	*************************
	g costodeudaTot = costodeudaExterno + costodeudaInterno
	g tasaInterno = costodeudaInterno/L.shrfspInterno*100
	g tasaExterno = costodeudaExterno/L.shrfspExterno*100
	g tasaEfectiva = porInterno*tasaInterno + porExterno*tasaExterno

	g depreciacion = tipoDeCambio-L.tipoDeCambio
	g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100

	format tasa* depreciacion Depreciacion %7.1fc

	tabstat costodeudaTot if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	tabstat pibY Poblacion_ajustada if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot2
	matrix `mattot2' = r(StatTotal)

	noisily di in g _dup(72) "="
	noisily di in g "  {bf:(*) Costo financiero" ///
		_col(33) in y %20.0fc `mattot'[1,1] ///
		_col(55) in y %7.1fc `mattot'[1,1]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"


	** 6.1 Gráfica tasas de interés **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		egen costodeudaTotg = rsum(costodeudaInterno costodeudaExterno)
		egen costodeudaOyEg = rsum(costopemex costocfe)
		replace costodeudaOyEg = costodeudaOyEg/1000000000000/deflator
		replace costodeudaTotg = costodeudaTotg/1000000000000/deflator
		format costodeudaTotg %5.1fc
		
		if `"$export"' == "" {
			local graphtitle "{bf:Costo de la deuda pública}"
			local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}		
		twoway (bar costodeudaTotg anio if anio > 2000 & anio <= 2024, ///
				yaxis(2) pstyle(p1) lwidth(none) barwidth(.75)) ///
			(bar costodeudaOyE anio if anio > 2000 & anio <= 2024, ///
				yaxis(2) pstyle(p1) lwidth(none) barwidth(.75) fintensity(50) lcolor(none)) ///
			(bar costodeudaTotg anio if anio > 2024 & anio <= 2030, ///
				yaxis(2) pstyle(p2) lwidth(none) barwidth(.75) fintensity(75)) ///
			(bar costodeudaOyE anio if anio > 2024 & anio <= 2030, ///
				yaxis(2) pstyle(p2) lwidth(none) barwidth(.75) fintensity(50) lcolor(none)) ///
			(connected tasaEfectiva anio if anio > 2000 & anio <= 2024, ///
				mlabel(tasaEfectiva) mlabposition(12) mlabcolor(black) pstyle(p1) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(connected tasaEfectiva anio if anio > 2024 & anio <= 2030, ///
				mlabel(tasaEfectiva) mlabposition(12) mlabcolor(black) pstyle(p2) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(scatter costodeudaTotg anio if anio > 2000 & anio <= 2030, ///
				yaxis(2) mlabel(costodeudaTotg) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(vlarge)) ///
			if tasaInterno != . & anio > `ultanio', ///
			title("`graphtitle'") ///
			text(`=costodeudaTotg[24]' `=`ultanio'+1' "{bf:billones}" "{bf:`currency' `aniovp'}", ///
				yaxis(2) place(6) size(large) color("111 111 111")) ///
			///text(`=(costodeudaTotg[41]-costodeudaOyEg[41])*.25+costodeudaOyEg[41]' 2030 "Gob. Fed.", ///
			///	yaxis(2) place(0) size(large) color("111 111 111") justification(center)) ///
			///text(`=costodeudaOyEg[41]*.5' 2030 "OyE", ///
			///	yaxis(2) place(0) size(large) color("111 111 111") justification(center)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			text(`=tasaEfectiva[24]' `=`ultanio'+1' "{bf:Interés}" "{bf:promedio (%)}", ///
				place(6) size(large) color("111 111 111")) ///
			yscale(range(-10) noline) ///
			yscale(range(0 1.75) axis(2) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			legend(off) ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) xtitle("") ///
			name(tasasdeinteres, replace) ///
			caption("`graphfuente'")
				
		graph save tasasdeinteres `"`c(sysdir_personal)'/SIM/graphs/tasasdeinteres.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/tasasdeinteres.png", replace name(tasasdeinteres)
		}
	}



	*********************************
	***                           ***
	**# 7 Efectos indicador deuda ***
	***                           ***
	*********************************
	*replace balprimario = balprimario + rfspOtros
	foreach k of varlist rfsp* shrfsp* balprimario costofinanciero tipoDeCambio nopresupuestario {
		g `k'_pib = `k'/pibY*100
		g `k'_pc = `k'/Poblacion_ajustada/deflator
		g `k'_real = `k'/deflator
		format `k'_pib `k'_pc %10.1fc
	}

	sort rfsp_pib
	scalar RFSPmaxPIB = rfsp_pib[1]
	scalar aniorfspmax = anio[1]
	scalar RFSPmax = rfsp[1]/deflator[1]
	scalar anioLP = `lastexo'
	sort anio

	replace balprimario_pib = -balprimario_pib - rfspOtros_pib

	g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	g dif_shrfsp_pib = D.shrfsp_pib
	g dif_shrfsp_pc = shrfsp_pc - L.shrfsp_pc
	format dif_* %10.1fc

	** 7.1 Efectos sobre el indicador **
	g efectoCrecimiento  = -var_pibY/100*L.shrfsp/pibY*100 - var_indiceY/100*L.shrfsp/pibY*100
	g efectoIntereses    = costofinanciero/pibY*100 + D.tipoDeCambio*L.shrfspExternoUSD/pibY*100
	
	g efectoTotal        = balprimario_pib + efectoCrecimiento + efectoIntereses
	g efectoOtros        = dif_shrfsp_pib - efectoTotal //+ rfspOtros_pib

	if "`nographs'" != "nographs" & "$nographs" == "" {
		local j = 100/(2023-`ultanio'+1)/2
		local i = 100/(`lastexo'-2023)/2

		** Gráfica por PIB **
		if `"$export"' == "" {
			local graphtitle "{bf:Efectos sobre el indicador de deuda pública}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		graph bar balprimario_pib efectoCrecimiento efectoIntereses efectoOtros if balprimario_pib != . & anio > `ultanio', ///
			over(anio) stack ///
			blabel(, format(%5.1fc)) outergap(0) ///
			text(`textDeuda1', color(red) size(small)) ///
			text(`textDeuda2', color(green) size(small)) ///
			ytitle("% PIB") ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			legend(on position(6) rows(1) label(3 "Tasas de inter{c e'}s") label(6 "Inflaci{c o'}n") label(2 "Crec. Econ{c o'}mico") ///
			label(1 "Déficit Primario") label(5 "No presupuestario") label(7 "No presupuestario") ///
			label(4 "Otros") region(margin(zero))) ///
			name(efectoDeuda, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'")
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
		}
	}



	********************/
	** 4.2 Deuda Pemex **
	/********************
		** Gráfica para Pemex **
		tempvar shrfspsinPemex shrfspPemex
		g `shrfspPemex' = deudaPemex/1000000000/deflator
		replace `shrfspPemex' = 0 if `shrfspPemex' == .
		g `shrfspsinPemex' = (shrfsp)/1000000000/deflator
		replace `shrfspsinPemex' = 0 if `shrfspsinPemex' == .

		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} de RFSP"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (bar `shrfspsinPemex' `shrfspPemex' anio if anio >= `ultanio' & anio < `anio') ///
			(bar `shrfspsinPemex' `shrfspPemex' anio if anio >= `anio') if `externo' != . & anio >= `ultanio' ///
			, title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`anio', noticks) ///	
			text(`textPemex' `textSPemex', color(white) size(small)) ///
			text(`text', placement(n) size(vsmall)) ///
			///text(2 `=`anio'+1.45' "{bf:Proyecci{c o'}n PE 2022}", color(white)) ///
			///text(2 `=2003+.45' "{bf:Externo}", color(white)) ///
			///text(`=2+`externosize2003'' `=2003+.45' "{bf:Interno}", color(white)) ///
			yscale(range(0) axis(1) noline) ///
			ytitle("mil millones `currency' `aniovp'") xtitle("") ///
			legend(on position(6) rows(1) order(1 2) ///
			label(1 `"Resto del SP"') ///
			label(2 `"Pemex"')) ///
			name(shrfspPemex, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfspPemex.png", replace name(shrfspPemex)
		}
	}


	**********************************/
	** EFECTOS SOBRE LOS INDICADORES **
	tempvar rfspBalance rfspOtros rfspBalance0 rfspOtros0 rfsppib rfsppc rfsp
	g `rfspOtros0' = (- rfspPIDIREGAS - rfspIPAB - rfspFONADIN - rfspDeudores - rfspBanca - rfspAdecuaciones)/1000000000000/deflator
	g `rfspOtros' = (- rfspPIDIREGAS - rfspIPAB - rfspFONADIN - rfspDeudores - rfspBanca  - rfspAdecuaciones)/1000000000000/deflator

	g `rfspBalance0' = - rfspBalance/1000000000000/deflator
	g `rfspBalance' = (- rfspBalance + `rfspOtros')/1000000000000/deflator if `rfspOtros' < 0
	replace `rfspBalance' = `rfspOtros' - rfspBalance/1000000000000/deflator if `rfspOtros' >= 0
	format `rfspBalance' `rfspOtros' `rfspBalance0' `rfspOtros0' %5.1f
	
	g `rfsppib' = -rfsp/pibY*100
	g rfsppc = -rfsp/(Poblacion_ajustada)/deflator
	g `rfsp' = -rfsp/1000000000000/deflator
	format `rfsp' %5.1fc
	format `rfsppib' %5.1fc

	* Informes mensuales texto *
	tabstat `rfsp' if anio == `anio' | anio == `anio'-1, by(anio) f(%20.0fc) stat(sum) c(v) save nototal
	tempname stathoy statayer rango
	matrix `stathoy' = r(Stat2)
	matrix `statayer' = r(Stat1)

	tabstat `rfsp' `rfsppib', f(%20.3fc) stat(min max mean) save
	matrix `rango' = r(StatTotal)

	scalar RFSPPromPIB = -`rango'[3,2]

	g efectoPositivoRFSP = 0
	foreach k of varlist `rfspBalance0' `rfspOtros0' {
			replace efectoPositivoRFSP = efectoPositivoRFSP + `k' if `k' > 0
	}

	if "`nographs'" != "nographs" & "$nographs" == "" {
		if "$export" == "" {
			local graphtitle "{bf:Requerimientos financieros del sector p{c u'}blico}"
		}
		else {
			local graphtitle ""
		}
		twoway (bar `rfsp' anio if anio < `anio', barwidth(.75)) ///
			(bar `rfspOtros' anio if anio < `anio', pstyle(p1) lwidth(none) fintensity(50) barwidth(.75)) ///
			(bar `rfsp' anio if anio >= `anio', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `rfspOtros' anio if anio >= `anio', pstyle(p2) lwidth(none) fintensity(50) barwidth(.75)) ///
			(connected `rfsppib' anio if anio < `anio', ///
				yaxis(2) mlabel(`rfsppib') mlabposition(12) mlabcolor(black) pstyle(p2) lpattern(dot) msize(small) mlabsize(vlarge)) ///
			(connected `rfsppib' anio if anio >= `anio', ///
				yaxis(2) mlabel(`rfsppib') mlabposition(12) mlabcolor(black) pstyle(p2) lpattern(dot) msize(small) mcolor(%50) mlabsize(vlarge)) ///
			(scatter `rfsp' anio, mlabel(`rfsp') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(vlarge)) ///
			if rfsp != . & anio > `ultanio', ///
			title("`graphtitle'") ///
			xtitle("") ///
			name(rfsp, replace) ///
			text(`=`rfsppib'[24]' 2013 "{bf:% PIB}", place(6) yaxis(2)) ///
			text(`=`rfsp'[24]' 2013 "{bf:billones}" "{bf:`currency' `aniovp'}", place(6)) ///
			///text(`=(`rfsp'[41]-`rfspOtros'[41])*.5+`rfspOtros'[41]' 2030 "Balance", place(0) size(large)) ///
			///text(`=`rfspOtros'[41]*.5' 2030 "Otros RFSP", place(0) size(large)) ///
			text(`=`rango'[3,2]' 2008 "{bf:Promedio:}" `"`=string(`rango'[3,2],"%5.1f")' % PIB"', place(5) yaxis(2)) ///
			ylabel(none, format(%15.0fc) labsize(small)) ///
			ylabel(none, format(%15.0fc) labsize(small) axis(2)) ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			yscale(range(0 `=`rango'[2,1]*2') axis(1) noline) ///
			yscale(range(0 `=-`rango'[2,1]*3') axis(2) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			yline(`=`rango'[3,2]', axis(2)) ///
			legend(off) ///
			caption("`graphfuente'")

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/rfsp.png", replace name(rfsp)
		}			
	}


	***********
	*** END ***
	***********
	if "`textbook'" == "textbook" {
		noisily scalarlatex, log(shrfsp) alt(shrfsp)
	}
	capture drop __*
	timer off 5
	timer list 5
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t5)/r(nt5)',.1) in g " segs."

}
end



program define UpdateSHRFSP
	**********************************
	***                            ***
	**#     1 SHRFSP (acervos)     ***
	***                            ***
	**********************************
	noisily DatosAbiertos SHRF5000, $nographs
	drop clave_de_concepto nombre 
	rename monto shrfsp
	tempfile shrfsp
	save "`shrfsp'"


	** Interno **
	noisily DatosAbiertos SHRF5100, $nographs
	rename monto shrfspInterno
	tempfile shrfspinterno
	save "`shrfspinterno'"


	** Externo **
	noisily DatosAbiertos SHRF5200, $nographs
	rename monto shrfspExterno
	tempfile shrfspexterno
	save "`shrfspexterno'"



	*******************************
	***                         ***
	***     2 RFSP (flujos)     ***
	***                         ***
	*******************************
	noisily DatosAbiertos RF000000SPFCS, $nographs reverse
	rename monto rfsp
	tempfile rfsp
	save "`rfsp'"


	** Endeudamiento presupuestario y no presupuestario **
	noisily DatosAbiertos RF000001SPFCS, $nographs reverse
	rename monto rfspBalance
	tempfile Balance
	save "`Balance'"


	** PIDIREGAS **
	noisily DatosAbiertos RF000002SPFCS, $nographs reverse
	rename monto rfspPIDIREGAS
	tempfile PIDIREGAS
	save "`PIDIREGAS'"


	** IPAB **
	noisily DatosAbiertos RF000003SPFCS, $nographs reverse
	rename monto rfspIPAB
	tempfile IPAB
	save "`IPAB'"


	** FONADIN **
	noisily DatosAbiertos RF000004SPFCS, $nographs reverse
	rename monto rfspFONADIN
	tempfile FONADIN
	save "`FONADIN'"


	** PROGRAMA DE DEUDORES **
	noisily DatosAbiertos RF000005SPFCS, $nographs reverse
	rename monto rfspDeudores
	tempfile Deudores
	save "`Deudores'"


	** BANCA DE DESARROLLO **
	noisily DatosAbiertos RF000006SPFCS, $nographs reverse
	rename monto rfspBanca
	tempfile Banca
	save "`Banca'"


	** ADECUACIONES PRESUPUESTARIAS **
	noisily DatosAbiertos RF000007SPFCS, $nographs reverse
	rename monto rfspAdecuaciones
	tempfile Adecuaciones
	save "`Adecuaciones'"





	************************************************
	***                                          ***
	***     3 Ajustes (RFSP vs. DIF. SHRFSP)     ***
	***                                          ***
	************************************************

	** Activos financieros internos del SP **
	noisily DatosAbiertos XED20, $nographs
	rename monto activosInt
	tempfile activosInt
	save "`activosInt'"


	** Activos financieros externos del SP **
	noisily DatosAbiertos XEB10, $nographs
	rename monto activosExt
	tempfile activosExt
	save "`activosExt'"


	** Diferimientos **
	noisily DatosAbiertos XOA0108, $nographs
	rename monto diferimientos
	tempfile diferimientos
	save "`diferimientos'"


	** Amortización **
	noisily DatosAbiertos IF03230, $nographs
	rename monto amortizacion
	tempfile amortizacion
	save "`amortizacion'"





	*************************************************
	***                                           ***
	***     4 Balance público (Endeudamiento)     ***
	***                                           ***
	*************************************************

	** Balance público **
	noisily di _newline(2) in g "{bf: Endeudamiento público} en millones de pesos"
	noisily DatosAbiertos XAA, $nographs reverse
	rename monto balancepublico
	tempfile balancepublico
	save "`balancepublico'"


	** Endeudamiento presupuestario **
	noisily DatosAbiertos XAA10, $nographs reverse
	rename monto presupuestario
	tempfile presupuestario
	save "`presupuestario'"


	** Endeudamiento no presupuestario **
	noisily DatosAbiertos XAA20, $nographs reverse
	rename monto nopresupuestario
	tempfile nopresupuestario
	save "`nopresupuestario'"



	****************************************
	* 4.1 Balance presupuestario (detalle) *

	** Gobierno Federal **
	noisily DatosAbiertos XAA11, $nographs
	rename monto gobiernofederal
	tempfile gobiernofederal
	save "`gobiernofederal'"


	** Pemex **
	noisily DatosAbiertos XAA1210, $nographs
	rename monto pemex
	tempfile pemex
	save "`pemex'"


	** CFE **
	noisily DatosAbiertos XOA0101, $nographs
	rename monto cfe
	tempfile cfe
	save "`cfe'"


	** IMSS **
	noisily DatosAbiertos XOA0105, $nographs
	rename monto imss
	tempfile imss
	save "`imss'"


	** ISSSTE **
	noisily DatosAbiertos XOA0106, $nographs
	rename monto issste
	tempfile issste
	save "`issste'"





	**********************************************
	***                                        ***
	***     5 Costo financiero de la deuda     ***
	***                                        ***
	**********************************************
	noisily di _newline(2) in g "{bf: Costo financiero de la deuda} en millones de pesos"
	noisily DatosAbiertos XAC21, $nographs
	rename monto costofinanciero
	tempfile costofinanciero
	save "`costofinanciero'"


	** Gobierno Federal **
	noisily DatosAbiertos XBC21, $nographs
	rename monto costogobiernofederal
	tempfile costogobiernofederal
	save "`costogobiernofederal'"


	** Pemex **
	noisily DatosAbiertos XOA0160, $nographs
	rename monto costopemex

	g deudaPemex = .
	replace deudaPemex = 2070542.31635290 if anio == 2022 	// a septiembre
	replace deudaPemex = 2173189.44800813 if anio == 2021
	replace deudaPemex = 2218737.53616582 if anio == 2020
	replace deudaPemex = 1922589.08819400 if anio == 2019
	replace deudaPemex = 2000374.02960390 if anio == 2018
	replace deudaPemex = 1940286.92629512 if anio == 2017
	replace deudaPemex = 1819638.21654995 if anio == 2016
	replace deudaPemex = 1384012.95509301 if anio == 2015
	replace deudaPemex = 1025261.97573126 if anio == 2014
	replace deudaPemex = 760494.694310920 if anio == 2013
	replace deudaPemex = 667623.708531536 if anio == 2012
	replace deudaPemex = 668178.069289112  if anio == 2011
	replace deudaPemex = 531138.3347399 if anio == 2010
	replace deudaPemex = 472098.44249911 if anio == 2009
	replace deudaPemex = 472486.10948318 if anio == 2008

	replace deudaPemex = deudaPemex*1000000
	format deudaPemex %20.0fc

	tempfile costopemex
	save "`costopemex'"


	** CFE **
	noisily DatosAbiertos XOA0162, $nographs
	rename monto costocfe
	tempfile costocfe
	save "`costocfe'"


	** Costo de la deuda interna **
	noisily DatosAbiertos XOA0155, $nographs
	rename monto costodeudaInterno
	tempfile costodeudaII
	save "`costodeudaII'"


	** Costo de la deuda externa **
	noisily DatosAbiertos XOA0156, $nographs
	rename monto costodeudaExterno
	tempfile costodeudaEE
	save "`costodeudaEE'"





	********************************
	***                          ***
	***     6 Tipo de cambio     ***
	***                          ***
	********************************

	* Deuda en pesos *
	noisily DatosAbiertos XET30, $nographs
	rename monto deudaMXN		
	tempfile MXN
	save "`MXN'"


	* Deuda en dólares *
	noisily DatosAbiertos XET40, $nographs
	rename monto deudaUSD
	tempfile USD
	save "`USD'"





	**********************/
	***                 ***
	***     7 Merge     ***
	***                 ***
	***********************

	* Acervos *
	use `shrfsp', clear
	merge 1:1 (anio) using "`shrfspinterno'", nogen
	merge 1:1 (anio) using "`shrfspexterno'", nogen


	* Flujos *
	merge 1:1 (anio) using "`rfsp'", nogen
	merge 1:1 (anio) using "`Balance'", nogen
	merge 1:1 (anio) using "`PIDIREGAS'", nogen
	merge 1:1 (anio) using "`IPAB'", nogen
	merge 1:1 (anio) using "`FONADIN'", nogen
	merge 1:1 (anio) using "`Deudores'", nogen
	merge 1:1 (anio) using "`Banca'", nogen
	merge 1:1 (anio) using "`Adecuaciones'", nogen


	* Adecuaciones *
	merge 1:1 (anio) using "`nopresupuestario'", nogen
	merge 1:1 (anio) using "`activosInt'", nogen
	merge 1:1 (anio) using "`activosExt'", nogen
	merge 1:1 (anio) using "`diferimientos'", nogen
	merge 1:1 (anio) using "`amortizacion'", nogen


	* Tipo de cambio *
	merge 1:1 (anio) using "`MXN'", nogen
	merge 1:1 (anio) using "`USD'", nogen


	* Costos financieros *
	merge 1:1 (anio) using "`costodeudaII'", nogen update
	merge 1:1 (anio) using "`costodeudaEE'", nogen update
	merge 1:1 (anio) using "`costopemex'", nogen update
	merge 1:1 (anio) using "`costocfe'", nogen update
	merge 1:1 (anio) using "`costofinanciero'", nogen update
	tsset anio


	* Tipo de cambio *
	g double tipoDeCambio = deudaMXN/deudaUSD
	format tipoDeCambio %7.2fc


	* Porcentaje interna y externa *
	g porInterno = shrfspInterno/shrfsp
	g porExterno = shrfspExterno/shrfsp


	* Balance primario *
	g balprimario = rfsp + costofinanciero
	format balprimario %20.0fc


	* Guardar *
	compress
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', replace
	}
end
