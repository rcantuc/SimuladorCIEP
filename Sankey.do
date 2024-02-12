**************
*** SANKEY ***
**************
if "`1'" == "" {
	clear programs
	local 1 = "decil"
	local 2 = 2022
	local 3 = "SankeyNTA"
	scalar anioenigh = 2022
}
timer on 7



****************
** 0 Economia **
SCN, anio(`2') nographs



****************
** 1 Ingresos **
LIF, anio(`2') nographs min(0)
local CuotasIMSS = r(Cuotas_IMSS)
local IMSSpropio = r(IMSS) //-`CuotasIMSS'
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP___derechos_petro__)
local Mejoras = r(Contribuciones_de_mejoras)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)



**********************************/
** Eje 1: Generación del ingreso **
use `"`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta"', clear
replace Yk = Yk - ing_estim_alqu
collapse (sum) ing_Ing_Laboral=Yl ing_Ing_Capital=Yk ing_Alquiler_propio=ing_estim_alqu [fw=factor], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* Sector Publico *
set obs `=_N+1'
replace from = -2 in -1
replace profile = `IMSSpropio' + `ISSSTEpropio' + `CFEpropio' + `Pemexpropio' + `FMP' + `OtrasEmpresas' in -1
label define `1' -2 "Empr_públicas", add
replace to = 2 in -1

* ROW *
set obs `=_N+2'
replace from = -1 if from == .
replace to = 3 in -1
replace profile = scalar(ROWRem) in -1
label define `1' -1 "Resto del mundo", add

replace to = 101 in -2
replace profile = scalar(ROWTrans) in -2
label define to 101 "Remesas", add

* Compras Netas *
if scalar(ComprasN) < 0 {
	set obs `=_N+1'
	replace from = -1 if from == .
	replace to = 102 in -1
	replace profile = -scalar(ComprasN) in -1
	label define to 102 "Turistas y extranjeros", add
}

* Eje */
tempfile eje1
save `eje1'



********************
** Eje 4: Consumo **
use `"`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta"', clear
collapse (sum) gas_pc* gasto_anual* gasto_anualAhorro=Ahorro [fw=factor], by(`1')
egen gasto_Alimentos = rsum(gas_pc_Agua gas_pc_Alim gas_pc_BebN)
egen gasto_Vestido = rsum(gas_pc_Vest gas_pc_Calz)
egen gasto__Salud = rsum(gas_pc_Salu)
egen gasto___Educación = rsum(gas_pc_Educ gas_pc_Recr)
egen gasto___Vivienda = rsum(gas_pc_Alqu gas_pc_Hoga gas_pc_Comu gas_pc_Elec)
egen gasto___Transporte = rsum(gas_pc_Vehi gas_pc_STra gas_pc_FTra)
egen gasto____Otros_gastos = rsum(gas_pc_Taba gas_pc_BebA gas_pc_Dive gas_pc_Rest)
*egen gasto_____Consumo_gobierno = rsum(gasto_anualGobierno)
egen gasto_____Depreciación_capital = rsum(gasto_anualDepreciacion)
*egen gasto____Ahorro = rsum(gasto_anualAhorro)
drop gasto_anual*

levelsof `1', local(`1')
foreach k of local `1' {
	local oldlabel : label (`1') `k'
	label define `1' `k' "_`oldlabel'", modify
}

* from */
tempvar from
reshape long gasto_, i(`1') j(`from') string
rename gasto_ profile
encode `from', g(from)

* to *
rename `1' to

* Sector Publico *
set obs `=_N+3'
replace to = -1 if from == .
label define `1' -1 "Bienes_públicos", add

replace profile = scalar(SerEGob) in -1
replace from = 4 in -1

replace profile = scalar(SaluGob) in -2
replace from = 3 in -2

replace profile = scalar(ConGob) - scalar(SerEGob) - scalar(SaluGob) in -3
replace from = 7 in -3

* Ahorro *
set obs `=_N+1'
drop if from == 98
replace from = 98 in -1
replace to = -2 in -1 
replace profile = scalar(AhorroN) in -1
label define `1' -2 "__Futuro", add
label define from 98 "Ahorro", add

* ROW *
set obs `=_N+1'
replace to = -3 if from == .
label define `1' -3 "__Resto del mundo", add
replace from = 99 in -1
replace profile = -scalar(ROWProp) in -1
label define from 99 "__Ing a la propiedad", add


/* Depreciacion *
replace to = -4 if from == 9
label define `1' -4 "__Depreciacion", add

* Eje */
tempfile eje4
save `eje4'



********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "Ing disponible"
label values to PIB

tempfile eje2
save `eje2'



********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "Ing disponible"
label values from PIB

tempfile eje3
save `eje3'



************
** Sankey **
noisily SankeySumSim, anio(`2') name(`1') folder(`3') a(`eje1') b(`eje2') c(`eje3') d(`eje4') 

timer off 7
timer list 7
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t7)/r(nt7)',.1) in g " segs."

