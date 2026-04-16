{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "PIBDeflactor##description"}{...}
{viewerjumpto "Primeros pasos" "PIBDeflactor##quickstart"}{...}
{viewerjumpto "Sintaxis" "PIBDeflactor##syntax"}{...}
{viewerjumpto "Opciones" "PIBDeflactor##options"}{...}
{viewerjumpto "Escenarios económicos" "PIBDeflactor##scenarios"}{...}
{viewerjumpto "Ejemplos" "PIBDeflactor##examples"}{...}
{viewerjumpto "Resultados" "PIBDeflactor##output"}{...}
{viewerjumpto "Variables y scalars" "PIBDeflactor##variables"}{...}
{viewerjumpto "Referencias" "PIBDeflactor##references"}{...}

{title:PIBDeflactor — PIB, deflactor e indicadores macroeconómicos}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:PIBDeflactor} descarga, procesa y proyecta los principales indicadores macroeconómicos
de México: {bf:PIB}, {bf:deflactor de precios}, {bf:inflación} y {bf:demografía laboral}.
Combina dos fuentes oficiales:
{p_end}

{phang2}1. {bf:BIE (INEGI)} — PIB trimestral, índice de precios implícitos, INPC y empleo{p_end}
{phang2}2. {bf:CONAPO} — Proyecciones de población 1950–2070{p_end}

{pstd}
{bf:¿Para qué sirve?} Es el comando base del Simulador Fiscal CIEP. Genera el deflactor
y el PIB que usan todos los demás comandos ({cmd:LIF}, {cmd:PEF}, {cmd:SHRFSP}, etc.)
para expresar valores en términos reales. También permite construir {bf:escenarios económicos}
alternativos modificando los globals de crecimiento en el {cmd:profile.do}.
{p_end}

{pstd}
Las series se presentan en tres tramos diferenciados:
{p_end}

