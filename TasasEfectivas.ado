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



	*********************************
	*** 1 Cuentas macroeconómicas ***
	*********************************
	SCN, anio(`anio') nographs



	*********************
	*** 2 RECAUDACIÓN ***
	*********************
	LIF, anio(`anio') by(divSIM) nographs desde(2018)
	local recursos = r(divSIM)
	foreach k of local recursos {
		local `=substr("`k'",1,7)' = r(`k')
		local `=substr("`k'",1,7)' = ``=substr("`k'",1,7)''/scalar(PIB)*100
	}



	************************************
	** 3 Impuestos al ingreso laboral **
	************************************
	noisily di _newline(2) in y "{bf: A. " in y "Impuestos laborales" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Impuestos a las personas f{c i'}sicas" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"


	** 3.1 ISR (asalariados) **
	capture confirm scalar ISRAS
	if _rc == 0 {
		local ISRAS = scalar(ISRAS)
	}
	noisily di in g "  Compensaci{c o'}n de asalariados*" ///
		_col(44) %7.3fc in y RemSalPIB ///
		_col(55) in g "ISR (salarios)" ///
		_col(88) %7.3fc in y (`ISRAS') ///
		_col(99) %7.3fc in y (`ISRAS')/RemSalPIB*100 " %"
	scalar ISRASPor = (`ISRAS')/RemSalPIB*100


	** 3.2 ISR (personas físicas) **
	capture confirm scalar ISRPF
	if _rc == 0 {
		local ISRPF = scalar(ISRPF)
	}
	noisily di in g "  Ingreso mixto laboral" ///
		_col(44) %7.3fc in y MixLPIB ///
		_col(55) in g "ISR (f{c i'}sicas)" ///
		_col(88) %7.3fc in y (`ISRPF') ///
		_col(99) %7.3fc in y (`ISRPF')/MixLPIB*100 " %"
	scalar ISRPFPor = (`ISRPF')/MixLPIB*100


	** 3.3 Cuotas (IMSS) **
	capture confirm scalar CUOTAS
	if _rc == 0 {
		local CUOTAS = scalar(CUOTAS)
	}
	noisily di in g "  Compensaci{c o'}n de asalariados" ///
		_col(44) %7.3fc in y (RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB) ///
		_col(55) in g "Cuotas IMSS" ///
		_col(88) %7.3fc in y (`CUOTAS') ///
		_col(99) %7.3fc in y (`CUOTAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB)*100 " %"
	scalar CUOTASPor = (`CUOTAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB)*100


	** 3.4 TOTAL LABORALES **
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(44) %7.3fc in y (YlPIB) ///
		_col(55) in g "Recaudaci{c o'}n total" ///
		_col(88) %7.3fc in y (`ISRAS'+`ISRPF'+`CUOTAS') ///
		_col(99) %7.3fc in y (`ISRAS'+`ISRPF'+`CUOTAS')/(YlPIB)*100 " %" "}"
	scalar YlImpPIB = (`ISRAS'+`ISRPF'+`CUOTAS')
	scalar YlImpPor = (`ISRAS'+`ISRPF'+`CUOTAS')/(YlPIB)*100



	*****************************
	** 4 Organismos y empresas **
	*****************************
	noisily di _newline(2) in y "{bf: B. " in y "Organismos y empresas" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Organismos y empresas" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"


	** 4.1 FMP (energía) **
	capture confirm scalar FMP
	if _rc == 0 {
		local FMP = scalar(FMP)
	}
	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "FMP" ///
		_col(88) %7.3fc in y (`FMP') ///
		_col(99) %7.3fc in y (`FMP')/(CapIncImpPIB)*100 " %"
	scalar FMPPor = (`FMP')/(CapIncImpPIB)*100


	** 4.2 Pemex (energía) **
	capture confirm scalar PEMEX
	if _rc == 0 {
		local PEMEX = scalar(PEMEX)
	}
	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "Pemex" ///
		_col(88) %7.3fc in y (`PEMEX') ///
		_col(99) %7.3fc in y (`PEMEX')/(CapIncImpPIB)*100 " %"
	scalar PEMEXPor = (`PEMEX')/(CapIncImpPIB)*100


	** 4.3 CFE (energía) **
	capture confirm scalar CFE
	if _rc == 0 {
		local CFE = scalar(CFE)
	}
	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "CFE" ///
		_col(88) %7.3fc in y (`CFE') ///
		_col(99) %7.3fc in y (`CFE')/(CapIncImpPIB)*100 " %"
	scalar CFEPor = (`CFE')/(CapIncImpPIB)*100


	** 4.4 IMSS **
	capture confirm scalar IMSS
	if _rc == 0 {
		local IMSS = scalar(IMSS)
	}
	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "IMSS" ///
		_col(88) %7.3fc in y (`IMSS') ///
		_col(99) %7.3fc in y (`IMSS')/(CapIncImpPIB)*100 " %"
	scalar IMSSPor = (`IMSS')/(CapIncImpPIB)*100


	** 4.4 ISSSTE **
	capture confirm scalar ISSSTE
	if _rc == 0 {
		local ISSSTE = scalar(ISSSTE)
	}
	noisily di in g "  Ingresos de capital p{c u'}blico" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "ISSSTE" ///
		_col(88) %7.3fc in y (`ISSSTE') ///
		_col(99) %7.3fc in y (`ISSSTE')/(CapIncImpPIB)*100 " %"
	scalar ISSSTEPor = (`ISSSTE')/(CapIncImpPIB)*100


	** 4.5 TOTAL INGRESOS DE CAPITAL PUBLICOS **
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos de capital totales" ///
		_col(44) %7.3fc in y (CapIncImpPIB) ///
		_col(55) in g "Ingresos propios totales" ///
		_col(88) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(99) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')/(CapIncImpPIB)*100 " %" "}"
	scalar IngKPublicosPIB = `FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE'
	scalar IngKPublicosPor = (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')/(CapIncImpPIB)*100



	****************************
	** 5 Impuestos al capital **
	****************************
	noisily di _newline(2) in y "{bf: C. " in y "Impuestos al capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Impuestos a las personas morales" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"


	** 5.1 ISR (personas morales) **
	capture confirm scalar ISRPM
	if _rc == 0 {
		local ISRPM = scalar(ISRPM)
	}
	noisily di in g "  Ingresos de capital privado*" ///
		_col(44) %7.3fc in y (ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB) ///
		_col(55) in g "ISR (morales)" ///
		_col(88) %7.3fc in y (`ISRPM') ///
		_col(99) %7.3fc in y (`ISRPM')/(ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB)*100 " %"


	** 5.2 Productos, derechos, aprovechamientos, contribuciones **
	capture confirm scalar OTROSK
	if _rc == 0 {
		local OTROSK = scalar(OTROSK)
	}
	noisily di in g "  Ingresos de capital privado*" ///
		_col(44) %7.3fc in y (ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB) ///
		_col(55) in g "Productos, derechos, aprovech..." ///
		_col(88) %7.3fc in y (`OTROSK') ///
		_col(99) %7.3fc in y (`OTROSK')/(ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB)*100 " %"
	scalar IngKPrivadoPIB = ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB
	scalar ISRPMPor = (`ISRPM')/(ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB)*100
	scalar OTROSKPor = (`OTROSK')/(ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB)*100


	** 5.3 TOTAL CAPITAL PRIVADO **
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Ingresos de capital privados" ///
		_col(44) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB) ///
		_col(55) in g "Recaudaci{c o'}n total" ///
		_col(88) %7.3fc in y (`ISRPM'+`OTROSK') ///
		_col(99) %7.3fc in y (`ISRPM'+`OTROSK')/(CapIncImpPIB-IngKPublicosPIB)*100 " %" "}"
	scalar IngKPrivadoTotPIB = CapIncImpPIB-IngKPublicosPIB
	scalar IngKPrivadoTotPor = (`ISRPM'+`OTROSK')/(CapIncImpPIB-IngKPublicosPIB)*100
	scalar ImpKPrivadoPIB = `ISRPM'+`OTROSK'



	****************************
	** 6 Impuestos al consumo **
	****************************
	noisily di _newline(2) in y "{bf: D. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Impuestos al consumo" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"


	** 6.1 IVA **
	capture confirm scalar IVA
	if _rc == 0 {
		local IVA = scalar(IVA)
	}
	noisily di in g "  Consumo hogares e ISFLSH*" ///
		_col(44) %7.3fc in y (ConHogPIB - AlimPIB - BebNPIB - SaluPIB) ///
		_col(55) in g "IVA" ///
		_col(88) %7.3fc in y `IVA' ///
		_col(99) %7.3fc in y `IVA'/(ConHogPIB - AlimPIB - BebNPIB - SaluPIB)*100 " %"
	scalar ConHogNBPIB = ConHogPIB - AlimPIB - BebNPIB - SaluPIB
	scalar IVAPor = `IVA'/(ConHogPIB - AlimPIB - BebNPIB - SaluPIB)*100


	** 6.2 ISAN **
	capture confirm scalar ISAN
	if _rc == 0 {
		local ISAN = scalar(ISAN)
	}
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(44) %7.3fc in y VehiPIB ///
		_col(55) in g "ISAN" ///
		_col(88) %7.3fc in y `ISAN' ///
		_col(99) %7.3fc in y `ISAN'/VehiPIB*100 " %"
	scalar ISANPor = `ISAN'/VehiPIB*100

	** 6.3 IEPS (no petrolero) **
	capture confirm scalar IEPSNP
	if _rc == 0 {
		local IEPSNP = scalar(IEPSNP)
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "IEPS (no petrolero)" ///
		_col(88) %7.3fc in y `IEPSNP' ///
		_col(99) %7.3fc in y `IEPSNP'/ConHogPIB*100 " %"
	scalar IEPSNPPor = `IEPSNP'/ConHogPIB*100


	** 6.4 IEPS (petrolero) **
	capture confirm scalar IEPSP
	if _rc == 0 {
		local IEPSP = scalar(IEPSP)
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "IEPS (petrolero)" ///
		_col(88) %7.3fc in y `IEPSP' ///
		_col(99) %7.3fc in y `IEPSP'/ConHogPIB*100 " %"
	scalar IEPSPPor = `IEPSP'/ConHogPIB*100


	** 6.5 Importaciones **
	capture confirm scalar IMPORT
	if _rc == 0 {
		local IMPORT = scalar(IMPORT)
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "Importaciones" ///
		_col(88) %7.3fc in y `IMPORT' ///
		_col(99) %7.3fc in y `IMPORT'/ConHogPIB*100 " %"
	scalar IMPORTPor = `IMPORT'/ConHogPIB*100


	** 6.6 TOTAL CONSUMO **
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y ConHogPIB ///
		_col(55) in g "Recaudaci{c o'}n total" ///
		_col(88) %7.3fc in y (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT') ///
		_col(99) %7.3fc in y (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')/ConHogPIB*100 " %" "}"
	scalar ingconsumoPIB = (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')
	scalar ingconsumoPor = (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')/ConHogPIB*100



	**********************
	** 7 DATOS ABIERTOS **
	**********************
	if "$nographs" == "" & "`nographs'" != "nographs" & `anio' == `aniovp' {
		DatosAbiertos XNA0120_s, pibvp(`ISRAS')		//    ISR salarios
		DatosAbiertos XNA0120_f, pibvp(`ISRPF')		//    ISR PF
		DatosAbiertos XNA0120_m, pibvp(`ISRPM')		//    ISR PM
		DatosAbiertos XKF0114, pibvp(`CUOTAS')		//    Cuotas IMSS
		DatosAbiertos XAB1120, pibvp(`IVA')		//    IVA
		DatosAbiertos XNA0141, pibvp(`ISAN')		//    ISAN
		DatosAbiertos XAB2122, pibvp(`IEPSP')		//    IEPS petrolero
		DatosAbiertos XAB2213, pibvp(`IEPSNP')		//    IEPS no petrolero
		DatosAbiertos XNA0136, pibvp(`IMPORT')		//    Importaciones
		DatosAbiertos FMP_Derechos, pibvp(`FMP')	//    FMP_Derechos
		DatosAbiertos XAB2110, pibvp(`PEMEX')		//    Ingresos propios Pemex
		DatosAbiertos XOA0115, pibvp(`CFE')		//    Ingresos propios CFE
		DatosAbiertos XKF0179, pibvp(`IMSS')		//    Ingresos propios IMSS
		DatosAbiertos XOA0120, pibvp(`ISSSTE')		//    Ingresos propios ISSSTE
		DatosAbiertos OtrosIngresosC, pibvp(`OTROSK')	//    Ingresos propios ISSSTE
	}


	****************
	*** Base SIM ***
	****************
	capture use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
	if _rc != 0 {
		use "`c(sysdir_personal)'/SIM/households`=aniovp'.dta", clear
	}

	* Distribuir los ingresos entre las observaciones *
	foreach k of varlist ISRAS ISRPF CUOTAS ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT FMP {
		tempvar `k'
		g ``k'' = `k'
		drop `k'
		Distribucion `k', relativo(``k'') macro(`=scalar(`k')/100*scalar(pibY)')
	}

	** Guardar **
	capture drop __*
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace	
	}





	***************************/
	*** 6 Estimaciones de LP ***
	/****************************
	*tabstat Laboral Consumo OtrosC CuotasSS Petroleo [fw=factor], stat(sum) f(%20.0fc) save
	*tempname INGRESOSSIM
	*matrix `INGRESOSSIM' = r(StatTotal)
	tempname RECBase
	local j = 1
	foreach k in Laboral Consumo OtrosC CuotasSS Petroleo {
		di "`k'"
		use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
		merge 1:1 (anio) using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
		tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
		matrix `RECBase' = r(StatTotal)

		replace estimacion = estimacion*`INGRESOSSIM'[1,`j']/`RECBase'[1,1]*`crecsim' if anio >= `anio'

		local ++j
		if `c(version)' > 13.1 {
			saveold `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace version(13)
		}
		else {
			save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace		
		}
	}







	**********/
	*** END ***
	***********
	timer off 8
	timer list 8
	noisily di _newline in g "Tiempo: " in y round(`=r(t8)/r(nt8)',.1) in g " segs."
}
end
