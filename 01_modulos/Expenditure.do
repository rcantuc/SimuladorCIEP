******************************************************************
****                                                          ****
**** A.2. MACRO + MICRO HARMONIZATION: HOUSEHOLD EXPENDITURES ****
****                                                          ****
******************************************************************
****
**** 9. Especifico de Mexico (plantilla de capitulo §9; alimenta cap0; texto de CUAD-1 §9, 2026-11-07; sin cambio de codigo):
****   | Elemento                         | Que requiere genericamente                                   | Por que Mexico lo resuelve asi                                        |
****   | Consumo privado por finalidad    | Consumo final de hogares por COICOP con S.14 separado de las | INEGI publica la apertura por finalidad solo para «hogares e ISFLSH»  |
****   | (BIE 724600-724656)              | ISFLSH                                                       | en territorio (BIE 7246xx); la CSI separa S.14 de S.15 solo en el     |
****   |                                  |                                                              | total P.3 (23,381.329 vs 388.320): el ancla TT<k> es hogares + ISFLSH |
****   |                                  |                                                              | y la correccion a S.14 es un factor unico (CUAD-1 consumo_ancla)      |
****   | ENIGH tipo_gasto y claves 2018   | Encuesta de gasto con tipo (monetario, autoconsumo, regalos, | La ENIGH 2024 «nueva serie» cambio claves (6 digitos); §2.6 trabaja   |
****   |                                  | en especie, transferencias, alquiler imputado) y catalogo    | con clave_2018 via clave_iva.dta (construida por CIEP); gasto_anual   |
****   |                                  | estable                                                      | suma G1-G7 (G2 y G5 cuentan los regalos dos veces; G6 es D.63)        |
****   | Recaudacion por impuesto (LIF)   | Recaudacion observada por impuesto del anio de la encuesta  | LIF por divCIEP/divSIM; §1.2 lee IEPS no petrolero de divCIEP (24.075)|
****   |                                  |                                                              | y TasasEfectivas de divSIM (224.780): CUAD-1 iepsnp_macro             |
****   | Valor agregado del ultimo        | Proporcion del precio final que es valor agregado del        | Censo Economico (VACB/PBT por clase SCIAN, §2.7): base del IVA        |
****   | eslabon (Censo Economico)        | vendedor, para la base del IVA micro                         | micro; la «informalidad» 23.1 % (IVAT[13]) es el cociente micro/LIF   |
****
**** §4 Decisiones (sesión log-legible, 2026-11-09): los parámetros firmados del consumo y del IEPS se describen aquí; SIM.do §0.8b solo los
**** declara en una línea y §0.9 imprime el cuadro con FLAG si el valor no es el firmado. La primera alternativa es la firmada.
****   (SIM.do §0.8b, resumen de alternativas) consumo_ancla p3_s14 (Σ Cpriv = P.3 S.14, CSI_115 f.166; ISFLSH P.3 S.15 y vintage como filas de
****   sector) | conhog (BIE 724600 hogares + ISFLSH, v8.15.3); consumo_precios comprador (C a precios de comprador e impuestos a productos ∝
****   gasto como ingreso; único implementado) | basicos (8.17: C − D.21 + D.31 por categoría); iepsnp_macro divsim (IEPSNP de divSIM 224.780 =
****   no petrolero + salud) | divciep (24.075, v8.15.3); ieps_relativo micro (IEPSP ∝ gas_pc_Gasolinas + gas_pc_Combustibles; IEPSNP ∝ IEPS micro
****   por categoría; lo leen PerfilesSim.do §6 y NTA.do §4) | proxy (gas_pc_Vehi / gas_pc_BebA, v8.15.3).
****
**** Parametros de Cuadratura II (v8.16.0, 2026-11-08; CUAD-1 §4 firmado en §4.0, firma CUAD-1-2 §B). SIM.do §0.8b los declara; sueltos rige el
**** valor firmado. Cada valor distinto del firmado imprime FLAG:
****   consumo_ancla = p3_s14      «Σ Cpriv = P.3 S.14» — los 19 rubros se anclan a su serie BIE (hogares + ISFLSH en territorio) y el total se
****                               reancla con UN factor (TTp3 = (P.3 S.14 − compras netas) / ConHog) a P.3 del sector hogares (CSI_115 f.166);
****                               P.3 S.15 (ISFLSH) y el vintage BIE−CSI del consumo quedan como filas de sector. Alternativa conhog (v8.15.3).
****   consumo_precios = comprador «C a precios de comprador» — unico implementado; basicos (C − D.21 + D.31 por categoria) es de 8.17.
****   iepsnp_macro = divsim       «IEPS no petrolero macro = IEPSNP de divSIM (224.780)» — §1.2 suma IEPS (no petrolero) + IEPS (salud) de divCIEP;
****                               divciep (24.075, v8.15.3) comparaba el micro (alcohol, tabaco, bebidas, alimentos) contra el grupo que no lo contiene.
****   FLAG 20 (cerrado 8.16b)     Simulador.ado restaura la variable sin deflactar: la cache consumption_*_pc.dta ya no lleva 1/deflactor.
****   FLAG 33 (8.16b)             gastotarjetas (TB01-TB16, sin tipo_gasto) fuera de la base del consumo: es el pago de la tarjeta (flujo
****                               financiero), no el consumo del trimestre; el monto se declara (escalar ExpTarjetas).
****   Fichas 5 y 6 (8.16b)        G2 (regalos otorgados) fuera: el consumo se cuenta en quien lo recibe (G5); predial R004 y tenencia R012 fuera
****                               del consumo (D.59; viven en OTROSK de la LIF); G009-G016 y R003 (gas LP, combustibles, gas natural) a 724614.
****   IEPS micro incompleto       gasolinas fuera de Expenditure.do (§6.2 salta Gasolinas): el IEPS micro cubre una fraccion del IEPSNP macro
****                               (escalar IEPSNPCobertura); el ancla LIF manda en TasasEfectivas y el reparto va ∝ IEPS micro (ieps_relativo).
****
capture mkdir "${SIMROOT}/raw"
capture mkdir "${SIMROOT}/raw/ENIGH/"
capture mkdir "${SIMROOT}/raw/temp"
cd "${SIMROOT}/raw/ENIGH/"
if "`1'" == "" {
	local anioenigh = 2024
	local aniovp = 2024
	local claveiva = "*2018"
	capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
	if _rc != 0 {
		ensure_asset "2024.zip"
		unzipfile "${SIMROOT}/raw/ENIGH/2024.zip", replace
	}
}
timer on 15
else {
	if `1' >= 2024 {
		local anioenigh = 2024
		local claveiva = "*2018"
		capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
		if _rc != 0 {
			ensure_asset "2024.zip"
			unzipfile "${SIMROOT}/raw/ENIGH/2024.zip", replace
		}
	}
	if `1' >= 2022 & `1' < 2024 {
		local anioenigh = 2022
		local claveiva = "*2018"
		capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
		if _rc != 0 {
			ensure_asset "2022.zip"
			unzipfile "${SIMROOT}/raw/ENIGH/2022.zip", replace
		}
	}
	if `1' >= 2020 & `1' < 2022 {
		local anioenigh = 2020
		local claveiva = "*2018"
		capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
		if _rc != 0 {
			ensure_asset "2020.zip"
			unzipfile "${SIMROOT}/raw/ENIGH/2020.zip", replace
		}
	}
	if `1' >= 2018 & `1' < 2020 {
		local anioenigh = 2018
		local claveiva = "*2018"
		capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
		if _rc != 0 {
			ensure_asset "2018.zip"
			unzipfile "${SIMROOT}/raw/ENIGH/2018.zip", replace
		}
	}
	if `1' >= 2016 & `1' < 2018 {
		local anioenigh = 2016
		local claveiva = "*2014"
		capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
		if _rc != 0 {
			ensure_asset "2016.zip"
			unzipfile "${SIMROOT}/raw/ENIGH/2016.zip", replace
		}
	}
	if `1' >= 2013 & `1' < 2016 {
		local anioenigh = 2014
		local claveiva = "*2014"
		capture confirm file "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta"
		if _rc != 0 {
			ensure_asset "2014.zip"
			unzipfile "${SIMROOT}/raw/ENIGH/2014.zip", replace
		}
	}
}


