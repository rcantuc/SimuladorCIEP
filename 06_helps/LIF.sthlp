{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "LIF##description"}{...}
{viewerjumpto "Primeros pasos" "LIF##quickstart"}{...}
{viewerjumpto "Sintaxis" "LIF##syntax"}{...}
{viewerjumpto "Opciones" "LIF##options"}{...}
{viewerjumpto "Ejemplos" "LIF##examples"}{...}
{viewerjumpto "Resultados" "LIF##output"}{...}
{viewerjumpto "Variables y scalars" "LIF##variables"}{...}
{viewerjumpto "Referencias" "LIF##references"}{...}

{title:LIF — Ley de Ingresos de la Federación}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:LIF} descarga y analiza los {bf:ingresos presupuestarios del gobierno federal},
combinando tres fuentes oficiales:
{p_end}

{phang2}1. {bf:LIF (Ley de Ingresos de la Federación)} — Montos aprobados por el Congreso{p_end}
{phang2}2. {bf:Estadísticas Oportunas SHCP} — Recaudación observada mensual{p_end}
{phang2}3. {bf:BIE (INEGI)} — PIB y deflactor para expresar valores como % del PIB{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite consultar la recaudación histórica desde 1993, comparar
su evolución entre años, analizar la {bf:elasticidad} de cada impuesto respecto al PIB,
y proyectar el cierre del año en curso cuando los datos son incompletos.
{p_end}

{pstd}
{bf:Dato importante:} Si el año solicitado está incompleto (año en curso), el comando
puede {bf:proyectar} el cierre anual usando la tendencia histórica mensual
(opción {opt proyeccion}) o mostrar los datos tal como están (opción {opt eofp}).
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para analizar los ingresos del año en curso:
{p_end}

{phang2}{cmd:. LIF}{p_end}

{pstd}
Para un año específico:
{p_end}

{phang2}{cmd:. LIF, anio(2025)}{p_end}

{pstd}
Para proyectar el cierre del año en curso:
{p_end}

{phang2}{cmd:. LIF, proyeccion}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:LIF} [{it:if}] [{cmd:,} {opt ANIO(#)} {opt DESDE(#)} {opt EOFP} {opt PROYeccion} {opt BY(varname)} {opt NOGraphs} {opt UPDATE} {opt Base} {opt MINimum(#)} {opt ROWS(#)} {opt COLS(#)} {opt TITle(string)}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{dlgtab:Análisis}

{phang}
{opt anio(#)} — {bf:Año de análisis.} Rango: 1993–año actual.
Por defecto usa el año del paquete económico ({cmd:anioPE}).
{p_end}

{phang}
{opt desde(#)} — {bf:Año de comparación.} Punto de inicio para calcular tasas de
crecimiento y elasticidades. Por defecto: 10 años antes del año de análisis.
{p_end}

{phang}
{opt eofp} — Muestra los datos {bf:tal como están} en las Estadísticas Oportunas,
sin proyectar meses faltantes. Útil para análisis con datos observados únicamente.
{p_end}

{phang}
{opt proyeccion} — {bf:Proyecta el cierre anual} de los meses faltantes usando
la proporción histórica mensual de cada rubro. Útil para estimar el año en curso.
{p_end}

{phang}
{opt by(varname)} — Agrupa los ingresos por la variable especificada. Por defecto
usa la clasificación CIEP ({cmd:divLIF}). Otras opciones: {cmd:concepto}, {cmd:ramo}.
{p_end}

{phang}
{opt nographs} — Suprime la generación de gráficas.
{p_end}

{phang}
{opt update} — Descarga los datos más recientes de las Estadísticas Oportunas SHCP
y del BIE/INEGI. Requiere conexión a internet.
{p_end}

{phang}
{opt base} — Descarga únicamente la base de datos sin cálculos adicionales.
Útil para análisis personalizados desde cero.
{p_end}

{dlgtab:Personalización de gráfica}

{phang}
{opt minimum(#)} — Porcentaje mínimo del PIB que un rubro debe alcanzar para
mostrarse individualmente en la gráfica. Los rubros menores se agrupan en "Otros".
Por defecto: 0.25. Aumenta este valor para simplificar la gráfica.
{p_end}

{phang}
{opt rows(#)} — Número de filas en la leyenda de la gráfica.
{p_end}

{phang}
{opt cols(#)} — Número de columnas en la leyenda de la gráfica.
{p_end}

{phang}
{opt title(string)} — Título personalizado para la gráfica.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Análisis básico del año en curso}{p_end}
{phang2}{cmd:. LIF}{p_end}

{pstd}{bf:Ejemplo 2 — Año específico}{p_end}
{phang2}{cmd:. LIF, anio(2025)}{p_end}

{pstd}{bf:Ejemplo 3 — Comparar con 2015, datos observados}{p_end}
{phang2}{cmd:. LIF, anio(2025) desde(2015) eofp}{p_end}
{pstd}Muestra solo datos observados, sin proyectar meses faltantes.{p_end}

{pstd}{bf:Ejemplo 4 — Proyectar cierre del año en curso}{p_end}
{phang2}{cmd:. LIF, proyeccion}{p_end}
{pstd}Estima el total anual usando la tendencia mensual histórica.{p_end}

{pstd}{bf:Ejemplo 5 — Actualizar datos y sin gráficas}{p_end}
{phang2}{cmd:. LIF, anio(2025) update nographs}{p_end}

{pstd}{bf:Ejemplo 6 — Personalizar gráfica}{p_end}
{phang2}{cmd:. LIF, anio(2025) desde(2015) minimum(0.5) rows(2) cols(4) title("Ingresos Tributarios 2025")}{p_end}
{pstd}Solo muestra rubros que representen al menos 0.5% del PIB.{p_end}

{pstd}{bf:Ejemplo 7 — Solo base de datos sin cálculos}{p_end}
{phang2}{cmd:. LIF, base}{p_end}
{pstd}Descarga la base cruda para análisis personalizados.{p_end}

{pstd}{bf:Ejemplo 8 — Análisis por concepto de ingreso}{p_end}
{phang2}{cmd:. LIF, anio(2025) by(concepto) minimum(1)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes cuatro tablas en pantalla, una gráfica y una base de datos:
{p_end}

{phang2}{bf:Tabla A — Ingresos por categoría:} Montos absolutos, % del PIB y
% del total de ingresos para el año de análisis{p_end}

{phang2}{bf:Tabla B — Ingresos resumidos:} Ingresos netos (excluye deuda y
aportaciones de seguridad social), con crecimiento real respecto al año de comparación{p_end}

{phang2}{bf:Tabla C — Cambios:} Diferencias en puntos porcentuales del PIB
entre el año de análisis y el año de comparación{p_end}

{phang2}{bf:Tabla D — Elasticidades:} Elasticidad de cada rubro de ingreso
respecto al crecimiento del PIB{p_end}

{pstd}{bf:Gráfica:} Composición de los ingresos presupuestarios como % del PIB
por año, con cada rubro en distinto color.{p_end}

{pstd}{bf:Archivos guardados:}{p_end}
{phang2}— {cmd:04_master/LIF.dta} — Base consolidada de ingresos 1993–año actual{p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{hline}

{marker variables}{...}
{title:Variables y scalars generados}

{pstd}{bf:Variables en la base de datos:}{p_end}

{phang2}{bf:anio} — Año{p_end}
{phang2}{bf:mes} — Mes (1–12){p_end}
{phang2}{bf:concepto} — Nombre del rubro de ingreso{p_end}
{phang2}{bf:divLIF} — Clasificación CIEP del ingreso{p_end}
{phang2}{bf:recaudacion} — Monto recaudado en millones de pesos nominales{p_end}
{phang2}{bf:recaudacionPIB} — Recaudación como % del PIB{p_end}
{phang2}{bf:recaudacionR} — Recaudación en términos reales (pesos del año base){p_end}
{phang2}{bf:pibY} — PIB nominal del año{p_end}
{phang2}{bf:deflator} — Deflactor del PIB{p_end}

{pstd}{bf:Scalars r() principales:}{p_end}

{phang2}{bf:r(IngTot)} — Ingresos totales del año de análisis{p_end}
{phang2}{bf:r(IngTotPIB)} — Ingresos totales como % del PIB{p_end}
{phang2}{bf:r(ISR)} — Recaudación del ISR{p_end}
{phang2}{bf:r(IVA)} — Recaudación del IVA{p_end}
{phang2}{bf:r(IEPS)} — Recaudación del IEPS{p_end}
{phang2}{bf:r(Petroleros)} — Ingresos petroleros{p_end}
{phang2}{bf:r(rc)} — "NoData" si no hay información para el año solicitado{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:SHCP — Ley de Ingresos de la Federación:}
{browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Paquete_Economico_y_Presupuesto"}
{p_end}

{pstd}
2. {bf:SHCP — Estadísticas Oportunas de Finanzas Públicas:}
{browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
3. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/PEF.sthlp":PEF} {c |}
{view "06_helps/SHRFSP.sthlp":SHRFSP} {c |}
{view "06_helps/DatosAbiertos.sthlp":DatosAbiertos} {c |}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "06_helps/TasasEfectivas.sthlp":TasasEfectivas}
{p_end}

{smcl_end}
