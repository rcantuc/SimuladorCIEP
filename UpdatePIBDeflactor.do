*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************
noisily di in g "  Updating PIBDeflactor.dta..." _newline
capture mkdir "`c(sysdir_personal)'/SIM"
capture mkdir "`c(sysdir_personal)'/SIM/BIE"
cd "`c(sysdir_personal)'/SIM/BIE"





**************
***        ***
**# 1. PIB ***
***        ***
**************

** 1.1. Importar variables de interés desde el BIE **
local series "734407 735143 446562 446565 446566"
// 750454 750455 750456 750457 750458 750459 750460 750461 750462 750463 750464 750465 750466 750467 750468 750469 750470 750471 750472 750473 750474 750475 750476 750477 750478 750479 750480 750481 750482 750483 750484 750485
run "`c(sysdir_personal)'/UpdateBIE.do" "`series'"


** 1.2 Renombrar variables **
rename periodos periodo

rename productointernobrutof1millonesde pibQ
label var pibQ "Producto Interno Bruto (trimestral)"

rename productointernobrutof1índicebase indiceQ
label var indiceQ "Índice de precios implícitos (trimestral)"

rename poblacióntotalaf1númerodepersona PoblacionENOE
label var PoblacionENOE "Población ENOE"

rename ocupadaaf1númerodepersonastrimes PoblacionOcupada
label var PoblacionOcupada "Población Ocupada (ENOE)"

rename desocupadaaf1númerodepersonastri PoblacionDesocupada
label var PoblacionDesocupada "Población Desocupada (ENOE)"


** 1.3 Dar formato a variables **
replace pibQ = pibQ*1000000
format indice* %8.3f
format pib %20.0fc
format Poblacion* %12.0fc


** 1.4 Time Series **
split periodo, destring p("/") //ignore("r p")
rename periodo1 anio
label var anio "anio"
rename periodo2 trimestre
label var trimestre "trimestre"


** 1.5 Guardar **
order anio trimestre pibQ
drop periodo
compress
tempfile PIB
save `PIB'





********************
***              ***
**# 2. Poblacion ***
***              ***
********************

** 2.1 Población (CONAPO) **
capture use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
if _rc != 0 {
	noisily run `"`c(sysdir_personal)'/UpdatePoblacion`=subinstr("${pais}"," ","",.)'.do"'
}
collapse (sum) Poblacion=poblacion if entidad == "Nacional", by(anio)
format Poblacion %15.0fc
tempfile poblacion
save "`poblacion'"


** 2.2 Working Ages (CONAPO) **
use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
collapse (sum) WorkingAge=poblacion if edad >= 15 & edad <= 65 & entidad == "Nacional", by(anio)
format WorkingAge %15.0fc
tempfile workingage
save "`workingage'"





***************
***         ***
**# 3 Unión ***
***         ***
***************
use `PIB', clear
	local ultanio = anio[_N]
	local ulttrim = trimestre[_N]
merge m:1 (anio) using "`workingage'", nogen //keep(matched)
merge m:1 (anio) using "`poblacion'", nogen //keep(matched)

** 1.4 Moneda **
g currency = "MXN"

** 3.1 Anio + Trimestre **
replace trimestre = 1 if trimestre == .
g aniotrimestre = yq(anio,trimestre)
format aniotrimestre %tq
label var aniotrimestre "YearQuarter"
tsset aniotrimestre





**************************
***                    ***
**# 4 Guardar base SIM ***
***                    ***
**************************
format pib* %25.0fc
capture drop __*
sort aniotrimestre
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace
}
