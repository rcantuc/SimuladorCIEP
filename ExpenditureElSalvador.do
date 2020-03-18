********************************
*** Ingresos presupuestarios ***
********************************
noisily LIF, by(divGA) anio(2018)
local alconsumo = r(Impuestos_al_consumo)



***************************
*** Encuesta de hogares ***
***************************
use "`c(sysdir_site)'../basesCIEP/Otros/EHPM2018.dta", clear
rename r106 edad
rename r104 sexo

g escol = 0 if r215a == 8 | r215a == 7 | r215a == .
replace escol = 1 if r215a == 0 | r215a == 1 | r215a == 2 | r215a == 6
replace escol = 2 if r215a == 3
replace escol = 3 if r215a == 4 | r215a == 5

label define escol 0 "Sin escolaridad" 1 "Basica" 2 "Media Superior" 3 "Superior"
label values escol escol
label var escol "Nivel de escolaridad"

xtile decil = ingpe [fw=fac00], n(10)

rename ingfa ing_bruto_tot

g formal = r422a == 1 | r422a == 2 | ///
	r422b == 1 | r422b == 2 | ///
	r422c == 1 | r422c == 2 | ///
	r422d == 1 | r422d == 2 | ///
	r422e == 1 | r422e == 2 | ///
	r422f == 1 | r422f == 2 | ///
	r422g == 1 | r422g == 2

rename fac00 factor

rename folio folioold
rename idboleta folio
rename r101 numren


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
if `c(version)' == 15.1 {
	saveold `"`c(sysdir_site)'../basesCIEP/SIM/2018/expenditure`=subinstr("${pais}"," ","",.)'.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'../basesCIEP/SIM/2018/expenditure`=subinstr("${pais}"," ","",.)'.dta"', replace
}
