# CUAD-1 — Capítulos `Expenditure` y `TasasEfectivas` del método: estado en v8.15.3 y propuesta de Cuadratura II (8.16)

**Fecha:** 2026-11-07 · **Sesión:** 8.16/8.17-memo (memo; ningún `.do`/`.ado`/número publicado cambia) · **Base:** `master` `9005ed3` (v8.15.3; baseline `v8.15.0`) · **Estado:** **borrador para firma** (Ricardo con Claude). Lo que decide Ricardo está en §4 y en la lista cerrada del PR. Nada de lo que aquí se propone se ejecuta en esta sesión.

## Encabezado

| Campo | Valor |
|---|---|
| `modulo` | `Expenditure` (consumo) y `TasasEfectivas` (impuestos y cuotas: `TasasEfectivas.ado`, `TasasEfectivasMicro.ado`, `01_modulos/ISR_Mod.do`, §6–§12 de `Households.do`) |
| `archivo` | `01_modulos/Expenditure.do`, `TasasEfectivas.ado`, `TasasEfectivasMicro.ado`, `01_modulos/ISR_Mod.do` @ `9005ed3` |
| `orden_en_SIM` | `Expenditure` es el primer módulo `.do` (`SIM.do` l. 134; `Households.do` l. 425–427 lo invoca si falta `deducciones.dta`); `TasasEfectivas` corre en §4 de `SIM.do` (nacional) y en `TasasEfectivasEntidad.do` (32 entidades); `ISR_Mod.do` es el «Calcular» (web y batch) |
| `desde_version` | `Expenditure.do`: perfilpc y bootstraps (`4eba8a7` 2026-10-03, `0692d9c`/`44da4ed` 2026-10-16); `TasasEfectivas.ado` v8.0 (03-jul-2026); `TasasEfectivasMicro.ado` 1.1.0 (F1-bis); `ISR_Mod.do`: FLAG-5 v8.14 |
| `ultima_decision` | 2026-10-31 (CUAD-0 §4.0 C: «Expenditures/TasasEfectivas → 8.16»; FLAG 19) |
| `sello` | **rojo**: hereda el peor de sus anclas (§5): bases LIF sin celda SCN, IEPS incompleto, ISR PM sobre negocios propios |

Escrito en `metodo/plantilla-capitulo.md`, con las mismas tres adiciones que CUAD-0 (resumen, parámetros nuevos como tabla de decisión, Δ esperado). **Convención:** miles de millones de MXN corrientes de 2024 («bn»), PIB = 33,667.023 bn (`escalar mxn PIB`, BIE 724025). «Σ ENIGH» = Σ x·factor sobre la ENIGH 2024 antes de cualquier factor; «Σ motor» = lo que el módulo suma antes del ancla (en `Expenditure.do` es `M<k>` de l. 913–914, después de `perfilpc`). **Principio C** (una celda SCN por variable) y **principio B** (toda partida de sector tiene regla a persona) como en CUAD-0.

**Sello** (de la plantilla): verde = oficial y estable; amarillo = oficial con vintage ambiguo; rojo = reconstruida, imputada o sin celda.

**Fuente** (de dónde sale cada cifra):

| Marca | Origen |
|---|---|
| `E l.N` / `T l.N` / `TM l.N` / `I l.N` / `H l.N` / `N l.N` / `O l.N` | `01_modulos/Expenditure.do`, `TasasEfectivas.ado`, `TasasEfectivasMicro.ado`, `01_modulos/ISR_Mod.do`, `01_modulos/Households.do`, `01_modulos/NTA.do`, `01_modulos/output.do` |
| `CSI_1xx f.N` | tabulados INEGI CSI 2024 (asset `raw/SCN/scn-congelado-2024.zip`; volcado `diag-conc1-2026-10-30/csi/`); columna U/A o R/P |
| `BIE nnnnnn` | serie del BIE en `master/SCN.dta` (`scn-celdas.md` tabla A) |
| `LIF` | `-datos/master/LIF.dta`, `anio == 2024`, `recaudacion` por `divSIM`/`divCIEP` sin `Financiamiento` (es lo que `LIF.ado` devuelve en `r()`; verificado contra el log) |
| `L` | logs de la corrida canónica v8.15.3 en `-datos/raw/temp/2024/expenditures.smcl` y `households.smcl` (2026-11-03) |
| `D` | `~/CIEP_Simuladores/diag-cuad-1-2-2026-11-07/` (`tabla1.py`, `4c-ampliado.py` y sus `.out`): lecturas con pandas de `-datos/master/2024/*.dta` y `raw/temp/2024/preconsumption.dta`, sin Stata |
| `DRR` | SHCP, *Renuncias Recaudatorias 2024* (28-jun-2024), https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/congreso/infoanual/2024/drr_2024.pdf (copia en `D/fuentes/`, sha256 `dd0c02ab…`); cuadros 3.2.1–3.2.3 y §III.1 f) |
| `ITG` | SAT, *Informe Tributario y de Gestión* 4T 2024, https://wu1agsprosta001.blob.core.windows.net/agsc-publicaciones/Datos_abiertos/Cifras_SAT/Indef/ITG_2024_4T.pdf (copia en `D/fuentes/`, sha256 `3c7d9331…`); cuadros 3 y 25 |
| `4c` | `diag-v8.15b-pre-2026-10-31/4c-wrap.log`, `4c-tabla.csv`, `pr-body.md` (base **v8.14.0**) |
| `(no en repo)` | La cifra no está versionada ni en `-datos`; se dice dónde debería estar |

Ninguna cifra es estimada. Los factores son cocientes de cifras de la misma fila.

## Resumen

1. **El consumo está anclado a 19 series del BIE que suman exactamente `ConHog` 24,192.112 (hogares + ISFLSH, en territorio), no a P.3 S.14 (23,381.329).** La brecha de −438.069 que CUAD-0 atribuye a «Cpriv vs P.3» es P.3 de las ISFLSH (388.320, CSI_118 f.166) + vintage BIE−CSI del consumo de residentes (49.749). **No se puede repartir por rubro con fuentes publicadas**: la CSI no desglosa P.3 por finalidad y el BIE 724601–724656 ya trae a las ISFLSH dentro (§5, Tabla 1).
2. **La base micro del consumo no conserva la ENIGH.** Σ gasto_anual·factor en `preconsumption.dta` es 9,860.460 bn; lo que `Expenditure.do` suma antes del ancla (`M<k>`) es 11,026.332: **+11.8 %**, y el cociente es **1.085868 en las 19 categorías** (por hogar, mediana exacta). El salto está entre §3.3 y §3.4 de `Expenditure.do` (la copia `o<var>` ya lo trae y `perfilpc` lo conserva). Los factores `TT<k>` lo absorben (el total anclado no cambia) pero están mal reportados en esa proporción y el reparto entre hogares no es el que la ENIGH dice. **FLAG nuevo, por identificar en 8.16**; no estaba en CUAD-0.
3. **Lo que la ENIGH clasifica como consumo y el SCN no:** regalos a otros hogares (G2, 90.530) **y** regalos recibidos (G5, 548.144) cuentan los dos; transferencias en especie de instituciones (G6, 164.719: D.63, consumo de gobierno/ISFLSH, no P.3 privado); predial (R004, 30.328: D.59) y tenencia (R012, 23.116: D.59) dentro de «Alquileres» y «Transporte». El alquiler imputado de la ENIGH (G102–G106, 1,408.154) viaja en la categoría `Alqu` y se ancla a BIE 724611+724612 (2,954.186), que no separa efectivo de imputado (CUAD-0 FLAG 18).
4. **Los impuestos no tienen celda SCN: todos se anclan a la LIF.** El total sí cuadra: ISR LIF 2,682.265 vs D.51 S.1 2,684.588; indirectos LIF 2,192.944 vs D.21 − D.31 2,175.907. Lo que no cuadra es **quién paga**: la CSI pone 1,540.050 de D.5 en S.14 y la LIF solo 1,330.838 de ISR de asalariados y PF (**+209.212**, el renglón de CUAD-0); la diferencia está en S.11+S.12 (D.5 1,188.648 vs ISR PM LIF 1,351.427). Las cuotas: la LIF solo ve 565.754 (IMSS) y la CSI 2,335.022 pagadas por S.14 a cuatro sectores (S.13 683.959, S.12 1,455.102, S.11 193.870, S.15 2.091).
5. **Tres bases están mal construidas y hoy no se ven porque el ancla LIF las tapa:** el IEPS no petrolero de `Expenditure.do` compara contra 24.075 (divCIEP «IEPS (no petrolero)») y no contra 224.780 (divSIM `IEPSNP`, que sí usa `TasasEfectivas`); `NTA.do` reparte el IEPS petrolero ∝ compra de vehículos (`gas_pc_Vehi`) y el no petrolero ∝ bebidas alcohólicas solamente; `ISR_asalariados = ISR × ing_subor/(ing_bruto_tax − cuotasTPF)` tiene mediana 1.150 y extremos ±miles (la parte «salarial» del ISR excede al ISR total en el 75 % de la base).
6. **Informalidad, con la base v8.15.3:** el corte deja **32.8 M formales** (no 42.5 M: `pensiones_en_yl = off` sacó a los jubilados de la base, que pasa de 54.2 a 49.3 M), umbral p ≥ 0.2285, λ = 1.1666, obligación estatutaria 1,424.327. Anclado a cotizantes IMSS+ISSSTE (25.5 M) la informalidad vale 294.590 y la «evasión» sale **negativa** (−124.048): la obligación del motor de los 25.5 M más probables no alcanza la recaudación. El requisito de entrada de 8.16 (anclar la obligación a declaraciones SAT por rango) **no es posible con lo que el SAT publica para 2024** (§4, §9).

