******************************
** 8 Cuentas Generacionales **
******************************
timer on 96
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY




***********************************
** PAR{c A'}METROS DEL SIMULADOR **

global id = "`1'"

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*adopath ++ PERSONAL
*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

***********************************/




******************************
*** 5 Transferencias Netas ***
******************************
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
capture g AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
if _rc != 0 {
	replace AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
}
label var AportacionesNetas "Aportaciones P{c u'}blicas Netas"

noisily Simulador AportacionesNetas if AportacionesNetas != 0 [fw=factor], base("ENIGH 2018") boot(1) graphs reboot
noisily CuentasGeneracionales AportacionesNetas, //boot(250)					// <-- OPTIONAL!!! Toma mucho tiempo.

save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
twoway connected estimacion anio, ///
	ytitle("millions `currency' `anio'") ///
	yscale(range(0)) /*ylabel(0(1)4)*/ ///
	ylabel(, format(%20.0fc) labsize(small)) ///
	xlabel(, labsize(small) labgap(2)) ///
	xtitle("") ///
	xline(`anio', lpattern(dash) lcolor("52 70 78")) ///
	///text(2 `=`aniobase'-1' "{bf:A{c n~}o base:} `anio'", place(w)) ///
	title("{bf:Proyecciones} de las aportaciones p{c u'}blicas netas") subtitle("$pais") ///
	caption("{it:Fuente: Elaborado con el Simulador Fiscal CIEP v5.}" "Fecha: `c(current_date)', `c(current_time)'.") ///
	name(AportacionesNetasProj, replace)

	
***************/
*** 7 SANKEY ***
/****************
run "`c(sysdir_personal)'/3GastosWeb.do"
run "`c(sysdir_personal)'/4IngresosWeb.do"

foreach k in sexo escol grupo_edad decil {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `anio'
}




*******************/
*** 8 FISCAL GAP ***
********************
noisily FiscalGap, graphs end(2050) //boot(250) //update




************************/
**** Touchdown!!! :) ****
*************************
timer off 96
timer list 96
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t96)/r(nt96)',.1) in g " segs  " _dup(20) "."
