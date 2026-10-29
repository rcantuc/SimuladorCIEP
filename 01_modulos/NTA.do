*********************************************************************
***                                                               ***
***   NTA.do — Cuenta de Transferencias Nacionales por individuo  ***
***   (Lee–Mason), cerrada por grupo de edad y por quinquenio×sexo ***
***                                                               ***
*********************************************************************
* NTA-1 (2026-10-27). Base: memo 02_governance/nta-0-inventario-2026-10-27.md (#38) y las decisiones firmadas por
* Ricardo el 2026-10-27. NTA-1b (2026-10-27, mismo PR #40): se alinean las definiciones con el sector hogares S.14
* del SCN ANTES de cualquier ancla de S; el ajuste de S queda como variante, no como default. NTA-1c (2026-10-28): el total
* de YA se re-ancla a S.14 (nta_YA = S14) y, si |Σ S − B.8n|/B.8n ≤ 15 %, el ancla multiplicativa de S se activa DECLARADA
* (nta_anclaS = auto -> multiplicativo; intra y la identidad se exigen sin ancla). NTA-3 (2026-10-29): se emiten además el Sankey v3
* (§7b, edades solo al inicio y al final, sin Familias ni «Ingreso g»/«Consumo g») y el panel grupo × sexo (§7c); ningún número cambia. Llamada (SIM.do §3.2b):
*   run NTA.do <anioenigh>        (2024: el único año con households.dta anclado a SCN/LIF/PEF 2024)
*
* IDENTIDAD (por persona, por grupo y nacional; el gate 05_scripts/test-nta-identidad.do la exige a 1e-9 relativo):
*     C − YL − ImpProd = (τ⁺ − τ⁻) + (YA − S)     con   τ⁺ − τ⁻ = τ⁺púb(efectivo + especie + colectivo) − τ⁻púb + τ⁺inter − τ⁻inter + intra
*   y en la forma que exige el gate:  C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − S) − intra = 0.
*   YL + YA + ImpProd es ingreso a PRECIOS DE MERCADO (ImpProd = impuestos netos a los productos como ingreso), C a precios de comprador.
*
* QUÉ LEE (nada se construye por persona que no exista ya en el motor; lo que falta es parámetro + FLAG):
*   master/<anio>/households.dta  (Households.do + Expenditure.do: Yl, Yk, gas_pc_*, ISR_*, cuotas*, infonavit, IVA, IEPS,
*                                  ISAN, Importaciones, ImpNetProductos_*, ing_* finas, ing_estim_alqu, gasto_anualDepreciacion,
*                                  gasto_anualComprasN, ing_capitalROW, ing_suborROW, edad, sexo, factor, folioviv foliohog numren)
*   raw/ENIGH/<anio>/poblacion.dta (parentesco: jefe del hogar, para el alquiler imputado)
*   raw/ENIGH/<anio>/ingresos.dta  (P101-P103, P106-P108: programas que Households.do no lee; memo FLAG 4)
*   raw/ENIGH/<anio>/gastohogar.dta (transferencias en efectivo otorgadas a otros hogares e instituciones)
*   SCN, LIF, PEF del año. Anclas S.14 (SCN.ado v8.3, de CSI_115.xlsx y CSI_103.xlsx con rótulo verificado): AhorroHog (B.8n),
*   TransfEspecie (D.63), CuotasHogS14 (D.61 − D.614), ImpNetosProd (D.21 − D.31 de S.1), AjustePension (D.8), TauPubS14 (D.62 + D.759),
*   YAHogS14 (B.2n + 1/3 B.3n + D.4 neto: filas 69, 70 y 95 de CSI_115).
*
* CONVENCIONES (decisiones firmadas NTA-1 y NTA-1b; no se reabren aquí):
*   C          = consumo privado a PRECIOS DE COMPRADOR (gas_pc_*, anclado a ConHog) + gasto_anualComprasN (la corrección del
*                motor por compras netas de no residentes: C es el de los residentes) + consumo público INDIVIDUAL = D.63
*                (SerEGob con el perfil de matrícula de PerfilesSim.do l. 365-443, SaluGob ∝ gas_pc_SaluT, resto individual per
*                cápita) + consumo público COLECTIVO = ConGob − D.63 per cápita a todas las personas (sin dimensión de edad).
*   τ⁻ público = lo que los hogares pagan en S.14: ISR de personas físicas (asalariados con retenciones + PF, LIF), cuotas a la
*                seguridad social (cuotasTP + infonavit una sola vez; ancla nta_cuotas: D.61 − D.614 de S.14 | LIF CUOTAS) e
*                indirectos anclados a LIF (IVA, IEPS, ISAN, importaciones). FUERA: ISR_PM y OTROSK (los pagan las sociedades
*                en el SCN); se calculan y reportan (TmenFuera) sin restarse a nadie.
*   ImpProd    = ImpNetosProd (D.21 − D.31 de la economía total) ∝ Cpriv: lo que paga cada quien. Entra como ingreso; lo que
*                Altimir embebía de ImpNet en Yk (ImpNetProductos_mixK/_soc/_hog, Households.do l. 2420-2427) se saca de YA para
*                no contarlo dos veces. Así los indirectos de τ⁻ ya no son doble resta. D.29 − D.39 sigue en Yl/Yk (FLAG).
*   YL         = Yl del motor − pensiones (ing_jubila × TaltimirSal, lo que Households.do metió a Yl: FLAG motor v9.x)
*                − 2/3 de las transferencias y flujos financieros que viajan dentro de ing_mixto (× TaltimirSelf) + ing_suborROW.
*   YA         = YA_base + YA_d8 [+ YA_ajuste solo con nta_anclaS = aditivo]. YA_motor = Yk − depreciación (CapFij: base NETA,
*                consistente con S = B.8n) − ImpNet embebido − 1/3 de lo mismo de ing_mixto + ing_capitalROW + alquiler imputado
*                reasignado al jefe del hogar (ingreso). YA_base = YA_motor × YAHogS14/Σ YA_motor con nta_YA = S14 (NTA-1c: el total
*                de YA al del sector hogares B.2n + 1/3 B.3n + D.4 neto, misma distribución; el alquiler se escala igual) o = YA_motor
*                con nta_YA = motor. YA_d8 = D.8 ∝ YL de quienes cotizan (nta_d8). FLAG motor v8.14: Yk lleva ExNOpSoc bruto (−1,765 bn).
*   τ⁺ público = EFECTIVO: pensiones contributivas y Pensión Bienestar ancladas al PEF del año (∝ ing_jubila jubilados, ∝ ing_PAM,
*                como PerfilesSim.do) + becas/programas observados en la ENIGH (ing_benef + P101-P103/P106-P108), todo × UN factor
*                global TauPubS14 / Σ para anclar a D.62 + D.759 de S.14 (nta_anclaTau, default on);
*                ESPECIE: el consumo público individual (D.63) por persona; COLECTIVO: ConGob − D.63 per cápita. Ambos en C.
*   τ⁺ inter   = donativos (P039, P040) + herencias (P057) observados, + remesas (ing_remesas, anclado a ROWTrans), una sola vez.
*   τ⁻ inter   = transferencias EN EFECTIVO otorgadas (ENIGH gastohogar 173416 ayuda a parientes y personas ajenas, 133030 ayuda a
*                adultos mayores/discapacidad, 173417 donativos a instituciones), del hogar a sus adultos con ingreso ∝ (YL+YA).
*                Los regalos en especie (T901-T915) quedan en C del que los compra, como en el SCN (parámetro nta_otorgado).
*   S          = residual del HOGAR: Σ_h (YL + ImpProd + YA + τ⁺ + τ⁺inter − τ⁻ − τ⁻inter) − Σ_h C, repartido a los adultos con
*                ingreso ∝ (YL+YA) = S_sinancla. Se reporta Σ S_sinancla por grupo vs AhorroHog (B.8n S.14), el factor implícito y
*                la brecha. nta_anclaS = auto (default NTA-1c): si |brecha| ≤ 15 % → multiplicativo (S = f·S_sinancla de los adultos,
*                sin contrapartida en YA; la diferencia S_ajuste = S − S_sinancla queda DECLARADA: residual explícito de la identidad
*                con ancla y nodos «Ancla S14 recorte»/«complemento» del Sankey); si no → off con FLAG (se para y se descompone).
*                Variantes: off; aditivo (NTA-1: suma ∝ al mismo reparto con contrapartida en YA_ajuste; no sirve con D < 0).
*   intra      = residual por persona con S SIN ancla; Σ por hogar = 0 (y nacional) por construcción en todos los modos.
*   Flujos financieros de ing_mixto (préstamos, retiros, hipotecas, seguros: cap9) quedan FUERA de la identidad (FLAG motor).
*   Flujos brutos; año 2024; desahorro como dos nodos en los Sankeys v2 y v3 (grupo que ahorra → Futuro; Desahorro → Activos).
*
* PARÁMETROS (globals nta_*; default entre paréntesis; se declaran en la salida):
*   nta_anclaS   ("auto") multiplicativo si |Σ S − B.8n|/B.8n ≤ 15 %, si no off | "off" | "aditivo" | "multiplicativo".
*   nta_YA       ("S14") total de YA a B.2n + 1/3 B.3n + D.4 neto ∝ YA del motor | "motor".
*   nta_cuotas   ("S14") D.61 − D.614 | "LIF" CUOTAS IMSS como PerfilesSim.
*   nta_d8       ("yl_cotizantes") D.8 ∝ YL de personas con cuotas > 0 | "per_capita_adultos".
*   nta_anclaTau ("on") τ⁺ efectivo × factor a D.62 + D.759 | "off" PEF/ENIGH.      nta_alqu ("jefe") | "motor".
*                nta_alqu es solo el lado INGRESO del alquiler imputado (al jefe | como lo deja Households por persona). El lado
*                CONSUMO no se re-reparte aquí: gas_pc_Alqu llega de Expenditure.do ya repartido entre los miembros del hogar por
*                perfilpc.ado (perfil edad-sexo, punto fijo; NO per cápita) y entra a Cpriv tal cual (verificado NTA-2, 2026-10-28).
*   nta_tauCash  ("PEF") pensiones y PAM al PEF | "ENIGH" observadas.   nta_otorgado ("efectivo") | "todo" (incluye T901-T915).
*   nta_mixto    ("crudo") las transferencias y flujos financieros que viajan dentro de ing_mixto se restan de YL/YA a su valor
*                CRUDO ENIGH (el que citan las decisiones: 273 bn financieros, 260 donativos...) y el anclaje de ing_mixto a Cuentas
*                Nacionales (× TaltimirSelf ≈ 6.2) se queda en YL/YA como ingreso mixto; "escalado": se restan × TaltimirSelf (lo que
*                de verdad viaja en Yl/Yk; deja un hueco de Σ YL+YA frente al PIN del tamaño del FLAG); "reancla": se restan escalados
*                y el ingreso mixto restante se re-ancla al mismo total (lo que debería hacer el motor, v9.x). Las tres se reportan.
*
* SALIDAS: users/$id/NTA/nta-persona.dta, nta-grupoedad.json, nta-quinquenio-sexo.json (obligatorio: 36 celdas), nta-identidad.txt,
*          nta-panel-grupoedad-sexo.json (NTA-3: panel grupo × sexo, §7c); users/$id/SankeyNTA/sankey-v2-grupoedad.json (contrato
*          v2.1, §7) y sankey-v3-grupoedad.json (NTA-3: contrato v3, edades solo al inicio y al final, §7b; el 31/79 de v1 no se toca).
* Nada de literales: todo número que sale viene de escalar/SCN/LIF/PEF o de la base.
*********************************************************************
if "`1'" == "" {
	local 1 = 2024
}
local anio = `1'
timer on 14
noisily di _newline(2) in g _dup(20) "." "{bf:   NTA:" in y " cuenta por individuo `anio'   }" in g _dup(20) "." _newline

** 0 Parámetros declarados **
if "$nta_anclaS" == "" | "$nta_anclaS" == "AhorroHog" global nta_anclaS "auto"	// NTA-1c: auto = multiplicativo si |Σ S − B.8n|/B.8n ≤ 15 %, si no off; "AhorroHog" (NTA-1) era el aditivo
if !inlist("$nta_anclaS", "auto", "off", "aditivo", "multiplicativo") {
	noisily di as err `"NTA: nta_anclaS = "$nta_anclaS" no es auto | off | aditivo | multiplicativo"'
	exit 198
}
global nta_anclaS_param "$nta_anclaS"
local brecha_max = 15
if "$nta_YA" == "" global nta_YA "S14"
if !inlist("$nta_YA", "motor", "S14") {
	noisily di as err `"NTA: nta_YA = "$nta_YA" no es motor | S14"'
	exit 198
}
if "$nta_cuotas" == "" global nta_cuotas "S14"
if "$nta_d8" == "" global nta_d8 "yl_cotizantes"
if "$nta_anclaTau" == "" global nta_anclaTau "on"
if !inlist("$nta_d8", "yl_cotizantes", "per_capita_adultos") {
	noisily di as err `"NTA: nta_d8 = "$nta_d8" no es yl_cotizantes | per_capita_adultos"'
	exit 198
}
if "$nta_alqu" == "" global nta_alqu "jefe"
if "$nta_tauCash" == "" global nta_tauCash "PEF"
if "$nta_otorgado" == "" global nta_otorgado "efectivo"
if "$nta_mixto" == "" global nta_mixto "crudo"
local adulto = 18
local tol = 1e-9
capture mkdir "${SIMROOT}/users/$id"
capture mkdir "${SIMROOT}/users/$id/NTA"
capture mkdir "${SIMROOT}/users/$id/SankeyNTA"
local dirnta `"${SIMROOT}/users/$id/NTA"'
local flags ""



**********************************
**# 1. Macros del año: SCN, LIF, PEF
**********************************
quietly SCN, anio(`anio') nographs
foreach k in ConHog ConGob SerEGob SaluGob ComprasN ROWRem ROWProp ROWTrans CapFij PIN IngDisp AhorroN {
	local `k' = scalar(`k')
}
capture confirm scalar AhorroHog
if _rc != 0 {
	noisily di as err "NTA: SCN no definió AhorroHog/TransfEspecie (sin CSI_115.xlsx). Sin ancla S.14 no hay cuenta NTA."
	exit 459
}
local AhorroHog = scalar(AhorroHog)
local AhorroHogB = scalar(AhorroHogB)
local TransfEspecie = scalar(TransfEspecie)
local ConHogS14 = scalar(ConHogS14)
* NTA-1b: anclas S.14 adicionales; si SCN no las definió (tabulado viejo) el parámetro cae a la variante del motor con FLAG *
capture confirm scalar CuotasHogS14
if _rc == 0 local CuotasHogS14 = scalar(CuotasHogS14)
else {
	local CuotasHogS14 = .
	if "$nta_cuotas" == "S14" {
		global nta_cuotas "LIF"
		local flags `"`flags' "SCN sin CuotasHogS14 (D.61-D.614 de CSI_115): nta_cuotas cae a LIF""'
	}
}
capture confirm scalar AjustePension
if _rc == 0 local AjustePension = scalar(AjustePension)
else {
	local AjustePension = 0
	local flags `"`flags' "SCN sin AjustePension (D.8 de CSI_115): YA sin D.8""'
}
capture confirm scalar YAHogS14
if _rc == 0 {
	local YAHogS14 = scalar(YAHogS14)
	local ExNOpHogS14 = scalar(ExNOpHogS14)
	local MixNHogS14 = scalar(MixNHogS14)
	local RentaPropHogNeta = scalar(RentaPropHogNeta)
}
else {
	local YAHogS14 = .
	local ExNOpHogS14 = .
	local MixNHogS14 = .
	local RentaPropHogNeta = .
	if "$nta_YA" == "S14" {
		global nta_YA "motor"
		local flags `"`flags' "SCN sin YAHogS14 (B.2n + 1/3 B.3n + D.4 neto de CSI_115): nta_YA cae a motor""'
	}
}
capture confirm scalar TauPubS14
if _rc == 0 {
	local TauPubS14 = scalar(TauPubS14)
	local PrestSocHog = scalar(PrestSocHog)
	local OtrasTransfHog = scalar(OtrasTransfHog)
}
else {
	local TauPubS14 = .
	local PrestSocHog = .
	local OtrasTransfHog = .
	if "$nta_anclaTau" == "on" {
		global nta_anclaTau "off"
		local flags `"`flags' "SCN sin TauPubS14 (D.62 + D.759 de CSI_115): nta_anclaTau cae a off""'
	}
}
local ImpNetBIE = scalar(ImpNet)
capture confirm scalar ImpNetosProd
if _rc == 0 local ImpNetosProd = scalar(ImpNetosProd)
else {
	local ImpNetosProd = `ImpNetBIE'
	local flags `"`flags' "SCN sin ImpNetosProd (D.21-D.31 de CSI_103): se usa ImpNet del BIE""'
}

* LIF del año por grupo divSIM (sin financiamiento, como PerfilesSim.do §2) *
quietly LIF if divLIF != 10 | divCIEP == 8, anio(`anio') by(divSIM) nographs min(0)
foreach k in ISRAS ISRPF CUOTAS ISRPM OTROSK IVA ISAN IEPSNP IEPSP IMPORT FMP PEMEX CFE IMSS ISSSTE {
	local `k' = r(`k')
	if "``k''" == "." | "``k''" == "" {
		local `k' = 0
		local flags `"`flags' "LIF `anio' sin grupo divSIM `k': se toma 0""'
	}
}
local OyE = `FMP' + `PEMEX' + `CFE' + `IMSS' + `ISSSTE'

