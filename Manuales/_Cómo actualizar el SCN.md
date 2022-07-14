# Sistema de Cuentas Nacionales (SCN)
	Versión: 12 julio 2022. Último programador: Ricardo

**Objetivo**: *Actualizar*, con los valores más recientes publicados por el INEGI, los archivos dentro de la carpeta `c(sysdir_site)/UPDATE/SCN/` que utilizan los comandos del Simulador Fiscal CIEP v5: 

`SCN` 
`PIBDeflactor`
`Inflacion` 

-
### Pasos a seguir 
Se requiere forzosamente de un **Excel para Windows**. Dentro de la carpeta `c(sysdir_site)/UPDATE/SCN/`:

1. **Doble click** a _todos los archivos_ con terminación .IQY. El Excel empezará automáticamente a descargar la información del INEGI (posiblemente te pida habilitar el uso de "macros").
3. **Guardar** y **reemplazar**, con el nuevo archivo descargado, el archivo con terminación .xlsx (Excel) que está bajo el _mismo nombre_.
4. En Stata, ejecutar los siguientes comandos:

`SCN, update` 
`PIBDeflactor, update`
`Inflacion, update` 

