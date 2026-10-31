# CUAD-0 — Addendum de firma (Ricardo, 2026-10-31)

Se firma CUAD-0 (`02_governance/CUAD-0.md` @ `14e6ba2`) con las decisiones de abajo. Donde este addendum difiere del memo, manda el addendum. Es el insumo de la sesión v8.15b; se commitea como `02_governance/CUAD-0-firma.md` y CUAD-0 §4 se actualiza para reflejarlo.

## A. Dos correcciones al memo

1. **Pensiones (§4 `pensiones_en_yl`, Δ esperado).** v8.14.0 no duplica pensiones: las subcuenta. `ing_jubila` entra a `ing_subor`, absorbe parte del ancla RemSalSS, y `NTA.do` las resta después, dejando YL 751.330 bn por debajo de D.1 + ⅔ B.3n. Con `off`, el ancla D.1 se reparte solo sobre salarios y YL coincide con la celda. El +751 de la corrida alterna de v8.15b-pre es la corrección, no un efecto secundario.
2. **D.4 (Tabla 1, filas `*PM`, `cap6`, `cap8`).** La renta de la propiedad que recibe S.14 (D.41 544.940 + D.42 4,779.531 + D.44 735.471) no tiene contraparte utilizable en la ENIGH (intereses 19.335 + dividendos 2.368 crudos: <0.4 %). La partición pf/PM de honorarios y rentas (`H` l. 512–513, 522–523) era un proxy de propiedad presentado como celda; `ing_t4_cap3PM` negativo es el síntoma. Se separa lo que el principio C junta: **la celda del SCN fija el total; el relativo de reparto es un parámetro declarado**, con sello rojo cuando la encuesta no ve la partida.

## B. Decisiones firmadas

| # | Parámetro | Valor | Nota |
|---|---|---|---|
| 2 | `pensiones_en_yl` | **off** | D.62; ya cableado en v8.15b-pre |
| 3 | `ing_mixto_depurado` | **`transf_negocios`** + **honorarios y rentas efectivas íntegros a B.3n** (sin partición pf/PM) | P068–P081 = negocios propios (catálogo ENIGH verificado en v8.15b-pre 4a) = B.3n S.14. Base cruda: cap2 + cap3 + negocios + agropecuario; factor ≈ 4.6 (se reporta el exacto) |
| 5 | `yk_ancla` | **`b2n_b3n_d4`** | Con el ⅓ de B.3n incluido (v8.15b-pre reportó que falta) y sin restar `ImpNetProductos_soc/_hog` en NTA bajo este ancla |
| 6 | `cap4` | **fuera** | Ganancia de capital, fuera de la cuenta corriente; sigue en `ing_bruto_tax` |
| 7 | `cap3_particion` | **sin objeto** | Muere con la decisión 3 |
| 8 | `alq_en_capital` | **off** | Alquiler imputado solo en `ing_estim_alqu`, anclado a B.2n S.14 |
| — | **`d4_relativo`** (nuevo) | **`proxy_propiedad`** | D.4 neto S.14 repartido con `Distribucion` ∝ (cap6 + cap8 + rentas efectivas crudas + alquiler imputado crudo + negocios crudos). Alternativa `enigh` (solo cap6 + cap8, factor ≈ 250: no se usa). **Sello rojo**, FLAG «D.4 por proxy de propiedad; la ENIGH cubre <1 % de la celda». Corrección por top incomes (SAT) = línea 9.x |
| 9 | `suborrow` | **off** | D.1 S.14 incluye los 52.721 del exterior (CSI_103 f.35 / CSI_121 f.71) |
| 10 | `oye_en_hub` | **off** | OyE = P.11 de Pemex/CFE + D.45; no es ingreso de personas. En el Sankey fiscal entra como fila de sector «Empresas públicas → Gobierno» |
| 11 | `cuotas_d614` | **neto** | D.442 (605.932) sale de YA y D.614 de cuotas; circuito contable con neto cero en el hogar. YA_base = 8,226.391 |
| 12 | Excedente retenido S.11/S.12 | **memo en 8.15b; imputación en 8.17** | Principio A («ahorro de personas = ahorro neto nacional») lo lleva a personas ∝ `d4_relativo` en el Sankey de la economía |
| 13 | Yl + Yk + OyE = PIB | **filas de sector** | PIB = YL + YA + retenido S.11/S.12 + impuestos netos S.13 + S.15 + CCF + ROW. La identidad vuelve a cerrar con `output.txt` declarándolo |
| 14 | `baseline` | **gate desde v8.15.0** | Cableado en v8.15b-pre; `baseline = v8.15.0` |

## C. Lo que 8.15b no cierra y se declara

- Brecha de S residual (≈ +11 % sobre B.8n tras `cuotas_d614=neto`): D.5 LIF vs devengado (209), τ⁺ efectivo vs D.62 + D.7 (461), Cpriv vs P.3 (−438). Es Expenditures/TasasEfectivas → 8.16. El ancla multiplicativa de S se conserva con FLAG.
- Subreporte de top incomes: `d4_relativo` lo nombra; la corrección es 9.x.
- Informalidad: λ = 1.215 y 42.5 M formales implícitos vs 25.5 M cotizantes (v8.15b-pre 4c). La obligación estatutaria sobre ingreso con Altimir uniforme sale baja; **requisito de entrada de 8.16**: anclar la obligación de ISR PF a declaraciones SAT por rango de ingreso antes de descomponer informalidad/evasión.

## D. Verificación contra el manual (Claude, 2026-10-31; va a CUAD-0 §10)

