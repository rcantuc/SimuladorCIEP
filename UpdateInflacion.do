*****************************
**** Base de datos: INPC ****
*****************************


***************
*** 0 BASES ***
***************
* 0.1.1. PIB *
import excel "`=c(sysdir_site)'/bases/UPDATE/SCN/inflacion.xlsx", clear

* 0.1.2. Limpia *
LimpiaBIE

* 0.1.3. Rename *
rename A periodo
rename B inpc
replace inpc = inpc/1000000
format inpc %6.4fc

* 0.1.4. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 mes
label var mes "mes"

destring inpc, replace
label var inpc "INPC"

drop periodo
order anio mes inpc

* 0.1.5. Guardar *
compress

if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'/SIM/inflacion.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'/SIM/inflacion.dta"', replace
}
