{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog SCN "dialog SCN"}{...}
{vieweralsosee "[R] SCN" "mansection R SCN"}{...}
{viewerjumpto "Syntax" "SCN##syntax"}{...}
{viewerjumpto "Description" "SCN##description"}{...}
{viewerjumpto "Options" "SCN##options"}{...}
{viewerjumpto "Examples" "SCN##examples"}{...}
{viewerjumpto "Output" "SCN##output"}{...}
{viewerjumpto "References" "SCN##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:SCN} [, {opt ANIO(int)} {opt NOGraphs} {opt UPDATE} {opt TEXTBOOK}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:SCN} es un comando que automatiza la extracción y proyección de datos del Sistema de Cuentas Nacionales (SCN) del INEGI.
Utiliza dos fuentes de datos:
{p_end}

{pstd}
1. {bf:Banco de Indicadores (BIE):} Proporciona datos sobre el ingreso, la producción bruta, la cuenta de ingreso nacional disponible, el consumo de los hogares, el gasto de consumo privado, el gasto de consumo del gobierno y el PIB por actividad económica.
{p_end}

{pstd}
2. {bf:Cuentas por Sectores Institucionales (CSI):} Proporciona información sobre el ingreso mixto bruto, las cuotas a la seguridad social, los subsidios a los productos, la producción e importaciones y los excedentes de operación.
{p_end}

{pstd}
Además, el comando implementa un modelo de forecast para proyectar datos futuros, generando una base de datos integral del SCN que abarca desde 1993 hasta 2070.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anio(int)}    Especifica el año inicial de la proyección (rango: 1993–2069).
{p_end}

{phang}
{opt aniomax(int)} Define el año final para la proyección (rango: 1994–2070).
{p_end}

{phang}
{opt nographs}    Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}      Ejecuta un do‑file para actualizar la base de datos con los datos más recientes.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Ejemplo 1}: Análisis básico de cuentas nacionales 2024{p_end}
{phang2}{cmd:. SCN, anio(2024)}
{p_end}

{pstd}{bf:Ejemplo 2}: Actualizar datos del BIE{p_end}
{phang2}{cmd:. SCN, anio(2024) update}
{p_end}

{pstd}{bf:Ejemplo 3}: Análisis sin gráficas{p_end}
{phang2}{cmd:. SCN, anio(2024) nographs}
{p_end}

{pstd}{bf:Ejemplo 4}: Formato para publicación (sin títulos){p_end}
{phang2}{cmd:. SCN, anio(2024) textbook}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando despliega las siguientes cuentas:
{p_end}

{phang2}{bf:A. Cuenta de producción:} Producción bruta, consumo intermedio, valor agregado, impuestos a productos y PIB.{p_end}

{phang2}{bf:B.1. Distribución del ingreso:} Remuneraciones, contribuciones sociales, ingreso mixto laboral, impuestos a la producción (laborales), ingresos laborales totales, ingresos de capital, PIN y PIB.{p_end}

{phang2}{bf:B.2. Ingresos de capital:} Excedente de operación de sociedades, ingreso mixto de capital, alquiler imputado, gobierno, impuestos netos.{p_end}

{phang2}{bf:C. Distribución secundaria:} PIB, PIN, ingresos del resto del mundo (remuneraciones, propiedad, transferencias) e ingreso nacional disponible.{p_end}

{phang2}{bf:D. Utilización del ingreso:} Consumo de hogares, consumo de gobierno, compras netas, ahorro bruto.{p_end}

{phang2}{bf:E. Consumo de hogares:} Desglose por categoría (alimentos, vivienda, transporte, salud, educación, etc.).{p_end}

{pstd}
Gráficas generadas:
{p_end}

{phang2}- Distribución del ingreso (laborales, capital, depreciación){p_end}
{phang2}- Utilización del ingreso disponible{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Banco de Indicadores INEGI:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{pstd}
2. {bf:Cuentas por Sectores Institucionales:} {browse "https://www.inegi.org.mx/temas/si/#tabulados"}
{p_end}

{pstd}
3. {bf:Sistema de Cuentas Nacionales de México:} {browse "https://www.inegi.org.mx/temas/pib/"}
{p_end}

{title:See Also}

{pstd}
{help PIBDeflactor}, {help Poblacion}, {help LIF}, {help PEF}
{p_end}

{smcl_end}
