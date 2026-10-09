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

**D.1 vigente (NL-0.5.2, 2026-10-08, motor v8.8.1, ancla `e40af4a6dda77d3a042228a291d55443fc020d3bf431698b179e7c11385a4d27`):** PASÓ en la misma sesión batch que reprodujo el ancla (StataNow 19.5 SE, 1 procesador, fuentes congeladas 2026-10-06): decil I −87,881.77 / −52.7364; X 483,531.74 / 16.7357; Nac 30,986.68 / 3.8616, idénticos al pipeline en `xhogar`, distribución e incidencia; `scalarjson (entidad-nl): 1801 escalares, 0 faltantes`. Evidencia: `~/CIEP_Simuladores/diag-cadencia-nl-2026-10-07/compuerta2/`.

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
| **Paridad nacional** | **PASÓ — diff vacío** | Árbol limpio de `origin/master` (`git archive` a `~/CIEP_Simuladores/_paridad-master-8.6.0`, `raw/` compartido por symlink, copia propia de `master/`) vs. el worktree NL. `users/ricardo/output.txt`: 48,810 bytes en ambos, SHA-256 `ae624b9885b7ac67a901ce858d2a5046d6e2750b6a7e02727ac64dbeb945fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`) idéntico; los 5 `sankey-*.json` también idénticos. 0 líneas con `> `. TOUCH-DOWN 612.7 s (master) / 767.3 s (NL). |
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

**Resolución (2026-10-03):** (1a) `Poblacion, update` ejecutado en el worktree NL: `master/Poblacion.dta` pasa a 1970–2070 (733,260 obs, asset `raw/CONAPO/Poblacion_Estimada_Mitad_Anio.zip` descargado del sidecar, SHA verificado por `ensure_asset`); la paridad nacional se **re-verificó** con la caché nueva: `output.txt` SHA-256 `ae624b98…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`), idéntico al de la corrida fresca de master. (2) El CSV municipal se **commitea** en `01_modulos/nl-assets/pobproy_quinq1.csv` (36.7 MB; SHA-256 `1a8f07be08de082a0c33404f0fbce9d9292845a8c8290153a6ad2e1889bab31a`; checksum Stata 3853515816; procedencia en `nl-assets/nl-manifest.json`), fuera del manifest del motor. (3) Driver propio `01_modulos/PoblacionNL.do`.

**Hallazgo de entorno (no del repo):** el `python_exec` permanente de Stata en esta máquina apunta a `/usr/local/bin/python3` = **Python 3.14**, que Stata 17 no puede inicializar (`r(7100)` en `ensure_asset`, `profile.do` cae en su guard). Las corridas batch de este anexo usaron `python set exec /usr/bin/python3` (3.9) **por sesión**, sin tocar la configuración permanente. Recomendación: `python set exec /usr/bin/python3, permanently` (o un 3.9–3.12 instalado) para que `AccesoBIE`/`ensure_asset` funcionen en interactivo.

---

## Versionado de la capa NL

Fuente de verdad legible por máquina: `01_modulos/nl-assets/nl-manifest.json` (`version_nl`, `motor_sincronizado`, assets de la capa con checksum). La identidad de producto la resuelve `01_modulos/nl-assets/nl-identidad.do` (`_NLidentidad`): lee la versión del motor de `05_scripts/manifest.json` y la de la capa de `nl-manifest.json`; ninguna salida de la capa la escribe a mano.

