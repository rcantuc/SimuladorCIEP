*****************************
**** Base de datos: INPC ****
*****************************


***************
*** 0 BASES ***
***************
* 0.1.1. PIB *
import excel "`=c(sysdir_site)'../basesCIEP/INEGI/SCN/inflacion.xlsx", clear

* 0.1.2. Limpia *
LimpiaBIE

* 0.1.3. Rename *
rename A periodo
rename B inflacion
replace inflacion = inflacion/1000000
format inflacion %6.4fc

* 0.1.4. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 mes
label var mes "mes"

destring infl, replace
label var infl "Inflaci{c o'}n"

drop periodo
order anio mes infl

* 0.1.5. Guardar *
compress

if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'../basesCIEP/SIM/inflacion.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'../basesCIEP/SIM/inflacion.dta"', replace
}
