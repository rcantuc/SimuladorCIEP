# Celdas del SCN que lee el motor — inventario (v8.15b-pre, 2026-10-31)

Insumo de la política de fuente SCN de CUAD-0 §4 bis (canal BIE por API; congelado en `raw/`; refresco deliberado). Es el inventario que `05_scripts/refrescar-scn.sh --comparar` recorre. **Hoy nada del SCN es asset del manifest**: lo que el motor lee es `master/SCN.dta`, construido por `SCN.ado` (`UpdateSCN`) a partir de (i) 525 series del BIE descargadas por `AccesoBIE.ado` (copia exacta en `raw/temp/AccesoBIE/<serie>.csv`) y (ii) los tabulados de cuentas por sector institucional `raw/temp/SCN/CSI_*.xlsx` (zip de INEGI). Ninguno registra etiqueta preliminar/revisada; el vintage es la fecha del archivo. Clon de referencia: `-datos` (`ee410a3`, v8.14.0). Valores 2024 en miles de millones de MXN (bn) tal como están en `master/SCN.dta`.

| Capa | Archivo | Vintage que registra el motor | sha256 |
|---|---|---|---|
| Base que lee el motor | `master/SCN.dta` | archivo del 2026-10-28 20:49 (sin etiqueta INEGI) | `3bdc3a0215a3` |
| Descargas BIE (API) | `raw/temp/AccesoBIE/<serie>.csv` ×525 nacionales | archivos del 2026-10-16 00:34 al 2026-10-16 00:48; `periodo,valor`; sin LASTUPDATE ni OBS_NOTE guardados | por serie (ver `refrescar-scn.sh`) |
| Tabulados CSI (zip INEGI, no API) | `raw/temp/SCN/CSI_103/106/109/112/115/118.xlsx` | archivos del 2026-10-16 00:48; INEGI «2024 revisada» (CONC-1) | CSI_103 `c28d560709f5`, CSI_115 `f0e9fecfd9f8`, CSI_106 `b498099f959d`, CSI_109 `230c609766cf`, CSI_112 `3b981612648c`, CSI_118 `9bf053f965f0` |

**Brecha frente a §4 bis:** vintage BIE vs CSI sin resolver (PIB 33,667.023 BIE vs B.1b CSI 33,582.899; RemSalSS 10,013.434 vs D.1 S.14 10,052.962); ninguna celda está congelada como asset con sha256 en el manifest; `UpdateSCN` descarga en caliente cuando falta `master/SCN.dta` o con `global update`. El modo `--congelar` de `refrescar-scn.sh` queda documentado y deshabilitado hasta 8.15b.

## A. Series BIE que llegan a un escalar que algún módulo lee

Serie = clave del indicador en el BIE (`AccesoBIE <serie>`); variable = nombre en `SCN.ado`; archivo = `.dta` intermedio de `UpdateSCN` que se fusiona en `master/SCN.dta`. Consumidores según `grep scalar()` en `01_modulos/*.do` y los `.ado` (2026-10-31).

