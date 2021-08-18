**********************************
****                          ****
****    HOUSEHOLDS ECUADOR    ****
****                          ****
**********************************
if "`1'" == "" {
	clear all
	local 1 = 2020
}



********************************
*** Ingresos presupuestarios ***
********************************
noisily LIF, by(divGA) anio(`1') nographs //ilif //update
local alconsumo = r(Impuestos_al_consumo)
local alingreso = r(Impuestos_al_ingreso)
local otrosing = r(Otros_ingresos)
local petroleros = r(Petroleros)
local cuotasss = r(Seguridad_Social)



******************************
*** Gastos presupuestarios ***
******************************
noisily PEF, anio(`1') nographs //update
local pensiones = r(Pensiones)
local educacion = r(Educaci_c_o__n)
local salud = r(Salud)
local deuda = r(Deuda)
local otrosgas = r(Otros)



***************************
*** Encuesta de hogares ***
***************************

/* ARCHIVOS *
local archivos: dir "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/Tablas_Primarias/01 TABLAS PRIMARIAS" files "*.sav"
foreach k of local archivos {
	import spss using "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/Tablas_Primarias/01 TABLAS PRIMARIAS/`k'", clear
	local length = strlen("`k'")
	save "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/`=substr("`k'",1,`=`length'-4')'.dta", replace
}*/



*****************************
*** Base origen: Personas ***
*****************************
use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/04 ENIGHUR11_PERSONAS.dta", clear
g Identif_perna = Identif_per

label dir
foreach k in `=r(names)' {
	label copy `k' BASE`k'
	*label drop `k'
}


*******************
*** Escolaridad ***
*******************
g escol = 0 if P14A == -1 | P14A == 1 | P14A == 2 | P14A == 3 | P14A == .
replace escol = 1 if P14A == 4 | P14A == 5
replace escol = 2 if P14A == 6 | P14A == 7
replace escol = 3 if P14A == 8 | P14A == 9 | P14A == 10

label define escol 0 "Sin escolaridad" 1 "Primaria" 2 "Secundaria/Media" 3 "Superior"
label values escol escol
label var escol "Nivel de escolaridad"



******************************************
*** Coeficientes de consumo por edades ***
******************************************
rename P02 sexo
rename P03 edad
g alfa = 1 if edad != .
replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
replace alfa = .4 if edad <= 4

tempvar alfatot
egen `alfatot' = sum(alfa), by(Identif_hog)



*************************************
*** Distribuciones proporcionales ***
*************************************
capture program drop Distribucion
program Distribucion
	syntax varname, MACRO(real)

	tempvar vartotal proporcion
	egen double `vartotal' = sum(`varlist') if factor != 0
	replace `varlist' = `varlist'/`vartotal'*`macro'/factor if factor != 0
end

tempfile base
save `base'



*************
*** MERGE ***
*************
use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/05 ENIGHUR11_PERCEPTORNA_PARTEA.dta", clear
g PERCEP = PERA02
g VALOR = PERA05*12

label dir
foreach k in `=r(names)' {
	label copy `k' A`k' 
	*label drop `k'
}

tempfile partea
save `partea'

use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/06 ENIGHUR11_PERCEPTORNA_PARTEB.dta", clear
g PERCEP = PERB02
g VALOR = PERB04

label dir
foreach k in `=r(names)' {
	label copy `k' B`k' 
	*label drop `k'
}

tempfile parteb
save `parteb'

*use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/07 ENIGHUR11_PERCEPTORNA_PARTEC.dta", clear
*g PERCEP = PERC04
*g VALOR = PERC07*12
*tempfile partec
*save `partec'

*use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/08 ENIGHUR11_PERCEPTOR_PARTED.dta", clear
*g PERCEP = PERD02
*tempfile parted
*save `parted'

use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/09 ENIGHUR11_PERCEPTOR_PARTEE.dta", clear
g PERCEP = PERE02
g VALOR = PERE04

label dir
foreach k in `=r(names)' {
	label copy `k' E`k' 
	*label drop `k'
}

rename identif_perna Identif_perna
tempfile partee
save `partee'

use "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/10 ENIGHUR11_PERCEPTOR_PARTEF.dta", clear
g PERCEP = PERF02
g VALOR = PERF03

label dir
foreach k in `=r(names)' {
	label copy `k' F`k'
	*label drop `k'
}

rename identif_perna Identif_perna
tempfile partef
save `partef'



* Append *
use `partea', clear
append using `parteb'
*append using `partec'
*append using `parted'
append using `partee'
append using `partef'
exit


keep if /*PERCEP == "Impuesto a la renta" |*/ PERCEP == "Aportaciones al seguro social" ///
	| PERCEP == "Pensión x jubilación, cesantia" | PERCEP == "Remuneración mensual unificada" 
collapse (sum) VALOR, by(Identif* PERCEP)

g ingresos = 1 if PERCEP == "Aportaciones al seguro social"
replace ingresos = 2 if PERCEP == "Remuneración mensual unificada"
replace ingresos = 3 if PERCEP == "Pensión x jubilación, cesantia"
drop PERCEP
reshape wide VALOR, i(Identif_perna) j(ingresos)
exit
merge 1:1 (Identif_perna) using `base', nogen
merge m:1 (Identif_hog) using "`c(sysdir_site)'../basesCIEP/Otros/Ecuador/ENIGHUR11_HOGARES_AGREGADOS.dta", nogen keepus(dec_nac_per ing_cor_tot ing_no_mon gas_gru_cor)

g decil = dec_nac_per
egen ingbrutotot = rsum(ing_cor_tot ing_no_mon)

g factor = round(Fexp_cen2010)
g numren = substr(Identif_per,-2,2)





*******************************
*** Variables Simulador.ado ***
*******************************



** (+) Consumo **
g Consumo = gas_gru_cor*alfa/`alfatot'
label var Consumo "impuestos al consumo"
Distribucion Consumo, macro(`alconsumo')
noisily Simulador Consumo [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (+) Ingreso **
g Laboral = VALOR2
replace Laboral = 0 if Laboral == .
label var Laboral "impuestos al ingreso"
Distribucion Laboral, macro(`alingreso')
noisily Simulador Laboral [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (+) Otros ingresos **
g OtrosC = 1
label var OtrosC "otros ingresos"
Distribucion OtrosC, macro(`otrosing')
noisily Simulador OtrosC [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (+) Petroleros **
g Petroleo = 1
label var Petroleo "ing. petroleros"
Distribucion Petroleo, macro(`petroleros')
noisily Simulador Petroleo [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (+) Seguridad Social **
g CuotasSS = VALOR1
replace CuotasSS = 0 if CuotasSS == .
label var CuotasSS "seguridad social"
Distribucion CuotasSS, macro(`cuotasss')
noisily Simulador CuotasSS [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (+) ISR_PM **
g ISR__PM = 0
label var ISR__PM "ISR personas morales"



** (-) IngBasico **
g IngBasico = 0
label var IngBasico "IngBasico"
Simulador IngBasico [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (-) PenBienestar **
g PenBienestar = 0
label var PenBienestar "PenBienestar"
Simulador PenBienestar if edad >= 68 [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (-) Infra **
g Infra = 0
label var Infra "Infra"



** (-) Pensiones **
g Pension = VALOR3
replace Pension = 0 if Pension == .
label var Pension "Pensiones"
Distribucion Pension, macro(`pensiones')
noisily Simulador Pension [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (-) Educación **
tabstat factor if P18 == 1, stat(sum) by(P14A) f(%10.0fc) save
matrix TotAlum = r(StatTotal)
matrix BasAlum = r(Stat1)+r(Stat2)+r(Stat3)
matrix MedAlum = r(Stat4)+r(Stat5)
matrix SupAlum = r(Stat6)+r(Stat7)+r(Stat8)


g Educacion = 157.2*1000000/TotAlum[1,1] + 638.5*1000000/BasAlum[1,1] if (P14A == 2 | P14A == 3 | P14A == 4 | P14A == 5) & P18 == 1
replace Educacion = 157.2*1000000/TotAlum[1,1] + 102.5*1000000/MedAlum[1,1] if (P14A == 6 | P14A == 7) & P18 == 1
replace Educacion = 157.2*1000000/TotAlum[1,1] + 84.3*1000000/SupAlum[1,1] if (P14A == 8 | P14A == 9 | P14A == 10) & P18 == 1
replace Educacion = 0 if Educacion == .
label var Educacion "Educación"

Distribucion Educacion, macro(`educacion')
Simulador Educacion [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** Salud **
g Salud = 0
replace Salud = 1.963106 if edad == 0
replace Salud = .1351139 if edad == 1
replace Salud = .0710421 if edad == 2
replace Salud = .0499305 if edad == 3
replace Salud = .0435635 if edad == 4
replace Salud = .0406816 if edad == 5
replace Salud = .0377997 if edad == 6
replace Salud = .0366604 if edad == 7
replace Salud = .0367274 if edad == 8
replace Salud = .0380008 if edad == 9
replace Salud = .0408157 if edad == 10
replace Salud = .0454401 if edad == 11
replace Salud = .0518741 if edad == 12
replace Salud = .06119 if edad == 13
replace Salud = .0719133 if edad == 14
replace Salud = .0845803 if edad == 15
replace Salud = .0985876 if edad == 16
replace Salud = .1129301 if edad == 17
replace Salud = .1279427 if edad == 18
replace Salud = .1428213 if edad == 19
replace Salud = .1573648 if edad == 20
replace Salud = .1705009 if edad == 21
replace Salud = .183637 if edad == 22
replace Salud = .1950976 if edad == 23
replace Salud = .2048156 if edad == 24
replace Salud = .21259 if edad == 25
replace Salud = .2184208 if edad == 26
replace Salud = .2221069 if edad == 27
replace Salud = .2247208 if edad == 28
replace Salud = .2269995 if edad == 29
replace Salud = .2280048 if edad == 30
replace Salud = .2303505 if edad == 31
replace Salud = .231825 if edad == 32
replace Salud = .2343047 if edad == 33
replace Salud = .2374547 if edad == 34
replace Salud = .2412079 if edad == 35
replace Salud = .2464355 if edad == 36
replace Salud = .2534057 if edad == 37
replace Salud = .2617162 if edad == 38
replace Salud = .2727747 if edad == 39
replace Salud = .2861118 if edad == 40
replace Salud = .3017277 if edad == 41
replace Salud = .3197563 if edad == 42
replace Salud = .3391923 if edad == 43
replace Salud = .3592315 if edad == 44
replace Salud = .3803431 if edad == 45
replace Salud = .4013206 if edad == 46
replace Salud = .421963 if edad == 47
replace Salud = .4438788 if edad == 48
replace Salud = .4657276 if edad == 49
replace Salud = .489654 if edad == 50
replace Salud = .5133794 if edad == 51
replace Salud = .5393164 if edad == 52
replace Salud = .567063 if edad == 53
replace Salud = .5955469 if edad == 54
replace Salud = .6245669 if edad == 55
replace Salud = .6546592 if edad == 56
replace Salud = .6843494 if edad == 57
replace Salud = .7137045 if edad == 58
replace Salud = .740915 if edad == 59
replace Salud = .7671201 if edad == 60
replace Salud = .7916497 if edad == 61
replace Salud = .815107 if edad == 62
replace Salud = .837492 if edad == 63
replace Salud = .8573301 if edad == 64
replace Salud = .8764981 if edad == 65
replace Salud = .8941916 if edad == 66
replace Salud = .9090032 if edad == 67
replace Salud = .9293775 if edad == 68
replace Salud = .9522986 if edad == 69
replace Salud = .9701261 if edad == 70
replace Salud = .9868143 if edad == 71
replace Salud = 1.002765 if edad == 72
replace Salud = 1.016505 if edad == 73
replace Salud = 1.02944 if edad == 74
replace Salud = 1.03842 if edad == 75
replace Salud = 1.047937 if edad == 76
replace Salud = 1.053567 if edad == 77
replace Salud = 1.053165 if edad == 78
replace Salud = 1.046731 if edad == 79
replace Salud = 1.037013 if edad == 80
replace Salud = 1.023408 if edad == 81
replace Salud = 1.005111 if edad == 82
replace Salud = .9829941 if edad == 83
replace Salud = .9557837 if edad == 84
replace Salud = .9243509 if edad == 85
replace Salud = .8868863 if edad == 86
replace Salud = .844127 if edad == 87
replace Salud = .7932582 if edad == 88
replace Salud = .7351512 if edad == 89
replace Salud = .6751676 if edad == 90
replace Salud = .612168 if edad == 91
replace Salud = .54756 if edad == 92
replace Salud = .4848955 if edad == 93
replace Salud = .4216949 if edad == 94
replace Salud = .3601028 if edad == 95
replace Salud = .3007894 if edad == 96
replace Salud = .2456312 if edad == 97
replace Salud = .1952316 if edad == 98
replace Salud = .151333 if edad == 99
replace Salud = .1138013 if edad == 100
replace Salud = .0828377 if edad == 101
replace Salud = .0587102 if edad == 102
replace Salud = .0397433 if edad == 103
replace Salud = .0259371 if edad == 104
replace Salud = .0162861 if edad == 105
replace Salud = .0092489 if edad == 106
replace Salud = .0049595 if edad == 107
replace Salud = .0004021 if edad == 108
replace Salud = .0030159 if edad >= 109
label var Salud "Salud"
Distribucion Salud, macro(`salud')
noisily Simulador Salud [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** Otros gastos **
g OtrosGas = 1
replace OtrosGas = 0 if OtrosGas == .
label var OtrosGas "Otros gastos"
Distribucion OtrosGas, macro(`otrosgas')
Simulador OtrosGas [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)





***********
*** END ***
capture drop __*
compress
capture mkdir "`c(sysdir_personal)'/SIM/$pais/"
capture mkdir "`c(sysdir_personal)'/SIM/$pais/2018/"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/$pais/2018/households.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/$pais/2018/households.dta", replace
}
