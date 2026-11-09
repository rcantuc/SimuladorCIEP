# CUAD-1 — Capítulos `Expenditure` y `TasasEfectivas` del método: estado en v8.15.3 y propuesta de Cuadratura II (8.16)

**Fecha:** 2026-11-07 · **Sesión:** 8.16/8.17-memo (memo; ningún `.do`/`.ado`/número publicado cambia) · **Base:** `master` `9005ed3` (v8.15.3; baseline `v8.15.0`) · **Estado:** **firmado** por Ricardo el 2026-11-07 (`CUAD-1-2-firma.md`; la firma está fundida en §4.0) e **implementado en la sesión 8.16b** (v8.16.0, rama `sesion/8.16b`; §4 lleva los valores firmados, §7 los gates nuevos y su resultado, §8 los FLAGs cerrados y abiertos). **Sesión 8.16a (2026-11-07):** se añaden §8 bis (diagnóstico de los hallazgos: dónde, mecanismo, desde cuándo, cuánto pesa, corrección) y §8 ter (plan de retiro de `ISRInformesTrimestrales.xlsx`); se corrigen la Tabla 1 (Σ ENIGH) y la decisión 9 (el ITAN sí publica el ISR por rango); el motor no cambia de números. **Sesión 8.16b (2026-11-08):** todo lo propuesto en §4 entra como parámetro con el valor firmado como default; `baseline = v8.16.0`.

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
2. **La base micro del consumo lleva un factor uniforme de 1.085868 que no es de la ENIGH (FLAG 20, identificado en 8.16a, §8 bis).** Es el deflactor: `Simulador.ado` (rutina de gráficas) divide la variable graficada entre el deflactor del año de la corrida **sobre el propio dataset** (l. 109, sin `if` ni `restore`), y `Expenditure.do` la invoca sobre `ogas_pc_<k>` y `gas_pc_<k>` cuando hay gráficas (l. 801, 830); la caché `consumption_*_pc.dta` del 16-oct nació de una corrida con gráficas y `1/deflactor_2024(base 2026) = 1/0.920922131 = 1.085868139` quedó dentro (reproducido con `PIBDeflactor` al noveno decimal). Σ motor `M<k>` = 11,026.332 = 1.085868 × 10,154.393, y 10,154.393 **sí** es la ENIGH (Σ hogar + individual con el factor de `concentrado`): la cifra 9,860.460 de la primera versión de este memo dejaba fuera 293.933 bn de `gastotarjetas` (filas sin factor en `preconsumption.dta`, que el motor recupera en §3.3). Peso en los números publicados: **cero** (el total anclado no cambia; `gas_pc_*` anclado idéntico a 1e-15 con y sin el factor, corrida R1 de 8.16a); peso en el log: `ETotPIB` 32.751 → 30.161 % del PIB y cada `TT<k>` ×1.085868 (`TTConHog` 2.194 → 2.382). Corrección en 8.16b: copia temporal en `Simulador.ado` + regenerar la caché; no mueve `baseline`.
3. **Lo que la ENIGH clasifica como consumo y el SCN no:** regalos a otros hogares (G2, 90.530) **y** regalos recibidos (G5, 548.144) cuentan los dos; transferencias en especie de instituciones (G6, 164.719: D.63, consumo de gobierno/ISFLSH, no P.3 privado); predial (R004, 30.328: D.59) y tenencia (R012, 23.116: D.59) dentro de «Alquileres» y «Transporte». El alquiler imputado de la ENIGH (G102–G106, 1,408.154) viaja en la categoría `Alqu` y se ancla a BIE 724611+724612 (2,954.186), que no separa efectivo de imputado (CUAD-0 FLAG 18).
4. **Los impuestos no tienen celda SCN: todos se anclan a la LIF.** El total sí cuadra: ISR LIF 2,682.265 vs D.51 S.1 2,684.588; indirectos LIF 2,192.944 vs D.21 − D.31 2,175.907. Lo que no cuadra es **quién paga**: la CSI pone 1,540.050 de D.5 en S.14 y la LIF solo 1,330.838 de ISR de asalariados y PF (**+209.212**, el renglón de CUAD-0); la diferencia está en S.11+S.12 (D.5 1,188.648 vs ISR PM LIF 1,351.427). Las cuotas: la LIF solo ve 565.754 (IMSS) y la CSI 2,335.022 pagadas por S.14 a cuatro sectores (S.13 683.959, S.12 1,455.102, S.11 193.870, S.15 2.091).
5. **Tres bases están mal construidas y hoy no se ven porque el ancla LIF las tapa:** el IEPS no petrolero de `Expenditure.do` compara contra 24.075 (divCIEP «IEPS (no petrolero)») y no contra 224.780 (divSIM `IEPSNP`, que sí usa `TasasEfectivas`); `NTA.do` reparte el IEPS petrolero ∝ compra de vehículos (`gas_pc_Vehi`) y el no petrolero ∝ bebidas alcohólicas solamente; `ISR_asalariados = ISR × ing_subor/(ing_bruto_tax − cuotasTPF)` tiene mediana 1.150 y extremos ±miles (la parte «salarial» del ISR excede al ISR total en el 75 % de la base).
6. **Informalidad, con la base v8.15.3:** el corte deja **32.8 M formales** (no 42.5 M: `pensiones_en_yl = off` sacó a los jubilados de la base, que pasa de 54.2 a 49.3 M), umbral p ≥ 0.2285, λ = 1.1666, obligación estatutaria 1,424.327. Anclado a cotizantes IMSS+ISSSTE (25.5 M) la informalidad vale 294.590 y la «evasión» sale **negativa** (−124.048): la obligación del motor de los 25.5 M más probables no alcanza la recaudación. El requisito de entrada de 8.16 (anclar la obligación a declaraciones por rango) **sí tiene fuente oficial**: los Informes Trimestrales de la SHCP (ITAN, anexo `itanfp02`, hoja «I.II RecGobFed a) ISR») publican desde 2019-1T la recaudación del ISR por rango de ingreso anual declarado × tipo de contribuyente, acumulada al trimestre; el 4T 2024 está en la Tabla 1b (fila nueva) y la decisión 9 se reescribe (8.16a corrige la afirmación «no publicado» de la primera versión).

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
| 4 | Separa gasto individual y del hogar; el del hogar se divide entre integrantes y se reparte por perfil edad-sexo (`perfilpc`); suma el individual | `perfilpc` conserva exactamente el total del hogar (verificado); la caché canónica trae `M<k>` = 1.085868 × (hog + ind) en las 19 porque `Simulador.ado` deflactó la variable en la corrida con gráficas del 16-oct (FLAG 20, §8 bis) | `E l.518–876`; `Simulador.ado l.109` |
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
| `obligacion_isrpf_ancla` | `itan_rangos` (propuesta 8.16a) | `enigh` | «obligación de ISR PF anclada por rango de ingreso declarado (ITAN 4T)» | **Decisión 9 reescrita en 8.16a.** La primera versión decía «no publicado por SAT/SHCP para 2024»: es incorrecto. Los *Informes sobre la Situación Económica, las Finanzas Públicas y la Deuda Pública* (SHCP) publican cada trimestre, en el anexo de finanzas públicas `itanfp02_<AAAA><TT>.xlsx`, hoja «I.II RecGobFed a) ISR», la recaudación del ISR (mdp, acumulado enero–trimestre) por **rango de ingreso anual declarado por el contribuyente** (12 rangos, miles de pesos) × **tipo** (personas morales; PF con actividad empresarial; PF sin actividad empresarial; retenciones por sueldos y salarios de PM y de PF; otros auxiliares), más sector de actividad y número de contribuyentes que presentaron declaración con pago; el 4T es la cifra anual (Tabla 1b, fila nueva; asset `raw/ITAN/itan-congelado.zip`, catálogo `05_scripts/itan-catalogo.json`, `AccesoITAN.ado` → `master/itan-isr-rangos.dta`, 2019-1 … 2026-3). **Nota metodológica:** (i) el rango es de *ingreso anual declarado* (nota 1_/ del cuadro; RIF por declaraciones bimestrales), no de base gravable ni de ISR causado: el mapeo a la ENIGH exige asumir que el ingreso declarado corresponde al `ing_bruto_tax` anual de la persona (ingresos acumulables antes de deducciones) y que la distribución *dentro* de cada rango es la de la ENIGH; (ii) en las columnas de **retenciones por sueldos y salarios** el «contribuyente» es el retenedor (el patrón: 584.5 de los 1,254.8 bn caen en «más de 500 millones»), así que esos rangos ordenan a las empresas, **no** a los asalariados: solo las columnas de PF con y sin actividad empresarial (77.117 bn en 2024) anclan la obligación de PF por rango; la de asalariados sigue anclándose por total (`ISRAS` LIF = ITAN retenciones por salarios 1,254.807 al peso); (iii) son acumulados anuales y cifras preliminares del SAT (la SHCP revisó 2021 y 2022-3T: Tabla 1b); (iv) «Resto» = contribuyentes sin declaración anual (412.9 bn de retenciones) y los rangos bajos de PF sin actividad empresarial salen negativos (devoluciones): el ancla por rango se construye sobre los 11 rangos con PF ≥ 0 y «Resto» se reparte ∝ ENIGH, declarado. Con `enigh` la obligación por rango no se ancla (hoy). |
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

