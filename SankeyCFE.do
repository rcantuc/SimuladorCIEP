********************************
***                          ***
*** LINGO, Sankey's de CFE   ***
***                          ***
********************************
clear all
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"
cd "`c(sysdir_site)'"


*************************
***                   ***
*** 1. Bases de datos ***
***                   ***
*************************
*local 1 "update"
if "`1'" == "update" {
	** 1.1. Ventas netas de bienes y servicios **
	DatosAbiertos XKD0106, nog
	rename monto Ventas
	keep anio Ventas
	save "03_temp/XKD0106.dta", replace

	** 1.2. Otros ingresos **
	DatosAbiertos XKD0179, nog
	rename monto OtrosIngresos
	keep anio OtrosIngresos
	save "03_temp/XKD0179.dta", replace

	** 1.3. Subsidios **
	DatosAbiertos XKD0122, nog
	rename monto Subsidios
	keep anio Subsidios
	save "03_temp/XKD0122.dta", replace

	** 2.1. Transferencias al gobierno federal **
	DatosAbiertos XKD0113, nog
	rename monto Transferencias
	keep anio Transferencias
	save "03_temp/XKD0113.dta", replace

	** 2.2. Gasto programable **
	DatosAbiertos XKD0131, nog
	rename monto Programable
	keep anio Programable
	save "03_temp/XKD0131.dta", replace

	** 2.2.1 Pensiones y jubilaciones **
	DatosAbiertos XKD0139, nog
	rename monto Pensiones
	keep anio Pensiones
	save "03_temp/XKD0139.dta", replace

	** 2.2.2. Gastos de inversión **
	DatosAbiertos XKD0145, nog
	rename monto Inversion
	keep anio Inversion
	save "03_temp/XKD0145.dta", replace

	** 2.3. Gasto no programable **
	DatosAbiertos XKD0157, nog
	rename monto NoProgramable
	keep anio NoProgramable
	save "03_temp/XKD0157.dta", replace
}


** 1.2. Información adicional **
forvalues anio = 2019(1)2025 {

	************************************
	***                              ***
	*** Eje 1: Ingresos propios (CFE) ***
	***                              ***
	************************************
	use "03_temp/XKD0106.dta", clear
	append using "03_temp/XKD0179.dta"
	append using "03_temp/XKD0122.dta"

	collapse (sum) Ing_Propios__Ventas=Ventas ///
		Ing_Propios_Otros_Ingresos=OtrosIngresos ///
		Ing_Propios_Subsidios=Subsidios ///
		if anio == `anio', by(anio)

	tabstat Ing_Propios_Subsidios if anio == `anio', s(sum) save
	local subsidios = r(StatTotal)[1,1] 

	** 1.2. Reshape para el Sankey **
	tempvar from to
	g `to' = "CFE"
	reshape long Ing_Propios_, i(`to') j(`from') string

	encode `to', g(to)
	encode `from', g(from)

	rename Ing_Propios_ profile

	tabstat profile, s(sum) save
	local ingresosCFE = r(StatTotal)[1,1] 

	replace profile = profile / 1000000000
	tempfile eje`anio'1
	save `eje`anio'1'


	*********************************************************
	***                                                   ***
	*** Eje 2: Gastos operativos, financieros e impuestos ***
	***                                                   ***
	*********************************************************
	use "03_temp/XKD0113.dta", clear
	append using "03_temp/XKD0131.dta"
	append using "03_temp/XKD0157.dta"
	append using "03_temp/XKD0139.dta"
	append using "03_temp/XKD0145.dta"

	collapse (sum) Gastos_Transferencias=Transferencias ///
		Gastos__Gastos_Operativos=Programable ///
		Gastos__Gastos_Financieros=NoProgramable ///
		Gastos__Pensiones=Pensiones ///
		Gastos__Inversión=Inversion ///
		if anio == `anio', by(anio)

	replace Gastos__Gastos_Operativos = Gastos__Gastos_Operativos - Gastos__Pensiones - Gastos__Inversión

	tabstat Gastos_Transferencias, s(sum) save
	local gastosTransferencias = r(StatTotal)[1,1]

	tempvar from to
	g `from' = "CFE"
	reshape long Gastos_, i(`from') j(`to') string

	encode `to', g(to)
	encode `from', g(from)

	rename Gastos_ profile

	tabstat profile, s(sum) save
	local gastosCFE = r(StatTotal)[1,1]

	local balance = 0
	if `ingresosCFE' - `gastosCFE' > 0 {
		local balance = `ingresosCFE' - `gastosCFE'
	}

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 1 in -1
	replace to = 203 in -1
	replace profile = `balance' in -1
	label define to 203 "__BALANCE FINANCIERO", add

	replace profile = profile / 1000000000
	tempfile eje`anio'2
	save `eje`anio'2'


	********************************************************
	***                                                  ***
	*** Eje 3: Aportaciones al gobierno federal          ***
	***                                                  ***
	********************************************************
	use `eje`anio'2', clear
	collapse (sum) profile if to == 1, by(to anio)
	rename to from 

	g to = 7
	label define to 7 "Federación", add
	label values to to

	tabstat profile, s(sum) save
	local TransferenciasEnteros = r(StatTotal)[1,1]

	tempfile eje`anio'3
	save `eje`anio'3'


	********************************
	** Eje 4: Balance Fiscal **
	use `eje`anio'3', clear

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 7 in -1
	replace to = 100 in -1
	replace profile = (`gastosTransferencias' + `balance' - `subsidios')/1000000000 in -1
	label define to 100 "BALANCE FISCAL", add

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 203 in -1
	replace to = 7 in -1
	replace profile = `balance' / 1000000000 in -1

	label values to to
	tempfile eje`anio'4
	save `eje`anio'4'


	**********************************************
	** Eje 5: Subsidios del gobierno federal **
	use `eje`anio'4', clear
	collapse (sum) profile if to == 7, by(to anio)
	rename to from

	replace profile = `subsidios' in -1
	replace profile = profile / 1000000000

	g to = 201
	label define to 201 "Subsidios", add
	label values to to

	tempfile eje`anio'5
	save `eje`anio'5'


	noisily SankeySumLoop, anio(`anio') name(`anio') folder(SankeyCFE) a(`eje`anio'1') b(`eje`anio'2') c(`eje`anio'3') d(`eje`anio'4') e(`eje`anio'5')
}


