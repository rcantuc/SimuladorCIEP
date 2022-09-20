program define TasasEfectivas, return
quietly {

	timer on 8
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	syntax [, ANIO(int `aniovp') NOGraphs CRECSIM(real 1)]
	noisily di _newline(2) in g _dup(35) "." "{bf:   Tasas Efectivas de los INGRESOS " in y `anio' "   }" in g _dup(35) "."



	***************************************************************
	*** 1 Cuentas macroeconómicas (SCN, PIB, Balanza Comercial) ***
	***************************************************************
	*use if anio == `anio' using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
	PIBDeflactor, aniovp(`anio') nographs nooutput
	keep if anio == `anio'
	local PIB = pibY[1]

	balanzacomercial, anio(`anio')

	SCN, anio(`anio') nographs



	*********************
	*** 2 RECAUDACIÓN ***
	*********************
	LIF, anio(`anio') by(divSIM) rows(2) nographs
	local recursos = r(divSIM)
	foreach k of local recursos {
		local `=substr("`k'",1,7)' = r(`k')
		local `=substr("`k'",1,7)' = ``=substr("`k'",1,7)''/`PIB'*100
	}


	noisily di _newline(2) in y "{bf: A. " in y "Impuestos a los ingresos laborales" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Impuestos a las personas f{c i'}sicas" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"

	// ISR (asalariados)
	capture confirm scalar ISRAS
	if _rc == 0 {
		local ISRAS = scalar(ISRAS)					// <-- Para el display
	}
	else {
		scalar ISRAS = `ISRAS'						// <-- Para el simulador (Sankey, FiscalGap)
	}
	noisily di in g "  Compensaci{c o'}n de asalariados (sin CSS)" ///
		_col(44) %7.3fc in y RemSalPIB ///
		_col(55) in g "ISR (salarios)" ///
		_col(88) %7.3fc in y (`ISRAS') ///
		_col(99) %7.3fc in y (`ISRAS')/RemSalPIB*100 " %"

	// ISR (personas f{c i'}sicas)
	capture confirm scalar ISRPF
	if _rc == 0 {
		local ISRPF = scalar(ISRPF)
	}
	else {
		scalar ISRPF = `ISRPF'
	}
	noisily di in g "  Ingreso mixto laboral" ///
		_col(44) %7.3fc in y MixLPIB ///
		_col(55) in g "ISR (f{c i'}sicas)" ///
		_col(88) %7.3fc in y (`ISRPF') ///
		_col(99) %7.3fc in y (`ISRPF')/MixLPIB*100 " %"

	// Cuotas (IMSS)
	capture confirm scalar CUOTAS
	if _rc == 0 {
		local CUOTAS = scalar(CUOTAS)
	}
	else {
		scalar CUOTAS = `CUOTAS'
	}

	noisily di in g "  Compensaci{c o'}n de asalariados" ///
		_col(44) %7.3fc in y (RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB) ///
		_col(55) in g "Cuotas IMSS" ///
		_col(88) %7.3fc in y (`CUOTAS') ///
		_col(99) %7.3fc in y (`CUOTAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB)*100 " %"

	// TOTAL LABORALES
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(44) %7.3fc in y (YlPIB) ///
		_col(55) in g "Recaudaci{c o'}n total" ///
		_col(88) %7.3fc in y (`ISRAS'+`ISRPF'+`CUOTAS') ///
		_col(99) %7.3fc in y (`ISRAS'+`ISRPF'+`CUOTAS')/(YlPIB)*100 " %" "}"

	noisily di _newline(2) in y "{bf: B. " in y "Impuestos a los ingresos de capital privado" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Impuestos a las personas morales" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"

	// ISR (personas morales)
	capture confirm scalar ISRPM
	if _rc == 0 {
		local ISRPM = scalar(ISRPM)
	}
	else {
		scalar ISRPM = (`ISRPM')
	}
	noisily di in g "  Sociedades e ISFLSH (netos)" ///
		_col(44) %7.3fc in y (ExNOpSocPIB+ImpNetProduccionKPIB+ImpNetProductosPIB) ///
		_col(55) in g "ISR (morales)" ///
		_col(88) %7.3fc in y (`ISRPM') ///
		_col(99) %7.3fc in y (`ISRPM')/(ExNOpSocPIB)*100 " %"

	noisily di in g "  Sociedades e ISFLSH (netos)" ///
		_col(44) %7.3fc in y (ExNOpSocPIB+ImpNetProduccionKPIB+ImpNetProductosPIB) ///
		_col(55) in g "Productos, derechos, aprovech..." ///
		_col(88) %7.3fc in y (`OTROSK') ///
		_col(99) %7.3fc in y (`OTROSK')/(ExNOpSocPIB)*100 " %"

	// TOTAL CAPITAL PRIVADO
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos de capital (netos)" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "Recaudaci{c o'}n total" ///
		_col(88) %7.3fc in y (`ISRPM'+`OTROSK') ///
		_col(99) %7.3fc in y (`ISRPM'+`OTROSK')/(CapIncImpPIB)*100 " %" "}"



	noisily di _newline(2) in y "{bf: C. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Impuestos al consumo" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"

	// IVA
	capture confirm scalar IVA
	if _rc == 0 {
		local IVA = scalar(IVA)
	}
	else {
		scalar IVA = `IVA'
	}
	noisily di in g "  Consumo hogares e ISFLSH*" ///
		_col(44) %7.3fc in y (ConHogPIB - AlimPIB - BebNPIB - SaluPIB) ///
		_col(55) in g "IVA" ///
		_col(88) %7.3fc in y `IVA' ///
		_col(99) %7.3fc in y `IVA'/(ConHogPIB - AlimPIB - BebNPIB - SaluPIB)*100 " %"

	// ISAN
	capture confirm scalar ISAN
	if _rc == 0 {
		local ISAN = scalar(ISAN)
	}
	else {
		scalar ISAN = `ISAN' 
	}
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(44) %7.3fc in y VehiPIB ///
		_col(55) in g "ISAN" ///
		_col(88) %7.3fc in y `ISAN' ///
		_col(99) %7.3fc in y `ISAN'/VehiPIB*100 " %"

	// IEPS (no petrolero)
	capture confirm scalar IEPSNP
	if _rc == 0 {
		local IEPSNP = scalar(IEPSNP)
	}
	else {
		scalar IEPSNP = `IEPSNP'
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "IEPS (no petrolero)" ///
		_col(88) %7.3fc in y `IEPSNP' ///
		_col(99) %7.3fc in y `IEPSNP'/ConHogPIB*100 " %"

	// IEPS (petrolero)
	capture confirm scalar IEPSP
	if _rc == 0 {
		local IEPSP = scalar(IEPSP)
	}
	else {
		scalar IEPSP = `IEPSP'
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "IEPS (petrolero)" ///
		_col(88) %7.3fc in y `IEPSP' ///
		_col(99) %7.3fc in y `IEPSP'/ConHogPIB*100 " %"

	// Importaciones
	capture confirm scalar IMPORT
	if _rc == 0 {
		local IMPORT = scalar(IMPORT)
	}
	else {
		scalar IMPORT = `IMPORT' 
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "Importaciones" ///
		_col(88) %7.3fc in y `IMPORT' ///
		_col(99) %7.3fc in y `IMPORT'/ConHogPIB*100 " %"

	// TOTAL CONSUMO
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "Recaudaci{c o'}n total" ///
		_col(88) %7.3fc in y (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT') ///
		_col(99) %7.3fc in y (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')/ConHogPIB*100 " %" "}"
	scalar ingconsumoPIB = (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')



	noisily di _newline(2) in y "{bf: D. " in y "Ingresos de capital p{c u'}blico" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Organismos y empresas" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"

	// Energía
	capture confirm scalar FMP
	if _rc == 0 {
		local FMP = scalar(FMP)
	}
	else {
		scalar FMP = (`FMP') 
	}
	capture confirm scalar PEMEX
	if _rc == 0 {
		local PEMEX = scalar(PEMEX)
	}
	else {
		scalar PEMEX = (`PEMEX') 
	}
	capture confirm scalar CFE
	if _rc == 0 {
		local CFE = scalar(CFE)
	}
	else {
		scalar CFE = (`CFE') 
	}

	// IMSS + ISSSTE
	capture confirm scalar IMSS
	if _rc == 0 {
		local IMSS = scalar(IMSS)
	}
	else {
		scalar IMSS = (`IMSS') 
	}
	capture confirm scalar ISSSTE
	if _rc == 0 {
		local ISSSTE = scalar(ISSSTE)
	}
	else {
		scalar ISSSTE = (`ISSSTE') 
	}

	// Productos, derechos, aprovechamientos, contribuciones
	capture confirm scalar OTROSK
	if _rc == 0 {
		local OTROSK = scalar(OTROSK)
	}
	else {
		scalar OTROSK  = (`OTROSK') 
	}

	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(55) in g "IMSS" ///
		_col(88) %7.3fc in y (`IMSS') ///
		_col(99) %7.3fc in y (`IMSS')/(`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')*100 " %"

	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(55) in g "ISSSTE" ///
		_col(88) %7.3fc in y (`ISSSTE') ///
		_col(99) %7.3fc in y (`ISSSTE')/(`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')*100 " %"

	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(55) in g "FMP" ///
		_col(88) %7.3fc in y (`FMP') ///
		_col(99) %7.3fc in y (`FMP')/(`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')*100 " %"

	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(55) in g "Pemex" ///
		_col(88) %7.3fc in y (`PEMEX') ///
		_col(99) %7.3fc in y (`PEMEX')/(`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')*100 " %"

	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(55) in g "CFE" ///
		_col(88) %7.3fc in y (`CFE') ///
		_col(99) %7.3fc in y (`CFE')/(`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')*100 " %"

	// TOTAL INGRESOS DE CAPITAL PUBLICOS
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos de capital (netos)" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "Ingresos propios totales" ///
		_col(88) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(99) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')/(CapIncImpPIB)*100 " %" "}"
	scalar ingcapitalPIB = (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')



	****************
	*** Base SIM ***
	/****************
	use `"`c(sysdir_site)'/users/$pais/$id/households.dta"', clear

	* ISR *
	tabstat Laboral Consumo OtrosC ISR__PM Petroleo CuotasSS [fw=factor], stat(sum) f(%20.0fc) save
	matrix INGRESOS = r(StatTotal)

	replace Laboral = Laboral*((scalar(ISRAS)+scalar(ISRPF))/100*`PIB')/INGRESOS[1,1]
	replace Consumo = Consumo*((scalar(IVA)+scalar(ISAN)+scalar(IEPS)+scalar(Importa))/100*`PIB')/INGRESOS[1,2]
	replace OtrosC = OtrosC*((scalar(ISRPM)+scalar(OYE)+scalar(OtrosC))/100*`PIB')/INGRESOS[1,3]

	replace ISR__PM = ISR__PM*((scalar(ISRPM))/100*`PIB')/INGRESOS[1,4]
	replace ISR__PM = 0 if ISR__PM == .

	replace Petroleo = Petroleo*((scalar(FMP))/100*`PIB')/INGRESOS[1,5]
	replace Petroleo = 0 if Petroleo == .

	replace CuotasSS = CuotasSS*((scalar(CuotasT))/100*`PIB')/INGRESOS[1,6]
	replace CuotasSS = 0 if CuotasSS == .

	tabstat Laboral Consumo OtrosC CuotasSS Petroleo [fw=factor], stat(sum) f(%20.0fc) save
	tempname INGRESOSSIM
	matrix `INGRESOSSIM' = r(StatTotal)
	


	** Guardar **
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace	
	}




	***************************
	*** 6 Estimaciones de LP ***
	****************************
	tempname RECBase
	local j = 1
	foreach k in Laboral Consumo OtrosC CuotasSS Petroleo {
		di "`k'"
		use `"`c(sysdir_site)'/users/$pais/bootstraps/1/`k'REC"', clear
		merge 1:1 (anio) using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
		tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
		matrix `RECBase' = r(StatTotal)

		replace estimacion = estimacion*`INGRESOSSIM'[1,`j']/`RECBase'[1,1]*`crecsim' if anio >= `anio'

		local ++j
		if `c(version)' > 13.1 {
			saveold `"`c(sysdir_site)'/users/$pais/$id/`k'REC.dta"', replace version(13)
		}
		else {
			save `"`c(sysdir_site)'/users/$pais/$id/`k'REC.dta"', replace		
		}
	}



	*************/
	*** OUTPUT ***
	**************
	if "$output" == "output" {
		quietly log on output
		noisily di in w "INGRESOSPIB: " in w "["  ///
			%8.3f ISRAS ", " ///
			%8.3f ISRPF ", " ///
			%8.3f CUOTAS ", " ///
			%8.3f ISRAS+ISRPF+CUOTAS ", " ///
			%8.3f ISRPM ", " ///
			%8.3f OTROSK ", " ///
			%8.3f ISRPM+OTROSK ", " ///
			%8.3f IVA ", " ///
			%8.3f ISAN ", " ///
			%8.3f IEPSNP ", " ///
			%8.3f IEPSP ", " ///
			%8.3f IMPORT ", " ///
			%8.3f IVA+ISAN+IEPSNP+IEPSP+IMPORT ", " ///
			%8.3f IMSS ", " ///
			%8.3f ISSSTE ", " ///
			%8.3f FMP ", " ///
			%8.3f PEMEX ", " ///
			%8.3f CFE ", " ///
			%8.3f IMSS+ISSSTE+FMP+PEMEX+CFE ", " ///
			%8.3f ISRAS+ISRPF+CUOTAS+ISRPM+OTROSK+IVA+ISAN+IEPSNP+IEPSP+IMPORT+IMSS+ISSSTE+FMP+PEMEX+CFE ///
		"]"
		noisily di in w "INGRESOSTEF: " in w "["  ///
			%8.3f ISRAS/RemSalPIB*100 ", " ///
			%8.3f ISRPF/MixLPIB*100 ", " ///
			%8.3f CUOTAS/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB)*100 ", " ///
			%8.3f (ISRAS+ISRPF+CUOTAS)/YlPIB*100 ", " ///
			%8.3f ISRPM/ExNOpSocPIB*100 ", " ///
			%8.3f OTROSK/ExNOpSocPIB*100 ", " ///
			%8.3f (ISRPM+OTROSK)/CapIncImpPIB*100 ", " ///
			%8.3f IVA/(ConHogPIB-AlimPIB-BebNPIB-SaluPIB)*100 ", " ///
			%8.3f ISAN/VehiPIB*100 ", " ///
			%8.3f IEPSNP/ConHogPIB*100 ", " ///
			%8.3f IEPSP/ConHogPIB*100 ", " ///
			%8.3f IMPORT/ConHogPIB*100 ", " ///
			%8.3f (IVA+ISAN+IEPSNP+IEPSP+IMPORT)/ConHogPIB*100 ", " ///
			%8.3f IMSS/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 ", " ///
			%8.3f ISSSTE/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 ", " ///
			%8.3f FMP/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 ", " ///
			%8.3f PEMEX/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 ", " ///
			%8.3f CFE/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 ", " ///
			%8.3f (IMSS+ISSSTE+FMP+PEMEX+CFE)/CapIncImpPIB*100 ///
		"]"
		quietly log off output
	}


	** DATOS ABIERTOS **
	if "$export" != "" & "$nographs" != "nograhs" & "$pais" == "" {
		DatosAbiertos XNA0120_s, g pibvp(`=ISRAS')   	//    ISR salarios
		DatosAbiertos XNA0120_f, g pibvp(`=ISRPF')    	//    ISR PF
		DatosAbiertos XNA0120_m, g pibvp(`=ISRPM')    	//    ISR PM
		DatosAbiertos XKF0114, g pibvp(`=CuotasT')      //    Cuotas IMSS
		DatosAbiertos XAB1120, g pibvp(`=IVA')      	//    IVA
		DatosAbiertos XNA0141, g pibvp(`=ISAN')      	//    ISAN
		DatosAbiertos XAB1130, g pibvp(`=IEPS')      	//    IEPS
		DatosAbiertos XNA0136, g pibvp(`=Importa')      //    Importaciones
		DatosAbiertos FMP_Derechos, g pibvp(`=FMP') 	//    FMP_Derechos
		DatosAbiertos XAB2110, g pibvp(`=`recPemex'')	//    Ingresos propios Pemex
		DatosAbiertos XOA0115, g pibvp(`=`recCFE'')		//    Ingresos propios CFE
		DatosAbiertos XKF0179, g pibvp(`=`recIMSS'')	//    Ingresos propios IMSS
		DatosAbiertos XOA0120, g pibvp(`=`recISSSTE'')	//    Ingresos propios ISSSTE
		DatosAbiertos OtrosIngresosC, g pibvp(`=OtrosC')	//    Ingresos propios ISSSTE
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