| Serie BIE | Variable | Etiqueta INEGI (SCN.ado) | Bloque / archivo intermedio | 2024 (bn) | Quién la consume | Vintage (csv) |
|---|---|---|---|---:|---|---|
| 724014 | `RemSalSS` | Remuneraciones a asalariados + CSS | §1.1 Generación del ingreso / GenIng.dta | 10,013.434 | SCN B.1 (Yl, ImpNetProduccionL); TasasEfectivas (RemSalSSPIB) | 2026-10-16 00:34 |
| 724015 | `RemSal` | Remuneraciones a asalariados | §1.1 Generación del ingreso / GenIng.dta | 8,559.205 | Households §1.1/§9 (TaltimirSal), PerfilesSim, TasasEfectivas | 2026-10-16 00:34 |
| 724016 | `SSEmpleadores` | CSS empleadores | §1.1 Generación del ingreso / GenIng.dta | 1,454.229 | Households §1.1/§9, TasasEfectivas | 2026-10-16 00:34 |
| 724017 | `Imp` | Impuestos a la producción | §1.1 Generación del ingreso / GenIng.dta | 2,527.875 | SCN (ImpuestosNetos) | 2026-10-16 00:34 |
| 724018 | `ImpProductos` | Impuestos a los productos | §1.1 Generación del ingreso / GenIng.dta | 2,268.863 | SCN B.5 → ImpNetProductos (Households §9, l. 2420-2427) | 2026-10-16 00:34 |
| 724022 | `ImpProduccion` | Impuestos a la producción | §1.1 Generación del ingreso / GenIng.dta | 259.012 | SCN B.5 → ImpNetProduccion → ImpNetProduccionL/K (Households §9, §12) | 2026-10-16 00:35 |
| 724023 | `Sub` | Subsidios (total) | §1.1 Generación del ingreso / GenIng.dta | 106.061 | SCN (ImpuestosNetos) | 2026-10-16 00:35 |
| 724024 | `ExBOp` | Excedente bruto de operación | §1.1 Generación del ingreso / GenIng.dta | 21,231.775 | SCN B.3 → ExNOpSoc residuo (Households §9 TaltimirCap; PerfilesSim) | 2026-10-16 00:35 |
| 724025 | `PIB` | Producto Interno Bruto | §1.1 Generación del ingreso / GenIng.dta | 33,667.023 | Households §1.1 (PIBSCN), Expenditure, NTA, ISR_Mod, PerfilesSim, TasasEfectivas (pibY), escalar PIB de todo el motor | 2026-10-16 00:35 |
| 723652 | `ProdT` | Producción total | §2.1 Producción bruta / ProdBru.dta | 56,492.634 | SCN cuenta A | 2026-10-16 00:35 |
| 723656 | `ImpNet` | Impuestos netos | §2.1 Producción bruta / ProdBru.dta | 2,174.811 | Households §9 Altimir (ImpNetProductos_*), NTA §4.3, PerfilesSim | 2026-10-16 00:35 |
| 723657 | `ImpProd` | Impuestos a los productos | §2.1 Producción bruta / ProdBru.dta | 2,268.863 | SCN cuadre | 2026-10-16 00:35 |
| 723658 | `SubProd` | Subsidios a los productos | §2.1 Producción bruta / ProdBru.dta | 94.053 | SCN B.5 → ImpNetProductos | 2026-10-16 00:35 |
| 723663 | `ConsInt` | Consumo intermedio | §2.1 Producción bruta / ProdBru.dta | 25,000.422 | SCN cuenta A | 2026-10-16 00:35 |
| 724028 | `CapFij` | Consumo de capital fijo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 6,457.576 | Households §11.3 (ConCapFij: depreciación ∝ ing_capital), NTA (YA neto), SCN B/C | 2026-10-16 00:35 |
| 724029 | `PIN` | Producto interno neto | §3.1 Ingreso nacional disponible / IngNacDis.dta | 27,209.448 | PerfilesSim, SCN C | 2026-10-16 00:35 |
| 724030 | `ROWRemR` | Remuneraciones recibidas del resto del mundo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 52.721 | SCN C.6 → ROWRem (Households §12 ing_suborROW; Sankey.do) | 2026-10-16 00:35 |
| 724031 | `ROWRemP` | Remuneraciones pagadas al resto del mundo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 0.000 | ídem | 2026-10-16 00:36 |
| 724032 | `ROWPropR` | Ingresos a la propiedad recibidos del resto del mundo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 361.554 | SCN C.6 → ROWProp (Households ing_capitalROW; Sankey.do) | 2026-10-16 00:36 |
| 724033 | `ROWPropP` | Ingresos a la propiedad pagados al resto del mundo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 1,350.775 | ídem | 2026-10-16 00:36 |
| 724034 | `ROWTransR` | Transferencias recibidas del resto del mundo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 1,211.876 | SCN C.6 → ROWTrans (Households §9 TaltimirROWTrans: remesas; Sankey.do) | 2026-10-16 00:36 |
| 724035 | `ROWTransP` | Transferencias pagadas al resto del mundo | §3.1 Ingreso nacional disponible / IngNacDis.dta | 25.786 | ídem | 2026-10-16 00:36 |
| 724600 | `ConHog` | Consumo de hogares e ISFLSH | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 24,192.112 | Expenditure (ancla ConHog), PerfilesSim, TasasEfectivas (ConHogPIB), SCN D | 2026-10-16 00:36 |
| 724601 | `AlimBebT` | Alimentos y bebidas | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 6,144.682 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724602 | `Alim` | Alimentos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 5,524.006 | Expenditure.do (ancla TTAlim); SCN R.6 | 2026-10-16 00:36 |
| 724603 | `BebN` | Bebidas no alcohólicas | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 620.675 | Expenditure.do (ancla TTBebN); SCN R.6 | 2026-10-16 00:36 |
| 724604 | `BebTabT` | Bebidas alcohólicas y tabaco | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 497.630 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724605 | `BebA` | Bebidas alcohólicas | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 361.568 | Expenditure.do (ancla TTBebA); TasasEfectivas BebAPIB | 2026-10-16 00:36 |
| 724606 | `Taba` | Tabaco | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 136.062 | Expenditure.do (ancla TTTaba); TasasEfectivas TabaPIB | 2026-10-16 00:36 |
| 724607 | `VestCalT` | Prendas de vestir y calzado | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 452.177 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724608 | `Vest` | Prendas de vestir | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 328.684 | Expenditure.do (ancla TTVest); SCN R.6 | 2026-10-16 00:36 |
| 724609 | `Calz` | Calzado | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 123.494 | Expenditure.do (ancla TTCalz); SCN R.6 | 2026-10-16 00:36 |
| 724610 | `AlojT` | Alquiler efectivo y conservación de la vivienda | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 3,763.882 | Households §1.2 (SNAAlojamiento: share pf/PM de rentas); Expenditure (TT) | 2026-10-16 00:36 |
| 724611 | `Alqu` | Alquiler efectivo | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 2,763.650 | Expenditure.do (ancla TTAlqu); SCN R.6 | 2026-10-16 00:36 |
| 724612 | `CRep` | Conservación y reparación de la vivienda | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 190.536 | Expenditure.do (ancla TTCRep); SCN R.6 | 2026-10-16 00:36 |
| 724613 | `Agua` | Agua | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 64.995 | Expenditure.do (ancla TTAgua); SCN R.6 | 2026-10-16 00:36 |
| 724614 | `Elec` | Electricidad, gas y otros combustibles | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 744.701 | Expenditure.do (ancla TTElec); SCN R.6 | 2026-10-16 00:36 |
| 724615 | `HogaT` | Artículos para el hogar | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 1,366.870 | Expenditure.do (ancla TTHogaT); SCN R.6 | 2026-10-16 00:36 |
| 724616 | `Mueb` | Muebles | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 177.662 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724617 | `Text` | Textiles | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 58.247 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724618 | `Arte` | Artefactos eléctricos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 331.911 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724619 | `Vajil` | Vajillas y utensilios | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 119.474 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724620 | `Herr` | Herramientas | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 117.581 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724621 | `ConH` | Consumo de salud | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 561.995 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724622 | `SaluT` | Salud | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 739.771 | Expenditure.do (ancla TTSaluT); SCN R.6 | 2026-10-16 00:36 |
| 724623 | `Smed` | Servicios médicos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 420.539 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724624 | `Sext` | Servicios dentales | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 181.525 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724625 | `Hosp` | Hospitales | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 137.708 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724626 | `TraT` | Transporte | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 5,053.399 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:36 |
| 724627 | `Vehi` | Adquisición de vehículos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 832.724 | Expenditure.do (ancla TTVehi); TasasEfectivas VehiPIB | 2026-10-16 00:36 |
| 724628 | `FTra` | Funcionamiento de transporte | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 2,715.704 | Expenditure.do (ancla TTFTra); SCN R.6 | 2026-10-16 00:36 |
| 724629 | `STra` | Servicios de transporte | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 1,504.971 | Expenditure.do (ancla TTSTra); SCN R.6 | 2026-10-16 00:36 |
| 724630 | `ComuT` | Comunicaciones | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 525.720 | Expenditure.do (ancla TTComuT); SCN R.6 | 2026-10-16 00:37 |
| 724631 | `Post` | Correos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 55.626 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724632 | `TelEq` | Teléfonos y equipo de comunicación | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 0.166 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724633 | `TelS` | Servicios telefónicos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 469.927 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724634 | `RecrT` | Recreación y cultura | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 1,185.699 | Expenditure.do (ancla TTRecrT); SCN R.6 | 2026-10-16 00:37 |
| 724635 | `Audi` | Aparatos de audio y video | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 439.033 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724636 | `Durab` | Durables | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 18.770 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724637 | `ArtEq` | Artículos de esparcimiento | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 242.138 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724638 | `Culs` | Cultura | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 412.049 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724639 | `Publ` | Publicaciones | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 44.167 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724640 | `Turis` | Turismo | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 29.543 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724641 | `EducT` | Educación | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 322.257 | Expenditure.do (ancla TTEducT); SCN R.6 | 2026-10-16 00:37 |
| 724642 | `PrePri` | Preescolar y primaria | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 85.021 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724643 | `Secu` | Secundaria | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 98.567 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724644 | `PostNT` | Postsecundaria no terciaria | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 1.081 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724645 | `Terc` | Terciaria | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 134.475 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724646 | `NoAtr` | No atribuible | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 3.112 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724647 | `RestT` | Restaurantes y hoteles | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 1,371.191 | Expenditure.do (ancla TTRestT); SCN R.6 | 2026-10-16 00:37 |
| 724648 | `Comi` | Comidas | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 725.177 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724649 | `Hote` | Hoteles | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 646.014 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724650 | `DiveT` | Bienes y servicios diversos | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 2,768.834 | Expenditure.do (ancla TTDiveT); SCN R.6 | 2026-10-16 00:37 |
| 724651 | `Cuid` | Cuidado personal | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 233.694 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724652 | `EfeP` | Efectos personales | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 358.383 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724653 | `Prot` | Productos de protección | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 25.123 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724654 | `Segu` | Seguros | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 292.050 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724655 | `ServF` | Servicios financieros | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 1,482.256 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724656 | `OtrS` | Otros servicios | §4.1 Consumo de hogares e ISFLSH / ConHog.dta | 377.328 | SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN) | 2026-10-16 00:37 |
| 724771 | `GastPrivT` | Gastos de consumo privado - Total | §5.1 Consumo privado / GastPriv.dta | 23,819.398 | SCN D | 2026-10-16 00:37 |
| 724777 | `ComprasN` | Compras netas de residentes y no residentes | §5.1 Consumo privado / GastPriv.dta | -372.715 | Households (gasto_anualComprasN), NTA (Cpriv), Sankey.do, SCN D | 2026-10-16 00:37 |
| 724959 | `ConGob` | Gastos de consumo de gobierno general - Total | §6.1 Consumo de gobierno / GovCons.dta | 3,916.328 | Households (gasto_anualGobierno), NTA (colectivo), Sankey.do, SCN D | 2026-10-16 00:37 |
| 725116 | `ConsPriv_21` | 21 Minería | §8.1 Consumo privado por actividad / SecExt.dta | 678.177 | TasasEfectivas (ConsPriv21PIB: IEPS petrolero) | 2026-10-16 00:48 |
| 725126 | `ConsPriv_54` | 54 Servicios profesionales, científicos y técnicos | §8.1 Consumo privado por actividad / SecExt.dta | 121.918 | Households §1.2 (ConsPriv54: honorarios pf/PM) | 2026-10-16 00:48 |
| 725130 | `ConsPriv_62` | 62 Servicios de salud y de asistencia social | §8.1 Consumo privado por actividad / SecExt.dta | 1.007 | Households §1.2 (ConsPriv62: salud pf/PM) | 2026-10-16 00:48 |
| 780054 | `Inmob5311` | 5311 Alquiler sin intermediación de bienes raíces | §7 PIB por actividad / PIBAE1-5.dta | 2,708.952 | Households §1.2 (SNAAlquiler: share pf/PM de rentas, l. 466-467) | 2026-10-16 00:45 |
| 780055 | `Inmob5312` | 5312 Inmob5312 y corredores | §7 PIB por actividad / PIBAE1-5.dta | 75.908 | Households §1.2 (SNAInmobiliarias) | 2026-10-16 00:45 |
| 780065 | `Prof541_T` | Total subsector 541: Servicios profesionales, científicos y técnicos | §7 PIB por actividad / PIBAE1-5.dta | 728.248 | Households §1.2 (ServProf) | 2026-10-16 00:45 |
| 780103 | `Salud6211` | 6211 Consultorios médicos | §7 PIB por actividad / PIBAE1-5.dta | 253.442 | Households §1.2 (ConsMedi) | 2026-10-16 00:46 |
| 780104 | `Salud6212` | 6212 Consultorios dentales | §7 PIB por actividad / PIBAE1-5.dta | 59.290 | Households §1.2 (ConsDent) | 2026-10-16 00:46 |
| 780105 | `Salud6213` | 6213 Otros consultorios para el cuidado de la salud | §7 PIB por actividad / PIBAE1-5.dta | 7.854 | Households §1.2 (ConsOtro) | 2026-10-16 00:46 |
| 780108 | `Salud6216` | 6216 Servicios de enfermería a domicilio | §7 PIB por actividad / PIBAE1-5.dta | 1.320 | Households §1.2 (EnfeDomi) | 2026-10-16 00:46 |
| 780135 | `Recre7132` | 7132 Casinos, loterías y otros juegos de azar | §7 PIB por actividad / PIBAE1-5.dta | 31.082 | TasasEfectivas (Recre7132PIB: IEPS juegos) | 2026-10-16 00:47 |

