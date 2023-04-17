*****************************
*** UPDATE Base Entidades ***
*****************************
tokenize $entidadesC



**********************
*** 1. PIB Estatal ***
**********************
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/PIB entidades federativas.xlsx", clear
LimpiaBIE
rename A anio
local j = 1
foreach k of varlist B-AG {
	rename `k' pibYEnt``j''
	local ++j
}
reshape long pibYEnt, i(anio) j(entidad) string
tempfile PIBEntidades
save `PIBEntidades'

** PIB Deflactor **
PIBDeflactor, nographs
tempfile PIBDeflactor
save `PIBDeflactor'

** ITAEE **
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/ITAEE.xlsx", clear
LimpiaBIE, nomultiply
split A, parse("/")
drop A
rename A1 anio
rename A2 trimestre
destring anio trimestre, replace
order anio trimestre

collapse (mean) B-AG, by(anio)
set obs `=_N+1'
replace anio = anio[_N-1]+1 in -1

local j = 1
foreach k of varlist B-AG {
	replace `k' = 3.4 in -1
	rename `k' ITAEE``j''
	local ++j
}
reshape long ITAEE, i(anio) j(entidad) string

** Merge **
merge 1:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio) using `PIBDeflactor', nogen keepus(deflator)

encode entidad, gen(entidadx)
xtset entidadx anio
replace pibYEnt = L.pibYEnt*(1+ITAEE/100)*deflator if pibYEnt == .

keep if anio >= 2003 & anio <= 2022

tempfile PIBEntidades
save `PIBEntidades'



