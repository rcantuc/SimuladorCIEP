{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "Poblacion##description"}{...}
{viewerjumpto "Primeros pasos" "Poblacion##quickstart"}{...}
{viewerjumpto "Sintaxis" "Poblacion##syntax"}{...}
{viewerjumpto "Opciones" "Poblacion##options"}{...}
{viewerjumpto "Ejemplos" "Poblacion##examples"}{...}
{viewerjumpto "Resultados" "Poblacion##output"}{...}
{viewerjumpto "Variables y scalars" "Poblacion##variables"}{...}
{viewerjumpto "Referencias" "Poblacion##references"}{...}

{title:Poblacion — Proyecciones demográficas de México (CONAPO)}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:Poblacion} descarga y procesa automáticamente las proyecciones demográficas del
{bf:Consejo Nacional de Población (CONAPO)}, integrando tres bases de datos oficiales:
{p_end}

{phang2}1. {bf:Población} — Estimación de habitantes a mitad de cada año (1950–2070){p_end}
{phang2}2. {bf:Defunciones} — Estimación de defunciones anuales (1950–2070){p_end}
{phang2}3. {bf:Migración Internacional} — Inmigrantes y emigrantes (1950–2069){p_end}

{pstd}
El resultado es una base de datos unificada con información histórica y proyecciones
desagregadas por {bf:entidad federativa}, {bf:sexo}, {bf:edad} y {bf:año}.
{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite analizar la transición demográfica de México, comparar
pirámides poblacionales entre años, calcular tasas de dependencia y obtener proyecciones
de población para cualquier entidad del país.
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Si es tu primera vez usando este comando, ejecuta lo siguiente para obtener
la proyección nacional 2025–2050:
{p_end}

{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2050)}{p_end}

{pstd}
Esto generará automáticamente la base de datos, las gráficas y los scalars
con totales poblacionales. Si quieres actualizar los datos del CONAPO antes
de correr el análisis, agrega la opción {opt update}:
{p_end}

