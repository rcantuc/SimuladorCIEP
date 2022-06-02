clear all
macro drop _all
capture log close all

global data "`c(sysdir_site)'/../../Hewlett Subnacional/Base de datos/LIE/INEGI"

local entidadesN `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
local entidades "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nacional"
tokenize `entidades'



*********************************************************
*** Ingresos de las entidades federativas (2018-2020) ***
*********************************************************
forvalues anio=2018(1)2020 {
	import delimited "$data/INEGI_`anio'.csv", clear
	drop if v4 == ""
	foreach k of varlist _all {
		rename `k' `=strtoname(`k'[1])'
	}
	drop in 1
	drop in -1
	drop _Total
	destring _all, replace ignore(",")
	rename _ concepto
	
	*** Reshape ***************
	reshape long _@, i(concepto) j(Entidad, string)
	rename _ monto
	format monto %20.0fc

	*** Base lista ************
	gen anio=`anio'
	order anio Entidad concepto monto
	
	replace concepto = trim(concepto)
	drop if concepto == "Total" ///
		| concepto == "Impuestos" ///
		| concepto == "Impuesto sobre los Ingresos" ///
		| concepto == "Impuestos sobre el Patrimonio"

	tempfile `anio'
	save "``anio''"
}



***************************************
*** Ingresos de la CDMX (2018-2020) ***
***************************************
import delimited "$data/CDMX.csv", clear
drop if v4 == ""
foreach k of varlist _all {
	rename `k' `=strtoname(`k'[1])'
}
drop in 1
destring _all, replace ignore(",")
rename _ concepto

*** Reshape ***************
reshape long _, i(concepto) j(anio)
rename _ monto
format monto %20.0fc

replace concepto = trim(concepto)
drop if concepto == "Total" ///
	| concepto == "Impuestos" ///
	| concepto == "Impuesto sobre los Ingresos" ///
	| concepto == "Impuestos sobre el Patrimonio"

*** Base lista ************
g Entidad = "Ciudad_de_México"
order anio Entidad concepto monto
keep if anio >= 2018
tempfile cdmx
save "`cdmx'"



*******************
*** LIEs (2021) ***
*******************
import excel "$data/../LIE_2021.xlsx", firstrow clear
drop id_entidad I-K
rename desc_entidad entidad

tempfile 2021
save "`2021'"



*******************
*** LIEs (2022) ***
*******************
import excel "$data/../LIE_2022.xlsx", firstrow clear
rename ciclo anio
rename desc_tipo_ingreso tipo_ingreso

g Entidad = strtoname(desc_entidad)

replace tipo_ingreso = trim(tipo_ingreso)
keep if anio == 2022

replace tipo_ingreso = "Financiamiento" if tipo_ingreso == "Ingresos Derivados de Financiamiento" ///
	| tipo_ingreso == "Ingresos Derivados Del Financiamiento" ///
	| tipo_ingreso == "Ingresos Derivados De Financiamiento" ///
	| desc_concepto == "Ingresos Derivados De Financiamiento"
	
replace tipo_ingreso = "Federalizado" if tipo_ingreso == "Federales" ///
	| tipo_ingreso == "Federal" ///
	| desc_concepto == "Fondos Distintos De Aportaciones" ///
	| desc_concepto == "Participaciones" ///
	| desc_concepto == "Transferencias, Asignaciones, Subsidios Y Otras Ayudas" ///
	| desc_concepto == "Incentivos Derivados De La Colaboración Fiscal"

replace tipo_ingreso = "Organismos y empresas" if tipo_ingreso == "Organismos Y Empresas" ///
	| tipo_ingreso == "Ingresos Propios De Entidades Públicas, Autónomos Y Poderes" ///
	| tipo_ingreso == "Ingresos De Organismos Y Empresas" ///
	| tipo_ingreso == "Ingresos Organismos Y Empresas" ///
	| tipo_ingreso == "Aportaciones Y Cuotas De Seguridad Social" ///
	| desc_concepto == "Cuotas Y Aportaciones De Seguridad Social" ///
	| desc_concepto == "Ingresos Por Ventas De Bienes Y Servicios" ///
	| desc_concepto == "Ingresos Por Venta De Bienes Y Servicios" ///
	| desc_concepto == "Ingreso Por Ventas De Bienes Y Servicios"

replace tipo_ingreso = "Propios" if tipo_ingreso == "Superávit Del Ejercicio Anterior" ///
	| tipo_ingreso == "Recursos propios" ///
	| tipo_ingreso == "Recursos Fiscales" ///
	| tipo_ingreso == "Recursos Propios" ///
	| tipo_ingreso == "Contribuciones Especiales" ///
	| tipo_ingreso == "Remanentes" ///
	| desc_concepto == "Otros Ingresos"
	
* Especiales *
replace tipo_ingreso = "Federalizado" if desc_concepto == "Aportaciones" ///
	| desc_concepto == "Convenios"

drop id_entidad desc_entidad
tempfile 2022
save "`2022'"



**************/
*** Append ***
**************
use `2018', clear
append using "`2019'" "`2020'" "`cdmx'" "`2021'" "`2022'"
foreach k of varlist concepto {
	replace `k'= subinstr(`k', "á","{c a'}",.)
	replace `k'= subinstr(`k', "é","{c e'}",.)
	replace `k'= subinstr(`k', "í","{c i'}",.)
	replace `k'= subinstr(`k', "ó","{c o'}",.)
	replace `k'= subinstr(`k', "ú","{c u'}",.)
	replace `k'= subinstr(`k', "ñ","{c n~}",.)

	replace `k'= subinstr(`k', "Á","{c A'}",.)
	replace `k'= subinstr(`k', "É","{c E'}",.)
	replace `k'= subinstr(`k', "Í","{c I'}",.)
	replace `k'= subinstr(`k', "Ó","{c O'}",.)
	replace `k'= subinstr(`k', "Ú","{c U'}",.)
	replace `k'= subinstr(`k', "Ñ","{c N~}",.)
	*limpia espacios dobles o triples
	replace `k' = trim(`k')
}
compress
replace concepto = desc_concepto if anio == 2022


