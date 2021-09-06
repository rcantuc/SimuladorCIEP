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
	if "`c(username)'" == "ciepmx" & "$pais" == "" {
		*UpdateDatosAbiertos
		local updated = "yes" //r(updated)
		*local ultanio = r(ultanio)
		*local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
	}



	****************
	*** 2 SYNTAX ***
	****************
	syntax [if/] [, ANIO(int `aniovp' ) DEPreciacion(int 5) NOGraphs Update Base ID(string) ///
		MINimum(real 1)]

	** 2.1 Update SHRFSP **
	capture confirm file `"`c(sysdir_personal)'/SIM/$pais/SHRFSP.dta"'
	if ("`update'" == "update" | _rc != 0) & "$pais" != "" {
		noisily run `"`c(sysdir_personal)'/UpdateSHRFSPMundial.do"' `anio'
	}
	if ("`update'" == "update" | _rc != 0) & "$pais" == "" {
		noisily run `"`c(sysdir_personal)'/UpdateSHRFSP.do"'
	}

	** 2.2 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save `PIB'

	** 2.3 Base SHRFSP **
	use `"`c(sysdir_personal)'/SIM/$pais/SHRFSP.dta"', clear
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: DEUDA $pais " in y `anio' "  }" in g _dup(20) "."
	
	local aniofirst = anio[1]
	local aniolast = anio[_N]
	capture local meslast = mes[_N]
	if _rc == 0 {
		local meslast = "m`meslast'"		
	}



	***************
	*** 3 Merge ***
	***************
	merge 1:1 (anio) using `PIB', nogen keepus(pibY pibYR var_*) update replace
	tsset anio

	** 3.1 NUEVOS par{c a'}metros ** 
	if "$pais" == "" {
		g tasaInterno = costodeudaInterno/shrfspInterno
		g tasaExterno = costodeudaExterno/shrfspExterno

		g porInterno = shrfspInterno/shrfsp
		g porExterno = shrfspExterno/shrfsp

		g balprimario = (-rfspBalance-costodeudaInterno-costodeudaExterno)/pibY*100
		
		g depreciacion = tipoDeCambio-L.tipoDeCambio
		g Depreciacion = tipoDeCambio/L.tipoDeCambio-1
		
		g tasaEfectiva = porInterno*tasaInterno + porExterno*tasaExterno

		g efectoIntereses = (tasaEfectiva/((1+var_pibY/100)*(1+var_indiceY/100)))*L.shrfsp/L.pibY*100 
		g efectoInflacion = ((-(var_indiceY/100*(1+var_pibY/100)))/(1+var_pibY/100)*(1+var_indiceY/100))*L.shrfsp/L.pibY*100
		g efectoCrecimiento = -((var_pibY/100)/((1+var_pibY/100)*(1+var_indiceY/100)))*L.shrfsp/L.pibY*100
		g efectoTipoDeCambio = ((porExterno*Depreciacion*(1+tasaExterno))/(1+var_pibY/100)*(1+var_indiceY/100))*L.shrfsp/L.pibY*100

		if "`nographs'" != "nographs" {
			graph bar efectoIntereses efectoInflacion efectoCrecimiento balprimario efectoTipoDeCambio if anio <= `anio' & Depreciacion != ., ///
				over(anio) stack blabel(, format(%5.1fc)) ///
				legend(on position(6) rows(1) label(1 "Tasas de inter{c e'}s") label(2 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
				label(4 "Balance Primario") label(5 "Tipo de cambio")) ///
				title("Componentes del {bf:Indicador de la Deuda}") ///
				name(efectoDeuda, replace) ///
				note("{bf:{c U'}ltimo dato}: `aniolast'`meslast'") ///
				caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.")
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

		noisily di _newline(2) in g "  {bf:Depreciaci{c o'}n acumulada}: " 
		noisily di in g "   `anio'-`=`anio'-`depreciacion'': " in y %7.3fc `depre'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+1': " in y %7.3fc `deprea'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+2': " in y %7.3fc `depreb'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+3': " in y %7.3fc `deprec'[1,1] in g " `currency'"
		noisily di in g "   `anio'-`=`anio'-`depreciacion'+4': " in y %7.3fc `depred'[1,1] in g " `currency'"

	}

	foreach k of varlist shrfsp* {
		tempvar `k'
		g ``k'' = `k'/pibY*100
	}

	noisily di _newline in g _col(3) "A{c N~}O" _col(15) %10s "Interna" _col(25) %10s "Externa" _col(35) %10s "Total"
	forvalues k=1(1)`=_N' {
		if `shrfsp'[`k'] != . {
			noisily di in y _col(3) anio[`k'] ///
			%10.1fc _col(15) `shrfspInterno'[`k'] ///
			%10.1fc _col(25) `shrfspExterno'[`k'] ///
			%10.1fc _col(35) `shrfsp'[`k']
		}
	}



	***************
	*** 4 Graph ***
	***************	
	if "`nographs'" != "nographs" {
		tempvar interno externo rfsp rfsppib
		g `externo' = shrfspExterno/1000000000
		g `interno' = `externo' + shrfspInterno/1000000000
		g `rfsp' = rfsp/1000000000
		g `rfsppib' = rfsp/pibY*100

		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= 2003 {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=`shrfsp'[`k']' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%5.1fc")'}""'
				local textI `"`textI' `=`shrfspInterno'[`k']' `=anio[`k']' "`=string(shrfspInterno[`k']/pibY[`k']*100,"%5.1fc")'""'
				local textE `"`textE' `=`shrfspExterno'[`k']' `=anio[`k']' "`=string(shrfspExterno[`k']/pibY[`k']*100,"%5.1fc")'""'
			}
			if `rfsppib'[`k'] != . & anio[`k'] >= 2003 {
				if "`aniorfsp'" == "" {
					local aniorfsp = anio[`k']
				}
				local textR `"`textR' `=`rfsppib'[`k']' `=anio[`k']' "{bf:`=string(rfsp[`k']/pibY[`k']*100,"%5.1fc")'}""'
			}
		}

		twoway (area `rfsp' anio) (connected `rfsppib' anio, yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")) if anio <= `anio' & rfsp != ., ///
			title("{bf:Requerimientos financieros} del sector p{c u'}blico") ///
			subtitle($pais) ///
			name(rfsp, replace) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`aniorfsp'(1)`anio', noticks) ///
			text(`textR', yaxis(2)) ///
			ylabel(, axis(2) noticks format(%5.0fc) labsize(small)) ///
			yscale(range(0) axis(1) noline) ///
			yscale(range(0) axis(2) noline) ///
			ytitle(mil millones `currency') ytitle(% PIB, axis(2)) xtitle("") ///
			legend(off position(6) rows(2)) ///
			note("{bf:{c U'}ltimo dato}: `aniolast'`meslast'") ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.")

		twoway (area `interno' `externo' anio if `externo' != .) ///
			(connected `shrfspInterno' anio if `externo' != ., yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")) ///
			(connected `shrfspExterno' anio if `externo' != ., yaxis(2) mlcolor("255 189 0") lcolor("255 189 0")) ///
			(connected `shrfsp' anio if `externo' != ., yaxis(2) mlcolor("53 200 71") lcolor("53 200 71")) if `shrfsp' != ., ///
			title("{bf:Saldo hist{c o'}rico} de RFSP") ///
			subtitle($pais) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`anioshrfsp'(1)`aniolast', noticks) ///
			text(`text' `textE' `textI', yaxis(2)) /*text(`textI', size(vsmall)) text(`textE', size(vsmall))*/ ///
			ylabel(, axis(2) noticks format(%5.0fc) labsize(small)) ///
			yscale(range(0) axis(1) noline) ///
			yscale(range(0) axis(2) noline) ///
			ytitle(mil millones `currency') ytitle(% PIB, axis(2)) xtitle("") ///
			legend(on position(6) rows(1) label(1 "Interno") label(2 "Externo") label(5 "= Total (% PIB)") ///
			label(3 "Interno (% PIB)") label(4 "Externo (% PIB)")) ///
			name(shrfsp, replace) ///
			note("{bf:{c U'}ltimo dato}: `aniolast'`meslast'") ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.")

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
