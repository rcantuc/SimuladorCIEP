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

---

## Anexo F1-bis — Verificación y corrección (2026-08-31)

**Premisa verificada:** la base micro reconstruye el **100.0000% del PIB** (tabla A.3). Los "faltantes por cobertura" que F1 declaró eran errores de F1 (variable equivocada o base incompleta), no limitaciones del método. F0 §0.1.1 estaba **bien descrito**: el error de F1 fue usar `ing_subor` de `perfiles<anio>.dta` sin advertir que `PerfilesSim.do:196` lo reescala a `RemSal+ImpNetProduccionL` (es decir, le quita las SS que el Altimir sí incluye).

### A.1 Dónde vive cada componente de `RemSalSSPIB`

| Componente | Variable micro | Se crea en | ¿Sobrevive a `perfiles<anio>.dta`? |
|---|---|---|---|
| Sueldos y salarios + INPL | `ing_subor` | Households.do §6.2 (post-Altimir §9; PerfilesSim.do:196 lo reescala a RemSal+INPL) | Sí |
| Cuotas trabajador | `cuotasT` | Households.do:1530 | No (dentro de `ing_subor` bruto y de `cuotasTPF`) |
| Cuotas patrón | `cuotasP` | Households.do:1533 | No (dentro de `cuotasTPF`) |
| Cuotas federación | `cuotasF` | Households.do:1536 (+INFONAVIT :1539) | No (dentro de `cuotasTPF`) |
| Total T+P+F+INFONAVIT | `cuotasTPF` | Households.do:1544-1547 | **Sí** |
| SS imputadas | vía Altimir sobre `ing_subor` (households); mapeo `cuotasTPF`↔`SSEmp+SSImp` del propio pipeline (Households.do:1665-1667) | §6.1/§9 | vía `cuotasTPF` |
| INPL (parte laboral) | `ImpNetProduccionL_subor` (Distribucion) | Households.do:2405 | No (implícito en el reescalado de `ing_subor`) |

### A.2 Verificación de una línea (`perfiles2026` + SCN 2026, sesión SIM)

| Concepto | % del PIB |
|---|---:|
| Σ `ing_subor` [aw=factor] | 25.24 (= RemSalPIB 24.79 + INPL 0.45) |
| Σ (`ing_subor` + `cuotasTPF`→SSEmp+SSImp) = `BaseSalnac` (11,440 mmdp) | **30.23** |
| `RemSalSSPIB` oficial (RemSal+SSEmp+SSImp+INPL) | **30.23** |

En `households.dta` (2024, post-Altimir, PRE-PerfilesSim): Σ`ing_subor` = 30.09% del PIB 2024 ≈ RemSal 24.79 + SSEmp+SSImp 4.99 + parte laboral de INPL — **el Altimir sí incluye las SS**, como decía F0 §0.1.1. En consecuencia, `TasasEfectivasMicro.ado` v1.1 usa `BaseSal = ing_subor + Distribucion(cuotasTPF → SSEmpleadores+SSImputada)`.

### A.3 Cobertura del PIB (households 2024 vs SCN 2024, % del PIB)

| Componente micro | Σ micro | Agregado SCN | |
|---|---:|---:|---|
| `ing_subor` | 30.09 | RemSal+SS+INPL(sal) | ✓ |
| `ing_mixto` (L 14.95 + K 7.47) | 22.42 | MixL 13.81 + MixKN 6.91 + impuestos parte | ✓ |
| `ing_capital` | 19.80 | ExNOpSoc 20.33 + imp − EP | ✓ |
| `ing_estim_alqu` | 3.33 | ExNOpHog 2.71 + imp parte | ✓ |
| `ing_Sector_Publico` | 5.13 | EP (LIF) | ✓ |
| `gasto_anualDepreciacion` | 19.23 | CapFij 19.23 | ✓ |
| **Total** | **100.0000** | PIB | **✓** |
| Memo: `cuotasT/P/F`+INFONAVIT = `cuotasTPF` | 0.61+2.53+1.24+0.66 = 5.03 | SSEmp+SSImp 4.99 | ✓ |
| Memo: `ing_remesas` | 3.52 | ROWTrans 3.52 | ✓ (fuera del PIB) |

### A.4 Consistencia del reescalado
Numerador (LIF `divSIM`, `anio(2026)`, vía `Distribucion` en PerfilesSim) y denominador (SCN `anio(2026)`) comparten **el mismo año de referencia y el mismo PIB**: en la sesión de SIM.do, `scalar(PIB)` de SCN 2026 = `scalar(pibY)` de PIBDeflactor = 37.85 billones (SCN proyecta con los mismos globales `$pib*/$def*`). Desfase de momento contable LIF (caja presupuestaria estimada de la Ley) vs SCN (devengado): se declara cualitativamente; su magnitud observable es la columna `Dif*TEnac` (< 0.55% relativo en todas las bases, tabla A.5).

### A.5 TE micro nacionales recalculadas (base completa) — brechas residuales con causa

| Base / impuesto | Oficial | Micro nac | Dif (causa identificada) |
|---|---:|---:|---|
| ISR asalariados | 12.399 | 12.400 | +0.01% (redondeo del parámetro `ISRASPIB`=3.748 vs LIF exacto) |
| Cuotas IMSS | 5.611 | 5.610 | idem |
| ISR PF | 1.723 | 1.721 | idem (`ISRPFPIB`=0.238) |
| ISR PM | 12.438 | 12.438 | 0 |
| Otros K | 4.142 | 4.142 | 0 |
| IVA | 5.841 | 5.841 | 0 |
| Importaciones | 0.936 | 0.936 | 0 |
| ISAN | 2.137 | 2.148 | +0.5% (monto LIF ISAN vs parámetro 0.053) |
| IEPS NP | 48.094 | 48.098 | ~0 (juegos imputado con `gas_pc_RecrT`→Recre7132) |
| IEPS P | 61.949 | 61.924 | −0.04% (combustibles `gas_pc_Gasolinas+Combustibles`→ConsPriv21) |
| Laborales | 12.902 | 12.902 | 0 |
| Consumo total | 9.650 | 9.649 | ~0 |

Notas de imputación (componentes que existen en micro a granularidad más gruesa, distribuidos con el canal `Distribucion` del propio pipeline): juegos (Recre7132, 0.093% PIB) dentro de `gas_pc_RecrT` — la ENIGH 2024 no genera categoría IEPS "Juegos" separada (verificado en `consumption_categ_ieps_pc.dta`); combustibles (ConsPriv21) con `gas_pc_Gasolinas+gas_pc_Combustibles`.

### B. Parámetros `*PIB` de SIM.do §4.1 vs defaults calculados vs micro

Los "defaults" se calculan en `ISR_Mod.do` (ISR_AS/PF/PM_Mod, CUOTAS_Mod = Σ micro simulada/pibY, con factores de calibración internos ×3.793/3.255 etc.) e `IVA_Mod.do` (IVA_Mod, con evasión `IVAT[13]` y factor ×4.249/4.495); solo corren bajo `cambioisrpf`/`cambioiva` (política nueva). Corrida de prueba (sesión aparte, `SIM.do` sin tocar):

