program define SHRFSP, return
quietly {

	timer on 5
	**********************
	**# 1 BASE DE DATOS **
	**********************

	** 1.1 Anio valor presente **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}	
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	** 1.2 Base SHRFSP **
	capture confirm file `"`c(sysdir_personal)'/SIM/SHRFSP.dta"'
	if _rc != 0 {
		noisily UpdateSHRFSP
	}



	****************
	**# 2 SYNTAX ***
	****************
	use in 1 using `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', clear
	syntax [if] [, ANIO(int `aniovp' ) DEPreciacion(int 5) NOGraphs UPDATE Base ///
		 ULTAnio(int 2001)]
	
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: DEUDA $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput `update'
	local currency = currency[1]
	g Poblacion_adj = Poblacion*lambda
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



	***************
	**# 3 MERGE ***
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
	}
	local lastexo = anio[`obsvp']
	local obsfin = _N



	*****************************
	***                       ***
	**# 5 PARÁMETROS EXÓGENOS ***
	***                       ***
	*****************************
	tsset anio
	forvalues j = 1(1)`=_N' {
		* Política fiscal *
		foreach k of varlist shrfspInterno shrfspExterno ///
			rfsp rfspBalance rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones ///
			balprimario {
			capture confirm scalar `k'`=anio[`j']'
			if _rc == 0 {
				replace `k' = scalar(`k'`=anio[`j']')/100*pibY if anio == `=anio[`j']'
				local lastexo = `=anio[`j']'
			}
		}
		
		* Costos financieros *
		replace porInterno = shrfspInterno/(shrfspInterno+shrfspExterno) if porInterno == .
		replace porExterno = shrfspExterno/(shrfspInterno+shrfspExterno) if porExterno == .
		capture confirm scalar costodeudaInterno`=anio[`j']'
		if _rc == 0 {
			replace costodeudaInterno = scalar(costodeudaInterno`=anio[`j']')/100*porInterno*pibY if anio == `=anio[`j']'
		}		
		capture confirm scalar costodeudaExterno`=anio[`j']'
		if _rc == 0 {
			replace costodeudaExterno = scalar(costodeudaExterno`=anio[`j']')/100*porExterno*pibY if anio == `=anio[`j']'
		}
		format costodeuda* %20.0fc
		
		* Tipo de cambio *
		capture confirm scalar tipoDeCambio`=anio[`j']'
		if _rc == 0 {
			replace tipoDeCambio = scalar(tipoDeCambio`=anio[`j']') if anio == `=anio[`j']'
		}

		replace shrfsp = shrfspInterno + shrfspExterno if anio == `=anio[`j']'
	}



	*****************
	**# 4 DISPLAY ***
	*****************
	noisily di _newline in g "{bf: " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "Per cápita" "}"

	tempvar rfspOtros
	egen `rfspOtros' = rowtotal(rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones)
	tabstat rfspBalance `rfspOtros' rfsp shrfspInterno shrfspExterno shrfsp if anio == `anio', stat(sum) format(%20.0fc) save
	if _rc != 0 {
		noisily di in r "No hay informaci{c o'}n para el a{c n~}o `anio'"
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)

	tabstat pibY Poblacion_adj if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot2
	matrix `mattot2' = r(StatTotal)

	noisily di in g "  {bf:(+) Balance presupuestario" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,1]/`mattot2'[1,2] "}"
	noisily di in g "  {bf:(+) Otros RFSP" ///
		_col(44) in y %20.0fc `mattot'[1,2] ///
		_col(66) in y %7.1fc `mattot'[1,2]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,2]/`mattot2'[1,2] "}"
	noisily di in g _dup(83) "-"
	noisily di in g "  {bf:(=) RFSP" ///
		_col(44) in y %20.0fc `mattot'[1,3] ///
		_col(66) in y %7.1fc `mattot'[1,3]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,3]/`mattot2'[1,2] "}"
	noisily di in g _dup(83) "="
	noisily di in g "  {bf:(+) SHRFSP Interna" ///
		_col(44) in y %20.0fc `mattot'[1,4] ///
		_col(66) in y %7.1fc `mattot'[1,4]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,4]/`mattot2'[1,2] "}"
	noisily di in g "  {bf:(+) SHRFSP Externa" ///
		_col(44) in y %20.0fc `mattot'[1,5] ///
		_col(66) in y %7.1fc `mattot'[1,5]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,5]/`mattot2'[1,2] "}"
	noisily di in g _dup(83) "-"
	noisily di in g "  {bf:(=) SHRFSP" ///
		_col(44) in y %20.0fc `mattot'[1,6] ///
		_col(66) in y %7.1fc `mattot'[1,6]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,6]/`mattot2'[1,2] "}"

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

		** % del PIB **
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

		twoway (bar `interno' anio if mes == 12, ///
				mlabel(`interno_label') mlabsize(small) mlabposition(6) mlabangle(0) mlabcolor("114 113 118") barwidth(.75)) ///
			(bar `externo' anio if mes == 12, ///
				mlabel(`externo') mlabsize(small) mlabposition(6) mlabangle(0) mlabcolor("114 113 118") barwidth(.75)) ///
			(bar `interno' anio if mes != 12, ///
				mlabel(`interno_label') mlabsize(small) mlabpositio(6) mlabangle(0) mlabcolor("114 113 118") pstyle(p1) barwidth(.75) fintensity(50) lcolor(%7)) ///
			(bar `externo' anio if mes != 12, ///
				mlabel(`externo') mlabsize(small) mlabpositio(6) mlabangle(0) mlabcolor("114 113 118") pstyle(p2) barwidth(.75) fintensity(50) lcolor(%7)) ///
			(connected `shrfsp_pib' anio if mes == 12, ///
				yaxis(2) mlabel(`shrfsp_pib') mlabposition(12) mlabcolor("114 113 118") pstyle(p3) mlabsize(small)) ///
			(connected `shrfsp_pib' anio if mes != 12, ///
				yaxis(2) mlabel(`shrfsp_pib') mlabposition(12) mlabcolor("114 113 118") pstyle(p3) mlabsize(small) lpattern(dot) msize(small)) ///
			if `externo' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			///subtitle("Monto reportado (billones `currency' `aniovp') y como % del PIB") ///
			caption("`graphfuente'") ///
			ylabel(none, format(%15.0fc) labsize(small)) ///
			ylabel(none, format(%10.0fc) labsize(small) axis(2)) ///
			yscale(range(0 `=`rango'[2,1]*1.5') axis(1) noline) ///
			yscale(range(0 `=`rango'[1,2]-(`rango'[2,2]-`rango'[1,2])') axis(2) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			legend(on position(6) rows(1) order(1 2 5) ///
			label(1 `"Interno (billones `currency' `=anio[`obsvp']')"') ///
			label(2 `"Externo (billones `currency' `=anio[`obsvp']')"') ///
			label(5 `"Saldo (% del PIB)"') ///
			region(margin(zero))) ///
			name(shrfsp, replace)

		graph save shrfsp `"`c(sysdir_personal)'/SIM/graphs/shrfsp.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}

		** Por persona **
		tempvar shrfsp_pc
		g `shrfsp_pc' = shrfsp/Poblacion_adj/deflator/1000
		format `shrfsp_pc' %10.0fc

		tabstat `interno' `shrfsp_pc', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway (bar `interno' anio if mes == 12, ///
				mlabel(`interno_label') mlabsize(small) mlabposition(6) mlabangle(0) mlabcolor("114 113 118") barwidth(.75)) ///
			(bar `externo' anio if mes == 12, ///
				mlabel(`externo') mlabsize(small) mlabposition(6) mlabangle(0) mlabcolor("114 113 118") barwidth(.75)) ///
			(bar `interno' anio if mes != 12, ///
				mlabel(`interno_label') mlabsize(small) mlabpositio(6) mlabangle(0) mlabcolor("114 113 118") pstyle(p1) barwidth(.75) fintensity(50) lcolor(%7)) ///
			(bar `externo' anio if mes != 12, ///
				mlabel(`externo') mlabsize(small) mlabposition(6) mlabangle(0) mlabcolor("114 113 118") pstyle(p2) barwidth(.75) fintensity(50) lcolor(%7)) ///
			(connected `shrfsp_pc' anio if mes == 12, ///
				yaxis(2) mlabel(`shrfsp_pc') mlabposition(12) mlabcolor("114 113 118") pstyle(p3) mlabsize(small)) ///
			(connected `shrfsp_pc' anio if mes != 12, ///
				yaxis(2) mlabel(`shrfsp_pc') mlabposition(12) mlabcolor("114 113 118") pstyle(p3) mlabsize(small) lpattern(dot) msize(small)) ///
			if `externo' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			///subtitle("Monto reportado (billones `currency' `aniovp') y por persona (miles `currency' `aniovp')") ///
			caption("`graphfuente'") ///
			ylabel(none, format(%15.0fc) labsize(small)) ///
			ylabel(none, format(%10.0fc) labsize(small) axis(2)) ///
			yscale(range(0 `=`rango'[2,1]*1.5') axis(1) noline) ///
			yscale(range(0 `=`rango'[1,2]-(`rango'[2,2]-`rango'[1,2])') axis(2) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			legend(on position(6) rows(1) order(1 2 5) ///
			label(1 `"Interno (billones `currency' `=anio[`obsvp']')"') ///
			label(2 `"Externo (billones `currency' `=anio[`obsvp']')"') ///
			label(5 `"Saldo (miles `currency' `=anio[`obsvp']' por persona)"') ///
			region(margin(zero))) ///
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

	tabstat pibY Poblacion_adj if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot2
	matrix `mattot2' = r(StatTotal)

	noisily di in g _dup(83) "="
	noisily di in g "  {bf:(*) Costo financiero" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,1]/`mattot2'[1,2] "}"


	** 6.1 Gráfica tasas de interés **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar costodeudaTot costodeudaPIB costodeudaPC
		egen `costodeudaTot' = rsum(costodeudaInterno costodeudaExterno)
		replace `costodeudaTot' = `costodeudaTot'/1000000000000		
		g `costodeudaPC' = `costodeudaTot'/Poblacion_adj/deflator
		g `costodeudaPIB' = `costodeudaTot'/pibY*100
		format `costodeudaTot' %5.1fc

		twoway (bar `costodeudaTot' anio if mes == 12, ///
				yaxis(2) mlabel(`costodeudaTot') mlabsize(small) mlabposition(6) mlabcolor("114 113 118") pstyle(p1) lwidth(none) barwidth(.75)) ///
			(bar `costodeudaTot' anio if mes != 12, ///
				yaxis(2) mlabel(`costodeudaTot') mlabsize(small) mlabposition(6) mlabcolor("114 113 118") pstyle(p1) lwidth(none) barwidth(.75) fintensity(50) lcolor(%7)) ///
			(connected tasaEfectiva anio if mes == 12, ///
				mlabel(tasaEfectiva) mlabsize(vsmall) mlabposition(12) mlabcolor("114 113 118") pstyle(p3)) ///
			(connected tasaEfectiva anio if mes != 12, ///
				mlabel(tasaEfectiva) msize(small) mlabsize(vsmall) mlabposition(12) mlabcolor("114 113 118") pstyle(p3) lpattern(dot)) ///
			if tasaInterno != . & anio >= `ultanio', ///
			title("{bf:Costo de la deuda pública}") ///
			///subtitle("Costo financiero (billones `currency' `aniovp') y tasa de interés efectiva (costo/saldo*100)") /**/ ///
			ylabel(none, format(%15.0fc) labsize(small)) ///
			ylabel(none, format(%15.0fc) labsize(small) axis(2)) ///
			yscale(range(0) noline) ///
			yscale(range(0 3) axis(2) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			legend(position(6) rows(1) order(1 3) region(margin(zero)) ///
			label(1 "Costo financiero (billones `currency' `aniovp')") ///
			label(3 "Tasa de inter{c e'}s efectiva (costo/saldo*100)")) ///
			xlabel(`ultanio'(1)`lastexo') xtitle("") ///
			name(tasasdeinteres, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			caption("`graphfuente'")
	}


	*********************************
	***                           ***
	**# 7 Efectos indicador deuda ***
	***                           ***
	*********************************
	foreach k of varlist shrfsp* balprimario `rfspOtros' {
		g `k'_pib = `k'/pibY*100
		g `k'_pc = `k'/Poblacion_adj/deflator
		format `k'_pib `k'_pc %10.1fc
	}

	g dif_shrfsp_pib = D.shrfsp_pib
	g dif_shrfsp_pc = D.shrfsp_pc
	format dif_* %10.1fc


	** 7.1 Efectos sobre el indicador **
	*g efectoActivos      = -(D.activosInt+D.activosExt*tipoDeCambio*1000-amortizacion)/pibY*100
	g efectoCrecimiento  = -(var_pibY/100)*L.shrfsp/pibY*100
	g efectoInflacion    = -(var_indiceY/100+var_indiceY/100*var_pibY/100)*L.shrfsp/pibY*100 
	g efectoIntereses    = ((tasaInterno/100)*L.shrfspInterno + (tasaExterno/100)*L.shrfspExterno)/pibY*100
	g efectoTipoDeCambio = (Depreciacion/100 + tasaExterno/100*Depreciacion/100)*L.shrfspExterno/pibY*100
	g efectoTotal = balprimario_pib + `rfspOtros'_pib + efectoCrecimiento + efectoInflacion + efectoIntereses + efectoTipoDeCambio
	g efectoOtros        = dif_shrfsp_pib - efectoTotal

	g efectoCrecimiento_pc  = -((Poblacion_adj-L.Poblacion_adj)/L.Poblacion_adj)*L.shrfsp/Poblacion_adj/deflator
	g efectoInflacion_pc= -(var_indiceY/100+var_indiceY/100*((Poblacion_adj-L.Poblacion_adj)/L.Poblacion_adj))*L.shrfsp/Poblacion_adj/deflator
	g efectoIntereses_pc    = (tasaInterno/100)*L.shrfspInterno/Poblacion_adj/deflator + (tasaExterno/100)*L.shrfspExterno/Poblacion_adj/deflator
	g efectoTipoDeCambio_pc = (Depreciacion/100 + tasaExterno/100*Depreciacion/100)*L.shrfspExterno/Poblacion_adj/deflator
	g efectoTotal_pc = balprimario_pc + `rfspOtros'_pc + efectoCrecimiento_pc + efectoInflacion_pc + efectoIntereses_pc + efectoTipoDeCambio_pc
	g efectoOtros_pc        = dif_shrfsp_pc - efectoTotal_pc

	g efectoPositivo = 0
	g efectoPositivo_pc = 0
	g efectoNegativo = 0
	g efectoNegativo_pc = 0
	foreach k of varlist balprimario_pib `rfspOtros'_pib efectoCrecimiento efectoInflacion ///
		efectoIntereses efectoTipoDeCambio efectoOtros {
			replace efectoPositivo = efectoPositivo + `k' if `k' > 0
			replace efectoNegativo = efectoNegativo + `k' if `k' < 0
	}
	foreach k of varlist balprimario_pc `rfspOtros'_pc efectoCrecimiento_pc efectoInflacion_pc ///
		efectoIntereses_pc efectoTipoDeCambio_pc efectoOtros_pc {
			replace efectoPositivo_pc = efectoPositivo_pc + `k' if `k' > 0
			replace efectoNegativo_pc = efectoNegativo_pc + `k' if `k' < 0
	}


		/** Texto **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		local j = 100/(2023-`ultanio'+1)/2
		local i = 100/(`lastexo'-2023)/2
		forvalues k=1(1)`=_N' {
			if abs(efectoPositivo[`k']) > abs(efectoNegativo[`k']) & mes[`k'] == 12 & anio[`k'] >= `ultanio' & efectoPositivo[`k'] != . & efectoNegativo[`k'] != . {
				local textDeuda1 `"`textDeuda1' `=efectoPositivo[`k']+.5' `j' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda11 `"`textDeuda11' `=efectoPositivo_pc[`k']+750' `j' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local j = `j' + 100/(2023-`ultanio'+1)
			}
			if abs(efectoNegativo[`k']) >= abs(efectoPositivo[`k']) & mes[`k'] == 12 & anio[`k'] >= `ultanio' & efectoNegativo[`k'] != . & efectoPositivo[`k'] != . {
				local textDeuda2 `"`textDeuda2' `=efectoNegativo[`k']-.5' `j' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda22 `"`textDeuda22' `=efectoNegativo_pc[`k']-750' `j' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local j = `j' + 100/(2023-`ultanio'+1)
			}

			if abs(efectoPositivo[`k']) > abs(efectoNegativo[`k']) & mes[`k'] != 12 & anio[`k'] >= `ultanio' & anio[`k'] <= `lastexo' & efectoPositivo[`k'] != . & efectoNegativo[`k'] != . {
				local textDeuda3 `"`textDeuda3' `=efectoPositivo[`k']+.5' `i' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda33 `"`textDeuda33' `=efectoPositivo_pc[`k']+750' `i' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local i = `i' + 100/(`lastexo'-2023)
			}
			if abs(efectoNegativo[`k']) >= abs(efectoPositivo[`k']) & mes[`k'] != 12 & anio[`k'] >= `ultanio' & anio[`k'] <= `lastexo' & efectoNegativo[`k'] != . & efectoPositivo[`k'] != . {
				local textDeuda4 `"`textDeuda4' `=efectoNegativo[`k']-.5' `i' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda44 `"`textDeuda44' `=efectoNegativo_pc[`k']-750' `i' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local i = `i' + 100/(`lastexo'-2023)
			}
		}

		** Gráfica por PIB **
		if `"$export"' == "" {
			local graphtitle "{bf:La deuda como % del PIB}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		graph bar balprimario_pib `rfspOtros'_pib efectoCrecimiento efectoInflacion efectoIntereses efectoTipoDeCambio efectoOtros if balprimario_pib != ., ///
			over(anio, gap(0)) stack ///
			blabel(, format(%5.1fc)) outergap(0) ///
			text(`textDeuda1', color(red) size(small)) ///
			text(`textDeuda2', color(green) size(small)) ///
			ytitle("% PIB") ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			name(efectoDeuda, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			title({it:Observado})
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
		}


		** Gráfica por persona ajustada **	
		if `"$export"' == "" {
			local graphtitle "{bf:Efectos sobre el indicador de la deuda per cápita}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		graph bar balprimario_pc `rfspOtros'_pc efectoCrecimiento_pc efectoInflacion_pc efectoIntereses_pc efectoTipoDeCambio_pc efectoOtros_pc if balprimario_pc != ., ///
			over(anio, gap(0)) stack ///
			blabel(, format(%10.0fc)) outergap(0) ///
			text(`textDeuda11', color(red) size(small)) ///
			text(`textDeuda22', color(green) size(small)) ///
			ytitle("`currency' `aniovp'") ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Demogr{c a'}fico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			name(efectoDeudaPC, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			title(Observado)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeudaPC.png", replace name(efectoDeudaPC)
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
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar rfspBalance rfspAdecuacion rfspOtros rfspBalance0 rfspAdecuacion0 rfspOtros0 rfsppib rfsppc rfsp
		g `rfspOtros0' = (- rfspPIDIREGAS - rfspIPAB - rfspFONADIN - rfspDeudores - rfspBanca)/1000000000000/deflator
		g `rfspAdecuacion0' = - rfspAdecuacion/1000000000000/deflator
		g `rfspBalance0' = - rfspBalance/1000000000000/deflator

		g `rfspOtros' = (- rfspPIDIREGAS - rfspIPAB - rfspFONADIN - rfspDeudores - rfspBanca)/1000000000000/deflator
		g `rfspAdecuacion' = (`rfspOtros' - rfspAdecuacion)/1000000000000/deflator if rfspAdecuacion <= 0
		replace `rfspAdecuacion' = - rfspAdecuacion/1000000000000/deflator if rfspAdecuacion > 0
		replace `rfspAdecuacion' = 0 if `rfspAdecuacion' == .

		g `rfspBalance' = `rfspAdecuacion' - rfspBalance/1000000000000/deflator if rfspAdecuacion <= 0 & `rfspOtros' >= 0
		replace `rfspBalance' = rfspBalance/1000000000000/deflator if rfspAdecuacion > 0 & `rfspOtros' < 0
		replace `rfspBalance' = `rfspOtros' - rfspBalance/1000000000000/deflator if rfspAdecuacion > 0 & `rfspOtros' >= 0
		replace `rfspBalance' = `rfspAdecuacion' - `rfspOtros' - rfspBalance/1000000000000/deflator if rfspAdecuacion <= 0 & `rfspOtros' < 0

		format `rfspBalance' `rfspAdecuacion' `rfspOtros' `rfspBalance0' `rfspAdecuacion0' `rfspOtros0' %5.1f
		
		g `rfsppib' = -rfsp/pibY*100
		g rfsppc = -rfsp/(Poblacion_adj)/deflator
		g `rfsp' = -rfsp/1000000000000/deflator
		format `rfsp' %10.0fc
		format `rfsppib' %5.1fc

		* Informes mensuales texto *
		tabstat `rfsp' if anio == `anio' | anio == `anio'-1, by(anio) f(%20.0fc) stat(sum) c(v) save nototal
		tempname stathoy statayer rango
		matrix `stathoy' = r(Stat2)
		matrix `statayer' = r(Stat1)


		tabstat `rfsp', by(anio) f(%20.0fc) stat(min max) save
		matrix `rango' = r(StatTotal)

		g efectoPositivoRFSP = 0
		foreach k of varlist `rfspBalance0' `rfspAdecuacion0' `rfspOtros0' {
				replace efectoPositivoRFSP = efectoPositivoRFSP + `k' if `k' > 0
		}
		if "$export" == "" {
			local graphtitle "{bf:Requerimientos financieros del sector p{c u'}blico}"
		}
		else {
			local graphtitle ""
		}
		twoway (bar `rfspBalance' anio if mes == 12, mlabel(`rfspBalance0') mlabposition(12) mlabcolor("114 113 118") barwidth(.75)) ///
			(bar `rfspAdecuacion' anio if mes == 12, barwidth(.75)) ///
			(bar `rfspOtros' anio if mes == 12, barwidth(.75)) ///
			(bar `rfspBalance' anio if mes != 12, mlabel(`rfspBalance0') mlabposition(12) mlabcolor("114 113 118") pstyle(p1) lwidth(none) barwidth(.1)) ///
			(bar `rfspAdecuacion' anio if mes != 12, pstyle(p2) lwidth(none) barwidth(.1)) ///
			(bar `rfspOtros' anio if mes != 12, pstyle(p3) lwidth(none) barwidth(.1)) ///
			(connected `rfsppib' anio if mes == 12, ///
				yaxis(2) mlabel(`rfsppib') mlabsize(vsmall) mlabposition(12) mlabcolor("114 113 118") pstyle(p4)) ///
			(connected `rfsppib' anio if mes != 12, ///
				yaxis(2) mlabel(`rfsppib') mlabsize(vsmall) mlabposition(12) mlabcolor("114 113 118") lpattern(dot) msize(small) pstyle(p4)) ///
			if rfsp != . & anio >= `ultanio', ///
			title("`graphtitle'") ///
			subtitle("Monto reportado (billones `currency' `aniovp') y como % del PIB") ///
			xtitle("") ///
			name(rfsp, replace) ///
			ylabel(none, format(%15.0fc) labsize(small)) ///
			ylabel(none, format(%15.0fc) labsize(small) axis(2)) ///
			xlabel(2008(1)`lastexo', noticks) ///	
			yscale(range(0 `=`rango'[2,1]*1.75') axis(1) noline) ///
			yscale(range(0 `=`rango'[1,1]-2.75*(`=`rango'[2,1]'-`=`rango'[1,1]')') axis(2) noline) ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			legend(on rows(1) label(3 "Otros ajustes") label(2 "Adecuaciones a registros") label(1 "Déficit público") ///
			region(margin(zero)) order(1 2 3)) ///
			caption("`graphfuente'")

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/rfsp.png", replace name(rfsp)
		}			
	}


	***********
	*** END ***
	***********
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


	** Endeudamiento presupuestario **
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


	noisily DatosAbiertos XOA0155, $nographs			// costo deuda interna
	rename monto costodeudaInterno
	tempfile costodeudaII
	save "`costodeudaII'"

	noisily DatosAbiertos XOA0156, $nographs			// costo deuda externa
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
	merge 1:1 (anio) using "`costopemex'", nogen
	tsset anio


	* Tipo de cambio *
	g double tipoDeCambio = deudaMXN/deudaUSD
	format tipoDeCambio %7.2fc


	* Porcentaje interna y externa *
	g porInterno = shrfspInterno/shrfsp
	g porExterno = shrfspExterno/shrfsp


	* Balance primario *
	g balprimario = -rfspBala - costodeudaInt - costodeudaExt
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
