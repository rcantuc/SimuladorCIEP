********************************
***                          ***
*** LINGO, Sankey's de Pemex ***
***                          ***
********************************
clear all
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///       // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
cd "`c(sysdir_personal)'"


*************************
***                   ***
*** 1. Bases de datos ***
***                   ***
*************************

** 1.1. Ventas netas de bienes y servicios **
DatosAbiertos XKC0106, nog
g montoR = monto/deflator
rename monto Ventas

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname Ventas_pib
matrix `Ventas_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname Ventas_pib2013
matrix `Ventas_pib2013' = r(StatTotal)

keep anio Ventas
save XKC0106, replace

** 1.2. Otros ingresos **
DatosAbiertos XKC0179, nog
g montoR = monto/deflator
rename monto OtrosIngresos

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname OtrosIngresos_pib
matrix `OtrosIngresos_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname OtrosIngresos_pib2013
matrix `OtrosIngresos_pib2013' = r(StatTotal)

keep anio OtrosIngresos
save XKC0179, replace

** 2.1. Derechos y enteros **
DatosAbiertos XKC0113, nog
g montoR = monto/deflator
rename monto Derechos

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname Derechos_pib
matrix `Derechos_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname Derechos_pib2013
matrix `Derechos_pib2013' = r(StatTotal)

keep anio Derechos
save XKC0113, replace

** 2.2. Gasto programable **
DatosAbiertos XKC0131, nog
g montoR = monto/deflator
rename monto Programable

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname Programable_pib
matrix `Programable_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname Programable_pib2013
matrix `Programable_pib2013' = r(StatTotal)

keep anio Programable
save XKC0131, replace

** 2.2.1 Pensiones y jubilaciones **
DatosAbiertos XKC0139, nog
g montoR = monto/deflator
rename monto Pensiones

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname Pensiones_pib
matrix `Pensiones_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname Pensiones_pib2013
matrix `Pensiones_pib2013' = r(StatTotal)

keep anio Pensiones
save XKC0139, replace

** 2.2.2. Gastos de inversión **
DatosAbiertos XKC0145, nog
g montoR = monto/deflator
rename monto Inversion

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname Inversion_pib
matrix `Inversion_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname Inversion_pib2013
matrix `Inversion_pib2013' = r(StatTotal)

keep anio Inversion
save XKC0145, replace

** 2.3. Gasto no programable **
DatosAbiertos XKC0157, nog
g montoR = monto/deflator
rename monto NoProgramable

tabstat montoR if anio >= 2019 & anio <= 2024, save stat(sum)
tempname NoProgramable_pib
matrix `NoProgramable_pib' = r(StatTotal)

tabstat montoR if anio >= 2013 & anio < 2019, save stat(sum)
tempname NoProgramable_pib2013
matrix `NoProgramable_pib2013' = r(StatTotal)

keep anio NoProgramable
save XKC0157, replace