| Parámetro | A mano (SIM.do §4.1) | Default `*_Mod` | Micro perfiles (`Rec*nac`/pibY) |
|---|---:|---:|---:|
| ISRASPIB | 3.748 | 3.807 | **3.748** |
| ISRPFPIB | 0.238 | 0.374 | **0.238** |
| ISRPMPIB | 4.126 | 4.325 | **4.126** |
| CUOTASPIB | 1.696 | 1.655 | **1.696** |
| IVAPIB | 4.199 | 4.190 | **4.199** |
| OTROSK/IEPSNP/IEPSP/ISAN/IMPORT | 1.374/0.761/1.251/0.053/0.673 | — | idénticos |

**Conclusión:** el numerador de `TasasEfectivasMicro` (Σ perfiles reescalada a LIF) coincide al milésimo con los parámetros a mano — que es la convención histórica publicada (bloque `INGRESOS` de `output.txt`, anclado a LIF). Los `*_Mod` son el canal de recalculo para cambios de política, no la convención publicada. **F1 replica la convención histórica.**

### C. Descomposición ISR PM y mixto

**ISR PM** (brecha F1: 18.23 vs 12.44 oficial = 5.79 pp):
- Efecto numerador: Σ`ISRPM` perfiles/pibY = 4.126 = `ISRPMPIB` → **0 pp**.
- Efecto denominador: **5.79 pp completos**. F1 usó solo `ing_bruto_tpm` (22.6% del PIB); el oficial `IngKPrivado` = `CapIncImp` − 4 públicos = 33.2%, donde `CapIncImp = ExNOpSoc+ExNOpHog+MixKN+INPK+ImpNet` (SCN.ado:229). Componentes omitidos por F1, todos con contraparte micro: alquiler imputado `ing_estim_alqu`→ExNOpHog (2.71% PIB), mixto capital `ing_mixtoK`→MixKN (6.91%), INPK (0.31%), FMP reintegrado (0.64%; PerfilesSim resta 5 públicos y la TE oficial solo 4). Con la base completa: **12.438 = oficial exacto**.

**Mixto**: TE ya coincidía (1.721 vs 1.723; causa residual = redondeo del parámetro). La brecha de conciliación −3.57 pp (participación NL 4.28% del mixto vs 7.86% del PIBE) no es error de método: el ingreso mixto es la base más asociada a la informalidad y NL es la entidad con menor informalidad laboral del país (TIL2 32.9% vs ~54% nacional, ENOE 4T2024) — razón declarada: **clasificación/composición**, más denominador (PIBE total ≠ base mixta) y momento contable (PIBE 2023).

### D. Incidencia — compuerta y corrección

**D.1 Compuerta (PASÓ):** el driver sin `entidad()` reproduce `INCD`/`INCD2`/`INCD3` de `output.txt` (AportacionesNetas) con `reldif < 1e-6` en las 11 filas (monto por hogar, distribución e incidencia; p. ej. decil I: −80,427.99 / −26.30 / −50.72; Nac: 30,581.76 / 100.0 / 4.006). Tabla completa en el PR.

**D.2 Objeto replicado (SIM.do §7.1 + Simulador.ado §1.3.3 + INCI.ado):** total = `ImpuestosAportaciones` = ISRPM_Sim+ISRAS_Sim+ISRPF_Sim+CUOTAS_Sim+IVA_Sim+IEPSNP_Sim+IEPSP_Sim+ISAN_Sim+IMPORT_Sim (**sin OTROSK ni FMP**, SIM.do:440); subtotales AlTrabajo/AlCapital/AlConsumo tal como los guarda `aportaciones.dta` (nota: `AlCapital` del pipeline sí incluye OTROSK, SIM.do:436 — se replica tal cual). Denominador: `ingbrutotot` (Σ nacional = PIN, PerfilesSim.do:177; incluye las SS vía Altimir) sumado por decil con `fw=factor` sobre el MISMO universo del numerador; colapso por hogar → decil → cociente (INCI.ado); deflactor espejo de Simulador.ado:68/82; restricción `if var != 0`.

**D.3 Checklist de errores probables (versión F1):**
| Posible error | ¿Presente en F1? |
|---|---|
| Doble conteo (`ISR` + `ISRAS/ISRPF/ISRPM`; `CUOTAS` + `cuotasT/P/F`) | No |
| Cuotas patronales en numerador sin contraparte en denominador | No (`ingbrutotot` ≈ PIN incluye SS) |
| EP o gasto público sumados como impuestos | **Sí: F1 sumó OTROSK al total** (el pipeline lo excluye de `ImpuestosAportaciones`). Corregido: 33.5% → 29.8% NL |
| Mezcla per cápita / por hogar | No |
| `ingbrutotot` de universo distinto al numerador | No |
| Deciles estatales con el `xtile` de respaldo (Simulador.ado:251) | No (`ing_decil_pc`, criterios de Households.do:2591-2598) |
| Numerador perfiles-LIF vs `*_Sim` del pipeline | Sí (menor: ≈ mismos montos); corregido usando `aportaciones.dta` (`*_Sim`) |

**D.4 Resultados corregidos** (incidencia total, % del ingreso bruto del decil): nacional 20.7% (I: 21.5 … X: 20.7); NL en deciles nacionales 29.8% (I: 39.3, X: 33.5); NL en deciles estatales 29.8% (I: 30.7, X: 33.9). La sobre-incidencia de NL respecto al nacional está identificada: concentración del ISR PM en residentes de NL (AlCapital NL 14.6% vs 6.8% nacional), consistente con el ranking nacional de formalidad del pipeline.

## Anexo F1-bis-2 — Decil I / robustez de AlConsumo y banda de sensibilidad del ISR PM (2026-08-31)

### 1. Diagnóstico del decil I y robustez de AlConsumo

**(a) Razón gasto corriente monetario / ingreso bruto por decil** (`razonGY<suf><dec>`): decil I nacional **212%**, NL en deciles nacionales **252%**, NL en deciles estatales **196%**; total 89/85/85%. En el decil I el gasto duplica al ingreso corriente: el denominador de la incidencia es el atípico, no el numerador.

**(b) Composición del decil I nacional** (`nHogDecI*`, `PctIngBajoDecI*`, `TamHogDecI*`, `EdadJefeDecI*`):

| | n hogares (muestra) | % ingreso 0 o < 25% del gasto | Integrantes | Edad del jefe |
|---|---:|---:|---:|---:|
| Decil I nacional (país) | 10,521 | 14.2 | 4.34 | 49.6 |
| Decil I nacional (NL) | 426 | **25.0** | 4.15 | 50.4 |

Los hogares NL del decil I nacional tienen casi el doble de probabilidad de reportar ingreso corriente ≈ 0 o muy inferior a su gasto.

**(c) Descomposición de AlConsumo por impuesto en el decil I** (incidencia, % del ingreso del decil; familias `IVA/IEPSNP/IEPSP/ISAN/IMPORT` por sufijo):

