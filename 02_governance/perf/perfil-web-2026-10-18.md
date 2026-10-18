# Perfil de tiempo del flujo web «Calcular» — 2026-10-18 (v8.12, fase 1)

**Alcance:** solo medición. Cero optimización, cero cambio de números, cero despliegue. Qué optimizar lo decide Ricardo con este reporte enfrente.
**Instrumento:** `05_scripts/perfilar-web.sh` (+ `perfilar-web.py`). Reproducible por cualquiera con un clon que tenga `master/`, `raw/` y `users/ricardo/` (ver §9).
**Base de código medida:** `origin/master` = `ffca008` (v8.11.0 + hotfix v8.10.1). El motor no se editó: los hooks viven en la copia de trabajo del `.do` de la sesión que genera el instrumento.
**Evidencia cruda (no versionada, en el clon medido):** `users/_perf/2026-10-18/` → `escenario.json`, `perfbase/`, `perfrun1..3/`, `perftraza/`, `piso-io/`, `wall.txt`, `identicos.txt`, `resumen.md`. El `resumen.md` generado se copia íntegro como anexo en `perfil-web-2026-10-18-resumen-generado.md`.

---

## 0. Resumen ejecutivo

| | |
|---|---|
| Tiempo de pared del flujo (local, StataNow 19.5 SE, 1 procesador, Mac M-series) | **31.5–35.0 s** por «Calcular» (3 corridas instrumentadas: 31.57 / 31.71 / 31.96 s; baseline sin hooks 32.49 s; primera corrida de la noche, caché frío: 34.98 s) |
| Arranque + cierre de Stata (`stata -b`, incluye `sysprofile.do`) | ≈ 0.2 s |
| Secciones con tiempo medible | **5 de 14**: FiscalGap 39.8 %, GastoPC 24.5 %, Simulador+egen 14.5 %, SankeySF×5 14.5 %, TasasEfectivas 4.5 % (+ merge §6 2.0 %) |
| I/O de disco (piso: `use`/`save` aislados de los mismos archivos) | **≈ 1.4 s de 31.5 s (4 %)** en esta máquina (NVMe, caché caliente). El resto es cómputo de Stata: `tabstat` (477 llamadas, 5.6 s), `collapse` (69, 4.9 s), `egen total` sobre 3.56 M filas (4.0 s), `generate/replace` sobre la micro (≈ 6 s). |
| Invariante al escenario (precacheable sin tocar metodología) | **≈ 11–12 s (36 %)**: PEF histórico dentro de FiscalGap (≈ 8.3 s), lectura/merge/conteos de población de GastoPC §1–2 (≈ 2 s), 24 collapses de `*RECprom` en FiscalGap (≈ 1.5 s). |
| Dependiente del escenario pero *lineal* en los inputs (precacheable con cambio metodológico → FLAG) | ≈ 10 s (31 %): GastoPC §3–8 (≈ 5.7), TasasEfectivas §7 (1.4), merge+egen de §6 (1.7), HH de FiscalGap §3 (≈ 1.0). |
| Dependiente no lineal (debe correr cada vez) | ≈ 9.5 s (30 %): SankeySF×5 (4.6), Simulador (3.3; perfiles por edad de AportacionesNetas), FiscalGap §4.2–7 (≈ 1.7; proyección, deuda, balance). |
| Compuertas | Instrumento corrió de punta a punta 3 veces (+ baseline + traza) sin error; `output.txt` de las 3 corridas instrumentadas **byte-idéntico** al baseline (`identicos.txt`). |
| Meta de trabajo < 15 s | Alcanzable **solo con precache del bloque invariante + sustitución de los recorridos lineales por escalares** (§8). Precache del invariante puro deja el run en ≈ 20 s; < 15 s exige además decisión metodológica sobre §3 de FiscalGap y GastoPC §3–8. |

Los tres cuellos de botella (§7): **(1)** `PEF` histórico dentro de `FiscalGap` (≈ 8.3 s, 26 %, invariante), **(2)** `GastoPC` (7.7 s, 25 %, mitad invariante / mitad lineal), **(3)** `SankeySF`×5 + `Simulador` (≈ 9.1 s, 29 %, dependiente).

---

## 1. Qué se midió

### 1.1 El objeto

El flujo que dispara `04_1_simuladorfiscal.ciep.mx/calculaStata.php` cuando el usuario pulsa «Calcular»:

1. toma los 154 valores del formulario más `idSession` (`$llaves`, `calculaStata.php:12-48`),
2. sustituye `{{llave}}` en `01_modulos/Web.Stata.do` → `users/<idSession>/<idSession>.do`,
3. `cd users/<idSession> && stata -b do <idSession>.do`,
4. lee `users/<idSession>/output.txt`.

No es la corrida completa de `SIM.do` (≈ 35 min): Web.Stata.do parte de `master/perfiles2027.dta` ya construido y de los `users/ricardo/bootstraps/250/*RECprom.dta` precomputados.

### 1.2 Escenario: el default nacional, tal como lo manda el sitio

