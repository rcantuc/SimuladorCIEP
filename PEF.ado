program define PEF, return
quietly {

	timer on 5
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 Datos Abiertos (MÈxico) **
	if "$pais" == "" {
		UpdateDatosAbiertos
		local updated = r(updated)
		local ultanio = r(ultanio)
		local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
	}

	** 1.3 Base PEF **
	capture confirm file "`c(sysdir_personal)'/SIM/$pais/PEF.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_personal)'/UpdatePEF.do"
	}



	****************
	*** 2 SYNTAX ***
	****************
	use in 1 using "`c(sysdir_personal)'/SIM/$pais/PEF.dta", clear
	syntax [if] [, ANIO(int `aniovp') NOGraphs Update Base ID(string) ///
		BY(varname) ROWS(int 1) COLS(int 5) MINimum(real 1) PEF PPEF]

	if "`ppef'" == "ppef" {
		local textintro = "PPEF"
	}
	else if "`pef'" == "pef" {
		local textintro = "PEF"
	}
	else {
		local textintro = "Cuenta P{c u'}blica"
	}
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: GASTOS $pais " in y `anio' "  }" in g _dup(20) "."
	
	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save `PIB'

	** 2.2 Update PEF **
	if "`update'" == "update" /*| "`updated'" != "yes"*/ {
		noisily run "`c(sysdir_personal)'/UpdatePEF.do"
	}

	** 2.2 Base RAW **
	use `if' using "`c(sysdir_personal)'/SIM/$pais/PEF.dta", clear
	if "`base'" == "base" {
		exit
	}

	** 2.3 Default `by' **
	if "`by'" == "" {
		local by = "desc_funcion"
	}



	***************
	*** 3 Merge ***
	***************
	collapse (sum) gasto*, by(anio `by' transf_gf) 
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator var_pibY) ///
		update replace keep(matched) sorted
	local aniofirst = anio[1]
	local aniolast = anio[_N]

	** 3.1 Utilizar PPEF **
	if "`ppef'" == "ppef" {
		replace gasto = proyecto if anio == `anio'
		replace gastoneto = proyectoneto if anio == `anio'
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
	replace `resumido' = 999 if abs(`gastonetoPIB') < `minimum'
	label define `label' 999 "< `minimum'% PIB", add modify

	/*levelsof `by', local(levelsof)
	foreach k of local levelsof {
		local labelotros : label `by' `k'
		if "`labelotros'" == "Otros" { 
			replace `resumido' = 98 if `by' == `k'
			label define `label' 98 "Otros", modify
		}
	}*/



	********************
	** 4. Display PEF **
	
	** 4.1 Division `by' **
	noisily di _newline in g "{bf: A. Gasto bruto (`by') " ///
		_col(44) in g %20s "`currency'" ///
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

		* Display text *
		if substr(`"`=r(name`k')'"',1,31) == "'" {
			local disptext = substr(`"`=r(name`k')'"',1,30)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,31)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		*return scalar `name' = `mat`k''[1,1]
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
	
	return scalar Gasto_bruto = `mattot'[1,1]

	** 4.1.1 Gasto neto **
	if "$pais" == "" {

		* 4.0 Aportaciones y cuotas de la Federacion *
		capture tabstat gasto gastoPIB if anio == `anio' & transf_gf == 1, stat(sum) f(%20.0fc) save
		tempname Aportaciones_Federacion
		if _rc == 0 {
			matrix `Aportaciones_Federacion' = r(StatTotal)
		}
		else {
			matrix `Aportaciones_Federacion' = J(1,1,0)
		}
		return scalar Aportaciones_a_Seguridad_Social = `Aportaciones_Federacion'[1,1]

		capture tabstat gasto gastoPIB if `by' == -1 & anio == `anio', stat(sum) f(%20.0fc) save
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
		
		return scalar Gasto_neto = `mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1]
	}

	** 4.2. Division Resumido **
	noisily di _newline in g "{bf: B. Gasto neto (Resumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	tabstat gastoneto gastonetoPIB if anio == `anio' & `by' != -1 & transf_gf == 0, by(`resumido') stat(sum) f(%20.1fc) save
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

	/** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Mayores cambios:" in y " `=`anio'-4' - `anio'" in g ///
		_col(55) %7s "`=`anio'-4'" ///
		_col(66) %7s "`anio'" ///
		_col(77) %7s "Cambio PIB" "}"

	preserve
	collapse (sum) gastoneto* if `by' != -1 & transf_gf == 0, by(anio `by')
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

	capture tabstat gastoneto gastonetoPIB if anio == `anio'-4, by(`by') stat(sum) f(%20.1fc) missing save
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
	restore*/



	if "$graphs" == "on" | "`nographs'" != "nographs" {
		preserve
		tabstat gastonetoPIB if anio == `anio' & `by' != -1 & transf_gf == 0, stat(sum) f(%20.0fc) save
		tempname gasanio
		matrix `gasanio' = r(StatTotal)

		*graph pie gastonetoPIB if anio == `anio' & `by' != -1 & transf_gf == 0, over(`resumido') ///
			plabel(_all percent, format(%5.1fc)) ///
			title(`"Gastos `=upper("`pef'`ppef'")' `anio'"') /// subtitle($pais) ///
			name(gastospie, replace) ///
			legend(on position(6) rows(`rows') cols(`cols')) ///
			ptext(0 0 `"{bf:`=string(`gasanio'[1,1],"%6.1fc")' % PIB}"', color(white) size(small))


		levelsof `resumido' if `by' != -1, local(lev_resumido)
		local totlev = 0
		foreach k of local lev_resumido {
			local legend`k' : label `label' `k'
			local ++totlev
		}

		collapse (sum) gastoneto* if `by' != -1 & transf_gf == 0, by(anio `resumido')
		reshape wide gastoneto gastonetoPIB, i(anio) j(`resumido')
		local countlev = 1
		foreach k of local lev_resumido {
			tempvar lev_res`countlev'
			if `countlev' == 1 {
				g `lev_res`countlev'' = gastoneto`k'/1000000000
			}
			else {
				g `lev_res`countlev'' = gastoneto`k'/1000000000 + `lev_res`=`countlev'-1''
			}
			replace `lev_res`countlev'' = 0 if `lev_res`countlev'' == .
			
			local graphvars = "`lev_res`countlev'' `graphvars' "
			local legend = `"`legend' label(`=`totlev'-`countlev'+1' "`legend`k''")"'
			local ++countlev
		}

		tempvar TOTPIB
		egen `TOTPIB' = rsum(gastonetoPIB*)
		forvalues k=1(1)`=_N' {
			if `TOTPIB'[`k'] != . & anio[`k'] >= 2014 {
				local text `"`text' `=`TOTPIB'[`k']' `=anio[`k']' "`=string(`TOTPIB'[`k'],"%5.1fc")'""'
			}
		}
		twoway (area `graphvars' anio if anio >= 2014) ///
			(connected `TOTPIB' anio if anio >= 2014, yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")), ///
			title("{bf:Gasto} p{c u'}blico") ///
			subtitle($pais) ///
			text(`text', yaxis(2)) ///
			ytitle(mil millones `currency') ytitle(% PIB, axis(2)) xtitle("") ///
			ylabel(/*0(5)30*/, format(%15.0fc) labsize(small)) ///
			ylabel(/*0(5)30*/, axis(2) noticks format(%5.1fc) labsize(small)) ///
			yscale(range(0)) yscale(range(0) axis(2) noline) ///
			xlabel(2014(1)`aniolast') ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' label(`=`totlev'+1' "= Total % PIB")) ///
			name(gastos, replace) ///
			caption("Fuente: Elaborado por el CIEP.")
		
		restore
	}



	**********/
	*** END ***
	***********
	capture drop __*
	timer off 5
	timer list 5
	noisily di _newline in g "Tiempo: " in y round(`=r(t5)/r(nt5)',.1) in g " segs."
}
end
