# CUAD-0 — Capítulo `Households` del método: estado en v8.14.0 y propuesta de Cuadratura 8.15

**Fecha:** 2026-10-30 · **Sesión:** v8.15a (memo; ningún `.do`/`.ado`/número publicado cambia) · **Base:** `master` `ee410a3` (v8.14.0) · **Estado:** **firmado** por Ricardo el 2026-10-31 (`02_governance/CUAD-0-firma.md`, que manda donde difiera) e **implementado en la sesión v8.15b** (rama `sesion/v8.15b`; §4 lleva los valores firmados, §5 la columna «factor obtenido 8.15b», §7 los gates nuevos, §8 los FLAGs cerrados y §10 la verificación contra el manual). El paso 0 de v8.15b (firma v3 §D: «verifica al peso, no decide la celda») encontró B.2b S.14 = 2,107.569 > alquiler imputado CSVM 2024 = 1,886.385 (+221.184): FLAG 18 **de contenido** (§8, §10 bis), no de vintage ni de lectura; la celda de las rentas efectivas sigue en **B.3n** (`rentas_celda = b3n`; `b2n` es el otro escenario, medido y declarado).

## Encabezado

| Campo | Valor |
|---|---|
| `modulo` | `Households` |
| `archivo` | `01_modulos/Households.do` @ `ee410a3` |
| `orden_en_SIM` | Segundo módulo `.do`, después de `Expenditure` (`SIM.do` l. 134, l. 138) |
| `desde_version` | v8.14.0 (último cambio del archivo: `e6d8b21`) |
| `ultima_decision` | 2026-10-30 (§4 bis y este memo) |
| `sello` | **rojo**: hereda el peor de sus entradas y anclas (§2, §5) |

Escrito en `metodo/plantilla-capitulo.md`. Añade tres cosas que pide el encargo y la plantilla no trae: este resumen, §4 bis y §4 ter, y el Δ esperado al final. La Tabla 1 añade «factor propuesto» y la columna «Fuente».

**Convención.** Miles de millones de MXN corrientes de 2024 («bn»), 2024, PIB = 33,667.023 bn (`escalar mxn PIB`, BIE 724025). «Crudo» = Σ x·factor antes de Altimir. **Principio C:** una celda del SCN por variable ENIGH. **Principio B:** toda partida de sector tiene regla explícita para llegar a personas.

**Sello** (de la plantilla): verde = oficial y estable; amarillo = oficial con vintage ambiguo; rojo = reconstruida o imputada. En §5 se aplica mecánicamente: celda SCN identificada → amarillo, porque hoy todo el SCN del motor tiene el vintage BIE vs CSI sin resolver; sin celda, o con una base que no corresponde a la celda → rojo. Por eso ningún ancla es verde todavía.

**Fuente** (de dónde sale cada cifra):