**Regla de cadencia.** La capa NL hace merge de `master` en **cada release etiquetado** del nacional y, antes de subir `version_nl`, pasa las tres compuertas de §0.3 del anexo F0-8.6.0: (1) paridad nacional: `output.txt` **byte-idéntico al ancla de reproducibilidad del motor** (`05_scripts/ancla-reproducibilidad.json`, receta §9.1 de `runbook-deploys-ciep.md`: estado cero sin `master/`, `users/<id>/` ni `raw/temp/`; `SIM-local.do` canónico `{nographs, output, update, fuentes}`; **StataNow 19.5 SE con `set processors 1`**; batch) — **ancla vigente `e40af4a6dda77d3a042228a291d55443fc020d3bf431698b179e7c11385a4d27` (v8.8.0, fuentes congeladas 2026-10-06)**; (2) compuerta D.1 de `EntidadNL.do` en la misma sesión; (3) delta NL documentado con descomposición Paquete-vs-motor, y veredicto de vintages (sellos re-emitidos si cambia la versión del motor o se mueven sus insumos). Las citas de `ae624b98…45fa15` en entradas anteriores a NL-0.5.2 corresponden al ancla del 22-sep, **retirada** (irreproducible: cachés `master/2024/*_pc` pre-`perfilpc` e intermedios de otra máquina; F0 del PR #16). **Regla de versión:** `NL-MAJOR.MINOR.PATCH` — MAJOR = cambio de contrato de salida (JSON/HTML); MINOR = producto o endpoint nuevo; PATCH = corrección sin cambio de contrato. El motor nunca se modifica en esta rama: una mejora general se propone a `master` por PR aparte.

**Identidad de producto (F1).** Las salidas de la capa (banner de los drivers, bloque `presentacion` del JSON de `entidad-nl`, encabezado y pie del HTML de Población) se presentan como **"Simulador Fiscal NL"** con subtítulo **"construido sobre el Simulador Fiscal CIEP v<versión>"**. Ningún archivo del motor se renombra; `output.txt` y los títulos de las salidas nacionales no cambian (paridad verificada).

### Changelog

#### NL-0.5.2 — 2026-10-08 (motor sincronizado: v8.8.1) — gate de cadencia v8.8.0: re-anclaje a `e40af4a6…`, hotfix v8.8.1 y sellos re-emitidos
- **Merge de cadencia** de `origin/master` v8.8.0 (`8636a93`: PR #16 release de datos/reproducibilidad, PR #17 publicar.sh fuente remota): **limpio, cero conflictos** (`9eef91b`; intersección de archivos tocados por ambos lados desde el merge-base `158f737` = vacía). Después, merge del hotfix `fix/scalarjson-manifest-backtick` (**PR #18 → v8.8.1**, abajo) en `6314379`.
- **Hallazgo en el motor (bug de master v8.8.0, PR #18):** `05_scripts/manifest.json` traía un acento grave en `fuentes_congeladas_regla`; `scalarjson.ado` §1 y los nodos del micrositio (`micrositio-pe`, `portada`, `indicadores`) leen el manifest con `file read` + `regexm` sobre el macro expandido → `r(132) too few quotes`. En el worktree NL `EntidadNL.do` murió en `_NLidentidad` (mismo patrón en `nl-identidad.do`); en el clon de Dropbox (con `../CIEP_Micrositios/…/nodos` presente) `SIM.do` moriría en §6 (`SHRFSP` → `nodo-deuda` → `scalarjson`) **antes de escribir `output.txt`**. La receta del ancla no lo vio porque corre sobre `git archive` sin esa carpeta ("solo-repo"). Hotfix: cinturón `subinstr local` (quita `char(96)` sin expandir) en los cuatro lectores del motor y texto del manifest sin acentos graves; sin efecto en números. Capa NL: mismo cinturón en `nl-identidad.do` v1.0.1 y `PoblacionNL.do` (lector de `nl-manifest.json`). Colateral: la primera redacción del CHANGELOG v8.8.1 rompía la bienvenida de `profile.do` §1.5 (secuencia comilla doble + simple); regla anotada en el propio CHANGELOG.
- **Compuerta 1 — paridad nacional contra el ancla v8.8.0: PASÓ.** Estado cero (`rm -rf master users/ricardo raw/temp`; snapshot previo en la evidencia), `SIM-local.do` canónico `{nographs, output, update, fuentes "2026-10-06"}`, **StataNow 19.5 SE, `set processors 1`**, batch con `< /dev/null` (el `sysprofile.do` interactivo de StataNow no fija `SITE`): `users/ricardo/output.txt` SHA-256 **`e40af4a6dda77d3a042228a291d55443fc020d3bf431698b179e7c11385a4d27`** y los 5 `sankey-*.json` **idénticos al byte** a `05_scripts/ancla-reproducibilidad.json` (TOUCH-DOWN 3,843 s). Control adicional: la re-corrida sobre esos cachés con el motor **v8.8.1** (sin `update`, misma sesión que `EntidadNL.do`) repite `output.txt` `e40af4a6…` al byte (TOUCH-DOWN 645 s); los sankeys difieren solo en el último bit (ruido `sortseed`, esperado fuera de la receta exacta; runbook §9.1).
- **Compuerta 2 — D.1 en la corrida vigente: PASÓ** (11 filas idénticas al pipeline; `scalarjson (entidad-nl): 1801 escalares, 0 faltantes`). Ver §D.1 "vigente".
- **Compuerta 3 — veredicto de vintages: insumos verificados y sellos re-emitidos.** (a) Insumos del motor antes (22-sep) vs después (fuentes 2026-10-06), por año: `LIF.dta` recaudación observada mes 12 de los 10 impuestos **idéntica 2016–2025 (0 celdas)** — solo cambian `monto/mes/acum_prom` de **2026** (meses nuevos de la SHCP); `SCN.dta` **idéntico 2014–2023, difiere 2024 y 2025** (revisión del PIB de INEGI); `PIBDeflactor.dta` y `Deflactor.dta` idénticos en todos los años; `SHRFSP.dta` difiere (derivado, DEUDAPARAM). (b) Por la regla de identidad (`FederacionNL` exige sello de la misma capa y motor) se re-corrieron los **5 vintages** con `STATA=…/stata-se ./nl-vintages.sh` (StataNow SE, 1 procesador; 2016: 1,797 s; 2018: 1,765; 2020: 1,975; 2022: 2,007; 2024: 1,067; D.1 PASÓ en los cinco) y `nl-vintages-sello.do` (compuertas 1–4 PASÓ; ligadura 2024 vs vigente **3.09e-05**). **Resultado: 2016, 2018, 2020 y 2022 reproducen exactamente las participaciones del sello NL-0.5.1 (Δ = 0.00 pp en los 10 impuestos, muestra idéntica), pese al cambio Stata 17 MP → StataNow 19.5 SE y a los cachés `master/<vintage>/` frescos; 2024 se mueve** por la revisión del SCN 2024 y los cachés `master/2024/*_pc` pre-`perfilpc` del ancla vieja (F0 del PR #16): ISR salarios 8.82→8.86 (+0.05 pp), ISR PF 6.10→5.99 (−0.11), **ISR PM 14.22→14.15 (−0.07; banda [8.64, 20.90]→[8.56, 20.78]; top-1 48.1→47.9 %)**, cuotas/IVA/IEPS/ISAN/importaciones sin cambio; `nHogDecMinnl` 338→340. (c) Corrida vigente PE 2027 (`statajson_entidad-nl.json`, 1,801 escalares, mismas claves): el delta es **del motor/fuentes, no de la capa** — se mueve igual el nacional: TE laboral NL 18.02→17.65 (nac 13.36→13.15), TE ISR PM NL 24.37→23.84, TE IVA NL 6.44→6.25, incidencia total NL **30.80→30.17 %** (nac 21.47→21.12); causas = SCN 2024 revisado (PIB 33,582.9→33,667.0 mmdp; armonización macro-micro de `Households.do`) + cachés micro regenerados (`APORT*` hasta 0.9 pp en el CHANGELOG v8.8.0). (d) `FederacionNL` modo canal con `nlfed_sellar 1`: 38 diferencias con el canal → `federacion-sello.json` re-sellado (capa NL-0.5.2, motor v8.8.1, SHA del sello de vintages `cc5e7f6d…`); compuertas 1–13 PASÓ. **Cifras citables 2025 (el `recibe` no cambia: EOPF hasta 2026-08, Last-Modified 30-sep):** recibe **117.4** mmdp (=); paga **496.2 → 495.7** mmdp (S1 414.5→413.7, S3 593.9→592.7; −0.11 %); neta **−378.8 → −378.3** mmdp. El nodo fue regenerado en `users/ricardo/nodos/` pero **NO publicado al Drive**: la publicación (`./actualizar-nl.sh` → `publicar-conl.sh` + bitácora) la decide Ricardo.
- **Entorno (capa, aditivo):** `nl-vintages.sh` y `actualizar-nl.sh` aceptan `STATA=<ruta>` (default StataMP 17 intacto) y el wrap de vintages hace `capture set processors 1`. Hallazgos de entorno que NO se corrigen en el repo: (i) el Python de StataNow (python.org 3.14) no valida el certificado de `secciones.hacienda.gob.mx` (falta el intermedio; Apple Python 3.9 sí lo resuelve) → `_NLeopf` muere con `URLError`; el fallback `except ssl.SSLError` de `nl_fed.py`/`nl_bie.py` nunca se dispara porque `urlopen` envuelve el error en `URLError` (bug latente, no se toca: bajar a `CERT_NONE` no es la salida). Solución por sesión: `python set exec /usr/bin/python3` **antes** de que `profile.do` inicialice Python (wrap que hace `run profile.do` explícito); recomendación vigente de §0.5 (hallazgo de entorno) de fijarlo `permanently` en StataNow. (ii) `SSL_CERT_FILE=/etc/ssl/cert.pem` sí resuelve INEGI con Python 3.14, no la SHCP.
- **Hallazgo de diseño (fuentes congeladas vs NL en vivo):** `PIBDeflactorNL` compara el INPC nacional del BIE (`AccesoBIE 910392`) con `master/PIBDeflactor.dta`; con el motor congelado al 2026-10-06 y la capa descargando en vivo, INEGI publicó el INPC de 2026-09 (146.075) y la compuerta 3 **abortó** (reldif 4.2e-3 > 1e-3: el motor proyecta el trimestre incompleto). Además, sin `$fuentes` en la sesión, `AccesoBIE` **sobrescribió** los csv congelados de `raw/temp/AccesoBIE/` (910392, 734407, 735143) con descargas vivas (se restauraron del zip). Solución aplicada: la sesión de los drivers lleva `global fuentes "2026-10-06"` → las series nacionales salen del asset congelado (coherentes con el motor) y las series NL (`_NLbie`, `_NLinpc`, `_NLeopf`) siguen en vivo. **Pregunta abierta para Ricardo:** ¿la capa NL congela sus propias series (`nl_*.csv`, `nl_inpc_*.csv`, EOPF `nl_transferencias.csv` + `.meta`) con la misma convención de fecha en `nl-assets/` (o en un asset propio), y `actualizar-nl.sh` fija `global fuentes` cuando el motor está congelado? `AccesoBIE, area()` (v8.7.0) tampoco entra al zip nacional.
- **Pendientes fuera de esta rama:** merge de **PR #18** (v8.8.1) en master y decisión del **Gate 9** (re-anclar con `--anclar`, esperado SHA idéntico, o heredar el ancla en patches sin cambio de números); Release v8.8.1 con los 27 assets (modo fuente remota de `publicar.sh`). Al entrar PR #18 a master, el re-merge de `origin/master` en esta rama trae solo el commit de merge.
- Evidencia: `~/CIEP_Simuladores/diag-cadencia-nl-2026-10-07/` (`antes/` snapshot y shasums; `compuerta1/` wrap, log, shasums; `compuerta2/` log, statajson, D.1; `compuerta3/` comparación de insumos `compara-master.*`, `lif-detalle.*`, `compara-sellos.md`, vintages (5 logs + JSON), `fed/` logs y nodos; `hallazgo-manifest/` reproducción y PR). Detalle en el anexo "Cadencia v8.8.1".

#### NL-0.5.1 — 2026-10-06 (motor sincronizado: v8.7.2) — pasada de identidad con el Manual de Identidad 2023
- **Merge de cadencia** de `origin/master` v8.7.2 (SIM.do autolocalizable, SIMroot v8.5, prueba `--zip`; sin archivos en común con la capa, merge limpio `3cb4b80`). Tres compuertas: (1) paridad nacional `output.txt` SHA-256 `ae624b98…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`) **byte-idéntico** (TOUCH-DOWN 455 s, `output.txt` 48,810 bytes y los 5 `sankey-*.json` sin cambio) con el motor v8.7.2 sobre los intermedios cacheados vigentes (`raw/temp/2024/`; el re-anclaje a intermedios frescos —hallazgo de PR #15— vendrá con el release de datos, no aquí); (2) D.1 **PASÓ** en la corrida vigente (`scalarjson (entidad-nl): 1801 escalares, 0 faltantes`) y en los 5 vintages; (3) delta NL: cero cambios en drivers, sellos ni contratos (solo versión de capa/motor en la identidad y la ropa de los HTML).
- **Manual de Identidad 2023 legible** (`My Drive/2023_CNL_BrandBook (1)-1-1.pdf`, Brandital v3.0) y **Guías de co-branding 2025** (`20250122_Co-branding_Brandbook_ConsejoNL-2.pdf`): `nl-estilo.md` §6.6c registra regla por regla qué corrige sobre lo inferido del sitio y del manual 2020. Tres cambios, nada más:
  1. **Hex exactos de la paleta primaria** (§5): morado `#5A2248` (90,34,72), turquesa `#00B1AF`, amarillo `#FCB817` (252,184,23). Los tokens del sitio eran ±1 por canal. `NLEstilo` (`nl-datos.js`): `--nl`, `--banda`, `--proy`, `--nowcast` sobre el morado exacto, `--paquete` amarillo exacto; `:root` de respaldo de las tres plantillas alineado. Secundarios ya coincidían (el azul del sitio es el del manual 2023).
  2. **Separador de co-branding en la atribución** (guía 2025, socio principal, versión 2 "marcas externas tecleadas"): imagotipo a color (72 px) · ½X · **línea negra de 1 px (≤ 2 px) del alto del logo** · ½X · texto **en Inter Regular** (sin negritas). X = grosor del isotipo = 0.535 × alto. El contenido del bloque sigue intocable (producto — módulo · leyenda de `_NLidentidad` tal cual · capa · motor · GitHub · corrida · log · driver).
  3. **Descriptor vs. eslogan**: el manual define el imagotipo como isotipo + logotipo + **eslogan** ("Para la planeación estratégica") y exige la versión completa "siempre en documentos oficiales y publicaciones"; lo que el `.ai` de 2020 llamaba *descriptor* es esa misma línea. Decisión: **versión completa con eslogan en cabecera (blanco, 50 px = conl.mx) y atribución (color, 72 px: eslogan de 6.8 px, legible)**. Hallazgo: el SVG de NL-0.4.1 era el **wordmark 2020** (caja baja, otra letra), no el imagotipo vigente que sí usa el sitio; se sustituye por el vector **extraído del propio manual** (lámina 2, 47 trazos, 12.9 KB, rellenos a los hex de §5) y su variante blanca. Área de protección = X del isotipo (cabecera padding/gap 27 px; pie 39 px).
- Vistas, datos y estructura intactos: ningún driver cambia; `nl-estilo-build.py` → `nl-estilo-assets.js` regenerado (94 KB; SHA de los SVG en `nl-manifest.json`). Sellos re-emitidos por la regla de identidad exacta (`participaciones-vintages.json` con los 5 vintages NL-0.5.1/v8.7.2 — números idénticos al sello NL-0.5.0 salvo ruido flotante en 5 `partS3` (reldif ≤ 2e-14); 9 compuertas del sello y ligadura vintage 2024 vs corrida vigente reldif 2.68e-05; `federacion-sello.json` re-sellado).
- Publicado y verificado desde el Drive: los tres HTML byte-idénticos al origen (`poblacion-nl` `dcb3512c20c4`, 887 KB; `actividad-nl` `ab3b1e62a090`, 284 KB; `federacion-nl` `d6fca1ca396f`, 576 KB), cero referencias externas, cabecera "v8.7.2 · capa NL-0.5.1", atribución con el lockup (logo 2023 · línea · Inter Regular) y autocomprobaciones en verde 8 / 15 / 24; compuerta de publicación OK en los tres; bitácora `2026-10-06T01:40:17`.

#### NL-0.5.0 — 2026-10-05 (motor sincronizado: v8.7.1) — participaciones históricas con ENIGH bienal 2016–2024
- **Lado "paga" por vintage ENIGH.** El supuesto "participaciones constantes (ENIGH 2024, PE 2027)" se sustituye por `Part<X>nl` estimadas con **cada ENIGH bienal** (2016, 2018, 2020, 2022, 2024), cada una corrida con el motor calibrado a la **economía de su año** (`anioPE = aniovp = anioenigh`, sin los parámetros del Paquete: `TasasEfectivas`/`GastoPC` toman LIF/PEF observados) y con la compuerta D.1 en cada vintage. Asignación **escalonada sin interpolación** (2016→2016–17, 2018→2018–19, 2020→2020–21 con sello pandémico, 2022→2022–23, 2024→2024–2027; antes de 2016, ENIGH 2016 `extrapolado`); la ENIGH 2014 queda fuera (cambio de diseño). Driver `nl-assets/nl-vintage.do` v1.0.0 (+ modo ligero de desarrollo), agregador `nl-assets/nl-vintages-sello.do` → **sello commiteado `nl-assets/participaciones-vintages.json`** (identidad, muestra NL, participaciones y banda S1/S2/S3 por vintage, Rec nacional/NL, LIF observada, concentración top-1, saltos), `./nl-vintages.sh` (5 corridas + sello con fallo seguro).
- **`FederacionNL.do` v1.2.0:** `participacionesAnual` y arreglo `vintages` desde el sello (ambos modos), paga anual con la participación del vintage asignado, compuertas 10–13 (Rec por vintage = recaudación observada 1e-6; Part = Rec/Rec 1e-9; **ligadura** vintage 2024 vs corrida vigente 1e-3, hoy 2.7e-05; sello de vintages de la misma capa/motor y atado al sello de corrida por SHA). **`EntidadNL.do` v1.4.0** (aditivo): muestra NL (`nHognl`, `nPersnl`, `nHogDecMinnl`), `concTop1<X>nl`/`nPos<X>nl`, textos con el vintage. Paridad `output.txt` `ae624b98…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`) intacta con el motor v8.7.1; D.1 PASÓ en los 5 vintages y en la corrida vigente.
- **Hallazgos declarados (resoluciones F0 §0.8, se publican tal cual):** (a) `Part<X>nl` depende del vintage ENIGH y no del año de política (reldif ≤ 2e-4); (b) el **ISR PM de NL lo sostiene una observación** en todos los vintages — 2016: una persona = 96 % del ISR PM de NL (participación 41.6 %; 2.8 % sin ella); 2024: 48 % (14.2 % vs 7.9 %) — y la banda S1–S3 no lo acota (2016: S0 fuera de [18.3, 19.4]); la serie se publica con **sello de sensibilidad muestral** (`concTop1` por impuesto y vintage, letrero en la nota del año, la vista y los extractos); (c) saltos máximos entre bienios: ISR salarios 1.75 pp, IVA 0.53, cuotas 0.72, importaciones 0.45, IEPS NP 2.71, IEPS P/ISAN 4.23, ISR PF 6.89 (top-1 67.5 % en 2022), ISR PM 33.75.
- **`federacion-nl.html`:** nota del año "ENIGH <vintage>, método bienal|extrapolado" (+ sello pandémico 2020–2021 y sensibilidad) en controles, Sankey, conciliación y extractos; **vista nueva "La carga federal de NL a través del tiempo"** (participación por impuesto y vintage con tramos por bienio, franja S1–S3 del ISR PM, ENIGH 2020 marcada, ficha por vintage en modo tabla; pesos pagados por impuesto por habitante con cortes de vintage); autocomprobaciones por vintage y de ligadura (24 en verde). `actualizar-nl.sh` registra los vintages en la bitácora; el runner exige el sello de vintages.
- **Motor:** bug de `PIBDeflactor.ado` (`pibQ not found` cuando `aniovp + 5` queda antes del último trimestre publicado; bloqueaba las ENIGH 2016–2020) corregido en `master` por **PR #13 (v8.7.1)**, con paridad demostrada; merge de cadencia a la capa. Incidente de Releases sin assets (v8.6.1–v8.7.1) resuelto espejando los 26 assets a v8.7.1; proceso de release y Gate 8 propuestos a `master` en **PR #14**.
- Publicado y verificado desde el Drive: `federacion-nl.html` SHA `1ac72fb34b64…` idéntico, 585 KB, cero red, cabecera "v8.7.1 · capa NL-0.5.0", autocomprobación 24/24; bitácora `2026-10-05T19:26:07`.

#### NL-0.4.1 — 2026-10-05 (motor sincronizado: v8.6.0) — identidad visual CoNL y retrofit de actividad
- **Identidad 100 % Consejo Nuevo León** en los tres endpoints (`nl-estilo.md` §6): tokens fijados en `NLEstilo` (`nl-datos.js`, único lugar) a partir de los tokens oficiales `--cn-*` de conl.mx, coincidentes con el PE 2040 y con el RGB del BrandBook 2020 (morado 90,33,73 · aqua 0,177,176 · amarillo 253,185,19). Semántica intacta: NL morado, nacional gris, recibe aqua, paga naranja (daltonismo y color de la comisión de Finanzas Públicas), Paquete amarillo, proyección/nowcast = morado atenuado (eco del `fintensity`), acento púrpura con borde aqua, H/M azul/rosa, rojo reservado para alertas.
- **Tipografía** Poppins SemiBold + Inter Regular/SemiBold (SIL OFL 1.1), subsets WOFF2 embebidos como data: URI (57 KB) con números tabulares; **logotipo vectorial oficial** (de `consejonl_logotipo.ai`) en color y blanco; zona de respeto y uso en blanco según el BrandBook 2020 §4–§6. Activos versionados en `nl-assets/identidad/` (SHA en `nl-manifest.json`), empaquetados por `nl-estilo-build.py` → `nl-estilo-assets.js`, inyectados por `nl-html.do` v1.1.0 en la marca `/*__NL_ESTILO_ASSETS__*/`.
- **Bloque de atribución intocable** en los tres endpoints (`NLEstilo.atribucion`): logo CoNL · producto — módulo · "construido sobre el Simulador Fiscal CIEP v8.6.0" (tal cual de `_NLidentidad`) · capa · motor · GitHub (URL desde `nl-manifest.json` → `procedencia.repositorio`, un `<a>`, cero red). Cabecera común morada con logo blanco (`NLEstilo.cabecera`).
- **Retrofit de `actividad-nl`**: vista principal nueva **PIBE por habitante** (patrón `pib_pc`: barras del nivel real per cápita por tramo observado/nowcast/proyección, crecimiento per cápita como línea punteada en eje propio, `yline` del promedio geométrico, nacional atenuado; segundo panel NL como % del nacional por habitante), registro `pc|macro` por URL, tarjeta per cápita al frente. `PIBDeflactorNL.do` v1.1.0 añade población CONAPO de `master/Poblacion.dta` con **compuerta de misma corrida** contra `poblacion-nl.json` y 14 escalares per cápita (`pibeRpcnl/nac`, `crecPc*`, `razonPcNL`, …).
- **Addendum F1 en `federacion-nl.html`** (misma gramática, otra estructura): (a) **Sankey navegable por año** con el `anio` del estado URL: lado recibe observado por año (EOFP); lado paga = participaciones de la corrida (ENIGH 2024, PE 2027) × recaudación observada de ese año, declarado en la nota de la vista, en el pie de cada extracto y en la columna "Participación de NL (%) · ENIGH 2024"; banda S1–S3 en todos los años; los impuestos negativos (estímulo al IEPS de gasolinas 2013/2014/2022) se dibujan como devolución a la derecha. El JSON lleva **`participacionesAnual`** (una fila por año 2000–2027 con `enigh`, `metodo: constante` y las 13 participaciones) para que el sprint de ENIGH bienal cambie datos y no HTML (+5 KB; `federacion-nl.html` 548 KB). (b) Paneles **apilados a ancho completo** (fondos arriba, detalle por fondo abajo). (c) **Jerarquía de controles**: zona fija = identidad + alcance + parámetros globales (registro, medida, escenario, año) + tarjetas; los botones de sección y los controles de la vista (rango, comparativo, modo, nota del año) viven pegados a los paneles. `FederacionNL.do` v1.1.0: vintage ENIGH leído del JSON de EntidadNL (`presentacion.enigh_vintage`, nueva clave aditiva de `EntidadNL.do`, o del criterio `momento_de_registro`) y guardado en el sello (`identidad.enigh`, exigido en modo sello); `_nltxt` corregido (comillas compuestas) y CSV de fondos con `\n`.
- Verificado desde el Drive (SHA idéntico, render sin red, autocomprobaciones en verde: 8 / 15 / 18 cifras) y **contraste medido** sobre estilos computados: texto 16.1, secundario y pie 5.3, blanco sobre morado 12.0, sobre acento 8.2, enlace 7.6, textos recibe/paga/alerta 4.6/4.6/4.9 (AA), referencia gris 4.0 y proyección 3.3 (gráfico). Statajson regenerado (paridad `output.txt` `ae624b98…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`), D.1 PASÓ); sello re-sellado.

#### NL-0.4.0 — 2026-10-04 (motor sincronizado: v8.6.0) — endpoint "La Federación y Nuevo León"
- **Driver `01_modulos/FederacionNL.do` v1.0.0**: transferencias federales a NL por fondo (SHCP, Estadísticas Oportunas, lector propio `_NLeopf` con caché completa de 32 entidades + No distribuible + total, `Last-Modified`, checksum, escritura atómica), carga federal de residentes por incidencia (`Part<X>nl` × recaudación observada de `LIF.dta`; sin OTROSK; cuotas IMSS aparte) y **balanza de flujos identificables** como banda [S1, S3] con S0; nominal / real (deflactor implícito PIBE NL) / per cápita (CONAPO) / % PIBE; lugar de NL entre las 32; anclas CP/PEF/PPEF por entidad (`PEF.dta`, `divFEDE`); 9 compuertas; JSON `nl.federacion/v1`.
- **Arquitectura B**: `nl-assets/federacion-sello.json` (extracto del canal con identidad y SHA) escrito en modo canal (Mac) y consumido en modo sello (runner) solo si capa, motor y `anioPE` coinciden; igualdad reldif 1e-9 exigida cuando el canal existe.
- **Endpoint `federacion-nl.html`** (412 KB, inline, cero red): letrero de alcance permanente; tarjetas en persona-escala con banda; **Sankey** de ida y vuelta con nodo "aportación neta en flujos identificables" y halo de la banda del ISR PM; serie con tramos observado / Paquete / en curso; recibe por fondo y subfondos; conciliación del lado paga; modo datos; autocomprobación (16 cifras); estado por URL común (`reg|medida|esc|anio|ini|fin|cmp|modo`).
- **Gramática de comunicación**: borrador `nl-assets/nl-estilo.md` (canon del motor, doctrina de registro, tokens) pendiente de la pasada de Ricardo; tokens parametrizados en `NLEstilo` (`nl-datos.js`).
- `EntidadNL.do` v1.3.0: `Part<X>nl`, `RecImp*`, `PartImp*` (aditivo; paridad `output.txt` intacta, D.1 PASÓ). `nl-fed.do`/`nl_fed.py`: lectores EOPF/JSON/SHA. Actualizadores con el tercer driver; runner con `robocopy /E` (sin borrado) en lugar de `/MIR`. Fuentes y defectos del caché `DatosAbiertos` del motor documentados (issue para `master`).

#### NL-0.3.2 — 2026-10-04 (motor sincronizado: v8.6.0) — instalación del runner Windows (primera máquina real)
- Primera instalación en la HP de CoNL (usuario con espacio, OpenSSH 9.5, Git 2.56); defectos hallados y corregidos en `windows/`: `IdentityFile` sin comillas; `ssh-keyscan` falla contra GitHub (KEX sntrup761) → clave ed25519 fija verificada por huella; `KexAlgorithms` compatible y reescritura de un bloque `Host` mal formado; `04_3_anteriores/` trae nombres con `?` inválidos en Windows → sparse-checkout + `core.protectNTFS false` solo en ese clon (Git rechaza la ruta al armar el índice aunque esté excluida); `Start-Process` sin comillas en la corrida de prueba; chequeo de `SIMroot` tolerante a CRLF.
- **Verificado en Windows 11 (HP, Stata 19.5 BE):** corrida completa descarga INEGI → compuertas → publicación al Drive → bitácora, sin intervención.

#### NL-0.3.1 — 2026-10-04 (motor sincronizado: v8.6.0) — corrección y compuerta de publicación
- **Diagnóstico del reporte "el JSON no fue incrustado" en `actividad-nl.html`**: el artefacto publicado en el Drive (SHA `00f04bbd26e0`, igual al de la bitácora de las 23:17) sí traía el JSON inyectado y renderizaba con autocomprobación en verde al abrirlo desde el Drive montado; el síntoma se reproduce exactamente al abrir la **plantilla** `01_modulos/nl-assets/actividad-nl.html` (marca sin reemplazar → `window.NLACT = ;` → SyntaxError → mensaje genérico). La hipótesis "4cb778a cambió las marcas sin re-correr el driver" se descarta por la bitácora (ambos drivers corrieron a las 23:17:34); lo que sí faltó fue **re-verificar actividad desde el Drive** tras la migración (solo se verificó población).
- **Post-mortem (dos líneas).** (1) La autocomprobación vive *dentro* del HTML: valida cifras contra arreglos cuando la página ya corre, pero nadie la leía antes de publicar y nada en `publicar-conl.sh` miraba el artefacto, así que un HTML sin datos (o la plantilla misma) podía cruzar al Drive y "renderizar" con un mensaje genérico. (2) **Regla nueva:** ningún endpoint se entrega sin verificación desde el Drive (abrirlo ahí y leer su pie), aunque el cambio parezca solo de plantilla; y la publicación tiene compuerta propia.
- **Compuerta de publicación** en `publicar-conl.sh` (Mac) y en `windows/actualizar-nl.ps1` (runner): antes de copiar cualquier HTML, (a) ninguna marca `/*__NL…__*/` sin reemplazar, (b) el componente `nl-datos.js` presente, (c) el bloque `<script type="application/json" id="nl-data">` existe, parsea como JSON y trae `procedencia.generado_en`. Si falla, aborta sin publicar y el Drive conserva lo vigente. Probada en negativo (plantilla en lugar del endpoint → aborta, SHA del Drive intacto) y, de inmediato, atrapó un falso positivo propio (un comentario de la plantilla citaba literalmente la etiqueta del bloque y confundía al extractor): corregido el comentario, no la compuerta.
- **Endurecimiento del artefacto**: los datos ya no van como literal JS (`window.X = {...};`) sino en `<script type="application/json" id="nl-data">` y se parsean con `JSON.parse` vía `NLDatos.load()`, que reporta con precisión qué falló (bloque ausente, marca sin reemplazar = "este archivo es la plantilla", JSON inválido con posición) en lugar de un "no fue incrustado" genérico. Ambos endpoints regenerados, publicados y verificados desde el Drive (pie en verde: 12 y 8 cifras).

#### NL-0.3.0 — 2026-10-03 (motor sincronizado: v8.6.0)
- **Retrofit de `poblacion-nl.html`**: modo datos (Gráfica/Tabla por vista, Copiar TSV, Descargar CSV con encabezado de procedencia: fuentes CONAPO y cobertura, filtros geo/sexo/edades/años, versión NL, corrida); filtro de **rango de edad** (edad simple en NL/nacional; en municipios **snap explícito a los grupos quinquenales** de la fuente, sin interpolar) y **sexo** aplicables a toda vista y tabla; tablas con columnas H / M / Total; tarjetas que respetan el filtro (población del rango, % del total, % mujeres del rango; la razón de dependencia se declara sobre toda la población) con autocomprobación de filtros (tarjeta = suma de la tabla) además de la del canal. 782 KB (+18 KB).
- **Componente compartido `nl-assets/nl-datos.js`** (extracto TSV/CSV con procedencia, tabla, portapapeles con fallbacks, descarga) y constructor `nl-assets/nl-html.do` (`nlhtml_inject`: marca de datos + marca `NL_DATOS_JS`); `actividad-nl.html` migrado al componente. Candado `version 17` en ambos drivers.
- **Runner Windows** (`windows/`): instalador idempotente con deploy key de solo lectura, port `actualizar-nl.ps1` con fallo seguro, verificador integral y README; ver anexo "Runner Windows".

#### NL-0.2.0 — 2026-10-03 (motor sincronizado: v8.6.0)
- **Endpoint de actividad económica y precios** (`01_modulos/PIBDeflactorNL.do` v1.0.0 + plantilla `nl-assets/actividad-nl.html`): PIBE nominal/real y deflactor implícito NL, crecimiento real con ancla PIBE + nowcast ITAEE, inflación INPC Nuevo León (promedio, dic/dic, vigente), comparativos nacionales con las mismas transformaciones, proyección corta al año de política con los criterios de `PIBDeflactor.ado`; 4 compuertas; JSON `nl.actividad/v1` + HTML autocontenido (150 KB) con **modo datos** (tabla con filtros, copiar TSV, descargar CSV, encabezado de procedencia en cada extracto).
- **Lectores INEGI de la capa** (`nl-assets/nl-bie.do` + `nl_bie.py`): `_NLbie indicador, area()` (BIE por área geográfica, misma vía pública que `AccesoBIE`) y `_NLinpc serie, estructura()` (programa INPC de INEGI). Motivo en el anexo PIBDeflactorNL §0.2; propuesta a `master` por PR aparte: opción `area()` en `AccesoBIE`.
- **Actualizador** `actualizar-nl.sh` (un comando: PoblacionNL + PIBDeflactorNL en batch con `profile.do`, fallo seguro con respaldo/restauración, publicación y bitácora `nl-assets/bitacora-publicaciones.log`).
- `publicar-conl.sh` publica también `actividad-nl.html` en la raíz del Drive.
- Drivers con log de procedencia propio y con nombre (`name(nlpob)`/`name(nlact)`): coexisten con el log de batch y entre sí.
- Segunda ronda: caché de tabla completa por indicador (un pull, filtro por área al consumir, escritura atómica), sellos de revisión INEGI por observación/serie/cifra, bloque `presentacion` con el criterio de proyección, bitácora con sellos.
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

**Refinamientos aprobados (2026-10-03, segunda ronda):** (1) `_NLbie` cachea la **tabla completa del indicador** (33 áreas, `raw/temp/AccesoBIE/nl_<id>.csv` + `.meta` con título, fecha de consulta y áreas) una sola vez por sesión y filtra `area()` al consumir: el comparativo nacional sale del mismo pull y el checksum registrado es el de la tabla completa. Escritura atómica (`.tmp` → `os.replace`): un formato inesperado (sin tabla, sin columna de área, sin filas) aborta y **conserva el último caché bueno**; el actualizador no publica. Vía pública, sin token. (2) INPC: estructura vigente localizada (post ago-2024), no hizo falta 2c; **Banxico SIE queda documentado como plan C** (INPC por ciudad, API con token propio), no implementado. (3) Criterio "sin exógenos CGPE estatales" declarado en el bloque `presentacion` del JSON (y en el pie y los extractos del HTML). **Sellos de revisión INEGI** (ITAEE `p1`, PIBE `r1`) viajan por observación en `anual.selloPIBEnl/nac` y `trimestral.selloITAEEnl`, por serie en `procedencia.series[].sello_ultimo`, en `cifras.selloPIBEult/selloITAEEult`, en las tarjetas, en la columna "Sello INEGI" de las tablas, en el encabezado de los extractos y en la bitácora. El PR a `master` con `area()` en `AccesoBIE` **va por separado** (no se toca el motor en esta rama); especificación: estrictamente aditivo, sin la opción el comportamiento es byte-idéntico al actual.

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

---

## Anexo Runner Windows — la máquina de CoNL ejecuta y publica sola (2026-10-03, capa NL-0.3.0)

**Arquitectura.** La laptop HP de CoNL (Windows 11, Stata 19.5 StataNow, Git con `core.autocrlf false`, Tailscale, Google Drive Desktop) es un *runner* de **solo lectura**: clon de una sola rama (`feature/entidad-nl`) por **deploy key sin escritura**, `git reset --hard origin/<rama>` en cada corrida (aborta si el working tree está sucio: señal de que alguien editó donde no debía), drivers NL en Stata batch (`/e do`) desde la raíz del repo (carga `profile.do`), publicación al Drive **de esa máquina** (`G:\Mi unidad\2. Simuladores CoNL\SimuladorCoNL`). Jamás desarrolla, jamás pushea. Carpeta `windows/` de la capa NL:

| Archivo | Función |
|---|---|
| `runner-common.ps1` | funciones compartidas: `Find-Stata` (C:\Program Files\Stata19\ MP > SE > BE, luego StataNow*), `Invoke-StataBatch`, `Invoke-Native` (git/ssh/robocopy sin que PowerShell 5.1 convierta stderr en excepción), `Test-StataLogError`, bitácora y tabla verde/rojo |
| `instalar-runner.ps1` | idempotente: prerrequisitos (git, autocrlf, OpenSSH, Drive montado + escritura de prueba + proceso GoogleDriveFS, Stata), deploy key ed25519 en `%USERPROFILE%\.ssh\simulador_nl_deploy` + alias en `~/.ssh/config` + known_hosts + prueba `ssh -T`, clon `--branch --single-branch`, `config-runner.ps1` desde la plantilla, tarea programada vía XML (`Register-ScheduledTask`) |
| `actualizar-nl.ps1` | port de `actualizar-nl.sh`: fetch/reset, respaldo de productos, Stata batch, verificación del log (`r(#)`, 3 marcadores, 4 productos), reintento único a los 30 min si el fallo parece de INEGI (`-RetryOnce`), `robocopy /MIR` **solo** sobre `nodos\`, copia de HTML a la raíz, bitácora `windows\bitacora-runner.log` y latido `ultimo-exito.txt` (local + Drive) |
| `verificar-runner.ps1` | chequeo integral: config, prerrequisitos, clon (rama, limpio, al día, remoto por deploy key, archivos clave), Stata batch (`display`, Python, `requests`/`bs4`, `SIMroot`), escritura/borrado de prueba en el Drive, tarea y próxima ejecución, corrida completa de prueba; tabla verde/rojo en `windows\verificacion-runner.log` + qué pegar a Devin/Claude |
| `config-runner.ps1.template` → `config-runner.ps1` | rutas (repo, Stata, Drive, rama, alias SSH); la real queda fuera de git (`windows/.gitignore`, propio de la capa: el `.gitignore` del motor no se toca) |
| `README-runner.md` | checklist de 10 pasos, política del runner, tarea y credenciales |

**Verificación posible desde el Mac (sin Windows):** los cinco `.ps1` pasan el parser de PowerShell (7.6, portátil en `/tmp`, sin instalar nada) con 0 errores; UTF-8 con BOM y CRLF verificados; funciones compartidas (`Show-Resumen`, `Get-RunnerConfig`) probadas; `actualizar-nl.ps1` ejercitó en Mac el camino de **aborto seguro por working tree sucio** (exit 1, bitácora, Drive intacto). Lo que solo Ricardo puede verificar en la HP lo cubre `verificar-runner.ps1` con salida inequívoca.

**Deploy key.** ed25519 sin passphrase, alias `github-simulador-nl` (`IdentitiesOnly yes`), registrada en GitHub → `rcantuc/SimuladorCIEP` → Settings → Deploy keys **sin** "Allow write access". El instalador se detiene (exit 2) hasta que GitHub la acepta y se vuelve a correr.

**Tarea programada.** `SimuladorNL-Actualizar`: mensual día 5, 03:00; `StartWhenAvailable` (si se omitió, corre en cuanto pueda), `WakeToRun`, `RunOnlyIfNetworkAvailable`, sin bloqueo por batería, `MultipleInstancesPolicy=IgnoreNew`, límite 3 h; acción `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...\actualizar-nl.ps1 -RetryOnce`.
**Limitaciones conocidas:** (1) corre con **InteractiveToken** (sesión iniciada, puede estar bloqueada) porque `G:\` de Google Drive Desktop solo existe dentro de la sesión del usuario; "ejecutar aunque el usuario no haya iniciado sesión" (S4U/contraseña guardada) perdería la unidad y, además, exigiría re-registrar la tarea tras cada cambio de contraseña — con InteractiveToken no se guardan credenciales y el cambio de contraseña no la afecta. (2) `Register-ScheduledTask` puede requerir PowerShell como administrador; el instalador lo reporta en rojo con la instrucción. (3) Python de Stata en Windows: debe configurarse una vez (`python set exec ..., permanently`, 3.9–3.12) con `requests` y `beautifulsoup4` para `AccesoBIE`; `verificar-runner.ps1` lo comprueba. (4) En la primera corrida de una máquina virgen, `master/Poblacion.dta` no existe: `PoblacionNL.do` invoca `Poblacion` del motor, que lo construye desde el asset del sidecar (descarga y SHA vía `ensure_asset`); `PIBDeflactorNL.do` declara "no evaluada" la compuerta de control contra `master/PIBDeflactor.dta` si ese caché no existe.

**Fila pendiente (recordatorio):** el PR a `master` con la opción `area()` en `AccesoBIE` sigue **pendiente, por separado** (estrictamente aditivo; sin la opción, byte-idéntico).

---

## Anexo Federación↔NL — F0: inventario y diseño del endpoint "La Federación y Nuevo León" (2026-10-04; F0 APROBADO con las resoluciones de §0.6; implementado en NL-0.4.0, ver §1–§4 abajo)

**Objeto.** Tercer endpoint: cuánto recibe NL de la Federación (gasto federalizado identificable por entidad), cuánto pagan sus residentes en impuestos federales (incidencia micro de la capa NL) y la **balanza de flujos identificables** entre ambos. Las reglas de diseño del prompt (alcance declarado, lado "paga" desde la incidencia y nunca por domicilio fiscal, banda S1–S3 propagada, petroleros/no tributarios fuera, sidecars para transformaciones, comparabilidad nacional) se toman como dadas; aquí se documenta qué hay, qué falta y cómo se arma. Solo lectura: ningún archivo del motor ni de la capa cambió en F0.

### 0.1 Qué tiene ya el motor (verificado en Stata sobre los cachés del worktree, solo lectura)

| Pieza del endpoint | Dónde vive en el motor | Nivel | Cobertura en el caché actual | Fuente / vintage | Juicio para F1 |
|---|---|---|---|---|---|
| **Transferencias pagadas por fondo × entidad, mensual** | `master/DatosAbiertos.dta` (vía `UpdateDatosAbiertos` §1.5: `transferencias_entidades_fed` + `_hist`) | **32 entidades + "No distribuible" (`33`) + total (`00`)**, por fondo: R28 total y 13 fondos (`XAC28A`–`M`: FGP, FFM, IEPS, tenencia, 0.136 % RFP, DAEP, ISAN, incentivos, FOFIR, FEXHI, IEPS gasolinas, Repecos, Fondo ISR); R33 total y 15 (`XAC33A`–`O`: FAEB/FONE, FASSA, FAIS y sus dos componentes, FAM y sus tres, FORTAMUN, FASP, FAETA y sus dos, FAFEF); convenios de descentralización (`XACCD` + SADER/SEP/CONAGUA), convenios de reasignación (`XACCR`), gasto federalizado del R23 (`XAC23` + FIES/FEIEF/resto), protección social en salud (`XACPSS`), total gasto federalizado (`XACGF`) | NL: 1990 (R28), 1997 (R33, fondos), 2000 (CD, CR, R23, PSS, GF) → **2026m7**; monthly, flujo **pagado**, miles de pesos ×1000 | SHCP, Estadísticas Oportunas de Finanzas Públicas, datos abiertos; caché del 22-sep-2026 | Es exactamente la serie oportuna que pide el endpoint. **Dos defectos del caché del motor** (no de SHCP): (a) `UpdateDatosAbiertos` §4.7 crea una clave `XACGF00` = `XAC2800+XAC3300` (nombre "Gasto Federalizado") que **duplica** la clave homónima de SHCP ("Total: Total Gasto Federalizado"): el total nacional queda inflado ~2× (2024: 4.88 vs 2.59 billones); (b) en **2011** (costura `_hist`/vigente) las filas nacionales de varios subfondos (R28 −6.9 %, FAIS −47 %, FAM −30/−53 %, FAFEF −41 %) no cuadran con la suma por entidad, mientras el CSV **fresco de SHCP cuadra a 1e-9** en 2011 (verificado hoy). Conclusión: la capa **no debe leer `DatosAbiertos.dta`** para este lado; lee el CSV de SHCP con fetcher propio (patrón `_NLbie`). |
| **Gasto federalizado por entidad, anual, Cuenta Pública** (ancla) | `master/PEF.dta` (`UpdatePEF`; assets `raw/PEFs/CP 2013–2025.xlsx`, `PEF 2026.xlsx`, `PPEF 2027.xlsx` vía sidecar con SHA) | registro presupuestario con `entidad` (1–32, 33 extranjero, 34 no distribuible) y `divFEDE` ∈ {Participaciones (R28), Aportaciones (R33+R25), Convenios (objeto 43801/85101/43101-SADER), Subsidios (R23: FEIEF, FIES, 43801), Salud federalizado (INSABI/IMSS-Bienestar pp 13), No federalizado} | **CP ejercido 2013–2025**; PEF aprobado 2026; PPEF proyecto 2027 (los tres con entidad) | SHCP/Transparencia Presupuestaria, datos abiertos de CP/PEF/PPEF | **Ancla anual definitiva y Paquete.** Cotejo CP vs Estadísticas Oportunas para NL: **R28 idéntico al peso** en 2013–2025 (p. ej. 2024: 68,555,752,172 en ambos); R33 dentro de ±0.15 % salvo **2022 (+1.8 %)**; convenios difieren por construcción (CP clasifica por objeto de gasto; EOFP por fondo). Hallazgo útil: PEF/PPEF **sí distribuyen R28 y R33 por entidad** → el año de política tiene lado "recibe" del Paquete (NL 2026: R28 76.5 / R33 36.0 mmdp; PPEF 2027: 82.6 / 39.1 mmdp). |
| **Recaudación observada por impuesto, anual** | `master/LIF.dta` (`UpdateLIF`), familia `divSIM`: ISRAS, ISRPF, ISRPM, CUOTAS, IVA, IEPSNP, IEPSP, ISAN, IMPORT, OTROSK, FMP, PEMEX, CFE, IMSS, ISSSTE, DEUDA | nacional | observado (`monto`, mes 12) **2013–2025**; 2026 a julio; `ILIF` 2026 (LIF aprobada) y 2027 (Paquete) | SHCP EOFP (vía `DatosAbiertos`) + LIF/ILIF | Es el canal "recaudación del motor" que exige la compuerta ("no re-descargada"). Nota: IEPS petrolero **negativo** en 2013, 2014 y 2022 (estímulo a gasolinas) → el "paga" de ese renglón es negativo esos años; se declara, no se trunca. |
| Escalares del motor reutilizables | `LIF, by(divSIM)` → `r(ISRAS)`… (PerfilesSim §2); `PIBDeflactor` (`pibY`, `deflator`, `Poblacion`); `Poblacion.dta` (32 entidades, CONAPO) | nacional / 32 entidades | — | — | Población de las 32 entidades disponible → **lugar de NL entre las 32 per cápita es factible por el canal**. |
| Legado | `01_modulos/legacy/Subnacional.do` §3 (DatosAbiertos `XAC28/33/23/CD/CR/PSS` × 32), `SubnacionalGasto.do` | — | sin mantenimiento (v8.1) | — | Confirma la nomenclatura de claves EOFP; no se reutiliza código (depende de `c(sysdir_site)` y de códigos `encode` obsoletos). |

**Lo que el endpoint pide y el motor NO tiene por entidad:** nada en el lado "recibe" (todo existe por entidad en EOFP y en CP). Lo que falta es (i) un lector **sano** de EOFP (los defectos del caché arriba), (ii) **PIBE y población NL** → ya los dan los sidecars `PIBDeflactorNL` y `PoblacionNL`, (iii) **incidencia por impuesto en pesos** → capa NL (0.3). El gasto federal **directo** ejercido en NL (pensiones contributivas, IMSS/ISSSTE patronal, CFE, inversión física federal, sueldos federales) existe en `PEF.dta` con `entidad` solo parcialmente (buena parte cae en 34 "No distribuible": p. ej. R19 pensiones): queda **fuera del alcance** y así se declara; su atribución es la fase futura explícita.

### 0.2 Fuentes SHCP para NL (verificadas con llamadas reales, 2026-10-04)

| Fuente | URL / mecanismo (verificado) | Unidad y registro | Frecuencia, rezago | Años | Formato | Propuesta de uso |
|---|---|---|---|---|---|---|
| **Estadísticas Oportunas — Transferencias a entidades federativas y municipios** | `https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.zip` (HEAD 200, 2.56 MB, **Last-Modified 30-sep-2026**; CSV de 80 MB, 260,304 filas, `PERIODO_INICIO 2011-01`, `PERIODO_FINAL 2026-08`) + `..._hist.zip` (1.6 MB, 11-nov-2025, 1990/1997–2010). Descarga directa sin token. | miles de pesos; flujo **pagado**; columnas `CICLO, MES, CLAVE_DE_CONCEPTO, NOMBRE, …, MONTO` | mensual; "30 días después del cierre del mes" | 1990/1997–**2026-08** | ZIP→CSV | **Serie oportuna (nowcast) y detalle por fondo.** Fetcher propio `_NLeopf` (nl-assets): descarga ambos ZIP, **cachea la tabla completa (32 entidades + ND + total, todos los fondos)** en `raw/temp/EOPF/nl_transferencias.csv` + `.meta` (Last-Modified, periodo final, n, checksum), escritura atómica, filtro de entidad al consumir, fallo seguro (formato inesperado → conserva caché y aborta). El filtro de claves es por **lista explícita** de fondos (no por substring: `XAC4219` es "Ramo Bienestar", no NL). |
| **Transparencia Presupuestaria — Cuenta Pública (datos abiertos)** | índice `…/PTP_Datos_Abiertos/data/cuenta_publica/cuenta_publica.json` → `…/BD_Cuenta_Publica/XLSX/cuenta_publica_2025_gf_ecd_epe_xlsx.zip` y `CSV/…2025….csv` (200, 105.6 MB, 19-may-2026); 2020–2025 en línea | pesos; aprobado/modificado/devengado/pagado/ejercido por registro con `ID_ENTIDAD_FEDERATIVA` | anual; CP del año t sale en abr–may de t+1 | 2013–2025 (el motor conserva 2013–2019 en el sidecar) | XLSX/CSV | **Ancla anual definitiva**: es la misma base que el motor ya ingiere a `PEF.dta` (sidecar con SHA). La capa **no la re-descarga**: consume `PEF.dta` (`divFEDE` × `entidad` × año). |
| **Transparencia Presupuestaria — PEF / PPEF (datos abiertos)** | `…/Bases_de_datos_presupuesto/XLSX/PPEF_2027.xlsx` (200, 18.6 MB, 12-sep-2026); PEF 2020–2026 | pesos aprobados / proyecto, con entidad para R28/R33 | anual | 2020–2027 | XLSX/CSV | Año de política: lado "recibe" del Paquete, también vía `PEF.dta`. |
| Transparencia Presupuestaria — "Gasto Federalizado" (`Entidades_Federativas/2025/ef2025.zip`, 23.7 MB, 31-ago-2026) | 200 | proyectos reportados por los **ejecutores locales** (SRFT: destino del gasto, contratos, georreferencias) | trimestral | 2013–2026T2 | ZIP (6 CSV) | **No se usa**: es el reporte del receptor sobre el destino, no el flujo federal pagado; útil para una fase de "destino" futura. |
| Cuenta Pública — Tomo de gasto federalizado (`cuentapublica.hacienda.gob.mx/es/CP/2024`, 200) | HTML/PDF/XLSX por tomo | anual | — | referencia documental del ancla; no se automatiza (el dato ya viene en la base abierta). |
| Sidecars de la capa | `actividad-nl.json` (`pibeNnl/nac`, `deflatornl/nac`, `partPIBEnl`, proyección al año de política) y `poblacion-nl.json` / `master/Poblacion.dta` (NL, nacional, 32 entidades) | — | — | — | per cápita, reales y % PIBE; población de las 32 para el ranking. |

**Compuerta de consistencia interna de EOFP (probada sobre el caché y sobre el CSV fresco):** para cada fondo y año 2000–2026, Σ(32 entidades) + "No distribuible" = total nacional con error < 1e-6 (el único fallo, 2011, es artefacto del caché del motor, no del CSV). El total "GF" de SHCP = R28+R33+CD+CR+R23+PSS a 1e-9 en todos los años, nacional y NL. **Año de arranque común** del lado "recibe" con los seis agregados: **2000** (R28 y R33 desde 1990/1997 se exportan igualmente, marcados como "sin convenios/R23/PSS"); detalle por subfondo desde 2008 (FOFIR/FEXHI/IEPS gasolinas), 2014 (Repecos), 2015 (Fondo ISR). **Anclas:** R28 EOFP = CP al peso (tolerancia de compuerta 0.1 %); R33 EOFP vs CP tolerancia 2.5 % (2022 +1.8 % por R25/devengado-vs-pagado; se declara); convenios/subsidios: cotejo **informativo** (clasificaciones distintas), no compuerta.

### 0.3 Lado "paga": qué expone hoy `statajson_entidad-nl.json` (PE 2027, v8.6.0, corrida 4-oct-2026)

Escalares `mxn` por impuesto, nacional y NL (sufijos `nac`/`nl`): `Rec{ISRAS,CUOTAS,ISRPF,ISRPM,OTROSK,IVA,IEPSNP,IEPSP,ISAN,IMPORT,Total}`; banda del ISR PM: `RecISRPMnlS1/S2/S3`, `PartISRPMnl/S1/S2/S3`; `PartRecTotalnl`; `Pobnl/Pobnac` (ENIGH expandida). **Verificado:** `Rec<X>nac` coincide con el nivel LIF/ILIF 2027 del motor para cada impuesto (p. ej. `RecIVAnac` = 1,768,017.3 mdp = ILIF 2027 IVA; `RecCUOTASnac` = 702,564.7 mdp), de modo que la **participación de NL en cada impuesto es `Rec<X>nl / Rec<X>nac`** y está completamente determinada por el canal:

| Impuesto | Part. NL (%) | | Impuesto | Part. NL (%) |
|---|---:|---|---|---:|
| ISR salarios | 8.82 | | IVA | 6.46 |
| ISR personas físicas | 6.10 | | IEPS no petrolero | 12.01 |
| ISR personas morales S0 (vigente) | **14.23** | | IEPS petrolero | 6.48 |
| ISR PM S1 (cota inferior) | 8.64 | | ISAN | 6.48 |
| ISR PM S3 (cota superior) | 20.97 | | Importaciones | 6.26 |
| Cuotas IMSS | 9.83 | | (ref.) población ENIGH / PIBE 2023 | 4.71 / 7.86 |

**Escalares a agregar aditivamente a `EntidadNL.do` (no cambian nada existente):** `Part<X>nl` (pct) para los 10 impuestos (hoy solo existen `PartISRPMnl*` y `PartRecTotalnl`), `RecImpnl`/`RecImpnac` = total **sin OTROSK ni cuotas** (impuestos federales stricto sensu) y sus `RecImpnlS1/S3`, `PartImpnl/S1/S3`. El driver F1 los lee del JSON y además **recalcula `Part = Rec/Rec` como compuerta** (reldif < 1e-9). Nada más falta.

**Decisión de alcance del "paga" (propuesta):** incluir ISR AS/PF/PM, IVA, IEPS NP y P, ISAN e importaciones; **excluir OTROSK** (productos, derechos, aprovechamientos: no tributarios y en parte petroleros; ya fuera del total del pipeline) y **mostrar las cuotas IMSS en renglón aparte etiquetado, sin sumarlas**: su contraparte de gasto (IMSS) está fuera del lado "recibe" por alcance, y sumarlas sesgaría la balanza. Si se prefiere sumarlas, basta un flag en el driver (se exportan ambas versiones de todos modos).

**Orden de magnitud (F0, a mano desde el canal; NO citable — las cifras citables salen del driver):** 2025, participaciones fijas de la corrida PE 2027 × recaudación observada 2025 (`LIF.dta`): paga impuestos **S0 ≈ 496 mmdp, banda [414, 595]**; cuotas IMSS aparte ≈ 59; recibe (EOFP 2025) **≈ 117 mmdp** (R28 71.8, R33 35.8, convenios 8.2, PSS 1.1, R23 0.5); balanza **≈ −379 mmdp [−478, −297]**; per cápita (CONAPO 2025) recibe ≈ 18.3 mil vs ≈ 20.3 mil nacional; paga ≈ 77 mil [65, 93]; balanza ≈ −59 mil [−74, −46] por persona. El signo y el orden coinciden con la literatura de balanza fiscal estatal; la banda del ISR PM es, con mucho, la mayor fuente de incertidumbre (±90 mmdp).

### 0.4 Propuesta de diseño

**Fórmulas (todas en el driver, ningún número a mano):**
- `recibe[f,t]` = EOFP pagado NL por fondo `f` y año `t` (suma de meses; año en curso = acumulado a `mes_ult`, etiquetado "parcial"); `recibe[t]` = Σ seis agregados; para el año de política `t = anioPE`: PPEF/PEF por entidad (`PEF.dta`, divFEDE), etiquetado "Paquete".
- `paga[x,t]` = `Part<x>nl` (corrida vigente) × `recaudación observada[x,t]` (`LIF.dta`, mes 12; año en curso: acumulado; anioPE: ILIF) para x ∈ impuestos; **banda**: `pagaS1[t]`, `pagaS3[t]` sustituyen solo el ISR PM; S0 = método vigente, marcado.
- `balanza[t]` = `recibe[t] − paga[t]`, como banda `[recibe − pagaS3, recibe − pagaS1]` con S0 dentro.
- Transformaciones: nominal; real = `/deflatornl[t]` (deflactor implícito del PIBE NL base `aniovp`, de `actividad-nl.json`; alternativa declarada: INPC NL); per cápita = `/pobNL[t]` (CONAPO, `master/Poblacion.dta`, **no** la ENIGH expandida); % PIBE = `/pibeNnl[t]×100` (observado hasta 2024, nowcast/proyección después, con `tipo`). Referencia nacional de cada flujo "recibe": per cápita nacional (`total 00 / pobNac`) y **lugar de NL entre las 32** per cápita por fondo (población de las 32 del motor).
- **Supuesto declarado y visible:** la participación de NL en cada impuesto se toma **constante en el tiempo** (vintage ENIGH 2024 / PE 2027). Es una retropolación de incidencia, no una serie observada; el JSON lo marca por celda (`tipo: "incidencia fija"`) y el HTML lo dice junto a la serie.

**Esquema del JSON `users/ricardo/nodos/federacion-nl.json` (`esquema: "nl.federacion/v1"`, estilo `actividad-nl.json`; identidad `_NLidentidad`):**
```
producto, titulo, subtitulo, anio_referencia (último año completo con ambos lados observados), anio_politica,
alcance: { declarado: "balanza de flujos identificables", incluye: [...], excluye: [...], leyenda_tarjeta },
procedencia: { version_motor, version_capa_nl, driver, log, generado_en,
  fuentes: [ {id:"eopf_transferencias", url, last_modified, periodo_final, n, checksum},
             {id:"pef_dta", vintage (fecha del archivo), anios_cp, anio_pef, anio_ppef},
             {id:"lif_dta", vintage, ultimo_mes}, {id:"entidad_nl_json", generado_en, version_capa_nl, anioPE, sha256},
             {id:"actividad_nl_json", ...}, {id:"poblacion_dta", ...} ],
  compuertas: { suma32: "...", ancla_r28: "...", ancla_r33: "...", part_igual_rec: "...", vintage_entidadnl: "...", rejilla: "..." },
  supuestos: { incidencia_fija, deflactor, poblacion, anio_parcial, paquete } },
definiciones: { fondos: {R28:{...13 subfondos}, R33:{...15}, CD, CR, R23, PSS}, impuestos: {...}, escenarios: {S0,S1,S2,S3}, tipo: {observado, parcial, Paquete, incidencia fija} },
cifras: { anioRef, anioParcial, mesUlt, recibeNL, recibeNLpc, recibeNacpc, lugarRecibePc, recibeR28, recibeR33, recibeConv, recibeOtros,
          pagaS0, pagaS1, pagaS3, cuotasIMSS, balanzaS0, balanzaS1, balanzaS3, balanzaPc*, balanzaPIBE*, partRecibeNL, ... (escalares del driver, sin guion bajo) },
anual: [ {anio, tipoRecibe, tipoPaga, recibe{R28,R33,CD,CR,R23,PSS,total}, recibeNac{...}, pagaS0{ISRAS,...,total}, pagaS1total, pagaS3total, cuotas,
          balanzaS0, balanzaS1, balanzaS3, deflator, pobNL, pobNac, pibeNnl, tipoPIBE, pc{...}, real{...}, pibe{...}, lugarPc{R28,R33,total}} ],
subfondos: [ {anio, clave, fondo, nombre, nl, nac, partNL, pcNL, pcNac, lugar} ],   // detalle R28/R33 por fondo
mensual: [ {anio, mes, recibe{...}} ]   // solo agregados, para el año en curso y el anterior (nowcast)
```
Familias de escalares del driver (registro solo-aditivo vía `escalar`, sin guion bajo): solo cifras del **año de referencia y del año de política** (`recibeNL`, `recibeNLpc`, `recibeNacpc`, `lugarRecibePc`, `recibeR28NL`, `recibeR33NL`, `pagaS0NL`, `pagaS1NL`, `pagaS3NL`, `cuotasIMSSNL`, `balanzaS0NL`, `balanzaS1NL`, `balanzaS3NL`, `balanzaPcS0NL`, `balanzaPIBES0NL`, `partRecibeNL`, …, y sus variantes `*PE`); las series completas viajan en los arreglos `anual`/`subfondos`/`mensual`, mismo criterio que `actividad-nl`.

**Compuertas del driver `01_modulos/FederacionNL.do` (abortan):** (1) **suma 32 + ND = total nacional** por fondo y año (tolerancia 1e-4 relativa; con el CSV fresco pasa a 1e-9); (2) **ancla CP**: R28 NL EOFP = `PEF.dta` R28 NL por año CP (0.1 %) y R33 (2.5 %); convenios: diferencia **reportada**; (3) **recaudación = la del motor**: el "paga" usa `LIF.dta` (vintage registrado) y verifica que `Rec<X>nac` del JSON de EntidadNL = ILIF del año de política en `LIF.dta` (reldif 1e-6); (4) **`Part = Rec/Rec`** recalculado (1e-9); (5) **vintage de EntidadNL compatible**: `presentacion.version_capa_nl` = `nl-manifest.version_nl`, `version_motor` = `05_scripts/manifest.json`, `anio_referencia` = `anioPE` de la sesión; si no, aborta con mensaje; (6) **rejilla** anual 2000–anioPE sin huecos, mensual sin huecos (año en curso), subfondos con año de inicio declarado; (7) **identidad GF**: total EOFP de SHCP = Σ seis agregados (1e-6); (8) log activo y exactamente una marca de inyección en la plantilla (como los otros drivers).

**Vistas de `federacion-nl.html` — formato narrativo (pregunta → patrón del canon → por qué ese; canon en `nl-assets/nl-estilo.md` §2; tokens §3). Reglas duras sin cambio: un archivo, inline, cero red, < 2 MB, autocomprobaciones, modo datos; estado por URL común a todos los endpoints `#vista=…&reg=pc|macro&medida=nominal|real|pibe&esc=S0&anio=&ini=&fin=&cmp=1&modo=tabla`.**

- **Encabezado + tarjeta permanente de alcance** (no en el pie). *Pregunta:* ¿qué estoy mirando y qué no? → *Patrón:* la "costura" declarada de `nodo-deuda.html` (criterios de cobertura institucional, neto/bruto, denominadores), pero **desplegada**, no plegada, porque aquí el alcance cambia el signo de la lectura. → Texto: "Balanza de **flujos identificables**: gasto federalizado pagado a NL (R28, R33, convenios, subsidios R23, PSS) menos impuestos federales de residentes de NL por incidencia. **Excluye** gasto federal directo ejercido en NL (pensiones contributivas, IMSS/ISSSTE, CFE, inversión física federal, sueldos federales) — fase futura".

- **Tarjetas (persona-escala, año de referencia).** *Pregunta:* ¿cuánto recibe, cuánto paga y cuánto queda **por neolonés**? → *Patrón:* familia per cápita del motor (`PIBDeflactor pib_pc`, `GastoPC`, columna `MXN PC` de PEF/LIF) + doctrina de registro §1 de `nl-estilo.md`. → Titular per cápita **con banda** (`paga` y `balanza` como [S1, S3], S0 marcado), subtítulo macro (nivel en mmdp y % PIBE), tercera línea comparativo: recibe per cápita NL vs nacional y **lugar x de 32**; etiqueta "acumulado a <mes>" si el año es parcial. Tres tarjetas: recibe · paga · balanza; el letrero de alcance pegado a la cifra de la balanza.

- **Vista principal — La balanza como flujo de ida y vuelta (Sankey).** *Pregunta:* ¿cómo circula el dinero entre los neoloneses y la Federación? → *Patrón:* **Sankey Sistema Fiscal** (`SankeySF.do` + `SankeySumSim.ado`): nodo central, flujos de entrada por origen y de salida por destino, cierre contable siempre visible ("Endeudamiento → Futuro"); y el precedente bidireccional `SankeyPemex/CFE` (una entidad frente a la Federación). → *Por qué ese y no otro:* la pregunta sustantiva del endpoint es de **ida y vuelta**, no de nivel: una serie temporal muestra el saldo pero esconde que los 496 mmdp salen por nueve impuestos y los 117 regresan por cinco fondos; el Sankey es el único patrón del canon que cuenta las dos direcciones y el saldo en una sola figura, y es el que el CIEP ya usa para "de dónde sale y a dónde va" el Paquete. → *Construcción:* izquierda = impuestos pagados por residentes (ISR AS, ISR PF, ISR PM, IVA, IEPS NP, IEPS P, ISAN, importaciones; cuotas IMSS como enlace punteado aparte, no sumado) → nodo central **"Federación"** → derecha = R28 (con FGP y Fondo ISR destacados), R33 (FONE/FASSA/FAIS/FORTAMUN/resto), convenios, R23+PSS → nodo **"Nuevo León"**; el **saldo neto** cierra como nodo "Resto de la Federación" (contribución neta de NL), espejo del "Endeudamiento → Futuro" del motor. La **banda** del ISR PM se cuenta con el patrón del motor para lo incierto: el enlace ISR PM se dibuja en S0 con un **halo al 25 %** hasta S3 y un borde punteado en S1 (eco de `linkalpha 30`/`fintensity 40`); el selector `esc=S1|S0|S3` redibuja el Sankey completo. Registro: `pc` muestra los enlaces en MXN por neolonés (los anchos no cambian, solo las etiquetas), `macro` en mmdp y % PIBE. Año seleccionable (`anio=`), por defecto el de referencia. Un Sankey **no** sirve para la evolución: por eso es la vista principal y no la única.

- **Vista secundaria — La balanza en el tiempo.** *Pregunta:* ¿la contribución neta de NL crece o se achica? → *Patrón:* barras del nivel + línea punteada de variación con **tres tramos** observado / Paquete / proyección (`PIBDeflactor pib_pc` 687-731; `SHRFSP` 510-545 con `xline(anioPE-.5)`), más la banda del motor para lo incierto (`fintensity`). → *Por qué:* es el patrón del canon para "nivel per cápita + cambio" y ya separa el Paquete del observado, que aquí es obligatorio (2026 parcial, 2027 PPEF/ILIF). → Serie `recibe − paga` 2013–anioPE como banda [S1, S3] con línea S0, per cápita real por defecto (`reg=pc`), % PIBE o nominal en `macro`; `xline` discontinua antes del Paquete; oración-resumen bajo la gráfica generada desde el JSON ("De 2013 a 2025 la contribución neta por neolonés pasó de x a y MXN de VP"), como el `b1title` del motor.

- **¿Cuánto recibe NL?** *Pregunta:* ¿de qué fondos viene y cómo se compara con el país? → *Patrón:* **barras apiladas por año con grupos ordenados de mayor a menor y agrupación de los menores** (`LIF.ado` 550-563 / `PEF.ado` 582-605: `over(resumido, sort(1) descending) over(anio) stack asyvars`, `blabel`, oración `b1title`) para la composición (R28 / R33 / convenios / R23+PSS), y **línea NL saturada vs nacional atenuada** para el per cápita (patrón de comparativo de `actividad-nl`, tokens `--nl/--nac`). → *Por qué:* es exactamente cómo el motor cuenta "composición del gasto y su evolución"; el `highlight()` de PEF (atenuar al 30 % lo no seleccionado) se reutiliza al elegir un fondo. → Tabla de **subfondos** del año seleccionado con las columnas del display del motor adaptadas: Concepto · `MXN` (o per cápita) · `% del total NL` · `% NL en el nacional` · `MXN PC NL` · `MXN PC nacional` · `lugar de 32`; años de inicio de cada fondo declarados.

- **¿Cuánto pagan los neoloneses?** *Pregunta:* ¿por qué impuestos sale el dinero y cuánta incertidumbre hay? → *Patrón:* **tabla de conciliación** `(+)/(−)/(=)` de LIF/PEF (impuestos sumados, cuotas IMSS como renglón `(·)` aparte no sumado, total `(=)` en negritas) + **barras apiladas por año** (composición por impuesto, mismo patrón que arriba) con la **banda** del total [S1, S3] sombreada y S0 "método vigente" (`presentacion.escenario_s0` de `entidad-nl`). → *Por qué:* la incidencia ya se presenta en el canon como tabla con totales y nota de suma (INCD / `EntidadNL.do` §4); el supuesto "participación fija de la corrida vigente × recaudación observada" se escribe junto a la serie, no en el pie.

- **Modo datos** (ya canon desde NL-0.3.0): tabla/TSV/CSV con encabezado de procedencia (fuentes, Last-Modified EOFP, vintage CP/LIF/EntidadNL/Población, alcance, supuesto de incidencia fija, filtros y registro activo); autocomprobación: tarjetas = recálculo desde `anual`, Σ fondos = total, Σ impuestos = pagaS0, S1 ≤ S0 ≤ S3, Σ enlaces del Sankey = totales de cada lado, y **compuerta de denominador** (sello de población del JSON = sello de `poblacion-nl.json` de la misma corrida).

### 0.5 Gramática de comunicación (addendum F0)

**(a) Inventario del canon.** Borrador entregado en `01_modulos/nl-assets/nl-estilo.md` (patrones por módulo —familia per cápita con prioridad: `outputPW*`/`pibYPC`, `GastoPC`, `MXN PC` de PEF/LIF, deuda per cápita—, composición/evolución, distribución, Sankey, schemes con paletas, convenciones de tablas y catálogo de formatos de `escalar.ado`). Hallazgos que fundan reglas: el motor **separa siempre** observado / Paquete / proyección (tramos `p1/p2/p3`, `xline(anioPE-.5)`, `fintensity 40-50`); **ordena de mayor a menor y agrupa lo menor a `min()`**; **cuenta el dato en una oración** (`b1title`/`text()`); usa **tablas a cuatro columnas** (MXN · % PIB · % Tot · MXN PC) con conciliación `(+)/(−)/(=)`; el lenguaje web del Paquete es **ultra-austero** (tabla desnuda + costura plegada + sello). Los tres HTML de la capa hoy eligen colores propios y distintos entre sí: se sustituyen por tokens derivados de `scheme-ciep` (propuesta en `nl-estilo.md` §3; Ricardo corrige).

**(b) Doctrina de registro** incorporada como reglas 2–4 de `nl-estilo.md` §0 y aplicada arriba (tarjetas per cápita con banda, toggle `reg=pc|macro` persistente y común, denominador con procedencia y compuerta). Para `federacion-nl` el denominador es `pobNL[t]`/`pobNac[t]` de `master/Poblacion.dta` (misma corrida que `poblacion-nl.json`; el driver registra el sello y aborta si difiere); % PIBE con `pibeNnl[t]` de `actividad-nl.json` con su `tipo` por celda. Otros denominadores (contribuyentes, beneficiarios por fondo) **no** los provee hoy el canal para NL: no se usan.

**(c) Retrofit NL-0.4.1 de `actividad-nl`:** entra como vista principal nueva **PIBE per cápita NL vs. nacional** (patrón `pib_pc` del motor: nivel real per cápita en barras por tramo + variación anual punteada + `yline` del promedio; comparativo nacional atenuado), con el doble registro y los tokens fijos; `poblacion-nl` migra tokens (`--h/--m`). **Producto por trabajador NL (reporte, no se construye):** el canon ya tiene el patrón (`PIBDeflactor` §7.1, `outputPW*`: PIB real / población ocupada ENOE). Verificado hoy: los indicadores ENOE del BIE que usa el motor (`446562/446565/446566`) traen **solo el área 00** (nacional), así que `_NLbie` no puede filtrar NL de ellos; la población ocupada estatal existe en INEGI como "Indicadores estratégicos de ocupación y empleo por entidad federativa" (tabulados ENOE trimestrales, xlsx) y en la API de indicadores (geo 19), que hoy responde 401 con el token vigente; el legado `Subnacional.do` §2 la leía de un xlsx manual (`raw/ENOE/Población ocupada.xlsx`). Para construirla habría que (i) localizar el ID BIE de la serie estatal (si existe en el árbol 2025) o (ii) escribir un lector del tabulado ENOE por entidad con caché y checksum (patrón `_NLinpc`), y declarar el momento (promedio de 4 trimestres vs. PIBE anual) y la cobertura (15 años y más). Se recomienda **(ii) en NL-0.4.1 solo si el ID BIE no aparece**; queda como decisión.

**Arquitectura de ejecución (decisión necesaria).** El lado "recibe" es ligero (ZIP de 2.5 MB) y corre en cualquier máquina; el lado "paga" y las anclas dependen de cachés pesados del motor que **el runner Windows no tiene** (`LIF.dta` ← `DatosAbiertos.dta` ~500 MB de descarga; `PEF.dta` 1.7 GB tras importar 15 xlsx del sidecar; `statajson_entidad-nl.json` ← SIM.do completo). Opciones: **(A)** `FederacionNL.do` corre **solo en el Mac** (tras `SIM.do` + `EntidadNL.do`) y publica el endpoint; el runner solo refresca Población y Actividad (hoy ya es así). **(B)** El Mac escribe, en cada release, un **sello de corrida** commiteado `nl-assets/federacion-sello.json` (extracto del canal: `Part<X>nl*`, recaudación observada por impuesto y año de `LIF.dta`, anclas CP por `divFEDE`×entidad×año de `PEF.dta`, con versiones, `anioPE`, SHA-256 de cada fuente y `generado_en`); el driver acepta el sello solo si versión de capa, de motor y `anioPE` coinciden con la sesión (compuerta 5) y, cuando los cachés del motor existen (Mac), **recalcula y exige igualdad** con el sello; así el runner refresca mensualmente el lado "recibe" con EOFP fresco y re-publica. **(C)** El runner construye los cachés del motor (primera corrida de horas; `DatosAbiertos` 5 min al mes). **Recomendación: B** (mismo patrón que el CSV municipal commiteado con SHA; los números siguen saliendo del canal), con A como mínimo viable si se prefiere no commitear extractos.

**Hallazgo colateral (pre-existente, no se corrige aquí):** `windows/actualizar-nl.ps1` hace `robocopy /MIR` sobre `nodos\`: en la primera corrida del runner **borrará del Drive** `statajson_entidad-nl.json` y `entidad-nl.log` (que solo produce el Mac) y haría lo mismo con `federacion-nl.*` bajo la opción A. Hay que cambiar `/MIR` por copia sin borrado (o excluir los productos del Mac) en F2.

**Decisiones que se piden antes de F1:** (1) alcance del "paga": impuestos sin cuotas IMSS (renglón aparte) — ¿de acuerdo?; (2) arquitectura A/B/C; (3) deflactor para "reales": implícito del PIBE NL (coherente con % PIBE) o INPC NL; (4) año de referencia de las tarjetas: último año **completo con ambos lados observados** (hoy 2025) y el Paquete (2027) como vista adicional — ¿o el año de política como en los otros endpoints?; (5) `actualizar-nl.sh`/`.ps1`: incorporar `FederacionNL.do` (según 2) y sustituir `/MIR`; (6) **aprobación/corrección del borrador `nl-assets/nl-estilo.md`** (tokens §3: NL azul CIEP profundo vs. naranja CIEP; nacional gris atenuado; recibe jade / paga rojo institucional; oración-resumen bajo cada gráfica); (7) **Sankey como vista principal de la balanza** con la serie temporal como secundaria (evaluación arriba) — ¿de acuerdo?; (8) producto por trabajador NL en NL-0.4.1: solo si aparece el ID BIE estatal, o lector del tabulado ENOE.

### 0.6 Resoluciones (Ricardo, 2026-10-04) — vinculantes

| # | Decisión | Resolución |
|---|---|---|
| 1 | Alcance "paga" | **Aprobado**: sin OTROSK; cuotas IMSS en renglón aparte, no sumadas; la simetría (cuotas excluidas ↔ gasto IMSS excluido) se explica en el letrero de alcance. |
| 2 | Arquitectura | **B**: sello de corrida commiteado desde el Mac con validación de versión de capa, de motor y `anioPE` (aborta si incompatible). Razón adicional: C pondría derivados de la ENIGH en infraestructura de CoNL — frontera motor/producto. |
| 3 | Deflactor | **Implícito del PIBE NL** (coherencia con % PIBE y convención fiscal del motor); el INPC no se usa en flujos fiscales. |
| 4 | Año de referencia | **Último año completo observado** (2025); el Paquete 2027 como vista adicional etiquetada "año de política". |
| 5 | Runner | **Copia sin borrado** (`robocopy /E`) en lugar de `/MIR` sobre `nodos\`; el `rsync --delete` del Mac se queda (el Mac produce el conjunto completo). |
| 6 | `nl-estilo.md` | Ricardo lo corrige en el archivo esta semana; **los tokens de color NO se fijan** hasta su pasada. F1 no depende de ellos; F2 los deja **parametrizados** en `NLEstilo` (`nl-datos.js`) para aplicar su decisión sin retrabajo. |
| 7 | Sankey | **Aprobado** como vista principal; el nodo de saldo se etiqueta siempre **"aportación neta en flujos identificables"**, nunca sin el calificador. |
| 8 | Producto por trabajador | **Fuera de NL-0.4.1**, a la fila. |
| — | Defectos de `DatosAbiertos` del motor | **No se tocan desde esta rama**; issue documentado con evidencia en §5 para levantarlo en `master` por separado. |

### 1. Implementación F1 — `01_modulos/FederacionNL.do` v1.0.0 (commit `9c0e983`)

**Lectores de la capa** (`nl-assets/nl-fed.do` + `nl_fed.py`): `_NLeopf, fondos(lista) [offline]` baja los dos ZIP de Estadísticas Oportunas (vigente + histórico), filtra por **lista explícita** de 41 claves (`XAC28`+13 subfondos, `XAC33`+15, `XACCD`+3, `XACCR`, `XAC23`+3, `XACPSS`, `XACGF`) con entidad `00`–`33` exacta, convierte miles→pesos, exige base de registro "Pagado", resuelve el traslape histórico/vigente a favor del vigente, y escribe `raw/temp/EOPF/nl_transferencias.csv` (+ `_fondos.csv` con los nombres SHCP y `.meta` con `Last-Modified` de cada ZIP, periodo final, n, URL) con escritura atómica: un formato inesperado aborta y conserva el último caché bueno. `_NLjsonget/_NLjsonarr/_NLjsonesc` leen JSON del canal a `r()`/datos (Stata no parsea JSON); `_NLsha256` y `_NLfileinfo` dan huella y vintage. Verificado en vivo: 453,292 filas útiles, periodo final 2026-08, `Last-Modified` 30-sep-2026.

**Fórmulas (todo del canal):** `recibe[f,t]` = EOFP pagado NL por fondo y año (año en curso = acumulado al mes 8, tipo `parcial`); `ancla[d,t]` = `PEF.dta` por `divFEDE` × entidad (CP 2013–2025 ejercido, PEF 2026 aprobado, PPEF 2027 proyecto); `paga[x,t]` = `Part<x>nl` × recaudación observada de `LIF.dta` (filtro `divLIF != 10 | divCIEP == 8` de PerfilesSim §2, sin financiamiento) y `pagaLif[x,t]` = `Part<x>nl` × LIF/ILIF; `pagaS1/S3` sustituyen solo el ISR PM; `balanza[t]` = `nlTot − paga` cuando ambos lados son observados completos, `balanzaPaq[t]` = `anclaTot − pagaLif` para 2026 (PEF vs LIF) y 2027 (PPEF vs ILIF). Transformaciones por fila: `Pc` (÷ `pobNL` CONAPO), `R` (÷ `deflatornl` del sidecar, base 2027 = 1), `PIBE` (÷ `pibeNnl` × 100, desde 2003); nacional per cápita; **lugar de NL entre las 32** per cápita por fondo y año (población de las 32 del motor). `EntidadNL.do` v1.3.0 exporta aditivamente `Part<X>nl` (10), `RecImp{nac,nl}`, `RecImpnlS1-3`, `PartImpnl{,S1,S2,S3}` (+18 escalares; 1,777 en total).

**Compuertas (todas abortan; resultado de la corrida 2026-10-04):**

| # | Compuerta | Tolerancia | Resultado |
|---|---|---|---|
| 1 | Σ 32 entidades + No distribuible = total nacional, por fondo y año 2000–2026 | 1e-4 | **PASÓ**, reldif máx 1.17e-05 |
| 2 | Ancla CP: R28 EOFP = `PEF.dta`; R33; convenios+subsidios+salud informativo | 1e-3 / 0.025 / — | **PASÓ**: R28 1.1e-06; R33 0.0177 (2022: R25 y devengado vs pagado); conv. −12.1 % a −0.2 % (clasificaciones distintas) |
| 3 | Recaudación = la del motor; `Rec<X>nac` de EntidadNL = ILIF 2027 de `LIF.dta`, 10 impuestos | 1e-6 | **PASÓ** (requirió el mismo filtro sin financiamiento que PerfilesSim: OTROSK de LIF.dta incluye el endeudamiento) |
| 4 | `Part<X>nl` = `Rec<X>nl/Rec<X>nac` recalculado | 1e-9 | **PASÓ** |
| 5 | Vintage: EntidadNL (PE 2027, NL-0.4.0, v8.6.0), sidecars y sello = sesión; 5b sello = canal | igualdad / 1e-9 | **PASÓ**; negativos probados: sello NL-0.3.9 → aborta; sello con `part` ×1.001 → aborta ("difiere del canal en 1 elemento; re-corre con `nlfed_sellar 1`") |
| 6 | Rejillas: anual 2000–2026 seis agregados NL y nacional (0 solo donde el nacional es 0); mensual 24 meses | — | **PASÓ** |
| 7 | Total GF de SHCP = R28+R33+CD+CR+R23+PSS, nacional y NL | 1e-6 | **PASÓ**, reldif máx 1.0e-07 |
| 8 | Denominador: población 2027 de `master/Poblacion.dta` = `poblacion-nl.json` (NL 6,616,988; nacional 135,391,662); Σ 32 = nacional todos los años | 1e-9 | **PASÓ** |
| 9 | Log de procedencia activo | — | `users/ricardo/nodos/federacion-nl.log` |

**Sello de corrida** `01_modulos/nl-assets/federacion-sello.json` (`nl.federacion-sello/v1`, 38 KB, commiteado): identidad (capa NL-0.4.0, motor v8.6.0, PE 2027, `generado_en`, SHA-256 de `statajson_entidad-nl.json`, mtime y último mes de `LIF.dta`, mtime y años CP/PEF/PPEF de `PEF.dta`), `participaciones` (10 × part/S1/S2/S3/recNac/recNL), `recaudacion` (280 filas año × impuesto: mes, observado, LIF/ILIF), `anclas` (67 filas año × divFEDE: fuente, NL, nacional, no distribuible). **Modo sello probado** quitando temporalmente `statajson_entidad-nl.json`: 0 diferencias en `cifras` y en las 28 filas de `anual` respecto al modo canal.

**Cifras del canal (año de referencia 2025, observado; `federacion-nl.json`):**

| Concepto | mmdp | MXN por habitante | % PIBE NL |
|---|---:|---:|---:|
| Recibe (R28 71,752.7 · R33 35,834.8 · convenios 8,229.7 · R23+PSS 1,541.3) | **117,358.5** | **18,300** (nacional 20,239; lugar **27 de 32**; R28 lugar 6, R33 lugar 32) | 4.06 |
| Pagan los residentes, S0 (impuestos federales) | **496,192.8** [414,455.1, 595,042.6] | **77,371** [64,626, 92,785] (nacional 39,373) | 17.15 |
| Cuotas IMSS (aparte, no sumadas) | 59,277.7 | 9,243 | — |
| **Aportación neta en flujos identificables, S0** | **−378,834.3** [−477,684.2, −297,096.6] | **−59,072** [−74,485, −46,326] | **−13.09** [−16.51, −10.27] |
| Participación de NL | recibe 4.35 % del gasto federalizado · paga 9.45 % de los impuestos federales | | |
| Año de política 2027 (PPEF por entidad vs ILIF) | recibe 129,288.5 · paga 577,411.9 [484,063.7, 690,302.9] · neto −448,123.4 | −67,723 por habitante | −13.53 |

### 2. Implementación F2 — `nl-assets/federacion-nl.html` (commit `f406f45`)

Un archivo, inline, cero `http(s)://`, **412 KB**; `NLDatos.load` + compuerta de publicación; estado por URL **común a los endpoints**: `#vista=balanza|recibe|paga&reg=pc|macro&medida=nominal|real|pibe&esc=S0|S1|S3&anio=&ini=&fin=&cmp=&modo=`. Letrero de alcance permanente bajo el encabezado (incluye la simetría de las cuotas y el supuesto de incidencia fija). Tarjetas en persona-escala (titular per cápita con banda y escenario, subtítulo macro mmdp y % PIBE, tercera línea nacional per cápita / lugar de 32 / participación), con etiqueta "en curso" (2026) o "año de política" (2027). Vistas con su patrón declarado (comentarios `PATRÓN` en la plantilla y `presentacion.patrones` en el JSON): **Sankey** de 3 columnas (impuestos → Federación → fondos + "aportación neta en flujos identificables"; la columna izquierda **reserva el espacio de S3** para el ISR PM y el halo punteado marca [S1, S3]; cuotas IMSS como flujo aparte punteado; por habitante o mmdp sin cambiar anchos); **serie de la aportación neta** (barra S0, franja [S1, S3], tramos observado / Paquete / en curso con `xline`, oración-resumen generada desde el canal); **recibe por fondo** (apilado de mayor a menor dentro de cada año, línea nacional per cápita, tabla de subfondos con lugar); **paga** (tabla de conciliación `(+)/(=)/(·)` con participaciones y banda; apilado por impuesto con banda del total). Modo datos con encabezado de procedencia (fuentes con `Last-Modified`/vintage/SHA, alcance, supuesto, registro, escenario, filtros). **Autocomprobación: 16 cifras** del canal = recálculo (Σ fondos, Σ impuestos, balanza = recibe − paga en S0/S1/S3, per cápita, % PIBE, participación, S1 ≤ S0 ≤ S3, `Part` = rec/rec, Σ entradas = Σ salidas del Sankey, PPEF − ILIF). Tokens de color **solo** desde `NLEstilo` (`nl-datos.js`), provisionales hasta la pasada de estilo.

**Actualizadores:** `actualizar-nl.do` corre los tres drivers ("LOS TRES DRIVERS TERMINARON"); `actualizar-nl.sh` exige `FederacionNL: listo`, 6 productos, y registra en la bitácora modo/EOFP/sello; `publicar-conl.sh` publica `federacion-nl.html` (compuerta de publicación incluida); `windows/actualizar-nl.ps1` incorpora el driver (modo sello), el tercer HTML y **`robocopy /E` sin borrado** (parser PowerShell 7.4: 0 errores en ambos `.ps1`); `verificar-runner.ps1` comprueba los archivos nuevos del clon; README actualizado.

### 3. Evidencia de entrega (2026-10-04)

`./actualizar-nl.sh` con descargas frescas (INEGI + SHCP): "Stata OK: compuertas en verde, 6 productos generados"; bitácora `2026-10-04T22:04:26 capa=NL-0.4.0 | … | fed: modo canal; EOFP hasta 2026-08 (Last-Modified Wed, 30 Sep 2026 21:06:24 GMT); ref 2025; sello 4-Oct-2026T21:51:43 | sha256(12): … federacion-nl.html=c5074ebf0f19 nodos/federacion-nl.json=bb04a825c544`. Compuerta de publicación: `federacion-nl.html (347543 bytes de JSON, corrida 4-Oct-2026T22:04:24, capa NL-0.4.0)`. **Desde el Drive** (`/My Drive/2. Simuladores CoNL/SimuladorCoNL/federacion-nl.html`, también en `nodos/`): SHA-256 `c5074ebf0f19aca2…` idéntico al local; render con Chrome headless abriendo el archivo del Drive, sin red: encabezado "Simulador Fiscal NL — La Federación y Nuevo León · construido sobre el Simulador Fiscal CIEP v8.6.0 · capa NL-0.4.0 · año de referencia 2025 · Paquete 2027"; tarjetas 18,300 / 77,371 S0 [64,626, 92,785] / −59,072 S0 [−74,485, −46,326] MXN por habitante; pie con fuentes, compuertas, supuestos y **autocomprobación en verde (16 cifras)**; vistas recibe (macro % PIBE, 2024), paga (pc, S3, 2027) y balanza (2026, tabla) verificadas por DOM. El Drive conserva `statajson_entidad-nl.json` y `entidad-nl.log` del Mac.

### 4. Paridad y frontera

`SIM.do` + `EntidadNL.do` v1.3.0 re-corridos en batch (receta del runbook, PE 2027): `users/ricardo/output.txt` SHA-256 `ae624b98…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`), **idéntico** al de la paridad de v8.6.0; compuerta D.1 **PASÓ**. `git diff --name-only origin/master HEAD` = solo capa NL (ningún archivo del motor). Registro de escalares solo-aditivo.

### 5. Issue para `master` (no se toca desde esta rama): `UpdateDatosAbiertos` y las transferencias por entidad

Evidencia (Stata sobre `master/DatosAbiertos.dta` del 22-sep-2026 vs CSV fresco de SHCP del 30-sep-2026): (a) `DatosAbiertos.ado` §4.7 **apendiza** una clave derivada `XACGF00` (= `XAC2800 + XAC3300`, nombre "Gasto Federalizado") que coexiste con la clave homónima de SHCP ("Total: Total Gasto Federalizado") → `duplicates report anio mes if clave == "XACGF00"`: 355 pares duplicados; el total nacional queda ~2× (2024: 4.88 vs 2.59 billones) y además omite convenios/R23/PSS en su definición; (b) en **2011** las filas nacionales de varios subfondos no cuadran con la suma por entidad (R28 −6.93 %, FAIS −46.9 %, FAM −30.0/−53.1 %, FAFEF −40.5 %, FAETA −11.7 %), mientras el CSV fresco cuadra a 5e-9 en 2011: artefacto de la costura `_hist`/vigente (probablemente filas 2011 en ambos archivos con `nombre` distinto que el `collapse (mean) … by(nombre clave)` no agrupa). Propuesta para `master` (PR aparte): renombrar la clave derivada (p. ej. `XACGF_R2833`) o eliminarla, y deduplicar la costura por `(anio, mes, clave)` con prioridad al archivo vigente. Ningún producto de la capa depende hoy de ese caché.

---

## Anexo Identidad CoNL — fuente usada y aproximaciones (2026-10-05, capa NL-0.4.1)

**Fuente de identidad.** Mixta, por autoridad: (1) **BrandBook 2020** (Algoritmo Design; `Shared drives/Revisión Plan Estratégico 2019-2021/Materiales para diseño/Identidad Consejo Nuevo León/`, dejado por Ricardo) para logotipo vectorial (`consejonl_logotipo.ai`), zona de respeto (½ del logotipo), aplicación en blanco, usos incorrectos y RGB de la paleta primaria; (2) **conl.mx** (tema `conl`, 2025) para los hex canónicos y variantes WCAG (`--cn-*`), tipografía vigente (Poppins/Inter autoalojadas) y acento (`.btn-morado`: morado + borde aqua); (3) **PE 2040** (2024) como verificación: misma paleta y mismas fuentes embebidas. El **BrandBook 2023** del repositorio de Comunicación existe (`6.Comunicación/Manual de identidad/LOGOS CONL/2023_CNL_BrandBook (1).pdf`, Drive id `1T3EhKASNhDbR3KNRpJf1FmWOpznQBJ5q`) pero no es legible desde esta máquina (stubs `.gdrive`; los enlaces compartidos exigen sesión).

**Aproximaciones declaradas (para cuando CoNL entregue el manual vigente):** tipografía — el manual 2020 pide Basis Grotesque Pro Light (comercial, no embebible) y Public Sans Light; se usa Poppins/Inter porque es lo que CoNL publica hoy (sitio y PE 2040) y es OFL; azul — el sitio (`#0a6db6`) difiere del manual 2020 (`#2C70B9`), se usa el del sitio; los hex impresos del manual 2020 (#F5BC43/#4FADAF/#4D1B45) son conversiones CMYK que no coinciden con su propio RGB, se tomó el RGB. Detalle y evidencia: `nl-assets/nl-estilo.md` §6.

**Cero red y peso.** Fuentes y logo embebidos (`nl-estilo-assets.js`, 105 KB con 100 KB de data: URI); el único `http` de cada HTML es el enlace a GitHub. Pesos publicados: `poblacion-nl.html` 896 KB, `actividad-nl.html` 294 KB, `federacion-nl.html` 523 KB (< 2 MB).

---

## Anexo Participaciones históricas — F0: factibilidad por vintage ENIGH 2016–2024 (2026-10-05; propuesta NL-0.5.0; **PENDIENTE DE APROBACIÓN — F1 no inicia sin ella**)

**Objeto.** Sustituir el supuesto "participaciones constantes (ENIGH 2024, PE 2027)" del lado *paga* de `FederacionNL` por participaciones `Part<X>nl` estimadas con cada ENIGH bienal (2016, 2018, 2020, 2022, 2024), cada una **nacida de la economía de su año**. Decisiones heredadas del prompt que **no se reabren**: serie desde 2016 (la ENIGH 2014 queda fuera por el cambio de diseño 2016); asignación **escalonada sin interpolación** (2016→2016–17, 2018→2018–19, 2020→2020–21, 2022→2022–23, 2024→2024 en adelante; años < 2016 = ENIGH 2016 con `metodo: extrapolado`; con ENIGH propia `metodo: bienal`); 2020 se usa tal cual con sello pandémico declarado; la banda S1–S3 del ISR PM se recalcula por vintage. **Motor intacto**: en F0 ningún archivo del motor cambió en el worktree (`git status`: solo el driver nuevo de la capa). Evidencia de esta F0 en `users/ricardo/vintages/` (logs `run-v<anio>*.log`, `muestra-nl-<anio>.log`, `isrpm-diag*.log`, `extract.py`; gitignored) y en `users/ricardo-v<anio>/nodos/statajson_entidad-nl.json` (uno por vintage).

### 0.1 Mecanismo del motor para correr otra ENIGH (F0.1)

**Cómo elige el motor la ENIGH.** `SIM.do` §0.2 fija `scalar anioenigh = 2024` y pasa `anioPE` como argumento a `Expenditure.do`, `Households.do` y `PerfilesSim.do`; los tres (y `GastoPC.ado`, `TasasEfectivasMicro.ado`, `Perfiles.ado`) traen el **mismo mapeo** `anioPE → anioenigh` (≥2024→2024, 2022–23→2022, 2020–21→2020, 2018–19→2018, 2016–17→2016, 2013–15→2014). `Expenditure.do` descarga el ZIP de la ENIGH del vintage con `ensure_asset` (manifest v8.6.0: `2016.zip` 175 MB, `2018.zip` 164 MB, `2020.zip` 155 MB, `2022.zip` 180 MB; **los cuatro siguen en el Release v8.6.0** — HEAD 200, tamaños iguales al manifest; descargados hoy y **SHA-256 verificados** contra el manifest) y construye las cachés por vintage en `master/<anioenigh>/` (`expenditures`, `consumption_categ_*`, `categ_iva`, `deducciones`, `households.dta`, probits `formal_*.ster`; 2.7–3.3 GB por vintage) y `master/perfiles<anioPE>.dta` (100–125 MB). Las cachés 2016–2022 **no existían** en ninguna copia local (worktree NL, Dropbox master): había que construirlas.

**Lo que el motor NO permite tal cual (por eso existe el driver de la capa):** `SIM.do` hardcodea el año de política (2027) y, sobre todo, los **parámetros del Paquete** §4.1 (`escalar pctpib ISRASPIB = 3.855`, …) y §5.1 (gasto), que son del PE 2027. Si se corre `SIM.do` con otro `anioPE`, esos parámetros seguirían siendo los de 2027. El propio motor tiene el default correcto cuando **no** existen esos escalares: `TasasEfectivas.ado` §2 "sin parámetros de escenario el default es lo observado en LIF `anio`" y `GastoPC.ado` (`capture confirm scalar …` → PEF del año). De ahí el driver **`01_modulos/nl-assets/nl-vintage.do` v0.1.0** (capa NL, nuevo): espejo de `SIM.do` §0–§4.7, §5 (PEF + GastoPC) y §7 con `anioPE = aniovp = anioenigh = <vintage>`, **omitiendo** §4.1 y §5.1 (con guarda: aborta si algún `<X>PIB` ya existe en la sesión), §4.2/§4.6 (tarifa ISR/IEPST: `Households.do`/`Expenditure.do` definen las suyas por vintage), §6 SHRFSP y §8 FiscalGap/Sankey (no alimentan la incidencia); conserva `PM` e `IVAT` (los lee `EntidadNL.do`); `$id = <usuario>-v<vintage>` aísla `users/` (ingresos, gastos, aportaciones, bootstraps, `nodos/statajson_entidad-nl.json`) sin tocar `users/ricardo/` ni `perfiles2027.dta`; después corre `EntidadNL.do` en la misma sesión (compuerta D.1 incluida). Uso: `do 01_modulos/nl-assets/nl-vintage.do 2016` desde la raíz del worktree.

**Costo medido (Mac, Stata 17 MP; corridas en paralelo de 2–3 vintages):** construcción de cachés ≈ 10–13 min por vintage (Expenditure 2016: 599 s incl. descarga; Households 140 s), PerfilesSim ≈ 2 min, GastoPC ≈ 4 min, EntidadNL ≈ 3 min. Total primera vez: 2016 **1,147 s**, 2018 **1,251 s**, 2020 **1,355 s**, 2022 **1,268 s**; con cachés ya construidas (2024): **651 s**. Las cachés de los cinco vintages ya están construidas en el worktree (+12 GB en `master/`; disco con 133 GB libres). **Plan de corridas F1:** cinco corridas definitivas secuenciales ≈ **55 min** (≈ 11 min cada una) + `FederacionNL` 3 min: cabe en una sesión diurna; no hace falta batch nocturno. Se propone un wrapper `nl-vintages.sh` (Mac) que corra las cinco, construya el sello (§0.6) y deje bitácora.

### 0.2 Calibración contemporánea: mecanismo exacto (F0.2)

Con `anioPE = aniovp = anioenigh = t`, **cada pieza se calibra al año t** sin tocar el motor:

| Pieza | Dónde | Año que usa | Verificado en la corrida |
|---|---|---|---|
| Armonización ingresos (Altimir/TT, cut-offs probit, tarifa ISR, UDIS, UMA, subsidio al empleo) | `Households.do` | SCN *t*, LIF *t* (`ISRMorales`, `ISRSalarios`, `ISRFisicas` del año → cut-offs), PEF *t*; tarifa ISR/SE por bloque de vintage (líneas 233–314), UDIS/UMA/subsidio por vintage (19–78), matrices CSS propias | sí (bloques `anioenigh` 2016/2018/2020/2022 ejecutados) |
| Armonización consumo (IVA/IEPS por categoría) | `Expenditure.do` | SCN *t*, LIF *t* por producto, Población *t*; `IVAT`/`IEPST` propias | sí |
| Reescalado a macros | `PerfilesSim.do` | PEF *t*, LIF *t* observada (`monto`, mes 12), Poblaciontot *t*, SCN *t* → `perfiles<t>.dta` | sí |
| Parámetros `<X>PIB` | `TasasEfectivas.ado` §2 (sin escalares) | **LIF *t* observada** (p. ej. 2016: ISR salarios 3.085 % PIB = 640,366.9 mdp) → `ingresos.dta` | sí |
| Gasto per cápita | `GastoPC.ado` (sin escalares §5.1) | PEF *t* | sí |
| `pibY`, deflactor | `PIBDeflactor` con `aniovp = t` | PIB *t*; deflactor(*t*) = 1 | sí |
| TE micro y `Rec<X>` | `TasasEfectivasMicro.ado` | `perfiles<t>.dta` + SCN *t* | sí |
| Banda S1/S2/S3 | `EntidadNL.do` §2.1b | `prob_moral` del probit del vintage; `PM[1,1]` = 30 % (tasa vigente en 2016–2024) | sí |

**Compuerta de calibración (equivalente a la compuerta 3 de FederacionNL, por vintage):** `Rec<X>nac` de cada corrida = recaudación observada de `LIF.dta` del año (mes 12, filtro sin financiamiento): ISR salarios 2016 640,366.9 / 2018 760,363.8 / 2020 828,672.7 / 2022 1,015,668.3 / 2024 1,253,784.5 mdp — **idénticos** a `LIF.dta` (verificado al peso en 2016 y 2022; en F1 se vuelve compuerta formal, tolerancia 1e-6, 10 impuestos × 5 vintages). IEPS petrolero 2022 **negativo** (−79,162 mdp): el paga de ese renglón es negativo ese año, se declara, no se trunca (criterio ya vigente).

**Hallazgo (propiedad del canal): `Part<X>nl` depende del vintage ENIGH, no del año de política.** El reescalado del motor es proporcional (`Distribucion … macro()` multiplica toda la variable por un factor; el único paso no proporcional es el redondeo entero del `factor` tras el ajuste poblacional de `PerfilesSim` §3), de modo que `Rec<X>nl/Rec<X>nac` solo cambia con la encuesta. **Prueba:** ENIGH 2024 con PE 2024 (esta F0) vs PE 2027 (corrida vigente): ISR salarios 8.8183 vs 8.8174; IVA 6.4622 vs 6.4612; ISR PM 14.2210 vs 14.2241; cuotas 9.8296 vs 9.8284 (reldif ≤ 2e-4). La calibración contemporánea sí determina los **niveles** (`Rec<X>nac` = recaudación del año), las TE y la incidencia; las participaciones son robustas al año de política. Consecuencia para F1: la fila 2024+ puede alimentarse de la corrida vintage 2024 (uniformidad del mecanismo) y ligarse a la corrida vigente con una compuerta `reldif ≤ 1e-3`.

### 0.3 Muestra de NL por vintage (F0.3) — `master/<t>/households.dta` post-ajuste, `entidad = substr(folioviv,1,2)`

| Vintage | Hogares NL (muestra) | Hogares NL (exp.) | Personas NL (muestra) | Personas NL (exp.) | Hogares nac. | Mín. hogares NL por decil **nacional** | Mín. por decil **estatal** |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2016 | **2,984** | 1,405,532 | 10,558 | 5,190,277 | 70,311 | **166** (decil I) | 212 |
| 2018 | **3,043** | 1,497,190 | 10,455 | 5,331,583 | 74,647 | **181** (I) | 244 |
| 2020 | **3,502** | 1,708,867 | 12,003 | 5,870,363 | 89,006 | **223** (I) | 266 |
| 2022 | **3,612** | 1,828,822 | 12,036 | 6,078,708 | 90,102 | **219** (I) | 264 |
| 2024 | **3,796** | 1,859,166 | 12,586 | 6,136,446 | 91,414 | **338** (VIII) | 273 |

Todos los vintages cumplen el umbral de referencia (≥ 100 hogares NL por decil nacional) con holgura; el decil I nacional es el más delgado en 2016–2022 (166–223 hogares, sesgo esperado de NL hacia deciles altos: 60–63 % expandido en VI–X). Nada que decidir aquí: deciles nacionales y estatales son utilizables en los cinco. **Pero el tamaño de muestra no es el problema** (ver §0.5-B): la estadística crítica del lado *paga* no es la de deciles sino la del ISR PM, sostenida por unas pocas observaciones.

### 0.4 Compuerta D.1 por vintage (F0.4)

`EntidadNL.do` §2.2 (driver sin `entidad()` sobre `AportacionesNetas` vs escalares `INCD*` del pipeline, tolerancia 1e-6 en `xhogar`, distribución e incidencia, 11 filas): **PASÓ en los cinco vintages** (2016, 2018, 2020, 2022, 2024), es decir, la capa NL no distorsiona la incidencia nacional del motor en vintages que nunca había pisado. Nacional, incidencia total (`incImpAportnacTot`): 17.39 (2016), 16.91 (2018), 19.08 (2020), 17.69 (2022), 20.06 (2024; 21.47 con PE 2027).

### 0.5 Sorpresas y bloqueos — **aquí se FRENA**

**A. Bug del motor que bloquea 2016, 2018 y 2020 (FRENA: toca el motor).** `PIBDeflactor.ado` §2.1 detecta el "último trimestre observado" buscando la primera fila con `pibQ` faltante **dentro del rango `anio <= aniomax`**, y `aniomax` por default es `aniovp + 5`. Si `aniovp + 5` cae **antes** del último trimestre publicado (hoy 2026q2), ninguna fila tiene `pibQ` faltante, `aniofinal`/`obsfinal` quedan sin definir y la rutina truena con `pibQ not found` (`r(111)`). `SCN.ado` llama `PIBDeflactor, anio(`anio')` sin `aniomax` y `Households.do` `PIBDeflactor, aniovp(anioenigh)`, así que **`SCN, anio(2016|2018|2020)` y la construcción de `households.dta` de esos vintages fallan en el motor v8.6.0 tal cual**; 2022 (2027 > 2026) y 2024 pasan. Es un caso borde nunca ejercitado (el nacional siempre corre con `aniovp ≥ 2024`). **Reproducido** en el worktree (log `run-v2016` primera corrida: `SCN 2016 → pibQ not found`). **Propuesta de corrección mínima para `master` (PR aparte; no se toca desde esta rama):** tras el bucle de §2.1, `if "`obsfinal'" == "" { local aniofinal = anio[_N]; local trim_last = trimestre[_N]; scalar trimlast = trimestre[_N]; local obsfinal = _N }` (4 líneas); **no cambia ningún número de producción**: para `aniovp ≥ 2024` el bucle sí define `obsfinal` y el bloque nuevo no se ejecuta (paridad por construcción; el PR lo demostraría con `output.txt` byte-idéntico). **Cómo se obtuvo la evidencia de esta F0 sin tocar el motor:** árbol *scratch* `~/CIEP_Simuladores/_vintage-f0/` (`git archive HEAD` + `raw/` y `master/` por symlink al worktree) con ese parche aplicado **solo ahí**, marcado `[DIAGNÓSTICO NL-0.5.0 F0]`; los vintages 2016/2018/2020 corrieron en el scratch y 2022/2024 en el worktree sin parche. Las cachés `master/2016|2018|2020` quedaron construidas con el parche; el parche no afecta el año del vintage (deflactor(*t*) = 1, PIB *t* observado) pero, para que F1 no dependa del scratch, **F1 requiere decidir**: (a) PR a `master` + release + merge a la capa (limpio; la capa sincroniza en cada release etiquetado), o (b) correr F1 desde el scratch parcheado y declararlo en el sello (más rápido; deja a NL-0.5.0 dependiendo de un parche no versionado — **no recomendado**). **Recomendación: (a)**, y rehacer las cachés 2016/2018/2020 con el motor corregido (≈ 35 min) para que el sello cite un motor etiquetado.

**B. El ISR PM de NL lo sostiene UNA observación de la ENIGH — en todos los vintages (decisión requerida).** Participaciones estimadas (S0 = método vigente; banda [S1, S3]) y su concentración:

| Vintage | Part ISR PM S0 (%) | S1 | S3 | Personas NL con `ISRPM_Sim > 0` (muestra) | **Top-1 NL como % del ISR PM de NL** | Part S0 **sin la persona top-1 de NL** | Top-1 NL en `ing_bruto_tpm` NL | Top-1 nacional |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| 2016 | **41.64** | 18.35 | 19.40 | 218 | **96.0 %** | **2.77 %** | 85.6 % | **es de NL**: factor 1,074, `ing_bruto_tpm` 738.3 mdp/año, ISR PM simulado 276.7 mdp → **40.0 % del ISR PM nacional** |
| 2018 | 7.89 | 4.37 | 8.85 | 324 | 22.7 % | 6.21 % | 15.4 % | CDMX, 2.9 % |
| 2020 | 10.01 | 5.44 | 10.44 | 532 | 37.9 % | 6.47 % | 28.0 % | es de NL, 3.8 % |
| 2022 | 4.64 | 3.18 | 5.43 | 533 | 9.4 % | 4.22 % | 6.4 % | Chihuahua, 1.4 % |
| 2024 | 14.22 | 8.64 | 20.90 | 481 | 48.1 % | 7.92 % | 37.2 % | es de NL, 6.8 % |

Contraste: el top-1 de NL pesa 1.5–5.8 % del ISR salarios de NL y 0.4–1.4 % del IVA de NL. Lectura: la participación de NL en el ISR PM **no es estimable con precisión desde la ENIGH** en ningún vintage (incluida la vigente: la mitad del 14.22 % publicado es una persona); la banda S1–S3 **no lo cubre** porque S1 y S3 también se reparten sobre `ing_bruto_tpm`, dominado por la misma observación (2016: S1 18.3 %, S3 19.4 % y S0 41.6 %, todos fuera de cualquier rango plausible para una entidad con 7.9 % del PIBE). La regla del prompt ("un salto grande no se corrige, se documenta") aplica a saltos entre bienios, pero aquí el salto 41.6 → 7.9 → 10.0 → 4.6 → 14.2 **es ruido muestral de una observación**, y la regla de extrapolación llevaría el 41.6 % de 2016 a los 16 años 2000–2015 (paga ISR PM de NL ≈ 40 % del nacional durante toda la retropolación). Opciones, **ninguna decidida**: (1) publicar la serie tal cual con banda y un **sello de sensibilidad muestral** por vintage (nuevo escalar declarado `concTop1ISRPMnl` y texto "una observación aporta el x % del ISR PM de NL"), aceptando que la serie histórica del ISR PM y el paga de 2000–2017 lleven ese letrero; (2) **excluir el ISR PM (y OTROSK, que hereda su reparto) de la serie histórica**: en la vista nueva mostrar solo ISR salarios, ISR PF, IVA, IEPS y cuotas por vintage, y para el paga anual tratar el ISR PM con **un solo vintage declarado** (p. ej. la ENIGH 2024 vigente, `metodo: constante`) o con la **mediana de los cinco vintages** como estimador declarado; (3) añadir en la capa un **escenario de robustez declarado** "S0 sin la observación top-1 nacional de capital" (no modifica el motor; es un estimador más, como S1–S3) y publicar la banda ampliada. Recomendación técnica: **(2) para la serie visible + (1) como declaración en procedencia**; (3) solo si se quiere conservar una serie del ISR PM. Nota: la ENIGH es representativa por entidad en ingresos corrientes, no en la cola de ingresos de capital; esto no es defecto del motor ni de la capa, es la encuesta.

**C. Saltos entre bienios en los impuestos "estables" (se documentan, no se corrigen):**

| Impuesto | 2016 | 2018 | 2020 | 2022 | 2024 | Salto máx. entre bienios (pp) |
|---|---:|---:|---:|---:|---:|---:|
| ISR salarios | 7.39 | 7.08 | 8.82 | 8.67 | 8.82 | +1.75 (2018→2020) |
| ISR personas físicas | 6.23 | 6.27 | 6.82 | **12.99** | 6.10 | +6.17 / −6.89 (2022: revisar concentración en F1) |
| Cuotas IMSS | 9.31 | 8.79 | 9.51 | 9.93 | 9.83 | +0.72 |
| IVA | 5.77 | 6.30 | 6.78 | 6.72 | 6.46 | +0.53 |
| IEPS no petrolero | 8.11 | 9.98 | 8.35 | 9.30 | 12.01 | +2.71 (2022→2024) |
| IEPS petrolero = ISAN | 9.45 | 9.03 | 6.13 | 10.35 | 6.48 | +4.23 / −3.88 |
| Importaciones | 5.44 | 5.89 | 6.02 | 6.28 | 6.26 | +0.45 |
| Impuestos sin OTROSK ni cuotas, S0 [S1, S3] | 16.59 [10.15, 10.44] | 7.32 [6.31, 7.59] | 8.18 [6.93, 8.29] | 6.74 [6.27, 7.00] | 9.46 [7.92, 11.31] | — |

ISR salarios, cuotas, IVA e importaciones son series coherentes con el peso económico de NL (NL = 4.2–4.7 % de la población ENIGH expandida; PIBE ≈ 7.9 %). El ISR PF 2022 (13.0 %) y el IEPS petrolero/ISAN (6.1–10.4 %) merecen la misma métrica de concentración en F1 antes de publicarse. Observación para el motor (no bloquea): `PartIEPSP = PartISAN` en los cinco vintages y en producción, porque ambos se reparten sobre la misma base vehicular (`gas_pc_Vehi`); se declara.

**D. Nits resueltos en la capa (sin tocar el motor):** (i) `Expenditure.do` hace `cd "${SIMROOT}/raw/ENIGH/"` antes de `ensure_asset`; en una sesión que carga los `.ado` desde "." (SITE = Stata, como en este Mac) el `cd` deja de ver el motor → `command ensure_asset is unrecognized`. El driver hace `adopath ++ "${SIMROOT}"` (misma solución que `05_scripts/test-simulador-dorado.do`). En instalaciones con `sysprofile.do` (SITE = clon) no ocurre. (ii) Un `/*` dentro de un comentario del driver convertía el archivo entero en comentario (corregido). (iii) `python set exec` no es necesario: el `python_exec` permanente ya es `/usr/bin/python3`.

**E. Pendientes para F1/F2 detectados (aditivos):** `EntidadNL.do` trae "ENIGH 2024" literal en tres textos (`momento_de_registro`, `fuente poblacion`, `den_iepsnp_nota`) → usar `scalar(anioenigh)`; `federacion-nl.html` tiene la autocomprobación `participacionesAnual[ref].ISRPM = corrida` y la nota `notaPart` ("corrida PE 2027 aplicada a…") escritas para el caso constante → en F2 pasan a "= vintage asignado al año"; `FederacionNL.do` §4.2 multiplica `part × observado` con una sola `PART` → en F1 usa la participación del vintage asignado a cada año (el HTML ya compara `anual[].paga*` contra `byPA[anio] × recNac`, así que ambos deben cambiar juntos).

### 0.6 Diseño F1/F2 (para aprobación; nada implementado salvo el driver de F0)

- **Sello de vintages commiteado** `01_modulos/nl-assets/participaciones-vintages.json` (`nl.participaciones-vintages/v1`, arquitectura B como `federacion-sello.json`): `identidad` (capa, motor etiquetado, `generado_en`), `asignacion` (regla escalonada declarada: `{"<2016": 2016 extrapolado, 2016: 2016, …, ">=2024": 2024}`), `vintages[]` = {`enigh`, `anioPE`, `aniovp`, `statajson_sha256`, `generado_en`, `muestra` {hogNL, perNL, minDecilNac, minDecilEst}, `d1: "PASÓ"`, `participaciones` (13: 10 impuestos + ISRPM S1/S2/S3), `recNac`/`recNL` (10), `concentracion` {`top1ISRPM`, `top1Kpriv`}, `sello` ("pandémica: levantamiento ago–nov 2020; posibles atipicidades" en 2020)}. Lo escribe un agregador `nl-assets/nl-vintages-sello.do` desde los cinco `users/<usuario>-v<t>/nodos/statajson_entidad-nl.json` (Mac); el runner lo consume.
- **`FederacionNL.do` v1.2.0:** lee el sello de vintages (modo canal: lo verifica contra los JSON de vintage si existen, reldif 1e-9; modo sello: lo exige con misma capa/motor); `participacionesAnual` = una fila por año con `enigh`, `metodo` (`bienal`/`extrapolado`) y las 13 participaciones del vintage asignado; `paga[x,t]` usa esa participación; `participaciones` (corrida vigente) se conserva para las cifras del año de política y para la compuerta 3 actual; `identidad.enigh` del sello pasa a lista de vintages con SHA. **Compuertas nuevas (abortan salvo la informativa):** (10) `Rec<X>nac` de cada vintage = `LIF.dta` observada del año, 1e-6; (11) `Part = Rec/Rec` por vintage, 1e-9; (12) vintage 2024 vs corrida vigente, reldif ≤ 1e-3 (ligadura); (13) D.1 = PASÓ registrado por vintage; (14) **saltos entre bienios reportados** en procedencia (informativo) con la métrica de concentración top-1 por impuesto y vintage.
- **F2:** Sankey y conciliación con el vintage del año (nota "ENIGH <vintage>, método <bienal|extrapolado>"; sello pandémico en 2020; extractos con el vintage en el encabezado); vista secundaria **"La carga federal de NL a través del tiempo"** (serie 2016–2024 por impuesto, patrón de serie del canon, persona-escala por defecto) con el alcance del ISR PM según la decisión B; autocomprobaciones ajustadas (§0.5-E); `nl-vintages.sh`; changelog NL-0.5.0; publicación y verificación desde el Drive.

### 0.7 Decisiones que se piden antes de F1

| # | Decisión | Opciones | Recomendación |
|---|---|---|---|
| 1 | Bug `PIBDeflactor` (bloquea 2016/2018/2020) | (a) PR a `master` + release + merge a la capa; (b) F1 desde el scratch parcheado | **(a)**; mientras, la capa queda en F0 |
| 2 | ISR PM dominado por una observación | (1) publicar con sello de sensibilidad; (2) excluirlo de la serie histórica y tratarlo con un vintage declarado o mediana; (3) escenario de robustez "sin top-1" | **(2) + (1) en procedencia**; (3) opcional |
| 3 | Fila 2024+ de `participacionesAnual` | corrida vintage 2024 (PE 2024) con ligadura a la vigente; o corrida vigente PE 2027 | **vintage 2024** (mecanismo uniforme; diferencia ≤ 2e-4) |
| 4 | Extrapolación 2000–2015 con ENIGH 2016 | tal cual (decisión heredada) — pero véase B: para el ISR PM significaría 41.6 % durante 16 años salvo decisión 2 | mantener para los impuestos estables; ISR PM según decisión 2 |
| 5 | Métrica de concentración como escalar declarado (`concTop1<X>nl`) para los 10 impuestos | sí / no | **sí** (aditivo; alimenta la compuerta informativa 14 y el letrero) |

*F1 no inicia hasta la resolución de 1 y 2.*

### 0.8 Resoluciones (Ricardo, 2026-10-05) — vinculantes; F0 APROBADO con ellas

| # | Decisión | Resolución |
|---|---|---|
| 1 | Bug `PIBDeflactor` | **PR a `master` + release + merge a la capa.** Las cachés 2016/2018/2020 se rehacen con el motor etiquetado antes de las corridas definitivas. |
| 2 | ISR PM dominado por una observación | **Publicar tal cual con sello de sensibilidad muestral**: serie del ISR PM por vintage con banda, escalar declarado de concentración por impuesto y vintage (`concTop1<X>nl`: "una observación aporta el x % del impuesto de NL"), letrero visible en la vista y en procedencia; 2000–2017 heredan el 41.6 % de 2016 con el letrero. No se suaviza, no se excluye, no se corrige. |
| 3 | Fila 2024+ | **Corrida vintage 2024 (PE 2024)** con compuerta de ligadura contra la corrida vigente (reldif ≤ 1e-3). |
| 4 | Extrapolación 2000–2015 con ENIGH 2016 | Tal cual (decisión heredada), con el sello de la resolución 2. |
| 5 | `concTop1<X>nl` como escalar declarado | **Sí** (aditivo en `EntidadNL.do`; alimenta la compuerta informativa de saltos y el letrero). |

### 1. Implementación F1 (commits `b727a0b`, `8858ad3`; motor intacto)

- **`01_modulos/nl-assets/nl-vintage.do` v1.0.0** — espejo de `SIM.do` con `anioPE = aniovp = anioenigh = <vintage>`, sin §4.1/§5.1 (guarda: aborta si algún `<X>PIB` ya existe), sin §6/§8; `adopath ++ ${SIMROOT}` (el `cd` de `Expenditure.do` deja de ver los `.ado` cuando SITE no es el clon: misma receta del runbook); `$id = <usuario>-v<vintage>`; `EntidadNL.do` en la misma sesión. **Modo ligero** (`global nlvint_light 1`, solo desarrollo): reutiliza `users/$id/aportaciones.dta`, re-registra los escalares de la sesión (`TasasEfectivas` sin `enigh`, `Simulador AportacionesNetas`) y re-corre `EntidadNL` en ~16 s con números idénticos; las corridas del sello se hacen sin él.
- **`01_modulos/EntidadNL.do` v1.4.0** (aditivo): `nHognl`, `nPersnl`, `nHogDecMinnl` (muestra NL post-ajuste), `concTop1<X>nl` y `nPos<X>nl` para los 10 impuestos, `concTop1KPrivnl`; nota `sensibilidad_muestral_nota`; los textos del contrato citan `scalar(anioenigh)` en lugar de "ENIGH 2024" literal. Paridad: `output.txt` `ae624b98…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`) intacto; D.1 PASÓ.
- **`01_modulos/nl-assets/nl-vintages-sello.do` v1.0.0** — lee los cinco `users/<usuario>-v<t>/nodos/statajson_entidad-nl.json`, **compuertas** (1) misma capa y motor que la sesión y `anio_referencia = enigh_vintage = t`; (2) `Rec<X>nac` = `master/LIF.dta` observada del año (mes 12, filtro sin financiamiento), 1e-6, 10 × 5 celdas; (3) `Part = Rec/Rec`, 1e-9; (4) `nHogDecMinnl ≥ 100`; **informativo** saltos entre vintages consecutivos, concentración top-1 máxima por impuesto y ligadura vintage 2024 vs corrida vigente. Escribe `nl-assets/participaciones-vintages.json` (`nl.participaciones-vintages/v1`, ~20 KB): `identidad`, `asignacion` (regla escalonada, `sello_2020`, `sensibilidad_muestral`), `ligadura`, `vintages[]` (enigh, anioPE, corrida, SHA del statajson, muestra, `partImp/S1/S3`, `concTop1KPrivnl`, sello), `participaciones[]` (enigh × impuesto: part, S1/S2/S3, recNac, recNL, lifObs, concTop1, nPos), `saltos[]`. `./nl-vintages.sh` corre los cinco vintages en serie y el sello con fallo seguro.
- **`01_modulos/FederacionNL.do` v1.2.0** — §3b lee el sello de vintages en **ambos modos** y añade las compuertas **(10)** `Rec<X>nac` por vintage = recaudación observada del año (del canal o del sello de corrida), 1e-6; **(11)** `part = recNL/recNac`, 1e-9; **(12)** ligadura vintage 2024 vs corrida vigente, 1e-3 (hoy 2.7e-05); **(13)** sello de vintages de la misma capa y motor; en modo canal, SHA de cada statajson de vintage presente = sello; el SHA del sello de vintages viaja en `identidad.vintages_sha256` de `federacion-sello.json` (en modo sello se exige igualdad: los dos sellos se verifican como par). Asignación año→vintage (escalonada; `extrapolado` antes del primero), **lado paga por año con la participación del vintage asignado** (§4.2), `participacionesAnual` con `enigh`, `metodo`, `sello`, muestra y `concTop1<X>` por año, nuevo arreglo `vintages`, procedencia (fuente `participaciones_vintages`, compuertas `vintages_sello`/`recaudacion_vintage`/`part_vintage`/`ligadura`/`saltos_informativo`/`isrpm_por_vintage`, supuestos `participaciones_bienales`/`sello_2020`/`sensibilidad_muestral`, tipos `bienal`/`extrapolado`). Probado: modo canal y modo sello producen `anual`, `cifras` y `participacionesAnual` idénticos.

### 2. Implementación F2 (commits `8858ad3`, `d09440f`)

`federacion-nl.html`: nota del año "ENIGH <vintage>, método <bienal|extrapolado>" (+ sello pandémico en 2020–2021, + "una persona de la muestra aporta el x % del ISR PM de NL") en la zona de controles, el Sankey, la conciliación y los extractos; letrero de alcance con el supuesto corto; **vista nueva "La carga federal de NL a través del tiempo"** (`#vista=vintages`): (c1) participación de NL en cada impuesto por ENIGH bienal — un punto por vintage, tramo horizontal = bienio que cubre (nunca interpolado), franja = banda [S1, S3] del ISR PM, anillo y línea roja en la ENIGH 2020 pandémica, tooltip con muestra y sensibilidad, oración-resumen generada desde el canal; en modo tabla la **ficha por vintage** (calibración, muestra, participaciones, banda, top-1 por impuesto, corrida y SHA); (c2) pesos pagados por impuesto por habitante (o macro) desde 2016 con cortes punteados donde cambia la ENIGH. Autocomprobaciones nuevas: `participacionesAnual[ref] = vintages[enigh(ref)]`, ligadura vintage 2024 ≈ corrida vigente (1e-3), 8 impuestos y S1 ≤ S3 por vintage (24 cifras en verde con el sello de desarrollo). `actualizar-nl.sh` registra los vintages en la bitácora; `windows/verificar-runner.ps1` exige `participaciones-vintages.json`; `nl-manifest.json` NL-0.5.0 con el sello declarado en `sellos`.

**Hallazgo de la banda (se documenta):** en la ENIGH 2016 el S0 del ISR PM (41.6 %) queda **fuera** de [S1, S3] = [18.3, 19.4]: S1/S3 prorratean sobre `ing_bruto_tpm` mientras S0 concentra el cut-off en la observación top-1; la banda acota los estimadores de prorrateo, no al S0 — por eso la autocomprobación por vintage solo exige S1 ≤ S3 y la del año de referencia sigue exigiendo S1 ≤ S0 ≤ S3.

### 3. Corridas definitivas y evidencia (2026-10-05, motor v8.7.1)

**Secuencia ejecutada:** PR #13 mergeado y etiquetado `v8.7.1` (Releases v8.6.1/v8.7.0/v8.7.1 creados desde los tags **sin assets** → `ensure_asset` 404 en el `SIM.do` nacional; resuelto espejando los 26 assets de v8.6.0 a v8.7.1, SHA verificado; proceso y Gate 8 en **PR #14**) → merge de cadencia `origin/master` → `feature/entidad-nl` (`ecc9c6d`, limpio; difieren del merge-base solo `AccesoBIE`/`DatosAbiertos`/`PIBDeflactor` de master) → borradas `master/2016|2018|2020` y `perfiles20{16,18,20,22,24}.dta` → `./nl-vintages.sh` (2016: 1,109 s; 2018: 2,351 s y 2024: 1,810 s con el `SIM.do` nacional corriendo en paralelo; 2020: 1,291 s; 2022: 776 s) → `nl-vintages-sello.do`: compuertas 1–4 **PASÓ**, ligadura 2.68e-05 → `SIM.do` + `EntidadNL.do` vigente (TOUCH-DOWN 457 s; `output.txt` SHA-256 `ae624b9885b7ac67…45fa15` (ancla del 22-sep, retirada en NL-0.5.2: hoy `e40af4a6…`) **idéntico** con el motor v8.7.1; D.1 PASÓ) → `FederacionNL` con `nlfed_sellar 1` (2 diferencias esperadas: SHA del statajson y del sello de vintages) → `./actualizar-nl.sh` (INEGI y SHCP frescos; "compuertas en verde, 6 productos") → publicado.

**Participaciones definitivas (%, S0; idénticas a las de F0: el fix del motor no toca el año del vintage):**

| ENIGH | ISR salarios | ISR PF | ISR PM [S1, S3] | top-1 ISR PM | IVA | IEPS NP | IEPS P = ISAN | Import. | Cuotas | Hogares NL (mín. decil) | SHA statajson |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2016 | 7.39 | 6.23 | 41.64 [18.35, 19.40] | 96.0 % | 5.77 | 8.11 | 9.45 | 5.44 | 9.31 | 2,984 (166) | `f8ea4dcc1fb1` |
| 2018 | 7.08 | 6.27 | 7.89 [4.37, 8.85] | 22.7 % | 6.30 | 9.98 | 9.03 | 5.89 | 8.79 | 3,043 (181) | `5fe42b5dd7f0` |
| 2020 (pandémica) | 8.82 | 6.82 | 10.01 [5.44, 10.44] | 37.9 % | 6.78 | 8.35 | 6.13 | 6.02 | 9.51 | 3,502 (223) | `43a60f9e6890` |
| 2022 | 8.67 | 12.99 | 4.64 [3.18, 5.43] | 9.4 % | 6.72 | 9.30 | 10.35 | 6.28 | 9.93 | 3,612 (219) | `3f3fff952cd7` |
| 2024 | 8.82 | 6.10 | 14.22 [8.64, 20.90] | 48.1 % | 6.46 | 12.01 | 6.48 | 6.26 | 9.83 | 3,796 (338) | `678c3d041be4` |

Sellos commiteados: `participaciones-vintages.json` (SHA `22eaf7c05523…`, 5-Oct-2026T19:12:26) y `federacion-sello.json` (19:25:29, con `vintages_sha256`). **Evidencia desde el Drive** (`/My Drive/2. Simuladores CoNL/SimuladorCoNL/federacion-nl.html`): SHA-256 `1ac72fb34b64adbf…` idéntico al local, 585 KB, un solo `http` (GitHub); Chrome headless sobre el archivo del Drive, sin red: cabecera "construido sobre el Simulador Fiscal CIEP v8.7.1 · capa NL-0.5.0 · año de referencia 2025 · Paquete 2027"; vista `vintages` con la serie 2016–2024 y la ENIGH 2020 marcada; nota de 2021 = "ENIGH 2020, método bienal · ENIGH pandémica … · sensibilidad muestral: una persona de la muestra aporta el 37.9 % del ISR PM de NL"; autocomprobación **24/24** en verde. Bitácora: `2026-10-05T19:26:07 capa=NL-0.5.0 | … | fed: modo canal; EOFP hasta 2026-08; ref 2025; sello 5-Oct-2026T19:25:29; vintages 2016 2018 2020 2022 2024 (sellados 5-Oct-2026T19:12:26) | sha256(12): federacion-nl.html=1ac72fb34b64 nodos/federacion-nl.json=a55ad105cd85`. Cifras del año de referencia 2025 sin cambio material respecto a NL-0.4.1 (el vintage asignado a 2025 es la misma ENIGH 2024: paga S0 496,182.8 mmdp vs 496,192.8; diferencia = redondeo de factores de la calibración 2024 vs 2027): el cambio visible está en 2000–2023 y en la vista nueva.

### 4. Paridad y frontera

Motor intacto en la rama (vs merge-base `ecc9c6d` solo cambian archivos de la capa NL); los dos cambios al motor viajaron por `master` (PR #13 fusionado; PR #14 abierto). Registro de escalares solo-aditivo. El árbol *scratch* `~/CIEP_Simuladores/_vintage-f0/` ya no se necesita (las cachés definitivas se reconstruyeron con v8.7.1) y puede borrarse junto con `~/CIEP_Simuladores/SimuladorCIEP-fixes` cuando PR #14 se fusione.

---

## Anexo Cadencia v8.8.1 — gate de cadencia de la capa NL y re-anclaje (2026-10-08, capa NL-0.5.2)

Resumen ejecutivo en el changelog (entrada NL-0.5.2). Aquí la evidencia en tablas; los logs y JSON viven en `~/CIEP_Simuladores/diag-cadencia-nl-2026-10-07/`.

### 1. Compuertas

| Compuerta | Resultado | Evidencia |
|---|---|---|
| **1. Paridad nacional vs ancla v8.8.0** | **PASÓ — byte-idéntico** | Estado cero + `SIM-local.do` canónico (`nographs`, `output`, `update`, `fuentes "2026-10-06"`), StataNow 19.5 SE, `set processors 1`, batch `< /dev/null`. `output.txt` `e40af4a6dda77d3a042228a291d55443fc020d3bf431698b179e7c11385a4d27` (48,790 bytes, 0 líneas con `> `); sankeys `9e99bc33…`, `eb19eb8b…`, `bf3b6236…`, `7cf63b33…`, `4e3d3e2e…` = ancla. TOUCH-DOWN 3,843 s. `compuerta1/shasums-despues.txt`. |
| **2. D.1 (`EntidadNL.do`)** | **PASÓ** | Misma sesión (motor v8.8.1 tras el hotfix; `output.txt` repite `e40af4a6…`, TOUCH-DOWN 645 s): 11 filas idénticas al pipeline; `scalarjson (entidad-nl): 1801 escalares, 0 faltantes`. `compuerta2/wrap-sim-nl.log`. |
| **3. Vintages y sellos** | **Re-emitidos; 2016–2022 Δ = 0, 2024 se mueve** | `nl-vintages.sh` con StataNow SE (5 corridas, D.1 PASÓ en cada una; sello: compuertas 1–4 PASÓ, ligadura 3.09e-05); `FederacionNL` canal + `nlfed_sellar 1`: compuertas 1–13 PASÓ, 38 diferencias con el canal → re-sellado. `compuerta3/`. |

### 2. Insumos del motor: 22-sep (ancla retirada) vs fuentes congeladas 2026-10-06

`datasignature` por año tras `sort` por todas las variables (`compuerta3/compara-master.txt`) y comparación celda a celda de `LIF.dta` (`lif-detalle.log`):

| Base | Años idénticos | Años que difieren | Lectura |
|---|---|---|---|
| `LIF.dta` (numérico: `LIF`, `ILIF`, `monto`, `acum_prom`, `mes`, `recaudacion`) | 2014–2025 | **2026** (37 celdas de `monto`, 50 de `acum_prom`, 54 de `mes`) | meses nuevos de la SHCP; la recaudación observada mes 12 de los 10 impuestos 2016–2025 **no cambia** (0 celdas, reldif > 1e-9) |
| `SCN.dta` (544 variables) | 2014–2023, 2026–2027 | **2024, 2025** | revisión del PIB 2024 y publicación de 2025 (INEGI) |
| `PIBDeflactor.dta`, `Deflactor.dta` | todos | — | sin cambio entre el 22-sep y el 6-oct |
| `SHRFSP.dta` | 2027 | 2014–2026 | derivado (DEUDAPARAM, meses nuevos) |

Consecuencia esperada y observada: los vintages 2016–2022 (SCN y LIF de su año idénticos) no se mueven; el vintage 2024 y la corrida vigente (ENIGH 2024, SCN 2024) sí.

### 3. Participaciones por vintage: sello NL-0.5.1 (v8.7.2, Stata 17 MP) vs NL-0.5.2 (v8.8.1, StataNow 19.5 SE)

Participación de NL (%), antes → después, por vintage (Δ en pp):

| Vintage | ISRAS | ISRPF | ISRPM | CUOTAS | IVA | IEPSNP | IEPSP | ISAN | IMPORT | OTROSK |
|---|---|---|---|---|---|---|---|---|---|---|
| 2016 | 7.39→7.39 (+0.00) | 6.23→6.23 (+0.00) | 41.64→41.64 (+0.00) | 9.31→9.31 (+0.00) | 5.77→5.77 (+0.00) | 8.11→8.11 (+0.00) | 9.45→9.45 (+0.00) | 9.45→9.45 (+0.00) | 5.44→5.44 (+0.00) | 41.64→41.64 (+0.00) |
| 2018 | 7.08→7.08 (+0.00) | 6.27→6.27 (+0.00) | 7.89→7.89 (+0.00) | 8.79→8.79 (+0.00) | 6.30→6.30 (+0.00) | 9.98→9.98 (+0.00) | 9.03→9.03 (+0.00) | 9.03→9.03 (+0.00) | 5.89→5.89 (+0.00) | 7.89→7.89 (+0.00) |
| 2020 | 8.82→8.82 (+0.00) | 6.82→6.82 (+0.00) | 10.01→10.01 (+0.00) | 9.51→9.51 (+0.00) | 6.78→6.78 (+0.00) | 8.35→8.35 (+0.00) | 6.13→6.13 (+0.00) | 6.13→6.13 (+0.00) | 6.02→6.02 (+0.00) | 10.01→10.01 (+0.00) |
| 2022 | 8.67→8.67 (+0.00) | 12.99→12.99 (+0.00) | 4.64→4.64 (+0.00) | 9.93→9.93 (+0.00) | 6.72→6.72 (+0.00) | 9.30→9.30 (+0.00) | 10.35→10.35 (+0.00) | 10.35→10.35 (+0.00) | 6.28→6.28 (+0.00) | 4.64→4.64 (+0.00) |
| 2024 | 8.82→8.86 (+0.05) | 6.10→5.99 (-0.11) | 14.22→14.15 (-0.07) | 9.83→9.83 (+0.00) | 6.46→6.46 (-0.00) | 12.01→12.01 (+0.00) | 6.48→6.48 (+0.00) | 6.48→6.48 (+0.00) | 6.26→6.26 (+0.00) | 14.22→14.15 (-0.07) |

Salto máximo antes→después por impuesto (pp): ISRAS 0.05; ISRPF 0.11; ISRPM 0.07; CUOTAS 0.00; IVA 0.00; IEPSNP 0.00; IEPSP 0.00; ISAN 0.00; IMPORT 0.00; OTROSK 0.07

ISR PM: banda [S1, S3] y top-1 por vintage:

| Vintage | S0 antes → después | S1 antes → después | S3 antes → después | top-1 antes → después |
|---|---|---|---|---|
| 2016 | 41.64 → 41.64 | 18.35 → 18.35 | 19.40 → 19.40 | 96.0 % → 96.0 % |
| 2018 | 7.89 → 7.89 | 4.37 → 4.37 | 8.85 → 8.85 | 22.7 % → 22.7 % |
| 2020 | 10.01 → 10.01 | 5.44 → 5.44 | 10.44 → 10.44 | 37.9 % → 37.9 % |
| 2022 | 4.64 → 4.64 | 3.18 → 3.18 | 5.43 → 5.43 | 9.4 % → 9.4 % |
| 2024 | 14.22 → 14.15 | 8.64 → 8.56 | 20.90 → 20.78 | 48.1 % → 47.9 % |

Muestra NL por vintage idéntica (2016: 2,984 hogares / 10,558 personas; 2018: 3,043 / 10,455; 2020: 3,502 / 12,003; 2022: 3,612 / 12,036; 2024: 3,796 / 12,586); mínimo de hogares por decil nacional 166 / 181 / 223 / 219 / **338→340**. `recNac` idéntico en las 50 celdas (LIF observada mes 12). Ligadura vintage 2024 vs corrida vigente: 2.68e-05 → 3.09e-05.

### 4. Corrida vigente PE 2027 (`statajson_entidad-nl.json`): delta Paquete-vs-motor

Mismo Paquete (PE 2027, ENIGH 2024, mismos parámetros de `SIM.do` salvo IVAT[13] 23.0→23.1): todo el delta es **fuentes + motor** y mueve igual al nacional. 1,801 escalares comunes; 1,625 con reldif > 1e-9 (los `Dif*TE*` nacionales, cercanos a cero, dominan los reldif grandes).

| Escalar | NL-0.5.1 (v8.7.2, 6-oct) | **NL-0.5.2 (v8.8.1, 8-oct)** | Δ |
|---|---:|---:|---:|
| TE laboral NL `YlImpTEnl` | 18.02 | **17.65** | −0.38 |
| TE laboral nacional `YlImpTEnac` | 13.36 | **13.15** | −0.21 |
| TE ISR PM NL `ISRPMTEnl` | 24.37 | **23.84** | −0.54 |
| TE IVA NL `IVATEnl` | 6.44 | **6.25** | −0.19 |
| Incidencia total NL `incImpAportnlTot` | 30.80 | **30.17** | −0.62 |
| Incidencia total nacional `incImpAportnacTot` | 21.47 | **21.12** | −0.35 |
| `PartISRPMnl` [S1, S3] | 14.22 [8.64, 20.97] | **14.15 [8.56, 20.86]** | −0.07 |
| `concTop1ISRPMnl` | 48.1 % | **47.9 %** | −0.3 |
| `PartISRASnl` / `PartISRPFnl` | 8.82 / 6.10 | **8.86 / 5.99** | +0.05 / −0.12 |
| `PartCUOTASnl` / `PartIVAnl` / `PartIEPSNPnl` | 9.83 / 6.46 / 12.01 | = | 0 |

Causas (CHANGELOG v8.8.0, F0 del PR #16): SCN 2024 revisado (PIB 33,582.9→33,667.0 mmdp → armonización macro-micro de `Households.do`, `INCD` hasta 11 %) y cachés micro `master/2024/*_pc` regenerados con `perfilpc` v8.5.0 (el ancla vieja arrastraba cachés pre-`perfilpc`). **Cifras citables vigentes (PE 2027 / motor v8.8.1 / capa NL-0.5.2):** TE laboral NL **17.6 %** (nacional 13.1 %); incidencia total NL **30.2 %** del ingreso bruto (nacional 21.1 %); participación NL en ISR PM **14.2 %** [8.6, 20.9]. Las de NL-0.5.1 (18.0 / 30.8 / [8.6, 21.0]) quedan superadas por la fuente, no por la capa.

### 5. Nodo Federación↔NL: cifras 2025 antes vs después (`federacion-nl.json` → `cifras`)

| cifra | antes (NL-0.5.1/v8.7.2) | después (NL-0.5.2/v8.8.1) | Δ | Δ % |
|---|---:|---:|---:|---:|
| `recibeNL` | 117.36 mmdp | 117.36 mmdp | 0.00 mmdp | +0.000 % |
| `recibeNac` | 2,699.20 mmdp | 2,699.20 mmdp | 0.00 mmdp | +0.000 % |
| `pagaS0NL` | 496.18 mmdp | 495.65 mmdp | -0.53 mmdp | -0.107 % ** |
| `pagaS1NL` | 414.47 mmdp | 413.72 mmdp | -0.75 mmdp | -0.181 % ** |
| `pagaS3NL` | 593.94 mmdp | 592.71 mmdp | -1.23 mmdp | -0.207 % ** |
| `balanzaS0NL` | -378.82 mmdp | -378.29 mmdp | 0.53 mmdp | -0.141 % ** |
| `balanzaS1NL` | -297.11 mmdp | -296.36 mmdp | 0.75 mmdp | -0.252 % ** |
| `balanzaS3NL` | -476.59 mmdp | -475.35 mmdp | 1.23 mmdp | -0.258 % ** |
| `pagaS0NLpibe` | 17.1457 | 17.1273 | -0.0184 | -0.107 % ** |
| `balanzaS0NLpibe` | -13.0904 | -13.0720 | +0.0184 | -0.141 % ** |
| `partRecibeNL` | 4.3479 | 4.3479 | +0.0000 | +0.000 % |
| `partPagaNL` | 9.4492 | 9.4390 | -0.0101 | -0.107 % ** |
| `pagaPES0NL` | 577.40 mmdp | 576.81 mmdp | -0.59 mmdp | -0.102 % ** |
| `balanzaPES0NL` | -448.11 mmdp | -447.52 mmdp | 0.59 mmdp | -0.131 % ** |

El lado "recibe" no cambia (EOPF hasta 2026-08, Last-Modified 30-sep-2026; `_NLeopf` en vivo). El lado "paga" baja 0.1 % por `Part<X>nl` del vintage 2024 (ISR PF y PM). Regenerado en `users/ricardo/nodos/`, **no publicado**.

### 6. Entorno y procedimiento (lo que hizo falta para que corriera)

1. `sysprofile.do` de StataNow es interactivo (`_request`): en batch se lanza con `< /dev/null` para que no fije `SITE`; `profile.do` del worktree carga igual.
2. El asset `fuentes-2026-10-06.zip` se copió del worktree `SimuladorCIEP-datos` (SHA `783bd2bc…` = manifest); `ensure_asset` lo re-verificó.
3. Hotfix v8.8.1 (PR #18) necesario para que `EntidadNL`/`scalarjson` corran; fusionado localmente en la rama antes de la compuerta 2.
4. Drivers NL (`actualizar-nl.do`) con StataNow: wrap con `python set exec /usr/bin/python3` + `run profile.do` explícito (Python 3.14 de StataNow no valida el certificado de la SHCP), `global fuentes "2026-10-06"` (series nacionales congeladas = motor) y `global nlfed_sellar 1`. Los csv congelados de `raw/temp/AccesoBIE/` se restauraron del zip tras la primera corrida sin `$fuentes`.
5. `nl-vintage.do` conserva `IVAT[13] = 23.0` (el motor pasó a 23.1 en `SIM.do` §4.5): `EntidadNL` solo lee los regímenes (filas 1–12) de la matriz, así que no afecta números; se anota como asimetría a resolver cuando se toque el driver.

---

## Anexo Fuentes congeladas de la capa NL — candado `nlfuentes` (2026-10-08, sprint NL-0.6.0, sesión C1) — BORRADOR, pendiente de aprobación

**Objeto (item 1 del sprint).** Las series que la capa trae por su cuenta —`_NLbie` (`raw/temp/AccesoBIE/nl_<indicador>.csv` + `.meta`), `_NLinpc` (`nl_inpc_<serie>.csv` + `.meta`) y `_NLeopf` (`raw/temp/EOPF/nl_transferencias.csv` + `.meta` + `_fondos.csv`)— corrían **siempre en vivo**, mientras el motor va congelado al 2026-10-06 (`global fuentes`). Eso tumbó dos compuertas en 48 h (INPC 2026-09 publicado el 7-oct; EOFP re-descargado el 8-oct, hallazgo de diseño de la entrada NL-0.5.2). Resolución: la capa congela sus fuentes con la **misma convención de fecha** que el motor.

### 1. Qué se empacó

`01_modulos/nl-assets/nl-fuentes-2026-10-08.zip` (2,878,315 bytes; SHA-256 `5304051c385910e1fa598788adfc79498447c4979107ee57cbf90d2b03cd7309`; `checksum_stata` 472376347) = el estado **vigente** de las cachés que produjo los sellos del 8-oct (`federacion-sello.json` 13:38, `participaciones-vintages.json` 13:27, publicación 17:57): 15 archivos, 13,193,886 bytes sin comprimir —`AccesoBIE/nl_750453`, `nl_746097`, `nl_753357`, `nl_741180`, `nl_741927` (consulta INEGI 08/10/2026 13:37), `nl_inpc_902690` (INPC NL hasta 2026/09, 13:38) y `EOPF/nl_transferencias.*` (descarga 2026-10-08 13:38:06, Last-Modified 30-sep-2026, periodo final 2026-08, 453,292 filas). Los SHA-256 de los 15 archivos (`diag-sankey-nl-2026-10-08/C1/nl-fuentes-shasums.txt`) coinciden con las cachés vivas. Declarado en `nl-manifest.json`: `fuentes_nl_congeladas_al = 2026-10-08`, `fuentes_nl_regla` y entrada en `assets` (name, sha256, checksum_stata, filelen, contenido, consume, validacion).

### 2. Candado en los lectores

- `nl-assets/nl-fuentes.do` v1.0.0 define `_NLfuentes`: con `global nlfuentes "AAAA-MM-DD"` verifica que `nl-fuentes-<fecha>.zip` esté declarado en `nl-manifest.json` y que `checksum_stata` y `filelen` coincidan (zip pisado o sin declarar → aborta), lo extrae **una vez por sesión** en `raw/temp/` con `replace` (espejo de SIM.do §0.4 con el asset del motor) y devuelve `r(congelado) = 1`; con el global vacío devuelve 0 y no hace nada.
- `nl-bie.do` v1.1.0 (`_NLbie`, `_NLinpc`) y `nl-fed.do` v1.1.0 (`_NLeopf`): tras resolver la caché llaman `_NLfuentes`; si está congelado, **no descargan** (abortan si el zip no trae el archivo pedido). Con el global vacío el comportamiento es **idéntico** al anterior (en vivo, u `offline` con la caché que haya).
- `actualizar-nl.sh`: acepta `NLFUENTES=AAAA-MM-DD` y escribe `global nlfuentes` en el wrap, al lado de `FUENTES=` (motor). Vacío = en vivo.
- No se rediseña `ensure_asset` (el zip viaja commiteado en `nl-assets/`, como `pobproy_quinq1.csv`) ni se toca el motor.

### 3. Prueba del candado (`C1/test-nlfuentes.log`)

Cachés vivas apartadas, red bloqueada con un proxy inválido (`https_proxy=http://127.0.0.1:9`), `global nlfuentes "2026-10-08"`: `_NLbie 750453` extrajo el zip (checksum verificado), leyó la caché (último 2024 r1, checksum tabla 3636773412), `_NLinpc 902690` (último 2026/09) y `_NLeopf` (453,292 filas, periodo final 2026-08, descarga 2026-10-08 13:38:06) leyeron sin red; la segunda llamada no re-extrajo. Los 15 archivos restaurados reproducen los SHA-256 vigentes (`shasum -c`: 15 OK). Después se devolvieron las cachés originales (mismos bytes, timestamps 13:37–13:38).

### 4. Regla operativa

Toda corrida de la capa con el motor congelado lleva **los dos candados**: `global fuentes "2026-10-06"` (motor) y `global nlfuentes "2026-10-08"` (capa), o `FUENTES=… NLFUENTES=… ./actualizar-nl.sh --offline`. Mover la fecha de la capa es un **release de datos de la capa**: nuevo zip con el estado que se quiere sellar, SHA-256 + `checksum_stata` + `filelen` en `nl-manifest.json`, `fuentes_nl_congeladas_al`, y entrada en este documento. Los sellos (`federacion-sello.json`, `participaciones-vintages.json`) **no se mueven** con este anexo.

### 5. Primera corrida con el candado

`FederacionNLQuintiles.do` v0.1.0 (capa de datos del Sankey por quintil, sesión C1; ver borrador de la entrada NL-0.6.0 en `diag-sankey-nl-2026-10-08/C1/`) corrió con ambos globals; procedencia `fuentes_congeladas_motor = 2026-10-06`, `fuentes_congeladas_capa = 2026-10-08`. Cero descargas en la sesión (timestamps de `raw/temp/AccesoBIE/` del motor 6-oct 17:01–17:16; propios 8-oct 13:37–13:38).

