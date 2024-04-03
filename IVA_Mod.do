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
keep if anio == 2022 | anio == aniovp
local lambda = lambda[1]
local deflator = deflator[1]
local pibY = pibY[_N]



* Households *
use "`c(sysdir_personal)'/SIM/`=anioenigh'/categ_iva.dta", clear


** 5.2. Cálculo del IVA **
capture drop IVA
g IVA = 0
levelsof categs, local(categs)
local j = 2
foreach k of local categs {
	if IVAT[`j',1] == 2 {
		replace IVA = IVA + precio*cant_pc_*proporcion*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	if IVAT[`j',1] == 3 {
		replace IVA = IVA + precio*cant_pc_*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	local ++j
}
tabstat IVA [aw=factor], stat(sum) f(%20.0fc) save
collapse (sum) IVA, by(folioviv foliohog numren)

replace IVA = IVA*(1-IVAT[13,1]/100)

tempfile ivamod
save `ivamod'


* Households *
use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
keep folioviv foliohog numren factor
merge 1:1 (folioviv foliohog numren) using `ivamod', nogen update replace keepus(IVA)


* RESULTS IVA *
noisily tabstat IVA [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA
matrix `IVA' = r(StatTotal)
scalar IVA_Mod = `IVA'[1,1]/`pibY'*100
noisily di _newline in g " RESULTADOS IVA: " _col(29) in y %10.3fc IVA_Mod


/* RESULTS GASTO *
tabstat GastoTOT GastoTOTC GastoTOTE GastoTOTG GastoTOTEG [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA2
matrix `IVA2' = r(StatTotal)

noisily di _newline in g " GASTO ANUAL: " _col(29) in y %10.3fc `IVA2'[1,1]/`pibY'*100
noisily di in g " GASTO 0%: " _col(29)  in y %10.3fc `IVA2'[1,2]/`pibY'*100
noisily di in g " GASTO EXENTO: " _col(29)  in y %10.3fc `IVA2'[1,3]/`pibY'*100
noisily di in g " GASTO EXENTO GRAVADO: " _col(29)  in y %10.3fc `IVA2'[1,5]/`pibY'*100
noisily di in g " GASTO GRAVADO: " _col(29)  in y %10.3fc `IVA2'[1,4]/`pibY'*100*/

save `"`c(sysdir_personal)'/users/$pais/$id/iva_mod.dta"', replace



************************/
**** Touchdown!!! :) ****
*************************
timer off 93
timer list 93
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t93)/r(nt93)',.1) in g " segs  " _dup(20) "."
