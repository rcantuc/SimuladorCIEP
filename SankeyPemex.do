********************************
***                          ***
*** LINGO, Sankey's de Pemex ***
***                          ***
********************************
clear all
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"
cd "`c(sysdir_site)'"


*************************
***                   ***
*** 1. Bases de datos ***
***                   ***
*************************
*local 1 "update"
if "`1'" == "update" {
	** 1.1. Ventas netas de bienes y servicios **
	DatosAbiertos XKC0106, nog
	rename monto Ventas
	keep anio Ventas
	save "03_temp/XKC0106.dta", replace

	** 1.2. Otros ingresos **
	DatosAbiertos XKC0179, nog
	rename monto OtrosIngresos
	keep anio OtrosIngresos
	save "03_temp/XKC0179.dta", replace

	** 2.1. Derechos y enteros **
	DatosAbiertos XKC0113, nog
	rename monto Derechos
	keep anio Derechos
	save "03_temp/XKC0113.dta", replace

	** 2.2. Gasto programable **
	DatosAbiertos XKC0131, nog
	rename monto Programable
	keep anio Programable
	save "03_temp/XKC0131.dta", replace

	** 2.2.1 Pensiones y jubilaciones **
	DatosAbiertos XKC0139, nog
	rename monto Pensiones
	keep anio Pensiones
	save "03_temp/XKC0139.dta", replace

	** 2.2.2. Gastos de inversión **
	DatosAbiertos XKC0145, nog
	rename monto Inversion
	keep anio Inversion
	save "03_temp/XKC0145.dta", replace

	** 2.3. Gasto no programable **
	DatosAbiertos XKC0157, nog
	rename monto NoProgramable
	keep anio NoProgramable
	save "03_temp/XKC0157.dta", replace
}


