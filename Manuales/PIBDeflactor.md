# PIB y su deflactor
    Versión: 14 de julio de 2022. Autor: Ricardo

---

## UpdatePIBDeflactor.do
**Actualiza** la base de datos del simulador [`c(sysdir_site)/SIM/PIBDeflactor.dta`] con la información presente en los archivos[^1]:

- `c(sysdir_site)/bases/UPDATE/SCN/PIB.xlsx`
- `c(sysdir_site)/bases/UPDATE/SCN/deflactor.xlsx`

[^1]: Para saber cómo actualizar los valores presentes en los archivos `PIB.xlsx` y `deflactor.xlsx` con los más recientes publicados por el INEGI, ir a: [Actualizar el SCN](Actualizar el SCN.md).


### 1. Base de datos INEGI/BIE: PIB
**Importar** y **limpiar** la base de datos del PIB, publicada por el Banco de Información Económica (BIE) del INEGI.

![PIBBIE](images/Cap_0/PIBBIE.png)


### 2. Base de datos INEGI/BIE: Deflactor de precios
**Importar** y **limpiar** la base de datos del PIB, publicada por el Banco de Información Económica (BIE) del INEGI.

![DeflactorBIE](images/Cap_0/DeflactorBIE.png)


### 3. Unión de datos y guardar base final
**Unir** las bases de datos limpias del *PIB* y el *Deflactor*. Adicionalmente, se **genera** la variable `aniotrimestre`, el cual será utilizado para definir la serie de tiempo. El archivo final, en formato `Stata 13`, se guarda en `c(sysdir_site)/SIM/PIBDeflactor.dta`.

![UnionPIBDeflactor](images/Cap_0/UnionPIBDeflactor.png)


### 4. Finalización
Al finalizar, **aparecerá una gráfica** con la información alimentada. Este paso significa que el *do-file* corrió sin errores. **¡Felicidades!**

![GPIBQ](images/Cap_0/UpdatePIBDeflactor.png)

FIN de `UpdatePIBDeflactor.do`

---

## PIBDeflactor.ado


### Sintaxis
`PIBDeflactor` [*if*] [*, UPDATE ANIOvp(int) NOGraphs GEOPIB(int) GEODEF(int) NOOutput SAVE*]

**Opciones**

- **update**: ejecuta el *do-file* `UpdatePIBDeflactor.do`[^2].
- **aniovp**: cambia el año de referencia para calcular el *valor presente*. Tiene que ser un íntegro (i.e. no número fraccionado) entre 1993 (mínimo reportado por el INEGI/BIE) y 2050 (máximo proyectado por el CONAPO, en su base de población). El *default* es el año corriente.
- **nographs**: evita que se despliguen las gráficas generadas por el comando (para mayor velocidad de ejecución).
- **geopib**:
- **geodef**:
- **fin**:
- **nooutput**:
- **save**:

[^2]: Este comando/opción se debe realizar *solamente una vez*, hasta la próxima actualización (próximo trimestre).


### 1. Bases de datos

**Poblacion.dta**


**PIBDeflactor.dta**




### 4. Variables en términos reales


### 5. Imputar parámetros


### 6. Proyecciones


### 7. Gráficas y textos


### 8. Finalización

FIN de `PIBDeflactor.ado`
