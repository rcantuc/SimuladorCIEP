**************
*** 1 CIEP ***
**************
clear all
set scheme ciepnew
graph set window fontface "Ubuntu"

set more off, permanently
set type double, permanently
set charset latin1, permanently

sysdir set PERSONAL "`c(sysdir_site)'"



**************
* Bienvenida *
noisily di _newline(3) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"




*********************************
*** 2 Par{c a'}metros de CGPE ***
*********************************
// Incorporar los que sean necesarios seg{c u'}n su a{c n~}o //
global pib2020 = -1.9			// Pre-criterios 2021 [-3.9,0.1]
global def2020 = 3.5			// Pre-criterios 2021

global pib2021 = 2.5			// Pre-criterios 2021 [1.5,3.5]
global def2021 = 3.2			// Pre-criterios 2021

noisily di _newline in g "{bf:Pre-criterios" in y " 2021}"
noisily PIBDeflactor
clear
