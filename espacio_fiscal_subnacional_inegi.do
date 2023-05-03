clear all
macro drop _all
capture log close all
*Arreglamos acentos de la descripción
*cd "C:\Users\Admin\CIEP Dropbox\Juan Pablo López\Hewlett Subnacional\Base de datos\LIE\INEGI\bases originales"
*********************************
*Base ingresos
*********************************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta" , replace
keep if anio>2012
sort capitulo
drop if entidad=="Nac"
*cambiar aquí si se quiere usar el financiamiento
drop if capitulo=="Financiamiento"
*preserve
collapse (sum) valor (mean) deflator pob* pib* , by(anio entidad1) 
rename valor ingresos
rename entidad1 entidad
tempfile ingresos
save "`ingresos'"


forvalues anio=2013(1)2021 {

	***************
	** 4.1 Bases **
	***************

	** Bases de estados **
	import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal/conjunto_de_datos/efipem_estatal_anual_tr_cifra_`anio'.csv", encoding(UTF-8) clear
	tempfile estados
	save "`estados'"

	** Bases de la CDMX **
	import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/CDMX/conjunto_de_datos/efipem_cdmx_anual_tr_cifra_`anio'.csv", encoding(UTF-8) clear
	append using "`estados'"
	
	keep anio id_entidad tema categoria descrip* valor
	*keep if id_entidad==9
	
	keep if (tema=="Egresos" & categoria=="Capítulo" & descripcion_categoria=="Deuda pública") ///
	| (tema=="Egresos" & categoria=="Capítulo" & descripcion_categoria=="Servicios personales") ///
	| (tema=="Egresos" & categoria=="Capítulo" & (descripcion_categoria=="Recursos asignados a municipios"| descripcion_categoria=="Recursos asignados a alcaldías de la Ciudad de México y sector paraestatal")) ///
	| (tema=="Egresos"& descripcion_categoria=="Pensiones y jubilaciones") ///
	| (tema=="Ingresos" & categoria=="Subpartida Genérica" & descripcion_categoria=="FA para Nómina Educativa y Gasto Operativo") ///
	| (tema=="Ingresos" & categoria=="Subpartida Genérica" & descripcion_categoria=="FA para Infraestructura Social Estatal") ///
	| (tema=="Ingresos" & categoria=="Subpartida Genérica" & descripcion_categoria=="FA Múltiples") 
	
	
	
	
	rename descripcion_categoria GI_
	
	*encode descripcion_categoria, generate(GI_) label(mylabel)
	drop tema anio categoria
	replace GI_="Servicio_Deuda" if GI_=="Deuda pública"
	replace GI_="Servicio_Personales" if GI_=="Servicios personales"
	replace GI_="Servicio_GF" if GI_=="Recursos asignados a municipios" |GI_=="Recursos asignados a alcaldías de la Ciudad de México y sector paraestatal"
	replace GI_="FONE_O" if GI_=="FA para Nómina Educativa y Gasto Operativo"
	replace GI_="FAIS" if GI_=="FA para Infraestructura Social Estatal"
	replace GI_="FAM" if GI_=="FA Múltiples"
	replace GI_="Servicio_Pensiones" if GI_=="Pensiones y jubilaciones"

	*Hacemos reshape 
	reshape wide valor, i(id_entidad) j(GI_) string
	rename valor* *
	tempfile ineludible
	save "`ineludible'"
	*Ponemos nombres
	import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal/catalogos/tc_entidad.csv", encoding(UTF-8) clear
	merge 1:1 id_entidad using "`ineludible'", nogen
	rename nom_ent entidad
	gen anio="`anio'"
	destring anio, replace
	*encode anio_, generate(anio)
	*drop anio_
	*Arreglamos nombres distintos
	tostring id_entidad, replace
	replace entidad="Coahuila" if entidad=="Coahuila de Zaragoza"
	replace entidad="Michoacán" if entidad=="Michoacán de Ocampo"
	replace entidad="Estado de México" if entidad=="México"
	replace entidad="Veracruz" if entidad=="Veracruz de Ignacio de la Llave"
	*Guardamos por año
	tempfile `anio'
	if "`baseuse'" == "" {
		local baseuse `"``anio''"'
	}
	else {
		local basesappend `"`basesappend' ``anio''"'
	}
	save "``anio''", replace
}

use `baseuse', clear
append using `basesappend'
*Agregamos ingresos
merge 1:1 entidad anio using "`ingresos'"
*quitamos . y ponemos 0
foreach var of varlist FAIS FAM FONE_O Servicio_Deuda Servicio_GF Servicio_Personales Servicio_Pensiones{
    display "`var'"
	replace `var'=0 if `var'==.
}
*Cálculos
g ef_=ingresos-( Servicio_Deuda + Servicio_GF + Servicio_Personales+ Servicio_Pensiones)
g g_inelu=Servicio_Deuda + Servicio_GF + Servicio_Personales+ Servicio_Pensiones
format %20.0fc ef_ FAIS FAM FONE_O Servicio_Deuda Servicio_GF Servicio_Personales g_inelu
g ef_real=(ef_/poblacion)/deflator
g ingresos_real=(ingresos/poblacion)/deflator
*Graficamos pero conservamos la base
preserve
collapse (sum) ingresos g_inelu poblacion (mean) deflator, by(anio)
g espacio_fiscal=ingresos-g_inelu
g espacio_real=espacio_fiscal/deflator
g espacio_real_pc=espacio_real/poblacion
*drop if anio==2022
twoway line espacio_real_pc anio 

restore
*sort  anio ef_
*save "`c(sysdir_personal)'/SIM/espacio_fiscal_inegi_subnacional.dta", replace
*keep if anio==2021