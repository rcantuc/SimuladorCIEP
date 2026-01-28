*****************************
***                       ***
***    4.1 ISR PF + PM    ***
***                       ***
*****************************
timer on 94
noisily di _newline(2) in g "  MODULO: " in y "ISR " aniovp



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
*local smdf = 172.87 			// SM 2022


*********************
** INFORMACIÓN PIB **
*********************
SCN, nographs
local pibY = real(subinstr(scalar(PIB),",","",.))*1000000



****************************
** INFORMACIÓN HOUSEHOLDS **
****************************
capture use "`c(sysdir_site)'/04_master/perfiles`=anioPE'.dta", clear
if _rc != 0 {
	noisily run "`c(sysdir_site)'/PerfilesSim.do" `=anioPE'
}
drop CUOTAS ISRAS ISRPF

noisily tabstat ing_bruto_tax [fw=factor], stat(sum) f(%20.0fc) save
noisily di _newline in g "INGRESOS BRUTOS: " in y %20.3fc r(StatTotal)[1,1]/`pibY'*100




**********************************/
** 6.1 cuotasTPF A LA SSEmpleadores **
* Salario Base de Cotizacion: IMSS *

* IMSS *
g gmasgP = sbc*CSS_IMSS[1,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmasgT = sbc*CSS_IMSS[1,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmasgF = sbc*CSS_IMSS[1,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g gmpenP = sbc*CSS_IMSS[2,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmpenT = sbc*CSS_IMSS[2,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmpenF = sbc*CSS_IMSS[2,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g invyvidaP = sbc*CSS_IMSS[3,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g invyvidaT = sbc*CSS_IMSS[3,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g invyvidaF = sbc*CSS_IMSS[3,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g riesgoP = sbc*CSS_IMSS[4,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g riesgoT = sbc*CSS_IMSS[4,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g riesgoF = sbc*CSS_IMSS[4,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g guardP = sbc*CSS_IMSS[5,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g guardT = sbc*CSS_IMSS[5,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g guardF = sbc*CSS_IMSS[5,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g cestyvejP = sbc*CSS_IMSS[6,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g cestyvejT = sbc*CSS_IMSS[6,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g cestyvejF = sbc*CSS_IMSS[6,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g cuotasocimssP = CSS_IMSS[7,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' <= 15
replace cuotasocimssP = 15*CSS_IMSS[7,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' > 15
g cuotasocimssT = CSS_IMSS[7,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' <= 15
replace cuotasocimssT = 15*CSS_IMSS[7,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' > 15
g cuotasocimssF = sbc/`smdf'*CSS_IMSS[7,3]*52 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' <= 15
replace cuotasocimssF = 15*CSS_IMSS[7,3]*52 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' > 15

* ISSSTE *
g fondomedP = sbc*CSS_ISSSTE[1,1]/100*360 if (formal2 == 2 | formal2 == 5)
g fondomedT = sbc*CSS_ISSSTE[1,2]/100*360 if (formal2 == 2 | formal2 == 5)
g fondomedF = CSS_ISSSTE[1,3]*52 if (formal2 == 2 | formal2 == 5)

g pensjubP = sbc*CSS_ISSSTE[2,1]/100*360 if (formal2 == 2 | formal2 == 5)
g pensjubT = sbc*CSS_ISSSTE[2,2]/100*360 if (formal2 == 2 | formal2 == 5)
g pensjubF = sbc*CSS_ISSSTE[2,3]/100*360 if (formal2 == 2 | formal2 == 5)

g segriesgP = sbc*CSS_ISSSTE[3,1]/100 if (formal2 == 2 | formal2 == 5)
g segriesgT = sbc*CSS_ISSSTE[3,2]/100 if (formal2 == 2 | formal2 == 5)
g segriesgF = sbc*CSS_ISSSTE[3,3]/100 if (formal2 == 2 | formal2 == 5)

g presperP = sbc*CSS_ISSSTE[4,1]/100*360 if (formal2 == 2 | formal2 == 5)
g presperT = sbc*CSS_ISSSTE[4,2]/100*360 if (formal2 == 2 | formal2 == 5)
g presperF = sbc*CSS_ISSSTE[4,3]/100*360 if (formal2 == 2 | formal2 == 5)

g servsocculP = sbc*CSS_ISSSTE[5,1]/100*360 if (formal2 == 2 | formal2 == 5)
g servsocculT = sbc*CSS_ISSSTE[5,2]/100*360 if (formal2 == 2 | formal2 == 5)
g servsocculF = sbc*CSS_ISSSTE[5,3]/100*360 if (formal2 == 2 | formal2 == 5)

g admingenP = sbc*CSS_ISSSTE[6,1]/100*360 if (formal2 == 2 | formal2 == 5)
g admingenT = sbc*CSS_ISSSTE[6,2]/100*360 if (formal2 == 2 | formal2 == 5)
g admingenF = sbc*CSS_ISSSTE[6,3]/100*360 if (formal2 == 2 | formal2 == 5)

g fvivP = sbc*CSS_ISSSTE[7,1]/100*360 if (formal2 == 2 | formal2 == 5)
g fvivT = sbc*CSS_ISSSTE[7,2]/100*360 if (formal2 == 2 | formal2 == 5)
g fvivF = sbc*CSS_ISSSTE[7,3]/100*360 if (formal2 == 2 | formal2 == 5)

g cuotasocisssteP = CSS_ISSSTE[8,1]/100*360 if (formal2 == 2 | formal2 == 5)
g cuotasocisssteT = CSS_ISSSTE[8,2]/100*360 if (formal2 == 2 | formal2 == 5)
g cuotasocisssteF = CSS_ISSSTE[8,3]*52 if (formal2 == 2 | formal2 == 5)

* Agregación *
egen double CUOTAS = rsum(gmasgT gmpenT invyvidaT riesgoT guardT cestyvejT cuotasocimssT ///
	gmasgP gmpenP invyvidaP riesgoP guardP cestyvejP cuotasocimssP ///
	fondomedT pensjubT segriesgT presperT servsocculT admingenT fvivT ///
	fondomedP pensjubP segriesgP presperP servsocculP admingenP fvivP)

egen double cuotasF = rsum(gmasgF gmpenF invyvidaF riesgoF guardF cestyvejF cuotasocimssF cuotasocisssteF)
replace cuotasTPF = cuotasF + CUOTAS


*************************/
** CALCULO DE ISR FINAL **
**************************
g ISR = 0
label var ISR "ISR (f{c i'}sicas y asalariados)"

g SE = 0
label var SE "Subsidio al empleo (SIM)"

* Limitar deducciones *
replace deduc_isr = `=DED[1,1]'*`smdf' if `=DED[1,1]'*`smdf' <= `=DED[1,2]'/100*ing_bruto_tax & deduc_isr >= `=DED[1,1]'*`smdf'
replace deduc_isr = `=DED[1,2]'/100*ing_bruto_tax if `=DED[1,1]'*`smdf' >= `=DED[1,2]'/100*ing_bruto_tax & deduc_isr >= `=DED[1,2]'/100*ing_bruto_tax

g categF = ""
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		if ISR[`j',1] > SE[`k',2] {
				continue
		}
		replace categF = "J`j'K`k'" ///
			if (ing_bruto_tax - exen_tot - deduc_isr - CUOTAS) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - CUOTAS) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - CUOTAS) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - CUOTAS) <= SE[`k',2]

		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - CUOTAS - ISR[`j',1]) if categF == "J`j'K`k'"
		replace SE = SE[`k',3] if categF == "J`j'K`k'"
	}
}

/*g ing_EITC = (ing_bruto_tax - CUOTAS)/12
gen EITC = 0
replace EITC = 2500.00 - (ing_EITC/4) if ing_EITC <= 644.58
replace EITC = 2338.86 - ((ing_EITC-644.59)/6) if ing_EITC > 644.58 & ing_EITC <= 5470.92
replace EITC = 1534.47 if ing_EITC>5470.92 & ing_EITC <= 9614.66
replace EITC = 1534.47 if ing_EITC>9614.66 & ing_EITC <= 11176.62
replace EITC = 1534.47 if ing_EITC>11176.62 & ing_EITC <= 13381.47
replace EITC = 1534.47 - ((ing_EITC-13381.48)/8.9) if ing_EITC > 13381.47 & ing_EITC <= 26988.50
replace ISR = ISR - EITC*12 if categF != ""*/


************************
** Subsidio al empleo **
replace SE = SE*.1492/.098


******************
** ISR SALARIOS **
replace formal_asalariados = prop_salarios <= (1-DED[1,4]/100) & prop_salarios != .
g ISRAS_Sim = ISR*(ing_subor+cuotasTPF)/(ing_bruto_tax)
replace ISRAS_Sim = 0 if formal_asalariados == 0
replace ISRAS_Sim = ISRAS_Sim*3.793/3.255


**************************
** ISR PERSONAS FISICAS **
replace formal_fisicas = prop_formal <= (1-DED[1,3]/100) & prop_formal != .

g ISRPF_Sim = ISR*(1-(ing_subor+cuotasTPF)/(ing_bruto_tax))
replace ISRPF_Sim = 0 if formal_fisicas == 0
replace ISRPF_Sim = ISRPF_Sim*0.241/0.553


**************************
** ISR PERSONAS MORALES **
replace formal_morales = prop_moral <= (1-PM[1,2]/100) & prop_moral != .

tabstat SE [fw=factor] if formal_asalariados == 1, stat(sum) f(%20.0fc) save
tempname SE
matrix `SE' = r(StatTotal)
capture drop SE_empresas
Distribucion SE_empresas, relativo(ing_bruto_tpm) macro(`=`SE'[1,1]')

g ISRPM_Sim = (ing_bruto_tpm-exen_tpm)*PM[1,1]/100 - SE_empresas if formal_morales == 1
replace ISRPM_Sim = 0 if ISRPM_Sim == .
replace ISRPM_Sim = ISRPM_Sim*4.176/2.781


*****************
** CUOTAS IMSS **
g CUOTAS_Sim = CUOTAS*1.675/1.525 if formal2 == 1


***************
** ISR TOTAL **

* Results *
tabstat ISRAS_Sim [fw=factor] if formal_asalariados == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISRPF_Sim [fw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)

tabstat ISRPM_Sim [fw=factor] if formal_morales == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXM
matrix `SIMTAXM' = r(StatTotal)

tabstat CUOTAS_Sim [fw=factor] if formal2 == 1, stat(sum) f(%25.2fc) save
tempname SIMCSS
matrix `SIMCSS' = r(StatTotal)

scalar ISR_AS_Mod = `SIMTAXS'[1,1]/`pibY'*100 								// ISR (asalariados)
scalar ISR_PF_Mod = `SIMTAX'[1,1]/`pibY'*100 								// ISR (personas f{c i'}sicas)
scalar ISR_PM_Mod = `SIMTAXM'[1,1]/`pibY'*100 								// ISR (personas morales)
scalar CUOTAS_Mod = `SIMCSS'[1,1]/`pibY'*100 								// Cuotas IMSS
scalar SE_Mod = `SE'[1,1]/`pibY'*100 									// Subsidio al empleo

noisily di _newline in g "  RESULTADOS ISR (salarios): " _col(33) in y %10.3fc ISR_AS_Mod
noisily di in g "  RESULTADOS ISR (f{c i'}sicas):  " _col(33) in y %10.3fc ISR_PF_Mod
noisily di in g "  RESULTADOS ISR (morales):  " _col(33) in y %10.3fc ISR_PM_Mod
noisily di in g "  RESULTADOS SE:  " _col(33) in y %10.3fc SE_Mod
noisily di in g "  RESULTADOS Cuotas IMSS:  " _col(33) in y %10.3fc CUOTAS_Mod


************************/
**** Touchdown!!! :) ****
*************************
capture drop __*
save "`c(sysdir_site)'/users/$id/isr_mod.dta", replace
timer off 94
timer list 94
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t94)/r(nt94)',.1) in g " segs  " _dup(20) "."
