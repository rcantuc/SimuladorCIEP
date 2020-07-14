program define TasasEfectivas, return
quietly {

	timer on 8
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, ANIO(int `aniovp')]



	***************************************
	*** 1 Sistema de cuentas nacionales ***
	***************************************
	noisily SCN, anio(`anio') graphs



	*************
	*** 2 LIF ***
	*************
	noisily LIF, anio(`anio')
	local recursos = r(divCIEP)
	foreach k of local recursos {
		local rec`=substr("`k'",1,7)' = r(`k')
	}

	capture confirm scalar ISR_AS
	if _rc == 0 {
		local recISR_AS = scalar(ISR_AS)/100*scalar(PIB)
	}
	else {
		local recISR_AS = `recISR'*(783743.8/1687830.1)
	}
	capture confirm scalar ISR_PF
	if _rc == 0 {
		local recISR_PF = scalar(ISR_PF)/100*scalar(PIB)
	}
	else {
		local recISR_PF = `recISR'*(45756.7/1687830.1)
	}
	capture confirm scalar CuotasT
	if _rc == 0 {
		local recCuotas_ = scalar(CuotasT)/100*scalar(PIB)
	}

	capture confirm scalar IVA
	if _rc == 0 {
		local recIVA = scalar(IVA)/100*scalar(PIB)
	}
	capture confirm scalar ISAN
	if _rc == 0 {
		local recISAN = scalar(ISAN)/100*scalar(PIB)
	}
	capture confirm scalar IEPS
	if _rc == 0 {
		local recIEPS = scalar(IEPS)/100*scalar(PIB)
	}
	else {
		local recIEPS = `recIEPS__p' + `recIEPS__n'
	}
	capture confirm scalar Importa
	if _rc == 0 {
		local recImporta = scalar(Importa)/100*scalar(PIB)
	}

	capture confirm scalar ISR_PM
	if _rc == 0 {
		local recISR_PM = scalar(ISR_PM)/100*scalar(PIB)
	}
	else {
		local recISR_PM = `recISR'*((1687830.1-(783743.8+45756.7))/1687830.1)
	}
	capture confirm scalar FMP
	if _rc == 0 {
		local recFMP__De = scalar(FMP)/100*scalar(PIB)
	}
	capture confirm scalar OYE
	if _rc == 0 {
		local recOYE = scalar(OYE)/100*scalar(PIB)
	}
	else {
		local recOYE = `recCFE'+`recPemex'+`recIMSS'+`recISSSTE'
	}
	capture confirm scalar OtrosI
	if _rc == 0 {
		local recOtrosI = scalar(OtrosI)/100*scalar(PIB)
	}
	else {
		local recOtrosI = `recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib'
	}



	********************
	*** 3 Resultados ***
	********************
	noisily di _newline(2) in g _dup(20) "." "{bf:   Tasas Efectivas de los INGRESOS " in y `anio' "   }" in g _dup(20) "."

	noisily di _newline(2) in y "{bf: A. " in y "Impuestos al ingreso" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci{c o'}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Compensaci{c o'}n de asalariados" ///
		_col(44) %7.3fc in y (RemSal)/PIB*100 ///
		_col(55) in g "ISR (salarios)" ///
		_col(88) %7.3fc in y (`recISR_AS')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR_AS')/(RemSal)*100 " %"
	noisily di in g "  Ingreso mixto laboral" ///
		_col(44) %7.3fc in y MixL/PIB*100 ///
		_col(55) in g "ISR (f{c i'}sicas)" ///
		_col(88) %7.3fc in y (`recISR_PF')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR_PF')/MixL*100 " %"
	noisily di in g "  Compensaci{c o'}n de asalariados (+ Cuotas SS)" ///
		_col(44) %7.3fc in y (RemSal+SSImputada+SSEmpleadores)/PIB*100 ///
		_col(55) in g "Cuotas IMSS" ///
		_col(88) %7.3fc in y (`recCuotas_')/PIB*100 ///
		_col(99) %7.1fc in y (`recCuotas_')/(RemSal+SSImputada+SSEmpleadores)*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(44) %7.3fc in y (Yl)/PIB*100 ///
		_col(55) in g "Impuestos al ingreso" ///
		_col(88) %7.3fc in y (`recISR_AS'+`recISR_PF'+`recCuotas_')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR_AS'+`recISR_PF'+`recCuotas_')/(Yl)*100 " %" "}"


	noisily di _newline(2) in y "{bf: B. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci{c o'}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Consumo hogares e ISFLSH (no b{c a'}sico)" ///
		_col(44) %7.3fc in y (ConHog - Alim - BebN)/PIB*100 ///
		_col(55) in g "IVA" ///
		_col(88) %7.3fc in y `recIVA'/PIB*100 ///
		_col(99) %7.1fc in y `recIVA'/(ConHog - Alim - BebN)*100 " %"
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(44) %7.3fc in y Vehi/PIB*100 ///
		_col(55) in g "ISAN" ///
		_col(88) %7.3fc in y `recISAN'/PIB*100 ///
		_col(99) %7.1fc in y `recISAN'/Vehi*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/PIB*100 ///
		_col(55) in g "IEPS" ///
		_col(88) %7.3fc in y (`recIEPS')/PIB*100 ///
		_col(99) %7.1fc in y (`recIEPS')/ConHog*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/PIB*100 ///
		_col(55) in g "Importaciones" ///
		_col(88) %7.3fc in y `recImporta'/PIB*100 ///
		_col(99) %7.1fc in y `recImporta'/ConHog*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y (ConHog)/PIB*100 ///
		_col(55) in g "Impuestos al consumo" ///
		_col(88) %7.3fc in y (`recIEPS'+`recIVA'+`recISAN'+`recImporta')/PIB*100 ///
		_col(99) %7.1fc in y (`recIEPS'+`recIVA'+`recISAN'+`recImporta')/(ConHog)*100 " %" "}"


	noisily di _newline(2) in y "{bf: C. " in y "Impuestos e ingresos de capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci{c o'}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Sociedades e ISFLSH" ///
		_col(44) %7.3fc in y (ExNOpSoc)/PIB*100 ///
		_col(55) in g "ISR (morales)" ///
		_col(88) %7.3fc in y (`recISR_PM')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR_PM')/(ExNOpSoc)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/PIB*100 ///
		_col(55) in g "FMP (petr{c o'}leo)" ///
		_col(88) %7.3fc in y (`recFMP__De')/PIB*100 ///
		_col(99) %7.1fc in y (`recFMP__De')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/PIB*100 ///
		_col(55) in g "CFE, Pemex, IMSS, ISSSTE" ///
		_col(88) %7.3fc in y (`recOYE')/PIB*100 ///
		_col(99) %7.1fc in y (`recOYE')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/PIB*100 ///
		_col(55) in g "Productos, derechos, aprovech..." ///
		_col(88) %7.3fc in y (`recOtrosI')/PIB*100 ///
		_col(99) %7.1fc in y (`recOtrosI')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "  {bf:Ingreso de capital" ///
		_col(44) %7.3fc in y (CapIncImp)/PIB*100 ///
		_col(55) in g "Impuestos e ingresos de capital" ///
		_col(88) %7.3fc in y (`recISR_PM'+`recFMP__De'+`recOYE'+`recOtrosI')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR_PM'+`recFMP__De'+`recOYE'+`recOtrosI')/(CapIncImp)*100 " %" "}"


	***********
	*** END ***
	***********
	capture drop __*
	timer off 8
	timer list 8
	noisily di _newline in g "Tiempo: " in y round(`=r(t8)/r(nt8)',.1) in g " segs."
}
end
