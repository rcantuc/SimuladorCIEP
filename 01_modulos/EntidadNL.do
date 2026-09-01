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
	args v fam decvar suf vdef ydef
	tempvar v2 ing2
	quietly g double `v2' = `v'/`vdef'
	quietly g double `ing2' = ingbrutotot/`ydef'
	label var `ing2' "Ingreso bruto total"
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

** 2.2 COMPUERTA D.1 (nacional, AportacionesNetas — la variable ya viene
**     deflactada del pipeline [Simulador.ado:68 + use original], por eso el
**     espejo usa deflactor 1 sobre ella y el verdadero sobre el ingreso) **
_ENLinci AportacionesNetas AportacionesNetas decil "" 1 `deflator'

** 2.3 Incidencia nacional de las cargas del pipeline (sufijo nac) **
noisily di _newline in g "{bf:  Incidencia nacional (deciles nacionales) — sufijo nac}"
foreach par in "AlTrabajo AlTrabajo" "AlCapital AlCapital" "AlConsumo AlConsumo" "ImpuestosAportaciones ImpAport" {
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decil nac `deflator' `deflator'
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
foreach par in "AlTrabajo AlTrabajo" "AlCapital AlCapital" "AlConsumo AlConsumo" "ImpuestosAportaciones ImpAport" {
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decil nl `deflator' `deflator'
	_ENLinci `: word 1 of `par'' `: word 2 of `par'' decilE nle `deflator' `deflator'
}

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
		_col(40) %10s "AlConsumo" _col(54) %12s "Total (SIM)"
	noisily di in g _dup(66) "-"
	foreach d in I II III IV V VI VII VIII IX X Tot {
		noisily di in g "  `d'" ///
			_col(12) in y %10.1fc scalar(incAlTrabajo`s'`d') ///
			_col(26) in y %10.1fc scalar(incAlCapital`s'`d') ///
			_col(40) in y %10.1fc scalar(incAlConsumo`s'`d') ///
			_col(54) in y %12.1fc scalar(incImpAport`s'`d')
	}
}

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
foreach v in AlTrabajo AlCapital AlConsumo ImpAport {
	foreach s in nac nl nle {
		foreach d in I II III IV V VI VII VIII IX X Tot {
			foreach fam in `v'`s'`d' dis`v'`s'`d' inc`v'`s'`d' {
				capture confirm scalar `fam'
				if _rc == 0 local esc "`esc' `fam'"
			}
		}
	}
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
