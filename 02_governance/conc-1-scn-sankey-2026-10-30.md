# CONC-1 — Conciliación SCN ↔ Sankey NTA: por qué el hub «Ing nacional» lee 86.7 % del PIB y el ingreso nacional disponible 81.6 %, y qué hace falta para un Sankey de la economía completa

**Fecha:** 2026-10-30 · **Sesión:** CONC-1 (memo, solo lectura; ningún `.do`/`.ado`/JSON cambia) · **Base:** `master` `73ecaf7` (v8.13.0, PR #46)
**Insumos leídos:** `SCN.ado` (v8.4, cuentas A–G y `SCNHogaresS14`), `01_modulos/NTA.do` (v1.4, §1, §4, §7b, §7c), `01_modulos/Households.do` (§9 Altimir, l. 2415–2435), `04_1_simuladorfiscal.ciep.mx/NTA/index.php`, `02_governance/nta-0-inventario-2026-10-27.md`; de la corrida canónica en `-datos` (`users/ricardo/`, 29-oct 22:07, `73ecaf7`): `NTA/nta-grupoedad.json`, `NTA/nta-panel-grupoedad-sexo.json` (bloques `nacional_pctpib` y `v3_mxn`), `NTA/nta-identidad.txt`, `NTA/nta-persona.dta`, `SankeyNTA/sankey-v3-grupoedad.json` (35 nodos / 99 enlaces); `master/SCN.dta` (fila 2024: las series BIE y las S.14 que `SCNHogaresS14` añadió) y `master/2024/households.dta`; `raw/temp/SCN/CSI_103/106/109/112/115/118/121.xlsx` (INEGI, Cuentas por Sectores Institucionales, base 2018, serie 2003–2024, «2024 revisada»: S.1, S.11, S.12, S.13, S.14, S.15, S.2; columnas AR = U/A y AS = R/P del año 2024).
**Cómo se obtuvieron los números:** ningún comando de Stata se corrió. Las cuentas A–G del `SCN, anio(2024)` se reconstruyen con las fórmulas de `SCN.ado` sobre la fila 2024 de `master/SCN.dta` (es lo que `NTA.do` §1 ejecuta en silencio: `quietly SCN, anio(2024)`; el `SIM.do` completo solo imprime el SCN 2027). Las sumas micro son `Σ x·factor` con pandas sobre `nta-persona.dta` y `households.dta` de `-datos`. Script y salida: `~/CIEP_Simuladores/diag-conc1-2026-10-30/puente.py`, `puente.out`; volcados de las siete tablas CSI en `csi/`.
**Convención:** miles de millones de MXN corrientes 2024 («bn») con tres decimales y % del PIB con tres decimales; PIB = `escalar mxn PIB` de `SCN.ado` = 33,667.023 bn (BIE 724025), el mismo denominador que `pctpib` del v3. Signos en el puente: lo que se **suma** para ir de un agregado al siguiente. «Hub» = nodo `Ing nacional` del v3 = `v3_mxn.hub_Ing_nacional` = 29,195.472 bn.

---

## Resumen ejecutivo

1. **El hub no es ingreso nacional ni lo contiene.** Es el ingreso del lado de los hogares a precios de mercado antes de impuestos: B.5n de S.14 (69.870 % del PIB) menos la brecha laboral del motor frente al sector (−2.244), más cuatro partidas que el SCN no cuenta como ingreso nacional o cuenta en otro sector: OyE públicas de la LIF (+4.758), impuestos netos a los productos como ingreso de hogares (+6.463), D.8 (+3.773) y el desbalance de transferencias privadas de la ENIGH (+0.575), más las remesas (+3.523). Suma 86.718 %. El ingreso nacional disponible neto (INBD, `SCN.ado` cuenta C = IngNacD BIE) es 81.561 %; el PIN 80.819 %.
2. **La tabla puente (§1) cierra a 1.1e-14 relativo** (0.33 MXN sobre 29.2 billones): INBD + Σ diferencias = hub, con cada diferencia identificada por cuadro y fila del SCN y por variable del motor. Dos partidas son de vintage y quedan explícitas: BIE vs CSI (PIB 33,667.0 vs 33,582.9: 84.901 bn = 0.252 %) y RemSalSS BIE vs D.1 S.14 (−39.528 bn).
3. **Lo que el hub omite del INBD** es lo que no llega a los hogares: el saldo primario neto de las sociedades después de pagar renta de la propiedad (S.11 **−1,116.929**, negativo: las no financieras distribuyen 7,513 de D.4 contra 5,523 de excedente neto; S.12 +2,070.833), el del gobierno sin los impuestos a los productos (D.29 − D.39 +255.114; D.4 neto −836.920, los intereses de la deuda) y el de las ISFLSH (+116.767).
4. **Lo que el hub añade y no es ingreso nacional:** las OyE (1,601.824 bn) son ventas de Pemex (755.0) y CFE (521.5), ingresos diversos de IMSS (61.5) e ISSSTE (59.9) y transferencias del FMP (203.9) tomados de la LIF: en el SCN las ventas son producción (P.11), no ingreso; el excedente de esas empresas ya está en el B.2n de S.11 y el FMP en la renta D.45 que recibe el gobierno (224.1). Entran al Sankey como «Ing capital» per cápita y el gobierno los vuelve a recibir como ingreso: **doble conteo frente al SCN**. D.8 (1,270.277) es un recurso de S.14 con un uso igual en S.12: neto cero nacional.
5. **Cierre de usos (§2).** INBD 27,459.038 = C 27,735.726 + ahorro neto nacional −276.687 (ahorro bruto 6,180.888 − CCF 6,457.576). El Sankey: hub 29,195.472 + Déficit público 506.776 + Desahorro 39.603 = C 27,735.726 + Futuro 1,940.629 + Ajuste S14 65.497. El consumo coincide al peso (Cpriv = GastPrivT BIE = ConHog + ComprasN; Cpub = ConGob). El «ahorro» del Sankey (Futuro − Desahorro = 1,901.026 = B.8n S.14) difiere del ahorro neto nacional en 2,177.713 bn = el ahorro neto de los otros sectores (S.11 −2,903.413; S.12 +1,789.804; S.13 −1,157.268; S.15 +61.425; vintage +31.738). El «Déficit público» del Sankey (506.8) es el balance del nodo Gobierno del lado hogares, no el déficit de S.13 (B.8n −1,157.3; endeudamiento neto B.9 −2,156.5 = 6.4 % del PIB): §2.3 lo concilia partida por partida.
6. **Esqueleto (§4):** cinco columnas por sector institucional (generación → PIB/PIN → distribución primaria → secundaria → usos), 26 nodos nuevos y 11 escalares nuevos de `SCN.ado` leídos de las mismas tablas CSI con el lector de `SCNHogaresS14` (filas 63, 95, 110, 114, 117, 131, 153, 166, 171, 190, 265 de cada cuadro). Trece decisiones son de Ricardo (§4.4), la primera: si el excedente retenido de sociedades se asigna a los hogares como dueños (NTA canónico) o se queda en Sociedades (SCN).
7. **La página (§5)** llama «national income» al hub en cuatro lugares; la nota propuesta para v8.14 dice qué es y por qué difiere del 81.6 %, con las cifras de este memo. Hallazgos laterales (§6): YL lleva 477.7 bn de impuestos a la producción y a los productos embebidos por Altimir; las cuotas (1,729.1) van todas a Gobierno cuando el SCN manda 1,455.1 a S.12 y 193.9 a S.11; la especie (2,399.2) incluye 388.3 de ISFLSH; el τ⁺ efectivo (3,445.1) incluye 442.3 pagados por S.11/S.12/S.15; el lado gasto del BIE trae una discrepancia estadística de −1,616.2 bn (−4.8 % del PIB).

---

## 1. Tabla puente: PIB → PIN → INBD → hub «Ing nacional» (2024, bn MXN y % del PIB)

### 1.1 Del PIB al ingreso nacional disponible (cuenta C de `SCN.ado`, series BIE de `master/SCN.dta`)

| Concepto | Cuadro / serie | Variable | bn MXN | % PIB |
|---|---|---|---:|---:|
| **PIB a precios de mercado** | BIE 724025 | `PIB` (= `escalar mxn PIB`, denominador de `pctpib`) | **33,667.023** | **100.000** |
| (−) Consumo de capital fijo (CCF) | BIE 724028 | `CapFij` | −6,457.576 | −19.181 |
| **= Producto interno neto (PIN)** | BIE 724029 | `PIN` (`escalar mxn PIN`) | **27,209.448** | **80.819** |
| (+) Remuneraciones netas del resto del mundo | BIE 724030 − 724031 | `ROWRem` | +52.721 | +0.157 |
| (+) Renta de la propiedad neta del resto del mundo | BIE 724032 − 724033 | `ROWProp` | −989.221 | −2.938 |
| = Ingreso nacional neto (NNI) | (no lo imprime SCN.ado) | PIN + ROWRem + ROWProp | 26,272.948 | 78.038 |
| (+) Transferencias corrientes netas del resto del mundo | BIE 724034 − 724035 | `ROWTrans` | +1,186.091 | +3.523 |
| **= Ingreso nacional disponible neto (INBD)** | = BIE 724037 `IngNacD` (coincide al peso) | `escalar mxn IngDisp` | **27,459.038** | **81.561** |

El PIN de `SCN.ado` cuenta B (Yl + CapIncImp) es el mismo 27,209.448: `DiscEstPIB` vale 0.001 bn en 2024. CCF es la partida mayor que separa al PIB del NTA neto (19.181 %): el NTA de `NTA.do` es neto por construcción (YA_motor = Yk − `gasto_anualDepreciacion`, 6,457.576 bn ∝ `ing_capital`; S anclado a B.8n, no a B.8b).

### 1.2 Del INBD al hub (cada línea: qué es, dónde está, por qué, signo)

| # | Concepto | Cuadro / fila del SCN ↔ variable del Sankey | bn MXN | % PIB |
|---|---|---|---:|---:|
| | **INBD** | cuenta C de `SCN.ado` | **27,459.038** | **81.561** |
| 1 | (−) Transferencias corrientes netas del mundo. **En INBD** (ROWTrans, cuenta C); **en el hub** entran aparte como `El mundo → Remesas` (línea 16). Mismo monto en dos lugares: se resta aquí y se suma allá. | BIE 724034−724035 ↔ `ROWTrans` (ancla de `ing_remesas`) | −1,186.091 | −3.523 |
| 2 | (−) Vintage BIE vs CSI. NNI BIE (26,272.948) − B.5n S.1 CSI (26,188.047). PIB BIE 33,667.023 vs B.1b CSI 33,582.899; CCF 6,457.576 vs 6,458.352. **En INBD** (BIE); el hub está anclado a S.14 (CSI). No es economía: son dos vintages del INEGI. | CSI_103 filas 27–29, 110 | −84.901 | −0.252 |
| 3 | (−) B.5n S.11 sociedades no financieras = B.2n 5,522.905 + D.4 recibida 873.632 − D.4 pagada 7,513.466 (D.42 dividendos 4,901.399; D.41 intereses 1,875.704; D.45 254.502). Es el **excedente retenido neto después de renta de la propiedad** y es **negativo**: distribuyen más que su excedente neto (en bruto, B.5b = +3,517.199). **En INBD; no en el hub.** Restar un negativo suma. | CSI_106 filas 63, 95, 110 | +1,116.929 | +3.318 |
| 4 | (−) B.5n S.12 sociedades financieras = B.2n 1,200.594 + D.4 recibida 3,187.675 − pagada 2,317.436 (de ella D.442 605.932 renta sobre derechos de pensión, que los hogares reciben como D.4 y devuelven como D.614). **En INBD; no en el hub.** | CSI_109 filas 63, 95, 103, 110 | −2,070.833 | −6.151 |
| 5 | (−) B.5n S.13, parte 1: impuestos netos a los productos D.21 − D.31 (2,269.960 − 94.053). **En INBD** como recurso del gobierno; **en el hub** como ingreso de hogares `ImpProd` ∝ Cpriv (línea 14). Mismo monto, dos lugares. | CSI_103 filas 25–26 (= `ImpNetosProdS1`) ↔ `Impuestos a productos` | −2,175.907 | −6.463 |
| 6 | (−) B.5n S.13, parte 2: otros impuestos netos a la producción D.29 − D.39 (267.123 − 12.009). **En INBD; en el hub solo lo que Altimir embebió en Yl** (línea 11). | CSI_103 filas 52, 58 | −255.114 | −0.758 |
| 7 | (−) B.5n S.13, parte 3: renta de la propiedad neta del gobierno = D.4 recibida 368.867 (D.45 renta petrolera 224.114, D.41 142.253) − pagada 1,205.787 (D.41 intereses de la deuda 1,205.483). **En INBD (negativo); no en el hub.** Restar un negativo suma. | CSI_112 filas 95–96, 105 | +836.920 | +2.486 |
| 8 | (−) B.5n S.15 ISFLSH = B.2n 102.442 + D.4 neto 14.325. **En INBD; no en el hub** (el Sankey no tiene sector ISFLSH). | CSI_118 filas 63, 95, 110 | −116.767 | −0.347 |
| 9 | (−) B.5n S.13, resto (B.2n del gobierno = 0; residuo de redondeo del tabulado) | CSI_112 fila 63 | −0.000 | −0.000 |
| | **= B.5n S.14: saldo de ingresos primarios neto de los hogares** = D.1 10,052.962 + B.3n 6,956.984 + B.2n 910.359 + D.4 neto 5,602.969 (recibida 6,116.263: D.42 4,779.531, D.44 735.471, D.41 544.940, D.45 56.321; pagada 513.293). **En ambos**: es el ingreso a precios de mercado del sector que el hub reproduce (D.1 + ⅔ B.3n como «laboral»; B.2n + ⅓ B.3n + D.4 neto = `YAHogS14` = `YA_base` 8,832.323). El D.4 recibido por los hogares (18.166 % del PIB) está en el hub y **no en el PIN**: el PIN reparte B.2/B.3/D.1/D.2 antes de que la renta de la propiedad cruce sectores. | CSI_115 filas 69–71, 95–105, 110 ↔ `Ing laboral`, `Ing capital` (parte hogares), `Alquiler propio` | **23,523.274** | **69.870** |
| 10 | (+) Brecha laboral: YL del NTA (13,935.397) − (D.1 + ⅔ B.3n de S.14 = 14,690.951). Suma de 11 a 16. | `nta-grupoedad.json` grupos.0.YL ↔ CSI_115 filas 70–71 | −755.554 | −2.244 |
| 11 | · RemSalSS BIE (10,013.434, ancla de `ing_subor`) − D.1 S.14 CSI (10,052.962): vintage | BIE 724014 ↔ CSI_115 fila 71 | −39.528 | −0.117 |
| 12 | · Impuestos a la producción que Altimir embebe en `ing_subor` (Σ ing_subor − RemSalSS = share de `ImpNetProduccionL`). **En el hub (dentro de YL); en INBD dentro de la línea 6.** | `Households.do` l. 2081–2082, 2098 | +99.782 | +0.296 |
| 13 | · ⅔ de los impuestos que Altimir embebe en `ing_mixto` (Σ ing_mixto 7,523.869 − MixN 6,956.984 = 566.885): productos ⅔·`ImpNetProductos_mixK` 497.560 = 331.707 y producción ⅔·69.325 = 46.217. **En el hub (dentro de YL)**; en INBD dentro de las líneas 5 y 6. `NTA.do` §4.3 resta de YA los 497.560 completos aunque solo ⅓ viajaba en Yk: YL conserva 331.707 de impuestos a productos **además** de recibir `ImpProd` (FLAG §6.1). | `Households.do` l. 2083–2086, 2108–2110; `NTA.do` §4.3 | +377.923 | +1.123 |
| 14 | · (−) Pensiones contributivas que el motor deja en Yl (`nta_pens_enYl` = min(ing_jubila·TaltimirSal, ing_subor)). **En S.14 D.1 no están** (son D.62); el motor las trae en Yl y `NTA.do` las saca: corrige el motor, no al SCN. | `NTA.do` §4.1–4.2 | −751.330 | −2.232 |
| 15 | · (−) ⅔ de transferencias y flujos financieros que viajan en `ing_mixto` (crudo: donativos, herencias, becas, remesas crudas 141.526, préstamos, retiros = 742.684). Ídem: no son D.1 ni B.3. | `NTA.do` §4.1 (`nta_mixto=crudo`) | −495.122 | −1.471 |
| 16 | · (+) Remuneraciones netas del exterior (`ing_suborROW` ∝ ing_subor = ROWRem). **En ambos**: en INBD en la cuenta C, en el hub dentro de YL. | `Households.do` l. 2435 ↔ BIE 724030−724031 | +52.721 | +0.157 |
| 17 | (+) OyE públicas: ingresos propios de Pemex 754.972, CFE 521.463, IMSS 61.542, ISSSTE 59.904 y transferencias del FMP 203.942 (LIF 2024, `divSIM`, sin financiamiento). **En el hub** (`OyE públicas → Ing capital`, per cápita en el motor); **no es ingreso en el SCN**: las ventas son P.11 de S.11/S.13 y su excedente ya está en la línea 3; el FMP es la renta D.45 que recibe S.13 (224.114, línea 7). | `Households.do` l. 2064–2071 ↔ `nta-grupoedad.json` anclas.OyE | +1,601.824 | +4.758 |
| 18 | (+) Impuestos netos a los productos como ingreso de hogares (`ImpProd` ∝ Cpriv). **En ambos** (contrapartida de la línea 5): el SCN los pone en el gobierno; el NTA en quien los paga, para que YL + YA + ImpProd sea a precios de mercado y C a precios de comprador. | `NTA.do` §4.4b ↔ CSI_103 filas 25–26 | +2,175.907 | +6.463 |
| 19 | (+) D.8 ajuste por cambio en los derechos de pensión. **En el hub** como `Derechos de pensión D8` (YA_d8 ∝ YL de cotizantes); **no en INBD**: en el SCN es una partida de la cuenta de utilización (recurso de S.14 fila 169, uso igual de S.12: neto cero nacional). | CSI_115 fila 169 ↔ `YA_d8` | +1,270.277 | +3.773 |
| 20 | (+) Remesas (`ing_remesas` × TaltimirROWTrans = ROWTrans al peso). Contrapartida de la línea 1. En el SCN son D.752 recibidas por S.14 (1,188.474 CSI) dentro de D.7 del mundo. | `El mundo → Remesas` ↔ BIE 724034−724035 | +1,186.091 | +3.523 |
| 21 | (+) Otras transferencias privadas: inter-hogar recibido 282.426 − otorgado 88.773. **En el hub** como fuente; **no en INBD**: entre hogares residentes el SCN consolida D.75 dentro de S.14 (neto cero). Es el desbalance de la ENIGH entre lo que unos declaran recibir y otros dar. | `NTA.do` §7 `BF` ↔ nodo `Otras transferencias privadas` | +193.653 | +0.575 |
| | **= Hub «Ing nacional»** | `v3_mxn.hub_Ing_nacional` = Σ enlaces a `Ing nacional` | **29,195.472** | **86.718** |

**Cierre:** INBD + Σ(líneas 1–9, 10, 17–21) = 29,195,472,120,883.80 MXN contra el hub 29,195,472,120,883.47: diferencia 0.33 MXN, 1.1e-14 relativo (`puente.out`). La suma 11–16 reproduce la línea 10 a 2e-13. El B.5n S.14 reconstruido desde el INBD (líneas 1–9) coincide al peso con la fila 110 de CSI_115.

**Compras netas (−372.715 bn, −1.107 % del PIB; BIE 724777).** No es una diferencia de ingreso: no está en el INBD ni en el hub. Está del lado de los usos: ConHog BIE 24,192.112 incluye compras de no residentes en el país y excluye las de residentes fuera; `GastPrivT` 23,819.398 = ConHog + ComprasN es el consumo de residentes y es, al peso, la Cpriv del NTA (`gastoanualTOT` + `gasto_anualComprasN`). En el SCN la partida es P.621 − P.721 del cuadro V.1 (en el S.2 de CSI el renglón viene vacío; el BIE la publica en la serie 724777). §2.1 la ubica en la identidad de usos.

**Lectura en una línea.** De INBD a hub: −3.523 (remesas, cambian de lugar) −0.252 (vintage) +3.318 −6.151 (sociedades) −6.463 −0.758 +2.486 (gobierno) −0.347 (ISFLSH) = 69.870 (S.14); −2.244 (motor vs sector) +4.758 (OyE) +6.463 (ImpProd) +3.773 (D.8) +3.523 (remesas) +0.575 (desbalance ENIGH) = 86.718.

### 1.3 Nota sobre ExNOpSoc de `SCN.ado`

`SCN.ado` cuenta B.2 calcula «Sociedades e ISFLSH (ajustado)» como residuo BIE: ExBOp 21,231.775 − CapFij 6,457.576 − MixN 6,956.984 − ExNOpHog 910.359 − ExNOpGob 0 = **6,906.856** (20.515 %). En CSI, B.2n de S.11 + S.12 + S.15 = 5,522.905 + 1,200.594 + 102.442 = 6,825.941. La diferencia (80.915) es la misma brecha de vintage de la línea 2. Para el Sankey de la economía completa conviene anclar el excedente de sociedades a las filas 63 de CSI_106/109/118 y no al residuo BIE (§4.3), o declarar el vintage como nodo.

---

## 2. Cierre fuentes = usos de la economía completa y dónde entra cada flujo del Sankey

### 2.1 La identidad corriente del SCN (cuenta D de `SCN.ado`, BIE) y la del Sankey

| Usos del INBD (bruto) | bn MXN | % PIB | ↔ Sankey v3 | bn MXN |
|---|---:|---:|---|---:|
| Consumo de hogares e ISFLSH (`ConHog`) | 24,192.112 | 71.857 | Cpriv (= ConHog + ComprasN = GastPrivT) → 7 categorías → grupos | 23,819.398 |
| Compras netas de no residentes (`ComprasN`) | −372.715 | −1.107 | dentro de Cpriv, ∝ `gastoanualTOT` (no hay nodo) | — |
| Consumo de gobierno (`ConGob`) | 3,916.328 | 11.632 | `Gobierno →` Salud/Educación/Otros (D.63 2,399.168) + `Colectivo` 1,517.160 | 3,916.328 |
| Ahorro bruto (`AhorroN` var., residuo) | 6,180.888 | 18.359 | — | |
| **= INBD bruto** (27,459.038 + CCF) | **33,916.614** | **100.741** | | |
| (−) CCF | −6,457.576 | −19.181 | no existe (NTA neto) | |
| **Ahorro neto nacional** (`escalar mxn AhorroN`) | **−276.687** | **−0.822** | `Futuro` − `Desahorro` = S anclado = B.8n S.14 | 1,901.026 |

Identidad del SCN: INBD 27,459.038 = C 27,735.726 + AhorroN −276.687. Identidad del Sankey (fuentes = usos, verificada en `puente.out` a 1e-12): hub 29,195.472 + `Déficit público` 506.776 + `Desahorro` 39.603 = **29,741.852** = C 27,735.726 + `Futuro` 1,940.629 + `Ajuste a cuentas nacionales S14` 65.497. El consumo total del NTA (`grupos.0.C` 27,735.726) es, al peso, ConHog + ComprasN + ConGob del BIE: el lado de usos ya cuadra con el SCN. Lo que no cuadra es el ahorro: el Sankey lleva solo el de los hogares.

### 2.2 Dónde se va la diferencia de ahorro (B.8n por sector, CSI; bn)

| Sector | B.8b bruto | CCF (P.51c) | **B.8n neto** | P.5n formación neta | **B.9 préstamo (+) / endeudamiento (−) neto** |
|---|---:|---:|---:|---:|---:|
| S.11 sociedades no financieras | 1,730.715 | 4,634.128 | **−2,903.413** | −1,105.699 | **−1,416.744** |
| S.12 sociedades financieras (tras D.8 −1,270.277) | 1,852.539 | 62.735 | **+1,789.804** | +24.117 | **+1,780.446** |
| S.13 gobierno general | −1,148.275 | 8.993 | **−1,157.268** | +602.257 | **−2,156.464** (−6.405 % PIB) |
| S.14 hogares | 3,622.120 | 1,721.094 | **+1,901.026** | +450.514 | **+1,450.512** |
| S.15 ISFLSH | 92.828 | 31.402 | **+61.425** | −28.983 | **+90.408** |
| **S.1 economía (CSI)** | 6,149.927 | 6,458.352 | **−308.425** | −57.794 | **−251.842** |
| S.2 resto del mundo (espejo) | | | B.12 saldo corriente +250.632 | | **+251.842** |
| Ahorro neto BIE (`SCN.ado`) | 6,180.888 | 6,457.576 | **−276.687** | | vintage CSI→BIE +31.738 |

Sankey (1,901.026) − nacional BIE (−276.687) = 2,177.713 = −Σ B.8n de los otros sectores − vintage = −(−2,903.413 + 1,789.804 − 1,157.268 + 61.425) − 31.738 = 2,209.452 − 31.738 = 2,177.714 (redondeo 0.001). Los B.9 de los sectores residentes suman −251.842, lo que el mundo presta (0.748 % del PIB).

### 2.3 Qué financia el «Desahorro» y el «Déficit público» del Sankey

**Desahorro, 39.603 bn (0.118 %).** Es −S de los grupos 5–17 (−0.927) y 18–24 (−38.676) después del ancla (`nta-identidad.txt`). En el Sankey lo financia el hub `Activos`: entra como fuente, sale hacia las categorías de consumo de esos grupos (40.968 con el complemento del ancla). En el SCN **no existe**: S.14 es un solo sector con B.8n +1,901.026 y B.9 +1,450.512; el desahorro de unos hogares lo financia el ahorro de otros **dentro** del sector. Lo que sí se ve en la cuenta financiera de S.14 (CSI_115 filas 270–313): emisión neta de pasivos 888.974 (préstamos F.4 +446.470: crédito al consumo e hipotecario; otras cuentas por pagar 125.758; discrepancia YA3 316.746) contra adquisición neta de activos 2,339.486 (depósitos F.2 575.719; derechos de pensión F.63 1,011.288; seguros y pensiones F.6 1,635.035). La contraparte micro del «Desahorro» es ese F.4 de pasivos: deuda nueva de hogares, 11 veces el desahorro neto por grupo (los préstamos y retiros que la ENIGH registra, 272.497 bn crudos, `nta_mixto_fin`, quedaron fuera de YL/YA por decisión NTA-1: coherente).

**Déficit público, 506.776 bn (1.505 %).** Es el balance del nodo `Gobierno` del lado hogares: −(Tmen 5,252.870 + OyE 1,601.824 − TpubEf 3,445.143 − Cpub 3,916.328). No es el déficit de S.13. Conciliación con la cuenta corriente de S.13 (CSI_112; bn):

| Partida | Sankey (nodo Gobierno) | S.13 CSI | Diferencia y causa |
|---|---:|---:|---|
| Impuestos a productos, producción e importaciones (D.2 − D.3) | 2,192.943 (τ⁻ indirectos ∝ LIF IVA/IEPS/ISAN/importación) | 2,431.022 | −238.079: D.29 − D.39 (255.114) no está; el Sankey ancla a LIF, el SCN a devengado; ImpProd (2,175.907) entra al hub y vuelve al gobierno como parte de τ⁻ |
| ISR de personas físicas y asalariados (D.5 de S.14) | 1,330.838 (LIF ISRAS + ISRPF) | 1,540.050 (S.14 D.5 pagado) | −209.212: D.59 otros impuestos corrientes 21.138 y vintage LIF/SCN |
| ISR de personas morales y otros tributarios (D.5 de S.11/S.12) | **0** (`TmenFuera` 1,801.570 informativo) | 1,188.648 (S.11 1,043.370 + S.12 145.278) | el Sankey no tiene sector Sociedades: su impuesto no llega a Gobierno |
| Cuotas a la seguridad social (D.61) | 1,729.089 (D.61 − D.614, todas a Gobierno) | **683.959** recibidas por S.13 | +1,045.130: el SCN manda 1,455.102 a S.12 (Afores, seguros; incluye D.614 605.932) y 193.870 a S.11 (planes de empleadores) |
| OyE públicas | 1,601.824 | 224.114 (D.45) + B.2n 0 | +1,377.710: ventas de Pemex/CFE/IMSS/ISSSTE no son ingreso del gobierno (§1.2 línea 17) |
| Renta de la propiedad recibida (D.4) | — | 368.867 | |
| **Recursos** | **6,854.695** | 7,003.735 (D.2−D.3 2,431.022 + D.4r 368.867 + D.5 2,728.698 + D.61 683.959 + D.759r 791.189) | |
| Intereses de la deuda (D.41 pagado) | **—** | 1,205.483 (3.580 % PIB) | el Sankey no lo ve |
| Prestaciones en efectivo (D.62 + D.759 pagados a hogares) | 3,445.143 (`TpubEf`, = D.62 + D.759 recibidos por S.14) | 1,397.608 + 1,612.421 = 3,010.029 | +435.114: D.62 pagado por S.12 244.292, S.11 193.870, S.15 4.182 (pensiones privadas, Afores) atribuido a Gobierno; D.759 de S.11 700.204 va a S.13/ROW, no a hogares |
| Consumo de gobierno individual (D.63) | 2,399.168 (D.63 recibido por S.14) | 2,010.849 | +388.320: es el D.63 de las ISFLSH (S.15 fila 157), que el Sankey atribuye a Gobierno |
| Consumo colectivo | 1,517.160 (ConGob BIE − D.63) | 1,896.999 (P.32) | −379.839: el espejo del renglón anterior (−388.320) + vintage ConGob BIE 3,916.328 vs P.3 CSI 3,907.848 |
| **Usos corrientes** | **7,361.471** | 3,907.848 + 3,010.029 + 1,205.483 + D.7 otros | |
| **Balance** | **−506.776** (`Déficit público`) | **B.8n −1,157.268**; con P.5 611.250: **B.9 −2,156.464** | |

Lo que financia el déficit de S.13 en el SCN es la cuenta financiera: emisión neta de pasivos del gobierno (títulos de deuda F.3) por 2,156.464 más lo que el mundo presta (B.9 S.2 +251.842 en total nacional). El «Déficit público» del Sankey (506.776) es menor porque el nodo Gobierno recibe 1,601.824 de OyE y 1,045.130 de cuotas que el SCN no le da, y no paga 1,205.483 de intereses; a cambio no recibe 1,188.648 de ISR de sociedades.

### 2.4 Nodo propuesto: «Financiamiento: deuda y venta de activos»

Un solo nodo fuente, sin edad, que sustituya a `Déficit público` y `Desahorro` como origen y haga explícito que todo lo que el Sankey «financia» desde fuera del ingreso es endeudamiento neto o venta de activos de un sector. Nombre de nodo (sin paréntesis ni puntos, por SankeySumSim): `Financiamiento deuda y venta de activos`. Componentes y fuente de cada uno:

| Componente (enlace desde el nodo) | Hacia | Monto hoy (v3) | Escalar propuesto en `SCN.ado` | Fila CSI (lector `SCNHogaresS14`, columna U/A) |
|---|---|---:|---|---|
| Gobierno: endeudamiento neto | `Gobierno` | 506.776 (balance del nodo) | `B9Gob` = −B.9 S.13 (2,156.464) en la economía completa; en v3 sigue siendo el balance declarado del nodo | CSI_112 fila 265 |
| Hogares: desahorro de los grupos que desahorran | `Activos` | 39.603 (Σ max(−S_g, 0)) | ya existe: `NTAV3DesahorroPIB`; contraparte SCN: F.4 pasivos S.14 446.470 (`F4PasHog`, informativo) | CSI_115 fila 286 (R/P) |
| Sociedades: endeudamiento neto de S.11 | `Sociedades` (nuevo, §4) | — | `B9SocNF` = −B.9 S.11 (1,416.744) | CSI_106 fila 265 |
| Mundo: préstamo neto del resto del mundo | sink `Mundo` (o fuente si B.9 S.2 > 0, como en 2024) | — | `B9ROW` = B.9 S.2 (251.842) = −Σ B.9 residentes | CSI_121 fila 265 |

Con los B.9 de los cinco sectores residentes y el del mundo, el nodo conserva por construcción: Σ fuentes de financiamiento (sectores con B.9 < 0: S.11 1,416.744 + S.13 2,156.464 = 3,573.208) = Σ préstamos netos (S.12 1,780.446 + S.14 1,450.512 + S.15 90.408 + mundo 251.842 = 3,573.208). Los sectores con B.9 > 0 van al sink `Futuro` (hoy solo hogares); los de B.9 < 0 salen del nodo de financiamiento. El tooltip de cada enlace declara el B.9 de la cuenta III.1 del sector. Decisión de Ricardo (§4.4, D8): si el Sankey sigue siendo del lado hogares, el nodo lleva solo las dos primeras filas y el nombre dice lo que hoy dicen los dos nodos; si es de la economía completa, las cuatro.

---

## 3. Lo que está en el SCN y no en el Sankey (2024, bn; sector de origen; apertura por edad)

| # | Concepto | Monto (bn) | % PIB | Cuadro / fila | Sector que lo origina | ¿Apertura por edad? |
|---|---|---:|---:|---|---|---|
| 1 | Renta de la propiedad pagada al mundo, neta (ROWProp) | −989.221 (pagada 1,350.775: intereses 625.220, dividendos 243.694, utilidades reinvertidas de IED y otros 481.861; recibida 361.554) | −2.938 | BIE 724032−724033; CSI_121 filas 95–98 | S.11 y S.12 (IED, deuda corporativa), S.13 (deuda externa) | No. En el motor `ing_capitalROW` ∝ `ing_capital` (−989.221) **sí** llega a YA_motor por persona, pero el re-anclaje a `YAHogS14` lo diluye: el hub no lleva un nodo «al mundo». Per cápita o sin edad |
| 2 | Compras netas de no residentes / turistas (ComprasN) | −372.715 | −1.107 | BIE 724777 (P.621 − P.721) | S.2 contra S.14 | Sí (ya está: ∝ `gastoanualTOT` por persona dentro de Cpriv); si se quiere nodo `Turistas`, sale de la misma variable |
| 3 | Excedente retenido neto de sociedades después de D.4 (B.5n S.11 + S.12) | 953.904 (S.11 −1,116.929; S.12 +2,070.833); antes de D.4: B.2n 6,723.499; bruto B.5b 5,650.767 | 2.833 | CSI_106/109 filas 63, 95, 109–110 | S.11, S.12 | No en el SCN. Sí si se asigna a hogares como dueños (NTA canónico): ∝ D.42 recibido / ∝ YA por decil y edad (el motor ya reparte `ing_capital` anclado a ExNOpSoc) |
| 4 | Ahorro neto de sociedades (B.8n S.11 + S.12) | −1,113.609 (S.11 −2,903.413; S.12 +1,789.804); bruto 3,583.254 | −3.308 | CSI_106/109 fila 171 | S.11, S.12 | Igual que 3 (ahorro corporativo como ahorro de hogares en NTA canónico) |
| 5 | Impuestos corrientes pagados por sociedades (D.5 S.11 + S.12) | 1,188.648 (LIF: ISR PM 1,351.427 + OTROSK 450.142 = `TmenFuera` 1,801.570) | 3.531 | CSI_106/109 fila 114 | S.11, S.12 → S.13 | No (hoy informativo) |
| 6 | Consumo de capital fijo | 6,457.576 BIE; CSI por sector: S.11 4,634.128; S.12 62.735; S.13 8.993; S.14 1,721.094 (1,197.210 sobre B.2 vivienda, 523.884 sobre B.3); S.15 31.402 | 19.181 | BIE 724028; CSI fila 28 de cada cuadro | todos | Hogares sí (`gasto_anualDepreciacion` ∝ `ing_capital`, 6,457.576 por persona hoy; para S.14 habría que re-anclar a 1,721.094); sociedades y gobierno no |
| 7 | Consumo de gobierno colectivo vs individual | individual P.31 2,010.849; colectivo P.32 1,896.999 (CSI S.13); Sankey 2,399.168 / 1,517.160 | 5.973 / 5.635 | CSI_112 filas 167–168 | S.13 | Ya separado; el colectivo es per cápita en la cuenta (`TpubCol`) y sin edad en el gráfico. La diferencia con el Sankey son las ISFLSH (#8) y el vintage |
| 8 | ISFLSH (S.15) | producción 426.455; B.2n 102.442; D.751 recibidas 340.736 (de hogares 274.349, S.11 41.530, S.13 18.984); B.6n 449.745; consumo P.3 388.320 (todo D.63 a hogares); B.8n 61.425; B.9 90.408 | 1.153 (P.3) | CSI_118 | S.15 | Su D.63 (388.320) sí: con el mismo reparto que salud/educación/resto; hoy está dentro de la «especie» del nodo Gobierno; sus ingresos (donativos de hogares 274.349) están en `InterOtor` (173417, 88.773 en total) y no cierran |
| 9 | Intereses de la deuda pública (D.41 pagado por S.13) | 1,205.483 | 3.580 | CSI_112 fila 96 | S.13 → S.12, S.14 (544.940 recibidos), S.2 | No (NTA canónico: renta pública de activos per cápita) |
| 10 | Cuotas que no recibe el gobierno (D.61 a S.12 y S.11) | 1,455.102 + 193.870 = 1,648.972 (de ellas D.614 605.932) | 4.898 | CSI_109/106 fila 117 | S.14 → S.12, S.11 | Sí (ya por persona en `nta_CUOTAS`): es cambiar el destino, no el origen |
| 11 | Prestaciones pagadas por S.11/S.12/S.15 (D.62) | 442.344 | 1.314 | CSI_106/109/118 fila 131 | S.11, S.12, S.15 → S.14 | Sí (ya en `TpubPens`): cambiar el origen |
| 12 | D.8 contraparte (uso de S.12) | −1,270.277 | −3.773 | CSI_109 fila 169 | S.12 | No: es el espejo de `YA_d8` |
| 13 | Otros impuestos netos a la producción (D.29 − D.39) | 255.114 | 0.758 | CSI_103 filas 52, 58 | S.11 (199.756 − 12.009), S.12 32.699, S.13 34.188, S.15 0.480 → S.13 | No (hoy 146.0 de ellos viajan en YL vía Altimir, §6.1) |
| 14 | Discrepancia estadística del lado gasto | BIE `DiscEst` −1,616.168; CSI YA0 −1,649.318 | −4.800 | BIE 724036; CSI_103 fila 264 | S.1 | No. Es lo que separa al ahorro bruto «por ingreso» (6,180.888) de FBCF + existencias (8,052.454) − déficit externo |
| 15 | Vintage BIE vs CSI en PIB, CCF, D.1 y ConGob | 84.901 (NNI), 39.528 (D.1), 8.480 (ConGob) | 0.252 | §1.2 líneas 2 y 11 | INEGI | No |

---

## 4. Esqueleto del Sankey de la economía completa (texto; no JSON)

### 4.1 Columnas y nodos

Convención: **[v3]** existe en el v3 (35/99) con ese nombre; **[nuevo]**; entre paréntesis el escalar que lo ancla (los de `SCN.ado` que ya existen van sin asterisco; los nuevos con *). Todo nodo intermedio conserva; los saldos negativos (B.5n de S.11, B.8n de S.11 y S.13, ahorro neto nacional) se dibujan como fuentes de financiamiento (§2.4), nunca como enlaces negativos.

**Col. 0 — Fuentes del ingreso primario, por sector y edad.** Grupos perceptores 0–4 … 65+ **[v3]** → `Ing laboral` **[v3]** (D.1 S.14 + ⅔ B.3n: `RemSal`, `SSocial`, `MixL`; hoy YL del motor, §6.1), `Alquiler propio` **[v3]** (`ExNOpHogS14` 910.359), `Ing capital` hogares **[v3]** (⅓ B.3n + D.4 neto; hoy `YAHogS14` − B.2n). `Sociedades no financieras` **[nuevo]** (`ExNOpSocNF`* = B.2n S.11 5,522.905, fila 63 CSI_106) y `Sociedades financieras` **[nuevo]** (`ExNOpSocF`* 1,200.594). `ISFLSH` **[nuevo]** (`ExNOpISFLSH` ya se importa: 102.442). `Impuestos a productos` **[v3]** (`ImpNetosProd` 2,175.907) y `Otros impuestos a la producción` **[nuevo]** (D.29 − D.39 255.114, `ImpNetProduccion`). `Depreciación` **[nuevo]** (`CapFij` 6,457.576; por sector con las filas 28 de CSI si se quiere).
**Col. 1 — PIB / PIN.** `PIB` **[nuevo]** = 100 % (`PIB`), del que sale `Depreciación` como sink (o hacia `Formación de capital`) y queda `PIN` **[nuevo]** (`PIN` 27,209.448). Aquí desaparecen `OyE públicas` **[v3 → eliminar]** (no es ingreso) y `Derechos de pensión D8` **[v3 → mover a col. 3]**.
**Col. 2 — Distribución primaria (D.4 y el mundo).** `PIN` → `Hogares` **[nuevo]** (B.5n S.14 23,523.274, fila 110 CSI_115: lleva el D.4 recibido 6,116.263), `Sociedades` (B.5n S.11 + S.12: la parte negativa de S.11 entra desde `Financiamiento`), `Gobierno` **[v3]** (B.5n S.13 1,594.102: D.2 − D.3 + D.4 neto −836.920; los intereses de la deuda salen aquí hacia `Hogares`, `Sociedades financieras` y `Mundo`), `ISFLSH` (116.767). `Mundo` **[v3: El mundo]**: remuneraciones +52.721, renta de la propiedad −989.221 (sale hacia `Mundo`), y en col. 3 las remesas +1,186.091. Escalares: `ROWRem`, `ROWProp`, `ROWTrans` existen; `B5nHog`*, `B5nSocNF`*, `B5nSocF`*, `B5nGob`*, `B5nISFLSH`* nuevos (fila 110).
**Col. 3 — Distribución secundaria.** Desde `Hogares`: `D.5` ISR PF 1,540.050 → Gobierno (hoy `Tmen` directo 1,330.838); `D.61` cuotas 2,335.022 → Gobierno 683.959, Sociedades financieras 1,455.102, Sociedades no financieras 193.870 (hoy todo a Gobierno); `D.751` donativos 274.349 → ISFLSH; `D.752` 23.889 → Mundo. Desde `Sociedades`: `D.5` 1,188.648 → Gobierno (hoy fuera); `D.62` 438.162 → Hogares. Desde `Gobierno`: `Transferencias en efectivo` **[v3]** (D.62 1,397.608 + D.759 1,612.421 → Hogares; hoy 3,445.143 con las privadas), `D.63` en especie 2,010.849 → categorías **[v3]**, `Colectivo` **[v3]** 1,896.999. Desde `Sociedades financieras`: `Derechos de pensión D8` **[v3]** 1,270.277 → Hogares. Desde `Mundo`: `Remesas` **[v3]** 1,186.091 → Hogares. Resultado: `Ingreso disponible` por sector **[nuevo]**: Hogares 24,012.079 (B.6n fila 153), Sociedades NF −2,903.413, SF 3,060.081, Gobierno 2,750.579, ISFLSH 449.745; Σ = 27,369.071 (CSI) = INBD − vintage.
**Col. 4 — Usos.** `Hogares` → 7 categorías de consumo **[v3]** (P.3 S.14 23,381.329 + ISFLSH 388.320 ≈ GastPrivT 23,819.398 BIE) → grupos consumidores **[v3]**; `Gobierno` → `Colectivo` **[v3]** y especie (ya en col. 3); ahorro neto por sector → `Formación de capital` **[nuevo]** (P.5n: S.14 450.514, S.13 602.257, S.12 24.117; S.11 −1,105.699 y S.15 −28.983 son desinversión neta) y `Préstamo neto` / `Futuro` **[v3: Futuro]** (B.9 > 0: S.14 1,450.512, S.12 1,780.446, S.15 90.408); `Financiamiento deuda y venta de activos` **[nuevo, §2.4]** como fuente de los B.9 < 0 (S.11 1,416.744, S.13 2,156.464) y del `Desahorro` **[v3]**; `Mundo` recibe el préstamo neto del exterior 251.842 (B.12 250.632). `Ajuste a cuentas nacionales S14` **[v3]**: si el motor sigue anclando S a B.8n con factor, se conserva; si la economía completa cierra con S de S.14 como residuo del sector, desaparece.

### 4.2 Conteo

Nodos v3 que sobreviven: 31 de 35 (desaparece `OyE públicas`; `Déficit público` y `Desahorro` se funden en `Financiamiento`; `Otras transferencias privadas` se vuelve un ajuste declarado de la ENIGH dentro de `Hogares` o se mantiene). Nodos nuevos: 26 (`Sociedades no financieras`, `Sociedades financieras`, `ISFLSH`, `Otros impuestos a la producción`, `Depreciación`, `PIB`, `PIN`, `Hogares`, `Sociedades`, `Mundo` como sink, `D5 hogares`, `D5 sociedades`, `Cuotas`, `Donativos a ISFLSH`, `Prestaciones privadas`, `Intereses de la deuda`, 5 × `Ingreso disponible`, `Formación de capital`, `Préstamo neto`, `Financiamiento`, `Turistas` opcional, `Discrepancia estadística` opcional). Escalares nuevos en `SCN.ado`: 11 filas × 5 cuadros (63 B.2n, 95 D.4 U y R, 110 B.5n, 114 D.5, 117 D.61, 131 D.62, 153 B.6n, 166 P.3, 171 B.8n, 190 P.51b, 265 B.9) con el `specs` del lector de `SCNHogaresS14` (ya verifica rótulo y año), más la fila 265 de CSI_121. Ninguno exige el BIE.

### 4.3 Qué ancla a qué (regla)

Un solo vintage: todo lo que sea por sector sale de CSI (2024 revisada); el PIB y la cuenta de bienes y servicios del BIE se conservan para el denominador `pctpib` y para ConHog/ConGob por categoría, y la diferencia (84.901 bn en NNI; 8.480 en ConGob; 0.776 en CCF) se declara en un nodo `Vintage BIE vs CSI` o se absorbe en `Depreciación`. Decisión D3.

### 4.4 Decisiones de Ricardo

- **D1. Excedente retenido de sociedades.** (a) Se queda en `Sociedades` con su B.8n y B.9 (SCN: 2 nodos, sin edad); (b) se asigna a los hogares como dueños (NTA canónico, Lee–Mason: el ingreso de activos privado incluye el excedente de las sociedades y su ahorro es ahorro de los hogares): entraría a `Ing capital` por edad ∝ D.42 recibido o ∝ YA del motor, y el ahorro corporativo a `Futuro` con el mismo perfil. Con (b) el hub de hogares sube en 953.904 bn a ≈ 89.6 % del PIB y el ahorro de hogares baja a 1,901.026 − 1,113.609 = 787.417 bn.
- **D2. OyE públicas.** Eliminarlas (su excedente ya está en S.11/S.13 y el FMP en D.45) o conservarlas como memo LIF fuera de la conservación. Hoy duplican 1,601.824 frente al SCN.
- **D3. Vintage maestro.** BIE (como `SCN.ado` cuenta C) o CSI (como las anclas S.14). Afecta 0.25 % del PIB y el valor impreso del INBD (81.561 vs 81.516).
- **D4. Bruto o neto.** Dibujar CCF como flujo PIB → `Depreciación` (bruto, como el Sankey v1) o partir de PIN (neto, como el NTA actual). Si neto, el ahorro de S.11 es −2,903 y el de la nación −277: dos fuentes de financiamiento más.
- **D5. Circuito de pensiones.** Mostrar D.614/D.442 (605.932, ida y vuelta hogares ↔ S.12) y D.8 como enlaces propios, o netearlos (hoy D.614 está fuera de cuotas y D.8 dentro de YA).
- **D6. Destino de las cuotas.** Como el SCN (683.959 a Gobierno, 1,455.102 a S.12, 193.870 a S.11) o todo a Gobierno como hoy (cambia el balance del nodo Gobierno en 1,045.130).
- **D7. ISFLSH.** Sector propio (4 enlaces) o fundido en Hogares (como el BIE «hogares e ISFLSH»).
- **D8. Financiamiento.** Un nodo único (§2.4) con 2 o 4 componentes; nombre.
- **D9. Discrepancia estadística** del lado gasto (−1,616.168): nodo declarado, o fuera del Sankey (solo cuenta corriente, sin FBCF).
- **D10. Compras netas.** Nodo `Turistas` explícito (P.621 − P.721) o neteadas en Cpriv como hoy.
- **D11. Aperturas por edad** nuevas: D.63 de ISFLSH (388.320) con el perfil de salud/educación/resto; CCF de hogares (1,721.094) ∝ `ing_capital`; intereses de la deuda recibidos por hogares (544.940) ∝ D.41.
- **D12. D.4 recibido por hogares** (6,116.263): un solo `Ing capital` ∝ YA_motor (hoy) o partido en dividendos, intereses y D.442 con perfiles distintos.
- **D13. El nodo de ancla S14.** Conservar el factor sobre S (y su nodo) o, en la economía completa, dejar S de hogares como residuo del sector y declarar la brecha ENIGH–SCN en `Hogares`.

---

## 5. Lo que hoy dice la página /NTA que no es exacto

Frases de `04_1_simuladorfiscal.ciep.mx/NTA/index.php` (master `73ecaf7`) que llaman «national income» al hub, con la redacción honesta propuesta (nota al pie para v8.14; la página está en inglés).

| # | Línea | Dice hoy | Propuesta |
|---|---|---|---|
| 1 | l. 29 | «… feed the income types, which collapse into national income; from there the taxes households pay go to government …» | «… feed the income types, which collapse into the household-side income hub (`Ing nacional`: the sector's primary income at market prices before taxes, plus remittances, taxes on products, the pension-entitlement adjustment and public-enterprise revenue; see note N); from there …» |
| 2 | l. 41 | «The `Ing nacional` hub reads 86.7 % of GDP rather than 100 because it is not GDP: GDP net of depreciation (19.2 %) and of the balance of primary income with the rest of the world (−2.9 %) is national income, and of that the hub carries only what reaches households, plus the taxes on products (6.5), public-enterprise revenue (4.8) and remittances (3.5 %); what corporations and government retain is not in the chart.» | Falso en dos puntos: omite las remuneraciones netas (+0.2) y las transferencias netas del exterior (+3.5) al definir el ingreso nacional, y presenta al hub como subconjunto del ingreso nacional cuando lo excede en 5.2 puntos. Texto: «The `Ing nacional` hub is the household side of the NTA account, not national income. SNA net national disposable income is 81.6 % of GDP in 2024 (GDP 100 − consumption of fixed capital 19.2 + net compensation from abroad 0.2 − net property income paid abroad 2.9 + net current transfers from abroad 3.5). The hub reads 86.7 % because it adds flows that national income does not count as household income — public-enterprise revenue from the revenue law (4.8 %), the pension-entitlement adjustment D.8 (3.8 %), the survey's imbalance of private transfers (0.6 %) — and leaves out what the other sectors keep after property income: the retained net surplus of corporations (2.8 %), the government's primary income other than taxes on products (−1.7 %: other production taxes 0.8 less net interest paid 2.5), NPISH (0.3 %), plus the engine's labor-income gap against the sector (−2.2 %) and a vintage difference between the BIE and the institutional-sector tables (0.3 %). Taxes on products (6.5 %) and remittances (3.5 %) are in both, on the government side and abroad in the SNA, as household income here. Bridge: `02_governance/conc-1-scn-sankey-2026-10-30.md` §1.» |
| 3 | l. 89 | «`Ing nacional` — National income at market prices as it reaches households (plus the private-transfer balance, if positive): the single pivot between resources and their uses.» | «`Ing nacional` — Household-side income at market prices before taxes (S.14 primary income with the engine's labor definition, taxes on products, D.8, remittances and public-enterprise revenue, plus the private-transfer balance if positive): the single pivot between resources and their uses. It is 86.7 % of GDP against 81.6 % of SNA net national disposable income (note N).» |
| 4 | l. 150 | Encabezado de columna «National income (% of GDP)» | «Household income hub (% of GDP)» |
| 5 | l. 135 | «The hubs, in % of GDP. `Ing nacional` 86.7; …» | Sin cambio de cifra; añadir al final «(`Ing nacional` is not national income: note N)». |
| 6 | etiqueta del nodo | `Ing nacional` (NTA.do §7b `lbl4` 999; fijada en `test-sitio-nta.{sh,js}` y fixtures) | Para v8.14 solo la nota; renombrar a `Ing hogares` es cambio de contrato (35 etiquetas, fixtures, test) y va en un PR con corrida completa. |

Dos afirmaciones de la página que sí son exactas y conviene conservar: «Σ (`Ing capital` + `Alquiler propio`) from the age groups = B.2n + ⅓ B.3n + net D.4 of S.14» (l. 83: 8,832.323 al peso) y «Σ private consumption is reported against P.3 of S.14» (l. 112/134: 23,819.398 vs 23,381.329, la diferencia es ISFLSH 388.320 + vintage 49.749).

---

## 6. Hallazgos laterales (registrados, no corregidos)

1. **YL lleva 477.705 bn de impuestos embebidos por Altimir** (§1.2 líneas 12–13: 99.782 en `ing_subor`, 377.923 en ⅔ de `ing_mixto`, de ellos 331.707 de impuestos a los productos). `NTA.do` §4.3 resta de YA `ImpNetProductos_mixK` completo (497.560) aunque ⅔ de ese monto estaba en Yl, no en Yk. Efecto en el hub: los impuestos a los productos se cuentan 2,175.907 (ImpProd) + 331.707 (en YL); el ancla de YA a S.14 oculta la sobre-resta en YA. Corrección candidata (v8.14, cambia números): restar de YL ⅔·(ImpNetProductos_mixK) y los shares de ImpNetProduccion, o re-anclar YL a D.1 + ⅔ B.3n como se hizo con YA (`nta_YL=S14`), lo que mueve YL en +755.554 y S sin ancla en el mismo monto (la brecha S vs B.8n pasaría de +3.4 % a ≈ +43 %: el ancla de S caería a `off`). Decisión de Ricardo.
2. **OyE duplica 1,601.824 frente al SCN** (§1.2 línea 17; §2.3). Su único asidero SCN es la renta D.45 del gobierno (224.114).
3. **Cuotas:** 1,729.089 van a Gobierno; el SCN da 683.959 a S.13, 1,455.102 a S.12 y 193.870 a S.11.
4. **Especie:** 2,399.168 = D.63 recibido por S.14 incluye 388.320 de ISFLSH; `Colectivo` (1,517.160) queda 379.839 por debajo del P.32 de S.13 (1,896.999).
5. **τ⁺ efectivo:** 3,445.143 incluye 442.344 de D.62 pagados por S.11/S.12/S.15 (pensiones privadas y Afores), atribuidos al nodo Gobierno.
6. **Ahorro neto nacional negativo (−276.687) con discrepancia estadística del gasto de −1,616.168**: FBCF + existencias 8,052.454 (23.918 %) contra ahorro bruto 6,180.888 (18.359 %) y déficit externo de 0.748 %; la diferencia es la `DiscEst` del BIE (CSI YA0 −1,649.318). Cualquier Sankey con formación de capital tiene que declararla.
7. **`SCN.ado` imprime «Ingreso nacional disponible» = PIN + ROW (27,459.038)** y coincide al peso con la serie BIE 724037; la nota del código («~190 mil millones de discrepancia con IngDisp del BIE») es de otro vintage: hoy la diferencia es 0.
8. **S.11 tiene saldo primario neto negativo** (−1,116.929): el Sankey de la economía completa necesita desde el inicio nodos de financiamiento para balances negativos (§2.4), no solo para el gobierno.
9. **`LIF.dta` por `divSIM` suma series de todos los vintages** si se agrupa sin filtrar (`OTROSK` da 2,091.966 contra 450.142 de la LIF 2024): las OyE del memo salen de las filas `divLIF == Ventas`/`Derechos` de 2024, que cuadran con `anclas.OyE` al peso.

## Reproducibilidad

`~/CIEP_Simuladores/diag-conc1-2026-10-30/puente.py` (pandas 3.0.1, openpyxl 3.1.5, Python 3.14) lee `-datos/master/SCN.dta` fila 2024, `-datos/users/ricardo/NTA/{nta-grupoedad,nta-panel-grupoedad-sexo}.json`, `nta-persona.dta` y `master/2024/households.dta` (`[fw=factor]` como Σ x·factor) y las constantes CSI transcritas de `csi/CSI_1xx_S.x.txt` (volcado de columnas AR/AS de cada tabla, generado con openpyxl). `puente.out` imprime la tabla §1.2 y los cierres (`resid 0.328125 MXN`, `rel 1.1e-14`; fuentes = usos del Sankey a 6e-10; B.5n S.14 reconstruido = fila 110). Nada se corrió en Stata; los escalares citados de `SCN.ado` se reconstruyen con las fórmulas del `.ado` y coinciden con `nacional_pctpib` del panel (CapFij 19.181, PIN 80.819, ROWProp −2.938, ROWTrans 3.523, hub 86.718).
