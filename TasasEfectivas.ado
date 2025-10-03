program define TasasEfectivas, return
quietly {

	timer on 8
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	syntax [, ANIO(int `aniovp') NOGraphs CRECSIM(real 1) EOFP ENIGH]
	noisily di _newline(2) in g _dup(20) "." "{bf:   Fiscalización INGRESOS " in y `anio' "   }" in g _dup(20) "."



	*********************************
	**# 1 Cuentas macroeconómicas ***
	*********************************
	SCN, anio(`anio') nographs
	


	*********************
	**# 2 RECAUDACIÓN ***
	*********************
	if "`enigh'" == "" {
		LIF, anio(`anio') by(divSIM) nographs min(0) desde(`=`anio'-1') `eofp'
	}



	*************************************/
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
	*capture confirm scalar ISRAS
	*if _rc == 0 {
	*	local ISRAS = scalar(ISRAS)
	*}
	*else {
	*	scalar ISRAS = ISRASPIB
	*}
	scalar RemSalPIB = real(RemSalPIB)
	scalar SSImputadaPIB = real(SSImputadaPIB)
	scalar SSEmpleadoresPIB = real(SSEmpleadoresPIB)
	scalar ImpNetProduccionLPIB = real(ImpNetProduccionLPIB)

	noisily di in g "  Rem. de asalariados" ///
		_col(30) %7.3fc in y RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB ///
		_col(40) in g "ISR (salarios)" ///
		_col(55) %7.3fc in y (ISRASPIB) ///
		_col(63) %7.3fc in y (ISRASPIB)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100 " %"
	scalar ISRASPor = (ISRASPIB)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100

	** 3.2 ISR (personas físicas) **
	*capture confirm scalar ISRPF
	*if _rc == 0 {
	*	local ISRPF = scalar(ISRPF)
	*}
	*else {
	*	scalar ISRPF = ISRPFPIB
	*}
	scalar MixLPIB = real(MixLPIB)

	noisily di in g "  Ingreso mixto laboral" ///
		_col(30) %7.3fc in y MixLPIB ///
		_col(40) in g "ISR (f{c i'}sicas)" ///
		_col(55) %7.3fc in y (ISRPFPIB) ///
		_col(63) %7.3fc in y (ISRPFPIB)/MixLPIB*100 " %"
	scalar ISRPFPor = (ISRPFPIB)/MixLPIB*100

	** 3.3 Cuotas (IMSS) **
	*capture confirm scalar CUOTAS
	*if _rc == 0 {
	*	local CUOTAS = scalar(CUOTAS)
	*}
	*else {
	*	scalar CUOTAS = CUOTASPIB
	*}
	noisily di in g "  Rem. de asalariados" ///
		_col(30) %7.3fc in y (RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB) ///
		_col(40) in g "Cuotas IMSS" ///
		_col(55) %7.3fc in y (CUOTASPIB) ///
		_col(63) %7.3fc in y (CUOTASPIB)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100 " %"
	scalar CUOTASPor = (CUOTASPIB)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100

	** 3.4 TOTAL LABORALES **
	scalar YlPIB = real(YlPIB)
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(30) %7.3fc in y (YlPIB) ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (ISRASPIB+ISRPFPIB+CUOTASPIB) ///
		_col(63) %7.3fc in y (ISRASPIB+ISRPFPIB+CUOTASPIB)/(YlPIB)*100 " %" "}"
	scalar YlImpPIB = (ISRASPIB+ISRPFPIB+CUOTASPIB)
	scalar YlImpPor = (ISRASPIB+ISRPFPIB+CUOTASPIB)/(YlPIB)*100



	******************************
	**# 4 Impuestos al capital ***
	******************************
	scalar CapIncImpPIB = real(CapIncImpPIB)
	scalar IngKPublicosPIB = PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB
	scalar IngKPublicosPor = (PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB)/(CapIncImpPIB)*100

	noisily di _newline(2) in y "{bf: B. " in y "Impuestos al capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "Al capital" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"

	** 4.1 ISR (personas morales) **
	*capture confirm scalar ISRPM
	*if _rc == 0 {
	*	local ISRPM = scalar(ISRPM)
	*}
	*else {
	*	scalar ISRPM = ISRPMPIB
	*}
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB) ///
		_col(40) in g "ISR (morales)" ///
		_col(55) %7.3fc in y (ISRPMPIB) ///
		_col(63) %7.3fc in y (ISRPMPIB)/(CapIncImpPIB-IngKPublicosPIB)*100 " %"

	** 4.2 Productos, derechos, aprovechamientos, contribuciones **
	*capture confirm scalar OTROSK
	*if _rc == 0 {
	*	local OTROSK = scalar(OTROSK)
	*}
	*else {
	*	scalar OTROSK = OTROSKPIB
	*}
	scalar IngKPrivadoPIB = CapIncImpPIB-IngKPublicosPIB

	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB) ///
		_col(40) in g "Otros ingresos" ///
		_col(55) %7.3fc in y (OTROSKPIB) ///
		_col(63) %7.3fc in y (OTROSKPIB)/(CapIncImpPIB-IngKPublicosPIB)*100 " %"
	scalar IngKPrivadoPIB = CapIncImpPIB-IngKPublicosPIB
	scalar ISRPMPor = (ISRPMPIB)/(CapIncImpPIB-IngKPublicosPIB)*100
	scalar OTROSKPor = (OTROSKPIB)/(CapIncImpPIB-IngKPublicosPIB)*100

	** 5.1 FMP (energía) **
	*capture confirm scalar FMP
	*if _rc == 0 {
	*	local FMP = scalar(FMP)
	*}
	*else {
	*	scalar FMP = FMPPIB
	*}
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB) ///
		_col(40) in g "FMP" ///
		_col(55) %7.3fc in y (FMPPIB) ///
		_col(63) %7.3fc in y (FMPPIB)/(CapIncImpPIB-IngKPublicosPIB)*100 " %"
	scalar FMPPor = (FMPPIB)/(CapIncImpPIB-IngKPublicosPIB)*100

	** 4.3 TOTAL CAPITAL PRIVADO **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ing. de capital privado" ///
		_col(30) %7.3fc in y (CapIncImpPIB-IngKPublicosPIB) ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (ISRPMPIB+OTROSKPIB+FMPPIB) ///
		_col(63) %7.3fc in y (ISRPMPIB+OTROSKPIB+FMPPIB)/(CapIncImpPIB-IngKPublicosPIB)*100 " %" "}"
	scalar IngKPrivadoTotPIB = CapIncImpPIB-IngKPublicosPIB
	scalar IngKPrivadoTotPor = (ISRPMPIB+OTROSKPIB+FMPPIB)/(CapIncImpPIB-IngKPublicosPIB)*100
	scalar ImpKPrivadoPIB = ISRPMPIB+OTROSKPIB+FMPPIB



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

	** 5.2 Pemex (energía) **
	*capture confirm scalar PEMEX
	*if _rc == 0 {
	*	local PEMEX = scalar(PEMEX)
	*}
	*else {
	*	scalar PEMEX = PEMEXPIB
	*}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "Pemex" ///
		_col(55) %7.3fc in y (PEMEXPIB) ///
		_col(63) %7.3fc in y (PEMEXPIB)/(CapIncImpPIB)*100 " %"
	scalar PEMEXPor = (PEMEXPIB)/(CapIncImpPIB)*100

	** 5.3 CFE (energía) **
	*capture confirm scalar CFE
	*if _rc == 0 {
	*	local CFE = scalar(CFE)
	*}
	*else {
	*	scalar CFE = CFEPIB
	*}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "CFE" ///
		_col(55) %7.3fc in y (CFEPIB) ///
		_col(63) %7.3fc in y (CFEPIB)/(CapIncImpPIB)*100 " %"
	scalar CFEPor = (CFEPIB)/(CapIncImpPIB)*100

	** 5.4 IMSS **
	*capture confirm scalar IMSS
	*if _rc == 0 {
	*	local IMSS = scalar(IMSS)
	*}
	*else {
	*	scalar IMSS = IMSSPIB
	*}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "IMSS" ///
		_col(55) %7.3fc in y (IMSSPIB) ///
		_col(63) %7.3fc in y (IMSSPIB)/(CapIncImpPIB)*100 " %"
	scalar IMSSPor = (IMSSPIB)/(CapIncImpPIB)*100

	** 5.4 ISSSTE **
	*capture confirm scalar ISSSTE
	*if _rc == 0 {
	*	local ISSSTE = scalar(ISSSTE)
	*}
	*else {
	*	scalar ISSSTE = ISSSTEPIB
	*}
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "ISSSTE" ///
		_col(55) %7.3fc in y (ISSSTEPIB) ///
		_col(63) %7.3fc in y (ISSSTEPIB)/(CapIncImpPIB)*100 " %"
	scalar ISSSTEPor = (ISSSTEPIB)/(CapIncImpPIB)*100

	** 5.5 TOTAL INGRESOS DE CAPITAL PUBLICOS **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ingresos de capital" ///
		_col(30) %7.3fc in y (CapIncImpPIB) ///
		_col(40) in g "Ing. propios" ///
		_col(55) %7.3fc in y (FMPPIB+PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB) ///
		_col(63) %7.3fc in y (FMPPIB+PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB)/(CapIncImpPIB)*100 " %" "}"
	scalar IngKPublicosTotPIB = (FMPPIB+PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB)
	scalar IngKPublicosTotPor = (FMPPIB+PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB)/(CapIncImpPIB)*100
	scalar ImpKPublicosPIB = FMPPIB+PEMEXPIB+CFEPIB+IMSSPIB+ISSSTEPIB



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
	*capture confirm scalar IVA
	*if _rc == 0 {
	*	local IVA = scalar(IVA)
	*}
	*else {
	*	scalar IVA = IVAPIB
	*}
	scalar ConHogPIB = real(ConHogPIB)
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y (ConHogPIB) ///
		_col(40) in g "IVA" ///
		_col(55) %7.3fc in y IVAPIB ///
		_col(63) %7.3fc in y IVAPIB/(ConHogPIB)*100 " %"
	scalar IVAPor = IVAPIB/(ConHogPIB)*100

	** 6.2 ISAN **
	*capture confirm scalar ISAN
	*if _rc == 0 {
	*	local ISAN = scalar(ISAN)
	*}
	*else {
	*	scalar ISAN = ISANPIB
	*}
	scalar VehiPIB = real(VehiPIB)
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(30) %7.3fc in y VehiPIB ///
		_col(40) in g "ISAN" ///
		_col(55) %7.3fc in y ISANPIB ///
		_col(63) %7.3fc in y ISANPIB/VehiPIB*100 " %"
	scalar ISANPor = ISANPIB/VehiPIB*100

	** 6.3 IEPS (no petrolero) **
	*capture confirm scalar IEPSNP
	*if _rc == 0 {
	*	local IEPSNP = scalar(IEPSNP)
	*}
	*else {
	*	scalar IEPSNP = IEPSNPPIB
	*}
	scalar BebAPIB = real(BebAPIB)
	scalar TabaPIB = real(TabaPIB)
	scalar Recre7132PIB = real(Recre7132PIB)
	noisily di in g "  Alcohol, tabaco y juegos" ///
		_col(30) %7.3fc in y (BebAPIB+TabaPIB+Recre7132PIB) ///
		_col(40) in g "IEPS (No petr.)" ///
		_col(55) %7.3fc in y IEPSNPPIB ///
		_col(63) %7.3fc in y IEPSNPPIB/(BebAPIB+TabaPIB+Recre7132PIB)*100 " %"
	scalar IEPSNPPor = IEPSNPPIB/(BebAPIB+TabaPIB+Recre7132PIB)*100

	** 6.4 IEPS (petrolero) **
	*capture confirm scalar IEPSP
	*if _rc == 0 {
	*	local IEPSP = scalar(IEPSP)
	*}
	*else {
	*	scalar IEPSP = IEPSPPIB
	*}
	scalar ConsPriv21PIB = real(ConsPriv21PIB)
	noisily di in g "  Consumo privado minería" ///
		_col(30) %7.3fc in y ConsPriv21PIB ///
		_col(40) in g "IEPS (Petr.)" ///
		_col(55) %7.3fc in y IEPSPPIB ///
		_col(63) %7.3fc in y IEPSPPIB/ConsPriv21PIB*100 " %"
	scalar IEPSPPor = IEPSPPIB/ConsPriv21PIB*100

	** 6.5 Importaciones **
	*capture confirm scalar IMPORT
	*if _rc == 0 {
	*	local IMPORT = scalar(IMPORT)
	*}
	*else {
	*	scalar IMPORT = IMPORTPIB
	*}
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y ConHogPIB ///
		_col(40) in g "Importaciones" ///
		_col(55) %7.3fc in y IMPORTPIB ///
		_col(63) %7.3fc in y IMPORTPIB/ConHogPIB*100 " %"
	scalar IMPORTPor = IMPORTPIB/ConHogPIB*100

	** 6.6 TOTAL CONSUMO **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y ConHogPIB ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y (IEPSPPIB+IEPSNPPIB+IVAPIB+ISANPIB+IMPORTPIB) ///
		_col(63) %7.3fc in y (IEPSPPIB+IEPSNPPIB+IVAPIB+ISANPIB+IMPORTPIB)/ConHogPIB*100 " %" "}"
	scalar ingconsumoPIB = (IEPSPPIB+IEPSNPPIB+IVAPIB+ISANPIB+IMPORTPIB)
	scalar ingconsumoPor = (IEPSPPIB+IEPSNPPIB+IVAPIB+ISANPIB+IMPORTPIB)/ConHogPIB*100



	******************/
	**# 7. Base SIM ***
	*******************
	if "`enigh'" == "enigh" {
		capture use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
			ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
			using "`c(sysdir_site)'/04_master/perfiles`anio'.dta", clear 
		if _rc != 0 {
			noisily run "`c(sysdir_site)'/PerfilesSim.do" `anio'
			use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
				ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
				using "`c(sysdir_site)'/04_master/perfiles`anio'.dta", clear
		}

		* 7.1 Distribuir los ingresos entre las observaciones *
		scalar pibY = real(subinstr(scalar(pibY),",","",.))*1000000
		foreach k of varlist ISRAS ISRPF CUOTAS ///
			ISRPM OTROSK ///
			FMP PEMEX CFE IMSS ISSSTE ///
			IVA IEPSNP IEPSP ISAN IMPORT {

			Distribucion `k'_Sim, relativo(`k') macro(`=scalar(`k'PIB)/100*scalar(pibY)')
		}

		* 7.2 Guardar *
		capture drop __*
		save `"`c(sysdir_site)'/users/$id/ingresos.dta"', replace
	}



	**********/
	*** END ***
	***********
	timer off 8
	timer list 8
	noisily di _newline in g "Tiempo: " in y round(`=r(t8)/r(nt8)',.1) in g " segs."
}
end