### §4.0 — La firma (Ricardo, 2026-11-07; `CUAD-1-2-firma.md`, implementada en 8.16b)

Donde la firma difiere de este memo, manda la firma. Los parámetros viven en `SIM.do` §0.8b con el valor firmado como default; cualquier otro valor imprime FLAG en el header del módulo y en `nta-identidad.txt`. La fila «qué mueve en lo publicado» es la que explica cada llave de `output.txt`, sankey o entidad que cambia respecto a v8.15.3 (`gate-numeros` ROJO esperado; `baseline = v8.16.0`).

**Correcciones de código (§8 bis; sin parámetro):**

| Ficha | Decisión | Qué mueve en lo publicado |
|---|---|---|
| 1 (FLAG 20) | `Simulador.ado` guarda la copia del dataset **antes** de deflactar y la restaura al salir; `master/2024/consumption_*_pc.dta` se regeneran sin gráficas (`gas_pc_*` idéntico a 1e-15 a la caché regenerada; `TT<k>` sin el 1.085868; `ETotPIB` correcto) | nada; solo el log |
| 2 | `iepsnp_macro = divsim` (224.780) y `DifIEPSNP` honesto: FLAG «IEPS micro incompleto: gasolinas fuera de `Expenditure.do`» (cobertura `IEPSNPCobertura`) | nada; solo el log |
| 4 | `ieps_relativo = micro` en `PerfilesSim.do` **y** `NTA.do`: IEPSP ∝ `gas_pc_Gasolinas + gas_pc_Combustibles` (`base_iepsp`, de `consumption_categ_ieps_pc.dta`), IEPSNP ∝ `IEPS` micro por categoría | `INCD*` de IEPSNP, IEPSP, Consumo, ImpuestosAportaciones, AportacionesNetas; `APORT*`, `PROY*`; SankeySF; τ⁻ indirecto por edad en NTA |
| 5 | Regalos: cuenta **G5** (quien recibe); `tipo_gasto == "G2"` fuera en `Expenditure.do` §2.9b (90.530 bn crudos) | `gas_pc_*` por persona: SankeyNTA, base micro del IVA/IEPS (`INCD` IVA de 2.º orden) |
| 6 | R004 (predial 30.328) y R012 (tenencia 23.116) fuera del consumo → D.59 (`OTROSK`); G009–G016 y R003 → categoría 9 (BIE 724614) | ídem ficha 5 |
| FLAG 33 | `gastotarjetas` (TB01–TB16, sin `tipo_gasto`) fuera del consumo: flujo financiero; el monto se declara (`ExpTarjetas`) | ídem ficha 5 |

**Parámetros firmados (`SIM.do` §0.8b):**

| # | Parámetro | Valor | Nota |
|---|---|---|---|
| 1 | `consumo_ancla` | **`p3_s14`** | 19 relativos BIE + un factor `TTp3 = (P.3 S.14 − compras netas) / ConHog`; P.3 S.15 y vintage como filas de sector; gate Σ Cpriv = P.3 S.14 |
| 2 | `consumo_precios` | **`comprador`** | único implementado; `basicos` es de 8.17 |
| 3 | `cuotas_por_sector` | **`on`** | Tabla 1b: D.61 por pagador y receptor; `cuotasF` (cuota social y aportaciones federales) fuera de `cuotasTPF` |
| 4 | `isrpm_incidencia` | **`propiedad`** | ISR PM ∝ `ing_d4_rel`; negocios propios a la base de PF; denominador de `ISRPMTE` = B.2n S.11 + S.12 (excedente neto de operación de las sociedades; corrección de Ricardo 2026-11-08: con B.5n la tasa pasaba de 100 %) |
| 5 | `isr_personas_ancla` | **`d51_s14`** | NTA: ISR asalariados + PF → D.51 S.14 (1,518.912), ISR PM → D.51 S.11 + S.12 (1,165.676); fila «LIF vs CSI por sector» |
| 6 | `isras_share` | **`acotado`** | parte salarial del ISR en [0, 1] |
| 7 | `obligacion_isrpf_ancla` | **`itan_rangos`** | PF por los 11 rangos ≥ 0 del ITAN 4T 2024; «Resto» y rangos negativos ∝ ENIGH; asalariados por total; retiro de `ISRInformesTrimestrales.xlsx` desde 2019-1 (§8 ter), 2013–2018 con sello amarillo |
| 8 | `informalidad` | **`corte`** | el corte se aplica (hasta v8.15.3 no tocaba `ISR_asalariados`) |
| 9 | `ancla_formales` | **`imss`** | N = 25,500,447; el residuo Σ obligación(formales) − LIF es «ajuste por subreporte de ingresos altos» con sello rojo, **no** evasión |
| 10 | `iepsnp_macro` | **`divsim`** | 224.780 |
| 11 | `ieps_relativo` | **`micro`** | ficha 4 |

Gates nuevos (1e-9) en el log: Σ Cpriv = P.3 S.14; Σ cuotas = D.61 por sector receptor; Σ ISR personas = D.51 S.14; Σ ISR PM = D.51 S.11 + S.12; Σ IEPS repartido = LIF por tipo (§7). Lo que la firma declara y 8.16b no cierra (fila τ⁺ vs D.62 + D.7 netas, FLAG 27, FLAG 33, IEPS micro incompleto) está en `CUAD-1-2-firma.md` §E y en §8.

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

**Tabla 4c-c — Los cuatro componentes con la base de 8.17.2 (CUAD-3: `rentas_celda = b2n`, `ing_mixto_ancla = b3n_d422`, `altimir_elasticidad = ε\*`; bn 2024; corrida completa de la sesión cuad-3).** La brecha ENIGH–SCN de D.1 y B.3n se reparte ∝ Y^ε, así que la obligación de los de mayor *p* (los formales del corte `imss`) sube y el residuo Σ obligación(formales) − LIF cambia de tamaño: CUAD-3 §4 lo reescribe como **evasión identificable** si sale ≥ 0 (FLAG 27 cerrado) y como subreporte residual, sello rojo, si sigue < 0.

| Componente | v8.17.1 (ε = 1, `L`) | 8.17.2 (ε\* = 1.45) | Fuente |
|---|---:|---:|---|
| (a) Obligación estatutaria de asalariados, toda la base (share acotado) | 1,282.675 | 1,300.546 | cuadro «Validación del ajuste por subreporte», `Households` §11.1 |
| Formales (`ancla_formales = imss`) | 25,499,904 | 25,499,904 | ídem |
| INFORMALIDAD (extensivo) = Σ obligación de los que quedan abajo del corte | 266.091 | 259.085 | (a) − Σ obligación formales |
| Σ obligación de los formales | 1,016.584 | 1,041.461 | ídem |
| (c) Recaudado: LIF ISR retenciones por salarios | 1,253.785 | 1,253.785 | LIF 2024 |
| Residuo Σ obligación(formales) − LIF | −237.200 (−18.92 %) | −212.324 (−16.93 %) | FLAG 27 |
| Lectura del residuo | ajuste por subreporte de ingresos altos (sello rojo) | subreporte residual con ε\* (sello rojo); sería «evasión identificable» solo si saliera ≥ 0 | CUAD-3 §4, §8 |

Lectura mecánica, sin interpretar: (i) con `imss`/`enoe` el corte deja a 25.5/23.5 M y su obligación (1,129.7/1,084.6) no alcanza la LIF: el motor subestima la obligación de los más probables (CUAD-0 §4.0 C: «la obligación estatutaria sobre ingreso con Altimir uniforme sale baja»), y el residual sale negativo; (ii) con `sat` la base entera cabe en el padrón y toda la brecha es intensiva; (iii) ningún ancla cierra las cuatro cuentas con el ISR por rango, porque la fila (0)–(0a) depende de un share no acotado y de un gasto fiscal del motor que no se mide contra el `DRR` por concepto (aguinaldo, prima vacacional, PTU, horas extra, previsión social, cajas de ahorro están en `exen_t4_cap1`: Σ 450.064 en la base; `exen_tot` Σ 1,406.243). Lo que falta para cerrar: `isras_share = acotado`, el gasto fiscal por concepto del `DRR` como contraste del motor, y el SAT por rango **(no publicado para 2024)**.

Comparables de la base v8.15.3 (`D`): `cuotasTPF > 0` 43,074,483; `formal2 ∈ {1,3,4,6}` (IMSS) 26,390,703; `formal2 ∈ {2,5}` (ISSSTE) 4,820,969; `ing_t4_cap1 > 0` 51,028,544.

---

## §5 Anclas

### Tabla 1 — Consumo → SCN (una fila por rubro de `Expenditure.do`)

