program define GastoPCSIM, return
quietly {

	timer on 12
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, ANIO(int `aniovp') PEF]
	noisily di _newline(2) in g "{bf:TRANSFERENCIAS PER C{c A'}PITAS: " in y "GASTOS `anio'}"


	*************
	*** 1 PIB ***
	*************
	PIBDeflactor, anio(`anio')
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local deflactor = deflator[`k']
			continue, break
		}
	}


	*******************
	*** 2 Pensiones ***
	*******************
	noisily di _newline in y "{bf: A. Pensiones}"

	* HOUSEHOLDS *
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear
	label values formal formalidad

	tabstat factor if formal == 1 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname pensIMSS
	matrix `pensIMSS' = r(StatTotal)
	Distribucion penIMSS if formal == 1 & Pension != 0, relativo(Pension) macro(`=scalar(penims)')

	tabstat factor if formal == 2 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname pensISSSTE
	matrix `pensISSSTE' = r(StatTotal)
	Distribucion penISSSTE if formal == 2 & Pension != 0, relativo(Pension) macro(`=scalar(peniss)')

	tabstat factor if formal == 3 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname pensPemex
	matrix `pensPemex' = r(StatTotal)
	Distribucion penPemex if formal == 3 & Pension != 0, relativo(Pension) macro(`=scalar(penpem)')

	tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
	tempname pensPAM
	matrix `pensPAM' = r(StatTotal)
	Distribucion penPAM if edad >= 68, relativo(Pension) macro(`=scalar(Bienestar)')

	egen double PensionGastoPC = rsum(penIMSS penISSSTE penPemex penPAM)

	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi{c o'}n para el bienestar" ///
		_col(33) %15.0fc in y `pensPAM'[1,1] ///
		_col(50) %7.3fc in y scalar(Bienestar) ///
		_col(60) %15.0fc in y scalar(Bienestar)/100*scalar(pibY)/`pensPAM'[1,1]/`deflactor'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `pensIMSS'[1,1] ///
		_col(50) %7.3fc in y scalar(penims) ///
		_col(60) %15.0fc in y scalar(penims)/100*scalar(pibY)/`pensIMSS'[1,1]/`deflactor'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `pensISSSTE'[1,1] ///
		_col(50) %7.3fc in y scalar(peniss) ///
		_col(60) %15.0fc in y scalar(penims)/100*scalar(pibY)/`pensISSSTE'[1,1]/`deflactor'
	noisily di in g "  Pemex, CFE, LFC, Ferro, ISSFAM" ///
		_col(33) %15.0fc in y `pensPemex'[1,1] ///
		_col(50) %7.3fc in y scalar(penpem) ///
		_col(60) %15.0fc in y scalar(penpem)/100*scalar(pibY)/`pensPemex'[1,1]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`pensPAM'[1,1]+`pensIMSS'[1,1]+`pensISSSTE'[1,1]+`pensPemex'[1,1]) ///
		_col(50) %7.3fc in y (scalar(Bienestar)+scalar(penims)+scalar(peniss)+scalar(penpem)) ///
		_col(60) %15.0fc in y (scalar(Bienestar)+scalar(penims)+scalar(peniss)+scalar(penpem))/100*scalar(pibY)/(`pensPAM'[1,1]+`pensIMSS'[1,1]+`pensISSSTE'[1,1]+`pensPemex'[1,1])/`deflactor'



	************************
	*** 3 Educaci{c o'}n ***
	************************
	noisily di _newline in y "{bf: B. Educaci{c o'}n p{c u'}blica" "}"

	* HOUSEHOLDS *
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear
	if `anio' >= 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07")
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "13"
	}

	if `anio' < 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3")
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "4" & nivel <= "6")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "7" & nivel <= "8")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "9"
	}

	tabstat alum_basica alum_medsup alum_superi alum_posgra [fw=factor], stat(sum) f(%15.0fc) save
	tempname Educacion 
	matrix `Educacion' = r(StatTotal)

	if `anio' >= 2016 {
		g basica = scalar(basica)/`Educacion'[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07")
		g medsup = scalar(medsup)/`Educacion'[1,2] if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
		g superi = scalar(superi)/`Educacion'[1,3] if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
		g posgra = scalar(posgra)/`Educacion'[1,4] if asis_esc == "1" & tipoesc == "1" & nivel == "13"
	}

	if `anio' < 2016 {
		g basica = scalar(basica)/`Educacion'[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3")
		g medsup = scalar(medsup)/`Educacion'[1,2] if asis_esc == "1" & tipoesc == "1" & (nivel >= "4" & nivel <= "6")
		g superi = scalar(superi)/`Educacion'[1,3] if asis_esc == "1" & tipoesc == "1" & (nivel >= "7" & nivel <= "8")
		g posgra = scalar(posgra)/`Educacion'[1,4] if asis_esc == "1" & tipoesc == "1" & nivel == "9"
	}

	egen double EducacionGastoPC = rsum(basica medsup superi posgra)

	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  B{c a'}sica" ///
		_col(33) %15.0fc in y `Educacion'[1,1] ///
		_col(50) %7.3fc in y scalar(basica) ///
		_col(60) %15.0fc in y scalar(basica)/100*scalar(pibY)/`Educacion'[1,1]/`deflactor'
	noisily di in g "  Media superior" ///
		_col(33) %15.0fc in y `Educacion'[1,2] ///
		_col(50) %7.3fc in y scalar(medsup) ///
		_col(60) %15.0fc in y scalar(medsup)/100*scalar(pibY)/`Educacion'[1,2]/`deflactor'
	noisily di in g "  Superior" ///
		_col(33) %15.0fc in y `Educacion'[1,3] ///
		_col(50) %7.3fc in y scalar(superi) ///
		_col(60) %15.0fc in y scalar(superi)/100*scalar(pibY)/`Educacion'[1,3]/`deflactor'
	noisily di in g "  Posgrado" ///
		_col(33) %15.0fc in y `Educacion'[1,4] ///
		_col(50) %7.3fc in y scalar(posgra) ///
		_col(60) %15.0fc in y scalar(posgra)/100*scalar(pibY)/`Educacion'[1,4]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Educaci{c o'}n" ///
		_col(33) %15.0fc in y (`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]) ///
		_col(50) %7.3fc in y (scalar(basica)+scalar(medsup)+scalar(superi)+scalar(posgra)) ///
		_col(60) %15.0fc in y (scalar(basica)+scalar(medsup)+scalar(superi)+scalar(posgra))/100*scalar(pibY)/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4])/`deflactor'


	***************
	*** 4 Salud ***
	***************
	noisily di _newline in y "{bf: C. " in y "Salud" "}"

	* HOUSEHOLDS *
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear	
	g benef_imss = inst_1 == "1"
	g benef_issste = inst_2 == "2"
	g benef_isssteest = inst_3 == "3"
	g benef_pemex = inst_4 == "4"
	g benef_imssprospera = inst_5 == "5"
	capture g benef_otro = inst_6 == "6"
	if _rc != 0 {
		g benef_otro = 0
	}
	g benef_seg_pop = segpop == "1"
	g benef_ssa = 1

	tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
		benef_ssa benef_isssteest benef_otro [fw=factor], stat(sum) f(%15.0fc) save
	tempname Salud
	matrix `Salud' = r(StatTotal)

	g imss = scalar(imss)/`Salud'[1,1] if inst_1 == "1"
	g issste = scalar(issste)/`Salud'[1,2] if inst_2 == "2"
	g isssteest = inst_3 == "3"
	g pemex = (scalar(pemex))/`Salud'[1,3] if inst_4 == "4"
	g imssprospera = scalar(prospe)/`Salud'[1,4] if inst_5 == "5"
	capture g otro = inst_6 == "6"
	if _rc != 0 {
		g otro = 0
	}
	g seg_pop = scalar(segpop)/(`Salud'[1,5]+`Salud'[1,7]) if segpop == "1" | benef_isssteest == 1
	g ssa = scalar(ssa)/`Salud'[1,6]

	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobtot
	matrix `pobtot' = r(StatTotal)

	egen double SaludGastoPC = rsum(imss issste pemex imssprospera seg_pop ssa)

	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  SSA (sin afiliaci{c o'}n)" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y scalar(ssa) ///
		_col(60) %15.0fc in y scalar(ssa)/100*scalar(pibY)/`pobtot'[1,1]/`deflactor'
	noisily di in g "  FASSA, Seguro Popular" ///
		_col(33) %15.0fc in y `Salud'[1,5]+`Salud'[1,7] ///
		_col(50) %7.3fc in y (scalar(segpop)) ///
		_col(60) %15.0fc in y (scalar(segpop))/100*scalar(pibY)/(`Salud'[1,5]+`Salud'[1,7])/`deflactor'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `Salud'[1,1] ///
		_col(50) %7.3fc in y scalar(imss) ///
		_col(60) %15.0fc in y scalar(imss)/100*scalar(pibY)/`Salud'[1,1]/`deflactor'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `Salud'[1,2] ///
		_col(50) %7.3fc in y scalar(issste) ///
		_col(60) %15.0fc in y scalar(issste)/100*scalar(pibY)/`Salud'[1,2]/`deflactor'
	noisily di in g "  IMSS-Bienestar" ///
		_col(33) %15.0fc in y `Salud'[1,4] ///
		_col(50) %7.3fc in y scalar(prospe) ///
		_col(60) %15.0fc in y scalar(prospe)/100*scalar(pibY)/`Salud'[1,4]/`deflactor'
	noisily di in g "  Pemex, ISSFAM" ///
		_col(33) %15.0fc in y `Salud'[1,3] ///
		_col(50) %7.3fc in y (scalar(pemex)) ///
		_col(60) %15.0fc in y (scalar(pemex))/100*scalar(pibY)/`Salud'[1,3]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Salud" ///
		_col(33) %15.0fc in y (`pobtot'[1,1]) ///
		_col(50) %7.3fc in y (scalar(ssa)+scalar(segpop)+scalar(imss)+scalar(issste)+scalar(prospe)+scalar(pemex)) ///
		_col(60) %15.0fc in y (scalar(ssa)+scalar(segpop)+scalar(imss)+scalar(issste)+scalar(prospe)+scalar(pemex))/100*scalar(pibY)/(`pobtot'[1,1]+`Salud'[1,5]+`Salud'[1,7]+`Salud'[1,1]+`Salud'[1,2]+`Salud'[1,4]+`Salud'[1,3])/`deflactor'


	*****************************
	*** 5 Ingreso b{c a'}sico ***
	*****************************
	noisily di _newline in y "{bf: D. Ingreso b{c a'}sico}" 

	* HOUSEHOLDS *
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear	

	local bititle = "General"
	if ingbasico18 == 0 & ingbasico65 == 1 {
		tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
		matrix `pobtot' = r(StatTotal)
		local bititle = "Mayores de 18"
	}
	if ingbasico18 == 1 & ingbasico65 == 0 {
		tabstat factor if edad < 65, stat(sum) f(%20.0fc) save
		matrix `pobtot' = r(StatTotal)
		local bititle = "Menores de 65"
	}
	if ingbasico18 == 0 & ingbasico65 == 0 {
		tabstat factor if edad < 65 & edad >= 18, stat(sum) f(%20.0fc) save
		matrix `pobtot' = r(StatTotal)
		local bititle = "Entre 18 y 65"
	}

	noisily di _newline in g "{bf:  Gasto" ///
		_col(33) in g "Poblaci{c o'}n" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  `bititle'" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y IngBas ///
		_col(60) %15.0fc in y IngBas/100*scalar(pibY)/`pobtot'[1,1]/`deflactor'



	***********
	*** END ***
	***********
	timer off 12
	timer list 12
	noisily di in g "{bf:Tiempo:} " in y round(`=r(t12)/r(nt12)',.1) in g " segs."
}
end


*********************************
* Distribuciones proporcionales *
capture program drop Distribucion
program Distribucion, return
	syntax anything [if/], RELativo(varname) MACro(real)

	if "`if'" != "" {
		local if "if factor_cola != 0 & `if'"
	}
	tempvar TOT
	egen double `TOT' = sum(`relativo') `if' 
	g double `anything' = `relativo'/`TOT'*`macro'/factor_cola `if'
	replace `anything' = 0 if `anything' == .
end
