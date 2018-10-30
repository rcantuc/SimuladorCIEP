program define Sankey
quietly {




	*******************
	*** 0. Defaults ***
	*******************
	syntax [, BY(string) Anio(int $anioVP ) BIE id(string)]


	** By **
	if "`by'" == "" {
		local by = "decil"
	}


	** Directorio **
	capture mkdir "`c(sysdir_personal)'/users/`id'/Sankey`anio'"
	capture mkdir "`c(sysdir_personal)'/users/`id'/Sankey`anio'/css"

	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/default.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/index.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/SankeyDeciles.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/SankeyEdades.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/SankeyEscolaridad.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/SankeySexos.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/SankeyFormalidad.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_personal)'/bases/Sankeys/Sankey`anio'/css/estilos.css" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/css/"
	local results "`c(sysdir_personal)'/users/`id'/Sankey`anio'/"



	**************************
	*** 1. Politica Fiscal ***
	**************************
	SCN, anio(`anio') `update'
	local PIB = r(PIB)

	if `anio' >= 2016 {
		local enighanio = 2016
	}

	if `anio' == 2015 {
		local enighanio = 2014
	}

	if `anio' == 2014 {
		local enighanio = 2014
	}

	if `anio' == 2013 {
		local enighanio = 2012
	}

	use "`c(sysdir_personal)'/users/`id'/Sankey`anio'.dta", clear




	***********************************
	*** 2. Cuentas y transferencias ***
	***********************************
	egen double rec_tot = rsum(rec_*) 
	egen double uso_tot = rsum(uso_*)

	tabstat rec_tot uso_tot [aw=factor_hog], stat(sum) f(%20.0fc)


	** Lifecycle, deficit y superavit **
	g double lifecycle = rec_tot - uso_tot
	g double surplus = rec_tot - uso_tot if uso_tot < rec_tot
	g double deficit = uso_tot - rec_tot if uso_tot > rec_tot

	tabstat lifecycle surplus deficit [aw=factor_hog], stat(sum) f(%20.0fc)


	** Total por hogar **
	egen double hog_surplus = sum(surplus), by(folioviv foliohog)
	egen double hog_deficit = sum(deficit), by(folioviv foliohog)
	g double hog_tax = hog_deficit/hog_surplus*100

	tabstat hog_surplus hog_deficit [aw=factor_hog], stat(sum) f(%20.0fc)


	** Ahorros o desahorros **
	g double hog_desahorro = hog_deficit - hog_surplus if hog_deficit >= hog_surplus
	g double hog_ahorro = hog_surplus - hog_deficit if hog_deficit < hog_surplus

	g double ing_desahorro = surplus*(hog_tax/100-1) if hog_tax > 100
	replace ing_desahorro = deficit if hog_tax == . 
	replace ing_desahorro = 0 if ing_desahorro == .

	g double cons_ahorro = surplus*(1-hog_tax/100) if hog_tax <= 100
	replace cons_ahorro = 0 if cons_ahorro == .

	tabstat cons_ahorro ing_desahorro [aw=factor_hog], stat(sum) f(%20.0fc)


	** Transferencias intra-hogar **
	g trans_intra_in = deficit if hog_tax != .
	replace trans_intra_in = 0 if trans_intra_in == .

	g trans_intra_out = surplus + ing_desahorro - cons_ahorro
	replace trans_intra_out = 0 if trans_intra_out == .

	tabstat trans_intra_in trans_intra_out [aw=factor_hog], stat(sum) f(%20.0fc)


	** Collapse **
	tabstat rec_tot uso_tot trans_* [aw=factor_hog], by(`by') stat(sum) f(%20.0fc)
	collapse (sum) rec_* uso_* trans_* [fw=factor_hog], by(`by') fast


	** Reshape **
	reshape long rec_ uso_ trans_, i(`by') j(account) string
	rename (rec_ uso_ trans_) (recursos usos transfers)


	** Profile **
	egen double profile = rsum(recursos usos transfers)
	replace profile = -profile if account == "intra_out"
	format rec* uso* profile %20.0fc




	*****************
	*** 4. Labels ***
	*****************
	label define resources ///
		1 "Impuestos ingreso" ///
		2 "Impuestos consumo" ///
		3 "Impuestos al capital" ///
		4 "Otros" ///
		5 "IMSS, ISSSTE (sin cuotas)" ///
		6 "Pemex, CFE" ///
		7 "FMP"

	g resources = real(substr(account,-1,1)) if recursos != .
	label values resources resources

	label define uses ///
		1 "Pensiones" ///
		2 "Educacion" ///
		3 "Salud" ///
		4 "Infraestructura" ///
		5 "Gobierno" ///
		6 "_Otros" ///
		7 "_Pemex, CFE" ///
		8 "Transfs. subnacionales" ///
		9 "Costo de la deuda" ///
		0 "Ingreso basico"
	
	g uses = real(substr(account,-1,1)) if usos != .
	label values uses uses

	

	** Grupos **
	if "`by'" == "decil" {
		g grupo = 1 if decil <= 2
		replace grupo = 2 if decil >= 3 & decil <= 5
		replace grupo = 3 if decil >= 6 & decil <= 8
		replace grupo = 4 if decil >= 9

		label define grupo 1 "I-II" 2 "III-V" 3 "VI-VIII" 4 "IX-X"
		label define grupo2 1 "_I-II" 2 "_III-V" 3 "_VI-VIII" 4 "_IX-X"
	}
	if "`by'" == "sexo" {
		g grupo = 1 if sexo == "1"
		replace grupo = 2 if sexo == "2"

		label define grupo 1 "Hombres" 2 "Mujeres"
		label define grupo2 1 "_Hombres" 2 "_Mujeres"
	}
	if "`by'" == "edad" {
		g grupo = 1 if edad <= 17
		replace grupo = 2 if edad >= 18 & edad <= 37
		replace grupo = 3 if edad >= 38 & edad <= 64
		replace grupo = 4 if edad >= 65

		label define grupo 1 "0-17" 2 "18-37" 3 "38-64" 4 "65+"
		label define grupo2 1 "__0-17" 2 "__18-37" 3 "__38-64" 4 "__65+"
	}
	if "`by'" == "escol" {
		g grupo = 1 if escol == 0
		replace grupo = 2 if escol == 1
		replace grupo = 3 if escol == 2
		replace grupo = 4 if escol == 3
		replace grupo = 5 if escol == 4

		label define grupo 1 "Ninguna" 2 "Basica" 3 "Media Superior" 4 "Superior" 5 "Posgrado"
		label define grupo2 1 "_Ninguna" 2 "_Basica" 3 "_Media Superior" 4 "_Superior" 5 "_Posgrado"
	}
	if "`by'" == "formal" {
		g grupo = 1 if formal != 0
		replace grupo = 2 if formal == 0

		label define grupo 1 "Formal" 2 "Informal"
		label define grupo2 1 "_Formal" 2 "_Informal"
	}
	label define grupo 96 "Estados y municipios" 97 "Empresas" 98 "Futuro" 99 "No distribuible", add
	label define grupo2 96 "_Estados y municipios" 97 "_Empresas" 98 "_Futuro" 99 "_No distribuible", add
	label values grupo grupo


	** Reorganizaci${o}n de los grupos: Recursos **
	replace grupo = 97 if account == "ISR__PM3" | /*account == "FMP7" ///
		|*/ account == "CFE_PM6" | account == "CuotasP1" | account == "Pemex6" | account == "IMSSISSSTE5"
	replace grupo = 99 if account == "Otros4"


	** Reorganizaci${o}n de los grupos: Usos **
	g grupo2 = grupo
	replace grupo2 = 97 if account == "Pemex_resto7" | account == "CFE_resto7"
	replace grupo2 = 99 if account == "neto_Transfe8"
	replace grupo2 = 99 if account == "neto_Transac9"
	replace grupo2 = 99 if account == "neto_Otros__6"
	label values grupo2 grupo2



	**************
	** Sectores **
	**************
	g sector = 2 if recursos != .
	label define sector 1 "Intra-hogar" 2 "`anio'"
	label values sector sector

	g sector2 = 2 if uses != .
	label values sector2 sector



	***************************************
	** Ahorro, deuda, deficit, superavit **
	***************************************
	tabstat profile if sector != . & account != "tot", stat(sum) f(%20.0fc) save
	tempname SEC1
	matrix `SEC1' = r(StatTotal)

	tabstat profile if sector2 != . & account != "tot", stat(sum) f(%20.0fc) save
	tempname SEC2
	matrix `SEC2' = r(StatTotal)

	set obs `=_N+1'
	if `SEC2'[1,1] >`SEC1'[1,1] {
		replace grupo = 98 in -1

		replace profile = `SEC2'[1,1]-`SEC1'[1,1] in -1 
		replace resources = 99 in -1
		label define resources 99 "Endeudamiento", add
		*label define resources 99 "Desahorro", add

		replace sector = 2 in -1
	}

	if `SEC2'[1,1] <`SEC1'[1,1] {
		replace grupo2 = 98 in -1

		replace profile = `SEC1'[1,1]-`SEC2'[1,1] in -1 
		replace uses = 99 in -1
		label define uses 99 "Superavit", add
		*label define uses 99 "Ahorro", add

		replace sector2 = 2 in -1
	}


	** Base de datos **
	tempfile database
	save `database'	




	*****************
	*** 5. Sankey ***
	*****************
	local number = 0

	* Log file *
	tempfile sankey
	capture quietly log using `sankey', replace text name(sankey`by')
	noisily di in g "{"



	******************
	** 4.1 Ingresos **
	use `database', clear
	local from "grupo"
	local to "resources"


	** Collapse **
	replace profile = -profile if account == "ahorro"
	collapse (sum) profile if `to' != . & `from' != ., by(`from' `to') fast
	gsort `to' `from'
	format profile %20.0fc


	** Nodes and Flows **
	forvalues k=1(1)`=_N' {
		* FROM Nodes *
		local faccountname : label (`from') `=`from'[`k']'
		local faccountname = subinstr("`faccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`faccountname'")''

		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`faccountname'")' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`taccountname'")''

		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			if `to'[`k'] == 1 {
				local id "one"
			}
			if `to'[`k'] == 2 {
				local id "one"
			}
			if `to'[`k'] == 3 {
				local id "three"
			}
			if `to'[`k'] == 4 {
				local id "two"
			}
			if `to'[`k'] == 5 {
				local id "three"
			}
			if `to'[`k'] == 6 {
				local id "three"
			}
			if `to'[`k'] == 7 {
				local id "three"
			}
			if `to'[`k'] == 8 {
				local id ""
			}
			if `to'[`k'] == 9 {
				local id ""
			}
			if `to'[`k'] == 99 {
				local id "five"
			}

			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`taccountname'")' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`=strtoname("`taccountname'")'',"value":`=profile[`k']',"source":`node`=strtoname("`faccountname'")''},"'
		}
	}



	**********************/
	** 4.2 Sectores OUT **
	use `database', clear
	local from "resources"
	local to "sector"


	** Collapse **
	collapse (sum) profile if `to' != . & `from' != ., by(`from' `to') fast
	format profile %20.0fc


	** Nodes and Flows **
	forvalues k=1(1)`=_N' {
		* FROM Nodes *
		local faccountname : label (`from') `=`from'[`k']'
		local faccountname = subinstr("`faccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`faccountname'")''
		
		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`faccountname'")' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`taccountname'")''
		
		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`taccountname'")' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`=strtoname("`taccountname'")'',"value":`=profile[`k']',"source":`node`=strtoname("`faccountname'")''},"'
		}
	}



	*********************/
	** 4.3 Sectores IN **
	use `database', clear
	local from "sector2"
	local to "uses"


	** Collapse **
	collapse (sum) profile if `to' != . & `from' != ., by(`from' `to') fast
	format profile %20.0fc


	** Nodes and Flows **
	forvalues k=1(1)`=_N' {
		* FROM Nodes *
		local faccountname : label (`from') `=`from'[`k']'
		local faccountname = subinstr("`faccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`faccountname'")''
		
		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`faccountname'")' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`taccountname'")''

		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			if `to'[`k'] == 1 {
				local id "one"
			}
			if `to'[`k'] == 2 {
				local id "one"
			}
			if `to'[`k'] == 3 {
				local id "one"
			}
			if `to'[`k'] == 4 {
				local id "one"
			}
			if `to'[`k'] == 5 {
				local id "one"
			}
			if `to'[`k'] == 6 {
				local id "two"
			}
			if `to'[`k'] == 7 {
				local id "three"
			}
			if `to'[`k'] == 8 {
				local id "three"
			}
			if `to'[`k'] == 9 {
				local id "five"
			}
			if `to'[`k'] == 0 {
				local id "four"
			}
			if `to'[`k'] == 98 {
				local id "five"
			}

			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`taccountname'")' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`=strtoname("`taccountname'")'',"value":`=profile[`k']',"source":`node`=strtoname("`faccountname'")''},"'
		}
	}



	*****************/
	** 4.4 Consumo **
	use `database', clear
	local from "uses"
	local to "grupo2"


	** Collapse **
	replace profile = -profile if account == "desahorro"
	collapse (sum) profile if `to' != . & `from' != ., by(`from' `to') fast
	gsort `to' `from'
	format profile %20.0fc


	** Nodes and Flows **
	forvalues k=1(1)`=_N' {
		* FROM Nodes *
		local faccountname : label (`from') `=`from'[`k']'
		local faccountname = subinstr("`faccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`faccountname'")''

		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`from'"},"'
			local node`=strtoname("`faccountname'")' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`taccountname'")''

		local id ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`id'"},"'
			local node`=strtoname("`taccountname'")' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`=strtoname("`taccountname'")'',"value":`=profile[`k']',"source":`node`=strtoname("`faccountname'")''},"'
		}
	}




	***************/
	*** 5 OUTPUT ***
	****************
	noisily di in g `""nodes": [ `=substr(`"`nodes'"',1,`=strlen(`"`nodes'"')'-1)'], "'
	noisily di in g `""links": [ `=substr(`"`links'"',1,`=strlen(`"`links'"')'-1)']"' "}"
	capture quietly log close sankey`by'

	tempfile sankey1 sankey2 sankey3
	if "`=c(os)'" == "Windows" {
		filefilter `sankey' `sankey1', from(\r\n>) to("") replace		// Windows
	}
	else {
		filefilter `sankey' `sankey1', from(\n>) to("") replace			// Mac & Linux
	}
	filefilter `sankey1' `sankey2', from(" ") to("") replace
	filefilter `sankey2' `sankey3', from("_") to(" ") replace
	filefilter `sankey3' "`results'/`by'.json", from(".,") to("0") replace
}
end



program define Asignacion
	args var macro recuso

	tempvar `var'TOT
	egen double ``var'TOT' = sum(`var') if factor_hog != 0
	g double `recuso'_`var' = `var'/``var'TOT'*`macro'/factor_hog if factor_hog != 0
end