---

## §1 Propósito

`Expenditure` construye el consumo por persona y categoría a partir de la ENIGH (gasto del hogar repartido por `perfilpc`, más el individual), escalado a las series de consumo privado del BIE por categoría, y calcula IVA e IEPS micro; `TasasEfectivas` toma la recaudación de la LIF por impuesto, la divide entre una base macro del SCN (tasa efectiva) y la reparte entre las personas ∝ la variable micro de cada impuesto (`ISR_Mod.do`, `Distribucion`), para que el fiscal, el NTA y las 32 entidades repartan lo mismo.

## §2 Entradas

| Base | Fuente / institución | Vintage usado | Variables clave | Llave única | Sello | Fuente de la fila |
|---|---|---|---|---|---|---|
| ENIGH 2024 `gastospersona`, `gastohogar`, `gastotarjetas`, `erogaciones`, `concentrado`, `vivienda`, `poblacion` | INEGI | 2024 (asset `2024.zip`, sha256 `407dd6df…`) | `clave` (2024, se descarta; se usa `clave_2018` vía `clave_iva.dta`), `gasto_tri`, `gas_nm_tri`, `tipo_gasto`, `cantidad`, `frecuencia`, `lugar_comp`, `factor` | `folioviv foliohog numren clave` → `folioviv foliohog numren` | verde | `E l.142–157, 200–203, 263, 495` |
| `clave_iva.dta` (correspondencia 2024 → 2018, IVA/IEPS, clase SCIAN) | CIEP (no INEGI) | en el asset `2024.zip` | `clave_2018`, `iva2018`, `clase_de_actividad1–6`, `porcentaje_ieps2018`, `cuota_ieps2018` | `clave` | **rojo** (construida; sin ficha) | `E l.201–203` |
| Censo Económico municipios (`censo_eco_municipios.dta`) | INEGI | en el asset | `A111A` (PBT), `A131A` (VACB) → `va_ratio` | `clase_de_actividad` | amarillo | `E l.208–226` |
| BIE consumo privado por finalidad (`ConHog.dta`: 724600–724656) | INEGI, vía asset `scn-congelado-2024.zip` | 2024 definitivo (`scn_vintage`) | 19 anclas `TT<k>` + `ConHog`; `Alqu` del motor = 724611 + 724612 (`SCN.ado` l. 867) | `anio` | amarillo (hogares + ISFLSH, territorio) | `scn-celdas.md` A; `SCN.ado` l. 867 |
| LIF 2024 (`master/LIF.dta`) | SHCP | vintage del asset `LIFs.xlsx` | `recaudacion` por `divSIM` (ISRAS, ISRPF, ISRPM, CUOTAS, OTROSK, FMP, PEMEX, CFE, IMSS, ISSSTE, IVA, IEPSNP, IEPSP, ISAN, IMPORT) y por `divCIEP` | `anio`, `divSIM` | verde | `T l.34–44`; `E l.105–120`; `H l.315–336` |
| PEF 2024 (`master/PEF.dta`) | SHCP | ídem | `Cuotas_ISSSTE`, cuota social y seguros (`SSFederacion`) | `anio` | verde | `H l.259–263` |
| Tablas de cuotas IMSS/ISSSTE y tarifa LISR | IMSS Informe 2021-2022 Anexo A.4; ISSSTE IFA 2021; LISR art. 96/152 | cableadas | `CSS_IMSS`, `CSS_ISSSTE`, `ISR`, `SE`, UMA 248.93 | — | amarillo (vintage 2021 para 2024) | `H l.1572–1595, 395–421`; `I l.27` |
| SCN macro para denominadores de TE | `SCN.ado` | 2024 (anclas) / `anioPE` 2027 (pastcast) | `RemSalSSPIB`, `MixLPIB`, `CapIncImpPIB`, `ConHogPIB`, `VehiPIB`, `BebAPIB`, `TabaPIB`, `Recre7132PIB`, `ConsPriv21PIB` | — | amarillo | `T l.61–63, 73, 112, 234–239` |

**Brecha frente a la plantilla:** `clave_iva.dta` es la única entrada sin institución externa ni ficha metodológica; `clase_de_actividad*` (SCIAN del último eslabón) decide `va_ratio` y con él la base del IVA y del IEPS.

## §3 Procedimiento

| # | Qué hace | Qué conserva | Dónde está |
|---|---|---|---|
| 1 | Junta las cuatro tablas de gasto, anualiza (×4), pega factor y vivienda, mapea `clave` 2024 → 2018 | Σ gasto_anual·factor = 9,860.460 bn (`D`) | `E l.142–205` |
| 2 | Asigna `va_ratio` (VACB/PBT del Censo Económico) por clase SCIAN del último eslabón, en cascada 6→2 dígitos | Ninguna (es una proporción) | `E l.208–271` |
| 3 | Clasifica cada clave en 19 categorías SCN (`categ`), 11 de IVA (`categ_iva`) y 12 de IEPS (`categ_ieps`) | Toda clave cae en una categoría (`categ = 19` si no) | `E l.314–474` |
| 4 | Separa gasto individual y del hogar; el del hogar se divide entre integrantes y se reparte por perfil edad-sexo (`perfilpc`); suma el individual | **Debería** conservar el total del hogar (`perfilpc.ado` l. 41); medido: `M<k>` = 1.085868 × (hog + ind) en las 19 (`D`, Resumen 2) | `E l.518–876` |
| 5 | Ancla cada categoría a su serie BIE: `TT<k> = SCN/M<k>`; `gas_pc_<k> *= TT<k>` | Σ 19 anclas = `ConHog` 24,192.112 al peso | `E l.1039–1056` |
| 6 | IVA micro: precio × cantidad × `va_ratio` × 16/116 por categoría de IVA (`IVAT`), reescalado a `ConHog`; compara con LIF | Nada se ancla: se reporta `DifIVA` (23.1 %) y la LIF manda después vía `Distribucion` | `E l.1163–1236`; `T l.335` |
| 7 | IEPS micro (ad valorem + cuota) por categoría; gasolinas y «sin IEPS» se saltan; compara con `IEPSNP` de `divCIEP` (24.075) | Ídem (`DifIEPSNP` 15.0 %); **macro equivocado** (Resumen 5) | `E l.1247–1347`, `l.109` |
| 8 | `TasasEfectivas`: TE = recaudación LIF / base macro SCN por impuesto; `Distribucion` reparte LIF ∝ variable micro (`ISRAS`, `CUOTAS`, …) | Σ repartido = LIF por impuesto | `T l.60–307, 329–336` |
| 9 | `ISR_Mod.do`: recalcula cuotas y tarifa con los parámetros del formulario; cut-off por probit; factores de empalme cableados (3.793/3.255, 0.241/0.553, 4.176/2.781, 1.675/1.525) | Σ ISR simulado = LIF en el default (los cocientes están calibrados a mano) | `I l.59–246` |
| 10 | `Households.do` §6–§11: cuotas por régimen (`cuotasT/P/F`, infonavit), gross-up del salario, ISR por tarifa, tres probits y tres cut-offs a la LIF | ISR total = LIF (7.961 vs 7.967 % PIB, `L`) | `H l.1572–1735, 1826–1890, 2319–2343, 2382–2499` |

## §4 Decisiones: cada cambio de 8.16 como parámetro

Formato de CUAD-0 §4. **Propuesto** = default que este memo propone para 8.16; Ricardo decide fila por fila. Todos se declaran en `SIM.do` §0.8 (como los diez de v8.15b) y cualquier valor distinto imprime FLAG.

