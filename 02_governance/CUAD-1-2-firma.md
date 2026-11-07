# CUAD-1 y CUAD-2 — Addendum de firma (Ricardo, 2026-11-07)

Se firman `CUAD-1.md` (Cuadratura II: `Expenditure` y `TasasEfectivas`) y, en lo que 8.16b toca, `CUAD-2.md` (Sankey de la economía completa) con las decisiones de abajo. **Donde este addendum difiere de los memos, manda el addendum.** Es el insumo de la sesión 8.16b (v8.16.0); se commitea como `02_governance/CUAD-1-2-firma.md` y su §B se funde en §4.0 de cada memo.

> **Procedencia de este archivo.** El adjunto `CUAD-1-2-firma.md` que cita el prompt de la sesión 8.16b no llegó al worktree (no estaba en el repo, en Dropbox, en `~/CIEP_Simuladores` ni en la carpeta de la sesión). Lo que sigue es la **transcripción literal de las decisiones tal como el prompt las enuncia** (Bloques 1–5 y reglas 1–4), ordenada en las secciones que el prompt cita (§B decisiones, §C árboles, §D cuadros). El ejemplo de §D no es el del adjunto: es el cuadro del Paso 4 de `Households.do` tal como sale de la corrida de la sesión, que el prompt fija como formato de referencia. Ricardo sustituye este archivo por el original cuando lo tenga a mano; si difieren, manda el original y la diferencia se registra en el CHANGELOG.

## A. Alcance y reglas de la sesión

1. **El clon de Dropbox es intocable** (§C). Nada de `stash`, `reset`, `checkout`, `switch`, `pull` ni `merge` ahí; el trabajo va en el worktree de sesión y en `-datos`; el paso `baile` de `ritual.sh` solo actualiza `-datos`.
2. **Una corrida de `correr-sim.sh`**, al final, vía `ritual.sh --si`; antes, pruebas de módulo.
3. **Esta versión mueve números publicados**: `baseline = v8.16.0`, `data_updated` = fecha del merge; `gate-numeros` ROJO esperado y **cada llave que cambie debe estar explicada por una fila de §B**; las que no, van al reporte como «sin explicar» y paran el ritual.
4. Sin `publicar.sh vX` ni `publicar-vps.sh`: eso es de Ricardo.

## B. Decisiones firmadas

Correcciones de código (CUAD-1 §8 bis; no son parámetros):

| Ficha | Decisión | Qué mueve en lo publicado |
|---|---|---|
| 1 (FLAG 20) | `Simulador.ado` guarda la copia del dataset antes de deflactar y la restaura al salir: la variable graficada vuelve intacta. Se regeneran `master/2024/consumption_*_pc.dta` en `-datos` sin gráficas. Prueba: `gas_pc_*` idéntico a 1e-15 a la caché regenerada; `TT<k>` sin el 1.085868; `ETotPIB` del log correcto | nada (el factor era uniforme y `TT<k>` lo absorbía); solo el log |
| 2 | `iepsnp_macro = divsim` (224.780); `DifIEPSNP` honesto: FLAG «IEPS micro incompleto: gasolinas fuera de `Expenditure.do`» (el micro cubre ≈ 12.6 %) | nada; solo el log |
| 4 | `ieps_relativo = micro` en `PerfilesSim.do` y `NTA.do`: IEPSP ∝ `gas_pc_Gasolinas + gas_pc_Combustibles`; IEPSNP ∝ IEPS micro por categoría | `INCD/INCD2/INCD3` de IEPS (no petrolero y petrolero) y de `Consumo`, `ImpuestosAportaciones`, `AportacionesNetas`; `APORT*`, `PROY*`; SankeySF; τ⁻ indirecto por edad en NTA (SankeyNTA) |
| 5 | Regalos: **G5** cuenta (el consumo es de quien lo recibe); `tipo_gasto == "G2"` fuera en `Expenditure.do` §2 | `gas_pc_*` por persona (redistribución de 223 bn anclados): SankeyNTA (consumo por grupo), base micro del IVA/IEPS (`INCD` IVA de 2.º orden) |
| 6 | R004 (predial) y R012 (tenencia) fuera del consumo → D.59 (viven en `OTROSK`); G009–G016 y R003 → categoría 9 (electricidad, gas y combustibles) | ídem ficha 5 (redistribución dentro de Σ Cpriv) |
| FLAG 33 | `gastotarjetas` fuera del consumo (flujo financiero); el monto (293.933 bn crudos) se declara en el log | ídem ficha 5 |

Parámetros (`SIM.do` §0.8b; default = valor firmado; cualquier otro valor imprime FLAG en el header del módulo y en `nta-identidad.txt`):

