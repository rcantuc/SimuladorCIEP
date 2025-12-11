{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog PIBDeflactor "dialog PIBDeflactor"}{...}
{vieweralsosee "[R] PIBDeflactor" "mansection R PIBDeflactor"}{...}
{viewerjumpto "Syntax" "PIBDeflactor##syntax"}{...}
{viewerjumpto "Description" "PIBDeflactor##description"}{...}
{viewerjumpto "Options" "PIBDeflactor##options"}{...}
{viewerjumpto "Examples" "PIBDeflactor##examples"}{...}
{viewerjumpto "Output" "PIBDeflactor##output"}{...}
{viewerjumpto "References" "PIBDeflactor##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:PIBDeflactor} [{it:if}] [, {opt ANIOvp(int)} {opt NOGraphs} {opt UPDATE} {opt GEOPIB(int)} {opt GEODEF(int)} {opt DIScount(real)} {opt ANIOMAX(int)} {opt NOOutput} {opt TEXTbook}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:PIBDeflactor} es un comando diseñado para automatizar el cálculo y proyección de indicadores económicos relacionados con el PIB, utilizando datos del {bf:BIE} y del {bf:CONAPO}.  
Integra dos fuentes de datos:
{p_end}

{pstd}
1. {bf:BIE:} Proporciona datos sobre el PIB, el deflactor, la inflación y el empleo.
{p_end}

{pstd}
2. {bf:CONAPO:} Contiene estimaciones de población de 1950 a 2070.
{p_end}

{pstd}
Genera los siguientes indicadores:
{p_end}

{pstd}
{bf:Crecimiento Económico y Productividad:}
   - {bf:pibY:} PIB nominal en moneda corriente.
   - {bf:pibYR:} PIB real ajustado por inflación.
   - {bf:var_pibY:} Crecimiento anual del PIB real.
   - {bf:var_pibG:} Promedio geométrico del crecimiento del PIB real.
   - {bf:PIBPob:} PIB real per cápita.
   - {bf:pibPO:} PIB real por población ocupada.
   - {bf:OutputPerWorker:} PIB real por población en edad de trabajar.
   - {bf:pibYVP:} PIB real descontado a valor presente.
{p_end}

{pstd}
{bf:Demografía:}
   - {bf:PoblacionENOE:} Población total estimada según la ENOE de INEGI.
   - {bf:PoblacionOcupada:} Población ocupada según la ENOE de INEGI.
   - {bf:PoblacionDesocupada:} Población desocupada según la ENOE de INEGI.
   - {bf:Poblacion:} Estimaciones de población de CONAPO.
   - {bf:PoblacionO:} Población ocupada ajustada para cálculos de productividad.
   - {bf:WorkingAge:} Población en edad de trabajar (15-65 años) según CONAPO.
{p_end}

{pstd}
{bf:Precios e Inflación:}
   - {bf:inpc:} Índice Nacional de Precios al Consumidor (INPC).
   - {bf:IndiceY:} Índice de precios implícitos del PIB.
   - {bf:deflator:} Deflactor del PIB basado en el índice de precios implícitos.
   - {bf:deflatorpp:} Poder adquisitivo ajustado por inflación.
   - {bf:var_indiceY:} Crecimiento anual del índice de precios implícitos.
   - {bf:var_indiceG:} Promedio geométrico del crecimiento del índice de precios.
   - {bf:var_inflY:} Inflación anual calculada con el INPC.
   - {bf:var_inflG:} Promedio geométrico de la inflación en varios años.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt aniovp(int)}    Especifica el año base para calcular el valor presente (rango: 1993–2050).
{p_end}

{phang}
{opt aniomax(int)}   Especifica el año final para las proyecciones (por defecto 2070).
{p_end}

{phang}
{opt geopib(int)}    Especifica el año base para calcular el promedio geométrico del crecimiento del PIB.
{p_end}

{phang}
{opt geodef(int)}    Especifica el año base para calcular el promedio geométrico del deflactor del PIB.
{p_end}

{phang}
{opt discount(real)}  Tasa de descuento para convertir valores futuros a valor presente.
{p_end}

{phang}
{opt nographs}       Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}         Ejecuta un do-file para actualizar la base de datos con datos recientes.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Ejemplo 1}: Uso básico con año base 2025{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2025)}
{p_end}

{pstd}{bf:Ejemplo 2}: Proyección hasta 2050 con tasa de descuento del 3%{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2025) aniomax(2050) discount(3)}
{p_end}

{pstd}{bf:Ejemplo 3}: Calcular promedios geométricos desde 2000{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2025) geopib(2000) geodef(2000)}
{p_end}

{pstd}{bf:Ejemplo 4}: Actualizar datos sin generar gráficas{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2025) update nographs}
{p_end}

{pstd}{bf:Ejemplo 5}: Filtrar solo años específicos{p_end}
{phang2}{cmd:. PIBDeflactor if anio >= 2010 & anio <= 2030, aniovp(2025)}
{p_end}

{pstd}{bf:Ejemplo 6}: Uso completo con todos los parámetros{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2025) aniomax(2070) geopib(2000) geodef(2000) discount(5) nographs}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando genera una base de datos con las siguientes variables principales:
{p_end}

{phang2}- {bf:anio}: Año de la observación{p_end}
{phang2}- {bf:pibY}: PIB nominal{p_end}
{phang2}- {bf:pibYR}: PIB real (deflactado al año base){p_end}
{phang2}- {bf:deflator}: Índice deflactor (año base = 1){p_end}
{phang2}- {bf:deflatorpp}: Poder adquisitivo basado en INPC{p_end}
{phang2}- {bf:var_pibY}: Crecimiento anual del PIB real{p_end}
{phang2}- {bf:var_pibG}: Promedio geométrico del crecimiento{p_end}
{phang2}- {bf:var_indiceY}: Crecimiento anual del deflactor{p_end}
{phang2}- {bf:var_inflY}: Inflación anual (INPC){p_end}
{phang2}- {bf:PIBPob}: PIB real per cápita{p_end}
{phang2}- {bf:OutputPerWorker}: PIB por trabajador en edad laboral{p_end}

{pstd}
También genera gráficas de:
{p_end}

{phang2}- Productividad laboral{p_end}
{phang2}- Índice de precios implícitos{p_end}
{phang2}- Crecimiento del PIB{p_end}
{phang2}- PIB per cápita{p_end}
{phang2}- Inflación (INPC){p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Banco de Indicadores INEGI:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:Sistema de Cuentas Nacionales:} {browse "https://www.inegi.org.mx/temas/pib/"}
{p_end}

{pstd}
3. {bf:Proyecciones de Población CONAPO:} {browse "https://www.gob.mx/conapo"}
{p_end}

{title:See Also}

{pstd}
{help Poblacion}, {help SCN}, {help LIF}, {help PEF}
{p_end}

{smcl_end}