| Parámetro | Propuesto | Alternativas | FLAG | Qué cambia si se mueve |
|---|---|---|---|---|
| `consumo_precios` | `comprador` | `basicos` | «Cpriv a precios de comprador: P.3 S.14 e ImpNetProductos ∝ gasto» | Con `comprador` (hoy): la ENIGH y P.3 están a precios de comprador, los impuestos a los productos viajan dentro del gasto y además se reparten explícitos ∝ gasto como ingreso (`H l.2837`, `N l.462`), de modo que YL + YA + ImpProd es a precios de mercado y C a precios de comprador (identidad NTA). Con `basicos`: las categorías de consumo se dibujan netas de D.21 − D.31 (C − ImpProd, 2,175.907 ∝ gasto) y el enlace «Hogares → Gobierno: impuestos a productos» se hace explícito; los totales por persona no cambian, cambian los nodos de consumo del Sankey (−2,175.907) y el `ImpProd` deja de ser «ingreso». |
| `consumo_ancla` (añadido) | `p3_s14` | `conhog` (hoy) | «Σ Cpriv = P.3 S.14; ISFLSH aparte» | `conhog`: 19 anclas BIE que suman 24,192.112 (hogares + ISFLSH en territorio) y `ComprasN` ∝ gasto. `p3_s14`: los 19 relativos se conservan y el total se reancla a P.3 S.14 23,381.329 (CSI_115 f.166), con las ISFLSH (388.320) y el vintage (49.749) como filas de sector (CUAD-2). Mueve Cpriv −438.069 y la brecha de S en +438.069 (§7). Por rubro no hay celda: factor único sobre los 19. |
| `cuotas_por_sector` | `on` | `off` (hoy) | «D.61 por sector pagador y receptor» | `off`: `cuotasTPF` (trabajador + patrón + federación + infonavit) va toda a Gobierno (`N l.524`: ancla D.61 − D.614 = 1,729.089; fiscal: `CUOTAS` LIF 565.754 a Gobierno). `on`: Σ cuotas se parte en las celdas de la Tabla 1b: por quien paga (patrón S.11/S.12/S.13/S.15 = D.611 + D.612; trabajador = D.613 + D.614 − D.615) y por quien recibe (S.13 683.959, S.12 1,455.102, S.11 193.870, S.15 2.091). El nodo Gobierno del Sankey pierde 1,045.130 (CONC-1 §2.3) y aparecen «Hogares → Afores/aseguradoras (S.12)» y «→ planes de empleadores (S.11)». |
| `isrpm_incidencia` | `propiedad` | `negocios` (hoy; FLAG 19) | «ISR PM ∝ `d4_relativo`; base = D.5 S.11 + S.12» | `negocios`: base = `ing_bruto_tpm` (P068–P081, negocios propios) + depreciación − exenciones, tarifa 30 %, cut-off a ISR PM LIF 1,351.427 (`H l.2482–2489`); los negocios propios tributan como PF y el ISR PM es de sociedades. `propiedad`: el total (LIF 1,351.427; celda D.5 S.11 + S.12 1,188.648) se reparte ∝ `ing_d4_rel` (el relativo de D.4 de CUAD-0, sello rojo) como regla P de la Tabla 2; `ing_bruto_tpm` deja de ser base de ISR y pasa a la base de PF (actividad empresarial) con su propio cut-off. Mueve INCD (incidencia por decil) y `ISRPMTE`/`OTROSKTE` si el denominador pasa de `IngKPrivado` a B.5n S.11 + S.12 (§Δ). |
| `obligacion_isrpf_ancla` | `enigh` (no hay alternativa viable hoy) | `sat_rangos` | «obligación de ISR PF sin ancla externa por rango» | **Requisito de entrada de 8.16, no cumplible con lo publicado.** `sat_rangos` exige declaraciones anuales de PF por rango de ingreso (base gravable e ISR causado) del ejercicio 2024. El SAT publica: (i) microdatos anonimizados de declaraciones anuales de PF **2010–2015** y DIM de sueldos y salarios **2013–2015** (`SAT más abierto`, https://www.sat.gob.mx/minisitio/DatosAbiertos/sat_mas_abierto.html; archivos `Anuales_ISR_PF_2015.zip`, `F30a1_2015.zip`); (ii) el ITG 4T 2024 con padrón y recaudación por régimen sin rangos: sueldos y salarios 51,858,257 contribuyentes activos y 1,254,807 mdp; PF no asalariadas 11,868,641 y 139,538 mdp; 13,321,757 declaraciones anuales (cuadros 3 y 25); (iii) la SHCP (`DRR` cuadro IX y gráficas 4–5) publica deciles de las deducciones personales (ejercicio 2021) y el subsidio al empleo por múltiplo de salario mínimo (CFDI de nómina 2023), no el ISR causado por rango. **(no publicado por SAT/SHCP para 2024)**: la tabla «rango → base gravable → ISR causado → Σ motor → factor» queda vacía; lo que sí se puede anclar es el **total** por régimen (ITG = LIF al peso) y el **gasto fiscal** (`DRR`). Alternativa: solicitud INAI/convenio SAT, o usar 2015 como forma de la distribución con FLAG rojo. |
| `informalidad` | `corte` (sin cambio hasta tener ancla) | `probabilistica` | «formalidad por corte de ranking; alternativa p × obligación» | `corte` (hoy): formal = los de mayor *p* hasta que Σ obligación = recaudación LIF (`H l.2438–2439`). `probabilistica`: pago esperado = λ·*p*·obligación en toda la base (λ = recaudado / Σ *p*·obligación = 1.1666 en v8.15.3). Cambia la concentración del pago (top-10 % 47.8 → 57.6 % en 4c) y el número de personas que pagan (32.8 → 49.3 M). *p_i* es la probabilidad de ser formal estimada por el probit de `H l.2384–2388`: lectura agregada (esperanza), no identifica quién paga. |
| `ancla_formales` | `ninguna` (= recaudación LIF, hoy) | `imss`, `enoe`, `sat` | «el corte se ancla a N formales externos; la brecha con la LIF se declara como evasión» | Con `ninguna` el corte cierra la recaudación y la evasión es 0 por construcción. Con un ancla externa el corte se fija en N personas y la diferencia Σ obligación(formales) − LIF es el margen intensivo (Tabla 4c-ampliado): `sat` 51.86 M → informalidad 0.000, «evasión» +170.542; `imss` 25.50 M → informalidad 294.590, evasión −124.048; `enoe` 23.5 M → 339.692, −169.150. Las dos últimas salen negativas: la obligación que el motor calcula a los cotizantes no alcanza la LIF (Resumen 6). |
| `iepsnp_macro` (añadido) | `divsim` | `divciep` (hoy) | «IEPS no petrolero = 224.780 (divSIM), no 24.075» | `E l.109` toma `r(IEPS__no_petrolero_)` del `LIF, by(divCIEP)` = 24.075 (sin «IEPS (salud)» 200.705); `TasasEfectivas` usa `IEPSNP` de `divSIM` = 224.780. Con `divsim`, `DifIEPSNP` pasa de 15.0 % a un déficit de 87 % (micro 28.3 vs 224.780): el IEPS micro está incompleto (gasolinas se saltan, l. 1282) y el display lo tapaba. |
| `ieps_relativo` (añadido) | `micro` | `proxy` (hoy en NTA) | «IEPS repartido ∝ la variable del bien gravado» | `N l.534–535`: `nta_IEPSNP ∝ gas_pc_BebA` y `nta_IEPSP ∝ gas_pc_Vehi`. `micro`: ∝ `IEPS` de `consumption_categ_ieps.dta` (por categoría) y ∝ `gas_pc_Gasolinas + gas_pc_Combustibles` (como `TM l.136–137`). Mueve la incidencia por decil y edad de 628.364 bn. |
| `isras_share` (añadido) | `acotado` | `libre` (hoy) | «parte salarial del ISR acotada a [0, 1]» | `H l.2433`: `ISR_asalariados = ISR × ing_subor/(ing_bruto_tax − cuotasTPF)`; el cociente tiene mediana 1.150, p75 1.220, mínimo −1,395.8 y máximo 7,252.1 en la base del probit (`D`): la «parte salarial» excede al ISR total en tres cuartas partes de la base. `acotado`: clip a [0, 1] (o `ISR × ing_subor/ing_bruto_tax`). Cambia Σ obligación (1,424.327 hoy) y por tanto el umbral y los conteos de §4 bis. |

**Decisiones ya vivas** (sin parámetro; la plantilla exige que aparezcan):

| Decisión | Default | Dónde | Qué cambia si se mueve |
|---|---|---|---|
| Base del IVA micro = precio × cantidad × `va_ratio` (último eslabón, Censo Económico) | `va_ratio` por clase SCIAN, media si falta | `E l.218–271, 1203–1206` | Sin `va_ratio` el IVA micro sube; con él `DifIVA` = 23.1 % se publica como «informalidad» (`SIM.do` l. 288 `IVAT[13] = 23.1`, recalibrado 2026-10-06) |
| Factores de empalme cableados en `ISR_Mod.do` | 3.793/3.255 (ISRAS), 0.241/0.553 (ISRPF), 4.176/2.781 (ISRPM), 1.675/1.525 (CUOTAS) | `I l.184, 193, 208, 213` | Son cocientes LIF/micro de algún año; no se leen de ninguna fuente. Sin ellos el «Calcular» no cuadra con la LIF |
| `IEPST` tasas/cuotas y gasolinas excluidas | matriz cableada; `Gasolinas` y `Sin_IEPS` se saltan | `E l.1248–1258, 1282` | El IEPS petrolero (403.584) no tiene micro en `Expenditure.do` |
| Cuotas con tablas 2021 y UMA 2024; tope 25 UMA (IMSS) / 10 (ISSSTE) | cableado | `H l.1572–1611` | La CSS macro de comparación es D.12 S.14 (1,676.058); no hay ancla, solo display |
| Deducciones personales al jefe del hogar; límite min(5 UMA, 15 %) | cableado | `H l.2325–2329`; `E l.180–198` | `DRR` cuadro 3.2.1: 45,232 mdp en 2024 (todas las PF) |

### §4 bis — Informalidad, elusión y evasión: los cuatro componentes (4c ampliado)

Estructura pedida: Potencial de referencia → − gasto fiscal (ELUSIÓN) = obligación estatutaria → − margen extensivo (INFORMALIDAD, corte anclado a cada `ancla_formales`) → − margen intensivo (EVASIÓN, residual) = recaudado. Sin interpretar. Todo sobre la base del probit de salarios (`prob_salarios != .`: 113,592 registros, 49,291,514 personas en v8.15.3; 123,426 y 54,228,512 en v8.14.0 porque `pensiones_en_yl = off` sacó a los jubilados). Script y salida: `D/4c-ampliado.py`, `4c-ampliado.out`, `4c-ampliado.csv`.

**Tabla 4c-a — Los componentes que hoy se pueden calcular (bn 2024)**

| Componente | v8.14.0 (`4c`) | v8.15.3 (`D`) | Contraste externo | Fuente |
|---|---:|---:|---|---|
| (0) Potencial de referencia: tarifa LISR 2024 sobre `ing_bruto_tax − cuotas netas`, **sin** `exen_tot` ni `deduc_isr`, parte salarial | no calculado | **1,387.103** con el share acotado a [0, 1]; 1,583.470 con el share libre de `H l.2433` | — | `D`; tarifa de `H l.397–407` |
| (0a) − Gasto fiscal del motor (exenciones + deducciones de la base salarial) | — | **−37.223** (acotado: el potencial sale *menor* que la obligación, artefacto del share) / 159.143 (libre) | `DRR` cuadro 3.2.2: ingresos exentos por salarios **235,381** mdp (0.6939 % PIB), de los que jubilaciones 95,091 (fuera de la base con `pensiones_en_yl = off`) → comparable **140,290**; cuadro 3.2.1 deducciones personales **45,232** (todas las PF) | `D`; `DRR` |
| (0b) − Subsidio al empleo (informativo; no está dentro de `ISR_asalariados`) | — | 34.109 (Σ `SE` de los formales del umbral) | `DRR` §III.1 f): **32,841** mdp (0.0968 % PIB; 34,773 con gobierno) | `D`; `DRR` |
| (a) = Obligación estatutaria (Σ `ISR_asalariados`, toda la base) | 1,337.390 | **1,424.327** | — | `4c`; `D`; CHANGELOG `[v8.15.0]` |
| (b) Σ *p* × obligación | 1,031.873 | 1,074.735 | — | ídem |
| (c) Recaudado (cut-off) | 1,253.743 | **1,253.780** | LIF ISR asalariados 1,253.785; `ITG` cuadro 3 sueldos y salarios 1,254,807 mdp | `L` l. 246; `LIF`; `ITG` |
| λ = (c)/(b) | 1.215016 | **1.166595** | — | |
| Umbral del corte (p mínima de los formales) | 0.137230 | **0.228499** | — | |
| Formales del modelo | 42,521,496 | **32,814,376** (informalidad 33.43 % de la base) | cotizantes IMSS+ISSSTE 25,500,447; ENOE 23.5 M; padrón SAT sueldos y salarios 51,858,257 | `4c`; `D`; `ITG`; `4c pr-body` l. 90–91 |

