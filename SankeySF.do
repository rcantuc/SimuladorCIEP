**************
*** SANKEY ***
**************
local 1 = "decil"
local 2 = 2018

if "$pais" != "" {
	exit
}


********************
** Sistema Fiscal **
LIF, anio(`2')
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

collapse (sum) ing_Ingreso=Ingreso ing_Consumo=Consumo ing_Otros=Otros [fw=factor], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

tempfile eje1
save `eje1'


********************
** Eje 4: Consumo **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

collapse (sum) gas_Pension=Pension gas_Educacion=Educacion gas_Salud=Salud ///
	gas_PenBienestar=PenBienestar gas_OtrosGas=OtrosGas [fw=factor], by(`1')

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

sort from to
tempfile eje4
save `eje4'


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
noisily SankeySum, anio(2018) name(`1') folder(SankeySF) a(`eje1') b(`eje2') c(`eje3') d(`eje4') 