El sitio carga la vista inicial de `users/ciepmx/output.txt` (= copia de `users/ricardo/output.txt` del deploy, `publicar-vps.sh` Fase 3b-ter) y, al pulsar «Calcular», manda **lo que hay en el DOM**. `perfilar-web.py escenario` reproduce ese mapeo (los 154 valores quedan en `escenario.json`):

| Llaves del formulario | De dónde salen | Referencia |
|---|---|---|
| `INGRESOS0,1,2,4,5,7..11,13..17` | `INGRESOS[k]` de output.txt, por **id** (`#INGRESOSk`) | `stataCalcula.js:514-555` |
| `CRECPIB2026..2032`, `CRECDEF2026..2032` | `CRECPIB[0..6]`, `CRECDEF[0..6]` | `stataCalcula.js:632-637` |
| 34 scalars de gasto (`iniciaA … gascuidados`) | `GASTOS[i]` por orden DOM de `.GASTOS` (los índices 10, 18, 24, 30, 35, 39 son subtotales sin id) | `stataCalcula.js:557-559`, `index.php` |
| `ingbasico18/65` | `GASTOSPC[38/39]` ≠ 0 → checkbox → `1` | `stataCalcula.js:618-630, 1552-1553` |
| `ISRTASA0..10` | `value=` del HTML (el JS hace `.html()`, no `.val()`) = `ISRTASA[]` | `stataCalcula.js:490-492` |
| `SE*`, `DED*`, `ISRMORA*`, `CSSIMSS*`, `CSSISSSTE*`, `IVAT*` | `ISRSUBS`, `ISRDEDU`, `ISRMORA`, `CSSIMSS`, `CSSISSSTE`, `IVA` | `stataCalcula.js:494-499, 638-668` |
| `DEUDA0` | `DEUDAPARAM[0]` | `stataCalcula.js:427` |
| `moduloCambio`, `moduloCambioIva` | hidden `value=""` → `lee_numero()` → `"0"` (submódulos ISR/IVA apagados) | `config.php`, `Web.Stata.do:231,243` |

Globals del motor: `bootstrap "250"`, `idbase "ricardo"` (Web.Stata.do:40-41); semilla `1111` (default de `Simulador.ado:50` cuando `$seed` está vacío, que es el caso tras `macro drop _all`).

### 1.3 Entorno local vs. producción

| | Local (este reporte) | Producción (VPS) |
|---|---|---|
| Stata | StataNow 19.5 SE, `c(processors)=1`, Apple Silicon, `born 12 Aug 2026` | Stata/MP 17 rev. 2024 |
| Disco | NVMe local, caché de archivos caliente (3 corridas seguidas) | A confirmar (reconocimiento-vps.md) |
| Raíz | clon `SimuladorCIEP-release-v8.10.0` (el del deploy v8.11: `master/`, `raw/`, `users/ricardo/` con 41 `*RECprom.dta`) | `/SIM/OUT/current/` |

**Los absolutos no se transfieren; el reparto relativo por sección sí.** Dos diferencias que pueden mover el reparto en el VPS: (a) el piso de I/O aquí es 4 % con caché caliente — en el VPS `master/PEF.dta` (1.7 GB) leído desde disco frío puede pesar varios segundos; (b) MP 17 paraleliza `collapse`/`egen`/`sort` sobre varios núcleos, y aquí corrió con 1. **No se corrió nada en el VPS**; medir ahí es decisión de Ricardo (§9 propone cómo y cuánto cuesta).

---

## 2. Cómo se midió

- **Timer de Stata por sección**: `_perf_mark "<sección>"` insertado en la copia del `.do` ante cada encabezado `**# n` / `** n.m` de Web.Stata.do (timers 51–64; los ado usan 1–15 y 33). `timer` de Stata es tiempo de pared con resolución de 0.01 s.
- **`set rmsg on`** desde §2 (después del `log using`/`log off` de §0, para que el `r;` no entre a `output.txt`) y `set rmsg off` antes de `output.do`: tiempo de cada comando de primer nivel del `.do`.
- **`profiler` de Stata por sección**: `profiler on/off/report/clear` en cada marca → tiempo **propio** (sin subprogramas) de cada programa ado llamado dentro de la sección (`tabstat`, `collapse`, `_gtotal`, `PEF`, …). Los builtin (`use`, `save`, `replace`, `generate`, `sort`) no aparecen: quedan en el tiempo propio del programa que los llama.
- **Traza** (`set trace on, tracedepth 3`, una corrida aparte, no cronometrada): inventario de archivos que abre el flujo (verbo, ruta, tamaño, veces, sección).
- **Piso de I/O**: `piso-io.do` generado desde el inventario hace `use` (y `save` a tempfile, para los que el flujo escribe) de cada archivo **aislado**, 3 repeticiones. Cota inferior del I/O del flujo con la misma caché.
- **3 corridas instrumentadas + 1 baseline sin hooks**; `cmp` de `output.txt` de cada instrumentada contra el baseline.
- Tiempo de pared externo (shell, `time.time()` alrededor de `stata -b do`) para medir arranque y cierre de Stata.

Hooks inertes ya existentes en el motor (no se tocaron, el profiler los desglosa): `timer on 4` (LIF), `5` (PEF, SHRFSP), `7` (Simulador), `8` (TasasEfectivas), `9` (GastoPC), `11` (FiscalGap), `3` (PIBDeflactor), `33` (SCN).

