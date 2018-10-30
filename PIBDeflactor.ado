*! Ricardo. 20 de febrero de 2015
program define PIBDeflactor
quietly {
	version 13.1
	syntax [, Graphs NOGraphs ANIOvp(int $anioVP) ID(string) GLOBALs GEO(int 5) FIN(int 2030)]


	local anios_geo = `geo'
	local anio_fin = `fin'


	***********************
	** 1 PIB + Deflactor **
	***********************
	use "`c(sysdir_site)'/bases/INEGI/BIE/SCN/PIB/pib.dta", clear
	merge 1:1 (anio trimestre) using "`c(sysdir_site)'/bases/INEGI/BIE/SCN/Deflactor/deflactor.dta", nogen

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



	*****************
	** 2 Deflactor **
	*****************
	g double var_indiceQ = (indiceQ/L4.indiceQ-1)*100
	label var var_indiceQ "Trimestral"

	g double var_indiceY = (indiceY/L4.indiceY-1)*100
	label var var_indiceY "Anual"

	g double var_indiceG = ((indiceY/L`=4*`anios_geo''.indiceY)^(1/`anios_geo')-1)*100
	label var var_indiceG "Promedio geom${e}trico (`anios_geo' a${ni}os)"
	
	* Grafica historica *
	if "`graphs'" == "graphs" {
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if trimestre[`k'] == 1 & var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=aniotrimestre[`k']+2' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}

		twoway (connected var_indiceQ aniotrimestre) ///
			(connected var_indiceY aniotrimestre), ///
			title({bf:${I}ndice de precios impl${i}citos}) ///
			subtitle(Crecimiento anual) ///
			ytitle(porcentaje) xtitle("") ///
			text(`crec_deflactor') ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci${o}n del INEGI, BIE.}") ///
			note("{bf:${U}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(deflactorH, replace)

		*graph export `"`c(sysdir_personal)'/users/`id'/DeflactorH.png"', replace name(deflactorH)
	}


	** 2.1 Parametros exogenos **
	tsappend, last(`anio_fin'q4) tsfmt(tq)
	replace anio = yofd(dofq(aniotrimestre)) if anio == .
	replace trimestre = quarter(dofq(aniotrimestre)) if trim == .

	* Imputar *
	forvalues k=`anio_last'(1)`anio_fin' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k'
			local exceptI "`exceptI'`k' (${def`k'}%), "
		}
		else {
			replace var_indiceY = L4.var_indiceG if anio == `k'
		}
		replace indiceY = L4.indiceY*(1+var_indiceY/100) if anio == `k'
		replace var_indiceG = ((indiceY/L`=4*`anios_geo''.indiceY)^(1/`anios_geo')-1)*100 if anio == `k'
	}	

	* Valor presente *
	capture confirm existence $anioVP
	if _rc == 0 & `aniovp' == -1 {
		local aniovp = $anioVP
	}
	if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
			continue, break
		}
	}
	g double deflator = indiceY/indiceY[`obsvp']
	label var deflator "Deflactor"



	***********
	** 3 PIB **
	***********
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
	
	g double var_pibG = ((pibYR/L`=4*`anios_geo''.pibYR)^(1/`anios_geo')-1)*100
	label var var_pibG "Geometric mean (`anios_geo' years)"
	
	* Grafica historica *
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
			subtitle(Crecimiento anual) ///
			ytitle(percentaje) xtitle("") ///
			text(`crec_PIB') ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci${o}n del INEGI, BIE.}") ///
			note("{bf:${U}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(PIBH, replace)

		*graph export `"`c(sysdir_personal)'/users/`id'/PIBH.png"', replace name(PIBH)
	}


	*****************************
	** 3.1 Parametros exogenos **
	* Imputar *
	forvalues k=`anio_last'(1)`anio_fin' {
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
		replace var_pibG = ((pibYR/L`=4*`anios_geo''.pibYR)^(1/`anios_geo')-1)*100 if anio == `k'
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
			global PIB`=anio[`k']' = pibY[`k']
			global DEF`=anio[`k']' = deflator[`k']
			global pib`=anio[`k']' = var_pibY[`k']
			global def`=anio[`k']' = var_indiceY[`k']
		}
	}

	if "`graphs'" == "graphs" {
		* Texto sobre lineas *
		forvalues k=1(2)`=_N' {
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
		
		twoway (connected var_indiceY anio), ///
			title({bf:${I}ndice de precio impl${i}citos}) ///
			subtitle(Observado y proyectado) ///
			ytitle(percentaje) xtitle("") ///
			text(`crec_indicep') ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci${o}n del INEGI, BIE.}") ///
			note("{bf:Nota}: Promedio m${o}vil geom${e}trico de `anios_geo' a${ni}os despu${e}s de `anio_last'. `exceptI'{bf:${U}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(deflactorP, replace) ///
			legend(on)
		*graph export `"`c(sysdir_personal)'/users/`id'/DeflactorP.png"', replace name(deflactorP)


		twoway (connected var_pibY anio), ///
			title({bf:Producto Interno Bruto}) ///
			subtitle(Observado y proyectado) ///
			ytitle(percentaje) xtitle("") ///
			text(`crec_PIBp') ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci${o}n del INEGI, BIE.}") ///
			note("{bf:Nota}: Promedio m${o}vil geom${e}trico de `anios_geo' a${ni}os despu${e}s de `anio_last'. `except'{bf:${U}ltimo dato}: `anio_last'q`trim_last'.") ///
			name(PIBP, replace) ///
			legend(on)
		*graph export `"`c(sysdir_personal)'/users/`id'/PIBP.png"', replace name(PIBP)
	}
}
end
