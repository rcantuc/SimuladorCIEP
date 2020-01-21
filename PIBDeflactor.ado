program define PIBDeflactor, return
quietly {
	version 13.1
	syntax [, ANIOvp(int -1) GEO(int 5) FIN(int -1) Graphs UPDATE DIScount(real 3)]




	***********************
	*** 0 Base de datos ***
	***********************
	capture confirm file `"`c(sysdir_site)'../basesCIEP/SIM/Poblacion${pais}.dta"'
	if _rc == 0 | "`update'" == "update" {
		use `"`c(sysdir_site)'../basesCIEP/SIM/Poblacion${pais}.dta"', clear
		collapse (sum) WorkingAge=poblacion if edad >= 16 & edad <= 65, by(anio)
		format WorkingAge %15.0fc
		tempfile workingage
		save `workingage'
	}
	
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor${pais}.dta"', clear
	if _rc != 0 | "`update'" == "update" {
		run "`c(sysdir_personal)'/PIBDeflactorBase${pais}.do"
		use `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor${pais}.dta"', clear
	}
	local anio_first = anio[1]
	local anio_last = anio[_N]

	merge 1:1 (anio) using `workingage', nogen
	drop if anio < `anio_first'
	if `fin' == -1 {
		local fin = anio[_N]
	}
	
	if "$discount" != "" {
		local discount = $discount
	}




	*******************
	*** 1 Deflactor ***
	*******************
	tsset anio
	g double var_indiceY = (indiceY/L.indiceY-1)*100
	label var var_indiceY "Anual"

	g double var_indiceG = ((indiceY/L`=`geo''.indiceY)^(1/`geo')-1)*100
	label var var_indiceG "Promedio geom{c e'}trico (`geo' a{c n~}os)"



	***********************************
	** 2.1 Par{c a'}metros ex{c o'}genos **
	*tsappend, add(`=`fin'-`=anio[_N]'') //tsfmt(ty)

	* Imputar *
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k'
			local exceptI "`exceptI'`k' (${def`k'}%), "
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k'
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k'
		replace var_indiceG = ((indiceY/L`=`geo''.indiceY)^(1/`geo')-1)*100 if anio == `k'
	}	

	* Valor presente *
	capture confirm existence $anioVP
	if _rc == 0 & `aniovp' == -1 {
		local aniovp = $anioVP
	}
	else if `aniovp' == -1 {
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
	label var pibYR "PIB Real (`=anio[`obsvp'])"
	format pibYR %25.0fc

	g double var_pibY = (pibYR/L.pibYR-1)*100
	label var var_pibY "Anual"
	*label var var_pibY "Year On Year"
	
	g double var_pibG = ((pibYR/L`=`geo''.pibYR)^(1/`geo')-1)*100
	label var var_pibG "Geometric mean (`geo' years)"



	***************************************
	** 3.1 Par{c a'}metros ex{c o'}genos **
	replace currency = currency[`obslast']
	g OutputPerWorker = pibYR/WorkingAge
	scalar lambda = ((OutputPerWorker[`obslast']/OutputPerWorker[`=`obslast'-10'])^(1/10)-1)*100

	* Imputar *
	g lambda = .
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k'
			local except "`except'`k' (${pib`k'}%), "
			local bold`k' "bold"
		}
		else {
			replace var_pibY = L.var_pibG if anio == `k'
		}
		replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k'
		replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k'
	}		

	replace lambda = (1+scalar(lambda)/100)^(anio-`anio_last')
	replace pibYR = `=pibYR[`obsvp']'/`=WorkingAge[`obsvp']'*WorkingAge* ///
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
	noisily di _newline(2) in g "Output per worker: " in y _col(25) %10.1fc OutputPerWorker[`obsvp'] " `=currency[`obsvp']'"
	noisily di in g "Lambda (productividad): " in y _col(25) %10.4f scalar(lambda) " %" 
	
	scalar pibINF = pibYR[_N]*((pibYR[_N]/pibYR[_N-10])^(1/10))*(1+`discount'/100)^((`=anio[`obsvp']'-`=anio[_N]')/(((pibYR[_N]/pibYR[_N-10])^(1/10)-1)-(`discount'/100)))
	noisily di in g "PIB `=anio[_N]' al infinito: " in y _col(25) %20.0fc pibINF

	*if "`globals'" == "globals" {
		forvalues k=1(1)`=_N' {
			global PIB_`=anio[`k']' = pibY[`k']
			global DEF_`=anio[`k']' = deflator[`k']
			global pib_`=anio[`k']' = var_pibY[`k']
			global def_`=anio[`k']' = var_indiceY[`k']
		}
	*}
	
	
	if "`graphs'" == "graphs" {
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=anio[`k']' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}

		twoway (connected var_indiceY anio if anio <= `anio_last') ///
			(connected var_indiceY anio if anio >= `anio_last'), ///
			title("{bf:{c I'}ndice de precios impl{c i'}citos}") ///
			ytitle("Variaci{c o'}n anual (%)") xtitle("") yline(0) ///
			text(`crec_deflactor', place(c)) ///
			legend(label(1 "Observado") label(2 "Proyectado")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'$trim_last.") ///
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

		twoway (connected var_pibY anio if anio <= `anio_last') ///
			(connected var_pibY anio if anio > `anio_last'), ///
			title({bf:Producto Interno Bruto}) ///
			ytitle("Crecimiento real (%)") xtitle("") yline(0, lcolor(black)) ///
			text(`crec_PIB') ///
			legend(label(1 "Observado") label(2 "Proyectado")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'$trim_last.") ///
			name(PIBH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIBH.png", replace name(PIBH)
		}

		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000
		twoway (area `pibYRmil' anio if anio <= `anio_last') ///
			(area `pibYRmil' anio if anio > `anio_last'), ///
			title({bf:Producto Interno Bruto}) ///
			ytitle(millones de `=currency[`obsvp']' `aniovp') xtitle("") yline(0) ///
			text(`=`pibYRmil'[1]*.05' `=`anio_last'-1' "`anio_last'", place(nw) color(white)) ///
			text(`=`pibYRmil'[1]*.05' `=anio[1]+.5' "Observado" ///
			`=`pibYRmil'[1]*.05' `=`anio_last'+1.5' "Proyectado", place(ne) color(white)) ///
			ylabel(, format(%10.0fc)) xlabel(`=round(`anio_first',10)'(10)`fin') ///
			xline(`anio_last'.5) ///
			yscale(range(0)) ///
			legend(label(1 "Observado") label(2 "Proyecci{c o'}n") off) ///
			note("{bf:Nota}: Crecimiento promedio anual de la producitividad (lambda): `=string(scalar(lambda),"%6.4f")'%. {bf:{c U'}ltimo dato}: `anio_last'$trim_last.") ///
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

	forvalues k=`=`aniovp'-5'(1)`=`aniovp'+5' {
		capture confirm existence `bold`k''
		if _rc != 0 {
			noisily di in g "  `k' " _col(10) %8.4fc in y ${pib_`k'} " %" _col(25) %20.0fc ${PIB_`k'} _col(50) %8.4fc in y ${def_`k'} " %" _col(65) %8.4fc ${DEF_`k'}
		}
		else {
			capture confirm existence `firstrow'
			if _rc != 0 {
				noisily di in g _dup(72) "-"
				local firstrow "firstrow"
			}
			noisily di in g "{bf:  `k' " _col(10) %8.4fc in y ${pib_`k'} " %" _col(25) %20.0fc ${PIB_`k'} _col(50) %8.4fc in y ${def_`k'} " %" _col(65) %8.4fc ${DEF_`k'} "}"
			noisily di in g _dup(72) "-"
		}
	}

}
end
