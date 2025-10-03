{smcl}
{* *! version 1.  27feb2025}{...}
{viewerdialog LIF "dialog LIF"}{...}
{vieweralsosee "[R] LIF" "mansection R LIF"}{...}
{viewerjumpto "Syntax" "LIF##syntax"}{...}
{viewerjumpto "Description" "LIF##description"}{...}
{viewerjumpto "Options" "LIF##options"}{...}
{viewerjumpto "Examples" "LIF##examples"}{...}
{viewerjumpto "References" "LIF##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt LIF} [if] [, ANIO(int) BY(varname) UPDATE NOGraphs Base MINimum(real) DESDE(int) EOFP PROYeccion ROWS(int) COLS(int) TITle(string)]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:LIF} es un comando diseñado para automatizar la extracción y el análisis de datos de los ingresos de la federación. Utiliza datos oficiales de la {bf:SHCP} y del {bf:INEGI}.
{p_end}

{pstd}
El comando permite acceder a los ingresos fiscales históricos para cualquier año, comparar su evolución a lo largo del tiempo y analizar su elasticidad en relación con el PIB. Además, la herramienta permite personalizar las gráficas para ajustarlas a tus necesidades de visualización.
{p_end}

{pstd}
![Imagen1](images/LIF/IngresosPresupuestarios.png)
{p_end}

{pstd}
El comando procesa datos de tres fuentes:
  1. {bf:LIF:} Ley con los montos aprobados para la recaudación de impuestos.
  2. {bf:Estadísticas Oportunas de la SHCP:} Proporciona información sobre finanzas públicas del país, incluyendo balances fiscales, ingresos, gastos y deuda pública.
  3. {bf:BIE:} Proporciona datos sobre el PIB y el deflactor de precios.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anio(int)}     Especifica el {bf:Año Base} (por ejemplo, 2024).
{p_end}

{phang}
{opt desde(int)}    Especifica el {bf:Año de comparación}. Por defecto se usan 10 años anteriores al año base.
{p_end}

{phang}
{opt EOFP|PROYeccion}  
    Indica el {bf:Manejo de Datos Faltantes}.  
    Selecciona {bf:PROYeccion} para completar los valores según la tendencia del periodo analizado, o {bf:EOFP} para mostrar los datos tal como están.
{p_end}

{phang}
{opt nographs}     Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}       Ejecuta un do‑file para obtener los datos más recientes del SHCP y del INEGI.
{p_end}

{phang}
{opt base}         Permite descargar únicamente la base de datos sin aplicar cálculos adicionales.
{p_end}

{dlgtab:Graph Customization}

{phang}
{opt minimum(real)}  Define el {bf:Rango mínimo} del PIB que un rubro debe alcanzar para mostrarse en la gráfica. El valor default es 0.25.
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
{phang2}{cmd:. LIF, anio(2024) desde(2013) EOFP}
{p_end}

{pstd}Ejemplo 2: Uso con actualización y sin gráficos{p_end}
{phang2}{cmd:. LIF, anio(2024) desde(2013) PROYeccion nographs update}
{p_end}

{pstd}Ejemplo 3: Uso con personalización de gráfica{p_end}
{phang2}{cmd:. LIF, anio(2024) desde(2013) EOFP minimum(0.5) rows(1) cols(5) title("Ingresos Fiscales")}
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Ley Federal de Ingresos:} {browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Paquete_Economico_y_Presupuesto"}
{p_end}

{pstd}
2. {bf:Estadísticas Oportunas:} {browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
3. {bf:Banco de Indicadores:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{smcl_end}
