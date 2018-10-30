program define scalarlatex

	syntax [, Logname(string)]

	capture log off overall
	
	* Scalar list *
	noisily di _newline(3) in g "{bf:LaTeX scalar list}"
	tempfile scalarstata
	quietly log using `scalarstata', name(scalar) replace text
	noisily scalar list
	quietly log close scalar

	tempname myfile myout
	file open `myfile' using `scalarstata', read write text
	file read `myfile' line
	while r(eof) == 0 {
		local name = word("`line'",1)
		local scalars "`scalars' `name'"
	
		file read `myfile' line
	}
	file close `myfile'	
	
	* New log *
	quietly log using "$results/$id/outputstata_`logname'.tex", name(latex) replace text
	quietly log close latex

	* LaTeX-friendly log *
	foreach name in `scalars' {

		quietly log using "$results/$id/outputstata_`logname'.tex", name(latex) append text
				
		if `"`=substr("`name'",1,4)'"' == "anio" | `"`name'"' == "lif" | `"`name'"' == "pef" ///
			| `"`=substr("`name'",1,5)'"' == "enigh" {
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			local value = `name'
			di in w `"\d`name'{`value'}"'		
		}

		else if `"`=substr("`name'",1,3)'"' == "pib" | `"`=substr("`name'",1,3)'"' == "def" {
			*di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			*di in w `"\num\d`name'{`=string(`value',"%10.1fc")'}"'
		}

		else if `"`=substr("`name'",1,1)'"' == "T" | `"`=substr("`name'",-3,3)'"' == "PIB" {
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			local value = string(`=round(`name',.001)',"%6.3fc")
			di in w `"\d`name'{`value'}"'
		}

		else if `"`=substr("`name'",1,1)'"' == "Z" {
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			local value = string(`=round(`name',1)',"%10.0fc")
			di in w `"\d`name'{`value'}"'		
		}

		else {
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			local value = string(`=round(`name'/1000000,.1)',"%20.1fc")
			di in w `"\d`name'{`value'}"'
		}

		quietly log close latex
	}
	scalar drop _all
	capture log on overall
end