93 series de 525 descargadas. Las 432 restantes (PIB por actividad §7, consumo de gobierno por rama §6, consumo privado por rama §8, agregados de producción §2) viven en `master/SCN.dta` sin consumidor fuera de `SCN.ado`; `refrescar-scn.sh --todas` las compara también.

## B. Celdas de los tabulados CSI (no están en la API del BIE)

`UpdateSCN` §9-§25b y `SCNHogaresS14` leen filas de `raw/temp/SCN/CSI_<cuadro>.xlsx` (zip `tabulados_CSI.zip`, INEGI SCNM base 2018). Columnas: pares (U/A, R/P) por año desde 2003 en B; 2024 = AR (U/A) y AS (R/P). **El BIE no tiene estas celdas como serie**: se dicen con cuadro, fila y columna, y no se sustituyen.

| Cuadro (sector) | Fila | Columna | Variable | Código SCN | 2024 (bn) | Quién la consume |
|---|---:|---|---|---|---:|---|
| CSI_103 (S.1 economía total) | 60 | U/A | `IngMixto` | B.3b ingreso mixto bruto | 7,480.868 | SCN B.1 → MixN, MixL (⅔), MixK, MixKN: Households §9 (TaltimirSelf), PerfilesSim, TasasEfectivas (MixLPIB) |
| CSI_103 | 41 | U/A | `SSImputada` | D.122 contribuciones sociales imputadas | 221.830 | SCN B (RemSal = RemSalSS − SSEmpleadores − SSImputada); Households §1.1/§9; TasasEfectivas |
| CSI_103 | 54 | U/A | `SubProductos` | D.31 subsidios a los productos | -94.053 | SCN (ImpNetProductos usa SubProd del BIE; SubProductos CSI queda en SCN.dta) |
| CSI_103 | 58 | U/A | `SubProduccion` | D.39 otros subsidios a la producción | -12.009 | SCN B.5 → ImpNetProduccion (Households §9/§12) |
| CSI_103 | 62 | U/A | `DepMix` | P.51c consumo de capital fijo del ingreso mixto | 523.884 | SCN B.1 (MixN, MixK, MixKN); Households §1.1 (local DepMix) |
| CSI_106 (S.11) | 59 | U/A | `ExBOpNoFin` | B.2b excedente bruto, sociedades no financieras | 10,157.033 | SCN.dta (informativo; ExNOpSoc se calcula como residuo) |
| CSI_109 (S.12) | 59 | U/A | `ExBOpFin` | B.2b sociedades financieras | 1,263.329 | ídem |
| CSI_118 (S.15) | 59 | U/A | `ExBOpISFLSH` | B.2b ISFLSH | 133.845 | ídem |
| CSI_115 (S.14) | 59 | U/A | `ExBOpHog` | B.2b excedente bruto, hogares | 2,107.569 | Households §1.2 (SNAExBOpHog: share pf/PM de rentas, l. 466-467) |
| CSI_112 (S.13) | 59 | U/A | `ExBOpGob` | B.2b gobierno | 8.993 | SCN.dta (informativo) |
| CSI_106 | 63 | U/A | `ExNOpNoFin` | B.2n | 5,522.905 | SCN.dta (informativo) |
| CSI_109 | 63 | U/A | `ExNOpFin` | B.2n | 1,200.594 | ídem |
| CSI_118 | 63 | U/A | `ExNOpISFLSH` | B.2n | 102.442 | ídem |
| CSI_115 | 63 | U/A | `ExNOpHog` | B.2n excedente neto, hogares (alquiler imputado) | 910.359 | SCN B.3/B.4 (ExNOpSoc residuo, Capital); Households §9 (TaltimirHouse), §12 |
| CSI_112 | 63 | U/A | `ExNOpGob` | B.2n gobierno (0 en 2024) | 0.000 | SCN B.3/B.4; Households §1.1 |
| CSI_103 | 170 | U/A | `AhorroB` | B.8b ahorro bruto, economía total | 6,149.927 | SCN.dta (informativo; AhorroN se calcula como residuo) |
| CSI_103 | 152 | U/A | `IngDisp` | B.6b ingreso disponible bruto | 33,827.423 | SCN.dta (informativo; IngDispCalc se calcula) |
| CSI_115 | 170 | U/A | `AhorroHogB` | B.8b ahorro bruto hogares | 3,622.120 | NTA (escalar AhorroHogB) |
| CSI_115 | 171 | U/A | `AhorroHogN` | B.8n ahorro neto hogares | 1,901.026 | NTA (AhorroHog: ancla de S) |
| CSI_115 | 166 | U/A | `ConHogS14` | P.3 gasto de consumo final hogares | 23,381.329 | NTA (ConHogS14_P3) |
| CSI_115 | 176 | U/A | `ConEfecHogS14` | P.4 consumo final efectivo | 25,780.497 | NTA (TransfEspecie = P.4 − P.3) |
| CSI_115 | 117 | U/A | `ContribSocHog` | D.61 contribuciones sociales netas | 2,335.022 | NTA (CuotasHogS14 = D.61 − D.614) |
| CSI_115 | 127 | U/A | `ContribComplHog` | D.614 contribuciones complementarias | 605.932 | ídem |
| CSI_103 | 25 | R/P | `ImpProductosS1` | D.21 impuestos sobre los productos | 2,269.960 | NTA (ImpNetosProd = D.21 − D.31) |
| CSI_103 | 26 | R/P | `SubProductosS1` | D.31 subsidios a los productos (signo del tabulado) | -94.053 | ídem |
| CSI_115 | 169 | R/P | `AjustePensHog` | D.8 ajuste por derechos de pensión | 1,270.277 | NTA (YA_d8) |
| CSI_115 | 131 | R/P | `PrestSocHog` | D.62 prestaciones sociales en dinero | 1,839.952 | NTA (TauPubS14) |
| CSI_115 | 151 | R/P | `OtrasTransfHog` | D.759 otras transferencias corrientes | 1,605.191 | NTA (TauPubS14) |
| CSI_115 | 69 | R/P | `ExNOpHogS14` | B.2n | 910.359 | NTA (YAHogS14); Households §9 con yk_ancla = b2n_b3n_d4 |
| CSI_115 | 70 | R/P | `MixNHogS14` | B.3n ingreso mixto neto hogares | 6,956.984 | NTA (YAHogS14: ⅓) |
| CSI_115 | 95 | R/P − U/A | `RentaPropHogR − RentaPropHogU` | D.4 renta de la propiedad neta | 5,602.969 (R 6,116.263, U 513.293) | NTA (YAHogS14; RentaPropHogNeta); Households §9 con yk_ancla = b2n_b3n_d4 |
| CSI_115 | 157 | R/P | `(verificación)` | D.63 transferencias sociales en especie = P.4 − P.3 |  | SCNHogaresS14 (FLAG si no cuadra) |