---

## 3. Resultados: tiempo por sección

Media y desviación estándar (poblacional) de las 3 corridas instrumentadas (`perfrun1..3`), segundos de pared del `timer` de Stata.

| # | Sección de Web.Stata.do (líneas) | Media (s) | DE | % | I/O (piso) | Cómputo | Clasificación | Precache | Por qué |
|---|---|---:|---:|---:|---:|---:|---|---|---|
| 1 | §0 SET UP: `sysdir`, `cd`, scalars, `log using` (7-47) | 0.00 | 0.00 | 0.0 | — | — | invariante | no aplica | nada que ahorrar |
| 2 | §2 ECONOMÍA: 21 globals `pib/def/inf` (52-80) | 0.00 | 0.00 | 0.0 | — | — | **dependiente** (CRECPIB/CRECDEF del formulario) | no aplica | define los inputs; costo cero |
| 3 | §3.1 `LIF` + collapse + `save LIF.dta` (89-97) | 0.07 | 0.01 | 0.2 | ≈0 | 0.07 | invariante salvo pibY (FLAG-1) | sí, trivial | `master/LIF.dta` (1 917 filas); `PIBDeflactor` lee `master/PIBDeflactor.dta` y aplica `$pib/$def` |
| 4 | §3.1.1–3.1.7 scalars `*PIB`, matrices ISR/SE/DED/PM/CSS/IVAT/IEPST, submódulos (106-247) | 0.00 | 0.00 | 0.0 | — | — | dependiente (15 `INGRESOS*`, matrices) | no aplica | con `moduloCambio=0` los submódulos no corren; definir matrices cuesta 0 |
| 5 | §3.1.8 `TasasEfectivas, enigh` → `save ingresos.dta` (250) | 1.43 | 0.06 | 4.5 | 0.06 lee perfiles + 0.11 escribe ingresos = 0.17 | 1.26 | **dependiente lineal** (15 `*PIB` × pibY) | **FLAG-2** | `Distribucion.ado`: `k_Sim = k × (kPIB/100·pibY) / Σk` — escala un perfil fijo; `SCN` (0.14 s) y `PIBDeflactor` son invariantes salvo pibY |
| 6 | §3.2 `PEF` (258-263) | 0.00 | 0.00 | 0.0 | — | — | — | — | **No corre**: está dentro del bloque `/** … **/` que abre la línea 257 y cierra la 265 (ver §6, observación O-1) |
| 7 | §3.2.1 34 scalars de gasto (266-311) | 0.00 | 0.00 | 0.0 | — | — | dependiente | no aplica | costo cero |
| 8 | §3.2.2 `GastoPC` → `save gastos.dta` (315) | 7.73 | 0.26 | 24.5 | 0.06 perfiles + 0.10 households + 0.32 escribe gastos = 0.48 | 7.25 | **mixta**: §1–2 invariante (≈ 2 s); §3–8 dependiente lineal (≈ 5.5 s) | §1–2 **sí**; §3–8 **FLAG-3** | ver §4.2 |
| 9 | §3.3 matrices SHRFSP + 119 globals + `tasaEfectiva` (328-377) | 0.00 | 0.00 | 0.0 | — | — | invariante salvo `DEUDA0` | no aplica | costo cero |
| 10 | §6 `use ingresos` + `merge gastos` + `save aportaciones` (385-391) | 0.62 | 0.01 | 2.0 | 0.03 + 0.06 + 0.23 = 0.32 | 0.30 | dependiente (de 5 y 8) | sigue a 5 y 8 | 308 598 × 152 variables; `isr_mod`/`iva_mod` no existen (capture) |
| 11 | §6.7 5 `egen rsum` + `Simulador … reboot` (B=1) + `save aportaciones` (395-413) | 4.56 | 0.06 | 14.5 | 0.04 concentrado + 0.06 Poblacion + 0.23 escribe = 0.33 | 4.23 | **dependiente no lineal** (perfiles por edad/sexo/decil de `AportacionesNetas`) | no | ver §4.4 |
| 12 | §7.1 `FiscalGap` (422) | 12.55 | 0.17 | 39.8 | 0.32 PEF.dta + 0.03 ingresos + 0.06 gastos + RECprom ≈ 0.42 | 12.13 | **mixta**: PEF histórico ≈ 8.3 s y 24 collapses RECprom ≈ 1.5 s invariantes; HH §3 ≈ 1 s lineal; proyección/deuda/balance ≈ 1.7 s dependiente | PEF **sí**; RECprom **sí**; HH **FLAG-3**; resto no | ver §4.1 |
| 13 | §7.2 `SankeySF.do` × 5 cortes (426-428) | 4.56 | 0.01 | 14.5 | 10 × `use aportaciones` (lectura en caché ≈ 0.6) | 3.9 | dependiente (agrega `aportaciones.dta` por corte) | no (ver §4.3) | 25 `collapse` sobre la micro (2.7 s) + 360 `tabstat` (1.0 s) |
| 14 | §8 `output.do` (`log on` → `output.txt` + 4 `filefilter`) (435-436) | 0.00 | 0.00 | 0.0 | ≈0 | ≈0 | dependiente | no aplica | 52 KB |
| | **Total secciones** (= `timer 1` de Web.Stata.do) | **31.53** | 0.16 | 100 | **≈ 1.35** | **≈ 30.2** | | | |
| | Arranque + cierre de Stata (pared − timer 1) | 0.19 | 0.02 | | | | | | `sysprofile.do` local pide proyecto y es ignorado en batch; en el VPS no existe |

