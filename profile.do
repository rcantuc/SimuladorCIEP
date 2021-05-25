**************
*** 1 CIEP ***
**************
set scheme ciepnew
graph set window fontface "Ubuntu"

set more off, permanently
set type double, permanently
set charset latin1, permanently

adopath ++ SITE				// SUBIR DIRECTORIO SITE COMO EL PRINCIPAL
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

global pib2021 =  5.3                                                           // Pre-CGPE 2022: 5.3
global pib2022 =  3.6                                                           // Pre-CGPE 2022: 3.6
global pib2023 =  2.5
global pib2024 =  2.5
global pib2025 =  2.5

* 2026-2030 *
global pib2026 = $pib2025
global pib2027 = $pib2025
global pib2028 = $pib2025
global pib2029 = $pib2025
global pib2030 = $pib2025

/* 2031+ (incoporar mas segun anio) *
global pib2031 = $pib2025
global pib2032 = $pib2025
global pib2033 = $pib2025
global pib2034 = $pib2025
global pib2035 = $pib2025
global pib2036 = $pib2025
global pib2037 = $pib2025
global pib2038 = $pib2025
global pib2039 = $pib2025
global pib2040 = $pib2025
global pib2041 = $pib2025
global pib2042 = $pib2025
global pib2043 = $pib2025
global pib2044 = $pib2025
global pib2045 = $pib2025
global pib2046 = $pib2025
global pib2047 = $pib2025
global pib2048 = $pib2025
global pib2049 = $pib2025
global pib2050 = $pib2025


* OTROS (idem) */
global def2021 = 3.7393                                                         // Pre-CGPE 2022: 3.7
global def2022 = 3.2820                                                         // Pre-CGPE 2022: 3.2
global inf2021 = 3.8                                                            // Pre-CGPE 2022: 3.8
global inf2022 = 3.0                                                            // Pre-CGPE 2022: 3.0



*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily PIBDeflactor, nographs nooutput anio(2021) save //update
clear
