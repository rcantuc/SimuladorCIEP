*!*******************************************
*!***                                    ****
*!***    PIB y deflactor                 ****
*!***    BIE/INEGI                       ****
*!***    Autor: Ricardo                  ****
*!***    Fecha: 29/Sept/22               ****
*!***                                    ****
*!*******************************************
program define PIBDeflactor, return
timer on 2
quietly {

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", clear
	if _rc != 0 {
		noisily run `"`c(sysdir_personal)'/UpdatePIBDeflactor`=subinstr("${pais}"," ","",.)'.do"'
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
	*** 1. Sintaxis ***
	*******************
	syntax [if] [, ANIOvp(int `aniovp') NOGraphs UPDATE ///
		GEOPIB(int -1) GEODEF(int -1) DIScount(real 5) NOOutput]

	** 1.1 Si la opción "update" es llamada, ejecuta el do-file UpdatePIBDeflactor.do **
	if "`update'" == "update" {
		noisily run `"`c(sysdir_personal)'/UpdatePIBDeflactor`=subinstr("${pais}"," ","",.)'.do"'
	}



	************************
	*** 2 Bases de datos ***
	************************
	use "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", clear

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
	*local trim_last = " t`trim_last'"

	noisily di _newline(2) in g _dup(20) "." "{bf:   PIB + Deflactor:" in y " PIB `aniovp'   }" in g _dup(20) "." _newline
	noisily di in g " PIB " in y "`aniofinal'q`trim_last'" _col(33) %20.0fc pibQ[`obsfinal'] in g " `=currency' ({c u'}ltimo reportado)"
	collapse (mean) indiceY=indiceQ pibY=pibQ pibYR=pibQR WorkingAge Poblacion* pibPO (last) trimestre, by(anio currency)
	tsset anio

	** 2.2 Locales para los cálculos geométricos **
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

	*g double var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100
	g double var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100
	label var var_indiceG "Promedio geométrico (`difpib' años)"

	** 2.3 Imputar Parámetros exógenos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	local exo_def = 0
	local anio_def = `aniovp'
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k' & trimestre != 4
			local exceptI "`exceptI'${def`k'}% (`k'), "
			local anio_def = `k'
			local ++exo_def
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k' & trimestre != 4 & var_indiceY == .
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k' & trimestre != 4
		replace var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100 if anio == `k' & anio > `aniofinal'
	}
	if "`exceptI'" != "" {
		local exceptI "`=substr("`exceptI'",1,`=strlen("`exceptI'")-2')'"
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
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k' & trimestre != 4
			local except "`except'${pib`k'}% (`k'); "
			local anio_exo = `k'
			local ++exo_count

			replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k' & trimestre != 4
			replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' & trimestre != 4
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

	if "`nographs'" != "nographs" & "$nographs" == "" {

		if "`if'" != "" {
			keep `if'
		}

		* Graph type *
		if `exo_count'-1 <= 0 {
			local graphtype "bar"
		}
		else {
			local graphtype "area"
		}

		if `exo_def'-1 <= 0 {
			local graphtype2 "bar"
		}
		else {
			local graphtype2 "area"
		}



		************************************
		*** 1. Crecimiento del Deflactor ***
		************************************

		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=anio[`k']' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Índice de precios implícitos}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE y SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected var_indiceY anio ///
			if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 4)) ///
			(connected var_indiceY anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal') ///
			(connected var_indiceY anio if anio >= `aniofinal'+`exo_def'), ///
			xlabel(1993 2000 2005 2010 2015 2020 2035 2040 2050 2060 2070 `aniovp' `=`aniofinal'+`exo_count'-1') ///
			ylabel(, format(%3.0f)) ///
			ytitle("Crecimiento anual (%)") xtitle("") ///
			///yline(0, lcolor(black)) ///
			text(`crec_deflactor', color(white) size(vsmall)) ///
			legend(label(1 "INEGI, SCN 2018") label(2 "Estimación $paqueteEconomico") label(3 "Promedio (últimos `difdef' años)") ///
			region(margin(zero))) ///
			title("`graphtitle'") ///
			subtitle(${pais}) ///
			caption("`graphfuente'") ///
			note("{bf:{c U'}ltimo dato reportado}: `=`aniofinal''`trim_last'.") ///
			name(var_indiceYH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/var_indiceYH.png", replace name(var_indiceYH)
		}



		***********************************
		*** 2. Proyección del Deflactor ***
		***********************************

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Evolución del índice de precios implícitos}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE y SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (area deflator anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 4)) ///
			(`graphtype2' deflator anio if anio < `aniofinal'+`exo_def' & anio >= `aniofinal', lwidth(none)) ///
			(area deflator anio if anio >= `aniofinal'+`exo_def') ///
			, title("`graphtitle'") ///
			subtitle(${pais}) ///
			caption("`graphfuente'") ///
			xlabel(1993 2000 2005 2010 2015 2020 2035 2040 2050 2060 2070 `aniovp' `=`aniofinal'+`exo_count'-1') ///
			yscale(range(0)) ///
			ylabel(, format("%3.0f")) ///
			ytitle("{c I'}ndice `aniovp' = 1.000") xtitle("") ///
			legend(label(1 "INEGI, SCN 2018") label(2 "Estimación $paqueteEconomico") label(3 "Proyección")) ///
			note("{bf:Crecimiento de precios}: `=string(`=((indiceY[`obsDEF']/indice[`obs_def'])^(1/(`=`obsDEF'-`obs_def''))-1)*100',"%6.3f")'% (`=anio[[`obsDEF']]'-`=anio[`obs_def']'). {bf:{c U'}ltimo dato reportado}: `=`aniofinal''`trim_last'.") ///
			name(deflactorH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/deflactorH.png", replace name(deflactorH)
		}



		******************************
		*** 3. Crecimiento del PIB ***
		******************************

		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_pibY[`k'] != . {
				local crec_PIB `"`crec_PIB' `=var_pibY[`k']' `=anio[`k']' "`=string(var_pibY[`k'],"%5.1fc")'" "'
			}
		}

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Producto Interno Bruto}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected var_pibY anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 4)) ///
			(connected var_pibY anio if anio < `aniofinal'+`exo_count' & anio >= `aniofinal') ///
			(connected var_pibY anio if anio >= `aniofinal'+`exo_count') ///
			, title("`graphtitle'") ///
			subtitle(${pais}) ///
			caption("`graphfuente'") ///
			xlabel(1993 1995 2000 2005 2010 2015 2020 2035 2040 2050 2060 2070 `aniovp' `=`aniofinal'+`exo_count'-1') ///
			ylabel(/*-6(3)6*/, format(%3.0fc)) ///
			ytitle("Crecimiento anual (%)") xtitle("") ///
			///yline(0, lcolor(white)) ///
			text(`crec_PIB', color(white) size(vsmall)) ///
			legend(label(1 "INEGI, SCN 2018") label(2 "Estimación $paqueteEconomico") label(3 "Promedio (últimos `difpib' años)")) ///
			note("{bf:Crecimiento econ{c o'}mico}: `=string(`=((pibYR[`obsPIB']/pibYR[`obs_exo'])^(1/(`=`obsPIB'-`obs_exo''))-1)*100',"%6.3f")'% (`=anio[[`obsPIB']]'-`=anio[`obs_exo']'). {bf:{c U'}ltimo dato reportado}: `=`aniofinal''`trim_last'.") ///
			name(PIBH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIBH.png", replace name(PIBH)
		}



		*****************************
		*** 4. Proyección del PIB ***
		*****************************
		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000000000

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Flujo del Producto Interno Bruto}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (area `pibYRmil' anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 4)) ///
			(`graphtype' `pibYRmil' anio if anio < `aniofinal'+`exo_count' & anio >= `aniofinal', lwidth(none)) ///
			(area `pibYRmil' anio if anio >= `aniofinal'+`exo_count') ///
			, title("`graphtitle'") ///
			subtitle(${pais}) ///
			caption("`graphfuente'") ///
			ytitle(billones `=currency[`obsvp']' `aniovp') xtitle("") ///
			///ytitle(billions `=currency[`obsvp']' `aniovp') xtitle("") ///
			///text(`=`pibYRmil'[1]*.05' `=`aniofinal'-.5' "`aniofinal'", place(nw) color(white)) ///
			///text(`=`pibYRmil'[1]*.05' `=anio[1]+.5' "Reportado" ///
			///`=`pibYRmil'[1]*.05' `=`aniofinal'+1.5' "Proyecci{c o'}n CIEP", place(ne) color(white) size(small)) ///
			xlabel(1993 2000 2005 2010 2015 2020 2035 2040 2050 2060 2070 `aniovp' `=`aniofinal'+`exo_count'-1') ///
			ylabel(/*0(5)`=ceil(`pibYRmil'[_N])'*/, format(%20.0fc)) ///
			///xline(`aniofinal'.5) ///
			yscale(range(0)) /*xscale(range(1993))*/ ///
			legend(label(1 "INEGI, SCN 2018") label(2 "Estimación $paqueteEconomico") label(3 "Proyección")) ///
			///legend(label(1 "Observed") label(2 "Projected") label(3 "Estimated") order(1 3 2)) ///
			note("{bf:Productividad laboral}: `=string(scalar(llambda),"%6.3f")'% (`=anio[[`obsPIB']]'-`=anio[`obs_exo']'). {bf:{c U'}ltimo dato reportado}: `=`aniofinal''`trim_last'.") ///
			///note("{bf:Note}: Annual Labor Productivity Growth: `=string(scalar(llambda),"%6.3f")'% (`=anio[[`obsPIB']]'-`=anio[`obs_exo']').") ///
			name(PIBP, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIB.png", replace name(PIBP)
		}



		**************************
		*** 5. PIB por persona ***
		**************************
		g PIBPob = pibYR/Poblacion
		format PIBPob %20.0fc

		* Títulos y fuentes *
		if "$export" == "" {
			local graphtitle "{bf:Producto Interno Bruto por persona}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE/CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (bar PIBPob anio if (anio < `aniofinal' & anio >= `anioinicial') | (anio == `aniofinal' & trimestre == 4), ///
			mlabel(PIBPob) mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar PIBPob anio if anio < `aniofinal'+`exo_count' & anio >= `aniofinal', ///
			mlabel(PIBPob) mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar PIBPob anio if anio >= `aniofinal'+`exo_def', ///
			mlabel(PIBPob) mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)), ///
			title("`graphtitle'") ///
			subtitle(${pais}) ///
			caption("`graphfuente'") ///
			ytitle(`=currency[`obsvp']' `aniovp') ///
			xtitle("") ///
			xlabel(1993 1995 2000 2005 2010 2015 2020 2035 2040 2050 2060 2070 `aniovp' `=`aniofinal'+`exo_count'-1') ///
			legend(label(1 "Observado") label(2 "$paqueteEconomico") label(3 "Proyección")) ///
			ylabel(/*0(5)`=ceil(`pibYRmil'[_N])'*/, format(%20.0fc)) yscale(range(160000)) ///
			name(PIBPC, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIBPC.png", replace name(PIBPC)
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
	noisily di _newline in g _col(11) %~14s "Crec. PIB" _col(25) %~23s "PIB Nominal" _col(50) %~14s "Crec. {c I'}ndice" _col(64) %~14s "Deflactor"
	forvalues k=`=`obsvp'-10'(1)`=`obsvp'+10' {
		if anio[`k'] < `aniofinal' | (anio[`k'] == `aniofinal' & trimestre[`k'] == 4) {
			if "`reportado'" == "" {
				local reportado = "done"
			}
			noisily di in g " `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %12.10fc deflator[`k']
		}
		if (anio[`k'] == `aniofinal' & trimestre[`k'] < 4) | (anio[`k'] <= anio[`obs_exo'] & anio[`k'] > `aniofinal') {
			if "`estimado'" == "" {
				noisily di in g %~72s "$paqueteEconomico"
				local estimado = "done"
			}
			noisily di in g "{bf: `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %12.10fc deflator[`k'] "}"
		}
		if (anio[`k'] > `aniofinal') & anio[`k'] > anio[`obs_exo'] {
			if "`proyectado'" == "" {
				noisily di in g %~72s "PROYECTADO"
				local proyectado = "done"
			}
			noisily di in g " `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %12.10fc deflator[`k']
		}
	}

	return scalar aniolast = `aniofinal'

	timer off 2
	timer list 2
	noisily di _newline in g "Tiempo: " in y round(`=r(t2)/r(nt2)',.1) in g " segs."
}
end
