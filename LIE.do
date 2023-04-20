global export "`c(sysdir_personal)'../../EU/LaTeX/images/"



*************************
*** Población estatal ***
/*************************
foreach entidad of global entidadesL {
	noisily Poblacion if entidad == "`entidad'", aniofinal(2050) $update //anio(`piramide')
}
noisily scalarlatex, log(poblacion)



****************************/
*** Productividad laboral ***
/*****************************
use "`c(sysdir_personal)'/SIM/EstadosBaseEstOpor.dta", clear
collapse (mean) pob* deflator pibYEnt, by(anio entidad entidadx)
sort entidadx anio

g montograph = pibYEnt/poblacionOcupada/deflator
g montograph2 = ((pibYEnt/deflator)/(L.pibYEnt/L.deflator)-1)*100

local h = 1
tokenize `"$entidadesL"'
foreach k of global entidadesC {
	if "`k'" == "Nac" {
		continue
	}

	* Texto sobre gráficas *
	forvalues j=1(1)`=_N' {
		if entidad[`j'] == "`k'" & montograph[`j'] != . {
			local textgraph`k' `"`textgraph`k'' `=montograph[`j']' `=anio[`j']' "{bf:`=string(montograph[`j'],"%10.0fc")'}" "'
			local textgraph2`k' `"`textgraph2`k'' `=montograph2[`j']' `=anio[`j']' "{bf:`=string(montograph2[`j'],"%7.1fc")'%}" "'
		}
		if entidad[`j'] == "`k'" & montograph[`j'] != . & anio[`j'] == 2022 {
			scalar pibYEnt`k' = string(pibYEnt[`j']/deflator[`j']/1000000,"%15.0fc")
			scalar pibYEnt`k'pc = string(montograph[`j'],"%15.0fc")
		}
	}

	* Gráfica crecimiento *
	twoway connect montograph2 anio if entidad == "`k'" & montograph != ., ///
		title("{bf:Crecimiento} económico") ///
		subtitle("``h''") ///
		ytitle("PIB estatal por {bf:persona ocupada}") ///
		ylabel(, format(%7.1fc)) yscale(range(0)) ///
		xlabel(2005(1)2022) xtitle("") ///
		text(`textgraph2`k'', size(vsmall)) ///
		caption("{bf:Fuente}: Elaboración propia, con información del INEGI/BIE.") ///
		name(Crecimiento_`k', replace)

	if "$export" != "" {
		graph export "$export/Crecimiento_`k'.png", replace name(Crecimiento_`k')
	}

	* Gráfica productividad *
	twoway connect montograph anio if entidad == "`k'" & montograph != ., ///
		title("{bf:Productividad} laboral") ///
		subtitle("``h''") ///
		ytitle("PIB estatal por {bf:persona ocupada}") ///
		ylabel(0(100000)820000, format(%10.0fc)) yscale(range(0)) ///
		xlabel(2005(1)2022) xtitle("") ///
		text(`textgraph`k'', size(vsmall)) ///
		caption("{bf:Fuente}: Elaboración propia, con información del INEGI/BIE e INEGI/ENOE.") ///
		name(Productividad_`k', replace)

	if "$export" != "" {
		graph export "$export/Productividad_`k'.png", replace name(Productividad_`k')
	}
	local ++h
}
noisily scalarlatex, log(pibYEnt)




*************************/
*** Gasto Federalizado ***
/**************************
use "`c(sysdir_personal)'/SIM/EstadosBaseEstOpor.dta", clear
keep if anio >= 2003 & anio <= 2022

tempvar concepto2
g `concepto2' = "Participaciones" if substr(clave,1,5) == "XAC28" & strlen(clave) == 8
replace `concepto2' = "Aportaciones" if substr(clave,1,5) == "XAC33" & strlen(clave) == 8
replace `concepto2' = "Subsidios" if substr(clave,1,5) == "XAC23" & strlen(clave) == 8
replace `concepto2' = "Convenios" if (substr(clave,1,5) == "XACCD" & strlen(clave) == 8) ///
	| (substr(clave,1,5) == "XACCR" & strlen(clave) == 7)
replace `concepto2' = "Subsidios" if substr(clave,1,6) == "XACPSS"
encode `concepto2', g(concepto2)
replace concepto2 = 5 if clave == "XFA0000"
label define concepto2 5 "Resto RFP", modify


** 1-32 Gasto Federalizado total por tipo y por estados **
collapse (sum) monto (mean) poblacion deflator pibYEnt if concepto2 != ., by(anio entidad concepto2 `concepto2')

local h = 1
tokenize `"$entidadesL"'
g montograph = monto/poblacion/deflator
foreach k of global entidadesC {
	graph bar (mean) montograph if entidad == "`k'" [fw=poblacion], ///
		over(concepto2, sort(1) descending) ///
		over(anio) ///
		asyvar stack ///
		title(Gasto {bf:federalizado}) ///
		subtitle(``h'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(0(10000)30000, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(on) ///
		caption("{bf:Fuente}: Elaboración propia, con información del SHCP/Estadísticas Oportunas y CONAPO.") ///
		name(GasFed`k', replace)

	if "$export" != "" {
		graph export "$export/GasFed_`k'.png", replace name(GasFed`k')
	}
	local ++h
}

* Scalares *
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2021 {
		scalar `=substr(`concepto2'[`k'],1,4)'`=entidad[`k']' = montograph[`k']
	}
}

* 33. Distribución de la RFP *
collapse (sum) monto poblacion (mean) deflator if concepto2 != ., by(anio concepto2 `concepto2')

g rfpResto = monto if concepto2 != 5
egen rfpRestoSum = sum(rfpResto), by(anio)
replace monto = monto - rfpRestoSum if concepto2 == 5

g montograph = monto/poblacion/deflator
graph bar (mean) montograph [fw=poblacion], ///
	over(concepto2, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1) label(5 "Federaci{c o'}n")) ///
	name(RFP, replace)

if "$export" != "" {
	graph export "$export/RFP.png", replace name(RFP)
}





************************************/
*** Graficas 2 Gasto Federalizado ***
/************************************
use "`c(sysdir_personal)'/SIM/EstadosBaseEstOpor.dta", clear
keep if anio >= 2003 & anio <= 2022

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
replace conceptograph = "0.136% de la RFP" if conceptograph == "0.136% de la Recaudaci?n Federal Participable" ///
	| conceptograph == "0.136% de la Recaudación Federal Participable"
replace conceptograph = "FGP" if conceptograph == "Fondo General de Participaciones"
replace conceptograph = "FFM" if conceptograph == "Fondo de Fomento Municipal"
replace conceptograph = "Repecos" if conceptograph == "Fondo de Compensaci?n de Repecos Intermedios" ///
	| conceptograph == "Fondo de Compensación de Repecos Intermedios"
replace conceptograph = "Fiscalización" if conceptograph == "Fondo de Fiscalizaci?n a Entidades Federativas" ///
	| conceptograph == "Fondo de Fiscalización a Entidades Federativas"
replace conceptograph = "FExHi" if conceptograph == "Fondo de Extracci?n de Hidrocarburos" ///
	| conceptograph == "Fondo de Extracción de Hidrocarburos"
replace conceptograph = "FExHi" if conceptograph == "Participaciones por el Derecho Adicional sobre la Extracci?n de Petr?leo" ///
	| conceptograph == "Participaciones por el Derecho Adicional sobre la Extracción de Petróleo"
replace conceptograph = "IEPS" if conceptograph == "Participaciones por el Impuesto Especial sobre Producci?n y Servicios (IEPS)" ///
	| conceptograph == "Participaciones por el Impuesto Especial sobre Producción y Servicios (IEPS)"
replace conceptograph = "IEPS" if conceptograph == "Participaciones por el Impuesto Especial sobre Producci?n y Servicios de Gasolinas y Diesel (IEPS Gasolinas) Art?culo 2?.-A Fracci?n II Ley del IEPS" ///
	| conceptograph == "Participaciones por el Impuesto Especial sobre Producción y Servicios de Gasolinas y Diesel (IEPS Gasolinas) Artículo 2º.-A Fracción II Ley del IEPS"
replace conceptograph = "ISAN" if conceptograph == "Participaciones por el Impuesto sobre Autom?viles Nuevos (ISAN)" ///
	| conceptograph == "Participaciones por el Impuesto sobre Automóviles Nuevos (ISAN)"
replace conceptograph = "Tenencia" if conceptograph == "Participaciones por el Impuesto sobre Tenencia y Uso de Autom?viles" ///
	| conceptograph == "Participaciones por el Impuesto sobre Tenencia y Uso de Automóviles"
replace conceptograph = "Incentivos" if conceptograph == "Incentivos Econ?micos" ///
	| conceptograph == "Incentivos Económicos"


* 34. Participaciones *
preserve
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if concepto2 == 3 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	title({bf:Participaciones}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XAC28, replace)

if "$export" != "" {
	graph export "$export/XAC28.png", replace name(XAC28)
}


* 35. Aportaciones *
restore
preserve
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if concepto2 == 1
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if concepto2 == 1 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	title({bf:Aportaciones}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XAC33, replace)

if "$export" != "" {
	graph export "$export/XAC33.png", replace name(XAC33)
}


* 36. Convenios *
restore
preserve
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if concepto2 == 2
replace conceptograph = "Reasignación" if conceptograph == "Convenios de Reasignaci?n" ///
	| conceptograph == "Convenios de Reasignación"
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if concepto2 == 2 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	title({bf:Convenios}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACC, replace)
	
if "$export" != "" {
	graph export "$export/XACC.png", replace name(XACC)
}

* 37. Subsidios *
restore
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if concepto2 == 4 & inicial != 0 & final != 0
replace conceptograph = "Protección Social en Salud" if concepto == " Recursos para Protecci?n Social en Salud" ///
	| concepto == " Recursos para Protección Social en Salud"
replace conceptograph = "Otros subsidios" if concepto == " Resto del Gasto Federalizado del Ramo Provisiones Salariales y Economicas y Otros Subsidios"
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
g montograph = monto/poblacion/deflator
graph bar (mean) montograph if concepto2 == 4 [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	title({bf:Subsidios}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACSubsidios, replace)

if "$export" != "" {
	graph export "$export/XACSubsidios.png", replace name(XACSubsidios)
}



*****************/
*** LIEs INEGI ***
/******************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
keep if valor != .
rename valor monto

* 38. Recursos totales *
collapse (sum) monto (mean) poblacion deflator pibYEnt /*if divCIEP != "Financiamiento"*/, by(entidad anio divCIEP)

