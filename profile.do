**************
*** 1 CIEP ***
**************
clear all
set more off, permanently
set type double, permanently
set charset latin1, permanently
set scheme ciep
graph set window fontface "Ubuntu"




*************************
*** 2 Par{c a'}metros ***
************************
global pib2019 = 2.0
global def2019 = 3.9

PIBDeflactor



***************
*** 3 Texto ***
***************
noisily di _newline(2) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline in g "{bf:BIE + CGPE" in y " 2019}"
noisily di _newline in g "A{c n~}o" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(67) %8.4fc "Deflactor"

forvalues k=2017(1)2020 {
	if `k' == 2019 {
		local before "{bf:"
		local after "}"
	}
	noisily di in g "`before'`k' " _col(10) %8.4fc in y ${pib_`k'} " %" _col(25) %20.0fc ${PIB_`k'} _col(50) %8.4fc in y ${def_`k'} " %" _col(65) %12.8fc ${DEF_`k'} "`after'"
}
	
clear
