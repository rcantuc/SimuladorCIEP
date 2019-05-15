************************************************
**** Base de datos: Población y Defunciones ****
************************************************

********************
*** A. Poblacion ***
********************

**********************
** 1. Base de datos **
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/pob_mit_proyecciones.csv", clear


* 2. Limpia *
rename ao anio
rename sexo sexo0
encode sexo0, generate(sexo)

drop renglon sexo0
format poblacion %20.0fc


* 3. Labels *
label var poblacion "Poblaci{c o'}n"
label var entidad "Entidad federativa"
label var anio "A{c n~}o"


* 4. Orden *
replace entidad = "Nacional" if entidad == "República Mexicana"
keep if entidad == "Nacional"


* 5. Guardar *
save `"`c(sysdir_site)'../basesCIEP/SIM/Poblacion.dta"', replace

if "$graphs" == "on" {
	poblaciongraphs poblacion
}

collapse (sum) poblacion, by(anio entidad cve_geo)
save `"`c(sysdir_site)'../basesCIEP/SIM/Poblaciontot.dta"', replace




***************
* Defunciones *
* 1. Base de datos *
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/def_edad_proyecciones.csv", clear


* 2. Limpia *
rename ao anio
rename sexo sexo0
encode sexo0, generate(sexo)

drop renglon sexo0
format defunciones %20.0fc


* 3. Labels *
label var defunciones "Defunciones"
label var entidad "Entidad federativa"
label var anio "A{c n~}o"


* 4. Orden *
replace entidad = "Nacional" if entidad == "República Mexicana"
keep if entidad == "Nacional"


* 5. Guardar *
save `"`c(sysdir_site)'../basesCIEP/SIM/Defunciones.dta"', replace

if "$graphs" == "on" {
	poblaciongraphs defunciones
}

collapse (sum) defunciones, by(anio entidad cve_geo)
save `"`c(sysdir_site)'../basesCIEP/SIM/Defuncionestot.dta"', replace
