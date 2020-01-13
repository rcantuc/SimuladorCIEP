**************
*** 1 CIEP ***
**************
clear all
set scheme ciepnew
graph set window fontface "Ubuntu"

set more off, permanently
set type double, permanently
set charset latin1, permanently



**************
* Bienvenida *
noisily di _newline(2) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"





*********************************
*** 2 Par{c a'}metros de CGPE ***
*********************************
// Incorporar los que sean necesarios seg{c u'}n su a{c n~}o //
global pib2019 = 1.1227
global def2019 = 4.5
global pib2020 = 1.9717
global def2020 = 3.6

noisily di _newline(3) in g "{bf:Paquete Econ{c o'}mico" in y " 2020}"
noisily PIBDeflactor
clear
