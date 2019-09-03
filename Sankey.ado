program define Sankey
quietly {

	syntax [, BY(string) Anio(int 2017) id(string)]

	** By **
	if "`by'" == "" {
		local by = "decil"
	}
	if "`id'" == "" {
		local id = "CIEP"
	}




	*******************
	*** 0. Archivos ***
	*******************
	** Directorio **
	capture mkdir "`c(sysdir_personal)'/users"
	capture mkdir "`c(sysdir_personal)'/users/`id'"
	capture mkdir "`c(sysdir_personal)'/users/`id'/Sankey`anio'"
	capture mkdir "`c(sysdir_personal)'/users/`id'/Sankey`anio'/css"

	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/default.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/index.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/SankeyDeciles.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/SankeyEdades.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/SankeyEscolaridad.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/SankeySexos.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/SankeyFormalidad.html" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/"
	capture copy "`c(sysdir_site)'../basesCIEP/Sankeys/Sankey`anio'/css/estilos.css" ///
		"`c(sysdir_personal)'/users/`id'/Sankey`anio'/css/"




	**************
	*** 1. PIB ***
	**************
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




	************************
	*** 2. Base de datos ***
	************************
	use if anio == 2017 using "`c(sysdir_site)'../basesCIEP/SIM/PEF.dta", clear

	g cambio = .
	replace cambio = 1 if ejercido - aprobado > 0
	replace cambio = -1 if ejercido - aprobado < 0
	replace cambio = 0 if ejercido - aprobado == 0

	label define cambio 1 "Aumento" -1 "Disminuyo" 0 "Constante"
	label values cambio cambio

	g cambio2 = .
	replace cambio2 = -1 if ejercido - aprobado > 0
	replace cambio2 = 1 if ejercido - aprobado < 0
	replace cambio2 = 0 if ejercido - aprobado == 0
	label values cambio2 cambio


	** Base de datos **/
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
	** 5.1 Ingresos **
	use `database', clear
	local from "ramo"
	local to "cambio"


	** Collapse **
	*replace profile = -profile if account == "ahorro"
	collapse (sum) profile=aprobado if `to' != . & `from' != ., by(`from' `to') fast
	gsort `to' `from'
	format profile %20.0fc


	** Nodes and Flows **
	forvalues k=1(1)`=_N' {
		* FROM Nodes *
		local faccountname : label (`from') `=`from'[`k']'
		local faccountname = subinstr("`faccountname'"," ","_",.)
		local faccountname = substr("`faccountname'",1,20)
		local faccountname = strtoname("`faccountname'")
		capture confirm existence `node`faccountname''

		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
			local node`faccountname' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		local taccountname = substr("`taccountname'",1,20)
		local taccountname = strtoname("`taccountname'")
		capture confirm existence `node`taccountname''

		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			if `to'[`k'] == -1 {
				local color "one"
			}
			if `to'[`k'] == 0 {
				local color "two"
			}
			if `to'[`k'] == 1 {
				local color "three"
			}
			if `to'[`k'] == 4 {
				local color "two"
			}
			if `to'[`k'] == 5 {
				local color "three"
			}
			if `to'[`k'] == 6 {
				local color "three"
			}
			if `to'[`k'] == 7 {
				local color "three"
			}
			if `to'[`k'] == 8 {
				local color ""
			}
			if `to'[`k'] == 9 {
				local color ""
			}
			if `to'[`k'] == 99 {
				local color "five"
			}

			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
			local node`taccountname' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`taccountname'',"value":`=profile[`k']',"source":`node`faccountname''},"'
		}
	}



	**********************/
	** 4.2 Sectores OUT **
	use `database', clear
	local from "cambio2"
	local to "ramo_tipo"


	** Collapse **
	collapse (sum) profile=ejercido if `to' != . & `from' != ., by(`from' `to') fast
	format profile %20.0fc


	** Nodes and Flows **
	forvalues k=1(1)`=_N' {
		* FROM Nodes *
		local faccountname : label (`from') `=`from'[`k']'
		local faccountname = subinstr("`faccountname'"," ","_",.)
		local faccountname = substr("`faccountname'",1,20)
		local faccountname = strtoname("`faccountname'")
		capture confirm existence `node`faccountname''
		
		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
			local node`faccountname' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		local taccountname = substr("`taccountname'",1,20)
		local taccountname = strtoname("`taccountname'")
		capture confirm existence `node`taccountname''
		
		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
			local node`taccountname' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`taccountname'',"value":`=profile[`k']',"source":`node`faccountname''},"'
		}
	}



	*********************/
	/** 4.3 Sectores IN **
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
		
		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
			local node`=strtoname("`faccountname'")' = `number'
			local ++number
		}

		* TO Nodes *
		local taccountname : label (`to') `=`to'[`k']'
		local taccountname = subinstr("`taccountname'"," ","_",.)
		capture confirm existence `node`=strtoname("`taccountname'")''

		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			if `to'[`k'] == 1 {
				local color "one"
			}
			if `to'[`k'] == 2 {
				local color "one"
			}
			if `to'[`k'] == 3 {
				local color "one"
			}
			if `to'[`k'] == 4 {
				local color "one"
			}
			if `to'[`k'] == 5 {
				local color "one"
			}
			if `to'[`k'] == 6 {
				local color "two"
			}
			if `to'[`k'] == 7 {
				local color "three"
			}
			if `to'[`k'] == 8 {
				local color "three"
			}
			if `to'[`k'] == 9 {
				local color "five"
			}
			if `to'[`k'] == 0 {
				local color "four"
			}
			if `to'[`k'] == 98 {
				local color "five"
			}

			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
			local node`=strtoname("`taccountname'")' = `number'
			local ++number
		}

		if profile[`k'] != 0 {
			local links `"`links'{"target":`node`=strtoname("`taccountname'")'',"value":`=profile[`k']',"source":`node`=strtoname("`faccountname'")''},"'
		}
	}



	*****************/
	/** 4.4 Consumo **
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

		local color ""
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

		local color ""
		if _rc != 0 & profile[`k'] != 0 {
			tabstat profile if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
			tempname profile
			matrix `profile' = r(StatTotal)

			local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`PIB'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
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
	filefilter `sankey3' "`c(sysdir_personal)'/users/`id'/Sankey`anio'/`by'.json", from(".,") to("0") replace
}
end



program define Asignacion
	args var macro recuso

	tempvar `var'TOT
	egen double ``var'TOT' = sum(`var') if factor_hog != 0
	g double `recuso'_`var' = `var'/``var'TOT'*`macro'/factor_hog if factor_hog != 0
end
