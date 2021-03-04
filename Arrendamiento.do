**********************
*** 1. DATOS MACRO ***
**********************
clear programs
global anioVP = 2018
if "`c(os)'" == "Unix" {
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/BID SHCP/4.10.1 (BID-SHCP)"
}
if "`c(os)'" == "MacOSX" {
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/BID SHCP/4.10.1 (BID-SHCP)"
}
if "`c(os)'" == "Windows" {
	sysdir set PERSONAL "C:\Users\L00492215\Dropbox (CIEP)\BID SHCP\4.10.1 (BID-SHCP)"
}
noisily di _newline(50)





*****************************
** 1.1. Cuentas Nacionales **
noisily di _newline(2) in g "{bf:1. Sistema de Cuentas Nacionales}"

SCN, anio(2016)
local PIBSCN = r(PIB)
local SNAAlquiler = r(Alquileres)
local SNAExBOpHog = r(ExBOpHog)
local SNAInmobiliarias = r(Inmobiliarias)

noisily di _newline in g "{bf:Cuentas Nacionales" ///
	_col(33) %20s "Recaudaci${o}n" ///
	_col(55) %7s in g "% PIB" "}"
noisily di in g "Alquileres e inmobiliarias: " ///
	_col(33) in y %20.0fc (`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog') ///
	_col(55) in y %7.3fc (`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog')/`PIBSCN'*100
noisily di in g "Alquileres de bienes ra${i}ces: " ///
	_col(33) in y %20.0fc (`SNAAlquiler'-`SNAExBOpHog') ///
	_col(55) in y %7.3fc (`SNAAlquiler'-`SNAExBOpHog')/`PIBSCN'*100



******************************
** 1.2. Sistema Fiscal: LIF **
noisily di _newline(2) in g "{bf:2. Recaudaci${o}n}"

LIF, anio(2016)
local ISRFisicas = r(ISR__PF_)
local alquilerPF = 10772.3*1000000

use "`c(sysdir_personal)'/bases/SAT/Personas fisicas/Stata/2015_labels.dta", clear
tabstat basegrav deducpersonales iaarrendamiento isrcausado, stat(sum) f(%20.0fc) save
tempname SAT
matrix `SAT' = r(StatTotal)

noisily di _newline in g "{bf:SHCP, Informes trimestrales" ///
	_col(33) %20s "Recaudaci${o}n" ///
	_col(55) %7s in g "% PIB" "}"
noisily di in g "ISR por arrendamiento PF: " ///
	_col(33) in y %20.0fc `alquilerPF' ///
	_col(55) in y %7.3fc (`alquilerPF')/`PIBSCN'*100
noisily di in g "ISR (personas f${i}sicas): " ///
	_col(33) in y %20.0fc `ISRFisicas' ///
	_col(55) in y %7.3fc `ISRFisicas'/`PIBSCN'*100

noisily di _newline in g "{bf:SAT, Declaraciones anuales" ///
	_col(33) %20s "Recaudaci${o}n" ///
	_col(55) %7s in g "% PIB" "}"
noisily di in g "Ingresos por arrendamiento: " ///
	_col(33) in y %20.0fc `SAT'[1,3]*(1+5.3370265/100) ///
	_col(55) in y %7.3fc (`SAT'[1,3]*(1+5.3370265/100))/`PIBSCN'*100
noisily di in g "Deducciones personales: " ///
	_col(33) in y %20.0fc `SAT'[1,2]*(1+5.3370265/100) ///
	_col(55) in y %7.3fc (`SAT'[1,2]*(1+5.3370265/100))/`PIBSCN'*100





*************************
*** 2. ESCENARIO BASE ***
*************************
noisily di _newline(2) in g "{bf:3. ENIGH 2016. Escenario base.}"

noisily run "`c(sysdir_personal)'/Income.do"





*************************
*** 3. DEDUCIR RENTAS ***
*************************
noisily di _newline(2) in g "{bf:4. ISR alquileres}"

use "`c(sysdir_personal)'/bases/SIM/2016/income`c(os)'.dta", clear
tabstat renta ing_rent deduc_isr [aw=factor_cola] if formal != 0, stat(sum) f(%20.0fc) save
matrix RENTA = r(StatTotal)

* Escenario 1 *
replace deduc_isr = deduc_isr + .3*renta if .3*renta <= 50000
replace deduc_isr = deduc_isr + 50000 if .3*renta > 50000
replace formal_renta = 1 if ing_renta_accum < RENTA[1,1] & prob != .
replace formal = 1 if ing_renta_accum < RENTA[1,1] & formal == 0 & formal_renta == 1 & prob != .
replace formal_renta = 0 if ing_renta_accum > RENTA[1,1] & prob != .
*replace formal_renta = 1 if ing_rent != 0

save "`c(sysdir_personal)'/bases/SIM/2016/income`c(os)'_BID_SHCP.dta", replace



*************************
** 3.1. RECALCULAR ISR **
noisily ISR using "`c(sysdir_personal)'/bases/SIM/2016/income`c(os)'_BID_SHCP.dta"


* Escenario 3 *
*replace ISR__PF2 = ISR__PF2 - .1*renta if formal != 0


* Results *
Gini ISR__PF2, hogar(folioviv foliohog) individuo(numren) factor(factor_cola)
local gini_ISR__PF = r(gini_ISR__PF2)

tabstat ISR__asalariados ISR__PF2 [aw=factor_cola], stat(sum) f(%25.2fc) save
tempname RESTAX
matrix `RESTAX' = r(StatTotal)

noisily di _newline(2) in g "{bf: Paso 3: Sumar ingresos por individuo y re-calcular ISR}"
noisily di _newline in g "{bf: F. ISR anual" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "ENIGH" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di in g "  ISR personas f${i}sicas" ///
	_col(44) in y "(" %5.3fc `gini_ISR__PF' ")" ///
	_col(57) in y %7.3fc `RESTAX'[1,2]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRFisicas'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAX'[1,2]/`ISRFisicas'-1)*100 "%"

tabstat ing_bruto_tax ISR__PF2 if ing_rent != 0 [aw=factor_cola], stat(sum) f(%20.0fc) save
tempname TASA
matrix `TASA' = r(StatTotal)

noisily di _newline(2) in g "  Crecimiento ISR (arrendamiento): " in y %7.1fc ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/((`alquilerPF')/`PIBSCN'*100)*100 in g "%"
noisily di in g "  Crecimiento ISR (arrendamiento): " in y %7.3fc (`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH
noisily di in g "  Tasa efectiva ISR: " in y %7.1fc `TASA'[1,2]/`TASA'[1,1]*100 in g "%"

global crec_ISR_arre = ((`RESTAX'[1,2]/`PIBSCN'*100)/$isrPF_ENIGH-1 )*100



*********************
** 3.2. EFICIENCIA **
noisily di _newline in g "{bf:  Cuentas Nacionales" ///
	_col(44) %7s in g "% PIB" ///
	_col(55) "Recaudaci${o}n" ///
	_col(88) %7s in g "% PIB" ///
	_col(99) in g "Tasa efectiva" "}"
noisily di in g "  Alquiler de bienes ra${i}ces (- alq. imp.)" ///
	_col(44) %7.3fc in y (`SNAAlquiler'-`SNAExBOpHog')/`PIBSCN'*100 ///
	_col(55) in g "ISR (arrendamiento PF)" ///
	_col(88) %7.3fc in y (`alquilerPF' + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/`PIBSCN'*100 ///
	_col(99) %7.1fc in y (`alquilerPF' + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/(`SNAAlquiler'-`SNAExBOpHog')*100 " %"





***************************************
*** 4. DEDUCIR GASTOS PROFESIONALES ***
/***************************************
noisily di _newline(2) in g "{bf:5. ISR servicios profesionales}"

use "`c(sysdir_personal)'/bases/SIM/2016/income`c(os)'.dta", clear
tabstat renta ing_rent deduc_isr gasto_profesi [aw=factor_cola] if formal != 0, stat(sum) f(%20.0fc) save
matrix RENTA = r(StatTotal)

* Escenario 1 *
replace deduc_isr = deduc_isr + gasto_profesi if gasto_profesi <= 50000
replace deduc_isr = deduc_isr + 50000 if gasto_profesi > 50000
replace formal_renta = 1 if ing_renta_accum < RENTA[1,1] & prob != .
replace formal = 1 if ing_renta_accum < RENTA[1,1] & formal == 0 & formal_renta == 1 & prob != .
replace formal_renta = 0 if ing_renta_accum > RENTA[1,1] & prob != .
*replace formal_renta = 1 if ing_rent != 0

save "`c(sysdir_personal)'/bases/SIM/2016/income`c(os)'_BID_SHCP2.dta", replace



*************************
** 4.1. RECALCULAR ISR **
noisily ISR using "`c(sysdir_personal)'/bases/SIM/2016/income`c(os)'_BID_SHCP2.dta"


* Escenario 3 *
replace ISR__PF2 = ISR__PF2 - .01*gasto_profesi


* Results *
Gini ISR__PF2, hogar(folioviv foliohog) individuo(numren) factor(factor_cola)
local gini_ISR__PF = r(gini_ISR__PF2)

tabstat ISR__asalariados ISR__PF2 [aw=factor_cola], stat(sum) f(%25.2fc) save
tempname RESTAX
matrix `RESTAX' = r(StatTotal)

noisily di _newline(2) in g "{bf: Paso 3: Sumar ingresos por individuo y re-calcular ISR}"
noisily di _newline in g "{bf: F. ISR anual" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "ENIGH" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di in g "  ISR personas f${i}sicas" ///
	_col(44) in y "(" %5.3fc `gini_ISR__PF' ")" ///
	_col(57) in y %7.3fc `RESTAX'[1,2]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRFisicas'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAX'[1,2]/`ISRFisicas'-1)*100 "%"


