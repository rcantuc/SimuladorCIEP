# CUAD-2 — Sankey de la economía completa: Tabla 2 (principio B) con todas las partidas de S.11, S.12, S.13, S.15 y S.2, nodos, identidades y parámetros (8.17)

**Fecha:** 2026-11-07 · **Sesión:** 8.16/8.17-memo (memo; ningún `.do`/`.ado`/JSON/número publicado cambia) · **Base:** `master` `9005ed3` (v8.15.3; baseline `v8.15.0`; hub `Ing nacional` = 27,743.270 bn = **82.405 %** del PIB) · **Estado:** **firmado** por Ricardo el 2026-11-07 (`CUAD-1-2-firma.md` §A 16, 19–23 y §B 17–18; fundida en §4.0) e **implementado en la sesión 8.17** (v8.17.0, rama `sesion/8.17`; §4.0 lleva los valores firmados, §7 los gates con su resultado medido, §8 los FLAGs cerrados y abiertos). Esqueleto de partida: CONC-1 §4 (`historico/conc-1-scn-sankey-2026-10-30.md`, sobre v8.13.0; sus 13 decisiones D1–D13 quedaron firmadas en CUAD-0 §4 salvo las que aquí se vuelven parámetro). Nada de lo que aquí se propone se ejecuta en esta sesión.

## Encabezado

| Campo | Valor |
|---|---|
| `modulo` | `Sankey` (NTA v3 `SankeyNTA/sankey-v3-grupoedad.json`, `NTA.do` §7b–§7c; «PIB demográfico» `visualizations/Sankey.do`; fiscal `SankeySF.do`) |
| `archivo` | `01_modulos/visualizations/Sankey.do`, `01_modulos/NTA.do` @ `9005ed3` |
| `orden_en_SIM` | después de `Households` y `NTA`; `Sankey.do` lee `master/2024/households.dta` y los escalares CSI de `SCN.ado` |
| `desde_version` | v8.15.0 (filas de sector «Otros sectores», `CUADRATURA`; `oye_en_hub = off`) |
| `ultima_decision` | 2026-10-31 (CUAD-0 §4.0 C: «excedente retenido a personas (8.17)») |
| `sello` | **amarillo**: todas las partidas de sector tienen celda CSI (vintage BIE vs CSI declarado); rojo donde la regla a persona es un proxy (`d4_relativo`) |

Convención, principios, sellos y marcas de fuente como en CUAD-0 y CUAD-1 (`CSI_1xx f.N` = tabulado INEGI 2024, columna U/A o R/P; `BIE` = `master/SCN.dta`; `I` = `-datos/users/ricardo/NTA/nta-identidad.txt` 2026-11-03; `V3` = `SankeyNTA/sankey-v3-grupoedad.json` leído con `D/v3-enlaces.py`; `C1 §x` = CONC-1; `H`/`N`/`S l.N` = `Households.do`/`NTA.do`/`Sankey.do`). Regla: **P** = propiedad (∝ `ing_d4_rel`, el relativo de D.4 de CUAD-0, sello rojo) · **I** = incidencia (quien recibe o paga) · **C** = per cápita · **E** = perfil por edad (matrícula, salud, consumo) · **—** = no llega a personas (sector).

## Resumen

1. **El hub de la economía completa es el INBD: 27,459.038 bn = 81.561 % del PIB (BIE 724037, `escalar mxn IngDisp`), exacto.** Entra como Σ de los saldos primarios netos de los cinco sectores (B.5n S.1 26,188.047, CSI_103 f.110) + transferencias corrientes netas del mundo (1,186.091, BIE) + vintage BIE−CSI (84.901). El hub actual (27,743.270) lo excede en **284.232 bn**: tiene D.8 (1,270.277), los impuestos a los productos como ingreso de hogares (2,175.907) y el desbalance de transferencias de la ENIGH (193.653) que el INBD no cuenta ahí, y le faltan S.11+S.12 (953.904), S.13 (1,594.102), S.15 (116.767), D.442 (605.932) y el vintage (84.901). La tabla del Δ cierra al peso (§Δ).
2. **Tabla 2 completa (§5): 41 partidas de S.11, S.12, S.13, S.15 y S.2** con valor CSI, regla, relativo concreto y si hoy llegan a personas. Hoy llegan (con edad) solo D.62 y D.759 del gobierno (dentro de τ⁺ efectivo), D.63 (especie), P.32 (per cápita), D.8 (∝ YL de cotizantes), D.752 (remesas) y los impuestos a productos (∝ Cpriv); lo demás es «Otros sectores → Ing nacional» sin edad (`CUADRATURA`: 2.833 + 4.735 + 0.347 + 1.800 + 2.782 + 0.252 = 12.749 % del PIB) o no está (intereses de la deuda, D.5 de sociedades, D.61 a S.12/S.11, B.8n y B.9 de cada sector).
3. **Tres decisiones son parámetros:** `retenido_a_personas` (B.5n/B.8n de S.11+S.12 ∝ `ing_d4_rel` o nodo de sector), `deficit_a_personas` (B.8n S.13 −1,157.268 a personas per cápita, ∝ τ⁻ o nodo «Financiamiento»), `isflsh_regla` (sector propio, fundido en hogares, o D.63 por perfil). Con las dos primeras en `on`, **el ahorro de las personas suma el B.8n nacional** (−308.425 CSI; −276.687 BIE): la economía desahorra y el Sankey lo tiene que decir con un nodo fuente.
4. **Lo que cierra por construcción:** cada nodo de sector conserva (inflows = outflows) con las filas de la CSI (§6: Hogares 24,012.079, Gobierno 2,750.579, S.12 3,060.081, S.11 −2,903.413, ISFLSH 449.745 = B.6n de cada cuadro). Lo que **no** cierra con la CSI y se declara: el desbalance ENIGH de transferencias privadas (193.653: neto cero en S.14), D.759 de S.13 a hogares (1,612.421 pagados vs 1,605.191 recibidos: −7.230) y el vintage en tres sitios (NNI 84.901; transferencias del mundo 5.067; CCF 0.776; ConGob 8.480).
5. **Del JSON v3 (35 nodos / 99 enlaces) sobreviven sin cambio 25 nodos y 64 enlaces**; cambian de lugar o nombre 4 nodos (`Ing nacional` → INBD; `Derechos de pensión D8` → S.12 → Hogares; `Impuestos a productos` → recurso de Gobierno; `Empresas públicas` → dentro de S.11/S.13); desaparecen 4 (`Déficit público`, `Desahorro`, `Ajuste a cuentas nacionales S14`, `Otras transferencias privadas`); nuevos 17 (§6.4).

---

## §1 Propósito

Dibujar todo el PIB (BIE) como flujo de personas por edad → sectores institucionales → personas por edad, con el INBD como único pivote y cada partida de sector con regla declarada a persona o con nodo propio, de modo que el consumo, los impuestos, las transferencias y el ahorro de cada sector cuadren con la CSI 2024 y el `CUADRATURA` de `output.txt`.

## §2 Entradas

| Base | Fuente | Vintage | Variables clave | Llave | Sello |
|---|---|---|---|---|---|
| CSI 2024 S.1, S.11, S.12, S.13, S.14, S.15, S.2 (`CSI_103/106/109/112/115/118/121`) | INEGI, asset `scn-congelado-2024.zip` (`scn_vintage.csi`) | 2024 revisada | filas 20–29 (producción, CCF), 35–64 (generación), 95–110 (D.4, B.5n), 114–153 (D.5, D.61, D.62, D.7, B.6n), 157–171 (D.63, P.3, D.8, B.8n), 188–190 (P.5), 265 (B.9) | cuadro + fila + columna | amarillo (vintage ≠ BIE) |
| BIE (`master/SCN.dta`) | INEGI | 2024 definitivo | `PIB`, `CapFij`, `PIN`, `ROWRem/Prop/Trans`, `IngDisp`, `ConHog`, `ConGob`, `ComprasN`, `AhorroN`, series de consumo | `anio` | amarillo |
| `master/2024/households.dta`, `users/<id>/NTA/nta-persona.dta` | motor v8.15.3 | corrida 2026-11-03 | `Yl`, `Yk`, `ing_estim_alqu`, `ing_d4_rel`, `gas_pc_*`, `cuotasTP`, `ISR_*`, `YA_d8`, `Tpub*`, `S` | `folioviv foliohog numren` | según CUAD-0/CUAD-1 |
| LIF/PEF 2024 | SHCP | asset | OyE (1,601.824), ISR por régimen, cuotas, PEF pensiones y programas | `anio` | verde |

## §3 Procedimiento (hoy, v8.15.3)

| # | Qué hace | Qué conserva | Dónde |
|---|---|---|---|
| 1 | `Sankey.do` eje 1: grupos → `Ing laboral`, `Ing capital`, `Alquiler propio`; `El mundo → Remesas`; filas de sector → «Otros sectores»; compras netas | PIB BIE = YL + YA + D.442 + B.5n S.11+S.12 + B.5n S.13 + B.5n S.15 + CCF + ROW + vintage (gate 1e-9, `H` §9.1) | `S l.45–122` |
| 2 | Eje 4: 7 categorías de consumo → grupos; bienes públicos (educación, salud, resto); `Ahorro → Futuro` = `AhorroN` BIE; renta primaria al exterior | usos = fuentes del eje 1 | `S l.128–195` |
| 3 | NTA v3: hub `Ing nacional` = YL + YA + ImpProd + D.8 + Remesas + otras transf. privadas; `Gobierno` recibe τ⁻ y OyE y paga efectivo, especie, colectivo; `Activos` → `Futuro`/categorías; `Déficit público` y `Desahorro` como fuentes | identidad NTA por persona a 1e-9; Σ S = B.8n S.14 con ancla multiplicativa (0.8983) | `N` §7b–§7c; `I` |

## §4 Decisiones: parámetros de 8.17

