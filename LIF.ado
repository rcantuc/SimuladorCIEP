program define LIF, return
quietly {

	timer on 4
	***********************
	*** 1 BASE DE DATOS ***
	***********************

	** 1.1 Anio valor presente **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	** 1.2 Base LIF **
	capture confirm file "`c(sysdir_personal)'/SIM/$pais/LIF.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_personal)'/UpdateLIF.do"  // Genera a partir de la base ./basesCIEP/LIFs/LIF.xlsx
	}



	***************
	*** 2 SYNTAX **
	***************
	use in 1 using "`c(sysdir_personal)'/SIM/$pais/LIF.dta", clear
	syntax [if] [, ANIO(int `aniovp' ) UPDATE NOGraphs Base ID(string) ///
		MINimum(real 0.5) DESDE(int `=`aniovp'-1') ILIF LIF EOFP BY(varname) ROWS(int 2) COLS(int 5) ///
		TITle(string) SUBTITle(string)]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Sistema Fiscal:" in y " INGRESOS $pais `anio'   }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput `update'
	local currency = currency[1]
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local pibYR`anio' = pibYR[`k']
		}
		if anio[`k'] == `desde' {
			local pibYR`desde' = pibYR[`k']
		}
	}
	tempfile PIB
	save `PIB'

	** 2.2 Datos Abiertos **
	if "`update'" == "update" {
		capture confirm file "`c(sysdir_personal)'/SIM/DatosAbiertos.dta"
		if _rc != 0 | "`update'" == "update" {
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

	** 2.3 Update LIF **
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
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator lambda var_pibY) update replace keep(matched) sorted
	
	capture sort anio mes
	capture keep `if'


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
	g resumido = `by'

	capture label copy `by' label
	if _rc != 0 {
		label copy num`by' label
	}
	label values resumido label

	egen `recaudacionPIB' = max(recaudacionPIB) /*if anio >= 2010*/, by(`by')
	replace resumido = 999 if abs(`recaudacionPIB') < `minimum' //& divCIEP != 15 | recaudacionPIB == . | recaudacionPIB == 0
	label define label 999 `"< `=string(`minimum',"%5.1fc")'% PIB"', add modify

	capture replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	capture replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	capture replace nombre = subinstr(nombre,"/","_",.)
	


	********************
	** 4. Display LIF **

	** 4.1 Division `by' **
	noisily di _newline in g "{bf: A. Ingresos presupuestarios (`by')}" ///
		_newline ///
		_col(30) in g %20s "`currency'" ///
		_col(52) %7s "% PIB" ///
		_col(61) %7s "% Tot"

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
		if substr(`"`=r(name`k')'"',1,31) ==`"'"'' {
			local disptext = substr(`"`=r(name`k')'"',1,30)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,31)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		//return scalar `name' = `mat`k''[1,1]
		//return scalar `name'PIB = `mat`k''[1,2]
		//return scalar `name'Tot = `mat`k''[1,1]/`mattot'[1,1]*100
		local `by' `"``by'' `name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(30) in y %20.0fc `mat`k''[1,1] ///
			_col(52) in y %7.3fc `mat`k''[1,2] ///
			_col(61) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local `by' `"``by''"'

	noisily di in g _dup(68) "-"
	noisily di in g "{bf:  (=) Ingresos totales" ///
		_col(30) in y %20.0fc `mattot'[1,1] ///
		_col(52) in y %7.3fc `mattot'[1,2] ///
		_col(61) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"

	return scalar `=strtoname("Ingresos totales")' = `mattot'[1,1]

	** 4.2 Division Resumido **
	noisily di _newline in g "{bf: B. Ingresos presupuestarios (divResumido)}" ///
		_newline ///
		_col(30) in g %20s "`currency'" ///
		_col(52) %7s "% PIB" ///
		_col(61) %7s "% Real"

	preserve
	g by = `by'
	collapse (sum) recaudacion* if divLIF != 10, by(anio pibY deflator resumido)
	reshape wide recaudacion*, i(anio) j(resumido)
	reshape long

	tempvar recreal
	g `recreal' = recaudacion/deflator
	capture tabstat `recreal' if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save
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

	tabstat recaudacion recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.1fc) save
	tempname sindeudatot
	matrix `sindeudatot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		* Display text *
		if substr(`"`=r(name`k')'"',1,25) == `"'"' {
			local disptext = substr(`"`=r(name`k')'"',1,24)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,25)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		return scalar `=strtoname("`=r(name`k')'")' = `mat`k''[1,1]
		return scalar `=strtoname("`=r(name`k')'")'PIB = `mat`k''[1,2]
		return scalar `=strtoname("`=r(name`k')'")'C = ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`anio'-`desde''))-1)*100
		local divResumido `"`divResumido' `=strtoname(abbrev("`=r(name`k')'",7))'"'

		noisily di in g "  (+) `=r(name`k')'" ///
			_col(30) in y %20.0fc `mat`k''[1,1] ///
			_col(52) in y %7.3fc `mat`k''[1,2] ///
			_col(61) in y %7.1fc ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`anio'-`desde''))-1)*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(68) "-"
	noisily di in g "{bf:  (=) Ingresos (sin deuda)" ///
		_col(30) in y %20.0fc `sindeudatot'[1,1] ///
		_col(52) in y %7.3fc `sindeudatot'[1,2] ///
		_col(61) in y %7.1fc (`sindeudatot'[1,1]/`sindeudatotpre'[1,1]-1)*100 "}"
	
	return scalar Ingresos_sin_deuda = `sindeudatot'[1,1]
	return scalar Ingresos_sin_deudaPIB = `sindeudatot'[1,2]
	return scalar Ingresos_sin_deudaC = (`sindeudatot'[1,1]/`sindeudatotpre'[1,1]-1)*100


	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Cambios:" in y " `desde' - `anio'" in g " (% PIB)}" ///
		_newline ///
		_col(33) %7s "`desde'" ///
		_col(43) %7s "`anio'" ///
		_col(52) %7s "Dif" ///
		_col(61) %7s "Dif %"

	tabstat recaudacion recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacion recaudacionPIB if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')

			if substr(`"`=r(name`k')'"',1,25) == `"'"' {
				local disptext = substr(`"`=r(name`k')'"',1,24)
			}
			else {
				local disptext = substr(`"`=r(name`k')'"',1,25)
			}

			if `mat`k''[1,1] != . & `mat5`k''[1,1] != . {
				noisily di in g `"  (+) `disptext'"' ///
					_col(33) in y %7.3fc `mat5`k''[1,2] ///
					_col(43) in y %7.3fc `mat`k''[1,2] ///
					_col(52) in y %7.3fc `mat`k''[1,2]-`mat5`k''[1,2] ///
					_col(61) in y %7.1fc (`mat`k''[1,2]-`mat5`k''[1,2])/`mat5`k''[1,2]*100
			}
			local ++k
		}

		noisily di in g _dup(68) "-"
		noisily di in g "{bf:  (=) Ingresos" ///
			_col(33) in y %7.3fc `mattot5'[1,2] ///
			_col(43) in y %7.3fc `mattot'[1,2] ///
			_col(52) in y %7.3fc `mattot'[1,2]-`mattot5'[1,2] ///
			_col(61) in y %7.1fc (`mattot'[1,2]-`mattot5'[1,2])/`mattot5'[1,2]*100 "}"
	}
	restore

	** 4.4 Elasticidades **/
	noisily di _newline in g "{bf: D. Elasticidades:" in y " `desde' - `anio'}" in g ///
		_newline ///
		_col(33) %7s "%G" ///
		_col(43) %7s "%G pibR" ///
		_col(52) %7s "Elastic"

	g recaudacionR = recaudacion/deflator

	tabstat recaudacionR recaudacionPIB if anio == `anio' & divLIF != 10, by(resumido) stat(sum) f(%20.3fc) save missing
	tempname mattot
	matrix `mattot' = r(StatTotal)
	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacionR recaudacionPIB if anio == `desde' & divLIF != 10, by(resumido) stat(sum) f(%20.3fc) save missing
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)
		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')
			
			if `mat`k''[1,1] != . & `mat5`k''[1,1] != . {
				noisily di in g "  (+) `=r(name`k')'" ///
					_col(33) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1)*100) ///
					_col(43) in y %7.3fc (((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100) ///
					_col(52) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1))/ ///
					(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1))
			}
			return scalar E`=strtoname("`=r(name`k')'")' = (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1))/ ///
					(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1))
			local E`=strtoname("`=r(name`k')'")' = (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1))/ ///
					(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1))
			local ++k
		}

		noisily di in g _dup(59) "-"
		noisily di in g "{bf:  (=) Ingresos totales" ///
				_col(33) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/(`=`anio'-`desde''))-1)*100) ///
				_col(43) in y %7.3fc (((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100) ///
				_col(52) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/(`=`anio'-`desde''))-1)*100)/ ///
				(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100) "}"
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
		*preserve

		* Normalizar valores a billones *
		replace recaudacion=recaudacion/deflator/1000000000000
		replace monto=monto/deflator/1000000000000
		replace LIF=LIF/deflator/1000000000000

		collapse (sum) recaudacion* if divLIF != 10 & anio >= `desde', by(anio resumido)
		levelsof resumido, local(lev_resumido)
		label values resumido label
		
		* Ciclo para poner los paréntesis (% del total) en el legend *
		tabstat recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		local totlev = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')

			local legend`k' : label label `k'
			*local legend`k' = substr("`legend`k''",1,20)
			local legend = `"`legend' label(`totlev' "{bf:`legend`k''}")"'  
			//"(`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)"

			tempvar recaudacionPIB`k' connectedPIB`k' connectedTOT`k'
			egen `recaudacionPIB`k'' = sum(recaudacionPIB) if resumido >= `k', by(anio)
			replace `recaudacionPIB`k'' = 0 if `recaudacionPIB`k'' == .
			label var `recaudacionPIB`k'' "`legend`k''"

			egen `connectedTOT`k'' = sum(recaudacion), by(anio)
			g `connectedPIB`k'' = recaudacion/`connectedTOT`k''*100 if resumido == `k'
			//replace `connectedPIB`k'' = . if anio != `anio' & anio != `desde'
			format `recaudacionPIB`k'' `connectedPIB`k'' %7.1fc

			local extras = `"`extras' (area `recaudacionPIB`k'' anio if anio <= `anio' & resumido == `k', mlabpos(0) mlabcolor("114 113 118") mlabsize(vsmall) lpattern(dot) msize(small) mlabel(`recaudacionPIB`k'')) "'

			local extras2 = `"`extras2' (connected `connectedPIB`k'' anio if anio <= `anio', mlabpos(12) mlabcolor("114 113 118") mlabsize(small) mlabel(`connectedPIB`k'')) "'

			*local gr_edit`totlev' `"gr_edit .legend.plotregion1.key[`totlev'].xsz.editstyle `=`SUM`totlev''[1,1]/`SUM'[1,1]*100'"'
		}
		local legend `"`legend' label(`=`totlev'+1' "Recaudación total")"'
		
		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -recaudacion
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
			*	local order "`order' `=`ordervar'[`k']'"
			}
		}

		* Ciclo para los texto totales *
		tabstat recaudacion recaudacionPIB, stat(sum) by(anio) save
		local j = 100/(`anio'-`desde'+1)/2
		forvalues k=1(1)`=`anio'-`desde'+1' {
			if anio[`k'] >= `desde' & anio[`k'] <= `anio' {
				tempname TOT`k'
				matrix `TOT`k'' = r(Stat`k')
				local text `"`text' `=`TOT`k''[1,1]*1.005' `j' "{bf:`=string(`TOT`k''[1,2],"%7.1fc")'% PIB}""'
				local j = `j' + 100/(`anio'-`desde'+1)
			}
		}

		if "`title'" == "" {
			local graphtitle "{bf:Ingresos presupuestarios}"
			local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle "`title'"
			local graphfuente ""
		}

		tempvar recaudacionbar
		g `recaudacionbar' = recaudacion //if anio == `anio' | anio == `desde'
		replace `recaudacionbar' = 0 if `recaudacionbar' == .
		format recaudacion* `recaudacionbar' %15.1fc

		//graph bar `recaudacionbar', ///
		//	over(resumido, sort(1) descending) over(anio, gap(30)) ///
		//	stack asyvars percentages blabel(bar, format(%7.1fc)) outergap(0) ///
		twoway `extras2', ///aspectratio(4) ///
			xtitle("") ///
			xlabel(`desde'(1)`anio') ///
			subtitle("Distribución, como % de la recaudación") ///
			///subtitle(billones MXN `aniovp') ///
			///note("Nota: Porcentajes entre par{c e'}ntesis son con respecto al total de `anio'.") ///
			///bar(4, color(40 173 58)) bar(1, color(255 55 0)) ///
			///bar(2, color(255 129 0)) ///
			///text(`text', color(black) placement(n) size(vsmall)) ///
			///text(110 50 "De `desde' a `anio'," "{bf:el PIB creció `=string(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100,"%7.1fc")'%}," "en promedio, cada año.", placement(12) size(small) justification(center)) ///
			///ytitle("billones `currency' `anio'") ///
			ylabel(none, format(%15.1fc) labsize(small)) ///
			yscale(range(0 100)) ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' region(margin(zero)) /*symxsize(5)*/ symysize(6) width(250) order(`order') justification(left)) ///
			name(ingresosMXN`by', replace)

		foreach k of local lev_resumido {
			//`gr_edit`k''
			//`gr_edit2`k''
		}

		* Información agregada *
		egen recaudacionPIBTOT = sum(recaudacionPIB), by(anio)
		format recaudacionPIBTOT %7.1fc

		* Máximo *
		tabstat recaudacionPIBTOT, stat(max) by(anio) save
		tempname maxPIBTOT
		matrix `maxPIBTOT' = r(StatTotal)

		* Inicial *
		tabstat recaudacionPIBTOT if anio == `desde', stat(max) save by(anio)
		tempname iniPIBTOT
		matrix `iniPIBTOT' = r(StatTotal)

		* Final *
		tabstat recaudacionPIBTOT if anio == `anio', stat(max) save by(anio)
		tempname finPIBTOT
		matrix `finPIBTOT' = r(StatTotal)

		* Cambios * 
		if (`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]) > 0 {
			local cambio = "aumentó"
		}
		else {
			local cambio = "disminuyó"
		}

		twoway `extras' ///
			(connected recaudacionPIBTOT anio if anio <= `anio', ///
				mlabel(recaudacionPIBTOT) mlabpos(12) mlabcolor("114 113 118") mlabsize(small) lpattern(dot) msize(small)) ///
			, ///aspectratio(.25) ///
		///graph bar recaudacionPIB if anio <= `anio', ///
		///	over(resumido, sort(1) descending) over(anio, gap(30)) ///
		///	stack asyvars blabel(bar, format(%7.1fc)) outergap(0) ///
			name(ingresos`by'PIB, replace) ///
			yscale(range(0 `=`maxPIBTOT'[1,1]*1.25')) ///
			ylabel(none, format(%7.1fc) labsize(small)) ///
			xlabel(`desde'(1)`anio') ///
			xtitle("") ///
			ytitle("") ///
			subtitle("Recaudación, como % del PIB") ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' region(margin(zero)) /*symxsize(5)*/ symysize(6) width(250) order(`order') justification(left)) ///
			/// Added text 
			xline(`desde', lcolor("114 113 118") lpattern(dot)) ///
			xline(`anio', lcolor("114 113 118") lpattern(dot)) ///
			text(`=`maxPIBTOT'[1,1]*1.15' `=(`anio'-`desde')/2+`desde'' "De `desde' a `anio'," "{bf:la recaudación `cambio' `=string((`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]),"%7.1fc")'}" "puntos porcentuales del PIB", size(medsmall)) ///

		grc1leg ///
		///graph combine ///
		ingresos`by'PIB ingresosMXN`by' , ///
			title("{bf:`graphtitle'}") ///
			caption("Fuente: Elaborado por el CIEP, con informaci{c o'}n de SHCP/EOFP, INEGI/BIE y $paqueteEconomico.") ///
			name(ingresos`by', replace) xcommon ///

		capture window manage close graph ingresosMXN`by'
		capture window manage close graph ingresos`by'PIB
	
		if "$export" != "" {
			graph export "$export/ingresos`by'.png", as(png) name("ingresos`by'") replace
		}
		*restore
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
