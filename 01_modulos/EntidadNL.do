*! EntidadNL.do  v1.1.0 — driver F1-bis: TE micro/micro, incidencia y conciliación para Nuevo León (entidad 19)
*
* QUÉ ES ESTO (contrato F1 + F1-bis, DIAGNOSTICO_NL.md):
*   (1) TE-NL micro/micro vía TasasEfectivasMicro.ado con bases COMPLETAS
*       (la base micro reconstruye el 100% del PIB; ningún componente se
*       declara faltante — Anexo F1-bis A). Validación nacional micro/micro
*       vs. TE oficial macro/macro (Dif*TEnac) con causas identificadas.
*   (2) INCIDENCIA por decil sobre users/$id/aportaciones.dta — el OBJETO DEL
*       PIPELINE (SIM.do §7.1): AlTrabajo = ISRPF_Sim+ISRAS_Sim+CUOTAS_Sim;
*       AlCapital = ISRPM_Sim+OTROSK; AlConsumo = IVA_Sim+IEPSNP_Sim+IEPSP_Sim
*       +ISAN_Sim+IMPORT_Sim; total = ImpuestosAportaciones (SIN OTROSK ni FMP,
*       SIM.do:440). Misma rutina nacional: INCI.ado, espejo exacto de
*       Simulador.ado §1.3.3 (deflactor, if var!=0, relativo=ingbrutotot,
*       fw=factor, hogar->decil->ratio).
*   (3) COMPUERTA D.1: sin entidad(), la rutina debe reproducir los bloques
*       INCD/INCD2/INCD3 de output.txt (AportacionesNetas) al decimal. Si no
*       pasa, el driver ABORTA: ningún número de incidencia NL es válido.
*   (4) Escalares SIN guion bajo (sufijos nac/nl/nle); output.txt INTACTO:
*       toda salida NL va por escalar -> scalarjson.
*   (5) ANEXOS (F1-bis-2): (a) diagnóstico del decil I — descomposición de
*       AlConsumo por impuesto, estructura de la canasta (gravado/exento/tasa
*       cero/bienes con IEPS) y robustez con gasto corriente monetario como
*       denominador (familias *G y razonGY). El diferencial del decil I
*       combina DENOMINADOR (selección: ingreso corriente vs proxy de ingreso
*       permanente) y NUMERADOR (canasta más gravada); la construcción del
*       IVA es la misma. (b) banda de sensibilidad del ISR PM = [S1, S3]:
*       S1 = prorrateo a ingreso de capital sin cut-off (cota inferior),
*       S2 = traslación 50% capital / 25% trabajo / 25% consumo, S3 = pago
*       esperado p(probit) x impuesto potencial (cota superior), S0 = método
*       vigente (ranking probit + cut-off LIF), DENTRO de la banda. Todos son
*       estimadores válidos reescalados al mismo total. Sufijos nlS1/nlS2/nlS3
*       (y nleS1/nleS2/nleS3 en deciles estatales); nl sigue siendo S0.
*   NOTA de suma en tablas de incidencia: AlCapital (pipeline) incluye OTROSK
*   y el Total (ImpuestosAportaciones) lo excluye; se reporta la columna
*   OTROSK por separado: AlTrabajo+AlCapital+AlConsumo-OTROSK = Total.
*
* USO (tras correr SIM.do en la MISMA sesión, con escalares y bases vivas):
*   do "`c(sysdir_site)'/01_modulos/EntidadNL.do"
*
* SALIDA: users/$id/nodos/statajson_entidad-nl.json (generada, gitignored).
* OJO: destruye los datos en memoria (igual que el tramo 7 de SIM.do).

*** 0 GUARDAS (estado del motor vivo; sin él no hay validación posible) ***
local site `"`c(sysdir_site)'"'
foreach s in anioPE aniovp anioenigh pibY ISRASTE IVATE AportacionesNetasI incAportacionesNetasNac {
	capture confirm scalar `s'
	if _rc {
		di as err "EntidadNL: falta el scalar `s'. Corre SIM.do primero (misma sesión) y reintenta."
		exit 198
	}
}
capture confirm file `"`site'/users/$id/aportaciones.dta"'
if _rc {
	di as err "EntidadNL: falta users/$id/aportaciones.dta (la genera SIM.do §7)."
	exit 198
}
local anio = scalar(anioPE)
local pibY = scalar(pibY)

* Procedencia: sin log activo no hay exportación válida (scalarjson declara
* procedencia.log desde `log query`). En modo batch SIM.do cierra los logs
* (capture log close _all); el driver garantiza uno propio. *
capture quietly log query
if `"`r(filename)'"' == "" | `"`r(filename)'"' == "." {
	capture mkdir `"`site'/users/$id/nodos"'
	quietly log using `"`site'/users/$id/nodos/entidad-nl.log"', replace text
}
capture quietly log query
if `"`r(filename)'"' == "" | `"`r(filename)'"' == "." {
	di as err "EntidadNL: no hay log activo ni pudo abrirse uno; sin procedencia no hay exportación válida."
	exit 459
}

noisily di _newline(2) in g _dup(20) "." "{bf:   ENTIDAD 19 — NUEVO LEÓN " in y `anio' in g "   }" _dup(20) "."

*** 1 TE MICRO/MICRO ***
* 1.1 Espejo nacional (validación vs macro/macro; enmienda 1) *
noisily TasasEfectivasMicro, anio(`anio') sufijo(nac)

