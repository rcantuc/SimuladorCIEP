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

	** 1.3 Base PEF **
	use `"`c(sysdir_site)'../basesCIEP/SIM/SHRFSP`=subinstr("${pais}"," ","",.)'.dta"', clear



	****************
	*** 2 SYNTAX ***
	****************
	syntax [if/] [, ANIO(int `aniovp' ) NOGraphs Update Base ID(string) ///
		MINimum(real 1)]

	** 2.1 Update SHRFSP **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run UpdateSHRFSP.do
	}

	** 2.2 PIB + Deflactor **
	preserve
	PIBDeflactor, anio(`anio') nographs
	local currency = currency[1]
	tempfile PIB
	save `PIB'
	restore

	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "DEUDA `anio'" "}"


	***************
	*** 3 Merge ***
	***************
	merge 1:1 (anio) using `PIB', nogen keepus(pibY) keep(matched) update replace
	foreach k of varlist shrfsp* {
		tempvar `k'
		g ``k'' = `k'/pibY*100
	}


	***************
	*** 4 Graph ***
	***************	
	if "`nographs'" != "nographs" {
		graph bar (sum) `shrfspInterno' `shrfspExterno' if anio <= `anio' & shrfsp != ., ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Saldo hist{c o'}rico de RFSP}") ///
			/// subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(6) rows(1) label(1 "Interno") label(2 "Externo")) ///
			name(shrfsp, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}")
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
