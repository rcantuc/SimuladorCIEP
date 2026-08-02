# Plan de integración — Boceto Paquete 2027 (Entrega 2)

**Fecha:** 2026-08-01
**Alcance:** solo lectura y análisis. Ningún cambio a código de producción.
**Método:** catálogo de escalares extraído de los `.ado`/`.do` del motor (701 nombres registrados), lectura de `master/*.dta` vía pandas (solo lectura), censo línea por línea del documento 2026, historia git, y dos investigaciones documentales (caso 2021, `06_libro/public_html`).

La sección 2.5 va primero por instrucción expresa: es el dato que desbloquea calendario.

---

## 2.5 Censo de los literales del documento 2026 — PRIORIDAD

### Nota de alcance

El "68" de la Entrega 1 era una agregación del análisis por capítulos. El re-censo línea por línea (verificado contra los archivos: las líneas citadas coinciden) da **89 grupos de literales** en la prosa de los 10 capítulos, más **11 grupos en Implicaciones que repiten cifras titulares de los capítulos** (heredan su clasificación; costo marginal cero una vez conectados los capítulos). Cada grupo es una línea de prosa con una o más cifras relacionadas; la clasificación es por la necesidad dominante del grupo.

### Los tres números

| Clasificación | Grupos | % | Qué significa |
|---|---:|---:|---|
| **Conexión de escalar existente** | **42** | **47%** | El escalar ya se registra en el motor; falta `\input` del statalatex y sustituir el literal por la macro |
| **Cálculo nuevo en el motor** | **34** | **38%** | La serie/insumo ya está cargada en el motor (PEF.dta, anexos, ENIGH), pero nadie expone el escalar. Trabajo en Stata, no captura de datos |
| **Dato externo** | **13** | **15%** | Nunca pasó ni pasará por el Simulador: supuestos de CGPE, parámetros de iniciativas de ley, benchmarks internacionales (OMS/OCDE/UNESCO), padrones administrativos. Van como escalares curados (`origen: manual`, §2.2) o citas con fuente |

**Lectura de calendario:** los capítulos **Deuda (6/8 conexión), Ingresos presupuestarios (15/22), Educación (6/8) y Pensiones (2/3)** pueden salir mayormente bajo contrato en **septiembre** con esfuerzo de conexión pura. El bloque de **cálculo nuevo se concentra en un solo cuello: `PEF.ado` registra hoy CERO escalares** (verificado: 0 ocurrencias de `escalar` en el archivo), y de él dependen gasto-total, los programas presupuestarios de salud/educación/cuidados, los anexos transversales y federalizado por entidad. Ese es el trabajo de motor de octubre–diciembre. El 15% externo no es deuda: es la parte que por diseño se cura a mano con el mismo esquema del contrato.

### Censo por capítulo

Convención: **✔** escalar existente (nombre del catálogo del motor), **⚙** cálculo nuevo, **⬈** dato externo. Módulos: SHRFSP = `SHRFSP.ado`, LIF = `LIF.ado` (registra `<Concepto>`, `<Concepto>PIB`, `<Concepto>Tot`, `<Concepto>C` por concepto de la LIF), GPC = `GastoPC.ado`, PD = `PIBDeflactor.ado`, SIM = `Simulador.ado`/`SIM.do`.

#### 3_Deuda/deuda.tex (8 grupos: 6 ✔ · 2 ⚙ · 0 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 39 | 18.9 billones MXN saldo 2025; costo 1.6 billones = 4.1% PIB; 20.2 billones, 52.3% PIB 2026 | ✔ | `SHRFSPMonto`, `SHRFSPPIB`, `CostoFinancieroMonto`, `CostoFinancieroPIB` (SHRFSP) |
| 51 | RFSP 5.8% del PIB → 2.9% en 2027; 4.3% | ✔ parcial | `RFSPPIB` (año vp) ✔; la trayectoria multi-año pide escalares por año o serie (§2.2) |
| 72 | costo financiero +13.1% anual; 2.1% PIB GobFed; tasas 68.3%, 9.4%, 8.4%, 6.3% | ⚙ | composición GobFed/EPE del costo y tasas implícitas: derivable de series ya en `SHRFSP.dta` |
| 86 | RFSP 4.3%→4.1%; balance 3.0% PIB | ✔ | `RFSPPIB`, `rfspBalancePIB` |
| 92 | CGPE 2025 estimaba 51.4%; CGPE 2026 prevé 52.3% = 20.2 billones | ✔ | `SHRFSPPIB`, `SHRFSPMonto`; el 51.4% (CGPE del año previo) es cita documental, no escalar |
| 110 | balance primario 0.2 pp; 0% del PIB | ✔ | `rfspBalancePIB` |
| 122 | deuda per cápita: 151 mil pesos hoy, 159 mil en 2031 | ✔ | `SHRFSPPC`, `SHRFSPlastPC` (y `monto_pc` por año en `SHRFSP.dta`) |
| 141 | crecimiento 6% nominal, tasa 8.4%, crecimiento real 2% | ⚙ | tasa implícita y aritmética deuda-crecimiento: series existentes, falta escalar |

