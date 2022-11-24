*****************************
***                       ***
***    4.1 ISR PF + PM    ***
***                       ***
*****************************
timer on 94
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4)
noisily di _newline(2) in g "   MODULO: " in y "ISR: " aniovp



*********************
** Microsimulacion **
*********************
*use if anio == 2018 | anio == `anio' using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
PIBDeflactor, nog nooutput
keep if anio == 2020 | anio == aniovp
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
local smdf = 172.87								// Salario minimo general: 86.88



****************
** Households **
use `"`c(sysdir_site)'/users/$pais/$id/households.dta"', clear

replace ing_subor = (ing_subor)/(`deflator'*`lambda')
replace ing_bruto_tax = (ing_bruto_tax)/(`deflator'*`lambda')
replace ing_bruto_tpm = (ing_bruto_tpm)/(`deflator'*`lambda')

tabstat ing_subor ing_bruto_tax ing_bruto_tpm cuotasTPF infonavit fovissste [fw=factor], stat(sum) save f(%20.0fc)
tempname BRUT
matrix `BRUT' = r(StatTotal)

noisily di _newline in g "    Ing. Bruto Salarios: " _col(33) in y %10.3fc (`BRUT'[1,1]/`deflator')/`pibY'*100
noisily di in g "    Cuotas a la Seg. Soc.:  " _col(33) in y %10.3fc (`BRUT'[1,4]+`BRUT'[1,5]+`BRUT'[1,6])/`pibY'*100
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
tabstat cuotasTP [fw=factor] if formal2 == 1, stat(sum) f(%25.0fc) save
tempname cuotasTP
matrix `cuotasTP' = r(StatTotal)

replace cuotasTP = cuotasTP*(scalar(CUOTAS)/100*`pibY')/`cuotasTP'[1,1] if formal2 == 1
replace cuotasTPF = cuotasF + cuotasTP



**************************
** CALCULO DE ISR FINAL **
**************************
capture g ISR0 = ISR
capture g ISR__asalariados0 = ISR__asalariados
capture g ISR__PF0 = ISR__PF
capture g ISRPM0 = ISRPM
capture g SE0 = SE

replace ISR = 0
label var ISR "ISR (f{c i'}sicas y asalariados)"

replace ISR__asalariados = 0
label var ISR__asalariados "ISR (retenciones por salarios SIM)"

replace ISR__PF = 0
label var ISR__PF "ISR (personas f{c i'}sicas SIM)"

replace ISRPM = 0
label var ISRPM "ISR (personas morales SIM)"

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
			if (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) <= SE[`k',2]
		replace categISR = "J`j'" if categF == "J`j'K`k'"
		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) if categF == "J`j'K`k'"
		replace SE = SE[`k',3] if categF == "J`j'K`k'"
	}
}


******************
** ISR SALARIOS **
replace formal_asalariados = prop_salarios <= (1-DED[1,4]/100)
replace ISR__asalariados = ISR if ing_t4_cap1 != 0
replace ISR__asalariados = 0 if formal_asalariados == 0 | ISR__asalariados == .
replace ISR__asalariados = ISR__asalariados*3.696/3.587

replace SE = 0 if formal_asalariados == 0
replace SE = SE*.1492/.1780


**************************
** ISR PERSONAS FISICAS **
replace formal_fisicas = prop_formal <= (1-DED[1,3]/100)
replace ISR__PF = (ISR - ISR__asalariados) if ISR - ISR__asalariados > 0 & formal_fisicas == 1
replace ISR__PF = 0 if formal_fisicas == 0 | ISR__PF == .
replace ISR__PF = ISR__PF*0.240/0.411


**************************
** ISR PERSONAS MORALES **
replace formal_morales = prop_moral <= (1-PM[1,2]/100)

tabstat SE [fw=factor], stat(sum) f(%20.0fc) save
tempname SE
matrix `SE' = r(StatTotal)
capture drop SE_empresas
Distribucion SE_empresas, relativo(ing_bruto_tpm) macro(`=`SE'[1,1]')

replace ISRPM = (ing_bruto_tpm-exen_tpm)*PM[1,1]/100 - SE_empresas if formal_morales == 1
replace ISRPM = 0 if ISRPM == .
replace ISRPM = ISRPM*4.064/3.956


***************
** ISR TOTAL **
replace ISR = ISR__asalariados + ISR__PF + ISRPM

* Results *
tabstat ISR__asalariados [fw=factor] if formal_asalariados == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)
*noisily Simulador ISR__asalariados [fw=factor], base("ENIGH 2020") boot(1) reboot nooutput

tabstat ISR__PF [fw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)

tabstat ISRPM [fw=factor] if formal_morales == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXM
matrix `SIMTAXM' = r(StatTotal)

scalar ISR_AS_Mod = `SIMTAXS'[1,1]/`pibY'*100 								// ISR (asalariados)
scalar ISR_PF_Mod = `SIMTAX'[1,1]/`pibY'*100 								// ISR (personas f{c i'}sicas)
scalar ISR_PM_Mod = `SIMTAXM'[1,1]/`pibY'*100 								// ISR (personas morales)

noisily di _newline in g "    RESULTADOS ISR (salarios): " _col(33) in y %10.3fc ISR_AS_Mod
noisily di in g "    RESULTADOS ISR (f{c i'}sicas):  " _col(33) in y %10.3fc ISR_PF_Mod
noisily di in g "    RESULTADOS ISR (morales):  " _col(33) in y %10.3fc ISR_PM_Mod

tabstat cuotasTP [fw=factor] if formal2 == 1, stat(sum) f(%25.2fc) save
tempname SIMCSS
matrix `SIMCSS' = r(StatTotal)
scalar CUOTAS = `SIMCSS'[1,1]/`pibY'*100 //								Cuotas IMSS



/* SIMULACION EQUIDAD DE GENERO *
egen Equidad = rsum(ISR__asalariados ISR__PF)
label var Equidad "del ISR Salarios + PF"
noisily Simulador Equidad [fw=factor], base("ENIGH 2018") boot(1) reboot nooutput


* Results *
g ing_gravable = ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0
noisily tabstat ing_subor ISR__asalariados [fw=factor] if formal_asalariados == 1, stat(mean) f(%25.2fc) by(categISR) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISR__PF [fw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)





************************/
**** Touchdown!!! :) ****
*************************
capture drop __*
save `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace
timer off 94
timer list 94
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t94)/r(nt94)',.1) in g " segs  " _dup(20) "."
