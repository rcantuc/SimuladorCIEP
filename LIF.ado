program define LIF, return
quietly {

	timer on 3
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 Datos Abiertos (México) **
	if "$pais" == "" {
		noisily UpdateDatosAbiertos
		local updated = r(updated)
		local ultanio = r(ultanio)
		local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
	}

	** 1.3 Base LIF **
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/LIF`=subinstr("${pais}"," ","",.)'.dta"', clear
	if _rc != 0 {
		noisily run UpdateLIF.do					// Genera a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}
	


	***************
	*** 2 SYNTAX **
	***************
	syntax [if/] [, ANIO(int `aniovp' ) Update Graphs Base ID(string) ///
		MINimum(real 1) DESDE(int 2013) LIF BY(varname)]

	** 2.1 Update LIF **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run UpdateLIF.do					// Actualiza a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}

	** 2.2 PIB + Deflactor **
	preserve
	PIBDeflactor, anio(`anio')
	local currency = currency[1]
	tempfile PIB
	save `PIB'
	restore

	** 2.3 Base ID **
	if "`id'" != "" {
		use "`c(sysdir_site)'/users/`id'/LIF", clear
	}

	** 2.4 Base RAW **
	if "`base'" == "base" {
		exit
	}

	** 2.5 Default `by' **
	if "`by'" == "" {
		local by = "divCIEP"
	}

	noisily di _newline(2) in g "{bf:SISTEMA FISCAL: " in y "INGRESOS `anio'" "}"



	***************
	*** 3 Merge ***
	***************
	sort anio
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator lambda var_pibY) ///
		update replace keep(matched) sorted

	** 3.1 Utilizar ILIF **
	if "`lif'" == "lif" {
		replace recaudacion = LIF if anio == `anio'
	}

	** 3.2 Valores como % del PIB **
	foreach k of varlist recaudacion monto LIF ILIF {
		g double `k'PIB = `k'/pibY*100
	}
	format *PIB %10.3fc



	***************
	*** 4 Graph ***
	***************
	tempvar resumido recaudacionPIB
	g `resumido' = `by'

	tempname label
	label copy `by' `label'
	label values `resumido' `label'

	egen `recaudacionPIB' = max(recaudacionPIB) /*if anio >= 2010*/, by(`by')
	replace `resumido' = -99 if abs(`recaudacionPIB') < `minimum' // | recaudacionPIB == . | recaudacionPIB == 0
	label define `label' -99 "Otros (< `minimum'% PIB)", add modify

	capture replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	capture replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	capture replace nombre = subinstr(nombre,"/","_",.)

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		graph pie recaudacionPIB if anio == `anio' & divLIF != 10, over(`resumido') ///
			plabel(_all percent, format(%5.1fc)) ///
			title("{bf:Ingresos presupuestarios `anio'}") ///
			subtitle($pais) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			name(ingresospie, replace) ///
			legend(on position(3) cols(1))

		graph bar (sum) recaudacionPIB if divLIF != 10, ///
			over(`by', /*relabel(1 "LIF" 2 "SHCP")*/) ///
			over(anio, label(labgap(vsmall))) ///
			bargap(-30) stack asyvars ///
			title("{bf:Ingresos presupuestarios}") ///
			subtitle($pais) ///
			ytitle(% PIB) ylabel(0(5)30, labsize(small)) ///
			legend(on position(6) cols(4)) ///
			name(ingresos, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			/*note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')*/
		*gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		*gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
	}



	********************
	** 4. Display LIF **

	** 4.1 Division `by' **
	noisily di _newline in g "{bf: A. Ingresos presupuestarios (`by') " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	capture tabstat recaudacion recaudacionPIB if anio == `anio', by(`by') stat(sum) f(%20.0fc) save
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

		* Display text *
		if substr(`"`=r(name`k')'"',1,31) == "'" {
			local disptext = substr(`"`=r(name`k')'"',1,30)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,31)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		return scalar `name' = `mat`k''[1,1]
		local `by' `"``by'' `name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local `by' `"``by''"'

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Ingresos totales" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"

	return scalar `=strtoname("Ingresos totales")' = `mattot'[1,1]

	** 4.2 Division Resumido **
	noisily di _newline in g "{bf: B. Ingresos presupuestarios (divResumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat recaudacion recaudacionPIB if anio == `anio' & divLIF != 10, by(`resumido') stat(sum) f(%20.1fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		* Display text *
		if substr(`"`=r(name`k')'"',1,25) == "'" {
			local disptext = substr(`"`=r(name`k')'"',1,24)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,25)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
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


	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Mayores cambios:" in y " `=`anio'-4' - `anio'" in g ///
		_col(55) %7s "`=`anio'-4'" ///
		_col(66) %7s "`anio'" ///
		_col(77) %7s "Cambio PIB" "}"


	tabstat recaudacion recaudacionPIB if anio == `anio', by(`by') stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacion recaudacionPIB if anio == `anio'-4 & divLIF != 10, by(`by') stat(sum) f(%20.1fc) save
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



	*****************/
	* Returns Extras *
	if "$pais" == "" {
		tabstat recaudacion recaudacionPIB if anio == `anio' & nombre == "Cuotas a la seguridad social (IMSS)", stat(sum) f(%20.1fc) save
		tempname cuotas
		matrix `cuotas' = r(StatTotal)
		return scalar Cuotas_IMSS = `cuotas'[1,1]
		
		tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP == 10, stat(sum) by(nombre) f(%20.1fc) save
		tempname ieps
		matrix `ieps'7 = r(Stat7)
		matrix `ieps'10 = r(Stat10)
		matrix `ieps'8 = r(Stat8)
		matrix `ieps'11 = r(Stat11)
		matrix `ieps'4 = r(Stat4)
		matrix `ieps'5 = r(Stat5)
		matrix `ieps'3 = r(Stat3)
		matrix `ieps'6 = r(Stat6)
		matrix `ieps'1 = r(Stat1)
		
		return scalar Cervezas = `ieps'7[1,1]
		return scalar Tabacos = `ieps'10[1,1]
		return scalar Juegos = `ieps'8[1,1]
		return scalar Telecom = `ieps'11[1,1]
		return scalar Energiza = `ieps'4[1,1]
		return scalar Saboriza = `ieps'5[1,1]
		return scalar AlimNoBa = `ieps'3[1,1]
		return scalar Fosiles = `ieps'6[1,1]
		return scalar Alcohol = `ieps'1[1,1]
	}

	***********
	*** END ***
	***********
	capture drop __*
	timer off 3
	timer list 3
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t3)/r(nt3)',.1) in g " segs."
}
end
