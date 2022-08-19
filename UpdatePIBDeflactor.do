*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************

noisily di in g "  Updating PIBDeflactor.dta..." _newline

***************
*** 1 BASES ***
***************

* 1.1.1. Importar y limpiar la base de datos INEGI/BIE: PIB *
import excel "`=c(sysdir_site)'/bases/UPDATE/SCN/PIB.xlsx", clear
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

* 1.1.4. Guardar *
compress
tempfile PIB
save `PIB'


* 1.2.1. Importar y limpiar la base de datos INEGI/BIE: Índice de precios (deflactor) *
import excel "`=c(sysdir_site)'/bases/UPDATE/SCN/deflactor.xlsx", clear
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
label var indiceQ "${I}ndice de Precios Impl${i}citos (trimestral)"

drop periodo
order anio trimestre indiceQ

* 1.2.4. Guardar *
compress
tempfile Deflactor
save `Deflactor', replace




*************************
*** 2 PIB + Deflactor ***
*************************
use (anio trimestre pibQ) using `PIB', clear
merge 1:1 (anio trimestre) using `Deflactor', nogen keepus(indiceQ)

* Anio + Trimestre *
g aniotrimestre = yq(anio,trimestre)
format aniotrimestre %tq
label var aniotrimestre "YearQuarter"
tsset aniotrimestre

* Moneda *
g currency = "MXN"

* Guardar base SIM *
if `c(version)' > 13.1 {
	saveold "`c(sysdir_site)'/SIM/PIBDeflactor.dta", replace version(13)
}
else {
	save "`c(sysdir_site)'/SIM/PIBDeflactor.dta", replace
}




*****************************
*** 3 Gráfica informativa ***
*****************************
if "$nographs" == "" {

	* Variable de la gráfica *
	tempvar pibQR crec_pibQR
	g `pibQR' = pibQ/(indiceQ/100)
	g `crec_pibQR' = (`pibQR'/L4.`pibQR'-1)*100

	* Texto sobre lineas *
	forvalues k=1(1)`=_N' {
		if `crec_pibQR'[`k'] != . {
			local text_pibQR `"`text_pibQR' `=`crec_pibQR'[`k']' `=aniotrimestre[`k']' "{bf:`=string(`crec_pibQR'[`k'],"%5.1fc")'}" "'
		}
	}

	* Gráfica *
	twoway connected `crec_pibQR' aniotrimestre, ///
		title(Crecimiento del {bf:PIB trimestral}) ///
		ytitle("Crecimiento trimestral (%)") xtitle("") ///
		text(`text_pibQR') msize(large) ///
		note("{bf:{c U'}ltimo dato reportado}: `=anio[_N]' trim. `=trimestre[_N]'.") ///
		caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
		name(UpdatePIBDeflactor, replace)

	* Exportar gráfica *
	capture confirm existence $export
	if _rc == 0 {
		graph export "$export/var_indiceYH.png", replace name(var_indiceYH)
	}
}
