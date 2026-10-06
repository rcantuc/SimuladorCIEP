# nl-estilo.md — Gramática de comunicación de la capa NL (BORRADOR F0, 2026-10-04)

> Estado: **borrador para corrección de Ricardo**. Lo que él corrija aquí es canon desde NL-0.4.0.
> Fuente de verdad del inventario: código del motor v8.6.0 (archivos citados en cada fila), leído el 2026-10-04; ninguna regla se inventó sin su patrón de origen o sin declararla como patrón nuevo.

## 0. Reglas permanentes (vigentes desde NL-0.4.0)

1. **Ninguna vista nueva sin patrón declarado.** Cada vista de un endpoint NL cita el patrón del canon (§2) que la cuenta o declara "patrón nuevo" con justificación en `DIAGNOSTICO_NL.md`. El JSON del endpoint lleva `presentacion.patrones[]` con esa declaración, y la plantilla HTML la repite en un comentario junto a cada vista.
2. **Doble registro obligatorio** para toda cifra agregada: **antropocéntrico** (per cápita / por beneficiario; registro por defecto y titular de tarjetas) y **macro** (nivel nominal, real y % PIBE), conmutables con un **toggle persistente** cuyo estado viaja en la URL con la misma clave en todos los endpoints: `#reg=pc|macro` y, dentro de macro, `medida=nominal|real|pibe`.
3. **El denominador es dato con procedencia.** Población = `PoblacionNL` (CONAPO vía `master/Poblacion.dta`) de la **misma corrida/vintage** que el numerador; compuerta que aborta si el sello de población del JSON consumidor no coincide con el del productor. Otros denominadores (beneficiarios, contribuyentes, ocupados) solo si el canal los provee; se declaran en `definiciones.denominadores`.
4. **Tarjetas en persona-escala:** titular per cápita (con banda cuando exista), subtítulo macro (nivel y % PIBE), tercera línea = comparativo (nacional o lugar entre 32) cuando aplique.
5. **Colores fijos entre endpoints** (§3). Cada HTML consume los mismos tokens desde `nl-assets/nl-datos.js` (bloque `NLEstilo`), no define los suyos.
6. **Procedencia visible:** pie con fuente, vintage, versión de capa y motor, sello de corrida y log; modo datos con encabezado de procedencia en cada extracto (ya vigente desde NL-0.2.0).

## 1. Doctrina de registro (resumen operativo)

| Elemento | Registro antropocéntrico (default) | Registro macro (toggle) |
|---|---|---|
| Unidad | MXN por persona (o por beneficiario) del año VP; formato `%10.0fc` (catálogo `mxnpc` de `escalar.ado`) | MXN corrientes/constantes en millones (`mxn`, `%12.1fc`, divisor 1e6) y % PIBE (`pctpib`, `%7.3fc`) |
| Titular de tarjeta | per cápita **con banda** si existe (S1–S3) | nivel y % PIBE como subtítulo |
| Series | per cápita real (año VP) | nominal / real / % PIBE |
| Comparativo | NL vs nacional per cápita; lugar de NL entre 32 | participación de NL en el total nacional (%) |
| Denominador | `pobNL[t]`, `pobNac[t]` de `master/Poblacion.dta` (vintage declarado) | `pibeNnl[t]` de `actividad-nl.json` (tipo observado/nowcast/proyección por celda) |

Patrones del motor que fundan la doctrina (familia de referencia, documentada con prioridad en §2.1): `outputPW*`/`pibYPC` (PIBDeflactor), `GastoPC` (gasto por alumno/asegurado/persona), `gastoPC`/`recaudacionPC` en los displays de PEF/LIF, `monto_pc` en DatosAbiertos/nodo-deuda.

## 2. Inventario de la gramática visual del motor (v8.6.0)

### 2.1 Familia per cápita (referencia)

| Patrón | Dónde | Concepto que cuenta | Gráfica / tabla | Color y énfasis | Ordenamiento | Anotaciones |
|---|---|---|---|---|---|---|
| **PIB per cápita con crecimiento** | `PIBDeflactor.ado` §7 (`pib_pc`, 687-731) | nivel de producto por persona (miles MXN VP) y su variación anual | `twoway bar` del nivel (eje 2) + `connected` punteado de la variación (eje 1); **tres tramos** del mismo dato: observado / Paquete / proyección como series separadas | tramos = `p1/p2/p3` (observado, Paquete, proyección) con `mlabel` gris `111,111,111`; sin ejes (`ylabel(none)`), el dato va etiquetado sobre la barra | cronológico; `xlabel` desde `round(geopib,5)` | `yline` del crecimiento promedio + texto "Crec. prom. a–b: x %"; cajas de texto blancas marcando "miles MXN VP per cápita", "$paqueteEconomico", "Proyección" |
| **Productividad laboral (producto por ocupado)** | `PIBDeflactor.ado` §7.1 (399-426); escalares `outputPWI/outputPW/outputPWVECES` | PIB real / población ocupada ENOE | `twoway` con tres ejes: barras PIB (billones) y población ocupada (millones), línea de productividad (miles MXN) | `pstyle(p2)` PIB, `p1` ocupados, `p3` productividad; etiquetas grises sobre los puntos | cronológico 2005– | escalares I/F y "veces" (variación % entre año inicial y VP) para el texto |
| **Gasto per cápita por beneficiario** | `GastoPC.ado` §3.10 (475-534) y análogos salud/pensiones; `Graphs_PC.do` | gasto por alumno (nivel educativo), por asegurado (institución de salud), por pensionado, por persona (cultura, ciencia, SSa, inversión) | **tabla**: concepto · denominador (`Alumnos`/asegurados) · `% PIB` · `PC (MXN VP)`; serie 2013–anioPE con `twoway connected` de todos los conceptos del bloque | líneas `p1..pn` del scheme vigente, sin énfasis individual; totales en **negritas** entre reglas `_dup(71) "-"` | tabla: niveles de menor a mayor edad/escolaridad; total al final; "gasto público total" separado por regla | `ytitle("MXN VP")`, `yscale(range(0))`, `ylabel(,format(%9.0fc))`, leyenda abajo en 1–3 filas |
| **Deuda per cápita** | `SHRFSP.ado` 510-545; `nodo-deuda.do/.html` | saldo de deuda por persona (miles MXN VP) junto al nivel y la población | barras del saldo + línea per cápita (eje 2) + población (eje 3); en web: **tabla desnuda** Monto · % PIB · % Tot · MXN PC | observado `p1/p2` con `fintensity(40)` para lo proyectado; `p3` la línea per cápita | cronológico 2000– | cajas "Observado" / "$paqueteEconomico"; `xline(anioPE-.5)` punteada gris `gs10` separando el Paquete |
| **Displays PEF/LIF** | `PEF.ado` §5.1 (195-250), `LIF.ado` §4.2 (240-) | nivel por grupo del año `anio` | tabla a 4 columnas: `MXN` · `% PIB` · `% Tot` · `MXN PC`; conciliación bruto→neto con renglones `(+)`, `(−)`, `(=)` | totales `{bf:}`; regla `_dup(78) "-"` | orden del `by` (divCIEP/divSIM); el `(=)` cierra | la columna per cápita usa `Poblacion` de `PIBDeflactor` (misma corrida) |

