**************
*** 1 CIEP ***
**************
clear all
macro drop _all
capture log close _all
set more off, permanently
set type double, permanently
set charset latin1, permanently
set scheme ciepnew
graph set window fontface "Ubuntu"
sysdir set PERSONAL "`c(sysdir_site)'"



********************
*** 2 Bienvenida ***
********************
timer on 1
noisily di _newline(5) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"



********************
*** 3 Parametros ***
********************
run "`c(sysdir_personal)'/PARAM.do"



*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily di _newline in g `"{bf:{stata `"projmanager "`c(sysdir_site)'/simulador.stpr""':Simulador Fiscal CIEP v5.5 (Subnacional)}}"' ///
	_newline(2) _col(3) "CLICK para ejecutar los siguientes comandos disponibles." ///
	_newline _col(3) "O usar la siguiente sintaxis: " ///
	_newline(2) _col(3) "{bf:Comando} {it:argumentos} [, OPCIONES]"
noisily di _newline `"{stata "Poblacion":Poblacion} [if entidad == "{it:Nombre con acentos}"] [, ANIOhoy(int) ANIOFINal(int) NOGraphs UPDATE]"'
noisily di `"{stata "PIBDeflactor, geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs UPDATE]"'
noisily di `"{stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs UPDATE]"'
noisily di `"{stata "SCN":SCN} [, ANIO(int) NOGraphs UPDATE]"'
noisily di `"{stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE BASE]"'
noisily di `"{stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE BASE]"'
noisily di `"{stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs UPDATE]"' 
noisily di `"{stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES UPDATE]"' 
noisily di `"{stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `"{stata "GastoPC":GastoPC} [, ANIO(int)]"'
