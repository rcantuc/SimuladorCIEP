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
		
		* Busca la posici�n de > en el string name, si existe el s�mbolo, el nombre cambia \
		* al substring que termina en la posici�n*
		
		local pos = strpos("`name'",">")
		if `pos' > 0 {
			local name = substr("`name'",1,`pos')
		}
		local name = reverse("`name'")
		
		* Limpia el nombre de s�mbolos *
		
		local name = subinstr("`name'",">","",.)
		local name = subinstr("`name'","r1","",.)
		local name = subinstr("`name'","p1","",.)
		local name = subinstr("`name'","/","",.)
		
		* Acentos *
		local name = subinstr("`name'","‡","{c a'}",.)
		local name = subinstr("`name'","Ž","{c e'}",.)
		local name = subinstr("`name'","’","{c i'}",.)
		local name = subinstr("`name'","—","{c o'}",.)
		local name = subinstr("`name'","œ","{c u'}",.)
		local name = subinstr("`name'","ç","{c A'}",.)
		local name = subinstr("`name'","ƒ","{c E'}",.)
		local name = subinstr("`name'","ê","{c I'}",.)
		local name = subinstr("`name'","î","{c O'}",.)
		local name = subinstr("`name'","ò","{c U'}",.)
		
		local name2 = subinstr("`name2'","‡","{c a'}",.)
		local name2 = subinstr("`name2'","Ž","{c e'}",.)
		local name2 = subinstr("`name2'","’","{c i'}",.)
		local name2 = subinstr("`name2'","—","{c o'}",.)
		local name2 = subinstr("`name2'","œ","{c u'}",.)
		local name2 = subinstr("`name2'","ç","{c A'}",.)
		local name2 = subinstr("`name2'","ƒ","{c E'}",.)
		local name2 = subinstr("`name2'","ê","{c I'}",.)
		local name2 = subinstr("`name2'","î","{c O'}",.)
		local name2 = subinstr("`name2'","ò","{c U'}",.)
		
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
