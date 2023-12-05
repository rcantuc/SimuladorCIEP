*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************
noisily di in g "  Updating PIBDeflactor.dta..." _newline





**************
***        ***
**# 1. PIB ***
***        ***
**************

** 1.1. Importar variables de interés desde el BIE **
run "`c(sysdir_personal)'/AccesoBIE.do" "734407 735143 446562 446565 446566 628194"


** 1.2 Renombrar variables **
rename periodos periodo

rename productointernobrutof1millonesde pibQ
label var pibQ "Producto Interno Bruto (trimestral)"

rename productointernobrutof1índicebase indiceQ
label var indiceQ "Índice de precios implícitos (trimestral)"

rename poblacióntotalaf1númerodepersona PoblacionENOE
label var PoblacionENOE "Población ENOE"

rename ocupadaaf1númerodepersonastrimes PoblacionOcupada
label var PoblacionOcupada "Población Ocupada (ENOE)"

rename desocupadaaf1númerodepersonastri PoblacionDesocupada
label var PoblacionDesocupada "Población Desocupada (ENOE)"

rename índicegeneralf1índicebasesegunda inpc
label var inpc "Índice Nacional de Precios al Consumidor"


** 1.3 Dar formato a variables **
replace pibQ = pibQ*1000000
format indice* inpc %8.3f
format pib %20.0fc
format Poblacion* %12.0fc


** 1.4 Time Series **
split periodo, destring p("/") //ignore("r p")
rename periodo1 anio
label var anio "anio"
rename periodo2 trimestre
label var trimestre "trimestre"


** 1.5 Guardar **
order anio trimestre pibQ
drop periodo
compress
tempfile PIB
save `PIB'





********************
***              ***
**# 2. Poblacion ***
***              ***
********************

** 2.1 Población (CONAPO) **
capture use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
if _rc != 0 {
	noisily run `"`c(sysdir_personal)'/UpdatePoblacion`=subinstr("${pais}"," ","",.)'.do"'
}
collapse (sum) Poblacion=poblacion if entidad == "Nacional", by(anio)
format Poblacion %15.0fc
tempfile Poblacion
save "`Poblacion'"


** 2.2 Working Ages (CONAPO) **
use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
collapse (sum) WorkingAge=poblacion if edad >= 15 & edad <= 65 & entidad == "Nacional", by(anio)
format WorkingAge %15.0fc
tempfile WorkingAge
save "`WorkingAge'"


** 2.3 Recién nacidos (CONAPO) **
use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
collapse (sum) Poblacion0=poblacion if edad == 0 & entidad == "Nacional", by(anio)
format Poblacion0 %15.0fc
tempfile Poblacion0
save "`Poblacion0'"






***************
***         ***
**# 3 Unión ***
***         ***
***************
use `PIB', clear
	local ultanio = anio[_N]
	local ulttrim = trimestre[_N]
merge m:1 (anio) using "`Poblacion'", nogen //keep(matched)
merge m:1 (anio) using "`WorkingAge'", nogen //keep(matched)
merge m:1 (anio) using "`Poblacion0'", nogen //keep(matched)

** 1.4 Moneda **
g currency = "MXN"

** 3.1 Anio + Trimestre **
replace trimestre = 1 if trimestre == .
g aniotrimestre = yq(anio,trimestre)
format aniotrimestre %tq
label var aniotrimestre "YearQuarter"
tsset aniotrimestre





******************************
***                        ***
**# 4 Variables de interés ***
***                        ***
******************************
forvalues k=`=_N'(-1)1 {
	if indiceQ[`k'] != . {
		local obsvp = `k'
		local trim_last = trim[`k']
		local aniofinal = anio[`k']
		continue, break
	}
}
tempvar deflator
g double `deflator' = indiceQ/indiceQ[`obsvp']
g pibQR = pibQ/`deflator'

g pibPO = pibQR/PoblacionOcupada
format pibPO %20.0fc

g crec_pibQR = (pibQR/L4.pibQR-1)*100
format crec_pibQR %10.1fc

format pib* %25.0fc
capture drop __*
sort aniotrimestre
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace
}




******************
***            ***
**# 4 Gráficas ***
***            ***
******************
if "$nographs" == "" {
	
	* Títulos y fuentes *
	if "$export" == "" {
		local graphtitle "{bf:Índice de precios al consumidor}"
		local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/SHCP."
	}
	else {
		local graphtitle ""
		local graphfuente ""
	}
	twoway (connected crec_pibQR aniotrimestre, mlabel(crec_pibQR) mlabposition(0) mlabcolor(white) mlabgap(0pt)) if pibPO != ., ///
		title({bf:Producto Interno Bruto}) subtitle(Crecimiento trim. vs. trim.) ///
		ytitle("Crecimiento anual (%)") xtitle("") ///
		tlabel(2005q1(4)`aniofinal'q`trim_last') ///
		ylabel(none, format(%20.0fc)) ///
		caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
		name(UpdatePIBDeflactor, replace)


	* Títulos y fuentes *
	if "$export" == "" {
		local graphtitle "{bf:Productividad laboral}"
		local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/SHCP/ENOE."
	}
	else {
		local graphtitle ""
		local graphfuente ""
	}
	twoway (bar pibPO aniotrimestre, mlabel(pibPO) mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
		if pibPO != ., ///
		title("`graphtitle'") ///
		ytitle("PIB/Población ocupada (`=currency[`obsvp']' `aniofinal')") xtitle("") ///
		tlabel(2005q1(4)`aniofinal'q`trim_last') ///
		///text(`crec_PIBPC', size(vsmall)) ///
		ylabel(none, format(%20.0fc)) yscale(range(500000)) ///
		caption("`graphfuente'") ///
		name(pib_po, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/pib_po.png", replace name(pib_po)
		}
}
