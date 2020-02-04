program define Simulador
quietly {
	timer on 96
	version 13.1
	syntax varname [if] [fweight/], ///
		[ANIObase(int -1) BOOTstrap(int 1) ///
		Graphs REboot Noisily ///
		REESCalar(real 1) BANDwidth(int 5) ///
		BASE(string) GA ///
		MACro(string) BIE ///
		POBlacion(string) FOLIO(string) ///
		NOKernel POBGraph ID(string)]




	*******************
	*** 0. Defaults ***
	*******************
	if "`base'" == "" {
		local base = "ENIGH 2018"
	}


	** Anio de la BASE **
	tokenize `base'


	** Macros: PIB **
	preserve
	if "`bie'" == "bie" {
		SNA, anio(`aniobase')
		local PIB = r(PIB)
	}
	else {
		PIBDeflactor, anio(`aniobase')
		tempfile PIBBASE
		save `PIBBASE'

		forvalues k=1(1)`=_N' {
			if anio[`k'] == `aniobase' {
				local PIB = pibY[`k']
				local deflactor = deflator[`k']
				continue, break
			}
		}
	}
	restore


	** Poblacion **
	if "`poblacion'" == "" {
		local poblacion = "poblacion"
	}


	** Folio **
	if "`folio'" == "" {
		local folio = "folioviv foliohog"
	}


	** T{c i'}tulo **
	local title : variable label `varlist'
	local nombre `"`=subinstr("`varlist'","_","",.)'"'


	** Texto introductorio **
	noisily di _newline(2) in g "  {bf:Variable label: " in y "`title'}"
	noisily di in g "  {bf:Variable name: " in y "`varlist'}"
	if "`if'" != "" {
		noisily di in g "  {bf:If: " in y "`if'}"
	}
	else {
		noisily di in g "  {bf:If: " in y "Sin restricci{c o'}n. Todas las observaciones utilizadas.}"	
	}
	noisily di in g "  {bf:Bootstraps: " in y `bootstrap' "}" _newline


	** Base original **
	tempfile original
	save `original', replace
	
	
	** Reescalar **
	if `reescalar' != 1 {
		tempvar vartotal proporcion
		egen `vartotal' = sum(`varlist')
		g `proporcion' = `varlist'/`vartotal'
		replace `varlist' = `proporcion'*`reescalar'/`exp'
	}




	************************
	*** 1. Archivos POST ***
	************************
	capture confirm file `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'REC.dta"'
	if "`reboot'" == "reboot" | _rc != 0 {


		******************************
		** 1.1 Variables de control **
		tempvar cont boot
		g double `cont' = 1
		g `boot' = .


		******************
		** 1.2 Archivos **
		capture mkdir `"`c(sysdir_personal)'/users/$pais"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/`id'/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/`id'/graphs/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'"'


		** Per c{c a'}pita **
		postfile PC double(estimacion contribuyentes poblacion montopc edad39) ///
			using `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PC"', replace


		** Perfiles **
		postfile PERF edad double(perfil1 perfil2 contribuyentes1 contribuyentes2 ///
			estimacion1 estimacion2 pobcont1 pobcont2 poblacion1 poblacion2) ///
			using `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PERF"', replace


		** Incidencia por hogares **
		postfile INCI decil double(xhogar distribucion incidencia hogares) ///
			using `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'INCI"', replace


		** Ciclo de vida **
		postfile CICLO bootstrap sexo edad decil escol double(poblacion `varlist') ///
			using `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'CICLO"', replace


		** Proyecciones **
		postfile REC str30 (modulo) int (bootstrap anio aniobase) ///
			double (estimacion contribuyentes poblacion ///
			contribuyentes_Hom contribuyentes_Muj ///
			contribuyentes_0_24 contribuyentes_25_49 ///
			contribuyentes_50_74 contribuyentes_75_mas) ///
			using `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'REC"', replace


		** Cuentas Generacionales **
		if "`GA'" == "GA" {
			postfile GA sexo edad double(`varlist') ///
				using `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'GA"', replace
		}



		*******************
		** 1.3 Bootstrap **
		set seed 1111
		forvalues k = 1(1)`bootstrap' {
			if `bootstrap' != 1 {
				if `k'/5 == int(`k'/5) {
					noisily di in y . _cont
				}
				bsample _N, w(`boot')
			}
			else {
				replace `boot' = 1
			}


			** 1.3.1. Monto per capita **
			* Recaudacion *
			tempname REC REC39
			capture tabstat `varlist' [`weight' = `exp'*`boot'] `if', stat(sum) f(%20.2fc) save
			if _rc == 0 {
				matrix `REC' = r(StatTotal)
			}
			else {
				matrix `REC' = J(1,1,0)
			}
			if "`if'" != "" {
				local if39 = "`if' & edad == 39 & sexo == 1"
			}
			else {
				local if39 = "if edad == 39 & sexo == 1"			
			}
			capture tabstat `varlist' [`weight' = `exp'*`boot'] `if39', stat(sum) f(%20.2fc) save
			if _rc == 0 {
				matrix `REC39' = r(StatTotal)
			}
			else {
				matrix `REC39' = J(1,1,0)
			}

			* Contribuyentes *
			tempname FOR
			capture tabstat `cont' [`weight' = `exp'*`boot'] `if', stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `FOR' = r(StatTotal)
			}
			else {
				matrix `FOR' = J(1,1,0)
			}

			* Poblacion *
			tempname POB POB39
			capture tabstat `cont' [`weight' = `exp'*`boot'], stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `POB' = r(StatTotal)
			}
			else {
				matrix `POB' = J(1,1,0)
			}
			capture tabstat `cont' [`weight' = `exp'*`boot'] `if39', stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `POB39' = r(StatTotal)
			}
			else {
				matrix `POB39' = J(1,1,0)
			}

			* Monto per capita *
			if `FOR'[1,1] != 0 {
				local montopc = `REC'[1,1]/`FOR'[1,1]
			}
			else {
				local montopc = 0
			}
			
			* Edad 39 *
			local edad39 = `REC39'[1,1]/`POB39'[1,1]

			mata: PC = `edad39'

			* Desplegar estadisticos *
			`noisily' di in y "  montopc (`aniobase')"
			`noisily' di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]
			`noisily' di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `POB'[1,1]
			`noisily' di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %25.0fc `FOR'[1,1]
			`noisily' di in g "  Per c{c a'}pita (contr./benef.):" _column(40) in y %25.0fc `montopc'
			`noisily' di in g "  Edad 39 (poblaci{c o'}n):" _column(40) in y %25.0fc `edad39'

			* Guardar resultados POST *
			post PC (`REC'[1,1]) (`FOR'[1,1]) (`POB'[1,1]) (`montopc') (`REC39'[1,1]/`POB39'[1,1])



			*** 1.3.2. Perfiles ***
			`noisily' perfiles `varlist' `if' [`weight' = `exp'*`boot'], montopc(`edad39') post



			*** 1.3.3. Incidencia por hogar ***
			capture confirm variable decil
			tempvar decil
			if _rc != 0 {
				noisily di _newline in g "{bf:  No hay variable: " in y "decil" in g ". Se cre{c o'} con: " in y "`varlist'" in g ".}"
				xtile `decil' = `varlist' [`weight' = `exp'*`boot'], n(10)
			}
			else {
				g `decil' = decil
			}

			capture confirm variable ing_bruto_tot
			tempvar ingreso
			if _rc != 0 {
				g double `ingreso' = `varlist'
				local rellabel "[Sin variable de ingreso total]"
				label var `ingreso' "[Sin variable de ingreso total]"
			}
			else {
				g double `ingreso' = ing_bruto_tot
				local rellabel : variable label ing_bruto_tot
				label var `ingreso' "`rellabel'"
			}

			`noisily' incidencia `varlist' `if' [`weight' = `exp'*`boot'], folio(`folio') n(`decil') ///
				relativo(`ingreso') post



			*** 1.3.4. Ciclo de Vida ***
			`noisily' ciclodevida `varlist' `if' [`weight' = `exp'*`boot'], post boot(`k') decil(`decil')


			*** 1.3.5. Proyecciones ***
			`noisily' proyecciones `varlist', `graphs' post ///
				pob(`poblacion') boot(`k') aniobase(`aniobase')
			
			
			*** 1.3.6. Cuentas Generacionales ***
			if "`GA'" == "GA" {
				`noisily' cuentasgeneracionales `varlist', post ///
					pob(`poblacion') boot(`k') aniobase(`aniobase')
			}

		}


		***********************
		*** 1.4. Post close ***
		postclose PC
		postclose PERF
		postclose INCI
		postclose CICLO
		postclose REC
		if "`GA'" == "GA" {
			postclose GA
		}
	}


	noisily di _newline in y "  Simulador.ado" in g " (post-bootstraps)"


	**************************
	*** 2 Monto per capita ***
	**************************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PC"', clear


	***********************************
	*** 2.1. Intervalo de confianza ***
	ci estimacion
	noisily di _newline in g "  Monto:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"


	*******************************
	*** 2.2 Resultados globales ***
	local RECT = r(mean)/`PIB'*100

	ci contribuyentes
	noisily di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local POBCONTT = r(mean)*`bootstrap'

	ci poblacion
	noisily di in g "  Poblaci{c o'}n potencial:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"

	ci montopc
	noisily di in g "  Per c{c a'}pita:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local montopc_boot = r(mean)


	ci edad39
	noisily di in g "  Edad 39:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local montopc_boot = r(mean)



	******************
	*** 3 Perfiles ***
	******************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PERF"', clear


	*************************
	** 3.1 Texto bootstrap **
	if `bootstrap' > 1 {
		local boottext " Bootstraps: `bootstrap'."
	}


	***********************************
	** 3.2 Variables de los perfiles **
	tempvar perfilH perfilM contH contM

	* Sin kernel *
	if "`nokernel'" == "nokernel" {
		g double `perfilH' = perfil1
		g double `perfilM' = perfil2
		g double `contH' = contribuyentes1
		g double `contM' = contribuyentes2
	}

	* Con kernel *
	else {
		capture confirm variable perfilH
		if _rc != 0 {
			lpoly perfil1 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
				name(PerfilH`varlist', replace) generate(perfilH) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(39 a{c n~}os hombre equivalente) ///
				ylabel(0(.5)1.5) ///
				subtitle(Perfil de hombres) ///
				caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")
			graph save PerfilH`varlist' `"`c(sysdir_personal)'/users/$pais/`id'/graphs/`varlist'PerfilHCI.gph"', replace


			lpoly perfil2 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
				name(PerfilM`varlist', replace) generate(perfilM) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(39 a{c n~}os hombre equivalente) ///
				ylabel(0(.5)1.5) ///
				subtitle(Perfil de mujeres) ///
				caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")
			graph save PerfilM`varlist' `"`c(sysdir_personal)'/users/$pais/`id'/graphs/`varlist'PerfilMCI.gph"', replace


			lpoly contribuyentes1 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
				name(ContH`varlist', replace) generate(contH) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(porcentaje) yscale(range(0 100)) ///
				ylabel(0(20)100) ///
				subtitle(Participaci{c o'}n de hombres) ///
				caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")
			graph save ContH`varlist' `"`c(sysdir_personal)'/users/$pais/`id'/graphs/`varlist'ContHCI.gph"', replace


			lpoly contribuyentes2 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
				name(ContM`varlist', replace) generate(contM) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(porcentaje) yscale(range(0 100)) ///
				ylabel(0(20)100) ///
				subtitle(Participaci{c o'}n de mujeres) ///
				caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")
			graph save ContM`varlist' `"`c(sysdir_personal)'/users/$pais/`id'/graphs/`varlist'ContMCI.gph"', replace

			save `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PERF"', replace
		}
		g double `perfilH' = perfilH
		g double `perfilM' = perfilM
		g double `contH' = contH
		g double `contM' = contM
	}

	label var `perfilH' "{bf:Perfil}: Hombres"
	label var `perfilM' "{bf:Perfil}: Women"
	label var `contH' "{bf:Participaci{c o'}n}: Hombres"
	label var `contM' "{bf:Participaci{c o'}n}: Women"




	***********************
	*** 4. Incidencia *****
	***********************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'INCI"', clear
	format xhogar %15.1fc
	format distribucion %6.1fc
	format incidencia %6.1fc
	
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nacional"
	label values decil deciles


	**********************
	*** 4.1. Por hogar ***
	levelsof decil, local(deciles)
	noisily di _newline in g "  Decil" _column(20) %20s "Por hogar"
	foreach k of local deciles {
		ci xhogar if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.0fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}


	*************************
	*** 4.2. Distribucion ***
	noisily di _newline in g "  Decil" _column(20) %20s "Distribuci{c o'}n"
	foreach k of local deciles {
		ci distribucion if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}


	***********************
	*** 4.3. Incidencia ***
	noisily di _newline in g "  Decil" _column(20) %20s "Incidencia (% `rellabel')"
	foreach k of local deciles {
		ci incidencia if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}



	************************
	*** 5. CICLO DE VIDA ***
	************************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'CICLO"', clear
	
	* Labels *
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nacional"
	label values decil deciles

	replace escol = 3 if escol == 4
	label define escol 0 "Ninguna" 1 "B{c a'}sica" 2 "Media superior" 3 "Superior o posgrado"
	label values escol escol
	
	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo



	***********************************
	*** 5.1 Piramide de la variable ***
	poblaciongini `varlist', title("`title'") nombre(`nombre') boottext(`boottext') rect(`RECT') base(`base') `graphs' id(`id')



	**************************************
	*** 6. Proyecciones de largo plazo ***
	**************************************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'REC"', clear


	******************
	*** 6.1 Macro ***
	if "`macro'" != "" {
		*********AQUI*********
		preserve
		DatosAbiertos `macro'
		rename monto `macro'
		label var `macro' "`=nombre[1]'"

		tempfile macroshcp
		save `macroshcp'
		restore

		capture merge m:1 (anio) using `macroshcp', nogen keepus(`macro')

		tempvar macro_real
		g double `macro_real' = `macro'/deflator
		local seriehacienda "`macro_real'"
		local labmacro : var label `macro'
	}


	******************************************
	*** 6.2. Mean, upper and lower limits ***
	xtset bootstrap anio
	tempvar annual_growth
	g double `annual_growth' = (estimacion/L.estimacion-1)*100

	levelsof anio if `annual_growth' != ., local(anios)
	noisily di _newline in g "  A{c n~}o" _column(20) %20s "Crecimiento real anual"
	foreach k of local anios {
		if `k' == round(`k',10) {
			ci `annual_growth' if anio == `k'
			local `varlist'_mean = r(mean)
			local `varlist'_min = r(lb)
			local `varlist'_max = r(ub)

			noisily di in g "  `k'" in y _column(20) %20.2fc ``varlist'_mean' "%" ///
				in g "  I.C. (95%): " in y "+/-" %7.2fc (``varlist'_max'/``varlist'_mean'-1)*100 "%"
		}
	}

	tempvar profileproj
	collapse `profileproj'=estimacion contribuyentes poblacion `seriehacienda', by(anio modulo aniobase)
	tsset anio



	*************************
	*** 6.3 OLS Simulador ***
	merge 1:1 (anio) using `PIBBASE', nogen keepus(indiceY pibY* deflator lambda)


	*********AQUI*********
	if "`macro'" != "" {
		tempvar dummy08 dummy14
		g `dummy08' = anio < 2008
		g `dummy14' = anio >= 2014

		* OLS *
		regress `seriehacienda' `profileproj' pibYR `dummy14'
		tempvar predict
		predict `predict'
		replace `predict' = `predict'*deflator/pibY*100
		label var `predict' "Projecci{c o'}n MCO"

		* RECfinal *
		g double estimacion = `predict'/100*pibY
		format estimacion %20.0fc

		* Grafica *
		replace `seriehacienda' = `seriehacienda'*deflator/pibY*100
		label var `seriehacienda' "Observados"
		local gvarpredict "`predict'"
	}
	*********AQUI*********


	replace `profileproj' = `profileproj'*lambda/1000000 //pibYR*100
	label var `profileproj' "Proyecci{c o'}n del perfil"

	/* RECfinal *
	g double profile = `profileproj'/100*pibY
	label var profile "Proyecci{c o'}n del perfil"
	g double montopc = `montopc_boot'
	label var montopc "Per c{c a'}pita"

	capture confirm variable estimacion
	if _rc != 0 {
		g double estimacion = profile
		format estimacion %20.0fc
	}

	*****************/
	*** 6.4 Graphs ***
	if ("`graphs'" == "graphs" | "$graphs" == "on") {
		twoway connected `profileproj' `gvarpredict' `seriehacienda' anio if `profileproj' != ., ///
			ytitle("millones") ///
			yscale(range(0)) /*ylabel(0(1)4)*/ ///
			ylabel(, format(%20.0fc) labsize(small)) ///
			xlabel(, labsize(small) labgap(2)) ///
			xtitle("") ///
			title("{bf:`title'}") ///
			subtitle("Proyecciones demogr{c a'}ficas de largo plazo") ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}") ///
			name(`varlist'Proj, replace)
		graph save `varlist'Proj `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'Proj.gph"', replace
	}

	*capture drop __*
	*drop pibY indiceY
	*format profile contribuyentes poblacion %20.0fc
	*g title = "`title'"
	*save `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'RECFinal"', replace




	*********************************
	*** 7. Cuentas Generacionales ***
	*********************************
	if "`GA'" == "GA" {
		use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'GA"', clear
		
		levelsof edad, local(edades)
		noisily di _newline in g "   Cuenta Generacional" ///
			_column(20) %20s "Hombres" ///
			_column(40) %20s "Mujeres"
		forvalues k = 0(5)109 {
			noisily di in g _col(5) "`k'" _cont
			ci `varlist' if edad >= `k' & edad < `k'+4 & sexo == 1
			noisily di in g _column(23) in y %20.0fc r(mean) _cont
			ci `varlist' if edad >= `k' & edad < `k'+4 & sexo == 2
			noisily di in g _column(43) in y %20.0fc r(mean)
		}


		noisily di _newline in g "   Cuenta Generacional" ///
			_column(20) %20s "Hombres" ///
			_column(40) %20s "Mujeres"

		noisily di in g _col(5) "Z-entenials" _cont
		ci `varlist' if edad >= 0 & edad < 17 & sexo == 1
		noisily di in g _column(23) in y %20.0fc r(mean) _cont
		ci `varlist' if edad >= 0 & edad < 17 & sexo == 2
		noisily di in g _column(43) in y %20.0fc r(mean)

		noisily di in g _col(5) "Milenials" _cont
		ci `varlist' if edad >= 17 & edad < 37 & sexo == 1
		noisily di in g _column(23) in y %20.0fc r(mean) _cont
		ci `varlist' if edad >= 17 & edad < 37 & sexo == 2
		noisily di in g _column(43) in y %20.0fc r(mean)

		noisily di in g _col(5) "Generaci{c o'}n X" _cont
		ci `varlist' if edad >= 37 & edad < 57 & sexo == 1
		noisily di in g _column(23) in y %20.0fc r(mean) _cont
		ci `varlist' if edad >= 37 & edad < 57 & sexo == 2
		noisily di in g _column(43) in y %20.0fc r(mean)

		noisily di in g _col(5) "Baby-Boomers" _cont
		ci `varlist' if edad >= 57 & edad < 77 & sexo == 1
		noisily di in g _column(23) in y %20.0fc r(mean) _cont
		ci `varlist' if edad >= 57 & edad < 77 & sexo == 2
		noisily di in g _column(43) in y %20.0fc r(mean)
	}


	************/
	*** Final ***
	*************
	use `original', clear

	timer off 96
	timer list 96
	noisily di _newline in g "  {bf:`title' time}: " in y round(`=r(t96)/r(nt96)',.1) in g " segs."
}
end