**Tabla 4c-b — Cuatro componentes × ancla de formales (bn 2024, base v8.15.3).** El corte toma a las N personas de mayor *p* (ranking de `H l.2432`); INFORMALIDAD = Σ obligación de los que quedan abajo; EVASIÓN = Σ obligación de los de arriba − LIF 1,253.785 (residual; negativa significa que la obligación del motor de los N formales no llega a la recaudación).

| `ancla_formales` | N formales | Σ obligación arriba del corte | INFORMALIDAD (extensivo) | EVASIÓN (intensivo, residual) | *p* mínima | Σ arriba / LIF |
|---|---:|---:|---:|---:|---:|---:|
| `ninguna` (recaudación LIF; umbral actual) | 32,814,376 | 1,253.780 | 170.547 | −0.004 (= 0 por construcción) | 0.2285 | 1.0000 |
| `sat` (padrón activo de sueldos y salarios, `ITG` cuadro 3) | 51,858,257 | 1,424.327 | 0.000 (el padrón supera a la base: 49.3 M) | +170.542 | 0.0025 | 1.1360 |
| `imss` (IMSS 22,238,379 + ISSSTE 3,262,068 al 31-dic-2024) | 25,500,447 | 1,129.737 | 294.590 | **−124.048** | 0.5365 | 0.9011 |
| `enoe` (asalariados con acceso a salud, 3T 2024) | 23,500,000 | 1,084.635 | 339.692 | **−169.150** | 0.6240 | 0.8651 |

Lectura mecánica, sin interpretar: (i) con `imss`/`enoe` el corte deja a 25.5/23.5 M y su obligación (1,129.7/1,084.6) no alcanza la LIF: el motor subestima la obligación de los más probables (CUAD-0 §4.0 C: «la obligación estatutaria sobre ingreso con Altimir uniforme sale baja»), y el residual sale negativo; (ii) con `sat` la base entera cabe en el padrón y toda la brecha es intensiva; (iii) ningún ancla cierra las cuatro cuentas con el ISR por rango, porque la fila (0)–(0a) depende de un share no acotado y de un gasto fiscal del motor que no se mide contra el `DRR` por concepto (aguinaldo, prima vacacional, PTU, horas extra, previsión social, cajas de ahorro están en `exen_t4_cap1`: Σ 450.064 en la base; `exen_tot` Σ 1,406.243). Lo que falta para cerrar: `isras_share = acotado`, el gasto fiscal por concepto del `DRR` como contraste del motor, y el SAT por rango **(no publicado para 2024)**.

Comparables de la base v8.15.3 (`D`): `cuotasTPF > 0` 43,074,483; `formal2 ∈ {1,3,4,6}` (IMSS) 26,390,703; `formal2 ∈ {2,5}` (ISSSTE) 4,820,969; `ing_t4_cap1 > 0` 51,028,544.

---

## §5 Anclas

### Tabla 1 — Consumo → SCN (una fila por rubro de `Expenditure.do`)

Σ ENIGH = Σ gasto_anual·factor en `preconsumption.dta` por `categ` (todos los `tipo_gasto`); Σ motor = `M<k>` (post-`perfilpc`, pre-ancla); factor actual = `TT<k>` = celda / Σ motor (`E l.1042`); las 19 celdas suman `ConHog` 24,192.112 al peso. Celda P.3 S.14 por finalidad: **(no en repo; INEGI no la publica en la CSI; el BIE 724601–724656 es «hogares e ISFLSH» en territorio)**. Regla: **I** = incidencia (quien consume). Sello amarillo = celda BIE identificada pero con ISFLSH y no residentes dentro; rojo = además una mezcla de contenido.

