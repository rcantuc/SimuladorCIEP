**************
*** SANKEY ***
**************
*local 1 = "decil"
*local 2 = 2018

if "$pais" != "" {
	exit
}


**************
** Economia **
SCN, anio(`2')


**********************************/
** Eje 1: Generación del ingreso **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

replace ing_capital = ing_capital + gasto_anualDepreciacion + ing_estim_alqu
collapse (sum) ing_Asalariados=ing_subor ing_Ingreso_mixto=ing_mixto ///
	ing_Ingresos_de_capital=ing_capital [fw=factor], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

/* Sector Publico *
set obs `=_N+1'
replace from = -3 in -1
label define `1' -3 "Sector_publico", add
replace profile = `IMSSpropio' + `ISSSTEpropio' + `CFEpropio' + ///
	`Pemexpropio' + `FMP' + `Mejoras' + `Derechos' + `Productos' + `Aprovechamientos' + ///
	`OtrosTributarios' + `OtrasEmpresas' in -1
replace to = 3 in -1

* ROW */
set obs `=_N+2'
replace from = -1 if from == .
label define `1' -1 "Resto del mundo", add

replace to = 1 in -2
replace profile = scalar(ROWRem) in -2

replace to = -1 in -1
replace profile = scalar(ROWTrans) in -1
label define to -1 "Remesas", add

tempfile eje1
save `eje1'


********************
** Eje 4: Consumo **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

g gasto_anualAhorro = ing_bruto_tot + ing_capitalROW + ing_suborROW + ing_remesas ///
	- TOTgasto_anual - gasto_anualDepreciacion - gasto_anualComprasN - gasto_anualGobierno

collapse (sum) gasto_anual* [fw=factor], by(`1')

egen gasto_Alimentos = rsum(gasto_anual1-gasto_anual4)
egen gasto_Vestido = rsum(gasto_anual5-gasto_anual6)
egen gasto_Vivienda = rsum(gasto_anual7-gasto_anual10)
egen gasto_Salud = rsum(gasto_anual11)
egen gasto_Transporte_y_Comunica = rsum(gasto_anual12-gasto_anual15)
egen gasto_Educacion_y_Recreacion = rsum(gasto_anual16-gasto_anual18)
egen gasto_Otros = rsum(gasto_anual19)
*egen gasto___Consumo_Gobierno = rsum(gasto_anualGobierno)
egen gasto__Depreciacion = rsum(gasto_anualDepreciacion)
*egen gasto____Ahorro = rsum(gasto_anualAhorro)
drop gasto_anual*

levelsof `1', local(`1')
foreach k of local `1' {
	local oldlabel : label (`1') `k'
	label define `1' `k' "_`oldlabel'", modify
}

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
label define `1' -3 "_Resto del mundo", add

replace from = 99 in -1
replace profile = scalar(ROWTrans) + scalar(ComprasN) in -1
label define from 99 "__Ingresos a la propiedad", add

* Sector Publico *
set obs `=_N+3'
replace to = -1 if from == .
label define `1' -1 "Gobierno", add

replace profile = scalar(SerEGob) in -1
replace from = 2 in -1

replace profile = scalar(SaluGob) in -2
replace from = 4 in -2

replace profile = scalar(ConGob) - scalar(SerEGob) - scalar(SaluGob) in -3
replace from = 3 in -3

* Ahorro *
set obs `=_N+1'
drop if from == 9
replace from = 9 in -1
replace to = -2 in -1 
replace profile = scalar(AhorroN) in -1
label define `1' -2 "__Futuro", add
label define from 9 "Ahorro", add

sort from to
tempfile eje4
save `eje4'


********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "Ingreso disponible"
label values to PIB

tempfile eje2
save `eje2'


********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "Ingreso disponible"
label values from PIB

tempfile eje3
save `eje3'


************
** Sankey **
noisily SankeySum, anio(2018) a(`eje1') b(`eje2') c(`eje3') d(`eje4') name(`1') folder(SankeySIM)
