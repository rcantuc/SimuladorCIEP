program define Sankey
quietly {

	syntax anything using [, Anio(int 2018) id(string) PROFile(string)]



	noisily di _newline(3) in g "{bf: Sankey}: " in y "`anio'"



	**************
	*** 1. PIB ***
	**************
	if `anio' >= 2018 {
		local enighanio = 2018
	}

	if `anio' == 2016 {
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
	use `using', clear

	

	
	
	*******************
	*** 3. Log file ***
	*******************
	tempfile sankey
	capture quietly log using `sankey', replace text name(sankey`1')
	noisily di in g "{"





	***************
	*** 4. Ejes ***
	local totalprofiles = wordcount("`profile'")
	local total = wordcount("`anything'")

	tokenize `profile'
	forvalues k = 1(1)`totalprofiles' {
		local p`k' = "``k''"
	}

	tokenize `anything'

	local variable = 1
	local number = 0
	local color_num = 1
	while `variable' <= `total' {

		if `variable' < `total' {
			local from "``variable''"
			local to "``=`variable'+1''"
		}
		if `variable' == `total' {
			local from "``variable''"
			local to "`1'"
			local ultimo = "ultimo"
			continue, break
		}

		** Collapse **
		preserve
		collapse (sum) `profile' [fw=factor], by(`from' `to') fast
		gsort `to' `from'

		
		** Sankey data **
		forvalues w=1(1)`totalprofiles' {

			** Nodes and Flows **
			forvalues k=1(1)`=_N' {

				* FROM Nodes *
				local faccountname : label (`from') `=`from'[`k']'
				local faccountname = subinstr("`faccountname'"," ","_",.)
				local faccountname = substr("`faccountname'",1,20)
				local faccountname = strtoname("`faccountname'")
				if "`ultimo'" == "ultimo" {
					*local faccountname = "_`faccountname'"
				}
				capture confirm existence `node`faccountname''

				local color ""

				if _rc != 0 & `p`w''[`k'] != 0 {
					tabstat `p`w'', stat(sum) f(%20.0fc) save
					tempname ptotal
					matrix `ptotal' = r(StatTotal)

					tabstat `p`w'' if `from' == `=`from'[`k']', stat(sum) f(%20.0fc) save
					tempname `p`w''
					matrix ``p`w''' = r(StatTotal)

					local nodes `"`nodes'{"name":"`faccountname':_`=string(`=``p`w'''[1,1]/`ptotal'[1,1]*100',"%5.1fc")'%","id":"`color'"},"'
					local node`faccountname' = `number'
					local ++number
				}

				* TO Nodes *
				local taccountname : label (`to') `=`to'[`k']'
				local taccountname = subinstr("`taccountname'"," ","_",.)
				local taccountname = substr("`taccountname'",1,20)
				local taccountname = strtoname("`taccountname'")
				if "`ultimo'" == "ultimo" {
					local taccountname = "_`taccountname'"
				}
				capture confirm existence `node`taccountname''

				local color ""
				if _rc != 0 & `p`w''[`k'] != 0 {
					if `color_num' == 1 {
						local color = "one"
					}
					if `color_num' == 2 {
						local color = "two"
					}
					if `color_num' == 3 {
						local color = "three"
					}
					if `color_num' == 4 {
						local color = "four"
					}
					if `color_num' == 5 {
						local color = "five"
					}
					if `color_num' == 6 {
						local color = "six"
					}
					if `color_num' == 7 {
						local color = "seven"
					}
					if `color_num' == 8 {
						local color = "eight"
					}
					if `color_num' == 9 {
						local color = "nine"
					}
					if `color_num' == 10 {
						local color = "nine"
					}
					if `color_num' == 11 {
						local color = "eleven"
					}
					if `color_num' == 12 {
						local color = "twelve"
					}
					if `color_num' == 13 {
						local color = "thirteen"
					}
					if `color_num' == 14 {
						*local color = "fourteen"
					}
					if `color_num' == 15 {
						*local color = "fifteen"
					}
					if `color_num' == 16 {
						*local color = "sixteen"
					}
		
					local ++color_num
				
					tabstat `p`w'', stat(sum) f(%20.0fc) save
					tempname ptotal
					matrix `ptotal' = r(StatTotal)

					tabstat `p`w'' if `to' == `=`to'[`k']', stat(sum) f(%20.0fc) save
					tempname `p`w''
					matrix ``p`w''' = r(StatTotal)

					local nodes `"`nodes'{"name":"`taccountname':_`=string(`=``p`w'''[1,1]/`ptotal'[1,1]*100',"%5.1fc")'%","id":"`color'"},"'
					local node`taccountname' = `number'
					local ++number
				}

				if `p`w''[`k'] != 0 {
					local links `"`links'{"target":`node`taccountname'',"value":`=`p`w''[`k']',"source":`node`faccountname''},"'
				}
			}				
		}
		restore
		local ++variable
	}




	***************/
	*** 5 OUTPUT ***
	****************
	noisily di in g `""nodes": [ `=substr(`"`nodes'"',1,`=strlen(`"`nodes'"')'-1)'], "'
	noisily di in g `""links": [ `=substr(`"`links'"',1,`=strlen(`"`links'"')'-1)']"' "}"
	capture quietly log close sankey`1'

	tempfile sankey1 sankey2 sankey3
	if "`=c(os)'" == "Windows" {
		filefilter `sankey' `sankey1', from(\r\n>) to("") replace		// Windows
	}
	else {
		filefilter `sankey' `sankey1', from(\n>) to("") replace			// Mac & Linux
	}
	filefilter `sankey1' `sankey2', from(" ") to("") replace
	filefilter `sankey2' `sankey3', from("_") to(" ") replace
	filefilter `sankey3' "/Applications/XAMPP/xamppfiles/htdocs/v5/Sankey2018/Poblacion.json", from(".,") to("0") replace
}
end
