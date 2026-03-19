# Simulador Fiscal CIEP: PIB, deflactor y proyecciones

Versión: 20 de Febrero de 2025


<hr style="border: none; height: 2px; background-color: #ff7020;">

## PIBDeflactor.ado
**Descripción**: *Ado-file* diseñado para automatizar el acceso y generar proyecciones de indicadores económicos clave a partir de escenarios definidos por el usuario. Desarrollado con información del Banco de Información Económica (BIE) y el Consejo Nacional de Población (CONAPO).

<details>
  <summary>**Conoce la lista de indicadores generados**</summary>

---
**1. Crecimiento Económico y Productividad**  

* **pibY:** PIB nominal en moneda corriente.
* **pibYR:** PIB real ajustado por inflación.
* **var_pibY:** Crecimiento anual del PIB real.
* **var_pibG:** Promedio geométrico del crecimiento del PIB real.
* **PIBPob:** PIB real per cápita.
* **pibPO:** PIB real por población ocupada.
* **OutputPerWorker:** PIB real por población en edad de trabajar.
* **pibYVP:** PIB real descontado a valor presente.

**2. Demografía**  

* **PoblacionENOE:** Población total estimada según la ENOE de INEGI.
* **PoblacionOcupada:** Población ocupada según la ENOE de INEGI.
* **PoblacionDesocupada:** Población desocupada según la ENOE de INEGI.
* **Poblacion:** Estimaciones de población de CONAPO.
* **PoblacionO:** Población ocupada ajustada para cálculos de productividad.
* **WorkingAge:** Población en edad de trabajar (15-65 años) según CONAPO.

**3. Precios e Inflación**  

* **inpc:** Índice Nacional de Precios al Consumidor (INPC).
* **IndiceY:** Índice de precios implícitos del PIB.
* **deflator:** Deflactor del PIB con base en el índice de precios implícitos.
* **deflatorpp:** Poder adquisitivo ajustado por inflación.
* **var_indiceY:** Crecimiento anual del índice de precios implícitos.
* **var_indiceG:** Promedio geométrico del crecimiento del índice de precios.
* **var_inflY:** Inflación anual calculada con el INPC.
* **var_inflG:** Promedio geométrico de la inflación en varios años.

---

</details>


 ![ilustracion1](images/PIBDeflactor/ilustracion1.png)




<h3 style="color: #ff7020;">1. Input:</h3>

En este programa se utilizan dos fuentes de datos:

1. BIE:  Proporciona datos sobre el PIB, el deflactor de precios, la inflación y el empleo. [^1] 

2. CONAPO: Contiene la estimación del número de habitantes a mitad de cada año entre 1950 y 2070. [^2]

<details>
  <summary>Mostrar código fuente</summary>
  BIE:
  ![paso1](images/PIBDeflactor/CodigoFuente1A.png)
  ![paso1](images/PIBDeflactor/CodigoFuente1B.png)
  CONAPO:
  ![paso1](images/PIBDeflactor/CodigoFuente1C.png)
</details>

<h3 style="color: #ff7020;">2. Sintaxis:</h3>

Recuerda que este programa tiene dos funciones: acceder a los datos económicos y generar proyecciones económicos a partir de escenarios definidos por el usario. Antes de generar las proyecciones, es necesario ejecutar el programa para cargar los datos económicos.

<h5 style="color: #ff7020;">Accede a los datos:</h3>

Para extraer los datos, es necesario ingresar el comando en la consola siguiendo esta sintaxis:

`PIBDeflactor [if] [, ANIOvp(int) ANIOMAX(int 2070)  GEOPIB(int) GEODEF(int) DIScount(real) NOGraphs UPDATE]`

Para crear comandos de manera automática y evitar errores de sintaxis, utiliza nuestra calculadora de prompts.

<div style="text-align: center;">
    <h4 style="border-bottom: 2px solid black; display: inline-block;">Calculadora de Prompts</h4>
</div>



**Opciones disponibles:**
<!-- Opciones para PIBDeflactor -->

<div>
  <label for="anioVp">Año Base:</label>
  <input 
    type="number" 
    id="anioVp" 
    placeholder="Ej. 2024" 
    oninput="actualizarComando()"
  >
</div>
<div>
  <label for="aniofinal">Año Final:</label>
  <input type="number" id="aniomax" placeholder="Ej. 2070" oninput="actualizarComando()">
</div>
<div>
  <label for="geopib">Promedio Geométrico (PIB):</label>
  <input type="number" id="geopib" placeholder="Ej. 1993" oninput="actualizarComando()">
</div>
<div>
  <label for="geodef">Promedio Geométrico (Deflactor):</label>
  <input type="number" id="geodef" placeholder="Ej. 1993" oninput="actualizarComando()">
