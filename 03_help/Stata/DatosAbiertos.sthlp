{smcl}
{* *! version 8.0 CIEP 03jul2026}{...}
{viewerjumpto "Descripción" "DatosAbiertos##description"}{...}
{viewerjumpto "Primeros pasos" "DatosAbiertos##quickstart"}{...}
{viewerjumpto "Sintaxis" "DatosAbiertos##syntax"}{...}
{viewerjumpto "Opciones" "DatosAbiertos##options"}{...}
{viewerjumpto "Cómo encontrar una clave" "DatosAbiertos##findkey"}{...}
{viewerjumpto "Series comunes" "DatosAbiertos##series"}{...}
{viewerjumpto "Ejemplos" "DatosAbiertos##examples"}{...}
{viewerjumpto "Resultados" "DatosAbiertos##output"}{...}
{viewerjumpto "Referencias" "DatosAbiertos##references"}{...}

{title:DatosAbiertos — Estadísticas Oportunas de Finanzas Públicas (SHCP)}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:DatosAbiertos} proporciona acceso directo a cualquier serie de las
{bf:Estadísticas Oportunas de Finanzas Públicas (ESTOPOR)} de la SHCP,
con más de 500 series disponibles sobre ingresos, gastos, deuda y balance fiscal.
{p_end}

{pstd}
El comando integra automáticamente tres fuentes para enriquecer los datos:
{p_end}

