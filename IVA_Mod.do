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
use if anio == `anio' | anio == 2020 using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
sort anio
local lambda = lambda[1]
local deflator = deflator[1]
scalar PIB = pibY[_N]


* Households *
use "`c(sysdir_personal)'/SIM/2020/expenditure_categ_iva.dta", clear


** Re C{c a'}lculo del IVA **
local j = 2
foreach k in alim alquiler cb educacion fuera mascotas med mujer otros trans transf {
	replace gasto_anual`k' = gasto_anual`k'*66.012/57.477
	
	if IVAT[`j',1] == 1 {
		replace IVA`k' = 0
		g cero`k' = gasto_anual`k'
	}
	if IVAT[`j',1] == 2 {
		replace IVA`k' = gasto_anual`k'*(prop_exen`k')*IVAT[1,1]/100/(1+IVAT[1,1]/100)*(1-IVAT[13,1]/100)
		g exento`k' = gasto_anual`k'*(1-prop_exen`k')
		g gas_exento`k' = gasto_anual`k'*(prop_exen`k')
	}
	if IVAT[`j',1] == 3 {
		replace IVA`k' = gasto_anual`k'*IVAT[1,1]/100/(1+IVAT[1,1]/100)*(1-IVAT[13,1]/100)
		g gravado`k' = gasto_anual`k'
	}
	local ++j
}


* SIMULACI{c O'}N: Impuesto al consumo *
egen Consumo = rsum(IVAalim IVAalquiler IVAcb IVAeducacion IVAfuera ///
	IVAmascotas IVAmed IVAmujer IVAotros IVAtrans IVAtransf TOTIEPS)

egen GastoTOT = rsum(gasto_anualalim gasto_anualalquiler gasto_anualcb gasto_anualeducacion ///
	gasto_anualfuera gasto_anualmascotas gasto_anualmed gasto_anualmujer gasto_anualotros ///
	gasto_anualtrans gasto_anualtransf)

capture egen GastoTOTC = rsum(cero*)
if _rc != 0 {
	g GastoTOTC = 0
}
capture egen GastoTOTE = rsum(exento*)
if _rc != 0 {
	g GastoTOTE = 0
}
capture egen GastoTOTG = rsum(gravado*)
if _rc != 0 {
	g GastoTOTG = 0
}
capture egen GastoTOTEG = rsum(gas_exento*)
if _rc != 0 {
	g GastoTOTEG = 0
}
capture egen IVATotal = rsum(IVAalim IVAalquiler IVAcb IVAeducacion IVAfuera ///
	IVAmascotas IVAmed IVAmujer IVAotros IVAtrans IVAtransf)
if _rc != 0 {
	drop IVATotal
	egen IVATotal = rsum(IVAalim IVAalquiler IVAcb IVAeducacion IVAfuera ///
	IVAmascotas IVAmed IVAmujer IVAotros IVAtrans IVAtransf)
}
replace IVATotal = IVATotal
tempfile ivamod
save `ivamod'	


* Households *
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
merge 1:1 (folioviv foliohog numren) using `ivamod', nogen update replace ///
	keepus(Consumo gasto_anual* IVA* GastoTOT*)
replace Consumo = 0 if Consumo == .
label var Consumo "los impuestos al consumo"

*noisily Simulador Consumo [fw=factor], base("ENIGH 2018") boot(1) reboot $nographs nooutput



* RESULTS IVA *
tabstat IVATotal Consumo [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA
matrix `IVA' = r(StatTotal)
scalar IVA_Mod = `IVA'[1,1]/scalar(PIB)*100

noisily di _newline in g " RESULTADOS IVA: " _col(29) in y %10.3fc IVA_Mod


* RESULTS GASTO *
tabstat GastoTOT GastoTOTC GastoTOTE GastoTOTG GastoTOTEG [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA2
matrix `IVA2' = r(StatTotal)

noisily di _newline in g " GASTO ANUAL: " _col(29) in y %10.3fc `IVA2'[1,1]/scalar(PIB)*100
noisily di in g " GASTO 0%: " _col(29)  in y %10.3fc `IVA2'[1,2]/scalar(PIB)*100
noisily di in g " GASTO EXENTO: " _col(29)  in y %10.3fc `IVA2'[1,3]/scalar(PIB)*100
noisily di in g " GASTO EXENTO GRAVADO: " _col(29)  in y %10.3fc `IVA2'[1,5]/scalar(PIB)*100
noisily di in g " GASTO GRAVADO: " _col(29)  in y %10.3fc `IVA2'[1,4]/scalar(PIB)*100

save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace



************************/
**** Touchdown!!! :) ****
*************************
timer off 93
timer list 93
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t93)/r(nt93)',.1) in g " segs  " _dup(20) "."