| Juego | IVA | IEPS NP | IEPS P | ISAN | Import | AlConsumo |
|---|---:|---:|---:|---:|---:|---:|
| nacional (nac) | 9.8 | 1.6 | 0.7 | 0.0 | 2.0 | 14.1 |
| NL, deciles nacionales (nl) | 11.3 | 14.2 | 1.8 | 0.1 | 2.4 | 29.7 |
| NL, deciles estatales (nle) | 9.9 | 5.9 | 0.9 | 0.0 | 1.8 | 18.6 |

**(d) Estructura de la canasta del decil I** (% del gasto clasificado IVA; regímenes desde la matriz `IVAT`, mismo orden de `levelsof` que `Expenditure.do` §5.2):

| Juego | Gravado | Exento | Tasa cero | Bienes con IEPS |
|---|---:|---:|---:|---:|
| nacional | 37.2 | 15.5 | 47.3 | 8.9 |
| NL (nl) | 38.8 | 18.0 | 43.2 | 13.7 |
| NL (nle) | 42.9 | 19.0 | 38.1 | 13.9 |

**(e) Robustez con gasto como denominador** (familias `AlConsumoG`/`ImpAportG`; razón declarada: **denominador**): la incidencia de AlConsumo del decil I pasa de 14.1 (nac) / 29.7 (NL) sobre ingreso a **6.6 / 11.8 sobre gasto**; totales 9.7 / 10.9 ≈ las TE de consumo.

**Rótulo corregido:** la TE de consumo NL ≈ nacional (IVATEnl 6.028 vs IVATEnac 5.841) y **la construcción del IVA es la misma**; el diferencial del decil I **combina denominador** (selección: razón gasto/ingreso 252% y 25% de hogares con ingreso ≈ 0) **y numerador** (canasta más gravada: 38.8% gravado y 13.7% en bienes con IEPS vs 37.2% y 8.9% nacional; la incidencia del IEPS NP del decil I NL, 14.2 vs 1.6, es el mayor contribuyente del diferencial).

### 2. Banda de sensibilidad del ISR PM (NL)

Todos los escenarios son **estimadores válidos** reescalados al mismo total nacional (Σ `ISRPM_Sim`): cambia la incidencia, no la recaudación. Supuestos declarados en `presentacion` del JSON.

| Escenario | Supuesto de incidencia | TE ISRPM NL | Part. NL en ISR PM (%) | inc AlCapital Tot | inc Total Tot |
|---|---|---:|---:|---:|---:|
| **S1** (cota inferior) | prorrateo a ingreso de capital, sin cut-off | 14.35 | 8.64 | 10.4 | 25.5 |
| **S2** | 50% capital / 25% trabajo / 25% consumo | 13.04 | 7.86 | 9.8 | 24.9 |
| **S0** (método vigente) | ranking probit + cut-off LIF | 23.50 | 14.15 | 14.6 | 29.8 |
| **S3** (cota superior) | pago esperado p(probit)×impuesto potencial | 34.79 | 20.95 | 19.9 | 35.1 |

**Banda declarada [S1, S3] para la incidencia total NL: [25.5, 35.1]% del ingreso, con S0 (29.8, método vigente) dentro de ella.** S2 queda apenas por debajo de S1 (parte de la carga migra a trabajo/consumo, menos concentrados en NL). Escalares con sufijos `nlS1/nlS2/nlS3` y `nleS1/nleS2/nleS3`; `nl` sigue siendo S0.

### 3. Notas de contrato

- **Suma de columnas en tablas de incidencia**: `AlCapital` (pipeline, SIM.do:436) incluye OTROSK y el total `ImpAport` (SIM.do:440) lo excluye. Se exporta la **familia `OTROSK` por separado** (sufijos nac/nl/nle) de modo que `AlTrabajo+AlCapital+AlConsumo−OTROSK = Total` (verificado: 9.6+14.6+9.2−3.7 = 29.8 en nl).
- **Procedencia en batch**: el driver garantiza un log activo (abre `users/$id/nodos/entidad-nl.log` si `SIM.do` cerró los logs) y aborta si no lo consigue: **sin procedencia no hay exportación válida**. JSON final: 1,759 escalares, **0 faltantes**.
- **Deuda técnica**: extender `scalarjson.ado` con una clave canónica `supuestos` (bloque propio del contrato) para que los supuestos de incidencia de los escenarios no dependan del bloque libre `presentacion`.

### Nota de no-regresión (cachés)
`output.txt` es byte-idéntico al baseline en todas las corridas. Entre el baseline original y las corridas F1-bis, el dump crudo de `scalar list` mostró 23 escalares **adicionales** (`pob*Nacional`, de Poblacion.ado) y un reordenamiento del bloque LIF: provienen de un refresco de cachés `master/*.dta` provocado por una sesión de diagnóstico de solo lectura (SCN/Poblacion re-cachean al correr sin los globales de SIM.do), no de los archivos F1 (que SIM.do nunca invoca). Cero valores distintos en los escalares comunes; dos corridas consecutivas con el estado de cachés actual son byte-idénticas también en el dump crudo.

---

## Anexo F0-8.6.0 — Sincronización a v8.6.0 y diagnóstico del endpoint de Población (2026-10-03)

**Worktree:** `/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-NL` (rama `feature/entidad-nl`, disco local). El worktree de `master` (Dropbox) no se tocó.

### 0.1 Estado del PR #9 y de la capa NL en `master`

- **PR #9 sigue OPEN** (no mergeado, ni total ni parcialmente). `origin/master` @ `0bb0ca3` (v8.6.0) **no contiene ningún archivo de la capa NL**: `git ls-tree origin/master` no lista `EntidadNL.do`, `TasasEfectivasMicro.ado`, `DIAGNOSTICO_NL.md` ni `publicar-conl.sh`.
- La única mención a `entidad` en `Simulador.ado` de master es el filtro `entidad == "Nacional"` sobre `Poblacion.dta` (preexistente); la opción `entidad()` vive **solo** en `TasasEfectivasMicro.ado` (capa NL). El motor nunca recibió cambios desde esta rama.
- Antes del merge, la rama difería de su merge-base (`2b03cb7`, v8.3.3) **exclusivamente** en los 4 archivos de la capa NL. Consecuencia: el merge no podía producir conflictos en el motor.

### 0.2 Merge `origin/master` (v8.6.0) → `feature/entidad-nl`

`git checkout -- simulador.stpr` (estado de sesión) y `git merge origin/master`: **merge limpio, cero conflictos** (`6ead554`; 32 commits de master, v8.3.3→v8.6.0: v8.4.x SIMroot/sidecar/CONAPO vía DGIS, v8.5.0 `perfilpc`, v8.6.0 `Simulador` v2.0). Post-merge, `git diff --name-only origin/master HEAD` = los 4 archivos de la capa NL. **Ningún archivo del motor difiere de master.**

**Ajuste de la capa NL al contrato v8.4 (`${SIMROOT}`):** `TasasEfectivasMicro.ado` (3 rutas) y `EntidadNL.do` (`local site`) leían `c(sysdir_site)`; desde v8.4.0 la raíz de datos es `${SIMROOT}` (`SIMroot.ado`). Se cambió solo en la capa NL (misma corrección que master aplicó a `scalarjson.ado`/`PerfilesSim.do`). Sin ello, en una sesión interactiva con `SITE` apuntando a otro clon, el driver leería las bases de otro árbol.

