********************************
*** Ingresos presupuestarios ***
********************************
noisily LIF, by(divGA) anio(2018)
local alconsumo = r(Impuestos_al_consumo)



***************************
*** Encuesta de hogares ***
***************************
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/income`=subinstr("${pais}"," ","",.)'.dta"', clear


****************************************
** Coeficientes de consumo por edades **
g alfa = 1 if edad != .
replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
replace alfa = .4 if edad <= 4

tempvar alfatot
egen `alfatot' = sum(alfa), by(folio)



*************************************
*** Distribuciones proporcionales ***
*************************************
capture program drop Distribucion
program Distribucion
	syntax varname, MACRO(real)

	tempvar vartotal proporcion
	egen double `vartotal' = sum(`varlist') if factor != 0
	replace `varlist' = `varlist'/`vartotal'*`macro'/factor if factor != 0
end



*******************************
*** Variables Simulador.ado ***
*******************************
g Consumo = gastohog*alfa/`alfatot'
label var Consumo "Impuestos al consumo"
* Reescalar *
Distribucion Consumo, macro(`alconsumo')



***********
*** END ***
compress
capture drop __*
saveold `"`c(sysdir_site)'../basesCIEP/SIM/2018/expenditure`=subinstr("${pais}"," ","",.)'.dta"', replace version(13)

