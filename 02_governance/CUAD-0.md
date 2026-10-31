# CUAD-0 — Capítulo `Households` del método: estado en v8.14.0 y propuesta de Cuadratura 8.15

**Fecha:** 2026-10-30 · **Sesión:** v8.15a (memo; ningún `.do`/`.ado`/número publicado cambia) · **Base:** `master` `ee410a3` (v8.14.0) · **Estado:** para firma de Ricardo; es el insumo de 8.15b.

**Plantilla.** El adjunto `plantilla-capitulo.md` no llegó a la sesión. Los §2, §4, §5, §8, §9 y §10 usan el número y el contenido que pide el encargo. **Los títulos de §1, §3, §6 y §7 son inferidos** y se alinean cuando la plantilla entre al repo.

**Convención.** Miles de millones de MXN corrientes de 2024 («bn»), 2024, PIB = 33,667.023 bn (`escalar mxn PIB`, BIE 724025). «Crudo» = Σ x·factor antes de Altimir. Sellos:

| Sello | Origen |
|---|---|
| `H l.N` / `N l.N` / `S l.N` | `01_modulos/Households.do`, `01_modulos/NTA.do`, `SCN.ado` |
| `I` | `05_scripts/fixtures/nta-identidad.txt` |
| `C1 §x` | `02_governance/conc-1-scn-sankey-2026-10-30.md` (#47) |
| `(no en repo)` | La cifra no está versionada. Se lee de la corrida canónica; la fuente sigue al sello: `T` = `diag-v8.15a-2026-10-30/tabla1.out`, `CSI f.N` = tabulado INEGI en `-datos/raw/temp/SCN/`, `L` = `diag-v8.14.0-2026-10-30/02-ritual/wrap.log` |

Ninguna cifra es estimada. Los factores propuestos son cocientes de las cifras de la misma fila.

## Resumen

1. **El factor Altimir de 6.15 no mide subregistro.** `ing_mixto` crudo es 1,222.541 bn y 742.684 de ellos (61 %) son transferencias y flujos financieros: con el factor pesan 4,570.687 bn.
2. **Depurar solo eso empeora el factor: 6.15 → 14.50.** El ingreso de cuenta propia que queda es 479.858 bn. Lo que evita el salto es que los negocios (`ing_t2_cap1`, `ing_t2_cap8`: 1,019.131 bn crudos), que hoy se anclan a sociedades, pasen a B.3n: el factor queda en **5.05**. A cambio, D.4 se concentra (10.55). Es la decisión central (§4).
3. **Hallazgos que el encargo no listaba** y que violan el principio C: el alquiler imputado está dentro de la base de `ing_capital` (352.038 crudos); `ing_t4_cap3PM` es **negativo** (−160.094: la partición de l. 466–467 vale 2.45); las remesas crudas se escalan dos veces (× 6.15 en `ing_t4_cap9` y × 8.38 en `ing_remesas`); D.1 de S.14 **ya incluye** las remuneraciones del exterior (52.721), de modo que `ing_suborROW` duplicaría.
4. **La consecuencia de 8.15b es un cambio de signo:** con YL = D.1 + ⅔ B.3n, Σ S sin ancla pasa de 1,634.8 (−14.0 %) a 2,722.1 (+43.2 % sobre B.8n) y la regla `auto` apaga el ancla. La brecha se descompone al peso (Δ esperado); 605.9 bn son D.614. Corregir ese circuito la deja en +11.3 %, dentro de la regla.
5. **Yl + Yk + OyE deja de sumar el PIB** (hoy 33,667.023 exacto). El Sankey fiscal necesita que la Tabla 2 entre, no solo la Tabla 1.

---

## §1 Propósito y alcance (título inferido)

`Households.do` arma la base por persona: lee la ENIGH, clasifica el ingreso según la LISR, estima cuotas e ISR, escala cada ingreso a cuentas nacionales (Altimir, §9 del `.do`) y deja `Yl`, `Yk` y el consumo que leen `SankeySF`, `NTA.do` y el resto del motor. Este capítulo describe el estado en v8.14.0 y, en columna aparte, lo propuesto para 8.15.

Dos principios ordenan la propuesta. **C:** una celda del SCN por variable ENIGH. **B:** toda partida de sector tiene regla explícita para llegar a personas.

## §2 Entradas

| Entrada | Vintage | Identificación | Sello |
|---|---|---|---|
| ENIGH 2024 (INEGI), `ingresos.dta` y resto | 2024; `anioenigh` | Asset `2024.zip`, sha256 `407dd6df…`. Llave única del `sort`: `folioviv foliohog numren id_trabajo clave` (`H l.560`), colapsada a `folioviv foliohog numren id_trabajo`. Factor: `factor`, Σ = 130,325,969 personas; 308,598 registros | `05_scripts/manifest.json`; `H l.557–562`; `I` |
| CSI, cuentas por sector institucional (INEGI, base 2018, serie 2003–2024, «2024 revisada»): `CSI_103/106/109/112/115/118/121` = S.1, S.11, S.12, S.13, S.14, S.15, S.2 | Tabulados del 16-oct-2026 en `-datos` (fecha de archivo; la consulta no está registrada) | **No es asset del manifest:** vive en `raw/temp/SCN/` (ignorado por git) y se baja de `tabulados_CSI.zip` si falta. `CSI_115` sha256 `3b981612…`, `CSI_103` `c28d5607…` | `S l.2128–2133`; `C1` encabezado; (no en repo) sha |
| BIE (INEGI), series SCN | `master/SCN.dta` del 28-oct-2026, sha256 `3bdc3a02…`; etiqueta preliminar/revisada **no registrada** | Lectura vía `AccesoBIE`; sin asset congelado. PIB 33,667.023 vs B.1b CSI 33,582.899: los dos vintages no cuadran (84.901 en NNI) | `C1 §1.2`; (no en repo) sha |
| CONAPO, población a mitad de año (pry23, vía DGIS) | Conciliación 1970–2019 y proyecciones 2020–2070 | Asset `Poblacion_Estimada_Mitad_Anio.zip`, sha256 `e77873cd…` | `manifest.json`; `Poblacion.ado` l. 644–678 |
| LIF / PEF | Paquete Económico vigente del motor | OyE 1,601.824 de la LIF 2024; τ⁺ de PEF | `C1 §1.2` línea 17 |

**Brecha frente a §4 bis:** de las cuatro fuentes, CSI y BIE no están congeladas con sha ni vintage en el manifest. Es lo primero que cierra 8.15b.

## §3 Transformación actual (título inferido)

| Paso | Qué hace | Dónde |
|---|---|---|
| 1 | Clasifica por clave ENIGH en `ing_t2_cap*` y `ing_t4_cap*` según la LISR | `H l.378–550` |
| 2 | Parte `cap2` y `cap3` entre persona física y moral con shares del SCN | `H l.456–457`, `l.466–467` |
| 3 | Suma `ing_mixto` (⅔ L, ⅓ K) e `ing_capital` | `H l.1056–1080` |
| 4 | Recupera el ingreso bruto (`ing_subor`), cuotas e ISR | `H l.1699–1745` |
| 5 | Calcula cinco factores Altimir (`Taltimir*`) y escala | `H l.2085–2122` |
| 6 | Reparte macro: CCF ∝ `ing_capital`, ROW ∝ `ing_capital` / `ing_subor`, impuestos embebidos | `H l.2306`, `l.2415–2443` |
| 7 | `Yl` = `ing_subor` + `ing_mixtoL`; `Yk` = `ing_capital` + `ing_mixtoK` + `ing_estim_alqu` + CCF | `H l.2664–2670` |

## §4 Decisiones: cada cambio de 8.15 como parámetro

«Default» es lo que propone este memo para 8.15b; `actual` reproduce v8.14.0 byte a byte. Todo valor distinto de `actual` lleva FLAG en el header del módulo y en `nta-identidad.txt`.

| Parámetro | Valores (default en negritas) | FLAG | Qué cambia si se mueve |
|---|---|---|---|
| `pensiones_en_yl` | `on` (actual) · **`off`** | «pensiones fuera de Yl: D.62» | Saca 751.330 de `Yl` y de `ing_subor`; D.1 deja de cargar con D.62. |
| `ing_mixto_depurado` | `off` (actual) · `transf` · **`transf_negocios`** | «base de B.3n = …» | `transf`: quita 742.684 crudos y sube el factor a 14.50. `transf_negocios`: además mueve negocios a B.3n; factor 5.05 y `ing_capital` pierde 1,019.131 crudos. |
| `yk_ancla` | `actual` · **`b2n_b3n_d4`** | «Yk = B.2n + ⅓ B.3n + D.4 neto de S.14» | `Yk` neto de CCF pasa de 10,478.495 a 8,832.323; el factor 1.1938 de `NTA.do` queda en 1. |
| `cap4` | `mixto` (actual) · **`fuera`** | «enajenaciones fuera de la cuenta corriente» | 95.936 crudos salen de `ing_mixto` (hoy 590.4 × 6.15); siguen en la base del ISR. |

**Añadidos por este memo** (no estaban en el encargo; salen de la Tabla 1):

| Parámetro | Valores | Qué cambia si se mueve |
|---|---|---|
| `cap3_particion` | `actual` · **`acotada`** (share en [0,1]) | `cap3PM` deja de ser −160.094. Con el default: B.3n 5.05 → 5.71, D.4 10.55 → 8.11. |
| `alq_en_capital` | `on` (actual) · **`off`** | Saca 352.038 crudos de la base de `ing_capital`: hoy ese alquiler pesa 1,283.4 bn anclado a sociedades, además de ir en `ing_estim_alqu`. |
| `suborrow` | `on` (actual) · **`off`** con ancla D.1 de S.14 | Evita duplicar 52.721. |
| `oye_en_hub` | **`on`** (actual) · `off` | D2 de `C1 §4.4`. Con `off` el hub baja 1,601.824. Ricardo decide; el default no cambia. |
| `cuotas_d614` | `actual` · **`neto`** | Cierra 605.9 bn de la brecha de S (Δ esperado). Sin esto, el ancla de S cae a `off` por la regla `auto`. |

### §4 bis — Política de fuente SCN (firmada por Ricardo, 2026-10-30)

- **Canal:** BIE por API.
- **Congelamiento:** cada descarga queda en `raw/` como asset del manifest, con sha256 y vintage (fecha de consulta + etiqueta INEGI preliminar/revisada) en el header del módulo y en `manifest.json`.
- **Refresco deliberado:** nunca hay lectura en caliente. Un cambio de INEGI entra solo por PR de datos.

**Spec de `05_scripts/refrescar-scn.sh` (se implementa en 8.15b):**

```text
Uso: 05_scripts/refrescar-scn.sh --comparar [--series <lista>]
1. Lee de manifest.json los assets SCN congelados (sha256, fecha de consulta, etiqueta).
2. Descarga las mismas series del BIE por API a un directorio temporal, sin tocar raw/.
3. Compara serie a serie contra el asset congelado, con tolerancia cero sobre el valor publicado.
4. Sin diferencias: imprime «sin revisión INEGI» y sale con 0.
5. Con diferencias: imprime tabla serie/año/congelado/BIE/Δ y Δ % del PIB.
6. Si INEGI revisó: escribe el asset nuevo y su sha256 en una rama de datos.
7. Abre PR de datos que mueve data_updated y declara el Δ en el CHANGELOG.
8. Nunca se invoca desde el motor; SIM.do y los .ado solo leen assets congelados.
9. Salida distinta de 0 si el BIE no responde: «no comparado» nunca equivale a «sin revisión».
```

### §4 ter — Campo `baseline`

`manifest-datos.json` y `manifest.json` ganan `baseline: "<tag desde el que los números son comparables>"`. El CHANGELOG lleva la línea «a partir de vX los números no comparan con ≤vY por…». Se llena por primera vez en 8.15b. **Gate propuesto:** `publicar.sh --check` exige `baseline` desde v8.15.0.

---

## §5 Anclas

### Tabla 1 — Principio C: una celda SCN por variable ENIGH

⚠ = viola C hoy. La columna «propuesto» corresponde a los defaults de §4 con `cap3_particion=actual`, salvo nota.

| Variable (`H`) | Celda SCN propuesta | Valor SCN | Σ ENIGH: crudo → post-Altimir | Factor actual (ancla actual) | Factor propuesto | Sello |
|---|---|---:|---|---|---:|---|
| `ing_subor` sin pensiones, l. 443, 1699–1736 | D.1 S.14 | 10,052.962 | 9,571.430 → (incluida abajo) | 0.9781 | **1.0503** | `C1 §1.2`; (no en repo) T |
| ⚠ `ing_subor` total | RemSalSS BIE + D.29 embebido | 10,013.434 + 99.782 | 10,339.577 → 10,113.216 | 0.9781 | se parte en la fila de arriba y la de abajo | `H l.2092`; `C1 §1.2` |
| ⚠ `ing_jubila`, l. 440 | D.6211 + D.6221 S.14 | 1,390.052 | 768.147 → 751.330 | 0.9781 (ancla de salarios) | **1.8096** | `C1 §1.2` l. 14; (no en repo) CSI f.133, f.136 |
| `ing_PAM`, l. 543–546 | D.623 S.14 (72.268 < ENIGH: no sirve como ancla) | 72.268 | 359.084 → sin Altimir | ninguno (PEF 468.390 en NTA) | conserva PEF, con FLAG | (no en repo) T, CSI f.138; `nta-grupoedad.json` |
| ⚠ `ing_mixto` agregado, l. 1056 | B.3n S.14 + impuestos embebidos | 6,956.984 + 566.885 | 1,222.541 → 7,523.869 | **6.1543** | deja de ser agregado único | `H l.2094`; `C1 §1.2` l. 13 |
| `ing_t4_cap2pf`, l. 456 | B.3n S.14 | 6,956.984 | 88.744 → 546.157 | 6.1543 | **5.0460** | (no en repo) T |
| ⚠ `ing_t4_cap3pf`, l. 466 (share 2.4455 > 1) | B.3n S.14 | 6,956.984 | 270.847 → 1,666.870 | 6.1543 | **5.0460** | (no en repo) T |
| ⚠ `ing_t2_cap1` (P068–70, P075–77), l. 381 | B.3n S.14 | 6,956.984 | 900.869 → 3,284.359 | 3.6458 (ExNOpSoc) | **5.0460** | (no en repo) T |
| ⚠ `ing_t2_cap8` (P071–74, P078–81), l. 393 | B.3n S.14 | 6,956.984 | 118.262 → 431.155 | 3.6458 (ExNOpSoc) | **5.0460** | (no en repo) T |
| ⚠ `ing_t4_cap4`, l. 481 | Sin celda: ganancia de capital, fuera de la cuenta corriente | — | 95.936 → 93.835 como variable; 590.4 dentro de `ing_mixto` | **dos:** 0.9781 (variable, l. 2113) y 6.1543 (agregado) | **1**, fuera de Yl/Yk | `H l.1056, l.2113`; (no en repo) T |
| ⚠ `ing_t4_cap5` donativos, l. 489 | D.75 entre hogares (neto cero en S.14) | — | 260.194 → 1,601.311 | 6.1543 | **1** | `C1 §1.2` l. 15; (no en repo) T |
| ⚠ `ing_t4_cap6` intereses, l. 494–497 | D.41 recibida S.14 (dentro del grupo D.4) | 544.940 | 19.335 → 118.991 | 6.1543 | **10.5515** en grupo; 28.18 por celda | `C1 §1.2` l. 9; (no en repo) T |
| ⚠ `ing_t4_cap7` lotería, l. 502 | D.75 | — | 1.320 → 8.126 | 6.1543 | **1** | (no en repo) T |
| ⚠ `ing_t4_cap8` acciones, l. 510 | D.42 recibida S.14 (dentro del grupo D.4) | 4,779.531 | 2.368 → 14.576 | 6.1543 | **10.5515** en grupo; 2,018 por celda | `C1 §1.2` l. 9; (no en repo) T |
| ⚠ Remesas crudas en `ing_t4_cap9` e `ing_remesas`, l. 521 | D.752 recibida S.14 (BdP) | 1,188.474 | 141.526 → 871.0 en cap9; 1,186.091 en `ing_remesas` | **dos:** 6.1543 y 8.3807 (ROWTrans BIE 1,186.091) | **8.3976**, una sola vez | `C1 §1.2` l. 15, 20; (no en repo) T |
| ⚠ `ing_prest` + `ing_otrocap` + `ing_ahorro`, l. 527–533 | Sin celda: cuenta financiera (F.*) | — | 272.497 → 1,677.0 | 6.1543 | **1**, fuera de Yl/Yk | `C1 §2.3`; (no en repo) T |
| ⚠ `ing_benef` + `ing_heren`, l. 536–539 | Sin celda corriente de ingreso | — | 68.466 → 421.4 | 6.1543 | **1**, fuera de Yl/Yk | (no en repo) T |
| `ing_autor` + `ing_trabmenor`, l. 518–524 | Inmaterial: sin ancla | — | 1.308 → 8.0 | 6.1543 | **1**, memo | (no en repo) T |
| ⚠ `ing_capital` agregado, l. 1080 | D.4 neto S.14 | 5,602.969 | 1,880.477 → 6,855.782 | **3.6458** (ExNOpSoc 6,906.856 + impuestos 1,550.750 − OyE 1,601.824) | ver filas siguientes | `H l.2098`; `C1 §1.3`; (no en repo) T |
| `ing_t4_cap2PM`, l. 457 | D.4 neto S.14 | 5,602.969 | 669.401 → 2,440.482 | 3.6458 | **10.5515** | (no en repo) T |
| ⚠ `ing_t4_cap3PM`, l. 467 (**negativo**) | D.4 neto S.14 | 5,602.969 | −160.094 → −583.664 | 3.6458 | **10.5515**; con `acotada`, sale | (no en repo) T |
| ⚠ `ing_estim_alqu`, l. 361 | B.2n S.14 | 910.359 | 352.038 → 1,114.756; **además** 1,283.4 dentro de `ing_capital` | 3.1666 (ExNOpHog + impuestos) y 3.6458 | **2.5860**, una sola vez | `H l.2103, l.1080`; `I`; (no en repo) T |
| ⚠ `ing_suborROW`, l. 2443 | Ya dentro de D.1 S.14 | 52.721 | ∝ `ing_subor` → 52.721 | macro | **se retira** | `H l.2443`; (no en repo) CSI_103 f.35, CSI_121 f.71 |
| ⚠ `ing_capitalROW`, l. 2441 | Ya dentro de D.4 neto S.14 | −989.221 | ∝ `ing_capital` → −989.221 | macro | **se retira** | `H l.2441`; `C1 §3` #1 |
| ⚠ `gasto_anualDepreciacion`, l. 2306 | P.51c S.14 (el resto, en Tabla 2) | 1,721.094 | ∝ `ing_capital` → 6,457.576 | macro total | **macro de S.14** | `C1 §3` #6 |
| `ing_Sector_Publico` (OyE), l. 2071–2081 | Sin celda en S.14: LIF | 1,601.824 | sin ENIGH → 1,601.824 per cápita | 1 | decide `oye_en_hub` | `C1 §1.2` l. 17 |

**Violaciones actuales de C, en una línea cada una:**

- **`ing_mixto`:** transferencias y flujos financieros dentro: 742.684 crudos × `TaltimirSelf` 6.1543 = **4,570.687 bn**.
- **Pensiones dentro de `Yl`:** `ing_jubila` entra a `ing_t4_cap1` (l. 443) y llega a `Yl` por `ing_subor`: 751.330 bn. `NTA.do` l. 355, 362 las saca después; el motor fiscal no.
- **`Yk`:** anclado a ExNOpSoc (residuo BIE) + ExNOpHog + ⅓ B.3n + impuestos − OyE. Neto de CCF son 10,478.495 bn contra B.2n + ⅓ B.3n + D.4 neto = 8,832.323. `NTA.do` lo corrige después con el factor 1.1938, sobre un `YA_motor` de 7,398.609 (`I`).
- **`*_t4_cap4`:** la variable se escala con `TaltimirSal` (l. 2113) pero entra a `ing_mixto`, que se escala con `TaltimirSelf`. Tras Altimir, los componentes ya no suman el agregado.

**Dos correcciones a CONC-1** que salen de esta tabla:

1. La línea 11 de `C1 §1.2` llama «vintage» a RemSalSS BIE − D.1 S.14 = −39.528. No lo es del todo: D.1 S.14 (10,052.962) = D.1 pagado en la economía interna (10,000.241) + exterior (52.721). El vintage es +13.193 y el resto es ROW. La línea 16 suma esos 52.721 aparte, así que un YL anclado a D.1 no debe conservar `ing_suborROW`.
2. Las cifras de `C1` son de v8.13.0. En v8.14.0: YL 13,603.690 (era 13,935.397) y hub 28,863.765 = 85.733 % (era 86.718 %).

**Riesgo de los factores propuestos.** 10.55 sobre D.4 reparte renta de la propiedad en proporción a honorarios atribuidos a personas morales: **el factor cierra el total, no valida la distribución**. Alternativa sin mover negocios: B.3n 14.50 y D.4 3.61. Las claves P068–P081 se clasificaron por el rótulo LISR del código; **no verifiqué el catálogo ENIGH** (el descriptor es PDF), y de eso depende que `transf_negocios` sea correcto.

### Tabla 2 — Principio B: toda partida de sector tiene regla a persona

Regla: **P** = propiedad · **I** = incidencia · **C** = per cápita. Los valores CSI son de `C1 §1–§3` salvo sello.

| Sector | Partida | Valor | Regla | Cómo lo hace hoy el motor | Propuesto 8.15 | Sello |
|---|---|---:|---|---|---|---|
| S.11 + S.12 | Excedente de operación (B.2n; ExNOpSoc BIE) | 6,723.499 (BIE 6,906.856 con S.15) | P | Llega: `ing_capital` ∝ base mixta, anclado al residuo BIE | Solo llega lo distribuido (D.4, abajo) | `C1 §1.3`, `§3` #3 |
| S.11 + S.12 | D.42 a hogares | 4,779.531 | P | Indirecto, dentro de `ing_capital` y re-anclado en NTA | Dentro de D.4 neto | `C1 §1.2` l. 9 |
| S.11, S.12, S.13 | D.41 a hogares | 544.940 | P | Igual | Dentro de D.4 neto | `C1 §1.2` l. 9 |
| S.12 | D.44 a hogares (incluye D.442 605.932) | 735.471 | P | Igual; D.442 regresa como D.614 fuera de cuotas | Dentro de D.4 neto; circuito por `cuotas_d614` | `C1 §1.2` l. 4, 9 |
| S.12 | D.8 | 1,270.277 | I | `YA_d8` ∝ YL de cotizantes | Sin cambio | `I`; `N l.79` |
| S.11, S.12, S.15 | D.62 a hogares | 193.870 + 244.292 + 4.182 = 442.344 | I | Llega, atribuido al nodo Gobierno | Llega; origen correcto | `C1 §6.5` |
| S.12, S.11 | D.61 recibida | 1,455.102 + 193.870 | I | `Cuotas` por persona, todas a Gobierno | Por persona; destino por sector | `C1 §6.3` |
| S.11 + S.12 | D.5 (ISR de sociedades) | 1,188.648 (LIF 1,801.570 con OTROSK) | P | Fiscal: ISR PM por persona. NTA: `TmenFuera`, informativo | Regla única P en los dos Sankeys | `C1 §3` #5; `I` |
| S.11 + S.12 | Impuestos a productos y producción embebidos | 1,550.750 | I | Por Altimir en `ing_capital` | Fuera de factores; ImpProd explícito ∝ Cpriv | (no en repo) T |
| S.11, S.12 | CCF | 4,634.128 + 62.735 | P | Llega: ∝ `ing_capital`, dentro de los 6,457.576 | No llega como ingreso; memo por sector | `C1 §3` #6 |
| **S.11** | **Excedente retenido (B.5n)** | **−1,116.929** (B.8n −2,903.413) | P | **No llega** | P ∝ D.42 recibido, como memo: no entra a YA hasta decidir D1 de `C1 §4.4` | `C1 §1.2` l. 3 |
| **S.12** | **Excedente retenido (B.5n)** | **+2,070.833** (B.8n +1,789.804) | P | **No llega** | Igual | `C1 §1.2` l. 4 |
| S.13 | D.21 − D.31 | 2,175.907 | I | `ImpProd` ∝ Cpriv (τ⁻ indirectos 2,192.943) | Sin cambio | `I` |
| S.13 | D.29 − D.39 | 255.114 | I | Parcial: 247 bn embebidos en `Yl`/`Yk` | Fuera de factores; I ∝ base gravable | `N l.369`; `C1 §1.2` l. 6 |
| S.13 | D.62 + D.759 a hogares | 3,010.029 (`TpubEf` 3,445.143) | I | Llega; factor 1.7170 sobre PEF/ENIGH | Sin cambio de regla; se separa lo privado | `I`; `C1 §2.3` |
| S.13 | D.63 educación y salud | 1,054.587 + 948.537 | I | Llega por uso | Sin cambio; se ajusta al quitar ISFLSH | `I`; `nta-grupoedad.json` |
| S.13 | D.63 resto | 396.044 | C | Llega per cápita | Sin cambio; incluye la mezcla con ISFLSH | `I` |
| **S.13** | **Consumo colectivo P.32** | **1,896.999** (motor 1,517.160) | C | **Sí llega en la cuenta** per cápita (`TpubCol`) por 1,517.160; sin edad solo en el gráfico. Faltan 379.839 | C sobre P.32 completo | `I`; `C1 §6.4` |
| S.13 | D.41 pagado (intereses de la deuda) | 1,205.483 | C | **No llega** como gasto; lo recibido por hogares va en D.41 | C como renta pública de activos, memo | `C1 §3` #9 |
| S.13 | D.45 (FMP y renta petrolera) / OyE | 224.114 / 1,601.824 | C | OyE per cápita, duplica frente al SCN | `oye_en_hub`; sin doble conteo | `C1 §1.2` l. 17 |
| S.13 | B.8n / B.9 | −1,157.268 / −2,156.464 | C | **No llega**; `Déficit público` 506.776 es balance de nodo | C como financiamiento futuro; decide D8 de `C1 §4.4` | `C1 §2.3–2.4` |
| S.15 | D.63 | 388.320 | I | Llega, dentro de la especie de Gobierno | Regla I con origen S.15 | `C1 §6.4` |
| S.15 | B.2n (dentro de ExNOpSoc) | 102.442 | P | Llega dentro de `ing_capital` | No llega como renta; memo | `C1 §1.3` |
| S.15 | D.751 recibida (de hogares 274.349) | 340.736 | I | `InterOtor` 88.773, no cierra | Se declara la brecha | `C1 §3` #8; `I` |
| S.15 | B.8n | 61.425 | P | **No llega** | Memo, con D7 de `C1 §4.4` | `C1 §2.2` |
| S.2 | D.752 a hogares | 1,188.474 (BIE neto 1,186.091) | P | ∝ `ing_remesas` crudo, también dentro de cap9 | Una sola vez | `C1 §1.2` l. 20 |
| S.2 | D.1 | 52.721 | P | ∝ `ing_subor`, aparte de D.1 | Dentro de D.1 S.14 | Tabla 1 |
| S.2 | D.4 neta | −989.221 | P | ∝ `ing_capital`; el re-anclaje lo diluye | Dentro de D.4 neto S.14 | `C1 §3` #1 |
| S.2 | Compras netas de no residentes | −372.715 | I | ∝ `gastoanualTOT` dentro de Cpriv | Sin cambio | `I` |
| S.2 | B.9 | 251.842 | — | **No llega** | Memo, con D8 de `C1 §4.4` | `C1 §2.2` |

**Sobre el encargo:** pedía el consumo colectivo de S.13 entre lo que no llega a personas. En la cuenta NTA **sí llega** per cápita, por 1,517.160 (τ⁺ col en `I`). El defecto es otro: faltan 379.839 frente a P.32. Lo que de verdad no llega de S.13 son los intereses y su déficit.

---

## §6 Salidas (título inferido)

`master/<año>/households.dta` (por persona; `Yl`, `Yk`, `ing_*`, impuestos, consumo), los escalares `pctpib` de los pasos 0–4 en el log, y por `NTA.do`: `users/<id>/NTA/*` y `SankeyNTA/*`. Las salidas publicadas son `output.txt` y los 10 sankeys que vigila `05_scripts/gate-numeros.sh`.

## §7 Verificaciones (título inferido)

| Verificación | Resultado en v8.14.0 | Evidencia |
|---|---|---|
| `gate-numeros.sh` | VERDE: `output.txt` byte-idéntico, 10 sankeys | `diag-v8.15a-2026-10-30/gate-numeros.txt` |
| Yl + Yk + OyE = PIB | 15,129.128 + 16,936.071 + 1,601.824 = 33,667.023 | (no en repo) T |
| Residual por persona en NTA | máx 7.45e-09 MXN | `I` |
| Σ S = B.8n | 0.00 MXN (con ancla) | `I` |
| Puente INBD → hub | 0.33 MXN sobre el vintage v8.13.0 | `C1 §1.2` |
| Componentes crudos de `ing_mixto` = agregado | 1,222.541, cierra | (no en repo) T |

## §8 Límites conocidos

La versión de cierre es **propuesta** de este memo.

| # | FLAG abierto | Magnitud (bn) | Cierre propuesto |
|---|---|---:|---|
| 1 | Transferencias y flujos financieros en `ing_mixto` | 4,570.687 | 8.15b |
| 2 | Pensiones en `Yl` | 751.330 | 8.15b |
| 3 | `Yk` anclado fuera de S.14 | 10,478.495 vs 8,832.323 | 8.15b |
| 4 | `*_t4_cap4` con dos factores | 95.936 crudos | 8.15b |
| 5 | Partición de `cap3` con share 2.4455 y `cap3PM` negativo | −160.094 crudos | 8.15b |
| 6 | Alquiler imputado en la base de `ing_capital` | 352.038 crudos | 8.15b |
| 7 | Remesas escaladas dos veces | 141.526 crudos | 8.15b |
| 8 | Impuestos embebidos por Altimir en `Yl`/`Yk` | 247 de D.29 − D.39 | 8.15b |
| 9 | CSI y BIE sin asset congelado | toda ancla S.14 | 8.15b (§4 bis) |
| 10 | Vintage BIE vs CSI | 84.901 en NNI | 8.15b: se declara; una sola fuente, después |
| 11 | OyE duplica frente al SCN | 1,601.824 | Decisión de Ricardo |
| 12 | Circuito D.614 / D.442 | 605.932 | 8.15b, si se conserva el ancla de S |
| 13 | Cuotas todas a Gobierno | 1,045.130 | Con el Sankey de economía completa (posterior a 8.15b) |
| 14 | τ⁺ con D.62 privado en Gobierno | 442.344 | Ídem |
| 15 | D.63 de ISFLSH en Gobierno; colectivo corto | 388.320 / 379.839 | Ídem |
| 16 | Catálogo ENIGH de P068–P081 sin verificar contra el descriptor | 1,019.131 crudos | Antes de 8.15b |

## §9 Específico de México

- **ENIGH bienal:** el año de encuesta y el año fiscal rara vez coinciden; `anioenigh` los separa y las anclas se toman del año ENIGH.
- **CONAPO edad simple:** la población por edad simple sostiene perfiles y proyección a 2070.
- **CSI por sector:** INEGI publica S.11–S.15 y S.2, con un vintage distinto al del BIE.
- **Altimir:** la distancia ENIGH–SCN es grande (Yl + Yk crudos 33.36 % del PIB, `L`) y se escala por tipo de ingreso.
- **Informalidad por cotización:** se estima por probit con seguridad social; 89,518 personas con cuotas > 0 en la base (`L`).

**Pendiente:** estos renglones se comparan con `cap0-requerimientos.md` cuando el adjunto entre al repo; hoy no pude revisar si falta alguno.

## §10 Procedencia

| Sección | Archivo y líneas |
|---|---|
| §2 | `05_scripts/manifest.json` (assets); `01_modulos/Households.do` l. 114–134, 557–562; `SCN.ado` l. 60–79, 2128–2133; `Poblacion.ado` l. 644–678 |
| §3 | `Households.do` l. 356–393, 440–550, 1056–1080, 1699–1745, 2085–2122, 2306, 2415–2443, 2664–2670 |
| §4 | `Households.do` l. 443, 1056, 2113–2121; `NTA.do` l. 339–362, 386–387, 565; `C1 §4.4`, `§6.1` |
| §5 Tabla 1 | `Households.do` l. citadas en cada fila; `05_scripts/fixtures/nta-identidad.txt`; `C1 §1.2–§1.3`; `diag-v8.15a-2026-10-30/tabla1.py`, `tabla1.out`; CSI_115 f.69–71, 95–105, 133, 136, 138, 150; CSI_103 f.35; CSI_121 f.71 |
| §5 Tabla 2 | `C1 §1.2`, `§2.2–§2.4`, `§3`, `§6`; `nta-identidad.txt`; `NTA.do` l. 79, 369 |
| §7 | `05_scripts/gate-numeros.sh`; `diag-v8.15a-2026-10-30/gate-numeros.txt` |
| §9 | `Households.do`; `diag-v8.14.0-2026-10-30/02-ritual/wrap.log` l. 586–600, 1529–1537 |
| Δ esperado | Aritmética de Tabla 1, `nta-identidad.txt` y CSI_115 f.114–171 |

---

## Δ esperado de 8.15b

Con los defaults de §4 y `oye_en_hub=on`. Nada se corrió: es aritmética de las tablas.

| Agregado publicado | v8.14.0 | 8.15b | Dirección |
|---|---:|---:|---|
| `Yl` del motor | 15,129.128 | 14,690.951 (D.1 + ⅔ B.3n) | ↓ −438.177 |
| YL de NTA | 13,603.690 | 14,690.951 | ↑ +1,087.261 |
| `Yk` del motor (con CCF 6,457.576) | 16,936.071 | 15,289.899 | ↓ −1,646.172 |
| YA base de NTA | 8,832.323 | 8,832.323; factor 1.1938 → 1 | = |
| Hub `Ing nacional` | 28,863.765 (85.73 %) | 29,951.026 (88.96 %) | ↑ +1,087.261 |
| Hub con `oye_en_hub=off` | — | 28,349.202 (84.20 %) | ↓ −514.563 |
| Σ S sin ancla | 1,634.816 | 2,722.077 | ↑ +1,087.261 |
| Brecha vs B.8n (1,901.026) | −14.0 % | **+43.2 %**; `auto` → `off` | cambia de signo |
| Ídem con `cuotas_d614=neto` | — | 2,116.145: +11.3 %; ancla viva | |
| Yl + Yk + OyE vs PIB | 33,667.023 = PIB | 31,582.674: faltan 2,084.349 (6.2 %) | deja de cerrar |

**De dónde sale la brecha de 821.051** (S 2,722.077 − B.8n 1,901.026), con B.5n igual en los dos lados:

| Partida | NTA vs S.14 | Efecto en S |
|---|---|---:|
| D.61: cuotas sin D.614, con D.442 en YA | 1,729.089 vs 2,335.022 | +605.933 |
| τ netas: efectivo + remesas + inter-hogar vs D.62 + D.7 netas | 4,824.887 vs 4,363.876 | +461.011 |
| D.5: ISR LIF vs SCN | 1,330.838 vs 1,540.050 | +209.212 |
| Consumo: Cpriv (GastPrivT) vs P.3 | 23,819.398 vs 23,381.329 | −438.069 |
| ImpProd vs τ⁻ indirectos | 2,175.907 vs 2,192.943 | −17.036 |
| **Total** | | **+821.051** |

Las distribuciones por decil, edad y entidad también se mueven, pero su tamaño no se infiere de estas tablas. A partir de 8.15b los números **no comparan** con ≤ v8.14.0: es el primer uso de `baseline` (§4 ter).
