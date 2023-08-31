* Gini program*
program Gini, return
quietly {
	syntax varname [if], HOGar(varlist) factor(varlist)
	preserve

	collapse (mean) ingreso = `varlist' (max) `factor' `if', by(`hogar')
	keep if ingreso != 0 & ingreso != .
	count if ingreso != 0 & ingreso != .
	if r(N) == 0 {
		noisily di in g "Gini de " in y "`varlist'" in g ": " in y "No hay observaciones"
		return local gini_`varlist' = 0
		restore
		exit
	}

	sort ingreso `hogar'

	g double n = sum(`factor')		// Numero de individuos
	format n %15.0fc

	tempvar iy2
	g double `iy2' = n*ingreso
	tabstat `iy2' ingreso [fw=`factor'], stat(sum) f(%30.0fc) save

	tempname sumiy2
	matrix `sumiy2' = r(StatTotal)

	local gini_`=substr("`varlist'",1,20)' = ((2*`sumiy2'[1,1])/(n[_N]*`sumiy2'[1,2])) - (n[_N]+1)/n[_N]
	noisily di in g "Gini de " in y "`varlist'" in g ": " in y %5.3fc `gini_`=substr("`varlist'",1,20)''
	return local gini_`=substr("`varlist'",1,20)' = `gini_`=substr("`varlist'",1,20)''
	restore
}
end