Σ ENIGH = Σ gasto_anual·factor en `preconsumption.dta` por `categ` (todos los `tipo_gasto` **y** las filas de `gastotarjetas`, que en la caché del 16-oct traen el factor vacío y el motor recupera de `concentrado` en §3.3: 293.933 bn; corregido en 8.16a, antes 9,860.460); Σ motor = `M<k>` (post-`perfilpc`, pre-ancla) = 1.085868 × Σ ENIGH (FLAG 20, deflactor de `Simulador.ado`, §8 bis); factor actual = `TT<k>` = celda / Σ motor (`E l.1042`); las 19 celdas suman `ConHog` 24,192.112 al peso. Celda P.3 S.14 por finalidad: **(no en repo; INEGI no la publica en la CSI; el BIE 724601–724656 es «hogares e ISFLSH» en territorio)**. Regla: **I** = incidencia (quien consume). Sello amarillo = celda BIE identificada pero con ISFLSH y no residentes dentro; rojo = además una mezcla de contenido.

| Rubro (`categ`) | Claves ENIGH 2018 (`E l.315–365`) | Celda (BIE) | Valor | Σ ENIGH | Σ motor | Factor actual | Factor propuesto | Sello | Marca |
|---|---|---|---:|---:|---:|---:|---|---|---|
| 1 `Alim` | A001–A214, T901 | 724602 Alimentos | 5,524.006 | 2,232.183 | 2,423.856 | 2.2790 | mismo relativo; total a P.3 S.14 (`consumo_ancla`) | amarillo | T901 son regalos a otros hogares (53.208): G2 + G5 cuentan dos veces |
| 2 `BebN` | A215–A222 | 724603 Bebidas no alcohólicas | 620.675 | 169.647 | 184.215 | 3.3693 | ídem | amarillo | |
| 3 `BebA` | A223–A238 | 724605 Bebidas alcohólicas | 361.568 | 27.361 | 29.710 | **12.1697** | ídem; base del IEPS | **rojo** | subreporte ×12: la base del IEPS alcohol se infla con el ancla |
| 4 `Taba` | A239–A241 | 724606 Tabaco | 136.062 | 12.914 | 14.023 | **9.7030** | ídem | **rojo** | ídem (IEPS tabaco) |
| 5 `Vest` | H001–H083, T909 | 724608 Prendas de vestir | 328.684 | 198.367 | 215.401 | 1.5259 | ídem | amarillo | |
| 6 `Calz` | H084–H122 | 724609 Calzado | 123.494 | 121.302 | 131.717 | 0.9376 | ídem | amarillo | |
| 7 `Alqu` | G001–G004, G102–G106, R003–R004 | 724611 Alquiler efectivo + 724612 Conservación (`SCN.ado` l. 867) | 2,954.186 | 1,732.962 | 1,881.768 | 1.5699 | separar: alquiler imputado G102–G106 (1,408.154 ENIGH) = consumo de B.2n (CUAD-0, `ing_estim_alqu`); R004 predial (30.328) → D.59; R003 gas natural (16.576) → 724614 | **rojo** | 724611 no separa efectivo de imputado (CUAD-0 FLAG 18); el alquiler imputado consta dos veces en el motor: aquí como consumo y en `Households` como ingreso B.2n (consistente con el SCN: P.3 = B.2n del alquiler imputado) |
| 8 `Agua` | R002 | 724613 Agua | 64.995 | 76.033 | 82.562 | 0.7872 | ídem | amarillo | G005 recolección de desperdicios (6.381) cae en `HogaT` (COICOP 04.4, aquí) |
| 9 `Elec` | R001 | 724614 Electricidad, gas y otros combustibles | 744.701 | 139.677 | 151.670 | **4.9100** | mover G009 gas LP (111.599), G012–G014, G016 combustibles (8.679) y R003 gas natural (16.576) desde `HogaT`/`Alqu` | **rojo** | la ENIGH sí tiene gas (G009 111.599 bn) y el motor lo manda a «Artículos para el hogar»: el factor 4.9 es clasificación, no subreporte |
| 10 `HogaT` | G005–G016, K*, R013, T907, T912 | 724615 Artículos para el hogar | 1,366.870 | 328.119 | 356.294 | 3.8364 | sacar G005–G016 (combustibles y servicios de la vivienda: COICOP 04) | **rojo** | ver filas 8 y 9 |
| 11 `SaluT` | J*, T911 | 724622 Salud | 739.771 | 417.884 | 453.767 | 1.6303 | ídem | amarillo | G6 (transferencias de instituciones) 96.384 en salud: es D.63, no P.3 privado |
| 12 `Vehi` | M007–M009 | 724627 Adquisición de vehículos | 832.724 | 234.209 | 254.320 | 3.2743 | ídem; base del ISAN | amarillo | |
| 13 `FTra` | F007+, R012 | 724628 Funcionamiento de transporte | 2,715.704 | 534.772 | 580.692 | **4.6767** | R012 tenencia (23.116) → D.59; base del IEPS petrolero (`TM l.136`) | **rojo** | gasolinas: el subreporte ×4.7 infla la base del IEPS P; tenencia es impuesto |
| 14 `STra` | B*, M001–M006, T902, T914 | 724629 Servicios de transporte | 1,504.971 | 397.158 | 431.261 | 3.4897 | ídem | amarillo | G4 remuneración en especie 44.476 y G5 regalos 13.632 |
| 15 `ComuT` | F001–F006, R005–R011, T906 | 724630 Comunicaciones | 525.720 | 377.186 | 409.574 | 1.2836 | ídem; base del IEPS telecom | amarillo | |
| 16 `RecrT` | E008+, L001–L026, T905, T913 | 724634 Recreación y cultura | 1,185.699 | 431.724 | 468.796 | 2.5292 | ídem; juegos (IEPS) viven dentro (`TM l.28–31`) | amarillo | |
| 17 `EducT` | E001–E007 | 724641 Educación | 322.257 | 300.089 | 325.857 | 0.9890 | ídem | amarillo | G6 33.706 (becas/colegiaturas pagadas por instituciones): D.63 |
| 18 `RestT` | A242–A247, N003–N005 | 724647 Restaurantes y hoteles | 1,371.191 | 1,093.169 | 1,187.037 | 1.1551 | ídem | amarillo | G4 remuneración en especie 107.113 y G5 regalos 302.666 (comidas recibidas) |
| 19 `DiveT` | C*, D*, H123+, I*, L027+, M010–M018, N001–N002, N006+, T903–T904, T908, T910, T915, resto | 724650 Bienes y servicios diversos | 2,768.834 | 1,329.637 | 1,443.811 | 1.9177 | ídem | amarillo | residual (`categ = 19 if categ == .`) |
| **Σ 19** | | `ConHog` 724600 | **24,192.112** | **10,154.393** | **11,026.332** | **2.1940** (`TTConHog`) | **P.3 S.14 23,381.329** → factor único 0.96649 sobre los 19 | | |
| Compras netas de no residentes | — | 724777 `ComprasN` | −372.715 | — | ∝ `gastoanualTOT` (`H l.2845`) | 1 | sin cambio (S.2, Tabla 2) | amarillo | Cpriv = 24,192.112 − 372.715 = 23,819.398 (`N l.456`) |
| **Fila −438.069: Cpriv motor vs P.3 S.14** | | | 23,819.398 vs 23,381.329 | | | | | | **Descomposición:** P.3 S.15 (ISFLSH) **388.320** (CSI_118 f.166) + vintage BIE−CSI del consumo de residentes **49.749** (23,819.398 − 23,381.329 − 388.320) = 438.069. **Por rubro: (no en repo)**: la CSI no publica P.3 por finalidad ni para S.14 ni para S.15; la única apertura por finalidad (BIE 7246xx) ya es hogares + ISFLSH |

**Por `tipo_gasto` (ENIGH 2024, Σ gasto_anual·factor, bn; `D`):** G1 monetario para el hogar 7,358.337 · G2 monetario para otro hogar 90.530 · G3 autoconsumo 73.235 · G4 remuneraciones en especie 217.340 · G5 regalos recibidos de otro hogar 548.144 · G6 transferencias de instituciones 164.719 · G7 estimación del alquiler 1,408.154 · **sin `tipo_gasto`: `gastotarjetas` (TB01–TB16 → T9xx) 293.933** (8.16a; FLAG 33) · total 10,154.393. Lo que el SCN cuenta como P.3 de hogares: G1 + G3 + G4 + G7 y **una sola vez** los regalos entre hogares (G2 o G5, no ambos); G6 es D.63 (Tabla 2). Las cifras por categoría × tipo están en `D/tabla1.out`.

**El ×1.085868 entre Σ ENIGH y Σ motor (Resumen 2; FLAG 20, resuelto en 8.16a).** Σ (gas_hog + gas_ind)·factor en `consumption_categ_pc.dta` = 10,154.393 = Σ ENIGH al peso en las 19 categorías (la diferencia con 9,860.460 de la primera versión son las filas de `gastotarjetas` sin factor en `preconsumption.dta`, no un ×1.40 del gasto individual: `gas_ind` coincide al peso con la ENIGH en las 19). Σ gas_pc = 11,026.332 = **1.085868 × (hog + ind) exactamente** en las 19 (residuo ≤ 0.0003 bn); por hogar el cociente Σ_i gas_pc / (gas_hog × tot_integ) solo supera 1.085868 donde hay gasto individual. La constante es `1/deflactor_2024` con base en el año de la corrida (2026): `Simulador.ado` l. 109 divide la variable graficada entre el deflactor sobre el dataset y `Expenditure.do` la invoca sobre `ogas_pc` y `gas_pc` cuando hay gráficas; §8 bis, ficha 1.