#### 1_Ingresos/ingresos-energia.tex (8: 4 ✔ · 3 ⚙ · 1 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 48 | 1,794 mbd; 54.9 dólares/barril; 20.1% menores | ⬈ | supuestos CGPE (SHCP) → escalar curado `origen: manual` |
| 70 | FMP 971 mil 677 mdp; transferencias 263.5 mmdp, 27.1%; 708 mil 193, 5.6% | ✔ | conceptos LIF: `FMP`, `FMPPIB`, `FMPTot`, `FMPC` (LIF) |
| 86 | Pemex 708 mil 201 mdp, 11.7%; 73/27%; 7.6% | ✔ | concepto LIF Pemex (`Pemex*`); composición interna: ⚙ menor |
| 92 | 535 mil 477 mdp, 5.2% | ✔ | concepto LIF |
| 107 | CFE 602 mil 567 mdp, 1.5%; 92/8%; 20.4% | ✔ | concepto LIF CFE (`CFE*`; baseline ya tiene `ECFE`) |
| 111 | subsidio eléctrico 263 mil 699 / 263 mil 484 mdp, 86.8% | ⚙ | gasto por ramo/programa: vive en `master/PEF.dta`, PEF.ado no expone escalares |
| 113 | 92 mil 685 mdp; 12 mil 188 mdp | ⚙ | ídem (PEF) |
| 167 | 263.5 mmdp = 3.3 veces X, el doble de Y, 292 veces Z | ⚙ | comparadores: aritmética entre escalares existentes, falta registrarlos |

#### 1_Ingresos/ingresos-presupuestarios.tex (22: 15 ✔ · 0 ⚙ · 7 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 41 | ILIF 8 billones 721 mil 057 mdp = 22.5% PIB, +4.6%; tributarios 5,838,541 = 15.1% PIB | ✔ | `EIngresosTotales`, conceptos LIF con `PIB`/`C` (LIF) |
| 46 | crecerían 2.1% y 3.5% | ✔ | `<Concepto>C` (LIF) |
| 49–52 | ISR 66.9% del total (+6.5%); IVA 19.9% (0.0%); IEPS 8.8% (5.1%); otros 4.3% (2.7%) | ✔ | `<Concepto>Tot`, `<Concepto>C` (LIF) |
| 81 | evasión entre 1.8% y 2.8% del PIB; 2.3% | ⬈ | estudios de evasión (SAT/terceros) |
| 96 | 0.1% del PIB | ✔ | LIF |
| 99 | 0.1 pp; 22.5% del PIB | ✔ | LIF |
| 103 | 0.1 pp | ✔ | LIF |
| 109 | 15.1% del PIB, 0.5 pp | ✔ | LIF |
| 112 | ISR 3.07 billones, +3.7%, 7.9% PIB, 0.2 pp, 3.1% | ✔ | LIF concepto ISR + `ISRPFPIB`/`ISRPMPIB` (SIM) |
| 116 | IVA 1.59 billones, +4.9%, 4.1% PIB; 3.81→4.05%; 95,900 y 598,089 mdp; 1.82% PIB | ✔ | LIF concepto IVA + `IVAPIB` (SIM) |
| 120 | IEPS 473 mil 279 mdp, +6.7% | ✔ | LIF |
| 126 | 254,756 mdp +11.9%; 252,909 +17.6% | ✔ | conceptos LIF |
| 344 | 75 mil 290 mdp esperados por nuevas medidas | ⬈ | estimación oficial de la iniciativa (SHCP) |
| 346 | IEPS 1.1584 → 0.8516 pesos/litro; 160–200%; 62,079.2 mdp; 7.3% | ⬈ | parámetros de ley + estimación SHCP |
| 350 | 30% a 50%; 5,024.7 mdp | ⬈ | ídem |
| 352 | 8%; 183 mdp | ⬈ | ídem |
| 354 | 397,352 y 136,994 mdp; 52.6%; 0.35% PIB | ⬈ | estimaciones de la miscelánea (SHCP) |
| 451 | +4.6%; 22.5% PIB; 380,238 mdp; 6.4% | ✔ | LIF |
| 455 | 15.1% vs 14.6%; ALC 21.3%; OCDE 33.9% | ⬈ | comparativos internacionales (OCDE/CEPAL) |

#### 2_Gastos/gasto-total.tex (8: 2 ✔ · 6 ⚙ · 0 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 38 | gasto neto 10.2 billones = 26.3% PIB; programable 7.1; no programable 3.1, 33.7% | ⚙ | **PEF.ado registra 0 escalares**; la serie está en `master/PEF.dta` — exponer `GastoNeto*`, `GastoProg*`, `GastoNoProg*` |
| 42 | +5.8%; 7.9%; 22,637.7 mmdp; 5.0%; 33,599.9 | ⚙ | variaciones vs aprobado (PEF) |
| 45 | 7.1 billones, +5.0%, 2.2%, 8.9%, 4.0%, 6% | ⚙ | PEF |
| 48 | 3.1 billones, +7.9%, 29.8→30.4% | ⚙ | PEF |
| 99 | espacio fiscal 1.3 puntos; ineludibles 73.5% | ⚙ | metodología CIEP de espacio fiscal: cálculo sobre PEF, no expuesto |
| 129 | costo deuda 102,931.6 mdp, +5.9% | ✔ | `gascosto`/`gascosdeue` + PIB/PC (GPC) |
| 130 | 7.2%; 0.6 pp | ✔ | `gascostoPIB` (GPC) |
| 161 | 10.2 billones; 79.2% | ⚙ | PEF |

