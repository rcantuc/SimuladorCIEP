*! version 8.1 CIEP 08nov2026 (8.16b: isrpm_incidencia = propiedad -> denominador de ISRPMTE = B.2n S.11 + S.12; cuadro de anclas al estandar §D)
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
	noisily _log modulo "TasasEfectivas  ·  tasas efectivas de los ingresos públicos, `anio'" ref("CUAD-1 §4; /metodo")



	*********************************
	**# 1 Cuentas macroeconómicas ***
	*********************************
	SCN, anio(`anio') nographs
	


	*********************
	**# 2 RECAUDACIÓN ***
	*********************
	* Sin parametros de escenario (ISRASPIB, ...), el default es lo observado
	* en LIF `anio': se toma de r() (LIF ya no escribe escalares globales por
	* grupo) y se declara aqui, explicitamente, como parametro. *
	capture confirm scalar ISRASPIB
	if _rc != 0 {
		noisily LIF if divLIF != 10, anio(`anio') by(divSIM) $update $nographs `eofp'		///
			title("Ingresos presupuestarios") 					/// Cambiar título de la gráfica
			desde(2013) 								/// Año de inicio para el PROMEDIO
			min(0)							/// % del PIB mínimo
			rows(2)									//  Número de filas en la leyenda
		foreach k in ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT {
			local `k'LIF = r(`k'PIB)
		}
		foreach k in ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT {
			escalar pctpib `k'PIB = ``k'LIF'
		}
		* 8.16a/8.16b: cuadro de anclas a la recaudacion al estandar §D (_tabla_anclas.ado v2; catalogo 05_scripts/scn-cuentas.csv); solo log *
		_tabla_anclas clear
		foreach k in ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT {
			_tabla_anclas add, codigo(`k') sector(S.13) fuente("LIF `anio' · divSIM") valor(``k'LIF'/100*scalar(PIB)) variable(`k')
		}
		noisily _tabla_anclas print, titulo("Anclas a la recaudación: LIF `anio' por impuesto, divSIM; Σ repartido = LIF por construcción") sello("verde") razon("master/LIF.dta, asset LIFs.xlsx") unidad("MXN `anio'") pib(scalar(PIB)) nota("cada impuesto se reparte con Distribucion ∝ su variable micro de perfiles`anio'.dta (ISR_asalariados, ISR_PF, ISR_PM ∝ ing_d4_rel con isrpm_incidencia = propiedad, cuotasTP, IVA, IEPS micro y gasolinas + combustibles con ieps_relativo = micro, ISAN ∝ vehículos, importaciones ∝ gasto); Σ repartido = LIF al peso") ref("CUAD-1 §4")
	}



	*************************************/
	**# 3 Impuestos al ingreso laboral ***
	**************************************
	noisily _log cuadro clear
	noisily _log cuadro col, titulo("Base en cuentas nacionales") flex
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("Impuesto") ancho(30)
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("TE %") fmt(%7.3f)

	** 3.1 ISR (asalariados) **
	local RemSalPIB = scalar(RemSalPIB)
	local ISRASPIB = scalar(ISRASPIB)
	local RemSalSSPIB = scalar(RemSalPIB)+scalar(SSImputadaPIB)+scalar(SSEmpleadoresPIB)+scalar(ImpNetProduccionLPIB)

	noisily _log cuadro fila "Remuneración de los asalariados y contribuciones" "`RemSalSSPIB'" "ISR por salarios" "`ISRASPIB'" "`ISRASPIB'/`RemSalSSPIB'*100"
	escalar pct ISRASTE = `ISRASPIB'/`RemSalSSPIB'*100

	** 3.2 ISR (personas físicas) **
	local MixLPIB = scalar(MixLPIB)
	local ISRPFPIB = scalar(ISRPFPIB)

	noisily _log cuadro fila "Ingreso mixto neto, parte laboral" "`MixLPIB'" "ISR de personas físicas" "`ISRPFPIB'" "`ISRPFPIB'/`MixLPIB'*100"
	escalar pct ISRPFTE = `ISRPFPIB'/`MixLPIB'*100

	** 3.3 Cuotas (IMSS) **
	local CUOTASPIB = scalar(CUOTASPIB)

	noisily _log cuadro fila "Remuneración de los asalariados y contribuciones" "`RemSalSSPIB'" "Cuotas IMSS" "`CUOTASPIB'" "`CUOTASPIB'/`RemSalSSPIB'*100"
	escalar pct CUOTASTE = `CUOTASPIB'/`RemSalSSPIB'*100

	** 3.4 TOTAL LABORALES **
	local YlPIB = scalar(YlPIB)
	local YlImpPIB = `ISRASPIB'+`ISRPFPIB'+`CUOTASPIB'

	noisily _log cuadro fila "(=) Ingresos laborales" "`YlPIB'" "(=) Recaudación" "`YlImpPIB'" "`YlImpPIB'/`YlPIB'*100", sep negrita
	noisily _log cuadro print, titulo("A. Impuestos al trabajo, año `anio'") unidad("% del PIB `anio'") ref("CUAD-1 §4; /metodo tasas efectivas")
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
	* 8.16b (isrpm_incidencia = propiedad; CUAD-1 §4; firma decision 7 corregida por Ricardo 2026-11-08): el ISR de personas morales es de sociedades
	* y su tasa efectiva se mide sobre el excedente neto de operacion de S.11 + S.12 (B.2n, CSI f.63; pastcast del SCN para `anio'), no sobre el
	* residuo BIE de capital privado ni sobre B.5n (saldo tras pagar renta de la propiedad, que dejaba la tasa por encima de 100 %). *
	if "$isrpm_incidencia" == "" global isrpm_incidencia "propiedad"
	local ISRPMBasePIB = `IngKPrivadoPIB'
	local ISRPMBaseTxt "Ing. de capital privado"
	if "$isrpm_incidencia" == "propiedad" {
		capture confirm scalar B2nNoFin
		if _rc == 0 {
			local ISRPMBasePIB = (scalar(B2nNoFin) + scalar(B2nFin))/scalar(PIB)*100
			local ISRPMBaseTxt "B.2n S.11 + S.12"
		}
		else noisily _log aviso, tipo(FLAG) texto("TasasEfectivas: SCN sin B2nNoFin/B2nFin para `anio'; ISRPMTE sobre el capital privado BIE") ref("CUAD-1 §4.0") rojo
	}

	noisily _log cuadro clear
	noisily _log cuadro col, titulo("Base en cuentas nacionales") flex
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("Impuesto") ancho(30)
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("TE %") fmt(%7.3f)

	** 4.1 ISR (personas morales) **
	noisily _log cuadro fila "`ISRPMBaseTxt'" "`ISRPMBasePIB'" "ISR de personas morales" "`ISRPMPIB'" "`ISRPMPIB'/`ISRPMBasePIB'*100"

	** 4.2 Productos, derechos, aprovechamientos, contribuciones **
	noisily _log cuadro fila "Ingreso de capital privado" "`IngKPrivadoPIB'" "Otros ingresos: productos, derechos, aprovechamientos" "`OTROSKPIB'" "`OTROSKPIB'/`IngKPrivadoPIB'*100"
	escalar pct ISRPMTE = `ISRPMPIB'/`ISRPMBasePIB'*100
	escalar pctpib ISRPMBasePIB = `ISRPMBasePIB'
	escalar pct OTROSKTE = `OTROSKPIB'/`IngKPrivadoPIB'*100
	if "$isrpm_incidencia" == "propiedad" & "`ISRPMBaseTxt'" == "B.2n S.11 + S.12" noisily _log cuadro nota "ISRPMTE sobre B.2n S.11 + S.12 = `=strtrim(string(`ISRPMBasePIB', "%7.3f"))' % del PIB (isrpm_incidencia = propiedad, firma decisión 7)"

	** 4.3 FMP (energía) **
	noisily _log cuadro fila "Ingreso de capital privado" "`IngKPrivadoPIB'" "Fondo Mexicano del Petróleo" "`FMPPIB'" "`FMPPIB'/`IngKPrivadoPIB'*100"
	escalar pct FMPTE = `FMPPIB'/`IngKPrivadoPIB'*100

	** 4.4 TOTAL CAPITAL PRIVADO **
	local ImpKPrivadoPIB = `ISRPMPIB'+`OTROSKPIB'+`FMPPIB'

	noisily _log cuadro fila "Ingreso de capital privado" "`IngKPrivadoPIB'" "(=) Recaudación" "`ImpKPrivadoPIB'" "`ImpKPrivadoPIB'/`IngKPrivadoPIB'*100", sep negrita
	noisily _log cuadro print, titulo("B. Impuestos al capital, año `anio'") unidad("% del PIB `anio'") ref("CUAD-1 §4; /metodo tasas efectivas")
	escalar pctpib IngKPrivadoPIB = `IngKPrivadoPIB'
	escalar pct IngKPrivadoTotTE = `ImpKPrivadoPIB'/`IngKPrivadoPIB'*100
	escalar pctpib ImpKPrivadoPIB = `ImpKPrivadoPIB'



	*******************************
	**# 5 Organismos y empresas ***
	*******************************
	* Los locals PEMEXPIB, CFEPIB, IMSSPIB, ISSSTEPIB, FMPPIB ya fueron convertidos en sección 4
	local ImpKPublicosPIB = `PEMEXPIB'+`CFEPIB'+`IMSSPIB'+`ISSSTEPIB'

	noisily _log cuadro clear
	noisily _log cuadro col, titulo("Base en cuentas nacionales") flex
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("Impuesto") ancho(30)
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("TE %") fmt(%7.3f)

	** 5.1 Pemex (energía) **
	noisily _log cuadro fila "Ingresos de capital, neto más impuestos" "`CapIncImpPIB'" "Pemex" "`PEMEXPIB'" "`PEMEXPIB'/`CapIncImpPIB'*100"
	escalar pct PEMEXTE = `PEMEXPIB'/`CapIncImpPIB'*100

	** 5.2 CFE (energía) **
	noisily _log cuadro fila "Ingresos de capital, neto más impuestos" "`CapIncImpPIB'" "CFE" "`CFEPIB'" "`CFEPIB'/`CapIncImpPIB'*100"
	escalar pct CFETE = `CFEPIB'/`CapIncImpPIB'*100

	** 5.3 IMSS **
	noisily _log cuadro fila "Ingresos de capital, neto más impuestos" "`CapIncImpPIB'" "IMSS" "`IMSSPIB'" "`IMSSPIB'/`CapIncImpPIB'*100"
	escalar pct IMSSTE = `IMSSPIB'/`CapIncImpPIB'*100

	** 5.4 ISSSTE **
	noisily _log cuadro fila "Ingresos de capital, neto más impuestos" "`CapIncImpPIB'" "ISSSTE" "`ISSSTEPIB'" "`ISSSTEPIB'/`CapIncImpPIB'*100"
	escalar pct ISSSTETE = `ISSSTEPIB'/`CapIncImpPIB'*100

	** 5.5 TOTAL INGRESOS DE CAPITAL PUBLICOS **
	noisily _log cuadro fila "Ingresos de capital, neto más impuestos" "`CapIncImpPIB'" "(=) Ingresos propios" "`ImpKPublicosPIB'" "`ImpKPublicosPIB'/`CapIncImpPIB'*100", sep negrita
	noisily _log cuadro print, titulo("C. Organismos y empresas públicas, ingresos propios, año `anio'") unidad("% del PIB `anio'") ref("CUAD-1 §4; /metodo tasas efectivas")
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

	noisily _log cuadro clear
	noisily _log cuadro col, titulo("Base en cuentas nacionales") flex
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("Impuesto") ancho(30)
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("TE %") fmt(%7.3f)

	** 6.1 IVA **
	noisily _log cuadro fila "Consumo de hogares e ISFLSH" "`ConHogPIB'" "IVA" "`IVAPIB'" "`IVAPIB'/`ConHogPIB'*100"
	escalar pct IVATE = `IVAPIB'/`ConHogPIB'*100

	** 6.2 ISAN **
	noisily _log cuadro fila "Adquisición de vehículos" "`VehiPIB'" "ISAN" "`ISANPIB'" "`ISANPIB'/`VehiPIB'*100"
	escalar pct ISANTE = `ISANPIB'/`VehiPIB'*100

	** 6.3 IEPS (no petrolero) **
	noisily _log cuadro fila "Alcohol, tabaco y juegos de azar" "`AlcTabJuePIB'" "IEPS no petrolero" "`IEPSNPPIB'" "`IEPSNPPIB'/`AlcTabJuePIB'*100"
	escalar pct IEPSNPTE = `IEPSNPPIB'/`AlcTabJuePIB'*100

	** 6.4 IEPS (petrolero) **
	noisily _log cuadro fila "Consumo privado de minería" "`ConsPriv21PIB'" "IEPS petrolero" "`IEPSPPIB'" "`IEPSPPIB'/`ConsPriv21PIB'*100"
	escalar pct IEPSPTE = `IEPSPPIB'/`ConsPriv21PIB'*100

	** 6.5 Importaciones **
	noisily _log cuadro fila "Consumo de hogares e ISFLSH" "`ConHogPIB'" "Impuesto a las importaciones" "`IMPORTPIB'" "`IMPORTPIB'/`ConHogPIB'*100"
	escalar pct IMPORTTE = `IMPORTPIB'/`ConHogPIB'*100

	** 6.6 TOTAL CONSUMO **
	local ingconsumoPIB = `IEPSPPIB'+`IEPSNPPIB'+`IVAPIB'+`ISANPIB'+`IMPORTPIB'

	noisily _log cuadro fila "Consumo de hogares e ISFLSH" "`ConHogPIB'" "(=) Recaudación" "`ingconsumoPIB'" "`ingconsumoPIB'/`ConHogPIB'*100", sep negrita
	noisily _log cuadro print, titulo("D. Impuestos al consumo, año `anio'") unidad("% del PIB `anio'") ref("CUAD-1 §4; /metodo tasas efectivas")
	escalar pctpib ingconsumoPIB = `ingconsumoPIB'
	escalar pct ingconsumoTE = `ingconsumoPIB'/`ConHogPIB'*100



	******************/
	**# 7. Base SIM ***
	*******************
	if "`enigh'" == "enigh" {
		capture use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
			ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
			using "${SIMROOT}/master/perfiles`anio'.dta", clear 
		if _rc != 0 {
			noisily run "${SIMROOT}/01_modulos/PerfilesSim.do" `=anioPE'
			use (folioviv foliohog numren factor edad decil grupoedad sexo rural escol ingbrutotot ///
				ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT) ///
				using "${SIMROOT}/master/perfiles`anio'.dta", clear
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
		save `"${SIMROOT}/users/$id/ingresos.dta"', replace
	}

	if "$textbook" == "textbook" {
		noisily scalarlatex, log(tasasEfectivas) alt(tasas)
	}


	**********/
	*** END ***
	***********
	timer off 8
	timer list 8
	noisily _log tiempo, timer(8) texto("TasasEfectivas")
}
end