### Tabla 1b — Impuestos y cuotas → quién paga (una fila por impuesto de `TasasEfectivas`)

Base gravable del motor = la variable micro que define la incidencia; celda SCN = dónde lo registra la CSI y en qué sector; recaudado = LIF 2024 (`recaudacion`, `divSIM`); Σ motor = lo que el módulo reparte (igual a la LIF por construcción salvo nota). Regla: **I** = incidencia · **P** = propiedad · **C** = per cápita. Sello amarillo = total con celda SCN identificada y sector pagador distinto del que el motor asume; rojo = sin celda o base equivocada.

| Impuesto / cuota | Base gravable del motor (incidencia hoy) | Celda SCN (sector pagador → receptor) | Valor SCN | LIF 2024 | Σ motor | Factor actual | Propuesto | Regla | Sello | Fuente |
|---|---|---|---:|---:|---:|---:|---|---|---|---|
| ISR asalariados (`ISRAS`) | `ISR_asalariados` = tarifa(`ing_bruto_tax − exen_tot − deduc_isr − cuotas netas`) × `ing_subor/(ing_bruto_tax − cuotasTPF)`; cut-off por ranking de `prob_salarios` | D.51 S.14 → S.13 (dentro de 1,518.912; la CSI no separa asalariados de PF) | D.5 S.14 1,540.050 (D.51 1,518.912 + D.59 21.138) | 1,253.785 | 1,253.780 (cut-off) | 1 (LIF) | ancla del **total** S.14: ISRAS + ISRPF = 1,330.838 → D.51 S.14 1,518.912 (factor 1.1413) o D.5 1,540.050 (1.1572); `isras_share = acotado`; `informalidad`/`ancla_formales` de §4 | I | amarillo | `H l.2433–2439`; CSI_115 f.114–116; `LIF`; `L` l. 246 |
| ISR personas físicas (`ISRPF`) | `ISR_PF = ISR − ISR_asalariados` si > 0; cut-off por `prob_formal` (informalidad 76.07 %) | D.51 S.14 (misma celda) | ídem | 77.053 | 77.053 | 1 | ídem (una sola celda para ISRAS + ISRPF); con `isrpm_incidencia = propiedad`, `ing_bruto_tpm` entra aquí como actividad empresarial | I | amarillo | `H l.2455–2462`; `L` l. 247 |
| **ISR por rango de ingreso (ITAN 4T 2024; fila nueva 8.16a)** | rango de ingreso anual declarado por el contribuyente (12 rangos) × tipo; `AccesoITAN.ado` → `master/itan-isr-rangos.dta` | D.51 S.14 (PF y retenciones) y D.51 S.11 + S.12 (PM); la CSI no publica por rango | 2,684.588 (D.51 S.1) | 2,684.495 (ITAN total = LIF ISR 2,682.265 + 2.230 de retenciones al extranjero no clasificadas) | — (no se usa aún) | — | `obligacion_isrpf_ancla = itan_rangos`: PF con/sin actividad empresarial por rango (77.117); asalariados por total (1,254.807 = `ISRAS` LIF 1,253.785 + 1.022) | I | amarillo (preliminar SAT; rangos de ingreso declarado; retenciones ordenadas por el retenedor) | ITAN `itanfp02_202404.xlsx` hoja «I.II RecGobFed a) ISR» O18:V30 (asset `itan-congelado.zip`, sha256 `7c22bf10…`; archivo `c3867bef…`) |
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

**ISR por rango de ingreso y tipo de contribuyente, enero–diciembre de 2024 (ITAN 4T 2024, mdp, cifras preliminares del SAT; `master/itan-isr-rangos.dta`, `anio == 2024 & trimestre == 4`):**

| Rango (miles de pesos de ingreso anual declarado) 1_/ | Total | Personas morales | PF con actividad empresarial | PF sin actividad empresarial | Retenciones sueldos y salarios (PM + PF) 2_/ | Otros auxiliares |
|---|---:|---:|---:|---:|---:|---:|
| Total | 2,684,494.7 | 1,346,341.7 | 35,054.7 | 42,061.9 | 1,254,807.4 | 6,229.0 |
| 0 ≤ 250 | 66,225.6 | 21,702.9 | 6,494.0 | 1,544.2 | 36,484.4 | 0.0 |
| 250 ≤ 500 | 1,870.5 | 1,773.5 | 2,302.8 | −3,884.0 | 1,678.1 | 0.0 |
| 500 ≤ 750 | 709.8 | 1,073.7 | 1,785.2 | −3,347.5 | 1,198.4 | 0.0 |
| 750 ≤ 1,000 | 1,952.8 | 757.4 | 1,386.6 | −1,316.3 | 1,125.0 | 0.0 |
| 1,000 ≤ 5,000 | 39,723.8 | 12,242.4 | 8,398.5 | 8,694.5 | 10,388.3 | 0.0 |
| 5,000 ≤ 10,000 | 30,534.8 | 10,602.0 | 3,209.0 | 7,025.8 | 9,698.0 | 0.0 |
| 10,000 ≤ 20,000 | 41,121.6 | 15,599.8 | 2,751.3 | 7,694.0 | 15,076.4 | 0.0 |
| 20,000 ≤ 50,000 | 72,774.4 | 32,690.7 | 2,475.2 | 6,765.4 | 30,843.1 | 0.0 |
| 50,000 ≤ 100,000 | 72,684.7 | 35,564.4 | 1,347.1 | 3,592.5 | 32,180.7 | 0.0 |
| 100,000 ≤ 500,000 | 259,969.4 | 133,440.3 | 1,846.2 | 5,987.5 | 118,695.4 | 0.0 |
| Más de 500 mil | 1,642,404.2 | 1,049,763.4 | 591.6 | 7,528.9 | 584,520.3 | 0.0 |
| Resto 3_/ | 454,523.3 | 31,130.9 | 2,467.3 | 1,776.7 | 412,919.4 | 6,229.0 |

1_/ Rangos por los ingresos anuales declarados por el contribuyente (RIF: declaraciones bimestrales). 2_/ El contribuyente es el retenedor: el rango ordena a patrones, no a asalariados. 3_/ Contribuyentes que no presentaron declaración anual. Contribuyentes con declaración con pago: 5,642,745 (PM 745,039; PF 3,870,989; otras PF y PM 1,026,717). **Validación contra `ISRInformesTrimestrales.xlsx`** (`AccesoITAN, validar`; 29 trimestres comunes 2019-1 … 2026-1, acumulados): 25 trimestres coinciden a 0.1 mdp (sueldos y salarios, PF y PM + auxiliares); los cuatro de **2021** difieren en todos los tipos (ITAN − captura: SyS +3,629.5, +4,910.2, +6,894.3, +6,700.2; PF +7,003.0, −8,507.4, −7,921.5, −6,446.9; PM + aux +22,855.8, −16,194.5, −31,393.5, −13,370.6) y **2022-3T** en PM + aux (+48,549.2; SyS y PF iguales): la captura manual tomó otro vintage o se equivocó de columna; el ITAN publicado manda y en 8.16b sustituye a la captura desde 2019-1 (§8 ter). Para 2012–2018 la tabla por rango no existe en los `.xlsx` de la SHCP (el `itanfp02` de 2013–2015 es otro anexo y 2016–2018 no la traen en ningún anexo `.xlsx` del IV trimestre): la captura sigue siendo la única fuente para esos años.

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
| **Σ S sin ancla vs B.8n S.14** | **2,116.145 vs 1,901.026: +215.119 (+11.3 %)** | **Tras 8.16 (medido en 8.16b): 2,366.139 vs 1,901.026 = +465.1 (+24.5 %)** = τ⁺/inter/remesas vs D.62 + D.7 netas +461.0 (8.17) + D.59 +21.1 − ImpProd 17.0, con D.5 (→ D.51 S.14) y Cpriv (→ P.3 S.14) en 0. **Tras 8.17 (medido en la sesión 8.17, v8.17.0): 1,881.607 vs 1,901.026 = −19.419 (−1.0 %)** = ImpProd − τ⁻ indirectos LIF −17.0 + vintage de remesas D.752 CSI vs ROWTrans BIE −2.4; la fila τ cerrada por sector (CUAD-2 §4.0 bis) y D.59 en τ⁻ | `brecha_max` volvió a 15 % en 8.17 y `nta_anclaS = auto` queda en multiplicativo con factor 1.0103 (el nodo de ajuste del v4 es un sink de 19.4 bn, declarado) | `NTA.do` §4.11 |
| IEPS micro vs macro | 28.3 vs 24.075 (`DifIEPSNP` 15.0 %) | 28.3 vs 224.780 declarado; gasolinas con micro | — | `Expenditure.do` §6.3 |
| Parte salarial del ISR ∈ [0, 1] | mediana 1.150; extremos ±miles | acotada | — | gate nuevo en `Households.do` §11.1 |

## §8 Límites conocidos

