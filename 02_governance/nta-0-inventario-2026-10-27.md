# NTA-0 — Inventario para `NTA.do`: qué ya existe por individuo y cómo (no) cierra la identidad NTA

**Fecha:** 2026-10-27 · **Sesión:** NTA-0 (solo lectura; ningún `.do`/`.ado` cambia) · **Base:** `master` `07b9d5c`
**Insumos leídos:** `master/2024/households.dta` (19-oct-2026, 308,598 personas, 304 variables), `users/ricardo/SankeyNTA/*.json` (19-oct), `users/ricardo/aportaciones.dta` (16-oct), `master/LIF.dta`, `master/perfiles2027.dta` (solo `describe`). Las corridas de esta sesión son `tabstat`/`collapse` sobre esos archivos; no se corrió `SIM.do`.
**Convención:** cifras en miles de millones de MXN corrientes 2024 ("bn"), sumas ponderadas con `factor` (`[fw=factor]`). Las líneas citadas son de `master` `07b9d5c`.

**Objetivo.** `NTA.do` armará la cuenta de Transferencias Nacionales por individuo (Lee–Mason):

> **C − YL = (τ⁺ − τ⁻) + (YA − S)**  — el déficit del ciclo de vida se financia con transferencias netas y con reasignaciones basadas en activos.

Este memo dice qué piezas ya están por persona en el motor, con qué regla se repartieron dentro del hogar, a qué escalar de Cuentas Nacionales (SCN) están ancladas, cómo se ve la identidad con las variables **tal como están hoy** (Paso 3), y qué decisiones quedan para Ricardo (Paso 4). Cada hueco es un parámetro con opciones; aquí no se decide nada.

---

## Resumen ejecutivo (lo que hay que saber antes de leer el detalle)

1. **Todo lo micro ya está por persona y anclado a SCN 2024** (`households.dta`): ingreso laboral `Yl`, capital `Yk`, alquiler imputado, depreciación, 19 categorías de consumo privado `gas_pc_*`, y un `Ahorro` por persona. Solo falta la clave de hogar para intra-hogar (`folioviv foliohog`, está) y la edad simple (`edad`, está): el corte quinquenio × sexo sale sin tocar el motor.
2. **El `Ahorro` individual SÍ es un residual, pero no es el ahorro NTA.** Fórmula exacta (`Households.do` l. 2678-2679, con `ingbrutotot` de l. 2462):
   `Ahorro_i = ing_subor + ing_mixto + ing_capital + ing_estim_alqu + 2·ing_remesas + ing_capitalROW + ing_suborROW − gastoanualTOT`
   = ingreso **bruto de impuestos** (con pensiones, becas, donativos, herencias, préstamos y retiros adentro) − consumo privado. **No resta impuestos, no incluye consumo público, cuenta las remesas dos veces de forma explícita (y una tercera dentro de `ing_mixto`) y es negativo para todo menor de 25 años** (−70 bn en 0-4, −528 bn en 5-17, −318 bn en 18-24). Es el **déficit del ciclo de vida con el signo cambiado y sin impuestos**, no S. Suma 2,851 bn contra `AhorroN` (SCN, neto de CapFij) = −277 bn; la brecha se descompone exactamente: `ΣAhorro − AhorroN = ConGob − OyE_públicas + remesas + ComprasN = 3,916 − 1,602 + 1,186 − 373 = 3,128 bn`. Por sexo: hombres +3,760 bn, mujeres −908 bn — el sexo "ahorra" lo que el reparto intra-hogar del consumo le asigna de menos, no lo que ahorra.
3. **Las transferencias ya están en la ENIGH pero viven dentro de YL/YA** (`Households.do` §2): las pensiones contributivas (`ing_jubila`, 768 bn) están **dentro de `ing_subor` → `Yl`** (l. 434-437 → 1040 → 1728), y se les aplica el gross-up de ISR/cuotas como si fueran salario; becas, programas sociales (P042-P048), donativos, herencias, remesas, préstamos y retiros de ahorro están **dentro de `ing_mixto`** (cap5 + cap9, l. 1046) y por tanto 2/3 en `Yl` y 1/3 en `Yk` (l. 1052/1058). La Pensión para el Bienestar (`ing_PAM`, 359 bn, P104/P105) **no está en ningún agregado**; las becas Benito Juárez y los demás programas P101-P103/P106-P108 **no se leen** (l. 530 solo toma P037-P038 y P042-P048).
4. **Los impuestos por persona existen en dos sabores que no son el mismo año**: en `households.dta` (2024: ISR con corte a LIF 2024, cuotas estatutarias, IVA/IEPS estatutarios **sin** anclar a recaudación, ISAN/importaciones/otros anclados) y en `perfiles2027.dta`/`users/$id/{ingresos,gastos,aportaciones}.dta` (todo anclado a LIF/PEF **2027** con la estructura ENIGH 2024 y `factor` re-escalado a la población CONAPO 2027). Las transferencias públicas en especie y en efectivo por persona (educación por matrícula, salud, pensiones, PAM) **solo existen en el sabor 2027**; en `households.dta` el consumo de gobierno es un monto cuasi-per cápita (`gasto_anualGobierno`, l. 2431) sin perfil de edad.
5. **Con las variables tal como están, la identidad no cierra**: el residual es +1,543 bn (5.5 % de C), positivo en todos los grupos (13 % de C en 0-4, 10 % en 5-17, 13 % en 18-24, 3 % en 25-64, 9 % en 65+) y se descompone **exactamente** en `R = τ⁻ − depreciación + 2·remesas + ROW − PAM` (Tabla 3b). No es ruido: son componentes que están de un solo lado.

---

## Paso 1 — Inventario de lo distribuido por individuo en `Households.do`

Notación: "persona" = una fila `folioviv foliohog numren` de `households.dta`; "per cápita del hogar" = el monto del hogar dividido igual entre `tot_integ`; "∝ x" = repartido con `Distribucion.ado` (`y_i = x_i · MACRO / Σ_w x`, l. 4-16: imputación proporcional al relativo, exacta en el total).

### 1.1 YL — ingreso laboral

| Variable | Nace en | Regla de reparto / supuesto | Anclaje SCN 2024 | Unidad |
|---|---|---|---|---|
| `ing_t4_cap1` | l. 392-437 | Suma de claves ENIGH de sueldos, destajo, comisiones, horas extra, gratificaciones, primas, utilidades, aguinaldo, indemnizaciones **y `ing_jubila` (P032 con `act_pnea1=="2"`, l. 424-434)** | — (crudo ENIGH anualizado ×4.3333, l. 349) | persona (perceptor) |
| `ing_sueldos` | l. 1040 | = `ing_t4_cap1` | — | persona |
| `ing_mixto` | l. 1046 | = cap2pf + cap3pf + cap4 + **cap5 (donativos)** + cap6 + cap7 + cap8 + **cap9 (autor, remesas, trabajo <12, préstamos, otras percepciones, retiros de ahorro, prestaciones SS/becas/programas, herencias)** | Altimir: × `TaltimirSelf` (= (MixKN+MixL+ImpNet·shares)/Σ, l. 2086-2089; aplicado l. 2108-2110) | persona |
| `ing_mixtoL` / `ing_mixtoK` | l. 1052 / 1058 | **2/3 – 1/3** de `ing_mixto`, fijo | hereda | persona |
| `ing_subor` | l. 1691-1728 | **Gross-up** de `ing_t4_cap1`: el ingreso neto reportado + ISR retenido (`isrE`, l. 1733) + contribuciones a la seguridad social (`cuotasTPF` netas de IMP/OTR: tripartitas, incluye la patronal), por tramo ISR y subsidio al empleo; informales: = `ing_t4_cap1` | Altimir: × `TaltimirSal` (= (RemSal+SSEmpleadores+SSImputada+ImpNetProduccionL·share)/Σ, l. 2084-2085; aplicado l. 2105-2107) | persona |
| **`Yl`** | **l. 2653** | = `ing_subor + ing_mixtoL` | Σ = 15,129 bn (RemSal + SS + ImpNetL + 2/3 Mixto) | persona |