| Parámetro | Propuesto | Alternativas | FLAG | Qué cambia si se mueve |
|---|---|---|---|---|
| `hub` | `inbd` | `ing_nacional` (hoy) | «hub = INBD BIE 27,459.038 = 81.561 % PIB» | Con `ing_nacional` el hub es el lado hogares (82.405 %, Resumen 1). Con `inbd` entran S.11+S.12, S.13, S.15, D.442 y el vintage como fuentes; salen D.8, ImpProd y el desbalance ENIGH (se colocan donde el SCN los pone: §6). |
| `retenido_a_personas` | `off` | `on` | «B.5n y B.8n de S.11 + S.12 en nodo de sector» | `off`: nodo «Sociedades» con B.5n 953.904 → hub y, del lado de usos, B.8n −2,903.413 (S.11) y +1,789.804 (S.12), S.11 financiado. `on` (NTA canónico, Lee–Mason; `C1` D1): B.5n S.11+S.12 entra a `Ing capital` por edad ∝ `ing_d4_rel` (regla P, sello rojo) y su ahorro a las personas con el mismo perfil; Σ S de personas = B.8n S.14 + S.11 + S.12 = 787.417. |
| `deficit_a_personas` | `off` | `per_capita`, `tau_menos` | «B.8n S.13 −1,157.268 a personas» | `off`: «Financiamiento (deuda)» → Gobierno 1,157.268 (B.8n) o 2,156.464 (B.9, con P.5n 602.257). `per_capita`: desahorro del gobierno repartido C a todas las personas (cada quien «debe» 8,880 MXN: −1,157.268 / 130.326 M); `tau_menos`: ∝ τ⁻ de cada persona (quien paga impuestos hoy paga la deuda mañana). Con `on` (cualquiera) y `retenido_a_personas = on`: Σ S de personas = B.8n S.1 −308.425 (CSI) = −276.687 BIE + vintage. |
| `isflsh_regla` | `sector` | `hogares`, `d63_perfil` | «ISFLSH como sector» | `sector`: 4 enlaces (B.5n 116.767 → hub; D.751 274.349 ← Hogares; D.63 388.320 → categorías por perfil; B.8n 61.425 → Futuro). `hogares`: fundido en S.14 como el BIE (hogares e ISFLSH): el consumo privado queda 23,769.649 y el ancla de CUAD-1 cambia. `d63_perfil`: solo el D.63 llega (E, mismo perfil que la especie pública) y el resto es nodo. |
| `circuito_d442` | `neto` | `bruto` | «D.442 ↔ D.614 neteado» (= `cuotas_d614` de CUAD-0) | `neto`: la fila «Fondos de pensión D.442» 605.932 entra al hub como sector y no hay enlace de vuelta. `bruto`: S.12 → Hogares D.442 605.932 (renta de inversión sobre derechos de pensión, ∝ `cuotasTP`) y Hogares → S.12 D.614 605.932 (`C1` D5). Mismos totales; dos enlaces más. |
| `vintage_nodo` | `si` | `absorbido` | «Vintage BIE vs CSI como nodo» (`C1` D3) | `si`: nodo fuente 84.901 (NNI) + 5.067 (transferencias del mundo) al hub, y 0.776 (CCF) + 8.480 (ConGob) + 49.749 (consumo de residentes) del lado de usos. `absorbido`: se suma a `Depreciación` o al sector mayor; esconde 0.25 % del PIB. |
| `bruto_neto` | `neto` | `bruto` | «PIN como origen; CCF como sink» (`C1` D4) | `neto` (hoy, NTA): PIB → Depreciación 6,457.576 → el resto es PIN. `bruto`: CCF por sector (S.11 4,634.128; S.12 62.735; S.13 8.993; S.14 1,721.094; S.15 31.402; CSI f.28) viaja hasta «Formación de capital» (P.5b). |
| `financiamiento` | `un_nodo_4` | `un_nodo_2` (lado hogares), `por_sector` | «Financiamiento: deuda y venta de activos» (`C1` §2.4, D8) | `un_nodo_4`: un nodo fuente con S.11 1,416.744 + S.13 2,156.464 (B.9 < 0) y, del otro lado, préstamo neto S.12 1,780.446 + S.14 1,450.512 + S.15 90.408 + Mundo 251.842 (Σ = 3,573.208 a cada lado). `un_nodo_2`: solo Gobierno y Desahorro de hogares (hoy). |
| `discrepancia_gasto` | `fuera` | `nodo` | «Discrepancia estadística del gasto −1,616.168» (`C1` D9) | Solo entra si se dibuja la formación de capital (P.5): FBCF + existencias 8,052.454 vs ahorro bruto 6,180.888 − déficit externo. Con `fuera` el Sankey es cuenta corriente (INBD = C + B.8n). |

### §4.0 — La firma (Ricardo, 2026-11-07; `CUAD-1-2-firma.md`): lo que 8.16b implementa de este memo

Donde la firma difiere de este memo, manda la firma. La firma de 2026-11-07 decide CUAD-1 (Cuadratura II) y, de este memo, solo lo que 8.16b necesita para cerrar las anclas de CUAD-1; los parámetros de §4 (`hub`, `retenido_a_personas`, `deficit_a_personas`, `isflsh_regla`, `circuito_d442`, `vintage_nodo`, `bruto_neto`, `financiamiento`, `discrepancia_gasto`) siguen **pendientes de firma** para 8.17.

Lo que 8.16b deja listo para el Sankey de la economía completa (v8.16.0):

| Partida de la Tabla 2 | Qué hace 8.16b | Dónde |
|---|---|---|
| P.3 S.15 (ISFLSH, 388.320) y vintage BIE−CSI del consumo de residentes (49.749) | dejan de estar dentro del consumo de personas: `consumo_ancla = p3_s14` reancla Σ Cpriv a P.3 S.14 y ambas quedan declaradas como filas de sector (`ExpVintageCons`, escalar `ConISFLSH` de `SCN.ado`) | `Expenditure.do` §4.1–4.2; `SCN.ado` (`ConISFLSH`) |
| D.61 recibido por S.13 (683.959), S.12 (1,455.102 con D.614), S.11 (193.870) y S.15 (2.091) | `cuotas_por_sector = on`: NTA reparte las cuotas de las personas por sector receptor con la celda f.117 R/P de cada cuadro (`nta_CUOTAS_S13`, `_S12` sin D.614, `_S11`, `_S15`; relativos: seguros sociales de afiliados a IMSS/ISSSTE, retiro + vivienda, cuotas de otros regímenes); los nodos «Hogares → Afores/aseguradoras» y «→ planes de empleadores» se dibujan en 8.17 | `NTA.do` §4.6; `SCN.ado` (`CuotasGobR`, `CuotasFinR`, `CuotasNoFinR`, `CuotasISFLSHR`); `Households.do` §6 (`cuotasRCV`, `cuotasViv`, `cuotasSeg`) |
| D.5 pagado por S.14 (1,540.050) y por S.11 + S.12 (1,188.648) | `isr_personas_ancla = d51_s14`: el τ⁻ directo de las personas se ancla a D.51 S.14 (1,518.912) y el ISR de sociedades a D.51 S.11 + S.12 (1,165.676); la fila «LIF vs CSI por sector» queda en `nta-identidad.txt` (D.59 = D.5 − D.51 es predial y tenencia, fuera del consumo desde 8.16b) | `NTA.do` §4.6; `SCN.ado` (`D51HogS14`, `D51NoFin`, `D51Fin`) |
| ISR de sociedades a personas (regla P) | `isrpm_incidencia = propiedad`: en el fiscal el ISR PM se reparte ∝ `ing_d4_rel` (lo que `retenido_a_personas = on` usará para B.5n/B.8n de S.11 + S.12); `ISRPMTE` se mide sobre B.2n S.11 + S.12 (CSI f.63, escalares `B2nNoFin`/`B2nFin` de `SCN.ado`) | `Households.do` §11.3; `TasasEfectivas.ado` §4.1 |
| Cuota social y aportaciones federales (`cuotasF`) | fuera de las cuotas de las personas: son S.13 → S.13 (D.73/D.62), como pide la Tabla 1b de CUAD-1 | `Households.do` §6 |
| Fila τ⁺ vs D.62 + D.7 netas (+461.011) | **sigue abierta**: donativos a ISFLSH, primas, remesas enviadas y D.759 privado son de este memo (`isflsh_regla`, S.12); por eso la brecha de Σ S sin ancla de 8.16b la lleva íntegra (+24.5 %; CUAD-1 §7, `nta-identidad.txt` cuadro 3) y `NTA.do` lleva `brecha_max = 30 %` con FLAG hasta que este memo la cierre | 8.17 |

### §4.0 bis — La firma de 8.17 (Ricardo, 2026-11-07; `CUAD-1-2-firma.md` §A 16, 19–23 y §B 17–18) y lo que la sesión 8.17 implementó (v8.17.0)