{phang2}1. {bf:ESTOPOR (SHCP)} — Serie fiscal mensual solicitada{p_end}
{phang2}2. {bf:PIBDeflactor} — PIB y deflactor para expresar valores como % del PIB y en términos reales{p_end}
{phang2}3. {bf:Poblacion (CONAPO)} — Población para calcular valores per cápita{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite analizar cualquier indicador fiscal de México con
contexto macroeconómico: evolución mensual, comparación anual, proporción del PIB
y valor per cápita, todo en un solo comando.
{p_end}

{pstd}
{bf:Tipos de series disponibles:}
{p_end}
{phang2}— {bf:Flujo}: Ingresos, gastos, transacciones mensuales (se acumulan en el año){p_end}
{phang2}— {bf:Saldo}: Deuda, posiciones de balance (valor al final del período){p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para consultar los ingresos presupuestarios totales:
{p_end}

{phang2}{cmd:. DatosAbiertos XAB}{p_end}

{pstd}
Para consultar el balance público desde 2015:
{p_end}

{phang2}{cmd:. DatosAbiertos XAA, desde(2015)}{p_end}

{pstd}
{bf:¿No sabes la clave?} Consulta la sección {view "help/Stata/DatosAbiertos.sthlp##findkey":Cómo encontrar una clave}
o la lista de {view "help/Stata/DatosAbiertos.sthlp##series":Series comunes}.
{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:DatosAbiertos} {it:clave} [{it:if}] [{cmd:,} {opt DESDE(#)} {opt PIBVP(#)} {opt PIBVF(#)} {opt NOGraphs} {opt UPDATE} {opt PROYeccion} {opt REVERSE} {opt ZIPFILE} {opt CSVFILE} {opt FILES}]
{p_end}

{pstd}
Donde {it:clave} es el código de la serie en las Estadísticas Oportunas de la SHCP
(ej. {cmd:XAB}, {cmd:XAA}, {cmd:XED10}).
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt desde(#)} — {bf:Año inicial} para las gráficas y comparaciones.
Por defecto: 2008.
{p_end}

{phang}
{opt pibvp(#)} — {bf:Cifra oficial para el año en curso}, expresada como % del PIB.
Sustituye el valor observado del año actual de la serie. Útil cuando existe una
cifra oficial parcial (por ejemplo, de un documento del paquete económico) antes
de que cierre el año y llegue la información definitiva.
{p_end}

{phang}
{opt pibvf(#)} — {bf:Estimación oficial para el año siguiente}, expresada como % del PIB.
Agrega el punto a la gráfica para el año inmediato posterior al actual, cuando existe
una estimación oficial pero todavía no hay cifra realizada.
{p_end}

{phang}
{opt nographs} — Suprime la generación de gráficas.
{p_end}

{phang}
{opt update} — Descarga los datos más recientes de las Estadísticas Oportunas SHCP.
Requiere conexión a internet.
{p_end}

{phang}
{opt proyeccion} — {bf:Proyecta el cierre anual} de los meses faltantes usando
la distribución mensual histórica. Útil para estimar el total del año en curso.
{p_end}

{phang}
{opt reverse} — Invierte el signo de los montos. Útil para series que la SHCP
reporta en negativo (ej. algunos componentes de gasto).
{p_end}

{phang}
{opt zipfile} — Descarga los datos desde los archivos ZIP del portal SHCP
(más rápido para actualizaciones completas).
{p_end}

{phang}
{opt csvfile} — Descarga los datos directamente desde archivos CSV en línea.
{p_end}

{phang}
{opt files} — {bf:Reconstruye la base desde los archivos locales} ya descargados
en {cmd:raw/temp/Datos Abiertos/}, sin conexión a internet. Útil para ahorrar tiempo
cuando los archivos fuente ya están en tu máquina.
{p_end}

{hline}

{marker findkey}{...}
{title:Cómo encontrar la clave de una serie}

{pstd}
Pasos para localizar el código de cualquier serie en las Estadísticas Oportunas:
{p_end}

{phang2}1. Ir a: {browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp":ESTOPOR — Estadísticas Oportunas SHCP}{p_end}
{phang2}2. Buscar el reporte de tu interés (ej. "Ingresos Petroleros del Sector Público"){p_end}
{phang2}3. Seleccionar la serie específica{p_end}
{phang2}4. Copiar el código que aparece (ej. {cmd:XAC10}){p_end}
{phang2}5. Pegar el código después de {cmd:DatosAbiertos} en la consola{p_end}

{hline}

{marker series}{...}
{title:Series comunes}

{pstd}{bf:Ingresos:}{p_end}
{phang2}{bf:XAB} — Ingresos presupuestarios totales{p_end}
{phang2}{bf:XAA} — Balance público{p_end}
{phang2}{bf:XAA30} — Balance primario{p_end}

{pstd}{bf:Gasto:}{p_end}
{phang2}{bf:XAC} — Gasto público neto pagado{p_end}

{pstd}{bf:Deuda:}{p_end}
{phang2}{bf:XED10} — Deuda interna del sector público federal{p_end}
{phang2}{bf:XEB00} — Deuda externa del sector público federal{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Ingresos presupuestarios totales}{p_end}
{phang2}{cmd:. DatosAbiertos XAB}{p_end}

{pstd}{bf:Ejemplo 2 — Balance público desde 2015}{p_end}
{phang2}{cmd:. DatosAbiertos XAA, desde(2015)}{p_end}

{pstd}{bf:Ejemplo 3 — Deuda interna con proyección del año en curso}{p_end}
{phang2}{cmd:. DatosAbiertos XED10, proyeccion}{p_end}
{pstd}Estima el saldo al cierre del año usando la tendencia mensual.{p_end}

{pstd}{bf:Ejemplo 4 — Deuda externa sin gráficas}{p_end}
{phang2}{cmd:. DatosAbiertos XEB00, nographs}{p_end}

{pstd}{bf:Ejemplo 5 — Actualizar datos y consultar balance primario}{p_end}
{phang2}{cmd:. DatosAbiertos XAA30, update desde(2010)}{p_end}

{pstd}{bf:Ejemplo 6 — Gasto neto con proyección desde 2008}{p_end}
{phang2}{cmd:. DatosAbiertos XAC, desde(2008) proyeccion}{p_end}

{pstd}{bf:Ejemplo 7 — Cifra oficial del año en curso y estimación del siguiente}{p_end}
{phang2}{cmd:. DatosAbiertos XAB, pibvp(23.5) pibvf(23.9)}{p_end}
{pstd}Sustituye el año actual con 23.5% del PIB y grafica 23.9% para el año siguiente.{p_end}

{pstd}{bf:Ejemplo 8 — Reconstruir la base sin internet}{p_end}
{phang2}{cmd:. DatosAbiertos XAA, files}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes una tabla en pantalla, cuatro gráficas y una base de datos:
{p_end}

{pstd}{bf:Tabla de resultados:} Comparación del último mes y acumulado anual
vs el año anterior, en términos nominales y reales.{p_end}

{pstd}{bf:Cuatro gráficas:}{p_end}
{phang2}A. {bf:Desglose mensual} — Registro mensual de la serie{p_end}
{phang2}B. {bf:Último mes por año} — Valor del último mes disponible de cada año{p_end}
{phang2}C. {bf:Acumulado anual} — Total acumulado hasta el último mes disponible{p_end}
{phang2}D. {bf:Acumulado anual como % del PIB} — Proporción respecto al PIB{p_end}

{pstd}{bf:Variables en la base de datos:}{p_end}
{phang2}{bf:anio}, {bf:mes} — Identificadores temporales{p_end}
{phang2}{bf:montomill} — Monto en millones de pesos nominales{p_end}
{phang2}{bf:monto_pc} — Monto per cápita en pesos reales{p_end}
{phang2}{bf:monto_pib} — Monto como % del PIB{p_end}
{phang2}{bf:deflactor} — Factor de deflactación (INPC){p_end}
{phang2}{bf:poblacion} — Población total del año{p_end}
{phang2}{bf:pibY} — PIB anual{p_end}
{phang2}{bf:acum_prom} — Proporción mensual promedio histórica{p_end}

{pstd}{bf:Archivos guardados:}{p_end}
{phang2}— {cmd:master/DatosAbiertos.dta} — Base completa de series ESTOPOR{p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{pstd}{bf:Cálculos mostrados según el tipo de serie:}{p_end}

{pstd}Para series de {bf:flujo} (ingresos, gastos):{p_end}
{phang2}— Comparación del último mes vs el mismo mes del año anterior (nominal y real){p_end}
{phang2}— Comparación del acumulado hasta el último mes vs el año anterior{p_end}
{phang2}— Tasas de crecimiento real interanual{p_end}

{pstd}Para series de {bf:saldo} (deuda, posiciones de balance):{p_end}
{phang2}— Saldo al último mes disponible vs diciembre del año anterior{p_end}
{phang2}— Saldo deflactado a pesos constantes y su crecimiento real{p_end}

{pstd}
{bf:Nota sobre escalas:} la fuente original reporta los montos en {bf:miles de pesos
nominales}; el comando los muestra en {bf:millones de pesos} (nominales y reales),
como % del PIB anual, y per cápita en pesos reales por habitante.
{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:SHCP — Estadísticas Oportunas de Finanzas Públicas:}
{browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
2. {bf:SHCP — Datos Abiertos:}
{browse "https://www.transparenciapresupuestaria.gob.mx/Datos-Abiertos"}
{p_end}

{pstd}
3. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:Ver también}

{pstd}
{view "help/Stata/LIF.sthlp":LIF} {c |}
{view "help/Stata/PEF.sthlp":PEF} {c |}
{view "help/Stata/SHRFSP.sthlp":SHRFSP} {c |}
{view "help/Stata/AccesoBIE.sthlp":AccesoBIE} {c |}
{view "help/Stata/PIBDeflactor.sthlp":PIBDeflactor}
{p_end}

{smcl_end}
