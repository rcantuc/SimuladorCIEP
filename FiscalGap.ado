program define FiscalGap
timer on 11
quietly {

	*****************
	*** 0 ANIO VP ***
	*****************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, NOGraphs Anio(int `aniovp') BOOTstrap(int 1) Update END(int 2100) ///
		ANIOMIN(int 2000) DIScount(real 5) DESDE(int `=`aniovp'-1')]



	*************
	*** 1 PIB ***
	*************
	PIBDeflactor, nographs nooutput
	keep if anio <= `end'
	local currency = currency[1]
	local anio_last = `anio'
	forvalues k = 1(1)`=_N' {
		if anio[`k'] == `anio_last' {
			local obs`anio_last' = `k'
			continue, break
		}
	}
	tempfile PIB
	save `PIB'



	****************
	*** 2 SHRFSP ***
	****************
	SHRFSP, anio(`anio') nographs //update
	tempfile shrfsp
	save `shrfsp'



	*******************
	*** 3 HOUSEHOLDS **
	*******************
	use "`c(sysdir_personal)'/users/$id/households.dta", clear
	capture drop _*
	foreach k in Educación Pension Pensión_Bienestar Salud Otros IngBasico Inversión Otras_Part_y_Apor Energía {
		tabstat `k' [fw=factor], stat(sum) f(%20.0fc) save
		tempname HH`k'
		matrix `HH`k'' = r(StatTotal)
	}



	******************************
	*** 4 Fiscal Gap: Ingresos ***
	******************************
	LIF if divLIF != 10, base
	levelsof divSIM, local(divSIM)
	
	LIF if divLIF != 10, anio(`anio') nographs by(divSIM) min(0) desde(`desde') //ilif //eofp
	local j = 0
	foreach k of local divSIM {
		local label`k' : label divSIM `k'
		local `label`k''C = r(`label`k''C)
		if ``label`k''C' > 15 {
			local `label`k''C = 15
		}
		if ``label`k''C' < -15 {
			local `label`k''C = -15
		}

		capture confirm scalar `k'
		if _rc != 0 {
			scalar `label`k'' = r(`label`k'')/scalar(pibY)*100
		}
		local ++j
	}

	collapse (sum) recaudacion, by(anio divSIM) fast
	g modulo = ""
	foreach k of local divSIM {
		local divSIM`k' : label divSIM `k'
		if "`divSIM`k''" != "FMP" & "`divSIM`k''" != "PEMEX" {
			preserve

			use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/`divSIM`k''REC.dta"', clear
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion, by(anio modulo aniobase)

			tempvar estimacion
			g `estimacion' = estimacion
			replace estimacion = `estimacion'/L.`estimacion'*(scalar(`divSIM`k''))/100*scalar(pibY)*(1+``divSIM`k''C'/100)^(anio-`anio') if anio >= `anio' //& abs(``divSIM`k''C'/100) < .4

			g divSIM = `k'
			replace modulo = "`divSIM`k''"

			tempfile `divSIM`k''
			save ``divSIM`k'''

			restore
			merge 1:1 (anio divSIM) using  ``divSIM`k''', nogen update replace
		}
		else {
			preserve

			use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/`divSIM`k''REC.dta"', clear
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion, by(anio modulo aniobase)

			tempvar estimacion
			g `estimacion' = estimacion
			replace estimacion = `estimacion'/L.`estimacion'*(scalar(`divSIM`k''))/100*scalar(pibY)*(1+``divSIM`k''C'/100)^(anio-`anio') if anio >= `anio' //& abs(``divSIM`k''C'/100) < .4

			g divSIM = `k'
			replace modulo = "`divSIM`k''"

			tempfile `divSIM`k''
			save ``divSIM`k'''

			restore
			merge 1:1 (anio divSIM) using  ``divSIM`k''', nogen update replace			
		}
	}
	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) recaudacion estimacion (max) pibYR deflator lambda Poblacion, by(anio modulo)

	* Actualizaciones *
	replace estimacion = 0 if estimacion == .
	replace estimacion = estimacion*lambda
	replace recaudacion = 0 if recaudacion == .
	replace recaudacion = recaudacion/deflator

	* Reshape *
	reshape wide recaudacion estimacion, i(anio) j(modulo) string
	format recaudacion* estimacion* %20.0fc
	tsset anio



	***************/
	** 3.1 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		tempvar recaccum estaccum
		g `recaccum' = 0
		g `estaccum' = 0
		foreach k of local divSIM {
			tempvar rec`divSIM`k'' est`divSIM`k''
			g `rec`divSIM`k''' = recaudacion`divSIM`k''/1000000000000 + `recaccum'
			replace `recaccum' = recaudacion`divSIM`k''/1000000000000 + `recaccum'
			local varrec "`rec`divSIM`k''' `varrec'"

			g `est`divSIM`k''' = estimacion`divSIM`k''/1000000000000 + `estaccum'
			replace `estaccum' = estimacion`divSIM`k''/1000000000000 + `estaccum'
			local varest "`est`divSIM`k''' `varest'"
			local legend `"label(`j' "`divSIM`k''") `legend'"'
			local --j
		}

		twoway (area `varrec' anio if anio <= `anio' & anio >= `aniomin') ///
			(area `varest' anio if anio > `anio'), ///
			legend(rows(1) `legend') ///
			xlabel(`aniomin'(1)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`=`anio'+.5') ///
			text(`=`kpublico2'[`obs`anio_last'']*.0618' `=`anio'-1.5' "{bf:Observado}", ///
			place(n) color(white)) ///
			text(`=`kpublico2'[`obs`anio_last'']*.0618' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", ///
			place(ne) color(white)) ///
			yscale(range(0)) ///
			title({bf:Proyecci{c o'}n} de los ingresos p{c u'}blicos) ///
			subtitle($pais) ///
			xtitle("") ytitle(billones `currency' `anio') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			name(Proy_ingresos, replace)
		if "$export" != "" {
			graph export `"$export/Proy_ingresos.png"', replace name(Proy_ingresos)
		}
	}

	*****************************
	** Actualizar con un ciclo **
	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_consumo  = "`proy_consumo' `=string(`=recaudacionConsumo[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_consumo  = "`proy_consumo' `=string(`=estimacionConsumo[`k']/1000000000000',"%10.3f")',"
			}
		}
		local length_consumo = strlen("`proy_consumo'")
		capture log on output
		noisily di in w "PROYCONSU: [`=substr("`proy_consumo'",1,`=`length_consumo'-1')']"
		capture log off output
	}


	*********************
	** 3.2 Al infinito **
	noisily di _newline(2) in g "{bf: FISCAL GAP:" in y " $pais `anio' }"

	reshape long recaudacion estimacion, i(anio) j(modulo) string
	collapse (sum) recaudacion estimacion (mean) pibYR deflator, by(anio) fast

	local grow_rate_LR = ((pibYR[_N]/pibYR[_N-10])^(1/10)-1)*100
	g estimacionVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format estimacionVP %20.0fc
	local estimacionINF = estimacionVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	tabstat estimacionVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname estimacionVP
	matrix `estimacionVP' = r(StatTotal)

	noisily di in g "  (+) Ingresos futuros en VP:" in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] in g " `currency'"
	*noisily di in g "  (*) Estimacion INF:" in y _col(35) %25.0fc `estimacionINF' in g " `currency'"
	*noisily di in g "  (*) Estimacion VP:" in y _col(35) %25.0fc `estimacionVP'[1,1] in g " `currency'"
	
	* Save *
	rename estimacion estimacioningresos
	tempfile baseingresos
	save `baseingresos'



	****************************
	*** 4 Fiscal Gap: Gastos ***
	****************************
	PEF if transf_gf == 0 & anio >= 2013 & divCIEP != -1, anio(`anio') by(divCIEP) nographs desde(`desde')
	local divCIEP "`=r(divCIEP)'"
	foreach k of local divCIEP {
		local `k' = r(`k')
		local `k'C = r(`k'C)
		if ``k'C' > 15 {
			local `k'C = 15
		}
		if ``k'C' < -15 {
			local `k'C = -15
		}
	}

	g divCIEP = resumido
	label values divCIEP labelresumido

	collapse (sum) gasto, by(anio divCIEP) fast
	g modulo = ""

	local totlabels = 0
	levelsof divCIEP, local(divCIEP)
	foreach k of local divCIEP {
		local ++totlabels
		local divCIEP`k' : label labelresumido `k'
		if "`divCIEP`k''" != "Costo de la deuda" & "`divCIEP`k''" != "Otras Part y Apor" & "`divCIEP`k''" != "Energía" {

			preserve

			use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/`=strtoname("`divCIEP`k''")'REC.dta"', clear
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			tempvar estimacion
			g `estimacion' = estimacion
			capture confirm matrix `HH`=strtoname("`divCIEP`k''")''
			if _rc == 0 {
				replace estimacion = `estimacion'/L.`estimacion'*`HH`=strtoname("`divCIEP`k''")''[1,1]*(1+``=strtoname("`divCIEP`k''")'C'/100)^(anio-`anio') if anio >= `anio' //& abs(``=strtoname("`divCIEP`k''")'C') < .4
			}
			else {
				replace estimacion = `estimacion'/L.`estimacion'*``=strtoname("`divCIEP`k''")''*(1+``=strtoname("`divCIEP`k''")'C'/100)^(anio-`anio') if anio >= `anio' //& abs(``=strtoname("`divCIEP`k''")'C') < .4
			}

			g divCIEP = `k'
			replace modulo = "`divCIEP`k''"

			tempfile `divCIEP`k''
			save ``divCIEP`k'''

			restore
			merge 1:1 (anio divCIEP) using ``divCIEP`k''', nogen update replace
		}
		else if "`divCIEP`k''" != "Costo de la deuda" {
			preserve

			use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/`=strtoname("`divCIEP`k''")'REC.dta"', clear
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			tempvar estimacion
			g `estimacion' = estimacion
			capture confirm matrix `HH`=strtoname("`divCIEP`k''")''
			if _rc == 0 {
				replace estimacion = `estimacion'/L.`estimacion'*`HH`=strtoname("`divCIEP`k''")''[1,1] if anio >= `anio'				
			}
			else {
				replace estimacion = `estimacion'/L.`estimacion'*``=strtoname("`divCIEP`k''")'' if anio >= `anio'
			}

			g divCIEP = `k'
			replace modulo = "`divCIEP`k''"

			tempfile `divCIEP`k''
			save ``divCIEP`k'''

			restore
			merge 1:1 (anio divCIEP) using ``divCIEP`k''', nogen update replace
		}
		else {
			replace modulo = "`divCIEP`k''" if divCIEP == `k'
		}
	}

	** Ingreso basico **
	preserve
	use `"`c(sysdir_personal)'/users/ciepmx/bootstraps/1/IngBasicoREC.dta"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
	collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

	tempvar estimacion
	g `estimacion' = estimacion
	capture confirm matrix `HH`=strtoname("`divCIEP`k''")''
	if _rc == 0 {
		replace estimacion = `estimacion'/L.`estimacion'*`HH`=strtoname("`divCIEP`k''")''[1,1] if anio >= `anio'				
	}

	g divCIEP = 99
	replace modulo = "ingbasico"

	tempfile ingbasico
	save `ingbasico'


	** We are back! **
	restore
	merge 1:1 (anio divCIEP) using `ingbasico', nogen update replace
	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) gasto estimacion (max) pibYR deflator lambda Poblacion, by(anio modulo) fast



	*********************
	** Actualizaciones **
	replace estimacion = 0 if estimacion == .
	replace estimacion = estimacion*lambda
	replace gasto = 0 if gasto == .
	replace gasto = gasto/deflator

	* Reshape *
	replace modulo = strtoname(modulo)
	reshape wide gasto estimacion, i(anio) j(modulo) string
	format gasto* estimacion* %20.0fc
	tsset anio

	* Energía (supuesto: como % PIB) *
	*capture replace estimacionEnergía = (gascfe+gaspemex+gassener)*Poblacion if anio == `anio'
	*g EnergíaPIB = estimacionEnergía/pibYR*100
	*replace EnergíaPIB = L.EnergíaPIB if EnergíaPIB == .
	*replace estimacionEnergía = EnergíaPIB/100*pibYR if estimacionEnergía == .


	******************************/
	** DEUDA Y COSTO DE LA DEUDA **
	merge 1:1 (anio) using `shrfsp', nogen keep(matched) keepus(shrfsp* rfsp* /*nopresupuestario*/ tipoDeCambio tasaEfectiva costodeuda*)
	merge 1:1 (anio) using `baseingresos', nogen

	* Costo de la deuda *
	tabstat tasaEfectiva if anio <= `anio'-1 & anio >= `anio'-2, save
	tempname tasaEfectiva_ari
	matrix `tasaEfectiva_ari' = r(StatTotal)
	replace tasaEfectiva = `tasaEfectiva_ari'[1,1] if anio >= `anio' //& tasaEfectiva == .

	* Simulacion *
	capture confirm scalar gascosto
	if _rc == 0 {
		replace estimacionCosto_de_la_deuda = scalar(gascosto)*Poblacion if anio == `anio'
		replace gastoCosto_de_la_deuda = scalar(gascosto)*Poblacion if anio == `anio'
		replace tasaEfectiva = gastoCosto_de_la_deuda/L.shrfsp*100 if anio == `anio'
	}

	capture confirm existence $tasaEfectiva
	if _rc == 0 {
		replace tasaEfectiva = $tasaEfectiva if anio >= `anio'
	}

	* Depreciacion *
	g depreciacion = tipoDeCambio-L.tipoDeCambio
	replace depreciacion = L.depreciacion if depreciacion == .

	g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	replace tipoDeCambio = L.tipoDeCambio + depreciacion if anio >= `anio'
	replace shrfspExternoUSD = shrfspExterno/tipoDeCambio

	g efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)
	g difshrfsp = shrfsp - L.shrfsp - efectoTipoDeCambio
	format shrfspExternoUSD efectoTipoDeCambio difshrfsp %20.0fc

	tabstat efectoTipoDeCambio rfsp, stat(sum) f(%20.0fc) save
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
	local actualizacion_geo = (((shrfsp[`obslast']-shrfsp[`obsfirs'])/(`ACT'[1,1]+`ACT'[1,2]))^(1/(`obslast'-`obsfirs'))-1)*100
	g actualizacion = `actualizacion_geo'

	* MXN Reales *
	replace rfsp = rfsp/deflator
	replace shrfsp = shrfsp/deflator

	* Otros rfsp (% del PIB) *
	foreach k of varlist rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones {
		g `k'_pib = `k'/pibYR*100
		replace `k'_pib = L.`k'_pib if `k'_pib == .
		replace `k' = `k'_pib/100*pibYR if `k' == .
	}

	***************
	* Iteraciones *
	***************
	forvalues k = `=`anio''(1)`=anio[_N]' {

		* Costo de la deuda *
		replace estimacionCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio == `k'

		* RFSP *
		replace rfspBalance = estimacionCosto_de_la_deuda + estimacionEducación  ///
			+ estimacionEnergía + estimacionInversión + estimacionOtras_Part_y_Apor ///
			+ estimacionOtros + estimacionPensiones + estimacionPensión_AM ///
			+ estimacionSalud + estimacioningbasico - estimacioningresos if anio == `k'
		replace rfsp = rfspBalance + rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones if anio == `k'

		* SHRFSP *
		replace shrfspExternoUSD = L.shrfspExterno/L.tipoDeCambio if anio == `k'
		replace efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)

		replace shrfspExterno = L.shrfspExterno*(1+`actualizacion_geo'/100*0) + efectoTipoDeCambio ///
			+ rfsp*L.shrfspExterno/L.shrfsp if anio == `k'
		replace shrfspInterno = L.shrfspInterno*(1+`actualizacion_geo'/100*0) ///
			+ rfsp*L.shrfspInterno/L.shrfsp if anio == `k'

		replace shrfsp = shrfspExterno + shrfspInterno if anio == `k'
	}

	g rfsp_pib = rfsp/pibYR*100
	replace shrfsp_pib = shrfsp/pibYR*100 //if anio >= `anio'
	g shrfspPC = shrfsp/Poblacion


	****************
	** 4.1 Graphs **
	tempvar prev_var prev_var2
	g `prev_var' = 0
	g `prev_var2' = 0
	local j = `totlabels'
	local style = 1
	foreach k of local divCIEP {
		tempvar `k'g `k'g2
		g ``k'g' = `prev_var' + gasto`=strtoname("`divCIEP`k''")'/1000000000000
		replace `prev_var' = ``k'g'
		local gastovar `"``k'g' `gastovar'"'
		local gastolab `"`gastolab' label(`j' "`divCIEP`k''")"'
		local --j

		g ``k'g2' = `prev_var2' + estimacion`=strtoname("`divCIEP`k''")'/1000000000000
		replace `prev_var2' = ``k'g2'
		local estimvar `"``k'g2' `estimvar'"'
		local estimsty "`estimsty' p`style'"
		local order "`order' `style'"
		local ++style
	}

	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		twoway (area `gastovar' anio if anio <= `anio' & anio >= `aniomin') ///
			(area `estimvar' anio if anio > `anio', astyle(`estimsty')) if anio >= `aniomin', ///
			legend(cols(9) `gastolab' order(`order')) ///
			xlabel(`aniomin'(1)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`=`anio'+.5') ///
			text(`=`otrosg'[`obs`anio_last'']*.0618' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", place(ne) color(white)) ///
			yscale(range(0)) ///
			title({bf:Proyecci{c o'}n} del gasto p{c u'}blico) ///
			subtitle($pais) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			xtitle("") ytitle(billones `currency' `anio') ///
			name(Proy_gastos, replace)

		if "$export" != "" {
			graph export `"$export/Proy_gastos.png"', replace name(Proy_gastos)
		}

		twoway (area rfsp_pib anio if anio <= `anio' & anio >= `aniomin') ///
			(area rfsp_pib anio if anio > `anio' & anio <= `end'), ///
			yscale(range(0)) ///
			ytitle(% PIB) ///
			xtitle("") ///
			xlabel(`aniomin'(1)`=round(anio[_N],10)') ///
			xline(`=`anio'+.5') ///
			legend(off) ///
			text(`=rfsp_pib[`obs`anio_last'']*.1' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", color(white) placement(e)) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			title({bf: Proyecci{c o'}n} de los RFSP) subtitle($pais) ///
			name(Proy_rfsp, replace)
	}

	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_educa = "`proy_educa' `=string(`=gastoeducacion[`k']/1000000000000',"%10.3f")',"
				local proy_pension = "`proy_pension' `=string(`=gastopensiones[`k']/1000000000000',"%10.3f")',"
				local proy_salud = "`proy_salud' `=string(`=gastosalud[`k']/1000000000000',"%10.3f")',"
				local proy_costo = "`proy_costo' `=string(`=gastocostodeuda[`k']/1000000000000',"%10.3f")',"
				local proy_otrosg = "`proy_otrosg' `=string(`=gastootros[`k']/1000000000000',"%10.3f")',"
				local proy_bienestar = "`proy_bienestar' `=string(`=gastopenbienestar[`k']/1000000000000',"%10.3f")',"
				local proy_ingbas = "`proy_ingbas' `=string(`=gastoingbasico[`k']/1000000000000',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_educa = "`proy_educa' `=string(`=estimacioneducacion[`k']/1000000000000',"%10.3f")',"
				local proy_pension = "`proy_pension' `=string(`=estimacionpensiones[`k']/1000000000000',"%10.3f")',"
				local proy_salud = "`proy_salud' `=string(`=estimacionsalud[`k']/1000000000000',"%10.3f")',"
				local proy_costo = "`proy_costo' `=string(`=estimacioncostodeuda[`k']/1000000000000',"%10.3f")',"
				local proy_otrosg = "`proy_otrosg' `=string(`=estimacionotros[`k']/1000000000000',"%10.3f")',"
				local proy_bienestar = "`proy_bienestar' `=string(`=estimacionpenbienestar[`k']/1000000000000',"%10.3f")',"
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
		noisily di in w "PROYEDUCA:   [`=substr("`proy_educa'",1,`=`length_educa'-1')']"
		noisily di in w "PROYPENSION: [`=substr("`proy_pension'",1,`=`length_pension'-1')']"
		noisily di in w "PROYSALUD:   [`=substr("`proy_salud'",1,`=`length_salud'-1')']"
		noisily di in w "PROYCOSTO:   [`=substr("`proy_costo'",1,`=`length_costo'-1')']"
		noisily di in w "PROYOTROSG:  [`=substr("`proy_otrosg'",1,`=`length_otrosg'-1')']"
		noisily di in w "PROYBIENES:  [`=substr("`proy_bienestar'",1,`=`length_bienestar'-1')']"
		noisily di in w "PROYINGBAS:  [`=substr("`proy_ingbas'",1,`=`length_ingbas'-1')']"
		capture log off output	
	}


	*********************
	** 4.2 Al infinito **
	*drop estimaciongasto
	reshape long gasto estimacion, i(anio) j(modulo) string
	collapse (sum) gasto estimacion (mean) pibYR deflator shrfsp* rfsp Poblacion ///
		if modulo != "ingresos" & modulo != "VP" & anio <= `end', by(anio) fast

	g gastoVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format gastoVP %20.0fc
	local gastoINF = gastoVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	tabstat gastoVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname gastoVP
	matrix `gastoVP' = r(StatTotal)

	noisily di in g "  (-) Gastos futuros en VP:" in y _col(35) %25.0fc `gastoINF'+`gastoVP'[1,1] in g " `currency'"	
	
	* Save *
	rename estimacion estimaciongastos
	tempfile basegastos
	save `basegastos'


	*****************************
	*** 5 Fiscal Gap: Balance ***
	*****************************
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Balance futuro en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	

	* Saldo de la deuda *
	tabstat shrfsp if anio == `=`anio'', stat(sum) f(%20.0fc) save
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
		twoway (area shrfsp_pib anio if shrfsp_pib != . & anio <= `anio' & anio >= 2005) ///
			(area shrfsp_pib anio if anio > `anio' & anio <= `end'), ///
			title({bf:Proyecci{c o'}n} del SHRFSP) ///
			subtitle($pais) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			xtitle("") ytitle(% PIB) ///
			xlabel(2005(1)`end') ///
			yscale(range(0)) ///
			legend(off) ///
			text(`=shrfsp_pib[`obs`anio_last'']*.1' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", color(white) placement(e)) ///
			xline(`=`anio'+.5') ///
			name(Proy_shrfsp, replace)
		if "$export" != "" {
			graph export `"$export/Proy_shrfsp.png"', replace name(Proy_shrfsp)
		}

		forvalues k=1(1)`=_N' {
			if shrfspPC[`k'] != . & anio[`k'] >= 2005 {
				local textPC2 `"`textPC2' `=shrfspPC[`k']' `=anio[`k']' "{bf:`=string(shrfspPC[`k'],"%10.0fc")'}""'
			}
		}
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} por persona"
			local graphfuente "{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (connected shrfspPC anio if shrfsp_pib != . & anio < `anio'-1 & anio >= 2005) ///
			(connected shrfspPC anio if anio >= `anio'-1 & anio <= `end'), ///
			title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			xtitle("") ///
			ytitle("`currency' `aniovp' por persona") ///
			ylabel(, format(%10.0fc)) ///
			xlabel(2005(1)`end') ///
			legend(off) ///
			text(`textPC2', color(black) placement(c) size(small)) ///
			name(Proy_shrfsppc, replace)
		if "$export" != "" {
			graph export `"$export/Proy_shrfsppc.png"', replace name(Proy_shrfsppc)
		}
	}
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
		capture log off output
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `end' {
			local shrfsp_end = shrfsp_pib[`k']
			local shrfsp_end_MX = shrfsp[`k']
			continue, break
		}
	}
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Deuda (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc `shrfsp_end' ///
		in g " % PIB"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Tasa Efectiva Promedio: " in y _col(35) %25.4fc `tasaEfectiva_ari'[1,1] in g " %"
	noisily di in g "  (*) Growth rate LP:" in y _col(35) %25.4fc `grow_rate_LR' in g " %"
	noisily di in g "  (*) Discount rate:" in y _col(35) %25.4fc `discount' in g " %"


	*****************************************
	*** 5 Fiscal Gap: Cuenta Generacional ***
	*****************************************
	preserve
	use if entidad == "Nacional" using `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
	
	tabstat poblacion if anio == `anio' | anio == `end', stat(sum) save f(%20.0fc) by(anio)
	tempname poblacionACT poblacionEND
	matrix `poblacionACT' = r(Stat1)
	matrix `poblacionEND' = r(Stat2)

	collapse (sum) poblacion if edad == 0, by(anio) fast
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	drop if lambda == .
	
	g poblacionVP = poblacion*lambda/(1+`discount'/100)^(anio-`anio')
	format poblacionVP %20.0fc

	tabstat poblacionVP if anio > `anio', stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)
	
	noisily di _newline(2) in g "{bf: INEQUIDAD INTERGENERACIONAL:" in y " $pais `anio' }"
	noisily di in g "  (*) Poblaci{c o'}n futura VP: " in y _col(35) %25.0fc `poblacionVP'[1,1] in g " personas"
	local poblacionINF = poblacionVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))
	noisily di in g "  (*) Poblaci{c o'}n futura INF: " in y _col(35) %25.0fc `poblacionINF' in g " personas"
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaciones `anio':" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1])/(`poblacionACT'[1,1]) ///
		in g " `currency' por persona"
	noisily di in g "  (*) Deuda generaciones `end':" ///
		in y _col(35) %25.0fc -(-`shrfsp_end_MX')/(`poblacionEND'[1,1]) ///
		in g " `currency' por persona"
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaci{c o'}n futura:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad GA:" ///
			in y _col(35) %25.0fc ((-(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}

	if "$output" != "" {
		quietly log on output
		noisily di in w "PROYSHRFSP3: [" ///
			%10.0f -(-`shrfsp'[1,1])/(`poblacionACT'[1,1]) "," ///
			%10.0f -(-`shrfsp_end_MX')/(`poblacionEND'[1,1]) ///
			"]"
		quietly log off output
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





