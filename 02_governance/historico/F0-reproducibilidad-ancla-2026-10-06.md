> Reporte one-shot del diagnóstico F0 (2026-10-06) que motivó el release de datos v8.8.0 y la receta canónica de `runbook-deploys-ciep.md` §9. Evidencia (corridas, logs, scripts) en la máquina de Ricardo: `~/CIEP_Simuladores/diag-release-datos-2026-10-06/`. Se conserva como memoria; la norma vigente está en el runbook.

# F0 — Diagnóstico de las tres anclas (`output.txt`, PE 2027)

Worktree: `~/CIEP_Simuladores/SimuladorCIEP-datos` (rama `fix/release-datos` desde
`origin/master` = 158f737, v8.7.2). Evidencia, scripts y corridas en
`~/CIEP_Simuladores/diag-release-datos-2026-10-06/` (`run_sim.sh`, `cmp_output.py`,
`dsig*.do`, `R*/` con `output.txt`, `wrap.log`, `resumen.txt`, `estado.txt`).
Dropbox y worktree NL: solo lectura.

## 0. Resumen ejecutivo

1. **`ae624b98` no es reproducible desde código + assets.** Sus cachés micro
   (`master/2024/consumption_*_pc.dta`, `deducciones.dta`, `raw/temp/2024/*`) son del
   22-sep, anteriores a `perfilpc` (v8.5.0, "CAMBIA RESULTADOS") y a `Simulador` v2.0,
   y `global update` **no los invalida** (solo borra `raw/temp/`; los `*_pc` de
   `master/<anio>/` se crean únicamente si faltan). Además sus macro (`SCN`, `LIF`,
   `SHRFSP`, `DatosAbiertos`, `PIBDeflactor`) son descargas del 22-sep. Toda la
   "paridad" de la temporada midió "mismo estado congelado → mismo output", no
   "misma receta → mismo output".
2. **`38eb4c43` (Ricardo, 6-oct) ES la regeneración limpia de hoy.** Mi regeneración
   desde cero (assets del release + fuentes vivas del 6-oct, StataNow SE 19.5,
   `global update`) reproduce los 5,0xx valores de `38eb` **sin una sola diferencia
   numérica**; el único byte distinto es la primera línea `.quietlylogoffoutput`,
   artefacto de invocar `SIM.do` con `do` (eco del comando) vs `run`/Do-file Editor.
   El "estado híbrido" de Dropbox no tuvo efecto.
3. **Determinismo probado:** la misma receta corrida dos veces desde cero (R1 y R3,
   SE 19.5, `global update`, 2 h de diferencia) da `output.txt` **y** los cinco
   `sankey-*.json` **idénticos al byte**; las 815 descargas (BIE, CSI, SHCP) fueron
   idénticas entre ambas. Con cachés (R2) `output.txt` sigue idéntico. El ruido de último bit existe
   (`sankey-*.json` a 16 dígitos cambia entre corridas con distinto camino de
   ejecución) y tiene dos causas medidas: (a) `collapse (sum)`/sumas flotantes
   dependen del orden de los empates, que Stata `sort` rompe con un RNG propio
   (`sortseed`) que avanza con cada `sort` de la sesión → el resultado depende de qué
   corrió antes; (b) StataMP suma en paralelo: el resultado depende de
   `set processors` (1≠2≠…≠10) y MP(procs=1) = SE. `output.txt` redondea a 3
   decimales y absorbe este ruido (0 flips en 5,0xx valores entre caminos distintos),
   pero no está garantizado por construcción.
4. **Stata 17 no puede descargar de la SHCP** (`copy` → r(603) en
   `secciones.hacienda.gob.mx`; StataNow 19.5 sí, `curl` sí). Una regeneración
   completa con `global update` en Stata 17 aborta en `DatosAbiertos`; solo prospera
   si los csv ya están en `raw/temp/Datos Abiertos/` (fallback local). Las
   "máquinas limpias" anteriores nunca regeneraron de verdad con Stata 17.