Columnas "I/O (piso)" y "Cómputo": el piso es la suma de los `use`/`save` aislados de los archivos que la sección abre (tabla §5); "Cómputo" = media − piso. Con caché caliente el piso es cota inferior, no estimación del VPS.

**Varianza:** DE ≤ 0.26 s en todas las secciones; el run completo varía ±0.2 s entre corridas consecutivas y ≈ +3 s en la primera corrida de la sesión (caché frío: 34.98 s vs 32–33 s después). El contador de 35 s del sitio (`stataCalcula.js:1661`) coincide con el caso frío local.

---

## 4. Desglose de las secciones pesadas (profiler por sección, tiempo propio, media de 3)

### 4.1 §7.1 FiscalGap — 12.55 s (39.8 %)

| Programa (propio) | Llamadas | s | % FG | Dónde | Clasificación |
|---|---:|---:|---:|---|---|
| `PEF` | 1 | 4.39 | 35 | `FiscalGap.ado:401` → `PEF.ado:120` `use master/PEF.dta` **completo** (3 562 813 filas × 43 vars, 1.7 GB), `g cuotasTOT`, `replace`, `collapse … by(anio divCIEP transf_gf)` (:131), `egen max` (:181), `collapse` (:342) | **invariante** (datos históricos; `anio(2027) by(divCIEP) desde(2016)` son constantes en el flujo). Solo la conversión a % del PIB usa pibY (FLAG-1) |
| `_gtotal` (`egen … = sum() by(anio)`) | 3 | 3.95 | 32 | `PEF.ado:123` y `:127` sobre los 3.56 M de filas (la 3.ª es `LIF.ado:135`, 1 917 filas) | **invariante** |
| `collapse` | 37 | 2.15 | 17 | 24 en los loops `_FGrecprom` (`:120`, `:430`: 101 filas cada uno, ≈ 0.05 s de overhead fijo por `collapse`), 13 sobre tablas anuales (`:110,177,332,382,477,637,700`) y las de PEF/LIF | 24 **invariantes** (promedios de réplicas del escenario base, no dependen del formulario); 13 dependientes baratas |
| `tabstat` | 52 | 0.89 | 7 | 9 en §3 HOUSEHOLDS (`:68`, sobre la micro 308 598 × 152), 24 en los loops RECprom (`:129`, `:437`), resto anuales | 9 **lineales** (FLAG-3): recuperan Σ gasto por categoría, que por construcción de `GastoPC` es `scalar(X)/100·pibY`; 24 invariantes |
| `merge` | 32 | 0.57 | 5 | `:64` ingresos⨝gastos (micro, ≈ 0.5 s), 15 + ≈ 14 merges 1:1 anuales | el de la micro es dependiente (viene de 5 y 8) |
| `egen`, `_gsum`, `FiscalGap` propio, `SHRFSP`, `LIF`, `PIBDeflactor`, `_FGrecprom` | | ≈ 0.6 | 5 | §5.6–7 deuda (`tasaEfectiva` = `DEUDA0`, `gascosto`), §7 balance | dependiente (barato) |

Lectura: **≈ 8.3 s de los 12.55 s de FiscalGap son `PEF` reconstruyendo la serie histórica anual de gasto desde el microdato de 3.56 M de filas**, igual en cada clic. Lo que FiscalGap consume de PEF es `r(divCIEP)`, `r(k)`, `r(kC)` y la base anual `anio × divCIEP` (:402-420): unas decenas de filas.

### 4.2 §3.2.2 GastoPC — 7.73 s (24.5 %)

| Programa (propio) | Llamadas | s | % | Dónde | Clasificación |
|---|---:|---:|---:|---|---|
| `GastoPC` propio | 1 | 3.84 | 50 | `g`/`replace` sobre 308 598 filas: §2.1–2.9 indicadores (`alum_*`, `benef_*`, `der_*`, `pens_*`, cuidados, `pob`) y §3–8 asignación `Var = Var + scalar(XPC)*indicador` por 34 categorías; `save gastos.dta` (233 MB, 0.32 s) | §2 **invariante**; §3–8 **lineal** en `scalar(X)/100·PIB` (`:270,300,…,1516`) |
| `tabstat` | 20 | 2.78 | 36 | `:81,113,161,188,207,241,247,254` conteos de población con `[fw=factor]` (§2, ≈ 1.1 s), `:1143,1489-1507,1580` (§6–8) | §2 **invariante**; los demás invariantes también (cuentan personas, no gasto) |
| `Distribucion` | 9 | 0.34 | 4 | asignaciones vía perfil relativo (`Distribucion.ado`: 1 `tabstat` + 1 `g`) | lineal |
| `merge` | 1 | 0.32 | 4 | `:76` perfiles2027 ⨝ `master/2024/households.dta` (527 MB, `keepusing` 12 vars) | **invariante** |
| `_gtotal`, `_gcount` | 3 | 0.39 | 5 | `:118,667,668` `egen … by(folioviv foliohog)` | invariante |
| `PIBDeflactor` | 1 | <0.1 | | `:46` | salvo pibY (FLAG-1) |