******************************************/
*** 2. Poblacion por Entidad Federativa ***
*******************************************
local j = 1
foreach k of global entidadesL {
	Poblacion if entidad == "`k'", nographs
	
	g pob1664 = poblacion if edad >= 16 & edad <= 64
	replace pob1664 = 0 if pob1664 == .
	
	collapse (sum) pob*, by(entidad anio)
	format pob* %15.0fc
	rename entidad entidad1
	g entidad = "``j''"

	tempfile Pob``j''
	save `Pob``j'''
	local ++j

	scalar poblacion``j'' = poblaciontotal
}
local j = 1
forvalues k=1(1)33 {
	if `k' == 1 {
		use `Pob``j''', clear
	}
	else {
		append using `Pob``j'''
	}
	local ++j
}
drop entidad1
*noisily scalarlatex, logname(pob)
tempfile PobTot
save `PobTot'



*****************************************/
*** 3. Gasto Federalizado y sus Fondos ***
******************************************
DatosAbiertos XFA0000, nographs
split nombre, gen(entidad) parse(":")
drop nombre
replace entidad1 = "Nacional"
rename entidad2 concepto
tempfile XFA0000
save `XFA0000'

local series28 `""" A B C D E F G H I J K L M"'
*local series28 `""""'

local series33 `""" A B C D E F G H I J K L M N O"'
*local series33 `""""'

local series23 `""" A B C"'
*local series23 `""""'

local seriesCD `""" A D E"'
*local seriesCD `""""'

local seriesCR `""""'

local seriesPSS `""""'

* Obtener las bases de Datos Abiertos *
foreach gastofed in 28 33 PSS 23 CD CR {
	foreach fondo of local series`gastofed' {

		local serie "XAC`gastofed'`fondo'"
		local j = 1

		forvalues k=1(1)32 {
			noisily DatosAbiertos `serie'`=string(`k',"%02.0f")', nographs
			if r(error) != 2000 {
				* Limpiar base intermedia *
				split nombre, gen(entidad) parse(":")
				drop nombre
				rename entidad2 concepto
				g entidad = "``j''"
			}

			* Guardar bases estados *
			tempfile `serie'`=string(`k',"%02.0f")'
			save ``serie'`=string(`k',"%02.0f")''
			local ++j
		}

		* Unir bases estados *
		use ``serie'01', clear
		forvalues k=2(1)32 {
			append using ``serie'`=string(`k',"%02.0f")''
		}
		tempfile XAC`gastofed'`fondo'
		save `XAC`gastofed'`fondo''
	}
}

* Unir todas las bases obtenidas *
local j = 0
foreach gastofed in 28 33 PSS 23 CD CR {
	foreach fondo of local series`gastofed' {
		if `j' == 0 {
			use `XAC`gastofed'', clear
			local ++j
		}
		else {
			append using `XAC`gastofed'`fondo''
		}
	}
}
append using `XFA0000'
replace entidad = "Nacional" if entidad == ""
tempfile GastoFedBase
save `GastoFedBase'



***********************************
*** 4. INGRESOS LOCALES / INEGI ***
***********************************
*cd "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal"
*unzipfile "https://www.inegi.org.mx/contenidos/programas/finanzas/datosabiertos/efipem_estatal_csv.zip", replace

*cd "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/CDMX"
*unzipfile "https://www.inegi.org.mx/contenidos/programas/finanzas/datosabiertos/efipem_cdmx_csv.zip", replace

*import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/conjunto_de_datos/efipem_estatal_anual_tr_cifra_2021.csv", clear varnames(1) case(lower)

cd "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional"

forvalues anio=2018(1)2021 {
	
	import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal/conjunto_de_datos/efipem_estatal_anual_tr_cifra_`anio'.csv", encoding(UTF-8) clear
	tempfile estados
	save "`estados'"

	import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/CDMX/conjunto_de_datos/efipem_cdmx_anual_tr_cifra_`anio'.csv", encoding(UTF-8) clear
	append using "`estados'"
	replace descripcion_categoria="Aportaciones Federales" if descripcion_categoria=="Aportaciones federales"
	foreach k of varlist descripcion_categoria {
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
	gen aux=.
	keep if tema == "Ingresos"
	*sort categoria
	levelsof categoria, local(cates)
	g capitulo="JP"
	g concepto="JP"
	g partida="JP"
	g subpartida="JP"

	local i = 1
	foreach cate of local cates {
		display "`cate'"
		replace aux = `i' if categoria=="`cate'"
		local i = `i' + 1
	}

	replace capitulo=descripcion_categoria if aux==1
	replace concepto=descripcion_categoria if aux==2
	replace partida=descripcion_categoria if aux==3
	replace subpartida=descripcion_categoria if aux==4

	*para corroborar despues
	preserve 
	keep if aux==5
	keep id_entidad valor
	tempfile totales
	save "`totales'"
	restore

	drop if aux==5

	*expandimos capitulo
	local mis_vars capitulo
	foreach var of local mis_vars {
		forvalues k=2(1)`=_N'{
			if `var'[`k']=="JP"{
				replace `var'=`var'[`=`k'-1'] in `k'
			}
		}
	}
	*expandimos concepto
	local mis_vars concepto
	foreach var of local mis_vars {
		local conceptoAnterior = capitulo[1]
		forvalues k=2(1)`=_N'{
			if `var'[`k']=="JP" & capitulo[`k'] == "`conceptoAnterior'" {
				replace `var'=`var'[`=`k'-1'] in `k'
			}
			local conceptoAnterior = capitulo[`k']
		}
	}

	*expandimos partida
	local mis_vars partida
	foreach var of local mis_vars {
		local conceptoAnterior = concepto[1]
		forvalues k=2(1)`=_N'{
			if `var'[`k']=="JP" & concepto[`k'] == "`conceptoAnterior'" {
				replace `var'=`var'[`=`k'-1'] in `k'
			}
			local conceptoAnterior = concepto[`k']
		}
	}
	********************************************************************************
	*limpiar 
	********************************************************************************
	g borrador=0

	local limpia capitulo
	foreach var of local limpia {
		local nombreDespues = capitulo[1]
		forvalues k=1(1)`=_N'{
			local nombreDespues = capitulo[`k']	
			if "`nombreDespues'" != "JP"{
				if capitulo[`=`k'+1']== "`nombreDespues'" & concepto[`k']=="JP"{
				replace borrador=1 in `k'	
				display "`k'"	
				}
			}
		}
	}

	keep if borrador==0

	*limpiamos concepto
	local limpia concepto
	foreach var of local limpia {
		local nombreDespues = concepto[1]
		forvalues k=1(1)`=_N'{
			local nombreDespues = concepto[`k']	
			if "`nombreDespues'" != "JP"{
				if concepto[`=`k'+1']== "`nombreDespues'" & partida[`k']=="JP"{
					replace borrador=1 in `k'	
					display "`k'"	
				}
			}
		}
	}
	keep if borrador==0

	*limpiamos partida
	local limpia partida
	foreach var of local limpia {
		local nombreDespues = partida[1]
		forvalues k=1(1)`=_N'{
			local nombreDespues = partida[`k']
			if "`nombreDespues'" != "JP"{
				if partida[`=`k'+1']== "`nombreDespues'" & subpartida[`k']=="JP"{
					replace borrador=1 in `k'	
					display "`k'"	
				}
			}
		}
	}

	*keep if id_entidad==2
	format valor %20.1fc
	 
	keep if borrador==0
	keep anio id_entidad valor capitulo concepto partida subpartida

	*Lo que sigue es para corroborar
	tempfile `anio'
	save "``anio''", replace
/*collapse(sum) valor ,by(id_entidad)
rename valor valor_colapsado
merge 1:1 id_entidad using "`totales'"
g cuadrador=valor_colapsado-valor
format cuadrador %20.1fc
*/
}
append using "`2018'" "`2019'" "`2020'" 
*Generamos nuestra división CIEP
g DivCIEP=""
replace DivCIEP="Recursos Propios" if capitulo=="Aprovechamientos" | ///
		capitulo=="Contribuciones de Mejoras" | capitulo=="Derechos" | ///
		capitulo=="Disponibilidad inicial" | capitulo=="Impuestos" | ///
		capitulo=="Productos"
replace DivCIEP="Federalizado aportaciones" if capitulo=="Aportaciones Federales" 

replace DivCIEP="Federalizado partcipaciones" if capitulo== "Participaciones federales"
replace DivCIEP="Organismos y empresas" if capitulo=="Cuotas y Aportaciones de Seguridad Social" | ///
	capitulo=="Otros ingresos"
replace DivCIEP="Financiamiento" if capitulo=="Financiamiento"
replace DivCIEP="Federalizado convenios" if concepto=="Recursos federales reasignados" & capitulo=="Aportaciones Federales" 

*Limpiamos los últimos auxiliares
replace concepto=capitulo if concepto=="JP"
replace partida=concepto if partida=="JP"
replace subpartida=partida if subpartida=="JP"

tempfile temporal_INEGI
save "`temporal_INEGI'"


import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal/catalogos/tc_entidad.csv", encoding(UTF-8) clear

merge 1:m id_entidad using "`temporal_INEGI'", nogen
order anio id_entidad nom_ent capitulo concepto partida subpartida DivCIEP valor
sort anio id_entidad nom_ent capitulo concepto partida subpartida

save "`c(sysdir_personal)'/SIM/LIEs_INEGI.dta", replace
*Le ponemos nombre a las entidades




















******************
*** BASE FINAL ***
******************
use `GastoFedBase', clear
merge m:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio entidad) using `PobTot', nogen
save "`c(sysdir_personal)'/SIM/EstadosBase.dta", replace
