program define TasasEfectivas, return
quietly {

	timer on 8
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, ANIO(int `aniovp')]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Tasas Efectivas de los INGRESOS " in y `anio' "   }" in g _dup(20) "."



	***************************************
	*** 1 Sistema de Cuentas Nacionales ***
	***************************************
	SCN, anio(`anio') nographs
	use if anio == `anio' using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
	scalar PIB = pibY[1]



	****************************
	*** 2 Ingresos iniciales ***
	****************************
	noisily LIF, anio(`anio') //min(1) //graphs
	local recursos = r(divCIEP)
	foreach k of local recursos {
		local rec`=substr("`k'",1,7)' = r(`k')
	}

	* Al ingreso *
	capture confirm scalar ISRAS
	if _rc == 0 {
		local recISR_AS = scalar(ISRAS)/100*scalar(PIB)
	}
	else {
		local recISR_AS = `recISR_PF'*(783743.8/(783743.8+45756.7))
		scalar ISRAS  = (`recISR_AS')/scalar(PIB)*100 // 						ISR (asalariados)
	}
	capture confirm scalar ISRPF
	if _rc == 0 {
		local recISR_PF = scalar(ISRPF)/100*scalar(PIB)
	}
	else {
		local recISR_PF = `recISR_PF'*(45756.7/(783743.8+45756.7))
		scalar ISRPF  = (`recISR_PF')/scalar(PIB)*100 // 						ISR (personas f{c i'}sicas)
	}
	capture confirm scalar CuotasT
	if _rc == 0 {
		local recCuotas_ = scalar(CuotasT)/100*scalar(PIB)
	}
	else {
		scalar CuotasT = (`recCuotas_')/scalar(PIB)*100 // 						Cuotas (IMSS)
	}

	* Al consumo *
	capture confirm scalar IVA
	if _rc == 0 {
		local recIVA = scalar(IVA)/100*scalar(PIB)
	}
	else {
		scalar IVA     = `recIVA'/scalar(PIB)*100 //							IVA 
	}

	capture confirm scalar ISAN
	if _rc == 0 {
		local recISAN = scalar(ISAN)/100*scalar(PIB)
	}
	else {
		scalar ISAN    = `recISAN'/scalar(PIB)*100 //							ISAN
	}
	capture confirm scalar IEPS
	if _rc == 0 {
		local recIEPS = scalar(IEPS)/100*scalar(PIB)
	}
	else {
		local recIEPS = `recIEPS__p' + `recIEPS__n'
		scalar IEPS    = `recIEPS'/scalar(PIB)*100 // 							IEPS (no petrolero + petrolero)
	}
	capture confirm scalar Importa
	if _rc == 0 {
		local recImporta = scalar(Importa)/100*scalar(PIB)
	}
	else {
		scalar Importa = `recImporta'/scalar(PIB)*100 //						Importaciones
	}

	* Al capital *
	capture confirm scalar ISRPM
	if _rc == 0 {
		local recISR_PM = scalar(ISRPM)/100*scalar(PIB)
	}
	else {
		local recISR_PM = `recISR_PM'
		scalar ISRPM  = (`recISR_PM')/scalar(PIB)*100 //						ISR (personas morales)
	}
	capture confirm scalar FMP
	if _rc == 0 {
		local recFMP__De = scalar(FMP)/100*scalar(PIB)
	}
	else {
		scalar FMP     = (`recFMP__De')/scalar(PIB)*100 // 						Fondo Mexicano del Petr{c o'}leo
	}
	capture confirm scalar OYE
	if _rc == 0 {
		local recOYE = scalar(OYE)/100*scalar(PIB)
	}
	else {
		local recOYE = `recCFE'+`recPemex'+`recIMSS'+`recISSSTE'
		scalar OYE     = (`recOYE')/scalar(PIB)*100 //							Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
	}
	capture confirm scalar OtrosI
	if _rc == 0 {
		local recOtrosI = scalar(OtrosI)/100*scalar(PIB)
	}
	else {
		local recOtrosI = `recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib'
		scalar OtrosI  = (`recOtrosI')/scalar(PIB)*100 //						Productos, derechos, aprovechamientos, contribuciones
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
		_col(44) %7.3fc in y (RemSal)/scalar(PIB)*100 ///
		_col(55) in g "ISR (salarios)" ///
		_col(88) %7.3fc in y (`recISR_AS')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recISR_AS')/(RemSal)*100 " %"
	noisily di in g "  Ingreso mixto laboral" ///
		_col(44) %7.3fc in y MixL/scalar(PIB)*100 ///
		_col(55) in g "ISR (f{c i'}sicas)" ///
		_col(88) %7.3fc in y (`recISR_PF')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recISR_PF')/MixL*100 " %"
	noisily di in g "  Compensaci{c o'}n de asalariados" ///
		_col(44) %7.3fc in y (RemSal+SSImputada+SSEmpleadores)/scalar(PIB)*100 ///
		_col(55) in g "Cuotas IMSS" ///
		_col(88) %7.3fc in y (`recCuotas_')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recCuotas_')/(RemSal+SSImputada+SSEmpleadores)*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(44) %7.3fc in y (Yl)/scalar(PIB)*100 ///
		_col(55) in g "Impuestos al ingreso" ///
		_col(88) %7.3fc in y (`recISR_AS'+`recISR_PF'+`recCuotas_')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recISR_AS'+`recISR_PF'+`recCuotas_')/(Yl)*100 " %" "}"


	noisily di _newline(2) in y "{bf: B. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci{c o'}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Consumo hogares (sin alim.)" ///
		_col(44) %7.3fc in y (ConHog - Alim - BebN - Salu)/scalar(PIB)*100 ///
		_col(55) in g "IVA" ///
		_col(88) %7.3fc in y `recIVA'/scalar(PIB)*100 ///
		_col(99) %7.1fc in y `recIVA'/(ConHog - Alim - BebN - Salu)*100 " %"
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(44) %7.3fc in y Vehi/scalar(PIB)*100 ///
		_col(55) in g "ISAN" ///
		_col(88) %7.3fc in y `recISAN'/scalar(PIB)*100 ///
		_col(99) %7.1fc in y `recISAN'/Vehi*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/scalar(PIB)*100 ///
		_col(55) in g "IEPS" ///
		_col(88) %7.3fc in y `recIEPS'/scalar(PIB)*100 ///
		_col(99) %7.1fc in y `recIEPS'/ConHog*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/scalar(PIB)*100 ///
		_col(55) in g "Importaciones" ///
		_col(88) %7.3fc in y `recImporta'/scalar(PIB)*100 ///
		_col(99) %7.1fc in y `recImporta'/ConHog*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHog/scalar(PIB)*100 ///
		_col(55) in g "Impuestos al consumo" ///
		_col(88) %7.3fc in y (`recIEPS'+`recIVA'+`recISAN'+`recImporta')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recIEPS'+`recIVA'+`recISAN'+`recImporta')/ConHog*100 " %" "}"


	noisily di _newline(2) in y "{bf: C. " in y "Impuestos e ingresos de capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci{c o'}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Sociedades e ISFLSH" ///
		_col(44) %7.3fc in y (ExNOpSoc)/scalar(PIB)*100 ///
		_col(55) in g "ISR (morales)" ///
		_col(88) %7.3fc in y (`recISR_PM')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recISR_PM')/(ExNOpSoc)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/scalar(PIB)*100 ///
		_col(55) in g "FMP (petr{c o'}leo)" ///
		_col(88) %7.3fc in y (`recFMP__De')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recFMP__De')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/scalar(PIB)*100 ///
		_col(55) in g "CFE, Pemex, IMSS, ISSSTE" ///
		_col(88) %7.3fc in y (`recOYE')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recOYE')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (CapIncImp-ExNOpHog)/scalar(PIB)*100 ///
		_col(55) in g "Productos, derechos, aprovech..." ///
		_col(88) %7.3fc in y (`recOtrosI')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recOtrosI')/(CapIncImp-ExNOpHog)*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "  {bf:Ingreso de capital" ///
		_col(44) %7.3fc in y (CapIncImp)/scalar(PIB)*100 ///
		_col(55) in g "Impuestos e ingresos de capital" ///
		_col(88) %7.3fc in y (`recISR_PM'+`recFMP__De'+`recOYE'+`recOtrosI')/scalar(PIB)*100 ///
		_col(99) %7.1fc in y (`recISR_PM'+`recFMP__De'+`recOYE'+`recOtrosI')/(CapIncImp)*100 " %" "}"




	****************
	*** Base SIM ***
	****************
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

	* ISR *
	tabstat Laboral Consumo Otros ISR__PM ing_cap_fmp [fw=factor], stat(sum) f(%20.0fc) save
	matrix INGRESOS = r(StatTotal)

	replace Laboral = Laboral*((scalar(ISRAS)+scalar(ISRPF)+scalar(CuotasT))/100*scalar(PIB))/INGRESOS[1,1]
	replace Consumo = Consumo*((scalar(IVA)+scalar(ISAN)+scalar(IEPS)+scalar(Importa))/100*scalar(PIB))/INGRESOS[1,2]
	replace Otros = Otros*((scalar(ISRPM)+scalar(FMP)+scalar(OYE)+scalar(OtrosI))/100*scalar(PIB))/INGRESOS[1,3]

	replace ISR__PM = ISR__PM*((scalar(ISRPM))/100*scalar(PIB))/INGRESOS[1,4]
	replace ing_cap_fmp = ing_cap_fmp*((scalar(FMP))/100*scalar(PIB))/INGRESOS[1,5]

	tabstat Laboral Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
	matrix INGRESOSSIM = r(StatTotal)

	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace	
	}




	***************************/
	*** 6 Estimaciones de LP ***
	****************************
	tempname RECBase
	local j = 1
	foreach k in Laboral Consumo Otros {
		use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
		merge 1:1 (anio) using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
		tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
		matrix `RECBase' = r(StatTotal)

		replace estimacion = estimacion*INGRESOSSIM[1,`j']/`RECBase'[1,1] if anio >= `anio'

		local ++j
		if `c(version)' > 13.1 {
			saveold `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace version(13)
		}
		else {
			save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace		
		}
	}




	***********
	*** END ***
	***********
	capture drop __*
	timer off 8
	timer list 8
	noisily di _newline in g "Tiempo: " in y round(`=r(t8)/r(nt8)',.1) in g " segs."
}
end