| # | FLAG | Magnitud (bn) | Cierre propuesto |
|---|---|---:|---|
| 20 | Σ motor del consumo = 1.085868 × Σ (hog + ind) en las 19 categorías: `Simulador.ado` deflactó `gas_pc_*` en la caché (**identificado en 8.16a**, §8 bis ficha 1; el «×1.40 del gasto individual» era un error de la Tabla 1) | +871.939 (8.5868 %) en el log; **0.000** en lo publicado | 8.16b: `Simulador.ado` sobre copia temporal + regenerar `consumption_*_pc.dta`; gate Σ motor = Σ ENIGH |
| 21 | Consumo anclado a hogares + ISFLSH en territorio (`ConHog`) y no a P.3 S.14 | −438.069 | 8.16: `consumo_ancla = p3_s14` |
| 22 | Regalos entre hogares contados dos veces (G2 + G5) | 90.530 | 8.16: decidir cuál cuenta |
| 23 | Transferencias en especie de instituciones (G6) dentro del consumo privado | 164.719 | 8.17: es D.63 (Tabla 2) |
| 24 | Predial y tenencia (R004, R012) dentro del consumo | 53.444 | 8.16: → D.59 (`OTROSK`) |
| 25 | Gas LP y combustibles (G009–G016) en «Artículos para el hogar», no en 724614 | 120.278 | 8.16: reclasificar |
| 26 | IEPS no petrolero comparado contra 24.075 en vez de 224.780; IEPS petrolero sin micro; NTA reparte IEPS ∝ vehículos / ∝ alcohol | 628.364 | 8.16: `iepsnp_macro`, `ieps_relativo` |
| 27 | Parte salarial del ISR no acotada (`H l.2433`); desde 8.16b, residuo Σ obligación(formales) − LIF < 0 con `ancla_formales = imss` | Σ obligación 1,424.327 dependía de ella; residuo −237.200 (−18.92 %) en v8.17.1 | 8.16: `isras_share = acotado`. **8.17.2 (CUAD-3):** con la brecha ∝ Y^ε (ε\* = 1.45) el residuo es −212.324 (−16.93 %): sigue < 0 → subreporte residual, sello rojo (no hay evasión identificable) |
| 19 | ISR PM sobre negocios propios (CUAD-0) | 1,351.427 | 8.16: `isrpm_incidencia = propiedad` |
| 13 | Cuotas todas a Gobierno (CUAD-0) | 1,045.130 | 8.16: `cuotas_por_sector = on` (destinos); 8.17: nodos |
| 28 | Cuota social federal (`cuotasF`) sumada como cuota de personas | 0.569 % PIB ≈ 191.6 | 8.16: fuera de `cuotasTPF`; es gasto S.13 |
| 29 | Factores de empalme cableados en `ISR_Mod.do` (3.793/3.255, …) | ISR web vs batch | 8.16: leerlos de la corrida (`char`), como `TaltimirSal` |
| 30 | Ancla por rango para la obligación de ISR PF | 77.117 (PF 2024) | **publicado**: ITAN 4T (SHCP) desde 2019-1T; asset `itan-congelado.zip` + `AccesoITAN.ado` (8.16a); 8.16b: `obligacion_isrpf_ancla = itan_rangos` (decisión 9) |
| 33 | `gastotarjetas` (TB01–TB16 → T9xx, sin `tipo_gasto`) dentro de la base del consumo; en `preconsumption.dta` del 16-oct esas filas traen el factor vacío y el motor lo recupera en §3.3 | 293.933 crudo (2.9 % de la base) | 8.16: decidir si el gasto con tarjeta es consumo del trimestre (INEGI lo publica aparte de `gastohogar`) o pago de deuda |
| 34 | El reparto del IEPS ∝ `gas_pc_Vehi` / `gas_pc_BebA` también vive en `PerfilesSim.do` l. 288 y 294 (no solo en `NTA.do`): es lo que llega a `INCD*` | IEPSP 81.6 y IEPSNP 41.7 bn cambian de decil | 8.16: `ieps_relativo = micro` en los dos módulos |
| 31 | Tablas de cuotas IMSS/ISSSTE 2021 con UMA 2024 | — | 8.16: vintage declarado |
| 32 | Anclas de informalidad externas no cierran la LIF (`imss`/`enoe` dan evasión negativa) | −124.048 / −169.150 | 8.16: primero FLAG 27 y gasto fiscal por concepto; después decidir ancla |
| 35 | IEPS micro incompleto: gasolinas fuera de `Expenditure.do` §6 (`Gasolinas` y `Sin_IEPS` se saltan); el micro cubre una fracción del IEPSNP macro (`IEPSNPCobertura`) | 224.780 vs micro ≈ 28 | declarado en 8.16b (FLAG en el log); el ancla LIF manda y el reparto va ∝ micro |

**Estado en 8.16b (v8.16.0; firma `CUAD-1-2-firma.md`).** Cerrados: 20 (`Simulador.ado` restaura la variable; cachés regeneradas), 21 (`consumo_ancla = p3_s14`), 22 (G5 cuenta; G2 fuera), 24 (R004/R012 fuera → D.59), 25 (G009–G016 y R003 → 724614), 26 y 34 (`iepsnp_macro = divsim`, `ieps_relativo = micro` en los dos módulos), 19 (`isrpm_incidencia = propiedad`), 13 en su parte de 8.16 (`cuotas_por_sector = on`: destinos por sector receptor; los nodos son de 8.17), 28 (`cuotasF` fuera de `cuotasTPF`), 30 (`obligacion_isrpf_ancla = itan_rangos`), 33 (`gastotarjetas` fuera; el monto se declara). Declarados con sello: 27 (`isras_share = acotado`; con `ancla_formales = imss` el residuo Σ obligación(formales) − LIF se imprime como **ajuste por subreporte de ingresos altos**, sello rojo: la ENIGH no ve los ingresos altos; **8.17.2, CUAD-3:** la brecha de D.1 y B.3n se reparte ∝ Y^ε y el residuo pasa a −212.324 bn, sigue < 0 → subreporte residual, sello rojo (no hay evasión identificable)), 31 (tablas de cuotas 2021 con UMA 2024), 32 (el ancla `imss` elegida; el residuo no es evasión), 35 (IEPS micro incompleto). Abiertos: 23 (G6 es D.63: 8.17), 29 (factores de empalme de `ISR_Mod.do`), la fila τ⁺ vs D.62 + D.7 netas (+461.0 bn; CUAD-2, 8.17) y, con ella, la brecha de Σ S sin ancla (ver §7).

### §8 bis — Diagnóstico de los hallazgos (sesión 8.16a, 2026-11-07)

Una ficha por hallazgo del reporte de CUAD-1: dónde (archivo y líneas en `9b1c758`), mecanismo (economía, no Stata), desde cuándo (`git log -S` / `git blame`; «anterior al repo» = ya estaba en la primera carga de 2018-10-29), cuánto pesa (bn 2024 y llaves de `output.txt`), corrección propuesta y su tipo. Nada se corrige aquí; las cifras salen de los `.dta` de `-datos` (pandas, `probes/`) y de tres corridas en worktrees desechables (`diag-8.16a-2026-11-07/`): R0 (`PIBDeflactor`), R1 (`Expenditure.do` sin caché y sin gráficas) y R2 (`SIM.do` completo con `isras_share = acotado`).

