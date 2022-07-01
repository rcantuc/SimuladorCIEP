clear all
macro drop _all
capture log close _all

local entidadesN `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
local entidades "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nacional"
tokenize `entidades'

global export "`c(sysdir_site)'../../Hewlett Subnacional/Documento LaTeX/images"





*********************
*** PIB Entidades ***
/*********************
import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/PIB entidades federativas.xlsx", clear
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



*** PIB Deflactor ***
PIBDeflactor, nographs
tempfile PIBDeflactor
save `PIBDeflactor'



*** ITAEE ***
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

merge 1:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio) using `PIBDeflactor', nogen keepus(deflator)

encode entidad, gen(entidadx)
xtset entidadx anio
replace pibYEnt = L.pibYEnt*(1+ITAEE/100)*deflator if pibYEnt == .

keep if anio >= 2003 & anio <= 2022
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", replace





***************************************/
*** Poblacion por Entidad Federativa ***
/****************************************
local j = 1
foreach k of local entidadesN {
	Poblacion if entidad == "`k'", nographs
	collapse (sum) pob*, by(entidad anio)
	format pob* %15.0fc
	rename entidad entidad1
	g entidad = "``j''"
	scalar poblacion``j'' = poblaciontotal
	tempfile Pob``j''
	save `Pob``j'''
	local ++j
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
noisily scalarlatex, logname(pob)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", replace





**************************************/
*** Gasto Federalizado y sus Fondos ***
/***************************************
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
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedBase.dta", replace





*************************************************/
*** Graficas 1 Gasto Federalizado (Capitulo 1) ***
*************************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedBase.dta", clear
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2013 & anio <= 2022

tempvar concepto2 montograph montopibYE
g `concepto2' = "Participaciones" if substr(clave,1,5) == "XAC28" & strlen(clave) == 8
replace `concepto2' = "Aportaciones" if substr(clave,1,5) == "XAC33" & strlen(clave) == 8
replace `concepto2' = "Subsidios" if substr(clave,1,5) == "XAC23" & strlen(clave) == 8
replace `concepto2' = "Convenios" if (substr(clave,1,5) == "XACCD" & strlen(clave) == 8) ///
	| (substr(clave,1,5) == "XACCR" & strlen(clave) == 7)
replace `concepto2' = "Subsidios" if substr(clave,1,6) == "XACPSS"
encode `concepto2', g(concepto2)

replace concepto2 = 5 if clave == "XFA0000"
label define concepto2 5 "Resto RFP", modify


* 1.-32. Gasto Federalizado total por tipo y por estados *
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(anio entidad concepto2 `concepto2')
g montograph = monto/poblacion/deflator
levelsof entidad, local(entidades)
foreach k of local entidades {
	graph bar (mean) montograph if entidad == "`k'" [fw=poblacion], ///
		over(concepto2, sort(1) descending) ///
		over(anio) ///
		asyvar stack ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(on) ///
		name(GasFed`k', replace)
	graph export "$export/GasFed_`k'.png", replace name(GasFed`k')

}

* Scalares *
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2021 {
		scalar `=substr(`concepto2'[`k'],1,4)'`=entidad[`k']' = montograph[`k']
	}
}


* 33. Distribución de la RFP *
preserve
collapse (sum) monto poblacion (mean) deflator if concepto2 != ., by(anio concepto2 `concepto2')
tempvar rfpResto rfpRestoSum

g rfpResto = monto if concepto2 != 5
egen rfpRestoSum = sum(rfpResto), by(anio)
replace monto = monto - rfpRestoSum if concepto2 == 5
g montograph = monto/poblacion/deflator

graph bar (mean) montograph [fw=poblacion], ///
	over(concepto2, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1) label(5 "Resto RFP (Federaci{c o'}n)")) ///
	name(RFP, replace)
graph export "$export/RFP.png", replace name(RFP)

* Scalars *
forvalues k=1(1)`=_N' {
	scalar GasFed`=substr(`concepto2'[`k'],1,4)' = montograph[`k']
}
scalar GasFedGasFed = GasFedApor + GasFedConv + GasFedPart + GasFedSubs


restore
preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
g montograph = monto/poblacion/deflator
g montopibYE = monto/pibYEnt*100

