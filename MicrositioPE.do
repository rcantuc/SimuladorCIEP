** Update PaqueteEconomico.ciep.mx **
forvalues anio=2013(1)`=anioPE' {
	noisily LIF, by(divPE) rows(1) min(0) anio(`anio') //update desde(2018)
}
forvalues anio=2013(1)`=anioPE' {
	noisily PEF, by(divCIEP) rows(2) min(0) anio(`anio') //update desde(2018)
}
noisily SHRFSP, ultanio(2013) //update
