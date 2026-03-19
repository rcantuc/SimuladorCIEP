{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "SHRFSP##description"}{...}
{viewerjumpto "Primeros pasos" "SHRFSP##quickstart"}{...}
{viewerjumpto "Sintaxis" "SHRFSP##syntax"}{...}
{viewerjumpto "Opciones" "SHRFSP##options"}{...}
{viewerjumpto "Ejemplos" "SHRFSP##examples"}{...}
{viewerjumpto "Resultados" "SHRFSP##output"}{...}
{viewerjumpto "Variables y scalars" "SHRFSP##variables"}{...}
{viewerjumpto "Interpretación" "SHRFSP##interpretation"}{...}
{viewerjumpto "Referencias" "SHRFSP##references"}{...}

{title:SHRFSP — Saldo Histórico de los Requerimientos Financieros del Sector Público}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:SHRFSP} descarga y analiza la {bf:deuda pública de México} en su medida más amplia,
combinando dos fuentes oficiales:
{p_end}

{phang2}1. {bf:Estadísticas Oportunas SHCP} — Saldos de deuda, requerimientos financieros,
balance fiscal y costo de la deuda{p_end}
{phang2}2. {bf:BIE (INEGI)} — PIB y deflactor para expresar valores como % del PIB y en términos reales{p_end}

{pstd}
{bf:¿Qué es el SHRFSP?} El Saldo Histórico de los Requerimientos Financieros del Sector
Público es la medida más amplia de deuda pública en México. A diferencia de la deuda
tradicional, incluye pasivos fuera del presupuesto:
{p_end}

