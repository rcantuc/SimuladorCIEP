{smcl}
{* *! version 1.  20feb2025}{...}
{viewerdialog PIBDeflactor "dialog PIBDeflactor"}{...}
{vieweralsosee "[R] PIBDeflactor" "mansection R PIBDeflactor"}{...}
{viewerjumpto "Syntax" "PIBDeflactor##syntax"}{...}
{viewerjumpto "Description" "PIBDeflactor##description"}{...}
{viewerjumpto "Options" "PIBDeflactor##options"}{...}
{viewerjumpto "Examples" "PIBDeflactor##examples"}{...}
{viewerjumpto "References" "PIBDeflactor##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt PIBDeflactor} [if] [, {it:aniovp(int)} {it:aniomax(int)} {it:geopib(int)} {it:geodef(int)} {it:discount(real)} {it:nographs} {it:update}]
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

{pstd}Ejemplo 1: Uso básico{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2024) aniomax(2070) geopib(1993) geodef(1993) discount(5)}
{p_end}

{pstd}Ejemplo 2: Uso sin generación de gráficas y con actualización de datos{p_end}
{phang2}{cmd:. PIBDeflactor, aniovp(2024) aniomax(2070) geopib(1993) geodef(1993) discount(5) nographs update}
{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Banco de Indicadores:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:Bases de Datos CONAPO:} {browse "https://www.gob.mx/conapo/articulos/reconstruccion-y-proyecciones-de-la-poblacion-de-los-municipios-de-mexico"}
{p_end}

{smcl_end}
