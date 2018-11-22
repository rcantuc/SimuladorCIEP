****************************
****                    ****
**** Base de datos: PIB ****
****                    ****
****************************

* 1. Base de datos *
import excel "`=c(sysdir_site)'/bases/INEGI/SCN/PIB/PIB.xlsx", clear

* 2. Limpia *
LimpiaBIE

* 3. Rename *
rename A periodo
rename B pibQ

* 4. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 trimestre
label var trimestre "trimestre"

destring pibQ, replace
label var pibQ "Producto Interno Bruto"

drop periodo
order anio trimestre pibQ

* 5. Guardar *
compress
save "`=c(sysdir_site)'/bases/INEGI/SCN/PIB/PIB.dta", replace
