**************
*** SANKEY ***
**************
timer on 9
if "`1'" == "" {
	local 1 = "decil"
	local 2 = 2023
}





***************************************
*** 1 Sistema de Cuentas Nacionales ***
***************************************
SCN, anio(`2') nographs




**********************************/
** Eje 1: Generación del ingreso **
capture use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen replace update
if _rc != 0 {
	*use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
}
tempvar Laboral Consumo Capital FMP
egen `Laboral'  = rsum(ISRAS ISRPF CUOTAS)
egen `Consumo'  = rsum(IVA IEPSP IEPSNP ISAN IMPORT)
egen `Capital'  = rsum(ISRPM OTROSK)
egen `FMP' = rsum(FMP)

collapse (sum) ing_Imp_al_trabajo=`Laboral' ing__Imp_al_consumo=`Consumo' ///
	ing___Imp_al_capital=`Capital' /*ing____FMP=`FMP'*/ [fw=factor], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* IMSS e ISSSTE *
set obs `=_N+1'
replace from = 99 in -1
replace profile = (scalar(IMSS)+scalar(ISSSTE))/100*scalar(PIB) in -1
replace to = 4 in -1
label define `1' 99 "IMSS, ISSSTE", add

* CFE *
set obs `=_N+1'
replace from = 98 in -1
replace profile = scalar(CFE)/100*scalar(PIB) in -1
replace to = 4 in -1
label define `1' 98 "CFE", add

* Pemex *
set obs `=_N+1'
replace from = 97 in -1
replace profile = (scalar(PEMEX))/100*scalar(PIB) in -1
replace to = 4 in -1
label define `1' 97 "Pemex", add
label define to 4 "Empresas públicas", add

* FMP *
set obs `=_N+1'
replace from = 97 in -1
replace profile = scalar(FMP)/100*scalar(PIB) in -1
replace to = 5 in -1
label define to 5 "FMP", add

* TOTAL *
tabstat profile, stat(sum) f(%20.0fc) save
tempname ingtot
matrix `ingtot' = r(StatTotal)

tempfile eje1
save `eje1'




********************
** Eje 4: Consumo **
use if anio == `2' using `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', clear
local ajustepob = poblacion

capture use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen replace update
if _rc != 0 {
	*use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
}
tabstat factor, stat(sum) f(%20.0fc) save
tempname pobenigh
matrix `pobenigh' = r(StatTotal)

tabstat factor if edad >= 65, stat(sum) f(%20.0fc) save
tempname pobpenbien
matrix `pobpenbien' = r(StatTotal)

tabstat factor, stat(sum) f(%20.0fc) save
tempname pobtot
matrix `pobtot' = r(StatTotal)*`ajustepob'/`pobenigh'[1,1]

replace Pension = Pension + Pensión_AM
*tabstat Pension Educación Salud Otros_gastos [fw=factor], stat(sum) f(%20.0fc) save
*tempname GAST 
*matrix `GAST' = r(StatTotal)

collapse (sum) gas_Educación=Educación gas_Salud=Salud /*gas__Salarios_de_gobierno=Salarios*/ ///
	gas___Pensiones=Pension gas____Transferencias=IngBasico ///
	gas____Inversión=Otras_inversiones [fw=factor], by(`1')

levelsof `1', local(`1')
foreach k of local `1' {
	local oldlabel : label (`1') `k'
	label define `1' `k' "_`oldlabel'", modify
}

* from *
tempvar from
reshape long gas_, i(`1') j(`from') string
rename gas_ profile
encode `from', g(from)

* to *
rename `1' to

* Costo de la deuda *
set obs `=_N+5'

replace from = 97 in -1
label define from 97 "Costo de la deuda", add

replace profile = scalar(gascosto)*`pobtot'[1,1] in -1

replace to = 14 in -1
label define `1' 14 "Sistema financiero", add

* Aportaciones y participaciones *
replace from = 94 in -2
label define from 94 "Otras Part y Aport", add

replace profile = scalar(gasfeder)*`pobtot'[1,1] in -2

replace to = 12 in -2
label define `1' 12 "Estados y municipios", add

* Otros *
replace from = 95 in -3
label define from 95 "Otros gastos", add

replace profile = scalar(gasotros)*`pobtot'[1,1] in -3

replace to = 13 in -3
label define `1' 13 "No distribuibles", add

* Energía *
replace from = 96 in -4
label define from 96 "Energía", add

replace profile = (scalar(gaspemex)+scalar(gascfe)+scalar(gassener)+scalar(gasinverf))*`pobtot'[1,1] in -4

replace to = 11 in -4
label define `1' 11 "CFE Pemex SENER", add

* Costo de la deuda energía *
replace from = 96 in -5

replace profile = scalar(gascosdeue)*`pobtot'[1,1] in -5

replace to = 14 in -5


* Gasto total */
tabstat profile, stat(sum) f(%20.0fc) save
tempname gastot
matrix `gastot' = r(StatTotal)

sort from to
tempfile eje4
save `eje4'




********************
** DEUDA o AHORRO **
if `gastot'[1,1]-`ingtot'[1,1] > 0 {
	use `eje1', clear

	set obs `=_N+1'

	replace from = 100 in -1
	replace profile = (`gastot'[1,1]-`ingtot'[1,1]) in -1
	replace to = 6 in -1

	label define `1' 100 "Futuro", add
	label define to 6 "Endeudamiento", add

	save `eje1', replace
}
else {
	use `eje4', clear

	set obs `=_N+1'

	replace from = 101 in -1
	replace profile = (`ingtot'[1,1]-`gastot'[1,1]) in -1
	replace to = 15 in -1

	label define `1' 15 "Futuro", add
	label define from 101 "Ahorro", add

	save `eje4', replace
}




********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "$paqueteEconomico"
label values to PIB

tempfile eje2
save `eje2'




********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "$paqueteEconomico"
label values from PIB

tempfile eje3
save `eje3'




************
** Sankey **
noisily SankeySumSim, anio(`2') name(`1') folder(SankeySF5) a(`eje1') b(`eje2') c(`eje3') d(`eje4') 

timer off 9
timer list 9
noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
