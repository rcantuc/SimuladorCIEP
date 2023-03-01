****************************************************************************************
****                                                                                ****
****   Bases de datos de Mexico: Población, defunciones y migración internacional   ****
****                                                                                ****
****************************************************************************************

noisily di in g "  Updating Poblacion.dta..." _newline

********************
*** A. Poblacion ***
********************

** 1. Base de datos (online) **
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/pob_mit_proyecciones.csv", clear


/** 1.Bis Base de datos (Censo 2020). Responsable: Ale Macias **
use "`c(sysdir_personal)'../basesCIEP/CONAPO/censo2020.dta", clear
tostring sexo, replace


** 2. Limpia **/
capture drop renglon
capture rename año anio
capture rename ao anio

rename sexo sexo0
encode sexo0, generate(sexo)
drop sexo0


** 3. Guardar **
tempfile poblacion
save "`poblacion'"





**********************
*** B. Defunciones ***
**********************

** 1. Base de datos (online) **
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/def_edad_proyecciones_n.csv", clear


** 2. Limpia **/
capture rename año anio
capture rename ao anio
capture rename aão anio

rename sexo sexo0
encode sexo0, generate(sexo)
drop *renglon sexo0


** 3. Guardar **
tempfile defunciones
save "`defunciones'"





**********************************
*** C. Migracion Internacional ***
**********************************

** 1. Base de datos (online) **
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/mig_inter_quin_proyecciones.csv", clear


** 2. Limpia **
capture rename año anio
if _rc != 0 {
	rename ao anio
}
split anio, parse("-") destring
split edad, parse("--") destring

rename sexo sexo0
encode sexo0, generate(sexo)
drop renglon sexo0 anio edad

* 2.1 Se expanden los años para rellenar los espacios entre rangos. Por ejemplo: de 0-4 a 0,1,2,3,4. *
expand anio2-anio1
replace emigrantes = emigrantes/(anio2-anio1)
replace inmigrantes = inmigrantes/(anio2-anio1)
sort entidad anio1 anio2 edad1 edad2 sexo
by entidad anio1 anio2 edad1 edad2 sexo: g n = _n
replace anio1 = anio1 + n
drop anio2 n
rename anio1 anio

* 2.2 Se distribuyen entre edades *
expand edad2-edad1+1
replace emigrantes = emigrantes/(edad2-edad1+1)
replace inmigrantes = inmigrantes/(edad2-edad1+1)
sort entidad anio edad1 edad2 sexo
by entidad anio edad1 edad2 sexo: g n = _n
replace edad1 = edad1 + n - 1
drop edad2 n
rename edad1 edad


** 3. Guardar **
tempfile migracion
save "`migracion'"





***************/
*** D. Union ***
****************

** 1. Base de datos (temporales) **
use "`poblacion'", clear
merge 1:1 (anio edad sexo entidad) using "`defunciones'", nogen
merge 1:1 (anio edad sexo entidad) using "`migracion'", nogen


** 2. Limpia **
replace poblacion = 0 if poblacion == .
replace emigrantes = 0 if emigrantes == .
replace inmigrantes = 0 if inmigrantes == .

replace entidad = "Nacional" if substr(entidad,1,3) == "Rep"
replace entidad = "Estado de México" if entidad == "M?xico" | entidad == "México"


** 3. Labels y formato *
label var anio "Año"
label var sexo "Sexo"
label var edad "Edad"
label var entidad "Entidad federativa"
label var poblacion "Población"
label var emigrantes "Emigrantes internacionales"
label var inmigrantes "Inmigrantes internacionales"
label var defunciones "Defunciones"
format poblacion defunciones *migrantes %10.0fc


** 4. Tasa de fertilidad **
tempvar mujeresf nacimien nacimientos mujeresfert
egen `mujeresf' = sum(poblacion) if edad >= 16 & edad <= 49 & sexo == 2, by(anio)
egen `nacimien' = sum(poblacion) if edad == 0, by(anio)
egen `nacimientos' = mean(`nacimien'), by(anio)
egen `mujeresfert' = mean(`mujeresf'), by(anio)

g tasafecundidad = `nacimientos'/`mujeresfert'*1000
tabstat tasafecundidad, stat(mean) by(anio) f(%10.1fc) save
label var tasafecundidad "Nacimientos por cada mil mujeres"


** 5. Guardar bases SIM **
order anio sexo edad entidad poblacion defunciones
drop cve_geo 
capture drop __*
compress
capture mkdir "`c(sysdir_personal)'/SIM/"

if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/Poblacion.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/Poblacion.dta", replace
}

collapse (sum) poblacion, by(anio entidad)
keep if entidad == "Nacional"
if `c(version)' > 13.1 {
	saveold `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', replace
}
