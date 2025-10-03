{smcl}
{* *! version 1.  6mar2025}{...}
{viewerdialog PEF "dialog PEF"}{...}
{vieweralsosee "[R] PEF" "mansection R PEF"}{...}
{viewerjumpto "Syntax" "PEF##syntax"}{...}
{viewerjumpto "Description" "PEF##description"}{...}
{viewerjumpto "Options" "PEF##options"}{...}
{viewerjumpto "Examples" "PEF##examples"}{...}
{viewerjumpto "References" "PEF##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt PEF} [if] [, ANIO(int) BY(varname) UPDATE NOGraphs Base MINimum(real) DESDE(int) PEF PPEF APROBado ROWS(int) COLS(int) TITle(string)]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:PEF} es un comando diseñado para automatizar la extracción y el análisis de datos del {bf:Presupuesto de Egresos de la Federación (PEF)}.  
Este programa permite extraer y analizar automáticamente los datos oficiales del gasto público publicados por la {bf:SHCP} y utiliza datos del {bf:INEGI} para cálculos adicionales.
{p_end}

{pstd}
![TablaA](images/PEF/GastoPublico.png)
{p_end}

{pstd}
El comando procesa datos de tres fuentes:
  1. {bf:Cuenta Pública:} Contiene la distribución de los recursos públicos ejercidos en el gasto del gobierno federal.
  2. {bf:Presupuesto de Egresos de la Federación:} Documento que detalla la distribución de los recursos públicos aprobada para el gasto del gobierno federal, utilizado cuando la cuenta pública aún no ha sido publicada.
  3. {bf:BIE:} Proporciona datos sobre el PIB, el deflactor de precios, la inflación y el empleo.
{p_end}

{pstd}
El alcance del comando permite consultar el gasto histórico desde 2013 hasta el año actual, desglosando la distribución del gasto en salud, educación, seguridad y otros sectores, y evaluando su relación con el PIB.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anio(int)}    Especifica el {bf:Año Base} (por ejemplo, 2024).
{p_end}

{phang}
{opt desde(int)}   Especifica el {bf:Año de comparación} (por ejemplo, 2013).
{p_end}

{phang}
{opt nographs}    Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}      Ejecuta un do‑file para obtener los datos más recientes.
{p_end}

{phang}
{opt base}        Permite descargar únicamente la base de datos sin aplicar cálculos adicionales.
{p_end}

{dlgtab:Graph Customization}

{phang}
{opt minimum(real)}  Define el {bf:Rango mínimo} del PIB que un concepto de gasto debe alcanzar para ser visualizado en la gráfica.
{p_end}

{phang}
{opt rows(int)}      Especifica el número de {bf:Filas} en la leyenda de la gráfica.
{p_end}

{phang}
{opt cols(int)}      Especifica el número de {bf:Columnas} en la leyenda de la gráfica.
{p_end}

{phang}
{opt title(string)}    Define el {bf:Título} de la gráfica.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Ejemplo 1: Uso básico sin personalización de gráfica{p_end}
{phang2}{cmd:. PEF, anio(2024) desde(2013)}
{p_end}

{pstd}Ejemplo 2: Uso con actualización y sin gráficos{p_end}
{phang2}{cmd:. PEF, anio(2024) desde(2013) update nographs}
{p_end}

{pstd}Ejemplo 3: Uso con personalización de gráfica{p_end}
{phang2}{cmd:. PEF, anio(2024) desde(2013) minimum(0.5) rows(1) cols(5) title("Ingresos Fiscales")}
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Presupuesto de Egresos:} {browse "https://www.ppef.hacienda.gob.mx/"}
{p_end}

{pstd}
2. {bf:BIE:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
3. {bf:Transparencia Presupuestaria:} {browse "https://www.transparenciapresupuestaria.gob.mx/Datos-Abiertos"}
{p_end}

{smcl_end}