replace divCIEP = strtoname(divCIEP)
reshape wide monto, i(anio entidad poblacion pibYEnt deflator) j(divCIEP) string
collapse (sum) monto* (mean) poblacion deflator pibYEnt /*if divCIEP != "Financiamiento"*/, by(entidad anio)
reshape long
replace divCIEP = subinstr(divCIEP,"_"," ",.)

tempvar montograph
g `montograph' = monto/poblacion/deflator

preserve
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion] , ///
	over(divCIEP, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(LIEs, replace)
if "$export" != "" {
	graph export "$export/LIEs.png", replace name(LIEs)
}


* 1-32 Recursos totales *
restore
tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	if "`k'" == "Nac" {
		continue
	}
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(divCIEP, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		title(Recursos {bf:estatales}) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		name(LIEs_`k', replace)
	if "$export" != "" {
		graph export "$export/LIEs_`k'.png", replace name(LIEs_`k')
	}
	local ++j
}





***********************/
*** Recursos Propios ***
************************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
keep if valor != .
rename valor monto

collapse (sum) monto (mean) poblacion deflator pibYEnt if divCIEP == "Recursos Propios", by(entidad anio concepto)

tempvar montograph
g `montograph' = monto/poblacion/deflator

graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(concepto, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	title(Recursos {bf:propios}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(Recursos_prop, replace)

if "$export" != "" {
	graph export  "$export/Recursos_prop.png", as(png) replace name(Recursos_prop)
}

tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	if "`k'" == "Nac" {
		continue
	}
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(concepto, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		title(Recursos {bf:propios}) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		name(Recursos_prop`k', replace)
	
	if "$export" != "" {
		graph export  "$export/Recursos_prop`k'.png", as(png) replace name(Recursos_prop`k')
	}
	local ++j
}





