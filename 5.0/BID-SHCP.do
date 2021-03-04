****************************
****                    ****
**** PROYECTO: BID-SHCP ****
****                    ****
****************************
clear all
if "`c(os)'" == "Unix" {
	*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/BID SHCP/4.10.1 (BID-SHCP)"
}
if "`c(os)'" == "MacOSX" {
	*sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/BID SHCP/4.10.1 (BID-SHCP)"
}
if "`c(os)'" == "Windows" {
	*sysdir set PERSONAL "C:\Users\L00492215\Dropbox (CIEP)\BID SHCP\4.10.1 (BID-SHCP)"
}
noisily di _newline(50)
clear programs
timer on 1





**************************
*** 1. ISR: Alquileres ***
**************************
noisily di _newline(5) in w "{bf:1. ISR, ARRENDAMIENTO Y EN GENERAL POR OTORGAR " ///
	"EL USO O GOCE TEMPORAL DE BIENES INMUEBLES (T${i}tulo II, Cap${i}tulo III)}"



****************************************
** 1.1. Sistema de Cuentas Nacionales **
local anio = 2016

SCN, anio(`anio') //update
local PIBSCN = r(PIB)
local SNAAlquiler = r(Alquileres)
local SNAExBOpHog = r(ExBOpHog)
local SNAInmobiliarias = r(Inmobiliarias)
local SNAAlojamiento = r(Alojamiento)
local smdf = 73.04

PIBDeflactor, aniovp(`anio')
forvalues k = 1(1)`=_N' {
	if anio[`k'] == 2015 {
		local deflactor = deflator[`k']
		continue, break
	}
}


*************
** DISPLAY **
noisily di _newline(2) "{bf:" ///
	_col(04) in g "A. Sistema de Cuentas Nacionales: " in y "`anio'" ///
	_col(55) in g %20s "Recaudaci${o}n" ///
	_col(75) in g %7s in g "% PIB" ///
	"}"
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(+) Alquileres sin intermediaci${o}n de B. R. (5311): " ///
	_col(55) in y %20.0fc (`SNAAlquiler') ///
	_col(75) in y %7.3fc (`SNAAlquiler')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(-) Alquiler imputado (Ex. B. Op. Hog.): " ///
	_col(55) in y %20.0fc (`SNAExBOpHog') ///
	_col(75) in y %7.3fc (`SNAExBOpHog')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(=) Alquileres sin intermediaci${o}n de B. R. (neto): " ///
	_col(55) in y %20.0fc (`SNAAlquiler'-`SNAExBOpHog') ///
	_col(75) in y %7.3fc (`SNAAlquiler'-`SNAExBOpHog')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) Inmobiliarias y corredores (5312)" ///
	_col(55) in y %20.0fc (`SNAInmobiliarias') ///
	_col(75) in y %7.3fc (`SNAInmobiliarias')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(=) Servicios inmobiliarias (531, neto): " ///
	_col(55) in y %20.0fc (`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog') ///
	_col(75) in y %7.3fc (`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(.) Alquileres efect. de aloja. (hog. e ISFLSH): " ///
	_col(55) in y %20.0fc (`SNAAlojamiento'-`SNAExBOpHog') ///
	_col(75) in y %7.3fc (`SNAAlojamiento'-`SNAExBOpHog')/`PIBSCN'*100



*************************
** 1.2. Sistema Fiscal **
LIF, anio(`anio')
local ISRFisicas = r(ISR__PF_)
if `anio' == 2017 {
	local alquilerPF = 15615.5*1000000 //(2017)
	local alquilerPM = 45490.0*1000000 //(2017)
}
if `anio' == 2016 {
	local alquilerPF = 10772.3*1000000 //(2016)
	local alquilerPM = 44234.8*1000000 //(2016)
}
local predial = 103283002528


use "`c(sysdir_personal)'/bases/SAT/Personas fisicas/Stata/2015_labels.dta", clear
tabstat basegrav deducpersonales iaarrendamiento isrcausado, stat(sum) f(%20.0fc) save
tempname SAT
matrix `SAT' = r(StatTotal)


*************
** DISPLAY **
noisily di _newline(2) "{bf:" ///
	_col(04) in g "B. SAT, Declaraciones anuales: " in y "2015/`deflactor'" ///
	_col(55) in g %20s "Recaudaci${o}n" ///
	_col(75) in g %7s "% PIB" "}"
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(+) Ingresos por arrendamiento: " ///
	_col(55) in y %20.0fc (`SAT'[1,3]/`deflactor'/.65) ///
	_col(75) in y %7.3fc (`SAT'[1,3]/`deflactor'/.65)/`PIBSCN'*100
noisily di ///
	_col(04) in g "(-) Ingresos exentos por arrendamiento (35%): " ///
	_col(55) in y %20.0fc (`SAT'[1,3]/`deflactor'/.65*.35) ///
	_col(75) in y %7.3fc (`SAT'[1,3]/`deflactor'/.65*.35)/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(=) Ingresos acumulables por arrendamiento (65%): " ///
	_col(55) in y %20.0fc (`SAT'[1,3]/`deflactor') ///
	_col(75) in y %7.3fc (`SAT'[1,3]/`deflactor')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(.) Deducciones personales: " ///
	_col(55) in y %20.0fc `SAT'[1,2]/`deflactor' ///
	_col(75) in y %7.3fc (`SAT'[1,2]/`deflactor')/`PIBSCN'*100

noisily di _newline(2) "{bf:" ///
	_col(04) in g "C. SHCP, Informes trimestrales: " in y "`anio'-IV" ///
	_col(55) in g %20s "Recaudaci${o}n" ///
	_col(75) in g %7s "% PIB" "}"
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(+) ISR por arrendamiento PF: " ///
	_col(55) in y %20.0fc `alquilerPF' ///
	_col(75) in y %7.3fc (`alquilerPF')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) ISR por arrendamiento PM: " ///
	_col(55) in y %20.0fc `alquilerPM' ///
	_col(75) in y %7.3fc (`alquilerPM')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(=) ISR por arrendamiento: " ///
	_col(55) in y %20.0fc `alquilerPF'+`alquilerPM' ///
	_col(75) in y %7.3fc (`alquilerPF'+`alquilerPM')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(.) Predial y agua: " ///
	_col(55) in y %20.0fc `predial' ///
	_col(75) in y %7.3fc `predial'/`PIBSCN'*100



****************
/** 1.3. ENIGH **
noisily di _newline(2) "{bf:" ///
	_col(04) in g "D. Escenario base: " in y "ENIGH 2018" "}"

noisily run "`c(sysdir_personal)'/Income.do"



********************************/
/** 1.4. ESCENARIOS ALQUILERES **
noisily di _newline(2) "{bf:" ///
	_col(04) in g "E. Escenarios: " in y "Alquileres" "}"

local escens "escen3" //"escen0 escen1 escen2 escen3"

foreach escenario of local escens {
	*postfile `escenario' deduccion cumplimiento pib alquiler using "`c(sysdir_personal)'/`escenario'.dta", replace
}

forvalues cumplimiento=1(.1)1 {
	foreach deduccion of numlist /*0*/ .1 /*.2 .3 .4 .5 .12 .14 .16 .18 .02 .04 .06 .08*/ {
		foreach escenario of local escens {
			forvalues repeticion=1(1)100 {

				use "`c(sysdir_personal)'/bases/SIM/2016/income.dta", clear

				* Consumo de rentas por personas formales *
				tabstat renta [aw=factor_cola] if formal != 0, stat(sum) f(%20.0fc) save
				matrix RENTA = r(StatTotal)


				* Fiscalizacion. Escenario 0. *
				if "`escenario'" == "escen0" {
					if `deduccion' == 0 {
						noisily di _newline(2) ///
							in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'." ///
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							in g " Repetici${o}n: " in y %3.0fc `repeticion' ///
							"}"


						* Step 1. Cut-off *
						*set seed 1111
						g fiscal_renta = runiform() if ing_rent != 0 & formal == 0


						* Step 2. Proporcion de cumplimiento *
						noisily tabstat formal_renta [fw=factor_hog] if prob_renta != ., stat(sum) f(%20.0fc)
						replace formal_renta = 1 if fiscal_renta <= `cumplimiento' & fiscal_renta != .
						noisily tabstat formal_renta [fw=factor_hog], stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'
					}
					else {
						continue
					}
				}


				* Escenario 1 *
				if "`escenario'" == "escen1" {
					if (`deduccion' == .1 | `deduccion' >= .2 | `deduccion' == 0) & `repeticion' == 1 {
						noisily di _newline(2) ///
							in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'." ///
							in g " Deducci${o}n: " in y %3.0fc `deduccion'*100 " % Rentas" ///
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							"}"


						* Consumo de renta por personas formales *
						gsort -prob_renta_cons
						egen hogar_renta_accum = sum(factor_hog) if prob_renta_cons != . & formal != 0
						g formal_renta_accum = sum(formal*factor_hog) if prob_renta_cons != . & formal != 0
						g prop_formal_renta = formal_renta_accum/hogar_renta_accum


						* Step 1. Proporcion de cumplimiento (consumo) *
						capture tabstat renta [aw=factor_cola] if formal != 0 & prop_formal_renta <= `cumplimiento', stat(sum) f(%20.0fc) save
						if _rc == 0 {
							matrix RENTA = r(StatTotal)
						}
						else {
							matrix RENTA = J(1,1,0)
						}

						* Deduccion *
						replace deduc_isr = deduc_isr + `deduccion'*renta if `deduccion'*renta <= 2*`smdf'*365 & prop_formal_renta <= `cumplimiento'
						replace deduc_isr = deduc_isr + 2*`smdf'*365 if `deduccion'*renta > 2*`smdf'*365 & prop_formal_renta <= `cumplimiento'


						* Step 2. Cut-off *
						noisily tabstat formal_renta [fw=factor_hog] if prob_renta != ., stat(sum) f(%20.0fc)
						replace formal_renta = 1 if ing_renta_accum_hog <= RENTA[1,1] & prob_renta != .
						*replace formal_renta = 0 if ing_renta_accum_hog > RENTA[1,1] & prob_renta != .
						noisily tabstat formal_renta [fw=factor_hog], stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'
					}
					else {
						continue
					}
				}


				* Escenario 2 *
				global escen2 = 0
				if "`escenario'" == "escen2" {
					if (`deduccion' <= .2 & `deduccion' >= .1) & `repeticion' == 1 {
						noisily di _newline(2) ///
							in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'." ///
							in g " Riesgo " in y %3.0fc `deduccion'*100 " > % Tasa Efectiva" ///
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							"}"

						global escen2 = 1


						* Produccion de renta por personas formales *
						gsort -prob_renta
						egen hogar_renta_accum = sum(factor_hog) if prob_renta != . //& formal_renta != 0
						g formal_renta_accum = sum(factor_hog) if prob_renta != . //& formal_renta != 0
						g prop_formal_renta = formal_renta_accum/hogar_renta_accum


						* Step 1. Cut-off *
						tempvar formal_original
						g `formal_original' = formal_renta
						noisily tabstat formal_renta [fw=factor_hog] if prob_renta != ., stat(sum) f(%20.0fc)
						replace formal_renta = 1 if TE >= `deduccion' & prob_renta != . & prop_formal_renta <= `cumplimiento'
						*replace formal_renta = 0 if TE < `deduccion' & prob_renta != .


						* Step 2. Proporcion de cumplimiento (produccion) *
						*replace formal_renta = 0 if prop_formal_renta > `cumplimiento' & `formal_original' == 0
						noisily tabstat formal_renta [fw=factor_hog], stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'
						replace ISR__PF2 = ISR__PF2 + (ing_rent - exen_rent)*.1 if formal_renta == 1 & prop_formal_renta <= `cumplimiento'
					}
					else {
						continue
					}
				}


				* Escenario 3 *
				if "`escenario'" == "escen3" {
					if `deduccion' <= .1 & `repeticion' == 1 {
						noisily di _newline(2) ///
							in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'." ///
							in g " Cr${e}dito fiscal: " in y %3.0fc `deduccion'*100 " % Rentas" ///
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							"}"


						* Consumo de renta por personas formales *
						gsort -prob_renta_cons
						egen hogar_renta_accum = sum(factor_hog) if prob_renta_cons != . & formal != 0
						g formal_renta_accum = sum(formal*factor_hog) if prob_renta_cons != . & formal != 0
						g prop_formal_renta = formal_renta_accum/hogar_renta_accum


						* Step 1. Proporcion de cumplimiento (consumo) *
						capture tabstat renta [aw=factor_cola] if formal != 0 & prop_formal_renta <= `cumplimiento', stat(sum) f(%20.0fc) save
						if _rc == 0 {
							matrix RENTA = r(StatTotal)
						}
						else {
							matrix RENTA = J(1,1,0)
						}

						* Step 2. Cut-off *
						noisily tabstat formal_renta [fw=factor_hog] if prob_renta != ., stat(sum) f(%20.0fc)
						replace formal_renta = 1 if ing_renta_accum_hog <= RENTA[1,1] & prob_renta != .
						*replace formal_renta = 0 if ing_renta_accum_hog > RENTA[1,1] & prob_renta != .
						noisily tabstat formal_renta [fw=factor_hog] if prob_renta != ., stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'

						* Credito fiscal *
						replace ISR__PF2 = ISR__PF2 - `deduccion'*renta if `deduccion'*renta <= 2*`smdf'*365 & prop_formal_renta <= `cumplimiento'
						replace ISR__PF2 = ISR__PF2 - 2*`smdf'*365 if `deduccion'*renta > 2*`smdf'*365 & prop_formal_renta <= `cumplimiento'
					}
					else {
						continue
					}
				}



				*********************
				** 1.6. RESULTADOS **
				tabstat ISR__asalariados ISR__PF2 [aw=factor_cola], stat(sum) f(%25.2fc) save
				tempname RESTAX
				matrix `RESTAX' = r(StatTotal)

				capture tabstat ing_rent [aw=factor_cola] if formal_renta != 0 & prob_renta != ., stat(sum) f(%20.0fc) save
				if _rc == 0 {
					tempname RENTA2
					matrix `RENTA2' = r(StatTotal)
				}
				else {
					tempname RENTA2
					matrix `RENTA2' = J(1,1,0)
				}

				tabstat ing_bruto_tax ISR__PF2 if ing_rent != 0 [aw=factor_cola], stat(sum) f(%20.0fc) save
				tempname TASA
				matrix `TASA' = r(StatTotal)

				noisily di _newline ///
					_col(04) in g "{bf:Cuentas Nacionales" ///
					_col(44) %7s in g "% PIB" ///
					_col(55) "Recaudaci${o}n" ///
					_col(88) %7s in g "% PIB" ///
					_col(99) in g "Tasa efectiva" "}"
				noisily di _col(04) _dup(108) in g "-"
				noisily di ///
					_col(04) in g "Servicios inmobiliarios (65%, neto)" ///
					_col(44) %7.3fc in y (`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog')*.65/`PIBSCN'*100 ///
					_col(55) in g "ISR (arrendamiento PF + PM)" ///
					_col(88) %7.3fc in y (`alquilerPF' + `alquilerPM' + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/`PIBSCN'*100 ///
					_col(99) %7.1fc in y (`alquilerPF' + `alquilerPM' + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/((`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog')*.65)*100 " %"
				noisily di ///
					_col(04) in g "Ingresos acum. por arrendamiento PF" ///
					_col(44) %7.3fc in y (`RENTA2'[1,1]*.65)/`PIBSCN'*100 ///
					_col(55) in g "ISR (arrendamiento PF)" ///
					_col(88) %7.3fc in y (`alquilerPF' + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/`PIBSCN'*100 ///
					_col(99) %7.1fc in y (`alquilerPF' + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/(`RENTA2'[1,1]*.65)*100 " %"

				noisily di _newline ///
					_col(04) in g "Crecimiento ISR (arrendamiento): " ///
					_col(44) in y %7.1fc ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/((`alquilerPF')/`PIBSCN'*100)*100 in g " %"
				noisily di ///
					_col(04) in g "Crecimiento ISR (arrendamiento): " ///
					_col(44) in y %7.3fc (`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH in g " % PIB"
				noisily di ///
					_col(04) in g "Crecimiento ISR (arrendamiento): " ///
					_col(44) in y %7.0fc ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/100*$PIB2018/1000000 in g " millones de MXN de 2018"

				*post `escenario' (`deduccion') (`cumplimiento') ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH) (((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/100*$PIB2018/1000000)
			}
		}
	}
}

foreach escenario of local escens {
	*postclose `escenario'
}


********************/
/*** 1.7 GRAFICAS ***
use "`c(sysdir_personal)'/escen0.dta", clear
twoway (lpolyci alquiler cumplimiento if round(deduccion,.1) == 0), ///
	title({bf:Alquileres (mayor fiscalizaci${o}n)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas informales que son auditados.") ///
	ylabel(, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	legend(label(1 "Selecci${o}n aleatoria uniforme")) ///
	name(escen0, replace)
graph save escen0 ./users/escen0.gph, replace
graph export ./users/escen0.png, name(escen0) replace

use "`c(sysdir_personal)'/escen1.dta", clear
twoway (connect alquiler cumplimiento if round(deduccion,.01) == .1) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .2) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .3) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .4) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .5), ///
	title({bf:Alquileres: rentas deducibles (escenario 1)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas formales que piden facturas.") ///
	ylabel(, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	xline(.20, lcolor(green) lpattern(dash)) ///
	xline(.21, lcolor(green) lpattern(dash)) ///
	text(0 .205 "20%-21%", placement(n)) ///
	legend(label(1 "Deducci${o}n 10%") label(2 "Deducci${o}n 20%") ///
	label(3 "Deducci${o}n 30%") label(4 "Deducci${o}n 40%") ///
	label(5 "Deducci${o}n 50%")) ///
	name(escen1, replace)
graph save escen1 ./users/escen1.gph, replace
graph export ./users/escen1.png, name(escen1) replace

use "`c(sysdir_personal)'/escen2.dta", clear
twoway (connect alquiler cumplimiento if round(deduccion,.01) == .1) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .12) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .14) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .16) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .18) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .2), ///
	title({bf:Alquileres: tasa reducida (escenario 2)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas que tienen una tasa efectiva mayor al estipulado.") ///
	ylabel(, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	xline(.43, lcolor(green) lpattern(dash)) ///
	text(0 .43 "43%", placement(n)) ///
	xline(.53, lcolor(green) lpattern(dash)) ///
	text(0 .53 "53%", placement(n)) ///
	legend(label(1 "Tasa efectiva 10%") label(2 "Tasa efectiva 12%") ///
	label(3 "Tasa efectiva 14%") label(4 "Tasa efectiva 16%") ///
	label(5 "Tasa efectiva 18%") label(6 "Tasa efectiva 20%")) ///
	name(escen2, replace)
graph save escen2 ./users/escen2.gph, replace
graph export ./users/escen2.png, name(escen2) replace

use "`c(sysdir_personal)'/escen3.dta", clear
twoway (connect alquiler cumplimiento if round(deduccion,.01) == .02) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .04) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .06) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .08) ///
	(connect alquiler cumplimiento if round(deduccion,.01) == .1), ///
	title({bf:Alquileres: cr${e}dito fiscal (escenario 3)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas formales que piden facturas.") ///
	ylabel(20000(-10000)-40000, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	xline(.25, lcolor(green) lpattern(dash)) ///
	text(0 .25 "25%", placement(n)) ///
	xline(.75, lcolor(green) lpattern(dash)) ///
	text(0 .75 "75%", placement(n)) ///
	legend(label(1 "Cr${e}dito 2%") label(2 "Cr${e}dito 4%") ///
	label(3 "Cr${e}dito 6%") label(4 "Cr${e}dito 8%") ///
	label(5 "Cr${e}dito 10%")) ///
	name(escen3, replace)
graph save escen3 ./users/escen3.gph, replace
graph export ./users/escen3.png, name(escen3) replace




****************************************/
*** 2. ISR: ACTIVIDADES PROFESIONALES ***
*****************************************
noisily di _newline(5) in w "{bf:2. ISR, ACTIVIDADES EMPRESARIALES Y PROFESIONALES (T${i}tulo II, Cap${i}tulo II, Secci${o}n I)}"



****************************************
** 2.1. Sistema de Cuentas Nacionales **
SCN, anio(`anio') update
local PIBSCN = r(PIB)
local ServProf = r(ServProf)
local ConsMedi = r(ConsMedi)
local ConsDent = r(ConsDent)
local ConsOtro = r(ConsOtro)
local EnfeDomi = r(EnfeDomi)
local ServProfH = 67849000000							//.96519958
local SaludH = 196882000000
local smdf = 73.04


noisily di _newline(2) "{bf:" ///
	_col(04) in g "A. Sistema de Cuentas Nacionales: " in y "`anio'" ///
	_col(55) in g %20s "Recaudaci${o}n" ///
	_col(75) in g %7s in g "% PIB" ///
	"}"
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(+) Servicios prof., cient. y t${e}c. (54): " ///
	_col(55) in y %20.0fc (`ServProf') ///
	_col(75) in y %7.3fc (`ServProf')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) Consultorios m${e}dicos (6211): " ///
	_col(55) in y %20.0fc (`ConsMedi') ///
	_col(75) in y %7.3fc (`ConsMedi')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) Consultorios dentales (6212): " ///
	_col(55) in y %20.0fc (`ConsDent') ///
	_col(75) in y %7.3fc (`ConsDent')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) Otros consultorios (6213): " ///
	_col(55) in y %20.0fc (`ConsOtro') ///
	_col(75) in y %7.3fc (`ConsOtro')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) Enfermer${i}a a domicilio (6216): " ///
	_col(55) in y %20.0fc (`EnfeDomi') ///
	_col(75) in y %7.3fc (`EnfeDomi')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(=) Servicios profesionales y salud: " ///
	_col(55) in y %20.0fc (`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi') ///
	_col(75) in y %7.3fc (`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(.) Servicios prof., cient. y t${e}c. (cons. hog.): " ///
	_col(55) in y %20.0fc (`ServProfH') ///
	_col(75) in y %7.3fc (`ServProfH')/`PIBSCN'*100
noisily di ///
	_col(04) in g "(.) Servicios salud y asis. social (cons. hog.): " ///
	_col(55) in y %20.0fc (`SaludH') ///
	_col(75) in y %7.3fc (`SaludH')/`PIBSCN'*100



*************************
** 2.2. Sistema Fiscal **
LIF, anio(`anio')
local ISRFisicas = r(ISR__PF_)
local ISRPFEmpre = 18144.4*1000000
if `anio' == 2016 {
	local ISRActProf = 11702.2*1000000						//14451.4*1000000 //
	local ISRActProfPM = 91932.7*1000000						//102108.5*1000000 //
}
if `anio' == 2017 {
	local ISRActProf = 14451.4*1000000 // 2017
	local ISRActProfPM = 102108.5*1000000 // 2017

}
local ISRSalud = 1294.0*1000000


use "`c(sysdir_personal)'/bases/SAT/Personas fisicas/Stata/2015_labels.dta", clear
tabstat utgravacumap deducpersonales utgravacumriap, stat(sum) f(%20.0fc) save
tempname SAT
matrix `SAT' = r(StatTotal)

noisily di _newline(2) "{bf:" ///
	_col(04) in g "B. SAT, Declaraciones anuales: " in y "2015/`deflactor'" ///
	_col(55) in g %20s "Recaudaci${o}n" ///
	_col(75) in g %7s "% PIB" "}"
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(.) Utilidad gravable acumulable (act. prof.): " ///
	_col(55) in y %20.0fc (`SAT'[1,1]/`deflactor') ///
	_col(75) in y %7.3fc (`SAT'[1,1]/`deflactor')/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(.) Deducciones personales: " ///
	_col(55) in y %20.0fc `SAT'[1,2]/`deflactor' ///
	_col(75) in y %7.3fc (`SAT'[1,2]/`deflactor')/`PIBSCN'*100

noisily di _newline(2) "{bf:" ///
	_col(04) in g "C. SHCP, Informes trimestrales: " in y "`anio'-IV" ///
	_col(55) in g %20s "Recaudaci${o}n" ///
	_col(75) in g %7s "% PIB" "}"
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(+) ISR (personas f${i}sicas, servicios prof.): " ///
	_col(55) in y %20.0fc `ISRActProf' ///
	_col(75) in y %7.3fc `ISRActProf'/`PIBSCN'*100
noisily di ///
	_col(04) in g "(+) ISR (personas f${i}sicas, servicios salud): " ///
	_col(55) in y %20.0fc `ISRSalud' ///
	_col(75) in y %7.3fc `ISRSalud'/`PIBSCN'*100
noisily di _col(04) _dup(78) in g "-"
noisily di ///
	_col(04) in g "(=) ISR (servicios profesionales): " ///
	_col(55) in y %20.0fc (`ISRActProf'+`ISRSalud') ///
	_col(75) in y %7.3fc (`ISRActProf'+`ISRSalud')/`PIBSCN'*100



****************
/** 2.3. ENIGH **
noisily di _newline(2) "{bf:" ///
	_col(04) in g "D. Escenario base: " in y "ENIGH 2016" "}"

noisily run "`c(sysdir_personal)'/Income.do"



*********************************************/
/** 2.4. ESCENARIOS SERVICIOS PROFESIONALES **
noisily di _newline(2) "{bf:" ///
	_col(04) in g "E. Escenarios: " in y "Servicios Profesionales" "}"

local escens "escen1" //"escen0 escen1 escen2"

foreach escenario of local escens {
	postfile `escenario'serv deduccion cumplimiento pib servprof using "`c(sysdir_personal)'/`escenario'serv.dta", replace
}

forvalues cumplimiento=0(.1)1 {
	foreach deduccion of numlist 0 .1 .2 .3 .4 .5 {
		foreach escenario of local escens {
			forvalues repeticion=1(1)100 {


				* Income.do *
				use "`c(sysdir_personal)'/bases/SIM/2016/income.dta", clear


				* Fiscalizacion. Escenario 0. *
				if "`escenario'" == "escen0" {
					if `deduccion' == 0 {
						noisily di _newline(2) in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'" ///
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							in g " Repetici${o}n: " in y %3.0fc `repeticion' ///
							"}"


						* Step 1. Cut-off *
						*set seed 1111
						g fiscal_servprof = runiform() if ing_t4_cap2 != 0 & formal_servprof == 0


						* Step 2. Proporcion de fiscalizacion *
						noisily tabstat formal_servprof [fw=factor_hog] if prob_servprof != ., stat(sum) f(%20.0fc)
						replace formal_servprof = 1 if fiscal_servprof <= `cumplimiento' & fiscal_servprof != .
						noisily tabstat formal_servprof [fw=factor_hog] if prob_servprof != ., stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'
					}
					else {
						continue
					}
				}


				* Escenario 1 *
				if "`escenario'" == "escen1" {
					if (`deduccion' >= .1 | `deduccion' == 0) & `repeticion' == 1 {
						noisily di _newline(2) in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'" ///
							in g " Deduccion: " in y %3.0fc `deduccion'*100 " %" /// 
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							"}"


						* Consumo de servicios profesionales por personas formales *
						gsort -prob_servprof_cons
						egen hogar_servprof_accum = sum(factor_hog) if prob_servprof_cons != . & formal != 0
						g formal_servprof_accum = sum(formal*factor_hog) if prob_servprof_cons != . & formal != 0
						g prop_formal_servprof = formal_servprof_accum/hogar_servprof_accum


						* Step 1. Proporcion de cumplimiento (consumo) *
						capture tabstat gasto_profesi [aw=factor_cola] if formal != 0 & prop_formal_servprof <= `cumplimiento', stat(sum) f(%20.0fc) save
						if _rc == 0 {
							matrix PROFES = r(StatTotal)
						}
						else {
							matrix PROFES = J(1,1,0)
						}

						* Deduccion *
						replace deduc_isr = deduc_isr + `deduccion'*gasto_profesi if `deduccion'*gasto_profesi <= 2*`smdf'*365 & prop_formal_servprof <= `cumplimiento'
						replace deduc_isr = deduc_isr + 2*`smdf'*365 if `deduccion'*gasto_profesi > 2*`smdf'*365 & prop_formal_servprof <= `cumplimiento'


						* Step 2. Cut-off *
						noisily tabstat formal_servprof [fw=factor_hog], stat(sum) f(%20.0fc)
						replace formal_servprof = 1 if ing_servprof_accum_hog <= PROFES[1,1] & prob_servprof != .
						*replace formal_servprof = 0 if ing_servprof_accum_hog > PROFES[1,1] & prob_servprof != .
						noisily tabstat formal_servprof [fw=factor_hog], stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'
					}
					else {
						continue
					}
				}


				* Escenario 2 *
				global escenprof2 = 0
				if "`escenario'" == "escen2" {
					if (`deduccion' >= .1 | `deduccion' == 0) & `repeticion' == 1 {
						noisily di _newline(2) in g " {bf:  ESCENARIO " in y "`=substr("`escenario'",-1,1)'" ///
							in g " Porcentaje de consumo con tarjeta" in y %3.0fc `deduccion'*100 " %" /// 
							in g " Porcentaje de cumplimiento: " in y %3.0fc `cumplimiento'*100 " %" ///
							"}"


						* Consumo de servicios profesionales por personas formales *
						gsort -prob_servprof_cons
						egen hogar_servprof_accum = sum(factor_hog) if prob_servprof_cons != . & formal != 0
						g formal_servprof_accum = sum(formal*factor_hog) if prob_servprof_cons != . & formal != 0
						g prop_formal_servprof = formal_servprof_accum/hogar_servprof_accum


						* Step 1. Proporcion de cumplimiento (consumo) *
						capture tabstat gasto_profesi [aw=factor_cola] if formal != 0 & prop_formal_servprof <= `cumplimiento', stat(sum) f(%20.0fc) save
						if _rc == 0 {
							matrix PROFES = r(StatTotal)
						}
						else {
							matrix PROFES = J(1,1,0)
						}


						* Step 2. Cut-off *
						noisily tabstat formal_servprof [fw=factor_hog], stat(sum) f(%20.0fc)
						replace formal_servprof = 1 if ing_servprof_accum_hog <= PROFES[1,1] & prob_servprof != .
						*replace formal_servprof = 0 if ing_servprof_accum_hog > PROFES[1,1] & prob_servprof != .
						noisily tabstat formal_servprof [fw=factor_hog], stat(sum) f(%20.0fc)


						* Step 3. Recalcular ISR *
						tempfile BID_SHCP
						save `BID_SHCP', replace
						noisily ISR using `BID_SHCP'

						* Credito fiscal *
						if `deduccion' != 0 {
							replace ISR__PF2 = ISR__PF2 - `deduccion'*.01*gasto_profesi if prop_formal_servprof <= `cumplimiento'
						}
						else {
							replace ISR__PF2 = ISR__PF2 - .01*gasto_profesi_tarjeta if prop_formal_servprof <= `cumplimiento'
						}
					}
					else {
						continue
					}
				}



				*********************
				** 2.6. RESULTADOS **
				tabstat ISR__asalariados ISR__PF2 [aw=factor_cola], stat(sum) f(%25.2fc) save
				tempname RESTAX
				matrix `RESTAX' = r(StatTotal)

				capture tabstat ing_t4_cap2 exen_t4_cap2 [aw=factor_cola] if formal_servprof != 0, stat(sum) f(%20.0fc) save
				if _rc == 0 {
					matrix UTIL2 = r(StatTotal)
				}
				else {
					matrix UTIL2 = J(2,2,0)
				}

				tabstat ing_bruto_tax ISR__PF2 if ing_servprof_accum != 0 [aw=factor_cola], stat(sum) f(%20.0fc) save
				tempname TASA
				matrix `TASA' = r(StatTotal)

				noisily di _newline ///
					_col(04) in g "{bf:Cuentas Nacionales" ///
					_col(44) %7s in g "% PIB" ///
					_col(55) "Recaudaci${o}n" ///
					_col(88) %7s in g "% PIB" ///
					_col(99) in g "Tasa efectiva" "}"
				noisily di _col(04) _dup(108) in g "-"
				noisily di ///
					_col(04) in g "(+) Serv. prof., cient. y t${e}c. (54): " ///
					_col(44) %7.3fc in y (`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi')/`PIBSCN'*100 ///
					_col(55) in g "ISR (serv. prof.)" ///
					_col(88) %7.3fc in y ((`ISRActProf'+`ISRSalud') + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/`PIBSCN'*100 ///
					_col(99) %7.1fc in y ((`ISRActProf'+`ISRSalud') + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/(`ServProf')*100 " %"
				noisily di ///
					_col(04) in g "(+) Utilidad gravable: " ///
					_col(44) %7.3fc in y (UTIL2[1,1]-UTIL2[1,2])/`PIBSCN'*100 ///
					_col(55) in g "ISR (serv. prof.)" ///
					_col(88) %7.3fc in y ((`ISRActProf'+`ISRSalud') + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/`PIBSCN'*100 ///
					_col(99) %7.1fc in y ((`ISRActProf'+`ISRSalud') + (`RESTAX'[1,2] - $isrPF_ENIGH/100*`PIBSCN'))/(UTIL2[1,1]-UTIL2[1,2])*100 " %"

				noisily di _newline ///
					_col(04) in g "Crecimiento ISR (act. empresariales): " ///
					_col(44) in y %7.1fc ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/((`ISRActProf')/`PIBSCN'*100)*100 in g "%"
				noisily di ///
					_col(04) in g "Crecimiento ISR (act. empresariales): " ///
					_col(44) in y %7.3fc (`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH in g "% PIB"
				noisily di ///
					_col(04) in g "Crecimiento ISR 2018 (act. emp.): " ///
					_col(44) in y %7.0fc ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/100*$PIB2018/1000000 in g " millones de MXN"

				post `escenario'serv (`deduccion') (`cumplimiento') ((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH) (((`RESTAX'[1,2]/`PIBSCN'*100) - $isrPF_ENIGH)/100*$PIB2018/1000000)
			}
		}
	}
}

foreach escenario of local escens {
	postclose `escenario'serv
}



*******************/
/*** 2.7 GRAFICAS ***
use "`c(sysdir_personal)'/escen0serv.dta", clear
twoway (lpolyci servprof cumplimiento if round(deduccion,.1) == 0), ///
	title({bf:Servicios Profesionales (mayor fiscalizaci${o}n)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas informales que son auditados.") ///
	ylabel(, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	name(escen0serv, replace)
graph save escen0serv "`c(sysdir_personal)'/users/escen0serv.gph", replace
graph export "`c(sysdir_personal)'/users/escen0serv.png", name(escen0serv) replace

use "`c(sysdir_personal)'/escen1serv.dta", clear
twoway (connect servprof cumplimiento if round(deduccion,.01) == .1) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .2) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .3) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .4) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .5), ///
	title({bf:Servicios Profesionales: gastos deducibles (escenario 1)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas formales que piden facturas.") ///
	ylabel(, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	/*xline(.13, lcolor(green) lpattern(dash)) ///
	text(0 .13 "13%", placement(n))*/ ///
	legend(label(1 "Deducci${o}n 10%") label(2 "Deducci${o}n 20%") ///
	label(3 "Deducci${o}n 30%") label(4 "Deducci${o}n 40%") ///
	label(5 "Deducci${o}n 50%")) ///
	name(escen1serv, replace)
graph save escen1serv "`c(sysdir_personal)'/users/escen1serv.gph", replace
graph export "`c(sysdir_personal)'/users/escen1serv.png", name(escen1serv) replace

use "`c(sysdir_personal)'/escen2serv.dta", clear
twoway (connect servprof cumplimiento if round(deduccion,.01) == 0) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .1) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .2) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .3) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .4) ///
	(connect servprof cumplimiento if round(deduccion,.01) == .5), ///
	title({bf:Servicios Profesionales: cr${e}dito fiscal (escenario 2)}) ///
	subtitle("An${a}lisis de sensibilidad") ///
	caption("{it:Elaborado por el CIEP, utilizando informaci${o}n de la ENIGH 2016.}") ///
	ytitle(Cambio en recaudaci${o}n (millones de MXN)) ///
	xtitle("% de personas formales que piden facturas.") ///
	ylabel(, format(%7.0fc)) ///
	yline(0, lcolor(red) lpattern(dash)) ///
	/*xline(.12, lcolor(green) lpattern(dash)) ///
	text(0 .12 "12%", placement(n))*/ ///
	legend(label(1 "Consumo con tarjeta observado") ///
	label(2 "Consumo con tarjeta 10%") label(3 "Consumo con tarjeta 20%") ///
	label(4 "Consumo con tarjeta 30%") label(5 "Consumo con tarjeta 40%") ///
	label(6 "Consumo con tarjeta 50%")) ///
	name(escen2serv, replace)
graph save escen2serv "`c(sysdir_personal)'/users/escen2serv.gph", replace
graph export "`c(sysdir_personal)'/users/escen2serv.png", name(escen2serv) replace

timer off 1
timer list 1
noisily di _newline(2) in g "Segundos: " in y %10.2fc r(t1)/r(nt1)
