program define FiscalGap
quietly {

	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, Graphs Anio(int `aniovp') BOOTstrap(int 1) Update END(int 2100) INTERvencion]


	*************
	*** 1 PIB ***
	*************
	PIBDeflactor, anio(`anio')
	local currency = currency[1]
	local discount = r(discount)
	local anio_last = r(anio_last)
	
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
	SHRFSP, anio(`anio') `update'
	tempfile shrfsp
	save `shrfsp'


	******************************
	*** 3 Fiscal Gap: Ingresos ***
	******************************
	LIF, anio(`anio') lif
	collapse (sum) recaudacion if divLIF != 10, by(anio divGA) fast
	g modulo = ""

	levelsof divGA, local(divGA)
	foreach k of local divGA {
		local divGA`k' : label divGA `k'
		if "`divGA`k''" == "Impuestos al ingreso" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/$id/IngresoREC.dta"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			g divGA = `k'
			g modulo = "alingreso"

			tempfile alingreso
			save `alingreso'

			restore
			merge 1:1 (anio divGA) using `alingreso', nogen update replace
		}
		if "`divGA`k''" == "Impuestos al consumo" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/$id/ConsumoREC.dta"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			g divGA = `k'
			g modulo = "alconsumo"

			tempfile alconsumo
			save `alconsumo'

			restore
			merge 1:1 (anio divGA) using `alconsumo', nogen update replace
		}
		if "`divGA`k''" == "Ingresos de capital" | "`divGA`k''" == "Otros ingresos" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/$id/OtrosREC"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			g divGA = `k'
			g modulo = "otrosing"

			tempfile otros
			save `otros'

			restore
			merge 1:1 (anio divGA) using `otros', nogen update replace
		}
	}
	if "$pais" == "El Salvador" & "`intervencion'" == "intervencion" {
		preserve
		
		import excel "`c(sysdir_site)'../basesCIEP/SIM/intervencion_neta.xlsx", sheet("Hoja1") firstrow clear
		g divGA = 4
		g modulo = "otrosing"

		tempfile intervencion
		save `intervencion'

		restore
		merge 1:1 (anio divGA) using `intervencion', nogen update replace
	}
	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) recaudacion estimacion (max) pibYR deflator lambda, by(anio modulo)

	* Actualizaciones *
	replace recaudacion = 0 if recaudacion == .
	replace estimacion = 0 if estimacion == .
	replace estimacion = estimacion*lambda
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
	if "`graphs'" == "graphs" {
		tempvar consumo ingreso otros
		g `consumo' = (recaudacionalconsumo)/1000000
		g `ingreso' = (recaudacionalingreso + recaudacionalconsumo)/1000000
		g `otros' = (recaudacionotros + recaudacionalingreso + recaudacionalconsumo)/1000000

		tempvar consumo2 ingreso2 otros2
		g `consumo2' = (estimacionalconsumo)/1000000
		g `ingreso2' = (estimacionalingreso + estimacionalconsumo)/1000000
		g `otros2' = (estimacionotros + estimacionalingreso + estimacionalconsumo)/1000000

		twoway (area `otros' `ingreso' `consumo' anio if anio < `anio' & anio >= 2015) ///
			(area `otros2' anio if anio >= `anio', color("255 129 0")) ///
			(area `ingreso2' anio if anio >= `anio', color("255 189 0")) ///
			(area `consumo2' anio if anio >= `anio', color("39 97 47")), ///
			legend(cols(3) order(1 2 3) ///
			label(1 "Ingresos de capital") label(2 "Impuestos al ingreso") label(3 "Impuestos al consumo")) ///
			xlabel(2015(5)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`=`anio'-.5') ///
			text(`=`otros'[`obs`anio_last'']*.05' `=`anio'+.5' "Proyecci{c o'}n", place(ne) color(white)) ///
			yscale(range(0)) ///
			title({bf:Proyecci{c o'}n de los ingresos}) ///
			subtitle($pais) ///
			xtitle("") ytitle(millones `currency' `anio') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			name(Proy_ingresos, replace)
	}

	*********************
	** 3.2 Al infinito **
	noisily di _newline(2) in g "{bf: FISCAL GAP:" in y " $pais `anio' }"

	reshape long recaudacion estimacion, i(anio) j(modulo) string
	collapse (sum) recaudacion estimacion (mean) pibYR deflator, by(anio) fast

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	g estimacionVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format estimacionVP %20.0fc
	local estimacionINF = estimacion[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')/(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat estimacionVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname estimacionVP
	matrix `estimacionVP' = r(StatTotal)

	noisily di in g "  (+) Ingresos al infinito en VP:" in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] in g " `currency'"	
	
	* Save *
	rename estimacion estimacioningresos
	tempfile baseingresos
	save `baseingresos'



	****************************
	*** 4 Fiscal Gap: Gastos ***
	****************************
	PEF if divGA != -1, anio(`anio') by(divGA)
	collapse (sum) gasto=gastoneto if transf_gf == 0, by(anio divGA) fast
	g modulo = ""

	levelsof divGA, local(divGA)
	foreach k of local divGA {
		local divGA`k' : label divGA `k'
		if "`divGA`k''" == "Educaci{c o'}n" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/$id/EducacionREC.dta"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			g divGA = `k'
			g modulo = "educacion"

			tempfile educacion
			save `educacion'

			restore
			merge 1:1 (anio divGA) using `educacion', nogen update replace
		}
		if "`divGA`k''" == "Pensiones" {
			preserve

			if "$pais" == "" {
				use `"`c(sysdir_personal)'/users/$pais/$id/PensionREC.dta"', clear
				collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			}
			if "$pais" == "El Salvador" {
				import excel "`c(sysdir_site)'../basesCIEP/SIM/PensionesElSalvador.xlsx", sheet("Sheet1") firstrow clear
			}
			g divGA = `k'
			g modulo = "pensiones"

			tempfile pensiones
			save `pensiones'

			restore
			merge 1:1 (anio divGA) using `pensiones', nogen update replace
		}
		if "`divGA`k''" == "Salud" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/$id/SaludREC.dta"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			g divGA = `k'
			g modulo = "salud"

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
			local modpenbien = `k'
		}
		if "`divGA`k''" == "Otros" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/$id/OtrosGasREC.dta"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
			g divGA = `k'
			g modulo = "otrosgas"

			tempfile otrosgas
			save `otrosgas'

			restore
			merge 1:1 (anio divGA) using `otrosgas', nogen update replace
		}
	}


	** Pension Bienestar **
	preserve
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/PenBienestarREC"', clear
	collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
	capture g divGA = `modpenbien'
	if _rc != 0 {
		g divGA = 98
	}
	g modulo = "penbienestar"

	tabstat poblacion if anio == `anio', save
	tempname pob
	matrix `pob' = r(StatTotal)
	
	if scalar(BienestarLP) == 1 {
		replace estimacion = poblacion*`=`=scalar(Bienestar)'/100*`=scalar(pibY)'/`=`pob'[1,1]''
	}
	else {
		replace estimacion = poblacion*`=`=scalar(Bienestar)'/100*`=scalar(pibY)'/`=`pob'[1,1]'' if anio == `anio'
		replace estimacion = 0 if anio != `anio'
	}

	tempfile penbienestar
	save `penbienestar'

	restore
	merge 1:1 (anio divGA) using `penbienestar', nogen update replace


	** Ingreso basico **
	preserve
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/IngBasicoREC"', clear
	collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio) fast
	g divGA = 99
	g modulo = "ingbasico"

	tabstat poblacion if anio == `anio', save
	tempname pob
	matrix `pob' = r(StatTotal)
	
	if scalar(IngBasLP) == 1 {
		replace estimacion = poblacion*`=`=scalar(IngBas)'/100*`=scalar(pibY)'/`=`pob'[1,1]''
	}
	else {
		replace estimacion = poblacion*`=`=scalar(IngBas)'/100*`=scalar(pibY)'/`=`pob'[1,1]'' if anio == `anio'
		replace estimacion = 0 if anio != `anio'
	}
	
	tempfile ingbasico
	save `ingbasico'

	restore
	merge 1:1 (anio divGA) using `ingbasico', nogen update replace

	* PIB *
	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) gasto estimacion (max) pibYR deflator lambda, by(anio modulo) fast


	*********************
	** Actualizaciones **
	replace gasto = 0 if gasto == .
	replace estimacion = 0 if estimacion == .
	replace estimacion = estimacion*lambda
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
	g amortizacionpib = gastoamortizacion/pibYR*100
	egen amortizacionprom = mean(amortizacionpib)
	replace amortizacionpib = L.amortizacionpib if amortizacionpib == .

	replace gastoamortizacion = amortizacionpib/100*pibYR if gastoamortizacion == .
	replace estimacionamortizacion = amortizacionpib/100*pibYR if estimacionamortizacion == .

	replace estimacionamortizacion = gastoamortizacion if anio == `anio' & estimacionamortizacion == 0

	* Costo financiero de la deuda *
	merge 1:1 (anio) using `shrfsp', nogen keepus(shrfsp rfsp)
	merge 1:1 (anio) using `baseingresos', nogen

	replace shrfsp = shrfsp/deflator
	replace rfsp = rfsp/deflator

	* Actualizacion de los saldos *
	g actualizacion = ((shrfsp - L.shrfsp) - (rfsp) ///
		+ (gastoamortizacion))/L.shrfsp*100 //if anio <= `anio'
	egen actualizacionprom = mean(actualizacion)
	replace actualizacion = actualizacionprom if actualizacion == .

	/*forvalues k=`=_N'(-1)1 {
		if actualizacion[`k'] != . & "`foundlast'" != "yes" {
			local act_obslast = `k'
			local foundlast = "yes"
		}
		if actualizacion[`k'] == . & "`foundlast'" == "yes" {
			local act_obsfirs = `k'+1
			continue, break
		}
	}
	g actualizacion_geo = (actualizacion[`act_obslast']/actualizacion[`act_obsfirs'])^(1/(`act_obslast'-`act_obsfirs'))
	replace actualizacion = `actualizacion_geo' if actualizacion == .*/
	format actualizacion %5.3fc

	* Costo de la deuda *
	g costodeudashrfsp = gastocostodeuda/shrfsp*100
	egen costodeudashrfsp_ari = mean(costodeudashrfsp)
	replace costodeudashrfsp = costodeudashrfsp_ari if costodeudashrfsp == .

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

	forvalues k = `anio'(1)`=anio[_N]' {
		replace estimacioncostodeuda = L.costodeudashrfsp/100*L.shrfsp if anio == `k'
		*replace estimacioncostodeuda = 0 if estimacioncostodeuda < 0
		replace rfsp = estimacionamortizacion + estimacioncostodeuda + estimacioneducacion ///
			+ estimacionsalud + estimacionpensiones + estimacionotrosgas + estimacioningbasico ///
			+ estimacionpenbienestar ///
			- estimacioningresos if anio == `k'
		replace shrfsp = L.shrfsp*(1+actualizacion/100) + rfsp if anio == `k'
	}
	
	g rfsp_pib = rfsp/pibY*100

	****************
	** 4.1 Graphs **
	if "`graphs'" == "graphs" {
		tempvar educaciong pensionesg saludg costog amortg otrosg ingbasg bienestarg
		g `educaciong' = (gastoeducacion)/1000000
		g `pensionesg' = (gastopensiones + gastoeducacion)/1000000
		g `saludg' = (gastosalud + gastopensiones + gastoeducacion)/1000000
		g `costog' = (gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		g `amortg' = (gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		g `otrosg' = (gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		g `bienestarg' = (gastopenbienestar + gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		g `ingbasg' = (gastoingbasico + gastopenbienestar + gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		
		tempvar educaciong2 pensionesg2 saludg2 costog2 amortg2 otrosg2 ingbasg2 bienestarg2
		g `educaciong2' = (estimacioneducacion)/1000000
		g `pensionesg2' = (estimacionpensiones + estimacioneducacion)/1000000
		g `saludg2' = (estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `costog2' = (estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `amortg2' = (estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `otrosg2' = (estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `bienestarg2' = (estimacionpenbienestar + estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `ingbasg2' = (estimacioningbasico + estimacionpenbienestar + estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000

		twoway (area `ingbasg' `bienestarg' `otrosg' `amortg' `costog' `saludg' `pensionesg' `educaciong' anio if anio < `anio' & anio >= 2013) ///
			(area `ingbasg2' anio if anio >= `anio', color("255 129 0")) ///
			(area `bienestarg2' anio if anio >= `anio', color("255 189 0")) ///
			(area `otrosg2' anio if anio >= `anio', color("39 97 47")) ///
			(area `amortg2' anio if anio >= `anio', color("53 200 71")) ///
			(area `costog2' anio if anio >= `anio', color("0 78 198")) ///
			(area `saludg2' anio if anio >= `anio', color("0 151 201")) ///
			(area `pensionesg2' anio if anio >= `anio', color("186 34 64")) ///
			(area `educaciong2' anio if anio >= `anio', color("254 118 109")) if anio >= 2015, ///
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
			xline(`=`anio'-.5') ///
			text(`=`otrosg'[`obs`anio_last'']*.075' `=`anio'+.5' "Proyecci{c o'}n", place(ne) color(white)) ///
			yscale(range(0)) ///
			title({bf:Proyecci{c o'}n de los gastos}) ///
			subtitle($pais) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			xtitle("") ytitle(millones `currency' `anio') ///
			name(Proy_gastos, replace)
			
		twoway (area rfsp_pib anio if anio < `anio' & anio >= 2015) ///
			(area rfsp_pib anio if anio >= `anio'), ///
			yscale(range(0)) ///
			ytitle(% PIB) ///
			xtitle("") ///
			xlabel(2015(5)`=round(anio[_N],10)') ///
			xline(`=`anio'-.5') ///
			legend(off) ///
			title({bf: Proyecci{c o'}n de los RFSP}) subtitle($pais) ///
			name(Proy_rfsp, replace)
	}

	*********************
	** 4.2 Al infinito **
	reshape long gasto estimacion, i(anio) j(modulo) string
	collapse (sum) gasto estimacion (mean) pibYR deflator shrfsp rfsp ///
		if modulo != "ingresos" & modulo != "VP", by(anio) fast

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	g gastoVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format gastoVP %20.0fc
	local gastoINF = estimacion[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')/(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat gastoVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname gastoVP
	matrix `gastoVP' = r(StatTotal)

	noisily di in g "  (-) Gastos al infinito en VP:" in y _col(35) %25.0fc `gastoINF'+`gastoVP'[1,1] in g " `currency'"	
	
	* Save *
	rename estimacion estimaciongastos
	tempfile basegastos
	save `basegastos'


	*****************************
	*** 5 Fiscal Gap: Balance ***
	*****************************
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Balance al infinito en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	

	* Saldo de la deuda *
	tabstat shrfsp if anio == `anio', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)

	noisily di in g "  (+) Deuda (`anio'):" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Financial wealth (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (/) Ingresos al infinito en VP:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`estimacionINF'+`estimacionVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (/) Gastos al infinito en VP:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`gastoINF'+`gastoVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (/) PIB al infinito en VP:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/scalar(pibVPINF)*100 ///
		in g " %"

	if "`graphs'" == "graphs" {
		g shrfspPIB = shrfsp/pibY*100
		twoway (area shrfspPIB anio if shrfspPIB != . & anio < `anio' & anio >= 2015) ///
			(area shrfspPIB anio if anio >= `anio'), ///
			title({bf:Proyecci{c o'}n del SHRFSP}) ///
			subtitle($pais) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			xtitle("") ytitle(% PIB) ///
			xlabel(2015(5)`end') ///
			yscale(range(0)) ///
			legend(off) ///
			text(`=shrfspPIB[`obs`anio_last'']*.075' `=`anio'+.5' "Proyecci{c o'}n", color(white) placement(e)) ///
			xline(`=`anio'-.5') ///
			name(Proy_shrfsp, replace)			
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `end' {
			local shrfsp_end = shrfspPIB[`k']
			continue, break
		}
	}


	*****************************************
	*** 5 Fiscal Gap: Cuenta Generacional ***
	*****************************************
	preserve
	Poblacion
	collapse (sum) poblacion if edad == 0, by(anio) fast
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	
	g poblacionVP = poblacion*lambda/(1+`discount'/100)^(anio-`anio') if anio > `anio'
	format poblacionVP %20.0fc
	
	tabstat poblacionVP, stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)
	
	local poblacionINF = poblacion[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')/(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc `shrfsp_end' ///
		in g " % PIB"	
	noisily di in g "  (*) Cuenta generaciones futuras:" ///
		in y _col(35) %25.0fc -(`estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad generacional:" ///
			in y _col(35) %25.0fc ((-(`estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}
}
end