* 1.2 Nuevo León *
noisily TasasEfectivasMicro, anio(`anio') entidad(19) sufijo(nl)

*** 2 INCIDENCIA — espejo exacto de Simulador.ado §1.3.3 + INCI.ado ***

** 2.0 Subrutinas **
* Exporta el postfile de INCI a escalares por decil (espejo de Simulador.ado
* §4.1-4.3; con bootstrap=1 el promedio ES el valor): mxnpc <var><suf><dec>,
* pct dis<var><suf><dec>, pct inc<var><suf><dec>. dec 11 = "Tot". Vive en el
* driver (no como subrutina de otro .ado: Stata puede descargar subprogramas
* auto-cargados y no los re-encuentra por nombre de archivo distinto). *
* NOTA de nombres: la familia de escalares del total es "ImpAport" (alias de
* la variable ImpuestosAportaciones del pipeline): el registro viaja con
* prefijos t_/f_ dentro de scalarjson y los locals de Stata topan en 31
* caracteres; el nombre completo los rebasaba. *
capture program drop _ENLexp
program define _ENLexp
	args pfile var suf
	preserve
	quietly use `"`pfile'"', clear
	forvalues k = 1/`=_N' {
		local d = dec[`k']
		local lab : word `d' of I II III IV V VI VII VIII IX X Tot
		escalar mxnpc `var'`suf'`lab' = xhogar[`k']
		escalar pct dis`var'`suf'`lab' = distribucion[`k']
		escalar pct inc`var'`suf'`lab' = incidencia[`k']
	}
	restore
end

* Corre INCI (la rutina nacional) sobre la variable v con el juego de deciles
* decvar y exporta escalares <v><suf><dec>. Espejo de Simulador.ado:
* deflactor aplicado a la variable y al ingreso, if v!=0, fw=factor. *
capture program drop _ENLinci
program define _ENLinci
	args v fam decvar suf vdef ydef yvar
	if "`yvar'" == "" {
		local yvar "ingbrutotot"
		local ylab "Ingreso bruto total"
	}
	else {
		local ylab "Gasto corriente monetario"
	}
	tempvar v2 ing2
	quietly g double `v2' = `v'/`vdef'
	quietly g double `ing2' = `yvar'/`ydef'
	label var `ing2' "`ylab'"
	tempfile pf
	capture postclose INCI
	postfile INCI dec double(xhogar distribucion incidencia hogares) using `pf', replace
	quietly INCI `v2' if `v2' != 0 [fw=factor], folio(folioviv foliohog) n(`decvar') relativo(`ing2') post
	postclose INCI
	if "`suf'" != "" {
		_ENLexp `"`pf'"' `fam' `suf'
	}
	else {
		* Compuerta D.1: comparar contra los escalares que generaron INCD* *
		preserve
		quietly use `"`pf'"', clear
		local fallas = 0
		noisily di _newline in g "{bf:  Compuerta D.1 — `v' vs escalares del pipeline (INCD/INCD2/INCD3)}"
		noisily di in g "  Decil" _col(12) %14s "xhogar" _col(30) %14s "pipeline" ///
			_col(48) %10s "inc" _col(60) %10s "pipeline"
		forvalues k = 1/`=_N' {
			local d = dec[`k']
			local lab : word `d' of I II III IV V VI VII VIII IX X Nac
			local okx = reldif(xhogar[`k'], scalar(`v'`lab')) < 1e-6
			local okd = reldif(distribucion[`k'], scalar(dis`v'`lab')) < 1e-6
			local oki = reldif(incidencia[`k'], scalar(inc`v'`lab')) < 1e-6
			if !(`okx' & `okd' & `oki') local ++fallas
			noisily di in g "  `lab'" ///
				_col(12) in y %14.2fc xhogar[`k'] _col(30) in y %14.2fc scalar(`v'`lab') ///
				_col(48) in y %10.4fc incidencia[`k'] _col(60) in y %10.4fc scalar(inc`v'`lab') ///
				_col(72) in g cond(`okx' & `okd' & `oki', "ok", "FALLA")
			* (la comparación usa el nombre de la VARIABLE del pipeline `v')
		}
		restore
		if `fallas' > 0 {
			di as err "EntidadNL: la compuerta D.1 FALLÓ en `fallas' filas. Ningún número de incidencia es válido."
			exit 459
		}
		noisily di in g "  {bf:Compuerta D.1: " in y "PASÓ" in g " (xhogar, distribución e incidencia idénticos al pipeline).}"
	}
	capture drop `v2' `ing2'
end

* Razón gasto corriente monetario / ingreso bruto por decil (anexo 1a):
* escalares pct razonGY<suf><dec>. *
capture program drop _ENLrazon
program define _ENLrazon
	args decvar suf
	noisily di _newline in g "{bf:  Razón gasto/ingreso por decil (sufijo `suf')}"
	forvalues d = 1/11 {
		local lab : word `d' of I II III IV V VI VII VIII IX X Tot
		if `d' < 11 local iff "if `decvar' == `d'"
		else local iff ""
		quietly tabstat GastoBase ingbrutotot [aw=factor] `iff', stat(sum) save
		escalar pct razonGY`suf'`lab' = r(StatTotal)[1,1]/r(StatTotal)[1,2]*100
		noisily di in g "  `lab'" _col(12) in y %8.1fc scalar(razonGY`suf'`lab')
	}
end

* Composición del decil I nacional (anexo 1b): n muestral de hogares,
* proporción con ingreso cero o < 25% de su gasto, tamaño del hogar y edad
* del jefe (numren 01). Se corre sobre el universo vigente en memoria. *
capture program drop _ENLdecI
program define _ENLdecI
	args suf
	quietly summ edad [aw=factor] if decil == 1 & numren == "01"
	local edadjefe = r(mean)
	preserve
	quietly {
		keep if decil == 1
		tempvar ing gto tam
		egen double `ing' = sum(ingbrutotot), by(folioviv foliohog)
		egen double `gto' = sum(GastoBase), by(folioviv foliohog)
		egen `tam' = count(edad), by(folioviv foliohog)
		bysort folioviv foliohog: keep if _n == 1
		count
		local n = r(N)
		tempvar bajo
		g byte `bajo' = (`ing' == 0) | (`ing' < 0.25*`gto')
		summ `bajo' [aw=factor]
		local pbajo = r(mean)*100
		summ `tam' [aw=factor]
		local tamh = r(mean)
	}
	restore
	escalar personas nHogDecI`suf' = `n'
	escalar pct PctIngBajoDecI`suf' = `pbajo'
	* promedios de integrantes y edad: no caben en el catálogo estándar *
	escalar custom(%6.2f) TamHogDecI`suf' = `tamh'
	escalar custom(%6.1f) EdadJefeDecI`suf' = `edadjefe'
	noisily di in g "  Decil I (`suf'): n hogares muestra " in y `n' ///
		in g " · ingreso 0 o <25% del gasto " in y %5.1fc `pbajo' "%" ///
		in g " · integrantes " in y %5.2fc `tamh' ///
		in g " · edad jefe " in y %5.1fc `edadjefe'
end

* Estructura de la canasta del decil I (anexo 1b): participación del gasto en
* gravado / exento / tasa cero (regímenes leídos de la matriz IVAT, en el
* MISMO orden alfabético de levelsof que usan Expenditure.do §5.2 e
* IVA_Mod.do) y en bienes con IEPS. Escalares pct pct<Grupo>DecI<suf>. *
capture program drop _ENLcanasta
program define _ENLcanasta
	args decvar suf
	local cats `"Alimentos Alquiler CanastaBas Educación FueraHog Mascotas Medicinas Mujer Otros TransporteFor TransporteLoc"'
	local vcero ""
	local vexen ""
	local vgrav ""
	local j = 2
	foreach k of local cats {
		if IVAT[`j',1] == 1 local vcero "`vcero' gas_pc_`k'"
		else if IVAT[`j',1] == 2 local vexen "`vexen' gas_pc_`k'"
		else local vgrav "`vgrav' gas_pc_`k'"
		local ++j
	}
	tempvar cero exen grav tot ieps
	quietly {
		egen double `cero' = rsum(`vcero')
		egen double `exen' = rsum(`vexen')
		egen double `grav' = rsum(`vgrav')
		egen double `tot' = rsum(`cero' `exen' `grav')
		egen double `ieps' = rsum(gas_pc_Cervezas gas_pc_Alcohol_20 gas_pc_Alcohol_20_ ///
			gas_pc_Tabaco gas_pc_AltoContCal gas_pc_BebidasEner gas_pc_BebidasSabor ///
			gas_pc_Combustibles gas_pc_Gasolinas gas_pc_Telecom)
		tabstat `grav' `exen' `cero' `ieps' `tot' [aw=factor] if `decvar' == 1, stat(sum) save
	}
	escalar pct pctGravDecI`suf' = r(StatTotal)[1,1]/r(StatTotal)[1,5]*100
	escalar pct pctExenDecI`suf' = r(StatTotal)[1,2]/r(StatTotal)[1,5]*100
	escalar pct pctCeroDecI`suf' = r(StatTotal)[1,3]/r(StatTotal)[1,5]*100
	escalar pct pctIEPSDecI`suf' = r(StatTotal)[1,4]/r(StatTotal)[1,5]*100
	noisily di in g "  Canasta decil I (`suf'): gravado " in y %5.1fc scalar(pctGravDecI`suf') "%" ///
		in g " · exento " in y %5.1fc scalar(pctExenDecI`suf') "%" ///
		in g " · tasa cero " in y %5.1fc scalar(pctCeroDecI`suf') "%" ///
		in g " · bienes con IEPS " in y %5.1fc scalar(pctIEPSDecI`suf') "%"
end

** 2.1 Cargar el objeto del pipeline y espejar el deflactor de Simulador.ado **
use `"`site'/users/$id/aportaciones.dta"', clear
preserve
quietly PIBDeflactor, anio(`=scalar(aniovp)') nographs nooutput
local deflator = 1
forvalues k = 1(1)`=_N' {
	if anio[`k'] == `anio' {
		local deflator = deflator[`k']
		continue, break
	}
}
restore
noisily di _newline in g "  Deflactor (aniope `anio' | aniovp `=scalar(aniovp)'): " in y %8.6f `deflator'

** 2.1b Ingredientes de los anexos (dataset completo, ANTES del corte NL) **
* Bases micro para robustez y escenarios; mismos canales del pipeline.
* ing_subor / ing_bruto_tpm / exen_tpm ya viajan en aportaciones.dta con los
* valores de perfiles<anio>.dta (verificado: sumas idénticas). *
merge 1:1 folioviv foliohog numren using `"`site'/master/`=scalar(anioenigh)'/households.dta"', ///
	nogen keep(master match) keepusing(gastoanualTOT prob_moral gasto_anualDepreciacion)
* Canasta por categoría de régimen IVA y bienes con IEPS (anexo 1b) *
merge 1:1 folioviv foliohog numren using `"`site'/master/`=scalar(anioenigh)'/consumption_categ_iva_pc.dta"', ///
	nogen keep(master match) keepusing(gas_pc_*)
merge 1:1 folioviv foliohog numren using `"`site'/master/`=scalar(anioenigh)'/consumption_categ_ieps_pc.dta"', ///
	nogen keep(master match) keepusing(gas_pc_*)

* Gasto corriente monetario a escala del año de política (ConHog de SCN,
* vivo desde TasasEfectivasMicro; mismo canal que PerfilesSim.do:184) *
Distribucion GastoBase, relativo(gastoanualTOT) macro(`=scalar(ConHog)')

* Escenarios ISR PM — todos reescalados al MISMO total nacional del pipeline
* (Σ ISRPM_Sim), para que solo cambie la INCIDENCIA, no la recaudación:
*   S1: prorrateo a ingreso de capital privado, sin cut-off por probit
*   S2: traslación 50% capital / 25% trabajo (ing_subor) / 25% consumo (GastoBase)
*   S3: pago esperado = p(probit, prob_moral) x impuesto potencial
*       [(tpm + depreciación - exenciones) x PM[1,1]%, espejo de Households.do:2301] *
quietly tabstat ISRPM_Sim [aw=factor], stat(sum) save
local MPM = r(StatTotal)[1,1]
Distribucion ISRPMS1, relativo(ing_bruto_tpm) macro(`MPM')
tempvar s2k s2l s2c
Distribucion `s2k', relativo(ing_bruto_tpm) macro(`=0.50*`MPM'')
Distribucion `s2l', relativo(ing_subor) macro(`=0.25*`MPM'')
Distribucion `s2c', relativo(GastoBase) macro(`=0.25*`MPM'')
egen double ISRPMS2 = rsum(`s2k' `s2l' `s2c')
tempvar pot relS3
g double `pot' = max(0, (ing_bruto_tpm + gasto_anualDepreciacion - exen_tpm)*PM[1,1]/100)
g double `relS3' = prob_moral*`pot'
quietly replace `relS3' = 0 if `relS3' == .
Distribucion ISRPMS3, relativo(`relS3') macro(`MPM')

* Totales por escenario (sustituyen SOLO el componente ISR PM del pipeline) *
forvalues i = 1/3 {
	g double AlCapS`i' = AlCapital - ISRPM_Sim + ISRPMS`i'
	g double TotS`i' = ImpuestosAportaciones - ISRPM_Sim + ISRPMS`i'
}

** 2.2 COMPUERTA D.1 (nacional, AportacionesNetas — la variable ya viene
**     deflactada del pipeline [Simulador.ado:68 + use original], por eso el
**     espejo usa deflactor 1 sobre ella y el verdadero sobre el ingreso) **
_ENLinci AportacionesNetas AportacionesNetas decil "" 1 `deflator'

** 2.3 Incidencia nacional de las cargas del pipeline (sufijo nac) **
noisily di _newline in g "{bf:  Incidencia nacional (deciles nacionales) — sufijo nac}"
foreach par in "AlTrabajo AlTrabajo" "AlCapital AlCapital" "AlConsumo AlConsumo" "ImpuestosAportaciones ImpAport" ///
	"OTROSK OTROSK" "IVA_Sim IVA" "IEPSNP_Sim IEPSNP" "IEPSP_Sim IEPSP" "ISAN_Sim ISAN" "IMPORT_Sim IMPORT" {
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decil nac `deflator' `deflator'
}

** 2.3b Anexos nacionales: razón gasto/ingreso, decil I (composición y
**      canasta) y robustez con denominador de gasto **
_ENLrazon decil nac
_ENLdecI nac
_ENLcanasta decil nac
noisily di _newline in g "{bf:  Robustez nacional: incidencia con gasto como denominador (sufijo nac, familias *G)}"
foreach par in "AlConsumo AlConsumoG" "ImpuestosAportaciones ImpAportG" {
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decil nac `deflator' `deflator' GastoBase
}

** 2.4 Nuevo León: solo residentes (numerador Y denominador) **
g entidad = real(substr(folioviv,1,2))
keep if entidad == 19

* Deciles estatales — mismos criterios que Households.do:2591-2598 *
tempvar toti dechog decpc
egen `toti' = count(edad), by(folioviv foliohog)
egen double `dechog' = sum(ingbrutotot), by(folioviv foliohog)
g double `decpc' = `dechog'/`toti'
xtile decilE = `decpc' [pw=factor/`toti'], n(10)

noisily di _newline in g "{bf:  Incidencia NL (deciles nacionales nl / estatales nle)}"
foreach par in "AlTrabajo AlTrabajo" "AlCapital AlCapital" "AlConsumo AlConsumo" "ImpuestosAportaciones ImpAport" ///
	"OTROSK OTROSK" "IVA_Sim IVA" "IEPSNP_Sim IEPSNP" "IEPSP_Sim IEPSP" "ISAN_Sim ISAN" "IMPORT_Sim IMPORT" {
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decil nl `deflator' `deflator'
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decilE nle `deflator' `deflator'
}

** 2.5 Anexo 1 NL: razón gasto/ingreso, decil I (composición y canasta) y robustez *G **
_ENLrazon decil nl
_ENLrazon decilE nle
_ENLdecI nl
_ENLcanasta decil nl
_ENLcanasta decilE nle
noisily di _newline in g "{bf:  Robustez NL: incidencia con gasto como denominador (familias *G)}"
foreach par in "AlConsumo AlConsumoG" "ImpuestosAportaciones ImpAportG" {
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decil nl `deflator' `deflator' GastoBase
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decilE nle `deflator' `deflator' GastoBase
}

** 2.6 Anexo 2 NL: banda de sensibilidad del ISR PM (S1/S2/S3; nl = S0) **
noisily di _newline in g "{bf:  Escenarios ISR PM (incidencia nlS*/nleS*)}"
forvalues i = 1/3 {
	_ENLinci AlCapS`i' AlCapital decil nlS`i' `deflator' `deflator'
	_ENLinci AlCapS`i' AlCapital decilE nleS`i' `deflator' `deflator'
	_ENLinci TotS`i' ImpAport decil nlS`i' `deflator' `deflator'
	_ENLinci TotS`i' ImpAport decilE nleS`i' `deflator' `deflator'
}

* TE y participación de NL por escenario (denominador: BaseKPrivnl, sin cambio) *
quietly tabstat ISRPMS1 ISRPMS2 ISRPMS3 ISRPM_Sim [aw=factor], stat(sum) save
tempname RNL
matrix `RNL' = r(StatTotal)
forvalues i = 1/3 {
	escalar mxn RecISRPMnlS`i' = `RNL'[1,`i']
	escalar pct ISRPMTEnlS`i' = `RNL'[1,`i']/scalar(BaseKPrivnl)*100
	escalar pct PartISRPMnlS`i' = `RNL'[1,`i']/`MPM'*100
}
escalar pct PartISRPMnl = `RNL'[1,4]/`MPM'*100

*** 3 CONCILIACIÓN POR BASE (brechas DECLARADAS, nunca forzadas) ***
* Participaciones de NL en el agregado ENIGH ajustado (micro, post-CN) *
escalar pct PartSalENIGHnl = scalar(BaseSalnl)/scalar(BaseSalnac)*100
escalar pct PartMixENIGHnl = scalar(BaseMixnl)/scalar(BaseMixnac)*100
escalar pct PartKPrivENIGHnl = scalar(BaseKPrivnl)/scalar(BaseKPrivnac)*100
escalar pct PartConsENIGHnl = scalar(BaseConsunl)/scalar(BaseConsunac)*100
escalar pct PartPobnl = scalar(Pobnl)/scalar(Pobnac)*100
escalar pct PartRecTotalnl = scalar(RecTotalnl)/scalar(RecTotalnac)*100

* Proxies estatales — parámetros con fuente y corte declarados (misma
* convención que los parámetros de SIM.do §4.1) *
* Masa salarial (ENOE): NL = 24,962.12 mdp y nacional = 385,672.30 mdp
*   mensuales a precios del 1T2020, tercer trimestre de 2024. Fuentes:
*   INEGI, Pobreza Laboral, boletín NL 3T2025 (serie 3T2024) y CONEVAL,
*   "Indicadores de pobreza laboral nacional y estatal", dic. 2024 (ENOE/ENOE-N).
escalar pct ProxyMasaSalENOEnl = 24962.12/385672.30*100
* PIBE: NL = 2,502,823 mdp y nacional = 31,855,566 mdp corrientes, 2023
*   (preliminar). Fuente: INEGI, PIBE 2023, boletines nacional y NL (dic. 2024).
escalar pct ProxyPIBEnl = 2502823/31855566*100

* Brechas (participación ENIGH-NL menos proxy, en puntos porcentuales).
* Razón declarada (lista cerrada del proyecto) — viaja como texto en el JSON:
*   salarios vs ENOE:   cobertura, deflactor, momento contable, fuente y corte
*   mixto/capital vs PIBE: clasificación, denominador, momento contable
*   consumo vs PIBE:    cobertura, denominador, momento contable
escalar pct BrechaSalENOEnl = scalar(PartSalENIGHnl) - scalar(ProxyMasaSalENOEnl)
escalar pct BrechaMixPIBEnl = scalar(PartMixENIGHnl) - scalar(ProxyPIBEnl)
escalar pct BrechaKPrivPIBEnl = scalar(PartKPrivENIGHnl) - scalar(ProxyPIBEnl)
escalar pct BrechaConsPIBEnl = scalar(PartConsENIGHnl) - scalar(ProxyPIBEnl)

*** 4 TABLAS RESUMEN (display; los números viven en escalares) ***
noisily di _newline in g "{bf:  Tasa efectiva (%)" ///
	_col(30) %9s "Oficial" _col(42) %9s "Micro nac" _col(54) %9s "Micro NL" _col(66) %8s "NL-nac" "}"
noisily di in g _dup(74) "-"
foreach te in ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP IEPSP YlImp ingconsumo {
	local of = "."
	capture local of : di %9.3fc scalar(`te'TE)
	local rel = "."
	capture local rel : di %8.3fc scalar(Rel`te'TEnl)
	noisily di in g "  `te'" ///
		_col(30) in y %9s "`of'" ///
		_col(42) in y %9.3fc scalar(`te'TEnac) ///
		_col(54) in y %9.3fc scalar(`te'TEnl) ///
		_col(66) in y %8s "`rel'"
}
noisily di _newline in g "{bf:  Conciliación (participación de NL, %)}"
noisily di in g "  Salarios ENIGH-CN: " in y %6.2fc scalar(PartSalENIGHnl) ///
	in g "  vs masa salarial ENOE 3T2024: " in y %6.2fc scalar(ProxyMasaSalENOEnl) ///
	in g "  brecha: " in y %6.2fc scalar(BrechaSalENOEnl) in g " pp (cobertura, deflactor, momento, fuente y corte)"
noisily di in g "  Mixto ENIGH-CN:    " in y %6.2fc scalar(PartMixENIGHnl) ///
	in g "  vs PIBE 2023: " in y %6.2fc scalar(ProxyPIBEnl) ///
	in g "  brecha: " in y %6.2fc scalar(BrechaMixPIBEnl) in g " pp (clasificación, denominador, momento)"
noisily di in g "  Capital ENIGH-CN:  " in y %6.2fc scalar(PartKPrivENIGHnl) ///
	in g "  vs PIBE 2023: " in y %6.2fc scalar(ProxyPIBEnl) ///
	in g "  brecha: " in y %6.2fc scalar(BrechaKPrivPIBEnl) in g " pp (clasificación, denominador, momento)"
noisily di in g "  Consumo ENIGH-CN:  " in y %6.2fc scalar(PartConsENIGHnl) ///
	in g "  vs PIBE 2023: " in y %6.2fc scalar(ProxyPIBEnl) ///
	in g "  brecha: " in y %6.2fc scalar(BrechaConsPIBEnl) in g " pp (cobertura, denominador, momento)"

* Incidencia (display desde los escalares ya registrados) *
foreach s in nac nl nle {
	if "`s'" == "nac" local jlab "nacional, deciles nacionales"
	if "`s'" == "nl"  local jlab "NL, deciles nacionales"
	if "`s'" == "nle" local jlab "NL, deciles estatales"
	noisily di _newline in g "{bf:  Incidencia (`jlab') — % del ingreso bruto del decil}"
	noisily di in g "  Decil" _col(12) %10s "AlTrabajo" _col(26) %10s "AlCapital" ///
		_col(40) %10s "AlConsumo" _col(52) %8s "OTROSK" _col(64) %12s "Total (SIM)"
	noisily di in g _dup(76) "-"
	foreach d in I II III IV V VI VII VIII IX X Tot {
		noisily di in g "  `d'" ///
			_col(12) in y %10.1fc scalar(incAlTrabajo`s'`d') ///
			_col(26) in y %10.1fc scalar(incAlCapital`s'`d') ///
			_col(40) in y %10.1fc scalar(incAlConsumo`s'`d') ///
			_col(52) in y %8.1fc scalar(incOTROSK`s'`d') ///
			_col(64) in y %12.1fc scalar(incImpAport`s'`d')
	}
	noisily di in g "  Nota: AlCapital incluye OTROSK y el Total lo excluye:" ///
		" AlTrabajo+AlCapital+AlConsumo-OTROSK = Total."
}

* Anexo 1b: descomposición de AlConsumo por impuesto en el decil I *
noisily di _newline in g "{bf:  Decil I — incidencia de AlConsumo por impuesto (% del ingreso del decil)}"
noisily di in g "  Juego" _col(12) %8s "IVA" _col(24) %8s "IEPS NP" _col(36) %8s "IEPS P" ///
	_col(48) %8s "ISAN" _col(60) %8s "Import" _col(70) %10s "AlConsumo"
foreach s in nac nl nle {
	noisily di in g "  `s'" ///
		_col(12) in y %8.1fc scalar(incIVA`s'I) ///
		_col(24) in y %8.1fc scalar(incIEPSNP`s'I) ///
		_col(36) in y %8.1fc scalar(incIEPSP`s'I) ///
		_col(48) in y %8.1fc scalar(incISAN`s'I) ///
		_col(60) in y %8.1fc scalar(incIMPORT`s'I) ///
		_col(70) in y %10.1fc scalar(incAlConsumo`s'I)
}

* Anexo 1b: estructura de la canasta del decil I *
noisily di _newline in g "{bf:  Decil I — estructura de la canasta (% del gasto clasificado IVA)}"
noisily di in g "  Juego" _col(12) %8s "Gravado" _col(24) %8s "Exento" ///
	_col(36) %10s "Tasa cero" _col(50) %12s "Bienes IEPS"
foreach s in nac nl nle {
	noisily di in g "  `s'" ///
		_col(12) in y %8.1fc scalar(pctGravDecI`s') ///
		_col(24) in y %8.1fc scalar(pctExenDecI`s') ///
		_col(36) in y %10.1fc scalar(pctCeroDecI`s') ///
		_col(50) in y %12.1fc scalar(pctIEPSDecI`s')
}

* Anexo 1c: robustez con gasto como denominador (AlConsumo y total, % del gasto) *
foreach s in nac nl nle {
	noisily di _newline in g "{bf:  Robustez `s' — incidencia sobre GASTO corriente monetario (razón: denominador)}"
	noisily di in g "  Decil" _col(12) %12s "AlConsumo/G" _col(28) %12s "Total/G" ///
		_col(44) %12s "razón G/Y"
	foreach d in I II III IV V VI VII VIII IX X Tot {
		noisily di in g "  `d'" ///
			_col(12) in y %12.1fc scalar(incAlConsumoG`s'`d') ///
			_col(28) in y %12.1fc scalar(incImpAportG`s'`d') ///
			_col(44) in y %12.1fc scalar(razonGY`s'`d')
	}
}
noisily di _newline in g "  {bf:Nota anexo 1:} la TE de consumo NL ≈ nacional (IVATEnl " ///
	in y %5.3fc scalar(IVATEnl) in g " vs IVATEnac " in y %5.3fc scalar(IVATEnac) ///
	in g "); el diferencial del decil I COMBINA denominador (selección: ingreso corriente" ///
	in g " vs proxy de ingreso permanente) y numerador (canasta más gravada); la construcción del IVA es la misma."

* Anexo 2: banda de sensibilidad ISR PM = [S1, S3]; S0 (método vigente) dentro *
noisily di _newline in g "{bf:  Banda de sensibilidad ISR PM — NL (todos los escenarios son estimadores válidos)}"
noisily di in g "  Escenario" _col(20) %10s "TE ISRPM" _col(34) %12s "Part NL (%)" ///
	_col(50) %14s "inc AlCap Tot" _col(66) %14s "inc Total Tot"
noisily di in g "  S1 prorrateo K (inf)" _col(20) in y %10.3fc scalar(ISRPMTEnlS1) ///
	_col(34) in y %12.2fc scalar(PartISRPMnlS1) ///
	_col(50) in y %14.1fc scalar(incAlCapitalnlS1Tot) ///
	_col(66) in y %14.1fc scalar(incImpAportnlS1Tot)
noisily di in g "  S2 50K/25L/25C" _col(20) in y %10.3fc scalar(ISRPMTEnlS2) ///
	_col(34) in y %12.2fc scalar(PartISRPMnlS2) ///
	_col(50) in y %14.1fc scalar(incAlCapitalnlS2Tot) ///
	_col(66) in y %14.1fc scalar(incImpAportnlS2Tot)
noisily di in g "  S0 método vigente" _col(20) in y %10.3fc scalar(ISRPMTEnl) ///
	_col(34) in y %12.2fc scalar(PartISRPMnl) ///
	_col(50) in y %14.1fc scalar(incAlCapitalnlTot) ///
	_col(66) in y %14.1fc scalar(incImpAportnlTot)
noisily di in g "  S3 p×potencial (sup)" _col(20) in y %10.3fc scalar(ISRPMTEnlS3) ///
	_col(34) in y %12.2fc scalar(PartISRPMnlS3) ///
	_col(50) in y %14.1fc scalar(incAlCapitalnlS3Tot) ///
	_col(66) in y %14.1fc scalar(incImpAportnlS3Tot)
noisily di in g "  {bf:Banda de incidencia total NL [S1, S3]: [" ///
	in y %5.1fc scalar(incImpAportnlS1Tot) in g ", " ///
	in y %5.1fc scalar(incImpAportnlS3Tot) in g "] % del ingreso; S0 (" ///
	in y %5.1fc scalar(incImpAportnlTot) in g ") dentro de la banda.}"

*** 5 EXPORTACIÓN — scalarjson (canal único de salida numérica NL) ***

** 5.1 Serie canónica (un año: el de la política) **
preserve
quietly {
	clear
	set obs 1
	g int anio = `anio'
	g double saldo_nominal = scalar(RecTotalnl)
	g double poblacion = scalar(Pobnl)
	g double indice_precios = `deflator'
	g double saldo_real = saldo_nominal/indice_precios
	g double saldo_pc_nominal = saldo_nominal/poblacion
	g double saldo_pc_real = saldo_real/poblacion
	g double saldo_pib = saldo_nominal/`pibY'*100
	tempfile serie
	save `serie'

	** 5.2 Metadatos (unidad/formato/divisor; criterios; fuentes; presentacion
	**     = notas de imputación y razones declaradas de brecha) **
	clear
	input str16 bloque str32 clave str244 texto
	"unidad"   "saldo_nominal"    "pesos corrientes"
	"unidad"   "saldo_real"       "pesos del año valor presente"
	"unidad"   "poblacion"        "personas"
	"unidad"   "indice_precios"   "índice (año VP = 1)"
	"unidad"   "saldo_pc_nominal" "pesos corrientes por persona"
	"unidad"   "saldo_pc_real"    "pesos del año VP por persona"
	"unidad"   "saldo_pib"        "% del PIB nacional"
	"formato"  "saldo_nominal"    "%12.1fc"
	"formato"  "saldo_real"       "%12.1fc"
	"formato"  "poblacion"        "%15.0fc"
	"formato"  "indice_precios"   "%6.3f"
	"formato"  "saldo_pc_nominal" "%10.0fc"
	"formato"  "saldo_pc_real"    "%10.0fc"
	"formato"  "saldo_pib"        "%7.3fc"
	"divisor"  "saldo_nominal"    "1000000"
	"divisor"  "saldo_real"       "1000000"
	"criterio" "cobertura_institucional" "impuestos federales simulados (ISR, cuotas IMSS, IVA, IEPS, ISAN, importaciones) de residentes de NL; sin recaudación local"
	"criterio" "momento_de_registro" "anual devengado ENIGH 2024 ajustada a CN, escalada a macros del año de política"
	"criterio" "neto_o_bruto"     "recaudación neta simulada; bases brutas ajustadas a CN (reconstruyen el 100% del PIB)"
	"criterio" "moneda_y_valuacion" "pesos corrientes del año de política"
	"criterio" "denominador_pib"  "PIB nacional (pibY, PIBDeflactor)"
	"criterio" "poblacion_denominador" "población expandida ENIGH de NL (factor reescalado nacional)"
	"criterio" "deflactor"        "deflactor del PIB (PIBDeflactor), año VP = 1"
	"fuente"   "saldo_nominal"    "Simulador CIEP: perfiles del año de política, corte entidad 19"
	"fuente"   "saldo_real"       "derivado: saldo_nominal / indice_precios"
	"fuente"   "poblacion"        "ENIGH 2024 (factor), corte entidad 19"
	"fuente"   "indice_precios"   "PIBDeflactor.ado"
	"fuente"   "saldo_pc_nominal" "derivado: saldo_nominal / poblacion"
	"fuente"   "saldo_pc_real"    "derivado: saldo_real / poblacion"
	"fuente"   "saldo_pib"        "derivado: saldo_nominal / pibY x 100"
	"presentacion" "den_salarios_nota" "base completa: ing_subor (RemSal+INPL) + cuotasTPF escaladas a SSEmpleadores+SSImputada (mapeo del propio pipeline, Households.do:1665)"
	"presentacion" "den_capital_nota" "base completa: ing_bruto_tpm + alquiler imputado (ExNOpHog) + mixto capital (MixKN) + INPK + FMP = CapIncImp - públicos"
	"presentacion" "den_iepsnp_nota" "juegos (Recre7132) imputado por participación con gas_pc_RecrT: la ENIGH 2024 no genera categoría IEPS de juegos separada"
	"presentacion" "den_iepsp_nota" "combustibles: gas_pc_Gasolinas+gas_pc_Combustibles escalados a ConsPriv21"
	"presentacion" "brechas_residuales_causa" "numerador con montos LIF (divSIM) vía Distribucion vs parámetros de SIM.do §4.1; públicos LIF vs parámetros *PIB en la base de capital"
	"presentacion" "brecha_salarios_razon" "cobertura (ENIGH-CN vs ENOE), deflactor (ENOE a pesos 1T2020; se compara por participaciones), momento contable (ENIGH 2024 vs ENOE 3T2024), fuente y corte"
	"presentacion" "brecha_mixto_razon" "clasificación (PIBE incluye gobierno y actividades no gravables), denominador (PIBE total vs base fiscal), momento contable (PIBE 2023 preliminar)"
	"presentacion" "brecha_capital_razon" "clasificación, denominador, momento contable (PIBE 2023 preliminar)"
	"presentacion" "brecha_consumo_razon" "cobertura (consumo residente vs producción territorial), denominador, momento contable"
	"presentacion" "incidencia_nota" "objeto del pipeline (SIM.do §7.1) sobre aportaciones.dta: total = ImpuestosAportaciones (sin OTROSK ni FMP); AlCapital = ISRPM_Sim+OTROSK; compuerta D.1 validada contra INCD/INCD2/INCD3"
	"presentacion" "deciles_leyenda" "sufijo nac = nacional; nl = hogares NL en deciles nacionales; nle = deciles recalculados solo con hogares NL (mismos criterios de ordenamiento)"
	"presentacion" "escenario_s0" "supuesto de incidencia S0 (sufijo nl, método vigente): ISR PM recae en perceptores de ingreso de capital con ranking probit de formalidad y cut-off en la recaudación LIF; queda dentro de la banda [S1, S3]"
	"presentacion" "escenario_s1" "supuesto de incidencia S1: ISR PM nacional prorrateado a ingreso de capital privado por hogar, sin cut-off por probit; cota inferior de la banda"
	"presentacion" "escenario_s2" "supuesto de incidencia S2: traslación 50% capital (prorrateo S1) / 25% trabajo (ing_subor) / 25% consumo (base de IVA)"
	"presentacion" "escenario_s3" "supuesto de incidencia S3: pago esperado = probabilidad predicha del probit de formalidad PM (prob_moral, households.dta) x impuesto potencial [(tpm+depreciación-exenciones) x 30%], reescalado al total del pipeline; cota superior de la banda"
	"presentacion" "escenarios_nota" "todos los escenarios son estimadores válidos reescalados al mismo total nacional (suma de ISRPM_Sim): cambia la incidencia, no la recaudación; banda declarada [S1, S3], con S0 (método vigente) dentro de ella"
	"presentacion" "robustez_denominador" "familias *G y razonGY usan gasto corriente monetario (gastoanualTOT a escala ConHog) como denominador; razón declarada: denominador (ingreso corriente vs proxy de ingreso permanente)"
	"presentacion" "decilI_nota" "la TE de consumo NL es similar a la nacional (IVATEnl vs IVATEnac) y la construcción del IVA es la misma; el diferencial de incidencia del decil I COMBINA denominador (selección: razón gasto/ingreso > 1) y numerador (canasta más gravada: pctGravDecI/pctIEPSDecI)"
	"presentacion" "canasta_nota" "estructura de la canasta del decil I (pct*DecI*): participaciones del gasto clasificado por régimen IVA (gravado/exento/tasa cero, matriz IVAT en el orden de levelsof de Expenditure.do §5.2) y de bienes con IEPS sobre el total clasificado"
	"presentacion" "otrosk_nota" "en las tablas de incidencia AlCapital incluye OTROSK (SIM.do:436) y el total ImpAport lo excluye (SIM.do:440); se exporta la familia OTROSK por separado: AlTrabajo+AlCapital+AlConsumo-OTROSK = Total"
	"presentacion" "deuda_tecnica" "extender scalarjson.ado con una clave canónica supuestos (bloque propio del contrato) para que los supuestos de incidencia de escenarios no dependan del bloque libre presentacion"
	end
	tempfile meta
	save `meta'

	** 5.3 Capas declaradas **
	clear
	input str24 id str80 etiqueta str24 escalar str40 definida_en str24 tipo_dato str16 unidad str8 incluida
	"ylimptenl" "TE laboral NL (micro/micro)" "YlImpTEnl" "TasasEfectivasMicro.ado" "simulado" "%" "false"
	"ivatenl"   "TE IVA NL (micro/micro)" "IVATEnl" "TasasEfectivasMicro.ado" "simulado" "%" "false"
	"isrpmtenl" "TE ISR PM NL (micro/micro)" "ISRPMTEnl" "TasasEfectivasMicro.ado" "simulado" "%" "false"
	"inctotnl"  "Incidencia total NL (% ingreso, pipeline)" "incImpAportnlTot" "EntidadNL.do (INCI.ado)" "simulado" "%" "false"
	end
	tempfile capas
	save `capas'

	** 5.4 Tabla (estructura del display que la página espejaría) **
	clear
	input byte bloque str60 etiqueta str12 prefijo str20 familia byte enfasis
	1 "Salarios: ISR asalariados" "" "ISRASTE" 0
	1 "Salarios: cuotas IMSS" "" "CUOTASTE" 0
	1 "Mixto: ISR personas físicas" "" "ISRPFTE" 0
	1 "Capital: ISR personas morales" "" "ISRPMTE" 0
	1 "Consumo: IVA" "" "IVATE" 0
	1 "Consumo: IEPS no petrolero" "" "IEPSNPTE" 0
	1 "Consumo: IEPS petrolero" "" "IEPSPTE" 0
	1 "Laborales (total)" "" "YlImpTE" 1
	1 "Consumo (total)" "" "ingconsumoTE" 1
	2 "Conciliación: participación NL" "" "Part" 0
	2 "Proxies estatales declarados" "" "Proxy" 0
	2 "Brechas declaradas (pp)" "" "Brecha" 1
	3 "Incidencia por decil (pipeline)" "inc" "ImpAport" 1
	end
	tempfile tabla
	save `tabla'
}
restore

** 5.5 Lista de escalares a exportar (solo los vivos; cero números a mano) **
local esc ""
foreach te in ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP IEPSP YlImp ingconsumo {
	foreach s in nac nl {
		foreach fam in `te'TE`s' Dif`te'TE`s' {
			capture confirm scalar `fam'
			if _rc == 0 local esc "`esc' `fam'"
		}
	}
	capture confirm scalar Rel`te'TEnl
	if _rc == 0 local esc "`esc' Rel`te'TEnl"
}
foreach s in nac nl {
	foreach b in RecISRAS RecCUOTAS RecISRPF RecISRPM RecOTROSK RecIVA RecIEPSNP RecIEPSP RecISAN RecIMPORT RecTotal ///
		BaseSal BaseMix BaseKPriv BaseConsu BaseVehic BaseAlcTaba BaseCombu IngBruto Pob {
		capture confirm scalar `b'`s'
		if _rc == 0 local esc "`esc' `b'`s'"
	}
}
foreach c in PartSalENIGHnl PartMixENIGHnl PartKPrivENIGHnl PartConsENIGHnl PartPobnl PartRecTotalnl ///
	ProxyMasaSalENOEnl ProxyPIBEnl BrechaSalENOEnl BrechaMixPIBEnl BrechaKPrivPIBEnl BrechaConsPIBEnl {
	capture confirm scalar `c'
	if _rc == 0 local esc "`esc' `c'"
}
foreach v in AlTrabajo AlCapital AlConsumo ImpAport AlConsumoG ImpAportG ///
	OTROSK IVA IEPSNP IEPSP ISAN IMPORT {
	foreach s in nac nl nle nlS1 nlS2 nlS3 nleS1 nleS2 nleS3 {
		foreach d in I II III IV V VI VII VIII IX X Tot {
			foreach fam in `v'`s'`d' dis`v'`s'`d' inc`v'`s'`d' {
				capture confirm scalar `fam'
				if _rc == 0 local esc "`esc' `fam'"
			}
		}
	}
}
foreach s in nac nl nle {
	foreach d in I II III IV V VI VII VIII IX X Tot {
		capture confirm scalar razonGY`s'`d'
		if _rc == 0 local esc "`esc' razonGY`s'`d'"
	}
}
foreach s in nac nl nle {
	foreach b in nHogDecI PctIngBajoDecI TamHogDecI EdadJefeDecI ///
		pctGravDecI pctExenDecI pctCeroDecI pctIEPSDecI {
		capture confirm scalar `b'`s'
		if _rc == 0 local esc "`esc' `b'`s'"
	}
}
foreach c in PartISRPMnl PartISRPMnlS1 PartISRPMnlS2 PartISRPMnlS3 ///
	ISRPMTEnlS1 ISRPMTEnlS2 ISRPMTEnlS3 RecISRPMnlS1 RecISRPMnlS2 RecISRPMnlS3 {
	capture confirm scalar `c'
	if _rc == 0 local esc "`esc' `c'"
}

** 5.6 Contrato JSON **
capture mkdir `"`site'/users/$id/nodos"'
noisily scalarjson, nodo("entidad-nl") ///
	titulo("Tasas efectivas e incidencia fiscal federal: Nuevo León") ///
	medida("recaudación federal simulada de residentes de Nuevo León") ///
	anioref(`anio') ///
	serie(`serie') origenserie("master/perfiles`anio'.dta + master/households.dta + users/aportaciones.dta, corte entidad 19") ///
	metadatos(`meta') capas(`capas') tabla(`tabla') ///
	escalares(`esc') ///
	saving(`"`site'/users/$id/nodos/statajson_entidad-nl.json"')

noisily di _newline in g "EntidadNL: listo. Salida única: " in y `"`site'/users/$id/nodos/statajson_entidad-nl.json"'