## C. Escalares derivados (fórmula en `SCN.ado`) y de qué celdas dependen

| Escalar | Fórmula (SCN.ado) | Celdas | 2024 (bn) | Quién lo consume |
|---|---|---|---:|---|
| `RemSal` | RemSal_BIE − SSImputada | 724015, CSI_103 f.41 | 8,559.205 | Households §1.1/§9 (TaltimirSal), PerfilesSim, TasasEfectivas |
| `MixN / MixL / MixK / MixKN` | IngMixto − DepMix; ⅔ MixN; ⅓ MixN + DepMix; MixK − DepMix | CSI_103 f.60, f.62 | n/a (MixL) / n/a (MixKN) | Households §9 (TaltimirSelf), TasasEfectivas, PerfilesSim |
| `ExNOpSoc` | (ExBOp − CapFij) − MixN − ExNOpHog − ExNOpGob (residuo) | 724024, 724028, CSI_103 f.60/62, CSI_115 f.63, CSI_112 f.63 | n/a | Households §9 (TaltimirCap), PerfilesSim |
| `Capital` | ExNOpSoc + MixKN + ExNOpHog + ExNOpGob | ídem | n/a | SCN B.4 |
| `ImpNetProduccion` | ImpProduccion + SubProduccion | 724022, CSI_103 f.58 | n/a | SCN B.5 |
| `ImpNetProduccionL` | ImpNetProduccion × (RemSalSS + MixL)/(RemSalSS + MixL + Capital) | 724014, 724022, … | n/a | Households §9/§12, PerfilesSim, TasasEfectivas |
| `ImpNetProduccionK` | ImpNetProduccion − ImpNetProduccionL + DiscEstPIB | … | n/a | Households §9/§12 |
| `ImpNetProductos` | ImpProductos − SubProd | 724018, 723658 | n/a | Households §9/§12 (ImpNetProductos_*) |
| `Yl` | RemSalSS + MixL + ImpNetProduccionL | 724014, CSI_103, 724022 | n/a | PerfilesSim, TasasEfectivas (YlPIB) |
| `CapIncImp` | Capital + ImpNetProduccionK + ImpNet | …, 723656 | n/a | TasasEfectivas (CapIncImpPIB) |
| `ROWRem / ROWProp / ROWTrans` | recibidas − pagadas | 724030-724035 | n/a / n/a / n/a | Households §9/§12, Sankey.do |
| `IngDispCalc, AhorroN` | PIN + ROW + CapFij; − ConHog − ConGob − ComprasN | 724029, 724030-35, 724028, 724600, 724959, 724777 | n/a / n/a | SCN C/D, Sankey.do (AhorroN) |
| `YAHogS14` | ExNOpHogS14 + MixNHogS14/3 + RentaPropHogR − RentaPropHogU | CSI_115 f.69, 70, 95 | 8,832.323 | NTA (nta_YA = S14) |
| `CuotasHogS14, ImpNetosProdS1, TauPubS14` | D.61 − D.614; D.21 − |D.31|; D.62 + D.759 | CSI_115 f.117/127; CSI_103 f.25/26; CSI_115 f.131/151 | 1,729.089 / 2,175.907 / 3,445.143 | NTA |