{phang2}— {bf:Histórico} (naranja): datos observados desde 1993{p_end}
{phang2}— {bf:Estimaciones CGPE} (amarillo): proyecciones oficiales de la SHCP{p_end}
{phang2}— {bf:Proyecciones CIEP} (verde): proyecciones con metodología propia{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para obtener el PIB y deflactor con el año actual como base de valor presente:
{p_end}

{phang2}{cmd:. PIBDeflactor}{p_end}

{pstd}
Para especificar el año de valor presente y el horizonte de proyección:
{p_end}

{phang2}{cmd:. PIBDeflactor, aniovp(2026) aniomax(2031)}{p_end}

{pstd}
{bf:Nota:} El {cmd:profile.do} ya ejecuta este comando automáticamente al iniciar Stata
con los parámetros del paquete económico vigente.
{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:PIBDeflactor} [{it:if}] [{cmd:,} {opt ANIOvp(#)} {opt ANIOMAX(#)} {opt GEOPIB(#)} {opt GEODEF(#)} {opt DIScount(#)} {opt NOGraphs} {opt UPDATE} {opt NOOutput} {opt TEXTbook}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{dlgtab:Año de referencia}

{phang}
{opt aniovp(#)} — {bf:Año de valor presente.} Todos los valores reales se expresan
en pesos de este año. Rango: 1993–2050. Por defecto usa el año actual.
{p_end}

{phang}
{opt aniomax(#)} — {bf:Año final de proyección.} Hasta qué año se extienden las
gráficas y la base de datos. Por defecto: año actual + 15.
{p_end}

{dlgtab:Parámetros de proyección}

{phang}
{opt geopib(#)} — {bf:Año base para el promedio geométrico del PIB.} A partir de
este año se calcula el crecimiento promedio histórico que se usa para proyectar
el PIB en años sin datos exógenos. Por defecto: primer año disponible.
{p_end}

{phang}
{opt geodef(#)} — {bf:Año base para el promedio geométrico del deflactor.}
Análogo a {opt geopib} pero para el índice de precios implícitos.
{p_end}

{phang}
{opt discount(#)} — {bf:Tasa de descuento} (%) para calcular el valor presente
del PIB futuro. Por defecto: 5%.
{p_end}

{dlgtab:Escenarios económicos}

{pstd}
Puedes definir tasas de crecimiento exógenas año por año en el {cmd:profile.do}
usando globals con el formato {cmd:$pib}{it:año} y {cmd:$def}{it:año}:
{p_end}

{phang2}{cmd:global pib2026 = 2.262}   {it:// Crecimiento PIB real 2026 (%)}{p_end}
{phang2}{cmd:global def2026 = 4.8}     {it:// Crecimiento deflactor 2026 (%)}{p_end}
{phang2}{cmd:global inf2026 = 3.54}    {it:// Inflación 2026 (%)}{p_end}

{pstd}
Los años sin global usan el promedio geométrico histórico como proyección.
{p_end}

{dlgtab:Otras opciones}

{phang}
{opt nographs} — Suprime la generación de gráficas.
{p_end}

{phang}
{opt update} — Descarga los datos más recientes del BIE/INEGI y CONAPO.
Requiere conexión a internet.
{p_end}

{phang}
{opt nooutput} — Suprime la tabla de resultados en pantalla.
{p_end}

{phang}
{opt textbook} — Genera gráficas sin títulos ni fuentes, para publicaciones.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Uso básico}{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2026) aniomax(2031)}{p_end}
{pstd}Genera el deflactor y PIB con base 2026, proyectando hasta 2031.{p_end}

{pstd}{bf:Ejemplo 2 — Con tasa de descuento personalizada}{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2026) aniomax(2050) discount(4)}{p_end}

{pstd}{bf:Ejemplo 3 — Promedios geométricos desde 2010}{p_end}
{phang2}{cmd:. PIBDeflactor, geopib(2010) geodef(2010) aniomax(2031)}{p_end}
{pstd}Calcula el crecimiento promedio del PIB y deflactor desde 2010 para proyectar.{p_end}

{pstd}{bf:Ejemplo 4 — Actualizar datos sin gráficas}{p_end}
{phang2}{cmd:. PIBDeflactor, update nographs}{p_end}

{pstd}{bf:Ejemplo 5 — Solo para uso en otro comando (sin output)}{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2026) nographs nooutput}{p_end}
{pstd}Así lo llaman internamente {cmd:LIF}, {cmd:PEF} y {cmd:SHRFSP}.{p_end}

{pstd}{bf:Ejemplo 6 — Filtrar años específicos}{p_end}
{phang2}{cmd:. PIBDeflactor if anio >= 2020 & anio <= 2031, geopib(2015)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes:
{p_end}

{phang2}{bf:1. Tabla de resultados} — Resumen de crecimiento, inflación y PIB per cápita.{p_end}
{phang2}{bf:2. Cuatro gráficas} — Índice de precios, PIB real, PIB per cápita e inflación.{p_end}
{phang2}{bf:3. Base de datos en memoria} — Lista para análisis inmediato.{p_end}
{phang2}{bf:4. Scalars r()} — Para uso en otros comandos y scripts.{p_end}

{pstd}{bf:Archivos guardados:}{p_end}

{phang2}— {cmd:04_master/PIBDeflactor.dta} — Base consolidada con series macroeconómicas{p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{hline}

{marker variables}{...}
{title:Variables y scalars generados}

{pstd}{bf:Variables principales en la base de datos:}{p_end}

{phang2}{bf:anio} — Año{p_end}
{phang2}{bf:pibY} — PIB nominal (millones de pesos corrientes){p_end}
{phang2}{bf:pibYR} — PIB real (pesos del año base){p_end}
{phang2}{bf:indiceY} — Índice de precios implícitos del PIB{p_end}
{phang2}{bf:deflator} — Deflactor (indiceY / indiceY[aniovp]){p_end}
{phang2}{bf:deflatorpp} — Deflactor de poder adquisitivo (base INPC){p_end}
{phang2}{bf:inpc} — Índice Nacional de Precios al Consumidor{p_end}
{phang2}{bf:var_pibY} — Crecimiento anual del PIB real (%){p_end}
{phang2}{bf:var_pibG} — Promedio geométrico del crecimiento del PIB (%){p_end}
{phang2}{bf:var_indiceY} — Crecimiento anual del deflactor (%){p_end}
{phang2}{bf:var_inflY} — Inflación anual INPC (%){p_end}
{phang2}{bf:PIBPob} — PIB real per cápita{p_end}
{phang2}{bf:pibYVP} — PIB descontado a valor presente{p_end}
{phang2}{bf:Poblacion} — Población total (CONAPO){p_end}
{phang2}{bf:WorkingAge} — Población 15–65 años{p_end}
{phang2}{bf:lambda} — Factor de productividad{p_end}

{pstd}{bf:Scalars r() principales:}{p_end}

{phang2}{bf:r(pibY)} — PIB nominal del año base{p_end}
{phang2}{bf:r(pibYPC)} — PIB per cápita del año base{p_end}
{phang2}{bf:r(crecimientoProm)} — Crecimiento promedio del PIB (%){p_end}
{phang2}{bf:r(deflactorProm)} — Crecimiento promedio del deflactor (%){p_end}
{phang2}{bf:r(inflacionProm)} — Inflación promedio (%){p_end}
{phang2}{bf:r(aniovp)} — Año base utilizado{p_end}
{phang2}{bf:r(discount)} — Tasa de descuento utilizada{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:INEGI — Banco de Información Económica (BIE):}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:INEGI — Sistema de Cuentas Nacionales:}
{browse "https://www.inegi.org.mx/temas/pib/"}
{p_end}

{pstd}
3. {bf:CONAPO — Proyecciones de Población:}
{browse "https://www.gob.mx/conapo/documentos/bases-de-datos-de-la-conciliacion-demografica-1950-a-2019-y-proyecciones-de-la-poblacion-de-mexico-2020-a-2070"}
{p_end}

{pstd}
4. {bf:SHCP — Criterios Generales de Política Económica:}
{browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Paquete_Economico_y_Presupuesto"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/Poblacion.sthlp":Poblacion} {c |} 
{view "06_helps/SCN.sthlp":SCN} {c |} 
{view "06_helps/LIF.sthlp":LIF} {c |} 
{view "06_helps/PEF.sthlp":PEF} {c |} 
{view "06_helps/SHRFSP.sthlp":SHRFSP}
{p_end}

{smcl_end}
