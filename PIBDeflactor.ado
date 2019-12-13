program define PIBDeflactor
quietly {
	version 13.1
	syntax [, ANIOvp(int -1) GEO(int 5) FIN(int 2030) Graphs]




	***************
	*** 0 BASES ***
	***************
	* 0.1.1. PIB *
	import excel "`=c(sysdir_site)'../basesCIEP/INEGI/SCN/PIB.xls", clear

	* 0.1.2. Limpia *
	LimpiaBIE

	* 0.1.3. Rename *
	rename A periodo
	rename B pibQ

	* 0.1.4. Time Series *
	split periodo, destring p("/") ignore("r p")

	rename periodo1 anio
	label var anio "anio"

	rename periodo2 trimestre
	label var trimestre "trimestre"

	destring pibQ, replace
	label var pibQ "Producto Interno Bruto"

	drop periodo
	order anio trimestre pibQ

	* 0.1.5. Guardar *
	compress
	tempfile PIB
	save `PIB'


	* 0.2.1. Deflactor *
	import excel "`=c(sysdir_site)'../basesCIEP/INEGI/SCN/deflactor.xls", clear

	* 0.2.2. Limpia *
	LimpiaBIE, nomult

	* 0.2.3. Rename *
	rename A periodo
	rename B indiceQ

	* 0.2.4. Time Series *
	split periodo, destring p("/") ignore("r p")

	rename periodo1 anio
	label var anio "anio"

	rename periodo2 trimestre
	label var trimestre "trimestre"

	destring indiceQ, replace
	label var indiceQ "${I}ndice de Precios Impl${i}citos"

	drop periodo
	order anio trimestre indiceQ

	* 0.2.5. Guardar *
	compress
	tempfile Deflactor
	save `Deflactor', replace




	*************************
	*** 1 PIB + Deflactor ***
	*************************
	use (anio trimestre pibQ) using `PIB', clear
	merge 1:1 (anio trimestre) using `Deflactor', nogen keepus(indiceQ)

	* Anio + Trimestre *
	g aniotrimestre = yq(anio,trimestre)
	format aniotrimestre %tq
	label var aniotrimestre "YearQuarter"
	tsset aniotrimestre

	* Ultimos valores *
	local anio_last = anio[_N]
	local trim_last = trimestre[_N]

	* Anualizar *
	egen double indiceY = mean(indiceQ), by(anio)
	label var indiceY "Crecimiento anual"
	format indiceY %10.4fc

	egen double pibY = mean(pibQ), by(anio)
	label var pibY "Crecimiento anual"
	format pibY %25.0fc
	
	order aniotrimestre anio trimestre *Q *Y




	*******************
	*** 2 Deflactor ***
	*******************
	g double var_indiceQ = (indiceQ/L4.indiceQ-1)*100
	label var var_indiceQ "Trimestral"

	g double var_indiceY = (indiceY/L4.indiceY-1)*100
	label var var_indiceY "Anual"

	g double var_indiceG = ((indiceY/L`=4*`geo''.indiceY)^(1/`geo')-1)*100
	label var var_indiceG "Promedio geom{c e'}trico (`geo' a{c n~}os)"
	
	* Gr{c a'}fica hist{c o'}rica *
	if "`graphs'" == "graphs" {
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if trimestre[`k'] == 1 & var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=aniotrimestre[`k']+2' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}

		twoway (connected var_indiceQ aniotrimestre) ///
			(connected var_indiceY aniotrimestre), ///
			title("{bf:{c I'}ndice de precios impl{c i'}citos}") ///
			ytitle(porcentaje) xtitle("") yline(0) ///
			text(`crec_deflactor') ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n del INEGI, BIE.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(deflactorH, replace)
			
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/deflactorH.png", replace name(deflactorH)
		}
	}


	***********************************
	** 2.1 Par{c a'}metros ex{c o'}genos **
	tsappend, last(`fin'q4) tsfmt(tq)
	replace anio = yofd(dofq(aniotrimestre)) if anio == .
	replace trimestre = quarter(dofq(aniotrimestre)) if trim == .

	* Imputar *
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k'
			local exceptI "`exceptI'`k' (${def`k'}%), "
		}
		else {
			replace var_indiceY = L4.var_indiceG if anio == `k'
		}
		replace indiceY = L4.indiceY*(1+var_indiceY/100) if anio == `k'
		replace var_indiceG = ((indiceY/L`=4*`geo''.indiceY)^(1/`geo')-1)*100 if anio == `k'
	}	

	* Valor presente *
	capture confirm existence $anioVP
	if _rc == 0 & `aniovp' == -1 {
		local aniovp = $anioVP
	}
	else if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
		*global anioVP = `aniovp'
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
			continue, break
		}
	}
	g double deflator = indiceY/indiceY[`obsvp']
	label var deflator "Deflactor"




	*************
	*** 3 PIB ***
	*************
	g double pibQR = pibQ/deflator
	label var pibQR "Quarter Real (`=anio[`obsvp']'q`=trimestre[`obsvp']')"
	format pibQR %25.0fc

	g double pibYR = pibY/deflator
	label var pibYR "Annual Real (`=anio[`obsvp']'q`=trimestre[`obsvp']')"
	format pibYR %25.0fc

	g double var_pibQ = (pibQR/L4.pibQR-1)*100
	label var var_pibQ "Trimestral"
	*label var var_pibQ "Quarter On Quarter"
	
	g double var_pibY = (pibYR/L4.pibYR-1)*100
	label var var_pibY "Anual"
	*label var var_pibY "Year On Year"
	
	g double var_pibG = ((pibYR/L`=4*`geo''.pibYR)^(1/`geo')-1)*100
	label var var_pibG "Geometric mean (`geo' years)"
	
	* Gr{c a'}fica hist{c o'}rica *
	if "`graphs'" == "graphs" {
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if trimestre[`k'] == 1 & var_pibY[`k'] != . {
				local crec_PIB `"`crec_PIB' `=var_pibY[`k']' `=aniotrimestre[`k']+2' "`=string(var_pibY[`k'],"%5.1fc")'" "'
			}
		}

		twoway (connected var_pibQ aniotrimestre) ///
			(connected var_pibY aniotrimestre) if var_pibY != ., ///
			title({bf:Producto Interno Bruto}) ///
			subtitle(Crecimiento real) ///
			ytitle(porcentaje) xtitle("") yline(0) ///
			text(`crec_PIB') ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n del INEGI, BIE.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(PIBH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIBH.png", replace name(PIBH)
		}
	}



	***********************************
	** 3.1 Par{c a'}metros ex{c o'}genos **
	* Imputar *
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k'
			local except "`except'`k' (${pib`k'}%), "
		}
		else {
			replace var_pibY = L4.var_pibG if anio == `k'
		}
		replace pibY = L4.pibY*(1+var_pibY/100)*indiceY/L4.indiceY if anio == `k'
		replace pibYR = L4.pibYR*(1+var_pibY/100) if anio == `k'
		replace var_pibG = ((pibYR/L`=4*`geo''.pibYR)^(1/`geo')-1)*100 if anio == `k'
	}		
	
	order aniotrimestre anio trimestre *Y* *G *Q*
	g double productivity = pibYR/pibYR[`obsvp']
	label var productivity "Productivity"




	*****************
	** 4 Simulador **
	*****************
	keep if trimestre == 1
	drop *Q *trimestre
	
	if "`globals'" == "globals" {
		forvalues k=1(1)`=_N' {
			global PIB_`=anio[`k']' = pibY[`k']
			global DEF_`=anio[`k']' = deflator[`k']
			global pib_`=anio[`k']' = var_pibY[`k']
			global def_`=anio[`k']' = var_indiceY[`k']
		}
	}

	if "`graphs'" == "graphs" {
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_pibY[`k'] != . {
				local crec_PIBp `"`crec_PIBp' `=var_pibY[`k']' `=anio[`k']' "`=string(var_pibY[`k'],"%5.1fc")'" "'
			}
			if var_indiceY[`k'] != . {
				local crec_indicep `"`crec_indicep' `=var_indiceY[`k']' `=anio[`k']' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}

		if "`except'" != "" {
			local except `"Excepto: `=substr("`except'",1,`=strlen("`except'")-2')'. "'
			local exceptI `"Excepto: `=substr("`exceptI'",1,`=strlen("`exceptI'")-2')'. "'
		}
		
		twoway (connected var_indiceY anio if anio < `aniovp') ///
			(connected var_indiceY anio if anio >= `aniovp'), ///
			title({bf:{c I'}ndice de precio impl{c i'}citos}) ///
			ytitle(porcentaje) xtitle("") yline(0) ///
			text(`crec_indicep') ///
			legend(label(1 "Observado") label(2 "Proyecci{c o'}n")) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n del INEGI, BIE.}") ///
			note("{bf:Nota}: Promedio m{c o'}vil geom{c e'}trico de `geo' a{c n~}os despu{c e'}s de `anio_last'. `exceptI'{bf:{c U'}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(deflactorP, replace) ///
			legend(on)

		twoway (connected var_pibY anio if anio < `aniovp') ///
			(connected var_pibY anio if anio >= `aniovp'), ///
			title({bf:Producto Interno Bruto}) ///
			subtitle(Crecimiento real) ///
			ytitle(porcentaje) xtitle("") yline(0) ///
			text(`crec_PIBp') ///
			legend(label(1 "Observado") label(2 "Proyecci{c o'}n")) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n del INEGI, BIE.}") ///
			note("{bf:Nota}: Promedio m{c o'}vil geom{c e'}trico de `geo' a{c n~}os despu{c e'}s de `anio_last'. `except'{bf:{c U'}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(PIBP, replace) ///
			legend(on)
	}




	***************
	*** 5 Texto ***
	***************
	noisily di _newline in g "A{c n~}o" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(64) %8.4fc "Deflactor"

	forvalues k=`=`aniovp'-1'(1)`=`aniovp'+1' {
		noisily di in g "`k' " _col(10) %8.4fc in y ${pib_`k'} " %" _col(25) %20.0fc ${PIB_`k'} _col(50) %8.4fc in y ${def_`k'} " %" _col(65) %8.4fc ${DEF_`k'}
	}

}
end
