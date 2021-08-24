*****************************
***                       ***
***    4.1 ISR PF + PM    ***
***                       ***
*****************************
timer on 94
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4)
noisily di _newline(2) in g "   MODULO: " in y "ISR"



*********************
** Microsimulacion **
*********************
use if anio == 2018 | anio == `anio' using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
local lambda = lambda[1]
local deflator = deflator[1]
local pibY = pibY[_N]

* Verificar limites *
forvalues k=2(1)`=rowsof(ISR)' {
	matrix ISR[`k',1] = ISR[`=`k'-1',2]+.01
	if ISR[`k',1] >= ISR[`k',2] {
		matrix ISR[`k',2] = ISR[`k',1]+.01
	}
	matrix ISR[`k',3] = (ISR[`=`k'-1',2] - ISR[`=`k'-1',1])*ISR[`=`k'-1',4]/100 + ISR[`=`k'-1',3]
}
forvalues k=2(1)`=rowsof(SE)' {
	matrix SE[`k',1] = SE[`=`k'-1',2]+.01
	if SE[`k',1] >= SE[`k',2] {
		matrix SE[`k',2] = SE[`k',1]+.01
	}
}
local smdf = 86.88																// Salario minimo general


****************
** Households **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

tempvar ImpNet
egen `ImpNet' = rsum(ImpNetProduccion* ImpNetProductos_mixK ImpNetProductos_hog)

*replace ing_bruto_tax = (ing_bruto_tax)/(`deflator')
*replace ing_bruto_tpm = (ing_bruto_tpm)/(`deflator')

tabstat ing_subor ing_bruto_tax ing_bruto_tpm cuotasTPF `ImpNet' infonavit fovissste [fw=factor_cola], stat(sum) save f(%20.0fc)
tempname BRUT
matrix `BRUT' = r(StatTotal)

noisily di _newline in g "    Ing. Bruto Salarios: " _col(33) in y %10.3fc (`BRUT'[1,1]/*-`BRUT'[1,4]*/)/`pibY'*100
noisily di in g "    Cuotas a la Seg. Soc.:  " _col(33) in y %10.3fc (`BRUT'[1,4]+`BRUT'[1,6]+`BRUT'[1,7])/`pibY'*100
noisily di in g "    Ing. Bruto Tax PF:  " _col(33) in y %10.3fc (`BRUT'[1,2]-`BRUT'[1,1])/`pibY'*100
noisily di in g "    Ing. Bruto Tax (Sal + PF):  " _col(33) in y %10.3fc (`BRUT'[1,2])/`pibY'*100
noisily di in g "    Ing. Bruto Tax PM:  " _col(33) in y %10.3fc `BRUT'[1,3]/`pibY'*100


/************************
** Igualdad de genero **
noisily tabstat ing_bruto_tax ing_bruto_tpm [fw=factor], stat(mean) f(%10.0fc) by(sexo) save
tempname INGH INGM
matrix `INGH' = r(Stat1)
matrix `INGM' = r(Stat2)

replace ing_bruto_tax = ing_bruto_tax*`INGH'[1,1]/`INGM'[1,1] if sexo == 2
replace exen_tot = exen_tot*`INGH'[1,1]/`INGM'[1,1] if sexo == 2
replace ing_bruto_tpm = ing_bruto_tpm*`INGH'[1,2]/`INGM'[1,2] if sexo == 2
replace exen_tpm = exen_tpm*`INGH'[1,2]/`INGM'[1,2] if sexo == 2

noisily tabstat ing_bruto_tax ing_bruto_tpm [fw=factor], stat(mean) f(%10.0fc) by(sexo) save


**************************************/
** Cuotas a la Seguridad Social IMSS **
tabstat cuotasTP [fw=factor_cola] if formal2 == 1, stat(sum) f(%25.0fc) save
tempname cuotasTP
matrix `cuotasTP' = r(StatTotal)

replace cuotasTP = cuotasTP*(scalar(CuotasT)/100*`pibY')/`cuotasTP'[1,1] if formal2 == 1
replace cuotasTPF = cuotasF + cuotasTP



**************************
** CALCULO DE ISR FINAL **
**************************
capture g ISR0 = ISR
capture g ISR__asalariados0 = ISR__asalariados
capture g ISR__PF0 = ISR__PF
capture g ISR__PM0 = ISR__PM
capture g SE0 = SE

replace ISR = 0
label var ISR "ISR (f{c i'}sicas y asalariados)"

replace ISR__asalariados = 0
label var ISR__asalariados "ISR (retenciones por salarios SIM)"

replace ISR__PF = 0
label var ISR__PF "ISR (personas f{c i'}sicas SIM)"

replace ISR__PM = 0
label var ISR__PM "ISR (personas morales SIM)"

replace SE = 0
label var SE "Subsidio al empleo SIM"

* Limitar deducciones *
replace deduc_isr = `=DED[1,1]'*`smdf'*360 ///
	if `=DED[1,1]'*`smdf'*360 <= `=DED[1,2]'/100*ing_bruto_tax & deduc_isr >= `=DED[1,1]'*`smdf'*360
replace deduc_isr = `=DED[1,2]'/100*ing_bruto_tax ///
	if `=DED[1,1]'*`smdf'*360 >= `=DED[1,2]'/100*ing_bruto_tax & deduc_isr >= `=DED[1,2]'/100*ing_bruto_tax

replace categF = ""
capture g categISR = ""
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		replace categF = "J`j'K`k'" ///
			if (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0) <= SE[`k',2]
		replace categISR = "J`j'" if categF == "J`j'K`k'"
		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0 - ISR[`j',1]) if categF == "J`j'K`k'"
		replace SE = SE[`k',3] if categF == "J`j'K`k'"
	}
}


******************
** ISR SALARIOS **
replace formal_asalariados = prop_salarios <= (1-DED[1,4]/100)
replace ISR__asalariados = ISR if ing_t4_cap1 != 0
replace ISR__asalariados = 0 if formal_asalariados == 0 | ISR__asalariados == .
replace ISR__asalariados = ISR__asalariados*3.491/3.639

*replace ISR__asalariados = 0 if (formal_asalariados == 0 & ing_t4_cap1 != 0) | ISR__asalariados == . | ISR__asalariados < 0
*replace ISR__asalariados = ISR*ing_t4_cap1/(ing_t4_cap1+ing_t4_cap2+ing_t4_cap3+ing_t4_cap4+ing_t4_cap5+ing_t4_cap6+ing_t4_cap7+ing_t4_cap8+ing_t4_cap9) if formal_asalariados == 1 & ing_t4_cap1 != 0

replace SE = 0 if formal_asalariados == 0


**************************
** ISR PERSONAS FISICAS **
replace formal_fisicas = prop_formal <= (1-DED[1,3]/100)
replace ISR__PF = (ISR - ISR__asalariados) if ISR - ISR__asalariados > 0 & formal_fisicas == 1
replace ISR__PF = 0 if formal_fisicas == 0 | ISR__PF == .
replace ISR__PF = ISR__PF*0.227/0.325


**************************
** ISR PERSONAS MORALES **
replace formal_morales = prop_moral <= (1-PM[1,2]/100)

tabstat SE [fw=factor], stat(sum) f(%20.0fc) save
tempname SE
matrix `SE' = r(StatTotal)
capture drop SE_empresas
Distribucion SE_empresas, relativo(ing_bruto_tpm) macro(`=`SE'[1,1]')

replace ISR__PM = (ing_bruto_tpm-exen_tpm)*PM[1,1]/100 - SE_empresas if formal_morales == 1
replace ISR__PM = 0 if ISR__PM == .
replace ISR__PM = ISR__PM*3.839/3.278


***************
** ISR TOTAL **
replace ISR = ISR__asalariados + ISR__PF + ISR__PM

* Results *
tabstat ISR__asalariados [fw=factor_cola] if formal_asalariados == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISR__PF [fw=factor_cola] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)

tabstat ISR__PM [fw=factor_cola] if formal_morales == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXM
matrix `SIMTAXM' = r(StatTotal)

scalar ISR_AS_Mod = `SIMTAXS'[1,1]/`pibY'*100 								// ISR (asalariados)
scalar ISR_PF_Mod = `SIMTAX'[1,1]/`pibY'*100 								// ISR (personas f{c i'}sicas)
scalar ISR_PM_Mod = `SIMTAXM'[1,1]/`pibY'*100 								// ISR (personas morales)

noisily di _newline in g "    RESULTADOS ISR (salarios): " _col(33) in y %10.3fc ISR_AS_Mod
noisily di in g "    RESULTADOS ISR (f{c i'}sicas):  " _col(33) in y %10.3fc ISR_PF_Mod
noisily di in g "    RESULTADOS ISR (morales):  " _col(33) in y %10.3fc ISR_PM_Mod

tabstat cuotasTP [fw=factor_cola] if formal2 == 1, stat(sum) f(%25.2fc) save
tempname SIMCSS
matrix `SIMCSS' = r(StatTotal)
scalar CuotasT = `SIMCSS'[1,1]/`pibY'*100 //								Cuotas IMSS


/* SIMULACION EQUIDAD DE GENERO *
egen Equidad = rsum(ISR__asalariados ISR__PF)
label var Equidad "del ISR Salarios + PF"
noisily Simulador Equidad [fw=factor_cola], base("ENIGH 2018") boot(1) reboot nooutput


* Results *
g ing_gravable = ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0
noisily tabstat ing_subor ISR__asalariados [fw=factor_cola] if formal_asalariados == 1, stat(mean) f(%25.2fc) by(categISR) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISR__PF [fw=factor_cola] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)





************************/
**** Touchdown!!! :) ****
*************************
capture drop __*
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace
timer off 94
timer list 94
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t94)/r(nt94)',.1) in g " segs  " _dup(20) "."
