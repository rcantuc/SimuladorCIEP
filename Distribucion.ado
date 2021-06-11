program Distribucion, return
	syntax anything, RELativo(varname) MACro(real)

	tempvar TOT
	egen double `TOT' = sum(`relativo') if factor_cola != 0
	g double `anything' = `relativo'/`TOT'*`macro'/factor_cola if factor_cola != 0
end