replace concepto = "Otros impuestos sobre ingresos" if concepto == "Remuneraciones al trabajo no subordinado" ///
	| concepto == "Ejercicio de profesiones y honorarios" ///
	| concepto == "Instrumentos p{c u'}blicos y operaciones contractuales"

replace concepto = "Otros impuestos sobre el patrimonio" if concepto == "Enajenaci{c o'}n de bienes muebles y adquisici{c o'}n de veh{c i'}culos" ///
	| concepto == "Traslado de dominio de bienes inmuebles" ///
	| concepto == "Adquisici{c o'}n de bienes inmuebles" ///
	| concepto == "Impuesto predial"



******************************************************************************************************
****** Tipo Ingreso***********************************************************************************
******************************************************************************************************
replace tipo_ingreso = "Propios" if concepto == "Impuesto sobre n{c o'}mina" ///
	| concepto == "Ejercicio de profesiones y honorarios" ///
	| concepto == "Impuesto sobre los Ingresos" ///
	| concepto == "Otros impuestos sobre ingresos" ///
	| concepto == "Remuneraciones al trabajo no subordinado" ///
	| concepto == "Traslado de dominio de bienes inmuebles" ///
	| concepto == "Otros impuestos sobre el patrimonio" ///
	| concepto == "Instrumentos p{c u'}blicos y operaciones contractuales" ///
	| concepto == "Impuesto sobre tenencia o uso de veh{c i'}culos" ///
	| concepto == "Enajenaci{c o'}n de bienes muebles y adquisici{c o'}n de veh{c i'}culos" ///
	| concepto == "Adquisici{c o'}n de bienes inmuebles" ///
	| concepto == "Contribuciones de mejoras" ///
	| concepto == "Derechos" ///
	| concepto == "Productos" ///
	| concepto == "Aprovechamientos" ///
	| concepto == "Disponibilidad inicial" ///
	| concepto == "Impuesto sobre la producci{c o'}n, el consumo y las transacciones" ///
	| concepto == "Adicionales" ///
	| concepto == "Accesorios" ///
	| concepto == "Otros impuestos" ///
	| concepto == "Otros Ingresos" ///
	| tipo_ingreso == "Recursos Propios"

replace tipo_ingreso = "Organismos y empresas" if concepto == "Cuotas y Aportaciones de Seguridad Social" ///
	| tipo_ingreso == "Ingresos Organismos Y Empresas" ///
	| concepto == "Otros ingresos"


replace tipo_ingreso = "Financiamiento" if concepto == "Financiamiento" ///
	| tipo_ingreso == "Ingresos Derivados Del Financiamiento"

replace tipo_ingreso = "Federalizado" if concepto == "Participaciones federales" ///
	| concepto == "Aportaciones federales" ///
	| tipo_ingreso == "Federal"



tempvar montomill
g `montomill' = monto/1000000
graph bar (sum) `montomill', over(tipo_ingreso) over(anio) ///
	stack asyvar ytitle(millones de MXN 2022) ///
	ylabel(, format(%20.0fc)) blabel(, format(%20.0fc)) ///
	legend(rows(1)) name(tipo_ingreso, replace)

	
	
g concepto_propios = concepto if tipo_ingreso == "Propios"
replace concepto_propios = "Impuestos" if concepto == "Impuesto sobre la producci{c o'}n, el consumo y las transacciones" ///
	| concepto == "Impuesto sobre los Ingresos" ///
	| concepto == "Impuesto sobre n{c o'}mina" ///
	| concepto == "Impuesto sobre tenencia o uso de veh{c i'}culos" ///
	| concepto == "Otros impuestos" ///
	| concepto == "Otros impuestos sobre el patrimonio" ///
	| concepto == "Otros impuestos sobre ingresos"

replace concepto_propios = "Otros" if concepto == "Accesorios" ///
	| concepto == "Adicionales" ///
	| concepto == "Contribuciones De Mejoras" ///
	| concepto == "Contribuciones de mejoras" ///
	| concepto == "Contribución O Aportación De Mejoras Por Obras Públicas" ///
	| concepto == "Disponibilidad inicial" ///
	| concepto == "Otros Ingresos" ///
	| concepto == "Otros ingresos"
	
replace concepto_propios = "Aprovechamientos" if concepto == "Accesorios De Los Aprovechamientos"

graph bar (sum) `montomill' if tipo_ingreso == "Propios", over(concepto_propios) over(anio) ///
	stack asyvar ytitle(millones de MXN 2022) ///
	ylabel(, format(%20.0fc)) blabel(, format(%20.0fc)) ///
	legend(rows(1)) name(propios, replace)
	

replace Entidad = subinstr(Entidad,"_"," ",.)
replace Entidad = trim(Entidad)
replace Entidad = "Coahuila" if Entidad == "Coahuila de Zaragoza"
replace Entidad = "Michoacán" if Entidad == "Michoacán de Ocampo"
replace Entidad = "Veracruz" if Entidad == "Veracruz de Ignacio de la Llave"
local j = 1
foreach k of local entidadesN {
	replace entidad = "``j''" if Entidad == "`k'"
	local ++j
}

capture drop _*
replace entidad = trim(entidad)
save "$data/LIEs.dta", replace	
