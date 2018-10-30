program define LIF, return
quietly {




	************************
	*** 1. BASE DE DATOS ***
	************************
	/* Generar base de datos para el simulador *
	capture confirm file "`c(sysdir_personal)'/bases/SIM/LIF`c(os)'.dta"
	if _rc != 0 {
		capture confirm file "`c(sysdir_personal)'/bases/LIFs/Nacional/LIF`c(os)'.dta"
		if _rc != 0 | "`remake'" == "remake" {
			noisily run "`c(sysdir_personal)'/bases/LIFs/Nacional/LIFSIM.do"	// It takes a long time.
		}

		use "`c(sysdir_personal)'/bases/LIFs/Nacional/LIF`c(os)'.dta", clear

		g double recaudacion = monto if mes == 12					// Se reemplazan cuando la serie esta completa
		replace recaudacion = LIF if mes < 12 | mes == . 				// De lo contrario, es LIF
		replace recaudacion = ILIF if mes == . & LIF == 0 & ILIF != 0			// De lo contrario, es ILIF
		format recaudacion %20.0fc

		replace serie = -1*divLIF if serie == .
		save "`c(sysdir_personal)'/bases/SIM/LIF`c(os)'.dta", replace
	}


	** 1.2 Syntax **/
	use "`c(sysdir_personal)'/bases/SIM/LIF`c(os)'.dta", clear
	syntax [if/] [, ANIO(int $anioVP ) Graphs Update Base Remake ID(string)]
	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "INGRESOS `anio'" "}"


	** 1.3 Base ID **
	if "`id'" != "" {
		use "`c(sysdir_personal)'/users/`id'/LIF", clear
	}




	**************
	*** 2. LIF ***
	**************
	if "$update" == "on" | "`update'" == "update" | "`remake'" == "remake" {
		capture confirm file "`c(sysdir_personal)'/bases/LIFs/Nacional/LIF`c(os)'.dta"
		if _rc != 0 | "`remake'" == "remake" {
			noisily run "`c(sysdir_personal)'/bases/LIFs/Nacional/LIFSIM.do"	// It takes a long time.
		}

		use "`c(sysdir_personal)'/bases/LIFs/Nacional/LIF`c(os)'.dta", clear

		g double recaudacion = monto if mes == 12					// Solo se reemplazan cuando la serie esta completa
		replace recaudacion = LIF if mes < 12 | mes == . 				// De lo contrario, es LIF
		replace recaudacion = ILIF if mes == . & LIF == 0 & ILIF != 0			// De lo contrario, es ILIF
		format recaudacion %20.0fc

		replace serie = -1*divLIF if serie == .
		save "`c(sysdir_personal)'/bases/SIM/LIF`c(os)'.dta", replace
	}

	if "`base'" == "base" {
		exit
	}

	levelsof divCIEP, local(levels)
	foreach k of local levels {
		local levellabel : label divCIEP `k'
		if "`levellabel'" == "Deuda" {
			local deuda = `k'
			continue, break
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

	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator productivity var_pibY) update replace keep(matched)

	g double recaudacionPIB = recaudacion/pibY*100
	g double montoPIB = monto/pibY*100
	g double LIFPIB = LIF/pibY*100
	g double ILIFPIB = ILIF/pibY*100
	format *PIB %7.3fc




	****************
	*** 4. Graph ***
	****************
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

	replace `resumido' = -2 if (abs(recaudacionPIB) < .3 | recaudacionPIB == .) ///
		& divCIEP != `deuda' & divCIEP != 7 & divCIEP != 13 & anio != $anioVP
	replace `resumido' = -2 if (abs(LIFPIB) < .3 | LIFPIB == .) ///
		& divCIEP != `deuda' & divCIEP != 7 & divCIEP != 13 & anio == $anioVP

	label define `label' -2 "Otros (< .3% PIB)", add modify

	replace nombre = subinstr(nombre,"Impuesto especial sobre producci${o}n y servicios de ","",.)
	replace nombre = subinstr(nombre,"alimentos no b${a}sicos con alta densidad cal${o}rica","comida chatarra",.)
	replace nombre = subinstr(nombre,"/","_",.)

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		tabstat LIFPIB recaudacionPIB if anio >= 2013 & anio <= $anioVP & divCIEP != `deuda', by(anio) stat(sum) save
		tempname r1 r2 r3 r4 r5 r6
		matrix `r1' = r(Stat1)
		matrix `r2' = r(Stat2)
		matrix `r3' = r(Stat3)
		matrix `r4' = r(Stat4)
		matrix `r5' = r(Stat5)
		matrix `r6' = r(Stat6)

		if "`id'" != "" {
			local textosim `"text(`=`r6'[1,2]' 91.1392 `"{bf:`id': `=string(`r6'[1,2],"%5.1fc")'}"', color(black) placement(12))"'
		}
		
		graph bar (sum) recaudacionPIB LIFPIB if anio >= 2013 & anio <= $anioVP & divCIEP != `deuda', ///
			over(divOrigen, relabel(1 "Rec." 2 "LIF")) ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("Ingresos presupuestarios", margin(large)) ///
			ytitle(% PIB) ylabel(0(10)20, labsize(small)) yscale(range(0(3)30)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3)) ///
			name(ingresos, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			plotregion(margin(zero)) graphregion(margin(zero)) ///
			`textosim'
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)

		graph bar (sum) recaudacionPIB LIFPIB if anio >= 2011 & anio <= $anioVP & divCIEP != `deuda' & divOrigen == 5, ///
			over(`resumido', relabel(1 "Rec." 2 "LIF") gap(*1.2)) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("Ingresos presupuestarios recaudados y estimados") ///
			ytitle(% PIB) ylabel(-2 0(10)15, labsize(small)) yscale(range(-2(1)15)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3) margin(-6 0 0 0)) ///
			name(ingresosTributarios, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			//caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .scaleaxis.reset_rule 0 15 5 , tickset(major) ruletype(range) 


		graph bar (sum) recaudacionPIB LIFPIB if anio >= 2011 & anio <= $anioVP & divCIEP != `deuda' & divOrigen == 3, ///
			over(`resumido', relabel(1 "Rec." 2 "LIF") gap(*1.2)) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("Ingresos presupuestarios recaudados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3) margin(-6 0 0 0)) ///
			name(ingresosNoTributarios, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			//caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		
		graph bar (sum) recaudacionPIB LIFPIB if anio >= 2011 & anio <= $anioVP & divCIEP != `deuda' & divOrigen == 4, ///
			over(`resumido', relabel(1 "Rec." 2 "LIF") gap(*1.2)) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("Ingresos presupuestarios recaudados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3) margin(-6 0 0 0)) ///
			name(ingresosPetroleros, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			//caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)

		graph bar (sum) recaudacionPIB LIFPIB if anio >= 2011 & anio <= $anioVP & divCIEP != `deuda' & divOrigen == 1 & divCIEP != 18, ///
			over(divCIEP, relabel(1 "Rec." 2 "LIF") gap(*1.2)) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("Ingresos presupuestarios recaudados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3) margin(-6 0 0 0)) ///
			name(ingresosOyE, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			//caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.")
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
			
		graph bar (sum) recaudacionPIB LIFPIB if anio >= 2011 & anio <= $anioVP & divCIEP != `deuda', ///
			over(divOrigen, relabel(1 "Rec." 2 "LIF") gap(*1.2)) ///
			over(anio, label(labgap(small))) ///
			stack asyvars ///
			title("Ingresos presupuestarios recaudados y estimados") ///
			ytitle(% PIB) ylabel(0(10)30, labsize(small)) yscale(range(0(3)27)) ///
			legend(on position(9) cols(1) justification(right) textfirst rowgap(3) margin(-6 0 0 0)) ///
			name(ingresosOrigen, replace) ///
			yalternate ///
			blabel(bar, format(%7.1fc)) ///
			/// caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
			`textosim'
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)

		graph save ingresosOrigen "`c(sysdir_personal)'/users/`id'/Ingresos.gph", replace
		*graph export "`c(sysdir_personal)'/users/`id'/Ingresos.eps", replace name(ingresosOrigen)
		*graph export "`c(sysdir_personal)'/users/`id'/Ingresos.png", replace name(ingresosOrigen)
	}


	*********************
	** 1.5 Display LIF **

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
