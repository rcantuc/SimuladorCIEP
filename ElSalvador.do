*****************************************************
****    SECTION FOR PROGRAMMING PURPOSES ONLY    ****
****         MUST BE COMMENTED OTHERWISE         ****
*****************************************************
clear all
macro drop _all
capture log close _all
if "`c(username)'" == "ricardo" {
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}
if "`c(username)'" == "ciepmx" {
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}


***********************************/
** PARAMETROS SIMULADOR: OPCIONES **
global pais = "El Salvador"			// Comentar o "" (vacío) para Mexico
*global nographs = "nographs"
** PARAMETROS SIMULADOR: OPCIONES **
************************************




************************/
***                   ***
***    0. ARRANQUE    ***
***                   ***
*************************
timer on 1
noisily di _newline(50) _col(35) in w "Simulador Fiscal CIEP v5.0" ///
	_newline _col(43) in y "$pais"


** DIRECTORIOS **
adopath ++ PERSONAL
cd "`c(sysdir_personal)'"
capture mkdir "`c(sysdir_personal)'/SIM/"
capture mkdir "`c(sysdir_personal)'/users/"
capture mkdir "`c(sysdir_personal)'/users/$id/"
capture mkdir "`c(sysdir_personal)'/users/$pais/"


** AÑO VALOR BASE **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
local aniovp = 2021




************************************************************
***                                                      ***
***    1. SET-UP: Cap. 3. La economia antropocentrica    ***
***                                                      ***
************************************************************


** POBLACION **
Poblacion, anio(`aniovp') $nographs //update //tf(`=64.333315/2.2*2.07') //tm2044(18.9) tm4564(63.9) tm65(35.0) //aniofinal(2040)


** HOUSEHOLDS **
capture confirm file `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC.dta"'
if _rc != 0 {
	local id = "$id"
	global id = ""
	noisily run `"`c(sysdir_personal)'/Households`=subinstr("${pais}"," ","",.)'.do"' `aniovp'
	global id = "`id'"
}




*********************************************/
***                                        ***
***    2. Simulador v5: PIB + Deflactor    ***
***    Cap. 2. El sistema de la ciencia    ***
***                                        ***
**********************************************


*******************************
** PARAMETROS SIMULADOR: PIB **
global pib2020 = -7.200
global pib2021 =  4.600

global pib2022 =  3.100
global pib2023 =  2.500
global pib2024 =  2.500
global pib2025 =  2.500
global pib2026 =  2.500
global pib2027 =  2.500
global pib2028 =  2.500
global pib2029 =  2.500
global pib2030 =  2.500

global def2020 =  0.383
global def2021 =  0.512
** PARAMETROS SIMULADOR: PIB **
*******************************


noisily PIBDeflactor, anio(`aniovp') $nographs //geo(`geo') //discount(3.0)
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
}




*********************************/
***                            ***
***    3. PARTE III: GASTOS    ***
***                            ***
**********************************
noisily GastoPC, anio(`aniovp') `nographs' crec(0.92)




**********************************/
***                             ***
***    4. PARTE II: INGRESOS    ***
***                             ***
***********************************
noisily TasasEfectivas, anio(`aniovp') `nographs' crec(1.02)




****************************************/
***                                   ***
***    5. PARTE IV: REDISTRIBUCION    ***
***                                   ***
*****************************************
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
capture g AportacionesNetas = (Laboral + Consumo + ISR__PM + ing_cap_fmp) ///
	+ (- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra)
if _rc != 0 {
	replace AportacionesNetas = (Laboral + Consumo + ISR__PM + ing_cap_fmp) ///
	+ (- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra)
}
label var AportacionesNetas "las aportaciones netas"
noisily Simulador AportacionesNetas if AportacionesNetas != 0 [fw=factor], ///
	base("ENIGH 2018") boot(1) reboot nographs anio(`aniovp')


** CUENTA GENERACIONAL **/
*noisily CuentasGeneracionales AportacionesNetas, anio(`aniovp') //boot(250) //	<-- OPTIONAL!!! Toma mucho tiempo.


** GRAFICA PROYECCION **
use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
merge 1:1 (anio) using `"`c(sysdir_personal)'/users/$pais/$id/PIB.dta"', nogen
replace estimacion = estimacion/pibYR*100

tabstat estimacion, stat(max) save
tempname MAX
matrix `MAX' = r(StatTotal)
forvalues k=1(1)`=_N' {
	if estimacion[`k'] == `MAX'[1,1] {
		local aniomax = anio[`k']
	}
	if anio[`k'] == `aniovp' {
		local estimacionvp = estimacion[`k']
	}
}

if "$nographs" != "nographs" {
	twoway (connected estimacion anio) (connected estimacion anio if anio == `aniovp') if anio > 1990, ///
		ytitle("% PIB") ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(0(1)5, format(%20.1fc) labsize(small)) ///
		xlabel(1990(10)2050, labsize(small) labgap(2)) ///
		xtitle("") ///
		legend(off) ///
		text(`=`MAX'[1,1]' `aniomax' "{bf:M{c a'}ximo:} `aniomax'", place(w)) ///
		text(`estimacionvp' `aniovp' "{bf:Paquete Econ{c o'}mico} `aniovp'", place(e)) ///
		///title("{bf:Proyecciones} de las aportaciones netas") subtitle("$pais") ///
		///caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5.") ///
		name(AportacionesNetasProj, replace)

	capture confirm existence $export
	if _rc == 0 {
		graph export "$export/AportacionesNetasProj.png", replace name(AportacionesNetasProj)
	}
}




*******************************/
***                          ***
***    6. PARTE IV: DEUDA    ***
***                          ***
********************************
noisily FiscalGap, anio(`aniovp') $nographs end(2050) //boot(250) //update




***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
