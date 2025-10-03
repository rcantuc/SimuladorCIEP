{smcl}
{* *! version 1.0 Gabriel Santisteban 04apr2025}
{title:AccesoBIE}

{pstd}
{cmd:AccesoBIE} carga series de datos del Banco de Información Económica (BIE) del INEGI directamente a Stata.

{title:Syntax}

{p 8 15 2}
{cmd:AccesoBIE} {it:"claves"} {it:"nombres"}

{synoptset 20 tabbed}
{synoptline}
{synopt:{it:claves}} Claves de los indicadores económicos separados por espacio. Ej: "734407 735143"{p_end}
{synopt:{it:nombres}} Nombres con los que se guardarán las variables. Ej: "PibNominal Inflacion"{p_end}
{synoptline}

{title:Description}

{pstd}
Este comando automatiza la descarga de datos desde el BIE sin necesidad de ingresar manualmente a su sitio. Facilita la consulta de series como el PIB, el empleo, inflación, entre otros.

{title:Example}

{pstd}
Este comando carga tres indicadores: PIB a precios corrientes, índice de precios implícitos y población total:

{phang2}{cmd:. AccesoBIE "734407 735143 446562" "PibNominal IndicePrecios PoblacionENOE"}

{title:Output}

{pstd}
Al ejecutarlo, se genera una base de datos con las variables solicitadas y una variable de fecha para facilitar el análisis.

{title:Como encontrar las series del Banco de Indicares Económicos}

{pstd}
1. Ir a: {browse "https://www.inegi.org.mx/app/indicadores/default.aspx?tm=0#tabMCcollapse-Indicadores":Banco de Información Económica (BIE)}
2. Buscar el indicador deseado y seleccionar en la esquina superior derecha "metadato".
3. Copiar el código de la serie donde dice "clave".

{title:Referencias}

{pstd}
Datos obtenidos del Banco de Información Económica de INEGI.

{p 4 4 2}
{browse "https://www.inegi.org.mx/app/indicadores/"} 


