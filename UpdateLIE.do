clear all
macro drop _all
capture log close _all

global export "/home/ciepmx/Dropbox (CIEP)/Hewlett Subnacional/Documento LaTeX/images"
*global export "/Users/ricardo/Dropbox (CIEP)/Hewlett Subnacional/Documento LaTeX/images"

local entidadesN `"  "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional"    "'
local entidades "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac"
tokenize `entidades'





/*******
* LIEs *
********
import excel "/Users/ricardo/Dropbox (CIEP)/Hewlett Subnacional/Base de datos/LIE/LIE.xlsx", sheet("Data") firstrow clear


foreach k of varlist desc_* {
	* Limpiar los espacios dobles, inciales o finales *
	replace `k' = trim(`k')
	* Limpia de acentos en minúsculas *
	replace `k' = subinstr(`k',"á","{c a'}",.)
	replace `k' = subinstr(`k',"é","{c e'}",.)
	replace `k' = subinstr(`k',"í","{c i'}",.)
	replace `k' = subinstr(`k',"ó","{c o'}",.)
	replace `k' = subinstr(`k',"ú","{c u'}",.)
	* Limpia de acentos en mayúsculas *
	replace `k' = subinstr(`k',"Á","{c A'}",.)
	replace `k' = subinstr(`k',"É","{c E'}",.)
	replace `k' = subinstr(`k',"Í","{c I'}",.)
	replace `k' = subinstr(`k',"Ó","{c O'}",.)
	replace `k' = subinstr(`k',"Ú","{c U'}",.)
	* Limpia de la ñ *
	replace `k' = subinstr(`k',"ñ","{c n~}",.)
	replace `k' = subinstr(`k',"Ñ","{c N~}",.)

	*table `k'
}

levelsof desc_concepto, local(desc_concepto)
foreach k of local desc_concepto {
	bysort desc_entidad: tabstat monto if desc_concepto == "`k'", stat(sum) by(ciclo) format(%20.0fc)
}

replace entidad1 = "Estado de M{c e'}xico" if entidad1 == "M?xico" | entidad1 == "México"
replace entidad1 = "Michoac{c a'}n" if entidad1 == "Michoac?n" | entidad1 == "Michoacán"
replace entidad1 = "Nuevo Le{c o'}n" if entidad1 == "Nuevo Le?n" | entidad1 == "Nuevo León"
replace entidad1 = "Quer{c e'}taro" if entidad1 == "Quer?taro" | entidad1 == "Querétaro"
replace entidad1 = "San Luis Potos{c i'}" if entidad1 == "San Luis Potos?" | entidad1 == "San Luis Potosí"
replace entidad1 = "Yucat{c a'}n" if entidad1 == "Yucat?n" | entidad1 == "Yucatán"

****************/
* PIB Entidades *
*****************


