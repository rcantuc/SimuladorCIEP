********************
*** LINGO, Pemex ***
********************
clear all
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///       // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
cd `"`c(sysdir_personal)'"'





***************************************
***                                 ***
*** Eje 1: Ingresos propios (PEMEX) ***
***                                 ***
***************************************

** 1.1. Ventas netas de bienes y servicios **
DatosAbiertos XKC0106, nog
rename monto Ventas
keep anio Ventas
tempfile XKC0106
save `XKC0106'


** 1.2. Otros ingresos **
DatosAbiertos XKC0179, nog
rename monto OtrosIngresos
keep anio OtrosIngresos
tempfile XKC0179
save `XKC0179'


** 1.3 Append **
use `XKC0106', clear
append using `XKC0179'

tempvar from to
g `to' = "Pemex"
collapse (sum) Ing_Propios_Ventas=Ventas Ing_Propios__Otros_Ingresos=OtrosIngresos if anio >= 2019 & anio <= 2023, by(anio `to')
reshape long Ing_Propios_, i(anio) j(`from') string

encode `to', g(to)
encode `from', g(from)

rename Ing_Propios_ profile
tempfile eje1
save `eje1'





*********************************************************
***                                                   ***
*** Eje 2: Gastos operativos, financieros e impuestos ***
***                                                   ***
*********************************************************

** 2.1. Derechos y enteros **
DatosAbiertos XKC0113, nog
rename monto Derechos
keep anio Derechos
tempfile XKC0113
save `XKC0113'


** 2.2. Gasto programable **
DatosAbiertos XKC0131, nog
rename monto Programable
keep anio Programable
tempfile XKC0131
save `XKC0131'


** 2.3. Gasto no programable **
DatosAbiertos XKC0157, nog
rename monto NoProgramable
keep anio NoProgramable
tempfile XKC0157
save `XKC0157'


** Append **
use `eje1', clear
collapse (sum) profile, by(to)
local from = to
drop to

use `XKC0113', clear
append using `XKC0131'
append using `XKC0157'
collapse (sum) Gastos_Derechos_y_Enteros=Derechos Gastos_Gastos_Operativos=Programable ///
    Gastos_Gastos_Financieros=NoProgramable if anio >= 2019 & anio <= 2023, by(anio)
tempvar to
reshape long Gastos_, i(anio) j(`to') string

g from = `from'
label define from 1 "Pemex", add
label values from from

encode `to', g(to)
rename Gastos_ profile
tempfile eje2
save `eje2'










**********************************************
** Eje 3: Aportaciones del gobierno federal **
use `eje2', clear
collapse (sum) profile if to == 3, by(to)
rename to from 




replace profile = 166615122970
g to = 5
label define to 5 "Pemex", add

set obs `=_N+1'
replace from = 3 if from == .
replace to = 6 if to == .
label define to 6 "Reducción DUC", add
replace profile = 157500*1000000 if profile == .

set obs `=_N+1'
replace from = 3 if from == .
replace to = 7 if to == .
label define to 7 "Estímulos fiscales", add
replace profile = 86640*1000000 if profile == .

label values to to

tempfile eje3
save `eje3'




noisily SankeySumLoop, anio(2023) name(Fed) folder(SankeyPemex) a(`eje1') b(`eje2') //c(`eje3') //d(`eje4') 






***************************
** Primero, los ingresos **
***************************
//noisily LIF if divCIEP2 == 4, by(divPE) rows(1) min(0) anio(2024) $update desde(2000) title("Ingresos petroleros") update



***************************************************
** Segundo, las aportaciones al gobierno federal **
***************************************************