</div>
<div>
  <label for="discount">Tasa de descuento:</label>
  <input type="number" id="discount" step="0.1" placeholder="Ej. 5" oninput="actualizarComando()">
</div>
<div>
  <label for="noGraphs">Sin gráficos:</label>
  <input type="checkbox" id="noGraphs" onchange="actualizarComando()">
</div>
<div>
  <label for="update">Actualizar base:</label>
  <input type="checkbox" id="update" onchange="actualizarComando()">
</div>

<p><strong>Copia y pega este comando en la consola:</strong></p>
<pre id="códigoComando">PIBDeflactor</pre>

<script>
  function actualizarComando() {
    // Obtiene los valores de cada opción
    var anioVp   = document.getElementById("anioVp").value;
    var geopib   = document.getElementById("geopib").value;
    var geodef   = document.getElementById("geodef").value;
    var discount = document.getElementById("discount").value;
    var aniomax  = document.getElementById("aniomax").value;
    var noGraphs = document.getElementById("noGraphs").checked;
    var update   = document.getElementById("update").checked;

    // Comando base
    var comando = "PIBDeflactor";
    
    // Construye las opciones adicionales
    var opciones = "";
    if(anioVp)   { opciones += " aniovp(" + anioVp + ")"; }
    if(geopib)   { opciones += " geopib(" + geopib + ")"; }
    if(geodef)   { opciones += " geodef(" + geodef + ")"; }
    if(discount) { opciones += " discount(" + discount + ")"; }
    if(aniomax)  { opciones += " aniomax(" + aniomax + ")"; }
    if(noGraphs) { opciones += " nographs"; }
    if(update)   { opciones += " update"; }
    
    // Agrega las opciones al comando si se definió alguna
    if(opciones.trim() !== "") {
       comando += "," + opciones;
    }
    
    // Actualiza el pre con el comando final
    document.getElementById("códigoComando").textContent = comando;
  }
</script>



<details>
  <summary>**Descripción de opciones**</summary>
  
- **Año Base (aniovp)**: Cambia el año de referencia para calcular el *valor presente*. Tiene que ser un número entre 1993 (mínimo reportado por el INEGI/BIE) y 2050 (máximo proyectado por el CONAPO, en su base de población). El *año actual* es el valor por default.
- **Año Final (aniomax)**: Año final para las proyecciónes de las gráficas. El último año de la serie (2070) es el valor por default.
- **Promedio Geométrico PIB (geopib)**:  Año base a partir del cual se calcula el crecimiento geométrico promedio del PIB, utilizado para proyectar el crecimiento en años futuros. [^3]
- **Promedio Geométrico Deflactor (geodef)**:  Año base a partir del cual se calcula el crecimiento geométrico promedio del deflactor del PIB, utilizado para estimar la evolución de los precios en el futuro. [^4] 
- **Tasa de Descuento (discount)**: Tasa utilizada para convertir valores futuros del PIB en su equivalente a valor presente.
- **Sin Gráfico (nographs)**: Evita la generación de gráficas.
- **Actualizar Base (update)**: Corre un *do.file* para obtener los datos más recientes del BIE y el CONAPO. 

</details>

<h5 style="color: #ff7020;">Genera escenarios económicos:</h3>

Para generar escenarios económicos podras modificar 3 variables y observar los efectos en las proyecciones económicas.

1. Crecimiento económico:
2. 



<h3 style="color: #ff7020;">3. Output:</h3>

Tras ingresar el prompt, el código devolverá tres elementos: ventana de resultados, cuatro gráficas y la base de datos. Podrás modificar el ado.file para obtener una base a tus necesidades.

**1. Ventana de Resultados:** Muestra un resumen del análisis realizado. 

![resultados](images/PIBDeflactor/Ventana de Resultados.png) 


**2. Gráficas:** Representación visual de los indicadores calculados. 

Los indicadores se dividen en 3 temporalidades:

* Datos históricos (naranja): datos reales reportados desde 1993 hasta la fecha.
* Estimaciones de los CGPE (amarillo): datos estimados por la Secretaría de Hacienda desde la fecha actual hasta siete años en el futuro.
* Proyecciones CIEP (verde): datos proyectados utilizando la metodología del CIEP con base en tendencias históricas. 


#####A
![Indice](images/PIBDeflactor/Indice de Precios Implicitos.png)

#####B
![PIB](images/PIBDeflactor/Producto Interno Bruto.png)

#####C
![PIBP](images/PIBDeflactor/Producto Interno Bruto por Persona.png)

#####D
![INPC](images/PIBDeflactor/Indice Nacional De Precios al Consumidor.png)


