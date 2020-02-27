program define PIBDeflactor, return
quietly {
	version 13.1
	syntax [, ANIOvp(int -1) GEO(int 5) FIN(int -1) Graphs UPDATE DIScount(real 3)]



	***********************
	*** 0 Base de datos ***
	***********************
	Poblacion, anio(`aniovp') `graphs' `update'
	collapse (sum) WorkingAge=poblacion if edad >= 16 & edad <= 65, by(anio)
	format WorkingAge %15.0fc
	tempfile workingage
	save `workingage'
	
	/* Verifica si se puede usar la base, si no es así o la opción update es llamada, 
	limpia la base y la usa */
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor`=subinstr("${pais}"," ","",.)'.dta"', clear
	if _rc != 0 | "`update'" == "update" {
		run `"`c(sysdir_personal)'/PIBDeflactorBase`=subinstr("${pais}"," ","",.)'.do"'
		use `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor`=subinstr("${pais}"," ","",.)'.dta"', clear
	}
	local anio_first = anio[1]
	local anio_last = anio[_N]
	capture local trim_last = trimestre[_N]
	if _rc == 0 {
		local trim_last = "q`trim_last'"
	}

	merge 1:1 (anio) using `workingage', nogen
	drop if anio < `anio_first'
	if `fin' == -1 {
		local fin = anio[_N]
	}
	
	global discount = `discount'



	*******************
	*** 1 Deflactor ***
	*******************
	* Time series operators: L = lag *
	tsset anio
	g double var_indiceY = (indiceY/L.indiceY-1)*100
	label var var_indiceY "Anual"

	g double var_indiceG = ((indiceY/L`=`geo''.indiceY)^(1/`geo')-1)*100
	label var var_indiceG "Promedio geom{c e'}trico (`geo' a{c n~}os)"



	***********************************************
	** 2.1 Imputar Par{c a'}metros ex{c o'}genos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k' & trimestre != 4
			local exceptI "`exceptI'`k' (${def`k'}%), "
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k' & trimestre != 4
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k' & trimestre != 4
		replace var_indiceG = ((indiceY/L`=`geo''.indiceY)^(1/`geo')-1)*100 if anio == `k' & trimestre != 4
	}	

	* Valor presente *
	if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
		}
		if anio[`k'] == `anio_last' {
			local obslast = `k'
		}
	}
	g double deflator = indiceY/indiceY[`obsvp']
	label var deflator "Deflactor"
	


	*************
	*** 3 PIB ***
	*************
	g double pibYR = pibY/deflator
	label var pibYR "PIB Real (`=anio[`obsvp']')"
	format pibYR %25.0fc

	g double var_pibY = (pibYR/L.pibYR-1)*100
	label var var_pibY "Anual"
	
	g double var_pibG = ((pibYR/L`=`geo''.pibYR)^(1/`geo')-1)*100
	label var var_pibG "Geometric mean (`geo' years)"



	***************************************
	** 3.1 Par{c a'}metros ex{c o'}genos **
	replace currency = currency[`obslast']
	g OutputPerWorker = pibYR/WorkingAge

	* Crecimiento promedio del producto por trabajador en los últimos diez años *
	scalar lambda = ((OutputPerWorker[`obslast']/OutputPerWorker[`=`obslast'-10'])^(1/10)-1)*100

	* Imputar *
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k' & trimestre != 4
			local except "`except'`k' (${pib`k'}%), "
		}
		else {
			replace var_pibY = L.var_pibG if anio == `k' & trimestre != 4
		}
		replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k' & trimestre != 4
		replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' & trimestre != 4
	}		

	* Lambda (productividad) *
	g lambda = (1+scalar(lambda)/100)^(anio-`anio_last')
	*replace lambda = 1

	replace pibYR = `=pibYR[`obslast']'/`=WorkingAge[`obslast']'*WorkingAge* ///
		(1+scalar(lambda)/100)^(anio-`anio_last') if pibYR == .
	replace pibY = pibYR*deflator if pibY == .
	replace var_pibG = ((pibYR/L`=`geo''.pibYR)^(1/`geo')-1)*100
	replace var_pibY = (pibYR/L.pibYR-1)*100
	g double pibYVP = pibYR/(1+`discount'/100)^(anio-`=anio[`obsvp']')
	format pibYVP %20.0fc
	
	replace OutputPerWorker = pibYR/WorkingAge if OutputPerWorker == .



	*****************
	** 4 Simulador **
	*****************
	noisily di _newline in g " Output per worker: " in y _col(35) %10.1fc OutputPerWorker[`obsvp'] in g " `=currency[`obsvp']'"
	noisily di in g " Lambda (productividad): " in y _col(35) %10.4f scalar(lambda) in g " %" 
	
	scalar pibINF = pibYR[_N]*((pibYR[_N]/pibYR[_N-10])^(1/10))*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')/((`discount'/100)-((pibYR[_N]/pibYR[_N-10])^(1/10)-1))
	noisily di in g " PIBR `=anio[_N]' al infinito: " in y _col(25) %20.0fc pibINF in g " `=currency[`obsvp']'"

	*if "`globals'" == "globals" {
		*forvalues k=1(1)`=_N' {
		*	global PIB_`=anio[`k']' = pibY[`k']
		*	global DEF_`=anio[`k']' = deflator[`k']
		*	global pib_`=anio[`k']' = var_pibY[`k']
		*	global def_`=anio[`k']' = var_indiceY[`k']
		*}
	*}
	
	
	if "`graphs'" == "graphs" {

		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=anio[`k']' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}
		
		* Deflactor *
		twoway (connected var_indiceY anio if anio <= `anio_last') ///
			(connected var_indiceY anio if anio > `anio_last'), ///
			title("{bf:{c I'}ndice de precios impl{c i'}citos}") ///
			subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)') ///
			ytitle("Variaci{c o'}n anual (%)") xtitle("") yline(0) ///
			text(`crec_deflactor', place(c)) ///
			legend(label(1 "Observado") label(2 "Proyectado")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'`trim_last'.") ///
			name(deflactorH, replace)
			
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/deflactorH.png", replace name(deflactorH)
		}

		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_pibY[`k'] != . {
				local crec_PIB `"`crec_PIB' `=var_pibY[`k']' `=anio[`k']' "`=string(var_pibY[`k'],"%5.1fc")'" "'
			}
		}
		
		* Crecimiento PIB *
		twoway (connected var_pibY anio if anio <= `anio_last') ///
			(connected var_pibY anio if anio > `anio_last'), ///
			title({bf:Producto Interno Bruto}) ///
			subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)') ///
			ytitle("Crecimiento real (%)") xtitle("") yline(0, lcolor(black)) ///
			text(`crec_PIB') ///
			legend(label(1 "Observado") label(2 "Proyectado")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'`trim_last'.") ///
			name(PIBH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIBH.png", replace name(PIBH)
		}


		* PIB real *
		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000
		twoway (area `pibYRmil' anio if anio <= `anio_last') ///
			(area `pibYRmil' anio if anio > `anio_last'), ///
			title({bf:Producto Interno Bruto}) ///
			subtitle(${pais}) ///
			ytitle(millones `=currency[`obsvp']' `aniovp') xtitle("") yline(0) ///
			text(`=`pibYRmil'[1]*.05' `=`anio_last'-.5' "`anio_last'", place(nw) color(white)) ///
			text(`=`pibYRmil'[1]*.05' `=anio[1]+.5' "Observado" ///
			`=`pibYRmil'[1]*.05' `=`anio_last'+1.5' "Proyectado", place(ne) color(white)) ///
			xlabel(`=anio[1]' `=round(anio[1],10)'(10)`=round(anio[_N],10)') ///
			ylabel(#4, format(%10.0fc)) ///
			xline(`anio_last'.5) ///
			yscale(range(0)) ///
			legend(label(1 "Observado") label(2 "Proyecci{c o'}n") off) ///
			note("{bf:Nota}: Crecimiento promedio anual de la producitividad (lambda): `=string(scalar(lambda),"%6.3f")'%. {bf:{c U'}ltimo dato}: `anio_last'`trim_last'.") ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			name(PIBP, replace)
	}

	
	return local except "`except'"
	return local exceptI "`exceptI'"
	return scalar geo = `geo'



	***************
	*** 5 Texto ***
	***************
	noisily di _newline in g "  A{c n~}o" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(64) %8.4fc "Deflactor"
	forvalues k=`=`obsvp'-5'(1)`=`obsvp'+5' {
		if anio[`k'] <= `anio_last' | (anio[`k'] == `anio_last' & trimestre < 4) {
			noisily di in g " `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.4fc in y var_indiceY[`k'] " %" _col(65) %8.4fc deflator[`k']
		}
		else {
			capture confirm existence `firstrow'
			if _rc != 0 {
				noisily di in g _dup(72) "-"
				local firstrow "firstrow"
			}
			noisily di in g "{bf: `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.4fc in y var_indiceY[`k'] " %" _col(65) %8.4fc deflator[`k'] "}"
		}
	}

}
end