### 2.2 Composición y evolución (niveles)

| Patrón | Dónde | Concepto | Gráfica | Color / énfasis | Orden | Anotaciones |
|---|---|---|---|---|---|---|
| **Barras apiladas por año (% PIB)** | `LIF.ado` 550-563, `PEF.ado` 582-605 | composición de ingresos / gasto por grupo y su evolución | `graph bar … over(resumido, sort(1) descending) over(anio, gap(25)) stack asyvars` | scheme `ingresos`/`ciep`; PEF asigna colores explícitos por posición y **atenúa a 30 % de opacidad** todo lo que no sea el grupo `highlight()` | grupos de **mayor a menor** dentro de cada año (`sort(1) descending`); los menores a `min()` % PIB se agrupan en "_menor_a_x_PIB" / "Otros (< x % PIB)" | `blabel(bar, %5.1fc)` sobre cada segmento; `b1title` con la oración "De a a b, el gasto aumentó/disminuyó x pp del PIB"; leyenda abajo (`position(6)`), `rows()/cols()` configurables |
| **Tasas efectivas históricas** | `Graphs_TE.do` | TE por tipo de impuesto 2000–anioPE | `twoway connected` por serie, un panel por familia (trabajo, capital, consumo, organismos) | `p1..p5` del scheme | orden fijo por familia (ISR AS, ISR PF, cuotas…) | `yscale(range(0))`; texto "De 2000 a anioPE la TE de X creció y pp" colocado con `text()`; `caption` de fuente |
| **Deflactor / inflación / crecimiento** | `PIBDeflactor.ado` 478-523, 579-618, 793-839 | nivel real y variación | barras del nivel + `connected` punteado de la variación; **tres tramos** (observado / Paquete / proyección) | `p1/p2/p3`; leyenda apagada, sustituida por cajas de texto | cronológico | `yline` del promedio geométrico con etiqueta "Crec. prom."; `b1title` "1 MXN de a = x MXN en VP" |
| **Deuda (SHRFSP/RFSP)** | `SHRFSP.ado` 451-491 | saldo (billones) y flujo (RFSP) con % PIB | barras saldo + barras flujo + línea % PIB (eje 2) | p2 saldo, p1 flujo, p3 línea; proyección `fintensity(50)` | cronológico | `xline(anioPE-.5)` dash gs10; cajas "billones MXN VP", "$paqueteEconomico", "% PIB" |

### 2.3 Distribución (quién recibe / quién paga)

| Patrón | Dónde | Concepto | Gráfica | Color / énfasis | Orden | Anotaciones |
|---|---|---|---|---|---|---|
| **Pirámide por edad y sexo con grupos de ingreso** | `Simulador.ado` `graphpiramide` (1034-1077), `poblaciongini` (843-867) | distribución por edad de un impuesto o gasto, por sexo y por deciles **I–V / VI–IX / X** | `graph hbar (sum) … over(grupo) over(edad, descending) stack asyvars xalternate`, hombres a la izquierda (`xalternate`) y mujeres a la derecha, `graph combine … ycommon xcommon` | tres tonos del scheme por grupo de deciles; etiquetas de edad cada 5 años | edad descendente (109 arriba); sexo H/M | `t2title` "{bf:Hombres}: x %"; leyenda con participación por grupo de edad (0-18 / 19-65 / 65+) y por decil |
| **Pirámide poblacional** | `Poblacion.ado` 363-414 | estructura por edad/sexo en dos años | `twoway bar … horizontal` por sexo; panel inicial y final; "Por nacer" / "Vivos en a" | p1 (H) / p2 (M) por defecto del scheme; textos grises `111,111,111` | edad simple 0–109 | total en texto grande dentro de la pirámide |
| **Áreas por grandes grupos de edad** | `Poblacion.ado` 517-532 | millones de personas 0-18 / 19-60 / 61+ | `twoway area` apilada | p1/p2/p3 | cronológico | `xline(anioinicial+.5)`; texto "Max (grupo): x % (año)" |
| **Incidencia por decil (INCD)** | `output.txt` INCD/INCD2/INCD3; `EntidadNL.do` §4 | % del ingreso del decil por tipo de impuesto | **tabla** Decil · AlTrabajo · AlCapital · AlConsumo · OTROSK · Total; nota de suma | totales `Tot` en negritas | deciles I→X, Tot al final | nota "AlCapital incluye OTROSK y el Total lo excluye" |

### 2.4 Flujos (Sankey)