** 0.0 Parametros de Cuadratura II (8.16b): sueltos rige el valor firmado; distinto del firmado = FLAG **
if "$consumo_ancla" == "" global consumo_ancla "p3_s14"
if "$consumo_precios" == "" global consumo_precios "comprador"
if "$iepsnp_macro" == "" global iepsnp_macro "divsim"
if !inlist("$consumo_ancla", "p3_s14", "conhog") {
	noisily _log aviso, tipo(IMPORTANTE) texto(`"Expenditure: consumo_ancla = "$consumo_ancla" no es p3_s14 | conhog"') ref("CUAD-1 §4.0") rojo
	exit 198
}
if !inlist("$iepsnp_macro", "divsim", "divciep") {
	noisily _log aviso, tipo(IMPORTANTE) texto(`"Expenditure: iepsnp_macro = "$iepsnp_macro" no es divsim | divciep"') ref("CUAD-1 §4.0") rojo
	exit 198
}
if "$consumo_precios" != "comprador" {
	noisily _log aviso, tipo(FLAG) texto("Expenditure: consumo_precios = $consumo_precios; solo comprador está implementado en 8.16b (basicos es de 8.17), se sigue con comprador") ref("CUAD-1 §4.0") rojo
	global consumo_precios "comprador"
}
if "$consumo_ancla" != "p3_s14" noisily _log aviso, tipo(FLAG) texto("Expenditure: consumo_ancla = $consumo_ancla ancla el consumo a ConHog BIE (hogares + ISFLSH), no a P.3 S.14; no compara con el baseline") ref("CUAD-1 §4.0") rojo
if "$iepsnp_macro" != "divsim" noisily _log aviso, tipo(FLAG) texto("Expenditure: iepsnp_macro = $iepsnp_macro compara el IEPS micro contra IEPS no petrolero de divCIEP, sin IEPS salud") ref("CUAD-1 §4.0") rojo

** 0.1 Directorios y log files **
capture log close expenditures
capture mkdir "${SIMROOT}/raw/temp/`anioenigh'"
log using "${SIMROOT}/raw/temp/`anioenigh'/expenditures.smcl", replace name(expenditures)


** 0.2 Texto introductorio **
noisily _log modulo "Expenditure  ·  gasto de los hogares, ENIGH `anioenigh'" ref("CUAD-1 §4; header §4 Decisiones")





**********************************
***                            ***
***  1. DATOS MACROECONóMICOS  ***
***                            ***
**********************************

** 1.1 Sistema de Cuentas Nacionales **
SCN, anio(`anioenigh') nographs
local PIB = scalar(PIB)
local ConHog = scalar(ConHog)


** 1.2 SHCP: Datos Abiertos **
LIF, anio(`anioenigh') by(divCIEP) nographs min(0)
* Por grupo LIF devuelve r(); los IEPS por producto (Tabacos, Juegos, ...)
* son escalares de "Returns Extras" y siguen globales. *
local IVA = r(IVA)
* 8.16b (CUAD-1 §8 bis ficha 2; iepsnp_macro): el IEPS no petrolero macro es IEPSNP de divSIM = IEPS (no petrolero) + IEPS (salud) de divCIEP;
* el micro de §6 (alcohol, tabaco, bebidas, alimentos) es casi todo «salud», y compararlo contra 24.075 tapaba que esta incompleto. *
local IEPSNP_divciep = r(IEPS__no_petrolero_)
local IEPSNP_salud = r(IEPS__salud_)
if "$iepsnp_macro" == "divsim" local IEPSNP = `IEPSNP_divciep' + `IEPSNP_salud'
else local IEPSNP = `IEPSNP_divciep'
local IepsGasolinas = r(IEPS__petrolero_)
local IepsTabaco = scalar(Tabacos)
local IepsJuegos = scalar(Juegos)
local IepsTelecom = scalar(Telecom)
local IepsBebidasEner = scalar(Energiza)
local IepsBebidasSabor = scalar(Saboriza)
local IepsAltoContCal = scalar(AlimNoBa)
local IepsCombustibles = scalar(Fosiles)
local IepsAlcohol_20 = scalar(Alcohol)*0.2
local IepsAlcohol_20_ = scalar(Alcohol)*0.2
local IepsCervezas = scalar(Alcohol)*0.6


** 1.3 Población **
Poblacion, anio(`anioenigh') nographs
tabstat poblacion if anio == `anioenigh', stat(sum) save f(%15.0fc)
local pobtotNacional = r(StatTotal)[1,1]




**********************************
***                            ***
***  2. DATOS MICROECONóMICOS  ***
***                            ***
**********************************
capture confirm file "${SIMROOT}/raw/temp/`anioenigh'/preconsumption.dta"
if _rc != 0 {
	capture confirm file "${SIMROOT}/raw/temp/`anioenigh'/pre_iva.dta"
	if _rc != 0 {

		** 2.1. Base de datos de gastos de los hogares **
		use "${SIMROOT}/raw/ENIGH/`anioenigh'/gastospersona.dta", clear
		append using "${SIMROOT}/raw/ENIGH/`anioenigh'/gastohogar.dta"
		append using "${SIMROOT}/raw/ENIGH/`anioenigh'/gastotarjetas.dta"
		append using "${SIMROOT}/raw/ENIGH/`anioenigh'/erogaciones.dta"

		** 2.2. Gasto anual **
		egen gasto_anual = rsum(gas_nm_tri gasto_tri)
		replace gasto_anual = gasto_anual*4
		format gasto_anual %10.2fc

		** 2.3. Variables sociodemograficas **
		merge m:1 (folioviv foliohog) using "${SIMROOT}/raw/ENIGH/`anioenigh'/concentrado.dta", ///
			nogen keepus(factor)
		merge m:1 (folioviv) using "${SIMROOT}/raw/ENIGH/`anioenigh'/vivienda.dta", ///
			nogen keepus(ubica_geo tenencia)
		capture rename factor_hog factor

		** 2.4. Gasto en educación *
		replace inscrip = 0 if inscrip == .
		replace colegia = 0 if colegia == .
		capture replace material = 0 if material == .

		if `anioenigh' < 2024 {
			** 2.5. Deducciones personales del ISR **
			g deduc_gasto_colegi1 = gasto_anual if clave == "E001"
			g deduc_gasto_colegi2 = gasto_anual if clave == "E002"
			g deduc_gasto_colegi3 = gasto_anual if clave == "E003"
			g deduc_gasto_colegi4 = gasto_anual if clave == "E007"
			g deduc_gasto_colegi5 = gasto_anual if clave == "E004"
			g deduc_STrans_escolar = gasto_anual if clave == "E013"
			g deduc_honor_medicos = gasto_anual if (clave >= "J001" & clave <= "J003") ///
				| (clave >= "J007" & clave <= "J008") | (clave >= "J011" & clave <= "J012") ///
				| (clave >= "J016" & clave <= "J019") | (clave >= "J039" & clave <= "J041")
			g deduc_segur_medicos = gasto_anual if clave == "J071"
			g deduc_gasto_funerar = gasto_anual if clave == "N002"
			g deduc_gasto_donativ = gasto_anual if clave == "N014"
		}

		if `anioenigh' >= 2024 {
			** 2.5. Deducciones personales del ISR **
			g deduc_gasto_colegi1 = gasto_anual if clave == "174111" | clave == "174112" ///
				| clave == "133011" | clave == "133012" | clave == "101011" | clave == "101012"
			g deduc_gasto_colegi2 = gasto_anual if clave == "101021" | clave == "102022"
			g deduc_gasto_colegi3 = gasto_anual if clave == "102001" | clave == "102002"
			g deduc_gasto_colegi4 = gasto_anual if clave == "104011" | clave == "104012"
			g deduc_gasto_colegi5 = gasto_anual if clave == "103001" | clave == "103002"
			g deduc_STrans_escolar = gasto_anual if clave == "073230"
			g deduc_honor_medicos = gasto_anual if clave == "062194" | clave == "062192" ///
				| clave == "064103" | clave == "064202" | clave == "063103" | clave == "063104" ///
				| clave == "063106" | clave == "062193" | clave == "062191" | clave == "062210" ///
				| clave == "062291" | clave == "062292" | clave == "064101" | clave == "064102" ///
				| clave == "064201" | clave == "063101" | clave == "063105" | clave == "063200" ///
				| clave == "063102"
			g deduc_segur_medicos = gasto_anual if clave == "121202" | clave == "121201"
			g deduc_gasto_funerar = gasto_anual if clave == "139092"
			g deduc_gasto_donativ = gasto_anual if clave == "173417"
		}

		** 2.6. Unión de claves de IVA y IEPS **
		merge m:1 (clave) using "${SIMROOT}/raw/ENIGH/`anioenigh'/clave_iva.dta", ///
			nogen keepus(descripcion `claveiva' clase_de_actividad*) keep(matched master)
		encode iva201, gen(tiva)
		compress
		save "${SIMROOT}/raw/temp/`anioenigh'/pre_iva.dta", replace
	}

	** 2.7. Valor agregado del último eslabón — Censo Económico **
	*  VA ratio = VACB / PBT (Valor Agregado Censal Bruto / Producción Bruta Total)
	*  Mide qué fracción del precio final es valor creado en el sector.
	capture confirm file "${SIMROOT}/raw/temp/`anioenigh'/va_por_clase_actividad.dta"
	if _rc != 0 {
		use "${SIMROOT}/raw/ENIGH/`anioenigh'/censo_eco_municipios.dta", clear
		rename codigo clase_de_actividad

		collapse (sum) A111A A131A, by(clase_de_actividad)

		gen double va_ratio = A131A / A111A
		replace va_ratio = . if A111A <= 0
		replace va_ratio = 0 if va_ratio < 0 & !missing(va_ratio)
		replace va_ratio = 1 if va_ratio > 1 & !missing(va_ratio)

		keep clase_de_actividad va_ratio
		summ va_ratio, detail
		save "${SIMROOT}/raw/temp/`anioenigh'/va_por_clase_actividad.dta", replace
	}

	** 2.8. Merge jerárquico: VA ratio → registros de gasto **
	capture confirm file "${SIMROOT}/raw/temp/`anioenigh'/pre_iva_final.dta"
	if _rc != 0 {
		* Construir lookup tables jerárquicos (6→5→4→3→2 dígitos)
		use "${SIMROOT}/raw/temp/`anioenigh'/va_por_clase_actividad.dta", clear
		tostring clase_de_actividad, replace
		tempfile LU6 LU5 LU4 LU3 LU2
		forvalues n = 6(-1)2 {
			preserve
			gen code = substr(clase_de_actividad, 1, `n')
			bys code: egen double va_mean = mean(va_ratio)
			duplicates drop code, force
			keep code va_mean
			save `LU`n'', replace
			restore
		}

		use "${SIMROOT}/raw/temp/`anioenigh'/pre_iva.dta", clear

		forvalues k = 1/6 {
			gen double va`k' = .
			foreach n in 6 5 4 3 2 {
				tostring clase_de_actividad`k', replace force
				gen code = substr(clase_de_actividad`k', 1, `n')
				merge m:1 code using `LU`n'', keep(master match) nogen
				replace va`k' = va_mean if missing(va`k') & !missing(va_mean)
				drop code va_mean
			}
		}

		save "${SIMROOT}/raw/temp/`anioenigh'/pre_iva_final.dta", replace
	}

	use "${SIMROOT}/raw/temp/`anioenigh'/pre_iva_final.dta", clear
	order folioviv-porcentaje_ieps201 *1 *2 *3 *4 *5 *6
	if `anioenigh' >= 2024 drop clave // Quedarnos con la clave_2018

	** 2.9b Lo que la ENIGH registra y el SCN no cuenta como P.3 de los hogares (8.16b; CUAD-1 §8 bis fichas 5 y 6, FLAG 33; firma §B) **
	*   gastotarjetas (claves TB01-TB16, sin tipo_gasto): el pago de la tarjeta es un flujo financiero, no el consumo del trimestre: fuera.
	*   G2 (regalos otorgados a otros hogares): el consumo se cuenta una sola vez, en quien lo recibe (G5): fuera.
	*   Los montos se declaran (escalares ExpTarjetas, ExpRegalosG2) y van a la nota del cuadro de anclas de §4. En pre_iva_final.dta las filas de
	*   gastotarjetas traen el factor vacio: se toma de concentrado solo para medirlas. *
	g byte exp_tarjeta = substr(clave_2018, 1, 2) == "TB"
	g byte exp_g2 = tipo_gasto == "G2"
	preserve
	keep if exp_tarjeta | exp_g2
	drop factor
	merge m:1 (folioviv foliohog) using "${SIMROOT}/raw/ENIGH/`anioenigh'/concentrado.dta", nogen keepus(factor) keep(master match)
	capture rename factor_hog factor
	tabstat gasto_anual if exp_tarjeta [aw=factor], stat(sum) save
	local exp_tarjetas = r(StatTotal)[1,1]
	tabstat gasto_anual if exp_g2 [aw=factor], stat(sum) save
	local exp_g2 = r(StatTotal)[1,1]
	restore
	escalar mxn ExpTarjetas = `exp_tarjetas'
	escalar mxn ExpRegalosG2 = `exp_g2'
	noisily _log aviso, tipo(FLAG) num(33) texto("gasto con tarjeta TB01-TB16 fuera de la base del consumo: `=strtrim(string(`exp_tarjetas'/1e9, "%12.3fc"))' bn MXN `anioenigh', flujo financiero") ref("CUAD-1 §8 bis")
	noisily _log aviso, tipo(Nota) texto("regalos otorgados G2 fuera de la base: `=strtrim(string(`exp_g2'/1e9, "%12.3fc"))' bn; el consumo se cuenta en quien lo recibe, G5") ref("CUAD-1 ficha 5")
	drop if exp_tarjeta | exp_g2
	drop exp_tarjeta exp_g2

	egen proporcion = rowmean(va1 va2 va3 va4 va5 va6)

	summ proporcion [aw=factor]
	replace proporcion = r(mean) if missing(proporcion)

	* Mostrar proporción promedio ponderada
	noisily _log linea "Proporción de valor agregado del último eslabón (VACB/PBT, Censo Económico): `=strtrim(string(r(mean), "%8.4f"))'"

	** 2.9. Estado y ubicación geográfica ***
	g estado = substr(folioviv,1,2)
	replace ubica_geo = substr(ubica_geo,1,5)
	destring ubica_geo estado, replace

	* Frontera norte *
	g front = estado==2 | estado==3 ///
		| ubica_geo==05002 | ubica_geo==05012 | ubica_geo==05013 | ubica_geo==05014 ///
		| ubica_geo==05022 | ubica_geo==05023 | ubica_geo==05025 | ubica_geo==05038 ///
		| ubica_geo==08005 | ubica_geo==08015 | ubica_geo==08028 | ubica_geo==08035 ///
		| ubica_geo==08037 | ubica_geo==08042 | ubica_geo==08052 | ubica_geo==08053 ///
		| ubica_geo==19005 | ubica_geo==26002 | ubica_geo==26004 | ubica_geo==26017 ///
		| ubica_geo==26019 | ubica_geo==26027 | ubica_geo==26035 | ubica_geo==26039 ///
		| ubica_geo==26043 | ubica_geo==26048 | ubica_geo==26055 | ubica_geo==26059 ///
		| ubica_geo==26060 | ubica_geo==26070 | ubica_geo==28007 | ubica_geo==28014 ///
		| ubica_geo==28015 | ubica_geo==28022 | ubica_geo==28024 | ubica_geo==28025 ///
		| ubica_geo==28027 | ubica_geo==28032 | ubica_geo==28033 | ubica_geo==28040 ///
	/* Frontera sur */ ///
		| estado== 23      | ubica_geo==04010 | ubica_geo==04011 | ubica_geo==07006 ///
		| ubica_geo==07010 | ubica_geo==07015 | ubica_geo==07019 ///
		| ubica_geo==07034 | ubica_geo==07035 | ubica_geo==07036 | ubica_geo==07041 ///
		| ubica_geo==07053 | ubica_geo==07055 | ubica_geo==07057 ///
		| ubica_geo==07059 | ubica_geo==07052 | ubica_geo==07070 | ubica_geo==07087 ///
		| ubica_geo==07089 | ubica_geo==07099 | ubica_geo==07102 ///
		| ubica_geo==07105 | ubica_geo==07114 | ubica_geo==07115 | ubica_geo==07116 ///
		| ubica_geo==20079 | ubica_geo==27001 | ubica_geo==27017


	** 2.10. Variables auxiliares **
	g letra = substr(clave,1,1)
	g letra2 = substr(clave,2,1)
	replace letra2 = "" if letra2 != "R" & letra2 != "B"

	g num = substr(clave,2,.) if letra2 != "R" & letra2 != "B"
	replace num = substr(clave,3,.) if letra2 == "R" | letra2 == "B"
	destring num, replace
	replace num = num - 900 if letra == "T" & (letra2 != "R" & letra2 != "B")

	g rentab = tenencia == "1" | tenencia == "3"


	** 2.11. SNA categorías **
	g categ = 1 if letra == "A" & num <= 214
	replace categ = 1 if letra == "T" & num == 1
	replace categ = 2 if letra == "A" & num >= 215 & num <= 222
	replace categ = 3 if letra == "A" & num >= 223 & num <= 238
	replace categ = 4 if letra == "A" & num >= 239 & num <= 241
	replace categ = 5 if letra == "H" & num <= 83
	replace categ = 5 if letra == "T" & num == 9
	replace categ = 6 if letra == "H" & num >= 84 & num <= 122
	replace categ = 7 if letra == "G" & num <= 4
	replace categ = 7 if letra == "G" & num >= 101
	replace categ = 7 if letra == "R" & num >= 3 & num <= 4
	replace categ = 8 if letra == "R" & num == 2
	replace categ = 9 if letra == "R" & num == 1
	replace categ = 10 if letra == "G" & num >= 5 & num <= 16
	replace categ = 10 if letra == "R" & num == 13
	replace categ = 10 if letra == "K"
	replace categ = 10 if letra == "T" & num == 7
	replace categ = 10 if letra == "T" & num == 12
	replace categ = 11 if letra == "J"
	replace categ = 11 if letra == "T" & num == 11
	replace categ = 12 if letra == "M" & num >= 7 & num <= 9
	replace categ = 13 if letra == "F" & num >= 7
	replace categ = 13 if letra == "R" & num == 12
	replace categ = 14 if letra == "B"
	replace categ = 14 if letra == "M" & num <= 6
	replace categ = 14 if letra == "T" & num == 2
	replace categ = 14 if letra == "T" & num == 14
	replace categ = 15 if letra == "F" & num <= 6
	replace categ = 15 if letra == "R" & num >= 5 & num <= 11
	replace categ = 15 if letra == "T" & num == 6
	replace categ = 16 if letra == "E" & num >= 8
	replace categ = 16 if letra == "L" & num <= 26
	replace categ = 16 if letra == "T" & num == 5
	replace categ = 16 if letra == "T" & num == 13
	replace categ = 17 if letra == "E" & num <= 7
	replace categ = 18 if letra == "A" & num >= 242 & num <= 247
	replace categ = 18 if letra == "N" & num >= 3 & num <= 5
	replace categ = 19 if letra == "C"
	replace categ = 19 if letra == "D"
	replace categ = 19 if letra == "H" & num >= 123
	replace categ = 19 if letra == "I"
	replace categ = 19 if letra == "L" & num >= 27
	replace categ = 19 if letra == "M" & num >= 10 & num <= 18
	replace categ = 19 if letra == "N" & num <= 2
	replace categ = 19 if letra == "N" & num >= 6
	replace categ = 19 if letra == "T" & num == 3
	replace categ = 19 if letra == "T" & num == 4
	replace categ = 19 if letra == "T" & num == 8
	replace categ = 19 if letra == "T" & num == 10
	replace categ = 19 if letra == "T" & num == 15
	replace categ = 19 if categ == .

	* 8.16b (CUAD-1 §8 bis ficha 6; firma §B): COICOP 04.5 y D.59. Gas LP, combustibles solidos y otros combustibles (G009-G016) y gas natural
	* (R003) son «electricidad, gas y otros combustibles» (BIE 724614), no articulos para el hogar ni alquileres: TT<Elec> 4.91 media clasificacion,
	* no subreporte. Predial (R004) y tenencia (R012) son D.59 (impuestos corrientes sobre la propiedad), no consumo: salen de la base y quedan
	* declarados (escalares ExpPredialD59, ExpTenenciaD59); la LIF los lleva en OTROSK (per capita en el fiscal). *
	replace categ = 9 if letra == "G" & num >= 9 & num <= 16
	replace categ = 9 if letra == "R" & num == 3
	g byte exp_d59 = letra == "R" & (num == 4 | num == 12)
	tabstat gasto_anual if exp_d59 & num == 4 [aw=factor], stat(sum) save
	local exp_predial = r(StatTotal)[1,1]
	tabstat gasto_anual if exp_d59 & num == 12 [aw=factor], stat(sum) save
	local exp_tenencia = r(StatTotal)[1,1]
	escalar mxn ExpPredialD59 = `exp_predial'
	escalar mxn ExpTenenciaD59 = `exp_tenencia'
	noisily _log aviso, tipo(Nota) texto("predial R004 `=strtrim(string(`exp_predial'/1e9, "%12.3fc"))' y tenencia R012 `=strtrim(string(`exp_tenencia'/1e9, "%12.3fc"))' bn fuera del consumo: D.59, viven en OTROSK de la LIF") ref("CUAD-1 ficha 6")
	drop if exp_d59
	drop exp_d59

	label define categ2 1 "Alimentos" /// Alimentos
		2 "Bebidas no alcohólicas" /// Bebidas no alcohólicas
		3 "Bebidas alcohólicas" /// Bebidas alcohólicas
		4 "Tabaco" /// Tabaco
		5 "Prendas de vestir" /// Prendas de vestir
		6 "Calzado" /// Calzado
		7 "Alquileres y vivienda" /// Alquileres y vivienda
		8 "Agua" /// Agua
		9 "Electricidad" /// Electricidad
		10 "Artículos para el hogar" /// Artículos para el hogar
		11 "Salud" /// Salud
		12 "Adquisición de vehículos" /// Adquisición de vehículos
		13 "Transporte personal" /// Transporte personal
		14 "Servicios de transporte" /// Servicios de transporte
		15 "Comunicaciones" /// Comunicaciones
		16 "Recreación y cultura" /// Recreación y cultura
		17 "Educación" /// Educación
		18 "Restaurantes y hoteles" /// Restaurantes y hoteles
		19 "Otros diversos" // Otros diversos

	label define categ 1 "Alim" /// Alimentos
		2 "BebN" /// Bebidas no alcohólicas
		3 "BebA" /// Bebidas alcohólicas
		4 "Taba" /// Tabaco
		5 "Vest" /// Prendas de vestir
		6 "Calz" /// Calzado
		7 "Alqu" /// Alquileres efectivos
		8 "Agua" /// `Agua'
		9 "Elec" /// Electricidad
		10 "HogaT" /// Artículos para el hogar
		11 "SaluT" /// Salud
		12 "Vehi" /// Adquisición de vehículos
		13 "FTra" /// Transporte personal
		14 "STra" /// Servicios de transporte
		15 "ComuT" /// Comunicaciones
		16 "RecrT" /// Recreación y cultura
		17 "EducT" /// Educación
		18 "RestT" /// Restaurantes y hoteles
		19 "DiveT" // Otros diversos
	label values categ categ


	** 2.12 IVA categorías **
	g categ_iva = 1 if letra == "A"
	replace categ_iva = 2 if letra == "A" & ((num >= 198 & num <= 202) | (num >= 243 & num <= 247))
	replace categ_iva = 3 if letra == "A" & ((num == 1 | num == 4 | num == 9 | num == 10 | num == 12 | num == 13 | num == 19 | num == 25 | num == 34 | num == 38 | num == 42 | num == 48 | num == 55 | num == 57 | num == 58 | num == 59 | num == 62 | num == 66 | num == 75 | num == 85 | num == 87 | num == 91 | num == 93 | num == 95 | num == 102 | num == 112 | num == 115 | num == 116 | num == 117 | num == 118 | num == 124 | num == 137 | num == 154 | num == 158 | num == 160 | num == 166 | num == 173 | num == 200 | num == 215 | num == 220 | num == 243 | num == 244 | num == 245 | num == 202))
	replace categ_iva = 4 if (letra == "L" & (num == 029)) | (letra == "A" & (num == 213 | num == 214))
	replace categ_iva = 5 if letra == "J" & ((num == 9 | (num >= 20 & num <= 38) | num == 42 | (num >= 44 & num <= 59) | num == 64))
	replace categ_iva = 6 if letra == "B"
	replace categ_iva = 7 if (letra == "M" & num == 1) | (letra == "B" & num == 6)
	replace categ_iva = 8 if letra == "E" & (num >= 1 & num <= 7)
	replace categ_iva = 9 if letra == "G" & ((num >= 1 & num <= 3) | (num >= 101 & num <= 106))
	replace categ_iva = 10 if letra == "D" & num == 15
	replace categ_iva = 11 if categ_iva == . //& tiva != .

	label define categ_iva 1 "Alimentos" ///
		2 "FueraHog" ///
		3 "CanastaBas" ///
		4 "Mascotas" ///
		5 "Medicinas" ///
		6 "TransporteLoc" ///
		7 "TransporteFor" ///
		8 "Educación" ///
		9 "Alquiler" ///
		10 "Mujer" ///
		11 "Otros"
	label values categ_iva categ_iva

	label define categ_iva2 1 "Otros alimentos" ///
		2 "Fuera del hogar" ///
		3 "Canasta básica" ///
		4 "Mascotas" ///
		5 "Medicinas" ///
		6 "Transporte local" ///
		7 "Transporte foráneo" ///
		8 "Educación" ///
		9 "Alquiler y vivienda" ///
		10 "Productos femeninos" ///
		11 "Otros gastos"

	** 2.13 IEPS categorías **
	g categ_ieps = 1 if (letra == "A" & (num == 224))
	replace categ_ieps = 2 if (letra == "A" & num == 225 | num == 226 | num == 227 | num == 228 | num == 231 | num == 232 | num == 234)
	replace categ_ieps = 3 if (letra == "A" & (num == 223 | num == 229 | num == 230 | num == 233 | num == 235 | num == 236 | num == 237 | num == 238))
	replace categ_ieps = 4 if (letra == "A" & (num >= 239 & num <= 241))
	replace categ_ieps = 5 if (letra == "E" & num == 031)
	replace categ_ieps = 6 if (letra == "F" & (num >= 1 & num <= 3)) ///
		| (letra == "K" & num == 3) | (letra == "R" & ((num >= 5 & num <= 7) | (num >= 9 & num <= 11)))
	replace categ_ieps = 7 if (letra == "A" & num == 221)
	replace categ_ieps = 8 if (letra == "A" & (num == 219 | num == 220))
	replace categ_ieps = 9 if (letra == "A" & (num == 106 | (num >= 180 & num <= 182) | (num >= 205 & num <= 209)))
	replace categ_ieps = 10 if (letra == "G" & (num >= 9 & num <= 11))
	replace categ_ieps = 11 if (letra == "F" & (num >= 7 & num <= 9))
	replace categ_ieps = 12 if categ_ieps == .

	label define categ_ieps 1 "Cervezas" ///
		2 "Alcohol 20" ///
		3 "Alcohol 20+" ///
		4 "Tabaco" ///
		5 "Juegos" ///
		6 "Telecom" ///
		7 "BebidasEner" ///
		8 "BebidasSabor" ///
		9 "AltoContCal" ///
		10 "Combustibles" ///
		11 "Gasolinas" ///
		12 "Sin IEPS"
	label values categ_ieps categ_ieps


	** 2.15. Informalidad **
	g informal = lugar_comp == "01" | lugar_comp == "02" | lugar_comp == "03" | lugar_comp == "17"	// Informalidad


	** 2.16. Cálculo de la cantidad anual **
	replace cantidad = cantidad*365 if frecuencia == "1"
	replace cantidad = cantidad*52 if frecuencia == "2"
	replace cantidad = cantidad*12 if frecuencia == "3"
	replace cantidad = cantidad*4 if frecuencia == "4"
	replace cantidad = 1 if frecuencia == "5" | frecuencia == "6" 
	replace cantidad = 1 if frecuencia == "0" | frecuencia == ""
	replace cantidad = 1 if gasto_anual > 0 & cantidad == 0
	replace cantidad = 1 if letra == "E" & (num >= 1 & num <= 7) // Educación


	** 2.18. Guardar pre-base **
	capture drop __*
	compress
	sort folioviv foliohog numren clave

	save "${SIMROOT}/raw/temp/`anioenigh'/preconsumption.dta", replace


	** 2.19. Deducciones personales del ISR **
	collapse (sum) deduc_*, by(folioviv foliohog numren)
	replace numren = "01"
	collapse (sum) deduc_*, by(folioviv foliohog numren)

	capture mkdir "${SIMROOT}/master/`anioenigh'"
	save "${SIMROOT}/master/`anioenigh'/deducciones.dta", replace
}





********************************************************
***                                                  ***
***  3. Integración consumo de hogares + individuos  ***
***                                                  ***
********************************************************
foreach categ in categ categ_iva categ_ieps {
	capture confirm file "${SIMROOT}/master/`anioenigh'/consumption_`categ'_pc.dta"
	if _rc != 0 {

		** 3.1 Consumo de los individuos **
		use "${SIMROOT}/raw/temp/`anioenigh'/preconsumption.dta", clear
		drop if gasto_anual == 0 | numren == ""
		collapse (sum) gas_ind=gasto_anual cant_ind=cantidad (mean) prop=proporcion, by(folioviv foliohog numren `categ')

		decode `categ', gen(categs)
		replace categs = strtoname(categs)
		drop `categ'

		levelsof categs, local(categs)

		* Toda categoría observada en la muestra debe existir para todo individuo:
		* 0 si no la consumió, y prop = media global si no tiene observación. Antes
		* se lograba con reshape wide -> long -> wide (el long creaba las celdas
		* faltantes); aquí se crea la misma rejilla en un solo reshape. La media de
		* prop es idéntica: el reshape long solo agregaba filas con prop missing.
		tabstat prop, stat(mean) f(%20.3fc) save
		tempname propmean
		scalar `propmean' = r(StatTotal)[1,1]	// escalar, no local: conserva la precisión double
		reshape wide gas_ind cant_ind prop, i(folioviv foliohog numren) j(categs) string
		foreach v of varlist gas_ind* cant_ind* {
			replace `v' = 0 if `v' == .
		}
		foreach v of varlist prop* {
			replace `v' = scalar(`propmean') if `v' == .
		}

		tempfile gastoindividuos
		save `gastoindividuos'


		** 3.2 Consumo de los hogares **
		use "${SIMROOT}/raw/temp/`anioenigh'/preconsumption.dta", clear
		drop if gasto_anual == 0 | numren != ""
		collapse (sum) gas_hog=gasto_anual cant_hog=cantidad (mean) prop=proporcion, by(folioviv foliohog `categ')

		decode `categ', gen(categs)
		replace categs = strtoname(categs)
		drop `categ'

		levelsof categs, local(categs)

		* Misma rejilla completa hogar x categoría que en 3.1 (ver nota ahí)
		tabstat prop, stat(mean) f(%20.3fc) save
		tempname propmean
		scalar `propmean' = r(StatTotal)[1,1]	// escalar, no local: conserva la precisión double
		reshape wide gas_hog cant_hog prop, i(folioviv foliohog) j(categs) string
		foreach v of varlist gas_hog* cant_hog* {
			replace `v' = 0 if `v' == .
		}
		foreach v of varlist prop* {
			replace `v' = scalar(`propmean') if `v' == .
		}


		** 3.3 Consumo de los hogares + individuos **
		merge 1:m (folioviv foliohog) using "${SIMROOT}/raw/ENIGH/`anioenigh'/poblacion.dta", ///
			nogen keepus(numren edad sexo) keep(master match)
		merge m:1 (folioviv foliohog) using "${SIMROOT}/raw/ENIGH/`anioenigh'/concentrado.dta", ///
			nogen keepus(factor) keep(master match)
		egen tot_integ = count(factor), by(folioviv foliohog)
		egen long hhid = group(folioviv foliohog)	// id numérico del hogar para perfilpc (se borra antes de guardar)

		foreach k of varlist *hog* {
			if "`k'" == "foliohog" | "`k'" == "factor_hog" continue
			replace `k' = `k'/tot_integ
		}

		merge 1:1 (folioviv foliohog numren) using `gastoindividuos', nogen keepus(*_ind* prop*) keep(master match)
		capture merge 1:1 (folioviv foliohog numren) using "${SIMROOT}/master/`anioenigh'/households.dta", ///
			nogen keepus(decil) keep(master match)
		if _rc != 0 {
			local nohouseholds = "nohouseholds"
		}

		** 3.4 Gasto per cápita **
		noisily _log linea "Categorías del consumo: `categs'"
		local convlog				// bitácora de convergencia de perfilpc: variable, iteraciones, convergió, criterio
		foreach k of local categs {
			foreach vars in cant_ gas_ {
				* Categorías *
				if "`vars'" == "gas_" {
					local title = "Gasto"
				}
				if "`vars'" == "cant_" {
					local title = "Cantidad"
				}

				* Categorías: Consumo *
				if "`k'" == "Alim" {
					local label = "Alimentos"
				}
				if "`k'" == "BebN" {
					local label = "Bebidas no alcohólicas"
				}
				if "`k'" == "BebA" {
					local label = "Bebidas alcohólicas"
				}
				if "`k'" == "Taba" {
					local label = "Tabaco"
				}
				if "`k'" == "Vest" {
					local label = "Prendas de vestir"
				}
				if "`k'" == "Calz" {
					local label = "Calzado"
				}
				if "`k'" == "Alqu" {
					local label = "Alquileres efectivos"
				}
				if "`k'" == "Agua" {
					local label = "Agua"
				}
				if "`k'" == "Elec" {
					local label = "Electricidad"
				}
				if "`k'" == "HogaT" {
					local label = "Artículos para el hogar"
				}
				if "`k'" == "SaluT" {
					local label = "Salud"
				}
				if "`k'" == "Vehi" {
					local label = "Adquisición de vehículos"
				}
				if "`k'" == "FTra" {
					local label = "Transporte personal"
				}
				if "`k'" == "STra" {
					local label = "Servicios de transporte"
				}
				if "`k'" == "ComuT" {
					local label = "Comunicaciones"
				}
				if "`k'" == "RecrT" {
					local label = "Recreación y cultura"
				}
				if "`k'" == "EducT" {
					local label = "Educación"
				}
				if "`k'" == "RestT" {
					local label = "Restaurantes y hoteles"
				}
				if "`k'" == "DiveT" {
					local label = "Otros diversos"
				}

				* Categorías: IVA *
				if "`k'" == "Alimentos" {
					local label = "Otros alimentos"
				}
				if "`k'" == "FueraHog" {
					local label = "Fuera del hogar"
				}
				if "`k'" == "CanastaBas" {
					local label = "Canasta básica"
				}
				if "`k'" == "Mascotas" {
					local label = "Mascotas"
				}
				if "`k'" == "Medicinas" {
					local label = "Medicinas"
				}
				if "`k'" == "TransporteLoc" {
					local label = "Transporte local"
				}
				if "`k'" == "TransporteFor" {
					local label = "Transporte foráneo"
				}
				if "`k'" == "Educación" {
					local label = "Educación"
				}
				if "`k'" == "Alquiler" {
					local label = "Alquiler y vivienda"
				}
				if "`k'" == "Mujer" {
					local label = "Productos femeninos"
				}
				if "`k'" == "Otros" {
					local label = "Otros gastos"
				}

				* Categorías: IEPS *
				if "`k'" == "Cervezas" {
					local label = "Cervezas"
				}
				if "`k'" == "Alcohol_20" {
					local label = "Alcohol 20"
				}
				if "`k'" == "Alcohol_20_" {
					local label = "Alcohol 20+"
				}
				if "`k'" == "Tabaco" {
					local label = "Tabaco"
				}
				if "`k'" == "Juegos" {
					local label = "Juegos y sorteos"
				}
				if "`k'" == "Telecom" {
					local label = "Telecomunicaciones"
				}
				if "`k'" == "BebidasEner" {
					local label = "Bebidas energéticas"
				}
				if "`k'" == "BebidasSabor" {
					local label = "Bebidas saborizadas"
				}
				if "`k'" == "AltoContCal" {
					local label = "Alto contenido calórico"
				}
				if "`k'" == "Combustibles" {
					local label = "Combustibles"
				}
				if "`k'" == "Gasolinas" {
					local label = "Gasolinas"
				}
				if "`k'" == "Sin_IEPS" {
					local label = "Sin IEPS"
				}


				* Gasto por hogar *
				capture replace `vars'hog`k' = 0 if `vars'hog`k' == .
				if _rc != 0 {
					g `vars'hog`k' = 0
				}
				quietly tabstat `vars'hog`k' [fw=factor], stat(sum) f(%20.0fc) save
				noisily _log linea "`vars'hog`k': Σ `=strtrim(string(r(StatTotal)[1,1]/1e9, "%14.3fc"))' bn"

				* Outliers *
				capture tabstat `vars'hog`k' if `vars'hog`k' != 0, stat(p99 p95) save
				if _rc != 0 {
					g hogar_outlier = 0
				}
				else {
					g hogar_outlier = `vars'hog`k' >= r(StatTotal)[1,1] & r(StatTotal)[1,1] != r(StatTotal)[2,1]
				}

				* Gasto por individuo *
				capture replace `vars'ind`k' = 0 if `vars'ind`k' == .
				if _rc != 0 {
					g `vars'ind`k' = 0
				}
				quietly tabstat `vars'ind`k' [fw=factor], stat(sum) f(%20.0fc) save
				noisily _log linea "`vars'ind`k': Σ `=strtrim(string(r(StatTotal)[1,1]/1e9, "%14.3fc"))' bn"

				* Outliers *
				capture tabstat `vars'ind`k' if `vars'ind`k' != 0, stat(p99 p95) save
				if _rc != 0 {
					g ind_outlier = 0
				}
				else {
					g ind_outlier = `vars'ind`k' >= r(StatTotal)[1,1] & r(StatTotal)[1,1] != r(StatTotal)[2,1]
				}

				g `vars'pc_`k' = `vars'hog`k' //+ `vars'ind`k'
				local label = "`title' en `label'"
				label var `vars'pc_`k' "`label'"

				* Perfil original *
				g o`vars'pc_`k' = `vars'pc_`k'
				label var o`vars'pc_`k' "`label' (original)"
				if "`nohouseholds'" == "" & "$nographs" != "nographs" {
					//noisily Perfiles ``vars'pc_`k'' [fw=factor] ///
					//	if ``vars'pc_`k'' != 0 & hogar_outlier == . & ind_outlier == ., ///
					//	aniope(`anioenigh')
					noisily Simulador o`vars'pc_`k' [fw=factor] ///
						if o`vars'pc_`k' != 0 & hogar_outlier == 0 & ind_outlier == 0, ///
						aniope(`anioenigh') ///
						title("`label'") reboot boot($bootstrap)
				}

				* Iteraciones: reparto intra-hogar por perfil edad-sexo (punto fijo en Mata,
				* perfilpc.ado). Hasta v8.4.x: 25 iteraciones fijas con redondeo a centavos
				* (220 tabstat + 440 replace por iteración, ~7 min por variable); ese modo
				* sigue disponible con `legacy iter(25)`. Ahora: redondeo a 6 cifras
				* significativas e iteración hasta que la fracción del gasto que cambia de
				* celda edad-sexo baja de 1e-6 (cada variable itera lo que necesita; 100-600).
				* equiv() conserva la variable equivalencias`k' que dejaba el bloque anterior.
				* Nota metodológica en el encabezado de perfilpc.ado. Las gráficas (pirámide
				* per cápita, pirámide del gasto total, convergencia) quedan en memoria y en
				* users/$id/graphs/ para seguir el reparto iteración a iteración.
				local pgraf
				if "$nographs" != "nographs" local pgraf grafica(`vars'`k'_`anioenigh') title("`label'")	// gráficas `vars'`k'_`anioenigh'_{pc,tot,conv}
				noisily perfilpc `vars'pc_`k', hogar(`vars'hog`k') integrantes(tot_integ) factor(factor) ///
					hhid(hhid) equiv(equivalencias`k') `pgraf'
				local convlog `"`convlog' "`vars'`k'" `=r(iter)' `=r(converged)' `=r(relL1)'"'
				replace `vars'pc_`k' = `vars'pc_`k' + `vars'ind`k'
				*noisily tabstat `vars'pc_`k' `vars'hog`k' `vars'ind`k' [fw=factor], stat(sum) f(%20.0fc)

				if "`nohouseholds'" == "" & "$nographs" != "nographs" {
					//noisily Perfiles `vars'pc_`k' [fw=factor] ///
					//	if `vars'pc_`k' != 0 & hogar_outlier == . & ind_outlier == ., ///
					//	aniope(`anioenigh') ///
					//	title(`title' en `k')
					noisily Simulador `vars'pc_`k' [fw=factor] ///
						if `vars'pc_`k' != 0 & hogar_outlier == 0 & ind_outlier == 0, ///
						aniope(`anioenigh') ///
						title("`label'") reboot boot($bootstrap)
				}
				capture g preci`k' = gas_pc_`k'/cant_pc_`k'
				capture drop *outlier
			}
			quietly tabstat preci`k' gas_pc_`k' cant_pc_`k' [fw=factor], stat(mean) f(%10.2fc) save
			noisily _log linea "`k': precio medio `=strtrim(string(r(StatTotal)[1,1], "%10.2fc"))', gasto per cápita `=strtrim(string(r(StatTotal)[1,2], "%10.2fc"))', cantidad per cápita `=strtrim(string(r(StatTotal)[1,3], "%10.2fc"))'"
		}

		** 3.4.1 Resumen de convergencia del reparto intra-hogar (una gráfica por grupo) **
		* Cuántas iteraciones necesitó cada variable para que la fracción del gasto que
		* cambia de celda edad-sexo bajara de la tolerancia; en rojo las que llegaron a
		* maxiter sin converger. Queda en memoria (conv_`categ'_`anioenigh') y en users/$id/graphs/.
		if "$nographs" != "nographs" {
			preserve
			clear
			local nconv : word count `convlog'
			qui set obs `=`nconv'/4'
			qui gen str32 variable = ""
			qui gen int iteraciones = .
			qui gen byte convergio = .
			qui gen double criterio = .
			forvalues r = 1/`=`nconv'/4' {
				qui replace variable    = `"`: word `=4*`r'-3' of `convlog''"' in `r'
				qui replace iteraciones = `: word `=4*`r'-2' of `convlog'' in `r'
				qui replace convergio   = `: word `=4*`r'-1' of `convlog'' in `r'
				qui replace criterio    = `: word `=4*`r'' of `convlog'' in `r'
			}
			qui gen int it_ok = iteraciones if convergio
			qui gen int it_no = iteraciones if !convergio
			qui count if !convergio
			local nno = r(N)
			if `nno' == 0 local notaconv "Todas las variables convergieron."
			else local notaconv "`nno' variable(s) sin converger: revisar su gr{c a'}fica _conv."
			graph hbar (asis) it_ok it_no, over(variable, sort(iteraciones) descending label(labsize(vsmall))) ///
				stack bar(1, color("255 153 0")) bar(2, color(cranberry)) ///
				ytitle("Iteraciones hasta converger") ///
				title("Convergencia del reparto intra-hogar: `categ', ENIGH `anioenigh'") ///
				subtitle("Criterio: fracci{c o'}n del gasto que cambia de celda edad-sexo {&le} 1e-6; perfil redondeado a 6 cifras significativas", size(small)) ///
				legend(order(1 "Convergi{c o'}" 2 "No convergi{c o'} (maxiter)") rows(1)) ///
				note("`notaconv'", size(vsmall)) ///
				name(conv_`categ'_`anioenigh', replace)
			qui graph export "${SIMROOT}/users/$id/graphs/conv_`categ'_`anioenigh'.png", replace name(conv_`categ'_`anioenigh')
			restore
		}

		** 3.5 Coeficientes de consumo por edades **
		g alfa = 1 if edad != .
		replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
		replace alfa = .4 if edad <= 4

		** Guardar pre-base individuos **
		capture drop __*
		drop hhid
		compress
		sort folioviv foliohog numren
		capture mkdir "${SIMROOT}/master/`anioenigh'"
		save "${SIMROOT}/master/`anioenigh'/consumption_`categ'_pc.dta", replace
	}
}





*****************************/
***                        ***
***  4. Aggregated values  ***
***                        ***
******************************
use "${SIMROOT}/master/`anioenigh'/consumption_categ_pc.dta", replace
merge m:1 (folioviv foliohog) using "${SIMROOT}/raw/ENIGH/`anioenigh'/concentrado.dta", nogen keepus(factor)
capture rename factor_hog factor
order folioviv foliohog numren
drop *_hog* *_ind*

egen gastpc = rsum(gas_pc*)
label var gastpc "Gasto total per cápita"

Gini gastpc, hogar(folioviv foliohog) factor(factor)
local gini_gastpc = r(gini_gastpc)
escalar pctpib ginigastopc = `gini_gastpc'

scalar MTot = 0
*local scnname = "Alim BebN BebA Taba Vest Calz Alqu Agua Elec HogaT SaluT Vehi FTra STra ComuT RecrT EducT RestT DiveT"
local scnname = "Agua Alim Alqu BebA BebN Calz ComuT DiveT EducT Elec FTra HogaT RecrT RestT STra SaluT Taba Vehi Vest"
tokenize `scnname'
local scnvalue = 1
foreach k of varlist prop* {
	local varname = substr("`k'",5,11)
	rename `k' prop`varname'
	local ``scnvalue'' = scalar(``scnvalue'')

	di in g "`varname' : ``scnvalue''"

	tabstat gas_pc_`varname' [aw=factor], stat(sum) f(%20.0fc) save
	scalar M``scnvalue'' = r(StatTotal)[1,1]
	escalar pctpib E``scnvalue''PIB = M``scnvalue''/`PIB'*100
	escalar pctpib S``scnvalue''PIB = ```scnvalue'''/`PIB'*100
	scalar E``scnvalue''PC = M``scnvalue''/`pobtotNacional'

	Gini gas_pc_`varname', hogar(folioviv foliohog) factor(factor)
	local gini``scnvalue'' = r(gini_gas_pc_`varname')
	escalar pctpib gini``scnvalue'' = `gini``scnvalue'''

	scalar MTot = MTot + M``scnvalue''
	local ++scnvalue
}
escalar pctpib ETotPIB = MTot/`PIB'*100
scalar ETotPC = MTot/`pobtotNacional'


* Cuadro de anclas al estandar §D (8.16b; _tabla_anclas.ado v2; catalogo 05_scripts/scn-cuentas.csv). Cada rubro se ancla a una serie del BIE
* (hogares + ISFLSH en territorio); Alqu = 724611 + 724612 (SCN.ado). Con consumo_ancla = p3_s14 el total se reancla a P.3 S.14 con un factor unico. *
local serie_Alim 724602
local serie_BebN 724603
local serie_BebA 724605
local serie_Taba 724606
local serie_Vest 724608
local serie_Calz 724609
local serie_Alqu 724611+724612
local serie_Agua 724613
local serie_Elec 724614
local serie_HogaT 724615
local serie_SaluT 724622
local serie_Vehi 724627
local serie_FTra 724628
local serie_STra 724629
local serie_ComuT 724630
local serie_RecrT 724634
local serie_EducT 724641
local serie_RestT 724647
local serie_DiveT 724650

** 4.1. Factores de escala **
* 8.16b (consumo_ancla = p3_s14; CUAD-1 §4 y §7): los 19 TT<k> conservan los relativos del BIE y UN factor TTp3 = (P.3 S.14 − compras netas) / ConHog
* reancla el total al sector hogares: Σ gas_pc_* + compras netas (ComprasN, BIE 724777, repartidas ∝ gasto en Households §12) = P.3 S.14 al peso.
* ConHog − P.3 S.14 − P.3 S.15 + compras netas = vintage BIE−CSI del consumo de residentes (fila de sector, CUAD-2). *
local ConHogS14 = .
local ConISFLSH = .
capture local ConHogS14 = scalar(ConHogS14)
capture local ConISFLSH = scalar(ConISFLSH)
local ComprasN = scalar(ComprasN)
scalar TTp3 = 1
if "$consumo_ancla" == "p3_s14" {
	if `ConHogS14' == . {
		noisily _log aviso, tipo(FLAG) texto("Expenditure: SCN no dejó ConHogS14 (P.3 S.14 de CSI_115); el consumo queda anclado a ConHog BIE (conhog)") ref("CUAD-1 §4.0") rojo
		global consumo_ancla "conhog"
	}
	else scalar TTp3 = (`ConHogS14' - `ComprasN')/`ConHog'
}
scalar MMTot = 0
foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec HogaT SaluT Vehi FTra STra ComuT RecrT EducT RestT DiveT {
	scalar TT`k' = (M`k'/``k'')^(-1)
	scalar Dif`k' = ((M`k'/``k'')-1)*100
	replace gas_pc_`k' = gas_pc_`k'*scalar(TT`k')*scalar(TTp3)
	escalar pct TT`k' = (M`k'/``k'')^(-1)

	tabstat gas_pc_`k' [aw=factor], stat(sum) f(%20.0fc) save
	scalar MM`k' = r(StatTotal)[1,1]
	escalar pctpib EE`k'PIB = MM`k'/`PIB'*100
	scalar EE`k'PC = MM`k'/`pobtotNacional'

	scalar MMTot = MMTot + MM`k'
}
escalar pctpib EETotPIB = MMTot/`PIB'*100
scalar EETotPC = MMTot/`pobtotNacional'
escalar pct TTConHog = (MTot/`ConHog')^(-1)
escalar pct TTp3 = scalar(TTp3)
scalar ConsAncla = MMTot			// Σ gas_pc_* anclado (ConHog × TTp3): la base a la que §5 y §6 reescalan el micro del IVA y del IEPS
if "$consumo_ancla" == "p3_s14" {
	escalar mxn ExpCprivS14 = MMTot + `ComprasN'
	escalar mxn ExpVintageCons = `ConHog' + `ComprasN' - `ConHogS14' - `ConISFLSH'
}

** 4.2 Cuadro de anclas (estandar §D) y gates **
local nota_fuera ""
capture confirm scalar ExpTarjetas
* log legible: la expansión `: di scalar(Exp*)' ocurre antes de evaluar el if de la misma línea e imprimía «ExpTarjetas not found» (x4) en la ruta con cache; con llaves solo se expande si existen *
if _rc == 0 {
	local nota_fuera "Fuera de la base del consumo (8.16b): gasto con tarjeta TB01-TB16 `: di %14.3fc scalar(ExpTarjetas)/1e9' (flujo financiero, FLAG 33); regalos otorgados G2 `: di %14.3fc scalar(ExpRegalosG2)/1e9' (el consumo se cuenta en quien recibe, G5); predial R004 `: di %14.3fc scalar(ExpPredialD59)/1e9' y tenencia R012 `: di %14.3fc scalar(ExpTenenciaD59)/1e9' (D.59, en OTROSK de la LIF). MXN `anioenigh', miles de millones"
}
else local nota_fuera "Base del consumo con la cache consumption_*_pc.dta ya construida: gasto con tarjeta (FLAG 33), regalos G2 y predial/tenencia (D.59) fuera desde 8.16b; los montos se imprimen al reconstruir preconsumption.dta"
_tabla_anclas clear
foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec HogaT SaluT Vehi FTra STra ComuT RecrT EducT RestT DiveT {
	_tabla_anclas add, codigo(`serie_`k'') sector("S.14+S.15") fuente("BIE `serie_`k'' · asset") valor(``k'') variable(gas_pc_`k') motor(M`k') gini(gini`k')
}
_tabla_anclas add, codigo(724600) sector("S.14+S.15") fuente("BIE 724600 · asset") valor(`ConHog') variable(gastpc) motor(MTot) gini(ginigastopc) sep nota("Σ de los 19 rubros = ConHog al peso; TT<k> = celda / Σ motor; Σ motor = Σ (gas_hog + gas_ind) · factor tras perfilpc, sin deflactar (FLAG 20 cerrado en 8.16b). TTConHog = `: di %8.4f scalar(TTConHog)'")
if "$consumo_ancla" == "p3_s14" {
	_tabla_anclas add, codigo(724777) sector("S.14+S.15") fuente("BIE 724777 · asset") valor(`ComprasN') variable(gasto_anualComprasN) nota("compras netas de residentes fuera del pais menos de no residentes dentro; Households §12 las reparte ∝ gasto total")
	_tabla_anclas add, codigo(P.3) sector(S.15) fuente("CSI_118 · f.166 U/A") valor(-`ConISFLSH') variable("(fila de sector)") nota("consumo de las ISFLSH, dentro de ConHog BIE: fila de sector (CUAD-2), no consumo de personas")
	_tabla_anclas add, codigo(—) rotulo("Vintage BIE vs CSI del consumo de residentes") sector("S.14") fuente("BIE − CSI") valor(-scalar(ExpVintageCons)) variable("(fila de sector)") nota("ConHog + compras netas − P.3 S.14 − P.3 S.15: diferencia de vintage entre el BIE y los cuadros por sector, declarada")
	_tabla_anclas add, codigo(P.3) sector(S.14) fuente("CSI_115 · f.166 U/A") valor(`ConHogS14') variable("Σ gas_pc_* + compras netas") motor(scalar(ExpCprivS14)) sep nota("consumo_ancla = p3_s14: factor unico TTp3 = (P.3 S.14 − compras netas) / ConHog = `: di %8.6f scalar(TTp3)' sobre los 19 rubros; los relativos TT<k> se conservan")
	_tabla_anclas gate, texto("Σ Cpriv = Σ gas_pc_* anclado + compras netas = P.3 S.14") a(scalar(ExpCprivS14)) b(`ConHogS14')
}
_tabla_anclas gate, texto("Σ gas_pc_* anclado = ConHog × TTp3") a(MMTot) b(`ConHog'*scalar(TTp3))
noisily _tabla_anclas print, motor titulo("Anclas del consumo: BIE por finalidad, hogares + ISFLSH, y P.3 S.14, ENIGH `anioenigh'") sello("$scn_sello") unidad("MXN `anioenigh'") nota(`"`nota_fuera'"') ref("CUAD-1 §4.0")
if "$TA_GATES_OK" != "1" noisily _log aviso, tipo(GATE) texto("Expenditure: el consumo anclado no cierra a 1e-9 (ver el cuadro)") rojo


** 4.3. Guardar base **
if `c(version)' > 13.1 {
	saveold "${SIMROOT}/master/`anioenigh'/expenditures.dta", replace version(13)
}
else {
	save "${SIMROOT}/master/`anioenigh'/expenditures.dta", replace
}




*************/
***        ***
*** 5. IVA ***
***        ***
**************
if `anioenigh' >= 2014 {
	matrix IVAT = (16 \     ///  1  Tasa general 
		1  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
		2  \     ///  3  Alquiler, idem
		1  \     ///  4  Canasta basica, idem
		2  \     ///  5  Educacion, idem
		3  \     ///  6  Consumo fuera del hogar, idem
		3  \     ///  7  Mascotas, idem
		1  \     ///  8  Medicinas, idem
		1  \     ///  9  Toallas sanitarias, idem
		3  \     /// 10  Otros, idem
		2  \     /// 11  Transporte local, idem
		3  \     /// 12  Transporte foraneo, idem
		7.77)   //  13  Evasion e informalidad IVA, input[0-100]
}

use "${SIMROOT}/master/`anioenigh'/consumption_categ_iva_pc.dta", clear
merge m:1 (folioviv foliohog) using "${SIMROOT}/raw/ENIGH/`anioenigh'/concentrado.dta", nogen keepus(factor) keep(master match)
capture rename factor_hog factor
order folioviv foliohog numren
drop *_hog* *_ind*

*merge 1:1 (folioviv foliohog numren) using "${SIMROOT}/01_raw/CONEVAL/2022/Base final/pobreza_20.dta", nogen keepus(decil)
reshape long gas_pc_ cant_pc_ prop, i(folioviv foliohog numren) j(categs) string


** 5.1. Cálculo de precios (8.16b: la base micro se reescala al consumo anclado de §4.1, ConsAncla = ConHog × TTp3) **
replace gas_pc_ = gas_pc_*scalar(ConsAncla)/MTot
replace cant_pc_ = cant_pc_*scalar(ConsAncla)/MTot
g precio = gas_pc_/cant_pc_
tabstat precio gas_pc_ cant_pc_ [aw=factor], f(%20.0fc) by(categs)


** 5.2. Cálculo del IVA **
capture drop IVA
g IVA = 0
levelsof categs, local(categs)
local j = 2
foreach k of local categs {
	if IVAT[`j',1] == 2 {
		replace IVA = IVA + precio*cant_pc_*prop*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	if IVAT[`j',1] == 3 {
		replace IVA = IVA + precio*cant_pc_*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	local ++j
}
tabstat IVA [aw=factor], stat(sum) f(%20.0fc) save
di in g "IVA Observado: " in y %20.0fc `IVA'

escalar pct IVAHHSPIB = r(StatTotal)[1,1]/`PIB'*100
escalar pct IVASCNPIB = `IVA'/`PIB'*100
escalar pct DifIVA = (scalar(IVAHHSPIB) - scalar(IVASCNPIB))/scalar(IVAHHSPIB)*100

Gini IVA, hogar(folioviv foliohog) factor(factor)
local gini_IVA = r(gini_IVA)
escalar pctpib giniIVA = `gini_IVA'


** 5.3. Display de resultados **
noisily _log cuadro clear
noisily _log cuadro col, titulo("Impuesto") flex
noisily _log cuadro col, titulo("Gini") fmt(%6.3f)
noisily _log cuadro col, titulo("ENIGH") fmt(%7.3f)
noisily _log cuadro col, titulo("Macro") fmt(%7.3f)
noisily _log cuadro col, titulo("Informalidad %") fmt(%7.1f)
noisily _log cuadro fila "IVA micro, Σ por categoría" "giniIVA" "scalar(IVAHHSPIB)" "scalar(IVASCNPIB)" "scalar(DifIVA)"
noisily _log cuadro print, titulo("C. IVA: base micro ENIGH vs recaudación LIF; informalidad = (ENIGH − macro) / ENIGH") unidad("% del PIB `anioenigh'") ref("runbook §9.6")

save "${SIMROOT}/master/`anioenigh'/categ_iva.dta", replace
collapse (sum) IVA, by(folioviv foliohog numren)
save "${SIMROOT}/master/`anioenigh'/consumption_categ_iva.dta", replace





*******************/
***              ***
***    6. IEPS   ***
*** (incompleto) ***
*******************
if `anioenigh' >= 2014 {
	matrix IEPST = (26.5	,		0 			\ /// Cervezas y licores
		30.0	,		0 			\ /// Alcohol 14+ a 20
		53.0	,		0 			\ /// Alcohol 20+
		8.0		,		0 			\ /// Alto contenido calórico
		25.0	,		0 			\ /// Bebidas energéticas
		0		,		1.5737		\ /// Bebidas saborizadas
		0		,		19.8607		\ /// Combustibles (diesel)
		30.0	,		0 			\ /// Juegos y sorteos
		160.0	,		0.6166		\ /// Tabaco y cigarros
		3.0		,		0 			) //  Telecomunicaciones
}

use "${SIMROOT}/master/`anioenigh'/consumption_categ_ieps_pc.dta", clear
drop gas_hog* cant_hog* gas_ind* cant_ind*

*merge 1:1 (folioviv foliohog numren) using "${SIMROOT}/01_raw/CONEVAL/2022/Base final/pobreza_20.dta", nogen keepus(decil)
reshape long gas_pc_ cant_pc_ prop, i(folioviv foliohog numren) j(categs) string


** 6.1. Cálculo de precios (8.16b: reescalado al consumo anclado de §4.1) **
g precio = gas_pc_/cant_pc_*scalar(ConsAncla)/MTot
*noisily tabstat precio gas_pc_ cant_pc_ [aw=factor], f(%20.0fc) by(categs)


** 6.2. Cálculo del IEPS **
** NOTA: El precio en ENIGH incluye IEPS e IVA. IEPS se aplica antes de IVA.
** Estructura: Precio_final = (Precio_base + IEPS) * (1 + IVA)
** Para extraer IEPS: primero quitar IVA, luego calcular IEPS sobre la base
capture drop IEPS
g IEPS = 0
levelsof categs, local(categs)
local j = 0
foreach k of local categs {
	local ++j
	if "`k'" == "Gasolinas" | "`k'" == "Sin_IEPS" {
		continue
	}
	else if "`k'" == "Alcohol" {
		* Tasa promedio de alcohol, quitando IVA (16%) del precio
		local tasa_ieps = (IEPST[`j',1]+IEPST[`j'+1,1]+IEPST[`j'+2,1])/3/100
		replace IEPS = IEPS + (precio*cant_pc_*prop/(1+0.16))*`tasa_ieps'/(1+`tasa_ieps') + IEPST[`j',2]*cant_pc_ if categs == "`k'"
		local j = `j' + 2
		continue
	}
	else {
		* IEPS ad valorem + cuota específica, quitando IVA del precio
		local tasa_ieps = IEPST[`j',1]/100
		replace IEPS = IEPS + (precio*cant_pc_*prop/(1+0.16))*`tasa_ieps'/(1+`tasa_ieps') + IEPST[`j',2]*cant_pc_ if categs == "`k'"
	}
}

tabstat IEPS [aw=factor], stat(sum) f(%20.0fc) save by(categs)

escalar pct IEPSNPHHSPIB = r(StatTotal)[1,1]/`PIB'*100
escalar pct IEPSNPSCNPIB = `IEPSNP'/`PIB'*100
escalar pct DifIEPSNP = (scalar(IEPSNPHHSPIB) - scalar(IEPSNPSCNPIB))/scalar(IEPSNPHHSPIB)*100

foreach k of local categs {
	local j = 1
	while "`=r(name`j')'" != "`k'" {
		local ++j
	}
	matrix IEPS`k' = r(Stat`j')
	local name`k' = "`=r(name`j')'"
}
foreach k of local categs {
	Gini IEPS if categs == "`k'", hogar(folioviv foliohog) factor(factor)
	local gini_ieps`k' = r(gini_IEPS)
	scalar gini_ieps`k' = `gini_ieps`k''
}

Gini IEPS, hogar(folioviv foliohog) factor(factor)
local giniIEPS = r(gini_IEPS)
escalar pctpib giniIEPS = `giniIEPS'

** 6.3. Display de resultados (8.16b: la columna es la diferencia micro vs macro, no «informalidad»: el micro esta incompleto) **
noisily _log cuadro clear
noisily _log cuadro col, titulo("Categoría") flex
noisily _log cuadro col, titulo("Gini") fmt(%6.3f)
noisily _log cuadro col, titulo("ENIGH") fmt(%7.3f)
noisily _log cuadro col, titulo("Macro") fmt(%7.3f)
noisily _log cuadro col, titulo("Dif vs macro %") fmt(%7.1f)
foreach k of local categs {
	if "`k'" != "Sin_IEPS" {
		local ieps_enigh = IEPS`k'[1,1]/`PIB'*100
		noisily _log cuadro fila "`name`k''" "gini_ieps`k'" "`ieps_enigh'" "—" "—"
	}
}
noisily _log cuadro fila "(=) IEPS micro, sin gasolinas" "giniIEPS" "scalar(IEPSNPHHSPIB)" "scalar(IEPSNPSCNPIB)" "scalar(DifIEPSNP)", sep negrita
noisily _log cuadro print, titulo("D. IEPS: base micro ENIGH por categoría vs IEPS no petrolero macro") unidad("% del PIB `anioenigh'") ref("CUAD-1 §4.0")
escalar pct IEPSNPCobertura = scalar(IEPSNPHHSPIB)/scalar(IEPSNPSCNPIB)*100
noisily _log aviso, tipo(FLAG) texto("IEPS micro sin gasolinas cubre `=strtrim(string(scalar(IEPSNPCobertura), "%5.1f"))' % del IEPSNP macro (`=strtrim(string(`IEPSNP'/1e9, "%12.3fc"))' bn); el ancla LIF manda, reparto ∝ micro") ref("CUAD-1 §4.0")

collapse (sum) IEPS, by(folioviv foliohog numren)
save "${SIMROOT}/master/`anioenigh'/consumption_categ_ieps.dta", replace


*** TOUCH DOWN ***/
timer off 15
timer list 15
noisily _log tiempo, timer(15) texto("Expenditure")
log close expenditures
