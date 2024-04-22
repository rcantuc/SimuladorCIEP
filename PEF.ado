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
		noisily UpdatePEF
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
		BY(varname) ROWS(int 2) COLS(int 5) MINimum(real 1) ///
		PEF PPEF APROBado DESDE(int `=`aniovp'-1') ///
		TITle(string) SUBTitle(string)]

	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: GASTOS $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput
	local currency = currency[1]
	tempfile PIB
	save "`PIB'"

	** 2.2 Update PEF **
	if "`update'" == "update" {
		noisily UpdatePEF
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

	** 2.4 Etiquetas abreviadas **
	label define ramo 7 "SEDENA", modify
	label define ramo 19 "Aportaciones a Seg Soc", modify
	label define ramo 33 "Aportaciones federales", modify
	label define ramo 47 "No sectorizadas", modify
	label define ramo 50 "IMSS", modify
	label define ramo 51 "ISSSTE", modify
	label define ramo 52 "Pemex", modify
	label define ramo 53 "CFE", modify



	***************
	*** 3 Merge ***
	***************
	collapse (sum) gasto*, by(anio `by' transf_gf) fast
	merge m:1 (anio) using "`PIB'", nogen keepus(pibY indiceY deflator lambda Poblacion) keep(matched) sorted
	forvalues k=1(1)`=_N' {
		if gasto[`k'] != . & "`first'" != "first" { 
			local aniofirst = 2014 //anio[`k']
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


	****************************
	** 4.2. Division Resumido **
	noisily di _newline in g "{bf: B. Gasto bruto (Resumido) " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "Dif% Real" "}"

	collapse (sum) gasto* if transf_gf == 0, by(anio pibY deflator lambda Poblacion `resumido')
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
		if substr(`"`=r(name`k')'"',1,31) == `"'"' {
			local disptext = substr(`"`=r(name`k')'"',1,30)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,31)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		return scalar `=substr("`name'",1,31)' = `mat`k''[1,1]
		return scalar `=substr("`name'",1,28)'PIB = `mat`k''[1,2]
		return scalar `=substr("`name'",1,31)'C = ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`aniovp'-`desde''))-1)*100
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

			if substr(`"`=r(name`k')'"',1,25) == `"'"' {
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

		/* Ciclo para poner los paréntesis (% del total) en el legend *
		local totlev = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')
			local legend`k' : label labelresumido `k'
			local legend`k' = substr("`legend`k''",1,23)
			local legend = `"`legend' label(`totlev' "`legend`k'' (`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)")"'
		}

		* Ciclo para determinar el orden de mayor a menor, según gastoneto */
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
		if "`title'" == "" {
			local graphtitle "Gasto público"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP."
		}
		else {
			local graphtitle "`title'"
			local graphsubtitle "`subtitle'"
			local graphfuente ""
		}

		graph bar (sum) gastoreal if anio >= `aniofirst' & anio <= `anio', ///
			over(resumido, sort(1) descending) over(anio, gap(0)) stack asyvar ///
			blabel(none, format(%10.1fc)) outergap(0) ///
			bar(9, color(150 6 92)) bar(8, color(53 200 71)) ///
			bar(7, color(255 129 0)) bar(6, color(0 151 201)) ///
			bar(5, color(224 97 83)) bar(4, color(255 189 0)) ///
			bar(3, color(255 55 0)) bar(2, color(57 198 184)) ///
			bar(1, color(211 199 225)) ///
			title("`graphtitle'") ///
			subtitle("`graphsubtitle'") ///
			caption("`graphfuente'") ///
			text(`text', color(black) placement(n) size(small)) ///
			ytitle(mil millones MXN `anio') ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			yscale(range(0)) ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' order(`order')) /// 
			name(gastos`by', replace) ///
			//note("{bf:Nota}: Porcentajes entre par{c e'}ntesis son con respecto al total de `anio'.")

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


*************************
****                 ****
**** UpdatePEF.do    ****
**** De .xlsx a .dta ****
****                 ****
*************************
program define UpdatePEF


	*************************
	***                   ***
	*** 1. BASES DE DATOS ***
	***                   ***
	*************************
	capture confirm file "`c(sysdir_personal)'/SIM/prePEF.dta"
	if _rc != 0 | "`1'" == "update" {
		local archivos: dir "`c(sysdir_site)'../BasesCIEP/PEFs" files "*.xlsx"			// Busca todos los archivos .xlsx en /bases/PEFs/
		*local archivos `""PEF 2024.xlsx" "CuotasISSSTE.xlsx" "'

		foreach k of local archivos {															// Loop para todos los archivos .xlsx encontrados

			* 1.1 Importar el archivo `k'.xlsx (Cuenta Pública) *
			noisily di in g "Importando: " in y "`k'"
			import excel "`c(sysdir_site)'../BasesCIEP/PEFs/`k'", clear firstrow case(lower)

			* 1.2 Limpiar observaciones *
			capture drop if ciclo == ""
			capture drop if ciclo == .
			capture rename ciclo anio

			* 1.3 Limpiar nombres *
			capture rename ejercicio ejercido
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
			}

			* 1.4 Limpiar valores *
			capture drop v*
			foreach j of varlist _all {
				tostring `j', replace													// Primero, que todos sean strings (facilidad)
				capture confirm string variable `k'										// Segundo, comprobar que la variable sea string (no siempre el tostring funciona)
				if _rc == 0 {															// Tercero, si es string, quitar espacios y caracteres especiales
					replace `j' = trim(`j')
					replace `j' = subinstr(`j',`"""',"",.)
					replace `j' = subinstr(`j',"  "," ",.)
					replace `j' = subinstr(`j',"Ê"," ",.)								// <--Algunas CPs tienen este caracter "raro".
					replace `j' = subinstr(`j',"Â","",.)
					replace `j' = subinstr(`j'," "," ",.)
					replace `j' = subinstr(`j'," "," ",.)
					format `j' %30s
				}
				destring `j', replace													// Cuarto, hacer numéricas las variables posibles
			}

			* Quinto, asegurar que las variables de gasto sean numéricas. 
			foreach j in aprobado modificado devengado pagado adefas ejercido proyecto {
				capture destring `j', replace ignore(",") 								// Ignorar las comas
				if _rc == 0 {
					format `j' %20.0fc
					replace `j' = 0 if `j' == .
				}
			}
			capture tostring ramo, replace

			* 1.5 Save *
			tempfile `=strtoname("`k'")'												// strtoname convierte el texto en Stata var_type_name
			save ``=strtoname("`k'")''
		}

		* Sexto, loop para unir los archivos ya limpios y en formato Stata *
		local j = 0
		foreach k of local archivos {
		*foreach k in "CP 2019" {														// <-- Dejar para hacer pruebas
			noisily di in g "Appending: " in y "`k'"
			if `j' == 0 {
				use ``=strtoname("`k'")'', clear
				local ++j
			}
			else {
				append using ``=strtoname("`k'")'', force
			}
		}
		compress





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
		replace desc_ramo = "Tribunal Federal de Justicia Administrativa" if ramo == 32
		replace desc_ramo = "Seguridad y Protección Ciudadana" if ramo == 36
		replace desc_ramo = "Humanidades, Ciencias, Tecnologías e Innovación" if ramo == 38
		replace desc_ramo = "Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales" if ramo == 44
		replace desc_ramo = "Petróleos Mexicanos" if ramo == 52
		replace desc_ramo = "Comisión Federal de Electricidad" if ramo == 53

		labmask ramo, values(desc_ramo)
		drop desc_ramo

		** 2.3 Descripción Entidad Federativa **
		replace desc_entidad = trim(desc_entidad)
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
		foreach k of varlist desc_ur desc_funcion desc_subfuncion desc_ai desc_modalidad desc_pp ///
			desc_objeto desc_tipogasto /*desc_partida_generica*/ {

			rename `k' `k'2
			encode `k'2, g(`k')
			format %30.0fc `k'
			drop `k'2	

			replace `k' = -1 if `k' == .
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

		if `c(version)' > 13.1 {
			saveold "`c(sysdir_personal)'/SIM/prePEF.dta", replace version(13)
		}
		else {
			save "`c(sysdir_personal)'/SIM/prePEF.dta", replace
		}

		* 3.3 Datos Abiertos: PEFEstOpor.dta *
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
		}
	}




	***************************************/
	***                                  ***
	*** 4. Modulos SIMULADOR FISCAL CIEP ***
	***                                  ***
	****************************************
	use "`c(sysdir_personal)'/SIM/prePEF.dta", clear


	** 4.1 Pensiones **
	levelsof desc_pp, local(levelsof)
	foreach k of local levelsof {
		local label : label desc_pp `k'
		if `"`label'"' == "Pensión para Adultos Mayores" | ///
			`"`label'"' == "Pensión para el Bienestar de las Personas Adultas Mayores" | ///
			`"`label'"' == "Pensión para el Bienestar de las Personas con Discapacidad Permanente" {
			local ifpp `"`ifpp'desc_pp == `k' | "'
		}
	}
	local ifpp `"(`=substr("`ifpp'",1,`=strlen("`ifpp'")-3')')"'

	// Pensiones contributivas
	g desc_divCIEP = "Pensiones" if (substr(string(objeto),1,2) == "45" | substr(string(objeto),1,2) == "47")
	g desc_divSIM = desc_divCIEP

	// Pensión para adultos mayores
	replace desc_divCIEP = "Pensión AM" if desc_divCIEP == "" & `ifpp'
	replace desc_divSIM = "Pensiones" if desc_divSIM == "" & `ifpp'


	** 4.2 Salud **
	replace desc_divCIEP = "Salud" if desc_divCIEP == "" & (desc_funcion == 21 | ramo == 12)
	replace desc_divCIEP = "Salud" if desc_divCIEP == "" & (ramo == 50 | ramo == 51) & (pp == 4 | pp == 15) & funcion == 8
	replace desc_divCIEP = "Salud" if desc_divCIEP == "" & ramo == 52 & ai == 231


	** 4.3 Energía **
	replace desc_divCIEP = "Energía" if desc_divCIEP == "" ///
		& (ramo == 18 | ramo == 45 | ramo == 46 | ramo == 52 | ramo == 53 ///
		| (ramo == 23 & desc_funcion == 7))


	** 4.4 Costo de la deuda **
	replace desc_divCIEP = "Costo de la deuda" if desc_divCIEP == "" & capitulo == 9


	** 4.5 Educación **
	replace desc_divCIEP = "Educación" if desc_divCIEP == "" ///
		& (desc_funcion == 10 | ramo == 11 | ramo == 48 | ramo == 38)


	** 4.6 Inversión e Infraestructura **
	replace desc_divCIEP = "Otras inversiones" if desc_divCIEP == "" ///
		& (desc_tipogasto == 4 | desc_tipogasto == 5 | desc_tipogasto == 6 | desc_tipogasto == 8)

	replace desc_divSIM = "Inversión" if (desc_tipogasto == 4 | desc_tipogasto == 5 | desc_tipogasto == 6 | desc_tipogasto == 8)


	** 4.7 Federalizado **
	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (ramo == 28)                                  // Part
	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (ramo == 33 | ramo == 25)                     // Aport

	g desc_divFEDE = "Participaciones" if (ramo == 28)                                                               // Part
	replace desc_divFEDE = "Aportaciones" if (ramo == 33 | ramo == 25)                                               // Aport

	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (objeto == 43801)                             // Convenios descentralizados

	replace desc_divFEDE = "Convenios" if (objeto == 43801 & ramo != 23)                                             // Convenios descentralizados

	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (objeto == 85101)                             // Convenios de reasignación
	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (objeto == 43101 & ramo == 8 & pp == 263 & entidad != 34) // Convenios de reasignación

	replace desc_divFEDE = "Convenios" if (objeto == 85101)                                                          // Convenios de reasignación
	replace desc_divFEDE = "Convenios" if (objeto == 43101 & ramo == 8 & pp == 263 & entidad != 34)                  // Convenios de reasignación

	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (objeto == 46101 & ramo == 23 & pp == 80)     // FEIEF
	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (ramo == 23 & pp == 4 & modalidad == "Y")     // FEIEF
	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (ramo == 23 & pp == 141)                      // FIES

	replace desc_divFEDE = "Subsidios" if (objeto == 46101 & ramo == 23 & pp == 80)                                  // FEIEF
	replace desc_divFEDE = "Subsidios" if (ramo == 23 & pp == 4 & modalidad == "Y")                                  // FEIEF
	replace desc_divFEDE = "Subsidios" if (ramo == 23 & pp == 141)                                                   // FIES
	replace desc_divFEDE = "Subsidios" if (ramo == 23 & objeto == 43801)

	replace desc_divCIEP = "Part y otras Apor" if desc_divCIEP == "" & (pp == 13 & (ramo == 12 | ramo == 47) & modalidad == "U") // INSABI/Seguro Popular/IMSS-Bienestar
	replace desc_divFEDE = "Salud (federalizado)" if (pp == 13 & (ramo == 12 | ramo == 47) & modalidad == "U")         // INSABI/Seguro Popular/IMSS-Bienestar


	** 4.7 Economía de los cuidados **
	replace desc_divSIM = "Cuidados" if (ramo == 11 & pp == 312) | (ramo == 11 & pp == 31) | (ramo == 11 & pp == 66) ///
		| (ramo == 20 & pp == 174) | (ramo == 51 & pp == 48) | (ramo == 50 & pp == 7) ///
		| (ramo == 20 & pp == 241) ///
		| (ramo == 12 & pp == 41) | (ramo == 20 & pp == 3 & ur == "V3A") | (ramo == 33 & pp == 6) ///
		| (ramo == 4 & pp == 12  & ur == "V00") | (ramo == 51 & pp == 42) | (ramo == 12 & pp == 39) ///
		| (ramo == 12 & pp == 40) | (ramo == 11 & pp == 221) | (ramo == 25 & pp == 221) ///
		| (ramo == 51 & subfuncion == 3 & anio <= 2019) | (ramo == 20 & pp == 12 & anio >= 2019 & anio <= 2022)


	** 4.8 Otros **
	replace desc_divCIEP = "Otros gastos" if desc_divCIEP == ""
	replace desc_divFEDE = "No federalizado" if desc_divFEDE == ""
	replace desc_divSIM = desc_divCIEP if desc_divSIM == ""


	** 4.9 Cuotas ISSSTE **
	foreach k in divCIEP divFEDE divSIM {
		replace desc_`k' = "zCuotas ISSSTE" if ramo == -1
		encode desc_`k', generate(`k')
		replace desc_`k' = "Cuotas ISSSTE" if ramo == -1
		replace `k' = -1 if ramo == -1
		label define `k' -1 "Cuotas ISSSTE", add
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

	g byte transf_gf = (ramo == 19 & ur == "GYN") | (ramo == 19 & ur == "GYR")

	g byte noprogramable = ramo == 28 | capitulo == 9
	replace noprogramable = -1 if ramo == -1
	label define noprogramable 1 "No programable" 0 "Programable" -1 "Cuotas ISSSTE"
	label values noprogramable noprogramable

	g byte ineludible = divCIEP == 7 | divFEDE == 4 | ramo == 28 ///
		| capitulo == 9 | (ramo >= 50 & ramo <= 53) | divCIEP == 8
	replace ineludible = -1 if ramo == -1
	*replace ineludible = 2 if divCIEP == 8
	label define ineludible 2 "Programas prioritarios" 1 "Ineludible" 0 "No ineludible" -1 "Cuotas ISSSTE"
	label values ineludible ineludible



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
		saveold "`c(sysdir_personal)'/SIM/PEF.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/PEF.dta", replace
	}
end