| Parámetro (`SIM.do` §0.8c) | Firmado | Implementado en `NTA.do` | Alternativas que corren con FLAG |
|---|---|---|---|
| `hub` | `inbd` | §7d: hub = `IngDisp` BIE (724037 − CCF) = 27,459.038 bn = 81.561 % del PIB, exacto; Σ B.5n de los sectores (celdas CSI) + ROWTrans + vintage NNI 84.901 | `ing_nacional`: el v4 no se emite, el v3 sigue |
| `retenido_a_personas` | **`on`** (§B 17) | §4.7b: `YA_ret` = B.5n S.11 + S.12 (953.904) ∝ `ing_d4_rel`; `TmenRet` = B.5n − B.8n de S.11 + S.12 (2,067.513: ISR de sociedades, D.8, transferencias netas) ∝ `ing_d4_rel`; `S_ret` = B.8n S.11 + S.12 (−1,113.609). Nodo «Sociedades» en medio: entra de los grupos ∝ `ing_d4_rel`, sale al hub | `off`: «Sociedades» fuente sin edad; Σ S de personas = B.8n S.14 + S.13 + S.15 |
| `deficit_a_personas` | **`per_capita`** (§B 18) | §4.7b: `TmenDef` = −B.8n S.13 (1,157.268) por igual a cada persona y `S_def` = −`TmenDef`; la alternativa ∝ τ⁻ del hogar se calcula (`TmenDefTau`) y se imprime por grupo en el cuadro 1 de `nta-identidad.txt` (déf∝τ⁻: 0–4 −2.1, 5–17 −24.0, 18–24 −93.0, 25–64 −960.0, 65+ −78.1 vs per cápita −66.6, −254.3, −129.0, −587.5, −119.9) | `tau_menos`, `off` |
| `isflsh_regla` | `sector` | nodo «ISFLSH» (B.5n 116.767 → hub) e «ISFLSH ingreso disponible» (donativos 274.349, saldo, D.751 de S.11/S.12/S.13 → D.62 4.182 a hogares, D.63 388.320 a Otros gastos, B.8n 61.425 a Futuro); el ahorro de las ISFLSH llega a personas per cápita (`TpubISFLSH`, `S_isflsh`) para que Σ S de personas = B.8n S.1 (decisión de la sesión, a confirmar: las ISFLSH sirven a los hogares) | `hogares`, `d63_perfil`: no implementados (FLAG, se dibuja sector) |
| `circuito_d442` | `neto` | «Fondos de pensión D442» → Hogares 605.932; cuotas a Afores sin D.614 (849.170); el circuito viaja dentro de «Sociedades saldo primario» | `bruto`: cuotas a S.12 con D.614 (1,455.102) |
| `vintage_nodo` | `si` | fuente «Vintage BIE vs CSI» → hub 84.901 (= NNI BIE − B.5n S.1); sink «Vintage BIE vs CSI usos» 83.400 (= INBD − Σ B.6n CSI − residuo D.759 6.568); el vintage del consumo (49.749) y de ConGob (8.480) no se dibujan: el v4 usa P.3 por sector de la CSI y se declaran como FLAG | `absorbido`: ambos se suman a Hogares |
| `bruto_neto` | `neto` | hub neto de CCF; la CCF no se dibuja | `bruto`: no implementado (FLAG) |
| `financiamiento` | `un_nodo_4` | «Financiamiento deuda y venta de activos» 2,406.884 = desahorro de los grupos 136.007 + S.11 + S.12 1,113.609 + S.13 1,157.268; gate de la CSI Σ B.9 < 0 = Σ B.9 > 0 + Mundo (3,573.208) impreso | `por_sector` (tres nodos), `un_nodo_2` (FLAG: no conserva con S.11, se dibuja un_nodo_4) |
| `discrepancia_gasto` | `fuera` | cuenta corriente: INBD = Σ P.3 + Σ B.8n (gate) | `nodo`: no implementado (FLAG) |
| `inter_hogar` (nuevo, decisión de la sesión) | `balance` | lo otorgado entre hogares (173416 + 133030: 83.7 bn) × 3.3745 = lo recibido (282.4): D.75 entre residentes neto cero como en el SCN; cierra los 193.653 de «Otras transferencias privadas» (sello rojo: la ENIGH subreporta lo dado) | `enigh`: sin escalar, el desbalance queda en la brecha de S |

La fila τ⁺/inter/remesas vs D.62 + D.7 netas (+461.0 en 8.16b) se cierra por sector en §4.6–§4.9 de `NTA.do`: D.59 (21.138) ∝ alquiler imputado + vehículos a τ⁻; D.72 indemnizaciones (168.468) ∝ gasto en seguros a τ⁺; D.751 donativos a ISFLSH (274.349) ∝ gastohogar 173417 con factor 54.01 (FLAG 35: la ENIGH solo ve 5.1 bn); D.71 primas netas (116.394) ∝ `gas_pc_DiveT`; D.752 remesas enviadas (23.889) per cápita de adultos con ingreso (FLAG 36); D.759 pagada (23.578) ∝ YL + YA («Por identificar»); prestaciones privadas (442.344) separadas de las públicas ∝ pensiones. Resultado medido (corrida de la sesión): **Σ S sin ancla 1,881.607 vs B.8n S.14 1,901.026 = −19.419 (−1.0 %; esperado −0.9 %)** = ImpProd − τ⁻ indirectos LIF (−17.0) + vintage de remesas D.752 CSI vs ROWTrans BIE (−2.4); `nta_anclaS = auto` → multiplicativo con factor 1.0103 y el nodo «Ajuste a cuentas nacionales S14» del v4 es un sink de 19.4 bn (0.058 % del PIB). **Σ S de las personas = −308.425 = B.8n S.1** al peso (gate 1e-9). Consumo colectivo = P.32 S.13 (1,896.999) en vez de ConGob − D.63 (1,517.160: FLAG 15 cerrado).

## §5 Tabla 2 — Principio B completo: una fila por partida de S.11, S.12, S.13, S.15 y S.2

Valor = CSI 2024 (U/A o R/P del cuadro del sector; bn). Relativo = la variable del motor con la que se repartiría a personas. «Hoy» = qué hace v8.15.3 con la partida y la cifra que `CUADRATURA` imprime (% del PIB) cuando viaja como fila de sector. Las filas en **negrita** son las que el hub `inbd` añade o quita.

### S.11 Sociedades no financieras (CSI_106)

| Partida | Valor | Regla | Relativo concreto | Hoy (v8.15.3) | Propuesto 8.17 | Sello |
|---|---:|---|---|---|---|---|
| B.1n valor agregado neto | 10,270.752 | — | — | no se dibuja (el PIB entra por ingresos) | nodo «PIB» → «Sociedades NF» solo con `bruto_neto = bruto` | amarillo |
| D.1 pagada (f.35) | 4,560.099 | I | ya es ingreso de personas: dentro de D.1 S.14 (`ing_subor`) | llega (YL) | enlace S.11 → Ing laboral solo informativo (el origen por sector del D.1 no cambia la persona) | amarillo |
| D.29 − D.39 (f.52, 58) | 199.756 − 12.009 = 187.747 | — | hoy ∝ `ing_bruto_tax + ing_bruto_tpm` (`H l.2841`) | llega a personas (fuera de Yl/Yk) aunque S.14 no paga D.29 (CUAD-1 FLAG) | S.11 → Gobierno «Otros impuestos a la producción»; sin persona (o P ∝ `ing_d4_rel` con `retenido_a_personas = on`) | **rojo** |
| B.2n excedente neto (f.63) | 5,522.905 | P | `ing_d4_rel` (= relativo de D.4 de CUAD-0) | **no llega**: solo lo que S.11 distribuye como D.4 | con `retenido_a_personas = off` no se dibuja (se dibuja B.5n); con `on` entra ∝ `ing_d4_rel` | **rojo** (P) |
| D.4 pagada (f.95): D.41 1,875.704; D.42 4,901.399 (D.421 4,250.528 + D.422 650.871); D.43 481.861; D.45 254.502 | 7,513.466 | P / — | D.42 a S.14 (4,779.531 del total recibido por hogares) ∝ `ing_d4_rel`; D.43 → Mundo (481.861); D.45 → Gobierno (renta petrolera 224.114 recibida por S.13) | la parte a hogares llega dentro de `ing_capital` (D.4 neto S.14) | enlaces S.11 → Hogares (D.42, D.41), → Mundo (D.43, parte de D.41), → Gobierno (D.45) **(la CSI no publica la matriz de quién a quién: la partición se infiere por las celdas receptoras y queda «residuo por identificar» si no cuadra)** | **rojo** (matriz) |
| D.4 recibida (f.95): D.41 742.312; D.43 124.604; D.44 6.716 | 873.632 | — | — | no | enlace Hogares/S.12/Mundo → S.11 según receptores | amarillo |
| **B.5n saldo primario neto (f.110)** | **−1,116.929** | P o — | `ing_d4_rel` | **fila de sector** «Sociedades S11+S12» → Otros sectores → Ing nacional, junto con S.12: **2.833 % del PIB** (`CUADRATURA[3]`) | nodo «Sociedades» (con S.12: 953.904) → hub; el signo negativo de S.11 se dibuja como «Financiamiento → Sociedades NF» 1,116.929 si van separadas | amarillo |
| D.5 pagada (f.114): D.51 1,020.417 + D.59 22.953 | 1,043.370 | P | `ing_d4_rel` (CUAD-1 `isrpm_incidencia = propiedad`) | **no llega** a Gobierno en el NTA (`TmenFuera`, informativo); fiscal: ISR PM por persona ∝ negocios propios (FLAG 19) | S.11 → Gobierno «ISR de sociedades»; a personas solo con `retenido_a_personas = on` (P) | **rojo** |
| D.61 recibida (f.117: D.612 imputadas) | 193.870 | I | `cuotasP` de quienes tienen prestaciones de empleador no de seguridad social (`formal` 3–5) | llega a Gobierno (todas las cuotas) | Hogares → S.11 «Cuotas: planes de empleadores» (CUAD-1 `cuotas_por_sector`) | amarillo |
| D.62 pagada (f.131: D.622) | 193.870 | I | ∝ `ing_jubila` de pensionados sin IMSS/ISSSTE (`formal` 3–5) | llega atribuido a Gobierno (dentro de τ⁺ efectivo 3,445.143: CUAD-0 FLAG 14) | S.11 → Hogares «Prestaciones privadas» | amarillo |
| D.7 pagada (f.139): D.71 48.968; D.751 41.530; D.759 700.204 | 790.703 | — | — | no | S.11 → S.12 (primas), → ISFLSH (41.530), → Gobierno/Mundo (D.759 700.204: **residuo por identificar**: la CSI no dice el receptor) | **rojo** |
| D.7 recibida (f.139): D.72 43.769; D.759 3.820 | 47.589 | — | — | no | S.12 → S.11 (indemnizaciones) | amarillo |
| B.6n ingreso disponible neto (f.153) | −2,903.413 | — | — | no | nodo «Ingreso disponible S.11» (negativo: financiado) | amarillo |
| B.8n ahorro neto (f.171) = B.6n | −2,903.413 | P o — | `ing_d4_rel` | **no llega** | `retenido_a_personas`: `off` → «Financiamiento → Sociedades NF»; `on` → S de personas ∝ `ing_d4_rel` | **rojo** (P) |
| P.5n formación neta (f.189) = P.51b 5,138.632 − CCF 4,634.128 + existencias | −1,105.699 | — | — | no | solo con `discrepancia_gasto = nodo` | amarillo |
| B.9 préstamo (+)/endeudamiento (−) neto (f.265) | −1,416.744 | — | — | **no llega** | «Financiamiento» (componente 1 de 4) | amarillo |
| P.51c consumo de capital fijo (f.28) | 4,634.128 | — | hoy CCF BIE total ∝ `ing_capital` (`H l.2477`) | llega a personas como `gasto_anualDepreciacion` (6,457.576 total) | con `bruto_neto = neto` no se dibuja; con `bruto`, S.11 → Depreciación | amarillo |