Hallazgos: (i) **pensiones dentro de YL** (768 bn crudos; tras gross-up y Altimir son más); (ii) **transferencias privadas y públicas en efectivo dentro de YL (2/3) y YA (1/3)** vía `ing_mixto`: donativos 260 bn, herencias 22 bn, becas/programas 46 bn, remesas 1,186 bn (ya anclado a ROWTrans), préstamos/retiros/otras 273 bn — todo escalado por `TaltimirSelf` como si fuera ingreso de cuenta propia; (iii) P049 "otros ingresos" va a honorarios (l. 446); (iv) **P033 = jubilaciones del exterior** se trata como remesa (l. 515) — correcto como flujo ROW, pero es pensión.

### 1.2 YA — ingreso de activos

| Variable | Nace en | Regla / supuesto | Anclaje | Unidad |
|---|---|---|---|---|
| `ing_estim_alqu` | l. 342, 352-356 | `estim_alqu` del hogar (concentrado) **÷ número de filas de ingresos del hogar** (`_N` por hogar en `ingresos.dta`, NO integrantes) y luego `collapse (sum)` por persona (l. 551, 1294): cada perceptor recibe `estim_alqu × (sus filas / filas del hogar)`; **quien no tiene fila de ingreso recibe 0** (93 % de los 0-4, 78 % de 5-17, 44 % del total) | Altimir: × `TaltimirHouse` → Σ = ExNOpHog = 1,115 bn | persona (perceptores) |
| `ing_capital` | l. 1070 | = t2_cap1 + t2_cap8 + cap2PM + cap3PM **+ `ing_estim_alqu`** | Altimir: × `TaltimirCap` (= (ExNOpSoc + ImpNetK·share + ImpNet·share − 6 ingresos propios públicos)/Σ `ing_capital` **incluyendo alqu**, l. 2090-2094; aplicado l. 2111-2113) → Σ = 6,856 bn | persona |
| `ing_mixtoK` | l. 1058 | 1/3 de `ing_mixto` | hereda → 2,508 bn | persona |
| `gasto_anualDepreciacion` | l. 2298 | ∝ `ing_capital` (consumo de capital fijo imputado a quien tiene capital) | CapFij = 6,458 bn | persona |
| `ing_Sector_Publico` | l. 2064-2071 | ∝ `pob` (= 1: per cápita uniforme) | IMSS+ISSSTE+CFE+Pemex+FMP+otras = 1,602 bn | persona |
| **`Yk`** | **l. 2659** | = `ing_capital + ing_mixtoK + ing_estim_alqu + gasto_anualDepreciacion` | Σ = 16,936 bn | persona |

Hallazgos: (i) el alquiler imputado aparece como sumando explícito y además como 1,283 bn "incrustados" dentro de `ing_capital` (la parte del excedente de sociedades que se reparte en proporción al alquiler; **el total de `ing_capital` es correcto porque Altimir lo ancla a ExNOpSoc**, pero la *distribución* del excedente de sociedades usa la vivienda propia como allocator). `Sankey.do` l. 49 resta `ing_estim_alqu` una vez; (ii) **YA incluye depreciación** (6,458 bn, 38 % de Yk) y en el Sankey vuelve a salir como "uso"; (iii) `ing_Sector_Publico` **no** está en `Yk` ni en `ingbrutotot`: entra al Sankey como origen aparte ("OyE públicas").

### 1.3 S — ahorro (lo más importante)

**Dónde:** `Households.do` l. 2678-2679 (`g Ahorro`), pasa por `Simulador` (l. 2682: perfil edad × sexo, incidencia por decil, `CICLO` sexo×edad×decil, bootstrap) y se guarda en `households.dta`. Es lo que Ricardo recuerda como "ya distribuido por individuo y por sexo": **sí** está por persona y el perfil por sexo existe, pero el reparto por sexo no es una regla de ahorro sino el reflejo del reparto del consumo (`perfilpc`) y del ingreso (ENIGH por perceptor).

**Fórmula exacta** (verificada: `Ahorro − (ingbrutotot + ing_capitalROW + ing_suborROW + ing_remesas − gastoanualTOT)` = 0 en las 308,598 filas):

```
Ahorro_i = ingbrutotot_i + ing_capitalROW_i + ing_suborROW_i + ing_remesas_i − gastoanualTOT_i
ingbrutotot_i = ing_subor_i + ing_mixto_i + ing_capital_i + ing_estim_alqu_i + ing_remesas_i      (l. 2462)
⇒ Ahorro_i = Yl_i + (Yk_i − dep_i) + 2·ing_remesas_i + ing_capitalROW_i + ing_suborROW_i − C_priv_i
```

donde `ing_capitalROW` ∝ `ing_capital` × ROWProp (l. 2433, Σ = −989 bn) y `ing_suborROW` ∝ `ing_subor` × ROWRem (l. 2435, Σ = +53 bn). El comentario de l. 2679 (`//- gasto_anualComprasN - gasto_anualGobierno`) muestra que se consideró restar consumo público y compras netas y se dejó fuera.

**Residual ¿de qué?** De *ingreso bruto antes de impuestos* menos *consumo privado*. En términos NTA, para la persona i:

```
Ahorro_i = S_i + τ⁻_i − dep_i + ing_remesas_i (la copia extra) + [transferencias recibidas que ya viajan dentro de Yl/Yk]
```

es decir, lo que la persona "no gastó" de un ingreso del que **no se le han restado los impuestos que paga** (6,924 bn en `households.dta`) ni se le ha sumado el consumo público que recibe.

**¿Suma a `AhorroN`?** No. Σ `Ahorro` = **2,851 bn**; `AhorroN` (escalar SCN, l. 556 de `SCN.ado`: ahorro bruto − CapFij) = **−277 bn**; `Ciclodevida` (l. 2673, = Yl + Yk + remesas + suborROW − C_priv) = 9,112 bn. Identidad exacta de la brecha (con los escalares del Sankey):

```
ΣAhorro − AhorroN = ConGob − OyE_públicas + ing_remesas + ComprasN
                  = 3,916.3 − 1,601.8 + 1,186.1 − 372.7 = 3,127.9 bn   ✓ (2,851.2 − (−276.7) = 3,127.9)
```

