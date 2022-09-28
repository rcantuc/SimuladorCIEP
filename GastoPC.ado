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
	PIBDeflactor, aniovp(`anio') nographs nooutput
	keep if anio == `anio'
	local PIB = pibY[1]





	************************
	*** 2 TRANSFERENCIAS ***
	************************
	use "`c(sysdir_site)'/SIM/2020/households`=aniovp'.dta", clear
	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobenigh
	matrix `pobenigh' = r(StatTotal)

	tabstat Pension Educacion Salud OtrosGas Infra [fw=factor], stat(sum) f(%20.0fc) save
	matrix GASTOS = r(StatTotal)





	*******************
	*** 3 Educacion ***
	*******************
	capture drop alum_*
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
	scalar basicaPIB = (`basica')/`PIB'*100

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
	scalar medsupPIB = (`medsup')/`PIB'*100

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
	scalar superiPIB = (`superi')/`PIB'*100

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
	scalar posgraPIB = (`posgra')/`PIB'*100

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
	scalar eduaduPIB = (`eduadu')/`PIB'*100

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
	scalar otrosePIB = (`otrose')/`PIB'*100
	scalar educacPIB = (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/`PIB'*100
	scalar educacion = (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/ ///
		(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5])

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






	***************/
	*** 4 Salud ***
	***************
	capture drop benef_*
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
		PEF if divPE == 9, anio(`anio') by(desc_pp) min(0) nographs
		local imssbien0 = r(Programa_IMSS_BIENESTAR) //+r(Programa_IMSS_BIENESTARC)
		local segpop0 = r(Seguro_Popular) //+r(Seguro_PopularC)
		if `segpop0' == . {
			local segpop0 = r(Atención_a_la_Salud_y_Medicame) //+r(Atenci_c_o__n_a_la_Salud_y_MediC)
		}

		PEF if divPE == 9 & ramo == 12, anio(`anio') by(desc_pp) min(0) nographs
		local atencINSABI = r(Atención_a_la_Salud) //+r(Atenci_c_o__n_a_la_SaludC)
		local fortaINSABI = r(Fortalecimiento_a_la_atención_) //+r(Fortalecimiento_a_la_atenci_c_oC)
		if `fortaINSABI' == . {
			local fortaINSABI = 0
		}

		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local fassa = r(Aportaciones_Federales_para_Ent) //+ r(Aportaciones_Federales_para_EntC)

		local imssbien = `segpop0'+`imssbien0'+`fassa'+`fortaINSABI'+`atencINSABI'
		scalar imssbien = `imssbien'/(`Salud'[1,6]-`Salud'[1,1]-`Salud'[1,2]-`Salud'[1,3])
		restore
	}
	scalar imssbienPIB = `imssbien'/`PIB'*100

	capture confirm scalar ssa
	if _rc == 0 {
		local ssa = scalar(ssa)*`Salud'[1,6]
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(desc_pp) min(0) nographs
		local caneros = r(Seguridad_Social_Cañeros) //+r(Seguridad_Social_Ca_c_n__erosC)
		local incorpo = r(Régimen_de_Incorporación) //+r(R_c_e__gimen_de_Incorporaci_c_oC)
		local adeusal = r(Adeudos_con_el_IMSS_e_ISSSTE_y_)
		if `adeusal' == . {
			local adeusal = 0
		}

		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local ssa = r(Salud)+`incorpo'+`adeusal'+`caneros'-`segpop0'-`fortaINSABI'-`atencINSABI'  //+r(SaludC)
		scalar ssa = `ssa'/`Salud'[1,6]
		restore
	}
	scalar ssaPIB = `ssa'/`PIB'*100

	capture confirm scalar imss
	if _rc == 0 {
		local imss = scalar(imss)*`Salud'[1,1]
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local imss = r(Instituto_Mexicano_del_Seguro_S) //+r(Instituto_Mexicano_del_Seguro_SC)

		PEF if divPE == 9 & ramo == 50, anio(`anio') by(desc_pp) min(0) nographs			
		local saludciencia = r(Investigación_y_desarrollo_tec) //+ r(Investigaci_c_o__n_y_desarrolloC)

		local imss = `imss' //+ `saludciencia'
		scalar imss = `imss'/`Salud'[1,1]
		restore
	}
	scalar imssPIB = `imss'/`PIB'*100

	capture confirm scalar issste
	if _rc == 0 {
		local issste = scalar(issste)*`Salud'[1,2]
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local issste = r(Instituto_de_Seguridad_y_Servic) //+r(Instituto_de_Seguridad_y_ServicC)
		
		PEF if divPE == 9 & ramo == 51, anio(`anio') by(desc_pp) min(0) nographs	
		local saludciencia2 = r(Investigación_y_Desarrollo_Tec) //+ r(Investigaci_c_o__n_y_DesarrolloC)
		
		local issste = `issste' //+ `saludciencia2'
		scalar issste = `issste'/`Salud'[1,2]
		restore
	}
	scalar issstePIB = `issste'/`PIB'*100

	capture confirm scalar pemex
	if _rc == 0 {
		local pemex = scalar(pemex)*`Salud'[1,3]
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local pemex = r(Petróleos_Mexicanos) + r(Defensa_Nacional) + r(Marina) //+ r(Petr_c_o__leos_MexicanosC) + r(Defensa_NacionalC) + r(MarinaC)
		scalar pemex = (`pemex')/`Salud'[1,3]
		restore
	}
	scalar pemexPIB = `pemex'/`PIB'*100
	scalar saludPIB = (`ssa'+`imssbien'+`imss'+`issste'+`pemex')/`PIB'*100
	scalar salud = (`ssa'+`imssbien'+`imss'+`issste'+`pemex')/(`Salud'[1,6])

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
	replace Salud = Salud + `imssbien'/(`Salud'[1,6]-`Salud'[1,1]-`Salud'[1,2]-`Salud'[1,3]) ///
		if benef_imss == 0 & benef_issste == 0 & benef_pemex == 0
	replace Salud = Salud + `imss'/`Salud'[1,1] if benef_imss > 0
	replace Salud = Salud + `issste'/`Salud'[1,2] if benef_issste > 0
	replace Salud = Salud + `pemex'/`Salud'[1,3] if benef_pemex > 0
	replace Salud = Salud + `ssa'/`Salud'[1,6] if benef_ssa > 0





	*******************
	*** 5 Pensiones ***
	*******************
	capture drop pens_*
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
		PEF if divCIEP == 8, anio(`anio') by(divCIEP) min(0) nographs
		local bienestar = r(Pensión_Bienestar)
		scalar bienestar = `bienestar'/`PENS'[1,1]
		restore
	}
	scalar bienestarPIB = `bienestar'/`PIB'*100

	capture confirm scalar penimss
	if _rc == 0 {
		local penimss = scalar(penimss)*`PENS'[1,2]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penimss = r(Instituto_Mexicano_del_Seguro_S)
		scalar penimss = `penimss'/`PENS'[1,2]
		restore
	}
	scalar penimssPIB = `penimss'/`PIB'*100
	
	capture confirm scalar penisss
	if _rc == 0 {
		local penisss = scalar(penisss)*`PENS'[1,3]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penisss = r(Instituto_de_Seguridad_y_Servic)
		scalar penisss = `penisss'/`PENS'[1,3]
		restore
	}
	scalar penisssPIB = `penisss'/`PIB'*100

	capture confirm scalar penotro
	if _rc == 0 {
		local penotro = scalar(penotro)*`PENS'[1,4]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penotro = r(Petróleos_Mexicanos)+r(Aportaciones_a_Seguridad_Social)+r(Comisión_Federal_de_Electricid)
		scalar penotro = `penotro'/`PENS'[1,4]
		restore
	}
	scalar penotroPIB = `penotro'/`PIB'*100
	scalar pensionPIB = (`bienestar'+`penimss'+`penisss'+`penotro')/`PIB'*100
	scalar pensiones = (`bienestar'+`penimss'+`penisss'+`penotro')/(`PENS'[1,1]+`PENS'[1,2]+`PENS'[1,3]+`PENS'[1,4])

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
		_col(50) %7.3fc in y `penimss'/`PIB'*100 ///
		_col(60) %15.0fc in y `penimss'/`PENS'[1,2]
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `PENS'[1,3] ///
		_col(50) %7.3fc in y `penisss'/`PIB'*100 ///
		_col(60) %15.0fc in y `penisss'/`PENS'[1,3]
	noisily di in g "  Pemex, CFE, LFC, Ferro, ISSFAM" ///
		_col(33) %15.0fc in y `PENS'[1,4] ///
		_col(50) %7.3fc in y `penotro'/`PIB'*100 ///
		_col(60) %15.0fc in y `penotro'/`PENS'[1,4]
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`PENS'[1,1]+`PENS'[1,2]+`PENS'[1,3]+`PENS'[1,4]) ///
		_col(50) %7.3fc in y (`bienestar'+`penimss'+`penisss'+`penotro')/`PIB'*100 ///
		_col(60) %15.0fc in y (`bienestar'+`penimss'+`penisss'+`penotro')/(`PENS'[1,1]+`PENS'[1,2]+`PENS'[1,3]+`PENS'[1,4])

	replace PenBienestar = `bienestar'/`PENS'[1,1] if edad >= 65
	replace Pension = `penimss'/`PENS'[1,2] if formal == 1 & ing_jubila != 0
	replace Pension = `penisss'/`PENS'[1,3] if formal == 2 & ing_jubila != 0 
	replace Pension = `penotro'/`PENS'[1,4] if formal == 3 & ing_jubila != 0




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
	scalar gaspemexPIB = `gaspemex'/`PIB'*100

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
	scalar gascfePIB = `gascfe'/`PIB'*100

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
	scalar gassenerPIB = `gassener'/`PIB'*100

	capture confirm scalar gasfeder
	if _rc == 0 {
		local gasfeder = gasfeder*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasfeder = r(Otras_Part_y_Apor)
		scalar gasfeder = `gasfeder'/`Salud'[1,6]
		restore
	}
	scalar gasfederPIB = `gasfeder'/`PIB'*100

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
	scalar gascostoPIB = `gascosto'/`PIB'*100

	capture confirm scalar gasinfra
	if _rc == 0 {
		local gasinfra = gasinfra*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasinfra = r(Inversión)
		scalar gasinfra = `gasinfra'/`Salud'[1,6]
		restore
	}
	scalar gasinfraPIB = `gasinfra'/`PIB'*100

	capture confirm scalar gasotros
	if _rc == 0 {
		local gasotros = gasotros*`Salud'[1,6]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasotros = r(Otros)+r(Cuotas_ISSSTE)
		scalar gasotros = `gasotros'/`Salud'[1,6]
		restore
	}
	scalar gasotrosPIB = `gasotros'/`PIB'*100

	* Resultados *
	noisily di _newline in y "{bf: D. Otros gastos}"
	noisily di _newline in g "{bf:  Gasto por divisi{c o'}n CIEP" ///
		_col(33) %15s in g "Poblacion" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  CFE" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y (`gascfe')/`PIB'*100 ///
		_col(60) %15.0fc in y (`gascfe')/`Salud'[1,6]
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y (`gaspemex')/`PIB'*100 ///
		_col(60) %15.0fc in y (`gaspemex')/`Salud'[1,6]
	noisily di in g "  SENER y otros" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y (`gassener')/`PIB'*100 ///
		_col(60) %15.0fc in y (`gassener')/`Salud'[1,6]
	noisily di in g "  Inversión" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gasinfra'/`PIB'*100 ///
		_col(60) %15.0fc in y `gasinfra'/`Salud'[1,6]
	noisily di in g "  Costo de la deuda" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gascosto'/`PIB'*100 ///
		_col(60) %15.0fc in y `gascosto'/`Salud'[1,6]
	noisily di in g "  Otras Part y Aport" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gasfeder'/`PIB'*100 ///
		_col(60) %15.0fc in y `gasfeder'/`Salud'[1,6]
	noisily di in g "  Resto de los gastos" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y `gasotros'/`PIB'*100 ///
		_col(60) %15.0fc in y `gasotros'/`Salud'[1,6]
	noisily di in g _dup(80) "-"
	noisily di in g "  Otros gastos" ///
		_col(33) %15.0fc in y `Salud'[1,6] ///
		_col(50) %7.3fc in y (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros')/`PIB'*100 ///
		_col(60) %15.0fc in y (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros')/`Salud'[1,6]


	capture drop _OtrosGas
	Distribucion _OtrosGas, relativo(OtrosGas) macro(`=`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gasinfra'+`gasotros'')

	capture drop _Infra
	Distribucion _Infra, relativo(infra_entidad) macro(`gasinfra')




	
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
	scalar IngBasPIB = `IngBas'/`PIB'*100
	scalar ingbasico = `IngBas'/`pobIngBas'[1,1]
	scalar otrosgasPIB = (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros'+`IngBas')/`PIB'*100
	scalar otrosgastos = (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros'+`IngBas')/`Salud'[1,6]

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



	******************************
	*** 8 Salarios de gobierno ***
	/*****************************
	tabstat ing_subor if scian == "93" [fw=factor], stat(sum) f(%20.0fc) save
	tempname salarios
	matrix `salarios' = r(StatTotal)

	g Salarios = ing_subor*`servpers'/`salarios'[1,1] if scian == "93"
	replace Salarios = 0 if Salarios == .





	*****************/
	*** 9 Base SIM ***
	******************
	capture drop __*
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace	
	}



	****************/
	*** 11 OUTPUT ***
	*****************
	if "$output" == "output" & "$pais" == "" {
		quietly log on output
		noisily di in w "GASTOS: " in w "["  ///
			%8.3f basicaPIB ", " ///
			%8.3f medsupPIB ", " ///
			%8.3f superiPIB ", " ///
			%8.3f posgraPIB ", " ///
			%8.3f eduaduPIB ", " ///
			%8.3f otrosePIB ", " ///
			%8.3f basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB ", " ///
			%8.3f ssaPIB ", " ///
			%8.3f imssbienPIB ", " ///
			%8.3f imssPIB ", " ///
			%8.3f issstePIB ", " ///
			%8.3f pemexPIB ", " ///
			%8.3f ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB ", " ///
			%8.3f bienestarPIB ", " ///
			%8.3f penimssPIB ", " ///
			%8.3f penisssPIB ", " ///
			%8.3f penotroPIB ", " ///
			%8.3f bienestarPIB+penimssPIB+penisssPIB+penotroPIB ", " ///
			%8.3f gascfePIB ", " ///
			%8.3f gaspemexPIB ", " ///
			%8.3f gassenerPIB ", " ///
			%8.3f gasinfraPIB ", " ///
			%8.3f gascostoPIB ", " ///
			%8.3f gasfederPIB ", " ///
			%8.3f gasotrosPIB ", " ///
			%8.3f gascfePIB+gaspemexPIB+gassenerPIB+gasinfraPIB+gascostoPIB+gasfederPIB+gasotrosPIB ", " ///
			%8.3f IngBasPIB ", " ///
			%8.3f basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB+ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+bienestarPIB+penimssPIB+penisssPIB+penotroPIB+gascfePIB+gaspemexPIB+gassenerPIB+gasinfraPIB+gascostoPIB+gasfederPIB+gasotrosPIB+IngBasPIB ///
			"]"		
		noisily di in w "GASTOSPC: " in w "["  ///
			%8.0f basica ", " ///
			%8.0f medsup ", " ///
			%8.0f superi ", " ///
			%8.0f posgra ", " ///
			%8.0f eduadu ", " ///
			%8.0f otrose ", " ///
			%8.0f scalar(educacion) ", " ///
			%8.0f ssa ", " ///
			%8.0f imssbien ", " ///
			%8.0f imss ", " ///
			%8.0f issste ", " ///
			%8.0f pemex ", " ///
			%8.0f scalar(salud) ", " ///
			%8.0f bienestar ", " ///
			%8.0f penimss ", " ///
			%8.0f penisss ", " ///
			%8.0f penotro ", " ///
			%8.0f pensiones ", " ///
			%8.0f gascfe ", " ///
			%8.0f gaspemex ", " ///
			%8.0f gassener ", " ///
			%8.0f gasinfra ", " ///
			%8.0f gascosto ", " ///
			%8.0f gasfeder ", " ///
			%8.0f gasotros ", " ///
			%8.0f otrosgastos ", " ///
			%8.0f ingbasico ", " ///
			%8.0f ingbasico18 ", " ///
			%8.0f ingbasico65 ///
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
