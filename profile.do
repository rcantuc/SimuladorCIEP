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
noisily di in g "Fuente:" in y " INEGI, BIE + {bf:Pre-CGPE 2022}"

* 2021-2026 *
global pib2021 = 5.3                                                        // Pre-CGPE 2022: 5.3
global pib2022 = 3.6                                                        // Pre-CGPE 2022: 3.6
global pib2023 = 2.5                                                        // Supuesto: 2.5
global pib2024 = 2.5                                                        // Supuesto: 2.5
global pib2025 = 2.5                                                        // Supuesto: 2.5
global pib2026 = 2.5                                                        // Supuesto: 2.5

* 2026-2030 *
forvalues k=2027(1)2030 {
	global pib`k' = $pib2026                                                // SUPUESTO DE LARGO PLAZO
}

/* 2031-2050 *
forvalues k=2031(1)2050 {
	global pib`k' = $pib2025                                                // SUPUESTO DE LARGO PLAZO
}

* OTROS */
global inf2021 = 3.8                                                        // Pre-CGPE 2022: 3.8
global inf2022 = 3.0                                                        // Pre-CGPE 2022: 3.0

global def2021 = 3.7393                                                     // Pre-CGPE 2022: 3.7
global def2022 = 3.2820                                                     // Pre-CGPE 2022: 3.2

global tasaEfectiva = 6.7445                                                // Tasa de inter{c e'}s EFECTIVA
global tipoDeCambio = 19.9487                                               // Tipo de cambio
global depreciacion = 0.0000                                                // Depreciaci{c o'}n



*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily PIBDeflactor, nographs nooutput anio(2022) update
clear
