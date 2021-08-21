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



** (-) Infra **
g Infra = 0
label var Infra "Infra"



** (-) Pensiones **
g Pension = VALOR3
replace Pension = 0 if Pension == .
label var Pension "pensiones p{c u'}blicas"
Distribucion Pension, macro(`pensiones')
noisily Simulador Pension if P05A >= 1 & P05A <= 4 [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot anio(`1') folio(Identif_hog)



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
replace Salud = 0.025686798 if edad == 0 & sexo == 1
replace Salud = 0.020031615 if edad == 0 & sexo == 2
replace Salud = 0.002411970 if edad == 1 & sexo == 1
replace Salud = 0.001866892 if edad == 1 & sexo == 2
replace Salud = 0.001267306 if edad == 2 & sexo == 1
replace Salud = 0.001185545 if edad == 2 & sexo == 2
replace Salud = 0.000872125 if edad == 3 & sexo == 1
replace Salud = 0.000681347 if edad == 3 & sexo == 2
replace Salud = 0.000872125 if edad == 4 & sexo == 1
replace Salud = 0.000613213 if edad == 4 & sexo == 2
replace Salud = 0.002984302/5 if (edad >= 5 & edad <= 9) & sexo == 1
replace Salud = 0.002248447/5 if (edad >= 5 & edad <= 9) & sexo == 2
replace Salud = 0.003529380/5 if (edad >= 10 & edad <= 14) & sexo == 1
replace Salud = 0.002793524/5 if (edad >= 10 & edad <= 14) & sexo == 2
replace Salud = 0.010029434/5 if (edad >= 15 & edad <= 19) & sexo == 1
replace Salud = 0.004524147/5 if (edad >= 15 & edad <= 19) & sexo == 2
replace Salud = 0.016965551/5 if (edad >= 20 & edad <= 24) & sexo == 1
replace Salud = 0.005587049/5 if (edad >= 20 & edad <= 24) & sexo == 2
replace Salud = 0.018341873/5 if (edad >= 25 & edad <= 29) & sexo == 1
replace Salud = 0.005409899/5 if (edad >= 25 & edad <= 29) & sexo == 2
replace Salud = 0.017524256/5 if (edad >= 30 & edad <= 34) & sexo == 1
replace Salud = 0.006513681/5 if (edad >= 30 & edad <= 34) & sexo == 2
replace Salud = 0.016652131/5 if (edad >= 35 & edad <= 39) & sexo == 1
replace Salud = 0.008121661/5 if (edad >= 35 & edad <= 39) & sexo == 2
replace Salud = 0.017524256/5 if (edad >= 40 & edad <= 44) & sexo == 1
replace Salud = 0.009552491/5 if (edad >= 40 & edad <= 44) & sexo == 2
replace Salud = 0.019527417/5 if (edad >= 45 & edad <= 49) & sexo == 1
replace Salud = 0.012386896/5 if (edad >= 45 & edad <= 49) & sexo == 2
replace Salud = 0.022988662/5 if (edad >= 50 & edad <= 54) & sexo == 1
replace Salud = 0.015861768/5 if (edad >= 50 & edad <= 54) & sexo == 2
replace Salud = 0.029475090/5 if (edad >= 55 & edad <= 59) & sexo == 1
replace Salud = 0.022034776/5 if (edad >= 55 & edad <= 59) & sexo == 2
replace Salud = 0.035920637/5 if (edad >= 60 & edad <= 64) & sexo == 1
replace Salud = 0.026736073/5 if (edad >= 60 & edad <= 64) & sexo == 2
replace Salud = 0.042161779/5 if (edad >= 65 & edad <= 69) & sexo == 1
replace Salud = 0.032486646/5 if (edad >= 65 & edad <= 69) & sexo == 2
replace Salud = 0.047244631/5 if (edad >= 70 & edad <= 74) & sexo == 1
replace Salud = 0.036942658/5 if (edad >= 70 & edad <= 74) & sexo == 2
replace Salud = 0.050814892/5 if (edad >= 75 & edad <= 79) & sexo == 1
replace Salud = 0.041861986/5 if (edad >= 75 & edad <= 79) & sexo == 2
replace Salud = 0.057396708/5 if (edad >= 80 & edad <= 84) & sexo == 1
replace Salud = 0.052068571/5 if (edad >= 80 & edad <= 84) & sexo == 2
replace Salud = 0.112667611/15 if edad >= 85 & sexo == 1
replace Salud = 0.137632181/15 if edad >= 85 & sexo == 2

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
capture mkdir "`c(sysdir_personal)'/SIM/$pais/2018/"
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/$pais/2018/households.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/$pais/2018/households.dta", replace
}
