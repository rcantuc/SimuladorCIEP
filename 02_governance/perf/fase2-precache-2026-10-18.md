# Fase 2 del plan de rendimiento del «Calcular» — 2a precache de lo invariante, 2b forma cerrada tras interruptor (2026-10-18)

**Base:** `perfil-web-2026-10-18.md` (fase 1, PR #28): ~32 s por «Calcular», de los cuales ≈ 12 s eran
invariantes al escenario y ≈ 10 s lineales en los inputs.
**Entregable:** un PR con dos commits. 2a hace el «Calcular» más rápido **sin mover un número por
defecto**; 2b deja una opción **apagada** y la medición para que Ricardo decida si se enciende.
**Evidencia cruda:** `~/CIEP_Simuladores/diag-v8.12-fase2-2026-10-18/` (no versionada; índice en §7).
**Entorno:** StataNow 19.5 SE, Mac. Datos: clones APFS de `master/`, `raw/` y `users/ricardo/` del clon
del deploy v8.11.0 (`SimuladorCIEP-release-v8.10.0`). Los tiempos de pared de §2–§4 se midieron con
dos corridas batch de Stata en paralelo en la misma máquina: son ≈ 1–2 s más altos que en reposo.

---

## 0. Resumen

| | Antes (ffca008) | 2a (default de este PR) | 2a + 2b encendido |
|---|---:|---:|---:|
| «Calcular» default, pared local | 31.5–35 s | **≈ 19.4 s** (18.5–20.3) | **≈ 16.1 s** (15.9–16.3) |
| `output.txt` vs antes | — | **byte-idéntico** | byte-idéntico |
| 5 `sankey-*.json` vs antes (web) | — | 232 de 520 enlaces distintos en el 15º–16º dígito, Δ rel máx 2.8e-14, **0 visibles** (§5, FLAG-7) | idéntico a 2a (0 bytes distintos) |
| Batch `SIM.do` (entidad vacío) vs v8.11.0 `566c31ea…` | — | **`output.txt` y los 5 sankeys byte-idénticos** (8 427 valores, 0 distintos) | **byte-idénticos** (0 de 8 427) |

Los < 15 s **no se alcanzan** con 2a + 2b (≈ 16 s). Lo que queda es dependiente del escenario y es
implementación, no precache ni álgebra: `Simulador` + `SankeySF` ≈ 9 s (C del perfil de fase 1).

---

## 1. Qué se precachea (2a) y qué no

Regla firmada: el cache guarda la parte cara en su **unidad cruda** (pesos corrientes, conteos de
personas), que es invariante de verdad; la conversión a % PIB con `pibY`/`deflator` (que depende de
CRECPIB/CRECDEF 2026–2027) se hace en tiempo de ejecución. FLAG-1 del perfil queda resuelto así.

| Item (`users/<id>/cache/`) | Qué es | Unidad | Insumos sellados (bytes) | Ahorro medido |
|---|---|---|---|---:|
| `PEF_divCIEP_iftransf_gfeq0.dta` | el colapso `anio × divCIEP × transf_gf` de `master/PEF.dta` (3.56 M filas) con la misma llamada que hace `FiscalGap` (`PEF if transf_gf == 0, by(divCIEP)`): `gasto`, `gastoTOT`, `CuoTOT` | pesos corrientes | `master/PEF.dta` | FiscalGap 12.5 → 2.1 s |
| `GastoPC_base_2027.dta` + `_mat.dta` | la micro de `GastoPC` tras §2 (`perfiles2027` ⨝ `households`, indicadores `alum_*`, `benef_*`, `der_*`, `pens_*`, cuidados, `pob`) y las 8 matrices de conteos (`tabstat [fw=factor]`) como `matriz, columna, nombre, valor` | personas / participaciones | `master/perfiles2027.dta`, `master/2024/households.dta` | GastoPC 7.7 → 4.6 s |
| `REC_<var>.dta` (41) | `collapse estimacion contribuyentes, by(anio modulo aniobase)` de cada `*RECprom.dta` (lo que `FiscalGap` §4.2/§5.2 hacía 24 veces por clic) | pesos / personas | `users/<id>/bootstraps/<B>/<var>RECprom.dta` | (dentro de FiscalGap) |
| `sello.txt` | `sello version/data_updated/commit/generado/id/bootstrap/aniope`; `item <item> <archivo>`; `insumo <item> <ruta> <bytes> -` | — | — | — |

**No se precacheó (y por qué):** `GastoPC` §3–8 y `TasasEfectivas` §7 (lineales en los escalares: es
2b, no cache); los conteos de §6–8 de `GastoPC` (`tabstat factor if edad…`, `ing_subor if scian`),
invariantes pero dentro de bloques de escenario (≈ 0.5 s; candidato de una fase 2c); `Simulador` y
`SankeySF` (dependientes). Ningún item resultó inseparable de los escalares: no hubo que forzar nada.

**Candado de frescura** (`_precache_usa`, probado en §6): existe el sello y el item; `data_updated`
del `05_scripts/manifest.json` del SIMROOT == el del sello; cada insumo existe y tiene los bytes del
sello. `mtime` no se exige (rsync/cp pueden no conservarlo). `commit` y `version` se registran, no se
exigen (un patch de código no regenera datos). Si falla cualquiera: `r(601)` con la receta ("corre
SIM.do §5.1b Precache…"); el `output.txt` queda con 33 bytes (solo la cabecera del log): el sitio no
recibe números viejos.

**Producción:** `publicar-vps.sh` Fase 3b-bis propaga `users/ricardo/cache/` (≈ 210 MB) junto con
los `*RECprom`; Gate 5 exige sello, items y `data_updated` == manifest. **No se desplegó nada.**

**Pendientes (FLAGs, decisión de Ricardo):** (a) `PEF, cache` llama a `_precache_usa`, que no está
en el endpoint `net install` (manifest-endpoint.toml / PEF.pkg): un investigador externo con solo
`PEF` instalado no usa `cache` (ni le hace falta: `PEF` sin opción calcula como siempre), pero si se
quiere coherencia total hay que añadir `_precache_usa.ado`, `_precache_bytes.ado` y
`_precache_manifest.ado` al endpoint. (b) El sello registra `commit`; el hash de este PR cambió al
corregir el commit 1 (563d8c9 → el final) después de generar la evidencia: el contenido del código
es el mismo, el sello del VPS se regenerará en el deploy. (c) Los conteos invariantes de `GastoPC`
§6–8 (≈ 0.5 s) quedan para una fase 2c.

---

## 2. «Calcular» default, web (3 corridas por variante)

| Variante | Corridas (timer 1 de Web.Stata.do, s) | Media | `output.txt` | sankeys |
|---|---|---:|---|---|
| ffca008 (sin cache) — baseline de #28 | 31.4 / 31.5 / 31.8 (en reposo) | 31.5 | referencia | referencia |
| 2a (cache) — `perf-2a/` | 20.3 / 19.3 / 18.5 | 19.4 | = baseline (0 bytes) | 232 de 520 enlaces distintos en el 15º–16º dígito (decil 83, escol 47, grupoedad 45, rural 34, sexo 23); Δ rel máx 2.8e-14, mediana 3.9e-15; **0 visibles** (`comparacion-web-ffca008-vs-2a.md`) |
| 2a + 2b apagado — `perf-2b-off/` | 18.2 / 19.0 / 19.2 | 18.8 | = 2a (0 bytes) | = 2a (0 bytes) |
| 2a + 2b encendido — `perf-2b-on/` | 16.1 / 16.1 / 15.9 | 16.0 | = 2a (0 bytes) | = 2a (0 bytes) |

Por sección (2a, `perf-2a/resumen.md`): TasasEfectivas 1.05 s, GastoPC 4.64, §6 merge 0.66,
Simulador+egen 5.34, FiscalGap 2.08, SankeySF×5 5.55. Lo que queda es Simulador + Sankey (56 %).

---

## 3. Batch completo con `entidad` vacío (gate i de 2a)

Corrida: `SIM.do` con `global nographs`, `global output`, `bootstrap 250`, raíz = el worktree de la
sesión (`batch-2a/SIM_run.do`, misma mecánica que `compuertas-entidad.sh`). Referencia: el
`users/ricardo/output.txt` publicado con v8.11.0 (`sha256 566c31ea6ab83f72…`) y sus 5 sankeys.

Resultado (`batch-2a/`, 31.2 min, `Precache` dentro: 43 items, sello `commit 563d8c9`):

- `output.txt`: `sha256 566c31ea6ab83f72…` — **byte-idéntico a v8.11.0**.
- 5 sankeys: **byte-idénticos** a los publicados con v8.11.0 (`comparacion-vs-v8.11.0.md`:
  8 427 valores comparados, 0 distintos).

Es decir: en el batch, con `PEF` histórico, `GastoPC` §2 y los 24 colapsos tomados del cache, el
producto completo es el mismo byte a byte. (El drift de 1e-15 de los sankeys del §5 es un fenómeno
del flujo **web** únicamente.)

---

## 4. 2b: forma cerrada tras interruptor — qué cambia y qué mide

`global algebra` vacío = apagado (default). Encendido:

- `FiscalGap` §3: en vez de `use ingresos ⨝ gastos` + 9 `tabstat [fw=factor]`, los totales HH del
  año base son `Σ_c scalar(c)/100·pibY(anio)/deflator(anio)` con el mismo `PIBDeflactor` que usa
  `GastoPC` §1. Es exacto por construcción de `GastoPC` (PC = x/conteo/deflator ⇒ Σ factor·PC·ind
  = x/deflator; `Distribucion` reparte exactamente el macro). Composición usada: Educacion =
  iniciaA basica medsup superi posgra eduadu otrose invere cultur invest; Pensiones = penimss
  penisss penpeme penotro; Pensión_AM = pam; Salud = ssa imssbien imss issste pemex issfam invers;
  Otros_gastos = gasotros; IngBasico = IngBas gasmadres gascuidados; Otras_inversiones = gasinfra;
  Federalizado = gasfeder; Energia = gascfe gaspemex gassener gasinverf gascosdeue.
- `GastoPC` §3–6: `Educacion`, `Salud`, `Pensiones`, `Energia` se generan en una pasada
  (`g Var = t1 + t2 + …`, término condicional como `(expr)*(cond)`) en vez de 26 `replace`.
  Misma asociación izquierda→derecha que la cadena de `replace`; `x + 0 = x` exacto.
  `IngBasico`, `Federalizado`, `OtrasInversiones`, `OtrosGastos` no se tocaron (Distribucion /
  condiciones múltiples): quedan para una 2c si 2b se enciende.

### 4.1 Totales HH, ruta micro vs forma cerrada (precisión completa, `hh-micro-vs-cerrada.txt`)

| Variable | micro (`tabstat sum [fw]`) | cerrada (escalares) | Δ rel |
|---|---:|---:|---:|
| Educacion | 1 387 806 928 361.6819 | 1 387 806 928 361.6824 | 3.5e-16 |
| Pensiones | 1 840 686 837 673.6880 | 1 840 686 837 673.6880 | 0 |
| Pensión_AM | 580 979 100 370.6672 | 580 979 100 370.6672 | 0 |
| Salud | 1 137 126 665 243.8091 | 1 137 126 665 243.8093 | 2.1e-16 |
| OtrosGastos | 675 575 426 075.5248 | 675 575 426 075.5248 | 0 |
| IngBasico | 22 072 475 997.8001 | 22 072 475 997.8001 | 0 |
| OtrasInversiones | 618 029 327 938.4031 | 618 029 327 938.4031 | 0 |
| Federalizado | 1 651 494 186 263.9729 | 1 651 494 186 263.9729 | 0 |
| Energia | 1 269 167 369 873.5061 | 1 269 167 369 873.5066 | 3.8e-16 |

**Δ relativo máximo: 3.8e-16** (1–2 ulp de double). Es el único lugar donde 2b cambia una
operación aritmética; aguas abajo `output.txt` (3 decimales) y los sankeys salieron **idénticos al
byte** con el interruptor encendido (web, 3 corridas: §2). Tabla renglón por renglón: trivial —
0 de 1 036 valores distintos (`comparar-productos.py perf-2b-off/off1 perf-2b-on/on1`).

### 4.2 Batch completo con el interruptor encendido

`batch-2b/` (30.4 min; mismo `SIM_run.do` que 2a más `global algebra "algebra"`). Verificado con
`set trace` en el flujo web que las dos ramas nuevas corren con el interruptor (FiscalGap §3 llama
`PIBDeflactor, aniovp(…)` en vez de `use ingresos`; GastoPC ejecuta 4 `_GPCcierra` y 0 `replace`).

- `output.txt`: `sha256 566c31ea6ab83f72…` — **byte-idéntico** a batch 2a y a v8.11.0.
- 5 sankeys: **byte-idénticos** a batch 2a y a v8.11.0 (8 427 valores, 0 distintos;
  `batch-2b/comparacion-vs-batch-2a.md`).

Tabla renglón por renglón / enlace por enlace, apagado vs encendido: **vacía** (no hay un solo
valor distinto). La única diferencia aritmética de 2b está en los totales HH (§4.1, ≤ 3.8e-16),
que `FiscalGap` usa como ancla del año base y que `output.txt` imprime con 3 decimales.

### 4.3 Tolerancia propuesta (Ricardo firma)

**10⁻⁹ relativo** por valor de `output.txt` y por enlace de sankey, como se propuso; la medición
da 3.8e-16 en el único punto que cambia y 0 aguas abajo, así que la tolerancia sobra por seis
órdenes de magnitud. El default **se queda apagado** en este PR.

---

## 5. FLAG-7 — en el flujo web, los sankeys de 2a difieren en el 15º–16º dígito

Hechos:

1. Web, 2a vs ffca008: `output.txt` byte-idéntico; 232 de los 520 enlaces de los 5 sankeys cambian
   en el último o penúltimo dígito significativo (Δ rel máx 2.8e-14, mediana 3.9e-15; p. ej.
   `I → Imp al trabajo` 49197860719.77805 vs 49197860719.77823). Los enlaces que vienen de
   escalares × pibY (FMP, Empresas públicas, Costo de la deuda…) son idénticos; los que son sumas
   ponderadas de la micro (`collapse (sum) … [fw=factor], by(corte)`) son los que se mueven.
2. `ingresos.dta`, `gastos.dta` y `aportaciones.dta` de las dos corridas son **idénticos valor por
   valor y en el mismo orden** (`cf _all`). La diferencia nace dentro de `SankeySF.do`, en la suma.
3. **Batch** 2a vs v8.11.0: sankeys **byte-idénticos**. El fenómeno es solo del flujo web.
4. Aislado (`srt2.do`): el mismo `collapse (sum) [fw=factor], by(decil)` sobre el mismo
   `aportaciones.dta` da sumas distintas en el último bit si antes corrió un `sort` ajeno: el orden
   en que `collapse` acumula los empates de `decil` depende del estado interno del `sort`
   (`c(sortrngstate)`), que a su vez depende de qué `sort`/`collapse`/`egen` corrieron antes en la
   sesión. 2a quita, antes de los sankeys del flujo web, los del `PEF` sobre 3.56 M filas, los de
   `GastoPC` §2 y los 24 de `*RECprom`.
5. No cierra del todo: insertar un `sort` suelto en el flujo web (`sorttest`) no los movió, y 2b
   encendido (que quita un `merge`) tampoco. El disparador exacto dentro del flujo web no quedó
   aislado; la magnitud (≤ 3e-14), el lugar (la suma ponderada de `SankeySF`) y el mecanismo
   general (orden de acumulación) sí.

Lectura: es **ruido de orden de operaciones en coma flotante, no un número movido** — cero
diferencias a la precisión del sitio (mdp con 1 decimal) y cero a la tolerancia de 1e-9 propuesta
para 2b. El gate "byte-idéntico" para JSON impresos con 16 dígitos es frágil ante cualquier cambio
de la secuencia de operaciones de la sesión; el batch lo cumple hoy y el web no.

Propuesta (decisión de Ricardo, commit aparte): hacer las sumas de `SankeySF.do` independientes
del historial de la sesión — `sort <corte> folioviv foliohog numren` (clave única, orden
determinista) antes de cada `collapse … by(<corte>)`. Costo: un drift único de ~1e-15 respecto a
v8.11.0 en el batch; después, los sankeys quedan estables al byte ante cualquier cambio del
pipeline (incluido 2a). Alternativa: declarar para los JSON la tolerancia de 1e-9 en lugar de
byte-identidad.

## 6. Gates

| Gate | Resultado | Evidencia |
|---|---|---|
| 2a (i) batch entidad vacío → `output.txt` + 5 sankeys = v8.11.0 | **byte-idénticos** (`566c31ea…`; 8 427 valores, 0 distintos) | `batch-2a/` |
| 2a (ii) «Calcular» con cache → `output.txt` = sin cache | **byte-idéntico** (1 036 valores, 0 distintos) | `perf-2a/`, `comparar-productos.py` |
| 2a (iii) tiempo 3 corridas antes/después | 31.5 → 19.4 s | `perf-2a/resumen.md` |
| 2a (iv) candado | 4 casos (sin cache, sin item, insumo con bytes distintos, `data_updated` distinto) → `r(601)` con receta, sin números | `candado/candado.txt` |
| 2b apagado = 2a | **0 bytes distintos** (output + sankeys), 3 corridas | `perf-2b-off/` |
| 2b encendido vs apagado | **0 bytes distintos**; HH Δ rel máx 3.8e-16; 16.0 s | `perf-2b-on/`, `hh-micro-vs-cerrada.txt` |
| 2b batch encendido | `output.txt` y sankeys **byte-idénticos** a 2a y a v8.11.0 (0 de 8 427) | `batch-2b/` |
| `compuertas-entidad.sh` (Nuevo León) | **TODAS EN VERDE** (160 JSON; Σ 32 entidades = nacional en 224 enlaces, reldif máx 1.0e-13; testigo NL 90 celdas reldif 2.4e-15; banda ENIGH; sellos). El cache no rompe entidad: `SIM.do` con `entidad` corre `Precache` y `GastoPC, cache`/`FiscalGap` igual que el nacional. (Primer intento sin las bases por vintage ni el statajson: las dos ✗ de precondición de datos ya conocidas de v8.11b; se repusieron y se repitió.) | `compuertas-nl/`, `compuertas-nl-intento1-sin-precondiciones/` |
| `publicar.sh v8.11.0 --check` | **8/8** (Gate 5 con los 26 assets locales verificados por SHA) | `publicar-check.txt` |

---

## 7. Evidencia (`~/CIEP_Simuladores/diag-v8.12-fase2-2026-10-18/`)

`precache/` (corrida standalone de `Precache`), `perf-2a/` (perfilar-web, 3 corridas + baseline),
`perf-2b-off/`, `perf-2b-on/` (3 corridas c/u, `tiempos.txt`), `hh-micro-vs-cerrada.txt`,
`candado/candado.txt`, `srt2.do/.log` (sort y sumas), `batch-2a/`, `batch-2b/`, `compuertas-nl/`,
`comparar-productos.py`, `correr-web.sh`.
