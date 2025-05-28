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
PIBDeflactor, nog nooutput
keep if anio == 2022 | anio == scalar(anioPE)
local lambda = lambda[1]
local deflator = deflator[1]
local pibY = pibY[_N]



* Households *
use "`c(sysdir_site)'/04_master/`=anioenigh'/categ_iva.dta", clear


** 5.2. Cálculo del IVA **
replace precio = precio/`deflator'
capture drop IVA
g IVA = 0
*levelsof categs, local(categs)
local j = 2
*foreach k of local categs {
foreach k in `"Alimentos"' `"Alquiler"' `"CanastaBas"' `"Educación"' `"FueraHog"' `"Mascotas"' `"Medicinas"' `"Mujer"' `"Otros"' `"TransporteFor"' `"TransporteLoc"' {
	if IVAT[`j',1] == 2 {
		replace IVA = IVA + precio*cant_pc_*proporcion*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	if IVAT[`j',1] == 3 {
		replace IVA = IVA + precio*cant_pc_*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	local ++j
}
collapse (sum) IVA (max) factor, by(folioviv foliohog numren)
tabstat IVA [aw=factor], stat(sum) f(%20.0fc) save

replace IVA = IVA*(1-IVAT[13,1]/100)

* RESULTS IVA *
tabstat IVA [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA
matrix `IVA' = r(StatTotal)
scalar IVA_Mod = `IVA'[1,1]/`pibY'*100*4.064/3.889
noisily di _newline in g "   RESULTADOS IVA: " _col(33) in y %10.3fc IVA_Mod


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
save `"`c(sysdir_site)'/users/$pais/$id/iva_mod.dta"', replace



************************/
**** Touchdown!!! :) ****
*************************
timer off 93
timer list 93
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t93)/r(nt93)',.1) in g " segs  " _dup(20) "."
