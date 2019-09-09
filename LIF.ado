program define LIF, return
quietly {




	timer on 3
	************************
	*** 1. BASE DE DATOS ***
	************************
	PIBDeflactor
	tempfile PIB
	save `PIB'

	noisily UpdateDatosAbiertos
	local updated = r(updated)
	local ultanio = r(ultanio)
	local ultmes = r(ultmes)

	capture confirm existence $anioVP
	if _rc != 0 {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}
	else {
		local aniovp = $anioVP
	}
	use "`c(sysdir_site)'../basesCIEP/SIM/LIF.dta", clear
	syntax [if/] [, ANIO(int `aniovp' ) Update Graphs Base ID(string) ///
		MINimum(real 1) DESDE(int 2013) ILIF]

	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run "`c(sysdir_site)'/UpdateLIF.do"					// Actualiza la base de Excel (./basesCIEP/LIFs/LIF.xlsx)
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
	*** 2. PIB ***
	**************
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator productivity var_pibY) update replace keep(matched)

	if "`ilif'" == "ilif" {
		replace LIF = ILIF if anio == $anioVP
	}

	g double recaudacionPIB = recaudacion/pibY*100
	g double montoPIB = monto/pibY*100
	g double LIFPIB = LIF/pibY*100
	g double ILIFPIB = ILIF/pibY*100
	format *PIB %7.3fc




	****************
	*** 3. Graph ***
	****************
	*drop if serie == .
	*xtset serie anio

	tempvar resumido recaudacionPIB
	g `resumido' = divCIEP

	tempname label
	label copy divCIEP `label'
	label values `resumido' `label'

	egen `recaudacionPIB' = max(recaudacionPIB) /*if anio >= 2010*/, by(divCIEP)
	replace `resumido' = -99 if abs(`recaudacionPIB') < `minimum' | recaudacionPIB == . | recaudacionPIB == 0
	*replace `resumido' = -99 if divCIEP == 1
	label define `label' -99 "Otros (< `minimum'% PIB)", add modify

	replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	replace nombre = subinstr(nombre,"/","_",.)




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

	tabstat recaudacion recaudacionPIB if anio == `anio' & divLIF != 10, by(`resumido') stat(sum) f(%20.1fc) save
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


	tabstat recaudacion recaudacionPIB if anio == `anio' & divLIF != 10, by(divCIEP) stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}


	capture tabstat recaudacion recaudacionPIB if anio == `anio'-5 & divLIF != 10, by(divCIEP) stat(sum) f(%20.1fc) save
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

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		replace recaudacionPIB = 0 if anio == $anioVP
		
		if "`if'" != "" {
			graph bar (sum) LIFPIB recaudacionPIB if `if', ///
				over(`resumido', relabel(1 "LIF" 2 "SHCP")) ///
				over(anio, label(labgap(vsmall) labsize(vsmall))) ///
				stack asyvars ///
				title("{bf:Ingresos presupuestarios}") ///
				ytitle(% PIB) ///
				/*ylabel(0(5)30, labsize(small))*/ ///
				legend(on position(6) rows(2)) ///
				name(ingresosIf, replace) ///
				blabel(bar, format(%7.1fc)) ///
				caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
				note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
			exit
		}

		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & divLIF != 10, ///
			over(divOrigen, relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos presupuestarios}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(2)) ///
			name(ingresosH, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}
			
		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & divLIF != 10 & divOrigen == 5, ///
			over(`resumido', relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos tributarios}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(1)) ///
			name(ingresosTributariosH, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}
		
*******************************
		
		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & (divOrigen == 4 | divOrigen==2 | divOrigen == 3), ///
			over(`resumido', relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos no tributarios}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(1)) ///
			name(ingresosnoTributariosA, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}
		
***************************************
	
		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & divLIF != 10 & divOrigen == 2, ///
			over(`resumido', relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos no tributarios}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(1)) ///
			name(ingresosNoTributariosH, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}

		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & divLIF != 10 & divOrigen == 4, ///
			over(`resumido', relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos petroleros}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(1)) ///
			name(ingresosPetrolerosH, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}

		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & divLIF != 10 & (divCIEP == 12 | divCIEP == 15 | divCIEP == 2 | divCIEP == 18), ///
			over(divCIEP, relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos de organismos y empresas}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(1)) ///
			name(ingresosOyEH, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}
	
		graph bar (sum) LIFPIB recaudacionPIB if anio >= `desde' & divLIF == 10, ///
			over(`resumido', relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall) labsize(vsmall))) ///
			stack asyvars ///
			title("{bf:Endeudamiento}") ///
			ytitle(% PIB) ///
			/*ylabel(0(5)30, labsize(small))*/ ///
			legend(on position(6) rows(1)) ///
			name(ingresosDeudaH, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')			
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		if "`ilif'" == "ilif" {
			gr_edit .grpaxis.edit_tick 15 93.9024 `"ILIF"', tickset(major)
		}
			
		/*graph pie LIFPIB if anio == `aniovp', over(`resumido') descending sort ///
			plabel(_all percent, format(%5.1fc)) ///
			title("{bf:Composici{c o'}n de la LIF}") ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			name(ingresospie, replace) ///
			legend(on position(3) cols(1))*/

		/*graph bar (sum) LIFPIB recaudacionPIB if anio >= 2010 & divLIF != 10, ///
			over(divOrigen, relabel(1 "LIF" 2 "SHCP")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Ingresos presupuestarios}") ///
			ytitle(% PIB) ylabel(0(5)30, labsize(small)) ///
			legend(on position(6) rows(2)) ///
			name(ingresos, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}") ///
			note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .grpaxis.style.editstyle majorstyle(tickstyle(textstyle(size(vsmall)))) editcopy
		*gr_edit .grpaxis.major.num_rule_ticks = 0
		*gr_edit .grpaxis.edit_tick 18 87.9227 `"Est*"', tickset(major)
		*gr_edit .grpaxis.edit_tick 19 95.1691 `"ILIF"', tickset(major)
		*gr_edit .grpaxis.edit_tick 20 98.3092 `" "', tickset(major)*/
	}

	capture drop __*
	timer off 3
	timer list 3
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t3)/r(nt3)',.1) in g " segs."

}
end
