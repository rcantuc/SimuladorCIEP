********************
*** 9 FISCAL GAP ***
********************
timer on 95
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY
local anio = 2020





***********************************
** PAR{c A'}METROS DEL SIMULADOR **

global id = "$id"

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*adopath ++ PERSONAL
*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

***********************************/





***************/
*** 1 SANKEY ***
****************
run "`c(sysdir_personal)'/3GastosWeb.do" fast
run "`c(sysdir_personal)'/4IngresosWeb.do" fast

foreach k in sexo escol grupo_edad decil {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `anio'
}





*******************/
*** 2 FISCAL GAP ***
********************
noisily FiscalGap, anio(`anio') graphs end(2030) output //boot(250) //update





************************/
**** Touchdown!!! :) ****
*************************
timer off 95
timer list 95
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t95)/r(nt95)',.1) in g " segs  " _dup(20) "."
