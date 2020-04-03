program define TasasEfectivas, return
quietly {

	timer on 10
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, ANIO(int `aniovp') LIF]
	noisily di _newline(2) in g "{bf:TASAS EFECTIVAS: " in y "INGRESOS `anio'}"



	***************************************
	*** 1 Sistema de cuentas nacionales ***
	***************************************
	SCN, anio(`anio')



	*************
	*** 2 LIF ***
	*************
	LIF, anio(`anio') `lif'
	local recursos = r(divCIEP)
	foreach k of local recursos {
		local rec`=substr("`k'",1,7)' = r(`k')
	}



	********************
	*** 3 Resultados ***
	********************
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
		_col(88) %7.3fc in y (`recISR'*(783743.8/1687830.1))/PIB*100 ///
		_col(99) %7.1fc in y (`recISR'*(783743.8/1687830.1))/(RemSal)*100 " %"
	noisily di in g "  Ingreso mixto laboral" ///
		_col(44) %7.3fc in y MixL/PIB*100 ///
		_col(55) in g "ISR (f{c i'}sicas)" ///
		_col(88) %7.3fc in y (`recISR'*(45756.7/1687830.1))/PIB*100 ///
		_col(99) %7.1fc in y (`recISR'*(45756.7/1687830.1))/MixL*100 " %"
	noisily di in g "  Compensaci{c o'}n de asalariados (+ SS)" ///
		_col(44) %7.3fc in y RemSal/PIB*100 ///
		_col(55) in g "Cuotas IMSS" ///
		_col(88) %7.3fc in y (`recCuotas_')/PIB*100 ///
		_col(99) %7.1fc in y (`recCuotas_')/RemSal*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(44) %7.3fc in y (MixL+RemSal+SSImputada+SSEmpleadores)/PIB*100 ///
		_col(55) in g "Impuestos al ingreso" ///
		_col(88) %7.3fc in y (`recISR'*((783743.8+45756.7)/1687830.1)+`recCuotas_')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR'*((783743.8+45756.7)/1687830.1)+`recCuotas_')/(MixL+RemSal+SSImputada+SSEmpleadores)*100 " %" "}"

	scalar ISR_ASBase = (`recISR'*(783743.8/1687830.1))/PIB*100
	scalar ISR_PFBase = (`recISR'*(45756.7/1687830.1))/PIB*100
	scalar CuotasBase = (`recCuotas_')/PIB*100

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
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/PIB*100 ///
		_col(55) in g "IEPS" ///
		_col(88) %7.3fc in y (`recIEPS__p'+`recIEPS__n')/PIB*100 ///
		_col(99) %7.1fc in y (`recIEPS__p'+`recIEPS__n')/ConHog*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/PIB*100 ///
		_col(55) in g "Importaciones" ///
		_col(88) %7.3fc in y `recImporta'/PIB*100 ///
		_col(99) %7.1fc in y `recImporta'/ConHog*100 " %"
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(44) %7.3fc in y Vehi/PIB*100 ///
		_col(55) in g "ISAN" ///
		_col(88) %7.3fc in y `recISAN'/PIB*100 ///
		_col(99) %7.1fc in y `recISAN'/Vehi*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y (ConHog)/PIB*100 ///
		_col(55) in g "Impuestos al consumo" ///
		_col(88) %7.3fc in y (`recIEPS__p'+`recIEPS__n'+`recIVA'+`recISAN'+`recImporta')/PIB*100 ///
		_col(99) %7.1fc in y (`recIEPS__p'+`recIEPS__n'+`recIVA'+`recISAN'+`recImporta')/(ConHog)*100 " %" "}"
		
	scalar IVABase = `recIVA'/PIB*100
	scalar IEPSBase = (`recIEPS__p'+`recIEPS__n')/PIB*100
	scalar ImportaBase = `recImporta'/PIB*100
	scalar ISANBase = `recISAN'/PIB*100
	scalar ConsumoImp = (`recIEPS__p'+`recIEPS__n'+`recIVA'+`recISAN'+`recImporta')/PIB*100


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
		_col(88) %7.3fc in y (`recISR'*(803643.1/1687830.1))/PIB*100 ///
		_col(99) %7.1fc in y (`recISR'*(803643.1/1687830.1))/(ExNOpSoc)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/PIB*100 ///
		_col(55) in g "FMP (petr{c o'}leo)" ///
		_col(88) %7.3fc in y (`recFMP__De')/PIB*100 ///
		_col(99) %7.1fc in y (`recFMP__De')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/PIB*100 ///
		_col(55) in g "CFE, Pemex, IMSS, ISSSTE" ///
		_col(88) %7.3fc in y (`recCFE'+`recPemex'+`recIMSS'+`recISSSTE')/PIB*100 ///
		_col(99) %7.1fc in y (`recCFE'+`recPemex'+`recIMSS'+`recISSSTE')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/PIB*100 ///
		_col(55) in g "Productos, derechos, aprovech..." ///
		_col(88) %7.3fc in y (`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib')/PIB*100 ///
		_col(99) %7.1fc in y (`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "  {bf:Ingreso de capital" ///
		_col(44) %7.3fc in y (CapIncImp)/PIB*100 ///
		_col(55) in g "Impuestos e ingresos de capital" ///
		_col(88) %7.3fc in y (`recISR'*(803643.1/1687830.1)+`recPemex'+`recCFE'+`recIMSS'+`recISSSTE'+`recFMP__De'+`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec')/PIB*100 ///
		_col(99) %7.1fc in y (`recISR'*(803643.1/1687830.1)+`recPemex'+`recCFE'+`recIMSS'+`recISSSTE'+`recFMP__De'+`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec')/(CapIncImp)*100 " %" "}"

	scalar ISR_PMBase = (`recISR'*(803643.1/1687830.1))/PIB*100
	
	scalar FMPBase = (`recFMP__De')/PIB*100
	scalar OYEBase = (`recCFE'+`recPemex'+`recIMSS'+`recISSSTE')/PIB*100
	scalar OtrosIngBase = (`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib')/PIB*100

	***********
	*** END ***
	***********
	capture drop __*
	timer off 10
	timer list 10
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t10)/r(nt10)',.1) in g " segs."
}
end
