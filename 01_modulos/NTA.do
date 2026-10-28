*********************************************************************
***                                                               ***
***   NTA.do — Cuenta de Transferencias Nacionales por individuo  ***
***   (Lee–Mason), cerrada por grupo de edad y por quinquenio×sexo ***
***                                                               ***
*********************************************************************
* NTA-1 (2026-10-27). Base: memo 02_governance/nta-0-inventario-2026-10-27.md (#38) y las
* decisiones firmadas por Ricardo el 2026-10-27. Llamada (SIM.do §3.2b):
*   run NTA.do <anioenigh>        (2024: el único año con households.dta anclado a SCN/LIF/PEF 2024)
*
* IDENTIDAD (por persona, por grupo y nacional; el gate 05_scripts/test-nta-identidad.do la exige a 1e-9 relativo):
*     C − YL = (τ⁺ − τ⁻) + (YA − S)          con   τ⁺ − τ⁻ = τ⁺púb(efectivo + especie) − τ⁻púb + τ⁺inter − τ⁻inter + intra
*   y en la forma que exige el gate:  C − YL − (τ⁺ − τ⁻) − (YA − S) − intra = 0.
*
* QUÉ LEE (nada se construye por persona que no exista ya en el motor; lo que falta es parámetro + FLAG):
*   master/<anio>/households.dta  (Households.do + Expenditure.do: Yl, Yk, gas_pc_*, ISR_*, cuotas*, IVA, IEPS,
*                                  ISAN, Importaciones, ing_* finas, ing_estim_alqu, gasto_anualDepreciacion,
*                                  gasto_anualComprasN, ing_capitalROW, ing_suborROW, edad, sexo, factor, folioviv foliohog numren)
*   raw/ENIGH/<anio>/poblacion.dta (parentesco: jefe del hogar, para el alquiler imputado)
*   raw/ENIGH/<anio>/ingresos.dta  (P101-P103, P106-P108: programas que Households.do no lee; memo FLAG 4)
*   raw/ENIGH/<anio>/gastohogar.dta (transferencias en efectivo otorgadas a otros hogares e instituciones)
*   SCN, LIF, PEF del año (anclas: ConHog, ConGob, SerEGob, SaluGob, ComprasN, ROW*, AhorroHog, TransfEspecie; recaudación LIF; PEF)
*
* CONVENCIONES (decisiones firmadas; no se reabren aquí):
*   C          = consumo privado a PRECIOS DE COMPRADOR (gas_pc_*, anclado a ConHog) + gasto_anualComprasN (la corrección
*                del motor por compras netas de no residentes: C es el de los residentes) + consumo público EN ESPECIE por
*                persona (SaluGob ∝ gas_pc_SaluT; SerEGob con el perfil de matrícula de PerfilesSim.do l. 365-443 con las
*                macros PEF del año; resto de ConGob per cápita). Ancla informativa: Σ especie vs TransfEspecie (D.63 S.14).
*   τ⁻ público = impuestos directos e indirectos ANCLADOS a la recaudación observada del año (LIF, Distribucion con los
*                mismos relativos que PerfilesSim.do). Los indirectos (IVA, IEPS, ISAN, importaciones) se restan UNA sola vez,
*                aquí como τ⁻: el ingreso del motor está a precios de mercado (Altimir reparte ImpNet en Yl/Yk) y C a precios
*                de comprador, así que el impuesto está en los dos lados y se cancela al restarlo del ingreso. No se resta de C.
*   YL         = Yl del motor − pensiones (ing_jubila × TaltimirSal, lo que Households.do metió a Yl: FLAG motor v9.x)
*                − 2/3 de las transferencias y flujos financieros que viajan dentro de ing_mixto (× TaltimirSelf) + ing_suborROW.
*   YA         = Yk − depreciación (CapFij: base NETA, consistente con S = B.8n) − 1/3 de lo mismo de ing_mixto + ing_capitalROW
*                + alquiler imputado reasignado al jefe del hogar (ingreso) [+ ajuste por el ancla de S, columna aparte].
*   τ⁺ público = EFECTIVO: pensiones contributivas y Pensión Bienestar ancladas al PEF del año (∝ ing_jubila jubilados, ∝ ing_PAM,
*                como PerfilesSim.do) + becas/programas observados en la ENIGH (ing_benef + P101-P103/P106-P108; sin línea PEF: FLAG);
*                ESPECIE: el consumo público por persona de arriba (lo recibe quien lo consume).
*   τ⁺ inter   = donativos (P039, P040) + herencias (P057) observados, + remesas (ing_remesas, anclado a ROWTrans), una sola vez.
*   τ⁻ inter   = transferencias EN EFECTIVO otorgadas (ENIGH gastohogar 173416 ayuda a parientes y personas ajenas, 133030 ayuda a
*                adultos mayores/discapacidad, 173417 donativos a instituciones), del hogar a sus adultos con ingreso ∝ (YL+YA).
*                Los regalos en especie (T901-T915) quedan en C del que los compra, como en el SCN (parámetro nta_otorgado).
*   S          = residual del HOGAR: Σ_h (YL + YA + τ⁺ + τ⁺inter − τ⁻ − τ⁻inter) − Σ_h C, repartido a los adultos con ingreso
*                ∝ (YL+YA). Ancla: Σ S = AhorroHog (B.8n S.14). El ajuste se aplica como suma ∝ al mismo reparto y la
*                contrapartida va a YA (columna YA_ajuste): así Σ S = AhorroHog, la identidad se conserva y Σ intra = 0 se
*                conserva. Se reporta el factor multiplicativo AhorroHog/Σ S y el ajuste aditivo. Parámetro nta_anclaS.
*   intra      = residual por persona después de todo lo anterior; Σ por hogar = 0 (y nacional) por construcción.
*   Flujos financieros de ing_mixto (préstamos, retiros, hipotecas, seguros: cap9) quedan FUERA de la identidad (FLAG motor).
*   Flujos brutos; año 2024; desahorro como dos nodos en el Sankey v2 (grupo que ahorra → Futuro; Desahorro → grupo).
*
* PARÁMETROS (globals nta_*; default entre paréntesis; se declaran en la salida):
*   nta_anclaS   ("AhorroHog") | "" sin ancla.          nta_alqu ("jefe") | "motor".
*   nta_tauCash  ("PEF") pensiones y PAM al PEF | "ENIGH" observadas.   nta_otorgado ("efectivo") | "todo" (incluye T901-T915).
*   nta_mixto    ("crudo") las transferencias y flujos financieros que viajan dentro de ing_mixto se restan de YL/YA a su valor
*                CRUDO ENIGH (el que citan las decisiones: 273 bn financieros, 260 donativos...) y el anclaje de ing_mixto a Cuentas
*                Nacionales (× TaltimirSelf ≈ 6.2) se queda en YL/YA como ingreso mixto; "escalado": se restan × TaltimirSelf (lo que
*                de verdad viaja en Yl/Yk; deja un hueco de Σ YL+YA frente al PIN del tamaño del FLAG); "reancla": se restan escalados
*                y el ingreso mixto restante se re-ancla al mismo total (lo que debería hacer el motor, v9.x). Las tres se reportan.
*
* SALIDAS: users/$id/NTA/nta-persona.dta, nta-grupoedad.json, nta-quinquenio-sexo.json, nta-identidad.txt;
*          users/$id/SankeyNTA/sankey-v2-grupoedad.json (contrato nuevo; el 31/79 de v1 no se toca).
* Nada de literales: todo número que sale viene de escalar/SCN/LIF/PEF o de la base.
*********************************************************************
if "`1'" == "" {
	local 1 = 2024
}
local anio = `1'
timer on 14
noisily di _newline(2) in g _dup(20) "." "{bf:   NTA:" in y " cuenta por individuo `anio'   }" in g _dup(20) "." _newline

** 0 Parámetros declarados **
if "$nta_anclaS" == "" | "$nta_anclaS" == "AhorroHog" global nta_anclaS "off"	// NTA-1b: sin tapón; "AhorroHog" (NTA-1) era el aditivo
if !inlist("$nta_anclaS", "off", "aditivo", "multiplicativo") {
	noisily di as err `"NTA: nta_anclaS = "$nta_anclaS" no es off | aditivo | multiplicativo"'
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
label var YA_motor "Ingreso de activos NTA antes del ajuste por ancla de S (neto de depreciación, sin impuestos a productos)"

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
Distribucion CpubEduc, relativo(`educ') macro(`SerEGob')
Distribucion CpubSalud, relativo(gas_pc_SaluT) macro(`SaluGob')
Distribucion CpubOtros, relativo(pob) macro(`=`ConGob' - `SerEGob' - `SaluGob'')
egen double Cpub = rsum(CpubEduc CpubSalud CpubOtros)
label var CpubEduc "Consumo público en especie: educación (SerEGob, perfil de matrícula)"
label var CpubSalud "Consumo público en especie: salud (SaluGob ∝ gas_pc_SaluT)"
label var CpubOtros "Consumo público en especie: resto de ConGob (per cápita)"
label var Cpub "Consumo público en especie = τ⁺ público en especie"
g double C = Cpriv + Cpub
label var C "Consumo total (privado + público en especie)"

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
g double Tpub = TpubEf + Cpub
label var TpubPens "τ⁺ efectivo: pensiones contributivas ($nta_tauCash; ancla D.62+D.759 $nta_anclaTau)"
label var TpubPAM "τ⁺ efectivo: Pensión Bienestar ($nta_tauCash; ancla D.62+D.759 $nta_anclaTau)"
label var TpubProg "τ⁺ efectivo: becas y programas (ENIGH: ing_benef + P101-P103/P106-P108; ancla D.62+D.759 $nta_anclaTau)"
label var TpubEf "τ⁺ público en efectivo (ancla D.62+D.759 S.14: $nta_anclaTau)"
label var Tpub "τ⁺ público = efectivo + especie"

** 4.8 Transferencias privadas entre hogares **
g double InterRec = ing_dona + ing_heren
g double Remesas = ing_remesas
label var InterRec "τ⁺ inter-hogar recibido: donativos (P039, P040) + herencias (P057)"
label var Remesas "τ⁺ inter-hogar recibido del exterior: remesas (ing_remesas, anclado a ROWTrans)"
g double nta_otor_hog = nta_otor_ef + cond("$nta_otorgado" == "todo", nta_otor_esp, 0)

** 4.9 Reparto a los adultos con ingreso ∝ (YL + YA): peso común para S y para lo otorgado **
g double nta_w = cond(nta_adulto & (YL + YA_motor) > 0, YL + YA_motor, 0)
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
g double nta_yd = YL + ImpProd + YA_motor + YA_d8 + Tpub + InterRec + Remesas - Tmen - InterOtor
egen double nta_S_hog = total(nta_yd - C), by(nta_hhid)
g double S_sinancla = nta_S_hog*nta_share
label var S_sinancla "Ahorro: residual del hogar repartido a adultos ∝ (YL+YA), antes del ancla"

** 4.11 Σ S micro vs AhorroHog (B.8n S.14). Default nta_anclaS = off: S es el residual, sin tapón; se reporta el
**      factor implícito y la brecha. Variantes: "aditivo" (NTA-1: suma ∝ al mismo reparto, contrapartida en YA_ajuste,
**      la identidad y Σ intra = 0 se conservan) y "multiplicativo" (factor sobre S de los adultos, sin contrapartida:
**      la diferencia cae al residual intra, Σ intra ≠ 0 por construcción; informativo). **
tabstat S_sinancla [fw=factor], stat(sum) save
local S_micro = r(StatTotal)[1,1]
local D = `AhorroHog' - `S_micro'
local fS = `AhorroHog'/`S_micro'
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
label var YA_ajuste "Ajuste por ancla aditiva Σ S = AhorroHog (0 salvo nta_anclaS = aditivo); contrapartida de S"
g double YA = YA_motor + YA_d8 + YA_ajuste
label var S "Ahorro NTA (residual del hogar a adultos ∝ YL+YA; ancla: $nta_anclaS)"
label var YA "Ingreso de activos NTA (neto de depreciación; con D.8)"

** 4.12 Intra-hogar: el único residual **
g double Intra = C - YL - ImpProd - YA - Tpub + Tmen - InterRec - Remesas + InterOtor + S
label var Intra "τ intra-hogar (residual por persona; Σ por hogar = 0)"
g double Resid = C - YL - ImpProd - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - S) - Intra
label var Resid "Residual de la identidad (0 por construcción)"

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
escalar pct NTABrechaSPct = (`S_micro'/`AhorroHog' - 1)*100
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
	in g "  factor implícito " in y %8.4f `fS' in g "  brecha " in y %7.1f scalar(NTABrechaSPct) in g " %  nta_anclaS=" in y "$nta_anclaS"



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
	tabstat Intra S Cpriv Cpub YL YA Tmen TpubEf InterRec Remesas InterOtor YA_ajuste [fw=factor], stat(sum) save
	tempname TOT
	matrix `TOT' = r(StatTotal)
}
local Intra_nac = `TOT'[1,1]
local S_nac = `TOT'[1,2]
escalar mxn NTAIntraNac = `Intra_nac'
escalar mxn NTASNac = `S_nac'
escalar mxn NTACprivNac = `TOT'[1,3]
escalar mxn NTACpubNac = `TOT'[1,4]
escalar mxn NTABrechaEspecie = `TOT'[1,4] - `TransfEspecie'
escalar pct NTABrechaEspeciePct = (`TOT'[1,4]/`TransfEspecie' - 1)*100
escalar mxn NTABrechaCpriv = `TOT'[1,3] - `ConHogS14'
local ok = 1
if `maxres' > `tol'*`Cpc' {
	local ok = 0
	noisily di as err "  GATE NTA: residual por persona máximo " %12.4f `maxres' " (relativo al C per cápita " %9.2e `maxres'/`Cpc' ")"
}
if abs(`Intra_nac')/`Ctot' > `tol' {
	if "$nta_anclaS" == "multiplicativo" {
		noisily di in g "  (nta_anclaS = multiplicativo: Σ intra nacional " in y %16.2f `Intra_nac' in g " = −(f−1)·Σ S sin ancla por construcción; informativo)"
	}
	else {
		local ok = 0
		noisily di as err "  GATE NTA: Σ intra-hogar nacional " %16.2f `Intra_nac' " (relativo a C " %9.2e abs(`Intra_nac')/`Ctot' ")"
	}
}
if "$nta_anclaS" != "off" & reldif(`S_nac', `AhorroHog') > `tol' {
	local ok = 0
	noisily di as err "  GATE NTA: Σ S " %16.2f `S_nac' " ≠ AhorroHog " %16.2f `AhorroHog'
}
noisily di in g "  Gates: residual por persona máx " in y %9.2e `maxres' in g "; Σ intra por hogar máx " in y %9.2e `maxintra_hog' ///
	in g "; Σ intra nacional " in y %12.2f `Intra_nac' in g "; Σ S " in y %16.0fc `S_nac' in g " -> " in y cond(`ok', "OK", "ROJO")
noisily di in g "  Especie: Σ Cpub " in y %16.0fc `TOT'[1,4] in g " vs TransfEspecie " in y %16.0fc `TransfEspecie' ///
	in g " (brecha " in y %7.1f NTABrechaEspeciePct in g " %: la diferencia es el consumo colectivo P.32 dentro de ConGob)"



**********************************
**# 6. Agregados: grupo de edad (escalares) y quinquenio × sexo
**********************************
local vars "C Cpriv Cpub YL ImpProd YA YA_d8 YA_ajuste S S_sinancla Tpub TpubEf TpubPens TpubPAM TpubProg Tmen TmenDir TmenCuotas TmenInd TmenFuera InterRec Remesas InterOtor Intra Resid ALQ"
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
	* quinquenio × sexo (tabla al JSON desde el colapsado) *
	use `per', clear
	collapse (sum) `vars' pobw [fw=factor], by(quinq sexo)
	g double resid_chk = C - YL - ImpProd - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - S) - Intra
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
file write `fh' %-12s ("Grupo") %9s ("Pob(M)") %10s ("S sin aj") %10s ("S final") %10s ("YA ajuste") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTAS_sinancla`g')/1e9) `f1' (scalar(NTAS`g')/1e9) `f1' (scalar(NTAYA_ajuste`g')/1e9) _n
}
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTAS_sinancla0)/1e9) `f1' (scalar(NTAS0)/1e9) `f1' (scalar(NTAYA_ajuste0)/1e9) _n
file write `fh' "B.8n (AhorroHog) " `f1' (`AhorroHog'/1e9) "; factor implícito B.8n / Σ S sin ajuste " %8.4f (`fS') "; brecha (Σ S − B.8n)/B.8n " %7.1f (scalar(NTABrechaSPct)) " %; ajuste aditivo que exigiría el ancla " `f1' (`D'/1e9) "; nta_anclaS=$nta_anclaS" _n _n
file write `fh' "Identidad por grupo de edad: C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − S) − intra = R   (ImpProd = impuestos netos a los productos como ingreso ∝ Cpriv)" _n
file write `fh' "τ⁺ = público efectivo + público especie + inter recibido + remesas; τ⁻ = público (ISR PF+asalariados, cuotas $nta_cuotas, indirectos LIF) + inter otorgado. Fuera de τ⁻ (informativo): ISR_PM + OTROSK." _n
file write `fh' "Parámetros: nta_anclaS=$nta_anclaS nta_cuotas=$nta_cuotas nta_d8=$nta_d8 nta_anclaTau=$nta_anclaTau nta_alqu=$nta_alqu nta_tauCash=$nta_tauCash nta_otorgado=$nta_otorgado nta_mixto=$nta_mixto" _n _n
file write `fh' %-12s ("Grupo") %9s ("Pob(M)") %10s ("Cpriv") %10s ("Cpub") %10s ("C") %10s ("YL") %10s ("ImpProd") %10s ("YA") %10s ("  YA d8") %10s ("S") %10s ("tau-pub") %10s ("  cuotas") %10s ("  indir") %10s ("fuera") %10s ("tau+efec") %10s ("tau+esp") %10s ("interRec") %10s ("remesas") %10s ("interOtor") %10s ("intra") %10s ("R") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTACpriv`g')/1e9) `f1' (scalar(NTACpub`g')/1e9) `f1' (scalar(NTAC`g')/1e9) ///
		`f1' (scalar(NTAYL`g')/1e9) `f1' (scalar(NTAImpProd`g')/1e9) `f1' (scalar(NTAYA`g')/1e9) `f1' (scalar(NTAYA_d8`g')/1e9) `f1' (scalar(NTAS`g')/1e9) `f1' (scalar(NTATmen`g')/1e9) `f1' (scalar(NTATmenCuotas`g')/1e9) `f1' (scalar(NTATmenInd`g')/1e9) `f1' (scalar(NTATmenFuera`g')/1e9) ///
		`f1' (scalar(NTATpubEf`g')/1e9) `f1' (scalar(NTACpub`g')/1e9) `f1' (scalar(NTAInterRec`g')/1e9) `f1' (scalar(NTARemesas`g')/1e9) ///
		`f1' (scalar(NTAInterOtor`g')/1e9) `f1' (scalar(NTAIntra`g')/1e9) %10.6f (scalar(NTAResid`g')/1e9) _n
}
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTACpriv0)/1e9) `f1' (scalar(NTACpub0)/1e9) `f1' (scalar(NTAC0)/1e9) ///
	`f1' (scalar(NTAYL0)/1e9) `f1' (scalar(NTAImpProd0)/1e9) `f1' (scalar(NTAYA0)/1e9) `f1' (scalar(NTAYA_d80)/1e9) `f1' (scalar(NTAS0)/1e9) `f1' (scalar(NTATmen0)/1e9) `f1' (scalar(NTATmenCuotas0)/1e9) `f1' (scalar(NTATmenInd0)/1e9) `f1' (scalar(NTATmenFuera0)/1e9) ///
	`f1' (scalar(NTATpubEf0)/1e9) `f1' (scalar(NTACpub0)/1e9) `f1' (scalar(NTAInterRec0)/1e9) `f1' (scalar(NTARemesas0)/1e9) ///
	`f1' (scalar(NTAInterOtor0)/1e9) `f1' (scalar(NTAIntra0)/1e9) %10.6f (scalar(NTAResid0)/1e9) _n _n
