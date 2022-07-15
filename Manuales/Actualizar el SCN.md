# Sistema de Cuentas Nacionales (SCN)
	Versión: 12 julio 2022. Último programador: Ricardo

## Objetivo
**Saber actualizar**, con los valores más **recientes publicados** por el INEGI, los archivos dentro de la carpeta `c(sysdir_site)/UPDATE/SCN/` que actualmente utilizan los comandos del Simulador: 

- `PIBDeflactor`

- `SCN`

- `Inflacion`


## Pasos a seguir
    Se requiere forzosamente de Excel para Windows.

Dentro de la carpeta `c(sysdir_site)/UPDATE/SCN/`:

1. **Doble click** a _todos los archivos_ con terminación .IQY. El Excel empezará automáticamente a descargar la información del INEGI (posiblemente te pida habilitar el uso de "macros").
3. **Guardar** y **reemplazar**, con el nuevo archivo descargado, el archivo con terminación .xlsx (Excel) que está bajo el _mismo nombre_ que su .IQY.
4. En Stata, **ejecutar** los siguientes comandos:

    - `PIBDeflactor, update`

    - `SCN, update`

    - `Inflacion, update`

