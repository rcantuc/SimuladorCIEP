************************************************
**** Base de datos: PIB e índice de precios ****
************************************************


***************
*** 0 BASES ***
***************

* 0.1.1. PIB *
import excel "`c(sysdir_site)'../basesCIEP/Otros/El Salvador/PIB.xls", clear sheet("PIB") firstrow


* 0.1.2. Limpia *
replace trimestre = trim(trimestre)
replace trimestre = "1" if trimestre == "I"
replace trimestre = "2" if trimestre == "II"
replace trimestre = "3" if trimestre == "III"
replace trimestre = "4" if trimestre == "IV"
destring trimestre, replace

replace pibQ = pibQ*1000000

collapse (sum) pibQ, by(anio trimestre)
replace pibQ = pibQ*4


* 0.1.5. Guardar *
compress
format pib* %25.0fc
tempfile PIB
save `PIB'



* 0.2.1. Deflactor *
import excel "`c(sysdir_site)'../basesCIEP/Otros/El Salvador/deflactor.xls", clear sheet("deflactor") firstrow

g trimestre = 1 if mes >= 1 & mes <= 3
replace trimestre = 2 if mes >= 4 & mes <= 6
replace trimestre = 3 if mes >= 7 & mes <= 9
replace trimestre = 4 if mes >= 10 & mes <= 12

collapse (mean) indiceQ = indiceM, by(anio trimestre)


* 0.2.5. Guardar *
compress
tempfile deflactor
save `deflactor', replace




*************************
*** 1 PIB + Deflactor ***
*************************
use `PIB', clear
merge 1:1 (anio trimestre) using `deflactor', nogen keep(match)

g pibQR = pibQ/(indiceQ/100)
g currency = "USD"

if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/$pais/PIBDeflactor.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/$pais/PIBDeflactor.dta", replace
}
