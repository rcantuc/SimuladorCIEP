************************
** 1 SHRFSP (acervos) **
************************
noisily DatosAbiertos SHRF5000, $nographs
drop clave_de_concepto nombre 
*keep anio mes monto mes
rename monto shrfsp
tempfile shrfsp
save "`shrfsp'"


** Interno **
noisily DatosAbiertos SHRF5100, $nographs
keep anio mes monto mes
rename monto shrfspInterno
tempfile shrfspinterno
save "`shrfspinterno'"


** Externo **
noisily DatosAbiertos SHRF5200, $nographs
keep anio mes monto mes
rename monto shrfspExterno
tempfile shrfspexterno
save "`shrfspexterno'"



*********************
** 2 RFSP (flujos) **
*********************
noisily DatosAbiertos RF000000SPFCS, $nographs
keep anio mes monto
rename monto rfsp
replace rfsp = -rfsp
tempfile rfsp
save "`rfsp'"


** Endeudamiento presupuestario **
noisily DatosAbiertos RF000001SPFCS, $nographs
keep anio mes monto
rename monto rfspBalance
tempfile Balance
save "`Balance'"


** PIDIREGAS **
noisily DatosAbiertos RF000002SPFCS, $nographs
keep anio mes monto
rename monto rfspPIDIREGAS
tempfile PIDIREGAS
save "`PIDIREGAS'"


** IPAB **
noisily DatosAbiertos RF000003SPFCS, $nographs
keep anio mes monto
rename monto rfspIPAB
tempfile IPAB
save "`IPAB'"


** FONADIN **
noisily DatosAbiertos RF000004SPFCS, $nographs
keep anio mes monto
rename monto rfspFONADIN
tempfile FONADIN
save "`FONADIN'"


** PROGRAMA DE DEUDORES **
noisily DatosAbiertos RF000005SPFCS, $nographs
keep anio mes monto
rename monto rfspDeudores
tempfile Deudores
save "`Deudores'"


** BANCA DE DESARROLLO **
noisily DatosAbiertos RF000006SPFCS, $nographs
keep anio mes monto
rename monto rfspBanca
tempfile Banca
save "`Banca'"


** ADECUACIONES PRESUPUESTARIAS **
noisily DatosAbiertos RF000007SPFCS, $nographs
keep anio mes monto
rename monto rfspAdecuaciones
tempfile Adecuaciones
save "`Adecuaciones'"



**************************************
** 3 Ajustes (RFSP vs. DIF. SHRFSP) **
**************************************

** Activos financieros internos del SP **
noisily DatosAbiertos XED20, $nographs
keep anio mes monto
rename monto activosInt
tempfile activosInt
save "`activosInt'"


** Activos financieros externos del SP **
noisily DatosAbiertos XEB10, $nographs
keep anio mes monto
rename monto activosExt
tempfile activosExt
save "`activosExt'"


** Diferimientos **
noisily DatosAbiertos XOA0108, $nographs
keep anio mes monto
rename monto diferimientos
tempfile diferimientos
save "`diferimientos'"


** Amortización **
noisily DatosAbiertos IF03230, $nographs
keep anio mes monto
rename monto amortizacion
tempfile amortizacion
save "`amortizacion'"




***************************************
** 4 Balance público (Endeudamiento) **
***************************************

** Balance público **
noisily di _newline(2) in g "{bf: Endeudamiento público} en millones de pesos"
noisily DatosAbiertos XAA, $nographs
keep anio mes monto
rename monto balancepublico
tempfile balancepublico
save "`balancepublico'"


** Endeudamiento presupuestario **
noisily DatosAbiertos XAA10, $nographs
keep anio mes monto
rename monto presupuestario
tempfile presupuestario
save "`presupuestario'"

** Endeudamiento no presupuestario **
noisily DatosAbiertos XAA20, $nographs
keep anio mes monto
rename monto nopresupuestario
tempfile nopresupuestario
save "`nopresupuestario'"




****************************************
* 4.1 Balance presupuestario (detalle) *

** Gobierno Federal **
noisily DatosAbiertos XAA11, $nographs
keep anio mes monto
rename monto gobiernofederal
tempfile gobiernofederal
save "`gobiernofederal'"


** Pemex **
noisily DatosAbiertos XAA1210, $nographs
keep anio mes monto
rename monto pemex
tempfile pemex
save "`pemex'"


** CFE **
noisily DatosAbiertos XOA0101, $nographs
keep anio mes monto
rename monto cfe
tempfile cfe
save "`cfe'"


** IMSS **
noisily DatosAbiertos XOA0105, $nographs
keep anio mes monto
rename monto imss
tempfile imss
save "`imss'"


** ISSSTE **
noisily DatosAbiertos XOA0106, $nographs
keep anio mes monto
rename monto issste
tempfile issste
save "`issste'"



***********************************/
** 5 Costo financiero de la deuda **
************************************
noisily di _newline(2) in g "{bf: Costo financiero de la deuda} en millones de pesos"
noisily DatosAbiertos XAC21, $nographs
keep anio mes monto
rename monto costofinanciero
tempfile costofinanciero
save "`costofinanciero'"


** Gobierno Federal **
noisily DatosAbiertos XBC21, $nographs
keep anio mes monto
rename monto costogobiernofederal
tempfile costogobiernofederal
save "`costogobiernofederal'"


