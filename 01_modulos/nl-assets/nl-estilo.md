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

## 3. Tokens fijos de la capa NL (propuesta; se fijan al aprobarse — resolución 2026-10-04: NO fijar hasta la pasada de Ricardo)

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

## 5. Pendientes abiertos de este borrador

- Confirmar tokens §3 (en particular NL = azul CIEP profundo vs. naranja CIEP; nacional gris vs. color).
- Decidir si la oración-resumen del motor (`b1title` "De a a b…") se replica en los endpoints como línea bajo cada gráfica (propuesta: sí, generada desde el JSON, nunca escrita a mano).
- Retrofit NL-0.4.1 de `poblacion-nl`/`actividad-nl` a estos tokens y al doble registro (vista principal nueva: PIBE per cápita NL vs. nacional).
