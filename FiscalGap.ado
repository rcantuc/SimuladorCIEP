program define FiscalGap
quietly {

	timer on 11
	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, NOGraphs Anio(int `aniovp') BOOTstrap(int 1) Update END(int 2100)]


	*************
	*** 1 PIB ***
	*************
	use "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
	local currency = currency[1]
	local discount = discount[1]
	local anio_last = 2020
	
	forvalues k = 1(1)`=_N' {
		if anio[`k'] == `anio_last' {
			local obs`anio_last' = `k'
			continue, break
		}
	}
	
	keep if anio <= `end'
	
	tempfile PIB
	save `PIB'


	****************
	*** 2 SHRFSP ***
	****************
	SHRFSP, anio(`anio') `nographs' //update
	tempfile shrfsp
	save `shrfsp'


	******************************
	*** 3 Fiscal Gap: Ingresos ***
	******************************
	/*if "$pais" == "" {
		capture confirm file "`c(sysdir_personal)'/SIM/XNA0120_m.dta"
		if _rc != 0 | "`update'" == "update" {
			DatosAbiertos XNA0120_m, pibvp(3.714)
			if `c(version)' > 13.1 {
				saveold "`c(sysdir_personal)'/SIM/XNA0120_m.dta", replace version(13)
			}
			else {
				save "`c(sysdir_personal)'/SIM/XNA0120_m.dta", replace
			}
		}
		use "`c(sysdir_personal)'/SIM/XNA0120_m.dta", clear
		g divGA = 3
		tempfile pm_ingreso
		save `pm_ingreso'
		
		replace divGA = 4
		tempfile pm_capital
		save `pm_capital'
	}*/
	
	LIF, anio(`anio') `nographs' by(divGA) //eofp
	collapse (sum) recaudacion if divLIF != 10, by(anio divGA) fast
	if "$pais" == "" {
		*merge 1:1 (anio divGA) using `pm_ingreso', nogen keepus(monto)
		*merge 1:1 (anio divGA) using `pm_capital', nogen keepus(monto) update
		*replace recaudacion = recaudacion - monto if divGA == 3 & monto != .
		*replace recaudacion = recaudacion + monto if divGA == 4 & monto != .
	}
	g modulo = ""

	levelsof divGA, local(divGA)
	foreach k of local divGA {
		local divGA`k' : label divGA `k'
		if "`divGA`k''" == "Impuestos al ingreso" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/LaboralREC.dta"', clear
			if _rc != 0 {
				 use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/LaboralREC.dta"', clear
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "alingreso"

			tempfile alingreso
			save `alingreso'

			restore
			merge 1:1 (anio divGA) using `alingreso', nogen update replace
		}
		if "`divGA`k''" == "Impuestos al consumo" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/ConsumoREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/ConsumoREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "alconsumo"

			tempfile alconsumo
			save `alconsumo'

			restore
			merge 1:1 (anio divGA) using `alconsumo', nogen update replace
		}
		if "`divGA`k''" == "Ingresos de capital" | "`divGA`k''" == "Otros ingresos" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/OtrosCREC"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/OtrosCREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "otrosing"

			tempfile otros
			save `otros'

			restore
			merge 1:1 (anio divGA) using `otros', nogen update replace
		}
	}

	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) recaudacion estimacion (max) pibYR deflator lambda, by(anio modulo)

	* Actualizaciones *
	replace estimacion = 0 if estimacion == .
	replace estimacion = estimacion*lambda
	replace recaudacion = 0 if recaudacion == .
	replace recaudacion = recaudacion/deflator

	* Reshape *
	reshape wide recaudacion estimacion, i(anio) j(modulo) string
	format recaudacion* estimacion* %20.0fc
	tsset anio

	/* Otros ingresos *
	g otrospib = recaudacionotros/pibYR*100
	replace otrospib = L.otrospib if anio > `anio'
	replace estimacionotros = L.otrospib/100*pibYR if anio > `anio'

	***************/
	** 3.1 Graphs **
	if "`nographs'" != "nographs" {
		tempvar consumo ingreso otros
		g `consumo' = (recaudacionalconsumo)/1000000000000
		g `ingreso' = (recaudacionalingreso + recaudacionalconsumo)/1000000000000
		g `otros' = (recaudacionotros + recaudacionalingreso + recaudacionalconsumo)/1000000000000

		tempvar consumo2 ingreso2 otros2
		g `consumo2' = (estimacionalconsumo)/1000000000000
		g `ingreso2' = (estimacionalingreso + estimacionalconsumo)/1000000000000
		g `otros2' = (estimacionotros + estimacionalingreso + estimacionalconsumo)/1000000000000

		twoway (area `otros' `ingreso' `consumo' anio if anio <= `anio' & anio >= 2003) ///
			(area `otros2' anio if anio > `anio', color("255 129 0")) ///
			(area `ingreso2' anio if anio > `anio', color("255 189 0")) ///
			(area `consumo2' anio if anio > `anio', color("39 97 47")), ///
			legend(cols(3) order(1 2 3) ///
			label(1 "Ingresos de capital") label(2 "Impuestos laborales") label(3 "Impuestos al consumo")) ///
			xlabel(2010(5)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`=`anio'+.5') ///
			text(`=`otros'[`obs`anio_last'']*.0618' `=`anio'+1.5' "Proyecci{c o'}n", place(ne) color(white)) ///
			yscale(range(0)) ///
			///title({bf:Proyecci{c o'}n} de los ingresos p{c u'}blicos) ///
			subtitle($pais) ///
			xtitle("") ytitle(mil millones `currency' `anio') ///
			///caption("{it:Fuente: Elaborado por el CIEP con el Simulador Fiscal CIEP v5.}") ///
			name(Proy_ingresos, replace)
		if "$export" != "" {
			graph export `"$export/Proy_ingresos.png"', replace name(Proy_ingresos)
		}
	}
	if "$output" == "output" {
		keep if anio >= 2010
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2010 & anio[`k'] < `anio' {
				local proy_consumo = "`proy_consumo' `=string(`=recaudacionalconsumo[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_consumo = "`proy_consumo' `=string(`=estimacionalconsumo[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= 2010 & anio[`k'] < `anio' {
				local proy_ingreso = "`proy_ingreso' `=string(`=recaudacionalingreso[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_ingreso = "`proy_ingreso' `=string(`=estimacionalingreso[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= 2010 & anio[`k'] < `anio' {
				local proy_otrosing = "`proy_otrosing' `=string(`=recaudacionotrosing[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_otrosing = "`proy_otrosing' `=string(`=estimacionotrosing[`k']/1000000000000',"%10.3f")',"
			}
		}
		local length_consumo = strlen("`proy_consumo'")
		local length_ingreso = strlen("`proy_ingreso'")
		local length_otrosing = strlen("`proy_otrosing'")
		capture log on output
		noisily di in w "PROYCON: [`=substr("`proy_consumo'",1,`=`length_consumo'-1')']"
		noisily di in w "PROYING: [`=substr("`proy_ingreso'",1,`=`length_ingreso'-1')']"
		noisily di in w "PROYOTRING: [`=substr("`proy_otrosing'",1,`=`length_otrosing'-1')']"
		capture log off output
	}
	

	*********************
	** 3.2 Al infinito **
	noisily di _newline(2) in g "{bf: FISCAL GAP:" in y " $pais `anio' }"

	reshape long recaudacion estimacion, i(anio) j(modulo) string
	collapse (sum) recaudacion estimacion (mean) pibYR deflator, by(anio) fast

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	g estimacionVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format estimacionVP %20.0fc
	local estimacionINF = estimacionVP[_N] /*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')*/ /(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat estimacionVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname estimacionVP
	matrix `estimacionVP' = r(StatTotal)

	noisily di in g "  (+) Ingresos INF en VP:" in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] in g " `currency'"	
	
	* Save *
	rename estimacion estimacioningresos
	tempfile baseingresos
	save `baseingresos'



	****************************
	*** 4 Fiscal Gap: Gastos ***
	****************************
	PEF if divGA != -1, anio(`anio') by(divGA) `nographs'
	capture confirm variable transf_gf
	if _rc != 0 {
		g transf_gf = 0
	}
	collapse (sum) gasto if transf_gf == 0, by(anio divGA) fast
	g modulo = ""

	levelsof divGA, local(divGA)
	foreach k of local divGA {
		local divGA`k' : label divGA `k'
		if "`divGA`k''" == "Educaci{c o'}n" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/EducacionREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/EducacionREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "educacion"

			tempfile educacion
			save `educacion'

			restore
			merge 1:1 (anio divGA) using `educacion', nogen update replace
		}
		if "`divGA`k''" == "Pensiones" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/PensionREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			if "$pais" == "El Salvador" {
				tempfile proypensiones
				save `proypensiones'
				
				import excel `"`c(sysdir_site)'/../basesCIEP/SIM/$pais/Pensiones.xlsx"', clear firstrow
				drop if anio == .
				capture drop PIB
				rename estimacion estimacionSIM
				format estimacion* %20.0fc

				merge 1:1 (anio) using `proypensiones', nogen
				replace estimacion = estimacionSIM
				drop estimacionSIM
			}

			g divGA = `k'
			replace modulo = "pensiones"

			tempfile pensiones
			save `pensiones'

			restore
			merge 1:1 (anio divGA) using `pensiones', nogen update replace
		}
		if "`divGA`k''" == "Salud" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/SaludREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/SaludREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "salud"

			tempfile salud
			save `salud'

			restore
			merge 1:1 (anio divGA) using `salud', nogen update replace
		}
		if "`divGA`k''" == "Costo de la deuda" {
			replace modulo = "costodeuda" if divGA == `k'
		}
		if "`divGA`k''" == "Amortizaci{c o'}n" {
			replace modulo = "amortizacion" if divGA == `k'
		}
		if "`divGA`k''" == "Pensi{c o'}n Bienestar" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/PenBienestarREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PenBienestarREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "penbienestar"

			tempfile penbienestar
			save `penbienestar'

			restore
			merge 1:1 (anio divGA) using `penbienestar', nogen update replace
		}
		if "`divGA`k''" == "Otros" {
			preserve

			capture use `"`c(sysdir_personal)'/users/$pais/$id/OtrosGasREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/OtrosGasREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divGA = `k'
			replace modulo = "otrosgas"

			tempfile otrosgas
			save `otrosgas'

			restore
			merge 1:1 (anio divGA) using `otrosgas', nogen update replace
		}
	}

	** Ingreso basico **
	preserve

	capture use `"`c(sysdir_personal)'/users/$pais/$id/IngBasicoREC"', clear
	if _rc != 0 {
		use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/IngBasicoREC.dta"', clear			
	}
	merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
	collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

	g divGA = 99
	replace modulo = "ingbasico"
	
	tempfile ingbasico
	save `ingbasico'

	restore
	merge 1:1 (anio divGA) using `ingbasico', nogen update replace

	* PIB *
	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) gasto estimacion (max) pibYR deflator lambda, by(anio modulo) fast
	
	*replace estimacion = pibYR*.04 if modulo == "pensiones"


	*********************
	** Actualizaciones **
	replace estimacion = 0 if estimacion == .
	replace estimacion = estimacion*lambda
	replace gasto = 0 if gasto == .
	replace gasto = gasto/deflator

	* Reshape *
	reshape wide gasto estimacion, i(anio) j(modulo) string
	format gasto* estimacion* %20.0fc
	tsset anio

	* Otros gastos *
	g otrospib = gastootros/pibYR*100
	replace otrospib = L.otrospib if otrospib == .
	replace estimacionotros = L.otrospib/100*pibYR if estimacionotros == .

	* Amortizacion */
	g amortizacionpib = gastoamortizacion/pibYR*100 if anio <= `anio'
	egen amortizacionprom = mean(amortizacionpib)
	replace amortizacionpib = amortizacionprom if amortizacionpib == .

	replace gastoamortizacion = amortizacionpib/100*pibYR if gastoamortizacion == .
	
	replace estimacionamortizacion = amortizacionpib/100*pibYR if estimacionamortizacion == .
	replace estimacionamortizacion = gastoamortizacion if anio >= `anio' //& estimacionamortizacion == 0



	***********
	** DEUDA **
	merge 1:1 (anio) using `shrfsp', nogen keepus(shrfsp* rfsp* /*nopresupuestario*/ tipoDeCambio) keep(matched)
	merge 1:1 (anio) using `baseingresos', nogen

	g difshrfsp = shrfsp-L.shrfsp
	g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	g shrfspExternoDep = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)

	tabstat shrfspExternoDep rfsp, stat(sum) f(%20.0fc) save
	tempname ACT
	matrix `ACT' = r(StatTotal)

	forvalues k=`=_N'(-1)1 {
		if shrfsp[`k'] != . & "`lastfound'" != "yes" {
			local obslast = `k'
			local lastfound = "yes"
		}
		if shrfsp[`k'] == . & "`lastfound'" == "yes" {
			local obsfirs = `k'+1
			continue, break
		}
	}
	if "`lastfound'" == "yes" & "`obsfirs'" == "" {
		local obsfirs = 1
	}
	local shrfspobslast = shrfsp[`obslast']/pibY[`obslast']*100

	* Actualizacion de los saldos *
	*g actualizacion = `actualizacion_geo'
	local actualizacion_geo = (((shrfsp[`obslast']-shrfsp[`obsfirs'])/(`ACT'[1,1]+`ACT'[1,2]))^(1/(`obslast'-`obsfirs'))-1)*100

	* MXN Reales *
	replace rfsp = rfsp/deflator
	replace shrfsp = shrfsp/deflator

	* Costo de la deuda *
	g costodeudashrfsp = gastocostodeuda/shrfsp*100 if anio <= `anio'
	egen costodeudashrfsp_ari = mean(costodeudashrfsp)
	replace costodeudashrfsp = costodeudashrfsp_ari if costodeudashrfsp == .

	replace estimacioncostodeuda = costodeudashrfsp/100*shrfsp if estimacioncostodeuda == . //anio == `anio'


	* Iteraciones *
	capture confirm variable estimacionpenbienestar
	if _rc != 0 {
		g estimacionpenbienestar = 0
		g gastopenbienestar = 0
	}
	capture confirm variable estimacioningbasico
	if _rc != 0 {
		g estimacioningbasico = 0
		g gastoingbasico = 0
	}

	forvalues k = `=`anio''(1)`=anio[_N]' {
		replace estimacioncostodeuda = costodeudashrfsp/100*L.shrfsp if anio == `k'
		*replace estimacioncostodeuda = 0 if estimacioncostodeuda < 0

		capture confirm variable rfspBalance
		if _rc != 0 {
			g rfspBalance = estimacionamortizacion + estimacioncostodeuda + estimacioneducacion ///
				+ estimacionsalud + estimacionpensiones + estimacionotrosgas + estimacioningbasico ///
				+ estimacionpenbienestar ///
				- estimacioningresos if anio == `k'
		}
		else {
			replace rfspBalance = estimacionamortizacion + estimacioncostodeuda + estimacioneducacion ///
				+ estimacionsalud + estimacionpensiones + estimacionotrosgas + estimacioningbasico ///
				+ estimacionpenbienestar ///
				- estimacioningresos if anio == `k'
		}
		replace rfsp = rfspBalance if anio == `k'

		replace shrfsp = L.shrfsp*(1+`actualizacion_geo'/100*0) + rfspBalance if anio == `k' //& shrfsp == .
	}

	g rfsp_pib = rfsp/pibYR*100

	egen estimaciongastos = rsum(estimacionamortizacion estimacioncostodeuda estimacioneducacion ///
			estimacionsalud estimacionpensiones estimacionotrosgas estimacioningbasico ///
			estimacionpenbienestar)
	format estimaciongastos %20.0fc


	****************
	** 4.1 Graphs **
	tempvar educaciong pensionesg saludg costog amortg otrosg ingbasg bienestarg
	g `educaciong' = (gastoeducacion)/1000000000000
	g `pensionesg' = (gastopensiones + gastoeducacion)/1000000000000
	g `saludg' = (gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `costog' = (gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `amortg' = (gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `otrosg' = (gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `bienestarg' = (gastopenbienestar + gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `ingbasg' = (gastoingbasico + gastopenbienestar + gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	
	tempvar educaciong2 pensionesg2 saludg2 costog2 amortg2 otrosg2 ingbasg2 bienestarg2
	g `educaciong2' = (estimacioneducacion)/1000000000000
	g `pensionesg2' = (estimacionpensiones + estimacioneducacion)/1000000000000
	g `saludg2' = (estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `costog2' = (estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `amortg2' = (estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `otrosg2' = (estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `bienestarg2' = (estimacionpenbienestar + estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `ingbasg2' = (estimacioningbasico + estimacionpenbienestar + estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000

	if "`nographs'" != "nographs" {
		twoway (area `ingbasg' `bienestarg' `otrosg' `amortg' `costog' `saludg' `pensionesg' `educaciong' anio if anio <= `anio' & anio > 2013) ///
			(area `ingbasg2' anio if anio > `anio', color("255 129 0")) ///
			(area `bienestarg2' anio if anio > `anio', color("255 189 0")) ///
			(area `otrosg2' anio if anio > `anio', color("39 97 47")) ///
			(area `amortg2' anio if anio > `anio', color("53 200 71")) ///
			(area `costog2' anio if anio > `anio', color("0 78 198")) ///
			(area `saludg2' anio if anio > `anio', color("0 151 201")) ///
			(area `pensionesg2' anio if anio > `anio', color("186 34 64")) ///
			(area `educaciong2' anio if anio > `anio', color("254 118 109")) if anio >= 2013, ///
			legend(cols(8) order(1 2 3 4 5 6 7 8) ///
			label(1 "Renta b{c a'}sica") ///
			label(2 "Pensi{c o'}n Bienestar") ///
			label(3 "Otros gastos") ///
			label(4 "Amortizaci{c o'}n") ///
			label(5 "Costo de la deuda") ///
			label(6 "Salud") ///
			label(7 "Pensiones") ///
			label(8 "Educaci{c o'}n")) ///
			xlabel(2015(5)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`=`anio'+.5') ///
			text(`=`otrosg'[`obs`anio_last'']*.0618' `=`anio'+1.5' "Proyecci{c o'}n", place(ne) color(white)) ///
			yscale(range(0)) ///
			///title({bf:Proyecci{c o'}n} del gasto p{c u'}blico) ///
			subtitle($pais) ///
			///caption("{it:Fuente: Elaborado por el CIEP con el Simulador Fiscal CIEP v5.}") ///
			xtitle("") ytitle(mil millones `currency' `anio') ///
			name(Proy_gastos, replace)
		if "$export" != "" {
			graph export `"$export/Proy_gastos.png"', replace name(Proy_gastos)
		}

		twoway (area rfsp_pib anio if anio <= `anio' & anio >= 2008) ///
			(area rfsp_pib anio if anio > `anio' & anio <= `end'), ///
			yscale(range(0)) ///
			ytitle(% PIB) ///
			xtitle("") ///
			xlabel(2015(5)`=round(anio[_N],10)') ///
			xline(`=`anio'+.5') ///
			legend(off) ///
			text(`=rfsp_pib[`obs`anio_last'']*.0618' `=`anio'+1.5' "Proyecci{c o'}n", color(white) placement(e)) ///
			///title({bf: Proyecci{c o'}n} de los RFSP) subtitle($pais) ///
			name(Proy_rfsp, replace)
	}
	if "$output" == "output" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_educa = "`proy_educa' `=string(`=gastoeducacion[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_educa = "`proy_educa' `=string(`=estimacioneducacion[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_pension = "`proy_pension' `=string(`=gastopensiones[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_pension = "`proy_pension' `=string(`=estimacionpensiones[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_salud = "`proy_salud' `=string(`=gastosalud[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_salud = "`proy_salud' `=string(`=estimacionsalud[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_costo = "`proy_costo' `=string(`=gastocostodeuda[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_costo = "`proy_costo' `=string(`=estimacioncostodeuda[`k']/1000000000000',"%10.3f")',"
			}				
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_amort = "`proy_amort' `=string(`=gastoamortizacion[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_amort = "`proy_amort' `=string(`=estimacionamortizacion[`k']/1000000000000',"%10.3f")',"
			}				
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_otrosg = "`proy_otrosg' `=string(`=gastootros[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_otrosg = "`proy_otrosg' `=string(`=estimacionotros[`k']/1000000000000',"%10.3f")',"
			}				
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_bienestar = "`proy_bienestar' `=string(`=gastopenbienestar[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_bienestar = "`proy_bienestar' `=string(`=estimacionpenbienestar[`k']/1000000000000',"%10.3f")',"
			}				
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_ingbas = "`proy_ingbas' `=string(`=gastoingbasico[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_ingbas = "`proy_ingbas' `=string(`=estimacioningbasico[`k']/1000000000000',"%10.3f")',"
			}
		}
		local length_educa = strlen("`proy_educa'")
		local length_pension = strlen("`proy_pension'")
		local length_salud = strlen("`proy_salud'")
		local length_costo = strlen("`proy_costo'")
		local length_amort = strlen("`proy_amort'")
		local length_otrosg = strlen("`proy_otrosg'")
		local length_bienestar = strlen("`proy_bienestar'")
		local length_ingbas = strlen("`proy_ingbas'")
		capture log on output
		noisily di in w "PROYEDUCA: [`=substr("`proy_educa'",1,`=`length_educa'-1')']"
		noisily di in w "PROYPENSION: [`=substr("`proy_pension'",1,`=`length_pension'-1')']"
		noisily di in w "PROYSALUD: [`=substr("`proy_salud'",1,`=`length_salud'-1')']"
		noisily di in w "PROYCOSTO: [`=substr("`proy_costo'",1,`=`length_costo'-1')']"
		noisily di in w "PROYAMORT: [`=substr("`proy_amort'",1,`=`length_amort'-1')']"
		noisily di in w "PROYOTROSG: [`=substr("`proy_otrosg'",1,`=`length_otrosg'-1')']"
		noisily di in w "PROYBIENESTAR: [`=substr("`proy_bienestar'",1,`=`length_bienestar'-1')']"
		noisily di in w "PROYINGBAS: [`=substr("`proy_ingbas'",1,`=`length_ingbas'-1')']"
		capture log off output	
	}

	*********************
	** 4.2 Al infinito **
	drop estimaciongasto
	reshape long gasto estimacion, i(anio) j(modulo) string
	collapse (sum) gasto estimacion (mean) pibYR deflator shrfsp rfsp ///
		if modulo != "ingresos" & modulo != "VP" & anio <= `end', by(anio) fast

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	g gastoVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format gastoVP %20.0fc
	local gastoINF = gastoVP[_N] /*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')*/ /(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat gastoVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname gastoVP
	matrix `gastoVP' = r(StatTotal)

	noisily di in g "  (-) Gastos INF en VP:" in y _col(35) %25.0fc `gastoINF'+`gastoVP'[1,1] in g " `currency'"	
	
	* Save *
	rename estimacion estimaciongastos
	tempfile basegastos
	save `basegastos'


	*****************************
	*** 5 Fiscal Gap: Balance ***
	*****************************
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Balance INF en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	

	* Saldo de la deuda *
	tabstat shrfsp if anio == `=`anio'-1', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)

	noisily di in g "  (+) Deuda (" in y `=`anio'-1' in g "):" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Financial wealth INF en VP:" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (/) Ingresos INF en VP:" ///
		in y _col(35) %25.1fc -(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`estimacionINF'+`estimacionVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (/) Gastos INF en VP:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`gastoINF'+`gastoVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (/) PIB INF en VP:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/scalar(pibVPINF)*100 ///
		in g " %"

	g shrfspPIB = shrfsp/pibY*100
	if "`nographs'" != "nographs" {
		twoway (area shrfspPIB anio if shrfspPIB != . & anio <= `anio' & anio >= 2000) ///
			(area shrfspPIB anio if anio > `anio' & anio <= `end'), ///
			///title({bf:Proyecci{c o'}n} del SHRFSP) ///
			subtitle($pais) ///
			///caption("{it:Fuente: Elaborado por el CIEP con el Simulador Fiscal CIEP v5.}") ///
			xtitle("") ytitle(% PIB) ///
			xlabel(2005(5)`end') ///
			yscale(range(0)) ///
			legend(off) ///
			text(`=shrfspPIB[`obs`anio_last'']*.0618' `=`anio'+1.5' "Proyecci{c o'}n", color(white) placement(e)) ///
			xline(`=`anio'+.5') ///
			name(Proy_shrfsp, replace)
		if "$export" != "" {
			graph export `"$export/Proy_shrfsp.png"', replace name(Proy_shrfsp)
		}
	}
	if "$output" == "output" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio' & anio[`k'] >= 2010 {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfspPIB[`k']',"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' null,"
			}
			if anio[`k'] == `anio' {
				local proy_shrfsp = "`proy_shrfsp' `=string(`shrfspobslast',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(52.348,"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfspPIB[`k']',"%10.3f")',"
			}
			if anio[`k'] > `anio' & anio[`k'] <= 2030 {
				local proy_shrfsp = "`proy_shrfsp' null,"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfspPIB[`k']',"%10.3f")',"
			}
		}
		local length_shrfsp = strlen("`proy_shrfsp'")
		local length_shrfsp2 = strlen("`proy_shrfsp2'")
		capture log on output
		noisily di in w "PROYSHRFSP1: [`=substr("`proy_shrfsp'",1,`=`length_shrfsp'-1')']"
		noisily di in w "PROYSHRFSP2: [`=substr("`proy_shrfsp2'",1,`=`length_shrfsp2'-1')']"	
		capture log off output
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `end' {
			local shrfsp_end = shrfspPIB[`k']
			continue, break
		}
	}
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc `shrfsp_end' ///
		in g " % PIB"	


	*****************************************
	*** 5 Fiscal Gap: Cuenta Generacional ***
	*****************************************
	preserve
	use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear

	collapse (sum) poblacion if edad == 0, by(anio) fast
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	drop if lambda == .
	
	g poblacionVP = poblacion*lambda/(1+`discount'/100)^(anio-`anio')
	format poblacionVP %20.0fc

	tabstat poblacionVP if anio > `anio', stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)
	
	noisily di in g "  (*) Poblaci{c o'}n futura VP: " in y _col(35) %25.0fc `poblacionVP'[1,1] in g " personas"

	local poblacionINF = poblacionVP[_N] /*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')*/ /(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	noisily di in g "  (*) Poblaci{c o'}n futura INF: " in y _col(35) %25.0fc `poblacionINF' in g " personas"

	noisily di in g "  (*) Cuenta generaciones futuras:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad generacional:" ///
			in y _col(35) %25.0fc ((-(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}
	restore



	************************/
	**** Touchdown!!! :) ****
	*************************
	timer off 11
	timer list 11
	noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t11)/r(nt11)',.1) in g " segs  " _dup(20) "."
}
end




*****************************************/
***                                    ***
*** 6. Parte 4: Balance presupuestario ***
***                                    ***
/******************************************
noisily di _newline(2) in g "{bf: POL{c I'}TICA FISCAL " in y "`anio'" "}"
noisily di in g "  (+) Ingresos: " ///
	_col(30) in y %20.0fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3]) in g " MXN" ///
	_col(60) in y %8.1fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])/scalar(pibY)*100 in g "% PIB"
noisily di in g "  (-) Gastos: " ///
	_col(30) in y %20.0fc GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY) in g " MXN" ///
	_col(60) in y %8.1fc (GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort')/scalar(pibY)*100 + scalar(IngBas) + scalar(Bienestar) in g "% PIB"
noisily di _dup(72) in g "-"
noisily di in g "  (=) Balance "in y "econ{c o'}mico" in g ": " ///
	_col(30) in y %20.0fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3] ///
	-(GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY))) in g " MXN" ///
	_col(60) in y %8.1fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3] ///
	-(GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'))/scalar(pibY)*100 - scalar(IngBas) - scalar(Bienestar) in g "% PIB"
noisily di in g "  (-) Costo de la deuda: " ///
	_col(30) in y %20.0fc -`CostoDeuda' in g " MXN" ///
	_col(60) in y %8.1fc -`CostoDeuda'/scalar(pibY)*100 in g "% PIB"
noisily di _dup(72) in g "-"
noisily di in g "  (=) Balance " in y "primario" in g ": " ///
	_col(30) in y %20.0fc (((INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])) ///
	-((GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY))) ///
	+`CostoDeuda') in g " MXN" ///
	_col(60) in y %8.1fc (((INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])) ///
	-((GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort')) ///
	+`CostoDeuda')/scalar(pibY)*100 - scalar(IngBas) - scalar(Bienestar) in g "% PIB"





