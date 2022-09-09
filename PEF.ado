program define PEF, return
quietly {

	timer on 5
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** 1.2 Datos Abiertos (Mexico) **
	if "`c(username)'" == "ricardo" & "$pais" == "" {
		*UpdateDatosAbiertos
		local updated = "yes" //r(updated)
		*local ultanio = r(ultanio)
		*local ultmes = r(ultmes)
	}
	else {
		local updated = "yes"
	}

	** 1.3 Base PEF **
	capture confirm file "`c(sysdir_site)'/SIM/$pais/PEF.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_site)'/UpdatePEF.do"
	}

	capture confirm scalar aniovp
	if _rc == 0 {
			local aniovp = scalar(aniovp)
	}	


	****************
	*** 2 SYNTAX ***
	****************
	use in 1 using "`c(sysdir_site)'/SIM/$pais/PEF.dta", clear
	syntax [if] [, ANIO(int `aniovp') NOGraphs Update Base ///
		BY(varname) ROWS(int 2) COLS(int 5) MINimum(real 1) PEF PPEF APROBado]

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
	*use "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
	local currency = currency[1]
	tempfile PIB
	save "`PIB'"

	** 2.2 Update PEF **
	if "`update'" == "update" /*| "`updated'" != "yes"*/ {
		noisily run "`c(sysdir_site)'/UpdatePEF.do"
	}

	** 2.2 Base RAW **
	use `if' using "`c(sysdir_site)'/SIM/$pais/PEF.dta", clear
	if "`base'" == "base" {
		exit
	}

	** 2.3 Default `by' **
	if "`by'" == "" {
		local by = "divPE"
	}



	***************
	*** 3 Merge ***
	***************
	collapse (sum) gasto*, by(anio `by' transf_gf) 
	merge m:1 (anio) using "`PIB'", nogen keepus(pibY indiceY deflator var_pibY) ///
		update replace keep(matched) sorted
	local aniofirst = anio[1]
	local aniolast = anio[_N]

	/*replace gasto = aprobado if gasto == . & aprobado != .
	capture confirm variable aprobadoneto
	if _rc == 0 {
		replace gastoneto = aprobadoneto if gasto == . & aprobadoneto != .
	}
	else {
		replace gastoneto = aprobado if gasto == . & aprobado != .
	}

	capture confirm variable proyecto
	if _rc == 0 {
		replace gasto = proyecto if gasto == . & proyecto != .
		replace gastoneto = proyectoneto if gasto == . & proyectoneto != .
	}*/

	** 3.2 Valores como % del PIB **
	foreach k of varlist gasto* {
		g double `k'PIB = `k'/pibY*100
	}
	format *PIB %10.3fc



	***************
	*** 4 Graph ***
	***************
	tempvar resumido resumidopie gastoPIB
	g `resumido' = `by'
	g `resumidopie' = `by'

	tempname label
	label copy `by' `label'
	label values `resumido' `label'
	label values `resumidopie' `label'

	egen `gastoPIB' = max(gastoPIB), by(`by')
	replace `resumido' = 99999 if abs(`gastoPIB') < `minimum' & `by' != -1
	replace `resumido' = 99998 if `by' == -1
	replace `resumidopie' = 99999 if gastoPIB < `minimum'
	label define `label' 99998 "Cuotas ISSSTE", add modify
	label define `label' 99999 "< `minimum'% PIB", add modify

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
	while `"`=r(name`k')'"' != "." {
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
		
	}

	** 4.2. Division Resumido **
	noisily di _newline in g "{bf: B. Gasto bruto (Resumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "Dif% Real" "}"

	preserve
	collapse (sum) gasto* if transf_gf == 0, by(anio pibY deflator `resumido')
	reshape wide gasto*, i(anio) j(`resumido')
	reshape long

	tempvar gasreal
	replace gasto = -gasto if `resumido' == 99998
	replace gastoPIB = -gastoPIB if `resumido' == 99998
	g `gasreal' = gasto/deflator

	capture tabstat `gasreal' if anio == `anio'-1, by(`resumido') stat(sum) f(%20.1fc) save missing
	if _rc == 0 {
		tempname pregastot
		matrix `pregastot' = r(StatTotal)
		local k = 1
		while `"`=r(name`k')'"' != "." {
			tempname pre`k'
			matrix `pre`k'' = r(Stat`k')
			local ++k
		}
	}

	tabstat gasto gastoPIB gastoCUOTAS if anio == `anio', by(`resumido') stat(sum) f(%20.1fc) save missing
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		
		capture confirm matrix `pre`k''
		if _rc != 0 {
			tempname pre`k'
			matrix `pre`k'' = J(1,1,0)
		}
		
		capture confirm matrix `pregastot'
		if _rc != 0 {
			tempname pregastot
			matrix `pregastot' = J(1,1,0)
		}

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
		return scalar `name'C = `mat`k''[1,3]
		local divResumido `"`divResumido' neto_`name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc (`mat`k''[1,1]/`pre`k''[1,1]-1)*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Gasto neto" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc (`mattot'[1,1]/`pregastot'[1,1]-1)*100 "}"
	
	return scalar Gasto_neto = `mattot'[1,1]


	tempname Resumido_total
	matrix `Resumido_total' = r(StatTotal)
	return scalar Resumido_total = `Resumido_total'[1,1]
	*restore


	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Cambios:" in y " `=`anio'-1' - `anio'" in g ///
		_col(44) %7s "% PIB `=`anio'-1'" ///
		_col(55) %7s "% PIB `anio'" ///
		_col(66) %7s "Dif pts" ///
		_col(77) %7s "Dif %" "}"

	*preserve
	*collapse (sum) gastoneto* (mean) pibY deflator if `by' != -1 & transf_gf == 0, by(anio `resumido')
	*reshape wide gastoneto*, i(anio) j(`resumido')
	*reshape long

	tabstat gasto gastoPIB if anio == `anio', by(`resumido') stat(sum) f(%20.1fc) missing save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat gasto gastoPIB if anio == `anio'-1, by(`resumido') stat(sum) f(%20.1fc) missing save
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)

		local k = 1
		while `"`=r(name`k')'"' != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')

			if substr(`"`=r(name`k')'"',1,25) == "'" {
				local disptext = substr(`"`=r(name`k')'"',1,24)
			}
			else {
				local disptext = substr(`"`=r(name`k')'"',1,25)
			}
			
			*if abs(`mat`k''[1,2]-`mat5`k''[1,2]) > .4 {
				noisily di in g `"  (+) `disptext'"' ///
					_col(44) in y %7.3fc `mat5`k''[1,2] ///
					_col(55) in y %7.3fc `mat`k''[1,2] ///
					_col(66) in y %7.3fc `mat`k''[1,2]-`mat5`k''[1,2] ///
					_col(77) in y %7.1fc (`mat`k''[1,2]-`mat5`k''[1,2])/`mat5`k''[1,2]*100
			*}
			local ++k
		}

		noisily di in g _dup(83) "-"
		noisily di in g "{bf:  (=) Total" ///
			_col(44) in y %7.3fc `mattot5'[1,2] ///
			_col(55) in y %7.3fc `mattot'[1,2] ///
			_col(66) in y %7.3fc `mattot'[1,2]-`mattot5'[1,2] ///
			_col(77) in y %7.1fc (`mattot'[1,2]-`mattot5'[1,2])/`mattot5'[1,2]*100 "}"
	}
	restore

	if "`nographs'" != "nographs" & "$nographs" == "" {
		preserve
		replace gasto = gasto/deflator/1000000000
		replace gastoCUOTAS = gastoCUOTAS/deflator/1000000000
		replace gasto = -gasto if `resumido' == 99998

		collapse (sum) gasto* if transf_gf == 0 & anio >= 2013, by(anio `resumido')
		reshape wide gasto*, i(anio) j(`resumido')
		reshape long

		levelsof `resumido' if anio == `anio', local(lev_resumido)
		tabstat gasto if anio == `anio', by(`resumido') stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		* Ciclo para poner los paréntesis (% del total) en el legend *
		local totlev = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')
			local legend`k' : label `label' `k'
			local legend`k' = substr("`legend`k''",1,20)
			local legend = `"`legend' label(`totlev' "`legend`k'' (`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)")"'
		}

		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -gasto
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
				local order "`order' `=`ordervar'[`k']'"
			}
		}

		* Ciclo para los texto totales *
		tabstat gasto gastonetoPIB gastoCUOTAS gastoCUOTASPIB, stat(sum) by(anio) save
		local j = 100/(`anio'-2013+1)/2
		forvalues k=1(1)`=`anio'-2013+1' {
			tempname TOT`k'
			matrix `TOT`k'' = r(Stat`k')
			local text `"`text' `=(`TOT`k''[1,1]+`TOT`k''[1,3])*1.005' `j' "{bf:`=string(`TOT`k''[1,2]-`TOT`k''[1,4],"%7.1fc")'% PIB}""'
			local j = `j' + 100/(`anio'-2013+1)
		}

		graph bar (sum) gasto if anio >= 2013 & anio <= `anio', ///
			over(`resumido', sort(1) descending) over(anio, gap(0)) stack asyvar ///
			blabel(, format(%7.1fc)) outergap(0) ///
			bar(9, color(150 6 92)) bar(8, color(53 200 71)) ///
			bar(7, color(255 129 0)) bar(6, color(224 97 83)) ///
			bar(5, color(255 189 0)) bar(4, color(0 151 201)) ///
			bar(3, color(255 55 0)) bar(2, color(57 198 184)) ///
			bar(1, color(210 213 32)) ///
			title("{bf:Gasto} p{c u'}blico presupuestario") ///
			subtitle($pais) ///
			text(`text', color(black) placement(n)) ///
			ytitle(mil millones MXN `anio') ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			yscale(range(0)) ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' region(margin(zero)) order(`order')) /// 
			name(gastos`by', replace) ///
			note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `anio'.") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/Cuentas Públicas y $paqueteEconomico.")

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
