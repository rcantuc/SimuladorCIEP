{smcl}
{* *! version 1.  22mar2025}{...}
{viewerdialog scn "dialog scn"}{...}
{vieweralsosee "[R] SCN" "mansection R SCN"}{...}
{viewerjumpto "Syntax" "SCN##syntax"}{...}
{viewerjumpto "Description" "SCN##description"}{...}
{viewerjumpto "Options" "SCN##options"}{...}
{viewerjumpto "Examples" "SCN##examples"}{...}
{viewerjumpto "References" "SCN##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt SCN} [, ANIO(int) NOGraphs UPDATE ANIOMax(int) TEXTBOOK]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:SCN} es un comando que automatiza la extracción y proyección de datos del Sistema de Cuentas Nacionales (SCN) del INEGI.
Utiliza dos fuentes de datos:
{p_end}

{pstd}
1. {bf:Banco de Indicadores (BIE):} Proporciona datos sobre el ingreso, la producción bruta, la cuenta de ingreso nacional disponible, el consumo de los hogares, el gasto de consumo privado, el gasto de consumo del gobierno y el PIB por actividad económica.
{p_end}

{pstd}
2. {bf:Cuentas por Sectores Institucionales (CSI):} Proporciona información sobre el ingreso mixto bruto, las cuotas a la seguridad social, los subsidios a los productos, la producción e importaciones y los excedentes de operación.
{p_end}

{pstd}
Además, el comando implementa un modelo de forecast para proyectar datos futuros, generando una base de datos integral del SCN que abarca desde 1993 hasta 2070.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anio(int)}    Especifica el año inicial de la proyección (rango: 1993–2069).
{p_end}

{phang}
{opt aniomax(int)} Define el año final para la proyección (rango: 1994–2070).
{p_end}

{phang}
{opt nographs}    Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}      Ejecuta un do‑file para actualizar la base de datos con los datos más recientes.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Ejemplo 1: Uso básico sin gráficos{p_end}
{phang2}{cmd:. SCN, anio(2025) aniomax(2070)}
{p_end}

{pstd}Ejemplo 2: Uso con actualización de datos{p_end}
{phang2}{cmd:. SCN, anio(2025) aniomax(2070) update}
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Banco de Indicadores:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:Cuentas por Sectores Institucionales:} {browse "https://www.inegi.org.mx/temas/si/#tabulados"}
{p_end}

{smcl_end}
