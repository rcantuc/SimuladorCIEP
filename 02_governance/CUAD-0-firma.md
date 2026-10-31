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

Leído: SNA 2008 borrador final, capítulos 7 y 8 (unstats.un.org/unsd/statcom/doc08/SNA-Chapter7.pdf, -Chapter8.pdf) y **INEGI, *Sistema de Cuentas Nacionales de México. Cuentas por sectores institucionales. Fuentes y metodologías* (702825068479.pdf; páginas del PDF)**. Los cinco puntos quedan respaldados por las dos fuentes; el paso 0 de 8.15b pasa de «decide la celda» a «confirma al peso».

1. **Rentas efectivas de hogares → B.3n (decisión 3): verde.** SNA 2008 §7.9: «all unincorporated enterprises owned by households that are not quasi-corporations are deemed to have mixed income»; excepciones: ocupantes propietarios («For owner-occupiers, all value added is operating surplus») y hogares con personal doméstico; §7.19(c): el B.2 de hogares es «the operating surplus from housing services produced for own consumption by owner-occupiers». INEGI, p. 33: el excedente de la empresa no constituida de un hogar es «Ingreso Mixto» en lugar de «excedente de operación», «excepto cuando se trata del excedente derivado de la producción por cuenta propia de los servicios de vivienda»; p. 45: «En el caso de los Hogares, el excedente se origina en la producción por cuenta propia del servicio de alquiler de vivienda». B.2n S.14 = alquiler imputado y nada más; las rentas efectivas de un casero son B.3n. Prueba al peso en el paso 0: B.2n S.14 (CSI_115 f.69, 910.359) = VAB neto del alquiler imputado.
2. **Negocios P068–P081 íntegros a B.3n: verde con FLAG de cuasisociedades.** INEGI, p. 12: cuasisociedades = «empresas que no están constituidas en sociedad pero funcionan como tal, pues se comportan en forma autónoma e independiente de sus propietarios y disponen de conjuntos completos de cuentas», y «las cuasisociedades que son propiedad de los Hogares o del Gobierno se agrupan junto con las sociedades no financieras». P. 17 y p. 33: todo lo demás es ingreso mixto del hogar («trabajadores por cuenta propia, profesionistas independientes, ejidatarios, jornaleros, artesanos, vendedores ambulantes», p. 33). La ENIGH no identifica cuasisociedades; la cobertura (Σ crudos / B.3n) se declara como factor con FLAG «negocios de hogares con contabilidad completa están en S.11, no en la celda». Sello amarillo solo por ese FLAG.
3. **Circuito D.442/D.614 neutral (decisión 11): verde.** INEGI, p. 46: D.442 «comprende los rendimientos obtenidos por la inversión de los fondos de pensiones, propiedad de los trabajadores y administrados por alguna institución»; p. 47: D.614 «son los ingresos de la propiedad obtenidos durante el periodo contable sobre el saldo de los derechos de pensiones y no de pensiones». SNA 2008 cap. 8 (borrador §8.77, §8.83): los suplementos «represent the return to the pension fund of the property income earned on the start of year pension entitlement». CSI_115: D.442 = D.614 = 605.932 al peso. `cuotas_d614=neto` no deja residuo en S.
4. **D.8: verde.** INEGI, p. 49: «proviene de la diferencia entre los pagos de contribuciones de pensión a los fondos y los cobros de pensiones por los pensionistas … se trata como si fueran propiedad colectiva de los hogares que tienen derechos sobre dichos fondos». Es lo que `NTA.do` hace (`YA_d8` ∝ YL de cotizantes). Sin cambio en 8.15b.
5. **Remesas D.752: verde.** INEGI, p. 48: D.752 «entre hogares que consisten en las remesas regulares entre los miembros de la misma familia residentes en diferentes partes del mismo país o en diferentes países»; SNA 2008 cap. 8 borrador §8.26(e). Celda confirmada (CSI_115 f. de D.752, 1,188.474).

**Consecuencia para el paso 0 del prompt de 8.15b:** ya no decide la celda; verifica al peso B.2n = alquiler imputado y, si no coincide, reporta la diferencia como vintage o como error de lectura, no como cambio de celda. Devin copia estas citas (con página) a CUAD-0 §10 y adjunta el PDF de INEGI a `02_governance/metodo/fuentes/` con su sha256.

Regla: ninguna frase del método nace fuera del repo, incluidas las de Claude; los párrafos citados arriba se copian a CUAD-0 §10 con URL.