**3. Base de Datos:** Permite al usuario obtener una base de datos recortada y limpia para hacer sus propios análisis.

  ![BASE](images/PIBDeflactor/Base De Datos.png) 


## Sintaxis completa (documentación técnica)

```stata
PIBDeflactor [if] [, ANIOvp(int año_actual) NOGraphs UPDATE GEOPIB(int -1) GEODEF(int -1) DIScount(real 5) ANIOMAX(int año_actual+15) NOOutput TEXTbook]
```

### Opciones adicionales no documentadas anteriormente:

- **NOOutput**: Suprime la salida de variables de retorno
- **TEXTbook**: Modo especial para generar gráficos sin títulos ni fuentes (para uso en libros de texto)

## Dependencias

### Programa requerido:
- **`UpdatePIBDeflactor`**: Actualiza la base de datos desde BIE/INEGI y CONAPO

### Archivos requeridos:
- **`04_master/PIBDeflactor.dta`**: Base de datos consolidada con series macroeconómicas
- Acceso a internet para actualización de datos (cuando se usa `update`)

### Variables globales utilizadas:
- **`$pais`**: Nombre del país para títulos
- **`$id`**: Identificador de usuario para rutas de archivos
- **`$paqueteEconomico`**: Etiqueta para escenarios oficiales
- **`$nographs`**: Supresor global de gráficos
- **`$textbook`**: Modo textbook global
- **Parámetros de crecimiento exógeno**: `$pib{año}`, `$def{año}`, `$inf{año}`
- **`$lambda`**: Tasa de crecimiento de productividad exógena

## Cálculos y metodología

### 4.1 Cálculo de promedios geométricos:
```stata
var_pibG = ((pibYR/L{difpib}.pibYR)^(1/{difpib})-1)*100
var_indiceG = ((indiceY/L{difdef}.indiceY)^(1/{difdef})-1)*100
```

### 4.2 Proyección de PIB con productividad (Lambda):
```stata
lambda = (1+llambda/100)^(anio-aniovp)
pibYR_proyectado = pibYR_base/WorkingAge_base * WorkingAge * lambda
```

### 4.3 Valor presente descontado:
```stata
pibYVP = pibYR/(1+discount/100)^(anio-aniovp)
deflator = indiceY/indiceY[aniovp]
```

## Inputs (archivos de entrada)

### Base de datos principal:
**`04_master/PIBDeflactor.dta`** con variables:
- `anio`, `trimestre`, `aniotrimestre`: Identificadores temporales
- `pibQ`, `pibQR`: PIB trimestral nominal y real
- `indiceQ`: Índice de precios implícitos trimestral
- `inpc`: Índice Nacional de Precios al Consumidor
- `WorkingAge`: Población en edad de trabajar (15-65 años)
- `Poblacion`, `PoblacionOcupada`: Datos demográficos
- `currency`: Tipo de moneda

### Parámetros exógenos (opcionales):
- **`$pib{año}`**: Crecimiento del PIB para año específico
- **`$def{año}`**: Crecimiento del deflactor para año específico  
- **`$inf{año}`**: Inflación para año específico
- **`$lambda`**: Tasa de productividad exógena

## Outputs (archivos y variables generadas)

### Archivos de gráficos exportados:
Ubicación: `users/$id/graphs/`

1. **`Productividad{año}.png`**: Productividad laboral histórica y proyectada
2. **`deflactor.png`**: Índice de precios implícitos y crecimiento anual
3. **`pib.png`**: PIB real en billones y crecimiento anual
4. **`pib_pc.png`**: PIB per cápita y crecimiento anual
5. **`inflacion.png`**: INPC y crecimiento anual (inflación)

### Variables en dataset final:
- **Indicadores principales**: `pibY`, `pibYR`, `indiceY`, `inpc`, `deflator`
- **Crecimiento anual**: `var_pibY`, `var_indiceY`, `var_inflY`
- **Promedios geométricos**: `var_pibG`, `var_indiceG`, `var_inflG`
- **Per cápita**: `PIBPob`, `pibPO`, `OutputPerWorker`
- **Valor presente**: `pibYVP`, `deflatorpp`
- **Demografía**: `Poblacion`, `PoblacionOcupada`, `WorkingAge`
- **Productividad**: `lambda`

### Scalars de retorno (r()):

#### Parámetros del análisis:
- **`r(aniovp)`**: Año base utilizado
- **`r(geo)`**: Número de años para promedio geométrico del PIB
- **`r(discount)`**: Tasa de descuento utilizada
- **`r(anio_exo)`**: Último año con datos exógenos de PIB
- **`r(deflator)`**: Deflactor del año base (=1.0)
- **`r(deflatorpp)`**: Deflactor de poder adquisitivo del año base

