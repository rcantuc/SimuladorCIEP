*! version 1.1.0  TasasEfectivasMicro — TE micro/micro con opción entidad() (F1-bis Nuevo León)
*
* QUÉ ES ESTO (contrato F1 + F1-bis, DIAGNOSTICO_NL.md):
* Tasas efectivas construidas MICRO/MICRO: numerador = Σ variable de impuesto
* de master/perfiles<anio>.dta; denominador = Σ base micro ajustada a Cuentas
* Nacionales. La opción entidad(numlist) corta la muestra POR RESIDENCIA
* DESPUÉS del ajuste nacional (factores Altimir/TT/Distribucion heredados tal
* cual; aquí NO se recalibra nada). Sin entidad() calcula el espejo micro/micro
* NACIONAL que valida contra la TE oficial macro/macro de TasasEfectivas.ado
* (escalares Dif*TE<sufijo>).
*
* PREMISA F1-bis (verificada en el Anexo F1-bis del diagnóstico): la base
* micro reconstruye el 100.00% del PIB, así que TODOS los componentes del
* denominador oficial tienen contraparte micro. Ninguno se declara faltante:
*
*   RemSalSS = RemSal+SSEmp+SSImp+ImpNetProduccionL
*     -> ing_subor (perfiles; Σ = RemSal+ImpNetProduccionL, PerfilesSim.do:196)
*        + cuotasTPF -> SSEmpleadores+SSImputada (Households.do:1544-1547;
*        el propio pipeline usa ese mapeo en Households.do:1665-1667)
*   MixL -> ing_mixtoL (households post-Altimir)
*   IngKPrivado = CapIncImp - públicos, con CapIncImp = ExNOpSoc+ExNOpHog
*     +MixKN+ImpNetProduccionK+ImpNet (SCN.ado:229)
*     -> ing_bruto_tpm (Σ = ExNOpSoc+ImpNet-IngKPublicos, PerfilesSim.do:201)
*        + ing_estim_alqu -> ExNOpHog + ing_mixtoK -> MixKN
*        + ing_bruto_tpm -> ImpNetProduccionK + FMP (var de perfiles; se
*        reintegra porque PerfilesSim restó 5 públicos y la TE oficial solo 4)
*   ConHog -> gastoanualTOT · Vehi -> gas_pc_Vehi
*   BebA+Taba+Recre7132 -> gas_pc_BebA + gas_pc_Taba + gas_pc_RecrT->Recre7132
*     (el gasto en juegos vive DENTRO de RecrT: la ENIGH 2024 no genera una
*     categoría IEPS "Juegos" separada; se imputa con el canal Distribucion,
*     el mismo del pipeline)
*   ConsPriv21 -> gas_pc_Gasolinas+gas_pc_Combustibles (consumption_categ_ieps_pc)
*
* CAUSAS RESIDUALES IDENTIFICADAS de las brechas oficial<->micro (no son
* faltantes de cobertura): (i) numerador: montos LIF (divSIM) vía Distribucion
* vs parámetros de SIM.do §4.1; (ii) públicos LIF vs parámetros *PIB en
* BaseKPriv; (iii) Recre7132 y ConsPriv21 imputados por participación.
*
* ESTE PROGRAMA NO SE INVOCA EN EL PIPELINE NACIONAL (SIM.do intacto;
* output.txt intacto). Lo llama el driver 01_modulos/EntidadNL.do, que también
* corre la incidencia por decil sobre users/$id/aportaciones.dta (el objeto
* del pipeline, SIM.do §7.1) con INCI.ado y la compuerta INCD* (F1-bis D.1).
*
* ENTIDAD: 2 primeros dígitos de folioviv (convención de PerfilesSim.do:477).
*
* ESCALARES (registro solo-aditivo; SIN guiones bajos): sufijos nac / nl.
*   mxn  Rec<IMP><suf> · Base<BASE><suf> · IngBruto<suf>   montos anuales
*   personas Pob<suf>
*   pct  <IMP>TE<suf> · Dif<IMP>TE<suf> (vs oficial) · Rel<IMP>TE<suf> (vs nac)
*
* Sintaxis:  TasasEfectivasMicro [, ANIO(int) ENTidad(numlist) SUFijo(str)]
* OJO: destruye los datos en memoria (carga perfiles<anio>.dta).

