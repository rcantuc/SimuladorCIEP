{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "GastoPC##description"}{...}
{viewerjumpto "Primeros pasos" "GastoPC##quickstart"}{...}
{viewerjumpto "Sintaxis" "GastoPC##syntax"}{...}
{viewerjumpto "Componentes disponibles" "GastoPC##components"}{...}
{viewerjumpto "Opciones" "GastoPC##options"}{...}
{viewerjumpto "Ejemplos" "GastoPC##examples"}{...}
{viewerjumpto "Resultados" "GastoPC##output"}{...}
{viewerjumpto "Scalars generados" "GastoPC##scalars"}{...}
{viewerjumpto "Referencias" "GastoPC##references"}{...}

{title:GastoPC — Gasto público per cápita por función}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:GastoPC} calcula el {bf:gasto público per cápita} por función (educación, salud,
pensiones, energía, infraestructura y otros), distribuyéndolo entre los individuos
de la {bf:ENIGH} según sus características socioeconómicas.
{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite responder preguntas como: ¿cuánto gasta el gobierno
en educación por alumno?, ¿cuánto recibe en promedio un pensionado del IMSS?,
¿cómo se distribuye el gasto en salud entre deciles de ingreso?
{p_end}

{pstd}
El comando integra tres fuentes:
{p_end}

{phang2}1. {bf:PEF (SHCP)} — Montos presupuestados por ramo y función{p_end}
{phang2}2. {bf:ENIGH (INEGI)} — Características de los beneficiarios (alumnos, asegurados, pensionados){p_end}
{phang2}3. {bf:PIBDeflactor (INEGI)} — Deflactor para expresar montos en pesos constantes{p_end}

{pstd}
{bf:Metodología:} El gasto total de cada función se divide entre el número de
beneficiarios identificados en la ENIGH, asignando a cada individuo el monto
per cápita correspondiente según su condición (ej. si asiste a la escuela,
si tiene seguro médico, si recibe pensión).
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para calcular el gasto per cápita en todas las funciones:
{p_end}

{phang2}{cmd:. GastoPC}{p_end}

{pstd}
Para calcular solo educación y salud:
{p_end}

{phang2}{cmd:. GastoPC educacion salud}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:GastoPC} [{it:componentes}] [{cmd:,} {opt ANIOVP(#)} {opt ANIOpe(#)} {opt EXCEL}]
{p_end}

{pstd}
Si no se especifica ningún componente, se calculan todos.
{p_end}

{hline}

{marker components}{...}
{title:Componentes disponibles}

{pstd}
Puedes especificar uno o más de los siguientes componentes:
{p_end}

{phang2}{bf:educacion} — Gasto en educación por nivel{p_end}
{phang2}{bf:salud} — Gasto en salud por institución{p_end}
{phang2}{bf:pensiones} — Gasto en pensiones y jubilaciones{p_end}
{phang2}{bf:energia} — Subsidios y gasto en energía (CFE, Pemex){p_end}
{phang2}{bf:infraestructura} — Inversión en infraestructura pública{p_end}
{phang2}{bf:otrosgastos} — Otros gastos públicos no clasificados{p_end}

{pstd}
{bf:Desglose de educación:}
{p_end}
{phang2}Inicial, básica, media superior, superior, posgrado, educación para adultos,
inversión educativa, cultura y ciencia y tecnología{p_end}

{pstd}
{bf:Desglose de salud:}
{p_end}
{phang2}SSa, IMSS-Bienestar, IMSS, ISSSTE, Pemex, ISSFAM, inversión en salud{p_end}

{pstd}
{bf:Desglose de pensiones:}
{p_end}
{phang2}Pensión para el Bienestar (adultos mayores), IMSS, ISSSTE, Pemex, otras pensiones{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt aniovp(#)} — {bf:Año de valor presente.} Año base para expresar los montos
en pesos constantes. Por defecto usa el escalar {cmd:aniovp} del {cmd:profile.do}.
{p_end}

{phang}
{opt aniope(#)} — {bf:Año del paquete económico.} Año del presupuesto de referencia.
Por defecto usa el escalar {cmd:anioPE} del {cmd:profile.do}.
{p_end}

{phang}
{opt excel} — Exporta los resultados a un archivo Excel ({cmd:Deciles.xlsx})
con el gasto per cápita por decil de ingreso para cada función.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Gasto per cápita completo}{p_end}
{phang2}{cmd:. GastoPC}{p_end}
{pstd}Calcula el gasto per cápita en todas las funciones para el año en curso.{p_end}

{pstd}{bf:Ejemplo 2 — Solo educación}{p_end}
{phang2}{cmd:. GastoPC educacion}{p_end}
{pstd}Muestra el gasto por alumno en cada nivel educativo.{p_end}

{pstd}{bf:Ejemplo 3 — Educación y salud}{p_end}
{phang2}{cmd:. GastoPC educacion salud}{p_end}

{pstd}{bf:Ejemplo 4 — Año específico}{p_end}
{phang2}{cmd:. GastoPC educacion salud, aniope(2025)}{p_end}

{pstd}{bf:Ejemplo 5 — Exportar a Excel por deciles}{p_end}
{phang2}{cmd:. GastoPC, excel}{p_end}
{pstd}Genera {cmd:Deciles.xlsx} con el gasto per cápita por decil de ingreso.{p_end}

{pstd}{bf:Ejemplo 6 — Solo pensiones}{p_end}
{phang2}{cmd:. GastoPC pensiones}{p_end}
{pstd}Muestra el gasto per cápita en pensiones por institución (IMSS, ISSSTE, etc.).{p_end}

{pstd}{bf:Ejemplo 7 — Año de valor presente personalizado}{p_end}
{phang2}{cmd:. GastoPC, aniovp(2024) aniope(2025)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Para cada componente solicitado, el comando muestra una tabla con:
{p_end}

{phang2}{bf:Beneficiarios} — Número de alumnos, asegurados o pensionados (en millones){p_end}
{phang2}{bf:% PIB} — Gasto total de esa función como % del PIB{p_end}
{phang2}{bf:PC (MXN)} — Gasto per cápita en pesos constantes del año de valor presente{p_end}

{pstd}
{bf:Variables generadas en la base de datos (ENIGH):}{p_end}
{phang2}{bf:Educacion} — Gasto per cápita en educación asignado a cada individuo{p_end}
{phang2}{bf:Salud} — Gasto per cápita en salud asignado a cada individuo{p_end}
{phang2}{bf:Pensiones} — Gasto per cápita en pensiones asignado a cada individuo{p_end}
{phang2}{bf:Energia} — Gasto per cápita en energía asignado a cada individuo{p_end}

{hline}

{marker scalars}{...}
{title:Scalars generados}

{pstd}{bf:Educación (por nivel):}{p_end}
{phang2}{bf:basicaPC} — Gasto per cápita educación básica{p_end}
{phang2}{bf:medsupPC} — Gasto per cápita educación media superior{p_end}
{phang2}{bf:superiPC} — Gasto per cápita educación superior{p_end}
{phang2}{bf:educacPIB} — Gasto total en educación como % del PIB{p_end}

{pstd}{bf:Salud (por institución):}{p_end}
{phang2}{bf:ssaPC} — Gasto per cápita SSa{p_end}
{phang2}{bf:imssPC} — Gasto per cápita IMSS{p_end}
{phang2}{bf:issstePC} — Gasto per cápita ISSSTE{p_end}
{phang2}{bf:saludPIB} — Gasto total en salud como % del PIB{p_end}

{pstd}{bf:Pensiones (por institución):}{p_end}
{phang2}{bf:bienestarPC} — Gasto per cápita Pensión para el Bienestar{p_end}
{phang2}{bf:imsspensPC} — Gasto per cápita pensiones IMSS{p_end}
{phang2}{bf:issstepenPC} — Gasto per cápita pensiones ISSSTE{p_end}
{phang2}{bf:pensionesPIB} — Gasto total en pensiones como % del PIB{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:SHCP — Presupuesto de Egresos de la Federación:}
{browse "https://www.ppef.hacienda.gob.mx/"}
{p_end}

{pstd}
2. {bf:INEGI — Encuesta Nacional de Ingresos y Gastos de los Hogares (ENIGH):}
{browse "https://www.inegi.org.mx/programas/enigh/nc/"}
{p_end}

{pstd}
3. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/PEF.sthlp":PEF} {c |}
{view "06_helps/TasasEfectivas.sthlp":TasasEfectivas} {c |}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "06_helps/Poblacion.sthlp":Poblacion}
{p_end}

{smcl_end}
