****************************
*** 2 ECONOMIA Y CUENTAS ***													Cap. 3. Sistema: de Cuentas Nacionales
****************************
timer on 99
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY




***********************************
** PAR{c A'}METROS DEL SIMULADOR **

global id = "`id'"

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*adopath ++ PERSONAL
*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

* Crecimiento PIB *
global pib2020 = -3.9 // Precriterios 2021 [-3.9,0.1]
global pib2021 =  3.5 // Precriterios 2021 [1.5,3.5]
global pib2022 =  2.5 // CGPE 2020
global pib2023 =  2.6 // CGPE 2020
global pib2024 =  2.7 // CGPE 2020
global pib2025 =  2.7 // CGPE 2020

global def2020 =  3.5 // Precriterios 2021 [-3.9,0.1]
global def2021 =  3.2 // Precriterios 2021 [-3.9,0.1]
global def2022 =  3.5 // CGPE 2020
global def2023 =  3.5 // CGPE 2020
global def2024 =  3.5 // CGPE 2020
global def2025 =  3.5 // CGPE 2020


***********************************/




noisily PIBDeflactor, anio(`anio') `1' //nographs //update //discount(3.0)
save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
noisily SCN, anio(`anio') nographs




************************/
**** Touchdown!!! :) ****
*************************
timer off 99
timer list 99
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t99)/r(nt99)',.1) in g " segs  " _dup(20) "."
