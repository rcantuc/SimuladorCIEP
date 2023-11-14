program define PEF, return
quietly {

	timer on 5
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	** ¿Existe base PEF.dta? **
	capture confirm file "`c(sysdir_personal)'/SIM/$pais/PEF.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_personal)'/UpdatePEF.do"
	}

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}	


	****************
	*** 2 SYNTAX ***
	****************
	use in 1 using "`c(sysdir_personal)'/SIM/$pais/PEF.dta", clear
	syntax [if] [, ANIO(int `aniovp') NOGraphs Update Base ///
		BY(varname) ROWS(int 2) COLS(int 5) MINimum(real 1) PEF PPEF APROBado DESDE(int `=`aniovp'-1')]

	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: GASTOS $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save "`PIB'"

	** 2.2 Update PEF **
	if "`update'" == "update" {
		noisily run "`c(sysdir_personal)'/UpdatePEF.do" `update'
	}

	** 2.2 Base RAW **
	use `if' using "`c(sysdir_personal)'/SIM/$pais/PEF.dta", clear
	if "`base'" == "base" {
		exit
	}

	** 2.3 Default `by' **
	if "`by'" == "" {
		local by = "divCIEP"
	}
	replace desc_pp = 914 if desc_pp == 915
	replace desc_pp = 71 if desc_pp == 72



	***************
	*** 3 Merge ***
	***************
	collapse (sum) gasto*, by(anio `by' transf_gf) fast
	merge m:1 (anio) using "`PIB'", nogen keepus(pibY indiceY deflator var_pibY) keep(matched) sorted
	forvalues k=1(1)`=_N' {
		if gasto[`k'] != . & "`first'" != "first" { 
			local aniofirst = 2016 //anio[`k']
			local first "first"
		}
	}
	local aniolast = anio[_N]

	** 3.1 Valores como % del PIB **
	foreach k of varlist gasto* {
		g double `k'PIB = `k'/pibY*100
	}
	format *PIB %10.3fc



	******************
	*** 4 Resumido ***
	******************
	tempvar resumido resumidopie gastoPIB
	g `resumido' = `by'
	g `resumidopie' = `by'

	tempname labelresumido
	label copy `by' labelresumido
	label values `resumido' labelresumido
	label values `resumidopie' labelresumido

	egen `gastoPIB' = max(gastoPIB), by(`by')
	replace `resumido' = 99999998 if `by' == -1
	label define labelresumido 99999998 "Cuotas ISSSTE", add modify

	replace `resumido' = 99999999 if abs(`gastoPIB') < `minimum' & `by' != -1
	replace `resumidopie' = 99999999 if gastoPIB < `minimum'
	label define labelresumido 99999999 "< `minimum'% PIB", add modify



	********************
	** 5. Display PEF **
	
	** 5.1 Division `by' **
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
		if substr(`"`=r(name`k')'"',1,35) == "'" {
			local disptext = substr(`"`=r(name`k')'"',1,34)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,35)
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

	** 5.2 Gasto neto **
	* Aportaciones y cuotas de la Federacion *
	capture tabstat gasto gastoPIB if anio == `anio' & transf_gf == 1, stat(sum) f(%20.0fc) save
	tempname Aportaciones_Federacion
	if _rc == 0 {
		matrix `Aportaciones_Federacion' = r(StatTotal)
	}
	else {
		matrix `Aportaciones_Federacion' = J(1,2,0)
	}
	return scalar Aportaciones_a_Seguridad_Social = `Aportaciones_Federacion'[1,1]

	capture tabstat gasto gastoPIB if `by' == -1 & anio == `anio', stat(sum) f(%20.0fc) save
	tempname Cuotas_ISSSTE
	if _rc == 0 {
		matrix `Cuotas_ISSSTE' = r(StatTotal)
		return scalar Cuotas_ISSSTE = `Cuotas_ISSSTE'[1,1]
	}
	else {
		matrix `Cuotas_ISSSTE' = J(1,2,0)		
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


	** 4.2. Division Resumido **
	noisily di _newline in g "{bf: B. Gasto bruto (Resumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "Dif% Real" "}"

	collapse (sum) gasto* if transf_gf == 0, by(anio pibY deflator `resumido')
	g resumido = `resumido'
	reshape wide gasto* `resumido', i(anio) j(resumido)
	reshape long
	label values resumido labelresumido

	replace gasto = 0 if gasto == .
	replace gastoPIB = 0 if gastoPIB == .
	replace gasto = -gasto if resumido == 99999998
	replace gastoPIB = -gastoPIB if resumido == 99999998
	
	g gastoreal = gasto/deflator
	capture tabstat gastoreal if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save missing
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

	tabstat gasto gastoPIB if anio == `anio', by(resumido) stat(sum) f(%20.1fc) save missing
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
		return scalar `name'C = ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`aniovp'-`desde''))-1)*100
		local divResumido `"`divResumido' `name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`aniovp'-`desde''))-1)*100
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


	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Cambios:" in y " `=`desde'' - `anio'" in g ///
		_col(44) %7s "% PIB `anio'" ///
		_col(55) %7s "% PIB `=`desde''" ///
		_col(66) %7s "Dif pts" ///
		_col(77) %7s "Dif %" "}"

	capture tabstat gasto gastoPIB if anio == `desde', by(resumido) stat(sum) f(%20.1fc) missing save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat gasto gastoPIB if anio == `anio', by(resumido) stat(sum) f(%20.1fc) missing save
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)

		local k = 1
		while `"`=r(name`k')'"' != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')

			if substr(`"`=r(name`k')'"',1,25) == "'" {
				local disptext = substr(`"`=r(name`k')'"',1,25)
			}
			else {
				local disptext = substr(`"`=r(name`k')'"',1,26)
			}
			
			noisily di in g `"  (+) `disptext'"' ///
				_col(44) in y %7.3fc `mat5`k''[1,2] ///
				_col(55) in y %7.3fc `mat`k''[1,2] ///
				_col(66) in y %7.3fc `mat5`k''[1,2]-`mat`k''[1,2] ///
				_col(77) in y %7.1fc (`mat5`k''[1,2]-`mat`k''[1,2])/`mat`k''[1,2]*100

			local ++k
		}

		noisily di in g _dup(83) "-"
		noisily di in g "{bf:  (=) Total" ///
			_col(44) in y %7.3fc `mattot5'[1,2] ///
			_col(55) in y %7.3fc `mattot'[1,2] ///
			_col(66) in y %7.3fc `mattot5'[1,2]-`mattot'[1,2] ///
			_col(77) in y %7.1fc (`mattot5'[1,2]-`mattot'[1,2])/`mattot'[1,2]*100 "}"
	}

	if "`nographs'" != "nographs" & "$nographs" == "" {
		replace gastoreal = gastoreal/1000000000
		
		levelsof resumido if anio == `anio', local(lev_resumido)
		tabstat gastoreal if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		* Ciclo para poner los paréntesis (% del total) en el legend *
		local totlev = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')
			local legend`k' : label labelresumido `k'
			local legend`k' = substr("`legend`k''",1,23)
			local legend = `"`legend' label(`totlev' "`legend`k'' (`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)")"'
		}

		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -gastoreal
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
				local order "`order' `=`ordervar'[`k']'"
			}
		}

		* Ciclo para los texto totales *
		capture tabstat gastoreal if resumido == 99999998 & anio >= `aniofirst', stat(sum) by(anio) save
		if _rc == 0 {
			forvalues k=1(1)`=`anio'-`aniofirst'+1' {
				tempname CUOTAS`k'
				matrix `CUOTAS`k'' = r(Stat`k')
			}
		}
		else {
			forvalues k=1(1)`=`anio'-`aniofirst'+1' {
				tempname CUOTAS`k'
				matrix `CUOTAS`k'' = J(1,1,0)
			}
		}

		tabstat gastoreal gastoPIB if anio >= `aniofirst', stat(sum) by(anio) save
		local j = 100/(`anio'-`aniofirst'+1)/2
		forvalues k=1(1)`=`anio'-`aniofirst'+1' {
			tempname TOT`k'
			matrix `TOT`k'' = r(Stat`k')
			if `TOT`k''[1,1]-`CUOTAS`k''[1,1] != . {
				local text `"`text' `=(`TOT`k''[1,1]-`CUOTAS`k''[1,1])*1.02' `j' "{bf:`=string(`TOT`k''[1,1],"%7.1fc")'}""'
				local j = `j' + 100/(`anio'-`aniofirst'+1)
			}
		}
		//if "$export" == "" {
			local graphtitle "Gasto público"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP."
		//}
		//else {
		//	local graphtitle ""
		//	local graphfuente ""
		//}
		graph bar (sum) gastoreal if anio >= `aniofirst' & anio <= `anio', ///
			over(resumido, sort(1) descending) over(anio, gap(0)) stack asyvar ///
			blabel(, format(%10.1fc)) outergap(0) ///
			bar(9, color(150 6 92)) bar(8, color(53 200 71)) ///
			bar(7, color(255 129 0)) bar(6, color(0 151 201)) ///
			bar(5, color(224 97 83)) bar(4, color(255 189 0)) ///
			bar(3, color(255 55 0)) bar(2, color(57 198 184)) ///
			bar(1, color(211 199 225)) ///
			title("`graphtitle'") ///
			subtitle("por `by'") ///
			caption("`graphfuente'") ///
			text(`text', color(black) placement(n) size(small)) ///
			ytitle(mil millones MXN `anio') ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			yscale(range(0)) ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' order(`order')) /// 
			name(gastos`by', replace) ///
			note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `anio'.")

		if "$export" != "" {
			*graph export "$export/gastos`by'`if'.png", as(png) name("gastos`by'") replace
			graph save gastos`by' "$export/gastos`by'`if'.gph", replace
		}
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
