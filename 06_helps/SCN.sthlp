{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "SCN##description"}{...}
{viewerjumpto "Primeros pasos" "SCN##quickstart"}{...}
{viewerjumpto "Sintaxis" "SCN##syntax"}{...}
{viewerjumpto "Opciones" "SCN##options"}{...}
{viewerjumpto "Ejemplos" "SCN##examples"}{...}
{viewerjumpto "Resultados" "SCN##output"}{...}
{viewerjumpto "Variables y scalars" "SCN##variables"}{...}
{viewerjumpto "Referencias" "SCN##references"}{...}

{title:SCN — Sistema de Cuentas Nacionales de México (INEGI)}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:SCN} descarga, procesa y proyecta el {bf:Sistema de Cuentas Nacionales (SCN)} de México,
integrando dos fuentes oficiales del INEGI:
{p_end}

{phang2}1. {bf:BIE (Banco de Información Económica)} — Ingreso, producción bruta, consumo
de hogares, gasto de gobierno y PIB por actividad económica{p_end}
{phang2}2. {bf:CSI (Cuentas por Sectores Institucionales)} — Ingreso mixto bruto, cuotas de
seguridad social, subsidios y excedentes de operación{p_end}

{pstd}
{bf:¿Para qué sirve?} Permite descomponer el PIB por sus tres métodos de cálculo
(producción, ingreso y gasto) y obtener la distribución funcional del ingreso entre
{bf:trabajo}, {bf:capital} y {bf:depreciación}. Esta información es insumo clave para
{cmd:TasasEfectivas} y {cmd:GastoPC}.
{p_end}

{pstd}
La base de datos cubre de {bf:1993 a 2070}, combinando datos históricos observados
con proyecciones basadas en las tasas de crecimiento del PIB definidas en el {cmd:profile.do}.
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para obtener las cuentas nacionales del año en curso:
{p_end}

{phang2}{cmd:. SCN}{p_end}

{pstd}
Para un año específico:
{p_end}

