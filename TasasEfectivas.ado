*! version 8.0 CIEP 03jul2026
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
	/*********************
	if "`enigh'" == "" {
		noisily LIF, anio(`=anioPE') by(divSIM) $update $nographs `eofp'		///
			title("Ingresos presupuestarios") 					/// Cambiar título de la gráfica
			desde(2013) 								/// Año de inicio para el PROMEDIO
			rows(2)									//  Número de filas en la leyenda
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
	local RemSalPIB = scalar(RemSalPIB)
	local ISRASPIB = scalar(ISRASPIB)
	local RemSalSSPIB = scalar(RemSalPIB)+scalar(SSImputadaPIB)+scalar(SSEmpleadoresPIB)+scalar(ImpNetProduccionLPIB)

	noisily di in g "  Rem. de asalariados" ///
		_col(30) %7.3fc in y `RemSalSSPIB' ///
		_col(40) in g "ISR (salarios)" ///
		_col(55) %7.3fc in y `ISRASPIB' ///
		_col(63) %7.3fc in y `ISRASPIB'/`RemSalSSPIB'*100 " %"
	escalar pct ISRASTE = `ISRASPIB'/`RemSalSSPIB'*100

	** 3.2 ISR (personas físicas) **
	local MixLPIB = scalar(MixLPIB)
	local ISRPFPIB = scalar(ISRPFPIB)

	noisily di in g "  Ingreso mixto laboral" ///
		_col(30) %7.3fc in y `MixLPIB' ///
		_col(40) in g "ISR (f{c i'}sicas)" ///
		_col(55) %7.3fc in y `ISRPFPIB' ///
		_col(63) %7.3fc in y `ISRPFPIB'/`MixLPIB'*100 " %"
	escalar pct ISRPFTE = `ISRPFPIB'/`MixLPIB'*100

	** 3.3 Cuotas (IMSS) **
	local CUOTASPIB = scalar(CUOTASPIB)

	noisily di in g "  Rem. de asalariados" ///
		_col(30) %7.3fc in y `RemSalSSPIB' ///
		_col(40) in g "Cuotas IMSS" ///
		_col(55) %7.3fc in y `CUOTASPIB' ///
		_col(63) %7.3fc in y `CUOTASPIB'/`RemSalSSPIB'*100 " %"
	escalar pct CUOTASTE = `CUOTASPIB'/`RemSalSSPIB'*100

	** 3.4 TOTAL LABORALES **
	local YlPIB = scalar(YlPIB)
	local YlImpPIB = `ISRASPIB'+`ISRPFPIB'+`CUOTASPIB'

	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ingresos laborales" ///
		_col(30) %7.3fc in y `YlPIB' ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y `YlImpPIB' ///
		_col(63) %7.3fc in y `YlImpPIB'/`YlPIB'*100 " %" "}"
	escalar pctpib YlImpPIB = `YlImpPIB'
	escalar pct YlImpTE = `YlImpPIB'/`YlPIB'*100



	******************************
	**# 4 Impuestos al capital ***
	******************************
	* Convertir scalars de string a real
	local CapIncImpPIB = scalar(CapIncImpPIB)
	local PEMEXPIB = scalar(PEMEXPIB)
	local CFEPIB = scalar(CFEPIB)
	local IMSSPIB = scalar(IMSSPIB)
	local ISSSTEPIB = scalar(ISSSTEPIB)
	local ISRPMPIB = scalar(ISRPMPIB)
	local OTROSKPIB = scalar(OTROSKPIB)
	local FMPPIB = scalar(FMPPIB)

	local IngKPublicosPIB = `PEMEXPIB'+`CFEPIB'+`IMSSPIB'+`ISSSTEPIB'
	local IngKPrivadoPIB = `CapIncImpPIB'-`IngKPublicosPIB'

	noisily di _newline(2) in y "{bf: B. " in y "Impuestos al capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "Al capital" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"

	** 4.1 ISR (personas morales) **
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y `IngKPrivadoPIB' ///
		_col(40) in g "ISR (morales)" ///
		_col(55) %7.3fc in y `ISRPMPIB' ///
		_col(63) %7.3fc in y `ISRPMPIB'/`IngKPrivadoPIB'*100 " %"

	** 4.2 Productos, derechos, aprovechamientos, contribuciones **
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y `IngKPrivadoPIB' ///
		_col(40) in g "Otros ingresos" ///
		_col(55) %7.3fc in y `OTROSKPIB' ///
		_col(63) %7.3fc in y `OTROSKPIB'/`IngKPrivadoPIB'*100 " %"
	escalar pct ISRPMTE = `ISRPMPIB'/`IngKPrivadoPIB'*100
	escalar pct OTROSKTE = `OTROSKPIB'/`IngKPrivadoPIB'*100

	** 4.3 FMP (energía) **
	noisily di in g "  Ing. de capital privado" ///
		_col(30) %7.3fc in y `IngKPrivadoPIB' ///
		_col(40) in g "FMP" ///
		_col(55) %7.3fc in y `FMPPIB' ///
		_col(63) %7.3fc in y `FMPPIB'/`IngKPrivadoPIB'*100 " %"
	escalar pct FMPTE = `FMPPIB'/`IngKPrivadoPIB'*100

	** 4.4 TOTAL CAPITAL PRIVADO **
	local ImpKPrivadoPIB = `ISRPMPIB'+`OTROSKPIB'+`FMPPIB'

	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ing. de capital privado" ///
		_col(30) %7.3fc in y `IngKPrivadoPIB' ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y `ImpKPrivadoPIB' ///
		_col(63) %7.3fc in y `ImpKPrivadoPIB'/`IngKPrivadoPIB'*100 " %" "}"
	escalar pctpib IngKPrivadoPIB = `IngKPrivadoPIB'
	escalar pct IngKPrivadoTotTE = `ImpKPrivadoPIB'/`IngKPrivadoPIB'*100
	escalar pctpib ImpKPrivadoPIB = `ImpKPrivadoPIB'



	*******************************
	**# 5 Organismos y empresas ***
	*******************************
	* Los locals PEMEXPIB, CFEPIB, IMSSPIB, ISSSTEPIB, FMPPIB ya fueron convertidos en sección 4
	local ImpKPublicosPIB = `PEMEXPIB'+`CFEPIB'+`IMSSPIB'+`ISSSTEPIB'

	noisily di _newline(2) in y "{bf: C. " in y "Organismos y empresas" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "OyE públicas" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"

	** 5.1 Pemex (energía) **
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y `CapIncImpPIB' ///
		_col(40) in g "Pemex" ///
		_col(55) %7.3fc in y `PEMEXPIB' ///
		_col(63) %7.3fc in y `PEMEXPIB'/`CapIncImpPIB'*100 " %"
	escalar pct PEMEXTE = `PEMEXPIB'/`CapIncImpPIB'*100

	** 5.2 CFE (energía) **
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y `CapIncImpPIB' ///
		_col(40) in g "CFE" ///
		_col(55) %7.3fc in y `CFEPIB' ///
		_col(63) %7.3fc in y `CFEPIB'/`CapIncImpPIB'*100 " %"
	escalar pct CFETE = `CFEPIB'/`CapIncImpPIB'*100

	** 5.3 IMSS **
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y `CapIncImpPIB' ///
		_col(40) in g "IMSS" ///
		_col(55) %7.3fc in y `IMSSPIB' ///
		_col(63) %7.3fc in y `IMSSPIB'/`CapIncImpPIB'*100 " %"
	escalar pct IMSSTE = `IMSSPIB'/`CapIncImpPIB'*100

	** 5.4 ISSSTE **
	noisily di in g "  Ingresos de capital" ///
		_col(30) %7.3fc in y `CapIncImpPIB' ///
		_col(40) in g "ISSSTE" ///
		_col(55) %7.3fc in y `ISSSTEPIB' ///
		_col(63) %7.3fc in y `ISSSTEPIB'/`CapIncImpPIB'*100 " %"
	escalar pct ISSSTETE = `ISSSTEPIB'/`CapIncImpPIB'*100

	** 5.5 TOTAL INGRESOS DE CAPITAL PUBLICOS **
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Ingresos de capital" ///
		_col(30) %7.3fc in y `CapIncImpPIB' ///
		_col(40) in g "Ing. propios" ///
		_col(55) %7.3fc in y `ImpKPublicosPIB' ///
		_col(63) %7.3fc in y `ImpKPublicosPIB'/`CapIncImpPIB'*100 " %" "}"
	escalar pctpib IngKPublicosTotPIB = `ImpKPublicosPIB'
	escalar pct IngKPublicosTotTE = `ImpKPublicosPIB'/`CapIncImpPIB'*100
	escalar pctpib ImpKPublicosPIB = `ImpKPublicosPIB'



	******************************
	**# 6 Impuestos al consumo ***
	******************************
	* Convertir scalars de string a real
	local ConHogPIB = scalar(ConHogPIB)
	local VehiPIB = scalar(VehiPIB)
	local BebAPIB = scalar(BebAPIB)
	local TabaPIB = scalar(TabaPIB)
	local Recre7132PIB = scalar(Recre7132PIB)
	local ConsPriv21PIB = scalar(ConsPriv21PIB)

	local IVAPIB = scalar(IVAPIB)
	local ISANPIB = scalar(ISANPIB)
	local IEPSNPPIB = scalar(IEPSNPPIB)
	local IEPSPPIB = scalar(IEPSPPIB)
	local IMPORTPIB = scalar(IMPORTPIB)

	local AlcTabJuePIB = `BebAPIB'+`TabaPIB'+`Recre7132PIB'

	noisily di _newline(2) in y "{bf: D. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(30) %7s in g "% PIB" ///
		_col(40) "Al consumo" ///
		_col(55) %7s in g "% PIB" ///
		_col(63) in g "  TE (%)" "}"
	noisily di in g _dup(71) "-"

	** 6.1 IVA **
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y `ConHogPIB' ///
		_col(40) in g "IVA" ///
		_col(55) %7.3fc in y `IVAPIB' ///
		_col(63) %7.3fc in y `IVAPIB'/`ConHogPIB'*100 " %"
	escalar pct IVATE = `IVAPIB'/`ConHogPIB'*100

	** 6.2 ISAN **
	noisily di in g "  Compra de veh{c i'}culos" ///
		_col(30) %7.3fc in y `VehiPIB' ///
		_col(40) in g "ISAN" ///
		_col(55) %7.3fc in y `ISANPIB' ///
		_col(63) %7.3fc in y `ISANPIB'/`VehiPIB'*100 " %"
	escalar pct ISANTE = `ISANPIB'/`VehiPIB'*100

	** 6.3 IEPS (no petrolero) **
	noisily di in g "  Alcohol, tabaco y juegos" ///
		_col(30) %7.3fc in y `AlcTabJuePIB' ///
		_col(40) in g "IEPS (No petr.)" ///
		_col(55) %7.3fc in y `IEPSNPPIB' ///
		_col(63) %7.3fc in y `IEPSNPPIB'/`AlcTabJuePIB'*100 " %"
	escalar pct IEPSNPTE = `IEPSNPPIB'/`AlcTabJuePIB'*100

	** 6.4 IEPS (petrolero) **
	noisily di in g "  Consumo privado minería" ///
		_col(30) %7.3fc in y `ConsPriv21PIB' ///
		_col(40) in g "IEPS (Petr.)" ///
		_col(55) %7.3fc in y `IEPSPPIB' ///
		_col(63) %7.3fc in y `IEPSPPIB'/`ConsPriv21PIB'*100 " %"
	escalar pct IEPSPTE = `IEPSPPIB'/`ConsPriv21PIB'*100

	** 6.5 Importaciones **
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y `ConHogPIB' ///
		_col(40) in g "Importaciones" ///
		_col(55) %7.3fc in y `IMPORTPIB' ///
		_col(63) %7.3fc in y `IMPORTPIB'/`ConHogPIB'*100 " %"
	escalar pct IMPORTTE = `IMPORTPIB'/`ConHogPIB'*100

	** 6.6 TOTAL CONSUMO **
	local ingconsumoPIB = `IEPSPPIB'+`IEPSNPPIB'+`IVAPIB'+`ISANPIB'+`IMPORTPIB'

	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Consumo hogares e ISFLSH" ///
		_col(30) %7.3fc in y `ConHogPIB' ///
		_col(40) in g "Recaudaci{c o'}n" ///
		_col(55) %7.3fc in y `ingconsumoPIB' ///
		_col(63) %7.3fc in y `ingconsumoPIB'/`ConHogPIB'*100 " %" "}"
	escalar pctpib ingconsumoPIB = `ingconsumoPIB'
	escalar pct ingconsumoTE = `ingconsumoPIB'/`ConHogPIB'*100



	******************/
	**# 7. Base SIM ***
	*******************
	if "`enigh'" == "enigh" {
		capture use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
			ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
			using "`c(sysdir_site)'/master/perfiles`anio'.dta", clear 
		if _rc != 0 {
			noisily run "`c(sysdir_site)'/PerfilesSim.do" `anio'
			use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
				ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
				using "`c(sysdir_site)'/master/perfiles`anio'.dta", clear
		}

		* 7.1 Distribuir los ingresos entre las observaciones *
		* Convertir pibY de string a real (viene de SCN con comas)
		local pibY = scalar(pibY)
		
		foreach k of varlist ISRAS ISRPF CUOTAS ///
			ISRPM OTROSK ///
			FMP PEMEX CFE IMSS ISSSTE ///
			IVA IEPSNP IEPSP ISAN IMPORT {
			* Convertir cada scalar *PIB de string a real
			local `k'PIB = scalar(`k'PIB)
			Distribucion `k'_Sim, relativo(`k') macro(`=``k'PIB'/100*`pibY'')
		}

		* 7.2 Guardar *
		capture drop __*
		save `"`c(sysdir_site)'/users/$id/ingresos.dta"', replace
	}

	if "$textbook" == "textbook" {
		noisily scalarlatex, log(tasasEfectivas) alt(tasas)
	}


	**********/
	*** END ***
	***********
	timer off 8
	timer list 8
	noisily di _newline in g "Tiempo: " in y round(`=r(t8)/r(nt8)',.1) in g " segs."
}
end
