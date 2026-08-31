# DIAGNÓSTICO — Tasas efectivas e incidencia fiscal federal: Nuevo León (Fase 0)

**Rama:** `feature/entidad-nl` · **Fase:** 0 (solo lectura; ningún cambio de código)
**Bases leídas:** `01_modulos/Households.do`, `01_modulos/Expenditure.do`, `01_modulos/PerfilesSim.do`, `TasasEfectivas.ado`, `Simulador.ado`, `INCI.ado`, `escalar.ado`, `scalarlatex.ado`, `scalarjson.ado`, `SIM.do`, `01_modulos/output.do`.
**Verificación empírica:** corrida de solo lectura sobre `master/2024/households.dta` (Stata 17 MP, 2026-08-31).

---

## 0.1 Ajuste a Cuentas Nacionales

### 0.1.1 Ingresos (Households.do)

El ajuste ENIGH→SCN de ingresos ocurre en **`Households.do`, sección 9 "Altimirs" (líneas ~2074–2112)**. Es un ajuste multiplicativo tipo Altimir por gran componente de ingreso:

| Factor (scalar Stata) | Definición (numerador SCN / denominador ENIGH ponderado) | Se aplica a |
|---|---|---|
| `TaltimirSal` | (RemSal + SSEmpleadores + SSImputada + parte laboral de ImpNetProduccionL) / Σ`ing_subor` | `ing_subor`, `*_t4_cap4..cap9` |
| `TaltimirSelf` | (MixL + MixKN + partes de ImpNetProduccionL/K e ImpNetProductos) / Σ`ing_mixto` | `ing_mixto*`, `*_t4_cap2pf`, `*_t4_cap3pf`, `*_t4_cap5..cap9` |
| `TaltimirCap` | (ExNOpSoc + partes de impuestos − ingresos propios de IMSS/ISSSTE/CFE/Pemex/FMP/OtrasEmpresas) / Σ`ing_capital` | `ing_capital`, `ing_t2_cap1`, `ing_t2_cap8`, `ing_t4_cap2PM`, `ing_t4_cap3PM` |
| `TaltimirHouse` | (ExNOpHog + partes de impuestos) / Σ`ing_estim_alqu` | `ing_estim_alqu` (alquiler imputado) |
| `TaltimirROWTrans` | ROWTrans / Σ`ing_remesas` | `ing_remesas` |

Los agregados macro provienen de **`SCN.ado`** (`SCN, anio() nographs`, líneas 108–130 de Households.do): `PIB`, `RemSal`, `SSEmpleadores`, `SSImputada`, `MixL`, `MixKN`, `ExNOpSoc`, `ExNOpHog`, `ImpNetProduccionL`, `ImpNetProduccionK`, `ImpNet`, `ROW*`, `CapFij`, `ConGob`; complementados con `PEF.ado` y `LIF.ado` (empresas públicas, cuotas, ISR observado).

Complementos del ajuste (misma sección o cercanas):
- Imputaciones vía `Distribucion.ado` (proporcionales a una variable micro contra un macro): empresas públicas (`ing_cap_imss/issste/cfe/pemex/fmp/otrasempr`, líneas 2062–2069), impuestos a la producción/productos (líneas 2405–2427), depreciación (`gasto_anualDepreciacion`, línea 2296), gasto de gobierno, ROW.
- **Cola derecha (secciones 7 y 8.1)**: activa solo si `betamin > 1`. Para ENIGH 2018+ `betamin = 1` (línea 21), por lo que hoy **está inactiva** (verificado: `factor_original` no existe en `households.dta` 2024).

### 0.1.2 Consumo (Expenditure.do)

El ajuste del gasto ocurre en **`Expenditure.do`, sección 4.1 "Factores de escala" (líneas ~1000–1017)**: para cada una de las 19 categorías SCN (Alim, BebN, BebA, Taba, Vest, Calz, Alqu, Agua, Elec, HogaT, SaluT, Vehi, FTra, STra, ComuT, RecrT, EducT, RestT, DiveT):

