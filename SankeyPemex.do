********************************
***                          ***
*** LINGO, Sankey's de Pemex ***
***                          ***
********************************
clear all
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"
if "`c(username)'" == "servidorciep" & "`c(console)'" == "" ///       // Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
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

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname Ventas_pib
	matrix `Ventas_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname Ventas_pib2013
	matrix `Ventas_pib2013' = r(StatTotal)

	keep anio Ventas
	save "03_temp/XKC0106.dta", replace

	** 1.2. Otros ingresos **
	DatosAbiertos XKC0179, nog
	rename monto OtrosIngresos

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname OtrosIngresos_pib
	matrix `OtrosIngresos_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname OtrosIngresos_pib2013
	matrix `OtrosIngresos_pib2013' = r(StatTotal)

	keep anio OtrosIngresos
	save "03_temp/XKC0179.dta", replace

	** 2.1. Derechos y enteros **
	DatosAbiertos XKC0113, nog
	rename monto Derechos

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname Derechos_pib
	matrix `Derechos_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname Derechos_pib2013
	matrix `Derechos_pib2013' = r(StatTotal)

	keep anio Derechos
	save "03_temp/XKC0113.dta", replace

	** 2.2. Gasto programable **
	DatosAbiertos XKC0131, nog
	rename monto Programable

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname Programable_pib
	matrix `Programable_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname Programable_pib2013
	matrix `Programable_pib2013' = r(StatTotal)

	keep anio Programable
	save "03_temp/XKC0131.dta", replace

	** 2.2.1 Pensiones y jubilaciones **
	DatosAbiertos XKC0139, nog
	rename monto Pensiones

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname Pensiones_pib
	matrix `Pensiones_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname Pensiones_pib2013
	matrix `Pensiones_pib2013' = r(StatTotal)

	keep anio Pensiones
	save "03_temp/XKC0139.dta", replace

	** 2.2.2. Gastos de inversión **
	DatosAbiertos XKC0145, nog
	rename monto Inversion

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname Inversion_pib
	matrix `Inversion_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname Inversion_pib2013
	matrix `Inversion_pib2013' = r(StatTotal)

	keep anio Inversion
	save "03_temp/XKC0145.dta", replace

	** 2.3. Gasto no programable **
	DatosAbiertos XKC0157, nog
	rename monto NoProgramable

	tabstat monto_pib if anio >= 2019 & anio < 2024, save
	tempname NoProgramable_pib
	matrix `NoProgramable_pib' = r(StatTotal)

	tabstat monto_pib if anio >= 2013 & anio < 2019, save
	tempname NoProgramable_pib2013
	matrix `NoProgramable_pib2013' = r(StatTotal)

	keep anio NoProgramable
	save "03_temp/XKC0157.dta", replace
}