### 0.3 Compuertas post-merge

Receta batch del runbook (`02_governance/runbook-deploys-ciep.md` §1: `global output` + `global nographs`, `set linesize 255`, `stata-mp -b`), `global bootstrap 1`, PE 2027.

| Compuerta | Resultado | Evidencia |
|---|---|---|
| **Paridad nacional** | **PASÓ — diff vacío** | Árbol limpio de `origin/master` (`git archive` a `~/CIEP_Simuladores/_paridad-master-8.6.0`, `raw/` compartido por symlink, copia propia de `master/`) vs. el worktree NL. `users/ricardo/output.txt`: 48,810 bytes en ambos, SHA-256 `ae624b9885b7ac67a901ce858d2a5046d6e2750b6a7e02727ac64dbeb945fa15` idéntico; los 5 `sankey-*.json` también idénticos. 0 líneas con `> `. TOUCH-DOWN 612.7 s (master) / 767.3 s (NL). |
| **D.1 (EntidadNL.do)** | **PASÓ** | Misma sesión batch tras SIM.do: "Compuerta D.1: PASÓ (xhogar, distribución e incidencia idénticos al pipeline)"; `scalarjson (entidad-nl): 1759 escalares, 1 año de serie, 4 capas, 0 faltantes`. Log: `users/ricardo/nodos/entidad-nl.log`. |
| **Delta NL documentado** | ver tabla | `statajson_entidad-nl.json` v8.3.3 (corrida 2026-09-23, PE 2027) vs v8.6.0 (2026-10-03, PE 2027); mismas 1,759 claves. |

**Delta NL** (% salvo indicación; `nl` = S0, deciles nacionales):

| Escalar | F1-bis-2 (2026-08-31, PE 2026, v8.3.x) | v8.3.3 (2026-09-23, PE 2027) | **v8.6.0 (2026-10-03, PE 2027)** | Δ motor 8.3.3→8.6.0 |
|---|---:|---:|---:|---:|
| TE laboral NL `YlImpTEnl` | 17.4 | 18.03 | **18.03** | 0.00 |
| TE laboral nacional `YlImpTEnac` | 12.9 | 13.36 | **13.36** | 0.00 |
| TE ISR PM NL `ISRPMTEnl` | 23.5 | 24.25 | **24.38** | +0.12 |
| TE IVA NL `IVATEnl` | 6.0 | 6.44 | **6.44** | 0.00 |
| Incidencia total NL `incImpAportnlTot` | 29.8 | 30.77 | **30.80** | +0.02 |
| Incidencia total nacional `incImpAportnacTot` | 20.7 | 21.48 | **21.48** | 0.00 |
| Banda [S1, S3] NL | [25.5, 35.1] | [26.38, 36.22] | **[26.35, 36.17]** | [−0.03, −0.04] |
| Participación NL en ISR PM `PartISRPMnl` | 14.15 | 14.15 | **14.22** | +0.07 |

> **Cifras citables vigentes (PE 2027 / motor v8.6.0 / capa NL-0.1.0):** TE laboral NL **18.0 %** (nacional 13.4 %); incidencia total NL **30.8 %** del ingreso bruto (nacional 21.5 %); banda ISR PM **[26.4, 36.2]**. Las cifras de F1-bis-2 (17.4 / 29.8 / [25.5, 35.1]) corresponden a PE 2026 y **quedan superadas**. Toda comunicación de cambios usa la descomposición **Paquete-vs-motor**: primero el efecto del Paquete Económico (parámetros `*PIB`, macros SCN/LIF del año de política), después el efecto de la versión del motor (metodología), nunca un solo delta agregado.

Atribución: (i) el salto F1-bis-2 → v8.3.3 **no es del motor**: es el cambio de año de política (PE 2026 → CGPE 2027, parámetros `*PIB` de `SIM.do` §4.1 y macros SCN/LIF 2027) en la corrida del 23-sep; (ii) el delta **8.3.3→8.6.0 es de metodología del motor, no de la capa NL**, y se concentra en el ISR PM y en la incidencia (≤ 0.12 pp): `perfilpc` v8.5.0 (reparto intra-hogar por punto fijo con paro por tolerancia, "CAMBIA RESULTADOS" según el CHANGELOG) altera la asignación por persona que alimenta el probit/cut-off del ISR PM; `Simulador` v2.0 con B=1 coincide con v1.x a precisión de máquina, así que no aporta al delta. TE laboral, cuotas, ISR PF, IVA y consumo: **0.00**.

### 0.4 Diagnóstico para el endpoint de Población (solo lectura)

**Módulo del motor.** `Poblacion.ado` v8.0 (`Poblacion [if] [, ANIOinicial ANIOFinal NOGraphs UPDATE TEXTBOOK]`) + subrutina `UpdatePoblacion`. Fuente (v8.4.1): CONAPO, Conciliación Demográfica 1970-2019 y Proyecciones 2020-2070 (**pry23**, 11-sep-2023), redistribuida por DGIS-Salud como `Poblacion_Estimada_Mitad_Anio.zip` (asset del sidecar, SHA verificado por `ensure_asset`; CONAPO dejó de servir los CSV en vivo en sep-2026). Bases: `master/Poblacion.dta` — **edad simple (0–109) × sexo (1 H / 2 M) × entidad (32 + "Nacional" = suma) × año**, variable `poblacion` (+ `tasafecundidad`); `master/Poblaciontot.dta` — total nacional por año (lo consume `PerfilesSim.do:138` para reescalar el factor). `SIM.do` §1 lo invoca con `anioi(aniovp) aniofinal(2070)`; `Simulador.ado:403` lee las matrices edad×año nacionales para REC.

**Estado de la caché local (hallazgo).** `master/Poblacion.dta` del worktree NL (y la copia usada en la paridad) es del **24-may-2026**: vintage pre-v8.4.1 (CSV en vivo de CONAPO), **1950–2070**, 737,660 obs, 9 variables. El motor v8.6.0 reconstruye desde el zip de DGIS con cobertura **1970–2070** solo si la caché falta o con `update`; según el CHANGELOG v8.4.1 las 555,500 celdas comunes coinciden exactamente. `raw/CONAPO/` no existe en el worktree NL (el asset no se ha descargado). Decisión pendiente para F2 (ver abajo).

**Escalares/JSON de población que exporta hoy el canal.** `Poblacion.ado` registra vía `escalar` 23 escalares por entidad (`pob*<Entidad>`, aquí `Nacional`): `personas` — `pobtot`, `pobfin`, `pobhomI/F`, `pobmujI/F`, `pobMenoresI/F`, `pobPrimeI/F`, `pobMayoresI/F`; `pct` — `pobhompropI/F`, `pobmujpropI/F`, `pobMenorespropI/F`, `pobPrimepropI/F`, `pobMayorespropI/F`; `anio` — `aniotdmin`, `aniotdmax` (solo con gráficas). A `output.txt` no viaja ningún bloque demográfico (solo conteos de beneficiarios `GASTOSPOB1/2`). Ningún nodo `scalarjson` exporta población como serie salvo `poblacion` como denominador en `nodo-deuda` (`master/Poblaciontot.dta`) y `Pobnl` (ENIGH expandida) en `entidad-nl`. **No existe hoy un JSON de población por edad/sexo/año**: el endpoint F2 lo crea en la capa NL leyendo `master/Poblacion.dta` sin tocar el `.ado`.

