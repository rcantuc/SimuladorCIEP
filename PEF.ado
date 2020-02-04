program define PEF, return
quietly {




	timer on 2
	************************
	*** 1. BASE DE DATOS ***
	************************
	PIBDeflactor
	sort anio
	tempfile PIB
	save `PIB'

	capture confirm existence $anioVP
	if _rc != 0 {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}
	else {
		local aniovp = $anioVP
	}

	capture use in 1 using "`c(sysdir_site)'../basesCIEP/SIM/PEF.dta", clear
	if _rc != 0 {
		run UpdatePEF.do
	}
	syntax [if] [, ANIO(int `aniovp') Graphs Update Base ID(string) ///
		BY(varname) Fast ROWS(int 3) COLS(int 4) MINimum(real 1) ///
		PPEF]

	use `if' using "`c(sysdir_site)'../basesCIEP/SIM/PEF.dta", clear


	** Base PEF **
	if "`update'" == "update" {
		noisily run "`c(sysdir_site)'/UpdatePEF.do"
	}

	** Base ID **
	if "`id'" != "" {
		use "`c(sysdir_site)'/users/`id'/PEF", clear
	}

	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "GASTO P{c U'}BLICO `anio'}"

	if "`base'" == "base" {
		exit
	}

	if "`fast'" == "fast" {
		keep if anio == `anio'
	}

	if "`by'" == "" {
		local by = "desc_funcion"
	}

	if "`ppef'" == "ppef" {
		replace gasto = proyecto if anio == $anioVP
		replace gastoneto = proyectoneto if anio == $anioVP
		replace aprobado = proyecto if anio == $anioVP
		replace aprobadoneto = proyectoneto if anio == $anioVP
	}

	collapse (sum) gasto* aprobado* ejercido*, by(anio `by' transf_gf) 



	**************
	*** 2. PIB ***
	**************
	sort anio
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator var_pibY) update replace keep(matched) sorted
	foreach k of varlist gasto aprobado ejercido {
		g double `k'PIB = `k'/pibY*100
		g double `k'netoPIB = `k'neto/pibY*100
	}
	format *PIB %10.3fc


	** 2.1 Aportaciones y cuotas de la Federacion **
	capture tabstat gasto gastoPIB if anio == `anio' & transf_gf == 1, stat(sum) f(%20.0fc) save
	tempname Aportaciones_Federacion
	matrix `Aportaciones_Federacion' = r(StatTotal)
	return scalar Aportaciones_Federacion = `Aportaciones_Federacion'[1,1]

	capture tabstat gasto gastoPIB if `by' == -1 & anio == `anio', stat(sum) f(%20.0fc) save
	tempname Cuotas_ISSSTE
	matrix `Cuotas_ISSSTE' = r(StatTotal)
	return scalar Cuotas_ISSSTE = `Cuotas_ISSSTE'[1,1]


	/** 2.2. Append **
	if "`datosabiertos'" == "datosabiertos" {
		capture confirm var serie_`by'
		if _rc != 0 {
			di in r "No hay datos para `by'."
			exit
		}
		local varserie "serie_`by'"
		
		tempvar montototal proptotal
		egen `montototal' = sum(gastoneto) if transf_gf ==0 & desc_funcion != -1, by(`by' anio)
		g `proptotal' = gasto/`montototal'
	}

	collapse (sum) gasto* aprobado* ejercido* `proptotal' (mean) pibY `if', ///
		by(`by' anio transf_gf `varserie') fast

	if "`datosabiertos'" == "datosabiertos" {
		decode serie_`by', g(serie)
		levelsof serie, l(serie)
		foreach k of local serie {
			joinby (anio serie) using "`c(sysdir_personal)'../basesCIEP/SIM/`k'.dta", unmatched(both) update
			drop _merge
		}

		tempvar neto19 propneto19
		egen `neto19' = sum(gasto) if serie == "XAC4218", by(anio)
		g `propneto19' = gasto/`neto19'
		replace monto = monto*`propneto19' if serie == "XAC4218"

		replace gasto = monto if anio <= 2018
		replace gastoPIB = monto/pibY*100 if anio <= 2018
		replace gastoneto = monto if anio <= 2018
		replace gastonetoPIB = monto/pibY*100 if anio <= 2018

		*replace gasto = monto*`proptotal' if anio <= 2018
		*replace gastoPIB = monto*`proptotal'/pibY*100 if anio <= 2018
		*replace gastoneto = monto*`proptotal' if anio <= 2018
		*replace gastonetoPIB = monto*`proptotal'/pibY*100 if anio <= 2018
	}




	***************/
	*** 4. Graph ***
	****************
	tempvar over gastonetoPIB
	g `over' = `by'

	tempname label
	label copy `by' `label'
	label values `over' `label'

	egen `gastonetoPIB' = max(gastonetoPIB), by(`by')	
	replace `over' = -99 if abs(`gastonetoPIB') < `minimum'
	
	*replace `over' = -99 if desc_funcion == 8
	
	label define `label' -99 "Otros (< `minimum'% PIB)", add modify

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		graph bar (sum) aprobadonetoPIB ejercidoPIB if anio >= 2013 & `by' != -1 ///
			& transf_gf == 0, ///
			over(`over', relabel(1 "PEF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Gastos presupuestarios}", /*position(5)*/) ///
			ytitle(% PIB) ylabel(0(5)30, labsize(small)) ///
			legend(on position(6) rows(`rows') cols(`cols')) ///
			name(gastos, replace) ///
			/// yreverse xalternate yalternate ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Cuenta P{c u'}blica y Paquetes Econ{c o'}micos).}")

		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ppef'" == "ppef" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"PPEF"', tickset(major)
		}

	}




	********************
	** 4. Display PEF **

	** 4.1. Concepto **
	noisily di _newline in g "{bf: A. Gasto presupuestario (`by') " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	capture tabstat gasto gastoPIB if anio == `anio' & `by' != -1, by(`by') stat(sum) f(%20.0fc) save
	if _rc != 0 {
		noisily di in r "No hay informaci{c o'}n para el a{c n~}o `anio'."
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		if substr(`"`=r(name`k')'"',1,31) == "'" {
			local disptext = substr(`"`=r(name`k')'"',1,30)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,31)
		}
		local name = strtoname(`"`disptext'"')
		return scalar `name' = `mat`k''[1,1]
		local division `"`division' `name'"'

		noisily di in g `"  (+) `disptext'"' ///
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


	** 4.2. Resumido **
	noisily di _newline in g "{bf: B. Gasto presupuestario (Resumido) " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat gastoneto gastonetoPIB if anio == `anio' & `by' != -1 & transf_gf == 0, by(`over') stat(sum) f(%20.1fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		if substr(`"`=r(name`k')'"',1,25) == "'" {
			local disptext = substr(`"`=r(name`k')'"',1,24)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,25)
		}
		local name = strtoname(`"`disptext'"')

		return scalar neto_`name' = `mat`k''[1,1]
		local resumido `"`resumido' neto_`name'"'


		noisily di in g `"  (+) `disptext'"' ///
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


	** 4.3 Crecimientos **
	preserve
	collapse (sum) gastoneto* if `by' != -1 & transf_gf == 0, by(anio `by')
	if `=_N' > 5 {
		xtset `by' anio
		tsfill, full
		tabstat gastoneto gastonetoPIB if anio == `anio', by(`by') stat(sum) f(%20.1fc) missing save
		tempname mattot
		matrix `mattot' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat`k'
			matrix `mat`k'' = r(Stat`k')
			local ++k
		}

		capture tabstat gastoneto gastonetoPIB if anio == `anio'-5, by(`by') stat(sum) f(%20.1fc) missing save
		if _rc == 0 {
			tempname mattot5
			matrix `mattot5' = r(StatTotal)

			noisily di _newline in g "{bf: C. Mayores cambios:" in y " `=`anio'-5' - `anio'" in g ///
				_col(55) %7s "`=`anio'-5'" ///
				_col(66) %7s "`anio'" ///
				_col(77) %7s "Cambio PIB" "}"

			local k = 1
			while "`=r(name`k')'" != "." {
				tempname mat5`k'
				matrix `mat5`k'' = r(Stat`k')

				if substr(`"`=r(name`k')'"',1,25) == "'" {
					local disptext = substr(`"`=r(name`k')'"',1,24)
				}
				else {
					local disptext = substr(`"`=r(name`k')'"',1,25)
				}
				
				if abs(`mat`k''[1,2]-`mat5`k''[1,2]) > .4 {
					noisily di in g `"  (+) `disptext'"' ///
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
	timer off 2
	timer list 2
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t2)/r(nt2)',.1) in g " segs."

}
end