5. **Fuentes vivas:** entre el 22-sep y el 5-oct INEGI revisó el PIB 2024
   (33,582.9 → 33,667.0 mmdp) y publicó 2025; la SHCP agregó meses. Eso explica
   INGRESOSTEF (IEPSP 67.6→76.3), DEUDAPARAM (6.599→6.667), PROYCOSTO/PROYSHRFSP y,
   vía la armonización macro-micro de `Households.do`, INCD. Las fuentes del 5-oct y
   del 6-oct dieron valores idénticos (estables en el día), pero cambian con cada
   publicación: sin congelarlas el ancla caduca sola.
6. **IVAT evasión 23.0→23.1:** es exactamente la fila "Informalidad %" que imprime
   `Expenditure.do` §5 (potencial ENIGH vs IVA observado/PIB): 5.443/4.193 → 22.96 %
   ("23.0") en el estado viejo; 5.44094/4.18208 → **23.137 %** ("23.1") regenerado.
   El movimiento viene sobre todo del denominador (PIB 2024 revisado por INEGI:
   IVA/PIB 4.193→4.182), no de los perfiles (potencial 5.443→5.441). Cierre del
   módulo web (`IVA_Mod.do`, PE 2027, estado regenerado): la simulación cruda da
   4.494 % PIB con 23.0 y **4.488 con 23.1 vs 4.485 observado (LIF 2027): brecha
   +0.003 pp (+0.08 %)** — 23.1 cierra. PERO `IVA_Mod.do` multiplica además por un
   factor fijo `4.249/4.495` (calibración heredada de otro ejercicio) que deja el
   resultado publicado en 4.248/4.243 (−5.3 %/−5.4 % vs LIF); y deflacta precios con
   `anio == 2022` fijo (ENIGH 2022) en vez de `anioenigh`. Ambos son decisión
   metodológica de Ricardo, no de este PR: se documentan, no se tocan.

## 1. Inventario de estado: qué determina `output.txt`

| Capa | Archivos | Fuente | ¿Lo regenera `global update`? | ¿Lo construye una máquina virgen? |
|---|---|---|---|---|
| Código | `*.ado`, `01_modulos/*.do`, `SIM.do` | git (tag) | — | — |
| Assets del sidecar (26) | `raw/ENIGH/*.zip`, `raw/PEFs/*`, `raw/LIFs/LIFs.xlsx`, `raw/CONAPO/*.zip`, `raw/ISRInformesTrimestrales.xlsx` | GitHub Release (`ensure_asset`, SHA en manifest) | no (inmutables) | sí (descarga, SHA) |
| ENIGH descomprimida | `raw/ENIGH/<anio>/*.dta` | unzip del asset (20/20 archivos, mismos bytes que el zip) | no (se reutiliza si existe) | sí |
| **Fuentes vivas** | `raw/temp/AccesoBIE/*.csv` (~540 series BIE), `raw/temp/SCN/CSI_*.xlsx` (tabulados INEGI, 12 MB), `raw/temp/Datos Abiertos/*.csv` (SHCP, 492 MB) | INEGI / SHCP en línea | **sí** (`update` borra `raw/temp/` y re-descarga; `AccesoBIE` descarga siempre, no reutiliza su csv) | sí (descarga; **falla en Stata 17 para la SHCP**) |
| Macro derivadas | `master/{Poblacion,Poblaciontot,PIBDeflactor,Deflactor,SCN,DatosAbiertos,LIF,PEF,SHRFSP}.dta`, `raw/temp/*.dta` (SCN), `raw/temp/prePEF.dta` | assets + fuentes vivas | sí (`update` en cada módulo). `DatosAbiertos` además se refresca solo si el caché tiene > 2 meses (regla que depende de la fecha de hoy) | sí (si falta, cada módulo lo construye) |
| Micro congeladas (**solo si faltan**) | `raw/temp/2024/{pre_iva,va_por_clase_actividad,pre_iva_final,preconsumption}.dta`, `master/2024/{deducciones,consumption_categ_pc,consumption_categ_iva_pc,consumption_categ_ieps_pc}.dta` | ENIGH + código (`Expenditure.do` §2–3, `perfilpc`) | **`raw/temp/2024` sí; `master/2024/*_pc` y `deducciones` NO** | sí |
| Micro de cada corrida | `master/2024/{expenditures,households,categ_iva,consumption_categ_iva,consumption_categ_ieps,formal_*.ster}`, `master/perfiles2027.dta`, `users/$id/{ingresos,gastos,aportaciones}.dta`, `users/$id/bootstraps/1/*` (`reboot`) | micro congeladas + macro (SCN 2024, LIF/PEF 2027, Poblacion) | se rehacen en cada corrida | sí |
| Entorno | binario de Stata (edición/versión), `set processors`, forma de invocar `SIM.do` (`do` vs `run`) | máquina | — | — |
| Salida | `users/$id/output.txt`, `users/$id/sankey-*.json` | todo lo anterior | — | — |

