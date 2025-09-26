# Simulador Fiscal CIEP: Saldo Histórico de los Requerimientos Financieros del Sector Público (SHRFSP)

Versión: 4 de marzo de 2025

<hr style="border: none; height: 2px; background-color: #ff7020;">

## SHRFSP.ado

**Descripción:** *Ado-file* diseñado para automatizar la extracción y el análisis del Saldo Histórico de los Requerimientos Financieros del Sector Público (SHRFSP). Utiliza información proveniente de la Secretaría de Hacienda y Crédito Público (SHCP) y del INEGI para calcular indicadores relacionados con la deuda pública y la estructura fiscal. 

![Imagen2](images/SHRSFP/1.SaldoHistorico_RSFP.png)

<details>
  <summary>**Esta es la información que encontrarás aquí:**</summary>
  ---
  **1. Indicadores anuales sobre deuda**
  
  - Balance presupuestario.
  - Balance de proyectos fuera del presupuesto: PIDIGERAS, IPAB, FONADIN, Programa de Deudores, Banca de Desarrollo y Adecuaciones.
 
 
</details>
  

<h3 style="color: #ff7020;">1. Input:</h3>

Este programa utiliza dos fuentes de datos:

1. Estadísticas Oportunas de la SHCP: Proporciona información sobre finanzas públicas del país, incluyendo balances fiscales, ingresos, gastos y deuda pública [^1]
2. BIE:  Proporciona datos sobre el PIB y el deflactor de precios. [^2]

<h3 style="color: #ff7020;">2. Sintaxis:</h3>

Para extraer los datos, es necesario ingresar el prompt en la consola siguiendo esta sintaxis:

`SHRFSP [, ANIO(int) ULTanio(int) NOGraphs UPDATE Base]`


Para crear comandos de manera automática y evitar errores de sintaxis, utiliza nuestra calculadora de prompts.


<div style="text-align: center;">
    <h4 style="border-bottom: 2px solid black; display: inline-block;">Calculadora de Prompts</h4>
</div>


<div>
  <label for="anioVp">Año:</label>
  <input 
    type="number" 
    id="anioVp" 
    placeholder="Ej. 2024" 
    oninput="actualizarComando()">
</div>
<div>
  <label for="ultAnio">Último Año:</label>
  <input type="number" id="ultAnio" placeholder="Ej. 2001" oninput="actualizarComando()">
</div>
<div>
  <label for="noGraphs">Sin gráficos:</label>
  <input type="checkbox" id="noGraphs" onchange="actualizarComando()">
</div>
<div>
  <label for="update">Actualizar:</label>
  <input type="checkbox" id="update" onchange="actualizarComando()">
</div>
<div>
  <label for="base">Solo desplegar base:</label>
  <input type="checkbox" id="base" onchange="actualizarComando()">
</div>


<p><strong>Copia y pega este comando en la consola:</strong></p>
<pre id="codigoComando">SHRFSP</pre>

<script>
  function actualizarComando() {
    // Obtiene los valores de cada campo
    var anioVp       = document.getElementById("anioVp").value;
    var noGraphs     = document.getElementById("noGraphs").checked;
    var update       = document.getElementById("update").checked;
    var base         = document.getElementById("base").checked;
    var ultAnio      = document.getElementById("ultAnio").value;
    
    // Comando base
    var comando = "SHRFSP";
    
    // Construye las opciones adicionales
    var opciones = "";
    if (anioVp)       { opciones += " anio(" + anioVp + ")"; }
    if (noGraphs)     { opciones += " nographs"; }
    if (update)       { opciones += " update"; }
    if (base)         { opciones += " base"; }
    if (ultAnio)      { opciones += " ultanio(" + ultAnio + ")"; }
    
    // Agrega las opciones al comando si existen
    if (opciones.trim() !== "") {
      comando += "," + opciones;
    }
    
    // Actualiza el contenido del <pre> con el comando final
    document.getElementById("codigoComando").textContent = comando;
  }
</script>

<details>
  <summary>**Descripción de opciones:**</summary>
  
 - **Año (anio):** Cambia el año de referencia. Tiene que ser un número entre 1993 y el año actual, que es el valor default.

- **Último año (ultanio)**: Especifica el último año de referencia para la gráfica. Debe ser anterior al año base y estar dentro del rango de 1993 hasta el año actual. El valor predeterminado es 2001.

- **Sin Gráfico (nographs)**: Evita la generación de gráficas.

- **Actualizar Base (update)**: Corre un *do.file* para obtener los datos más recientes del SHCP y el INEGI. 

- **Solo Base (base)**:  Permite descargar únicamente la base de datos sin aplicar cálculos adicionales.
  
</details>



<h3 style="color: #ff7020;">3. Output:</h3>

Tras ingresar el prompt, el código devolverá tres elementos. La ventana de resultados, siete gráficas y una base de datos. 

**1. Ventana de Resultados:** 
![Imagen1](images/SHRSFP/VentanaDeResultados.png)
  
**2. Gráficas:** 

**Saldo histórico de RSFP (% de PIB):** Muestra el saldo de la deuda neta del sector público, desglosada en deuda externa e interna. Además, presenta la deuda como porcentaje del PIB.

![Imagen2](images/SHRSFP/1.SaldoHistorico_RSFP.png)

**Saldo histórico de RSFP (Deuda per Cápita):** Muestra la deuda neta del sector público, desglosada en deuda externa e interna. Además, calcula la deuda per cápita.

![Imagen3](images/SHRSFP/2.SaldoHistorico_RSFP.png)

**Deuda Bruta (Entidades Deudoras):** Muestra el acumulado de la deuda bruta del sector público, desglosada por las entidades deudoras.

![Imagen4](images/SHRSFP/3.DeudaBruta-oye.png)

**Deuda Bruta (Tipo de Deuda):** Muestra el acumulado de la deuda bruta del sector público, desglosada por tipo de deuda
![Imagen5](images/SHRSFP/4.DeudaBruta-shrsfp.png)

**Costo de la Deuda:** Muestra el costo financiero de la deuda. También, detalla la tasa de interés promedio[^3] de la deuda. 
![Imagen6](images/SHRSFP/5.CostoDeLaDeuda.png)

**Efectos sobre el indicador de deuda:** Presenta los factores económicos que contribuyen al aumento o reducción de la deuda, como indicador del PIB.

![Imagen7](images/SHRSFP/6.EfectosDeuda.png)

**Requerimientos financieros del sector público:** Muestra el nivel de endeudamiento del sector público para cada año. 
![Imagen8](images/SHRSFP/7.RFSP.png)

**3. Base de Datos:** Permite obtener una base de datos recortada y limpia para hacer sus propios análisis.
![Imagen9](images/SHRSFP/8.BaseDeDatos.png)

<details>
  <summary>**Información sobre la base de datos**</summary>
  
 1. Información sobre los valores: Todos los montos en la base de datos son en valor nominal, salvo que se indique lo contrario. La información de las cifras proviene directamente de fuentes públicas.
 2. En el caso de que selecciones la opción 
`solo base`, el programa te devolverá una base de datos sin ningún tipo de procesamiento. Se desplegará exactamente igual que en fuentes públicas. Consideramos que esta es una buena opción si quieres empezar tus análisis desde cero. 

</details>

[^1]: **Link:** [Estadísticas Oportunas](http://presto.hacienda.gob.mx/EstoporLayout/estadisticas.jsp) 

[^2]: **Link:** [Banco de Indicadores](https://www.inegi.org.mx/app/indicadores/) 

[^3]: La tasa de interés se obtiene mediante la división del monto de los intereses pagados entre la deuda para el mismo año.