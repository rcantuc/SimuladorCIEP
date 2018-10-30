****************************
* Base de datos: Deflactor *
****************************

* 1. Base de datos *
import excel "`=c(sysdir_site)'../simuladorCIEP/$simuladorCIEP/bases/INEGI/BIE/SCN/PIB/PIB.xlsx", clear

* 2. Limpia *
drop if substr(A,1,1) != "1" & substr(A,1,1) != "2"
rename A periodo
rename B pibQ

split periodo, destring p("/") ignore("r p")

rename periodo1 anio
rename periodo2 trimestre

destring pibQ, replace
drop periodo

* 2.1 Convertirlo a pesos *
replace pibQ = pibQ*1000000
format pibQ %25.0fc

* 3. Labels *
label var anio "a${ni}o"
label var trimestre "trimestre"
label var pibQ "Producto Interno Bruto"

* 4. Orden *
order anio trimestre pibQ

* 5. Guardar *
compress
save "`=c(sysdir_site)'../simuladorCIEP/$simuladorCIEP/bases/INEGI/BIE/SCN/PIB/pib.dta", replace