```
TT`k' = (M`k' / SCN`k')^(-1)          // M`k' = Σ gas_pc_`k' [aw=factor]
replace gas_pc_`k' = gas_pc_`k' * TT`k'
```

Para las bases de **IVA** (§5.1, línea 1151) y **IEPS** (§6.1, línea 1229) el reescalado es **un solo factor global** `ConHog/MTot` (consumo de hogares SCN sobre total ENIGH), **no** los `TT` por categoría.

### 0.1.3 ¿Escalares guardados o recalculados?

**Se recalculan en cada corrida.** Viven como *scalars* de Stata en memoria (`Taltimir*`, `TT*`, `M*`) y algunos se registran vía `escalar` (`TaltimirSalF`, `TT`k'`, etc.) para el libro/JSON. **No hay archivo de factores.** Lo que sí persiste son las **bases micro ya ajustadas**: `master/<anio>/households.dta`, `expenditures.dta`, `consumption_categ_iva.dta`, `consumption_categ_ieps.dta`. Todo consumidor aguas abajo (PerfilesSim, TasasEfectivas, SIM.do) parte de esas bases post-ajuste. **Esto es exactamente el punto de corte que necesita NL: filtrar después de cargarlas hereda los factores nacionales sin recalibrar.**

### 0.1.4 ¿Sobrevive la entidad hasta la base micro final?

- `ubica_geo` se une en `Households.do` línea 1295–1296 (`merge ... keepusing(tot_integ ubica_geo factor)`), pero **se pierde en el `collapse` de las líneas 1909–1911** (no está en la lista de variables). Verificado empíricamente: `households.dta` 2024 **no** contiene `ubica_geo`.
- En `Expenditure.do`, `ubica_geo`/`estado` existen en `preconsumption.dta` (§2.9, líneas 271–274) pero no sobreviven a los `collapse`/`reshape` de la sección 3.
- **Sin embargo, `folioviv` sobrevive en todas las bases finales**, y sus **2 primeros dígitos son la entidad federativa** (convención ENIGH que el propio repo ya usa: `PerfilesSim.do` líneas 477–478, `g entidad = substr(folioviv,1,2)`). El ajuste Altimir (§9) ocurre **después** del collapse, así que la entidad es derivable tanto en el punto del ajuste como en la base final. **No hay pérdida efectiva de información de entidad.**

---

## 0.2 Impuestos simulados a nivel micro

Todos se calculan en `Households.do` / `Expenditure.do` y quedan como variables micro en `households.dta` (persona) y `consumption_categ_*.dta`:

### ISR sueldos y salarios (`ISR_asalariados`)
1. **Bruto desde neto** (§6.2–6.3, líneas 1678–1741): la ENIGH reporta salarios netos (supuesto documentado, línea 391); se invierte la tarifa del ISR (`matrix ISR`, con CF/tasas por año) y el subsidio al empleo (`matrix SE`, prorrateado por horas `htrab/40`), descontando exenciones (Art. 93 LISR: aguinaldo, primas, horas extras, etc., sección 3) y cuotas del trabajador → `ing_subor` (bruto) e `isrE` (retención).
2. **Recálculo final** (§10–11.1, líneas 2118–2258): tras Altimir, se aplica la tarifa a `ing_bruto_tax − exen_tot − deduc_isr − cuotas netas` (deducciones personales del Art. 151 limitadas a min(5 UMA anual, 15% del ingreso); `deduc_*` provienen de `Expenditure.do` §2.5). `ISR_asalariados = ISR × ing_subor/(ing_bruto_tax − cuotasTPF)`.
3. **Formalidad**: probit (edad, sexo, escolaridad, rural, SINCO, SCIAN, tipo/tamaño de empresa; §10.2) ordena a los contribuyentes; **cut-off acumulado contra el macro LIF `ISRSalarios`** (línea 2258): solo pagan los primeros hasta agotar la recaudación observada. Incidencia: el trabajador.

### ISR ingreso de capital de personas físicas (`ISR_PF`)
`ISR_PF = ISR − ISR_asalariados` (línea 2274), con probit propio (§10.3) y cut-off contra `ISRFisicas` (LIF). La base son los capítulos II–IX del Título IV (honorarios pf, arrendamiento pf, enajenación, adquisición, intereses, premios, dividendos, otros), con las particiones PF/PM de servicios profesionales y arrendamiento calibradas con SCN (líneas 448–449 y 458–459).

