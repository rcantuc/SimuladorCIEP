program define SHRFSP
quietly {


	timer on 5
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 Datos Abiertos (México) **
	if "$pais" == "" {
		UpdateDatosAbiertos
		local updated = r(updated)
		local ultanio = r(ultanio)
		local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
		local ultanio = 2021
	}

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
	*use "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
	PIBDeflactor, nog
	local currency = currency[1]
	tempfile PIB
	save `PIB'



	***************
	*** 3 MERGE ***
	***************
	use `"`c(sysdir_site)'/SIM/$pais/SHRFSP.dta"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(pibY pibYR var_* Poblacion deflator) update replace
	tsset anio

	** 3.1 CGPE 2022 ** 
	if "$pais" == "" {
		/*replace shrfsp = 51/100*pibY if anio == 2022
		replace shrfspInterno = 34.5/100*pibY if anio == 2022
		replace shrfspExterno = 16.5/100*pibY if anio == 2022
		replace rfsp = 3.5/100*pibY if anio == 2022
		replace rfspBalance = -3.1/100*pibY if anio == 2022
		replace rfspPIDIREGAS = -0.0/100*pibY if anio == 2022
		replace rfspIPAB = -0.1/100*pibY if anio == 2022
		replace rfspFONADIN = -0.0/100*pibY if anio == 2022
		replace rfspDeudores = 0.1/100*pibY if anio == 2022
		replace rfspBanca = -0.0/100*pibY if anio == 2022
		replace rfspAdecuacion = -0.4/100*pibY if anio == 2022
		replace tipoDeCambio = 20.4 if anio == 2022

		replace shrfsp = 51/100*pibY if anio == 2023
		replace shrfspInterno = 35.1/100*pibY if anio == 2023
		replace shrfspExterno = 15.9/100*pibY if anio == 2023
		replace rfsp = 3.2/100*pibY if anio == 2023
		replace rfspBalance = -2.7/100*pibY if anio == 2023
		replace rfspPIDIREGAS = -0.0/100*pibY if anio == 2023
		replace rfspIPAB = -0.1/100*pibY if anio == 2023
		replace rfspFONADIN = -0.0/100*pibY if anio == 2023
		replace rfspDeudores = 0.0/100*pibY if anio == 2023
		replace rfspBanca = -0.0/100*pibY if anio == 2023
		replace rfspAdecuacion = -0.4/100*pibY if anio == 2023
		replace tipoDeCambio = 20.6 if anio == 2023

		replace shrfsp = 51/100*pibY if anio == 2024
		replace shrfspInterno = 35.5/100*pibY if anio == 2024
		replace shrfspExterno = 15.5/100*pibY if anio == 2024
		replace rfsp = 2.9/100*pibY if anio == 2024
		replace rfspBalance = -2.4/100*pibY if anio == 2024
		replace rfspPIDIREGAS = -0.0/100*pibY if anio == 2024
		replace rfspIPAB = -0.1/100*pibY if anio == 2024
		replace rfspFONADIN = -0.0/100*pibY if anio == 2024
		replace rfspDeudores = 0.0/100*pibY if anio == 2024
		replace rfspBanca = -0.0/100*pibY if anio == 2024
		replace rfspAdecuacion = -0.4/100*pibY if anio == 2024
		replace tipoDeCambio = 20.8 if anio == 2024

		replace shrfsp = 51/100*pibY if anio == 2025
		replace shrfspInterno = 36.0/100*pibY if anio == 2025
		replace shrfspExterno = 15.0/100*pibY if anio == 2025
		replace rfsp = 2.8/100*pibY if anio == 2025
		replace rfspBalance = -2.3/100*pibY if anio == 2025
		replace rfspPIDIREGAS = -0.0/100*pibY if anio == 2025
		replace rfspIPAB = -0.1/100*pibY if anio == 2025
		replace rfspFONADIN = -0.0/100*pibY if anio == 2025
		replace rfspDeudores = 0.0/100*pibY if anio == 2025
		replace rfspBanca = -0.0/100*pibY if anio == 2025
		replace rfspAdecuacion = -0.4/100*pibY if anio == 2025
		replace tipoDeCambio = 20.9 if anio == 2025

		replace shrfsp = 51/100*pibY if anio == 2026
		replace shrfspInterno = 36.5/100*pibY if anio == 2026
		replace shrfspExterno = 14.5/100*pibY if anio == 2026
		replace rfsp = 2.8/100*pibY if anio == 2026
		replace rfspBalance = -2.3/100*pibY if anio == 2026
		replace rfspPIDIREGAS = -0.0/100*pibY if anio == 2026
		replace rfspIPAB = -0.1/100*pibY if anio == 2026
		replace rfspFONADIN = -0.0/100*pibY if anio == 2026
		replace rfspDeudores = 0.0/100*pibY if anio == 2026
		replace rfspBanca = -0.0/100*pibY if anio == 2026
		replace rfspAdecuacion = -0.4/100*pibY if anio == 2026
		replace tipoDeCambio = 21.0 if anio == 2026

		replace shrfsp = 51/100*pibY if anio == 2027
		replace shrfspInterno = 36.9/100*pibY if anio == 2027
		replace shrfspExterno = 14.1/100*pibY if anio == 2027
		replace rfsp = 2.8/100*pibY if anio == 2027
		replace rfspBalance = -2.3/100*pibY if anio == 2027
		replace rfspPIDIREGAS = -0.0/100*pibY if anio == 2027
		replace rfspIPAB = -0.1/100*pibY if anio == 2027
		replace rfspFONADIN = -0.0/100*pibY if anio == 2027
		replace rfspDeudores = 0.1/100*pibY if anio == 2027
		replace rfspBanca = -0.0/100*pibY if anio == 2027
		replace rfspAdecuacion = -0.5/100*pibY if anio == 2027
		replace tipoDeCambio = 21.3 if anio == 2027*/

		/*replace costodeudaInterno = 2.8/100*porInterno*pibY if anio == 2022
		replace costodeudaExterno = 2.8/100*porExterno*pibY if anio == 2022
		replace costodeudaInterno = 3.0/100*porInterno*pibY if anio == 2023
		replace costodeudaExterno = 3.0/100*porExterno*pibY if anio == 2023
		replace costodeudaInterno = 3.0/100*porInterno*pibY if anio == 2024
		replace costodeudaExterno = 3.0/100*porExterno*pibY if anio == 2024
		replace costodeudaInterno = 3.0/100*porInterno*pibY if anio == 2025
		replace costodeudaExterno = 3.0/100*porExterno*pibY if anio == 2025
		replace costodeudaInterno = 3.0/100*porInterno*pibY if anio == 2026
		replace costodeudaExterno = 3.0/100*porExterno*pibY if anio == 2026
		replace costodeudaInterno = 3.1/100*porInterno*pibY if anio == 2027
		replace costodeudaExterno = 3.1/100*porExterno*pibY if anio == 2027*/
		
		g porInterno = shrfspInterno/shrfsp
		g porExterno = shrfspExterno/shrfsp
		g tasaInterno = costodeudaInterno/shrfspInterno*100
		g tasaExterno = costodeudaExterno/shrfspExterno*100
		g tasaEfectiva = porInterno*tasaInterno + porExterno*tasaExterno

		*replace tasaInterno = L.tasaInterno if tasaInterno == .
		*replace tasaExterno = L.tasaExterno if tasaExterno == .

		g depreciacion = tipoDeCambio-L.tipoDeCambio
		g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100

		/*replace balprimario = 0.3 if anio == 2022
		replace balprimario = -0.3 if anio == 2023
		replace balprimario = -0.6 if anio == 2024
		replace balprimario = -0.6 if anio == 2025
		replace balprimario = -0.7 if anio == 2026
		replace balprimario = -0.8 if anio == 2027*/

		g nopresupuestario   = -(rfspPIDIREGAS+rfspIPAB+rfspFONADIN+rfspDeudores+rfspBanca+rfspAdecuacion)/pibY*100
		g balprimario        = -(rfspBala+costodeudaInt+costodeudaExt)/pibY*100

		g efectoCrecimiento  = -(var_pibY/100)*L.shrfsp/pibY*100
		g efectoInflacion    = -(var_indiceY/100+var_indiceY/100*var_pibY/100)*L.shrfsp/pibY*100 

		g efectoIntereses    = ((1+tasaInterno/100)*L.shrfspInterno+(1+tasaExterno/100)*L.shrfspExterno)/pibY*100 - L.shrfsp/pibY*100

		g efectoTipoDeCambio = (Depreciacion/100 + tasaExterno/100*Depreciacion/100)*L.shrfspExterno/pibY*100

		g efectoTotal = balprimario + nopresupuestario + efectoCrecimiento + efectoInflacion + efectoIntereses + efectoTipoDeCambio
		
		g efectoPositivo = 0
		foreach k of varlist balprimario nopresupuestario efectoCrecimiento efectoInflacion efectoIntereses efectoTipoDeCambio {
				replace efectoPositivo = efectoPositivo + `k' if `k' > 0
		}
   
		if "`nographs'" != "nographs" & "$nographs" == "" {
			local j = 100/(`anio'-2014)/2
			forvalues k=1(1)`=_N' {
				if efectoTotal[`k'] != . & anio[`k'] >= 2014 {
					local textDeuda `"`textDeuda' `=efectoPositivo[`k']+.35' `j' "{bf:`=string(efectoTotal[`k'],"%5.1fc")'% PIB}""'
					local j = `j' + 100/(`anio'-2014)
				}
			}
			graph bar balprimario nopresupuestario efectoCrecimiento efectoInflacion efectoIntereses efectoTipoDeCambio ///
				if Depreciacion != . & anio >= 2008, ///
				over(anio, gap(0)) stack blabel(, format(%5.1fc)) outergap(0) ///
				text(`textDeuda', color(black)) ///
				ytitle("% PIB") ///
				legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
				label(1 "Balance Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") region(margin(zero))) ///
				title("Efectos sobre el {bf:indicador de la deuda}") ///
				name(efectoDeuda, replace) ///
				note("{bf:{c U'}ltimo dato}: `ultanio'm`ultmes'") ///
				caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP.")

			capture confirm existence $export
			if _rc == 0 {
				graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
			}			
		}

		tabstat depreciacion if anio <= `anio' & anio >= `=`anio'-`depreciacion'+1', stat(sum) save
		tempname depre
		matrix `depre' = r(StatTotal)

		replace depreciacion = `depre'[1,1] if depreciacion == . & anio > `anio'

		tabstat depreciacion if anio <= `anio' & anio >= `=`anio'-`depreciacion'+1+1', stat(sum) save
		tempname deprea
		matrix `deprea' = r(StatTotal)

		tabstat depreciacion if anio <= `anio' & anio >= `=`anio'-`depreciacion'+1+2', stat(sum) save
		tempname depreb
		matrix `depreb' = r(StatTotal)

		tabstat depreciacion if anio <= `anio' & anio >= `=`anio'-`depreciacion'+1+3', stat(sum) save
		tempname deprec
		matrix `deprec' = r(StatTotal)

		tabstat depreciacion if anio <= `anio' & anio >= `=`anio'-`depreciacion'+1+4', stat(sum) save
		tempname depred
		matrix `depred' = r(StatTotal)

		noisily di _newline in g "  {bf:Depreciaci{c o'}n acumulada}: " 
		noisily di in g "   `anio'-`=`anio'-`depreciacion'': " in y %7.3fc `depre'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+1': " in y %7.3fc `deprea'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+2': " in y %7.3fc `depreb'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+3': " in y %7.3fc `deprec'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+4': " in y %7.3fc `depred'[1,1] in g " `currency'"

	}

	foreach k of varlist shrfsp* {
		*tempvar `k'
		*g ``k'' = `k' //pibY*100
	}



	***************
	*** 4 Graph ***
	***************	
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar shrfsp interno externo rfspBalance rfspAdecuacion rfspOtros rfspBalance0 rfspAdecuacion0 rfspOtros0 rfsppib
		g `shrfsp' = shrfsp
		g `externo' = shrfspExterno/1000000000/deflator
		g `interno' = `externo' + shrfspInterno/1000000000/deflator

		local j = 100/(`ultanio'-`anioshrfsp'+1)/2
		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= 2003 {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=shrfsp[`k']/1000000000/deflator[`k']*1.005' `=anio[`k']' "{bf:`=string(`shrfsp'[`k']/pibY[`k']*100,"%5.1fc")'% PIB}""'
				local textI `"`textI' `=`interno'[`k']/2+`externo'[`k']/2' `=anio[`k']' "`=string(shrfspInterno[`k']/1000000000,"%10.0fc")'""'
				local textE `"`textE' `=`externo'[`k']/2' `=anio[`k']' "`=string(shrfspExterno[`k']/1000000000,"%10.0fc")'""'
				local j = `j' + 100/(`ultanio'-`anioshrfsp'+1)
			}
			if anio[`k'] == `ultanio' {
				local obsvp = `k'
			}
		}
		
		twoway (bar `interno' `externo' anio if anio <= `anio') ///
			/*(bar `interno' `externo' anio if anio > `anio')*/ if `externo' != ., ///
			title("{bf:Saldo hist{c o'}rico} de RFSP") ///
			subtitle($pais) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`anioshrfsp'(1)`ultanio', noticks) ///	
			text(`textE' `textI', color(white)) ///
			text(`text', placement(n)) ///
			///text(2 `=`anio'+1.45' "{bf:Proyecci{c o'}n PE 2022}", color(white)) ///
			///text(2 `=2003+.45' "{bf:Externo}", color(white)) ///
			///text(`=2+`externosize2003'' `=2003+.45' "{bf:Interno}", color(white)) ///
			yscale(range(0) axis(1) noline) ///
			ytitle("mil millones `currency' `aniovp'") xtitle("") ///
			legend(on position(6) rows(1) order(1 2 3 4) ///
			label(1 `"Interno (`=string(shrfspInterno[`obsvp']/shrfsp[`obsvp']*100,"%7.1fc")'%)"') ///
			label(2 `"Externo (`=string(shrfspExterno[`obsvp']/shrfsp[`obsvp']*100,"%7.1fc")'%)"') ///
			/*label(3 "Proy. Interno") label(4 "Proy. Externo")*/ region(margin(zero))) ///
			name(shrfsp, replace) ///
			note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `=anio[`obsvp']'. {bf:{c U'}ltimo dato}: `ultanio'm`ultmes'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP.")

		noisily di _newline in g "  {bf:Tipo de cambio " in y anio[`obsvp'] in g ": }" _col(30) in y %15.1fc tipoDeCambio[`obsvp'] in g " `currency'/USD"

		noisily di _newline in g "  {bf:SHRFSP a" in y " `ultanio'm`ultmes'" in g ": }" _col(30) in y %15.0fc shrfsp[`obsvp']/Poblacion[`obsvp'] in g " `currency' por persona."
		noisily di in g "  {bf:SHRFSP interna a" in y " `ultanio'm`ultmes'" in g ": }" _col(30) in y %15.0fc shrfspInterno[`obsvp']/Poblacion[`obsvp'] in g " `currency' por persona."
		noisily di in g "  {bf:SHRFSP externa a" in y " `ultanio'm`ultmes'" in g ": }" _col(30) in y %15.0fc shrfspExterno[`obsvp']/Poblacion[`obsvp']/tipoDeCambio[`obsvp'] in g " USD por persona."

		noisily di _newline in g "  {bf:SHRFSP a" in y " `=`ultanio'-1'm`ultmes'" in g ": }" _col(30) in y %15.0fc shrfsp[`obsvp'-1]/Poblacion[`obsvp'-1] in g " `currency' por persona."
		noisily di in g "  {bf:SHRFSP interna a" in y " `=`ultanio'-1'm`ultmes'" in g ": }" _col(30) in y %15.0fc shrfspInterno[`obsvp'-1]/Poblacion[`obsvp'-1] in g " `currency' por persona."
		noisily di in g "  {bf:SHRFSP externa a" in y " `=`ultanio'-1'm`ultmes'" in g ": }" _col(30) in y %15.0fc shrfspExterno[`obsvp'-1]/Poblacion[`obsvp'-1]/tipoDeCambio[`obsvp'-1] in g " USD por persona."

		if "$pais" != "" {
			exit
		}

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
		noisily di _newline in g "  {bf:RFSP a" in y " `ultanio'm`ultmes'" in g ": }" _col(30) in y %15.1fc `stathoy'[1,1]/(`statayer'[1,1]/deflator[`=`obsvp'-1'])*100 in g " % de `=`anio'-1'."
		noisily di in g "  {bf:RFSP a" in y " `ultanio'm`ultmes'" in g ": }" _col(30) in y %15.1fc `stathoy'[1,1]/1000000 in g " millones `currency'."

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
				local textRFSP `"`textRFSP' `=efectoPositivoRFSP[`k']+.025' `=anio[`k']' "{bf:`=string(`rfsppib'[`k'],"%5.1fc")'% PIB}""'
				local textRFBa `"`textRFBa' `=`rfspBalance'[`k']/2+max(`rfspAdecuacion'[`k']/2,0)+max(`rfspOtros'[`k']/2,0)' `=anio[`k']' "{bf:`=string(`rfspBalance0'[`k'],"%5.1fc")'}""'
				if `rfspAdecuacion'[`k'] < 0 {
					local textRFAd `"`textRFAd' `=`rfspAdecuacion'[`k']/2+min(`rfspOtros'[`k']/2,0)' `=anio[`k']' "{bf:`=string(`rfspAdecuacion0'[`k'],"%5.1fc")'}""'
				}
				else {
					local textRFAd `"`textRFAd' `=`rfspAdecuacion'[`k']/2+max(`rfspOtros'[`k']/2,0)' `=anio[`k']' "{bf:`=string(`rfspAdecuacion0'[`k'],"%5.1fc")'}""'					
				}
				local textRFOt `"`textRFOt' `=`rfspOtros'[`k']/2' `=anio[`k']' "{bf:`=string(`rfspOtros0'[`k'],"%5.1fc")'}""'
				local j = `j' + 100/(2027-2008+1)
			}
		}

		twoway (bar `rfspBalance' `rfspAdecuacion' `rfspOtros' anio if anio <= `anio', bstyle(p1bar p2bar p3bar)) ///
			/*(bar `rfspBalance' `rfspAdecuacion' `rfspOtros' anio if anio > `anio', bstyle(p5bar p6bar p7bar))*/ if rfsp != ., ///
			title("{bf:Requerimientos financieros} del sector p{c u'}blico") ///
			subtitle($pais) xtitle("") ///
			name(rfsp, replace) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(2013(1)`ultanio', noticks) ///	
			yscale(range(0) axis(1) noline) ///
			text(`textRFSP', placement(n)) ///
			text(`textRFBa', color(white)) ///
			text(`textRFAd', color(white)) ///
			text(`textRFOt', color(white)) ///
			ytitle("% PIB") ///
			legend(on position(6) rows(1) label(3 "Otros") label(2 "Adecuaciones") label(1 "Balance presupuestario") ///
			/*label(6 "Proy. Otros") label(5 "Proy. Adecuaciones") label(4 "Proy. Balance presupuestario")*/ region(margin(zero))) ///
			note("{bf:{c U'}ltimo dato}: `ultanio'm`ultmes'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP.")

		graph bar tasaInterno tasaExterno if anio >= 2013 & anio <= `anio' & tasaInterno != ., ///
			over(anio) blabel(bar, format(%5.1fc)) ///
			title("Tasas de interés {bf:efectivas}") ///
			subtitle($pais) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			ytitle("costo/saldo %") ///
			legend(on position(6) rows(1) order(1 2 3 4) label(1 "Interno") label(2 "Externo") ///
			region(margin(zero))) ///
			name(tasasdeinteres, replace) ///
			note("{bf:{c U'}ltimo dato}: `ultanio'm`ultmes'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP.")
			
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


