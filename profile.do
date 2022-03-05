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
run "`c(sysdir_personal)'/PARAM${pais}.do"





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
