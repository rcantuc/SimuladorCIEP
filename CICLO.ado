program define CICLO, rclass
quietly {
	version 13.1
	syntax varname [if] [fweight], DECIL(varname) [BOOTstrap(int 1) POST]

	noisily di _newline in y "  ciclodevida.ado"



	*******************************
	*** 0 Guardar base original ***
	*******************************
	preserve

    /*if "`=scalar(aniovp)'" == "2022" {
        local ppp = 9.684
    }
    if "`=scalar(aniovp)'" == "2020" {
        local ppp = 9.813
    }
    if "`=scalar(aniovp)'" == "2018" {
        local ppp = 9.276
    }
    if "`=scalar(aniovp)'" == "2016" {
        local ppp = 8.446
    }
    if "`=scalar(aniovp)'" == "2014" {
        local ppp = 8.045
    }*/


	****************************
	*** 1 Variables internas ***	
	****************************
	tempvar pob
	g double `pob' = 1
	
	destring sexo, replace ignore("co")

	tempvar varlist2
	g double `varlist2' = `varlist' /* /`ppp' */ `if'
	
	collapse (sum) `varlist2' `pob' [`weight' `exp'] `if', by(sexo edad `decil')
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
			capture post CICLO (`bootstrap') (sexo[`k']) (edad[`k']) (`decil'[`k']) (`pob'[`k']) (`varlist2'[`k'])
		}
	}



	***************
	*** 4 Final ***
	***************
	restore
}
end