Lectura: el ahorro individual no paga el consumo de gobierno (nadie "consume" los 3,916 bn), no recibe el excedente de las empresas públicas, cuenta las remesas de más y no ve el saldo turístico. En el Sankey v1 el nodo `Ahorro` es `AhorroN` (SCN), no Σ`Ahorro`: `Sankey.do` l. 99 colapsa `gasto_anualAhorro=Ahorro` y l. 109-110 lo descarta.

**Signo por grupo** (Tabla 3): 0-4 −70 bn, 5-17 −528 bn, 18-24 −318 bn, 25-64 +3,054 bn, 65+ +713 bn. Un menor "desahorra" porque consume (con el reparto `perfilpc`) más de lo que percibe: eso es el déficit del ciclo de vida que en NTA financian las **transferencias intra-hogar**, no un desahorro. Por sexo: hombres +3,760 bn, mujeres −908 bn.

### 1.4 C — consumo privado y público

| Variable | Nace en | Regla / supuesto | Anclaje | Unidad |
|---|---|---|---|---|
| `gas_pc_<cat>` (19 categorías: Alim BebN BebA Taba Vest Calz Alqu Agua Elec HogaT SaluT Vehi FTra STra ComuT RecrT EducT RestT DiveT) | `Expenditure.do` l. 518-875, guardado l. 1152 | Gasto **del hogar** (gastohogar, erogaciones, tarjetas) ÷ `tot_integ` como punto de partida (l. 582-588) y **reparto intra-hogar por perfil edad×sexo** con `perfilpc.ado` (punto fijo tipo IPF: `x_i = G_h · m_{c(i)} / Σ_j m_{c(j)}`, conserva exactamente el gasto de cada hogar; tolerancia 1e-6; 100-600 iteraciones) **+ gasto reportado por persona** (`gastospersona`, l. 807). La escala `alfa` NTA (0.4 en 0-4 → 1 a los 20, l. 865-867) se crea pero **no se usa** | × `TT<cat>` a ConHog por categoría COICOP (l. 1044); Σ = ConHog = 24,192 bn | persona |
| `gastoanualTOT` | `Households.do` l. 2629 | = Σ `gas_pc_*` | 24,192 bn | persona |
| `gasto_anualComprasN` | l. 2633 | ∝ `gastoanualTOT` × ComprasN | −373 bn | persona |
| `gasto_anualGobierno` | l. 2431 | `Distribucion ..., relativo(factor)`: **∝ al propio factor de expansión**, no per cápita uniforme (per cápita por grupo: 27.6 k en 0-4 … 31.0 k en 25-64, ±8 % alrededor de 30.0 k) | ConGob = 3,916 bn | persona |
| `SaluGob`, `SerEGob` | escalares `SCN.ado` l. 966-970 | **no están por persona** en `households.dta`; en el Sankey entran como escalares (`Sankey.do` l. 132-139) | 949 bn / 1,055 bn | — |

**Lo que sí tiene perfil de edad del consumo público está en `perfiles2027.dta` / `users/$id/gastos.dta`** (ver Paso 2): `Educacion` por matrícula pública por nivel (`PerfilesSim.do` l. 365-436), `Salud` ∝ `gas_pc_SaluT` (l. 439: el gasto privado en salud como allocator del público), `Pensiones` ∝ `ing_jubila` de jubilados (l. 466-476), `Pension_AM` ∝ `ing_PAM` (l. 452-463), y el resto per cápita (`Otros_gastos`, `Energia`, `Federalizado`, `DEUDA`, l. 503-525) o por entidad (`Otras_inversiones`, l. 484-497). Niveles PEF 2027.

---

## Paso 2 — Reasignaciones que el motor ya calcula fuera de `Households.do`

### 2.1 Impuestos por individuo

**(a) En `households.dta` (2024, misma llave y mismo `factor` que todo lo anterior):**

| Variable | Nace en | Cómo | ¿Anclado a LIF 2024? (LIF.dta `monto` 2024) |
|---|---|---|---|
| `ISR_asalariados` | l. 2254 | ISR estatutario sobre `ing_subor` con probit de formalidad y **corte** acumulado al monto LIF (l. 2259-2260) | ≈ sí: 1,338 vs 1,254 bn |
| `ISR_PF` | l. 2276-2283 | ídem, residuo ISR − asalariados, corte a LIF | sí: 77.0 vs 77.1 bn |
| `ISR_PM` | l. 2303-2310 | 30 % × (`ing_bruto_tpm` + depreciación − exenciones) − SE, corte a LIF; **incidencia sobre el perceptor de capital** | sí: 1,351 vs 1,351 bn |
| `cuotasT/P/F`, `cuotasTP`, `cuotasTPF`, `infonavit` | l. 1451-1552 | Estatutarias por SBC (IMSS/ISSSTE), tripartitas | **no**: `cuotasTP` 1,052 vs LIF CUOTAS 566 bn; **`infonavit` se suma dos veces en `cuotasTPF`** (l. 1541 y 1549) |
| `IVA`, `IEPS` | `Expenditure.do` l. 1179-1347 (merge l. 2587-2588) | Estatutarios sobre `gas_pc_*` (tasa por clave), consumo escalado a ConHog | **no**: IVA 1,832 vs 1,408 bn (potencial, sin evasión); IEPS 28 vs 629 bn (solo lo que la ENIGH ve de alcohol/tabaco) |
| `ISAN`, `Importaciones` | l. 2643-2644 | ∝ `gas_pc_Vehi` / ∝ `gastoanualTOT` | sí (18.8 / 137.8 bn) |
| `ing_cap_{mejoras,derechos,productos,aprovecha,otrostrib}` | l. 2636-2640 | ∝ `factor` | sí (450 bn) |

**(b) En `perfiles<anioPE>.dta` (`PerfilesSim.do`) y `users/$id/{ingresos,gastos,aportaciones}.dta` (SIM.do §7):** misma llave `folioviv foliohog numren`, **pero `factor` re-escalado a la población CONAPO del año PE** (l. 175-179: 135.4 M en 2027 vs 130.3 M en `households.dta`) y **todos los montos re-anclados con `Distribucion` a LIF/PEF/SCN del año PE** (ISRAS, ISRPF, CUOTAS, ISRPM, OTROSK, IVA, ISAN, IEPSNP, IEPSP, IMPORT, l. 218-311; ingresos públicos de capital l. 319-351). `TasasEfectivasMicro.ado` lee ese archivo (no `households.dta`) y agrega: no emite nada nuevo por persona. **Compatibilidad con `households.dta`: llave sí; factor no; año no.** Para un NTA 2024 habría que correr el mismo bloque de `Distribucion` con LIF/PEF/SCN **2024** (el código es reutilizable tal cual: `PerfilesSim.do` parametriza el año).

### 2.2 Incidencia del gasto público por individuo