| Rubro (`categ`) | Claves ENIGH 2018 (`E l.315–365`) | Celda (BIE) | Valor | Σ ENIGH | Σ motor | Factor actual | Factor propuesto | Sello | Marca |
|---|---|---|---:|---:|---:|---:|---|---|---|
| 1 `Alim` | A001–A214, T901 | 724602 Alimentos | 5,524.006 | 2,177.453 | 2,423.856 | 2.2790 | mismo relativo; total a P.3 S.14 (`consumo_ancla`) | amarillo | T901 son regalos a otros hogares (53.208): G2 + G5 cuentan dos veces |
| 2 `BebN` | A215–A222 | 724603 Bebidas no alcohólicas | 620.675 | 169.647 | 184.215 | 3.3693 | ídem | amarillo | |
| 3 `BebA` | A223–A238 | 724605 Bebidas alcohólicas | 361.568 | 27.361 | 29.710 | **12.1697** | ídem; base del IEPS | **rojo** | subreporte ×12: la base del IEPS alcohol se infla con el ancla |
| 4 `Taba` | A239–A241 | 724606 Tabaco | 136.062 | 12.914 | 14.023 | **9.7030** | ídem | **rojo** | ídem (IEPS tabaco) |
| 5 `Vest` | H001–H083, T909 | 724608 Prendas de vestir | 328.684 | 193.628 | 215.401 | 1.5259 | ídem | amarillo | |
| 6 `Calz` | H084–H122 | 724609 Calzado | 123.494 | 121.302 | 131.717 | 0.9376 | ídem | amarillo | |
| 7 `Alqu` | G001–G004, G102–G106, R003–R004 | 724611 Alquiler efectivo + 724612 Conservación (`SCN.ado` l. 867) | 2,954.186 | 1,732.962 | 1,881.768 | 1.5699 | separar: alquiler imputado G102–G106 (1,408.154 ENIGH) = consumo de B.2n (CUAD-0, `ing_estim_alqu`); R004 predial (30.328) → D.59; R003 gas natural (16.576) → 724614 | **rojo** | 724611 no separa efectivo de imputado (CUAD-0 FLAG 18); el alquiler imputado consta dos veces en el motor: aquí como consumo y en `Households` como ingreso B.2n (consistente con el SCN: P.3 = B.2n del alquiler imputado) |
| 8 `Agua` | R002 | 724613 Agua | 64.995 | 76.033 | 82.562 | 0.7872 | ídem | amarillo | G005 recolección de desperdicios (6.381) cae en `HogaT` (COICOP 04.4, aquí) |
| 9 `Elec` | R001 | 724614 Electricidad, gas y otros combustibles | 744.701 | 139.677 | 151.670 | **4.9100** | mover G009 gas LP (111.599), G012–G014, G016 combustibles (8.679) y R003 gas natural (16.576) desde `HogaT`/`Alqu` | **rojo** | la ENIGH sí tiene gas (G009 111.599 bn) y el motor lo manda a «Artículos para el hogar»: el factor 4.9 es clasificación, no subreporte |
| 10 `HogaT` | G005–G016, K*, R013, T907, T912 | 724615 Artículos para el hogar | 1,366.870 | 304.548 | 356.294 | 3.8364 | sacar G005–G016 (combustibles y servicios de la vivienda: COICOP 04) | **rojo** | ver filas 8 y 9 |
| 11 `SaluT` | J*, T911 | 724622 Salud | 739.771 | 403.915 | 453.767 | 1.6303 | ídem | amarillo | G6 (transferencias de instituciones) 96.384 en salud: es D.63, no P.3 privado |
| 12 `Vehi` | M007–M009 | 724627 Adquisición de vehículos | 832.724 | 234.209 | 254.320 | 3.2743 | ídem; base del ISAN | amarillo | |
| 13 `FTra` | F007+, R012 | 724628 Funcionamiento de transporte | 2,715.704 | 534.772 | 580.692 | **4.6767** | R012 tenencia (23.116) → D.59; base del IEPS petrolero (`TM l.136`) | **rojo** | gasolinas: el subreporte ×4.7 infla la base del IEPS P; tenencia es impuesto |
| 14 `STra` | B*, M001–M006, T902, T914 | 724629 Servicios de transporte | 1,504.971 | 372.014 | 431.261 | 3.4897 | ídem | amarillo | G4 remuneración en especie 44.476 y G5 regalos 13.632 |
| 15 `ComuT` | F001–F006, R005–R011, T906 | 724630 Comunicaciones | 525.720 | 375.323 | 409.574 | 1.2836 | ídem; base del IEPS telecom | amarillo | |
| 16 `RecrT` | E008+, L001–L026, T905, T913 | 724634 Recreación y cultura | 1,185.699 | 370.033 | 468.796 | 2.5292 | ídem; juegos (IEPS) viven dentro (`TM l.28–31`) | amarillo | |
| 17 `EducT` | E001–E007 | 724641 Educación | 322.257 | 300.089 | 325.857 | 0.9890 | ídem | amarillo | G6 33.706 (becas/colegiaturas pagadas por instituciones): D.63 |
| 18 `RestT` | A242–A247, N003–N005 | 724647 Restaurantes y hoteles | 1,371.191 | 1,093.169 | 1,187.037 | 1.1551 | ídem | amarillo | G4 remuneración en especie 107.113 y G5 regalos 302.666 (comidas recibidas) |
| 19 `DiveT` | C*, D*, H123+, I*, L027+, M010–M018, N001–N002, N006+, T903–T904, T908, T910, T915, resto | 724650 Bienes y servicios diversos | 2,768.834 | 1,221.411 | 1,443.811 | 1.9177 | ídem | amarillo | residual (`categ = 19 if categ == .`) |
| **Σ 19** | | `ConHog` 724600 | **24,192.112** | **9,860.460** | **11,026.332** | **2.1940** (`TTConHog`) | **P.3 S.14 23,381.329** → factor único 0.96649 sobre los 19 | | |
| Compras netas de no residentes | — | 724777 `ComprasN` | −372.715 | — | ∝ `gastoanualTOT` (`H l.2845`) | 1 | sin cambio (S.2, Tabla 2) | amarillo | Cpriv = 24,192.112 − 372.715 = 23,819.398 (`N l.456`) |
| **Fila −438.069: Cpriv motor vs P.3 S.14** | | | 23,819.398 vs 23,381.329 | | | | | | **Descomposición:** P.3 S.15 (ISFLSH) **388.320** (CSI_118 f.166) + vintage BIE−CSI del consumo de residentes **49.749** (23,819.398 − 23,381.329 − 388.320) = 438.069. **Por rubro: (no en repo)**: la CSI no publica P.3 por finalidad ni para S.14 ni para S.15; la única apertura por finalidad (BIE 7246xx) ya es hogares + ISFLSH |

**Por `tipo_gasto` (ENIGH 2024, Σ gasto_anual·factor, bn; `D`):** G1 monetario para el hogar 7,358.337 · G2 monetario para otro hogar 90.530 · G3 autoconsumo 73.235 · G4 remuneraciones en especie 217.340 · G5 regalos recibidos de otro hogar 548.144 · G6 transferencias de instituciones 164.719 · G7 estimación del alquiler 1,408.154 · total 9,860.460. Lo que el SCN cuenta como P.3 de hogares: G1 + G3 + G4 + G7 y **una sola vez** los regalos entre hogares (G2 o G5, no ambos); G6 es D.63 (Tabla 2). Las cifras por categoría × tipo están en `D/tabla1.out`.

**El +11.8 % entre Σ ENIGH y Σ motor (Resumen 2).** Σ (gas_hog + gas_ind)·factor en `consumption_categ_pc.dta` = 10,154.393 (= Σ ENIGH en las 11 categorías sin gasto individual al peso; en las 8 con individual el `gas_ind` sale ×1.40 sobre `preconsumption`); Σ gas_pc = 11,026.332 = **1.085868 × (hog + ind) en las 19 categorías**. Por hogar, el cociente Σ_i gas_pc / (gas_hog × tot_integ) tiene **mínimo, cuartiles y mediana exactamente 1.085868**, media 1.093 y máximo 19.70 (`D/tabla1.py`, primeros 300,000 registros, `BebN`): ningún hogar queda por debajo de la constante y algunos reciben más. La constante no es de `perfilpc` (que conserva Σ_i x_i del valor con el que arranca) sino de lo que `o<var>` ya traía al entrar (`ogas_pc_BebN` = 1.085868 × `gas_hogBebN` en el mismo registro). **(causa no identificada en esta sesión: por identificar en 8.16; los datos son los de la corrida canónica del 16-oct en `-datos`)**.

### Tabla 1b — Impuestos y cuotas → quién paga (una fila por impuesto de `TasasEfectivas`)

Base gravable del motor = la variable micro que define la incidencia; celda SCN = dónde lo registra la CSI y en qué sector; recaudado = LIF 2024 (`recaudacion`, `divSIM`); Σ motor = lo que el módulo reparte (igual a la LIF por construcción salvo nota). Regla: **I** = incidencia · **P** = propiedad · **C** = per cápita. Sello amarillo = total con celda SCN identificada y sector pagador distinto del que el motor asume; rojo = sin celda o base equivocada.