file write `fh' "S y intra-hogar por sexo (bn): hombres S " `f1' (scalar(NTASH)/1e9) " intra " `f1' (scalar(NTAIntraH)/1e9) "; mujeres S " `f1' (scalar(NTASM)/1e9) " intra " `f1' (scalar(NTAIntraM)/1e9) _n
file write `fh' "Impuestos a productos: ImpNetosProd (D.21−D.31) " `f1' (`ImpNetosProd'/1e9) "; ImpNet BIE " `f1' (`ImpNetBIE'/1e9) "; embebido por Altimir en Yk (sacado de YA) " `f1' (scalar(NTAImpProdMotor)/1e9) "; Σ indirectos micro τ⁻ " `f1' (scalar(NTATmenInd0)/1e9) " (factor " %7.4f (scalar(NTAFactorIndirectos)/100) ")" _n
file write `fh' "τ⁺ efectivo PEF/ENIGH " `f1' (`TpubEf_pre'/1e9) " vs D.62 + D.759 S.14 " `f1' (`TauPubS14'/1e9) " (D.62 " `f1' (`PrestSocHog'/1e9) ", D.759 " `f1' (`OtrasTransfHog'/1e9) "); factor " %7.4f (`fTau') "; nta_anclaTau=$nta_anclaTau; Σ τ⁺ efectivo final " `f1' (scalar(NTATpubEf0)/1e9) _n
file write `fh' "D.8 AjustePension " `f1' (`AjustePension'/1e9) " → YA_d8 ($nta_d8) Σ " `f1' (scalar(NTAD8Nac)/1e9) _n
file write `fh' "Σ Cpub (especie) " `f1' (scalar(NTACpubNac)/1e9) " vs TransfEspecie " `f1' (`TransfEspecie'/1e9) " (brecha " %6.1f (scalar(NTABrechaEspeciePct)) " %)" _n
file write `fh' "Σ Cpriv " `f1' (scalar(NTACprivNac)/1e9) " vs P.3 S.14 " `f1' (`ConHogS14'/1e9) "; ConHog (BIE) " `f1' (`ConHog'/1e9) "; ComprasN " `f1' (`ComprasN'/1e9) _n
file write `fh' "Gates: residual máx por persona " %9.2e (`maxres') " MXN; Σ intra nacional " %12.2f (`Intra_nac') " MXN; Σ S − AhorroHog " %12.2f (`S_nac' - `AhorroHog') " MXN -> `okstr'" _n
file close `fh'

* 6.2 JSON por grupo de edad *
local q = char(34)
local fecha : di %tdCCYY-NN-DD date("$S_DATE", "DMY")
local fm "%20.4f"
file open `fh' using `"`dirnta'/nta-grupoedad.json"', write replace text
file write `fh' `"{"esquema":"nta/v1","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"grupoedad","' _n
file write `fh' `""identidad":"C - YL - ImpProd - (tau_mas - tau_menos) - (YA - S) - intra = residual; ImpProd = impuestos netos a los productos como ingreso (∝ Cpriv); tau_mas = tau_pub_efectivo + tau_pub_especie + inter_recibido + remesas; tau_menos = tau_pub + inter_otorgado","' _n
file write `fh' `""parametros":{"nta_anclaS":"$nta_anclaS","nta_cuotas":"$nta_cuotas","nta_d8":"$nta_d8","nta_anclaTau":"$nta_anclaTau","nta_alqu":"$nta_alqu","nta_tauCash":"$nta_tauCash","nta_otorgado":"$nta_otorgado","nta_mixto":"$nta_mixto","adulto":`adulto',"tolerancia":1e-9},"' _n
file write `fh' `""anclas":{"AhorroHog_B8n":`=trim(string(`AhorroHog', "`fm'"))',"AhorroHogB_B8b":`=trim(string(`AhorroHogB', "`fm'"))',"TransfEspecie_D63":`=trim(string(`TransfEspecie', "`fm'"))',"ConHogS14_P3":`=trim(string(`ConHogS14', "`fm'"))',"ConHog":`=trim(string(`ConHog', "`fm'"))',"ConGob":`=trim(string(`ConGob', "`fm'"))',"SerEGob":`=trim(string(`SerEGob', "`fm'"))',"SaluGob":`=trim(string(`SaluGob', "`fm'"))',"ComprasN":`=trim(string(`ComprasN', "`fm'"))',"ROWTrans":`=trim(string(`ROWTrans', "`fm'"))',"ROWRem":`=trim(string(`ROWRem', "`fm'"))',"ROWProp":`=trim(string(`ROWProp', "`fm'"))',"CapFij":`=trim(string(`CapFij', "`fm'"))',"IngDisp":`=trim(string(`IngDisp', "`fm'"))',"AhorroN":`=trim(string(`AhorroN', "`fm'"))',"OyE":`=trim(string(`OyE', "`fm'"))',"PEF_Pensiones":`=trim(string(`Pensiones', "`fm'"))',"PEF_PensionAM":`=trim(string(`PenBienestar', "`fm'"))',"TaltimirSelf":`=trim(string(`TSelf', "%12.8f"))',"TaltimirSal":`=trim(string(`TSal', "%12.8f"))'},"' _n
file write `fh' `""S_vs_B8n":{"S_sin_ajuste":`=trim(string(`S_micro', "`fm'"))',"AhorroHog":`=trim(string(`AhorroHog', "`fm'"))',"factor_implicito":`=trim(string(`fS', "%12.8f"))',"brecha_pct":`=trim(string(scalar(NTABrechaSPct), "%12.6f"))',"ajuste_aditivo_que_exigiria":`=trim(string(`D', "`fm'"))',"S_final":`=trim(string(`S_nac', "`fm'"))',"modo":"$nta_anclaS","mixto_motor":`=trim(string(scalar(NTAMixtoMotor), "`fm'"))',"mixto_transf_fin_escalado":`=trim(string(scalar(NTAMixtoTransfFin), "`fm'"))',"pensiones_en_Yl":`=trim(string(scalar(NTAPensEnYl), "`fm'"))',"regla":"off: S residual sin tapón; aditivo: suma ∝ (YL+YA) de adultos con contrapartida en YA_ajuste; multiplicativo: S × factor, sin contrapartida (cae a intra)"},"' _n
file write `fh' `""impuestos_productos":{"ImpNetosProd_D21_D31":`=trim(string(`ImpNetosProd', "`fm'"))',"ImpNet_BIE":`=trim(string(`ImpNetBIE', "`fm'"))',"ImpProd_micro":`=trim(string(scalar(NTAImpProdNac), "`fm'"))',"embebido_Altimir_sacado_de_YA":`=trim(string(scalar(NTAImpProdMotor), "`fm'"))',"indirectos_micro_tau_menos":`=trim(string(scalar(NTATmenInd0), "`fm'"))',"factor_indirectos_sobre_ImpNetosProd":`=trim(string(scalar(NTAFactorIndirectos)/100, "%12.8f"))',"regla":"ImpProd ∝ Cpriv; el ImpNet que Altimir embebe en Yk (∝ ing_mixtoK, ing_capital, ing_estim_alqu) se saca de YA"},"' _n
file write `fh' `""tau_mas_efectivo":{"PEF_ENIGH_pre":`=trim(string(`TpubEf_pre', "`fm'"))',"D62":`=trim(string(`PrestSocHog', "`fm'"))',"D759":`=trim(string(`OtrasTransfHog', "`fm'"))',"TauPubS14":`=trim(string(`TauPubS14', "`fm'"))',"factor":`=trim(string(`fTau', "%12.8f"))',"nta_anclaTau":"$nta_anclaTau","final":`=trim(string(scalar(NTATpubEf0), "`fm'"))',"regla":"un solo factor global multiplicativo sobre pensiones, Pensión Bienestar y becas/programas"},"' _n
file write `fh' `""d8":{"AjustePension_D8":`=trim(string(`AjustePension', "`fm'"))',"YA_d8_micro":`=trim(string(scalar(NTAD8Nac), "`fm'"))',"nta_d8":"$nta_d8","personas_con_cuotas":`Ncotiz'},"' _n
file write `fh' `""tau_menos":{"directos":`=trim(string(scalar(NTATmenDir0), "`fm'"))',"cuotas":`=trim(string(scalar(NTACuotasNac), "`fm'"))',"cuotas_ancla":"$nta_cuotas","CuotasHogS14_D61_menos_D614":`=trim(string(`CuotasHogS14', "`fm'"))',"LIF_CUOTAS":`=trim(string(`CUOTAS', "`fm'"))',"indirectos":`=trim(string(scalar(NTATmenInd0), "`fm'"))',"fuera_ISRPM_OTROSK":`=trim(string(scalar(NTATmenFueraNac), "`fm'"))',"LIF_ISRPM":`=trim(string(`ISRPM', "`fm'"))',"LIF_OTROSK":`=trim(string(`OTROSK', "`fm'"))'},"' _n
file write `fh' `""especie":{"Cpub":`=trim(string(scalar(NTACpubNac), "`fm'"))',"TransfEspecie":`=trim(string(`TransfEspecie', "`fm'"))',"brecha":`=trim(string(scalar(NTABrechaEspecie), "`fm'"))',"brecha_pct":`=trim(string(scalar(NTABrechaEspeciePct), "%12.6f"))'},"' _n
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
file write `fh' `""procedencia":{"modulo":"01_modulos/NTA.do v1.0 (NTA-1)","base":"master/`anio'/households.dta + raw/ENIGH/`anio'/{poblacion,ingresos,gastohogar}.dta","anclas":"SCN/LIF/PEF `anio' (escalar); S.14 de CSI_115.xlsx via SCN.ado","generado_el":"`fecha' $S_TIME","stata":"`c(stata_version)' `c(edition_real)'"}}"' _n
file close `fh'

* 6.3 JSON quinquenio × sexo (desde el colapsado) *
preserve
use `qs', clear
file open `fh' using `"`dirnta'/nta-quinquenio-sexo.json"', write replace text
file write `fh' `"{"esquema":"nta/v1","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"quinquenio x sexo","' _n
file write `fh' `""identidad":"C - YL - ImpProd - (tau_mas - tau_menos) - (YA - S) - intra = residual","residual_max":`=trim(string(`maxres_qs', "%12.4e"))',"' _n
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
file write `fh' `"],"procedencia":{"modulo":"01_modulos/NTA.do v1.0 (NTA-1)","generado_el":"`fecha' $S_TIME"}}"' _n
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
* los brutos por persona (IntraPos/IntraNeg) quedan en nta-grupoedad.json. El ajuste del ancla de S es un
* tipo de ingreso aparte ("Ajuste ancla S.14"), no se esconde en el capital.
* Compras netas de no residentes: ya restadas de C (gasto_anualComprasN), por eso no hay nodo "Turistas".
local BF = scalar(NTAInterRec0) - scalar(NTAInterOtor0)
local BG = scalar(NTATmen0) + `OyE' - scalar(NTATpubEf0) - scalar(NTACpub0)
local lbl3 `"1 "Ingreso 0 a 4" 2 "Ingreso 5 a 17" 3 "Ingreso 18 a 24" 4 "Ingreso 25 a 64" 5 "Ingreso 65 y más" 11 "Gobierno" 12 "Familias" 13 "Activos" 21 "Desahorro 0 a 4" 22 "Desahorro 5 a 17" 23 "Desahorro 18 a 24" 24 "Desahorro 25 a 64" 25 "Desahorro 65 y más" 31 "Otras transferencias privadas" 32 "Déficit público" 41 "Consumo 0 a 4" 42 "Consumo 5 a 17" 43 "Consumo 18 a 24" 44 "Consumo 25 a 64" 45 "Consumo 65 y más" 51 "_De 0 a 4" 52 "_De 5 a 17" 53 "_De 18 a 24" 54 "_De 25 a 64" 55 "_De 65 y más" 61 "Futuro 0 a 4" 62 "Futuro 5 a 17" 63 "Futuro 18 a 24" 64 "Futuro 25 a 64" 65 "Futuro 65 y más" 71 "Resto del gasto público" 72 "Transferencias privadas netas" 999 "Ing nacional""'
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
		local propio = `Y' - scalar(NTATmen`g') - scalar(NTAInterOtor`g') - `Ineg' - `Spos'
		local salidas `"11 `=scalar(NTATmen`g')' 12 `=scalar(NTAInterOtor`g') + `Ineg'' 13 `Spos' `=40+`g'' `propio'"'
		local entradas `"11 `=scalar(NTATpubEf`g')' 12 `=scalar(NTAInterRec`g') + scalar(NTARemesas`g') + `Ipos'' 13 `Sneg'"'
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
	g double sk_Otros_bienes_públicos = CpubOtros
	collapse (sum) sk_* [fw=factor], by(grupoedad)
	reshape long sk_, i(grupoedad) j(cat) string
	rename sk_ profile
	g byte publica = inlist(cat, "Educación_pública", "Salud_pública", "Otros_bienes_públicos")
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
**# 8. Guardar la cuenta por persona
**********************************
quietly {
	keep folioviv foliohog numren factor edad sexo grupoedad quinq decil nta_hhid nta_jefe nta_adulto ///
		YL ImpProd YA YA_motor YA_d8 YA_ajuste ALQ Cpriv Cpub CpubEduc CpubSalud CpubOtros C ///
		Tmen TmenDir TmenCuotas TmenInd TmenFuera nta_ISRAS nta_ISRPF nta_CUOTAS nta_ISRPM nta_OTROSK nta_IVA nta_ISAN nta_IEPSNP nta_IEPSP nta_IMPORT ///
		Tpub TpubEf TpubPens TpubPAM TpubProg InterRec Remesas InterOtor S S_sinancla Intra Resid ///
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
	char _dta[nta_parametros] "nta_anclaS=$nta_anclaS nta_cuotas=$nta_cuotas nta_d8=$nta_d8 nta_anclaTau=$nta_anclaTau nta_alqu=$nta_alqu nta_tauCash=$nta_tauCash nta_otorgado=$nta_otorgado nta_mixto=$nta_mixto"
	compress
	save `"`dirnta'/nta-persona.dta"', replace
}
noisily di in g "  Salidas: " in y "users/$id/NTA/{nta-persona.dta, nta-grupoedad.json, nta-quinquenio-sexo.json, nta-identidad.txt}" in g " y " in y "users/$id/SankeyNTA/sankey-v2-grupoedad.json"
if `ok' == 0 {
	noisily di as err "  NTA: algún gate interno quedó ROJO (ver arriba); 05_scripts/test-nta-identidad.sh lo confirma."
}
timer off 14
timer list 14
noisily di in g "{bf:Tiempo NTA:} " in y round(`=r(t14)/r(nt14)',.1) in g " segs."
