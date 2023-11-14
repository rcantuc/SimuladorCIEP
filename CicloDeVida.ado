program define CicloDeVida, rclass
quietly {
	version 13.1
	syntax varname [if] [fweight], DECIL(varname) [BOOTstrap(int 1) POST]

	noisily di _newline in y "  ciclodevida.ado"



	*******************************
	*** 0 Guardar base original ***
	*******************************
	preserve



	****************************
	*** 1 Variables internas ***	
	****************************
	tempvar pob
	g double `pob' = 1
	
	destring sexo, replace ignore("co")

	tempvar varlist2
	g double `varlist2' = `varlist' `if'
	
	collapse (sum) `varlist2' `pob' [`weight' `exp'], by(sexo edad `decil' escol formal)
	format `varlist2' %20.0fc



	********************************
	*** 2 Desplegar estadisticos ***
	********************************
	tabstat `varlist2' `pob', stat(sum) f(%25.2fc) save
	tempname REC
	matrix `REC' = r(StatTotal)

	noisily di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]
	noisily di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `REC'[1,2]



	*********************************
	*** 3 Guardar resultados POST ***
	*********************************
	if "`post'" == "post" {
		forvalues k=1(1)`=_N' {
			capture post CICLO (`bootstrap') (sexo[`k']) (edad[`k']) (`decil'[`k']) (escol[`k']) (formal[`k']) (`pob'[`k']) (`varlist2'[`k'])
		}
	}



	***************
	*** 4 Final ***
	***************
	restore
}
end
