program define PEF, return
timer on 5
quietly {

	*****************
	*** 0. INICIO ***
	*****************

	** 0.1 Anio valor presente **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	** 0.2 Base PEF **
	capture confirm file "`c(sysdir_site)'/04_master/PEF.dta"
	if _rc != 0 {
		noisily UpdatePEF
	}



	****************
	*** 1 SYNTAX ***
	****************
	use in 1 using "`c(sysdir_site)'/04_master/PEF.dta", clear
	syntax [if] [, ANIO(int `aniovp') BY(varname) ///
		UPDATE NOGraphs Base ///
		MINimum(real 1) DESDE(int -1) ///
	 	PEF PPEF APROBado  ///
		ROWS(int 1) COLS(int 5) ///
		TITle(string)]

	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: GASTOS " in y `anio' "  }" in g _dup(20) "."

	* 1.1 Valor año mínimo *
	if `desde' == -1 {
		local desde = `anio'-9
	}

	* 1.2 Títulos y fuentes *
	if "`title'" == "" {
		local graphtitle "{bf:Gasto público}"
		local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/CPs/PEFs y $paqueteEconomico."
	}
	else {
		local graphtitle "`title'"
		local graphfuente ""
	}

	** 1.3 Base RAW **
	if "`base'" == "base" {
		use `if' using "`c(sysdir_site)'/04_master/PEF.dta", clear
		exit
	}

	** 1.4 Valor default `by' **
	if "`by'" == "" {
		local by = "divCIEP"
	}

	** 2.4 Etiquetas abreviadas **
	label define ramo 7 "SEDENA", modify
	label define ramo 19 "Aport a Seg Soc", modify
	label define ramo 33 "Aport federales", modify
	label define ramo 47 "No sectorizadas", modify
	label define ramo 50 "IMSS", modify
	label define ramo 51 "ISSSTE", modify
	label define ramo 52 "Pemex", modify
	label define ramo 53 "CFE", modify



	****************
	*** 2. DATOS ***
	****************

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

	** 2.3 Update PEF **
	if "`update'" == "update" {
		noisily UpdatePEF `update'
	}



	***************
	*** 3 Merge ***
	***************
	use "`c(sysdir_site)'/04_master/PEF.dta", clear

	** 3.1 Gasto total **
	egen double gastoTOT = sum(gasto) if transf_gf == 0, by(anio)

	** 3.2 Cuotas ISSSTE **
	g cuotasTOT = -gasto if ramo == -1
	egen double CuoTOT = sum(cuotasTOT), by(anio)

	** 3.3 Gasto neto **
	replace gastoTOT = gastoTOT + CuoTOT
	collapse (sum) gasto (max) gastoTOT CuoTOT `if', by(anio `by' transf_gf) fast
	sort anio `by'
	merge m:1 (anio) using "`PIB'", nogen keepus(pibY indiceY deflator lambda Poblacion) keep(matched) sorted
	forvalues k=1(1)`=_N' {
		if gasto[`k'] != . & "`first'" != "first" { 
			local aniofirst = 2014 //anio[`k']
			local first "first"
		}
	}
	local aniolast = anio[_N]

	** 3.4 Valores como % del PIB **
	foreach k of varlist gasto* {
		g double `k'PIB = `k'/pibY*100
	}
	g double gastoR = gasto/deflator
	format *PIB %10.3fc
	format gastoR gastoTOT CuoTOT %20.0fc



	******************
	*** 4 Resumido ***
	******************
	*keep if anio >= `desde'-1
	capture confirm string variable `by'
	if _rc != 0 {
		tempvar by2
		rename `by' `by2'
		decode `by2', g(resumido)
		decode `by2', g(`by')
	}
	else {
		g resumido = `by'
	}

	capture label copy `by' label
	if _rc != 0 {
		capture label copy num`by' label
	}
	capture label values resumido label

	tempvar gastoPIB
	egen `gastoPIB' = max(gastoPIB), by(`by')
	replace resumido = `"_menor_a_`minimum'_PIB"' if abs(`gastoPIB') < `minimum' & lower(resumido) != "cuotas issste"
	*replace resumido = `"< `=string(`minimum',"%5.1fc")'% PIB"' if abs(`gastoPIB') < `minimum' & resumido != "Cuotas ISSSTE"


	********************
	** 5. Display PEF **
	
	** 5.1 Division `by' **
	noisily di _newline in g "{bf: A. Gasto bruto (`by') " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "% Total" "}"

	capture tabstat gasto gastoPIB if anio == `anio' & lower(`by') != "cuotas issste", by(`by') stat(sum) f(%20.0fc) save
	if _rc != 0 {
		noisily di in g "No hay informaci{c o'}n para el a{c n~}o `anio'."
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		* Display text *
		if substr(`"`=r(name`k')'"',1,35) == `"'"' {
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
	capture tabstat gasto gastoPIB if anio == `anio' & transf_gf == 1, stat(sum) f(%20.0fc) save by(`by')
	tempname Aportaciones_Federacion
	if _rc == 0 {
		matrix `Aportaciones_Federacion' = r(StatTotal)
	}
	else {
		matrix `Aportaciones_Federacion' = J(1,2,0)
	}
	return scalar Aportaciones_a_Seguridad_Social = `Aportaciones_Federacion'[1,1]
	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname tgf`k'
		matrix `tgf`k'' = r(Stat`k')
		
		if `tgf`k''[1,1] == . {
			matrix `tgf`k'' = J(1,1,0)
		}

		* Display text *
		local disptext = r(name`k')
		local disptext = subinstr(`"`disptext'"',"á","a",.)
		local disptext = subinstr(`"`disptext'"',"é","e",.)
		local disptext = subinstr(`"`disptext'"',"í","i",.)
		local disptext = subinstr(`"`disptext'"',"ó","o",.)
		local disptext = subinstr(`"`disptext'"',"ú","u",.)
		local disptext = subinstr(`"`disptext'"',"ñ","n",.)
		local disptext = subinstr(`"`disptext'"',"ü","u",.)
		local disptext = ustrregexra(`"`disptext'"',`"[^a-zA-Z0-9 ]"',"")
		local name = strtoname(`"`disptext'"')

		* Display *
		return scalar `name' = `tgf`k''[1,1]
		local ++k
	}

	capture tabstat gasto gastoPIB if lower(`by') == "cuotas issste" & anio == `anio', stat(sum) f(%20.0fc) save
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


	****************************
	** 4.2. Division Resumido **
	noisily di _newline in g "{bf: B. Gasto bruto (Resumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "Dif% Real" "}"

	replace gasto = -gasto if lower(resumido) == "cuotas issste"
	replace gastoR = -gastoR if lower(resumido) == "cuotas issste"
	replace gastoPIB = -gastoPIB if lower(resumido) == "cuotas issste"
	
	replace gasto = 0 if gasto == .
	replace gastoR = 0 if gastoR == .
	replace gastoPIB = 0 if gastoPIB == .

	rename resumido resumido2
	replace resumido2 = strtoname(resumido2)
	replace resumido2 = substr(resumido2,1,24)
	collapse (sum) gasto gastoPIB gastoR (max) pibY deflator lambda Poblacion if transf_gf == 0, by(anio resumido2)
	reshape wide gasto*, i(anio) j(resumido2) string
	reshape long
	replace resumido2 = subinstr(resumido2,"_"," ",.)
	encode resumido2, g(resumido)
	
	capture tabstat gastoR if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save missing
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

	capture tabstat gasto gastoPIB if anio == `anio', by(resumido) stat(sum) f(%20.1fc) save missing
	tempname mattot
	if _rc == 0 {
		matrix `mattot' = r(StatTotal)
	}
	else {
		matrix `mattot' = J(1,1,0)
	}

	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		
		if `mat`k''[1,1] == . {
			matrix `mat`k'' = J(1,1,0)
		}

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
		local disptext = r(name`k')
		local disptext = subinstr(`"`disptext'"',"á","a",.)
		local disptext = subinstr(`"`disptext'"',"é","e",.)
		local disptext = subinstr(`"`disptext'"',"í","i",.)
		local disptext = subinstr(`"`disptext'"',"ó","o",.)
		local disptext = subinstr(`"`disptext'"',"ú","u",.)
		local disptext = subinstr(`"`disptext'"',"ñ","n",.)
		local disptext = subinstr(`"`disptext'"',"ü","u",.)
		local disptext = ustrregexra(`"`disptext'"',`"[^a-zA-Z0-9 ]"',"")
		local name = strtoname(`"`disptext'"')

		* Display *
		return scalar `name' = `mat`k''[1,1]
		return scalar `name'PIB = `mat`k''[1,2]
		return scalar `name'C = (abs(`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`aniovp'-`desde''))-1)*100
		local divResumido `"`divResumido' `name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(44) in y %20.0fc `mat`k''[1,1] ///
			_col(66) in y %7.3fc `mat`k''[1,2] ///
			_col(77) in y %7.1fc (abs(`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`aniovp'-`desde''))-1)*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(83) "-"
	noisily di in g "{bf:  (=) Gasto neto" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.3fc `mattot'[1,2] ///
		_col(77) in y %7.1fc ((`mattot'[1,1]/`pregastot'[1,1])^(1/(`=`aniovp'-`desde''))-1)*100 "}"
	
	return scalar Gasto_neto = `mattot'[1,1]
	return scalar Gasto_netoPIB = `mattot'[1,2]
	return scalar Gasto_netoC = ((`mattot'[1,1]/`pregastot'[1,1])^(1/(`=`aniovp'-`desde''))-1)*100

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

			* Display text *
			local disptext = r(name`k')
			local disptext = subinstr(`"`disptext'"',"á","a",.)
			local disptext = subinstr(`"`disptext'"',"é","e",.)
			local disptext = subinstr(`"`disptext'"',"í","i",.)
			local disptext = subinstr(`"`disptext'"',"ó","o",.)
			local disptext = subinstr(`"`disptext'"',"ú","u",.)
			local disptext = subinstr(`"`disptext'"',"ñ","n",.)
			local disptext = subinstr(`"`disptext'"',"ü","u",.)
			local disptext = ustrregexra(`"`disptext'"',`"[^a-zA-Z0-9 ]"',"")
			local name = strtoname(`"`disptext'"')
			
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


	*******************
	*** 5. Gráficos ***
	*******************
	if "`nographs'" != "nographs" & "$nographs" == "" {
		*preserve

		* Normalizar valores a billones *
		*replace gasto=gasto/deflator/1000000000000
		*replace monto=monto/deflator/1000000000000

		collapse (sum) gasto gastoR gastoPIB (max) pibY deflator if anio >= `desde', by(anio resumido)
		levelsof resumido, local(lev_resumido)

		foreach k of local lev_resumido {
			local legend`k' : label resumido `k'
			if "`legend`k''" == "Cuotas ISSSTE" | "`legend`k''" == "cuotas issste" {
				replace resumido = -1 if resumido == `k'
				label define resumido -1 "Cuotas ISSSTE", add
				*label define resumido 1 `"< `=string(`minimum',"%5.1fc")'% PIB"', modify
			}
		}
		
		* Ciclo para poner los paréntesis (% del total) en el legend *
		tabstat gastoPIB if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		levelsof resumido if resumido != -1, local(lev_resumido)
		local totlev = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')

			local legend`k' : label resumido `k'
			local legend`k' = substr("`legend`k''",1,20)
			local legend = `"`legend' label(`totlev' "{bf:`legend`k''}")"'  
			//"(`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)"
			
			tempvar gastoPIB`k' connectedPIB`k' connectedTOT`k'
			egen `gastoPIB`k'' = sum(gastoPIB) if resumido >= `k', by(anio)
			replace `gastoPIB`k'' = 0 if `gastoPIB`k'' == .
			label var `gastoPIB`k'' "`legend`k''"

			egen `connectedTOT`k'' = sum(gastoR), by(anio)
			g `connectedPIB`k'' = gastoR/`connectedTOT`k''*100 if resumido == `k'
			format `gastoPIB`k'' `connectedPIB`k'' %7.1fc

			local extras = `"`extras' (bar `gastoPIB`k'' anio if anio <= `anio' & resumido == `k', mlabpos(6) mlabcolor("111 111 111") barwidth(.8)) "'
		}
		*local legend `"`legend' label(`=`totlev'+1' "Gasto total")"'
		
		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -gasto
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
				*local order "`order' `=`ordervar'[`k']'"
			}
		}
		sort anio resumido

		tempvar gastobar gastoline gastoby
		g `gastobar' = gastoR
		replace `gastobar' = 0 if `gastobar' == .

		egen `gastoby' = sum(gasto), by(anio)
		g `gastoline' = `gastoby'/(pibY)*100
		format gasto* `gastobar' `gastoline' `gastoby' %15.1fc
		label var `gastoline' "Como % del PIB"

		* Información agregada *
		egen gastoPIBTOT = sum(gastoPIB), by(anio)
		format gastoPIBTOT %7.1fc


		***********
		** Texto **
		* Máximo *
		tabstat gastoPIBTOT `gastoline', stat(max) by(anio) save
		tempname maxPIBTOT
		matrix `maxPIBTOT' = r(StatTotal)

		* Inicial *
		tempname iniPIBTOT
		capture tabstat gastoPIBTOT if anio == `desde', stat(max) save by(anio)
		if _rc == 0 {
			matrix `iniPIBTOT' = r(StatTotal)
		}
		else {
			matrix `iniPIBTOT' = J(1,1,0)
		}

		* Final *
		tabstat gastoPIBTOT if anio == `anio', stat(max) save by(anio)
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
			(connected `gastoline' anio if resumido == resumido[1], mlabpos(12) mlabcolor("111 111 111") mlabel(`gastoline') yaxis(2) mlabsize(large)) ///
			///(scatter gastoPIBTOT anio if resumido == resumido[1], mlabpos(12) mlabcolor("111 111 111") mlabel(gastoPIBTOT) mlabsize(large) mcolor(white) lcolor(white)) ///
			if anio <= `anio', ///
			///over(resumido, sort(1) descending) over(anio, gap(30)) ///
			///stack asyvars blabel(bar, format(%7.1fc)) outergap(0) ///
			name(gastos`by'PIB, replace) ///
			title("`graphtitle'") ///
			yscale(range(0 `=`maxPIBTOT'[1,1]*1.75')) ///
			yscale(range(-50 `=`maxPIBTOT'[1,2]*1.1') axis(2) noline) ///
			ylabel(, format(%7.1fc) labsize(small)) ///
			ylabel(none, axis(2)) ///
			xlabel(`desde'(1)`anio') ///
			xtitle("") ///
			ytitle("billones de `currency' `anio'") ///
			ytitle("", axis(2)) ///
			///subtitle("Gasto, como % del PIB") ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' order(`order') justification(left)) ///
			/// Added text 
			///text(`=gastoPIBTOT[1]' `=anio[1]' "{bf:% PIB}", placement(6)) ///
			///text(`=`gastoline'[1]' `=anio[1]' "{bf:% PEF}", placement(6) yaxis(2)) ///
			///b1title("De `desde' a `anio', el {bf:gasto `cambio' `=string(abs(`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]),"%7.1fc")'} puntos porcentuales del PIB.")

		/*grc1leg ///
		///graph combine ///
		ingresos`by'PIB ingresosMXN`by' , ///
			title("{bf:`graphtitle'}") ///
			caption("Fuente: Elaborado por el CIEP, con informaci{c o'}n de SHCP/EOFP, INEGI/BIE y $paqueteEconomico.") ///
			name(ingresos`by', replace) xcommon */

		*capture window manage close graph ingresosMXN`by'
		*capture window manage close graph ingresos`by'PIB
	
		graph save gastos`by'PIB "`c(sysdir_site)'/05_graphs/gastos`by'PIB", replace
		if "$export" != "" {
			graph export "$export/gastos`by'PIB.png", as(png) name("gastos`by'PIB") replace
		}
		*restore
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





*************************
****                 ****
**** UpdatePEF.do    ****
**** De .xlsx a .dta ****
****                 ****
*************************
program define UpdatePEF

	*************************
	*** 1. BASES DE DATOS ***
	*************************
	capture confirm file "`c(sysdir_site)'/03_temp/prePEF.dta"
	if _rc == 0 {
		local archivos: dir "`c(sysdir_site)'/01_raw/PEFs" files "*.xlsx"		// Archivos .xlsx
		*local archivos `""PEF 2025.xlsx" "CuotasISSSTE.xlsx""'
		*local archivos `""CP 2013.xlsx" "CuotasISSSTE.xlsx""'

		foreach k of local archivos {

			* 1.1 Importar el archivo `k'.xlsx (Cuenta Pública) *
			noisily di in g "Importando: " in y "`k'"
			tokenize `k'
			import excel "`c(sysdir_site)'/01_raw/PEFs/`k'", clear firstrow case(lower) allstring sheet(`=substr("`2'",1,4)')
			capture drop v*

			* 1.2 Limpiar observaciones *
			capture drop if ciclo == ""
			capture rename ciclo anio

			* 1.3 Limpiar nombres *
			foreach j of varlist _all {
				if strlen("`j'") == 2 {
					drop `j'
				}
			}
			foreach j of varlist _all {
				if `"`=substr("`j'",1,3)'"' == "id_" {
					local newname = `"`=substr("`j'",4,.)'"'
					capture rename `j' `newname'
					if _rc != 0 {
						rename `newname' desc_`newname'
						rename `j' `newname'				
					}
					local j = "`newname'"
				}
				if `"`=substr("`j'",1,6)'"' == "monto_" {
					local newname = `"`=substr("`j'",7,.)'"'
					rename `j' `newname'	
					local j = "`newname'"
				}
				if "`j'" == "objeto_del_gasto" | "`j'" == "partida_especifica" {
					rename `j' objeto
					local j = "objeto"
				}
				if "`j'" == "desc_objeto_del_gasto" | "`j'" == "desc_partida_especifica" {
					rename `j' desc_objeto
					local j = "desc_objeto"
				}
				if "`j'" == "desc_gpo_funcional" {
					rename `j' desc_finalidad
					local j = "desc_finalidad"
				}
				if "`j'" == "gpo_funcional" {
					rename `j' finalidad
					local j = "finalidad"
				}
				if "`j'" == "ff" {
					rename `j' fuente
					local j = "fuente"
				}
				if "`j'" == "desc_ff" {
					rename `j' desc_fuente
					local j = "desc_fuente"
				}
				if "`j'" == "desc_entidad_federativa" {
					rename `j' desc_entidad
					local j = "desc_entidad"
				}
				if "`j'" == "entidad_federativa" {
					capture rename `j' entidad
				}
				capture rename ejercicio ejercido
			}

			* 1.4 Limpiar valores *
			// Primero, asegurar que las variables de gasto sean numéricas. 
			foreach j in aprobado modificado devengado pagado adefas ejercido proyecto {
				capture destring `j', replace ignore(",")
				if _rc == 0 {
					format `j' %20.0fc
					replace `j' = 0 if `j' == .
				}
			}

			// Segundo, limpiar
			foreach j of varlist _all {
				if "`j'" != "ejercido" & "`j'" != "aprobado" & "`j'" != "proyecto" ///
					& "`j'" != "modificado" & "`j'" != "devengado" & "`j'" != "pagado" ///
					& "`j'" != "adefas" & "`j'" != "ramo" {	
					noisily di "`j'"
					replace `j' = trim(`j')
					replace `j' = lower(`j')
					replace `j' = subinstr(`j',`"""',"",.)
					replace `j' = subinstr(`j',"  "," ",.)
					replace `j' = subinstr(`j',"Ê"," ",.)	// <--Algunas CPs tienen este caracter "raro".
					replace `j' = subinstr(`j',"Â","",.) 	// <--Algunas CPs tienen este caracter "raro".
					replace `j' = subinstr(`j'," "," ",.)
					format `j' %30s
				}
				destring `j', replace				// Tercero, hacer numéricas las variables posibles
			}
			capture tostring ramo, replace

			* 1.5 Save *
			tempfile `=strtoname("`k'")'				// strtoname convierte el texto en Stata var_type_name
			save ``=strtoname("`k'")''
		}

		* Cuarto, loop para unir los archivos ya limpios y en formato Stata *
		local j = 0
		foreach k of local archivos {
		*foreach k in "CP 2019" {					// <-- Dejar para hacer pruebas
			noisily di in g "Appending: " in y "`k'"
			if `j' == 0 {
				use ``=strtoname("`k'")'', clear
				local ++j
			}
			else {
				append using ``=strtoname("`k'")''
			}
		}


		***********************************
		***                             ***
		*** 2. HOMOLOGACION DE TÉRMINOS ***
		***                             ***
		***********************************

		** 2.1 Finalidad **
		replace desc_finalidad = "Otras" if finalidad == 4
		capture labmask finalidad, values(desc_finalidad)
		if _rc == 199 {
			net install labutil.pkg
			labmask finalidad, values(desc_finalidad)
		}
		drop desc_finalidad

		** 2.2 Ramo **
		replace ramo = "50" if ramo == "GYR"
		replace ramo = "51" if ramo == "GYN"
		replace ramo = "52" if ramo == "TZZ" | ur == "TZZ"
		replace ramo = "53" if ramo == "TOQ" | ur == "TOQ"
		destring ramo, replace

		replace desc_ramo = "Oficina de la Presidencia de la República" if ramo == 2
		replace desc_ramo = "Agricultura y Desarrollo Rural" if ramo == 8
		replace desc_ramo = "Infraestructura, Comunicaciones y Transportes" if ramo == 9
		replace desc_ramo = "Desarrollo Agrario, Territorial y Urbano" if ramo == 15
		replace desc_ramo = "Bienestar" if ramo == 20
		replace desc_ramo = "Instituto Nacional Electoral" if ramo == 22
		replace desc_ramo = "Anticorrupción y Buen Gobierno" if ramo == 27
		replace desc_ramo = "Tribunal Federal de Justicia Administrativa" if ramo == 32
		replace desc_ramo = "Seguridad y Protección Ciudadana" if ramo == 36
		replace desc_ramo = "Humanidades, Ciencias, Tecnologías e Innovación" if ramo == 38
		replace desc_ramo = "Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales" if ramo == 44
		replace desc_ramo = "Petróleos Mexicanos" if ramo == 52
		replace desc_ramo = "Comisión Federal de Electricidad" if ramo == 53
		replace desc_ramo = lower(desc_ramo)

		labmask ramo, values(desc_ramo)
		drop desc_ramo

		** 2.3 Descripción Entidad Federativa **
		capture replace desc_entidad = trim(desc_entidad)
		if _rc != 0 {
			g desc_entidad = ""
			g entidad = .
		}
		replace entidad = 34 if entidad == .
		replace desc_entidad = "Aguascalientes" if entidad == 1
		replace desc_entidad = "Baja California" if entidad == 2
		replace desc_entidad = "Baja California Sur" if entidad == 3
		replace desc_entidad = "Campeche" if entidad == 4
		replace desc_entidad = "Coahuila" if entidad == 5
		replace desc_entidad = "Colima" if entidad == 6
		replace desc_entidad = "Chiapas" if entidad == 7
		replace desc_entidad = "Chihuahua" if entidad == 8
		replace desc_entidad = "Ciudad de México" if entidad == 9
		replace desc_entidad = "Durango" if entidad == 10
		replace desc_entidad = "Guanajuato" if entidad == 11
		replace desc_entidad = "Guerrero" if entidad == 12
		replace desc_entidad = "Hidalgo" if entidad == 13
		replace desc_entidad = "Jalisco" if entidad == 14
		replace desc_entidad = "Estado de México" if entidad == 15
		replace desc_entidad = "Michoacán" if entidad == 16
		replace desc_entidad = "Morelos" if entidad == 17
		replace desc_entidad = "Nayarit" if entidad == 18
		replace desc_entidad = "Nuevo León" if entidad == 19
		replace desc_entidad = "Oaxaca" if entidad == 20
		replace desc_entidad = "Puebla" if entidad == 21
		replace desc_entidad = "Querétaro" if entidad == 22
		replace desc_entidad = "Quintana Roo" if entidad == 23
		replace desc_entidad = "San Luis Potosí" if entidad == 24
		replace desc_entidad = "Sinaloa" if entidad == 25
		replace desc_entidad = "Sonora" if entidad == 26
		replace desc_entidad = "Tabasco" if entidad == 27
		replace desc_entidad = "Tamaulipas" if entidad == 28
		replace desc_entidad = "Tlaxcala" if entidad == 29
		replace desc_entidad = "Veracruz" if entidad == 30
		replace desc_entidad = "Yucatán" if entidad == 31
		replace desc_entidad = "Zacatecas" if entidad == 32
		replace desc_entidad = "En El Extranjero" if entidad == 33
		replace desc_entidad = "No Distribuible Geográficamente" if entidad == 34
		labmask entidad, values(desc_entidad)
		drop desc_entidad

		** 2.4 Capítulo de gasto **
		capture drop capitulo
		g capitulo = substr(string(objeto),1,1) if objeto != -1
		destring capitulo, replace
		replace capitulo = -1 if ramo == -1

		label define capitulo 1 "Servicios personales" 2 "Materiales y suministros" ///
			3 "Gastos generales" 4 "Subsidios y transferencias" ///
			5 "Bienes muebles e inmuebles" 6 "Obras públicas" 7 "Inversión financiera" ///
			8 "Participaciones y aportaciones" 9 "Deuda pública" -1 "Cuotas ISSSTE"
		label values capitulo capitulo

		** 2.5 Tipo de ramo **
		g ramo_tipo = .
		replace ramo_tipo = -1 if ramo == -1
		replace ramo_tipo = 1 if ramo == 1 | ramo == 3 | ramo == 22 | ramo == 32 | ramo == 35 ///
			| ramo == 40 | ramo == 41 | ramo == 42 | ramo == 43 | ramo == 44
		replace ramo_tipo = 2 if ramo == 19 | ramo == 23 | ramo == 25  | ramo == 33
		replace ramo_tipo = 3 if ramo == 50 | ramo == 51
		replace ramo_tipo = 4 if (ramo == 52 | ramo == 53) & capitulo != 9
		replace ramo_tipo = 5 if ramo == 2 | ramo == 4 | ramo == 5 | ramo == 6  | ramo == 7  ///
			| ramo == 8  | ramo == 9 | ramo == 10 | ramo == 11  | ramo == 12  | ramo == 13  ///
			| ramo == 14 | ramo == 15 | ramo == 16  | ramo == 17  | ramo == 18  | ramo == 20 ///
			| ramo == 21 | ramo == 27  | ramo == 31  | ramo == 36  | ramo == 37 | ramo == 38 ///
			| ramo == 45  | ramo == 46 | ramo == 47  | ramo == 48
		replace ramo_tipo = 6 if ramo == 24 | ramo == 28 | ramo == 30 | ramo == 34 
		replace ramo_tipo = 7 if (ramo == 52 | ramo == 53) & (capitulo == 9)

		label define tipos_ramo -1 "Cuotas al ISSSTE" 1 "Ramos autónomos" 2 "Ramos generales programables" ///
			3 "Entidades de control directo" 4 "Empresas Productivas del Estado" ///
			5 "Ramos administrativos" 7 "Gasto no programable de las empresas productivas del estado" ///
			6 "Gasto no programable del gobierno federal"
		label values ramo_tipo tipos_ramo

		** 2.6 Encode y agregar Cuotas ISSSTE **
		foreach k of varlist desc_* {

			if "`k'" == "desc_pp" {
				continue
			}
		
			rename `k' `k'2
			encode `k'2, g(`k')
			drop `k'2	

			//replace `k' = -1 if `k' == .
			label define `k' -1 "Cuotas ISSSTE", add
		}


		*********************************
		***                           ***
		*** 3. ESTADÍSTICAS OPORTUNAS ***
		***                           ***
		*********************************

		** 3.1 Función **
		g serie_desc_funcion = "XKG0116" if desc_funcion == -1
		replace serie_desc_funcion = "XAC23" if desc_funcion == 1
		replace serie_desc_funcion = "XOA0424" if desc_funcion == 2
		replace serie_desc_funcion = "XOA0423" if desc_funcion == 3
		replace serie_desc_funcion = "XOA0410" if desc_funcion == 4
		replace serie_desc_funcion = "XOA0412" if desc_funcion == 5
		replace serie_desc_funcion = "XOA0430" if desc_funcion == 6
		replace serie_desc_funcion = "XOA0425" if desc_funcion == 7
		replace serie_desc_funcion = "XOA0428" if desc_funcion == 8
		replace serie_desc_funcion = "XOA0408" if desc_funcion == 9
		replace serie_desc_funcion = "XOA0419" if desc_funcion == 10
		replace serie_desc_funcion = "XOA0407" if desc_funcion == 11
		replace serie_desc_funcion = "XOA0402" if desc_funcion == 12
		replace serie_desc_funcion = "XOA0426" if desc_funcion == 13
		replace serie_desc_funcion = "XOA0431" if desc_funcion == 14
		replace serie_desc_funcion = "XOA0421" if desc_funcion == 15
		replace serie_desc_funcion = "XOA0413" if desc_funcion == 16
		replace serie_desc_funcion = "XOA0415" if desc_funcion == 17
		replace serie_desc_funcion = "XOA0420" if desc_funcion == 18
		replace serie_desc_funcion = "XOA0418" if desc_funcion == 19
		replace serie_desc_funcion = "XOA0409" if desc_funcion == 20
		replace serie_desc_funcion = "XOA0417" if desc_funcion == 21
		replace serie_desc_funcion = "XAC2120" if desc_funcion == 22
		replace serie_desc_funcion = "XOA0411" if desc_funcion == 23
		replace serie_desc_funcion = "XAC21" if desc_funcion == 24
		replace serie_desc_funcion = "XAC2800" if desc_funcion == 25
		replace serie_desc_funcion = "XOA0427" if desc_funcion == 26
		replace serie_desc_funcion = "XOA0429" if desc_funcion == 27
		replace serie_desc_funcion = "XOA0416" if desc_funcion == 28

		** 3.2 Ramo **
		g serie_ramo = "XKG0116" if ramo == -1
		replace serie_ramo = "XDB54" if ramo ==1
		replace serie_ramo = "XAC4210" if ramo == 2
		replace serie_ramo = "XDB55" if ramo == 3
		replace serie_ramo = "XAC4220" if ramo == 4
		replace serie_ramo = "XAC4230" if ramo == 5
		replace serie_ramo = "XAC4240" if ramo == 6
		replace serie_ramo = "XAC4250" if ramo == 7
		replace serie_ramo = "XAC4260" if ramo == 8
		replace serie_ramo = "XAC4270" if ramo == 9
		replace serie_ramo = "XAC4280" if ramo == 10
		replace serie_ramo = "XAC4290" if ramo == 11
		replace serie_ramo = "XAC4211" if ramo == 12
		replace serie_ramo = "XAC4212" if ramo == 13
		replace serie_ramo = "XAC4213" if ramo == 14
		replace serie_ramo = "XAC4214" if ramo == 15
		replace serie_ramo = "XAC4215" if ramo == 16
		replace serie_ramo = "XAC4216" if ramo == 17
		replace serie_ramo = "XAC4217" if ramo == 18
		replace serie_ramo = "XAC4218" if ramo == 19
		replace serie_ramo = "XAC4219" if ramo == 20
		replace serie_ramo = "XAC4310" if ramo == 21
		replace serie_ramo = "XDB56" if ramo == 22
		replace serie_ramo = "XAC4320" if ramo == 23
		replace serie_ramo = "XAC21" if ramo == 24
		replace serie_ramo = "XAC4330" if ramo == 25
		replace serie_ramo = "XAC4350" if ramo == 27
		replace serie_ramo = "XAC22" if ramo == 28
		replace serie_ramo = "XAC23" if ramo == 30
		replace serie_ramo = "XAC4370" if ramo == 31
		replace serie_ramo = "XAC4380" if ramo == 32
		replace serie_ramo = "XAC4390" if ramo == 33
		replace serie_ramo = "XAC2120" if ramo == 34
		replace serie_ramo = "XDB57" if ramo == 35
		replace serie_ramo = "XAC44" if ramo == 36
		replace serie_ramo = "XAC4410" if ramo == 37
		replace serie_ramo = "XAC4420" if ramo == 38
		replace serie_ramo = "XDB40" if ramo == 40
		replace serie_ramo = "XDB51" if ramo == 41
		replace serie_ramo = "XDB52" if ramo == 42
		replace serie_ramo = "XDB53" if ramo == 43
		replace serie_ramo = "XDB58" if ramo == 44
		replace serie_ramo = "XOA0832" if ramo == 45 | (ur == "C00" & ramo == 18)
		replace serie_ramo = "XOA0833" if ramo == 46 | (ur == "D00" & ramo == 18)
		replace serie_ramo = "XOA1013" if ramo == 47
		replace serie_ramo = "XOA1019" if ramo == 48
		replace serie_ramo = "XOA0145" if ramo == 50
		replace serie_ramo = "XOA0146" if ramo == 51
		replace serie_ramo = "XKC0131" if ramo == 52
		replace serie_ramo = "XOA0141" if ramo == 53

		compress
		if `c(version)' > 13.1 {
			saveold "`c(sysdir_site)'/03_temp/prePEF.dta", replace version(13)
		}
		else {
			save "`c(sysdir_site)'/03_temp/prePEF.dta", replace
		}
	}

	/* 3.3 Datos Abiertos: PEFEstOpor.dta *
	levelsof serie_desc_funcion, local(serie)
	foreach k of local serie {
		noisily DatosAbiertos `k', nog

		rename clave_de_concepto serie
		keep anio serie nombre monto mes acum_prom

		tempfile `k'
		quietly save ``k''
	}

	** 2.1.1 Append **
	local j = 0
	foreach k of local serie {
		if `j' == 0 {
			use ``k'', clear
			local ++j
		}
		else {
			append using ``k''
		}
	}

	rename serie series
	encode series, generate(serie)
	drop series

	capture drop __*
	compress
	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/GastoEstOpor.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/GastoEstOpor.dta", replace
	}*/

	***************************************/
	***                                  ***
	*** 4. Modulos SIMULADOR FISCAL CIEP ***
	***                                  ***
	****************************************
	use "`c(sysdir_site)'/03_temp/prePEF.dta", clear
	replace desc_funcion = -1 if ramo == -1


	*******************
	** 4.1 Pensiones **
	// Pensiones contributivas
	g divCIEP = "Pensiones" if (substr(string(objeto),1,2) == "45" | substr(string(objeto),1,2) == "47")
	g divSIM = "Pensiones" if divCIEP == "Pensiones"

	// Pensión para adultos mayores
	replace divCIEP = "Pensión AM" if divCIEP == "" ///
		& (desc_pp == "pensión para adultos mayores" ///
		| desc_pp == "pensión para el bienestar de las personas adultas mayores" ///
		| desc_pp == "pensión para el bienestar de las personas con discapacidad permanente")
	replace divSIM = "Pensiones" if divCIEP == "Pensión AM"


	***************
	** 4.2 Salud **
	replace divCIEP = "Salud" if divCIEP == "" ///
		& (desc_funcion == 21 | ramo == 12)
	replace divCIEP = "Salud" if divCIEP == "" ///
		& (ramo == 50 | ramo == 51) & (pp == 4 | pp == 15) & funcion == 8
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ramo == 52 & ai == 231
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ramo == 47 & ur == "ayo"
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ramo == 20 & pp == 317

	replace divSIM = "Salud" if divCIEP == "Salud"


	*****************
	** 4.3 Energía **
	replace divCIEP = "Energía" if divCIEP == "" ///
		& (ramo == 18 | ramo == 45 | ramo == 46 | ramo == 52 | ramo == 53 ///
		| (ramo == 23 & desc_funcion == 7))

	replace divSIM = "Energía" if divCIEP == "Energía"


	***************************
	** 4.4 Costo de la deuda **
	replace divCIEP = "Costo de la deuda" if divCIEP == "" ///
		& capitulo == 9

	replace divSIM = "Costo de la deuda" ///
		if capitulo == 9


	*******************
	** 4.5 Educación **
	replace divCIEP = "Educación" if divCIEP == "" ///
		& (desc_funcion == 10 | ramo == 11 | ramo == 48 | ramo == 38)

	replace divSIM = "Educación" if divCIEP == "Educación"


	*************************************
	** 4.6 Inversión e Infraestructura **
	replace divCIEP = "Otras inversiones" if divCIEP == "" ///
		& (desc_tipogasto == 4 | desc_tipogasto == 5 | desc_tipogasto == 6 | desc_tipogasto == 7 | desc_tipogasto == 8)

	replace divSIM = "Inversión" ///
		if (desc_tipogasto == 4 | desc_tipogasto == 5 | desc_tipogasto == 6 | desc_tipogasto == 7 | desc_tipogasto == 8)


	**********************
	** 4.7 Federalizado **
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (ramo == 28)                                        // Part
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (ramo == 33 | ramo == 25)                           // Aport
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (objeto == 43801)                                   // Convenios descentralizados
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (objeto == 85101)                                   // Convenios de reasignación
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (objeto == 43101 & ramo == 8 & pp == 263 & entidad != 34) // Convenios de reasignación
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (objeto == 46101 & ramo == 23 & pp == 80)           // FEIEF
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (ramo == 23 & pp == 4 & modalidad == "Y")           // FEIEF
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (ramo == 23 & pp == 141)                            // FIES
	replace divCIEP = "Part y otras Apor" if divCIEP == "" ///
		& (pp == 13 & (ramo == 12 | ramo == 47) & modalidad == "U") // INSABI/Seguro Popular/IMSS-Bienestar

	g divFEDE = "Participaciones" if (ramo == 28) // Part
	replace divFEDE = "Aportaciones" if (ramo == 33 | ramo == 25)    // Aport
	replace divFEDE = "Convenios" if (objeto == 43801 & ramo != 23)  // Convenios descentralizados
	replace divFEDE = "Convenios" if (objeto == 85101)               // Convenios de reasignación
	replace divFEDE = "Convenios" if (objeto == 43101 & ramo == 8 & pp == 263 & entidad != 34) // Convenios de reasignación
	replace divFEDE = "Subsidios" if (objeto == 46101 & ramo == 23 & pp == 80) // FEIEF
	replace divFEDE = "Subsidios" if (ramo == 23 & pp == 4 & modalidad == "Y") // FEIEF
	replace divFEDE = "Subsidios" if (ramo == 23 & pp == 141) // FIES
	replace divFEDE = "Subsidios" if (ramo == 23 & objeto == 43801)
	replace divFEDE = "Salud (federalizado)" if (pp == 13 & (ramo == 12 | ramo == 47) & modalidad == "U") // INSABI/Seguro Popular/IMSS-Bienestar


	**********************************
	** 4.8 Economía de los cuidados **
	replace divSIM = "Cuidados" if divSIM == "" & (ramo == 11 & pp == 312) | (ramo == 11 & pp == 31) ///
		| (ramo == 11 & pp == 66) ///
		| (ramo == 20 & pp == 174) | (ramo == 51 & pp == 48) | (ramo == 50 & pp == 7) ///
		| (ramo == 20 & pp == 241) ///
		| (ramo == 12 & pp == 41) | (ramo == 20 & pp == 3 & ur == "V3A") | (ramo == 33 & pp == 6) ///
		| (ramo == 4 & pp == 12  & ur == "V00") | (ramo == 51 & pp == 42) | (ramo == 12 & pp == 39) ///
		| (ramo == 12 & pp == 40) | (ramo == 11 & pp == 221) | (ramo == 25 & pp == 221) ///
		| (ramo == 51 & subfuncion == 3 & anio <= 2019) | (ramo == 20 & pp == 12 & anio >= 2019 & anio <= 2022)


	***************
	** 4.9 Otros **
	replace divCIEP = "Otros gastos" if divCIEP == ""
	replace divFEDE = "No federalizado" if divFEDE == ""
	replace divSIM = divCIEP if divSIM == ""


	************************
	** 4.10 Cuotas ISSSTE **
	foreach k in divCIEP divFEDE divSIM {
		replace `k' = "Cuotas ISSSTE" if ramo == -1
	}



	**************************
	***                    ***
	*** 5. NETEO DEL GASTO ***
	***                    ***
	**************************
	replace ejercido = . if ramo == -1 & ejercido == 0
	replace aprobado = . if ramo == -1 & aprobado == 0
	replace proyecto = . if ramo == -1 & proyecto == 0

	g double gasto = ejercido if ejercido != .
	replace gasto = aprobado if ejercido == . & aprobado != .
	replace gasto = proyecto if ejercido == . & aprobado == . & proyecto != .

	g byte transf_gf = (ramo == 19 & ur == "gyn") | (ramo == 19 & ur == "gyr")

	g byte noprogramable = ramo == 28 | capitulo == 9
	replace noprogramable = -1 if ramo == -1
	label define noprogramable 1 "No programable" 0 "Programable" -1 "Cuotas ISSSTE"
	label values noprogramable noprogramable



	****************/
	***           ***
	*** 6. SAVING ***
	***           ***
	*****************
	format gasto ejercido aprobado %20.0fc
	capture order ejercido, last
	capture order aprobado modificado devengado pagado, last
	capture order proyecto, last
	capture drop __*
	compress
	if `c(version)' > 13.1 {
		saveold "`c(sysdir_site)'/04_master/PEF.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/04_master/PEF.dta", replace
	}
end