| Patrón | Dónde | Concepto | Construcción | Color / énfasis | Orden | Anotaciones |
|---|---|---|---|---|---|---|
| **Sankey Sistema Fiscal** | `SankeySF.do` + `SankeySumSim.ado` | de dónde sale el dinero (impuestos al trabajo/consumo/capital por decil, empresas públicas, FMP, endeudamiento) → **nodo central "$paqueteEconomico"** → a dónde va (educación, salud, pensiones, transferencias, inversión por decil; estados y municipios; costo de la deuda; energía; no distribuibles) | 4 ejes (`a`→`b` total izquierdo, `c`→`d` total derecho): `from/to/profile`; FusionCharts `sankey` horizontal, `linkalpha 30`, `linkhoveralpha 60`, `nodelabelposition start`, sin leyenda | color por nodo (tema `fusion`); el **nodo central** es la referencia visual | el orden vertical se fuerza con guiones bajos antepuestos a la etiqueta (`_Futuro`, `__El mundo`) — convención del motor | el cierre contable **siempre** aparece como nodo: "Endeudamiento → Futuro" si gasto > ingreso, "Ahorro → Futuro" si no |
| **Sankey NTA (Sankey.do)** | `Sankey.do` | generación del ingreso (laboral, capital, alquiler por decil; OyE públicas; el mundo) → "Ing nacional" → consumo por rubro, bienes públicos, ahorro | misma mecánica | — | — | muestra remesas y turistas como flujos del "mundo" |
| **Sankey Pemex / CFE** | `SankeyPemex.do`, `SankeyCFE.do` | flujos de ida y vuelta de una entidad con la Federación (ingresos propios, transferencias, impuestos pagados, inversión) | misma mecánica, nodo central = la entidad | — | — | precedente directo de un **balance de flujos bidireccional** en el canon |

### 2.5 Schemes (`scheme-*.scheme`, raíz del repo)

| Scheme | Uso (`set scheme` en `SIM.do`/`profile.do`) | Qué cambia respecto a `ciep` |
|---|---|---|
| `ciep` | default (`profile.do:27`, `SIM.do:10`); gasto (`SIM.do:289`) | base `s2color`; 16×7; fondo blanco; texto/ejes gris `111,111,111`; grid `200,200,200` discontinuo; leyenda abajo (`clockdir 5`) sin marco; sin línea de eje; `yline` gris discontinua; **paleta** p1 naranja CIEP `255,128,0`, p2 amarillo `255,189,0`, p3 verde bandera `53,199,72`, p4 celeste `23,151,201`, p5 rojo fuego `255,55,0`, p6 rojo institucional `186,34,64`, p7 aguamarina `57,197,183`, p8 verde lima `102,177,0`, p9 vino CIEP `150,6,92`, p10 verde jade `0,179,147`, p11 azul CIEP profundo `0,78,198`, p12 terracota `194,76,68`, p13 coral claro `254,118,109`, …, p22 negro técnico `34,34,34`, p23 gris claro `175,174,180`, p24 beige `243,243,233` |
| `ingresos` | `SIM.do:127` (LIF) | misma tipografía; paleta reordenada: p1 rojo institucional, p2 verde `40,172,58`, p3 naranja pastel, p4 rojo fuego, p5 verde petróleo … |
| `deuda` | `SIM.do:401,475` | gris `114,113,118`; leyenda 4 columnas, etiquetas pequeñas; paleta cálida (vinos/naranjas) en p7–p15 y fría (verdes/azules) en p1–p6, p16–p20 |
| `educacion` / `salud` / `energia` | módulos temáticos (libro) | 16×5; `tick_label large`; paletas temáticas (salmón/turquesa/amarillo; magenta/amarillo/turquesa…; rojos→naranjas→verdes→azules) |
| `cuidados` | módulo cuidados | sin líneas en `lineplot` (solo marcadores) |
| web (`portada.html`, `nodo-deuda.html`) | nodos del Paquete | tokens CSS: `--ciep-orange #d76f33`, `--ciep-orange-light #ff874d`, `--ciep-gray #999b9c`, `--ciep-beige #f3f3e9`, `--ciep-black #1F1F1F`; `nodo-deuda` acento azul `#2a78d6/#3987e5`, papel `#fbfbf9`, tinta `#14140f`; **lenguaje "ultra-austero"**: tabla desnuda + costura/procedencia plegada (`<details>`) + sello |

Convenciones transversales observadas: títulos en `{bf:}`; `xtitle("")` siempre; `ytitle` con la unidad explícita ("% PIB", "MXN VP", "Tasa efectiva (%)"); `yscale(range(0))` en niveles y tasas; `caption` "{bf:Fuente}: Elaborado por el CIEP, con información de …"; el **año de política se separa visualmente** del observado (tramo propio o `xline` discontinua), la **proyección se atenúa** (`fintensity 40–50`) y lo preliminar/nowcast se etiqueta por tipo; la oración-resumen ("De a a b, X aumentó y pp") vive en `b1title`/`text()`, es decir, el dato se cuenta en una frase además de dibujarse.

### 2.6 Cómo presentan las tablas los comandos (`presentacion`)