Notas: `FiscalGap.ado` lee `users/ricardo/bootstraps/1/*REC.dta` (usuario y B fijos).
Los `.dta` llevan timestamp en el header: el contenido se compara con `datasignature`,
no con SHA del archivo.

### 1.1 Contenido de los cachés: NL (ancla ae62) vs Dropbox (38eb) vs regeneración R1

`datasignature` (N:k(hash nombres):hash datos):

| Base | NL (22-sep) | Dropbox (5/6-oct) | R1-SE (6-oct) | Lectura |
|---|---|---|---|---|
| `master/Poblacion.dta` | 2774184642 | = | = | asset CONAPO, determinista |
| `master/Deflactor.dta` | 682389190 | = | = | idem |
| `master/PEF.dta` | 1410057014 | = | = | assets PEFs, determinista |
| `master/SCN.dta` | 1051461098 (N=121) | 2155302843 | = Dropbox | INEGI revisó 2024 y publicó 2025 |
| `master/PIBDeflactor.dta` | 1605603923 | 1266139316 | = Dropbox | idem (BIE) |
| `master/DatosAbiertos.dta` | N=1,706,836 | N=1,716,734 | = Dropbox | SHCP agregó meses |
| `master/LIF.dta` | 2502006440 | 3995093393 | 3860575549 | SHCP; Dropbox≠R1 con `DatosAbiertos` idéntico → ruido de bit (§2.2), sin efecto en `output.txt` |
| `master/SHRFSP.dta` | 3271914180 | 1928697173 | = Dropbox | SHCP |
| `raw/temp/2024/pre_iva.dta` | 3731389384 | = | = | ENIGH pura, determinista |
| `raw/temp/2024/va_por_clase_actividad.dta` | 1458061646 | 852782137 | 2141173636 | mismo N, k: ruido de último bit (ver §2.2) |
| `master/2024/deducciones.dta` | 437452564 | 3002726090 | 1072013107 | idem |
| `master/2024/consumption_categ_pc.dta` | k=198 | k=217 | k=217 | **NL es pre-perfilpc** (11 variables menos) |
| `master/2024/consumption_categ_{iva,ieps}_pc.dta` | k=118 | k=129 | k=129 | idem |
| `master/2024/expenditures.dta` | k=123 | k=142 | — | idem |

## 2. Determinismo

### 2.1 Corridas (receta batch del runbook: `nographs` + `output`; PE 2027)

| Corrida | Estado inicial | Stata | `update` | Duración | `output.txt` SHA-256 | `sankey-*.json` |
|---|---|---|---|---|---|---|
| ae62 (NL, 6-oct 01:28) | cachés 22-sep + master/2024 pre-perfilpc | MP 17, 10 procs | no | ~12 min | `ae624b98…` | `1e8f353d…` |
| 38eb (Ricardo, 6-oct 07:58) | Dropbox: master/ 5-oct + raw/ reconstruido | SE 19.5 (`run`) | no | — | `38eb4c43…` | `d14c53e3…` |
| **R1-SE-update** | `raw/` = 26 assets (SHA ok), sin master/, users/, raw/temp | SE 19.5 | sí | 79 min | **`698629db…`** | `9e99bc33…` |
| **R2-SE-cache** | estado final de R1 | SE 19.5 | no | 11 min | **`698629db…`** (= R1) | `33ef2134…` (≠ R1) |
| **R3-SE-update** | como R1 (de cero, 2 h después) | SE 19.5 | sí | 79 min | **`698629db…`** (= R1 al byte) | **= R1 al byte (5/5)** |
| **R4-MP17p1** | como R1 + csv SHCP del 6-oct en `raw/temp/Datos Abiertos` (+ parche local en `_DAdescarga`, ver §2.3) | MP 17, `set processors 1` | no (todo falta → se construye) | 86 min | `e371964d…` | ≠ R1 (5/5) |
| **R5-MP17p10** | idem | MP 17, 10 procs (default) | no | 72 min | `e371964d…` (**= R4 al byte**) | ≠ R4 (5/5) |
| R1-MP17-update | como R1 | MP 17 | sí | abortó | — | `DatosAbiertos`: r(603) en la SHCP |

