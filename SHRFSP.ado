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
	syntax [if/] [, ANIO(int `aniovp' ) NOGraphs Update Base ID(string) ///
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


	** 2.3 Base PEF **
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
	merge 1:1 (anio) using `PIB', nogen keepus(pibY) update replace
	foreach k of varlist shrfsp* {
		tempvar `k'
		g ``k'' = `k'/pibY*100
	}

	/*replace `shrfspExterno' = 20.0 if anio == 2020
	replace `shrfspExterno' = 18.7 if anio == 2021
	replace `shrfspExterno' = 18.2 if anio == 2022
	replace `shrfspExterno' = 17.8 if anio == 2023
	replace `shrfspExterno' = 17.4 if anio == 2024
	replace `shrfspExterno' = 17.0 if anio == 2025
	replace `shrfspExterno' = 16.6 if anio == 2026*/

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
				local text `"`text' `=`shrfsp'[`k']' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%5.1fc")'}""'
				local textI `"`textI' `=`shrfspInterno'[`k']' `=anio[`k']' "`=string(shrfspInterno[`k']/pibY[`k']*100,"%5.1fc")'""'
				local textE `"`textE' `=`shrfspExterno'[`k']' `=anio[`k']' "`=string(shrfspExterno[`k']/pibY[`k']*100,"%5.1fc")'""'
				local textR `"`textR' `=`rfsppib'[`k']' `=anio[`k']' "{bf:`=string(rfsp[`k']/pibY[`k']*100,"%5.1fc")'}""'
			}
		}
		
		twoway (area `rfsp' anio) (connected `rfsppib' anio, yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")) if rfsp != ., ///
			title("{bf:Requerimientos financieros} del sector p{c u'}blico") ///
			subtitle($pais) ///
			name(rfsp, replace) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`aniofirst'(1)`aniolast', noticks) ///
			text(`textR', yaxis(2)) ///
			ylabel(, axis(2) noticks format(%5.0fc) labsize(small)) ///
			yscale(range(0) axis(2) noline) ///
			ytitle(mil millones `currency') ytitle(% PIB, axis(2)) xtitle("") ///
			legend(off position(6) rows(1)) ///
			note("{bf:{c U'}ltimo dato}: `aniolast'`meslast'") ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.")
		
		
		twoway (area `interno' `externo' anio if `externo' != .) ///
			(connected `shrfspInterno' anio if `externo' != ., yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")) ///
			(connected `shrfspExterno' anio if `externo' != ., yaxis(2) mlcolor("255 189 0") lcolor("255 189 0")) ///
			(connected `shrfsp' anio if `externo' != ., yaxis(2) mlcolor("53 200 71") lcolor("53 200 71")), ///
			title("{bf:Saldo hist{c o'}rico} de RFSP") ///
			subtitle($pais) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`aniofirst'(1)`aniolast', noticks) ///
			text(`text' `textE' `textI', yaxis(2)) /*text(`textI', size(vsmall)) text(`textE', size(vsmall))*/ ///
			ylabel(, axis(2) noticks format(%5.0fc) labsize(small)) ///
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
