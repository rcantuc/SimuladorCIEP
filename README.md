# Conoce el Simulador Fiscal CIEP

Versión: 14 de marzo de 2025

<hr style="border: none; height: 2px; background-color: #ff7020;">

<h2 style="color: #ff7020;">Simulador Fiscal</h2>

#### ¿Qué hace el Simulador Fiscal?

El proyecto del Simulador Fiscal facilita el acceso a toda la información económica relevante de México. Con los programas del simulador podrás acceder a gran parte de la información económica pública a través de Stata. Además, el simulador brinda un pre-análisis y gráficas para facilitar la comprensión de los datos.

<div>
    <p style="margin-bottom: 5px; font-weight: bold;">¿Cuánto tiempo toma acceder a datos del PIB e inflación?</p>
    <div style="display: flex;">
        <div style="flex: 1; padding: 10px;">
            <h2 style="font-size: 14px; font-weight: normal; margin-top: 0; margin-bottom: 5px;">Con el Simulador</h2>
        </div>
        <div style="flex: 1; padding: 10px;">
            <h2 style="font-size: 14px; font-weight: normal; margin-top: 0; margin-bottom: 5px;">Sin el Simulador</h2>
        </div>
    </div>
</div>

![Paso1](video2.gif)
<div style="display: flex;">
    <div style="flex: 1; padding: 10px;">
        <ul>
            <li>Tiempo de acceso: 18 segundos</li>
            <li>Base de datos pre-analizada y limpia</li>
            <li>Integración directa con Stata para análisis</li>
        </ul>
    </div>
    <div style="flex: 1; padding: 10px;">
        <ul>
            <li>Tiempo de acceso: más de 1 minuto</li>
            <li>Base de datos cruda</li>
            <li>Sin integración directa a Stata</li>
        </ul>
    </div>
</div>


#### Te lleva un paso más allá

Además de facilitar la descarga de indicadores económicos, el simulador tiene análisis y graficas pre-cargadas que facilitan la interpretación de los datos.

**1. Pre-análisis:** Destaca automáticamente la información más relevante en un formato estructurado, claro y comprensible.

<div style="display: flex; justify-content: center; align-items: center;">
    <img src="manuales/images/ReadMe/Ventana de Resultados.png" style="width: 50%; height: auto;" alt="Paso1">
</div>


**2. Gráficas:** El simulador proporciona acceso a gráficas que mejoran la comprensión de los datos.

<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;">
    <img src="manuales/images/ReadMe/Grafica1.png" style="width: 100%;">
    <img src="manuales/images/ReadMe/Grafica2.png" style="width: 100%;">
    <img src="manuales/images/ReadMe/Grafica3.png" style="width: 100%;">
    <img src="manuales/images/ReadMe/Grafica4.png" style="width: 100%;">
</div>

**3. Base de Datos procesada:** El simulador analiza los datos e incorpora indicadores adicionales. Por ejemplo, el programa PIBDeflactor facilita el acceso a datos como el PIB Nominal, PIB Real, PIB per cápita, y PIB por población ocupada, entre otros

<div style="display: flex; justify-content: center; align-items: center;">
    <img src="manuales/images/ReadMe/video3.gif" style="width: 50%; height: auto;" alt="Paso1">
</div>


<h2 style="color: #ff7020;">Cómo acceder al Simulador</h2>

#### 1. Instala GitHub Desktop

