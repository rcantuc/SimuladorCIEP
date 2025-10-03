{smcl}
{* *! version 1.  4mar2025}{...}
{viewerdialog SHRFSP "dialog SHRFSP"}{...}
{vieweralsosee "[R] SHRFSP" "mansection R SHRFSP"}{...}
{viewerjumpto "Syntax" "SHRFSP##syntax"}{...}
{viewerjumpto "Description" "SHRFSP##description"}{...}
{viewerjumpto "Options" "SHRFSP##options"}{...}
{viewerjumpto "Examples" "SHRFSP##examples"}{...}
{viewerjumpto "References" "SHRFSP##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt SHRFSP} [{it:if}] [, ANIO(int) DEPreciacion(int) NOGraphs UPDATE Base ULTAnio(int) TEXTbook]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:SHRFSP} es un comando diseñado para automatizar la extracción y el análisis del Saldo Histórico de los Requerimientos Financieros del Sector Público (SHRFSP). Utiliza información proveniente de la {bf:SHCP} y del {bf:BIE} para calcular indicadores relacionados con la deuda pública y la estructura fiscal.
{p_end}

{pstd}
![Imagen2](images/SHRSFP/1.SaldoHistorico_RSFP.png)
{p_end}

{pstd}
El comando procesa datos de:
  1. {bf:Estadísticas Oportunas de la SHCP:} Proporciona información sobre finanzas públicas, incluyendo balances fiscales, ingresos, gastos y deuda pública.
  2. {bf:BIE:} Proporciona datos sobre el PIB y el deflactor de precios.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anio(int)}    Cambia el año de referencia. Debe ser un número entre 1993 y el año actual (valor default).
{p_end}

{phang}
{opt ultanio(int)} Especifica el último año de referencia para la gráfica. Debe ser anterior al año base y en el rango de 1993 hasta el año actual. El valor predeterminado es 2001.
{p_end}

{phang}
{opt nographs}    Evita la generación de gráficas.
{p_end}

{phang}
{opt update}      Ejecuta un do‑file para actualizar los datos de la SHCP y del BIE.
{p_end}

{phang}
{opt base}        Solo despliega la base de datos sin aplicar cálculos adicionales.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Ejemplo 1: Uso básico{p_end}
{phang2}{cmd:. SHRFSP, anio(2024) ultanio(2001)}
{p_end}

{pstd}Ejemplo 2: Uso con actualización, sin gráficos y solo base{p_end}
{phang2}{cmd:. SHRFSP, anio(2024) ultanio(2001) nographs update base}
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Estadísticas Oportunas:} {browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
2. {bf:Banco de Indicadores:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
3. La tasa de interés se obtiene dividiendo el monto de intereses pagados entre la deuda para el mismo año.
{p_end}

{smcl_end}
