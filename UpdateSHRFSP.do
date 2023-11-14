**********************************
***                            ***
**#     1 SHRFSP (acervos)     ***
***                            ***
**********************************
noisily DatosAbiertos SHRF5000, $nographs
drop clave_de_concepto nombre 
rename monto shrfsp
tempfile shrfsp
save "`shrfsp'"


** Interno **
noisily DatosAbiertos SHRF5100, $nographs
rename monto shrfspInterno
tempfile shrfspinterno
save "`shrfspinterno'"


** Externo **
noisily DatosAbiertos SHRF5200, $nographs
rename monto shrfspExterno
tempfile shrfspexterno
save "`shrfspexterno'"





*******************************
***                         ***
***     2 RFSP (flujos)     ***
***                         ***
*******************************
noisily DatosAbiertos RF000000SPFCS, $nographs
rename monto rfsp
tempfile rfsp
save "`rfsp'"


** Endeudamiento presupuestario **
noisily DatosAbiertos RF000001SPFCS, $nographs
rename monto rfspBalance
tempfile Balance
save "`Balance'"


** PIDIREGAS **
noisily DatosAbiertos RF000002SPFCS, $nographs
rename monto rfspPIDIREGAS
tempfile PIDIREGAS
save "`PIDIREGAS'"


** IPAB **
noisily DatosAbiertos RF000003SPFCS, $nographs
rename monto rfspIPAB
tempfile IPAB
save "`IPAB'"


** FONADIN **
noisily DatosAbiertos RF000004SPFCS, $nographs
rename monto rfspFONADIN
tempfile FONADIN
save "`FONADIN'"


** PROGRAMA DE DEUDORES **
noisily DatosAbiertos RF000005SPFCS, $nographs
rename monto rfspDeudores
tempfile Deudores
save "`Deudores'"


** BANCA DE DESARROLLO **
noisily DatosAbiertos RF000006SPFCS, $nographs
rename monto rfspBanca
tempfile Banca
save "`Banca'"


** ADECUACIONES PRESUPUESTARIAS **
noisily DatosAbiertos RF000007SPFCS, $nographs
rename monto rfspAdecuaciones
tempfile Adecuaciones
save "`Adecuaciones'"





************************************************
***                                          ***
***     3 Ajustes (RFSP vs. DIF. SHRFSP)     ***
***                                          ***
************************************************

** Activos financieros internos del SP **
noisily DatosAbiertos XED20, $nographs
rename monto activosInt
tempfile activosInt
save "`activosInt'"


** Activos financieros externos del SP **
noisily DatosAbiertos XEB10, $nographs
rename monto activosExt
tempfile activosExt
save "`activosExt'"


** Diferimientos **
noisily DatosAbiertos XOA0108, $nographs
rename monto diferimientos
tempfile diferimientos
save "`diferimientos'"


** Amortización **
noisily DatosAbiertos IF03230, $nographs
rename monto amortizacion
tempfile amortizacion
save "`amortizacion'"





*************************************************
***                                           ***
***     4 Balance público (Endeudamiento)     ***
***                                           ***
*************************************************

** Balance público **
noisily di _newline(2) in g "{bf: Endeudamiento público} en millones de pesos"
noisily DatosAbiertos XAA, $nographs
rename monto balancepublico
tempfile balancepublico
save "`balancepublico'"


** Endeudamiento presupuestario **
noisily DatosAbiertos XAA10, $nographs
rename monto presupuestario
tempfile presupuestario
save "`presupuestario'"


** Endeudamiento no presupuestario **
noisily DatosAbiertos XAA20, $nographs
rename monto nopresupuestario
tempfile nopresupuestario
save "`nopresupuestario'"



****************************************
* 4.1 Balance presupuestario (detalle) *

** Gobierno Federal **
noisily DatosAbiertos XAA11, $nographs
rename monto gobiernofederal
tempfile gobiernofederal
save "`gobiernofederal'"


