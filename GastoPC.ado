program define GastoPC, return
quietly {

	timer on 11
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

	PEF if divGA == 5, anio(`anio') by(ramo)
	local penIMSS = r(Instituto_Mexicano_del_Seguro_S)
	local penISSSTE = r(Instituto_de_Seguridad_y_Servic)
	local penLFCFerronales = r(Aportaciones_a_Seguridad_Social)						// incluye ISSFAM
	local penPemex = r(Petr_c_o__leos_Mexicanos)
	local penCFE = r(Comisi_c_o__n_Federal_de_Electr)
	local Pensiones = r(Gasto_bruto)

	PEF if divGA == 6, anio(`anio') by(divGA)
	local penPAM = r(Pensi_c_o__n_Bienestar)


	* HOUSEHOLDS *
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear
	label values formal formalidad

	tabstat factor if formal == 1 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname pensIMSS
	matrix `pensIMSS' = r(StatTotal)
	Distribucion penIMSS if formal == 1 & Pension != 0, relativo(Pension) macro(`penIMSS')

	tabstat factor if formal == 2 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname pensISSSTE
	matrix `pensISSSTE' = r(StatTotal)
	Distribucion penISSSTE if formal == 2 & Pension != 0, relativo(Pension) macro(`penISSSTE')

	tabstat factor if formal == 3 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname pensPemex
	matrix `pensPemex' = r(StatTotal)
	Distribucion penPemex if formal == 3 & Pension != 0, relativo(Pension) macro(`=`penPemex'+`penCFE'+`penLFCFerronales'')

	tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
	tempname pensPAM
	matrix `pensPAM' = r(StatTotal)
	Distribucion penPAM if edad >= 68, relativo(Pension) macro(`penPAM')

	egen double PensionGastoPC = rsum(penIMSS penISSSTE penPemex penPAM)

	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi{c o'}n para el bienestar" ///
		_col(33) %15.0fc in y `pensPAM'[1,1] ///
		_col(50) %7.3fc in y `penPAM'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `penPAM'/`pensPAM'[1,1]/`deflactor'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `pensIMSS'[1,1] ///
		_col(50) %7.3fc in y `penIMSS'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `penIMSS'/`pensIMSS'[1,1]/`deflactor'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `pensISSSTE'[1,1] ///
		_col(50) %7.3fc in y `penISSSTE'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `penISSSTE'/`pensISSSTE'[1,1]/`deflactor'
	noisily di in g "  Pemex, CFE, LFC, Ferro, ISSFAM" ///
		_col(33) %15.0fc in y `pensPemex'[1,1] ///
		_col(50) %7.3fc in y (`=`penPemex'+`penCFE'+`penLFCFerronales'')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`=`penPemex'+`penCFE'+`penLFCFerronales'')/`pensPemex'[1,1]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`pensPAM'[1,1]+`pensIMSS'[1,1]+`pensISSSTE'[1,1]+`pensPemex'[1,1]) ///
		_col(50) %7.3fc in y (`penPAM'+`penIMSS'+`penISSSTE'+`penPemex'+`penCFE'+`penLFCFerronales')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`penPAM'+`penIMSS'+`penISSSTE'+`penPemex'+`penCFE'+`penLFCFerronales')/(`pensPAM'[1,1]+`pensIMSS'[1,1]+`pensISSSTE'[1,1]+`pensPemex'[1,1])/`deflactor'

	scalar pamBase = `penPAM'/scalar(pibY)*100
	scalar penimsBase = `penIMSS'/scalar(pibY)*100
	scalar penissBase = `penISSSTE'/scalar(pibY)*100
	scalar penpemBase = `penPemex'/scalar(pibY)*100


	************************
	*** 3 Educaci{c o'}n ***
	************************
	noisily di _newline in y "{bf: B. Educaci{c o'}n p{c u'}blica" "}"

	PEF if divGA == 3, anio(`anio') by(desc_subfuncion)
	local basica = r(Educaci_c_o__n_B_c_a__sica)
	local medsup = r(Educaci_c_o__n_Media_Superior)
	local superi = r(Educaci_c_o__n_Superior)
	local posgra = r(Posgrado)


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
		g basica = `basica'/`Educacion'[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07")
		g medsup = `medsup'/`Educacion'[1,2] if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
		g superi = `superi'/`Educacion'[1,3] if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
		g posgra = `posgra'/`Educacion'[1,4] if asis_esc == "1" & tipoesc == "1" & nivel == "13"
	}

	if `anio' < 2016 {
		g basica = `basica'/`Educacion'[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3")
		g medsup = `medsup'/`Educacion'[1,2] if asis_esc == "1" & tipoesc == "1" & (nivel >= "4" & nivel <= "6")
		g superi = `superi'/`Educacion'[1,3] if asis_esc == "1" & tipoesc == "1" & (nivel >= "7" & nivel <= "8")
		g posgra = `posgra'/`Educacion'[1,4] if asis_esc == "1" & tipoesc == "1" & nivel == "9"
	}

	egen double EducacionGastoPC = rsum(basica medsup superi posgra)

	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  B{c a'}sica" ///
		_col(33) %15.0fc in y `Educacion'[1,1] ///
		_col(50) %7.3fc in y `basica'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `basica'/`Educacion'[1,1]/`deflactor'
	noisily di in g "  Media superior" ///
		_col(33) %15.0fc in y `Educacion'[1,2] ///
		_col(50) %7.3fc in y `medsup'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `medsup'/`Educacion'[1,2]/`deflactor'
	noisily di in g "  Superior" ///
		_col(33) %15.0fc in y `Educacion'[1,3] ///
		_col(50) %7.3fc in y `superi'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `superi'/`Educacion'[1,3]/`deflactor'
	noisily di in g "  Posgrado" ///
		_col(33) %15.0fc in y `Educacion'[1,4] ///
		_col(50) %7.3fc in y `posgra'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `posgra'/`Educacion'[1,4]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Educaci{c o'}n" ///
		_col(33) %15.0fc in y (`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]) ///
		_col(50) %7.3fc in y (`basica'+`medsup'+`superi'+`posgra')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`basica'+`medsup'+`superi'+`posgra')/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4])/`deflactor'

	scalar basicaBase = `basica'/scalar(pibY)*100
	scalar mediasBase = `medsup'/scalar(pibY)*100
	scalar superiBase = `superi'/scalar(pibY)*100
	scalar posgraBase = `posgra'/scalar(pibY)*100


	***************
	*** 4 Salud ***
	***************
	noisily di _newline in y "{bf: C. " in y "Salud" "}"

	PEF if divGA == 7, anio(`anio') by(desc_pp)
	local salPROSPERA = r(Programa_IMSS_BIENESTAR)
	if `salPROSPERA' == . {
		local salPROSPERA = r(Programa_IMSS_PROSPERA)							// IMSS-Prospera
	}
	if `salPROSPERA' == . {
		local salPROSPERA = r(Programa_IMSS_Oportunidades)						// IMSS-Oportunidades
	}
	local salSegPop = r(Seguro_Popular)											// Seguro Popular

	PEF if divGA == 7 ///
		& modalidad == "E" & pp == 13 & ramo == 52, anio(`anio') by(ramo)		// Salud - Pemex (no mover de lugar)
	local salPemex = r(Petr_c_o__leos_Mexicanos)

	PEF if divGA == 7, anio(`anio') by(ramo)
	local salIMSS = r(Instituto_Mexicano_del_Seguro_S)							// IMSS
	local salISSSTE = r(Instituto_de_Seguridad_y_Servic)						// ISSSTE
	local salISSFAM = r(Defensa_Nacional)+r(Marina)								// ISSFAM
	local salFASSA = r(Aportaciones_Federales_para_Ent)							// FASSA
	local salSSA = r(Salud)-`salSegPop'											// SSA, sin Seguro Popular


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

	g imss = `salIMSS'/`Salud'[1,1] if inst_1 == "1"
	g issste = `salISSSTE'/`Salud'[1,2] if inst_2 == "2"
	g isssteest = inst_3 == "3"
	g pemex = (`salPemex'+`salISSFAM')/`Salud'[1,3] if inst_4 == "4"
	g imssprospera = `salPROSPERA'/`Salud'[1,4] if inst_5 == "5"
	capture g otro = inst_6 == "6"
	if _rc != 0 {
		g otro = 0
	}
	g seg_pop = (`salFASSA'+`salSegPop')/(`Salud'[1,5]+`Salud'[1,7]) if segpop == "1" | benef_isssteest == 1
	g ssa = `salSSA'/`Salud'[1,6]

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
		_col(50) %7.3fc in y `salSSA'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `salSSA'/`pobtot'[1,1]/`deflactor'
	noisily di in g "  FASSA, Seguro Popular" ///
		_col(33) %15.0fc in y `Salud'[1,5]+`Salud'[1,7] ///
		_col(50) %7.3fc in y (`salFASSA'+`salSegPop')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`salFASSA'+`salSegPop')/(`Salud'[1,5]+`Salud'[1,7])/`deflactor'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `Salud'[1,1] ///
		_col(50) %7.3fc in y `salIMSS'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `salIMSS'/`Salud'[1,1]/`deflactor'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `Salud'[1,2] ///
		_col(50) %7.3fc in y `salISSSTE'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `salISSSTE'/`Salud'[1,2]/`deflactor'
	noisily di in g "  IMSS-Bienestar" ///
		_col(33) %15.0fc in y `Salud'[1,4] ///
		_col(50) %7.3fc in y `salPROSPERA'/scalar(pibY)*100 ///
		_col(60) %15.0fc in y `salPROSPERA'/`Salud'[1,4]/`deflactor'
	noisily di in g "  Pemex, ISSFAM" ///
		_col(33) %15.0fc in y `Salud'[1,3] ///
		_col(50) %7.3fc in y (`salPemex'+`salISSFAM')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`salPemex'+`salISSFAM')/`Salud'[1,3]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Salud" ///
		_col(33) %15.0fc in y (`pobtot'[1,1]) ///
		_col(50) %7.3fc in y (`salSSA'+`salFASSA'+`salSegPop'+`salIMSS'+`salISSSTE'+`salPROSPERA'+`salPemex'+`salISSFAM')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`salSSA'+`salFASSA'+`salSegPop'+`salIMSS'+`salISSSTE'+`salPROSPERA'+`salPemex'+`salISSFAM')/(`pobtot'[1,1]+`Salud'[1,5]+`Salud'[1,7]+`Salud'[1,1]+`Salud'[1,2]+`Salud'[1,4]+`Salud'[1,3])/`deflactor'

	scalar ssaBase    = `salSSA'/scalar(pibY)*100 							// SSalud
	scalar segpopBase = (`salFASSA'+`salSegPop')/scalar(pibY)*100			// Seguro Popular
	scalar imssBase   = `salIMSS'/scalar(pibY)*100							// IMSS (salud)
	scalar isssteBase = `salISSSTE'/scalar(pibY)*100						// ISSSTE (salud)
	scalar prospeBase = `salPROSPERA'/scalar(pibY)*100						// IMSS-Prospera
	scalar pemexBase  = (`salPemex'+`salISSFAM')/scalar(pibY)*100			// Pemex (salud)


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
	
	g double IngBasi = singbas/100*scalar(pibY)/`pobtot'[1,1]/`deflactor'
	noisily di _newline in g "{bf:  Gasto" ///
		_col(33) in g "Poblaci{c o'}n" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  `bititle'" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y singbas ///
		_col(60) %15.0fc in y singbas/100*scalar(pibY)/`pobtot'[1,1]/`deflactor'


	PEF if divGA != 5 & divGA != 3 & divGA != 6, by(capitulo) anio(`anio')
	scalar servpersBase = r(Servicios_personales)				// Servicios personales
	scalar matesumiBase = r(Materiales_y_suministros)			// Materiales y suministros
	scalar gastgeneBase = r(Gastos_generales)					// Gastos generales
	scalar substranBase = r(Subsidios_y_transferencia)			// Subsidios y transferencias
	scalar bienmuebBase = r(Bienes_muebles_e_inmuebles)			// Bienes muebles e inmuebles
	scalar obrapublBase = r(Obras_p_c_u__blicas)				// Obras p{c u'}blicas
	scalar invefinaBase = r(Inversi_c_o__n_financiera)			// Inversi{c o'}n financiera
	scalar partaporBase = r(Participaciones_y_aportac)			// Participaciones y aportaciones
	scalar deudpublBase = r(Deuda_p_c_u__blica)					// Deuda p{c u'}blica


	***********
	*** END ***
	***********
	timer off 11
	timer list 11
	noisily di in g "{bf:Tiempo:} " in y round(`=r(t11)/r(nt11)',.1) in g " segs."
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
