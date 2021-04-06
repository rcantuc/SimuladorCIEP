************************************************
**** Base de datos: Población y Defunciones ****
************************************************



********************
*** A. Poblacion ***
********************



**********************
** 1. Base de datos **
import delimited using "`c(sysdir_site)'../basesCIEP/Otros/El Salvador/WPP2019_PopulationBySingleAgeSex_2020-2100.csv", clear
if "$pais" == "" {
	keep if locid == 484
}
if "$pais" == "El Salvador" {
	keep if locid == 222
}
tempfile futuro
save `futuro'


import delimited using "`c(sysdir_site)'../basesCIEP/Otros/El Salvador/WPP2019_PopulationBySingleAgeSex_1950-2019.csv", clear
if "$pais" == "" {
	keep if locid == 484
}
if "$pais" == "El Salvador" {
	keep if locid == 222
}
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
capture mkdir "`c(sysdir_personal)'/SIM/$pais/"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/$pais/Poblacion.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/$pais/Poblacion.dta", replace
}


collapse (sum) poblacion, by(anio)
g entidad = "Nacional"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/$pais/Poblaciontot.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/$pais/Poblaciontot.dta", replace
}
