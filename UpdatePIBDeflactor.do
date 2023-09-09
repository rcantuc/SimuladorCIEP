*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************
noisily di in g "  Updating PIBDeflactor.dta..." _newline



**************
***        ***
**# 1. PIB ***
***        ***
**************

** 1.1 Importar y limpiar la base de datos **
import excel "`=c(sysdir_site)'../BasesCIEP/UPDATE/SCN/01 - PIB.xlsx", clear
LimpiaBIE


** 1.2 Renombrar variables **
rename A periodo
rename B pibQ
rename GD indiceQ
replace indiceQ = indiceQ/1000000
format indice* %8.3f


** 1.3 Time Series **
split periodo, destring p("/") ignore("r p")
rename periodo1 anio
label var anio "anio"
rename periodo2 trimestre
label var trimestre "trimestre"

destring pibQ indiceQ, replace
label var pibQ "Producto Interno Bruto (trimestral)"
label var indiceQ "Índice de precios implícitos (trimestral)"


** 1.4 Guardar **
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
tempfile poblacion
save "`poblacion'"


** 2.2 Working Ages (CONAPO) **
use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
collapse (sum) WorkingAge=poblacion if edad >= 15 & edad <= 65 & entidad == "Nacional", by(anio)
format WorkingAge %15.0fc
tempfile workingage
save "`workingage'"


** 2.3 Población ocupada (ENOE) **
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/02 - Poblacion.xlsx", clear
LimpiaBIE, nomult


** 2.4 Renombrar variables **
rename A periodo
rename B PoblacionENOE
rename E PoblacionOcupada
rename F PoblacionDesocupada


** 2.5 Time Series **
split periodo, destring p("/") ignore("r p")
rename periodo1 anio
rename periodo2 trimestre


** 2.5 Guardar **
g entidad = "Nacional"
drop periodo
format Poblacion* %15.0fc
tempfile poblacionenoe
save "`poblacionenoe'"





***************
***         ***
**# 3 Unión ***
***         ***
***************
use (anio trimestre pibQ indiceQ) using `PIB', clear
	local ultanio = anio[_N]
	local ulttrim = trimestre[_N]
merge m:1 (anio) using "`workingage'", nogen //keep(matched)
merge m:1 (anio) using "`poblacion'", nogen //keep(matched)
merge 1:1 (anio trimestre) using "`poblacionenoe'", nogen keepus(Poblacion*)


** 3.1 Anio + Trimestre **
replace trimestre = 1 if trimestre == .
g aniotrimestre = yq(anio,trimestre)
format aniotrimestre %tq
label var aniotrimestre "YearQuarter"
tsset aniotrimestre


** 3.2 Moneda **
g currency = "MXN"


** 3.3 Variables de interés **
forvalues k=1(1)`=_N' {
	if anio[`k'] == `ultanio' & trimestre[`k'] == `ulttrim' {
		local obsvp = `k'
	}
}
tempvar deflator
g double `deflator' = indiceQ/indiceQ[`obsvp']
g pibQR = pibQ/`deflator'
g pibPO = pibQR/PoblacionOcupada





********************
* 3 Guardar base SIM *
********************
format pib* %25.0fc
capture drop __*
sort aniotrimestre
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace
}





*******************************
*** 4 Gráficas informativas ***
*******************************
use "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", clear

** 1.4 Texto **
g crec_pibQR = (pibQR/L4.pibQR-1)*100

* Texto sobre lineas *
forvalues k=`=_N'(-1)1 {
	if pibPO[`k'] != . /*& trimestre[`k'] == `ulttrim'*/ {
		local text_pibQR `"`text_pibQR' `=crec_pibQR[`k']' `=aniotrimestre[`k']' "`=string(crec_pibQR[`k'],"%5.1fc")'%" "'
	}
}

* Gráfica *
twoway connected crec_pibQR aniotrimestre if pibPO != . /*& trimestre == `k'*/, ///
	title({bf:Producto Interno Bruto}) subtitle(${pais}) ///
	ytitle("Crecimiento trimestre vs. trimestre (%)") xtitle("") ///
	tlabel(2005q1(4)`ultanio'q`ulttrim') ///
	text(`text_pibQR', size(vsmall) color(white)) ///
	note("{bf:{c U'}ltimo dato reportado}: `ultanio' trim. `ulttrim'.") ///
	caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
	name(UpdatePIBDeflactor, replace)

twoway (bar pibPO aniotrimestre, mlabel(pibPO) mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
	if pibPO != . /*& trimestre == `k'*/, ///
	title({bf:Producto Interno Bruto por población ocupada}) subtitle(${pais}) ///
	ytitle(`=currency[`obsvp']' `ultanio') xtitle("") ///
	tlabel(2005q1(4)`ultanio'q`ulttrim') ///
	///text(`crec_PIBPC', size(vsmall)) ///
	ylabel(/*0(5)`=ceil(`pibYRmil'[_N])'*/, format(%20.0fc)) yscale(range(500000)) ///
	note("{bf:{c U'}ltimo dato reportado}: `ultanio' trim. `ulttrim'.") ///
	caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE/ENOE.") ///
	name(UpdatePIBDeflactorPO, replace)