| Comando | Columnas (orden) | Totales y reglas | Formato |
|---|---|---|---|
| `LIF` §4.2 / `PEF` §5.1 | Concepto · `MXN` · `% PIB` · `% Tot` · `MXN PC` | `(+)` renglones, `(−)` ajustes, `(=)` total en negritas; regla de 78 guiones | `%18.0fc` / `%7.3fc` / `%6.1fc` / `%8.0fc` |
| `GastoPC` §3.10 | Concepto · denominador (alumnos/asegurados) · `% PIB` · `PC (MXN VP)` | subtotales por bloque entre reglas de 71 guiones; total general al final | `%15.0fc` / `%7.3f` / `%15.0fc` |
| `TasasEfectivasMicro` §3.4 | Base/impuesto · `Base (mmdp)` · `Rec (mmdp)` · `TE (%)` | totales laboral y consumo en negritas tras la regla | `%10.0fc` / `%8.3fc` |
| Incidencia (`EntidadNL.do` §4) | Decil · AlTrabajo · AlCapital · AlConsumo · OTROSK · Total | `Tot` al final; nota de suma | `%10.1fc` |
| `scalarjson` (`tabla[]`) | la **estructura** viaja en el contrato: `bloque`, `etiqueta`, `prefijo` (`(+)/(−)/(=)`), `familia`, `enfasis`; la página la espeja (`nodo-deuda.html` renderTabla) | `rule-max` entre bloques, `rule-min` antes del énfasis | `formato_sugerido`/`divisor_sugerido` por escalar; catálogo `escalar.ado`: `pctpib %7.3fc`, `pct %7.1fc`, `mxn %12.1fc ÷1e6`, `mxnpc %10.0fc`, `personas %15.0fc`, `anio %4.0f` |

## 3. Tokens fijos de la capa NL — FIJADOS en NL-0.4.1 con la identidad CoNL (§6; resoluciones 2026-10-04). La tabla de abajo es la propuesta histórica derivada de `scheme-ciep`; los valores vigentes son los de §6.3 y viven en `NLEstilo` (`nl-datos.js`).

**Dónde viven:** `nl-assets/nl-datos.js`, bloque `NLEstilo` (único lugar). `federacion-nl.html` ya consume `var(--nl)`, `var(--nac)`, `var(--banda)`, `var(--recibe)`, `var(--paga)`, `var(--paquete)`, `var(--proy)`, `var(--acento)`; cambiar los valores ahí aplica la decisión a todos los endpoints que llamen `NLEstilo.apply()` (retrofit de `poblacion-nl`/`actividad-nl` en NL-0.4.1). Los valores actuales son los de esta tabla, marcados **provisionales** en el pie de cada endpoint.

Derivados de la paleta `scheme-ciep` para que un lector del libro/portada reconozca la familia. Hoy `poblacion-nl.html` y `actividad-nl.html` usan tokens propios (`--nl #0b4f6c`, `--nac #c9553d`, `--h #2a6f97`, `--m #c9553d`, `--now #e8a33d`, `--proy #9aa5b1`): **se migran** a estos en NL-0.4.x.

| Token | Significado | Color (scheme-ciep) | Uso |
|---|---|---|---|
| `--nl` | Nuevo León (sujeto) | azul CIEP profundo `rgb(0,78,198)` = p11 | líneas/barras de NL, línea S0 |
| `--nac` | nacional / referencia | gris claro `rgb(175,174,180)` = p23 (línea o barra atenuada) | comparativos; la referencia nunca compite en saturación con el sujeto |
| `--banda` | banda S1–S3 | `--nl` al 25 % de opacidad (eco de `linkalpha 30` / `fintensity 40`) | área sombreada; borde punteado en S1 y S3 |
| `--recibe` | flujo Federación → NL | verde jade `rgb(0,179,147)` = p10 | barras/áreas del lado "recibe"; enlaces Sankey de vuelta |
| `--paga` | flujo NL → Federación | rojo institucional `rgb(186,34,64)` = p6 | lado "paga"; enlaces Sankey de ida |
| `--balanza` | saldo neto | `--nl` (positivo) / `--paga` (negativo) | tarjeta y serie de la balanza |
| `--paquete` | año de política (PEF/PPEF/ILIF) | amarillo institucional `rgb(255,189,0)` = p2 | tramo "Paquete", como el motor |
| `--proy` / `--parcial` | proyección / año en curso parcial | naranja CIEP `rgb(255,128,0)` = p1 al 50 % | tramo atenuado, como `fintensity(50)` |
| `--acento` | énfasis de interfaz (toggle activo, foco) | naranja CIEP web `#d76f33` (portada) | botones, selector de registro |
| `--h` / `--m` | hombres / mujeres (población) | p4 celeste `rgb(23,151,201)` / p9 vino `rgb(150,6,92)` | pirámides (hoy azul/rojo-ladrillo; se alinea) |
| `--ink` / `--mut` / `--line` / `--bg` | texto, texto secundario, reglas, fondo | `#1F1F1F` (ciep-black) / `rgb(111,111,111)` (gris de ejes del scheme) / `rgb(200,200,200)` (grid del scheme) / `#f3f3e9` (ciep-beige) o blanco | tipografía y reglas, iguales al scheme |

Reglas de uso: (a) el sujeto (NL) siempre saturado, la referencia (nacional) siempre atenuada; (b) la banda nunca lleva color propio distinto del sujeto; (c) "recibe/paga" solo en el endpoint de la Federación y en cualquier Sankey futuro; (d) el año de política y la proyección se marcan con los mismos tramos y sombreados que el motor (`p2` y `p1` atenuado), nunca con un color nuevo; (e) máximo 6 series por gráfica, como los paneles de `Graphs_TE/PC`.

## 4. Vistas por pregunta (plantilla narrativa obligatoria)

Cada vista se documenta así, en `DIAGNOSTICO_NL.md` y en la plantilla HTML:

> **Pregunta** que contesta → **Patrón del canon** (§2.x, archivo:líneas) → **Por qué ese y no otro** → **Registro** (pc/macro) → **Tokens** (§3) → **Anotaciones** (líneas de referencia, tramos, oración-resumen).

## 6. Identidad CoNL (F0 de identidad visual, 2026-10-04 — PROPUESTA, frena hasta aprobación)

**Decisión de canon (Ricardo):** la identidad visual de los endpoints es 100 % Consejo Nuevo León (paleta, tipografía, logo); la **estructura** de este documento (patrones, gramática, doble registro, semántica) no cambia, cambia la fuente de los valores. Intocables de atribución: la leyenda que ya imprime `_NLidentidad` ("construido sobre el Simulador Fiscal CIEP v<motor>", tal cual) y la versión/enlace de GitHub de la capa.