**Serie NL vs nacional (caché actual):** 1970: 1.79 M (3.5 % del país) · 2000: 3.91 M (3.9 %) · 2020: 5.91 M (4.6 %) · 2025: 6.41 M (4.8 %) · 2040: 7.77 M (5.4 %) · 2070: 9.08 M (6.4 %).

**Trabajo municipal previo.** En el repo (ramas, historial, nombres de archivo con `municip`): **nada** — `git log --all --grep=municip` y `git log --all --name-only | grep -i municip` vacíos; `raw/ENIGH/*/censo_eco_municipios.dta` es el Censo Económico (VA-ratio), no población. **Fuera del repo** sí existe:

- `Drive CoNL / 2. Simuladores CoNL / CORE / PoblacionNL.ado` (7-may-2026, 24.5 KB) + `INICIO.do` (7-may-2026, Simulador NL embrionario con `sysdir set SITE` al Drive): clon de `Poblacion.ado` por municipio (`PoblacionNL [if mun == "…"]`, 51 municipios), con `UpdatePoblacionNL` que lee `raw/CONAPO/pobproy_quinq1.csv`, filtra `clave_ent == 19`, hace `reshape long` de los 18 quinquenios y **expande a edades simples repartiendo uniformemente (÷5; 85+ repartido en 85–109)**. Escribe `master/PoblacionNL.dta` y `PoblacionNLtot.dta` en `c(sysdir_site)` (contrato pre-v8.4). Las bases generadas **no están** en el Drive (la carpeta `SimuladorCoNL/` está vacía salvo `graphs/` de hoy).
- Fuente municipal localizada: `Drive CoNL / 2. Simuladores CoNL / TMCA VACB real per capita regiones NL / 02_datos / pobproy_quinq1.csv` (36.7 MB, 6-ago-2026): **CONAPO, "Reconstrucción y proyecciones de la población de los municipios de México 1990-2040" (2024)**, población a mitad de año por **grupos quinquenales (0-4 … 80-84, 85+) × sexo × municipio × año 1990–2040**, 2,475 municipios (incluye los de creación reciente, p. ej. Ñuu Savi). NL: 51 municipios × 2 sexos × 51 años = 5,202 filas × 18 grupos = **93,636 celdas**.
- **Consistencia verificada (Stata, solo lectura):** la suma de los 51 municipios de NL coincide **exactamente (dif = 0)** con la serie estatal de `master/Poblacion.dta` en los 51 años comunes 1990–2040 (p. ej. 2025: 6,413,123; 2040: 7,769,371). Es el mismo vintage demográfico (pry23) → la fuente municipal **queda confirmada** para F2, con dos salvedades que se declaran, no se corrigen: cobertura 1990–2040 (vs 1970/1950–2070 estatal) y edad quinquenal (vs simple).
- La fuente municipal **no está integrada** al motor ni al sidecar (`manifest.json` solo trae el zip de DGIS). Para F2 se propone traerla a la capa NL como insumo local declarado (`raw/CONAPO/pobproy_quinq1.csv`, gitignored, SHA-256 registrado en este anexo) con guarda que aborta si falta; **no** se añade al manifest del motor (eso sería PR aparte a master).

### 0.5 Decisiones (aprobadas 2026-10-03: 1a, 2 con el CSV commiteado en la capa NL, 3)

1. **Vintage de la caché de población.** (a) Correr `Poblacion, update` en el worktree NL para alinear `master/Poblacion.dta` al asset canónico v8.6.0 (1970–2070, descarga ~1 asset del sidecar; cambia la caché del motor pero no sus números en celdas comunes), o (b) conservar la caché 1950–2070 actual y declarar el vintage en el HTML. **Recomendación: (a)** — el endpoint debe reproducirse desde un `master/` reconstruible con el motor v8.6.0.
2. **Municipios en F2** con la fuente confirmada: pirámides municipales en **grupos quinquenales** tal como da la fuente (sin la expansión uniforme ÷5 de `PoblacionNL.ado`, que inventa estructura intra-quinquenio); estatal y nacional en edad simple; el comparativo de estructura NL vs nacional vs municipio se hace en quinquenios. Tamaño estimado del JSON embebido: ~0.5 MB municipal + ~0.4 MB estatal/nacional (edad simple, 1970–2070) → HTML < 1.5 MB, dentro del objetivo de 2 MB.
3. **Ubicación del comando:** `01_modulos/PoblacionNL.do` (driver propio de la capa NL, invocable tras `SIM.do` o solo; lee `master/Poblacion.dta` + el CSV municipal; escribe `users/$id/nodos/poblacion-nl.json` y `poblacion-nl.html`), en lugar de subrutina de `EntidadNL.do` — la población no depende de la corrida fiscal y debe poder regenerarse sin ella.

**Resolución (2026-10-03):** (1a) `Poblacion, update` ejecutado en el worktree NL: `master/Poblacion.dta` pasa a 1970–2070 (733,260 obs, asset `raw/CONAPO/Poblacion_Estimada_Mitad_Anio.zip` descargado del sidecar, SHA verificado por `ensure_asset`); la paridad nacional se **re-verificó** con la caché nueva: `output.txt` SHA-256 `ae624b98…45fa15`, idéntico al de la corrida fresca de master. (2) El CSV municipal se **commitea** en `01_modulos/nl-assets/pobproy_quinq1.csv` (36.7 MB; SHA-256 `1a8f07be08de082a0c33404f0fbce9d9292845a8c8290153a6ad2e1889bab31a`; checksum Stata 3853515816; procedencia en `nl-assets/nl-manifest.json`), fuera del manifest del motor. (3) Driver propio `01_modulos/PoblacionNL.do`.

**Hallazgo de entorno (no del repo):** el `python_exec` permanente de Stata en esta máquina apunta a `/usr/local/bin/python3` = **Python 3.14**, que Stata 17 no puede inicializar (`r(7100)` en `ensure_asset`, `profile.do` cae en su guard). Las corridas batch de este anexo usaron `python set exec /usr/bin/python3` (3.9) **por sesión**, sin tocar la configuración permanente. Recomendación: `python set exec /usr/bin/python3, permanently` (o un 3.9–3.12 instalado) para que `AccesoBIE`/`ensure_asset` funcionen en interactivo.

---

## Versionado de la capa NL

Fuente de verdad legible por máquina: `01_modulos/nl-assets/nl-manifest.json` (`version_nl`, `motor_sincronizado`, assets de la capa con checksum). La identidad de producto la resuelve `01_modulos/nl-assets/nl-identidad.do` (`_NLidentidad`): lee la versión del motor de `05_scripts/manifest.json` y la de la capa de `nl-manifest.json`; ninguna salida de la capa la escribe a mano.