Lectura: **≈ 2 s de GastoPC (lectura, merge con households, conteos de población) no dependen de ningún input**; los ≈ 5.5 s restantes son 34 pasadas de `replace` sobre la micro que multiplican un indicador fijo por un escalar del formulario, más `save gastos.dta`.

### 4.3 §7.2 SankeySF × 5 — 4.56 s (14.5 %)

Por corte (`decil grupoedad sexo rural escol`): `use aportaciones.dta` dos veces (`SankeySF.do:203,286`; 285 MB, 0.06 s cada una en caché), 5 `collapse (sum)` sobre la micro por corte (`:109,160,217,314,451,467`; 25 en total, 2.71 s, ≈ 0.11 s cada uno), 72 `tabstat` (`:274,294-302,388`; 360 en total, 1.01 s), `SankeySumSim` (0.02 s cada uno). Todo depende de `aportaciones.dta` del escenario. Observación (no decisión): los 5 cortes recorren la misma base 10 veces para producir 5 JSON de ≈ 1 MB; un solo `collapse` por los 5 cortes a la vez produciría lo mismo — es optimización de **implementación**, no de metodología, pero sigue siendo cambio al motor: fuera de esta sesión.

### 4.4 §6.7 egen + Simulador — 4.56 s (14.5 %)

`egen rsum` × 5 sobre la micro (`Web.Stata.do:395-405`, 1.1 s por rmsg); `Simulador` 3.28 s: propio 1.93 s (Mata `simci`, perfiles por edad × sexo, `collapse`s a `bootstraps/1/*.dta`), `_growtotal` 0.92 s, `GroupFromSort`/`_ggroup` 0.71 s (`egen group(folioviv foliohog)`, `group(upm)`, `group(est_dis)`: `Simulador.ado:336,365-366`), `merge` 0.36 s (`:354` `raw/ENIGH/2024/concentrado.dta` por `upm est_dis`, `:404` `master/Poblacion.dta`). Dependiente no lineal (los perfiles de `AportacionesNetas` por edad son el producto). Los tres `egen group` y el merge con `concentrado.dta` (≈ 1 s) son identificadores estructurales de la ENIGH, iguales en cada clic: candidato menor a precache (bastaría traerlos ya en `perfiles2027.dta`) — es cambio de insumo, no de método: FLAG-4.

### 4.5 §3.1.8 TasasEfectivas — 1.43 s (4.5 %)

`SCN` 0.14 s (lee `master/SCN.dta`, invariante salvo pibY), `use (24 vars) perfiles2027.dta` 0.06 s, 15 × `Distribucion` (15 `tabstat` 0.84 s + 15 `g` 0.29 s), `save ingresos.dta` 0.11 s. Cada `k_Sim` es el perfil `k` reescalado al macro `kPIB/100·pibY` del formulario (`TasasEfectivas.ado:335`, `Distribucion.ado`).

---

## 5. I/O vs. cómputo

Inventario de la traza (archivos ≥ 1 MB; completo en el anexo) y piso de I/O aislado (media de 3, caché caliente):

| Archivo | MB | Filas × vars | Lo abre | Veces/run | Piso `use` (s) | Piso `save` (s) |
|---|---:|---|---|---:|---:|---:|
| `master/PEF.dta` | 1 696 | 3 562 813 × 43 | FiscalGap → PEF (`use in 1` + `use` completo) | 2 | 0.32 | |
| `master/2024/households.dta` | 527 | 308 598 × 304 | GastoPC (merge, 12 vars) | 1 | 0.10 | |
| `users/<id>/aportaciones.dta` | 286 | 308 598 × 152 | §6 (save ×2), SankeySF (use ×10) | 12 | ≈0.06 | 0.23 |
| `users/<id>/gastos.dta` | 234 | 308 598 × 131 | GastoPC (save), §6 y FiscalGap (merge) | 3 | 0.06 | 0.32 |
| `master/perfiles2027.dta` | 128 | 308 598 × 88 | TasasEfectivas (24 vars), GastoPC | 2 | 0.06 | |
| `raw/ENIGH/2024/concentrado.dta` | 88 | 91 414 × 126 | Simulador (merge `upm est_dis`) | 2 | 0.04 | |
| `users/<id>/ingresos.dta` | 83 | 308 598 × 41 | TasasEfectivas (save), §6 y FiscalGap (merge) | 3 | 0.03 | 0.11 |
| `master/Poblacion.dta` | 26 | | Simulador | 1 | 0.06 | |
| 41 × `users/ricardo/bootstraps/250/*RECprom.dta` + `PIBDeflactor` (×14) + `LIF` + `SHRFSP` + `SCN` + `bootstraps/1/*` | < 1 cada uno | 101 × 14 | FiscalGap, todos | ≈ 65 | 0.004 total | |
| **Suma del piso** | | | | | **≈ 1.35 s** | |

