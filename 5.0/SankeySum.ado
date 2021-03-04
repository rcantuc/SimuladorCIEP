program define SankeySum
quietly {

	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax, A(string) NAME(string) FOLDER(string) ///
		[B(string) C(string) D(string) E(string) ANIO(int `aniovp')]

	noisily di _newline(2) in g "{bf: Sankey}: " in y "`anio'"
	PIBDeflactor, anio(`anio') nographs


	******************
	*** 1 Log file ***
	******************
	tempfile sankey
	quietly log using `sankey', replace text name(sankey)
	noisily di in g "{"


	**************
	*** 2 Ejes ***
	**************
	local number = 0
	local color_num = 1
	foreach base in `a' `b' `c' `d' `e' {

		use `base', clear

		** Nodes and Flows **
		forvalues k=1(1)`=_N' {

			* FROM Nodes *
			local faccountname : label (from) `=from[`k']'
			local faccountname = substr("`faccountname'",1,20)
			local faccountname = strtoname("`faccountname'")

			capture confirm existence `node`faccountname''

			local color ""
			if _rc != 0 & profile[`k'] != 0 {
				if "`folder'" ==  "SankeySIMC" {
					if `color_num' == 1 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "one"
					}
					if `color_num' == 2 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "two"
					}
					if `color_num' == 3 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "three"
					}
					if `color_num' == 4 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "four"
					}
					if `color_num' == 5 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "five"
					}
					if `color_num' == 6 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "six"
					}
					if `color_num' == 7 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "seven"
					}
					if `color_num' == 8 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "eight"
					}
					if `color_num' == 9 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "nine"
					}
					if `color_num' == 10 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "ten"
					}
					if `color_num' == 11 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "eleven"
					}
					if `color_num' == 12 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "twelve"
					}
					if `color_num' == 13 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "thirteen"
					}
					if `color_num' == 14 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "fourteen"
					}
					if `color_num' == 15 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "fifteen"
					}
					if `color_num' == 16 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "sixteen"
					}
					if `color_num' == 17 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "seventeen"
					}
					if `color_num' == 18 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "eighteen"
					}
					if `color_num' == 19 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "nineteen"
					}
					if `color_num' == 20 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "twenty"
					}
					local ++color_num
				}

				tabstat profile, stat(sum) f(%20.0fc) save
				tempname ptotal
				matrix `ptotal' = r(StatTotal)

				tabstat profile if from == `=from[`k']', stat(sum) f(%20.0fc) save
				tempname profile
				matrix `profile' = r(StatTotal)

				local nodes `"`nodes'{"name":"`faccountname':_`=string(`=`profile'[1,1]/`=scalar(pibY)'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
				local node`faccountname' = `number'
				local ++number
			}


			* TO Nodes *
			local taccountname : label (to) `=to[`k']'
			local taccountname = subinstr("`taccountname'"," ","_",.)
			local taccountname = substr("`taccountname'",1,20)
			local taccountname = strtoname("`taccountname'")
			if "`cycle'" != "" & "`base'" == "`d'" {
				local taccountname = "_`taccountname'"
			}
			capture confirm existence `node`taccountname''

			local color ""
			if _rc != 0 & profile[`k'] != 0 {
				if "`folder'" ==  "SankeySIM" {
					if `color_num' == 1 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "one"
					}
					if `color_num' == 2 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "two"
					}
					if `color_num' == 3 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "three"
					}
					if `color_num' == 4 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "four"
					}
					if `color_num' == 5 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "five"
					}
					if `color_num' == 6 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "six"
					}
					if `color_num' == 7 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "seven"
					}
					if `color_num' == 8 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "eight"
					}
					if `color_num' == 9 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "nine"
					}
					if `color_num' == 10 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "ten"
					}
					if `color_num' == 11 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "eleven"
					}
					if `color_num' == 12 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "twelve"
					}
					if `color_num' == 13 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "thirteen"
					}
					if `color_num' == 14 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "fourteen"
					}
					if `color_num' == 15 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "fifteen"
					}
					if `color_num' == 16 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "sixteen"
					}
					if `color_num' == 17 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "seventeen"
					}
					if `color_num' == 18 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "eighteen"
					}
					if `color_num' == 19 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "nineteen"
					}
					if `color_num' == 20 & ("`base'" == "`a'" | "`base'" == "`c'") {
						local color = "twenty"
					}
					local ++color_num
				}

				tabstat profile, stat(sum) f(%20.0fc) save
				tempname ptotal
				matrix `ptotal' = r(StatTotal)

				tabstat profile if to == `=to[`k']', stat(sum) f(%20.0fc) save
				tempname profile
				matrix `profile' = r(StatTotal)

				local nodes `"`nodes'{"name":"`taccountname':_`=string(`=`profile'[1,1]/`=scalar(pibY)'*100',"%5.1fc")'%_PIB","id":"`color'"},"'
				local node`taccountname' = `number'
				local ++number
			}

			if profile[`k'] != 0 {
				local links `"`links'{"target":`node`taccountname'',"value":`=profile[`k']',"source":`node`faccountname''},"'
			}
		}
	}



	***************/
	*** 5 OUTPUT ***
	****************
	noisily di in g `""nodes": [ `=substr(`"`nodes'"',1,`=strlen(`"`nodes'"')'-1)'], "'
	noisily di in g `""links": [ `=substr(`"`links'"',1,`=strlen(`"`links'"')'-1)']"' "}"
	capture quietly log close sankey

	tempfile sankey1 sankey2 sankey3
	if "`=c(os)'" == "Windows" {
		filefilter `sankey' `sankey1', from(\r\n>) to("") replace		// Windows
	}
	else {
		filefilter `sankey' `sankey1', from(\n>) to("") replace			// Mac & Linux
	}
	filefilter `sankey1' `sankey2', from(" ") to("") replace
	filefilter `sankey2' `sankey3', from("_") to(" ") replace
	if "`c(os)'" == "MacOSX" {
		filefilter `sankey3' "/Applications/XAMPP/xamppfiles/htdocs/`folder'/`name'.json", from(".,") to("0") replace
	}
	if "`c(os)'" == "Unix" {
		filefilter `sankey3' "/var/www/html/`folder'/`name'.json", from(".,") to("0") replace
	}
}
end
