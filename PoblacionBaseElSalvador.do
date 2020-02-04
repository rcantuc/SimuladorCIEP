************************************************
**** Base de datos: Población y Defunciones ****
************************************************



********************
*** A. Poblacion ***
********************
if "$S_OS" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/UNICEF GA/Datos/"
}
if "$S_OS" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/UNICEF GA/Datos/"
}



**********************
** 1. Base de datos **
import delimited using "WPP2019_PopulationBySingleAgeSex_2020-2100.csv", clear
keep if locid == 222 // 484
tempfile futuro
save `futuro'


import delimited using "WPP2019_PopulationBySingleAgeSex_1950-2019.csv", clear
keep if locid == 222 // 484
append using `futuro'

rename time anio
rename agegrp edad
keep anio edad pop*

reshape long pop, i(anio edad) j(sexo) string

replace pop = pop*1000
rename pop poblacion

replace sexo = "Hombres" if sexo == "male"
replace sexo = "Mujeres" if sexo == "female"

encode sexo, g(sexo0)
drop sexo
rename sexo0 sexo




***************
** 2. Labels **
label var poblacion "Poblaci{c o'}n"
label var anio "A{c n~}o"

label define sexo 1 "Hombres" 2 "Mujeres"
label values sexo sexo
drop if sexo == 3




****************
** 3. Guardar **
save `"`c(sysdir_site)'../basesCIEP/SIM/Poblacion$pais.dta"', replace


collapse (sum) poblacion, by(anio)
save `"`c(sysdir_site)'../basesCIEP/SIM/Poblaciontot$pais.dta"', replace
