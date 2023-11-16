# Documentación del archivo SIM.do
El archivo `simulador.stpr` es el proyecto que concentra todos los do-files y ado-files del Simulador Fiscal CIEP. Abrir para explorar todo lo que contiene.

El archivo `SIM.do` es la "plantilla maestra" (template) para hacer simulaciones fiscales. Aquí se configura el entorno, se definen opciones globales, se establece el directorio de trabajo basado en el usuario y se ejecuta varios comandos de forma secuencial.


## Configuración inicial: `profile.do`
El archivo comienza ejecutando el archivo `profile.do`, el cual realiza varias configuraciones iniciales para un entorno de simulación fiscal en Stata, estableciendo estilos, directorios y parámetros relevantes. Este código prepara Stata para análisis y simulaciones fiscales, adaptándolo para el manejo de datos en español y estilos visuales personalizados.


### 1. Estilo y configuraciones CIEP
- `set scheme ciep`: Establece un esquema de colores y estilos para gráficos estilo "CIEP".
- `graph set window fontface "Ubuntu"`: Configura la fuente de las ventanas de gráficos a "Ubuntu".
- `set more off, permanently`: Desactiva la pausa en la visualización de resultados largos de manera permanente.
- `set type double, permanently`: Define el tipo de dato numérico predeterminado como `double` (alta precisión) de forma permanente.
- `set charset latin1, permanently`: Establece el conjunto de caracteres a `latin1` permanentemente, útil para soportar caracteres en español.


### 2. Parámetros
- Establece la variable local `fecha` con la fecha actual y el escalar `aniovp` como el año base para obtener los "valores presentes". Se puede reemplazar posteriormente en cualquier momento.


### 3. Política Fiscal
- Define un paquete económico global como "CGPE 2024" o "Pre-Criterios 2025" y se establece el escalar `anioPE`. Se puede reemplazar posteriormente en cualquier momento.


### 4. Incidencia ENIGH
- Determina el año de la Encuesta Nacional de Ingresos y Gastos de los Hogares (ENIGH) más reciente basado en el año del paquete económico con el escalar `anioenigh`. Se puede reemplazar posteriormente en cualquier momento.


### 5. Entidades Federativas
- Define dos listas de nombres (una completa y otra abreviada) de las entidades federativas de México para análisis a nivel estatal.



## Directorio de trabajo: Repositorio SimuladorCIEP


### 1. Instalar Git
Asegúrate de tener Git instalado en tu computadora. Puedes descargarlo desde [git-scm.com](https://git-scm.com/). Sigue las instrucciones de instalación para tu sistema operativo.


### 2. Localizar el Repositorio en GitHub
Ve a la página del repositorio `SimuladorCIEP` en GitHub: `https://github.com/rcantuc/SimuladorCIEP`.


### 3. Copiar la URL del Repositorio
En la página del repositorio, haz clic en el botón "Clone or download" y copia la URL que aparece.


### 4. Abrir la Terminal o Línea de Comandos
Abre la terminal en Linux o macOS, o la línea de comandos/PowerShell en Windows.


### 5. Clonar el Repositorio
Navega hasta la carpeta donde desees colocar el repositorio clonado con el comando `cd ruta/del/directorio`. Luego, ejecuta:

```bash
git clone https://github.com/rcantuc/SimuladorCIEP
```

Reemplaza la URL con la que copiaste. Esto clonará el repositorio en tu máquina.


### 6. Navegar al Repositorio Clonado
Una vez clonado, accede al directorio del repositorio con:

```bash
cd SimuladorCIEP
```

Ahora tienes una copia local del repositorio `SimuladorCIEP`.


### 7. El repositorio local es el directorio `PERSONAL`
El directorio donde clonaste el repositorio se convierte en tu directorio de trabajo. Aquí se encuentran todos los archivos y bases de datos del Simulador. Puedes establecer diferentes directorios de trabajo para diferentes usuarios.

Por ejemplo:
- Si el nombre de usuario es "ricardo", el directorio de trabajo podría ser `/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/`.
- Si el nombre de usuario es "ciepmx", el directorio de trabajo se establecería en `/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/`.

Esto permite trabajar en múltiples computadoras con diferentes configuraciones de directorio, manteniendo la sincronización y el acceso a través de GitHub.


## Opciones globales
Esta sección permite al usuario establecer varias opciones globales. Estas opciones incluyen:

- `id`: Establece una variable global `id` al nombre de usuario actual (`c(username)`).
- `export`: Establece el directorio donde se quieren guardar las imágenes generadas.
- `nographs`: Suprime la generación de gráficos.
- `textbook`: Cambia el formato de los gráficos a LaTeX.
- `output`: Determina si se generan salidas para la web.
- `update`: Determina si se actualizan las diferentes bases utilizadas (toma mucho tiempo).


### Rutas de Archivos
- Crea un log file (`output.txt`) donde se guardarán los resultados de la simulación.
- Utiliza `capture mkdir` para crear directorios en la carpeta personal del usuario para el simulador y usuarios específicos.



## 1. Marco Macro

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