** Pemex **
noisily DatosAbiertos XAA1210, $nographs
rename monto pemex
tempfile pemex
save "`pemex'"


** CFE **
noisily DatosAbiertos XOA0101, $nographs
rename monto cfe
tempfile cfe
save "`cfe'"


** IMSS **
noisily DatosAbiertos XOA0105, $nographs
rename monto imss
tempfile imss
save "`imss'"


** ISSSTE **
noisily DatosAbiertos XOA0106, $nographs
rename monto issste
tempfile issste
save "`issste'"





**********************************************
***                                        ***
***     5 Costo financiero de la deuda     ***
***                                        ***
**********************************************
noisily di _newline(2) in g "{bf: Costo financiero de la deuda} en millones de pesos"
noisily DatosAbiertos XAC21, $nographs
rename monto costofinanciero
tempfile costofinanciero
save "`costofinanciero'"


** Gobierno Federal **
noisily DatosAbiertos XBC21, $nographs
rename monto costogobiernofederal
tempfile costogobiernofederal
save "`costogobiernofederal'"


** Pemex **
noisily DatosAbiertos XOA0160, $nographs
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
rename monto costocfe
tempfile costocfe
save "`costocfe'"


noisily DatosAbiertos XOA0155, $nographs			// costo deuda interna
rename monto costodeudaInterno
tempfile costodeudaII
save "`costodeudaII'"

noisily DatosAbiertos XOA0156, $nographs			// costo deuda externa
rename monto costodeudaExterno
tempfile costodeudaEE
save "`costodeudaEE'"





********************************
***                          ***
***     6 Tipo de cambio     ***
***                          ***
********************************

* Deuda en pesos *
noisily DatosAbiertos XET30, $nographs
rename monto deudaMXN		
tempfile MXN
save "`MXN'"


* Deuda en dólares *
noisily DatosAbiertos XET40, $nographs
rename monto deudaUSD
tempfile USD
save "`USD'"





**********************/
***                 ***
***     7 Merge     ***
***                 ***
***********************

* Acervos *
use `shrfsp', clear
merge 1:1 (aniomes) using "`shrfspinterno'", nogen
merge 1:1 (aniomes) using "`shrfspexterno'", nogen


* Flujos *
merge 1:1 (aniomes) using "`rfsp'", nogen
merge 1:1 (aniomes) using "`Balance'", nogen
merge 1:1 (aniomes) using "`PIDIREGAS'", nogen
merge 1:1 (aniomes) using "`IPAB'", nogen
merge 1:1 (aniomes) using "`FONADIN'", nogen
merge 1:1 (aniomes) using "`Deudores'", nogen
merge 1:1 (aniomes) using "`Banca'", nogen
merge 1:1 (aniomes) using "`Adecuaciones'", nogen


* Adecuaciones *
merge 1:1 (aniomes) using "`nopresupuestario'", nogen
merge 1:1 (aniomes) using "`activosInt'", nogen
merge 1:1 (aniomes) using "`activosExt'", nogen
merge 1:1 (aniomes) using "`diferimientos'", nogen
merge 1:1 (aniomes) using "`amortizacion'", nogen


* Tipo de cambio *
merge 1:1 (aniomes) using "`MXN'", nogen
merge 1:1 (aniomes) using "`USD'", nogen


* Costos financieros *
merge 1:1 (aniomes) using "`costodeudaII'", nogen update
merge 1:1 (aniomes) using "`costodeudaEE'", nogen update
merge 1:1 (aniomes) using "`costopemex'", nogen
tsset aniomes


* Tipo de cambio *
g double tipoDeCambio = deudaMXN/deudaUSD
format tipoDeCambio %7.2fc


* Porcentaje interna y externa *
g porInterno = shrfspInterno/shrfsp
g porExterno = shrfspExterno/shrfsp


* Balance primario *
g balprimario = -rfspBala - costodeudaInt - costodeudaExt
format balprimario %20.0fc


* Guardar *
compress
if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'/SIM/SHRFSP.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'/SIM/SHRFSP.dta"', replace
}
