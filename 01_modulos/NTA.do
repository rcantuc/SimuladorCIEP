*********************************************************************
***                                                               ***
***   NTA.do — Cuenta de Transferencias Nacionales por individuo  ***
***   (Lee–Mason), cerrada por grupo de edad y por quinquenio×sexo ***
***                                                               ***
*********************************************************************
* NTA-1 (2026-10-27). Base: memo 02_governance/historico/nta-0-inventario-2026-10-27.md (#38) y las decisiones firmadas por
* Ricardo el 2026-10-27. NTA-1b (2026-10-27, mismo PR #40): se alinean las definiciones con el sector hogares S.14
* del SCN ANTES de cualquier ancla de S; el ajuste de S queda como variante, no como default. NTA-1c (2026-10-28): el total
* de YA se re-ancla a S.14 (nta_YA = S14) y, si |Σ S − B.8n|/B.8n ≤ 15 %, el ancla multiplicativa de S se activa DECLARADA
* (nta_anclaS = auto -> multiplicativo; intra y la identidad se exigen sin ancla). NTA-3 (2026-10-29): se emiten además el Sankey v3
* (§7b, edades solo al inicio y al final, sin Familias ni «Ingreso g»/«Consumo g») y el panel grupo × sexo (§7c); ningún número cambia.
* NTA-4 (2026-10-29): el v3 funde Desahorro/Futuro en un nodo cada uno, la especie pública en su categoría y el ancla S.14 en un solo nodo con el neto,
* y cada enlace viaja con value (MXN) y pctpib (% del PIB del año, escalar PIB de SCN.ado); el panel emite ambas unidades (esquema nta-panel/v2).
* v8.14 (2026-10-30, CONC-1 §6.1): los impuestos netos a los productos que Altimir embebe en ing_mixto (ImpNetProductos_mixK, 497.6 bn en 2024)
* se sacan de donde viajan: ⅓ de YA (Yk lleva ing_mixtoK = ⅓ ing_mixto) y ⅔ de YL (Yl lleva ing_mixtoL); antes §4.3 restaba de YA los 497.6 completos
* y YL conservaba 331.7 bn de impuestos además de recibir ImpProd. Llamada (SIM.do §3.2b):
*   run NTA.do <anioenigh>        (2024: el único año con households.dta anclado a SCN/LIF/PEF 2024)
*
* 8.16b (v8.16.0, CUAD-1 firmado en CUAD-1-2-firma.md §B; Cuadratura II): el τ⁻ directo de las personas se ancla a D.51 S.14 y el ISR de sociedades a
* D.51 S.11 + S.12 (isr_personas_ancla = d51_s14; la LIF clasifica por quien entera, la CSI por quien soporta); las cuotas se reparten por sector
* receptor con la celda D.61 de cada cuadro (cuotas_por_sector = on: S.13, S.12 sin D.614, S.11, S.15); el IEPS va ∝ el bien gravado (ieps_relativo =
* micro); Σ Cpriv = P.3 S.14 es gate (consumo_ancla = p3_s14, Expenditure.do). nta-identidad.txt sale al estandar §D (cuadros numerados, notas al
* pie, separador de miles, gates al final). La brecha de Σ S esperada en CUAD-1 §7 (−0.9 %) supone cerrada la fila τ⁺ vs D.62 + D.7 netas, que
* es de CUAD-2 (8.17): mientras, la brecha observada la lleva esa fila y el FLAG lo dice.
*
* 8.17 (v8.17.0, CUAD-2 firmado en CUAD-1-2-firma.md §A 16, 19-23 y §B 17-18; Sankey de la economia completa): (i) la fila τ⁺/inter/remesas vs
* D.62 + D.7 netas se cierra por sector pagador/receptor: τ⁻ gana D.59 (otros impuestos corrientes, ∝ alquiler imputado + vehiculos), las primas
* netas de seguros D.71 (∝ gas_pc_DiveT), los donativos a ISFLSH D.751 (∝ gastohogar 173417, factor a la celda: FLAG 35), las remesas enviadas
* D.752 (per capita de adultos con ingreso: FLAG 36) y D.759 pagada (∝ YL + YA; receptor por identificar); τ⁺ gana las indemnizaciones de seguros
* D.72 (∝ gas_pc_DiveT); lo otorgado entre hogares se escala a lo recibido (inter_hogar = balance: D.75 entre residentes neto cero, como el SCN);
* las prestaciones en efectivo se parten en publicas (S.13) y privadas (S.11 + S.12 + S.15, ∝ pensiones). (ii) retenido_a_personas = on: B.5n de
* S.11 + S.12 entra a YA de las personas ∝ ing_d4_rel (YA_ret, regla P, sello rojo) y lo que las sociedades pagan por cuenta de sus dueños
* (B.5n − B.8n: ISR de sociedades, D.8, transferencias netas) es τ⁻ retenido (TmenRet), asi que S_ret = B.8n de S.11 + S.12 por persona;
* deficit_a_personas = per_capita: la deuda publica asignada −B.8n S.13 es τ⁻ (TmenDef) y desahorro (S_def) por igual a cada persona
* (tau_menos: ∝ τ⁻; medido en nta-identidad.txt); el ahorro de las ISFLSH (B.8n S.15) llega per capita como τ⁺ y S (S_isflsh). Con los
* defaults Σ S de las personas = B.8n S.1 (la economia desahorra). La cuenta del HOGAR (S_hh anclado a B.8n S.14, YA_hh, Tmen_hh) sigue siendo
* la del v3 y el panel; la identidad por persona se exige con los dos juegos. (iii) El consumo colectivo es P.32 S.13 (CSI), no ConGob − D.63.
* (iv) §7d emite el Sankey v4 (sankey-v4-economia.json): personas por edad en los extremos, sectores en medio conservando, hub = INBD BIE al peso.
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
*                Altimir embebía de ImpNet en Yk y Yl (ImpNetProductos_mixK/_soc/_hog, Households.do l. 2420-2427) se saca de YA
*                (_soc, _hog y ⅓ de _mixK) y de YL (⅔ de _mixK: v8.14) para no contarlo dos veces. Así los indirectos de τ⁻ ya no
*                son doble resta. D.29 − D.39 sigue en Yl/Yk (FLAG).
*   YL         = Yl del motor (v8.15b, CUAD-0 firma: Yl = D.1 S.14 + 2/3 B.3n al peso). Las correcciones que compensaban al motor hasta
*                v8.14 (pensiones × TaltimirSal, 2/3 de las transferencias y flujos financieros de ing_mixto, 2/3 de ImpNetProductos_mixK,
*                + ing_suborROW) siguen cableadas pero valen 0 con los parámetros firmados (pensiones_en_yl = off, ing_mixto_depurado =
*                transf_negocios, sin impuestos embebidos, suborrow = off) y se reportan; con los alternos (base v8.14) vuelven a actuar.
*   YA         = YA_base + YA_d8 [+ YA_ajuste solo con nta_anclaS = aditivo]. YA_motor = Yk − depreciación (CapFij: base NETA, consistente
*                con S = B.8n) + alquiler imputado reasignado al jefe del hogar (ingreso) [− ImpNet embebido − 1/3 transf + ing_capitalROW:
*                0 con la firma]. YA_base = YA_motor × fYA, fYA = (YAHogS14 − D.442 con cuotas_d614 = neto) / Σ YA_motor con nta_YA = S14:
*                desde v8.15b el motor ya trae Yk − CCF = YAHogS14 − D.442 al peso, así que fYA = 1.0000 y se exige a 1e-9 (FLAG si no).
*                YA_d8 = D.8 ∝ YL de quienes cotizan (nta_d8).
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
* §4 DECISIONES (sesión log-legible, 2026-11-09): los diez parámetros del Sankey de la economía completa (SIM.do §0.8c; CUAD-2 §4, firmados en
*   CUAD-1-2-firma.md §A 16, 19-23 y §B 17-18) se describen aquí; SIM.do solo los declara en una línea y §0.9 imprime el cuadro con FLAG si el
*   valor no es el firmado. La primera alternativa es la firmada; «no implementado» imprime FLAG y dibuja la firmada:
*   hub                  inbd (hub = ingreso nacional disponible BIE 724037, 81.561 % PIB 2024; los sectores entran con su B.5n) | ing_nacional
*                        (lado hogares, v3; el v4 no se emite).
*   retenido_a_personas  on (B.5n y B.8n de S.11 + S.12 llegan a personas ∝ ing_d4_rel, regla P, sello rojo; «Sociedades» visible en medio) |
*                        off (nodo de sector sin edad).
*   deficit_a_personas   per_capita (B.8n S.13, −1,157.268, a todas las personas por igual, C) | tau_menos (∝ τ⁻ de cada persona) | off (solo
*                        «Financiamiento → Gobierno»).
*   isflsh_regla         sector (ISFLSH con nodo propio: B.5n al hub, D.751 de hogares, D.63 a categorías, B.8n a personas per cápita) | hogares |
*                        d63_perfil (no implementados en 8.17).
*   circuito_d442        neto (D.442 → Hogares como fila de sector y D.614 fuera de las cuotas a Afores) | bruto (cuotas a S.12 con D.614).
*   vintage_nodo         si (nodo «Vintage BIE vs CSI» al hub, NNI, y sink tras el hub, Σ B.6n CSI vs INBD BIE) | absorbido (se suma a Hogares).
*   bruto_neto           neto (hub neto de CCF; PIN como origen) | bruto (CCF por sector hasta la formación de capital; no implementado en 8.17).
*   financiamiento       un_nodo_4 (un solo nodo fuente «Financiamiento deuda y venta de activos»: desahorro de hogares, S.11 + S.12 y S.13) |
*                        por_sector (un nodo por sector) | un_nodo_2 (= un_nodo_4 con FLAG: sin S.11 + S.12 no conserva).
*   discrepancia_gasto   fuera (el Sankey es cuenta corriente: INBD = C + B.8n) | nodo (solo con la formación de capital; no implementado en 8.17).
*   inter_hogar          balance (lo otorgado entre hogares, ENIGH 173416 + 133030, se escala a lo recibido P039 + P040 + P057: D.75 entre
*                        residentes neto cero, como el SCN; sello rojo) | enigh (sin escalar: el desbalance 193.7 bn queda en la brecha de S).
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
*          v2.1, §7) y sankey-v3-grupoedad.json (NTA-3: contrato v3, edades solo al inicio y al final, §7b; NTA-4: value + pctpib por enlace; el 31/79 de v1 no se toca).
* Nada de literales: todo número que sale viene de escalar/SCN/LIF/PEF o de la base.
*********************************************************************
if "`1'" == "" {
	local 1 = 2024
}
local anio = `1'
timer on 14
noisily _log modulo "NTA  ·  cuenta de Transferencias Nacionales por individuo, `anio'" ref("CUAD-2 §6; NTA.do header §4")

** 0 Parámetros declarados **
if "$nta_anclaS" == "" | "$nta_anclaS" == "AhorroHog" global nta_anclaS "auto"	// NTA-1c: auto = multiplicativo si |Σ S − B.8n|/B.8n ≤ 15 %, si no off; "AhorroHog" (NTA-1) era el aditivo
if !inlist("$nta_anclaS", "auto", "off", "aditivo", "multiplicativo") {
	noisily _log aviso, tipo(IMPORTANTE) texto(`"NTA: nta_anclaS = "$nta_anclaS" no es auto | off | aditivo | multiplicativo"') rojo
	exit 198
}
global nta_anclaS_param "$nta_anclaS"
* 8.16b (decision de Ricardo 2026-11-08): brecha_max 15 -> 30 % mientras la fila τ⁺/inter/remesas vs D.62 + D.7 netas (+461.0 bn) se cerraba en 8.17.
* 8.17: la fila se cierra (τ por sector) y brecha_max vuelve a 15 %; la brecha esperada es ≈ −0.9 % (ImpProd LIF vs devengado − vintage de remesas). *
local brecha_max = 15
if "$nta_YA" == "" global nta_YA "S14"
if !inlist("$nta_YA", "motor", "S14") {
	noisily _log aviso, tipo(IMPORTANTE) texto(`"NTA: nta_YA = "$nta_YA" no es motor | S14"') rojo
	exit 198
}
if "$nta_cuotas" == "" global nta_cuotas "S14"
if "$nta_d8" == "" global nta_d8 "yl_cotizantes"
if "$nta_anclaTau" == "" global nta_anclaTau "on"
if !inlist("$nta_d8", "yl_cotizantes", "per_capita_adultos") {
	noisily _log aviso, tipo(IMPORTANTE) texto(`"NTA: nta_d8 = "$nta_d8" no es yl_cotizantes | per_capita_adultos"') rojo
	exit 198
}
if "$nta_alqu" == "" global nta_alqu "jefe"
if "$nta_tauCash" == "" global nta_tauCash "PEF"
if "$nta_otorgado" == "" global nta_otorgado "efectivo"
if "$nta_mixto" == "" global nta_mixto "crudo"
* v8.15b (CUAD-0 firma): parametros de Households.do. En la sesion de SIM.do llegan como globals; sueltos se leen del char cuad_params de
* households.dta (§2.4); si tampoco estan, rige el valor firmado. Se declaran en nta-identidad.txt y en el JSON. *
local cuad_firma "pensiones_en_yl off ing_mixto_depurado transf_negocios rentas_celda b2n d4_relativo proxy_propiedad yk_ancla b2n_b3n_d4 cap4 fuera suborrow off cuotas_d614 neto oye_en_hub off"
* 8.16b (CUAD-1 §4 firmado; firma CUAD-1-2 §B): parametros de Cuadratura II. Los que NTA.do aplica: isr_personas_ancla (D.51 S.14 y D.51 S.11 + S.12 como
* anclas de τ⁻ directo e ISR PM), cuotas_por_sector (D.61 por sector receptor), ieps_relativo (IEPS ∝ bien gravado), consumo_ancla (gate Σ Cpriv = P.3 S.14). *
local cuad_firma "`cuad_firma' consumo_ancla p3_s14 consumo_precios comprador cuotas_por_sector on isrpm_incidencia propiedad isr_personas_ancla d51_s14 isras_share acotado obligacion_isrpf_ancla itan_rangos informalidad corte ancla_formales imss iepsnp_macro divsim ieps_relativo micro"
* 8.17 (CUAD-2 §4 firmado; SIM.do §0.8c): parametros del Sankey de la economia completa. Los lee este modulo (§4.6c, §4.5, §7d). *
local cuad_firma "`cuad_firma' hub inbd retenido_a_personas on deficit_a_personas per_capita isflsh_regla sector circuito_d442 neto vintage_nodo si bruto_neto neto financiamiento un_nodo_4 discrepancia_gasto fuera inter_hogar balance"
* 8.17.2 (CUAD-3 §4.0): rentas efectivas en B.2n (rentas_celda b2n), celda de negocios B.3n + D.422 (ing_mixto_ancla) y la brecha ENIGH-SCN repartida ∝ Y^ε
* (altimir_elasticidad; 1 = Altimir uniforme). Con ε ≠ 1 los chars TaltimirSal/TaltimirSelf son factores MEDIOS: las reconstrucciones de §3-§4 que los usan
* (pensiones_en_yl = on, ing_mixto_depurado = off: alternativas, 0 con la firma) son aproximadas y lo declaran (FLAG). *
local cuad_firma "`cuad_firma' ing_mixto_ancla b3n_d422 altimir_elasticidad 1.75"
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
	noisily _log aviso, tipo(IMPORTANTE) texto("NTA: SCN no definió AhorroHog/TransfEspecie (sin CSI_115.xlsx); sin ancla S.14 no hay cuenta NTA") ref("CUAD-0 §4 bis") rojo
	exit 459
}
local AhorroHog = scalar(AhorroHog)
local AhorroHogB = scalar(AhorroHogB)
* NTA-4: PIB nominal del año (SCN.ado: escalar mxn PIB = PIB[anio], BIE); denominador de pctpib en el v3 y en el panel *
capture confirm scalar PIB
if _rc != 0 | scalar(PIB) <= 0 {
	noisily _log aviso, tipo(IMPORTANTE) texto("NTA: SCN no dejó el escalar PIB del año `anio' (denominador de % del PIB); sin PIB no hay v3 ni panel") rojo
	exit 459
}
local PIBY = scalar(PIB)
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
* v8.15b (CUAD-0 firma 11): D.442 (f.103) sale de YA con cuotas_d614 = neto; D.5 (f.114) y D.7 recibidas/pagadas (f.139) sostienen la
* descomposicion de la brecha de S («De donde sale la brecha», CUAD-0 Δ esperado). Si SCN no las trae (base anterior a v8.15b): 0 y FLAG. *
foreach k in D1HogS14 D442Hog ImpIngHog OtrasTransfHogR OtrasTransfHogU RemesasHogS14 {
	capture local `k' = scalar(`k')
	if _rc != 0 {
		local `k' = 0
		local flags `"`flags' "SCN sin `k' (CSI_115, v8.15b): se toma 0""'
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
* 8.16b: celdas de Cuadratura II (SCN.ado): D.51 pagado por S.14 y por S.11 + S.12, P.3 de las ISFLSH, D.61 recibido por sector *
foreach k in D51HogS14 D51NoFin D51Fin ConISFLSH CuotasGobR CuotasFinR CuotasNoFinR CuotasISFLSHR ContribSocHog {
	capture local `k' = scalar(`k')
	if _rc != 0 local `k' = .
}
* 8.17 (CUAD-2 §6.4; SCN.ado SCNSectores): celdas por sector del Sankey de la economia completa. Si SCN no las trae (SCN.dta anterior a 8.17), el hub
* cae a ing_nacional con FLAG y el v4 no se emite. *
local sect "B8nS1 B6nS1 P3S1 B9S1 D5NoFin D5Fin D62NoFinU D62FinU D7NoFinU D7NoFinR D7FinU D7FinR D71FinR D72FinU D751NoFinU D751FinU D759NoFinU D759FinU D759NoFinR D759FinR B6nNoFin B6nFin B8nNoFin B8nFin D8FinU B9NoFin B9Fin"
local sect "`sect' D41GobU D45GobR D62GobU D7GobU D7GobR D71GobU D72GobR D73Gob D74GobU D751GobU D759GobU D759GobR B6nGob D63GobU P3Gob P32Gob B8nGob B9Gob"
local sect "`sect' D59Hog D71HogU D72HogR D751HogU D752HogU D759HogU B6nHog B9Hog D62ISFLSHU D7ISFLSHU D7ISFLSHR D71ISFLSHU D751ISFLSHR D751ISFLSHU B6nISFLSH D63ISFLSHU B8nISFLSH B9ISFLSH D7RowU D7RowR B9Row VintageNNI D29D39GobR"
local sect "`sect' B5nNoFin B5nFin B5nGob B5nISFLSH B5nS1 RentaPropGobR RentaPropGobU ImpNetGobR"
local sinsect = 0
local sinsect_k ""
foreach k of local sect {
	capture confirm scalar `k'
	if _rc == 0 local `k' = scalar(`k')
	else {
		local `k' = .
		local sinsect = 1
		local sinsect_k "`sinsect_k' `k'"
	}
}
if `sinsect' & "$hub" == "inbd" {
	global hub "ing_nacional"
	noisily _log aviso, tipo(FLAG) texto("NTA: SCN sin las celdas por sector (`sinsect_k'); hub cae a ing_nacional y el Sankey v4 no se emite") ref("CUAD-2 §6.4") rojo
	local flags `"`flags' "SCN sin las celdas por sector de CUAD-2 §6.4 (SCNSectores, 8.17:`sinsect_k'): hub cae a ing_nacional y el Sankey v4 no se emite""'
}
foreach p in hub retenido_a_personas deficit_a_personas isflsh_regla circuito_d442 vintage_nodo bruto_neto financiamiento discrepancia_gasto inter_hogar {
	if "${`p'}" == "" {
		local k = strpos(" `cuad_firma'", " `p' ")
		local resto = substr(" `cuad_firma'", `k', .)
		gettoken pp firmado : resto
		gettoken firmado : firmado
		global `p' "`firmado'"
	}
}
if !inlist("$hub", "inbd", "ing_nacional") | !inlist("$retenido_a_personas", "on", "off") | !inlist("$deficit_a_personas", "per_capita", "tau_menos", "off") ///
	| !inlist("$isflsh_regla", "sector", "hogares", "d63_perfil") | !inlist("$circuito_d442", "neto", "bruto") | !inlist("$vintage_nodo", "si", "absorbido") ///
	| !inlist("$bruto_neto", "neto", "bruto") | !inlist("$financiamiento", "un_nodo_4", "un_nodo_2", "por_sector") | !inlist("$discrepancia_gasto", "fuera", "nodo") | !inlist("$inter_hogar", "balance", "enigh") {
	noisily _log aviso, tipo(IMPORTANTE) texto("NTA: parámetro de CUAD-2 fuera de rango: hub=$hub retenido=$retenido_a_personas deficit=$deficit_a_personas isflsh=$isflsh_regla d442=$circuito_d442 vintage=$vintage_nodo bruto=$bruto_neto fin=$financiamiento disc=$discrepancia_gasto inter=$inter_hogar") ref("SIM.do §0.9") rojo
	exit 198
}
if "$isflsh_regla" != "sector" local flags `"`flags' "isflsh_regla = $isflsh_regla no implementado en 8.17: se dibuja sector (B.5n al hub, D.751 de hogares, D.63 a categorias, B.8n a personas per capita)""'
if "$bruto_neto" != "neto" local flags `"`flags' "bruto_neto = bruto no implementado en 8.17: el hub es neto de CCF (PIN como origen)""'
if "$discrepancia_gasto" != "fuera" local flags `"`flags' "discrepancia_gasto = nodo no implementado en 8.17 (exige dibujar P.5): el Sankey es cuenta corriente""'
if "$financiamiento" == "un_nodo_2" local flags `"`flags' "financiamiento = un_nodo_2 (solo hogares y gobierno) no conserva con S.11 negativo: se dibuja un_nodo_4""'
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

* 8.16a: tabla vertical de anclas (_tabla_anclas.ado; catalogo 05_scripts/scn-cuentas.csv); solo cambia el log *
_tabla_anclas clear
_tabla_anclas add, codigo(724600) sector("S.14+S.15") fuente("BIE 724600 · asset") valor(`ConHog') variable(Cpriv) nota("consumo de hogares e ISFLSH en territorio; Cpriv = Σ gas_pc_* anclado + compras netas (724777)")
_tabla_anclas add, codigo(724959) sector(S.13) fuente("BIE 724959 · asset") valor(`ConGob') variable("CpubInd + CpubCol") nota("consumo de gobierno general")
_tabla_anclas add, codigo(B.8n) sector(S.14) fuente("CSI_115 · f.171 U/A") valor(`AhorroHog') variable(S) nota("ancla de Σ S (nta_anclaS=$nta_anclaS)")
_tabla_anclas add, codigo(D.63) sector(S.14) fuente("CSI_115 · f.176 − f.166 U/A") valor(`TransfEspecie') variable(CpubInd) nota("P.4 − P.3: transferencias sociales en especie")
_tabla_anclas add, codigo(P.3) sector(S.14) fuente("CSI_115 · f.166 U/A") valor(`ConHogS14') variable(Cpriv) nota("consumo_ancla = $consumo_ancla: con p3_s14 Σ Cpriv = P.3 S.14 (gate 1e-9); ISFLSH y vintage del consumo son filas de sector")
if `D51HogS14' < . _tabla_anclas add, codigo(D.51) sector(S.14) fuente("CSI_115 · f.115 U/A") valor(`D51HogS14') variable("nta_ISRAS + nta_ISRPF") nota("isr_personas_ancla = $isr_personas_ancla: con d51_s14 el ISR de personas de τ⁻ se ancla aqui (la LIF clasifica por quien entera; la CSI por quien soporta)")
if `D51NoFin' < . _tabla_anclas add, codigo(D.51) sector("S.11+S.12") fuente("CSI_106/109 · f.115 U/A") valor(`D51NoFin' + `D51Fin') variable(nta_ISRPM) nota("ISR de sociedades (informativo, fuera de τ⁻); con d51_s14 anclado a la celda en vez de a la LIF")
if `CuotasGobR' < . _tabla_anclas add, codigo(D.61) sector("S.13|S.12|S.11|S.15") fuente("CSI f.117 R/P") valor(`CuotasGobR' + `CuotasFinR' + `CuotasNoFinR' + `CuotasISFLSHR') variable("nta_CUOTAS_S13 … S15") nota("cuotas_por_sector = $cuotas_por_sector: D.61 por sector receptor (S.13 `: di %14.3fc `CuotasGobR'/1e9', S.12 `: di %14.3fc `CuotasFinR'/1e9' con D.614, S.11 `: di %14.3fc `CuotasNoFinR'/1e9', S.15 `: di %14.3fc `CuotasISFLSHR'/1e9' bn) = D.61 pagado por S.14")
noisily _tabla_anclas print, titulo("Anclas al SCN, NTA `anio'") sello("$scn_sello") unidad("MXN `anio'") ref("CUAD-2 §6")
if "$isr_personas_ancla" == "d51_s14" & `D51HogS14' == . {
	global isr_personas_ancla "lif"
	local flags `"`flags' "SCN sin D51HogS14 (CSI_115 f.115, 8.16b): isr_personas_ancla cae a lif""'
}
if "$cuotas_por_sector" == "on" & (`CuotasGobR' == . | `ContribSocHog' == .) {
	global cuotas_por_sector "off"
	local flags `"`flags' "SCN sin D.61 por sector receptor (CSI f.117 R/P, 8.16b): cuotas_por_sector cae a off""'
}



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
	* 8.17: 173417 (donativos a instituciones) se separa: es D.751 a ISFLSH, no una transferencia entre hogares *
	g byte efectivo = inlist(clave, "173416", "133030")
	g byte inst = clave == "173417"
	g byte especie = substr(clave, 1, 2) == "T9" & tipo_gasto == "G2" & clave != "T916"
	keep if efectivo | especie | inst
	g double nta_otor_ef = gasto_tri*4 if efectivo
	g double nta_otor_inst = gasto_tri*4 if inst
	g double nta_otor_esp = gasto_tri*4 if especie
	collapse (sum) nta_otor_ef nta_otor_inst nta_otor_esp, by(folioviv foliohog)
	save `otor'

* 2.3 Parentesco (jefe del hogar) *
	use folioviv foliohog numren parentesco using "`dir_enigh'/poblacion.dta", clear
	save `paren'
}

* 2.4 Base conciliada del motor *
use "${SIMROOT}/master/`anio'/households.dta", clear
drop if folioviv == ""
* v8.15b: parametros de Households desde la base (char cuad_params) cuando no hay sesion; luego el valor firmado *
local cuad : char _dta[cuad_params]
local cuad_linea ""
while "`cuad_firma'" != "" {
	gettoken p cuad_firma : cuad_firma
	gettoken firmado cuad_firma : cuad_firma
	if "${`p'}" == "" & regexm("`cuad'", "`p'=([^ ]+)") global `p' = regexs(1)
	if "${`p'}" == "" global `p' "`firmado'"
	local cuad_linea "`cuad_linea' `p'=${`p'}"
}
global cuad_params "`cuad_linea'"
* 8.17.2 (CUAD-3 §4.0, decision 2): con ing_mixto_ancla = b3n_d422, D.422 (CSI_115 f.99) esta en la celda de ing_mixto y fuera de la de D.4: la ancla de YL
* es D.1 + 2/3 (B.3n + D.422) y la de YA baja 2/3 D.422 (YAHogS14 − D.442 − 2/3 D.422); YL + YA = B.5n S.14 − D.442 no cambia. *
capture local D422Hog = scalar(D422Hog)
if _rc != 0 {
	local D422Hog = 0
	if "$ing_mixto_ancla" == "b3n_d422" local flags `"`flags' "SCN sin D422Hog (CSI_115 f.99): la ancla de YA/YL no descuenta D.422 aunque ing_mixto_ancla = b3n_d422""'
}
local D422m = cond("$ing_mixto_ancla" == "b3n_d422", `D422Hog', 0)
if "$altimir_elasticidad" != "" & "$altimir_elasticidad" != "1" & ("$pensiones_en_yl" == "on" | "$ing_mixto_depurado" == "off") {
	local flags `"`flags' "altimir_elasticidad = $altimir_elasticidad: las reconstrucciones con TaltimirSal/TaltimirSelf (pensiones_en_yl = on, ing_mixto_depurado = off) usan el factor medio; aproximadas""'
}
quietly {
	merge 1:1 folioviv foliohog numren using `prog', nogen keep(master match)
	merge m:1 folioviv foliohog using `otor', nogen keep(master match)
	merge 1:1 folioviv foliohog numren using `paren', nogen keep(master match)
	foreach v in nta_prog_raw nta_otor_ef nta_otor_inst nta_otor_esp {
		replace `v' = 0 if `v' == .
	}
	* v8.15b: las variables ROW y los impuestos embebidos ya no existen con la firma (suborrow = off, sin Altimir con impuestos): valen 0 *
	foreach v in ing_jubila ing_PAM ing_dona ing_heren ing_benef ing_prest ing_otrocap ing_ahorro ///
		ing_autor ing_trabmenor ing_remesas ing_t4_cap9 ing_t4_cap5 ing_estim_alqu gasto_anualDepreciacion ///
		gasto_anualComprasN ing_capitalROW ing_suborROW ISR_asalariados ISR_PF ISR_PM cuotasTP infonavit IVA ISAN Importaciones gas_pc_SaluT ///
		ImpNetProductos_mixK ImpNetProductos_soc ImpNetProductos_hog IEPS base_iepsp cuotasRCV cuotasViv cuotasSeg cuotasOTR cuotasIMP gas_pc_DiveT gas_pc_Vehi ing_d4_rel {
		capture confirm variable `v'
		if _rc != 0 g double `v' = 0
		else replace `v' = 0 if `v' == .
	}
	capture g pob = 1
	egen long nta_hhid = group(folioviv foliohog)
	g byte nta_adulto = edad >= `adulto'
}
local N = _N
quietly summarize nta_hhid, meanonly
local H = r(max)
noisily _log linea "Base NTA `anio': `=strtrim(string(`N', "%12.0fc"))' personas en `=strtrim(string(`H', "%12.0fc"))' hogares"



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
* v8.15b: Households.do deja los factores en chars de la base (TaltimirSal, TaltimirSelf, TaltimirHouse, TaltimirROWTrans); la reconstruccion
* desde cap5/cap4 ya no aplica (factor 1 con la firma) y solo se usa si no hay ni scalars ni chars (base anterior a v8.15b). *
local TSelf_c : char _dta[TaltimirSelf]
local TSal_c : char _dta[TaltimirSal]
local TRow_c : char _dta[TaltimirROWTrans]
capture confirm scalar TaltimirSelf
if _rc == 0 {
	local TSelf = scalar(TaltimirSelf)
	local TSal = scalar(TaltimirSal)
	if "`TSelf_c'" != "" & (reldif(`TSelf', `TSelf_c') > 1e-9 | reldif(`TSal', `TSal_c') > 1e-9) {
		local flags `"`flags' "Taltimir vivos (Self `TSelf', Sal `TSal') difieren de los chars de la base (`TSelf_c', `TSal_c')""'
	}
}
else if "`TSelf_c'" != "" {
	local TSelf = `TSelf_c'
	local TSal = `TSal_c'
	scalar TaltimirSelf = `TSelf'
	scalar TaltimirSal = `TSal'
	scalar TaltimirROWTrans = `TRow_c'
}
else {
	local TSelf = `TSelf_base'
	local TSal = `TSal_base'
	local flags `"`flags' "base sin chars Taltimir (anterior a v8.15b): factores reconstruidos de cap5/cap4""'
}
escalar pct NTATaltimirSelf = `TSelf'*100
escalar pct NTATaltimirSal = `TSal'*100
noisily _log linea "Altimir: TaltimirSelf `=strtrim(string(`TSelf', "%6.4f"))', TaltimirSal `=strtrim(string(`TSal', "%6.4f"))'"



**********************************
**# 4. Componentes por persona
**********************************
quietly {

** 4.1 Lo que viaja dentro de ing_mixto y no es ingreso factorial (crudo; ing_t4_cap9 ya está × TaltimirSelf) **
* remesas crudas = cap9/TaltimirSelf − (lo demás crudo de cap9); transferencias = dona + heren + benef; financieros = prest + otrocap + ahorro *
* v8.15b (CUAD-0 firma, decision 3): con ing_mixto_depurado = transf_negocios ninguna transferencia ni flujo financiero viaja dentro de
* ing_mixto (cap5, cap7, cap9 con factor 1, fuera de Yl/Yk): no hay nada que restar y nta_rem_raw son las remesas crudas de la ENIGH. *
if "$ing_mixto_depurado" == "transf_negocios" {
	g double nta_rem_raw = ing_remesas/scalar(TaltimirROWTrans)
	g double nta_mixto_transf = 0
	g double nta_mixto_fin = 0
}
else {
	g double nta_rem_raw = ing_t4_cap9/`TSelf' - (ing_autor + ing_trabmenor + ing_prest + ing_otrocap + ing_ahorro + ing_benef + ing_heren)
	replace nta_rem_raw = 0 if nta_rem_raw < 0 & nta_rem_raw > -1e-6
	g double nta_mixto_transf = (ing_dona + ing_heren + ing_benef + nta_rem_raw)*cond("$nta_mixto" == "crudo", 1, `TSelf')
	g double nta_mixto_fin = (ing_prest + ing_otrocap + ing_ahorro)*cond("$nta_mixto" == "crudo", 1, `TSelf')
}
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
g double nta_pens_enYl = cond("$pensiones_en_yl" == "off", 0, min(ing_jubila*`TSal', ing_subor))	// v8.15b-pre: con pensiones_en_yl = off no hay nada que restar
* tamaño del FLAG: lo que ing_mixto trae de transferencias y flujos financieros, escalado como ingreso de cuenta propia *
g double nta_mixto_flag = cond("$ing_mixto_depurado" == "transf_negocios", 0, (ing_dona + ing_heren + ing_benef + nta_rem_raw + ing_prest + ing_otrocap + ing_ahorro)*`TSelf')

** 4.2 YL (v8.14, CONC-1 §6.1: Yl = ing_subor + ing_mixtoL y ing_mixtoL = ⅔ ing_mixto trae ⅔ de los impuestos netos a los productos
**     que Altimir embebió en ing_mixto, ImpNetProductos_mixK; se sacan de aquí, el ⅓ que viaja en Yk se saca de YA en §4.3) **
g double nta_impprod_YL = 2/3*ImpNetProductos_mixK
g double YL = Yl - nta_pens_enYl - 2/3*(nta_mixto_transf + nta_mixto_fin) - nta_impprod_YL + ing_suborROW
label var YL "Ingreso laboral NTA (sin pensiones, transferencias de ing_mixto ni 2/3 de ImpNet embebido; con ROW)"

** 4.3 YA (neto de depreciación; alquiler imputado al jefe; con ROW; SIN los impuestos netos a los productos que Altimir
**     embebe en Yk: NTA-1b pieza 3 los saca de aquí y los reasigna ∝ consumo como ImpProd, §4.4b) **
* Lo que Altimir puso de ImpNetProductos en cada persona: Households.do l. 2420-2427 lo deja calculado (∝ ing_mixtoK,
* ing_capital, ing_estim_alqu con las participaciones MixKN / ExNOpSoc / ExNOpHog); Σ = ImpNet del BIE. Los otros
* impuestos a la producción (D.29 − D.39: ImpNetProduccionL/K, 247 bn) se quedan en Yl/Yk como en el motor (FLAG).
* v8.14 (CONC-1 §6.1): ImpNetProductos_mixK se calculó ∝ ing_mixtoK pero es el embebido en TODO ing_mixto, que el motor
* reparte ⅔ a Yl (ing_mixtoL) y ⅓ a Yk (ing_mixtoK): de YA se saca solo el ⅓ (165.9 bn en 2024); los ⅔ (331.7) salen de YL (§4.2).
* Antes se restaban de YA los 497.6 completos y YL los conservaba (doble conteo frente a ImpProd). *
g double nta_impprod_motor = ImpNetProductos_mixK + ImpNetProductos_soc + ImpNetProductos_hog
g double nta_impprod_YA = nta_impprod_motor - nta_impprod_YL
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
g double YA_motor = Yk - gasto_anualDepreciacion - ing_estim_alqu + ALQ - 1/3*ImpNetProductos_mixK - ImpNetProductos_soc ///
	- 1/3*(nta_mixto_transf + nta_mixto_fin) + ing_capitalROW
label var YA_motor "Ingreso de activos del motor (neto de depreciación, sin el ImpNet embebido en Yk, sin D.8)"

** 4.3b nta_YA (NTA-1c): el TOTAL de YA del motor se re-ancla a YAHogS14 = B.2n + 1/3 B.3n + D.4 neto del sector hogares
**      (CSI_115 filas 69, 70, 95), repartido ∝ YA_motor (misma distribución, otro nivel). ImpNet ya fuera (pieza 3) y D.8 ya
**      dentro aparte (pieza 4): no se duplican. El alquiler imputado (parte de YA_motor) se escala con el mismo factor. **
tabstat YA_motor [fw=factor], stat(sum) save
local YA_motor_tot = r(StatTotal)[1,1]
* v8.15b (firma 11): con cuotas_d614 = neto la ancla de YA es YAHogS14 − D.442 (el circuito D.442/D.614 es neutral en el hogar) *
local YAHogS14n = `YAHogS14' - cond("$cuotas_d614" == "neto", `D442Hog', 0) - `D422m'*2/3
local fYA = cond("$nta_YA" == "S14", `YAHogS14n'/`YA_motor_tot', 1)
if "$nta_YA" == "S14" & "$yk_ancla" == "b2n_b3n_d4" & reldif(`fYA', 1) > 1e-9 {
	local flags `"`flags' "factor YA = `=string(`fYA', "%8.6f")' ≠ 1: el motor (yk_ancla = b2n_b3n_d4) debia traer Yk − CCF = YAHogS14 − D.442 − 2/3 D.422 al peso""'
}
g double YA_base = YA_motor*`fYA'
replace ALQ = ALQ*`fYA'
label var YA_base "Ingreso de activos NTA sin D.8 (nta_YA = $nta_YA: YA_motor × factor a B.2n + 1/3 B.3n + D.4 neto S.14 − D.442 con cuotas_d614 = neto)"

** 4.4 Consumo privado (precios de comprador; residentes) **
g double Cpriv = gastoanualTOT + gasto_anualComprasN
label var Cpriv "Consumo privado (gas_pc_* anclado + compras netas de no residentes; consumo_ancla = $consumo_ancla: con p3_s14 Σ = P.3 S.14)"

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
* 8.17 (CUAD-2 §5 S.13; hub = inbd): el consumo colectivo es P.32 del gobierno general (CSI_112 f.168), no ConGob BIE − D.63 (que mezclaba el vintage
* BIE−CSI del consumo de gobierno y la especie de las ISFLSH: FLAG 15). La diferencia ConGob BIE − P.3 S.13 CSI es vintage declarado. *
local Colectivo = `ConGob' - `TransfEspecie'
if "$hub" == "inbd" & `P32Gob' < . {
	local Colectivo = `P32Gob'
	local flags `"`flags' "consumo colectivo = P.32 S.13 CSI `=string(`P32Gob'/1e9, "%9.1f")' bn (hub = inbd); ConGob BIE − P.3 S.13 CSI = `=string((`ConGob' - `P3Gob')/1e9, "%6.1f")' bn de vintage declarado""'
}
Distribucion CpubCol, relativo(pob) macro(`Colectivo')
g double Cpub = CpubInd + CpubCol
label var CpubEduc "Consumo público individual: educación (SerEGob, perfil de matrícula)"
label var CpubSalud "Consumo público individual: salud (SaluGob ∝ gas_pc_SaluT)"
label var CpubRestoInd "Consumo público individual: resto de D.63 (per cápita, perfil PerfilesSim «otros gastos»)"
label var CpubInd "Consumo público individual = D.63 TransfEspecie = τ⁺ público en especie"
label var CpubCol "Consumo público colectivo (per cápita, sin dimensión de edad) = τ⁺ público colectivo (hub = inbd: P.32 S.13 CSI; si no ConGob − D.63)"
label var Cpub "Consumo público = individual (D.63) + colectivo (ConGob − D.63)"
g double C = Cpriv + Cpub
label var C "Consumo total (privado + público individual + público colectivo)"

** 4.6 τ⁻ público = lo que los hogares pagan en S.14 (NTA-1b, pieza 2): ISR de personas físicas (asalariados con
**     retenciones + PF; LIF), cuotas a la seguridad social (infonavit una sola vez; ancla nta_cuotas) e indirectos
**     anclados a LIF. FUERA de τ⁻: ISR_PM y OTROSK (en el SCN los pagan las sociedades, D.5 de S.11/S.12); se
**     calculan y se reportan como TmenFuera, no se restan a nadie. **
* 8.16b (isr_personas_ancla = d51_s14; CUAD-1 §7 y firma §B): la LIF clasifica el ISR por quien lo entera (retenedor) y la CSI por quien lo soporta;
* el τ⁻ directo de las personas se ancla a D.51 S.14 (ISR asalariados + PF con un factor sobre la LIF: la CSI no los separa) y el ISR de sociedades
* a D.51 S.11 + S.12 (informativo, fuera de τ⁻). La diferencia con la LIF es la fila «LIF vs CSI por sector» de nta-identidad.txt. *
local fD51 = 1
if "$isr_personas_ancla" == "d51_s14" {
	local fD51 = `D51HogS14'/(`ISRAS' + `ISRPF')
	Distribucion nta_ISRAS, relativo(ISR_asalariados) macro(`=`ISRAS'*`fD51'')
	Distribucion nta_ISRPF, relativo(ISR_PF) macro(`=`ISRPF'*`fD51'')
	Distribucion nta_ISRPM, relativo(ISR_PM) macro(`=`D51NoFin' + `D51Fin'')
}
else {
	Distribucion nta_ISRAS, relativo(ISR_asalariados) macro(`ISRAS')
	Distribucion nta_ISRPF, relativo(ISR_PF) macro(`ISRPF')
	Distribucion nta_ISRPM, relativo(ISR_PM) macro(`ISRPM')
	local flags `"`flags' "isr_personas_ancla = lif: ISR de personas anclado a la LIF (1,330.8 bn) y no a D.51 S.14; la brecha de S lleva la fila D.5""'
}
label var nta_ISRAS "τ⁻: ISR por salarios (∝ ISR_asalariados de los formales; ancla $isr_personas_ancla)"
label var nta_ISRPF "τ⁻: ISR de personas fisicas (∝ ISR_PF; ancla $isr_personas_ancla)"
tempvar cuo
g double `cuo' = cuotasTP + infonavit
if "$nta_cuotas" == "S14" & "$cuotas_por_sector" == "on" {
	* 8.16b (cuotas_por_sector = on; CUAD-1 Tabla 1b): D.61 pagado por S.14 se reparte por sector RECEPTOR con la celda de cada cuadro (f.117 R/P):
	* S.13 (IMSS/ISSSTE como fondos de seguridad social) ∝ cuotas de los seguros sociales de los afiliados a IMSS/ISSSTE; S.12 (Afores, PENSIONISSSTE,
	* Infonavit/FOVISSSTE, aseguradoras) ∝ retiro + vivienda, con D.614 fuera (cuotas_d614 = neto: la celda S.12 trae D.614 = D.442 y se descuenta);
	* S.11 (planes de empleadores) y S.15 ∝ cuotas de los regimenes distintos de IMSS/ISSSTE (cuotasOTR + cuotasIMP). Σ por sector = celda a 1e-9. *
	local D614 = `ContribSocHog' - `CuotasHogS14'
	local CuotasS12n = `CuotasFinR' - cond("$cuotas_d614" == "neto", `D614', 0)
	tempvar relS13 relS12 relS11
	g double `relS13' = cond(inlist(formal2, 1, 2), cuotasSeg, 0)
	g double `relS12' = cuotasRCV + cuotasViv
	g double `relS11' = cuotasOTR + cuotasIMP
	Distribucion nta_CUOTAS_S13, relativo(`relS13') macro(`CuotasGobR')
	Distribucion nta_CUOTAS_S12, relativo(`relS12') macro(`CuotasS12n')
	Distribucion nta_CUOTAS_S11, relativo(`relS11') macro(`CuotasNoFinR')
	Distribucion nta_CUOTAS_S15, relativo(`relS11') macro(`CuotasISFLSHR')
	egen double nta_CUOTAS = rsum(nta_CUOTAS_S13 nta_CUOTAS_S12 nta_CUOTAS_S11 nta_CUOTAS_S15)
	label var nta_CUOTAS_S13 "τ⁻ cuotas al gobierno general S.13 (IMSS, ISSSTE: seguros sociales; D.61 f.117 R/P de CSI_112)"
	label var nta_CUOTAS_S12 "τ⁻ cuotas a sociedades financieras S.12 (Afores, PENSIONISSSTE, Infonavit, FOVISSSTE; D.61 CSI_109 − D.614)"
	label var nta_CUOTAS_S11 "τ⁻ cuotas a sociedades no financieras S.11 (planes de empleadores; D.61 CSI_106)"
	label var nta_CUOTAS_S15 "τ⁻ cuotas a ISFLSH S.15 (D.61 CSI_118)"
	local CuotasSectores = `CuotasGobR' + `CuotasS12n' + `CuotasNoFinR' + `CuotasISFLSHR'
}
else if "$nta_cuotas" == "S14" {
	* D.61 − D.614 de S.14 (CuotasHogS14): lo que los hogares pagan a los sistemas, incluidas las contribuciones
	* patronales e imputadas que el motor ya puso en Yl (TaltimirSal lleva SSEmpleadores + SSImputada) *
	Distribucion nta_CUOTAS, relativo(`cuo') macro(`CuotasHogS14')
	local CuotasSectores = .
}
else {
	Distribucion nta_CUOTAS if formal2 == 1, relativo(cuotasTP) macro(`CUOTAS')
	local CuotasSectores = .
}
replace nta_CUOTAS = 0 if nta_CUOTAS == .
Distribucion nta_OTROSK, relativo(ISR_PM) macro(`OTROSK')
Distribucion nta_IVA, relativo(IVA) macro(`IVA')
Distribucion nta_ISAN, relativo(ISAN) macro(`ISAN')
* 8.16b (ieps_relativo = micro; CUAD-1 §8 bis ficha 4): IEPS no petrolero ∝ IEPS micro por categoria, petrolero ∝ gasolinas + combustibles (base_iepsp);
* con proxy (v8.15.3) ∝ bebidas alcoholicas y ∝ compra de vehiculos *
local rel_iepsnp = cond("$ieps_relativo" == "micro", "IEPS", "gas_pc_BebA")
local rel_iepsp = cond("$ieps_relativo" == "micro", "base_iepsp", "gas_pc_Vehi")
if "$ieps_relativo" != "micro" local flags `"`flags' "ieps_relativo = $ieps_relativo: IEPS repartido ∝ `rel_iepsnp' / `rel_iepsp' (proxy de v8.15.3)""'
Distribucion nta_IEPSNP, relativo(`rel_iepsnp') macro(`IEPSNP')
Distribucion nta_IEPSP, relativo(`rel_iepsp') macro(`IEPSP')
Distribucion nta_IMPORT, relativo(Importaciones) macro(`IMPORT')
* 8.17 (CUAD-2; cierre de la fila D.5): D.59 otros impuestos corrientes pagados por los hogares (predial y tenencia, fuera del consumo desde 8.16b) es τ⁻
* ∝ alquiler imputado + compra de vehiculos (proxy declarado, sello amarillo); con el ISR anclado a D.51, Σ (ISR + D.59) = D.5 S.14 al peso. *
if "$hub" == "inbd" & `D59Hog' < . {
	tempvar rel59
	g double `rel59' = ing_estim_alqu + gas_pc_Vehi
	Distribucion TmenD59, relativo(`rel59') macro(`D59Hog')
}
else {
	g double TmenD59 = 0
	if "$hub" == "inbd" local flags `"`flags' "SCN sin D59Hog (CSI_115 f.116): τ⁻ sin D.59""'
}
label var TmenD59 "τ⁻: otros impuestos corrientes D.59 S.14 (predial y tenencia; ∝ alquiler imputado + vehículos, proxy declarado)"
egen double TmenDir = rsum(nta_ISRAS nta_ISRPF nta_CUOTAS TmenD59)
egen double TmenInd = rsum(nta_IVA nta_ISAN nta_IEPSNP nta_IEPSP nta_IMPORT)
egen double TmenFuera = rsum(nta_ISRPM nta_OTROSK)
g double Tmen_hh = TmenDir + TmenInd
g double Tmen = Tmen_hh
label var Tmen_hh "τ⁻ público del hogar = directos + indirectos (sin lo atribuido por retenido/déficit)"
label var TmenDir "τ⁻ público directo (ISR asalariados + PF; D.59; cuotas $nta_cuotas)"
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
label var Tpub "τ⁺ público = efectivo + especie (individual) + colectivo (+ ahorro de las ISFLSH atribuido, 8.17)"
* 8.17: prestaciones en efectivo por sector pagador (CUAD-2 §6.2): TpubEf se ancla a D.62 + D.759 de S.14, que incluye las prestaciones privadas
* (D.62 pagadas por S.11 + S.12 + S.15 = 442.344 bn); se separan ∝ pensiones (TpubPens) para que el Sankey las dibuje desde las sociedades y las ISFLSH. *
local D62priv = cond(`D62NoFinU' < ., `D62NoFinU' + `D62FinU' + `D62ISFLSHU', 0)
tabstat TpubPens [fw=factor], stat(sum) save
local TpubPens_tot = r(StatTotal)[1,1]
g double TpubEfPriv = cond(`TpubPens_tot' > 0, TpubPens*`D62priv'/`TpubPens_tot', 0)
g double TpubEfPub = TpubEf - TpubEfPriv
label var TpubEfPriv "τ⁺ efectivo pagado por S.11 + S.12 + S.15 (D.62 privadas; ∝ pensiones, declarado)"
label var TpubEfPub "τ⁺ efectivo pagado por el gobierno general (D.62 S.13 + D.759 S.14)"

** 4.7b (8.17; firma §B 17-18, CUAD-2 §4): lo que los otros sectores retienen o desahorran llega a las personas. **
*  retenido_a_personas = on: YA_ret = B.5n S.11 + S.12 ∝ ing_d4_rel (regla P, sello rojo) y TmenRet = B.5n − B.8n de S.11 + S.12 ∝ ing_d4_rel (lo que las
*  sociedades pagan o transfieren por cuenta de sus dueños: ISR de sociedades, D.8, cuotas recibidas menos prestaciones y transferencias pagadas);
*  S_ret = YA_ret − TmenRet suma B.8n de S.11 + S.12. deficit_a_personas: TmenDef = −B.8n S.13 (deuda publica asignada) per capita (C) o ∝ τ⁻ del hogar
*  (tau_menos), con S_def = −TmenDef (quien «paga» la deuda la desahorra hoy). ISFLSH (isflsh_regla = sector): su ahorro B.8n S.15 llega per capita
*  como τ⁺ (TpubISFLSH) y S (S_isflsh): las ISFLSH sirven a los hogares. La identidad por persona no cambia: cada pieza entra por los dos lados. *
local B5nSoc = cond(`B5nNoFin' < ., `B5nNoFin' + `B5nFin', .)
local B8nSoc = cond(`B8nNoFin' < ., `B8nNoFin' + `B8nFin', .)
if "$retenido_a_personas" == "on" & `B5nSoc' < . & `B8nSoc' < . {
	Distribucion YA_ret, relativo(ing_d4_rel) macro(`B5nSoc')
	Distribucion TmenRet, relativo(ing_d4_rel) macro(`=`B5nSoc' - `B8nSoc'')
	local flags `"`flags' "retenido_a_personas = on: B.5n S.11 + S.12 `=string(`B5nSoc'/1e9, "%9.1f")' bn a YA y B.8n `=string(`B8nSoc'/1e9, "%9.1f")' bn a S ∝ ing_d4_rel (regla P, sello rojo)""'
}
else {
	g double YA_ret = 0
	g double TmenRet = 0
	if "$retenido_a_personas" == "on" local flags `"`flags' "SCN sin B.5n/B.8n de S.11 + S.12: retenido_a_personas cae a off""'
}
g double S_ret = YA_ret - TmenRet
if "$deficit_a_personas" != "off" & `B8nGob' < . {
	tempvar reldef
	g double `reldef' = cond("$deficit_a_personas" == "tau_menos", Tmen_hh, pob)
	Distribucion TmenDef, relativo(`reldef') macro(`=-`B8nGob'')
	local flags `"`flags' "deficit_a_personas = $deficit_a_personas: B.8n S.13 `=string(`B8nGob'/1e9, "%9.1f")' bn a las personas (`=cond("$deficit_a_personas" == "per_capita", "per capita, C", "∝ τ⁻ del hogar")')""'
}
else {
	g double TmenDef = 0
	if "$deficit_a_personas" != "off" local flags `"`flags' "SCN sin B.8n S.13: deficit_a_personas cae a off""'
}
g double S_def = -TmenDef
* alternativa medida (firma §B 18): deficit ∝ τ⁻ del hogar, por grupo, solo para el reporte *
tempvar reltau
g double `reltau' = Tmen_hh
if `B8nGob' < . Distribucion TmenDefTau, relativo(`reltau') macro(`=-`B8nGob'')
else g double TmenDefTau = 0
if `B8nISFLSH' < . {
	Distribucion TpubISFLSH, relativo(pob) macro(`B8nISFLSH')
}
else g double TpubISFLSH = 0
g double S_isflsh = TpubISFLSH
replace Tmen = Tmen_hh + TmenRet + TmenDef
replace Tpub = Tpub + TpubISFLSH
label var YA_ret "Ingreso de activos retenido por las sociedades (B.5n S.11 + S.12 ∝ ing_d4_rel; retenido_a_personas = $retenido_a_personas)"
label var TmenRet "τ⁻ retenido: lo que las sociedades pagan por cuenta de sus dueños (B.5n − B.8n S.11 + S.12 ∝ ing_d4_rel)"
label var S_ret "Ahorro retenido por las sociedades atribuido a la persona (= B.8n S.11 + S.12 ∝ ing_d4_rel)"
label var TmenDef "τ⁻ deuda pública asignada (−B.8n S.13; deficit_a_personas = $deficit_a_personas)"
label var TmenDefTau "Deuda pública asignada ∝ τ⁻ del hogar (alternativa tau_menos, solo medida)"
label var S_def "Desahorro público atribuido a la persona (= B.8n S.13 repartido; deficit_a_personas = $deficit_a_personas)"
label var TpubISFLSH "τ⁺ ahorro de las ISFLSH atribuido per cápita (B.8n S.15)"
label var S_isflsh "Ahorro de las ISFLSH atribuido a la persona (B.8n S.15 per cápita)"

** 4.8 Transferencias privadas entre hogares **
g double InterRec = ing_dona + ing_heren
g double Remesas = ing_remesas
label var InterRec "τ⁺ inter-hogar recibido: donativos (P039, P040) + herencias (P057)"
label var Remesas "τ⁺ inter-hogar recibido del exterior: remesas (ing_remesas, anclado a ROWTrans)"
* 8.17 (CUAD-2 §6.2): indemnizaciones de seguros no de vida recibidas por los hogares (D.72, CSI_115 f.143) ∝ gasto en seguros (dentro de gas_pc_DiveT) *
if "$hub" == "inbd" & `D72HogR' < . Distribucion RecIndem, relativo(gas_pc_DiveT) macro(`D72HogR')
else g double RecIndem = 0
g double OtrosRec = RecIndem
label var RecIndem "τ⁺ recibido de las sociedades financieras: indemnizaciones de seguros D.72 (∝ gas_pc_DiveT)"
label var OtrosRec "τ⁺ recibido de otros sectores (D.72)"
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
* 8.17 (inter_hogar = balance): lo otorgado entre hogares (173416, 133030) se escala a lo recibido (P039 + P040 + P057): D.75 entre residentes es neto
* cero en el SCN y la ENIGH subreporta lo dado (sello rojo). Con enigh no se escala y el desbalance queda en la brecha de S. Las sumas son por hogar
* (el monto del hogar × la participación del adulto), no por persona. *
tempvar oto inst
g double `oto' = nta_otor_hog*nta_share
g double `inst' = nta_otor_inst*nta_share
tabstat InterRec `oto' `inst' [fw=factor], stat(sum) save
local InterRec_tot = r(StatTotal)[1,1]
local Otor_tot = r(StatTotal)[1,2]
local Inst_tot = r(StatTotal)[1,3]
local fInter = cond("$inter_hogar" == "balance" & `Otor_tot' > 0, `InterRec_tot'/`Otor_tot', 1)
if "$inter_hogar" == "balance" local flags `"`flags' "inter_hogar = balance: lo otorgado entre hogares (ENIGH `=string(`Otor_tot'/1e9, "%7.1f")' bn) × `=string(`fInter', "%7.4f")' = lo recibido `=string(`InterRec_tot'/1e9, "%7.1f")' bn (D.75 entre residentes neto cero; sello rojo)""'
else local flags `"`flags' "inter_hogar = enigh: lo otorgado entre hogares no se escala; desbalance `=string((`InterRec_tot' - `Otor_tot')/1e9, "%7.1f")' bn en la brecha de S""'
replace nta_otor_hog = nta_otor_hog*`fInter'
escalar pct NTAFactorInter = `fInter'*100
g double InterOtor = nta_otor_hog*nta_share
label var InterOtor "τ⁻ inter-hogar otorgado (efectivo; del hogar a sus adultos con ingreso ∝ YL+YA; inter_hogar = $inter_hogar)"
* 8.17 (CUAD-2 §6.2, cierre de la fila D.7 pagada por S.14 = 438.209 bn): transferencias corrientes pagadas a otros sectores. Donativos a ISFLSH D.751
* ∝ gastohogar 173417 del hogar (a sus adultos ∝ YL + YA) con un factor a la celda (FLAG 35: ENIGH 88.8 vs CSI 274.3); primas netas D.71 ∝ gas_pc_DiveT;
* remesas enviadas D.752 per capita de adultos con ingreso (FLAG 36: sin variable ENIGH); D.759 pagada ∝ YL + YA de adultos (receptor por identificar). *
if "$hub" == "inbd" & `D751HogU' < . {
	if `Inst_tot' > 0 {
		local fDona = `D751HogU'/`Inst_tot'
		g double OtorISFLSH = nta_otor_inst*nta_share*`fDona'
		local flags `"`flags' "donativos a ISFLSH: ENIGH 173417 `=string(`Inst_tot'/1e9, "%7.1f")' bn × `=string(`fDona', "%7.4f")' = D.751 S.14 `=string(`D751HogU'/1e9, "%7.1f")' bn (FLAG 35, sello rojo)""'
	}
	else {
		Distribucion OtorISFLSH, relativo(nta_w) macro(`D751HogU')
		local fDona = .
		local flags `"`flags' "donativos a ISFLSH: sin 173417 en la ENIGH; D.751 ∝ YL + YA de adultos (FLAG 35)""'
	}
	Distribucion OtorPrimas, relativo(gas_pc_DiveT) macro(`D71HogU')
	tempvar adulto_ing
	g double `adulto_ing' = nta_adulto & (YL + YA_base) > 0
	Distribucion OtorRemEnv, relativo(`adulto_ing') macro(`D752HogU')
	Distribucion OtorD759, relativo(nta_w) macro(`D759HogU')
}
else {
	foreach v in OtorISFLSH OtorPrimas OtorRemEnv OtorD759 {
		g double `v' = 0
	}
	local fDona = .
}
egen double OtrosOtor = rsum(OtorISFLSH OtorPrimas OtorRemEnv OtorD759)
label var OtorISFLSH "τ⁻ donativos a ISFLSH D.751 (∝ 173417 del hogar, factor a la celda: FLAG 35)"
label var OtorPrimas "τ⁻ primas netas de seguros no de vida D.71 (∝ gas_pc_DiveT)"
label var OtorRemEnv "τ⁻ remesas enviadas D.752 (per cápita de adultos con ingreso: FLAG 36)"
label var OtorD759 "τ⁻ otras transferencias corrientes diversas D.759 pagadas (∝ YL + YA de adultos; receptor por identificar)"
label var OtrosOtor "τ⁻ transferencias corrientes pagadas a otros sectores (D.7 pagada por S.14 sin la inter-hogar)"

** 4.10 S: residual del hogar, a los adultos ∝ (YL + YA) **
g double nta_yd = YL + ImpProd + YA_base + YA_d8 + TpubEf + TpubEsp + TpubCol + InterRec + OtrosRec + Remesas - Tmen_hh - InterOtor - OtrosOtor
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
* v8.15b (CUAD-0 firma C): brecha esperada ≈ +11 % con cuotas_d614 = neto. 8.16b (CUAD-1 §7): Δ esperado ≈ −0.9 % (−17.035 bn) una vez cerradas las
* filas D.5 (ancla D.51 S.14), Cpriv (P.3 S.14) y τ (D.62 + D.7 netas); la fila τ (+461.0 bn: donativos a ISFLSH, primas, remesas enviadas, D.759
* privado) es de CUAD-2 (8.17) y sigue abierta en 8.16b, asi que la brecha observada la lleva integra. Si difiere en mas de 2 puntos de la esperada
* se FLAGuea y la descomposicion de abajo (nta-identidad.txt) dice partida por partida de donde sale. *
local brecha_esp = -0.9
if abs(`brecha' - `brecha_esp') > 2 local flags `"`flags' "brecha Σ S vs B.8n = `=string(`brecha', "%6.1f")' % difiere en mas de 2 puntos de la esperada tras 8.17 (`=string(`brecha_esp', "%4.1f")' %, CUAD-1 §7 / CUAD-2 §7): parar y descomponer (cuadro 3 de nta-identidad.txt)""'
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
	g double S_hh = S_sinancla + YA_ajuste
}
else if "$nta_anclaS" == "multiplicativo" {
	g double S_hh = S_sinancla*`fS'
}
else {
	g double S_hh = S_sinancla
}
g double S_ajuste = S_hh - S_sinancla - YA_ajuste
* 8.17: S de la persona = S del hogar (anclado a B.8n S.14) + lo atribuido de los otros sectores (retenido, deficit, ISFLSH); con los defaults firmados
* Σ S = B.8n S.1 (gate §5). YA_hh y Tmen_hh son la cuenta del hogar (v3, v2); YA y Tmen la de la persona (panel, identidad, nta-persona.dta). *
g double S = S_hh + S_ret + S_def + S_isflsh
label var YA_ajuste "Ajuste por ancla aditiva Σ S = AhorroHog (0 salvo nta_anclaS = aditivo); contrapartida de S"
label var S_ajuste "Ancla multiplicativa de S del hogar (S_hh − S_sinancla; 0 salvo nta_anclaS = multiplicativo): declarado fuera de la identidad"
g double YA_hh = YA_base + YA_d8 + YA_ajuste
g double YA = YA_hh + YA_ret
label var S_hh "Ahorro NTA del hogar (residual del hogar a adultos ∝ YL+YA; ancla: $nta_anclaS)"
label var S "Ahorro NTA de la persona = S_hh + S_ret + S_def + S_isflsh (retenido_a_personas = $retenido_a_personas; deficit_a_personas = $deficit_a_personas)"
label var YA_hh "Ingreso de activos NTA del hogar (nta_YA = $nta_YA; con D.8)"
label var YA "Ingreso de activos NTA de la persona (YA_hh + YA_ret)"

** 4.12 Intra-hogar: el único residual (con S sin ancla: Σ por hogar = 0 en todos los modos) **
g double Intra = C - YL - ImpProd - (YA - YA_ajuste) - Tpub + Tmen - InterRec - OtrosRec - Remesas + InterOtor + OtrosOtor + S_sinancla + S_ret + S_def + S_isflsh
label var Intra "τ intra-hogar (residual por persona con S sin ancla; Σ por hogar = 0)"
g double Resid = C - YL - ImpProd - (Tpub + InterRec + OtrosRec + Remesas - Tmen - InterOtor - OtrosOtor) - (YA - YA_ajuste - S_sinancla - S_ret - S_def - S_isflsh) - Intra
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
if "$ing_mixto_depurado" == "transf_negocios" local flags `"`flags' "ing_mixto del motor = `=string(scalar(NTAMixtoMotor)/1e9, "%9.1f")' bn = B.3n S.14 (honorarios + negocios propios; sin transferencias ni flujos financieros dentro: ing_mixto_depurado=transf_negocios)""'
else local flags `"`flags' "ing_mixto del motor = `=string(scalar(NTAMixtoMotor)/1e9, "%9.1f")' bn, de los cuales `=string(scalar(NTAMixtoTransfFin)/1e9, "%9.1f")' bn (`=string(scalar(NTAMixtoTransfFinPct), "%4.1f")' %) son transferencias y flujos financieros × TaltimirSelf; nta_mixto=$nta_mixto""'
escalar mxn NTAAjusteS = `D'
escalar pct NTAFactorS = `fS'*100
escalar mxn NTASsinAncla = `S_micro'
escalar pct NTABrechaSPct = `brecha'
escalar mxn NTAYAMotorNac = `YA_motor_tot'
escalar pct NTAFactorYA = `fYA'*100
quietly tabstat YA_base S_ajuste [fw=factor], stat(sum) save
escalar mxn NTAYABaseNac = r(StatTotal)[1,1]
escalar mxn NTASAjusteNac = r(StatTotal)[1,2]
noisily _log linea "YA (bn): motor `=strtrim(string(`YA_motor_tot'/1e9, "%14.3fc"))'; YAHogS14 `=strtrim(string(`YAHogS14'/1e9, "%14.3fc"))' = B.2n `=strtrim(string(`ExNOpHogS14'/1e9, "%14.3fc"))' + 1/3 B.3n `=strtrim(string(`MixNHogS14'/3e9, "%14.3fc"))' + D.4 neto `=strtrim(string(`RentaPropHogNeta'/1e9, "%14.3fc"))'"
noisily _log linea "YA (bn): − D.442 − 2/3 D.422 `=strtrim(string((`YAHogS14' - `YAHogS14n')/1e9, "%14.3fc"))' (cuotas_d614 $cuotas_d614; ing_mixto_ancla $ing_mixto_ancla) = ancla `=strtrim(string(`YAHogS14n'/1e9, "%14.3fc"))'; factor `=strtrim(string(`fYA', "%8.6f"))' (nta_YA $nta_YA)"
quietly tabstat TmenDir TmenInd TmenFuera nta_CUOTAS [fw=factor], stat(sum) save
escalar mxn NTATmenFueraNac = r(StatTotal)[1,3]
escalar mxn NTACuotasNac = r(StatTotal)[1,4]
noisily _log linea "τ⁻ (bn): directos `=strtrim(string(r(StatTotal)[1,1]/1e9, "%14.3fc"))' (cuotas $nta_cuotas `=strtrim(string(r(StatTotal)[1,4]/1e9, "%14.3fc"))'); indirectos `=strtrim(string(r(StatTotal)[1,2]/1e9, "%14.3fc"))'"
noisily _log linea "τ⁻ (bn): fuera de τ⁻, ISR PM + OTROSK `=strtrim(string(r(StatTotal)[1,3]/1e9, "%14.3fc"))'"
quietly tabstat ImpProd nta_impprod_motor TmenInd nta_impprod_YA nta_impprod_YL [fw=factor], stat(sum) save
escalar mxn NTAImpProdNac = r(StatTotal)[1,1]
escalar mxn NTAImpProdMotor = r(StatTotal)[1,2]
escalar mxn NTAImpProdMotorYA = r(StatTotal)[1,4]
escalar mxn NTAImpProdMotorYL = r(StatTotal)[1,5]
escalar pct NTAFactorIndirectos = r(StatTotal)[1,3]/`ImpNetosProd'*100
noisily _log linea "Impuestos a productos (bn): ImpNetosProd D.21 − D.31 `=strtrim(string(`ImpNetosProd'/1e9, "%14.3fc"))'; ImpNet BIE `=strtrim(string(`ImpNetBIE'/1e9, "%14.3fc"))'"
noisily _log linea "Impuestos a productos (bn): embebido por Altimir, sacado `=strtrim(string(r(StatTotal)[1,2]/1e9, "%14.3fc"))' = de YA `=strtrim(string(r(StatTotal)[1,4]/1e9, "%14.3fc"))' + de YL `=strtrim(string(r(StatTotal)[1,5]/1e9, "%14.3fc"))'"
noisily _log linea "Impuestos a productos (bn): Σ indirectos micro τ⁻ `=strtrim(string(r(StatTotal)[1,3]/1e9, "%14.3fc"))'; factor indirectos / ImpNetosProd `=strtrim(string(r(StatTotal)[1,3]/`ImpNetosProd', "%7.4f"))'"
escalar pct NTAFactorTau = `fTau'*100
escalar mxn NTATpubEfPre = `TpubEf_pre'
noisily _log linea "τ⁺ efectivo (bn): PEF/ENIGH `=strtrim(string(`TpubEf_pre'/1e9, "%14.3fc"))'; D.62 + D.759 S.14 `=strtrim(string(`TauPubS14'/1e9, "%14.3fc"))' (D.62 `=strtrim(string(`PrestSocHog'/1e9, "%14.3fc"))', D.759 `=strtrim(string(`OtrasTransfHog'/1e9, "%14.3fc"))')"
noisily _log linea "τ⁺ efectivo: factor `=strtrim(string(`fTau', "%7.4f"))' (nta_anclaTau $nta_anclaTau)"
quietly tabstat YA_d8 [fw=factor], stat(sum) save
escalar mxn NTAD8Nac = r(StatTotal)[1,1]
noisily _log linea "D.8 AjustePension `=strtrim(string(`AjustePension'/1e9, "%14.3fc"))' bn → YA_d8 ($nta_d8; `Ncotiz' personas con cuotas > 0): Σ `=strtrim(string(r(StatTotal)[1,1]/1e9, "%14.3fc"))' bn"
noisily _log linea "S micro sin ajuste `=strtrim(string(`S_micro'/1e9, "%14.3fc"))' bn vs B.8n S.14 `=strtrim(string(`AhorroHog'/1e9, "%14.3fc"))'; factor implícito `=strtrim(string(`fS', "%8.4f"))'; brecha `=strtrim(string(scalar(NTABrechaSPct), "%7.1f"))' %"
noisily _log linea "nta_anclaS = $nta_anclaS (parámetro $nta_anclaS_param); Σ S_ajuste `=strtrim(string(scalar(NTASAjusteNac)/1e9, "%14.3fc"))' bn"



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
	tabstat Intra S Cpriv Cpub YL YA Tmen TpubEf InterRec Remesas InterOtor YA_ajuste CpubInd CpubCol S_hh S_ret S_def S_isflsh OtrosRec OtrosOtor YA_ret TmenRet TmenDef TpubISFLSH TmenD59 [fw=factor], stat(sum) save
	tempname TOT
	matrix `TOT' = r(StatTotal)
}
local Intra_nac = `TOT'[1,1]
local S_pers = `TOT'[1,2]
local S_nac = `TOT'[1,15]
escalar mxn NTAIntraNac = `Intra_nac'
escalar mxn NTASNac = `S_nac'
escalar mxn NTASPersonasNac = `S_pers'
escalar mxn NTASRetNac = `TOT'[1,16]
escalar mxn NTASDefNac = `TOT'[1,17]
escalar mxn NTASISFLSHNac = `TOT'[1,18]
escalar mxn NTAOtrosRecNac = `TOT'[1,19]
escalar mxn NTAOtrosOtorNac = `TOT'[1,20]
escalar mxn NTAYARetNac = `TOT'[1,21]
escalar mxn NTATmenRetNac = `TOT'[1,22]
escalar mxn NTATmenDefNac = `TOT'[1,23]
escalar mxn NTATpubISFLSHNac = `TOT'[1,24]
escalar mxn NTAD59Nac = `TOT'[1,25]
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
	noisily _log aviso, tipo(GATE) texto("NTA: residual por persona máximo `=strtrim(string(`maxres', "%12.4f"))' MXN (relativo al C per cápita `=strtrim(string(`maxres'/`Cpc', "%9.2e"))')") rojo
}
if abs(`Intra_nac')/`Ctot' > `tol' {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA: Σ intra-hogar nacional `=strtrim(string(`Intra_nac', "%16.2f"))' MXN (relativo a C `=strtrim(string(abs(`Intra_nac')/`Ctot', "%9.2e"))')") rojo
}
if "$nta_anclaS" != "off" & reldif(`S_nac', `AhorroHog') > `tol' {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA: Σ S_hh `=strtrim(string(`S_nac'/1e9, "%14.3fc"))' bn ≠ AhorroHog B.8n `=strtrim(string(`AhorroHog'/1e9, "%14.3fc"))' bn") rojo
}
* 8.17 (prompt Bloque 3): Σ S de las personas = B.8n S.1 con los defaults firmados (retenido on, deficit ≠ off, ISFLSH per capita, ancla ≠ off) *
local S_pers_esp = .
if "$retenido_a_personas" == "on" & "$deficit_a_personas" != "off" & "$nta_anclaS" != "off" & `B8nS1' < . local S_pers_esp = `B8nS1'
if `S_pers_esp' < . & reldif(`S_pers', `S_pers_esp') > `tol' {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA 8.17: Σ S de las personas `=strtrim(string(`S_pers'/1e9, "%14.3fc"))' bn ≠ B.8n S.1 `=strtrim(string(`S_pers_esp'/1e9, "%14.3fc"))' bn") rojo
}
noisily _log aviso, tipo(GATE) texto("NTA: residual por persona máx `=strtrim(string(`maxres', "%9.2e"))'; Σ intra por hogar máx `=strtrim(string(`maxintra_hog', "%9.2e"))'; Σ intra nacional `=strtrim(string(`Intra_nac', "%12.2f"))' → `=cond(`ok', "OK", "ROJO")'")
noisily _log aviso, tipo(GATE) texto("NTA: Σ S_hh `=strtrim(string(`S_nac'/1e9, "%14.3fc"))' bn; Σ S personas `=strtrim(string(`S_pers'/1e9, "%14.3fc"))' bn vs B.8n S.1 `=strtrim(string(`B8nS1'/1e9, "%14.3fc"))' → `=cond(`ok', "OK", "ROJO")'")
* 8.16b: gates de Cuadratura II (1e-9 relativo; CUAD-1 §7): Σ Cpriv = P.3 S.14; Σ ISR de personas = D.51 S.14; Σ ISR PM = D.51 S.11 + S.12;
* Σ cuotas = D.61 por sector receptor; Σ IEPS repartido = LIF por tipo. Al estandar §D (_tabla_anclas.ado v2). *
quietly tabstat Cpriv nta_ISRAS nta_ISRPF nta_ISRPM nta_CUOTAS nta_IEPSNP nta_IEPSP [fw=factor], stat(sum) save
tempname C2
matrix `C2' = r(StatTotal)
escalar mxn NTAISRPersonasNac = `C2'[1,2] + `C2'[1,3]
escalar mxn NTAISRPMNac = `C2'[1,4]
_tabla_anclas clear
if "$consumo_ancla" == "p3_s14" _tabla_anclas gate, texto("Σ Cpriv = P.3 S.14 (consumo_ancla = p3_s14)") a(`C2'[1,1]) b(`ConHogS14')
if "$isr_personas_ancla" == "d51_s14" {
	_tabla_anclas gate, texto("Σ ISR de personas (asalariados + PF) = D.51 S.14") a(`C2'[1,2] + `C2'[1,3]) b(`D51HogS14')
	_tabla_anclas gate, texto("Σ ISR PM (informativo, fuera de τ⁻) = D.51 S.11 + S.12") a(`C2'[1,4]) b(`D51NoFin' + `D51Fin')
}
if "$cuotas_por_sector" == "on" & "$nta_cuotas" == "S14" {
	quietly tabstat nta_CUOTAS_S13 nta_CUOTAS_S12 nta_CUOTAS_S11 nta_CUOTAS_S15 [fw=factor], stat(sum) save
	tempname CS
	matrix `CS' = r(StatTotal)
	_tabla_anclas gate, texto("Σ cuotas a S.13 (gobierno general: IMSS, ISSSTE) = D.61 recibido S.13") a(`CS'[1,1]) b(`CuotasGobR')
	_tabla_anclas gate, texto("Σ cuotas a S.12 (Afores, vivienda, aseguradoras) = D.61 recibido S.12 − D.614") a(`CS'[1,2]) b(`CuotasS12n')
	_tabla_anclas gate, texto("Σ cuotas a S.11 (planes de empleadores) = D.61 recibido S.11") a(`CS'[1,3]) b(`CuotasNoFinR')
	_tabla_anclas gate, texto("Σ cuotas a S.15 (ISFLSH) = D.61 recibido S.15") a(`CS'[1,4]) b(`CuotasISFLSHR')
	_tabla_anclas gate, texto("Σ cuotas por sector = D.61 − D.614 pagado por S.14 (redondeo de los cuadros CSI)") a(`C2'[1,5]) b(`CuotasHogS14') tol(1e-6)
	escalar mxn NTACuotasS13Nac = `CS'[1,1]
	escalar mxn NTACuotasS12Nac = `CS'[1,2]
	escalar mxn NTACuotasS11Nac = `CS'[1,3]
	escalar mxn NTACuotasS15Nac = `CS'[1,4]
}
_tabla_anclas gate, texto("Σ IEPS no petrolero repartido (∝ `rel_iepsnp') = LIF IEPSNP") a(`C2'[1,6]) b(`IEPSNP')
_tabla_anclas gate, texto("Σ IEPS petrolero repartido (∝ `rel_iepsp') = LIF IEPSP") a(`C2'[1,7]) b(`IEPSP')
* 8.17 (CUAD-2 §7): anclas por sector de la fila τ y de lo atribuido *
if "$hub" == "inbd" {
	_tabla_anclas gate, texto("Σ ISR personas + D.59 = D.5 S.14 (f.114)") a(`=scalar(NTAISRPersonasNac) + scalar(NTAD59Nac)') b(`ImpIngHog')
	_tabla_anclas gate, texto("Σ D.7 pagada a otros sectores (D.751 + D.71 + D.752 + D.759) = D.7 S.14 U/A (f.139)") a(scalar(NTAOtrosOtorNac)) b(`OtrasTransfHogU')
	_tabla_anclas gate, texto("Σ indemnizaciones recibidas = D.72 S.14 (f.143)") a(scalar(NTAOtrosRecNac)) b(`D72HogR')
	_tabla_anclas gate, texto("Σ CpubCol = P.32 S.13 (f.168)") a(`TOT'[1,14]) b(`P32Gob')
	if "$retenido_a_personas" == "on" _tabla_anclas gate, texto("Σ YA_ret = B.5n S.11 + S.12; Σ S_ret = B.8n S.11 + S.12") a(scalar(NTAYARetNac) - scalar(NTASRetNac)) b(`=`B5nNoFin' + `B5nFin' - `B8nNoFin' - `B8nFin'')
	if "$deficit_a_personas" != "off" _tabla_anclas gate, texto("Σ S_def = B.8n S.13 (deficit_a_personas = $deficit_a_personas)") a(scalar(NTASDefNac)) b(`B8nGob')
	_tabla_anclas gate, texto("Σ S_isflsh = B.8n S.15") a(scalar(NTASISFLSHNac)) b(`B8nISFLSH')
}
noisily _tabla_anclas print, titulo("Gates de Cuadratura II, NTA `anio'") unidad("MXN `anio'") ref("CUAD-1 §7; CUAD-2 §7")
if "$TA_GATES_OK" != "1" {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA Cuadratura II: algún ancla de CUAD-1 no cierra (ver los gates de arriba)") rojo
}
noisily _log linea "ConGob partido (bn): individual D.63 Σ `=strtrim(string(`TOT'[1,13]/1e9, "%14.3fc"))' vs TransfEspecie `=strtrim(string(`TransfEspecie'/1e9, "%14.3fc"))' (reldif `=strtrim(string(reldif(`TOT'[1,13], `TransfEspecie'), "%9.2e"))')"
noisily _log linea "ConGob partido (bn): colectivo ConGob − D.63 Σ `=strtrim(string(`TOT'[1,14]/1e9, "%14.3fc"))'; Σ Cpub `=strtrim(string(`TOT'[1,4]/1e9, "%14.3fc"))'"



**********************************
**# 6. Agregados: grupo de edad (escalares) y quinquenio × sexo
**********************************
local vars "C Cpriv Cpub CpubInd CpubCol CpubEduc CpubSalud CpubRestoInd YL ImpProd YA YA_base YA_motor YA_d8 YA_ajuste S S_sinancla S_ajuste Tpub TpubEf TpubEsp TpubCol TpubPens TpubPAM TpubProg Tmen TmenDir TmenCuotas TmenInd TmenFuera InterRec Remesas InterOtor Intra Resid ALQ"
* 8.17: la cuenta del hogar (hh) y lo atribuido de los otros sectores, la fila τ por sector *
local vars "`vars' YA_hh YA_ret S_hh S_ret S_def S_isflsh Tmen_hh TmenRet TmenDef TmenDefTau TmenD59 TpubISFLSH TpubEfPub TpubEfPriv OtrosRec OtrosOtor RecIndem OtorISFLSH OtorPrimas OtorRemEnv OtorD759"
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
	g double resid_chk = C - YL - ImpProd - (Tpub + InterRec + OtrosRec + Remesas - Tmen - InterOtor - OtrosOtor) - (YA - YA_ajuste - S_sinancla - S_ret - S_def - S_isflsh) - Intra
	summarize resid_chk, meanonly
	local maxres_qs = max(abs(r(min)), abs(r(max)))
	tempfile qs
	save `qs'
}
restore
if `maxres_qs'/`Ctot' > `tol' {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA: residual por quinquenio × sexo máx `=strtrim(string(`maxres_qs', "%12.2f"))' MXN") rojo
}
escalar mxn NTAResidMaxQS = `maxres_qs'
escalar mxn NTAResidMaxPersona = `maxres'

* 6.1 Tabla de identidad (texto; bn MXN). 8.16b: al estandar de la firma CUAD-1-2 §D (columnas de ancho fijo, separador de miles, notas al pie
* «^n» / «Nota n:» para todo parametro o comentario, gates debajo de cada cuadro). Abre con Σ S micro sin ajuste por grupo vs B.8n. *
local f1 "%11.1fc"
local okstr = cond(`ok', "OK", "ROJO")
local raya = 110*"─"
tempname fh
file open `fh' using `"`dirnta'/nta-identidad.txt"', write replace text
file write `fh' "NTA `anio' — cuenta de Transferencias Nacionales por individuo: identidad, anclas S.14 y descomposición de la brecha de S (miles de millones de MXN corrientes de `anio'; sumas [fw=factor])" _n
file write `fh' "`raya'" _n
file write `fh' "Cuadro 1. Σ S micro (residual de los hogares, sin ajuste) por grupo de edad vs B.8n S.14, y el ahorro de las personas con lo atribuido de los otros sectores vs B.8n S.1^1^2" _n
file write `fh' "`raya'" _n
file write `fh' %-12s ("Grupo") %9s ("Pob (M)") %11s ("S sin aj.") %11s ("S hogar") %11s ("Ajuste") %11s ("S retenido") %11s ("S déficit") %11s ("S ISFLSH") %11s ("S persona") %11s ("déf∝τ⁻") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTAS_sinancla`g')/1e9) `f1' (scalar(NTAS_hh`g')/1e9) `f1' ((scalar(NTAS_hh`g') - scalar(NTAS_sinancla`g'))/1e9) `f1' (scalar(NTAS_ret`g')/1e9) `f1' (scalar(NTAS_def`g')/1e9) `f1' (scalar(NTAS_isflsh`g')/1e9) `f1' (scalar(NTAS`g')/1e9) `f1' (-scalar(NTATmenDefTau`g')/1e9) _n
}
file write `fh' "`raya'" _n
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTAS_sinancla0)/1e9) `f1' (scalar(NTAS_hh0)/1e9) `f1' ((scalar(NTAS_hh0) - scalar(NTAS_sinancla0))/1e9) `f1' (scalar(NTAS_ret0)/1e9) `f1' (scalar(NTAS_def0)/1e9) `f1' (scalar(NTAS_isflsh0)/1e9) `f1' (scalar(NTAS0)/1e9) `f1' (-scalar(NTATmenDefTau0)/1e9) _n
file write `fh' %-12s ("CSI") %9s ("") %11s ("") `f1' (`AhorroHog'/1e9) %11s ("") `f1' ((`B8nNoFin' + `B8nFin')/1e9) `f1' (`B8nGob'/1e9) `f1' (`B8nISFLSH'/1e9) `f1' (`B8nS1'/1e9) `f1' (`B8nGob'/1e9) _n
file write `fh' %-12s ("Celda") %9s ("") %11s ("") %11s ("B.8n S.14") %11s ("") %11s ("B.8n S11S12") %11s ("B.8n S.13") %11s ("B.8n S.15") %11s ("B.8n S.1") %11s ("B.8n S.13") _n
file write `fh' "`raya'" _n
file write `fh' "Nota 1: factor implícito B.8n S.14 / Σ S sin ajuste " %8.4f (`fS') "; brecha (Σ S − B.8n) / B.8n " %7.1f (scalar(NTABrechaSPct)) " % (esperada tras 8.17 " %5.1f (`brecha_esp') " %); ajuste aditivo que exigiría el ancla " `f1' (`D'/1e9) " bn; nta_anclaS = $nta_anclaS (parámetro $nta_anclaS_param; auto = multiplicativo si |brecha| ≤ `brecha_max' %). S persona = S hogar + retenido (B.5n − TmenRet de S.11 + S.12 ∝ ing_d4_rel; retenido_a_personas = $retenido_a_personas, regla P, sello rojo) + déficit (−B.8n S.13 por igual a cada persona; deficit_a_personas = $deficit_a_personas) + ISFLSH (B.8n S.15 per cápita); Σ S persona " `f1' (scalar(NTASPersonasNac)/1e9) " vs B.8n S.1 " `f1' (`B8nS1'/1e9) " (con retenido y déficit en off sería B.8n S.14 " `f1' (`AhorroHog'/1e9) "). La columna déf. ∝ τ⁻ es la alternativa tau_menos (firma §B 18), medida: el déficit repartido ∝ τ⁻ del hogar." _n
file write `fh' "Nota 2: YA del motor " `f1' (`YA_motor_tot'/1e9) " vs YAHogS14 = B.2n " `f1' (`ExNOpHogS14'/1e9) " + 1/3 B.3n " `f1' (`MixNHogS14'/3e9) " + D.4 neto " `f1' (`RentaPropHogNeta'/1e9) " = " `f1' (`YAHogS14'/1e9) " − D.442 − 2/3 D.422 (ing_mixto_ancla = $ing_mixto_ancla) " `f1' ((`YAHogS14' - `YAHogS14n')/1e9) " = ancla " `f1' (`YAHogS14n'/1e9) "; factor " %8.6f (`fYA') " (debe ser 1 desde v8.15b); nta_YA = $nta_YA; Σ YA_base " `f1' (scalar(NTAYABaseNac)/1e9) ". Por decil (motor → re-anclado):"
forvalues d = 1/10 {
	file write `fh' " D`d' " %7.1fc (scalar(NTAYAMotorD`d')/1e9) " → " %7.1fc (scalar(NTAYABaseD`d')/1e9)
}
file write `fh' "." _n
file write `fh' "Nota 3: parámetros de Households (CUAD-0 firma 2026-10-31 y CUAD-1 firma 2026-11-07; FLAG si difieren del firmado):$cuad_params." _n
file write `fh' "Nota 4: parámetros de NTA: nta_anclaS = $nta_anclaS, nta_YA = $nta_YA, nta_cuotas = $nta_cuotas, nta_d8 = $nta_d8, nta_anclaTau = $nta_anclaTau, nta_alqu = $nta_alqu, nta_tauCash = $nta_tauCash, nta_otorgado = $nta_otorgado, nta_mixto = $nta_mixto." _n _n
file write `fh' "`raya'" _n
* log legible (2026-11-09): el cuadro 2 se parte en 2a (consumo e ingreso), 2b (τ⁻) y 2c (τ⁺, transferencias privadas, intra y R) para
* caber en 110 columnas; mismos escalares, mismos formatos, misma precisión. *
file write `fh' "Cuadro 2a. Identidad por grupo de edad sin ancla, consumo e ingreso: C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − YA_ajuste − S sin ancla) − intra = R^5^6" _n
file write `fh' "`raya'" _n
file write `fh' %-12s ("Grupo") %9s ("Pob (M)") %11s ("Cpriv") %11s ("Cpub") %11s ("C") %11s ("YL") %11s ("ImpProd") %11s ("YA") %11s ("YA D.8") %11s ("S") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTACpriv`g')/1e9) `f1' (scalar(NTACpub`g')/1e9) `f1' (scalar(NTAC`g')/1e9) ///
		`f1' (scalar(NTAYL`g')/1e9) `f1' (scalar(NTAImpProd`g')/1e9) `f1' (scalar(NTAYA`g')/1e9) `f1' (scalar(NTAYA_d8`g')/1e9) `f1' (scalar(NTAS`g')/1e9) _n
}
file write `fh' "`raya'" _n
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTACpriv0)/1e9) `f1' (scalar(NTACpub0)/1e9) `f1' (scalar(NTAC0)/1e9) ///
	`f1' (scalar(NTAYL0)/1e9) `f1' (scalar(NTAImpProd0)/1e9) `f1' (scalar(NTAYA0)/1e9) `f1' (scalar(NTAYA_d80)/1e9) `f1' (scalar(NTAS0)/1e9) _n
file write `fh' "`raya'" _n
file write `fh' "Cuadro 2b. Identidad por grupo de edad: τ⁻ público y sus partes" _n
file write `fh' "`raya'" _n
file write `fh' %-12s ("Grupo") %9s ("Pob (M)") %11s ("τ⁻ púb.") %11s ("cuotas") %11s ("indirectos") %11s ("fuera τ⁻") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTATmen`g')/1e9) `f1' (scalar(NTATmenCuotas`g')/1e9) `f1' (scalar(NTATmenInd`g')/1e9) `f1' (scalar(NTATmenFuera`g')/1e9) _n
}
file write `fh' "`raya'" _n
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTATmen0)/1e9) `f1' (scalar(NTATmenCuotas0)/1e9) `f1' (scalar(NTATmenInd0)/1e9) `f1' (scalar(NTATmenFuera0)/1e9) _n
file write `fh' "`raya'" _n
file write `fh' "Cuadro 2c. Identidad por grupo de edad: τ⁺ público, transferencias privadas, intra-hogar y residual R" _n
file write `fh' "`raya'" _n
file write `fh' %-12s ("Grupo") %9s ("Pob (M)") %11s ("τ⁺ efect.") %11s ("τ⁺ esp.") %11s ("τ⁺ colec.") %11s ("inter rec.") %11s ("remesas") %11s ("inter otor.") %11s ("intra") %11s ("R") _n
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' %-12s ("`lab'") %9.1f (scalar(NTAPob`g')/1e6) `f1' (scalar(NTATpubEf`g')/1e9) `f1' (scalar(NTATpubEsp`g')/1e9) `f1' (scalar(NTATpubCol`g')/1e9) `f1' (scalar(NTAInterRec`g')/1e9) `f1' (scalar(NTARemesas`g')/1e9) ///
		`f1' (scalar(NTAInterOtor`g')/1e9) `f1' (scalar(NTAIntra`g')/1e9) %11.6f (scalar(NTAResid`g')/1e9) _n
}
file write `fh' "`raya'" _n
file write `fh' %-12s ("Total") %9.1f (scalar(NTAPob0)/1e6) `f1' (scalar(NTATpubEf0)/1e9) `f1' (scalar(NTATpubEsp0)/1e9) `f1' (scalar(NTATpubCol0)/1e9) `f1' (scalar(NTAInterRec0)/1e9) `f1' (scalar(NTARemesas0)/1e9) ///
	`f1' (scalar(NTAInterOtor0)/1e9) `f1' (scalar(NTAIntra0)/1e9) %11.6f (scalar(NTAResid0)/1e9) _n
file write `fh' "`raya'" _n
file write `fh' "Nota 5: con el ancla multiplicativa la diferencia S − S sin ancla queda declarada en la columna Ajuste del cuadro 1, no en la identidad. ImpProd = impuestos netos a los productos como ingreso ∝ Cpriv. τ⁺ = público efectivo + público en especie (individual, D.63) + público colectivo (ConGob − D.63) + inter-hogar recibido + remesas; τ⁻ público = ISR de personas (asalariados + PF; ancla $isr_personas_ancla) + cuotas ($nta_cuotas; por sector receptor: cuotas_por_sector = $cuotas_por_sector) + indirectos LIF (IEPS ∝ `rel_iepsnp' / `rel_iepsp'); fuera de τ⁻ (informativo): ISR PM (ancla $isr_personas_ancla) + OTROSK." _n
file write `fh' "Nota 6: S e intra-hogar por sexo: hombres S " `f1' (scalar(NTASH)/1e9) ", intra " `f1' (scalar(NTAIntraH)/1e9) "; mujeres S " `f1' (scalar(NTASM)/1e9) ", intra " `f1' (scalar(NTAIntraM)/1e9) ". Impuestos a productos: ImpNetosProd (D.21 − D.31) " `f1' (`ImpNetosProd'/1e9) ", ImpNet BIE " `f1' (`ImpNetBIE'/1e9) ", embebido por Altimir (sacado) " `f1' (scalar(NTAImpProdMotor)/1e9) " = de YA " `f1' (scalar(NTAImpProdMotorYA)/1e9) " + de YL " `f1' (scalar(NTAImpProdMotorYL)/1e9) "; Σ indirectos micro τ⁻ " `f1' (scalar(NTATmenInd0)/1e9) " (factor " %7.4f (scalar(NTAFactorIndirectos)/100) "). τ⁺ efectivo PEF/ENIGH " `f1' (`TpubEf_pre'/1e9) " vs D.62 + D.759 S.14 " `f1' (`TauPubS14'/1e9) " (D.62 " `f1' (`PrestSocHog'/1e9) ", D.759 " `f1' (`OtrasTransfHog'/1e9) "), factor " %7.4f (`fTau') ", nta_anclaTau = $nta_anclaTau, Σ final " `f1' (scalar(NTATpubEf0)/1e9) ". D.8 AjustePension " `f1' (`AjustePension'/1e9) " → YA_d8 ($nta_d8) Σ " `f1' (scalar(NTAD8Nac)/1e9) ". ConGob partido: individual (D.63) Σ " `f1' (scalar(NTACpubIndNac)/1e9) " vs TransfEspecie " `f1' (`TransfEspecie'/1e9) " (educación " `f1' (scalar(NTACpubEduc0)/1e9) ", salud " `f1' (scalar(NTACpubSalud0)/1e9) ", resto individual per cápita " `f1' (scalar(NTACpubRestoInd0)/1e9) "); colectivo (ConGob − D.63, per cápita) Σ " `f1' (scalar(NTACpubColNac)/1e9) "; ConGob " `f1' (`ConGob'/1e9) ". Σ Cpriv " `f1' (scalar(NTACprivNac)/1e9) " vs P.3 S.14 " `f1' (`ConHogS14'/1e9) "; ConHog BIE " `f1' (`ConHog'/1e9) "; compras netas " `f1' (`ComprasN'/1e9) "; P.3 S.15 " `f1' (`ConISFLSH'/1e9) "." _n
file write `fh' %-62s ("GATE 1e-9  residual máximo por persona (MXN)") %21.2e (`maxres') _n
file write `fh' %-62s ("GATE 1e-9  Σ intra-hogar nacional (MXN)") %21.2fc (`Intra_nac') _n
file write `fh' %-62s ("GATE 1e-9  Σ S − B.8n S.14 con ancla (MXN)") %21.2fc (`S_nac' - `AhorroHog') _n
if "$consumo_ancla" == "p3_s14" file write `fh' %-62s ("GATE 1e-9  Σ Cpriv − P.3 S.14 (MXN)") %21.2fc (scalar(NTACprivNac) - `ConHogS14') _n
if "$isr_personas_ancla" == "d51_s14" file write `fh' %-62s ("GATE 1e-9  Σ ISR de personas − D.51 S.14 (MXN)") %21.2fc (scalar(NTAISRPersonasNac) - `D51HogS14') _n
if "$isr_personas_ancla" == "d51_s14" file write `fh' %-62s ("GATE 1e-9  Σ ISR PM − D.51 S.11 + S.12 (MXN)") %21.2fc (scalar(NTAISRPMNac) - `D51NoFin' - `D51Fin') _n
if "$cuotas_por_sector" == "on" & "$nta_cuotas" == "S14" {
	file write `fh' %-62s ("GATE 1e-9  Σ cuotas a S.13 − D.61 receptor S.13 (MXN)") %21.2fc (scalar(NTACuotasS13Nac) - `CuotasGobR') _n
	file write `fh' %-62s ("GATE 1e-9  Σ cuotas a S.12 − D.61 receptor S.12 − D.614 (MXN)") %21.2fc (scalar(NTACuotasS12Nac) - `CuotasS12n') _n
	file write `fh' %-62s ("GATE 1e-9  Σ cuotas a S.11 − D.61 receptor S.11 (MXN)") %21.2fc (scalar(NTACuotasS11Nac) - `CuotasNoFinR') _n
	file write `fh' %-62s ("GATE 1e-9  Σ cuotas a S.15 − D.61 receptor S.15 (MXN)") %21.2fc (scalar(NTACuotasS15Nac) - `CuotasISFLSHR') _n
}
file write `fh' %-62s ("RESULTADO de los gates") %21s ("`okstr'") _n
* v8.15b: «De dónde sale la brecha» (CUAD-0 Δ esperado): Σ S sin ancla − B.8n partida por partida, NTA vs S.14 (bn) *
quietly tabstat YL YA_base YA_d8 ImpProd TmenInd nta_ISRAS nta_ISRPF nta_CUOTAS TpubEf InterRec Remesas InterOtor Cpriv CpubInd CpubCol TpubEsp TpubCol nta_ISRPM TmenD59 OtrosRec OtrosOtor [fw=factor], stat(sum) save
tempname BR
matrix `BR' = r(StatTotal)
local b_prim = (`BR'[1,1] + `BR'[1,2]) - `YAHogS14n' - `D1HogS14' - (`MixNHogS14' + `D422m')*2/3
local b_d8 = `BR'[1,3] - `AjustePension'
local b_impprod = `BR'[1,4] - `BR'[1,5]
local b_d5 = -(`BR'[1,6] + `BR'[1,7] + `BR'[1,19]) + `ImpIngHog'
local b_d61 = -`BR'[1,8] + `CuotasHogS14'
local b_tau = (`BR'[1,9] + `BR'[1,10] + `BR'[1,11] + `BR'[1,20] - `BR'[1,12] - `BR'[1,21]) - (`TauPubS14' + `OtrasTransfHogR' - `OtrasTransfHog' - `OtrasTransfHogU')
local b_cpriv = -`BR'[1,13] + `ConHogS14'
local b_cpub = (`BR'[1,16] + `BR'[1,17]) - (`BR'[1,14] + `BR'[1,15])
local b_tot = `b_prim' + `b_d8' + `b_impprod' + `b_d5' + `b_d61' + `b_tau' + `b_cpriv' + `b_cpub'
escalar mxn NTABrechaD5 = `b_d5'
escalar mxn NTABrechaTau = `b_tau'
escalar mxn NTABrechaCprivS = `b_cpriv'
escalar mxn NTABrechaImpProd = `b_impprod'
file write `fh' _n "`raya'" _n
file write `fh' "Cuadro 3. De dónde sale la brecha: Σ S sin ancla − B.8n = " %11.1fc ((`S_micro' - `AhorroHog')/1e9) " bn; partida de la cuenta NTA vs celda S.14 y efecto en S^7" _n
file write `fh' "`raya'" _n
file write `fh' %-66s ("Partida") %-10s ("Código") %11s ("NTA") %11s ("S.14") %11s ("Efecto en S") _n
file write `fh' %-66s ("YL + YA base vs D.1 + B.3n + D.422 + B.2n + D.4 neto − D.442 − D.422") %-10s ("B.5n") `f1' ((`BR'[1,1] + `BR'[1,2])/1e9) `f1' ((`YAHogS14n' + `D1HogS14' + (`MixNHogS14' + `D422m')*2/3)/1e9) `f1' (`b_prim'/1e9) _n
file write `fh' %-66s ("Ajuste por cambio en los derechos de pensiones: YA D.8 vs celda") %-10s ("D.8") `f1' (`BR'[1,3]/1e9) `f1' (`AjustePension'/1e9) `f1' (`b_d8'/1e9) _n
file write `fh' %-66s ("Impuestos netos a los productos como ingreso vs τ⁻ indirectos LIF") %-10s ("D.21−D.31") `f1' (`BR'[1,4]/1e9) `f1' (`BR'[1,5]/1e9) `f1' (`b_impprod'/1e9) _n
file write `fh' %-66s ("ISR de personas + D.59 vs D.5 S.14; ancla $isr_personas_ancla") %-10s ("D.5") `f1' ((`BR'[1,6] + `BR'[1,7] + `BR'[1,19])/1e9) `f1' (`ImpIngHog'/1e9) `f1' (`b_d5'/1e9) _n
file write `fh' %-66s ("Contribuciones sociales netas: cuotas vs D.61 − D.614 S.14") %-10s ("D.61") `f1' (`BR'[1,8]/1e9) `f1' (`CuotasHogS14'/1e9) `f1' (`b_d61'/1e9) _n
file write `fh' %-66s ("Transferencias netas recibidas − otorgadas vs D.62 + D.7 netas") %-10s ("D.62+D.7") `f1' ((`BR'[1,9] + `BR'[1,10] + `BR'[1,11] + `BR'[1,20] - `BR'[1,12] - `BR'[1,21])/1e9) `f1' ((`TauPubS14' + `OtrasTransfHogR' - `OtrasTransfHog' - `OtrasTransfHogU')/1e9) `f1' (`b_tau'/1e9) _n
file write `fh' %-66s ("Gasto de consumo final: Cpriv vs P.3 S.14") %-10s ("P.3") `f1' (`BR'[1,13]/1e9) `f1' (`ConHogS14'/1e9) `f1' (`b_cpriv'/1e9) _n
file write `fh' %-66s ("Consumo público: τ⁺ especie + colectivo vs Cpub, neutro") %-10s ("D.63+P.32") `f1' ((`BR'[1,16] + `BR'[1,17])/1e9) `f1' ((`BR'[1,14] + `BR'[1,15])/1e9) `f1' (`b_cpub'/1e9) _n
file write `fh' "`raya'" _n
file write `fh' %-66s ("Total (debe igualar la brecha)") %-10s ("") %11s ("") %11s ("") `f1' (`b_tot'/1e9) _n
file write `fh' "`raya'" _n
file write `fh' "Nota 7: brecha observada " %6.1f (`brecha') " % de B.8n; esperada tras 8.17 (CUAD-1 §7, CUAD-2 §7) " %5.1f (`brecha_esp') " %: la fila LIF vs devengado de los impuestos a productos (ImpProd − τ⁻ indirectos) más el vintage de las remesas (D.752 CSI " `f1' (`RemesasHogS14'/1e9) " vs ROWTrans BIE " `f1' (`ROWTrans'/1e9) "). Fila τ cerrada en 8.17 por sector: D.72 recibidas " `f1' (`BR'[1,20]/1e9) "; D.7 pagada a otros sectores " `f1' (`BR'[1,21]/1e9) " = donativos a ISFLSH " `f1' (scalar(NTAOtorISFLSH0)/1e9) " (ENIGH 173417 × factor, FLAG 35) + primas netas " `f1' (scalar(NTAOtorPrimas0)/1e9) " + remesas enviadas " `f1' (scalar(NTAOtorRemEnv0)/1e9) " (FLAG 36) + D.759 " `f1' (scalar(NTAOtorD7590)/1e9) " (receptor por identificar); inter-hogar otorgado × " %7.4f (scalar(NTAFactorInter)/100) " = recibido (inter_hogar = $inter_hogar). LIF vs CSI por sector: ISR de personas LIF (asalariados + PF) " `f1' ((`ISRAS' + `ISRPF')/1e9) " vs D.51 S.14 " `f1' (`D51HogS14'/1e9) " (" `f1' ((`ISRAS' + `ISRPF' - `D51HogS14')/1e9) "); ISR PM LIF " `f1' (`ISRPM'/1e9) " vs D.51 S.11 + S.12 " `f1' ((`D51NoFin' + `D51Fin')/1e9) " (" `f1' ((`ISRPM' - `D51NoFin' - `D51Fin')/1e9) "): la LIF clasifica por quien entera y la CSI por quien soporta; ISR total LIF " `f1' ((`ISRAS' + `ISRPF' + `ISRPM')/1e9) " vs D.51 S.14 + S.11 + S.12 " `f1' ((`D51HogS14' + `D51NoFin' + `D51Fin')/1e9) ". D.5 − D.51 = D.59 (predial y tenencia, fuera del consumo desde 8.16b)." _n
file close `fh'

* 6.2 JSON por grupo de edad *
local q = char(34)
local fecha : di %tdCCYY-NN-DD date("$S_DATE", "DMY")
local fm "%20.4f"
file open `fh' using `"`dirnta'/nta-grupoedad.json"', write replace text
file write `fh' `"{"esquema":"nta/v1","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"grupoedad","' _n
file write `fh' `""identidad":"C - YL - ImpProd - (tau_mas - tau_menos) - (YA - YA_ajuste - S_sinancla) - intra = 0 (sin ancla); con ancla multiplicativa el residual declarado es S_ajuste = S - S_sinancla; ImpProd = impuestos netos a los productos como ingreso (∝ Cpriv); tau_mas = tau_pub_efectivo + tau_pub_especie (individual D.63) + tau_pub_colectivo (ConGob - D.63) + inter_recibido + remesas; tau_menos = tau_pub + inter_otorgado","' _n
file write `fh' `""parametros":{"nta_anclaS":"$nta_anclaS","nta_anclaS_param":"$nta_anclaS_param","nta_YA":"$nta_YA","nta_cuotas":"$nta_cuotas","nta_d8":"$nta_d8","nta_anclaTau":"$nta_anclaTau","nta_alqu":"$nta_alqu","nta_tauCash":"$nta_tauCash","nta_otorgado":"$nta_otorgado","nta_mixto":"$nta_mixto","hub":"$hub","retenido_a_personas":"$retenido_a_personas","deficit_a_personas":"$deficit_a_personas","isflsh_regla":"$isflsh_regla","circuito_d442":"$circuito_d442","vintage_nodo":"$vintage_nodo","bruto_neto":"$bruto_neto","financiamiento":"$financiamiento","discrepancia_gasto":"$discrepancia_gasto","inter_hogar":"$inter_hogar","households":"`=trim("$cuad_params")'","adulto":`adulto',"tolerancia":1e-9},"' _n
file write `fh' `""sectores":{"IngDisp_INBD":`=trim(string(`IngDisp', "`fm'"))',"B5nS1":`=trim(string(`B5nS1', "`fm'"))',"B6nS1":`=trim(string(`B6nS1', "`fm'"))',"B5nS11S12":`=trim(string(cond(`B5nNoFin' < ., `B5nNoFin' + `B5nFin', .), "`fm'"))',"B5nS13":`=trim(string(`B5nGob', "`fm'"))',"B5nS15":`=trim(string(`B5nISFLSH', "`fm'"))',"VintageNNI":`=trim(string(`VintageNNI', "`fm'"))',"P32S13":`=trim(string(`P32Gob', "`fm'"))',"D72S14":`=trim(string(`D72HogR', "`fm'"))',"D7pagadaS14":`=trim(string(`OtrasTransfHogU', "`fm'"))',"D59S14":`=trim(string(`D59Hog', "`fm'"))',"B9Row":`=trim(string(`B9Row', "`fm'"))',"factor_inter_hogar":`=trim(string(scalar(NTAFactorInter)/100, "%12.8f"))',"factor_donativos_isflsh":`=cond(`fDona' < ., trim(string(`fDona', "%12.8f")), "null")',"regla":"celdas CSI por sector (SCN.ado SCNSectores; CUAD-2 §6.4) que el Sankey v4 y las atribuciones a personas usan; hub = INBD BIE 724037 − CCF"},"' _n
file write `fh' `""anclas":{"AhorroHog_B8n":`=trim(string(`AhorroHog', "`fm'"))',"AhorroHogB_B8b":`=trim(string(`AhorroHogB', "`fm'"))',"TransfEspecie_D63":`=trim(string(`TransfEspecie', "`fm'"))',"ConHogS14_P3":`=trim(string(`ConHogS14', "`fm'"))',"ConHog":`=trim(string(`ConHog', "`fm'"))',"ConGob":`=trim(string(`ConGob', "`fm'"))',"SerEGob":`=trim(string(`SerEGob', "`fm'"))',"SaluGob":`=trim(string(`SaluGob', "`fm'"))',"ComprasN":`=trim(string(`ComprasN', "`fm'"))',"ROWTrans":`=trim(string(`ROWTrans', "`fm'"))',"ROWRem":`=trim(string(`ROWRem', "`fm'"))',"ROWProp":`=trim(string(`ROWProp', "`fm'"))',"CapFij":`=trim(string(`CapFij', "`fm'"))',"IngDisp":`=trim(string(`IngDisp', "`fm'"))',"AhorroN":`=trim(string(`AhorroN', "`fm'"))',"OyE":`=trim(string(`OyE', "`fm'"))',"PEF_Pensiones":`=trim(string(`Pensiones', "`fm'"))',"PEF_PensionAM":`=trim(string(`PenBienestar', "`fm'"))',"TaltimirSelf":`=trim(string(`TSelf', "%12.8f"))',"TaltimirSal":`=trim(string(`TSal', "%12.8f"))'},"' _n
file write `fh' `""S_vs_B8n":{"S_sin_ajuste":`=trim(string(`S_micro', "`fm'"))',"AhorroHog":`=trim(string(`AhorroHog', "`fm'"))',"factor_implicito":`=trim(string(`fS', "%12.8f"))',"brecha_pct":`=trim(string(scalar(NTABrechaSPct), "%12.6f"))',"brecha_esperada_pct":`=trim(string(`brecha_esp', "%6.2f"))',"ajuste_aditivo_que_exigiria":`=trim(string(`D', "`fm'"))',"S_final":`=trim(string(`S_nac', "`fm'"))',"S_ajuste":`=trim(string(scalar(NTASAjusteNac), "`fm'"))',"S_personas":`=trim(string(`S_pers', "`fm'"))',"S_ret":`=trim(string(scalar(NTASRetNac), "`fm'"))',"S_def":`=trim(string(scalar(NTASDefNac), "`fm'"))',"S_isflsh":`=trim(string(scalar(NTASISFLSHNac), "`fm'"))',"B8nS1":`=trim(string(`B8nS1', "`fm'"))',"B8nS11S12":`=trim(string(cond(`B8nNoFin' < ., `B8nNoFin' + `B8nFin', .), "`fm'"))',"B8nS13":`=trim(string(`B8nGob', "`fm'"))',"B8nS15":`=trim(string(`B8nISFLSH', "`fm'"))',"modo":"$nta_anclaS","modo_param":"$nta_anclaS_param","brecha_max_pct":`brecha_max',"mixto_motor":`=trim(string(scalar(NTAMixtoMotor), "`fm'"))',"mixto_transf_fin_escalado":`=trim(string(scalar(NTAMixtoTransfFin), "`fm'"))',"pensiones_en_Yl":`=trim(string(scalar(NTAPensEnYl), "`fm'"))',"regla":"off: S residual sin tapón; aditivo: suma ∝ (YL+YA) de adultos con contrapartida en YA_ajuste; multiplicativo: S × factor, sin contrapartida (cae a intra)"},"' _n
file write `fh' `""ya_s14":{"YA_motor":`=trim(string(`YA_motor_tot', "`fm'"))',"YAHogS14":`=trim(string(`YAHogS14', "`fm'"))',"D442":`=trim(string(`YAHogS14' - `YAHogS14n', "`fm'"))',"YAHogS14_ancla":`=trim(string(`YAHogS14n', "`fm'"))',"B2n":`=trim(string(`ExNOpHogS14', "`fm'"))',"tercio_B3n":`=trim(string(`MixNHogS14'/3, "`fm'"))',"D4_neto":`=trim(string(`RentaPropHogNeta', "`fm'"))',"factor":`=trim(string(`fYA', "%12.8f"))',"nta_YA":"$nta_YA","YA_base_micro":`=trim(string(scalar(NTAYABaseNac), "`fm'"))',"por_decil":["'
forvalues d = 1/10 {
	file write `fh' `"`=cond(`d' > 1, ",", "")'{"decil":`d',"pob":`=trim(string(scalar(NTAPobD`d'), "%20.0f"))',"YA_motor":`=trim(string(scalar(NTAYAMotorD`d'), "`fm'"))',"YA_base":`=trim(string(scalar(NTAYABaseD`d'), "`fm'"))'}"'
}
file write `fh' `"],"regla":"el total de YA del motor (neto de depreciación, sin ImpNet embebido, sin D.8) se re-ancla a B.2n + 1/3 B.3n + D.4 neto de S.14 ∝ YA del motor; el alquiler imputado se escala igual"},"' _n
file write `fh' `""impuestos_productos":{"ImpNetosProd_D21_D31":`=trim(string(`ImpNetosProd', "`fm'"))',"ImpNet_BIE":`=trim(string(`ImpNetBIE', "`fm'"))',"ImpProd_micro":`=trim(string(scalar(NTAImpProdNac), "`fm'"))',"embebido_Altimir_sacado":`=trim(string(scalar(NTAImpProdMotor), "`fm'"))',"embebido_Altimir_sacado_de_YA":`=trim(string(scalar(NTAImpProdMotorYA), "`fm'"))',"embebido_Altimir_sacado_de_YL":`=trim(string(scalar(NTAImpProdMotorYL), "`fm'"))',"indirectos_micro_tau_menos":`=trim(string(scalar(NTATmenInd0), "`fm'"))',"factor_indirectos_sobre_ImpNetosProd":`=trim(string(scalar(NTAFactorIndirectos)/100, "%12.8f"))',"regla":"ImpProd ∝ Cpriv; el ImpNet que Altimir embebe en Yk y Yl (∝ ing_mixtoK, ing_capital, ing_estim_alqu) se saca de YA (_soc, _hog y 1/3 de _mixK) y de YL (2/3 de _mixK; v8.14, CONC-1 §6.1)"},"' _n
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
file write `fh' _n "`raya'" _n
file write `fh' "Cuadro 4. S e intra-hogar por quinquenio × sexo (S con el ancla salvo nta_anclaS = off)^8" _n
file write `fh' "`raya'" _n
file write `fh' %-6s ("Edad") %-8s ("Sexo") %8s ("Pob (M)") %11s ("C") %11s ("YL") %11s ("YA") %11s ("τ⁻ públ.") %11s ("τ⁺ públ.") %11s ("S") %11s ("intra") %11s ("R") _n
forvalues i = 1/`=_N' {
	local ql : label quinq `=quinq[`i']'
	local sl : label sexo `=sexo[`i']'
	file write `fh' %-6s ("`ql'") %-8s ("`sl'") %8.1f (pobw[`i']/1e6) `f1' (C[`i']/1e9) `f1' (YL[`i']/1e9) `f1' (YA[`i']/1e9) `f1' (Tmen[`i']/1e9) `f1' (Tpub[`i']/1e9) `f1' (S[`i']/1e9) `f1' (Intra[`i']/1e9) %11.6f (resid_chk[`i']/1e9) _n
}
file write `fh' "`raya'" _n
file write `fh' "Nota 8: residual de la identidad por celda |R| / C máximo " %9.2e (`maxres_qs'/`Ctot') " (gate 1e-9)." _n
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
local BF = scalar(NTAInterRec0) + scalar(NTAOtrosRec0) - scalar(NTAInterOtor0) - scalar(NTAOtrosOtor0)	// 8.17: + indemnizaciones D.72 − D.7 pagada a otros sectores
if abs(`BF') < 1 local BF = 0	// 8.17: con inter_hogar = balance el neto es 0 salvo el ultimo bit; un enlace de 0.001 MXN rompe la tolerancia de pctpib
local BG = scalar(NTATmen_hh0) + `OyE' - scalar(NTATpubEf0) - scalar(NTACpub0)
local lbl3 `"1 "Ingreso 0 a 4" 2 "Ingreso 5 a 17" 3 "Ingreso 18 a 24" 4 "Ingreso 25 a 64" 5 "Ingreso 65 y más" 11 "Gobierno" 12 "Familias" 13 "Activos" 21 "Desahorro 0 a 4" 22 "Desahorro 5 a 17" 23 "Desahorro 18 a 24" 24 "Desahorro 25 a 64" 25 "Desahorro 65 y más" 31 "Otras transferencias privadas" 32 "Déficit público" 41 "Consumo 0 a 4" 42 "Consumo 5 a 17" 43 "Consumo 18 a 24" 44 "Consumo 25 a 64" 45 "Consumo 65 y más" 51 "_De 0 a 4" 52 "_De 5 a 17" 53 "_De 18 a 24" 54 "_De 25 a 64" 55 "_De 65 y más" 61 "Futuro 0 a 4" 62 "Futuro 5 a 17" 63 "Futuro 18 a 24" 64 "Futuro 25 a 64" 65 "Futuro 65 y más" 71 "Resto del gasto público" 72 "Transferencias privadas netas" 81 "Ancla S14 recorte" 82 "Ancla S14 complemento" 15 "Empresas públicas" 999 "Ing nacional""'
quietly {
	tempfile per2 e1 e2 e3 e4 e5
	save `per2'

	* --- Eje 1: perceptores → tipos de ingreso (+ El mundo → Remesas, OyE → capital) --- *
	g double nta_YK = YA_hh - YA_d8 - YA_ajuste - ALQ
	collapse (sum) ing_Ing_laboral=YL ing_Ing_capital=nta_YK ing_Alquiler_propio=ALQ ing_Impuestos_a_productos=ImpProd ing_Derechos_de_pensión_D8=YA_d8 ing_Ajuste_ancla_S_14=YA_ajuste ing_Remesas=Remesas [fw=factor], by(grupoedad)
	reshape long ing_, i(grupoedad) j(tipo) string
	rename ing_ profile
	replace grupoedad = -1 if tipo == "Remesas"
	collapse (sum) profile, by(grupoedad tipo)
	* v8.15b (oye_en_hub = off, firmado): OyE no entra al hub por «Ing capital»; con on (v8.14.0) si *
	if "$oye_en_hub" == "on" {
		set obs `=_N+1'
		replace grupoedad = -2 in -1
		replace tipo = "Ing_capital" in -1
		replace profile = `OyE' in -1
	}
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
		replace profile = scalar(NTAYL`g') + scalar(NTAYA_hh`g') + scalar(NTAImpProd`g') in `g'
	}
	replace to = 11 in 6
	replace profile = `OyE' in 6
	if "$oye_en_hub" == "off" replace from = 15 in 6		// v8.15b: «Empresas públicas → Gobierno», no desde el hub
	replace to = 12 in 7
	replace profile = scalar(NTARemesas0) in 7
	forvalues g = 1/5 {
		if scalar(NTAS_hh`g') < 0 {
			set obs `=_N+1'
			replace from = 20 + `g' in -1
			replace to = 13 in -1
			replace profile = -scalar(NTAS_hh`g') in -1
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
		local Y = scalar(NTAYL`g') + scalar(NTAYA_hh`g') + scalar(NTAImpProd`g')
		local Spos = max(scalar(NTAS_hh`g'), 0)
		local Sneg = max(-scalar(NTAS_hh`g'), 0)
		local Ipos = max(scalar(NTAIntra`g'), 0)
		local Ineg = max(-scalar(NTAIntra`g'), 0)
		* ancla multiplicativa (NTA-1c): d = S sin ancla − S anclado; d > 0 sale de Ingreso g al sink «Ancla S14 recorte»,
		* d < 0 entra a Consumo g desde la fuente «Ancla S14 complemento»; así Ingreso g y Consumo g conservan *
		local d = -scalar(NTAS_ajuste`g')
		local propio = `Y' - scalar(NTATmen_hh`g') - scalar(NTAInterOtor`g') - scalar(NTAOtrosOtor`g') - `Ineg' - `Spos' - max(`d', 0)
		local salidas `"11 `=scalar(NTATmen_hh`g')' 12 `=scalar(NTAInterOtor`g') + scalar(NTAOtrosOtor`g') + `Ineg'' 13 `Spos' `=40+`g'' `propio' 81 `=max(`d', 0)'"'
		local entradas `"11 `=scalar(NTATpubEf`g')' 12 `=scalar(NTAInterRec`g') + scalar(NTAOtrosRec`g') + scalar(NTARemesas`g') + `Ipos'' 13 `Sneg' 82 `=max(-`d', 0)'"'
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
		if scalar(NTAS_hh`g') > 0 {
			set obs `=_N+1'
			replace from = 13 in -1
			replace to = 60 + `g' in -1
			replace profile = scalar(NTAS_hh`g') in -1
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
	noisily _log aviso, tipo(GATE) texto("NTA Sankey v2: `negs' enlaces negativos (un grupo con ingreso propio insuficiente)") rojo
}
escalar mxn NTASankeyBalGob = `BG'
escalar mxn NTASankeyBalFam = `BF'
noisily SankeySumSim, anio(`anio') name(v2-grupoedad) folder(SankeyNTA) a(`e1') b(`e2') c(`e3') d(`e4') e(`e5')
quietly use `per2', clear
noisily _log linea "Sankey v2 (bn): balance Gobierno `=strtrim(string(`BG'/1e9, "%14.3fc"))' (τ⁻ + OyE − τ⁺ efectivo − especie)"
noisily _log linea "Sankey v2 (bn): balance Familias `=strtrim(string(`BF'/1e9, "%14.3fc"))' (recibido − otorgado)"



**********************************
**# 7b. Sankey v3 (NTA-3, 2026-10-29; NTA-4: nodos fundidos y % del PIB): edades solo al inicio y al final (users/$id/SankeyNTA/sankey-v3-grupoedad.json)
**********************************
* Decisión de Ricardo (2026-10-29): el gráfico principal de /NTA lleva las edades solo como perceptores (izquierda) y como
* consumidores (derecha); se eliminan los ejes «Ingreso g» y «Consumo g» y el nodo «Familias». Las transferencias en efectivo,
* inter e intra-hogar netean a cero nacionalmente (lo que un grupo recibe otro lo paga), así que el v3 no las dibuja por grupo:
* la cuenta por grupo × sexo, con efectivo e inter/intra-hogar, vive en el panel (§7c). El v2 (§7) se sigue emitiendo.
* NTA-4 (2026-10-29, decisiones de Ricardo; la cuenta no cambia, cambia la emisión): (i) un solo «Desahorro» (fuente) y un solo
* «Futuro» (sink) en lugar de uno por grupo (el detalle por grupo vive en el panel); (ii) la especie pública se funde con su
* categoría de consumo: Gobierno → Salud / Educación / Otros gastos (desaparecen «Salud pública», «Educación pública», «Otros en
* especie»); cada categoría recibe de Ing nacional, Transferencias en efectivo, Activos y Gobierno y sale a los grupos
* consumidores con privado + especie; «Colectivo» sigue como nodo propio terminal; (iii) el ancla de S.14 en un solo nodo
* «Ajuste a cuentas nacionales S14» con el NETO recorte − complemento (Activos → ajuste si el neto es un recorte; ajuste →
* Activos si fuera un complemento neto); recorte y complemento por separado siguen en nta-grupoedad.json y en el panel;
* (iv) cada enlace viaja con value (MXN corrientes, como siempre) y pctpib = value / PIB × 100 (variable j_pctpib: SankeySumSim
* la escribe como campo del enlace), con el PIB nominal del año que registra SCN.ado (escalar mxn PIB) y que aquí se guarda
* como NTAPIBY; los totales de los hubs se registran como escalar pctpib. Nada se divide fuera de Stata.
* Columnas: Fuentes (grupos perceptores, OyE públicas, El mundo, Desahorro, balances declarados) → Tipos de ingreso (laboral,
* capital, alquiler propio, impuestos a productos, D.8, remesas; mismos ejes 1 y 2 que el v2) → Ing nacional → Gobierno (entran
* τ⁻ + OyE; salen la especie a Salud / Educación / Otros gastos, Colectivo sin edad y «Transferencias en efectivo» a un nodo
* único) y Activos (entra el S sin ancla de los grupos que ahorran y el Desahorro de los que no; salen Futuro, el ajuste S.14 y
* el desahorro hacia las categorías) → Usos (7 categorías, Colectivo, Transferencias en efectivo) → Sinks (grupos consumidores,
* Futuro, Colectivo, Ajuste a cuentas nacionales S14).
* Financiamiento del consumo privado (lo que v2 resolvía en «Consumo g»): cada categoría recibe de Ing nacional lo que los grupos
* pagan con ingreso PROPIO (Y − τ⁻ − S⁺ − recorte + inter recibido + remesas + intra − inter otorgado), de «Transferencias en
* efectivo» lo pagado con τ⁺ efectivo y de Activos lo pagado con desahorro (+ complemento del ancla), cada flujo de cada grupo
* repartido por la CANASTA del grupo (Cpriv_gc / Cpriv_g): propio + efectivo + desahorro = Cpriv_g por la identidad, así que
* Σ entradas de cada categoría = Σ_g Cpriv_gc + Σ_g Cpub_gc (la especie que entra de Gobierno) = sus salidas a los grupos.
* Balances como en v2: «Déficit público» → Gobierno si τ⁻ + OyE < τ⁺ efectivo + Cpub (si no Gobierno → «Resto del gasto
* público»); «Otras transferencias privadas» → Ing nacional si inter recibido > otorgado (si no Ing nacional → «Transferencias
* privadas netas»). Ancla multiplicativa declarada (d_g = S sin ancla − S anclado): recorte = Σ_g max(d_g, 0), complemento =
* Σ_g max(−d_g, 0); el nodo lleva el neto. Conservación en todo nodo intermedio en ambas unidades; test-nta-identidad.sh C lo exige.
* v8.14b (punto 14, 2026-10-30): orden vertical EXPLÍCITO. SankeySumSim emite los nodos por primera aparición (eje por eje, fila por
* fila) y los enlaces en el orden de las filas, y FusionCharts coloca los nodos de cada columna en el orden del arreglo nodes
* (verificado con la captura de test-sitio-nta.sh --png; no hace falta atributo de la librería). Cada eje f1..f5 se ordena por
* (rango del origen, rango del destino) con _nta_v3rank: col. 1 El mundo, grupos de edad, OyE públicas, Desahorro, Otras
* transferencias privadas, Déficit público, Ajuste S14 (si es fuente); col. 2 Remesas, Impuestos a productos, Ing capital, Ing
* laboral, Alquiler propio, Derechos de pensión D8; Ing nacional; Gobierno, Activos; Transferencias en efectivo, Colectivo, Futuro;
* categorías Alimentos, Vivienda, Transporte, Salud, Educación, Vestido, Otros gastos; grupos consumidores («Ajuste ancla S 14»
* del eje 1 vale 0 con nta_anclaS multiplicativo y SankeySumSim no lo emite; lleva rango para que el sort no falle). En el eje 3 las filas
* de Ing nacional van primero (Gobierno sobre Activos). Ningún valor cambia: los ejes 1 y 2 del v2 (e1, e2) no se tocan.
capture program drop _nta_v3rank
program define _nta_v3rank
	args var new
	tempvar lab
	decode `var', g(`lab')
	quietly replace `lab' = subinstr(`lab', "_", " ", .)
	quietly g int `new' = .
	local k = 0
	foreach l in "El mundo" "De 0 a 4" "De 5 a 17" "De 18 a 24" "De 25 a 64" "De 65 y más" "OyE públicas" "Empresas públicas" "Desahorro" ///
		"Otras transferencias privadas" "Déficit público" "Ajuste a cuentas nacionales S14" ///
		"Remesas" "Impuestos a productos" "Ing capital" "Ing laboral" "Alquiler propio" "Derechos de pensión D8" "Ajuste ancla S 14" ///
		"Ing nacional" "Gobierno" "Activos" "Transferencias en efectivo" "Colectivo" "Futuro" "Resto del gasto público" ///
		"Transferencias privadas netas" "Alimentos" "Vivienda" "Transporte" "Salud" "Educación" "Vestido" "Otros gastos" ///
		" De 0 a 4" " De 5 a 17" " De 18 a 24" " De 25 a 64" " De 65 y más" {
		local ++k
		quietly replace `new' = `k' if `lab' == "`l'"
	}
	quietly count if `new' == .
	if r(N) > 0 {
		di as err "NTA.do §7b: nodo sin rango de orden vertical en `var' (_nta_v3rank): "
		noisily list `lab' if `new' == ., noobs
		exit 459
	}
end
local lbl4 `"11 "Gobierno" 13 "Activos" 14 "Transferencias en efectivo" 15 "Empresas públicas" 20 "Desahorro" 31 "Otras transferencias privadas" 32 "Déficit público" 51 "_De 0 a 4" 52 "_De 5 a 17" 53 "_De 18 a 24" 54 "_De 25 a 64" 55 "_De 65 y más" 60 "Futuro" 71 "Resto del gasto público" 72 "Transferencias privadas netas" 80 "Ajuste a cuentas nacionales S14" 999 "Ing nacional""'
quietly {
	tempfile catg fin f1 f2 f3 f4 f5

	* --- Categorías por grupo: privado (misma receta que §7 eje 5) + especie pública fundida en su categoría; «Colectivo» sin edad --- *
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
	g double pb_Salud = CpubSalud
	g double pb_Educación = CpubEduc
	g double pb_Otros_gastos = CpubRestoInd
	g double pb_Colectivo = CpubCol
	collapse (sum) sk_* pb_* [fw=factor], by(grupoedad)
	reshape long sk_ pb_, i(grupoedad) j(cat) string
	rename sk_ priv
	rename pb_ pub
	replace priv = 0 if priv == .
	replace pub = 0 if pub == .
	g double profile = priv + pub
	encode cat, g(catn)
	levelsof catn, local(cats)
	local lblcat ""
	foreach c of local cats {
		local cl : label catn `c'
		local lblcat `"`lblcat' `=100+`c'' "`cl'""'
	}
	* canasta privada del grupo: participación de cada categoría en Cpriv_g (la especie no entra a la canasta) *
	egen double cpriv_g = total(priv), by(grupoedad)
	g double share = priv/cpriv_g
	save `catg'

	* --- Financiamiento del consumo privado por categoría: propio (desde Ing nacional), efectivo (desde Transferencias en
	*     efectivo) y desahorro + complemento (desde Activos), cada grupo repartido por su canasta --- *
	drop if cat == "Colectivo"
	g double v_propio = .
	g double v_efectivo = .
	g double v_desahorro = .
	local Spos_tot = 0
	local Sneg_tot = 0
	local rec_tot = 0
	local comp_tot = 0
	forvalues g = 1/5 {
		local d = -scalar(NTAS_ajuste`g')
		local propio = scalar(NTAYL`g') + scalar(NTAYA_hh`g') + scalar(NTAImpProd`g') - scalar(NTATmen_hh`g') - max(scalar(NTAS_hh`g'), 0) - max(`d', 0) ///
			+ scalar(NTAInterRec`g') + scalar(NTAOtrosRec`g') + scalar(NTARemesas`g') + scalar(NTAIntra`g') - scalar(NTAInterOtor`g') - scalar(NTAOtrosOtor`g')
		replace v_propio = share*(`propio') if grupoedad == `g'
		replace v_efectivo = share*scalar(NTATpubEf`g') if grupoedad == `g'
		replace v_desahorro = share*(max(-scalar(NTAS_hh`g'), 0) + max(-`d', 0)) if grupoedad == `g'
		local Spos_tot = `Spos_tot' + max(scalar(NTAS_hh`g'), 0)
		local Sneg_tot = `Sneg_tot' + max(-scalar(NTAS_hh`g'), 0)
		local rec_tot = `rec_tot' + max(`d', 0)
		local comp_tot = `comp_tot' + max(-`d', 0)
	}
	collapse (sum) v_propio v_efectivo v_desahorro, by(catn)
	save `fin'
	* neto del ancla: > 0 recorte neto (Activos → ajuste), < 0 complemento neto (ajuste → Activos) *
	local ajuste_neto = `rec_tot' - `comp_tot'

	* --- Eje 3: Ing nacional → Gobierno (τ⁻ + OyE) / Activos (S sin ancla de los que ahorran) / categorías (propio);
	*     fuentes → Ing nacional (Otras transferencias privadas), → Gobierno (Déficit público), → Activos (Desahorro, complemento neto) --- *
	g from = 999
	g to = 100 + catn
	g double profile = v_propio
	keep from to profile
	set obs `=_N+1'
	replace from = 999 in -1
	replace to = 11 in -1
	replace profile = scalar(NTATmen_hh0) + cond("$oye_en_hub" == "on", `OyE', 0) in -1
	if "$oye_en_hub" == "off" {
		* v8.15b (firma 10): OyE no es ingreso de personas; entra a Gobierno como fila de sector «Empresas públicas → Gobierno» *
		set obs `=_N+1'
		replace from = 15 in -1
		replace to = 11 in -1
		replace profile = `OyE' in -1
	}
	set obs `=_N+1'
	replace from = 999 in -1
	replace to = 13 in -1
	replace profile = `Spos_tot' + `rec_tot' in -1
	if `Sneg_tot' > 0 {
		set obs `=_N+1'
		replace from = 20 in -1
		replace to = 13 in -1
		replace profile = `Sneg_tot' in -1
	}
	if `ajuste_neto' < 0 {
		set obs `=_N+1'
		replace from = 80 in -1
		replace to = 13 in -1
		replace profile = -`ajuste_neto' in -1
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

	* --- Eje 4: Gobierno → categorías (la especie: Salud, Educación, Otros gastos) y → Colectivo y → Transferencias en efectivo
	*     (τ⁺ efectivo); Transferencias en efectivo → categorías; Activos → categorías (desahorro), → Futuro, → ajuste S.14 (recorte
	*     neto); Gobierno → Resto del gasto público --- *
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
	collapse (sum) pub, by(catn)
	keep if pub > 0
	g from = 11
	g to = 100 + catn
	rename pub profile
	keep from to profile
	append using `f4a'
	set obs `=_N+1'
	replace from = 11 in -1
	replace to = 14 in -1
	replace profile = scalar(NTATpubEf0) in -1
	if `Spos_tot' > 0 {
		set obs `=_N+1'
		replace from = 13 in -1
		replace to = 60 in -1
		replace profile = `Spos_tot' in -1
	}
	if `ajuste_neto' > 0 {
		set obs `=_N+1'
		replace from = 13 in -1
		replace to = 80 in -1
		replace profile = `ajuste_neto' in -1
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

	* --- Eje 5: categorías (privado + especie) → grupos consumidores; Colectivo es terminal (sin edad) --- *
	use `catg', clear
	drop if cat == "Colectivo"
	g from = 100 + catn
	g to = 50 + grupoedad
	keep from to profile
	label define n4 `lbl4' `lblcat'
	label values from n4
	label values to n4
	save `f5'

	* --- % del PIB por enlace (NTA-4): copias propias de los ejes 1 y 2 (el v2 sigue byte-idéntico) y j_pctpib en los cinco --- *
	local negs3 = 0
	local IngNac_tot = 0
	foreach e in e1 e2 f3 f4 f5 {
		use ``e'', clear
		count if profile < 0
		local negs3 = `negs3' + r(N)
		if "`e'" == "e2" {
			tabstat profile, stat(sum) save
			local IngNac_tot = r(StatTotal)[1,1] + max(`BF', 0)
		}
		g double j_pctpib = profile/`PIBY'*100
		* orden vertical explícito (v8.14b, punto 14): solo en las copias del v3; e1/e2 del v2 siguen como estaban *
		_nta_v3rank from nta_rf
		_nta_v3rank to nta_rt
		if "`e'" == "f3" replace nta_rf = 0 if from == 999		// Ing nacional → Gobierno / Activos / categorías primero (Empresas públicas → Gobierno después)
		sort nta_rf nta_rt
		drop nta_rf nta_rt
		if "`e'" == "e1" save `f1'
		else if "`e'" == "e2" save `f2'
		else save ``e'', replace
	}
	use `per2', clear
}
if `negs3' > 0 {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA Sankey v3: `negs3' enlaces negativos (un grupo con ingreso propio insuficiente para su canasta)") rojo
}
escalar mxn NTAPIBY = `PIBY'
escalar pctpib NTAV3IngNacPIB = `IngNac_tot'/`PIBY'*100
escalar pctpib NTAV3GobiernoPIB = (scalar(NTATmen_hh0) + `OyE' + max(-`BG', 0))/`PIBY'*100
escalar pctpib NTAV3ActivosPIB = (`Spos_tot' + `rec_tot' + `Sneg_tot' + max(-`ajuste_neto', 0))/`PIBY'*100
escalar pctpib NTAV3TransfEfPIB = scalar(NTATpubEf0)/`PIBY'*100
escalar pctpib NTAV3FuturoPIB = `Spos_tot'/`PIBY'*100
escalar pctpib NTAV3DesahorroPIB = `Sneg_tot'/`PIBY'*100
escalar pctpib NTAV3ColectivoPIB = scalar(NTACpubColNac)/`PIBY'*100
escalar pctpib NTAV3AjusteS14PIB = `ajuste_neto'/`PIBY'*100
escalar mxn NTAV3AjusteS14 = `ajuste_neto'
escalar mxn NTAV3Recorte = `rec_tot'
escalar mxn NTAV3Complemento = `comp_tot'
noisily SankeySumSim, anio(`anio') name(v3-grupoedad) folder(SankeyNTA) a(`f1') b(`f2') c(`f3') d(`f4') e(`f5')
quietly use `per2', clear
noisily _log linea "Sankey v3 (bn): PIB `anio' `=strtrim(string(`PIBY'/1e9, "%14.3fc"))'; Ing nacional `=strtrim(string(scalar(NTAV3IngNacPIB), "%6.2f"))' % del PIB"
noisily _log linea "Sankey v3 (bn): → Gobierno `=strtrim(string((scalar(NTATmen_hh0) + `OyE')/1e9, "%14.3fc"))' (τ⁻ + OyE, oye_en_hub $oye_en_hub); → Activos `=strtrim(string((`Spos_tot' + `rec_tot')/1e9, "%14.3fc"))'"
noisily _log linea "Sankey v3 (bn): Transferencias en efectivo `=strtrim(string(scalar(NTATpubEf0)/1e9, "%14.3fc"))'; Desahorro `=strtrim(string(`Sneg_tot'/1e9, "%14.3fc"))'; Futuro `=strtrim(string(`Spos_tot'/1e9, "%14.3fc"))'"
noisily _log linea "Sankey v3 (bn): ajuste S.14 neto `=strtrim(string(`ajuste_neto'/1e9, "%14.3fc"))' = recorte `=strtrim(string(`rec_tot'/1e9, "%14.3fc"))' − complemento `=strtrim(string(`comp_tot'/1e9, "%14.3fc"))'"



**********************************
**# 7d. Sankey v4 (8.17, CUAD-2 §6; firma CUAD-1-2 §A 16, 19-23 y §B 17-18): la economía completa, hub = INBD (users/$id/SankeyNTA/sankey-v4-economia.json)
**********************************
* Personas por edad en los dos extremos; en medio los sectores institucionales (Hogares, Sociedades = S.11 + S.12, Gobierno, ISFLSH, el mundo),
* cada uno conservando (entradas = salidas al peso con sus celdas CSI), y un solo pivote: el ingreso nacional disponible neto del BIE (724037 − CCF),
* 27,459.038 bn = 81.561 % del PIB 2024, exacto. Columnas (FusionCharts las deduce del grafo; el orden vertical es el de _nta_v4rank):
*   fuentes: 5 grupos perceptores, El mundo, Fondos de pensión D442, Otros impuestos a la producción, Renta de la propiedad recibida por el gobierno,
*            ISFLSH (B.5n), Vintage BIE vs CSI, Financiamiento (deuda y venta de activos: desahorro de los hogares, de S.11 + S.12 y de S.13), Ajuste S.14 si es fuente
*   tipos:   Ing laboral, Ing capital, Alquiler propio, Impuestos a productos (∝ Cpriv, van al gobierno: no son ingreso de hogares), Sociedades (con
*            retenido_a_personas = on el B.5n de S.11 + S.12 lo aportan las personas ∝ ing_d4_rel; con off es fuente sin edad), Remesas
*   sectores pre-hub: Hogares (B.5n S.14), Gobierno ingreso primario (D.21 − D.31 + D.29 − D.39 + D.4 recibida − intereses de la deuda → Por identificar)
*   hub:     Ingreso nacional disponible = Σ B.5n de los sectores + transferencias netas del mundo + vintage NNI
*   post-hub: el hub es la casa de compensación de la distribución secundaria: lo que cada sector recibe de los demás sale del hub por un nodo con nombre
*            (ISR de personas, Cuotas a la seguridad social, Cuotas a Afores y aseguradoras, Cuotas a planes de empleadores, Primas netas de seguros,
*            Donativos a ISFLSH, Otras transferencias D759, saldos primarios netos) hacia su «… ingreso disponible»; de ahí, lo que cada sector paga a los
*            hogares va a «Hogares ingreso disponible» (Transferencias en efectivo, Prestaciones privadas, Derechos de pensión D8), el ISR de sociedades a
*            Gobierno, D.751 a ISFLSH, la especie (D.63) a Educación / Salud / Otros gastos, el consumo colectivo (P.32) a Colectivo y el ahorro a Futuro;
*            los sectores que desahorran reciben de Financiamiento. Lo que la CSI no dice a quién llega (intereses de la deuda D.41 del gobierno, el
*            residuo de D.759) va a «Por identificar» (sello rojo). El vintage BIE−CSI de los sectores tras el hub es un sink declarado.
*   usos:    7 categorías → 5 grupos consumidores (privado + especie); Colectivo y Futuro terminales.
* Hogares ingreso disponible recibe del hub la celda CSI (B.5n − D.5 − D.61 − D.7 pagada + D.752) y de los demás sectores sus transferencias; paga P.3 a
* las categorías (menos el desahorro de los grupos que desahorran, que financia Financiamiento) y S⁺ a Futuro, con el S micro SIN ancla; la diferencia
* con B.8n S.14 es el nodo «Ajuste a cuentas nacionales S14» (sink si la CSI ahorra más que el micro; fuente si menos): declarado, nunca absorbido.
* Todo valor nace aquí de escalares de SCN.ado (celdas CSI y BIE) o de las sumas por grupo de la cuenta por persona; cada enlace viaja con value (MXN)
* y pctpib (% del PIB BIE del año). Cada nodo intermedio conserva a 1e-9 (cuadro 5 de nta-identidad.txt; test-nta-identidad.sh D lo exige).
capture program drop _nta_v4add
program define _nta_v4add
	args f t v
	if `v' == 0 exit
	if `v' < 0 {
		global NTA_V4_NEG "$NTA_V4_NEG `f'->`t'=`v'"
		exit
	}
	quietly set obs `=_N+1'
	quietly replace from = `f' in -1
	quietly replace to = `t' in -1
	quietly replace profile = `v' in -1
end
capture program drop _nta_v4rank
program define _nta_v4rank
	args var new
	tempvar lab
	decode `var', g(`lab')
	quietly replace `lab' = subinstr(`lab', "_", " ", .)
	quietly g int `new' = .
	local k = 0
	foreach l in "El mundo" "De 0 a 4" "De 5 a 17" "De 18 a 24" "De 25 a 64" "De 65 y más" "Fondos de pensión D442" "Otros impuestos a la producción" ///
		"Renta de la propiedad recibida por el gobierno" "ISFLSH" "Vintage BIE vs CSI" "Ajuste a cuentas nacionales S14" ///
		"Financiamiento deuda y venta de activos" "Financiamiento de los hogares" "Financiamiento de las sociedades" "Financiamiento del gobierno" ///
		"Remesas" "Ing laboral" "Ing capital" "Alquiler propio" "Impuestos a productos" "Sociedades" "Hogares" "Gobierno ingreso primario" "Intereses de la deuda" ///
		"Ingreso nacional disponible" "Hogares ingreso disponible" "Transferencias en efectivo" "Prestaciones privadas" "Derechos de pensión D8" ///
		"ISR de personas" "Cuotas a la seguridad social" "Ingreso primario neto del gobierno" "ISR de sociedades" "Otras transferencias D759" "Gobierno ingreso disponible" ///
		"Cuotas a Afores y aseguradoras" "Cuotas a planes de empleadores" "Primas netas de seguros" "Sociedades saldo primario" "Sociedades ingreso disponible" ///
		"Donativos a ISFLSH" "ISFLSH saldo primario" "ISFLSH ingreso disponible" "Vintage BIE vs CSI usos" "Por identificar" ///
		"Alimentos" "Vivienda" "Transporte" "Salud" "Educación" "Vestido" "Otros gastos" "Colectivo" "Futuro" ///
		" De 0 a 4" " De 5 a 17" " De 18 a 24" " De 25 a 64" " De 65 y más" {
		local ++k
		quietly replace `new' = `k' if `lab' == "`l'"
	}
	quietly count if `new' == .
	if r(N) > 0 {
		di as err "NTA.do §7d: nodo sin rango de orden vertical en `var' (_nta_v4rank): "
		noisily list `lab' if `new' == ., noobs
		exit 459
	}
end
foreach l in v4hub v4hogB5n v4socB5n v4gobB5n v4isfB5n v4rem v4vhub v4vsink v4fin v4fut v4pid v4aj v4col {
	local `l' = 0
}
global NTA_V4_NEG ""
local v4nodos = 0
local v4enlaces = 0
if "$hub" == "inbd" {
quietly {
	tempfile g1 g2 g3 g4 g5 v4all
	local on = ("$retenido_a_personas" == "on")
	local B5nSoc = `B5nNoFin' + `B5nFin'
	local B8nSoc = `B8nNoFin' + `B8nFin'
	local D614 = `ContribSocHog' - `CuotasHogS14'
	local d614 = cond("$circuito_d442" == "neto", `D614', 0)
	* --- celdas y sumas micro --- *
	local hogB5n = 0
	local Spos4_tot = 0
	local Sneg4_tot = 0
	forvalues g = 1/5 {
		local hogB5n = `hogB5n' + scalar(NTAYL`g') + scalar(NTAYA_base`g')
		local Spos4`g' = max(scalar(NTAS_sinancla`g'), 0)
		local Sneg4`g' = max(-scalar(NTAS_sinancla`g'), 0)
		local Spos4_tot = `Spos4_tot' + `Spos4`g''
		local Sneg4_tot = `Sneg4_tot' + `Sneg4`g''
	}
	local hogB5n = `hogB5n' + `D442Hog'
	local Rem = scalar(NTARemesas0)
	local ISRpers = scalar(NTAISRPersonasNac) + scalar(NTAD59Nac)
	local sector_on = ("$cuotas_por_sector" == "on" & "$nta_cuotas" == "S14")
	if `sector_on' {
		local cS13 = scalar(NTACuotasS13Nac)
		local cS12 = scalar(NTACuotasS12Nac) + (`D614' - `d614')
		local cS11 = scalar(NTACuotasS11Nac)
		local cS15 = scalar(NTACuotasS15Nac)
	}
	else {
		local cS13 = scalar(NTACuotasNac)
		local cS12 = 0
		local cS11 = 0
		local cS15 = 0
		local flags `"`flags' "Sankey v4: cuotas_por_sector = off: todas las cuotas van al gobierno (sin Afores ni planes de empleadores)""'
	}
	local primas = scalar(NTAOtorPrimas0)
	local dona = scalar(NTAOtorISFLSH0)
	local remenv = scalar(NTAOtorRemEnv0)
	local d759h = scalar(NTAOtorD7590)
	local ISRsoc = `D5NoFin' + `D5Fin'
	local prest = `D62NoFinU' + `D62FinU' + `D72HogR'
	local d8 = `D8FinU'
	local d759soc = `D759NoFinU' + `D759FinU'
	local donaSoc = `D751NoFinU' + `D751FinU'
	local donaGob = `D751GobU'
	local transfEf = `D62GobU' + `OtrasTransfHog'
	local educ = `SerEGob'*`fEsp'
	local salud = `SaluGob'*`fEsp'
	local otrosGob = `D63GobU' - `educ' - `salud'
	local colect = `P32Gob'
	local finGob = max(-`B8nGob', 0)
	local finSoc = max(-`B8nSoc', 0)
	local futISF = max(`B8nISFLSH', 0)
	local finISF = max(-`B8nISFLSH', 0)
	local futSoc = max(`B8nSoc', 0)
	local futGob = max(`B8nGob', 0)
	* hub → Hogares ingreso disponible: la celda CSI del hogar tras la distribución secundaria con el circuito D.442/D.614 según circuito_d442 *
	local hubHog = `hogB5n' - `ISRpers' - (`cS13' + `cS12' + `cS11' + `cS15' + `d614') - (`primas' + `dona' + `remenv' + `d759h') + `RemesasHogS14'
	local d759in = `d759h' + `d759soc'
	local d759gob = min(`D759GobR', `d759in')
	local d759pid = `d759in' - `d759gob'
	if `d759gob' < `D759GobR' local flags `"`flags' "D.759 recibida por el gobierno `=string(`D759GobR'/1e9, "%7.1f")' bn > pagada por S.11 + S.12 + S.14 `=string(`d759in'/1e9, "%7.1f")': el enlace al gobierno se acota a lo pagado""'
	* saldos residuales (conservación exacta de cada sector tras el hub) *
	local gobOut = `transfEf' + `educ' + `salud' + `otrosGob' + `colect' + `donaGob' + `futGob'
	local gobSaldo = `gobOut' - (`ISRpers' + `cS13' + `d759gob' + `ISRsoc' + `finGob')
	local socOut = `ISRsoc' + `prest' + `d8' + `d759soc' + `donaSoc' + `futSoc'
	local socSaldo = `socOut' - (`cS12' + `cS11' + `primas' + `finSoc')
	local isfOut = `D62ISFLSHU' + `D63ISFLSHU' + `futISF'
	local isfSaldo = `isfOut' - (`dona' + `donaSoc' + `donaGob' + `finISF')	// las cuotas a ISFLSH (D.61 S.15) viajan dentro del saldo
	* pre-hub: gobierno ingreso primario *
	local impProd = scalar(NTAImpProd0)
	local otrosImp = `D29D39GobR'
	local rentaGob = `B5nGob' + `D41GobU' - `impProd' - `otrosImp'
	* hub *
	local hubIn0 = `hogB5n' + `B5nSoc' + `B5nGob' + `B5nISFLSH' + `Rem'
	local vHub = `IngDisp' - `hubIn0'
	local hubOut0 = `hubHog' + `ISRpers' + `cS13' + `gobSaldo' + `cS12' + `cS11' + `primas' + `socSaldo' + `dona' + `isfSaldo' + `d759h'
	local vSink = `IngDisp' - `hubOut0'
	local absorbido = ("$vintage_nodo" == "absorbido")
	if `absorbido' local flags `"`flags' "vintage_nodo = absorbido: el vintage BIE−CSI (`=string(`vHub'/1e9, "%6.1f")' al hub, `=string(`vSink'/1e9, "%6.1f")' en usos) se suma a Hogares""'
	* hogares ingreso disponible: entradas, P.3 y S micro sin ancla; el ajuste S.14 es lo que falta o sobra contra B.8n S.14 *
	local hogBin = `hubHog' + cond(`absorbido', `vSink', 0) + `transfEf' + `prest' + `d8' + `D62ISFLSHU'
	local ajuste = `hogBin' - scalar(NTACpriv0) - (`Spos4_tot' - `Sneg4_tot')
	* códigos de las categorías (los de §7b: catn de catg) *
	use `catg', clear
	foreach c in Salud Educación Otros_gastos Colectivo {
		levelsof catn if cat == "`c'", local(cc)
		local code_`c' = 100 + `cc'
	}
	levelsof catn if cat != "Colectivo", local(cats)
	* financiamiento: un nodo (16) o uno por sector (17 hogares, 18 sociedades, 20 gobierno) *
	local finH = cond("$financiamiento" == "por_sector", 17, 16)
	local finS = cond("$financiamiento" == "por_sector", 18, 16)
	local finG = cond("$financiamiento" == "por_sector", 20, 16)
	local lbl5 `"10 "El mundo" 11 "Fondos de pensión D442" 12 "Otros impuestos a la producción" 13 "Renta de la propiedad recibida por el gobierno" 14 "ISFLSH" 15 "Vintage BIE vs CSI" 16 "Financiamiento deuda y venta de activos" 17 "Financiamiento de los hogares" 18 "Financiamiento de las sociedades" 20 "Financiamiento del gobierno" 19 "Ajuste a cuentas nacionales S14" 21 "Ing laboral" 22 "Ing capital" 23 "Alquiler propio" 24 "Impuestos a productos" 25 "Sociedades" 26 "Remesas" 31 "Hogares" 32 "Gobierno ingreso primario" 33 "Intereses de la deuda" 40 "Ingreso nacional disponible" 51 "ISR de personas" 52 "Cuotas a la seguridad social" 53 "Ingreso primario neto del gobierno" 54 "Cuotas a Afores y aseguradoras" 55 "Cuotas a planes de empleadores" 56 "Primas netas de seguros" 57 "Sociedades saldo primario" 58 "Donativos a ISFLSH" 59 "ISFLSH saldo primario" 60 "Otras transferencias D759" 61 "Vintage BIE vs CSI usos" 71 "Hogares ingreso disponible" 72 "Gobierno ingreso disponible" 73 "Sociedades ingreso disponible" 74 "ISFLSH ingreso disponible" 81 "ISR de sociedades" 82 "Prestaciones privadas" 83 "Derechos de pensión D8" 84 "Transferencias en efectivo" 90 "Por identificar" 91 "Colectivo" 92 "Futuro""'
	forvalues g = 1/5 {
		local lg : label grupoedad `g'
		local lbl5 `"`lbl5' `g' "`lg'" `=150+`g'' "_`lg'""'
	}
	* --- g1: perceptores → tipos de ingreso; El mundo → Remesas --- *
	clear
	g int from = .
	g int to = .
	g double profile = .
	forvalues g = 1/5 {
		_nta_v4add `g' 21 `=scalar(NTAYL`g')'
		_nta_v4add `g' 22 `=scalar(NTAYA_base`g') - scalar(NTAALQ`g')'
		_nta_v4add `g' 23 `=scalar(NTAALQ`g')'
		_nta_v4add `g' 24 `=scalar(NTAImpProd`g')'
		if `on' _nta_v4add `g' 25 `=scalar(NTAYA_ret`g')'
	}
	_nta_v4add 10 26 `Rem'
	capture label drop n5
	label define n5 `lbl5' `lblcat'
	label values from n5
	label values to n5
	save `g1'
	* --- g2: tipos → sectores pre-hub → hub --- *
	clear
	g int from = .
	g int to = .
	g double profile = .
	local sYL = 0
	local sYK = 0
	local sALQ = 0
	forvalues g = 1/5 {
		local sYL = `sYL' + scalar(NTAYL`g')
		local sYK = `sYK' + scalar(NTAYA_base`g') - scalar(NTAALQ`g')
		local sALQ = `sALQ' + scalar(NTAALQ`g')
	}
	_nta_v4add 21 31 `sYL'
	_nta_v4add 22 31 `sYK'
	_nta_v4add 23 31 `sALQ'
	_nta_v4add 11 31 `D442Hog'
	if `absorbido' _nta_v4add 15 31 `vHub'
	_nta_v4add 31 40 `=`hogB5n' + cond(`absorbido', `vHub', 0)'
	_nta_v4add 24 32 `impProd'
	_nta_v4add 12 32 `otrosImp'
	_nta_v4add 13 32 `rentaGob'
	_nta_v4add 32 40 `B5nGob'
	_nta_v4add 32 33 `D41GobU'
	_nta_v4add 33 90 `D41GobU'
	_nta_v4add 25 40 `B5nSoc'
	_nta_v4add 14 40 `B5nISFLSH'
	_nta_v4add 26 40 `Rem'
	if !`absorbido' _nta_v4add 15 40 `vHub'
	capture label drop n5
	label define n5 `lbl5' `lblcat'
	label values from n5
	label values to n5
	save `g2'
	* --- g3: hub → hogares ingreso disponible, nodos de la distribución secundaria, vintage de usos --- *
	clear
	g int from = .
	g int to = .
	g double profile = .
	_nta_v4add 40 71 `=`hubHog' + cond(`absorbido', `vSink', 0)'
	_nta_v4add 40 51 `ISRpers'
	_nta_v4add 40 52 `cS13'
	_nta_v4add 40 53 `gobSaldo'
	_nta_v4add 40 54 `cS12'
	_nta_v4add 40 55 `cS11'
	_nta_v4add 40 56 `primas'
	_nta_v4add 40 57 `socSaldo'
	_nta_v4add 40 58 `dona'
	_nta_v4add 40 59 `isfSaldo'
	_nta_v4add 40 60 `d759h'
	if !`absorbido' _nta_v4add 40 61 `vSink'
	capture label drop n5
	label define n5 `lbl5' `lblcat'
	label values from n5
	label values to n5
	save `g3'
	* --- g4: sectores ingreso disponible: entradas, transferencias entre ellos y a los hogares, usos --- *
	clear
	g int from = .
	g int to = .
	g double profile = .
	_nta_v4add 51 72 `ISRpers'
	_nta_v4add 52 72 `cS13'
	_nta_v4add 53 72 `gobSaldo'
	_nta_v4add 54 73 `cS12'
	_nta_v4add 55 73 `cS11'
	_nta_v4add 56 73 `primas'
	_nta_v4add 57 73 `socSaldo'
	_nta_v4add 58 74 `dona'
	_nta_v4add 59 74 `isfSaldo'
	_nta_v4add `finS' 73 `finSoc'
	_nta_v4add `finG' 72 `finGob'
	_nta_v4add 16 74 `finISF'
	_nta_v4add 73 81 `ISRsoc'
	_nta_v4add 81 72 `ISRsoc'
	_nta_v4add 73 60 `d759soc'
	_nta_v4add 60 72 `d759gob'
	_nta_v4add 60 90 `d759pid'
	_nta_v4add 73 74 `donaSoc'
	_nta_v4add 72 74 `donaGob'
	_nta_v4add 73 82 `prest'
	_nta_v4add 82 71 `prest'
	_nta_v4add 73 83 `d8'
	_nta_v4add 83 71 `d8'
	_nta_v4add 72 84 `transfEf'
	_nta_v4add 84 71 `transfEf'
	_nta_v4add 74 71 `D62ISFLSHU'
	_nta_v4add 72 `code_Educación' `educ'
	_nta_v4add 72 `code_Salud' `salud'
	_nta_v4add 72 `code_Otros_gastos' `otrosGob'
	_nta_v4add 72 91 `colect'
	_nta_v4add 74 `code_Otros_gastos' `D63ISFLSHU'
	_nta_v4add 74 92 `futISF'
	_nta_v4add 73 92 `futSoc'
	_nta_v4add 72 92 `futGob'
	_nta_v4add 71 92 `Spos4_tot'
	if `ajuste' > 0 _nta_v4add 71 19 `ajuste'
	if `ajuste' < 0 _nta_v4add 19 71 `=-`ajuste''
	capture label drop n5
	label define n5 `lbl5' `lblcat'
	label values from n5
	label values to n5
	tempfile g4a
	save `g4a'
	* hogares → categorías (Cpriv del grupo menos su desahorro, por canasta) y Financiamiento → categorías (el desahorro, por canasta) *
	use `catg', clear
	drop if cat == "Colectivo"
	g double v_hog = .
	g double v_fin = .
	forvalues g = 1/5 {
		local cpriv_g = scalar(NTACpriv`g')
		replace v_hog = share*(`cpriv_g' - `Sneg4`g'') if grupoedad == `g'
		replace v_fin = share*`Sneg4`g'' if grupoedad == `g'
	}
	collapse (sum) v_hog v_fin, by(catn)
	g int from = 71
	g int to = 100 + catn
	g double profile = v_hog
	tempfile g4b
	keep from to profile
	save `g4b'
	use `catg', clear
	drop if cat == "Colectivo"
	g double v_fin = .
	forvalues g = 1/5 {
		replace v_fin = share*`Sneg4`g'' if grupoedad == `g'
	}
	collapse (sum) v_fin, by(catn)
	g int from = `finH'
	g int to = 100 + catn
	g double profile = v_fin
	keep from to profile
	append using `g4b'
	append using `g4a'
	drop if profile == 0
	capture label drop n5
	label define n5 `lbl5' `lblcat'
	label values from n5
	label values to n5
	save `g4'
	* --- g5: categorías (privado + especie) → grupos consumidores --- *
	use `catg', clear
	drop if cat == "Colectivo"
	g int from = 100 + catn
	g int to = 150 + grupoedad
	keep from to profile
	drop if profile == 0
	capture label drop n5
	label define n5 `lbl5' `lblcat'
	label values from n5
	label values to n5
	save `g5'
	* --- % del PIB, orden vertical y conservación por nodo --- *
	clear
	foreach e in g1 g2 g3 g4 g5 {
		append using ``e''
	}
	save `v4all'
	foreach e in g1 g2 g3 g4 g5 {
		use ``e'', clear
		g double j_pctpib = profile/`PIBY'*100
		_nta_v4rank from nta_rf
		_nta_v4rank to nta_rt
		sort nta_rf nta_rt
		drop nta_rf nta_rt
		save ``e'', replace
	}
	use `v4all', clear
	local v4enlaces = _N
	preserve
	collapse (sum) salida = profile, by(from)
	rename from nodo
	tempfile vout
	save `vout'
	restore
	collapse (sum) entrada = profile, by(to)
	rename to nodo
	merge 1:1 nodo using `vout', nogen
	replace entrada = 0 if entrada == .
	replace salida = 0 if salida == .
	local v4nodos = _N
	g double reldif = cond(entrada > 0 & salida > 0, reldif(entrada, salida), .)
	g byte intermedio = entrada > 0 & salida > 0
	summarize reldif, meanonly
	local v4maxrel = cond(r(N) > 0, r(max), 0)
	count if intermedio
	local v4nint = r(N)
	decode nodo, g(nodolab)
	replace nodolab = subinstr(nodolab, "_", " ", .)
	tempfile v4nodes
	save `v4nodes'
	use `per2', clear
}
if "$NTA_V4_NEG" != "" {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA Sankey v4: enlaces negativos omitidos: $NTA_V4_NEG") rojo
	local flags `"`flags' "Sankey v4: enlaces negativos omitidos ($NTA_V4_NEG)""'
}
if `v4maxrel' > `tol' {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA Sankey v4: algún nodo intermedio no conserva (reldif máx `=strtrim(string(`v4maxrel', "%9.2e"))')") rojo
}
local v4hub = `IngDisp'
local v4hogB5n = `hogB5n'
local v4socB5n = `B5nSoc'
local v4gobB5n = `B5nGob'
local v4isfB5n = `B5nISFLSH'
local v4rem = `Rem'
local v4vhub = `vHub'
local v4vsink = `vSink'
local v4fin = `Sneg4_tot' + `finSoc' + `finGob' + `finISF'
local v4fut = `Spos4_tot' + `futISF' + `futSoc' + `futGob'
local v4pid = `D41GobU' + `d759pid'
local v4aj = `ajuste'
local v4col = `colect'
escalar pctpib NTAV4HubPIB = `IngDisp'/`PIBY'*100
escalar mxn NTAV4Hub = `IngDisp'
escalar mxn NTAV4VintageHub = `vHub'
escalar mxn NTAV4VintageUsos = `vSink'
escalar mxn NTAV4Financiamiento = `v4fin'
escalar mxn NTAV4Futuro = `v4fut'
escalar mxn NTAV4PorIdentificar = `v4pid'
escalar mxn NTAV4AjusteS14 = `ajuste'
escalar mxn NTAV4SPersonas = `S_pers'
escalar mxn NTAV4B8nS1 = `B8nS1'
noisily SankeySumSim, anio(`anio') name(v4-economia) folder(SankeyNTA) a(`g1') b(`g2') c(`g3') d(`g4') e(`g5')
quietly use `per2', clear
noisily _log linea "Sankey v4 (bn): hub INBD `=strtrim(string(`IngDisp'/1e9, "%14.3fc"))' = `=strtrim(string(scalar(NTAV4HubPIB), "%6.3f"))' % del PIB; Hogares `=strtrim(string(`hogB5n'/1e9, "%14.3fc"))'"
noisily _log linea "Sankey v4 (bn): Sociedades `=strtrim(string(`B5nSoc'/1e9, "%14.3fc"))'; Gobierno `=strtrim(string(`B5nGob'/1e9, "%14.3fc"))'; ISFLSH `=strtrim(string(`B5nISFLSH'/1e9, "%14.3fc"))'"
noisily _log linea "Sankey v4 (bn): Remesas `=strtrim(string(`Rem'/1e9, "%14.3fc"))'; vintage al hub `=strtrim(string(`vHub'/1e9, "%14.3fc"))' (NNI `=strtrim(string(`VintageNNI'/1e9, "%14.3fc"))'), en usos `=strtrim(string(`vSink'/1e9, "%14.3fc"))'"
noisily _log linea "Sankey v4 (bn): Financiamiento `=strtrim(string(`v4fin'/1e9, "%14.3fc"))' (hogares `=strtrim(string(`Sneg4_tot'/1e9, "%14.3fc"))', sociedades `=strtrim(string(`finSoc'/1e9, "%14.3fc"))', gobierno `=strtrim(string(`finGob'/1e9, "%14.3fc"))')"
noisily _log linea "Sankey v4 (bn): Futuro `=strtrim(string(`v4fut'/1e9, "%14.3fc"))'"
noisily _log linea "Sankey v4 (bn): Por identificar `=strtrim(string(`v4pid'/1e9, "%14.3fc"))' (intereses de la deuda `=strtrim(string(`D41GobU'/1e9, "%14.3fc"))', D.759 `=strtrim(string(`d759pid'/1e9, "%14.3fc"))')"
noisily _log linea "Sankey v4 (bn): ajuste S.14 `=strtrim(string(`ajuste'/1e9, "%14.3fc"))' (B.8n S.14 − S micro)"
noisily _log aviso, tipo(GATE) texto("NTA Sankey v4: `v4nodos' nodos, `v4enlaces' enlaces; conservación en nodos intermedios reldif máx `=strtrim(string(`v4maxrel', "%9.2e"))' → `=cond(`v4maxrel' <= `tol' & "$NTA_V4_NEG" == "", "OK", "ROJO")'")
* cuadro 5 de nta-identidad.txt: nodos, enlaces e identidades por nodo (estándar §D) *
quietly {
	use `v4nodes', clear
	sort nodo
	file open `fh' using `"`dirnta'/nta-identidad.txt"', write append text
	file write `fh' _n "`raya'" _n
	file write `fh' "Cuadro 5. Sankey v4 (la economía completa, hub = INBD): identidad por nodo, entradas = salidas (miles de millones de MXN `anio'; `v4nodos' nodos, `v4enlaces' enlaces)^9" _n
	file write `fh' "`raya'" _n
	file write `fh' %-48s ("Nodo") %13s ("Entradas") %13s ("Salidas") %12s ("reldif") %7s ("") _n
	forvalues i = 1/`=_N' {
		local lab = nodolab[`i']
		if intermedio[`i'] file write `fh' %-48s ("`lab'") %13.1fc (entrada[`i']/1e9) %13.1fc (salida[`i']/1e9) %12.2e (reldif[`i']) %7s (cond(reldif[`i'] <= `tol', "OK", "ROJO")) _n
		else file write `fh' %-48s ("`lab'") %13.1fc (entrada[`i']/1e9) %13.1fc (salida[`i']/1e9) %12s (cond(entrada[`i'] == 0, "fuente", "sink")) %7s ("") _n
	}
	file write `fh' "`raya'" _n
	file write `fh' "Nota 9: parámetros CUAD-2: hub = $hub, retenido_a_personas = $retenido_a_personas, deficit_a_personas = $deficit_a_personas, isflsh_regla = $isflsh_regla, circuito_d442 = $circuito_d442, vintage_nodo = $vintage_nodo, bruto_neto = $bruto_neto, financiamiento = $financiamiento, discrepancia_gasto = $discrepancia_gasto, inter_hogar = $inter_hogar. Las fuentes y los sinks son los extremos (personas por edad, el mundo, vintage, financiamiento, por identificar, futuro, colectivo). «Por identificar» recibe los intereses de la deuda pública (D.41 S.13 " %11.1fc (`D41GobU'/1e9) ") y el residuo de D.759 (" %11.1fc (`d759pid'/1e9) "): la CSI no publica la matriz de quién a quién (sello rojo). El ajuste S.14 = B.8n S.14 − Σ S micro sin ancla = " %11.1fc (`ajuste'/1e9) " (sink si > 0)." _n
	file write `fh' %-62s ("GATE 1e-9  hub = INBD BIE 724037 − CCF (MXN)") %21.2fc (`hubIn0' + `vHub' - `IngDisp') _n
	file write `fh' %-62s ("GATE 1e-9  hub = B.5n S.1 CSI + ROWTrans BIE + vintage NNI (MXN)") %21.2fc (`hubIn0' + `vHub' - `B5nS1' - `ROWTrans' - `VintageNNI') _n
	file write `fh' %-62s ("GATE 1e-9  Hogares → hub = B.5n S.14 CSI f.110 (MXN)") %21.2fc (`hogB5n' - `D1HogS14' - `MixNHogS14' - `ExNOpHogS14' - `RentaPropHogNeta') _n
	file write `fh' %-62s ("GATE 1e-9  Hogares ingreso disponible − D.8 = B.6n S.14 (MXN)") %21.2fc (`hogBin' - `d8' - `B6nHog') _n
	file write `fh' %-62s ("GATE 1e-9  Gobierno: entradas − financiamiento − pagadas = B.6n S.13 (MXN)") %21.2fc (`ISRpers' + `cS13' + `gobSaldo' + `d759gob' + `ISRsoc' - `transfEf' - `donaGob' - `B6nGob') _n
	file write `fh' %-62s ("GATE 1e-9  Sociedades: entradas − financiamiento − pagadas = B.6n S.11 + S.12 (MXN)") %21.2fc (`cS12' + `cS11' + `primas' + `socSaldo' - `ISRsoc' - `prest' - `d759soc' - `donaSoc' - `B6nNoFin' - `B6nFin') _n
	file write `fh' %-62s ("GATE 1e-9  ISFLSH: entradas − financiamiento − pagadas = B.6n S.15 (MXN)") %21.2fc (`dona' + `isfSaldo' + `donaSoc' + `donaGob' - `D62ISFLSHU' - `B6nISFLSH') _n
	file write `fh' %-62s ("GATE 1e-9  Σ B.6n por sector = B.6n S.1 CSI (MXN)") %21.2fc (`B6nHog' + `B6nGob' + `B6nNoFin' + `B6nFin' + `B6nISFLSH' - `B6nS1') _n
	file write `fh' %-62s ("INFO       INBD − Σ B.6n = vintage usos + por identificar D.759 (MXN)") %21.2fc (`IngDisp' - `B6nS1' - `vSink' - `d759pid') _n
	file write `fh' %-62s ("GATE 1e-9  Usos: Σ B.6n = Σ P.3 + Σ B.8n CSI (MXN)") %21.2fc (`B6nS1' - `P3S1' - `B8nS1') _n
	file write `fh' %-62s ("GATE 1e-9  Futuro − Financiamiento + ajuste S.14 = B.8n S.1 (MXN)") %21.2fc (`v4fut' - `v4fin' + `ajuste' - `B8nS1') _n
	file write `fh' %-62s ("GATE 1e-9  Financiamiento CSI: Σ B.9 < 0 = Σ B.9 > 0 + Mundo (MXN)") %21.2fc (-`B9NoFin' - `B9Gob' - `B9Fin' - `B9Hog' - `B9ISFLSH' - `B9Row') _n
	file write `fh' %-62s ("GATE 1e-9  conservación en los `v4nint' nodos intermedios (reldif máx)") %21.2e (`v4maxrel') _n
	file write `fh' %-62s ("RESULTADO del Sankey v4") %21s (cond(`v4maxrel' <= `tol' & "$NTA_V4_NEG" == "", "OK", "ROJO")) _n
	file close `fh'
	use `per2', clear
}
}
else {
	noisily _log aviso, tipo(Nota) texto("Sankey v4: no se emite (hub = $hub)") ref("CUAD-2 §4")
}



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
* NTA-4 (esquema nta-panel/v2): doble emisión. Cada celda lleva además pctpib = valor / PIB × 100 (PIB nominal del año, escalar PIB de
* SCN.ado = NTAPIBY) de sus escalares y de cada flujo; el bloque pib declara el denominador y nacional_pctpib trae en % del PIB las
* cifras nacionales que la página /NTA escribe en bn («Anchoring and residual»: S, ancla, YA, efectivo, τ⁻, consumo, hubs del v3) y
* v3_mxn los totales del v3 (hubs, Futuro, Desahorro, Colectivo, ancla recorte / complemento / neta) en MXN.
* Nada se divide fuera de Stata: la página solo transcribe.
capture program drop _ntanum
program define _ntanum, rclass
	args e
	local s = trim(string(`e', "%25.17g"))
	if "`s'" == "." local s = "null"
	else if substr("`s'", 1, 1) == "." local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end
local pan_in "YL YA TpubEf TpubEsp TpubCol TpubISFLSH InterRec OtrosRec IntraRec Desahorro AnclaComplemento"
local pan_out "Cpriv CpubEsp CpubCol Tmen InterOtor OtrosOtor IntraOtor S AnclaRecorte"
quietly {
	tempfile pan
	g double IntraPos = max(Intra, 0)
	g double IntraNeg = max(-Intra, 0)
	g double pobw = 1
	g byte sexo3 = sexo
	save `pan'
	replace sexo3 = 0
	append using `pan'
	collapse (sum) YL YA ImpProd YA_d8 TpubEf TpubEsp TpubCol TpubISFLSH InterRec OtrosRec Remesas IntraPos IntraNeg S S_hh S_ret S_def S_isflsh S_sinancla S_ajuste Cpriv CpubInd CpubCol C Tmen Tmen_hh TmenRet TmenDef YA_hh YA_ret InterOtor OtrosOtor pobw [fw=factor], by(grupoedad sexo3)
	sort grupoedad sexo3
	g double in_YL = YL
	g double in_YA = YA + ImpProd
	g double in_TpubEf = TpubEf
	g double in_TpubEsp = TpubEsp
	g double in_TpubCol = TpubCol
	g double in_TpubISFLSH = TpubISFLSH
	g double in_InterRec = InterRec + Remesas
	g double in_OtrosRec = OtrosRec
	g double in_IntraRec = IntraPos
	g double in_Desahorro = max(-S, 0)
	g double in_AnclaComplemento = max(S_ajuste, 0)
	g double out_Cpriv = Cpriv
	g double out_CpubEsp = CpubInd
	g double out_CpubCol = CpubCol
	g double out_Tmen = Tmen
	g double out_InterOtor = InterOtor
	g double out_OtrosOtor = OtrosOtor
	g double out_IntraOtor = IntraNeg
	g double out_S = max(S, 0)
	g double out_AnclaRecorte = max(-S_ajuste, 0)
	egen double entradas = rowtotal(in_*)
	egen double salidas = rowtotal(out_*)
	g double balance = entradas - salidas
	g double deficit_cv = C - YL
	foreach v in C YL deficit_cv S S_hh S_ret S_def S_isflsh S_sinancla S_ajuste YA YA_hh YA_ret ImpProd YA_d8 Tmen Tmen_hh TmenRet TmenDef InterRec OtrosRec Remesas InterOtor OtrosOtor IntraPos IntraNeg Cpriv CpubInd CpubCol TpubEf TpubEsp TpubCol TpubISFLSH entradas salidas {
		g double pp_`v' = `v'/`PIBY'*100
	}
	foreach v of local pan_in {
		g double ppin_`v' = in_`v'/`PIBY'*100
	}
	foreach v of local pan_out {
		g double ppout_`v' = out_`v'/`PIBY'*100
	}
	g double balrel = abs(balance)/C
	summarize balrel, meanonly
	local balmax = r(max)
	local ncel = _N
}
local okpan = cond(`balmax' <= `tol', 1, 0)
if `okpan' == 0 {
	local ok = 0
	noisily _log aviso, tipo(GATE) texto("NTA panel: alguna celda grupo × sexo no balancea (|entradas − salidas|/C máx `=strtrim(string(`balmax', "%9.2e"))')") rojo
}
file open `fh' using `"`dirnta'/nta-panel-grupoedad-sexo.json"', write replace text
file write `fh' `"{"esquema":"nta-panel/v2","anio":`anio',"unidad":"MXN corrientes de `anio', sumas [fw=factor]","corte":"grupoedad x sexo","' _n
_ntanum "`PIBY'"
file write `fh' `""pib":{"anio":`anio',"valor":`r(n)',"unidad":"MXN corrientes de `anio'","escalar":"PIB (SCN.ado, BIE; registrado como NTAPIBY en NTA.do)","regla":"pctpib = valor / pib.valor x 100, calculado en Stata; la pagina transcribe"},"' _n
file write `fh' `""identidad":"Σ entradas = Σ salidas en cada celda: YL + (YA + ImpProd) + tau_pub_efectivo + tau_pub_especie + tau_pub_colectivo + tau_isflsh + (inter_recibido + remesas) + indemnizaciones_D72 + intra_recibido + desahorro + ancla_complemento = Cpriv + Cpub_especie + Cpub_colectivo + tau_menos + inter_otorgado + transferencias_a_otros_sectores_D7 + intra_otorgado + S + ancla_recorte; es la identidad del gate (C - YL - ImpProd - (tau_mas - tau_menos) - (YA - S_sinancla) - intra = 0) con S anclado (S = S_hh + S_ret + S_def + S_isflsh; S_hh = S_sinancla + S_ajuste) y el ajuste declarado como ancla; 8.17: YA incluye el retenido de las sociedades (YA_ret), tau_menos el retenido (TmenRet) y la deuda publica asignada (TmenDef), tau_isflsh el ahorro de las ISFLSH per capita","' _n
file write `fh' `""regla":"intra_recibido / intra_otorgado = sumas por persona de max(intra, 0) / max(-intra, 0); desahorro / S = -S / S de la celda segun su signo; ancla_complemento / ancla_recorte = S_ajuste / -S_ajuste de la celda segun su signo; S es el anclado (nta_anclaS=$nta_anclaS)","' _n
file write `fh' `""parametros":{"nta_anclaS":"$nta_anclaS","nta_YA":"$nta_YA","nta_cuotas":"$nta_cuotas","nta_d8":"$nta_d8","nta_anclaTau":"$nta_anclaTau","nta_alqu":"$nta_alqu","nta_tauCash":"$nta_tauCash","nta_otorgado":"$nta_otorgado","nta_mixto":"$nta_mixto","hub":"$hub","retenido_a_personas":"$retenido_a_personas","deficit_a_personas":"$deficit_a_personas","isflsh_regla":"$isflsh_regla","inter_hogar":"$inter_hogar","tolerancia":1e-9},"' _n
file write `fh' `""sexos":[{"s":"T","sexo":"Total"},{"s":"H","sexo":"Hombres"},{"s":"M","sexo":"Mujeres"}],"' _n
file write `fh' `""grupos":["'
forvalues g = 1/5 {
	local lab : label grupoedad `g'
	file write `fh' `"`=cond(`g' > 1, ",", "")'{"g":`g',"grupo":"`lab'"}"'
}
file write `fh' `"],"' _n
file write `fh' `""entradas":[{"id":"YL","etiqueta":"Ing laboral","variables":"YL"},{"id":"YA","etiqueta":"Ing activos + imp productos","variables":"YA + ImpProd (YA incluye YA_d8)"},{"id":"TpubEf","etiqueta":"τ⁺ efectivo","variables":"TpubEf"},{"id":"TpubEsp","etiqueta":"τ⁺ especie","variables":"TpubEsp"},{"id":"TpubCol","etiqueta":"τ⁺ colectivo","variables":"TpubCol"},{"id":"TpubISFLSH","etiqueta":"Ahorro ISFLSH atribuido","variables":"TpubISFLSH (B.8n S.15 per cápita)"},{"id":"InterRec","etiqueta":"Inter hogar recibido","variables":"InterRec + Remesas"},{"id":"OtrosRec","etiqueta":"Indemnizaciones de seguros","variables":"OtrosRec (D.72 de S.12)"},{"id":"IntraRec","etiqueta":"Intra hogar recibido","variables":"sum max(Intra, 0)"},{"id":"Desahorro","etiqueta":"Desahorro","variables":"max(-S, 0)"},{"id":"AnclaComplemento","etiqueta":"Ancla S14 complemento","variables":"max(S_ajuste, 0)"}],"' _n
file write `fh' `""salidas":[{"id":"Cpriv","etiqueta":"C privado","variables":"Cpriv"},{"id":"CpubEsp","etiqueta":"C público especie","variables":"CpubInd"},{"id":"CpubCol","etiqueta":"C colectivo","variables":"CpubCol"},{"id":"Tmen","etiqueta":"τ⁻","variables":"Tmen"},{"id":"InterOtor","etiqueta":"Inter hogar otorgado","variables":"InterOtor"},{"id":"OtrosOtor","etiqueta":"Transferencias a otros sectores","variables":"OtrosOtor (D.751 + D.71 + D.752 + D.759 pagadas)"},{"id":"IntraOtor","etiqueta":"Intra hogar otorgado","variables":"sum max(-Intra, 0)"},{"id":"S","etiqueta":"S","variables":"max(S, 0)"},{"id":"AnclaRecorte","etiqueta":"Ancla S14 recorte","variables":"max(-S_ajuste, 0)"}],"' _n
file write `fh' `""celdas":["' _n
forvalues i = 1/`ncel' {
	local g = grupoedad[`i']
	local s3 = sexo3[`i']
	local lab : label grupoedad `g'
	local sc = cond(`s3' == 0, "T", cond(`s3' == 1, "H", "M"))
	local sl = cond(`s3' == 0, "Total", cond(`s3' == 1, "Hombres", "Mujeres"))
	file write `fh' `"`=cond(`i' > 1, ",", "")'{"g":`g',"s":"`sc'","grupo":"`lab'","sexo":"`sl'","pob":`=trim(string(pobw[`i'], "%20.0f"))'"'
	foreach v in C YL deficit_cv S S_hh S_ret S_def S_isflsh S_sinancla S_ajuste YA YA_hh YA_ret ImpProd YA_d8 Tmen Tmen_hh TmenRet TmenDef InterRec OtrosRec Remesas InterOtor OtrosOtor IntraPos IntraNeg Cpriv CpubInd CpubCol TpubEf TpubEsp TpubCol TpubISFLSH entradas salidas {
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
	file write `fh' `"},"pctpib":{"'
	local k = 0
	foreach v in C YL deficit_cv S S_hh S_ret S_def S_isflsh S_sinancla S_ajuste YA YA_hh YA_ret ImpProd YA_d8 Tmen Tmen_hh TmenRet TmenDef InterRec OtrosRec Remesas InterOtor OtrosOtor IntraPos IntraNeg Cpriv CpubInd CpubCol TpubEf TpubEsp TpubCol TpubISFLSH entradas salidas {
		local ++k
		_ntanum "pp_`v'[`i']"
		file write `fh' `"`=cond(`k' > 1, ",", "")'"`v'":`r(n)'"'
	}
	file write `fh' `","entradas_flujos":{"'
	local k = 0
	foreach v of local pan_in {
		local ++k
		_ntanum "ppin_`v'[`i']"
		file write `fh' `"`=cond(`k' > 1, ",", "")'"`v'":`r(n)'"'
	}
	file write `fh' `"},"salidas_flujos":{"'
	local k = 0
	foreach v of local pan_out {
		local ++k
		_ntanum "ppout_`v'[`i']"
		file write `fh' `"`=cond(`k' > 1, ",", "")'"`v'":`r(n)'"'
	}
	_ntanum "balance[`i']"
	file write `fh' `"}},"balance":`r(n)'}"' _n
}
file write `fh' `"],"' _n
* NTA-4: cifras nacionales en % del PIB (las que /NTA escribe en bn desde nta-grupoedad.json, más los hubs del v3); mismas fuentes que §6.2 *
file write `fh' `""nacional_pctpib":{"'
local k = 0
foreach par in "S_sin_ajuste `S_micro'" "AhorroHog `AhorroHog'" "S_final `S_nac'" "S_ajuste scalar(NTASAjusteNac)" "ancla_recorte `rec_tot'" "ancla_complemento `comp_tot'" "ancla_neto `ajuste_neto'" ///
	"YA_motor `YA_motor_tot'" "YAHogS14 `YAHogS14'" "B2n `ExNOpHogS14'" "tercio_B3n `MixNHogS14'/3" "D4_neto `RentaPropHogNeta'" ///
	"YL scalar(NTAYL0)" "YA scalar(NTAYA0)" "ImpProd scalar(NTAImpProd0)" "C scalar(NTAC0)" "TpubEf scalar(NTATpubEf0)" "Tmen scalar(NTATmen0)" "OyE `OyE'" ///
	"InterOtor scalar(NTAInterOtor0)" "InterRec scalar(NTAInterRec0)" "Remesas scalar(NTARemesas0)" "Intra_bruto_recibido scalar(NTAIntraPos1)+scalar(NTAIntraPos2)+scalar(NTAIntraPos3)+scalar(NTAIntraPos4)+scalar(NTAIntraPos5)" ///
	"Cpriv scalar(NTACprivNac)" "ConHogS14_P3 `ConHogS14'" "ConHog `ConHog'" "Cpub scalar(NTACpubNac)" "individual_D63 scalar(NTACpubIndNac)" "colectivo scalar(NTACpubColNac)" ///
	"CapFij `CapFij'" "PIN `PIN'" "ROWProp `ROWProp'" "ROWTrans `ROWTrans'" ///
	"hub_Ing_nacional `IngNac_tot'" "hub_Gobierno scalar(NTATmen_hh0)+`OyE'+max(-`BG',0)" "hub_Activos `Spos_tot'+`rec_tot'+`Sneg_tot'+max(-`ajuste_neto',0)" "hub_Transferencias_efectivo scalar(NTATpubEf0)" ///
	"Futuro `Spos_tot'" "Desahorro `Sneg_tot'" "Deficit_publico max(-`BG',0)" "Otras_transf_privadas max(`BF',0)" ///
	"hub_INBD `IngDisp'" "S_personas `S_pers'" "B8nS1 `B8nS1'" "S_ret scalar(NTASRetNac)" "S_def scalar(NTASDefNac)" "S_isflsh scalar(NTASISFLSHNac)" "YA_ret scalar(NTAYARetNac)" "Tmen_hh scalar(NTATmen_hh0)" "OtrosRec scalar(NTAOtrosRecNac)" "OtrosOtor scalar(NTAOtrosOtorNac)" ///
	"v4_hub `v4hub'" "v4_hogares_B5n `v4hogB5n'" "v4_sociedades_B5n `v4socB5n'" "v4_gobierno_B5n `v4gobB5n'" "v4_isflsh_B5n `v4isfB5n'" "v4_remesas `v4rem'" "v4_vintage_hub `v4vhub'" "v4_vintage_usos `v4vsink'" "v4_financiamiento `v4fin'" "v4_futuro `v4fut'" "v4_por_identificar `v4pid'" "v4_ajuste_S14 `v4aj'" "v4_colectivo `v4col'" "v4_mundo_B9 `B9Row'" {
	local ++k
	gettoken nm ex : par
	_ntanum "(`ex')/`PIBY'*100"
	file write `fh' `"`=cond(`k' > 1, ",", "")'"`nm'":`r(n)'"'
}
file write `fh' `"},"' _n
* NTA-4: los mismos totales del v3 en MXN (hubs, Futuro, Desahorro y el ancla S.14 por separado y neta), para que la página los escriba en ambas unidades;
* 8.17: y los del v4 (hub INBD, sectores, financiamiento, futuro, por identificar, vintage, ajuste S.14, Σ S de las personas) *
file write `fh' `""v3_mxn":{"'
local k = 0
foreach par in "hub_Ing_nacional `IngNac_tot'" "hub_Gobierno scalar(NTATmen_hh0)+`OyE'+max(-`BG',0)" "hub_Activos `Spos_tot'+`rec_tot'+`Sneg_tot'+max(-`ajuste_neto',0)" "hub_Transferencias_efectivo scalar(NTATpubEf0)" ///
	"Futuro `Spos_tot'" "Desahorro `Sneg_tot'" "ancla_recorte `rec_tot'" "ancla_complemento `comp_tot'" "ancla_neto `ajuste_neto'" "Colectivo scalar(NTACpubColNac)" ///
	"v4_hub `v4hub'" "v4_hogares_B5n `v4hogB5n'" "v4_sociedades_B5n `v4socB5n'" "v4_gobierno_B5n `v4gobB5n'" "v4_isflsh_B5n `v4isfB5n'" "v4_remesas `v4rem'" "v4_vintage_hub `v4vhub'" "v4_vintage_usos `v4vsink'" "v4_financiamiento `v4fin'" "v4_futuro `v4fut'" "v4_por_identificar `v4pid'" "v4_ajuste_S14 `v4aj'" "v4_colectivo `v4col'" "v4_mundo_B9 `B9Row'" "S_personas `S_pers'" "B8nS1 `B8nS1'" "S_ret scalar(NTASRetNac)" "S_def scalar(NTASDefNac)" "S_isflsh scalar(NTASISFLSHNac)" "YA_ret scalar(NTAYARetNac)" {
	local ++k
	gettoken nm ex : par
	_ntanum "(`ex')"
	file write `fh' `"`=cond(`k' > 1, ",", "")'"`nm'":`r(n)'"'
}
file write `fh' `"},"' _n
file write `fh' `""gates":{"celdas":`ncel',"balance_max_rel":`=trim(string(`balmax', "%12.4e"))',"tolerancia":1e-9,"ok":`okpan'},"' _n
file write `fh' `""procedencia":{"modulo":"01_modulos/NTA.do v1.4 (NTA-4)","base":"la misma cuenta por persona que users/$id/NTA/nta-persona.dta, agregada por grupoedad x sexo [fw=factor]; pctpib con el escalar PIB de SCN.ado","anclas":"SCN/LIF/PEF `anio' (escalar); S.14 de CSI_115.xlsx y S.1 de CSI_103.xlsx via SCN.ado","stata":"`c(stata_version)' `c(edition_real)'","generado_el":"`fecha' $S_TIME"}}"' _n
file close `fh'
noisily _log aviso, tipo(GATE) texto("NTA panel grupo × sexo: `ncel' celdas; |entradas − salidas|/C máx `=strtrim(string(`balmax', "%9.2e"))' → `=cond(`okpan', "OK", "ROJO")'")
quietly use `per2', clear



* log legible (2026-11-09): nta-identidad.txt a 110 columnas; títulos, notas y gates largos se envuelven con sangría; mismos valores *
noisily _log envuelve, archivo("`dirnta'/nta-identidad.txt")

**********************************
**# 8. Guardar la cuenta por persona
**********************************
quietly {
	keep folioviv foliohog numren factor edad sexo grupoedad quinq decil nta_hhid nta_jefe nta_adulto ///
		YL ImpProd YA YA_base YA_motor YA_d8 YA_ajuste ALQ Cpriv Cpub CpubInd CpubCol CpubEduc CpubSalud CpubRestoInd C ///
		Tmen TmenDir TmenCuotas TmenInd TmenFuera nta_ISRAS nta_ISRPF nta_CUOTAS nta_ISRPM nta_OTROSK nta_IVA nta_ISAN nta_IEPSNP nta_IEPSP nta_IMPORT ///
		Tpub TpubEf TpubEsp TpubCol TpubPens TpubPAM TpubProg InterRec Remesas InterOtor S S_sinancla S_ajuste Intra Resid ///
		YA_hh YA_ret S_hh S_ret S_def S_isflsh Tmen_hh TmenRet TmenDef TmenDefTau TmenD59 TpubISFLSH TpubEfPub TpubEfPriv OtrosRec OtrosOtor RecIndem OtorISFLSH OtorPrimas OtorRemEnv OtorD759 ///
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
	char _dta[nta_parametros] "nta_anclaS=$nta_anclaS nta_YA=$nta_YA nta_cuotas=$nta_cuotas nta_d8=$nta_d8 nta_anclaTau=$nta_anclaTau nta_alqu=$nta_alqu nta_tauCash=$nta_tauCash nta_otorgado=$nta_otorgado nta_mixto=$nta_mixto$cuad_params"
	char _dta[nta_B8nS1] "`B8nS1'"
	compress
	save `"`dirnta'/nta-persona.dta"', replace
}
noisily _log aviso, tipo(Salida) texto("users/$id/NTA/: nta-persona.dta, nta-grupoedad.json, nta-quinquenio-sexo.json, nta-identidad.txt, nta-panel-grupoedad-sexo.json")
noisily _log aviso, tipo(Salida) texto("users/$id/SankeyNTA/: sankey-v2-grupoedad.json, sankey-v3-grupoedad.json, sankey-v4-economia.json") ref("runbook §12")
if `ok' == 0 {
	noisily _log aviso, tipo(GATE) texto("NTA: algún gate interno quedó ROJO (ver arriba); 05_scripts/test-nta-identidad.sh lo confirma") rojo
}
timer off 14
timer list 14
noisily _log tiempo, timer(14) texto("NTA")