* Scalars *
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2021 {
		scalar GasFed`=entidad[`k']' = montograph[`k']
		scalar GasFedPIB`=entidad[`k']' = montopibYE[`k']
	}
}

restore
collapse (sum) monto, by(entidad anio)
g tipo_ingreso = "Federalizado"
drop if anio == 2022
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedSum.dta", replace
noisily scalarlatex, logname(gastofed)





*************************************************/
*** Graficas 2 Gasto Federalizado (Capitulo 1) ***
**************************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedBase.dta", clear
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2013 & anio <= 2022

tempvar concepto2 montograph montopibYE
g `concepto2' = "Participaciones" if substr(clave,1,5) == "XAC28" & strlen(clave) == 8
replace `concepto2' = "Aportaciones" if substr(clave,1,5) == "XAC33" & strlen(clave) == 8
replace `concepto2' = "Subsidios" if substr(clave,1,5) == "XAC23" & strlen(clave) == 8
replace `concepto2' = "Convenios" if (substr(clave,1,5) == "XACCD" & strlen(clave) == 8) ///
	| (substr(clave,1,5) == "XACCR" & strlen(clave) == 7)
replace `concepto2' = "Subsidios" if substr(clave,1,6) == "XACPSS"
encode `concepto2', g(concepto2)

replace concepto2 = 5 if clave == "XFA0000"
label define concepto2 5 "Resto RFP", modify

keep if concepto2 != .
g conceptograph = trim(concepto)
g inicial = strpos(concepto,"(")
g final = strpos(concepto,")")


* Participaciones *
replace conceptograph = "0.136% de la RFP" if conceptograph == "0.136% de la Recaudaci?n Federal Participable"
replace conceptograph = "FGP" if conceptograph == "Fondo General de Participaciones"
replace conceptograph = "FFM" if conceptograph == "Fondo de Fomento Municipal"
replace conceptograph = "Repecos" if conceptograph == "Fondo de Compensaci?n de Repecos Intermedios"
replace conceptograph = "Fiscalización" if conceptograph == "Fondo de Fiscalizaci?n a Entidades Federativas"
replace conceptograph = "FExHi" if conceptograph == "Fondo de Extracci?n de Hidrocarburos"
replace conceptograph = "FExHi" if conceptograph == "Participaciones por el Derecho Adicional sobre la Extracci?n de Petr?leo"
replace conceptograph = "IEPS" if conceptograph == "Participaciones por el Impuesto Especial sobre Producci?n y Servicios (IEPS)"
replace conceptograph = "IEPS" if conceptograph == "Participaciones por el Impuesto Especial sobre Producci?n y Servicios de Gasolinas y Diesel (IEPS Gasolinas) Art?culo 2?.-A Fracci?n II Ley del IEPS"
replace conceptograph = "ISAN" if conceptograph == "Participaciones por el Impuesto sobre Autom?viles Nuevos (ISAN)"
replace conceptograph = "Tenencia" if conceptograph == "Participaciones por el Impuesto sobre Tenencia y Uso de Autom?viles"
replace conceptograph = "Incentivos económicos" if conceptograph == "Incentivos Econ?micos"


* 34. Participaciones *
preserve
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if anio <= 2021 & concepto2 == 3 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2)) ///
	name(XAC28, replace)
graph export "$export/XAC28.png", replace name(XAC28)


* 35. Aportaciones *
restore
preserve
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if concepto2 == 1
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if anio <= 2021 & concepto2 == 1 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2)) ///
	name(XAC33, replace)
graph export "$export/XAC33.png", replace name(XAC33)


* 36. Convenios *
restore
preserve
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if concepto2 == 2
replace conceptograph = "Reasignación" if conceptograph == "Convenios de Reasignaci?n"
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if anio <= 2021 & concepto2 == 2 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACC, replace)
graph export "$export/XACC.png", replace name(XACC)


* 37. Subsidios *
restore
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if concepto2 == 4 & inicial != 0 & final != 0
replace conceptograph = "Protecci{c o'}n Social en Salud" if concepto == " Recursos para Protecci?n Social en Salud"
replace conceptograph = "Otros subsidios" if concepto == " Resto del Gasto Federalizado del Ramo Provisiones Salariales y Economicas y Otros Subsidios"
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if concepto2 == 4 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACSubsidios, replace)
graph export "$export/XACSubsidios.png", replace name(XACSubsidios)




