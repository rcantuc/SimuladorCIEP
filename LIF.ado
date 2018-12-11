program define LIF, return
quietly {




	************************
	*** 1. BASE DE DATOS ***
	************************
	syntax [if/] [, ANIO(int $anioVP ) Graphs Update Base ID(string) ///
		MINimum(real 1)]


	** Base LIF **
	capture use "`c(sysdir_site)'/bases/SIM/LIF.dta", clear
	if _rc != 0 | "`update'" == "update" {
		noisily run "`c(sysdir_site)'/UpdateLIF.do" `update'		// Update: It takes a long, long, long time.
	}


	** Base ID **
	if "`id'" != "" {
		use "`c(sysdir_site)'/users/`id'/LIF", clear
	}

	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "INGRESOS `anio'" "}"

	if "`base'" == "base" {
		exit
	}




	**************
	*** 2. LIF ***
	**************
	levelsof divCIEP, local(levels)
	foreach k of local levels {
		local levellabel : label divCIEP `k'
		if "`levellabel'" == "Deuda" {
			local deuda = `k'
			continue, break
		}
	}




	**************
	*** 2. PIB ***
	**************
	preserve
	PIBDeflactor
	tempfile PIB
	save `PIB'
	restore

	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator productivity var_pibY) update replace keep(matched)

	g double recaudacionPIB = recaudacion/pibY*100
	g double montoPIB = monto/pibY*100
	g double LIFPIB = LIF/pibY*100
	g double ILIFPIB = ILIF/pibY*100
	format *PIB %7.3fc




	****************
	*** 3. Graph ***
	****************
	drop if serie == .
	xtset serie anio
	forvalues k=1(1)`=_N' {
		if monto[`k'] == . & mes[`k'] != . {
			local ultanio = anio in `=`k'-1'
			local ultmes = mes in `=`k'-1'
			
			if `ultmes' < 12 {
				local textmes "(mes `ultmes')"
			}

			continue, break
		}
	}

	tempvar resumido
	g `resumido' = divCIEP

	tempname label
	label copy divCIEP `label'
	label values `resumido' `label'

	replace `resumido' = -2 if (abs(recaudacionPIB) < `minimum' | recaudacionPIB == . | recaudacionPIB == 0) ///
		& divCIEP != `deuda'
	label define `label' -2 "Otros (< `minimum'% PIB)", add modify

	replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	replace nombre = subinstr(nombre,"/","_",.)

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		replace LIFPIB = ILIFPIB if anio == 2019
		replace recaudacionPIB = 0 if anio == 2019
		
		graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divCIEP != `deuda', ///
			over(divOrigen, relabel(1 "LIF" 2 "Obs")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos presupuestarios observados y estimados}") ///
			/// subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(0(5)30, labsize(small)) ///
			legend(on position(6) rows(1)) ///
			name(ingresos, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.major.num_rule_ticks = 0
		gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)

		graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divCIEP != `deuda' & divOrigen == 5, ///
			over(`resumido', relabel(1 "LIF" 2 "Obs")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos tributarios observados y estimados}") ///
			/// subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(0(5)15, labsize(small)) ///
			legend(on position(6) rows(1)) ///
			name(ingresosTributarios, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.major.num_rule_ticks = 0
		gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)

		graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divCIEP != `deuda' & divOrigen == 2, ///
			over(`resumido', relabel(1 "LIF" 2 "Obs")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos no tributarios recaudados y estimados}") ///
			ytitle(% PIB) ylabel(0(5)15, labsize(small)) ///
			legend(on position(6) rows(1)) ///
			name(ingresosNoTributarios, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.major.num_rule_ticks = 0
		gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)

		graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divCIEP != `deuda' & divOrigen == 4, ///
			over(`resumido', relabel(1 "LIF" 2 "Obs")) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("{bf:Ingresos petroleros recaudados y estimados}") ///
			ytitle(% PIB) ylabel(0(5)15, labsize(small)) ///
			legend(on position(6) rows(1)) ///
			name(ingresosPetroleros, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.major.num_rule_ticks = 0
		gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)

		graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divCIEP != `deuda' & divOrigen == 3 & divCIEP != 18, ///
			over(divCIEP, relabel(1 "LIF" 2 "Obs")) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("{bf:Ingresos de organismos y empresas recaudados y estimados}") ///
			ytitle(% PIB) ylabel(0(5)15, labsize(small)) ///
			legend(on position(6) rows(1)) ///
			name(ingresosOyE, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.major.num_rule_ticks = 0
		gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)

		graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divCIEP != `deuda' & (divCIEP == 21 | divCIEP == 2), ///
			over(divCIEP, relabel(1 "LIF" 2 "Obs")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos de EPE observados y estimados}") ///
			subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(0(5)30, labsize(small)) ///
			legend(on position(6) rows(1)) ///
			name(ingresosEPE, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.major.num_rule_ticks = 0
		gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)

		replace LIFPIB = 0 if anio == 2019
		replace recaudacionPIB = ILIFPIB if anio == 2019
	}


	********************
	** 4. Display LIF **

	** Division CIEP **
	noisily di _newline in g "{bf: A. Ingresos presupuestarios (divCIEP) " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat recaudacion recaudacionPIB if anio == `anio', by(divCIEP) stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		local name = strtoname("`=r(name`k')'")

		return scalar `name' = `mat`k''[1,1]
		local divCIEP `"`divCIEP' `name'"'
		
		noisily di in g "  (+) `=r(name`k')'" ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}

	return local divCIEP `"`divCIEP'"'
	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Total" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"


	** Division Origen **
	noisily di _newline in g "{bf: B. Ingresos presupuestarios (divOrigen) " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat recaudacion recaudacionPIB if anio == `anio', by(divOrigen) stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		return scalar `=strtoname(abbrev("`=r(name`k')'",7))' = `mat`k''[1,1]
		local divOrigen `"`divOrigen' `=strtoname(abbrev("`=r(name`k')'",7))'"'

		noisily di in g "  (+) `=r(name`k')'" ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}

	return local divOrigen `"`divOrigen'"'
	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Total" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"


	** Division Resumido **
	noisily di _newline in g "{bf: C. Ingresos presupuestarios (divResumido) " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP != `deuda', by(`resumido') stat(sum) f(%20.1fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		return scalar `=strtoname("`=r(name`k')'")' = `mat`k''[1,1]
		local divResumido `"`divResumido' `=strtoname(abbrev("`=r(name`k')'",7))'"'

		noisily di in g "  (+) `=r(name`k')'" ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}

	return local divResumido `"`divResumido'"'
	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Total (sin deuda)" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"


	** Crecimientos **
	noisily di _newline in g "{bf: D. Mayores cambios:" in y " `=`anio'-5' - `anio'" in g ///
		_col(55) %7s "`=`anio'-5'" ///
		_col(66) %7s "`anio'" ///
		_col(77) %7s "Cambio PIB" "}"


	tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP != `deuda', by(divCIEP) stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}


	capture tabstat recaudacion recaudacionPIB if anio == `anio'-5 & divCIEP != `deuda', by(divCIEP) stat(sum) f(%20.1fc) save
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')

			if abs(`mat`k''[1,2]-`mat5`k''[1,2]) > .5 {
				noisily di in g "  (+) `=r(name`k')'" ///
					_col(55) in y %7.3fc `mat5`k''[1,2] ///
					_col(66) in y %7.3fc `mat`k''[1,2] ///
					_col(77) in y %7.3fc `mat`k''[1,2]-`mat5`k''[1,2]
			}
			local ++k
		}

		noisily di in g _dup(83) "-"
		noisily di in g "{bf:  (=) Total (sin deuda)" ///
			_col(55) in y %7.3fc `mattot5'[1,2] ///
			_col(66) in y %7.3fc `mattot'[1,2] ///
			_col(77) in y %7.3fc `mattot'[1,2]-`mattot5'[1,2] "}"
	}


	** If **
	if "`if'" != "" {
	noisily di _newline in g "{bf: E. Ingresos (if `if') " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

		tabstat recaudacion recaudacionPIB if anio == `anio', by(divCIEP) stat(sum) f(%20.0fc) save
		tempname mattot
		matrix `mattot' = r(StatTotal)

		tabstat recaudacion recaudacionPIB if anio == `anio' & recaudacionPIB != 0 & `if', by(nombre) f(%7.3fc) stat(sum) save
		tempname matiftot
		matrix `matiftot' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname matif`k'
			matrix `matif`k'' = r(Stat`k')
			
			return scalar `=strtoname("`=r(name`k')'")' = `matif`k''[1,1]
			local name = strtoname("`=r(name`k')'")
			local divIf `"`divIf' `name'"'

			noisily di in g "  (+) `=r(name`k')'" ///
				_col(44) in y %20.0fc `matif`k''[1,1] ///
				_col(66) in y %7.3fc `matif`k''[1,2] ///
				_col(77) in y %7.1fc `matif`k''[1,1]/`mattot'[1,1]*100
			local ++k
		}

		return local divIf `"`divIf'"'
		noisily di in g _dup(83) "-"
		noisily di in g "{bf:  (=) Total" ///
			_col(44) in y %20.0fc `matiftot'[1,1] ///
			_col(66) in y %7.3fc `matiftot'[1,2] ///
			_col(77) in y %7.1fc `matiftot'[1,1]/`matiftot'[1,1]*100 "}"

	}

	capture drop __*
}
end