Conclusión local: el flujo es **CPU-bound** (96 %). Cada «Calcular» escribe ≈ 890 MB a `users/<id>/` (ingresos 83 + gastos 234 + aportaciones 286 × 2) y lee ≈ 3.5 GB; en esta máquina eso cuesta ≈ 1.4 s. **En el VPS esta proporción puede ser distinta** (disco, caché compartida entre sesiones concurrentes): es el primer dato que conviene obtener allá (§9).

---

## 6. Clasificación invariante / dependiente, línea por línea

Criterio: una pieza es **invariante** si ningún valor de `$llaves` (`calculaStata.php:12-48`) cambia su resultado; **lineal** si el resultado es un perfil/base fija multiplicada por escalares del formulario; **dependiente** si no. La dependencia a través de `pibY`/`deflator` (CRECPIB/CRECDEF 2026-2027 → `PIBDeflactor.ado:205-228, 296-303`) se marca aparte porque atraviesa casi todo (FLAG-1).

| Pieza | Archivo:línea | Inputs del formulario que la tocan | Clase |
|---|---|---|---|
| `LIF` (3.1 y dentro de FiscalGap 4.1) | `LIF.ado:30,77,135`; `FiscalGap.ado:97` | ninguno directo; `% PIB` vía `PIBDeflactor` ← `$pib2026-27`, `$def2026-27` | invariante salvo pibY |
| `SCN` | `TasasEfectivas.ado:22` → `SCN.ado:42,58` | ídem | invariante salvo pibY |
| `PIBDeflactor` (14 llamadas) | `PIBDeflactor.ado:205-228` (`$def`, `$inf`), `:296-303` (`$pib`) | `CRECPIB2026..2032`, `CRECDEF2026..2032` | **dependiente** (barato: 0.06 s por llamada; pero propaga pibY) |
| `TasasEfectivas` §7 | `TasasEfectivas.ado:320-340`, `Distribucion.ado` | `INGRESOS0,1,2,4,5,7-11,13-17` (vía `scalar(kPIB)`) y pibY | **lineal** |
| `GastoPC` §1–2 (PIBDeflactor, use perfiles, merge households, 9 tabstat de población, `egen` por hogar) | `GastoPC.ado:46-254` | ninguno (solo `anioPE`, constante) | **invariante** |
| `GastoPC` §3–8 (34 asignaciones) | `GastoPC.ado:270-1516` (`scalar(X)/100*PIB` → `escalar XPC` → `g/replace`) | los 34 scalars de gasto + `ingbasico18/65` + pibY | **lineal** (cada `Var` = Σ indicador × escalar) |
| `GastoPC` conteos §6–8 (`tabstat pob`, `factor if edad…`, `ing_subor if scian=="93"`) | `GastoPC.ado:1143,1489-1507,1580` | ninguno | invariante |
| §6 `use`/`merge`/`save` | `Web.Stata.do:385-391` | hereda de las dos bases | dependiente (de bases lineales) |
| §6.7 `egen rsum` | `Web.Stata.do:395-405` | ídem | dependiente (lineal) |
| `Simulador` (perfiles por edad; `bootstraps/1/`) | `Simulador.ado` (`simci` Mata, `:478-787`) | `AportacionesNetas` (todo) | **dependiente no lineal** |
| `Simulador`: `egen group` ×3, merge `concentrado.dta`, `use Poblacion.dta` | `Simulador.ado:336,354,365-366,404` | ninguno | invariante (FLAG-4) |
| `FiscalGap` §1 PIB, §2 `SHRFSP` | `FiscalGap.ado:36-54`, `SHRFSP.ado:64` | `$shrfsp*`, `$rfsp*` (constantes en el template, :328-373), pibY | invariante salvo pibY |
| `FiscalGap` §3 HOUSEHOLDS (merge micro + 9 tabstat) | `FiscalGap.ado:63-85` | gasto scalars (vía `gastos.dta`) y pibY | **lineal** (FLAG-3) |
| `FiscalGap` §4.1 `LIF`, §4.2 loop 15 × (`_FGrecprom`, `collapse`, `tabstat`, tendencias) | `FiscalGap.ado:97-146` | ninguno (RECprom = escenario base de `idbase`, `bootstrap`) | **invariante** |
| `FiscalGap` §4.2 ancla y proyección | `FiscalGap.ado:150-163` (`scalar(kPIB)`, `pibY`) | `INGRESOS*`, CRECPIB/CRECDEF | dependiente (barato) |
| `FiscalGap` §5.1 `PEF` | `FiscalGap.ado:401` → `PEF.ado:120-342` | ninguno (`% PIB` vía pibY) | **invariante** salvo pibY |
| `FiscalGap` §5.2 loop 9 × RECprom gasto | `FiscalGap.ado:429-455` | ninguno | **invariante** |
| `FiscalGap` §5.2 ancla `HH` | `FiscalGap.ado:458-462` | gasto scalars (vía §3) | dependiente (barato) |
| `FiscalGap` §5.6–5.9 deuda | `FiscalGap.ado:699-873` | `DEUDA0` (`tasaEfectiva`, :752-758), `gascosto` (:738-748), `$shrfsp*`, pibY | dependiente (barato) |
| `FiscalGap` §4.3–4.6, 5.3–5.5, 7 | resto | proyecciones | dependiente (barato) |
| `SankeySF.do` × 5 | `SankeySF.do:203-487` | `aportaciones.dta` | dependiente |
| `output.do` | `01_modulos/output.do` | escalares/globals | dependiente (0 s) |

