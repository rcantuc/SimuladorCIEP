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
noisily DatosAbiertos SHRF5000
keep anio mes monto mes
rename monto shrfsp
tempfile shrfsp
save "`shrfsp'"


** Interno **
noisily DatosAbiertos SHRF5100
keep anio mes monto mes
rename monto shrfspInterno
tempfile interno
save "`interno'"


** Externo **
noisily DatosAbiertos SHRF5200
keep anio mes monto mes
rename monto shrfspExterno
tempfile externo
save "`externo'"



***************************************
** 2 Balance público (Endeudamiento) **
***************************************
noisily di _newline(2) in g "{bf: Endeudamiento público} en millones de pesos"
noisily DatosAbiertos XAA
keep anio mes monto
rename monto balancepublico
tempfile balancepublico
save "`balancepublico'"


** Endeudamiento presupuestario **
noisily DatosAbiertos XAA10
keep anio mes monto
rename monto presupuestario
tempfile presupuestario
save "`presupuestario'"


** Endeudamiento no presupuestario **
noisily DatosAbiertos XAA20
keep anio mes monto
rename monto nopresupuestario
tempfile nopresupuestario
save "`nopresupuestario'"



******************************************
** 2.1 Balance presupuestario (detalle) **
******************************************
noisily di _newline(2) in g "{bf: Endeudamiento presupuestario} en millones de pesos"
** Gobierno Federal **
noisily DatosAbiertos XAA11
keep anio mes monto
rename monto gobiernofederal
tempfile gobiernofederal
save "`gobiernofederal'"


** Pemex **
noisily DatosAbiertos XAA1210
keep anio mes monto
rename monto pemex
tempfile pemex
save "`pemex'"


** CFE **
noisily DatosAbiertos XOA0101
keep anio mes monto
rename monto cfe
tempfile cfe
save "`cfe'"


** IMSS **
noisily DatosAbiertos XOA0105
keep anio mes monto
rename monto imss
tempfile imss
save "`imss'"


** ISSSTE **
noisily DatosAbiertos XOA0106
keep anio mes monto
rename monto issste
tempfile issste
save "`issste'"



************************************
** 3 Costo financiero de la deuda **
************************************
noisily di _newline(2) in g "{bf: Costo financiero de la deuda} en millones de pesos"
noisily DatosAbiertos XAC21
keep anio mes monto
rename monto costofinanciero
tempfile costofinanciero
save "`costofinanciero'"


** Gobierno Federal **
noisily DatosAbiertos XBC21
keep anio mes monto
rename monto costogobiernofederal
tempfile costogobiernofederal
save "`costogobiernofederal'"


** Pemex **
noisily DatosAbiertos XOA0160
keep anio mes monto
rename monto costopemex
tempfile costopemex
save "`costopemex'"


** CFE **
noisily DatosAbiertos XOA0162
keep anio mes monto
rename monto costocfe
tempfile costocfe
save "`costocfe'"




****************************
** 2 RFSP (Endeudamiento) **
****************************
noisily DatosAbiertos RF000000SPFCS
keep anio mes monto
rename monto rfsp
replace rfsp = -rfsp
tempfile rfsp
save "`rfsp'"


** Endeudamiento presupuestario **
noisily DatosAbiertos RF000001SPFCS
keep anio mes monto
rename monto rfspBalance
tempfile Balance
save "`Balance'"


noisily DatosAbiertos RF000002SPFCS			// PIDIREGAS
keep anio mes monto
rename monto rfspPIDIREGAS
tempfile PIDIREGAS
save "`PIDIREGAS'"

noisily DatosAbiertos RF000003SPFCS			// IPAB
keep anio mes monto
rename monto rfspIPAB
tempfile IPAB
save "`IPAB'"

noisily DatosAbiertos RF000004SPFCS			// FONADIN
keep anio mes monto
rename monto rfspFONADIN
tempfile FONADIN
save "`FONADIN'"

noisily DatosAbiertos RF000005SPFCS			// Programa de deudores
keep anio mes monto
rename monto rfspDeudores
tempfile Deudores
save "`Deudores'"

noisily DatosAbiertos RF000006SPFCS			// Banca de desarrollo
keep anio mes monto
rename monto rfspBanca
tempfile Banca
save "`Banca'"

noisily DatosAbiertos RF000007SPFCS			// Adecuaciones presupuestarias
keep anio mes monto
rename monto rfspAdecuaciones
tempfile Adecuaciones
save "`Adecuaciones'"




**********************
** 3 Tipo de cambio **
**********************
noisily DatosAbiertos XET30				// pesos
keep anio mes monto
rename monto deudaMXN		
tempfile MXN
save "`MXN'"

noisily DatosAbiertos XET40				// d{c o'}lares
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

noisily DatosAbiertos XOA0155			// costo deuda interna
keep anio mes monto
rename monto costodeudaInterno
tempfile costodeudaII
save "`costodeudaII'"

noisily DatosAbiertos XOA0156			// costo deuda externa
keep anio mes monto
rename monto costodeudaExterno
tempfile costodeudaEE
save "`costodeudaEE'"

PEF if divGA == 1, nographs
collapse (sum) amortizacion=gastoneto, by(anio)
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
tsset anio

** Tipo de cambio **
g double tipoDeCambio = deudaMXN/deudaUSD/1000
format tipoDeCambio %7.2fc

drop deuda*

compress
if `c(version)' > 13.1 {
	saveold `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', replace
}