### ISR personas morales (`ISR_PM`)
**Sí existe a nivel micro** (§11.3, líneas 2296–2308): `ISR_PM = (ing_bruto_tpm + gasto_anualDepreciacion − exen_tpm) × 0.30 − SE_empresas`, con probit (§10.4) y cut-off contra `ISRMorales` (LIF). `ing_bruto_tpm` = ingresos empresariales T2 + agro T2-cap8 + partes PM de honorarios/arrendamiento; la depreciación se imputa proporcional a `ing_capital` contra `CapFij` de SCN. **Supuesto de incidencia implícito: el ISR PM recae 100% en los hogares perceptores de ingreso de capital** (no hay traslación a precios ni a salarios). No está rotulado como supuesto en el código; conviene declararlo en cualquier salida NL.

### IVA (`IVA`, en `consumption_categ_iva.dta`)
`Expenditure.do` §5 (líneas 1124–1197). Once categorías de ley (`categ_iva`, §2.12) con régimen en `matrix IVAT` (1=tasa cero, 2=exento, 3=gravado, tasa general 16%):
- Gravado: `IVA += precio×cantidad × t/(1+t)`.
- Exento: solo grava la fracción del **valor agregado del último eslabón** `prop` (= VACB/PBT por clase SCIAN del Censo Económico, §2.7–2.8): `IVA += precio×cantidad×prop × t/(1+t)`.
- Tasa cero: 0.
- **Compras informales**: la variable `informal` (lugar de compra 01/02/03/17, §2.15 línea 476) **se crea pero no entra al cálculo base**. La evasión/informalidad del IVA es el parámetro `IVAT[13,1]` (7.77 en Expenditure.do; 23.0 en SIM.do §4.5) que se aplica **solo en el módulo de simulación** `IVA_Mod.do` línea 47: `IVA_Sim = IVA×(1−IVAT[13,1]/100)`. En el pipeline nacional estándar (`TasasEfectivas, enigh`) el micro-IVA se reescala vía `Distribucion` al macro LIF, lo que absorbe implícitamente la evasión.

### IEPS (`IEPS`, en `consumption_categ_ieps.dta`)
`Expenditure.do` §6 (líneas 1208–1308). Categorías `categ_ieps` (§2.13); `matrix IEPST` con componentes ad valorem y cuota específica; se retira primero el IVA del precio (`/(1+0.16)`) y luego `t/(1+t)` + cuota×cantidad. Gasolinas y "Sin IEPS" quedan fuera del cálculo micro base.

### Cuotas a la seguridad social (`cuotasT/P/F`, `cuotasTPF`)
`Households.do` §6.1 (líneas 1422–1587): SBC = salario/360/UMA con piso 1 y techo 25 UMA (IMSS) o 10 UMA (ISSSTE); matrices `CSS_IMSS` y `CSS_ISSSTE` por ramo de aseguramiento, separando **trabajador (`*T`), patrón (`*P`) y federación (`*F`)**; INFONAVIT 5% adicional. La formalidad (IMSS/ISSSTE/Pemex/otros/independiente) viene de derechohabiencia y prestaciones (§5).

### Reescalado final a macros de política (PerfilesSim.do)
`PerfilesSim.do` genera `master/perfiles<anio>.dta`: reescala el factor a la población proyectada (líneas 168–172) y crea las variables **`ISRAS`, `ISRPF`, `CUOTAS`, `ISRPM`, `OTROSK`, `IVA`, `IEPSNP`, `IEPSP`, `ISAN`, `IMPORT`, `FMP`, `PEMEX`, `CFE`, `IMSS`, `ISSSTE`** vía `Distribucion` (perfil micro reescalado al macro LIF del año de política). `TasasEfectivas, enigh` (§7) genera de ahí `*_Sim` y guarda `users/$id/ingresos.dta`. **Este es el nivel donde viven las cargas por persona que consume la incidencia.**

---

## 0.3 Tasas efectivas nacionales

### Dónde se calculan
**`TasasEfectivas.ado`** (secciones 3–6). Numeradores y denominadores exactos (todos en % del PIB):