* PEF del año (PerfilesSim.do §1) *
quietly PEF, anio(`anio') by(divCIEP) min(0) nographs
local Pensiones = r(Pensiones)
local PenBienestar = r(Pension_AM)
local PEFEducacion = r(Educacion)
local PEFSalud = r(Salud)
quietly PEF if divCIEP == "Educación", anio(`anio') by(desc_subfuncion) min(0) nographs
local Basica = r(educacion_basica)
local Media = r(educacion_media_superio)
local Superior = r(educacion_superior)
local Adultos = r(educacion_para_adultos)
local Posgrado = r(posgrado)
local OtrosEdu = r(Gasto_neto) - `Basica' - `Media' - `Superior' - `Adultos' - `Posgrado'

noisily di in g "  Anclas `anio' (mxn): ConHog " in y %16.0fc `ConHog' in g "  ConGob " in y %16.0fc `ConGob' ///
	in g "  AhorroHog (B.8n) " in y %16.0fc `AhorroHog' in g "  TransfEspecie (D.63) " in y %16.0fc `TransfEspecie'



**********************************
**# 2. Micro: households.dta + lo que falta de la ENIGH cruda
**********************************
local dir_enigh "${SIMROOT}/raw/ENIGH/`anio'"

* 2.1 Programas no leídos por Households.do (P101-P103, P106-P108), misma anualización que ing_* (×4.3333) *
tempfile prog otor paren
quietly {
	use folioviv foliohog numren clave ing_tri using "`dir_enigh'/ingresos.dta", clear
	keep if inlist(clave, "P101", "P102", "P103", "P106", "P107", "P108")
	replace numren = "01" if numren == ""
	g double nta_prog_raw = ing_tri*4.3333
	collapse (sum) nta_prog_raw, by(folioviv foliohog numren)
	save `prog'

* 2.2 Transferencias en efectivo otorgadas por el hogar (gastohogar; anualización ×4 como Expenditure.do) *
	use folioviv foliohog clave tipo_gasto gasto_tri using "`dir_enigh'/gastohogar.dta", clear
	g byte efectivo = inlist(clave, "173416", "133030", "173417")
	g byte especie = substr(clave, 1, 2) == "T9" & tipo_gasto == "G2" & clave != "T916"
	keep if efectivo | especie
	g double nta_otor_ef = gasto_tri*4 if efectivo
	g double nta_otor_esp = gasto_tri*4 if especie
	collapse (sum) nta_otor_ef nta_otor_esp, by(folioviv foliohog)
	save `otor'

* 2.3 Parentesco (jefe del hogar) *
	use folioviv foliohog numren parentesco using "`dir_enigh'/poblacion.dta", clear
	save `paren'
}

* 2.4 Base conciliada del motor *
use "${SIMROOT}/master/`anio'/households.dta", clear
drop if folioviv == ""
quietly {
	merge 1:1 folioviv foliohog numren using `prog', nogen keep(master match)
	merge m:1 folioviv foliohog using `otor', nogen keep(master match)
	merge 1:1 folioviv foliohog numren using `paren', nogen keep(master match)
	foreach v in nta_prog_raw nta_otor_ef nta_otor_esp {
		replace `v' = 0 if `v' == .
	}
	foreach v of varlist ing_jubila ing_PAM ing_dona ing_heren ing_benef ing_prest ing_otrocap ing_ahorro ///
		ing_autor ing_trabmenor ing_remesas ing_t4_cap9 ing_t4_cap5 ing_estim_alqu gasto_anualDepreciacion ///
		gasto_anualComprasN ing_capitalROW ing_suborROW ISR_asalariados ISR_PF ISR_PM cuotasTP infonavit IVA ISAN Importaciones gas_pc_SaluT ///
		ImpNetProductos_mixK ImpNetProductos_soc ImpNetProductos_hog {
		replace `v' = 0 if `v' == .
	}
	capture g pob = 1
	egen long nta_hhid = group(folioviv foliohog)
	g byte nta_adulto = edad >= `adulto'
}
local N = _N
quietly summarize nta_hhid, meanonly
local H = r(max)
noisily di in g "  Personas: " in y %12.0fc `N' in g "; hogares: " in y %12.0fc `H'



**********************************
**# 3. Factores Altimir (vivos en la sesión o reconstruidos de la base)
**********************************
* Households.do deja TaltimirSal/TaltimirSelf/TaltimirROWTrans como scalars; de pie (NTA.do suelto) se
* reconstruyen de la propia base: ing_t4_cap5 = TaltimirSelf × ing_dona (cap5 solo tiene donativos) y
* ing_t4_cap4 = TaltimirSal × (enajenaciones crudas). Si los dos caminos existen y difieren, FLAG.
quietly {
	tabstat ing_t4_cap5 ing_dona ing_t4_cap4 ing_enaje ing_enajecasa ing_enajem [fw=factor], stat(sum) save
	tempname ALT
	matrix `ALT' = r(StatTotal)
	local TSelf_base = `ALT'[1,1]/`ALT'[1,2]
	local TSal_base = `ALT'[1,3]/(`ALT'[1,4] + `ALT'[1,5] + `ALT'[1,6])
}
capture confirm scalar TaltimirSelf
if _rc == 0 {
	local TSelf = scalar(TaltimirSelf)
	local TSal = scalar(TaltimirSal)
	if reldif(`TSelf', `TSelf_base') > 1e-6 | reldif(`TSal', `TSal_base') > 1e-6 {
		local flags `"`flags' "Taltimir vivos (Self `TSelf', Sal `TSal') difieren de los reconstruidos (`TSelf_base', `TSal_base')""'
	}
}
else {
	local TSelf = `TSelf_base'
	local TSal = `TSal_base'
}
escalar pct NTATaltimirSelf = `TSelf'*100
escalar pct NTATaltimirSal = `TSal'*100
noisily di in g "  Altimir: TaltimirSelf " in y %6.4f `TSelf' in g "  TaltimirSal " in y %6.4f `TSal'



