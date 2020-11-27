**************
*** SANKEY ***
**************
if "`1'" == "" {
	local 1 = "decil"
	local 2 = 2018
}

if "$pais" != "" {
	exit
}
timer on 7



****************
** 0 Economia **
SCN, anio(`2') nographs
LIF, anio(`2') nographs
local CuotasIMSS = r(Cuotas_IMSS)
local IMSSpropio = r(IMSS)-`CuotasIMSS'
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP__Derechos_petroleros)
local Mejoras = r(Contribuciones_de_mejoras)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)



**********************************/
** Eje 1: Generación del ingreso **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

g ing_Sector_Publico = ing_cap_imss + ing_cap_issste + ing_cap_cfe + ing_cap_pemex ///
	+ ing_cap_fmp + ing_cap_mejoras + ing_cap_derechos + ing_cap_productos + ing_cap_aprovecha ///
	+ ing_cap_otrostrib + ing_cap_otrasempr
replace Yk = Yk - ing_estim_alqu //- ing_Sector_Publico
collapse (sum) ing_Ing_Laboral=Yl ing_Ing_Capital=Yk ing_Empresas_Publicas=ing_Sector_Publico ///
	ing_Alquiler_imputado=ing_estim_alqu ing_Remesas=ing_remesas [fw=factor_cola], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* Compras Netas *
if scalar(ComprasN) < 0 {
	set obs `=_N+1'
	replace from = -1 if from == .
	replace to = -2 in -1
	replace profile = -scalar(ComprasN) in -1
	label define to -2 "__Compras por extranjeros", add
}
label define `1' -1 "Resto del mundo", add

rename to to2
rename from to
rename to2 from

* Eje */
tempfile eje1
save `eje1'



********************
** Eje 4: Consumo **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

collapse (sum) gasto_anual* gasto_anualAhorro=Ahorro [fw=factor_cola], by(`1')

egen gasto_Alimentos = rsum(gasto_anual1-gasto_anual3)
egen gasto_Vestido = rsum(gasto_anual5-gasto_anual6)
egen gasto__Salud = rsum(gasto_anual11)
egen gasto___Educacion_y_Recreacion = rsum(gasto_anual16-gasto_anual18)
egen gasto___Vivienda = rsum(gasto_anual7-gasto_anual10)
egen gasto___Transporte_y_Comunica = rsum(gasto_anual12-gasto_anual15)
egen gasto____Otros_gastos = rsum(gasto_anual4 gasto_anual19)
egen gasto_____Consumo_gobierno = rsum(gasto_anualGobierno)
egen gasto_____Consumo_capital = rsum(gasto_anualDepreciacion)
*egen gasto____Ahorro = rsum(gasto_anualAhorro)
drop gasto_anual*

* from *
tempvar from
reshape long gasto_, i(`1') j(`from') string
rename gasto_ profile
encode `from', g(from)

* to *
rename `1' to

* ROW *
set obs `=_N+1'
replace to = -3 if from == .
label define `1' -3 "Resto del mundo", add

replace from = 99 in -1
replace profile = scalar(ROWTrans) in -1
label define from 99 "__Ing a la propiedad", add

rename to to2
rename from to
rename to2 from

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

rename to to2
rename from to
rename to2 from

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
noisily SankeySum, anio(`2') name(`1') folder(SankeySIMC) a(`eje4') b(`eje1') //c(`eje3') d(`eje4')

timer off 7
timer list 7
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t7)/r(nt7)',.1) in g " segs."

