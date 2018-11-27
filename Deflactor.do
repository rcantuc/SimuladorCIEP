**********************************
****                          ****
**** Base de datos: Deflactor ****
****                          ****
**********************************

* 1. Base de datos *
import excel "`=c(sysdir_site)'/bases/INEGI/SCN/Deflactor/Deflactor.xlsx", clear

* 2. Limpia *
LimpiaBIE, nomult

* 3. Rename *
rename A periodo
rename B indiceQ

* 4. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 trimestre
label var trimestre "trimestre"

destring indiceQ, replace
label var indiceQ "${I}ndice de Precios Impl${i}citos"

drop periodo
order anio trimestre indiceQ

* 5. Guardar *
compress
save "`=c(sysdir_site)'/bases/INEGI/SCN/Deflactor/Deflactor.dta", replace
