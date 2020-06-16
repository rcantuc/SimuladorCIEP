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
noisily di _newline(15) in g _dup(77) "~"





********************
*** 1 ESCENARIOS ***
********************
global pais = "El Salvador"
local anio = 2020


** Pre-Covid19, lo que no fue **
global pib2019 = 2.4		// Banco Central de Reserva
global pib2020 = 2.5		// Ministerio de Hacienda

scalar OtrosGasLP = 0															// 1: largo plazo; 0: corto plazo
scalar OtrosGasGW = 1


/** Post-Covid19, escenario actual y pesimista **
global pib2020 = -5.6		// [-5.6,0.1]
global pib2021 = 1.5 		// [ 1.5,4.3]

scalar OtrosGasGW = 1.42


** Alternativa 1: Productividad **
global pib2021 = 4			// 169% PIB
global pib2022 = 4
global pib2023 = 4
global pib2024 = 4
global pib2025 = 4
global pib2026 = 4
global pib2027 = 4
global pib2028 = 4
global pib2029 = 4
global pib2030 = 4
*global lambda = 2			// 165% PIB


** Alternativa 2: Aumentar ingresos **/
scalar IngresoLP = 0 //1														// 1: largo plazo; 0: corto plazo
scalar IngresoGW = (1+(${pib2020}-2.5)*2.785/100) // *1.4 //1.15

scalar ConsumoLP = 0 //1														// 1: largo plazo; 0: corto plazo
scalar ConsumoGW = (1+(${pib2020}-2.5)*1.568/100) // *1.4 //1.15

scalar OtrosLP = 0 //1															// 1: largo plazo; 0: corto plazo
scalar OtrosGW = (1+(${pib2020}-2.5)*2.248/100) // *1.4 //1.15


** Alternativa 3: Reducir gastos **
scalar PensionLP = 1															// 1: largo plazo; 0: corto plazo
scalar PensionGW = 1 // *.85

scalar EducacionLP = 1															// 1: largo plazo; 0: corto plazo
scalar EducacionGW = 1 // *.85

scalar SaludLP = 1																// 1: largo plazo; 0: corto plazo
scalar SaludGW = 1 // *.85

*scalar OtrosGasLP = 1															// 1: largo plazo; 0: corto plazo
*scalar OtrosGasGW = .85


** INGRESO BASICO **
scalar IngBas = 0
scalar IngBasLP = 0							// 1: largo plazo; 0: corto plazo

scalar ingbasico18 = 1						// Incluye menores de 18 anios
scalar ingbasico65 = 1						// Incluye mayores de 65 anios


** PENSION BIENESTAR **
scalar Bienestar = 0
scalar BienestarLP = 0						// 1: largo plazo; 0: corto plazo


** Economía BASE **/
noisily PIBDeflactor, graphs //update //discount(3.0)									<-- Cap. 3. Par{c a'}metros MACRO.
tempfile PIB
save `PIB'


** Poblacion BASE: 2018 **
if "`c(os)'" == "Unix" & "go" == "no" {
	noisily run HouseholdsElSalvador.do 2018 graphs
}





*********************************/
*** 3 Sistema Fiscal: INGRESOS ***
**********************************
noisily LIF if anio == `anio', anio(`anio') by(divGA) lif //graphs //update					<-- Parte 2.
local ingresostot = r(Ingresos_sin_deuda)
local Ingreso = r(Impuestos_al_ingreso)
local Consumo = r(Impuestos_al_consumo)
local Otros = r(Otros_ingresos)


** A. POBLACION SIM **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
tabstat Ingreso Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOS = r(StatTotal)

replace Ingreso = Ingreso*`Ingreso'/INGRESOS[1,1]*scalar(IngresoGW)
replace Consumo = Consumo*`Consumo'/INGRESOS[1,2]*scalar(ConsumoGW) + IngBasico*(1-0.061)*9.9/100
replace Otros = Otros*`Otros'/INGRESOS[1,3]*scalar(OtrosGW)

tabstat Ingreso Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOSSIM = r(StatTotal)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** B. ESTIMACIONES LP SIM **
tempname RECBase
local j = 1
foreach k in Ingreso Consumo Otros {
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `RECBase' = r(StatTotal)

	if scalar(`k'LP) == 1 {
		replace estimacion = estimacion*INGRESOSSIM[1,`j']/`RECBase'[1,1]*lambda
	}
	else {
		replace estimacion = estimacion*``k''/`RECBase'[1,1]*lambda if anio != `anio'
		replace estimacion = estimacion*INGRESOSSIM[1,`j']/`RECBase'[1,1]*lambda if anio == `anio'
	}
	local ++j
	save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace
}





*******************************/
*** 4 Sistema Fiscal: GASTOS ***
********************************
noisily PEF if anio == `anio', anio(`anio') by(divGA) pef //graphs //update					<-- Parte 3.
local gastostot = r(Resumido_total)
local OtrosGas = r(Otros)
local Pension = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)
local CostoDeuda = r(Costo_de_la_deuda)
local Amort = r(Amortizaci_c_o__n)
local cuotasissste = r(Cuotas_ISSSTE)


** A. POBLACION SIM **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOS = r(StatTotal)

replace Pension = Pension*`Pension'/GASTOS[1,1]*PensionGW
replace Educacion = Educacion*`Educacion'/GASTOS[1,2]*EducacionGW
replace Salud = Salud*`Salud'/GASTOS[1,3]*SaludGW
replace OtrosGas = OtrosGas*`OtrosGas'/GASTOS[1,4]*OtrosGasGW

tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOSSIM = r(StatTotal)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** B. ESTIMACIONES LP SIM **
local j = 1
foreach k in Pension Educacion Salud OtrosGas {
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `RECBase' = r(StatTotal)

	if scalar(`k'LP) == 1 {
		replace estimacion = estimacion*GASTOSSIM[1,`j']/`RECBase'[1,1]*lambda
	}
	else {
		replace estimacion = estimacion*``k''/`RECBase'[1,1]*lambda if anio != `anio'
		replace estimacion = estimacion*GASTOSSIM[1,`j']/`RECBase'[1,1]*lambda if anio == `anio'
	}
	local ++j
	save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace
}



****************************************/
*** 5 Parte 4: Balance presupuestario ***
*****************************************
noisily di _newline(2) in g "{bf: POL{c I'}TICA FISCAL: }" in y "{bf:$pais} `anio'"
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
noisily FiscalGap, graphs end(2050) //intervencion //boot(250) //update





********************/
*** 4. Touchdown! ***
*********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(3) in g "{bf:TOUCHDOWN! " in y %14.1fc round(`=r(t1)/r(nt1)',.1) in g " segs.}"
noisily di in g _dup(77) "~"
