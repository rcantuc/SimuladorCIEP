**************************
**** HOLA, HUMANO! :) ****
**************************
clear all
macro drop _all
capture log close _all

if "`c(os)'" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}
if "`c(os)'" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}
adopath ++ PERSONAL
timer on 1
noisily di _newline(15) in g _dup(60) "~"





*************************
*** 1 Par{c a'}metros ***
*************************
global pais = "El Salvador"
local anio = 2020

** Pre-Covid19, lo que no fue **
global pib2019 = 3.47		// Banco Central de Reserva
global pib2020 = 2.5		// Ministerio de Hacienda
scalar OtrosGasGW = 1

** Post-Covid19, escenario actual **
global pib2020 = -5.6		// [-5.6,0.1]
global pib2021 = 1.5 		// [ 1.5,4.3]
scalar OtrosGasGW = 1.41

/** Alternativas **
global pib2021 = 6			// [ 1.5,4.3]
global pib2022 = 6			// [ 1.5,4.3]
global pib2023 = 6			// [ 1.5,4.3]

** Economía BASE **/
noisily PIBDeflactor, graphs //discount(3.0)									<-- Cap. 3. Par{c a'}metros MACRO.
tempfile PIB
save `PIB'

** Poblacion BASE: 2018 **
if "`c(os)'" == "Unix" & "go" == "go" {
	noisily run HouseholdsElSalvador.do 2018
}





********************
*** 2 ESCENARIOS ***
********************

** INGRESO BASICO **
scalar IngBas = 0
scalar IngBasLP = 0							// 1: largo plazo; 0: corto plazo

scalar ingbasico18 = 1						// Incluye menores de 18 anios
scalar ingbasico65 = 1						// Incluye mayores de 65 anios

** PENSION BIENESTAR **
scalar Bienestar = 0
scalar BienestarLP = 0						// 1: largo plazo; 0: corto plazo

** INGRESOS PRESUPUESTARIOS **
scalar IngresosLP = 0															// 1: largo plazo; 0: corto plazo
scalar IngresosGW = 1*(1+(${pib2020}-2.5)*2.835/100)

scalar ConsumoLP = 0															// 1: largo plazo; 0: corto plazo
scalar ConsumoGW = 1*(1+(${pib2020}-2.5)*1.596/100)

scalar OtrosILP = 0																// 1: largo plazo; 0: corto plazo
scalar OtrosIGW = 1*(1+(${pib2020}-2.5)*2.289/100)

** ESCENARIOS: El Salvador **
scalar PensionesLP = 0															// 1: largo plazo; 0: corto plazo
scalar PensionesGW = 1

scalar EducacionLP = 0															// 1: largo plazo; 0: corto plazo
scalar EducacionGW = 1

scalar SaludLP = 0																// 1: largo plazo; 0: corto plazo
scalar SaludGW = 1

scalar OtrosGasLP = 0															// 1: largo plazo; 0: corto plazo





**************************
*** 3 PRE-ASIGNACIONES ***
**************************
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear

** (+) Ingreso BASICO **
if ingbasico18 == 0 & ingbasico65 == 1 {
	tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION1 = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION1[1,1] if edad >= 18
}
else if ingbasico18 == 1 & ingbasico65 == 0 {
	tabstat factor if edad < 68, stat(sum) f(%20.0fc) save
	matrix POBLACION2 = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION2[1,1] if edad < 68
}
else if ingbasico18 == 0 & ingbasico65 == 0 {
	tabstat factor if edad < 68 & edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION3 = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION3[1,1] if edad >= 18 & edad < 68
}
else { 
	tabstat factor, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION[1,1]
}
label var IngBasico "Ingreso b{c a'}sico"
Simulador IngBasico [fw=factor], base("ENIGH 2018") ///
	boot(1) reboot //graphs

** (+) Pension BIENESTAR **
tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
matrix POBLACION68 = r(StatTotal)

capture g PenBienestar = scalar(Bienestar)/100*scalar(pibY)/POBLACION68[1,1] if edad >= 68
if _rc != 0 {
	replace PenBienestar = scalar(Bienestar)/100*scalar(pibY)/POBLACION68[1,1] if edad >= 68
}
replace PenBienestar = 0 if PenBienestar == .
label var PenBienestar "Pensi{c o'}n Bienestar"
Simulador PenBienestar [fw=factor], base("ENIGH 2018") ///
	boot(1) reboot //graphs

tabstat IngBasico PenBienestar [fw=factor], stat(sum) f(%20.0fc)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace





*********************************/
*** 4 Sistema Fiscal: INGRESOS ***
**********************************
LIF if anio == `anio', anio(`anio') by(divGA) lif //graphs //update					<-- Parte 2.
local ingresostot = r(Ingresos_sin_deuda)
local alingreso = r(Impuestos_al_ingreso)
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Otros_ingresos)


** A. POBLACION SIM **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
tabstat Ingreso Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOS = r(StatTotal)

