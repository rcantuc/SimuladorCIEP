
** RFSP **
noisily DatosAbiertos RF000000SPFCS //if subtema != "RFSP"			// Total
rename monto rfsp
drop clave nombre mes monto_pib pibY
tempfile rfsp
save `rfsp'

noisily DatosAbiertos RF000002SPFCS //if nombre != ""				// PIDIREGAS
rename monto rfspPIDIREGAS
drop clave nombre mes monto_pib pibY
tempfile PIDIREGAS
save `PIDIREGAS'

noisily DatosAbiertos RF000003SPFCS //if nombre != ""				// IPAB
rename monto rfspIPAB
drop clave nombre mes monto_pib pibY
tempfile IPAB
save `IPAB'

noisily DatosAbiertos RF000004SPFCS //if nombre != ""				// FONADIN
rename monto rfspFONADIN
drop clave nombre mes monto_pib pibY
tempfile FONADIN
save `FONADIN'

noisily DatosAbiertos RF000005SPFCS //if nombre != ""				// Programa de deudores
rename monto rfspDeudores
drop clave nombre mes monto_pib pibY
tempfile Deudores
save `Deudores'

noisily DatosAbiertos RF000006SPFCS //if nombre != ""				// Banca de desarrollo
rename monto rfspBanca
drop clave nombre mes monto_pib pibY
tempfile Banca
save `Banca'

noisily DatosAbiertos RF000007SPFCS //if nombre != ""				// Adecuaciones presupuestarias
rename monto rfspAdecuaciones
drop clave nombre mes monto_pib pibY
tempfile Adecuaciones
save `Adecuaciones'

noisily DatosAbiertos RF000001SPFCS //if nombre != ""				// Balance tradicional
rename monto rfspBalance
drop clave nombre mes monto_pib pibY
tempfile Balance
save `Balance'



** SHRFSP **
noisily DatosAbiertos SHRF5000							// Total
rename monto shrfsp
drop clave nombre mes monto_pib pibY
tempfile shrfsp
save `shrfsp'

noisily DatosAbiertos SHRF5100							// Interno
rename monto shrfspInterno
drop clave nombre mes monto_pib pibY
tempfile interno
save `interno'

noisily DatosAbiertos SHRF5200							// Externo
rename monto shrfspExterno
drop clave nombre mes monto_pib pibY
tempfile externo
save `externo'


** Tipo de cambio **
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


** Diferimientos de pagos **
noisily DatosAbiertos XOA0764							// Diferimientos de pagos
rename monto diferimientos
drop clave nombre mes monto_pib pibY
tempfile diferimientos
save `diferimientos'


** Balance no presupuestario **
noisily DatosAbiertos XAA20							// Balance no presupuestario
rename monto nopresupuestario
drop clave nombre mes monto_pib pibY
tempfile nopresupuestario
save `nopresupuestario'


** LIF **
LIF
collapse (sum) recaudacion if divLIF!= 3 & divLIF != 10, by(anio)
tempfile LIF
save `LIF'


** PEF **
PEF, datos
collapse (sum) gastoneto if neto == 0 & desc_funcion != 1, by(anio)
tempfile PEF
save `PEF'


** Merge **
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
merge 1:1 (anio) using `diferimientos', nogen
merge 1:1 (anio) using `nopresupuestario', nogen
merge 1:1 (anio) using `LIF', nogen
merge 1:1 (anio) using `PEF', nogen
tsset anio


** Tipo de cambio **
g double tipoDeCambio = deudaMXN/deudaUSD/1000
format tipoDeCambio %7.2fc
drop deuda* acum_prom

save "`c(sysdir_site)'/bases/SIM/SHRFSP.dta", replace