**********************************
**# 4. Componentes por persona
**********************************
quietly {

** 4.1 Lo que viaja dentro de ing_mixto y no es ingreso factorial (crudo; ing_t4_cap9 ya está × TaltimirSelf) **
* remesas crudas = cap9/TaltimirSelf − (lo demás crudo de cap9); transferencias = dona + heren + benef; financieros = prest + otrocap + ahorro *
g double nta_rem_raw = ing_t4_cap9/`TSelf' - (ing_autor + ing_trabmenor + ing_prest + ing_otrocap + ing_ahorro + ing_benef + ing_heren)
replace nta_rem_raw = 0 if nta_rem_raw < 0 & nta_rem_raw > -1e-6
g double nta_mixto_transf = (ing_dona + ing_heren + ing_benef + nta_rem_raw)*cond("$nta_mixto" == "crudo", 1, `TSelf')
g double nta_mixto_fin = (ing_prest + ing_otrocap + ing_ahorro)*cond("$nta_mixto" == "crudo", 1, `TSelf')
if "$nta_mixto" == "reancla" {
	* ingreso mixto sin transferencias ni flujos financieros, re-anclado al total del motor (Σ ing_mixto = SCN) *
	tempvar mixpuro
	g double `mixpuro' = max(ing_mixto - nta_mixto_transf - nta_mixto_fin, 0)
	tabstat ing_mixto [fw=factor], stat(sum) save
	Distribucion nta_mixto_re, relativo(`mixpuro') macro(`=r(StatTotal)[1,1]')
	* lo que se resta de Yl/Yk es la diferencia entre el mixto del motor y el re-anclado (2/3 - 1/3) *
	replace nta_mixto_transf = ing_mixto - nta_mixto_re
	replace nta_mixto_fin = 0
}
g double nta_pens_enYl = min(ing_jubila*`TSal', ing_subor)
* tamaño del FLAG: lo que ing_mixto trae de transferencias y flujos financieros, escalado como ingreso de cuenta propia *
g double nta_mixto_flag = (ing_dona + ing_heren + ing_benef + nta_rem_raw + ing_prest + ing_otrocap + ing_ahorro)*`TSelf'

** 4.2 YL **
g double YL = Yl - nta_pens_enYl - 2/3*(nta_mixto_transf + nta_mixto_fin) + ing_suborROW
label var YL "Ingreso laboral NTA (sin pensiones ni transferencias de ing_mixto; con ROW)"

** 4.3 YA (neto de depreciación; alquiler imputado al jefe; con ROW; SIN los impuestos netos a los productos que Altimir
**     embebe en Yk: NTA-1b pieza 3 los saca de aquí y los reasigna ∝ consumo como ImpProd, §4.4b) **
* Lo que Altimir puso de ImpNetProductos en cada persona: Households.do l. 2420-2427 lo deja calculado (∝ ing_mixtoK,
* ing_capital, ing_estim_alqu con las participaciones MixKN / ExNOpSoc / ExNOpHog); Σ = ImpNet del BIE. Los otros
* impuestos a la producción (D.29 − D.39: ImpNetProduccionL/K, 247 bn) se quedan en Yl/Yk como en el motor (FLAG). *
g double nta_impprod_motor = ImpNetProductos_mixK + ImpNetProductos_soc + ImpNetProductos_hog
egen double nta_alqu_hog = total(ing_estim_alqu - ImpNetProductos_hog), by(nta_hhid)
g byte nta_jefe = parentesco == "101"
egen byte nta_njefe = total(nta_jefe), by(nta_hhid)
* hogares sin jefe en la base: el adulto de mayor edad; sin adultos: el de mayor edad *
egen double nta_edadmax_ad = max(cond(nta_adulto, edad, .)), by(nta_hhid)
egen double nta_edadmax = max(edad), by(nta_hhid)
replace nta_jefe = (edad == nta_edadmax_ad & nta_adulto) if nta_njefe == 0 & nta_edadmax_ad != .
replace nta_jefe = (edad == nta_edadmax) if nta_njefe == 0 & nta_edadmax_ad == .
bysort nta_hhid nta_jefe (numren): replace nta_jefe = 0 if nta_jefe == 1 & _n > 1	// un solo jefe por hogar
g double ALQ = cond("$nta_alqu" == "jefe", cond(nta_jefe, nta_alqu_hog, 0), ing_estim_alqu - ImpNetProductos_hog)
label var ALQ "Alquiler imputado (ingreso, sin impuestos a productos embebidos): al jefe del hogar"
g double YA_motor = Yk - gasto_anualDepreciacion - ing_estim_alqu + ALQ - ImpNetProductos_mixK - ImpNetProductos_soc ///
	- 1/3*(nta_mixto_transf + nta_mixto_fin) + ing_capitalROW
label var YA_motor "Ingreso de activos del motor (neto de depreciación, sin impuestos a productos, sin D.8)"

** 4.3b nta_YA (NTA-1c): el TOTAL de YA del motor se re-ancla a YAHogS14 = B.2n + 1/3 B.3n + D.4 neto del sector hogares
**      (CSI_115 filas 69, 70, 95), repartido ∝ YA_motor (misma distribución, otro nivel). ImpNet ya fuera (pieza 3) y D.8 ya
**      dentro aparte (pieza 4): no se duplican. El alquiler imputado (parte de YA_motor) se escala con el mismo factor. **
tabstat YA_motor [fw=factor], stat(sum) save
local YA_motor_tot = r(StatTotal)[1,1]
local fYA = cond("$nta_YA" == "S14", `YAHogS14'/`YA_motor_tot', 1)
g double YA_base = YA_motor*`fYA'
replace ALQ = ALQ*`fYA'
label var YA_base "Ingreso de activos NTA sin D.8 (nta_YA = $nta_YA: YA_motor × factor a B.2n + 1/3 B.3n + D.4 neto S.14)"

** 4.4 Consumo privado (precios de comprador; residentes) **
g double Cpriv = gastoanualTOT + gasto_anualComprasN
label var Cpriv "Consumo privado (gas_pc_* anclado a ConHog + compras netas de no residentes)"

** 4.4b Impuestos netos a los productos como ingreso (NTA-1b pieza 3): ImpNetosProd = D.21 − D.31 de la economía total,
**      asignado ∝ Cpriv (lo que paga cada quien). YL + YA + ImpProd es ingreso a precios de mercado, C a precios de
**      comprador: los indirectos de τ⁻ (∝ IVA, IEPS, ISAN, importaciones micro) ya no son doble resta. **
Distribucion ImpProd, relativo(Cpriv) macro(`ImpNetosProd')
label var ImpProd "Impuestos netos a los productos como ingreso (D.21 − D.31 S.1, ∝ consumo privado)"

** 4.5 Consumo público en especie: educación (perfil de matrícula, PerfilesSim.do l. 365-443, macros PEF del año) **
replace nivel = "0" + nivel if length(nivel) == 1
tempvar educ
g double `educ' = .
tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18, stat(sum) save
local BasAlum = r(StatTotal)[1,1]
replace `educ' = `Basica'/`BasAlum' if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18
tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10"), stat(sum) save
local MedAlum = r(StatTotal)[1,1]
replace `educ' = `Media'/`MedAlum' if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12"), stat(sum) save
local SupAlum = r(StatTotal)[1,1]
replace `educ' = `Superior'/`SupAlum' if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
tabstat factor if asis_esc == "1" & tipoesc == "1" & nivel == "13", stat(sum) save
local PosAlum = r(StatTotal)[1,1]
replace `educ' = `Posgrado'/`PosAlum' if asis_esc == "1" & tipoesc == "1" & nivel == "13"
tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18, stat(sum) save
local AduAlum = r(StatTotal)[1,1]
replace `educ' = `Adultos'/`AduAlum' if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18
replace `educ' = `educ' + `OtrosEdu'/(`BasAlum' + `MedAlum' + `SupAlum' + `PosAlum' + `AduAlum') if `educ' != .
replace `educ' = 0 if `educ' == .
* NTA-1b pieza 6: ConGob partido. INDIVIDUAL = D.63 (TransfEspecie): educación (SerEGob, perfil de matrícula), salud
* (SaluGob ∝ gas_pc_SaluT) y el resto individual (D.63 − SerEGob − SaluGob) con el perfil de PerfilesSim.do para
* «otros gastos» (per cápita). COLECTIVO = ConGob − D.63, per cápita a todas las personas: consumo público sin
* dimensión de edad. Los dos quedan en C público; solo el individual es τ⁺ en especie (el colectivo es τ⁺ colectivo:
* lo financia el mismo gobierno y la identidad lo exige). Si SerEGob + SaluGob > D.63 se escalan los dos a D.63 (FLAG). *
local RestoInd = `TransfEspecie' - `SerEGob' - `SaluGob'
local fEsp = 1
if `RestoInd' < 0 {
	local fEsp = `TransfEspecie'/(`SerEGob' + `SaluGob')
	local RestoInd = 0
	local flags `"`flags' "SerEGob + SaluGob > D.63: educación y salud en especie escaladas por `=string(`fEsp', "%6.4f")'""'
}
Distribucion CpubEduc, relativo(`educ') macro(`=`SerEGob'*`fEsp'')
Distribucion CpubSalud, relativo(gas_pc_SaluT) macro(`=`SaluGob'*`fEsp'')
Distribucion CpubRestoInd, relativo(pob) macro(`RestoInd')
egen double CpubInd = rsum(CpubEduc CpubSalud CpubRestoInd)
Distribucion CpubCol, relativo(pob) macro(`=`ConGob' - `TransfEspecie'')
g double Cpub = CpubInd + CpubCol
label var CpubEduc "Consumo público individual: educación (SerEGob, perfil de matrícula)"
label var CpubSalud "Consumo público individual: salud (SaluGob ∝ gas_pc_SaluT)"
label var CpubRestoInd "Consumo público individual: resto de D.63 (per cápita, perfil PerfilesSim «otros gastos»)"
label var CpubInd "Consumo público individual = D.63 TransfEspecie = τ⁺ público en especie"
label var CpubCol "Consumo público colectivo = ConGob − D.63 (per cápita, sin dimensión de edad) = τ⁺ público colectivo"
label var Cpub "Consumo público = individual (D.63) + colectivo (ConGob − D.63)"
g double C = Cpriv + Cpub
label var C "Consumo total (privado + público individual + público colectivo)"

** 4.6 τ⁻ público = lo que los hogares pagan en S.14 (NTA-1b, pieza 2): ISR de personas físicas (asalariados con
**     retenciones + PF; LIF), cuotas a la seguridad social (infonavit una sola vez; ancla nta_cuotas) e indirectos
**     anclados a LIF. FUERA de τ⁻: ISR_PM y OTROSK (en el SCN los pagan las sociedades, D.5 de S.11/S.12); se
**     calculan y se reportan como TmenFuera, no se restan a nadie. **
Distribucion nta_ISRAS, relativo(ISR_asalariados) macro(`ISRAS')
Distribucion nta_ISRPF, relativo(ISR_PF) macro(`ISRPF')
tempvar cuo
g double `cuo' = cuotasTP + infonavit
if "$nta_cuotas" == "S14" {
	* D.61 − D.614 de S.14 (CuotasHogS14): lo que los hogares pagan a los sistemas, incluidas las contribuciones
	* patronales e imputadas que el motor ya puso en Yl (TaltimirSal lleva SSEmpleadores + SSImputada) *
	Distribucion nta_CUOTAS, relativo(`cuo') macro(`CuotasHogS14')
}
else {
	Distribucion nta_CUOTAS if formal2 == 1, relativo(cuotasTP) macro(`CUOTAS')
}
replace nta_CUOTAS = 0 if nta_CUOTAS == .
Distribucion nta_ISRPM, relativo(ISR_PM) macro(`ISRPM')
Distribucion nta_OTROSK, relativo(ISR_PM) macro(`OTROSK')
Distribucion nta_IVA, relativo(IVA) macro(`IVA')
Distribucion nta_ISAN, relativo(ISAN) macro(`ISAN')
Distribucion nta_IEPSNP, relativo(gas_pc_BebA) macro(`IEPSNP')
Distribucion nta_IEPSP, relativo(gas_pc_Vehi) macro(`IEPSP')
Distribucion nta_IMPORT, relativo(Importaciones) macro(`IMPORT')
egen double TmenDir = rsum(nta_ISRAS nta_ISRPF nta_CUOTAS)
egen double TmenInd = rsum(nta_IVA nta_ISAN nta_IEPSNP nta_IEPSP nta_IMPORT)
egen double TmenFuera = rsum(nta_ISRPM nta_OTROSK)
g double Tmen = TmenDir + TmenInd
label var TmenDir "τ⁻ público directo (ISR asalariados + PF; cuotas $nta_cuotas)"
label var TmenInd "τ⁻ público indirecto (IVA, ISAN, IEPS, importaciones; LIF)"
label var TmenFuera "Fuera de τ⁻ (informativo): ISR_PM + OTROSK, pagados por sociedades en el SCN"
label var Tmen "τ⁻ público = directos + indirectos"

** 4.6b D.8 como escalar (NTA-1b pieza 4): AjustePension = D.8 del sector hogares entra a YA ∝ YL de las personas con
**      cuotas > 0 (quienes acumulan derechos; nta_d8 = yl_cotizantes) o per cápita entre adultos (per_capita_adultos). **
tempvar rel_d8
if "$nta_d8" == "yl_cotizantes" g double `rel_d8' = cond(`cuo' > 0, max(YL, 0), 0)
else g double `rel_d8' = nta_adulto
Distribucion YA_d8, relativo(`rel_d8') macro(`AjustePension')
label var YA_d8 "Ajuste por cambio en derechos de pensión (D.8 S.14) como ingreso de activos ($nta_d8)"
count if `cuo' > 0
local Ncotiz = r(N)

** 4.7 τ⁺ público en efectivo **
if "$nta_tauCash" == "PEF" {
	tempvar jubpub
	g double `jubpub' = ing_jubila if jubilado == 1
	replace `jubpub' = 0 if `jubpub' == .
	Distribucion TpubPens, relativo(`jubpub') macro(`Pensiones')
	Distribucion TpubPAM, relativo(ing_PAM) macro(`PenBienestar')
}
else {
	g double TpubPens = ing_jubila
	g double TpubPAM = ing_PAM
}
g double TpubProg = ing_benef + nta_prog_raw
* NTA-1b pieza 5: τ⁺ público efectivo anclado a D.62 + D.759 de S.14 con UN factor global sobre cada componente
* (pensiones, Pensión Bienestar, becas y programas); nta_anclaTau = off deja PEF/ENIGH como NTA-1 *
tabstat TpubPens TpubPAM TpubProg [fw=factor], stat(sum) save
local TpubEf_pre = r(StatTotal)[1,1] + r(StatTotal)[1,2] + r(StatTotal)[1,3]
local fTau = cond(`TauPubS14' != ., `TauPubS14'/`TpubEf_pre', .)
if "$nta_anclaTau" == "on" {
	foreach v in TpubPens TpubPAM TpubProg {
		replace `v' = `v'*`fTau'
	}
}
g double TpubEf = TpubPens + TpubPAM + TpubProg
g double TpubEsp = CpubInd
g double TpubCol = CpubCol
g double Tpub = TpubEf + TpubEsp + TpubCol
label var TpubEsp "τ⁺ público en especie (individual, D.63)"
label var TpubCol "τ⁺ público colectivo (ConGob − D.63, per cápita)"
label var TpubPens "τ⁺ efectivo: pensiones contributivas ($nta_tauCash; ancla D.62+D.759 $nta_anclaTau)"
label var TpubPAM "τ⁺ efectivo: Pensión Bienestar ($nta_tauCash; ancla D.62+D.759 $nta_anclaTau)"
label var TpubProg "τ⁺ efectivo: becas y programas (ENIGH: ing_benef + P101-P103/P106-P108; ancla D.62+D.759 $nta_anclaTau)"
label var TpubEf "τ⁺ público en efectivo (ancla D.62+D.759 S.14: $nta_anclaTau)"
label var Tpub "τ⁺ público = efectivo + especie (individual) + colectivo"

** 4.8 Transferencias privadas entre hogares **
g double InterRec = ing_dona + ing_heren
g double Remesas = ing_remesas
label var InterRec "τ⁺ inter-hogar recibido: donativos (P039, P040) + herencias (P057)"
label var Remesas "τ⁺ inter-hogar recibido del exterior: remesas (ing_remesas, anclado a ROWTrans)"
g double nta_otor_hog = nta_otor_ef + cond("$nta_otorgado" == "todo", nta_otor_esp, 0)

** 4.9 Reparto a los adultos con ingreso ∝ (YL + YA): peso común para S y para lo otorgado **
g double nta_w = cond(nta_adulto & (YL + YA_base) > 0, YL + YA_base, 0)
egen double nta_wsum = total(nta_w), by(nta_hhid)
* cadena de respaldo: adultos ∝ ingreso disponible positivo; adultos por igual; todos por igual *
g double nta_w2 = cond(nta_adulto, max(TpubEf + InterRec + Remesas, 0), 0)
egen double nta_w2sum = total(nta_w2), by(nta_hhid)
egen double nta_nad = total(nta_adulto), by(nta_hhid)
egen double nta_nint = count(edad), by(nta_hhid)
g double nta_share = nta_w/nta_wsum if nta_wsum > 0
replace nta_share = nta_w2/nta_w2sum if nta_wsum <= 0 & nta_w2sum > 0
replace nta_share = nta_adulto/nta_nad if nta_wsum <= 0 & nta_w2sum <= 0 & nta_nad > 0
replace nta_share = 1/nta_nint if nta_share == .
g double InterOtor = nta_otor_hog*nta_share
label var InterOtor "τ⁻ inter-hogar otorgado (efectivo; del hogar a sus adultos con ingreso ∝ YL+YA)"

** 4.10 S: residual del hogar, a los adultos ∝ (YL + YA) **
g double nta_yd = YL + ImpProd + YA_base + YA_d8 + Tpub + InterRec + Remesas - Tmen - InterOtor
egen double nta_S_hog = total(nta_yd - C), by(nta_hhid)
g double S_sinancla = nta_S_hog*nta_share
label var S_sinancla "Ahorro: residual del hogar repartido a adultos ∝ (YL+YA), antes del ancla"

** 4.11 Σ S micro vs AhorroHog (B.8n S.14). S_sinancla es el residual; la identidad y Σ intra = 0 se exigen SIN ancla.
**      nta_anclaS: "auto" (default, NTA-1c) = "multiplicativo" si |Σ S − B.8n|/B.8n ≤ 15 %, si no "off" con FLAG (se para y se
**      descompone); "off"; "aditivo" (NTA-1: suma ∝ al mismo reparto con contrapartida en YA_ajuste); "multiplicativo" (S = f·S_sinancla
**      de los adultos, sin contrapartida en YA: la diferencia S_ajuste = S − S_sinancla queda DECLARADA fuera de la identidad, en
**      el Sankey como «Ancla S14 recorte»/«complemento»; intra se calcula con S_sinancla, así Σ intra = 0 se conserva). **
tabstat S_sinancla [fw=factor], stat(sum) save
local S_micro = r(StatTotal)[1,1]
local D = `AhorroHog' - `S_micro'
local fS = `AhorroHog'/`S_micro'
local brecha = (`S_micro'/`AhorroHog' - 1)*100
if "$nta_anclaS" == "auto" {
	if abs(`brecha') <= `brecha_max' global nta_anclaS "multiplicativo"
	else {
		global nta_anclaS "off"
		local flags `"`flags' "|Σ S − B.8n|/B.8n = `=string(abs(`brecha'), "%6.1f")' % > `brecha_max' %: no se aplica ancla (nta_anclaS auto -> off)""'
	}
}
tabstat nta_w [fw=factor], stat(sum) save
local wtot = r(StatTotal)[1,1]
g double YA_ajuste = 0
if "$nta_anclaS" == "aditivo" {
	replace YA_ajuste = nta_w/`wtot'*`D'
	g double S = S_sinancla + YA_ajuste
}
else if "$nta_anclaS" == "multiplicativo" {
	g double S = S_sinancla*`fS'
}
else {
	g double S = S_sinancla
}
g double S_ajuste = S - S_sinancla - YA_ajuste
label var YA_ajuste "Ajuste por ancla aditiva Σ S = AhorroHog (0 salvo nta_anclaS = aditivo); contrapartida de S"
label var S_ajuste "Ancla multiplicativa de S (S − S_sinancla; 0 salvo nta_anclaS = multiplicativo): declarado fuera de la identidad"
g double YA = YA_base + YA_d8 + YA_ajuste
label var S "Ahorro NTA (residual del hogar a adultos ∝ YL+YA; ancla: $nta_anclaS)"
label var YA "Ingreso de activos NTA (nta_YA = $nta_YA; con D.8)"

** 4.12 Intra-hogar: el único residual (con S sin ancla: Σ por hogar = 0 en todos los modos) **
g double Intra = C - YL - ImpProd - (YA - YA_ajuste) - Tpub + Tmen - InterRec - Remesas + InterOtor + S_sinancla
label var Intra "τ intra-hogar (residual por persona con S sin ancla; Σ por hogar = 0)"
g double Resid = C - YL - ImpProd - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - YA_ajuste - S_sinancla) - Intra
label var Resid "Residual de la identidad sin ancla (0 por construcción); con ancla el residual es S_ajuste"

** 4.13 Cortes **
g byte quinq = min(floor(edad/5), 17) + 1
label define quinq 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-19" 5 "20-24" 6 "25-29" 7 "30-34" 8 "35-39" 9 "40-44" ///
	10 "45-49" 11 "50-54" 12 "55-59" 13 "60-64" 14 "65-69" 15 "70-74" 16 "75-79" 17 "80-84" 18 "85+", replace
label values quinq quinq
}
quietly tabstat ing_mixto nta_mixto_flag nta_pens_enYl [fw=factor], stat(sum) save
escalar mxn NTAMixtoMotor = r(StatTotal)[1,1]
escalar mxn NTAMixtoTransfFin = r(StatTotal)[1,2]
escalar pct NTAMixtoTransfFinPct = r(StatTotal)[1,2]/r(StatTotal)[1,1]*100
escalar mxn NTAPensEnYl = r(StatTotal)[1,3]
local flags `"`flags' "ing_mixto del motor = `=string(scalar(NTAMixtoMotor)/1e9, "%9.1f")' bn, de los cuales `=string(scalar(NTAMixtoTransfFin)/1e9, "%9.1f")' bn (`=string(scalar(NTAMixtoTransfFinPct), "%4.1f")' %) son transferencias y flujos financieros × TaltimirSelf; nta_mixto=$nta_mixto""'
escalar mxn NTAAjusteS = `D'
escalar pct NTAFactorS = `fS'*100
escalar mxn NTASsinAncla = `S_micro'
escalar pct NTABrechaSPct = `brecha'
escalar mxn NTAYAMotorNac = `YA_motor_tot'
escalar pct NTAFactorYA = `fYA'*100
quietly tabstat YA_base S_ajuste [fw=factor], stat(sum) save
escalar mxn NTAYABaseNac = r(StatTotal)[1,1]
escalar mxn NTASAjusteNac = r(StatTotal)[1,2]
noisily di in g "  YA: motor " in y %16.0fc `YA_motor_tot' in g "  YAHogS14 (B.2n + 1/3 B.3n + D.4 neto) " in y %16.0fc `YAHogS14' in g " (B.2n " in y %16.0fc `ExNOpHogS14' in g ", 1/3 B.3n " in y %16.0fc `MixNHogS14'/3 in g ", D.4 neto " in y %16.0fc `RentaPropHogNeta' in g ")  factor " in y %7.4f `fYA' in g "  nta_YA=" in y "$nta_YA"
quietly tabstat TmenDir TmenInd TmenFuera nta_CUOTAS [fw=factor], stat(sum) save
escalar mxn NTATmenFueraNac = r(StatTotal)[1,3]
escalar mxn NTACuotasNac = r(StatTotal)[1,4]
noisily di in g "  τ⁻: directos " in y %16.0fc r(StatTotal)[1,1] in g " (cuotas $nta_cuotas " in y %16.0fc r(StatTotal)[1,4] in g ")  indirectos " in y %16.0fc r(StatTotal)[1,2] ///
	in g "  fuera (ISR_PM + OTROSK) " in y %16.0fc r(StatTotal)[1,3]
quietly tabstat ImpProd nta_impprod_motor TmenInd [fw=factor], stat(sum) save
escalar mxn NTAImpProdNac = r(StatTotal)[1,1]
escalar mxn NTAImpProdMotor = r(StatTotal)[1,2]
escalar pct NTAFactorIndirectos = r(StatTotal)[1,3]/`ImpNetosProd'*100
noisily di in g "  Impuestos a productos: ImpNetosProd (D.21−D.31 CSI_103) " in y %16.0fc `ImpNetosProd' in g "  ImpNet BIE " in y %16.0fc `ImpNetBIE' ///
	in g "  embebido por Altimir en Yk (sacado) " in y %16.0fc r(StatTotal)[1,2] in g "  Σ indirectos micro (τ⁻) " in y %16.0fc r(StatTotal)[1,3] ///
	in g "  factor indirectos/ImpNetosProd " in y %7.4f r(StatTotal)[1,3]/`ImpNetosProd'
escalar pct NTAFactorTau = `fTau'*100
escalar mxn NTATpubEfPre = `TpubEf_pre'
noisily di in g "  τ⁺ efectivo: PEF/ENIGH " in y %16.0fc `TpubEf_pre' in g "  D.62 + D.759 S.14 " in y %16.0fc `TauPubS14' in g " (D.62 " in y %16.0fc `PrestSocHog' in g ", D.759 " in y %16.0fc `OtrasTransfHog' in g ")  factor " in y %7.4f `fTau' in g "  nta_anclaTau=" in y "$nta_anclaTau"
quietly tabstat YA_d8 [fw=factor], stat(sum) save
escalar mxn NTAD8Nac = r(StatTotal)[1,1]
noisily di in g "  D.8 (AjustePension) " in y %16.0fc `AjustePension' in g " → YA_d8 ($nta_d8; " in y `Ncotiz' in g " personas con cuotas > 0 en la base): Σ " in y %16.0fc r(StatTotal)[1,1]
noisily di in g "  S micro (residual de hogares, sin ajuste): " in y %16.0fc `S_micro' in g "  AhorroHog (B.8n): " in y %16.0fc `AhorroHog' ///
	in g "  factor implícito " in y %8.4f `fS' in g "  brecha " in y %7.1f scalar(NTABrechaSPct) in g " %  nta_anclaS=" in y "$nta_anclaS" in g " (param " in y "$nta_anclaS_param" in g ")  Σ S_ajuste " in y %16.0fc scalar(NTASAjusteNac)



**********************************
**# 5. Gates internos (por persona y por hogar)
**********************************
quietly {
	tabstat C [fw=factor], stat(sum) save
	local Ctot = r(StatTotal)[1,1]
	tabstat factor, stat(sum) save
	local poptot = r(StatTotal)[1,1]
	local Cpc = `Ctot'/`poptot'
	g double nta_absres = abs(Resid)
	summarize nta_absres, meanonly
	local maxres = r(max)
	egen double nta_intra_hog = total(Intra), by(nta_hhid)
	g double nta_absintra = abs(nta_intra_hog)
	summarize nta_absintra, meanonly
	local maxintra_hog = r(max)
	tabstat Intra S Cpriv Cpub YL YA Tmen TpubEf InterRec Remesas InterOtor YA_ajuste CpubInd CpubCol [fw=factor], stat(sum) save
	tempname TOT
	matrix `TOT' = r(StatTotal)
}
local Intra_nac = `TOT'[1,1]
local S_nac = `TOT'[1,2]
escalar mxn NTAIntraNac = `Intra_nac'
escalar mxn NTASNac = `S_nac'
escalar mxn NTACprivNac = `TOT'[1,3]
escalar mxn NTACpubNac = `TOT'[1,4]
escalar mxn NTACpubIndNac = `TOT'[1,13]
escalar mxn NTACpubColNac = `TOT'[1,14]
escalar mxn NTABrechaEspecie = `TOT'[1,13] - `TransfEspecie'
escalar pct NTABrechaEspeciePct = (`TOT'[1,13]/`TransfEspecie' - 1)*100
escalar mxn NTABrechaCpriv = `TOT'[1,3] - `ConHogS14'
local ok = 1
if `maxres' > `tol'*`Cpc' {
	local ok = 0
	noisily di as err "  GATE NTA: residual por persona máximo " %12.4f `maxres' " (relativo al C per cápita " %9.2e `maxres'/`Cpc' ")"
}
if abs(`Intra_nac')/`Ctot' > `tol' {
	local ok = 0
	noisily di as err "  GATE NTA: Σ intra-hogar nacional " %16.2f `Intra_nac' " (relativo a C " %9.2e abs(`Intra_nac')/`Ctot' ")"
}
if "$nta_anclaS" != "off" & reldif(`S_nac', `AhorroHog') > `tol' {
	local ok = 0
	noisily di as err "  GATE NTA: Σ S " %16.2f `S_nac' " ≠ AhorroHog " %16.2f `AhorroHog'
}
noisily di in g "  Gates: residual por persona máx " in y %9.2e `maxres' in g "; Σ intra por hogar máx " in y %9.2e `maxintra_hog' ///
	in g "; Σ intra nacional " in y %12.2f `Intra_nac' in g "; Σ S " in y %16.0fc `S_nac' in g " -> " in y cond(`ok', "OK", "ROJO")
noisily di in g "  ConGob partido: individual (D.63) Σ " in y %16.0fc `TOT'[1,13] in g " vs TransfEspecie " in y %16.0fc `TransfEspecie' ///
	in g " (reldif " in y %9.2e reldif(`TOT'[1,13], `TransfEspecie') in g "); colectivo (ConGob − D.63) Σ " in y %16.0fc `TOT'[1,14] in g "; Σ Cpub " in y %16.0fc `TOT'[1,4]



**********************************
**# 6. Agregados: grupo de edad (escalares) y quinquenio × sexo
**********************************
local vars "C Cpriv Cpub CpubInd CpubCol CpubEduc CpubSalud CpubRestoInd YL ImpProd YA YA_base YA_motor YA_d8 YA_ajuste S S_sinancla S_ajuste Tpub TpubEf TpubEsp TpubCol TpubPens TpubPAM TpubProg Tmen TmenDir TmenCuotas TmenInd TmenFuera InterRec Remesas InterOtor Intra Resid ALQ"
quietly g double TmenCuotas = nta_CUOTAS
preserve
quietly {
	g double pobw = 1
	g byte g0 = 0
	tempfile per
	save `per'
	* por grupo de edad y total (grupo 0) *
	collapse (sum) `vars' pobw [fw=factor], by(grupoedad)
	tempfile ge
	save `ge'
	use `per', clear
	collapse (sum) `vars' pobw [fw=factor], by(g0)
	rename g0 grupoedad
	append using `ge'
	sort grupoedad
	foreach v in `vars' pobw {
		forvalues i = 1/`=_N' {
			local g = grupoedad[`i']
			if "`v'" == "pobw" escalar personas NTAPob`g' = pobw[`i']
			else escalar mxn NTA`v'`g' = `v'[`i']
		}
	}
	* intra bruto por signo (Sankey) y S por signo *
	use `per', clear
	g double IntraPos = max(Intra, 0)
	g double IntraNeg = max(-Intra, 0)
	collapse (sum) IntraPos IntraNeg [fw=factor], by(grupoedad)
	forvalues i = 1/`=_N' {
		local g = grupoedad[`i']
		escalar mxn NTAIntraPos`g' = IntraPos[`i']
		escalar mxn NTAIntraNeg`g' = IntraNeg[`i']
	}
	* por sexo *
	use `per', clear
	collapse (sum) S Intra YL YA C Tmen Tpub pobw [fw=factor], by(sexo)
	forvalues i = 1/`=_N' {
		local s = cond(sexo[`i'] == 1, "H", "M")
		foreach v in S Intra YL YA C Tmen Tpub {
			escalar mxn NTA`v'`s' = `v'[`i']
		}
		escalar personas NTAPob`s' = pobw[`i']
	}
	* por decil: YA del motor vs YA re-anclado a S.14 (la magnitud del FLAG Yk vs D.4 en deciles, NTA-1c) *
	use `per', clear
	collapse (sum) YA_motor YA_base pobw [fw=factor], by(decil)
	forvalues i = 1/`=_N' {
		local d = decil[`i']
		escalar mxn NTAYAMotorD`d' = YA_motor[`i']
		escalar mxn NTAYABaseD`d' = YA_base[`i']
		escalar personas NTAPobD`d' = pobw[`i']
	}
	* quinquenio × sexo (tabla al JSON desde el colapsado) *
	use `per', clear
	collapse (sum) `vars' pobw [fw=factor], by(quinq sexo)
	g double resid_chk = C - YL - ImpProd - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - YA_ajuste - S_sinancla) - Intra
	summarize resid_chk, meanonly
	local maxres_qs = max(abs(r(min)), abs(r(max)))
	tempfile qs
	save `qs'
}
restore
if `maxres_qs'/`Ctot' > `tol' {
	local ok = 0
	noisily di as err "  GATE NTA: residual por quinquenio×sexo máx " %12.2f `maxres_qs'
}
escalar mxn NTAResidMaxQS = `maxres_qs'
escalar mxn NTAResidMaxPersona = `maxres'

* 6.1 Tabla de identidad (texto; bn MXN). Abre con Σ S micro sin ajuste por grupo vs B.8n y el factor implícito. *
local f1 "%10.1f"
local okstr = cond(`ok', "OK", "ROJO")
tempname fh
file open `fh' using `"`dirnta'/nta-identidad.txt"', write replace text
file write `fh' "NTA `anio' — Σ S micro (residual de los hogares, SIN ajuste) por grupo de edad vs B.8n S.14 (miles de millones de MXN corrientes; [fw=factor])" _n
file write `fh' %-12s ("Grupo") %9s ("Pob(M)") %10s ("S sin aj") %10s ("S final") %10s ("ajuste") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTAS_sinancla`g')/1e9) `f1' (scalar(NTAS`g')/1e9) `f1' ((scalar(NTAS`g') - scalar(NTAS_sinancla`g'))/1e9) _n
}
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTAS_sinancla0)/1e9) `f1' (scalar(NTAS0)/1e9) `f1' ((scalar(NTAS0) - scalar(NTAS_sinancla0))/1e9) _n
file write `fh' "B.8n (AhorroHog) " `f1' (`AhorroHog'/1e9) "; factor implícito B.8n / Σ S sin ajuste " %8.4f (`fS') "; brecha (Σ S − B.8n)/B.8n " %7.1f (scalar(NTABrechaSPct)) " %; ajuste aditivo que exigiría el ancla " `f1' (`D'/1e9) "; nta_anclaS=$nta_anclaS (param $nta_anclaS_param; auto = multiplicativo si |brecha| <= `brecha_max' %)" _n
file write `fh' "YA: motor " `f1' (`YA_motor_tot'/1e9) " vs YAHogS14 (B.2n " `f1' (`ExNOpHogS14'/1e9) " + 1/3 B.3n " `f1' (`MixNHogS14'/3e9) " + D.4 neto " `f1' (`RentaPropHogNeta'/1e9) ") = " `f1' (`YAHogS14'/1e9) "; factor " %7.4f (`fYA') "; nta_YA=$nta_YA; Σ YA_base " `f1' (scalar(NTAYABaseNac)/1e9) _n
file write `fh' "YA del motor vs re-anclado por decil (bn): "
forvalues d = 1/10 {
	file write `fh' "D`d' " %7.1f (scalar(NTAYAMotorD`d')/1e9) "->" %7.1f (scalar(NTAYABaseD`d')/1e9) " "
}
file write `fh' _n _n
file write `fh' "Identidad por grupo de edad SIN ancla: C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − YA_ajuste − S sin ancla) − intra = R; con el ancla multiplicativa la diferencia S − S sin ancla queda declarada (columna ajuste de arriba), no en la identidad.   (ImpProd = impuestos netos a los productos como ingreso ∝ Cpriv)" _n
file write `fh' "τ⁺ = público efectivo + público especie (individual D.63) + público colectivo (ConGob − D.63) + inter recibido + remesas; τ⁻ = público (ISR PF+asalariados, cuotas $nta_cuotas, indirectos LIF) + inter otorgado. Fuera de τ⁻ (informativo): ISR_PM + OTROSK." _n
file write `fh' "Parámetros: nta_anclaS=$nta_anclaS nta_YA=$nta_YA nta_cuotas=$nta_cuotas nta_d8=$nta_d8 nta_anclaTau=$nta_anclaTau nta_alqu=$nta_alqu nta_tauCash=$nta_tauCash nta_otorgado=$nta_otorgado nta_mixto=$nta_mixto" _n _n
file write `fh' %-12s ("Grupo") %9s ("Pob(M)") %10s ("Cpriv") %10s ("Cpub") %10s ("C") %10s ("YL") %10s ("ImpProd") %10s ("YA") %10s ("  YA d8") %10s ("S") %10s ("tau-pub") %10s ("  cuotas") %10s ("  indir") %10s ("fuera") %10s ("tau+efec") %10s ("tau+esp") %10s ("tau+col") %10s ("interRec") %10s ("remesas") %10s ("interOtor") %10s ("intra") %10s ("R") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTACpriv`g')/1e9) `f1' (scalar(NTACpub`g')/1e9) `f1' (scalar(NTAC`g')/1e9) ///
		`f1' (scalar(NTAYL`g')/1e9) `f1' (scalar(NTAImpProd`g')/1e9) `f1' (scalar(NTAYA`g')/1e9) `f1' (scalar(NTAYA_d8`g')/1e9) `f1' (scalar(NTAS`g')/1e9) `f1' (scalar(NTATmen`g')/1e9) `f1' (scalar(NTATmenCuotas`g')/1e9) `f1' (scalar(NTATmenInd`g')/1e9) `f1' (scalar(NTATmenFuera`g')/1e9) ///
		`f1' (scalar(NTATpubEf`g')/1e9) `f1' (scalar(NTATpubEsp`g')/1e9) `f1' (scalar(NTATpubCol`g')/1e9) `f1' (scalar(NTAInterRec`g')/1e9) `f1' (scalar(NTARemesas`g')/1e9) ///
		`f1' (scalar(NTAInterOtor`g')/1e9) `f1' (scalar(NTAIntra`g')/1e9) %10.6f (scalar(NTAResid`g')/1e9) _n
}
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTACpriv0)/1e9) `f1' (scalar(NTACpub0)/1e9) `f1' (scalar(NTAC0)/1e9) ///
	`f1' (scalar(NTAYL0)/1e9) `f1' (scalar(NTAImpProd0)/1e9) `f1' (scalar(NTAYA0)/1e9) `f1' (scalar(NTAYA_d80)/1e9) `f1' (scalar(NTAS0)/1e9) `f1' (scalar(NTATmen0)/1e9) `f1' (scalar(NTATmenCuotas0)/1e9) `f1' (scalar(NTATmenInd0)/1e9) `f1' (scalar(NTATmenFuera0)/1e9) ///
	`f1' (scalar(NTATpubEf0)/1e9) `f1' (scalar(NTATpubEsp0)/1e9) `f1' (scalar(NTATpubCol0)/1e9) `f1' (scalar(NTAInterRec0)/1e9) `f1' (scalar(NTARemesas0)/1e9) ///
	`f1' (scalar(NTAInterOtor0)/1e9) `f1' (scalar(NTAIntra0)/1e9) %10.6f (scalar(NTAResid0)/1e9) _n _n
file write `fh' "S y intra-hogar por sexo (bn): hombres S " `f1' (scalar(NTASH)/1e9) " intra " `f1' (scalar(NTAIntraH)/1e9) "; mujeres S " `f1' (scalar(NTASM)/1e9) " intra " `f1' (scalar(NTAIntraM)/1e9) _n
file write `fh' "Impuestos a productos: ImpNetosProd (D.21−D.31) " `f1' (`ImpNetosProd'/1e9) "; ImpNet BIE " `f1' (`ImpNetBIE'/1e9) "; embebido por Altimir en Yk (sacado de YA) " `f1' (scalar(NTAImpProdMotor)/1e9) "; Σ indirectos micro τ⁻ " `f1' (scalar(NTATmenInd0)/1e9) " (factor " %7.4f (scalar(NTAFactorIndirectos)/100) ")" _n
file write `fh' "τ⁺ efectivo PEF/ENIGH " `f1' (`TpubEf_pre'/1e9) " vs D.62 + D.759 S.14 " `f1' (`TauPubS14'/1e9) " (D.62 " `f1' (`PrestSocHog'/1e9) ", D.759 " `f1' (`OtrasTransfHog'/1e9) "); factor " %7.4f (`fTau') "; nta_anclaTau=$nta_anclaTau; Σ τ⁺ efectivo final " `f1' (scalar(NTATpubEf0)/1e9) _n
file write `fh' "D.8 AjustePension " `f1' (`AjustePension'/1e9) " → YA_d8 ($nta_d8) Σ " `f1' (scalar(NTAD8Nac)/1e9) _n
file write `fh' "ConGob partido: individual (D.63) Σ " `f1' (scalar(NTACpubIndNac)/1e9) " vs TransfEspecie " `f1' (`TransfEspecie'/1e9) " (educación " `f1' (scalar(NTACpubEduc0)/1e9) ", salud " `f1' (scalar(NTACpubSalud0)/1e9) ", resto individual per cápita " `f1' (scalar(NTACpubRestoInd0)/1e9) "); colectivo (ConGob − D.63, per cápita) Σ " `f1' (scalar(NTACpubColNac)/1e9) "; ConGob " `f1' (`ConGob'/1e9) _n
file write `fh' "Σ Cpriv " `f1' (scalar(NTACprivNac)/1e9) " vs P.3 S.14 " `f1' (`ConHogS14'/1e9) "; ConHog (BIE) " `f1' (`ConHog'/1e9) "; ComprasN " `f1' (`ComprasN'/1e9) _n
file write `fh' "Gates: residual máx por persona " %9.2e (`maxres') " MXN; Σ intra nacional " %12.2f (`Intra_nac') " MXN; Σ S − AhorroHog " %12.2f (`S_nac' - `AhorroHog') " MXN -> `okstr'" _n
file close `fh'

* 6.2 JSON por grupo de edad *
local q = char(34)
local fecha : di %tdCCYY-NN-DD date("$S_DATE", "DMY")
local fm "%20.4f"
file open `fh' using `"`dirnta'/nta-grupoedad.json"', write replace text
file write `fh' `"{"esquema":"nta/v1","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"grupoedad","' _n
file write `fh' `""identidad":"C - YL - ImpProd - (tau_mas - tau_menos) - (YA - YA_ajuste - S_sinancla) - intra = 0 (sin ancla); con ancla multiplicativa el residual declarado es S_ajuste = S - S_sinancla; ImpProd = impuestos netos a los productos como ingreso (∝ Cpriv); tau_mas = tau_pub_efectivo + tau_pub_especie (individual D.63) + tau_pub_colectivo (ConGob - D.63) + inter_recibido + remesas; tau_menos = tau_pub + inter_otorgado","' _n
file write `fh' `""parametros":{"nta_anclaS":"$nta_anclaS","nta_anclaS_param":"$nta_anclaS_param","nta_YA":"$nta_YA","nta_cuotas":"$nta_cuotas","nta_d8":"$nta_d8","nta_anclaTau":"$nta_anclaTau","nta_alqu":"$nta_alqu","nta_tauCash":"$nta_tauCash","nta_otorgado":"$nta_otorgado","nta_mixto":"$nta_mixto","adulto":`adulto',"tolerancia":1e-9},"' _n
file write `fh' `""anclas":{"AhorroHog_B8n":`=trim(string(`AhorroHog', "`fm'"))',"AhorroHogB_B8b":`=trim(string(`AhorroHogB', "`fm'"))',"TransfEspecie_D63":`=trim(string(`TransfEspecie', "`fm'"))',"ConHogS14_P3":`=trim(string(`ConHogS14', "`fm'"))',"ConHog":`=trim(string(`ConHog', "`fm'"))',"ConGob":`=trim(string(`ConGob', "`fm'"))',"SerEGob":`=trim(string(`SerEGob', "`fm'"))',"SaluGob":`=trim(string(`SaluGob', "`fm'"))',"ComprasN":`=trim(string(`ComprasN', "`fm'"))',"ROWTrans":`=trim(string(`ROWTrans', "`fm'"))',"ROWRem":`=trim(string(`ROWRem', "`fm'"))',"ROWProp":`=trim(string(`ROWProp', "`fm'"))',"CapFij":`=trim(string(`CapFij', "`fm'"))',"IngDisp":`=trim(string(`IngDisp', "`fm'"))',"AhorroN":`=trim(string(`AhorroN', "`fm'"))',"OyE":`=trim(string(`OyE', "`fm'"))',"PEF_Pensiones":`=trim(string(`Pensiones', "`fm'"))',"PEF_PensionAM":`=trim(string(`PenBienestar', "`fm'"))',"TaltimirSelf":`=trim(string(`TSelf', "%12.8f"))',"TaltimirSal":`=trim(string(`TSal', "%12.8f"))'},"' _n
file write `fh' `""S_vs_B8n":{"S_sin_ajuste":`=trim(string(`S_micro', "`fm'"))',"AhorroHog":`=trim(string(`AhorroHog', "`fm'"))',"factor_implicito":`=trim(string(`fS', "%12.8f"))',"brecha_pct":`=trim(string(scalar(NTABrechaSPct), "%12.6f"))',"ajuste_aditivo_que_exigiria":`=trim(string(`D', "`fm'"))',"S_final":`=trim(string(`S_nac', "`fm'"))',"S_ajuste":`=trim(string(scalar(NTASAjusteNac), "`fm'"))',"modo":"$nta_anclaS","modo_param":"$nta_anclaS_param","brecha_max_pct":`brecha_max',"mixto_motor":`=trim(string(scalar(NTAMixtoMotor), "`fm'"))',"mixto_transf_fin_escalado":`=trim(string(scalar(NTAMixtoTransfFin), "`fm'"))',"pensiones_en_Yl":`=trim(string(scalar(NTAPensEnYl), "`fm'"))',"regla":"off: S residual sin tapón; aditivo: suma ∝ (YL+YA) de adultos con contrapartida en YA_ajuste; multiplicativo: S × factor, sin contrapartida (cae a intra)"},"' _n
file write `fh' `""ya_s14":{"YA_motor":`=trim(string(`YA_motor_tot', "`fm'"))',"YAHogS14":`=trim(string(`YAHogS14', "`fm'"))',"B2n":`=trim(string(`ExNOpHogS14', "`fm'"))',"tercio_B3n":`=trim(string(`MixNHogS14'/3, "`fm'"))',"D4_neto":`=trim(string(`RentaPropHogNeta', "`fm'"))',"factor":`=trim(string(`fYA', "%12.8f"))',"nta_YA":"$nta_YA","YA_base_micro":`=trim(string(scalar(NTAYABaseNac), "`fm'"))',"por_decil":["'
forvalues d = 1/10 {
	file write `fh' `"`=cond(`d' > 1, ",", "")'{"decil":`d',"pob":`=trim(string(scalar(NTAPobD`d'), "%20.0f"))',"YA_motor":`=trim(string(scalar(NTAYAMotorD`d'), "`fm'"))',"YA_base":`=trim(string(scalar(NTAYABaseD`d'), "`fm'"))'}"'
}
file write `fh' `"],"regla":"el total de YA del motor (neto de depreciación, sin ImpNet embebido, sin D.8) se re-ancla a B.2n + 1/3 B.3n + D.4 neto de S.14 ∝ YA del motor; el alquiler imputado se escala igual"},"' _n
file write `fh' `""impuestos_productos":{"ImpNetosProd_D21_D31":`=trim(string(`ImpNetosProd', "`fm'"))',"ImpNet_BIE":`=trim(string(`ImpNetBIE', "`fm'"))',"ImpProd_micro":`=trim(string(scalar(NTAImpProdNac), "`fm'"))',"embebido_Altimir_sacado_de_YA":`=trim(string(scalar(NTAImpProdMotor), "`fm'"))',"indirectos_micro_tau_menos":`=trim(string(scalar(NTATmenInd0), "`fm'"))',"factor_indirectos_sobre_ImpNetosProd":`=trim(string(scalar(NTAFactorIndirectos)/100, "%12.8f"))',"regla":"ImpProd ∝ Cpriv; el ImpNet que Altimir embebe en Yk (∝ ing_mixtoK, ing_capital, ing_estim_alqu) se saca de YA"},"' _n
file write `fh' `""tau_mas_efectivo":{"PEF_ENIGH_pre":`=trim(string(`TpubEf_pre', "`fm'"))',"D62":`=trim(string(`PrestSocHog', "`fm'"))',"D759":`=trim(string(`OtrasTransfHog', "`fm'"))',"TauPubS14":`=trim(string(`TauPubS14', "`fm'"))',"factor":`=trim(string(`fTau', "%12.8f"))',"nta_anclaTau":"$nta_anclaTau","final":`=trim(string(scalar(NTATpubEf0), "`fm'"))',"regla":"un solo factor global multiplicativo sobre pensiones, Pensión Bienestar y becas/programas"},"' _n
file write `fh' `""d8":{"AjustePension_D8":`=trim(string(`AjustePension', "`fm'"))',"YA_d8_micro":`=trim(string(scalar(NTAD8Nac), "`fm'"))',"nta_d8":"$nta_d8","personas_con_cuotas":`Ncotiz'},"' _n
file write `fh' `""tau_menos":{"directos":`=trim(string(scalar(NTATmenDir0), "`fm'"))',"cuotas":`=trim(string(scalar(NTACuotasNac), "`fm'"))',"cuotas_ancla":"$nta_cuotas","CuotasHogS14_D61_menos_D614":`=trim(string(`CuotasHogS14', "`fm'"))',"LIF_CUOTAS":`=trim(string(`CUOTAS', "`fm'"))',"indirectos":`=trim(string(scalar(NTATmenInd0), "`fm'"))',"fuera_ISRPM_OTROSK":`=trim(string(scalar(NTATmenFueraNac), "`fm'"))',"LIF_ISRPM":`=trim(string(`ISRPM', "`fm'"))',"LIF_OTROSK":`=trim(string(`OTROSK', "`fm'"))'},"' _n
file write `fh' `""congob":{"ConGob":`=trim(string(`ConGob', "`fm'"))',"individual_D63":`=trim(string(scalar(NTACpubIndNac), "`fm'"))',"TransfEspecie":`=trim(string(`TransfEspecie', "`fm'"))',"educacion":`=trim(string(scalar(NTACpubEduc0), "`fm'"))',"salud":`=trim(string(scalar(NTACpubSalud0), "`fm'"))',"resto_individual_per_capita":`=trim(string(scalar(NTACpubRestoInd0), "`fm'"))',"colectivo_per_capita":`=trim(string(scalar(NTACpubColNac), "`fm'"))',"factor_educ_salud":`=trim(string(`fEsp', "%12.8f"))',"regla":"individual = D.63 con perfil de edad (educación matrícula, salud ∝ gasto privado, resto per cápita) = τ⁺ en especie; colectivo = ConGob − D.63 per cápita = τ⁺ colectivo; ambos en C público"},"' _n
file write `fh' `""grupos":["' _n
forvalues g = 0/5 {
	if `g' == 0 local lab "Total"
	else local lab : label grupoedad `g'
	file write `fh' `"`=cond(`g' > 0, ",", "")'{"g":`g',"grupo":"`lab'","pob":`=trim(string(scalar(NTAPob`g'), "%20.0f"))'"'
	foreach v in `vars' {
		file write `fh' `","`v'":`=trim(string(scalar(NTA`v'`g'), "`fm'"))'"'
	}
	if `g' > 0 {
		file write `fh' `","IntraPos":`=trim(string(scalar(NTAIntraPos`g'), "`fm'"))',"IntraNeg":`=trim(string(scalar(NTAIntraNeg`g'), "`fm'"))'"'
	}
	file write `fh' "}" _n
}
file write `fh' `"],"' _n
file write `fh' `""sexo":[{"sexo":"Hombres","pob":`=trim(string(scalar(NTAPobH), "%20.0f"))',"S":`=trim(string(scalar(NTASH), "`fm'"))',"Intra":`=trim(string(scalar(NTAIntraH), "`fm'"))',"YL":`=trim(string(scalar(NTAYLH), "`fm'"))',"YA":`=trim(string(scalar(NTAYAH), "`fm'"))',"C":`=trim(string(scalar(NTACH), "`fm'"))',"Tmen":`=trim(string(scalar(NTATmenH), "`fm'"))',"Tpub":`=trim(string(scalar(NTATpubH), "`fm'"))'},"' _n
file write `fh' `"{"sexo":"Mujeres","pob":`=trim(string(scalar(NTAPobM), "%20.0f"))',"S":`=trim(string(scalar(NTASM), "`fm'"))',"Intra":`=trim(string(scalar(NTAIntraM), "`fm'"))',"YL":`=trim(string(scalar(NTAYLM), "`fm'"))',"YA":`=trim(string(scalar(NTAYAM), "`fm'"))',"C":`=trim(string(scalar(NTACM), "`fm'"))',"Tmen":`=trim(string(scalar(NTATmenM), "`fm'"))',"Tpub":`=trim(string(scalar(NTATpubM), "`fm'"))'}],"' _n
file write `fh' `""gates":{"residual_max_persona":`=trim(string(`maxres', "%12.4e"))',"residual_max_quinq_sexo":`=trim(string(`maxres_qs', "%12.4e"))',"intra_nacional":`=trim(string(`Intra_nac', "%16.4f"))',"intra_hogar_max":`=trim(string(`maxintra_hog', "%12.4e"))',"S_menos_AhorroHog":`=trim(string(`S_nac' - `AhorroHog', "%16.4f"))',"ok":`ok'},"' _n
file write `fh' `""flags":["'
local nf = 0
foreach f of local flags {
	local ++nf
	file write `fh' `"`=cond(`nf' > 1, ",", "")'"`f'""'
}
file write `fh' `"],"' _n
file write `fh' `""procedencia":{"modulo":"01_modulos/NTA.do v1.3 (NTA-3)","base":"master/`anio'/households.dta + raw/ENIGH/`anio'/{poblacion,ingresos,gastohogar}.dta","anclas":"SCN/LIF/PEF `anio' (escalar); S.14 de CSI_115.xlsx y S.1 de CSI_103.xlsx via SCN.ado","generado_el":"`fecha' $S_TIME","stata":"`c(stata_version)' `c(edition_real)'"}}"' _n
file close `fh'

* 6.3 JSON quinquenio × sexo (desde el colapsado) *
preserve
use `qs', clear
file open `fh' using `"`dirnta'/nta-quinquenio-sexo.json"', write replace text
file write `fh' `"{"esquema":"nta/v1","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"quinquenio x sexo","' _n
file write `fh' `""identidad":"C - YL - ImpProd - (tau_mas - tau_menos) - (YA - YA_ajuste - S_sinancla) - intra = residual (sin ancla)","residual_max":`=trim(string(`maxres_qs', "%12.4e"))',"' _n
file write `fh' `""celdas":["' _n
forvalues i = 1/`=_N' {
	local ql : label quinq `=quinq[`i']'
	local sl : label sexo `=sexo[`i']'
	file write `fh' `"`=cond(`i' > 1, ",", "")'{"q":`=quinq[`i']',"quinquenio":"`ql'","s":`=sexo[`i']',"sexo":"`sl'","pob":`=trim(string(pobw[`i'], "%20.0f"))'"'
	foreach v in `vars' {
		file write `fh' `","`v'":`=trim(string(`v'[`i'], "`fm'"))'"'
	}
	file write `fh' "}" _n
}
file write `fh' `"],"procedencia":{"modulo":"01_modulos/NTA.do v1.3 (NTA-3)","generado_el":"`fecha' $S_TIME"}}"' _n
file close `fh'
* 6.3b S e intra-hogar por quinquenio × sexo al reporte de texto (NTA-1b pieza 7) *
file open `fh' using `"`dirnta'/nta-identidad.txt"', write append text
file write `fh' _n "S e intra-hogar por quinquenio × sexo (bn; S sin ajuste salvo nta_anclaS ≠ off). |R|/C máx " %9.2e (`maxres_qs'/`Ctot') _n
file write `fh' %-8s ("Edad") %-9s ("Sexo") %8s ("Pob(M)") %10s ("C") %10s ("YL") %10s ("YA") %10s ("tau-pub") %10s ("tau+pub") %10s ("S") %10s ("intra") %10s ("R") _n
forvalues i = 1/`=_N' {
	local ql : label quinq `=quinq[`i']'
	local sl : label sexo `=sexo[`i']'
	file write `fh' %-8s ("`ql'") %-9s ("`sl'") %8.1f (pobw[`i']/1e6) `f1' (C[`i']/1e9) `f1' (YL[`i']/1e9) `f1' (YA[`i']/1e9) `f1' (Tmen[`i']/1e9) `f1' (Tpub[`i']/1e9) `f1' (S[`i']/1e9) `f1' (Intra[`i']/1e9) %10.6f (resid_chk[`i']/1e9) _n
}
file close `fh'
restore



**********************************
**# 7. Sankey v2 (solo el JSON; contrato nuevo, users/$id/SankeyNTA/sankey-v2-grupoedad.json)
**********************************
* Columnas: Fuentes (grupos como perceptores, OyE públicas, El mundo, Desahorro por grupo, balances) →
* Tipos de ingreso (laboral, capital, alquiler propio, remesas) → Ing nacional → Reasignaciones (Ingreso por
* grupo → Gobierno / Familias / Activos; τ⁺ efectivo, inter recibido + remesas, intra y desahorro salen por
* grupo hacia Consumo por grupo; la especie sale de Gobierno a las categorías públicas) → Usos (categorías
* privadas y públicas) → Sinks (grupos como consumidores, Futuro por grupo, Resto del gasto público).
* Todo flujo ≥ 0; cada nodo intermedio conserva entradas = salidas (lo verifica test-nta-identidad.sh).
* Intra-hogar y S van NETOS por grupo (brutos entre grupos: un grupo entra o sale de Familias/Activos);
* los brutos por persona (IntraPos/IntraNeg) quedan en nta-grupoedad.json. El ajuste del ancla de S (solo con
* nta_anclaS = aditivo) es un tipo de ingreso aparte ("Ajuste ancla S.14"), no se esconde en el capital; con el
* default off vale 0 y SankeySumSim no emite el nodo.
* NTA-1b (contrato v2.1): en la columna de tipos de ingreso se agregan «Impuestos a productos» (ImpProd ∝ Cpriv) y
* «Derechos de pensión D8» (YA_d8); «Ing capital» es YA sin D.8, sin ajuste y sin alquiler. Las categorías públicas
* son «Educación pública», «Salud pública», «Otros en especie» (las tres suman D.63: en especie con edad) y
* «Colectivo per cápita» (ConGob − D.63). Con ISR_PM y OTROSK fuera de τ⁻, el balance del gobierno suele ser
* negativo: entra como fuente «Déficit público». test-nta-identidad.sh exige estos nodos.
* Compras netas de no residentes: ya restadas de C (gasto_anualComprasN), por eso no hay nodo "Turistas".
local BF = scalar(NTAInterRec0) - scalar(NTAInterOtor0)
local BG = scalar(NTATmen0) + `OyE' - scalar(NTATpubEf0) - scalar(NTACpub0)
local lbl3 `"1 "Ingreso 0 a 4" 2 "Ingreso 5 a 17" 3 "Ingreso 18 a 24" 4 "Ingreso 25 a 64" 5 "Ingreso 65 y más" 11 "Gobierno" 12 "Familias" 13 "Activos" 21 "Desahorro 0 a 4" 22 "Desahorro 5 a 17" 23 "Desahorro 18 a 24" 24 "Desahorro 25 a 64" 25 "Desahorro 65 y más" 31 "Otras transferencias privadas" 32 "Déficit público" 41 "Consumo 0 a 4" 42 "Consumo 5 a 17" 43 "Consumo 18 a 24" 44 "Consumo 25 a 64" 45 "Consumo 65 y más" 51 "_De 0 a 4" 52 "_De 5 a 17" 53 "_De 18 a 24" 54 "_De 25 a 64" 55 "_De 65 y más" 61 "Futuro 0 a 4" 62 "Futuro 5 a 17" 63 "Futuro 18 a 24" 64 "Futuro 25 a 64" 65 "Futuro 65 y más" 71 "Resto del gasto público" 72 "Transferencias privadas netas" 81 "Ancla S14 recorte" 82 "Ancla S14 complemento" 999 "Ing nacional""'
quietly {
	tempfile per2 e1 e2 e3 e4 e5
	save `per2'

	* --- Eje 1: perceptores → tipos de ingreso (+ El mundo → Remesas, OyE → capital) --- *
	g double nta_YK = YA - YA_d8 - YA_ajuste - ALQ
	collapse (sum) ing_Ing_laboral=YL ing_Ing_capital=nta_YK ing_Alquiler_propio=ALQ ing_Impuestos_a_productos=ImpProd ing_Derechos_de_pensión_D8=YA_d8 ing_Ajuste_ancla_S_14=YA_ajuste ing_Remesas=Remesas [fw=factor], by(grupoedad)
	reshape long ing_, i(grupoedad) j(tipo) string
	rename ing_ profile
	replace grupoedad = -1 if tipo == "Remesas"
	collapse (sum) profile, by(grupoedad tipo)
	set obs `=_N+1'
	replace grupoedad = -2 in -1
	replace tipo = "Ing_capital" in -1
	replace profile = `OyE' in -1
	encode tipo, g(to)
	rename grupoedad from
	label define grupoedad -1 "El mundo" -2 "OyE públicas", add
	label values from grupoedad
	drop tipo
	save `e1'

	* --- Eje 2: tipos de ingreso → Ing nacional --- *
	collapse (sum) profile, by(to)
	rename to from
	g to = 999
	label define n3 `lbl3'
	label values to n3
	save `e2'

	* --- Eje 3: Ing nacional → Ingreso por grupo / Gobierno (OyE) / Familias (remesas); fuentes → Activos, balances --- *
	clear
	set obs 7
	g from = 999
	g to = _n
	g double profile = .
	forvalues g = 1/5 {
		replace profile = scalar(NTAYL`g') + scalar(NTAYA`g') + scalar(NTAImpProd`g') in `g'
	}
	replace to = 11 in 6
	replace profile = `OyE' in 6
	replace to = 12 in 7
	replace profile = scalar(NTARemesas0) in 7
	forvalues g = 1/5 {
		if scalar(NTAS`g') < 0 {
			set obs `=_N+1'
			replace from = 20 + `g' in -1
			replace to = 13 in -1
			replace profile = -scalar(NTAS`g') in -1
		}
	}
	if `BF' > 0 {
		set obs `=_N+1'
		replace from = 31 in -1
		replace to = 12 in -1
		replace profile = `BF' in -1
	}
	if `BG' < 0 {
		set obs `=_N+1'
		replace from = 32 in -1
		replace to = 11 in -1
		replace profile = -`BG' in -1
	}
	label define n3 `lbl3'
	label values from n3
	label values to n3
	save `e3'

	* --- Eje 4: Ingreso g → Gobierno/Familias/Activos/Consumo g; Gobierno/Familias/Activos → Consumo g --- *
	clear
	set obs 1
	g from = .
	g to = .
	g double profile = .
	drop in 1
	forvalues g = 1/5 {
		local Y = scalar(NTAYL`g') + scalar(NTAYA`g') + scalar(NTAImpProd`g')
		local Spos = max(scalar(NTAS`g'), 0)
		local Sneg = max(-scalar(NTAS`g'), 0)
		local Ipos = max(scalar(NTAIntra`g'), 0)
		local Ineg = max(-scalar(NTAIntra`g'), 0)
		* ancla multiplicativa (NTA-1c): d = S sin ancla − S anclado; d > 0 sale de Ingreso g al sink «Ancla S14 recorte»,
		* d < 0 entra a Consumo g desde la fuente «Ancla S14 complemento»; así Ingreso g y Consumo g conservan *
		local d = -scalar(NTAS_ajuste`g')
		local propio = `Y' - scalar(NTATmen`g') - scalar(NTAInterOtor`g') - `Ineg' - `Spos' - max(`d', 0)
		local salidas `"11 `=scalar(NTATmen`g')' 12 `=scalar(NTAInterOtor`g') + `Ineg'' 13 `Spos' `=40+`g'' `propio' 81 `=max(`d', 0)'"'
		local entradas `"11 `=scalar(NTATpubEf`g')' 12 `=scalar(NTAInterRec`g') + scalar(NTARemesas`g') + `Ipos'' 13 `Sneg' 82 `=max(-`d', 0)'"'
		while "`salidas'" != "" {
			gettoken dest salidas : salidas
			gettoken val salidas : salidas
			set obs `=_N+1'
			replace from = `g' in -1
			replace to = `dest' in -1
			replace profile = `val' in -1
		}
		while "`entradas'" != "" {
			gettoken src entradas : entradas
			gettoken val entradas : entradas
			set obs `=_N+1'
			replace from = `src' in -1
			replace to = 40 + `g' in -1
			replace profile = `val' in -1
		}
	}
	label define n3 `lbl3'
	label values from n3
	label values to n3
	save `e4'

	* --- Eje 5: Consumo g → categorías privadas; Gobierno → categorías públicas; categorías → grupos consumidores;
	*     Activos → Futuro g; Gobierno → Resto del gasto público; Familias → Transferencias privadas netas --- *
	use `per2', clear
	egen double sk_Alimentos = rsum(gas_pc_Agua gas_pc_Alim gas_pc_BebN)
	egen double sk_Vestido = rsum(gas_pc_Vest gas_pc_Calz)
	egen double sk_Salud = rsum(gas_pc_SaluT)
	egen double sk_Educación = rsum(gas_pc_EducT gas_pc_RecrT)
	egen double sk_Vivienda = rsum(gas_pc_Alqu gas_pc_HogaT gas_pc_ComuT gas_pc_Elec)
	egen double sk_Transporte = rsum(gas_pc_Vehi gas_pc_STra gas_pc_FTra)
	egen double sk_Otros_gastos = rsum(gas_pc_Taba gas_pc_BebA gas_pc_DiveT gas_pc_RestT)
	foreach v of varlist sk_* {
		replace `v' = `v' + gasto_anualComprasN*`v'/gastoanualTOT if gastoanualTOT > 0
	}
	g double sk_Educación_pública = CpubEduc
	g double sk_Salud_pública = CpubSalud
	g double sk_Otros_en_especie = CpubRestoInd
	g double sk_Colectivo_per_cápita = CpubCol
	collapse (sum) sk_* [fw=factor], by(grupoedad)
	reshape long sk_, i(grupoedad) j(cat) string
	rename sk_ profile
	g byte publica = inlist(cat, "Educación_pública", "Salud_pública", "Otros_en_especie", "Colectivo_per_cápita")
	encode cat, g(catn)
	label define n3 `lbl3'
	levelsof catn, local(cats)
	foreach c of local cats {
		local cl : label catn `c'
		label define n3 `=100+`c'' "`cl'", add
	}
	* categoría → grupo consumidor *
	g from = 100 + catn
	g to = 50 + grupoedad
	tempfile c2
	save `c2'
	* Consumo g → categoría privada; Gobierno → categoría pública *
	replace from = cond(publica, 11, 40 + grupoedad)
	replace to = 100 + catn
	append using `c2'
	keep from to profile
	collapse (sum) profile, by(from to)
	forvalues g = 1/5 {
		if scalar(NTAS`g') > 0 {
			set obs `=_N+1'
			replace from = 13 in -1
			replace to = 60 + `g' in -1
			replace profile = scalar(NTAS`g') in -1
		}
	}
	if `BG' > 0 {
		set obs `=_N+1'
		replace from = 11 in -1
		replace to = 71 in -1
		replace profile = `BG' in -1
	}
	if `BF' < 0 {
		set obs `=_N+1'
		replace from = 12 in -1
		replace to = 72 in -1
		replace profile = -`BF' in -1
	}
	label values from n3
	label values to n3
	save `e5'

	local negs = 0
	foreach e in `e1' `e2' `e3' `e4' `e5' {
		use `e', clear
		count if profile < 0
		local negs = `negs' + r(N)
	}
	use `per2', clear
}
if `negs' > 0 {
	local ok = 0
	noisily di as err "  GATE NTA Sankey v2: `negs' enlace(s) negativos (un grupo con ingreso propio insuficiente)."
}
escalar mxn NTASankeyBalGob = `BG'
escalar mxn NTASankeyBalFam = `BF'
noisily SankeySumSim, anio(`anio') name(v2-grupoedad) folder(SankeyNTA) a(`e1') b(`e2') c(`e3') d(`e4') e(`e5')
quietly use `per2', clear
noisily di in g "  Sankey v2: balance Gobierno " in y %20.0fc `BG' in g " (τ⁻ + OyE − τ⁺ efectivo − especie); balance Familias " in y %20.0fc `BF' in g " (recibido − otorgado)"



**********************************
**# 7b. Sankey v3 (NTA-3, 2026-10-29): edades solo al inicio y al final (users/$id/SankeyNTA/sankey-v3-grupoedad.json)
**********************************
* Decisión de Ricardo (2026-10-29): el gráfico principal de /NTA lleva las edades solo como perceptores (izquierda) y como
* consumidores (derecha); se eliminan los ejes «Ingreso g» y «Consumo g» y el nodo «Familias». Las transferencias en efectivo,
* inter e intra-hogar netean a cero nacionalmente (lo que un grupo recibe otro lo paga), así que el v3 no las dibuja por grupo:
* la cuenta por grupo × sexo, con efectivo e inter/intra-hogar, vive en el panel (§7c). El v2 (§7) se sigue emitiendo.
* Columnas: Fuentes (grupos perceptores, OyE públicas, El mundo, Desahorro g, balances declarados) → Tipos de ingreso (laboral,
* capital, alquiler propio, impuestos a productos, D.8, remesas; mismos ejes 1 y 2 que el v2) → Ing nacional → Gobierno (entran
* τ⁻ + OyE; salen Educación/Salud pública y Otros en especie por edad, Colectivo sin edad y «Transferencias en efectivo» a un
* nodo único) y Activos (entra el S sin ancla de los grupos que ahorran y el desahorro de los que no; salen Futuro g, «Ancla S14
* recorte» y el desahorro hacia las categorías) → Usos (7 categorías privadas, 3 en especie, Colectivo, Transferencias en
* efectivo) → Sinks (grupos consumidores, Futuro g, Colectivo).
* Financiamiento del consumo privado (lo que v2 resolvía en «Consumo g»): cada categoría recibe de Ing nacional lo que los grupos
* pagan con ingreso PROPIO (Y − τ⁻ − S⁺ − recorte + inter recibido + remesas + intra − inter otorgado), de «Transferencias en
* efectivo» lo pagado con τ⁺ efectivo y de Activos lo pagado con desahorro (+ complemento del ancla), cada flujo de cada grupo
* repartido por la CANASTA del grupo (Cpriv_gc / Cpriv_g): propio + efectivo + desahorro = Cpriv_g por la identidad, así que
* Σ entradas de cada categoría = Σ_g Cpriv_gc = sus salidas a los grupos consumidores.
* Balances como en v2: «Déficit público» → Gobierno si τ⁻ + OyE < τ⁺ efectivo + Cpub (si no Gobierno → «Resto del gasto
* público»); «Otras transferencias privadas» → Ing nacional si inter recibido > otorgado (si no Ing nacional → «Transferencias
* privadas netas»). Ancla multiplicativa declarada (d_g = S sin ancla − S anclado): Activos → «Ancla S14 recorte» Σ_g max(d_g, 0);
* «Ancla S14 complemento» → Activos Σ_g max(−d_g, 0). Conservación en todo nodo intermedio; test-nta-identidad.sh B lo exige.
local lbl4 `"11 "Gobierno" 13 "Activos" 14 "Transferencias en efectivo" 21 "Desahorro 0 a 4" 22 "Desahorro 5 a 17" 23 "Desahorro 18 a 24" 24 "Desahorro 25 a 64" 25 "Desahorro 65 y más" 31 "Otras transferencias privadas" 32 "Déficit público" 51 "_De 0 a 4" 52 "_De 5 a 17" 53 "_De 18 a 24" 54 "_De 25 a 64" 55 "_De 65 y más" 61 "Futuro 0 a 4" 62 "Futuro 5 a 17" 63 "Futuro 18 a 24" 64 "Futuro 25 a 64" 65 "Futuro 65 y más" 71 "Resto del gasto público" 72 "Transferencias privadas netas" 81 "Ancla S14 recorte" 82 "Ancla S14 complemento" 999 "Ing nacional""'
quietly {
	tempfile catg fin f3 f4 f5

	* --- Categorías por grupo (misma receta que §7 eje 5; «Colectivo» sin edad reemplaza a «Colectivo per cápita») --- *
	use `per2', clear
	egen double sk_Alimentos = rsum(gas_pc_Agua gas_pc_Alim gas_pc_BebN)
	egen double sk_Vestido = rsum(gas_pc_Vest gas_pc_Calz)
	egen double sk_Salud = rsum(gas_pc_SaluT)
	egen double sk_Educación = rsum(gas_pc_EducT gas_pc_RecrT)
	egen double sk_Vivienda = rsum(gas_pc_Alqu gas_pc_HogaT gas_pc_ComuT gas_pc_Elec)
	egen double sk_Transporte = rsum(gas_pc_Vehi gas_pc_STra gas_pc_FTra)
	egen double sk_Otros_gastos = rsum(gas_pc_Taba gas_pc_BebA gas_pc_DiveT gas_pc_RestT)
	foreach v of varlist sk_* {
		replace `v' = `v' + gasto_anualComprasN*`v'/gastoanualTOT if gastoanualTOT > 0
	}
	g double sk_Educación_pública = CpubEduc
	g double sk_Salud_pública = CpubSalud
	g double sk_Otros_en_especie = CpubRestoInd
	g double sk_Colectivo = CpubCol
	collapse (sum) sk_* [fw=factor], by(grupoedad)
	reshape long sk_, i(grupoedad) j(cat) string
	rename sk_ profile
	g byte publica = inlist(cat, "Educación_pública", "Salud_pública", "Otros_en_especie", "Colectivo")
	encode cat, g(catn)
	levelsof catn, local(cats)
	local lblcat ""
	foreach c of local cats {
		local cl : label catn `c'
		local lblcat `"`lblcat' `=100+`c'' "`cl'""'
	}
	* canasta privada del grupo: participación de cada categoría privada en Cpriv_g *
	egen double cpriv_g = total(cond(publica, 0, profile)), by(grupoedad)
	g double share = cond(publica, ., profile/cpriv_g)
	save `catg'

	* --- Financiamiento del consumo privado por categoría: propio (desde Ing nacional), efectivo (desde Transferencias en
	*     efectivo) y desahorro + complemento (desde Activos), cada grupo repartido por su canasta --- *
	keep if !publica
	g double v_propio = .
	g double v_efectivo = .
	g double v_desahorro = .
	local Spos_tot = 0
	local Sneg_tot = 0
	local rec_tot = 0
	local comp_tot = 0
	forvalues g = 1/5 {
		local d = -scalar(NTAS_ajuste`g')
		local propio = scalar(NTAYL`g') + scalar(NTAYA`g') + scalar(NTAImpProd`g') - scalar(NTATmen`g') - max(scalar(NTAS`g'), 0) - max(`d', 0) ///
			+ scalar(NTAInterRec`g') + scalar(NTARemesas`g') + scalar(NTAIntra`g') - scalar(NTAInterOtor`g')
		replace v_propio = share*(`propio') if grupoedad == `g'
		replace v_efectivo = share*scalar(NTATpubEf`g') if grupoedad == `g'
		replace v_desahorro = share*(max(-scalar(NTAS`g'), 0) + max(-`d', 0)) if grupoedad == `g'
		local Spos_tot = `Spos_tot' + max(scalar(NTAS`g'), 0)
		local Sneg_tot = `Sneg_tot' + max(-scalar(NTAS`g'), 0)
		local rec_tot = `rec_tot' + max(`d', 0)
		local comp_tot = `comp_tot' + max(-`d', 0)
	}
	collapse (sum) v_propio v_efectivo v_desahorro, by(catn)
	save `fin'

	* --- Eje 3: Ing nacional → Gobierno (τ⁻ + OyE) / Activos (S sin ancla de los que ahorran) / categorías privadas (propio);
	*     fuentes → Ing nacional (Otras transferencias privadas), → Gobierno (Déficit público), → Activos (Desahorro g, complemento) --- *
	g from = 999
	g to = 100 + catn
	g double profile = v_propio
	keep from to profile
	set obs `=_N+1'
	replace from = 999 in -1
	replace to = 11 in -1
	replace profile = scalar(NTATmen0) + `OyE' in -1
	set obs `=_N+1'
	replace from = 999 in -1
	replace to = 13 in -1
	replace profile = `Spos_tot' + `rec_tot' in -1
	forvalues g = 1/5 {
		if scalar(NTAS`g') < 0 {
			set obs `=_N+1'
			replace from = 20 + `g' in -1
			replace to = 13 in -1
			replace profile = -scalar(NTAS`g') in -1
		}
	}
	if `comp_tot' > 0 {
		set obs `=_N+1'
		replace from = 82 in -1
		replace to = 13 in -1
		replace profile = `comp_tot' in -1
	}
	if `BF' > 0 {
		set obs `=_N+1'
		replace from = 31 in -1
		replace to = 999 in -1
		replace profile = `BF' in -1
	}
	if `BF' < 0 {
		set obs `=_N+1'
		replace from = 999 in -1
		replace to = 72 in -1
		replace profile = -`BF' in -1
	}
	if `BG' < 0 {
		set obs `=_N+1'
		replace from = 32 in -1
		replace to = 11 in -1
		replace profile = -`BG' in -1
	}
	label define n4 `lbl4' `lblcat'
	label values from n4
	label values to n4
	save `f3'

	* --- Eje 4: Gobierno → categorías públicas (especie por edad y Colectivo) y → Transferencias en efectivo (τ⁺ efectivo);
	*     Transferencias en efectivo → categorías privadas; Activos → categorías privadas (desahorro), → Futuro g, → Ancla S14 recorte;
	*     Gobierno → Resto del gasto público --- *
	use `fin', clear
	g from = 14
	g to = 100 + catn
	g double profile = v_efectivo
	keep from to profile
	tempfile f4a
	save `f4a'
	use `fin', clear
	g from = 13
	g to = 100 + catn
	g double profile = v_desahorro
	keep from to profile
	append using `f4a'
	save `f4a', replace
	use `catg', clear
	keep if publica
	collapse (sum) profile, by(catn)
	g from = 11
	g to = 100 + catn
	keep from to profile
	append using `f4a'
	set obs `=_N+1'
	replace from = 11 in -1
	replace to = 14 in -1
	replace profile = scalar(NTATpubEf0) in -1
	forvalues g = 1/5 {
		if scalar(NTAS`g') > 0 {
			set obs `=_N+1'
			replace from = 13 in -1
			replace to = 60 + `g' in -1
			replace profile = scalar(NTAS`g') in -1
		}
	}
	if `rec_tot' > 0 {
		set obs `=_N+1'
		replace from = 13 in -1
		replace to = 81 in -1
		replace profile = `rec_tot' in -1
	}
	if `BG' > 0 {
		set obs `=_N+1'
		replace from = 11 in -1
		replace to = 71 in -1
		replace profile = `BG' in -1
	}
	label define n4 `lbl4' `lblcat'
	label values from n4
	label values to n4
	save `f4'

	* --- Eje 5: categorías (privadas y en especie) → grupos consumidores; Colectivo es terminal (sin edad) --- *
	use `catg', clear
	drop if cat == "Colectivo"
	g from = 100 + catn
	g to = 50 + grupoedad
	keep from to profile
	label define n4 `lbl4' `lblcat'
	label values from n4
	label values to n4
	save `f5'

	local negs3 = 0
	foreach e in `f3' `f4' `f5' {
		use `e', clear
		count if profile < 0
		local negs3 = `negs3' + r(N)
	}
	use `per2', clear
}
if `negs3' > 0 {
	local ok = 0
	noisily di as err "  GATE NTA Sankey v3: `negs3' enlace(s) negativos (un grupo con ingreso propio insuficiente para su canasta)."
}
noisily SankeySumSim, anio(`anio') name(v3-grupoedad) folder(SankeyNTA) a(`e1') b(`e2') c(`f3') d(`f4') e(`f5')
quietly use `per2', clear
noisily di in g "  Sankey v3: Ing nacional → Gobierno " in y %20.0fc scalar(NTATmen0) + `OyE' in g " (τ⁻ + OyE); → Activos " in y %20.0fc `Spos_tot' + `rec_tot' in g " (S sin ancla de los que ahorran); Transferencias en efectivo " in y %20.0fc scalar(NTATpubEf0) in g "; desahorro + complemento a categorías " in y %20.0fc `Sneg_tot' + `comp_tot' in g "; recorte " in y %20.0fc `rec_tot'



**********************************
**# 7c. Panel por grupo de edad × sexo (NTA-3): users/$id/NTA/nta-panel-grupoedad-sexo.json
**********************************
* Un mini-Sankey de dos columnas por celda grupo (5) × sexo (Total, Hombres, Mujeres): entradas → «grupo» → salidas.
* Entradas: YL; YA (con D.8) + impuestos a productos; τ⁺ efectivo; τ⁺ especie (D.63); τ⁺ colectivo; inter-hogar recibido (donativos,
* herencias y remesas); intra-hogar recibido (Σ de los intra > 0 por persona); desahorro (−S de la celda si S < 0); «Ancla S14
* complemento» (S − S sin ancla de la celda, si > 0). Salidas: C privado; C público en especie; C colectivo; τ⁻; inter-hogar
* otorgado; intra-hogar otorgado (Σ de los intra < 0 por persona); S (de la celda, si > 0); «Ancla S14 recorte» (S sin ancla − S,
* si > 0). Σ entradas = Σ salidas en cada celda por la identidad del gate (C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − S sin ancla) − intra
* = 0) con el ancla declarada: S es el anclado (Σ = B.8n) como en el v3. Aquí sí se ven el efectivo y lo inter/intra-hogar que el
* v3 no dibuja. Formato scalarjson: números crudos a 17 dígitos significativos (round-trip exacto del double), nada de literales;
* generado_el aislado como última clave de procedencia. La página /NTA lee las tres variantes (T/H/M) de este único archivo.
capture program drop _ntanum
program define _ntanum, rclass
	args e
	local s = trim(string(`e', "%25.17g"))
	if substr("`s'", 1, 1) == "." local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end
local pan_in "YL YA TpubEf TpubEsp TpubCol InterRec IntraRec Desahorro AnclaComplemento"
local pan_out "Cpriv CpubEsp CpubCol Tmen InterOtor IntraOtor S AnclaRecorte"
quietly {
	tempfile pan
	g double IntraPos = max(Intra, 0)
	g double IntraNeg = max(-Intra, 0)
	g double pobw = 1
	g byte sexo3 = sexo
	save `pan'
	replace sexo3 = 0
	append using `pan'
	collapse (sum) YL YA ImpProd YA_d8 TpubEf TpubEsp TpubCol InterRec Remesas IntraPos IntraNeg S S_sinancla S_ajuste Cpriv CpubInd CpubCol C Tmen InterOtor pobw [fw=factor], by(grupoedad sexo3)
	sort grupoedad sexo3
	g double in_YL = YL
	g double in_YA = YA + ImpProd
	g double in_TpubEf = TpubEf
	g double in_TpubEsp = TpubEsp
	g double in_TpubCol = TpubCol
	g double in_InterRec = InterRec + Remesas
	g double in_IntraRec = IntraPos
	g double in_Desahorro = max(-S, 0)
	g double in_AnclaComplemento = max(S_ajuste, 0)
	g double out_Cpriv = Cpriv
	g double out_CpubEsp = CpubInd
	g double out_CpubCol = CpubCol
	g double out_Tmen = Tmen
	g double out_InterOtor = InterOtor
	g double out_IntraOtor = IntraNeg
	g double out_S = max(S, 0)
	g double out_AnclaRecorte = max(-S_ajuste, 0)
	egen double entradas = rowtotal(in_*)
	egen double salidas = rowtotal(out_*)
	g double balance = entradas - salidas
	g double balrel = abs(balance)/C
	summarize balrel, meanonly
	local balmax = r(max)
	g double deficit_cv = C - YL
	local ncel = _N
}
local okpan = cond(`balmax' <= `tol', 1, 0)
if `okpan' == 0 {
	local ok = 0
	noisily di as err "  GATE NTA panel: alguna celda grupo × sexo no balancea (|entradas − salidas|/C máx " %9.2e `balmax' ")"
}
file open `fh' using `"`dirnta'/nta-panel-grupoedad-sexo.json"', write replace text
file write `fh' `"{"esquema":"nta-panel/v1","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"grupoedad x sexo","' _n
file write `fh' `""identidad":"Σ entradas = Σ salidas en cada celda: YL + (YA + ImpProd) + tau_pub_efectivo + tau_pub_especie + tau_pub_colectivo + (inter_recibido + remesas) + intra_recibido + desahorro + ancla_complemento = Cpriv + Cpub_especie + Cpub_colectivo + tau_menos + inter_otorgado + intra_otorgado + S + ancla_recorte; es la identidad del gate (C - YL - ImpProd - (tau_mas - tau_menos) - (YA - S_sinancla) - intra = 0) con S anclado (S = S_sinancla + S_ajuste) y el ajuste declarado como ancla","' _n
file write `fh' `""regla":"intra_recibido / intra_otorgado = sumas por persona de max(intra, 0) / max(-intra, 0); desahorro / S = -S / S de la celda segun su signo; ancla_complemento / ancla_recorte = S_ajuste / -S_ajuste de la celda segun su signo; S es el anclado (nta_anclaS=$nta_anclaS)","' _n
file write `fh' `""parametros":{"nta_anclaS":"$nta_anclaS","nta_YA":"$nta_YA","nta_cuotas":"$nta_cuotas","nta_d8":"$nta_d8","nta_anclaTau":"$nta_anclaTau","nta_alqu":"$nta_alqu","nta_tauCash":"$nta_tauCash","nta_otorgado":"$nta_otorgado","nta_mixto":"$nta_mixto","tolerancia":1e-9},"' _n
file write `fh' `""sexos":[{"s":"T","sexo":"Total"},{"s":"H","sexo":"Hombres"},{"s":"M","sexo":"Mujeres"}],"' _n
file write `fh' `""grupos":["'
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' `"`=cond(`g' > 1, ",", "")'{"g":`g',"grupo":"`lab'"}"'
}
file write `fh' `"],"' _n
file write `fh' `""entradas":[{"id":"YL","etiqueta":"Ing laboral","variables":"YL"},{"id":"YA","etiqueta":"Ing activos + imp productos","variables":"YA + ImpProd (YA incluye YA_d8)"},{"id":"TpubEf","etiqueta":"τ⁺ efectivo","variables":"TpubEf"},{"id":"TpubEsp","etiqueta":"τ⁺ especie","variables":"TpubEsp"},{"id":"TpubCol","etiqueta":"τ⁺ colectivo","variables":"TpubCol"},{"id":"InterRec","etiqueta":"Inter hogar recibido","variables":"InterRec + Remesas"},{"id":"IntraRec","etiqueta":"Intra hogar recibido","variables":"sum max(Intra, 0)"},{"id":"Desahorro","etiqueta":"Desahorro","variables":"max(-S, 0)"},{"id":"AnclaComplemento","etiqueta":"Ancla S14 complemento","variables":"max(S_ajuste, 0)"}],"' _n
file write `fh' `""salidas":[{"id":"Cpriv","etiqueta":"C privado","variables":"Cpriv"},{"id":"CpubEsp","etiqueta":"C público especie","variables":"CpubInd"},{"id":"CpubCol","etiqueta":"C colectivo","variables":"CpubCol"},{"id":"Tmen","etiqueta":"τ⁻","variables":"Tmen"},{"id":"InterOtor","etiqueta":"Inter hogar otorgado","variables":"InterOtor"},{"id":"IntraOtor","etiqueta":"Intra hogar otorgado","variables":"sum max(-Intra, 0)"},{"id":"S","etiqueta":"S","variables":"max(S, 0)"},{"id":"AnclaRecorte","etiqueta":"Ancla S14 recorte","variables":"max(-S_ajuste, 0)"}],"' _n
file write `fh' `""celdas":["' _n
forvalues i = 1/`ncel' {
	local g = grupoedad[`i']
	local s3 = sexo3[`i']
	local lab : label grupoedad `g'
	local sc = cond(`s3' == 0, "T", cond(`s3' == 1, "H", "M"))
	local sl = cond(`s3' == 0, "Total", cond(`s3' == 1, "Hombres", "Mujeres"))
	file write `fh' `"`=cond(`i' > 1, ",", "")'{"g":`g',"s":"`sc'","grupo":"`lab'","sexo":"`sl'","pob":`=trim(string(pobw[`i'], "%20.0f"))'"'
	foreach v in C YL deficit_cv S S_sinancla S_ajuste YA ImpProd YA_d8 Tmen InterRec Remesas InterOtor IntraPos IntraNeg Cpriv CpubInd CpubCol TpubEf TpubEsp TpubCol entradas salidas {
		_ntanum "`v'[`i']"
		file write `fh' `","`v'":`r(n)'"'
	}
	file write `fh' `","entradas_flujos":{"'
	local k = 0
	foreach v of local pan_in {
		local ++k
		_ntanum "in_`v'[`i']"
		file write `fh' `"`=cond(`k' > 1, ",", "")'"`v'":`r(n)'"'
	}
	file write `fh' `"},"salidas_flujos":{"'
	local k = 0
	foreach v of local pan_out {
		local ++k
		_ntanum "out_`v'[`i']"
		file write `fh' `"`=cond(`k' > 1, ",", "")'"`v'":`r(n)'"'
	}
	_ntanum "balance[`i']"
	file write `fh' `"},"balance":`r(n)'}"' _n
}
file write `fh' `"],"' _n
file write `fh' `""gates":{"celdas":`ncel',"balance_max_rel":`=trim(string(`balmax', "%12.4e"))',"tolerancia":1e-9,"ok":`okpan'},"' _n
file write `fh' `""procedencia":{"modulo":"01_modulos/NTA.do v1.3 (NTA-3)","base":"la misma cuenta por persona que users/$id/NTA/nta-persona.dta, agregada por grupoedad x sexo [fw=factor]","anclas":"SCN/LIF/PEF `anio' (escalar); S.14 de CSI_115.xlsx y S.1 de CSI_103.xlsx via SCN.ado","stata":"`c(stata_version)' `c(edition_real)'","generado_el":"`fecha' $S_TIME"}}"' _n
file close `fh'
noisily di in g "  Panel grupo × sexo: " in y `ncel' in g " celdas; |entradas − salidas|/C máx " in y %9.2e `balmax' in g " -> " in y cond(`okpan', "OK", "ROJO")
quietly use `per2', clear



**********************************
**# 8. Guardar la cuenta por persona
**********************************
quietly {
	keep folioviv foliohog numren factor edad sexo grupoedad quinq decil nta_hhid nta_jefe nta_adulto ///
		YL ImpProd YA YA_base YA_motor YA_d8 YA_ajuste ALQ Cpriv Cpub CpubInd CpubCol CpubEduc CpubSalud CpubRestoInd C ///
		Tmen TmenDir TmenCuotas TmenInd TmenFuera nta_ISRAS nta_ISRPF nta_CUOTAS nta_ISRPM nta_OTROSK nta_IVA nta_ISAN nta_IEPSNP nta_IEPSP nta_IMPORT ///
		Tpub TpubEf TpubEsp TpubCol TpubPens TpubPAM TpubProg InterRec Remesas InterOtor S S_sinancla S_ajuste Intra Resid ///
		nta_pens_enYl nta_mixto_transf nta_mixto_fin nta_rem_raw nta_share
	rename nta_hhid hhid
	rename nta_jefe jefe
	rename nta_adulto adulto
	rename nta_share share_adulto
	label var hhid "Hogar (folioviv foliohog)"
	label var jefe "Jefe del hogar (parentesco 101; respaldo: adulto de mayor edad)"
	label var adulto "Edad >= `adulto'"
	label var share_adulto "Participación del adulto en S e inter otorgado del hogar"
	char _dta[nta_anio] "`anio'"
	char _dta[nta_AhorroHog] "`AhorroHog'"
	char _dta[nta_TransfEspecie] "`TransfEspecie'"
	char _dta[nta_parametros] "nta_anclaS=$nta_anclaS nta_YA=$nta_YA nta_cuotas=$nta_cuotas nta_d8=$nta_d8 nta_anclaTau=$nta_anclaTau nta_alqu=$nta_alqu nta_tauCash=$nta_tauCash nta_otorgado=$nta_otorgado nta_mixto=$nta_mixto"
	compress
	save `"`dirnta'/nta-persona.dta"', replace
}
noisily di in g "  Salidas: " in y "users/$id/NTA/{nta-persona.dta, nta-grupoedad.json, nta-quinquenio-sexo.json, nta-identidad.txt, nta-panel-grupoedad-sexo.json}" in g " y " in y "users/$id/SankeyNTA/sankey-{v2,v3}-grupoedad.json"
if `ok' == 0 {
	noisily di as err "  NTA: algún gate interno quedó ROJO (ver arriba); 05_scripts/test-nta-identidad.sh lo confirma."
}
timer off 14
timer list 14
noisily di in g "{bf:Tiempo NTA:} " in y round(`=r(t14)/r(nt14)',.1) in g " segs."
