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
	quietly log using "$export/../statalatex_`logname'.tex", name(latex) replace text
	quietly log close latex

	* LaTeX-friendly log *
	foreach name in `scalars' {

		quietly log using "$export/../statalatex_`logname'.tex", name(latex) append text
				
		if `"`=substr("`name'",1,4)'"' == "anio" {
			local value = scalar(`name')
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			di in w `"\d`name'{`value'}"'		
		}

		else if `"`=substr("`name'",-3,3)'"' == "PIB" & `"`=substr("`name'",1,3)'"' != "PIB" {
			if scalar(`name') != . {
				local value = scalar(`name')
			}
			else {
				local value = 0
			}
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			di in w `"\d`name'{`=string(`value',"%6.1fc")'}"'
		}
		else {
			if scalar(`name') != . {
				local value = scalar(`name')/1000000
			}
			else {
				local value = 0
			}
			di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
			di in w `"\d`name'{`=string(`value',"%12.1fc")'}"'		
		}

		quietly log close latex
	}
	*scalar drop _all
	capture log on overall
end
