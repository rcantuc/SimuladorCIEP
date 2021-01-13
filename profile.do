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
noisily di in w "¡Feliz de verte! Las 7 necesidades b{c a'}sicas para una mejor salud:"
noisily di in w "1) Respira profundamente. 2) Toma mucha agua. 3) Duerme bien. 4) Come saludablemente."
noisily di in w "5) Limpia tu casa y tu cuerpo de toxinas. 6) R{c i'}e y rod{c e'}ate de gente querida."
noisily di in w "7) Expr{c e'}sate creativamente."




*********************************
*** 3 Par{c a'}metros de CGPE ***
*********************************
noisily di _newline in g "{bf:Paquete Econ{c o'}mico" in y " CGPE 2021" in g "}"

// Incorporar los que sean necesarios seg{c u'}n su a{c n~}o //
*global pib2020 = -8.0
global pib2021 =  4.6
global pib2022 =  2.6
global pib2023 =  2.5
global pib2024 =  2.5
global pib2025 =  2.5

*global def2020 =  3.568
global def2021 =  3.425




*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily PIBDeflactor, nographs nooutput anio(2021) //update
clear
