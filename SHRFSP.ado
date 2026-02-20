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

	g shrfsp_lif = shrfsp/ingresos*100
	format shrfsp_lif %7.0fc

	** Escalares Balance presupuestario **
	scalar rfspBalanceMonto = string(rfspBalance[`obsvp']/1000000, "%20.1fc")
	scalar rfspBalancePIB = string(rfspBalance[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspBalancePorTot = string(rfspBalance[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspBalancePC = string(rfspBalance[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares PIDIREGAS **
	scalar rfspPIDIREGASMonto = string(rfspPIDIREGAS[`obsvp']/1000000, "%20.1fc")
	scalar rfspPIDIREGASPIB = string(rfspPIDIREGAS[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspPIDIREGASPorTot = string(rfspPIDIREGAS[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspPIDIREGASPC = string(rfspPIDIREGAS[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares IPAB **
	scalar rfspIPABMonto = string(rfspIPAB[`obsvp']/1000000, "%20.1fc")
	scalar rfspIPABPIB = string(rfspIPAB[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspIPABPorTot = string(rfspIPAB[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspIPABPC = string(rfspIPAB[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares FONADIN **
	scalar rfspFONADINMonto = string(rfspFONADIN[`obsvp']/1000000, "%20.1fc")
	scalar rfspFONADINPIB = string(rfspFONADIN[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspFONADINPorTot = string(rfspFONADIN[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspFONADINPC = string(rfspFONADIN[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Programa de Deudores **
	scalar rfspDeudoresMonto = string(rfspDeudores[`obsvp']/1000000, "%20.1fc")
	scalar rfspDeudoresPIB = string(rfspDeudores[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspDeudoresPorTot = string(rfspDeudores[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspDeudoresPC = string(rfspDeudores[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Banca de Desarrollo **
	scalar rfspBancaMonto = string(rfspBanca[`obsvp']/1000000, "%20.1fc")
	scalar rfspBancaPIB = string(rfspBanca[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspBancaPorTot = string(rfspBanca[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspBancaPC = string(rfspBanca[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Adecuaciones **
	scalar rfspAdecuacionesMonto = string(rfspAdecuaciones[`obsvp']/1000000, "%20.1fc")
	scalar rfspAdecuacionesPIB = string(rfspAdecuaciones[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar rfspAdecuacionesPorTot = string(rfspAdecuaciones[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar rfspAdecuacionesPC = string(rfspAdecuaciones[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares RFSP **
	scalar RFSPMonto = string(rfsp[`obsvp']/1000000, "%20.1fc")
	scalar RFSPPIB = string(rfsp[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar RFSPPorTot = string(rfsp[`obsvp']/rfsp[`obsvp']*100, "%7.1fc")
	scalar RFSPPC = string(rfsp[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares SHRFSP Interna **
	scalar SHRFSPInternoMonto = string(shrfspInterno[`obsvp']/1000000, "%20.1fc")
	scalar SHRFSPInternoPIB = string(shrfspInterno[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar SHRFSPInternoPorTot = string(shrfspInterno[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar SHRFSPInternoPC = string(shrfspInterno[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares SHRFSP Externa **
	scalar SHRFSPExternoMonto = string(shrfspExterno[`obsvp']/1000000, "%20.1fc")
	scalar SHRFSPExternoPIB = string(shrfspExterno[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar SHRFSPExternoPorTot = string(shrfspExterno[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar SHRFSPExternoPC = string(shrfspExterno[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares SHRFSP **
	scalar SHRFSPMonto = string(shrfsp[`obsvp']/1000000, "%20.1fc")
	scalar SHRFSPPIB = string(shrfsp[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar SHRFSPPorTot = string(shrfsp[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar SHRFSPPC = string(shrfsp[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")
	scalar SHRFSPLIF = string(shrfsp_lif[`obsvp'], "%7.0fc")
	

	** Escalares Deuda Gobierno federal **
	scalar DeudaGobFedMonto = string(shrfspGobFed[`obsvp']/1000000, "%20.1fc")
	scalar DeudaGobFedPIB = string(shrfspGobFed[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar DeudaGobFedPorTot = string(shrfspGobFed[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar DeudaGobFedPC = string(shrfspGobFed[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Deuda OyE **
	scalar DeudaOyEMonto = string(shrfspOyE[`obsvp']/1000000, "%20.1fc")
	scalar DeudaOyEPIB = string(shrfspOyE[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar DeudaOyEPorTot = string(shrfspOyE[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar DeudaOyEPC = string(shrfspOyE[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Deuda Banca de desarrollo **
	scalar DeudaBancaMonto = string(shrfspBanca[`obsvp']/1000000, "%20.1fc")
	scalar DeudaBancaPIB = string(shrfspBanca[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar DeudaBancaPorTot = string(shrfspBanca[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar DeudaBancaPC = string(shrfspBanca[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Deuda bruta **
	scalar DeudaBrutaMonto = string(deudabruta[`obsvp']/1000000, "%20.1fc")
	scalar DeudaBrutaPIB = string(deudabruta[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar DeudaBrutaPorTot = string(deudabruta[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar DeudaBrutaPC = string(deudabruta[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Deuda corto plazo **
	scalar DeudaCPMonto = string(shrfspCP[`obsvp']/1000000, "%20.1fc")
	scalar DeudaCPPIB = string(shrfspCP[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar DeudaCPPorTot = string(shrfspCP[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar DeudaCPPC = string(shrfspCP[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	** Escalares Deuda largo plazo **
	scalar DeudaLPMonto = string(shrfspLP[`obsvp']/1000000, "%20.1fc")
	scalar DeudaLPPIB = string(shrfspLP[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar DeudaLPPorTot = string(shrfspLP[`obsvp']/shrfsp[`obsvp']*100, "%7.1fc")
	scalar DeudaLPPC = string(shrfspLP[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	noisily di in g "  (+) Balance presupuestario" ///
		_col(33) in y %20s rfspBalanceMonto ///
		_col(55) in y %7s rfspBalancePIB ///
		_col(66) in y %7s rfspBalancePorTot ///
		_col(77) in y %9s rfspBalancePC
	noisily di in g "  (+) PIDIREGAS" ///
		_col(33) in y %20s rfspPIDIREGASMonto ///
		_col(55) in y %7s rfspPIDIREGASPIB ///
		_col(66) in y %7s rfspPIDIREGASPorTot ///
		_col(77) in y %9s rfspPIDIREGASPC
	noisily di in g "  (+) IPAB" ///
		_col(33) in y %20s rfspIPABMonto ///
		_col(55) in y %7s rfspIPABPIB ///
		_col(66) in y %7s rfspIPABPorTot ///
		_col(77) in y %9s rfspIPABPC
	noisily di in g "  (+) FONADIN" ///
		_col(33) in y %20s rfspFONADINMonto ///
		_col(55) in y %7s rfspFONADINPIB ///
		_col(66) in y %7s rfspFONADINPorTot ///
		_col(77) in y %9s rfspFONADINPC
	noisily di in g "  (+) Programa de Deudores" ///
		_col(33) in y %20s rfspDeudoresMonto ///
		_col(55) in y %7s rfspDeudoresPIB ///
		_col(66) in y %7s rfspDeudoresPorTot ///
		_col(77) in y %9s rfspDeudoresPC
	noisily di in g "  (+) Banca de Desarrollo" ///
		_col(33) in y %20s rfspBancaMonto ///
		_col(55) in y %7s rfspBancaPIB ///
		_col(66) in y %7s rfspBancaPorTot ///
		_col(77) in y %9s rfspBancaPC
	noisily di in g "  (+) Adecuaciones" ///
		_col(33) in y %20s rfspAdecuacionesMonto ///
		_col(55) in y %7s rfspAdecuacionesPIB ///
		_col(66) in y %7s rfspAdecuacionesPorTot ///
		_col(77) in y %9s rfspAdecuacionesPC
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) RFSP" ///
		_col(33) in y %20s RFSPMonto ///
		_col(55) in y %7s RFSPPIB ///
		_col(66) in y %7s RFSPPorTot ///
		_col(77) in y %9s RFSPPC "}"
	noisily di in g _dup(85) "="
	noisily di in g "  (+) SHRFSP Interna" ///
		_col(33) in y %20s SHRFSPInternoMonto ///
		_col(55) in y %7s SHRFSPInternoPIB ///
		_col(66) in y %7s SHRFSPInternoPorTot ///
		_col(77) in y %9s SHRFSPInternoPC
	noisily di in g "  (+) SHRFSP Externa" ///
		_col(33) in y %20s SHRFSPExternoMonto ///
		_col(55) in y %7s SHRFSPExternoPIB ///
		_col(66) in y %7s SHRFSPExternoPorTot ///
		_col(77) in y %9s SHRFSPExternoPC
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) SHRFSP" ///
		_col(33) in y %20s SHRFSPMonto ///
		_col(55) in y %7s SHRFSPPIB ///
		_col(66) in y %7s SHRFSPPorTot ///
		_col(77) in y %9s SHRFSPPC "}"
	noisily di in g _dup(85) "="
	noisily di in g "  (+) Deuda Gobierno federal" ///
		_col(33) in y %20s DeudaGobFedMonto ///
		_col(55) in y %7s DeudaGobFedPIB ///
		_col(66) in y %7s DeudaGobFedPorTot ///
		_col(77) in y %9s DeudaGobFedPC
	noisily di in g "  (+) Deuda OyE" ///
		_col(33) in y %20s DeudaOyEMonto ///
		_col(55) in y %7s DeudaOyEPIB ///
		_col(66) in y %7s DeudaOyEPorTot ///
		_col(77) in y %9s DeudaOyEPC
	noisily di in g "  (+) Deuda Banca de desarrollo" ///
		_col(33) in y %20s DeudaBancaMonto ///
		_col(55) in y %7s DeudaBancaPIB ///
		_col(66) in y %7s DeudaBancaPorTot ///
		_col(77) in y %9s DeudaBancaPC
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) Deuda bruta" ///
		_col(33) in y %20s DeudaBrutaMonto ///
		_col(55) in y %7s DeudaBrutaPIB ///
		_col(66) in y %7s DeudaBrutaPorTot ///
		_col(77) in y %9s DeudaBrutaPC "}"
	noisily di in g _dup(85) "="
	noisily di in g "  (+) Deuda corto plazo" ///
		_col(33) in y %20s DeudaCPMonto ///
		_col(55) in y %7s DeudaCPPIB ///
		_col(66) in y %7s DeudaCPPorTot ///
		_col(77) in y %9s DeudaCPPC
	noisily di in g "  (+) Deuda largo plazo" ///
		_col(33) in y %20s DeudaLPMonto ///
		_col(55) in y %7s DeudaLPPIB ///
		_col(66) in y %7s DeudaLPPorTot ///
		_col(77) in y %9s DeudaLPPC
	noisily di in g _dup(85) "-"
	noisily di in g "  {bf:(=) Deuda bruta" ///
		_col(33) in y %20s DeudaBrutaMonto ///
		_col(55) in y %7s DeudaBrutaPIB ///
		_col(66) in y %7s DeudaBrutaPorTot ///
		_col(77) in y %9s DeudaBrutaPC "}"

	g costodeudaTot = costofinanciero
	g tasaEfectiva = costodeudaTot/shrfsp*100

	g depreciacion = tipoDeCambio-L.tipoDeCambio
	g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100

	format tasa* depreciacion Depreciacion %7.1fc

	** Generar variables definitivas _pib, _real, _pc **
	foreach k of varlist rfsp* shrfsp* balprimario costofinanciero tipoDeCambio nopresupuestario {
		g `k'_pib = `k'/pibY*100
		g `k'_real = `k'/deflator
		g `k'_pc = `k'_real/Poblacion_ajustada
		format `k'_pib `k'_pc %10.1fc
	}

	** 4.2.1 Gráfica generales **
	if "`nographs'" != "nographs" & "$nographs" == "" {

		** Variables adicionales para gráficas **
		tempvar shrfsp_pc_miles
		g `shrfsp_pc_miles' = shrfsp_pc/1000
		format `shrfsp_pc_miles' %7.0fc

		tempvar shrfsp_bill
		g `shrfsp_bill' = shrfsp_real/1000000000000
		format `shrfsp_bill' %7.1fc

		tempvar rfsp_bill
		g `rfsp_bill' = rfsp_real/1000000000000
		format `rfsp_bill' %5.1fc

		tempvar rfspshrfsp
		g `rfspshrfsp' = (1+tasaEfectiva/100)/((1+var_indiceY/100)*(1+var_pibY/100))
		format `rfspshrfsp' %5.2fc

		tempvar lifpib
		g `lifpib' = ingresos/pibY*100
		format `lifpib' %5.1fc

		tempvar pobmill
		g `pobmill' = Poblacion_ajustada/1000000
		format `pobmill' %7.0fc

		tempvar costo_bill
		g `costo_bill' = costofinanciero_real/1000000000000
		format `costo_bill' %5.1fc

		if `"$textbook"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		tempvar pibY_bill
		g `pibY_bill' = pibY/1000000000000/deflator
		format `pibY_bill' %7.1fc

		tabstat `pibY_bill' shrfsp_pib `shrfsp_bill', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de shrfsp_pib en los 5 años centrales **
		local anioCentral = (`ultanio' + 1 + `lastexo') / 2
		local anioIniCentral = floor(`anioCentral' - 2)
		local anioFinCentral = floor(`anioCentral' + 2)
		summarize shrfsp_pib if anio >= `anioIniCentral' & anio <= `anioFinCentral' & shrfsp_pib != .
		local minval = r(min)
		summarize anio if round(shrfsp_pib,0.001) == round(`minval',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio = r(mean)

		twoway  (bar `pibY_bill' anio if anio > 2000 & anio <= `aniofin', barwidth(.75)) ///
			(bar `pibY_bill' anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar `shrfsp_bill' anio if anio <= `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `shrfsp_bill' anio if anio > `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected shrfsp_pib anio if anio > 2000 & anio <= `aniofin', ///
				yaxis(2) mlabel(shrfsp_pib) mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			(connected shrfsp_pib anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(shrfsp_pib) mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter `pibY_bill' anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(`pibY_bill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter `shrfsp_bill' anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(`shrfsp_bill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small) yaxis(3)) ///
			if shrfsp_pib != . & anio > `ultanio', ///
			title(`graphtitle') ///
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
			legend(on order(1 4) label(1 "PIB (billones `currency' `aniovp')") label(4 "SHRFSP (billones `currency' `aniovp')")) ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`minval'-1' `=`minanio'' "{bf:SHRFSP % PIB}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
			name(shrfsp, replace)

		graph save shrfsp `"`c(sysdir_site)'/05_graphs/shrfsp.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}

		tabstat `shrfsp_bill' `shrfsp_pc_miles' `pobmill', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de shrfsp_pc en los 5 años centrales **
		summarize `shrfsp_pc_miles' if anio >= `anioIniCentral' & anio <= `anioFinCentral' & `shrfsp_pc_miles' != .
		local minval2 = r(min)
		summarize anio if round(`shrfsp_pc_miles',0.001) == round(`minval2',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio2 = r(mean)

		twoway  (bar `shrfsp_bill' anio if anio > 2000 & anio <= `aniofin', barwidth(.75)) ///
			(bar `shrfsp_bill' anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(40)) ///
			(bar `pobmill' anio if anio <= `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `pobmill' anio if anio > `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(40)) ///
			(connected `shrfsp_pc_miles' anio if anio > 2000 & anio <= `aniofin', ///
				yaxis(2) mlabel(`shrfsp_pc_miles') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			(connected `shrfsp_pc_miles' anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(`shrfsp_pc_miles') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter `shrfsp_bill' anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(`shrfsp_bill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter `pobmill' anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(`pobmill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small) yaxis(3)) ///
			if `shrfsp_bill' != . & anio > `ultanio', ///
			title(`graphtitle') ///
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
			text(`=`minval2'-5' `=`minanio2'' "{bf:miles `currency' `aniovp' por persona}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
			name(shrfsppc, replace)

		graph save shrfsppc `"`c(sysdir_site)'/05_graphs/shrfsppc.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsppc.png", replace name(shrfsppc)
		}

		tabstat shrfsp_pib shrfsp_lif `lifpib', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de shrfsp_lif en los 5 años centrales **
		summarize shrfsp_lif if anio >= `anioIniCentral' & anio <= `anioFinCentral' & shrfsp_lif != .
		local minval3 = r(min)
		summarize anio if round(shrfsp_lif,0.001) == round(`minval3',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio3 = r(mean)

		twoway (bar shrfsp_pib anio if anio > 2000 & anio <= `aniofin', barwidth(.75)) ///
			(bar shrfsp_pib anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar `lifpib' anio if anio <= `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `lifpib' anio if anio > `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected shrfsp_lif anio if anio > 2000 & anio <= `aniofin', ///
				yaxis(2) mlabel(shrfsp_lif) mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			(connected shrfsp_lif anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(shrfsp_lif) mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter shrfsp_pib anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(shrfsp_pib) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter `lifpib' anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(`lifpib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small) yaxis(3)) ///
			if shrfsp_pib != . & anio > `ultanio', ///
			title(`graphtitle') ///
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
			text(`=`minval3'-5' `=`minanio3'' "{bf:% SHRFSP entre recaudación}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
			name(shrfsplif, replace)

		graph save shrfsplif `"`c(sysdir_site)'/05_graphs/shrfsplif.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsplif.png", replace name(shrfsplif)
		}

		** Gráfica de deuda interna y externa **
		tempvar porcentajeExterno
		g `porcentajeExterno' = shrfspExterno/(shrfspInterno+shrfspExterno)*100
		format `porcentajeExterno' %5.1fc

		tabstat shrfspInterno_pib shrfspExterno_pib `porcentajeExterno', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de porcentajeExterno en los 5 años centrales **
		summarize `porcentajeExterno' if anio >= `anioIniCentral' & anio <= `anioFinCentral' & `porcentajeExterno' != .
		local minval4 = r(min)
		summarize anio if round(`porcentajeExterno',0.001) == round(`minval4',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio4 = r(mean)

		twoway (bar shrfspInterno_pib anio if anio > 2000 & anio <= `aniofin', barwidth(.75)) ///
			(bar shrfspInterno_pib anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar shrfspExterno_pib anio if anio <= `aniofin', barwidth(.75) yaxis(1) ///
				pstyle(p2) lwidth(none)) ///
			(bar shrfspExterno_pib anio if anio > `aniofin', barwidth(.75) yaxis(1) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected `porcentajeExterno' anio if anio > 2000 & anio <= `aniofin', ///
				yaxis(2) mlabel(`porcentajeExterno') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			(connected `porcentajeExterno' anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(`porcentajeExterno') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter shrfspInterno_pib anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(shrfspInterno_pib) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter shrfspExterno_pib anio if anio > 2000 & anio <= `lastexo', ///
				mlabel(shrfspExterno_pib) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			if shrfsp_pib != . & anio > `ultanio', ///
			title(`graphtitle') ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			yscale(range(0 `=`rango'[2,1]*1.75') axis(1) noline) ///
			yscale(range(-40 `=`rango'[2,3]*1.15') axis(2) noline) ///
			xtitle("") ///
			xlabel(`=`ultanio'+1'(1)`lastexo', noticks) ///	
			legend(on order(1 3) label(1 "SHRFSP Interna (% PIB)") label(3 "SHRFSP Externa (% PIB)")) ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`minval4'-1' `=`minanio4'' "{bf:% Externa del total}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
			name(shrfspIntExt, replace)

		graph save shrfspIntExt `"`c(sysdir_site)'/05_graphs/shrfspIntExt.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfspIntExt.png", replace name(shrfspIntExt)
		}

		** Gráfica SHRFSP y PIB (billones) con RFSP y costo de deuda (% PIB) **
		capture drop costodeudaTotg
		g costodeudaTotg = costofinanciero/pibY*100
		format costodeudaTotg %5.1fc

		tabstat `pibY_bill' `shrfsp_bill' rfsp_pib costodeudaTotg, stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de rfsp_pib en los 5 años centrales **
		summarize rfsp_pib if anio >= `anioIniCentral' & anio <= `anioFinCentral' & rfsp_pib != .
		local minval8 = r(min)
		summarize anio if round(rfsp_pib,0.001) == round(`minval8',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio8 = r(mean)

		twoway ///
			(bar shrfsp_pib anio if anio > 2007 & anio <= `aniofin', barwidth(.75) ///
				yaxis(1) pstyle(p2) lwidth(none)) ///
			(bar shrfsp_pib anio if anio > `aniofin', barwidth(.75) ///
				yaxis(1) pstyle(p2) lwidth(none) fintensity(50)) ///
			(bar rfsp_pib anio if anio > 2007 & anio <= `aniofin', barwidth(.5) ///
				yaxis(2) pstyle(p3) lwidth(none)) ///
			(bar rfsp_pib anio if anio > `aniofin', barwidth(.5) ///
				yaxis(2) pstyle(p3) lwidth(none) fintensity(50)) ///
			(bar costodeudaTotg anio if anio > 2007 & anio <= `aniofin', barwidth(.35) ///
				yaxis(2) pstyle(p4) lwidth(none)) ///
			(bar costodeudaTotg anio if anio > `aniofin', barwidth(.35) ///
				yaxis(2) pstyle(p4) lwidth(none) fintensity(50)) ///
			(scatter shrfsp_pib anio if anio > 2007 & anio <= `lastexo', ///
				yaxis(1) mlabel(shrfsp_pib) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter rfsp_pib anio if anio > 2007 & anio <= `lastexo', ///
				yaxis(2) mlabel(rfsp_pib) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter costodeudaTotg anio if anio > 2007 & anio <= `lastexo', ///
				yaxis(2) mlabel(costodeudaTotg) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			if shrfsp_pib != . & anio > `ultanio', ///
			///title(`graphtitle') ///
			///caption("`graphfuente'") ///
			ytitle("% PIB") ///
			ytitle("", axis(2)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			yscale(range(0) axis(1) noline) ///
			yscale(range(0 8) axis(2) noline) ///
			xtitle("") ///
			xlabel(2008(1)`lastexo', noticks) ///
			legend(on order(1 4 7) ///
				label(1 "SHRFSP") ///
				label(4 "RFSP") ///
				label(7 "Costo financiero")) ///
			name(shrfspResumen, replace)

		graph save shrfspResumen `"`c(sysdir_site)'/05_graphs/shrfspResumen.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfspResumen.png", replace name(shrfspResumen)
		}
	}


	*************************
	***                   ***
	**# 6 TASAS EFECTIVAS ***
	***                   ***
	*************************

	** Escalares Costo financiero **
	scalar CostoFinancieroMonto = string(costodeudaTot[`obsvp']/1000000, "%20.1fc")
	scalar CostoFinancieroPIB = string(costodeudaTot[`obsvp']/pibY[`obsvp']*100, "%7.1fc")
	scalar CostoFinancieroPorTot = string(costodeudaTot[`obsvp']/costodeudaTot[`obsvp']*100, "%7.1fc")
	scalar CostoFinancieroPC = string(costodeudaTot[`obsvp']/Poblacion_ajustada[`obsvp'], "%10.0fc")

	noisily di in g _dup(85) "="
	noisily di in g "  {bf:(*) Costo financiero" ///
		_col(33) in y %20s CostoFinancieroMonto ///
		_col(55) in y %7s CostoFinancieroPIB ///
		_col(66) in y %7s CostoFinancieroPorTot ///
		_col(77) in y %9s CostoFinancieroPC "}"


	** 6.1 Gráfica tasas de interés **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		capture drop costodeudaTotg
		g costodeudaTotg = costofinanciero/pibY*100
		format costodeudaTotg %5.1fc
		
		if `"$textbook"' == "" {
			local graphtitle "{bf:Costo de la deuda pública}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		tabstat shrfsp_pib costodeudaTotg tasaEfectiva, stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de tasaEfectiva en los 5 años centrales **
		summarize tasaEfectiva if anio >= `anioIniCentral' & anio <= `anioFinCentral' & tasaEfectiva != .
		local minval5 = r(min)
		summarize anio if round(tasaEfectiva,0.001) == round(`minval5',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio5 = r(mean)
	
		twoway (bar shrfsp_pib anio if anio > 2000 & anio <= `aniofin', barwidth(.75)) ///
			(bar shrfsp_pib anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(40)) ///
			(bar costodeudaTotg anio if anio <= `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar costodeudaTotg anio if anio > `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(40)) ///
			(connected tasaEfectiva anio if anio > 2000 & anio <= `aniofin', ///
				yaxis(2) mlabel(tasaEfectiva) mlabposition(12) mlabcolor(black) pstyle(p3) lpattern(dot) msize(small) mlabsize(small)) ///
			(connected tasaEfectiva anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(tasaEfectiva) mlabposition(12) mlabcolor(black) pstyle(p3) lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter shrfsp_pib anio if anio > 2000 & anio <= `lastexo', ///
				yaxis(1) mlabel(shrfsp_pib) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter costodeudaTotg anio if anio > 2000 & anio <= `lastexo', ///
				yaxis(3) mlabel(costodeudaTotg) mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			if tasaEfectiva != . & anio > `ultanio', ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			text(0 `=`ultanio'+2' "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`minval5'-.5' `=`minanio5'' "{bf:Intereses promedio (%)}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
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
			name(tasasdeinteres, replace)
				
		graph save tasasdeinteres `"`c(sysdir_site)'/05_graphs/tasasdeinteres.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/tasasdeinteres.png", replace name(tasasdeinteres)
		}

		** Gráfica de RFSP vs PIB **
		tempvar pibY_bill_rfsp
		g `pibY_bill_rfsp' = pibY/1000000000000/deflator
		format `pibY_bill_rfsp' %7.1fc

		tabstat `pibY_bill_rfsp' rfsp_pib `rfsp_bill', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de rfsppib en los 5 años centrales **
		summarize rfsp_pib if anio >= `anioIniCentral' & anio <= `anioFinCentral' & rfsp_pib != .
		local minval6 = r(min)
		summarize anio if round(rfsp_pib,0.001) == round(`minval6',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio6 = r(mean)

		if "$export" == "" {
			local graphtitle "{bf:RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (bar `pibY_bill_rfsp' anio if anio > 2007 & anio <= `aniofin', barwidth(.75)) ///
			(bar `pibY_bill_rfsp' anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar `rfsp_bill' anio if anio <= `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none)) ///
			(bar `rfsp_bill' anio if anio > `aniofin', barwidth(.35) yaxis(3) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected rfsp_pib anio if anio > 2007 & anio <= `aniofin', ///
				yaxis(2) mlabel(rfsp_pib) mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			(connected rfsp_pib anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(rfsp_pib) mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter `pibY_bill_rfsp' anio if anio > 2007 & anio <= `lastexo', ///
				mlabel(`pibY_bill_rfsp') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter `rfsp_bill' anio if anio > 2007 & anio <= `lastexo', ///
				mlabel(`rfsp_bill') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small) yaxis(3)) ///
			if rfsp_pib != . & anio > `ultanio', ///
			title(`graphtitle') ///
			note("{bf:Nota}: No se publican cifras de los RFSP previos al 2008.") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ytitle("", axis(3)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			ylabel(none, axis(3)) ///
			yscale(range(0 `=`rango'[2,1]*1.8') axis(1) noline) ///
			yscale(range(-10 `=`rango'[2,2]*1.15') axis(2) noline) ///
			yscale(range(0 `=`rango'[2,3]*2.5') axis(3) noline) ///
			xtitle("") ///
			yline(`=rfsp_pib[`=`obsvp'-1']', axis(2) lpattern(dash) lcolor(gray)) ///
			xlabel(2008(1)`lastexo', noticks) ///
			legend(on order(1 4) label(1 "PIB (billones `currency' `aniovp')") label(4 "RFSP (billones `currency' `aniovp')")) ///
			text(0 2009 "{bf:Observado}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(3) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`minval6'-1' `=`minanio6'-1' "{bf:RFSP como % PIB}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
			name(rfsp, replace)

		graph save rfsp `"`c(sysdir_site)'/05_graphs/rfsp.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/rfsp.png", replace name(rfsp)
		}

		** Gráfica de RFSP desagregado: Balance presupuestario vs Otros **
		tempvar rfspBalance_pib rfspOtros_pib porcentajeBalance
		g `rfspBalance_pib' = rfspBalance/pibY*100
		g `rfspOtros_pib' = (rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones)/pibY*100
		g `porcentajeBalance' = rfspBalance/(rfspBalance + rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones)*100
		format `rfspBalance_pib' `rfspOtros_pib' %7.1fc
		format `porcentajeBalance' %5.1fc

		tabstat `rfspBalance_pib' `rfspOtros_pib' `porcentajeBalance', stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		** Calcular el mínimo de porcentajeBalance en los 5 años centrales **
		summarize `porcentajeBalance' if anio >= `anioIniCentral' & anio <= `anioFinCentral' & `porcentajeBalance' != .
		local minval7 = r(min)
		summarize anio if round(`porcentajeBalance',0.001) == round(`minval7',0.001) & anio >= `anioIniCentral' & anio <= `anioFinCentral'
		local minanio7 = r(mean)

		if "$export" != "" {
			local graphtitle "{bf:RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (bar `rfspBalance_pib' anio if anio > 2007 & anio <= `aniofin', barwidth(.75)) ///
			(bar `rfspBalance_pib' anio if anio > `aniofin' & anio <= `lastexo', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar `rfspOtros_pib' anio if anio <= `aniofin', barwidth(.75) yaxis(1) ///
				pstyle(p2) lwidth(none)) ///
			(bar `rfspOtros_pib' anio if anio > `aniofin', barwidth(.75) yaxis(1) ///
				pstyle(p2) lwidth(none) fintensity(50)) ///
			(connected `porcentajeBalance' anio if anio > 2007 & anio <= `aniofin', ///
				yaxis(2) mlabel(`porcentajeBalance') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			(connected `porcentajeBalance' anio if anio > `aniofin' & anio <= `lastexo', ///
				yaxis(2) mlabel(`porcentajeBalance') mlabposition(12) mlabcolor(black) pstyle(p3) ///
				lpattern(dot) msize(small) mlabsize(small) fintensity(40)) ///
			(scatter `rfspBalance_pib' anio if anio > 2007 & anio <= `lastexo', ///
				mlabel(`rfspBalance_pib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			(scatter `rfspOtros_pib' anio if anio > 2007 & anio <= `lastexo', ///
				mlabel(`rfspOtros_pib') mlabposition(12) mlabcolor(black) msize(zero) mlabsize(small)) ///
			if rfsp_pib != . & anio > `ultanio', ///
			title(`graphtitle') ///
			note("{bf:Nota}: No se publican cifras de los RFSP previos al 2008.") ///
			caption("`graphfuente'") ///
			ytitle("") ///
			ytitle("", axis(2)) ///
			ylabel(none) ///
			ylabel(none, axis(2)) ///
			yscale(range(0 `=`rango'[2,1]*1.75') axis(1) noline) ///
			yscale(range(-40 `=`rango'[2,3]*1.15') axis(2) noline) ///
			xtitle("") ///
			xlabel(2008(1)`lastexo', noticks) ///
			legend(on order(1 3) label(1 "Balance presupuestario (% PIB)") label(3 "Otros RFSP (% PIB)")) ///
			text(0 2009 "{bf:Observado}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'' "{bf:$paqueteEconomico}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(`=`minval7'-1' `=`minanio7'' "{bf:% Balance del total}", ///
				yaxis(2) size(medium) place(6) justification(center) bcolor(white) box) ///
			name(rfspBalOtros, replace)

		graph save rfspBalOtros `"`c(sysdir_site)'/05_graphs/rfspBalOtros.gph"', replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/rfspBalOtros.png", replace name(rfspBalOtros)
		}
	}



	*********************************
	***                           ***
	**# 7 Efectos indicador deuda ***
	***                           ***
	*********************************
	*replace balprimario = balprimario + rfspOtros

	sort rfsp_pib
	scalar RFSPmaxPIB = rfsp_pib[1]
	scalar aniorfspmax = anio[1]
	scalar RFSPmax = rfsp[1]/deflator[1]
	scalar anioLP = `lastexo'
	sort anio

	scalar SHRFSPlastPIB = string(shrfsp_pib[`obslastexo'],"%7.1fc")
	scalar SHRFSPlastPC = string(shrfsp_pc[`obslastexo'],"%10.0fc")
	scalar SHRFSPlastLIF = string(shrfsp_lif[`obslastexo'],"%10.0fc")

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
			blabel(, format(%5.1fc) color(black) size(small)) outergap(0) ///
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
	if "$textbook" == "textbook" {
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
