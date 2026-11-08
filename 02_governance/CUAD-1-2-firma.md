# CUAD-1 y CUAD-2 — Addendum de firma (Ricardo, 2026-11-07)

Se firman `02_governance/CUAD-1.md` y `CUAD-2.md` (rama `sesion/8.16a`, `015fbb0`) con lo que sigue. Donde este addendum difiere de los memos, manda el addendum. Se commitea como `CUAD-1-2-firma.md` y se funde en §4.0 de cada memo (como CUAD-0-firma en CUAD-0).

> **Procedencia (sesión 8.17, 2026-11-08).** Este archivo es el **adjunto original v2** de Ricardo. La sesión 8.16b no lo tuvo a mano y commiteó en su lugar una transcripción del prompt (§A reglas, §B con «qué mueve», §C árboles, §D cuadros, §E lo abierto); la sesión 8.17 lo sustituyó por el original. Diferencias registradas en el CHANGELOG `[v8.17.0]`: el original numera las decisiones mecánicas (§A 1–25) y las de Ricardo (§B 3, FLAG 33, 8–11, 14/FLAG 20, 4, 17, 18, 7); trae el §B bis (brecha de S tras 8.16 = +24.5 %, Δ esperado condicional) y el ejemplo del cuadro del Paso 4 en §D; no trae el §E de la transcripción (lo abierto quedó en CUAD-1 §8 y CUAD-2 §8).

## A. Las 20 decisiones mecánicas: como las proponen los memos

1 `consumo_ancla = p3_s14` · 2 `consumo_precios = comprador` · 4 `cuotas_por_sector = on` · 5 cuota social federal fuera de `cuotasTPF` · 6 `isrpm_incidencia = propiedad` · 7 denominador ISRPMTE = **B.2n S.11+S.12** (corregido 2026-11-07: B.5n ya es neto de la renta de la propiedad pagada y daba una tasa efectiva de 142 %; la base del impuesto es el excedente, como la TE laboral usa D.1) · 12 `isras_share = acotado` · 13 `iepsnp_macro = divsim`, `ieps_relativo = micro` · 15 predial/tenencia → D.59 (fuera del consumo), gas LP, combustibles y gas natural → categoría 9 · 16 `hub = inbd` · 19 `isflsh_regla = sector` · 20 `circuito_d442 = neto` · 21 `vintage_nodo = si` · 22 `bruto_neto = neto` · 23 `financiamiento = un_nodo_4`, `discrepancia_gasto = fuera` · 24 8.16 antes de 8.17 · 25 `baseline = v8.16.0` al cerrar 8.16.

## B. Las decisiones de Ricardo

| # | Parámetro / tema | Firmado | Razón |
|---|---|---|---|
| 3 | Regalos | **G5** (quien consume); G2 fuera | el SCN cuenta el consumo una vez |
| FLAG 33 | `gastotarjetas` | **fuera del consumo** | pago de tarjeta = flujo financiero, como préstamos |
| 8 | Ancla del ISR de personas | **D.51 S.14** (1,518.912) con fila «LIF vs CSI por sector» declarada; ISR PM → D.51 S.11+S.12 | los 209.2 bn son ISR de hogares que entera una sociedad |
| 9 | `obligacion_isrpf_ancla` | **`itan_rangos`** para PF con y sin actividad empresarial (11 rangos ≥ 0; «Resto» ∝ ENIGH); asalariados por total ITAN = LIF | en retenciones por salarios el rango ordena al patrón |
| 10 | `informalidad` | **`corte`** sobre N externo | con el share acotado la obligación (1,238) < LIF (1,254): el corte por recaudación ya no puede cerrar |
| 11 | `ancla_formales` | **`imss`** (IMSS 22,238,379 + ISSSTE 3,262,068 al 31-dic-2024). El residuo Σ obligación(formales) − LIF (−124.048) se declara **«ajuste por subreporte de ingresos altos»**, sello rojo, FLAG hasta 9.x. **No se publica «evasión»** | principio A aplicado a conteos: el número de formales es un total observado |
| 14 / FLAG 20 | `Simulador.ado` | **corregir** (la rutina de gráficas trabaja sobre `tempvar`) y **regenerar la caché** `consumption_*_pc.dta` en `-datos`; sin `baseline` ni `data_updated` | lo publicado no cambia (ficha 1) |
| 4 | Captura manual vs ITAN | **ITAN manda desde 2019-1T**; `ISRInformesTrimestrales.xlsx` se conserva solo para 2013–2018 con sello amarillo; retiro según §8 ter | 2021 y 2022-3T eran cifras preliminares revisadas |
| 17 | `retenido_a_personas` (8.17) | **`on`**: B.5n y B.8n de S.11+S.12 llegan a personas ∝ `d4_relativo` (regla P, sello rojo), con el nodo «Sociedades» visible en medio conservando | principio A: ahorro de personas = ahorro neto nacional; «la economía empieza y termina en la persona» |
| 18 | `deficit_a_personas` (8.17) | **`per_capita`**; `tau_menos` implementado y medido como alternativa | principio B: per cápita es el default honesto; τ⁻ supone quién pagará mañana |
| 7 | Stash de la pirámide por sexo | **Trabajo de Ricardo**; recuperado por él. Ningún agente lo toca | regla C |