* Poblacion *
local j = 1
foreach k of local entidadesN {
	Poblacion if entidad == "`k'", nographs
	collapse (sum) pob*, by(entidad anio)
	format pob* %10.0fc
	rename entidad entidad1
	g entidad = "``j''"
	scalar poblacion``j'' = poblaciontotal
	tempfile Pob``j''
	save `Pob``j'''
	local ++j
}

local j = 1
forvalues k=1(1)32 {
	if `k' == 1 {
		use `Pob``j''', clear
	}
	else {
		append using `Pob``j'''
	}
	local ++j
}
noisily scalarlatex, logname(pob)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", replace


* ITAEE */
*noisily run "`c(sysdir_personal)'/Arranque.do"
import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/ITAEE.xlsx", clear
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
tempfile ITAEE
save `ITAEE'


* PIB Deflactor *
PIBDeflactor, nographs
tempfile PIBDeflactor
save `PIBDeflactor'


* PIB Entidades *
import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/PIB entidades federativas.xlsx", clear
LimpiaBIE

rename A anio
local j = 1
foreach k of varlist B-AG {
	rename `k' pibYEnt``j''
	local ++j
}
reshape long pibYEnt, i(anio) j(entidad) string


* Agregar ITAEE y poblacion estatal *
merge 1:1 (anio entidad) using `ITAEE', nogen
merge 1:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
merge m:1 (anio) using `PIBDeflactor', nogen keepus(deflator)
encode entidad, gen(entidadx)
xtset entidadx anio
replace pibYEnt = L.pibYEnt*(1+ITAEE/100)*deflator if pibYEnt == .
drop if pibYEnt == .
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", replace



*******************************/
* Participaciones y sus fondos *
********************************
*local series28 `""" A B C D E F G H I J K L M"'
local series28 `"""'
*local series33 `""" A B C D E F G H I J K L M N O"'
local series33 `""""'
local seriesPSS `""""'
*local series23 `""" A B C"'
local series23 `""""'
*local seriesCD `""" A D E"'
local seriesCD `""""'
local seriesCR `""""'
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


			* Guardar base intermedia *
			tempfile `serie'`=string(`k',"%02.0f")'
			save ``serie'`=string(`k',"%02.0f")''
			local ++j
		}

		use ``serie'01'
		forvalues k=2(1)32 {
			append using ``serie'`=string(`k',"%02.0f")''
		}
		merge 1:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
		keep if anio >= 2013
		replace concepto = trim(concepto)
		
		tempfile XAC`gastofed'
		save `XAC`gastofed''
	}
}


use `XAC28', clear
append using `XAC33'
append using `XACPSS'
append using `XAC23'
append using `XACCD'
append using `XACCR'
drop if clave == ""

* Graficas *
*g monto_graph = monto/pibYEnt*100
g monto_graph = monto/poblacion/deflator


g concepto2 = "Participaciones" if substr(clave,4,2) == "28"
replace concepto2 = "Aportaciones" if substr(clave,4,2) == "33"
replace concepto2 = "Protecci{c o'}n Social en Salud" if substr(clave,4,3) == "PSS"
replace concepto2 = "Provisiones Salariales" if substr(clave,4,2) == "23"
replace concepto2 = "Convenios" if substr(clave,4,2) == "CD" | substr(clave,4,2) == "CR"


graph bar (mean) monto_graph if monto_graph != . & anio <= 2021 [fw=poblacion], over(concepto2, sort(4) descending) over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1) order(3 1 2 4 5)) ///
	name(GastoFed, replace)
graph export "$export/GastoFed.png", replace name(GastoFed)


preserve
collapse (mean) monto_graph if monto_graph != . & anio == 2021, by(entidad concepto2)
forvalues k=1(1)`=_N' {
	scalar `=substr(concepto2[`k'],1,4)'`=entidad[`k']' = monto_graph[`k']
}
collapse (sum) monto_graph if monto_graph != ., by(entidad)
forvalues k=1(1)`=_N' {
	scalar GasFed`=entidad[`k']' = monto_graph[`k']
}
restore
collapse (mean) monto_graph if monto_graph != . & anio == 2021 [fw=poblacion], by(concepto2)
forvalues k=1(1)`=_N' {
	scalar GasFed`=substr(concepto2[`k'],1,4)' = monto_graph[`k']
}
scalar GasFedGasFed = GasFedApor + GasFedConv + GasFedPart + GasFedProt + GasFedProv
noisily scalarlatex, logname(gastofed)


/*
tempvar rank montorecibido
egen `montorecibido' = mean(monto_graph), by(entidad)
egen `rank' = rank(`montorecibido') if anio == 2022, field
egen rank = mean(`rank'), by(entidad)
*replace entidad = entidad + " (" + string(rank) + ")"


local length = length("`=concepto[_N]'")
if `length' > 60 {
	local textsize ", size(medium)"
}
if `length' > 90 {
	local textsize ", size(vsmall)"
}
if `length' > 110 {
	local textsize ", size(vsmall)"
}


tabstat rank, stat(max) save
if r(StatTotal)[1,1] != . {
	graph bar monto_graph if monto_graph != . & rank >= 1 & rank <= 10, over(entidad, sort(rank)) over(anio) ///
		stack asyvar ///
		title({bf:`=concepto[_N]'}`textsize') ///
		subtitle(Por entidad federativa: Primeros 10) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(rows(1)) ///
		name(`serie'1, replace)
	graph export "$export/`serie'1.png", replace name(`serie'1)

	tabstat rank, stat(max) save
	if r(StatTotal)[1,1] > 10 {
		graph bar monto_graph if monto_graph != . & rank >= 11 & rank <= 20, over(entidad, sort(rank)) over(anio) ///
			stack asyvar ///
			title({bf:`=concepto[_N]'}`textsize') ///
			subtitle(Por entidad federativa: Del 11 al 20) ///
			ytitle("per c{c a'}pita (MXN 2022)") ///
			ylabel(, format(%7.0fc)) ///
			blabel(bar, format(%7.0fc)) ///
			legend(rows(1)) ///
			name(`serie'2, replace)
		graph export "$export/`serie'2.png", replace name(`serie'2)
	}

	tabstat rank, stat(max) save
	if r(StatTotal)[1,1] > 20 {
		graph bar monto_graph if monto_graph != . & rank >= 21, over(entidad, sort(rank)) over(anio) ///
			stack asyvar ///
			title({bf:`=concepto[_N]'}`textsize') ///
			subtitle(Por entidad federativa: Del 21 al 32) ///
			ytitle("per c{c a'}pita (MXN 2022)") ///
			ylabel(, format(%7.0fc)) ///
			blabel(bar, format(%7.0fc)) ///
			legend(rows(1)) ///
			name(`serie'3, replace)
		graph export "$export/`serie'3.png", replace name(`serie'3)
	}
}*/

