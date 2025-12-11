{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog LIF "dialog LIF"}{...}
{vieweralsosee "[R] LIF" "mansection R LIF"}{...}
{viewerjumpto "Syntax" "LIF##syntax"}{...}
{viewerjumpto "Description" "LIF##description"}{...}
{viewerjumpto "Options" "LIF##options"}{...}
{viewerjumpto "Examples" "LIF##examples"}{...}
{viewerjumpto "Output" "LIF##output"}{...}
{viewerjumpto "References" "LIF##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:LIF} [{it:if}] [, {opt ANIO(int)} {opt BY(varname)} {opt UPDATE} {opt NOGraphs} {opt Base} {opt MINimum(real)} {opt DESDE(int)} {opt EOFP} {opt PROYeccion} {opt ROWS(int)} {opt COLS(int)} {opt TITle(string)}]
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

{pstd}{bf:Ejemplo 1}: Análisis básico de ingresos para 2025{p_end}
{phang2}{cmd:. LIF, anio(2025)}
{p_end}

{pstd}{bf:Ejemplo 2}: Comparar ingresos desde 2015 con datos observados{p_end}
{phang2}{cmd:. LIF, anio(2025) desde(2015) EOFP}
{p_end}

{pstd}{bf:Ejemplo 3}: Proyectar ingresos del año incompleto{p_end}
{phang2}{cmd:. LIF, anio(2025) proyeccion}
{p_end}

{pstd}{bf:Ejemplo 4}: Actualizar datos y generar análisis sin gráficas{p_end}
{phang2}{cmd:. LIF, anio(2025) desde(2015) update nographs}
{p_end}

{pstd}{bf:Ejemplo 5}: Personalizar gráfica con título y leyenda{p_end}
{phang2}{cmd:. LIF, anio(2025) desde(2015) minimum(0.5) rows(2) cols(4) title("Ingresos Tributarios")}
{p_end}

{pstd}{bf:Ejemplo 6}: Obtener solo la base de datos sin cálculos{p_end}
{phang2}{cmd:. LIF, base}
{p_end}

{pstd}{bf:Ejemplo 7}: Análisis por tipo de impuesto{p_end}
{phang2}{cmd:. LIF if divLIF == 1, anio(2025)}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando muestra automáticamente:
{p_end}

{phang2}- {bf:Sección A}: Ingresos por categoría con montos, % PIB y % del total{p_end}
{phang2}- {bf:Sección B}: Ingresos resumidos (sin deuda) y crecimiento real{p_end}
{phang2}- {bf:Sección C}: Cambios en puntos porcentuales del PIB entre años{p_end}
{phang2}- {bf:Sección D}: Elasticidades de los ingresos respecto al PIB{p_end}

{pstd}
Variables generadas:
{p_end}

{phang2}- {bf:recaudacion}: Monto recaudado (observado o proyectado){p_end}
{phang2}- {bf:recaudacionPIB}: Recaudación como % del PIB{p_end}
{phang2}- {bf:recaudacionR}: Recaudación en términos reales{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Ley de Ingresos de la Federación:} {browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Paquete_Economico_y_Presupuesto"}
{p_end}

{pstd}
2. {bf:Estadísticas Oportunas de Finanzas Públicas:} {browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Estadisticas_Oportunas_de_Finanzas_Publicas"}
{p_end}

{pstd}
3. {bf:Banco de Indicadores INEGI:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:See Also}

{pstd}
{help PEF}, {help DatosAbiertos}, {help PIBDeflactor}, {help SHRFSP}
{p_end}

{smcl_end}