program define TasasEfectivasMicro
quietly {
	version 14
	syntax [, ANIO(int -1) ENTidad(numlist integer min=1 >=1 <=32) SUFijo(string)]

	** 0.1 Defaults y contratos de nombre **
	if `anio' == -1 {
		capture confirm scalar anioPE
		if _rc == 0 {
			local anio = scalar(anioPE)
		}
		else {
			local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
			local anio = substr(`"`=trim("`fecha'")'"',1,4)
		}
	}
	if `"`sufijo'"' == "" {
		if "`entidad'" == "" {
			local sufijo "nac"
		}
		else {
			noisily di as err "TasasEfectivasMicro: con entidad() el sufijo() es obligatorio (p. ej. sufijo(nl))."
			exit 198
		}
	}
	if strpos("`sufijo'", "_") {
		noisily di as err "TasasEfectivasMicro: el sufijo alimenta macros LaTeX; sin guiones bajos (contrato F1)."
		exit 198
	}

	** 0.2 Año ENIGH (mismo mapeo que PerfilesSim.do) **
	capture confirm scalar anioenigh
	if _rc == 0 {
		local anioenigh = scalar(anioenigh)
	}
	else {
		if `anio' >= 2024 local anioenigh = 2024
		else if `anio' >= 2022 local anioenigh = 2022
		else if `anio' >= 2020 local anioenigh = 2020
		else if `anio' >= 2018 local anioenigh = 2018
		else if `anio' >= 2016 local anioenigh = 2016
		else local anioenigh = 2014
	}

	noisily di _newline(2) in g _dup(20) "." "{bf:   TE micro/micro " in y `anio' " — sufijo `sufijo'" in g "   }" _dup(20) "."

	** 1. Macros SCN (niveles; los mismos que consumen PerfilesSim/Expenditure) **
	SCN, anio(`anio') nographs
	local PIBS = scalar(PIB)
	foreach s in MixL ConHog Vehi BebA Taba SSEmpleadores SSImputada ExNOpHog MixKN ImpNetProduccionK {
		local `s' = scalar(`s')
	}
	* Niveles derivados de escalares pctpib ya registrados por SCN (sin números a mano) *
	local Recre7132 = scalar(Recre7132PIB)/100*`PIBS'
	local ConsPriv21 = scalar(ConsPriv21PIB)/100*`PIBS'

	** 2. Base micro post-ajuste (numeradores) + bases de households (denominadores) **
	use "`c(sysdir_site)'/master/perfiles`anio'.dta", clear
	merge 1:1 folioviv foliohog numren using "`c(sysdir_site)'/master/`anioenigh'/households.dta", ///
		nogen keep(master match) keepusing(ing_mixtoL ing_mixtoK ing_estim_alqu ///
		gastoanualTOT gas_pc_Vehi gas_pc_BebA gas_pc_Taba gas_pc_RecrT)
	merge 1:1 folioviv foliohog numren using "`c(sysdir_site)'/master/`anioenigh'/consumption_categ_ieps_pc.dta", ///
		nogen keep(master match) keepusing(gas_pc_Gasolinas gas_pc_Combustibles)

	** 2.1 Bases al año de política — mismo canal nacional (Distribucion, factores nacionales) **
	* Salarios: ing_subor (RemSal+INPL) + contribuciones patronales e imputadas *
	Distribucion BaseCSS, relativo(cuotasTPF) macro(`=`SSEmpleadores'+`SSImputada'')
	egen double BaseSalTot = rsum(ing_subor BaseCSS)
	* Mixto laboral *
	Distribucion BaseMixL, relativo(ing_mixtoL) macro(`MixL')
	* Capital privado: tpm + alquiler imputado + mixto capital + INPK + FMP *
	Distribucion BaseAlqK, relativo(ing_estim_alqu) macro(`ExNOpHog')
	Distribucion BaseMixK, relativo(ing_mixtoK) macro(`MixKN')
	Distribucion BaseINPK, relativo(ing_bruto_tpm) macro(`ImpNetProduccionK')
	egen double BaseKPrivTot = rsum(ing_bruto_tpm BaseAlqK BaseMixK BaseINPK FMP)
	* Consumo *
	Distribucion BaseCons, relativo(gastoanualTOT) macro(`ConHog')
	Distribucion BaseVehi, relativo(gas_pc_Vehi) macro(`Vehi')
	Distribucion BaseBebA, relativo(gas_pc_BebA) macro(`BebA')
	Distribucion BaseTaba, relativo(gas_pc_Taba) macro(`Taba')
	Distribucion BaseJuegos, relativo(gas_pc_RecrT) macro(`Recre7132')
	egen double BaseAlcTab = rsum(BaseBebA BaseTaba BaseJuegos)
	egen double relComb = rsum(gas_pc_Gasolinas gas_pc_Combustibles)
	Distribucion BaseComb, relativo(relComb) macro(`ConsPriv21')

	** 2.2 Corte por entidad de residencia (post-ajuste; sin recalibrar) **
	g byte muestra = 1
	if "`entidad'" != "" {
		tempvar entvar
		g `entvar' = real(substr(folioviv,1,2))
		replace muestra = 0
		foreach e of numlist `entidad' {
			replace muestra = 1 if `entvar' == `e'
		}
		noisily di _newline in g "  Entidad(es): " in y "`entidad'" in g " — personas en la muestra:"
		noisily count if muestra == 1
	}

	** 3. Sumas ponderadas (misma convención [aw=factor] del pipeline) **
	local cols "ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT BaseSalTot BaseMixL BaseKPrivTot BaseCons BaseVehi BaseAlcTab BaseComb ingbrutotot"
	tabstat `cols' [aw=factor] if muestra == 1, stat(sum) save
	tempname S
	matrix `S' = r(StatTotal)
	local i = 1
	foreach c of local cols {
		local s`c' = `S'[1,`i']
		local ++i
	}
	tabstat factor if muestra == 1, stat(sum) save
	local spob = r(StatTotal)[1,1]

	** 3.1 Montos (mxn) y población (personas) **
	foreach k in ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT {
		escalar mxn Rec`k'`sufijo' = `s`k''
	}
	escalar mxn RecTotal`sufijo' = `sISRAS'+`sCUOTAS'+`sISRPF'+`sISRPM'+`sOTROSK'+`sIVA'+`sIEPSNP'+`sIEPSP'+`sISAN'+`sIMPORT'
	escalar mxn BaseSal`sufijo' = `sBaseSalTot'
	escalar mxn BaseMix`sufijo' = `sBaseMixL'
	escalar mxn BaseKPriv`sufijo' = `sBaseKPrivTot'
	escalar mxn BaseConsu`sufijo' = `sBaseCons'
	escalar mxn BaseVehic`sufijo' = `sBaseVehi'
	escalar mxn BaseAlcTaba`sufijo' = `sBaseAlcTab'
	escalar mxn BaseCombu`sufijo' = `sBaseComb'
	escalar mxn IngBruto`sufijo' = `singbrutotot'
	escalar personas Pob`sufijo' = `spob'

	** 3.2 Tasas efectivas micro/micro (pct) **
	escalar pct ISRASTE`sufijo' = `sISRAS'/`sBaseSalTot'*100
	escalar pct CUOTASTE`sufijo' = `sCUOTAS'/`sBaseSalTot'*100
	escalar pct ISRPFTE`sufijo' = `sISRPF'/`sBaseMixL'*100
	escalar pct ISRPMTE`sufijo' = `sISRPM'/`sBaseKPrivTot'*100
	escalar pct OTROSKTE`sufijo' = `sOTROSK'/`sBaseKPrivTot'*100
	escalar pct IVATE`sufijo' = `sIVA'/`sBaseCons'*100
	escalar pct IMPORTTE`sufijo' = `sIMPORT'/`sBaseCons'*100
	escalar pct ISANTE`sufijo' = `sISAN'/`sBaseVehi'*100
	escalar pct IEPSNPTE`sufijo' = `sIEPSNP'/`sBaseAlcTab'*100
	escalar pct IEPSPTE`sufijo' = `sIEPSP'/`sBaseComb'*100
	escalar pct YlImpTE`sufijo' = (`sISRAS'+`sISRPF'+`sCUOTAS')/(`sBaseSalTot'+`sBaseMixL')*100
	escalar pct ingconsumoTE`sufijo' = (`sIVA'+`sIEPSNP'+`sIEPSP'+`sISAN'+`sIMPORT')/`sBaseCons'*100

	** 3.3 Validación vs TE oficial macro/macro (si los escalares están vivos) **
	local telist "ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP IEPSP YlImp ingconsumo"
	foreach te of local telist {
		capture confirm scalar `te'TE
		if _rc == 0 {
			capture escalar pct Dif`te'TE`sufijo' = (scalar(`te'TE`sufijo')/scalar(`te'TE)-1)*100
		}
		if "`sufijo'" != "nac" {
			capture confirm scalar `te'TEnac
			if _rc == 0 {
				capture escalar pct Rel`te'TE`sufijo' = scalar(`te'TE`sufijo') - scalar(`te'TEnac)
			}
		}
	}

	** 3.4 Display **
	noisily di _newline in g "{bf:  Base / impuesto" ///
		_col(34) %10s "Base (mmdp)" ///
		_col(48) %10s "Rec (mmdp)" ///
		_col(62) %8s "TE (%)" "}"
	noisily di in g _dup(71) "-"
	noisily di in g "  Salarios+CSS / ISR asalariados" ///
		_col(34) %10.0fc in y `sBaseSalTot'/1e9 _col(48) %10.0fc in y `sISRAS'/1e9 ///
		_col(62) %8.3fc in y scalar(ISRASTE`sufijo')
	noisily di in g "  Salarios+CSS / Cuotas IMSS" ///
		_col(34) %10.0fc in y `sBaseSalTot'/1e9 _col(48) %10.0fc in y `sCUOTAS'/1e9 ///
		_col(62) %8.3fc in y scalar(CUOTASTE`sufijo')
	noisily di in g "  Mixto (laboral) / ISR PF" ///
		_col(34) %10.0fc in y `sBaseMixL'/1e9 _col(48) %10.0fc in y `sISRPF'/1e9 ///
		_col(62) %8.3fc in y scalar(ISRPFTE`sufijo')
	noisily di in g "  Capital privado / ISR PM" ///
		_col(34) %10.0fc in y `sBaseKPrivTot'/1e9 _col(48) %10.0fc in y `sISRPM'/1e9 ///
		_col(62) %8.3fc in y scalar(ISRPMTE`sufijo')
	noisily di in g "  Capital privado / Otros K" ///
		_col(34) %10.0fc in y `sBaseKPrivTot'/1e9 _col(48) %10.0fc in y `sOTROSK'/1e9 ///
		_col(62) %8.3fc in y scalar(OTROSKTE`sufijo')
	noisily di in g "  Consumo / IVA" ///
		_col(34) %10.0fc in y `sBaseCons'/1e9 _col(48) %10.0fc in y `sIVA'/1e9 ///
		_col(62) %8.3fc in y scalar(IVATE`sufijo')
	noisily di in g "  Consumo / Importaciones" ///
		_col(34) %10.0fc in y `sBaseCons'/1e9 _col(48) %10.0fc in y `sIMPORT'/1e9 ///
		_col(62) %8.3fc in y scalar(IMPORTTE`sufijo')
	noisily di in g "  Vehículos / ISAN" ///
		_col(34) %10.0fc in y `sBaseVehi'/1e9 _col(48) %10.0fc in y `sISAN'/1e9 ///
		_col(62) %8.3fc in y scalar(ISANTE`sufijo')
	noisily di in g "  Alcohol, tabaco y juegos / IEPS NP" ///
		_col(34) %10.0fc in y `sBaseAlcTab'/1e9 _col(48) %10.0fc in y `sIEPSNP'/1e9 ///
		_col(62) %8.3fc in y scalar(IEPSNPTE`sufijo')
	noisily di in g "  Combustibles / IEPS P" ///
		_col(34) %10.0fc in y `sBaseComb'/1e9 _col(48) %10.0fc in y `sIEPSP'/1e9 ///
		_col(62) %8.3fc in y scalar(IEPSPTE`sufijo')
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Laborales (ISRAS+ISRPF+Cuotas)" ///
		_col(34) %10.0fc in y (`sBaseSalTot'+`sBaseMixL')/1e9 ///
		_col(48) %10.0fc in y (`sISRAS'+`sISRPF'+`sCUOTAS')/1e9 ///
		_col(62) %8.3fc in y scalar(YlImpTE`sufijo') "}"
	noisily di in g "{bf:  Consumo (IVA+IEPS+ISAN+Imp)" ///
		_col(34) %10.0fc in y `sBaseCons'/1e9 ///
		_col(48) %10.0fc in y (`sIVA'+`sIEPSNP'+`sIEPSP'+`sISAN'+`sIMPORT')/1e9 ///
		_col(62) %8.3fc in y scalar(ingconsumoTE`sufijo') "}"

	noisily di _newline in g "  TasasEfectivasMicro: listo (sufijo " in y "`sufijo'" in g ")."
}
end
