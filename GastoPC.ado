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
	*use if anio == `anio' using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
	PIBDeflactor, aniovp(`anio') nographs nooutput
	keep if anio == `anio'
	local PIB = pibY[1]





	************************
	*** 2 TRANSFERENCIAS ***
	************************
	use "`c(sysdir_personal)'/SIM/2020/households`anio'.dta", clear
	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobenigh
	matrix `pobenigh' = r(StatTotal)





	*******************
	*** 3 Educación ***
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


	/** 3.1 Ajuste con las estadisticas oficiales **
	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto [fw=factor], stat(sum) f(%20.0fc) save
	tempname EducacionI
	matrix `EducacionI' = r(StatTotal)

	replace alum_basica = alum_basica*24597234/`EducacionI'[1,1]
	replace alum_medsup = alum_medsup*5353499/`EducacionI'[1,2]
	replace alum_superi = alum_superi*4579894/`EducacionI'[1,3]
	replace alum_posgra = alum_posgra*403312/`EducacionI'[1,4]
	replace alum_adulto = alum_adulto*1905180/`EducacionI'[1,5]


	** 3.2 Cifras finales de alumnos **/
	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto [fw=factor], stat(sum) f(%20.0fc) save
	tempname Educacion
	matrix `Educacion' = r(StatTotal)
	
	local alum_basica = `Educacion'[1,1]
	local alum_medsup = `Educacion'[1,2]
	local alum_superi = `Educacion'[1,3]
	local alum_posgra = `Educacion'[1,4]
	local alum_adulto = `Educacion'[1,5]


	** 3.3 Básica **
	capture confirm scalar basica
	if _rc == 0 {
		local basica = scalar(basica)*`alum_basica'
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) rows(3) nographs
		local basica = r(Educación_Básica)
		scalar basica = `basica'/`alum_basica'
		restore
	}
	scalar basicaPIB = (`basica')/`PIB'*100


	** 3.4 Media superior **
	capture confirm scalar medsup
	if _rc == 0 {
		local medsup = scalar(medsup)*`alum_medsup'
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local medsup = r(Educación_Media_Superior)
		scalar medsup = `medsup'/`alum_medsup'
		restore
	}
	scalar medsupPIB = (`medsup')/`PIB'*100


	** 3.5 Superior **
	capture confirm scalar superi
	if _rc == 0 {
		local superi = scalar(superi)*`alum_superi'
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local superi = r(Educación_Superior)
		scalar superi = `superi'/`alum_superi'
		restore
	}
	scalar superiPIB = (`superi')/`PIB'*100


	** 3.6 Posgrado **
	capture confirm scalar posgra
	if _rc == 0 {
		local posgra = scalar(posgra)*`alum_posgra'
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local posgra = r(Posgrado)
		scalar posgra = `posgra'/`alum_posgra'
		restore
	}
	scalar posgraPIB = (`posgra')/`PIB'*100


	** 3.7 Educación para adultos **
	capture confirm scalar eduadu
	if _rc == 0 {
		local eduadu = scalar(eduadu)*`alum_adulto'
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local eduadu = r(Educación_para_Adultos)

		scalar eduadu = `eduadu'/`alum_adulto'
		restore
	}
	scalar eduaduPIB = (`eduadu')/`PIB'*100


	** 3.8 Otros gastos educativos **
	capture confirm scalar otrose
	if _rc == 0 {
		local otrose = scalar(otrose)*(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')
	}
	else {
		preserve
		PEF if divPE == 2, anio(`anio') by(desc_subfuncion) min(0) nographs
		local otrose = r(Otros_Servicios_Educativos_y_Ac) + r(Cultura) + r(Deporte_y_Recreación) ///
			+ r(Desarrollo_Tecnológico) + r(Función_Pública) ///
			+ r(Investigación_Científica) + r(Servicios_Científicos_y_Tecnol)

		scalar otrose = `otrose'/(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')
		restore
	}
	scalar otrosePIB = (`otrose')/`PIB'*100

	scalar educacPIB = basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB
	scalar educacion = (`basica'+`medsup'+`superi'+`posgra'+`eduadu'+`otrose')/ ///
		(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')

	* Resultados *
	noisily di _newline in y "{bf: A. Educaci{c o'}n p{c u'}blica" "}"
	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  B{c a'}sica" ///
		_col(33) %15.0fc in y `alum_basica' ///
		_col(50) %7.3fc in y scalar(basicaPIB) ///
		_col(60) %15.0fc in y scalar(basica)
	noisily di in g "  Media superior" ///
		_col(33) %15.0fc in y `alum_medsup' ///
		_col(50) %7.3fc in y scalar(medsupPIB) ///
		_col(60) %15.0fc in y scalar(medsup)
	noisily di in g "  Superior" ///
		_col(33) %15.0fc in y `alum_superi' ///
		_col(50) %7.3fc in y scalar(superiPIB) ///
		_col(60) %15.0fc in y scalar(superi)
	noisily di in g "  Posgrado" ///
		_col(33) %15.0fc in y `alum_posgra' ///
		_col(50) %7.3fc in y scalar(posgraPIB) ///
		_col(60) %15.0fc in y scalar(posgra)
	noisily di in g "  Para adultos" ///
		_col(33) %15.0fc in y `alum_adulto' ///
		_col(50) %7.3fc in y scalar(eduaduPIB) ///
		_col(60) %15.0fc in y scalar(eduadu)
	noisily di in g "  Otros gastos educativos" ///
		_col(33) %15.0fc in y (`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto') ///
		_col(50) %7.3fc in y scalar(otrosePIB) ///
		_col(60) %15.0fc in y scalar(otrose)
	noisily di in g _dup(80) "-"
	noisily di in g "  Educaci{c o'}n" ///
		_col(33) %15.0fc in y (`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto') ///
		_col(50) %7.3fc in y scalar(educacPIB) ///
		_col(60) %15.0fc in y scalar(educacion)

	replace Educacion = 0
	replace Educacion = Educacion + scalar(basica)*alum_basica
	replace Educacion = Educacion + scalar(medsup)*alum_medsup
	replace Educacion = Educacion + scalar(superi)*alum_superi
	replace Educacion = Educacion + scalar(posgra)*alum_posgra
	replace Educacion = Educacion + scalar(eduadu)*alum_adulto
	replace Educacion = Educacion + scalar(otrose) if Educacion > 0

	*noisily tabstat Educacion [fw=factor], stat(sum) f(%20.0fc)





	**************/
	*** 4 Salud ***
	***************
	capture drop benef_*
	g benef_ssa = 1
	g benef_imss = inst_1 == "1"
	g benef_issste = inst_2 == "2"
	g benef_pemex = inst_4 == "4"
		replace benef_pemex = benef_pemex*598344/1047786
	g benef_issfam = inst_4 == "4"
		replace benef_issfam = benef_issfam - benef_pemex
	g benef_otros = inst_6 == "6"
	g benef_imssbien = 1 // inst_5 == "5"
		replace benef_imssbien = 0 if inst_1 == "1" | inst_2 == "2" | inst_4 == "4" | inst_6 == "6"


	/** 4.1 Ajuste con las estadisticas oficiales **
	tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
		benef_ssa /*benef_isssteest benef_otro*/ [fw=factor], stat(sum) f(%20.0fc) save
	tempname MSalud
	matrix `MSalud' = r(StatTotal)

	replace benef_imss = benef_imss*70519556/`MSalud'[1,1]
	replace benef_issste = benef_issste*13881797/`MSalud'[1,2]
	replace benef_pemex = benef_pemex*588049/`MSalud'[1,3]
	replace benef_imssprospera = benef_imssprospera*11768906/`MSalud'[1,4]
	replace benef_seg_pop = benef_seg_pop*68069755/`MSalud'[1,5]


	** 4.2 Cifras finales de beneficiarios **/
	tabstat benef_ssa benef_imss benef_issste benef_pemex benef_issfam benef_otros benef_imssbien [fw=factor], ///
		stat(sum) f(%20.0fc) save
	tempname Salud
	matrix `Salud' = r(StatTotal)

	local benef_ssa = `Salud'[1,1]
	local benef_imss = `Salud'[1,2]
	local benef_issste = `Salud'[1,3]
	local benef_pemex = `Salud'[1,4]
	local benef_issfam = `Salud'[1,5]
	local benef_imssbien = `Salud'[1,7]


	** 4.3 IMSS-Bienestar **
	capture confirm scalar imssbien
	if _rc == 0 {
		local imssbien = scalar(imssbien)*`benef_imssbien'
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(desc_pp) min(0) nographs
		local imssbien0 = r(Programa_IMSS_BIENESTAR)
		local segpop0 = r(Seguro_Popular)
		if `segpop0' == . {
			local segpop0 = r(Atención_a_la_Salud_y_Medicame)
		}

		PEF if divPE == 9 & ramo == 12, anio(`anio') by(desc_pp) min(0) nographs
		local atencINSABI = r(Atención_a_la_Salud)
		local fortaINSABI = r(Fortalecimiento_a_la_atención_)
		if `fortaINSABI' == . {
			local fortaINSABI = 0
		}

		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local fassa = r(Aportaciones_Federales_para_Ent)

		local imssbien = `segpop0'+`imssbien0'+`fassa'+`fortaINSABI'+`atencINSABI'
		scalar imssbien = `imssbien'/`benef_imssbien'
		restore
	}
	scalar imssbienPIB = `imssbien'/`PIB'*100


	** 4.4 Secretaría de Salud **
	capture confirm scalar ssa
	if _rc == 0 {
		local ssa = scalar(ssa)*`benef_ssa'
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(desc_pp) min(0) nographs
		local caneros = r(Seguridad_Social_Cañeros)
		local incorpo = r(Régimen_de_Incorporación)
		local adeusal = r(Adeudos_con_el_IMSS_e_ISSSTE_y_)
		if `adeusal' == . {
			local adeusal = 0
		}

		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local ssa = r(Salud)+`incorpo'+`adeusal'+`caneros'-`segpop0'-`fortaINSABI'-`atencINSABI'
		scalar ssa = `ssa'/`benef_ssa'
		restore
	}
	scalar ssaPIB = `ssa'/`PIB'*100


	** 4.5 IMSS (salud) **
	capture confirm scalar imss
	if _rc == 0 {
		local imss = scalar(imss)*`benef_imss'
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local imss = r(Instituto_Mexicano_del_Seguro_S)

		local imss = `imss'
		scalar imss = `imss'/`benef_imss'
		restore
	}
	scalar imssPIB = `imss'/`PIB'*100


	** 4.6 ISSSTE Federal (salud) **
	capture confirm scalar issste
	if _rc == 0 {
		local issste = scalar(issste)*`benef_issste'
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local issste = r(Instituto_de_Seguridad_y_Servic)

		local issste = `issste'
		scalar issste = `issste'/`benef_issste'
		restore
	}
	scalar issstePIB = `issste'/`PIB'*100


	** 4.7 Pemex (salud) **
	capture confirm scalar pemex
	if _rc == 0 {
		local pemex = scalar(pemex)*`benef_pemex'
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local pemex = r(Petróleos_Mexicanos)
		scalar pemex = (`pemex')/`benef_pemex'
		restore
	}
	scalar pemexPIB = `pemex'/`PIB'*100


	** 4.8 ISSFAM (salud) **
	capture confirm scalar issfam
	if _rc == 0 {
		local issfam = scalar(issfam)*`Salud'[1,7]
	}
	else {
		preserve
		PEF if divPE == 9, anio(`anio') by(ramo) min(0) nographs
		local issfam = r(Defensa_Nacional) + r(Marina)
		scalar issfam = (`issfam')/`benef_issfam'
		restore
	}
	scalar issfamPIB = `issfam'/`PIB'*100


	** 4.9 Total SALUD **
	scalar saludPIB = (`ssa'+`imssbien'+`imss'+`issste'+`pemex'+`issfam')/`PIB'*100
	scalar salud = (`ssa'+`imssbien'+`imss'+`issste'+`pemex'+`issfam')/`Salud'[1,1]

	* Resultados *
	noisily di _newline in y "{bf: B. " in y "Salud" "}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  SSA" ///
		_col(33) %15.0fc in y `benef_ssa' ///
		_col(50) %7.3fc in y scalar(ssaPIB) ///
		_col(60) %15.0fc in y scalar(ssa)
	noisily di in g "  IMSS-Bienestar" ///
		_col(33) %15.0fc in y `benef_imssbien' ///
		_col(50) %7.3fc in y scalar(imssbienPIB) ///
		_col(60) %15.0fc in y scalar(imssbien)
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `benef_imss' ///
		_col(50) %7.3fc in y scalar(imssPIB) ///
		_col(60) %15.0fc in y scalar(imss)
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `benef_issste' ///
		_col(50) %7.3fc in y scalar(issstePIB) ///
		_col(60) %15.0fc in y scalar(issste)
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `benef_pemex' ///
		_col(50) %7.3fc in y scalar(pemexPIB) ///
		_col(60) %15.0fc in y scalar(pemex)
	noisily di in g "  ISSFAM" ///
		_col(33) %15.0fc in y `benef_issfam' ///
		_col(50) %7.3fc in y scalar(issfamPIB) ///
		_col(60) %15.0fc in y scalar(issfam)
	noisily di in g _dup(80) "-"
	noisily di in g "  Salud" ///
		_col(33) %15.0fc in y `benef_ssa' ///
		_col(50) %7.3fc in y scalar(saludPIB) ///
		_col(60) %15.0fc in y scalar(salud)

	replace Salud = 0
	replace Salud = Salud + scalar(ssa)*benef_ssa
	replace Salud = Salud + scalar(imssbien)*benef_imssbien
	replace Salud = Salud + scalar(imss)*benef_imss
	replace Salud = Salud + scalar(issste)*benef_issste
	replace Salud = Salud + scalar(pemex)*benef_pemex
	replace Salud = Salud + scalar(issfam)*benef_issfam

	*noisily tabstat Salud [fw=factor], stat(sum) f(%20.0fc)





	******************/
	*** 5 Pensiones ***
	*******************
	capture drop pens_*
	g pens_pam = edad >= 65
	g pens_imss = ing_jubila != 0 & formal == 1
	g pens_issste = ing_jubila != 0 & formal == 2
	g pens_pemex = ing_jubila != 0 & formal == 3
		replace pens_pemex = pens_pemex*110000/181290
	g pens_otro = ing_jubila != 0 & formal == 3
		replace pens_otro = pens_otro - pens_pemex


	/** 5.1 Ajuste con las estadisticas oficiales **
	tabstat pens_pam pens_imss pens_issste pens_pemex [fw=factor], stat(sum) f(%20.0fc) save
	tempname PENSH
	matrix `PENSH' = r(StatTotal)

	replace pens_pam = pens_pam*10320548/`PENSH'[1,1]
	replace pens_imss = pens_imss*4723530/`PENSH'[1,2]
	replace pens_issste = pens_issste*1230999/`PENSH'[1,3]
	replace pens_pemex = pens_pemex*1230999/`PENSH'[1,3]
	replace pens_otro = pens_otro*1230999/`PENSH'[1,3]


	** 5.2 Cifras finales de beneficiarios **/
	tabstat pens_pam pens_imss pens_issste pens_pemex pens_otro [fw=factor], stat(sum) f(%20.0fc) save
	tempname Pension
	matrix `Pension' = r(StatTotal)

	local pens_pam = `Pension'[1,1]
	local pens_imss = `Pension'[1,2]
	local pens_issste = `Pension'[1,3]
	local pens_pemex = `Pension'[1,4]
	local pens_otro = `Pension'[1,5]


	** 5.3 Pensión para adultos mayores **
	capture confirm scalar pam
	if _rc == 0 {
		local pam = scalar(pam)*`pens_pam'
	}
	else {
		preserve
		PEF if divCIEP == 8, anio(`anio') by(divCIEP) min(0) nographs
		local pam = r(Pensión_Bienestar)
		scalar pam = `pam'/`pens_pam'
		restore
	}
	scalar pamPIB = `pam'/`PIB'*100

	capture confirm scalar penimss
	if _rc == 0 {
		local penimss = scalar(penimss)*`pens_imss'
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penimss = r(Instituto_Mexicano_del_Seguro_S)
		scalar penimss = `penimss'/`pens_imss'
		restore
	}
	scalar penimssPIB = `penimss'/`PIB'*100
	
	capture confirm scalar penisss
	if _rc == 0 {
		local penisss = scalar(penisss)*`pens_issste'
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penisss = r(Instituto_de_Seguridad_y_Servic)
		scalar penisss = `penisss'/`pens_issste'
		restore
	}
	scalar penisssPIB = `penisss'/`PIB'*100

	capture confirm scalar penpeme
	if _rc == 0 {
		local penpeme = scalar(penpeme)*`pens_pemex'
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penpeme = r(Petróleos_Mexicanos)
		scalar penpeme = `penpeme'/`pens_pemex'
		restore
	}
	scalar penpemePIB = `penpeme'/`PIB'*100

	capture confirm scalar penotro
	if _rc == 0 {
		local penotro = scalar(penotro)*`Pension'[1,5]
	}
	else {
		preserve
		PEF if divPE == 7, anio(`anio') by(ramo) min(0) nographs
		local penotro = r(Aportaciones_a_Seguridad_Social)+r(Comisión_Federal_de_Electricid)
		scalar penotro = `penotro'/`Pension'[1,5]
		restore
	}
	scalar penotroPIB = `penotro'/`PIB'*100

	scalar pensionPIB = (`pam'+`penimss'+`penisss'+`penpeme'+`penotro')/`PIB'*100
	scalar pensiones = (`pam'+`penimss'+`penisss'+`penpeme'+`penotro')/(`pens_pam'+`pens_imss'+`pens_issste'+`pens_pemex')

	* Resultados *
	noisily di _newline in y "{bf: C. Pensiones}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `anio')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi{c o'}n Bienestar" ///
		_col(33) %15.0fc in y `pens_pam' ///
		_col(50) %7.3fc in y scalar(pamPIB) ///
		_col(60) %15.0fc in y scalar(pam)
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `pens_imss' ///
		_col(50) %7.3fc in y scalar(penimssPIB) ///
		_col(60) %15.0fc in y scalar(penimss)
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `pens_issste' ///
		_col(50) %7.3fc in y scalar(penisssPIB) ///
		_col(60) %15.0fc in y scalar(penisss)
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `pens_pemex' ///
		_col(50) %7.3fc in y scalar(penpemePIB) ///
		_col(60) %15.0fc in y scalar(penpeme)
	noisily di in g "  CFE, LFC, Ferro, ISSFAM" ///
		_col(33) %15.0fc in y `pens_otro' ///
		_col(50) %7.3fc in y scalar(penotroPIB) ///
		_col(60) %15.0fc in y scalar(penotro)
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`pens_pam'+`pens_imss'+`pens_issste'+`pens_pemex'+`pens_otro') ///
		_col(50) %7.3fc in y (pamPIB+penimssPIB+penisssPIB+penpemePIB+penotroPIB) ///
		_col(60) %15.0fc in y (`pam'+`penimss'+`penisss'+`penpeme'+`penotro')/(`pens_pam'+`pens_imss'+`pens_issste'+`pens_pemex'+`pens_otro')

	replace PenBienestar = 0
	replace PenBienestar = scalar(pam)*pens_pam

	replace Pension = 0
	replace Pension = Pension + scalar(penimss)*pens_imss
	replace Pension = Pension + scalar(penisss)*pens_issste
	replace Pension = Pension + scalar(penpeme)*pens_pemex
	replace Pension = Pension + scalar(penotro)*pens_otro

	*noisily tabstat Pension PenBienestar [fw=factor], stat(sum) f(%20.0fc)




	***********************
	*** 6 Comprometidos ***
	***********************
	capture drop inelud
	g inelud = 1

	tabstat inelud [fw=factor], stat(sum) f(%20.0fc) save
	tempname Inelud
	matrix `Inelud' = r(StatTotal)


	* Inputs *
	capture confirm scalar gaspemex
	if _rc == 0 {
		local gaspemex = gaspemex*`Inelud'[1,1]
	}
	else {
		preserve
		PEF if divPE == 3, by(ramo) anio(`anio') min(0) nographs
		local gaspemex = r(Petróleos_Mexicanos)
		scalar gaspemex = `gaspemex'/`Inelud'[1,1]
		restore
	}
	scalar gaspemexPIB = `gaspemex'/`PIB'*100

	capture confirm scalar gascfe
	if _rc == 0 {
		local gascfe = gascfe*`Inelud'[1,1]
	}
	else {
		preserve
		PEF if divPE == 3, by(ramo) anio(`anio') min(0) nographs
		local gascfe = r(Comisión_Federal_de_Electricid)
		scalar gascfe = `gascfe'/`Inelud'[1,1]
		restore
	}
	scalar gascfePIB = `gascfe'/`PIB'*100

	capture confirm scalar gassener
	if _rc == 0 {
		local gassener = gassener*`Inelud'[1,1]
	}
	else {
		preserve
		PEF if divPE == 3, by(ramo) anio(`anio') min(0) nographs
		local gassener = r(Gasto_neto)-r(Comisión_Federal_de_Electricid)-r(Petróleos_Mexicanos)
		scalar gassener = `gassener'/`Inelud'[1,1]
		restore
	}
	scalar gassenerPIB = `gassener'/`PIB'*100

	capture confirm scalar gasfeder
	if _rc == 0 {
		local gasfeder = gasfeder*`Inelud'[1,1]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasfeder = r(Otras_Part_y_Apor)
		scalar gasfeder = `gasfeder'/`Inelud'[1,1]
		restore
	}
	scalar gasfederPIB = `gasfeder'/`PIB'*100

	capture confirm scalar gascosto
	if _rc == 0 {
		local gascosto = gascosto*`Inelud'[1,1]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gascosto = r(Costo_de_la_deuda)
		scalar gascosto = `gascosto'/`Inelud'[1,1]
		restore
	}
	scalar gascostoPIB = `gascosto'/`PIB'*100

	capture confirm scalar gasinfra
	if _rc == 0 {
		local gasinfra = gasinfra*`Inelud'[1,1]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasinfra = r(Inversión)
		scalar gasinfra = `gasinfra'/`Inelud'[1,1]
		restore
	}
	scalar gasinfraPIB = `gasinfra'/`PIB'*100

	capture confirm scalar gasotros
	if _rc == 0 {
		local gasotros = gasotros*`Inelud'[1,1]
	}
	else {
		preserve
		PEF, by(divPE) anio(`anio') min(0) nographs
		local gasotros = r(Otros)+r(Cuotas_ISSSTE)
		scalar gasotros = `gasotros'/`Inelud'[1,1]
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
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gascfePIB) ///
		_col(60) %15.0fc in y (`gascfe')/`Inelud'[1,1]
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gaspemexPIB) ///
		_col(60) %15.0fc in y (`gaspemex')/`Inelud'[1,1]
	noisily di in g "  SENER y otros" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gassenerPIB) ///
		_col(60) %15.0fc in y (`gassener')/`Inelud'[1,1]
	noisily di in g "  Inversión" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gasinfraPIB) ///
		_col(60) %15.0fc in y `gasinfra'/`Inelud'[1,1]
	noisily di in g "  Costo de la deuda" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gascostoPIB) ///
		_col(60) %15.0fc in y `gascosto'/`Inelud'[1,1]
	noisily di in g "  Otras Part y Aport" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gasfederPIB) ///
		_col(60) %15.0fc in y `gasfeder'/`Inelud'[1,1]
	noisily di in g "  Resto de los gastos" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y scalar(gasotrosPIB) ///
		_col(60) %15.0fc in y `gasotros'/`Inelud'[1,1]
	noisily di in g _dup(80) "-"
	noisily di in g "  Otros gastos" ///
		_col(33) %15.0fc in y `Inelud'[1,1] ///
		_col(50) %7.3fc in y gaspemexPIB+gascfePIB+gassenerPIB+gasfederPIB+gascostoPIB+gasinfraPIB+gasotrosPIB ///
		_col(60) %15.0fc in y (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros')/`Inelud'[1,1]

	drop OtrosGas
	Distribucion OtrosGas, relativo(pob) macro(`=`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gasotros'')

	drop Infra
	Distribucion Infra, relativo(infra_entidad) macro(`gasinfra')

	*noisily tabstat OtrosGas Infra [fw=factor], stat(sum) f(%20.0fc)



	
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
	scalar otrosgastos = (`gaspemex'+`gascfe'+`gassener'+`gasfeder'+`gascosto'+`gasinfra'+`gasotros'+`IngBas')/`Inelud'[1,1]

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
		saveold `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace	
	}





	***********
	*** END ***
	***********
	timer off 9
	timer list 9
	noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
}
end
