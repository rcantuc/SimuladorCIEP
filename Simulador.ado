program define Simulador
quietly {
	timer on 96
	version 13.1
	syntax varname [if] [fweight/], ///
		[BASE(string) ///
		Anio(int $anioVP) BOOTstrap(int 1) ///
		Graphs REboot Noisily ///
		MACro(string) BIE ///
		POBlacion(string) FOLIO(string) NOKernel POBGraph ID(string)]



	*******************
	*** 0. Defaults ***
	*******************

	if "`base'" == "" {
		local base = "ENIGH 2016"
	}


	** Anio de la BASE **
	tokenize `base'
	local aniobase = `2'


	** Macros: PIB **
	preserve
	if "`bie'" == "bie" {
		SNA, anio(`anio')
		local PIB = r(PIB)
	}
	else {
		PIBDeflactor
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anio' {
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


	** T${i}tulo **
	local title : variable label `varlist'
	local nombre `"`=subinstr("`varlist'","_","",.)'"'


	** Texto introductorio **
	noisily di _newline(2) in g "  {bf:Variable label: " in y "`title'}"
	noisily di in g "  {bf:Variable name: " in y "`varlist'}"
	if "`if'" != "" {
		noisily di in g "  {bf:If: " in y "`if'}"
	}
	else {
		noisily di in g "  {bf:If: " in y "Sin restricci${o}n. Todas las observaciones utilizadas.}"	
	}
	noisily di in g "  {bf:Bootstraps: " in y `bootstrap' "}" _newline

	local base ", utilizando el Simulador Fiscal $simuladorCIEP"


	** Base original **
	tempfile original
	save `original', replace




	************************
	*** 1. Archivos POST ***
	************************
	capture confirm file `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'REC.dta"'
	if "`reboot'" == "reboot" | _rc != 0 {


		******************************
		** 1.1 Variables de control **
		tempvar cont boot
		g double `cont' = 1
		g `boot' = .


		******************
		** 1.2 Archivos **
		capture mkdir `"`c(sysdir_personal)'/users/`id'/bootstraps/"'
		capture mkdir `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'"'


		** Per c${a}pita **
		postfile PC double(estimacion contribuyentes poblacion montopc) ///
			using `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'PC"', replace


		** Perfiles **
		postfile PERF edad double(perfil1 perfil2 contribuyentes1 contribuyentes2 ///
			estimacion1 estimacion2 pobcont1 pobcont2 poblacion1 poblacion2) ///
			using `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'PERF"', replace


		** Incidencia por hogares **
		postfile INCI decil double(xhogar distribucion incidencia hogares) ///
			using `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'INCI"', replace


		** Ciclo de vida **
		postfile CICLO bootstrap sexo edad decil entidad escol double(poblacion `varlist') ///
			using `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'CICLO"', replace


		** Proyecciones **
		postfile REC str30 (modulo) int (bootstrap anio aniobase) ///
			double (estimacion contribuyentes poblacion ///
			contribuyentes_Hom contribuyentes_Muj ///
			contribuyentes_0_24 contribuyentes_25_49 ///
			contribuyentes_50_74 contribuyentes_75_mas) ///
			using `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'REC"', replace


		** Cuentas Generacionales **
		postfile GA sexo edad double(`varlist') ///
			using `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'GA"', replace


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
			** Recaudacion **
			tempname REC
			capture tabstat `varlist' [`weight' = `exp'*`boot'] `if', stat(sum) f(%20.2fc) save
			if _rc == 0 {
				matrix `REC' = r(StatTotal)
			}
			else {
				matrix `REC' = J(1,1,0)
			}


			** Contribuyentes **
			tempname FOR
			capture tabstat `cont' [`weight' = `exp'*`boot'] `if', stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `FOR' = r(StatTotal)
			}
			else {
				matrix `FOR' = J(1,1,0)
			}


			** Poblacion **
			tempname POB
			capture tabstat `cont' [`weight' = `exp'*`boot'], stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `POB' = r(StatTotal)
			}
			else {
				matrix `POB' = J(1,1,0)
			}


			** Monto per capita **
			if `FOR'[1,1] != 0 {
				local montopc = `REC'[1,1]/`FOR'[1,1]
			}
			else {
				local montopc = 0
			}
			mata: PC = `montopc'


			** Desplegar estadisticos **
			`noisily' di in y "  montopc (`aniobase')"
			`noisily' di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]
			`noisily' di in g "  Poblaci${o}n:" _column(40) in y %25.0fc `POB'[1,1]
			`noisily' di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %25.0fc `FOR'[1,1]
			`noisily' di in g "  Per c${a}pita:" _column(40) in y %25.0fc `montopc'

			* Guardar resultados POST *
			post PC (`REC'[1,1]) (`FOR'[1,1]) (`POB'[1,1]) (`montopc')


			*** 1.3.2. Perfiles ***
			`noisily' perfiles `varlist' `if' [`weight' = `exp'*`boot'], montopc(`montopc') post


			*** 1.3.3. Incidencia por hogar ***
			capture confirm variable decil
			tempvar decil
			if _rc != 0 {
				xtile `decil' = `varlist' [`weight' = `exp'*`boot'], n(10)
			}
			else {
				g `decil' = decil
			}

			capture confirm variable ing_bruto_tot
			tempvar ingreso
			if _rc != 0 {
				g double `ingreso' = ing_anual
				local rellabel : variable label ing_anual
				label var `ingreso' "`rellabel'"

			}
			else {
				g double `ingreso' = ing_bruto_tot
				local rellabel : variable label ing_bruto_tot
				label var `ingreso' "`rellabel'"
			}

			`noisily' incidencia `varlist' `if' [`weight' = `exp'*`boot'], folio(`folio') n(`decil') ///
				relativo(`ingreso') post


			*** 1.3.4. Ciclo de Vida ***
			`noisily' CicloDeVida `varlist' `if' [`weight' = `exp'*`boot'], post boot(`k')


			*** 1.3.5. Proyecciones ***
			`noisily' proyecciones `varlist', `graphs' post ///
				pob(`poblacion') boot(`k') aniobase(`aniobase')
			
			
			*** 1.3.6. Cuentas Generacionales ***
			`noisily' CuentasGeneracionales `varlist', post ///
				pob(`poblacion') boot(`k') aniobase(`aniobase')

		}


		***********************
		*** 1.4. Post close ***
		postclose PC
		postclose PERF
		postclose INCI
		postclose CICLO
		postclose REC
		postclose GA
	}




	**************************
	*** 2 Monto per capita ***
	**************************
	use `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'PC"', clear


	***********************************
	*** 2.1. Intervalo de confianza ***
	ci estimacion
	noisily di _newline in g "   Monto:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"


	*******************************
	*** 2.2 Resultados globales ***
	local RECT = r(mean)/`PIB'*100

	ci contribuyentes
	noisily di in g "   Contribuyentes/Beneficiarios:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local POBCONTT = r(mean)*`bootstrap'

	ci poblacion
	noisily di in g "   Poblaci${o}n potencial:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"

	ci montopc
	noisily di in g "   Per c${a}pita:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local montopc_boot = r(mean)




	******************
	*** 3 Perfiles ***
	******************
	use `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'PERF"', clear


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
			capture mkdir "`c(sysdir_personal)'/users/`id'/annexes"

			lpoly perfil1 edad, bwidth(5) ci kernel(gaussian) degree(2) ///
				name(PerfilH`varlist', replace) generate(perfilH) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(per c${a}pita equivalente) ylabel(0(1)3) ///
				subtitle(Perfil de hombres) ///
				caption("{it: Fuente: Elaborado por el CIEP`base'.`boottext'}")
			graph save PerfilH`varlist' `"`c(sysdir_personal)'/users/`id'/annexes/`varlist'PerfilHCI.gph"', replace


			lpoly perfil2 edad, bwidth(5) ci kernel(gaussian) degree(2) ///
				name(PerfilM`varlist', replace) generate(perfilM) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(per c${a}pita equivalente) ylabel(0(1)3) ///
				subtitle(Perfil de mujeres) ///
				caption("{it: Fuente: Elaborado por el CIEP`base'.`boottext'}")
			graph save PerfilM`varlist' `"`c(sysdir_personal)'/users/`id'/annexes/`varlist'PerfilMCI.gph"', replace


			lpoly contribuyentes1 edad, bwidth(5) ci kernel(gaussian) degree(2) ///
				name(ContH`varlist', replace) generate(contH) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(porcentaje) yscale(range(0 100)) ///
				ylabel(0(20)100) ///
				subtitle(Participaci${o}n de hombres) ///
				caption("{it: Fuente: Elaborado por el CIEP`base'.`boottext'}")
			graph save ContH`varlist' `"`c(sysdir_personal)'/users/`id'/annexes/`varlist'ContHCI.gph"', replace


			lpoly contribuyentes2 edad, bwidth(5) ci kernel(gaussian) degree(2) ///
				name(ContM`varlist', replace) generate(contM) at(edad) noscatter ///
				title("{bf:`title'}") ///
				xtitle(edad) ///
				ytitle(porcentaje) yscale(range(0 100)) ///
				ylabel(0(20)100) ///
				subtitle(Participaci${o}n de mujeres) ///
				caption("{it: Fuente: Elaborado por el CIEP`base'.`boottext'}")
			graph save ContM`varlist' `"`c(sysdir_personal)'/users/`id'/annexes/`varlist'ContMCI.gph"', replace

			save `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'PERF"', replace
		}
		g double `perfilH' = perfilH
		g double `perfilM' = perfilM
		g double `contH' = contH
		g double `contM' = contM
	}

	label var `perfilH' "{bf:Perfil}: Hombres"
	label var `perfilM' "{bf:Perfil}: Women"
	label var `contH' "{bf:Participaci${o}n}: Hombres"
	label var `contM' "{bf:Participaci${o}n}: Women"


	*****************
	** 3.3 Grafica **
	if "`graphs'" == "graphs" | "$graphs" == "on" {


		*** 3.3.1. Maximos ***
		foreach k in perfilH perfilM contH contM {
			sort ``k''
			local ``k''_max = ``k'' in -1
			local ``k''_edad = edad in -1
		}


		*** 3.3.2. Poblacion ***
		tempname POBLAC
		tabstat poblacion*, stat(sum) f(%25.2fc) save
		matrix `POBLAC' = r(StatTotal)
		local POBLAC = (`POBLAC'[1,1]+`POBLAC'[1,2])


		*** 3.3.3. Recaudacion ***
		* Por edades *
		tempname REC16
		tabstat estimacion* if edad < 18, stat(sum) f(%25.2fc) save
		matrix `REC16' = r(StatTotal)
		local REC16 = (`REC16'[1,1]+`REC16'[1,2])/(`PIB'*`bootstrap')*100

		tempname REC1764
		tabstat estimacion* if edad < 65 & edad >= 18, stat(sum) f(%25.2fc) save
		matrix `REC1764' = r(StatTotal)
		local REC1764 = (`REC1764'[1,1]+`REC1764'[1,2])/(`PIB'*`bootstrap')*100

		tempname REC65
		tabstat estimacion* if edad >= 65, stat(sum) f(%25.2fc) save
		matrix `REC65' = r(StatTotal)
		local REC65 = (`REC65'[1,1]+`REC65'[1,2])/(`PIB'*`bootstrap')*100


		*** 3.3.4. Contribuyentes ***
		tempname POBCONT
		tabstat pobcont*, stat(sum) f(%25.2fc) save
		matrix `POBCONT' = r(StatTotal)
		local POBCONT = (`POBCONT'[1,1]+`POBCONT'[1,2])
		
		* Por edades *
		tempname POBCONT16
		tabstat pobcont* if edad < 18, stat(sum) f(%25.2fc) save
		matrix `POBCONT16' = r(StatTotal)
		local POBCONT16 = (`POBCONT16'[1,1]+`POBCONT16'[1,2])

		tempname POBCONT1764
		tabstat pobcont* if edad < 65 & edad >= 18, stat(sum) f(%25.2fc) save
		matrix `POBCONT1764' = r(StatTotal)
		local POBCONT1764 = (`POBCONT1764'[1,1]+`POBCONT1764'[1,2])

		tempname POBCONT65
		tabstat pobcont* if edad >= 65, stat(sum) f(%25.2fc) save
		matrix `POBCONT65' = r(StatTotal)
		local POBCONT65 = (`POBCONT65'[1,1]+`POBCONT65'[1,2])


		*** 3.3.5. Grafica ***
		local TSY`nombre' = `REC16'/`RECT'*100
		local TSM`nombre' = `REC1764'/`RECT'*100
		local TSO`nombre' = `REC65'/`RECT'*100

		local TPSY`nombre' = `POBCONT16'/`POBCONT'*100
		local TPSM`nombre' = `POBCONT1764'/`POBCONT'*100
		local TPSO`nombre' = `POBCONT65'/`POBCONT'*100
	}




	***********************
	*** 4. Incidencia *****
	***********************
	use `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'INCI"', clear
	format xhogar %15.1fc
	format distribucion %6.1fc
	format incidencia %6.1fc
	
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nacional"
	label values decil deciles


	**********************
	*** 4.1. Por hogar ***
	levelsof decil, local(deciles)
	noisily di _newline in g "   Decil" _column(20) %20s "Por hogar"
	foreach k of local deciles {
		ci xhogar if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "    `decil2'" _column(20) in y %20.0fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}


	*************************
	*** 4.2. Distribucion ***
	noisily di _newline in g "   Decil" _column(20) %20s "Distribuci${o}n"
	foreach k of local deciles {
		ci distribucion if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "    `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}


	***********************
	*** 4.3. Incidencia ***
	noisily di _newline in g "   Decil" _column(20) %20s "Incidencia (% `rellabel')"
	foreach k of local deciles {
		ci incidencia if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "    `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}



	***************
	*** 5. Gini ***
	***************
	use `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'CICLO"', clear
	
	* Labels *
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nacional"
	label values decil deciles

	label define escol 0 "Ninguna" 1 "B${a}sica" 2 "Media superior" 3 "Superior" 4 "Posgrado"
	label values escol escol
	
	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo
	
	label define entidad 1 "Aguascalientes" 2 "Baja California" 3 "Baja California Sur" 4 "Campeche" 5 "Coahuila" 6 "Colima" ///
		7 "Chiapas" 8 "Chihuahua" 9 "Distrito Federal" 10 "Durango" 11 "Guanajuato" 12 "Guerrero" 13 "Hidalgo" 14 "Jalisco" ///
		15 "Edo. de M${e}xico" 16 "Michoac${a}n" 17 "Morelos" 18 "Nayarit" 19 "Nuevo Le${o}n" 20 "Oaxaca" 21 "Puebla" 22 "Quer${e}taro" ///
		23 "Quintana Roo" 24 "San Luis Potos${i}" 25 "Sinaloa" 26 "Sonora" 27 "Tabasco" 28 "Tamaulipas" 29 "Tlaxcala" ///
		30 "Veracruz" 31 "Yucat${a}n" 32 "Zacatecas"
	label values entidad entidad


	********************************
	*** 5.1 Piramide demografica ***
	if "`pobgraph'" == "pobgraph" {
		poblaciongini poblacion, title(Population) nombre(`nombre') boottext(`boottext') base(`base') `graphs' id(`id')
	}


	************************************
	*** 5.2. Piramide de la variable ***
	poblaciongini `varlist', title("`title'") nombre(`nombre') boottext(`boottext') rect(`RECT') base(`base') `graphs' id(`id')



	**************************************
	*** 6. Proyecciones de largo plazo ***
	**************************************
	use `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'REC"', clear


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
	noisily di _newline in g "   A${ni}o" _column(20) %20s "Crecimiento real anual"
	foreach k of local anios {
		ci `annual_growth' if anio == `k'
		local `varlist'_mean = r(mean)
		local `varlist'_min = r(lb)
		local `varlist'_max = r(ub)

		noisily di in g "    `k'" in y _column(20) %20.2fc ``varlist'_mean' "%" ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (``varlist'_max'/``varlist'_mean'-1)*100 "%"
	}

	tempvar profileproj
	collapse `profileproj'=estimacion contribuyentes poblacion `seriehacienda', by(anio modulo aniobase)
	tsset anio



	*************************
	*** 6.3 OLS Simulador ***
	preserve
	PIBDeflactor
	tempfile PIB
	save `PIB'
	restore

	merge 1:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator productivity)


	if "`macro'" != "" {
	


	
		*********AQUI*********



		tempvar dummy08 dummy14
		g `dummy08' = anio < 2008
		g `dummy14' = anio >= 2014

		* OLS *
		regress `seriehacienda' `profileproj' pibYR `dummy14'
		tempvar predict
		predict `predict'
		replace `predict' = `predict'*deflator/pibY*100
		label var `predict' "Projecci${o}n MCO"

		* RECfinal *
		g double estimacion = `predict'/100*pibY
		format estimacion %20.0fc

		* Grafica *
		replace `seriehacienda' = `seriehacienda'*deflator/pibY*100
		label var `seriehacienda' "Observados"
		local gvarpredict "`predict'"



	}

	replace `profileproj' = `profileproj'*deflator*productivity/pibY*100
	label var `profileproj' "Proyecci${o}n del perfil"

	* RECfinal *
	g double profile = `profileproj'/100*pibY
	label var profile "Proyecci${o}n del perfil"
	g double montopc = `montopc_boot'
	label var montopc "Per c${a}pita"

	capture confirm variable estimacion
	if _rc != 0 {
		g double estimacion = profile
		format estimacion %20.0fc
	}

	******************
	*** 6.4 Graphs ***
	if ("`graphs'" == "graphs" | "$graphs" == "on") {
		twoway connected `profileproj' `gvarpredict' `seriehacienda' anio, ///
			ytitle(% PIB) ///
			yscale(range(0)) /*ylabel(0(1)4)*/ ///
			ylabel(, format(%5.1fc) labsize(small)) ///
			xlabel(, labsize(small) labgap(2)) ///
			xtitle("") ///
			title("{bf:`title'}") ///
			subtitle(Proyecciones de largo plazo) ///
			caption("Fuente: Elaborado por el CIEP`base'.`boottext'") ///
			name(`varlist'Proj, replace)
		graph save `varlist'Proj `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'Proj.gph"', replace
	}

	capture drop __*
	*drop pibY indiceY
	format profile contribuyentes poblacion %20.0fc

	g title = "`title'"
	save `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'RECFinal"', replace




	*********************************
	*** 7. Cuentas Generacionales ***
	********************************
	use `"`c(sysdir_personal)'/users/`id'/bootstraps/`bootstrap'/`varlist'GA"', clear
	
	levelsof edad, local(edades)
	noisily di _newline in g "   Cuenta Generacional" ///
		_column(20) %20s "Hombres" ///
		_column(40) %20s "Mujeres"
	forvalues k = 0(5)109 {
		noisily di in g _col(5) "`k'" _cont
		ci `varlist' if edad >= `k' & edad < `k'+4 & sexo == 1
		noisily di in g _column(20) in y %20.0fc r(mean) _cont
		ci `varlist' if edad >= `k' & edad < `k'+4 & sexo == 2
		noisily di in g _column(40) in y %20.0fc r(mean)
	}


	noisily di _newline in g "   Cuenta Generacional" ///
		_column(20) %20s "Hombres" ///
		_column(40) %20s "Mujeres"

	noisily di in g _col(5) "Z-entenials" _cont
	ci `varlist' if edad >= 0 & edad < 17 & sexo == 1
	noisily di in g _column(20) in y %20.0fc r(mean) _cont
	ci `varlist' if edad >= 0 & edad < 17 & sexo == 2
	noisily di in g _column(40) in y %20.0fc r(mean)

	noisily di in g _col(5) "Milenials" _cont
	ci `varlist' if edad >= 17 & edad < 37 & sexo == 1
	noisily di in g _column(20) in y %20.0fc r(mean) _cont
	ci `varlist' if edad >= 17 & edad < 37 & sexo == 2
	noisily di in g _column(40) in y %20.0fc r(mean)

	noisily di in g _col(5) "Generaci${o}n X" _cont
	ci `varlist' if edad >= 37 & edad < 57 & sexo == 1
	noisily di in g _column(20) in y %20.0fc r(mean) _cont
	ci `varlist' if edad >= 37 & edad < 57 & sexo == 2
	noisily di in g _column(40) in y %20.0fc r(mean)

	noisily di in g _col(5) "Baby-Boomers" _cont
	ci `varlist' if edad >= 57 & edad < 77 & sexo == 1
	noisily di in g _column(20) in y %20.0fc r(mean) _cont
	ci `varlist' if edad >= 57 & edad < 77 & sexo == 2
	noisily di in g _column(40) in y %20.0fc r(mean)


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
	label define `grupoescval' 1 `"{bf:B${a}sica o menos} (`=string(`gesclab0'+`gesclab1',"%7.0fc")'%)"' ///
		2 `"{bf:Media superior} (`=string(`gesclab2',"%7.0fc")'%)"' ///
		3 `"{bf:Superior o m${a}s} (`=string(`gesclab3'+`gesclab4',"%7.0fc")'%)"'
	label values `grupoesc' `grupoescval'
	label var `grupoesc' "escolaridad"


	*****************
	*** 5. Graphs ***
	if "`graphs'" == "graphs" | "$graphs" == "on" {
		graphpiramide `varlist', over(`grupo') title("`title'") rect(`rect') ///
			men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
			boot(`boottext') base(`base') id(`id')
		graphpiramide `varlist', over(`grupoesc') title("`title'") rect(`rect') ///
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
		local rect `"{bf: Tama${ni}o}: `=string(`rect',"%6.3fc")' % PIB"'
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
		over(`over') over(edad, axis(off) descending) ///
		stack asyvars xalternate ///
		yscale(noextend noline /*range(-7(1)7)*/) ///
		t2title({bf:Hombres} (`men'%), size(medsmall)) ///
		/*t2title({bf:Men} (`men'%), size(medsmall))*/ ///
		ytitle(porcentaje) ///
		/*ytitle(percentage)*/ ///
		/*ylabel(`=`PORmaxval'[2,1]'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks)*/ ///
		ylabel(-7(1)7, format(%7.0fc) noticks) ///
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
		t2title({bf:Mujeres} (`women'%), size(medsmall)) ///
		/*t2title({bf:Women} (`women'%), size(medsmall))*/ ///
		ytitle(porcentaje) ///
		/*ytitle(percentage)*/ ///
		/*ylabel(`=`PORmaxval'[2,1]'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks)*/ ///
		ylabel(-7(1)7, format(%7.0fc) noticks) ///
		name(M`varlist', replace) ///
		legend(cols(4) pos(5) bmargin(zero) size(vsmall) keygap(1) symxsize(3) textwidth(30) forcesize) ///
		plotregion(margin(zero)) ///
		graphregion(margin(zero)) aspectratio(, placement(left))

	graph combine H`varlist' M`varlist', name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)', replace) ycommon ///
		title("`title' por sexo, edad y `titleover'") ///
		/*title("`title' by sex, age and `titleover'")*/ ///
		caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
		/*caption("{it: Source: Own estimations.`boottext'}")*/ ///
		/*note(`"{bf:Nota}: Porcentajes entre par${e}ntesis representan la concentraci${o}n de `title' en cada grupo."')*/ ///
		/*note(`"{bf:Note}: Percentages inside parenthesis represent the concentration of `title' in each group."')*/
	
	graph export `"`c(sysdir_personal)'/users/`id'/`varlist'_`titleover'.eps"', replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')
	*graph export `"`c(sysdir_personal)'/users/`id'/`varlist'_`titleover'.png"', replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')

	capture window manage close graph H`varlist'
	capture window manage close graph M`varlist'

end
