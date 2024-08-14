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
	noisily di _newline(2) in g _dup(20) "." "{bf:   Fiscalización INGRESOS " in y `anio' "   }" in g _dup(20) "."





	*********************************
	**# 1 Cuentas macroeconómicas ***
	*********************************
	SCN, anio(`anio') nographs





	*********************
	**# 2 RECAUDACIÓN ***
	*********************
	LIF, anio(`anio') by(divSIM) nographs desde(2018) min(0)
	local recursos = r(divSIM)
	foreach k of local recursos {
		local `=substr("`k'",1,7)' = r(`k')
		local `=substr("`k'",1,7)' = ``=substr("`k'",1,7)''/scalar(PIB)*100
	}
	scalar IngKPublicosPIB = `FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE'
	scalar IngKPublicosPor = (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')/(CapIncImpPIB)*100





	**************************************
	**# 3 Impuestos al ingreso laboral ***
	**************************************
	noisily di _newline(2) in y "{bf: A. " in y "Impuestos al trabajo}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "Al trabajo" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"


	** 3.1 ISR (asalariados) **
	capture confirm scalar ISRAS
	if _rc == 0 {
		local ISRAS = scalar(ISRAS)
	}
	else {
		scalar ISRAS = `ISRAS'
	}
	
	noisily di in g "  Rem. de asalariados" ///
		_col(30) %7.3fc in y RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB ///
		_col(40) in g "ISR (salarios)" ///
		_col(55) %7.3fc in y (`ISRAS') ///
		_col(63) %7.3fc in y (`ISRAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100 " %"
	scalar ISRASPor = (`ISRAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100


	** 3.2 ISR (personas físicas) **
	capture confirm scalar ISRPF
	if _rc == 0 {
		local ISRPF = scalar(ISRPF)
	}
	else {
		scalar ISRPF = `ISRPF'
	}
	noisily di in g "  Ingreso mixto laboral" ///
		_col(30) %7.3fc in y MixLPIB ///
		_col(40) in g "ISR (f{c i'}sicas)" ///
		_col(55) %7.3fc in y (`ISRPF') ///
		_col(63) %7.3fc in y (`ISRPF')/MixLPIB*100 " %"
	scalar ISRPFPor = (`ISRPF')/MixLPIB*100


	** 3.3 Cuotas (IMSS) **
	capture confirm scalar CUOTAS
	if _rc == 0 {
		local CUOTAS = scalar(CUOTAS)
	}
	else {
		scalar CUOTAS = `CUOTAS'
	}
	noisily di in g "  Rem. de asalariados" ///
		_col(30) %7.3fc in y (RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB) ///
		_col(40) in g "Cuotas IMSS" ///
		_col(55) %7.3fc in y (`CUOTAS') ///
		_col(63) %7.3fc in y (`CUOTAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100 " %"
	scalar CUOTASPor = (`CUOTAS')/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100


	** 3.4 TOTAL LABORALES **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(30) %7.3fc in y (YlPIB) ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (`ISRAS'+`ISRPF'+`CUOTAS') ///
		_col(63) %7.3fc in y (`ISRAS'+`ISRPF'+`CUOTAS')/(YlPIB)*100 " %" "}"
	scalar YlImpPIB = (`ISRAS'+`ISRPF'+`CUOTAS')
	scalar YlImpPor = (`ISRAS'+`ISRPF'+`CUOTAS')/(YlPIB)*100





	******************************
	**# 4 Impuestos al capital ***
	******************************
	noisily di _newline(2) in y "{bf: B. " in y "Impuestos al capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "Al capital" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"


	** 4.1 ISR (personas morales) **
	capture confirm scalar ISRPM
	if _rc == 0 {
		local ISRPM = scalar(ISRPM)
	}
	else {
		scalar ISRPM = `ISRPM'
	}
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB) ///
		_col(40) in g "ISR (morales)" ///
		_col(55) %7.3fc in y (`ISRPM') ///
		_col(63) %7.3fc in y (`ISRPM')/(CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB)*100 " %"


	** 4.2 Productos, derechos, aprovechamientos, contribuciones **
	capture confirm scalar OTROSK
	if _rc == 0 {
		local OTROSK = scalar(OTROSK)
	}
	else {
		scalar OTROSK = `OTROSK'
	}
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB) ///
		_col(40) in g "Otros ingresos" ///
		_col(55) %7.3fc in y (`OTROSK') ///
		_col(63) %7.3fc in y (`OTROSK')/(CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB)*100 " %"
	scalar IngKPrivadoPIB = CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB
	scalar ISRPMPor = (`ISRPM')/(CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB)*100
	scalar OTROSKPor = (`OTROSK')/(CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB)*100


	** 4.3 TOTAL CAPITAL PRIVADO **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB) ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (`ISRPM'+`OTROSK') ///
		_col(63) %7.3fc in y (`ISRPM'+`OTROSK')/(CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB)*100 " %" "}"
	scalar IngKPrivadoTotPIB = CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB
	scalar IngKPrivadoTotPor = (`ISRPM'+`OTROSK')/(CapIncImpPIB-IngKPublicosPIB-ExNOpHogPIB)*100
	scalar ImpKPrivadoPIB = `ISRPM'+`OTROSK'





	*******************************
	**# 5 Organismos y empresas ***
	*******************************
	noisily di _newline(2) in y "{bf: C. " in y "Organismos y empresas" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "OyE públicas" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"


	** 5.1 FMP (energía) **
	capture confirm scalar FMP
	if _rc == 0 {
		local FMP = scalar(FMP)
	}
	else {
		scalar FMP = `FMP'
	}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "FMP" ///
		_col(55) %7.3fc in y (`FMP') ///
		_col(63) %7.3fc in y (`FMP')/(CapIncImpPIB)*100 " %"
	scalar FMPPor = (`FMP')/(CapIncImpPIB)*100


	** 5.2 Pemex (energía) **
	capture confirm scalar PEMEX
	if _rc == 0 {
		local PEMEX = scalar(PEMEX)
	}
	else {
		scalar PEMEX = `PEMEX'
	}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "Pemex" ///
		_col(55) %7.3fc in y (`PEMEX') ///
		_col(63) %7.3fc in y (`PEMEX')/(CapIncImpPIB)*100 " %"
	scalar PEMEXPor = (`PEMEX')/(CapIncImpPIB)*100


	** 5.3 CFE (energía) **
	capture confirm scalar CFE
	if _rc == 0 {
		local CFE = scalar(CFE)
	}
	else {
		scalar CFE = `CFE'
	}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "CFE" ///
		_col(55) %7.3fc in y (`CFE') ///
		_col(63) %7.3fc in y (`CFE')/(CapIncImpPIB)*100 " %"
	scalar CFEPor = (`CFE')/(CapIncImpPIB)*100


	** 5.4 IMSS **
	capture confirm scalar IMSS
	if _rc == 0 {
		local IMSS = scalar(IMSS)
	}
	else {
		scalar IMSS = `IMSS'
	}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "IMSS" ///
		_col(55) %7.3fc in y (`IMSS') ///
		_col(63) %7.3fc in y (`IMSS')/(CapIncImpPIB)*100 " %"
	scalar IMSSPor = (`IMSS')/(CapIncImpPIB)*100


	** 5.4 ISSSTE **
	capture confirm scalar ISSSTE
	if _rc == 0 {
		local ISSSTE = scalar(ISSSTE)
	}
	else {
		scalar ISSSTE = `ISSSTE'
	}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "ISSSTE" ///
		_col(55) %7.3fc in y (`ISSSTE') ///
		_col(63) %7.3fc in y (`ISSSTE')/(CapIncImpPIB)*100 " %"
	scalar ISSSTEPor = (`ISSSTE')/(CapIncImpPIB)*100


	** 5.5 TOTAL INGRESOS DE CAPITAL PUBLICOS **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE') ///
		_col(63) %7.3fc in y (`FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE')/(CapIncImpPIB)*100 " %" "}"





	******************************
	**# 6 Impuestos al consumo ***
	******************************
	noisily di _newline(2) in y "{bf: D. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "Al consumo" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"


	** 6.1 IVA **
	capture confirm scalar IVA
	if _rc == 0 {
		local IVA = scalar(IVA)
	}
	else {
		scalar IVA = `IVA'
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y (ConHogPIB) ///
		_col(40) in g "IVA" ///
		_col(55) %7.3fc in y `IVA' ///
		_col(63) %7.3fc in y `IVA'/(ConHogPIB)*100 " %"
	scalar IVAPor = `IVA'/(ConHogPIB)*100


	** 6.2 ISAN **
	capture confirm scalar ISAN
	if _rc == 0 {
		local ISAN = scalar(ISAN)
	}
	else {
		scalar ISAN = `ISAN'
	}
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(30) %7.3fc in y VehiPIB ///
		_col(40) in g "ISAN" ///
		_col(55) %7.3fc in y `ISAN' ///
		_col(63) %7.3fc in y `ISAN'/VehiPIB*100 " %"
	scalar ISANPor = `ISAN'/VehiPIB*100


	** 6.3 IEPS (no petrolero) **
	capture confirm scalar IEPSNP
	if _rc == 0 {
		local IEPSNP = scalar(IEPSNP)
	}
	else {
		scalar IEPSNP = `IEPSNP'
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y ConHogPIB ///
		_col(40) in g "IEPS (No petr.)" ///
		_col(55) %7.3fc in y `IEPSNP' ///
		_col(63) %7.3fc in y `IEPSNP'/ConHogPIB*100 " %"
	scalar IEPSNPPor = `IEPSNP'/ConHogPIB*100


	** 6.4 IEPS (petrolero) **
	capture confirm scalar IEPSP
	if _rc == 0 {
		local IEPSP = scalar(IEPSP)
	}
	else {
		scalar IEPSP = `IEPSP'
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y ConHogPIB ///
		_col(40) in g "IEPS (Petr.)" ///
		_col(55) %7.3fc in y `IEPSP' ///
		_col(63) %7.3fc in y `IEPSP'/ConHogPIB*100 " %"
	scalar IEPSPPor = `IEPSP'/ConHogPIB*100


	** 6.5 Importaciones **
	capture confirm scalar IMPORT
	if _rc == 0 {
		local IMPORT = scalar(IMPORT)
	}
	else {
		scalar IMPORT = `IMPORT'
	}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y ConHogPIB ///
		_col(40) in g "Importaciones" ///
		_col(55) %7.3fc in y `IMPORT' ///
		_col(63) %7.3fc in y `IMPORT'/ConHogPIB*100 " %"
	scalar IMPORTPor = `IMPORT'/ConHogPIB*100


	** 6.6 TOTAL CONSUMO **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y ConHogPIB ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT') ///
		_col(63) %7.3fc in y (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')/ConHogPIB*100 " %" "}"
	scalar ingconsumoPIB = (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')
	scalar ingconsumoPor = (`IEPSP'+`IEPSNP'+`IVA'+`ISAN'+`IMPORT')/ConHogPIB*100





	******************/
	**# 7. Base SIM ***
	*******************
	use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
		ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
		using "`c(sysdir_personal)'/SIM/perfiles`anio'.dta", clear 

	* 7.1 Distribuir los ingresos entre las observaciones *
	foreach k of varlist ISRAS ISRPF CUOTAS ///
		ISRPM OTROSK ///
		FMP PEMEX CFE IMSS ISSSTE ///
		IVA IEPSNP IEPSP ISAN IMPORT {
		Distribucion `k', relativo(`k') macro(`=scalar(`k')/100*scalar(pibY)')
	}

	* 7.2 Guardar *
	capture drop __*
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_personal)'/users/$id/ingresos.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/users/$id/ingresos.dta"', replace	
	}





	**********/
	*** END ***
	***********
	timer off 8
	timer list 8
	noisily di _newline in g "Tiempo: " in y round(`=r(t8)/r(nt8)',.1) in g " segs."
}
end