### 6.1 Fuentes consultadas, por autoridad

| # | Fuente | Qué se encontró | Estado |
|---|---|---|---|
| 1 | **Drive de CoNL** — `Shared drives/REPOSITORIO GENERAL CONL/6.Comunicación/Manual de identidad/LOGOS CONL/` | **Existe el manual oficial**: `2023_CNL_BrandBook (1).pdf` (Drive id `1T3EhKASNhDbR3KNRpJf1FmWOpznQBJ5q`) y el paquete de logos en PDF/PNG/JPG con la nomenclatura oficial: *Logotipo* (texto morado / texto negro, con y sin *Descriptor*), *Sello*, *Siglas*, *Wordmark*, *Descriptor*; `logos/logo-rgb.eps`, `logo cmyk (para imprimir).eps`. | **No legibles desde esta máquina**: todos los binarios de esa unidad compartida son stubs `.gdrive` de 158 bytes (Drive for Desktop no los transmite: permiso de solo visualización o unidad sin disponibilidad local) y la descarga por URL exige sesión de Google. **Se pide a Ricardo**: descargar `2023_CNL_BrandBook (1).pdf` y `Logotipo (Texto Morado)/Con Descriptor` (PDF o EPS) a una carpeta local para F1 (vector → SVG y zona de respeto oficial). |
| 2 | **conl.mx** (tema WordPress `conl` de Brainwave, `style.css` v1.0.0; leído el 2026-10-04) | Tokens CSS oficiales `--cn-*` con variantes WCAG declaradas por el propio sitio (ver 6.2); tipografía autoalojada **Poppins** (títulos) e **Inter 24pt** (cuerpo) en `/wp-content/themes/conl/webfonts/*.woff2`; logos `images/logo_blanco.png` (263×112, blanco sobre morado) y `uploads/2025/10/conl.png` (250×100, texto morado); favicon = símbolo (aqua + amarillo). Encabezado del sitio: fondo morado con logo blanco; botón primario `.btn-morado` = fondo morado + borde inferior aqua. | **Fuente efectiva de los valores** mientras el manual no sea legible. |
| 3 | **Publicaciones oficiales** — `My Drive/PE_2040_Versión Completa.pdf` (Plan Estratégico 2040, 492 pp.) y `CONL_Indicadores CVNL 2026.pdf` | Fuentes embebidas del PE 2040: **Poppins** (Bold, SemiBold, Medium, Regular, ExtraBold, BoldItalic) e **Inter** (Regular, Light, SemiBold, Bold, ExtraBold). Colores de los flujos de contenido (130 páginas muestreadas): gris texto `#4a4a49` (397 usos), aqua `#00b0b0` (213), morado `#592147` (160), púrpura `#872675` (130), rojo `#e03859` (108), naranja `#e86b24` (104), amarillo `#fcb817` (95), celeste `#a3dbe8` (85), azul `#0a6eb5` (48), verde `#179447` (21), rosa `#f27894` (16). **Coinciden con los tokens web ±1 en cada canal**: la paleta web es la paleta editorial. El PDF de indicadores usa colores de Google Sheets (no es referencia de marca). |
| 4 | Redes (verificación cruzada) | Favicon y símbolo del logo: aqua `#08b0b0` / amarillo `#ffb811`; `sameAs`: x.com/ConsejoNL, instagram.com/consejonl, facebook.com/ConsejoNL, youtube.com/c/consejonuevoleon. Las redes exigen sesión; no se muestreó su contenido. | Consistente con 2 y 3. |

### 6.2 Paleta CoNL (hex exactos de `conl.mx/style.css :root`; rol observado; evidencia)

| Rol | Token CoNL | Hex | Variante WCAG (del sitio) | Evidencia |
|---|---|---|---|---|
| **Primario** | `--cn-morado` | `#5a2148` | — (12.0:1 sobre blanco) | fondo del encabezado y de los `card_title`, botones, paginación, texto `.text-morado`; logo "Texto Morado"; PE 2040 `#592147` |
| Primario 2 | `--cn-purpura` / `--cn-morado3` | `#872675` | — (8.2:1) | `.bg-purpura`, categoría "seguridad y justicia", círculos; PE 2040 (130 usos) |
| Primario atenuado | `--cn-morado2` | `#6d5866` | — | `.bg-morado-light`, bordes |
| Secundario 1 | `--cn-aqua` | `#00b1af` | `--cn-aqua-wcag #008381` | símbolo del logo, borde inferior de botones, favicon; PE 2040 (213 usos) |
| Secundario 2 | `--cn-amarillo` | `#fbb818` | `--cn-amarillo-wcag #9B6E05` | símbolo del logo, `.btn-amarillo` (texto morado); PE 2040 |
| Acento | `--cn-naranja` | `#e76b24` | `--cn-naranja-wcag #C75108` | temático; PE 2040 (104) |
| Acento | `--cn-rojo` | `#e13758` | `--cn-rojo-wcag #D52B4D` | temático; PE 2040 (108) |
| Acento | `--cn-azul` | `#0a6db6` | — (5.4:1) | temático; PE 2040 |
| Acento | `--cn-celeste` | `#a2dce9` | `--cn-celeste-wcag #2F807E` | temático |
| Acento | `--cn-verde` | `#189347` | `--cn-verde-wcag #10873D` | temático |
| Acento | `--cn-rosa` | `#f27794` | `--cn-rosa-wcag #B55A6F` | temático |
| Neutros | `--cn-negro20` / `--cn-negro10` / `--cn-gris20` | `#212121` / `#2f303b` / `#666666` | — | texto; PE 2040 gris texto `#4a4a49`, grises de apoyo `#7f7f7f`, `#9d9d9c`, `#d0d0d0`, fondo `#f6f6f6` |
| Claros | `*-light` | amarillo `#fef1d1`, aqua `#ccefef`, azul `#d0e2f0`, celeste `#ecf8fb`, púrpura `#e7d4e3`, naranja `#fae1d3`, rojo `#f9d7de`, rosa `#fce4ea`, verde `#d1e9da` | — | fondos de tarjetas temáticas |

