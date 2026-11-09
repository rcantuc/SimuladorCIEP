# CUAD-3 — Capítulo `Households` del método, celdas revisadas e ingresos altos: rentas efectivas a B.2n, negocios = B.3n + D.422 y brecha ENIGH–SCN repartida ∝ Y^ε (8.17.2)

**Fecha:** 2026-11-08 · **Sesión:** `sesion/cuad-3` (memo + implementación; v8.17.2) · **Base:** `master` `5007066` (v8.17.1 + `_log.ado`; baseline `v8.17.0`) · **Estado:** **pendiente de firma**: Ricardo firma al leer el PR, antes del merge. Las cuatro decisiones de Ricardo del 2026-11-08 (`CEPAL-delCastillo-2023-lecciones.md`: 1 rentas efectivas → B.2n; 2 `ing_mixto` ancla = B.3n + D.422 S.14; 3 `altimir_elasticidad` calibrada contra el ITAN; 4 citar a del Castillo) están implementadas en esta rama con el valor propuesto aquí como default; §4 lleva cada parámetro con default, alternativas y FLAG, §7 los gates con su resultado medido y §8 los FLAGs que se cierran (18, 27) y los que se declaran.

## Encabezado

| Campo | Valor |
|---|---|
| `modulo` | `Households` (§0, §3, §9, §9.1, §11.1 de `01_modulos/Households.do`); celdas nuevas en `SCN.ado` (`SCNHogaresS14`); anclas de YA/YL en `NTA.do` §4.3b |
| `archivo` | `01_modulos/Households.do`, `SCN.ado`, `01_modulos/NTA.do`, `SIM.do` §0.8 @ la rama `sesion/cuad-3` (hash en el PR) |
| `orden_en_SIM` | Segundo módulo `.do`, después de `Expenditure` (`SIM.do` §3) |
| `desde_version` | v8.17.2 (`rentas_celda = b2n`, `ing_mixto_ancla`, `altimir_elasticidad`); `rentas_celda` existe desde v8.15.0 |
| `ultima_decision` | 2026-11-08 (decisiones 1–4 de Ricardo; §4.0) |
| `sello` | **rojo** heredado de D.4 (`d4_relativo`, CUAD-0); las celdas de D.1, B.3n + D.422 y B.2n son **amarillas** (CSI congelada, vintage BIE vs CSI declarado; cuasisociedades no identificables en la ENIGH) |

Escrito en `metodo/plantilla-capitulo.md` con las adiciones de CUAD-0 (Resumen, §4.0, §10 bis, Δ esperado). **Convención:** miles de millones de MXN corrientes de 2024 («bn»), PIB = 33,667.023 bn (BIE 724025); «crudo» = Σ x·factor antes de las anclas; «Σ motor» = lo que el motor suma antes del ancla. **Fuente** (marcas): `H l.N` = `01_modulos/Households.do`; `S` = `SCN.ado`; `N` = `01_modulos/NTA.do`; `L` = `diag-log-legible-2026-11-09/01-sim-completo/wrap.log` (corrida canónica de v8.17.1); `R0`, `Rε` = corridas de esta sesión en `~/CIEP_Simuladores/diag-cuad-3-2026-11-08/` (`00-gate-eps1-celdas-v8171`, `eps-<ε>`, `01-sim-completo`); `dC p.N` = del Castillo (2023), página del PDF `02_governance/metodo/fuentes/S2300345_es.pdf` (sha256 `74c0c048…`); CSI_115 f.N = tabulado INEGI S.14, 2024 revisada (asset congelado); `(no en repo)` = cifra que no está versionada y se dice de dónde sale. Ninguna cifra es estimada.

## Resumen

1. **FLAG 18 se cierra leyendo el SCN como lo lee del Castillo.** B.2b S.14 (2,107.569) supera al alquiler imputado de la CSVM 2024 (1,886.385) en 221.184 porque el excedente de operación de los hogares incluye la renta de los inmuebles arrendados (`dC p.232`; SNA 2008 §24.55). La celda de `ing_t4_cap3` (P023–P025, P031: 110.753 crudos) pasa de B.3n a B.2n: el factor de B.2n baja de 2.5860 a **1.9671** y el de B.3n sube de 3.6848 a 3.9144 (sin D.422). Mueve distribución, no totales (Yl, Yk, Σ S iguales al peso).
2. **La celda de los negocios es B.3n + D.422.** INEGI publica D.422 «Retiros de los ingresos de cuasi sociedades» recibidos por S.14 en CSI_115 f.99 R/P: **649.743** bn en 2024 (dentro de D.42 4,779.531 = D.421 4,129.787 + D.422). La ENIGH no distingue al dueño de una cuasisociedad del de un negocio (P068–P081, P012/P019): `ing_mixto` se ancla a **7,606.727** (factor **4.2800** sobre 1,777.277 crudos) y D.422 sale de la celda D.4 de `ing_capital` (4,997.037 → 4,347.294). YL sube ⅔ × 649.743 = **+433.162** (14,690.951 → 15,124.113; 43.636 → 44.923 % del PIB) y YA baja lo mismo; YL + YA = B.5n S.14 − D.442 no cambia (`CUADRATURA` cierra igual).
3. **La brecha ENIGH–SCN deja de repartirse uniforme.** Dentro de D.1 y de B.3n (+ D.422) cada persona recibe brecha × Y_i^ε / Σ w Y^ε (`dC p.238`): con ε = 1 es Altimir (hoy, byte-idéntico); con ε > 1 los ingresos altos absorben más subreporte. ε se calibra contra el ISR de personas físicas por rango de ingreso declarado del ITAN 4T 2024 (§4, Tabla 3b): **ε\* = 1.45** (mínimo del estadístico L1 sobre los 9 rangos del ITAN: 56.6 pp, frente a 94.9 con ε = 1 y 78.4 con el 1.75 de del Castillo; la curva es plana entre 1.35 y 1.50 (59.1–57.4) y 1.45 ya está en la malla de 0.05). Default propuesto: **`altimir_elasticidad = 1.45`**; alternativas 1 (Altimir) y 1.75 (del Castillo) corren con FLAG.
4. **FLAG 27 sigue abierto y declarado.** Con ε\* el residuo Σ obligación(formales) − LIF de asalariados pasa de −237.200 (−18.92 %, v8.17.1) a **−212.324** (−16.93 %): el residuo sigue negativo con cualquier ε ∈ [1, 2] (−237.2 → −182.7 bn), así que no hay evasión identificable: el motor subestima la obligación estatutaria de los 25.5 millones de formales aun con la brecha de D.1 concentrada arriba, porque la brecha de D.1 es solo 780 bn (8.4 % de la celda) y la mayor parte del ajuste cae en B.3n (5,829 bn), que no son asalariados. Se publica como subreporte residual con sello rojo (FLAG 27), no como evasión; la regla «≥ 0 = evasión identificable» queda en el código para cuando el ancla de formales o la celda cambien.
5. **Lo publicado se mueve y se declara** (`baseline = v8.17.2`): `CUADRATURA` (YL/YA), `INCD*` de ISR, Laboral y Aportaciones, `APORT*`, `PROY*` de segundo orden; los Sankeys NTA cambian de reparto por edad; Σ S sin ancla vs B.8n S.14 no cambia (−19.4 bn, −1.0 %; ancla multiplicativa 1.0103): las celdas nuevas y ε mueven el reparto dentro de B.5n S.14, no su total. Δ real vs esperado en el CHANGELOG `[v8.17.2]` y al final de este memo.

---

## §1 Propósito

Escalar el ingreso por persona de la ENIGH a las celdas del sector hogares del SCN **sin suponer que el subreporte es proporcional al ingreso**: la celda fija el total (principio C), la elasticidad ε fija cómo se reparte la brecha dentro de la celda, y la calibración externa (ITAN) fija ε. Deja a `NTA.do`, `PerfilesSim.do`, `TasasEfectivas` y los Sankeys la misma base por persona de siempre, con otra cola alta.

## §2 Entradas

| Base | Fuente / institución | Vintage usado | Variables clave | Llave única | Sello | Fuente de la fila |
|---|---|---|---|---|---|---|
| ENIGH 2024 `ingresos.dta` (P023–P025, P031 arrendamiento; P068–P081 negocios; P012, P013, P019–P022, P049 honorarios y utilidades; P001–P009, P011, P014–P016, P018 salarios) | INEGI | 2024 (asset `2024.zip`; descriptor `raw/ENIGH/2024/Documentos/Descriptor de archivos.pdf`) | `clave`, `ing_anual`, `factor`, `sinco` | `folioviv foliohog numren id_trabajo clave` | verde | `H` §2 (l. 599–700); descriptor pp. 214–218 del texto extraído |
| CSI_115 S.14, 2024 revisada: f.59 B.2b, f.69 B.2n, f.70 B.3n, f.71 D.1, f.95 D.4, f.97 D.42, f.98 D.421, **f.99 D.422**, f.103 D.442 | INEGI SCNM base 2018 | asset `raw/SCN/scn-congelado-2024.zip` (`manifest.json: scn_vintage.csi`, CSI_115 sha256 `f0e9fecf…`) | `D422Hog` (nuevo), `MixNHogS14`, `ExNOpHogS14`, `RentaPropHogR/U`, `D442Hog`, `YAHogS14` | cuadro + fila + columna (AS = 2024 R/P) | amarillo | `S` l. 2677 (spec `"CSI_115 99 D422Hog D.422 R"`), l. 605–648 |
| ITAN 4T 2024, hoja «I.II RecGobFed a) ISR», ISR de PF con y sin actividad empresarial por 12 rangos de ingreso anual declarado | SHCP, Informes Trimestrales | `master/itan-isr-rangos.dta` (asset `itan-congelado.zip`, catálogo `itan-catalogo.json` 2026-11-07) | `rango`, `tipo ∈ {pfae, pfsae}`, `mdp` | `anio trimestre rango tipo` | verde | `H` §1.4b (l. 399–457), §11.2 |
| CSVM 2024, alquiler imputado 1,886.385 | INEGI, boletín 47/25 (2025-11-21) | (no en repo: cita literal en CUAD-0 §10 bis 7) | — | — | amarillo | CUAD-0 §10 bis 7 |
| del Castillo (2023), cap. III §3 y §5 | CEPAL LC/TS.2023/44 | PDF congelado `metodo/fuentes/S2300345_es.pdf` | pp. 232–242, 268–273; cuadros 69–74, 92 | — | verde | `metodo/fuentes/README.md` |

