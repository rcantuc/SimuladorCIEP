{smcl}
{* *! version 8.0 CIEP 03jul2026}{...}
{viewerjumpto "Descripción" "AccesoBIE##description"}{...}
{viewerjumpto "Configuración del token" "AccesoBIE##token"}{...}
{viewerjumpto "Primeros pasos" "AccesoBIE##quickstart"}{...}
{viewerjumpto "Sintaxis" "AccesoBIE##syntax"}{...}
{viewerjumpto "Opciones" "AccesoBIE##options"}{...}
{viewerjumpto "Cómo encontrar una clave" "AccesoBIE##findkey"}{...}
{viewerjumpto "Series comunes" "AccesoBIE##series"}{...}
{viewerjumpto "Ejemplos" "AccesoBIE##examples"}{...}
{viewerjumpto "Resultados" "AccesoBIE##output"}{...}
{viewerjumpto "Referencias" "AccesoBIE##references"}{...}

{title:AccesoBIE — Banco de Información Económica del INEGI}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}{break}
Ricardo Cantú Calderón {c |} {browse "mailto:ricardocantu@ciep.mx":ricardocantu@ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:AccesoBIE} descarga directamente a Stata cualquier serie del
{bf:Banco de Información Económica (BIE)} del INEGI, con acceso a más de
{bf:200,000 series} sobre PIB, precios, empleo, sector externo y más.
{p_end}

{pstd}
El comando usa la {bf:API oficial del INEGI} con un sistema robusto de respaldo:
{p_end}

{phang2}1. Intenta primero con la API del BIE{p_end}
{phang2}2. Si falla, intenta con la API del BISE{p_end}
{phang2}3. Si ambas fallan, extrae los datos mediante web scraping del portal{p_end}
{phang2}4. Hasta 3 reintentos automáticos con 2 segundos de espera entre cada uno{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite cargar cualquier indicador económico del INEGI
sin necesidad de descargarlo manualmente. El comando detecta automáticamente
si la serie es anual, trimestral o mensual, y genera las variables de tiempo
correspondientes.
{p_end}

{pstd}
{bf:Nota técnica:} Requiere Python con las librerías {cmd:requests} y
{cmd:beautifulsoup4}. A partir de v8.0, el token de acceso al BIE/INEGI
{ul:no} viene incluido en el código del comando: debe fijarse como global
Stata antes de usarse (ver {it:Configuración del token} más abajo).
{p_end}

{hline}

{marker token}{...}
{title:Configuración del token del BIE}

{pstd}
A partir de v8.0, {cmd:AccesoBIE} requiere que el token del BIE/INEGI esté
fijado como global Stata {cmd:BIE_API_TOKEN} antes de usarse. Si el global
no está fijado y tampoco se pasa la opción {opt token()}, el comando aborta
con error.
{p_end}

{pstd}
El simulador usa un archivo {cmd:set_token.do} en la raíz del repositorio
para cargar el token. Este archivo está en {cmd:.gitignore} y nunca se
versiona; cada usuario tiene el suyo con su token personal.
{p_end}

{pstd}
{bf:Configuración inicial} (sólo una vez por máquina):
{p_end}

{phang2}1. Copia {cmd:set_token.template.do} (incluido en el repo) como
{cmd:set_token.do} en la misma carpeta:{p_end}
{phang2}{cmd:. ! cp set_token.template.do set_token.do}{p_end}

{phang2}2. Edita {cmd:set_token.do} y reemplaza {cmd:tu-token-aqui} con tu
token real.{p_end}

{pstd}
{cmd:SIM.do} carga el global automáticamente al inicio de cada corrida
(busca la línea con {cmd:capture do "set_token.do"}). No necesitas hacer
nada más en cada sesión.
{p_end}

{pstd}
Si no tienes token, solicítalo en
{browse "https://www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx":www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx}.
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para descargar el PIB nominal (clave 734407):
{p_end}

{phang2}{cmd:. AccesoBIE 734407, nombres(PIBNominal)}{p_end}

{pstd}
Para descargar tres series a la vez:
{p_end}

{phang2}{cmd:. AccesoBIE "734407 735143 446562", nombres(PIBNominal IndicePrecios PoblacionENOE)}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:AccesoBIE} {it:serie} [{it:serie2} ...] [{cmd:,} {opt Nombres(string)} {opt Token(string)}]
{p_end}

{pstd}
Donde {it:serie} es el código numérico de la serie en el BIE (ej. {cmd:734407}).
Para descargar múltiples series, enciérralas entre comillas separadas por espacio:
{cmd:"734407 735143 446562"}.
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt nombres(string)} — {bf:Nombres personalizados} para las variables descargadas,
separados por espacio. Si no se especifica, se usan los nombres de los metadatos del INEGI
(pueden ser largos o con caracteres especiales).
{p_end}

