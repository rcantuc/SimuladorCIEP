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
	}




	****************
	*** 2 SYNTAX ***
	****************
	syntax [if/] [, ANIO(int `aniovp' ) NOGraphs Update Base ID(string) ///
		MINimum(real 1)]

	** 2.1 Update SHRFSP **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run UpdateSHRFSP`=subinstr("${pais}"," ","",.)'.do
	}

	** 2.2 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save `PIB'


	** 2.3 Base PEF **
	use `"`c(sysdir_site)'../basesCIEP/SIM/SHRFSP`=subinstr("${pais}"," ","",.)'.dta"', clear
	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "DEUDA `anio'" "}"




	***************
	*** 3 Merge ***
	***************
	merge 1:1 (anio) using `PIB', nogen keepus(pibY) update replace
	foreach k of varlist shrfsp* {
		tempvar `k'
		g ``k'' = `k'/pibY*100
	}
	
	/*replace `shrfspInterno' = 34.7 if anio == 2020
	replace `shrfspInterno' = 35.0 if anio == 2021
	replace `shrfspInterno' = 35.1 if anio == 2022
	replace `shrfspInterno' = 35.2 if anio == 2023
	replace `shrfspInterno' = 35.4 if anio == 2024
	replace `shrfspInterno' = 35.4 if anio == 2025
	replace `shrfspInterno' = 35.6 if anio == 2026

	replace `shrfspExterno' = 20.0 if anio == 2020
	replace `shrfspExterno' = 18.7 if anio == 2021
	replace `shrfspExterno' = 18.2 if anio == 2022
	replace `shrfspExterno' = 17.8 if anio == 2023
	replace `shrfspExterno' = 17.4 if anio == 2024
	replace `shrfspExterno' = 17.0 if anio == 2025
	replace `shrfspExterno' = 16.6 if anio == 2026*/




	***************
	*** 4 Graph ***
	***************	
	if "`nographs'" != "nographs" {
		graph bar (sum) `shrfspInterno' `shrfspExterno' if `shrfspInterno' != ., ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Saldo hist{c o'}rico de RFSP}") ///
			/// subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(6) rows(1) label(1 "Interno") label(2 "Externo")) ///
			name(shrfsp, replace) ///
			blabel(bar, format(%7.1fc)) ///
			//caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}")
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