#### 2_Gastos/gasto-salud.tex (12: 4 ✔ · 6 ⚙ · 2 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 40 | 996,528 mdp; +5.9%; 4.7%; 2.6% PIB (vs 6% recomendado) | ✔ | `salud`, `saludPIB` (GPC); el 6% es benchmark OMS (⬈ menor, cita) |
| 53 | 3 puntos PIB; 1.04 billones = 2.8% PIB; 55,551.4 mdp = 0.15%; 58,213.9 | ✔ | `imss`, `issste`, `ssa`, `imssbien` + PIB (GPC) |
| 56 | IMSS-Bienestar 1,527.8 mdp, 0.47%, 3.2%… | ✔ | `imssbien*` (GPC) |
| 94 | programas: 75,033; 2,834.8; 11,214.5; 10,492.6 mdp | ⚙ | programa presupuestario (PEF, sin escalares) |
| 97 | 3,011.7; 16,834.9; 641.4; 2,691 mdp | ⚙ | ídem |
| 100 | 1,286.3 mdp; 0.8%; 0.6% | ⚙ | ídem |
| 103 | 1,972.9; 355.2; 8,125.7 mdp | ⚙ | ídem |
| 106 | 16.2 millones; 4,000 mdp; 93.2%; 0.40% | ⬈ | afiliación/informes IMSS |
| 136 | 20.1 → 44.5 millones sin acceso; 21.3%; 0.47% | ⬈ | CONEVAL (carencia por acceso a salud) |
| 160 | 3.4 puntos; 60,464,000 personas | ⚙ | población sin seguridad social: calculable con ENIGH ya en motor |
| 163 | per cápita $4,609 vs $4,412; 4.3%; 48,623.7 mdp, 7.9% | ✔ | `saludPC`, `imssbienPC` (GPC) |
| 166 | 73.1%; 75%; 39,400; 1,528 mdp | ⚙ | mezcla PEF + cálculo |

#### 2_Gastos/gasto-cuidados.tex (9: 2 ✔ · 6 ⚙ · 1 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 40 | Anexo 31: 466,674.9 mdp = 4.6% del gasto neto | ✔ prob. | `gascuidados*` (GPC) — verificar que la definición GPC = Anexo 31 |
| 42 | 45,810.4 mdp; 0.1% PIB; 0.5%; 24.3% | ⚙ | detalle del anexo transversal (PEF) |
| 51 | composición 36.9/31.6/29.2%; 97.6% | ⚙ | anexo por programa (PEF) |
| 54 | 129,386 (27.7%); 126,925.5 (27.2%); 123,260.7 (26.4%); 81% | ⚙ | programas del anexo (PEF) |
| 58 | 45,810.4; 0.7%; 3.7%; 3.3% | ⚙ | ídem |
| 161 | Anexo 13 (género): 599,145.4 mdp; 13.8% | ⚙ | anexo transversal género (PEF) |
| 185 | 150 mil mujeres | ⬈ | meta de programa (documento oficial) |
| 188 | 479,094.1 (+9.6%); 29,479.0; 508,573.1; 5.5%; 52.5% | ⚙ | anexo género (PEF) |
| 226 | 52% mujeres, 48% hombres | ✔ | `pobmujprop*`, `pobhomprop*` (Poblacion.ado) |

#### 2_Gastos/gasto-educacion.tex (8: 6 ✔ · 1 ⚙ · 1 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 34 | 1,238,620 mdp; 3.02% PIB; 12.2%; 3.2%; 58.5%; matrícula 17.2 millones | ✔ | `educac`, `educacPIB` (GPC); matrícula: ⬈ menor (SEP, cita) |
| 46 | 3.55 puntos; 8.1% | ✔ | `educacPIB` + serie histórica GPC |
| 54 | 3.19%; 5%; 16.1% | ✔ | `educacPIB` |
| 105 | básica 766.8 mil mdp; +7.3% | ✔ | `basica`, `basicaPIB` (GPC) |
| 107 | +7.9%; $2,407 per cápita; 3.0% | ✔ | `basicaPC` (GPC) |
| 111 | superior 170.6 mil mdp; 3.9%; 0.7%; 16.2; 0.5% | ✔ | `superi*` (GPC) |
| 122 | 0.4%; 4 mdp; 700 mil | ⚙ | programa presupuestario (PEF) |
| 130 | 3.19%; entre 1 y 3 puntos; 4% y 6% | ⬈ | benchmark internacional (UNESCO/OCDE) |

#### 2_Gastos/gasto-pensiones.tex (3: 2 ✔ · 0 ⚙ · 1 ⬈)