| Impuesto / cuota | Base gravable del motor (incidencia hoy) | Celda SCN (sector pagador → receptor) | Valor SCN | LIF 2024 | Σ motor | Factor actual | Propuesto | Regla | Sello | Fuente |
|---|---|---|---:|---:|---:|---:|---|---|---|---|
| ISR asalariados (`ISRAS`) | `ISR_asalariados` = tarifa(`ing_bruto_tax − exen_tot − deduc_isr − cuotas netas`) × `ing_subor/(ing_bruto_tax − cuotasTPF)`; cut-off por ranking de `prob_salarios` | D.51 S.14 → S.13 (dentro de 1,518.912; la CSI no separa asalariados de PF) | D.5 S.14 1,540.050 (D.51 1,518.912 + D.59 21.138) | 1,253.785 | 1,253.780 (cut-off) | 1 (LIF) | ancla del **total** S.14: ISRAS + ISRPF = 1,330.838 → D.51 S.14 1,518.912 (factor 1.1413) o D.5 1,540.050 (1.1572); `isras_share = acotado`; `informalidad`/`ancla_formales` de §4 | I | amarillo | `H l.2433–2439`; CSI_115 f.114–116; `LIF`; `L` l. 246 |
| ISR personas físicas (`ISRPF`) | `ISR_PF = ISR − ISR_asalariados` si > 0; cut-off por `prob_formal` (informalidad 76.07 %) | D.51 S.14 (misma celda) | ídem | 77.053 | 77.053 | 1 | ídem (una sola celda para ISRAS + ISRPF); con `isrpm_incidencia = propiedad`, `ing_bruto_tpm` entra aquí como actividad empresarial | I | amarillo | `H l.2455–2462`; `L` l. 247 |
| **Fila +209.212: D.5 S.14 vs ISR LIF de personas** | | | 1,540.050 | 1,330.838 | | | **No es vintage: es clasificación.** ISR LIF total 2,682.265 (1,253.785 + 77.053 + 1,351.427) vs D.51 S.1 2,684.588 (+2.323); la CSI pone en S.14 1,518.912 y en S.11 + S.12 1,165.676; la LIF pone en personas 1,330.838 y en PM 1,351.427. D.59 S.1 44.110 (S.14 21.138, S.11 22.953, S.12 0.019) no está en la LIF como ISR (tenencia, predial: `OTROSK`/estatales) | | | CSI_103 f.114–116; CSI_106/109/115 f.114–116 |
| ISR personas morales (`ISRPM`) | `ISR_PM = (ing_bruto_tpm + depreciación − exen_tpm) × 0.3 − SE_empresas`; cut-off por `prob_moral` (49.98 %); base = negocios propios P068–P081 | D.51 S.11 1,020.417 + S.12 145.259 → S.13 | D.5 S.11 + S.12 1,188.648 (D.51 1,165.676 + D.59 22.972) | 1,351.427 | 1,351.427 | 1 | **FLAG 19:** `isrpm_incidencia = propiedad`: total LIF (o D.5 S.11 + S.12) ∝ `ing_d4_rel`; TE con denominador B.5n S.11 + S.12 (953.904) o B.2n (6,723.499) en vez de `IngKPrivado` | **P** | **rojo** | `H l.2482–2489`; `I l.206–208`; `T l.112–122, 145`; CSI_106/109 f.114–116 |
| Otros tributarios y no tributarios (`OTROSK`: derechos 124.485, productos 13.405, aprovechamientos 234.137, otros tributarios 78.117) | fiscal: per cápita (`ing_cap_*` ∝ factor, `H l.2848–2852`); NTA: ∝ `ISR_PM` (`N l.531`, informativo) | mezcla: D.59 (44.110), D.29 (267.123, por sector productor), D.45 recibida por S.13 (224.114), D.75/D.9 | sin celda única | 450.142 | 450.142 | 1 | partir por concepto: derechos ∝ consumo del servicio (I), aprovechamientos → sector (P), tenencia/predial (D.59) ∝ `gas_pc_Vehi`/alquiler | mixta | **rojo** | `LIF` divCIEP; CSI_103 f.52, 105, 116 |
| FMP (`FMP`) | fiscal: per cápita; Sankey: «Empresas públicas → Gobierno» (`oye_en_hub = off`) | D.45 S.13 recibida 224.114 (D.452 202.584 + D.459 21.529) ← S.11 (Pemex paga D.45 254.502) | 224.114 | 203.942 | 203.942 | 1 | fila de sector S.11 → S.13 (CUAD-2); sin persona | — | amarillo | CSI_112 f.105–108; CSI_106 f.105 |
| Pemex, CFE, IMSS, ISSSTE ingresos propios | no se reparten (`oye_en_hub = off`) | P.11 (ventas) de S.11/S.13: no es impuesto ni ingreso del gobierno en el SCN | — | 754.972 + 521.463 + 61.542 + 59.904 = 1,397.881 | 1,397.881 | 1 | sin cambio: fila de sector | — | amarillo | CUAD-0 §4 `oye_en_hub`; `LIF` |
| Cuotas IMSS (`CUOTAS`) | `CUOTAS_Sim = CUOTAS × 1.675/1.525 if formal2 == 1` (`I l.213`); `Distribucion CUOTAS_Sim ∝ CUOTAS` (`T l.335`); NTA: `cuotasTP + infonavit` → D.61 − D.614 = 1,729.089, **todo a Gobierno** | D.61 pagada por S.14 2,335.022 = D.611 patrón 1,454.229 + D.612 imputada 221.830 + D.613 trabajador 87.878 + D.614 complementaria 605.932 − D.615 34.847 → **receptores** S.13 683.959, S.12 1,455.102, S.11 193.870, S.15 2.091 | 2,335.022 (S.14 U/A) | 565.754 (solo Cuotas IMSS) | fiscal 565.754; NTA 1,729.089 | 1 / 1 | `cuotas_por_sector = on`: tabla abajo | I | amarillo | CSI_115 f.117–130; CSI_106/109/112/118 f.117 |
| · cuotas por sector **pagador** (patrón) | el motor las imputa al trabajador (`cuotasP` ∝ SBC; `H l.1614–1640`) | D.121 + D.122 pagadas: S.11 686.113 + 193.870; S.12 150.602 + 15.107; S.13 608.244 + 10.762; S.15 9.269 + 2.091; Σ = D.12 S.14 1,676.058 | 1,676.058 | — | `cuotasP + cuotasIMP` sin ancla (display `L` l. 53–59: 4.364 vs 4.978 % PIB) | — | regla I al trabajador (SNA: D.12 es parte de D.1, el trabajador lo paga como D.611/D.612): sin cambio de incidencia, con origen por sector para el Sankey | I | amarillo | CSI_106/109/112/118 f.38–43 |
| · cuotas del **trabajador** | `cuotasT` ∝ SBC; `infonavit` 5 % | D.613 87.878 + D.614 605.932 (= D.442: circuito `cuotas_d614`) − D.615 34.847 | 658.963 | — | sin ancla | — | ídem | I | amarillo | CSI_115 f.124–130 |
| · cuota social / aportación federal (`cuotasF`) | ∝ SBC; `SSFederacion` PEF (0.569 % PIB = 191.6) | S.13 como **patrón** (D.121 608.244) y como aportante: la CSI no tiene celda para la cuota social (es D.73 dentro del gobierno general o D.62) | — | PEF 191.6 | `L` l. 55: 0.513 vs 0.569 % PIB | — | fuera de las cuotas de personas: transferencia S.13 → S.13 (IMSS) | — | **rojo** | `H l.263, 1649–1677`; CSI_112 f.146 |
| IVA | precio × cantidad × `va_ratio` × 16/116 por `categ_iva` (`IVAT`); `Distribucion IVA_Sim ∝ IVA` | D.211 S.1 1,407.983 (R/P S.13) | **1,407.983 = LIF al peso** | 1,407.983 | micro 1,831.8 (5.441 % PIB) → LIF | 0.7687 (= 1 − 23.1 %) | celda D.211; `consumo_precios`; la «informalidad» 23.1 % (`IVAT[13]`) es el cociente, no una medición | I | amarillo | `E l.1196–1215`; CSI_103 f.46; `SIM.do` l. 288 |
| IEPS no petrolero (`IEPSNP`) | micro ad valorem + cuota por `categ_ieps` (28.3 bn = 0.084 % PIB); NTA ∝ `gas_pc_BebA` | D.214 S.1 581.072 (impuestos sobre productos excepto IVA e importaciones; no separa IEPS de ISAN y estatales) | 581.072 (IEPS + ISAN LIF = 647.139) | 224.780 (divSIM) / 24.075 (divCIEP «no petrolero», lo que `E l.109` usa) | micro 28.3 → LIF 224.780 | 7.94 (micro → LIF) | `iepsnp_macro = divsim`; `ieps_relativo = micro`; declarar los 200.705 de «IEPS (salud)» que `Expenditure.do` no compara | I | **rojo** | `E l.109, 1299–1303`; `N l.534`; `LIF` divCIEP |
| IEPS petrolero (`IEPSP`) | micro: **0** (gasolinas se saltan, `E l.1282`); TE: `ConsPriv_21` 678.177 (BIE 725116, consumo privado de minería); NTA ∝ `gas_pc_Vehi`; `TM` ∝ `gas_pc_Gasolinas + Combustibles` | D.214 S.1 (misma celda) | — | 403.584 | 403.584 | 1 | relativo = gasolinas + combustibles (como `TM l.136–137`); base macro = `FTra` 724628 o `ConsPriv_21` | I | **rojo** | `E l.1282`; `T l.239, 282–287`; `N l.535`; `TM l.136–137` |
| ISAN | ∝ `gas_pc_Vehi` (`H l.2855`); TE sobre `Vehi` 832.724 | D.214 S.1 (misma celda) | — | 18.775 | 18.775 | 1 | sin cambio | I | amarillo | `H l.2855`; `T l.266–271` |
| Importaciones (`IMPORT`) | ∝ `gastoanualTOT` (`H l.2856`); TE sobre `ConHog` | D.2122 S.1 280.906 (impuestos sobre importaciones excl. IVA y derechos) | 280.906 | 137.822 | 137.822 | 1 | celda D.2122; el resto (143.084) es IEPS/ISAN de importación dentro de la misma celda **(no separable en la CSI)** | I | amarillo | `H l.2856`; CSI_103 f.47–49 |
| Impuestos netos a los productos (`ImpNetProductos`) | ∝ `gastoanualTOT` (`H l.2837`); NTA `ImpProd` ∝ Cpriv (`N l.462`) | D.21 − D.31 S.1 = 2,269.960 − 94.053 (R/P S.13) | 2,175.907 (BIE `ImpNet` 2,174.811) | IVA + IEPS + ISAN + IMPORT = 2,192.944 (τ⁻ indirectos) | 2,175.907 | 1 | sin cambio; la fila −17.036 de la brecha de S es LIF vs devengado | I | amarillo | CSI_103 f.25–26; `nta-identidad.txt` |
| Impuestos netos a la producción (`ImpNetProduccion`) | ∝ `ing_bruto_tax + ing_bruto_tpm` (`H l.2841`) | D.29 − D.39 por sector **productor**: S.11 199.756 − 12.009; S.12 32.699; S.13 34.188; S.15 0.480; **S.14 0** (CSI_115 f.52) | 255.114 | — (nómina y estatales no están en la LIF) | 255.114 | 1 | los hogares no pagan D.29 en la CSI: regla P ∝ `d4_relativo` (como el excedente) o fila de sector (CUAD-2) | P | **rojo** | CSI_106/109/112/115/118 f.52, 58 |

