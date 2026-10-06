****************************
***                      ***
***    4.2 MODULO IVA    ***
***                      ***
****************************
timer on 93
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY
noisily di _newline(2) in g "   MODULO: " in y "IVA"



*********************
** Microsimulacion **
*********************
* Precios de la ENIGH vigente (anioenigh) llevados al año del Paquete: hasta v8.7.2
* el año base estaba fijo en 2022 (ENIGH 2022), heredado del Paquete 2022 (v8.8.0). *
PIBDeflactor, nog nooutput
keep if anio == scalar(anioenigh) | anio == scalar(anioPE)
local lambda = lambda[1]
local deflator = deflator[1]
local pibY = pibY[_N]



* Households *
use "${SIMROOT}/master/`=anioenigh'/categ_iva.dta", clear


** 5.2. Cálculo del IVA **
replace precio = precio/`deflator'
capture drop IVA
g IVA = 0
*levelsof categs, local(categs)
local j = 2
*foreach k of local categs {
foreach k in `"Alimentos"' `"Alquiler"' `"CanastaBas"' `"Educación"' `"FueraHog"' `"Mascotas"' `"Medicinas"' `"Mujer"' `"Otros"' `"TransporteFor"' `"TransporteLoc"' {
	if IVAT[`j',1] == 2 {
		replace IVA = IVA + precio*cant_pc_*prop*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	if IVAT[`j',1] == 3 {
		replace IVA = IVA + precio*cant_pc_*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	local ++j
}
collapse (sum) IVA_Sim=IVA (max) factor, by(folioviv foliohog numren)
tabstat IVA_Sim [aw=factor], stat(sum) f(%20.0fc) save

replace IVA_Sim = IVA*(1-IVAT[13,1]/100)

* RESULTS IVA *
tabstat IVA_Sim [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA_Sim
matrix `IVA_Sim' = r(StatTotal)
* Sin factor de ajuste: hasta v8.7.2 se multiplicaba por 4.249/4.495, calibración
* ad hoc del Paquete 2022 que cerraba contra la recaudación proyectada de entonces sin
* tocar la informalidad observada (IVAT[13]). La brecha simulación vs proyección LIF
* se declara como residuo documentado (CHANGELOG v8.8.0, runbook-deploys-ciep.md §9.4),
* nunca se absorbe con factores silenciosos. *
scalar IVA_Mod = `IVA_Sim'[1,1]/scalar(pibY)*100
noisily di _newline in g "   RESULTADOS IVA: " _col(33) in y %10.3fc IVA_Mod
capture confirm scalar IVAPIB
if _rc == 0 {
	noisily di in g "   IVA observado/proyectado (LIF): " _col(33) in y %10.3fc scalar(IVAPIB) in g "   brecha: " in y %6.3f IVA_Mod-scalar(IVAPIB) in g " pp (residuo documentado)"
}


/* RESULTS GASTO *
tabstat GastoTOT GastoTOTC GastoTOTE GastoTOTG GastoTOTEG [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA2
matrix `IVA2' = r(StatTotal)

noisily di _newline in g " GASTO ANUAL: " _col(29) in y %10.3fc `IVA2'[1,1]/`pibY'*100
noisily di in g " GASTO 0%: " _col(29)  in y %10.3fc `IVA2'[1,2]/`pibY'*100
noisily di in g " GASTO EXENTO: " _col(29)  in y %10.3fc `IVA2'[1,3]/`pibY'*100
noisily di in g " GASTO EXENTO GRAVADO: " _col(29)  in y %10.3fc `IVA2'[1,5]/`pibY'*100
noisily di in g " GASTO GRAVADO: " _col(29)  in y %10.3fc `IVA2'[1,4]/`pibY'*100*/

keep folioviv foliohog numren IVA
save `"${SIMROOT}/users/$pais/$id/iva_mod.dta"', replace



************************/
**** Touchdown!!! :) ****
*************************
timer off 93
timer list 93
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t93)/r(nt93)',.1) in g " segs  " _dup(20) "."