- `38eb` vs `R1`: **0 diferencias numéricas** en las 46 llaves (5,0xx valores); única
  diferencia: línea 1 `.quietlylogoffoutput` (eco de `do`).
- `R1` vs `R2`: `output.txt` idéntico al byte; los 5 `sankey-*.json` difieren en los
  últimos 2-4 dígitos de 16 (p. ej. `49203202514.97522` vs `.97502`).
- `R1` vs `R3` (misma receta, de cero, dos veces): **idénticos al byte**, `output.txt`
  y los 5 sankeys.
- `R1` (SE 19.5) vs `R4` (MP 17, 1 procesador): **52 de ~5,000 valores distintos** en
  5 llaves — INCD (22 valores, máx 43 pesos = 0.05 %), APORTHX/APORTMX (hasta 0.042 pp)
  — el mismo patrón "~1e-4 en INCD/APORT" que el CHANGELOG atribuyó a `635b14dc`:
  **la versión de Stata (17 vs 19.5) mueve el output redondeado**; no es ruido de bit
  sino diferencias de algoritmo (xtile/probit/Mata) que cruzan fronteras de redondeo.
- `R4` (MP 17, 1 proc) vs `R5` (MP 17, 10 procs): `output.txt` **idéntico al byte**;
  sankeys distintos. El número de procesadores solo produce ruido de bit; la versión
  de Stata sí mueve `output.txt`.

Síntesis: `output.txt` = f(código, assets, fuentes vivas a una fecha, **versión de
Stata**); los sankeys a 16 dígitos además = f(camino de ejecución, procesadores).

### 2.2 Mecanismos del ruido de último bit (medidos sobre `va_por_clase_actividad`)

Mismo archivo de entrada (`censo_eco_municipios.dta`, SHA idéntico en los tres árboles),
mismo bloque de código:

| Condición | `datasignature` |
|---|---|
| SE 19.5, sesión limpia (×2) | 852782137 (= Dropbox) |
| MP 17 `set processors 1` | 852782137 (= SE) |
| MP 17 procs 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 | 1843427397 / 116558423 / 413580939 / 1388666154 / 288968990 / 3752246923 / 3259523117 / 2695545487 |
| MP 17 procs 10 (default en esta Mac, ×3) | 1177667990 |
| SE 19.5, mismo bloque tras `Poblacion` / `SCN` / `LIF` / `Poblacion` en la misma sesión | 2397322570 / 1314714817 / 298081321 / 164340913 (uno distinto cada vez) |
| idem con `set sortseed 1001` justo antes del `collapse` | 2581411395 (×5, independiente de lo anterior) |
| idem con `sort clase_de_actividad, stable` antes del `collapse` | 2629785380 (×5, independiente de lo anterior) |

Lectura: `collapse (sum)` suma en el orden físico de cada grupo; `sort` rompe empates
con su RNG (`sortseed`), cuyo estado avanza con cada `sort` de la sesión; MP además
particiona la suma por hilo. Ninguno de los tres árboles (NL 22-sep) coincide con
ningún número de procesadores de esta Mac: los intermedios del ancla vieja vienen de
otra máquina o de otro camino de ejecución.

Consecuencia operativa: **el ruido no cambia `output.txt` en la práctica** (0 flips en
R1/R2/38eb con caminos distintos), pero sí los `sankey-*.json` a 16 dígitos, y no está
garantizado. Las dos vías para garantizarlo son (a) fijar la receta (binario, procs=1,
estado de cero, misma invocación) o (b) hacer el motor insensible al orden
(`sort …, stable` antes de cada `collapse`/`egen sum`; auditoría grande, fuera de este
alcance).