| Marca | Origen |
|---|---|
| `H l.N` / `N l.N` / `S l.N` | `01_modulos/Households.do`, `01_modulos/NTA.do`, `SCN.ado` |
| `I` | `05_scripts/fixtures/nta-identidad.txt` |
| `C1 §x` | `02_governance/conc-1-scn-sankey-2026-10-30.md` (#47) |
| `(no en repo)` | La cifra no está versionada. Se lee de la corrida canónica; el origen sigue a la marca: `T` = `diag-v8.15a-2026-10-30/tabla1.out`, `CSI f.N` = tabulado INEGI en `-datos/raw/temp/SCN/`, `L` = `diag-v8.14.0-2026-10-30/02-ritual/wrap.log` |

Ninguna cifra es estimada. Los factores propuestos son cocientes de las cifras de la misma fila.

## Resumen

1. **El factor Altimir de 6.15 no mide subregistro.** `ing_mixto` crudo es 1,222.541 bn y 742.684 de ellos (61 %) son transferencias y flujos financieros: con el factor pesan 4,570.687 bn.
2. **Depurar solo eso empeora el factor: 6.15 → 14.50.** El ingreso de cuenta propia que queda es 479.858 bn. Lo que evita el salto es que los negocios (`ing_t2_cap1`, `ing_t2_cap8`: 1,019.131 bn crudos), que hoy se anclan a sociedades, pasen a B.3n: el factor queda en **5.05**. A cambio, D.4 se concentra (10.55). Es la decisión central (§4).
3. **Hallazgos que el encargo no listaba** y que violan el principio C: el alquiler imputado está dentro de la base de `ing_capital` (352.038 crudos); `ing_t4_cap3PM` es **negativo** (−160.094: la partición de l. 466–467 vale 2.45); las remesas crudas se escalan dos veces (× 6.15 en `ing_t4_cap9` y × 8.38 en `ing_remesas`); D.1 de S.14 **ya incluye** las remuneraciones del exterior (52.721), de modo que `ing_suborROW` duplicaría.
4. **La consecuencia de 8.15b es un cambio de signo:** con YL = D.1 + ⅔ B.3n, Σ S sin ancla pasa de 1,634.8 (−14.0 %) a 2,722.1 (+43.2 % sobre B.8n) y la regla `auto` apaga el ancla. La brecha se descompone al peso (Δ esperado); 605.9 bn son D.614. Corregir ese circuito la deja en +11.3 %, dentro de la regla.
5. **Yl + Yk + OyE deja de sumar el PIB** (hoy 33,667.023 exacto). El Sankey fiscal necesita que la Tabla 2 entre, no solo la Tabla 1.

---

## §1 Propósito

Construye el ingreso y las variables fiscales por persona y fuente a partir de la ENIGH, escalados a cuentas nacionales por tipo de ingreso (en 8.15, celda por celda al SCN del sector hogares), para que todos los módulos posteriores repartan sobre la misma base.

## §2 Entradas

| Base | Fuente / institución | Vintage usado | Variables clave | Llave única | Sello | Fuente de la fila |
|---|---|---|---|---|---|---|
| ENIGH 2024, `ingresos.dta` y resto | INEGI | 2024 (`enigh_vintage` del manifest; asset `2024.zip`, sha256 `407dd6df…`) | `clave`, `ing_anual`, `factor` (Σ = 130,325,969 personas; 308,598 registros) | `folioviv foliohog numren id_trabajo clave`; colapsa a `folioviv foliohog numren id_trabajo` | verde | `manifest.json`; `H l.557–562`; `I` |
| CSI `CSI_103/106/109/112/115/118/121` = S.1, S.11, S.12, S.13, S.14, S.15, S.2 | INEGI, base 2018, serie 2003–2024, «2024 revisada» | **El motor no lo registra.** Archivos del 16-oct-2026 en `-datos`; `CSI_115` sha256 `3b981612…`, `CSI_103` `c28d5607…`. No es asset: vive en `raw/temp/SCN/` | Filas de `C1 §1.2` | cuadro + fila + columna (AR U/A, AS R/P) | **amarillo** | `S l.2128–2133`; `C1` encabezado; (no en repo) sha |
| BIE, series SCN (`master/SCN.dta`) | INEGI, vía `AccesoBIE` | **El motor no lo registra.** Archivo del 28-oct-2026, sha256 `3bdc3a02…`; sin etiqueta preliminar/revisada. PIB 33,667.023 vs B.1b CSI 33,582.899 (84.901 en NNI) | `PIB`, `RemSalSS`, `ExNOp*`, `ROW*`, `CapFij` | `anio` | **amarillo** | `C1 §1.2`; (no en repo) sha |
| Población a mitad de año | CONAPO, conciliación 1970–2019 y proyecciones 2020–2070 (pry23, 11-sep-2023), redistribuida por DGIS | pry23; asset `Poblacion_Estimada_Mitad_Anio.zip`, sha256 `e77873cd…` | `poblacion` | `anio edad sexo entidad` | verde | `manifest.json`; `Poblacion.ado` l. 650–678 |
| LIF / PEF | SHCP, Paquete Económico | Vintage del motor | OyE 1,601.824 (LIF 2024); τ⁺ (PEF) | `anio` + división | verde | `C1 §1.2` línea 17, `§6.9` |

**Brecha frente a §4 bis y a la plantilla:** CSI y BIE no están congeladas ni registran vintage, y `manifest-datos.json` registra solo `enigh_vintage` y `data_updated`. Es lo primero que cierra 8.15b.

## §3 Procedimiento

Estado en v8.14.0.

| # | Qué hace | Qué conserva | Dónde está |
|---|---|---|---|
| 1 | Clasifica el ingreso de cada persona por concepto fiscal de la LISR | Ninguna (cada clave cae en un concepto; no hay gate de que caigan todas) | `H l.378–550` |
| 2 | Parte honorarios y rentas entre persona física y moral con shares del SCN | Física + moral = total, aunque la moral de rentas queda negativa | `H l.456–457`, `l.466–467` |
| 3 | Suma ingreso mixto (⅔ trabajo, ⅓ capital) e ingreso de capital | Σ componentes = agregado crudo (1,222.541 en mixto) | `H l.1056–1080` |
| 4 | Recupera el ingreso bruto salarial, las cuotas y el ISR; decide formalidad por ranking | ISR total = macro (7.966 vs 7.967 % del PIB, `L`) | `H l.1699–1745`, `l.2178–2253` |
| 5 | Escala cada tipo de ingreso a su agregado de cuentas nacionales (Altimir) | Σ escalada = agregado, por tipo; **los componentes ya no suman el agregado** (`cap4`) | `H l.2085–2122` |
| 6 | Reparte macro: depreciación y renta al exterior ∝ capital, remuneraciones del exterior ∝ salario, impuestos embebidos | Σ repartida = macro | `H l.2306`, `l.2415–2443` |
| 7 | Arma ingreso laboral y de capital por persona | Yl + Yk + OyE = PIB (33,667.023) | `H l.2664–2670` |

## §4 Decisiones: cada cambio de 8.15 como parámetro

**Firmado** (Ricardo, 2026-10-31, `CUAD-0-firma.md` §B) e **implementado en v8.15b**: «Firmado» es el default del código (`SIM.do` §0.8 lo declara; `Households.do` §0.0 lo valida y, suelto, lo impone); todo valor distinto imprime FLAG en el log de `Households.do` y en `nta-identidad.txt` y deja los números fuera del baseline (`manifest.json: baseline = v8.15.0`). «Añadido»: no estaba en el encargo; sale de la Tabla 1. Los Δ de nivel que esta tabla anotaba en v8.15a («saca 751.330 de Yl») eran ciertos solo si el ancla cambiaba a la vez (v8.15b-pre lo midió): en v8.15b cambian base y ancla juntas, así que los Δ reales están en el CHANGELOG `[v8.15.0]`.

| Parámetro | Firmado (default v8.15b) | Alternativas | FLAG | Memo | Qué hace |
|---|---|---|---|---|---|
| `pensiones_en_yl` | `off` | `on` (v8.14.0) | «pensiones fuera de Yl: D.62» | CUAD-0; firma A.1 | `ing_jubila` no entra a `ing_t4_cap1` ni a `ing_subor`; el ancla D.1 se reparte solo sobre salarios y YL coincide con D.1 + ⅔ B.3n. |
| `ing_mixto_depurado` | `transf_negocios` | `off` (v8.14.0) | «base de B.3n = honorarios + negocios propios» | CUAD-0; firma B.3 | `ing_mixto` = `ing_t4_cap2` íntegro + `ing_t2_cap1` + `ing_t2_cap8` (P068–P081); cap5, cap7, cap9 (transferencias, financieros, remesas crudas) y cap6, cap8 (intereses, dividendos) quedan con factor 1 fuera de Yl/Yk (siguen en `ing_bruto_tax`). `transf` (sin negocios) desaparece: sin partición pf/PM, B.3n es la única celda de los negocios. |
| `rentas_celda` (añadido en v8.15b) | `b3n` | `b2n` | «rentas efectivas de hogares en B.3n» | firma D.1; §10 bis | `ing_t4_cap3` (P023–P025, P031) entra a `ing_mixto` y se ancla a B.3n (SNA §7.9, §7.19c; INEGI p. 33, 45); con `b2n` (SNA §24.55) se ancla con `TaltimirHouse` a B.2n junto con `ing_estim_alqu` y viaja en Yk. El paso 0 (B.2b > alquiler imputado por 221.184) se reporta como vintage/lectura, no mueve la celda. |
| `d4_relativo` (añadido, firma) | `proxy_propiedad` | `enigh` | «D.4 por proxy de propiedad; la ENIGH cubre <1 % de la celda» (**sello rojo**) | firma A.2, B | `ing_capital` = `Distribucion` de D.4 neto S.14 (− D.442 con `cuotas_d614=neto`) ∝ (cap6 + cap8 + cap3 + alquiler imputado + negocios, crudos); `enigh` = cap6 + cap8 (factor ≈ 250). `escalar D4CoberturaENIGH` declara la cobertura. |
| `yk_ancla` | `b2n_b3n_d4` | `actual` (v8.14.0) | «Yk = B.2n + ⅓ B.3n + D.4 neto de S.14» | CUAD-0; `C1 §6.1`; firma B.5 | Yk = `ing_capital` + `ing_mixtoK` + `ing_estim_alqu` (+ cap3 con `b2n`) + CCF BIE ∝ `ing_capital`; gate Σ Yk − CCF = YAHogS14 − D.442 a 1e-9; el factor de `NTA.do` es 1 y se exige. `actual` reproduce las fórmulas de v8.14.0 y rompe los gates (declarado). |
| `cap4` | `fuera` | `dentro` (v8.14.0) | «enajenaciones fuera de la cuenta corriente» | CUAD-0; firma B.6 | `ing_t4_cap4` con factor 1, fuera de Yl/Yk; sigue en `ing_bruto_tax`. Con `dentro` entra a `ing_mixto` con el mismo factor (ya no dos factores). |
| `cap3_particion` | **sin objeto** | — | — | firma B.7 | Murió con la decisión 3: no existen `*pf`/`*PM`; `Households.do` rechaza el global. |
| `alq_en_capital` | `off` (único valor) | — | «alquiler fuera de la base de capital» | CUAD-0; firma B.8 | El alquiler imputado vive solo en `ing_estim_alqu` (B.2n); `ing_capital` ya no es suma de variables ENIGH. |
| `suborrow` | `off` | `on` (v8.14.0) | «ROW dentro de D.1» | CUAD-0; firma B.9 | D.1 S.14 (f.71) ya incluye los 52.721 del exterior (CSI_121 f.71); no existen `ing_suborROW` ni `ing_capitalROW`. |
| `oye_en_hub` | `off` | `on` (v8.14.0) | «OyE fuera del hub» | `C1 §4.4` D2; firma B.10 | OyE no se reparte a personas (`ing_Sector_Publico` no existe); en los Sankeys NTA entra como «Empresas públicas → Gobierno», en el fiscal (`SankeySF`) ya entraba como «Empresas públicas → CGPE». |
| `cuotas_d614` | `neto` | `actual` | «circuito D.614/D.442 neteado» | CUAD-0; `C1 §4.4` D5; firma B.11 | D.442 (605.932) sale de la celda de `ing_capital` y de YA (`NTA.do`); D.614 ya estaba fuera de las cuotas. YA_base = 8,226.391. |
| Impuestos embebidos | explícitos | — | «sin impuestos en los factores» | firma; E1 | Ningún `Taltimir*` lleva impuestos a productos ni a la producción; `ImpNetProductos` (∝ gasto) e `ImpNetProduccion` (∝ base gravable) se reparten explícitos en §12 y no entran a Yl/Yk. |
| Filas de sector (decisión 13) | en `Sankey.do` y `output.txt` | — | «PIB = YL + YA + sectores» | firma B.13; `C1 §4.3` | PIB (BIE) = YL + YA + D.442 + B.5n S.11 + S.12 + «S.13: impuestos netos + renta de la propiedad neta» (B.5n S.13 completo: D.2 − D.3 2,431.022 + D.4 neto −836.920; solo con los impuestos no cierra) + B.5n S.15 + CCF + renta primaria neta pagada al exterior + fila explícita «Vintage BIE vs CSI» (83.348; cerrar contra B.1b CSI escondería el dato); gate a 1e-9 en `Households.do` §9.1; llave `CUADRATURA` en `output.txt`. |

**Decisiones ya vivas** (la plantilla exige que aparezcan). Las tres primeras no son parámetro en v8.14.0: se declaran aquí para que existan.

| Parámetro | Default | Alternativas | FLAG | Memo | Qué cambia si se mueve |
|---|---|---|---|---|---|
| `informalidad` | `corte` | `probabilistica` (8.16) | No existe aún | `plantilla`; cap0 fila 12 | Pasa de corte por ranking a esperanza p × obligación. Fuera de 8.15. |
| `perfilpc` | perfil edad-sexo | per cápita | Sin parámetro en `Households.do` | Header de `Households.do` l. 5–7 | Reparte gasto, alquiler y depreciación del hogar entre sus miembros de otro modo. |
| `ImpNetProductos_mixK` | **desapareció en v8.15b** (no hay impuestos embebidos; `NTA.do` conserva la resta cableada, que vale 0 con la firma) | ⅓ en YA, ⅔ en YL (v8.14.0) | Sin parámetro | `C1 §6.1` | Con v8.13 YL llevaba 331.707 de impuestos a productos; con v8.14, 0 en YA y YL llevaba ⅔. |
| `altimir` | `yes` | no | `H l.16`, `l.2108` | CUAD-0 | Sin factores: los ingresos quedan crudos y los impuestos se suman explícitos (`H l.2448–2457`). |

### §4 bis — Política de fuente SCN (firmada por Ricardo, 2026-10-30)

- **Canal:** BIE por API.
- **Congelamiento:** cada descarga queda en `raw/` como asset del manifest, con sha256 y vintage (fecha de consulta + etiqueta INEGI preliminar/revisada) en el header del módulo y en `manifest.json`.
- **Refresco deliberado:** nunca hay lectura en caliente. Un cambio de INEGI entra solo por PR de datos.

**Spec de `05_scripts/refrescar-scn.sh` (pasos 1–5: v8.15b-pre; pasos 6–7 = `--congelar`: v8.15b, E4; `SCN.ado`/`AccesoBIE.ado` leen el asset de `raw/SCN/` verificado por sha256 contra `manifest.json: scn_vintage`, sello verde, y descargan solo si falta, sello amarillo):**

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

`manifest-datos.json` y `manifest.json` ganan `baseline: "<tag desde el que los números son comparables>"`. El CHANGELOG lleva la línea «a partir de vX los números no comparan con ≤vY por…». Se llena por primera vez en 8.15b: `baseline = v8.15.0` (firma B.14). **Gate 11** de `publicar.sh` (v8.15b-pre) exige `baseline` desde v8.15.0.

---

## §5 Anclas

### Tabla 1 — Principio C: una celda SCN por variable ENIGH

⚠ = violaba C en v8.14.0. La columna «propuesto» corresponde a los defaults de §4 del memo (v8.15a) con `cap3_particion=actual`, salvo nota; la columna «**obtenido 8.15b**» es el factor real de la sesión v8.15b con la firma (y `rentas_celda = b2n`, paso 0): corrida `diag-v8.15b-2026-10-31/r1-firma-hasta3` y la completa. Regla: **P** = propiedad · **I** = incidencia (quien recibe o paga) · **C** = per cápita · — = no es ingreso que se reparta.

| Variable (`H`) | Celda SCN propuesta | Valor SCN | Σ motor antes de ancla → post-Altimir | Factor actual (ancla actual) | Factor propuesto | **Obtenido 8.15b** | Regla | Sello | Fuente |
|---|---|---:|---|---|---:|---:|---|---|---|
| `ing_subor` sin pensiones, l. 443, 1699–1736 | D.1 S.14 | 10,052.962 | 9,571.430 → (incluida abajo) | 0.9781 | **1.0503** | **1.0650** (D.1 S.14; `pensiones_en_yl=off`) | I | amarillo | `C1 §1.2`; (no en repo) T|
| ⚠ `ing_subor` total | RemSalSS BIE + D.29 embebido | 10,013.434 + 99.782 | 10,339.577 → 10,113.216 | 0.9781 | se parte en la fila de arriba y la de abajo | 1.0650 (Σ `ing_subor` = D.1 S.14 al peso; sin impuestos) | I | amarillo | `H l.2092`; `C1 §1.2`|
| ⚠ `ing_jubila`, l. 440 | D.6211 + D.6221 S.14 | 1,390.052 | 768.147 → 751.330 | 0.9781 (ancla de salarios) | **1.8096** | fuera de Yl; PEF en NTA (τ⁺ efectivo × 1.7170 a D.62 + D.759) | I | amarillo | `C1 §1.2` l. 14; (no en repo) CSI f.133, f.136|
| `ing_PAM`, l. 543–546 | D.623 S.14 (72.268 < ENIGH: no sirve como ancla) | 72.268 | 359.084 → sin Altimir | ninguno (PEF 468.390 en NTA) | conserva PEF, con FLAG | conserva PEF (FLAG) | I | **rojo** | (no en repo) T, CSI f.138; `nta-grupoedad.json`|
| ⚠ `ing_mixto` agregado, l. 1056 | B.3n S.14 + impuestos embebidos | 6,956.984 + 566.885 | 1,222.541 → 7,523.869 | **6.1543** | deja de ser agregado único | **3.6848** (B.3n; base cap2 + cap3 + negocios + agropecuario: 1,888.030 = honorarios 758.146 + rentas 110.753 + negocios 900.869 + agropecuario 118.262 crudos; con `rentas_celda=b2n` 3.9144 sobre 1,777.277) | I ⅔ · P ⅓ | **rojo** | `H l.2094`; `C1 §1.2` l. 13|
| `ing_t4_cap2pf`, l. 456 | B.3n S.14 | 6,956.984 | 88.744 → 546.157 | 6.1543 | **5.0460** | 3.9144 (`ing_t4_cap2` íntegro: 758.146 crudos) | I ⅔ · P ⅓ | amarillo | (no en repo) T|
| ⚠ `ing_t4_cap3pf`, l. 466 (share 2.4455 > 1) | B.3n S.14 | 6,956.984 | 270.847 → 1,666.870 | 6.1543 | **5.0460** | **3.6848** (B.3n, `rentas_celda=b3n`; `ing_t4_cap3` íntegro: 110.753 crudos; con `b2n` 1.9671 a B.2n) | I ⅔ · P ⅓ | **rojo** | (no en repo) T|
| ⚠ `ing_t2_cap1` (P068–70, P075–77), l. 381 | B.3n S.14 | 6,956.984 | 900.869 → 3,284.359 | 3.6458 (ExNOpSoc) | **5.0460** | 3.9144 (B.3n) | I ⅔ · P ⅓ | amarillo | (no en repo) T|
| ⚠ `ing_t2_cap8` (P071–74, P078–81), l. 393 | B.3n S.14 | 6,956.984 | 118.262 → 431.155 | 3.6458 (ExNOpSoc) | **5.0460** | 3.9144 (B.3n) | I ⅔ · P ⅓ | amarillo | (no en repo) T|
| ⚠ `ing_t4_cap4`, l. 481 | Sin celda: ganancia de capital, fuera de la cuenta corriente | — | 95.936 → 93.835 como variable; 590.4 dentro de `ing_mixto` | **dos:** 0.9781 (variable, l. 2113) y 6.1543 (agregado) | **1**, fuera de Yl/Yk | **1** (`cap4=fuera`) | — | **rojo** | `H l.1056, l.2113`; (no en repo) T|
| ⚠ `ing_t4_cap5` donativos, l. 489 | D.75 entre hogares (neto cero en S.14) | — | 260.194 → 1,601.311 | 6.1543 | **1** | **1** | I | **rojo** | `C1 §1.2` l. 15; (no en repo) T|
| ⚠ `ing_t4_cap6` intereses, l. 494–497 | D.41 recibida S.14 (dentro del grupo D.4) | 544.940 | 19.335 → 118.991 | 6.1543 | **10.5515** en grupo; 28.18 por celda | 1 como variable; relativo de D.4 (D.4 neto − D.442 / Σ relativo = **3.3233**; cobertura ENIGH cap6 + cap8 = 0.43 %) | P | amarillo | `C1 §1.2` l. 9; (no en repo) T|
| ⚠ `ing_t4_cap7` lotería, l. 502 | D.75 | — | 1.320 → 8.126 | 6.1543 | **1** | **1** | I | **rojo** | (no en repo) T|
| ⚠ `ing_t4_cap8` acciones, l. 510 | D.42 recibida S.14 (dentro del grupo D.4) | 4,779.531 | 2.368 → 14.576 | 6.1543 | **10.5515** en grupo; 2,018 por celda | 1 como variable; relativo de D.4 (3.3233) | P | amarillo | `C1 §1.2` l. 9; (no en repo) T|
| ⚠ Remesas crudas en `ing_t4_cap9` e `ing_remesas`, l. 521 | D.752 recibida S.14 | 1,188.474 | 141.526 → 871.0 en cap9; 1,186.091 en `ing_remesas` | **dos:** 6.1543 y 8.3807 (ROWTrans BIE 1,186.091) | **8.3976**, una sola vez | **8.3807** una sola vez (ROWTrans BIE 1,186.091; D.752 S.14 1,188.474 se reporta); cap9 con factor 1 | I | amarillo | `C1 §1.2` l. 15, 20; (no en repo) T|
| ⚠ `ing_prest` + `ing_otrocap` + `ing_ahorro`, l. 527–533 | Sin celda: cuenta financiera (F.*) | — | 272.497 → 1,677.0 | 6.1543 | **1**, fuera de Yl/Yk | **1** | — | **rojo** | `C1 §2.3`; (no en repo) T|
| ⚠ `ing_benef` + `ing_heren`, l. 536–539 | Sin celda corriente de ingreso | — | 68.466 → 421.4 | 6.1543 | **1**, fuera de Yl/Yk | **1** | — | **rojo** | (no en repo) T|
| `ing_autor` + `ing_trabmenor`, l. 518–524 | Inmaterial: sin ancla | — | 1.308 → 8.0 | 6.1543 | **1**, memo | **1** | — | **rojo** | (no en repo) T|
| ⚠ `ing_capital` agregado, l. 1080 | D.4 neto S.14 | 5,602.969 | 1,880.477 → 6,855.782 | **3.6458** (ExNOpSoc 6,906.856 + impuestos 1,550.750 − OyE 1,601.824) | ver filas siguientes | `Distribucion` de D.4 neto − D.442 = **4,997.037** ∝ `ing_d4_rel` (1,503.626 crudos; 3.3233); **sello rojo** | P | **rojo** | `H l.2098`; `C1 §1.3`; (no en repo) T|
| `ing_t4_cap2PM`, l. 457 | D.4 neto S.14 | 5,602.969 | 669.401 → 2,440.482 | 3.6458 | **10.5515** | no existe (decisión 3) | P | amarillo | (no en repo) T|
| ⚠ `ing_t4_cap3PM`, l. 467 (**negativo**) | D.4 neto S.14 | 5,602.969 | −160.094 → −583.664 | 3.6458 | **10.5515**; con `acotada`, sale | no existe (decisión 3) | P | **rojo** | (no en repo) T|
| ⚠ `ing_estim_alqu`, l. 361 | B.2n S.14 | 910.359 | 352.038 → 1,114.756; **además** 1,283.4 dentro de `ing_capital` | 3.1666 (ExNOpHog + impuestos) y 3.6458 | **2.5860**, una sola vez | **2.5860** (B.2n; 352.038 crudos; con `rentas_celda=b2n` 1.9671 junto con cap3); una sola vez | P | amarillo | `H l.2103, l.1080`; `I`; (no en repo) T|
| ⚠ `ing_suborROW`, l. 2443 | Ya dentro de D.1 S.14 | 52.721 | ∝ `ing_subor` → 52.721 | macro | **se retira** | se retiró (`suborrow=off`) | I | amarillo | `H l.2443`; (no en repo) CSI_103 f.35, CSI_121 f.71|
| ⚠ `ing_capitalROW`, l. 2441 | Ya dentro de D.4 neto S.14 | −989.221 | ∝ `ing_capital` → −989.221 | macro | **se retira** | se retiró (`suborrow=off`) | P | amarillo | `H l.2441`; `C1 §3` #1|
| ⚠ `gasto_anualDepreciacion`, l. 2306 | P.51c S.14 (el resto, en Tabla 2) | 1,721.094 | ∝ `ing_capital` → 6,457.576 | macro total | **macro de S.14** | CCF BIE 6,457.576 ∝ `ing_capital` (D.4); vintage CSI − BIE 0.776 en la fila de vintage | P | amarillo | `C1 §3` #6|
| `ing_Sector_Publico` (OyE), l. 2071–2081 | Sin celda en S.14: LIF | 1,601.824 | sin ENIGH → 1,601.824 per cápita | 1 | decide `oye_en_hub` | no se reparte (`oye_en_hub=off`): fila de sector | C | **rojo** | `C1 §1.2` l. 17|

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

Mismas reglas y sellos que la Tabla 1. Los valores CSI son de `C1 §1–§3` salvo que la columna Fuente diga otra cosa.

| Sector | Partida | Valor | Regla | Cómo lo hace hoy el motor | Propuesto 8.15 | Sello | Fuente |
|---|---|---:|---|---|---|---|---|
| S.11 + S.12 | Excedente de operación (B.2n; ExNOpSoc BIE) | 6,723.499 (BIE 6,906.856 con S.15) | P | Llega: `ing_capital` ∝ base mixta, anclado al residuo BIE | Solo llega lo distribuido (D.4, abajo) | amarillo | `C1 §1.3`, `§3` #3 |
| S.11 + S.12 | D.42 a hogares | 4,779.531 | P | Indirecto, dentro de `ing_capital` y re-anclado en NTA | Dentro de D.4 neto | amarillo | `C1 §1.2` l. 9 |
| S.11, S.12, S.13 | D.41 a hogares | 544.940 | P | Igual | Dentro de D.4 neto | amarillo | `C1 §1.2` l. 9 |
| S.12 | D.44 a hogares (incluye D.442 605.932) | 735.471 | P | Igual; D.442 regresa como D.614 fuera de cuotas | Dentro de D.4 neto; circuito por `cuotas_d614` | amarillo | `C1 §1.2` l. 4, 9 |
| S.12 | D.8 | 1,270.277 | I | `YA_d8` ∝ YL de cotizantes | Sin cambio | amarillo | `I`; `N l.79` |
| S.11, S.12, S.15 | D.62 a hogares | 193.870 + 244.292 + 4.182 = 442.344 | I | Llega, atribuido al nodo Gobierno | Llega; origen correcto | amarillo | `C1 §6.5` |
| S.12, S.11 | D.61 recibida | 1,455.102 + 193.870 | I | `Cuotas` por persona, todas a Gobierno | Por persona; destino por sector | amarillo | `C1 §6.3` |
| S.11 + S.12 | D.5 (ISR de sociedades) | 1,188.648 (LIF 1,801.570 con OTROSK) | P | Fiscal: ISR PM por persona. NTA: `TmenFuera`, informativo | Regla única P en los dos Sankeys | amarillo | `C1 §3` #5; `I` |
| S.11 + S.12 | Impuestos a productos y producción embebidos | 1,550.750 | I | Por Altimir en `ing_capital` | Fuera de factores; ImpProd explícito ∝ Cpriv | **rojo** | (no en repo) T |
| S.11, S.12 | CCF | 4,634.128 + 62.735 | P | Llega: ∝ `ing_capital`, dentro de los 6,457.576 | No llega como ingreso; memo por sector | amarillo | `C1 §3` #6 |
| **S.11** | **Excedente retenido (B.5n)** | **−1,116.929** (B.8n −2,903.413) | P | **No llega** | P ∝ D.42 recibido, como memo: no entra a YA hasta decidir D1 de `C1 §4.4` | amarillo | `C1 §1.2` l. 3 |
| **S.12** | **Excedente retenido (B.5n)** | **+2,070.833** (B.8n +1,789.804) | P | **No llega** | Igual | amarillo | `C1 §1.2` l. 4 |
| S.13 | D.21 − D.31 | 2,175.907 | I | `ImpProd` ∝ Cpriv (τ⁻ indirectos 2,192.943) | Sin cambio | amarillo | `I` |
| S.13 | D.29 − D.39 | 255.114 | I | Parcial: 247 bn embebidos en `Yl`/`Yk` | Fuera de factores; I ∝ base gravable | amarillo | `N l.369`; `C1 §1.2` l. 6 |
| S.13 | D.62 + D.759 a hogares | 3,010.029 (`TpubEf` 3,445.143) | I | Llega; factor 1.7170 sobre PEF/ENIGH | Sin cambio de regla; se separa lo privado | amarillo | `I`; `C1 §2.3` |
| S.13 | D.63 educación y salud | 1,054.587 + 948.537 | I | Llega por uso | Sin cambio; se ajusta al quitar ISFLSH | amarillo | `I`; `nta-grupoedad.json` |
| S.13 | D.63 resto | 396.044 | C | Llega per cápita | Sin cambio; incluye la mezcla con ISFLSH | amarillo | `I` |
| **S.13** | **Consumo colectivo P.32** | **1,896.999** (motor 1,517.160) | C | **Sí llega en la cuenta** per cápita (`TpubCol`) por 1,517.160; sin edad solo en el gráfico. Faltan 379.839 | C sobre P.32 completo | amarillo | `I`; `C1 §6.4` |
| S.13 | D.41 pagado (intereses de la deuda) | 1,205.483 | C | **No llega** como gasto; lo recibido por hogares va en D.41 | C como renta pública de activos, memo | amarillo | `C1 §3` #9 |
| S.13 | D.45 (FMP y renta petrolera) / OyE | 224.114 / 1,601.824 | C | OyE per cápita, duplica frente al SCN | `oye_en_hub`; sin doble conteo | **rojo** | `C1 §1.2` l. 17 |
| S.13 | B.8n / B.9 | −1,157.268 / −2,156.464 | C | **No llega**; `Déficit público` 506.776 es balance de nodo | C como financiamiento futuro; decide D8 de `C1 §4.4` | amarillo | `C1 §2.3–2.4` |
| S.15 | D.63 | 388.320 | I | Llega, dentro de la especie de Gobierno | Regla I con origen S.15 | amarillo | `C1 §6.4` |
| S.15 | B.2n (dentro de ExNOpSoc) | 102.442 | P | Llega dentro de `ing_capital` | No llega como renta; memo | amarillo | `C1 §1.3` |
| S.15 | D.751 recibida (de hogares 274.349) | 340.736 | I | `InterOtor` 88.773, no cierra | Se declara la brecha | amarillo | `C1 §3` #8; `I` |
| S.15 | B.8n | 61.425 | P | **No llega** | Memo, con D7 de `C1 §4.4` | amarillo | `C1 §2.2` |
| S.2 | D.752 a hogares | 1,188.474 (BIE neto 1,186.091) | I | ∝ `ing_remesas` crudo, también dentro de cap9 | Una sola vez | amarillo | `C1 §1.2` l. 20 |
| S.2 | D.1 | 52.721 | I | ∝ `ing_subor`, aparte de D.1 | Dentro de D.1 S.14 | amarillo | Tabla 1 |
| S.2 | D.4 neta | −989.221 | P | ∝ `ing_capital`; el re-anclaje lo diluye | Dentro de D.4 neto S.14 | amarillo | `C1 §3` #1 |
| S.2 | Compras netas de no residentes | −372.715 | I | ∝ `gastoanualTOT` dentro de Cpriv | Sin cambio | amarillo | `I` |
| S.2 | B.9 | 251.842 | — | **No llega** | Memo, con D8 de `C1 §4.4` | **rojo** | `C1 §2.2` |

**Sobre el encargo:** pedía el consumo colectivo de S.13 entre lo que no llega a personas. En la cuenta NTA **sí llega** per cápita, por 1,517.160 (τ⁺ col en `I`). El defecto es otro: faltan 379.839 frente a P.32. Lo que de verdad no llega de S.13 son los intereses y su déficit.

---

## §6 Salidas

| Archivo / JSON / figura | Qué contiene | Quién lo consume | Check de CI que lo protege |
|---|---|---|---|
| `master/<año>/households.dta` | Base por persona: `Yl`, `Yk`, `ing_*`, impuestos, consumo | `NTA.do`, `PerfilesSim.do`, `SankeySF.do`, `CicloEntidad.do`, resto del motor | Sin protección automática — gate humano |
| Escalares `pctpib` de los pasos 0–4 | ENIGH vs macro y factores | Log de la corrida; módulos que los leen | Sin protección automática — gate humano |
| `users/<id>/output.txt` | Default del sitio | Sitio; sidecar | Sin protección de sus números en CI: `gate-numeros.sh` corre en sesión. `sitio-transitorios` solo lo usa como Stata falso |
| 5 `sankey-*.json` (fiscal) y 5 `SankeyNTA/sankey-*.json` | Flujos por corte | Portada; sidecar | Ídem: `gate-numeros.sh` en sesión |
| `users/<id>/NTA/*`, `SankeyNTA/sankey-v3-grupoedad.json` | Cuenta NTA y v3 (vía `NTA.do`) | `/NTA`; sidecar | `/NTA: Sankey NTA idéntico al JSON del motor` (dibujo vs fixture). La identidad corre en sesión: `test-nta-identidad.sh` |

## §7 Identidades verificadas

Última corrida: `02156b2` (sesión v8.15b; evidencia `diag-v8.15b-2026-10-31/r3-firma-completa`). Los gates nuevos de v8.15b viven en el log de `Households.do` §9.1 (`GATE Households (1e-9): …`), en `NTA.do` y en `output.txt` (`CUADRATURA`).

| Identidad | Tolerancia | Resultado | Hash |
|---|---|---|---|
| `gate-numeros.sh`: `output.txt` = baseline v8.14.0 | byte a byte | **ROJO esperado** (baseline nuevo v8.15.0; Δ por llave en el PR) | `02156b2` |
| `gate-numeros.sh`: 10 sankeys = baseline v8.14.0 | 1e-9 relativo por enlace | **ROJO esperado** (nodos nuevos: Otros sectores, Empresas públicas) | `02156b2` |
| Households: Σ `ing_subor` = D.1 S.14 (10,052.962) | 1e-9 relativo | VERDE, reldif 0.0e+00 | `02156b2` |
| Households: Σ `ing_mixto` = B.3n S.14 (6,956.984) | 1e-9 relativo | VERDE, reldif 0.0e+00 | `02156b2` |
| Households: Σ `ing_estim_alqu` + `ing_t4_cap3` = B.2n S.14 (910.359) | 1e-9 relativo | VERDE, reldif 0.0e+00 | `02156b2` |
| Households: Σ `ing_capital` = D.4 neto − D.442 (4,997.037) | 1e-9 relativo | VERDE, reldif 0.0e+00 | `02156b2` |
| Households: componentes de `ing_mixto` = agregado | 1e-9 relativo | VERDE, reldif 0.0e+00 | `02156b2` |
| Households: Σ Yl = D.1 + ⅔ B.3n (14,690.951); Σ Yk − CCF = YAHogS14 − D.442 (8,226.391) | 1e-9 relativo | VERDE, reldif 0.0e+00 (ambos) | `02156b2` |
| Households / `Sankey.do` / `output.txt`: PIB (BIE) = YL + YA + D.442 + B.5n S.11+S.12 + B.5n S.13 + B.5n S.15 + CCF + ROW + vintage | 1e-9 relativo | VERDE, reldif 0.0e+00 (`CUADRATURA`: 43.636 + 24.435 + 1.800 + 2.833 + 4.735 + 0.347 + 19.181 + 2.782 + 0.252 = 100.000) | `02156b2` |
| NTA: residual por persona (`N` §5) | 1e-9 × C per cápita | VERDE, máx 2.98e-08 MXN | `02156b2` |
| NTA: Σ intra nacional = 0 | 1e-9 relativo | VERDE, 0.00 MXN | `02156b2` |
| NTA: Σ S = B.8n con ancla (multiplicativa; Σ S sin ancla 2,116.145, brecha +11.3 %) | 1e-9 relativo | VERDE, 0.00 MXN | `02156b2` |
| NTA: factor YA = 1 (YA_motor = YAHogS14 − D.442 al peso) | 1e-9 relativo | VERDE, factor 1.000000 | `02156b2` |
| Identidad NTA sin ancla y conservación del v3 (`test-nta-identidad.sh`) | 1e-9 relativo | VERDE (`diag-v8.15b-2026-10-31/test-nta-identidad.txt`; v3 35 nodos / 99 enlaces; v2 52/173) | `02156b2` |
| Contrato de las 32 (`contrato-32.sh`: paridad, aditividad Σ32, sellos) | 1e-9 relativo / byte | PASÓ paridad + aditividad (Σ32 neto reldif 0.0e+00; APORT* máx 0.000499); el testigo NL falla contra el fixture v8.14 (re-baseline pendiente) | `02156b2` |
| Puente INBD → hub (`C1 §1.2`) | **Sin gate**: script de CONC-1 | superado por la identidad de sectores (fila anterior) | — |

## §8 Límites conocidos

La versión de cierre es **propuesta** de este memo.

| # | FLAG abierto | Magnitud (bn) | Cierre propuesto |
|---|---|---:|---|
| 1 | Transferencias y flujos financieros en `ing_mixto` | 4,570.687 | **Cerrado en v8.15b**: `ing_mixto_depurado = transf_negocios` (cap5, cap7, cap9 con factor 1 fuera de Yl/Yk) |
| 2 | Pensiones en `Yl` | 751.330 | **Cerrado en v8.15b**: `pensiones_en_yl = off` |
| 3 | `Yk` anclado fuera de S.14 | 10,478.495 vs 8,832.323 | **Cerrado en v8.15b**: `yk_ancla = b2n_b3n_d4` completo (Σ Yk − CCF = YAHogS14 − D.442 = 8,226.391, gate 1e-9; factor NTA = 1) |
| 4 | `*_t4_cap4` con dos factores | 95.936 crudos | **Cerrado en v8.15b**: `cap4 = fuera` (factor 1); con `dentro` un solo factor |
| 5 | Partición de `cap3` con share 2.4455 y `cap3PM` negativo | −160.094 crudos | **Cerrado en v8.15b**: sin partición pf/PM; `cap3` íntegro a B.3n (`rentas_celda = b3n`, firma D.1) |
| 6 | Alquiler imputado en la base de `ing_capital` | 352.038 crudos | **Cerrado en v8.15b**: `alq_en_capital = off`; `ing_capital` = Distribución de D.4 neto |
| 7 | Remesas escaladas dos veces | 141.526 crudos | **Cerrado en v8.15b**: cap9 con factor 1; `ing_remesas` × ROWTrans una sola vez (D.752 S.14 1,188.474 se reporta) |
| 8 | Impuestos embebidos por Altimir en `Yl`/`Yk` | 247 de D.29 − D.39 | **Cerrado en v8.15b**: ningún `Taltimir*` lleva impuestos; `ImpNetProductos`/`ImpNetProduccion` explícitos, fuera de Yl/Yk |
| 9 | CSI y BIE sin asset congelado | toda ancla S.14 | **Cerrado en v8.15b**: `refrescar-scn.sh --congelar` → `raw/SCN/` + `manifest.json: scn_vintage`; `SCN.ado`/`AccesoBIE.ado` lo verifican (sello verde) |
| 10 | Vintage BIE vs CSI | 84.124 en PIB (B.1b CSI 33,582.899 vs BIE 33,667.023); 0.776 en CCF | **Declarado en v8.15b** como fila «Vintage BIE−CSI» de la identidad (`CUADRATURA`); una sola fuente, después |
| 11 | OyE duplica frente al SCN | 1,601.824 | **Cerrado en v8.15b**: `oye_en_hub = off` (firma B.10); «Empresas públicas → Gobierno» |
| 12 | Circuito D.614 / D.442 | 605.932 | **Cerrado en v8.15b**: `cuotas_d614 = neto` (firma B.11); fila «Circuito D.442 → D.614» en la identidad |
| 13 | Cuotas todas a Gobierno | 1,045.130 | Sin fecha (Sankey de economía completa) |
| 14 | τ⁺ con D.62 privado en Gobierno | 442.344 | Sin fecha |
| 15 | ISFLSH mezcladas con hogares y Gobierno: D.63 en la especie; colectivo corto | 388.320 / 379.839 | Sin fecha |
| 16 | Catálogo ENIGH de P068–P081 sin verificar contra el descriptor | 1,019.131 crudos | **Cerrado en v8.15b-pre (4a)**: «ingresos por negocio propio» (trabajo independiente) |
| 18 | B.2b S.14 (2,107.569) > alquiler imputado CSVM 2024 (1,886.385): +221.184 (11.7 %; el vintage BIE–CSI es 0.25 %: no es vintage, es **contenido**: algo más vive en el B.2 de hogares pese al texto de INEGI p. 45; el candidato obvio son las rentas efectivas de viviendas arrendadas) | 221.184 (0.66 % del PIB) | **Abierto** (Ricardo, 2026-10-31): la celda se queda en B.3n (SNA §7.9 + INEGI); `rentas_celda = b2n` es el otro escenario, ya medido (r2: Self 3.9144, House 1.9671, mismos totales); las dos lecturas quedan declaradas. Se cierra con la ficha metodológica de la CSVM o la de la CSI base 2018 |
| 17 | Subreporte de top incomes en la ENIGH | Sin magnitud en este memo | Estructural |
| 19 | Base del ISR PM = negocios propios (`ing_bruto_tpm`, v8.15b): los negocios propios tributan como PF (actividad empresarial); el ISR PM es de sociedades y su incidencia a personas va ∝ `d4_relativo` (regla P de la Tabla 2) | ISR_PM 1,351.117 bn | **Declarado** (Ricardo, 2026-10-31); se corrige en 8.16 (ISR_Mod/TasasEfectivas) |

## §9 Específico de México

| Elemento | Qué requiere genéricamente | Por qué México lo resuelve así | En cap0 |
|---|---|---|---|
| ENIGH bienal | Encuesta con ingreso y gasto por persona, factor de expansión y folio hogar-persona | Es la única fuente con ingreso por fuente y gasto en el mismo hogar; bienal, por eso `anioenigh` se separa del año fiscal y las anclas se toman del año ENIGH | Filas 2 y 3 |
| CONAPO edad simple | Proyecciones por edad simple, sexo y unidad subnacional | Son las proyecciones oficiales, por entidad; sostienen perfiles y proyección a 2070 | Fila 1 |
| CSI por sector | Cuentas integradas con hogares separados, vintage identificable | INEGI publica S.11–S.15 y S.2, con vintage distinto al del BIE | Fila 4 |
| Altimir | Tabla de correspondencia encuesta → SCN, una celda por variable | La distancia es grande: Yl + Yk crudos son 33.36 % del PIB (`L`) y se escala por tipo de ingreso | §0.3, «Ajuste encuesta–SCN» |
| Informalidad por cotización | Afiliación o cotización por persona, y una definición oficial para validar | La ENIGH trae seguridad social; probit más corte por ranking contra la recaudación (89,518 personas con cuotas > 0, `L`) | Fila 12 |

**Comparación con cap0:** los cinco están; **no se copió ningún renglón.** cap0 ya está corregido en este PR; las cuatro diferencias que salieron de esta comparación quedan **resueltas en #51**:

1. **Fila 1**, «vintage anual»: el motor usa un solo vintage, pry23 de 2023 (`Poblacion.ado` l. 650–655). Ahora dice «un vintage fijo por versión; hoy CONAPO pry23».
2. **Fila 4**, «CSI; BIE como vintage alterno»: §4 bis firma el BIE como canal. Ahora dice «canal BIE, congelado en `raw/`», y la lista de partidas agrega las que las Tablas 1 y 2 usan: D.21/D.31, D.29/D.39, P.3, P.32, P.51c.
3. **Fila 15**, «Banxico»: el motor no lee Banxico; ancla remesas a ROWTrans del BIE (`H l.2106`). Ahora dice ROWTrans del BIE, con Banxico como contraste.
4. **§0.3**, principios C y B: describían el estado propuesto como hecho. Ahora dicen «vigente desde 8.15b si se firma CUAD-0».

## §10 Procedencia

| Sección | Archivo y líneas |
|---|---|
| Encabezado | `SIM.do` l. 134–138; `git log -- 01_modulos/Households.do` |
| §2 | `05_scripts/manifest.json` (assets); `01_modulos/Households.do` l. 114–134, 557–562; `SCN.ado` l. 60–79, 2128–2133; `Poblacion.ado` l. 650–678; `publicar.sh` l. 822–823 |
| §3 | `Households.do` l. 378–550, 1056–1080, 1699–1745, 2085–2122, 2178–2253, 2306, 2415–2443, 2664–2670 |
| §4 | `Households.do` l. 5–7, 16, 443, 1056, 2108–2121, 2448–2457; `NTA.do` l. 339–362, 386–387, 565; `C1 §4.4`, `§6.1`; `metodo/plantilla-capitulo.md` §4; `metodo/cap0-requerimientos.md` fila 12 |
| §5 Tabla 1 | `Households.do` l. citadas en cada fila; `05_scripts/fixtures/nta-identidad.txt`; `C1 §1.2–§1.3`; `diag-v8.15a-2026-10-30/tabla1.py`, `tabla1.out`; CSI_115 f.69–71, 95–105, 133, 136, 138, 150; CSI_103 f.35; CSI_121 f.71 |
| §5 Tabla 2 | `C1 §1.2`, `§2.2–§2.4`, `§3`, `§6`; `nta-identidad.txt`; `NTA.do` l. 79, 369 |
| §6 | `.github/workflows/gates-sin-stata.yml`; `02_governance/runbook-deploys-ciep.md` §11; `SIM.do` l. 141–145, 518–535 |
| §7 | `05_scripts/gate-numeros.sh`; `diag-v8.15a-2026-10-30/gate-numeros.txt`; `NTA.do` l. 128, 686–698; `05_scripts/test-nta-identidad.sh`; `02-ritual/commit.txt` |
| §9 | `Households.do` l. 2106, 2178–2253; `Poblacion.ado` l. 650–655; `metodo/cap0-requerimientos.md`; `diag-v8.14.0-2026-10-30/02-ritual/wrap.log` l. 586–600, 1529–1537 |
| Δ esperado | Aritmética de Tabla 1, `nta-identidad.txt` y CSI_115 f.114–171 |

### §10 bis — Verificación contra el manual (firma v3 §D, 2026-10-31; párrafos literales, página y URL)

Regla de la firma §D: ninguna frase del método nace fuera del repo; lo citado se copia literal. Fuentes: SNA 2008 (texto final, https://unstats.un.org/unsd/nationalaccount/docs/SNA2008.pdf; borradores de los caps. 7 y 8 en https://unstats.un.org/unsd/statcom/doc08/SNA-Chapter7.pdf y -Chapter8.pdf) e INEGI, *Sistema de Cuentas Nacionales de México. Cuentas por sectores institucionales 2003-2013. Año base 2008. Fuentes y metodología. Primera versión* (2014; `02_governance/metodo/fuentes/702825068479.pdf`, sha256 `20ff0c4f…`, páginas del PDF; origen https://www.inegi.org.mx/contenidos/productos/prod_serv/contenidos/espanol/bvinegi/productos/metodologias/SCNM/702825068479.pdf). La metodología base 2018 no tiene PDF público localizado (la guía rápida remite a «Fuentes y metodologías. Año base 2018»).

1. **Rentas efectivas de hogares → B.3n (decisión 3; `rentas_celda = b3n`): verde.** SNA 2008 §7.9: «In practice, all unincorporated enterprises owned by households that are not quasi-corporations are deemed to have mixed income as their balancing item, except owner-occupiers in their capacity as producers of housing services for own final consumption and households employing paid domestic staff. For owner-occupiers, all value added is operating surplus and for domestic staff all value added is compensation of employees.» §7.19(c): «The balance of primary incomes of the household sector consists of compensation of employees and mixed incomes accruing to households, plus property income receivable less property income payable. It also includes the operating surplus from housing services produced for own consumption by owner-occupiers.» INEGI, p. 33: «…el excedente derivado de las actividades productivas de una empresa no constituida en sociedad perteneciente a un hogar representa una combinación de dos clases diferentes de ingreso, razón por la cual el actual SCN lo denomina “Ingreso Mixto” en lugar de “excedente de operación”, excepto cuando se trata del excedente derivado de la producción por cuenta propia de los servicios de vivienda.» INEGI, p. 45: «En el caso de los Hogares, el excedente se origina en la producción por cuenta propia del servicio de alquiler de vivienda.» B.2n S.14 = alquiler imputado y nada más; las rentas efectivas de un casero son B.3n.
2. **Negocios P068–P081 íntegros a B.3n: verde con FLAG de cuasisociedades.** INEGI, p. 12: «Se denominan “cuasisociedades” a las empresas que no están constituidas en sociedad pero funcionan como tal, pues se comportan en forma autónoma e independiente de sus propietarios y disponen de conjuntos completos de cuentas, condición necesaria para que sean tratadas como cuasisociedades. Como consecuencia de ello, las cuasisociedades que son propiedad de los Hogares o del Gobierno se agrupan junto con las sociedades no financieras». INEGI, p. 33: «…también se contabilizan como hogares productores a los trabajadores por cuenta propia, profesionistas independientes, ejidatarios, jornaleros, artesanos, vendedores ambulantes, etcétera.» La ENIGH no identifica cuasisociedades; la cobertura (Σ crudos / B.3n) se declara como factor con FLAG. Sello amarillo solo por ese FLAG.
3. **Circuito D.442/D.614 neutral (decisión 11): verde.** INEGI, p. 46: «La Renta de inversión a pagar sobre derechos de pensión (D.442) comprende los rendimientos obtenidos por la inversión de los fondos de pensiones, propiedad de los trabajadores y administrados por alguna institución, regularmente de tipo financiero». INEGI, p. 47: «Las contribuciones sociales complementarias de los hogares son los ingresos de la propiedad obtenidos durante el periodo contable sobre el saldo de los derechos de pensiones y no de pensiones.» SNA 2008 cap. 8 (borrador §8.77, §8.83): los suplementos «represent the return to the pension fund of the property income earned on the start of year pension entitlement». CSI_115: D.442 = D.614 = 605.932 al peso (f.103, f.127).
4. **D.8: verde.** INEGI, p. 49: «El Ajuste por cambio en los derechos de pensiones (D.8) es una transacción que proviene de la diferencia entre los pagos de contribuciones de pensión a los fondos y los cobros de pensiones por los pensionistas … Con este ajuste el diferencial indicado se trata como si fueran propiedad colectiva de los hogares que tienen derechos sobre dichos fondos». Es lo que `NTA.do` hace (`YA_d8` ∝ YL de cotizantes). Sin cambio en 8.15b.
5. **Remesas D.752: verde.** INEGI, p. 48: «…entre hogares que consisten en las remesas regulares entre los miembros de la misma familia residentes en diferentes partes del mismo país o en diferentes países (D.752)». SNA 2008 cap. 8 borrador §8.26(e). Celda confirmada: CSI_115 f.150 D.752 recibida 1,188.474.
6. **PIB vs INB — SNA 2008 §7.21** (sostiene la fila «Renta primaria neta pagada al exterior» de la identidad de sectores): «It follows that the difference between the numerical values of GNI and GDP is equal to the difference between the total primary incomes receivable by residents from non-residents and the total primary incomes payable by residents to non-residents (that is, net income from abroad).»
7. **Paso 0 (verificación al peso B.2n = alquiler imputado): NO coincide; FLAG 18 de contenido, no de lectura ni de vintage (Ricardo, 2026-10-31).** INEGI publica el alquiler imputado bruto en la Cuenta Satélite de Vivienda de México 2024 (reporte de resultados 47/25, 21-nov-2025, p. 7–8, https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2025/viviendasat/CSVM2024_RR.pdf): «Adicionalmente, la CSVM proporciona datos sobre la valoración del alquiler imputado, que representa el monto que pagaría una persona propietaria si alquilara la vivienda que habita … En 2024, dicho concepto alcanzó un monto de 1 886 385 millones de pesos. Esta cifra representó 6.0 % del PIB de la economía total.» Contra la CSI: B.2b S.14 = 2,107.569 (CSI_115 f.59), P.51c1 = 1,197.210 (f.61), B.2n = 910.359 (f.63/f.69). B.2b − alquiler imputado CSVM = **+221.184 bn (11.7 % de B.2b; 0.66 % del PIB)**; la comparación es en bruto porque INEGI no publica el VAB neto del alquiler imputado. No es vintage (el vintage BIE–CSI del PIB es 0.25 %): algo más vive en el B.2 de hogares pese al texto de INEGI (p. 45); el candidato obvio son las rentas efectivas de viviendas arrendadas (SNA 2008 §24.55: «By convention, all the value added arising from leasing dwellings is treated as operating surplus, not mixed income»). La celda se queda en B.3n (SNA §7.9 + INEGI p. 33, 45): `rentas_celda = b3n`; el otro escenario, `b2n`, está medido (`diag-v8.15b-2026-10-31/r2-firma-hasta3`: TaltimirSelf 3.9144, TaltimirHouse 1.9671, mismos totales de Yl, Yk y Σ S, distinta distribución) y las dos lecturas quedan declaradas hasta la ficha metodológica de la CSVM o la de la CSI base 2018 (FLAG 18). La serie BIE 724611 «04.1 Alquileres efectivos de alojamiento» = 2,763.650 no separa efectivos de imputados y no sirve de prueba.

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
