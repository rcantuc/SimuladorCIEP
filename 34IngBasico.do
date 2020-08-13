** 3.4 Ingreso b{c a'}sico **
timer on 95
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
global id = "Ricardo"



*******************
* Microsimulacion *
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
noisily Simulador IngBasico if IngBasico != 0 [fw=factor], base("ENIGH 2018") boot(1) graphs reboot



************************/
**** Touchdown!!! :) ****
*************************
timer off 95
timer list 95
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t95)/r(nt95)',.1) in g " segs  " _dup(20) "."