| L | Literal(es) | ¿Escalar? | Nombre / qué falta |
|---|---|---|---|
| 40 | 2.3 billones (+3.7%); contributivas 1.7 billones (+0.5%); no contributivas +13.5%; 619,703 mdp | ✔ | `pension`, `penimss`, `penisss`, `penpeme`, `pam` + PIB (GPC) |
| 45 | 3.4% PIB; 6%; 1.4 pp; 21.1→22.5% | ✔ | `pensionPIB` + share sobre gasto (aritmética de escalares) |
| 51 | 13.5%; 5.2%; 20.8%; 266%; 3 millones beneficiarios | ⬈ | padrón (Bienestar) para beneficiarios; el resto conecta |

#### 2_Gastos/gasto-medio-ambiente.tex (5: 0 ✔ · 5 ⚙ · 0 ⬈)

| L | Literal(es) | ¿Escalar? | Qué falta |
|---|---|---|---|
| 50 | 44.0 mil mdp; +4.0% | ⚙ | **la función medio ambiente no existe en GastoPC** — agregarla (la fuente PEF ya está en el motor) |
| 52 | 2,264 mdp; 1.7%; 3.4%; 8.3% | ⚙ | ídem |
| 56 | CONAGUA 36,689 mdp; 4.5%; 21 mil mdp; 197.6% | ⚙ | ramo/programa (PEF) |
| 78 | Anexo cambio climático 212,569 mdp; 0.04% | ⚙ | anexo transversal (PEF) |
| 81 | 17,868 mdp; 55.4% | ⚙ | ídem |

#### 2_Gastos/gasto-federalizado.tex (6: 1 ✔ · 5 ⚙ · 0 ⬈)

| L | Literal(es) | ¿Escalar? | Qué falta |
|---|---|---|---|
| 45 | 2,810.8 mmdp; +3%; 7.4% PIB; participaciones 50.8%, aportaciones 40.3%… | ✔ | `gasfeder*` (GPC) para el agregado; desglose ⚙ |
| 60 | 4.6%; 3.8%; 1.9%; RFP 5,338,634 mdp; 5.3% | ⚙ | RFP: cálculo sobre LIF/REC no expuesto |
| 80 | FAISPIAM: 0.8%; 1.8%; 36.1%; 4,700; 1,790.5 mdp; 0.7% | ⚙ | fondos del Ramo 33 (PEF) |
| 93 | 10%; 13,506 mdp | ⚙ | ídem |
| 112 | por entidad: 16.3%; 2%; 2.6%; 11 entidades; 13,716.4; 12,952.9; 11,138… | ⚙ | aportaciones por entidad: la serie existe (`users/ricardo/aportaciones.dta`), falta canonizar y exponer |
| 114 | 218.9; 306.7; 313.6; 1,531.5; 1,429.8; 1,368.1 | ⚙ | ídem |

#### 4_Implicaciones/implicaciones.tex (11 grupos: heredan)

Las 11 líneas (L33–L74) repiten las cifras titulares de los capítulos (4.1% PIB, 52.3%, 151 mil pesos, 8.72 billones, 10.2 billones, 466.6 mmdp, 1.24 billones, 2.8 billones, 2.3 billones…). Una vez conectados los capítulos, Implicaciones usa las mismas macros. No suman esfuerzo propio.

---

## 2.1 Las tres series transversales

**Las tres existen hoy en el pipeline, como series canónicas en `master/*.dta`** (verificado leyendo los archivos). Los escalares del contrato son fotografías de un año (año valor presente); la **serie completa por año** vive en el `.dta` que cada módulo produce. Para el nodo se necesita el paso serie→archivo del contrato (§2.2), no producir datos nuevos.

| Serie | ¿Existe? | Dónde | Escalares asociados | Cobertura | Fuente |
|---|---|---|---|---|---|
| **Saldo de deuda (SHRFSP)** | ✅ | `master/SHRFSP.dta` (37 filas anuales; variables `anio`, `shrfsp` [monto], `monto_pc` [per cápita], `monto_pib` [% PIB], `poblacion`, `pibY`, `deflactor`) — módulo `SHRFSP.ado`, que además registra 76 escalares (`SHRFSPMonto`, `SHRFSPPIB`, `SHRFSPPC`, `SHRFSPlastPC`, `RFSP*`, `CostoFinanciero*`, desgloses GobFed/EPE/banca/interno/externo) | `SHRFSPMonto/PIB/PC` y familia | **1990–2026** | SHCP/EOFP vía `DatosAbiertos SHRF5000/5100/5200` + INEGI/BIE |
| **Población total** | ✅ | `master/Poblaciontot.dta` (121 filas anuales: `anio`, `entidad`, `poblacion`) y `master/Poblacion.dta` (por sexo/edad/entidad) — módulo `Poblacion.ado` (24 escalares: `pobtot*`, `pobmujprop*`, etc.) | `pobtot<entidad>` | **1950–2070** (proyección) | CONAPO 1950–2070 |
| **Índice de precios** | ✅ | `master/PIBDeflactor.dta` (trimestral: `indiceQ` deflactor, `inpc`, `currency`) — módulo `PIBDeflactor.ado` (14 escalares: `deflactorVECES`, `inflacionVECES`, `pibY`, `pibYPC`…) | `deflactorLP/VECES`, `inflacionLP/VECES` | **1950–2070** (observado + proyección) | INEGI/BIE |

