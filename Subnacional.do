***************************/
*** 1. Población estatal ***
/***************************
*forvalues anio=1950(1)2050 {
	foreach entidad in $entidadesL {
		noisily Poblacion if entidad == "`entidad'", $update //anio(`anio') //aniofinal(2030)
	}
*}




*******************************/
*** 2. Productividad laboral ***
/*******************************
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

	* 2.1 Gráfica crecimiento *
	twoway connect montograph2 anio if entidad == "`k'" & montograph != ., ///
		title("{bf:Crecimiento} económico") ///
		subtitle("``h''") ///
		ytitle("PIB estatal por {bf:persona ocupada}") ///
		ylabel(, format(%7.1fc)) yscale(range(0)) ///
		xlabel(2005(1)2022) xtitle("") ///
		text(`textgraph2`k'', size(vsmall)) ///
		caption("{bf:Fuente}: Elaboración propia, con información del INEGI/BIE.") ///
		name(Crecimiento_`k', replace)

	* 2.2 Gráfica productividad *
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
		graph export "$export/Crecimiento_`k'.png", replace name(Crecimiento_`k')
		graph export "$export/Productividad_`k'.png", replace name(Productividad_`k')
	}
	local ++h
}
noisily scalarlatex, log(pibYEnt)




****************************/
*** 3. Gasto Federalizado ***
/*****************************
use "`c(sysdir_personal)'/SIM/EstadosBaseEstOpor.dta", clear

g GasFed = 1 if substr(clave,1,5) == "XAC28" & strlen(clave) == 8
replace GasFed = 2 if substr(clave,1,5) == "XAC33" & strlen(clave) == 8
replace GasFed = 3 if substr(clave,1,5) == "XAC23" & strlen(clave) == 8
replace GasFed = 3 if substr(clave,1,6) == "XACPSS"
replace GasFed = 4 if (substr(clave,1,5) == "XACCD" & strlen(clave) == 8) | (substr(clave,1,5) == "XACCR" & strlen(clave) == 7)
replace GasFed = 5 if clave == "XFA0000"
label define GasFed 1 "Participaciones" 2 "Aportaciones" 3 "Subsidios" 4 "Convenios" 5 "Resto RFP"
label values GasFed GasFed

preserve
collapse (sum) monto (max) poblacion deflator pibYEnt if GasFed != ., by(anio entidad GasFed)
reshape wide monto, i(anio entidad) j(GasFed)
reshape long


** 2.1 Gasto Federalizado por tipo y estados **
local h = 1
tokenize `"$entidadesL"'
g montograph = monto/poblacion/deflator
foreach k of global entidadesC {
	if "`k'" == "Nac" {
		continue
	}

	graph bar (mean) montograph if entidad == "`k'" & GasFed != 5 [fw=poblacion], ///
		over(GasFed, sort(1) descending) ///
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

** 2.2 Distribución de la RFP **
collapse (sum) monto poblacion (max) deflator if GasFed != ., by(anio GasFed)

g rfp = monto if GasFed != 5
egen rfpRestoSum = sum(rfp), by(anio)
replace monto = monto - rfpRestoSum if GasFed == 5

g montograph = monto/poblacion/deflator
graph bar (mean) montograph [fw=poblacion], ///
	over(GasFed, sort(1) descending) ///
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


** 2.3 Gasto Federalizado por tipo **
restore
g conceptograph = trim(concepto)
g inicial = strpos(concepto,"(")
g final = strpos(concepto,")")

* 2.3.1 Participaciones *
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if inicial != 0 & final != 0
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
replace conceptograph = "Ramo 25" if conceptograph == "Gasto programable del Ramo Previsiones y Aportaciones para los Sistemas de Educación Básica Normal Tecnológica y de Adultos"

* 2.3.2 Aportaciones *
drop if substr(clave_de_concepto,1,6) == "XAC33E" | substr(clave_de_concepto,1,6) == "XAC33D"

* 2.3.3 Convenios *
replace conceptograph = "Reasignación" if conceptograph == "Convenios de Reasignaci?n" | conceptograph == "Convenios de Reasignación"

* 2.3.4 Subsidios *
replace conceptograph = "Protección Social en Salud" if concepto == " Recursos para Protecci?n Social en Salud" ///
	| concepto == " Recursos para Protección Social en Salud"
replace conceptograph = "Otros subsidios" if concepto == " Resto del Gasto Federalizado del Ramo Provisiones Salariales y Economicas y Otros Subsidios"

* 2.3.5 Gasto Federalizado *
forvalues k = 1(1)4 {
	local GasFed`k' : label GasFed `k'
	collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph GasFed)
	g montograph = monto/poblacion/deflator
	graph bar (mean) montograph if GasFed == `k' [fw=poblacion], ///
		over(conceptograph, sort(1) descending) ///
		over(anio) ///
		asyvar stack ///
		title({bf:`GasFed`k''}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(rows(1)) ///
		name(`GasFed`k'', replace)

	if "$export" != "" {
		graph export "$export/`GasFed`k''.png", replace name(`GasFed`k'')
	}
}

* Scalares *
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2021 {
		if GasFed[`k'] == 1 {
			scalar Part`=entidad[`k']' = montograph[`k']
		}
		if GasFed[`k'] == 2 {
			scalar Apor`=entidad[`k']' = montograph[`k']
		}
		if GasFed[`k'] == 3 {
			scalar Subs`=entidad[`k']' = montograph[`k']
		}
		if GasFed[`k'] == 4 {
			scalar Conv`=entidad[`k']' = montograph[`k']
		}
	}
}
noisily scalarlatex, log(GasFed)



****************************/
*** 4. Recursos estatales ***
/*****************************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
keep if valor != .
rename valor monto


* 4.1 Homolgar información *

* 4.2 Resultados *
encode divCIEP, g(concept) label(concept)
collapse (sum) monto* (max) poblacion deflator pibYEnt if concept != ., by(entidad anio concept)
reshape wide monto, i(anio entidad) j(concept)
reshape long


* 4.2 Gráfica *
local aniolast = anio[_N]
g montograph = monto/poblacion/deflator
replace montograph = 0 if montograph == .
tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {

	noisily di _newline(2) in g "Entidad: " in y "``j'' `aniolast'"

	local ifentidad ""
	if "`k'" != "Nac" {
		local ifentidad `"& entidad == "`k'""'
	}
	
	tabstat montograph if montograph != . & anio == `aniolast' `ifentidad' [fw=poblacion], by(concept) stat(sum) f(%20.0fc) save
	tempname Propios Federalizados
	matrix `Propios' = r(Stat4)+r(Stat3)
	matrix `Federalizados' = r(Stat1)
	
	noisily di in g "Tasa de dependencia: " in y %7.1fc `Federalizados'[1,1]/(`Propios'[1,1]+`Federalizados'[1,1])*100 in g "%"
	scalar Depen`k' = `Federalizados'[1,1]/(`Propios'[1,1]+`Federalizados'[1,1])*100
	
	graph bar (mean) montograph if montograph != . `ifentidad' [fw=poblacion], ///
		over(concept, sort(1) descending) ///
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
noisily scalarlatex, logname(IngLocales)





**************************/
*** 5. Recursos propios ***
/***************************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
rename valor monto

* 5.1 Homolgar y simplificar información *
g conceptograph = trim(concepto)
replace conceptograph = "Aprovechamientos" if conceptograph == "Aprovechamientos de tipo capital" ///
	| conceptograph == "Aprovechamientos de tipo corriente" | conceptograph == "Otros aprovechamientos"
replace conceptograph = "Derechos" if conceptograph == "Derechos por el uso, goce, aprovechamiento o explotación de bienes de dominio público" ///
	| conceptograph == "Derechos por prestación de servicios" | conceptograph == "Otros Derechos"
replace conceptograph = "Impuestos" if conceptograph == "Impuesto sobre la producción, el consumo y las transacciones" ///
	| conceptograph == "Impuesto sobre los Ingresos" | conceptograph == "Impuestos sobre el Patrimonio" | conceptograph == "Otros Impuestos"
replace conceptograph = "Productos" if conceptograph == "Productos de tipo capital" | conceptograph == "Productos de tipo corriente" ///
	| conceptograph == "Otros productos"
replace conceptograph = "Otros" if conceptograph == "Contribuciones de Mejoras no comprendidas en las fracciones de la Ley de Ingresos causadas en ejercicios fiscales anteriores pendientes de liquidación o pago" ///
	| conceptograph == "Contribución de mejoras por obras públicas" ///
	| conceptograph == "Accesorios" | conceptograph == "Adicionales"


* 5.3 Resultados *
encode conceptograph, g(concept) label(concept)
collapse (sum) monto (max) poblacion deflator pibYEnt if divCIEP == "Recursos Propios" & concepto != "Disponibilidad inicial", by(entidad anio concept)
reshape wide monto, i(anio entidad) j(concept)
reshape long


* 5.2 Gráfica *
local aniolast = anio[_N]
g montograph = monto/poblacion/deflator
replace montograph = 0 if montograph == .
tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	
	noisily di _newline(2) in g "Entidad: " in y "``j'' `aniolast'"

	local ifentidad ""
	if "`k'" != "Nac" {
		local ifentidad `"if entidad == "`k'""'
	}

	tabstat montograph `ifentidad' [fw=poblacion], by(anio) stat(mean) f(%20.0fc) save
	graph bar (mean) montograph `ifentidad' [fw=poblacion], ///
		over(concept, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		title(Recursos {bf:propios}) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(0(500)3000, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(rows(1)) ///
		name(Propios_`k', replace)
	
	if "$export" != "" {
		graph export  "$export/Propios_`k'.png", as(png) replace name(Propios_`k')
	}
	local ++j
}



*******************/
*** 6. Impuestos ***
/********************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
keep if capitulo == "Impuestos"
rename valor monto

g conceptograph = trim(concepto)
replace conceptograph = "Contribuciones de mejora" if conceptograph == "Contribución de mejoras por obras públicas"
replace conceptograph = "A la producción y consumo" if conceptograph == "Impuesto sobre la producción, el consumo y las transacciones"
replace conceptograph = "Al patrimonio" if conceptograph == "Impuestos sobre el Patrimonio"
replace conceptograph = "Sobre nómina" if partida == "Impuesto sobre nómina"
replace conceptograph = "Otros impuestos" if conceptograph == "Contribuciones de mejora" | conceptograph == "Accesorios" ///
	| conceptograph == "Adicionales" | conceptograph == "Impuesto sobre los ingresos" ///
	| conceptograph == "Impuesto sobre los Ingresos" | conceptograph == "Otros Impuestos"

encode conceptograph, g(concept) label(concept)
collapse (sum) monto (max) poblacion deflator pibYEnt , by(entidad anio concept)
reshape wide monto, i(anio entidad deflator) j(concept)
reshape long
replace monto = 0 if monto == .

g montograph = monto/poblacion/deflator

tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	local entidad ""
	if "`k'" != "Nac" {
		local entidad `"& entidad == "`k'""'
	}
	graph bar (mean) montograph if montograph != . `entidad' [fw=poblacion], ///
		over(concept, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		title({bf:Impuestos} locales) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(0(500)1500, format(%7.0fc)) ///
		legend(rows(1)) ///
		blabel(bar, format(%7.0fc)) ///
		name(Impuestos_`k', replace)

	if "$export" != "" {
		graph export  "$export/Impuestos_`k'.png", as(png) replace  name(Impuestos_`k')
	}
	local ++j
}



***********************/
*** 7. Deuda estatal ***
/************************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
rename valor monto

g montograph1 = gobiernoEstatal/poblacion/deflator*1000000
label var montograph1 "Gobierno estatal"

g montograph2 =  entidadesPublicas/poblacion/deflator*1000000
label var montograph2 "Entidades públicas"

tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	local entidad ""
	if "`k'" != "Nac" {
		local entidad `"& entidad == "`k'""'
	}
	graph bar (mean) montograph* if montograph1 != . `entidad' [fw=poblacion], ///
		over(anio) ///
		stack asyvars ///
		title({bf:Deuda} estatal) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(0(1000)6000, format(%7.0fc)) ///
		legend(rows(1) label (1 "Gobierno estatal") label(2 "Entidades públicas")) ///
		blabel(bar, format(%7.0fc)) ///
		name(Deuda_`k', replace)

	if "$export" != "" {
		graph export  "$export/Deuda_`k'.png", as(png) replace name(Deuda_`k')
	}
	local ++j
}

collapse (sum) monto (max) poblacion deflator pibYEnt deuda if divCIEP == "Recursos Propios" ///
	| capitulo == "Participaciones federales" | deudaTotal != ., by(entidad* anio)
sort entidadx anio

g crec_pib = pibYEnt/L.pibYEnt/deflator
replace monto = L.monto*crec_pib if anio == 2022

g montograph1 = deuda*1000000/pibYEnt*100
g montograph2 =  deuda*1000000/monto*100

tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	local entidad ""
	if "`k'" != "Nac" {
		local entidad `"& entidad == "`k'""'
	}
	graph bar (mean) montograph1 if montograph1 != . `entidad' [fw=poblacion], ///
		over(anio) ///
		asyvars ///
		///title({bf:Deuda} estatal como % del PIB) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(, format(%7.1fc)) ///
		legend(rows(1) label (1 "Gobierno estatal") label(2 "Entidades públicas")) ///
		blabel(bar, format(%7.1fc)) ///
		name(Deuda2_`k', replace)

	if "$export" != "" {
		graph export  "$export/Deuda2_`k'.png", as(png) replace name(Deuda2_`k')
	}
	local ++j
}

tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	local entidad ""
	if "`k'" != "Nac" {
		local entidad `"& entidad == "`k'""'
	}
	graph bar (mean) montograph2 if montograph2 != . `entidad' [fw=poblacion], ///
		over(anio) ///
		asyvars ///
		title({bf:Deuda} estatal como % ingresos libres) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(, format(%7.1fc)) ///
		legend(rows(1) label (1 "Gobierno estatal") label(2 "Entidades públicas")) ///
		blabel(bar, format(%7.1fc)) ///
		name(Deuda3_`k', replace)

	if "$export" != "" {
		graph export  "$export/Deuda3_`k'.png", as(png) replace name(Deuda3_`k')
	}
	local ++j
}



************************/
*** 8. Espacio fiscal ***
/*************************
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
rename valor monto


* 8.1 Homolgar y simplificar información *
g conceptograph = ""

* 8.1.1 Ingresos *
replace conceptograph = "Ingresos" if divCIEP != "" & divCIEP != "Financiamiento"

* 8.1.2 Gastos ineludibles *
replace conceptograph = "Servicio Deuda" if capitulo == "Deuda pública"
replace conceptograph = "Servicio Personales" if capitulo == "Servicios personales"
replace conceptograph = "Transferencias a municipios" if capitulo == "Recursos asignados a municipios" ///
	| capitulo == "Recursos asignados a alcaldías de la Ciudad de México y sector paraestatal"
replace conceptograph = "Pensiones" if concepto == "Pensiones y jubilaciones"

* 8.1.3 Gasto estatalizado *
replace conceptograph = "" if descripcion_categoria == "FA para Nómina Educativa y Gasto Operativo"
replace conceptograph = "" if descripcion_categoria == "FA para Infraestructura Social Estatal"
replace conceptograph = "" if descripcion_categoria == "FA Múltiples"


* 8.2 Resultados *
encode conceptograph, g(concept) label(concept)
collapse (sum) monto (max) poblacion deflator pibYEnt if monto != . & conceptograph != "", by(entidad anio concept)
reshape wide monto, i(anio entidad) j(concept)

* 8.2.1 Espacio fiscal *
egen gastosineludibles = rsum(monto2 monto3 monto4 monto5)
g espaciofiscal = monto1 - gastosineludibles


* 8.3 Gráfica *
local aniolast = anio[_N]
g montograph = espaciofiscal/poblacion/deflator
tokenize `"$entidadesL"'
local j = 1
foreach k of global entidadesC {
	
	noisily di _newline(2) in g "Entidad: " in y "``j'' `aniolast'"

	local ifentidad ""
	if "`k'" != "Nac" {
		local ifentidad `"if entidad == "`k'""'
	}

	tabstat montograph `ifentidad' [fw=poblacion], stat(mean) by(anio) f(%20.0fc) save
	graph bar (mean) montograph `ifentidad' [fw=poblacion], ///
		over(anio) ///
		title({bf:Espacio} fiscal) ///
		subtitle(``j'') ///
		ytitle("por residente (MXN `=aniovp')") ///
		ylabel(0(1000)9000, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(rows(1)) ///
		name(Espacio`k', replace)
	
	if "$export" != "" {
		graph export "$export/Espacio`k'.png", as(png) replace name(Espacio`k')
	}
	local ++j
}



