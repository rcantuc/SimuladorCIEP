program define PEF, return
quietly {

	timer on 4
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 PIB + Deflactor **
	PIBDeflactor, anio(`aniovp')
	tempfile PIB
	save `PIB'

	** 1.3 Datos Abiertos (México) **
	if "$pais" == "" {
		noisily UpdateDatosAbiertos
		local updated = r(updated)
		local ultanio = r(ultanio)
		local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
	}

	** 1.4 Base LIF **
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/PEF`=subinstr("${pais}"," ","",.)'.dta"', clear
	if _rc != 0 {
		noisily run UpdatePEF.do
	}



	****************
	*** 2 SYNTAX ***
	****************
	syntax [if] [, ANIOvp(int `aniovp') Graphs Update Base ID(string) ///
		BY(varname) Fast ROWS(int 3) COLS(int 4) MINimum(real 1) PPEF]

	** 2.1 Update PEF **
	if "`update'" == "update" {
		noisily run UpdatePEF.do
	}

	** 2.2 Base ID **
	if "`id'" != "" {
		use "`c(sysdir_site)'/users/`id'/PEF", clear
	}

	** 2.3 Base RAW **
	if "`base'" == "base" {
		exit
	}

	** 2.4 Default `by' **
	if "`by'" == "" {
		local by = "desc_funcion"
	}
	
	noisily di _newline(2) in g "{bf:SISTEMA FISCAL: " in y "GASTO P{c U'}BLICO `aniovp'}"



	***************
	*** 3 Merge ***
	***************
	if "`fast'" == "fast" {
		keep if anio == `aniovp'
	}
	collapse (sum) gasto* `if', by(anio `by' transf_gf) 
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator var_pibY) ///
		update replace keep(matched) sorted

	** 3.1 Utilizar PPEF **
	if "`ppef'" == "ppef" {
		replace gasto = proyecto if anio == `aniovp'
		replace gastoneto = proyectoneto if anio == `aniovp'
	}

	** 3.2 Valores como % del PIB **
	foreach k of varlist gasto* {
		g double `k'PIB = `k'/pibY*100
	}
	format *PIB %10.3fc



	***************
	*** 4 Graph ***
	***************
	tempvar resumido gastonetoPIB
	g `resumido' = `by'

	tempname label
	label copy `by' `label'
	label values `resumido' `label'

	egen `gastonetoPIB' = max(gastonetoPIB), by(`by')	
	replace `resumido' = -99 if abs(`gastonetoPIB') < `minimum'
	
	*replace `resumido' = -99 if desc_funcion == 8
	
	label define `label' -99 "Otros (< `minimum'% PIB)", add modify

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		graph pie gastonetoPIB if anio == `aniovp', over(`resumido') ///
			plabel(_all percent, format(%5.1fc)) ///
			title("{bf:Gastos presupuestarios `aniovp'}") ///
			subtitle($pais) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			name(gastospie, replace) ///
			legend(on position(3) cols(1))

		graph bar (sum) gastonetoPIB if `by' != -1 & transf_gf == 0, ///
			over(`resumido') ///
			over(anio, label(labgap(vsmall))) ///
			bargap(-30) stack asyvars ///
			title("{bf:Gastos presupuestarios}") ///
			subtitle($pais) ///
			ytitle(% PIB) ylabel(0(5)30, labsize(small)) ///
			legend(on position(6) cols(5)) ///
			name(gastos, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			/*note({bf:{c U'}ltimo dato:} `ultanio'm`ultmes')*/
		*gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
		*gr_edit .plotregion1.GraphEdit, cmd(_set_rotate)
	}



	********************
	** 4. Display PEF **
	
	** 4.1 Division `by' **
	noisily di _newline in g "{bf: A. Gasto presupuestario (`by') " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	capture tabstat gasto gastoPIB if anio == `aniovp' & `by' != -1, by(`by') stat(sum) f(%20.0fc) save
	if _rc != 0 {
		noisily di in r "No hay informaci{c o'}n para el a{c n~}o `aniovp'."
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
	noisily di in g "{bf:  (=) Gasto bruto" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"
	
	return scalar `=strtoname("Gasto bruto")' = `mattot'[1,1]

	** 4.1.1 Gasto neto **
	if "`if'" == "" & "$pais" == "" {

		* 4.0 Aportaciones y cuotas de la Federacion *
		tabstat gasto gastoPIB if anio == `aniovp' & transf_gf == 1, stat(sum) f(%20.0fc) save
		tempname Aportaciones_Federacion
		if _rc == 0 {
			matrix `Aportaciones_Federacion' = r(StatTotal)
		}
		else {
				matrix `Aportaciones_Federacion' = J(1,1,0)
		}
		return scalar Aportaciones_Federacion = `Aportaciones_Federacion'[1,1]

		capture tabstat gasto gastoPIB if `by' == -1 & anio == `aniovp', stat(sum) f(%20.0fc) save
		tempname Cuotas_ISSSTE
		if _rc == 0 {
			matrix `Cuotas_ISSSTE' = r(StatTotal)
			return scalar Cuotas_ISSSTE = `Cuotas_ISSSTE'[1,1]
		}
		else {
			matrix `Cuotas_ISSSTE' = J(1,1,0)		
		}

		* Display *
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
		
		return scalar `=strtoname("Gasto neto")' = `mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1]
	}

	** 4.2. Division Resumido **
	noisily di _newline in g "{bf: B. Gasto presupuestario (Resumido) " ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat gastoneto gastonetoPIB if anio == `aniovp' & `by' != -1 & transf_gf == 0, by(`resumido') stat(sum) f(%20.1fc) save
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
		local divResumido `"`divResumido' neto_`name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Gasto neto" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"


	tempname Resumido_total
	matrix `Resumido_total' = r(StatTotal)
	return scalar Resumido_total = `Resumido_total'[1,1]


	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Mayores cambios:" in y " `=`aniovp'-4' - `aniovp'" in g ///
		_col(55) %7s "`=`aniovp'-4'" ///
		_col(66) %7s "`aniovp'" ///
		_col(77) %7s "Cambio PIB" "}"

	preserve
	collapse (sum) gastoneto* if `by' != -1 & transf_gf == 0, by(anio `by')
	xtset `by' anio
	tsfill, full

	tabstat gastoneto gastonetoPIB if anio == `aniovp', by(`by') stat(sum) f(%20.1fc) missing save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat gastoneto gastonetoPIB if anio == `aniovp'-4, by(`by') stat(sum) f(%20.1fc) missing save
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)

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
	restore




	***********
	*** END ***
	***********
	capture drop __*
	timer off 4
	timer list 4
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t4)/r(nt4)',.1) in g " segs."

}
end
