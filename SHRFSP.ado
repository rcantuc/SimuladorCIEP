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
	capture confirm file `"`c(sysdir_site)'/04_master/SHRFSP.dta"'
	if _rc != 0 {
		noisily UpdateSHRFSP
	}



	****************
	***          ***
	**# 2 SYNTAX ***
	***          ***
	****************
	use in 1 using `"`c(sysdir_site)'/04_master/SHRFSP.dta"', clear
	syntax [if] [, ANIO(int `aniovp' ) DEPreciacion(int 5) ///
		NOGraphs UPDATE Base ///
		ULTAnio(int 2001) TEXTbook]
	
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: DEUDA $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput `update'
	local currency = currency[1]
	g Poblacion_ajustada = Poblacion*lambda
	tempfile PIB
	save `PIB'

	** 2.2 Update SHRFSP **
	if "`update'" == "update" {
		noisily UpdateSHRFSP
	}

	** 2.3 Bases RAW **
	use `if' using `"`c(sysdir_site)'/04_master/SHRFSP.dta"', clear
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
	merge m:1 (anio) using `PIB', nogen keepus(pibY pibYR var_* Poblacion* deflator lambda currency) update replace
	sort anio mes
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
	local obslastexo = _N
	tsset anio

	* Política fiscal *
	forvalues j = 1(1)`=_N' {
		foreach k of varlist shrfsp* ///
			rfspBalance rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones ///
			balprimario ingresos egresos {
			capture confirm existence ${`k'`=anio[`j']'}
			if _rc == 0 {
				replace `k' = ${`k'`=anio[`j']'}/100*pibY if anio == `=anio[`j']'
				local lastexo = `=anio[`j']'
				local obslastexo = `j'
			}
		}
	}

	replace porInterno = shrfspInterno/shrfsp*100 if porInterno == .
	replace porExterno = shrfspExterno/shrfsp*100 if porExterno == .

	* Costos financieros y tipo de cambio *
	forvalues j = 1(1)`=_N' {
		capture confirm existence ${costodeuda`=anio[`j']'}
		if _rc == 0 {
			replace costofinanciero = ${costodeuda`=anio[`j']'}/100*pibY if anio == `=anio[`j']'
			format costofinanciero %20.0fc
		}

		capture confirm existence ${tipoDeCambio`=anio[`j']'}
		if _rc == 0 {
			replace tipoDeCambio = ${tipoDeCambio`=anio[`j']'} if anio == `=anio[`j']'
			format tipoDeCambio %7.2fc
		}

		replace rfsp = rfspBalance + rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones if anio == `=anio[`j']'
	}


	*****************
	***           ***
	**# 5 DISPLAY ***
	***           ***
	*****************
	noisily di _newline in g "{bf: " ///
		_col(33) in g %20s "`currency'" ///
		_col(55) %7s "% PIB" ///
		_col(66) %7s "% Tot" ///
		_col(76) %7s "Per cápita" ///
		"}"

	egen rfspOtros = rowtotal(rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones)

	g shrfspGobFed = shrfspGobFedInterno + shrfspGobFedExterno*tipoDeCambio
	g shrfspOyE = shrfspOyEInterno + shrfspOyEExterno*tipoDeCambio
	g shrfspBanca = shrfspBancaInterno + shrfspBancaExterno*tipoDeCambio

	g shrfspLP = shrfspLargoPlazoInterno + shrfspLargoPlazoExterno*tipoDeCambio
	g shrfspCP = shrfspCortoPlazoInterno + shrfspCortoPlazoExterno*tipoDeCambio

	g deudabruta = shrfspLP + shrfspCP

	tabstat rfspBalance rfspOtros rfsp shrfspInterno shrfspExterno shrfsp ///
		rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones ///
		shrfspGobFed shrfspOyE ///
		shrfspBanca shrfspLP shrfspCP deudabruta ///
		if anio == `anio', stat(sum) format(%20.0fc) save
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
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,1]/`mattot2'[1,2]
	noisily di in g "  (+) PIDIREGAS" ///
		_col(33) in y %20.0fc `mattot'[1,7] ///
		_col(55) in y %7.1fc `mattot'[1,7]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,7]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,7]/`mattot2'[1,2]
	noisily di in g "  (+) IPAB" ///
		_col(33) in y %20.0fc `mattot'[1,8] ///
		_col(55) in y %7.1fc `mattot'[1,8]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,8]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,8]/`mattot2'[1,2]
	noisily di in g "  (+) FONADIN" ///
		_col(33) in y %20.0fc `mattot'[1,9] ///
		_col(55) in y %7.1fc `mattot'[1,9]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,9]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,9]/`mattot2'[1,2]
	noisily di in g "  (+) Programa de Deudores" ///
		_col(33) in y %20.0fc `mattot'[1,10] ///
		_col(55) in y %7.1fc `mattot'[1,10]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,10]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,10]/`mattot2'[1,2]
	noisily di in g "  (+) Banca de Desarrollo" ///
		_col(33) in y %20.0fc `mattot'[1,11] ///
		_col(55) in y %7.1fc `mattot'[1,11]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,11]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,11]/`mattot2'[1,2]
	noisily di in g "  (+) Adecuaciones" ///
		_col(33) in y %20.0fc `mattot'[1,12] ///
		_col(55) in y %7.1fc `mattot'[1,12]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,12]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,12]/`mattot2'[1,2]
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) RFSP" ///
		_col(33) in y %20.0fc `mattot'[1,3] ///
		_col(55) in y %7.1fc `mattot'[1,3]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,3]/`mattot'[1,3]*100 ///
		_col(77) in y %9.1fc `mattot'[1,3]/`mattot2'[1,2] "}"
	noisily di in g _dup(85) "="
	noisily di in g "  (+) SHRFSP Interna" ///
		_col(33) in y %20.0fc `mattot'[1,4] ///
		_col(55) in y %7.1fc `mattot'[1,4]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,4]/`mattot'[1,6]*100 ///
		_col(77) in y %9.1fc `mattot'[1,4]/`mattot2'[1,2]
	noisily di in g "  (+) SHRFSP Externa" ///
		_col(33) in y %20.0fc `mattot'[1,5] ///
		_col(55) in y %7.1fc `mattot'[1,5]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,5]/`mattot'[1,6]*100 ///
		_col(77) in y %9.1fc `mattot'[1,5]/`mattot2'[1,2]
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) SHRFSP" ///
		_col(33) in y %20.0fc `mattot'[1,6] ///
		_col(55) in y %7.1fc `mattot'[1,6]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,6]/`mattot'[1,6]*100 ///
		_col(77) in y %9.1fc `mattot'[1,6]/`mattot2'[1,2] "}"
	noisily di in g _dup(85) "="
	noisily di in g "  (+) Deuda Gobierno federal" ///
		_col(33) in y %20.0fc `mattot'[1,13] ///
		_col(55) in y %7.1fc `mattot'[1,13]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,13]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,13]/`mattot2'[1,2]
	noisily di in g "  (+) Deuda OyE" ///
		_col(33) in y %20.0fc `mattot'[1,14] ///
		_col(55) in y %7.1fc `mattot'[1,14]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,14]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,14]/`mattot2'[1,2]
	noisily di in g "  (+) Deuda Banca de desarrollo" ///
		_col(33) in y %20.0fc `mattot'[1,15] ///
		_col(55) in y %7.1fc `mattot'[1,15]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,15]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,15]/`mattot2'[1,2]
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) Deuda bruta" ///
		_col(33) in y %20.0fc `mattot'[1,18] ///
		_col(55) in y %7.1fc `mattot'[1,18]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,18]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,18]/`mattot2'[1,2] "}"
	noisily di in g _dup(85) "="
	noisily di in g "  (+) Deuda corto plazo" ///
		_col(33) in y %20.0fc `mattot'[1,16] ///
		_col(55) in y %7.1fc `mattot'[1,16]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,16]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,16]/`mattot2'[1,2]
	noisily di in g "  (+) Deuda largo plazo" ///
		_col(33) in y %20.0fc `mattot'[1,17] ///
		_col(55) in y %7.1fc `mattot'[1,17]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,17]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,17]/`mattot2'[1,2]
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) Deuda bruta" ///
		_col(33) in y %20.0fc `mattot'[1,18] ///
		_col(55) in y %7.1fc `mattot'[1,18]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,18]/`mattot'[1,18]*100 ///
		_col(77) in y %9.1fc `mattot'[1,18]/`mattot2'[1,2] "}"

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

	g costodeudaTot = costofinanciero
	g tasaEfectiva = costodeudaTot/shrfsp*100

	g depreciacion = tipoDeCambio-L.tipoDeCambio
	g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100

	format tasa* depreciacion Depreciacion %7.1fc

	** 4.2.1 Gráfica generales **
	if "`nographs'" != "nographs" & "$nographs" == "" {

		** Como % del PIB **
		tempvar shrfsp_pib shrfsp_pc shrfsp_bill shrfsp_lif
		g `shrfsp_pib' = shrfsp/pibY*100
		format `shrfsp_pib' %7.1fc
		g `shrfsp_pc' = shrfsp/(Poblacion_ajustada)/deflator/1000
		format `shrfsp_pc' %7.0fc
		g `shrfsp_bill' = shrfsp/1000000000000/deflator
		format `shrfsp_bill' %7.1fc
		g `shrfsp_lif' = shrfsp/ingresos*100
		format `shrfsp_lif' %7.0fc

		tempvar rfsppib rfsp rfsppc
		g `rfsppib' = rfsp/pibY*100
		g `rfsppc' = rfsp/(Poblacion_ajustada)/deflator
		g `rfsp' = rfsp/1000000000000/deflator
		format `rfsp' %5.1fc
		format `rfsppib' %5.1fc

		tempvar rfspshrfsp lifpib
		g `rfspshrfsp' = rfsp/shrfsp*100
		format `rfspshrfsp' %5.1fc
		g `lifpib' = ingresos/pibY*100
		format `lifpib' %5.1fc

		tempvar pobmill
		g `pobmill' = Poblacion_ajustada/1000000
		format `pobmill' %7.0fc

		//if `"$textbook"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		//}
		//else {
		//	local graphtitle ""
		//	local graphfuente ""
		//}

		tabstat `shrfsp_pib' `rfspshrfsp' `rfsppib', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway  (bar `shrfsp_pib' anio if anio > 2000 & anio < `=`anio'-1', barwidth(.75)) ///
			(bar `shrfsp_pib' anio if anio >= `=`anio'-1' & anio <= 2031, barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar `rfsppib' anio if anio < `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `rfsppib' anio if anio >= `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected `rfspshrfsp' anio if anio > 2000 & anio < `=`anio'-1', ///
				yaxis(2) mlabel(`rfspshrfsp') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected `rfspshrfsp' anio if anio >= `=`anio'-1' & anio <= 2031, ///
				yaxis(2) mlabel(`rfspshrfsp') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(medium) fintensity(40)) ///
			(scatter `shrfsp_pib' anio if anio > 2000 & anio <= 2031, ///
				mlabel(`shrfsp_pib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall)) ///
			(scatter `rfsppib' anio if anio > 2000 & anio <= 2031, ///
				mlabel(`rfsppib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall) yaxis(3)) ///
			if `shrfsp_pib' != . & anio > `ultanio', ///
			title(`graphtitle') ///
			subtitle("% del PIB") ///
			note("{bf:Nota}: No se publican cifras de los RFSP previos al 2008.") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ytitle("", axis(3)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			ylabel(none, axis(3)) ///
			yscale(range(0 `=`rango'[2,1]*1.8') axis(1) noline) ///
			yscale(range(-20 `=`rango'[2,2]*1.15') axis(2) noline) ///
			yscale(range(0 `=`rango'[2,3]*2.5') axis(3) noline) ///
			xtitle("") ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			legend(on order(1 4) label(1 "SHRFSP (% PIB)") label(4 "RFSP (% PIB)")) ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`rango'[1,2]' `=`ultanio'+2' "{bf:% RFSP}" "{bf:entre SHRFSP}", ///
				yaxis(2) size(medium) place(0) justification(left) bcolor(white) box) ///
			name(shrfsp, replace)

		graph save shrfsp `"`c(sysdir_site)'/05_graphs/shrfsp.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}

		tabstat `shrfsp_bill' `shrfsp_pc' `pobmill', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway  (bar `shrfsp_bill' anio if anio > 2000 & anio < `=`anio'-1', barwidth(.75)) ///
			(bar `shrfsp_bill' anio if anio >= `=`anio'-1' & anio <= 2031, barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(40)) ///
			(bar `pobmill' anio if anio < `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `pobmill' anio if anio >= `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(40)) ///
			(connected `shrfsp_pc' anio if anio > 2000 & anio < `=`anio'-1', ///
				yaxis(2) mlabel(`shrfsp_pc') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected `shrfsp_pc' anio if anio >= `=`anio'-1' & anio <= 2031, ///
				yaxis(2) mlabel(`shrfsp_pc') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(medium) fintensity(40)) ///
			(scatter `shrfsp_bill' anio if anio > 2000 & anio <= 2031, ///
				mlabel(`shrfsp_bill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall)) ///
			(scatter `pobmill' anio if anio > 2000 & anio <= 2031, ///
				mlabel(`pobmill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall) yaxis(3)) ///
			if `shrfsp_bill' != . & anio > `ultanio', ///
			title(`graphtitle') ///
			subtitle("Per cápita") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ytitle("", axis(3)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			ylabel(none, axis(3)) ///
			yscale(range(0 `=`rango'[2,1]*1.5') axis(1) noline) ///
			yscale(range(-30 `=`rango'[2,2]*1.15') axis(2) noline) ///
			yscale(range(0 `=`rango'[2,3]*3.25') axis(3) noline) ///
			xtitle("") ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			legend(on order(1 4) label(1 "SHRFSP (billones `currency' `aniovp')") label(4 "Población (millones)")) ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`rango'[1,2]' `=`ultanio'+2' "{bf:miles `currency' `aniovp'}" "{bf:por persona}", ///
				yaxis(2) size(medium) place(6) justification(left) bcolor(white) box) ///
			name(shrfsppc, replace)

		graph save shrfsppc `"`c(sysdir_site)'/05_graphs/shrfsppc.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsppc.png", replace name(shrfsppc)
		}

		tabstat `shrfsp_pib' `shrfsp_lif' `lifpib', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway (bar `shrfsp_pib' anio if anio > 2000 & anio < `=`anio'-1', barwidth(.75)) ///
			(bar `shrfsp_pib' anio if anio >= `=`anio'-1' & anio <= 2031, barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar `lifpib' anio if anio < `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `lifpib' anio if anio >= `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected `shrfsp_lif' anio if anio > 2000 & anio < `=`anio'-1', ///
				yaxis(2) mlabel(`shrfsp_lif') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected `shrfsp_lif' anio if anio >= `=`anio'-1' & anio <= 2031, ///
				yaxis(2) mlabel(`shrfsp_lif') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(medium) fintensity(40)) ///
			(scatter `shrfsp_pib' anio if anio > 2000 & anio <= 2031, ///
				mlabel(`shrfsp_pib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall)) ///
			(scatter `lifpib' anio if anio > 2000 & anio <= 2031, ///
				mlabel(`lifpib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall) yaxis(3)) ///
			if `shrfsp_pib' != . & anio > `ultanio', ///
			title(`graphtitle') ///
			subtitle("% de la recaudación") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ytitle("", axis(3)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			ylabel(none, axis(3)) ///
			yscale(range(0 `=`rango'[2,1]*1.75') axis(1) noline) ///
			yscale(range(-60 `=`rango'[2,2]*1.15') axis(2) noline) ///
			yscale(range(0 `=`rango'[2,3]*3.5') axis(3) noline) ///
			xtitle("") ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			legend(on order(1 4) label(1 "SHRFSP (% PIB)") label(4 "Recaudación (% PIB)")) ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`rango'[1,2]' `=`ultanio'+2' "{bf:% SHRFSP}" "{bf:entre recaudación}", ///
				yaxis(2) size(medium) place(6) justification(left) bcolor(white) box) ///
			name(shrfsplif, replace)

		graph save shrfsplif `"`c(sysdir_site)'/05_graphs/shrfsplif.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsplif.png", replace name(shrfsplif)
		}
	}


	*************************
	***                   ***
	**# 6 TASAS EFECTIVAS ***
	***                   ***
	*************************

	tabstat costodeudaTot if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	tabstat pibY Poblacion_ajustada if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot2
	matrix `mattot2' = r(StatTotal)

	noisily di in g _dup(85) "="
	noisily di in g "  {bf:(*) Costo financiero" ///
		_col(33) in y %20.0fc `mattot'[1,1] ///
		_col(55) in y %7.1fc `mattot'[1,1]/`mattot2'[1,1]*100 ///
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 ///
		_col(77) in y %9.1fc `mattot'[1,1]/`mattot2'[1,2] "}"


	** 6.1 Gráfica tasas de interés **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		g costodeudaTotg = costofinanciero
		replace costodeudaTotg = costodeudaTotg/pibY*100
		format costodeudaTotg %5.1fc
		
		//if `"$textbook"' == "" {
			local graphtitle "{bf:Costo de la deuda pública}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		//}
		//else {
		//	local graphtitle ""
		//	local graphfuente ""
		//}

		tabstat `shrfsp_pib' costodeudaTotg tasaEfectiva, stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)
	
		twoway (bar `shrfsp_pib' anio if anio > 2000 & anio < `=`anio'-1', barwidth(.75)) ///
			(bar `shrfsp_pib' anio if anio >= `=`anio'-1' & anio <= 2031, barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(40)) ///
			(bar costodeudaTotg anio if anio < `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar costodeudaTotg anio if anio >= `=`anio'-1', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(40)) ///
			(connected tasaEfectiva anio if anio > 2000 & anio < `=`anio'-1', ///
				yaxis(2) mlabel(tasaEfectiva) mlabposition(12) mlabcolor(black) pstyle(p3) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected tasaEfectiva anio if anio >= `=`anio'-1' & anio <= 2031, ///
				yaxis(2) mlabel(tasaEfectiva) mlabposition(12) mlabcolor(black) pstyle(p3) lpattern(dot) msize(small) mlabsize(medium)) ///
			(scatter `shrfsp_pib' anio if anio > 2000 & anio <= 2031, ///
				yaxis(1) mlabel(`shrfsp_pib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall)) ///
			(scatter costodeudaTotg anio if anio > 2000 & anio <= 2031, ///
				yaxis(3) mlabel(costodeudaTotg) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(medsmall)) ///
			if tasaEfectiva != . & anio > `ultanio', ///
			title("`graphtitle'") ///
			subtitle("Tasa promedio") ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`rango'[2,2]' `=`ultanio'+.75' "{bf:Intereses promedio (%)}", ///
				place(5) size(medium) color("111 111 111") yaxis(2)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			ylabel(none, axis(3)) ///
			yscale(range(0 `=`rango'[2,1]*1.5') axis(1) noline) ///
			yscale(range(-20 `=`rango'[2,3]*1.15') axis(2) noline) ///
			yscale(range(0 `=`rango'[2,2]*2.5') axis(3) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ytitle("", axis(3)) ///
			legend(on order(1 4) label(1 "SHRFSP (% PIB)") label(4 "Costo financiero (% PIB)")) ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) xtitle("") ///
			name(tasasdeinteres, replace) ///
			caption("`graphfuente'")
				
		graph save tasasdeinteres `"`c(sysdir_site)'/05_graphs/tasasdeinteres.gph"', replace
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
		g `k'_real = `k'/deflator
		g `k'_pc = `k'_real/Poblacion_ajustada
		format `k'_pib `k'_pc %10.1fc
	}

	sort rfsp_pib
	scalar RFSPmaxPIB = rfsp_pib[1]
	scalar aniorfspmax = anio[1]
	scalar RFSPmax = rfsp[1]/deflator[1]
	scalar anioLP = `lastexo'
	sort anio

	*replace balprimario_pib = -balprimario_pib + rfspOtros_pib

	g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	g dif_shrfsp_pib = D.shrfsp_pib
	format dif_* %10.1fc

	// 1. Inflación e ingreso real
	gen crecimientoRealY = (pibYR / L.pibYR - 1) * 100

	// 2. Efecto crecimiento real sobre deuda
	gen efectoCrecimientoReal = - (var_pibY / 100 + (var_pibY/100*var_inflY/100)) * (L.shrfsp / pibY) * 100

	// 3. Efecto inflación sobre deuda
	gen efectoInflacion = - (var_indiceY / 100) * (L.shrfsp / pibY) * 100

	// 4. Efecto intereses internos
	gen efectoIntereses = (costofinanciero / pibY) * 100

	// 5. Efecto tipo de cambio
	gen efectoTipoCambio = (D.tipoDeCambio * L.shrfspExternoUSD / pibY) * 100

	// 6. Balance primario (ya como % del PIB)
	* asumimos que ya tienes `balprimario_pib`

	// 7. Total explicado
	gen efectoTotal = balprimario_pib + efectoCrecimientoReal + efectoInflacion + ///
			efectoIntereses + efectoTipoCambio

	// 8. Cambio observado en SHRFSP/PIB
	//gen dif_shrfsp_pib = (shrfsp / pibY - L.shrfsp / L.pibY) * 100

	// 9. Otros factores (ajustes contables, errores, etc.)
	gen efectoOtros = dif_shrfsp_pib - efectoTotal

	// 10. Efecto residual
	gen efectoResidual = efectoTotal + efectoOtros - dif_shrfsp_pib

	if "`nographs'" != "nographs" & "$nographs" == "" {
		local j = 100/(2023-`ultanio'+1)/2
		local i = 100/(`lastexo'-2023)/2

		** Gráfica por PIB **
		if `"$textbook"' == "" {
			local graphtitle "{bf:Efectos sobre el indicador de deuda pública}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		graph bar balprimario_pib efectoCrecimientoReal efectoIntereses efectoTipoCambio efectoInflacion efectoOtros if balprimario_pib != . & anio > `ultanio'*0+2008, ///
			over(anio) stack ///
			blabel(, format(%5.1fc) color(black) size(medsmall)) outergap(0) ///
			text(`textDeuda1', color(red) size(small)) ///
			text(`textDeuda2', color(green) size(small)) ///
			ytitle("% PIB") ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			legend(on position(6) rows(1) label(3 "Tasas de inter{c e'}s") ///
			label(6 "Inflaci{c o'}n") label(2 "Crec. Econ{c o'}mico") ///
			label(1 "Déficit Primario") label(5 "Inflación") label(6 "No presupuestario") ///
			label(4 "Tipo de cambio") region(margin(zero))) ///
			name(efectoDeuda, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'")
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
		}
	}



	**********/
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


	** Deuda bruta **
	** OyE Interno **
	noisily DatosAbiertos XED110, $nographs
	rename monto shrfspOyEInterno
	tempfile shrfspOyEInterno
	save "`shrfspOyEInterno'"

	** OyE Externo **
	noisily DatosAbiertos XEB4020, $nographs
	rename monto shrfspOyEExterno
	tempfile shrfspOyEExterno
	save "`shrfspOyEExterno'"

	** Gobierno Federal Intero **
	noisily DatosAbiertos XED80, $nographs
	rename monto shrfspGobFedInterno
	tempfile shrfspGobFedInterno
	save "`shrfspGobFedInterno'"

	** Gobierno Federal Externo **
	noisily DatosAbiertos XEB4010, $nographs
	rename monto shrfspGobFedExterno
	tempfile shrfspGobFedExterno
	save "`shrfspGobFedExterno'"

	** Banca de desarrollo Intero **
	noisily DatosAbiertos XED140, $nographs
	rename monto shrfspBancaInterno
	tempfile shrfspBancaInterno
	save "`shrfspBancaInterno'"

	** Banca de desarrollo Externo **
	noisily DatosAbiertos XEB4030, $nographs
	rename monto shrfspBancaExterno
	tempfile shrfspBancaExterno
	save "`shrfspBancaExterno'"

	** Largo plazo interno **
	noisily DatosAbiertos XED50, $nographs
	rename monto shrfspLargoPlazoInterno
	tempfile shrfspLargoPlazoInterno
	save "`shrfspLargoPlazoInterno'"

	** Corto plazo interno **
	noisily DatosAbiertos XED60, $nographs
	rename monto shrfspCortoPlazoInterno
	tempfile shrfspCortoPlazoInterno
	save "`shrfspCortoPlazoInterno'"

	** Largo plazo externo **
	noisily DatosAbiertos XEB3010, $nographs
	rename monto shrfspLargoPlazoExterno
	tempfile shrfspLargoPlazoExterno
	save "`shrfspLargoPlazoExterno'"

	** Corto plazo externo **
	noisily DatosAbiertos XEB3020, $nographs
	rename monto shrfspCortoPlazoExterno
	tempfile shrfspCortoPlazoExterno
	save "`shrfspCortoPlazoExterno'"



	*******************************
	***                         ***
	***     2 RFSP (flujos)     ***
	***                         ***
	*******************************
	noisily DatosAbiertos RF000000SPFCS, $nographs reverse desde(2009)
	rename monto rfsp
	tempfile rfsp
	save "`rfsp'"

	** Endeudamiento presupuestario y no presupuestario **
	noisily DatosAbiertos RF000001SPFCS, $nographs reverse desde(2009)
	rename monto rfspBalance
	tempfile Balance
	save "`Balance'"

	** PIDIREGAS **
	noisily DatosAbiertos RF000002SPFCS, $nographs reverse desde(2009)
	rename monto rfspPIDIREGAS
	tempfile PIDIREGAS
	save "`PIDIREGAS'"

	** IPAB **
	noisily DatosAbiertos RF000003SPFCS, $nographs reverse desde(2009)
	rename monto rfspIPAB
	tempfile IPAB
	save "`IPAB'"

	** FONADIN **
	noisily DatosAbiertos RF000004SPFCS, $nographs reverse desde(2009)
	rename monto rfspFONADIN
	tempfile FONADIN
	save "`FONADIN'"

	** PROGRAMA DE DEUDORES **
	noisily DatosAbiertos RF000005SPFCS, $nographs reverse desde(2009)
	rename monto rfspDeudores
	tempfile Deudores
	save "`Deudores'"

	** BANCA DE DESARROLLO **
	noisily DatosAbiertos RF000006SPFCS, $nographs reverse desde(2009)
	rename monto rfspBanca
	tempfile Banca
	save "`Banca'"

	** ADECUACIONES PRESUPUESTARIAS **
	noisily DatosAbiertos RF000007SPFCS, $nographs reverse desde(2009)
	rename monto rfspAdecuaciones
	tempfile Adecuaciones
	save "`Adecuaciones'"



	************************************************
	***                                          ***
	***     3 Ajustes (RFSP vs. DIF. SHRFSP)     ***
	***                                          ***
	************************************************

	** Activos financieros internos del SP **
	noisily DatosAbiertos XED20, $nographs desde(2009)
	rename monto activosInt
	tempfile activosInt
	save "`activosInt'"

	** Activos financieros externos del SP **
	noisily DatosAbiertos XEB10, $nographs desde(2009)
	rename monto activosExt
	tempfile activosExt
	save "`activosExt'"

	** Diferimientos **
	noisily DatosAbiertos XOA0108, $nographs desde(2009)
	rename monto diferimientos
	tempfile diferimientos
	save "`diferimientos'"

	** Amortización **
	noisily DatosAbiertos IF03230, $nographs desde(2009)
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
	
	noisily DatosAbiertos XAB, $nographs
	rename monto ingresos
	tempfile ingresos
	save "`ingresos'"
	
	noisily DatosAbiertos XAC, $nographs
	rename monto egresos
	tempfile egresos
	save "`egresos'"


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
	noisily DatosAbiertos XAC21, $nographs desde(2009)
	rename monto costofinanciero
	tempfile costofinanciero
	save "`costofinanciero'"

	** Gobierno Federal **
	noisily DatosAbiertos XBC21, $nographs desde(2009)
	rename monto costogobiernofederal
	tempfile costogobiernofederal
	save "`costogobiernofederal'"

	** Pemex **
	noisily DatosAbiertos XOA0160, $nographs
	rename monto costopemex
	tempfile costopemex
	save "`costopemex'"

	** CFE **
	noisily DatosAbiertos XOA0162, $nographs
	rename monto costocfe
	tempfile costocfe
	save "`costocfe'"

	** Costo de la deuda interna **
	noisily DatosAbiertos XOA0155, $nographs desde(2009)
	rename monto costodeudaInterno
	tempfile costodeudaII
	save "`costodeudaII'"

	** Costo de la deuda externa **
	noisily DatosAbiertos XOA0156, $nographs desde(2009)
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
	merge 1:1 (anio) using "`shrfspOyEInterno'", nogen
	merge 1:1 (anio) using "`shrfspOyEExterno'", nogen
	merge 1:1 (anio) using "`shrfspGobFedInterno'", nogen
	merge 1:1 (anio) using "`shrfspGobFedExterno'", nogen
	merge 1:1 (anio) using "`shrfspBancaInterno'", nogen
	merge 1:1 (anio) using "`shrfspBancaExterno'", nogen
	merge 1:1 (anio) using "`shrfspLargoPlazoInterno'", nogen
	merge 1:1 (anio) using "`shrfspCortoPlazoInterno'", nogen
	merge 1:1 (anio) using "`shrfspLargoPlazoExterno'", nogen
	merge 1:1 (anio) using "`shrfspCortoPlazoExterno'", nogen

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
	merge 1:1 (anio) using "`balancepublico'", nogen
	merge 1:1 (anio) using "`ingresos'", nogen
	merge 1:1 (anio) using "`egresos'", nogen
	merge 1:1 (anio) using "`presupuestario'", nogen
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
	g balprimario = rfsp - costofinanciero
	format balprimario %20.0fc

	* Guardar *
	compress
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_site)'/04_master/SHRFSP.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_site)'/04_master/SHRFSP.dta"', replace
	}
end