Todo lo que hay está en `perfiles2027.dta`/`gastos.dta` (ver 1.4) y se agrega en `aportaciones.dta` (SIM.do l. 456-495): `Transferencias = Pensiones (+Pensión_AM) + IngBasico + Educacion + Salud + OtrasInversiones`, `ImpuestosAportaciones = ISRPM+ISRAS+ISRPF+CUOTAS+IVA+IEPSNP+IEPSP+ISAN+IMPORT` (sin OTROSK ni FMP), `AportacionesNetas = ImpuestosAportaciones − Transferencias`. Por grupo de edad, **niveles 2027** (Tabla 5). `SankeySF.do` consume `aportaciones.dta` por corte; nada adicional por persona. `Distribucion.ado` es el único mecanismo de imputación en todo el motor (proporcional al relativo): lo que es per cápita lo es porque el relativo es `pob`; lo que es ∝ `factor` (gobierno, otros LIF, inversión por entidad) **no** es per cápita.

### 2.3 Transferencias en la ENIGH (claves 2024, `Descriptor de archivos.pdf`) y dónde caen hoy

| Clave ENIGH | Concepto | Variable | Dónde termina hoy |
|---|---|---|---|
| P032 (`act_pnea1=="2"`) | Jubilaciones y pensiones del país | `ing_jubila` (l. 434) | **`Yl`** (vía cap1 → `ing_subor`, con gross-up) |
| P032 (otros) | ídem, no jubilado | `ing_indemn` (l. 425) | `Yl` |
| P033 | Jubilaciones del exterior | `ing_remesas` (l. 515) | `ing_mixto` (2/3 `Yl`, 1/3 `Yk`) **y** `ingbrutotot` **y** `Ahorro` (3 veces) |
| P041 | Remesas | `ing_remesas` | ídem |
| P037, P038 | Becas privadas / del gobierno | `ing_benef` (l. 530) | `ing_mixto` |
| P042–P048 | PROCAMPO, otros programas adultos mayores, otros programas sociales | `ing_benef` | `ing_mixto` |
| P039, P040 | Donativos de ONG / de otros hogares | `ing_dona` (l. 480) | `ing_mixto` (cap5) |
| P057 | Herencias | `ing_heren` | `ing_mixto` (cap9) |
| P104, P105 | Pensión Bienestar adultos mayores / discapacidad | `ing_PAM` (l. 537) | **ningún agregado** (solo `PerfilesSim` l. 452-463 como allocator) |
| P101–P103, P106–P108 | Becas Benito Juárez (básica, media superior), Jóvenes Escribiendo el Futuro, Estancias, Seguro Jefas de Familia, Jóvenes Construyendo el Futuro | — | **no se leen** |
| P051, P052, P053, P064, P065, P066 | Retiros de ahorro, préstamos, hipotecas, seguros de vida, otras percepciones financieras | `ing_ahorro`, `ing_prest`, `ing_otrocap` | `ing_mixto` (son flujos financieros, no ingreso) |

Montos 2024 (crudos ENIGH anualizados; Tabla 3a): `ing_jubila` 768 bn, `ing_PAM` 359 bn, `ing_benef` 46 bn, `ing_dona` 260 bn, `ing_heren` 22 bn, `ing_remesas` 1,186 bn (anclado), préstamos+retiros+otras 273 bn.

---

## Paso 3 — Memo de cierre: la identidad por grupo con las variables de hoy

Definiciones usadas (todo de `households.dta`, 2024, `[fw=factor]`): **C** = `gastoanualTOT` + `gasto_anualGobierno`; **YL** = `Yl`; **YA** = `Yk` (incluye depreciación); **S** = `Ahorro`; **τ⁻** = ISR(3) + `cuotasTPF` + IVA + IEPS + ISAN + Importaciones + otros LIF; **τ⁺ público** = `gasto_anualGobierno` (en especie, cuasi-uniforme) + `ing_PAM` (lo único en efectivo que **no** está ya dentro de YL/YA); **τ⁺ privado inter-hogar** = `ing_dona` + `ing_heren` (ya dentro de `ing_mixto`: se muestran pero no se suman otra vez); **R** = C − YL − (τ⁺ − τ⁻) − (YA − S).

### Tabla 3 — Identidad por grupo de edad (bn MXN 2024)

| Grupo | Pob (M) | C priv | C púb | **C** | **YL** | **YA** (incl. dep) | dep | **S** (Ahorro) | τ⁻ | τ⁺ púb cash fuera de Y (PAM) | τ⁺ priv inter-hogar (dona+heren) | remesas | **R** | R/C % |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| De 0 a 4 | 7.5 | 133.0 | 207.1 | **340.1** | **28.8** | **18.9** | 2.8 | **-69.6** | 29.6 | 0.1 | 3.7 | 9.4 | **45.1** | 13.3 |
| De 5 a 17 | 28.6 | 1,063.7 | 829.1 | **1,892.8** | **272.8** | **272.6** | 69.0 | **-527.9** | 199.0 | 2.6 | 26.7 | 34.7 | **186.8** | 9.9 |
| De 18 a 24 | 14.5 | 2,139.6 | 434.1 | **2,573.7** | **1,119.6** | **891.3** | 323.1 | **-317.7** | 521.0 | 1.9 | 36.5 | 89.7 | **330.2** | 12.8 |
| De 25 a 64 | 66.2 | 17,645.2 | 2,049.2 | **19,694.4** | **11,787.2** | **13,716.8** | 5,443.2 | **3,053.5** | 5,490.0 | 14.4 | 163.1 | 714.2 | **670.2** | 3.4 |
| De 65 y más | 13.5 | 3,210.6 | 396.8 | **3,607.4** | **1,920.8** | **2,036.5** | 619.5 | **713.0** | 684.7 | 340.0 | 52.5 | 338.1 | **311.0** | 8.6 |
| **Total** | 130.3 | 24,192.1 | 3,916.3 | **28,108.4** | **15,129.1** | **16,936.1** | 6,457.6 | **2,851.2** | 6,924.2 | 359.1 | 282.4 | 1,186.1 | **1,543.3** | 5.5 |

Σ τ⁺ público = 3,916 + 359 = 4,275 bn. Per cápita (MXN/persona/año):

| Grupo | C pc | YL pc | YA pc | S pc | τ⁻ pc | LCD = C − YL (pc) |
|---|---:|---:|---:|---:|---:|---:|
| De 0 a 4 | 45,341 | 3,840 | 2,520 | -9,286 | 3,944 | 41,501 |
| De 5 a 17 | 66,106 | 9,527 | 9,519 | -18,438 | 6,949 | 56,578 |
| De 18 a 24 | 177,200 | 77,083 | 61,364 | -21,872 | 35,872 | 100,116 |
| De 25 a 64 | 297,648 | 178,143 | 207,307 | 46,148 | 82,972 | 119,505 |
| De 65 y más | 267,195 | 142,268 | 150,839 | 52,807 | 50,713 | 124,928 |

### Tabla 3a — Transferencias que ya viajan dentro de YL/YA (no se suman en la identidad para no duplicar)

