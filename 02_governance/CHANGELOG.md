# Changelog del Simulador Fiscal CIEP

Este archivo registra los cambios de cada versión publicada del Simulador Fiscal CIEP.

Las versiones se numeran siguiendo el esquema descrito en `02_governance/versionado-y-git.md` §3:
mayor cuando hay cambio metodológico o institucional de fondo, menor cuando hay datos nuevos
o funcionalidad nueva compatible, patch para correcciones sobre versión publicada.

**A partir de v8.0, todas las versiones son reproducibles end-to-end** — código + datos +
endpoint publicados en la misma versión, referenciables mediante `git checkout v8.x`.

Formato de cada entrada:
- **Institucional:** cambios de governance, infraestructura, arquitectura de publicación
- **Comandos:** cambios que afectan cómo se usa el Simulador desde Stata (nuevas opciones,
  comandos agregados o modificados, comandos deprecados)
- **Datos:** cambios en fuentes, actualizaciones de PEFs, LIFs, ENIGH, u otras fuentes
- **Correcciones:** bugs corregidos que afectaban resultados o funcionamiento

## [v8.2.0] — 2026-07-19

**Cambio de metodología del PC de salud: el denominador pasa de
hogares-equivalentes a PERSONAS para mantener consistencia con los demás
rubros del gasto.** Y unificación de los conteos de población del sitio: los
19 `data-pop`/columnas quemados en el HTML migran a viajar por `output.txt`
(bloques nuevos `GASTOSPOB1`/`GASTOSPOB2`).

### Comandos
- `GastoPC.ado`: conteos de PERSONAS para display/PC/web (matriz `SaludPer`,
  ENIGH 2024 con el factor de perfiles ya proyectado a población CONAPO del
  año PE — reescalado calculado en la corrida, no hardcodeado). Definiciones
  documentadas en el código: SSA/Inversión/Total = población CONAPO
  (coherente con Energía/Cultura); IMSS `inst_1`; ISSSTE `inst_2`;
  Pemex/ISSFAM `inst_4` partido con el ancla administrativa 602513/1169476;
  otros `inst_6`; IMSS-Bienestar = residuo sin seguridad social, con `inst_3`
  (ISSSTE estatal, ~2.0M personas) DENTRO del residuo por continuidad
  metodológica — candidato de refinamiento registrado en bitácora. La doble
  afiliación declarada (0.7%) se cuenta en AMBAS instituciones, como en los
  registros administrativos. Los `*Pob`/`*PC` de salud pasan a personas
  (IMSS: 12,091,141 hogares-eq → 55,311,028 personas; PC 43,008 → 9,402);
  los `*PIB` no cambian.
- **Desacople de la incidencia**: la imputación por persona
  (`Salud = Σ PC×benef_*`) conserva el cociente hogares-equivalentes como
  tempname scalar interno (`*PCinc`, double exacto — un local stringifica y
  mueve el último bit); `benef_*` INTACTOS. Guardián: Sankeys y deciles
  byte-idénticos.
- `01_modulos/output.do`: bloques `GASTOSPOB1`/`GASTOSPOB2` con los 42 conteos
  (indexado espejo de `GASTOSPC`; en DOS bloques porque el linesize máximo de
  Stata (255) partiría la línea con `> ` y `checkStataStatus.php` no maneja
  continuaciones). Parser PHP genérico: cero cambios en PHP.
- Display de `GastoPC`: header "Asegurados" → "Derechohabientes".
- TODOs sembrados en las anclas administrativas sin fuente/corte documentados
  (`602513/1169476` salud Pemex/ISSFAM; `110000/181290` pensiones Pemex).

### Correcciones
- **Bug vivo del botón ± de Salud**: el HTML traía conteos quemados grandes
  (`data-pop`) mientras el PC publicado usaba denominador chico
  (hogares-equivalentes): un click de +$1,000 en IMSS saltaba el gasto de
  1.374% a ~6.4% del PIB. Con el PC por persona y `data-pop` del motor:
  1.374% → 1.520% (Δ +0.146 pp), verificado con la aritmética exacta del
  handler.
- **Procedencia de los fósiles del sitio RECUPERADA**: los conteos quemados
  (IMSS 55,311,028; IMSS-B 57,363,801; ISSSTE 7,171,893; Pemex 619,741;
  ISSFAM 583,175) eran exactamente esta misma construcción — personas ENIGH
  con el factor proyectado a CONAPO — y el motor nuevo los reproduce dígito
  por dígito (ese era el test de la construcción). La clase de fósil HTML
  muere: `poblarConteos()` en ambos JS sobreescribe la columna visible
  (spans `.pob-value`) y los `data-pop` desde `GASTOSPOB` en cada carga y en
  cada simulación; los números del HTML quedan como placeholder-snapshot con
  guard para motores sin el bloque.
- Sitio (ambos index): etiqueta "Asegurados"/"Insured" → "Derechohabientes
  (ENIGH 2024)"/"Beneficiaries (ENIGH 2024)" con tooltip ("Estimación ENIGH
  2024 ajustada a población CONAPO"); los 6 links de headers que apuntaban a
  ENIGH 2022 → 2024; el JS inglés NO tenía el handler del ± (gap preexistente
  del tablero) — portado idéntico al español.

### Datos
- Sin cambios de fuentes: misma ENIGH 2024 / CGPE 2026 (`data_updated`
  intacto — cambia la metodología de un derivado, no los datos).

