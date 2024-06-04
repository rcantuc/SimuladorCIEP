*****************************
***                       ***
***    4.1 ISR PF + PM    ***
***                       ***
*****************************
timer on 94
noisily di _newline(2) in g "   MODULO: " in y "ISR: " aniovp



*********************
** PIB y deflactor **
*********************
PIBDeflactor, nog nooutput anio(`=aniovp')
keep if anio == scalar(anioenigh) | anio == scalar(aniovp)
local lambda = lambda[1]
local deflator = deflator[1]
local pibY = pibY[_N]



***************************
** Verificar limites ISR **
***************************
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
local smdf = 248.93 			// SM 2024



****************
** Households **
****************
use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta", ///
	nogen keepus(ing_subor ing_mixto ing_capital ing_bruto_tax ing_bruto_tpm formal* ///
	ing_ss ISR* SE deduc_isr categ* exen_* prop_* ing_t4_cap1) 

replace ing_bruto_tax = (ing_bruto_tax)/(`deflator'*`lambda')
replace ing_bruto_tpm = (ing_bruto_tpm)/(`deflator'*`lambda')

tabstat ing_subor ing_bruto_tax ing_bruto_tpm ///
	cuotasTPF infonavit fovissste [fw=factor], stat(sum) save f(%20.0fc)
tempname BRUT
matrix `BRUT' = r(StatTotal)

noisily di _newline in g "   Remuneración de asalariados: " _col(33) in y %10.3fc (`BRUT'[1,1]/`deflator')/`pibY'*100
noisily di in g "   Ing. Bruto Tax PF:  " _col(33) in y %10.3fc (`BRUT'[1,2]-`BRUT'[1,1])/`pibY'*100
noisily di in g "   Ing. Bruto Tax (Sal + PF):  " _col(33) in y %10.3fc (`BRUT'[1,2])/`pibY'*100
noisily di in g "   Ing. Bruto Tax PM:  " _col(33) in y %10.3fc `BRUT'[1,3]/`pibY'*100
noisily di in g "   Cuotas a la Seg. Soc.:  " _col(33) in y %10.3fc (`BRUT'[1,4]+`BRUT'[1,5]+`BRUT'[1,6])/`pibY'*100


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


**********************************/
** 6.1 CUOTAS A LA SSEmpleadores **
* Salario Base de Cotizacion: IMSS *
g double sbc = ing_ss/360/`smdf' if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & ing_ss > 0 & ing_ss != .
replace sbc = 25 if sbc > 25 & (formal == 1 | formal == 3 | formal == 4 | formal == 6) & ing_ss > 0 & ing_ss != .
*replace sbc = floor(sbc) if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

* Sueldo Basico: ISSSTE *
replace sbc = ing_ss/360/`smdf' if (formal == 2 | formal == 5) & ing_ss > 0 & ing_ss != .
replace sbc = 10 if sbc > 10 & (formal == 2 | formal == 5) & ing_ss > 0 & ing_ss != .
*replace sbc = ceil(sbc) if (formal == 2 | formal == 5)

* Ajustes *
replace sbc = 1 if sbc > 0 & sbc < 1 & (formal == 1 | formal == 6)
replace sbc = sbc*`smdf'
replace sbc = 0 if formal == 0