** Pemex **
noisily DatosAbiertos XOA0160, $nographs
keep anio mes monto
rename monto costopemex

g deudaPemex = .
replace deudaPemex = 2070542.31635290 if anio == 2022 	// a septiembre
replace deudaPemex = 2173189.44800813 if anio == 2021
replace deudaPemex = 2218737.53616582 if anio == 2020
replace deudaPemex = 1922589.08819400 if anio == 2019
replace deudaPemex = 2000374.02960390 if anio == 2018
replace deudaPemex = 1940286.92629512 if anio == 2017
replace deudaPemex = 1819638.21654995 if anio == 2016
replace deudaPemex = 1384012.95509301 if anio == 2015
replace deudaPemex = 1025261.97573126 if anio == 2014
replace deudaPemex = 760494.694310920 if anio == 2013
replace deudaPemex = 667623.708531536 if anio == 2012
replace deudaPemex = 668178.069289112  if anio == 2011
replace deudaPemex = 531138.3347399 if anio == 2010
replace deudaPemex = 472098.44249911 if anio == 2009
replace deudaPemex = 472486.10948318 if anio == 2008

replace deudaPemex = deudaPemex*1000000
format deudaPemex %20.0fc

tempfile costopemex
save "`costopemex'"


** CFE **
noisily DatosAbiertos XOA0162, $nographs
keep anio mes monto
rename monto costocfe
tempfile costocfe
save "`costocfe'"


noisily DatosAbiertos XOA0155, $nographs			// costo deuda interna
keep anio mes monto
rename monto costodeudaInterno
tempfile costodeudaII
save "`costodeudaII'"

noisily DatosAbiertos XOA0156, $nographs			// costo deuda externa
keep anio mes monto
rename monto costodeudaExterno
tempfile costodeudaEE
save "`costodeudaEE'"



**********************
** 6 Tipo de cambio **
**********************

* Deuda en pesos *
noisily DatosAbiertos XET30, $nographs
keep anio mes monto
rename monto deudaMXN		
tempfile MXN
save "`MXN'"


* Deuda en dólares *
noisily DatosAbiertos XET40, $nographs
keep anio mes monto
rename monto deudaUSD
tempfile USD
save "`USD'"



************/
** 7 Merge **
*************

* Acervos *
use `shrfsp', clear
merge 1:1 (anio) using "`shrfspinterno'", nogen
merge 1:1 (anio) using "`shrfspexterno'", nogen

* Flujos *
merge 1:1 (anio) using "`rfsp'", nogen
merge 1:1 (anio) using "`Balance'", nogen
merge 1:1 (anio) using "`PIDIREGAS'", nogen
merge 1:1 (anio) using "`IPAB'", nogen
merge 1:1 (anio) using "`FONADIN'", nogen
merge 1:1 (anio) using "`Deudores'", nogen
merge 1:1 (anio) using "`Banca'", nogen
merge 1:1 (anio) using "`Adecuaciones'", nogen

* Adecuaciones *
merge 1:1 (anio) using "`nopresupuestario'", nogen
merge 1:1 (anio) using "`activosInt'", nogen
merge 1:1 (anio) using "`activosExt'", nogen
merge 1:1 (anio) using "`diferimientos'", nogen
merge 1:1 (anio) using "`amortizacion'", nogen


* Tipo de cambio *
merge 1:1 (anio) using "`MXN'", nogen
merge 1:1 (anio) using "`USD'", nogen


* Costos financieros *
merge 1:1 (anio) using "`costodeudaII'", nogen update
merge 1:1 (anio) using "`costodeudaEE'", nogen update
merge 1:1 (anio) using "`costopemex'", nogen
tsset anio

** Tipo de cambio **
g double tipoDeCambio = deudaMXN/deudaUSD
format tipoDeCambio %7.2fc

** Porcentaje interna y externa *
g porInterno = shrfspInterno/shrfsp
g porExterno = shrfspExterno/shrfsp

compress
if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'/SIM/SHRFSP.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'/SIM/SHRFSP.dta"', replace
}

exit



use `"`c(sysdir_site)'/SIM/SHRFSP.dta"', clear
local aniovp = 2023
tempvar shrfsp deudaPemex
g `shrfsp' = shrfsp/1000000/deflator
g `deudaPemex' = deudaPemex/1000000/deflator
forvalues k = 1(1)`=_N' {
	if `deudaPemex'[`k'] != . {
		local text1 = `"`text1' `=`deudaPemex'[`k']' `=anio[`k']' "{bf:`=string(`deudaPemex'[`k']/`shrfsp'[`k']*100,"%5.1fc")'%}" "'
	}
}
twoway (area `shrfsp' `deudaPemex' anio) if deudaPemex != ., ///
	ytitle(millones MXN `aniovp') ///
	xtitle("") ///
	xlabel(2008(1)2022) ///
	ylabel(, format(%15.0fc)) yscale(range(0)) ///
	legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
	text(`text1', color(black)) ///
	caption("`graphfuente'") ///
	legend(on label(1 "SHRFSP") label(2 "Deuda Pemex")) ///
	note("{bf:{c U'}ltimo dato:} 2022m9.") ///
	name(deudaPemex, replace)