Observaciones (hechos encontrados al leer; no son decisiones):

- **O-1.** En `Web.Stata.do` la línea 257 `/**` abre un comentario de bloque que cierra la línea 265 (`** 3.2.1 … **/`): `set scheme ciep` y la llamada a `PEF` de §3.2 **no se ejecutan** en el flujo web (el timer de la sección marca 0.00 y en el log no hay salida de PEF ahí). `FiscalGap` llama a `PEF` por su cuenta (`:401`), así que el resultado no se ve afectado, pero el template da a entender que §3.2 corre.
- **O-2.** `output.txt` del flujo web default **no coincide** con el `users/ricardo/output.txt` publicado (p. ej. `PIBY` 39 415 135 710 357 vs 39 419 415 318 851; `INCD` distinto). Dos causas visibles sin investigar más: el sitio devuelve `CRECPIB`/`CRECDEF` redondeados a 1 decimal (`output.do` imprime `%8.1f`: 1.4127 → 1.4, 1.9983 → 2.0) y `SIM.do:484` llama `Simulador … if k != 0` mientras `Web.Stata.do:412` no filtra. No afecta a este perfil (ambas corridas recorren el mismo código), pero es el estado real de «Calcular» con el default: FLAG-5.
- **O-3.** La corrida web escribe `users/<id>/LIF.dta` (§3.1) que nadie vuelve a leer en el flujo (la traza no registra ninguna lectura).

---

## 7. Los tres cuellos de botella

1. **`PEF` histórico dentro de `FiscalGap` — ≈ 8.3 s (26 % del run), invariante.** `PEF.ado:120-131` carga `master/PEF.dta` completo (3.56 M filas, 1.7 GB), hace dos `egen sum … by(anio)` sobre todas las filas y colapsa a `anio × divCIEP × transf_gf`. Produce una tabla de decenas de filas que es la misma en cada clic (solo cambia la división entre pibY al expresarla en % del PIB, que ocurre después y es barata). Es el candidato de precache más limpio: sin tocar metodología, el resultado del `collapse` de `:131` (o de `:342`) para `anio(2027) by(divCIEP) desde(2016)` es un artefacto del deploy, como ya lo son los `*RECprom.dta`.
2. **`GastoPC` — 7.7 s (25 %).** ≈ 2 s invariantes (merge con `households.dta`, 9 `tabstat` de población, `egen` por hogar) y ≈ 5.5 s de asignación lineal + `save gastos.dta` (234 MB). La parte invariante es precacheable sin decisión metodológica (traer `households` ya pegada en `perfiles2027.dta` y los conteos como escalares del deploy). La parte lineal solo se reduce cambiando *cómo* se calcula (FLAG-3).
3. **`SankeySF` × 5 + `Simulador` — ≈ 9.1 s (29 %), dependiente.** Son el producto del escenario (perfiles por edad y flujos por corte) y deben correr cada vez; el margen está en implementación (10 `use` de 286 MB y 25 `collapse` sobre la misma base para 5 JSON; `egen group` repetidos en `Simulador`), no en precache.

En suma: **invariante puro ≈ 12 s** (PEF 8.3 + GastoPC §1–2 ≈ 2 + RECprom collapses ≈ 1.5), **lineal ≈ 10 s**, **dependiente ≈ 9.5 s** (suma ≈ 31.5).

---

## 8. Meta realista (propuesta, no implementación)

| Escenario | Qué requiere | Tiempo local estimado | Decisión |
|---|---|---|---|
| Hoy | — | 31.5–35 s | — |
| **A. Precache del invariante puro** | Artefactos del deploy (como `*RECprom.dta`): (a) tabla anual de `PEF` para `anio(2027) by(divCIEP) desde(2016)` consumida por `FiscalGap:401-420`; (b) `perfiles2027.dta` con las 12 variables de `households` ya pegadas + conteos de población de `GastoPC §2` como escalares; (c) los 24 `collapse` de RECprom precolapsados. Ningún número cambia: son los mismos cálculos movidos al deploy. | **≈ 20 s** (−11.5) | técnica; no toca metodología. Requiere que `FiscalGap`/`GastoPC` acepten el artefacto (cambio al motor, con compuerta de byte-identidad de `output.txt`) |
| **B. A + sustituir los recorridos lineales por escalares** | `FiscalGap §3` (HH) toma Σ gasto por categoría de los escalares (`scalar(X)/100·pibY`) en vez de `merge` + 9 `tabstat` de la micro; `GastoPC §3–8` y `TasasEfectivas §7` siguen produciendo las bases (las necesitan `Simulador` y `SankeySF`) pero con una sola pasada vectorizada en lugar de 34 `replace`. | **≈ 14–16 s** | **metodológica** (FLAG-3): aunque algebraicamente equivalente, cambia la ruta por la que se obtiene cada cifra y hay que demostrar byte-identidad o aceptar diferencias de redondeo |
| **C. B + implementación de Sankey/Simulador** | 1 `use` + 1 `collapse` por los 5 cortes; `egen group`/`concentrado` precalculados en perfiles (FLAG-4); no escribir `aportaciones.dta` dos veces. | **≈ 10–12 s** | implementación; sin cambio de método |
| D. Hardware/Stata | Stata/MP con ≥ 2 núcleos en el VPS para `collapse`/`egen`/`sort`; disco con caché caliente de `PEF.dta`. | factor desconocido hasta medir allá | depende de §9 |

