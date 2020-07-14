program define GastoPC, return
quietly {

	timer on 9
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, ANIO(int `aniovp') PEF]



	***************************************
	*** 1 Sistema de cuentas nacionales ***
	***************************************
	SCN, anio(`anio')



	*******************
	*** 2 Pensiones ***
	*******************
	capture confirm scalar penims
	if _rc == 0 {
		local penims = penims/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 5, anio(`anio') by(ramo)
		local penims = r(Instituto_Mexicano_del_Seguro_S)
	}
	capture confirm scalar peniss
	if _rc == 0 {
		local peniss = peniss/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 5, anio(`anio') by(ramo)
		local peniss = r(Instituto_de_Seguridad_y_Servic)
	}
	capture confirm scalar penotr
	if _rc == 0 {
		local penotr = penotr/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 5, anio(`anio') by(ramo)
		local penotr = r(Petr_c_o__leos_Mexicanos)+r(Aportaciones_a_Seguridad_Social)+r(Comisi_c_o__n_Federal_de_Electr)
	}
	capture confirm scalar Bienestar
	if _rc == 0 {
		local bienestar = Bienestar/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 6, anio(`anio') by(divGA)
		local bienestar = r(Pensi_c_o__n_Bienestar)
	}
	capture confirm scalar basica
	if _rc == 0 {
		local basica = basica/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 3, anio(`anio') by(desc_subfuncion)
		local basica = r(Educaci_c_o__n_B_c_a__sica)	
	}
	capture confirm scalar medsup
	if _rc == 0 {
		local medsup = medsup/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 3, anio(`anio') by(desc_subfuncion)
		local medsup = r(Educaci_c_o__n_Media_Superior)
	}
	capture confirm scalar superi
	if _rc == 0 {
		local superi = superi/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 3, anio(`anio') by(desc_subfuncion)
		local superi = r(Educaci_c_o__n_Superior)
	}
	capture confirm scalar posgra
	if _rc == 0 {
		local posgra = posgra/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 3, anio(`anio') by(desc_subfuncion)
		local posgra = r(Posgrado)
	}
	capture confirm scalar segpop
	if _rc == 0 {
		local segpop = segpop/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 7, anio(`anio') by(desc_pp)
		local segpop0 = r(Seguro_Popular)
		local segpop = r(Seguro_Popular)
		noisily PEF if divGA == 7, anio(`anio') by(ramo)
		local segpop = `segpop'+r(Aportaciones_Federales_para_Ent)
	}
	capture confirm scalar imss
	if _rc == 0 {
		local imss = imss/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 7, anio(`anio') by(ramo)
		local imss = r(Instituto_Mexicano_del_Seguro_S)
	}
	capture confirm scalar issste
	if _rc == 0 {
		local issste = issste/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 7, anio(`anio') by(ramo)
		local issste = r(Instituto_de_Seguridad_y_Servic)
	}
	capture confirm scalar prospe
	if _rc == 0 {
		local prospe = prospe/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 7, anio(`anio') by(desc_pp)
		local prospe = r(Programa_IMSS_BIENESTAR)
	}
	capture confirm scalar pemex
	if _rc == 0 {
		local pemex = pemex/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 7 & modalidad == "E" & pp == 13 & ramo == 52, anio(`anio') by(ramo)
		local pemex = r(Petr_c_o__leos_Mexicanos)
	}
	capture confirm scalar ssa
	if _rc == 0 {
		local ssa = ssa/100*scalar(PIB)
	}
	else {
		PEF if divGA == 7, anio(`anio') by(ramo)
		local ssa = r(Salud)-`segpop0'
	}
	capture confirm scalar issfam
	if _rc == 0 {
		local issfam = issfam/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA == 7, anio(`anio') by(ramo)
		local issfam = r(Defensa_Nacional)+r(Marina)
	}
	capture confirm scalar IngBas
	if _rc == 0 {
		local IngBas = IngBas/100*scalar(PIB)
	}
	else {
		local IngBas = 0
	}
	capture confirm scalar servpers
	if _rc == 0 {
		local servpers = servpers/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local servpers = r(Servicios_personales)
	}
	capture confirm scalar matesumi
	if _rc == 0 {
		local matesumi = matesumi/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local matesumi = r(Materiales_y_suministros)
	}
	capture confirm scalar gastgene
	if _rc == 0 {
		local gastgene = gastgene/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local gastgene = r(Gastos_generales)
	}
	capture confirm scalar substran
	if _rc == 0 {
		local substran = substran/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local substran = r(Subsidios_y_transferencia)
	}
	capture confirm scalar bienmueb
	if _rc == 0 {
		local bienmueb = bienmueb/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local bienmueb = r(Bienes_muebles_e_inmuebles)
	}
	capture confirm scalar obrapubl
	if _rc == 0 {
		local obrapubl = obrapubl/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local obrapubl = r(Obras_p_c_u__blicas)
	}
	capture confirm scalar invefina
	if _rc == 0 {
		local invefina = invefina/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local invefina = r(Inversi_c_o__n_financiera)
	}
	capture confirm scalar partapor
	if _rc == 0 {
		local partapor = partapor/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local partapor = r(Participaciones_y_aportac)
	}
	capture confirm scalar costodeu
	if _rc == 0 {
		local costodeu = costodeu/100*scalar(PIB)
	}
	else {
		noisily PEF if divGA != 5 & divGA != 3 & divGA != 6 & divGA != 7, by(capitulo) anio(`anio')
		local costodeu = r(Deuda_p_c_u__blica)
	}
	
	

	********************
	*** 3 Resultados ***
	********************
	noisily di _newline(2) in g _dup(20) "." "{bf:   Transferencias per c{c a'}pita de los GASTOS " in y `anio' "   }" in g _dup(20) "."


	* Pensiones *
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear
	label values formal formalidad

	tabstat factor if formal == 1 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname mpenims
	matrix `mpenims' = r(StatTotal)

	tabstat factor if formal == 2 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname mpeniss
	matrix `mpeniss' = r(StatTotal)

	tabstat factor if formal == 3 & ing_jubila != 0, stat(sum) f(%20.0fc) save
	tempname mpenotr
	matrix `mpenotr' = r(StatTotal)

	tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
	tempname mbienestar
	matrix `mbienestar' = r(StatTotal)

	noisily di _newline in y "{bf: A. Pensiones}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi{c o'}n para el bienestar" ///
		_col(33) %15.0fc in y `mbienestar'[1,1] ///
		_col(50) %7.3fc in y (`bienestar')/PIB*100 ///
		_col(60) %15.0fc in y (`bienestar')/`mbienestar'[1,1]
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `mpenims'[1,1] ///
		_col(50) %7.3fc in y (`penims')/PIB*100 ///
		_col(60) %15.0fc in y (`penims')/`mpenims'[1,1]
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `mpeniss'[1,1] ///
		_col(50) %7.3fc in y (`peniss')/PIB*100 ///
		_col(60) %15.0fc in y (`peniss')/`mpeniss'[1,1]
	noisily di in g "  Pemex, CFE, LFC, Ferro, ISSFAM" ///
		_col(33) %15.0fc in y `mpenotr'[1,1] ///
		_col(50) %7.3fc in y (`penotr')/PIB*100 ///
		_col(60) %15.0fc in y (`penotr')/`mpenotr'[1,1]
	noisily di in g _dup(75) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`mbienestar'[1,1]+`mpenims'[1,1]+`mpeniss'[1,1]+`mpenotr'[1,1]) ///
		_col(50) %7.3fc in y (`bienestar'+`penims'+`peniss'+`penotr')/PIB*100 ///
		_col(60) %15.0fc in y (`bienestar'+`penims'+`peniss'+`penotr')/(`mbienestar'[1,1]+`mpenims'[1,1]+`mpeniss'[1,1]+`mpenotr'[1,1])


	* Educacion *
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

	noisily di _newline in y "{bf: B. Educaci{c o'}n p{c u'}blica" "}"
	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  B{c a'}sica" ///
		_col(33) %15.0fc in y `Educacion'[1,1] ///
		_col(50) %7.3fc in y (`basica')/PIB*100 ///
		_col(60) %15.0fc in y `basica'/`Educacion'[1,1]
	noisily di in g "  Media superior" ///
		_col(33) %15.0fc in y `Educacion'[1,2] ///
		_col(50) %7.3fc in y (`medsup')/PIB*100 ///
		_col(60) %15.0fc in y `medsup'/`Educacion'[1,2]
	noisily di in g "  Superior" ///
		_col(33) %15.0fc in y `Educacion'[1,3] ///
		_col(50) %7.3fc in y (`superi')/PIB*100 ///
		_col(60) %15.0fc in y `superi'/`Educacion'[1,3]
	noisily di in g "  Posgrado" ///
		_col(33) %15.0fc in y `Educacion'[1,4] ///
		_col(50) %7.3fc in y (`posgra')/PIB*100 ///
		_col(60) %15.0fc in y `posgra'/`Educacion'[1,4]
	noisily di in g _dup(75) "-"
	noisily di in g "  Educaci{c o'}n" ///
		_col(33) %15.0fc in y (`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]) ///
		_col(50) %7.3fc in y (`basica'+`medsup'+`superi'+`posgra')/scalar(pibY)*100 ///
		_col(60) %15.0fc in y (`basica'+`medsup'+`superi'+`posgra')/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4])



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

	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobtot
	matrix `pobtot' = r(StatTotal)

	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  SSA (sin afiliaci{c o'}n)" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `ssa'/PIB*100 ///
		_col(60) %15.0fc in y `ssa'/`pobtot'[1,1]
	noisily di in g "  FASSA, Seguro Popular" ///
		_col(33) %15.0fc in y `Salud'[1,5]+`Salud'[1,7] ///
		_col(50) %7.3fc in y (`segpop')/PIB*100 ///
		_col(60) %15.0fc in y (`segpop')/(`Salud'[1,5]+`Salud'[1,7])
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `Salud'[1,1] ///
		_col(50) %7.3fc in y `imss'/PIB*100 ///
		_col(60) %15.0fc in y `imss'/`Salud'[1,1]
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `Salud'[1,2] ///
		_col(50) %7.3fc in y `issste'/PIB*100 ///
		_col(60) %15.0fc in y `issste'/`Salud'[1,2]
	noisily di in g "  IMSS-Bienestar" ///
		_col(33) %15.0fc in y `Salud'[1,4] ///
		_col(50) %7.3fc in y `prospe'/PIB*100 ///
		_col(60) %15.0fc in y `prospe'/`Salud'[1,4]
	noisily di in g "  Pemex, ISSFAM" ///
		_col(33) %15.0fc in y `Salud'[1,3] ///
		_col(50) %7.3fc in y (`pemex'+`issfam')/PIB*100 ///
		_col(60) %15.0fc in y (`pemex'+`issfam')/`Salud'[1,3]
	noisily di in g _dup(75) "-"
	noisily di in g "  Salud" ///
		_col(33) %15.0fc in y (`pobtot'[1,1]) ///
		_col(50) %7.3fc in y (`ssa'+`segpop'+`imss'+`issste'+`prospe'+`pemex'+`issfam')/PIB*100 ///
		_col(60) %15.0fc in y (`ssa'+`segpop'+`imss'+`issste'+`prospe'+`pemex'+`issfam')/(`pobtot'[1,1])



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
		_col(33) %15s in g "Poblaci{c o'}n" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  `bititle'" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `IngBas'/PIB*100 ///
		_col(60) %15.0fc in y `IngBas'/`pobtot'[1,1]



	**********************
	*** 6 Otros gastos ***
	**********************
	noisily di _newline in y "{bf: E. Otros gastos}"
	
	
	noisily di _newline in g "{bf:  Gasto por cap{c i'}tulo" ///
		_col(33) %15s in g "Poblaci{c o'}n" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Servicios personales" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `servpers'/PIB*100 ///
		_col(60) %15.0fc in y `servpers'/`pobtot'[1,1]
	noisily di in g "  Materiales y suministros" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `matesumi'/PIB*100 ///
		_col(60) %15.0fc in y `matesumi'/`pobtot'[1,1]
	noisily di in g "  Gastos generales" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `gastgene'/PIB*100 ///
		_col(60) %15.0fc in y `gastgene'/`pobtot'[1,1]
	noisily di in g "  Subsidios y transferencias" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `substran'/PIB*100 ///
		_col(60) %15.0fc in y `substran'/`pobtot'[1,1]
	noisily di in g "  Bienes muebles e inmuebles" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `bienmueb'/PIB*100 ///
		_col(60) %15.0fc in y `bienmueb'/`pobtot'[1,1]
	noisily di in g "  Obras p{c u'}blicas" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `obrapubl'/PIB*100 ///
		_col(60) %15.0fc in y `obrapubl'/`pobtot'[1,1]
	noisily di in g "  Inversi{c o'}n financiera" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `invefina'/PIB*100 ///
		_col(60) %15.0fc in y `invefina'/`pobtot'[1,1]
	noisily di in g "  Participaciones y aportaciones" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `partapor'/PIB*100 ///
		_col(60) %15.0fc in y `partapor'/`pobtot'[1,1]
	noisily di in g "  Costo de la deuda" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y `costodeu'/PIB*100 ///
		_col(60) %15.0fc in y `costodeu'/`pobtot'[1,1]
	noisily di in g _dup(80) "-"
	noisily di in g "  Otros gastos" ///
		_col(33) %15.0fc in y `pobtot'[1,1] ///
		_col(50) %7.3fc in y (`servpers'+`matesumi'+`gastgene'+`substran'+`bienmueb'+`obrapubl'+`invefina'+`partapor'+`costodeu')/PIB*100 ///
		_col(60) %15.0fc in y (`servpers'+`matesumi'+`gastgene'+`substran'+`bienmueb'+`obrapubl'+`invefina'+`partapor'+`costodeu')/`pobtot'[1,1]



	***********
	*** END ***
	***********
	timer off 9
	timer list 9
	noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
}
end
