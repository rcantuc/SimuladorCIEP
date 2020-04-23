**************
*** SANKEY ***
**************
timer on 6
if "`1'" == "" {
	local 1 = "decil"
	local 2 = 2020
}

if "$pais" != "" {
	exit
}


********************
** Sistema Fiscal **
LIF, anio(`2') lif
local ISR = r(ISR)
local ISRPM = `ISR'*((1687830.1-(783743.8+45756.7))/1687830.1)
local oye = r(CFE)+r(Pemex)+r(IMSS)+r(ISSSTE)+r(Otras_empresas)

LIF, anio(`2') by(divGA) lif
local alingreso = r(Impuestos_al_ingreso)
local alconsumo = r(Impuestos_al_consumo)
local otros = r(Ingresos_de_capital)

PEF if anio == `2', by(divGA)
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)
local PenBienestar = r(Pensi_c_o__n_Bienestar)
local CostodeDeuda = r(Costo_de_la_deuda)

PEF if anio == `2' & ramo == 28
local Part = r(Resumido_total)


**********************************/
** Eje 1: Generación del ingreso **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

collapse (sum) ing_Ingreso=Ingreso ing_Consumo=Consumo ing__De_Capital=ISR__PM [fw=factor], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* Otros ingresos *
set obs `=_N+2'
replace from = 99 in -2
replace profile = `oye' in -2
replace to = 3 in -2
label define `1' 99 "OyE estatales", add

replace from = 98 in -1
replace profile = `otros'-`oye' in -1
replace to = 3 in -1
label define `1' 98 "Aprov Produc Otros", add

* Gasto total *
noisily tabstat profile, stat(sum) f(%20.0fc) save
tempname ingtot
matrix `ingtot' = r(StatTotal)

tempfile eje1
save `eje1'


********************
** Eje 4: Consumo **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
tempname pobpenbien
matrix `pobpenbien' = r(StatTotal)

tabstat Pension Educacion Salud PenBienestar OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
tempname GAST 
matrix `GAST' = r(StatTotal)

collapse (sum) gas_Pensiones=Pension gas_Educacion=Educacion gas_Salud=Salud ///
	gas__Pension_Bienestar=PenBienestar gas_Salarios_de_gobierno=Salarios gas_Ingreso_Basico=IngBasico [fw=factor], by(`1')

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
set obs `=_N+3'

replace from = 97 in -1
label define from 97 "Costo de la deuda", add

replace profile = `CostodeDeuda' in -1

replace to = 11 in -1
label define `1' 11 "Sistema financiero", add

* Aportaciones y participaciones *
replace from = 96 in -2
label define from 96 "Participaciones", add

replace profile = `Part' in -2

replace to = 12 in -2
label define `1' 12 "Estados y municipios", add

* Aportaciones y participaciones *
replace from = 95 in -3
label define from 95 "Otros gastos", add

replace profile = (`OtrosGas'-`Part'-scalar(servpers)/100*scalar(pibY)) in -3

replace to = 13 in -3
label define `1' 13 "No distribuible", add

* Gasto total *
noisily tabstat profile, stat(sum) f(%20.0fc) save
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
	replace to = 4 in -1

	label define `1' 100 "Futuro", add
	label define to 4 "Endeudamiento", add

	save `eje1', replace
}
else {
	use `eje4', clear

	set obs `=_N+1'

	replace from = 101 in -1
	replace profile = (`ingtot'[1,1]-`gastot'[1,1]) in -1
	replace to = 14 in -1

	label define to 14 "Futuro", add
	label define `1' 101 "Ahorro", add

	save `eje4', replace
}


********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "Sistema Fiscal"
label values to PIB

tempfile eje2
save `eje2'


********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "Sistema Fiscal"
label values from PIB

tempfile eje3
save `eje3'


************
** Sankey **
noisily SankeySum, anio(`2') name(`1') folder(SankeySF) a(`eje1') b(`eje2') c(`eje3') d(`eje4') 

timer off 6
timer list 6
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t6)/r(nt6)',.1) in g " segs."