replace Ingreso = Ingreso*`alingreso'/INGRESOS[1,1]*scalar(IngresosGW)
replace Consumo = Consumo*`alconsumo'/INGRESOS[1,2]*scalar(ConsumoGW) + IngBasico*(1-0.061)*9.9/100
replace Otros = Otros*`otrosing'/INGRESOS[1,3]*scalar(OtrosIGW)

tabstat Ingreso Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOSSIM = r(StatTotal)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** B. ESTIMACIONES LP SIM **
tempname RECBase

* (+) Al ingreso *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/IngresoREC"', clear
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(IngresosLP) == 1 {
	replace estimacion = estimacion*INGRESOSSIM[1,1]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`alingreso'/`RECBase'[1,1]*lambda if anio > `anio'
	replace estimacion = estimacion*INGRESOSSIM[1,1]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/IngresoREC.dta"', replace


* (+) Al consumo *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/ConsumoREC"', clear 
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(ConsumoLP) == 1 {
	replace estimacion = estimacion*INGRESOSSIM[1,2]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`alconsumo'/`RECBase'[1,1]*lambda if anio != `anio'
	replace estimacion = estimacion*INGRESOSSIM[1,2]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/ConsumoREC.dta"', replace


* (+) Al capital *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/OtrosREC"', clear
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(OtrosILP) == 1 {
	replace estimacion = estimacion*INGRESOSSIM[1,3]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`otrosing'/`RECBase'[1,1]*lambda if anio != `anio'
	replace estimacion = estimacion*INGRESOSSIM[1,3]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/OtrosREC.dta"', replace





*******************************/
*** 5 Sistema Fiscal: GASTOS ***
********************************
noisily PEF if anio == `anio', anio(`anio') by(divGA) pef //graphs //update					<-- Parte 3.
local gastostot = r(Resumido_total)
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)
local CostoDeuda = r(Costo_de_la_deuda)
local Amort = r(Amortizaci_c_o__n)
local cuotasissste = r(Cuotas_ISSSTE)


** A. POBLACION SIM **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOS = r(StatTotal)

replace Pension = Pension*`Pensiones'/GASTOS[1,1]*PensionesGW
replace Educacion = Educacion*`Educacion'/GASTOS[1,2]*EducacionGW
replace Salud = Salud*`Salud'/GASTOS[1,3]*SaludGW
replace OtrosGas = OtrosGas*`OtrosGas'/GASTOS[1,4]*OtrosGasGW

tabstat Educacion Pension Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOSSIM = r(StatTotal)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** B. ESTIMACIONES LP SIM **

* (-) Pensiones *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC"', clear
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(PensionesLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,2]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`Pensiones'/`RECBase'[1,1]*lambda if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,2]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/PensionREC.dta"', replace


* (-) Educacion *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/EducacionREC"', clear
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(EducacionLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,1]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`Educacion'/`RECBase'[1,1]*lambda if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,1]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/EducacionREC.dta"', replace


* (-) Salud *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/SaludREC"', clear
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(SaludLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,3]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`Salud'/`RECBase'[1,1]*lambda if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,3]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/SaludREC.dta"', replace


* (-) Otros gastos *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/OtrosGasREC"', clear
merge 1:1 (anio) using `PIB', nogen keepus(lambda)
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
matrix `RECBase' = r(StatTotal)

if scalar(OtrosGasLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,4]/`RECBase'[1,1]*lambda
}
else {
	replace estimacion = estimacion*`OtrosGas'/`RECBase'[1,1]*lambda if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,4]/`RECBase'[1,1]*lambda if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/OtrosGasREC.dta"', replace





****************************************/
*** 6 Parte 4: Balance presupuestario ***
*****************************************
noisily di _newline(2) in g "{bf: POL{c I'}TICA FISCAL " in y "`anio'" "}"
noisily di in g "  (+) Ingresos: " ///
	_col(30) in y %20.0fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3]) in g " USD" ///
	_col(60) in y %8.1fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])/scalar(pibY)*100 in g "% PIB"
noisily di in g "  (-) Gastos: " ///
	_col(30) in y %20.0fc (GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY)) in g " USD" ///
	_col(60) in y %8.1fc (GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort')/scalar(pibY)*100 + scalar(IngBas) + scalar(Bienestar) in g "% PIB"
noisily di _dup(72) in g "-"
noisily di in g "  (=) Balance "in y "econ{c o'}mico" in g ": " ///
	_col(30) in y %20.0fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3] ///
	-(GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY))) in g " USD" ///
	_col(60) in y %8.1fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3] ///
	-(GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'))/scalar(pibY)*100 - scalar(IngBas) - scalar(Bienestar) in g "% PIB"
noisily di in g "  (*) Balance " in y "primario" in g ": " ///
	_col(30) in y %20.0fc (((INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])) ///
	-((GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY))) ///
	+`CostoDeuda') in g " USD" ///
	_col(60) in y %8.1fc (((INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])) ///
	-((GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort')) ///
	+`CostoDeuda')/scalar(pibY)*100 - scalar(IngBas) - scalar(Bienestar) in g "% PIB"


/** C. POBLACION SIMULADA **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

g TransfNetas = Ingreso + Consumo - Pension - Educacion - Salud -  IngBasico - PenBienestar
label var TransfNetas "Transferencias Netas"
Simulador TransfNetas if TransfNetas != 0 [fw=factor], base("ENIGH 2018") ///
	boot(1) reboot graphs

save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** D. CUENTAS GENERACIONALES **
noisily CuentasGeneracionales TransfNetas, //boot(250)							// <-- OPTIONAL!!! Toma mucho tiempo.


** E. FISCAL GAP **/
noisily FiscalGap, graphs end(2050) //boot(250) //update





********************/
*** 4. Touchdown! ***
*********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(3) in g "{bf:TOUCHDOWN! " in y %14.1fc round(`=r(t1)/r(nt1)',.1) in g " segs.}"
noisily di in g _dup(60) "~"