| Grupo | jubila (en YL vía ing_subor) | benef (en mixto) | dona (en mixto) | heren (en mixto) | remesas (en mixto + 2× en Ahorro) | prest+retiros+otrocap (en mixto) | PAM (en nada) |
|---|---:|---:|---:|---:|---:|---:|---:|
| De 0 a 4 | 0.0 | 0.4 | 3.7 | 0.0 | 9.4 | 0.0 | 0.1 |
| De 5 a 17 | 0.0 | 9.9 | 26.5 | 0.2 | 34.7 | 1.2 | 2.6 |
| De 18 a 24 | 0.0 | 4.7 | 36.4 | 0.0 | 89.7 | 10.8 | 1.9 |
| De 25 a 64 | 270.1 | 21.3 | 142.3 | 20.7 | 714.2 | 214.3 | 14.4 |
| De 65 y más | 498.0 | 9.9 | 51.2 | 1.3 | 338.1 | 46.3 | 340.0 |
| **Total** | 768.1 | 46.2 | 260.2 | 22.2 | 1,186.1 | 272.5 | 359.1 |

### Tabla 3b — Descomposición exacta del residual

Como `S = Yl + Yk − dep + 2·rem + capROW + subROW − C_priv`, el residual es algebraicamente:

> **R = τ⁻ − depreciación + 2·remesas + ing_capitalROW + ing_suborROW − PAM**

| Grupo | R | = τ⁻ | − dep | + 2·remesas | + capROW (−ROWProp) | + subROW | − PAM |
|---|---:|---:|---:|---:|---:|---:|---:|
| De 0 a 4 | **45.1** | 29.6 | -2.8 | 18.8 | -0.4 | 0.0 | -0.1 |
| De 5 a 17 | **186.8** | 199.0 | -69.0 | 69.5 | -10.6 | 0.5 | -2.6 |
| De 18 a 24 | **330.2** | 521.0 | -323.1 | 179.4 | -49.5 | 4.3 | -1.9 |
| De 25 a 64 | **670.2** | 5,490.0 | -5,443.2 | 1,428.4 | -833.8 | 43.4 | -14.4 |
| De 65 y más | **311.0** | 684.7 | -619.5 | 676.2 | -94.9 | 4.6 | -340.0 |
| **Total** | **1,543.3** | 6,924.2 | -6,457.6 | 2,372.2 | -989.2 | 52.7 | -359.1 |

**Lectura del residual.** (i) Es **positivo en todos los grupos** y grande en los menores (13 % de C en 0-4) porque los impuestos que se les imputan (IVA, IEPS, "otros LIF" ∝ factor) no se restan de ningún ingreso y porque las remesas van dobles; (ii) en 25-64 casi se cancela (3.4 %) porque ahí la depreciación (5,443 bn) compensa los impuestos (5,490 bn) — coincidencia, no cierre; (iii) en 65+ la PAM (340 bn) reduce el residual porque la identidad la cuenta como τ⁺ y `Ahorro` no la tiene. **Ninguno de los seis términos es ruido: cada uno está de un solo lado de la cuenta.** Un `NTA.do` que (a) reste τ⁻ al ingreso disponible, (b) saque la depreciación de YA (o la ponga como uso), (c) cuente las remesas una vez y (d) ponga PAM/becas/programas como τ⁺, cierra a cero por construcción si S se redefine como residual de la persona — lo cual lleva al Paso 4(a).

### Tabla 3c — Composición de τ⁻ por grupo (lo que hoy se imputa a cada edad)

| Grupo | τ⁻ total | ISR (3) | cuotas TPF | IVA | IEPS | ISAN | Importaciones | otros LIF (∝ factor) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| De 0 a 4 | 29.6 | 0.0 | 0.1 | 4.2 | 0.5 | 0.2 | 0.8 | 23.8 |
| De 5 a 17 | 199.0 | 6.8 | 35.0 | 52.3 | 3.2 | 0.3 | 6.1 | 95.3 |
| De 18 a 24 | 521.0 | 110.6 | 176.4 | 167.4 | 3.1 | 1.5 | 12.2 | 49.9 |
| De 25 a 64 | 5,490.0 | 2,313.8 | 1,434.3 | 1,372.1 | 18.6 | 15.2 | 100.5 | 235.5 |
| De 65 y más | 684.7 | 335.7 | 44.8 | 235.8 | 2.9 | 1.6 | 18.3 | 45.6 |
| **Total** | 6,924.2 | 2,766.8 | 1,690.6 | 1,831.8 | 28.3 | 18.8 | 137.8 | 450.1 |

(IVA/IEPS/cuotas estatutarios; ISR y otros anclados a LIF 2024: ver 2.1. 29.6 bn de impuestos en 0-4 son IVA sobre su consumo repartido + 23.8 bn de "otros LIF" ∝ factor.)

### Tabla 4 — Quinquenio × sexo (bn MXN 2024; S y R con las mismas definiciones)