*****************
*** Poblacion ***
*****************
program poblaciongini
	version 13.1
	syntax varname, NOMbre(string) [TITle(string) Rect(real 100) BOOTtext(string) BASE(string) Graphs ID(string)]


	*************************
	*** 1. Variable total ***
	tabstat `varlist', stat(sum) save
	tempname GTOT
	matrix `GTOT' = r(StatTotal)


	******************
	*** 2. Deciles ***
	levelsof decil, local(deciles)
	foreach k of local deciles {
		tabstat `varlist' if decil == `k', stat(sum) save
		tempname GDEC
		matrix `GDEC' = r(StatTotal)
		local gdeclab`k' = `GDEC'[1,1]/`GTOT'[1,1]*100
	}

	* Labels *
	tempvar grupo
	g `grupo' = 1 if decil <= 5
	replace `grupo' = 2 if decil > 5 & decil < 10
	replace `grupo' = 3 if decil == 10

	tempname grupoval
	label define `grupoval' 1 `"{bf:I-V} (`=string(`gdeclab1'+`gdeclab2'+`gdeclab3'+`gdeclab4'+`gdeclab5',"%7.0fc")'%)"' ///
		2 `"{bf:VI-IX} (`=string(`gdeclab6'+`gdeclab7'+`gdeclab8'+`gdeclab9',"%7.0fc")'%)"' ///
		3 `"{bf:X} (`=string(`gdeclab10',"%7.0fc")'%)"'
	label values `grupo' `grupoval'
	label var `grupo' "deciles"


	***************
	*** 3. Sexo ***
	levelsof sexo, local(sexo)
	foreach k of local sexo {
		tabstat `varlist' if sexo == `k', stat(sum) save
		tempname GSEX
		matrix `GSEX' = r(StatTotal)
		local gsexlab`k' = `GSEX'[1,1]/`GTOT'[1,1]*100
	}


	*********************************
	*** 4. Educational attainment ***
	levelsof escol, local(escol)
	foreach k of local escol {
		tabstat `varlist' if escol == `k', stat(sum) save
		tempname GESC
		matrix `GESC' = r(StatTotal)
		local gesclab`k' = `GESC'[1,1]/`GTOT'[1,1]*100
	}

	* Labels *
	tempvar grupoesc
	g `grupoesc' = 1 if escol < 2
	replace `grupoesc' = 2 if escol == 2
	replace `grupoesc' = 3 if escol > 2 & escol != .

	tempname grupoescval
	label define `grupoescval' 1 `"{bf:B{c a'}sica o menos} (`=string(`gesclab0'+`gesclab1',"%7.0fc")'%)"' ///
		2 `"{bf:Media superior} (`=string(`gesclab2',"%7.0fc")'%)"' ///
		3 `"{bf:Superior o m{c a'}s} (`=string(`gesclab3',"%7.0fc")'%)"'
	label values `grupoesc' `grupoescval'
	label var `grupoesc' "escolaridad"


	*****************
	*** 5. Graphs ***
	if "`graphs'" == "graphs" | "$graphs" == "on" {
		graphpiramide `varlist', over(`grupo') title("`title'") rect(`rect') ///
			men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
			boot(`boottext') base(`base') id(`id')
		*graphpiramide `varlist', over(`grupoesc') title("`title'") rect(`rect') ///
			men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
			boot(`boottext') base(`base') id(`id')
	}
end


**********************
*** Pyramid Graphs ***
**********************
program graphpiramide
	version 13.1

	syntax varname, Over(varname) Men(string) Women(string) ///
		[Title(string) BOOTtext(string) Rect(real 100) BASE(string) ID(string)]

	* Title *
	local titleover : variable label `over'

	****************************
	*** 1. Valores agregados ***
	tempname TOT POR
	egen double `TOT' = sum(`varlist')
	g double `POR' = `varlist'/`TOT'*100

	* Max number *
	tempvar PORmax
	egen double `PORmax' = sum(`POR'), by(edad sexo)

	tabstat `PORmax', stat(max min) save
	tempname PORmaxval
	matrix `PORmaxval' = r(StatTotal)

	* By age *
	tempname AGEH AGEM
	tabstat `POR' if edad < 18 & sexo == 1, by(`over') stat(sum) save
	matrix `AGEH' = [r(Stat1),r(Stat2),r(Stat3)]
	tabstat `POR' if edad < 18 & sexo == 2, by(`over') stat(sum) save
	matrix `AGEM' = [r(Stat1),r(Stat2),r(Stat3)]

	tempname AGEH1 AGEM1
	tabstat `POR' if edad >= 18 & edad < 65 & sexo == 1, by(`over') stat(sum) save
	matrix `AGEH1' = [r(Stat1),r(Stat2),r(Stat3)]
	tabstat `POR' if edad >= 18 & edad < 65 & sexo == 2, by(`over') stat(sum) save
	matrix `AGEM1' = [r(Stat1),r(Stat2),r(Stat3)]

	tempname AGEH2 AGEM2
	tabstat `POR' if edad >= 65 & sexo == 1, by(`over') stat(sum) save
	matrix `AGEH2' = [r(Stat1),r(Stat2),r(Stat3)]
	tabstat `POR' if edad >= 65 & sexo == 2, by(`over') stat(sum) save
	matrix `AGEM2' = [r(Stat1),r(Stat2),r(Stat3)]


	*******************
	*** 2. GRAFICAS ***
	* Edades *
	forvalues k=0(1)120 {
		if `k' != 0 & `k' != 5 & `k' != 10 & `k' != 15 & `k' != 20 & `k' != 25 & `k' != 30 ///
			& `k' != 35 & `k' != 40 & `k' != 45 & `k' != 50 & `k' != 55 ///
			& `k' != 60 & `k' != 65 & `k' != 70 & `k' != 75 & `k' != 80 ///
			& `k' != 85 & `k' != 90 & `k' != 95 & `k' != 100 & `k' != 105 ///
			& `k' != 110 & `k' != 115 & `k' != 120 {
			local relabel `"`relabel' `=`k'+1' " " "'
		}
		else {
			local relabel `"`relabel' `=`k'+1' "`k'" "'
		}
	}

	* REC % del PIB * 
	if "`rect'" != "100" {
		local rect `"{bf: Tama{c n~}o}: `=string(`rect',"%6.3fc")' % PIB"'
		*local rect ""
	}
	else {
		local rect ""
	}

	* Base *
	if "`base'" != "" {
		local base " `base'"
	}

	* Boottext *
	if "`boottext'" != "" {
		local boottext " `boottext'"
	}

	graph hbar (sum) `POR' if sexo == 1, ///
		over(`over') over(edad, axis(off noextend noline outergap(0)) descending ///
		relabel(`relabel')) ///
		stack asyvars xalternate ///
		yscale(noextend noline /*range(-7(1)7)*/) ///
		blabel(bar, format(%5.1fc)) ///
		t2title({bf:Hombres} (`men'%), size(medsmall)) ///
		/*t2title({bf:Men} (`men'%), size(medsmall))*/ ///
		ytitle(porcentaje) ///
		/*ytitle(percentage)*/ ///
		ylabel(`=`PORmaxval'[2,1]'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks) ///
		name(H`varlist', replace) ///
		legend(cols(4) pos(6) bmargin(zero) label(1 "") label(2 "") label(3 "`rect'") ///
		label(4 "") label(5 "") label(6 "") label(7 "") label(8 "") label(9 "") ///
		label(10 "") symxsize(0)) ///
		yreverse ///
		plotregion(margin(zero)) ///
		graphregion(margin(zero)) aspectratio(, placement(right))

	graph hbar (sum) `POR' if sexo == 2, ///
		over(`over') over(edad, axis(noextend noline outergap(0)) descending ///
		relabel(`relabel') label(labsize(vsmall) labcolor("122 122 122"))) ///
		stack asyvars ///
		yscale(noextend noline /*range(-7(1)7)*/) /// |
		blabel(bar, format(%5.1fc)) ///
		t2title({bf:Mujeres} (`women'%), size(medsmall)) ///
		/*t2title({bf:Women} (`women'%), size(medsmall))*/ ///
		ytitle(porcentaje) ///
		/*ytitle(percentage)*/ ///
		ylabel(`=`PORmaxval'[2,1]'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks) ///
		name(M`varlist', replace) ///
		legend(cols(4) pos(5) bmargin(zero) size(vsmall) keygap(1) symxsize(3) textwidth(30) forcesize) ///
		plotregion(margin(zero)) ///
		graphregion(margin(zero)) aspectratio(, placement(left))

	graph combine H`varlist' M`varlist', name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)', replace) ycommon ///
		title("{bf:`title'}") ///
		subtitle("Sexo, edad y `titleover'") ///
		/*title("`title' by sex, age and `titleover'")*/ ///
		caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5. Fecha: `c(current_date)', `c(current_time)'.}") ///
		/*caption("{it: Source: Own estimations.`boottext'}")*/ ///
		/*note(`"{bf:Nota}: Porcentajes entre par{c e'}ntesis representan la concentraci{c o'}n de `title' en cada grupo."')*/ ///
		/*note(`"{bf:Note}: Percentages inside parenthesis represent the concentration of `title' in each group."')*/
	
	graph export `"`c(sysdir_personal)'/users/$pais/`id'/graphs/`varlist'_`titleover'.eps"', replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')
	*graph export `"`c(sysdir_personal)'/users/$pais/`id'/`varlist'_`titleover'.png"', replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')

	capture window manage close graph H`varlist'
	capture window manage close graph M`varlist'

end
