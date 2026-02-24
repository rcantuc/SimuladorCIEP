**************
*** SANKEY ***
**************
if "`1'" == "" {
	clear programs
	local 1 = "decil"
	local 2 = 2024
	local 3 = "SankeyNTA"
	scalar anioenigh = 2024
}
if "`2'" >= "2022" {
	local 2 = 2024
}
timer on 7
noisily di _newline(2) in g "{bf: Sankey}: " in y "`1' `2'"



****************
** 0 Economia **
SCN, anio(`2') nographs



****************
** 1 Ingresos **
LIF, anio(`2') nographs min(0) by(divCIEP)
local CuotasIMSS = real(subinstr(scalar(Cuotas_IMSS),",","",.))
local IMSSpropio = real(subinstr(scalar(IMSS),",","",.)) //-`CuotasIMSS'
local ISSSTEpropio = real(subinstr(scalar(ISSSTE),",","",.))
local CFEpropio = real(subinstr(scalar(CFE),",","",.))
local Pemexpropio = real(subinstr(scalar(Pemex),",","",.))
local FMP = real(subinstr(scalar(FMP_Derechos),",","",.))
local Mejoras = real(subinstr(scalar(Contrib_de_mejora),",","",.))
local Derechos = real(subinstr(scalar(Derechos),",","",.))
local Productos = real(subinstr(scalar(Productos),",","",.))
local Aprovechamientos = real(subinstr(scalar(Aprovechamientos),",","",.))
local OtrosTributarios = real(subinstr(scalar(Otros_tributarios),",","",.))
local OtrasEmpresas = real(subinstr(scalar(Otras_empresas),",","",.))



**********************************/
** Eje 1: Generación del ingreso **
use `"`c(sysdir_site)'/04_master/`2'/households.dta"', clear

noisily tabstat Yl Yk ing_estim_alqu [fw=factor], stat(sum) format(%20.0fc) by(`1')

replace Yk = Yk - ing_estim_alqu
collapse (sum) ing_Ing_Laboral=Yl ing_Ing_Capital=Yk ing_Alquiler_propio=ing_estim_alqu [fw=factor], by(`1')

noisily tabstat ing_Ing_Laboral ing_Ing_Capital ing_Alquiler_propio, stat(sum) format(%20.0fc) by(`1')

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
label define `1' -2 "OyE_públicas", add
replace to = 2 in -1

* ROW *
set obs `=_N+2'
replace from = -1 if from == .
replace to = 3 in -1
replace profile = real(subinstr(scalar(ROWRem),",","",.))*1000000 in -1
label define `1' -1 "El mundo", add

replace to = 101 in -2
replace profile = real(subinstr(scalar(ROWTrans),",","",.))*1000000 in -2
label define to 101 "Remesas", add

* Compras Netas *
if real(subinstr(scalar(ComprasN),",","",.)) < 0 {
	set obs `=_N+1'
	replace from = -1 if from == .
	replace to = 102 in -1
	replace profile = -real(subinstr(scalar(ComprasN),",","",.))*1000000 in -1
	label define to 102 "Turistas extranjeros", add
}

* Eje */
tempfile eje1
save `eje1'



********************
** Eje 4: Consumo **
use `"`c(sysdir_site)'/04_master/`2'/households.dta"', clear
collapse (sum) gas_pc* gasto_anual* gasto_anualAhorro=Ahorro [fw=factor], by(`1')
egen gasto_Alimentos = rsum(gas_pc_Agua gas_pc_Alim gas_pc_BebN)
egen gasto_Vestido = rsum(gas_pc_Vest gas_pc_Calz)
egen gasto__Salud = rsum(gas_pc_Salu)
egen gasto___Educación = rsum(gas_pc_Educ gas_pc_Recr)
egen gasto___Vivienda = rsum(gas_pc_Alqu gas_pc_Hoga gas_pc_Comu gas_pc_Elec)
egen gasto___Transporte = rsum(gas_pc_Vehi gas_pc_STra gas_pc_FTra)
egen gasto____Otros_gastos = rsum(gas_pc_Taba gas_pc_BebA gas_pc_Dive gas_pc_Rest)
*egen gasto_____Consumo_gobierno = rsum(gasto_anualGobierno)
egen gasto_____Depreciación = rsum(gasto_anualDepreciacion)
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

replace profile = real(subinstr(scalar(SerEGob),",","",.))*1000000 in -1
replace from = 4 in -1

replace profile = real(subinstr(scalar(SaluGob),",","",.))*1000000 in -2
replace from = 3 in -2

replace profile = real(subinstr(scalar(ConGob),",","",.))*1000000 - real(subinstr(scalar(SerEGob),",","",.))*1000000 - real(subinstr(scalar(SaluGob),",","",.))*1000000 in -3
replace from = 7 in -3

* Ahorro *
set obs `=_N+1'
drop if from == 98
replace from = 98 in -1
replace to = -2 in -1 
replace profile = real(subinstr(scalar(AhorroN),",","",.))*1000000 in -1
label define `1' -2 "_Futuro", add
label define from 98 "Ahorro", add

* ROW *
set obs `=_N+1'
replace to = -3 if from == .
label define `1' -3 "__El mundo", add
replace from = 99 in -1
replace profile = -real(subinstr(scalar(ROWProp),",","",.))*1000000 in -1
label define from 99 "_Ing a la propiedad", add


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
label define PIB 999 "Ing nacional"
label values to PIB

tempfile eje2
save `eje2'



********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "Ing nacional"
label values from PIB

tempfile eje3
save `eje3'



************
** Sankey **
noisily SankeySumSim, anio(`2') name(`1') folder(`3') a(`eje1') b(`eje2') c(`eje3') d(`eje4') 

timer off 7
timer list 7
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t7)/r(nt7)',.1) in g " segs."

