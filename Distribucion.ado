program Distribucion, return
	syntax anything [if], RELativo(varname) MACro(real)

	tabstat `relativo' `if' [fw=factor], stat(sum) save
	tempname SumaVar
	matrix `SumaVar' = r(StatTotal)

	g double `anything' = `relativo'*`macro'/`SumaVar'[1,1] `if'
end