| Base | Numerador (recaudación) | Denominador (base macro potencial) |
|---|---|---|
| Salarios | `ISRASPIB` (escalar de SIM.do §4.1 o `ISR_Mod`) | `RemSalSSPIB = RemSalPIB + SSImputadaPIB + SSEmpleadoresPIB + ImpNetProduccionLPIB` (SCN) |
| Salarios (cuotas) | `CUOTASPIB` | `RemSalSSPIB` (mismo) |
| Mixto | `ISRPFPIB` | `MixLPIB` (SCN) |
| Capital privado | `ISRPMPIB`, `OTROSKPIB`, `FMPPIB` | `IngKPrivadoPIB = CapIncImpPIB − (PEMEX+CFE+IMSS+ISSSTE)PIB` |
| OyE públicas | `PEMEXPIB`, `CFEPIB`, `IMSSPIB`, `ISSSTEPIB` | `CapIncImpPIB` |
| Consumo (IVA, Import) | `IVAPIB`, `IMPORTPIB` | `ConHogPIB` (SCN) |
| Consumo (ISAN) | `ISANPIB` | `VehiPIB` |
| Consumo (IEPS NP) | `IEPSNPPIB` | `AlcTabJuePIB = BebA+Taba+Recre7132` |
| Consumo (IEPS P) | `IEPSPPIB` | `ConsPriv21PIB` |

Nota: los numeradores `*PIB` son **parámetros de política** fijados a mano en `SIM.do` §4.1 (líneas 145–162, p. ej. `ISRASPIB = 3.748`) o re-estimados por `ISR_Mod.do`/`IVA_Mod.do` cuando hay cambio de política. Los denominadores salen de `SCN.ado` en cada corrida.

### Escalares exportados hoy relacionados con tasas efectivas
Vía `escalar` (registro `$scalarlatex_reg`, consumido por `scalarlatex`/`scalarjson`/`output.do`):

- **TE (tipo `pct`)**: `ISRASTE`, `ISRPFTE`, `CUOTASTE`, `YlImpTE`, `ISRPMTE`, `OTROSKTE`, `FMPTE`, `IngKPrivadoTotTE`, `PEMEXTE`, `CFETE`, `IMSSTE`, `ISSSTETE`, `IngKPublicosTotTE`, `IVATE`, `ISANTE`, `IEPSNPTE`, `IEPSPTE`, `IMPORTTE`, `ingconsumoTE`.
- **Agregados (tipo `pctpib`)**: `YlImpPIB`, `IngKPrivadoPIB`, `ImpKPrivadoPIB`, `IngKPublicosTotPIB`, `ImpKPublicosPIB`, `ingconsumoPIB`.
- `output.do` los imprime en el bloque `INGRESOSTEF` (líneas 51–71) hacia `users/$id/output.txt` (contrato con la web; parser sensible a posición).

### Incidencia nacional existente
La rutina de incidencia es **`Simulador.ado` §1.3.3 + `INCI.ado`**: por variable de impuesto/gasto, colapsa por hogar y **decil nacional** (variable `decil` de `households.dta`, creada en `Households.do` líneas 2591–2598: `xtile` de `ing_decil_pc` = ingreso bruto del hogar per cápita, peso `factor/tot_integ`), y postea `xhogar` (monto por hogar), `distribucion` (% del total) e `incidencia` (= carga / `ingbrutotot` del decil × 100). Exporta por decil: `escalar mxnpc <var><decil>`, `escalar pct dis<var><decil>`, `escalar pct inc<var><decil>` (Simulador.ado §4.1–4.3), y bloques `INCD/INCD2/INCD3` a `output.txt`.

---

## 0.4 Muestra de Nuevo León (base final post-ajuste)

Fuente: `master/2024/households.dta` (304 variables, 308,598 obs persona), `entidad = real(substr(folioviv,1,2))`. Corrida de verificación de solo lectura (log en `/tmp/diag_nl_04.log`, no versionado):

| Concepto | Muestra (obs) | Expandido (factor) |
|---|---:|---:|
| Hogares NL (`entidad==19`) | **3,796** | 1,859,166 |
| Personas NL | **12,586** | 6,136,446 |
| Hogares nacionales | 91,414 | — |
| Personas nacionales | 308,598 | 130,325,969 |

### Hogares NL por decil **nacional**

| Decil | Hogares (muestra) | Hogares (expandido) | % expandido |
|---|---:|---:|---:|
| I | 426 | 69,939 | 3.8 |
| II | 345 | 107,498 | 5.8 |
| III | 398 | 152,641 | 8.2 |
| IV | 394 | 192,480 | 10.4 |
| V | 349 | 164,311 | 8.8 |
| VI | 414 | 226,199 | 12.2 |
| VII | 396 | 236,147 | 12.7 |
| VIII | 348 | 223,868 | 12.0 |
| IX | 386 | 255,018 | 13.7 |
| X | 340 | 231,065 | 12.4 |
| **Total** | **3,796** | **1,859,166** | 100.0 |

