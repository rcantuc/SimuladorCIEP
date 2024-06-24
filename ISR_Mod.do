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
local smdf = 172.87 			// SM 2022


****************
** Households **
****************
use "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta", clear

replace ing_bruto_tax = (ing_bruto_tax)/(`deflator'*`lambda')
replace ing_bruto_tpm = (ing_bruto_tpm)/(`deflator'*`lambda')
replace ing_subor = (ing_subor)/(`deflator'*`lambda')

tabstat ing_subor ing_bruto_tax ing_bruto_tpm cuotasTPF infonavit fovissste isrE ISR ISR_PF ISR_PM cuotasTP [fw=factor], stat(sum) save f(%20.0fc)
tempname BRUT
matrix `BRUT' = r(StatTotal)

noisily di _newline in g " Información ENIGH: " in y `=anioenigh' in g " y perfiles " in y `=anioPE'
noisily di _newline in g "  Remuneración de asalariados: " _col(33) in y %10.3fc (`BRUT'[1,1]/`deflator')/`pibY'*100
noisily di in g "  Ing. Bruto Tax PF:  " _col(33) in y %10.3fc (`BRUT'[1,2]-`BRUT'[1,1])/`pibY'*100

tabstat ISR_asalariados [fw=factor] if formal_asalariados == 1, stat(sum) save f(%20.0fc)
tempname isrE
matrix `isrE' = r(StatTotal)
noisily di _newline in g "  ISR asalaridos:  " _col(33) in y %10.3fc `isrE'[1,1]/`pibY'*100

tabstat ISR_PF [fw=factor] if formal_fisicas == 1, stat(sum) save f(%20.0fc)
tempname ISR_PF
matrix `ISR_PF' = r(StatTotal)
noisily di in g "  ISR PF: " _col(33) in y %10.3fc `ISR_PF'[1,1]/`pibY'*100

tabstat ISR_PM [fw=factor] if formal_morales == 1, stat(sum) save f(%20.0fc)
tempname ISR_PM
matrix `ISR_PM' = r(StatTotal)
noisily di in g "  ISR PM: " _col(33) in y %10.3fc `ISR_PM'[1,1]/`pibY'*100

noisily di in g "  ISR total: " _col(33) in y %10.3fc (`isrE'[1,1]+`ISR_PF'[1,1]+`ISR_PM'[1,1])/`pibY'*100

tabstat cuotasTP [fw=factor] if formal2 == 1, stat(sum) save f(%20.0fc)
tempname cuotasTP
matrix `cuotasTP' = r(StatTotal)
noisily di in g "  Cuotas IMSS: " _col(33) in y %10.3fc `cuotasTP'[1,1]/`pibY'*100


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
drop cuotasTP
egen double cuotasTP = rsum(gmasgT gmpenT invyvidaT riesgoT guardT cestyvejT cuotasocimssT ///
	gmasgP gmpenP invyvidaP riesgoP guardP cestyvejP cuotasocimssP ///
	fondomedT pensjubT segriesgT presperT servsocculT admingenT fvivT ///
	fondomedP pensjubP segriesgP presperP servsocculP admingenP fvivP)

egen double cuotasF = rsum(gmasgF gmpenF invyvidaF riesgoF guardF cestyvejF cuotasocimssF cuotasocisssteF)
replace cuotasTPF = cuotasF + cuotasTP


*************************/
** CALCULO DE ISR FINAL **
**************************
replace ISR = 0
label var ISR "ISR (f{c i'}sicas y asalariados)"

replace ISR_asalariados = 0
label var ISR_asalariados "ISR (retenciones por salarios SIM)"

replace ISR_PF = 0
label var ISR_PF "ISR (personas f{c i'}sicas SIM)"

replace ISR_PM = 0
label var ISR_PM "ISR (personas morales SIM)"

replace SE = 0
label var SE "Subsidio al empleo (SIM)"

* Limitar deducciones *
replace deduc_isr = `=DED[1,1]'*`smdf' if `=DED[1,1]'*`smdf' <= `=DED[1,2]'/100*ing_bruto_tax & deduc_isr >= `=DED[1,1]'*`smdf'
replace deduc_isr = `=DED[1,2]'/100*ing_bruto_tax if `=DED[1,1]'*`smdf' >= `=DED[1,2]'/100*ing_bruto_tax & deduc_isr >= `=DED[1,2]'/100*ing_bruto_tax

replace categF = ""
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		if ISR[`j',2] > SE[`k',2] {
				*continue
		}
		replace categF = "J`j'K`k'" ///
			if (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) <= SE[`k',2]

		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTP - ISR[`j',1]) if categF == "J`j'K`k'"

		*replace SE = SE[`k',3]*htrab/48 if categ == "i`j's`k'" & htrab < 40 & formal != 0
		replace SE = SE[`k',3] if categF == "J`j'K`k'" /*& htrab >= 40*/
	}
}


******************
** ISR SALARIOS **
replace SE = SE*.1492/.144

replace formal_asalariados = prop_salarios <= (1-DED[1,4]/100)
replace ISR_asalariados = ISR*(ing_subor)/(ing_bruto_tax-cuotasTPF) if formal_asalariados == 1
replace ISR_asalariados = ISR_asalariados*3.691/3.201


**************************
** ISR PERSONAS FISICAS **
replace formal_fisicas = prop_formal <= (1-DED[1,3]/100)
replace ISR_PF = ISR - ISR_asalariados if ISR - ISR_asalariados >= 0
replace ISR_PF = 0 if formal_fisicas == 0 | ISR_PF == . | ISR_PF < 0
replace ISR_PF = ISR_PF*0.234/0.175


**************************
** ISR PERSONAS MORALES **
replace formal_morales = prop_moral <= (1-PM[1,2]/100)

tabstat SE [fw=factor] if formal_asalariados == 1, stat(sum) f(%20.0fc) save
tempname SE
matrix `SE' = r(StatTotal)
capture drop SE_empresas
Distribucion SE_empresas, relativo(ing_bruto_tpm) macro(`=`SE'[1,1]')

replace ISR_PM = (ing_bruto_tpm-exen_tpm)*PM[1,1]/100 - SE_empresas if formal_morales == 1
replace ISR_PM = 0 if ISR_PM == .
replace ISR_PM = ISR_PM*4.063/3.848


*****************
** cuotasTPF IMSS **
replace cuotasTP = cuotasTP*1.578/1.400 if formal2 == 1


***************
** ISR TOTAL **
replace ISR = ISR_asalariados + ISR_PF + ISR_PM

* Results *
tabstat ISR_asalariados [fw=factor] if formal_asalariados == 1, stat(sum) f(%25.2fc) save
tempname SIMTAXS
matrix `SIMTAXS' = r(StatTotal)

tabstat ISR_PF [fw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname SIMTAX
matrix `SIMTAX' = r(StatTotal)

tabstat ISR_PM [fw=factor] if formal_morales == 1, stat(sum) f(%25.2fc) save
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

rename ISR_asalariados ISRAS
rename ISR_PF ISRPF
rename ISR_PM ISRPM
rename cuotasTP CUOTAS

noisily di _newline in g "  RESULTADOS ISR (salarios): " _col(33) in y %10.3fc ISR_AS_Mod
noisily di in g "  RESULTADOS ISR (f{c i'}sicas):  " _col(33) in y %10.3fc ISR_PF_Mod
noisily di in g "  RESULTADOS ISR (morales):  " _col(33) in y %10.3fc ISR_PM_Mod
noisily di in g "  RESULTADOS SE:  " _col(33) in y %10.3fc SE_Mod
noisily di in g "  RESULTADO ISR TOTAL:  " _col(33) in y %10.3fc ISR_AS_Mod+ISR_PF_Mod+ISR_PM_Mod
noisily di in g "  RESULTADOS Cuotas IMSS:  " _col(33) in y %10.3fc CUOTAS_Mod


************************/
**** Touchdown!!! :) ****
*************************
capture drop __*
save "`c(sysdir_personal)'/users/$id/isr_mod.dta", replace
timer off 94
timer list 94
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t94)/r(nt94)',.1) in g " segs  " _dup(20) "."
