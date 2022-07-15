# PIB y su deflactor
    Versión: 14 de julio de 2022. Autor: Ricardo

Para actualizar los valores del **PIB trimestral** y del **Índice precios implícitos trimestral**, ir a:

[Cómo actualizar el SCN](Actualizar el SCN.md)

---

## UpdatePIBDeflactor.do

### Base de datos INEGI/BIE: PIB
1. **Importar** y **limpiar** la base de datos del PIB, publicada por el Banco de Información Económica (BIE) del INEGI.

    ![PIBBIE](images/Cap_0/PIBBIE.png)


### Base de datos INEGI/BIE: Deflactor de precios
1. **Importar** y **limpiar** la base de datos del PIB, publicada por el Banco de Información Económica (BIE) del INEGI.

    ![DeflactorBIE](images/Cap_0/DeflactorBIE.png)


### Unión de bases: PIB + Deflactor
1. **Unir** las bases de datos limpias del *PIB* y el *Deflactor*.

    ![UnionPIBDeflactor](images/Cap_0/UnionPIBDeflactor.png)

2. Al finalizar, **aparecerá una gráfica** con la información alimentada. Este paso significa que el *do-file* corrió sin errores. **¡Felicidades!**

    ![GPIBQ](images/Cap_0/UpdatePIBDeflactor.png)

FIN de `UpdatePIBDeflactor.do`

---

## PIBDeflactor.ado


FIN de `PIBDeflactor.ado`
