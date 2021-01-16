************************************************
**** Base de datos: Población y Defunciones ****
************************************************


********************
*** A. Poblacion ***
********************

**********************
** 1. Base de datos **
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/pob_ini_proyecciones.csv", clear
*import delimited "/Users/ricardo/Dropbox (CIEP)/pob_mit_proyecciones.csv", clear encoding("windows-1252")


* 2. Limpia *
capture rename año anio
if _rc != 0 {
	rename ao anio
}
rename sexo sexo0
encode sexo0, generate(sexo)

drop renglon sexo0
format poblacion %10.0fc


* 3. Labels *
label var poblacion "Poblaci{c o'}n"
label var entidad "Entidad federativa"
label var anio "A{c n~}o"


* 4. Orden *
replace entidad = "Nacional" if entidad == "República Mexicana"
keep if entidad == "Nacional"


* 5. Guardar *
tempfile poblacion
save `poblacion'




**********************
*** B. Defunciones ***
**********************

********************
* 1. Base de datos *
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/def_edad_proyecciones_n.csv", clear //encoding("utf-8")
*import delimited "/Users/ricardo/Dropbox (CIEP)/def_edad_proyecciones_n.csv", clear encoding("utf-8")


* 2. Limpia *
capture rename aão anio
if _rc != 0 {
	rename ao anio
}
rename sexo sexo0
encode sexo0, generate(sexo)

drop *renglon sexo0
format defunciones %10.0fc


* 3. Labels *
label var defunciones "Defunciones"
label var entidad "Entidad federativa"
label var anio "A{c n~}o"


* 4. Orden *
replace entidad = "Nacional" if entidad == "República Mexicana"
keep if entidad == "Nacional"


* 5. Guardar *
tempfile defunciones
save `defunciones'




**********************************
*** B. Migracion Internacional ***
**********************************

********************
* 1. Base de datos *
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/mig_inter_quin_proyecciones.csv", clear
*import delimited "/Users/ricardo/Dropbox (CIEP)/mig_inter_quin_proyecciones.csv", clear


* 2. Limpia *
capture rename año anio
if _rc != 0 {
	rename ao anio
}
rename sexo sexo0
encode sexo0, generate(sexo)

drop renglon sexo0
format *migrantes %10.0fc

split anio, parse("-") destring
split edad, parse("--") destring
drop anio edad

expand anio2-anio1
replace emigrantes = emigrantes/(anio2-anio1)
replace inmigrantes = inmigrantes/(anio2-anio1)
sort entidad anio1 anio2 edad1 edad2 sexo
by entidad anio1 anio2 edad1 edad2 sexo: g n = _n
replace anio1 = anio1 + n
drop anio2 n
rename anio1 anio

expand edad2-edad1+1
replace emigrantes = emigrantes/(edad2-edad1+1)
replace inmigrantes = inmigrantes/(edad2-edad1+1)
sort entidad anio edad1 edad2 sexo
by entidad anio edad1 edad2 sexo: g n = _n
replace edad1 = edad1 + n - 1
drop edad2 n
rename edad1 edad


* 3. Labels *
label var emigrantes "Emigrantes internacionales"
label var inmigrantes "Inmigrantes internacionales"
label var entidad "Entidad federativa"
label var anio "A{c n~}o"


* 4. Orden *
replace entidad = "Nacional" if entidad == "República Mexicana"
keep if entidad == "Nacional"


* 5. Guardar *
tempfile migracion
save `migracion'




***************/
*** D. Union ***
****************
use `poblacion', clear
merge 1:1 (anio edad sexo entidad) using `defunciones', nogen
merge 1:1 (anio edad sexo entidad) using `migracion', nogen
drop cve_geo
order anio sexo edad entidad poblacion defunciones

drop if anio > 2050

egen mujeresf = sum(poblacion) if edad >= 16 & edad <= 49 & sexo == 2, by(anio)
egen nacimien = sum(poblacion) if edad == 0, by(anio)
egen nacimientos = mean(nacimien), by(anio)
egen mujeresfert = mean(mujeresf), by(anio)
format nacimientos mujeresfert %10.0fc

g tasafecundidad = nacimientos/mujeresfert*1000
label var tasafecundidad "Nacimientos por cada mil mujeres"
noisily tabstat tasafecundidad, stat(mean) by(anio) f(%10.1fc) save

drop mujeresf nacimien nacimientos
compress
capture mkdir "`c(sysdir_personal)'/SIM/"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/Poblacion.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/Poblacion.dta", replace
}

collapse (sum) poblacion, by(anio entidad)
if `c(version)' > 13.1 {
	saveold `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', replace
}
