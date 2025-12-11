{smcl}
{* *! version 2.0 Ricardo Cantú 11dic2025}{...}
{viewerdialog PEF "dialog PEF"}{...}
{vieweralsosee "[R] PEF" "mansection R PEF"}{...}
{viewerjumpto "Syntax" "PEF##syntax"}{...}
{viewerjumpto "Description" "PEF##description"}{...}
{viewerjumpto "Options" "PEF##options"}{...}
{viewerjumpto "Examples" "PEF##examples"}{...}
{viewerjumpto "Output" "PEF##output"}{...}
{viewerjumpto "References" "PEF##references"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:PEF} [{it:if}] [, {opt ANIO(int)} {opt BY(varname)} {opt UPDATE} {opt NOGraphs} {opt Base} {opt MINimum(real)} {opt DESDE(int)} {opt PEF} {opt PPEF} {opt APROBado} {opt ROWS(int)} {opt COLS(int)} {opt HIGHlight(int)} {opt TITle(string)}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:PEF} es un comando diseñado para automatizar la extracción y el análisis de datos del {bf:Presupuesto de Egresos de la Federación (PEF)}.  
Este programa permite extraer y analizar automáticamente los datos oficiales del gasto público publicados por la {bf:SHCP} y utiliza datos del {bf:INEGI} para cálculos adicionales.
{p_end}

{pstd}
![TablaA](images/PEF/GastoPublico.png)
{p_end}

{pstd}
El comando procesa datos de tres fuentes:
  1. {bf:Cuenta Pública:} Contiene la distribución de los recursos públicos ejercidos en el gasto del gobierno federal.
  2. {bf:Presupuesto de Egresos de la Federación:} Documento que detalla la distribución de los recursos públicos aprobada para el gasto del gobierno federal, utilizado cuando la cuenta pública aún no ha sido publicada.
  3. {bf:BIE:} Proporciona datos sobre el PIB, el deflactor de precios, la inflación y el empleo.
{p_end}

{pstd}
El alcance del comando permite consultar el gasto histórico desde 2013 hasta el año actual, desglosando la distribución del gasto en salud, educación, seguridad y otros sectores, y evaluando su relación con el PIB.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:General}

{phang}
{opt anio(int)}    Especifica el {bf:Año Base} (por ejemplo, 2024).
{p_end}

{phang}
{opt desde(int)}   Especifica el {bf:Año de comparación} (por ejemplo, 2013).
{p_end}

{phang}
{opt nographs}    Suprime la generación de gráficas.
{p_end}

{phang}
{opt update}      Ejecuta un do‑file para obtener los datos más recientes.
{p_end}

{phang}
{opt base}        Permite descargar únicamente la base de datos sin aplicar cálculos adicionales.
{p_end}

{dlgtab:Graph Customization}

{phang}
{opt minimum(real)}  Define el {bf:Rango mínimo} del PIB que un concepto de gasto debe alcanzar para ser visualizado en la gráfica.
{p_end}

{phang}
{opt rows(int)}      Especifica el número de {bf:Filas} en la leyenda de la gráfica.
{p_end}

{phang}
{opt cols(int)}      Especifica el número de {bf:Columnas} en la leyenda de la gráfica.
{p_end}

{phang}
{opt title(string)}    Define el {bf:Título} de la gráfica.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Ejemplo 1}: Análisis básico del gasto público 2025{p_end}
{phang2}{cmd:. PEF, anio(2025)}
{p_end}

{pstd}{bf:Ejemplo 2}: Comparar gasto desde 2015{p_end}
{phang2}{cmd:. PEF, anio(2025) desde(2015)}
{p_end}

{pstd}{bf:Ejemplo 3}: Actualizar datos y generar análisis sin gráficas{p_end}
{phang2}{cmd:. PEF, anio(2025) update nographs}
{p_end}

{pstd}{bf:Ejemplo 4}: Personalizar gráfica con título{p_end}
{phang2}{cmd:. PEF, anio(2025) desde(2015) minimum(1) rows(2) cols(5) title("Gasto Público Federal")}
{p_end}

{pstd}{bf:Ejemplo 5}: Obtener solo la base de datos{p_end}
{phang2}{cmd:. PEF, base}
{p_end}

{pstd}{bf:Ejemplo 6}: Análisis por ramo administrativo{p_end}
{phang2}{cmd:. PEF, anio(2025) by(ramo)}
{p_end}

{pstd}{bf:Ejemplo 7}: Filtrar por ramo específico (Educación = ramo 11){p_end}
{phang2}{cmd:. PEF if ramo == 11, anio(2025)}
{p_end}

{pstd}{bf:Ejemplo 8}: Resaltar una categoría específica en la gráfica{p_end}
{phang2}{cmd:. PEF, anio(2025) highlight(3)}
{p_end}

{marker output}{...}
{title:Output}

{pstd}
El comando muestra automáticamente:
{p_end}

{phang2}- {bf:Sección A}: Gasto bruto por categoría con montos, % PIB y % del total{p_end}
{phang2}- {bf:Sección B}: Gasto resumido descontando cuotas ISSSTE y aportaciones{p_end}
{phang2}- {bf:Sección C}: Cambios en puntos porcentuales del PIB entre años{p_end}

{pstd}
Variables generadas:
{p_end}

{phang2}- {bf:gasto}: Monto del gasto ejercido{p_end}
{phang2}- {bf:gastoPIB}: Gasto como % del PIB{p_end}
{phang2}- {bf:gastoR}: Gasto en términos reales{p_end}
{phang2}- {bf:gastoTOT}: Gasto total del año{p_end}

{marker references}{...}
{title:References}

{pstd}
1. {bf:Presupuesto de Egresos de la Federación:} {browse "https://www.ppef.hacienda.gob.mx/"}
{p_end}

{pstd}
2. {bf:Cuenta Pública:} {browse "https://www.cuentapublica.hacienda.gob.mx/"}
{p_end}

{pstd}
3. {bf:Transparencia Presupuestaria:} {browse "https://www.transparenciapresupuestaria.gob.mx/Datos-Abiertos"}
{p_end}

{pstd}
4. {bf:Banco de Indicadores INEGI:} {browse "https://www.inegi.org.mx/app/indicadores/"}
{p_end}

{title:See Also}

{pstd}
{help LIF}, {help DatosAbiertos}, {help PIBDeflactor}, {help SHRFSP}
{p_end}

{smcl_end}