Tests (todas las clases esperadas verificadas con harness batch old-vs-new,
ids aislados `users/cbase820`/`users/cnew820`): (a) conteos y PC de salud
según la tabla aprobada; (b) 5 `sankey-*.json` BYTE-IDÉNTICOS
(incidencia/deciles intactos) y `output.txt` byte-idéntico salvo los 8 PC de
salud de `GASTOSPC`; (c) par de `statalatex_gastopc` harness: SOLO los 16
getters `*Pob/*PC` de salud cambian, `*PIBgpc` intactos — el `.tex` trackeado
del libro (registro global-acumulado de la corrida textbook completa, ~4,400
líneas vs 368 del harness) se refresca en la próxima corrida real del libro;
(d) bloques `GASTOSPOB` bien formados (196/193 chars, 21+21 slots, cero
elementos no numéricos) y digeridos por los parsers de
`cargaDefault.php`/`checkStataStatus.php` simulados en PHP; (e) test del ±
declarado y observado: 1.520% (Δ +0.146 pp).

## [v8.1.0] — 2026-07-19

Reprocesamiento completo de PEF.dta (2013-2026) y rediseño de `UpdatePEF`:
las divisiones (divCIEP/divSIM/divFEDE) se anclan a códigos oficiales de la
Clasificación Funcional del Gasto del CONAC (pares finalidad/función) y a
texto normalizado de TIPOGASTO, con verificador de deriva año-por-año que
DETIENE el proceso ante cualquier mismatch (jamás clasificar en silencio).
Motivador: los selectores por códigos de `encode` (alfabéticos) derivaron con
cada categoría nueva — `desc_funcion==21` ("salud" al escribirse) apuntaba a
"cuotas a organismos internacionales de energía" y `desc_funcion==10`
("educación") a "asuntos financieros y hacendarios".

### Datos
- **CP 2013 entra completa por primera vez** (308,454 obs; antes 1 obs): el
  xlsx de SHCP trae una hoja pivote antes de la hoja de datos y el import
  tomaba la primera. `UpdatePEF` ahora detecta la hoja de datos (la de más
  filas) sin depender de xlsx curados a mano.
- **2025 pasa de PEF (aprobado) a Cuenta Pública** (`CP 2025.xlsx`, 210,459
  obs con ejercido/modificado/devengado/pagado; el asset `PEF.2025.xlsx`
  queda superseded y se elimina localmente). Gasto total 2025:
  10,940.5 → 11,417.7 mmdp (aprobado→ejercido).
- CP 2025 llega con esquema nuevo de SHCP (columnas sin prefijo `ID_`; el
  ramo viene en la columna `R` — el `Diccionario.csv` de SHCP la documenta
  como `RAMO`; discrepancia documentada en el código). El drop de columnas
  de 2 caracteres (hack para las ~180 columnas fantasma de CP 2022) se
  reemplaza por detección de columnas 100% vacías, que no mata UR/AI/PP/FF.
- `manifest.json`: SHAs nuevos de `CP.2013.xlsx` (sin hoja pivote) y
  `CuotasISSSTE.xlsx`; alta de `CP.2025.xlsx` y `Diccionario.csv`; baja de
  `PEF.2025.xlsx`. `data_updated` → 2026-07-19.

### Correcciones
- **(a3) Reclasificación Salud/Educación/Energía**: con las reglas CONAC,
  Salud pasa de 133.7→489.3 (2014) … 255.6→959.6 (2024) mmdp; Educación de
  451.7→712.5 (2014) … 620.9→1,124.1 (2024) mmdp — recuperan la función
  salud/educación en IMSS/ISSSTE/ramo 33 que la regla muerta perdía, y sale
  de Educación el gasto hacendario (41-244 mmdp/año) que la deriva le metió.
  Contraparte: divCIEP "Federalizado" y "Otros gastos" disminuyen en lo
  mismo. **El gasto total por año NO cambia** (verificado al peso, 2014-2024
  y 2026).
