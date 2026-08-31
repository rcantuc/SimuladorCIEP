*! EntidadNL.do  v1.0.0 — driver F1: TE micro/micro, incidencia y conciliación para Nuevo León (entidad 19)
*
* QUÉ ES ESTO (contrato F1, DIAGNOSTICO_NL.md + enmiendas aprobadas por Ricardo):
*   (1) TE-NL micro/micro vía TasasEfectivasMicro.ado (numerador = Σ impuesto de
*       perfiles<anio>.dta con entidad==19; denominador = Σ base micro ajustada NL).
*       Incluye la validación nacional micro/micro vs. TE oficial macro/macro
*       (escalares Dif*TEnac) con los faltantes de denominador DECLARADOS.
*   (2) Escalares SIN guion bajo: sufijos nl (deciles nacionales) y nle
*       (deciles estatales). Las variables Stata espejo pueden llevar _nl.
*   (3) output.txt INTACTO: este driver no escribe en el log 'output'. Toda
*       salida NL va exclusivamente por escalar → scalarjson.
*
* USO (tras correr SIM.do en la MISMA sesión, con los escalares oficiales vivos):
*   do "`c(sysdir_site)'/01_modulos/EntidadNL.do"
*
* SALIDA: users/$id/nodos/statajson_entidad-nl.json (generada, gitignored).
* OJO: destruye los datos en memoria (igual que el tramo 7 de SIM.do).

*** 0 GUARDAS (escalares del motor vivos; sin ellos no hay validación posible) ***
local site `"`c(sysdir_site)'"'
foreach s in anioPE aniovp anioenigh pibY ISRASTE IVATE {
	capture confirm scalar `s'
	if _rc {
		di as err "EntidadNL: falta el scalar `s'. Corre SIM.do primero (misma sesión) y reintenta."
		exit 198
	}
}
local anio = scalar(anioPE)
local pibY = scalar(pibY)

noisily di _newline(2) in g _dup(20) "." "{bf:   ENTIDAD 19 — NUEVO LEÓN " in y `anio' in g "   }" _dup(20) "."

*** 1 TE MICRO/MICRO ***
* 1.1 Espejo nacional (validación vs macro/macro; enmienda 1) *
noisily TasasEfectivasMicro, anio(`anio') sufijo(nac)

