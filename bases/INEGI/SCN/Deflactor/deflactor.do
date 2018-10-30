****************************
* Base de datos: Deflactor *
****************************

* 1. Base de datos *
import excel "`=c(sysdir_site)'../simuladorCIEP/$simuladorCIEP/bases/INEGI/BIE/SCN/Deflactor/deflactor.xlsx", clear //sheet("deflactor") 

* 2. Limpia *
drop if substr(A,1,1) != "1" & substr(A,1,1) != "2"
rename A periodo
rename B indiceQ

split periodo, destring p("/") ignore("r p")

rename periodo1 anio
rename periodo2 trimestre

destring indice, replace
drop periodo

* 3. Labels *
label var anio "a${ni}o"
label var trimestre "trimestre"
label var indiceQ "${I}ndice de precios impl${i}citos"

* 4. Orden *
order anio trimestre indiceQ

* 5. Guardar *
compress
save "`=c(sysdir_site)'../simuladorCIEP/$simuladorCIEP/bases/INEGI/BIE/SCN/Deflactor/deflactor.dta", replace