**Bonus decisivo:** `SHRFSP.dta` ya trae las tres series **fusionadas fila por fila** — cada año tiene saldo, población, PIB, deflactor y el per cápita ya calculado (`monto_pc`) y el % PIB (`monto_pib`). El archivo del nodo puede generarse desde esa sola tabla.

**Serie más corta: SHRFSP, desde 1990.** La entrada personal del nodo ("¿en qué año naciste?") funciona con dato observado para nacidos en 1990 o después. Para nacidos antes de 1990 la ficha debe decirlo explícitamente ("la serie oficial comienza en 1990"), no extrapolar.

**Dos verificaciones antes de publicar la serie** (no bloquean el diseño):
1. En `SHRFSP.dta` la variable `shrfsp` está vacía en los primeros años mientras `montomill`/`monto_pc` sí tienen valor — confirmar cuál es la variable canónica del saldo y su unidad en 1990–1992.
2. Consistencia de unidades a través del cambio de moneda de 1993 (viejos/nuevos pesos): `PIBDeflactor.dta` tiene la variable `currency`, confirmar que la serie 1990–1992 ya está re-expresada.

---

## 2.2 Plan A y Plan B — el mismo contrato

**Plan A:** un exportador nuevo del motor — hermano de `scalarlatex` — que escriba el archivo del nodo desde `master/SHRFSP.dta` al final de la corrida (`statajson`/`statacsv`). Dado que la tabla fusionada ya existe, es un volcado con metadatos, no un cálculo.

**Plan B:** el investigador principal cura el mismo archivo a mano. **Mismo esquema, mismos campos, mismos tipos**; solo cambian tres campos de procedencia. La página no distingue.

### Esquema propuesto (`statajson_<nodo>.json`)

```json
{
  "esquema": "ciep.nodo.serie/v1",
  "nodo": "deuda-publica",
  "procedencia": {
    "origen": "simulador",            // "simulador" | "manual" — ÚNICO campo que cambia de plan
    "version_simulador": "vX.Y.Z",    // tag del repo (Plan A) o versión de referencia (Plan B)
    "corte_datos": "AAAA-MM-DD",
    "log": "ruta/o/URL del log de la corrida",   // Plan A
    "responsable": null,               // Plan B: nombre; Plan A: null
    "fecha_curacion": null             // Plan B: AAAA-MM-DD; Plan A: null
  },
  "series": {
    "saldo": {
      "unidad": "mxn",
      "tipo": "mxn",                   // catálogo de tipos de escalar.ado
      "fuente": "SHCP/EOFP (SHRF5000)",
      "valores": [ {"anio": 1990, "valor": 0.0}, {"anio": "...", "valor": "..."} ]
    },
    "poblacion":       { "unidad": "personas", "tipo": "personas", "fuente": "CONAPO",    "valores": [] },
    "indice_precios":  { "unidad": "indice",   "tipo": "custom(%9.4f)", "base": "AAAA", "fuente": "INEGI/BIE", "valores": [] },
    "pib":             { "unidad": "mxn",      "tipo": "mxn",      "fuente": "INEGI/BIE", "valores": [] },
    "saldo_pc_nominal":{ "unidad": "mxnpc",    "tipo": "mxnpc",    "derivada_de": ["saldo","poblacion"], "valores": [] },
    "saldo_pc_real":   { "unidad": "mxnpc",    "tipo": "mxnpc",    "base": "AAAA", "derivada_de": ["saldo","poblacion","indice_precios"], "valores": [] },
    "saldo_pct_pib":   { "unidad": "pctpib",   "tipo": "pctpib",   "derivada_de": ["saldo","pib"], "valores": [] }
  },
  "criterios": { "...": "los siete campos de conciliación (Entrega 3)" },
  "capas_declaradas": ["deuda subnacional", "pasivo pensionario"],
  "notas": ["La serie oficial del SHRFSP comienza en 1990."]
}
```

Reglas de diseño:
- **Los valores derivados (per cápita, % PIB, real) viajan ya calculados** — la página solo hace aritmética de presentación, nunca deflacta ni divide series.
- Los campos `tipo` reutilizan el catálogo de `escalar.ado` (`mxn`, `mxnpc`, `pctpib`, `personas`, `anio`, `custom`) — un solo vocabulario de tipos en toda la cadena.
- Plan B = mismo archivo con `origen: "manual"`, `responsable` y `fecha_curacion` poblados y `log: null`. Cuando el Plan A esté listo se sustituye el archivo; nada aguas abajo cambia. El Plan B no puede volverse deuda permanente porque el esquema lo delata (`origen` es visible en el sello de la página).
- El ejemplo va con placeholders; **ninguna cifra de este plan es real**.

---

## 2.3 Qué se rompe hoy (Stata → LaTeX → Web), por criticidad

