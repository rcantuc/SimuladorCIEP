*! version 8.1 CIEP 19jul2026
program define PEF, return
	capture mkdir `"`c(sysdir_site)'/users/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/graphs/"'
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
	capture confirm file "`c(sysdir_site)'/master/PEF.dta"
	if _rc != 0 {
		noisily UpdatePEF
	}



	****************
	*** 1 SYNTAX ***
	****************
	use in 1 using "`c(sysdir_site)'/master/PEF.dta", clear
	syntax [if] [, ANIO(int `aniovp') BY(varname) ///
		UPDATE NOGraphs Base ///
		MINimum(real 1) DESDE(int -1) ///
		ROWS(int 1) COLS(int 5) ///
		HIGHlight(int 0) ///
		TITle(string)]

	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: GASTOS " in y `anio' "  }" in g _dup(20) "."

	* 1.1 Valor año mínimo *
	* desde() debe ser < anio() (mismo guard que LIF, 2026-09-12): con desde >= anio
	* la tabla B dividiria entre nyears = 0 y las graficas perderian el anio. *
	if `desde' == -1 | `desde' >= `anio' {
		local desde = `anio'-9
	}

	* 1.2 Títulos y fuentes *
	if "`title'" == "" {
		local graphtitle "{bf:Gasto público}"
		local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/CPs/PEFs y $paqueteEconomico."
	}
	else {
		local graphtitle "{bf:`title'}"
		local graphfuente ""
	}

	** 1.3 Base RAW **
	if "`base'" == "base" {
		use `if' using "`c(sysdir_site)'/master/PEF.dta", clear
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
	PIBDeflactor, anio(`anio') nographs nooutput //`update'
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


	** 2.2 Update PEF **
	if "`update'" == "update" {
		noisily UpdatePEF `update'
	}



	***************
	*** 3 Merge ***
	***************
	use "`c(sysdir_site)'/master/PEF.dta", clear

	** 3.1 Gasto total **
	egen double gastoTOT = sum(gasto) if transf_gf == 0, by(anio)

	** 3.2 Cuotas ISSSTE **
	g cuotasTOT = -gasto if ramo == -1
	egen double CuoTOT = sum(cuotasTOT), by(anio)

	** 3.3 Gasto neto **
	replace gastoTOT = gastoTOT + CuoTOT
	capture collapse (sum) gasto (max) gastoTOT CuoTOT `if', by(anio `by' transf_gf) fast
	if _rc != 0 {
		noisily di in g `" No hay informaci{c o'}n para el a{c n~}o `if'."'
		return local rc = "NoData"
		exit
	}
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
	g double gastoPC = gasto/Poblacion					// per capita: `currency' por persona (Poblacion de PIBDeflactor)
	format *PIB %10.3fc
	format gastoR gastoTOT CuoTOT %20.0fc
	format gastoPC %10.0fc



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


	*******************************************************************
	** 5. Display PEF — simetrico con LIF (2026-09-12):                 **
	**    A. Nivel `anio' por `by' (MXN, % PIB, % Tot, MXN per capita) y
	**       conciliacion bruto -> neto (cuotas ISSSTE, aportaciones).  **
	**    B. Crecimiento `desde'-`anio' por grupo resumido (dif % PIB,  **
	**       %G real, elasticidad). Los r() conservan nombres y valores. **
	*******************************************************************

	** 5.1 A. Nivel por `by' **
	noisily di _newline in g "{bf: A. Gasto bruto (`by')}" ///
		_newline ///
		_col(37) in g %18s "`currency'" ///
		_col(56) %7s "% PIB" ///
		_col(64) %6s "% Tot" ///
		_col(71) %8s "`currency' PC"

	capture tabstat gasto gastoPIB gastoPC if anio == `anio' & lower(`by') != "cuotas issste", by(`by') stat(sum) f(%20.0fc) save
	if _rc != 0 {
		noisily di in g " No hay informaci{c o'}n para el a{c n~}o `anio'."
		return local rc = "NoData"
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

		noisily di in g `"  (+) `=substr(`"`disptext'"',1,30)'"' ///
			_col(37) in y %18.0fc `mat`k''[1,1] ///
			_col(56) in y %7.3fc `mat`k''[1,2] ///
			_col(64) in y %6.1fc `mat`k''[1,1]/`mattot'[1,1]*100 ///
			_col(71) in y %8.0fc `mat`k''[1,3]
		local ++k
	}
	return local `by' `"``by''"'

	noisily di in g _dup(78) "-"
	noisily di in g "{bf:  (=) Gasto bruto" ///
		_col(37) in y %18.0fc `mattot'[1,1] ///
		_col(56) in y %7.3fc `mattot'[1,2] ///
		_col(64) in y %6.1fc 100 ///
		_col(71) in y %8.0fc `mattot'[1,3] "}"
	
	return scalar Gasto_bruto = `mattot'[1,1]
	return scalar Gasto_brutoPIB = `mattot'[1,2]
	return scalar Gasto_brutoPC = `mattot'[1,3]

	** 5.2 Gasto neto **
	* Aportaciones y cuotas de la Federacion *
	capture tabstat gasto gastoPIB gastoPC if anio == `anio' & transf_gf == 1, stat(sum) f(%20.0fc) save by(`by')
	tempname Aportaciones_Federacion
	if _rc == 0 {
		matrix `Aportaciones_Federacion' = r(StatTotal)
	}
	else {
		matrix `Aportaciones_Federacion' = J(1,3,0)
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

	capture tabstat gasto gastoPIB gastoPC if lower(`by') == "cuotas issste" & anio == `anio', stat(sum) f(%20.0fc) save
	tempname Cuotas_ISSSTE
	if _rc == 0 {
		matrix `Cuotas_ISSSTE' = r(StatTotal)
		return scalar Cuotas_ISSSTE = `Cuotas_ISSSTE'[1,1]
	}
	else {
		matrix `Cuotas_ISSSTE' = J(1,3,0)		
	}

	* Conciliacion bruto -> neto (solo las lineas con monto) *
	if `Cuotas_ISSSTE'[1,1] != 0 {
		noisily di in g "  (-) Cuotas ISSSTE" ///
			_col(37) in y %18.0fc `Cuotas_ISSSTE'[1,1] ///
			_col(56) in y %7.3fc `Cuotas_ISSSTE'[1,2] ///
			_col(64) in y %6.1fc `Cuotas_ISSSTE'[1,1]/`mattot'[1,1]*100 ///
			_col(71) in y %8.0fc `Cuotas_ISSSTE'[1,3]
	}
	if `Aportaciones_Federacion'[1,1] != 0 {
		noisily di in g "  (-) Aportaciones a la seg. social" ///
			_col(37) in y %18.0fc `Aportaciones_Federacion'[1,1] ///
			_col(56) in y %7.3fc `Aportaciones_Federacion'[1,2] ///
			_col(64) in y %6.1fc `Aportaciones_Federacion'[1,1]/`mattot'[1,1]*100 ///
			_col(71) in y %8.0fc `Aportaciones_Federacion'[1,3]
	}
	if `Cuotas_ISSSTE'[1,1] != 0 | `Aportaciones_Federacion'[1,1] != 0 {
		noisily di in g _dup(78) "-"
		noisily di in g "{bf:  (=) Gasto neto" ///
			_col(37) in y %18.0fc `mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1] ///
			_col(56) in y %7.3fc  `mattot'[1,2]-`Cuotas_ISSSTE'[1,2]-`Aportaciones_Federacion'[1,2] ///
			_col(64) in y %6.1fc (`mattot'[1,1]-`Cuotas_ISSSTE'[1,1]-`Aportaciones_Federacion'[1,1])/`mattot'[1,1]*100 ///
			_col(71) in y %8.0fc `mattot'[1,3]-`Cuotas_ISSSTE'[1,3]-`Aportaciones_Federacion'[1,3] "}"
	}


	**********************************************************************
	** 5.2 B. Crecimiento `desde'-`anio' por grupo resumido               **
	** (el dataset resumido —cuotas ISSSTE en negativo, grupos < minimum   **
	**  agregados, balanceado por reshape— es el que consumen los graficos **
	**  y los r() por rubro: name, namePIB, nameTot, namePC, nameC, Ename) **
	**********************************************************************
	replace gasto = -gasto if lower(resumido) == "cuotas issste"
	replace gastoR = -gastoR if lower(resumido) == "cuotas issste"
	replace gastoPIB = -gastoPIB if lower(resumido) == "cuotas issste"
	replace gastoPC = -gastoPC if lower(resumido) == "cuotas issste"
	
	replace gasto = 0 if gasto == .
	replace gastoR = 0 if gastoR == .
	replace gastoPIB = 0 if gastoPIB == .
	replace gastoPC = 0 if gastoPC == .

	rename resumido resumido2
	replace resumido2 = strtoname(resumido2)
	replace resumido2 = substr(resumido2,1,24)
	collapse (sum) gasto gastoPIB gastoR gastoPC (max) pibY deflator lambda Poblacion if transf_gf == 0, by(anio resumido2)
	reshape wide gasto*, i(anio) j(resumido2) string
	reshape long
	replace resumido2 = subinstr(resumido2,"_"," ",.)
	encode resumido2, g(resumido)
	local nyears = `aniovp'-`desde'
	
	* Anio base: matrices por posicion k (el reshape balancea los grupos,
	* asi que la k-esima fila de `desde' y de `anio' es el mismo grupo) *
	local haspre = 0
	capture tabstat gastoR gastoPIB if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save missing
	if _rc == 0 & "`pibYR`desde''" != "" {
		local haspre = 1
		tempname pregastot
		matrix `pregastot' = r(StatTotal)
		local k = 1
		while `"`=r(name`k')'"' != "." {
			tempname pre`k'
			matrix `pre`k'' = r(Stat`k')
			local ++k
		}
		local gpib = ((`pibYR`anio''/`pibYR`desde'')^(1/`nyears')-1)*100
	}

	capture tabstat gasto gastoPIB gastoR gastoPC if anio == `anio', by(resumido) stat(sum) f(%20.1fc) save missing
	tempname mattot
	if _rc == 0 {
		matrix `mattot' = r(StatTotal)
	}
	else {
		matrix `mattot' = J(1,4,0)
	}

	if `haspre' {
		noisily di _newline in g "{bf: B. Crecimiento:" in y " `desde' - `anio'" in g " (gasto neto, grupos resumidos)}" ///
			_newline ///
			_col(35) %7s "`desde'" ///
			_col(44) %7s "`anio'" ///
			_col(53) %7s "Dif PIB" ///
			_col(62) %7s "%G real" ///
			_col(71) %7s "Elastic"
		noisily di in g _col(35) %7s "% PIB" _col(44) %7s "% PIB" _col(53) %7s "pp" _col(62) %7s "anual" _col(71) %7s "vs PIB"
	}

	local k = 1
	while `"`=r(name`k')'"' != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		
		if `mat`k''[1,1] == . {
			matrix `mat`k'' = J(1,4,0)
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

		* Returns de nivel *
		return scalar `name' = `mat`k''[1,1]
		return scalar `name'PIB = `mat`k''[1,2]
		return scalar `name'Tot = `mat`k''[1,1]/`mattot'[1,1]*100
		return scalar `name'PC = `mat`k''[1,4]
		local divResumido `"`divResumido' `name'"'

		* Crecimiento real (geometrico) y elasticidad, si hay anio base *
		if `haspre' {
			capture confirm matrix `pre`k''
			if _rc != 0 {
				tempname pre`k'
				matrix `pre`k'' = J(1,2,0)
			}
			local g = (abs(`mat`k''[1,3]/`pre`k''[1,1])^(1/`nyears')-1)*100
			return scalar `name'C = `g'
			if `gpib' != 0 {
				return scalar E`name' = `g'/`gpib'
			}
			noisily di in g `"  (+) `=substr("`disptext'",1,28)'"' ///
				_col(35) in y %7.3fc `pre`k''[1,2] ///
				_col(44) in y %7.3fc `mat`k''[1,2] ///
				_col(53) in y %7.3fc `mat`k''[1,2]-`pre`k''[1,2] ///
				_col(62) in y %7.3fc `g' ///
				_col(71) in y %7.3fc cond(`gpib' != 0, `g'/`gpib', .)
		}
		local ++k
	}
	return local divResumido `"`divResumido'"'

	return scalar Gasto_neto = `mattot'[1,1]
	return scalar Gasto_netoPIB = `mattot'[1,2]
	return scalar Gasto_netoPC = `mattot'[1,4]
	if `haspre' {
		local gtot = ((`mattot'[1,3]/`pregastot'[1,1])^(1/`nyears')-1)*100
		return scalar Gasto_netoC = `gtot'
		if `gpib' != 0 {
			return scalar EGasto_neto = `gtot'/`gpib'
		}
		noisily di in g _dup(78) "-"
		noisily di in g "{bf:  (=) Gasto neto" ///
			_col(35) in y %7.3fc `pregastot'[1,2] ///
			_col(44) in y %7.3fc `mattot'[1,2] ///
			_col(53) in y %7.3fc `mattot'[1,2]-`pregastot'[1,2] ///
			_col(62) in y %7.3fc `gtot' ///
			_col(71) in y %7.3fc cond(`gpib' != 0, `gtot'/`gpib', .) "}"
		noisily di in g "  PIB real: " in y %5.3fc `gpib' in g " % anual (`desde'-`anio'). Crecimientos sobre gasto real (deflactor `aniovp')."
	}

	tempname Resumido_total
	matrix `Resumido_total' = r(StatTotal)
	return scalar Resumido_total = `Resumido_total'[1,1]


	*******************
	*** 5. Gráficos ***
	*******************
	preserve
	if "`nographs'" != "nographs" & "$nographs" == "" {

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

		* Define color intensity based on highlight option *
		local int1 = cond(`highlight' == 0 | `highlight' == 1, "100", "30")
		local int2 = cond(`highlight' == 0 | `highlight' == 2, "100", "30")
		local int3 = cond(`highlight' == 0 | `highlight' == 3, "100", "30")
		local int4 = cond(`highlight' == 0 | `highlight' == 4, "100", "30")
		local int5 = cond(`highlight' == 0 | `highlight' == 5, "100", "30")
		local int6 = cond(`highlight' == 0 | `highlight' == 6, "100", "30")
		local int7 = cond(`highlight' == 0 | `highlight' == 7, "100", "30")
		local int8 = cond(`highlight' == 0 | `highlight' == 8, "100", "30")
		local int9 = cond(`highlight' == 0 | `highlight' == 9, "100", "30")
		local int10 = cond(`highlight' == 0 | `highlight' == 10, "100", "30")
		
		graph bar gastoPIB if anio <= `anio', ///
			over(resumido, sort(1) descending) over(anio, gap(25)) ///
			stack asyvars outergap(0) ///
			bar(1, color("255 189 0%`int1'")) ///
			bar(2, color("209 212 32%`int2'")) ///
			bar(3, color("57 197 183%`int3'")) ///
			bar(4, color("255 55 0%`int4'")) ///
			bar(5, color("0 150 200%`int5'")) ///
			bar(6, color("226 228 99%`int6'")) ///
			bar(7, color("224 97 95%`int7'")) ///
			bar(8, color("255 128 0%`int8'")) ///
			bar(9, color("103 222 86%`int9'")) ///
			bar(10, color("150 6 92%`int10'")) ///
			name(gastos`by'PIB, replace) ///
			title("`graphtitle'") ///
			ylabel(, format(%7.1fc) labsize(small)) ///
			ytitle("% PIB") ///
			blabel(bar, format(%5.1fc) size(medsmall)) ///
			legend(on position(6) rows(`rows') cols(`cols') /*`legend' order(`order')*/ justification(left)) ///
			/// Added text 
			///text(`=recaudacionPIBTOT[1]' `=anio[1]' "{bf:% PIB}", placement(6)) ///
			///text(`=`recaudacionline'[1]' `=anio[1]' "{bf:% LIF}", placement(6) yaxis(2)) ///
			///caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de SHCP/EOFP, INEGI/BIE y $paqueteEconomico.") ///
			b1title("De `desde' a `anio', el {bf:gasto `cambio' `=string(abs(`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]),"%7.1fc")'} puntos porcentuales del PIB.")

		/*grc1leg ///
		///graph combine ///
		ingresos`by'PIB ingresosMXN`by' , ///
			title("{bf:`graphtitle'}") ///
			caption("Fuente: Elaborado por el CIEP, con informaci{c o'}n de SHCP/EOFP, INEGI/BIE y $paqueteEconomico.") ///
			name(ingresos`by', replace) xcommon */

		*capture window manage close graph ingresosMXN`by'
		*capture window manage close graph ingresos`by'PIB
	
		graph save gastos`by'PIB "`c(sysdir_site)'/users/$id/graphs/gastos`by'PIB", replace
		if "$export" != "" {
			graph export "$export/gastos`by'PIB.png", as(png) name("gastos`by'PIB") replace
		}
	}
	restore



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
	* 1.1. Descargar archivos *
	capture confirm file "`c(sysdir_site)'/raw/temp/prePEF.dta"
	if _rc != 0 {
		* Asegurar que los assets esten descargados: TODOS los que el manifest
		* declara bajo raw/PEFs/ (CP/PEF/PPEF por anio, CuotasISSSTE, Diccionario).
		* La lista se DERIVA del manifest — hasta v8.3.0 era un foreach tecleado
		* a mano desde v7.0 y dejo fuera PPEF.2027.xlsx y Diccionario.csv: el
		* modulo descubre anios con `dir raw/PEFs`, asi que un asset no pedido
		* simplemente no existia, sin error (2026-09-14, v8.3.1). *
		ensure_asset, dir(raw/PEFs)
		* Prioridad por año: CP (Cuenta Publica, ejercido) > PEF (aprobado) >    *
		* PPEF (proyecto). Si coexisten dos versiones del mismo año, se usa la  *
		* de mayor prioridad y se avisa; asi no se duplica el año ni hay que    *
		* borrar xlsx a mano cuando llega la CP.                                *
		local todos: dir "`c(sysdir_site)'/raw/PEFs" files "*.xlsx"
		local archivos
		foreach k of local todos {
			* Archivos de bloqueo de Excel (~$nombre.xlsx): el xlsx esta abierto. *
			* macval() evita que Stata expanda el "$" como macro global.         *
			if strpos(`"`macval(k)'"', "~$") == 1 {
				noisily di in g "Omitiendo archivo de bloqueo de Excel (cerrar el xlsx abierto)."
				continue
			}
			if regexm(`"`k'"', "^(CP|PEF|PPEF) ([0-9][0-9][0-9][0-9])\.xlsx$") {
				local tipo = regexs(1)
				local yr = regexs(2)
				local mejor "`tipo'"
				foreach t in CP PEF PPEF {
					if `: list posof `"`t' `yr'.xlsx"' in todos' > 0 {
						local mejor "`t'"
						continue, break
					}
				}
				if "`tipo'" != "`mejor'" {
					noisily di in g "Omitiendo " in y "`k'" in g ": lo supersede " in y "`mejor' `yr'.xlsx" in g "."
					continue
				}
			}
			local archivos `"`archivos' `"`k'"'"'
		}

		foreach k of local archivos {

			* 1.1 Importar el archivo `k'.xlsx (Cuenta Pública) *
			* Deteccion de la hoja de datos: SHCP publica algunas CPs con hojas   *
			* pivote adicionales (p.ej. el archivo pristino de CP 2013 trae una   *
			* hoja pivote ANTES de la hoja de datos). Se elige la hoja con mas    *
			* filas; NO se depende de que el xlsx local este curado a mano.       *
			noisily di in g "Importando: " in y "`k'"
			tokenize `k'
			import excel "`c(sysdir_site)'/raw/PEFs/`k'", describe
			local hoja = r(worksheet_1)
			if r(N_worksheet) > 1 {
				local nsheets = r(N_worksheet)
				forvalues s = 1/`nsheets' {
					local ws`s' = r(worksheet_`s')
					local rg`s' = r(range_`s')
				}
				local maxfilas = 0
				forvalues s = 1/`nsheets' {
					local filas = 0
					if regexm("`rg`s''", "[A-Z]+([0-9]+)$") {
						local filas = real(regexs(1))
					}
					if `filas' > `maxfilas' {
						local maxfilas = `filas'
						local hoja "`ws`s''"
					}
				}
				noisily di in g "  hoja de datos: " in y "`hoja'" in g " (de `nsheets' hojas)"
			}
			import excel "`c(sysdir_site)'/raw/PEFs/`k'", clear firstrow case(lower) allstring sheet("`hoja'")
			capture drop v*

			* 1.2 Limpiar observaciones: filas sin CICLO (CP 2022 trae 1,000 vacias) *
			capture confirm variable ciclo
			if _rc != 0 {
				noisily di as error "ALARMA UpdatePEF (`k'): el archivo no trae la columna CICLO."
				error 459
			}
			quietly count if trim(ciclo) == ""
			if r(N) > 0 {
				noisily di in g "  filas sin CICLO eliminadas: " in y r(N)
				drop if trim(ciclo) == ""
			}

			* 1.3 Homologar nombres de columna al layout canonico y validar *
			* (diccionario unico para todos los layouts SHCP 2013-2027; una  *
			* columna desconocida o una canonica faltante DETIENE el proceso) *
			_PEFhomologa, archivo(`"`k'"')

			* 1.4 Limpiar valores: montos numericos, caracteres raros, codigos *
			_PEFlimpia, archivo(`"`k'"')

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
				capture append using ``=strtoname("`k'")''
				if _rc != 0 {
					local rc = _rc
					noisily di as error "ALARMA UpdatePEF: fallo el append de `k' (error r(`rc')). Tipos en conflicto:"
					_PEFtipos using ``=strtoname("`k'")''
					error `rc'
				}
			}
		}

		* Quinto, verificar comparabilidad intertemporal (año por año) *
		_PEFverifica


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
		replace ramo = "52" if ramo == "TZZ" | ur == "tzz"	// ur ya viene en minusculas (limpieza 1.4)
		replace ramo = "53" if ramo == "TOQ" | ur == "toq"
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
		* CONGELADO (v8.1): el bloque completo de Estadisticas Oportunas       *
		* (3.1, 3.2 y 3.3) se comenta y revive junto. Los mapeos 3.1/3.2       *
		* dependian de los codigos del encode de desc_funcion, que cambian     *
		* con cada categoria nueva (deriva alfabetica); al revivirlo, anclar   *
		* a finalidad/funcion (CONAC) o a strings normalizados.                *
		/*
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
		*/

		compress
		save "`c(sysdir_site)'/raw/temp/prePEF.dta", replace
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
		saveold "`c(sysdir_site)'/master/GastoEstOpor.dta", replace version(13)
	}
	else {
		capture mkdir "`c(sysdir_site)'/master/"
		save "`c(sysdir_site)'/master/GastoEstOpor.dta", replace
	}*/

	***************************************/
	***                                  ***
	*** 4. Modulos SIMULADOR FISCAL CIEP ***
	***                                  ***
	****************************************
	use "`c(sysdir_site)'/raw/temp/prePEF.dta", clear
	replace desc_funcion = -1 if ramo == -1


	**********************************************
	** 4.0 Verificador de deriva de catálogos   **
	**********************************************
	* Cinturon y tirantes (v8.1): las divisiones se anclan a los CODIGOS   *
	* oficiales (Clasificacion Funcional del Gasto del CONAC: pares        *
	* finalidad/funcion; y TIPOGASTO por prefijo de texto normalizado).    *
	* Por cada regla se verifica AQUI, año por año, que el texto publicado *
	* coincide con lo esperado. Un mismatch DETIENE el proceso con año y   *
	* texto encontrado: jamas clasificar en silencio con catalogo derivado.*
	tempvar vfun vtg
	decode desc_funcion, g(`vfun')
	replace `vfun' = strtrim(ustrlower(`vfun'))
	decode desc_tipogasto, g(`vtg')
	replace `vtg' = strtrim(ustrlower(`vtg'))

	* Toda observacion trae año (una hoja pivote importada por error no lo trae) *
	capture assert anio != .
	if _rc != 0 {
		noisily di as error "ALARMA UpdatePEF: observaciones sin anio (¿hoja pivote o archivo corrupto?)."
		error 459
	}

	levelsof anio, local(ANIOS)
	foreach a of local ANIOS {

		* CONAC finalidad 2 + funcion 3 = salud *
		capture assert `vfun' == "salud" if anio == `a' & finalidad == 2 & funcion == 3 & ramo != -1
		if _rc != 0 {
			noisily di as error "ALARMA UpdatePEF (`a'): finalidad 2 & funcion 3 deberia ser 'salud'. Encontrado:"
			noisily levelsof `vfun' if anio == `a' & finalidad == 2 & funcion == 3 & ramo != -1 & `vfun' != "salud"
			error 459
		}

		* CONAC finalidad 2 + funcion 5 = educación *
		capture assert `vfun' == "educación" if anio == `a' & finalidad == 2 & funcion == 5 & ramo != -1
		if _rc != 0 {
			noisily di as error "ALARMA UpdatePEF (`a'): finalidad 2 & funcion 5 deberia ser 'educación'. Encontrado:"
			noisily levelsof `vfun' if anio == `a' & finalidad == 2 & funcion == 5 & ramo != -1 & `vfun' != "educación"
			error 459
		}

		* CONAC finalidad 3 + funcion 3 = combustibles y energía *
		capture assert `vfun' == "combustibles y energía" if anio == `a' & finalidad == 3 & funcion == 3 & ramo != -1
		if _rc != 0 {
			noisily di as error "ALARMA UpdatePEF (`a'): finalidad 3 & funcion 3 deberia ser 'combustibles y energía'. Encontrado:"
			noisily levelsof `vfun' if anio == `a' & finalidad == 3 & funcion == 3 & ramo != -1 & `vfun' != "combustibles y energía"
			error 459
		}

		* TIPOGASTO: todo texto debe ser reconocido (corriente/capital/inversión/obra/part/pensiones) *
		capture assert strpos(`vtg',"gasto corriente") == 1 | strpos(`vtg',"gasto de capital") == 1 ///
			| strpos(`vtg',"gasto de inversión") == 1 | strpos(`vtg',"gasto de obra") == 1 ///
			| `vtg' == "participaciones" | `vtg' == "pensiones y jubilaciones" ///
			| `vtg' == "cuotas issste" | `vtg' == "" if anio == `a'
		if _rc != 0 {
			noisily di as error "ALARMA UpdatePEF (`a'): TIPOGASTO no reconocido (¿categoria nueva de SHCP?). Encontrado:"
			noisily levelsof `vtg' if anio == `a' & !(strpos(`vtg',"gasto corriente") == 1 ///
				| strpos(`vtg',"gasto de capital") == 1 | strpos(`vtg',"gasto de inversión") == 1 ///
				| strpos(`vtg',"gasto de obra") == 1 | `vtg' == "participaciones" ///
				| `vtg' == "pensiones y jubilaciones" | `vtg' == "cuotas issste" | `vtg' == "")
			error 459
		}
	}


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
	* Salud = finalidad 2 & funcion 3 (Clasificacion Funcional del Gasto, CONAC) *
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ((finalidad == 2 & funcion == 3) | ramo == 12 | ramo == 56)
	replace divCIEP = "Salud" if divCIEP == "" ///
		& (ramo == 50 | ramo == 51) & (pp == 4 | pp == 15 | pp == 8) & funcion == 8
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ramo == 52 & ai == 231
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ramo == 47 & ur == "ayo"
	replace divCIEP = "Salud" if divCIEP == "" ///
		& ramo == 20 & pp == 317

	replace divSIM = "Salud" if divCIEP == "Salud"


	*****************
	** 4.3 Energía **
	* Combustibles y energía = finalidad 3 & funcion 3 (CONAC) *
	replace divCIEP = "Energía" if divCIEP == "" ///
		& (ramo == 18 | ramo == 45 | ramo == 46 | ramo == 52 | ramo == 53 ///
		| (ramo == 23 & finalidad == 3 & funcion == 3))

	replace divSIM = "Energía" if divCIEP == "Energía"


	***************************
	** 4.4 Costo de la deuda **
	replace divCIEP = "Costo de la deuda" if divCIEP == "" ///
		& capitulo == 9

	replace divSIM = "Costo de la deuda" ///
		if capitulo == 9


	*******************
	** 4.5 Educación **
	* Educación = finalidad 2 & funcion 5 (CONAC) *
	replace divCIEP = "Educación" if divCIEP == "" ///
		& ((finalidad == 2 & funcion == 5) | ramo == 11 | ramo == 48 | ramo == 38)

	replace divSIM = "Educación" if divCIEP == "Educación"


	*************************************
	** 4.6 Inversión e Infraestructura **
	* Inversión = TIPOGASTO de capital/inversión/obra, por prefijo del texto  *
	* normalizado (los codigos del encode derivan con cada categoria nueva;   *
	* todo texto no reconocido lo detiene el verificador 4.0)                 *
	replace divCIEP = "Otras inversiones" if divCIEP == "" ///
		& (strpos(`vtg',"gasto de capital") == 1 | strpos(`vtg',"gasto de inversión") == 1 | strpos(`vtg',"gasto de obra") == 1)

	replace divSIM = "Inversión" ///
		if (strpos(`vtg',"gasto de capital") == 1 | strpos(`vtg',"gasto de inversión") == 1 | strpos(`vtg',"gasto de obra") == 1)


	**********************
	** 4.7 Federalizado **
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (ramo == 28)                                        // Part
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (ramo == 33 | ramo == 25)                           // Aport
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (objeto == 43801)                                   // Convenios descentralizados
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (objeto == 85101)                                   // Convenios de reasignación
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (objeto == 43101 & ramo == 8 & pp == 263 & entidad != 34) // Convenios de reasignación
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (objeto == 46101 & ramo == 23 & pp == 80)           // FEIEF
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (ramo == 23 & pp == 4 & modalidad == "y")           // FEIEF (minusculas: limpieza 1.4)
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (ramo == 23 & pp == 141)                            // FIES
	replace divCIEP = "Federalizado" if divCIEP == "" ///
		& (pp == 13 & (ramo == 12 | ramo == 47) & modalidad == "u") // INSABI/Seguro Popular/IMSS-Bienestar

	g divFEDE = "Participaciones" if (ramo == 28) // Part
	replace divFEDE = "Aportaciones" if (ramo == 33 | ramo == 25)    // Aport
	replace divFEDE = "Convenios" if (objeto == 43801 & ramo != 23)  // Convenios descentralizados
	replace divFEDE = "Convenios" if (objeto == 85101)               // Convenios de reasignación
	replace divFEDE = "Convenios" if (objeto == 43101 & ramo == 8 & pp == 263 & entidad != 34) // Convenios de reasignación
	replace divFEDE = "Subsidios" if (objeto == 46101 & ramo == 23 & pp == 80) // FEIEF
	replace divFEDE = "Subsidios" if (ramo == 23 & pp == 4 & modalidad == "y") // FEIEF
	replace divFEDE = "Subsidios" if (ramo == 23 & pp == 141) // FIES
	replace divFEDE = "Subsidios" if (ramo == 23 & objeto == 43801)
	replace divFEDE = "Salud (federalizado)" if (pp == 13 & (ramo == 12 | ramo == 47) & modalidad == "u") // INSABI/Seguro Popular/IMSS-Bienestar


	**********************************
	** 4.8 Economía de los cuidados **
	replace divSIM = "Cuidados" if divSIM == "" & (ramo == 11 & pp == 312) | (ramo == 11 & pp == 31) ///
		| (ramo == 11 & pp == 66) ///
		| (ramo == 20 & pp == 174) | (ramo == 51 & pp == 48) | (ramo == 50 & pp == 7) ///
		| (ramo == 20 & pp == 241) ///
		| (ramo == 12 & pp == 41) | (ramo == 20 & pp == 3 & ur == "v3a") | (ramo == 33 & pp == 6) ///
		| (ramo == 4 & pp == 12  & ur == "v00") | (ramo == 51 & pp == 42) | (ramo == 12 & pp == 39) ///
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
	replace noprogramable = 0 if ramo == -1
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
	capture mkdir "`c(sysdir_site)'/master/"
	save "`c(sysdir_site)'/master/PEF.dta", replace
end



****************************************************************
**** _PEFhomologa: nombres de columna SHCP -> layout canonico ****
****************************************************************
* Un solo diccionario para todos los layouts que ha publicado la SHCP:
*   CP 2013-2024  : ID_xxx / DESC_xxx, MONTO_xxx, EJERCICIO, ENTIDAD_FEDERATIVA (texto)
*   CP 2025       : sin prefijo ID_, "R" para ramo, ENTIDAD_FEDERATIVA (numerica)
*   PEF 2026      : ID_PARTIDA_ESPECIFICA en vez de OBJETO_DEL_GASTO, + capitulo/concepto
*   PPEF 2027     : RAMO_DESCRIPCION, UNIDAD, PROGR_PRES, TIPO_GASTO, FUENTE_FINAN,
*                   IMPORTE_PROYECTO, ..._DESCRIPCION
*   CuotasISSSTE  : ciclo ramo desc_ramo proyecto aprobado ejercido
* Recibe la base con nombres en minusculas (case(lower)). Elimina columnas
* fantasma (100% vacias), renombra segun el diccionario y DETIENE con lista
* explicita si queda una columna desconocida o falta una canonica requerida.
program define _PEFhomologa

	syntax , ARCHivo(string)

	** 1. Columnas fantasma: headers vacios que import excel nombra con la     **
	** letra de la columna (CP 2019: 73, CP 2021: 1,024, CP 2022: 212). Se    **
	** detectan por CONTENIDO (100% vacias), no por nombre: CP 2025 trae      **
	** columnas legitimas de 1-2 letras (R, UR, AI, PP, FF).                  **
	local fantasma = 0
	foreach j of varlist _all {
		capture assert missing(`j')
		if _rc == 0 {
			drop `j'
			local ++fantasma
		}
	}
	if `fantasma' > 0 {
		noisily di in g "  columnas fantasma (vacias) eliminadas: " in y `fantasma'
	}

	** 2. ENTIDAD_FEDERATIVA es TEXTO cuando existe ID_ENTIDAD_FEDERATIVA      **
	** (CP 2013-2024) y NUMERICA cuando no (CP 2025, PPEF 2027).              **
	capture confirm variable id_entidad_federativa, exact
	if _rc == 0 {
		capture rename entidad_federativa desc_entidad
	}

	** 3. Diccionario origen -> canonico **
	local dic ///
		ciclo:anio ///
		id_ramo:ramo r:ramo ///
		desc_ramo:desc_ramo ramo_descripcion:desc_ramo ///
		id_ur:ur unidad:ur ///
		desc_ur:desc_ur unidad_descripcion:desc_ur ///
		gpo_funcional:finalidad grupo_funcional:finalidad ///
		desc_gpo_funcional:desc_finalidad grupo_fun_descripcion:desc_finalidad ///
		id_funcion:funcion ///
		desc_funcion:desc_funcion funcionl_descripcion:desc_funcion ///
		id_subfuncion:subfuncion ///
		desc_subfuncion:desc_subfuncion subfuncionl_descripcion:desc_subfuncion ///
		id_ai:ai actividad_inst:ai ///
		desc_ai:desc_ai actividad_inst_descripcion:desc_ai ///
		id_modalidad:modalidad ///
		desc_modalidad:desc_modalidad modalidad_descripcion:desc_modalidad ///
		id_pp:pp progr_pres:pp ///
		desc_pp:desc_pp progr_pres_descripcion:desc_pp ///
		id_capitulo:capitulo ///
		desc_capitulo:desc_capitulo capitulo_desc:desc_capitulo ///
		id_concepto:concepto ///
		desc_concepto:desc_concepto concepto_desc:desc_concepto ///
		id_partida_generica:partida_generica ///
		desc_partida_generica:desc_partida_generica partida_generica_desc:desc_partida_generica ///
		id_objeto_del_gasto:objeto objeto_del_gasto:objeto id_partida_especifica:objeto partida_especifica:objeto ///
		desc_objeto_del_gasto:desc_objeto desc_partida_especifica:desc_objeto partida_descripcion:desc_objeto ///
		id_tipogasto:tipogasto tipo_gasto:tipogasto ///
		desc_tipogasto:desc_tipogasto tipo_gasto_descripcion:desc_tipogasto ///
		id_ff:fuente ff:fuente fuente_finan:fuente ///
		desc_ff:desc_fuente fuente_finan_descripcion:desc_fuente ///
		id_entidad_federativa:entidad entidad_federativa:entidad ///
		desc_entidad_federativa:desc_entidad entidad_fed_descripcion:desc_entidad ///
		id_clave_cartera:clave_cartera ///
		monto_aprobado:aprobado ///
		monto_modificado:modificado ///
		monto_devengado:devengado ///
		monto_pagado:pagado ///
		monto_adefas:adefas ///
		monto_ejercicio:ejercido ejercicio:ejercido monto_ejercido:ejercido ///
		importe_proyecto:proyecto

	local canonicas anio ramo desc_ramo ur desc_ur finalidad desc_finalidad funcion desc_funcion ///
		subfuncion desc_subfuncion ai desc_ai modalidad desc_modalidad pp desc_pp ///
		capitulo desc_capitulo concepto desc_concepto partida_generica desc_partida_generica ///
		objeto desc_objeto tipogasto desc_tipogasto fuente desc_fuente entidad desc_entidad ///
		clave_cartera aprobado modificado devengado pagado adefas ejercido proyecto

	local desconocidas
	foreach j of varlist _all {
		local destino
		foreach par of local dic {
			gettoken origen destino2 : par, parse(":")
			local destino2 = subinstr("`destino2'", ":", "", 1)
			if "`j'" == "`origen'" {
				local destino `destino2'
			}
		}
		if "`destino'" != "" {
			if "`destino'" != "`j'" {
				capture confirm variable `destino', exact
				if _rc == 0 {
					noisily di as error "ALARMA UpdatePEF (`archivo'): `j' y `destino' mapean a la misma columna canonica `destino'."
					error 459
				}
				rename `j' `destino'
			}
		}
		else if !`: list j in canonicas' {
			local desconocidas `desconocidas' `j'
		}
	}
	if "`desconocidas'" != "" {
		noisily di as error "ALARMA UpdatePEF (`archivo'): columnas NO reconocidas (¿layout nuevo de SHCP?): " in y "`desconocidas'"
		noisily di as error "  Agregarlas al diccionario de _PEFhomologa en PEF.ado antes de continuar."
		error 459
	}

	** 4. Canonicas requeridas segun el tipo de archivo **
	capture confirm variable ur, exact
	if _rc != 0 {
		* CuotasISSSTE: solo ciclo ramo desc_ramo + montos *
		local requeridas anio ramo desc_ramo
	}
	else {
		local requeridas anio ramo desc_ramo ur desc_ur finalidad desc_finalidad funcion desc_funcion ///
			subfuncion desc_subfuncion ai desc_ai modalidad desc_modalidad pp desc_pp ///
			objeto desc_objeto tipogasto desc_tipogasto fuente desc_fuente entidad desc_entidad clave_cartera
	}
	local faltantes
	foreach v of local requeridas {
		capture confirm variable `v', exact
		if _rc != 0 {
			local faltantes `faltantes' `v'
		}
	}
	if "`faltantes'" != "" {
		noisily di as error "ALARMA UpdatePEF (`archivo'): faltan columnas canonicas: " in y "`faltantes'"
		error 459
	}
	local montos = 0
	foreach v in aprobado ejercido proyecto {
		capture confirm variable `v', exact
		if _rc == 0 {
			local ++montos
		}
	}
	if `montos' == 0 {
		noisily di as error "ALARMA UpdatePEF (`archivo'): no trae ninguna columna de monto (aprobado/ejercido/proyecto)."
		error 459
	}
end


****************************************************************
**** _PEFlimpia: montos numericos, caracteres raros, codigos  ****
****************************************************************
* Recibe la base ya homologada (todo string, por allstring). Deja:
*   - montos numericos (coma de miles fuera), vacios = 0, formato %20.0fc
*   - textos sin NBSP / saltos de linea / tabs / mojibake (Ê, Â), sin comillas,
*     un solo espacio, trim, minusculas, acentos graves corregidos (ò -> ó:
*     CP 2013 trae "investigaciòn"), normalizados a NFC
*   - ramo STRING sin lower (codigos GYR/GYN/TZZ/TOQ se mapean en 2.2)
*   - codigos numericos forzados (anio finalidad funcion ... entidad): si no
*     convierten, DETIENE con los valores no numericos
*   - ur / modalidad / clave_cartera / desc_* forzados a string
program define _PEFlimpia

	syntax , ARCHivo(string)

	local montos aprobado modificado devengado pagado adefas ejercido proyecto
	local codigos anio finalidad funcion subfuncion ai pp capitulo concepto partida_generica ///
		objeto tipogasto fuente entidad
	local textos ur modalidad clave_cartera

	** 1. Montos **
	foreach j of local montos {
		capture confirm variable `j', exact
		if _rc == 0 {
			capture confirm string variable `j', exact
			if _rc == 0 {
				quietly replace `j' = subinstr(trim(`j'), ",", "", .)
				capture destring `j', replace
				if _rc != 0 {
					noisily di as error "ALARMA UpdatePEF (`archivo'): `j' trae valores no numericos:"
					noisily levelsof `j' if real(`j') == . & `j' != "", clean
					error 459
				}
			}
			format `j' %20.0fc
			quietly replace `j' = 0 if `j' == .
		}
	}

	** 2. Textos: todo lo que no es monto ni ramo **
	foreach j of varlist _all {
		if `: list j in montos' | "`j'" == "ramo" {
			continue
		}
		capture confirm string variable `j', exact
		if _rc != 0 {
			continue
		}
		quietly {
			replace `j' = ustrnormalize(`j', "nfc")
			replace `j' = subinstr(`j', char(160), " ", .)		// NBSP (todas las CPs)
			replace `j' = subinstr(`j', char(10), " ", .)		// salto de linea (PEF 2026, PPEF 2027)
			replace `j' = subinstr(`j', char(13), " ", .)
			replace `j' = subinstr(`j', char(9), " ", .)
			replace `j' = subinstr(`j', "Ê", " ", .)			// mojibake de algunas CPs
			replace `j' = subinstr(`j', "Â", "", .)
			replace `j' = subinstr(`j', `"""', "", .)
			replace `j' = ustrregexra(`j', " +", " ")
			replace `j' = trim(`j')
			replace `j' = lower(`j')
			if substr("`j'", 1, 5) == "desc_" {
				replace `j' = subinstr(`j', "à", "á", .)		// acentos graves: no existen en español
				replace `j' = subinstr(`j', "è", "é", .)
				replace `j' = subinstr(`j', "ì", "í", .)
				replace `j' = subinstr(`j', "ò", "ó", .)
				replace `j' = subinstr(`j', "ù", "ú", .)
			}
			format `j' %30s
		}
	}

	** 3. Codigos numericos: forzados; un valor no numerico detiene **
	foreach j of local codigos {
		capture confirm string variable `j', exact
		if _rc == 0 {
			capture destring `j', replace
			if _rc != 0 {
				noisily di as error "ALARMA UpdatePEF (`archivo'): el codigo `j' trae valores no numericos:"
				noisily levelsof `j' if real(`j') == . & `j' != "", clean
				error 459
			}
		}
	}

	** 4. Strings forzados: aunque un año venga 100% numerico, siguen string **
	** (ur mezcla 100/GYR; clave_cartera mezcla 0/alfanumerico)               **
	foreach j of local textos {
		capture confirm numeric variable `j', exact
		if _rc == 0 {
			quietly tostring `j', replace
		}
	}
	quietly tostring ramo, replace
	quietly replace ramo = trim(ramo)

	** 5. Un archivo CP/PEF/PPEF = un año (CuotasISSSTE trae todos los años) **
	capture confirm variable ur, exact
	if _rc == 0 {
		quietly levelsof anio, local(anios)
		if `: word count `anios'' != 1 {
			noisily di as error "ALARMA UpdatePEF (`archivo'): el archivo trae mas de un CICLO: `anios'"
			error 459
		}
	}
end


****************************************************************
**** _PEFtipos: diagnostico de tipos cuando falla un append   ****
****************************************************************
program define _PEFtipos

	syntax using/

	foreach v of varlist _all {
		local tm_`v' : type `v'
		local vmaster `vmaster' `v'
	}
	preserve
	use "`using'", clear
	foreach v of varlist _all {
		if `: list v in vmaster' {
			local tu : type `v'
			local tm `tm_`v''
			if (substr("`tm'",1,3) == "str") != (substr("`tu'",1,3) == "str") {
				noisily di as error "  {bf:`v'}: acumulado es " in y "`tm'" as err ", archivo es " in y "`tu'"
			}
		}
	}
	restore
end


****************************************************************
**** _PEFverifica: comparabilidad intertemporal tras el append ****
****************************************************************
* Año por año, sobre la base ya apilada (antes de la homologacion de terminos):
*   - cobertura de claves (ramo ur funcion objeto tipogasto entidad) >= 99.5%
*   - hay gasto: suma de aprobado, ejercido o proyecto > 0
*   - ramo: numerico 1-56 o codigo alfabetico conocido (GYR GYN TZZ TOQ), o -1
*   - modalidad: una letra; entidad: 1-34 o vacia; finalidad 1-4
*   - desc_tipogasto: solo categorias reconocidas por 4.6 (inversion) y 4.0
* Imprime una tabla resumen y DETIENE si alguna regla falla.
program define _PEFverifica

	tempvar okramo
	quietly g byte `okramo' = inrange(real(ramo), 1, 56) | inlist(ramo, "GYR", "GYN", "TZZ", "TOQ", "-1")

	noisily di _newline in g "{bf: Verificacion intertemporal PEF}"
	noisily di in g "  anio" _col(10) %9s "filas" _col(22) %7s "ramo" _col(31) %7s "ur" ///
		_col(40) %7s "funcion" _col(49) %7s "objeto" _col(58) %7s "tipogto" _col(67) %7s "entidad" ///
		_col(76) %10s "gasto(bn)"

	local fallas = 0
	quietly levelsof anio, local(ANIOS)
	foreach a of local ANIOS {
		quietly count if anio == `a'
		local ntot = r(N)
		quietly count if anio == `a' & ramo != "-1"
		local n = r(N)
		local cuotas = (`n' == 0)

		foreach v in ramo ur funcion objeto tipogasto entidad {
			capture confirm string variable `v', exact
			if _rc == 0 {
				quietly count if anio == `a' & ramo != "-1" & trim(`v') != ""
			}
			else {
				quietly count if anio == `a' & ramo != "-1" & `v' != .
			}
			local c_`v' = cond(`n' > 0, r(N)/`n'*100, 100)
		}
		quietly replace `okramo' = 1 if anio == `a' & ramo == "-1"
		quietly count if anio == `a' & `okramo' == 0
		local ramomal = r(N)

		local gasto = 0
		foreach v in aprobado ejercido proyecto {
			capture confirm variable `v', exact
			if _rc == 0 {
				quietly summarize `v' if anio == `a', meanonly
				local gasto = max(`gasto', r(sum))
			}
		}

		noisily di in g "  " in y `a' _col(10) %9.0fc `ntot' _col(22) %7.1f `c_ramo' _col(31) %7.1f `c_ur' ///
			_col(40) %7.1f `c_funcion' _col(49) %7.1f `c_objeto' _col(58) %7.1f `c_tipogasto' ///
			_col(67) %7.1f `c_entidad' _col(76) %10.2f `gasto'/1e12

		if `gasto' <= 0 {
			noisily di as error "    -> `a': sin gasto (aprobado/ejercido/proyecto suman 0)."
			local ++fallas
		}
		if `ramomal' > 0 {
			noisily di as error "    -> `a': `ramomal' filas con ramo no reconocido:"
			noisily levelsof ramo if anio == `a' & `okramo' == 0, clean
			local ++fallas
		}
		if `cuotas' {
			continue
		}
		foreach v in ramo ur funcion objeto tipogasto entidad {
			if `c_`v'' < 99.5 {
				noisily di as error "    -> `a': cobertura de `v' = `: di %5.1f `c_`v''' %."
				local ++fallas
			}
		}
		quietly count if anio == `a' & ramo != "-1" & !ustrregexm(modalidad, "^[a-z]$")
		if r(N) > 0 {
			noisily di as error "    -> `a': `r(N)' filas con modalidad que no es una letra."
			local ++fallas
		}
		quietly count if anio == `a' & ramo != "-1" & !(inrange(entidad, 1, 34) | entidad == .)
		if r(N) > 0 {
			noisily di as error "    -> `a': `r(N)' filas con entidad fuera de 1-34."
			local ++fallas
		}
		quietly count if anio == `a' & ramo != "-1" & !inrange(finalidad, 1, 4)
		if r(N) > 0 {
			noisily di as error "    -> `a': `r(N)' filas con finalidad fuera de 1-4."
			local ++fallas
		}
		quietly count if anio == `a' & ramo != "-1" & !(strpos(desc_tipogasto, "gasto corriente") == 1 ///
			| strpos(desc_tipogasto, "gasto de capital") == 1 | strpos(desc_tipogasto, "gasto de inversión") == 1 ///
			| strpos(desc_tipogasto, "gasto de obra") == 1 | desc_tipogasto == "participaciones" ///
			| desc_tipogasto == "pensiones y jubilaciones" | desc_tipogasto == "")
		if r(N) > 0 {
			noisily di as error "    -> `a': `r(N)' filas con desc_tipogasto no reconocido:"
			noisily levelsof desc_tipogasto if anio == `a' & ramo != "-1" & !(strpos(desc_tipogasto, "gasto corriente") == 1 ///
				| strpos(desc_tipogasto, "gasto de capital") == 1 | strpos(desc_tipogasto, "gasto de inversión") == 1 ///
				| strpos(desc_tipogasto, "gasto de obra") == 1 | desc_tipogasto == "participaciones" ///
				| desc_tipogasto == "pensiones y jubilaciones" | desc_tipogasto == ""), clean
			local ++fallas
		}
	}
	if `fallas' > 0 {
		noisily di as error "ALARMA UpdatePEF: `fallas' regla(s) de comparabilidad intertemporal fallaron (ver arriba)."
		error 459
	}
	noisily di in g "  Comparabilidad intertemporal: " in y "OK" in g "."
end