| Edad | Sexo | Pob (M) | C | YL | YA | S | τ⁻ | R | R/C % |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 0–4 | H | 3.8 | 151.4 | 14.6 | 9.9 | -17.9 | 13.6 | 22.5 | 14.8 |
| 0–4 | M | 3.7 | 188.7 | 14.2 | 9.0 | -51.7 | 16.0 | 22.6 | 12.0 |
| 5–9 | H | 5.2 | 296.9 | 31.2 | 26.4 | -81.3 | 24.7 | 32.5 | 11.0 |
| 5–9 | M | 4.9 | 233.5 | 29.5 | 25.0 | -36.5 | 19.9 | 26.0 | 11.1 |
| 10–14 | H | 5.9 | 365.0 | 49.2 | 50.4 | -96.2 | 32.5 | 34.6 | 9.5 |
| 10–14 | M | 5.6 | 347.6 | 42.1 | 41.8 | -99.2 | 30.7 | 30.4 | 8.7 |
| 15–19 | H | 5.8 | 659.2 | 201.4 | 174.8 | -159.1 | 114.6 | 58.9 | 8.9 |
| 15–19 | M | 5.5 | 575.8 | 120.3 | 110.2 | -188.0 | 82.2 | 74.4 | 12.9 |
| 20–24 | H | 5.0 | 992.9 | 539.1 | 425.9 | -53.0 | 240.9 | 62.8 | 6.3 |
| 20–24 | M | 5.3 | 995.6 | 379.6 | 309.4 | -132.2 | 174.5 | 197.3 | 19.8 |
| 25–29 | H | 4.3 | 1,188.6 | 785.7 | 713.1 | 122.8 | 344.7 | 23.3 | 2.0 |
| 25–29 | M | 4.8 | 1,311.6 | 604.3 | 488.4 | -33.2 | 263.5 | 307.4 | 23.4 |
| 30–34 | H | 4.6 | 1,537.4 | 1,069.5 | 1,114.2 | 274.7 | 486.5 | -24.9 | -1.6 |
| 30–34 | M | 5.1 | 1,486.8 | 679.5 | 616.4 | -97.2 | 311.3 | 249.3 | 16.8 |
| 35–39 | H | 4.1 | 1,412.6 | 971.6 | 1,074.0 | 254.0 | 465.2 | -45.0 | -3.2 |
| 35–39 | M | 4.9 | 1,550.1 | 732.0 | 774.5 | -21.1 | 323.2 | 195.0 | 12.6 |
| 40–44 | H | 4.1 | 1,400.0 | 977.1 | 1,203.9 | 352.7 | 482.2 | -79.6 | -5.7 |
| 40–44 | M | 4.7 | 1,462.6 | 690.4 | 668.5 | -94.0 | 310.8 | 177.5 | 12.1 |
| 45–49 | H | 3.8 | 1,165.5 | 957.2 | 1,239.2 | 575.7 | 447.0 | -123.6 | -10.6 |
| 45–49 | M | 4.5 | 1,275.2 | 594.7 | 701.4 | -6.4 | 267.3 | 96.6 | 7.6 |
| 50–54 | H | 3.9 | 1,201.1 | 920.1 | 1,333.4 | 568.5 | 457.6 | -147.0 | -12.2 |
| 50–54 | M | 4.5 | 1,222.1 | 572.5 | 694.3 | -27.6 | 257.0 | 40.0 | 3.3 |
| 55–59 | H | 3.1 | 882.1 | 698.9 | 944.3 | 462.6 | 347.3 | -49.9 | -5.7 |
| 55–59 | M | 3.7 | 933.2 | 442.1 | 504.0 | -10.4 | 173.3 | 35.3 | 3.8 |
| 60–64 | H | 2.8 | 791.6 | 689.5 | 1,234.5 | 720.7 | 410.2 | -89.0 | -11.2 |
| 60–64 | M | 3.4 | 873.9 | 402.0 | 412.8 | 11.7 | 143.2 | 104.7 | 12.0 |
| 65–69 | H | 2.3 | 681.8 | 464.8 | 592.0 | 367.2 | 202.1 | 76.7 | 11.3 |
| 65–69 | M | 2.6 | 698.5 | 290.9 | 305.8 | -30.7 | 104.5 | 37.8 | 5.4 |
| 70–74 | H | 1.6 | 419.9 | 268.1 | 358.1 | 199.9 | 115.8 | 21.1 | 5.0 |
| 70–74 | M | 1.9 | 530.0 | 210.1 | 188.4 | -78.2 | 69.5 | 11.2 | 2.1 |
| 75–79 | H | 1.1 | 268.0 | 192.7 | 182.8 | 164.5 | 59.5 | 58.2 | 21.7 |
| 75–79 | M | 1.3 | 331.1 | 150.0 | 141.4 | 32.4 | 42.0 | 42.3 | 12.8 |
| 80–84 | H | 0.7 | 148.4 | 107.8 | 93.6 | 71.7 | 31.2 | 15.2 | 10.2 |
| 80–84 | M | 0.8 | 229.8 | 88.8 | 76.2 | -22.6 | 24.0 | 17.2 | 7.5 |
| 85+ | H | 0.5 | 115.8 | 71.3 | 50.4 | 32.3 | 19.0 | 19.9 | 17.1 |
| 85+ | M | 0.7 | 184.1 | 76.3 | 47.8 | -23.5 | 17.2 | 11.4 | 6.2 |

**Señales en la tabla 4:** S es negativo en **todos** los quinquenios de mujeres hasta 60-64 y en 70+ (el reparto `perfilpc` les asigna consumo por perfil edad-sexo mientras la ENIGH les registra menos ingreso por perceptor); R cambia de signo en hombres de 30-64 (depreciación ∝ capital > impuestos) y es ~20 % de C en mujeres 20-29 (consumo alto, poco capital → poca depreciación que compense). Ambos patrones son artefactos de la definición actual de S, no economía.

### Tabla 5 — Lo que ya existe de τ⁻ y τ⁺ público por persona en `aportaciones.dta` (niveles PE 2027, población 2027)

| Grupo | Pob 2027 (M) | τ⁻ (ImpuestosAportaciones) | Pensiones (+PAM) | Educación | Salud | Otras inversiones | τ⁺ púb (Transferencias) | Neto τ⁻−τ⁺ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| De 0 a 4 | 7.8 | 11.7 | 0.0 | 92.9 | 25.0 | 32.3 | 154.2 | -142.4 |
| De 5 a 17 | 29.7 | 79.3 | 0.0 | 1,009.5 | 16.0 | 129.4 | 1,159.6 | -1,080.3 |
| De 18 a 24 | 15.1 | 447.8 | 0.0 | 189.1 | 64.1 | 67.8 | 323.1 | 124.7 |
| De 25 a 64 | 68.7 | 5,546.3 | 571.5 | 87.1 | 775.4 | 321.3 | 1,764.7 | 3,781.6 |
| De 65 y más | 14.0 | 752.2 | 1,850.4 | 9.3 | 256.8 | 67.4 | 2,185.8 | -1,433.6 |
| **Total** | 135.4 | 6,837.3 | 2,421.9 | 1,388.0 | 1,137.3 | 618.1 | 5,587.3 | 1,250.0 |

Esta es la pieza que `NTA.do` necesita para τ⁺ público con perfil de edad; hoy está en el año equivocado respecto a `households.dta` (2027 vs 2024). Pensiones 65+ = 1,850 bn (incluye PAM); Educación 5-17 = 1,010 bn; Salud 25-64 = 775 bn (∝ gasto privado en salud).

---

## Paso 4 — Huecos como parámetros (decisiones de Ricardo)

Cada decisión: opciones → qué implica para el cierre. **(a)** es previa a todas.

**(a) Qué es S y qué se vuelve residual.** Hoy `Ahorro_i` ES el residual (ingreso bruto − consumo privado) y absorbe impuestos, depreciación y la copia extra de remesas.
- a1. *S individual = residual NTA de la persona*: `S_i = YL_i + YA_i + τ⁺_i − τ⁻_i − C_i`. Cierra a 0 por persona y por grupo **trivialmente**; el gate de identidad deja de informar y hay que sustituirlo por gates de agregados (Σ S = `AhorroN` ± CapFij según (a3); Σ τ⁺ intra-hogar = 0 por hogar). Los menores quedan con S ≪ 0 salvo que (d) imponga intra-hogar.
- a2. *S por hogar y reparto explícito*: `S_h = Y_h − τ⁻_h − C_h`, repartido a los adultos del hogar (por YL, por YA, o solo al jefe); los menores tienen S = 0 y su déficit lo cubre τ⁺ intra-hogar (= residual de la persona). Es el estándar NTA; el residual pasa a ser **la transferencia intra-hogar**, que suma 0 dentro de cada hogar por construcción (gate verificable).
- a3. *S anclado a SCN*: Σ S = `AhorroN` (neto, −277 bn) o `AhorroN + CapFij` (bruto, 6,181 bn), con el perfil de a1/a2 como allocator. Decide si la depreciación es uso (como en el Sankey v1) o resta de YA.
- a4. *Dejar `Ahorro` como está y documentarlo como "excedente bruto del ciclo de vida"* — entonces no hay S NTA y el Sankey v2 no puede cerrar por grupo.