| # | Ruptura | Evidencia | Corrección propuesta | Esfuerzo |
|---|---|---|---|---|
| 1 | **El documento del Paquete no consume el contrato**: ningún `\input` de statalatex en 2026 (ni en ningún año salvo 2021) | Entrega 1 §2; preambles 2022–2026 | En el preamble 2027: `\input{statalatex_paquete}` + sustitución de literales por macros (los 42 grupos de conexión de §2.5) | Medio |
| 2 | **PEF.ado no registra escalares** (0 ocurrencias) — sin él no hay capítulo de gasto bajo contrato, ni anexos transversales, ni programas | grep verificado | Exponer en PEF.ado el bloque de escalares de gasto (neto/programable/no programable, variaciones, anexos 13/31/cambio climático, PP seleccionados, Ramo 33 por fondo y entidad) | Alto (es el 38% de cálculo nuevo de §2.5) |
| 3 | **No existe exportador de series** — `escalar`/`scalarlatex` manejan números sueltos; el nodo necesita series por año | diseño actual | Exportador `statajson` (§2.2) leyendo `master/*.dta`; primero para SHRFSP.dta | Medio |
| 4 | **`$export` vive comentado en `SIM.do`** (línea 57): el pipeline LaTeX es un switch manual sin documentar, con un solo destino (06_libro) | `SIM.do:57` | Destinos de export declarados por corrida (libro / paquete / web) y documentados en governance | Bajo |
| 5 | **Función medio ambiente ausente en GastoPC** — capítulo entero sin fuente | catálogo GPC | Agregar la función a GastoPC.ado (la fuente PEF ya está cargada) | Medio |
| 6 | **No hay exportador de tablas** — las 4 tablas de 2026 se teclearon | Entrega 1 §2d | Exportador de tabulares (statalatex de tablas); puede posponerse: no bloquea el nodo | Medio (posponible) |
| 7 | **Gráficas del Paquete se generan fuera del repo** (scripts personales, xlsx) | Entrega 1 §4 | Canonizarlas en `01_modulos/visualizations/` con los schemes ya existentes (`scheme-deuda`, etc.) | Medio |
| 8 | **La web del Paquete no tiene pipeline ni contenido versionable** | Entrega 1 §5 | §2.6 (opción A) | Medio |
| 9 | **Etiquetas de unidad tecleadas e inconsistentes en el Simulador web** | §2.7 | Derivarlas del payload del motor | Bajo |
| 10 | **Verificaciones de la serie 1990+** (variable canónica, moneda pre-1993) | §2.1 | Confirmar en SHRFSP.ado antes de publicar el nodo | Bajo |

---

## 2.4 El caso 2021 — el precedente recuperado

La investigación documental más la historia git cierran la cadena de evidencia:

**El generador SÍ existe y es el contrato mismo.** `scalarlatex.ado` está en el repo desde **2018-10-29** (commit `509d108` "Add files via upload"; actualizado en `052be3d` "Main Update 2020"). Su salida histórica con logname vacío es `statalatex_.tex` — y el preamble 2021 hace exactamente `\input{statalatex_}` (líneas 6 y 9, verificado). El `statalatex.tex` que hoy está en la carpeta del documento es esa salida copiada/renombrada a mano a Dropbox. **2021 no fue un experimento paralelo: fue una corrida normal del Simulador cuya salida se copió al documento.** Lo que nunca existió fue el paso automático motor→carpeta del documento; el eslabón era una persona copiando un archivo.

**Cruce de los 132 nombres con el presente:**
- ~22 coinciden exacto con el baseline actual de 228 y ~19 con escalares registrados (educación, salud, pensiones, SCN: `basicaPIB`, `imssPIB`, `pensionPIB`, `RemSalPIB`, `ConsInterPIB`…).
- El cruce estático subestima: **los bloques grandes de 2021 se generan hoy con nombres dinámicos**. Las 33 macros de aportaciones netas por decil (`AportacionesNetasI…X`, `inc…`, `dis…`) las registra hoy `Simulador.ado` (líneas 467/484/505: `escalar … \`varlist'\`decil2'`) y `SIM.do` sigue corriendo `Simulador AportacionesNetas`. El bloque GastoPC (montos y PIB de educación/salud/pensiones) coincide nombre a nombre. El bloque SCN sigue en `SCN.ado`.
- Lo que ya no se calcula: el gasto por capítulo económico (`servpers`, `obrapubl`, `matesumi`… ≈20 nombres) — GastoPC migró a clasificación funcional.

**¿Reproducible hoy?** En sustancia, sí: ~75–80% de los conceptos de 2021 siguen vivos en el motor, buena parte con nombre idéntico. No se reproduce el archivo byte a byte (formatos y ~20 nombres retirados), pero el flujo — corrida → `scalarlatex` → `\input` en el preamble — es exactamente el que está operando para `06_libro` hoy.

**¿Por qué no continuó?** No hay registro de la decisión: cero menciones en CHANGELOG/bitácoras, sin statalatex ni referencias comentadas en 2022, sin README. La evidencia estructural (etiquetada como hipótesis): el eslabón manual (copiar el archivo a la carpeta Dropbox del documento) dependía de una persona; en 2022 cambió la estructura del documento (nuevo preamble, nueva plantilla `ciepnew`) y el `\input` no migró. **Lección de diseño para 2027: el eslabón motor→documento debe ser parte de la corrida (`$export` apuntando a la carpeta del documento), no un paso humano.**

---

## 2.6 Estático o WordPress — recomendación: **Opción A (estático)**