| # | Parámetro | Valor | Nota | Qué mueve en lo publicado |
|---|---|---|---|---|
| 1 | `consumo_ancla` | **`p3_s14`** | Los 19 relativos BIE se conservan; UN factor `TTp3 = (P.3 S.14 − compras netas) / ConHog` reancla el total a P.3 del sector hogares (CSI_115 f.166 = 23,381.329); P.3 S.15 (ISFLSH, 388.320) y el vintage BIE−CSI del consumo (49.749) son filas de sector (CUAD-2). Gate: Σ Cpriv = P.3 S.14 a 1e-9 | Cpriv de NTA (−438.069): SankeyNTA (consumo, S), `nta-identidad.txt`; Sankey «PIB demográfico» (consumo); `gastoanualTOT` → `Consumo`, `IMPORT`, `ImpNetProductos`, `ComprasN` ∝ gasto: relativos sin cambio de forma |
| 2 | `consumo_precios` | **`comprador`** | Único implementado en 8.16b; `basicos` (C − D.21 + D.31 por categoría) es de 8.17 | nada |
| 3 | `cuotas_por_sector` | **`on`** | Tabla 1b: D.61 por pagador y por receptor (S.13 683.959, S.12 1,455.102 con D.614, S.11 193.870, S.15 2.091 = D.61 pagado por S.14 2,335.022). La cuota social y las aportaciones federales (`cuotasF`) son gasto de S.13, no contribución de las personas: **fuera de `cuotasTPF`**. Gate: Σ cuotas = D.61 por sector receptor a 1e-9 | `cuotasTPF` por persona (base del ISR, cuotas netas, share salarial): `INCD` de ISRAS/ISRPF/Laboral, `CUOTAS` sin cambio de total; SankeyNTA (cuotas por sector en 8.17; en 8.16b el reparto entre personas cambia con los relativos por sector) |
| 4 | `isrpm_incidencia` | **`propiedad`** | ISR PM ∝ `ing_d4_rel` (regla P, sello rojo); los negocios propios (`ing_bruto_tpm`) tributan como PF con actividad empresarial (base de la tarifa y probit de PF); denominador de `ISRPMTE` = B.5n S.11 + S.12 | `INCD` de ISRPM, OTROSK (∝ `ISR_PM`), KPrivado, ImpuestosAportaciones, AportacionesNetas; `INGRESOSTEF[4]` (ISRPMTE); `APORT*`, `PROY*`; SankeySF |
| 5 | `isr_personas_ancla` | **`d51_s14`** | En NTA el ISR de personas (asalariados + PF) se ancla a D.51 S.14 (1,518.912) con un factor sobre la LIF (la CSI no los separa) y el ISR PM a D.51 S.11 + S.12 (1,165.676); la diferencia con la LIF es la fila «LIF vs CSI por sector» de `nta-identidad.txt`. `INGRESOS` sigue siendo la LIF | SankeyNTA (τ⁻ directo: Gobierno +188.1), `nta-identidad.txt`; nada en `output.txt` |
| 6 | `isras_share` | **`acotado`** | Parte salarial del ISR en [0, 1] (FLAG 27; con `libre` la mediana era 1.150) | `INCD` de ISRAS/ISRPF/Laboral/ImpuestosAportaciones/AportacionesNetas; `APORT*`, `PROY*`; SankeySF (medido en 8.16a R2: 45 líneas) |
| 7 | `obligacion_isrpf_ancla` | **`itan_rangos`** | PF por los 11 rangos de ingreso anual declarado del ITAN 4T 2024 (PF con + sin actividad empresarial, mdp); los rangos con recaudación negativa y «Resto» ∝ ENIGH; asalariados por total (LIF). Retiro de `ISRInformesTrimestrales.xlsx` desde 2019-1 (CUAD-1 §8 ter); 2013–2018 con sello amarillo | `INCD` de ISRPF, Laboral, ImpuestosAportaciones, AportacionesNetas; `APORT*`, `PROY*`; SankeySF |
| 8 | `informalidad` | **`corte`** | Formal = los de mayor *p* del probit de salarios hasta N; el corte **se aplica** (hasta v8.15.3 se calculaba y no tocaba `ISR_asalariados`). `probabilistica` no implementada | `INCD` de ISRAS y agregados (con el 9) |
| 9 | `ancla_formales` | **`imss`** | N = 25,500,447 (IMSS 22,238,379 + ISSSTE 3,262,068 al 31-dic-2024); el residuo Σ obligación(formales) − LIF se imprime como **«ajuste por subreporte de ingresos altos»** con sello rojo y **no** como evasión; nada en la página dice «evasión» | `INCD` de ISRAS y agregados; `APORT*`, `PROY*`; SankeySF |
| 10 | `iepsnp_macro` | **`divsim`** | IEPS no petrolero macro = IEPSNP de divSIM (224.780 = no petrolero 24.075 + salud 200.705) | nada; solo el log (`DifIEPSNP`, cobertura) |
| 11 | `ieps_relativo` | **`micro`** | Ficha 4 | ver ficha 4 |

