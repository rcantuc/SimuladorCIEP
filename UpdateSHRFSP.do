***************
** 0 MUNDIAL **
***************
if "$pais" != "" {
		run UpdateSHRFSPMundial.do `1'
		exit
}


************
** 1 RFSP **
************
noisily DatosAbiertos RF000000SPFCS			// Total
keep anio mes monto
rename monto rfsp
replace rfsp = -rfsp
tempfile rfsp
save `rfsp'

noisily DatosAbiertos RF000001SPFCS			// Balance tradicional
keep anio mes monto
rename monto rfspBalance
tempfile Balance
save `Balance'

noisily DatosAbiertos RF000002SPFCS			// PIDIREGAS
keep anio mes monto
rename monto rfspPIDIREGAS
tempfile PIDIREGAS
save `PIDIREGAS'

noisily DatosAbiertos RF000003SPFCS			// IPAB
keep anio mes monto
rename monto rfspIPAB
tempfile IPAB
save `IPAB'

noisily DatosAbiertos RF000004SPFCS			// FONADIN
keep anio mes monto
rename monto rfspFONADIN
tempfile FONADIN
save `FONADIN'

noisily DatosAbiertos RF000005SPFCS			// Programa de deudores
keep anio mes monto
rename monto rfspDeudores
tempfile Deudores
save `Deudores'

noisily DatosAbiertos RF000006SPFCS			// Banca de desarrollo
keep anio mes monto
rename monto rfspBanca
tempfile Banca
save `Banca'

noisily DatosAbiertos RF000007SPFCS			// Adecuaciones presupuestarias
keep anio mes monto
rename monto rfspAdecuaciones
tempfile Adecuaciones
save `Adecuaciones'



**************
** 2 SHRFSP **
**************
noisily DatosAbiertos SHRF5000				// Total
keep anio mes monto mes
rename monto shrfsp

tsset anio
replace shrfsp = L.shrfsp+D.shrfsp*12/mes if mes != 12
drop mes

tempfile shrfsp
save `shrfsp'

noisily DatosAbiertos SHRF5100				// Interno
keep anio mes monto mes
rename monto shrfspInterno

tsset anio
replace shrfspInterno = L.shrfspInterno+D.shrfspInterno*12/mes if mes != 12
drop mes

tempfile interno
save `interno'

noisily DatosAbiertos SHRF5200				// Externo
keep anio mes monto mes
rename monto shrfspExterno

tsset anio
replace shrfspExterno = L.shrfspExterno+D.shrfspExterno*12/mes if mes != 12
drop mes

tempfile externo
save `externo'




**********************
** 3 Tipo de cambio **
**********************
noisily DatosAbiertos XET30				// pesos
keep anio mes monto
rename monto deudaMXN		
tempfile MXN
save `MXN'

noisily DatosAbiertos XET40				// d{c o'}lares
keep anio mes monto
rename monto deudaUSD
tempfile USD
save `USD'



*********************************
** 4 Balance no presupuestario **
*********************************
noisily DatosAbiertos XAA20					// Balance no presupuestario
keep anio mes monto
rename monto nopresupuestario
tempfile nopresupuestario
save `nopresupuestario'



*************************
** 5 Costo de la deuda **
*************************
PEF if divGA == 2, anio(2020) nographs
collapse (sum) costodeuda=gastoneto, by(anio)
tempfile costodeuda
save `costodeuda'

PEF if divGA == 1, anio(2018) nographs
collapse (sum) amortizacion=gastoneto, by(anio)
tempfile amortizacion
save `amortizacion'



************/
** 6 Merge **
*************
use `rfsp', clear
capture merge 1:1 (anio) using `Balance', nogen
capture merge 1:1 (anio) using `PIDIREGAS', nogen
capture merge 1:1 (anio) using `IPAB', nogen
capture merge 1:1 (anio) using `FONADIN', nogen
capture merge 1:1 (anio) using `Deudores', nogen
capture merge 1:1 (anio) using `Banca', nogen
capture merge 1:1 (anio) using `Adecuaciones', nogen
merge 1:1 (anio) using `shrfsp', nogen
capture merge 1:1 (anio) using `interno', nogen
capture merge 1:1 (anio) using `externo', nogen
capture merge 1:1 (anio) using `MXN', nogen
capture merge 1:1 (anio) using `USD', nogen
capture merge 1:1 (anio) using `nopresupuestario', nogen
merge 1:1 (anio) using `costodeuda', nogen
merge 1:1 (anio) using `amortizacion', nogen
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
