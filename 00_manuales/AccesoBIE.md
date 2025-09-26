# Simulador Fiscal CIEP: Acceso BIE

Versión: 4 de abril de 2025


<hr style="border: none; height: 2px; background-color: #ff7020;">

## AccesoBIE.ado
**Descripción**: *Ado-file* diseñado para cargar series de los datos disponibles en el Banco de Información Económica. 

**Alcance**: Este programa facilita las tareas de consulta y análisis de datos sin necesidad de descargar las series manualmente.


<h3 style="color: #ff7020;">1. Input:</h3>

Se utiliza una fuente de datos:

Banco de Información Económica:  Proporciona datos económicos sobre PIB, el deflactor de precios, la inflación, el empleo y muchos otros más[^1] 

<h3 style="color: #ff7020;">2. Sintaxis:</h3>

Para cargar los datos, es necesario ingresar el comando en la consola siguiendo esta sintaxis:

`AccesoBIE "clave" "nombre"`

**Descripción de cada termino:**

`AccesoBIE: ` Este comando llama al programa.

`clave:` Aquí ingresa las claves de los indicadores económicos que deseas ingresar

`nombre:` Aquí ingresa los nombre con los guardaras la variable del indicador económico. Puede escribir el que desees

**Ejemplo de uso**:
Este comando carga en Stata 3 indicadores: PIB a precios corrientes, el Indice de Precios Implicítos y la población total de la ENOE. 

`AccesoBIE "734407 735143 446562" "PibNominal IndicePrecios PoblacionENOE"`


<details>
  <summary>**Instrucciones para localizar series del Banco de Información Económica**</summary>

Pasos para encontrar código de la serie:

1. Ingresa a [Banco de Información Económica (BIE)](https://www.inegi.org.mx/app/indicadores/default.aspx?tm=0#tabMCcollapse-Indicadores)

2. Busca el indicador económico. En este caso se está eligiendo "Población ocupada, subocupada y desocupada". 
<div style="display: flex; justify-content: center; align-items: center;">
    <img src="images/AccesoBIE/Paso1.png" style="width: 50%; height: auto;" alt="Paso1">
</div>

3. Localiza el código de la serie y copialo.
<div style="display: flex; justify-content: center; align-items: center;">
    <img src="images/AccesoBIE/Paso2.png" style="width: 50%; height: auto;" alt="Paso1">
</div>
 
  
</details>


<h3 style="color: #ff7020;">3. Output:</h3>

Tras ingresar el comando, el código te devolverá una base de datos con los indicadores solicitados. El código agregará variables de fechas para hacer más fácil la interpretación.

**Ejemplo: Base de Datos** 
 
<div style="display: flex; justify-content: center; align-items: center;">
    <img src="images/AccesoBIE/BaseDeDatos.png" style="width: 50%; height: auto;" alt="Paso1">
</div>
 


[^1]: **Link:** [Banco de Indicadores](https://www.inegi.org.mx/app/indicadores/) 
