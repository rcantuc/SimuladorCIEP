**********
** RFSP **
**********
noisily DatosAbiertos RF000000SPFCS, pibvp(-2.7) pibvf(-2.6)						// Total
rename monto rfsp
drop clave nombre mes monto_pib pibY
tempfile rfsp
save `rfsp'

noisily DatosAbiertos RF000002SPFCS, pibvp(0) pibvf(-.1)			// PIDIREGAS
rename monto rfspPIDIREGAS
drop clave nombre mes monto_pib pibY
tempfile PIDIREGAS
save `PIDIREGAS'

noisily DatosAbiertos RF000003SPFCS, pibvp(0) pibvf(-.1)			// IPAB
rename monto rfspIPAB
drop clave nombre mes monto_pib pibY
tempfile IPAB
save `IPAB'

noisily DatosAbiertos RF000004SPFCS, pibvp(0) pibvf(-.1)			// FONADIN
rename monto rfspFONADIN
drop clave nombre mes monto_pib pibY
tempfile FONADIN
save `FONADIN'

noisily DatosAbiertos RF000005SPFCS, pibvp(0) pibvf(0)			// Programa de deudores
rename monto rfspDeudores
drop clave nombre mes monto_pib pibY
tempfile Deudores
save `Deudores'

noisily DatosAbiertos RF000006SPFCS, pibvp(.1) pibvf(.1)			// Banca de desarrollo
rename monto rfspBanca
drop clave nombre mes monto_pib pibY
tempfile Banca
save `Banca'

noisily DatosAbiertos RF000007SPFCS, pibvp(-.9) pibvf(-.3)			// Adecuaciones presupuestarias
rename monto rfspAdecuaciones
drop clave nombre mes monto_pib pibY
tempfile Adecuaciones
save `Adecuaciones'

noisily DatosAbiertos RF000001SPFCS						// Balance tradicional
rename monto rfspBalance
drop clave nombre mes monto_pib pibY
tempfile Balance
save `Balance'



************
** SHRFSP **
************
noisily DatosAbiertos SHRF5000, pibvp(45.3) pibvf(45.6)			// Total
rename monto shrfsp
drop clave nombre mes monto_pib pibY
tempfile shrfsp
save `shrfsp'

noisily DatosAbiertos SHRF5100, pibvp(29.2) pibvf(29.8)			// Interno
rename monto shrfspInterno
drop clave nombre mes monto_pib pibY
tempfile interno
save `interno'

noisily DatosAbiertos SHRF5200, pibvp(16.0) pibvf(15.8)			// Externo
rename monto shrfspExterno
drop clave nombre mes monto_pib pibY
tempfile externo
save `externo'


********************
** Tipo de cambio **
********************
noisily DatosAbiertos XET30							// pesos
rename monto deudaMXN		
drop clave nombre mes monto_pib pibY
tempfile MXN
save `MXN'

noisily DatosAbiertos XET40							// d${o}lares
rename monto deudaUSD
drop clave nombre mes monto_pib pibY
tempfile USD
save `USD'


**************************************
** Operaciones compensadas (ISSSTE) **
/**************************************
noisily DatosAbiertos XAC5210, //pibvf(2.580355)				// Operaciones compensadas (ISSSTE)
rename monto operaciones
drop clave nombre mes monto_pib pibY
tempfile operaciones
save `operaciones'


******************************/
** Balance no presupuestario **
*******************************
noisily DatosAbiertos XAA20, //pibvf(0)						// Balance no presupuestario
rename monto nopresupuestario
drop clave nombre mes monto_pib pibY
tempfile nopresupuestario
save `nopresupuestario'


*********
** LIF **
*********
LIF
collapse (sum) recaudacion if divLIF != 10, by(anio)
tempfile LIF
save `LIF'

LIF
collapse (sum) diferimientos=LIF if divCIEP == 8, by(anio)
tempfile diferimientos
save `diferimientos'



*********
** PEF **
*********
noisily DatosAbiertos XAC
rename monto gastopagado
drop clave nombre mes monto_pib pibY
tempfile gastopagado
save `gastopagado'

PEF, by(ramo)
collapse (sum) gastoneto if /*ramo != 34 &*/ ramo != -1 & transf_gf == 0, by(anio)
tempfile PEF
save `PEF'


***********
** Merge **
***********
use `rfsp', clear
merge 1:1 (anio) using `PIDIREGAS', nogen
merge 1:1 (anio) using `IPAB', nogen
merge 1:1 (anio) using `FONADIN', nogen
merge 1:1 (anio) using `Deudores', nogen
merge 1:1 (anio) using `Banca', nogen
merge 1:1 (anio) using `Adecuaciones', nogen
merge 1:1 (anio) using `Balance', nogen
merge 1:1 (anio) using `shrfsp', nogen
merge 1:1 (anio) using `interno', nogen
merge 1:1 (anio) using `externo', nogen
merge 1:1 (anio) using `MXN', nogen
merge 1:1 (anio) using `USD', nogen
*merge 1:1 (anio) using `operaciones', nogen
merge 1:1 (anio) using `nopresupuestario', nogen
merge 1:1 (anio) using `LIF', nogen
merge 1:1 (anio) using `diferimientos', nogen
merge 1:1 (anio) using `PEF', nogen
merge 1:1 (anio) using `gastopagado', nogen
tsset anio


** Tipo de cambio **
g double tipoDeCambio = deudaMXN/deudaUSD/1000
format tipoDeCambio %7.2fc
drop deuda* acum_prom

save "`c(sysdir_site)'../basesCIEP/SIM/SHRFSP.dta", replace