{phang2}— {bf:SHRFSP} (Saldo): Stock de deuda acumulada al final del período{p_end}
{phang2}— {bf:RFSP} (Requerimientos): Flujo anual de endeudamiento neto{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite analizar la sostenibilidad de las finanzas públicas,
comparar la deuda como % del PIB y per cápita, y descomponer los requerimientos
financieros en sus componentes (balance presupuestario, PIDIREGAS, IPAB, etc.).
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para obtener el análisis de deuda del año en curso:
{p_end}

{phang2}{cmd:. SHRFSP}{p_end}

{pstd}
Para un año específico con histórico desde 2010:
{p_end}

{phang2}{cmd:. SHRFSP, anio(2025) ultanio(2010)}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:SHRFSP} [{it:if}] [{cmd:,} {opt ANIO(#)} {opt ULTAnio(#)} {opt DEPreciacion(#)} {opt NOGraphs} {opt UPDATE} {opt Base} {opt TEXTbook}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt anio(#)} — {bf:Año de referencia} para el análisis. Rango: 1993–año actual.
Por defecto usa el año del paquete económico ({cmd:anioPE}).
{p_end}

{phang}
{opt ultanio(#)} — {bf:Año inicial} del período mostrado en las gráficas. Debe ser
anterior al año de referencia. Por defecto: 2001.
{p_end}

{phang}
{opt depreciacion(#)} — {bf:Tasa de depreciación cambiaria} (%) usada para ajustar
la deuda externa por efectos del tipo de cambio. Por defecto: 5%.
{p_end}

{phang}
{opt nographs} — Suprime la generación de gráficas.
{p_end}

{phang}
{opt update} — Descarga los datos más recientes de las Estadísticas Oportunas SHCP.
Requiere conexión a internet.
{p_end}

{phang}
{opt base} — Descarga únicamente la base de datos sin cálculos adicionales.
{p_end}

{phang}
{opt textbook} — Genera gráficas sin títulos ni fuentes, para publicaciones.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Análisis básico del año en curso}{p_end}
{phang2}{cmd:. SHRFSP}{p_end}

{pstd}{bf:Ejemplo 2 — Año específico}{p_end}
{phang2}{cmd:. SHRFSP, anio(2025)}{p_end}

{pstd}{bf:Ejemplo 3 — Histórico desde 2010}{p_end}
{phang2}{cmd:. SHRFSP, anio(2025) ultanio(2010)}{p_end}

{pstd}{bf:Ejemplo 4 — Con depreciación cambiaria personalizada}{p_end}
{phang2}{cmd:. SHRFSP, anio(2025) depreciacion(8)}{p_end}
{pstd}Ajusta la deuda externa asumiendo una depreciación del 8% anual.{p_end}

{pstd}{bf:Ejemplo 5 — Actualizar datos sin gráficas}{p_end}
{phang2}{cmd:. SHRFSP, update nographs}{p_end}

{pstd}{bf:Ejemplo 6 — Solo base de datos cruda}{p_end}
{phang2}{cmd:. SHRFSP, base}{p_end}

{pstd}{bf:Ejemplo 7 — Filtrar período específico}{p_end}
{phang2}{cmd:. SHRFSP if anio >= 2015 & anio <= 2025}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes una tabla en pantalla, siete gráficas y una base de datos:
{p_end}

{pstd}{bf:Tabla de resultados:} Resumen del SHRFSP y RFSP con montos absolutos,
% del PIB y valores per cápita.{p_end}

{pstd}{bf:Siete gráficas:}{p_end}
{phang2}1. {bf:SHRFSP como % del PIB} — Deuda total, interna y externa{p_end}
{phang2}2. {bf:SHRFSP per cápita} — Deuda por habitante en pesos reales{p_end}
{phang2}3. {bf:Deuda bruta por entidad deudora} — Gobierno Federal, organismos y empresas, banca{p_end}
{phang2}4. {bf:Deuda bruta por tipo} — Interna vs externa{p_end}
{phang2}5. {bf:Costo de la deuda} — Costo financiero y tasa efectiva de interés{p_end}
{phang2}6. {bf:Efectos sobre el indicador de deuda} — Factores que aumentan o reducen la deuda{p_end}
{phang2}7. {bf:RFSP} — Requerimientos financieros anuales por componente{p_end}

{pstd}{bf:Archivos guardados:}{p_end}
{phang2}— {cmd:04_master/SHRFSP.dta} — Base consolidada de deuda pública{p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{hline}

{marker variables}{...}
{title:Variables y scalars generados}

{pstd}{bf:Variables principales en la base de datos:}{p_end}

{phang2}{bf:anio} — Año{p_end}
{phang2}{bf:shrfsp} — SHRFSP total (millones de pesos){p_end}
{phang2}{bf:shrfsp_ext} — Deuda externa{p_end}
{phang2}{bf:shrfsp_int} — Deuda interna{p_end}
{phang2}{bf:rfsp} — Requerimientos financieros totales{p_end}
{phang2}{bf:rfspBalance} — Balance presupuestario{p_end}
{phang2}{bf:rfspPIDIREGAS} — Proyectos de infraestructura diferidos{p_end}
{phang2}{bf:rfspIPAB} — Instituto para la Protección al Ahorro Bancario{p_end}
{phang2}{bf:rfspFONADIN} — Fondo Nacional de Infraestructura{p_end}
{phang2}{bf:balprimario} — Balance primario{p_end}
{phang2}{bf:costodirecto} — Costo financiero directo de la deuda{p_end}
{phang2}{bf:tasaEfectiva} — Tasa de interés efectiva promedio{p_end}

{pstd}{bf:Scalars generados} (para cada componente {it:X}: {cmd:X}Monto, {cmd:X}PIB, {cmd:X}PC):
{p_end}

{phang2}{bf:shrfspMonto}, {bf:shrfspPIB}, {bf:shrfspPC} — SHRFSP total{p_end}
{phang2}{bf:shrfsp_extMonto}, {bf:shrfsp_extPIB} — Deuda externa{p_end}
{phang2}{bf:shrfsp_intMonto}, {bf:shrfsp_intPIB} — Deuda interna{p_end}
{phang2}{bf:rfspMonto}, {bf:rfspPIB} — Requerimientos financieros totales{p_end}
{phang2}{bf:tasaEfectiva} — Tasa efectiva de interés del año de referencia{p_end}

{hline}

{marker interpretation}{...}
{title:Interpretación de resultados}

{pstd}{bf:SHRFSP como % del PIB:}{p_end}
{phang2}— Menor a 30%: Nivel de deuda bajo (sostenible){p_end}
{phang2}— 30%–60%: Nivel moderado (requiere atención){p_end}
{phang2}— Mayor a 60%: Nivel alto (puede requerir ajustes fiscales){p_end}

{pstd}{bf:RFSP vs Balance presupuestario:}{p_end}
{phang2}— RFSP > Balance: Hay pasivos fuera del presupuesto (PIDIREGAS, IPAB, etc.){p_end}
{phang2}— RFSP = Balance: Solo hay déficit presupuestario tradicional{p_end}

{pstd}{bf:Nota metodológica:} La tasa efectiva de interés se calcula dividiendo
el costo financiero (intereses pagados) entre el saldo de la deuda del mismo año.
{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:SHCP — Estadísticas Oportunas de Finanzas Públicas:}
{browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
2. {bf:SHCP — Deuda Pública:}
{browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Deuda_Publica"}
{p_end}

{pstd}
3. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/LIF.sthlp":LIF} {c |}
{view "06_helps/PEF.sthlp":PEF} {c |}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "06_helps/TasasEfectivas.sthlp":TasasEfectivas} {c |}
{view "06_helps/DatosAbiertos.sthlp":DatosAbiertos}
{p_end}

{smcl_end}
