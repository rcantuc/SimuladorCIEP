{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "PEF##description"}{...}
{viewerjumpto "Primeros pasos" "PEF##quickstart"}{...}
{viewerjumpto "Sintaxis" "PEF##syntax"}{...}
{viewerjumpto "Opciones" "PEF##options"}{...}
{viewerjumpto "Clasificaciones" "PEF##classifications"}{...}
{viewerjumpto "Ejemplos" "PEF##examples"}{...}
{viewerjumpto "Resultados" "PEF##output"}{...}
{viewerjumpto "Variables y scalars" "PEF##variables"}{...}
{viewerjumpto "Referencias" "PEF##references"}{...}

{title:PEF — Presupuesto de Egresos de la Federación}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:PEF} descarga y analiza el {bf:gasto público federal}, combinando tres fuentes
con una jerarquía automática de prioridad:
{p_end}

{phang2}1. {bf:Cuenta Pública (SHCP)} — Gasto ejercido (más confiable, disponible con rezago){p_end}
{phang2}2. {bf:PEF aprobado} — Presupuesto aprobado por el Congreso{p_end}
{phang2}3. {bf:PPEF} — Proyecto de presupuesto del Ejecutivo{p_end}
{phang2}4. {bf:BIE (INEGI)} — PIB y deflactor para expresar valores como % del PIB{p_end}

