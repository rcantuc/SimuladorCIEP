****************************
*** 2 ECONOMIA Y CUENTAS ***													Cap. 3. Sistema: de Cuentas Nacionales
****************************
timer on 99
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
global id = "Ricardo"
capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"




***********************************
** PAR{c A'}METROS DEL SIMULADOR **

*global pib2020 = -1.9 // 														Pre-criterios 2021 [-3.9,0.1]
*global pib2021 =  2.5 // 														Pre-criterios 2021 [1.5,3.5]
*global pib2022 =  1.2 //														Proyecci{c o'}n
*global pib2023 =  1.1 //														Proyecci{c o'}n
*global pib2024 =  1.1 //														Proyecci{c o'}n
*global pib2025 =  1.1 //														Proyecci{c o'}n

global pib2020 =  2.0 //														Criterios 2020
global def2020 = 3.6 // 														Criterios 2020
*global def2021 = 3.2 // 														Pre-criterios 2021


***********************************/



noisily PIBDeflactor, `1' //nographs //update //discount(3.0)
save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
noisily SCN, anio(`anio') `1'




************************/
**** Touchdown!!! :) ****
*************************
timer off 99
timer list 99
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t99)/r(nt99)',.1) in g " segs  " _dup(20) "."