{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2050) update}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:Poblacion} [{it:if}] [{cmd:,} {opt ANIOinicial(#)} {opt ANIOFinal(#)} {opt NOGraphs} {opt UPDATE} {opt TEXTBOOK}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{dlgtab:Rango temporal}

{phang}
{opt anioinicial(#)} — Año de inicio del análisis. Rango válido: 1950–2069.
Por defecto usa el año actual.
{p_end}

{phang}
{opt aniofinal(#)} — Año de cierre del análisis. Rango válido: 1951–2070.
Por defecto usa el año actual + 1.
{p_end}

{dlgtab:Filtros (condición if)}

{pstd}
Puedes filtrar los resultados usando la condición {it:if} con las siguientes variables:
{p_end}

{phang2}{bf:entidad} — Nombre de la entidad federativa (texto). Ejemplos: {cmd:"Jalisco"},
{cmd:"Ciudad de México"}, {cmd:"Nacional"}.{p_end}

{phang2}{bf:sexo} — Sexo: {cmd:1} = Hombres, {cmd:2} = Mujeres. Si se omite, se incluyen ambos.{p_end}

{dlgtab:Otras opciones}

{phang}
{opt nographs} — Suprime la generación de gráficas. Útil cuando solo necesitas
la base de datos o los scalars.
{p_end}

{phang}
{opt update} — Descarga los datos más recientes del CONAPO antes de ejecutar
el análisis. Requiere conexión a internet.
{p_end}

{phang}
{opt textbook} — Genera gráficas sin títulos ni fuentes, para uso en
publicaciones o presentaciones.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Proyección nacional básica}{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2050)}{p_end}
{pstd}Genera la proyección para toda la República Mexicana entre 2025 y 2050.{p_end}

{pstd}{bf:Ejemplo 2 — Proyección de largo plazo hasta 2070}{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2070)}{p_end}

{pstd}{bf:Ejemplo 3 — Filtrar por entidad federativa}{p_end}
{phang2}{cmd:. Poblacion if entidad == "Jalisco", anioinicial(2025) aniofinal(2050)}{p_end}
{pstd}Reemplaza {cmd:"Jalisco"} con cualquier entidad. Ver lista completa en {cmd:$entidadesL}.{p_end}

{pstd}{bf:Ejemplo 4 — Solo hombres en Ciudad de México}{p_end}
{phang2}{cmd:. Poblacion if entidad == "Ciudad de México" & sexo == 1, anioinicial(2025) aniofinal(2050)}{p_end}

{pstd}{bf:Ejemplo 5 — Análisis histórico}{p_end}
{phang2}{cmd:. Poblacion, anioinicial(1990) aniofinal(2025)}{p_end}
{pstd}Combina datos históricos (1990–2019) con proyecciones (2020–2025).{p_end}

{pstd}{bf:Ejemplo 6 — Actualizar datos y suprimir gráficas}{p_end}
{phang2}{cmd:. Poblacion, anioinicial(2025) aniofinal(2070) update nographs}{p_end}

{pstd}{bf:Ejemplo 7 — Solo mujeres a nivel nacional}{p_end}
{phang2}{cmd:. Poblacion if sexo == 2, anioinicial(2025) aniofinal(2060)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes tres elementos:
{p_end}

{phang2}{bf:1. Base de datos en memoria} — Lista para análisis inmediato en Stata.{p_end}
{phang2}{bf:2. Gráficas} — Pirámides demográficas y transición demográfica.{p_end}
{phang2}{bf:3. Scalars} — Totales poblacionales por entidad para uso en otros comandos.{p_end}

{pstd}{bf:Gráficas generadas:}{p_end}

{phang2}— {bf:Pirámides poblacionales comparativas} entre el año inicial y final{p_end}
{phang2}— {bf:Transición demográfica}: evolución de la distribución por grupos de edad (0–18, 19–65, 65+){p_end}
{phang2}— {bf:Tasa de dependencia}: dependientes por cada 100 personas en edad laboral{p_end}

{pstd}{bf:Archivos guardados:}{p_end}

{phang2}— {cmd:04_master/Poblacion.dta} — Base completa por edad, sexo, año y entidad{p_end}
{phang2}— {cmd:04_master/Poblaciontot.dta} — Base colapsada por año (totales nacionales){p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{hline}

{marker variables}{...}
{title:Variables y scalars generados}

{pstd}{bf:Variables en la base de datos:}{p_end}

{phang2}{bf:anio} — Año (1950–2070){p_end}
{phang2}{bf:sexo} — 1 = Hombres, 2 = Mujeres{p_end}
{phang2}{bf:edad} — Edad simple (0–109 años){p_end}
{phang2}{bf:entidad} — Entidad federativa o "Nacional"{p_end}
{phang2}{bf:poblacion} — Número de habitantes a mitad de año{p_end}
{phang2}{bf:defunciones} — Defunciones estimadas{p_end}
{phang2}{bf:emigrantes} — Emigrantes internacionales{p_end}
{phang2}{bf:inmigrantes} — Inmigrantes internacionales{p_end}
{phang2}{bf:tasafecundidad} — Nacimientos por cada mil mujeres (16–49 años){p_end}

{pstd}{bf:Scalars generados por entidad} (donde {it:Ent} es el código de entidad, ej. {cmd:Nac}, {cmd:Jal}):
{p_end}

{phang2}{bf:pobtot{it:Ent}} — Población total en año inicial{p_end}
{phang2}{bf:pobfin{it:Ent}} — Población total en año final{p_end}
{phang2}{bf:pobhomI{it:Ent}}, {bf:pobhomF{it:Ent}} — Población masculina inicial/final{p_end}
{phang2}{bf:pobmujI{it:Ent}}, {bf:pobmujF{it:Ent}} — Población femenina inicial/final{p_end}
{phang2}{bf:pobMenoresI{it:Ent}}, {bf:pobMenoresF{it:Ent}} — Población 0–17 años{p_end}
{phang2}{bf:pobPrimeI{it:Ent}}, {bf:pobPrimeF{it:Ent}} — Población 18–64 años{p_end}
{phang2}{bf:pobMayoresI{it:Ent}}, {bf:pobMayoresF{it:Ent}} — Población 65+ años{p_end}
{phang2}{bf:aniotdmin}, {bf:aniotdmax} — Años con menor y mayor tasa de dependencia{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:Proyecciones de Población CONAPO 2020–2070:}
{browse "https://www.gob.mx/conapo/documentos/bases-de-datos-de-la-conciliacion-demografica-1950-a-2019-y-proyecciones-de-la-poblacion-de-mexico-2020-a-2070"}
{p_end}

{pstd}
2. {bf:Datos Abiertos CONAPO:}
{browse "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/"}
{p_end}

{pstd}
3. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor} {c |} 
{view "06_helps/SCN.sthlp":SCN} {c |} 
{view "06_helps/LIF.sthlp":LIF} {c |} 
{view "06_helps/PEF.sthlp":PEF} {c |} 
{view "06_helps/DatosAbiertos.sthlp":DatosAbiertos}
{p_end}

{smcl_end}
