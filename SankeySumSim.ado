program define SankeySumSim
quietly {

	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax, A(string) NAME(string) FOLDER(string) ///
		[B(string) C(string) D(string) E(string) ANIO(int `aniovp')]

	PIBDeflactor, anio(`anio') nographs nooutput


	******************
	*** 1 Log file ***
	******************
	tempfile sankey
	quietly log using `sankey', replace text name(sankey)
	*noisily di in g "{"


	**************
	*** 2 Ejes ***
	**************
	local number = 0
	foreach base in `a' `b' `c' `d' `e' {

		use `base', clear

		** Nodes and Flows **
		forvalues k=1(1)`=_N' {

			* FROM Nodes *
			local faccountname : label (from) `=from[`k']'
			local faccountname = substr("`faccountname'",1,20)
			local faccountname = strtoname("`faccountname'")

			capture confirm existence `node`faccountname''

			if _rc != 0 & profile[`k'] != 0 {
				tabstat profile, stat(sum) f(%20.0fc) save
				tempname ptotal
				matrix `ptotal' = r(StatTotal)

				tabstat profile if from == `=from[`k']', stat(sum) f(%20.0fc) save
				tempname profile
				matrix `profile' = r(StatTotal)

				local nodes `"`nodes'{label:"`faccountname'"},"'
				local node`faccountname' = `number'
				local `node`faccountname'' = "`faccountname'"
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

			if _rc != 0 & profile[`k'] != 0 {
				tabstat profile, stat(sum) f(%20.0fc) save
				tempname ptotal
				matrix `ptotal' = r(StatTotal)

				tabstat profile if to == `=to[`k']', stat(sum) f(%20.0fc) save
				tempname profile
				matrix `profile' = r(StatTotal)

				local nodes `"`nodes'{label:"`taccountname'"},"'
				local node`taccountname' = `number'
				local `node`taccountname'' = "`taccountname'"
				local ++number
			}

			if profile[`k'] != 0 {
				local links `"`links'{to:"``node`taccountname'''",value:"`=profile[`k']/`=scalar(pibY)'*100'",from:"``node`faccountname'''"},"'
			}
		}
	}



	***************/
	*** 5 OUTPUT ***
	****************
	noisily di in w "$" `"(document).ready(function()_{const_dataSource={chart:{caption:"",subcaption:"",theme:"fusion",orientation:"horizontal",linkalpha:30,linkhoveralpha:60,nodelabelposition:"start",showLegend:0},"'
	noisily di in w `"nodes: [ `=substr(`"`nodes'"',1,`=strlen(`"`nodes'"')'-1)'], "'
	noisily di in w `"links: [ `=substr(`"`links'"',1,`=strlen(`"`links'"')'-1)']"' "};"
	noisily di in w `"FusionCharts.ready(function()_{var_myChart=new_FusionCharts({type:"sankey",renderAt:"sankey-`name'",width:"100%",height:"100%",dataFormat:"json",dataSource}).render();});});"'
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
		filefilter `sankey3' "/Applications/XAMPP/xamppfiles/htdocs/`folder'/sankey-`name'.json", from(".,") to("0") replace
	}
	if "`c(os)'" == "Unix" {
		filefilter `sankey3' `"`c(sysdir_personal)'/users/$id/sankey-`name'.json"', from(".,") to("0") replace
		//filefilter `sankey3' `"/var/www/html/`folder'/sankey-`name'.json"', from(".,") to("0") replace
	}

}
end