## §3 Procedimiento (lo que cambia en 8.17.2; el resto es CUAD-0 §3)

| # | Qué hace | Qué conserva | Dónde está |
|---|---|---|---|
| 0 | `SCN.ado` lee D.422 S.14 (f.99 R/P) con rótulo verificado y lo expone como `D422Hog`; la lista de series S.14 de `master/SCN.dta` gana la variable (si falta, se releen todas) | Σ D.421 + D.422 = D.42 (f.97) al peso | `S` l. 70, 79, 2633, 2677, 2810, 605–648 |
| 1 | `Households` §0 arma las anclas: `MixAncla` = B.3n + D.422 (`ing_mixto_ancla = b3n_d422`), `D4Hog` = D.4 neto − D.442 − D.422; con `b3n` nada cambia | D.1 + B.3n + B.2n + D.4 neto − D.442 = B.5n S.14 − D.442 (la identidad de sectores) | `H` §0 (tras `local D4Hog`) |
| 2 | §3 construye `ing_mixto` sin `ing_t4_cap3` (`rentas_celda = b2n`): honorarios + negocios; `cap3` queda como variable propia con `exen_t4_cap3` | componentes = agregado | `H` §3 l. 1282 |
| 3 | §9 calcula los factores medios `TaltimirSal` = D.1/Σ y `TaltimirSelf` = MixAncla/Σ, y para D.1 y B.3n el factor **por persona** g_i = 1 + brecha × Y_i^(ε−1)/Σ_j w_j Y_j^ε; con ε = 1 toma el camino literal `g_i = Taltimir` (byte-idéntico a v8.17.1). B.2n (alquiler imputado + rentas efectivas) con `TaltimirHouse` uniforme; D.4 por `Distribucion` ∝ `ing_d4_rel`; ROWTrans uniforme | Σ_i w_i Y_i g_i = ancla (gate 1e-9); componentes y exenciones de `ing_mixto` con el mismo g_i de la persona | `H` §9 (bloque `altimir == "yes"`) |
| 4 | §9 imprime el cuadro «Brecha ENIGH–SCN repartida ∝ Y^ε por celda» (ε, ancla, Σ ENIGH, brecha, g medio, g en p50/p90/p99 de Y) | — | `H` §9 |
| 5 | §11.1 recalcula la obligación de asalariados sobre la base ajustada (la tarifa, el share acotado y el corte `imss` no cambian); el residuo Σ obligación(formales) − LIF se imprime como **evasión identificable** si ≥ 0 y como subreporte residual (FLAG 27, sello rojo) si < 0; cuadro de validación (Gini y top shares de YL, salario de SINCO 1, base gravable / salarios) | Σ ISR_asalariados de los formales → LIF al repartir (TasasEfectivas/PerfilesSim), como antes | `H` §11.1 |
| 6 | §11.2 ancla la obligación de PF por rango del ITAN como en 8.16b; la calibración de ε compara la **obligación estatutaria por rango** (Σ motor del cuadro «ISR de personas físicas por rango») con el ITAN | Σ ISR_PF = ITAN PF (gate) | `H` §11.2 |
| 7 | `NTA.do` ancla YA a YAHogS14 − D.442 − ⅔ D.422 y YL a D.1 + ⅔ (B.3n + D.422); `test-nta-identidad.do` igual | Σ S de las personas = B.8n S.1; factor YA = 1 | `N` §4.3b, cuadro 3; `05_scripts/test-nta-identidad.do` |

## §4 Decisiones: cada cambio de 8.17.2 como parámetro

| Parámetro | Propuesto (default 8.17.2) | Alternativas | FLAG | Memo | Qué cambia si se mueve |
|---|---|---|---|---|---|
| `rentas_celda` | **`b2n`** | `b3n` (v8.15b–v8.17.1) | «rentas efectivas de hogares en B.2n» (FLAG 18 cerrado) | §4.1; `dC p.232`, cuadro 69; SNA §24.55 | `ing_t4_cap3` (110.753 crudos) se ancla con `TaltimirHouse` a B.2n junto con el alquiler imputado y viaja en Yk; B.3n pierde las rentas. Factores: House 2.5860 → 1.9671; Self 3.6848 → 3.9144 (sin D.422). Totales de Yl, Yk, Σ S iguales; cambia quién recibe la brecha |
| `ing_mixto_ancla` (nuevo) | **`b3n_d422`** | `b3n` (v8.15b–v8.17.1) | «celda de negocios = B.3n + D.422» (sello amarillo: cuasisociedades) | §4.2; `dC p.232`, cuadros 69 y 71 | La ancla de `ing_mixto` es 7,606.727 (factor 4.2800); D.422 (649.743) sale de la celda D.4 (4,997.037 → 4,347.294). YL +433.162, YA −433.162; `CUADRATURA` YL 43.636 → 44.923 %, YA 24.435 → 23.148 %; la obligación de PF con negocios sube con la base |
| `altimir_elasticidad` (nuevo) | **`1.45`** | `1` (Altimir, v8.17.1), `1.75` (del Castillo), cualquier ε ∈ [1, 3] | «brecha ENIGH–SCN repartida ∝ Y^ε» | §4.3, Tablas 3a–3c; `dC p.238` | Con ε > 1 la brecha de D.1 y B.3n se concentra arriba: sube la obligación de asalariados y de PF en los rangos altos, el Gini de YL y los top shares; el total por celda no cambia. Con ε = 1 el motor es byte-idéntico a v8.17.1 (gate R0) |

**Decisiones ya vivas que esta sesión toca sin cambiar** (CUAD-0, CUAD-1): `d4_relativo = proxy_propiedad` (D.4 sin ε, sello rojo), `cuotas_d614 = neto` (D.442 fuera de YA), `isras_share = acotado`, `informalidad = corte`, `ancla_formales = imss` (N = 25,500,447), `obligacion_isrpf_ancla = itan_rangos`. La única regla que se reescribe es la lectura del residuo de FLAG 27 (§8).

### §4.0 — Las decisiones de Ricardo (2026-11-08) y lo que falta firmar

Las decisiones 1–4 están en `CEPAL-delCastillo-2023-lecciones.md` (transcripción del prompt: el adjunto original no llegó; se volvió a buscar en la sesión del ritual, 2026-11-09, sin resultado). Lo que este memo **propuso** y Ricardo firmó al leer el PR: (a) el valor de ε\* y la regla de redondeo (§4.3); (b) que el residuo de FLAG 27 con ε\* se publique como «evasión identificable» cuando sale ≥ 0 (§8); (c) el sello amarillo de la celda B.3n + D.422 por las cuasisociedades. La lista cerrada está al final.

