******************************
** 8 Cuentas Generacionales **
******************************
timer on 96
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY
local anio = 2021




***********************************
** PAR{c A'}METROS DEL SIMULADOR **

global id = "$id"

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*adopath ++ PERSONAL
*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

***********************************/




******************************
*** 5 Transferencias Netas ***
******************************
capture g AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
if _rc != 0 {
	replace AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
}
label var AportacionesNetas "de las aportaciones netas"
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace

noisily Simulador AportacionesNetas if AportacionesNetas != 0 [fw=factor], ///
	base("ENIGH 2018") boot(1) reboot graphs //output

noisily CuentasGeneracionales AportacionesNetas, anio(`anio') output //boot(250) //	<-- OPTIONAL!!! Toma mucho tiempo.


use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
replace estimacion = estimacion/1000000000000

tabstat estimacion, stat(max) save
tempname MAX
matrix `MAX' = r(StatTotal)

forvalues k=1(1)`=_N' {
	if estimacion[`k'] == `MAX'[1,1] {
		local aniomax = anio[`k']
	}
}

twoway connected estimacion anio, ///
	ytitle("billiones MXN `anio'") ///
	yscale(range(0)) /*ylabel(0(1)4)*/ ///
	ylabel(, format(%20.1fc) labsize(small)) ///
	xlabel(, labsize(small) labgap(2)) ///
	xtitle("") ///
	xline(`anio', lpattern(dash) lcolor("52 70 78")) ///
	text(`=`MAX'[1,1]' `aniomax' "{bf:M{c a'}ximo:} `aniomax'", place(n)) ///
	title("{bf:Proyecciones} de las aportaciones netas") subtitle("$pais") ///
	caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5." "Fecha: `c(current_date)', `c(current_time)'.") ///
	name(AportacionesNetasProj, replace)

* Output */
forvalues k=1(10)`=_N' {
	local out_proy = "`out_proy' `=string(estimacion[`k'],"%8.3f")',"
}

local lengthproy = strlen("`out_proy'")
noisily di in w "PROY: [`=substr("`out_proy'",1,`=`lengthproy'-1')']"
noisily di in w "PROYMAX: [`aniomax']"





************************/
**** Touchdown!!! :) ****
*************************
timer off 96
timer list 96
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t96)/r(nt96)',.1) in g " segs  " _dup(20) "."