****************/
*** Impuestos ***
*****************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
keep if valor != .
rename valor monto

collapse (sum) monto (mean) poblacion deflator pibYEnt if capitulo == "Impuestos", by(entidad anio concepto)

tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(concepto, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	title({bf:Impuestos} locales) ///
	///subtitle(Por entidad federativa) ///
	ytitle("por residente (MXN `=aniovp')") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	name(Impuestos, replace)

if "$export" != "" {
	graph export  "$export/Impuestos.png", as(png) replace 
}


tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	if "`k'" == "Nac" {
		continue
	}
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(concepto, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		title({bf:Impuestos} locales) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) name(Impuestos_`k', replace)

	if "$export" != "" {
		graph export  "$export/Impuestos_`k'.png", as(png) replace 
	}
	local ++j
}















exit










restore
* Scalars *
drop `montograph'
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















collapse (sum) monto `montograph' (mean) poblacion deflator pibYEnt, by(entidad anio concepto_propio)
reshape wide monto `montograph' deflator pibYEnt, i(anio entidad) j(concepto) string
reshape long
replace `montograph' = . if `montograph' == 0
preserve
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

*tempfile aux_final
*save "`aux_final'"
*use "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\PobTot.dta" , replace
*keep if anio==2022
*merge 1:m entidad using "`aux_final'"
*exit
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
scalar RPTotNac = RPaprovNac + RPderNac + RPimpNac+ RPotrosNac + RPprodNac
/*collapse (sum) monto poblacion (mean) deflator, by(anio)
g montograph = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTotNac = montograph[`k']
	}
}
*/
noisily scalarlatex, logname(Recursos_propios)













































exit
*************************************************************************************
*IMPUESTOS
***********************************************************************************


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


