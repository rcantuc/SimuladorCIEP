{smcl}
{* *! version 3.0 CIEP 23feb2026}{...}
{viewerjumpto "Descripción" "TasasEfectivas##description"}{...}
{viewerjumpto "Primeros pasos" "TasasEfectivas##quickstart"}{...}
{viewerjumpto "Sintaxis" "TasasEfectivas##syntax"}{...}
{viewerjumpto "Opciones" "TasasEfectivas##options"}{...}
{viewerjumpto "Ejemplos" "TasasEfectivas##examples"}{...}
{viewerjumpto "Resultados" "TasasEfectivas##output"}{...}
{viewerjumpto "Scalars generados" "TasasEfectivas##scalars"}{...}
{viewerjumpto "Referencias" "TasasEfectivas##references"}{...}

{title:TasasEfectivas — Tasas efectivas de tributación por tipo de ingreso}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:TasasEfectivas} calcula las {bf:tasas efectivas de tributación} para México,
comparando la recaudación observada con las bases imponibles del
{bf:Sistema de Cuentas Nacionales (SCN)}.
{p_end}

{pstd}
{bf:¿Qué es una tasa efectiva?} Es el cociente entre lo que el gobierno
{it:realmente recauda} y la base económica sobre la que recae ese impuesto.
Por ejemplo, si el ISR de asalariados recauda 3% del PIB y las remuneraciones
representan 30% del PIB, la tasa efectiva sobre el trabajo asalariado es 10%.
{p_end}

{pstd}
El comando calcula tasas efectivas para cuatro categorías:
{p_end}

{phang2}{bf:A. Trabajo} — ISR asalariados, ISR personas físicas, cuotas IMSS{p_end}
{phang2}{bf:B. Capital privado} — ISR personas morales, otros ingresos de capital, FMP{p_end}
{phang2}{bf:C. Organismos y empresas} — Pemex, CFE, IMSS, ISSSTE{p_end}
{phang2}{bf:D. Consumo} — IVA, ISAN, IEPS (petrolero y no petrolero), importaciones{p_end}

{pstd}
Internamente ejecuta {view "06_helps/SCN.sthlp":SCN} y {view "06_helps/LIF.sthlp":LIF}
para obtener las bases macroeconómicas y la recaudación observada.
{p_end}

{hline}

{marker quickstart}{...}
{title:Primeros pasos}

{pstd}
Para calcular las tasas efectivas del año en curso:
{p_end}

{phang2}{cmd:. TasasEfectivas}{p_end}

{pstd}
Para un año específico:
{p_end}

{phang2}{cmd:. TasasEfectivas, anio(2025)}{p_end}