### 2.3 Bug de robustez encontrado: el respaldo local de la SHCP se autodestruye

`_DAdescarga` (DatosAbiertos.ado §2) hace `copy "<url>.csv" "<dir>/<nombre>.csv", replace`;
en Stata 17 `copy` **borra el destino antes de fallar** (r(603)), así que el fallback
"archivos locales de raw/temp/" encuentra el archivo recién borrado (`not found`, R4
primer intento). Fix mínimo (probado en R4): descargar a `<nombre>.csv.tmp` y solo
entonces reemplazar. Necesario para el modo de fuentes congeladas en cualquier Stata.

## 3. Anatomía de las tres anclas (`cmp_output.py`)

### 3.1 ae62 → 38eb (= R1): 2,890 valores distintos en 16 llaves

| Familia | Qué cambia | Causa |
|---|---|---|
| INCD/INCD2/INCD3 (ingreso por decil, 41 bloques) | máx 11 % | (b) SCN 2024 revisado → armonización macro-micro de `Households.do`; (c) cachés micro pre-perfilpc |
| APORTH*/APORTM* (ciclo de vida sexo×edad×deciles) | hasta 0.9 pp, 100 % relativo en celdas chicas | (c) `consumption_*_pc` pre-perfilpc vs perfilpc (reparto intra-hogar) + (b) |
| PROY / PROYMAX | máx 1.2 (6 %); PROYMAX 2027→2028 en 1 variable | (b)+(c) vía perfiles2027 |
| INGRESOSTEF | IEPSP 67.6→76.3, IEPSNP 46.5→47.9, ISRAS 12.8→12.7, ISRPM 12.8→12.9, ISAN 1.8→1.7, consumo 10.0→9.9 | (b) SCN 2024 revisado (denominadores) |
| DEUDAPARAM (tasa efectiva) 6.599→6.667; PROYSHRFSP2/3; PROYCOSTO 2026 2.0→2.2 | | (b) SHCP: meses nuevos en `DatosAbiertos` → `SHRFSP` |
| Línea 1 `.quietlylogoffoutput` | presente en ae62/R1, ausente en 38eb | invocación `do` vs `run` |
| Sin cambio | INGRESOS, GASTOS, GASTOSPC, PIBY, ISR*, IVA, CSS*, CRECPIB/DEF, PROY{LABOR,…,INVER}, PROYSHRFSP1 | parámetros de `SIM.do` / PEF (assets) |

(a) "intermedios raw/temp de otra época" solo es causa indirecta: `pre_iva.dta` es
idéntico en los tres árboles; lo que difiere son los `master/2024/*_pc` (código
distinto) y el ruido de bit.

### 3.2 635b14dc (máquina limpia del PR #15)

El archivo ya no existe (`/tmp/Prueba Alumno/…` borrado; no hay copia en ningún
árbol). Por el CHANGELOG ("~1e-4 en INCD/APORT") era una corrida con cachés macro
del 22-sep y cachés micro parcialmente reconstruidos; con lo medido aquí es
consistente con ruido de bit + caché mixto, no con revisión de fuentes. No se puede
re-derivar sin el archivo; se registra como no reproducible.

### 3.3 IVAT[13] 23.0 vs 23.1

No interviene en `output.txt` por default (solo se imprime como `IVA:[…,23]` y solo
se USA en `IVA_Mod.do`, es decir, en simulaciones web con cambio de IVA). `38eb` y
`R1` se corrieron con 23.0. El 23.1 es la lectura de la fila "Informalidad %" de
`Expenditure.do` §5 tras regenerar (ver §0.6).

## 4. Propuesta de receta canónica (para aprobar antes de F1)

**Definición:** `output.txt` canónico = el que produce `SIM.do` (PE 2027, `nographs`,
`output`, `bootstrap 1`) desde **estado cero** con **assets del release** y
**fuentes vivas congeladas a una fecha declarada**, en **StataNow 19.5 con un procesador**,
invocado en **batch con `do`**.