| Criterio | A: estático generado desde JSON, versionado | B: nodos dentro de WordPress |
|---|---|---|
| Reproducibilidad | Total: página = f(JSON versionado + plantilla versionada) | Nula: el contenido vive en MySQL fuera de todo control; hoy ni siquiera se puede auditar qué cifras hay publicadas (Entrega 1 §4.7) |
| Versionado | git, junto al motor que produce el dato | Solo con plugins/exports parciales; historial no confiable |
| Reversión | La disciplina del Simulador ya existe: cutover atómico por symlink + health check + rollback (`publicar-vps.sh`, runbook) | Restaurar backup de BD: lento, total (no por página), y sin garantía de estado |
| Conexión mala / teléfono | HTML+CSS+JS mínimo sin backend; requisito 4 de la Entrega 3 se cumple por construcción | WordPress+Elementor: el sitio actual carga stack de page-builder (jets, addons); pesado por diseño |
| Indexación | Control directo de meta/sitemap por archivo (y evita repetir el `noindex` accidental que hoy afecta al WP) | Depende del ajuste global de WP (el error actual es evidencia del riesgo) |
| Quién edita qué | Investigadores editan JSON/plantillas vía repo (con verificadores como gate); nadie puede cambiar una cifra sin que quede trazado — que es exactamente el contrato | Cualquiera con acceso al panel puede editar una cifra sin rastro — es la definición del problema que este proyecto ataca |
| Riesgo de seguridad | Superficie mínima (archivos estáticos) | Amplía la superficie PHP/plugins ya observada |

**La nota de diseño de la ficha (Evolución · Incidencia · Implicaciones + entrada personal) no necesita nada de WordPress**: es una página por nodo con un JSON, tres secciones y un input numérico. El caso donde WP aporta (edición WYSIWYG de prosa por no técnicos) es justo el caso que el contrato quiere eliminar para las cifras.

**Convivencia durante la transición:**
- WordPress conserva `paqueteeconomico.ciep.mx/` tal cual: portada, PDFs históricos, kit de prensa. No recibe nodos nuevos.
- Los nodos viven bajo una ruta propia servida como estático: `paqueteeconomico.ciep.mx/nodos/<nodo>/` (alias en el vhost hacia una carpeta desplegada con la disciplina del Simulador), p. ej. `/nodos/deuda-publica/`, con su `statajson_deuda-publica.json` y CSV descargable al lado. Alternativa de menor fricción con el hosting actual: subdominio `nodos.paqueteeconomico.ciep.mx`; la elección depende de dónde termine hospedado el WP (faltante: hoy no está documentado) — la ruta en el mismo dominio es preferible por SEO y citabilidad.
- El repo agrega la carpeta fuente de los nodos (plantillas + JSON), y el deploy reutiliza el patrón `publicar-vps.sh` (backup → rsync → cutover → health check → rollback).
- Cuando un nodo sustituye a una página WP equivalente, la página vieja redirige 301 al nodo. El PDF sigue siendo el archivo; el nodo, la interfaz.

---

## 2.7 Etiquetas de unidad tecleadas en el Simulador web — censo

Las cuatro gráficas ApexCharts declaran el año base del deflactor a mano, **inconsistente entre gráficas y entre idiomas** (verificado; el mapeo etiqueta→gráfica se hizo siguiendo cada bloque `var options` hasta su `querySelector`):

| Gráfica (sección del sitio) | Contenedor | ES: archivo:línea → texto | EN: archivo:línea → texto |
|---|---|---|---|
| Crecimiento del PIB | `#pib-2` | `js/stataCalcula.js:768` → "billones MXN de 2021" | `js/stataCalcula-en.js:766` → "billones MXN de 2021" |
| El bono fiscal | `#line-1` | `js/stataCalcula.js:840` → "billones MXN de **2026**" | `js/stataCalcula-en.js:838` → "billones MXN de **2025**" |
| La proyección de recursos | `#stacked1` | `js/stataCalcula.js:935` → "billones MXN de **2024**" | `js/stataCalcula-en.js:933` → "billones MXN de **2025**" |
| La proyección de los compromisos | `#stacked2` | `js/stataCalcula.js:1035` → "billones MXN de **2024**" | `js/stataCalcula-en.js:1033` → "billions MXN **2025**" |

Tres de las cuatro gráficas declaran **años base distintos en español y en inglés para la misma serie**. Como mínimo una de las dos etiquetas de cada par es incorrecta; el dato graficado es el mismo payload del motor.

**Propuesta (sin corregir todavía):** el mecanismo ya existe a medias. El motor emite `ANIOBASE` en el output (`FiscalGap.ado:967`) y el JS ya consume `datos.ANIOBASE` para el texto del SHRFSP (`stataCalcula.js:435,439`). La corrección de fondo:
1. El motor emite el año base **por serie** en el payload (p. ej. `datos.ANIOBASE_PIB`, `datos.ANIOBASE_FISCAL` — o uno solo si todas las series comparten base, cosa que el motor sabe y el JS no debe adivinar).
2. Los cuatro `title.text` se construyen como `'billones MXN de ' + datos.ANIOBASE_*` (y su traducción), eliminando el literal.
3. Regla para el nodo (Entrega 3): la unidad viaja en el JSON (`series.*.unidad`, `base`) y la página la renderiza — nunca la escribe.

