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
noisily di _newline(5) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"




********************
*** 3 Parametros ***
********************
global paqueteEconomico "CGPE 2022"

* 2021-2026 *
global pib2022 = 4.1                                                            // CGPE 2022
global pib2023 = 3.4                                                            // CGPE 2022
global pib2024 = 2.8                                                            // CGPE 2022
global pib2025 = 2.5                                                            // CGPE 2022
global pib2026 = 2.5                                                            // CGPE 2022
global pib2027 = 2.5                                                            // CGPE 2022

global def2022 = 3.7                                                            // CGPE 2022


* 2026-2030 *
forvalues k=2028(1)2030 {
	global pib`k' = $pib2027                                                    // SUPUESTO DE LARGO PLAZO
}

/* 2031-2050 *
forvalues k=2031(1)2050 {
	global pib`k' = $pib2027                                                    // SUPUESTO DE LARGO PLAZO
}

* OTROS */
global inf2022 = 3.4                                                            // CGPE 2022
global inf2023 = 3.0                                                            // CGPE 2022
global inf2024 = 3.0                                                            // CGPE 2022
global inf2025 = 3.0                                                            // CGPE 2022
global inf2026 = 3.0                                                            // CGPE 2022
global inf2027 = 3.0                                                            // CGPE 2022





*************************/
*** 4 Informaci{c o'}n ***
**************************
noisily di _newline(2) in g "{bf:Bienvenidxs}." _newline "Hacer CLICK para ejecutar los siguientes comandos disponibles."
noisily di _newline `"{stata "noisily PIBDeflactor, nooutput geopib(2010) geodef(2010)":PIBDeflactor}"' _col(20) " para los valores del PIB y del deflactor."
noisily di `"{stata "noisily Poblacion":Poblacion}"' _col(20) " para las proyecciones demogr{c a'}ficas."
noisily di `"{stata "noisily Inflacion":Inflacion}"' _col(20) " para el INPC."
noisily di `"{stata "noisily SCN":SCN}"' _col(20) " para el Sistema de Cuentas Nacionales."
noisily di `"{stata "noisily LIF":LIF}"' _col(20) " para la Ley de Ingresos de la Federaci{c o'}n."
noisily di `"{stata "noisily PEF":PEF}"' _col(20) " para el Prespuesto de Egresos de la Federaci{c o'}n."
noisily di `"{stata "noisily SHRFSP":SHRFSP}"' _col(20) " para el Saldo Hist{c o'}rico de RFSP."
