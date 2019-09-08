**************
*** 1 CIEP ***
**************
clear all
set more off, permanently
set type double, permanently
set charset latin1, permanently
set scheme ciep
graph set window fontface "Ubuntu"




*********************************
*** 2 Par{c a'}metros de CGPE ***
*********************************
// Incorporar los que sean necesarios seg{c u'}n su a{c n~}o //
global pib2019 = 1.1227
global def2019 = 4.5
global pib2020 = 1.9717
global def2020 = 3.6

global anioVP = 2020
PIBDeflactor




***************
*** 3 Texto ***
***************
noisily di _newline(2) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline in g "{bf:BIE + CGPE" in y " $anioVP}"
noisily di _newline in g "A{c n~}o" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(67) %8.4fc "Deflactor"

forvalues k=`=$anioVP-2'(1)`=$anioVP+2' {
	if `k' == $anioVP {
		local before "{bf:"
		local after "}"
	}
	noisily di in g "`before'`k' " _col(10) %8.4fc in y ${pib_`k'} " %" _col(25) %20.0fc ${PIB_`k'} _col(50) %8.4fc in y ${def_`k'} " %" _col(65) %12.8fc ${DEF_`k'} "`after'"
}
	
clear