### 6.3 Mapeo semántico propuesto a los tokens de `NLEstilo` (misma historia, distinta ropa)

| Token | Semántica (no cambia) | Valor CoNL propuesto | Contraste sobre blanco (`#f6f6f6`) | Nota |
|---|---|---|---|---|
| `--nl` | Nuevo León, sujeto; línea S0; cabecera | **morado `#5a2148`** → `#5A2248` desde NL-0.5.1 (§6.6c) | 12.0 (11.1) — AA texto ✓ | el primario de la marca es el protagonista |
| `--nac` | nacional, referencia atenuada | **gris `#7f7f7f`** (PDF) | 4.0 (3.7) — AA gráfico ✓ | `#9d9d9c` falla 3:1 como gráfico; `#666666` queda para texto secundario |
| `--banda` | banda [S1, S3] | morado al 25 % `rgba(90,33,72,.25)` | — | nunca color propio |
| `--recibe` | Federación → NL | **aqua `#00b1af`** (texto: `#008381`) | 2.7 relleno / 4.6 texto-wcag ✓ | color del símbolo del logo; en etiquetas sobre blanco se usa la variante WCAG |
| `--paga` | NL → Federación | **naranja `#e76b24`** (texto: `#C75108`) — alternativa rojo `#e13758` (`#D52B4D`) | 3.2 / 4.6 ✓ | ver daltonismo abajo: naranja domina al rojo frente al aqua |
| `--paquete` | año de política (PEF/PPEF/ILIF) | **amarillo `#fbb818`** → `#FCB817` desde NL-0.5.1 (§6.6c) | 1.75 — solo relleno, nunca texto | misma semántica que el `p2` amarillo del motor |
| `--proy` / parcial | proyección / año en curso | **morado al 45 %** `rgba(90,33,72,.45)` | — | eco fiel del `fintensity(40-50)` del motor (mismo color, atenuado) en lugar de un matiz distinto; libera el naranja para `--paga` |
| `--acento` | interfaz (toggle activo, foco, letrero de alcance) | **púrpura `#872675`** con borde inferior aqua (patrón `.btn-morado`) | 8.2 ✓ (blanco sobre él 8.2) | el aqua solo no soporta texto blanco (2.7) |
| `--h` / `--m` | hombres / mujeres (Población) | **azul `#0a6db6` / rosa `#f27794`** — alternativa M = púrpura `#872675` | 5.4 / 2.7 (relleno) | ver daltonismo; rosa es más distinguible, púrpura más neutro; **decide Ricardo** |
| `--ink` / `--mut` / `--line` / `--bg` / `--card` | texto / secundario / reglas / fondo / tarjeta | `#212121` / `#666666` / `#d0d0d0` / `#f6f6f6` / `#ffffff` | 16.1 / 5.7 ✓ | neutros del sitio y del PE 2040 |
| escalonado de fondos / impuestos | familias dentro de recibe/paga | aclarados del token (como hoy) | — | sin colores nuevos |

**Daltonismo (simulación Machado 2009, ΔE CIE76 normal / protan / deutan / tritan; > 20 = distinguible):** aqua vs **naranja** 107 / 60 / 75 / 113 ✓✓; aqua vs rojo 109 / 29 / 44 / 127 ✓ (protan justo); verde vs rojo 115 / 35 / **5** / 121 ✗ (descartado); morado vs gris `#7f7f7f` 54 / 48 / 41 / 51 ✓; amarillo (Paquete) vs morado 45 % — distintos por luminosidad ✓; azul vs rosa 74 / 41 / 67 / 90 ✓; azul vs púrpura 53 / **21** / 31 / 73 (protan justo). Contrastes: texto blanco sobre morado 12.0 ✓, sobre púrpura 8.2 ✓, sobre aqua 2.7 ✗ (por eso el acento es púrpura, no aqua).

### 6.4 Tipografía

- **Oficial** (sitio y PE 2040): **Poppins** para títulos (h1 = Poppins SemiBold 600 en el sitio; Bold/ExtraBold en portadas del PE) e **Inter** para cuerpo (Inter 24pt Regular 400; Medium/SemiBold/Bold para énfasis). Ambas bajo **SIL Open Font License 1.1** (declarado en la tabla `name` de los archivos del sitio: Poppins 4.004, Inter 4.001) → **embebibles**. Los archivos están en el servidor de CoNL (`conl.mx/wp-content/themes/conl/webfonts/`), no en el Drive legible; descargados y verificados hoy (Poppins 50 KB c/u, Inter 116–119 KB c/u).
- **Plan cero-red (propuesto):** subset WOFF2 embebido como `data:` URI en `nl-datos.js` (bloque `NLEstilo.fuentes`), rango Latin + Latin Ext-A + puntuación tipográfica + `− → ≤ ≥ € · ×`, con `kern, liga, tnum, pnum, lnum` (números tabulares para tarjetas y tablas), sin hinting. Costo medido con fontTools: **Poppins SemiBold 9.5 KB → 12.6 KB base64; Inter Regular 16.3 → 21.8; Inter SemiBold 16.8 → 22.4; Inter Medium 16.7 → 22.3**. Tres pesos (títulos + cuerpo + negritas) = **≈ 57 KB**; cuatro (con Medium) ≈ 77 KB por endpoint. `font-display: swap` con pila de respaldo `-apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif`. Propuesta: **3 pesos**.
- Jerarquía: h1/h2 y titulares de tarjeta en Poppins SemiBold; cuerpo, tablas, pie y extractos en Inter Regular; énfasis/totales en Inter SemiBold; números con `font-variant-numeric: tabular-nums` (Inter `tnum`).

### 6.5 Logo