## D. Lo que no está en el BIE o viene de otra tabla

- **Ingreso mixto, consumo de capital fijo del mixto, contribuciones imputadas, subsidios por tipo, excedente por sector, ahorro e ingreso disponible brutos (tabla B, filas CSI_103/106/109/112/118):** no son series del BIE; el motor los toma del zip `tabulados_CSI.zip` (SCNM base 2018, cuentas por sector institucional). Clave exacta = cuadro + fila + columna (par U/A o R/P del año). `refrescar-scn.sh --csi` compara el sha256 de cada cuadro y las filas del inventario.
- **Sector hogares S.14 completo (CSI_115):** las anclas de `NTA.do` (B.8n, P.3, P.4, D.61, D.614, D.8, D.62, D.759, B.2n, B.3n, D.4) y las dos celdas que `yk_ancla = b2n_b3n_d4` usa. Mismo canal.
- **Población** (`master/Poblaciontot.dta`, CONAPO) se fusiona en `master/SCN.dta` pero no es SCN: la gobierna `Poblacion.ado` y el asset `Poblacion_Estimada_Mitad_Anio.zip`.
- **`escalar pctpib` de LIF/PEF** (ISRASPIB, …) no son SCN: salen de `LIF.ado`/`PEF.ado` (assets `LIFs.xlsx`, `CP *.xlsx`).

