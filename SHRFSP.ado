program define SHRFSP
timer on 5
quietly {

	************************
	**# 1 VALOR PRESENTE ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}	



	****************
	**# 2 SYNTAX ***
	****************
	syntax [if/] [, ANIO(int `aniovp' ) DEPreciacion(int 5) NOGraphs UPDATE Base ID(string) ULTAnio(int 2008)]
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: DEUDA $pais " in y `anio' "  }" in g _dup(20) "."


	** 2.1 Update SHRFSP **
	capture confirm file `"`c(sysdir_site)'/SIM/$pais/SHRFSP.dta"'
	if ("`update'" == "update" | _rc != 0) & "$pais" != "" {
		noisily run `"`c(sysdir_site)'/UpdateSHRFSPMundial.do"' `anio'
	}
	if ("`update'" == "update" | _rc != 0) & "$pais" == "" {
		noisily run `"`c(sysdir_site)'/UpdateSHRFSP.do"'
	}


	** 2.2 PIB + Deflactor **
	PIBDeflactor, nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save `PIB'



	***************
	**# 3 MERGE ***
	***************
	use `"`c(sysdir_site)'/SIM/$pais/SHRFSP.dta"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(pibY pibYR var_* Poblacion* deflator) update replace
	tsset anio

	forvalues k=1(1)`=_N' {
		if rfsp[`k'] != . & "`anioini'" == "" {
			local anioini = anio[`k']
		}
		if rfsp[`k'] == . & "`anioini'" != "" & "`aniofin'" == "" {
			local aniofin = anio[`=`k'-1']
			local mesfin = mes[`=`k'-1']
			local obsfin = `k'-1
		}
		if anio[`k'] == `anio' {
			local obsvp = `k'
		}
	}
	local lastexo = `aniofin'



	*****************
	**# 4 DISPLAY ***
	*****************
	noisily di _newline in g "  {bf:Tipo de cambio " in y anio[`obsfin'] in g ": }" _col(30) in y %15.1fc tipoDeCambio[`obsfin'] in g " `currency'/USD"
	noisily di in g "  {bf:Tipo de cambio " in y anio[`obsfin'-1] in g ": }" _col(30) in y %15.1fc tipoDeCambio[`obsfin'-1] in g " `currency'/USD"
	noisily di in g "  {bf:Diferencia " in y "`=anio[`obsfin']'-`=anio[`obsfin'-1]'" in g ": }" _col(30) in y %15.1fc tipoDeCambio[`obsfin']-tipoDeCambio[`obsfin'-1] in g " `currency'/USD"
	
	noisily di _newline in g "  {bf:SHRFSP a" in y " `=anio[`obsfin']'m`=mes[`obsfin']'" in g ": }" _col(30) in y %15.0fc shrfsp[`obsfin']/Poblacion[`obsfin']/deflator[`obsfin'] in g " `currency' `=anio[`obsfin']' por persona"
	noisily di in g "  {bf:SHRFSP interna a" in y " `=anio[`obsfin']'m`=mes[`obsfin']'" in g ": }" _col(30) in y %15.0fc shrfspInterno[`obsfin']/Poblacion[`obsfin']/deflator[`obsfin'] in g " `currency' `=anio[`obsfin']' por persona"
	noisily di in g "  {bf:SHRFSP externa a" in y " `=anio[`obsfin']'m`=mes[`obsfin']'" in g ": }" _col(30) in y %15.0fc shrfspExterno[`obsfin']/Poblacion[`obsfin']/tipoDeCambio[`obsfin'] in g " USD por persona"

	noisily di _newline in g "  {bf:SHRFSP a" in y " `=anio[`obsfin'-1]'m`=mes[`obsfin'-1]'" in g ": }" _col(30) in y %15.0fc shrfsp[`obsfin'-1]/Poblacion[`obsfin'-1]/deflator[`obsfin'-1] in g " `currency' `=anio[`obsfin']' por persona"
	noisily di in g "  {bf:SHRFSP interna a" in y " `=anio[`obsfin'-1]'m`=mes[`obsfin'-1]'" in g ": }" _col(30) in y %15.0fc shrfspInterno[`obsfin'-1]/Poblacion[`obsfin'-1]/deflator[`obsfin'-1] in g " `currency' `=anio[`obsfin']' por persona"
	noisily di in g "  {bf:SHRFSP externa a" in y " `=anio[`obsfin'-1]'m`=mes[`obsfin'-1]'" in g ": }" _col(30) in y %15.0fc shrfspExterno[`obsfin'-1]/Poblacion[`obsfin'-1]/tipoDeCambio[`obsfin'-1] in g " USD por persona"

	noisily di _newline in g "  {bf:Diferencia" in y " `=anio[`obsfin']'m`=mes[`obsfin']'-`=anio[`obsfin'-1]'m`=mes[`obsfin'-1]'" in g ": }" _col(30) in y %15.0fc shrfsp[`obsfin']/Poblacion[`obsfin']/deflator[`obsfin']-shrfsp[`obsfin'-1]/Poblacion[`obsfin'-1]/deflator[`obsfin'-1] in g " `currency' `=anio[`obsfin']' por persona"
	noisily di in g "  {bf:Diferencia interna" in g ": }" _col(30) in y %15.0fc shrfspInterno[`obsfin']/Poblacion[`obsfin']/deflator[`obsfin']-shrfspInterno[`obsfin'-1]/Poblacion[`obsfin'-1]/deflator[`obsfin'-1] in g " `currency' `=anio[`obsfin']' por persona"
	noisily di in g "  {bf:Diferencia externa" in g ": }" _col(30) in y %15.0fc shrfspExterno[`obsfin']/Poblacion[`obsfin']/tipoDeCambio[`obsfin']-shrfspExterno[`obsfin'-1]/Poblacion[`obsfin'-1]/tipoDeCambio[`obsfin'-1] in g " USD por persona"



	*****************************
	**# 5 PARÁMETROS EXÓGENOS ***
	*****************************
	replace porInterno = L.porInterno if porInterno == .
	replace porExterno = L.porExterno if porExterno == .
	forvalues j = 1(1)`=_N' { 
		foreach k of varlist shrfspInterno shrfspExterno rfsp rfspBalance rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones {
			capture confirm scalar `k'`=anio[`j']'
			if _rc == 0 {
				replace `k' = scalar(`k'`=anio[`j']')/100*pibY if anio == `=anio[`j']'
				local lastexo = `=anio[`j']'
			}
		}
		capture confirm scalar costodeudaInterno`=anio[`j']'
		if _rc == 0 {
			replace costodeudaInterno = scalar(costodeudaInterno`=anio[`j']')/100*porInterno*pibY if anio == `=anio[`j']'
		}		
		capture confirm scalar costodeudaExterno`=anio[`j']'
		if _rc == 0 {
			replace costodeudaExterno = scalar(costodeudaExterno`=anio[`j']')/100*porExterno*pibY if anio == `=anio[`j']'
		}
		capture confirm scalar tipoDeCambio`=anio[`j']'
		if _rc == 0 {
			replace tipoDeCambio = scalar(tipoDeCambio`=anio[`j']') if anio == `=anio[`j']'
		}
	}



	*************************
	**# 6 TASAS EFECTIVAS ***
	*************************
	replace shrfsp = shrfspInterno + shrfspExterno if mes != 12 
	
	g tasaInterno = costodeudaInterno/L.shrfspInterno*100
	g tasaExterno = costodeudaExterno/L.shrfspExterno*100
	g tasaEfectiva = porInterno*tasaInterno + porExterno*tasaExterno
	format tasa* %7.1fc

	g depreciacion = tipoDeCambio-L.tipoDeCambio
	g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100



	*********************************
	**# 7 Efectos indicador deuda ***
	*********************************
	foreach k of varlist shrfsp* {
		g `k'_pib = `k'/pibY*100
	}
	g dif_shrfsp_pib = D.shrfsp_pib

	g balprimario = -(rfspBala+costodeudaInt+costodeudaExt)/pibY*100
	forvalues j = 1(1)`=_N' { 
		foreach k of varlist balprimario {
				capture confirm scalar `k'`=anio[`j']'
				if _rc == 0 {
					replace `k' = scalar(`k'`=anio[`j']') if anio == `=anio[`j']'
				}		
		}
	}
	g nopresupuestario_pib   = -(rfspPIDIREGAS+rfspIPAB+rfspFONADIN+rfspDeudores+rfspBanca+rfspAdecuacion)/pibY*100
	g efectoCrecimiento  = -(var_pibY/100)*L.shrfsp/pibY*100
	g efectoInflacion    = -(var_indiceY/100+var_indiceY/100*var_pibY/100)*L.shrfsp/pibY*100 
	g efectoIntereses    = ((tasaInterno/100)*L.shrfspInterno+(tasaExterno/100)*L.shrfspExterno)/pibY*100
	g efectoTipoDeCambio = (Depreciacion/100 + tasaExterno/100*Depreciacion/100)*L.shrfspExterno/pibY*100
	*g efectoActivos      = -(D.activosInt+D.activosExt*tipoDeCambio*1000-amortizacion)/pibY*100
	g efectoTotal = balprimario + nopresupuestario_pib + efectoCrecimiento + efectoInflacion ///
		+ efectoIntereses + efectoTipoDeCambio
	g efectoOtros        = dif_shrfsp_pib - efectoTotal

	g efectoPositivo = 0
	foreach k of varlist balprimario nopresupuestario_pib efectoCrecimiento efectoInflacion ///
		efectoIntereses efectoTipoDeCambio efectoOtros {
			replace efectoPositivo = efectoPositivo + `k' if `k' > 0
	}

	if "`nographs'" != "nographs" & "$nographs" == "" {
		local j = 100/(`anio'-`ultanio'+1)/2
		forvalues k=1(1)`=_N' {
			if efectoPositivo[`k'] != . & anio[`k'] >= `ultanio' {
				local textDeuda `"`textDeuda' `=efectoPositivo[`k']+.3' `j' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local j = `j' + 100/(`anio'-`ultanio'+1)
			}
		}
		if `"$export"' == "" {
			local graphtitle "{bf:Efectos sobre el indicador de la deuda}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		graph bar balprimario nopresupuestario_pib efectoCrecimiento efectoInflacion efectoIntereses efectoTipoDeCambio efectoOtros ///
			if anio <= `anio' & anio >= `ultanio', ///
			over(anio, gap(0)) stack ///
			blabel(, format(%5.1fc)) outergap(0) ///
			text(`textDeuda', color(black) size(vsmall)) ///
			ytitle("% PIB") ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			name(efectoDeuda, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
		}			
	}



	*********************************
	** 4.2 Deuda interna y externa **
	*********************************
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar shrfsp shrfspexterno shrfspinterno shrfspexternoG shrfspinternoG interno externo ///
		rfspBalance rfspAdecuacion rfspOtros rfspBalance0 rfspAdecuacion0 rfspOtros0 rfsppib

		g `shrfsp' = shrfsp/Poblacion/deflator

		g `shrfspinterno' = shrfspInterno/Poblacion/deflator
		g `shrfspexterno' = shrfspExterno/Poblacion/deflator
		g `shrfspinternoG' = shrfspInterno/Poblacion/deflator
		g `shrfspexternoG' = `shrfspinternoG' + shrfspExterno/Poblacion/deflator

		g `externo' = shrfspExterno/1000000000/deflator
		g `interno' = `externo' + shrfspInterno/1000000000/deflator

		format `shrfspexterno' `shrfspinterno' `shrfspexternoG' `shrfspinternoG' `externo' `interno' %10.0fc
		
		tempvar shrfspsinPemex shrfspPemex
		g `shrfspPemex' = deudaPemex/1000000000/deflator
		replace `shrfspPemex' = 0 if `shrfspPemex' == .
		g `shrfspsinPemex' = (shrfsp)/1000000000/deflator
		replace `shrfspsinPemex' = 0 if `shrfspsinPemex' == .

		local j = 100/(`ultanio'-`anioshrfsp'+1)/2
		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= `ultanio' {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=shrfsp[`k']/1000000000/deflator[`k']*1.0075' `=anio[`k']' "{bf:`=string(shrfsp[`k']/pibY[`k']*100,"%5.1fc")'% PIB}""'
				if `shrfspsinPemex'[`k'] != . & anio[`k'] < `anio' {
					local textPemex `"`textPemex' `=`shrfspPemex'[`k']/2' `=anio[`k']' "{bf:`=string(`shrfspPemex'[`k'],"%10.1fc")'}""'
					local textSPemex `"`textSPemex' `=`shrfspsinPemex'[`k']/2+`shrfspPemex'[`k']/2' `=anio[`k']' "{bf:`=string(`shrfspsinPemex'[`k']-`shrfspPemex'[`k'],"%10.1fc")'}""'
				}
				local textPC `"`textPC' `=`shrfsp'[`k']*1.0075' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%10.0fc")'}""'
				local j = `j' + 100/(`ultanio'-`anioshrfsp'+1)
			}
		}
		
		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `interno' anio if mes == 12, mlabel(`interno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `externo' anio if mes == 12, mlabel(`externo') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `interno' anio if mes != 12, mlabel(`interno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p1) fintensity(inten60) lwidth(none)) ///
			(bar `externo' anio if mes != 12, mlabel(`externo') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p2) fintensity(inten60) lwidth(none)) ///
			if `externo' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			text(`text', placement(n) size(vsmall)) ///
			///text(2 `=`anio'+1.45' "{bf:Proyecci{c o'}n PE 2022}", color(white)) ///
			///text(2 `=2003+.45' "{bf:Externo}", color(white)) ///
			///text(`=2+`externosize2003'' `=2003+.45' "{bf:Interno}", color(white)) ///
			yscale(range(0) axis(1) noline) ///
			ytitle("mil millones `currency' `aniovp'") xtitle("") ///
			legend(on position(6) rows(1) order(1 2) ///
			label(1 `"Interno (`=string(shrfspInterno[`obsvp']/shrfsp[`obsvp']*100,"%7.1fc")'%)"') ///
			label(2 `"Externo (`=string(shrfspExterno[`obsvp']/shrfsp[`obsvp']*100,"%7.1fc")'%)"') ///
			region(margin(zero))) ///
			name(shrfsp, replace) ///
			note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `=anio[`obsvp']'.")

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}			

		/*if `"$export"' == "" {
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
		}*/
		
		
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico por persona}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, $paqueteEconomico y CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `shrfspexternoG' anio if mes == 12, mlabel(`shrfspexterno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `shrfspinternoG' anio if mes == 12, mlabel(`shrfspinterno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `shrfspexternoG' anio if mes != 12, mlabel(`shrfspexterno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p1) fintensity(inten60) lwidth(none)) ///
			(bar `shrfspinternoG' anio if mes != 12, mlabel(`shrfspinterno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p2) fintensity(inten60) lwidth(none)) ///
			if `shrfsp' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			ylabel(#4, format(%15.0fc) labsize(small)) yscale(range(40000)) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			text(`textPC', placement(n) color(black) size(vsmall)) ///
			yscale(axis(1) noline) ///
			ytitle("`currency' `aniovp'") xtitle("") ///
			note("{bf:Nota:} Las barras opacas son proyecciones de $paqueteEconomico.") ///
			legend(label(2 "Deuda Interna") label(1 "Deuda Externa") order(1 2)) ///
			name(shrfsppc, replace)

		/*gr_edit .xaxis1.edit_tick 16 2023 `"2023*"', tickset(major)
		gr_edit .xaxis1.edit_tick 16 2024 `"2024*"', tickset(major)
		gr_edit .xaxis1.edit_tick 16 2025 `"2025*"', tickset(major)
		gr_edit .xaxis1.edit_tick 16 2026 `"2026*"', tickset(major)
		gr_edit .xaxis1.edit_tick 16 2027 `"2027*"', tickset(major)
		gr_edit .xaxis1.edit_tick 16 2028 `"2028*"', tickset(major)
		gr_edit .xaxis1.edit_tick 16 2029 `"2029*"', tickset(major)*/

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsppc.png", replace name(shrfsppc)
		}

		if "$pais" != "" {
			exit
		}


		**************************************************
		** REQUERIMIENTOS FINANCIEROS DEL SECTOR PÚBLCO **
		g `rfspOtros0' = - rfspPIDIREGAS/pibY*100 - rfspIPAB/pibY*100 - rfspFONADIN/pibY*100 - rfspDeudores/pibY*100 - rfspBanca/pibY*100
		g `rfspAdecuacion0' = - rfspAdecuacion/pibY*100		
		g `rfspBalance0' = - rfspBalance/pibY*100

		g `rfspOtros' = - rfspPIDIREGAS/pibY*100 - rfspIPAB/pibY*100 - rfspFONADIN/pibY*100 - rfspDeudores/pibY*100 - rfspBanca/pibY*100
		g `rfspAdecuacion' = `rfspOtros' - rfspAdecuacion/pibY*100 if rfspAdecuacion <= 0
		replace `rfspAdecuacion' = - rfspAdecuacion/pibY*100 if rfspAdecuacion > 0
		replace `rfspAdecuacion' = 0 if `rfspAdecuacion' == .

		g `rfspBalance' = `rfspAdecuacion' - rfspBalance/pibY*100 if rfspAdecuacion <= 0 & `rfspOtros' >= 0
		replace `rfspBalance' = - rfspBalance/pibY*100 if rfspAdecuacion > 0 & `rfspOtros' < 0
		replace `rfspBalance' = `rfspOtros' - rfspBalance/pibY*100 if rfspAdecuacion > 0 & `rfspOtros' >= 0
		replace `rfspBalance' = `rfspAdecuacion' - `rfspOtros' - rfspBalance/pibY*100 if rfspAdecuacion <= 0 & `rfspOtros' < 0

		format `rfspBalance' `rfspAdecuacion' `rfspOtros' `rfspBalance0' `rfspAdecuacion0' `rfspOtros0' %5.1f
		
		g `rfsppib' = rfsp/pibY*100

		* Informes mensuales texto *
		tabstat rfsp if anio == `anio' | anio == `anio'-1, by(anio) f(%20.0fc) stat(sum) c(v) save nototal
		tempname stathoy statayer
		matrix `stathoy' = r(Stat2)
		matrix `statayer' = r(Stat1)
		noisily di _newline in g "  {bf:RFSP a" in y " `aniofin'm`mesfin'" in g ": }" _col(30) in y %15.1fc `stathoy'[1,1]/(`statayer'[1,1]/deflator[`=`obsvp'-1'])*100 in g " % de `=`anio'-1'."
		noisily di in g "  {bf:RFSP a" in y " `aniofin'm`mesfin'" in g ": }" _col(30) in y %15.1fc `stathoy'[1,1]/1000000 in g " millones `currency'."

		g efectoPositivoRFSP = 0
		foreach k of varlist `rfspBalance0' `rfspAdecuacion0' `rfspOtros0' {
				replace efectoPositivoRFSP = efectoPositivoRFSP + `k' if `k' > 0
		}

		local j = 100/(`anio'-`ultanio'+1)/2
		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= `ultanio' {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=`shrfsp'[`k']*1.005' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%5.1fc")'}""'
				local textI `"`textI' `=`interno'[`k']/2+`externo'[`k']/2' `=anio[`k']' "`=string(shrfspInterno[`k']/pibY[`k']*100,"%5.1fc")'""'
				local textE `"`textE' `=`externo'[`k']/2' `=anio[`k']' "`=string(shrfspExterno[`k']/pibY[`k']*100,"%5.1fc")'""'
			}

			if `rfsppib'[`k'] != . & anio[`k'] >= `ultanio' {
				local textRFSP `"`textRFSP' `=efectoPositivoRFSP[`k']+.025' `=anio[`k']' "{bf:`=string(`rfsppib'[`k'],"%5.1fc")'% PIB}""'

				local textTEI `"`textTEI' `=tasaInterno[`k']' `=anio[`k']' "{bf:`=string(tasaInterno[`k'],"%5.1fc")'}""'
				local textTEE `"`textTEE' `=tasaExterno[`k']' `=anio[`k']' "{bf:`=string(tasaExterno[`k'],"%5.1fc")'}""'
				
				local j = `j' + 100/(`anio'-`ultanio'+1)
			}
		}

		if "$export" == "" {
			local graphtitle "{bf:Requerimientos financieros del sector p{c u'}blico}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `rfspBalance' anio if mes == 12, mlabel(`rfspBalance0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(bar `rfspAdecuacion' anio if mes == 12, mlabel(`rfspAdecuacion0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(bar `rfspOtros' anio if mes == 12, mlabel(`rfspOtros0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(bar `rfspBalance' anio if mes != 12, mlabel(`rfspBalance0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p1) fintensity(inten60) lwidth(none)) ///
			(bar `rfspAdecuacion' anio if mes != 12, mlabel(`rfspAdecuacion0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p2) fintensity(inten60) lwidth(none)) ///
			(bar `rfspOtros' anio if mes != 12, mlabel(`rfspOtros0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p3) fintensity(inten60) lwidth(none)) ///
			if rfsp != . & anio >= `ultanio', ///
			title("`graphtitle'") ///
			subtitle($pais) xtitle("") ///
			name(rfsp, replace) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			yscale(range(0) axis(1) noline) ///
			text(`textRFSP', placement(n) size(vsmall)) ///
			ytitle("% PIB") ///
			legend(on rows(1) label(3 "Otros ajustes") label(2 "Adecuaciones a registros") label(1 "Déficit presupuestario") ///
			region(margin(zero)) order(1 2 3)) ///
			///note("{bf:Nota:} Las barras opacas son proyecciones de $paqueteEconomico.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/rfsp.png", replace name(rfsp)
		}			

		twoway (connected tasaInterno anio if mes == 12, mlabel(tasaInterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(connected tasaExterno anio if mes == 12, mlabel(tasaExterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(connected tasaInterno anio if mes != 12, mlabel(tasaInterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p1) mcolor(%70) mlwidth(none)) ///
			(connected tasaExterno anio if mes != 12, mlabel(tasaExterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p2) mcolor(%70) mlwidth(none)) ///
			if tasaInterno != . & anio >= `ultanio', ///
			title("Tasas de interés {bf:efectivas}") ///
			subtitle($pais) /**/ ///
			ylabel(0(2)8, format(%15.0fc) labsize(small)) ///
			ytitle("Costo Fin./Saldo Fin. * 100") ///
			legend(on position(6) rows(1) order(1 2 3 4) label(1 "Interno") label(2 "Externo") ///
			region(margin(zero))) ///
			xlabel(`ultanio'(1)`lastexo') xtitle("") ///
			///text(`textTEE', placement(c) color(white)) ///
			///text(`textTEI', placement(c) color(white)) ///
			name(tasasdeinteres, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico.")
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


