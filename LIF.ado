program define LIF, return
quietly {

	timer on 4
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 Datos Abiertos (MÈxico) **
	if "`c(username)'" == "ricardo" & "$pais" == "" {
		*UpdateDatosAbiertos									// TO-DO: Updates deben estar en el arranque, no aqui
		local updated = "yes" // r(updated)
		*local ultanio = r(ultanio)
		*local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
	}

	** 1.3 Base LIF **
	capture confirm file "`c(sysdir_personal)'/SIM/$pais/LIF.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_personal)'/UpdateLIF.do"			// Genera a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}
	


	***************
	*** 2 SYNTAX **
	***************
	use in 1 using "`c(sysdir_personal)'/SIM/$pais/LIF.dta", clear
	syntax [if] [, ANIO(int `aniovp' ) Update NOGraphs Base ID(string) ///
		MINimum(real 0.5) DESDE(int 2013) ILIF LIF BY(varname) ROWS(int 2) COLS(int 5)]

	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: INGRESOS $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local pibYR`anio' = pibYR[`k']
		}
		if anio[`k'] == `anio'-10 {
			local pibYR`=`anio'-10' = pibYR[`k']
		}
	}
	tempfile PIB
	save `PIB'

	** 2.2 Update LIF **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run "`c(sysdir_personal)'/UpdateLIF.do"			// Actualiza a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}

	** 2.4 Base RAW **
	use `if' using "`c(sysdir_personal)'/SIM/$pais/LIF.dta", clear
	if "`base'" == "base" {
		exit
	}

	** 2.5 Default `by' **
	if "`by'" == "" {
		local by = "divCIEP"
	}




	***************
	*** 3 Merge ***
	***************
	sort anio
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator lambda var_pibY) ///
		update replace keep(matched) sorted
	sort anio mes

	*keep if anio >= 2002
	local aniofirst = anio[1]
	local aniolast = anio[_N]

	tabstat mes if anio == `aniolast', stat(max) save
	tempname MLast
	matrix `MLast' = r(StatTotal)
	local meslast = `MLast'[1,1]

	** 3.1 Utilizar LIF o ILIF **
	if "`lif'" == "" {
		replace recaudacion = LIF if anio == `anio'
	}

	if "`ilif'" == "ilif" {
		replace recaudacion = ILIF if anio == `anio'
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
	capture label copy `by' `label'
	if _rc != 0 {
		label copy num`by' `label'
	}
	label values `resumido' `label'

	egen `recaudacionPIB' = max(recaudacionPIB) /*if anio >= 2010*/, by(`by')
	replace `resumido' = 999 if abs(`recaudacionPIB') < `minimum' & divCIEP != 15 // | recaudacionPIB == . | recaudacionPIB == 0
	label define `label' 999 `"< `=string(`minimum',"%5.1fc")'% PIB"', add modify

	capture replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	capture replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	capture replace nombre = subinstr(nombre,"/","_",.)



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
	di _newline in g "{bf: B. Ingresos presupuestarios (divResumido) " ///
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

		di in g "  (+) `=r(name`k')'" ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Ingresos (sin deuda)" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"
	
	return scalar Ingresos_sin_deuda = `mattot'[1,1]


	** 4.3 Crecimientos **
	if "`by'" == "divGA" {
		noisily di _newline in g "{bf: B. Crecimientos geom{c e'}tricos:" in y " `=`anio'-10' - `anio'" in g ///
			_col(55) %7s "Ingreso" ///
			_col(66) %7s "PIB" ///
			_col(77) %7s "Elasticidad" "}"


		tabstat recaudacion recaudacionPIB if anio == `anio' & divLIF != 10, by(`by') stat(sum) f(%20.0fc) save
		tempname mattot
		matrix `mattot' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat`k'
			matrix `mat`k'' = r(Stat`k')
			local ++k
		}

		capture tabstat recaudacion recaudacionPIB if anio == `anio'-10 & divLIF != 10, by(`by') stat(sum) f(%20.1fc) save
		if _rc == 0 {
			tempname mattot5
			matrix `mattot5' = r(StatTotal)

			local k = 1
			while "`=r(name`k')'" != "." {
				tempname mat5`k'
				matrix `mat5`k'' = r(Stat`k')

				noisily di in g "  (+) `=r(name`k')'" ///
					_col(55) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/10)-1)*100) ///
					_col(66) in y %7.3fc (((`pibYR`anio''/`pibYR`=`anio'-10'')^(1/10)-1)*100) ///
					_col(77) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/10)-1)*100)/ ///
					(((`pibYR`anio''/`pibYR`=`anio'-10'')^(1/10)-1)*100)

				local ++k
			}

			noisily di in g _dup(83) "-"
			noisily di in g "{bf:  (=) Ingresos (sin deuda)" ///
					_col(55) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/10)-1)*100) ///
					_col(66) in y %7.3fc (((`pibYR`anio''/`pibYR`=`anio'-10'')^(1/10)-1)*100) ///
					_col(77) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/10)-1)*100)/ ///
					(((`pibYR`anio''/`pibYR`=`anio'-10'')^(1/10)-1)*100) "}"
		}
	}



	*****************/
	* Returns Extras *
	if "$pais" == "" {
		capture tabstat recaudacion recaudacionPIB if anio == `anio' & nombre == "Cuotas a la seguridad social (IMSS)", stat(sum) f(%20.1fc) save
		tempname cuotas
		matrix `cuotas' = r(StatTotal)
		return scalar Cuotas_IMSS = `cuotas'[1,1]
		
		capture tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP == 11, stat(sum) by(nombre) f(%20.1fc) save
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



	if "`nographs'" != "nographs" {
		preserve
		tabstat recaudacionPIB if anio == `anio' & divLIF != 10, stat(sum) f(%20.0fc) save
		tempname recanio
		matrix `recanio' = r(StatTotal)
		
		*graph pie recaudacionPIB if anio == `anio' & divLIF != 10, over(`resumido') ///
			plabel(_all percent, format(%5.1fc)) ///
			title(`"Ingresos `=upper("`lif'`ilif'")'"') /// subtitle($pais) ///
			name(ingresospie, replace) ///
			legend(on position(6) rows(`rows') cols(`cols')) ///
			ptext(0 0 `"{bf:`=string(`recanio'[1,1],"%6.1fc")' % PIB}"', color(white) size(small))

		levelsof `resumido' if divLIF != 10, local(lev_resumido)
		local totlev = 0
		foreach k of local lev_resumido {
			local legend`k' : label `label' `k'
			local ++totlev
		}
		collapse (sum) recaudacion* ///
			if divLIF != 10 | recaudacion != 0 | recaudacion == ., by(anio `resumido')
		reshape wide recaudacion recaudacionPIB, i(anio) j(`resumido')
		local countlev = 1
		foreach k of local lev_resumido {
			tempvar lev_res`countlev'
			if `countlev' == 1 {
				g `lev_res`countlev'' = recaudacion`k'/1000000000000
			}
			else {
				g `lev_res`countlev'' = recaudacion`k'/1000000000000 + `lev_res`=`countlev'-1''
			}
			replace `lev_res`countlev'' = 0 if `lev_res`countlev'' == .
			
			local graphvars = "`lev_res`countlev'' `graphvars' "
			local legend = `"`legend' label(`=`totlev'-`countlev'+1' "`legend`k''")"'
			local ++countlev
		}

		tempvar TOTPIB
		egen `TOTPIB' = rsum(recaudacionPIB*)
		forvalues k=1(1)`=_N' {
			if `TOTPIB'[`k'] != . & anio[`k'] >= 2003 {
				local text `"`text' `=`TOTPIB'[`k']' `=anio[`k']' "{bf:`=string(`TOTPIB'[`k'],"%5.1fc")'}""'
			}
		}
		twoway (area `graphvars' anio if anio >= `aniofirst') ///
			(connected `TOTPIB' anio if anio >= `aniofirst', yaxis(2) mlcolor("255 129 0") lcolor("255 129 0")), ///
			title("{bf:Ingresos} p{c u'}blicos") ///
			subtitle($pais) ///
			text(`text', yaxis(2)) ///
			ytitle(billones `currency') ytitle(% PIB, axis(2)) xtitle("") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			ylabel(, axis(2) noticks format(%5.0fc) labsize(small)) ///
			yscale(range(0) axis(2) noline) ///
			xlabel(`aniofirst'(1)`aniolast', noticks) ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' label(`=`totlev'+1' "= Total (% PIB)")) ///
			name(ingresos, replace) ///
			caption("Elaborado por el CIEP, con informaci{c o'}n de la SHCP, EOFP (`aniolast'm`meslast').")
		restore
	}



	***********
	*** END ***
	***********
	capture drop __*
	timer off 4
	timer list 4
	noisily di _newline in g "Tiempo: " in y round(`=r(t4)/r(nt4)',.1) in g " segs."
}
end