**Ningún decil nacional tiene < 100 hogares NL** (mínimo: 340, decil X). La muestra soporta tanto deciles nacionales como deciles estatales (~380 hogares por decil estatal). La distribución expandida confirma el sesgo esperado de NL hacia deciles altos (63.9% en VI–X).

---

## 0.5 Bifurcaciones (opciones, criterios y recomendación)

### B1. Cómo derivar la entidad en la base final
- **(a) `substr(folioviv,1,2)` en el punto de corte** — cero cambios aguas arriba; convención ya usada por el repo (`PerfilesSim.do:477`); verificada contra población NL (6.14M expandido, consistente con CONAPO). **← Recomendada.**
- (b) Preservar `ubica_geo` a través del `collapse` de `Households.do:1909` — tocaría el módulo nacional y obliga a regenerar `households.dta`, arriesgando la no-regresión byte-a-byte sin ganancia (el dígito de entidad ya viaja en `folioviv`).

### B2. Dónde insertar la opción `entidad(numlist)`
- **(a) Post-carga de las bases ajustadas** (`households.dta` / `perfiles<anio>.dta` / `consumption_categ_*.dta`), es decir, en el tramo `PerfilesSim.do`→`TasasEfectivas.ado` o en un driver que filtre inmediatamente después de `use`. Hereda todos los factores nacionales tal cual; sin argumento el flujo no se toca. **← Recomendada.**
- (b) Opción `entidad()` en `Simulador.ado` — el motor lo comparte todo el pipeline (Households, Expenditure, GastoPC…); un filtro ahí multiplica superficie de regresión y mezclaría el corte con el bootstrap/deflactación.
- (c) Filtrar dentro de `Households.do`/`Expenditure.do` — **descartada**: recalibraría Altimir/TT con totales de NL, violando la regla de oro.

### B3. Colisión de nombres de escalares
`Simulador.ado`/`TasasEfectivas.ado` generan escalares con nombre derivado de la variable (`ISRASGPIB`, `incISRASX`, `ISRASTE`…). Correr la misma rutina sobre el subconjunto NL con los mismos nombres de variable **pisaría el registro nacional** (contrato *last-wins* de `escalar.ado`).
- **(a) Variables espejo con sufijo** (`ISRAS_nl`, …) antes de invocar la rutina de incidencia, de modo que los escalares nazcan con namespace propio (`ISRAS_nlGPIB`, `incISRAS_nlX`, `ISRASTE_nl`…); adiciones puras al registro, cero renombres. **← Recomendada.**
- (b) Correr nacional→exportar→NL confiando en el orden — frágil: cualquier re-corrida parcial contaminaría el registro.

Para el juego de deciles estatales se necesita un segundo sufijo (propuesta: `_nl` = hogares NL en deciles nacionales; `_nl_de` = deciles estatales), a confirmar en F1.

### B4. Deciles estatales
`decil` (nacional) viene grabado en `households.dta`. El decil estatal se recalcularía en el corte con **los mismos criterios** (`xtile` de `ing_decil_pc`, peso `factor/tot_integ`, n(10)) restringido a `entidad==19`. Sin opciones en conflicto; solo se deja constancia de que **no** debe reutilizarse el `xtile` de respaldo de `Simulador.ado:251` (ese ordena por la variable de impuesto, no por ingreso).

### B5. Pesos y reescalado poblacional
`PerfilesSim.do:171` reescala `factor` a la población nacional proyectada (`Poblaciontot.dta`). Para NL se hereda ese factor tal cual (post-reescalado nacional); la diferencia contra la población CONAPO-NL se **declara** en el bloque de conciliación (razón: *denominador*), no se corrige. La ENIGH 2024 tiene representatividad estatal, así que los totales NL expandidos son utilizables.

### B6. Parámetros nacionales que NL hereda sin ajuste (a declarar, no corregir)
- Factor de evasión IVA `IVAT[13,1]` (nacional).
- Cut-offs de formalidad por probit (umbral nacional de recaudación LIF): la informalidad implícita de NL queda determinada por el ranking nacional, no por un margen estatal (razón: *cobertura*).
- Partición PF/PM de honorarios/arrendamiento y VA-ratio del Censo Económico (nacionales por clase de actividad, no por entidad) (razón: *clasificación*).

---

## Fase 2 — Especificación (NO implementar)

