******************************
** 8 Cuentas Generacionales **
******************************
timer on 96
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
global id = "Ricardo"




******************************
*** 5 Transferencias Netas ***
******************************
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
capture g TransfNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
if _rc != 0 {
	replace TransfNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
}
label var TransfNetas "Transferencias Netas"
Simulador TransfNetas if TransfNetas != 0 [fw=factor], base("ENIGH 2018") boot(1) graphs reboot
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace




****************
*** 7 SANKEY ***
****************
foreach k in sexo grupo_edad decil escol {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `anio'
}




********************
*** 8 FISCAL GAP ***
********************
noisily FiscalGap, graphs end(2050) //boot(250) //update




**************************
* Cuentas generacionales *
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
noisily CuentasGeneracionales TransfNetas, //boot(250)								// <-- OPTIONAL!!! Toma mucho tiempo.




************************/
**** Touchdown!!! :) ****
*************************
timer off 96
timer list 96
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t96)/r(nt96)',.1) in g " segs  " _dup(20) "."