** 1.2. Información adicional **
PIBDeflactor, aniovp(2024) nographs
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2015 {
		local deflator15 = deflator[`k']
	}
	if anio[`k'] == 2016 {
		local deflator16 = deflator[`k']
	}
	if anio[`k'] == 2017 {
		local deflator17 = deflator[`k']
	}
	if anio[`k'] == 2018 {
		local deflator18 = deflator[`k']
	}
    if anio[`k'] == 2019 {
        local deflator19 = deflator[`k']
    }
    if anio[`k'] == 2020 {
        local deflator20 = deflator[`k']
    }
    if anio[`k'] == 2021 {
        local deflator21 = deflator[`k']
    }
    if anio[`k'] == 2022 {
        local deflator22 = deflator[`k']
    }
    if anio[`k'] == 2023 {
        local deflator23 = deflator[`k']
    }
    if anio[`k'] == 2024 {
        local deflator24 = deflator[`k']
    }
}
tempfile PIBDeflactor
save `PIBDeflactor'

local reduccionductot = 0
local estimulosfiscalestot = 0
local apoyospatrimonialestot = 0
local fmptot = 0
forvalues anio = 2015(1)2024 {
	if "`anio'" == "2015" {
		local reduccionduc = 0/`deflator15'
		local estimulosfiscales = 0/`deflator15'
		local apoyospatrimoniales = 60000*1000000/`deflator15'
		local indirectos = 0/`deflator15'
		local fmp = 426395128797/`deflator15'
		local fmp_feip_feief = 5.38
		local fmp_feh = 1.52
		local fmp_investigacion = 1.23
		local fmp_tesofe = 91.87
		local fmp_otros = 0.00

		local reduccionductot_pre = `reduccionduc'
		local apoyospatrimonialestot_pre = `apoyospatrimoniales'
	}
	if "`anio'" == "2016" {
		local reduccionduc = 0/`deflator16'
		local estimulosfiscales = 40213*1000000/`deflator16'
		local apoyospatrimoniales = 161939*1000000/`deflator16'
		local indirectos = 0/`deflator16'
		local fmp = 321023438114/`deflator16'
		local fmp_feip_feief = 4.48
		local fmp_feh = 1.29
		local fmp_investigacion = 1.03
		local fmp_tesofe = 93.20
		local fmp_otros = 0.00

		local reduccionductot_pre = `reduccionduc' + `reduccionductot_pre'
		local apoyospatrimonialestot_pre = `apoyospatrimoniales' + `apoyospatrimonialestot_pre'
	}
	if "`anio'" == "2017" {
		local reduccionduc = 0/`deflator17'
		local estimulosfiscales = 7769*1000000/`deflator17'
		local apoyospatrimoniales = 0/`deflator17'
		local indirectos = 0/`deflator17'
		local fmp = 434763080208/`deflator17'
		local fmp_feip_feief = 2.48
		local fmp_feh = 0.73
		local fmp_investigacion = 0.57
		local fmp_tesofe = 96.21
		local fmp_otros = 0.00

		local reduccionductot_pre = `reduccionduc' + `reduccionductot_pre'
		local apoyospatrimonialestot_pre = `apoyospatrimoniales' + `apoyospatrimonialestot_pre'
	}
	if "`anio'" == "2018" {
		local reduccionduc = 0/`deflator18'
		local estimulosfiscales = 11110*1000000/`deflator18'
		local apoyospatrimoniales = 0/`deflator18'
		local indirectos = 0/`deflator18'
		local fmp = 526831188563/`deflator18'
		local fmp_feip_feief = 2.39
		local fmp_feh = 0.72
		local fmp_investigacion = 0.55
		local fmp_tesofe = 96.33
		local fmp_otros = 0.01

		local reduccionductot_pre = `reduccionduc' + `reduccionductot_pre'
		local apoyospatrimonialestot_pre = `apoyospatrimoniales' + `apoyospatrimonialestot_pre'
	}
	if "`anio'" == "2019" {
		local reduccionduc = 0/`deflator19'
		local estimulosfiscales = (25787+38704)*1000000/`deflator19'
		local apoyospatrimoniales = 122131*1000000/`deflator19'
		local indirectos = 443943085740*0/`deflator19'
		local fmp = 410158961425/`deflator19'
		local fmp_feip_feief = 3.42
		local fmp_feh = 1.05
		local fmp_investigacion = 0.78
		local fmp_tesofe = 94.75
		local fmp_otros = 0.00

		local reduccionductot = `reduccionduc'
		local estimulosfiscalestot = `estimulosfiscales'
		local apoyospatrimonialestot = `apoyospatrimoniales'
		local fmptot = `fmp'
	}
	if "`anio'" == "2020" {
		local reduccionduc = 26500*1000000/`deflator20'
		local estimulosfiscales = (65000+5800)*1000000/`deflator20'
		local apoyospatrimoniales = 46256*1000000/`deflator20'
		local indirectos = 399325085921*0/`deflator20'
		local fmp = 187271584137/`deflator20'
		local fmp_feip_feief = 5.91
		local fmp_feh = 1.79
		local fmp_investigacion = 1.35
		local fmp_tesofe = 90.95
		local fmp_otros = 0.00

		local reduccionductot = `reduccionductot' + `reduccionduc'
		local estimulosfiscalestot = `estimulosfiscalestot' + `estimulosfiscales'
		local apoyospatrimonialestot = `apoyospatrimonialestot' + `apoyospatrimoniales'
		local fmptot = `fmptot' + `fmp'
	}
	if "`anio'" == "2021" {
		local reduccionduc = 77900*1000000/`deflator21'
		local estimulosfiscales = (73280+22915)*1000000/`deflator21'
		local apoyospatrimoniales = 316354*1000000/`deflator21'
		local indirectos = 357608812555*0/`deflator21'
		local fmp = 383922663710/`deflator21'
		local fmp_feip_feief = 2.67
		local fmp_feh = 0.83
		local fmp_investigacion = 0.61
		local fmp_tesofe = 95.89
		local fmp_otros = 0.00

		local reduccionductot = `reduccionductot' + `reduccionduc'
		local estimulosfiscalestot = `estimulosfiscalestot' + `estimulosfiscales'
		local apoyospatrimonialestot = `apoyospatrimonialestot' + `apoyospatrimoniales'
		local fmptot = `fmptot' + `fmp'
	}
	if "`anio'" == "2022" {
		local reduccionduc = 238100*1000000/`deflator22'
		local estimulosfiscales = (7455+23000)*1000000/`deflator22'
		local apoyospatrimoniales = 188306*1000000/`deflator22'
		local indirectos = 299434678260*0/`deflator22'
		local fmp = 529233592611/`deflator22'
		local fmp_feip_feief = 1.66
		local fmp_feh = 0.51
		local fmp_investigacion = 0.38
		local fmp_tesofe = 97.45
		local fmp_otros = 0.00

		local reduccionductot = `reduccionductot' + `reduccionduc'
		local estimulosfiscalestot = `estimulosfiscalestot' + `estimulosfiscales'
		local apoyospatrimonialestot = `apoyospatrimonialestot' + `apoyospatrimoniales'
		local fmptot = `fmptot' + `fmp'
	}
	if "`anio'" == "2023" {
		local reduccionduc = 157500000000/`deflator23'
		local estimulosfiscales = 86640000000/`deflator23'
		local apoyospatrimoniales = 166615122970/`deflator23'
		local indirectos = 416875393557*0/`deflator23'
		local fmp = 255633786073/`deflator23'
		local fmp_feip_feief = 4.05
		local fmp_feh = 1.24
		local fmp_investigacion = 0.93
		local fmp_tesofe = 93.78
		local fmp_otros = 0.00

		local reduccionductot = `reduccionductot' + `reduccionduc'
		local estimulosfiscalestot = `estimulosfiscalestot' + `estimulosfiscales'
		local apoyospatrimonialestot = `apoyospatrimonialestot' + `apoyospatrimoniales'
		local fmptot = `fmptot' + `fmp'
	}
	if "`anio'" == "2024" {
		local reduccionduc = 178735000000/`deflator24'
		local estimulosfiscales = 0/`deflator24'
		local apoyospatrimoniales = 170929000000/`deflator24'
		local indirectos = 0/`deflator24'
		local fmp = 41468323430/.2616/`deflator24'
		local fmp_feip_feief = 4.05
		local fmp_feh = 1.24
		local fmp_investigacion = 0.93
		local fmp_tesofe = 93.78
		local fmp_otros = 0.00

		local reduccionductot = 449960000000 //`reduccionductot' + `reduccionduc'
		local estimulosfiscalestot = 48283000000 //`estimulosfiscalestot' + `estimulosfiscales'
		local apoyospatrimonialestot = 921736000000 //`apoyospatrimonialestot' + `apoyospatrimoniales'
		local fmptot = `fmptot' + `fmp'
	}
}

***************************************
***                                 ***
*** Eje 1: Ingresos propios (PEMEX) ***
***                                 ***
***************************************

** 1.1. Ingresos propios **
use XKC0106, clear
append using XKC0179

merge m:1 anio using `PIBDeflactor', nogen

replace Ventas = Ventas/deflator
replace OtrosIngresos = OtrosIngresos/deflator

collapse (sum) Ing_Propios_Ventas=Ventas ///
	Ing_Propios_Otros_Ingresos=OtrosIngresos ///
	if anio >= 2019 & anio <= 2024

replace Ing_Propios_Ventas = Ing_Propios_Ventas*`Ventas_pib'[1,1]/`Ventas_pib2013'[1,1] + `indirectos'
replace Ing_Propios_Otros_Ingresos = Ing_Propios_Otros_Ingresos - `apoyospatrimonialestot'
replace Ing_Propios_Otros_Ingresos = Ing_Propios_Otros_Ingresos*(`OtrosIngresos_pib'[1,1]-`apoyospatrimonialestot')/(`OtrosIngresos_pib2013'[1,1]-`apoyospatrimonialestot_pre')

replace Ing_Propios_Ventas = Ing_Propios_Ventas*(1-.3043)
replace Ing_Propios_Otros_Ingresos = Ing_Propios_Otros_Ingresos*(1-.3043)

** 1.2. Reshape para el Sankey **
tempvar from to
g `to' = "Pemex"
reshape long Ing_Propios_, i(`to') j(`from') string

encode `to', g(to)
encode `from', g(from)

rename Ing_Propios_ profile

tabstat profile, s(sum) save
local ingresosPemex = r(StatTotal)[1,1] 
local ingresosPemex = `ingresosPemex' + `reduccionductot' + `estimulosfiscalestot' + `apoyospatrimonialestot'

set obs `=_N+1'

replace profile = `indirectos' in -1
replace to = 98 in -1
replace from = 2 in -1
label define to 98 "Imp Indirectos", add

replace profile = profile / 1000000000
tempfile eje1
save `eje1'


*********************************************************
***                                                   ***
*** Eje 2: Gastos operativos, financieros e impuestos ***
***                                                   ***
*********************************************************
use XKC0113, clear
append using XKC0131
append using XKC0157
append using XKC0139
append using XKC0145

merge m:1 anio using `PIBDeflactor', nogen

replace Derechos = Derechos/deflator
replace Programable = Programable/deflator
replace NoProgramable = NoProgramable/deflator
replace Pensiones = Pensiones/deflator
replace Inversion = Inversion/deflator

collapse (sum) Gastos_Derechos_y_Enteros=Derechos ///
	Gastos_Gastos_Operativos=Programable ///
	Gastos_Gastos_Financieros=NoProgramable ///
	Gastos_Pensiones=Pensiones ///
	Gastos_Inversión=Inversion ///
	if anio >= 2019 & anio <= 2024

replace Gastos_Derechos = Gastos_Derechos*`Derechos_pib'[1,1]/`Derechos_pib2013'[1,1] + `indirectos'		// IEPS e IVA
replace Gastos_Derechos = Gastos_Derechos + `reduccionductot' 												// Reducción DUC
replace Gastos_Derechos = Gastos_Derechos + `estimulosfiscalestot' 											// Estímulos fiscales

replace Gastos_Gastos_Operativos = Gastos_Gastos_Operativos*`Programable_pib'[1,1]/`Programable_pib2013'[1,1]
replace Gastos_Gastos_Financieros = Gastos_Gastos_Financieros*`NoProgramable_pib'[1,1]/`NoProgramable_pib2013'[1,1]
replace Gastos_Pensiones = Gastos_Pensiones*`Pensiones_pib'[1,1]/`Pensiones_pib2013'[1,1]
replace Gastos_Inversión = Gastos_Inversión*`Inversion_pib'[1,1]/`Inversion_pib2013'[1,1]
replace Gastos_Gastos_Operativos = Gastos_Gastos_Operativos - Gastos_Inversión - Gastos_Pensiones

replace Gastos_Inversión = 0


tabstat Gastos_Derechos, s(sum) save
local gastosDerechos = r(StatTotal)[1,1] - `reduccionductot' - `estimulosfiscalestot' + `indirectos'

tempvar from to
g `from' = "Pemex"
reshape long Gastos_, i(`from') j(`to') string

encode `to', g(to)
encode `from', g(from)

rename Gastos_ profile

tabstat profile, s(sum) save
local gastosPemex = r(StatTotal)[1,1]

replace profile = profile / 1000000000
tempfile eje2
save `eje2'


********************************************************
***                                                  ***
*** Eje 3: Aportaciones al gobierno federal y al FMP ***
***                                                  ***
********************************************************
use `eje2', clear
collapse (sum) profile if to == 1, by(to)
rename to from 

g to = 6
label define to 6 "FMP", add
label values to to

tabstat profile, s(sum) save
local DerechosEnteros = r(StatTotal)[1,1]

*replace profile = `fmptot' / 1000000000
replace profile = profile - (`reduccionductot' + `estimulosfiscalestot')/1000000000 - `DerechosEnteros'*(.054389216)

set obs `=_N+1'

replace from = 1 in -1
replace to = 7 in -1
label define to 7 "Gobierno Federal", add
replace profile = `DerechosEnteros'*(.054389216) in -1 			// <--- Promedio de 2019 a 2024
local impuestosExtrac_Explora = profile*1000000000 in -1
local gastosDerechos = `gastosDerechos' - `impuestosExtrac_Explora'

set obs `=_N+1'

replace from = 1 in -1
replace to = 8 in -1
replace profile = (`reduccionductot' + `estimulosfiscalestot')/1000000000 in -1
label define to 8 "Pemex", add

set obs `=_N+1'

replace from = 200 in -1
replace to = 7 in -1
replace profile = `indirectos' / 1000000000 in -1
label define to 200 "Imp Indirectos", add

tempfile eje3
save `eje3'


********************************
** Eje 4: Aportaciones del FMP **
use `eje3', clear
collapse (sum) profile if to == 6, by(to)
rename to from 

g to = 7
label values to to

tabstat profile, s(sum) save
local profile = r(StatTotal)[1,1]
replace profile = `profile' * `fmp_tesofe' / 100

set obs `=_N+1'

replace from = 6 in -1
replace to = 101 in -1
replace profile = `profile' * `fmp_feip_feief' / 100 in -1
label define to 101 "Fondos", add

set obs `=_N+1'

replace from = 6 in -1
replace to = 102 in -1
replace profile = `profile' * `fmp_feh' / 100 in -1
label define to 102 "Fondos", add

set obs `=_N+1'

replace from = 6 in -1
replace to = 103 in -1
replace profile = `profile' * `fmp_investigacion' / 100 in -1
label define to 103 "Fondos", add

set obs `=_N+1'

replace from = 6 in -1
replace to = 104 in -1
replace profile = `profile' * `fmp_otros' / 100 in -1
label define to 104 "Otros", add

local deficit = 0
if `ingresosPemex' - `gastosPemex' < 0 {
	local deficit = -(`ingresosPemex' - `gastosPemex')*0
}
label define to 201 "Pemex", add

*if (`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimonialestot' - `deficit' + `impuestosExtrac_Explora') > 0 {
	set obs `=_N+1'
	
	replace from = 7 in -1
	replace to = 100 in -1
	replace profile = (`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimonialestot' - `deficit' + `impuestosExtrac_Explora')/1000000000 in -1
	label define to 100 "Aportación neta", add
/*}
else {
	set obs `=_N+1'
	
	replace from = 202 in -1
	replace to = 7 in -1
	replace profile = -(`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimonialestot' - `deficit' + `impuestosExtrac_Explora')/1000000000 in -1
	label define to 202 "Subsidio neto", add
}*/

label values to to
tempfile eje4
save `eje4'


**********************************************
** Eje 5: Aportaciones del gobierno federal **
use `eje4', clear
collapse (sum) profile if to == 7, by(to)
rename to from

replace profile = `apoyospatrimonialestot' + `deficit'				// Apoyos patrimoniales
replace profile = profile / 1000000000

g to = 201
label values to to

tempfile eje5
save `eje5'


*noisily SankeySumLoop, anio(2024) name(2025_2030) folder(SankeyPemex) a(`eje1') b(`eje2') c(`eje3') d(`eje4') e(`eje5')
noisily SankeySumLoop, anio(2024) name(2025_2030Plus) folder(SankeyPemex) a(`eje1') b(`eje2') c(`eje3') d(`eje4') e(`eje5')