- Variantes disponibles hoy: `conl.png` (logotipo horizontal con descriptor, texto morado, 250×100, 10.5 KB → 14 KB base64) y `logo_blanco.png` (263×112, 5.9 KB → 8 KB base64), ambos del sitio oficial; favicon 32×32 = símbolo. En el Drive existen las versiones vectoriales (PDF/EPS) y el BrandBook con la zona de respeto oficial: **pendientes de que Ricardo las baje**.
- Propuesta: encabezado morado con **`logo_blanco`** (como conl.mx) a 44–48 px de alto, a la izquierda del título; pie con **`conl.png`** (texto morado) a 36 px. Zona de respeto **provisional** = la mitad de la altura del símbolo alrededor (se sustituye por la del BrandBook). Al tener el vector: SVG data-URI (menor y nítido); hasta entonces PNG @2x (los tamaños de uso son ≤ 125×50 CSS px, así que 250×100 rinde a 2×).

### 6.6 Bloque de atribución (maqueta del pie, intocable)

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ [logo CoNL texto morado, 36 px]  Simulador Fiscal NL — <módulo>                           │
│ construido sobre el Simulador Fiscal CIEP v8.6.0  ·  capa NL-0.4.1  ·  GitHub ↗           │
│ (enlace: https://github.com/rcantuc/SimuladorCIEP/tree/feature/entidad-nl — es un <a>, no │
│  una carga: cero red se mantiene)                                                        │
│ corrida <sello> · log <archivo> · <driver>                                                │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```
La leyenda se toma **tal cual** de `_NLidentidad` (`r(subtitulo)` → `procedencia`/`subtitulo` del JSON), nunca se reescribe; la versión de la capa y el enlace salen de `nl-manifest.json` (`version_nl` + clave nueva `repositorio` que F1 añade al manifest), no de la plantilla. Mismo bloque en los tres endpoints (cabecera: logo blanco + título; pie: logo morado + atribución).

### 6.6b Lo que dice el BrandBook 2020 (leído el 2026-10-04 desde `Shared drives/Revisión Plan Estratégico 2019-2021/Materiales para diseño/Identidad Consejo Nuevo León/BrandBook_Consejo_NL .pdf`, Algoritmo Design, nov-2020, 16 pp.) — el manual manda sobre lo inferido del sitio

| Regla del manual | Cómo se aplica en NL-0.4.1 |
|---|---|
| **§4 Espacio blanco**: "la mínima cantidad de espacio blanco es equivalente a la mitad del tamaño del logotipo" (área de protección = una unidad del símbolo; extrema = dos) | logo de cabecera a 44 px con relleno de 22 px; logo del pie a 36 px con 18 px; nada dentro de esa franja (sustituye la zona provisional de F0) |
| **§5 Aplicación cromática**: "puede ser utilizado en blanco siempre y cuando no afecte su legibilidad" (muestra: blanco sobre morado) | cabecera morada con logotipo blanco (como conl.mx); pie claro con logotipo en color |
| **§6 Usos incorrectos**: no rotar, no colores fuera de la paleta, no efectos, no distorsionar | el SVG se escala proporcionalmente (`height` fijo, `width:auto`), sin filtros ni recoloreos; el blanco es la variante del propio manual |
| **§8 Paleta primaria**: amarillo Pantone 130 C (RGB 253,185,19), aqua Pantone 326 C (RGB 0,177,176), morado Pantone 518 C (RGB 90,33,73); los hex impresos (#F5BC43 / #4FADAF / #4D1B45) son conversiones CMYK desaturadas y **no coinciden con su propio RGB** | se usan los RGB del manual, que coinciden ±2 por canal con los tokens oficiales del sitio (`--cn-morado #5a2148`, `--cn-aqua #00b1af`, `--cn-amarillo #fbb818`) y con el PE 2040; se toman los hex del sitio como forma canónica |
| **§9 Paleta secundaria**: verde #00B259, púrpura #872175, naranja #F47D30, azul #2C70B9, celeste #3ECADD, rojo #E03657; **§11–12 comisiones**: Finanzas Públicas = naranja (#E78245 / #E86A23) | púrpura y rojo coinciden con el sitio; el naranja del sitio (#e76b24) es el de la comisión de Finanzas Públicas del propio manual → `--paga` naranja queda además alineado temáticamente; azul del sitio (#0a6db6) difiere del manual (#2C70B9): se usa el del sitio (vigente) |
| **§7 Tipografías**: primaria **Basis Grotesque Pro Light** (titulares), secundaria **Public Sans Light** (párrafos) | **discrepancia declarada**: el sitio (2025) y el PE 2040 (2024) usan Poppins + Inter; Basis Grotesque es comercial (Colophon) y no puede embeberse; se aplica Poppins/Inter (OFL) como identidad vigente y se deja la confirmación al BrandBook 2023 (no legible) |
| Logotipo vectorial | tomado de `consejonl_logotipo.ai` (misma carpeta): contornos (sin texto vivo), separaciones Pantone 518/326/130 C mapeadas al RGB de marca; convertido a SVG (47 trazos, 17 KB) con la variante blanca derivada |

### 6.6c Lo que dice el Manual de Identidad 2023 (leído el 2026-10-06 desde `My Drive/2023_CNL_BrandBook (1)-1-1.pdf`, Brandital, versión 3.0, 15 láminas) y la guía de co-branding (`My Drive/20250122_Co-branding_Brandbook_ConsejoNL-2.pdf`, Brandital, 22-ene-2025, 37 láminas) — vigente desde NL-0.5.1; el manual 2023 manda sobre el 2020 y sobre lo inferido del sitio