** 1.2. Información adicional **
forvalues anio = 2019(1)2025 {
	if "`anio'" == "2019" {
		local apoyospatrimoniales = 122131*1000000
		local fmp = 410158961425
		local fmp_feip_feief = 3.42
		local fmp_feh = 1.05
		local fmp_investigacion = 0.78
		local fmp_tesofe = 94.75
	}
	if "`anio'" == "2020" {
		local apoyospatrimoniales = 46256*1000000
		local fmp = 187271584137
		local fmp_feip_feief = 5.91
		local fmp_feh = 1.79
		local fmp_investigacion = 1.35
		local fmp_tesofe = 90.95
	}
	if "`anio'" == "2021" {
		local apoyospatrimoniales = 316354*1000000
		local fmp = 383922663710
		local fmp_feip_feief = 2.67
		local fmp_feh = 0.83
		local fmp_investigacion = 0.61
		local fmp_tesofe = 95.89
	}
	if "`anio'" == "2022" {
		local apoyospatrimoniales = 188306*1000000
		local fmp = 529233592611
		local fmp_feip_feief = 1.66
		local fmp_feh = 0.51
		local fmp_investigacion = 0.38
		local fmp_tesofe = 97.45
	}
	if "`anio'" == "2023" {
		local apoyospatrimoniales = 166615122970
		local fmp = 255633786073
		local fmp_feip_feief = 4.05
		local fmp_feh = 1.24
		local fmp_investigacion = 0.93
		local fmp_tesofe = 93.78
	}
	if "`anio'" == "2024" {
		local apoyospatrimoniales = 170929000000 // TODO: Actualizar con datos más recientes
		local fmp = 41468323430/.2616
		local fmp_feip_feief = 4.05
		local fmp_feh = 1.24
		local fmp_investigacion = 0.93
		local fmp_tesofe = 93.78
	}
	if "`anio'" == "2025" {
		local apoyospatrimoniales = 0
		local fmp = 0
		local fmp_feip_feief = 0.00
		local fmp_feh = 0.00
		local fmp_investigacion = 0.00
		local fmp_tesofe = 0.00
	}
	


	***************************************
	***                                 ***
	*** Eje 1: Ingresos propios (PEMEX) ***
	***                                 ***
	***************************************
	use "03_temp/XKC0106.dta", clear
	append using "03_temp/XKC0179.dta"

	collapse (sum) Ing_Propios__Ventas=Ventas ///
		Ing_Propios_Otros_Ingresos=OtrosIngresos ///
		if anio == `anio', by(anio)

	** 1.2. Reshape para el Sankey **
	tempvar from to
	g `to' = "Pemex"
	reshape long Ing_Propios_, i(`to') j(`from') string

	encode `to', g(to)
	encode `from', g(from)

	rename Ing_Propios_ profile

	tabstat profile, s(sum) save
	local ingresosPemex = r(StatTotal)[1,1] 
	local ingresosPemex = `ingresosPemex' // + `apoyospatrimoniales'

	replace profile = profile / 1000000000
	tempfile eje`anio'1
	save `eje`anio'1'


	*********************************************************
	***                                                   ***
	*** Eje 2: Gastos operativos, financieros e impuestos ***
	***                                                   ***
	*********************************************************
	use "03_temp/XKC0113.dta", clear
	append using "03_temp/XKC0131.dta"
	append using "03_temp/XKC0157.dta"
	append using "03_temp/XKC0139.dta"
	append using "03_temp/XKC0145.dta"

	collapse (sum) Gastos_Derechos_y_Enteros=Derechos ///
		Gastos__Gastos_Operativos=Programable ///
		Gastos__Gastos_Financieros=NoProgramable ///
		Gastos__Pensiones=Pensiones ///
		Gastos__Inversión=Inversion ///
		if anio == `anio', by(anio)

	replace Gastos__Gastos_Operativos = Gastos__Gastos_Operativos - Gastos__Pensiones - Gastos__Inversión

	tabstat Gastos_Derechos, s(sum) save
	local gastosDerechos = r(StatTotal)[1,1]

	tempvar from to
	g `from' = "Pemex"
	reshape long Gastos_, i(`from') j(`to') string

	encode `to', g(to)
	encode `from', g(from)

	rename Gastos_ profile

	tabstat profile, s(sum) save
	local gastosPemex = r(StatTotal)[1,1]

	local balance = 0
	if `ingresosPemex' - `gastosPemex' > 0 {
		local balance = `ingresosPemex' - `gastosPemex'
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
	*** Eje 3: Aportaciones al gobierno federal y al FMP ***
	***                                                  ***
	********************************************************
	use `eje`anio'2', clear
	collapse (sum) profile if to == 1, by(to anio)
	rename to from 

	g to = 6
	label define to 6 "FMP", add
	label values to to

	tabstat profile, s(sum) save
	local DerechosEnteros = r(StatTotal)[1,1]

	replace profile = `fmp' / 1000000000

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 1 in -1
	replace to = 7 in -1
	label define to 7 "Federación", add
	replace profile = `DerechosEnteros' - (`fmp')/1000000000 in -1
	local impuestosExtrac_Explora = profile*1000000000 in -1
	local gastosDerechos = `gastosDerechos' - `impuestosExtrac_Explora'

	tempfile eje`anio'3
	save `eje`anio'3'


	********************************
	** Eje 4: Aportaciones del FMP **
	use `eje`anio'3', clear
	collapse (sum) profile if to == 6, by(to anio)
	rename to from 

	g to = 7
	label values to to

	tabstat profile, s(sum) save
	local profile = r(StatTotal)[1,1]
	replace profile = `profile' * `fmp_tesofe' / 100

	/*set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 6 in -1
	replace to = 101 in -1
	replace profile = `profile' * `fmp_feip_feief' / 100 in -1
	label define to 101 "Fondos", add

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 6 in -1
	replace to = 102 in -1
	replace profile = `profile' * `fmp_feh' / 100 in -1
	label define to 102 "Fondos", add

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 6 in -1
	replace to = 103 in -1
	replace profile = `profile' * `fmp_investigacion' / 100 in -1
	label define to 103 "Fondos", add*/

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 7 in -1
	replace to = 100 in -1
	replace profile = (`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimoniales' + `impuestosExtrac_Explora' + `balance')/1000000000 in -1
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
	** Eje 5: Aportaciones del gobierno federal **
	use `eje`anio'4', clear
	collapse (sum) profile if to == 7, by(to anio)
	rename to from

	replace profile = `apoyospatrimoniales' in -1
	replace profile = profile / 1000000000

	g to = 202
	label define to 202 "Otros_Ingresos", add
	label values to to

	tempfile eje`anio'5
	save `eje`anio'5'


	noisily SankeySumLoop, anio(`anio') name(`anio') folder(SankeyPemex) a(`eje`anio'1') b(`eje`anio'2') c(`eje`anio'3') d(`eje`anio'4') e(`eje`anio'5')
}

