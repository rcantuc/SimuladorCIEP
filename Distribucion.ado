program Distribucion, return
	syntax anything [if], RELativo(varname) MACro(real)

	tabstat `relativo' `if' [fw=factor], stat(sum) f(%20.0fc) save
	tempname SumaVar
	matrix `SumaVar' = r(StatTotal)

	capture confirm variable `anything'
	if _rc == 0 {
		tempvar `relativo'
		g double ``relativo'' = `anything'
		drop `anything'
		g double `anything' = ``relativo''*`macro'/`SumaVar'[1,1] `if'
	}
	else {
		g double `anything' = `relativo'*`macro'/`SumaVar'[1,1] `if'
	}
	tabstat `relativo' `if' [fw=factor], stat(sum) f(%20.0fc) save
end