** 1.2. Información adicional **
forvalues anio = 2019(1)2025 {
	if "`anio'" == "2019" {
		local reduccionduc = 0
		local estimulosfiscales = (25787+38704)*1000000
		local apoyospatrimoniales = 122131*1000000
		local indirectos = 443943085740*0
		local fmp = 410158961425
		local fmp_feip_feief = 3.42
		local fmp_feh = 1.05
		local fmp_investigacion = 0.78
		local fmp_tesofe = 94.75
		local fmp_otros = 0.00
	}
	if "`anio'" == "2020" {
		local reduccionduc = 26500*1000000
		local estimulosfiscales = (65000+5800)*1000000
		local apoyospatrimoniales = 46256*1000000
		local indirectos = 399325085921*0
		local fmp = 187271584137
		local fmp_feip_feief = 5.91
		local fmp_feh = 1.79
		local fmp_investigacion = 1.35
		local fmp_tesofe = 90.95
		local fmp_otros = 0.00
	}
	if "`anio'" == "2021" {
		local reduccionduc = 77900*1000000
		local estimulosfiscales = (73280+22915)*1000000
		local apoyospatrimoniales = 316354*1000000
		local indirectos = 357608812555*0
		local fmp = 383922663710
		local fmp_feip_feief = 2.67
		local fmp_feh = 0.83
		local fmp_investigacion = 0.61
		local fmp_tesofe = 95.89
		local fmp_otros = 0.00
	}
	if "`anio'" == "2022" {
		local reduccionduc = 238100*1000000
		local estimulosfiscales = (7455+23000)*1000000
		local apoyospatrimoniales = 188306*1000000
		local indirectos = 299434678260*0
		local fmp = 529233592611
		local fmp_feip_feief = 1.66
		local fmp_feh = 0.51
		local fmp_investigacion = 0.38
		local fmp_tesofe = 97.45
		local fmp_otros = 0.00
	}
	if "`anio'" == "2023" {
		local reduccionduc = 157500000000
		local estimulosfiscales = 86640000000
		local apoyospatrimoniales = 166615122970
		local indirectos = 416875393557*0
		local fmp = 255633786073
		local fmp_feip_feief = 4.05
		local fmp_feh = 1.24
		local fmp_investigacion = 0.93
		local fmp_tesofe = 93.78
		local fmp_otros = 0.00
	}
	if "`anio'" == "2024" {
		local reduccionduc = 178735000000
		local estimulosfiscales = 0
		local apoyospatrimoniales = 170929000000
		local indirectos = 416875393557*0 // <-- Falta actualizar
		local fmp = 41468323430/.2616  // 344478000000 <-- Falta actualizar
		local fmp_feip_feief = 4.05
		local fmp_feh = 1.24
		local fmp_investigacion = 0.93
		local fmp_tesofe = 93.78
		local fmp_otros = 0.00
	}
	if "`anio'" == "2025" {
		local reduccionduc = 0
		local estimulosfiscales = 0
		local apoyospatrimoniales = 0
		local indirectos = 0
		local fmp = 0
		local fmp_feip_feief = 0.00
		local fmp_feh = 0.00
		local fmp_investigacion = 0.00
		local fmp_tesofe = 0.00
		local fmp_otros = 0.00
	}
	if "`anio'" == "2026" {
		local reduccionduc = 0
		local estimulosfiscales = 0
		local apoyospatrimoniales = 0
		local indirectos = 0
		local fmp = 0
		local fmp_feip_feief = 0.00
		local fmp_feh = 0.00
		local fmp_investigacion = 0.00
		local fmp_tesofe = 0.00
		local fmp_otros = 0.00
	}
	


	***************************************
	***                                 ***
	*** Eje 1: Ingresos propios (PEMEX) ***
	***                                 ***
	***************************************

	** 1.1. Ingresos propios **
	use "03_temp/XKC0106.dta", clear
	append using "03_temp/XKC0179.dta"

	collapse (sum) Ing_Propios_Ventas=Ventas ///
		Ing_Propios_Otros_Ingresos=OtrosIngresos ///
		if anio == `anio', by(anio)

	replace Ing_Propios_Ventas = Ing_Propios_Ventas + `indirectos'
	replace Ing_Propios_Otros_Ingresos = Ing_Propios_Otros_Ingresos - `apoyospatrimoniales'

	** 1.2. Reshape para el Sankey **
	tempvar from to
	g `to' = "Pemex"
	reshape long Ing_Propios_, i(`to') j(`from') string

	encode `to', g(to)
	encode `from', g(from)

	rename Ing_Propios_ profile

	tabstat profile, s(sum) save
	local ingresosPemex = r(StatTotal)[1,1] 
	local ingresosPemex = `ingresosPemex' + `reduccionduc' + `estimulosfiscales' + `apoyospatrimoniales'

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace profile = `indirectos' in -1
	replace to = 98 in -1
	replace from = 2 in -1
	label define to 98 "Imp Indirectos", add

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
		Gastos_Gastos_Operativos=Programable ///
		Gastos_Gastos_Financieros=NoProgramable ///
		Gastos_Pensiones=Pensiones ///
		Gastos_Inversión=Inversion ///
		if anio == `anio', by(anio)

	replace Gastos_Gastos_Operativos = Gastos_Gastos_Operativos - Gastos_Pensiones - Gastos_Inversión

	replace Gastos_Derechos = Gastos_Derechos + `reduccionduc' 		// Reducción DUC
	replace Gastos_Derechos = Gastos_Derechos + `estimulosfiscales' // Estímulos fiscales
	replace Gastos_Derechos = Gastos_Derechos + `indirectos'*0		// IEPS e IVA

	tabstat Gastos_Derechos, s(sum) save
	local gastosDerechos = r(StatTotal)[1,1] - `reduccionduc' - `estimulosfiscales' //+ `indirectos'

	tempvar from to
	g `from' = "Pemex"
	reshape long Gastos_, i(`from') j(`to') string

	encode `to', g(to)
	encode `from', g(from)

	rename Gastos_ profile

	tabstat profile, s(sum) save
	local gastosPemex = r(StatTotal)[1,1]

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
	label define to 7 "Gobierno Federal", add
	replace profile = `DerechosEnteros' - (`fmp' + `reduccionduc' + `estimulosfiscales')/1000000000 in -1
	local impuestosExtrac_Explora = profile*1000000000 in -1
	local gastosDerechos = `gastosDerechos' - `impuestosExtrac_Explora'

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 1 in -1
	replace to = 8 in -1
	replace profile = (`reduccionduc' + `estimulosfiscales')/1000000000 in -1
	label define to 8 "Pemex", add

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 200 in -1
	replace to = 7 in -1
	replace profile = `indirectos' / 1000000000 in -1
	label define to 200 "Imp Indirectos", add

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

	set obs `=_N+1'
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
	label define to 103 "Fondos", add

	set obs `=_N+1'
	replace anio = `anio' in -1
	replace from = 6 in -1
	replace to = 104 in -1
	replace profile = `profile' * `fmp_otros' / 100 in -1
	label define to 104 "Otros", add

	local deficit = 0
	if `ingresosPemex' - `gastosPemex' < 0 {
		local deficit = -(`ingresosPemex' - `gastosPemex')*0
	}
	label define to 201 "Pemex", add

	*if (`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimoniales' - `deficit' + `impuestosExtrac_Explora') > 0 {
		set obs `=_N+1'
		replace anio = `anio' in -1
		replace from = 7 in -1
		replace to = 100 in -1
		replace profile = (`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimoniales' - `deficit' + `impuestosExtrac_Explora' + `indirectos')/1000000000 in -1
		label define to 100 "Aportación neta", add
	/*}
	else {
		set obs `=_N+1'
		replace anio = `anio' in -1
		replace from = 202 in -1
		replace to = 7 in -1
		replace profile = -(`gastosDerechos'*`fmp_tesofe'/100 - `apoyospatrimoniales' - `deficit' + `impuestosExtrac_Explora')/1000000000 in -1
		label define to 202 "Subsidio neto", add
	}*/

	label values to to
	tempfile eje`anio'4
	save `eje`anio'4'


	**********************************************
	** Eje 5: Aportaciones del gobierno federal **
	use `eje`anio'4', clear
	collapse (sum) profile if to == 7, by(to anio)
	rename to from

	replace profile = `apoyospatrimoniales' + `deficit'				// Apoyos patrimoniales
	replace profile = profile / 1000000000

	g to = 201
	label values to to

	tempfile eje`anio'5
	save `eje`anio'5'


	noisily SankeySumLoop, anio(`anio') name(`anio') folder(SankeyPemex) a(`eje`anio'1') b(`eje`anio'2') c(`eje`anio'3') d(`eje`anio'4') e(`eje`anio'5')
}

