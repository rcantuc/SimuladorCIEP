program define incidencia, rclass
quietly {
	version 13.1
	syntax varname [if] [fweight/], Folio(varlist) Relativo(name) N(name) [POST]

	noisily di _newline in y "  incidencia.ado"



	******************************
	** 0. Guardar base original **
	preserve
	local rellabel : variable label `relativo'



	***************************
	** 1. Variables internas **
	tempvar hog miembros
	egen `miembros' = count(`exp'), by(`folio')
	g `hog' = 1/`miembros'

	tempvar varlist2
	g double `varlist2' = `varlist' `if'

	collapse (sum) `varlist2' `hog' `relativo' [`weight' = `exp'], by(`n')

	* 1.1 Comprobacion *
	tempname REC
	tabstat `varlist2', stat(sum) f(%25.2fc) save
	matrix `REC' = r(StatTotal)
	noisily di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]

	* 1.2 Hogares *
	tempname FOR
	tabstat `hog', stat(sum) f(%12.0fc) save
	matrix `FOR' = r(StatTotal)
	noisily di in g "  Hogares:" _column(40) in y %25.0fc `FOR'[1,1]

	* 1.3 Relativo *
	tempname REL
	tabstat `relativo', stat(sum) f(%25.2fc) save
	matrix `REL' = r(StatTotal)
	noisily di in g "  `rellabel':" _column(40) in y %25.0fc `REL'[1,1]

	sort `n'
	if _N != 10 {
		set obs 10
		forvalues k=1(1)10 {
			if `n'[`k'] != `k' {
				replace `n' = `k' in -1
				replace `varlist2' = 0 in -1
				replace `relativo' = 1 in -1
				sort `n'
			}
		}
	}


	***************
	** 2.0 Total **
	quietly {
		sort `n'
		set obs `=_N+1'
		replace `n' = _N in `=_N'

		tempvar rectot hogtot relativo2
		egen double `rectot' = sum(`varlist2')
		egen double `hogtot' = sum(`hog')
		egen double `relativo2' = sum(`relativo')

		replace `hog' = `hogtot' in `=_N'
		replace `varlist2' = `rectot' in `=_N'
		replace `relativo' = `relativo2' in `=_N'

		* Per capita *
		tempvar recxhog dis prop
		g double `recxhog' = `varlist2' / `hog'
		replace `recxhog' = 0 if `recxhog' == .

		* Distribucion *
		g double `dis' = `varlist2'/`rectot' * 100
		replace `dis' = 0 if `dis' == .

		// Proporcion como % del `relativo' //
		g double `prop' = `varlist2' / `relativo' * 100
	}



	*********************************
	** 3.0 Guardar resultados POST **	
	if "`post'" == "post" {
		forvalues k=1(1)`=_N' {
			capture post INCI (`n'[`k']) (`recxhog'[`k']) (`dis'[`k']) (`prop'[`k']) (`hog'[`k'])
		}
	}



	***************
	** 5.0 Final **
	restore
}
end
