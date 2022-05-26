program define scalarlatex

	if "$export" != "" {
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

			if `"`=substr("`name'",1,4)'"' == "anio" | `"`=substr("`name'",1,4)'"' == "defl" ///
				| `"`=substr("`name'",1,4)'"' == "trim" | `"`=substr("`name'",1,4)'"' == "infl" ///
				| `"`=substr("`name'",1,9)'"' == "poblacion" | `"`=substr("`name'",1,4)'"' == "gini" ///
				| `"`=substr("`name'",1,6)'"' == "output" | `"`=substr("`name'",1,4)'"' == "asis" {
				local value = scalar(`name')
				di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
				di in w `"\d`name'{`value'}"'		
			}

			else if (`"`=substr("`name'",-3,3)'"' == "PIB" & `"`=substr("`name'",1,3)'"' != "PIB") ///
				| `"`=substr("`name'",1,6)'"' == "lambda" | `"`=substr("`name'",1,2)'"' == "TT" ///
				| `"`=substr("`name'",1,7)'"' == "llambda" | `"`=substr("`name'",1,6)'"' == "Lambda" {
				if scalar(`name') != . {
					local value = scalar(`name')
				}
				else {
					local value = 0
				}
				di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
				di in w `"\d`name'{`=string(`value',"%6.3fc")'}"'
			}

			else if "`name'" == "ISRAS" | "`name'" == "ISRPF" | "`name'" == "CuotasT" ///
				| "`name'" == "IVA" | "`name'" == "ISAN" | "`name'" == "IEPS" ///
				| "`name'" == "Importa" | "`name'" == "ISRPM" | "`name'" == "FMP" ///
				| "`name'" == "OYE" | "`name'" == "OtrosI"  {
				local value = scalar(`name')
				di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
				di in w `"\d`name'{`=string(`value',"%12.3fc")'}"'
			}
			
			else if "`name'" == "basica" | "`name'" == "medsup" | "`name'" == "superi" ///
			| "`name'" == "posgra" | "`name'" == "eduadu" | "`name'" == "otrose" ///
			| "`name'" == "ssa" | "`name'" == "segpop" | "`name'" == "imss" ///
			| "`name'" == "issste" | "`name'" == "prospe" | "`name'" == "pemex" ///
			| "`name'" == "bienestar" | "`name'" == "penims" | "`name'" == "peniss" ///
			| "`name'" == "penotr" | "`name'" == "servpers" | "`name'" == "matesumi" ///
			| "`name'" == "gastgene" | "`name'" == "substran" | "`name'" == "bienmueb" ///
			| "`name'" == "obrapubl" | "`name'" == "invefina" | "`name'" == "partapor" ///
			| "`name'" == "costodeu" | "`name'" == "educacion" | "`name'" == "salud" ///
			| "`name'" == "pensiones" | "`name'" == "otrosgastos" | `"`=substr("`name'",1,3)'"' == "jer" ///
			| `"`=substr("`name'",1,4)'"' == "Part" | `"`=substr("`name'",1,4)'"' == "Apor" ///
			| `"`=substr("`name'",1,4)'"' == "Conv"| `"`=substr("`name'",1,4)'"' == "Prov" ///
			| `"`=substr("`name'",1,4)'"' == "Prot" | `"`=substr("`name'",1,6)'"' == "GasFed" ///
			| `"`=substr("`name'",1,3)'"' == "LIE" {
				local value = scalar(`name')
				di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
				di in w `"\d`name'{`=string(`value',"%12.0fc")'}"'			
			}
			
			else if `"`=substr("`name'",-1,1)'"' == "I" | `"`=substr("`name'",-1,1)'"' == "V" ///
				| `"`=substr("`name'",-1,1)'"' == "X" | `"`=substr("`name'",-1,1)'"' == "H" ///
				| `"`=substr("`name'",-1,1)'"' == "M" | `"`=substr("`name'",-8,8)'"' == "Nacional" ///
				| `"`=substr("`name'",-2,2)'"' == "PC" | `"`=substr("`name'",-3,3)'"' == "GEO" ///
				| `"`=substr("`name'",-3,3)'"' == "Por" {
				local value = scalar(`name')
				di in w "\def\d`name'#1{\gdef\\`name'{#1}}"
				di in w `"\d`name'{`=string(`value',"%12.1fc")'}"'				
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
	}
end
