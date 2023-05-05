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
PIBDeflactor, nographs aniovp(`=aniovp')
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
	replace `k' = $pib2023 in -1
	rename `k' ITAEE``j''
	local ++j
}
reshape long ITAEE, i(anio) j(entidad) string

** Merge **
merge 1:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio) using `PIBDeflactor', nogen keepus(deflator pibY)

encode entidad, gen(entidadx)
xtset entidadx anio
replace pibYEnt = L.pibYEnt*(1+ITAEE/100)*deflator if pibYEnt == .

tempfile PIBEntidades
save `PIBEntidades'



******************************************/
*** 2. Poblacion por Entidad Federativa ***
*******************************************
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/ENOE/Población ocupada.xls", clear
drop if B == ""
drop AI

rename A periodo
split periodo, g(periodo)
drop periodo2 periodo3
rename periodo4 anio
drop periodo

rename periodo1 trimestre
replace trimestre = "1" if trimestre == "Primer"
replace trimestre = "2" if trimestre == "Segundo"
replace trimestre = "3" if trimestre == "Tercer"
replace trimestre = "4" if trimestre == "Cuarto"

order anio trimestre
order B, last
local j = 1
foreach k of varlist C-AH B {
	rename `k' ``j''
	local ++j
}
drop in 1
destring _all, replace

local j = 1
foreach k of global entidadesC {
	rename `k' poblacionOcupada``j''
	local ++j
}
reshape long poblacionOcupada, i(anio trimestre) j(entidad) string
destring poblacionOcupada anio, replace
collapse (mean) poblacionOcupada, by(anio entidad)
format poblacionOcupada %15.0fc
tempfile poblacionOcupada
save `poblacionOcupada'

local j = 1
foreach k in $entidadesL {
	Poblacion if entidad == "`k'", nographs
	
	g pob1664 = poblacion if edad >= 16 & edad <= 64
	replace pob1664 = 0 if pob1664 == .
	
	collapse (sum) pob*, by(entidad anio)
	format pob* %15.0fc
	rename entidad entidad1
	g entidad = "``j''"

	tempfile Pob``j''
	if "`basepobuse'" == "" {
		local basepobuse `"`Pob``j'''"'
	}
	else {
		local basespobappend `"`basespobappend' `Pob``j'''"'
	}
	save `Pob``j'''
	local ++j
}
use `basepobuse', clear
append using `basespobappend'
tempfile PobTot
save `PobTot'



*****************************************/
*** 3. Gasto Federalizado y sus Fondos ***
/******************************************
DatosAbiertos XFA0000, nographs
split nombre, gen(entidad) parse(":")
drop nombre
rename entidad2 concepto
g entidad = "Nacional"
tempfile XFA0000
save `XFA0000'

DatosAbiertos XAC4330, nographs
rename nombre concepto
g entidad = "Ciudad de México"
tempfile XAC4330
save `XAC4330'

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

** Obtener las bases de Datos Abiertos **
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
		local basesEstOporappend `"`basesEstOporappend' `XAC`gastofed'`fondo''"'
		save `XAC`gastofed'`fondo''
	}
}

** Unir todas las bases obtenidas **
use `XFA0000', clear
append using `XAC4330'
append using `basesEstOporappend'
replace entidad = "Nac" if entidad == ""
tempfile GastoFedBase
save `GastoFedBase'



**********************************/
*** 4. INGRESOS LOCALES / INEGI ***
***********************************
*capture mkdir "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal"
*cd "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal"
*unzipfile "https://www.inegi.org.mx/contenidos/programas/finanzas/datosabiertos/efipem_estatal_csv.zip", replace

*capture mkdir "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/CDMX"
*cd "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/CDMX"
*unzipfile "https://www.inegi.org.mx/contenidos/programas/finanzas/datosabiertos/efipem_cdmx_csv.zip", replace

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
	*sort id_entidad


	************************************
	** 4.2 Creación de bases INGRESOS **
	************************************
	keep if tema == "Ingresos"
	replace descripcion_categoria = "Aportaciones Federales" if descripcion_categoria == "Aportaciones federales"

	/** Acentos **
	foreach k of varlist descripcion_categoria {
		replace `k' = trim(`k')

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
	}

	** Variables auxiliares **/
	g aux = .
	levelsof categoria, local(cates)
	g capitulo   = "JP"
	g concepto   = "JP"
	g partida    = "JP"
	g subpartida = "JP"

	local i = 1
	foreach cate of local cates {
		display "`cate'"
		replace aux = `i' if categoria=="`cate'"
		local i = `i' + 1
	}
	replace capitulo   = descripcion_categoria if aux == 1
	replace concepto   = descripcion_categoria if aux == 2
	replace partida    = descripcion_categoria if aux == 3
	replace subpartida = descripcion_categoria if aux == 4

	** Para corroborar después **
	preserve 
	keep if aux==5
	keep id_entidad valor
	tempfile totales
	save "`totales'"
	restore
	
	** Expandimos capitulo **
	drop if aux==5
	local mis_vars capitulo
	foreach var of local mis_vars {
		forvalues k=2(1)`=_N'{
			if `var'[`k'] == "JP" {
				replace `var'=`var'[`=`k'-1'] in `k'
			}
		}
	}

	** Expandimos concepto **
	local mis_vars concepto
	foreach var of local mis_vars {
		local conceptoAnterior = capitulo[1]
		forvalues k=2(1)`=_N'{
			if `var'[`k'] == "JP" & capitulo[`k'] == "`conceptoAnterior'" {
				replace `var'=`var'[`=`k'-1'] in `k'
			}
			local conceptoAnterior = capitulo[`k']
		}
	}

	** Expandimos partida **
	local mis_vars partida
	foreach var of local mis_vars {
		local conceptoAnterior = concepto[1]
		forvalues k=2(1)`=_N'{
			if `var'[`k'] == "JP" & concepto[`k'] == "`conceptoAnterior'" {
				replace `var'=`var'[`=`k'-1'] in `k'
			}
			local conceptoAnterior = concepto[`k']
		}
	}


	***************************
	** 4.3 Limpia de la base ** 
	***************************
	g borrador=0

	** Limpiamos capitulo **
	local nombreDespues = capitulo[1]
	forvalues k=1(1)`=_N'{
		local nombreDespues = capitulo[`k']	
		if "`nombreDespues'" != "JP" {
			if capitulo[`=`k'+1'] == "`nombreDespues'" & concepto[`k'] == "JP" {
				replace borrador = 1 in `k'	
			}
		}
	}
	keep if borrador == 0

	** Limpiamos concepto **
	local nombreDespues = concepto[1]
	forvalues k=1(1)`=_N'{
		local nombreDespues = concepto[`k']	
		if "`nombreDespues'" != "JP" {
			if concepto[`=`k'+1'] == "`nombreDespues'" & partida[`k'] == "JP" {
				replace borrador = 1 in `k'	
			}
		}
	}
	keep if borrador == 0

	** Limpiamos partida **
	local nombreDespues = partida[1]
	forvalues k=1(1)`=_N'{
		local nombreDespues = partida[`k']
		if "`nombreDespues'" != "JP" {
			if partida[`=`k'+1'] == "`nombreDespues'" & subpartida[`k'] == "JP" {
				replace borrador = 1 in `k'	
			}
		}
	}
	keep if borrador == 0


	**********************************************
	** 4.4 Comprobar que los valores están bien **
	/**********************************************
	collapse(sum) valor ,by(id_entidad)
	rename valor valor_colapsado
	merge 1:1 id_entidad using "`totales'"
	g cuadrador=valor_colapsado-valor
	format cuadrador %20.1fc


	*************************/
	** 4.5 Bases temporales **
	**************************
	tempfile `anio'
	if "`baseuse'" == "" {
		local baseuse `"``anio''"'
	}
	else {
		local basesappend `"`basesappend' ``anio''"'
	}
	keep anio id_entidad valor capitulo concepto partida subpartida
	format valor %20.1fc
	save "``anio''", replace
}


