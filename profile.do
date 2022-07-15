**************
*** 1 CIEP ***
**************
set more off, permanently
set type double, permanently
set charset latin1, permanently
set scheme ciepnew
graph set window fontface "Ubuntu"



********************
*** 2 Bienvenida ***
********************
noisily di _newline(5) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"



********************
*** 3 Parametros ***
********************
global paqueteEconomico "CGPE 2022"
run "`c(sysdir_site)'/PARAM.do"

di "Econom{c i'}a"

*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily di _newline in g "{bf:Bienvenidxs al Simulador Fiscal CIEP v5.2.}" ///
	_newline(2) _col(3) "CLICK para ejecutar los siguientes comandos disponibles." ///
	_newline _col(3) "O usar la siguiente sintaxis: " ///
	_newline(2) _col(3) "{it:Comando} [OPCIONES DISPONIBLES]"
noisily di _newline `"{stata "Poblacion":Poblacion} [, ANIOhoy(int) ANIOFinal(int) NOGraphs UPDATE]"'
noisily di `"{stata "PIBDeflactor, nooutput geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs UPDATE]"'
noisily di `"{stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs UPDATE]"'
noisily di `"{stata "SCN":SCN} [, ANIO(int) NOGraphs UPDATE]"'
noisily di `"{stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE]"'
noisily di `"{stata "PEF":PEF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE]"'
noisily di `"{stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs UPDATE]"' 
noisily di `"{stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real 1993) MES UPDATE]"' 