---

## 2.8 Ciclo de vida de `06_libro/public_html`

**Qué es (evidencia directa de archivos, sin tocar credenciales):**
- Es **`libro.ciep.mx`**: el sitio del libro institucional *"Finanzas Públicas Antropocéntricas"* (Ricardo Cantú, CIEP, 2026, 15º aniversario). Identificado por `06_libro/entrada_wordpress_libro.html` (borrador de entrada de blog con enlaces a `libro.ciep.mx`) y por el contenido de uploads (portadas del libro, `Version-03Mar-29-2026.pdf`).
- **WordPress 6.9.4** (actual). Plugins: **WooCommerce 10.7.0 + MercadoPago 8.7.17** (venta del libro / pagos), Elementor 4.0.2 + elementskit/jeg/metform, Mailchimp-for-WooCommerce, WP Mail SMTP Pro, YayMail, LiteSpeed Cache 7.8.1, Google Site Kit 1.176.0, duplicate-page, insert-headers-and-footers. Temas: hello-elementor, twentytwentyfive, twentytwentythree.
- **Uploads solo 2026/01–04** (735 archivos); archivo más reciente **2026-04-25**; logs de WooCommerce hasta 2026-04-25. La copia local es un snapshot de ~25 de abril de 2026. El sitio nació este año.
- **Procesa pagos**: la combinación WooCommerce+MercadoPago+wc-logs implica venta en producción (consistente con `06_libro/Donativos/.env` — que NO se inspeccionó, conforme a la regla).

**Contra el marco de ciclo de vida** (`politicas-institucionales.md`, Parte II):
- **No está entre los 11 productos pendientes de clasificar** (esa lista es previa: Pensiones, Gasto educativo, Vacuna contra la Desigualdad, etc.). Es un producto **posterior al marco** que aún no se ha incorporado al inventario — primera acción: darlo de alta en la clasificación.
- Su **documento bandera existe y es vigente**: el libro mismo (LaTeX en `06_libro/` + PDF publicado 2026). El micrositio es el contenedor comercial/difusión.

**Qué se perdería si se apagara:** el canal de venta/difusión del libro recién lanzado, las entradas/páginas (en la BD MySQL remota, no en esta carpeta), y los uploads 2026. El documento bandera NO se perdería (vive en LaTeX/PDF bajo la carpeta y el contrato del motor).

**Recomendación (propuesta a validar por dirección):** **SE MANTIENE** — sin aviso de desactualización. No es un micrositio viejo con datos caducos: es el producto comercial activo del año, con documento bandera vigente. Lo que sí, con tres condiciones operativas:
1. **Seguridad primero** (ya en la orden de trabajo): rotar credenciales (wp-config con `DB_HOST` remoto — prioridad dentro del punto 3 de la orden), y sacar la copia con credenciales de Dropbox (§3.3 de la política).
2. **Clasificarlo formalmente** en el marco de ciclo de vida (alta como producto: bandera = libro; micrositio = libro.ciep.mx) con responsable y criterio de revisión anual.
3. **Definir el ciclo del snapshot local**: la copia de abril en Dropbox no es backup (no se actualiza ni se restaura); o se documenta un mecanismo real de respaldo del sitio/BD, o se elimina la copia local dejando solo lo que el marco pide conservar.

**Explícitamente NO se recomienda decomisionar**: procesaría mal un canal de ingresos activo y el producto tiene meses de vida.

---

## Nota de diseño incorporada

La ficha del nodo adopta la plantilla que el equipo ya escribe desde 2019 — **Evolución · Incidencia · Implicaciones** — con la entrada personal antes y capas declaradas/conciliación/acervo/sello después. La recomendación 2.6-A la soporta sin fricción: cada sección es contenido estático alimentado por el mismo JSON, y la Incidencia por decil ya tiene productor en el motor (`Simulador.ado`: `AportacionesNetas<decil>`, `TasasEfectivas.ado`: `IVATE`, `ISRPFTE`…) — el mismo bloque que alimentó 2021.

---

## Faltantes

1. **Cifras publicadas hoy en el WP del Paquete**: siguen sin ser auditables (BD MySQL no disponible). No bloquea el plan; bloquea saber cuánto hay que corregir en el sitio viejo.
2. **Dónde está hospedado cada WordPress** (Paquete y libro): sin eso no se puede aterrizar el vhost/alias de `/nodos/` (§2.6) ni el mecanismo de backup real (§2.8.3).
3. **Definición exacta del Anexo 31 vs `gascuidados`** en GastoPC: verificación pendiente (§2.5, cuidados L40).
4. **Variable canónica y unidades 1990–1992 en `SHRFSP.dta`** (§2.1): verificación en el módulo antes de publicar la serie.
5. Las estimaciones de esfuerzo son cualitativas (bajo/medio/alto); no doy fechas — la conversión a calendario es del investigador principal con el cociente de §2.5.

---

*Fin de la Entrega 2. Pendiente de autorización. Nada commiteado.*
