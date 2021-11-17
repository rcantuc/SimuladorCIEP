# Simulador Fiscal CIEP v5.0

	Versión: 4/marzo/2021

¡Bienvenidxs al equipo!

El Simulador Fiscal CIEP está (actualmente) programado en **Stata** (versiones 13+). Sin embargo, se pudieran incorporar otros programas como **R** u otros lenguajes como **PHP**.


**La misión**:  
Construir una red de programadores que use, estudie, mejore, facilite, actualice y automatice las necesidades del Simulador Fiscal CIEP en su versiones consecuentes. Es una herramienta comunitaria y participativa que puede ser utilizada para fines didácticos y analíticos.

---

Los pasos para empezar a **colaborar** (actualmente, sólo bajo invitación):

0. **Instalar** descargar la versión de Github para escritorio y contar con la invitación para colaborar. Descarga disponible en: https://desktop.github.com/
1. **Clonar** el repositorio del Simulador Fiscal CIEP disponible desde [Github][]: [rcantuc/simuladorCIEP][simuladorCIEP]
	Ubicar en el buscador de archivos dentro de la aplicación de escritorio de Github.
	
	![add](/Images/Cap_0/add.PNG) 
	
	Guardar una copia dentro del equipo del usuario. **Recordar la dirección donde se va a copiar el directorio**
	
	![copia](/Images/Cap_0/copia.PNG)

2. **Abrir** el archivo *simulador.stpr*. Es el *Stata project* que concentra todos los *do-files* y *ado-files* para su fácil acceso.
	
	![open_project](/Images/Cap_0/open_project.PNG)
	
3. **Abrir** el archivo *SIM5.do*. Es el *do-file* que arranca, genera, controla y modifica los parámetros de cada **simulación**[^1]. 
	
	![open_SIM](/Images/Cap_0/open_SIM.PNG)
	
4. **Definir** el directorio PERSONAL: ahí es desde donde se programará. Agregar el número de computadoras alternativas o secundarias desde donde se programará.
	Recordar que la dirección debe ser la misma donde se clonó el repositorio. 
	
	![sysdir](/Images/Cap_0/sysdir.PNG)
	
5. **Definir** el (los) superuser(s): estos son los que generarán las bases datos y outputs de default.

---
## Capítulo_0: Opciones



### Comandos para limpiar el ambiente 

Los primeros tres comandos nos permiten al programa limpiar en su totalidad el ambiente de trabajo. Primero eliminamos cualquier **variable** guardada en el programa. Segundo, utilizamos el comando macro para **manipular todas las macros** tanto globales como locales.  Por último, se cierran todos **los archivos tipo log** que puedan estar ejecutándose en el momento de iniciar a correr el simulador fiscal.  
	![limpiador](/Images/Cap_0/Limpiador.PNG)

### Arranque.do
El *Do.file llamado SIM* inicia otro *Do.file* llamado *Arranque.do*. Este archivo creo carpetas dentro de la direeción base, donde se irán almacenando los distintos archivos generados durante la simulación. 

## Capítulo_1: Población

## poblacion.do
OBJETIVO DE ESTE DO.FILE

### A. Población
Primero, importamos las bases de datos que utilizaremos en el modulo de población. 
En la sección de **población** la base es la “Base de datos de México: Población, defunciones y migración internacional” disponible en:

“../basesCIEP/CONAPO/ censo2020.dta” [^2]

Esta base nos dará a conocer los valores de la población separada por año, sexo y edad.  

Se realiza la limpieza de variables y los problemas derivados de los caracteres especiales. En este caso se corrigen las variables Año y sexo. Además, le ponemos label en STATA a las variables Población, Entidad Federativa y Año.
La variable población se convierte a string separada por comas y sin decimales, para facilitar su interpretación. 

Posteriormente se ordena y guardamos de manera temporal la base de datos, ya que procederemos a trabajar con otra base. 

![poblacion](/Images/Cap_1/poblacion.PNG)


### B. Defunciones

Primero, cargamos la base de datos para esta sección. En este caso el programa contempla las versiones posteriores de STATA 13.1 para realizar una codificación, caso contrario la carga de manera normal. 
En este caso la base de datos se encuentra disponible en la siguiente dirección: 

"`c(sysdir_site)'../basesCIEP/CONAPO/def_edad_proyecciones_n.csv" [^3]

Posteriormente se limpian las variables sexo, año y defunciones. Las primeras dos nos servirán para unir esta base con la base población, mientras que defunciones es una variable nueva y escrita en formato separada por comas sin decimales. 

El archivo se guarda de manera temporal para utilizarla posteriormente. 

![poblacion](/Images/Cap_1/defunciones.PNG)


### C. Migración internacional
Para cargar la base se debe usar la dirección: 

"`c(sysdir_site)'../basesCIEP/CONAPO/” 

Misma donde se encontra la base de población y también utilizando  la ubicación de nuestro directorio “c(sysdir_site)”.

Al igual que población y defunciones se debe cambiar el nombre de las variables para arreglar los caracteres especiales. En este caso las variables son Año, sexo inmigrantes y emigrantes.
Esta base de datos tiene valores entre rangos de edad y años; por lo que se debe ajustar al formato de las otras dos bases del módulo. Utilizando STATA se crean promedios para asignar valores uniformes entre los rangos de edad y año[^4].

![promedios_mig](/Images/Cap_1/promedios_mig.PNG)

Posteriormente de agregan las labels necesarias para emigrantes, inmigrantes, entidad y año. Guardamos la base con el nombre de migración y ya es posible **unir nuestras bases.**

### D.Unión

Recordemos que la última base utilizada fue *migración*, por lo que es la base de datos que el programa está usando actualmente, considerada como la base de datos en la memoria. Usando los comandos **“use” y “merge”** vamos a unir estás tablas por medio de las variables **“año” ,”edad”, “sexo” y “entidad”**. También limpiamos los valores nulos “.” , reemplazándolos por ceros.

Para calcular la **tasa de fecundidad** se filtra la base de datos de tal manera que tengamos el total de mujeres en edades fértiles y nacimientos por año.  Posteriormente se calculan las medias por año y con la siguiente formulas obtenemos la tasa de fecundidad por año (nacimientos cada 1000 mujeres en edades fértiles). 

<img src="https://render.githubusercontent.com/render/math?math=Tasa de fecundidad =\frac{Nacimientos}{Mujeres Fertiles}*1000">

![tasa_fecundidad](/Images/Cap_1/tasa_fecundidad.PNG)









[^1]: Se define como cada DO o RUN que ejecutamos en el Stata para calcular los resultados de un escenario económico particular (el default/oficial o el de un usuario).
[^2]: Recordemos que el directorio fue definido en el inicio del código, los “..” al inicio de la dirección es para regresar un directorio de donde nos encontrábamos antes. Regresamos de la dirección “/TemplatesCIEP/simuladorCIEP” a la dirección “/Templates” para después ingresar a “../basesCIEP/CONAPO/”. 

[^3]: Recordando que `c(sysdir_site)' contiene la dirección del directorio base.  
[^4]: Se debe asumir una distribución uniforme tanto en edad como en año. 

[Github]:https://github.com/

[simuladorCIEP]:https://github.com/rcantuc/simuladorCIEP
