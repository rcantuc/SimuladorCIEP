program define FiscalGap
quietly {

	timer on 11
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, NOGraphs Anio(int `=aniovp') Update END(int 2100) ///
		ANIOMIN(int 2000) DIScount(real 5) DESDE(int `=`=aniovp'-1')]
	noisily di _newline(2) in g "{bf: FISCAL GAP:" in y " $pais `anio' }"



	*************
	***       ***
	**# 1 PIB ***
	***       ***
	*************
	PIBDeflactor, anio(`=aniovp') geopib(`desde') geodef(`desde') nographs nooutput
	replace Poblacion = Poblacion*lambda
	replace Poblacion0 = Poblacion0*lambda
	keep if anio <= `end'
	local currency = currency[1]
	local llambda = real(llambda)
	tempfile PIB
	save `PIB'



	****************
	***          ***
	**# 2 SHRFSP ***
	***          ***
	****************
	noisily SHRFSP, anio(`anio') nographs $textbook //update
	tempfile shrfsp
	save `shrfsp'



	********************
	***              ***
	**# 3 HOUSEHOLDS ***
	***              ***
	********************
	use "`c(sysdir_site)'/users/$id/ingresos.dta", clear
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen update
	capture drop _*
	foreach k in Educacion Pensiones Pensión_AM Salud OtrosGastos IngBasico OtrasInversiones Federalizado Energia {
		tabstat `k' [fw=factor], stat(sum) f(%20.0fc) save
		local k = subinstr("`k'","á","a",.)
		local k = subinstr("`k'","é","e",.)
		local k = subinstr("`k'","í","i",.)
		local k = subinstr("`k'","ó","o",.)
		local k = subinstr("`k'","ú","u",.)
		
		if "`k'" == "OtrasInversiones" {
			local k "Otras_inversiones"
		}
	
		if "`k'" == "OtrosGastos" {
			local k "Otros_gastos"
		}
		
		tempname HH`k'
		matrix `HH`k'' = r(StatTotal)
	}



	******************************
	***                        ***
	**# 4 Fiscal Gap: Ingresos ***
	***                        ***
	******************************
	noisily di _newline in g "  INGRESOS " in y "`desde'-`anio'"

	** 4.1 Información histórica de los ingresos **
	LIF if divLIF != 10, anio(`anio') nographs by(divSIM) min(0) desde(`desde') //eofp //ilif
	local divSIM = r(divSIM)

	foreach k of local divSIM {
		local `k'C = scalar(`k'C)
		if ``k'C' > 5 {
			local `k'C = 5
		}
		if ``k'C' < -5 {
			local `k'C = -5
		}
		capture confirm scalar `k'PIB
		if _rc != 0 {
			scalar `k'PIB = scalar(`k')/scalar(pibY)*100
		}
	}
	collapse (sum) recaudacion, by(anio divSIM) fast
	decode divSIM, g(divCIEP)
	replace divCIEP = strtoname(divCIEP)

	** 4.2 Proyección futura de los ingresos **/
	scalar pibY = real(subinstr(scalar(pibY),",","",.))*1000000
	foreach k in CFE CUOTAS FMP IEPSNP IEPSP IMPORT IMSS ISAN ISRAS ISRPF ISRPM ISSSTE IVA OTROSK PEMEX {
		use `"`c(sysdir_site)'/users/ciepmx/bootstraps/1/`k'REC.dta"', clear
		collapse estimacion contribuyentes, by(anio modulo aniobase)
		tsset anio
		
		g divSIM = "`k'"
		
		* Calcular tasa de crecimiento demográfico (contribuyentes) *
		g crecimiento_demo = (contribuyentes/L.contribuyentes - 1) * 100
		
		* Calcular promedio de crecimiento demográfico histórico *
		tabstat crecimiento_demo if anio <= `anio' & anio >= `anio'-5 & crecimiento_demo != ., stat(mean) save
		local tasa_demo = r(StatTotal)[1,1]
		
		* Separar tendencia de largo plazo en componentes *
		* Tendencia total = ``k'C'
		* Componente demográfico = `tasa_demo'
		* Componente no demográfico (per cápita) = ``k'C' - `tasa_demo'
		local tendencia_pc = real(scalar(`k'C)) - `tasa_demo'
		
		* Mensaje informativo *
		noisily di in g "  `k': " ///
		_col(35) "Tasa total =" in y %7.2f real(scalar(`k'C)) "%" ///
		_col(60) in g "Demográfica =" in y %7.2f `tasa_demo' "%" ///
		_col(85) in g "Económica =" in y %7.2f `tendencia_pc' "%"

		tempvar estimacion
		g `estimacion' = estimacion
		
		* Nueva fórmula SIN doble contabilización *
		replace estimacion = (contribuyentes/L.contribuyentes) *	/// Cambio demográfico PURO (contribuyentes)
			(real(`k'PIB)/100*scalar(pibY)) *			/// Estimación como % del PIB (Parámetros)
			(1+`tendencia_pc'/100)^(anio-`anio')			/// Tendencia per cápita (LIF.ado - efecto demo)
			if anio >= `anio'
		
		* Para años donde no hay datos de contribuyentes, usar método original *
		*replace estimacion = `estimacion'/L.`estimacion' * 		/// Cambio demográfico
			(real(`k'PIB)/100*scalar(pibY)) * 			/// Estimación como % del PIB (Parámetros)
			(1+`tendencia_pc'/100)^(anio-`anio') 			/// Tendencia per cápita
			if anio >= `anio'

		*noisily di "`k': " %5.2fc (1+`tendencia_pc'/100) " " %5.2fc `tendencia_pc'
		tempfile `k'
		save ``k''
	}

	use `"`c(sysdir_site)'/users/$id/LIF.dta"', clear	
	g modulo = ""
	foreach k in CFE CUOTAS FMP IEPSNP IEPSP IMPORT IMSS ISAN ISRAS ISRPF ISRPM ISSSTE IVA OTROSK PEMEX {
		merge 1:1 (anio divSIM) using ``k'', nogen update replace
	}
	format estimacion %20.0fc

	** 4.3 Actualizaciones **
	collapse (sum) recaudacion estimacionRecaudacion=estimacion if anio <= `end', by(anio divSIM) fast
	merge m:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda Poblacion*) update replace keep(matched)

	replace estimacionRecaudacion = estimacionRecaudacion*deflator
	replace recaudacion = 0 if recaudacion == .
	replace estimacionRecaudacion = 0 if estimacionRecaudacion == .
	format estimacion* %20.0fc

	g recaudacion_pib = recaudacion/pibY*100 				
	g estimacionRecaudacion_pib = estimacionRecaudacion/pibY*100 

	g divGraph = "Impuestos laborales" if divSIM == "CUOTAS" | divSIM == "ISRAS" | divSIM == "ISRPF"
	replace divGraph = "Impuestos al consumo" if divSIM == "IEPSNP" | divSIM == "IEPSP" | divSIM == "IVA" | divSIM == "ISAN" | divSIM == "IMPORT"
	replace divGraph = "Impuestos al capital" if divSIM == "ISRPM" | divSIM == "OTROSK" | divSIM == "FMP"
	replace divGraph = "Organismos y empresas" if divSIM == "CFE" | divSIM == "IMSS" | divSIM == "ISSSTE" | divSIM == "PEMEX"


	****************
	** 4.4 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		//noisily tabstat recaudacion_pib estimacionRecaudacion_pib if anio >= `aniomin', stat(sum) by(anio) save
		graph bar (sum) recaudacion_pib if anio < `anio' & anio >= `aniomin', ///
			bargap(20) ///
			over(divGraph) ///
			over(anio, gap(0)) ///
			ytitle("% PIB") ///
			stack asyvar ///
			text(`text', size(vsmall)) ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_ingresos1) ///
			title(Observado)

		graph bar (sum) estimacionRecaudacion_pib if anio >= `anio', ///
			bargap(20) ///
			over(divGraph) ///
			over(anio, gap(0)) ///
			ytitle("") ylabel(, labcolor(white)) ///
			stack asyvar ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_ingresos2) ///
			title(Proyectado)

		capture which grc1leg2
		if _rc != 0 {
			net install "http://fmwww.bc.edu/RePEc/bocode/g/grc1leg2.pkg"
		}
		grc1leg2 Proy_ingresos1 Proy_ingresos2, ycommon ///
		///graph combine Proy_ingresos1 Proy_ingresos2, ycommon ///
			///title({bf:Ingresos p{c u'}blicos}) ///
			///caption("`graphfuente'") ///
			name(Proy_ingresos, replace)

		capture window manage close graph Proy_ingresos1
		capture window manage close graph Proy_ingresos2

		if "$export" != "" {
			graph export `"$export/Proy_ingresos.png"', replace name(Proy_ingresos)
		}
	}


	*****************
	** 4.5 Outputs **
	if "$output" != "" {
		preserve
		collapse (sum) recaudacion_pib estimacionRecaudacion_pib if anio <= `end', by(anio divGraph) fast
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				if divGraph[`k'] == "Impuestos laborales" {
					local proy_laborales = "`proy_laborales' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al consumo" {
					local proy_consumo  = "`proy_consumo' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al capital" {
					local proy_capital  = "`proy_capital' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Organismos y empresas" {
					local proy_organismos  = "`proy_organismos' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				if divGraph[`k'] == "Impuestos laborales" {
					local proy_laborales = "`proy_laborales' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al consumo" {
					local proy_consumo  = "`proy_consumo' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al capital" {
					local proy_capital  = "`proy_capital' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Organismos y empresas" {
					local proy_organismos  = "`proy_organismos' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
			}
		}
		local length_laborales = strlen("`proy_laborales'")
		local length_consumo = strlen("`proy_consumo'")
		local length_capital = strlen("`proy_capital'")
		local length_organismos = strlen("`proy_organismos'")
		capture log on output
		noisily di in w "PROYLABOR: [`=substr("`proy_laborales'",1,`=`length_laborales'-1')']"
		noisily di in w "PROYCONSU: [`=substr("`proy_consumo'",1,`=`length_consumo'-1')']"
		noisily di in w "PROYCAPIT: [`=substr("`proy_capital'",1,`=`length_capital'-1')']"
		noisily di in w "PROYORGAN: [`=substr("`proy_organismos'",1,`=`length_organismos'-1')']"
		capture log off output
		restore
	}


	********************/
	** 4.6 Al infinito **
	collapse (sum) recaudacion* estimacionRecaudacion* (last) pibY deflator, by(anio) fast

	* Calcular tasa de crecimiento de largo plazo (robusto) *
	count if anio >= `anio'
	local obs_futuras = r(N)
	local periodo_LR = min(10, `obs_futuras'-1)
	if `periodo_LR' < 2 {
		local periodo_LR = 2
	}
	
	* Verificar que no haya valores cero antes de dividir *
	if estimacionRecaudacion[_N-`periodo_LR'] > 0 & estimacionRecaudacion[_N] > 0 {
		local grow_rate_LR = (((estimacionRecaudacion[_N]/deflator[_N])/(estimacionRecaudacion[_N-`periodo_LR']/deflator[_N-`periodo_LR']))^(1/`periodo_LR')-1)*100
	}
	else {
		* Tasa de crecimiento por defecto si hay problemas *
		local grow_rate_LR = 2.0
		noisily di in r "      {bf:WARNING}: Usando tasa de crecimiento por defecto (`grow_rate_LR'%) para ingresos"
	}

	g estimacionVP = estimacionRecaudacion/(1+`discount'/100)^(anio-`anio')
	format estimacionVP %20.0fc
	
	* Validar que grow_rate < discount para perpetuidad *
	if `grow_rate_LR' >= `discount' {
		noisily di in r "      {bf:ERROR}: Tasa de crecimiento (`grow_rate_LR'%) >= tasa de descuento (`discount'%)"
		noisily di in r "      Ajustando tasa de crecimiento a `=`discount'-0.5'%"
		local grow_rate_LR = `discount' - 0.5
	}
	local estimacionINF = estimacionVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	tabstat estimacionVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname estimacionVP
	matrix `estimacionVP' = r(StatTotal)

	* Texto *
	noisily di in g "  (+) Ingresos futuros en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] in g " `currency'"
	noisily di in g "      (*) Ingresos INF:" in y _col(35) %25.0fc `estimacionINF' in g " `currency'"
	noisily di in g "      (*) Ingresos VP:" in y _col(35) %25.0fc `estimacionVP'[1,1] in g " `currency'"
	noisily di in g "      (*) Growth rate LP:" in y _col(35) %25.4fc `grow_rate_LR' in g " %"

	* Save *
	tempfile baseingresos
	save `baseingresos'





	****************************
	***                      ***
	**# 5 Fiscal Gap: Gastos ***
	***                      ***
	****************************
	noisily di _newline in g "  GASTOS " in y "`desde'-`anio'"

	*********************************************
	** 5.1 Información histórica de los gastos **
	noisily PEF if transf_gf == 0, anio(`anio') by(divCIEP) nographs desde(`desde')
	local divCIEP "`=r(divCIEP)' IngBasico"
	local divCIEP = subinstr("`divCIEP'","á","a",.)
	local divCIEP = subinstr("`divCIEP'","é","e",.)
	local divCIEP = subinstr("`divCIEP'","í","i",.)
	local divCIEP = subinstr("`divCIEP'","ó","o",.)
	local divCIEP = subinstr("`divCIEP'","ú","u",.)
	foreach k of local divCIEP {
		local `k' = r(`k')
		local `k'C = r(`k'C)
		
		if ``k'C' > 5 {
			local `k'C = 5
		}
		if ``k'C' < -5 {
			local `k'C = -5
		}
	}
	decode resumido, g(divCIEP)
	replace divCIEP = strtoname(divCIEP)
	replace divCIEP = subinstr(divCIEP,"á","a",.)
	replace divCIEP = subinstr(divCIEP,"é","e",.)
	replace divCIEP = subinstr(divCIEP,"í","i",.)
	replace divCIEP = subinstr(divCIEP,"ó","o",.)
	replace divCIEP = subinstr(divCIEP,"ú","u",.)


	****************************************/
	** 5.2 Proyección futura de los gastos **
	g modulo = ""
	foreach k of local divCIEP {
		if `"`=strtoname("`k'")'"' != "Costo_de_la_deuda" {
			preserve
			use `"`c(sysdir_site)'/users/ciepmx/bootstraps/1/`=strtoname("`k'")'REC.dta"', clear
			collapse estimacion contribuyentes, by(anio modulo aniobase)
			tsset anio
			
			* Calcular tasa de crecimiento demográfico (contribuyentes/beneficiarios) *
			g crecimiento_demo = (contribuyentes/L.contribuyentes - 1) * 100
			
			* Calcular promedio de crecimiento demográfico histórico *
			tabstat crecimiento_demo if anio <= `anio' & anio >= `anio'-5 & crecimiento_demo != ., stat(mean) save
			local tasa_demo = r(StatTotal)[1,1]
			
			* Separar tendencia de largo plazo en componentes *
			* Tendencia total = ``=strtoname("`k'")'C'
			* Componente demográfico = `tasa_demo'
			* Componente no demográfico (per cápita) = ``=strtoname("`k'")'C' - `tasa_demo'
			local tendencia_pc = ``=strtoname("`k'")'C' - `tasa_demo'
			
			* Mensaje informativo *
			noisily di in g "  `=strtoname("`k'")': " ///
				_col(35) "Tasa total =" in y %5.2f ``=strtoname("`k'")'C' "%" ///
				_col(60) in g "Demográfica =" in y %5.2f `tasa_demo' "%" ///
				_col(85) in g "Económica =" in y %5.2f `tendencia_pc' "%"
			
			tempvar estimacion
			g `estimacion' = estimacion
			
			* Nueva fórmula SIN doble contabilización *
			replace estimacion = (contribuyentes/L.contribuyentes) *     	/// Cambio demográfico PURO
				`HH`=strtoname("`k'")''[1,1] * 				/// Gasto total del año base (GastoPC.ado)
				(1+`tendencia_pc'/100)^(anio-`anio')    		/// Tendencia per cápita 
				if anio >= `anio'
			
			* Para años donde no hay datos de contribuyentes, usar método original *
			*replace estimacion = `estimacion'/L.`estimacion' * 		/// Cambio demográfico
			*	`HH`=strtoname("`k'")''[1,1] * 				/// Gasto total del año base (GastoPC.ado)
			*	(1+`tendencia_pc'/100)^(anio-`anio') 			/// Tendencia per cápita
			*	if anio >= `anio'

			g divCIEP = `"`=strtoname("`k'")'"'

			tempfile `k'
			save ``k''

			restore
			merge 1:1 (anio divCIEP) using ``k'', nogen update replace
		}
	}


	*************************
	** 5.3 Actualizaciones **
	collapse (sum) gasto estimacionGasto=estimacion if anio <= `end', by(anio divCIEP) fast
	merge m:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency Poblacion*) keep(matched) update

	replace estimacionGasto = gasto if divCIEP == "Cuotas_ISSSTE"
	replace estimacionGasto = estimacionGasto*deflator
	replace gasto = 0 if gasto == .
	replace estimacionGasto = 0 if estimacionGasto == .

	g gasto_pib = gasto/pibY*100
	g estimacionGasto_pib = estimacionGasto/pibY*100

	g divSIM = subinstr(divCIEP,"_"," ",.)
	replace divSIM = "Otros gastos" if divSIM == "IngBasico" | divSIM == "Federalizado" | divSIM == "Cuotas ISSSTE"
	replace divSIM = "Pensiones" if divSIM == "Pension AM"
	replace divSIM = "Educación" if divSIM == "Educacion"
	replace divSIM = "Energía" if divSIM == "Energia"


	****************
	** 5.4 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		//noisily tabstat gasto_pib estimacionGasto if anio >= `aniomin', stat(sum) by(anio) save
		graph bar (sum) gasto_pib if anio < `anio' & anio >= `aniomin' & divSIM != "Costo de la deuda", ///
			over(divSIM) ///
			over(anio, gap(0)) ///
			ytitle("% PIB") ///
			stack asyvar ///
			text(`text', size(vsmall)) ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_gastos1) ///
			title(Observado)

		graph bar (sum) estimacionGasto_pib if anio >= `anio' & divSIM != "Costo de la deuda", ///
			over(divSIM) ///
			over(anio, gap(0)) ///
			ytitle("") ylabel(none) ///
			stack asyvar ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_gastos2) ///
			title(Proyectado)

		grc1leg2 Proy_gastos1 Proy_gastos2, ycommon ///
		///graph combine Proy_gastos1 Proy_gastos2, ycommon ///
			///title({bf:Gasto p{c u'}blico primario}) ///
			subtitle($pais) ///
			///caption("`graphfuente'") ///
			name(Proy_gastos, replace)

		capture window manage close graph Proy_gastos1
		capture window manage close graph Proy_gastos2

		if "$export" != "" {
			graph export `"$export/Proy_gastos.png"', replace name(Proy_gastos)
		}

	}


	****************
	** 5.5 Output **
	if "$output" != "" {
		preserve
		*noisily levelsof divSIM, local(divSIM)
		collapse (sum) gasto_pib estimacionGasto_pib if anio <= `end', by(anio divSIM) fast
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				if divSIM[`k'] == "Educación" {
					local proy_educacion = "`proy_educacion' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Pensiones" {
					local proy_pensiones = "`proy_pensiones' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Salud" {
					local proy_salud = "`proy_salud' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otros gastos" {
					local proy_otros = "`proy_otros' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Energía" {
					local proy_energia = "`proy_energia' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otras inversiones" {
					local proy_inversiones = "`proy_inversiones' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				if divSIM[`k'] == "Educación" {
					local proy_educacion = "`proy_educacion' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Pensiones" {
					local proy_pensiones = "`proy_pensiones' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Salud" {
					local proy_salud = "`proy_salud' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otros gastos" {
					local proy_otros = "`proy_otros' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Energía" {
					local proy_energia = "`proy_energia' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otras inversiones" {
					local proy_inversiones = "`proy_inversiones' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
			}
		}
		local length_educacion = strlen("`proy_educacion'")
		local length_pensiones = strlen("`proy_pensiones'")
		local length_salud = strlen("`proy_salud'")
		local length_otros = strlen("`proy_otros'")
		local length_energia = strlen("`proy_energia'")
		local length_inversiones = strlen("`proy_inversiones'")
		capture log on output
		noisily di in w "PROYEDUCA: [`=substr("`proy_educacion'",1,`=`length_educacion'-1')']"
		noisily di in w "PROYPENSI: [`=substr("`proy_pensiones'",1,`=`length_pensiones'-1')']"
		noisily di in w "PROYSALUD: [`=substr("`proy_salud'",1,`=`length_salud'-1')']"
		noisily di in w "PROYOTROS: [`=substr("`proy_otros'",1,`=`length_otros'-1')']"
		noisily di in w "PROYENERG: [`=substr("`proy_energia'",1,`=`length_energia'-1')']"
		noisily di in w "PROYINVER: [`=substr("`proy_inversiones'",1,`=`length_inversiones'-1')']"
		capture log off output
		restore
	}


	***************************
	** 5.6 Costo de la deuda **
	collapse (sum) gasto* estimacion* (max) pibY deflator lambda Poblacion* if anio <= `end', by(anio) fast
	merge 1:1 (anio) using `shrfsp', nogen keep(matched) keepus(shrfsp* rfsp* /*nopresupuestario*/ tipoDeCambio tasaEfectiva costodeuda*)
	merge 1:1 (anio) using `baseingresos', nogen
	tsset anio

	* Actualización de la deuda *
	g gastoCosto_de_la_deuda = costodeudaInterno + costodeudaExterno
	g estimacionCosto_de_la_deuda = gastoCosto_de_la_deuda if gastoCosto_de_la_deuda != .
	*replace estimacionGasto = estimacionGasto + estimacionCosto_de_la_deuda if anio == `anio'
	format estimacion* gasto* %20.0fc

	* Reemplazar tasaEfectiva con la media artimética desde el año `desde' *
	replace tasaEfectiva = gastoCosto_de_la_deuda/L.shrfsp*100
	tabstat tasaEfectiva if anio <= `anio' & anio >= `anio'-5, save
	tempname tasaEfectiva_ari
	matrix `tasaEfectiva_ari' = r(StatTotal)
	replace tasaEfectiva = r(StatTotal)[1,1] if anio >= `anio'
	local tasaEfectiva = r(StatTotal)[1,1]

	* Scalar Costo_de_la_deuda (gascosto) *
	capture confirm scalar gascosto
	if _rc == 0 {
		replace estimacionCosto_de_la_deuda = scalar(gascosto)*Poblacion if anio == `anio'
		replace gastoCosto_de_la_deuda = estimacionCosto_de_la_deuda if anio == `anio'
		*replace estimacionGasto_pib = estimacionGasto_pib/pibY*100 if anio == `anio'

		* Reestimar la tasa efectiva para el año `anio' *
		replace tasaEfectiva = L.tasaEfectiva if anio >= `anio'
		format %20.0fc *Costo_de_la_deuda
	}
	else {
		*scalar gascosto = r(StatTotal)[1,1]/r(StatTotal)[1,2]*8539/9234
		*scalar gascostoPIB = r(StatTotal)[1,1]/r(StatTotal)[1,3]*100*3.329/3.600
	}

	* Reemplazar tasasEfectivas con el escalar tasasEfectiva *
	capture confirm scalar tasaEfectiva
	if _rc == 0 {
		replace tasaEfectiva = scalar(tasaEfectiva) if anio >= `anio'
		replace gastoCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio >= `anio'
	}
	else {
		scalar tasaEfectiva = `tasaEfectiva'		
	}


	**********************/
	** 5.7 Tipo de cambio *
	g depreciacion = tipoDeCambio-L.tipoDeCambio

	* Reemplazar depreciacion por el último valor observado para los años futuros *
	tabstat depreciacion if anio >= `anio'-5 & anio <= `anio', stat(mean) f(%20.3fc) save
	replace depreciacion = r(StatTotal)[1,1] if depreciacion == .

	* SHRFSP externo en USD *
	*g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	replace tipoDeCambio = L.tipoDeCambio + L.depreciacion if anio >= `anio' & tipoDeCambio == .
	replace shrfspExternoUSD = shrfspExterno/tipoDeCambio

	g efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)
	g difshrfsp = shrfsp - L.shrfsp - efectoTipoDeCambio - rfsp if anio >= 2009
	format shrfspExternoUSD efectoTipoDeCambio difshrfsp %20.0fc

	* Efecto acumulado del tipo de cambio y los rfsp *
	tabstat efectoTipoDeCambio rfsp difshrfsp if anio >= 2009, stat(sum) f(%20.0fc) save
	tempname ACT
	matrix `ACT' = r(StatTotal)


	*********************************
	** 5.8 Saldo final de la deuda **
	forvalues k=`=_N'(-1)1 {
		if shrfsp[`k'] != . & "`lastfound'" != "yes" {
			local obslast = `k'
			local lastfound = "yes"
		}
		if anio[`k'] == 2009 & "`lastfound'" == "yes" {
			local obsfirs = `k'
		}
		if anio[`k'] == `desde' {
			local obsdesde = `k'
		}
	}
	if "`lastfound'" == "yes" & "`obsfirs'" == "" {
		local obsfirs = 1
	}
	local shrfspobslast = shrfsp[`obslast']/pibY[`obslast']*100

	* Actualizacion de los saldos *
	if (`ACT'[1,1]+`ACT'[1,2]) != 0 {
		local actualizacion_geo = (((shrfsp[`obslast']-shrfsp[`obsfirs'])/(`ACT'[1,1]+`ACT'[1,2]))^(1/(`obslast'-`obsfirs'))-1)*100
	}
	else {
		local actualizacion_geo = 0
		noisily di in r "      {bf:WARNING}: Denominador cero en actualización geométrica. Usando 0%."
	}
	g actualizacion = `actualizacion_geo'

	* Otros rfsp (% del PIB) *
	foreach k of varlist rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones {
		replace `k'_pib = L.`k'_pib if `k'_pib == .
		replace `k' = `k'_pib/100*pibY if `k' == . //deflator
	}


	**********************************************************
	** 5.9 Iteraciones para el costo financiero de la deuda **
	forvalues k = `=`anio''(1)`=anio[_N]' {

		* Costo de la deuda *
		replace estimacionCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio == `k' //& estimacionCosto_de_la_deuda == .
		replace estimacionGasto = estimacionGasto + estimacionCosto_de_la_deuda if anio == `k'

		* RFSP *
		replace rfspBalance = -estimacionRecaudacion + estimacionGasto if anio == `k'
		replace rfsp = (rfspBalance + rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones) if anio == `k'

		* SHRFSP *
		replace shrfspExternoUSD = L.shrfspExterno/L.tipoDeCambio if anio == `k'
		replace efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)

		replace shrfspExterno = L.shrfspExterno*(1+`actualizacion_geo'/100) + efectoTipoDeCambio ///
			+ rfsp*L.shrfspExterno/L.shrfsp if anio == `k'
		replace shrfspInterno = L.shrfspInterno*(1+`actualizacion_geo'/100) ///
			+ rfsp*L.shrfspInterno/L.shrfsp if anio == `k'

		replace shrfsp = shrfspExterno + shrfspInterno if anio == `k'
	}

	replace shrfsp_pib = shrfsp/pibY*100 //if anio >= `anio'
	replace estimacionGasto_pib = estimacionGasto/pibY*100 //if anio >= `anio'

	replace rfsp_pib = rfsp/pibY*100

	replace rfspOtros = rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones
	replace rfspOtros_pib = rfspOtros/pibY*100
	format *_pib %7.1fc

	g shrfspPC = shrfsp/Poblacion/deflator
	g shrfspPC_mil = shrfspPC/1000
	format shrfspPC* %10.0fc


	****************
	** 5.10 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		twoway (bar rfsp_pib anio if anio < `anio' & anio >= `desde', barwidth(.75)) ///
			(bar rfsp_pib anio if anio >= `anio' & anio <= `end', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar rfspOtros_pib anio if anio < `anio' & anio >= `desde', barwidth(.75)) ///
			(bar rfspOtros_pib anio if anio >= `anio' & anio <= `end', barwidth(.75) ///
				pstyle(p3) lcolor(none) fintensity(50)) ///
			(connected rfsp_pib anio if anio >= `desde' & anio <= `end', ///
				mlabel(rfsp_pib) mlabposition(12) mlabcolor(black) pstyle(p2) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			if rfsp_pib != ., ///
			title({bf: Proyecci{c o'}n} de los RFSP) subtitle($pais) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			ytitle("% PIB") ///
			xtitle("") ///
			xlabel(`desde'(1)`end', noticks) ///
			legend(on order(1 3) label(1 "RFSP presupuestario") label(3 "Otros RFSP")) ///
			text(0 `desde' "{bf:Observado}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'+3' "{bf:$paqueteEconomico}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			name(Proy_rfsp, replace)
			
		if "$export" != "" {
			graph export `"$export/Proy_rfsp.png"', replace name(Proy_rfsp)
		}


		* Saldo de la deuda combinada *
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected shrfsp_pib anio if anio < `anio', ///
				mlabel(shrfsp_pib) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge)) ///
			(connected shrfsp_pib anio if anio >= `anio', ///
				mlabel(shrfsp_pib) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge)) ///			
			(bar shrfspPC_mil anio if anio < `anio', ///
				mlabel(shrfspPC_mil) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge) yaxis(2) pstyle(p1) barwidth(.75)) ///
			(bar shrfspPC_mil anio if anio >= `anio', ///
				mlabel(shrfspPC_mil) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge) yaxis(2) pstyle(p2) barwidth(.75)) ///
			if anio >= `aniomin', ///
			///title("`graphtitle'") ///
			///subtitle("Indicadores de la deuda") ///
			///caption("`graphfuente'") ///
			xtitle("") ///
			yscale(range(-50)) ///
			yscale(range(0 250) axis(2) lwidth(none)) ///
			ylabel(none, axis(2) noticks) ///
			ylabel(none, axis(1) noticks) ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`aniomin'(1)`end') ///
			legend(off label(1 "Como % del PIB") label(2 "Por persona ajustada")) ///
			text(`=shrfsp_pib[`obsdesde']*.925' `=anio[`obsdesde']' "{bf:Como % del PIB}", ///
				place(5) color("111 111 111") size(medsmall)) ///
			text(0 `=anio[`obsdesde']' "{bf:Por persona (miles `currency' `=aniovp')}", ///
				place(1) color(black) size(medsmall) yaxis(2) bcolor(white) box) ///
			name(Proy_combinado, replace)

		if "$export" != "" {
			graph export `"$export/Proy_combinado.png"', replace name(Proy_combinado)
		}
	}


	*****************
	** 5.11 Outputs **
	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio' & anio[`k'] >= 2013 {
				local proy_costo = "`proy_costo' `=string(`=gastoCosto_de_la_deuda[`k']/pibY[`k']*100',"%10.1fc")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_costo = "`proy_costo' `=string(`=estimacionCosto_de_la_deuda[`k']/pibY[`k']*100',"%10.1fc")',"
			}
		}
		local length_costo = strlen("`proy_costo'")
		capture log on output
		noisily di in w "PROYCOSTO: [`=substr("`proy_costo'",1,`=`length_costo'-1')']"
		capture log off output
	}


	*********************
	** 5.12 Al infinito **
	*drop estimaciongasto
	*reshape long gasto estimacion, i(anio) j(modulo) string
	*collapse (sum) gasto estimacion (mean) pibY deflator shrfsp* rfsp Poblacion if modulo != "ingresos" & modulo != "VP" & anio <= `end', by(anio) fast

	* Calcular tasa de crecimiento de largo plazo (robusto) *
	count if anio >= `anio'
	local obs_futuras = r(N)
	local periodo_LR = min(10, `obs_futuras'-1)
	if `periodo_LR' < 2 {
		local periodo_LR = 2
	}
	
	* Verificar que no haya valores cero antes de dividir *
	if estimacionGasto[_N-`periodo_LR'] > 0 & estimacionGasto[_N] > 0 {
		local grow_rate_LR = (((estimacionGasto[_N]/deflator[_N])/(estimacionGasto[_N-`periodo_LR']/deflator[_N-`periodo_LR']))^(1/`periodo_LR')-1)*100
	}
	else {
		* Tasa de crecimiento por defecto si hay problemas *
		local grow_rate_LR = 2.5
		noisily di in r "      {bf:WARNING}: Usando tasa de crecimiento por defecto (`grow_rate_LR'%) para gastos"
	}

	g gastoVP = estimacionGasto/(1+`discount'/100)^(anio-`anio')
	format gastoVP %20.0fc
	
	* Validar que grow_rate < discount para perpetuidad *
	if `grow_rate_LR' >= `discount' {
		noisily di in r "      {bf:ERROR}: Tasa de crecimiento gastos (`grow_rate_LR'%) >= tasa de descuento (`discount'%)"
		noisily di in r "      Ajustando tasa de crecimiento a `=`discount'-0.5'%"
		local grow_rate_LR = `discount' - 0.5
	}
	local gastoINF = gastoVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	tabstat gastoVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname gastoVP
	matrix `gastoVP' = r(StatTotal)

	noisily di in g "  (-) Gastos futuros en VP:" in y _col(35) %25.0fc `gastoINF'+`gastoVP'[1,1] in g " `currency'"	
	noisily di in g "      (*) Gasto INF:" in y _col(35) %25.0fc `gastoINF' in g " `currency'"
	noisily di in g "      (*) Gasto VP:" in y _col(35) %25.0fc `gastoVP'[1,1] in g " `currency'"
	noisily di in g "      (*) Growth rate LP:" in y _col(35) %25.4fc `grow_rate_LR' in g " %"

	* Save *
	*rename estimacion estimaciongastos
	tempfile basegastos
	save `basegastos'


	* Saldo de la deuda *
	noisily tabstat shrfsp deflator if anio == `anio', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)



	*****************************
	***                       ***
	**# 7 Fiscal Gap: Balance ***
	***                       ***
	****************************
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Balance futuro en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	

	noisily di in g "  (+) Deuda (" in y `=`anio'' in g "):" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Finan. wealth futuro en VP:" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Wealth/Ingresos futuros:" ///
		in y _col(35) %25.1fc -(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`estimacionINF'+`estimacionVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (=) Wealth/Gastos futuros:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`gastoINF'+`gastoVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (=) Wealth/PIB futuro:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/scalar(pibVPINF)*100 ///
		in g " %"
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Deuda (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc shrfsp_pib[_N] ///
		in g " % PIB"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Tasa Efectiva Promedio: " in y _col(35) %25.4fc scalar(tasaEfectiva) in g " %"
	noisily di in g "  (*) Discount rate:" in y _col(35) %25.4fc `discount' in g " %"
	noisily di in g "  (*) Actualización deuda:" in y _col(35) %25.4fc `actualizacion_geo' in g " %"





	****************************************/
	*** 6 Fiscal Gap: Cuenta Generacional ***
	*****************************************
	tabstat Poblacion0 Poblacion if (anio == `anio' | anio == `end'), stat(sum) save f(%20.0fc) by(anio)
	tempname poblacionACT poblacionEND
	matrix `poblacionACT' = r(Stat1)
	matrix `poblacionEND' = r(Stat2)


	******************
	** Poblacion VP **
	g poblacionVP = Poblacion0/(1+`discount'/100)^(anio-`anio')
	format poblacionVP %20.0fc

	tabstat poblacionVP if anio > `anio', stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)

	* Calcular tasa de crecimiento poblacional (robusto) *
	count if anio > `anio'
	local obs_futuras_pob = r(N)
	local periodo_LR_pob = min(10, `obs_futuras_pob')
	if `periodo_LR_pob' < 2 {
		local periodo_LR_pob = 2
	}
	
	if Poblacion0[_N-`periodo_LR_pob'] > 0 & Poblacion0[_N] > 0 {
		local grow_rate_LR_pob = (((Poblacion0[_N]/deflator[_N])/(Poblacion0[_N-`periodo_LR_pob']/deflator[_N-`periodo_LR_pob']))^(1/`periodo_LR_pob')-1)*100
	}
	else {
		local grow_rate_LR_pob = 1.0
		noisily di in r "      {bf:WARNING}: Usando tasa de crecimiento por defecto (`grow_rate_LR_pob'%) para población"
	}

	* Validar que grow_rate < discount para perpetuidad *
	if `grow_rate_LR_pob' >= `discount' {
		noisily di in r "      {bf:ERROR}: Tasa crecimiento población (`grow_rate_LR_pob'%) >= tasa de descuento (`discount'%)"
		noisily di in r "      Ajustando tasa de crecimiento a `=`discount'-0.5'%"
		local grow_rate_LR_pob = `discount' - 0.5
	}
	local poblacionINF = poblacionVP[_N]/(1-((1+`grow_rate_LR_pob'/100)/(1+`discount'/100)))

	noisily di _newline(2) in g "{bf: INEQUIDAD INTERGENERACIONAL:" in y " $pais `anio' }"
	*noisily di in g "  (*) Poblaci{c o'}n futura VP: " in y _col(35) %25.0fc `poblacionVP'[1,1] in g " personas"
	*noisily di in g "  (*) Poblaci{c o'}n futura INF: " in y _col(35) %25.0fc `poblacionINF' in g " personas"
	*noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaciones " in y "`anio'" in g ":" in y _col(35) %25.0fc (`shrfsp'[1,1]/`shrfsp'[1,2])/(`poblacionACT'[1,2]) in g " `currency' por persona"
	noisily di in g "  (*) Deuda generaciones " in y "`end'" in g ":" in y _col(35) %25.0fc (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2]) in g " `currency' por persona"
	local deudagenlast = (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2])

	* Inequidad intergeneracional *
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaci{c o'}n futura:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1] + `estimacionINF' + `estimacionVP'[1,1] - `gastoINF' - `gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"
	local deudageninf = -(-`shrfsp'[1,1] + `estimacionINF' + `estimacionVP'[1,1] - `gastoINF' - `gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF')
	noisily di in g "  (*) Inequidad intergeneracional:" ///
		in y _col(35) %25.0fc (`deudageninf'/`deudagenlast'-1)*100 ///
		in g " %"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad GA:" ///
			in y _col(35) %25.0fc ((-(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}


	** Output **
	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio' & anio[`k'] >= 2013 {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' null,"
			}
			if anio[`k'] == `anio' {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(`shrfspobslast',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(51.000,"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
			}
			if anio[`k'] > `anio' & anio[`k'] <= 2030 {
				local proy_shrfsp = "`proy_shrfsp' null,"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
			}
		}
		local length_shrfsp = strlen("`proy_shrfsp'")
		local length_shrfsp2 = strlen("`proy_shrfsp2'")
		capture log on output
		noisily di in w "PROYSHRFSP1: [`=substr("`proy_shrfsp'",1,`=`length_shrfsp'-1')']"
		noisily di in w "PROYSHRFSP2: [`=substr("`proy_shrfsp2'",1,`=`length_shrfsp2'-1')']"	
		noisily di in w "PROYSHRFSP3: [" ///
			%10.0f (`shrfsp'[1,1]/`shrfsp'[1,2])/(`poblacionACT'[1,2]) "," ///
			%10.0f (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2]) ///
			"]"
		noisily di in w "ANIOBASE: [`anio']"
		quietly log off output
	}



	************************/
	**** Touchdown!!! :) ****
	*************************
	timer off 11
	timer list 11
	noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t11)/r(nt11)',.1) in g " segs  " _dup(20) "."
}
end