**Cuotas por sector (D.61 2024, bn; CSI f.117–130 de cada cuadro):** pagan los hogares 2,335.022 (toda D.61 es «de S.14» porque D.12 se imputa primero al trabajador como D.1); reciben S.13 683.959 (D.611 673.011 + D.612 10.762 + D.613 0.186), S.12 1,455.102 (D.611 781.217 + D.612 15.107 + D.613 87.692 + D.614 605.932 − D.615 34.847), S.11 193.870 (D.612 imputadas: planes de empleadores), S.15 2.091 (D.612). Hoy el motor manda 1,729.089 (NTA) o 565.754 (fiscal) a Gobierno. La cuota social del gobierno federal (`cuotasF`, PEF) no es D.61: es gasto del gobierno (D.73/D.62) y no debe sumarse como cuota pagada por personas.

---

## §6 Salidas

| Archivo / JSON / figura | Qué contiene | Quién lo consume | Check de CI que lo protege |
|---|---|---|---|
| `master/<año>/consumption_categ_pc.dta`, `consumption_categ_iva_pc.dta`, `consumption_categ_ieps_pc.dta` | gasto per cápita por categoría pre-ancla (`gas_pc_*`, `ogas_pc_*`, `gas_hog*`, `gas_ind*`) | `Expenditure.do` §4–§6; `TasasEfectivasMicro` | sin protección automática — gate humano (caché: se recalcula solo si falta) |
| `master/<año>/expenditures.dta`, `categ_iva.dta`, `consumption_categ_iva.dta`, `consumption_categ_ieps.dta`, `deducciones.dta` | consumo anclado (`gas_pc_* × TT`), IVA e IEPS por persona, deducciones personales | `Households.do` §1.6, §12; `NTA.do`; `PerfilesSim.do` | ídem |
| Escalares `TT*`, `E*PIB`, `EE*PIB`, `gini*`, `IVAHHSPIB`, `DifIVA`, `IEPSNP*` | anclas y diagnósticos de consumo | log; `scalarlatex` | `scalarlatex-baseline.txt` (deriva) |
| `users/<id>/ingresos.dta` (`*_Sim`), `isr_mod.dta` | recaudación por persona por impuesto | `INCI.ado` → `INCD*` de `output.txt`; `aportaciones.dta`; 32 entidades | `gate-numeros.sh` (en sesión); `contrato-32.sh` |
| `output.txt`: `INGRESOS` (LIF `anioPE` % PIB), `INGRESOSTEF` (TE), `IVA`, `ISRTASA`, `INCD/INCD2/INCD3` | lo que el sitio muestra | sitio; sidecar | `gate-numeros.sh` byte a byte (sesión); `test-web-batch.sh` 47/47 |

## §7 Identidades que 8.16 debe cerrar

Estado en v8.15.3 (`nta-identidad.txt` de `-datos/users/ricardo/NTA/`, 2026-11-03) y propuesta.

| Identidad | Hoy | Debe quedar | Tolerancia | Quién la comprueba |
|---|---|---|---|---|
| Σ Cpriv = P.3 S.14 | 23,819.398 vs 23,381.329 (**−438.069** en S) | igual al peso con `consumo_ancla = p3_s14`; ISFLSH 388.320 y vintage 49.749 como filas de sector | 1e-9 rel. | gate nuevo en `Expenditure.do` §4.1 + `nta-identidad.txt` |
| Σ 19 categorías = celda total | 24,192.112 = `ConHog` al peso | = P.3 S.14 (o `ConHog` con `conhog`, declarado) | 1e-9 | ídem |
| Σ Cpriv por `tipo_gasto`: regalos una sola vez | G2 90.530 **y** G5 548.144 | solo G5 (consumo del que recibe) o solo G2 (gasto del que da), declarado | — | gate de clasificación |
| Σ cuotas = D.61 por sector receptor | 1,729.089 todo a Gobierno (NTA); 565.754 (fiscal) | S.13 683.959 + S.12 1,455.102 + S.11 193.870 + S.15 2.091 = 2,335.022 (con D.614) | 1e-9 | `NTA.do` §4.6 + Sankey |
| Σ ISR de personas = D.5 S.14 | 1,330.838 (LIF) vs 1,540.050 (**+209.212**) | ancla a D.51 S.14 1,518.912 (D.59 aparte) o a D.5; la diferencia con la LIF se declara como «LIF vs CSI por sector» | 1e-9 | `nta-identidad.txt`, tabla «De dónde sale la brecha» |
| Σ ISR PM = D.5 S.11 + S.12 | 1,351.427 (LIF) vs 1,188.648 | mismo tratamiento; incidencia P | 1e-9 | ídem |
| τ⁺ efectivo vs D.62 + D.7 netas | 4,824.887 vs 4,363.876 (**+461.011**) | es de 8.17 (D.62 privado 442.344 fuera de Gobierno; D.759 de S.11 700.204 no va a hogares) | — | CUAD-2 |
| **Σ S sin ancla vs B.8n S.14** | **2,116.145 vs 1,901.026: +215.119 (+11.3 %)** | tras cerrar 209.212 (D.5) + 461.011 (τ) − 438.069 (Cpriv): 215.119 − 232.154 = **−17.035** = la fila LIF vs devengado de los indirectos (**−0.9 %**) | ≤ 15 % para que `nta_anclaS = auto` siga en multiplicativo; la meta de 8.16 es declarar los −17.035 y apagar el ancla | `NTA.do` §4.11 |
| IEPS micro vs macro | 28.3 vs 24.075 (`DifIEPSNP` 15.0 %) | 28.3 vs 224.780 declarado; gasolinas con micro | — | `Expenditure.do` §6.3 |
| Parte salarial del ISR ∈ [0, 1] | mediana 1.150; extremos ±miles | acotada | — | gate nuevo en `Households.do` §11.1 |

## §8 Límites conocidos

| # | FLAG | Magnitud (bn) | Cierre propuesto |
|---|---|---:|---|
| 20 | Σ motor del consumo = 1.085868 × Σ (hog + ind) en las 19 categorías; `gas_ind` ×1.40 sobre `preconsumption` | +1,165.872 (11.8 %) | 8.16: localizar entre `E l.577–780`; gate Σ motor = Σ ENIGH |
| 21 | Consumo anclado a hogares + ISFLSH en territorio (`ConHog`) y no a P.3 S.14 | −438.069 | 8.16: `consumo_ancla = p3_s14` |
| 22 | Regalos entre hogares contados dos veces (G2 + G5) | 90.530 | 8.16: decidir cuál cuenta |
| 23 | Transferencias en especie de instituciones (G6) dentro del consumo privado | 164.719 | 8.17: es D.63 (Tabla 2) |
| 24 | Predial y tenencia (R004, R012) dentro del consumo | 53.444 | 8.16: → D.59 (`OTROSK`) |
| 25 | Gas LP y combustibles (G009–G016) en «Artículos para el hogar», no en 724614 | 120.278 | 8.16: reclasificar |
| 26 | IEPS no petrolero comparado contra 24.075 en vez de 224.780; IEPS petrolero sin micro; NTA reparte IEPS ∝ vehículos / ∝ alcohol | 628.364 | 8.16: `iepsnp_macro`, `ieps_relativo` |
| 27 | Parte salarial del ISR no acotada (`H l.2433`) | Σ obligación 1,424.327 depende de ella | 8.16: `isras_share = acotado` |
| 19 | ISR PM sobre negocios propios (CUAD-0) | 1,351.427 | 8.16: `isrpm_incidencia = propiedad` |
| 13 | Cuotas todas a Gobierno (CUAD-0) | 1,045.130 | 8.16: `cuotas_por_sector = on` (destinos); 8.17: nodos |
| 28 | Cuota social federal (`cuotasF`) sumada como cuota de personas | 0.569 % PIB ≈ 191.6 | 8.16: fuera de `cuotasTPF`; es gasto S.13 |
| 29 | Factores de empalme cableados en `ISR_Mod.do` (3.793/3.255, …) | ISR web vs batch | 8.16: leerlos de la corrida (`char`), como `TaltimirSal` |
| 30 | Sin ancla SAT por rango para la obligación de ISR PF | — | **no publicado por SAT/SHCP para 2024**; alternativa INAI o 2015 con sello rojo |
| 31 | Tablas de cuotas IMSS/ISSSTE 2021 con UMA 2024 | — | 8.16: vintage declarado |
| 32 | Anclas de informalidad externas no cierran la LIF (`imss`/`enoe` dan evasión negativa) | −124.048 / −169.150 | 8.16: primero FLAG 27 y gasto fiscal por concepto; después decidir ancla |

