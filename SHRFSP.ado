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
	if "`c(username)'" == "ricardo" & "$pais" == "" {
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
	if "`update'" == "update" | /*"`updated'" != "yes" |*/ _rc != 0 {
		noisily run `"$sysdir_principal/UpdateSHRFSP`=subinstr("${pais}"," ","",.)'.do"'
	}

	** 2.2 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save `PIB'


	** 2.3 Base PEF **
	use `"`c(sysdir_personal)'/SIM/$pais/SHRFSP.dta"', clear
	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "DEUDA `anio'" "}"
	
	local aniofirst = anio[1]
	local aniolast = anio[_N]
	local meslast = mes[_N]




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
		tempvar interno externo
		g `interno' = shrfspInterno/1000000000000
		g `externo' = `interno' + shrfspExterno/1000000000000

		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= 2003 {
				local text `"`text' `=`shrfsp'[`k']' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%5.1fc")'}""'
				local textI `"`textI' `=`interno'[`k']' `=anio[`k']' "`=string(shrfspInterno[`k']/1000000000000,"%5.1fc")'""'
				local textE `"`textE' `=`externo'[`k']' `=anio[`k']' "`=string(shrfspExterno[`k']/1000000000000,"%5.1fc")'""'
			}
		}

		twoway (area `externo' `interno' anio if `externo' != .) ///
			(connected `shrfsp' anio if `externo' != ., yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")), ///
			title("{bf:Saldo hist{c o'}rico} de RFSP") ///
			subtitle($pais) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`aniofirst'(1)`aniolast', noticks) ///
			text(`text', yaxis(2)) /*text(`textI', size(vsmall)) text(`textE', size(vsmall))*/ ///
			ylabel(, axis(2) noticks format(%5.0fc) labsize(small)) ///
			yscale(range(0) axis(2) noline) ///
			ytitle(billones MXN) ytitle(% PIB, axis(2)) xtitle("") ///
			legend(on position(6) rows(1) label(1 "Interno") label(2 "Externo") label(3 "= Total (% PIB)")) ///
			name(shrfsp, replace) ///
			caption("Elaborado por el CIEP, con informaci{c o'}n de la SHCP, EOFP (`aniolast'm`meslast').")
			
		capture confirm existence $export
		if _rc == 0 {
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
