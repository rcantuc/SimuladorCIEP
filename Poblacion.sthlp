{smcl}
{* *! version 1.  22mar2025}{...}
{viewerdialog Poblacion "dialog Poblacion"}{...}
{vieweralsosee "[R] Poblacion" "mansection R Poblacion"}{...}
{viewerjumpto "Syntax" "Poblacion##syntax"}{...}
{viewerjumpto "Description" "Poblacion##description"}{...}
{viewerjumpto "Options" "Poblacion##options"}{...}
{viewerjumpto "Examples" "Poblacion##examples"}{...}
{viewerjumpto "References" "Poblacion##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt poblacion} [if] [, ANIOinicial(int) ANIOFinal(int) NOGraphs UPDATE]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:poblacion} es un comando que automatiza la extracción de datos de las Proyecciones de la Población de México, utilizando información proveniente del CONAPO.  
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
{pstd}Ejemplo 1: Uso básico sin filtros{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2050)}
{p_end}

{pstd}Ejemplo 2: Uso con filtros y actualización de datos{p_end}
{phang2}{cmd:. Poblacion if entidad == "Jalisco" & sexo == 1, anioinicial(2020) aniofinal(2070) update}
{p_end}

{pstd}Ejemplo 3: Sin generación de gráficas{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2010) aniofinal(2070) nographs}
{p_end}

{marker references}{...}
{title:References}
{pstd}
1. Bases de Datos CONAPO: {browse "https://www.gob.mx/conapo/documentos/bases-de-datos-de-la-conciliacion-demografica-1950-a-2019-y-proyecciones-de-la-poblacion-de-mexico-2020-a-2070"}
{p_end}

{smcl_end}
