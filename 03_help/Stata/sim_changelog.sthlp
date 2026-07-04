{smcl}
{* *! version 8.0 CIEP 03jul2026}{...}
{viewerjumpto "Descripción" "sim_changelog##description"}{...}
{viewerjumpto "Primeros pasos" "sim_changelog##quickstart"}{...}
{viewerjumpto "Sintaxis" "sim_changelog##syntax"}{...}
{viewerjumpto "Opciones" "sim_changelog##options"}{...}
{viewerjumpto "Ejemplos" "sim_changelog##examples"}{...}
{viewerjumpto "Referencias" "sim_changelog##references"}{...}

{title:sim_changelog — Historial de cambios del Simulador Fiscal CIEP}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:sim_changelog} muestra en pantalla el {bf:historial completo de cambios} del
Simulador Fiscal CIEP, leyendo el archivo {cmd:CHANGELOG.md} de la Carpeta del Simulador.
{p_end}

{pstd}
{bf:¿En qué se diferencia del banner de bienvenida?} El banner que ves al abrir Stata
solo muestra las novedades acumuladas entre la última versión que usaste y la versión
actual. {cmd:sim_changelog} te da el historial completo, versión por versión, en
cualquier momento y sin reiniciar Stata.
{p_end}

{pstd}
{bf:¿Para qué sirve?} Para saber qué cambió entre versiones: comandos nuevos o
modificados, actualizaciones de datos (PEFs, LIFs, ENIGH), correcciones de bugs y
cambios institucionales (governance, arquitectura de publicación).
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para ver el historial completo:
{p_end}

{phang2}{cmd:. sim_changelog}{p_end}

{pstd}
Para ver solo los cambios de una versión específica:
{p_end}

{phang2}{cmd:. sim_changelog, version(v8.0)}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:sim_changelog} [{cmd:,} {opt VERsion(str)}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt version(str)} — Muestra únicamente la entrada de esa versión. Acepta el nombre
con o sin la {it:v} inicial: {cmd:version(v8.0)} y {cmd:version(8.0)} son equivalentes.
Si la versión no existe en el CHANGELOG, el comando termina con error 198 y te sugiere
correr {cmd:sim_changelog} sin opciones para ver las versiones disponibles.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Historial completo}{p_end}
{phang2}{cmd:. sim_changelog}{p_end}
{pstd}Muestra todas las versiones publicadas, de la más reciente a la más antigua.{p_end}

{pstd}{bf:Ejemplo 2 — Una versión específica}{p_end}
{phang2}{cmd:. sim_changelog, version(v8.0)}{p_end}

{pstd}{bf:Ejemplo 3 — Sin la v inicial}{p_end}
{phang2}{cmd:. sim_changelog, version(7.0)}{p_end}
{pstd}Equivale a {cmd:version(v7.0)}.{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:CHANGELOG.md} — Registro de cambios por versión, en {cmd:02_governance/} de la Carpeta del Simulador.
{p_end}

{pstd}
2. {bf:Convenciones de versionado:} {cmd:02_governance/convenciones-git.md} §3 — cuándo una
versión es mayor, menor o de corrección.
{p_end}

{title:Ver también}

{pstd}
{view "help/Stata/LIF.sthlp":LIF} {c |}
{view "help/Stata/PEF.sthlp":PEF} {c |}
{view "help/Stata/SHRFSP.sthlp":SHRFSP} {c |}
{view "help/Stata/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "help/Stata/DatosAbiertos.sthlp":DatosAbiertos}
{p_end}

{smcl_end}
