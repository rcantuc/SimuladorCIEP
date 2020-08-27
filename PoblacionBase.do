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
rename año anio
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
saveold `"`c(sysdir_site)'../basesCIEP/SIM/Poblacion.dta"', replace version(13)

collapse (sum) poblacion, by(anio entidad cve_geo)
saveold `"`c(sysdir_site)'../basesCIEP/SIM/Poblaciontot.dta"', replace version(13)




**********************
*** B. Defunciones ***
**********************

********************
* 1. Base de datos *
import delimited "http://www.conapo.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/def_edad_proyecciones.csv", clear


* 2. Limpia *
rename año anio
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

if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'../basesCIEP/SIM/Defunciones.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'../basesCIEP/SIM/Defunciones.dta"', replace
}

collapse (sum) defunciones, by(anio entidad cve_geo)

if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'../basesCIEP/SIM/Defuncionestot.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'../basesCIEP/SIM/Defuncionestot.dta"', replace
}
