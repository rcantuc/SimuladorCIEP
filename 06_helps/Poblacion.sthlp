{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog Poblacion "dialog Poblacion"}{...}
{vieweralsosee "[R] Poblacion" "mansection R Poblacion"}{...}
{viewerjumpto "Syntax" "Poblacion##syntax"}{...}
{viewerjumpto "Description" "Poblacion##description"}{...}
{viewerjumpto "Options" "Poblacion##options"}{...}
{viewerjumpto "Examples" "Poblacion##examples"}{...}
{viewerjumpto "Output" "Poblacion##output"}{...}
{viewerjumpto "References" "Poblacion##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:Poblacion} [{it:if}] [, {opt ANIOinicial(int)} {opt ANIOFinal(int)} {opt NOGraphs} {opt UPDATE} {opt TEXTBOOK}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:Poblacion} es un comando que automatiza la extracción de datos de las Proyecciones de la Población de México, utilizando información proveniente del CONAPO.  
Integra tres bases de datos:

{pstd}
1. {bf:Población:} Estimación del número de habitantes a mitad de cada año (1950–2070).

{pstd}
2. {bf:Defunciones:} Estimación anual de defunciones (1950–2070).

{pstd}
3. {bf:Migración Internacional:} Estimación de inmigrantes y emigrantes (1950–2069).  

{pstd}
Genera una base de datos final que incluye datos históricos y proyecciones, permitiendo análisis por entidad, sexo, edad y año.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anioinicial(int)}    Especifica el año inicial de la proyección (rango: 1950–2069).
{p_end}

{phang}
{opt aniofinal(int)}     Especifica el año final de la proyección (rango: 1951–2070).
{p_end}

{phang}
{opt nographs}          Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}            Ejecuta un do-file para actualizar la base de datos con datos recientes.
{p_end}

{dlgtab:Filters}

{phang}
Opcionalmente, se pueden incluir filtros en la condición {it:if}:

{pstd}
  {bf:Entidad:} Filtra por entidad federativa (ej. "Jalisco", "Ciudad de México", etc.).

{pstd}
  {bf:Sexo:} Filtra por sexo, donde 1 representa Hombres, 2 Mujeres; si se omite, se incluyen ambos.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Ejemplo 1}: Proyección poblacional básica 2025-2050{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2050)}
{p_end}

{pstd}{bf:Ejemplo 2}: Proyección a nivel nacional hasta 2070{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2070)}
{p_end}

{pstd}{bf:Ejemplo 3}: Filtrar por entidad federativa (Jalisco){p_end}
{phang2}{cmd:. Poblacion if entidad == "Jalisco", anioinicial(2025) aniofinal(2050)}
{p_end}

{pstd}{bf:Ejemplo 4}: Filtrar solo hombres en CDMX{p_end}
{phang2}{cmd:. Poblacion if entidad == "Ciudad de México" & sexo == 1, anioinicial(2025) aniofinal(2050)}
{p_end}

{pstd}{bf:Ejemplo 5}: Actualizar datos de CONAPO sin gráficas{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2070) update nographs}
{p_end}

{pstd}{bf:Ejemplo 6}: Análisis histórico desde 1990{p_end}
{phang2}{cmd:. Poblacion, anioinicial(1990) aniofinal(2025)}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando genera una base de datos con:
{p_end}

{phang2}- {bf:anio}: Año de la observación{p_end}
{phang2}- {bf:edad}: Edad simple (0-109){p_end}
{phang2}- {bf:sexo}: 1=Hombres, 2=Mujeres{p_end}
{phang2}- {bf:entidad}: Entidad federativa o "Nacional"{p_end}
{phang2}- {bf:poblacion}: Población a mitad de año{p_end}
{phang2}- {bf:defunciones}: Defunciones estimadas{p_end}
{phang2}- {bf:emigrantes}: Emigrantes internacionales{p_end}
{phang2}- {bf:inmigrantes}: Inmigrantes internacionales{p_end}
{phang2}- {bf:tasafecundidad}: Tasa de fecundidad{p_end}

{pstd}
Gráficas generadas:
{p_end}

{phang2}- Pirámides poblacionales comparativas{p_end}
{phang2}- Transición demográfica (distribución por grupos de edad){p_end}
{phang2}- Tasa de dependencia (dependientes por cada 100 personas en edad laboral){p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Proyecciones de Población CONAPO 2020-2070:} {browse "https://www.gob.mx/conapo"}
{p_end}

{pstd}
2. {bf:Datos Abiertos CONAPO:} {browse "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/"}
{p_end}

{pstd}
3. {bf:Conciliación Demográfica 1950-2019:} {browse "https://www.gob.mx/conapo/documentos/bases-de-datos-de-la-conciliacion-demografica-1950-a-2019-y-proyecciones-de-la-poblacion-de-mexico-2020-a-2070"}
{p_end}

{title:See Also}

{pstd}
{help PIBDeflactor}, {help SCN}, {help LIF}, {help PEF}
{p_end}

{smcl_end}
