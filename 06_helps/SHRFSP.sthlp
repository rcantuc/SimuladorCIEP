{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog SHRFSP "dialog SHRFSP"}{...}
{vieweralsosee "[R] SHRFSP" "mansection R SHRFSP"}{...}
{viewerjumpto "Syntax" "SHRFSP##syntax"}{...}
{viewerjumpto "Description" "SHRFSP##description"}{...}
{viewerjumpto "Options" "SHRFSP##options"}{...}
{viewerjumpto "Examples" "SHRFSP##examples"}{...}
{viewerjumpto "Output" "SHRFSP##output"}{...}
{viewerjumpto "References" "SHRFSP##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:SHRFSP} [{it:if}] [, {opt ANIO(int)} {opt DEPreciacion(int)} {opt NOGraphs} {opt UPDATE} {opt Base} {opt ULTAnio(int)} {opt TEXTbook}]
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

{pstd}{bf:Ejemplo 1}: Análisis básico de deuda pública 2025{p_end}
{phang2}{cmd:. SHRFSP, anio(2025)}
{p_end}

{pstd}{bf:Ejemplo 2}: Comparar desde 2005{p_end}
{phang2}{cmd:. SHRFSP, anio(2025) ultanio(2005)}
{p_end}

{pstd}{bf:Ejemplo 3}: Actualizar datos de la SHCP{p_end}
{phang2}{cmd:. SHRFSP, anio(2025) update}
{p_end}

{pstd}{bf:Ejemplo 4}: Análisis sin gráficas{p_end}
{phang2}{cmd:. SHRFSP, anio(2025) nographs}
{p_end}

{pstd}{bf:Ejemplo 5}: Obtener solo la base de datos cruda{p_end}
{phang2}{cmd:. SHRFSP, base}
{p_end}

{pstd}{bf:Ejemplo 6}: Filtrar por años específicos{p_end}
{phang2}{cmd:. SHRFSP if anio >= 2010, anio(2025)}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando despliega información detallada sobre:
{p_end}

{phang2}{bf:RFSP (Requerimientos Financieros del Sector Público):}{p_end}
{phang2}- Balance presupuestario{p_end}
{phang2}- PIDIREGAS{p_end}
{phang2}- IPAB{p_end}
{phang2}- FONADIN{p_end}
{phang2}- Programa de Deudores{p_end}
{phang2}- Banca de Desarrollo{p_end}
{phang2}- Adecuaciones{p_end}

{phang2}{bf:SHRFSP (Saldo Histórico):}{p_end}
{phang2}- Deuda interna y externa{p_end}
{phang2}- Deuda por plazo (corto y largo){p_end}
{phang2}- Deuda por deudor (Gobierno Federal, OyE, Banca){p_end}

{phang2}{bf:Indicadores calculados:}{p_end}
{phang2}- Valores como % del PIB{p_end}
{phang2}- Valores per cápita en términos reales{p_end}
{phang2}- Tasa efectiva de interés{p_end}
{phang2}- Costo financiero de la deuda{p_end}

{pstd}
Gráficas generadas:
{p_end}

{phang2}- SHRFSP como % del PIB vs PIB{p_end}
{phang2}- SHRFSP per cápita vs población{p_end}
{phang2}- SHRFSP vs recaudación{p_end}
{phang2}- Deuda interna vs externa{p_end}
{phang2}- Costo financiero y tasa efectiva{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Estadísticas Oportunas de Finanzas Públicas:} {browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Estadisticas_Oportunas_de_Finanzas_Publicas"}
{p_end}

{pstd}
2. {bf:Banco de Indicadores INEGI:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
3. {bf:Deuda Pública - SHCP:} {browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Deuda_Publica"}
{p_end}

{pstd}
{bf:Nota metodológica:} La tasa efectiva de interés se calcula dividiendo el costo financiero (intereses pagados) entre el saldo de la deuda para el mismo año.
{p_end}

{title:See Also}

{pstd}
{help LIF}, {help PEF}, {help PIBDeflactor}, {help DatosAbiertos}
{p_end}

{smcl_end}