**Regla de cadencia.** La capa NL hace merge de `master` en **cada release etiquetado** del nacional y, antes de subir `version_nl`, pasa las tres compuertas de §0.3 del anexo F0-8.6.0: (1) paridad nacional con `output.txt` byte-idéntico a una corrida fresca de `master`; (2) compuerta D.1 de `EntidadNL.do`; (3) delta NL documentado con descomposición Paquete-vs-motor. **Regla de versión:** `NL-MAJOR.MINOR.PATCH` — MAJOR = cambio de contrato de salida (JSON/HTML); MINOR = producto o endpoint nuevo; PATCH = corrección sin cambio de contrato. El motor nunca se modifica en esta rama: una mejora general se propone a `master` por PR aparte.

**Identidad de producto (F1).** Las salidas de la capa (banner de los drivers, bloque `presentacion` del JSON de `entidad-nl`, encabezado y pie del HTML de Población) se presentan como **"Simulador Fiscal NL"** con subtítulo **"construido sobre el Simulador Fiscal CIEP v<versión>"**. Ningún archivo del motor se renombra; `output.txt` y los títulos de las salidas nacionales no cambian (paridad verificada).

### Changelog

#### NL-0.2.0 — 2026-10-03 (motor sincronizado: v8.6.0)
- **Endpoint de actividad económica y precios** (`01_modulos/PIBDeflactorNL.do` v1.0.0 + plantilla `nl-assets/actividad-nl.html`): PIBE nominal/real y deflactor implícito NL, crecimiento real con ancla PIBE + nowcast ITAEE, inflación INPC Nuevo León (promedio, dic/dic, vigente), comparativos nacionales con las mismas transformaciones, proyección corta al año de política con los criterios de `PIBDeflactor.ado`; 4 compuertas; JSON `nl.actividad/v1` + HTML autocontenido (150 KB) con **modo datos** (tabla con filtros, copiar TSV, descargar CSV, encabezado de procedencia en cada extracto).
- **Lectores INEGI de la capa** (`nl-assets/nl-bie.do` + `nl_bie.py`): `_NLbie indicador, area()` (BIE por área geográfica, misma vía pública que `AccesoBIE`) y `_NLinpc serie, estructura()` (programa INPC de INEGI). Motivo en el anexo PIBDeflactorNL §0.2; propuesta a `master` por PR aparte: opción `area()` en `AccesoBIE`.
- **Actualizador** `actualizar-nl.sh` (un comando: PoblacionNL + PIBDeflactorNL en batch con `profile.do`, fallo seguro con respaldo/restauración, publicación y bitácora `nl-assets/bitacora-publicaciones.log`).
- `publicar-conl.sh` publica también `actividad-nl.html` en la raíz del Drive.
- Drivers con log de procedencia propio y con nombre (`name(nlpob)`/`name(nlact)`): coexisten con el log de batch y entre sí.
- Python de Stata fijado a `/usr/bin/python3` (3.9) de forma permanente (aprobado).

#### NL-0.1.0 — 2026-10-03 (motor sincronizado: v8.6.0)
- **Sincronización** a `master` v8.6.0 (merge limpio) con las tres compuertas en verde; capa alineada al contrato `${SIMROOT}` (v8.4+) en `TasasEfectivasMicro.ado` y `EntidadNL.do`.
- **Identidad de producto**: `nl-assets/nl-manifest.json`, `nl-assets/nl-identidad.do` (`_NLidentidad`); `EntidadNL.do` v1.2.0 imprime el banner y declara `producto`/`subtitulo`/`version_capa_nl`/`version_motor` en `presentacion`; `titulo` del JSON con prefijo del producto.
- **Endpoint de Población** (`01_modulos/PoblacionNL.do` v1.0.0 + plantilla `nl-assets/poblacion-nl.html`): HTML autocontenido (CSS/JS/SVG inline, cero red, ~750 KB) con pirámide (edad simple para NL/nacional; quinquenal para los 51 municipios), serie de población total con rango, tarjetas de cifras, comparativo de estructura % contra la referencia (nacional para NL; NL para municipios), animación por año y estado inicial por URL (`#geo=m19039&cmp=1&anio=2035`). Datos 100 % del canal: `master/Poblacion.dta` (motor) + asset municipal CONAPO con compuerta (suma municipal = serie estatal). Cifras del año de referencia = escalares de `Poblacion.ado` (23 por entidad) + `razdepNL/razdepNac`, `pobjovprop*`, `pobactprop*`, `pob65prop*`, `PartPobCONAPONL` de la capa; el HTML autocomprueba sus sumas contra ellas.
- **Entrega**: `publicar-conl.sh` publica `nodos/` (JSON, logs, HTML) y copia `poblacion-nl.html` a la raíz del Drive de CoNL; crea el destino si el Drive está montado.
- **Caché de población** del worktree alineada al asset canónico v8.6.0 (1970–2070).

---

## Anexo F2 — Endpoint de Población: prueba de entrega (2026-10-03)

**Flujo verificado:** `do 01_modulos/PoblacionNL.do` (sesión batch, `aniovp = 2027`) → `users/ricardo/nodos/poblacion-nl.json` (738 KB) + `poblacion-nl.html` (764 KB) → `./publicar-conl.sh` → archivos en `/Users/ricardo/Library/CloudStorage/GoogleDrive-rcantu@conl.mx/My Drive/2. Simuladores CoNL/SimuladorCoNL/` (`poblacion-nl.html` en la raíz y en `nodos/`, más `poblacion-nl.json`, `poblacion-nl.log`, `statajson_entidad-nl.json`, `entidad-nl.log`, `output.txt`). SHA-256 del HTML en el Drive = SHA del generado en el worktree.

**Render desde el Drive (Chrome headless sobre el archivo del Drive, sin servidor ni red):** encabezado "Simulador Fiscal NL — Población · construido sobre el Simulador Fiscal CIEP v8.6.0 · capa NL-0.1.0"; tarjetas NL 2027: población 6,616,988; mujeres 49.7 %; razón de dependencia 46.7; participación 4.89 % del país; pie con fuentes (CONAPO pry23 vía DGIS, 1970–2070; CONAPO municipal 2024, 1990–2040), versión de la capa, del motor, sello de corrida y log; autocomprobación en verde: las 8 cifras del canal coinciden con las sumas de los arreglos incrustados. Vistas adicionales verificadas: Monterrey 2035 en estructura % vs NL (quinquenal) y San Pedro Garza García 2040, mujeres, vs NL.

**Compuertas del driver (abortan la exportación si fallan):** checksum y tamaño del asset municipal contra `nl-manifest.json`; rejilla completa entidad × sexo × año × edad; enteros; `pobtot<suf>` del motor = suma de la base para el año de referencia (reldif < 1e-9); suma de los 51 municipios = serie estatal del motor en los 51 años comunes (reldif < 1e-12); exactamente una marca de inyección en la plantilla; log activo (procedencia).