#### Resultados económicos:
- **`r(pibY)`**: PIB nominal del año base (millones)
- **`r(pibYPC)`**: PIB per cápita del año base
- **`r(crecimientoProm)`**: Crecimiento promedio del PIB (%)
- **`r(crecimientoPobProm)`**: Crecimiento promedio per cápita (%)
- **`r(deflactorProm)`**: Crecimiento promedio del deflactor (%)
- **`r(inflacionProm)`**: Inflación promedio (%)
- **`r(llambda)`**: Tasa de productividad calculada (%)
- **`r(pibVPINF)`**: PIB valor presente total (incluye infinito)

#### Configuración de escenarios:
- **`r(except)`**: Lista de años con PIB exógeno
- **`r(exceptI)`**: Lista de años con inflación exógena

### Matrices de retorno:
- **`r(pibYVP)`**: Valor presente total del PIB futuro

## Ejemplos prácticos actualizados

### Ejemplo 1: Análisis básico con proyecciones hasta 2050
```stata
PIBDeflactor, aniovp(2024) aniomax(2050) discount(4)
```

### Ejemplo 2: Análisis con promedios geométricos personalizados
```stata
PIBDeflactor, geopib(2000) geodef(2010) discount(3.5)
```

### Ejemplo 3: Actualizar datos y generar sin gráficos
```stata
PIBDeflactor, update nographs nooutput
```

### Ejemplo 4: Análisis con parámetros exógenos
```stata
// Definir crecimiento exógeno para años específicos
global pib2024 = 2.5
global pib2025 = 3.0
global def2024 = 4.2
PIBDeflactor, aniovp(2024) aniomax(2030)
```

### Ejemplo 5: Solo años específicos con filtro
```stata
PIBDeflactor if anio >= 2020 & anio <= 2030, geopib(2015)
```

## Ver también

### Programas relacionados:
- **`UpdatePIBDeflactor`**: Actualiza base de datos desde fuentes oficiales
- **`FiscalGap`**: Utiliza proyecciones de PIBDeflactor para análisis fiscal
- **`Poblacion`**: Genera proyecciones demográficas detalladas
- **`LIF`/`PEF`**: Utilizan deflactor para ajustar series fiscales
- **`SHRFSP`**: Utiliza PIB para calcular ratios de deuda

### Fuentes de datos:
- **BIE/INEGI**: Series macroeconómicas trimestrales
- **CONAPO**: Proyecciones demográficas 1950-2070
- **SHCP**: Criterios Generales de Política Económica (cuando disponible)

## Notas técnicas actualizadas

### Manejo de datos faltantes:
- Si no existe la base `PIBDeflactor.dta`, automáticamente ejecuta `UpdatePIBDeflactor`
- Los años futuros sin parámetros exógenos usan promedios geométricos móviles
- Missing values se proyectan usando tendencias históricas

### Validaciones automáticas:
- El año base debe estar entre el primer año disponible y el último año con datos
- Los promedios geométricos se ajustan automáticamente si el año inicial es muy antiguo
- La productividad lambda se calcula solo con años que tienen datos completos

### Configuración de directorios:
El programa crea automáticamente:
- `04_master/`: Para bases de datos
- `05_graphs/`: Para gráficos temporales
- `users/$id/graphs/`: Para gráficos finales del usuario

### Tiempo de ejecución:
- **Sin actualización**: < 5 segundos
- **Con actualización**: 30-120 segundos (depende de conexión a internet)
- **Con gráficos**: +10-15 segundos adicionales

### Memoria y rendimiento:
- Dataset final típico: ~50-100 observaciones
- Uso de memoria: < 5 MB
- Compatible con Stata 14+

[^1]: **Link:** [Banco de Indicadores](https://www.inegi.org.mx/app/indicadores/) 

[^2]: **Link:** [Bases de Datos CONAPO](https://www.gob.mx/conapo/articulos/reconstruccion-y-proyecciones-de-la-poblacion-de-los-municipios-de-mexico) 

[^3]: El promedio geométrico se calcula desde el año seleccionado hasta el año actual. Este valor se usa para estimar el PIB del siguiente año, aplicando el crecimiento promedio geométrico obtenido. A medida que avanzan los años, la ventana del cálculo se ajusta, incorporando el año más reciente y descartando el más antiguo.

[^4]: El cálculo se realiza desde el año seleccionado hasta el año actual para obtener una tasa de cambio promedio en los precios. Esta tasa se aplica para proyectar la inflación futura y ajustar el deflactor del PIB en los próximos años. La ventana de cálculo se ajusta dinámicamente año tras año, incorporando el dato más reciente y eliminando el más antiguo.