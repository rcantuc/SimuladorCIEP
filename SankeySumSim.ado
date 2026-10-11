program define SankeySumSim
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
quietly {

	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax, A(string) NAME(string) ///
		[B(string) C(string) D(string) E(string) ANIO(int `aniovp') FOLDER(string) META(string)]
	* folder(): subcarpeta de users/$id/ para el JSON (entidad, 2026-10-10: users/$id/<ABREV>/);
	*   vacía = users/$id/sankey-<name>.json, byte-idéntico a antes.
	* meta(): fragmento JSON "clave:{...}" que se inserta en dataSource después de chart
	*   (FusionCharts ignora las claves que no conoce); sin espacios: el filtro de abajo
	*   los borra y convierte "_" en espacio, como en nodos y enlaces.
	* Variables j_* en los ejes (entidad): cada una viaja como campo del enlace sin el
	*   prefijo (j_n -> n, j_top1 -> top1, j_sello -> sello, j_bmin/j_bmax -> banda,
	*   j_v<t> -> valor con el vintage ENIGH <t>); los valores perdidos no se escriben.

	*PIBDeflactor, anio(`anio') nographs nooutput


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
		local jvars ""
		capture quietly ds j_*
		if _rc == 0 local jvars "`r(varlist)'"

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
				local extra ""
				foreach v of local jvars {
					if `v'[`k'] != . local extra `"`extra',`=substr("`v'",3,.)':"`=`v'[`k']'""'
				}
				local links `"`links'{to:"``node`taccountname'''",value:"`=profile[`k']'",from:"``node`faccountname'''"`extra'},"'
			}
		}
	}



	***************/
	*** 5 OUTPUT ***
	****************
	noisily di in w "$" `"(document).ready(function()_{const_dataSource={chart:{caption:"",subcaption:"",theme:"fusion",orientation:"horizontal",linkalpha:30,linkhoveralpha:60,nodelabelposition:"start",showLegend:0},"'
	if `"`meta'"' != "" noisily di in w `"`meta',"'
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
	//if "`c(os)'" == "MacOSX" {
	//	filefilter `sankey3' "/Applications/XAMPP/xamppfiles/htdocs/`folder'/sankey-`name'.json", from(".,") to("0") replace
	//}
	//if "`c(os)'" == "Unix" & "`c(username)'" != "root" {
	//	filefilter `sankey3' `"/var/www/html/`folder'/sankey-`name'.json"', from(".,") to("0") replace
	//}
	//if "`c(os)'" == "Unix" & "`c(username)'" == "root" {
		local dest `"${SIMROOT}/users/$id"'
		if "`folder'" != "" {
			capture mkdir `"`dest'/`folder'"'
			local dest `"`dest'/`folder'"'
		}
		filefilter `sankey3' `"`dest'/sankey-`name'.json"', from(".,") to("0") replace
	//}
}
end