**(b) Transferencias públicas en especie (educación, salud, resto del consumo de gobierno).**
- b1. *Quedan en consumo público* (como hoy: C incluye `gasto_anualGobierno`, cuasi-uniforme) y τ⁺ público en especie = ese mismo monto → se cancelan en la identidad; no hay perfil de edad del gasto público en el NTA.
- b2. *Pasan a τ⁺ con perfil de edad*: C público por persona = Educación (matrícula) + Salud (allocator a decidir: ∝ `gas_pc_SaluT` como hoy, o por edad con utilización) + resto per cápita, con `SerEGob`/`SaluGob`/`ConGob − ambos` de SCN **2024** como totales (ya existen como escalares). Es el estándar NTA (`CG` por edad) y lo que el colega externo espera. Implica reproducir el bloque de `PerfilesSim.do` l. 365-443 con macros 2024.
- b3. *b2 pero con los niveles PEF 2027* de `gastos.dta` re-escalados a SCN 2024 (misma forma, otro total). Más barato; mezcla años en la forma.

**(c) Impuestos indirectos (IVA, IEPS, ISAN, importaciones).**
- c1. *τ⁻ por persona* (sobre quien consume): C queda a precios de comprador (como hoy, ConHog incluye impuestos) y τ⁻ incluye los indirectos → **doble conteo** salvo que se reste a C o se sume a YL/YA el mismo monto (NTA estándar: C a precios de comprador y los indirectos como τ⁻ pagados *del ingreso*, con el ajuste en la "ganancia" de los recursos). Hay que elegir el lado.
- c2. *Quedan en el precio del consumo* (no son τ⁻): identidad más limpia, pero el Sankey v2 no muestra IVA/IEPS y el "τ⁻ público" será solo ISR + cuotas + otros (3,957 bn de 6,924).
- c3. Independiente de c1/c2: **¿estatutario o anclado?** Hoy en `households.dta` IVA está 30 % arriba de la recaudación y IEPS en 4 % de ella; en `perfiles` están anclados pero a 2027. Para un NTA 2024 hay que anclar a LIF 2024 (`Distribucion`, 10 líneas).

**(d) Intra-hogar.**
- d1. *Residual puro*: τ⁺ intra-hogar_i = C_i − YL_i − (τ⁺ púb − τ⁻)_i − (YA_i − S_i) con S de (a2). Suma 0 por hogar si S_h se reparte dentro del hogar. Sin supuestos adicionales; hereda el reparto `perfilpc` del consumo.
- d2. *Regla explícita*: los adultos con YL>0 financian el déficit de los dependientes en proporción a su ingreso disponible (o solo el jefe/cónyuge); S se define después. Más interpretable, más supuestos.
- d3. Decidir también el **reparto del alquiler imputado**: hoy ∝ filas de ingreso del perceptor (1.2); alternativas: al jefe del hogar, a los adultos por igual, o ∝ YA.

