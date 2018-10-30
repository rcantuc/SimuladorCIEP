program define CicloDeVida, rclass
quietly {
	version 13.1
	syntax varname [if] [fweight] [, BOOTstrap(int 1) POST]

	noisily di _newline in y "  CicloDeVida.ado"



	*******************************
	*** 0 Guardar base original ***
	*******************************
	preserve



	****************************
	*** 1 Variables internas ***	
	****************************
	tempvar pob
	g double `pob' = 1
	
	g entidad = substr(folioviv,1,2) 
	destring sexo entidad, replace ignore("co")

	tempvar varlist2
	g double `varlist2' = `varlist' `if'

	capture confirm variable decil
	tempvar decil
	if _rc != 0 {
		xtile `decil' = `varlist' [`weight' `exp'], n(10) 
	}
	else {
		g `decil' = decil
	}
	
	collapse (sum) `varlist2' `pob' [`weight' `exp'], by(sexo edad `decil' entidad escol)
	format `varlist2' %20.0fc



	********************************
	*** 2 Desplegar estadisticos ***
	********************************
	tabstat `varlist2' `pob', stat(sum) f(%25.2fc) save
	tempname REC
	matrix `REC' = r(StatTotal)

	noisily di in g "  Amount (" in y `"`=upper("`1'")'"' in g "):" _column(40) in y %25.0fc `REC'[1,1]
	noisily di in g "  Population (" in y `"`=upper("`1'")'"' in g "):" _column(40) in y %25.0fc `REC'[1,2]



	*********************************
	*** 3 Guardar resultados POST ***
	*********************************
	if "`post'" == "post" {
		forvalues k=1(1)`=_N' {
			capture post CICLO (`bootstrap') (sexo[`k']) (edad[`k']) (`decil'[`k']) (entidad[`k']) ///
				(escol[`k']) (`pob'[`k']) (`varlist2'[`k'])
		}
	}



	***************
	*** 4 Final ***
	***************
	restore
}
end
