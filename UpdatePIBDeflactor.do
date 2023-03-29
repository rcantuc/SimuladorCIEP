*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************
noisily di in g "  Updating PIBDeflactor.dta..." _newline



***************
*** 1 BASES ***
***************

** 1.1 PIB **

* 1.1.1. Importar y limpiar la base de datos *
import excel "`=c(sysdir_site)'../BasesCIEP/UPDATE/SCN/PIB.xlsx", clear
LimpiaBIE

* 1.1.2. Renombrar variables *
rename A periodo
rename B pibQ

* 1.1.3. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 trimestre
label var trimestre "trimestre"

destring pibQ, replace
label var pibQ "Producto Interno Bruto (trimestral)"

drop periodo
order anio trimestre pibQ

* 1.1.4. Texto *
local ultanio = anio[_N]
local ulttrim = trimestre[_N]

* 1.1.5. Guardar *
compress
tempfile PIB
save `PIB'



** 1.2 Índice de precios y su deflactor *
* 1.2.1. Importar y limpiar la base de datos *
import excel "`=c(sysdir_site)'../BasesCIEP/UPDATE/SCN/deflactor.xlsx", clear
LimpiaBIE, nomult

* 1.2.2. Renombrar variables *
rename A periodo
rename B indiceQ

* 1.2.3. Time Series *
split periodo, destring p("/") ignore("r p")

rename periodo1 anio
label var anio "anio"

rename periodo2 trimestre
label var trimestre "trimestre"

destring indiceQ, replace
label var indiceQ "Índice de Precios Implícitos (trimestral)"

drop periodo
order anio trimestre indiceQ

* 1.2.4. Guardar *
compress
tempfile Deflactor
save `Deflactor', replace


** 1.3 Poblacion CONAPO **
capture use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
if _rc != 0 {
	noisily run `"`c(sysdir_personal)'/UpdatePoblacion`=subinstr("${pais}"," ","",.)'.do"'
}
collapse (sum) Poblacion=poblacion if entidad == "Nacional", by(anio)
local aniomax = anio[_N]
format Poblacion %15.0fc
tempfile poblacion
save "`poblacion'"


** 1.4 Working Ages **
use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
collapse (sum) WorkingAge=poblacion if edad >= 16 & edad <= 65 & entidad == "Nacional", by(anio)
format WorkingAge %15.0fc
tempfile workingage
save "`workingage'"



** 1.4 Poblacion ENOE **
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Poblacion.xlsx", sheet("Poblacion") clear
LimpiaBIE, nomult

* 1.4.1. Renombrar variables *
rename A periodo
split periodo, destring p("/") ignore("r p")
rename periodo1 anio
rename periodo2 trimestre
rename B PoblacionENOE
rename E PoblacionOcupada
rename F PoblacionDesocupada
g entidad = "Nacional"

format Poblacion* %15.0fc
tempfile poblacionenoe
save "`poblacionenoe'"



***************
*** 2 Unión ***
***************
use (anio trimestre pibQ) using `PIB', clear
merge 1:1 (anio trimestre) using `Deflactor', nogen keepus(indiceQ)
merge m:1 (anio) using "`workingage'", nogen //keep(matched)
merge m:1 (anio) using "`poblacion'", nogen //keep(matched)
merge 1:1 (anio trimestre) using "`poblacionenoe'", nogen keepus(Poblacion*)

* Anio + Trimestre *
g aniotrimestre = yq(anio,trimestre)
format aniotrimestre %tq
label var aniotrimestre "YearQuarter"
tsset aniotrimestre

* Moneda *
g currency = "MXN"

* Variables de interés *
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
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace
}





*******************************
*** 4 Gráficas informativas ***
*******************************
if "$nographs" == "" {

	g crec_pibQR = (pibQR/L4.pibQR-1)*100

	* Texto sobre lineas *
	forvalues k=1(1)`=_N' {
		if pibPO[`k'] != . & trimestre[`k'] == `ulttrim' {
			local text_pibQR `"`text_pibQR' `=crec_pibQR[`k']' `=aniotrimestre[`k']' "{bf:`=string(crec_pibQR[`k'],"%5.1fc")'}" "'
		}
		if pibPO[`k'] != . & trimestre[`k'] == `ulttrim' {
			local crec_PIBPC `"`crec_PIBPC' `=pibPO[`k']' `=aniotrimestre[`k']' "{bf:`=string(pibPO[`k'],"%10.0fc")'}" "'
		}
	}

	* Gráfica *
	twoway connected crec_pibQR aniotrimestre if pibPO != . & trimestre == `ulttrim', ///
		title({bf:Producto Interno Bruto}) ///
		ytitle("Crecimiento trimestre vs. trimestre (%)") xtitle("") ///
		tlabel(2005q`ulttrim'(4)`ultanio'q`ulttrim') ///
		text(`text_pibQR', size(small)) ///
		note("{bf:{c U'}ltimo dato reportado}: `ultanio' trim. `ulttrim'.") ///
		caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
		name(UpdatePIBDeflactor, replace)
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
		}

	twoway (connected pibPO aniotrimestre) if pibPO != . & trimestre == `ulttrim', ///
		title(Producto Interno Bruto por {bf:población ocupada}) subtitle(${pais}) ///
		ytitle(`=currency[`obsvp']' `ultanio') xtitle("") ///
		tlabel(2005q`ulttrim'(4)`ultanio'q`ulttrim') ///
		text(`crec_PIBPC', size(small)) ///
		ylabel(/*0(5)`=ceil(`pibYRmil'[_N])'*/, format(%20.0fc)) ///
		note("{bf:{c U'}ltimo dato reportado}: `ultanio' trim. `ulttrim'.") ///
		caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE/ENOE.") ///
		name(PIBPC, replace)
}