* IMSS *
g gmasgP = sbc*CSS_IMSS[1,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmasgT = sbc*CSS_IMSS[1,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmasgF = floor(sbc)*CSS_IMSS[1,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double gmpenP = sbc*CSS_IMSS[2,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmpenT = sbc*CSS_IMSS[2,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmpenF = floor(sbc)*CSS_IMSS[2,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double invyvidaP = sbc*CSS_IMSS[3,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double invyvidaT = sbc*CSS_IMSS[3,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double invyvidaF = floor(sbc)*CSS_IMSS[3,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double riesgoP = sbc*CSS_IMSS[4,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double riesgoT = sbc*CSS_IMSS[4,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double riesgoF = floor(sbc)*CSS_IMSS[4,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double guardP = sbc*CSS_IMSS[5,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double guardT = sbc*CSS_IMSS[5,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double guardF = floor(sbc)*CSS_IMSS[5,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double cestyvejP = sbc*CSS_IMSS[6,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double cestyvejT = sbc*CSS_IMSS[6,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double cestyvejF = floor(sbc)*CSS_IMSS[6,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double cuotasocimssP = sbc*CSS_IMSS[7,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' <= 15
replace cuotasocimssP = sbc*CSS_IMSS[7,1]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' > 15
g double cuotasocimssT = sbc*CSS_IMSS[7,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' <= 15
replace cuotasocimssT = sbc*CSS_IMSS[7,2]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' > 15
g double cuotasocimssF = floor(sbc)*CSS_IMSS[7,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' <= 15
replace cuotasocimssF = floor(sbc)*CSS_IMSS[7,3]/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' > 15

* ISSSTE *
g double fondomedP = sbc*CSS_ISSSTE[1,1]/100*360 if (formal == 2 | formal == 5)
g double fondomedT = sbc*CSS_ISSSTE[1,2]/100*360 if (formal == 2 | formal == 5)
g double fondomedF = floor(sbc)*CSS_ISSSTE[1,3]/100*360 if (formal == 2 | formal == 5)

g double pensjubP = sbc*CSS_ISSSTE[2,1]/100*360 if (formal == 2 | formal == 5)
g double pensjubT = sbc*CSS_ISSSTE[2,2]/100*360 if (formal == 2 | formal == 5)
g double pensjubF = floor(sbc)*CSS_ISSSTE[2,3]/100*360 if (formal == 2 | formal == 5)

g double segriesgP = sbc*CSS_ISSSTE[3,1]/100 if (formal == 2 | formal == 5)
g double segriesgT = sbc*CSS_ISSSTE[3,2]/100 if (formal == 2 | formal == 5)
g double segriesgF = floor(sbc)*CSS_ISSSTE[3,3]/100 if (formal == 2 | formal == 5)

g double presperP = sbc*CSS_ISSSTE[4,1]/100*360 if (formal == 2 | formal == 5)
g double presperT = sbc*CSS_ISSSTE[4,2]/100*360 if (formal == 2 | formal == 5)
g double presperF = floor(sbc)*CSS_ISSSTE[4,3]/100*360 if (formal == 2 | formal == 5)

g double servsocculP = sbc*CSS_ISSSTE[5,1]/100*360 if (formal == 2 | formal == 5)
g double servsocculT = sbc*CSS_ISSSTE[5,2]/100*360 if (formal == 2 | formal == 5)
g double servsocculF = floor(sbc)*CSS_ISSSTE[5,3]/100*360 if (formal == 2 | formal == 5)

g double admingenP = sbc*CSS_ISSSTE[6,1]/100*360 if (formal == 2 | formal == 5)
g double admingenT = sbc*CSS_ISSSTE[6,2]/100*360 if (formal == 2 | formal == 5)
g double admingenF = floor(sbc)*CSS_ISSSTE[6,3]/100*360 if (formal == 2 | formal == 5)

g double fvivP = sbc*CSS_ISSSTE[7,1]/100*360 if (formal == 2 | formal == 5)
g double fvivT = sbc*CSS_ISSSTE[7,2]/100*360 if (formal == 2 | formal == 5)
g double fvivF = floor(sbc)*CSS_ISSSTE[7,3]/100*360 if (formal == 2 | formal == 5)

g double cuotasocisssteP = 2.1879*26.45*CSS_ISSSTE[8,1]/100*360 if (formal == 2 | formal == 5)
g double cuotasocisssteT = 2.1879*26.45*CSS_ISSSTE[8,2]/100*360 if (formal == 2 | formal == 5)
g double cuotasocisssteF = 2.1879*26.45*CSS_ISSSTE[8,3]/100*360 if (formal == 2 | formal == 5)

* Agregación *
*capture rename cuotasTP cuotasTP0
egen double cuotasTP = rsum(gmasgT gmpenT invyvidaT riesgoT guardT cestyvejT cuotasocimssT ///
	gmasgP gmpenP invyvidaP riesgoP guardP cestyvejP cuotasocimssP ///
	fondomedT pensjubT segriesgT presperT servsocculT admingenT fvivT ///
	fondomedP pensjubP segriesgP presperP servsocculP admingenP fvivP)

capture rename cuotasF cuotasF0
capture drop cuotasF
egen double cuotasF = rsum(gmasgF gmpenF invyvidaF riesgoF guardF cestyvejF cuotasocimssF cuotasocisssteF)

*tabstat cuotasTP [fw=factor] if formal2 == 1, stat(sum) f(%25.0fc) save
*tempname cuotasTP
*matrix `cuotasTP' = r(StatTotal)

*replace cuotasTP = cuotasTP*(scalar(CUOTAS)/100*`pibY')/`cuotasTP'[1,1] if formal2 == 1
replace cuotasTPF = cuotasF + cuotasTP



*************************/
** CALCULO DE ISR FINAL **
**************************
capture g ISR0 = ISR
capture g ISR_asalariados0 = ISR_asalariados
capture g ISR_PF0 = ISR_PF
capture g ISRPM0 = ISRPM
capture g SE0 = SE

replace ISR = 0
label var ISR "ISR (f{c i'}sicas y asalariados)"

replace ISR_asalariados = 0
label var ISR_asalariados "ISR (retenciones por salarios SIM)"

replace ISR_PF = 0
label var ISR_PF "ISR (personas f{c i'}sicas SIM)"

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
		if ISR[`j',2] > SE[`k',2] {
				continue
		}
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
replace SE = SE*.1492/.137
replace formal_asalariados = prop_salarios <= (1-DED[1,4]/100)
replace ISR_asalariados = ISR*ing_subor/(ing_mixto+ing_subor+ing_capital) - SE
replace ISR_asalariados = 0 if formal_asalariados == 0 | ISR_asalariados == .
replace ISR_asalariados = ISR_asalariados // *3.691/2.384



**************************
** ISR PERSONAS FISICAS **
replace formal_fisicas = prop_formal <= (1-DED[1,3]/100)
replace ISR_PF = ISR - ISR_asalariados if ISR - ISR_asalariados >= 0
replace ISR_PF = 0 if formal_fisicas == 0 | ISR_PF == . | ISR_PF < 0
replace ISR_PF = ISR_PF // *0.234/0.266


**************************
** ISR PERSONAS MORALES **
replace formal_morales = prop_moral <= (1-PM[1,2]/100)

tabstat SE [fw=factor], stat(sum) f(%20.0fc) save
tempname SE
matrix `SE' = r(StatTotal)
capture drop SE_empresas
Distribucion SE_empresas, relativo(ing_bruto_tpm) macro(`=`SE'[1,1]')

replace ISRPM = (ing_bruto_tpm-exen_tpm*0)*PM[1,1]/100 - SE_empresas*0 if formal_morales == 1
replace ISRPM = 0 if ISRPM == .
replace ISRPM = ISRPM // *4.063/3.803


*****************
** CUOTAS IMSS **
replace cuotasTP = cuotasTP // *1.578/1.414 if formal2 == 1



***************
** ISR TOTAL **
replace ISR = ISR_asalariados + ISR_PF + ISRPM

* Results *
tabstat ISR_asalariados [fw=factor] if formal_asalariados == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISR_PF [fw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)

tabstat ISRPM [fw=factor] if formal_morales == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXM
matrix `SIMTAXM' = r(StatTotal)

tabstat cuotasTP [fw=factor] if formal2 == 1, stat(sum) f(%25.2fc) save
tempname SIMCSS
matrix `SIMCSS' = r(StatTotal)

scalar ISR_AS_Mod = `SIMTAXS'[1,1]/`pibY'*100 								// ISR (asalariados)
scalar ISR_PF_Mod = `SIMTAX'[1,1]/`pibY'*100 								// ISR (personas f{c i'}sicas)
scalar ISR_PM_Mod = `SIMTAXM'[1,1]/`pibY'*100 								// ISR (personas morales)
scalar CUOTAS_Mod = `SIMCSS'[1,1]/`pibY'*100 								// Cuotas IMSS
scalar SE_Mod = `SE'[1,1]/`pibY'*100 									// Subsidio al empleo

noisily di _newline in g "    RESULTADOS ISR (salarios): " _col(33) in y %10.3fc ISR_AS_Mod
noisily di in g "    RESULTADOS ISR (f{c i'}sicas):  " _col(33) in y %10.3fc ISR_PF_Mod
noisily di in g "    RESULTADOS ISR (morales):  " _col(33) in y %10.3fc ISR_PM_Mod
noisily di in g "    RESULTADOS IMSS (obr-pat):  " _col(33) in y %10.3fc CUOTAS_Mod
noisily di in g "    RESULTADOS SE:  " _col(33) in y %10.3fc SE_Mod

xxx

/* SIMULACION EQUIDAD DE GENERO *
egen Equidad = rsum(ISR_asalariados ISR_PF)
label var Equidad "del ISR Salarios + PF"
noisily Simulador Equidad [fw=factor], base("ENIGH 2018") boot(1) reboot nooutput


* Results *
g ing_gravable = ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF*0
noisily tabstat ing_subor ISR_asalariados [fw=factor] if formal_asalariados == 1, stat(mean) f(%25.2fc) by(categISR) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISR_PF [fw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)





************************/
**** Touchdown!!! :) ****
*************************
capture drop __*
save "`c(sysdir_personal)'/users/$id/isr_mod.dta", replace
timer off 94
timer list 94
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t94)/r(nt94)',.1) in g " segs  " _dup(20) "."