## B bis. Brecha de S tras 8.16 (2026-11-07)

El Δ esperado de CUAD-1 §7 (−0.9 %) suponía cerrada la fila τ⁺/inter/remesas vs D.62 + D.7 (+461.0), que esta firma manda a 8.17. Tras 8.16 la brecha de Σ S sin ancla vs B.8n es **+24.5 %** (= +461.0 + 21.1 D.59 − 17.0 ImpProd), al peso. Se publica con el ancla de S encendida (`nta_anclaS = auto`, `brecha_max = 30` hasta 8.17, FLAG declarado); la nota 2 de `/NTA` lleva las cifras nuevas; CUAD-1 §7 queda: tras 8.16 +24.5 %, tras 8.17 ≈ −0.9 %. Regla para los memos: el Δ esperado se escribe condicional a lo que cada versión cierra.

## C. Regla nueva de operación (2026-11-07): el clon de Dropbox es intocable

El clon `…/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP` es el espacio de trabajo de Ricardo. **Ningún agente ejecuta ahí `stash`, `reset`, `checkout`, `switch`, `pull` ni `merge`.** Lo que haya sin commit es trabajo en curso de Ricardo y no requiere explicación ni aviso. El «baile de master» desaparece: `-datos` queda en `master` permanentemente (es donde se publica y donde `ritual.sh` corre); Dropbox vive en la rama que Ricardo quiera. Devin trabaja solo en sus worktrees y en `-datos`. Va a las tres plantillas de `02_governance/prompts/`, al runbook §14 y a `ritual.sh` (el paso `baile` solo actualiza `-datos`).

## D. Estándar de presentación de cuadros en el log (2026-11-07)

Los cuadros de anclas, identidades y Tabla 1 salen hoy con comentarios dentro del rótulo («(+) Alquiler imputado + rentas b2n (B.2n S.14)(0.543)», «(oye_en_hub=off)(0.000)») y columnas desalineadas. Regla para todo cuadro que imprima el motor (`_tabla_anclas.ado`, `_cuadfila`, `_cuadsector`, gates, `nta-identidad.txt`):

1. **Una fila, un concepto, una celda.** El rótulo es el nombre de la cuenta como lo escribe INEGI; el código SCN y el sector van en columnas propias; nada entre paréntesis en el rótulo.
2. **Notas al pie con marcador**: todo comentario, parámetro vigente o salvedad sale del rótulo y va debajo del cuadro como `Nota 1:`, `Nota 2:` …, con el marcador `^1`, `^2` pegado al rótulo (p. ej. `Renta de la propiedad^1`). Las notas se numeran por cuadro.
3. **Columnas fijas y alineadas** a ancho declarado: Código · Cuenta · Sector · Gini · Motor (% PIB) · SCN (% PIB) · Factor · Fuente (cuadro·fila). Los números con `%` de ancho fijo y separador de miles donde son MXN (`%21.0fc`); sin cifras pegadas a texto.
4. **Encabezado del cuadro en una línea**: qué es, año, fuente congelada y sello; la regla del cuadro (línea de guiones) del mismo ancho que las columnas.
5. **Los gates debajo del cuadro, uno por línea**, con la misma alineación: `GATE  Σ ing_subor = D.1 S.14 ........ 10,052.962  vs  10,052.962   reldif 0.00e+00   OK`.
6. Lo que no cabe en el ancho se trunca con `…` **solo en el rótulo**, nunca en un número.
7. Mismo estándar en `nta-identidad.txt`, `contrato-32.md` y en todo `.md` de evidencia que imprima tablas del motor.

Ejemplo del cuadro del Paso 4 reescrito:

```
 Paso 4 — Anclas S.14 (Tabla 1 firmada) y filas de sector · % del PIB BIE 2024 = 33,667,023,163,000 MXN · asset raw/SCN congelado, sello verde
 Código  Cuenta                                                Sector   Gini    Motor     SCN   Factor  Fuente
 D.1     Remuneración de los asalariados                        S.14   0.517   29.860  29.860   1.0650  CSI_115·f.71
 B.3n    Ingreso mixto neto                                     S.14   0.687   20.664  20.664   3.6848  CSI_115·f.70
 D.4     Renta de la propiedad, neta^1                          S.14   0.715   14.843  14.843   3.3233  CSI_115·f.95
 B.2n    Excedente neto de operación^2                          S.14   0.543    2.704   2.704   2.5860  CSI_115·f.69
 —       Organismos y empresas públicas^3                       —      —        0.000   4.758   —       LIF
 ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
 B.5n    YL + YA de las personas^4                              S.14   0.566   68.071  68.071   1.0000
 …
 Nota 1: D.4 neto − D.442; relativo de reparto `d4_relativo = proxy_propiedad` (sello rojo; CUAD-0 §4.0).
 Nota 2: alquiler imputado; las rentas efectivas van en B.3n (SNA 2008 §7.9; INEGI p. 45).
 Nota 3: `oye_en_hub = off`: no es ingreso de personas; entra como fila de sector «Empresas públicas → Gobierno».
 Nota 4: B.5n S.14 − D.442 (`cuotas_d614 = neto`).
```
