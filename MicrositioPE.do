*****************************************
****                                 ****
**** UPDATE PaqueteEconomico.ciep.mx ****
****                                 ****
*****************************************
timer on 19
putexcel set "`c(sysdir_personal)'../../DatosMicrositioApp.xlsx", modify sheet("Paquete")



*******************
*** 1. Ingresos ***
*******************
local inicio = 6
forvalues anio=2013(1)`=anioPE' {
	putexcel A`inicio' = `anio'
	noisily LIF, by(divMicrositio) rows(1) min(0) anio(`anio') desde(`=`anio'-1') nographs

	* ISR *
	putexcel B`inicio' = `=r(ISR)'/1000000, nformat(number_sep) right
	putexcel C`inicio' = `=r(ISRPIB)', nformat(0.0"%") right
	putexcel D`inicio' = `=r(ISRC)', nformat(0.0"%") right

	* IVA *
	putexcel E`inicio' = `=r(IVA)'/1000000, nformat(number_sep) right
	putexcel F`inicio' = `=r(IVAPIB)', nformat(0.0"%") right
	putexcel G`inicio' = `=r(IVAC)', nformat(0.0"%") right

	* FMP *
	putexcel H`inicio' = `=r(FMP)'/1000000, nformat(number_sep) right
	putexcel I`inicio' = `=r(FMPPIB)', nformat(0.0"%") right
	putexcel J`inicio' = `=r(FMPC)', nformat(0.0"%") right

	* CFE *
	putexcel K`inicio' = `=r(CFE)'/1000000, nformat(number_sep) right
	putexcel L`inicio' = `=r(CFEPIB)', nformat(0.0"%") right
	putexcel M`inicio' = `=r(CFEC)', nformat(0.0"%") right

	* Pemex *
	putexcel N`inicio' = `=r(Pemex)'/1000000, nformat(number_sep) right
	putexcel O`inicio' = `=r(PemexPIB)', nformat(0.0"%") right
	putexcel P`inicio' = `=r(PemexC)', nformat(0.0"%") right

	* IMSS e ISSSTE *
	putexcel Q`inicio' = `=r(IMSS_e_ISSSTE)'/1000000, nformat(number_sep) right
	putexcel R`inicio' = `=r(IMSS_e_ISSSTEPIB)', nformat(0.0"%") right
	putexcel S`inicio' = `=r(IMSS_e_ISSSTEC)', nformat(0.0"%") right

	* IEPS *
	putexcel T`inicio' = `=r(IEPS__petrolero_)'/1000000, nformat(number_sep) right
	putexcel U`inicio' = `=r(IEPS__petrolero_PIB)', nformat(0.0"%") right
	putexcel V`inicio' = `=r(IEPS__petrolero_C)', nformat(0.0"%") right

	* Otros ingresos *
	putexcel W`inicio' = `=r(Otros_ingresos)'/1000000, nformat(number_sep) right
	putexcel X`inicio' = `=r(Otros_ingresosPIB)', nformat(0.0"%") right
	putexcel Y`inicio' = `=r(Otros_ingresosC)', nformat(0.0"%") right

	* Total ingresos *
	putexcel Z`inicio' = `=r(Ingresos_sin_deuda)'/1000000, nformat(number_sep) right
	putexcel AA`inicio' = `=r(Ingresos_sin_deudaPIB)', nformat(0.0"%") right
	putexcel AB`inicio' = `=r(Ingresos_sin_deudaC)', nformat(0.0"%") right
	local ++inicio
}