Gates nuevos (1e-9) en el log: Σ Cpriv = P.3 S.14 23,381.329; Σ cuotas = D.61 por sector; Σ ISR personas = D.51 S.14; Σ ISR PM = D.51 S.11 + S.12; Σ IEPS repartido = LIF por tipo. `nta-identidad.txt`: Σ S sin ancla vs B.8n debe quedar en el Δ esperado de CUAD-1 §7 (≈ −0.9 %); si difiere en más de 2 puntos, se para y se descompone (ver §E).

Numeración y release: `baseline = v8.16.0`; `data_updated` = fecha del merge; asset `itan-congelado.zip` `desde v8.16.0`; `[v8.16.0]` del CHANGELOG declara «a partir de v8.16.0 los números no comparan con ≤ v8.15.3 por: …» (lista de esta sección) y la tabla Δ real vs Δ esperado (Cpriv, Σ S, INCD por impuesto, INGRESOSTEF).

## C. Los tres árboles: el clon de Dropbox es intocable

- **Clon de Dropbox** (`~/Library/CloudStorage/Dropbox-CIEP/…/SimuladorCIEP`): es el árbol que abre el IDE y el que Dropbox sincroniza. **Ninguna sesión ni ningún script lo toca**: ni `stash`, `reset`, `checkout`, `switch`, `pull` ni `merge`; tampoco escribe archivos ahí. Lo que haya en él (ramas, cambios sin commit, conflictos) es de Ricardo.
- **Worktree de sesión** (`~/CIEP_Simuladores/wt-<tema>` o `SimuladorCIEP-<tema>`): rama propia desde `origin/master`, `raw/` y `master/` clonados de `-datos` (`cp -Rc`), desechable.
- **Clon de publicación `-datos`** (`~/CIEP_Simuladores/SimuladorCIEP-datos`): tiene `master` extraído y los datos canónicos; es donde corre `ritual.sh`. El paso `baile` hace `fetch` + `checkout master` + `pull --ff-only` **solo ahí**. `--dropbox` deja de existir.
- Runbook §10.3–§10.4 y las tres plantillas de `02_governance/prompts/` dicen esto mismo desde 8.16b.

## D. Estándar de los cuadros del log

Todo cuadro que imprime un módulo (`Households`, `NTA`, `Expenditure`, `TasasEfectivas`, `SCN`) y `contrato-32.md` sigue estas reglas, que `_tabla_anclas.ado` v2 implementa:

1. **Rótulo** = nombre de la cuenta tal como lo escribe INEGI (catálogo `05_scripts/scn-cuentas.csv`), **sin paréntesis**; lo que iba entre paréntesis es una nota al pie.
2. **Código y sector en columnas propias** (`D.1`, `B.3n`, `724602`, `ISRAS`; `S.14`, `S.13`, `S.14+S.15`).
3. **Todo comentario o parámetro va a una nota al pie**: marcador `^n` pegado al rótulo (o al título) y `Nota n: …` debajo del cuadro, numeradas en orden de aparición (la 1 es el sello y su razón).
4. **Columnas de ancho fijo alineadas por caracteres** (los acentos no desalinean); **separador de miles** en todo valor (`%21.0fc`); factores con cuatro decimales; «—» cuando no aplica.
5. **Los gates debajo del cuadro, una línea cada uno, alineados**: `GATE <tol> <texto> <a> vs <b> reldif <d> OK|ROJO`.
6. En `nta-identidad.txt`: mismos principios (cuadros numerados, notas al pie, `%11.1fc`, gates al final de cada cuadro).

El formato de referencia es el cuadro del Paso 4 de `Households.do` tal como sale en el log de la corrida de la sesión 8.16b; se adjunta en el reporte de la sesión y en CUAD-1 §4.0.

## E. Lo que 8.16b no cierra y se declara

- **Fila τ⁺ vs D.62 + D.7 netas (+461.0 bn)**: donativos a ISFLSH (D.751 274.349 vs ENIGH 88.773), primas netas de seguros (116.394), remesas enviadas (23.889) y D.759 privado (23.578) son CUAD-2 (8.17). Con D.5 (→ D.51 S.14) y Cpriv (→ P.3 S.14) cerrados en 8.16b, la brecha de Σ S sin ancla la lleva íntegra esta fila más D.59 (21.1) e ImpProd (−17.0); el −0.9 % de CUAD-1 §7 es el Δ esperado **después de 8.17**. El valor observado y su descomposición van en `nta-identidad.txt` (cuadro 3) y en el reporte.
- **FLAG 27 (subreporte de ingresos altos)**: con N = 25.5 M formales la obligación del motor no alcanza la LIF; el residuo se declara con sello rojo, no se corrige (línea 9.x, top incomes).
- **FLAG 33**: `gastotarjetas` fuera; INEGI publica el gasto con tarjeta aparte de `gastohogar`; si Ricardo decide que es consumo del trimestre, vuelve con un parámetro.
- **IEPS micro incompleto**: gasolinas fuera de `Expenditure.do` §6; el ancla LIF manda y el reparto va ∝ micro.
- **`consumo_precios = basicos`, `informalidad = probabilistica`, `retenido_a_personas`, `deficit_a_personas`**: 8.17.
