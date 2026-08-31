*! version 1.0.0  TasasEfectivasMicro — TE micro/micro con opción entidad() (F1 Nuevo León)
*
* QUÉ ES ESTO (contrato F1, DIAGNOSTICO_NL.md + enmiendas aprobadas):
* Tasas efectivas construidas MICRO/MICRO: numerador = Σ variable de impuesto
* de master/perfiles<anio>.dta; denominador = Σ base micro ajustada a Cuentas
* Nacionales. La opción entidad(numlist) corta la muestra POR RESIDENCIA
* DESPUÉS del ajuste nacional (los factores Altimir/TT/Distribucion se heredan
* tal cual; aquí NO se recalibra nada). Sin entidad() calcula el espejo
* micro/micro NACIONAL, que sirve de validación contra la TE oficial
* macro/macro de TasasEfectivas.ado (escalares Dif*TE<sufijo>).
*
* ESTE PROGRAMA NO SE INVOCA EN EL PIPELINE NACIONAL (SIM.do intacto;
* output.txt intacto). Lo llama el driver 01_modulos/EntidadNL.do.
*
* ENTIDAD: 2 primeros dígitos de folioviv (convención ENIGH ya usada por
* PerfilesSim.do:477). ubica_geo no sobrevive al collapse de Households.do.
*
* DENOMINADORES MICRO (base ajustada, mismo canal Distribucion que
* PerfilesSim.do; factores nacionales):
*   salarios  ing_subor            (ya escalado a RemSal+ImpNetProduccionL)
*   mixto     ing_mixtoL           (households.dta post-Altimir → MixL)
*   capital   ing_bruto_tpm        (ya escalado a ExNOpSoc+ImpNet-IngKPublicos)
*   consumo   gastoanualTOT        (households.dta post-TT → ConHog)
*   vehículos gas_pc_Vehi (→ Vehi) · alcohol+tabaco gas_pc_BebA+gas_pc_Taba (→ BebA+Taba)
*
* COMPONENTES DEL DENOMINADOR OFICIAL SIN CONTRAPARTE MICRO — DECLARADOS,
* razón COBERTURA, nunca imputados al vuelo (enmienda 1 de F0):
*   - SSEmpleadores + SSImputada (denominador oficial de ISRASTE/CUOTASTE)
*   - ConsPriv21, consumo privado de minería (denominador oficial de IEPSPTE):
*     el IEPS petrolero entra al numerador del agregado de consumo, pero NO
*     tiene TE micro propia.
*   - Recre7132, juegos (parte del denominador oficial de IEPSNPTE).
*
* ESCALARES (registro solo-aditivo; SIN guiones bajos — alimentan macros
* LaTeX): sufijos nac (nacional micro/micro), nl (NL, deciles nacionales),
* nle (NL, deciles estatales; solo incidencia). Familias:
*   mxn  Rec<IMP><suf>  Base<BASE><suf>        montos anuales
*   personas Pob<suf>                          población expandida
*   pct  <IMP>TE<suf>                          tasa efectiva micro/micro
*   pct  Dif<IMP>TE<suf>                       vs TE oficial macro/macro (si viva)
*   pct  Rel<IMP>TE<suf>                       <suf> menos nac, en puntos de TE
*   mxnpc <VAR><suf><DEC> · pct dis<VAR><suf><DEC> · pct inc<VAR><suf><DEC>
*     incidencia por decil (misma rutina nacional: INCI.ado, espejo de
*     Simulador.ado §1.3.3/§4), VAR en {AlTrabajo AlCapital AlConsumo
*     ImpTotal}, DEC en {I..X Tot}.
*
* Sintaxis:  TasasEfectivasMicro [, ANIO(int) ENTidad(numlist) SUFijo(str) NOINCidencia]
* OJO: destruye los datos en memoria (carga perfiles<anio>.dta).

