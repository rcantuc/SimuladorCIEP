program define SHRFSP
timer on 5
quietly {

	************************
	*** 1 VALOR PRESENTE ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}	



	****************
	*** 2 SYNTAX ***
	****************
	syntax [if/] [, ANIO(int `aniovp' ) DEPreciacion(int 5) NOGraphs UPDATE Base ID(string)]
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
	*** 3 MERGE ***
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
	
	* Parámetros *
	replace porInterno = L.porInterno if porInterno == .
	replace porExterno = L.porExterno if porExterno == .
	forvalues j = 1(1)`=_N' { 
		foreach k of varlist shrfsp shrfspInterno shrfspExterno rfsp rfspBalance rfspPIDIREGAS rfspIPAB rfspFONADIN ///
			rfspDeudores rfspBanca rfspAdecuaciones {
			capture confirm scalar `k'`=anio[`j']'
			if _rc == 0 {
				replace `k' = scalar(`k'`=anio[`j']')/100*pibY if anio == `=anio[`j']'
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
	
	* Tasas Efectivas *
	g tasaInterno = costodeudaInterno/L.shrfspInterno*100
	g tasaExterno = costodeudaExterno/L.shrfspExterno*100
	g tasaEfectiva = porInterno*tasaInterno + porExterno*tasaExterno

	g depreciacion = tipoDeCambio-L.tipoDeCambio
	g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100

	* Efectos indicador deuda *
	foreach k of varlist shrfsp* {
		*tempvar `k'
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
		local j = 100/(`anio'-2012+1)/2
		forvalues k=1(1)`=_N' {
			if efectoPositivo[`k'] != . & anio[`k'] >= 2012 {
				local textDeuda `"`textDeuda' `=efectoPositivo[`k']+.3' `j' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local j = `j' + 100/(`anio'-2012+1)
			}
		}
		if `"$export"' == "" {
			local graphtitle "Efectos sobre el {bf:indicador de la deuda}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		graph bar balprimario nopresupuestario_pib efectoCrecimiento efectoInflacion ///
			efectoIntereses efectoTipoDeCambio efectoOtros ///
			if anio <= `anio' & anio >= 2012, ///
			over(anio, gap(0)) stack ///
			blabel(, format(%5.1fc)) outergap(0) ///
			text(`textDeuda', color(black) size(small)) ///
			ytitle("% PIB") ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
			label(1 "Balance Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			name(efectoDeuda, replace) ///
			note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
		}			
	}



	***************
	*** 4 Graph ***
	***************	
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar shrfsp shrfspexterno shrfspinterno interno externo ///
		rfspBalance rfspAdecuacion rfspOtros rfspBalance0 rfspAdecuacion0 rfspOtros0 rfsppib
		g `shrfsp' = shrfsp/Poblacion/deflator
		g `shrfspexterno' = shrfspExterno/Poblacion/deflator
		g `shrfspinterno' = shrfspInterno/Poblacion/deflator

		g `externo' = shrfspExterno/1000000000/deflator
		g `interno' = `externo' + shrfspInterno/1000000000/deflator
		
		tempvar shrfspsinPemex shrfspPemex
		g `shrfspPemex' = deudaPemex/1000000000/deflator
		replace `shrfspPemex' = 0 if `shrfspPemex' == .
		g `shrfspsinPemex' = (shrfsp)/1000000000/deflator
		replace `shrfspsinPemex' = 0 if `shrfspsinPemex' == .

		local ultanio = 2008
		local j = 100/(`ultanio'-`anioshrfsp'+1)/2
		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= `ultanio' {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=shrfsp[`k']/1000000000/deflator[`k']' `=anio[`k']' "{bf:`=string(shrfsp[`k']/pibY[`k']*100,"%5.1fc")'% PIB}""'
				local textI `"`textI' `=`interno'[`k']/2+`externo'[`k']/2' `=anio[`k']' "`=string(shrfspInterno[`k']/1000000000,"%10.0fc")'""'
				local textE `"`textE' `=`externo'[`k']/2' `=anio[`k']' "`=string(shrfspExterno[`k']/1000000000,"%10.0fc")'""'
				if `shrfspsinPemex'[`k'] != . & anio[`k'] < `anio' {
					local textPemex `"`textPemex' `=`shrfspPemex'[`k']/2' `=anio[`k']' "{bf:`=string(`shrfspPemex'[`k'],"%10.1fc")'}""'
					local textSPemex `"`textSPemex' `=`shrfspsinPemex'[`k']/2+`shrfspPemex'[`k']/2' `=anio[`k']' "{bf:`=string(`shrfspsinPemex'[`k']-`shrfspPemex'[`k'],"%10.1fc")'}""'
				}
				local textPC `"`textPC' `=`shrfsp'[`k']' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%10.0fc")'}""'
				local textPC `"`textPC' `=`shrfspinterno'[`k']' `=anio[`k']' "{bf:`=string(`shrfspinterno'[`k'],"%10.0fc")'}""'
				local textPC `"`textPC' `=`shrfspexterno'[`k']' `=anio[`k']' "{bf:`=string(`shrfspexterno'[`k'],"%10.0fc")'}""'
				local j = `j' + 100/(`ultanio'-`anioshrfsp'+1)
			}
		}
		
		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} de RFSP"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `interno' `externo' anio if anio >= `ultanio' & anio < `anio') ///
			(bar `interno' `externo' anio if anio >= `anio') if `externo' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`anio', noticks) ///	
			text(`textE' `textI', color(white) size(small)) ///
			text(`text', placement(n) size(vsmall)) ///
			///text(2 `=`anio'+1.45' "{bf:Proyecci{c o'}n PE 2022}", color(white)) ///
			///text(2 `=2003+.45' "{bf:Externo}", color(white)) ///
			///text(`=2+`externosize2003'' `=2003+.45' "{bf:Interno}", color(white)) ///
			yscale(range(0) axis(1) noline) ///
			ytitle("mil millones `currency' `aniovp'") xtitle("") ///
			legend(on position(6) rows(1) order(1 2 3 4) ///
			label(1 `"Interno (`=string(shrfspInterno[`obsvp']/shrfsp[`obsvp']*100,"%7.1fc")'%)"') ///
			label(2 `"Externo (`=string(shrfspExterno[`obsvp']/shrfsp[`obsvp']*100,"%7.1fc")'%)"') ///
			label(3 "Interno ($paqueteEconomico)") label(4 "Externo ($paqueteEconomico)") region(margin(zero))) ///
			name(shrfsp, replace) ///
			note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `=anio[`obsvp']'. {bf:{c U'}ltimo dato}: `aniofin'm`mesfin'")

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}			

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
		
		
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} por persona"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (connected `shrfsp' `shrfspinterno' `shrfspexterno' anio if anio <= `anio') ///
			(connected `shrfsp' `shrfspinterno' `shrfspexterno' anio if anio > `anio') if `shrfsp' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			ylabel(#5, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`anio', noticks) ///	
			text(`textPC', placement(c) color(black) size(small)) ///
			yscale(axis(1) noline) ///
			ytitle("`currency' `aniovp'") xtitle("") ///
			note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			legend(label(1 "  Total") label(2 "  Interno") label(3 "  Externo") order(1 2 3)) ///
			name(shrfsppc, replace)

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

		local j = 100/(`anio'-2013+1)/2
		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= 2013 {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=`shrfsp'[`k']*1.005' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%5.1fc")'}""'
				local textI `"`textI' `=`interno'[`k']/2+`externo'[`k']/2' `=anio[`k']' "`=string(shrfspInterno[`k']/pibY[`k']*100,"%5.1fc")'""'
				local textE `"`textE' `=`externo'[`k']/2' `=anio[`k']' "`=string(shrfspExterno[`k']/pibY[`k']*100,"%5.1fc")'""'
			}

			if `rfsppib'[`k'] != . {
				local textRFSP `"`textRFSP' `=efectoPositivoRFSP[`k']+.025' `=anio[`k']' "{bf:`=string(`rfsppib'[`k'],"%5.1fc")'%}""'
				local textRFBa `"`textRFBa' `=`rfspBalance'[`k']/2+max(`rfspAdecuacion'[`k']/2,0)+max(`rfspOtros'[`k']/2,0)' `=anio[`k']' "{bf:`=string(`rfspBalance0'[`k'],"%5.1fc")'}""'
				if `rfspAdecuacion'[`k'] < 0 {
					local textRFAd `"`textRFAd' `=`rfspAdecuacion'[`k']/2+min(`rfspOtros'[`k']/2,0)' `=anio[`k']' "{bf:`=string(`rfspAdecuacion0'[`k'],"%5.1fc")'}""'
				}
				else {
					local textRFAd `"`textRFAd' `=`rfspAdecuacion'[`k']/2+max(`rfspOtros'[`k']/2,0)' `=anio[`k']' "{bf:`=string(`rfspAdecuacion0'[`k'],"%5.1fc")'}""'					
				}
				local textRFOt `"`textRFOt' `=`rfspOtros'[`k']/2' `=anio[`k']' "{bf:`=string(`rfspOtros0'[`k'],"%5.1fc")'}""'				

				local textTEI `"`textTEI' `=tasaInterno[`k']' `=anio[`k']' "{bf:`=string(tasaInterno[`k'],"%5.1fc")'}""'
				local textTEE `"`textTEE' `=tasaExterno[`k']' `=anio[`k']' "{bf:`=string(tasaExterno[`k'],"%5.1fc")'}""'
				
				local j = `j' + 100/(2027-2008+1)
			}
		}

		twoway (bar `rfspBalance' `rfspAdecuacion' `rfspOtros' anio if anio < `anio', bstyle(p1bar p2bar p3bar)) ///
			(bar `rfspBalance' `rfspAdecuacion' `rfspOtros' anio if anio >= `anio', bstyle(p5bar p6bar p7bar)) if rfsp != ., ///
			title("{bf:Requerimientos financieros} del sector p{c u'}blico") ///
			subtitle($pais) xtitle("") ///
			name(rfsp, replace) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(2008(1)`anio', noticks) ///	
			yscale(range(0) axis(1) noline) ///
			///text(`textRFSP', placement(n)) ///
			///text(`textRFBa', color(white)) ///
			///text(`textRFAd', color(white)) ///
			///text(`textRFOt', color(white)) ///
			ytitle("% PIB") ///
			legend(on position(6) rows(1) label(3 "Otros") label(2 "Adecuaciones") label(1 "Balance presupuestario") ///
			label(6 "Proy. Otros") label(5 "Proy. Adecuaciones") label(4 "Proy. Balance") region(margin(zero))) ///
			note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico.")

		twoway (connected tasaInterno tasaExterno anio if anio >= 2013 & anio <= `anio'), ///
			title("Tasas de interés {bf:efectivas}") ///
			subtitle($pais) /**/ ///
			ylabel(0(2)8, format(%15.0fc) labsize(small)) ///
			ytitle("Costo Fin./Saldo Fin. * 100") ///
			legend(on position(6) rows(1) order(1 2 3 4) label(1 "Interno") label(2 "Externo") ///
			region(margin(zero))) ///
			xlabel(2013(1)`anio') xtitle("") ///
			text(`textTEE', placement(c) color(white)) ///
			text(`textTEI', placement(c) color(white)) ///
			name(tasasdeinteres, replace) ///
			note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico.")

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/RFSP.png", replace name(rfsp)
			graph export "$export/SHRFSP.png", replace name(shrfsp)
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


