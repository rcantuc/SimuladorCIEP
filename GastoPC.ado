program define GastoPC, return
quietly {

	timer on 9
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	syntax [, ANIO(int `aniovp') OUTPUT NOGraphs OTROS(real 1)]
	noisily di _newline(2) in g _dup(20) "." "{bf:   Transferencias per c{c a'}pita de los GASTOS " in y `anio' "   }" in g _dup(20) "."





	***************************************************************
	*** 1 Cuentas macroeconómicas (SCN, PIB, Balanza Comercial) ***
	***************************************************************
	*use if anio == `anio' using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
	PIBDeflactor, aniovp(`anio') nographs
	keep if anio == `anio'
	local PIB = pibY[1]





	************************
	*** 2 TRANSFERENCIAS ***
	************************
	use "`c(sysdir_site)'/SIM/2020/households`anio'.dta", clear
	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobenigh
	matrix `pobenigh' = r(StatTotal)

	tabstat Pension Educacion Salud OtrosGas Infra [fw=factor], stat(sum) f(%20.0fc) save
	matrix GASTOS = r(StatTotal)





	*******************
	*** 3 Educacion ***
	*******************
	if `anio' >= 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "13"
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 15
	}

	if `anio' < 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "4" & nivel <= "6")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "7" & nivel <= "8")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "9"
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3") & edad > 15
	}

	/* 3.1 Ajuste con las estadisticas oficiales *
	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto [fw=factor], stat(sum) f(%15.0fc) save
	tempname EducacionI
	matrix `EducacionI' = r(StatTotal)

	replace alum_basica = alum_basica*24597234/`EducacionI'[1,1]
	replace alum_medsup = alum_medsup*5353499/`EducacionI'[1,2]
	replace alum_superi = alum_superi*4579894/`EducacionI'[1,3]
	replace alum_posgra = alum_posgra*403312/`EducacionI'[1,4]
	replace alum_adulto = alum_adulto*1905180/`EducacionI'[1,5]

	* 3.2 Cifras finales de alumnos */
	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto [fw=factor], stat(sum) f(%15.0fc) save
	tempname Educacion
	matrix `Educacion' = r(StatTotal)

	* Inputs *
	capture confirm scalar basica
	if _rc == 0 {
		local basica = scalar(basica)*`Educacion'[1,1]
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) rows(3) nographs
		local basica = r(Educación_Básica)
		scalar basica = `basica'/`Educacion'[1,1]
		restore
	}
	capture confirm scalar medsup
	if _rc == 0 {
		local medsup = scalar(medsup)*`Educacion'[1,2]
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local medsup = r(Educación_Media_Superior)
		scalar medsup = `medsup'/`Educacion'[1,2]
		restore
	}
	capture confirm scalar superi
	if _rc == 0 {
		local superi = scalar(superi)*`Educacion'[1,3]
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local superi = r(Educación_Superior)
		scalar superi = `superi'/`Educacion'[1,3]
		restore
	}
	capture confirm scalar posgra
	if _rc == 0 {
		local posgra = scalar(posgra)*`Educacion'[1,4]
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local posgra = r(Posgrado)
		scalar posgra = `posgra'/`Educacion'[1,4]
		restore
	}
	capture confirm scalar eduadu
	if _rc == 0 {
		local eduadu = scalar(eduadu)*`Educacion'[1,5]
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local eduadu = r(Educación_para_Adultos)

		scalar eduadu = `eduadu'/`Educacion'[1,5]
		restore
	}
	capture confirm scalar otrose
	if _rc == 0 {
		local otrose = scalar(otrose)*(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5])
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local otrose = r(Otros_Servicios_Educativos_y_Ac) + r(Cultura) + r(Deporte_y_Recreación) ///
			+ r(Desarrollo_Tecnológico) + r(Función_Pública) ///
			+ r(Investigación_Científica) + r(Servicios_Científicos_y_Tecnol)

		scalar otrose = `otrose'/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5])
		restore
	}

	* Resultados *
	noisily di _newline in y "{bf: A. Educaci{c o'}n p{c u'}blica" "}"
	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  B{c a'}sica" ///
		_col(33) %15.0fc in y `Educacion'[1,1] ///
		_col(50) %7.3fc in y (`basica')/`PIB'*100 ///
		_col(60) %15.0fc in y `basica'/`Educacion'[1,1]
	noisily di in g "  Media superior" ///
		_col(33) %15.0fc in y `Educacion'[1,2] ///
		_col(50) %7.3fc in y (`medsup')/`PIB'*100 ///
		_col(60) %15.0fc in y `medsup'/`Educacion'[1,2]
	noisily di in g "  Superior" ///
		_col(33) %15.0fc in y `Educacion'[1,3] ///
		_col(50) %7.3fc in y (`superi')/`PIB'*100 ///
		_col(60) %15.0fc in y `superi'/`Educacion'[1,3]
	noisily di in g "  Posgrado" ///
		_col(33) %15.0fc in y `Educacion'[1,4] ///
		_col(50) %7.3fc in y (`posgra')/`PIB'*100 ///
		_col(60) %15.0fc in y `posgra'/`Educacion'[1,4]
	noisily di in g "  Para adultos" ///
		_col(33) %15.0fc in y `Educacion'[1,5] ///
		_col(50) %7.3fc in y (`eduadu')/`PIB'*100 ///
		_col(60) %15.0fc in y `eduadu'/`Educacion'[1,5]
	noisily di in g "  Otros gastos educativos" ///
		_col(33) %15.0fc in y (`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5]) ///
		_col(50) %7.3fc in y (`otrose')/`PIB'*100 ///
		_col(60) %15.0fc in y `otrose'/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5])
	noisily di in g _dup(80) "-"
	noisily di in g "  Educaci{c o'}n" ///
		_col(33) %15.0fc in y (`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5]) ///
		_col(50) %7.3fc in y (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/`PIB'*100 ///
		_col(60) %15.0fc in y (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5])

	replace Educacion = `basica'/`Educacion'[1,1] if alum_basica > 0
	replace Educacion = `medsup'/`Educacion'[1,2] if alum_medsup > 0
	replace Educacion = `superi'/`Educacion'[1,3] if alum_superi > 0
	replace Educacion = `posgra'/`Educacion'[1,4] if alum_posgra > 0
	replace Educacion = `eduadu'/`Educacion'[1,5] if alum_adulto > 0
	replace Educacion = Educacion + `otrose'/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3] ///
		+`Educacion'[1,4]+`Educacion'[1,5]) if Educacion > 0

	scalar basicaPIB = (`basica')/`PIB'*100
	scalar medsupPIB = (`medsup')/`PIB'*100
	scalar superiPIB = (`superi')/`PIB'*100
	scalar posgraPIB = (`posgra')/`PIB'*100
	scalar eduaduPIB = (`eduadu')/`PIB'*100
	scalar otrosePIB = (`otrose')/`PIB'*100
	scalar educacPIB = (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/`PIB'*100
	scalar educacion = (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/(`Educacion'[1,1] ///
		+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5])





	***************/
	*** 4 Salud ***
	***************
	g benef_imss = formal == 1
	g benef_issste = formal == 2
	g benef_pemex = formal == 3
	g benef_imssprospera = formal == 4
	g benef_seg_pop = pop_insabi == "1"
	g benef_ssa = 1


	/* 4.1 Ajuste con las estadisticas oficiales *
	tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
		benef_ssa /*benef_isssteest benef_otro*/ [fw=factor], stat(sum) f(%15.0fc) save
	tempname MSalud
	matrix `MSalud' = r(StatTotal)

	replace benef_imss = benef_imss*70519556/`MSalud'[1,1]
	replace benef_issste = benef_issste*13881797/`MSalud'[1,2]
	replace benef_pemex = benef_pemex*588049/`MSalud'[1,3]
	replace benef_imssprospera = benef_imssprospera*11768906/`MSalud'[1,4]
	replace benef_seg_pop = benef_seg_pop*68069755/`MSalud'[1,5]

	* 4.2 Cifras finales de beneficiarios */
	tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
		benef_ssa /*benef_isssteest benef_otro*/ [fw=factor], stat(sum) f(%15.0fc) save
	tempname Salud
	matrix `Salud' = r(StatTotal)

	* Inputs *
	capture confirm scalar imssbien
	if _rc == 0 {
		local imssbien = scalar(imssbien)*(`Salud'[1,6]-`Salud'[1,1]-`Salud'[1,2]-`Salud'[1,3])
	}
	else {
		preserve
		PEF if divPE == 8, anio(`anio') by(desc_pp) min(0) nographs
		local imssbien0 = r(Programa_IMSS_BIENESTAR) //+r(Programa_IMSS_BIENESTARC)
		local segpop0 = r(Seguro_Popular) //+r(Seguro_PopularC)
		if `segpop0' == . {
			local segpop0 = r(Atención_a_la_Salud_y_Medicame) //+r(Atenci_c_o__n_a_la_Salud_y_MediC)
		}

		PEF if divPE == 8 & ramo == 12, anio(`anio') by(desc_pp) min(0) nographs
		local atencINSABI = r(Atención_a_la_Salud) //+r(Atenci_c_o__n_a_la_SaludC)
		local fortaINSABI = r(Fortalecimiento_a_la_atención_) //+r(Fortalecimiento_a_la_atenci_c_oC)
		if `fortaINSABI' == . {
			local fortaINSABI = 0
		}

		PEF if divPE == 8, anio(`anio') by(ramo) min(0) nographs
		local fassa = r(Aportaciones_Federales_para_Ent) //+ r(Aportaciones_Federales_para_EntC)

		local imssbien = `segpop0'+`imssbien0'+`fassa'+`fortaINSABI'+`atencINSABI'
		scalar imssbien = `imssbien'/(`Salud'[1,6]-`Salud'[1,1]-`Salud'[1,2]-`Salud'[1,3])
		restore
	}

	capture confirm scalar ssa
	if _rc == 0 {
		local ssa = scalar(ssa)*`Salud'[1,6]
	}
	else {
		preserve
		PEF if divPE == 8, anio(`anio') by(desc_pp) min(0) nographs
		local caneros = r(Seguridad_Social_Cañeros) //+r(Seguridad_Social_Ca_c_n__erosC)
		local incorpo = r(Régimen_de_Incorporación) //+r(R_c_e__gimen_de_Incorporaci_c_oC)
		local adeusal = r(Adeudos_con_el_IMSS_e_ISSSTE_y_)
		if `adeusal' == . {
			local adeusal = 0
		}

		PEF if divPE == 8, anio(`anio') by(ramo) min(0) nographs
		local ssa = r(Salud)+`incorpo'+`adeusal'+`caneros'-`segpop0'-`fortaINSABI'-`atencINSABI'  //+r(SaludC)
		scalar ssa = `ssa'/`Salud'[1,6]
		restore
	}

	capture confirm scalar imss
	if _rc == 0 {
		local imss = scalar(imss)*`Salud'[1,1]
	}
	else {
		preserve
		PEF if divPE == 8, anio(`anio') by(ramo) min(0) nographs
		local imss = r(Instituto_Mexicano_del_Seguro_S) //+r(Instituto_Mexicano_del_Seguro_SC)

		PEF if divPE == 8 & ramo == 50, anio(`anio') by(desc_pp) min(0) nographs			
		local saludciencia = r(Investigación_y_desarrollo_tec) //+ r(Investigaci_c_o__n_y_desarrolloC)

		local imss = `imss' //+ `saludciencia'
		scalar imss = `imss'/`Salud'[1,1]
		restore
	}

	capture confirm scalar issste
	if _rc == 0 {
		local issste = scalar(issste)*`Salud'[1,2]
	}
	else {
		preserve
		PEF if divPE == 8, anio(`anio') by(ramo) min(0) nographs
		local issste = r(Instituto_de_Seguridad_y_Servic) //+r(Instituto_de_Seguridad_y_ServicC)
		
		PEF if divPE == 8 & ramo == 51, anio(`anio') by(desc_pp) min(0) nographs	
		local saludciencia2 = r(Investigación_y_Desarrollo_Tec) //+ r(Investigaci_c_o__n_y_DesarrolloC)
		
		local issste = `issste' //+ `saludciencia2'
		scalar issste = `issste'/`Salud'[1,2]
		restore
	}

	capture confirm scalar pemex
	if _rc == 0 {
		local pemex = scalar(pemex)*`Salud'[1,3]
	}
	else {
		preserve
		PEF if divPE == 8, anio(`anio') by(ramo) min(0) nographs
		local pemex = r(Petróleos_Mexicanos) + r(Defensa_Nacional) + r(Marina) //+ r(Petr_c_o__leos_MexicanosC) + r(Defensa_NacionalC) + r(MarinaC)
		scalar pemex = (`pemex')/`Salud'[1,3]
		restore
	}

	* Resultados *
	noisily di _newline in y "{bf: B. " in y "Salud" "}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  SSA" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `ssa'/`PIB'*100 ///
		_col(60) %15.0fc in y `ssa'/`Salud'[1,6]
	noisily di in g "  IMSS-Bienestar" ///
		_col(33) %15.0fc in y `Salud'[1,6]-`Salud'[1,1]-`Salud'[1,2]-`Salud'[1,3] ///
		_col(50) %7.3fc in y (`imssbien')/`PIB'*100 ///
		_col(60) %15.0fc in y (`imssbien')/(`Salud'[1,6]-`Salud'[1,1]-`Salud'[1,2]-`Salud'[1,3])
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `Salud'[1,1] ///
		_col(50) %7.3fc in y `imss'/`PIB'*100 ///
		_col(60) %15.0fc in y `imss'/`Salud'[1,1]
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `Salud'[1,2] ///
		_col(50) %7.3fc in y `issste'/`PIB'*100 ///
		_col(60) %15.0fc in y `issste'/`Salud'[1,2]
	noisily di in g "  Pemex, ISSFAM" ///
		_col(33) %15.0fc in y `Salud'[1,3] ///
		_col(50) %7.3fc in y `pemex'/`PIB'*100 ///
		_col(60) %15.0fc in y `pemex'/`Salud'[1,3]
	noisily di in g _dup(80) "-"
	noisily di in g "  Salud" ///
		_col(33) %15.0fc in y (`Salud'[1,6]) ///
		_col(50) %7.3fc in y (`ssa'+`imssbien'+`imss'+`issste'+`pemex')/`PIB'*100 ///
		_col(60) %15.0fc in y (`ssa'+`imssbien'+`imss'+`issste'+`pemex')/(`Salud'[1,6])


	replace Salud = 0
	replace Salud = Salud + `imssbien'/(`Salud'[1,5]) if benef_imss == 0 & benef_issste == 0 & benef_pemex == 0
	replace Salud = Salud + `imss'/`Salud'[1,1] if benef_imss > 0
	replace Salud = Salud + `issste'/`Salud'[1,2] if benef_issste > 0
	replace Salud = Salud + `pemex'/`Salud'[1,3] if benef_pemex > 0
	replace Salud = Salud + `ssa'/`Salud'[1,6] if benef_ssa > 0

	scalar ssaPIB = `ssa'/`PIB'*100
	scalar segpopPIB = `imssbien'/`PIB'*100
	scalar imssPIB = `imss'/`PIB'*100
	scalar issstePIB = `issste'/`PIB'*100
	scalar pemexPIB = `pemex'/`PIB'*100
	scalar saludPIB = (`ssa'+`imssbien'+`imss'+`issste'+`pemex')/`PIB'*100
	scalar salud = (`ssa'+`imssbien'+`imss'+`issste'+`pemex')/(`Salud'[1,6])





	*******************
	*** 5 Pensiones ***
	*******************
	g pens_pam = edad >= 65
	g pens_imss = ing_jubila != 0 & formal == 1
	g pens_issste = ing_jubila != 0 & formal == 2
	g pens_pemex = ing_jubila != 0 & formal == 3

	/* 4.1 Ajuste con las estadisticas oficiales *
	tabstat pens_pam pens_imss pens_issste pens_pemex [fw=factor], stat(sum) f(%15.0fc) save
	tempname PENSH
	matrix `PENSH' = r(StatTotal)

	replace pens_pam = pens_pam*10320548/`PENSH'[1,1]
	replace pens_imss = pens_imss*4723530/`PENSH'[1,2]
	replace pens_issste = pens_issste*1230999/`PENSH'[1,3]

	* 4.2 Cifras finales de beneficiarios */
	tabstat pens_pam pens_imss pens_issste pens_pemex [fw=factor], stat(sum) f(%15.0fc) save
	tempname PENS
	matrix `PENS' = r(StatTotal)

	* Inputs *
	capture confirm scalar bienestar
	if _rc == 0 {
		local bienestar = scalar(bienestar)*`PENS'[1,1]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(divPE) min(0) nographs
		local bienestar = r(Pensión_Bienestar)
		scalar bienestar = `bienestar'/`PENS'[1,1]
		restore
	}
	capture confirm scalar penims
	if _rc == 0 {
		local penims = scalar(penims)*`PENS'[1,2]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penims = r(Instituto_Mexicano_del_Seguro_S)
		scalar penims = `penims'/`PENS'[1,2]
		restore
	}
	capture confirm scalar peniss
	if _rc == 0 {
		local peniss = scalar(peniss)*`PENS'[1,3]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local peniss = r(Instituto_de_Seguridad_y_Servic)
		scalar peniss = `peniss'/`PENS'[1,3]
		restore
	}
	capture confirm scalar penotr
	if _rc == 0 {
		local penotr = scalar(penotr)*`PENS'[1,4]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penotr = r(Petróleos_Mexicanos)+r(Aportaciones_a_Seguridad_Social)+r(Comisión_Federal_de_Electricid)
		scalar penotr = `penotr'/`PENS'[1,4]
		restore
	}


	* Resultados *
	noisily di _newline in y "{bf: C. Pensiones}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi{c o'}n para el bienestar" ///
		_col(33) %15.0fc in y `PENS'[1,1] ///
		_col(50) %7.3fc in y `bienestar'/`PIB'*100 ///
		_col(60) %15.0fc in y `bienestar'/`PENS'[1,1]
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `PENS'[1,2] ///
		_col(50) %7.3fc in y `penims'/`PIB'*100 ///
		_col(60) %15.0fc in y `penims'/`PENS'[1,2]
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `PENS'[1,3] ///
		_col(50) %7.3fc in y `peniss'/`PIB'*100 ///
		_col(60) %15.0fc in y `peniss'/`PENS'[1,3]
	noisily di in g "  Pemex, CFE, LFC, Ferro, ISSFAM" ///
		_col(33) %15.0fc in y `PENS'[1,4] ///
		_col(50) %7.3fc in y `penotr'/`PIB'*100 ///
		_col(60) %15.0fc in y `penotr'/`PENS'[1,4]
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`PENS'[1,1]+`PENS'[1,2]+`PENS'[1,3]+`PENS'[1,4]) ///
		_col(50) %7.3fc in y (`bienestar'+`penims'+`peniss'+`penotr')/`PIB'*100 ///
		_col(60) %15.0fc in y (`bienestar'+`penims'+`peniss'+`penotr')/(`PENS'[1,1]+`PENS'[1,2]+`PENS'[1,3]+`PENS'[1,4])

	replace PenBienestar = `bienestar'/`PENS'[1,1] if edad >= 65
	replace Pension = `penims'/`PENS'[1,2] if formal == 1 & ing_jubila != 0
	replace Pension = `peniss'/`PENS'[1,3] if formal == 2 & ing_jubila != 0 
	replace Pension = `penotr'/`PENS'[1,4] if formal == 3 & ing_jubila != 0

	scalar bienestarPIB = `bienestar'/`PIB'*100
	scalar penimsPIB = `penims'/`PIB'*100
	scalar penissPIB = `peniss'/`PIB'*100
	scalar penotrPIB = `penotr'/`PIB'*100
	scalar pensionPIB = (`bienestar'+`penims'+`peniss'+`penotr')/`PIB'*100
	scalar pensiones = (`bienestar'+`penims'+`peniss'+`penotr')/(`PENS'[1,1]+`PENS'[1,2]+`PENS'[1,3]+`PENS'[1,4])







	***********************
	*** 6 Comprometidos ***
	***********************

	* Inputs *
	capture confirm scalar gaspemex
	if _rc == 0 {
		local gaspemex = gaspemex*`Salud'[1,6]
	}
	else {
		preserve
		PEF if divPE == 3, by(ramo) anio(`anio') min(0) nographs
		local gaspemex = r(Petróleos_Mexicanos)
		scalar gaspemex = `gaspemex'/`Salud'[1,6]
		restore
	}

	capture confirm scalar gascfe
	if _rc == 0 {
		local gascfe = gascfe*`Salud'[1,6]
	}
	else {
		preserve
		PEF if divPE == 3, by(ramo) anio(`anio') min(0) nographs
		local gascfe = r(Comisión_Federal_de_Electricid)
		scalar gascfe = `gascfe'/`Salud'[1,6]
		restore
	}

	capture confirm scalar gassener
	if _rc == 0 {
		local gassener = gassener*`Salud'[1,6]
	}
	else {
		preserve
		PEF if divPE == 3, by(ramo) anio(`anio') min(0) nographs
		local gassener = r(Gasto_neto)-r(Comisión_Federal_de_Electricid)-r(Petróleos_Mexicanos)
		scalar gassener = `gassener'/`Salud'[1,6]
		restore
	}

	capture confirm scalar gasfeder
	if _rc == 0 {
		local gasfeder = gasfeder*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasfeder = r(Federalizado)
		scalar gasfeder = `gasfeder'/`Salud'[1,6]
		restore
	}

	capture confirm scalar gascosto
	if _rc == 0 {
		local gascosto = gascosto*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gascosto = r(Costo_de_la_deuda)
		scalar gascosto = `gascosto'/`Salud'[1,6]
		restore
	}

	capture confirm scalar gasinfra
	if _rc == 0 {
		local gasinfra = gasinfra*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasinfra = r(Infraestructura)
		scalar gasinfra = `gasinfra'/`Salud'[1,6]
		restore
	}

	capture confirm scalar gasotros
	if _rc == 0 {
		local gasotros = gasotros*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasotros = r(Otros)
		scalar gasotros = `gasotros'/`Salud'[1,6]
		restore
	}

	* Resultados *
	noisily di _newline in y "{bf: D. Otros gastos}"
	noisily di _newline in g "{bf:  Gasto por divisi{c o'}n CIEP" ///
		_col(33) %15s in g "Poblacion" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Energía" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y (`gaspemex'+`gascfe'+`gassener')/`PIB'*100 ///
		_col(60) %15.0fc in y (`gaspemex'+`gascfe'+`gassener')/`Salud'[1,6]
	noisily di in g "  Gasto federalizado" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gasfeder'/`PIB'*100 ///
		_col(60) %15.0fc in y `gasfeder'/`Salud'[1,6]
	noisily di in g "  Costo de la deuda" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gascosto'/`PIB'*100 ///
		_col(60) %15.0fc in y `gascosto'/`Salud'[1,6]
	noisily di in g "  Infraestructura" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gasinfra'/`PIB'*100 ///
		_col(60) %15.0fc in y `gasinfra'/`Salud'[1,6]
	noisily di in g "  Resto de los gastos" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gasotros'/`PIB'*100 ///
		_col(60) %15.0fc in y `gasotros'/`Salud'[1,6]
	noisily di in g _dup(80) "-"
	noisily di in g "  Otros gastos" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros')/`PIB'*100 ///
		_col(60) %15.0fc in y (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros')/`Salud'[1,6]

	replace OtrosGas = OtrosGas*(`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros')/`Salud'[1,6]
	replace Infra = Infra*`gasinfra'/`Salud'[1,6]

	/*scalar servpersPIB = `servpers'/`PIB'*100
	scalar matesumiPIB = `matesumi'/`PIB'*100
	scalar gastgenePIB = `gastgene'/`PIB'*100
	scalar substranPIB = `substran'/`PIB'*100
	scalar bienmuebPIB = `bienmueb'/`PIB'*100
	scalar obrapublPIB = `obrapubl'/`PIB'*100
	scalar invefinaPIB = `invefina'/`PIB'*100
	scalar partaporPIB = `partapor'/`PIB'*100
	scalar costodeuPIB = `costodeu'/`PIB'*100
	scalar otrosgasPIB = (`servpers'+`matesumi'+`gastgene'+`substran'+`bienmueb'+`obrapubl'+`invefina'+`partapor'+`costodeu')/`PIB'*100
	scalar otrosgastos = (`servpers'+`matesumi'+`gastgene'+`substran'+`bienmueb'+`obrapubl'+`invefina'+`partapor'+`costodeu')/`Salud'[1,6]




	
	****************************/
	*** 6 Ingreso b{c a'}sico ***
	*****************************
	local bititle = "General"
	capture confirm scalar ingbasico18
	if _rc != 0 {
		scalar ingbasico18 = 1
	}
	capture confirm scalar ingbasico65
	if _rc != 0 {
		scalar ingbasico65 = 1
	}

	if ingbasico18 == 0 & ingbasico65 == 1 {
		tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Mayores de 18"
	}
	else if ingbasico18 == 1 & ingbasico65 == 0 {
		tabstat factor if edad < 65, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Menores de 65"
	}
	else if ingbasico18 == 0 & ingbasico65 == 0 {
		tabstat factor if edad < 65 & edad >= 18, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Entre 18 y 65"
	}
	else {
		tabstat factor, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Poblaci{c o'}n general"		
	}


	* Inputs *
	capture confirm scalar IngBas
	if _rc == 0 {
		local IngBas = scalar(IngBas)*`pobIngBas'[1,1]
		*local IngBas = `IngBas'-(`IngBas'*(1-.06270)*0.084)
	}
	else {
		local IngBas = 0
		scalar IngBas = `IngBas'/`pobIngBas'[1,1]
	}

	* Resultados *
	noisily di _newline in y "{bf: E. Ingreso b{c a'}sico}" 
	noisily di _newline in g "{bf:  Gasto por ingreso b{c a'}sico" ///
		_col(33) %15s in g "Poblaci{c o'}n" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  `bititle'" ///
		_col(33) %15.0fc in y `pobIngBas'[1,1] ///
		_col(50) %7.3fc in y `IngBas'/`PIB'*100 ///
		_col(60) %15.0fc in y `IngBas'/`pobIngBas'[1,1]



	if ingbasico18 == 0 & ingbasico65 == 1 {
		replace IngBasico = `IngBas'/`pobIngBas'[1,1] if edad >= 18
	}
	else if ingbasico18 == 1 & ingbasico65 == 0 {
		replace IngBasico = `IngBas'/`pobIngBas'[1,1] if edad < 65
	}
	else if ingbasico18 == 0 & ingbasico65 == 0 {
		replace IngBasico = `IngBas'/`pobIngBas'[1,1] if edad >= 18 & edad < 65
	}
	else { 
		replace IngBasico = `IngBas'/`pobIngBas'[1,1]
	}

	scalar ingbasPIB = `IngBas'/`PIB'*100
	scalar ingbasico = `IngBas'/`pobIngBas'[1,1]

	
	
	
	

	******************************
	*** 8 Salarios de gobierno ***
	/*****************************
	tabstat ing_subor if scian == "93" [fw=factor], stat(sum) f(%20.0fc) save
	tempname salarios
	matrix `salarios' = r(StatTotal)

	g Salarios = ing_subor*`servpers'/`salarios'[1,1] if scian == "93"
	replace Salarios = 0 if Salarios == .




	*****************
	*** 9 Base SIM ***
	******************
	tabstat Pension Educacion Salud OtrosGas Infra [fw=factor], stat(sum) f(%20.0fc) save
	tempname GASTOSSIM TRANSFSIM
	matrix `GASTOSSIM' = r(StatTotal)

	tabstat IngBasico PenBienestar [fw=factor], stat(sum) f(%20.0fc) save
	matrix `TRANSFSIM' = r(StatTotal)

	keep folio* numren factor* Laboral Consumo OtrosC ISR__PM ing_cap_fmp Petroleo CuotasSS ///
		Pension Educacion Salud IngBasico PenBienestar Salarios OtrosGas Infra ///
		sexo grupoedad decil escol edad ing_bruto_tax prop_formal ///
		deduc_isr ISR categF ISR__asalariados ISR__PF cuotas* ingbrutotot htrab ///
		tipo_contribuyente exen_tot formal* *_tpm *_t2_* *_t4_* ing_mixto* isrE ing_subor IVA* IEPS* ///
		gasto_anualDepreciacion prop_* SE ImpNet* infonavit fovissste
	}

	** Guardar **
	capture drop __*
	if `c(version)' > 13.1 {
	*saveold `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace version(13)
	}
	else {
	*save `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace	
	}




	**************************/
	** 10 Estimaciones de LP **
	/***************************
	tempname GASBase
	local j = 1
	foreach k in Pension Educacion Salud OtrosGas {
	use `"`c(sysdir_site)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `GASBase' = r(StatTotal)

	if "`k'" != "OtrosGas" {
		replace estimacion = estimacion*`GASTOSSIM'[1,`j']/`GASBase'[1,1] if anio >= `anio'
	}

	if "`k'" == "OtrosGas" {
		replace estimacion = estimacion*`GASTOSSIM'[1,`j']/`GASBase'[1,1]*`otros' if anio >= `anio'
	}

	local ++j
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_site)'/users/$pais/$id/`k'REC.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_site)'/users/$pais/$id/`k'REC.dta"', replace		
	}
	}

	tempname TRABase
	local j = 1
	foreach k in IngBasico PenBienestar {
	use `"`c(sysdir_site)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `TRABase' = r(StatTotal)

	replace estimacion = estimacion*`TRANSFSIM'[1,`j']/`TRABase'[1,1] if anio >= `anio'

	local ++j
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_site)'/users/$pais/$id/`k'REC.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_site)'/users/$pais/$id/`k'REC.dta"', replace		
	}
	}




	****************/
	*** 11 OUTPUT ***
	*****************
	if "$output" == "output" & "$pais" == "" {
		quietly log on output
		noisily di in w "GASTOS: " in w "["  ///
			/*"basicaPIB "*/ %8.3f basicaPIB ", " ///
			/*"medsupPIB "*/ %8.3f medsupPIB ", " ///
			/*"superiPIB "*/ %8.3f superiPIB ", " ///
			/*"posgraPIB "*/ %8.3f posgraPIB ", " ///
			/*"eduaduPIB "*/ %8.3f eduaduPIB ", " ///
			/*"otrosePIB "*/ %8.3f otrosePIB ", " ///
			/*"educacPIB "*/ %8.3f educacPIB ", " ///
			/*"ssaPIB "*/ %8.3f ssaPIB ", " ///
			/*"prospePIB "*/ %8.3f prospePIB ", " ///
			/*"segpopPIB "*/ %8.3f segpopPIB ", " ///
			/*"imssPIB "*/ %8.3f imssPIB ", " ///
			/*"issstePIB "*/ %8.3f issstePIB ", " ///
			/*"pemexPIB "*/ %8.3f pemexPIB ", " ///
			/*"saludPIB "*/ %8.3f saludPIB ", " ///
			/*"bienestarPIB "*/ %8.3f bienestarPIB ", " ///
			/*"penimsPIB "*/ %8.3f penimsPIB ", " ///
			/*"penissPIB "*/ %8.3f penissPIB ", " ///
			/*"penotrPIB "*/ %8.3f penotrPIB ", " ///
			/*"pensionPIB "*/ %8.3f pensionPIB ", " ///
			/*"servpersPIB "*/ %8.3f servpersPIB ", " ///
			/*"matesumiPIB "*/ %8.3f matesumiPIB ", " ///
			/*"gastgenePIB "*/ %8.3f gastgenePIB ", " ///
			/*"substranPIB "*/ %8.3f substranPIB ", " ///
			/*"bienmuebPIB "*/ %8.3f bienmuebPIB ", " ///
			/*"obrapublPIB "*/ %8.3f obrapublPIB ", " ///
			/*"invefinaPIB "*/ %8.3f invefinaPIB ", " ///
			/*"partaporPIB "*/ %8.3f partaporPIB ", " ///
			/*"costodeuPIB "*/ %8.3f costodeuPIB ", " ///
			/*"otrosgasPIB "*/ %8.3f otrosgasPIB ", " ///
			/*"ingbasPIB "*/ %8.3f ingbasPIB ///
			"]"		
		noisily di in w "INPUTSG: " in w "["  ///
			/*"basicaPIB "*/ %8.0f basica ", " ///
			/*"medsupPIB "*/ %8.0f medsup ", " ///
			/*"superiPIB "*/ %8.0f superi ", " ///
			/*"posgraPIB "*/ %8.0f posgra ", " ///
			/*"eduaduPIB "*/ %8.0f eduadu ", " ///
			/*"otrosePIB "*/ %8.0f otrose ", " ///
			/*"educacPIB "*/ %8.0f educacion ", " ///
			/*"ssaPIB "*/ %8.0f ssa ", " ///
			/*"prospePIB "*/ %8.0f prospe ", " ///
			/*"segpopPIB "*/ %8.0f segpop ", " ///
			/*"imssPIB "*/ %8.0f imss ", " ///
			/*"issstePIB "*/ %8.0f issste ", " ///
			/*"pemexPIB "*/ %8.0f pemex ", " ///
			/*"saludPIB "*/ %8.0f salud ", " ///
			/*"bienestarPIB "*/ %8.0f bienestar ", " ///
			/*"penimsPIB "*/ %8.0f penims ", " ///
			/*"penissPIB "*/ %8.0f peniss ", " ///
			/*"penotrPIB "*/ %8.0f penotr ", " ///
			/*"pensionPIB "*/ %8.0f pensiones ", " ///
			/*"servpersPIB "*/ %8.0f servpers ", " ///
			/*"matesumiPIB "*/ %8.0f matesumi ", " ///
			/*"gastgenePIB "*/ %8.0f gastgene ", " ///
			/*"substranPIB "*/ %8.0f substran ", " ///
			/*"bienmuebPIB "*/ %8.0f bienmueb ", " ///
			/*"obrapublPIB "*/ %8.0f obrapubl ", " ///
			/*"invefinaPIB "*/ %8.0f invefina ", " ///
			/*"partaporPIB "*/ %8.0f partapor ", " ///
			/*"costodeuPIB "*/ %8.0f costodeu ", " ///
			/*"otrosgasPIB "*/ %8.0f otrosgastos ", " ///
			/*"costodeuPIB "*/ %8.0f ingbasico ", " ///
			/*"otrosgasPIB "*/ %8.0f ingbasico18 ", " ///
			/*"ingbasPIB "*/ %8.0f ingbasico65 ///
			"]"
		noisily di in w "GASTOSTOTAL: " in w "["  ///
			%8.3f educacPIB +saludPIB+pensionPIB+otrosgasPIB+ingbasPIB ///
		"]"
		quietly log off output
	}




	***********
	*** END ***
	***********
	timer off 9
	timer list 9
	noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
}
end