Leído: SNA 2008 borrador final, capítulos 7 y 8 (unstats.un.org/unsd/statcom/doc08/SNA-Chapter7.pdf, -Chapter8.pdf). No accesible desde la sesión: la metodología CSI de INEGI (702825068479.pdf) y el capítulo 24; la guía rápida del SCNM base 2018 (889463913832.pdf) no trata cuasisociedades ni D.442/D.614/D.8 y remite a la metodología del CAB 2018.

1. **Rentas efectivas de hogares → B.3n (decisión 3): respaldado por el SNA 2008 §7.9.** Regla: «all unincorporated enterprises owned by households that are not quasi-corporations are deemed to have mixed income»; las únicas excepciones son los ocupantes propietarios («For owner-occupiers, all value added is operating surplus») y los hogares que emplean personal doméstico. Un hogar que renta un inmueble es una empresa no constituida en sociedad → B.3n. §7.19(c) confirma que el B.2 de hogares es «the operating surplus from housing services produced for own consumption by owner-occupiers». **Pendiente INEGI**: que la CSI mexicana siga la regla; prueba empírica en el repo: B.2n S.14 (CSI_115 f.69, 910.359) debe coincidir al peso con el VAB neto del alquiler imputado que INEGI publica (cuenta satélite de vivienda / serie SCN). Si B.2n es mayor, INEGI metió rentas efectivas en B.2n y la fila cambia de celda. Devin lo corre en el paso 0.
2. **Negocios P068–P081 íntegros a B.3n: respaldado por §7.9 con una salvedad.** La excepción son las cuasisociedades (negocios de hogares con contabilidad completa que INEGI reclasifica a S.11). La ENIGH no distingue; la cobertura resultante (Σ crudos / B.3n ≈ 22 %) se declara como factor, no se parte. Sello amarillo hasta leer la metodología CSI.
3. **Circuito D.442/D.614 neutral (decisión 11): respaldado por el SNA 2008 cap. 8 (borrador §8.77 y §8.83).** Los suplementos a las cotizaciones «represent the return to the pension fund of the property income earned on the start of year pension entitlement» y «this amount is included in property income payable by the administrators of pension funds to households». En la CSI mexicana D.442 = D.614 = 605.932: la igualdad al peso confirma que INEGI lo registra así. `cuotas_d614=neto` es neutral en S.
4. **D.8:** no alcanzado en la lectura. La regla del SNA (D.8 = cotizaciones + suplementos − prestaciones, pagado por S.12 a S.14) ya la aplica `NTA.do` (`YA_d8` ∝ YL de cotizantes); sin cambio en 8.15b.
5. **Remesas D.752:** cap. 8 borrador §8.26(e) las lista como transferencias corrientes con no residentes; celda confirmada.

Regla: ninguna frase del método nace fuera del repo, incluidas las de Claude; los párrafos citados arriba se copian a CUAD-0 §10 con URL.

## E. Paso 0 de la sesión v8.15b (Claude, 2026-10-31): la celda de las rentas efectivas cambia a B.2n

La prueba empírica que pide D.1 se corrió y **B.2 de S.14 es mayor que el alquiler imputado**: la fila de rentas efectivas (`ing_t4_cap3`, P023–P025 y P031) cambia de celda, de B.3n a **B.2n junto al alquiler imputado**. Queda como parámetro `rentas_celda` de `Households.do` (firmado `b2n`; alternativa `b3n` = la lectura D.1 de este addendum). Lo demás de B no cambia.

| Cifra | Valor (bn, 2024) | Fuente |
|---|---:|---|
| B.2b S.14 (excedente bruto de operación de los hogares) | 2,107.569 | CSI_115 f.59 U/A |
| P.51c1 S.14 (CCF sobre el excedente bruto) | 1,197.210 | CSI_115 f.61 |
| B.2n S.14 | 910.359 | CSI_115 f.63/f.69 |
| Alquiler imputado de las viviendas de uso propio, 2024 | **1,886.385** | INEGI, CSVM 2024, reporte de resultados 47/25 (21-nov-2025), p. 7–8 |
| B.2b − alquiler imputado | **+221.184** | aritmética |
| 04.1 «Alquileres efectivos de alojamiento» (consumo de hogares por finalidad) | 2,763.650 | BIE 724611 (la serie no separa efectivos de imputados: 2,763.650 > 1,886.385) |

INEGI publica el alquiler imputado bruto («valor del alquiler imputado … 1 886 385 millones de pesos … 6.0 % del PIB»), no el VAB neto; la comparación se hace en bruto (B.2b) y el resultado no depende del neteo: B.2b excede al alquiler imputado en 221.184 bn (11.7 %), que es el orden de magnitud del arrendamiento de vivienda por hogares (ENIGH: 110.753 bn crudos). La regla del manual que lo sostiene no es §7.9 sino **§24.55**: «By convention, all the value added arising from leasing dwellings is treated as operating surplus, not mixed income» (SNA 2008, cap. 24, p. 466–467). INEGI (metodología CSI base 2008, p. 33) solo nombra la excepción de la vivienda por cuenta propia, así que la decisión descansa en §24.55 y en la cifra; sello amarillo hasta leer la metodología base 2018. Párrafos literales y URL en CUAD-0 §10.

Consecuencias en el motor (sesión v8.15b): `TaltimirHouse` ancla `ing_estim_alqu` + `ing_t4_cap3` a B.2n; `ing_mixto` = honorarios + negocios propios (sin rentas) → B.3n; las rentas efectivas viajan en Yk (capital), no en Yl; el relativo de D.4 (`d4_relativo`) no cambia. Lista de lo que Ricardo decide: si prefiere la lectura D.1 (`rentas_celda = b3n`), es un global.
