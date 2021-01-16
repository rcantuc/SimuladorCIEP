****************************************************
***               ACTUALIZACIÓN                  *** 
*** 1) abrir archivos .iqy en Excel de Windows   ***
*** 2) guardar y reemplazar .xls dentro de       ***
***      ./TemplateCIEP/basesCIEP/INEGI/SCN/     ***
*** 3) correr SCN[.ado] con opci{c o'}n "update" ***
****************************************************



**** Sistema de Cuentas Nacionales ****
program define balanzacomercial, return
quietly {
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, ANIO(int `aniovp') NOGraphs Update Discount(int 3)]
	
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema de Cuentas Nacionales " in y `anio' "  }" in g _dup(20) "."



	*****************************************************
	*** 1. Databases (D) and variable definitions (V) ***
	*****************************************************
	import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/balanza comercial.xlsx", clear
	LimpiaBIE
	split A, parse("/")
	drop A

	*******************************
	** 1.2. Rename variables (V) **
	** V.1. Anio **
	rename A1 anio
	rename A2 mes
	destring anio mes, replace
	rename B exportaciones
	rename C importaciones
	rename D FOB
	rename E fletes
	format exporta importa FOB fletes %20.0fc

	collapse (sum) exporta importa FOB fletes (last) mes, by(anio)
	tsset anio

	replace importaciones = importaciones*12/mes
	
	if anio[_N] < `anio' {
		tsappend, add(`=`anio'-anio[_N]')
	}

	tempfile balanza
	save`balanza'
	
	
	PIBDeflactor, nographs nooutput
	merge 1:1 (anio) using `balanza', keep(matched) nogen
	merge 1:1 (anio) using `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', keep(matched) keepus(tipoDeCambio) nogen


	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio'{
			local last = `k'
			continue, break
		}
	}

	replace importaciones = L.importaciones*(1+var_pibY/100) if importaciones == .
	replace exportaciones = L.exportaciones*(1+var_pibY/100) if exportaciones == .
	replace FOB = L.FOB*(1+var_pibY/100) if FOB == .
	replace fletes = L.fletes*(1+var_pibY/100) if fletes == .

	scalar importacionesBCPIB = (importaciones[`last']*tipoDeCambio[`=`last'-1'])/pibY[`last']*100

}
end
