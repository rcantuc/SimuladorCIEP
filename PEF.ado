program define PEF, return
quietly {




	************************
	*** 1. BASE DE DATOS ***
	************************
	* Generar base de datos para el simulador *
	capture confirm file "`c(sysdir_personal)'/bases/SIM/PEF`=c(os)'.dta"
	if _rc != 0 {
		capture confirm file "`c(sysdir_personal)'/bases/PEFs/Nacional/PEFSIM`=c(os)'.dta"
		if _rc != 0 {
			noisily run "`c(sysdir_personal)'/bases/PEFs/Nacional/PEFSIM.do"	// It takes a long, long, long time
		}

		use "`c(sysdir_personal)'/bases/PEFs/Nacional/PEFSIM`=c(os)'.dta", clear
		foreach k of varlist ejercido aprobado {
			tempvar `k'totbase
			egen ``k'totbase' = sum(`k'), by(anio)
		}

		g double gasto = ejercido if `ejercidototbase' != 0
		replace gasto = aprobado if `ejercidototbase' == 0 & `aprobadototbase' != 0
		replace gasto = proyecto if `ejercidototbase' == 0 & `aprobadototbase' == 0
		format %20.0fc gasto ejercido aprobado proyecto

		* Cuotas ISSSTE *
		foreach k of varlist gasto aprobado ejercido proyecto {
			tempvar `k' `k'Tot `k'cuotas `k'cuotasTot

			g ``k'' = `k' if ramo != -1 & neto == 0 & (substr(string(objeto),1,1) == "1")
			replace ``k'' = 0 if ``k'' == .
			egen ``k'Tot' = sum(``k''), by(anio)

			g ``k'cuotas' = `k' if ramo == -1
			egen ``k'cuotasTot' = sum(``k'cuotas'), by(anio)

			g double `k'neto = `k' - ``k''/``k'Tot'*``k'cuotasTot'
			format `k'* %20.0fc

			g double `k'CUOTAS = ``k''/``k'Tot'*``k'cuotasTot'
			format `k'CUOTAS %20.0fc
		}
		
		drop __*
		save "`c(sysdir_personal)'/bases/SIM/PEF`=c(os)'.dta", replace
	}

	
	** 1.2 Syntax **
	use "`c(sysdir_personal)'/bases/SIM/PEF`=c(os)'.dta", clear	
	syntax [if] [, ANIO(int $anioVP) Graphs Update Concepto(string) Base Datosabiertos Remake ID(string) Fast]
	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "GASTOS `anio'}"


	** 1.3 Base ID **
	if "`id'" != "" {
		use "`c(sysdir_personal)'/users/`id'/PEF", clear
	}



	
	**************
	*** 2. PEF ***
	**************
	if "$update" == "on" | "`update'" == "update" | "`remake'" == "remake" {
		use "`c(sysdir_personal)'/bases/SIM/PEF`=c(os)'.dta", clear

		if "`remake'" == "remake" {
			noisily run "`c(sysdir_personal)'/bases/PEFs/Nacional/PEFSIM.do"	// It takes a long, long, long time
		}

		use "`c(sysdir_personal)'/bases/PEFs/Nacional/PEFSIM`=c(os)'.dta", clear
		foreach k of varlist ejercido aprobado {
			tempvar `k'totbase
			egen ``k'totbase' = sum(`k'), by(anio)
		}

		g double gasto = ejercido if `ejercidototbase' != 0
		replace gasto = aprobado if `ejercidototbase' == 0 & `aprobadototbase' != 0
		replace gasto = proyecto if `ejercidototbase' == 0 & `aprobadototbase' == 0
		format %20.0fc gasto ejercido aprobado proyecto

		* Cuotas ISSSTE *
		foreach k of varlist gasto aprobado ejercido proyecto {
			tempvar `k' `k'Tot `k'cuotas `k'cuotasTot

			g ``k'' = `k' if ramo != -1 & neto == 0 & (substr(string(objeto),1,1) == "1")
			replace ``k'' = 0 if ``k'' == .
			egen ``k'Tot' = sum(``k''), by(anio)

			g ``k'cuotas' = `k' if ramo == -1
			egen ``k'cuotasTot' = sum(``k'cuotas'), by(anio)

			g double `k'neto = `k' - ``k''/``k'Tot'*``k'cuotasTot'
			format `k'* %20.0fc

			g double `k'CUOTAS = ``k''/``k'Tot'*``k'cuotasTot'
			format `k'CUOTAS %20.0fc
		}

		*drop if serie == .
		drop __*
		save "`c(sysdir_personal)'/bases/SIM/PEF`=c(os)'.dta", replace
	}

	if "`fast'" == "fast" {
		keep if anio == `anio'
	}

	if "`concepto'" == "" {
		local concepto = "desc_funcion"
	}

	if "`base'" == "base" {
		exit
	}



	************************
	*** 3 Datos Abiertos ***
	************************
	if "`concepto'" == "desc_funcion" {
		rename serie serielabel
		decode serielabel, g(serie)
		local varSerie "serie"
	}
		
	collapse (sum) gasto* aprobado* ejercido* proyecto* `if', by(`concepto' anio neto `varSerie' modulo) fast

	if "`concepto'" == "desc_funcion" & "`datosabiertos'" == "datosabiertos" {
		collapse (sum) gasto* aprobado* ejercido* proyecto* `if', by(`concepto' anio neto `varSerie') fast

		preserve

		levelsof serie, local(serie)
		foreach k of local serie {
			quietly DatosAbiertos `k', nographs

			rename clave_de_concepto serie
			keep anio serie nombre monto mes

			tempfile `k'
			quietly save ``k''
		}

		restore
		
		foreach k of local serie {
			joinby (anio serie) using ``k'', unmatched(both) update
			drop _merge
		}

		* Distribucion bycollapse **
		tempvar bycollapse
		egen `bycollapse' = sum(aprobado), by(`varSerie' anio neto)

		replace gasto = monto*aprobado/`bycollapse' if mes == 12 & (ejercido == . | ejercido == 0) & monto != . & neto == 0
		replace gastoneto = gasto if mes == 12 & (ejercido == . | ejercido == 0) & monto != . & neto == 0
		drop if desc_funcion == . & (monto < 1 | monto == .)

		sort anio desc_funcion
		forvalues k=`=_N'(-1)1 {
			if mes[`k'] != . {
				local textmes = "(mes `=mes[`k']')"
				continue, break
			}
		}
	}




	**************
	*** 3. PIB ***
	**************
	preserve
	PIBDeflactor
	tempfile PIB
	save `PIB'
	restore

	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator var_pibY) update replace keep(matched)
	foreach k of varlist gasto aprobado ejercido proyecto {
		g double `k'PIB = `k'/pibY*100
		g double `k'netoPIB = `k'neto/pibY*100
		format *PIB %10.3fc
	}


	************************************************
	** 3.1 Aportaciones y cuotas de la Federacion **
	capture tabstat gasto gastoPIB if anio == `anio' & neto == 1, stat(sum) f(%20.0fc) save
	tempname Aportaciones_Federacion
	matrix `Aportaciones_Federacion' = r(StatTotal)
	return scalar Aportaciones_Federacion = `Aportaciones_Federacion'[1,1]

	capture tabstat gasto gastoPIB if `concepto' == -1 & anio == `anio', stat(sum) f(%20.0fc) save
	tempname Cuotas_ISSSTE
	matrix `Cuotas_ISSSTE' = r(StatTotal)
	return scalar Cuotas_ISSSTE = `Cuotas_ISSSTE'[1,1]



	
	****************
	*** 4. Graph ***
	****************
	replace `concepto' = 999 if `concepto' == -2
	label define `concepto' 999 "Ingreso b${a}sico", add modify
	
	tempvar over
	g `over' = `concepto'

	tempname label
	label copy `concepto' `label'
	label values `over' `label'

	replace `over' = -99 if (abs(gastonetoPIB) < 1 | gastonetoPIB == .)
	label define `label' -99 "Otros (< 1% PIB)", add modify

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		tabstat aprobadonetoPIB ejercidonetoPIB proyectonetoPIB gastonetoPIB ///
			if anio >= 2013 & anio <= 2018 & `concepto' != -1 & neto == 0, by(anio) stat(sum) save
		tempname r1 r2 r3 r4 r5 r6
		matrix `r1' = r(Stat1)
		matrix `r2' = r(Stat2)
		matrix `r3' = r(Stat3)
		matrix `r4' = r(Stat4)
		matrix `r5' = r(Stat5)
		matrix `r6' = r(Stat6)

		if "`concepto'" == "desc_funcion" & "`datosabiertos'" == "datosabiertos" {
			local textgraph `"text(`=`r5'[1,4]' 74.6835 `"{bf:SHCP: `=string(`r5'[1,4],"%5.1fc")'}"', color(black) placement(6))"'
		}
		
		if "`id'" != "" {
			local textosim `"text(`=`r6'[1,4]' 91.1392 `"{bf:`id': `=string(`r6'[1,4],"%5.1fc")'}"', color(black) placement(6))"'		
		}

		graph bar (sum) gastonetoPIB if anio >= 2013 & anio <= 2018 & `concepto' != -1 & neto == 0, ///
			over(`over', sort((sum) gastonetoPIB)) ///
			over(anio, label(nolabels)) ///
			stack asyvars ///
			title("Gastos presupuestarios", position(5)) ///
			ytitle(% PIB) ylabel(0(10)20, labsize(small)) yscale(range(0(3)30)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3)) ///
			name(gastos, replace) ///
			yreverse xalternate yalternate ///
			blabel(bar, format(%7.1fc)) ///
			plotregion(margin(zero)) graphregion(margin(zero)) ///
			text(`=`r1'[1,1]' 8.86076 `"{bf:---PEF: `=string(`r1'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r2'[1,1]' 25.3165 `"{bf:---PEF: `=string(`r2'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r3'[1,1]' 41.7722 `"{bf:---PEF: `=string(`r3'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r4'[1,1]' 58.2278 `"{bf:---PEF: `=string(`r4'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r5'[1,1]' 74.6835 `"{bf:---PEF: `=string(`r5'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r6'[1,1]' 91.1392 `"{bf:---PEF: `=string(`r6'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r1'[1,2]' 8.86076 `"{bf:CP: `=string(`r1'[1,2],"%5.1fc")'}"', color(black) placement(6)) ///
			text(`=`r2'[1,2]' 25.3165 `"{bf:CP: `=string(`r2'[1,2],"%5.1fc")'}"', color(black) placement(6)) ///
			text(`=`r3'[1,2]' 41.7722 `"{bf:CP: `=string(`r3'[1,2],"%5.1fc")'}"', color(black) placement(6)) ///
			text(`=`r4'[1,2]' 58.2278 `"{bf:CP: `=string(`r4'[1,2],"%5.1fc")'}"', color(black) placement(6)) ///
			text(`=`r5'[1,2]' 74.6835 `"{bf:CP: `=string(`r5'[1,2],"%5.1fc")'}"', color(black) placement(6)) ///
			`textgraph' `textosim'

		if "`id'" != "" {
			local textosim `"text(`=`r6'[1,4]' 91.1392 `"{bf:`id': `=string(`r6'[1,4],"%5.1fc")'}"', color(black) placement(12))"'		
		}

		graph bar (sum) gastonetoPIB if anio >= 2013 & anio <= 2018 & `concepto' != -1 & neto == 0, ///
			over(`over', sort((sum) gastonetoPIB)) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("Gastos presupuestarios observados y estimados") ///
			ytitle(% PIB) ylabel(0(10)20, labsize(small)) yscale(range(0(3)30)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3) margin(-6 0 0 0)) ///
			name(gastos2, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
			text(`=`r1'[1,1]' 8.86076 `"{bf:---PEF: `=string(`r1'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r2'[1,1]' 25.3165 `"{bf:---PEF: `=string(`r2'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r3'[1,1]' 41.7722 `"{bf:---PEF: `=string(`r3'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r4'[1,1]' 58.2278 `"{bf:---PEF: `=string(`r4'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r5'[1,1]' 74.6835 `"{bf:---PEF: `=string(`r5'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r6'[1,1]' 91.1392 `"{bf:---PEF: `=string(`r6'[1,1],"%5.1fc")'---}"', color(black) placement(0)) ///
			text(`=`r1'[1,2]' 8.86076 `"{bf:CP: `=string(`r1'[1,2],"%5.1fc")'}"', color(black) placement(12)) ///
			text(`=`r2'[1,2]' 25.3165 `"{bf:CP: `=string(`r2'[1,2],"%5.1fc")'}"', color(black) placement(12)) ///
			text(`=`r3'[1,2]' 41.7722 `"{bf:CP: `=string(`r3'[1,2],"%5.1fc")'}"', color(black) placement(12)) ///
			text(`=`r4'[1,2]' 58.2278 `"{bf:CP: `=string(`r4'[1,2],"%5.1fc")'}"', color(black) placement(12)) ///
			text(`=`r5'[1,2]' 74.6835 `"{bf:CP: `=string(`r5'[1,2],"%5.1fc")'}"', color(black) placement(12)) ///
			`textgraph' `textosim'


		graph save gastos2 "`c(sysdir_personal)'/users/`id'/Gastos.gph", replace
		*graph export "`c(sysdir_personal)'/users/`id'/Gastos.eps", replace name(gastos2)
		*graph export "`c(sysdir_personal)'/users/`id'/Gastos.png", replace name(gastos2)
	}




	**********************
	*** 5. Display PEF ***
	**********************

	** 5.1. Concepto **
	noisily di _newline in g "{bf: A. Gasto presupuestario (`concepto') " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat gasto gastoPIB if anio == `anio' & `concepto' != -1, by(`concepto') stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		local name `"`=strtoname(`"`=substr(`"`=r(name`k')'"',1,31)'"')'"'

		return scalar `name' = `mat`k''[1,1]
		local division `"`division' `name'"'

		noisily di in g `"  (+) `=substr(`"`=r(name`k')'"',1,35)'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local division "`division'"

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Gasto bruto" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"

	if "`if'" == "" {
		noisily di in g `"  (-) `=substr("Cuotas ISSSTE",1,35)'"' ///
			_col(44) in y %20.0fc `Cuotas_ISSSTE'[1,1] ///
			_col(66) in y %7.3fc `Cuotas_ISSSTE'[1,2] ///
			_col(77) in y %7.1fc `Cuotas_ISSSTE'[1,1]/`mattot'[1,1]*100
		noisily di in g `"  (-) `=substr("Aportaciones a la seguridad social",1,35)'"' ///
			_col(44) in y %20.0fc `Aportaciones_Federacion'[1,1] ///
			_col(66) in y %7.3fc `Aportaciones_Federacion'[1,2] ///
			_col(77) in y %7.1fc `Aportaciones_Federacion'[1,1]/`mattot'[1,1]*100
		noisily di in g _dup(83) "-"
		noisily di in g "{bf:  (=) Gasto neto" ///
			_col(44) in y %20.0fc `mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1] ///
			_col(66) in y %7.3fc  `mattot'[1,2]-`Cuotas_ISSSTE'[1,2]-`Aportaciones_Federacion'[1,2] ///
			_col(77) in y %7.1fc (`mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1])/`mattot'[1,1]*100 "}"
	}
	else {
		matrix `Aportaciones_Federacion' = J(1,1,0)
	}

	return scalar `=strtoname("Gasto bruto")' = `mattot'[1,1]
	return scalar `=strtoname("Gasto neto")' = `mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1]


	** 5.2. Resumido **
	noisily di _newline in g "{bf: B. Gasto presupuestario (Resumido) " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat gastoneto gastonetoPIB if anio == `anio' & `concepto' != -1 & neto == 0, by(`over') stat(sum) f(%20.1fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		return scalar neto_`=strtoname("`=substr(`"`=r(name`k')'"',1,25)'")' = `mat`k''[1,1]
		local resumido `"`resumido' neto_`=strtoname("`=substr(`"`=r(name`k')'"',1,25)'")'"'

		noisily di in g `"  (+) `=substr(`"`=r(name`k')'"',1,35)'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local resumido "`resumido'"

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Gasto neto" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"


	tempname Resumido_total
	matrix `Resumido_total' = r(StatTotal)
	return scalar Resumido_total = `Resumido_total'[1,1]


	** Crecimientos **
	preserve
	collapse (sum) gastoneto* if `concepto' != -1 & neto == 0, by(anio `concepto')
	if `=_N' > 5 {
		xtset `concepto' anio
		tsfill, full
		noisily di _newline in g "{bf: C. Mayores cambios:" in y " `=`anio'-5' - `anio'" in g ///
			_col(55) %7s "`=`anio'-5'" ///
			_col(66) %7s "`anio'" ///
			_col(77) %7s "Cambio PIB" "}"


		tabstat gastoneto gastonetoPIB if anio == `anio', by(`concepto') stat(sum) f(%20.1fc) missing save
		tempname mattot
		matrix `mattot' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat`k'
			matrix `mat`k'' = r(Stat`k')
			local ++k
		}


		capture tabstat gastoneto gastonetoPIB if anio == `anio'-5, by(`concepto') stat(sum) f(%20.1fc) missing save
		if _rc == 0 {
			tempname mattot5
			matrix `mattot5' = r(StatTotal)

			local k = 1
			while "`=r(name`k')'" != "." {
				tempname mat5`k'
				matrix `mat5`k'' = r(Stat`k')

				if abs(`mat`k''[1,2]-`mat5`k''[1,2]) > .4 {
					noisily di in g `"  (+) `=substr(`"`=r(name`k')'"',1,35)'"' ///
						_col(55) in y %7.3fc `mat5`k''[1,2] ///
						_col(66) in y %7.3fc `mat`k''[1,2] ///
						_col(77) in y %7.3fc `mat`k''[1,2]-`mat5`k''[1,2]
				}
				local ++k
			}

			noisily di in g _dup(83) "-"
			noisily di in g "{bf:  (=) Total" ///
				_col(55) in y %7.3fc `mattot5'[1,2] ///
				_col(66) in y %7.3fc `mattot'[1,2] ///
				_col(77) in y %7.3fc `mattot'[1,2]-`mattot5'[1,2] "}"
		}
	}
	restore

	capture drop __*
}
end
