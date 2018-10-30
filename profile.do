**************
*** 1 CIEP ***
**************
set more off, permanently
set type double, permanently
set scheme ciep
graph set window fontface "Ubuntu"
*set charset latin1, permanently
*run `"`=c(sysdir_site)'acentos.do"'





*******************
*** 2 Simulador ***
*******************
*global simuladorCIEP "4.10.1 (BID-SHCP)"
*sysdir set PERSONAL `"`=c(sysdir_site)'../simuladorCIEP/"'





********************
*** 3 Parametros ***
********************
global pib2018 = 2.5
global pib2019 = 3.0

global def2018 = 4.8
global def2019 = 3.3

global depreMXN = 0.5





*****************
*** 4 General *** 
*****************
global anioVP = 2019
PIBDeflactor, globals
clear





***************
*** 5 Texto ***
***************
noisily di _newline(2) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline in g "{bf:Pre-criterios Generales de Pol{c i'}tica Econ{c o'}mica" in y " 2019}"
noisily di _newline in g "" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(64) %8.4fc "Deflactor"

forvalues k=2017(1)2020 {
	noisily di in g "`k' " _col(10) %8.4fc in y ${pib`k'} " %" _col(25) %20.0fc ${PIB`k'} _col(50) %8.4fc in y ${def`k'} " %" _col(65) %8.4fc ${DEF`k'}
}
