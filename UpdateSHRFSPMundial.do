if "`1'" == "" {
	local 1 = 2020
}


************
** 1 RFSP **
************
LIF, anio(`1') nographs
collapse (sum) recaudacion, by(anio)
tempfile LIF0
save `LIF0'

PEF, anio(`1') nographs
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
import excel "`c(sysdir_site)'../basesCIEP/Otros/$pais/shrfsp.xlsx", sheet("shrfsp") clear


* Limpia *
drop in 1
rename A anio
rename B shrfspInterno
rename C shrfspExterno
rename D shrfsp
destring _all, replace

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
merge 1:1 (anio) using `shrfsp', nogen
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
