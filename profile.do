**************
*** 1 CIEP ***
**************
clear all
set more off, permanently
set type double, permanently
set charset latin1, permanently

adopath ++ SITE
sysdir set PERSONAL "`c(sysdir_site)'"

set scheme ciep
graph set window fontface "Ubuntu"




***********************
*** 2 Par${a}metros ***
***********************
global anioVP = 2019

global pib2018 = 2.5
global pib2019 = 3.0

global def2018 = 4.8
global def2019 = 3.3

global depreMXN = 0.5

PIBDeflactor
clear




***************
*** 3 Texto ***
***************
noisily di _newline(2) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline in g "{bf:Pre-criterios Generales de Pol{c i'}tica Econ{c o'}mica" in y " 2019}"
noisily di _newline in g "A{c n~}o" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(64) %8.4fc "Deflactor"

forvalues k=2017(1)2020 {
	noisily di in g "`k' " _col(10) %8.4fc in y ${pib_`k'} " %" _col(25) %20.0fc ${PIB_`k'} _col(50) %8.4fc in y ${def_`k'} " %" _col(65) %8.4fc ${DEF_`k'}
}
