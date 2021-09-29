**********************************
****                          ****
****    HOUSEHOLDS ECUADOR    ****
****                          ****
**********************************
if "`1'" == "" {
	clear all
	local 1 = 2021
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

keep if /*PERCEP == "Impuesto a la renta" |*/ PERCEP == "Aportaciones al seguro social" ///
	| PERCEP == "Pensión x jubilación, cesantia" | PERCEP == "Remuneración mensual unificada" 
collapse (sum) VALOR, by(Identif* PERCEP)

g ingresos = 1 if PERCEP == "Aportaciones al seguro social"
replace ingresos = 2 if PERCEP == "Remuneración mensual unificada"
replace ingresos = 3 if PERCEP == "Pensión x jubilación, cesantia"

drop PERCEP
reshape wide VALOR, i(Identif_perna) j(ingresos)

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



** (-) Infra **/
g Infra = 0
label var Infra "Infra"



** (-) Pensiones **
g Pension = VALOR3 if P05A != 5 | P05A != 6 | P05A != 9
replace Pension = 0 if Pension == .
label var Pension "pensiones p{c u'}blicas"
Distribucion Pension, macro(`pensiones')
noisily Simulador Pension [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** (-) Educación **
g Educacion = 0

tabstat factor if edad <= 4, stat(sum) f(%20.0fc) save
tempname ini
matrix `ini' = r(StatTotal)

tabstat factor if edad == 5, stat(sum) f(%20.0fc) save
tempname ini5
matrix `ini5' = r(StatTotal)

replace Educacion =  669.7*270130/`ini'[1,1] if edad <= 4 // Inicial
replace Educacion =  666.1*239193/`ini5'[1,1] if edad == 5 // Preparatoria
replace Educacion =  666.1 if (P15A == 5 |  P15A == 6) & P17 != 2 & P18 == 1 // Basica
replace Educacion = 1166.9 if P15A == 7 & P17 != 2 & P18 == 1 // Bachillerato
replace Educacion = 1181.5 if (P15A == 8 | P15A == 9 | P15A == 10) & P17 != 2 & P18 == 1 // Superior
replace Educacion = 0 if Educacion == .
label var Educacion "Educación"

Distribucion Educacion, macro(`educacion')
Simulador Educacion [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** Salud **
g Salud = 0


/** Defunciones **
replace Salud = 0.02522058 if edad == 0 & sexo == 1
replace Salud = 0.02109691 if edad == 0 & sexo == 2
replace Salud = 0.00250197 if edad == 1 & sexo == 1
replace Salud = 0.00221544 if edad == 1 & sexo == 2
replace Salud = 0.00141788 if edad == 2 & sexo == 1
replace Salud = 0.0013145 if edad == 2 & sexo == 2
replace Salud = 0.00102501 if edad == 3 & sexo == 1
replace Salud = 0.00087141 if edad == 3 & sexo == 2
replace Salud = 0.00087731 if edad == 4 & sexo == 1
replace Salud = 0.00070008 if edad == 4 & sexo == 2
replace Salud = 0.00346495/5 if (edad >= 5 & edad <= 9) & sexo == 1
replace Salud = 0.0027885/5 if (edad >= 5 & edad <= 9) & sexo == 2
replace Salud = 0.00406164/5 if (edad >= 10 & edad <= 14) & sexo == 1
replace Salud = 0.00330248/5 if (edad >= 10 & edad <= 14) & sexo == 2
replace Salud = 0.00996062/5 if (edad >= 15 & edad <= 19) & sexo == 1
replace Salud = 0.00543522/5 if (edad >= 15 & edad <= 19) & sexo == 2
replace Salud = 0.01525405/5 if (edad >= 20 & edad <= 24) & sexo == 1
replace Salud = 0.00625345/5 if (edad >= 20 & edad <= 24) & sexo == 2
replace Salud = 0.01541947/5 if (edad >= 25 & edad <= 29) & sexo == 1
replace Salud = 0.00661678/5 if (edad >= 25 & edad <= 29) & sexo == 2
replace Salud = 0.01521565/5 if (edad >= 30 & edad <= 34) & sexo == 1
replace Salud = 0.00733163/5 if (edad >= 30 & edad <= 34) & sexo == 2
replace Salud = 0.01533972/5 if (edad >= 35 & edad <= 39) & sexo == 1
replace Salud = 0.00872884/5 if (edad >= 35 & edad <= 39) & sexo == 2
replace Salud = 0.01575031/5 if (edad >= 40 & edad <= 44) & sexo == 1
replace Salud = 0.01000198/5 if (edad >= 40 & edad <= 44) & sexo == 2
replace Salud = 0.01829659/5 if (edad >= 45 & edad <= 49) & sexo == 1
replace Salud = 0.01268414/5 if (edad >= 45 & edad <= 49) & sexo == 2
replace Salud = 0.02267726/5 if (edad >= 50 & edad <= 54) & sexo == 1
replace Salud = 0.0166808/5 if (edad >= 50 & edad <= 54) & sexo == 2
replace Salud = 0.02896911/5 if (edad >= 55 & edad <= 59) & sexo == 1
replace Salud = 0.0214632/5 if (edad >= 55 & edad <= 59) & sexo == 2
replace Salud = 0.03482083/5 if (edad >= 60 & edad <= 64) & sexo == 1
replace Salud = 0.0272322/5 if (edad >= 60 & edad <= 64) & sexo == 2
replace Salud = 0.03997838/5 if (edad >= 65 & edad <= 69) & sexo == 1
replace Salud = 0.03192599/5 if (edad >= 65 & edad <= 69) & sexo == 2
replace Salud = 0.04540473/5 if (edad >= 70 & edad <= 74) & sexo == 1
replace Salud = 0.03716329/5 if (edad >= 70 & edad <= 74) & sexo == 2
replace Salud = 0.05157843/5 if (edad >= 75 & edad <= 79) & sexo == 1
replace Salud = 0.04405184/5 if (edad >= 75 & edad <= 79) & sexo == 2
replace Salud = 0.05771668/5 if (edad >= 80 & edad <= 84) & sexo == 1
replace Salud = 0.05349848/5 if (edad >= 80 & edad <= 84) & sexo == 2
replace Salud = 0.11657948/15 if edad >= 85 & sexo == 1
replace Salud = 0.13711219/15 if edad >= 85 & sexo == 2


** Afiliacion **/
replace Salud = 55732 if edad == 0 & sexo == 1
replace Salud = 65538 if edad == 1 & sexo == 1
replace Salud = 69043 if edad == 2 & sexo == 1
replace Salud = 78951 if edad == 3 & sexo == 1
replace Salud = 73587 if edad == 4 & sexo == 1
replace Salud = 74546 if edad == 5 & sexo == 1
replace Salud = 73897 if edad == 6 & sexo == 1
replace Salud = 80879 if edad == 7 & sexo == 1
replace Salud = 68106 if edad == 8 & sexo == 1
replace Salud = 71185 if edad == 9 & sexo == 1
replace Salud = 72780 if edad == 10 & sexo == 1
replace Salud = 74930 if edad == 11 & sexo == 1
replace Salud = 76403 if edad == 12 & sexo == 1
replace Salud = 65937 if edad == 13 & sexo == 1
replace Salud = 79270 if edad == 14 & sexo == 1
replace Salud = 62380 if edad == 15 & sexo == 1
replace Salud = 70628 if edad == 16 & sexo == 1
replace Salud = 63838 if edad == 17 & sexo == 1
replace Salud = 21759 if edad == 18 & sexo == 1
replace Salud = 32563 if edad == 19 & sexo == 1
replace Salud = 29958 if edad == 20 & sexo == 1
replace Salud = 43894 if edad == 21 & sexo == 1
replace Salud = 43933 if edad == 22 & sexo == 1
replace Salud = 37554 if edad == 23 & sexo == 1
replace Salud = 48997 if edad == 24 & sexo == 1
replace Salud = 52774 if edad == 25 & sexo == 1
replace Salud = 49623 if edad == 26 & sexo == 1
replace Salud = 45332 if edad == 27 & sexo == 1
replace Salud = 56377 if edad == 28 & sexo == 1
replace Salud = 56598 if edad == 29 & sexo == 1
replace Salud = 54140 if edad == 30 & sexo == 1
replace Salud = 45816 if edad == 31 & sexo == 1
replace Salud = 46171 if edad == 32 & sexo == 1
replace Salud = 60531 if edad == 33 & sexo == 1
replace Salud = 52596 if edad == 34 & sexo == 1
replace Salud = 47095 if edad == 35 & sexo == 1
replace Salud = 49414 if edad == 36 & sexo == 1
replace Salud = 50444 if edad == 37 & sexo == 1
replace Salud = 43555 if edad == 38 & sexo == 1
replace Salud = 46048 if edad == 39 & sexo == 1
replace Salud = 46845 if edad == 40 & sexo == 1
replace Salud = 38763 if edad == 41 & sexo == 1
replace Salud = 42907 if edad == 42 & sexo == 1
replace Salud = 43060 if edad == 43 & sexo == 1
replace Salud = 44173 if edad == 44 & sexo == 1
replace Salud = 32839 if edad == 45 & sexo == 1
replace Salud = 40493 if edad == 46 & sexo == 1
replace Salud = 34740 if edad == 47 & sexo == 1
replace Salud = 39414 if edad == 48 & sexo == 1
replace Salud = 38025 if edad == 49 & sexo == 1
replace Salud = 33770 if edad == 50 & sexo == 1
replace Salud = 25364 if edad == 51 & sexo == 1
replace Salud = 37515 if edad == 52 & sexo == 1
replace Salud = 31965 if edad == 53 & sexo == 1
replace Salud = 30278 if edad == 54 & sexo == 1
replace Salud = 31491 if edad == 55 & sexo == 1
replace Salud = 27266 if edad == 56 & sexo == 1
replace Salud = 32035 if edad == 57 & sexo == 1
replace Salud = 31305 if edad == 58 & sexo == 1
replace Salud = 24732 if edad == 59 & sexo == 1
replace Salud = 23915 if edad == 60 & sexo == 1
replace Salud = 20780 if edad == 61 & sexo == 1
replace Salud = 20930 if edad == 62 & sexo == 1
replace Salud = 22119 if edad == 63 & sexo == 1
replace Salud = 21397 if edad == 64 & sexo == 1
replace Salud = 24861 if edad == 65 & sexo == 1
replace Salud = 17719 if edad == 66 & sexo == 1
replace Salud = 19901 if edad == 67 & sexo == 1
replace Salud = 17960 if edad == 68 & sexo == 1
replace Salud = 22462 if edad == 69 & sexo == 1
replace Salud = 11944 if edad == 70 & sexo == 1
replace Salud = 11564 if edad == 71 & sexo == 1
replace Salud = 11373 if edad == 72 & sexo == 1
replace Salud = 11316 if edad == 73 & sexo == 1
replace Salud = 14139 if edad == 74 & sexo == 1
replace Salud = 10980 if edad == 75 & sexo == 1
replace Salud = 8930 if edad == 76 & sexo == 1
replace Salud = 10913 if edad == 77 & sexo == 1
replace Salud = 6522 if edad == 78 & sexo == 1
replace Salud = 10227 if edad == 79 & sexo == 1
replace Salud = 7693 if edad == 80 & sexo == 1
replace Salud = 8023 if edad == 81 & sexo == 1
replace Salud = 5772 if edad == 82 & sexo == 1
replace Salud = 6336 if edad == 83 & sexo == 1
replace Salud = 5217 if edad == 84 & sexo == 1
replace Salud = 5329 if edad == 85 & sexo == 1
replace Salud = 3529 if edad == 86 & sexo == 1
replace Salud = 1987 if edad == 87 & sexo == 1
replace Salud = 1482 if edad == 88 & sexo == 1
replace Salud = 1419 if edad == 89 & sexo == 1
replace Salud = 496 if edad == 90 & sexo == 1
replace Salud = 2066 if edad == 91 & sexo == 1
replace Salud = 1514 if edad == 92 & sexo == 1
replace Salud = 525 if edad == 93 & sexo == 1
replace Salud = 1003 if edad == 94 & sexo == 1
replace Salud = 924 if edad == 95 & sexo == 1
replace Salud = 35 if edad == 96 & sexo == 1
replace Salud = 630 if edad == 97 & sexo == 1
replace Salud = 1492 if edad >= 98 & sexo == 1

replace Salud = 45060 if edad == 0 & sexo == 2
replace Salud = 57068 if edad == 1 & sexo == 2
replace Salud = 74871 if edad == 2 & sexo == 2
replace Salud = 72980 if edad == 3 & sexo == 2
replace Salud = 70673 if edad == 4 & sexo == 2
replace Salud = 69845 if edad == 5 & sexo == 2
replace Salud = 78776 if edad == 6 & sexo == 2
replace Salud = 69609 if edad == 7 & sexo == 2
replace Salud = 71690 if edad == 8 & sexo == 2
replace Salud = 62522 if edad == 9 & sexo == 2
replace Salud = 62646 if edad == 10 & sexo == 2
replace Salud = 74208 if edad == 11 & sexo == 2
replace Salud = 73966 if edad == 12 & sexo == 2
replace Salud = 70707 if edad == 13 & sexo == 2
replace Salud = 75921 if edad == 14 & sexo == 2
replace Salud = 59575 if edad == 15 & sexo == 2
replace Salud = 59612 if edad == 16 & sexo == 2
replace Salud = 59384 if edad == 17 & sexo == 2
replace Salud = 16239 if edad == 18 & sexo == 2
replace Salud = 16680 if edad == 19 & sexo == 2
replace Salud = 16750 if edad == 20 & sexo == 2
replace Salud = 24067 if edad == 21 & sexo == 2
replace Salud = 22824 if edad == 22 & sexo == 2
replace Salud = 29381 if edad == 23 & sexo == 2
replace Salud = 29494 if edad == 24 & sexo == 2
replace Salud = 34721 if edad == 25 & sexo == 2
replace Salud = 38511 if edad == 26 & sexo == 2
replace Salud = 34789 if edad == 27 & sexo == 2
replace Salud = 38935 if edad == 28 & sexo == 2
replace Salud = 41835 if edad == 29 & sexo == 2
replace Salud = 39275 if edad == 30 & sexo == 2
replace Salud = 44939 if edad == 31 & sexo == 2
replace Salud = 40389 if edad == 32 & sexo == 2
replace Salud = 49120 if edad == 33 & sexo == 2
replace Salud = 37275 if edad == 34 & sexo == 2
replace Salud = 42240 if edad == 35 & sexo == 2
replace Salud = 32562 if edad == 36 & sexo == 2
replace Salud = 41408 if edad == 37 & sexo == 2
replace Salud = 29564 if edad == 38 & sexo == 2
replace Salud = 37310 if edad == 39 & sexo == 2
replace Salud = 41274 if edad == 40 & sexo == 2
replace Salud = 34903 if edad == 41 & sexo == 2
replace Salud = 40624 if edad == 42 & sexo == 2
replace Salud = 34364 if edad == 43 & sexo == 2
replace Salud = 32394 if edad == 44 & sexo == 2
replace Salud = 26086 if edad == 45 & sexo == 2
replace Salud = 32883 if edad == 46 & sexo == 2
replace Salud = 34586 if edad == 47 & sexo == 2
replace Salud = 32550 if edad == 48 & sexo == 2
replace Salud = 30101 if edad == 49 & sexo == 2
replace Salud = 29439 if edad == 50 & sexo == 2
replace Salud = 30163 if edad == 51 & sexo == 2
replace Salud = 30686 if edad == 52 & sexo == 2
replace Salud = 22793 if edad == 53 & sexo == 2
replace Salud = 32390 if edad == 54 & sexo == 2
replace Salud = 26436 if edad == 55 & sexo == 2
replace Salud = 21905 if edad == 56 & sexo == 2
replace Salud = 18929 if edad == 57 & sexo == 2
replace Salud = 25003 if edad == 58 & sexo == 2
replace Salud = 20597 if edad == 59 & sexo == 2
replace Salud = 22134 if edad == 60 & sexo == 2
replace Salud = 20270 if edad == 61 & sexo == 2
replace Salud = 19287 if edad == 62 & sexo == 2
replace Salud = 18333 if edad == 63 & sexo == 2
replace Salud = 12067 if edad == 64 & sexo == 2
replace Salud = 17897 if edad == 65 & sexo == 2
replace Salud = 20472 if edad == 66 & sexo == 2
replace Salud = 14811 if edad == 67 & sexo == 2
replace Salud = 12200 if edad == 68 & sexo == 2
replace Salud = 11715 if edad == 69 & sexo == 2
replace Salud = 11379 if edad == 70 & sexo == 2
replace Salud = 8937 if edad == 71 & sexo == 2
replace Salud = 9017 if edad == 72 & sexo == 2
replace Salud = 9981 if edad == 73 & sexo == 2
replace Salud = 11113 if edad == 74 & sexo == 2
replace Salud = 9224 if edad == 75 & sexo == 2
replace Salud = 7353 if edad == 76 & sexo == 2
replace Salud = 7426 if edad == 77 & sexo == 2
replace Salud = 9538 if edad == 78 & sexo == 2
replace Salud = 7204 if edad == 79 & sexo == 2
replace Salud = 6832 if edad == 80 & sexo == 2
replace Salud = 3827 if edad == 81 & sexo == 2
replace Salud = 5385 if edad == 82 & sexo == 2
replace Salud = 4592 if edad == 83 & sexo == 2
replace Salud = 3559 if edad == 84 & sexo == 2
replace Salud = 3009 if edad == 85 & sexo == 2
replace Salud = 4646 if edad == 86 & sexo == 2
replace Salud = 2306 if edad == 87 & sexo == 2
replace Salud = 1752 if edad == 88 & sexo == 2
replace Salud = 1212 if edad == 89 & sexo == 2
replace Salud = 1386 if edad == 90 & sexo == 2
replace Salud = 1161 if edad == 91 & sexo == 2
replace Salud = 881 if edad == 92 & sexo == 2
replace Salud = 359 if edad == 93 & sexo == 2
replace Salud = 913 if edad == 94 & sexo == 2
replace Salud = 485 if edad == 95 & sexo == 2
replace Salud = 396 if edad == 96 & sexo == 2
replace Salud = 279 if edad == 97 & sexo == 2
replace Salud = 1268 if edad >= 98 & sexo == 2


*/
label var Salud "Salud"
Distribucion Salud, macro(`salud')
noisily Simulador Salud [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



** Otros gastos **
g OtrosGas = 1
replace OtrosGas = 0 if OtrosGas == .
label var OtrosGas "Otros gastos"
Distribucion OtrosGas, macro(`otrosgas')
noisily Simulador OtrosGas [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)





***********
*** END ***
capture drop __*
compress
capture mkdir "`c(sysdir_personal)'/SIM/$pais/"
capture mkdir "`c(sysdir_personal)'/SIM/$pais/2020/"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/$pais/2020/households.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/$pais/2020/households.dta", replace
}
