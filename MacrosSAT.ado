program define MacrosSAT
quietly{

	args anio
	noisily di _newline(2) in g "{bf:4. Sistema Fiscal}: " in y "SAT `anio'"



	**************************
	*** 1 Personas fisicas ***
	**************************
	local anio = 2015
	use "`c(sysdir_site)'../bases/SAT/PF/Stata/`anio'_labels.dta", clear

}
end
