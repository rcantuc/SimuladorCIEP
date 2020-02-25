use `"`c(sysdir_site)'../basesCIEP/SIM/2018/income`=subinstr("${pais}"," ","",.)'.dta"', clear


***********************************************
** MI.15. Coeficientes de consumo por edades **
g alfa = 1 if edad != .
replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
replace alfa = .4 if edad <= 4

tempvar alfatot
egen `alfatot' = sum(alfa), by(folio)



*******************************
*** Variables Simulador.ado *** 
g Consumo = gastohog*alfa/`alfatot'
label var Consumo "Impuestos al consumo"



***********
*** END ***
compress
capture drop __*
save `"`c(sysdir_site)'../basesCIEP/SIM/2018/expenditure`=subinstr("${pais}"," ","",.)'.dta"', replace