exit
*****************/
*** LIEs INEGI ***
******************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", clear
replace entidad = trim(entidad)
/*capture replace entidad1 = "México" if entidad1 == "Mexico"
capture replace entidad1 = "Ciudad de México" if entidad1 == "CDMX"
capture replace entidad1 = "San Luis Potosí" if entidad1 == "San Luis Potosi"
capture replace Entidades = lower(entidad1) if entidad1 != "" & Entidades == ""
foreach k of varlist Entidades /*entidad1 desc_entidad*/ {
	capture replace `k'= subinstr(`k', "{c a'}","á",.)
	capture replace `k'= subinstr(`k', "{c e'}","é",.)
	capture replace `k'= subinstr(`k', "{c i'}","í",.)
	capture replace `k'= subinstr(`k', "{c o'}","ó",.)
	capture replace `k'= subinstr(`k', "{c u'}","ú",.)
}

replace Entidades = subinstr(Entidades," ","",.)
local j = 1
drop entidad
g entidad = trim(desc_entidad)
if _rc != 0 {
	g entidad = ""
}
replace entidad = "EdoMex" if entidad == "Edomex"
replace entidad = "QRoo" if entidad == "Qroo"

foreach k of local entidadesN {
	replace entidad = "``j''" if Entidades == `"`=subinstr("`=lower("`k'")'"," ","",.)'"'
	local ++j
}
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", replace*/

collapse (sum) monto, by(anio entidad tipo_ingreso)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs_colapsada.dta", replace





**********************************************/
*** Grafica 3 Recursos totales (Capitulo 2) ***
***********************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs_colapsada.dta", clear
merge 1:1 (anio entidad tipo_ingreso) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedSum.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2018 & anio <= 2022
drop if entidad == "Nacional"
********************************************
**Estimar Impuestos faltante 2021
********************************************
tempvar montograph
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/IngresosEntidades.dta", replace


* 38. Recursos totales *
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio tipo_ingreso)
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . & tipo_ingreso != "Financiamiento" [fw=poblacion], ///
	over(tipo_ingreso, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(LIEs, replace)
graph export "$export/LIEs.png", replace name(LIEs)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_TipoIngreso_Total.dta", replace

* 39.-71. Recursos totales *
levelsof entidad, local(entidades)
foreach k of local entidades {
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" & tipo_ingreso != "Financiamiento" [fw=poblacion], ///
		over(tipo_ingreso, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) ///
		name(LIEs_`k', replace)
	graph export "$export/LIEs_`k'.png", replace name(LIEs_`k')
}
drop `montograph'
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_tipoingreso.dta", replace


* Scalars *
reshape wide monto poblacion pibYEnt, i(anio tipo_ingreso) j(entidad) string
reshape long
g `montograph' = monto/poblacion/deflator
replace `montograph' = . if round(`montograph') == 0

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Federalizado" {
		scalar LIEFed`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Propios" {
		scalar LIERec`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Organismos y empresas" {
		scalar LIEOyE`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Financiamiento" {
		scalar LIEFin`=entidad[`k']' = `montograph'[`k']
	}
}

preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt if anio == 2022, by(anio entidad)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
		scalar LIETot`=entidad[`k']' = `montograph'[`k']
		scalar LIETotPIB`=entidad[`k']' = monto[`k']/pibYEnt[`k']*100

}


restore
collapse (sum) monto poblacion (mean) deflator, by(anio tipo_ingreso)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Federalizado" {
		scalar LIEFedNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Propios" {
		scalar LIERecNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Organismos y empresas" {
		scalar LIEOyENac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Financiamiento" {
		scalar LIEFinNac = `montograph'[`k']
	}
}
scalar LIETotNac = LIEFedNac+LIERecNac+LIEOyENac+LIEFinNac
noisily scalarlatex, logname(gastotot)






***************************************/
**Recursos Propios
****************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", replace
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2018 & anio <= 2022
keep if tipo_ingreso=="Propios"

*preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt if tipo_ingreso == "Propios", by(entidad anio concepto_propio)
tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(concepto, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(Recursos_prop, replace)
graph export  "$export/Recursos_prop.png", as(png) replace name(Recursos_prop)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIES_RP.dta", replace

*******Checkpoint************
levelsof entidad, local(entidades)
foreach k of local entidades {
	noisily di "*`k'*"
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(concepto, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) ///
		name(RPdesag_`k', replace)
	graph export  "$export/RPdesag_`k'.png", as(png) replace name(RPdesag_`k')
}


replace concepto_propio = "Otros" if concepto_propio == ""
preserve
collapse (sum) monto `montograph' (mean) poblacion deflator pibYEnt, by(entidad anio concepto_propio)
reshape wide monto `montograph' deflator pibYEnt, i(anio entidad) j(concepto) string
reshape long
replace `montograph' = . if `montograph' == 0

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Aprovechamientos" {
		scalar RPaprov`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Derechos" {
		scalar RPder`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos" {
		scalar RPimp`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros" {
		scalar RPotros`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Productos" {
		scalar RPprod`=entidad[`k']' = `montograph'[`k']
	}
}

collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
g montograph = monto/poblacion/deflator
g montopibYE = monto/pibYEnt*100

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTot`=entidad[`k']' = montograph[`k']
		scalar RePrPIB`=entidad[`k']' = montopibYE[`k']
	}
}

restore
collapse (sum) monto poblacion (mean) deflator, by(anio concepto)
g montograph = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Aprovechamientos" {
		scalar RPaprovNac= montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Contribuciones" {
		scalar RPcontriNac= montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Derechos" {
		scalar RPderNac= montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos" {
		scalar RPimpNac = montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros" {
		scalar RPotrosNac = montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Productos" {
		scalar RPprodNac= montograph[`k']
	}
}
collapse (sum) monto poblacion (mean) deflator, by(anio)
g montograph = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTotNac = montograph[`k']
	}
}

noisily scalarlatex, logname(Recursos_propios)













































exit
*************************************************************************************
*IMPUESTOS
***********************************************************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", replace

merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2018 & anio <= 2022
keep if tipo_ingreso=="Recursos Propios"

replace concepto_desagregado="Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" if concepto_desagregado=="Impuesto sobre la producci{c o'}n, el consumo y las transacciones"
replace concepto_desagregado="Impuestos Sobre Ingresos" if concepto_desagregado=="Impuesto sobre los Ingresos" 
replace concepto_desagregado="Otros Impuestos" if concepto_desagregado=="Otros impuestos"
replace concepto_desagregado="ISN" if concepto_tipo=="ISN"
*preserve
keep if concepto=="Impuestos"
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio tipo_ingreso concepto_desagregado)

tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(concepto_desagregado, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2) label(4 "Impuesto Sobre La Producción," "Consumo Y Las Transacciones")) ///
	name(Impuestos, replace)
graph export  "$export/`=strtoname("Impuestos")'.png", as(png) replace 
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_Impuestos.dta", replace
*******Checkpoint************
levelsof entidad, local(entidades)

foreach k of local entidades {
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(concepto_desagregado, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) name(Impuestos_`k', replace)
	graph export  "$export/`=strtoname("Impuestos_`k'")'.png", as(png) replace 
}


drop `montograph'

****************************

*Checkponit*

***************************
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio concepto)

*reshape wide monto poblacion, i(anio concepto deflator pibYEnt) j(entidad) string
*reshape long
g `montograph' = monto/poblacion/deflator
preserve

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Accesorios" {
		scalar ImpAcc`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Adicionales" {
		scalar ImpAdi`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "ISN" {
		scalar ImpISN`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" {
		scalar ImpConsu`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Ingresos" {
		scalar ImpIng`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Patrimonio" {
		scalar ImpPatri`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Impuestos" {
		scalar ImpOtros`=entidad[`k']' = `montograph'[`k']
	}
	
}
restore
preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
g `montopibYE' = monto/pibYEnt*100

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar ImpTot`=entidad[`k']' = `montograph'[`k']
		scalar ImpPIB`=entidad[`k']' = `montopibYE'[`k']
	}
}
restore
preserve
collapse (sum) monto poblacion (mean) deflator, by(anio concepto)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Accesorios" {
		scalar ImpAccNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Adicionales" {
		scalar ImpAdiNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "ISN" {
		scalar ImpISNNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" {
		scalar ImpConsuNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Ingresos" {
		scalar ImpIngNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Patrimonio" {
		scalar ImpPatriNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Impuestos" {
		scalar ImpOtrosNac = `montograph'[`k']
	}
}


restore
collapse (sum) monto poblacion (mean) deflator, by(anio)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar ImpTotNac = `montograph'[`k']
	}
}

noisily scalarlatex, logname(Impuestos)