- **(a4) Comparaciones muertas por mayúsculas** (la limpieza pasa todo a
  minúsculas): FEIEF `modalidad=="Y"` (1.8-25.9 mmdp/año), INSABI/IMSS-B
  federalizado `modalidad=="U"` (67.8-105.3 mmdp/año, divFEDE "Salud
  (federalizado)" revive desde 2019), cuidados `ur=="V3A"/"V00"`
  (~0.3-0.8 mmdp/año), y `ur=="TZZ"/"TOQ"` en la homologación de ramo.
- Basura del pivote de CP 2013 eliminada: 66 obs sin año, variable
  `combustiblesyenergía`, y los labels fantasma "row labels"/"total result"
  en `desc_funcion`. Se limpia también la redundancia
  `desc_entidad_federativa` (quedaba junto a `entidad`).
- Evidencia contra anclar TIPOGASTO por id ("doble llave"): el id 4 fue
  "participaciones" en 2013-2015 y "pensiones y jubilaciones" desde 2016
  (SHCP renumeró el catálogo). El ancla correcta es el texto normalizado.

### Comandos
- `PEF.ado` v8.1: verificador de deriva (sección 4.0) corre en cada
  `UpdatePEF` — asserts por año de los pares CONAC (salud, educación,
  combustibles y energía) y whitelist de textos TIPOGASTO; mismatch → error
  459 con año y texto encontrado.
- Secciones 3.1/3.2 (series de Estadísticas Oportunas por códigos de encode)
  congeladas junto con la 3.3: el bloque completo se comenta y revive junto.
  `PEF.dta` pierde las variables muertas `serie_desc_funcion`/`serie_ramo`.
- `SubnacionalGasto.do` (legacy): comentario de advertencia — selecciona por
  códigos de encode que ya no significan lo que significaban.
- Contrato r() intacto: batería dorada con los nombres que consumen
  `GastoPC`/`Households`/`PerfilesSim`/`FiscalGap` corrida contra base vieja
  y nueva — ningún nombre se pierde; totales (`Gasto_neto`) idénticos; solo
  cambian los valores de las divisiones reclasificadas. Las etiquetas de los
  encodes se mantienen en minúsculas: los nombres de r() derivan del texto
  de las etiquetas y los consumidores dependen de su case exacto
  (`r(educacion_basica)` y `r(Baja_California)` conviven) — el plan de
  "etiquetas bonitas" queda diferido a un ciclo con migración de
  consumidores.

### Contrato de params de interfaz: string → NUMÉRICO
- Los 15 params de ingresos (`ISRASPIB`…`IMPORTPIB`) que `Web.Stata.do`
  declaraba entre comillas (string scalars) pasan a declararse SIN comillas,
  igual que las 5 reasignaciones de los submódulos ISR/IVA
  (`round(<Mod>, 0.001)` en vez de `"\`=round(...)'"`). Ambos flujos hablan
  igual: local vía `escalar` (SIM.do) y web vía template — y los `real()` a
  la lectura mueren con razón (FiscalGap:132 y los 4 sitios de SankeySF ya
  consumían numérico directo; sin esta migración el flujo web tronaba con
  type mismatch). Censo repo: cero `real()` sobre params restantes; los
  `real()` de parsing legítimo (`PEF.ado:678` regex, `TarjetaRFSP.do:25`
  fecha) no son params y quedan.
- **Mejora del modo de falla**: un placeholder `{{X}}` sin sustituir antes
  producía `real("{{X}}") = missing` — cero silencioso que se propagaba;
  ahora truena en SINTAXIS (r(198), visible en el log de sesión con el
  nombre del placeholder en la línea). Verificado con harness del contrato
  web (positivo: 155/155 sustituidos, corrida completa sin errores, bloques
  de `output.txt` idénticos en forma a la referencia; negativo: r(198)
  visible, cero bloques de datos producidos). Matiz registrado sin tocar:
  `calculaStata.php:63` sustituye `0` por default para params ausentes del
  POST — ese modo de falla silencioso es preexistente y de otro ciclo.
- Strings por diseño conservan comillas con comentario: `{{idSession}}`
  (id de sesión: paths) y `{{moduloCambio}}`/`{{moduloCambioIva}}` (flags en
  igualdad de strings; sin sustituir el módulo queda apagado — degradación
  intencional). `calculaStata.php` no se toca: `str_replace` es textual y
  las comillas vivían solo en el template.

## [v8.0.13] — 2026-07-18

Cierra la migración a `escalar` con `Simulador.ado` (excluido explícitamente
en v8.0.12): sus 9 sitios `string()` alimentan el alias `perf`, el mayor
consumidor del libro (414 usos). Con esto queda vigente el CONTRATO de
governance: **todo lo que alimenta el libro pasa por `escalar`** (regla
escrita donde vive el catálogo: header de `escalar.ado` y
`03_help/PROGRAMAS_AUXILIARES.md` §16). Cobertura verificada con censo
contra el libro: los 17 productores textbook + `Simulador.ado` registran
todo lo que el libro consume con formato; el residual "sin registrar" del
resumen (228 scalars en memoria) se auditó nombre por nombre — 211 son
scalars de trabajo internos que el libro NO referencia y 17 los consume
as-is numéricos con valor correcto (años de sesión `aniovp/anioPE/anioenigh/
aniofinal` y agregados `RFSPmax*`, `*gene*`, `pibVECES*`) — candidatos a
migración puntual en un ciclo futuro para dejar el resumen en 0 real.

### Comandos
- `Simulador.ado`: migrados los 9 sitios `string()` → `escalar` con tipos del
  catálogo: `<var>GPIB`→pctpib; `<var><decil>` (pesos por hogar)→mxnpc;
  `dis/inc<var><decil>`→pct; `<var>GIV/GVIIX/GX`→pct; `<var>GH/GM`→pct.
  Estos sitios corren también en cada simulación web (secciones 2, 4 y
  `poblaciongini` son incondicionales), no solo bajo textbook.
- `scalarlatex.ado` v2.1.0: el resumen de cobertura compara los sin-registrar
  contra el baseline auditado `02_governance/scalarlatex-baseline.txt` (228
  nombres) — dentro del baseline, línea informativa sin dump; nombres NUEVOS,
  aviso en rojo solo con esos nombres (la señal ya no se ahoga en 228 líneas
  permanentes). Procedimiento de actualización legítima en el header del
  baseline; sin el archivo (repo incompleto), cae al listado histórico.

### Correcciones
- Hallazgo de Fase A: `Simulador.ado:469` leía el scalar por-decil con
  `subinstr()` (función de strings) para armar la línea `INCD:` del flujo
  web — con el scalar ya numérico habría tronado con r(109) en CADA
  simulación web. Adaptado a `string(<scalar>,"%10.0f")`, que produce el
  mismo entero sin comas. Equivalencia demostrada empíricamente (lección del
  incidente v1.39): corrida batch con `$output=="output"` antes y después de
  la migración — líneas `INCD:`/`INCD2:`/`INCD3:` (y `APORT*`/`PROY*`)
  byte-idénticas.

### Test dorado (perfiles + acumulación)
- Los 9 `.tex` regenerados (corrida textbook completa, export a /tmp) y
  comparados getter por getter contra los vigentes: **519 getters cambiados,
  el 100% de la clase esperada** `*GIV/*GVIIX/*GX` entero → 1 decimal (108 en
  perfiles/fiscalgap/shrfsp, 90 en gastopc/tasas, 15 en households, por
  acumulación del registro global); **cero diffs de valor, cero getters
  nuevos**. Los 414 getters `perf` que usa el libro: 380 existen con el mismo
  nombre; los 34 restantes (`OtrosGastos*` sin T, `GATA*`) ya faltaban en el
  baseline — drift libro↔modelo preexistente, no regresión.
- Nota del test batch: `aniotdmin/aniotdmax` no se generan bajo `nographs`
  (se definen dentro del bloque de gráficas de `Poblacion.ado:197`) — artefacto
  del harness, preexistente; la corrida real del libro va con gráficas.

## [v8.0.12] — 2026-07-18

Pipeline textbook declarativo: los ~670 scalars que alimentan los documentos
LaTeX internos dejan de definirse con `noisily di %fmt` + relectura de logs de
pantalla (patrón fósil, frágil ante cualquier cambio cosmético de impresión) y
pasan a declararse con el nuevo comando `escalar <tipo> <nombre> = <exp>`,
que registra nombre y tipo semántico; `scalarlatex` exporta desde ese registro
con formato canónico por tipo. Cero impacto en el endpoint público. Los `.tex`
internos sí cambian de valores: la precisión completa y dos bugs corregidos
(ver Correcciones) mueven los agregados por decil de los módulos ENIGH.

### Comandos
- Nuevo `escalar.ado` (solo-repo): define el scalar y lo registra para
  exportación textbook con el catálogo de tipos pctpib, pct, mxn, mxnpc,
  personas, anio y custom(%fmt). Ver `03_help/PROGRAMAS_AUXILIARES.md` §16.
- `scalarlatex.ado` reescrito: aplica el formato canónico del registro
  `$scalarlatex_reg` en vez de releer `users/$id/*.txt`; ya no depende de
  `log on/off` ni de formatos de impresión. Los scalars sin registrar se
  exportan tal cual y se reportan (drift visible). Interfaz intacta
  (`log()`, `alt()`).
- Migrados los 17 archivos productores textbook (~670 sitios): PIBDeflactor, Poblacion,
  SCN, SHRFSP, TasasEfectivas, GastoPC, LIF, FiscalGap y módulos Households,
  PerfilesSim, Expenditure, ISR_Mod, IVA_Mod, output, Sankey(SF), Graphs_TE.
- El censo de cierre cazó 17 sitios omitidos en `Expenditure.do` (incluidos los
  round-trips `DifIVA`/`DifIEPSNP`, misma clase del bug del arrendamiento) y 10 en
  `FiscalGap.ado` (`tt*/td*/tn*` + años): migrados. El `real()` de FiscalGap:132
  sobre los params `*PIB` de SIM.do queda con comentario-INVARIANTE: son strings
  por diseño (interfaz web), igual que en SankeySF — no migrar.
- `Simulador.ado` (9 sitios `string()`, nombres dinámicos por decil) NO se migra
  en v8.0.12: corre en el VPS por cada simulación y exige ciclo propio con
  validación web. Registrado en bitácora v1.38 como candidato.

### Correcciones
- Cierra el AGUJERO CONOCIDO de v8.0.11: PIBDeflactor, Poblacion, SCN y SHRFSP
  publicados ahora hacen `capture which scalarlatex` bajo `textbook` y avisan
  amablemente que la opción es solo-repo, en vez de tronar con "command
  scalarlatex is unrecognized" en el endpoint.
- Los `\def` LaTeX con dígitos en el nombre (p.ej. `\dConsPriv21PIBscn`) se
  generaban rotos en silencio; `escalar` convierte dígitos a letras (0→A…9→J)
  y ahora esas macros son válidas.
- Los scalars "% del PIB" del SHRFSP se exportaban con 1 decimal (formato de
  pantalla); ahora 3 decimales canónicos. Padding accidental de `%07.1fc` y
  redondeos compuestos de la relectura de logs eliminados.
- BUG NUMÉRICO corregido (silencioso desde el origen del patrón): en
  `Households.do` el split arrendamiento pf/PM (`ing_t4_cap3pf`/`PM`) usaba
  `real(scalar(AlojT))` sin quitar comas; `real("940,573.4")` = missing, así
  que TODO el capítulo 3 (arrendamiento) se caía en silencio del ingreso mixto
  y del ingreso de capital (`rsum` trata missing como 0). Con el valor real,
  el ingreso mixto captado sube ~30% (MixLHHSPIB 1.861→2.421% PIB;
  DifMixL −86.5→−82.5%) y se recorren deciles, ahorro, cortes de formalidad
  ISR y la brecha fiscal (diffs de ±1–4% en fiscalgap/gastopc/households/
  perfiles/shrfsp/tasasEfectivas del test dorado).
  Causalidad DEMOSTRADA por prueba de aislamiento: código viejo + únicamente
  el fix del `subinstr` reproduce 4,315 de los ~4,900 valores que cambian
  (base→viejo+parche); el resto es precisión/formato del pipeline nuevo
  (viejo+parche→nuevo: 96 diffs = 16 escalares×6 alias, todos auditados:
  mismo valor con decimal nuevo o fin del redondeo a 0.1 mdp de la
  relectura). Residuo inexplicado: 0.
- Durante la migración, `SCN.ado` registraba `PIB` en millones con tipo
  `pctpib` mientras sus consumidores (Households, Expenditure, ISR_Mod)
  esperan pesos: ratios `*HHSPIB` salían 1e6 veces más grandes. Corregido a
  `escalar mxn PIB = PIB[obs]` (pesos, display idéntico al histórico).

## [v8.0.11] — 2026-07-10

El endpoint público se vuelve autosuficiente: un usuario externo que instala
un comando vía `net install` puede reconstruir los datos desde cero en SU
máquina, sin repo ni clone. Corrige un bug de arquitectura presente desde el
primer deploy del endpoint: los comandos publicados invocaban helpers y
dependencias que el endpoint no entregaba — nunca funcionó para un externo;
solo parecía funcionar porque siempre se probó desde el repo. Cero impacto
en resultados numéricos.

### Institucional
- Decisión de arquitectura: el endpoint DEBE permitir reconstruir datos desde
  cero — es abierto, reconstruir es la gracia. La solución es un ensure_asset
  de doble entorno con pin de versión quemado al publicar (ver Comandos), de
  modo que código y datos del externo siempre casan: reconstruye contra los
  assets del Release de SU versión instalada.
- AGUJERO CONOCIDO PENDIENTE (no corregido en este bump): `scalarlatex` es
  invocado por PIBDeflactor, Poblacion, SCN y SHRFSP bajo la opción `textbook`
  (insumos LaTeX internos CIEP) y NO se publica al endpoint — un externo que
  active esa opción verá "command scalarlatex is unrecognized". Fix futuro:
  `capture which scalarlatex` + aviso amable de que textbook es solo-repo.

### Comandos
- ensure_asset ahora funciona sin repo (doble entorno): si encuentra
  `05_scripts/manifest.json` en el site (caso repo), comportamiento intacto;
  si no, usa el pin de versión que publicar-endpoint.sh quema en la copia
  publicada para descargar el manifest de GitHub por tag
  (raw.githubusercontent.com/<repo>/<tag>/05_scripts/manifest.json), lo
  cachea por versión en `raw/temp/manifest-<tag>.json`, valida que la
  versión del manifest coincida con el pin (drift → error ruidoso nombrando
  la URL) y continúa con la descarga de assets ya existente. El .ado del
  REPO lleva el pin VACÍO — solo la copia publicada lo lleva relleno.
- ensure_asset se publica al endpoint (sale de la lista de exclusión de
  manifest-endpoint.toml); viaja dentro de los .pkg que lo necesitan, sin
  paquete propio de cara al usuario.

### Datos
- Sin cambios respecto a v8.0.10.

### Correcciones
- Clausura transitiva de dependencias en 6 .pkg: cada paquete ahora declara
  TODAS sus dependencias .ado (quien instala PEF recibe también
  DatosAbiertos, AccesoBIE, Poblacion y ensure_asset; análogo para
  DatosAbiertos, LIF, PIBDeflactor, SCN y SHRFSP). Antes, instalar un
  paquete individual dejaba fuera eslabones de su cadena de reconstrucción
  y el comando tronaba con "command ... is unrecognized".
- publicar-endpoint.sh verifica la inyección del pin y ABORTA si el marcador
  no está — imposible publicar un ensure_asset sin pin por accidente.
- Hallazgos del test de "máquina virgen" (instalar SOLO desde el endpoint y
  reconstruir), corregidos de paso — tres bugs que solo muerden fuera del
  repo:
  - ensure_asset descarga con `requests` en lugar de `urllib`: urllib truena
    con CERTIFICATE_VERIFY_FAILED en Pythons sin certificados configurados
    (caso típico de instalación de python.org en macOS); requests trae sus
    propios certificados (certifi) y ya es dependencia dura de la suite
    (AccesoBIE la importa).
  - `mkdir master/` antes de cada save de la cadena de reconstrucción (LIF,
    PEF ×2, SCN, SHRFSP, Deflactor): en una máquina sin repo el directorio
    no existe y el save tronaba con r(603) — mismo bug de instalación fresca
    que v8.0.9/v8.0.10, en otra capa.
  - Eliminado un guard `if c(console)==console { exit }` en
    UpdateDatosAbiertos que abortaba la reconstrucción EN SILENCIO en Stata
    console/batch — el comando anunciaba "ACTUALIZANDO..." y salía sin
    hacer nada, dejando un r(601) críptico aguas abajo. Hacía imposible
    reconstruir en batch (p.ej. servidores).

## [v8.0.10] — 2026-07-10

AccesoBIE deja de exigir token para funcionar: sin token, usa la consulta
pública de exportación (.aspx) del INEGI — una vía que YA existía como
respaldo automático cuando la API falla, pero que era inalcanzable sin
token porque el comando abortaba antes de intentarla. Los comandos
publicados del Simulador dejan de depender de que el usuario externo
tenga token. Cero impacto en resultados numéricos.

### Institucional
- Nota de diseño sobre la vía pública (.aspx), con honestidad sobre su
  fragilidad: el *mecanismo* es oficial y abierto (el endpoint de
  exportación a Excel del propio portal del BIE, sin auth), pero la
  *implementación* parsea la tabla HTML de la respuesta con
  BeautifulSoup — más frágil que el JSON de la API: se rompe si INEGI
  cambia el layout de esa tabla. Es aceptable distribuirla porque (a) ya
  era camino de producción activo (corría cada vez que la API fallaba),
  (b) no introduce dependencias nuevas, y (c) el fallo es visible, no
  silencioso. Por esa fragilidad, la API con token sigue siendo la vía
  recomendada.

### Comandos
- AccesoBIE sin token: ya no aborta con exit 198 inmediato. Usa la
  consulta pública (.aspx) como vía única, con aviso visible de por cuál
  vía se obtuvieron los datos y de cómo conseguir el token gratuito.
  Sin token NO se golpea la API (no se hacen requests con token vacío).
  Ambas vías entregan exactamente el mismo formato de salida.
- AccesoBIE: exit 198 pasa a ser el fallo FINAL — solo cuando una serie
  no se pudo obtener por ninguna vía — con mensaje que nombra la serie y,
  si no hay token, explica que solo se intentó la vía pública.

### Datos
- Sin cambios respecto a v8.0.9.

### Correcciones
- AccesoBIE: si una serie no se obtenía (p.ej. clave inexistente), el
  comando mostraba un error y seguía (continue), dejando tempfiles
  indefinidos que después tronaban en el use/merge con un error críptico
  lejos de la causa. Ahora el error truena en su origen, claro y
  nombrando la serie.
- AccesoBIE: mismo bug de instalación fresca que v8.0.9 en DatosAbiertos
  — mkdir no recursivo —: el árbol site/raw/temp/AccesoBIE/ ahora se crea
  nivel por nivel.

## [v8.0.9] — 2026-07-10

DatosAbiertos aprende a descargar con respaldos: la opción `update` ahora
intenta el zip (dos veces, por errores transitorios de conexión), si falla
cae al csv directo, y si también falla usa los archivos locales de
`raw/temp/`. Antes, `update` sin más opciones ni siquiera descargaba —
leía los archivos locales en silencio. La opción `files` se renombra a
`local` y los 33 bloques repetidos de descarga se colapsan en un programa
auxiliar. Cero impacto en resultados numéricos.

### Institucional
- DatosAbiertos.ado: los 33 bloques idénticos `csvfile/zipfile/else`
  (~550 líneas, uno por base del portal SHCP) se colapsan en el programa
  auxiliar `_DAdescarga`, que concentra la cadena de respaldos en un solo
  lugar. Arreglar un problema de descarga ahora es un cambio de una línea,
  no de 33.

### Comandos
- DatosAbiertos, `update`: ahora descarga de verdad, con cadena de
  respaldos automática (zip con reintento → csv directo → archivos
  locales). Cada caída de la cadena se anuncia en pantalla; si tampoco hay
  archivo local, el error truena en su origen.
- DatosAbiertos, `zipfile`: se conserva por compatibilidad; hoy equivale a
  la cadena completa de `update`.
- DatosAbiertos, `csvfile`: brinca el zip y va directo al csv en línea;
  si falla, usa los archivos locales.
- DatosAbiertos, `local` (nueva): reconstruye la base desde los archivos
  ya descargados en `raw/temp/`, sin internet. Sustituye a `files`, que
  se retira — quien la use recibirá el error estándar "option files not
  allowed".

### Datos
- Sin cambios respecto a v8.0.8.

### Correcciones
- DatosAbiertos: la primera corrida en una instalación fresca tronaba con
  r(170) — `mkdir` de Stata no es recursivo y el árbol
  `site/raw/temp/Datos Abiertos/` no se creaba si faltaba algún nivel
  (una instalación nueva no trae ni `site/`). Ahora el árbol se crea
  nivel por nivel antes de usarse.
- DatosAbiertos: las descargas ahora van con `copy` (que acepta URLs en
  cualquier versión de Stata) en lugar de `unzipfile`/`import delimited`
  con URL directa, que no son portables entre versiones — en algunas, el
  intento de zip fallaba al instante sin llegar a la red. Los mensajes de
  la cadena de respaldos ahora incluyen el código de error de Stata para
  poder diagnosticar la causa (conexión, servidor, archivo inexistente).

## [v8.0.8] — 2026-07-10

La cadena del token BIE/INEGI se endurece de punta a punta: SIM.do deja
de tragarse errores reales al cargar el token, profile.do lo carga al
abrir Stata (los investigadores CIEP ya no necesitan correr SIM.do para
usar AccesoBIE), y el mensaje de error de AccesoBIE ahora dice qué hacer
según quién seas. Cero impacto en resultados numéricos.

### Institucional
- SIM.do: el `capture do set_token.do` ciego (que ocultaba errores de un
  token mal configurado) se reemplaza por `confirm file` + `run` sin
  capture. Ahora distingue archivo ausente (aviso amable con el camino:
  copiar `set_token.template.do` a `set_token.do`) de archivo roto (el
  error se ve en su origen). SIM.do sigue siendo autocontenido: carga su
  propio token después del `macro drop _all` del arranque.
- profile.do: carga el token al arranque interactivo con el mismo patrón.
  Si falta, la bienvenida incluye una nota amable con el camino para
  configurarlo — sin error rojo, el arranque no se interrumpe.

### Comandos
- AccesoBIE: mensaje de error mejorado cuando falta el token. Ahora sirve
  a dos audiencias: usuario externo (cómo fijar `global BIE_API_TOKEN` y
  el link del INEGI para obtener token) e investigadores CIEP (correr
  set_token.do o reiniciar Stata). La validación con `exit 198` ya
  existía; solo cambió la redacción. Sin cambios en sintaxis ni
  resultados.

### Datos
- Sin cambios respecto a v8.0.7.

## [v8.0.7] — 2026-07-09

SCN deja de depender de un directorio externo para su intermedio de PIB:
el archivo temporal `raw/temp/basepib.dta` se reemplaza por un `tempfile`
de Stata. En instalaciones donde `raw/temp/` no existía (por ejemplo, un
deployment limpio del servidor web), SCN tronaba con r(603) al intentar
guardar ahí. Cero impacto en resultados numéricos.

### Institucional
- SCN.ado: el intermedio `basepib` ahora vive en un `tempfile` (Stata lo
  crea donde corresponde y lo limpia solo), en lugar de escribir y leer
  `raw/temp/basepib.dta`. Mismo principio que `ensure_asset`: los comandos
  no asumen estado de directorios externo.
- Detectado durante el debugging del primer deploy del motor web v8.0 al
  VPS (2026-07-09); el pipeline de deployment también se endureció en el
  mismo commit (fases de permisos y assets — no afecta a los comandos).

### Comandos
- Sin cambios en sintaxis, opciones ni resultados de SCN. El cambio es
  interno (dónde vive un archivo temporal).

### Datos
- Sin cambios respecto a v8.0.6.

## [v8.0.6] — 2026-07-07

Fixes estéticos coherentes en las gráficas de dos comandos del canon
(PIBDeflactor y SCN): eliminar del eje temporal los años que solo contenían
datos missing, que hacían que las gráficas se vieran incompletas y con
huecos visuales. Cero impacto en resultados numéricos.

### Institucional
- PIBDeflactor.ado (gráfica de Productividad): filtro del `if` y del `tlabel`
  ajustados para mostrar solo años con datos válidos. Bloque `yline` + `text`
  de diferencia 2005-aniofinal preservado comentado (decisión del
  investigador principal para posible reactivación futura).
- SCN.ado (2 gráficas): `xlabel` del eje X ahora llega hasta `latest`
  (último año con datos reales) en lugar de `aniomax` (año máximo teórico).
- SIM.do: cambio de comportamiento default — por defecto muestra gráficas
  (`global nographs` comentado). Antes suprimía gráficas por default.
  Solo afecta a investigadores CIEP internos que corren SIM.do.

### Comandos
- Sin cambios en sintaxis, opciones ni datasets de PIBDeflactor y SCN.
  Los cambios son puramente visuales en las gráficas generadas.

### Datos
- Sin cambios respecto a v8.0.5.

## [v8.0.5] — 2026-07-04

Nuevo Gate 4 en pipeline de publicación: validación de existencia de archivos
declarados en manifest-endpoint.toml. Antes de crear la Release en GitHub,
publicar.sh verifica que cada archivo declarado como ado_files, sthlp_files,
y pkg_files existe físicamente en el filesystem del repo. Si algún archivo
falta, aborta con error informativo. Habría atrapado el bug de AccesoBIE.pkg
(v8.0.3 fix).

### Institucional
- Nuevo Gate 4 en publicar.sh valida existencia de archivos declarados en
  manifest-endpoint.toml antes de crear Release GitHub y rsync al endpoint.
- Los gates semánticos candidatos (autoría, URLs, prueba de humo automatizada)
  se descartan formalmente. Revisión visual del .sthlp por el investigador
  cubre autoría y URLs. Prueba de humo manual desde Stata externo (net from +
  net describe) es el gate humano institucional para validación semántica de
  paquetes publicados.

### Comandos
- Sin cambios de comportamiento en los comandos del canon.

### Datos
- Sin cambios respecto a v8.0.4.

## [v8.0.4] — 2026-07-04

Fix: corrige link para obtener el token del BIE/INEGI. El link anterior
(https://www.inegi.org.mx/servicios/api_biinegi.html) era una página obsoleta.
El link correcto es el generador de tokens de INEGI:
https://www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx
(compartido con DENUE, ya que INEGI usa un único sistema de tokens).

### Institucional
- 03_help/Stata/AccesoBIE.sthlp: link del {browse} corregido al generador
  de tokens vigente.
- AccesoBIE.ado: mensaje de error apunta al link correcto.
- set_token.template.do: comentario del template apunta al link correcto.

### Comandos
- Sin cambios de comportamiento. AccesoBIE mantiene sintaxis y datasets.

### Datos
- Sin cambios respecto a v8.0.3.

## [v8.0.3] — 2026-07-04

Fix: agrega 05_scripts/AccesoBIE.pkg que estaba declarado en el manifest del
sub-canal Stata público pero nunca existió en el filesystem. Este bug estaba
presente silenciosamente desde v8.0 y solo se destapó al probar
`net describe AccesoBIE` desde Stata externo tras la publicación de v8.0.2.

### Institucional
- Nuevo 05_scripts/AccesoBIE.pkg permite que investigadores externos hagan
  `net describe AccesoBIE` y `net install AccesoBIE` correctamente.
- manifest-endpoint.toml actualizado para incluir AccesoBIE.pkg en pkg_files.
- Corrección de typo en los 8 .pkg: "finanzas púbicas" → "finanzas públicas"
  (texto visible para investigadores externos en `net describe`).

### Comandos
- Sin cambios de comportamiento. Los comandos mantienen sintaxis y datasets.

### Datos
- Sin cambios respecto a v8.0.2.

## [v8.0.2] — 2026-07-04

Cambio menor de metadata: los 11 archivos .sthlp del canon (AccesoBIE,
DatosAbiertos, LIF, PEF, PIBDeflactor, Poblacion, SCN, SHRFSP, GastoPC,
TasasEfectivas, sim_changelog) ahora incluyen autoría del investigador
principal + correo institucional clicable en el encabezado.

### Institucional
- Encabezado de los .sthlp muestra ahora: "Centro de Investigación Económica
  y Presupuestaria, A.C. | ciep.mx" seguido de "Ricardo Cantú Calderón |
  ricardocantu@ciep.mx" (correo abre cliente de mail al hacer clic).

### Comandos
- Sin cambios respecto a v8.0.1. Los comandos mantienen sintaxis, opciones,
  resultados y datasets.

### Datos
- Sin cambios respecto a v8.0.1. Assets del data sidecar son idénticos.

## [v8.0.1] — 2026-07-03

Cleanup documental. La ayuda de comandos institucionales del canon queda consolidada
en archivos .sthlp como fuente única de verdad. Los .md descriptivos que vivían en
paralelo desde febrero 2026 fueron migrados (contenido metodológico que sobrevivió
la auditoría de sincronía .ado/.sthlp) o eliminados. El manual del investigador se
movió de manuales/ a help/.

### Institucional
- Los .md de ayuda de los 8 comandos del canon (AccesoBIE, DatosAbiertos, LIF, PEF,
  PIBDeflactor, Poblacion, SCN, SHRFSP) fueron consolidados en sus respectivos .sthlp
  y eliminados. Nueva subsección 2.7 en 02_governance/arquitectura-y-bitacoras.md
  formaliza el principio "la ayuda de comandos vive en .sthlp".
- Manual del investigador movido de manuales/ a help/ (unifica dominio "help").
- README.md corregido: rutas de imágenes rotas apuntan a help/images/; bloques con
  imágenes fantasma eliminados; entrada canónica a la ayuda ahora es help <comando>.
- Hallazgo #3 de 02_governance/historico/auditoria-drift-sthlp.md marcado como resuelto.

### Comandos
- Sin cambios respecto a v8.0. Los comandos mantienen la misma sintaxis, opciones,
  resultados y datasets. Solo cambia el contenido de la ayuda (más rico, sin drift).

### Datos
- Sin cambios respecto a v8.0. Las fuentes y assets del data sidecar son idénticos.

## [v8.0] — 2026-05-29

**Primera versión bajo arquitectura institucional completa.** Marca el inicio de la era
reproducible: a partir de v8.0 cualquiera puede reconstruir código + datos exactos usados
para producir un resultado citado del Simulador.

### Institucional
- Data sidecar publicado en GitHub Release v8.0 con 23 archivos de fuentes (PEFs, LIFs,
  ENIGH, CuotasISSSTE, ISRInformesTrimestrales, CP históricos).
- Sub-canal Stata público automatizado: `net from https://ciep.mx/simuladorfiscal/`
  sirve los 8 paquetes principales sin necesidad de tener acceso al repo.
- `manifest.json` en la raíz del repo declara el Catálogo de datos asociados con
  huellas digitales SHA-256 y URLs de descarga.
- `publicar.sh` publica una versión nueva al endpoint público en un solo comando.
- Governance formal documentada en el directorio `governance/`.
- Convenciones de Git, versionado y publicación formalizadas en `02_governance/versionado-y-git.md`.

### Comandos
- Sin cambios respecto a v7.0. Los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`,
  `SHRFSP`, `DatosAbiertos`, `AccesoBIE` mantienen la misma sintaxis y opciones.
- `GastoPC` y `TasasEfectivas` continúan en desarrollo, no publicados oficialmente.

### Datos
- Las fuentes de datos son las mismas que v7.0. La ruptura de v8.0 es institucional
  (reproducibilidad, publicación formal), no metodológica ni de fuentes.

## [v7.0] — 2026-05-23

**Última versión del Simulador como proyecto personal del investigador principal.**
Transición del Simulador desde código operativo con conocimiento metodológico
principalmente tácito hacia infraestructura institucional. El mensaje del tag lo captura:
"Data sidecar publicado (transición v7.x → v8.0)."

### Institucional
- Migración inicial de datos: de URLs personales de Dropbox a assets de GitHub Release v7.0.
- `manifest.json` inicial (23 assets con SHA-256).
- Introducción de `ensure_asset.ado` para descarga verificada de fuentes.
- Rewrite de historia Git para purgar credenciales expuestas y binarios pesados
  (repo: 5.1 GB → 49 MB).
- Externalización del token BIE/INEGI mediante `set_token.do` gitignored + plantilla
  `set_token.template.do` versionada.
- Cierre del canal manual `Stata net/`: los `.ado` viven solo en el root del repo.

### Comandos
- Los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`, `SHRFSP`, `DatosAbiertos`,
  `AccesoBIE` están disponibles y funcionales.
- Refactor de los `.ado` para usar `ensure_asset` en lugar de URLs hardcoded a Dropbox.

### Datos
- Fuentes: PEFs (2013-2026), CPs, ENIGH (2014-2024), LIFs, CuotasISSSTE,
  ISRInformesTrimestrales.
