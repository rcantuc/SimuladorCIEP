program define LIF, return
quietly {

	timer on 4
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 Datos Abiertos (Mexico) **
	if "$pais" == "" {
		capture confirm file "`c(sysdir_site)'/SIM/DatosAbiertos.dta"
		if _rc != 0 {
			UpdateDatosAbiertos
			local updated = r(updated)
			local ultanio = r(ultanio)
			local ultmes = r(ultmes)
		}
		else {
			local updated = "yes" // r(updated)
		}
	}
	else {
		local updated = "yes"
	}

	** 1.3 Base LIF **
	capture confirm file "`c(sysdir_site)'/SIM/$pais/LIF.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_site)'/UpdateLIF.do"  // Genera a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}
	
	capture confirm scalar aniovp
	if _rc == 0 {
			local aniovp = scalar(aniovp)
	}	


	***************
	*** 2 SYNTAX **
	***************
	use in 1 using "`c(sysdir_site)'/SIM/$pais/LIF.dta", clear
	syntax [if] [, ANIO(int `aniovp' ) UPDATE NOGraphs Base ID(string) ///
		MINimum(real 0.5) DESDE(int 2013) ILIF LIF EOFP BY(varname) ROWS(int 2) COLS(int 5)]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Sistema Fiscal:" in y " INGRESOS $pais `anio'   }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	*use "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
	local currency = currency[1]
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local pibYR`anio' = pibYR[`k']
		}
		if anio[`k'] == `anio'-9 {
			local pibYR`=`anio'-9' = pibYR[`k']
		}
	}
	tempfile PIB
	save `PIB'

	** 2.2 Update LIF **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run "`c(sysdir_site)'/UpdateLIF.do"			// Actualiza a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}

	** 2.4 Base RAW **
	use `if' using "`c(sysdir_site)'/SIM/$pais/LIF.dta", clear
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
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator lambda var_pibY) update replace keep(matched) sorted
	
	capture sort anio mes
	capture keep `if'

	*keep if anio >= 2002
	local aniofirst = anio[1]
	local aniolast = anio[_N]

	capture tabstat mes if anio == `aniolast', stat(max) save
	tempname MLast
	matrix `MLast' = r(StatTotal)
	if `MLast'[1,1] != . {
		local meslast = "m`=`MLast'[1,1]'"
	}

	** 3.1 Utilizar LIF o ILIF **
	capture replace recaudacion = LIF if mes < 12
	if "`eofp'" == "eofp" {
		replace recaudacion = monto if mes < 12
	}
	replace recaudacion = ILIF if mes == .

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
	replace `resumido' = 999 if abs(`recaudacionPIB') < `minimum' //& divCIEP != 15 | recaudacionPIB == . | recaudacionPIB == 0
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
	noisily di _newline in g "{bf: B. Ingresos presupuestarios (divResumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Real" "}"

	preserve
	g by = `by'
	g resumido = `resumido'
	collapse (sum) recaudacion* if divLIF != 10, by(anio pibY deflator `resumido')
	reshape wide recaudacion*, i(anio) j(`resumido')
	reshape long

	tempvar recreal
	g `recreal' = recaudacion/deflator
	capture tabstat `recreal' if anio == `anio'-1, by(`resumido') stat(sum) f(%20.1fc) save
	if _rc == 0 {
		tempname sindeudatotpre
		matrix `sindeudatotpre' = r(StatTotal)
		local k = 1
		while "`=r(name`k')'" != "." {
			tempname pre`k'
			matrix `pre`k'' = r(Stat`k')
			local ++k
		}
	}

	tabstat recaudacion recaudacionPIB if anio == `anio', by(`resumido') stat(sum) f(%20.1fc) save
	tempname sindeudatot
	matrix `sindeudatot' = r(StatTotal)

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
			_col(77) in y %7.1fc (`mat`k''[1,1]/`pre`k''[1,1]-1)*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Ingresos (sin deuda)" ///
		_col(44) in y %20.0fc `sindeudatot'[1,1] ///
		_col(66) in y %7.3fc `sindeudatot'[1,2] ///
		_col(77) in y %7.1fc (`sindeudatot'[1,1]/`sindeudatotpre'[1,1]-1)*100 "}"
	
	return scalar Ingresos_sin_deuda = `sindeudatot'[1,1]


	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Cambios:" in y " `=`anio'-1' - `anio'" in g " (% PIB)" ///
		_col(44) %7s "`=`anio'-1'" ///
		_col(55) %7s "`anio'" ///
		_col(66) %7s "Dif" ///
		_col(77) %7s "Dif %" "}"

	tabstat recaudacion recaudacionPIB if anio == `anio', by(`resumido') stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacion recaudacionPIB if anio == `anio'-1, by(`resumido') stat(sum) f(%20.1fc) save
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

			if `mat`k''[1,1] != . & `mat5`k''[1,1] != . {
				noisily di in g `"  (+) `disptext'"' ///
					_col(44) in y %7.3fc `mat5`k''[1,2] ///
					_col(55) in y %7.3fc `mat`k''[1,2] ///
					_col(66) in y %7.3fc `mat`k''[1,2]-`mat5`k''[1,2] ///
					_col(77) in y %7.1fc (`mat`k''[1,2]-`mat5`k''[1,2])/`mat5`k''[1,2]*100 in g "%"
			}
			local ++k
		}

		noisily di in g _dup(83) "-"
		noisily di in g "{bf:  (=) Ingresos" ///
			_col(44) in y %7.3fc `mattot5'[1,2] ///
			_col(55) in y %7.3fc `mattot'[1,2] ///
			_col(66) in y %7.3fc `mattot'[1,2]-`mattot5'[1,2] ///
			_col(77) in y %7.1fc (`mattot'[1,2]-`mattot5'[1,2])/`mattot5'[1,2]*100 in g "%}"
	}
	restore

	** 4.4 Elasticidades **
	noisily di _newline in g "{bf: D. Elasticidades:" in y " `=`anio'-9' - `anio'" in g ///
		_col(44) %7s "Crec %G IngR" ///
		_col(66) %7s "Crec %G pibYR" ///
		_col(88) %7s "Elasticidad" "}"

	g recaudacionR = recaudacion/deflator

	tabstat recaudacionR recaudacionPIB if anio == `anio' & divLIF != 10, by(`resumido') stat(sum) f(%20.3fc) save missing
	tempname mattot
	matrix `mattot' = r(StatTotal)
	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacionR recaudacionPIB if anio == `anio'-9 & divLIF != 10, by(`resumido') stat(sum) f(%20.3fc) save missing
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)
		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')
			
			if `mat`k''[1,1] != . & `mat5`k''[1,1] != . {
				noisily di in g "  (+) `=r(name`k')'" ///
					_col(44) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/9)-1)*100) in g "%" ///
					_col(66) in y %7.3fc (((`pibYR`anio''/`pibYR`=`anio'-9'')^(1/9)-1)*100) in g "%" ///
					_col(88) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/9)-1)*100)/ ///
					(((`pibYR`anio''/`pibYR`=`anio'-9'')^(1/9)-1)*100)
			}
			local ++k
		}

		noisily di in g _dup(95) "-"
		noisily di in g "{bf:  (=) Ingresos totales" ///
				_col(44) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/9)-1)*100) in g "%" ///
				_col(66) in y %7.3fc (((`pibYR`anio''/`pibYR`=`anio'-9'')^(1/9)-1)*100) in g "%" ///
				_col(88) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/9))*100)/ ///
				(((`pibYR`anio''/`pibYR`=`anio'-9'')^(1/9))*100) "}"
	}
	drop recaudacionR



	******************
	* Returns Extras *
	capture tabstat recaudacion recaudacionPIB if anio == `anio' & nombre == "Cuotas a la seguridad social (IMSS)", stat(sum) f(%20.1fc) save
	tempname cuotas
	matrix `cuotas' = r(StatTotal)
	return scalar Cuotas_IMSS = `cuotas'[1,1]

	capture tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP == 12, stat(sum) by(nombre) f(%20.1fc) save
	
	tempname ieps
	matrix `ieps'1 = r(Stat1)
	return scalar Alcohol = `ieps'1[1,1]

	matrix `ieps'2 = r(Stat2)
	return scalar AlimNoBa = `ieps'2[1,1]

	matrix `ieps'7 = r(Stat7)
	return scalar Juegos = `ieps'7[1,1]
	
	matrix `ieps'6 = r(Stat6)
	return scalar Cervezas = `ieps'6[1,1]
	
	matrix `ieps'9 = r(Stat9)
	return scalar Tabacos = `ieps'9[1,1]
	
	matrix `ieps'10 = r(Stat10)
	return scalar Telecom = `ieps'10[1,1]
	
	matrix `ieps'3 = r(Stat3)
	return scalar Energiza = `ieps'3[1,1]

	matrix `ieps'4 = r(Stat4)
	return scalar Saboriza = `ieps'4[1,1]

	matrix `ieps'5 = r(Stat5)
	return scalar Fosiles = `ieps'5[1,1]

	if "`nographs'" != "nographs" & "$nographs" == "" {
		preserve
		replace recaudacion=recaudacion/deflator/1000000000
		replace monto=monto/deflator/1000000000
		replace LIF=LIF/deflator/1000000000

		collapse (sum) recaudacion* if divLIF != 10 & anio >= 2013, by(anio `resumido')

		levelsof `resumido', local(lev_resumido)
		
		tabstat recaudacionPIB if anio == `anio', by(`resumido') stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		* Ciclo para poner los paréntesis (% del total) en el legend *
		local totlev = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')
			local legend`k' : label `label' `k'
			*local legend`k' = substr("`legend`k''",1,20)
			local legend = `"`legend' label(`totlev' "`legend`k'' (`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)")"'
		}
		
		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -recaudacion
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
				local order "`order' `=`ordervar'[`k']'"
			}
		}

		* Ciclo para los texto totales *
		tabstat recaudacion recaudacionPIB, stat(sum) by(anio) save
		local j = 100/(`anio'-2013+1)/2
		forvalues k=1(1)`=`anio'-2013+1' {
			if anio[`k'] >= 2013 & anio[`k'] <= `anio' {
				tempname TOT`k'
				matrix `TOT`k'' = r(Stat`k')
				local text `"`text' `=`TOT`k''[1,1]*1.005' `j' "{bf:`=string(`TOT`k''[1,2],"%7.1fc")'% PIB}""'
				local j = `j' + 100/(`anio'-2013+1)
			}
		}

		graph bar recaudacion if anio >= 2012 & anio <= `anio', ///
			over(`resumido', sort(1) descending) over(anio, gap(0)) ///
			stack asyvars blabel(bar, format(%7.1fc)) outergap(0) ///
			title("{bf:Ingresos} p{c u'}blicos presupuestarios") ///
			subtitle($pais) ///
			bar(4, color(40 173 58)) bar(1, color(255 55 0)) ///
			bar(2, color(255 129 0)) ///
			text(`text', color(black) placement(n)) ///
			ytitle("mil millones `currency' `anio'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			yscale(range(0)) ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' region(margin(zero)) order(`order')) ///
			name(ingresos`by', replace) ///
			note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `anio'.") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico.")
		
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
