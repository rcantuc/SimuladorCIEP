** 4.1 ISR PF + PM **
timer on 94
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
global id = "Ricardo"




*******************
* Microsimulacion *
use if anio == `anio' | anio == 2018 using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
local lambda = lambda[1]
local deflator = deflator[1]
scalar PIB = pibY[_N]


* Verificar limites *
forvalues k=2(1)11 {
	matrix ISR[`k',1] = ISR[`=`k'-1',2]+.01
	if ISR[`k',1] >= ISR[`k',2] {
		matrix ISR[`k',2] = ISR[`k',1]+.01
	}
	matrix ISR[`k',3] = (ISR[`=`k'-1',2] - ISR[`=`k'-1',1])*ISR[`=`k'-1',4]/100 + ISR[`=`k'-1',3]
}
forvalues k=2(1)12 {
	matrix SE[`k',1] = SE[`=`k'-1',2]+.01
	if SE[`k',1] >= SE[`k',2] {
		matrix SE[`k',2] = SE[`k',1]+.01
	}
}
local smdf = 88.36																// Salario minimo general


* Households *
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
replace ing_bruto_tax = ing_bruto_tax/(`lambda'*`deflator')*79185533/77096593


* Cuotas a la Seguridad Social IMSS *
tabstat cuotasTP [fw=factor_cola] if formal2 == 1, stat(sum) f(%25.0fc) save
tempname cuotasTP
matrix `cuotasTP' = r(StatTotal)

replace cuotasTP = cuotasTP*(scalar(CuotasT)/100*scalar(PIB))/`cuotasTP'[1,1] if formal2 == 1
replace cuotasT = cuotasTP*cuotasT/(cuotasT + cuotasP) //cuotasT/(`lambda'*`deflator') // *79185533/77096593 if formal2 == 1


* Limitar deducciones *
replace deduc_isr = `=DED[1,1]'*`smdf'*365 if `=DED[1,1]'*`smdf'*365 <= `=DED[1,2]'/100*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT) & deduc_isr >= `=DED[1,1]'*`smdf'*365
replace deduc_isr = `=DED[1,2]'/100*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT) if `=DED[1,1]'*`smdf'*365 >= `=DED[1,2]'/100*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT) & deduc_isr >= `=DED[1,2]'/100*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT)


* Calcular ISR *
replace ISR = 0
replace categF = ""
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		replace categF = "J`j'K`k'" ///
			if (ing_bruto_tax - exen_tot - deduc_isr - cuotasT) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasT) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasT) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasT) <= SE[`k',2] ///
			 //& formal != 0

		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT - ISR[`j',1]) ///
			- SE[`k',3]*htrab/48 ///
			if categF == "J`j'K`k'" /*& formal != 0*/ & htrab < 48 & tipo_contribuyente == 1
		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT - ISR[`j',1]) ///
			- SE[`k',3] ///
			if categF == "J`j'K`k'" /*& formal != 0*/ & htrab >= 48 & tipo_contribuyente == 1
		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasT - ISR[`j',1]) ///
			if categF == "J`j'K`k'" /*& formal != 0*/ & (tipo_contribuyente == 2 | htrab == 0)
	}
}
replace ISR = 0 if formal == 0 //& formal_renta == 0 & formal_servprof == 0

replace ISR__asalariados = ISR*ing_subor/(ing_bruto_tax - exen_tot - deduc_isr - cuotasT) //if formal != 0
replace ISR__asalariados = 0 if ISR__asalariados == .
label var ISR__asalariados "ISR (retenciones por salarios)"

replace ISR__PF = ISR - ISR__asalariados //if ISR > ISR__asalariados
replace ISR__PF = 0 if ISR__PF == .
label var ISR__PF "ISR (personas f{c i'}sicas)"

replace ISR__PM = ing_capital*PM[1,1]/100/(`lambda'*`deflator')*79185533/77096593 if formal != 0
replace ISR__PM = 0 if ISR__PM == .
label var ISR__PM "ISR (personas morales)"

replace ISR = ISR__asalariados + ISR__PF + ISR__PM

* Results *
tabstat ISR__asalariados ISR__PF ISR__PM [fw=factor_cola] if formal != 0, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)

scalar ISR_AS = `SIMTAX'[1,1]/scalar(PIB)*100 //								ISR (asalariados)
scalar ISR_PF = `SIMTAX'[1,2]/scalar(PIB)*100 //								ISR (personas f{c i'}sicas)
scalar ISR_PM = `SIMTAX'[1,3]/scalar(PIB)*100 //								ISR (personas morales)


tabstat cuotasTP [fw=factor_cola] if formal2 == 1, stat(sum) f(%25.2fc) save
tempname SIMCSS
matrix `SIMCSS' = r(StatTotal)
scalar CuotasT = `SIMCSS'[1,1]/scalar(PIB)*100 //								Cuotas IMSS



* SIMULACI{c O'}N: Impuesto al ingreso laboral *
drop Laboral
egen Laboral = rsum(ISR__asalariados ISR__PF cuotasTP) if formal != 0
replace Laboral = 0 if Laboral == .
label var Laboral "los impuestos al ingreso laboral"
noisily Simulador Laboral [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
*noisily Simulador ISR__PM if ISR__PM != 0 [fw=factor], base("ENIGH 2018") boot(1) graphs reboot

save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace




************************/
**** Touchdown!!! :) ****
*************************
timer off 94
timer list 94
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t94)/r(nt94)',.1) in g " segs  " _dup(20) "."