**Firma (Ricardo Cantú, PR #71, comentario del 2026-11-09T03:59Z, https://github.com/rcantuc/SimuladorCIEP/pull/71#issuecomment-6731894072), textual:**

> Firmo CUAD-3 §4.0: rentas_celda = b2n (cierra FLAG 18); ing_mixto_ancla = b3n_d422; altimir_elasticidad = 1.45 (ε* calibrado al ITAN 4T 2024, meseta 1.35–1.50; aplica igual a D.1 y B.3n); estadístico L1 sobre 9 rangos; FLAG 27 abierto y declarado (−212.3 bn, no se publica evasión); FLAG 45 D.59 declarado. Pendiente para la sesión del ritual: sustituir la transcripción de CEPAL-delCastillo-2023-lecciones.md por el original. — Ricardo Cantú, 2026-11-08

Los tres parámetros firmados son los defaults de `SIM.do` §0.8 desde v8.17.2 (merge `68a2375`). **FLAG 46 (añadido en el ritual, 2026-11-09):** la partición ⅔ trabajo / ⅓ capital de `ing_mixto` (`ing_mixtoL`, `ing_mixtoK`; convención NTA de CUAD-0 §3 paso 3) se aplica **también a D.422** una vez que entra a la celda de los negocios: los retiros de cuasisociedades llegan como ingreso laboral en dos tercios y como ingreso de capital en un tercio por herencia de la convención, no por un hallazgo sobre su naturaleza (en el SCN son renta de la propiedad). Es un parámetro futuro (p. ej. `d422_particion = nta | capital`); con `capital` YL bajaría 433.162 bn y YA subiría lo mismo respecto a v8.17.2. Declarado en §8.

### §4.1 — Rentas efectivas → B.2n (decisión 1; cierra FLAG 18)

| Concepto | Valor (bn 2024) | Fuente |
|---|---:|---|
| B.2b S.14 excedente bruto de operación | 2,107.569 | CSI_115 f.59 |
| Alquiler imputado, CSVM 2024 (bruto) | 1,886.385 | INEGI boletín 47/25 (CUAD-0 §10 bis 7) |
| Diferencia = renta efectiva de inmuebles que vive en B.2 de hogares | **+221.184** (11.7 % de B.2b; 0.66 % del PIB) | aritmética |
| B.2n S.14 (celda neta que ancla) | 910.359 | CSI_115 f.69 |
| Σ ENIGH cruda del alquiler imputado (`ing_estim_alqu`) | 352.038 | `L` l.665; CUAD-0 Tabla 1 |
| Σ ENIGH cruda de rentas efectivas `ing_t4_cap3` = P023 tierras + P024/P025 casas, edificios, locales e inmuebles (dentro y fuera del país) + P031 otros | **110.753** | `L` l.664 (1,888.030 − 1,777.277); CUAD-0 Tabla 1; descriptor ENIGH 2024 (`arrenda` = P023–P031) |
| Factor de B.2n con `b3n` (solo alquiler imputado) | 2.5860 | `L` l.665 |
| **Factor de B.2n con `b2n`** (alquiler imputado + rentas) = 910.359 / 462.791 | **1.9671** | `R0`/`Rε` cuadro «Factores Altimir»; v8.15b r2 |
| Factor de B.3n con `b3n` (base 1,888.030 con rentas) | 3.6848 | `L` l.664 |
| **Factor de B.3n sin rentas** (base 1,777.277) | **3.9144** (4.2800 con D.422, §4.2) | aritmética; `Rε` |

Sustento (citas literales en §10 bis): `dC p.232` «el Sistema de Cuentas Nacionales incluye, en el rubro B.2b Excedente bruto de operación del sector Hogares (S.14), la renta de los inmuebles, más la renta imputada de las viviendas que las familias ocupan»; cuadro 69 (`dC p.233`) pone X017 «Alquiler de casas, edificios e inmuebles» (= P024/P025 de la ENIGH 2024) en el grupo de B.2b; SNA 2008 §24.55 «all the value added arising from leasing dwellings is treated as operating surplus, not mixed income». Lo que sostuvo `b3n` en v8.15b (SNA §7.9, §7.19(c); INEGI p. 33 y 45) habla del excedente de la producción por cuenta propia de servicios de vivienda y no niega que el arrendamiento a terceros sea excedente: **se leyó de más**; queda como nota en CUAD-0 §10 bis 7. Las rentas de la ENIGH son 110.753 crudos contra una celda implícita de 221.184 brutos: la ENIGH ve la mitad (sin descontar el consumo de capital fijo del arrendador, que INEGI no publica aparte).

### §4.2 — Celda de negocios = B.3n + D.422 (decisión 2)

**D.422 existe y se publica.** CSI_115, cuenta II.1.2 asignación del ingreso primario, S.14 recursos 2024: f.95 D.4 6,116.263 = f.96 D.41 544.940 + f.97 D.42 4,779.531 (= f.98 D.421 dividendos 4,129.787 + **f.99 D.422 retiros de los ingresos de cuasi sociedades 649.743**) + f.101 D.44 735.471 + f.105 D.45 56.321. `SCN.ado` lo lee como `D422Hog` con el rótulo verificado (`S` l. 2677) y lo imprime en el cuadro «Celdas CSI del sector hogares» (`Rε` l. 2989: 762.665 para 2027 proyectado; 649.743 en 2024, l. 3206).

| Concepto | Valor (bn 2024) | Fuente |
|---|---:|---|
| Σ ENIGH cruda de negocios propios P068–P081 (`ing_t2_cap1` 900.869 + `ing_t2_cap8` 118.262) | 1,019.131 | CUAD-0 Tabla 1; `L` |
| Σ ENIGH cruda de honorarios y utilidades `ing_t4_cap2` (P012, P013, P019–P022, P049) | 758.146 | CUAD-0 Tabla 1 |
| de los cuales P012/P019 «ganancias/utilidades» = `utilidad` del descriptor INEGI («cooperativas, sociedades y empresas que funcionan como sociedades»: X007/X008 de del Castillo) | ≈ 68 % de los honorarios crudos (475.2 de 699.8 con el factor de `concentrado`; aproximación, no es la base del motor) | `raw/ENIGH/2024/ingresos.dta` + descriptor #45 |
| Base cruda de la celda (sin rentas, `b2n`) | **1,777.277** | `L` l.664 − 110.753 |
| B.3n S.14 | 6,956.984 | CSI_115 f.70 |
| D.422 S.14 recursos | **649.743** | CSI_115 f.99 |
| **Celda B.3n + D.422** | **7,606.727** | aritmética |
| Factor antes (`b3n`, con rentas, sin D.422) | 3.6848 | `L` |
| Factor después (`b3n_d422`, sin rentas) | **4.2800** | `Rε` cuadro «Factores Altimir» |
| Celda D.4 de `ing_capital`: D.4 neto 5,602.969 − D.442 605.932 − D.422 649.743 | 4,997.037 → **4,347.294** | `Rε` |
| YL = D.1 + ⅔ (B.3n + D.422) | 14,690.951 → **15,124.113** (+433.162) | aritmética; gate §9.1 |
| YA = B.2n + ⅓ (B.3n + D.422) + D.4 neto − D.442 − D.422 | 8,226.391 → **7,793.229** (−433.162) | aritmética; gate §9.1 |

Por qué D.422 va con los negocios y no con la renta de la propiedad: la ENIGH pregunta por el ingreso del negocio (P068–P081) o por «ganancias/utilidades» (P012/P019) sin saber si el negocio lleva cuentas completas; INEGI clasifica como cuasisociedad al que las lleva y manda su excedente a S.11 y su retiro a D.422 de S.14 (INEGI 2014 p. 12, CUAD-0 §10 bis 2). Del Castillo (`dC p.232`, cuadro 71) compara el ingreso mixto de la encuesta con B.3b + D.422. El principio B se respeta: D.422 sigue siendo un recurso de S.14 que llega a personas; cambia la regla (de P ∝ `ing_d4_rel`, sello rojo, a I ⅔ · P ⅓ con la distribución de los negocios declarados). **Sello amarillo**: la ENIGH no identifica cuasisociedades y el factor 4.28 mezcla subreporte con cobertura.

### §4.3 — `altimir_elasticidad`: la brecha repartida ∝ Y^ε (decisión 3)

**Definición** (`dC p.238`, ecs. 3–4): factor_i = (Y_i / Σ Y)^ε, ponderador_i = factor_i / Σ factor; a cada persona se le suma brecha_celda × ponderador_i. En el motor, con pesos de expansión w_i: Y_i' = Y_i + brecha × Y_i^ε / Σ_j w_j Y_j^ε, es decir g_i = Y_i'/Y_i = 1 + brecha × Y_i^(ε−1) / Σ_j w_j Y_j^ε. Con ε = 1, g_i = ancla / Σ ENIGH = `Taltimir` (Altimir 1975/1987; Hernández-Laos; v8.15b–v8.17.1). Aplica a D.1 (`ing_subor`) y a B.3n + D.422 (`ing_mixto`, sus componentes y exenciones con el g_i de la persona). **No** aplica a B.2n (alquiler imputado + rentas: factor uniforme), a D.4 (`Distribucion` ∝ `ing_d4_rel` entre declarantes, CUAD-0) ni a ROWTrans. Si la ENIGH superara a la celda (brecha ≤ 0) el factor es uniforme y se imprime FLAG. Implementación: una sola rutina en `H` §9 para las dos celdas; con ε = 1 el código toma el camino literal `replace x = x × Taltimir` y el resultado es byte-idéntico a v8.17.1 (gate R0: §7).

**Tabla 3a — Sensibilidad a ε (celdas nuevas `b2n` + `b3n_d422`; base v8.17.1 en la primera fila).** Σ obligación estatutaria de ISR de asalariados (toda la base del probit, share acotado), formales con `ancla_formales = imss`, residuo Σ obligación(formales) − LIF 1,253.785 (FLAG 27), Gini de YL por hogar (`Gini.ado`), top-1 % y top-10 % del ingreso laboral entre personas con YL > 0, salario mensual medio de «Funcionarios y directivos» (SINCO división 1, asalariados con `ing_subor` > 0) para comparar con la validación de del Castillo (cuadro 74: ENIGH 2018 53,716 → 282,110 MXN mensuales ajustado), y base gravable de asalariados / salarios ajustados (del Castillo supone 0.85).

| ε | Celdas | Σ obligación asalariados (bn) | Formales (M) | Σ obligación formales (bn) | Residuo vs LIF 1,253.785 (bn, %) | Gini YL (hogar) | Top 10 % YL (%) | Top 1 % YL (%) | Salario SINCO 1 (miles MXN/mes) | Base gravable / salarios | g p99: D.1 / B.3n |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1.00 | v8.17.1 (b3n, b3n) | 1,282.675 | 25.500 | 1,016.584 | -237.200 (-18.92 %) | 0.523 | 39.7 | 12.5 | 47.3 | 0.869 | 1.0841 / 3.6848 |
| 1.00 | b2n + b3n_d422 | 1,282.913 | 25.500 | 1,016.527 | -237.257 (-18.92 %) | 0.526 | 40.4 | 13.0 | 47.3 | 0.869 | 1.0841 / 4.2800 |
| 1.25 | b2n + b3n_d422 | 1,292.630 | 25.500 | 1,030.218 | -223.567 (-17.83 %) | 0.569 | 44.6 | 17.9 | 48.3 | 0.869 | 1.1060 / 4.1995 |
| 1.35 | b2n + b3n_d422 | 1,296.563 | 25.500 | 1,035.812 | -217.972 (-17.39 %) | 0.588 | 46.4 | 20.3 | 48.8 | 0.869 | 1.1145 / 3.9319 |
| 1.40 | b2n + b3n_d422 | 1,298.549 | 25.500 | 1,038.630 | -215.154 (-17.16 %) | 0.598 | 47.3 | 21.6 | 49.1 | 0.869 | 1.1185 / 3.7498 |
| 1.45 | b2n + b3n_d422 | 1,300.546 | 25.500 | 1,041.461 | -212.324 (-16.93 %) | 0.608 | 48.1 | 22.9 | 49.4 | 0.869 | 1.1224 / 3.5416 |
| 1.50 | b2n + b3n_d422 | 1,302.548 | 25.500 | 1,044.297 | -209.488 (-16.71 %) | 0.618 | 49.0 | 24.1 | 49.7 | 0.869 | 1.1260 / 3.3140 |
| 1.75 | b2n + b3n_d422 | 1,312.582 | 25.500 | 1,058.377 | -195.408 (-15.59 %) | 0.659 | 52.6 | 29.7 | 51.4 | 0.869 | 1.1399 / 2.1612 |
| 2.00 | b2n + b3n_d422 | 1,321.521 | 25.500 | 1,071.117 | -182.668 (-14.57 %) | 0.684 | 54.8 | 33.1 | 53.6 | 0.869 | 1.1432 / 1.4368 |

**Tabla 3b — Calibración contra el ITAN 4T 2024** (`master/itan-isr-rangos.dta`, PF con y sin actividad empresarial, mdp → bn). Para cada ε, la **obligación estatutaria de PF del motor** acumulada por rango de ingreso anual declarado (`base_isr_pf` = `ing_bruto_tax` + negocios; columna «Σ motor» del cuadro «ISR de personas físicas por rango») se compara con el ISR del ITAN por rango. Como la obligación del motor (≈ 1,000 bn) es un múltiplo de la recaudación (77.117), se comparan **participaciones**: estadístico L1 = Σ_r |s_motor,r − s_ITAN,r| sobre los 9 rangos con ITAN ≥ 0 y personas en la ENIGH (r = 1, 4–10; los rangos 2 y 3 son devoluciones netas y «Más de 500 mil» no tiene personas en la ENIGH), y Δ del top observable (r = 10, «100,000 ≤ 500,000 mil»). ε\* = el que minimiza L1.

| Rango (MXN anuales declarados) | ITAN 4T 2024 (bn) | ITAN share (%) | ε = 1.00 v8.17.1: Σ motor (bn) / share (%) | ε = 1.00: Σ motor (bn) / share (%) | ε = 1.25: Σ motor (bn) / share (%) | ε = 1.35: Σ motor (bn) / share (%) | ε = 1.40: Σ motor (bn) / share (%) | ε = 1.45: Σ motor (bn) / share (%) | ε = 1.50: Σ motor (bn) / share (%) | ε = 1.75: Σ motor (bn) / share (%) | ε = 2.00: Σ motor (bn) / share (%) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1: 0–250 mil | 8.038 | 10.6 | 57.833 / 8.7 | 52.770 / 6.6 | 56.476 / 6.5 | 56.980 / 6.4 | 57.413 / 6.5 | 58.738 / 6.6 | 58.353 / 6.6 | 61.321 / 6.8 | 59.520 / 6.6 |
| 4: 750 mil–1 M | 0.070 | 0.1 | 107.100 / 16.2 | 128.150 / 16.0 | 96.739 / 11.1 | 77.343 / 8.8 | 69.507 / 7.8 | 59.799 / 6.7 | 49.995 / 5.6 | 33.224 / 3.7 | 21.659 / 2.4 |
| 5: 1–5 M | 17.093 | 22.5 | 356.100 / 53.8 | 442.470 / 55.1 | 387.145 / 44.3 | 338.109 / 38.3 | 317.023 / 35.7 | 291.678 / 32.7 | 264.876 / 29.8 | 145.181 / 16.1 | 89.638 / 9.9 |
| 6: 5–10 M | 10.235 | 13.5 | 57.128 / 8.6 | 79.461 / 9.9 | 94.755 / 10.8 | 94.118 / 10.7 | 87.686 / 9.9 | 84.589 / 9.5 | 83.237 / 9.4 | 54.261 / 6.0 | 27.135 / 3.0 |
| 7: 10–20 M | 10.445 | 13.7 | 26.310 / 4.0 | 27.799 / 3.5 | 47.136 / 5.4 | 54.323 / 6.1 | 53.087 / 6.0 | 53.121 / 6.0 | 48.541 / 5.5 | 33.603 / 3.7 | 15.279 / 1.7 |
| 8: 20–50 M | 9.241 | 12.2 | 15.398 / 2.3 | 18.155 / 2.3 | 43.787 / 5.0 | 48.199 / 5.5 | 50.475 / 5.7 | 52.411 / 5.9 | 49.773 / 5.6 | 41.434 / 4.6 | 26.305 / 2.9 |
| 9: 50–100 M | 4.940 | 6.5 | 10.732 / 1.6 | 17.950 / 2.2 | 10.959 / 1.3 | 20.959 / 2.4 | 22.649 / 2.6 | 24.001 / 2.7 | 28.819 / 3.2 | 22.286 / 2.5 | 16.392 / 1.8 |
| 10: 100–500 M | 7.834 | 10.3 | 30.850 / 4.7 | 36.071 / 4.5 | 41.387 / 4.7 | 53.847 / 6.1 | 62.931 / 7.1 | 69.705 / 7.8 | 69.767 / 7.8 | 91.574 / 10.2 | 85.265 / 9.5 |
| 11: > 500 M | 8.120 | 10.7 | 0.000 / 0.0 | 0.000 / 0.0 | 95.107 / 10.9 | 139.700 / 15.8 | 166.957 / 18.8 | 197.239 / 22.1 | 236.510 / 26.6 | 416.386 / 46.3 | 559.975 / 62.1 |
| **L1 (9 rangos, pp)** | | | **94.9** | **97.0** | **66.0** | **59.1** | **58.2** | **56.6** | **57.4** | **78.4** | **107.5** |
| L1 (rangos ≥ 1 M, pp) | | | 93.1 | 92.0 | 59.7 | 53.3 | 53.0 | 52.3 | 54.1 | 79.6 | 112.7 |
| Δ top > 500 M (share motor − ITAN, pp) | | | -10.7 | -10.7 | +0.2 | +5.1 | +8.1 | +11.4 | +15.9 | +35.6 | +51.5 |
| Σ motor total PF (obligación, bn) | | | 976.788 | 1,138.728 | 1,131.986 | 1,114.043 | 1,102.405 | 1,089.560 | 1,075.957 | 1,013.690 | 981.034 |

Rangos excluidos del estadístico: 2 y 3 (ITAN negativo: devoluciones netas) y «Resto» (sin declaración anual). ITAN 4T 2024 PF (pfae + pfsae) = 77.117 bn.

**Lectura.** Con ε = 1 (uniforme) el motor pone el 54 % de la obligación de PF en el rango de 1–5 millones y nada arriba de 500 millones, donde el ITAN recauda el 10.7 %; al subir ε la cola alta se puebla (ε = 1.25: 10.9 %, igual que el ITAN) y el rango 1–5 M baja. El estadístico L1 baja de 94.9 pp (ε = 1) a 66.0 (1.25), 59.1 (1.35), 58.2 (1.40), **56.6 (1.45)** y 57.4 (1.50), y vuelve a subir a 78.4 (1.75) y 107.5 (2.0) porque el rango «más de 500 millones» se dispara (46 % y 62 % de la obligación contra 10.7 % del ITAN): **ε\* = 1.45**. El 1.75 de del Castillo sobreajusta la cola en México 2024 con la base del motor (su D.1 de 2018 tenía factor 1.59; el del motor es 1.08 porque el salario ya lleva el gross-up de cuotas). El mismo ordenamiento sale con el estadístico restringido a los rangos ≥ 1 millón (52.3 pp en 1.45). La desviación que ningún ε corrige es la del rango 750 mil–1 millón (ITAN 0.1 %: ahí las personas pagan por retenciones, no por declaración de PF) y la del rango 0–250 mil.

**Nota metodológica.** El rango del ITAN es de *ingreso anual declarado* (nota 1_/ del cuadro de la SHCP) y se mapea a `ing_bruto_tax` + negocios anuales de la persona (CUAD-1 decisión 9); dentro del rango manda la distribución de la ENIGH. Las retenciones por salarios **no** sirven por rango (ordenan al retenedor: 584.5 de los 1,254.8 bn caen en «más de 500 millones»), así que la calibración es sobre PF y la validación de asalariados es por total (Tabla 3a) y por el SINCO (cuadro 74 de del Castillo). El ITAN es recaudación efectiva y la columna del motor es obligación estatutaria: la distancia por rango mezcla subreporte, elusión y evasión, por eso se calibra en participaciones y no en niveles.

**Tabla 3c — Sensibilidad publicada: qué llaves de `output.txt` se mueven entre ε = 1 y ε\*** (con las celdas nuevas en ambos), INCD por decil (ISR asalariados, bloque 12), `APORT*`, `INGRESOSTEF`, y Σ S sin ancla vs B.8n S.14.

Corridas completas: `02-full-eps1-celdas-nuevas` (ε = 1, `b2n` + `b3n_d422`) y `01-sim-completo` (ε\* = 1.45, mismas celdas); la primera columna es v8.17.1 (`L`). Bloques `INCD` = per cápita anual (MXN) por decil, en el orden de las llamadas a `Simulador`; `INCD2` = participación del decil X.

| Bloque `INCD` (per cápita anual, MXN) | Decil I: v8.17.1 → ε = 1 nuevas → ε\* | Decil X: v8.17.1 → ε = 1 nuevas → ε\* | Nacional | Participación del decil X (`INCD2`, %): v8.17.1 → ε = 1 → ε\* |
|---|---|---|---|---|
| 1 Yl | 38,144 → 30,353 → 29,287 | 1,144,717 → 1,202,826 → 1,524,416 | 378,338 → 389,493 → 389,493 | 30.3 → 30.9 → 39.1 |
| 2 Yk | 51,841 → 49,110 → 50,133 | 1,622,323 → 1,598,949 → 1,671,167 | 378,158 → 367,003 → 367,003 | 42.9 → 43.6 → 45.5 |
| 3 ingbrutotot | 68,353 → 56,907 → 55,545 | 2,223,336 → 2,262,717 → 2,699,446 | 620,739 → 620,739 → 620,739 | 35.8 → 36.5 → 43.5 |
| 6 Ahorro | −266,660 → −279,493 → −276,908 | 1,096,125 → 1,140,597 → 1,534,938 | 8,998 → 8,998 → 8,998 | 1,218.1 → 1,267.6 → 1,705.9 |
| 11 ing_subor | 208,862 → 191,606 → 174,819 | 1,148,809 → 1,147,290 → 1,231,073 | 602,962 → 602,962 → 602,962 | 19.7 → 19.4 → 22.5 |
| 13 ISRAS | 35,207 → 31,111 → 26,933 | 388,043 → 390,467 → 406,061 | 174,412 → 174,413 → 174,517 | 34.1 → 33.6 → 39.0 |
| 14 ISRPF | 458 → 515 → 273 | 47,428 → 46,941 → 56,975 | 12,900 → 12,886 → 13,281 | 83.5 → 82.7 → 88.4 |
| 16 Laboral | 15,687 → 13,214 → 8,997 | 272,443 → 270,085 → 309,951 | 144,297 → 144,179 → 145,256 | 32.3 → 31.9 → 36.3 |
| 17 ISRPM | 9,426 → 9,213 → 10,082 | 243,930 → 245,734 → 237,180 | 66,085 → 66,085 → 66,085 | 42.7 → 42.4 → 40.6 |
| 32 ImpuestosAportaciones | 43,047 → 43,199 → 43,040 | 569,170 → 564,329 → 585,174 | 185,629 → 185,629 → 185,629 | 30.7 → 30.4 → 31.5 |
| 43 AportacionesNetas | −168,078 → −179,753 → −167,273 | 413,579 → 411,948 → 433,969 | 30,987 → 30,987 → 30,987 | 133.5 → 132.9 → 140.0 |

Lectura: entre ε = 1 y ε\* (mismas celdas) cambian 406 de las 509 líneas de `output.txt` (5,700 números); las celdas nuevas solas (v8.17.1 → ε = 1) mueven 401 líneas y los totales nacionales de Yl (+11,155 per cápita: ⅔ D.422) y Yk; ε mueve solo el reparto: el decil X gana 8.2 puntos de participación en Yl (30.9 → 39.1), 5.4 en el ISR de asalariados (33.6 → 39.0) y 5.7 en el ISR de personas físicas (82.7 → 88.4); la Laboral del decil I baja de 13,214 a 8,997 porque la obligación se desplaza arriba con el mismo total LIF. `INGRESOS`, `INGRESOSTEF`, `GASTOS*` y `PIBY` no cambian (anclas LIF/PEF; la tasa efectiva del ISR PM sigue sobre B.2n S.11 + S.12); `PROY*` cambia en segundo orden (ISR proyectado por decil; p. ej. el primer bloque 10.847/12.266/13.576 → 11.044/12.519/13.946 % del PIB) y `PROYMAX` del bloque de aportaciones netas un año (2069 → 2070, 2055 → 2056). `APORT*` (aportaciones por edad y sexo, % del total) se redistribuye hacia las edades de 25–64 del decil X. Σ S sin ancla vs B.8n S.14: −19.4 bn (−1.0 %) en las tres corridas.

**Propuesta del memo.** Default = ε\* calibrado (redondeado a 0.05) si el ajuste al ITAN mejora claramente sobre ε = 1; si no, 1.75 de del Castillo con FLAG; alternativa 1. Resultado: **default `altimir_elasticidad = 1.45`** (ε\*: L1 56.6 pp contra 94.9 con ε = 1: mejora clara); alternativas `1` (Altimir uniforme, v8.17.1) y `1.75` (del Castillo, L1 78.4), ambas corren con FLAG. Ricardo puede preferir 1.50 (L1 57.4, misma meseta) o el 1.75 de la literatura: la diferencia entre 1.45 y 1.50 es de 0.8 pp de L1, 1 punto de Gini de YL y 2.8 bn de obligación de asalariados (Tabla 3a).

### §4.4 — Verificación con del Castillo

| Prueba | del Castillo | Motor (v8.17.1 → ε\*) | Lectura | Fuente |
|---|---|---|---|---|
| Base gravable de asalariados / salarios ajustados | 0.85 (`dC p.241`: 15 % exento y contribuciones) | 0.869 → 0.869 | gate informativo (cuadro de validación, `H` §11.1) | `R0`, `R1.45` |
| Salario mensual medio de funcionarios y directivos (SINCO 1) | 53,716 sin ajuste → 282,110 ajustado (2018, sector financiero privado, cuadro 74) | 47.3 → 49.4 miles de MXN (2024, todos los sectores, asalariados con `ing_subor` > 0) | sube 4.5 % con ε\* (53.6 mil con ε = 2): la brecha de D.1 del motor (780 bn, factor 1.08) es mucho menor que la de del Castillo en 2018 (factor 1.59, cuadro 71) porque `ing_subor` ya lleva el gross-up de cuotas y el ISR retenido; el salto 53 → 282 mil no es reproducible con esta celda | ídem |
| D.59 S.14 (otros impuestos corrientes: predial y tenencia) vs ENIGH | del Castillo imputa D.59 ∝ ingreso ajustado (`dC p.242`) | D.59 S.14 = D.5 1,540.050 − D.51 1,518.912 = **21.138**; ENIGH R004 predial 30.328 + R012 tenencia 23.116 = **53.444** crudos (reclasificados fuera del consumo en 8.16b, CUAD-1 ficha 6): la ENIGH **supera** la celda 2.5 veces | la celda CSI no recoge todo el predial estatal/municipal o la ENIGH lo sobrerreporta; en NTA viaja `TmenD59` anclado a 21.138 (CUAD-2) | CUAD-1 §8 bis ficha 6; CUAD-2 §4.0 bis |
| Cuadro 69 vs Tabla 1 de CUAD-0, clave por clave | ver abajo | | | `dC p.233`; `H` §2 |

**Cuadro 69 (del Castillo) frente a la Tabla 1 del motor, por celda:**

| Celda | del Castillo (base homologada X) | Motor (ENIGH 2024 P) | Diferencia |
|---|---|---|---|
| D.1 | X001–X006 (sueldos, comisiones, aguinaldo, primas, utilidades, trabajo secundario) **+ remuneraciones en especie YE001–YE009** | P001–P005, P007–P009, P011, P014–P016, P018 (+ P006 bono, P034–P036 indemnizaciones y P032 de no jubilados) | el motor no suma la especie de la ENIGH (la celda D.1 la contiene: se escala sobre lo monetario); las indemnizaciones (D.1 para el motor) del Castillo no las lista |
| B.3b + D.422 | X007–X008 cooperativas, sociedades y cuasisociedades; X009–X014 negocios industriales, comerciales, servicios, agrícolas, pecuarios y secundarios **+ autoconsumo YA001–YA038** | P012/P019 utilidades + P013/P020/P021/P022/P049 otros trabajos y honorarios + P068–P081 negocios | mismo perímetro de los negocios y de las utilidades de sociedades; el motor no suma el autoconsumo; desde 8.17.2 la celda incluye D.422 como en del Castillo (y es neta, B.3n, no bruta) |
| Renta de la propiedad | D.41 + D.421 + D.443 + D.451 + B.2b − alquiler imputado de la encuesta ↔ X016 tierras, **X017 casas e inmuebles**, X018–X021 intereses, X022 patentes, X023 otros | D.4 neto − D.442 − D.422 por `Distribucion` ∝ `ing_d4_rel` (P026–P029 intereses, P050 acciones, cap3, alquiler imputado, negocios como proxy); **P023–P025, P031 (X016, X017, X023) → B.2n desde 8.17.2**; P030 patentes fuera (inmaterial) | del Castillo ancla la renta de la propiedad **entre declarantes** porque su celda junta B.2b; el motor separa B.2n (alquiler + rentas) de D.4 y reparte D.4 por proxy (cobertura ENIGH 0.43 %, sello rojo); D.442 y D.422 salen de D.4 en el motor (circuito de pensiones y cuasisociedades) |
| Transferencias | D.62 + D.752 + D.759 − X040 ↔ X024 jubilaciones, X027–X036 becas, donativos, remesas, programas, P109/P114/P115 | pensiones (D.62) y programas anclados al PEF en NTA; remesas a ROWTrans BIE; donativos y becas con factor 1 fuera de Yl/Yk (CUAD-0) | el motor no escala transferencias a la celda D.62 + D.7 de la CSI: las ancla al PEF por programa (CUAD-0 §4, CUAD-2) |

## §5 Anclas (Tabla 1 de CUAD-0, filas que cambian)

| Variable (`H`) | Celda SCN | Valor SCN | Σ motor antes del ancla | Factor v8.17.1 | **Factor 8.17.2** | Regla | Sello |
|---|---|---:|---:|---:|---:|---|---|
| `ing_subor` | D.1 S.14 (f.71) | 10,052.962 | 9,272.904 | 1.0841 (uniforme) | 1.0841 medio; g_i ∝ Y^ε: p50 1.0254, p90 1.0755, p99 1.1224 (ε\* = 1.45) | I, ε | amarillo |
| `ing_mixto` = honorarios + negocios | B.3n + D.422 (f.70 + f.99) | 7,606.727 (6,956.984 + 649.743) | 1,777.277 | 3.6848 (sobre 1,888.030 con rentas, celda 6,956.984) | 4.2800 medio; g_i ∝ Y^ε: p50 1.0000, p90 2.2337, p99 3.5416 (ε\* = 1.45: la brecha va al 1 % superior de los negocios; por eso el p99 baja al subir ε) | I ⅔ · P ⅓, ε | amarillo (cuasisociedades) |
| `ing_estim_alqu` + `ing_t4_cap3` | B.2n S.14 (f.69) | 910.359 | 352.038 + 110.753 = 462.791 | 2.5860 (solo alquiler) | **1.9671** uniforme | P | amarillo |
| `ing_capital` | D.4 neto − D.442 − D.422 (f.95, 103, 99) | 4,347.294 | relativo `ing_d4_rel` 1,503.626 − cap3 ya no entra… (ver nota) | 3.3233 | 2.8912 (celda 4,347.294 sobre el mismo relativo 1,503.626) | P ∝ proxy | **rojo** |
| `ing_remesas` | ROWTrans BIE | 1,186.091 | 141.526 | 8.3807 | 8.3807 | I | amarillo |

Nota: `ing_d4_rel` (proxy de D.4) sigue siendo cap6 + cap8 + cap3 + alquiler imputado + negocios **crudos** (CUAD-0 firma A.2): no cambia con `rentas_celda` ni con ε; solo cambia la celda que reparte (−649.743).

## §6 Salidas

| Archivo / JSON / figura | Qué cambia en 8.17.2 | Quién lo consume | Check |
|---|---|---|---|
| `master/2024/households.dta` | `ing_subor`, `ing_mixto*`, `ing_t4_cap3`, `exen_*`, `ing_capital`, `Yl`, `Yk`, `ISR*`; char `cuad_params` con los tres parámetros | todo el motor posterior | gate humano |
| `users/<id>/output.txt` | `CUADRATURA` (YL/YA), `INCD*` ISR/Laboral/Aportaciones, `APORT*`, `PROY*`, `INGRESOSTEF` donde el denominador cambie | sitio, sidecar | `gate-numeros.sh` ROJO esperado; `baseline = v8.17.2` |
| 5 `SankeySF/*.json`, 5 `SankeyNTA/*.json`, `NTA/*` | reparto por edad/decil de YL, YA, ISR | portada, `/NTA` | `gate-numeros.sh`, `test-nta-identidad.sh`, `test-sitio-nta.sh` |
| 32 entidades (`SIMentidad.ado`) | `INCD*` por entidad | `/entidades` | `contrato-32.sh` (c32 del ritual; fixtures en PR corto, como 8.16b) |
| Log de `Households`: cuadros «Brecha ∝ Y^ε por celda» y «Validación del ajuste» | nuevos | lectura humana; este memo | `test-log-ancho.sh` |

## §7 Identidades verificadas

Última corrida: `01-sim-completo` (defaults de CUAD-3, hash del PR; evidencia `diag-cuad-3-2026-11-08/`). Gates de Households §9.1 y §11.5, NTA y los tests de la sesión.

| Identidad | Tolerancia | Resultado | Fuente |
|---|---|---|---|
| Gate de la sesión: con `rentas_celda = b3n`, `ing_mixto_ancla = b3n`, `altimir_elasticidad = 1` el motor reproduce v8.17.1 | byte a byte (`output.txt`), 1e-9 (sankeys) | **VERDE**: `output.txt` byte-idéntico (51,892 bytes); 10 sankeys ≤ 3.0e-14 | `00-gate-eps1-celdas-v8171/gate-numeros.txt`; `03-bitcheck-eps1-celdas-v8171` |
| `gate-numeros.sh`: `output.txt` y 10 sankeys = baseline v8.17.1 | byte a byte / 1e-9 | **ROJO esperado** (404 de 509 líneas; SankeySF decil 80/104 enlaces, Δ rel. máx 0.35; SankeyNTA decil 113/143, 0.33); fixtures re-baselineados → VERDE contra la corrida | `01-sim-completo/gate-numeros.txt` |
| Households: Σ `ing_subor` = D.1 S.14 (10,052.962) con g_i ∝ Y^ε | 1e-9 | VERDE, reldif 0.0e+00 | `wrap.log` l. 844 |
| Households: Σ `ing_mixto` = B.3n + D.422 (7,606.727); componentes = agregado | 1e-9 | VERDE, reldif 1.3e-16 | l. 845, 848 |
| Households: Σ `ing_estim_alqu` + `ing_t4_cap3` = B.2n (910.359) | 1e-9 | VERDE, 0.0e+00 | l. 846 |
| Households: Σ `ing_capital` = D.4 neto − D.442 − D.422 (4,347.294) | 1e-9 | VERDE, 0.0e+00 | l. 847 |
| Households: YA = YAHogS14 − D.442 − ⅔ D.422 (7,793.229); Σ Yl = D.1 + ⅔ (B.3n + D.422) (15,124.113); Σ Yk − CCF | 1e-9 | VERDE, 0.0e+00 (los tres) | l. 849, 929, 930 |
| Households: PIB BIE = YL + YA + D.442 + B.5n S.11+S.12 + S.13 + S.15 + CCF + ROW + vintage (`CUADRATURA`: 44.923 + 23.148 + 1.800 + 2.833 + 4.735 + 0.347 + 19.181 + 2.782 + 0.252 = 100.000) | 1e-9 | VERDE, 0.0e+00 | l. 850; `output.txt` |
| Households: Σ ISR_PF = ITAN PF 4T 2024 (77.117); Σ ISR_PM = LIF (1,351.427) | 1e-9 | VERDE | l. 767, 794–795 |
| NTA: residual por persona; Σ intra nacional = 0; Σ S personas = B.8n S.1 (−308.425); factor YA = 1 | 1e-9 | VERDE (máx 2.0e-07 MXN por persona) | l. 1158–1159; `nta-identidad.txt` |
| NTA: Σ Cpriv = P.3 S.14; Σ ISR personas = D.51 S.14; cuotas por sector; IEPS; D.5; D.7; P.32; S_ret, S_def, S_isflsh | 1e-9 | VERDE (todos) | l. 1161–1200 |
| NTA: Sankey v4 57 nodos / 134 enlaces, conservación; panel 15 celdas | 1e-9 | VERDE (2.2e-14; 1.1e-14) | l. 1196–1197 |
| `test-nta-identidad.sh` | 1e-9 | VERDE (v3 35/99, v4 57/134, panel 15 celdas; ajuste S.14 −19.4 bn) | `diag-cuad-3-2026-11-08/test-nta-identidad.txt` |
| `test-web-batch.sh` (paridad web = batch) | llaves N/N | VERDE 47/47 (el «Calcular» default reproduce el `output.txt` del batch) | `diag-cuad-3-2026-11-08/test-web-batch.txt` |
| `test-log-ancho.sh` (110 columnas) | 0 líneas > 110 | VERDE en las 11 corridas de la sesión (la primera relectura de las series S.14 imprimía 122 líneas de 115 columnas: corregido con `quietly reshape`) | `*/test-log-ancho.txt` |
| Σ S sin ancla vs B.8n S.14 | informativo | −19.4 bn (−1.0 %), igual que v8.17.1 | `nta-identidad.txt` nota 1 |
| Contrato de las 32 (`contrato-32.sh`) | — | **no corrió en la sesión**: los fixtures de `/entidades` (banda de vintages) salen del paso `c32` del ritual y entran en un PR corto, como en 8.16b | — |

## §8 Límites conocidos

| # | FLAG | Magnitud | Estado en 8.17.2 |
|---|---|---:|---|
| 18 | B.2b S.14 > alquiler imputado CSVM 2024 (+221.184): «algo más vive en el B.2 de hogares» | 221.184 | **Cerrado**: son las rentas efectivas; `rentas_celda = b2n` (SNA §24.55; `dC p.232`, cuadro 69). La ENIGH ve 110.753 crudos de esa celda (50 % en bruto) |
| 27 | Residuo Σ obligación(formales) − LIF de asalariados | −237.200 (−18.92 %) en v8.17.1 → −212.324 (−16.93 %) con ε\* | **sigue abierto y declarado**: el residuo sigue negativo con cualquier ε ∈ [1, 2] (−237.2 → −182.7 bn), así que no hay evasión identificable: el motor subestima la obligación estatutaria de los 25.5 millones de formales aun con la brecha de D.1 concentrada arriba, porque la brecha de D.1 es solo 780 bn (8.4 % de la celda) y la mayor parte del ajuste cae en B.3n (5,829 bn), que no son asalariados. Se publica como subreporte residual con sello rojo (FLAG 27), no como evasión; la regla «≥ 0 = evasión identificable» queda en el código para cuando el ancla de formales o la celda cambien. Regla nueva (`H` §11.1): si ≥ 0 se publica como evasión identificable y entra al cuadro de cuatro componentes de CUAD-1 §4 bis; si < 0 se declara con sello rojo |
| 17 | Subreporte de top incomes (estructural) | — | **Tratado, no cerrado**: ε reparte la brecha conocida (la celda) hacia arriba; no repone lo que la celda misma no tiene (cuasisociedades en S.11, dividendos en D.421 con cobertura ENIGH < 1 %). D.4 sigue por proxy (sello rojo, 9.x) |
| 42 (nuevo) | La ENIGH no identifica cuasisociedades: el factor 4.28 de B.3n + D.422 mezcla subreporte y cobertura; D.422 es el 8.5 % de la celda | 649.743 | Declarado; sello amarillo de la celda |
| 43 (nuevo) | Con ε ≠ 1 los chars `TaltimirSal`/`TaltimirSelf` son factores medios: las reconstrucciones de `NTA.do` §3–§4 que los usan (`pensiones_en_yl = on`, `ing_mixto_depurado = off`) son aproximadas | 0 con la firma | Declarado en `NTA.do` (FLAG cuando se usan las alternativas) |
| 44 (nuevo) | La calibración de ε usa 9 rangos del ITAN; «Más de 500 mil» (8.120 bn, 10.5 % del ISR PF) no tiene personas en la ENIGH con ningún ε ≤ 3 y los rangos 2–3 son devoluciones netas | 8.120 + (−3.143) | Declarado: el top del ITAN sigue sin contraparte micro; candidato a 9.x (truncamiento vs subreporte, `dC pp.268–271`) |
| 45 (nuevo) | D.59 S.14 (21.138) < predial + tenencia ENIGH (53.444 crudos) | 32.306 | Declarado (§4.4); la celda CSI manda en NTA (`TmenD59`) |
| 46 (nuevo, ritual 2026-11-09) | La partición ⅔ / ⅓ de `ing_mixto` se aplica también a D.422 (retiros de cuasisociedades) por convención NTA heredada, no por hallazgo: en el SCN D.422 es renta de la propiedad | ⅔ × 649.743 = 433.162 en YL | Declarado (§4.0); parámetro futuro `d422_particion` (`nta` | `capital`) |

## §9 Específico de México

| Elemento | Qué requiere genéricamente | Por qué México lo resuelve así | En cap0 |
|---|---|---|---|
| Elasticidad del subreporte calibrada contra registros fiscales por rango | Un registro administrativo del impuesto a la renta de personas **por rango de ingreso declarado** | La SHCP publica el ISR por rango y tipo de contribuyente cada trimestre (ITAN); el SAT no publica microdatos ni tabulados por percentil para 2024 | fila 17 (nueva), §0.3 |
| D.422 como parte de la celda de negocios | Cuentas por sector con D.42 abierto en D.421/D.422 | INEGI publica D.422 de S.14 en la CSI (f.99); la ENIGH no distingue cuasisociedades | fila 4 |
| Rentas efectivas en B.2n | Que la cuenta de producción de hogares separe vivienda propia de arrendamiento | INEGI no publica el VAB del arrendamiento aparte; la CSVM da el alquiler imputado bruto y la diferencia con B.2b es la renta efectiva | fila 4 |
| Validación con ocupaciones de alto ingreso | Clasificador de ocupaciones en la encuesta de ingreso | SINCO (división 1 «Funcionarios, directores y jefes») en la ENIGH; del Castillo lo usa con el sector financiero | fila 2 |

## §10 Procedencia

| Sección | Archivo y líneas |
|---|---|
| Encabezado, §3 | `SIM.do` §0.8 l. 98–102, §0.9; `01_modulos/Households.do` header §4, §0.0 (`cuad_params`, `altimir_elasticidad`), §0 (tras `local D4Hog`), §3 l. 1282, §9 (bloque `altimir == "yes"`), §9.1, §11.1, §11.5; `SCN.ado` l. 70, 79, 605–648, 2633, 2677, 2810; `01_modulos/NTA.do` l. 173–180, 228–250, §4.3b, cuadro 3, JSON `parametros`; `05_scripts/test-nta-identidad.do` |
| §2 | CSI_115.xlsx f.59–71, 95–105 (asset congelado, `manifest.json: scn_vintage.csi`); `master/itan-isr-rangos.dta`; `raw/ENIGH/2024/Documentos/Descriptor de archivos.pdf` (rubros #45 `utilidad`, #46 `arrenda`; claves P023–P031 e INGRESOS POR RENTA DE LA PROPIEDAD) |
| §4.1 | CUAD-0 §10 bis 7 y Tabla 1; `L` l. 659–676; `dC` pp. 232–233; SNA 2008 §24.55 |
| §4.2 | CSI_115 f.95–105 (leídos con pandas desde `-datos/raw/SCN/CSI_115.xlsx`, columna AS = 2024 R/P); `dC` pp. 232, 236 (cuadro 71); INEGI 2014 p. 12 (CUAD-0 §10 bis 2) |
| §4.3 | `dC` pp. 237–241 (ecs. 3–4, gráfico 77, cuadro 74); `R0`, `Rε` (`wrap.log`: cuadros «Brecha ENIGH–SCN repartida ∝ Y^ε», «Validación del ajuste por subreporte», «ISR de personas físicas por rango de ingreso anual declarado», «ISR anual del motor vs LIF»); `diag-cuad-3-2026-11-08/analisis-eps.py` y `analisis-eps.out` |
| §4.4 | `dC` pp. 233, 241–242, 268–271 (cuadros 69, 74, 92); CUAD-1 §8 bis ficha 6; CUAD-2 §4.0 bis |
| §7 | `R0/gate-numeros.txt`, `R0/wrap.log` (gates de `Households` §9.1 y §11.5); `01-sim-completo/` (`gate-numeros.txt` ROJO esperado, `test-web-batch.md`, `test-nta-identidad.txt`, `test-log-ancho.txt`) |
| Δ esperado | aritmética de §4.1–§4.3; `01-sim-completo/output.txt` vs `05_scripts/fixtures/output-default.txt` (v8.17.1) |

### §10 bis — Citas literales (regla de la firma §D de CUAD-0)

1. **`dC p.232`** (cap. III §3 «Propuesta de ajuste de la información»): «La variable remuneraciones de los asalariados, de la Encuesta Nacional de Ingresos y Gastos de los Hogares (ENIGH), se compara con el concepto D.1 Remuneración de los asalariados (II.1.2 Cuenta de asignación del ingreso primario), del Sistema de Cuentas Nacionales. El ingreso mixto de la encuesta será comparado con los rubros B.3b Ingreso mixto bruto y D.422 Retiros de ingresos de cuasi sociedades (II.1.2 Cuenta de asignación del ingreso primario). La renta de la propiedad será comparada con los rubros D.41 Intereses, D.421 Dividendos, D.443 Renta de inversión atribuida a los accionistas de fondos de inversión colectiva, y D.451 Renta de la tierra».
2. **`dC p.232`**: «En virtud de que el Sistema de Cuentas Nacionales incluye, en el rubro B.2b Excedente bruto de operación del sector Hogares (S.14), la renta de los inmuebles, más la renta imputada de las viviendas que las familias ocupan (de las residencias propias, prestadas o con hipotecas), se aplicará el siguiente procedimiento. Se compara la suma del excedente bruto de operación más la renta de la propiedad de cuentas nacionales y menos el alquiler imputado de la encuesta, con la suma de la renta de la propiedad de la encuesta».
3. **`dC p.233`, cuadro 69**, grupo «Renta de la propiedad»: «D.41 Intereses (recursos), D.421 Dividendos (recursos) D.443 Renta de inversión atribuida a los accionistas de fondos de inversión colectiva, D.451 Renta de la tierra, y B.2b Excedente bruto de operación. Menos la estimación del alquiler de la vivienda de la Encuesta Nacional de Ingresos y Gastos de los Hogares (ENIGH)» ↔ «X016 Alquiler de tierras y terrenos; X017 Alquiler de casas, edificios e inmuebles; X018 Intereses provenientes de inversiones a plazo fijo; X019 Intereses provenientes de cuentas de ahorro; X020 Intereses provenientes de préstamos a terceros; X021 Intereses provenientes de acciones, bonos y cédulas; X022 Alquiler de marcas, patentes y derechos de autor; X023 Otros ingresos por renta de la propiedad no considerados anteriormente».
4. **`dC p.237`**: «A nivel de ingreso nacional, el 41% de la diferencia entre El Sistema de Cuentas Nacionales y la Encuesta de Ingresos y Gastos de los Hogares (ENIGH) se debe a la renta de la propiedad, y una cantidad muy similar (38%) a negocios del hogar y trabajo por cuenta propia (véase el gráfico 76); percepciones que tienen, principalmente, los hogares con mayores ingresos. Por ello, el ajuste no debe ser neutro con la distribución, es decir, no debe asignarse la diferencia entre todos los hogares». Y: «El ajuste de las remuneraciones de los asalariados y del ingreso mixto, no es neutro con la distribución, es decir, se considera una elasticidad ingreso del subreporte mayor a uno. La diferencia en la renta de la propiedad y en las transferencias se asigna solo a las familias que han declarado este tipo de ingresos, de manera proporcional».
5. **`dC p.238`**, ecuaciones (3) y (4): Factor_i = [Y_i / Σ_{x=1}^{n} Y_i]^{1.75}; Ponderador_i = [Factor_i / Σ Factor_i]. «Donde Y es el ingreso de cada persona (i). Es decir, se eleva a la potencia 1,75 la proporción que representa el ingreso de la persona (i) en el total, para obtener un factor. El ponderador final es igual al factor de cada ingreso (i), entre la suma de los factores».
6. **`dC p.240–241`**: «de acuerdo con la cifra original de la encuesta (sin ajuste), el ingreso por trabajo (sueldos, aguinaldo, primas y bonos), de los directores y funcionarios del sector financiero privado, en 2018, fue de 53.000 pesos mensuales, cantidad sumamente baja. Con el ajuste llevado a cabo la cifra crece a 282.000 pesos mensuales (véase el cuadro 74). De acuerdo con la firma PageGroup, la remuneración de un director general (Chief Executive Officer, CEO), se ubicaba en el rango de 160.000 a 585.000 pesos mensuales, en 2018». «se puede considerar el ajuste llevado a cabo como plausible y ligeramente conservador; es probable que la elasticidad subreporte del ingreso sea un poco mayor».
7. **`dC p.241`**: «Se estima el ingreso gravable para los empleados y obreros subordinados que tenían un contrato de trabajo […], igual al 85% de su ingreso por trabajo ajustado. Se descuenta el 15% para excluir los ingresos no gravados, así como las contribuciones sociales».
8. **`dC p.225`** (Altimir): «El subregistro en cada tipo de ingreso es proporcional a las percepciones, con excepción de los ingresos por renta de la propiedad; en este caso la diferencia se concentra en el quintil superior de la distribución. […] Altimir optó por la hipótesis más conservadora, es decir, asumir que la subdeclaración es proporcional al ingreso (Altimir, 1975, 1982 y 1987)».
9. **SNA 2008 §24.55** (ya en CUAD-0 §10 bis 7): «By convention, all the value added arising from leasing dwellings is treated as operating surplus, not mixed income».

## Δ esperado condicional (tras CUAD-3, con las celdas nuevas y ε\*)

| Agregado publicado | v8.17.1 | Esperado CUAD-3 (§4.1–§4.3) | Real v8.17.2 (`01-sim-completo`) | Por qué |
|---|---:|---:|---:|---|
| Factor de B.2n (`TaltimirHouse`) | 2.5860 | 1.9671 | **1.9671** | `rentas_celda = b2n` |
| Factor de B.3n (`TaltimirSelf`, medio) | 3.6848 | 4.2800 | **4.2800** | sin rentas, + D.422 |
| Celda de D.4 de `ing_capital` (bn) | 4,997.037 | 4,347.294 | **4,347.294** (factor 2.8912) | − D.422 |
| YL (`CUADRATURA`, % PIB) | 43.636 (14,690.951) | 44.923 (15,124.113) | **44.923** | + ⅔ D.422 |
| YA (`CUADRATURA`, % PIB) | 24.435 (8,226.391) | 23.148 (7,793.229) | **23.148** | − ⅔ D.422 |
| Resto de `CUADRATURA` (D.442, sectores, CCF, ROW, vintage) | 1.800 … 0.252 | sin cambio | **sin cambio** | la identidad no toca sectores |
| Σ obligación de asalariados (bn; formales / toda la base) | 1,016.584 / 1,282.675 | sube con ε | **1,041.461 / 1,300.546** | ε\* = 1.45 (Tabla 3a) |
| Residuo FLAG 27 (bn, %) | −237.200 (−18.92) | no cierra con ε ≤ 2 | **−212.324 (−16.93)** | subreporte residual, sello rojo |
| Gini YL por hogar; top 10 % / top 1 % de YL | 0.523; 39.7 / 12.5 % | ↑ | **0.608; 48.1 / 22.9 %** | ε en D.1 y B.3n |
| Participación del decil X en Yl (`INCD2`) | 30.3 % | ↑ | **39.1 %** | ídem |
| `INGRESOS`, `INGRESOSTEF`, `GASTOS*`, `PIBY` | — | sin cambio | **sin cambio** | anclas LIF/PEF |
| `INCD*`, `APORT*`, `PROY*` | — | se mueven | **404 de 509 líneas de `output.txt`** (Tabla 3c) | reparto por decil/edad |
| Σ S sin ancla vs B.8n S.14 | −19.4 (−1.0 %) | sin cambio | **−19.4 (−1.0 %)** | totales de S.14 iguales |
| Hub del Sankey v4 (INBD, % PIB) | 81.561 | sin cambio | **81.561** | celdas de sector iguales |
| Sankeys (`gate-numeros`) | baseline v8.17.1 | ROJO esperado | **ROJO**: SF decil 80/104, NTA decil 113/143; re-baseline | reparto por decil |

Lo que **no** se infiere de las tablas y lo dice la corrida completa: el reparto por decil del ISR de asalariados (`INCD` bloque 12) y el tamaño del cambio en `APORT*` por edad y sexo. A partir de v8.17.2 los números **no comparan** con ≤ v8.17.1 por: B.2n incluye rentas efectivas; B.3n + D.422; elasticidad ε\*.

## Lista cerrada para Ricardo (antes del merge)

| # | Decisión | Propuesta del memo | Alternativa |
|---|---|---|---|
| 1 | `rentas_celda` | **`b2n`** (decisión 1 de Ricardo; FLAG 18 cerrado; SNA §24.55, del Castillo p. 232 y cuadro 69) | `b3n` (v8.15b–v8.17.1), con FLAG |
| 2 | `ing_mixto_ancla` | **`b3n_d422`** (decisión 2; D.422 = 649.743 existe en CSI_115 f.99; sello amarillo por cuasisociedades) | `b3n`, con FLAG |
| 3 | `altimir_elasticidad` (ε\*) | **`1.45`** (mínimo de L1 contra el ITAN: 56.6 pp; meseta 1.35–1.50) | `1.50` (misma meseta, L1 57.4) · `1.75` (del Castillo, L1 78.4: sobreajusta la cola) · `1` (Altimir) |
| 4 | Estadístico de calibración | L1 de participaciones sobre los 9 rangos con ITAN ≥ 0 (r = 1, 4–11), publicado con el L1 de los rangos ≥ 1 M y el Δ del top | otro criterio (p. ej. solo rangos ≥ 1 M: mismo ε\*) |
| 5 | FLAG 27 | **sigue abierto y declarado**: residuo −212.324 bn (−16.93 %) con ε\*; se publica como subreporte residual, sello rojo; la regla «≥ 0 = evasión identificable» queda en el código | cerrarlo por decreto (no: el número no lo permite) |
| 6 | Lectura de D.1 en el memo | la validación con SINCO 1 (47.3 → 49.4 mil) no reproduce el 53 → 282 mil de del Castillo porque la brecha de D.1 del motor es 8.4 % y no 59 %: se declara como diferencia de celda, no como falla | — |
| 7 | Transcripción del adjunto | `CEPAL-delCastillo-2023-lecciones.md` es transcripción del prompt: Ricardo sustituye por el original si difiere | — |
| 8 | Cuadro 69 vs Tabla 1 | el motor no suma remuneraciones en especie ni autoconsumo a las bases crudas de D.1 y B.3n (del Castillo sí): se declara; cambiarlo es otra sesión | incluirlos (mueve los factores medios, no los totales) |
| 9 | Release | `baseline = v8.17.2`; fixtures de `output.txt`, sankeys y NTA re-baselineados en este PR; los de `/entidades` en PR corto tras el c32 del ritual (8.16b) | — |