### S.12 Sociedades financieras (CSI_109)

| Partida | Valor | Regla | Relativo concreto | Hoy | Propuesto 8.17 | Sello |
|---|---:|---|---|---|---|---|
| B.1n (f.29) | 1,612.683 | — | — | no | ídem S.11 | amarillo |
| D.1 pagada (f.35) | 379.390 | I | dentro de D.1 S.14 | llega (YL) | informativo | amarillo |
| D.29 (f.52) | 32.699 | — | — | llega a personas ∝ base gravable (CUAD-1) | S.12 → Gobierno | **rojo** |
| B.2n (f.63) | 1,200.594 | P | `ing_d4_rel` | no (solo lo distribuido) | ídem S.11 | **rojo** (P) |
| D.4 recibida (f.95): D.41 3,119.050; D.42 4.008; D.44 64.617 | 3,187.675 | — | — | no | Hogares (intereses pagados 487.665, CSI_115 f.96 U/A), S.11 (1,875.704 parte), Gobierno (intereses de la deuda 1,205.483 parte), Mundo → S.12 **(matriz no publicada: residuo por identificar)** | **rojo** (matriz) |
| D.4 pagada (f.95): D.41 1,395.890; D.42 113.369; D.44 808.177 (D.441 124.705; **D.442 605.932**; D.443 77.540) | 2,317.436 | P / I | D.441 + D.443 ∝ `ing_d4_rel`; **D.442 ∝ `cuotasTP`** (derechos de pensión) | D.442 es fila de sector «Fondos de pensión D442» → Otros sectores: **1.800 % del PIB** (`CUADRATURA[2]`); el resto dentro de D.4 neto S.14 | `circuito_d442`: `neto` → fila al hub; `bruto` → S.12 → Hogares 605.932 (I ∝ `cuotasTP`) y Hogares → S.12 D.614 | amarillo |
| **B.5n (f.110)** | **2,070.833** | P o — | `ing_d4_rel` | fila de sector (con S.11: 2.833 %) | nodo «Sociedades» → hub | amarillo |
| D.5 pagada (f.114): D.51 145.259 + D.59 0.019 | 145.278 | P | `ing_d4_rel` | no llega a Gobierno (informativo) | S.12 → Gobierno «ISR de sociedades» | **rojo** |
| D.61 recibida (f.117): D.611 781.217 + D.612 15.107 + D.613 87.692 + D.614 605.932 − D.615 34.847 | 1,455.102 | I | `cuotasP` + `cuotasT` de `formal2 ∈ {1,3,4,6}` para RCV (Afores) y seguros; D.614 ∝ `cuotasTP` | llega a **Gobierno** (CUAD-0 FLAG 13: 1,045.130 de más en el nodo Gobierno) | Hogares → S.12 «Cuotas: Afores y aseguradoras» (CUAD-1 `cuotas_por_sector`) | amarillo |
| D.62 pagada (f.131: D.622 244.292 = D.6221 115.620 + D.6222 128.672) | 244.292 | I | ∝ `ing_jubila` de pensiones privadas / retiros Afore (ENIGH P032 de no IMSS/ISSSTE; `ing_ahorro` P065 seguros) | llega atribuido a Gobierno (FLAG 14) | S.12 → Hogares «Prestaciones privadas» | amarillo |
| D.7 pagada (f.139): D.71 63.250; D.72 208.949 (indemnizaciones); D.751 0.808; D.759 73.975 | 346.982 | I | D.72 a hogares (168.468 recibidas por S.14, CSI_115 f.143) ∝ primas pagadas (`gas_pc_` seguros 724654 292.050: dentro de `DiveT`) | no | S.12 → Hogares «Indemnizaciones de seguros» 168.468; → S.11 43.769; → Mundo | amarillo |
| D.7 recibida (f.139): D.71 200.908 (primas netas); D.72 60.245; D.759 9.544 | 270.697 | I | primas de hogares 116.394 (CSI_115 f.140 U/A) ∝ gasto en seguros | no (viaja en el consumo privado) | Hogares → S.12 «Primas netas» 116.394 (sale de la categoría «Otros gastos» con `consumo_precios`/clasificación de CUAD-1) | amarillo |
| B.6n (f.153) | 3,060.081 | — | — | no | nodo «Ingreso disponible S.12» | amarillo |
| **D.8 pagada (f.169)** | **1,270.277** | I | `max(YL, 0)` de quienes tienen cuotas > 0 (`N l.549`) | **llega** como `Derechos de pensión D8` → `Ing nacional` (3.773 % del PIB en el hub) | se mueve: S.12 → Hogares «Derechos de pensión D8» después del hub (no es ingreso nacional: uso de S.12 = recurso de S.14) | amarillo |
| B.8n (f.171) | 1,789.804 | P o — | `ing_d4_rel` | no llega | `retenido_a_personas` (como S.11); con `off` → Futuro | **rojo** (P) |
| P.5n (f.189) | 24.117 | — | — | no | opcional | amarillo |
| B.9 (f.265) | 1,780.446 | — | — | no | «Préstamo neto» → Futuro / Financiamiento (lado acreedor) | amarillo |
| P.51c (f.28) | 62.735 | — | — | dentro de la CCF total | ídem S.11 | amarillo |

### S.13 Gobierno general (CSI_112)

