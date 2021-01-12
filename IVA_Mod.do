******************
*** MÓDULO IVA ***
******************
timer on 93
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY



*******************
* Microsimulacion *
use if anio == `anio' | anio == 2018 using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
local lambda = lambda[1]
local deflator = deflator[1]
scalar PIB = pibY[_N]


* Households *
use "`c(sysdir_site)'../basesCIEP/SIM/2018/expenditure_categ_iva.dta", clear
*replace factor = factor*79185533/77096593
*replace factor = round(factor,1)


** Re C{c a'}lculo del IVA **
local j = 2
foreach k in alim alquiler cb educacion fuera mascotas med otros trans transf {
	replace gasto_anual`k' = gasto_anual`k'/(`lambda'*`deflator')
	if IVA[`j',1] == 1 {
		replace IVA`k' = 0
	}
	if IVA[`j',1] == 2 {
		replace IVA`k' = gasto_anual`k'*IVA[1,1]/100*(1-.35125482)*(1-IVA[12,1]/100)
	}
	if IVA[`j',1] == 3 {
		replace IVA`k' = gasto_anual`k'*IVA[1,1]/100*(1-IVA[12,1]/100)
	}
	local ++j
}


* SIMULACI{c O'}N: Impuesto al consumo *
egen Consumo = rsum(IVAalim IVAalquiler IVAcb IVAeducacion IVAfuera ///
	IVAmascotas IVAmed IVAotros IVAtrans IVAtransf)
merge 1:1 (folioviv foliohog numren) using ///
	`"`c(sysdir_personal)'/users/$pais/$id/households.dta"', nogen //update replace
replace Consumo = 0 if Consumo == .
label var Consumo "los impuestos al consumo"

noisily Simulador Consumo [fw=factor], base("ENIGH 2018") boot(1) reboot //graphs

capture egen IVATotal = rsum(IVAalim IVAalquiler IVAcb IVAeducacion IVAfuera ///
	IVAmascotas IVAmed IVAotros IVAtrans IVAtransf)
if _rc != 0 {
	drop IVATotal
	egen IVATotal = rsum(IVAalim IVAalquiler IVAcb IVAeducacion IVAfuera ///
	IVAmascotas IVAmed IVAotros IVAtrans IVAtransf)
}

noisily tabstat IVATotal Consumo [fw=factor], stat(sum) f(%20.0fc) save
tempname IVA
matrix `IVA' = r(StatTotal)
scalar IVA_Mod = `IVA'[1,1]/scalar(PIB)*100

save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace



************************/
**** Touchdown!!! :) ****
*************************
timer off 93
timer list 93
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t93)/r(nt93)',.1) in g " segs  " _dup(20) "."
