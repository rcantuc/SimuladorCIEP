****************************
*** 2 ECONOMIA Y CUENTAS ***
****************************
timer on 99
if "`1'" == "" {
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local anio = substr(`"`=trim("`fecha'")'"',1,4)
	local nographs "nographs"
}
else {
	local anio = `1'
	local nographs "$nographs"
}




**********************************/
** PAR{c A'}METROS DEL SIMULADOR **
***********************************
if "$id" == "PE2021" {

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




********************/
** PIB + Deflactor **
*********************
noisily PIBDeflactor, anio(`anio') output `nographs' //geo(`geo') //discount(3.0)


** Guardar base de $pais y $id **
capture mkdir "`c(sysdir_personal)'/users"
capture mkdir "`c(sysdir_personal)'/users/$pais/"
capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
}


** SCN + Inflacion **
if "$pais" == "" & "`1'" != "" {
	noisily Inflacion, anio(`anio') `nographs' //update
	noisily SCN, anio(`anio') `nographs' //update
}



************************/
**** Touchdown!!! :) ****
*************************
timer off 99
timer list 99
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t99)/r(nt99)',.1) in g " segs  " _dup(20) "."
