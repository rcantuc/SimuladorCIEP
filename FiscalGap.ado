program define FiscalGap
quietly {

	syntax [, Graphs Anio(int -1) BOOTstrap(int 1) Update]


	*************
	*** 1 PIB ***
	*************
	PIBDeflactor, anio(`anio')
	local currency = currency[1]
	local discount = r(discount)
	tempfile PIB
	save `PIB'


	****************
	*** 2 SHRFSP ***
	****************
	SHRFSP, anio(`anio') `graphs' `update'
	tempfile shrfsp
	save `shrfsp'


	******************************
	*** 3 Fiscal Gap: Ingresos ***
	******************************
	LIF, anio(`anio')
	collapse (sum) recaudacion if divLIF != 10, by(anio divGA)
	g modulo = ""

	levelsof divGA, local(divGA)
	foreach k of local divGA {
		local divGA`k' : label divGA `k'
		if "`divGA`k''" == "Impuestos al ingreso" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/IngresoREC"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio)
			g divGA = `k'
			g modulo = "alingreso"

			tempfile alingreso
			save `alingreso'

			restore
			merge 1:1 (anio divGA) using `alingreso', nogen update replace
		}
		if "`divGA`k''" == "Impuestos al consumo" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/ConsumoREC"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio)
			g divGA = `k'
			g modulo = "alconsumo"

			tempfile alconsumo
			save `alconsumo'

			restore
			merge 1:1 (anio divGA) using `alconsumo', nogen update replace
		}
		if "`divGA`k''" == "Otros ingresos" {
			replace modulo = "otrosing" if divGA == `k'
		}
	}

	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) recaudacion estimacion (max) pibYR deflator lambda, by(anio modulo)

	* Actualizaciones *
	replace recaudacion = . if recaudacion == 0
	replace estimacion = . if estimacion == 0
	replace estimacion = estimacion*lambda
	replace recaudacion = recaudacion/deflator

	* Reshape *
	reshape wide recaudacion estimacion, i(anio) j(modulo) string
	format recaudacion* estimacion* %20.0fc

	* Otros ingresos *
	tsset anio
	g otrospib = recaudacionotros/pibYR*100
	replace otrospib = L.otrospib if anio > `anio'
	replace estimacionotros = L.otrospib/100*pibYR if anio > `anio'

	****************
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

		twoway (area `otros' `ingreso' `consumo' anio if anio <=`anio' & anio >= 2010) ///
			(area `otros2' anio if anio > `anio', color("255 129 0")) ///
			(area `ingreso2' anio if anio > `anio', color("255 189 0")) ///
			(area `consumo2' anio if anio > `anio', color("39 97 47")), ///
			legend(cols(3) order(1 2 3) ///
			label(1 "Otros ingresos") label(2 "Impuestos al ingreso") label(3 "Impuestos al consumo")) ///
			xlabel(2010(10)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`anio'.5) ///
			/*text(`=`otros'[1]*.05' `=`anio'-.5' "`anio'", place(nw) color(white))*/ ///
			/*text(`=`otros'[1]*.05' `=anio[1]+.5' "Observado", place(ne) color(white))*/ ///
			/*text(`=`otros'[1]*.05' `=`anio'+1.5' "Proyectado", place(ne) color(white))*/ ///
			yscale(range(0)) ///
			title({bf:Proyecci{c o'}n de los ingresos}) ///
			subtitle($pais) ///
			xtitle("") ytitle(millones `currency' `anio') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			name(Proy_ingresos, replace)
	}

	*********************
	** 3.2 Al infinito **
	noisily di _newline(2) in y " $pais `anio'"

	reshape long recaudacion estimacion, i(anio) j(modulo) string
	collapse (sum) recaudacion estimacion (mean) pibYR deflator, by(anio)

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
	PEF, anio(`anio') by(divGA)
	collapse (sum) gasto=gastoneto if transf_gf == 0, by(anio divGA)
	g modulo = ""

	levelsof divGA, local(divGA)
	foreach k of local divGA {
		local divGA`k' : label divGA `k'
		if "`divGA`k''" == "Educaci{c o'}n" {
			preserve

			use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/EducacionREC"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio)
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
				use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/PensionREC"', clear
				collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio)
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

			use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/SaludREC"', clear
			collapse (mean) estimacion contribuyentes* poblacion aniobase, by(anio)
			g divGA = `k'
			g modulo = "salud"

			tempfile salud
			save `salud'

			restore
			merge 1:1 (anio divGA) using `salud', nogen update replace
		}
		if "`divGA`k''" == "Costo financiero de la deuda" {
			replace modulo = "costodeuda" if divGA == `k'
		}
		if "`divGA`k''" == "Amortizaci{c o'}n" {
			replace modulo = "amortizacion" if divGA == `k'
		}
		if "`divGA`k''" == "Otros" {
			replace modulo = "otrosgas" if divGA == `k'
		}
	}

	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) gasto estimacion (max) pibYR deflator lambda, by(anio modulo)

	* Actualizaciones *
	replace gasto = . if gasto == 0
	replace estimacion = . if estimacion == 0
	replace estimacion = estimacion*lambda
	replace gasto = gasto/deflator

	* Reshape *
	reshape wide gasto estimacion, i(anio) j(modulo) string
	format gasto* estimacion* %20.0fc

	* Otros gastos *
	tsset anio
	g otrospib = gastootros/pibYR*100
	replace otrospib = L.otrospib if anio > `anio'
	replace estimacionotros = L.otrospib/100*pibYR if anio > `anio'

	* Amortizacion *
	g amortizacionpib = gastoamortizacion/pibYR*100
	replace amortizacionpib = L.amortizacionpib if anio > `anio'
	replace estimacionamortizacion = L.amortizacionpib/100*pibYR if anio > `anio'

	* Costo financiero de la deuda *
	merge 1:1 (anio) using `shrfsp', nogen keepus(shrfsp rfsp)
	merge 1:1 (anio) using `baseingresos', nogen

	replace shrfsp = shrfsp/deflator
	replace rfsp = rfsp/deflator

	g actualizacion = (D.shrfsp - (rfsp - gastoamortizacion))/L.shrfsp*100
	replace actualizacion = L.actualizacion if anio > `anio'

	g costodeudashrfsp = gastocostodeuda/shrfsp*100
	replace costodeudashrfsp = L.costodeudashrfsp if anio > `anio'

	* Iteraciones *
	forvalues k = `=`anio'+1'(1)`=anio[_N]' {
		replace estimacioncostodeuda = L.costodeudashrfsp/100*L.shrfsp if anio == `k'
		replace rfsp = estimacionamortizacion + estimacioncostodeuda + estimacioneducacion ///
			+ estimacionsalud + estimacionpensiones + estimacionotrosgas ///
			- estimacioningresos if anio == `k'
		replace shrfsp = L.shrfsp*(1+actualizacion/100) + rfsp if anio == `k'
	}

	****************
	** 4.1 Graphs **
	if "`graphs'" == "graphs" {
		tempvar educaciong pensionesg saludg costog amortg otrosg
		g `educaciong' = (gastoeducacion)/1000000
		g `pensionesg' = (gastopensiones + gastoeducacion)/1000000
		g `saludg' = (gastosalud + gastopensiones + gastoeducacion)/1000000
		g `costog' = (gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		g `amortg' = (gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000
		g `otrosg' = (gastootros + gastoamortizacion + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000

		tempvar educaciong2 pensionesg2 saludg2 costog2 amortg2 otrosg2
		g `educaciong2' = (estimacioneducacion)/1000000
		g `pensionesg2' = (estimacionpensiones + estimacioneducacion)/1000000
		g `saludg2' = (estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `costog2' = (estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `amortg2' = (estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000
		g `otrosg2' = (estimacionotros + estimacionamortizacion + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000

		twoway (area `otrosg' `amortg' `costog' `saludg' `pensionesg' `educaciong' anio if anio <= `anio' & anio >= 2014) ///
			(area `otrosg2' anio if anio > `anio', color("255 129 0")) ///
			(area `amortg2' anio if anio > `anio', color("255 189 0")) ///
			(area `costog2' anio if anio > `anio', color("39 97 47")) ///
			(area `saludg2' anio if anio > `anio', color("53 200 71")) ///
			(area `pensionesg2' anio if anio > `anio', color("0 78 198")) ///
			(area `educaciong2' anio if anio > `anio', color("0 151 201")), ///
			legend(cols(4) order(1 2 3 4 5 6) ///
			label(1 "Otros gastos") label(2 "Amortizaci{c o'}n") label(3 "Costo financiero de la deuda") ///
			label(4 "Salud") label(5 "Pensiones") label(6 "Educaci{c o'}n")) ///
			xlabel(2010(10)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`anio'.5) ///
			/*text(`=`saludg'[21]*.035' `=`anio'-.5' "`anio'", place(nw) color(white))*/ ///
			/*text(`=`saludg'[21]*.035' `=anio[21]+.5' "Observado", place(ne) color(white))*/ ///
			/*text(`=`saludg'[21]*.035' `=`anio'+1.5' "Proyectado", place(ne) color(white))*/ ///
			yscale(range(0)) ///
			title({bf:Proyecci{c o'}n de los gastos}) ///
			subtitle($pais) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			xtitle("") ytitle(millones `currency' `anio') ///
			name(Proy_gastos, replace)
	}

	*********************
	** 4.2 Al infinito **
	reshape long gasto estimacion, i(anio) j(modulo) string
	collapse (sum) gasto estimacion (mean) pibYR deflator ///
		if modulo != "ingresos" & modulo != "VP", by(anio)

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

	use `shrfsp', clear

	* Saldo de la deuda *
	tabstat shrfsp if anio == `anio', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)

	noisily di in g "  (+) Deuda (`anio'):" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Fianancial wealth en VP:" ///
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


	*****************************************
	*** 5 Fiscal Gap: Cuenta Generacional ***
	*****************************************
	Poblacion
	collapse (sum) poblacion if edad == 0, by(anio)
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	
	g poblacionVP = poblacion*lambda/(1+`discount'/100)^(anio-`anio') if anio > `anio'
	format poblacionVP %20.0fc
	
	tabstat poblacionVP, stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)
	
	local poblacionINF = poblacion[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`anio'-`=anio[_N]')/(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Cuenta generaciones futuras:" ///
		in y _col(35) %25.0fc -(`estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency'"
	noisily di in g "  (*) Inequidad generacional:" ///
		in y _col(35) %25.0fc ((-(`estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
		in g " %"

}
end
