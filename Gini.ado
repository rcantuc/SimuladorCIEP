* Gini program*
program Gini, return
quietly {
	syntax varname [if], HOGar(varlist) INDividuo(varlist) factor(varlist)
	preserve

	collapse (sum) ingreso = `varlist' (mean) tot_integ `factor' `if', by(`hogar')
	keep if ingreso > 0
	
	count if ingreso > 0
	if r(N) == 0 {
		noisily di in g "Gini de " in y "`varlist'" in g ": " in y "No hay observaciones"
		return local gini_`varlist' = 0
		restore
		exit
	}

	replace factor = round(factor)
	replace tot_integ = round(tot_integ)
	replace ingreso = ingreso/tot_integ			// Ingresos per capita
	sort ingreso `hogar'

	g double n = sum(`factor'*tot_integ)		// Numero de individuos
	format n %15.0fc

	tempvar iy2
	g double `iy2' = (n[_N]+1-n)*ingreso
	tabstat `iy2' ingreso [fw=`factor'*tot_integ], stat(sum) f(%30.0fc) save

	tempname sumiy2
	matrix `sumiy2' = r(StatTotal)

	local gini_`varlist' = 1/(n[_N]-1)*(n[_N]+1-2*(`sumiy2'[1,1]/`sumiy2'[1,2]))
	noisily di in g "Gini de " in y "`varlist'" in g ": " in y %5.3fc `gini_`varlist''
	return local gini_`varlist' = `gini_`varlist''
	restore
}
end
