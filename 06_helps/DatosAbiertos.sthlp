{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog DatosAbiertos "dialog DatosAbiertos"}{...}
{vieweralsosee "[R] DatosAbiertos" "mansection R DatosAbiertos"}{...}
{viewerjumpto "Syntax" "DatosAbiertos##syntax"}{...}
{viewerjumpto "Description" "DatosAbiertos##description"}{...}
{viewerjumpto "Options" "DatosAbiertos##options"}{...}
{viewerjumpto "Examples" "DatosAbiertos##examples"}{...}
{viewerjumpto "Output" "DatosAbiertos##output"}{...}
{viewerjumpto "References" "DatosAbiertos##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:DatosAbiertos} {it:clave_de_concepto} [{it:if}] [, {opt PIBVP(real)} {opt PIBVF(real)} {opt DESDE(real)} {opt UPDATE} {opt NOGraphs} {opt REVERSE} {opt PROYeccion} {opt ZIPFILE} {opt CSVFILE} {opt FILES}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:DatosAbiertos} proporciona acceso estructurado a los datos de las {bf:Estadísticas Oportunas de Finanzas Públicas (EOFP)} de la SHCP, facilitando el análisis de series fiscales mensuales.
{p_end}

{pstd}
El comando descarga y procesa automáticamente las siguientes bases de datos de la SHCP:
{p_end}

{phang2}- Ingresos, gastos y financiamiento del sector público{p_end}
{phang2}- Deuda pública{p_end}
{phang2}- SHRFSP (Saldo Histórico de los RFSP){p_end}
{phang2}- RFSP (Requerimientos Financieros del Sector Público){p_end}
{phang2}- Transferencias a entidades federativas{p_end}

{pstd}
Además, integra información de otros comandos del Simulador:
{p_end}

{phang2}- {bf:Poblacion.ado}: Calcula valores per cápita{p_end}
{phang2}- {bf:PIBDeflactor.ado}: Calcula valores como % del PIB y deflacta a precios constantes{p_end}

{marker options}{...}
{title:Options}

{dlgtab:General}

{phang}
{opt DESDE(real)} Especifica el año inicial para comparaciones y gráficas. Valor por defecto: 2008.
{p_end}

{phang}
{opt UPDATE} Descarga los datos más recientes de la SHCP. Útil cuando hay nuevas publicaciones.
{p_end}

{phang}
{opt NOGraphs} Suprime la generación de gráficas.
{p_end}

{phang}
{opt REVERSE} Invierte el signo de los montos (útil para series de gasto que se reportan en negativo).
{p_end}

{phang}
{opt PROYeccion} Proyecta el monto anual basándose en la distribución mensual histórica cuando el año está incompleto.
{p_end}

{dlgtab:Fuente de datos}

{phang}
{opt ZIPFILE} Descarga los datos desde los archivos ZIP del portal de la SHCP (más rápido para actualizaciones completas).
{p_end}

{phang}
{opt CSVFILE} Descarga los datos directamente desde los archivos CSV en línea.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Ejemplo 1}: Consultar ISR (clave XAA10){p_end}
{phang2}{cmd:. DatosAbiertos XAA10}
{p_end}

{pstd}{bf:Ejemplo 2}: Consultar IVA desde 2010{p_end}
{phang2}{cmd:. DatosAbiertos XAA20, desde(2010)}
{p_end}

{pstd}{bf:Ejemplo 3}: Actualizar datos y consultar IEPS sin gráficas{p_end}
{phang2}{cmd:. DatosAbiertos XAA30, update nographs}
{p_end}

{pstd}{bf:Ejemplo 4}: Proyectar el gasto en educación para el año en curso{p_end}
{phang2}{cmd:. DatosAbiertos XED10, proyeccion}
{p_end}

{pstd}{bf:Ejemplo 5}: Consultar ingresos petroleros con proyección{p_end}
{phang2}{cmd:. DatosAbiertos XAC10, desde(2008) proyeccion}
{p_end}

{pstd}{bf:Ejemplo 6}: Solo cargar la base de datos completa (sin filtrar por clave){p_end}
{phang2}{cmd:. DatosAbiertos}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando genera las siguientes variables:
{p_end}

{phang2}- {bf:anio, mes, aniomes}: Identificadores temporales{p_end}
{phang2}- {bf:monto}: Valor nominal de la serie{p_end}
{phang2}- {bf:montomill}: Valor en millones de pesos constantes{p_end}
{phang2}- {bf:monto_pib}: Valor como porcentaje del PIB{p_end}
{phang2}- {bf:monto_pc}: Valor per cápita en pesos constantes{p_end}
{phang2}- {bf:acum_prom}: Proporción promedio mensual histórica{p_end}

{pstd}
También genera gráficas automáticas mostrando la evolución mensual y anual de la serie.
{p_end}

{title:Claves comunes}

{pstd}
Algunas claves frecuentemente utilizadas:
{p_end}

{phang2}- {bf:XAA10}: Impuesto sobre la renta (ISR){p_end}
{phang2}- {bf:XAA20}: Impuesto al valor agregado (IVA){p_end}
{phang2}- {bf:XAA30}: Impuesto especial sobre producción y servicios (IEPS){p_end}
{phang2}- {bf:XAC10}: Ingresos petroleros{p_end}
{phang2}- {bf:XED10}: Gasto en educación{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Estadísticas Oportunas de Finanzas Públicas:} {browse "https://www.finanzaspublicas.hacienda.gob.mx/es/Finanzas_Publicas/Estadisticas_Oportunas_de_Finanzas_Publicas"}
{p_end}

{pstd}
2. {bf:Datos Abiertos SHCP:} {browse "https://www.secciones.hacienda.gob.mx/es/siop/datos_abiertos"}
{p_end}

{pstd}
3. {bf:Banco de Indicadores INEGI:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{smcl_end}