*******************************
** 4.6 Base final LIEs_INEGI **
*******************************
use `baseuse', clear
append using `basesappend'

** Limpiamos los últimos auxiliares **
replace concepto   = capitulo if concepto == "JP"
replace partida    = concepto if partida == "JP"
replace subpartida = partida  if subpartida == "JP"

** División CIEP **
g divCIEP = ""
replace divCIEP = "Recursos Propios" if capitulo == "Aprovechamientos" | ///
	capitulo == "Contribuciones de Mejoras" | capitulo == "Derechos" | ///
	capitulo == "Disponibilidad inicial" | capitulo == "Impuestos" | ///
	capitulo == "Productos"

replace divCIEP = "Federalizado" if capitulo == "Aportaciones Federales" 
replace divCIEP = "Federalizado" if capitulo == "Participaciones federales"
replace divCIEP = "Organismos y empresas" if capitulo == "Cuotas y Aportaciones de Seguridad Social" | capitulo == "Otros ingresos"
replace divCIEP = "Financiamiento" if capitulo == "Financiamiento"
replace divCIEP = "Federalizado" if concepto == "Recursos federales reasignados" //& capitulo == "Aportaciones Federales" 


** Le ponemos nombre a las entidades **
*tempfile temporal_INEGI
*save "`temporal_INEGI'"
*import delimited "`c(sysdir_site)'../BasesCIEP/UPDATE/Subnacional/estatal/catalogos/tc_entidad.csv", encoding(UTF-8) clear
*merge 1:m (id_entidad) using "`temporal_INEGI'", nogen

g entidad = ""
forvalues k=1(1)32 {
	replace entidad = "``k''" if id_entidad == `k'
}

** Guardar **
drop id_entidad
order anio entidad capitulo concepto partida subpartida divCIEP valor
sort entidad anio capitulo concepto partida subpartida

tempfile LIEs_INEGI
save `LIEs_INEGI'



*********************
*** 5. BASE FINAL ***
*********************
use `PIBEntidades', clear
merge 1:m (anio entidad) using `LIEs_INEGI', nogen
merge m:1 (anio entidad) using `PobTot', nogen update replace
merge m:1 (anio entidad) using `poblacionOcupada', nogen
keep if anio >= 2003 & anio <= 2022
save "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", replace

use `PIBEntidades', clear
merge 1:m (anio entidad) using `GastoFedBase', nogen
merge m:1 (anio entidad) using `PobTot', nogen
merge m:1 (anio entidad) using `poblacionOcupada', nogen
keep if anio >= 2003 & anio <= 2022
save "`c(sysdir_personal)'/SIM/EstadosBaseEstOpor.dta", replace