| Partida | Valor | Regla | Relativo concreto | Hoy | Propuesto 8.17 | Sello |
|---|---:|---|---|---|---|---|
| B.1n (f.29) | 2,759.058 | — | — | no | ídem | amarillo |
| D.1 pagada (f.35) | 2,724.870 | I | dentro de D.1 S.14 | llega (YL) | informativo | amarillo |
| D.2 − D.3 recibidos (f.44–58, R/P): D.21 − D.31 2,175.907 + D.29 − D.39 255.114 | 2,431.022 | I / — | D.21 − D.31 ∝ Cpriv (`N l.462`; `H l.2837` ∝ gasto total); D.29 − D.39 ∝ base gravable (`H l.2841`) | D.21 − D.31 llega como **ingreso de hogares** (`Impuestos a productos` → hub: 6.463 % del PIB) y vuelve como τ⁻ indirecto (2,192.943 LIF); D.29 − D.39 ∝ base gravable | «Impuestos a productos» (grupos ∝ Cpriv) → **Gobierno: ingreso primario** (no al hub de hogares); «Otros impuestos a la producción» ← sectores productores (S.11 187.747; S.12 32.699; S.13 34.188; S.15 0.480; S.14 0) | amarillo |
| D.4 recibida (f.95): D.41 142.253; D.42 1.127; D.44 1.373; **D.45 224.114** (D.452 202.584 + D.459 21.529) | 368.867 | — | — | D.45 ≈ FMP: «Empresas públicas → Gobierno» 1,601.824 (OyE LIF) | S.11 → Gobierno «Renta petrolera D.45» 224.114; las OyE (1,601.824) dejan de ser nodo (P.11 no es ingreso) o quedan como memo LIF | amarillo |
| D.4 pagada (f.95): **D.41 intereses de la deuda 1,205.483**; D.45 0.304 | 1,205.787 | C o I | C (renta pública de activos, NTA canónico) o I ∝ D.41 recibido por hogares (544.940, CSI_115 f.96 R/P: `ing_t4_cap6` crudos 19.335) | **no llega** (`C1 §3` #9) | Gobierno → Hogares 544.940 (parte de D.41 recibida por S.14; **residuo por identificar**: la CSI no dice cuánto de los 544.940 viene de S.13), → S.12, → Mundo (625.220 D.41 pagados al exterior por la economía) | **rojo** (matriz) |
| **B.5n (f.110)** | **1,594.102** | — | — | fila de sector «S13 impuestos netos y renta de la propiedad neta»: **4.735 % del PIB** (`CUADRATURA[4]`) = 7.221 − 2.486 | nodo «Gobierno: ingreso primario» → hub | amarillo |
| D.5 recibida (f.114) | 2,728.698 | I / P | S.14 1,540.050 ∝ `ISR_asalariados + ISR_PF` (I); S.11 + S.12 1,188.648 ∝ `ing_d4_rel` (P) | Hogares → Gobierno 1,330.838 (`Tmen` directo, LIF); sociedades **no** | Hogares → Gobierno 1,540.050 (o LIF 1,330.838 + «LIF vs CSI» 209.212 declarado); Sociedades → Gobierno 1,188.648 | amarillo / rojo (P) |
| D.61 recibida (f.117): D.611 673.011 + D.612 10.762 + D.613 0.186 | 683.959 | I | `cuotasTP` de `formal2 ∈ {1, 2}` (IMSS, ISSSTE) | Hogares → Gobierno 1,729.089 (todas) | Hogares → Gobierno 683.959; el resto a S.12/S.11/S.15 | amarillo |
| D.62 pagada (f.131): D.621 1,170.017 (D.6211 pensiones 1,134.162; D.6212 35.855) + D.622 157.413 + D.623 70.177 | 1,397.608 | I / E | `ing_jubila` (jubilados IMSS/ISSSTE), `ing_PAM`, `ing_benef` (`N l.559–568`) | llega: dentro de `Transferencias en efectivo` 3,445.143 (= D.62 + D.759 **de S.14**, incluye los 442.344 privados) | Gobierno → Hogares «Prestaciones en efectivo» 1,397.608 + D.759 1,605.191 = **3,002.799**; privadas 442.344 desde S.11/S.12/S.15 | amarillo |
| D.7 pagada (f.139): D.71 16.800; **D.73 4,649.972** (dentro del gobierno general); D.74 1.873; D.751 18.984; **D.759 1,612.421** | 6,300.051 | I / — | D.759 a hogares = programas (PEF) ∝ `ing_benef + nta_prog_raw`; D.73 es intra-S.13 (federación ↔ estados): neto cero | D.759 llega dentro de τ⁺ efectivo | Gobierno → Hogares 1,605.191 (CSI_115 f.151); **−7.230 residuo por identificar** (1,612.421 pagados vs 1,605.191 recibidos por S.14: otros receptores); D.73 no se dibuja | amarillo |
| D.7 recibida (f.139): D.72 0.319; D.73 4,649.972; D.759 791.189 | 5,441.480 | — | — | no | D.759 791.189 ← S.11 (700.204) + S.14 (23.578) + S.12 (73.975) **(suma 797.757 ≠ 791.189: residuo 6.568 por identificar)** | **rojo** |
| B.6n (f.153) | 2,750.579 | — | — | `Déficit público` 506.776 es el balance del nodo del lado hogares (`C1 §2.3`) | nodo «Ingreso disponible S.13» = 1,594.102 + 2,728.698 + 683.959 + 5,441.480 − 1,397.608 − 6,300.051 (cierra al peso) | amarillo |
| D.63 (f.157) = P.31 (f.167) | 2,010.849 | E | educación ∝ matrícula (`SerEGob`), salud ∝ `gas_pc_SaluT`, resto per cápita (`N l.498–500`) | **llega** como especie: 2,399.168 = D.63 S.14 recibido (incluye 388.320 de ISFLSH: FLAG 15) | Gobierno → Educación 1,054.587 / Salud 948.537 / Otros ≈ 7.725 (2,010.849 − 2,003.124; hoy «resto» 396.044 incluye ISFLSH y vintage) → grupos (E) | amarillo |
| P.32 consumo colectivo (f.168) | 1,896.999 | C | `pob` (`N l.502`) | llega per cápita por **1,517.160** (= ConGob BIE 3,916.328 − D.63 2,399.168); faltan 379.839 (FLAG 15) | Gobierno → Colectivo 1,896.999 (C); ConGob BIE 3,916.328 vs P.3 S.13 CSI 3,907.848: vintage 8.480 al nodo de vintage | amarillo |
| B.8n (f.171) | −1,157.268 | C / I / — | per cápita o ∝ τ⁻ (`deficit_a_personas`) | **no llega**; `Déficit público` 506.776 ≠ | `deficit_a_personas`: `off` → «Financiamiento → Gobierno» 1,157.268; `per_capita`/`tau_menos` → S de personas | amarillo (C) / rojo (I) |
| P.5n (f.189) | 602.257 | — | — | no | opcional (con B.9: −2,156.464) | amarillo |
| B.9 (f.265) | −2,156.464 | — | — | no | «Financiamiento» (componente 2 de 4) | amarillo |
| P.51c (f.28) | 8.993 | — | — | dentro de la CCF total | ídem | amarillo |

### S.15 ISFLSH (CSI_118)

| Partida | Valor | Regla | Relativo concreto | Hoy | Propuesto 8.17 | Sello |
|---|---:|---|---|---|---|---|
| B.1n (f.29) | 274.963 | — | — | no | ídem | amarillo |
| D.1 pagada (f.35) | 172.041 | I | dentro de D.1 S.14 | llega (YL) | informativo | amarillo |
| B.2n (f.63) | 102.442 | — | — | **no llega** (CUAD-0 Tabla 2) | dentro de B.5n S.15 → hub | amarillo |
| D.4 recibida 19.004 / pagada 4.680 (f.95) | 14.325 neto | — | — | no | dentro de B.5n | amarillo |
| **B.5n (f.110)** | **116.767** | — / C | per cápita si `isflsh_regla = hogares` | fila de sector «ISFLSH S15»: **0.347 % del PIB** (`CUADRATURA[5]`) | nodo «ISFLSH» → hub | amarillo |
| D.61 recibida (f.117: D.612) | 2.091 | I | `cuotasP` de `formal` 3–5 | a Gobierno | Hogares → ISFLSH | amarillo |
| D.62 pagada (f.131) | 4.182 | I | ∝ `ing_jubila` fuera de IMSS/ISSSTE | a Gobierno (FLAG 14) | ISFLSH → Hogares | amarillo |
| D.751 recibida (f.149): de hogares 274.349, S.11 41.530, S.13 18.984, S.12 0.808, S.15 5.064 | 340.736 | I | `ing_dona` otorgado (`InterOtor` 88.773 efectivo; `nta_otor_esp`) y deducción `deduc_gasto_donativ` (clave 173417) | `InterOtor` 88.773 no cierra con 274.349 (`C1 §3` #8) | Hogares → ISFLSH 274.349 con la brecha ENIGH declarada (185.576 = 274.349 − 88.773: **residuo por identificar**) | **rojo** |
| D.7 pagada (f.139): D.71 0.603; D.751 5.064 | 5.668 | — | — | no | ISFLSH → S.12 / ISFLSH | amarillo |
| B.6n (f.153) | 449.745 | — | — | no | nodo «Ingreso disponible S.15» | amarillo |
| D.63 (f.157) = P.3 (f.166) | 388.320 | E | mismo perfil que la especie pública: educación/salud/resto (`isflsh_regla = d63_perfil`) o C | **llega** dentro de la «especie» de Gobierno (FLAG 15) | ISFLSH → categorías (E) → grupos; sale de Gobierno | amarillo |
| B.8n (f.171) | 61.425 | — | — | no llega | ISFLSH → Futuro | amarillo |
| B.9 (f.265) | 90.408 | — | — | no | «Préstamo neto» | amarillo |
| P.51c (f.28) | 31.402 | — | — | dentro de la CCF | ídem | amarillo |

### S.2 Resto del mundo (CSI_121; signo desde México)

| Partida | Valor | Regla | Relativo concreto | Hoy | Propuesto 8.17 | Sello |
|---|---:|---|---|---|---|---|
| D.1 recibida del exterior (f.71 U/A) | +52.721 | I | dentro de D.1 S.14 (`suborrow = off`) | llega (YL); también en «Renta primaria al exterior» (−ROWProp − ROWRem, `S l.185`) | Mundo → Ing laboral 52.721 informativo (ya está en D.1 S.14) | amarillo |
| D.4 recibida (f.95 U/A): D.41 221.796; D.42 15.154; D.43 124.604 | +361.554 | — | — | dentro de D.4 neto S.14 (la parte de hogares) y de S.11/S.12 | Mundo → Sociedades (D.43 a S.11 124.604) / S.12 / Hogares **(matriz no publicada)** | **rojo** (matriz) |
| D.4 pagada (f.95 R/P): D.41 625.220; D.42 243.694; D.43 481.861 | −1,350.775 | — | — | fila de sector «El mundo» → Otros sectores: **2.782 % del PIB** (`CUADRATURA[7]` = 1,350.775 − 361.554 − 52.721 = 936.500) | Sociedades → Mundo (D.42 243.694 + D.43 481.861 + parte de D.41), Gobierno → Mundo (deuda externa, parte de D.41) **(partición por identificar)**; nodo «Mundo» como sink | amarillo |
| D.7 recibida (f.139 U/A): **D.752 remesas 1,188.474**; D.72 60.245; D.712 15.431; D.759 18.311 | +1,282.462 | I | `ing_remesas` × 8.3807 → ROWTrans BIE 1,186.091 (`H l.2106`) | **llega**: `El mundo → Remesas → Ing nacional` 1,186.091 (3.523 %) | igual (hub `inbd`: ROWTrans está dentro del INBD); D.752 CSI 1,188.474 vs BIE neto 1,186.091: **vintage 5.067** sobre el neto D.7 (1,199.769 CSI vs 1,186.091 BIE) **(incluye la diferencia de cobertura D.72/D.712/D.759: por identificar)** | amarillo |
| D.7 pagada (f.139 R/P): D.712 60.539; D.72 −3.607; D.74 1.873; D.752 23.889 | −82.693 | I | D.752 ∝ `ing_remesas`? **no**: son remesas **enviadas** (la ENIGH no las capta: `T916`? no) | no | Hogares → Mundo 23.889 **(sin variable ENIGH: per cápita o ∝ remesas recibidas, declarado)** | **rojo** |
| Compras netas de no residentes (BIE 724777; CSI P.621 − P.721 vacío) | −372.715 | I | ∝ `gastoanualTOT` (`H l.2845`) | llega dentro de Cpriv; `S l.112–118` «Turistas extranjeros» | sin cambio (`C1` D10) | amarillo |
| B.11 saldo exterior en bienes y servicios (f.66) | 513.900 (signo del cuadro S.2) | — | — | no | solo con `discrepancia_gasto = nodo` | amarillo |
| B.12 saldo corriente con el exterior (f.172) | 250.632 | — | — | no | — | amarillo |
| B.9 (f.265) | +251.842 (= −Σ B.9 residentes) | — | — | **no llega** | «Financiamiento»: Mundo presta 251.842 (componente 4 de 4) | amarillo |

### S.14 (lo que la Tabla 2 toca de hogares, para que las identidades cierren)

| Partida | Valor | Hoy | Propuesto |
|---|---:|---|---|
| B.5n (f.110) = D.1 10,052.962 + B.3n 6,956.984 + B.2n 910.359 + D.4 neto 5,602.969 | 23,523.274 | YL 14,690.951 + YA 8,226.391 + D.442 605.932 = 23,523.274 al peso (`CUADRATURA[0,1,2]` = 43.636 + 24.435 + 1.800) | igual: «Hogares» → hub |
| D.5 pagada (f.114) | 1,540.050 | 1,330.838 (LIF) | 1,540.050 o LIF + 209.212 declarado (CUAD-1) |
| D.61 pagada (f.117) | 2,335.022 | 1,729.089 a Gobierno | a 4 sectores |
| D.62 + D.759 recibidos (f.131, 151) | 1,839.952 + 1,605.191 = 3,445.143 | 3,445.143 todo de Gobierno | 3,002.799 de Gobierno + 442.344 privadas |
| D.7 pagada (f.139) | 438.209 | `InterOtor` 88.773 (inter-hogar) | 274.349 ISFLSH + 116.394 primas + 23.889 Mundo + 23.578 D.759 |
| D.72 recibida (f.143) | 168.468 | no | ← S.12 |
| B.6n (f.153) | 24,012.079 | — | nodo «Ingreso disponible S.14» |
| P.3 (f.166) | 23,381.329 | Cpriv 23,819.398 (CUAD-1 −438.069) | 23,381.329 → 7 categorías → grupos |
| D.8 recibida (f.169) | 1,270.277 | en el hub | ← S.12, después del hub |
| B.8n (f.171) | 1,901.026 | Σ S con ancla 0.8983 (sin ancla 2,116.145) | S residual de la cuenta por persona; `Ajuste S14` desaparece si la cuenta cierra con CUAD-1 (−17.035 declarado) |
| Otras transferencias privadas (ENIGH: `InterRec` 282.426 − `InterOtor` 88.773) | 193.653 | **en el hub** (0.575 % PIB) | **fuera del hub**: ajuste declarado dentro de «Hogares» (D.75 entre residentes es neto cero en S.14) |

---

## §6 Nodos, enlaces e identidades del Sankey de la economía completa

Nombres sin paréntesis ni puntos (restricción de `SankeySumSim`). **[v3]** existe hoy; **[mueve]** existe y cambia de lugar; **[nuevo]**. Valores en bn (CSI salvo nota), con `hub = inbd`, `retenido_a_personas = off`, `deficit_a_personas = off`, `isflsh_regla = sector`, `circuito_d442 = neto`, `vintage_nodo = si`, `bruto_neto = neto`, `financiamiento = un_nodo_4`.

### 6.1 Columna 0 → hub (fuentes del ingreso nacional disponible)

| Enlace | Valor | Fuente / regla |
|---|---:|---|
| Grupos de edad (5) **[v3]** → `Ing laboral` **[v3]** | 14,690.951 | `Yl` (D.1 + ⅔ B.3n S.14; I) |
| Grupos → `Alquiler propio` **[v3]** | 910.359 | `ing_estim_alqu` (B.2n; P) |
| Grupos → `Ing capital` **[v3]** | 7,316.032 | `Yk` − CCF − B.2n = ⅓ B.3n + D.4 neto − D.442 (P) |
| `Ing laboral` + `Alquiler propio` + `Ing capital` → `Hogares` **[nuevo]** | 22,917.342 | = B.5n S.14 − D.442 |
| `Fondos de pensión D442` **[mueve]** → `Hogares` | 605.932 | CSI_115 f.103 (con `circuito_d442 = neto`) |
| `Hogares` → `Ingreso nacional disponible` **[hub; v3 renombrado]** | 23,523.274 | B.5n S.14 (f.110) |
| `Sociedades` **[nuevo]** → hub | 953.904 | B.5n S.11 −1,116.929 + S.12 2,070.833 (hoy «Sociedades S11+S12», `CUADRATURA[3]`) |
| `Impuestos a productos` **[mueve]** ← grupos ∝ Cpriv → `Gobierno ingreso primario` **[nuevo]** | 2,175.907 | D.21 − D.31 (CSI_103 f.25–26); deja de entrar al hub como ingreso de hogares |
| `Otros impuestos a la producción` **[nuevo]** ← `Sociedades`/`Gobierno`/`ISFLSH` → `Gobierno ingreso primario` | 255.114 | D.29 − D.39 por sector productor |
| `Sociedades` → `Gobierno ingreso primario` «Renta petrolera D45» | 224.114 | CSI_112 f.105 |
| `Gobierno ingreso primario` → `Intereses de la deuda` **[nuevo]** → `Hogares` / `Sociedades` / `Mundo` | 1,205.483 | CSI_112 f.96 (partición por identificar) |
| `Gobierno ingreso primario` → hub | 1,594.102 | B.5n S.13 (`CUADRATURA[4]`) |
| `ISFLSH` **[nuevo]** → hub | 116.767 | B.5n S.15 (`CUADRATURA[5]`) |
| `El mundo` **[v3]** → `Remesas` **[v3]** → hub | 1,186.091 | ROWTrans BIE (`CUADRATURA` no la lleva: está en D.1/D.4 netos) |
| `Vintage BIE vs CSI` **[nuevo]** → hub | 84.901 | NNI BIE 26,272.948 − B.5n S.1 26,188.047 |
| **Σ al hub** | **27,459.038** | = `IngDisp` BIE 724037 = **81.561 %** del PIB (23,523.274 + 953.904 + 1,594.102 + 116.767 + 1,186.091 + 84.901 = 27,459.039; 0.001 de redondeo) |

Identidad del hub: INBD = B.5n S.1 + transferencias netas del mundo (BIE) + vintage = 26,188.047 + 1,186.091 + 84.901 ✓. La renta primaria neta pagada al exterior (936.500, `CUADRATURA[7]`) y la CCF (6,457.576, `[6]`) ya no son fuentes: el hub es neto y después de D.4 con el mundo (D.1 y D.4 de S.14 ya son netos de S.2).

### 6.2 Hub → sectores (distribución secundaria; todo interno a S.1 conserva)

| Enlace | Valor | Fuente |
|---|---:|---|
| hub → `Hogares ingreso disponible` **[nuevo]** | 23,523.274 → + recibidos − pagados = **24,012.079** (B.6n S.14) | f.153 |
| `Hogares` → `Gobierno`: ISR de personas (D.5) | 1,540.050 (LIF 1,330.838 + «LIF vs CSI» 209.212) | f.114 |
| `Hogares` → `Gobierno`: cuotas D.61 | 683.959 | CSI_112 f.117 |
| `Hogares` → `Sociedades financieras`: cuotas (Afores, aseguradoras) | 1,455.102 | CSI_109 f.117 |
| `Hogares` → `Sociedades no financieras`: planes de empleadores | 193.870 | CSI_106 f.117 |
| `Hogares` → `ISFLSH`: cuotas imputadas | 2.091 | CSI_118 f.117 |
| `Hogares` → `ISFLSH`: donativos D.751 | 274.349 | CSI_115 f.149 (ENIGH 88.773: brecha declarada) |
| `Hogares` → `Sociedades financieras`: primas netas D.71 | 116.394 | f.140 |
| `Hogares` → `El mundo`: remesas enviadas D.752 | 23.889 | f.150 |
| `Hogares` → (receptor por identificar): D.759 | 23.578 | f.151 U/A |
| `Sociedades` → `Gobierno`: ISR de sociedades D.5 | 1,188.648 | CSI_106/109 f.114 |
| `Gobierno` → `Hogares`: `Transferencias en efectivo` **[v3]** = D.62 + D.759 | 1,397.608 + 1,605.191 = 3,002.799 | CSI_112 f.131; CSI_115 f.151 |
| `Sociedades financieras` → `Hogares`: `Prestaciones privadas` **[nuevo]** D.62 | 244.292 | CSI_109 f.131 |
| `Sociedades no financieras` → `Hogares`: D.62 | 193.870 | CSI_106 f.131 |
| `ISFLSH` → `Hogares`: D.62 | 4.182 | CSI_118 f.131 |
| `Sociedades financieras` → `Hogares`: indemnizaciones D.72 | 168.468 | CSI_115 f.143 |
| `Sociedades financieras` → `Hogares`: `Derechos de pensión D8` **[mueve]** | 1,270.277 | f.169 |
| `Gobierno` ↔ `Gobierno`: D.73 (federación ↔ estados) | 4,649.972 | no se dibuja (intra-sector) |
| Resto de D.7 entre S.11, S.12, S.13, S.15 y S.2 (D.71/D.72 de seguros entre sociedades, D.74, D.759 de S.11 700.204 y de S.12 73.975) | según Tabla 2 | enlaces menores; el receptor de D.759 de S.11 y S.12 no está en la CSI: residuo por identificar |

Identidades por nodo (CSI, bn): **Hogares** 23,523.274 − 1,540.050 − 2,335.022 + 1,839.952 + 2,962.134 − 438.209 = 24,012.079 ✓ (f.153); **Gobierno** 1,594.102 + 2,728.698 + 683.959 + 5,441.480 − 1,397.608 − 6,300.051 = 2,750.580 ✓ (f.153: 2,750.579); **Sociedades financieras** 2,070.833 + 1,455.102 + 270.697 − 145.278 − 244.292 − 346.982 = 3,060.080 ✓ (3,060.081); **Sociedades no financieras** −1,116.929 + 193.870 + 47.589 − 1,043.370 − 193.870 − 790.703 = −2,903.413 ✓; **ISFLSH** 116.767 + 2.091 + 340.736 − 4.182 − 5.668 = 449.744 ✓ (449.745). Σ B.6n = 27,369.071 = B.6n S.1 (CSI_103 f.153) = hub − vintage 89.967 (84.901 + 5.067).

### 6.3 Ingreso disponible → usos

| Enlace | Valor | Fuente / regla |
|---|---:|---|
| `Hogares ingreso disponible` → 7 categorías **[v3]** (Alimentos, Vivienda, Transporte, Salud, Educación, Vestido, Otros gastos) → grupos consumidores (5) **[v3]** | 23,381.329 (P.3 S.14) | CUAD-1 `consumo_ancla = p3_s14`; hoy 23,819.398 |
| `Sociedades financieras` → `Hogares`: D.8 (ya arriba) y `Hogares` → `Futuro` **[v3]**: B.8n S.14 | 1,901.026 | f.171; S residual por persona |
| `Gobierno ingreso disponible` → `Educación` / `Salud` / `Otros gastos` (D.63, E) | 1,054.587 / 948.537 / 7.725 = 2,010.849 | CSI_112 f.157; `N l.498–500` |
| `Gobierno ingreso disponible` → `Colectivo` **[v3]** (C) | 1,896.999 | f.168 |
| `ISFLSH ingreso disponible` → categorías (D.63, E) | 388.320 | CSI_118 f.157 |
| `Vintage BIE vs CSI` → consumo | 49.749 (residentes) + 8.480 (ConGob) | Cpriv BIE 23,819.398 − P.3 S.14 − P.3 S.15; ConGob BIE 3,916.328 − P.3 S.13 3,907.848 |
| `Sociedades financieras` → `Futuro` (B.8n) | 1,789.804 | f.171 |
| `ISFLSH` → `Futuro` | 61.425 | f.171 |
| `Financiamiento deuda y venta de activos` **[nuevo; funde Déficit público y Desahorro]** → `Sociedades no financieras` | 2,903.413 (B.8n) | f.171; con B.9: 1,416.744 |
| `Financiamiento` → `Gobierno ingreso disponible` | 1,157.268 (B.8n) | f.171; con B.9: 2,156.464 |
| `Futuro` ↔ `Financiamiento`: préstamo neto del mundo | 251.842 | CSI_121 f.265 |

Identidad de usos: Σ B.6n 27,369.071 = P.3 S.14 23,381.329 + S.15 388.320 + S.13 3,907.848 + B.8n S.1 (−308.425) ✓ (27,677.497 − 308.425 = 27,369.072). Con el vintage: INBD 27,459.038 = C BIE 27,735.726 + AhorroN BIE −276.687 ✓ (`SCN.ado` cuenta D). **Ahorro de las personas** = B.8n S.14 1,901.026 con los defaults; = **−308.425** (B.8n S.1 CSI; −276.687 BIE con vintage 31.738) con `retenido_a_personas = on` y `deficit_a_personas ≠ off`: la nación desahorra y lo financia el mundo (B.9 S.2 +251.842) y la venta neta de activos.

### 6.4 Conteo y reutilización del JSON v3 (35 nodos / 99 enlaces; `D/v3-enlaces.py`)

| Grupo | Nodos |
|---|---|
| Sobreviven sin cambio (25) | `El mundo`, `Remesas`, 5 grupos perceptores, 5 grupos consumidores, `Ing laboral`, `Ing capital`, `Alquiler propio`, `Gobierno`, `Transferencias en efectivo`, `Colectivo`, `Futuro`, 7 categorías de consumo |
| Cambian de lugar o de nombre (4) | `Ing nacional` → `Ingreso nacional disponible` (hub INBD); `Impuestos a productos` (→ recurso de Gobierno, no del hub); `Derechos de pensión D8` (S.12 → Hogares, después del hub); `Empresas públicas` (→ dentro de S.11/S.13: B.2n y D.45; opcional como memo LIF) |
| Desaparecen (4) | `Déficit público` y `Desahorro` (→ `Financiamiento`), `Ajuste a cuentas nacionales S14` (S residual si CUAD-1 cierra), `Otras transferencias privadas` (ajuste declarado dentro de Hogares) |
| Nuevos (17) | `Hogares`, `Hogares ingreso disponible`, `Sociedades` (o `Sociedades no financieras` + `Sociedades financieras`), `Gobierno ingreso primario`, `Gobierno ingreso disponible`, `ISFLSH`, `ISFLSH ingreso disponible`, `Fondos de pensión D442`, `Otros impuestos a la producción`, `Intereses de la deuda`, `ISR de sociedades`, `Cuotas a Afores y aseguradoras`, `Cuotas a planes de empleadores`, `Prestaciones privadas`, `Donativos a ISFLSH`, `Vintage BIE vs CSI`, `Financiamiento deuda y venta de activos` |
| Enlaces | De los 99 (`D/v3-enlaces.out` los agrega por par origen → destino): **64 se reutilizan tal cual** (grupos → 3 fuentes 15; 7 categorías → 5 grupos 35; El mundo → Remesas 1; Remesas → hub 1; Gobierno → Colectivo 1; Gobierno → Educación/Salud/Otros 3; Gobierno → Transferencias en efectivo 1; Transferencias en efectivo → 7 categorías 7); **≈ 30 cambian de extremo** (3 fuentes → Hogares en vez del hub; hub → 7 categorías pasa a Hogares ingreso disponible; hub → Gobierno se parte en D.5/D.61 por sector; Impuestos a productos 6; D8 6; Activos → categorías/Futuro 8); **5 desaparecen** (Otras transferencias privadas, Empresas públicas, Desahorro, Déficit público, Activos → Ajuste); los nuevos son los de §6.1–6.3 (≈ 45, uno por fila de la Tabla 2 con enlace) |

Escalares nuevos de `SCN.ado` (lector `SCNHogaresS14`, mismo `specs` con rótulo y año): filas 110, 114, 117, 131, 139, 153, 157, 166, 168, 169, 171, 189, 265 de CSI_106/109/112/118; filas 66, 139, 172, 265 de CSI_121; ya existen B5n* (f.110), D442Hog, RemesasHogS14, ImpIngHog, OtrasTransfHogR/U, B.1b y P.51c de S.1.

## §7 Identidades verificadas (8.17: medidas en la corrida de la sesión; cuadro 5 y gates de `nta-identidad.txt`, `SCN.ado` cuadro de celdas por sector, `test-nta-identidad.sh` D)

| Identidad | Hoy (v8.15.3) | 8.17 (v8.17.0, medido) | Tolerancia |
|---|---|---|---|
| PIB BIE = YL + YA + D.442 + B.5n S.11+S.12 + B.5n S.13 + B.5n S.15 + CCF + ROW + vintage | VERDE (`CUADRATURA` Σ = 100.000) | se conserva (gate de `Households`; `CUADRATURA` sin cambio) | 1e-9 |
| Hub = INBD BIE 27,459.038 | hub 27,743.270 (82.405 %) | **= 27,459.038 (81.561 %)**, diferencia 0.00 MXN | 1e-9 |
| Hub = B.5n S.1 CSI + ROWTrans + vintage NNI | — | 26,188.047 + 1,186.091 + 84.901: 0.00 MXN | 1e-9 |
| Hogares → hub = B.5n S.14 (f.110) | — | 23,523.274; −0.31 MXN (1e-14) | 1e-9 |
| Cada sector: B.5n + recibidos − pagados = B.6n (f.153) | — | cuatro gates (Hogares + D.8, Gobierno, Sociedades = S.11 + S.12, ISFLSH) a 1e-14; Σ B.5n, Σ B.6n, Σ B.8n por sector = S.1 (CSI, reldif 0) en `SCN.ado` | 1e-9 (CSI redondea a 0.001) |
| Σ B.6n = INBD − vintage (84.901 + 5.067) | — | 27,369.071 = INBD − 89.967; en el Sankey: vintage usos 83.400 + «Por identificar» D.759 6.568 | 1e-9 |
| Usos: Σ B.6n = Σ P.3 + Σ B.8n | — | 27,677.496 − 308.425: 0.00 MXN | 1e-9 |
| Σ S de personas = B.8n S.1 (defaults firmados) | 1,901.026 con ancla 0.8983 | **−308.425 = B.8n S.1** (S hogar 1,901.026 + retenido −1,113.609 + déficit −1,157.268 + ISFLSH 61.425); con `retenido`/`deficit` = off: 1,901.026 (B.8n S.14) | 1e-9 |
| Σ S sin ancla vs B.8n S.14 | +11.3 % (8.16b: +24.5 %) | **1,881.607 vs 1,901.026: −19.419 (−1.0 %)**; esperado −0.9 %: ImpProd − τ⁻ indirectos −17.0 + vintage de remesas −2.4; ancla multiplicativa 1.0103 y nodo «Ajuste a cuentas nacionales S14» sink de 19.4 | ≤ 2 puntos de la esperada |
| Futuro − Financiamiento + ajuste S.14 = B.8n S.1 | — | 2,079.039 − 2,406.884 + 19.419 = −308.425: −0.25 MXN | 1e-9 |
| Financiamiento: Σ B.9 < 0 = Σ B.9 > 0 + Mundo | — | 3,573.208 = 3,573.208 (CSI f.265; reldif 0) | 1e-9 |
| Conservación en los 35 nodos intermedios del v4 (MXN y % del PIB) | — | reldif máx 2.8e-14; 57 nodos / 134 enlaces | 1e-9 |
| NTA por persona (`N` §5) | VERDE 2.98e-08 MXN | 1.5e-08 MXN; Σ intra por hogar 3.4e-08 | 1e-9 × C |

## §8 Límites conocidos

| # | FLAG | Magnitud | Cierre |
|---|---|---:|---|
| 33 | Matriz «de quién a quién» de D.4 (intereses, dividendos) no publicada en la CSI | D.4 pagada S.1 11,554.663 | **8.17, abierto y declarado**: los intereses de la deuda pública (D.41 S.13 1,205.483) salen de «Gobierno ingreso primario» al nodo «Por identificar» (sello rojo); la D.4 de los hogares ya viaja neta en «Ing capital» y la de las sociedades dentro de su B.5n |
| 34 | D.759 de S.11 (700.204) y S.12 (73.975) + D.759 pagada por hogares (23.578) = 797.757 vs 791.189 recibidas por S.13 | 6.568 | **8.17, declarado**: nodo «Otras transferencias D759» → Gobierno 791.189 y → «Por identificar» 6.568 («Por identificar» total 1,212.051 = 3.600 % del PIB) |
| 35 | D.751 a ISFLSH: ENIGH 173417 vs CSI 274.349 | la ENIGH solo ve 5.080 bn (el 88.773 del memo era todo lo otorgado, incl. inter-hogar): factor **54.01** | **8.17, declarado**: ∝ 173417 del hogar × factor (sello rojo); candidato a regla per cápita o ∝ ingreso en 9.x |
| 36 | Remesas enviadas (D.752 pagada 23.889) sin variable ENIGH | 23.889 | **8.17, declarado**: per cápita de adultos con ingreso |
| 37 | Vintage en cinco sitios (NNI 84.901; D.7 del mundo 5.067; CCF 0.776; ConGob 8.480; consumo 49.749) | 0.25–0.44 % PIB | `vintage_nodo = si`: NNI al hub (84.901) y sink de usos 83.400; ConGob y consumo declarados en el log (el v4 usa P.3 por sector CSI) |
| 13, 14, 15 | Cuotas a Gobierno; D.62 privado en Gobierno; ISFLSH mezcladas (CUAD-0) | 1,045.130; 442.344; 388.320/379.839 | **cerrados en 8.17**: cuotas por sector (nodos Afores, planes, seguridad social), prestaciones privadas desde Sociedades e ISFLSH, D.63 de ISFLSH desde su nodo, colectivo = P.32 S.13 |
| 38 | B.5n S.11 negativo exige nodo de financiamiento desde el inicio (`C1 §6` #8) | −1,116.929 | `financiamiento = un_nodo_4`; S.11 y S.12 se dibujan fundidos («Sociedades»: B.6n de S.11 −2,903.413 solo no cabe en un grafo sin ciclos) |
| 39 | Desbalance ENIGH de las transferencias entre hogares (recibido 282.426 vs otorgado 83.7) | 198.7 | **8.17, declarado**: `inter_hogar = balance` escala lo otorgado × 3.3745 (sello rojo) |
| 40 | Ahorro de las ISFLSH (B.8n S.15 61.425) atribuido a personas per cápita para que Σ S = B.8n S.1 | 61.425 | decisión de la sesión 8.17, a confirmar por Ricardo (alternativa: ISFLSH → Futuro y Σ S de personas = −369.851) |
| 41 | Grafo acíclico: la distribución secundaria se dibuja como casa de compensación desde el hub (los pagos de cada sector a los demás salen del hub por nodos con nombre; cada sector recibe su saldo residual); las D.7 menores entre S.11/S.12/S.13/S.15/S.2 viajan dentro de los saldos | — | diseño de 8.17 (CUAD-2 §6.2 dibujaba Hogares → Gobierno y Gobierno → Hogares, un ciclo que FusionCharts no acepta) |
| 17 | Top incomes y `d4_relativo` (sello rojo) condicionan toda regla P (también `YA_ret`, `TmenRet`, `S_ret`) | — | 9.x |

## §9 Específico de México

| Elemento | Qué requiere genéricamente | Por qué México lo resuelve así | En cap0 |
|---|---|---|---|
| CSI por sector institucional con S.14 y S.15 separados | Cuentas corrientes completas (I–III) por sector, con B.5n, B.6n, B.8n, B.9 | INEGI publica las siete tablas anuales (base 2018) sin la matriz de quién a quién de D.4 ni D.7; los receptores se infieren por sector | fila 4 |
| INBD como pivote | Un agregado de ingreso que sea neto, después de la renta primaria con el exterior y de las transferencias corrientes | El BIE lo publica (724037) y coincide al peso con PIN + ROW (`SCN.ado` cuenta C); la CSI da B.6n S.1 con otro vintage | fila 4 |
| Afores y planes de empleadores como receptores de cuotas | Sector financiero que recibe contribuciones sociales obligatorias | En México las cuotas RCV van a S.12 (Afores) y la CSI lo registra en D.61 de S.12 (1,455.102); la LIF solo ve las del IMSS como organismo | fila 12 |
| Deuda pública como renta pagada a hogares y al exterior | D.41 pagado por S.13 por receptor | 1,205.483 bn (3.58 % PIB) sin apertura por receptor en la CSI | fila 4 |
| Remesas | Transferencias corrientes de hogares no residentes a residentes, por edad | D.752 CSI 1,188.474 ≈ ROWTrans BIE 1,186.091; Banxico como contraste (CUAD-0 §9) | fila 15 |

## §10 Procedencia

| Sección | Archivo y líneas |
|---|---|
| Encabezado, §3 | `Sankey.do` l. 45–122, 128–195; `NTA.do` §7b–§7c; `output.do` l. 41–52 |
| §4 | `C1 §4.4` D1–D13; CUAD-0 §4 (`cuotas_d614`, `oye_en_hub`, `d4_relativo`); `NTA.do` l. 462, 498–502, 549, 619–657 |
| §5 | CSI_106/109/112/118 f.28–29, 35, 52, 58, 63, 95–110, 114–171, 189, 265; CSI_121 f.66, 71, 95, 139–151, 172, 265; CSI_115 f.96, 103, 110, 114, 117, 131, 139–153, 166–171; CSI_103 f.25–26, 110, 153, 166–171; `nta-identidad.txt`; `CUADRATURA` de `output.txt` |
| §6 | `D/v3-enlaces.py` (lectura del JSON v3: nodos, enlaces, agregados); `SCN.ado` `SCNHogaresS14`; BIE 724037, 724034–724035 |
| Δ | aritmética de §5–§6 y `C1 §1.2` actualizado a v8.15.3 |

---

## Δ esperado de 8.17: el hub pasa de 82.405 % a 81.561 % del PIB

Partida por partida (bn; % del PIB). Nada se corrió: es `C1 §1.2` con las cifras de v8.15.3 (`V3`, `I`) y la CSI. La columna «hub `inbd`» dice dónde queda cada partida.

| # | Partida | Hub `ing_nacional` (v8.15.3) | Hub `inbd` (8.17) | Δ | % PIB | Qué lo explica |
|---|---|---:|---:|---:|---:|---|
| 1 | YL (D.1 + ⅔ B.3n S.14) | 14,690.951 | 14,690.951 | 0 | 43.636 | sin cambio |
| 2 | YA = Ing capital 7,316.032 + Alquiler propio 910.359 | 8,226.391 | 8,226.391 | 0 | 24.435 | sin cambio |
| 3 | D.442 (fondos de pensión) | fila de sector, fuera del hub | +605.932 | **+605.932** | +1.800 | B.5n S.14 completo |
| 4 | D.8 ajuste por derechos de pensión | 1,270.277 | 0 | **−1,270.277** | −3.773 | recurso de S.14 = uso de S.12: no es ingreso nacional; se mueve a S.12 → Hogares |
| 5 | Impuestos a los productos como ingreso de hogares | 2,175.907 | 0 (dentro de B.5n S.13) | **−2,175.907** | −6.463 | el SCN los pone en el gobierno |
| 6 | Remesas (ROWTrans) | 1,186.091 | 1,186.091 | 0 | 3.523 | en ambos |
| 7 | Otras transferencias privadas (desbalance ENIGH) | 193.653 | 0 | **−193.653** | −0.575 | neto cero en S.14; ajuste declarado |
| 8 | B.5n S.11 + S.12 | fuera | +953.904 | **+953.904** | +2.833 | `CUADRATURA[3]` |
| 9 | B.5n S.13 (D.2 − D.3 2,431.022 + D.4 neto −836.920) | fuera | +1,594.102 | **+1,594.102** | +4.735 | `CUADRATURA[4]` |
| 10 | B.5n S.15 | fuera | +116.767 | **+116.767** | +0.347 | `CUADRATURA[5]` |
| 11 | Vintage BIE vs CSI (NNI) | fuera | +84.901 | **+84.901** | +0.252 | `CUADRATURA[8]` es 83.348 (incluye −0.776 de CCF y usa B.1b); aquí NNI: 84.901. Diferencia 1.553 = vintage de ROW/CCF: **residuo por identificar** entre las dos definiciones |
| | **Hub** | **27,743.270 (82.405 %)** | **27,459.038 (81.561 %)** | **−284.232** | **−0.844** | −1,270.277 − 2,175.907 − 193.653 + 605.932 + 953.904 + 1,594.102 + 116.767 + 84.901 = −284.231 ✓ (0.001 de redondeo) |

Otras llaves: `CUADRATURA` no cambia (es la identidad del PIB, no del hub); `INCD`/`INGRESOS`/`GASTOS` no cambian por 8.17 (es visualización) salvo lo que 8.16 mueva; los 5 `SankeyNTA/sankey-*.json` y `sankey-v3-grupoedad.json` cambian de estructura (nodos nuevos: re-baseline, `baseline` = v8.17.0 si 8.16 no lo movió antes); `NTA/index.php` cambia los textos del hub (nota N de `C1 §5` queda superada: el hub **es** el INBD). Con `retenido_a_personas = on` el hub de hogares subiría 953.904 (≈ 84.4 %) y el ahorro de personas bajaría a 787.417; con `deficit_a_personas ≠ off`, a −369.851 (CSI) — cifras de la Tabla 2, no corridas.