*****************
*** 2. Gastos ***
*****************
local inicio = 25
forvalues anio=2013(1)`=anioPE' {
	putexcel A`inicio' = `anio'
	noisily PEF, by(divCIEP) rows(2) min(0) anio(`anio') desde(`=`anio'-1') nographs

	* Gasto federalizado *
	putexcel B`inicio' = `=r(Part_y_otras_Apor)'/1000000, nformat(number_sep) right
	putexcel C`inicio' = `=r(Part_y_otras_AporPIB)', nformat(0.0"%") right
	putexcel D`inicio' = `=r(Part_y_otras_AporC)', nformat(0.0"%") right

	* Pensiones *
	putexcel E`inicio' = `=(r(Pensiones)+r(Pension_AM))'/1000000, nformat(number_sep) right
	putexcel F`inicio' = `=r(PensionesPIB)+r(Pension_AMPIB)', nformat(0.0"%") right
	putexcel G`inicio' = `=r(PensionesC)+r(Pension_AMC)', nformat(0.0"%") right

	* Energía *
	putexcel H`inicio' = `=r(Energia)'/1000000, nformat(number_sep) right
	putexcel I`inicio' = `=r(EnergiaPIB)', nformat(0.0"%") right
	putexcel J`inicio' = `=r(EnergiaC)', nformat(0.0"%") right

	* Educación *
	putexcel K`inicio' = `=r(Educacion)'/1000000, nformat(number_sep) right
	putexcel L`inicio' = `=r(EducacionPIB)', nformat(0.0"%") right
	putexcel M`inicio' = `=r(EducacionC)', nformat(0.0"%") right

	* Costo de la deuda *
	putexcel N`inicio' = `=r(Costo_de_la_deuda)'/1000000, nformat(number_sep) right
	putexcel O`inicio' = `=r(Costo_de_la_deudaPIB)', nformat(0.0"%") right
	putexcel P`inicio' = `=r(Costo_de_la_deudaC)', nformat(0.0"%") right

	* Salud *
	putexcel Q`inicio' = `=r(Salud)'/1000000, nformat(number_sep) right
	putexcel R`inicio' = `=r(SaludPIB)', nformat(0.0"%") right
	putexcel S`inicio' = `=r(SaludC)', nformat(0.0"%") right

	* Otras inversiones *
	putexcel T`inicio' = `=r(Otras_inversiones)'/1000000, nformat(number_sep) right
	putexcel U`inicio' = `=r(Otras_inversionesPIB)', nformat(0.0"%") right
	putexcel V`inicio' = `=r(Otras_inversionesC)', nformat(0.0"%") right

	* Otros gastos *
	putexcel W`inicio' = `=r(Otros_gastos)'/1000000, nformat(number_sep) right
	putexcel X`inicio' = `=r(Otros_gastosPIB)', nformat(0.0"%") right
	putexcel Y`inicio' = `=r(Otros_gastosC)', nformat(0.0"%") right

	* Total gastos *
	putexcel Z`inicio' = `=r(Gasto_neto)'/1000000, nformat(number_sep) right
	putexcel AA`inicio' = `=r(Gasto_netoPIB)', nformat(0.0"%") right
	putexcel AB`inicio' = `=r(Gasto_netoC)', nformat(0.0"%") right

	local ++inicio
}



****************
*** 3. Deuda ***
****************
local inicio = 44
forvalues anio=2013(1)`=anioPE' {
	putexcel A`inicio' = `anio'
	noisily SHRFSP, anio(`anio') ultanio(2013) nographs //update

	* Balance presupuestario *
	putexcel B`inicio' = `=r(rfspBalance)'/1000000, nformat(number_sep) right
	putexcel C`inicio' = `=r(rfspBalancePIB)', nformat(0.0"%") right
	putexcel D`inicio' = `=r(rfspBalancePC)', nformat(number_sep) right

	* Otros RFSP *
	putexcel E`inicio' = `=r(rfspOtros)'/1000000, nformat(number_sep) right
	putexcel F`inicio' = `=r(rfspOtrosPIB)', nformat(0.0"%") right
	putexcel G`inicio' = `=r(rfspOtrosPC)', nformat(number_sep) right

	* RFSP *
	putexcel H`inicio' = `=r(rfsp)'/1000000, nformat(number_sep) right
	putexcel I`inicio' = `=r(rfspPIB)', nformat(0.0"%") right
	putexcel J`inicio' = `=r(rfspPC)', nformat(number_sep) right

	* SHRFSP *
	putexcel K`inicio' = -`=r(shrfsp)'/1000000, nformat(number_sep) right
	putexcel L`inicio' = -`=r(shrfspPIB)', nformat(0.0"%") right
	putexcel M`inicio' = -`=r(shrfspPC)', nformat(number_sep) right

	local ++inicio
}
timer off 19
timer list 19
noisily di _newline in g "Tiempo: " in y round(`=r(t19)/r(nt19)', 0.01) in g " segs."
