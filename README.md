# Simulador Fiscal CIEP v5.0

	Versión: 4/marzo/2021

¡Bienvenidxs al equipo!

El Simulador Fiscal CIEP está (actualmente) programado en **Stata** (versiones 13+). Sin embargo, se pudieran incorporar otros programas como **R** u otros lenguajes como **PHP**.


**La misión**:  
Construir una red de programadores que use, estudie, mejore, facilite, actualice y automatice las necesidades del Simulador Fiscal CIEP en su versiones consecuentes. Es una herramienta comunitaria y participativa que puede ser utilizada para fines didácticos y analíticos.

---

Los pasos para empezar a **colaborar** (actualmente, sólo bajo invitación):

1. **Clonar** el repositorio del Simulador Fiscal CIEP disponible desde [Github][]: [rcantuc/simuladorCIEP][simuladorCIEP]
2. **Abrir** el archivo *simulador.stpr*. Es el *Stata project* que concentra todos los *do-files* y *ado-files* para su fácil acceso.
3. **Abrir** el archivo *SIM5.do*. Es el *do-file* que arranca, genera, controla y modifica los parámetros de cada **simulación**[^1].
4. **Definir** el directorio PERSONAL: ahí es desde donde se programará. Agregar el número de computadoras alternativas o secundarias desde donde se programará.
5. **Definir** el (los) superuser(s): estos son los que generarán las bases datos y outputs de default.

---
## Capítulo_0: Opciones
###Comandos para limpiar el ambiente 
Los primeros tres comandos permiten al programa limpiar en su totalidad el ambiente de trabajo. Primero eliminamos cualquier **variable** guardada en el programa. Segundo, utilizamos el comando macro para **manipular todas las macros** tanto globales como locales.  Por último, se cierran todos **los archivos tipo log** que puedan estar ejecutándose en el momento de iniciar a correr el simulador fiscal.  
![limpiador](/Images/Cap_0/Limpiador.PNG)

### Pendiente_ programación







[^1]: Se define como cada DO o RUN que ejecutamos en el Stata para calcular los resultados de un escenario económico particular (el default/oficial o el de un usuario).

[Github]:https://github.com/

[simuladorCIEP]:https://github.com/rcantuc/simuladorCIEP
