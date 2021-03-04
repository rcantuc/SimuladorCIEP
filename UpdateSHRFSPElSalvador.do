************
** 1 RFSP **
************
	LIF, anio(2021)
	collapse (sum) recaudacion, by(anio)
	tempfile LIF0
	save `LIF0'
	
	PEF, anio(2021)
	collapse (sum) gastoneto, by(anio)
	tempfile PEF0
	save `PEF0'
	
	use `LIF0', clear
	merge 1:1 (anio) using `PEF0', nogen
	g rfsp = gastoneto - recaudacion
	format rfsp %20.0fc
	
	keep anio rfsp
	tempfile rfsp
	save `rfsp'


**************
** 2 SHRFSP **
**************
	import excel "`c(sysdir_site)'../basesCIEP/Otros/El Salvador/shrfspElSalvador.xlsx", sheet("Sheet1") clear
	*drop if R == ""
	*drop R

	replace B = "anio" if B == "VARIABLES"
	replace B = "shrfsp" if B == "SALDO DEUDA TOTAL SPNF (con FOP Serie A)"
	replace B = "interno" if B == "2. DEUDA INTERNA DE CORTO, MEDIANO Y LARGO PLAZO  3/" ///
		| B == "FOP (CIP Series A)"
	replace B = "externo" if B == "1. DEUDA EXTERNA MEDIANO Y LARGO PLAZO"
	
	keep if B == "anio" | B == "shrfsp" | B == "interno" | B == "externo"
	
	foreach k of varlist C - S {
		rename `k' monto`=`k'[1]'
	}
	drop if B == "anio"
	rename B cuenta

	collapse (sum) monto*, by(cuenta)
	reshape long monto, i(cuenta) j(anio)
	
	compress
	reshape wide monto, i(anio) j(cuenta) string
	rename montoshrfsp shrfsp
	rename montointerno shrfspInterno
	rename montoexterno shrfspExterno
	
	foreach k of varlist shrfsp shrfspInterno shrfspExterno {
		replace `k' = `k'*1000000
		format `k' %20.0fc
	}

	tempfile shrfsp
	save `shrfsp'


	
**********************
** 3 Tipo de cambio **
**********************



*********************************
** 4 Balance no presupuestario **
*********************************



*************************
** 5 Costo de la deuda **
*************************
PEF if divGA == 2, nographs
collapse (sum) costodeuda=gastoneto, by(anio)
tempfile costodeuda
save `costodeuda'

PEF if divGA == 1, nographs
collapse (sum) amortizacion=gastoneto, by(anio)
tempfile amortizacion
save `amortizacion'



************/
** 6 Merge **
*************
use `rfsp', clear
capture merge 1:1 (anio) using `Balance', nogen
capture merge 1:1 (anio) using `PIDIREGAS', nogen
capture merge 1:1 (anio) using `IPAB', nogen
capture merge 1:1 (anio) using `FONADIN', nogen
capture merge 1:1 (anio) using `Deudores', nogen
capture merge 1:1 (anio) using `Banca', nogen
capture merge 1:1 (anio) using `Adecuaciones', nogen
merge 1:1 (anio) using `shrfsp', nogen
capture merge 1:1 (anio) using `interno', nogen
capture merge 1:1 (anio) using `externo', nogen
capture merge 1:1 (anio) using `MXN', nogen
capture merge 1:1 (anio) using `USD', nogen
capture merge 1:1 (anio) using `nopresupuestario', nogen
merge 1:1 (anio) using `costodeuda', nogen
merge 1:1 (anio) using `amortizacion', nogen
tsset anio

g tipoDeCambio = 1

keep if anio <= 2020

compress
if `c(version)' == 15.1 {
	saveold `"`c(sysdir_personal)'/SIM/$pais/SHRFSP.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/SIM/$pais/SHRFSP.dta"', replace
}
