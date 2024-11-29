*!*******************************************
*!***                                    ****
*!***    PIB, deflactor e inflación      ****
*!***    Fuente: BIE/INEGI               ****
*!***    Autor: Ricardo                  ****
*!***    Fecha: 29/Sept/22               ****
*!***                                    ****
*!*******************************************
program define PIBDeflactor, return
quietly {
	timer on 3

	capture mkdir `"`c(sysdir_personal)'/SIM/"'
	capture mkdir `"`c(sysdir_personal)'/SIM/graphs/"'

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", clear
	if _rc != 0 {
		UpdatePIBDeflactor
	}

	** 0.2 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)	
	}



	*******************
	**# 1. Sintaxis ***
	*******************
	syntax [if] [, ANIOvp(int `aniovp') NOGraphs UPDATE ///
		GEOPIB(int -1) GEODEF(int -1) DIScount(real 5) NOOutput ANIOMAX(int 2070)]

	** 1.1 Si la opción "update" es llamada, se ejecuta el do-file UpdatePIBDeflactor.do **
	if "`update'" == "update" {
		UpdatePIBDeflactor
	}



	************************
	**# 2 Bases de datos ***
	************************
	use `if' using "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", clear

	** 2.1 Obtiene el año inicial y final de la base **
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
		}
		if pibQ[`k'] != . & "`anioi'" != "found" {
			local anioinicial = anio[`k']
			local anioi "found"
		}
		if pibQ[`k'] == . & "`anioi'" == "found" {
			local aniofinal = anio[`=`k'-1']
			local trim_last = trimestre[`=`k'-1']
			scalar trimlast = trimestre[`=`k'-1']
			local obsfinal = `k'-1
			continue, break
		}
	}


	** 2.2 Display inicial **
	noisily di _newline(2) in g _dup(20) "." "{bf:   PIB + Deflactor:" in y " PIB `aniovp'   }" in g _dup(20) "." _newline
	noisily di in g " PIB " in y "`aniofinal'q`trim_last'" _col(33) %20.0fc pibQ[`obsfinal'] in g " `=currency' ({c u'}ltimo reportado)"
	sort anio trimestre
	collapse (mean) indiceY=indiceQ pibY=pibQ pibYR=pibQR WorkingAge Poblacion* pibPO inpc (last) trimestre, by(anio currency)
	tsset anio


	** 2.3 Locales para los cálculos geométricos **
	if `geodef' < `anioinicial' {
		local geodef = `anioinicial'
	}
	local difdef = `aniofinal'-`geodef'

	if `geopib' < `anioinicial' {
		local geopib = `anioinicial'
	}
	local difpib = `aniofinal'-`geopib'
	scalar aniogeo = `geopib'
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `geodef' {
			local obsDEF = `k'
		}
		if anio[`k'] == `geopib' {
			local obsPIB = `k'
		}
	}

	g double var_indiceY = (indiceY/L.indiceY-1)*100
	label var var_indiceY "Crecimiento anual del índice de precios"

	g double var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100
	label var var_indiceG "Promedio geométrico (`difdef' años)"
	
	g double var_inflY = (inpc/L.inpc-1)*100
	label var var_inflY "Anual"

	g double var_inflG = ((inpc/L`=`difdef''.inpc)^(1/`difdef')-1)*100
	label var var_inflG "Promedio geométrico (`difdef' años)"


	** 2.3 Imputar Parámetros exógenos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	local exo_def = 0
	local anio_def = `aniovp'
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm scalar def`k'
		if _rc == 0 {
			replace var_indiceY = `=scalar(def`k')' if anio == `k' //& trimestre != 4
			local exceptI "`exceptI'`=scalar(def`k')'% (`k'), "
			local anio_def = `k'
			local ++exo_def
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k' & var_indiceY == . //& trimestre != 4 
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k' //& trimestre != 4
		replace var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100 if anio == `k' & anio > `aniofinal'
	}
	if "`exceptI'" != "" {
		local exceptI "`=substr("`exceptI'",1,`=strlen("`exceptI'")-2')'"
	}

	local exo_count = 0
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm scalar inf`k'
		if _rc == 0 {
			replace var_inflY = `=scalar(inf`k')' if anio == `k' //& trimestre != 4
			local exceptI "`exceptI'`k' (`=scalar(inf`k')'%), "
			local ++exo_count
		}
		else {
			replace var_inflY = L.var_inflG if anio == `k' & var_inflY == . //& trimestre != 4 
		}
		replace inpc = L.inpc*(1+var_inflY/100) if anio == `k' //& trimestre != 4
		replace var_inflG = ((inpc/L`=`difdef''.inpc)^(1/`difdef')-1)*100 if anio == `k' & anio > `aniofinal'
	}


	** 2.4 Merge datasets **
	if `aniovp' < `=`anioinicial'' | `aniovp' > anio[_N] {
		noisily di in r "A{c n~}o para valor presente (`aniovp') inferior a `=`anioinicial'' o superior a `aniofinal'."
		exit
	}
	drop if anio < `anioinicial'
	tsset anio



	*******************
	*** 3 Deflactor ***
	*******************
	*g double indiceY = pibY/pibYR
	label var indiceY "Índice de Precios Implícitos"
	format indiceY %7.1fc


	** 3.2 Valor presente **
	if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
		}
		if anio[`k'] == `=`aniofinal'' {
			local obslast = `k'
		}
		if anio[`k'] == `geodef' {
			local obsDEF = `k'
		}
		if anio[`k'] == `geopib' {
			local obsPIB = `k'
		}
	}
	g double deflator = indiceY/indiceY[`obsvp']
	label var deflator "Deflactor"
	return scalar deflator = deflator[`obsvp']
	
	g double deflatorpp = inpc/inpc[`obsvp']
	label var deflatorpp "Poder adquisitivo"
	return scalar deflatorpp = deflatorpp[`obsvp']



	*************
	*** 4 PIB ***
	*************
	replace pibYR = pibY/deflator
	label var pibYR "PIB Real (`=anio[`obsvp']')"
	format pibYR* %25.0fc

	g var_pibY = (pibYR/L.pibYR-1)*100
	label var var_pibY "Anual"

	g double var_pibG = ((pibYR/L`=`difpib''.pibYR)^(1/(`difpib'))-1)*100
	label var var_pibG "Geometric mean (`difpib' years)"

	** 4.1 Imputar Parámetros exógenos **
	replace currency = currency[`obslast']
	local anio_exo = `aniofinal'
	local exo_count = 0
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm scalar pib`k'
		if _rc == 0 {
			replace var_pibY = `=scalar(pib`k')' if anio == `k' //& trimestre != 4
			local except "`except'`=scalar(pib`k')'% (`k'); "
			local anio_exo = `k'
			local ++exo_count

			replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k' //& trimestre != 4
			replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' //& trimestre != 4
		}
	}

	if "`except'" != "" {
		local except "`=substr("`except'",1,`=strlen("`except'")-2')'"
	}

	** 4.2 Lambda (productividad) **
	g OutputPerWorker = pibYR/WorkingAge
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio_exo' {
			local obs_exo = `k'
		}
		if anio[`k'] == `anio_def' {
			local obs_def = `k'
		}
	}
	return scalar anio_exo = `anio_exo'

	scalar llambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100
	scalar LLambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[1])^(1/(`obs_exo'))-1)*100
	capture confirm existence $lambda
	if _rc == 0 {
		scalar llambda = $lambda
	}
	g lambda = (1+scalar(llambda)/100)^(anio-`aniovp')
	



	**********************
	*** 5 Proyecciones ***
	**********************
	* Proyección de crecimiento PIB *
	replace pibYR = `=pibYR[`obs_exo']'/`=WorkingAge[`obs_exo']'*WorkingAge*(1+scalar(llambda)/100)^(anio-`anio_exo') if pibYR == .
	replace pibY = pibYR*deflator if pibY == .

	* Crecimientos *
	replace var_pibG = ((pibYR/L`=`difpib''.pibYR)^(1/(`difpib'))-1)*100
	replace var_pibY = (pibYR/L.pibYR-1)*100

	g double pibYVP = pibYR/(1+`discount'/100)^(anio-`=anio[`obsvp']')
	format pibYVP %20.0fc

	replace OutputPerWorker = pibYR/WorkingAge if OutputPerWorker == .
	




	*****************
	** 6 Simulador **
	*****************
	noisily di in g " PIB " in y anio[`obsvp'] in g " per c{c a'}pita " in y _col(43) %10.0fc pibY[`obsvp']/Poblacion[`obsvp'] in g " `=currency[`obsvp']'"
	noisily di in g " PIB " in y anio[`obsvp'] in g " por edades laborales " in y _col(43) %10.0fc OutputPerWorker[`obsvp'] in g " `=currency[`obsvp']' (16-65 a{c n~}os)"

	local crecimientoProm = ((pibYR[`obs_exo']/pibYR[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100
	local deflactorProm = ((deflator[`obs_exo']/deflator[`obsDEF'])^(1/(`obs_exo'-`obsDEF'))-1)*100
	local inflacionProm = ((inpc[`obs_exo']/inpc[`obsDEF'])^(1/(`obs_exo'-`obsDEF'))-1)*100
	noisily di _newline in g " Crecimiento promedio " in y anio[`obsPIB'] "-" anio[`obs_exo'] _col(43) %10.4f ((pibYR[`obs_exo']/pibYR[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100 in g " %" 
	noisily di in g " Lambda por trabajador " in y anio[`obsPIB'] "-" anio[`obs_exo'] _col(43) %10.4f scalar(llambda) in g " %" 
	*noisily di in g " Lambda por trabajador " in y anio[1] "-" anio[`obs_exo'] _col(35) %10.4f scalar(LLambda) in g " %" 

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	*scalar pibINF = pibYR[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')/((`discount'/100)-`grow_rate_LR'+((`discount'/100)*`grow_rate_LR'))
	scalar pibINF = pibYR[_N] /*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')*/ /(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat pibYVP if anio >= `aniovp', stat(sum) f(%20.0fc) save
	tempname pibYVP
	matrix `pibYVP' = r(StatTotal)

	scalar pibVPINF = `pibYVP'[1,1] + pibINF
	scalar pibY = pibY[`obsvp']
	*global pib`aniovp' = var_pibY[`obsvp']
	scalar deflatorLP = round(deflator[_N],.1)
	scalar deflatorINI = string(round(1/deflator[1],.1),"%5.1f")
	scalar anioLP = anio[_N]

	scalar anioPWI = anio[`obsPIB']
	scalar anioPWF = anio[`obs_exo']
	scalar outputPW = string(OutputPerWorker[`obsvp'],"%10.0fc")
	scalar lambdaNW = ((pibYR[`obs_exo']/pibYR[`=`obs_exo'-`difpib''])^(1/(`difpib'))-1)*100
	scalar LambdaNW = ((pibYR[`obs_exo']/pibYR[1])^(1/(`obs_exo'))-1)*100

	di _newline in g " PIB " in y "al infinito" in y _col(22) %23.0fc `pibYVP'[1,1] + pibINF in g " `=currency[`obsvp']'"
	di in g " Tasa de descuento: " in y _col(25) %20.1fc `discount' in g " %"
	di in g " Crec. al infinito: " in y _col(25) %20.1fc var_pibY[_N] in g " %"
	di in g " Defl. al infinito: " in y _col(25) %20.1fc var_indiceY[_N] in g " %"





	****************
	** 7 Gráficas **
	****************
	if "`nographs'" != "nographs" & "$nographs" == "" {

		if "`if'" != "" {
			keep `if'
			local aniomax = anio[_N]
			local anioinicial = anio[1]
		}

		************************************
		*** 1. Crecimiento del Deflactor ***
		************************************
		
		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Índice de precios implícitos}"
			local graphfuente "Fuente: Elaborado por el CIEP, con información de INEGI/SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local defl_ini = deflator[`k']
			}
			if anio[`k'] == `aniovp' {
				local defl_vp = deflator[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local indi_ini = var_indiceY[`k']
			}
			if anio[`k'] == `aniomax' {
				local defl_fin = deflator[`k']
				local indi_fin = var_indiceY[`k']
			}
		}
		format deflator %7.1fc
		format var_indiceY %7.1fc
		twoway /// Bar
			(bar deflator anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(2) mlabel(deflator) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75) mlabsize(large)) ///
			(bar deflator anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(2) mlabel(deflator) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75) mlabsize(large) fintensity(50)) ///
			(bar deflator anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(2) mlabel(deflator) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75) mlabsize(large) fintensity(50)) ///
			/// Connected
			(connected var_indiceY anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(1) mlabel(var_indiceY) mlabpos(12) mlabcolor(black) mstyle(p1) lstyle(p1) lpattern(dot) msize(small) mlabsize(large)) ///
			(connected var_indiceY anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(1) mlabel(var_indiceY) mlabpos(12) mlabcolor(black) mstyle(p2) lstyle(p2) lpattern(dot) msize(small) mlabsize(large)) ///
			(connected var_indiceY anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(1) mlabel(var_indiceY) mlabpos(12) mlabcolor(black) mstyle(p3) lstyle(p3) lpattern(dot) msize(small) mlabsize(large)) ///
			, ///
			title("`graphtitle'") ///
			xlabel(`=round(`anioinicial',5)'(5)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) yscale(range(0 2.5) axis(2) noline) ///
			ylabel(none, format(%3.0f) axis(1) noticks) yscale(range(0 -75) axis(1) noline) ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			legend(off label(1 "INEGI, SCN 2018") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			caption("`graphfuente'") ///
			///note("Nota: La proyección representa el promedio geométrico de los últimos `difdef' años. {c U'}ltimo dato reportado: `=`aniofinal''t`trim_last'.") ///
			name(deflactor, replace) ///
			/// Added text
			text(`=`pibYRmil'[1]*0' `=`anioinicial'' "{bf:Índice `aniovp' = 1.0}", yaxis(2) size(medsmall) place(1) justification(left) bcolor(white) box) ///
			text(`=`pibYRmil'[1]*0' `=`aniofinal'+1' "{bf:$paqueteEconomico}",  yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			///text(0 `=`aniofinal'+`exo_def'+(`aniomax'-`aniofinal'-`exo_def')/2' "Proyectado", size(vsmall) place(12) justification(left)  yaxis(2)) ///
			yline(`deflactorProm', axis(1)) ///
			text(`deflactorProm' `=`anioinicial'' "{bf:Crecimiento}" `"{bf:promedio: `=string(`deflactorProm',"%5.1fc")'%}"', justification(left) place(5) color("111 111 111") size(vlarge))

		graph save deflactor "`c(sysdir_personal)'/SIM/graphs/deflactor", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/deflactor.png", replace name(deflactor)
		}



		******************************
		*** 2. Crecimiento del PIB ***
		******************************
		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000000000
		format `pibYRmil' %7.0fc

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Producto Interno Bruto}"
			local graphfuente "Fuente: Elaborado por el CIEP, con información de INEGI/SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local pib_ini = `pibYRmil'[`k']
				local varpibYini = var_pibY[`k']
				if `varpibYini' == . {
					local varpibYini = var_pibY[`k'+1]
				}
			}
			if anio[`k'] == `aniovp' {
				local pib_vp = `pibYRmil'[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local crec_ini = var_pibY[`k']
			}
			if anio[`k'] == `aniomax' {
				local pib_fin = `pibYRmil'[`k']
				local crec_fin = var_pibY[`k']
			}
		}
		format var_pibY %7.1fc

		tabstat `pibYRmil' var_pibY, by(anio) f(%7.1fc) stat(min max) save
		tempname pibYRmil2
		matrix `pibYRmil2' = r(StatTotal)
		
		twoway ///
			(bar `pibYRmil' anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(2) mlabel(`pibYRmil') mlabpos(12) mlabcolor(black) mlabgap(0pt) barwidth(.75) mlabsize(large)) ///
			(bar `pibYRmil' anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(2) mlabel(`pibYRmil') mlabpos(12) mlabcolor(black) mlabgap(0pt) barwidth(.75) mlabsize(large) fintensity(50)) ///
			(bar `pibYRmil' anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(2) mlabel(`pibYRmil') mlabpos(12) mlabcolor(black) mlabgap(0pt) barwidth(.75) mlabsize(large) fintensity(50)) ///
			(connected var_pibY anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(1) mlabel(var_pibY) mlabpos(12) mlabcolor(black) mstyle(p1) lstyle(p1) lpattern(dot) msize(small) mlabsize(large)) ///
			(connected var_pibY anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(1) mlabel(var_pibY) mlabpos(12) mlabcolor(black) mstyle(p2) lstyle(p2) lpattern(dot) msize(small) mlabsize(large)) ///
			(connected var_pibY anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(1) mlabel(var_pibY) mlabpos(12) mlabcolor(black) mstyle(p3) lstyle(p3) lpattern(dot) msize(small) mlabsize(large)) ///
			, ///
			title("`graphtitle'") ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`=round(`anioinicial',5)'(5)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) ///
			ylabel(none, format(%3.0f) axis(1) noticks) ///
			yscale(range(0 `=`pibYRmil2'[1,2]*3') axis(1) noline) ///
			yscale(range(0 `=`pibYRmil2'[2,1]*2') axis(2) noline) ///
			legend(off label(1 "INEGI, SCN 2018") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			caption("`graphfuente'") ///
			///note("Nota: La proyección incluye la transición de personas en edad de trabajar con una productividad anual de `=string(llambda,"%5.2fc")'%. {c U'}ltimo dato reportado: `=`aniofinal''t`trim_last'.") ///
			name(pib, replace) ///
			/// Added text
			yline(`crecimientoProm', axis(1)) ///
			text(`=`pibYRmil'[1]*0' `=`anioinicial'' "{bf:billones MXN `aniovp'}", yaxis(2) size(medsmall) place(1) justification(left) bcolor(white) box) ///
			text(`=`pibYRmil'[1]*0' `=`aniofinal'+1' "{bf:$paqueteEconomico}",  yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(`crecimientoProm' `=`anioinicial'' "{bf:Crecimiento}" "{bf:promedio: `=string(`crecimientoProm',"%5.1fc")'%}", justification(left) place(5) color("111 111 111") size(vlarge)) ///
			//text(0 `=`aniofinal'+`exo_def'+(`aniomax'-`aniofinal'-`exo_def')/2' "Proyectado", size(medsmall) place(12) justification(left) yaxis(2)) ///

		graph save pib "`c(sysdir_personal)'/SIM/graphs/pib", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/pib.png", replace name(pib)
		}



		**************************
		*** 3. PIB por persona ***
		**************************
		g PIBPob = pibYR/Poblacion/1000
		format PIBPob %20.0fc

		g var_pibPob = (PIBPob/L.PIBPob-1)*100
		format var_pibPob %7.1fc

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Producto Interno Bruto por persona}"
			local graphfuente "Fuente: Elaborado por el CIEP, con información de INEGI/CONAPO."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local pib_ini = PIBPob[`k']
			}
			if anio[`k'] == `aniovp' {
				local pib_vp = PIBPob[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local crec_ini = var_pibPob[`k']
			}
			if anio[`k'] == `aniomax' {
				local pib_fin = PIBPob[`k']
				local crec_fin = var_pibPob[`k']
			}
		}

		tabstat PIBPob var_pibPob, by(anio) f(%7.1fc) stat(min max) save
		tempname pibPob
		matrix `pibPob' = r(StatTotal)

		//tabstat PIBPob var_pibPob if anio < `aniofinal'+`exo_def' & anio > `aniofinal', by(anio) f(%7.1fc) stat(min max) save
		//tempname pibPob2
		//matrix `pibPob2' = r(StatTotal)

		tempname pibPob3
		capture tabstat PIBPob var_pibPob if anio >= `aniofinal'+`exo_def', by(anio) f(%7.1fc) stat(min max) save
		if _rc == 0 {
			matrix `pibPob3' = r(StatTotal)
		}
		else {
			matrix `pibPob3' = J(1,1,0)
		}

		twoway (bar PIBPob anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(2) mlabel(PIBPob) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75)) ///
			(bar PIBPob anio if anio < `aniofinal'+`exo_count' & anio >= `aniofinal', ///
				yaxis(2) mlabel(PIBPob) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75)  fintensity(50)) ///
			(bar PIBPob anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(2) mlabel(PIBPob) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75)  fintensity(50)) ///			
			(connected var_pibPob anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(1) mlabel(var_pibPob) mlabpos(12) mlabcolor(black) mstyle(p1) lstyle(p1) lpattern(dot) msize(small)) ///
			(connected var_pibPob anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(1) mlabel(var_pibPob) mlabpos(12) mlabcolor(black) mstyle(p2) lstyle(p2) lpattern(dot) msize(small)) ///
			(connected var_pibPob anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(1) mlabel(var_pibPob) mlabpos(12) mlabcolor(black) mstyle(p3) lstyle(p3) lpattern(dot) msize(small)) ///
			, ///
			title("`graphtitle'") ///
			subtitle("    Nivel de producto per cápita (miles MXN `aniovp') y crecimiento anual (%)", margin(bottom)) ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`=round(`anioinicial',5)'(5)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) ///
			ylabel(none, format(%3.0f) axis(1) noticks) ///
			yscale(range(0 `=`pibPob'[1,1]-2.75*(`pibPob'[2,1]-`pibPob'[1,1])') axis(1) noline) ///
			yscale(range(0 `=`pibPob'[2,1]*1.75') axis(2) noline) ///
			legend(off label(1 "Observado") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			note("La proyección incluye la transición de personas en edad de trabajar con una productividad anual de `=string(llambda,"%5.2fc")'%. {c U'}ltimo dato reportado: `=`aniofinal''t`trim_last'.") ///
			caption("`graphfuente'") ///
			name(pib_pc, replace) ///
			/// Added text
			///xline(`aniovp', lcolor("111 111 111") lpattern(dot) lwidth(medium)) ///
			///xline(`anioinicial', lcolor("111 111 111") lpattern(dot) lwidth(medium)) ///
			///xline(`aniomax', lcolor("111 111 111") lpattern(dot) lwidth(medium)) ///
			text(`=`pibPob'[2,1]*1.15' `=(`aniovp'-`anioinicial'-1)/2+`anioinicial'' ///
				"De `anioinicial' a `aniovp'," "el PIB por persona" "<-----     {bf:han crecido `=string((`pib_vp'/`pib_ini'-1)*100,"%5.1fc")'%}     ----->", size(small) place(0) justification(center) yaxis(2)) ///
			text(`=`pibPob'[2,1]*1.35' `=(`aniomax'-`aniofinal'-1)/2+`aniofinal'' ///
				"De `aniovp' a `aniomax'," "el PIB por persona" "<-----     {bf:crecerían `=string((`pib_fin'/`pib_vp'-1)*100,"%5.1fc")'%}     ----->", size(small) place(0) justification(center) yaxis(2)) ///
			text(0 `=`aniofinal'+`exo_def'/2-.5' "$paqueteEconomico", size(vsmall) place(12) justification(right) yaxis(2)) ///
			text(0 `=`aniofinal'+`exo_def'+(`aniomax'-`aniofinal'-`exo_def')/2' "Proyectado", size(vsmall) place(12) justification(left)  yaxis(2)) ///

		graph save pib_pc "`c(sysdir_personal)'/SIM/graphs/pib_pc", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/pib_pc.png", replace name(pib_pc)
		}



		**************************
		*** 4. Inflación anual ***
		**************************

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Índice nacional de precios al consumidor}"
			local graphfuente "Fuente: Elaborado por el CIEP, con información de INEGI/SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local defl_ini = deflatorpp[`k']
			}
			if anio[`k'] == `aniovp' {
				local defl_vp = deflatorpp[`k']
				local infl_vp = var_inflY[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local infl_ini = var_inflY[`k']
			}
			if anio[`k'] == `aniomax' {
				local defl_fin = deflatorpp[`k']
				local infl_fin = var_inflY[`k']
			}
		}

		tabstat deflatorpp var_inflY, by(anio) f(%7.1fc) stat(min max) save
		tempname deflatorpp
		matrix `deflatorpp' = r(StatTotal)

		//tabstat deflatorpp var_inflY if anio < `aniofinal'+`exo_def' & anio > `aniofinal', by(anio) f(%7.1fc) stat(min max) save
		//tempname deflatorpp2
		//matrix `deflatorpp2' = r(StatTotal) 

		tempname deflatorpp3
		capture tabstat deflatorpp var_inflY if anio >= `aniofinal'+`exo_def', by(anio) f(%7.1fc) stat(min max) save
		if _rc == 0 {
			matrix `deflatorpp3' = r(StatTotal)
		}
		else {
			matrix `deflatorpp3' = J(1,1,0)
		}

		format deflatorpp %7.1fc
		format var_inflY %7.1fc
		twoway ///
			(bar deflatorpp anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(2) mlabel(deflatorpp) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75)) ///
			(bar deflatorpp anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(2) mlabel(deflatorpp) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75)  fintensity(50)) ///
			(bar deflatorpp anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(2) mlabel(deflatorpp) mlabposition(12) mlabcolor(black) mlabgap(0pt) barwidth(.75)  fintensity(50)) ///
			/// Connected
			(connected var_inflY anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 12), ///
				yaxis(1) mlabel(var_inflY) mlabpos(12) mlabcolor(black) mstyle(p1) lstyle(p1) lpattern(dot) msize(small)) ///
			(connected var_inflY anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', ///
				yaxis(1) mlabel(var_inflY) mlabpos(12) mlabcolor(black) mstyle(p2) lstyle(p2) lpattern(dot) msize(small)) ///
			(connected var_inflY anio if anio >= `aniofinal'+`exo_def', ///
				yaxis(1) mlabel(var_inflY) mlabpos(12) mlabcolor(black) mstyle(p3) lstyle(p3) lpattern(dot) msize(small)) ///
			, ///
			title("`graphtitle'") ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`=round(`anioinicial',5)'(5)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) ///
			ylabel(none, format(%3.0f) axis(1) noticks) ///
			yscale(range(0 2.5) axis(2) noline) ///
			yscale(range(0 -75) axis(1) noline) ///
			legend(off label(1 "INEGI, SCN 2018") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			note("La proyección se calcula con el promedio móvil geométrico de los últimos `difdef' años. {c U'}ltimo dato: `=`aniofinal''t`trim_last'.") ///
			caption("`graphfuente'") ///
			name(inflacion, replace) ///
			/// Added text
			text(`=`pibYRmil'[1]*0' `=`anioinicial'' "{bf:Índice `aniovp' = 1.0}", yaxis(2) size(medsmall) place(1) justification(left) bcolor(white) box) ///
			text(`=`pibYRmil'[1]*0' `=`aniofinal'+1' "{bf:$paqueteEconomico}",  yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			///text(0 `=`aniofinal'+`exo_def'+(`aniomax'-`aniofinal'-`exo_def')/2' "Proyectado", size(vsmall) place(12) justification(left)  yaxis(2)) ///
			yline(`inflacionProm', axis(1)) ///
			text(`inflacionProm' `=`anioinicial'' "{bf:Crecimiento}" `"{bf:promedio: `=string(`inflacionProm',"%5.1fc")'%}"', justification(left) place(5) color("111 111 111") size(vlarge))

		graph save inflacion "`c(sysdir_personal)'/SIM/graphs/inflacion", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/inflacion.png", replace name(inflacion)
		}
	}
	return local except "`except'"
	return local exceptI "`exceptI'"
	return scalar geo = `difpib'
	return scalar discount = `discount'
	return scalar aniovp = `aniovp'



	***************
	*** 4 Texto ***
	***************
	noisily di _newline in g _col(6) %~12s "Cr. PIB" _col(24) %~17s "PIB Nominal" _col(29) %~10s "Infl." _col(50) %~12s "Deflactor" _col(67) %-14s "Defl. INPC"
	forvalues k=`=`obsvp'-10'(1)`=`obsvp'+10' {
		if anio[`k'] < `aniofinal' | (anio[`k'] == `aniofinal' & trimestre[`k'] == 4) {
			if "`reportado'" == "" {
				local reportado = "done"
			}
			noisily di in g " `=anio[`k']' " _col(7) %6.1fc in y var_pibY[`k'] " %" ///
				_col(18) %20.0fc pibY[`k'] ///
				_col(35) %8.1fc in y var_indiceY[`k'] " %" ///
				_col(52) %12.10fc deflator[`k'] ///
				_col(65) %14.10fc deflatorpp[`k']
		}
		if (anio[`k'] == `aniofinal' & trimestre[`k'] < 4) | (anio[`k'] <= anio[`obs_exo'] & anio[`k'] > `aniofinal') {
			if "`estimado'" == "" {
				noisily di _col(25) in g %~17s "$paqueteEconomico"
				local estimado = "done"
			}
			noisily di in g "{bf: `=anio[`k']' " _col(7) %6.1fc in y var_pibY[`k'] " %" ///
				_col(18) %20.0fc pibY[`k'] ///
				_col(35) %8.1fc in y var_indiceY[`k'] " %" ///
				_col(52) %12.10fc deflator[`k'] ///
				_col(65) %14.10fc deflatorpp[`k'] "}"
		}
		if (anio[`k'] > `aniofinal') & anio[`k'] > anio[`obs_exo'] {
			if "`proyectado'" == "" {
				noisily di in g _col(25) %~17s "PROYECTADO"
				local proyectado = "done"
			}
			noisily di in g " `=anio[`k']' " _col(7) %6.1fc in y var_pibY[`k'] " %" ///
				_col(18) %20.0fc pibY[`k'] ///
				_col(35) %8.1fc in y var_indiceY[`k'] " %" ///
				_col(52) %12.10fc deflator[`k'] ///
				_col(65) %14.10fc deflatorpp[`k']
		}
	}
	return scalar aniolast = `aniofinal'

	timer off 3
	timer list 3
	noisily di _newline in g "Tiempo: " in y round(`=r(t3)/r(nt3)',.01) in g " segs."
}
end



*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************
program define UpdatePIBDeflactor
	noisily di in g "  Updating PIBDeflactor.dta..." _newline


	**************
	***        ***
	**# 1. PIB ***
	***        ***
	**************

	** 1.1. Importar variables de interés desde el BIE **
	run "`c(sysdir_personal)'/AccesoBIE.do" "734407 735143 446562 446565 446566" "pibQ indiceQ PoblacionENOE PoblacionOcupada PoblacionDesocupada"

	** 1.2 Label variables **
	label var pibQ "Producto Interno Bruto (trimestral)"
	label var indiceQ "Índice de precios implícitos (trimestral)"
	label var PoblacionENOE "Población ENOE"
	label var PoblacionOcupada "Población Ocupada (ENOE)"
	label var PoblacionDesocupada "Población Desocupada (ENOE)"

	** 1.3 Dar formato a variables **
	replace pibQ = pibQ*1000000
	format indice* %8.3f
	format pib %20.0fc
	format Poblacion* %12.0fc

	** 1.4 Time Series **
	split periodo, destring p("/") //ignore("r p")
	rename periodo1 anio
	label var anio "anio"
	rename periodo2 trimestre
	label var trimestre "trimestre"

	** 1.5 Guardar **
	order anio trimestre pibQ
	drop periodo
	compress
	tempfile PIB
	save `PIB'



	***************
	***         ***
	**# 2. INPC ***
	***         ***
	***************
	** 2.1. Importar variables de interés desde el BIE **
	run "`c(sysdir_personal)'/AccesoBIE.do" "910392" "inpc"

	** 2.2 Label variables **
	label var inpc "Índice Nacional de Precios al Consumidor"

	** 2.3 Dar formato a variables **
	format inpc %8.3f

	** 2.4 Time Series **
	split periodo, destring p("/") //ignore("r p")
	rename periodo1 anio
	label var anio "anio"
	rename periodo2 mes
	label var mes "mes"

	g trimestre = 1 if mes <= 3
	replace trimestre = 2 if mes > 3 & mes <= 6
	replace trimestre = 3 if mes > 6 & mes <= 9
	replace trimestre = 4 if mes > 9
	
	collapse (mean) inpc, by(anio trimestre)

	** 2.5 Guardar **
	order anio trimestre inpc
	compress
	tempfile inpc
	save `inpc'



	********************
	***              ***
	**# 3. Poblacion ***
	***              ***
	********************

	** 3.1 Población (CONAPO) **
	capture use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
	if _rc != 0 {
		Poblacion, nographs
	}
	collapse (sum) Poblacion=poblacion if entidad == "Nacional", by(anio)
	format Poblacion %20.0fc
	tempfile Poblacion
	save "`Poblacion'"

	** 3.2 Working Ages (CONAPO) **
	use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
	collapse (sum) WorkingAge=poblacion if edad >= 15 & edad <= 65 & entidad == "Nacional", by(anio)
	format WorkingAge %15.0fc
	tempfile WorkingAge
	save "`WorkingAge'"

	** 3.3 Recién nacidos (CONAPO) **
	use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
	collapse (sum) Poblacion0=poblacion if edad == 0 & entidad == "Nacional", by(anio)
	format Poblacion0 %15.0fc
	tempfile Poblacion0
	save "`Poblacion0'"



	***************
	***         ***
	**# 4 Unión ***
	***         ***
	***************
	use `PIB', clear
		local ultanio = anio[_N]
		local ulttrim = trimestre[_N]
	merge m:1 (anio) using "`Poblacion'", nogen //keep(matched)
	merge m:1 (anio) using "`WorkingAge'", nogen //keep(matched)
	merge m:1 (anio) using "`Poblacion0'", nogen //keep(matched)
	replace trimestre = 1 if trimestre == .
	merge 1:1 (anio trimestre) using "`inpc'", nogen //keep(matched)

	** 4.1 Moneda **
	g currency = "MXN"

	** 4.2 Anio + Trimestre **
	g aniotrimestre = yq(anio,trimestre)
	format aniotrimestre %tq
	label var aniotrimestre "YearQuarter"
	tsset aniotrimestre



	******************************
	***                        ***
	**# 5 Variables de interés ***
	***                        ***
	******************************
	forvalues k=`=_N'(-1)1 {
		if indiceQ[`k'] != . {
			local obsvp = `k'
			local trim_last = trim[`k']
			local aniofinal = anio[`k']
			continue, break
		}
	}
	tempvar deflator
	g double `deflator' = indiceQ/indiceQ[`obsvp']


	** 5.1 PIB Real **
	g pibQR = pibQ/`deflator'

	** 5.2 PIB por población ocupada **
	g pibPO = pibQR/PoblacionOcupada
	format pibPO %20.0fc

	** 5.3 Crecimiento anual real **
	g crec_pibQR = (pibQR/L4.pibQR-1)*100
	format crec_pibQR %10.1fc

	** 5.4 Guardar base de datos **
	format pib* %25.0fc
	capture drop __*
	sort aniotrimestre
	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", replace
	}



	******************
	***            ***
	**# 6 Gráficas ***
	***            ***
	******************
	if "$nographs" == "" {
		
		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Producto Interno Bruto}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (dropline crec_pibQR aniotrimestre if anio > 2024, ///
			mlabel(crec_pibQR) mlabposition(12) mlabcolor(black) mlabgap(0pt)) ///
			(dropline crec_pibQR aniotrimestre if anio > 2018 & anio <= 2024, ///
			mlabel(crec_pibQR) mlabposition(12) mlabcolor(black) mlabgap(0pt)) ///
			(dropline crec_pibQR aniotrimestre if anio > 2012 & anio <= 2018, ///
			mlabel(crec_pibQR) mlabposition(12) mlabcolor(black) mlabgap(0pt)) ///
			(dropline crec_pibQR aniotrimestre if anio > 2006 & anio <= 2012, ///
			mlabel(crec_pibQR) mlabposition(12) mlabcolor(black) mlabgap(0pt)) ///
			(dropline crec_pibQR aniotrimestre if anio > 2000 & anio <= 2006, ///
			mlabel(crec_pibQR) mlabposition(12) mlabcolor(black) mlabgap(0pt)) ///
			(dropline crec_pibQR aniotrimestre if anio > 1994 & anio <= 2000, ///
			mlabel(crec_pibQR) mlabposition(12) mlabcolor(black) mlabgap(0pt)) ///
			if pibPO != ., ///
			title(`graphtitle') ///
			ytitle("Crecimiento trimestre a trimestre") xtitle("") ///
			tlabel(2005q1(4)`aniofinal'q`trim_last') ///
			ylabel(none, format(%20.0fc)) ///
			legend(off)	///
			yline(0) ///
			caption("`graphfuente'") ///
			name(UpdatePIBDeflactor, replace)


		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Productividad laboral}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/SHCP/ENOE."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		tempvar pibPO
		g `pibPO' = pibPO/1000
		format `pibPO' %7.0fc
		twoway (dropline pibPO aniotrimestre if anio > 2024, ///
			mlabel(`pibPO') mlabposition(12) mlabangle(0) mlabcolor(black) mlabgap(0pt) lpattern(dot)) ///
			(dropline pibPO aniotrimestre if anio > 2018 & anio <= 2024, ///
			mlabel(`pibPO') mlabposition(12) mlabangle(0) mlabcolor(black) mlabgap(0pt) lpattern(dot)) ///
			(dropline pibPO aniotrimestre if anio > 2012 & anio <= 2018, ///
			mlabel(`pibPO') mlabposition(12) mlabangle(0) mlabcolor(black) mlabgap(0pt) lpattern(dot)) ///
			(dropline pibPO aniotrimestre if anio > 2006 & anio <= 2012, ///
			mlabel(`pibPO') mlabposition(12) mlabangle(0) mlabcolor(black) mlabgap(0pt) lpattern(dot)) ///
			(dropline pibPO aniotrimestre if anio > 2000 & anio <= 2006, ///
			mlabel(`pibPO') mlabposition(12) mlabangle(0) mlabcolor(black) mlabgap(0pt) lpattern(dot)) ///
			(dropline pibPO aniotrimestre if anio > 1994 & anio <= 2000, ///
			mlabel(`pibPO') mlabposition(12) mlabangle(0) mlabcolor(black) mlabgap(0pt) lpattern(dot)) ///
			if pibPO != ., ///
			title("`graphtitle'") ///
			ytitle("miles MXN `aniofinal' por ocupado(a)") xtitle("") ///
			tlabel(2005q1(4)`aniofinal'q`trim_last') ///
			ylabel(none, format(%20.0fc)) yscale(range(500000)) ///
			legend(off)	///
			caption("`graphfuente'") ///
			name(pib_po, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/pib_po.png", replace name(pib_po)
		}
	}
end