{phang}
{opt token(string)} — Token de acceso para la API del INEGI. Si se omite, el
comando lee el global Stata {cmd:$BIE_API_TOKEN}. Si tampoco está fijado el
global, el comando aborta con error. Ver {it:Configuración del token} arriba.
{p_end}

{hline}

{marker findkey}{...}
{title:Cómo encontrar la clave de una serie}

{pstd}
Pasos para localizar el código numérico de cualquier serie en el BIE:
{p_end}

{phang2}1. Ir a: {browse "https://www.inegi.org.mx/app/indicadores/":Banco de Información Económica (BIE)}{p_end}
{phang2}2. Buscar el indicador deseado (ej. "Población ocupada"){p_end}
{phang2}3. Hacer clic en el indicador para ver sus detalles{p_end}
{phang2}4. Localizar el código numérico en la URL o en los metadatos (ej. {cmd:446562}){p_end}
{phang2}5. Usar ese código en {cmd:AccesoBIE}{p_end}

{hline}

{marker series}{...}
{title:Series comunes del BIE}

{pstd}{bf:PIB y precios:}{p_end}
{phang2}{bf:734407} — PIB nominal (millones de pesos corrientes){p_end}
{phang2}{bf:735143} — Índice de precios implícitos del PIB{p_end}
{phang2}{bf:628194} — PIB a precios corrientes (serie alternativa){p_end}

{pstd}{bf:Empleo y población:}{p_end}
{phang2}{bf:446562} — Población total (ENOE){p_end}
{phang2}{bf:444612} — Tasa de desocupación{p_end}

{pstd}{bf:Sector externo:}{p_end}
{phang2}{bf:493911} — PIB trimestral a precios constantes{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Una serie con nombre automático}{p_end}
{phang2}{cmd:. AccesoBIE 628194}{p_end}
{pstd}Descarga el PIB. El nombre de la variable viene de los metadatos del INEGI.{p_end}

{pstd}{bf:Ejemplo 2 — Una serie con nombre personalizado}{p_end}
{phang2}{cmd:. AccesoBIE 734407, nombres(PIBNominal)}{p_end}

{pstd}{bf:Ejemplo 3 — Múltiples series con nombres personalizados}{p_end}
{phang2}{cmd:. AccesoBIE "734407 735143 446562", nombres(PIBNominal IndicePrecios PoblacionENOE)}{p_end}
{pstd}Descarga las tres series y las combina en una sola base de datos por año.{p_end}

{pstd}{bf:Ejemplo 4 — PIB trimestral, inflación y empleo}{p_end}
{phang2}{cmd:. AccesoBIE "493911 628229 444612", nombres(PIBTrim INPC PoblacionOcupada)}{p_end}

{pstd}{bf:Ejemplo 5 — Con token personalizado}{p_end}
{phang2}{cmd:. AccesoBIE 628194, token(mi-token-personal)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando se genera una base de datos en memoria con:
{p_end}

{phang2}{bf:anio} — Año de la observación{p_end}
{phang2}{bf:mes} — Mes (si la serie es mensual){p_end}
{phang2}{bf:trimestre} — Trimestre (si la serie es trimestral){p_end}
{phang2}{bf:subperiodo} — Otros tipos de período{p_end}
{phang2}{it:nombre} — Variable con los valores de la serie (nombre automático o personalizado){p_end}

{pstd}
Las variables incluyen {bf:etiquetas descriptivas} obtenidas automáticamente
de los metadatos del INEGI.
{p_end}

{pstd}{bf:Procesamiento automático de los datos:}{p_end}
{phang2}— Limpieza de períodos: elimina los sufijos {cmd:/p} (preliminar) y {cmd:/r} (revisado) que reporta el INEGI{p_end}
{phang2}— Conversión de tipos: los valores {cmd:"N/E"} y {cmd:"ND"} se convierten a missing{p_end}
{phang2}— Detección automática de la frecuencia de la serie (anual, trimestral o mensual){p_end}

{pstd}{bf:Archivos temporales generados:}{p_end}
{phang2}— {cmd:raw/temp/AccesoBIE/[serie].csv} — Archivo CSV por serie descargada{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:INEGI — API de Indicadores:}
{browse "https://www.inegi.org.mx/servicios/api_indicadores.html"}
{p_end}

{pstd}
3. {bf:INEGI — Documentación de la API:}
{browse "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/"}
{p_end}

{title:Ver también}

{pstd}
{view "help/Stata/DatosAbiertos.sthlp":DatosAbiertos} {c |}
{view "help/Stata/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "help/Stata/LIF.sthlp":LIF} {c |}
{view "help/Stata/PEF.sthlp":PEF}
{p_end}

{smcl_end}

