# Documentación del archivo SIM.do
El archivo SIM.do es un archivo do-file de Stata utilizado para simulaciones fiscales. Configura el entorno, define opciones globales, establece el directorio de trabajo basado en el usuario y ejecuta varias simulaciones.

## Configuración inicial
El archivo comienza ejecutando perfiles del sistema del archivo `profile.do`, el cual contiene configuraciones específicas del usuario.

## Opciones globales
Esta sección permite al usuario establecer varias opciones globales. Estas opciones incluyen:

- `nographs`: Suprime la generación de gráficos.
- `textbook`: Cambia el formato de los gráficos a LaTeX.
- `output`: Determina si se generan salidas para la web.
- `update`: Determina si se actualizan las diferentes bases utilizadas (toma mucho tiempo).

### 2.2. Directorio de trabajo
El directorio de trabajo donde se encuentran los archivos y las bases del Simulador. Se pueden establecer diferentes directorios para diferentes usuarios. 

Por ejemplo, al trabajar en múltiples computadoras, si el nombre de usuario es "ricardo", el directorio personal se establece en "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/". Si el nombre de usuario es "ciepmx", el directorio personal se establece en "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/". 

El comando `adopath ++PERSONAL` agrega el directorio personal a la ruta de búsqueda de archivos ado.

## 2. Marco Macro

El Marco Macro es la primera sección del script `SIM.do` y se encarga de establecer los parámetros y datos macroeconómicos que se utilizarán en las simulaciones.

### 2.1 Población

Esta subsección importa los datos de población por edad, sexo y entidad federativa para todos los años de interés. Los datos provienen de la CONAPO 2023. También genera gráficos de la pirámide y transición demográfica para el año de interés.

### 2.2 Economía

Esta subsección importa y procesa los datos económicos, incluyendo el PIB, el índice de precios implícitos, el INPC, la población y la población ocupada. Genera una base de datos con su deflactor y productividad laboral para todos los años. Los datos provienen del INEGI y BIE.

### 2.3 Sistema Fiscal

Esta subsección importa y procesa los datos del sistema fiscal, incluyendo los ingresos, gastos y deuda para todos los años. Los datos provienen de las LIFs (Leyes de Ingresos de la Federación), PEFs (Presupuestos de Egresos de la Federación) y SHRFSP (Sistema de Información de las Finanzas Públicas Estatales y Municipales).

### 2.4 Subnacionales

Esta subsección importa y procesa los datos de ingresos, gastos y deuda de los gobiernos subnacionales. Genera bases de datos con estos datos para todos los años y todas las entidades federativas.

### 2.5 Información de los Hogares

Esta subsección importa y procesa los datos de los hogares de la ENIGH del año especificado. Genera un archivo `households.dta` con estos datos.

### 2.6 Sankey

Esta subsección genera diagramas de Sankey para varios grupos de datos, incluyendo grupo de edad, sexo, decil, rural y escolaridad.

### 2.7 Perfiles del Paquete Económico

Esta subsección genera los perfiles del paquete económico para el año especificado.


### 2.8 Integración de módulos (Households + LIF + PEF)

Esta subsección integra los módulos de Households, LIF y PEF.

Inputs: Datos de Households, LIF y PEF.
Outputs: Tasas efectivas y gasto per cápita.

## 3. Ciclo de Vida

Esta sección calcula el ciclo de vida de los hogares.

### 3.1 Inputs

El archivo "`c(sysdir_site)'/users/$pais/$id/households.dta".

### 3.2 Outputs

El archivo "`c(sysdir_site)'/users/$pais/$id/households.dta".

### 3.3 Impuestos y Aportaciones

Calcula los impuestos y aportaciones de cada hogar.

### 3.4 Transferencias Públicas

Calcula las transferencias públicas de cada hogar.

### 3.5 Aportaciones Netas

Calcula las aportaciones netas de cada hogar.

### 3.6 Cuenta Generacional

Calcula la cuenta generacional.

### 3.7 Sankey

Genera diagramas de Sankey para varios grupos de datos.

## Cómo usar
Para usar este archivo, simplemente ejecútelo en Stata. Puede modificar las opciones globales en la parte superior del archivo para personalizar el comportamiento de las simulaciones.

## Conclusión
El archivo SIM.do es una herramienta poderosa para ejecutar simulaciones fiscales. Al entender su estructura y cómo personalizarla, puede usarla para generar una amplia gama de resultados de simulación.