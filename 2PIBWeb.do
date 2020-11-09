****************************
*** 2 ECONOMIA Y CUENTAS ***													Cap. 3. Sistema: de Cuentas Nacionales
****************************
timer on 99
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY
*scalar aniovp = 2021

capture mkdir "`c(sysdir_personal)'/users"
capture mkdir "`c(sysdir_personal)'/users/$pais/"
capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"





**********************************/
** PAR{c A'}METROS DEL SIMULADOR **
if "$id" == "PE2021" {
	*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	*adopath ++ PERSONAL

	* Crecimiento PIB *
	global pib2020 = -8.0
	global pib2021 =  4.6
	global pib2022 =  2.6
	global pib2023 =  2.5
	global pib2024 =  2.5
	global pib2025 =  2.5

	global def2020 =  3.568
	global def2021 =  3.425
	
	global inf2020 =  3.5
	global inf2021 =  3.0
}
if "$pais" == "El Salvador" {

	* Crecimiento PIB *
	global pib2020 = -7.499
	global pib2021 =  3.745
	global def2020 =  0.383
	global def2021 =  0.512
}

***********************************/





noisily PIBDeflactor, anio(`=scalar(aniovp)') geo(9) //output //nographs //discount(3.0)
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
}
if "$pais" == "" {
	noisily Inflacion, anio(`=scalar(aniovp)') //nographs //update
	noisily SCN, anio(`=scalar(aniovp)') //nographs //update
}




************************/
**** Touchdown!!! :) ****
*************************
timer off 99
timer list 99
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t99)/r(nt99)',.1) in g " segs  " _dup(20) "."