Ve a la página de [github.com/apps/desktop](https://github.com/apps/desktop) y sigue las instrucciones para instalar GitHub Desktop en tu computadora.

#### 2. Clona el repositorio de SimuladorCIEP en tu computadora.

<details>
  <summary>Instrucciones paso a paso</summary>

1.   Ingresa a la aplicación de GitHub Desktop
2.   Selecciona "Clone Repository from the Internet"
 
 
 <div style="display: flex; justify-content: center; align-items: center;">
    <img src="manuales/images/Paso1.png" style="width: 50%; height: auto;" alt="Paso1">
</div>
 
3. Ingresa el URL `https://github.com/rcantuc/SimuladorCIEP` y haz click en Clone
 <div style="display: flex; justify-content: center; align-items: center;">
    <img src="manuales/images/Paso2.png" style="width: 50%; height: auto;" alt="Paso2">
</div>
4. El repositorio empezará a descargarse en tu computadora
 <div style="display: flex; justify-content: center; align-items: center;">
    <img src="manuales/images/Paso3.png" style="width: 50%; height: auto;" alt="Paso3">
</div>
 
</details>

#### 3. Ya estás listo, verás una carpeta nueva creada en tu computadora.


<h2 style="color: #ff7020;">Programas Disponibles</h2>

A través de este simulador podrás acceder a diversos indicadores económicos con el uso de comandos. Estos son los comandos se han desarrollado hasta el momento:

#### 1. `Poblacion`
Este programa importa los datos de población por edad, sexo y entidad federativa para todos los años de interés. Los datos provienen de la CONAPO. También genera gráficos de la pirámide y transición demográfica para el año de interés.

#### 2. `PIBDeflactor`
Este programa importa y procesa los datos económicos, incluyendo el PIB, el índice de precios implícitos, el INPC, la población y la población ocupada. Genera una base de datos con su deflactor y productividad laboral para todos los años. Los datos provienen del INEGI y BIE.

#### 3. `SCN` (Sistema de Cuentas Nacionales)
Este programa importa y procesa los datos del sistema fiscal, incluyendo los ingresos, gastos y deuda para todos los años. Los datos provienen de las LIFs (Leyes de Ingresos de la Federación), PEFs (Presupuestos de Egresos de la Federación) y SHRFSP (Sistema de Información de las Finanzas Públicas Estatales y Municipales).

#### 4. `SHRSFP` (Saldo Histórico de los Requerimientos Financieros del Sector Público)
Este programa importa y procesa datos del Saldo Histórico de los Requerimientos Financieros del Sector Público desde el año 1993 hasta el año actual. Captura información para evaluar la deuda pública y estructura fiscal. Para este programa se utilizan datos de la SHCP y del INEGI.

#### 5. `LIF` (Ley de Ingresos de la Federación)
Este programa importa y procesa datos sobre los ingresos de la federación, utilizando información oficial de la SHCP y el INEGI. Permite acceder a registros históricos de ingresos fiscales, comparar su evolución a través del tiempo y analizar su elasticidad respecto al PIB.

#### 6. `PEF` (Presupuesto de Egresos de la Federación)
Este programa importa y procesa datos del Presupuesto de Egresos de la Federación (PEF), utilizando datos de la SHCP e INEGI. Permite acceder al gasto público histórico desde 2013 hasta la fecha actual, desglosando la distribución del gasto en sectores como salud, educación y seguridad.

#### 7. `DatosAbiertos`
Este programa está diseñado para proporcionar acceso estructurado a cualquier indicador económico de las Estadísticas Oportunas de Finanzas Públicas, facilitando su consulta y análisis. Para este programa se utiliza información de la SHCP y del INEGI.

<h2 style="color: #ff7020;">Como usar el Simulador</h2>

Para llamar al programa es necesario escribir un comando en la consola de Stata. Cada comando tiene una sintaxis específica y puede incluir *options*, instrucciones específicas que permiten refinar tu búsqueda para adaptarlo a lo que buscas.

<div style="display: flex; justify-content: center; align-items: center;">
    <img src="manuales/images/imagen1.png" style="width: 50%; height: auto;" alt="Paso1">
</div>


Llamar al programa con la sintaxis correcta puede resultar complejo. Por ello, cada programa esta acompañado de un *ReadMe file* que detalla sus alcances y funcionalidades. Además, este archivo cuenta con una herramienta de cálculo de Prompts, que facilita su diseño sin incurrir en errores de sintaxis. Se recomienda revisar este archivo antes de ejecutar cualquier comando.


<h2 style="color: #ff7020;">Somos tu mejor aliado en la investigación</h2>

Como cualquier herramienta, el proceso de adaptación al Simulador tomará tiempo. Sin embargo, creemos que una vez que pases por esta etapa de aprendizaje no volverás a acceder a los datos públicos de otra manera.

Si deseas que incluyamos nueva información económica, no dudes en enviarnos un correo a `ricardocantu@ciep.mx`. Estamos comprometidos en hacer este programa lo más robusto posible y estamos abiertos a todas tus sugerencias.


---

<h2 style="color: #ff7020;">Documentación Técnica</h2>

### Archivos principales

#### `simulador.stpr`
Proyecto que concentra todos los do-files y ado-files del Simulador Fiscal CIEP.

#### `SIM.do` 
Plantilla maestra (template) para hacer simulaciones fiscales. Configura el entorno, define opciones globales, establece el directorio de trabajo basado en el usuario y ejecuta varios comandos de forma secuencial.

#### `profile.do`
Archivo de configuración inicial que se ejecuta automáticamente al iniciar Stata. Realiza las siguientes configuraciones:

**1. Estilo CIEP**
- `set scheme ciep`: Esquema de colores y estilos para gráficos estilo CIEP
- `graph set window fontface "Ubuntu Light"`: Configura la fuente de las ventanas de gráficos
- `set more off, permanently`: Desactiva la pausa en la visualización de resultados largos
- `set type double, permanently`: Define el tipo de dato numérico predeterminado como `double`
- `set charset latin1, permanently`: Establece el conjunto de caracteres para soportar español

**2. Parámetros globales**
- Define el año base para valores presentes (`aniovp`)
- Establece el paquete económico (`anioPE`)
- Determina el año ENIGH más reciente (`anioenigh`)
- Lista de entidades federativas de México

### Opciones globales

- `id`: Variable global con el nombre de usuario actual
- `export`: Directorio donde se guardan las imágenes generadas
- `nographs`: Suprime la generación de gráficos
- `textbook`: Cambia el formato de los gráficos a LaTeX
- `output`: Determina si se generan salidas para la web
- `update`: Determina si se actualizan las bases de datos (toma tiempo)

### Estructura del flujo de trabajo

**1. Marco Macro**
- Población (CONAPO): Pirámide y transición demográfica
- Economía (INEGI, BIE): PIB, deflactores, productividad laboral
- Sistema Fiscal: Ingresos (LIF), Gastos (PEF), Deuda (SHRFSP)
- Subnacionales: Datos de gobiernos estatales y municipales

**2. Información de Hogares**
- Procesamiento de ENIGH
- Generación de `households.dta` y `expenditures.dta`
- Integración macro-micro

**3. Ciclo de Vida Fiscal**
- Impuestos y aportaciones por hogar
- Transferencias públicas
- Aportaciones netas
- Cuentas generacionales
- Diagramas de Sankey por grupo demográfico

### Cómo usar SIM.do

1. Abre el archivo en Stata
2. Modifica las opciones globales según tus necesidades
3. Ejecuta el script completo o por secciones
4. Los resultados se guardan en `users/$id/`

Para más información técnica, consulta la carpeta `00_manuales/`.