## E. Cómo se refresca

1. `bash 05_scripts/refrescar-scn.sh --comparar [--csi]` desde el clon con `set_token.do` (API oficial; si no responde, consulta pública de exportación del BIE, declarada por serie; los sufijos del periodo «p1»/«r1» son la etiqueta preliminar/revisada): imprime y guarda (en `--salida`, nunca en `raw/`) celda, valor congelado, valor BIE, Δ, Δ % del PIB, etiqueta INEGI (`OBS_STATUS`/`OBS_NOTE` del último dato, `LASTUPDATE` de la serie) y fecha de consulta; exit 0 sin revisión, 1 con diferencias, 3 no comparado.
2. Con diferencias: PR de datos (runbook-actualizar-assets.md) con el reporte adjunto; `data_updated` y CHANGELOG declaran el Δ. `--congelar` (escritura en `raw/` + manifest) queda deshabilitado hasta 8.15b.
3. `SIM.do` y los `.ado` nunca llaman a este script: el motor solo lee `master/SCN.dta` (y, cuando falta, `UpdateSCN` descarga: esa es la lectura en caliente que §4 bis retira en 8.15b).

*Generado con `diag-v8.15b-pre-2026-10-31/gen-scn-celdas.py` a partir de `SCN.ado`, el grep de consumidores y la fila 2024 de `-datos/master/SCN.dta`; se edita en su lugar cuando cambie `UpdateSCN`.*