## §9 Específico de México

| Elemento | Qué requiere genéricamente | Por qué México lo resuelve así | En cap0 |
|---|---|---|---|
| Consumo privado por finalidad (BIE 724600–724656) | Consumo final de hogares por COICOP con el sector hogares separado de las ISFLSH | INEGI publica la apertura por finalidad solo para «hogares e ISFLSH» en territorio (BIE); la CSI separa S.14 de S.15 solo en el total P.3. Por eso el ancla por rubro es hogares + ISFLSH y la corrección a S.14 es un factor único | fila 4 (nueva línea: P.3 por finalidad) |
| ENIGH `tipo_gasto` y claves 2018 | Encuesta de gasto con tipo (monetario, autoconsumo, regalos, en especie, transferencias, alquiler imputado) y catálogo estable | La ENIGH 2024 «nueva serie» cambió claves (6 dígitos); el motor trabaja con `clave_2018` vía `clave_iva.dta` (construida por CIEP) | fila 2 |
| Recaudación por impuesto (LIF, `divSIM`) | Recaudación observada por impuesto del año de la encuesta, compatible con el SCN | La LIF/SHCP publica mensual por concepto (ISR asalariados, PF, PM; IVA; IEPS por producto); el SCN no separa IVA de IEPS por sector pagador (D.211 sí es IVA al peso; D.214 junta IEPS, ISAN y estatales) | fila 7 |
| Declaraciones anuales por rango (SAT) | Base gravable e ISR causado por rango de ingreso del año de la encuesta | El SAT publica microdatos anonimizados solo 2010–2015 (`SAT más abierto`) y el ITG trimestral con padrón y recaudación por régimen sin rangos; para 2024 **no existe** la tabla | fila 12 (nueva línea) |
| Gasto fiscal (SHCP, Renuncias Recaudatorias) | Estimación oficial del costo de exenciones, deducciones y subsidios por concepto y año | La SHCP lo publica anual (2024: ingresos exentos por salarios 235,381 mdp, de ellos jubilaciones 95,091; deducciones personales 45,232; subsidio al empleo 32,841) con PIB 33,927,700 mdp (DRR) ≠ BIE 33,667,023 | fila 12 (nueva línea) |
| Formalidad oficial (IMSS, ISSSTE, ENOE) | Conteo oficial de cotizantes o de asalariados formales del año | IMSS publica puestos afiliados (22,238,379 al 31-dic-2024), ISSSTE trabajadores activos (3,262,068), ENOE asalariados con acceso a salud (23.5 M, 3T 2024); tres definiciones distintas y ninguna es «contribuyente de ISR» (SAT: 51,858,257 activos en sueldos y salarios) | fila 12 |
| Cuotas por régimen (IMSS, ISSSTE, Infonavit, cuota social) | Tablas de contribución por ramo y tope salarial | Las tablas viven en informes financieros (IMSS 2021-2022, ISSSTE IFA 2021); la cuota social la paga el gobierno federal y la ENIGH no la ve | fila 12 |

## §10 Procedencia

| Sección | Archivo y líneas |
|---|---|
| Encabezado | `SIM.do` l. 28–30, 79–91, 134; `git log -- 01_modulos/Expenditure.do TasasEfectivas.ado` |
| §2 | `Expenditure.do` l. 98–126, 142–157, 200–226, 263; `Households.do` l. 258–336, 395–421, 1572–1595; `TasasEfectivas.ado` l. 22–45, 61–63, 112–119, 234–247; `05_scripts/manifest.json` (assets, `scn_vintage`) |
| §3 | `Expenditure.do` l. 142–205, 208–271, 314–474, 518–876, 1039–1056, 1163–1236, 1247–1347; `TasasEfectivas.ado` l. 60–307, 329–336; `ISR_Mod.do` l. 59–246; `Households.do` l. 1572–1735, 1826–1890, 2319–2343, 2382–2499 |
| §4 | `Households.do` l. 2384–2388, 2432–2439, 2482–2489, 2837–2841; `NTA.do` l. 456–463, 517–540; `Expenditure.do` l. 109, 1282, 1299–1303; `ISR_Mod.do` l. 184, 193, 208, 213; `SIM.do` l. 288; `D/4c-ampliado.py`; `DRR` cuadros 3.2.1–3.2.3, §III.1 f); `ITG` cuadros 3, 25; SAT `sat_mas_abierto.html`; `diag-v8.15b-pre-2026-10-31/pr-body.md` l. 85–93 |
| §5 Tabla 1 | `Expenditure.do` l. 148–149, 315–365, 903–925, 1042; `SCN.ado` l. 867; `scn-celdas.md` A; `raw/ENIGH/2024/clave_iva.dta` (claves G/R/T); descriptor ENIGH 2024 (`tipo_gasto`, pp. 14087–14113 del texto extraído); CSI_115 f.166, CSI_118 f.166; `D/tabla1.py`, `tabla1.out` |
| §5 Tabla 1b | `Households.do` l. 1614–1735, 2433–2499, 2837–2856; `NTA.do` l. 517–540; `TasasEfectivas.ado` l. 60–307; `TasasEfectivasMicro.ado` l. 118–137; `ISR_Mod.do` l. 182–213; `-datos/master/LIF.dta`; CSI_103 f.25–26, 44–58, 105, 114–116; CSI_106/109/112/115/118 f.35–43, 52, 58, 105, 114–130 |
| §7 | `-datos/users/ricardo/NTA/nta-identidad.txt` (2026-11-03); `NTA.do` l. 619–657 |
| §9 | fuentes de la tabla «Fuente» |
| Δ esperado | aritmética de §5 y §7; `output.do` l. 54–98 |

---

## Δ esperado de 8.16

Solo por inferencia de las tablas; nada se corrió. `baseline` pasa a **v8.16.0** (los números dejan de comparar con v8.15.x).

| Llave / agregado | v8.15.3 | 8.16 (propuesto) | Dirección | Por qué |
|---|---:|---:|---|---|
| Σ Cpriv (`nta-identidad.txt`) | 23,819.398 | 23,381.329 | ↓ −438.069 | `consumo_ancla = p3_s14` |
| Σ S sin ancla vs B.8n | 2,116.145 (+11.3 %) | ≈ 1,883.991 (**−0.9 %**) si cierran D.5 y τ (8.17) y Cpriv | ↓ | §7 |
| `CUADRATURA` (YL, YA, …) | 43.636, 24.435, … | **sin cambio** | = | 8.16 no toca las anclas de `Households` §9 |
| `INGRESOS` (LIF `anioPE` % PIB, 20 valores) | 3.855, 0.244, 1.782, … | **sin cambio** | = | son la LIF 2027; no dependen del micro |
| `INGRESOSTEF[4,5,6]` (ISRPMTE, OTROSKTE, IngKPrivadoTotTE) | 12.9, 5.0, 19.5 | cambian si el denominador pasa de `IngKPrivado` (CapIncImp − públicos) a B.5n o B.2n de S.11 + S.12 | ↑ con B.5n (denominador menor) | `isrpm_incidencia` |
| `INGRESOSTEF[9]` (IEPSNPTE) | 47.9 | sin cambio (el macro de `TasasEfectivas` ya es `divSIM`) | = | `iepsnp_macro` solo corrige `Expenditure.do` |
| `INCD`, `INCD2`, `INCD3` (43 bloques: incidencia por decil, nacional y 32 entidades, ISR/IVA/…) | — | **se mueven**: ISR PM ∝ `d4_relativo` concentra en deciles altos; IEPS ∝ gasolinas/alcohol/tabaco reparte distinto; cuotas por sector no cambia quién paga | ISR PM ↑ en X, ↓ en I–VIII | `isrpm_incidencia`, `ieps_relativo` |
| `GASTOS`, `GASTOSPC`, `GASTOSPOB*`, `PROY*` | — | **sin cambio** | = | PEF, no micro |
| `IVA` (parámetros `IVAT`) | 16, 1, 2, …, 23.1 | sin cambio salvo que `consumo_ancla` mueva `DifIVA` (el micro se reescala a `ConHog/MTot`, `E l.1190`: con P.3 S.14 el reescalamiento baja a 0.9665 → IVA micro 1,770.4 y `DifIVA` ≈ 20.5 %) | `IVAT[13]` ↓ ≈ 2.6 pp (si se recalibra) | `E l.1190–1215` |
| Sankey NTA v3: nodo `Gobierno` | 5,252.870 entradas desde `Ing nacional` | −1,045.130 de cuotas (van a S.12/S.11) | ↓ | `cuotas_por_sector` (nodos en 8.17) |
| 10 sankeys, 32 entidades (`contrato-32.sh`) | baseline v8.15.0 | re-baseline | ROJO esperado | |

Lo que **no** se infiere de las tablas: cuánto cambia la distribución por decil del ISR PM con `ing_d4_rel` (depende de la cobertura 0.43 % de la ENIGH en D.4: sello rojo de CUAD-0) y el tamaño del +11.8 % de la base del consumo una vez localizado (FLAG 20).
