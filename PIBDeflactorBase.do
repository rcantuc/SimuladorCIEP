************************************************
**** Base de datos: PIB e índice de precios ****
************************************************


***************
*** 0 BASES ***
***************
* 0.1.1. PIB *
import excel "`=c(sysdir_site)'../basesCIEP/INEGI/SCN/PIB.xlsx", clear

* 0.1.2. Limpia *
LimpiaBIE

* 0.1.3. Rename *
rename A periodo
rename B pibQ

* 0.1.4. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 trimestre
label var trimestre "trimestre"

destring pibQ, replace
label var pibQ "Producto Interno Bruto"

drop periodo
order anio trimestre pibQ

* 0.1.5. Guardar *
compress
tempfile PIB
save `PIB'


* 0.2.1. Deflactor *
import excel "`=c(sysdir_site)'../basesCIEP/INEGI/SCN/deflactor.xlsx", clear

* 0.2.2. Limpia *
LimpiaBIE, nomult

* 0.2.3. Rename *
rename A periodo
rename B indiceQ

* 0.2.4. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 trimestre
label var trimestre "trimestre"

destring indiceQ, replace
label var indiceQ "${I}ndice de Precios Impl${i}citos"

drop periodo
order anio trimestre indiceQ

* 0.2.5. Guardar *
compress
tempfile Deflactor
save `Deflactor', replace




*************************
*** 1 PIB + Deflactor ***
*************************
use (anio trimestre pibQ) using `PIB', clear
merge 1:1 (anio trimestre) using `Deflactor', nogen keepus(indiceQ)

* Anio + Trimestre *
g aniotrimestre = yq(anio,trimestre)
format aniotrimestre %tq
label var aniotrimestre "YearQuarter"
tsset aniotrimestre

g pibQR = pibQ/(indiceQ/100)

collapse (mean) pibY=pibQ pibYR=pibQR (last) trimestre, by(anio)
format pib* %25.0fc

g currency = "MXN"

if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor.dta"', replace
}
