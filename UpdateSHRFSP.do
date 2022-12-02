***************
** 0 MUNDIAL **
***************
if "$pais" != "" {
	run UpdateSHRFSPMundial.do `1'
	exit
}



**************
** 1 SHRFSP **
**************
noisily di _newline(2) in g "{bf: Saldo de la deuda} en millones de pesos"
noisily DatosAbiertos SHRF5000, nog
keep anio mes monto mes
rename monto shrfsp
tempfile shrfsp
save "`shrfsp'"


** Interno **
noisily DatosAbiertos SHRF5100, nog
keep anio mes monto mes
rename monto shrfspInterno
tempfile interno
save "`interno'"


** Externo **
noisily DatosAbiertos SHRF5200, nog
keep anio mes monto mes
rename monto shrfspExterno
tempfile externo
save "`externo'"



***************************************
** 2 Balance público (Endeudamiento) **
***************************************
noisily di _newline(2) in g "{bf: Endeudamiento público} en millones de pesos"
noisily DatosAbiertos XAA, nog
keep anio mes monto
rename monto balancepublico
tempfile balancepublico
save "`balancepublico'"


** Endeudamiento presupuestario **
noisily DatosAbiertos XAA10, nog
keep anio mes monto
rename monto presupuestario
tempfile presupuestario
save "`presupuestario'"


** Endeudamiento no presupuestario **
noisily DatosAbiertos XAA20, nog
keep anio mes monto
rename monto nopresupuestario
tempfile nopresupuestario
save "`nopresupuestario'"


** Activos financieros **
noisily DatosAbiertos XEA10, nog
keep anio mes monto
rename monto activos
tempfile activos
save "`activos'"


** Diferimientos **
noisily DatosAbiertos XOA0108, nog
keep anio mes monto
rename monto diferimientos
tempfile diferimientos
save "`diferimientos'"



******************************************
** 2.1 Balance presupuestario (detalle) **
******************************************
noisily di _newline(2) in g "{bf: Endeudamiento presupuestario} en millones de pesos"
** Gobierno Federal **
noisily DatosAbiertos XAA11, nog
keep anio mes monto
rename monto gobiernofederal
tempfile gobiernofederal
save "`gobiernofederal'"


** Pemex **
noisily DatosAbiertos XAA1210, nog
keep anio mes monto
rename monto pemex
tempfile pemex
save "`pemex'"


** CFE **
noisily DatosAbiertos XOA0101, nog
keep anio mes monto
rename monto cfe
tempfile cfe
save "`cfe'"


** IMSS **
noisily DatosAbiertos XOA0105, nog
keep anio mes monto
rename monto imss
tempfile imss
save "`imss'"


** ISSSTE **
noisily DatosAbiertos XOA0106, nog
keep anio mes monto
rename monto issste
tempfile issste
save "`issste'"



************************************
** 3 Costo financiero de la deuda **
************************************
noisily di _newline(2) in g "{bf: Costo financiero de la deuda} en millones de pesos"
noisily DatosAbiertos XAC21, nog
keep anio mes monto
rename monto costofinanciero
tempfile costofinanciero
save "`costofinanciero'"


** Gobierno Federal **
noisily DatosAbiertos XBC21, nog
keep anio mes monto
rename monto costogobiernofederal
tempfile costogobiernofederal
save "`costogobiernofederal'"


** Pemex **
noisily DatosAbiertos XOA0160, nog
keep anio mes monto
rename monto costopemex
tempfile costopemex
save "`costopemex'"


** CFE **
noisily DatosAbiertos XOA0162, nog
keep anio mes monto
rename monto costocfe
tempfile costocfe
save "`costocfe'"




****************************
** 2 RFSP (Endeudamiento) **
****************************
noisily DatosAbiertos RF000000SPFCS, nog
keep anio mes monto
rename monto rfsp
replace rfsp = -rfsp
tempfile rfsp
save "`rfsp'"


** Endeudamiento presupuestario **
noisily DatosAbiertos RF000001SPFCS, nog
keep anio mes monto
rename monto rfspBalance
tempfile Balance
save "`Balance'"


noisily DatosAbiertos RF000002SPFCS, nog			// PIDIREGAS
keep anio mes monto
rename monto rfspPIDIREGAS
tempfile PIDIREGAS
save "`PIDIREGAS'"

noisily DatosAbiertos RF000003SPFCS, nog			// IPAB
keep anio mes monto
rename monto rfspIPAB
tempfile IPAB
save "`IPAB'"

noisily DatosAbiertos RF000004SPFCS, nog			// FONADIN
keep anio mes monto
rename monto rfspFONADIN
tempfile FONADIN
save "`FONADIN'"

noisily DatosAbiertos RF000005SPFCS, nog			// Programa de deudores
keep anio mes monto
rename monto rfspDeudores
tempfile Deudores
save "`Deudores'"

noisily DatosAbiertos RF000006SPFCS, nog			// Banca de desarrollo
keep anio mes monto
rename monto rfspBanca
tempfile Banca
save "`Banca'"

noisily DatosAbiertos RF000007SPFCS, nog			// Adecuaciones presupuestarias
keep anio mes monto
rename monto rfspAdecuaciones
tempfile Adecuaciones
save "`Adecuaciones'"




**********************
** 3 Tipo de cambio **
**********************
noisily DatosAbiertos XET30, nog				// pesos
keep anio mes monto
rename monto deudaMXN		
tempfile MXN
save "`MXN'"

noisily DatosAbiertos XET40, nog				// d{c o'}lares
keep anio mes monto
rename monto deudaUSD
tempfile USD
save "`USD'"




*************************/
** 5 Costo de la deuda **
*************************
/*PEF if desc_partida_generica == 33 | desc_partida_generica == 68 | desc_partida_generica == 88 ///
	| desc_partida_generica == 89 | desc_partida_generica == 90 | desc_partida_generica == 93, anio(2022) nographs
collapse (sum) costodeudaExterno=gastoneto, by(anio)
tempfile costodeudaE
save "`costodeudaE'"

PEF if desc_partida_generica == 34 | desc_partida_generica == 69 | desc_partida_generica == 91 ///
	| desc_partida_generica == 92, anio(2022) nographs
collapse (sum) costodeudaInterno=gastoneto, by(anio)
tempfile costodeudaI
save "`costodeudaI'"*/

noisily DatosAbiertos XOA0155, nog			// costo deuda interna
keep anio mes monto
rename monto costodeudaInterno
tempfile costodeudaII
save "`costodeudaII'"

noisily DatosAbiertos XOA0156, nog			// costo deuda externa
keep anio mes monto
rename monto costodeudaExterno
tempfile costodeudaEE
save "`costodeudaEE'"

noisily DatosAbiertos IF03230, nog			// amortizacion
keep anio mes monto
rename monto amortizacion
tempfile amortizacion
save "`amortizacion'"



************/
** 6 Merge **
*************
use `rfsp', clear
merge 1:1 (anio) using "`Balance'", nogen
merge 1:1 (anio) using "`PIDIREGAS'", nogen
merge 1:1 (anio) using "`IPAB'", nogen
merge 1:1 (anio) using "`FONADIN'", nogen
merge 1:1 (anio) using "`Deudores'", nogen
merge 1:1 (anio) using "`Banca'", nogen
merge 1:1 (anio) using "`Adecuaciones'", nogen
merge 1:1 (anio) using "`shrfsp'", nogen
merge 1:1 (anio) using "`interno'", nogen
merge 1:1 (anio) using "`externo'", nogen
merge 1:1 (anio) using "`MXN'", nogen
merge 1:1 (anio) using "`USD'", nogen
*merge 1:1 (anio) using "`nopresupuestario'", nogen
*merge 1:1 (anio) using "`costodeudaI'", nogen
*merge 1:1 (anio) using "`costodeudaE'", nogen
merge 1:1 (anio) using "`costodeudaII'", nogen update
merge 1:1 (anio) using "`costodeudaEE'", nogen update
merge 1:1 (anio) using "`amortizacion'", nogen
merge 1:1 (anio) using "`activos'", nogen
merge 1:1 (anio) using "`diferimientos'", nogen
tsset anio

** Tipo de cambio **
g double tipoDeCambio = deudaMXN/deudaUSD/1000
format tipoDeCambio %7.2fc

** Porcentaje interna y externa *
g porInterno = shrfspInterno/shrfsp
g porExterno = shrfspExterno/shrfsp

drop deuda*
compress
if `c(version)' > 13.1 {
	saveold `"`c(sysdir_site)'/SIM/SHRFSP.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'/SIM/SHRFSP.dta"', replace
}
