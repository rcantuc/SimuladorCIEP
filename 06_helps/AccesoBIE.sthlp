{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}
{viewerdialog AccesoBIE "dialog AccesoBIE"}{...}
{vieweralsosee "[R] AccesoBIE" "mansection R AccesoBIE"}{...}
{viewerjumpto "Syntax" "AccesoBIE##syntax"}{...}
{viewerjumpto "Description" "AccesoBIE##description"}{...}
{viewerjumpto "Options" "AccesoBIE##options"}{...}
{viewerjumpto "Examples" "AccesoBIE##examples"}{...}
{viewerjumpto "Output" "AccesoBIE##output"}{...}
{viewerjumpto "References" "AccesoBIE##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:AccesoBIE} {it:serie1} [{it:serie2} ...] [, {opt Nombres(string)} {opt Token(string)}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:AccesoBIE} descarga series de datos del Banco de Información Económica (BIE) y del Banco de Indicadores de Sustentabilidad Económica (BISE) del INEGI directamente a Stata mediante la API oficial.
{p_end}

{pstd}
El comando implementa un sistema robusto con:
{p_end}

{phang2}- Acceso directo a la API oficial del INEGI (BIE y BISE){p_end}
{phang2}- Sistema de respaldo mediante scraping del portal web si la API falla{p_end}
{phang2}- Reintentos automáticos (hasta 3 veces) en caso de errores de conexión{p_end}
{phang2}- Extracción automática de metadatos (nombre del indicador y etiquetas){p_end}
{phang2}- Combinación automática de múltiples series en una sola base de datos{p_end}

{marker options}{...}
{title:Options}

{dlgtab:General}

{phang}
{opt Nombres(string)} Especifica los nombres personalizados para las variables descargadas, separados por espacio. Si no se proporciona, se utilizan los nombres obtenidos de los metadatos del INEGI.
{p_end}

{phang}
{opt Token(string)} Token de acceso para la API del INEGI. Si no se especifica, se utiliza el token del CIEP por defecto.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Ejemplo 1}: Descargar una sola serie con nombre automático{p_end}
{phang2}{cmd:. AccesoBIE 628194}
{p_end}

{pstd}{bf:Ejemplo 2}: Descargar una serie con nombre personalizado{p_end}
{phang2}{cmd:. AccesoBIE 628194, nombres(PIB)}
{p_end}

{pstd}{bf:Ejemplo 3}: Descargar múltiples series con nombres personalizados{p_end}
{phang2}{cmd:. AccesoBIE 628194 444612, nombres(PIB Desempleo)}
{p_end}

{pstd}{bf:Ejemplo 4}: Descargar series de PIB trimestral, inflación y empleo{p_end}
{phang2}{cmd:. AccesoBIE 493911 628229 444612, nombres(PIBTrim INPC PoblacionOcupada)}
{p_end}

{pstd}{bf:Ejemplo 5}: Usar un token personalizado{p_end}
{phang2}{cmd:. AccesoBIE 628194, token(mi-token-personal-aqui)}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
Al ejecutar el comando se genera una base de datos que contiene:
{p_end}

{phang2}- {bf:anio}: Año de la observación{p_end}
{phang2}- {bf:mes} o {bf:trimestre}: Periodo subanual (si aplica){p_end}
{phang2}- Variables con los valores de cada serie solicitada{p_end}

{pstd}
Las variables incluyen etiquetas descriptivas obtenidas automáticamente de los metadatos del INEGI.
{p_end}

{title:Cómo encontrar las claves de las series}

{pstd}
1. Ir a: {browse "https://www.inegi.org.mx/app/indicadores/":Banco de Información Económica (BIE)}
{p_end}

{pstd}
2. Buscar el indicador deseado y hacer clic en "Metadatos" (esquina superior derecha).
{p_end}

{pstd}
3. Copiar el número que aparece en el campo "Clave".
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Banco de Información Económica:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:API del INEGI:} {browse "https://www.inegi.org.mx/servicios/api_indicadores.html"}
{p_end}

{pstd}
3. {bf:Documentación API:} {browse "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/"}
{p_end}