* 1.2 Nuevo León: TE + incidencia en deciles nacionales (nl) y estatales (nle) *
noisily TasasEfectivasMicro, anio(`anio') entidad(19) sufijo(nl)

*** 2 CONCILIACIÓN POR BASE (brechas DECLARADAS, nunca forzadas) ***
* Participaciones de NL en el agregado ENIGH ajustado (micro, post-CN) *
escalar pct PartSalENIGHnl = scalar(BaseSalnl)/scalar(BaseSalnac)*100
escalar pct PartMixENIGHnl = scalar(BaseMixnl)/scalar(BaseMixnac)*100
escalar pct PartKPrivENIGHnl = scalar(BaseKPrivnl)/scalar(BaseKPrivnac)*100
escalar pct PartConsENIGHnl = scalar(BaseConsunl)/scalar(BaseConsunac)*100
escalar pct PartPobnl = scalar(Pobnl)/scalar(Pobnac)*100
escalar pct PartRecTotalnl = scalar(RecTotalnl)/scalar(RecTotalnac)*100

* Proxies estatales — parámetros con fuente y corte declarados (misma
* convención que los parámetros de SIM.do §4.1; el valor publicado se captura
* UNA vez aquí, con su fuente, y todo lo derivado se computa) *
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

*** 3 TABLA RESUMEN (display; los números viven en escalares) ***
noisily di _newline in g "{bf:  Tasa efectiva (%)" ///
	_col(30) %9s "Oficial" _col(42) %9s "Micro nac" _col(54) %9s "Micro NL" _col(66) %8s "NL-nac" "}"
noisily di in g _dup(74) "-"
foreach te in ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP YlImp ingconsumo {
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

* 3.5 Incidencia por decil (display desde los escalares ya registrados) *
foreach s in nl nle {
	if "`s'" == "nl" local jlab "deciles nacionales"
	else local jlab "deciles estatales"
	noisily di _newline in g "{bf:  Incidencia NL (`jlab') — % del ingreso bruto del decil}"
	noisily di in g "  Decil" _col(12) %10s "AlTrabajo" _col(26) %10s "AlCapital" ///
		_col(40) %10s "AlConsumo" _col(54) %10s "Total"
	noisily di in g _dup(64) "-"
	foreach d in I II III IV V VI VII VIII IX X Tot {
		noisily di in g "  `d'" ///
			_col(12) in y %10.1fc scalar(incAlTrabajo`s'`d') ///
			_col(26) in y %10.1fc scalar(incAlCapital`s'`d') ///
			_col(40) in y %10.1fc scalar(incAlConsumo`s'`d') ///
			_col(54) in y %10.1fc scalar(incImpTotal`s'`d')
	}
}

*** 4 EXPORTACIÓN — scalarjson (canal único de salida numérica NL) ***

** 4.1 Serie canónica (un año: el de la política) **
preserve
quietly {
	PIBDeflactor, anio(`=scalar(aniovp)') nographs nooutput
	local deflator = 1
	forvalues k = 1(1)`=_N' {
		if anio[`k'] == `anio' {
			local deflator = deflator[`k']
			continue, break
		}
	}
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

	** 4.2 Metadatos (unidad/formato/divisor por variable canónica; criterios;
	**     fuentes; presentacion = razones declaradas de brecha y faltantes) **
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
	"criterio" "neto_o_bruto"     "recaudación neta simulada; bases brutas ajustadas a CN"
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
	"presentacion" "brecha_salarios_razon" "cobertura (ENIGH-CN vs ENOE), deflactor (ENOE a pesos 1T2020; se compara por participaciones), momento contable (ENIGH 2024 vs ENOE 3T2024), fuente y corte"
	"presentacion" "brecha_mixto_razon" "clasificación (PIBE incluye gobierno y actividades no gravables), denominador (PIBE total vs base fiscal), momento contable (PIBE 2023 preliminar)"
	"presentacion" "brecha_capital_razon" "clasificación, denominador, momento contable (PIBE 2023 preliminar)"
	"presentacion" "brecha_consumo_razon" "cobertura (consumo residente vs producción territorial), denominador, momento contable"
	"presentacion" "den_salarios_faltante" "SSEmpleadores+SSImputada del denominador oficial sin contraparte micro (cobertura); TE micro de salarios usa ing_subor"
	"presentacion" "den_iepsp_faltante" "ConsPriv21 (consumo privado minería) sin contraparte micro (cobertura); IEPSP sin TE propia, sí en el agregado de consumo"
	"presentacion" "den_iepsnp_faltante" "Recre7132 (juegos) sin contraparte micro (cobertura); TE micro de IEPS NP usa BebA+Taba"
	"presentacion" "deciles_leyenda" "sufijo nl = hogares NL en deciles nacionales; nle = deciles recalculados solo con hogares NL (mismos criterios de ordenamiento)"
	end
	tempfile meta
	save `meta'

	** 4.3 Capas declaradas (titular + faltantes conceptuales con procedencia) **
	clear
	input str24 id str80 etiqueta str24 escalar str40 definida_en str24 tipo_dato str16 unidad str8 incluida
	"ylimptenl" "TE laboral NL (micro/micro)" "YlImpTEnl" "TasasEfectivasMicro.ado" "simulado" "%" "false"
	"ivatenl"   "TE IVA NL (micro/micro)" "IVATEnl" "TasasEfectivasMicro.ado" "simulado" "%" "false"
	"isrpmtenl" "TE ISR PM NL (micro/micro)" "ISRPMTEnl" "TasasEfectivasMicro.ado" "simulado" "%" "false"
	"densscn"   "SSEmpleadores+SSImputada (denominador oficial salarios)" "" "sin contraparte micro (cobertura)" "no disponible" "mxn" "false"
	"deniepsp"  "ConsPriv21 (denominador oficial IEPS petrolero)" "" "sin contraparte micro (cobertura)" "no disponible" "mxn" "false"
	"denjuegos" "Recre7132 (denominador oficial IEPS no petrolero)" "" "sin contraparte micro (cobertura)" "no disponible" "mxn" "false"
	end
	tempfile capas
	save `capas'

	** 4.4 Tabla (estructura del display que la página espejaría) **
	clear
	input byte bloque str60 etiqueta str12 prefijo str20 familia byte enfasis
	1 "Salarios: ISR asalariados" "" "ISRASTE" 0
	1 "Salarios: cuotas IMSS" "" "CUOTASTE" 0
	1 "Mixto: ISR personas físicas" "" "ISRPFTE" 0
	1 "Capital: ISR personas morales" "" "ISRPMTE" 0
	1 "Consumo: IVA" "" "IVATE" 0
	1 "Consumo: IEPS no petrolero" "" "IEPSNPTE" 0
	1 "Laborales (total)" "" "YlImpTE" 1
	1 "Consumo (total)" "" "ingconsumoTE" 1
	2 "Conciliación: participación NL" "" "Part" 0
	2 "Proxies estatales declarados" "" "Proxy" 0
	2 "Brechas declaradas (pp)" "" "Brecha" 1
	end
	tempfile tabla
	save `tabla'
}
restore

** 4.5 Lista de escalares a exportar (solo los vivos; cero números a mano) **
local esc ""
foreach te in ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP YlImp ingconsumo {
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
		BaseSal BaseMix BaseKPriv BaseConsu BaseVehic BaseAlcTaba IngBruto Pob {
		capture confirm scalar `b'`s'
		if _rc == 0 local esc "`esc' `b'`s'"
	}
}
foreach c in PartSalENIGHnl PartMixENIGHnl PartKPrivENIGHnl PartConsENIGHnl PartPobnl PartRecTotalnl ///
	ProxyMasaSalENOEnl ProxyPIBEnl BrechaSalENOEnl BrechaMixPIBEnl BrechaKPrivPIBEnl BrechaConsPIBEnl {
	capture confirm scalar `c'
	if _rc == 0 local esc "`esc' `c'"
}
foreach v in AlTrabajo AlCapital AlConsumo ImpTotal {
	foreach s in nl nle {
		foreach d in I II III IV V VI VII VIII IX X Tot {
			foreach fam in `v'`s'`d' dis`v'`s'`d' inc`v'`s'`d' {
				capture confirm scalar `fam'
				if _rc == 0 local esc "`esc' `fam'"
			}
		}
	}
}

** 4.6 Contrato JSON **
capture mkdir `"`site'/users/$id/nodos"'
noisily scalarjson, nodo("entidad-nl") ///
	titulo("Tasas efectivas e incidencia fiscal federal: Nuevo León") ///
	medida("recaudación federal simulada de residentes de Nuevo León") ///
	anioref(`anio') ///
	serie(`serie') origenserie("master/perfiles`anio'.dta + master/households.dta, corte entidad 19") ///
	metadatos(`meta') capas(`capas') tabla(`tabla') ///
	escalares(`esc') ///
	saving(`"`site'/users/$id/nodos/statajson_entidad-nl.json"')

noisily di _newline in g "EntidadNL: listo. Salida única: " in y `"`site'/users/$id/nodos/statajson_entidad-nl.json"'