La meta de trabajo **< 15 s es realista solo con A + B** (y B es decisión de Ricardo). **A sola** deja el run en ≈ 20 s sin tocar un número. Con C se baja de 12 s. Todo lo anterior es local; el VPS puede añadir o quitar segundos de I/O (§9).

---

## 9. Siguiente paso propuesto: medir en el VPS

- **Qué:** correr `perfilar-web.sh --root /SIM/OUT/current --runs 3 --traza --sin-base` (o con baseline) como `www-data`/`ciepmx` en una ventana sin usuarios, sobre el deployment vigente. El script es portable (bash + python3 + `stata-mp`); hay que pasar `--stata /usr/local/stata17/stata-mp`. Escribe en `users/_perf/<fecha>/` y `users/perf*/` del deployment (≈ 900 MB por sesión; borrarlos al terminar con `--limpiar` o a mano).
- **Costo:** 5 corridas × ≈ 35–60 s + piso de I/O ≈ 6–8 min de Stata en el VPS; cero cambios al deployment (solo archivos nuevos bajo `users/`). Riesgo: ocupar la única licencia MP durante esos minutos — si un usuario pulsa «Calcular» en ese lapso, su corrida y la medición se estorban mutuamente (medir fuera de horario).
- **Qué responde:** el piso de I/O real (sobre todo `PEF.dta` 1.7 GB en frío), cuánto compensa MP la CPU, y si el reparto 40/25/15/15 se sostiene. Con eso la tabla de §8 pasa de estimación local a plan.
- **No se hizo en esta sesión** por candado explícito (producción no se toca sin decisión de Ricardo).

---

## 10. FLAGs (decisiones que no son del agente)

| # | Qué | Por qué es metodología |
|---|---|---|
| **FLAG-1** | Casi todo lo "invariante" depende de `pibY`/`deflator` 2026-2027 (`CRECPIB2026/2027`, `CRECDEF2026/2027`) al convertir pesos → % PIB o % PIB → pesos. Un precache puede (a) guardar en pesos y dividir al final, o (b) indexarse por esos 4 valores. | (a) cambia el orden de operaciones (riesgo de diferencias de redondeo en `output.txt`); (b) solo sirve si el usuario no mueve el marco macro. |
| **FLAG-2** | `TasasEfectivas §7` es un reescalado lineal de 15 perfiles; podría hacerse en una pasada o precalcularse por unidad de % PIB. | Cambia la ruta de cálculo de `ingresos.dta`, insumo de todo lo demás. |
| **FLAG-3** | `FiscalGap §3` recorre 300 MB de micro para obtener totales que por construcción son `scalar(X)/100·pibY`; `GastoPC §3–8` hace 34 `replace` sobre la micro. Sustituirlos por escalares / una pasada vectorizada es algebraicamente igual. | Igualdad algebraica ≠ igualdad numérica en coma flotante; además `GastoPC` reparte el gasto entre categorías con reglas (anclas 602513/1169476, etc.) cuyo total puede no ser exactamente el escalar. Debe validarse contra `output.txt`. |
| **FLAG-4** | Identificadores estructurales (`egen group` de hogar/UPM/estrato, merge con `concentrado.dta`) podrían venir ya en `perfiles2027.dta`. | Es cambio de insumo (`PerfilesSim.do`), con el candado del manifiesto de assets. |
| **FLAG-5** | `output.txt` del «Calcular» default difiere del publicado (O-2). | No es tema de rendimiento, pero cualquier compuerta de byte-identidad futura debe fijar contra cuál de los dos se compara. |
| **FLAG-6** | ¿Se precachea por deploy (un artefacto para todos) o por sesión (primer clic lento, siguientes rápidos)? El invariante puro admite lo primero; lo lineal (FLAG-2/3) solo lo segundo o el rediseño. | Define la arquitectura de la fase 2. |

---

## 11. Cómo reproducir

```bash
# en un clon con master/, raw/, users/ricardo/output.txt y users/ricardo/bootstraps/250/*RECprom.dta
bash 05_scripts/perfilar-web.sh --root <clon> --runs 3 --traza \
     --evidencia <clon>/users/_perf/$(date +%F)
# salida: <evidencia>/resumen.md (+ escenario.json, perfbase/, perfrun*/, perftraza/, piso-io/, identicos.txt)
# exit 2 si algún output.txt instrumentado difiere del baseline
```

Corrida de este reporte: `--root /Users/ricardo/CIEP_Simuladores/SimuladorCIEP-release-v8.10.0` (clon del deploy v8.11 en `ffca008`), 2026-10-18 00:58–01:02, StataNow 19.5 SE.
