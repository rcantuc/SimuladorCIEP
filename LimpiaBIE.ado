****************************
****  LIMPIA INEGI BIE  ****
****      SCN, SNA      ****
****************************
program define LimpiaBIE

	syntax [anything] [, NOMultiply]
	drop if B == ""

	foreach k of varlist _all {

		* Nombre *
		local name = reverse(`k'[1])
		local name2 = `k'[2]
		
		local pos = strpos("`name'",">")
		if `pos' > 0 {
			local name = substr("`name'",1,`pos')
		}
		local name = reverse("`name'")

		local name = subinstr("`name'",">","",.)
		local name = subinstr("`name'","r1","",.)
		local name = subinstr("`name'","p1","",.)
		local name = subinstr("`name'","/","",.)
		
		* Acentos *
		local name = subinstr("`name'","‡","${a}",.)
		local name = subinstr("`name'","Ž","${e}",.)
		local name = subinstr("`name'","’","${i}",.)
		local name = subinstr("`name'","—","${o}",.)
		local name = subinstr("`name'","œ","${u}",.)
		local name = subinstr("`name'","ç","${A}",.)
		local name = subinstr("`name'","ƒ","${E}",.)
		local name = subinstr("`name'","ê","${I}",.)
		local name = subinstr("`name'","î","${O}",.)
		local name = subinstr("`name'","ò","${U}",.)
		
		local name2 = subinstr("`name2'","‡","${a}",.)
		local name2 = subinstr("`name2'","Ž","${e}",.)
		local name2 = subinstr("`name2'","’","${i}",.)
		local name2 = subinstr("`name2'","—","${o}",.)
		local name2 = subinstr("`name2'","œ","${u}",.)
		local name2 = subinstr("`name2'","ç","${A}",.)
		local name2 = subinstr("`name2'","ƒ","${E}",.)
		local name2 = subinstr("`name2'","ê","${I}",.)
		local name2 = subinstr("`name2'","î","${O}",.)
		local name2 = subinstr("`name2'","ò","${U}",.)
		
		* Trim *
		local name = trim("`name'")
		local name = itrim("`name'")

		local name2 = trim("`name2'")
		local name2 = itrim("`name2'")
		
		* Nombre final *
		replace `k' = "`name', `name2'" in 1
		
		* Label *
		label var `k' "`=`k'[1]'"
		
		* Periodo *
		replace `k' = subinstr(`k',"p/","",.)
		replace `k' = subinstr(`k',"r/","",.)
		replace `k' = subinstr(`k',"ND","",.)
	}

	drop in 1
	drop if A == ""
	destring _all, replace	
	
	* Pesos *
	if "`nomultiply'" == "" {
		foreach k of varlist _all {
			local label : var label `k'
			if `"`=substr("`label'",1,7)'"' != "Periodo" {
				replace `k' = `k'*1000000
				format `k' %20.0fc
				recast double `k'
			}
		}
	}

	* Rename *
	foreach k of varlist _all {
		local label : var label `k'
		if `"`=substr("`label'",1,7)'"' != "Periodo" {
			rename `k' `k'`anything'
		}
	}	

	compress
end