{hline}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:TasasEfectivas} [{cmd:,} {opt ANIO(#)} {opt NOGraphs} {opt CRECSIM(#)} {opt EOFP} {opt ENIGH}]
{p_end}

{hline}

{marker options}{...}
{title:Opciones}

{phang}
{opt anio(#)} — {bf:Año de análisis.} Por defecto usa el año de valor presente
({cmd:aniovp}) definido en el {cmd:profile.do}.
{p_end}

{phang}
{opt nographs} — Suprime la generación de gráficas.
{p_end}

{phang}
{opt crecsim(#)} — {bf:Factor de crecimiento simulado.} Multiplica las bases
imponibles por este factor para simular escenarios alternativos de crecimiento
económico. Por defecto: 1 (sin simulación).
{p_end}

{phang}
{opt eofp} — Usa datos de las {bf:Estadísticas Oportunas de Finanzas Públicas}
(datos observados) en lugar de proyecciones. Útil para años con datos completos.
{p_end}

{phang}
{opt enigh} — Genera una base de datos a nivel de individuo (ENIGH) con la
distribución simulada de la carga fiscal por decil de ingreso.
{p_end}

{hline}

{marker examples}{...}
{title:Ejemplos}

{pstd}{bf:Ejemplo 1 — Tasas efectivas del año en curso}{p_end}
{phang2}{cmd:. TasasEfectivas}{p_end}

{pstd}{bf:Ejemplo 2 — Año específico}{p_end}
{phang2}{cmd:. TasasEfectivas, anio(2025)}{p_end}

{pstd}{bf:Ejemplo 3 — Sin gráficas (solo scalars)}{p_end}
{phang2}{cmd:. TasasEfectivas, anio(2025) nographs}{p_end}
{pstd}Útil cuando solo necesitas los scalars para otro análisis.{p_end}

{pstd}{bf:Ejemplo 4 — Con datos observados (sin proyección)}{p_end}
{phang2}{cmd:. TasasEfectivas, anio(2024) eofp}{p_end}
{pstd}Usa la recaudación observada de las Estadísticas Oportunas.{p_end}

{pstd}{bf:Ejemplo 5 — Distribución por decil de ingreso}{p_end}
{phang2}{cmd:. TasasEfectivas, anio(2025) enigh}{p_end}
{pstd}Genera una base ENIGH con la carga fiscal asignada a cada individuo.{p_end}

{pstd}{bf:Ejemplo 6 — Simular escenario de mayor crecimiento}{p_end}
{phang2}{cmd:. TasasEfectivas, anio(2025) crecsim(1.05)}{p_end}
{pstd}Simula las tasas efectivas si la economía creciera 5% adicional.{p_end}

{hline}

{marker output}{...}
{title:Resultados}

{pstd}
Al ejecutar el comando obtienes cuatro tablas en pantalla y una gráfica:
{p_end}

{phang2}{bf:Tabla A — Impuestos al trabajo:}
Base = remuneraciones de asalariados + ingreso mixto laboral.
Impuestos: ISR asalariados, ISR personas físicas, cuotas IMSS.{p_end}

{phang2}{bf:Tabla B — Impuestos al capital privado:}
Base = excedente de operación + ingreso mixto de capital.
Impuestos: ISR personas morales, otros ingresos de capital, FMP.{p_end}

{phang2}{bf:Tabla C — Organismos y empresas del Estado:}
Base = ingresos propios de Pemex, CFE, IMSS, ISSSTE.{p_end}

{phang2}{bf:Tabla D — Impuestos al consumo:}
Base = consumo privado de hogares.
Impuestos: IVA, ISAN, IEPS petrolero, IEPS no petrolero, importaciones.{p_end}

{pstd}
Cada tabla muestra para cada impuesto: monto recaudado (millones MXN),
% del PIB, base imponible (% del PIB) y {bf:tasa efectiva} (%).
{p_end}

{hline}

{marker scalars}{...}
{title:Scalars generados}

{pstd}
Los scalars se guardan con el sufijo {bf:TE} (Tasa Efectiva) y {bf:PIB} (% del PIB):
{p_end}

{phang2}{bf:ISRASTE} — Tasa efectiva ISR asalariados (%){p_end}
{phang2}{bf:ISRPFTE} — Tasa efectiva ISR personas físicas (%){p_end}
{phang2}{bf:CUOTASTE} — Tasa efectiva cuotas IMSS (%){p_end}
{phang2}{bf:ISRPMTE} — Tasa efectiva ISR personas morales (%){p_end}
{phang2}{bf:IVATE} — Tasa efectiva IVA (%){p_end}
{phang2}{bf:IEPSNPTE} — Tasa efectiva IEPS no petrolero (%){p_end}
{phang2}{bf:IEPSPTE} — Tasa efectiva IEPS petrolero (%){p_end}
{phang2}{bf:ISRASPIB}, {bf:ISRPFPIB}, etc. — Recaudación como % del PIB{p_end}

{hline}

{marker references}{...}
{title:Referencias}

{pstd}
1. {bf:INEGI — Sistema de Cuentas Nacionales:}
{browse "https://www.inegi.org.mx/temas/pib/"}
{p_end}

{pstd}
2. {bf:SHCP — Estadísticas Oportunas de Finanzas Públicas:}
{browse "http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp"}
{p_end}

{pstd}
3. {bf:INEGI — Cuentas por Sectores Institucionales:}
{browse "https://www.inegi.org.mx/temas/si/#tabulados"}
{p_end}

{title:Ver también}

{pstd}
{view "06_helps/SCN.sthlp":SCN} {c |}
{view "06_helps/LIF.sthlp":LIF} {c |}
{view "06_helps/GastoPC.sthlp":GastoPC} {c |}
{view "06_helps/PIBDeflactor.sthlp":PIBDeflactor}
{p_end}

{smcl_end}
