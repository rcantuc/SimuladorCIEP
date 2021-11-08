**************
*** 1 CIEP ***
**************
set more off, permanently
set type double, permanently
set charset latin1, permanently
set scheme ciepnew
graph set window fontface "Ubuntu"

* Directorios principales *
adopath ++ SITE
sysdir set PERSONAL "`c(sysdir_site)'"
cd "`c(sysdir_site)'"



********************
*** 2 Bienvenida ***
********************
noisily di _newline(3) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"




********************
*** 3 Parametros ***
********************
noisily di in g "Fuente:" in y " INEGI, BIE + {bf:CGPE 2022}"

* 2021-2026 *
global pib2021 = 6.3                                                            // CGPE 2022: 5.3
global pib2022 = 4.1                                                            // CGPE 2022: 3.6
global pib2023 = 3.4                                                            // Supuesto: 2.5
global pib2024 = 2.8                                                            // Supuesto: 2.5
global pib2025 = 2.5                                                            // Supuesto: 2.5
global pib2026 = 2.5                                                            // Supuesto: 2.5
global pib2027 = 2.5                                                            // Supuesto: 2.5

* 2026-2030 *
forvalues k=2028(1)2030 {
	global pib`k' = $pib2027                                                // SUPUESTO DE LARGO PLAZO
}

/* 2031-2050 *
forvalues k=2031(1)2050 {
	global pib`k' = $pib2027                                                // SUPUESTO DE LARGO PLAZO
}

* OTROS */
global inf2021 = 5.7                                                            // CGPE 2022: 3.8
global inf2022 = 3.4                                                            // CGPE 2022: 3.0
global inf2023 = 3.0                                                            // CGPE 2022: 3.0
global inf2024 = 3.0                                                            // CGPE 2022: 3.0
global inf2025 = 3.0                                                            // CGPE 2022: 3.0
global inf2026 = 3.0                                                            // CGPE 2022: 3.0
global inf2027 = 3.0                                                            // CGPE 2022: 3.0

global def2021 = 6.2295                                                         // CGPE 2022: 3.7
global def2022 = 3.7080                                                         // CGPE 2022: 3.2




*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily PIBDeflactor, nographs nooutput anio(2022) geopib(2010) geodef(2010) //update
clear