**Ficha 1 — FLAG 20: consumo ×1.085868 uniforme.**
1. *Dónde.* `Simulador.ado` l. 109, dentro de la rutina de gráficas: `replace `varlist' = `varlist'/`deflator'` (sin `if`, sin `restore`), con `deflator` = `PIBDeflactor, anio(aniovp)` y `aniovp` = el **año calendario de la corrida** cuando no se pasa (l. 64–66). `Expenditure.do` l. 801 (`noisily Simulador o`vars'pc_`k' … aniope(`anioenigh') …`) y l. 830 (`gas_pc_`k'`), solo cuando `$nographs` está vacío. La caché `master/2024/consumption_*_pc.dta` se construye una vez (§3, guard `capture confirm file`) y nadie la regenera después.
2. *Mecanismo.* La rutina que dibuja los perfiles expresa la variable en pesos del año de valor presente dividiéndola entre el deflactor, y lo hace sobre la variable misma, no sobre una copia. El reparto intra-hogar (`perfilpc`) conserva exactamente el gasto del hogar (verificado: residuo ≤ 0.0003 bn en las 19 categorías), así que todo el salto es el deflactor: `1/deflactor_2024` con base 2026 = `1/0.920922131` = **1.085868139** (R0, con los globals `def2026 = 3.8` de `SIM.do`; con base 2027 sería 1.1293 y con 2025, 1.0461: la constante depende de la fecha en que se corrió). Por eso `ogas_pc_<k>` = 1.085868 × `gas_hog<k>` en el mismo registro (la copia «original» ya estaba deflactada) y Σ gas_pc = 1.085868 × (hog + ind) al peso.
3. *Desde cuándo.* El `replace` de `Simulador.ado` existe desde `cda5c1d` (2023-03-28, v5.5); la llamada de `Expenditure.do` sobre `ogas_pc` desde `0afac4e` (2025-09-02, ENIGH 2024; `perfilpc` la conservó en `4eba8a7`, 2026-10-03). La caché canónica de `-datos` es del 2026-10-16 02:45 (corrida con gráficas, antes de v8.10.0); las corridas posteriores (`nographs`) la reutilizan.
4. *Cuánto pesa.* **0.000 bn en lo publicado**: el factor es uniforme y `TT<k>` lo absorbe; R1 (caché regenerada sin gráficas) deja `gas_pc_*` anclado, IVA micro y los 19 Σ idénticos a 1e-15. En el log: Σ motor 11,026.332 → 10,154.393 (`ETotPIB` 32.751 → 30.161 % del PIB), `TT<k>` ×1.085868 (`TTConHog` 2.1940 → 2.3824, `TTBebA` 12.17 → 13.21), `DifIEPSNP` 15.0 → 14.8 % (las cantidades también se deflactaron: IEPS micro 28.308 → 28.268 bn, no llega a `output.txt`). Llaves: ninguna (`INGRESOS`, `GASTOS`, `INCD*`, `TE*` sin cambio).
5. *Corrección.* `Simulador.ado`: trabajar sobre `tempvar` (o restaurar la variable al salir) y `Expenditure.do` regenerar `consumption_*_pc.dta` (`global update` ya las borra). **Corrección de código sin efecto en números publicados**: no mueve `data_updated` ni `baseline`; entra en 8.16b junto con la caché nueva en `-datos`. Lateral: la primera versión de este memo subestimó Σ ENIGH en 293.933 bn porque `preconsumption.dta` trae el factor vacío en las 88,626 filas de `gastotarjetas` (19,464) y `erogaciones` (69,162); hoy `append` + `merge` en Stata las empareja todas (0 sin match: la caché de octubre tiene una causa no reproducible sin reconstruir `preconsumption.dta`, ~1 h) y el motor recupera el factor en §3.3, así que esas 293.933 bn **sí** están en la base (FLAG 33: decidir si el gasto con tarjeta es consumo).

**Ficha 2 — IEPS no petrolero comparado contra 24.075 en vez de 224.780.**
1. *Dónde.* `Expenditure.do` l. 120–124: `LIF, anio(`anioenigh') by(divCIEP)` y `local IEPSNP = r(IEPS__no_petrolero_)`; `TasasEfectivas.ado` l. 34–40 usa `LIF … by(divSIM)` y `IEPSNP`.
2. *Mecanismo.* La clasificación `divCIEP` de la LIF parte el IEPS en tres: petrolero (403.584), «no petrolero» (24.075: telecomunicaciones, juegos, plaguicidas…) y **«salud»** (200.705: bebidas alcohólicas, cerveza, tabaco, bebidas saborizadas, alimentos de alto contenido calórico); `divSIM` junta los dos últimos en `IEPSNP` = 224.780. El IEPS micro de `Expenditure.do` (alcohol, tabaco, bebidas, alimentos) es casi todo «salud», y el display lo compara contra el grupo que no lo contiene.
3. *Desde cuándo.* Anterior al repo: la línea está en la primera carga (`509d108`, 2018-10-29) y sobrevivió a v5.0 (`36f7a96`) y al refactor `b7a87e0`.
4. *Cuánto pesa.* **0 en `output.txt`**: solo alimenta `IEPSNPSCNPIB`/`DifIEPSNP` (log y `scalarlatex`); el ancla del `IEPSNP` repartido (224.780, `TasasEfectivas`) es correcta. En el log: «informalidad» del IEPS no petrolero 15.0 % (28.3 vs 24.075) → con el macro correcto el micro cubre **12.6 %** de 224.780 (−694 %): el IEPS micro está incompleto (gasolinas se saltan, l. 1297) y la comparación lo tapaba.
5. *Corrección.* `local IEPSNP = r(IEPS__no_petrolero_) + r(IEPS__salud_)` o `LIF … by(divSIM)` (parámetro `iepsnp_macro = divsim`). **Corrección de display**: no mueve números ni `baseline`; 8.16b.

**Ficha 3 — Factores salariales del ISR con mediana 1.150 y extremos ±miles.**
1. *Dónde.* `Households.do` l. 2433: `g ISR_asalariados = ISR*(ing_subor)/(ing_bruto_tax-cuotasTPF) if prob_salarios != .`.
2. *Mecanismo.* `ing_subor` es el salario **bruto** (con el gross-up de §6: ya incluye las cuotas del trabajador) y el denominador le resta `cuotasTPF` (trabajador 1.4 % + patrón 8.7 % + federación 0.2 % + Infonavit 2.5 % = 15.1 % del salario en la mediana de los asalariados puros): la «parte salarial» del ISR es 1/(1 − 0.151) = **1.170** para quien solo tiene salario (mediana 1.1501 en toda la base, p75 1.22) y se dispara (−1,395.8 / +7,252.1) cuando otras rentas negativas o las cuotas dejan el denominador cerca de cero. El ISR total se asigna al salario con un share > 1, así que Σ `ISR_asalariados` (1,424.327) excede la obligación.
3. *Desde cuándo.* `3322f9d` (2024-06-23, v6); reescrito sin cambio de fórmula en `fa13516` (v7, 2026-03-19).
4. *Cuánto pesa.* Corrida R2 (`SIM.do` completo con la línea 2433 acotada a [0, 1], worktree desechable, 47 min; `diag-8.16a-2026-11-07/r2-isras-acotado/`): Σ `ISR_asalariados` (obligación estatutaria) baja de 1,424.327 a **1,238.3 bn** (3.678 % del PIB; log de R2 l. 839), **por debajo de la LIF 1,253.785**: el cut-off ya no cierra, la informalidad estimada de los asalariados pasa de 30.51 % a **0.00 %** (los 49.3 M de la base pagan) y `TasasEfectivas` reescala a la LIF (−1.2 %). `gate-numeros` ROJO con **45 líneas** de `output.txt` distintas: `INCD`/`INCD2`/`INCD3` de ISRAS (bloque 12; decil I 17,579 → 19,509 MXN, decil X 255,040 → 260,137; participación del decil X 28.9 → 29.4 %, decil VI 9.6 → 9.2 %), ISRPF (13, ±1), Laboral (15), ImpuestosAportaciones (31) y AportacionesNetas (42); `APORTH*`/`APORTM*` (aportaciones por edad y sexo, hasta ±0.43 pp), `PROY` de los mismos cuatro bloques (±0.002 % PIB) y `PROYSHRFSP2/3` de segundo orden (−0.001 pp, −2 mdp); SankeySF decil 10/104 enlaces, grupoedad 4/59 (Δ rel. máx 11.8 %), sexo 2/40. `INGRESOS`, `INGRESOSTEF`, `GASTOS*`, `CUADRATURA`, `PIBY` y los 5 SankeyNTA no cambian. Lectura: el share > 1 no «crea» recaudación (la LIF manda) pero decide **quién** paga y cuántos pagan; acotarlo mueve la obligación por debajo de lo recaudado, lo que confirma CUAD-0 §4.0 C («la obligación estatutaria sobre ingreso con Altimir uniforme sale baja») y deja la informalidad de asalariados sin identificar hasta tener el ancla por rango (decisión 9) o `ancla_formales`.
5. *Corrección.* `isras_share = acotado` (clip a [0, 1], o `ing_subor/ing_bruto_tax` con cuotas netas en ambos lados). **Metodológica** (parámetro + FLAG 27, mueve `INCD*`, `baseline` → v8.16.0); 8.16b.

**Ficha 4 — IEPS petrolero ∝ compra de vehículos; IEPS no petrolero ∝ bebidas alcohólicas.**
1. *Dónde.* `PerfilesSim.do` l. 288 (`Distribucion IEPSNP, relativo(gas_pc_BebA)`) y l. 294 (`Distribucion IEPSP, relativo(gas_pc_Vehi)`): de ahí salen las variables `IEPSNP`/`IEPSP` de `perfiles2027.dta` que `TasasEfectivas.ado` l. 335 reparte (`IEPSNP_Sim`, `IEPSP_Sim`) y `INCI.ado` resume en `INCD*`. `NTA.do` l. 534–535 repite el proxy (`nta_IEPSNP`, `nta_IEPSP`).
2. *Mecanismo.* Se usa la compra de automóviles como proxy del consumo de gasolina y la compra de alcohol como proxy de todo el IEPS no petrolero (cerveza, tabaco, refrescos, alimentos calóricos, telecomunicaciones). La compra de vehículos está mucho más concentrada que el gasto en combustibles: el decil X compra 37.4 % de los vehículos y 19.2 % de las gasolinas y combustibles (`gas_pc_Gasolinas + gas_pc_Combustibles`, Σ 643.136 bn); las bebidas alcohólicas 26.1 % vs 12.4 % del IEPS micro de `Expenditure.do`.
3. *Desde cuándo.* `PerfilesSim.do`: `8c54592` (2024-02-12, v6); `NTA.do`: `d70ef3d` (2026-10-27, NTA-1).
4. *Cuánto pesa.* IEPSP 403.584 bn: **81.6 bn cambian de decil** al pasar de vehículos a gasolinas (decil X −73.3, deciles I–VII +81.5); IEPSNP 224.780: **41.7 bn** (decil X −30.6). Llaves: `INCD`, `INCD2`, `INCD3` (columnas IEPS, nacional y 32 entidades) y los perfiles por edad de τ⁻ en NTA; `INGRESOS`/`INGRESOSTEF` sin cambio (totales LIF).
5. *Corrección.* `ieps_relativo = micro`: IEPSP ∝ `gas_pc_Gasolinas + gas_pc_Combustibles` (como `TasasEfectivasMicro.ado` l. 136–137), IEPSNP ∝ `IEPS` micro por categoría, en `PerfilesSim.do` **y** `NTA.do`. **Metodológica** (parámetro + FLAG 26/34; `baseline`); 8.16b.

**Ficha 5 — Regalos entre hogares contados dos veces.**
1. *Dónde.* `Expenditure.do` l. 157–160 (`append` de `gastospersona`, `gastohogar`, `gastotarjetas`, `erogaciones` sin filtrar `tipo_gasto`) y l. 330–331, 335–336… (T901 → `Alim`, T909 → `Vest`, …: los regalos otorgados entran por su clave T9xx).
2. *Mecanismo.* La ENIGH registra el regalo en el hogar que lo da (G2, claves T9xx: 90.530 bn) y el bien recibido en el hogar que lo recibe (G5, clave del bien: 548.144 bn); el SCN cuenta el consumo una vez. En la base anclada el G2 pesa 90.530 × 1.085868 × `TT<k>` = **223.272 bn** (Alim 131.7, RecrT 36.9, STra 13.9, DiveT 13.3), asignados al hogar que regala.
3. *Desde cuándo.* Anterior al repo (`509d108`; la clasificación T9xx está en v5.0 `36f7a96`).
4. *Cuánto pesa.* Σ anclado no cambia (los 19 `TT<k>` absorben): **redistribución de hasta 223.272 bn** entre hogares (del que recibe al que da). Llaves: `INCD*` solo vía la base del IVA micro (reescalado a `ConHog`), de segundo orden; `GASTOS`/`INGRESOS` sin cambio.
5. *Corrección.* Decisión 3: contar G5 (quitar `tipo_gasto == "G2"` en §2) o G2. **Metodológica** (FLAG 22; `baseline`); 8.16b.

**Ficha 6 — Predial y tenencia, gas LP y combustibles mal clasificados.**
1. *Dónde.* `Expenditure.do` l. 338–347: R003 (gas natural) y R004 (predial) → `Alqu` (categ 7); R012 (tenencia) → `FTra` (13); G005–G016 (gas LP 111.599, combustibles 10.209, y servicios) → `HogaT` (10); R001 → `Elec` (9).
2. *Mecanismo.* Predial y tenencia son D.59 (impuestos corrientes sobre la propiedad), no consumo; el gas LP, los combustibles sólidos y el gas natural son COICOP 04.5 («electricidad, gas y otros combustibles», BIE 724614), no «artículos para el hogar» (05) ni alquiler (04.1). Por eso `TT<Elec>` = 4.91 y `TT<HogaT>` = 3.84 miden clasificación, no subreporte.
3. *Desde cuándo.* Anterior al repo (`509d108`, v5.0 `36f7a96`).
4. *Cuánto pesa.* Predial + tenencia 53.443 crudo → **169.1 bn** anclados como consumo (R004 × 1.0859 × 1.5699 = 51.7; R012 × 1.0859 × 4.6767 = 117.4). Gas LP + combustibles + gas natural 140.384 crudo: si pasan a `Elec`, `TT<Elec>` 4.910 → **2.449**, `TT<HogaT>` 3.836 → 6.161, `TT<Alqu>` 1.570 → 1.585; sin predial `TT<Alqu>` → 1.614; sin tenencia `TT<FTra>` 4.677 → 4.888. Llaves: redistribución dentro de Σ Cpriv (sin cambio de total); `INCD*` IVA de segundo orden.
5. *Corrección.* Reclasificar (decisión 15): R004/R012 fuera del consumo → `OTROSK`/D.59; G009–G016, R003 → categ 9. **Metodológica** (FLAG 24/25; `baseline`); 8.16b.

**Ficha 7 — +209.212 de D.5: clasificación S.14 ↔ S.11 + S.12.**
1. *Dónde.* `Households.do` l. 315–336 (`LIF … by(divCIEP)` → `ISRSalarios`, `ISRFisicas`, `ISRMorales`, los tres cut-offs de §11) y `TasasEfectivas.ado` l. 34–44 (`LIF … by(divSIM)`: `ISRAS`, `ISRPF`, `ISRPM`). No hay ancla a la CSI.
2. *Mecanismo.* La LIF (y el ITAN) clasifican el ISR por **quién lo entera**: retenciones por salarios 1,254.807, PF 76.665, PM 1,271.053 y retenciones a residentes en el extranjero 81.969 (ITAN 4T 2024; nota 2_/: «la información es proporcionada por el retenedor y no por el obligado al pago»). La CSI clasifica D.5 por **quién lo soporta**: S.14 paga 1,540.050 (D.51 1,518.912 + D.59 21.138) y S.11 + S.12 1,188.648. La diferencia (D.51 S.14 − salarios − PF = 187.4; con D.59, 209.2) es ISR de los hogares que la LIF registra en «personas morales» o en retenciones porque lo entera una sociedad: retenciones sobre intereses y dividendos y el ISR de PF con actividad empresarial retenido por terceros. No es vintage: ISR LIF total 2,682.265 vs D.51 S.1 2,684.588 (+2.323).
3. *Desde cuándo.* Ancla a la LIF desde v5.3 (`36b86b1`, 2022-08-30, `by(divSIM)`); es una decisión de clasificación, no un bug.
4. *Cuánto pesa.* **209.212 bn** en la brecha de Σ S de NTA (τ⁻ directo de hogares subestimado); **0 en `output.txt`** hoy (anclas LIF). Si se ancla a D.51 S.14: factor 1.1413 sobre ISRAS + ISRPF (1,330.838 → 1,518.912) y, para cuadrar el total, ISR PM 1,351.427 → 1,165.676 (D.51 S.11 + S.12); `INGRESOS` sigue siendo la LIF 2027, `INCD*` cambia por la mezcla asalariados/PM.
5. *Corrección.* Decisión 8 (ancla D.51 S.14 con la fila «LIF vs CSI por sector» declarada). **Metodológica** (parámetro + FLAG; `baseline`); 8.16b, con 8.17 para el Sankey.

**Tabla resumen (8.16a)**

| Hallazgo | bn 2024 | Llaves de `output.txt` que toca | Tipo de corrección | Entra en | Origen (commit) |
|---|---:|---|---|---|---|
| 1. FLAG 20, consumo ×1.085868 (`Simulador.ado` deflacta la variable en el dataset; caché del 16-oct) | 871.939 en el log (8.5868 %); **0.000** publicado | ninguna | código + caché (no mueve `data_updated` ni `baseline`) | 8.16b | `cda5c1d` 2023-03-28 (replace); `0afac4e` 2025-09-02 (llamada) |
| 1b. Tabla 1 del memo: Σ ENIGH sin `gastotarjetas` (filas sin factor en `preconsumption.dta`) | 293.933 | ninguna | memo (corregido aquí); FLAG 33 para 8.16 | 8.16a | `preconsumption.dta` 2026-10-16 |
| 2. IEPS no petrolero vs 24.075 (divCIEP) | 0 publicado; micro cubre 12.6 % de 224.780 | ninguna (`DifIEPSNP` solo log) | display / `iepsnp_macro` | 8.16b | anterior al repo (`509d108`) |
| 3. Share salarial del ISR > 1 (gross-up vs cuotas TPF) | Σ obligación 1,424.3 → 1,238.3 (< LIF 1,253.8); informalidad asalariados 30.5 → 0.0 % | `INCD*` (ISR asalariados) | metodológica (`isras_share`, FLAG 27; `baseline`) | 8.16b | `3322f9d` 2024-06-23 |
| 4. IEPS ∝ vehículos / ∝ alcohol (`PerfilesSim.do`, `NTA.do`) | 81.6 (IEPSP) + 41.7 (IEPSNP) cambian de decil | `INCD`, `INCD2`, `INCD3` (IEPS); NTA τ⁻ por edad | metodológica (`ieps_relativo`, FLAG 26/34; `baseline`) | 8.16b | `8c54592` 2024-02-12; `d70ef3d` 2026-10-27 |
| 5. Regalos G2 + G5 | 223.272 anclados (90.530 crudos) redistribuidos | `INCD*` IVA, 2.º orden | metodológica (decisión 3, FLAG 22; `baseline`) | 8.16b | anterior al repo |
| 6. Predial/tenencia en consumo; gas LP en `HogaT` | 169.1 anclados (53.443 crudos); 140.384 crudos de gas (`TT<Elec>` 4.91 → 2.45) | `INCD*` IVA, 2.º orden | metodológica (decisión 15, FLAG 24/25; `baseline`) | 8.16b | anterior al repo |
| 7. D.5 +209.212, S.14 ↔ S.11 + S.12 | 209.212 (brecha de S en NTA) | hoy ninguna; con ancla D.51: `INCD*` | metodológica (decisión 8; `baseline`) | 8.16b / 8.17 | `36b86b1` 2022-08-30 |

### §8 ter — Plan de retiro de `ISRInformesTrimestrales.xlsx` (8.16b)

| Qué | Hoy (v8.15.3) | Con `master/itan-isr-rangos.dta` (8.16b) |
|---|---|---|
| Quién lo lee | Solo `DatosAbiertos.ado` §4.1 l. 723–760: `ensure_asset "ISRInformesTrimestrales.xlsx"`, `import excel … sheet("TipoDeContribuyente")` → `tsset anio trimestre`, diferencia los acumulados (`L.`) para obtener flujos trimestrales y calcula las proporciones `prop_m = (pm + aux)/Σ`, `prop_f = (pfae + pfsae)/Σ`, `prop_s = (ret_ss_pm + ret_ss_pf)/Σ` con las que parte el ISR mensual de Datos Abiertos (`XNA0120`) en `XNA0120_m`, `_f`, `_s`, `_pf` (y `_nopet`, §4.2) | `DatosAbiertos.ado` §4.1 lee `master/itan-isr-rangos.dta` (`rango == "Total"`, los 7 tipos en wide: mismos nombres `pm pfae pfsae ret_ss_pm ret_ss_pf aux total`) para 2019-1 en adelante y conserva la captura solo para 2012–2018 (donde el ITAN no publica la tabla en `.xlsx`); `AccesoITAN` se invoca antes (sello en el log) |
| Columnas que usa | `anio trimestre total pm pfae pfsae ret_ss_pm ret_ss_pf aux` (acumulados, mdp) | idénticas; además quedan disponibles los 12 rangos × 7 tipos, los conceptos (PM, PF, retenciones al extranjero, retenciones por salarios) y los contribuyentes con pago |
| Quién consume el resultado | `PerfilesSim.do` l. 555–557 (`DatosAbiertos XNA0120_s/_f/_m, pibvp()`: gráficas de ISR salarios/PF/PM, solo con gráficas) y `LIF.ado` l. 91–93 (`master/DatosAbiertos.dta`) | sin cambio de interfaz |
| Diferencias que el cambio introduce | — | 2021 (cuatro trimestres, todos los tipos) y 2022-3T (PM + aux +48,549 mdp): el ITAN publicado manda; `prop_*` de esos trimestres cambian (los flujos trimestrales de 2021 y 2022-3/4 se recalculan) → `master/DatosAbiertos.dta` cambia en `XNA0120_*` de 2021–2022; `output.txt` **no** (no lee Datos Abiertos) |
| Asset | `ISRInformesTrimestrales.xlsx` (14,718 B, captura manual 2012-1 … 2026-1, sin procedencia por celda) | `raw/ITAN/itan-congelado.zip` (3,450,638 B, `desde v8.16.0`) + `05_scripts/itan-catalogo.json` (sha256 por archivo, URL, celdas); `refrescar-scn.sh --itan` vigila el trimestre nuevo; la captura se recorta a 2012–2018 y se declara «histórica» |
| Prueba | — | `AccesoITAN, validar` imprime capturado vs extraído por trimestre (29 comunes hoy, 25 iguales a 0.1 mdp); al retirar: `cmp` de `DatosAbiertos.dta` antes/después restringido a 2012–2020 debe dar 0 diferencias |


## §9 Específico de México

| Elemento | Qué requiere genéricamente | Por qué México lo resuelve así | En cap0 |
|---|---|---|---|
| Consumo privado por finalidad (BIE 724600–724656) | Consumo final de hogares por COICOP con el sector hogares separado de las ISFLSH | INEGI publica la apertura por finalidad solo para «hogares e ISFLSH» en territorio (BIE); la CSI separa S.14 de S.15 solo en el total P.3. Por eso el ancla por rubro es hogares + ISFLSH y la corrección a S.14 es un factor único | fila 4 (nueva línea: P.3 por finalidad) |
| ENIGH `tipo_gasto` y claves 2018 | Encuesta de gasto con tipo (monetario, autoconsumo, regalos, en especie, transferencias, alquiler imputado) y catálogo estable | La ENIGH 2024 «nueva serie» cambió claves (6 dígitos); el motor trabaja con `clave_2018` vía `clave_iva.dta` (construida por CIEP) | fila 2 |
| Recaudación por impuesto (LIF, `divSIM`) | Recaudación observada por impuesto del año de la encuesta, compatible con el SCN | La LIF/SHCP publica mensual por concepto (ISR asalariados, PF, PM; IVA; IEPS por producto); el SCN no separa IVA de IEPS por sector pagador (D.211 sí es IVA al peso; D.214 junta IEPS, ISAN y estatales) | fila 7 |
| Recaudación del ISR por rango de ingreso (SHCP, ITAN) | Base gravable e ISR causado por rango de ingreso del año de la encuesta | La SHCP publica cada trimestre (anexo `itanfp02`, desde 2019-1T) la **recaudación** por rango de ingreso anual *declarado* × tipo de contribuyente, no la base gravable ni el ISR causado; los rangos de las retenciones por salarios ordenan al retenedor. El SAT publica microdatos anonimizados solo 2010–2015. Asset `itan-congelado.zip`, catálogo `itan-catalogo.json` (8.16a) | fila 12 (nueva línea) |
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
| §8 bis, §8 ter (8.16a) | `Simulador.ado` l. 39–110; `Expenditure.do` l. 120–135, 157–172, 330–380, 593–605, 790–830; `Households.do` l. 315–336, 2433–2439; `NTA.do` l. 534–535; `PerfilesSim.do` l. 288–294, 553–557; `TasasEfectivas.ado` l. 34–44; `DatosAbiertos.ado` l. 723–800; `git log -S` (fechas en cada ficha); `~/CIEP_Simuladores/diag-8.16a-2026-11-07/` (`r0-deflator`, `r1-expenditure-sin-cache`, `r2-isras-acotado`, `r5-accesoitan`, `probes/`) |

---

## Δ esperado de 8.16

Solo por inferencia de las tablas; nada se corrió. `baseline` pasa a **v8.16.0** (los números dejan de comparar con v8.15.x).

| Llave / agregado | v8.15.3 | 8.16 (propuesto) | Dirección | Por qué |
|---|---:|---:|---|---|
| Σ Cpriv (`nta-identidad.txt`) | 23,819.398 | 23,381.329 | ↓ −438.069 | `consumo_ancla = p3_s14` |
| Σ S sin ancla vs B.8n | 2,116.145 (+11.3 %) | **tras 8.16: 2,366.139 (+24.5 %)**, medido en 8.16b (D.5 y Cpriv cierran; la fila τ +461.0 queda para 8.17); **tras 8.17: 1,881.607 (−1.0 %)**, medido en la sesión 8.17 (esperado −0.9 %) | ↑ en 8.16, ↓ en 8.17 | §7 |
| `CUADRATURA` (YL, YA, …) | 43.636, 24.435, … | **sin cambio** | = | 8.16 no toca las anclas de `Households` §9 |
| `INGRESOS` (LIF `anioPE` % PIB, 20 valores) | 3.855, 0.244, 1.782, … | **sin cambio** | = | son la LIF 2027; no dependen del micro |
| `INGRESOSTEF[4,5,6]` (ISRPMTE, OTROSKTE, IngKPrivadoTotTE) | 12.9, 5.0, 19.5 | `ISRPMTE` pasa a B.2n S.11 + S.12 como denominador (decisión 7 corregida, 2026-11-08); OTROSKTE e IngKPrivadoTotTE siguen sobre `IngKPrivado` | ↑ ISRPMTE (denominador menor) | `isrpm_incidencia` |
| `INGRESOSTEF[9]` (IEPSNPTE) | 47.9 | sin cambio (el macro de `TasasEfectivas` ya es `divSIM`) | = | `iepsnp_macro` solo corrige `Expenditure.do` |
| `INCD`, `INCD2`, `INCD3` (43 bloques: incidencia por decil, nacional y 32 entidades, ISR/IVA/…) | — | **se mueven**: ISR PM ∝ `d4_relativo` concentra en deciles altos; IEPS ∝ gasolinas/alcohol/tabaco reparte distinto; cuotas por sector no cambia quién paga | ISR PM ↑ en X, ↓ en I–VIII | `isrpm_incidencia`, `ieps_relativo` |
| `GASTOS`, `GASTOSPC`, `GASTOSPOB*`, `PROY*` | — | **sin cambio** | = | PEF, no micro |
| `IVA` (parámetros `IVAT`) | 16, 1, 2, …, 23.1 | sin cambio salvo que `consumo_ancla` mueva `DifIVA` (el micro se reescala a `ConHog/MTot`, `E l.1190`: con P.3 S.14 el reescalamiento baja a 0.9665 → IVA micro 1,770.4 y `DifIVA` ≈ 20.5 %) | `IVAT[13]` ↓ ≈ 2.6 pp (si se recalibra) | `E l.1190–1215` |
| Sankey NTA v3: nodo `Gobierno` | 5,252.870 entradas desde `Ing nacional` | −1,045.130 de cuotas (van a S.12/S.11) | ↓ | `cuotas_por_sector` (nodos en 8.17) |
| 10 sankeys, 32 entidades (`contrato-32.sh`) | baseline v8.15.0 | re-baseline | ROJO esperado | |

Lo que **no** se infiere de las tablas: cuánto cambia la distribución por decil del ISR PM con `ing_d4_rel` (depende de la cobertura 0.43 % de la ENIGH en D.4: sello rojo de CUAD-0) y el tamaño del +11.8 % de la base del consumo una vez localizado (FLAG 20).
