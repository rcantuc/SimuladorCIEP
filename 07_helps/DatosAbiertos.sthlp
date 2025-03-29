{smcl}
{* *! version 1.  6mar2025}{...}
{viewerdialog DatosAbiertos "dialog DatosAbiertos"}{...}
{vieweralsosee "[R] DatosAbiertos" "mansection R DatosAbiertos"}{...}
{viewerjumpto "Syntax" "DatosAbiertos##syntax"}{...}
{viewerjumpto "Description" "DatosAbiertos##description"}{...}
{viewerjumpto "Options" "DatosAbiertos##options"}{...}
{viewerjumpto "Examples" "DatosAbiertos##examples"}{...}
{viewerjumpto "References" "DatosAbiertos##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt DatosAbiertos} {it:series} [if] [, PIBVP(real) PIBVF(real) DESDE(real) UPDATE NOGraphs REVERSE PROYeccion ZIPFILE]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:DatosAbiertos} es un comando diseñado para proporcionar acceso estructurado y sistematizado a los datos de las {bf:Estadísticas Oportunas de Finanzas Públicas}, facilitando su consulta y análisis. Utiliza datos de la {bf:SHCP} y del {bf:INEGI}.
{p_end}

{pstd}
El comando permite acceder a cualquier indicador económico publicado por la SHCP y, además, utiliza indicadores de otros ado‑files para realizar precálculos.  
{p_end}

{pstd}
![Grafica1](images/DatosAbiertos/EstadisticasOportunas.png)
{p_end}

{pstd}
Fusiones con otros ado‑files:
  - {bf:Poblacion.ado:} Genera una variable que muestra el valor del indicador seleccionado per cápita.
  - {bf:PIBDeflactor.ado:} Permite mostrar el monto del indicador en relación con el tamaño de la economía y ajusta los valores para hacerlos comparables en el tiempo.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt DESDE(int)}   Especifica el {bf:Año de comparación}. El valor por default es 2008.
{p_end}

{phang}
{opt update}       Ejecuta un do‑file para obtener los datos más recientes del SHCP.
{p_end}

{phang}
{opt nographs}     Suprime la generación de gráficas.
{p_end}

{phang}
{opt PROYeccion}   Determina el manejo de datos faltantes. Al seleccionar PROYeccion, los valores se completan utilizando la tendencia del periodo analizado.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Ejemplo 1: Uso básico{p_end}
{phang2}{cmd:. DatosAbiertos XED10, DESDE(2008)}
{p_end}

{pstd}Ejemplo 2: Uso con actualización y sin gráficos{p_end}
{phang2}{cmd:. DatosAbiertos XED10, DESDE(2008) update nographs}
{p_end}

{pstd}Ejemplo 3: Uso con proyección de datos faltantes{p_end}
{phang2}{cmd:. DatosAbiertos XED10, DESDE(2008) PROYeccion}
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Estadísticas Oportunas de Finanzas Públicas:} {browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
2. {bf:Bases de Datos CONAPO:} {browse "https://www.gob.mx/conapo/articulos/reconstruccion-y-proyecciones-de-la-poblacion-de-los-municipios-de-mexico"}
{p_end}

{pstd}
3. {bf:Banco de Indicadores:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{smcl_end}