{phang2}{cmd:. SCN, anio(2025)}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:SCN} [{cmd:,} {opt ANIO(#)} {opt ANIOMax(#)} {opt NOGraphs} {opt UPDATE} {opt TEXTbook}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt anio(#)} — {bf:Año de referencia} para el análisis. Rango: 1993–año actual.
Por defecto usa el año del paquete económico ({cmd:anioPE}).
{p_end}

{phang}
{opt aniomax(#)} — {bf:Año final} hasta el que se extiende la proyección en las gráficas.
Por defecto: 2070.
{p_end}

{phang}
{opt nographs} — Suprime la generación de gráficas. Útil cuando solo necesitas
los scalars para otro análisis (como {cmd:TasasEfectivas}).
{p_end}

{phang}
{opt update} — Descarga los datos más recientes del BIE/INEGI y las CSI.
Requiere conexión a internet.
{p_end}

{phang}
{opt textbook} — Genera gráficas sin títulos ni fuentes, para publicaciones.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Cuentas nacionales del año en curso}{p_end}
{phang2}{cmd:. SCN}{p_end}

{pstd}{bf:Ejemplo 2 — Año específico}{p_end}
{phang2}{cmd:. SCN, anio(2025)}{p_end}

{pstd}{bf:Ejemplo 3 — Sin gráficas (solo scalars)}{p_end}
{phang2}{cmd:. SCN, anio(2025) nographs}{p_end}
{pstd}Útil como paso previo a {cmd:TasasEfectivas}.{p_end}

{pstd}{bf:Ejemplo 4 — Actualizar datos del INEGI}{p_end}
{phang2}{cmd:. SCN, update nographs}{p_end}

{pstd}{bf:Ejemplo 5 — Proyección hasta 2031}{p_end}
{phang2}{cmd:. SCN, anio(2025) aniomax(2031)}{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes ocho tablas en pantalla, dos gráficas y una base de datos:
{p_end}

{pstd}{bf:Tablas (método de producción):}{p_end}
{phang2}{bf:A. Cuenta de producción bruta} — Producción bruta, consumo intermedio, valor
agregado, impuestos a productos y PIB{p_end}
{phang2}{bf:G. Cuenta de actividad económica} — PIB desagregado por sector productivo
(agricultura, manufactura, comercio, servicios, etc.){p_end}

{pstd}{bf:Tablas (método de ingreso):}{p_end}
{phang2}{bf:B1. Distribución del ingreso} — Remuneraciones de asalariados, ingreso mixto
laboral, ingresos de capital, depreciación y PIN{p_end}
{phang2}{bf:B2. Ingresos de capital} — Excedente de operación, ingreso mixto de capital,
alquiler imputado e impuestos netos{p_end}
{phang2}{bf:C. Distribución secundaria} — Transformación del PIB en ingreso nacional
disponible (transferencias del exterior){p_end}

{pstd}{bf:Tablas (método de gasto):}{p_end}
{phang2}{bf:D. Utilización del ingreso} — Consumo de hogares, consumo de gobierno,
ahorro bruto e inversión{p_end}
{phang2}{bf:E. Consumo de hogares} — Desglose por categoría: alimentos, vivienda,
transporte, salud, educación, recreación, etc.{p_end}
{phang2}{bf:F. Consumo de gobierno} — Distribución del gasto público por sector{p_end}

{pstd}{bf:Gráficas:}{p_end}
{phang2}— PIB por método de distribución del ingreso (trabajo, capital, depreciación){p_end}
{phang2}— PIB por método de utilización (consumo, inversión, gobierno, exportaciones netas){p_end}

{pstd}{bf:Archivos guardados:}{p_end}
{phang2}— {cmd:04_master/SCN.dta} — Base completa 1993–2070{p_end}
{phang2}— Gráficos PNG en {cmd:users/$id/graphs/}{p_end}

{hline}

{marker variables}{...}
{title:Variables y scalars generados}

{pstd}{bf:Variables principales:}{p_end}

{phang2}{bf:anio} — Año{p_end}
{phang2}{bf:PIB} — Producto Interno Bruto nominal{p_end}
{phang2}{bf:RemSal} — Remuneraciones de asalariados (excluye seguridad social){p_end}
{phang2}{bf:RemSalSS} — Remuneraciones totales (incluye seguridad social){p_end}
{phang2}{bf:MixL} — Ingreso mixto laboral (2/3 del ingreso mixto neto){p_end}
{phang2}{bf:MixK} — Ingreso mixto de capital (1/3 + depreciación){p_end}
{phang2}{bf:Yl} — Ingreso laboral total (RemSalSS + MixL){p_end}
{phang2}{bf:CapIncImp} — Ingreso de capital neto con impuestos{p_end}
{phang2}{bf:CapFij} — Consumo de capital fijo (depreciación){p_end}
{phang2}{bf:ConsPriv} — Consumo privado total{p_end}
{phang2}{bf:ConsGob} — Consumo de gobierno{p_end}

{pstd}{bf:Scalars generados} (en millones MXN y % del PIB):
{p_end}

{phang2}{bf:RemSalPIB} — Remuneraciones como % del PIB{p_end}
{phang2}{bf:YlPIB} — Ingreso laboral total como % del PIB{p_end}
{phang2}{bf:CapIncImpPIB} — Ingreso de capital como % del PIB{p_end}
{phang2}{bf:ConHogPIB} — Consumo de hogares como % del PIB{p_end}
{phang2}{bf:pibY} — PIB nominal del año de referencia{p_end}
{phang2}(y muchos más por cada componente de las cuentas){p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:INEGI — Banco de Información Económica:}
{browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:INEGI — Cuentas por Sectores Institucionales:}
{browse "https://www.inegi.org.mx/temas/si/#tabulados"}
{p_end}

{pstd}
3. {bf:INEGI — Sistema de Cuentas Nacionales de México:}
{browse "https://www.inegi.org.mx/temas/pib/"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor} {c |}
{view "06_helps/LIF.sthlp":LIF} {c |}
{view "06_helps/PEF.sthlp":PEF} {c |}
{view "06_helps/TasasEfectivas.sthlp":TasasEfectivas} {c |}
{view "06_helps/GastoPC.sthlp":GastoPC}
{p_end}

{smcl_end}