program define TasasEfectivasMicro
quietly {
	version 14
	syntax [, ANIO(int -1) ENTidad(numlist integer min=1 >=1 <=32) SUFijo(string) NOINCidencia]

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
	local MixL = scalar(MixL)
	local ConHog = scalar(ConHog)
	local Vehi = scalar(Vehi)
	local BebA = scalar(BebA)
	local Taba = scalar(Taba)

	** 2. Base micro post-ajuste (numeradores) + bases de households (denominadores) **
	use "`c(sysdir_site)'/master/perfiles`anio'.dta", clear
	merge 1:1 folioviv foliohog numren using "`c(sysdir_site)'/master/`anioenigh'/households.dta", ///
		nogen keep(master match) keepusing(ing_mixtoL gastoanualTOT gas_pc_Vehi gas_pc_BebA gas_pc_Taba)

	** 2.1 Bases al año de política — mismo canal nacional (Distribucion, factores nacionales) **
	Distribucion BaseMixL, relativo(ing_mixtoL) macro(`MixL')
	Distribucion BaseCons, relativo(gastoanualTOT) macro(`ConHog')
	Distribucion BaseVehi, relativo(gas_pc_Vehi) macro(`Vehi')
	Distribucion BaseBebA, relativo(gas_pc_BebA) macro(`BebA')
	Distribucion BaseTaba, relativo(gas_pc_Taba) macro(`Taba')
	egen double BaseAlcTab = rsum(BaseBebA BaseTaba)

	** 2.2 Corte por entidad de residencia (post-ajuste; sin recalibrar) **
	g byte muestra = 1
	if "`entidad'" != "" {
		tempvar entvar
		g `entvar' = real(substr(folioviv,1,2))
		replace muestra = 0
		foreach e of numlist `entidad' {
			replace muestra = 1 if `entvar' == `e'
		}
		noisily di _newline in g "  Entidad(es): " in y "`entidad'" in g " — hogares/personas en la muestra:"
		noisily count if muestra == 1
	}

	** 3. Sumas ponderadas (misma convención [aw=factor] del pipeline) **
	local cols "ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT ing_subor BaseMixL ing_bruto_tpm BaseCons BaseVehi BaseAlcTab ingbrutotot"
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
	escalar mxn BaseSal`sufijo' = `sing_subor'
	escalar mxn BaseMix`sufijo' = `sBaseMixL'
	escalar mxn BaseKPriv`sufijo' = `sing_bruto_tpm'
	escalar mxn BaseConsu`sufijo' = `sBaseCons'
	escalar mxn BaseVehic`sufijo' = `sBaseVehi'
	escalar mxn BaseAlcTaba`sufijo' = `sBaseAlcTab'
	escalar mxn IngBruto`sufijo' = `singbrutotot'
	escalar personas Pob`sufijo' = `spob'

	** 3.2 Tasas efectivas micro/micro (pct) **
	escalar pct ISRASTE`sufijo' = `sISRAS'/`sing_subor'*100
	escalar pct CUOTASTE`sufijo' = `sCUOTAS'/`sing_subor'*100
	escalar pct ISRPFTE`sufijo' = `sISRPF'/`sBaseMixL'*100
	escalar pct ISRPMTE`sufijo' = `sISRPM'/`sing_bruto_tpm'*100
	escalar pct OTROSKTE`sufijo' = `sOTROSK'/`sing_bruto_tpm'*100
	escalar pct IVATE`sufijo' = `sIVA'/`sBaseCons'*100
	escalar pct IMPORTTE`sufijo' = `sIMPORT'/`sBaseCons'*100
	escalar pct ISANTE`sufijo' = `sISAN'/`sBaseVehi'*100
	escalar pct IEPSNPTE`sufijo' = `sIEPSNP'/`sBaseAlcTab'*100
	escalar pct YlImpTE`sufijo' = (`sISRAS'+`sISRPF'+`sCUOTAS')/(`sing_subor'+`sBaseMixL')*100
	escalar pct ingconsumoTE`sufijo' = (`sIVA'+`sIEPSNP'+`sIEPSP'+`sISAN'+`sIMPORT')/`sBaseCons'*100
	* IEPSP: su denominador oficial (ConsPriv21) no tiene contraparte micro.
	* Se declara (razón: cobertura); el numerador sí entra a ingconsumoTE.

	** 3.3 Validación vs TE oficial macro/macro (si los escalares están vivos) **
	local telist "ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP YlImp ingconsumo"
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
	noisily di in g "  Salarios / ISR asalariados" ///
		_col(34) %10.0fc in y `sing_subor'/1e9 _col(48) %10.0fc in y `sISRAS'/1e9 ///
		_col(62) %8.3fc in y scalar(ISRASTE`sufijo')
	noisily di in g "  Salarios / Cuotas IMSS" ///
		_col(34) %10.0fc in y `sing_subor'/1e9 _col(48) %10.0fc in y `sCUOTAS'/1e9 ///
		_col(62) %8.3fc in y scalar(CUOTASTE`sufijo')
	noisily di in g "  Mixto (laboral) / ISR PF" ///
		_col(34) %10.0fc in y `sBaseMixL'/1e9 _col(48) %10.0fc in y `sISRPF'/1e9 ///
		_col(62) %8.3fc in y scalar(ISRPFTE`sufijo')
	noisily di in g "  Capital privado / ISR PM" ///
		_col(34) %10.0fc in y `sing_bruto_tpm'/1e9 _col(48) %10.0fc in y `sISRPM'/1e9 ///
		_col(62) %8.3fc in y scalar(ISRPMTE`sufijo')
	noisily di in g "  Capital privado / Otros K" ///
		_col(34) %10.0fc in y `sing_bruto_tpm'/1e9 _col(48) %10.0fc in y `sOTROSK'/1e9 ///
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
	noisily di in g "  Alcohol y tabaco / IEPS NP" ///
		_col(34) %10.0fc in y `sBaseAlcTab'/1e9 _col(48) %10.0fc in y `sIEPSNP'/1e9 ///
		_col(62) %8.3fc in y scalar(IEPSNPTE`sufijo')
	noisily di in g _dup(71) "-"
	noisily di in g "{bf:  Laborales (ISRAS+ISRPF+Cuotas)" ///
		_col(34) %10.0fc in y (`sing_subor'+`sBaseMixL')/1e9 ///
		_col(48) %10.0fc in y (`sISRAS'+`sISRPF'+`sCUOTAS')/1e9 ///
		_col(62) %8.3fc in y scalar(YlImpTE`sufijo') "}"
	noisily di in g "{bf:  Consumo (IVA+IEPS+ISAN+Imp)" ///
		_col(34) %10.0fc in y `sBaseCons'/1e9 ///
		_col(48) %10.0fc in y (`sIVA'+`sIEPSNP'+`sIEPSP'+`sISAN'+`sIMPORT')/1e9 ///
		_col(62) %8.3fc in y scalar(ingconsumoTE`sufijo') "}"

	** 4. Incidencia por decil — misma rutina nacional (INCI.ado) **
	if "`entidad'" != "" & "`noincidencia'" == "" {

		** 4.1 Cargas agregadas (mismas familias que SIM.do §7.1) **
		egen double AlTrabajo = rsum(ISRAS ISRPF CUOTAS)
		egen double AlCapital = rsum(ISRPM OTROSK)
		egen double AlConsumo = rsum(IVA IEPSNP IEPSP ISAN IMPORT)
		egen double ImpTotal = rsum(AlTrabajo AlCapital AlConsumo)

		** 4.2 Deciles estatales — mismos criterios que Households.do (líneas 2591-2598) **
		tempvar toti dechog decpc
		egen `toti' = count(edad), by(folioviv foliohog)
		egen double `dechog' = sum(ingbrutotot), by(folioviv foliohog)
		g double `decpc' = `dechog'/`toti'
		xtile decilE = `decpc' [pw=factor/`toti'] if muestra == 1, n(10)

		** 4.3 Solo residentes de la(s) entidad(es): numerador Y denominador **
		preserve
		keep if muestra == 1
		g double ingresoINCI = ingbrutotot
		label var ingresoINCI "Ingreso bruto total"

		foreach juego in A B {
			if "`juego'" == "A" {
				local decvar "decil"
				local suf2 "`sufijo'"
				local jlab "deciles nacionales"
			}
			else {
				local decvar "decilE"
				local suf2 "`sufijo'e"
				local jlab "deciles estatales"
			}
			noisily di _newline in g "{bf:  Incidencia (`jlab') — sufijo de escalar: " in y "`suf2'" in g "}"

			foreach v in AlTrabajo AlCapital AlConsumo ImpTotal {
				tempfile pinci
				capture postclose INCI
				postfile INCI dec double(xhogar distribucion incidencia hogares) ///
					using `pinci', replace
				INCI `v' [fw=factor], folio(folioviv foliohog) n(`decvar') relativo(ingresoINCI) post
				postclose INCI
				_TEMicroIncExport `"`pinci'"' `v' `suf2'
			}
		}
		restore
	}
	noisily di _newline in g "  TasasEfectivasMicro: listo (sufijo " in y "`sufijo'" in g ")."
}
end


* Exporta el postfile de INCI a escalares por decil (espejo de Simulador.ado
* §4.1-4.3, con bootstrap=1 el promedio ES el valor): mxnpc <var><suf><dec>,
* pct dis<var><suf><dec>, pct inc<var><suf><dec>. dec 11 = "Tot".
program define _TEMicroIncExport
	args pfile var suf
	preserve
	use `"`pfile'"', clear
	forvalues k = 1/`=_N' {
		local d = dec[`k']
		local lab : word `d' of I II III IV V VI VII VIII IX X Tot
		escalar mxnpc `var'`suf'`lab' = xhogar[`k']
		escalar pct dis`var'`suf'`lab' = distribucion[`k']
		escalar pct inc`var'`suf'`lab' = incidencia[`k']
		noisily di in g "    `lab'" _col(12) in g "por hogar: " in y %12.0fc xhogar[`k'] ///
			_col(38) in g "dist: " in y %6.1fc distribucion[`k'] "%" ///
			_col(55) in g "incid: " in y %6.1fc incidencia[`k'] "%"
	}
	restore
end
