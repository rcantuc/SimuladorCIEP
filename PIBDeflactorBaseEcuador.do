************************************************
**** Base de datos: PIB e índice de precios ****
************************************************


***************
*** 0 BASES ***
***************

* 0.1.1. PIB *
import excel "`c(sysdir_site)'../basesCIEP/SIM/Ecuador/CTASTRIM115.xlsx", sheet("Equilibrio-global corrientes") clear


* 0.1.2. Limpia *
rename B pibQ
split A, parse(".") generate(anio)
drop if anio2 == ""
keep pibQ anio*
rename anio1 anio
rename anio2 trimestre
order pibQ, last

replace trimestre = trim(trimestre)
replace trimestre = "1" if trimestre == "I"
replace trimestre = "2" if trimestre == "II"
replace trimestre = "3" if trimestre == "III"
replace trimestre = "4" if trimestre == "IV"

destring _all, replace

replace pibQ = pibQ*1000


* 0.1.3. Guardar *
compress
format pib* %25.0fc
tempfile PIB
save `PIB'



* 0.2.1. Deflactor *
import excel "`c(sysdir_site)'../basesCIEP/SIM/Ecuador/CTASTRIM115.xlsx", sheet("Deflactores Equilibrio O-U") clear


* 0.2.2. Limpia *
rename B indiceQ
split A, parse(".") generate(anio)
drop if anio2 == ""
keep indiceQ anio*
rename anio1 anio
rename anio2 trimestre
order indiceQ, last

replace trimestre = trim(trimestre)
replace trimestre = "1" if trimestre == "I"
replace trimestre = "2" if trimestre == "II"
replace trimestre = "3" if trimestre == "III"
replace trimestre = "4" if trimestre == "IV"

destring _all, replace


* 0.2.3. Guardar *
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