{pstd}
El comando selecciona automáticamente la mejor fuente disponible para cada año:
primero el gasto ejercido, luego el aprobado, y finalmente el proyecto.
{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite consultar el gasto histórico desde 2013, comparar
su evolución entre años, analizar la composición del gasto por función (salud,
educación, pensiones, seguridad, etc.) y evaluar su relación con el PIB.
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para analizar el gasto del año en curso:
{p_end}

{phang2}{cmd:. PEF}{p_end}

{pstd}
Para un año específico comparando con los últimos 10 años:
{p_end}

{phang2}{cmd:. PEF, anio(2025)}{p_end}

{pstd}
Para ver el gasto por ramo presupuestario:
{p_end}

{phang2}{cmd:. PEF, anio(2025) by(ramo)}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:PEF} [{it:if}] [{cmd:,} {opt ANIO(#)} {opt DESDE(#)} {opt BY(varname)} {opt NOGraphs} {opt UPDATE} {opt Base} {opt MINimum(#)} {opt ROWS(#)} {opt COLS(#)} {opt HIGHlight(#)} {opt TITle(string)}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{dlgtab:Análisis}

{phang}
{opt anio(#)} — {bf:Año de análisis.} Rango: 2013–año actual.
Por defecto usa el año del paquete económico ({cmd:anioPE}).
{p_end}

{phang}
{opt desde(#)} — {bf:Año de comparación.} Punto de inicio para calcular tasas de
crecimiento real. Por defecto: 10 años antes del año de análisis.
{p_end}

{phang}
{opt by(varname)} — {bf:Variable de agrupación del gasto.} Opciones principales:
{p_end}
{phang2}{cmd:divCIEP} — Clasificación funcional CIEP (predeterminado): salud, educación, pensiones, etc.{p_end}
{phang2}{cmd:ramo} — Ramo presupuestario (IMSS, ISSSTE, PEMEX, SEDENA, etc.){p_end}
{phang2}{cmd:funcion} — Función de gobierno{p_end}
{phang2}{cmd:capitulo} — Capítulo de gasto (objeto del gasto){p_end}

{phang}
{opt nographs} — Suprime la generación de gráficas.
{p_end}

{phang}
{opt update} — Descarga los datos más recientes de la Cuenta Pública y el PEF.
Requiere conexión a internet.
{p_end}

{phang}
{opt base} — Descarga únicamente la base de datos sin cálculos adicionales.
Útil para análisis personalizados desde cero.
{p_end}

{dlgtab:Personalización de gráfica}

{phang}
{opt minimum(#)} — Porcentaje mínimo del PIB que un rubro debe alcanzar para
mostrarse individualmente. Los rubros menores se agrupan en "Otros".
Por defecto: 1.0. Aumenta para simplificar, reduce para más detalle.
{p_end}

{phang}
{opt rows(#)} — Número de filas en la leyenda de la gráfica.
{p_end}

{phang}
{opt cols(#)} — Número de columnas en la leyenda de la gráfica.
{p_end}

{phang}
{opt highlight(#)} — Resalta una categoría específica en la gráfica (por número de orden).
{p_end}

{phang}
{opt title(string)} — Título personalizado para la gráfica.
{p_end}

{hline}

{marker classifications}{...}
{title:Clasificaciones de gasto (divCIEP)}

{pstd}
La clasificación predeterminada agrupa el gasto en las siguientes categorías:
{p_end}

{phang2}{bf:Salud} — IMSS, ISSSTE, servicios de salud{p_end}
{phang2}{bf:Educación} — Educación básica, media superior y superior{p_end}
{phang2}{bf:Pensiones} — Jubilaciones y pensiones{p_end}
{phang2}{bf:Energía} — CFE, PEMEX, subsidios energéticos{p_end}
{phang2}{bf:Seguridad} — SEDENA, SEMAR, seguridad pública{p_end}
{phang2}{bf:Desarrollo social} — Programas sociales y combate a la pobreza{p_end}
{phang2}{bf:Infraestructura} — Transporte, comunicaciones, obra pública{p_end}
{phang2}{bf:Otros} — Funciones no clasificadas en las anteriores{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Análisis básico del año en curso}{p_end}
{phang2}{cmd:. PEF}{p_end}

{pstd}{bf:Ejemplo 2 — Año específico con comparación}{p_end}
{phang2}{cmd:. PEF, anio(2025) desde(2015)}{p_end}

{pstd}{bf:Ejemplo 3 — Por ramo presupuestario}{p_end}
{phang2}{cmd:. PEF, anio(2025) by(ramo) minimum(0.5)}{p_end}
{pstd}Muestra el gasto por dependencia (IMSS, ISSSTE, PEMEX, etc.).{p_end}

{pstd}{bf:Ejemplo 4 — Por función de gobierno}{p_end}
{phang2}{cmd:. PEF, anio(2025) by(funcion) minimum(1.0)}{p_end}

{pstd}{bf:Ejemplo 5 — Gráfica personalizada}{p_end}
{phang2}{cmd:. PEF, anio(2025) title("Gasto Social 2025") highlight(1) rows(2) cols(4)}{p_end}

{pstd}{bf:Ejemplo 6 — Solo datos sin gráficas}{p_end}
{phang2}{cmd:. PEF, anio(2025) nographs}{p_end}

{pstd}{bf:Ejemplo 7 — Actualizar datos y base cruda}{p_end}
{phang2}{cmd:. PEF, update base}{p_end}

{pstd}{bf:Ejemplo 8 — Filtrar período específico}{p_end}
{phang2}{cmd:. PEF if anio >= 2020 & anio <= 2025, by(divCIEP) minimum(2.0)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes tres tablas en pantalla, una gráfica y una base de datos:
{p_end}

{phang2}{bf:Tabla A — Gasto bruto:} Montos absolutos, % del PIB y % del gasto total
para el año de análisis{p_end}

{phang2}{bf:Tabla B — Gasto neto resumido:} Excluye transferencias intergubernamentales
(Ramos 28 y 33) para evitar doble contabilización. Incluye crecimiento real.{p_end}

{phang2}{bf:Tabla C — Cambios:} Diferencias en puntos porcentuales del PIB entre
el año de análisis y el año de comparación{p_end}

{pstd}{bf:Gráfica:} Composición del gasto público como % del PIB por año.{p_end}

{pstd}{bf:Archivos guardados:}{p_end}
{phang2}— {cmd:04_master/PEF.dta} — Base consolidada de gasto 2013–año actual{p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{hline}

{marker variables}{...}
{title:Variables y scalars generados}

{pstd}{bf:Variables en la base de datos:}{p_end}

{phang2}{bf:anio} — Año{p_end}
{phang2}{bf:ramo} — Número de ramo presupuestario{p_end}
{phang2}{bf:nombre_ramo} — Nombre del ramo{p_end}
{phang2}{bf:divCIEP} — Clasificación funcional CIEP{p_end}
{phang2}{bf:gasto} — Monto del gasto (ejercido > aprobado > proyecto){p_end}
{phang2}{bf:gastoPIB} — Gasto como % del PIB{p_end}
{phang2}{bf:gastoR} — Gasto en términos reales{p_end}
{phang2}{bf:ejercido} — Gasto ejercido (Cuenta Pública){p_end}
{phang2}{bf:aprobado} — Gasto aprobado (PEF){p_end}
{phang2}{bf:proyecto} — Proyecto de presupuesto (PPEF){p_end}
{phang2}{bf:transf_gf} — Indicador de transferencia intergubernamental{p_end}
{phang2}{bf:noprogramable} — Indicador de gasto no programable{p_end}

{pstd}{bf:Scalars r() principales:}{p_end}

{phang2}{bf:r(Gasto_bruto)} — Gasto bruto total del año{p_end}
{phang2}{bf:r(Salud)} — Gasto en salud{p_end}
{phang2}{bf:r(Educacion)} — Gasto en educación{p_end}
{phang2}{bf:r(Pensiones)} — Gasto en pensiones{p_end}
{phang2}{bf:r(Energia)} — Gasto en energía{p_end}
{phang2}{bf:r(Seguridad)} — Gasto en seguridad{p_end}
{phang2}{bf:r(rc)} — "NoData" si no hay información para el año solicitado{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:SHCP — Presupuesto de Egresos de la Federación:}
{browse "https://www.ppef.hacienda.gob.mx/"}
{p_end}

{pstd}
2. {bf:SHCP — Cuenta Pública:}
{browse "https://www.cuentapublica.hacienda.gob.mx/"}
{p_end}

{pstd}
3. {bf:SHCP — Transparencia Presupuestaria:}
{browse "https://www.transparenciapresupuestaria.gob.mx/Datos-Abiertos"}
{p_end}

{pstd}
4. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/LIF.sthlp":LIF} {c |}
{view "06_helps/SHRFSP.sthlp":SHRFSP} {c |}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "06_helps/DatosAbiertos.sthlp":DatosAbiertos} {c |}
{view "06_helps/GastoPC.sthlp":GastoPC}
{p_end}

{smcl_end}