**Decisiones de diseño declaradas:** (a) municipios en grupos quinquenales tal como da la fuente — sin la expansión uniforme ÷5 de `CORE/PoblacionNL.ado`; el comparativo municipio↔NL agrega NL a quinquenios; (b) razón de dependencia (0–14 + 65+)/(15–64) para que estado, país y municipios compartan definición (la gráfica del motor usa 0–18/61+ sobre 19–60; se declara en el JSON y en el pie); (c) los nombres de los escalares del motor dependen de si `profile.do` cargó `$entidadesC` (`pobtotNL`/`pobtotNac` en interactivo; `pobtotNuevo_León`/`pobtotNacional` en batch): el JSON usa claves estables por familia y registra el nombre real en `cifras.*.escalares`; (d) `anio_inicio_proyeccion = 2020` (conciliación hasta 2019 en ambas fuentes) para el sombreado de la serie.

**Peso:** 764 KB (< 2 MB objetivo). Sin dependencias: cero `http(s)://`, cero `fetch`, cero `<link>`.

---

## Anexo PIBDeflactorNL — Actividad económica y precios de NL (2026-10-03, capa NL-0.2.0)

**Guardia de frontera (respetada):** `PIBDeflactorNL.do` es un sidecar macro (contexto, nowcast, deflactación de entregables NL). No toca `TasasEfectivasMicro.ado`, ni los factores Altimir, ni introduce reajuste alguno contra el PIBE; el reajuste biproporcional sigue siendo una fase futura explícita. Ningún archivo del motor cambió (`git diff --name-only origin/master HEAD` = solo capa NL).

### 0.1 Criterios heredados del `PIBDeflactor` nacional (motor)

| Elemento | `PIBDeflactor.ado` (motor) | Réplica en `PIBDeflactorNL.do` |
|---|---|---|
| Series | PIB trimestral nominal `734407`, índice de precios implícitos `735143`, ENOE `446562/446565/446566`, INPC `910392` | PIBE anual nominal `750453` y real 2018 `746097` (áreas 19 y 00), índice implícito `753357` (compuerta), ITAEE `741180`/`741927` (área 19), INPC NL `902690` (programa INPC), INPC nacional `910392` y PIB trimestral `734407+735143` vía `AccesoBIE` |
| Anualización | índice y PIB = media de trimestres; INPC anual = **diciembre** (dic/dic) | PIBE ya es anual; INPC: dic/dic como el motor **y** promedio anual (declarados ambos) |
| Deflactor | `deflator = indiceY/indiceY[aniovp]` (base aniovp = 1); `deflatorpp` con INPC | `deflatornl/nac` = deflactor implícito / valor en aniovp; `deflatorpp` con INPC de diciembre |
| Proyección a `aniomax` | exógeno `$pib/$def/$inf<año>` (CGPE) si existe; si no, `L.var_G` = **promedio geométrico desde el inicio de la serie** (`geopib/geodef = anioinicial`); el año parcial se sustituye por el exógeno; nominal = real × deflactor | sin CGPE estatal: exógeno = **nowcast ITAEE** (promedio de trimestres disponibles vs. mismos trimestres del año anterior) en los años con dato; después promedio geométrico 2003–2024; deflactor e inflación dic/dic: geométrico; nominal = real × deflactor. Mismo criterio para el comparativo nacional de este driver (declarado) |
| Escalares | `pibY`, `pibYPC`, `crecimientoProm`, `deflactorProm`, `inflacionProm`, `llambda`, `deflactorLP/VECES`, `inflacionLP/VECES`, `outputPW*` | `crecPIBEnl/nac`, `defPIBEnl/nac`, `pibeNnl`, `pibeRnl`, `partPIBEnl`, `deflatorPIBEnl`, `crecPIBEnlgeo`, `*PE` (año de política), `nowITAEEnl`, `crecITAEEnl`, `crecITAEEsaQnl`, `inflacionNLvig/dd/prom`, `inflacionNacvig/dd/prom`, `difCrecPIBEnl`, `difCrecITAEEnl`, `difInflacionNLvig/dd`, `anio*`, `inpcNLult` — sin guion bajo |

### 0.2 Inventario de series (verificado con llamadas reales a INEGI, 2026-10-03)

| Familia | Fuente / ID | Frecuencia, base | Cobertura, último dato | Rezago |
|---|---|---|---|---|
| PIBE NL valores corrientes | BIE `750453` área 19 (clásico `750472`) | anual, millones MXN | 2003–**2024 r1** | ~12 meses |
| PIBE NL valores constantes 2018 | BIE `746097` área 19 (clásico `746116`) | anual, millones MXN 2018 | 2003–2024 r1 | idem |
| PIBE NL índice de precios implícitos | BIE `753357` área 19 (clásico `753376`) | anual, 2018 = 100 | 2003–2024 | compuerta del deflactor |
| ITAEE NL original (con petróleo) | BIE `741180` área 19 (clásico `741198`) | trimestral, IVF 2018 = 100 | 1980T1–**2026T1 p1** | ~3 meses |
| ITAEE NL desestacionalizado | BIE `741927` área 19 (clásico `742053`) | trimestral, 2018 = 100 | 1980T1–2026T1 | idem |
| ITAEE nacional | **no existe en el BIE** (las tablas son solo estatales: 741180 trae 9 estados petroleros, 741927 los 32) | — | — | se usa PIB trimestral real `734407/735143` normalizado 2018 = 100 (declarado); sin serie desestacionalizada nacional |
| INPC por entidad federativa | **no está en el BIE** (árbol INPC 189113: 63 indicadores nacionales) | — | — | — |
| INPC Nuevo León | **programa INPC de INEGI** (`app/indicesdeprecios`, estructura `112001700070` "por entidad federativa", serie `902690`, Actualización de Canasta y Ponderadores 2024) | mensual, 2Q jul 2018 = 100 | jul-2018–**ago-2026** | ~10 días |
| INPC Monterrey (proxy no necesario) | misma app, estructura `112001700060`, serie `884954` | mensual | jul-2018–ago-2026 | — |
| INPC nacional | BIE `910392` vía `AccesoBIE` (motor) | mensual, 2Q jul 2018 = 100 | ene-1969–ago-2026 | — |

**Hallazgo 1 — `AccesoBIE` y el BIE 2025.** El BIE exporta cada *indicador* con las 33 áreas apiladas en una columna "Área geográfica"; los IDs clásicos por estado ya no responden y `ag=` se ignora; la API oficial responde **401** con el token vigente (el motor ya opera por la vía pública). `AccesoBIE` lee periodo/valor sin mirar el área → mezclaría 33 estados. Solución en la capa NL: `nl-assets/nl-bie.do` + `nl_bie.py` (`_NLbie`), misma vía pública, filtra el área, cachea en `raw/temp/AccesoBIE/nl_<id>_<área>.csv` + `.meta` (título, fecha de consulta INEGI, último periodo) y devuelve checksum. Las series nacionales siguen por `AccesoBIE`. **Propuesta a master (PR aparte):** opción `area()` en `AccesoBIE` con el parser de columna de área.

**Hallazgo 2 — INPC estatal.** Fuera del BIE; en el programa INPC de INEGI con exportación CSV por POST (`Exportacion.aspx?INPtipoExporta=CSV`, `_tipo=Niveles`). Las estructuras `1120013000xx` son el vintage pre-actualización (terminan jul-2024); las vigentes son `1120017000xx` (mensual, hasta ago-2026). Se usa **INPC por entidad (Nuevo León)**, mejor que el proxy Monterrey; no se necesitó el fallback.

