********************
*** LINGO, Pemex ***
********************
clear all
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///       // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
cd `"`c(sysdir_personal)'"'



***************************
** Primero, los ingresos **
***************************
//noisily LIF if divCIEP2 == 4, by(divPE) rows(1) min(0) anio(2024) $update desde(2000) title("Ingresos petroleros") update



***************************************************
** Segundo, las aportaciones al gobierno federal **
***************************************************


************************************************
** Eje 1: Venta de bienes y servicios (PEMEX) **
DatosAbiertos XKC0106, nog

keep if anio == 2023
rename monto Ventas
keep anio Ventas

tempfile XKC0106
save `XKC0106'


** Otros ingresos **
DatosAbiertos XKC0179, nog

keep if anio == 2023
rename monto OtrosIngresos
keep anio OtrosIngresos

replace OtrosIngresos = OtrosIngresos //- 166615122970

tempfile XKC0179
save `XKC0179'


** Append **
use `XKC0106', clear
append using `XKC0179'

tempvar from to
g `to' = "Pemex"

collapse (sum) Ing_Propios_Ventas=Ventas Ing_Propios__Otros_Ingresos=OtrosIngresos, by(anio `to')
reshape long Ing_Propios_, i(anio) j(`from') string

encode `to', g(to)
encode `from', g(from)

rename Ing_Propios_ profile
tempfile eje1
save `eje1'



*******************************************************
** Eje 2: Gastos operativos, financieros e impuestos **
DatosAbiertos XKC0113, nog

keep if anio == 2023
rename monto Impuestos
keep anio Impuestos

replace Impuestos = Impuestos + 157500*1000000 + 86640*1000000

tempfile XKC0113
save `XKC0113'


** Gasto programable **
DatosAbiertos XKC0131, nog

keep if anio == 2023
rename monto GastoProgramable
keep anio GastoProgramable

tempfile XKC0131
save `XKC0131'


** Gasto no programable **
DatosAbiertos XKC0157, nog

keep if anio == 2023
rename monto GastoNoProgramable
keep anio GastoNoProgramable

tempfile XKC0157
save `XKC0157'


** Append **
use `eje1', clear
collapse (sum) profile, by(to)
local from = to in 1

tempvar to
use `XKC0113', clear
append using `XKC0131'
append using `XKC0157'
collapse (sum) Ing_Propios_Gobierno_Federal=Impuestos Ing_Propios_Gastos_Operativos=GastoProgramable ///
    Ing_Propios_Gastos_Financieros=GastoNoProgramable, by(anio)
reshape long Ing_Propios_, i(anio) j(`to') string

g from = `from'
label define from 1 "Pemex", add
label values from from

encode `to', g(to)
rename Ing_Propios_ profile
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











noisily SankeySumSim, anio(2023) name(Fed) folder(SankeyPemex) a(`eje1') b(`eje2') c(`eje3') //d(`eje4') 
