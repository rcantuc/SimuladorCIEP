program define FiscalGap
quietly {

	timer on 11
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	syntax [, NOGraphs Anio(int `aniovp') Update END(int 2100) ///
		ANIOMIN(int 2000) DIScount(real 5) DESDE(int `=`aniovp'-1')]



	*************
	***       ***
	**# 1 PIB ***
	***       ***
	*************
	PIBDeflactor, nographs nooutput
	replace Poblacion = Poblacion*lambda
	replace Poblacion0 = Poblacion0*lambda
	keep if anio <= `end'
	local currency = currency[1]
	tempfile PIB
	save `PIB'



	****************
	***          ***
	**# 2 SHRFSP ***
	***          ***
	****************
	SHRFSP, anio(`anio') nographs //update
	tempfile shrfsp
	save `shrfsp'



	********************
	***              ***
	**# 3 HOUSEHOLDS ***
	***              ***
	********************
	use "`c(sysdir_personal)'/users/$id/ingresos.dta", clear
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen update
	capture drop _*
	foreach k in Educación Pensiones Pensión_AM Salud Otros_gastos IngBasico Otras_inversiones Part_y_otras_Apor Energía {
		tabstat `k' [fw=factor], stat(sum) f(%20.0fc) save
		local k = subinstr("`k'","á","a",.)
		local k = subinstr("`k'","é","e",.)
		local k = subinstr("`k'","í","i",.)
		local k = subinstr("`k'","ó","o",.)
		local k = subinstr("`k'","ú","u",.)
		tempname HH`k'
		matrix `HH`k'' = r(StatTotal)
	}



	******************************
	***                        ***
	**# 4 Fiscal Gap: Ingresos ***
	***                        ***
	******************************

	** 4.1 Información histórica de los ingresos **
	LIF if divLIF != 10, anio(`anio') nographs by(divSIM) min(0) desde(`desde') //eofp //ilif
	local divSIM = r(divSIM)

	foreach k of local divSIM {
		local `k'C = r(`k'C)
		if ``k'C' > 5 {
			local `k'C = 5
		}
		if ``k'C' < -5 {
			local `k'C = -5
		}
		capture confirm scalar `k'
		if _rc != 0 {
			scalar `k' = r(`k')/scalar(pibY)*100
		}
	}
	collapse (sum) recaudacion, by(anio divSIM) fast
	decode divSIM, g(divCIEP)
	replace divCIEP = strtoname(divCIEP)

	** 4.2 Proyección futura de los ingresos **
	g modulo = ""
	foreach k of local divSIM {
		preserve
		use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/`k'REC.dta"', clear
		collapse estimacion contribuyentes, by(anio modulo aniobase)
		tsset anio

		tempvar estimacion
		g `estimacion' = estimacion
		replace estimacion = `estimacion'/L.`estimacion'*       /// Cambio demográfico (PerfilesSim.do)
			(scalar(`k'))/100*scalar(pibY)*                     /// Estimación como % del PIB (TasasEfectivas.ado)
			(1+``k'C'/100)^(anio-`anio')                        /// Tendencia de largo plazo (LIF.ado)
			if anio > `anio'

		g divCIEP = `"`=strtoname("`k'")'"'

		tempfile `k'
		save ``k''

		restore
		merge 1:1 (anio divCIEP) using  ``k'', nogen update replace
	}

	** 4.3 Actualizaciones **
	collapse (sum) recaudacion estimacionRecaudacion=estimacion if anio <= `end', by(anio divCIEP) fast
	merge m:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda Poblacion*) update keep(matched)

	replace estimacionRecaudacion = estimacionRecaudacion*deflator*lambda
	replace recaudacion = 0 if recaudacion == .
	replace estimacionRecaudacion = 0 if estimacionRecaudacion == .
	format estimacion* %20.0fc

	g recaudacion_pib = recaudacion/pibY*100 				
	g estimacionRecaudacion_pib = estimacionRecaudacion/pibY*100 

	g divSIM = "Impuestos laborales" if divCIEP == "CUOTAS" | divCIEP == "ISRAS" | divCIEP == "ISRPF"
	replace divSIM = "Impuestos al consumo" if divCIEP == "IEPSNP" | divCIEP == "IEPSP" | divCIEP == "IVA" | divCIEP == "ISAN" | divCIEP == "IMPORT"
	replace divSIM = "Impuestos al capital" if divCIEP == "ISRPM" | divCIEP == "OTROSK"
	replace divSIM = "Organismos y empresas" if divCIEP == "CFE" | divCIEP == "FMP" | divCIEP == "IMSS" | divCIEP == "ISSSTE" | divCIEP == "PEMEX"


	****************
	** 4.4 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		//noisily tabstat recaudacion_pib estimacionRecaudacion_pib if anio >= `aniomin', stat(sum) by(anio) save
		graph bar (sum) recaudacion_pib if anio < `anio' & anio >= `aniomin', ///
			over(divSIM) ///
			over(anio, gap(0)) ///
			ytitle("% PIB") ///
			stack asyvar ///
			text(`text', size(vsmall)) ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_ingresos1) ///
			title(Observado)

		graph bar (sum) estimacionRecaudacion_pib if anio >= `anio', ///
			over(divSIM) ///
			over(anio, gap(0)) ///
			ytitle("") ylabel(, labcolor(white)) ///
			stack asyvar ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_ingresos2) ///
			title(Proyectado)

		grc1leg Proy_ingresos1 Proy_ingresos2, ycommon ///
			title({bf:Ingresos p{c u'}blicos}) ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			name(Proy_ingresos, replace) ///

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
		collapse (sum) recaudacion_pib estimacionRecaudacion_pib if anio <= `end', by(anio divSIM) fast
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				if divSIM[`k'] == "Impuestos laborales" {
					local proy_laborales = "`proy_laborales' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Impuestos al consumo" {
					local proy_consumo  = "`proy_consumo' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Impuestos al capital" {
					local proy_capital  = "`proy_capital' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Organismos y empresas" {
					local proy_organismos  = "`proy_organismos' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				if divSIM[`k'] == "Impuestos laborales" {
					local proy_laborales = "`proy_laborales' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Impuestos al consumo" {
					local proy_consumo  = "`proy_consumo' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Impuestos al capital" {
					local proy_capital  = "`proy_capital' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Organismos y empresas" {
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
	noisily di _newline(2) in g "{bf: FISCAL GAP:" in y " $pais `anio' }"

	local grow_rate_LR = (((estimacionRecaudacion[_N]/deflator[_N])/(estimacionRecaudacion[_N-10]/deflator[_N-10]))^(1/10)-1)*100

	g estimacionVP = estimacionRecaudacion/(1+`discount'/100)^(anio-`anio')
	format estimacionVP %20.0fc
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

	*********************************************
	** 5.1 Información histórica de los gastos **
	PEF if transf_gf == 0 & anio >= `desde', anio(`anio') by(divCIEP) nographs desde(`desde')
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


	*****************************************
	** 5.2 Proyección futura de los gastos **
	g modulo = ""
	foreach k of local divCIEP {
		if `"`=strtoname("`k'")'"' != "Costo_de_la_deuda" & `"`=strtoname("`k'")'"' != "Cuotas_ISSSTE" {
			preserve
			use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/`=strtoname("`k'")'REC.dta"', clear
			collapse estimacion contribuyentes, by(anio modulo aniobase)
			tsset anio
			
			tempvar estimacion
			g `estimacion' = estimacion
			replace estimacion = `estimacion'/L.`estimacion'*     /// Cambio demográfico
				`HH`=strtoname("`k'")''[1,1]* 			          /// Gasto total (GastoPC.ado)
				(1+``=strtoname("`k'")'C'/100)^(anio-`anio')      /// Tendencia de largo plazo (PEF.ado)
				if anio > `anio'

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
	replace estimacionGasto = estimacionGasto*deflator*lambda
	replace gasto = 0 if gasto == .
	replace estimacionGasto = 0 if estimacionGasto == .

	g gasto_pib = gasto/pibY*100
	g estimacionGasto_pib = estimacionGasto/pibY*100

	g divSIM = subinstr(divCIEP,"_"," ",.)
	replace divSIM = "Otros gastos" if divSIM == "IngBasico" | divSIM == "Part y otras Apor" | divSIM == "Cuotas ISSSTE"
	replace divSIM = "Pensiones" if divSIM == "Pension AM"


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

		grc1leg Proy_gastos1 Proy_gastos2, ycommon ///
			title({bf:Gasto p{c u'}blico primario}) ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			name(Proy_gastos, replace) ///

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

	* Reemplazar tasaEfectiva con la media artimética desde el año `desde' *
	tabstat tasaEfectiva if anio <= `anio' & anio >= `desde', save
	tempname tasaEfectiva_ari
	matrix `tasaEfectiva_ari' = r(StatTotal)
	replace tasaEfectiva = r(StatTotal)[1,1] if anio >= `anio'
	local tasaEfectiva = r(StatTotal)[1,1]

	* Reemplazar Costo_de_la_deuda con el escalar gascosto si fue provisto desde los parámetros en SIM.do *
	g gastoCosto_de_la_deuda = costodeudaInterno + costodeudaExterno
	g estimacionCosto_de_la_deuda = gastoCosto_de_la_deuda if gastoCosto_de_la_deuda != .
	format estimacion* %20.0fc
	capture confirm scalar gascosto
	if _rc == 0 {
		replace estimacionCosto_de_la_deuda = scalar(gascosto)*Poblacion if anio == `anio'
		replace gastoCosto_de_la_deuda = estimacionCosto_de_la_deuda if anio == `anio'
		replace estimacionGasto_pib = estimacionGasto_pib/pibY*100 if anio == `anio'

		* Reestimar la tasa efectiva para el año `anio' *
		replace tasaEfectiva = gastoCosto_de_la_deuda/L.shrfsp*100 if anio == `anio'
		format %20.0fc *Costo_de_la_deuda
	}

	* Reemplazar tasasEfectivas con el escalar tasasEfectiva si fue provisto desde los parámetros en SIM.do *
	capture confirm scalar tasaEfectiva
	if _rc == 0 {
		replace tasaEfectiva = scalar(tasaEfectiva) if anio >= `anio'
	}
	else {
		replace tasaEfectiva = `tasaEfectiva' if anio >= `anio'
		scalar tasaEfectiva = `tasaEfectiva'
	}


	***********************
	** 5.3 Tipo de cambio *
	g depreciacion = tipoDeCambio-L.tipoDeCambio

	* Reemplazar depreciacion por el último valor observado para los años futuros *
	replace depreciacion = L.depreciacion if depreciacion == .

	* SHRFSP externo en USD *
	g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	replace tipoDeCambio = L.tipoDeCambio + depreciacion if anio >= `anio'
	replace shrfspExternoUSD = shrfspExterno/tipoDeCambio

	g efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)
	g difshrfsp = shrfsp - L.shrfsp - efectoTipoDeCambio - rfsp if anio >= 2009
	format shrfspExternoUSD efectoTipoDeCambio difshrfsp %20.0fc

	* Efecto acumulado del tipo de cambio y los rfsp *
	tabstat efectoTipoDeCambio rfsp difshrfsp if anio >= 2009, stat(sum) f(%20.0fc) save
	tempname ACT
	matrix `ACT' = r(StatTotal)


	*********************************
	** 5.4 Saldo final de la deuda **
	forvalues k=`=_N'(-1)1 {
		if shrfsp[`k'] != . & "`lastfound'" != "yes" {
			local obslast = `k'
			local lastfound = "yes"
		}
		if anio[`k'] == 2009 & "`lastfound'" == "yes" {
			local obsfirs = `k'
			continue, break
		}
	}
	if "`lastfound'" == "yes" & "`obsfirs'" == "" {
		local obsfirs = 1
	}
	local shrfspobslast = shrfsp[`obslast']/pibY[`obslast']*100

	* Actualizacion de los saldos *
	local actualizacion_geo = 0 // (((shrfsp[`obslast']-shrfsp[`obsfirs'])/(`ACT'[1,1]+`ACT'[1,2]))^(1/(`obslast'-`obsfirs'))-1)*100
	g actualizacion = 0 // `actualizacion_geo'

	* Otros rfsp (% del PIB) *
	foreach k of varlist rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones {
		g `k'_pib = `k'/pibY*100 //deflator
		replace `k'_pib = L.`k'_pib if `k'_pib == .
		replace `k' = `k'_pib/100*pibY if `k' == . //deflator
	}


	**********************************************************
	** 5.5 Iteraciones para el costo financiero de la deuda **
	forvalues k = `=`anio''(1)`=anio[_N]' {

		* Costo de la deuda *
		*replace estimacionCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio == `k'
		replace estimacionGasto = estimacionGasto + estimacionCosto_de_la_deuda if anio == `k'

		* RFSP *
		replace rfspBalance = estimacionRecaudacion - estimacionGasto if anio == `k'
		replace rfsp = rfspBalance + rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones if anio == `k'

		* SHRFSP *
		replace shrfspExternoUSD = L.shrfspExterno/L.tipoDeCambio if anio == `k'
		replace efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)

		replace shrfspExterno = L.shrfspExterno*(1+`actualizacion_geo'/100) + efectoTipoDeCambio ///
			- rfsp*L.shrfspExterno/L.shrfsp if anio == `k'
		replace shrfspInterno = L.shrfspInterno*(1+`actualizacion_geo'/100) ///
			- rfsp*L.shrfspInterno/L.shrfsp if anio == `k'

		replace shrfsp = shrfspExterno + shrfspInterno if anio == `k'
	}

	replace shrfsp_pib = shrfsp/pibY*100 //if anio >= `anio'
	replace estimacionGasto_pib = estimacionGasto/pibY*100 //if anio >= `anio'

	g rfsp_pib = rfsp/pibY*100
	format *_pib %7.1fc

	g shrfspPC = shrfsp/Poblacion/deflator
	format shrfspPC %10.0fc


	****************
	** 5.6 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		twoway (area rfsp_pib anio if anio < `anio' & anio >= `aniomin') ///
			(area rfsp_pib anio if anio >= `anio' & anio <= `end'), ///
			yscale(range(0)) ///
			ytitle(% PIB) ///
			xtitle("") ///
			xlabel(`aniomin'(1)`=round(anio[_N],10)') ///
			xline(`=`anio'+.5') ///
			legend(off) ///
			///text(`=rfsp_pib[`obs`anio_last'']*.1' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", color(white) placement(e)) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			title({bf: Proyecci{c o'}n} de los RFSP) subtitle($pais) ///
			name(Proy_rfsp, replace)
	}


	*****************
	** 5.7 Outputs **
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
	** 5.8 Al infinito **
	*drop estimaciongasto
	*reshape long gasto estimacion, i(anio) j(modulo) string
	*collapse (sum) gasto estimacion (mean) pibY deflator shrfsp* rfsp Poblacion if modulo != "ingresos" & modulo != "VP" & anio <= `end', by(anio) fast

	local grow_rate_LR = (((estimacionGasto[_N]/deflator[_N])/(estimacionGasto[_N-10]/deflator[_N-10]))^(1/10)-1)*100

	g gastoVP = estimacionGasto/(1+`discount'/100)^(anio-`anio')
	format gastoVP %20.0fc
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





	*****************************
	***                       ***
	**# 7 Fiscal Gap: Balance ***
	***                       ***
	*****************************
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Balance futuro en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	

	* Saldo de la deuda *
	tabstat shrfsp deflator if anio == `anio', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)

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

	if "`nographs'" != "nographs" & "$nographs" != "nographs" {

		* Saldo de la deuda *
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} de la deuda"
			local graphfuente "{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected shrfsp_pib anio if shrfsp_pib != . & anio < `anio' & anio >= `aniomin', mlabel(shrfsp_pib) mlabpos(0) mlabcolor(black) mlabgap(0pt)) ///
			(connected shrfsp_pib anio if anio >= `anio' & anio <= `end', mlabel(shrfsp_pib) mlabpos(0) mlabcolor(black) mlabgap(0pt)), ///
			title("`graphtitle'") ///
			subtitle("{bf:Como % del PIB}") ///
			caption("`graphfuente'") ///
			xtitle("") ytitle(% PIB) ///
			xlabel(`aniomin'(1)`end') ///
			yscale(range(0)) ///
			legend(off) ///
			///text(`=shrfsp_pib[`obs`anio_last'']*.1' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", color(white) placement(e)) ///
			name(Proy_shrfsp, replace)

		if "$export" != "" {
			graph export `"$export/Proy_shrfsp.png"', replace name(Proy_shrfsp)
		}


		* Saldo de la deuda por persona *
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} por persona"
			local graphfuente "{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected shrfspPC anio if shrfsp_pib != . & anio < `anio'-1 & anio >= `aniomin', mlabel(shrfspPC) mlabpos(0) mlabcolor(black) mlabgap(0pt)) ///
			(connected shrfspPC anio if anio >= `anio'-1 & anio <= `end', mlabel(shrfspPC) mlabpos(0) mlabcolor(black) mlabgap(0pt)), ///
			title(`graphtitle') ///
			subtitle("{bf:Por persona ajustada}") ///
			caption("`graphfuente'") ///
			xtitle("") ///
			ytitle("`currency' `aniovp' por persona") ///
			ylabel(0(50000)200000, format(%10.0fc)) ///
			xlabel(`aniomin'(1)`end') ///
			legend(off) ///
			text(`textPC2', color(black) placement(c) size(small)) ///
			name(Proy_shrfsppc, replace)

		if "$export" != "" {
			graph export `"$export/Proy_shrfsppc.png"', replace name(Proy_shrfsppc)
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

		twoway (connected shrfsp_pib anio, mlabel(shrfsp_pib) mlabpos(0) mlabcolor(black) mlabgap(0)) ///
			(connected shrfspPC anio, mlabel(shrfspPC) mlabpos(0) mlabcolor(black) mlabgap(0) yaxis(2)) if anio >= `desde', ///
			title("`graphtitle'") ///
			///subtitle("{bf:Indicadores de la deuda}") ///
			caption("`graphfuente'") ///
			xtitle("") ///
			yscale(range(75)) ///
			yscale(range(175000) axis(2) lwidth(none)) ///
			ylabel(, axis(2) noticks) ///
			ytitle("Como % del PIB") ///
			ytitle("`currency' `aniovp'", axis(2)) ///
			xlabel(`desde'(1)`end') ///
			legend(label(1 "Como % del PIB") label(2 "Por persona ajustada")) ///
			name(Proy_combinado, replace)

		if "$export" != "" {
			graph export `"$export/Proy_combinado.png"', replace name(Proy_combinado)
		}
	}

	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Deuda (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc shrfsp_pib[_N] ///
		in g " % PIB"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Tasa Efectiva Promedio: " in y _col(35) %25.4fc scalar(tasaEfectiva) in g " %"
	noisily di in g "  (*) Discount rate:" in y _col(35) %25.4fc `discount' in g " %"
	noisily di in g "  (*) Actualización deuda:" in y _col(35) %25.4fc `actualizacion_geo' in g " %"





	*****************************************
	*** 5 Fiscal Gap: Cuenta Generacional ***
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

	local poblacionINF = poblacionVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	noisily di _newline(2) in g "{bf: INEQUIDAD INTERGENERACIONAL:" in y " $pais `anio' }"
	noisily di in g "  (*) Poblaci{c o'}n futura VP: " in y _col(35) %25.0fc `poblacionVP'[1,1] in g " personas"
	noisily di in g "  (*) Poblaci{c o'}n futura INF: " in y _col(35) %25.0fc `poblacionINF' in g " personas"
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaciones `anio':" in y _col(35) %25.0fc (`shrfsp'[1,1]/`shrfsp'[1,2])/(`poblacionACT'[1,2]) in g " `currency' por persona"
	noisily di in g "  (*) Deuda generaciones `end':" in y _col(35) %25.0fc (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2]) in g " `currency' por persona"

	* Inequidad intergeneracional *
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaci{c o'}n futura:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1] + `estimacionINF' + `estimacionVP'[1,1] - `gastoINF' - `gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad GA:" ///
			in y _col(35) %25.0fc ((-(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}


	** Output **
	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio'-1 & anio[`k'] >= 2013 {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' null,"
			}
			if anio[`k'] == `anio' {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(`shrfspobslast',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(51.000,"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
			}
			if anio[`k'] > `anio'-1 & anio[`k'] <= 2030 {
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