### 0.3 Compuertas del driver (abortan la exportación)

1. **Deflactor implícito:** nominal/real × 100 reproduce el índice de precios implícitos del BIE (`753357`) en los 22 años, NL y nacional (reldif < 1e-6). **PASÓ.**
2. **Cifra de control del BIE:** PIBE nacional corriente (`750453/00`) vs PIB anual del motor (promedio de `pibQ`, `master/PIBDeflactor.dta`): reldif máx **0.000 %** en 2003–2024 (tolerancia 1 %). **PASÓ.**
3. **INPC nacional BIE ≈ INPC del motor:** `910392` vs `master/PIBDeflactor.dta` (fin de trimestre), reldif máx **0** en 186 trimestres (tolerancia 1e-3). **PASÓ.**
4. **Rejillas sin huecos** (`tsset` anual, trimestral, mensual): verificadas; cualquier hueco aborta.
Además: checksum y vintage por serie en el JSON (`procedencia.series`), y autocomprobación del HTML (12 cifras del canal = recálculo desde los arreglos) en verde.

### 0.4 Resultados de la corrida (2026-10-03; cifras del canal)

| Cifra | NL | Nacional | Dif. (pp) | Tipo |
|---|---:|---:|---:|---|
| Crecimiento real PIBE 2024 | **3.37 %** | 1.46 % | +1.91 | observado |
| Nowcast ITAEE 2026T1 (a/a, original) | **1.18 %** | 0.20 % (PIB trim.) | +0.98 | preliminar |
| Nowcast anual 2025 (4 trim. ITAEE) | 1.73 % | 0.50 % | +1.23 | nowcast |
| Deflactor PIBE 2024 (var. %) | 4.31 % | 3.85 % | +0.46 | observado |
| Inflación INPC ago-2026 (a/a) | **2.94 %** | 3.26 % | −0.32 | observado |
| Inflación dic/dic 2025 | 3.51 % | 3.69 % | −0.18 | observado |
| Proyección 2027: crecimiento / deflactor / inflación dic/dic | 2.26 / 5.17 / 4.64 % | 1.68 / 5.14 / 4.80 % | — | geométrico 2003–2024 (inflación 2019–2025) |
| Participación NL en el PIB nacional 2024 | 8.05 % | — | — | observado |

### 0.5 Endpoint `actividad-nl.html` y prueba de entrega

- **Vistas:** Crecimiento (PIBE real anual NL vs nacional con barras por tipo y sombreado de años sin PIBE; ITAEE reciente a/a con último dato destacado; ITAEE desestacionalizado t/t y nivel) y Precios (inflación dic/dic, promedio anual o mensual a/a NL vs nacional; deflactor PIBE vs INPC dic/dic con nota producción vs consumo). Tarjetas: crecimiento PIBE, nowcast ITAEE, inflación vigente, deflactor, proyección — cada una con el diferencial NL−nacional. Estado por URL (`#vista=precios&serie=dd&ini=2019&fin=2027&cmp=1&modo=tabla`).
- **Modo datos (addendum):** toggle Gráfica/Tabla por vista; la tabla respeta vista, serie, rango y comparativo y muestra **valores del canal sin recálculo** (precisión completa en el extracto); "Copiar tabla" (TSV al portapapeles; si el navegador bloquea `navigator.clipboard`, selección + `execCommand('copy')` y, si también falla, el texto queda seleccionado para Ctrl/Cmd+C) y "Descargar CSV" (Blob; si el visor bloquea la descarga, el mensaje remite a Copiar). Todo extracto lleva como primeras filas (`#`, entrecomilladas en CSV) producto, versión de la capa y del motor, corrida, fuentes con consulta INEGI y último dato, filtros aplicados y leyenda de tipos.
- **Reglas duras:** un archivo, inline, cero `http(s)://`/`fetch`/`<link>`; **150 KB** (< 2 MB).
- **Evidencia:** flujo `./actualizar-nl.sh` → `users/ricardo/nodos/actividad-nl.{json,html}` → `publicar-conl.sh` → `/My Drive/2. Simuladores CoNL/SimuladorCoNL/actividad-nl.html` (y `nodos/`), SHA-256 del HTML en el Drive = SHA local. Render verificado con Chrome headless **abriendo el archivo del Drive montado** (vistas crecimiento/ITAEE/precios/tabla). Copiar/descargar verificados ejecutando el JS de la página con un DOM simulado en Node: TSV de 17 líneas (7 de procedencia + encabezado + 9 filas) para `vista=precios&serie=dd&rango 2019–2027`; CSV disparado. **Pendiente de confirmar por Ricardo desde el visor web de Drive** (previsualización en navegador, con cuentas de CoNL): si el visor bloquea el portapapeles o la descarga, los fallbacks están implementados (selección para Ctrl+C) y el HTML lo indica en pantalla.

### 0.6 Actualizador `actualizar-nl.sh` (F3)

Un comando. Corre Stata en batch desde la raíz del worktree (carga `profile.do`: `aniovp/anioPE`, `$entidadesC`, token) con `nl-assets/actualizar-nl.do` (PoblacionNL + PIBDeflactorNL). **Fallo seguro:** respalda los últimos JSON/HTML buenos, y si INEGI no responde, una compuerta aborta, el log trae `r(#)` o falta un producto, **no publica**, restaura los productos locales y escribe el motivo en `users/ricardo/actualizar-nl.log` (el Drive no se toca; el primer intento de esta sesión ejercitó exactamente ese camino). Si todo pasa: `publicar-conl.sh` y una línea en `nl-assets/bitacora-publicaciones.log` (fecha, capa, vintages CONAPO/INEGI, SHA-256(12) de los 4 productos). `--offline` reutiliza la caché INEGI (desarrollo). Corrida completa con descargas frescas: ~20 s.

**Programación mensual (especificación, NO implementada; decide Ricardo):** `launchd` de usuario, `~/Library/LaunchAgents/mx.conl.simulador-nl.plist`, requiere sesión iniciada (LaunchAgent, no Daemon), Stata MP con licencia local, Drive de CoNL montado y red:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>mx.conl.simulador-nl.actualizar</string>
  <key>ProgramArguments</key><array><string>/bin/zsh</string><string>-lc</string><string>/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-NL/actualizar-nl.sh</string></array>
  <key>StartCalendarInterval</key><dict><key>Day</key><integer>5</integer><key>Hour</key><integer>9</integer><key>Minute</key><integer>30</integer></dict>
  <key>StandardOutPath</key><string>/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-NL/users/ricardo/launchd-actualizar-nl.out</string>
  <key>StandardErrorPath</key><string>/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-NL/users/ricardo/launchd-actualizar-nl.err</string>
  <key>RunAtLoad</key><false/>
</dict></plist>
```
Carga: `launchctl load ~/Library/LaunchAgents/mx.conl.simulador-nl.plist`. Día 5 de cada mes, 9:30 (tras la publicación del INPC del mes anterior ~día 9 conviene ajustar al 12; ITAEE y PIBE caen cuando caen: el script publica lo que INEGI tenga). Si la máquina está apagada a esa hora, launchd corre al siguiente arranque con sesión.
