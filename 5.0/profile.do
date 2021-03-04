**************
*** 1 CIEP ***
**************
set scheme ciepnew
graph set window fontface "Ubuntu"

set more off, permanently
set type double, permanently
set charset latin1, permanently

sysdir set PERSONAL "`c(sysdir_site)'"
cd "`c(sysdir_site)'"



********************
*** 2 Bienvenida ***
********************
noisily di _newline(3) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"




*********************************
*** 3 Par{c a'}metros de CGPE ***
*********************************
noisily di _newline in g "{bf:Fuente}:" in y " Paquete Econ{c o'}mico CGPE 2021 + BIE, INEGI"

// Incorporar los que sean necesarios seg{c u'}n su a{c n~}o //
global pib2021 =  4.6
global pib2022 =  2.6
global pib2023 =  2.5
global pib2024 =  2.5
global pib2025 =  2.5

global def2021 =  3.425




*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily PIBDeflactor, nographs nooutput anio(2021) //update
clear