| Regla del manual | Qué corrige | Cómo se aplica en NL-0.5.1 |
|---|---|---|
| **§5 Paleta de color** (hex, CMYK y RGB impresos): morado `#5A2248` (90,34,72), turquesa `#00B1AF` (0,177,175), amarillo `#FCB817` (252,184,23); secundarios `#872675`, `#0A6DB6`, `#A2DCE9`, `#E76B24`, `#189347`, `#E13758`, `#F27794`. La guía de co-branding los nombra **Morado Colorín**, **Turquesa Santa Lucía** y **Amarillo Cielo Soleado** y da los tintes 80/60/40/20 %. | Los tokens del sitio eran ±1 por canal (`#5a2148`, `#fbb818`); el aqua ya coincidía. Los secundarios del sitio coinciden todos (el azul `#0a6db6` es el del manual 2023: la discrepancia con el 2020 queda resuelta a favor del sitio). | `--nl rgb(90,34,72)`, `--banda/--proy/--nowcast` sobre ese mismo RGB, `--paquete rgb(252,184,23)`; el resto igual. `:root` de respaldo de las tres plantillas alineado. Contrastes medidos: sin cambio material (morado 12.0:1 sobre blanco). |
| **§1 Imagotipo**: isotipo + logotipo + **eslogan** ("Para la planeación estratégica"); "la versión completa con el eslogan debe utilizarse **siempre** en documentos oficiales y/o publicaciones". No modificar, distorsionar ni redibujar. | El SVG de NL-0.4.1 venía del `.ai` de 2020 (wordmark en caja baja, otra letra): **no era el imagotipo vigente**. El sitio sí usa el de 2023 (`conl.png`, `logo_blanco.png`), ambos **con** el eslogan. Lo que el 2020 llamaba *descriptor* es el *eslogan* del 2023: misma línea, mismo papel. | **Decisión descriptor-vs-eslogan: versión completa con eslogan en los dos lugares** (cabecera y atribución), porque los endpoints son publicaciones oficiales y el sitio hace lo mismo en su cabecera (125 px de ancho). Vector extraído del propio manual (lámina 2, 47 trazos, 12.9 KB) con los rellenos llevados a los hex de §5; variante blanca derivada (co-branding: la versión color/blanco/negro depende del fondo). |
| **§2 Área de protección**: la unidad es el isotipo (X = grosor del isotipo, también en la guía de co-branding); extrema = 2X. | La zona de NL-0.4.1 era "½ del alto del logotipo" (manual 2020). | X = 0.535 × alto del imagotipo (medido en el vector). Cabecera: imagotipo 50 px, padding y gap ≥ 27 px. Atribución: 72 px, padding 39 px. |
| **Legibilidad del tamaño mínimo** (§8: "tomando en cuenta la legibilidad para su tamaño mínimo"). | A 36 px el eslogan medía 3.4 px. | El eslogan mide 9.4 % del alto: a 72 px son 6.8 px (legible); a 50 px, 4.7 px (como el sitio). |
| **Co-branding 2025, socio principal, versión 2 (marcas externas tecleadas)**: logotipo a color a la izquierda, **separado por una línea negra de hasta 2 px**, ½X a cada lado de la línea, las marcas externas **tecleadas en Inter Regular**. (§8 del manual 2023, *Arquitectura de marcas*, usa una línea gris para los logotipos alternos propios; aquí la marca externa es el CIEP, por eso rige la guía de co-branding.) | El bloque de atribución de NL-0.4.1 no tenía separador y llevaba el nombre del producto en negritas. | `NLEstilo.atribucion`: imagotipo a color (72 px) · ½X · línea de 1 px `#000` del alto del logo · ½X · texto en Inter Regular 400 (sin negritas; `code` y el enlace también en 400). El **contenido** sigue intocable: producto — módulo · leyenda de `_NLidentidad` tal cual · capa · motor · GitHub · corrida · log · driver. |
| **§4 Familias tipográficas**: "únicamente Poppins e Inter"; Poppins para titulares, Inter para cuerpos de texto, textos pequeños y legales. | Confirma la elección de NL-0.4.1 y cierra la discrepancia con el manual 2020 (Basis Grotesque/Public Sans). | Sin cambio. |
| **§6–§7 Iconografía de comisiones y textura**; **§9 versiones alternas** (wordmark "CONL", sello circular con "Estrategias que definen el futuro"). | — | No se usan: la capa solo emplea el imagotipo. |

### 6.7 Qué queda como aproximación

Nada de identidad: con el manual 2023 legible, tipografía, paleta (primaria y secundaria), imagotipo, área de protección y separador de co-branding salen del manual. Resuelto antes con el manual 2020 y confirmado o corregido en 6.6c: zona de respeto (ahora X del isotipo), uso en blanco, usos incorrectos, logotipo vectorial (ahora el de 2023), RGB de la paleta primaria (ahora hex exactos).

**F0 cerrado (resoluciones 2026-10-04):** mapeo §6.3 aprobado con `--paga` naranja y `--m` rosa (el púrpura colisiona con la familia del morado protagonista; el rojo queda para alertas); 3 pesos embebidos; atribución §6.6 tal cual; legibilidad del pie medida en la verificación desde el Drive (NL-0.4.1). Texto original de la petición: se piden a Ricardo (1) aprobación del mapeo 6.3 (en particular `--paga` naranja vs rojo y `--m` rosa vs púrpura), (2) del plan tipográfico 6.4 (3 pesos embebidos, ≈ 57 KB por endpoint), (3) del bloque de atribución 6.6, y (4) la descarga local del BrandBook y del logotipo vectorial del Drive (o confirmar que se sigue con PNG).

## 5. Pendientes abiertos de este borrador

- Confirmar tokens §3 (en particular NL = azul CIEP profundo vs. naranja CIEP; nacional gris vs. color).
- Decidir si la oración-resumen del motor (`b1title` "De a a b…") se replica en los endpoints como línea bajo cada gráfica (propuesta: sí, generada desde el JSON, nunca escrita a mano).
- Retrofit NL-0.4.1 de `poblacion-nl`/`actividad-nl` a estos tokens y al doble registro (vista principal nueva: PIBE per cápita NL vs. nacional).