1. **Congelar las fuentes vivas como asset del sidecar**: `fuentes-vivas-AAAA-MM-DD.zip`
   = `raw/temp/AccesoBIE/*.csv` (2 MB) + `raw/temp/SCN/*.xlsx` (12 MB) +
   `raw/temp/Datos Abiertos/*.csv` (492 MB; ~60-80 MB comprimido), con SHA en el
   manifest y campo `fuentes_congeladas_al`. Cambios mínimos en el motor, todos
   detrás de un global nuevo (`global fuentes "congeladas"`, nombre a decidir):
   `SIM.do` §0.4 → tras `rm -r raw/temp` descomprime el asset; `AccesoBIE` → si
   existe `raw/temp/AccesoBIE/<serie>.csv` lo usa en vez de descargar; `DatosAbiertos`
   → modo `local`; `SCN` ya reutiliza `CSI_*.xlsx` si existen. Sin el global, el
   comportamiento es el de hoy (byte-idéntico). Esto además hace viable Stata 17
   (no descarga de la SHCP) y la máquina sin red.
2. **Estado cero explícito**: la receta borra `master/`, `users/$id/` y `raw/temp/`
   antes de correr (hoy `update` deja vivos `master/2024/*_pc` y `deducciones`).
   Alternativa menor en el motor: que `update` también borre `master/<anioenigh>/`.
3. **Stata: versión fijada = StataNow 19.5** (la de producción de Ricardo; la única
   que descarga de la SHCP; R1=R3 al byte). MP 17 da otro `output.txt` (52 valores),
   así que el ancla se declara con versión (`c(stata_version)` = 19.5) y el gate la
   verifica. `set processors 1` en el `wrap.do` para que MP y SE coincidan al bit
   (procs ≠ 1 solo mueve los sankeys). El VPS (Linux) queda fuera del ancla: el
   ancla es del default local que se sube al sitio.
4. **Invocación**: batch `stata -b do wrap.do` (como el runbook). Fix mínimo en
   `SIM.do` §0.4: abrir el log dentro de `quietly { … }` para que `do` y `run`
   produzcan los mismos bytes (probado: elimina la línea `.quietlylogoffoutput`).
5. **Ancla**: `05_scripts/ancla-output.txt` (o campo en el manifest) con el SHA-256
   de `output.txt` y los 5 `sankey-*.json`, la fecha de fuentes, la versión y el
   binario; política: se re-ancla en cada release de datos (y cuando un cambio de
   código mueva números), nunca en silencio, con el delta en el CHANGELOG.
6. **Gate "reproducibilidad"** en `test-maquina-virgen.sh --reproducibilidad` (y
   opcional en `publicar.sh --check` como aviso): corre la receta en un SITE limpio
   (~80 min) y compara SHA de `output.txt` (estricto) y de los 5 `sankey-*.json`
   (estricto bajo la receta exacta: R1=R3 lo demuestra; si se corre con otro binario
   el gate lo dice en vez de fallar en silencio).
7. **Delta documentado**: tabla §3.1 al CHANGELOG (release de datos:
   `data_updated` = fecha de fuentes; versión según convención: minor si se
   considera "datos nuevos" — INEGI/SHCP revisados — o patch; propongo **minor**
   porque mueve números publicados).

8. **Candidato a ancla nueva (ya calculado):** `698629db9992b242912c5dd10b306ba92b5dc23e4126d0deeef8d294dd34651f`
   (fuentes del 6-oct-2026, SE 19.5, IVAT 23.0, con la línea `.quietlylogoffoutput`).
   El ancla oficial de F1 será OTRA: cambia con IVAT 23.1 (línea `IVA:[…,23.1]`) y
   con el fix de la línea 1; se recalcula al final de F1 con la receta ya cerrada.

Preguntas para aprobar: (i) ¿fecha de congelamiento = 6-oct-2026 (fuentes de hoy) o
esperar a una publicación concreta?; (ii) ¿nombre del global y del asset
(`fuentes` / `fuentes-vivas-2026-10-06.zip`)?; (iii) ¿`update` debe borrar también
`master/<anioenigh>/*_pc` y `deducciones` (hoy nunca se invalidan), o solo la receta
canónica parte de cero?; (iv) ¿minor o patch?; (v) `IVA_Mod.do`: ¿se tocan el factor
`4.249/4.495` y el `anio == 2022` fijo (decisión metodológica tuya) o solo se
documentan?