### (a) Reajuste biproporcional 32 entidades con restricción nacional
Objetivo: una matriz de factores entidad×base que distribuya los agregados nacionales ya ajustados a CN entre las 32 entidades, sin alterar la suma nacional (los factores Altimir/TT actuales quedan como restricción de margen). Método: RAS/IPF sobre la matriz de masas ENIGH expandidas `m(e,b)` (e = entidad; b = base: salarios, mixto, capital, y consumo por componente), con márgenes columna = agregados nacionales del pipeline actual y márgenes fila = proxies estatales: masa salarial ENOE (promedio anual de remuneraciones × ocupados por entidad) para salarios; participación de la entidad en PIBE por gran actividad (INEGI, para mixto/capital vía actividades no asalariadas y excedente); ITAEE/consumo estatal (o gasto ENIGH estatal reescalado) para consumo. Iterar filas/columnas hasta convergencia (<0.01%); documentar como escalares `factor_<base>_<ent>`. Decisiones abiertas: año de referencia PIBE vs. ENIGH (momento contable), tratamiento de CDMX-EdoMex (residencia vs. lugar de trabajo en ENOE), y si el consumo se ancla a PIBE o solo se reparte con margen ENIGH (riesgo de forzar contra un proxy débil). El pipeline nacional no se toca: el RAS es una capa posterior que produce pesos/factores por entidad consumidos por el mismo corte de F1 generalizado a `entidad(1..32)`.

### (b) Integración de recaudación local de NL
Para tasas efectivas *estatales completas* (federal + local): añadir al numerador NL la recaudación propia del estado — ISN (impuesto sobre nóminas NL, ~3%: base = masa salarial NL, misma base que ISR salarios/cuotas), tenencia/control vehicular (base = `gas_pc_Vehi`/parque vehicular NL), y derechos estatales (base = población o consumo). Fuentes: EFIPEM (INEGI, finanzas públicas estatales y municipales), Cuenta Pública NL / Ley de Ingresos NL, con año de corte declarado. Entrada al canal: escalares `ISNNLPIB`, `TENENCIANLPIB`, `DERECHOSNLPIB` (tipo `pctpib` contra PIB nacional o `custom` contra PIBE-NL — decidir denominador y declararlo en `criterios`), y TE compuestas `ISNTE_nl`, etc. La incidencia micro del ISN seguiría el supuesto del ISR salarios (trabajador) salvo decisión en contrario; la de tenencia, al gasto vehicular del hogar. Nada de esto altera la recaudación federal simulada: son capas aditivas con procedencia propia en `scalarjson` (`capas_declaradas`).

---

*Fin del diagnóstico. F1 no inicia hasta aprobación explícita de este documento.*

---

## Anexo F1 — Aprobación y enmiendas (2026-08-31)

F0 aprobado con **B1a, B2a, B3a-modificada, B4, B5 y B6**, más tres enmiendas obligatorias:

1. **TE-NL micro/micro**: numerador = Σ variable de impuesto de `perfiles<anio>.dta` (`entidad==19`); denominador = Σ base micro ajustada NL. No se filtra `TasasEfectivas.ado` (macro/macro). F1 incluye la validación TE nacional micro/micro vs. TE oficial macro/macro por base (escalares `Dif*TEnac`), con los componentes del denominador sin contraparte micro **declarados** (razón: cobertura), nunca imputados al vuelo: SSEmpleadores+SSImputada (salarios), ConsPriv21 (IEPS petrolero), Recre7132 (IEPS no petrolero).
2. **Nombres de escalar sin guion bajo** (alimentan macros LaTeX): sufijos `nl` (deciles nacionales) y `nle` (deciles estatales); `nac` para el espejo nacional micro/micro. Las variables Stata espejo pueden conservar `_nl`.
3. **`output.txt` intacto en F1**: toda salida NL va exclusivamente por `escalar` → `scalarjson.ado` (`users/$id/nodos/statajson_entidad-nl.json`).

**Implementación**: `TasasEfectivasMicro.ado` (motor micro/micro con opción `entidad(numlist)`; sin invocación en el pipeline nacional) + `01_modulos/EntidadNL.do` (driver: corre tras `SIM.do` en la misma sesión). Registro de escalares solo-aditivo; proxies de conciliación (masa salarial ENOE/PL 3T2024; PIBE 2023 preliminar) declarados como parámetros con fuente y corte, brechas calculadas y **nunca forzadas**.
