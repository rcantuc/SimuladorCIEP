program define FiscalGap
timer on 11
quietly {

	*****************
	*** 0 ANIO VP ***
	*****************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, NOGraphs Anio(int `aniovp') BOOTstrap(int 1) Update END(int 2100) ///
		ANIOMIN(int 2000) DIScount(real 3)]



	*************
	*** 1 PIB ***
	*************
	*use if anio <= `end' using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
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



	******************************
	*** 3 Fiscal Gap: Ingresos ***
	******************************
	LIF, anio(`anio') nographs by(divSIM2) //ilif //eofp
	collapse (sum) recaudacion if divLIF != 10, by(anio divSIM2) fast

	g modulo = ""
	levelsof divSIM2, local(divSIM2)
	foreach k of local divSIM2 {
		local divSIM2`k' : label divSIM2 `k'
		preserve

		capture use `"`c(sysdir_site)'/users/$pais/$id/`divSIM2`k''REC.dta"', clear
		if _rc != 0 {
			 use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/`divSIM2`k''REC.dta"', clear
		}
		merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
		collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

		g divSIM2 = `k'
		replace modulo = "`divSIM2`k''"

		tempfile `divSIM2`k''
		save ``divSIM2`k'''

		restore
		merge 1:1 (anio divSIM2) using  ``divSIM2`k''', nogen update replace
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
		tempvar consumo laboral kprivado kpublico
		g `consumo'  = (recaudacionConsumo)/1000000000000
		g `laboral'  = (recaudacionConsumo + recaudacionLaboral)/1000000000000
		g `kprivado' = (recaudacionConsumo + recaudacionLaboral + recaudacionKPrivado)/1000000000000
		g `kpublico' = (recaudacionConsumo + recaudacionLaboral + recaudacionKPrivado + recaudacionKPublico)/1000000000000
	
		tempvar consumo2 laboral2 kprivado2 kpublico2
		g `consumo2'  = (estimacionConsumo)/1000000000000
		g `laboral2'  = (estimacionConsumo + estimacionLaboral)/1000000000000
		g `kprivado2' = (estimacionConsumo + estimacionLaboral + estimacionKPrivado)/1000000000000
		g `kpublico2' = (estimacionConsumo + estimacionLaboral + estimacionKPrivado + estimacionKPublico)/1000000000000

		twoway (area `kpublico' `kprivado' `laboral' `consumo' anio if anio <= `anio' & anio >= `aniomin') ///
			(area `kpublico2' anio if anio > `anio', color("255 129 0")) ///
			(area `kprivado2' anio if anio > `anio', color("255 189 0")) ///
			(area `laboral2' anio if anio > `anio', color("39 97 47")) ///
			(area `consumo2' anio if anio > `anio', color("53 200 71")), ///
			legend(rows(1) order(1 2 3 4) ///
			label(1 "Organismos y Empresas") ///
			label(2 "Impuestos al capital") ///
			label(3 "Impuestos laborales") ///
			label(4 "Impuestos al consumo")) ///
			xlabel(`aniomin'(5)`=round(anio[_N],10)') ///
			ylabel(, format(%20.0fc)) ///
			xline(`=`anio'+.5') ///
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

	if "$output" == "output" {
		keep if anio >= 2013
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2010 & anio[`k'] < `anio' {
				local proy_consumo = "`proy_consumo' `=string(`=`consumo'[`k']',"%10.3f")',"
				local proy_ingreso = "`proy_ingreso' `=string(`=`laboral'[`k']',"%10.3f")',"
				local proy_kprivado = "`proy_kprivado' `=string(`=`kprivado'[`k']',"%10.3f")',"
				local proy_kpublico = "`proy_kpublico' `=string(`=`kpublico'[`k']',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_consumo = "`proy_consumo' `=string(`=`consumo2'[`k']',"%10.3f")',"
				local proy_ingreso = "`proy_ingreso' `=string(`=`laboral2'[`k']',"%10.3f")',"
				local proy_kprivado = "`proy_kprivado' `=string(`=`kprivado2'[`k']',"%10.3f")',"
				local proy_kpublico = "`proy_kpublico' `=string(`=`kpublico2'[`k']',"%10.3f")',"
			}
		}
		local length_consumo = strlen("`proy_consumo'")
		local length_ingreso = strlen("`proy_ingreso'")
		local length_kprivado = strlen("`proy_kprivado'")
		local length_kpublico = strlen("`proy_kpublico'")
		capture log on output
		noisily di in w "PROYCONSU: [`=substr("`proy_consumo'",1,`=`length_consumo'-1')']"
		noisily di in w "PROYINGRE: [`=substr("`proy_ingreso'",1,`=`length_ingreso'-1')']"
		noisily di in w "PROYKPUBL: [`=substr("`proy_kprivado'",1,`=`length_kprivado'-1')']"
		noisily di in w "PROYKPRIV: [`=substr("`proy_kpublico'",1,`=`length_kpublico'-1')']"
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

	noisily di in g "  (+) Ingresos INF + VP:" in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] in g " `currency'"
	*noisily di in g "  (*) Estimacion INF:" in y _col(35) %25.0fc `estimacionINF' in g " `currency'"
	*noisily di in g "  (*) Estimacion VP:" in y _col(35) %25.0fc `estimacionVP'[1,1] in g " `currency'"
	
	* Save *
	rename estimacion estimacioningresos
	tempfile baseingresos
	save `baseingresos'



	****************************
	*** 4 Fiscal Gap: Gastos ***
	****************************
	PEF if transf_gf == 0, anio(`anio') by(divPE) nographs
	replace divPE = 6 if divPE == 5 | divPE == 3 | divPE == -1 | divPE == 4
	collapse (sum) gasto, by(anio divPE) fast
	g modulo = ""

	levelsof divPE, local(divPE)
	foreach k of local divPE {
		local divPE`k' : label divPE `k'
		if "`divPE`k''" == "Educación" {
			preserve

			capture use `"`c(sysdir_site)'/users/$pais/$id/EducacionREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/EducacionREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divPE = `k'
			replace modulo = "educacion"

			tempfile educacion
			save `educacion'

			restore
			merge 1:1 (anio divPE) using `educacion', nogen update replace
		}
		if "`divPE`k''" == "Pensiones" {
			preserve

			capture use `"`c(sysdir_site)'/users/$pais/$id/PensionREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/PensionREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divPE = `k'
			replace modulo = "pensiones"

			tempfile pensiones
			save `pensiones'

			restore
			merge 1:1 (anio divPE) using `pensiones', nogen update replace
		}
		if "`divPE`k''" == "Salud" {
			preserve

			capture use `"`c(sysdir_site)'/users/$pais/$id/SaludREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/SaludREC.dta"', clear			
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divPE = `k'
			replace modulo = "salud"

			tempfile salud
			save `salud'

			restore
			merge 1:1 (anio divPE) using `salud', nogen update replace
		}
		if "`divPE`k''" == "Costo de la deuda" {
			replace modulo = "costodeuda" if divPE == `k'
		}
		if "`divPE`k''" == "Pensión Bienestar" {
			preserve

			capture use `"`c(sysdir_site)'/users/$pais/$id/PenBienestarREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/PenBienestarREC.dta"', clear
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divPE = `k'
			replace modulo = "penbienestar"

			tempfile penbienestar
			save `penbienestar'

			restore
			merge 1:1 (anio divPE) using `penbienestar', nogen update replace
		}
		if "`divPE`k''" == "Otros" {
			preserve

			capture use `"`c(sysdir_site)'/users/$pais/$id/OtrosGasREC.dta"', clear
			if _rc != 0 {
				use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/OtrosGasREC.dta"', clear
			}
			merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
			collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

			g divPE = `k'
			replace modulo = "otrosgas"

			tempfile otrosgas
			save `otrosgas'

			restore
			merge 1:1 (anio divPE) using `otrosgas', nogen update replace
		}
	}

	** Ingreso basico **
	preserve
	capture use `"`c(sysdir_site)'/users/$pais/$id/IngBasicoREC"', clear
	if _rc != 0 {
		use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/1/IngBasicoREC.dta"', clear
	}
	merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency)
	collapse estimacion contribuyentes poblacion , by(anio modulo aniobase)

	g divPE = 99
	replace modulo = "ingbasico"

	tempfile ingbasico
	save `ingbasico'

	restore
	merge 1:1 (anio divPE) using `ingbasico', nogen update replace

	* PIB *
	merge m:1 (anio) using `PIB', nogen keep(matched) update replace
	collapse (sum) gasto estimacion (max) pibYR deflator lambda Poblacion, by(anio modulo) fast



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

	/* Otros gastos (como % PIB) *
	g otrospib = gastootros/pibYR*100
	replace otrospib = L.otrospib if otrospib == .
	replace estimacionotros = L.otrospib/100*pibYR if estimacionotros == .


	******************************/
	** DEUDA Y COSTO DE LA DEUDA **
	merge 1:1 (anio) using `shrfsp', nogen keep(matched) keepus(shrfsp* rfsp* /*nopresupuestario*/ tipoDeCambio)
	merge 1:1 (anio) using `baseingresos', nogen


	* Costo de la deuda *
	g tasaEfectiva = gastocostodeuda/shrfsp*100
	capture confirm existence $tasaEfectiva
	if _rc == 0 {
		replace tasaEfectiva = $tasaEfectiva if anio >= `anio' & tasaEfectiva == .
	}
	tabstat tasaEfectiva if anio <= `anio' & anio >= `anio'-1, save
	tempname tasaEfectiva_ari
	matrix `tasaEfectiva_ari' = r(StatTotal)

	replace tasaEfectiva = `tasaEfectiva_ari'[1,1] if anio >= `anio' & tasaEfectiva == .


	* Simulacion *
	capture confirm scalar costodeu
	if _rc == 0 & "$pais" == "" {
		replace gastocostodeuda = scalar(costodeu)*Poblacion if anio == `anio'
		replace tasaEfectiva = gastocostodeuda/shrfsp*100 if anio == `anio'
	}


	* Depreciacion *
	g depreciacion = tipoDeCambio-L.tipoDeCambio
	replace depreciacion = L.depreciacion if depreciacion == .
	capture confirm existence $depreciacion
	if _rc == 0 {
		replace depreciacion = $depreciacion if anio >= `anio'
	}

	g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	capture confirm existence $tipoDeCambio
	if _rc == 0 {
		replace tipoDeCambio = $tipoDeCambio if anio == `anio'
	}
	replace tipoDeCambio = L.tipoDeCambio + depreciacion if anio > `anio'
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

	* Variables simulador *
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


	***************
	* Iteraciones *
	***************
	forvalues k = `=`anio'+1'(1)`=anio[_N]' {

		* Costo de la deuda *
		replace estimacioncostodeuda = tasaEfectiva/100*L.shrfsp if anio == `k'

		* RFSP *
		capture confirm variable rfspBalance
		if _rc != 0 {
			g rfspBalance = estimacioncostodeuda + estimacioneducacion ///
				+ estimacionsalud + estimacionpensiones + estimacionotrosgas + estimacioningbasico ///
				+ estimacionpenbienestar ///
				- estimacioningresos if anio == `k'
		}
		else {
			replace rfspBalance = estimacioncostodeuda + estimacioneducacion ///
				+ estimacionsalud + estimacionpensiones + estimacionotrosgas + estimacioningbasico ///
				+ estimacionpenbienestar ///
				- estimacioningresos if anio == `k'
		}
		replace rfsp = rfspBalance if anio == `k'

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

	egen estimaciongastos = rsum(estimacioncostodeuda estimacioneducacion ///
			estimacionsalud estimacionpensiones estimacionotrosgas estimacioningbasico ///
			estimacionpenbienestar)
	format estimaciongastos %20.0fc



	****************
	** 4.1 Graphs **
	tempvar educaciong pensionesg saludg costog otrosg ingbasg bienestarg
	g `educaciong' = (gastoeducacion)/1000000000000
	g `pensionesg' = (gastopensiones + gastoeducacion)/1000000000000
	g `saludg' = (gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `costog' = (gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `otrosg' = (gastootros + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `bienestarg' = (gastopenbienestar + gastootros + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	g `ingbasg' = (gastoingbasico + gastopenbienestar + gastootros + gastocostodeuda + gastosalud + gastopensiones + gastoeducacion)/1000000000000
	
	tempvar educaciong2 pensionesg2 saludg2 costog2 otrosg2 ingbasg2 bienestarg2
	g `educaciong2' = (estimacioneducacion)/1000000000000
	g `pensionesg2' = (estimacionpensiones + estimacioneducacion)/1000000000000
	g `saludg2' = (estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `costog2' = (estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `otrosg2' = (estimacionotros + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `bienestarg2' = (estimacionpenbienestar + estimacionotros + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000
	g `ingbasg2' = (estimacioningbasico + estimacionpenbienestar + estimacionotros + estimacioncostodeuda + estimacionsalud + estimacionpensiones + estimacioneducacion)/1000000000000

	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		twoway (area `ingbasg' `bienestarg' `otrosg' `costog' `saludg' `pensionesg' `educaciong' anio if anio <= `anio' & anio >= `aniomin') ///
			(area `ingbasg2' anio if anio > `anio', color("255 129 0")) ///
			(area `bienestarg2' anio if anio > `anio', color("255 189 0")) ///
			(area `otrosg2' anio if anio > `anio', color("39 97 47")) ///
			(area `costog2' anio if anio > `anio', color("53 200 71")) ///
			(area `saludg2' anio if anio > `anio', color("0 78 198")) ///
			(area `pensionesg2' anio if anio > `anio', color("0 151 201")) ///
			(area `educaciong2' anio if anio > `anio', color("186 34 64")) if anio >= `aniomin', ///
			legend(cols(8) order(2 3 4 5 6 7 1) ///
			label(1 "Renta b{c a'}sica") ///
			label(2 "Pensi{c o'}n Bienestar") ///
			label(3 "Otros gastos") ///
			label(4 "Costo de la deuda") ///
			label(5 "Salud") ///
			label(6 "Pensiones") ///
			label(7 "Educaci{c o'}n")) ///
			xlabel(`aniomin'(5)`=round(anio[_N],10)') ///
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
			xlabel(`aniomin'(5)`=round(anio[_N],10)') ///
			xline(`=`anio'+.5') ///
			legend(off) ///
			text(`=rfsp_pib[`obs`anio_last'']*.1' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", color(white) placement(e)) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			title({bf: Proyecci{c o'}n} de los RFSP) subtitle($pais) ///
			name(Proy_rfsp, replace)
	}

	if "$output" == "output" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				local proy_educa = "`proy_educa' `=string(`=`educaciong'[`k']',"%10.3f")',"
				local proy_pension = "`proy_pension' `=string(`=`pensionesg'[`k']',"%10.3f")',"
				local proy_salud = "`proy_salud' `=string(`=`saludg'[`k']',"%10.3f")',"
				local proy_costo = "`proy_costo' `=string(`=`costo'[`k']',"%10.3f")',"
				local proy_otrosg = "`proy_otrosg' `=string(`=`otrosg'[`k']',"%10.3f")',"
				local proy_bienestar = "`proy_bienestar' `=string(`=`bienestarg'[`k']',"%10.3f")',"
				local proy_ingbas = "`proy_ingbas' `=string(`=`ingbasg'[`k']',"%10.3f")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= 2030 {
				local proy_educa = "`proy_educa' `=string(`=`educaciong2'[`k']',"%10.3f")',"
				local proy_pension = "`proy_pension' `=string(`=`pensionesg2'[`k']',"%10.3f")',"
				local proy_salud = "`proy_salud' `=string(`=`saludg2'[`k']',"%10.3f")',"
				local proy_costo = "`proy_costo' `=string(`=`costo2'[`k']',"%10.3f")',"
				local proy_otrosg = "`proy_otrosg' `=string(`=`otrosg2'[`k']',"%10.3f")',"
				local proy_bienestar = "`proy_bienestar' `=string(`=`bienestarg2'[`k']',"%10.3f")',"
				local proy_ingbas = "`proy_ingbas' `=string(`=`ingbasg2'[`k']',"%10.3f")',"
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

	g gastoVP = estimacion/(1+`discount'/100)^(anio-`anio')
	format gastoVP %20.0fc
	local gastoINF = gastoVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	tabstat gastoVP if anio >= `anio', stat(sum) f(%20.0fc) save
	tempname gastoVP
	matrix `gastoVP' = r(StatTotal)

	noisily di in g "  (-) Gastos INF + VP:" in y _col(35) %25.0fc `gastoINF'+`gastoVP'[1,1] in g " `currency'"	
	
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
	tabstat shrfsp if anio == `=`anio'', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)

	noisily di in g "  (+) Deuda (" in y `=`anio'' in g "):" ///
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

	g shrfspPIB = shrfsp/pibYR*100
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		twoway (area shrfspPIB anio if shrfspPIB != . & anio <= `anio' & anio >= 2000) ///
			(area shrfspPIB anio if anio > `anio' & anio <= `end'), ///
			title({bf:Proyecci{c o'}n} del SHRFSP) ///
			subtitle($pais) ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
			xtitle("") ytitle(% PIB) ///
			xlabel(`aniomin'(5)`end') ///
			yscale(range(0)) ///
			legend(off) ///
			text(`=shrfspPIB[`obs`anio_last'']*.1' `=`anio'+1.5' "{bf:Proyecci{c o'}n}", color(white) placement(e)) ///
			xline(`=`anio'+.5') ///
			name(Proy_shrfsp, replace)
		if "$export" != "" {
			graph export `"$export/Proy_shrfsp.png"', replace name(Proy_shrfsp)
		}
	}
	if "$output" == "output" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio'-1 & anio[`k'] >= 2013 {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfspPIB[`k']',"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' null,"
			}
			if anio[`k'] == `anio' {
				local proy_shrfsp = "`proy_shrfsp' `=string(`shrfspobslast',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(51.000,"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfspPIB[`k']',"%10.3f")',"
			}
			if anio[`k'] > `anio'-1 & anio[`k'] <= 2030 {
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
	*preserve
	use if entidad == "Nacional" using `"`c(sysdir_site)'/SIM/$pais/Poblacion.dta"', clear
	
	tabstat poblacion if anio == `anio', stat(sum) save f(%20.0fc)
	tempname poblacionACT
	matrix `poblacionACT' = r(StatTotal)

	collapse (sum) poblacion if edad == 0, by(anio) fast
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	drop if lambda == .
	
	g poblacionVP = poblacion*lambda/(1+`discount'/100)^(anio-`anio')
	format poblacionVP %20.0fc

	tabstat poblacionVP if anio > `anio', stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)
	
	noisily di in g "  (*) Poblaci{c o'}n futura VP: " in y _col(35) %25.0fc `poblacionVP'[1,1] in g " personas"

	local poblacionINF = poblacionVP[_N]/(1-((1+`grow_rate_LR'/100)/(1+`discount'/100)))

	noisily di in g "  (*) Poblaci{c o'}n futura INF: " in y _col(35) %25.0fc `poblacionINF' in g " personas"

	noisily di in g "  (*) Deuda generaci{c o'}n futura:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"

	noisily di in g "  (*) Deuda generaci{c o'}n actual:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1])/(`poblacionACT'[1,1]) ///
		in g " `currency' por persona"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad generacional:" ///
			in y _col(35) %25.0fc ((-(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}

	*** TASA EFECTIVA ***
	noisily di in g "  " _dup(61) "-"
	capture confirm existence $tasaEfectiva
	if _rc == 0 {
		noisily di in g "  (*) Tasa Efectiva Futura: " in y _col(35) %25.4fc $tasaEfectiva in g " %"
	}
	noisily di in g "  (*) Tasa Efectiva Promedio: " in y _col(35) %25.4fc `tasaEfectiva_ari'[1,1] in g " %"
	noisily di in g "  (*) Growth rate LP:" in y _col(35) %25.4fc `grow_rate_LR' in g " %"
	noisily di in g "  (*) Discount rate:" in y _col(35) %25.4fc `discount' in g " %"

	*restore



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