**(e) Brutas vs netas en el Sankey v2.**
- e1. *Brutas*: τ⁺ y τ⁻ como flujos separados por grupo (público y privado), lo que el colega describe ("stuff in the middle"); más nodos (31/79 → ~45/120).
- e2. *Netas*: un solo enlace τ⁺ − τ⁻ por grupo, con signo; menos nodos pero FusionCharts no dibuja negativos (FLAG 1 del PR #37).
- e3. Mixto: brutas para público, neto para intra-hogar (que es un residual).

**(f) Desahorro por grupo (S < 0) y cómo se dibuja.**
- f1. *Dos nodos*: "Ahorro" (S>0, de los grupos al futuro) y "Desahorro" (S<0, del futuro/activos al grupo) — todos los enlaces positivos; el Sankey cierra.
- f2. *Neto por grupo* en un solo nodo con signo — no dibuja.
- f3. *Nodo "Activos" (YA − S)* como reasignación basada en activos, NTA puro: entra a cada grupo con signo positivo si YA > S; si S > YA se dibuja del grupo a "Activos". Requiere (a).

**(g) Año del NTA.** `households.dta` es 2024 (SCN/LIF/PEF 2024); τ⁺/τ⁻ con perfil existen solo a 2027. Opciones: g1 NTA 2024 (re-correr el bloque `Distribucion` de `PerfilesSim.do` con macros 2024); g2 NTA del año PE (re-escalar YL/YA/C a SCN 2027 proyectado, como hace `PerfilesSim` §5.4-5.6); g3 ambos (2024 observado + PE proyectado), que es lo que el ciclo de vida fiscal ya hace.

**(h) Pensiones contributivas.** Hoy dentro de YL con gross-up de ISR/cuotas. Opciones: h1 sacarlas de `ing_t4_cap1` antes del gross-up (cambia `ing_subor`, `isrE`, Altimir: **toca el motor**); h2 restarlas de YL en `NTA.do` con `ing_jubila` crudo × `TaltimirSal` (aproximación, no toca el motor); h3 dejarlas en YL y documentar (no es NTA).

**(i) Flujos financieros dentro de `ing_mixto`** (préstamos, retiros, hipotecas, seguros: 273 bn): i1 excluirlos de YL/YA en `NTA.do`; i2 dejarlos (sobreestiman YL en 2/3 × 273 × TaltimirSelf).

**(j) Programas no leídos** (P101-P103, P106-P108) y `ing_PAM`: j1 leerlos en `Households.do` (toca el motor; cambia Altimir); j2 leerlos en `NTA.do` directo de `raw/ENIGH/2024/ingresos.dta` por `folioviv foliohog numren` (no toca el motor).

---

## Paso 5 — Esqueleto de `NTA.do` (sin código)

**Entradas.** `master/<anioenigh>/households.dta` (todo lo de §1); `raw/ENIGH/<anioenigh>/ingresos.dta` solo si (j2); escalares SCN del año (`SCN, anio()`: PIN, ConHog, ConGob, SerEGob, SaluGob, CapFij, AhorroN, ROWRem/Trans/Prop, ComprasN); LIF/PEF del año si (g1) para anclar τ⁻ y τ⁺ público (`LIF`/`PEF`, `by(divSIM)`/`by(divCIEP)`, el mismo bloque de `PerfilesSim.do` l. 44-128 y 218-525); parámetros (a)-(j) como `local`/`global` al inicio, con defaults declarados.

**Pasos internos.** (1) Construir por persona: `C_priv`, `C_pub` (según b), `YL` (según h, i), `YA` (depreciación según a3), `τ⁻` (según c), `τ⁺_pub` (especie + efectivo: PAM, becas, programas, pensiones si h), `τ⁺_priv_inter` (donativos, herencias, remesas una vez), `τ⁺_intra` y `S` (según a, d). (2) Gate por **hogar**: Σ_h τ⁺_intra = 0 (1e-6 relativo). (3) Gate por **grupo** (grupoedad y quinquenio×sexo): `C − YL − (τ⁺ − τ⁻) − (YA − S) = 0`; con S residual el gate es trivial, así que el gate informativo es **de agregados**: Σ YL = RemSal+SS+ImpNetL+MixL, Σ YA = …, Σ C_priv = ConHog, Σ C_pub = ConGob, Σ τ⁻ = recaudación LIF del año, Σ S = AhorroN (± CapFij). Tolerancia: 1e-9 **relativa** (la absoluta de 1e-9 MXN no es alcanzable en doble precisión con totales de 1e13: el Sankey v1 cierra a 0.09 MXN). (4) Exportar.

**Salidas.** `users/$id/NTA/nta-persona.dta` (una fila por persona con todas las columnas, llave ENIGH, `factor`, `edad`, `sexo`, `grupoedad`, `quinq`, `decil`); `users/$id/NTA/nta-grupoedad.json`, `nta-quinq-sexo.json` (tabla de la identidad por grupo: columnas C, YL, YA, S, τ⁺púb, τ⁻púb, τ⁺priv inter, τ⁺intra, residual; totales; gates con su tolerancia y resultado); `users/$id/NTA/sankey-nta2-<corte>.json` con el **mismo formato** que emite `SankeySumSim.ado` (vía `SankeySumSim, folder(NTA) name(nta2-<corte>)`, con ejes construidos en `NTA.do` como hace `Sankey.do`), para que `jsonSankeyNTA.php` lo sirva con un `corte` nuevo sin tocar el PHP más que la lista blanca; opcionalmente `nta-<corte>.csv` para el colega externo.

**Dónde se engancha en `SIM.do`.** Después de §3.2 (`Households.do`, l. 138) y antes de §3.3 (`PerfilesSim.do`, l. 142) si el NTA es 2024 y no necesita perfiles; **después de §3.3** si (b3)/(g2) reutilizan `perfiles<anioPE>.dta`. Una línea: `noisily run "${SIMROOT}/01_modulos/NTA.do" `=anioPE'`, con `$hasta == "3"` cubriéndolo. **No** en `Web.Stata.do` (la página /NTA es estática y lee el default `ciepmx`): el JSON v2 viaja por la Fase 3b-ter como `SankeyNTA/` hoy (agregar `NTA/*.json` a `DEFAULT_MANIFEST` y a `MOTOR_LECTURAS_VPS`).

**Contrato 31/79 del Sankey v1 intacto hasta que v2 lo reemplace.** `Households.do` l. 2744-2746 sigue escribiendo `users/$id/SankeyNTA/sankey-<corte>.json` sin cambios; `NTA.do` escribe en `users/$id/NTA/` (carpeta distinta, `folder(NTA)`); el gate `05_scripts/test-sitio-nta.sh` sigue comparando contra `SankeyNTA/sankey-grupoedad.json` (31 nodos / 79 enlaces) hasta que una PR del sitio cambie `NTA/index.php` a `corte=nta2-grupoedad` y el fixture; ese cambio es el "swap" y es una PR aparte, con el PNG viejo y el nuevo lado a lado. Hasta entonces, `publicar-vps.sh` embarca ambos.

---

## FLAGs (registrados, no corregidos)

1. `ing_estim_alqu` se reparte ∝ **número de filas de ingreso** del perceptor (l. 354-356 + collapse l. 551), no entre integrantes: 44 % de la población (93 % de los 0-4) tiene 0.
2. `ing_jubila` (pensiones) dentro de `ing_t4_cap1` → `ing_subor` → `Yl`, con gross-up de ISR/cuotas como salario (l. 434-437, 1709, 1728).
3. `ing_mixto` (l. 1046) mezcla ingreso de cuenta propia con transferencias (cap5, cap9) y flujos financieros (préstamos, retiros, hipotecas); todo × `TaltimirSelf` y partido 2/3–1/3.
4. `ing_PAM` (359 bn) no está en ningún agregado; P101-P103, P106-P108 no se leen (l. 530, 537).
5. `ing_remesas` tres veces en `Ahorro` (dentro de `ing_mixto`, en `ingbrutotot` l. 2462 y sumada otra vez l. 2678); dos veces en `ingbrutotot`.
6. `infonavit` dos veces en `cuotasTPF` (l. 1541 y 1549): Σ TPF 1,690 = TP 1,052 + F 417 (ya con infonavit 221) + infonavit 221.
7. `Distribucion …, relativo(factor)` (gobierno l. 2431, otros LIF l. 2636-2640) no es per cápita: ∝ al factor de cada persona (±8 % entre grupos).
8. IVA (1,832 vs 1,408 bn) e IEPS (28 vs 629 bn) en `households.dta` no están anclados a recaudación 2024; `ISR_asalariados` 1,338 vs 1,254.
9. `Yk` incluye depreciación (6,458 bn, 38 %) y el Sankey v1 la vuelve a poner como uso; `Ahorro` la excluye (usa `ingbrutotot`).
10. `alfa` (escala NTA 0.4→1) se crea en `Expenditure.do` l. 865-867 y no se usa; el reparto real es `perfilpc` (edad×sexo endógeno).
11. `Salud` pública ∝ `gas_pc_SaluT` (`PerfilesSim.do` l. 439): el gasto privado en salud como allocator del público.
12. `perfiles<anioPE>.dta`/`aportaciones.dta`: `factor` re-escalado a CONAPO del año PE (135.4 M vs 130.3 M) — no se puede hacer `merge` y sumar con `households.dta` sin re-pesar.
13. `Sankey.do` l. 11-13: todo año ≥ 2022 se fuerza a 2024 (comparación de cadenas).
14. Comentario fósil `Households.do` l. 2743 (`/var/www/html/SankeyNTA/`); el destino real es `${SIMROOT}/users/$id/SankeyNTA/`.
15. Altimir escala `*_t4_cap4`…`*_t4_cap9` dos veces (l. 2105 × `TaltimirSal` y l. 2108 × `TaltimirSelf`); `ing_mixto` solo una vez, así que los agregados no cambian, pero las componentes `ing_t4_cap4-9` y `exen_t4_cap4-9` guardadas en `households.dta` están doblemente escaladas. Las variables finas (`ing_dona`, `ing_heren`, `ing_benef`, `ing_jubila`, `ing_PAM`, `ing_prest`, `ing_ahorro`) **no** se escalan (quedan crudas ENIGH); `ing_remesas` sí (× `TaltimirROWTrans`, l. 2103).

## Reproducibilidad de los números de este memo

`tabstat`/`collapse [fw=factor]` sobre `master/2024/households.dta` (19-oct-2026) y `users/ricardo/aportaciones.dta` (16-oct-2026); LIF 2024 de `master/LIF.dta` (`monto`, `by(divSIM)`). Chequeos de identidad interna (todos 0 en las 308,598 filas): `Yl = ing_subor + ing_mixtoL`; `Yk = ing_capital + ing_mixtoK + ing_estim_alqu + gasto_anualDepreciacion`; `Ahorro = ingbrutotot + ing_capitalROW + ing_suborROW + ing_remesas − gastoanualTOT`; `ingbrutotot = ing_subor + ing_mixto + ing_capital + ing_estim_alqu + ing_remesas`; `gastoanualTOT = Σ gas_pc_*`. Los totales coinciden con los enlaces del Sankey v1 (`SankeyNTA/sankey-grupoedad.json`): Ing Laboral 15,181.8 = Σ`Yl` 15,129.1 + ROWRem 52.7; Ing Capital 17,423.1 = Σ(`Yk` − `ing_estim_alqu`) 15,821.3 + OyE 1,601.8; Ing nacional 35,278.5 cierra a 0.09 MXN.
