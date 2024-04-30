program define GastoPC, return
quietly {
	// 0.1 Inicia un temporizador para medir el rendimiento
	timer on 9

	// 0.2 Obtiene el año actual
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	// 0.3 Verifica si el escalar aniovp existe y asigna su valor a una macro local
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	// 0.4 Verifica si el escalar anioPE existe y asigna su valor a una macro local
	// 0.4.1 Si no existe, asigna el valor de aniovp a la macro local aniope
	capture confirm scalar anioPE
	if _rc == 0 {
		local aniope = scalar(anioPE)
	}
	else {
		local aniope = `aniovp'
	}

	// 0.5 Define los inputs que este script acepta
	// 0.5.1 ANIOvp y ANIOPE son enteros opcionales que por defecto son aniovp y aniope
	// 0.5.2 OUTPUT es una bandera binaria
	// 0.5.3 NOGraphs es otra bandera binaria
	// 0.5.4 OTROS es un número real opcional que por defecto es 1
	syntax [, ANIOvp(int `aniovp') ANIOPE(int `aniope') OUTPUT NOGraphs OTROS(real 1)]

	// 0.6 Muestra una cadena formateada
	noisily di _newline(2) in g _dup(20) "." "{bf:   GASTO PÚBLICO per c{c a'}pita " in y `aniope' "   }" in g _dup(20) "."	





	// Sección 1: Cuentas macroeconómicas (SCN, PIB, Balanza Comercial)
	// Esta sección del código está relacionada con las cuentas macroeconómicas, incluyendo el Sistema de Cuentas Nacionales (SCN), el Producto Interno Bruto (PIB), y la balanza comercial.

	// Ejecuta el comando PIBDeflactor para el año especificado por aniovp, suprimiendo la salida gráfica y otros tipos de salida
	PIBDeflactor, aniovp(`aniovp') nographs nooutput

	// Filtra el conjunto de datos para incluir solo las observaciones para el año especificado por aniovp
	keep if anio == `aniope'

	// Crea una nueva macro local llamada PIB y le asigna el único valor de la variable del PIB (pibY)
	local PIB = pibY[1]





	********************************
	***                          ***
	**# 2 Información de hogares ***
	***                          ***
	********************************
	if `aniope' >= 2022 scalar anioenigh = 2022
		else if `aniope' >= 2020 & `aniope' < 2022 scalar anioenigh = 2020
		else if `aniope' >= 2018 & `aniope' < 2020 scalar anioenigh = 2018
		else if `aniope' >= 2016 & `aniope' < 2018 scalar anioenigh = 2016
		else if `aniope' >= 2014 & `aniope' < 2016 scalar anioenigh = 2014
		else if `aniope' >= 2012 & `aniope' < 2014 scalar anioenigh = 2012	
	capture use "`c(sysdir_personal)'/SIM/perfiles`aniope'.dta", clear
	if _rc != 0 {
		noisily di _newline in g "Creando base: " in y "/SIM/perfiles`aniope'.dta" ///
			in g " con " in y "ENIGH " scalar(anioenigh)
		noisily di in g "Tiempo aproximado de espera: " in y "10+ minutos"
		noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `aniope'
	}

	use "`c(sysdir_personal)'/SIM/perfiles`aniope'.dta", clear
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta", nogen keepus(asis_esc tipoesc nivel inst_* ing_jubila jubilado ing_PAM) 
	capture drop __*
	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobenigh
	matrix `pobenigh' = r(StatTotal)





	*******************
	***             ***
	**# 3 Educación ***
	***             ***
	*******************
	replace Educación = 0

	** 3.1 Alumnos y beneficiarios **
	capture drop alum_*
	if `aniope' >= 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "09")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "10" & nivel <= "12")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "13"
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 15
	}

	if `aniope' < 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "4" & nivel <= "6")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "7" & nivel <= "8")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "9"
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "1" & nivel <= "3") & edad > 15
	}
	g alum_adoles = edad > 5 & edad <= 12

	/** 3.1.1 Ajuste con las estadisticas oficiales **
	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto [fw=factor], stat(sum) f(%20.0fc) save
	tempname EducacionI
	matrix `EducacionI' = r(StatTotal)

	replace alum_basica = alum_basica*24597234/`EducacionI'[1,1]
	replace alum_medsup = alum_medsup*5353499/`EducacionI'[1,2]
	replace alum_superi = alum_superi*4579894/`EducacionI'[1,3]
	replace alum_posgra = alum_posgra*403312/`EducacionI'[1,4]
	replace alum_adulto = alum_adulto*1905180/`EducacionI'[1,5]

	** 3.1.2 Cifras finales de alumnos **/
	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto alum_adoles ///
		[fw=factor], stat(sum) f(%20.0fc) save
	tempname Educacion
	matrix `Educacion' = r(StatTotal)

	local alum_basica = `Educacion'[1,1]
	local alum_medsup = `Educacion'[1,2]
	local alum_superi = `Educacion'[1,3]
	local alum_posgra = `Educacion'[1,4]
	local alum_adulto = `Educacion'[1,5]
	local alum_adoles = `Educacion'[1,6]


	** 3.2 Primera infancia y cuidados **
	capture confirm scalar iniciaA
	if _rc == 0 {
		local iniciaA = scalar(iniciaA)*`alum_adoles'
		local iniciaB = 0
	}
	else {
		preserve
		PEF if anio == `aniope' & divSIM == 2 & divCIEP == 2, anio(`aniope') by(desc_pp) min(0) nographs
		local iniciaA = r(Expansión_de_la_Educación_Ini)
		if `iniciaA' == . {
			local iniciaA = 0
		}
		local iniciaB = r(Educación_Inicial_y_Básica_Co)
		if `iniciaB' == . {
			local iniciaB = 0
		}
		scalar iniciaA = (`iniciaA' + `iniciaB')/`alum_adoles'
		restore
	}

	** 3.2.1 Scalars **
	scalar iniciaAPIB = (`iniciaA' + `iniciaB')/`PIB'*100

	** 3.2.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(iniciaA)*alum_adoles


	** 3.3 Básica **
	capture confirm scalar basica
	if _rc == 0 {
		local basica = scalar(basica)*`alum_basica'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM != 5 & divSIM != 2, anio(`aniope') by(desc_subfuncion) min(0) rows(3) nographs
		local basica = r(Educación_Básica)
		scalar basica = `basica'/`alum_basica'
		restore
	}

	** 3.3.1 Scalars **
	scalar basicaPIB = (`basica')/`PIB'*100

	** 3.3.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(basica)*alum_basica


	** 3.4 Media superior **
	capture confirm scalar medsup
	if _rc == 0 {
		local medsup = scalar(medsup)*`alum_medsup'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM != 5 & divSIM != 2, anio(`aniope') by(desc_subfuncion) min(0) nographs
		local medsup = r(Educación_Media_Superior)
		scalar medsup = `medsup'/`alum_medsup'
		restore
	}

	** 3.4.1 Scalars **
	scalar medsupPIB = (`medsup')/`PIB'*100

	** 3.4.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(medsup)*alum_medsup


	** 3.5 Superior **
	capture confirm scalar superi
	if _rc == 0 {
		local superi = scalar(superi)*`alum_superi'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM != 5 & divSIM != 2, anio(`aniope') by(desc_subfuncion) min(0) nographs
		local superi = r(Educación_Superior)
		scalar superi = `superi'/`alum_superi'
		restore
	}

	** 3.5.1 Scalars **
	scalar superiPIB = (`superi')/`PIB'*100

	** 3.5.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(superi)*alum_superi


	** 3.6 Posgrado **
	capture confirm scalar posgra
	if _rc == 0 {
		local posgra = scalar(posgra)*`alum_posgra'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM != 5 & divSIM != 2, anio(`aniope') by(desc_subfuncion) min(0) nographs
		local posgra = r(Posgrado)
		scalar posgra = `posgra'/`alum_posgra'
		restore
	}

	** 3.6.1 Scalars **
	scalar posgraPIB = (`posgra')/`PIB'*100

	** 3.6.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(posgra)*alum_posgra


	** 3.7 Educación para adultos **
	capture confirm scalar eduadu
	if _rc == 0 {
		local eduadu = scalar(eduadu)*`alum_adulto'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM != 5 & divSIM != 2, anio(`aniope') by(desc_subfuncion) min(0) nographs
		local eduadu = r(Educación_para_Adultos)

		scalar eduadu = `eduadu'/`alum_adulto'
		restore
	}

	** 3.7.1 Scalars **
	scalar eduaduPIB = (`eduadu')/`PIB'*100

	** 3.7.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(eduadu)*alum_adulto


	** 3.8 Inversión educativa **
	capture confirm scalar invere
	if _rc == 0 {
		local invere = scalar(invere)*(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM == 5 & divSIM != 2, anio(`aniope') by(divCIEP) min(0) nographs
		local invere = r(Gasto_neto)

		scalar invere = `invere'/(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')
		restore
	}

	** 3.8.1 Scalars **
	scalar inverePIB = (`invere')/`PIB'*100

	** 3.8.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(invere) if alum_basica+alum_medsup+alum_superi+alum_posgra+alum_adulto > 0


	** 3.9 Otros gastos educativos **
	capture confirm scalar otrose
	if _rc == 0 {
		local cultur = scalar(cultur)*`pobenigh'[1,1]
		local invest = scalar(invest)*`pobenigh'[1,1]
		local otrose = scalar(otrose)*(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 2 & divSIM != 5 & divSIM != 2, anio(`aniope') by(desc_subfuncion) min(0) nographs
		local otrose = r(Otros_Servicios_Educativos_y_Ac) + r(Función_Pública)
		local cultur = r(Cultura) + r(Deporte_y_Recreación)
		local invest = r(Desarrollo_Tecnológico) + r(Investigación_Científica) + r(Servicios_Científicos_y_Tecnol)

		scalar otrose = `otrose'/(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')
		scalar cultur = `cultur'/`pobenigh'[1,1]
		scalar invest = `invest'/`pobenigh'[1,1]
		restore
	}

	** 3.9.1 Scalars **
	scalar otrosePIB = (`otrose')/`PIB'*100
	scalar culturPIB = (`cultur')/`PIB'*100
	scalar investPIB = (`invest')/`PIB'*100

	** 3.9.2 Asignación de gasto en variable **
	replace Educación = Educación + scalar(otrose) if alum_basica+alum_medsup+alum_superi+alum_posgra+alum_adulto > 0
	replace Educación = Educación + scalar(cultur)
	replace Educación = Educación + scalar(invest)



	** 3.10 Total Educación **
	scalar educacPIB = basicaPIB + medsupPIB + superiPIB + posgraPIB + eduaduPIB + otrosePIB ///
		+ inverePIB + iniciaAPIB
	scalar educacion = educacPIB/100*`PIB'/(`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto')

	scalar EducacPIB = basicaPIB + medsupPIB + superiPIB + posgraPIB + eduaduPIB + otrosePIB ///
		+ culturPIB + investPIB + inverePIB + iniciaAPIB
	scalar Educacion = EducacPIB/100*`PIB'/`pobenigh'[1,1]


	** 3.11 Resultados **
	noisily di _newline(2) in g "{bf: A. Educaci{c o'}n CIEP}"
	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Inicial y comunitaria" ///
		_col(33) %15.0fc in y (`alum_adoles') ///
		_col(50) %7.3fc in y scalar(iniciaAPIB) ///
		_col(60) %15.0fc in y scalar(iniciaA)
	noisily di
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
	noisily di
	noisily di in g "  Inversión en educación" ///
		_col(33) %15.0fc in y (`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto') ///
		_col(50) %7.3fc in y scalar(inverePIB) ///
		_col(60) %15.0fc in y scalar(invere)
	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gasto p{c u'}blico en educación" ///
		_col(33) %15.0fc in y (`alum_basica'+`alum_medsup'+`alum_superi'+`alum_posgra'+`alum_adulto') ///
		_col(50) %7.3fc in y scalar(educacPIB) ///
		_col(60) %15.0fc in y scalar(educacion) "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Cultura, deportes y recreación" ///
		_col(33) %15.0fc in y (`pobenigh'[1,1]) ///
		_col(50) %7.3fc in y scalar(culturPIB) ///
		_col(60) %15.0fc in y scalar(cultur)
	noisily di in g "  Ciencia y tecnología" ///
		_col(33) %15.0fc in y (`pobenigh'[1,1]) ///
		_col(50) %7.3fc in y scalar(investPIB) ///
		_col(60) %15.0fc in y scalar(invest)
	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gasto público total" ///
		_col(33) %15.0fc in y (`pobenigh'[1,1]) ///
		_col(50) %7.3fc in y scalar(EducacPIB) ///
		_col(60) %15.0fc in y scalar(Educacion) "}"


	** 3.12 Put excel **
	if "$export" != "" {
		if `aniope' == 2014 {
			local col "I"
		}
		if `aniope' == 2016 {
			local col "J"
		}
		if `aniope' == 2018 {
			local col "K"
		}
		if `aniope' == 2020 {
			local col "L"
		}
		if `aniope' == 2022 {
			local col "M"
		}
		if `aniope' == 2024 {
			local col "N"
		}
		putexcel set "$export/Deciles.xlsx", modify sheet("Educación")
		putexcel `col'17 = `=scalar(iniciaA)', nformat(number_sep)
		putexcel `col'18 = `=scalar(basica)', nformat(number_sep)
		putexcel `col'19 = `=scalar(medsup)', nformat(number_sep)
		putexcel `col'20 = `=scalar(superi)', nformat(number_sep)
		putexcel `col'21 = `=scalar(posgra)', nformat(number_sep)
		putexcel `col'22 = `=scalar(eduadu)', nformat(number_sep)
		putexcel `col'23 = `=scalar(otrose)', nformat(number_sep)
		putexcel `col'24 = `=scalar(invere)', nformat(number_sep)
		putexcel `col'25 = `=scalar(cultur)', nformat(number_sep)
		putexcel `col'26 = `=scalar(invest)', nformat(number_sep)
		putexcel `col'27 = `=scalar(Educacion)', nformat(number_sep)
	}

	** 3.13 Asignación per cápita en la base de datos de individuos **
	*noisily tabstat Educacion [fw=factor], stat(sum) f(%20.0fc)





	**************/
	***         ***
	**# 4 Salud ***
	***         ***
	***************
	replace Salud = 0


	************************************
	** 4.1 Asegurados y beneficiarios **
	capture drop benef_*
	g benef_ssa = 1
	g benef_imss = inst_1 == "1"
	g benef_issste = inst_2 == "2"
	g benef_isssteEst = inst_3 == "3"
	g benef_pemex = inst_4 == "4"
		replace benef_pemex = benef_pemex*602513/1169476
	g benef_issfam = inst_4 == "4"
		replace benef_issfam = benef_issfam - benef_pemex
	if `aniope' == 2014 {
		g benef_otros = inst_5 == "5"
	}
	else {
		g benef_otros = inst_6 == "6"
	}
	g benef_imssbien = 1 // inst_5 == "5"
	replace benef_imssbien = 0 if benef_imss != 0 | benef_issste != 0 | benef_pemex != 0 | benef_issfam != 0 | benef_otros != 0

	/** 4.1.1 Ajuste con las estadisticas oficiales **
	tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
		benef_ssa /*benef_isssteest benef_otro*/ [fw=factor], stat(sum) f(%20.0fc) save
	tempname MSalud
	matrix `MSalud' = r(StatTotal)

	replace benef_imss = benef_imss*70519556/`MSalud'[1,1]
	replace benef_issste = benef_issste*13881797/`MSalud'[1,2]
	replace benef_pemex = benef_pemex*588049/`MSalud'[1,3]
	replace benef_imssprospera = benef_imssprospera*11768906/`MSalud'[1,4]
	replace benef_seg_pop = benef_seg_pop*68069755/`MSalud'[1,5]

	** 4.1.2 Cifras finales de asegurados **/
	tabstat benef_ssa benef_imss benef_issste benef_pemex benef_issfam benef_otros benef_imssbien ///
		[fw=factor], stat(sum) f(%20.0fc) save
	tempname Salud
	matrix `Salud' = r(StatTotal)

	local benef_ssa = `Salud'[1,1]
	local benef_imss = `Salud'[1,2]
	local benef_issste = `Salud'[1,3]
	local benef_pemex = `Salud'[1,4]
	local benef_issfam = `Salud'[1,5]
	local benef_imssbien = `Salud'[1,7]
	local benef_nna = `Salud'[1,8]


	************************
	** 4.2 IMSS-Bienestar **
	capture confirm scalar imssbien
	if _rc == 0 {
		local imssbien = scalar(imssbien)*`benef_imssbien'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(desc_pp) min(0) nographs
		local imssbien0 = r(Programa_IMSS_BIENESTAR)
		if `imssbien0' == . {
			local imssbien0 = r(Programa_IMSS_PROSPERA)
		}
		if `imssbien0' == . {
			local imssbien0 = r(Programa_IMSS_Oportunidades)
		}
		local segpop0 = r(Seguro_Popular)
		if `segpop0' == . {
			local segpop0 = r(Atención_a_la_Salud_y_Medicame)
		}
		if `segpop0' == . {
			local segpop0 = r(Atención_a_la_salud_y_medicame)
		}

		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5 & ramo == 12, anio(`aniope') by(desc_pp) min(0) nographs
		local atencINSABI = r(Atención_a_la_Salud)
		if `atencINSABI' == . {
			local atencINSABI = r(Atención_a_la_salud)
		}
		if `atencINSABI' == . {
			local atencINSABI = r(Prestación_de_servicios_en_los)
		}
		local fortaINSABI = r(Fortalecimiento_a_la_atención_)
		if `fortaINSABI' == . {
			local fortaINSABI = 0
		}

		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(ramo) min(0) nographs
		local fassa = r(Aportaciones_federales)
		if `fassa' == . {
			local fassa = r(Aportaciones_Federales_para_Ent)
		}
		local nosec = r(No_sectorizadas)
		if `nosec' == . {
			local nosec = r(Entidades_no_Sectorizadas)
		}
		if `nosec' == . {
			local nosec = 0
		}
		local imssbien = `segpop0'+`imssbien0'+`fassa'+`fortaINSABI'+`atencINSABI'+`nosec'
		scalar imssbien = `imssbien'/`benef_imssbien'
		restore
	}

	** 4.2.1 Scalars **
	scalar imssbienPIB = `imssbien'/`PIB'*100



	*****************************
	** 4.3 Secretaría de Salud **
	capture confirm scalar ssa
	if _rc == 0 {
		local ssa = scalar(ssa)*`benef_ssa'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(desc_pp) min(0) nographs
		local caneros = r(Seguridad_Social_Cañeros)
		local incorpo = r(Régimen_de_Incorporación)
		local adeusal = r(Adeudos_con_el_IMSS_e_ISSSTE_y_)
		if `adeusal' == . {
			local adeusal = 0
		}

		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(ramo) min(0) nographs
		local ssa = r(Salud)+`incorpo'+`adeusal'+`caneros'-`segpop0'-`fortaINSABI'-`atencINSABI'
		scalar ssa = `ssa'/`benef_ssa'
		restore
	}

	** 4.3.1 Scalars **
	scalar ssaPIB = `ssa'/`PIB'*100



	**********************
	** 4.4 IMSS (salud) **
	capture confirm scalar imss
	if _rc == 0 {
		local imss = scalar(imss)*`benef_imss'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(ramo) min(0) nographs
		local imss = r(IMSS)

		local imss = `imss'
		scalar imss = `imss'/`benef_imss'
		restore
	}

	** 4.4.1 Scalars **
	scalar imssPIB = `imss'/`PIB'*100



	********************************
	** 4.5 ISSSTE Federal (salud) **
	capture confirm scalar issste
	if _rc == 0 {
		local issste = scalar(issste)*`benef_issste'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(ramo) min(0) nographs
		local issste = r(ISSSTE)

		local issste = `issste'
		scalar issste = `issste'/`benef_issste'
		restore
	}

	** 4.5.1 Scalars **
	scalar issstePIB = `issste'/`PIB'*100



	***********************
	** 4.6 Pemex (salud) **
	capture confirm scalar pemex
	if _rc == 0 {
		local pemex = scalar(pemex)*`benef_pemex'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(ramo) min(0) nographs
		local pemex = r(Pemex)
		scalar pemex = (`pemex')/`benef_pemex'
		restore
	}

	** 4.6.1 Scalars **
	scalar pemexPIB = `pemex'/`PIB'*100



	************************
	** 4.7 ISSFAM (salud) **
	capture confirm scalar issfam
	if _rc == 0 {
		local issfam = scalar(issfam)*`benef_issfam'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM != 5, anio(`aniope') by(ramo) min(0) nographs
		local issfam = r(SEDENA) + r(Marina)
		scalar issfam = (`issfam')/`benef_issfam'
		restore
	}

	** 4.7.1 Scalars **
	scalar issfamPIB = `issfam'/`PIB'*100



	****************************
	** 4.8 Inversión en salud **
	capture confirm scalar invers
	if _rc == 0 {
		local invers = scalar(invers)*`Salud'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 9 & divSIM == 5, anio(`aniope') by(divCIEP) min(0) nographs
		local invers = r(Gasto_neto)
		scalar invers = (`invers')/`benef_ssa'
		restore
	}

	** 4.8.1 Scalars **
	scalar inversPIB = `invers'/`PIB'*100

	** 4.8.2 Asignación de gasto en variable **
	replace Salud = Salud + scalar(invers)*benef_ssa
	replace Salud = Salud + scalar(issfam)*benef_issfam
	replace Salud = Salud + scalar(pemex)*benef_pemex
	replace Salud = Salud + scalar(issste)*benef_issste
	replace Salud = Salud + scalar(imss)*benef_imss
	replace Salud = Salud + scalar(ssa)*benef_ssa
	replace Salud = Salud + scalar(imssbien)*benef_imssbien

	/* Iteraciones *
	egen Saludhog = sum(Salud), by(folioviv foliohog)
	local salto = 2
	forvalues iter=1(1)25 {
		noisily di in w "`iter' " _cont
		forvalues edades=0(`salto')109 {
			forvalues sexos=1(1)2 {
				capture tabstat Salud [fw=factor] if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == `sexos', stat(mean) f(%20.0fc) save
				if _rc != 0 {
					local valor = 0
				}
				else {
					local valor = r(StatTotal)[1,1]
				}
				replace Salud = `valor' if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == `sexos'
			}
		}
		egen equivalencia = sum(Salud), by(folioviv foliohog)
		replace Salud = Saludhog*Salud/equivalencia
		drop equivalencia
	}
	replace Salud = 0 if Salud == .
	noisily Perfiles Salud [fw=factor], reboot aniope(2022)


	********************/
	** 4.9 Total SALUD **
	scalar saludPIB = ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+issfamPIB+inversPIB
	scalar salud = saludPIB/100*`PIB'/`benef_ssa'


	*********************
	** 4.10 Resultados **
	noisily di _newline(2) in g "{bf: B. Salud CIEP}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  SSa" ///
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
	noisily di
	noisily di in g "  Inversión en salud" ///
		_col(33) %15.0fc in y `benef_ssa' ///
		_col(50) %7.3fc in y scalar(inversPIB) ///
		_col(60) %15.0fc in y scalar(invers)
	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gasto público total" ///
		_col(33) %15.0fc in y `benef_ssa' ///
		_col(50) %7.3fc in y scalar(saludPIB) ///
		_col(60) %15.0fc in y scalar(salud) "}"

	
	** 4.12 Put excel **
	if "$export" != "" {
		if `aniope' == 2014 {
			local col "I"
		}
		if `aniope' == 2016 {
			local col "J"
		}
		if `aniope' == 2018 {
			local col "K"
		}
		if `aniope' == 2020 {
			local col "L"
		}
		if `aniope' == 2022 {
			local col "M"
		}
		if `aniope' == 2024 {
			local col "N"
		}
		putexcel set "`c(sysdir_personal)'/users/$id/Deciles.xlsx", modify sheet("Salud")
		putexcel `col'17 = `=scalar(ssa)+scalar(imssbien)', nformat(number_sep)
		putexcel `col'18 = `=scalar(imss)', nformat(number_sep)
		putexcel `col'19 = `=scalar(issste)', nformat(number_sep)
		putexcel `col'20 = `=scalar(pemex)', nformat(number_sep)
		putexcel `col'21 = `=scalar(issfam)', nformat(number_sep)
		putexcel `col'22 = `=scalar(invers)', nformat(number_sep)
		putexcel `col'23 = `=scalar(salud)', nformat(number_sep)
	}

	** 4.12 Asignación per cápita en la base de datos de individuos **
	*noisily tabstat Salud [fw=factor], stat(sum) f(%20.0fc)





	******************/
	**# 5 Pensiones ***
	*******************
	replace Pensión_AM = 0
	replace Pension = 0

	** 5.1 Pensionados **
	capture drop pens_*
	g pens_pam = ing_PAM != 0
	g pens_imss = ing_jubila != 0 & formal == 1 & jubilado == 1
	g pens_issste = ing_jubila != 0 & formal == 2 & jubilado == 1
	g pens_pemex = ing_jubila != 0 & formal == 3 & jubilado == 1
		replace pens_pemex = pens_pemex*110000/181290
	g pens_otro = ing_jubila != 0 & formal == 3 & jubilado == 1
		replace pens_otro = pens_otro - pens_pemex


	/** Ajuste con las estadisticas oficiales **
	tabstat pens_pam pens_imss pens_issste pens_pemex [fw=factor], stat(sum) f(%20.0fc) save
	tempname PENSH
	matrix `PENSH' = r(StatTotal)

	replace pens_pam = pens_pam*10320548/`PENSH'[1,1]
	replace pens_imss = pens_imss*4723530/`PENSH'[1,2]
	replace pens_issste = pens_issste*1230999/`PENSH'[1,3]
	replace pens_pemex = pens_pemex*1230999/`PENSH'[1,3]
	replace pens_otro = pens_otro*1230999/`PENSH'[1,3]


	** Cifras finales de beneficiarios **/
	tabstat pens_pam pens_imss pens_issste pens_pemex pens_otro [fw=factor], stat(sum) f(%20.0fc) save
	tempname Pension
	matrix `Pension' = r(StatTotal)

	local pens_pam = `Pension'[1,1]
	local pens_imss = `Pension'[1,2]
	local pens_issste = `Pension'[1,3]
	local pens_pemex = `Pension'[1,4]
	local pens_otro = `Pension'[1,5]


	** 5.2 Pensión para adultos mayores **
	capture confirm scalar pam
	if _rc == 0 {
		local pam = scalar(pam)*`pens_pam'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 8, anio(`aniope') by(divCIEP) min(0) nographs
		local pam = r(Pensión_AM)
		scalar pam = `pam'/`pens_pam'
		restore
	}

	** 5.2.1 Scalars **
	scalar pamPIB = `pam'/`PIB'*100

	** 5.2.2 Asignación de gasto en variable **
	replace Pensión_AM = scalar(pam)*pens_pam


	** 5.3 Pensiones IMSS **
	capture confirm scalar penimss
	if _rc == 0 {
		local penimss = scalar(penimss)*`pens_imss'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 7, anio(`aniope') by(ramo) min(0) nographs
		local penimss = r(IMSS)
		scalar penimss = `penimss'/`pens_imss'
		restore
	}

	** 5.3.1 Scalars **
	scalar penimssPIB = `penimss'/`PIB'*100

	** 5.3.2 Asignación de gasto en variable **
	replace Pension = Pension + scalar(penimss)*pens_imss


	** 5.4 Pensiones ISSSTE **
	capture confirm scalar penisss
	if _rc == 0 {
		local penisss = scalar(penisss)*`pens_issste'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 7, anio(`aniope') by(ramo) min(0) nographs
		local penisss = r(ISSSTE)
		scalar penisss = `penisss'/`pens_issste'
		restore
	}

	** 5.4.1 Scalars **
	scalar penisssPIB = `penisss'/`PIB'*100

	** 5.4.2 Asignación de gasto en variable **
	replace Pension = Pension + scalar(penisss)*pens_issste


	** 5.5 Pensiones Pemex **
	capture confirm scalar penpeme
	if _rc == 0 {
		local penpeme = scalar(penpeme)*`pens_pemex'
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 7, anio(`aniope') by(ramo) min(0) nographs
		local penpeme = r(Pemex)
		scalar penpeme = `penpeme'/`pens_pemex'
		restore
	}

	** 5.5.1 Scalars **
	scalar penpemePIB = `penpeme'/`PIB'*100

	** 5.5.2 Asignación de gasto en variable **
	replace Pension = Pension + scalar(penpeme)*pens_pemex


	** 5.6 Pensiones CFE, LFC, Ferronales, ISSFAM **
	capture confirm scalar penotro
	if _rc == 0 {
		local penotro = scalar(penotro)*`Pension'[1,5]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 7, anio(`aniope') by(ramo) min(0) nographs
		local penotro = r(Aportaciones_a_Seg_Soc)+r(CFE)
		scalar penotro = `penotro'/`Pension'[1,5]
		restore
	}

	** 5.6.1 Scalars **
	scalar penotroPIB = `penotro'/`PIB'*100

	** 5.6.2 Asignación de gasto en variable **
	replace Pension = Pension + scalar(penotro)*pens_otro

	scalar pensionPIB = (`pam'+`penimss'+`penisss'+`penpeme'+`penotro')/`PIB'*100
	scalar pensiones = (`pam'+`penimss'+`penisss'+`penpeme'+`penotro')/(`pens_pam'+`pens_imss'+`pens_issste'+`pens_pemex'+`pens_otro')


	** 5.7 Resultados **
	noisily di _newline(2) in g "{bf: C. Pensiones CIEP}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi{c o'}n Adultos Mayores" ///
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
	noisily di in g "  {bf:Gasto público total" ///
		_col(33) %15.0fc in y (`pens_pam'+`pens_imss'+`pens_issste'+`pens_pemex'+`pens_otro') ///
		_col(50) %7.3fc in y (pamPIB+penimssPIB+penisssPIB+penpemePIB+penotroPIB) ///
		_col(60) %15.0fc in y (`pam'+`penimss'+`penisss'+`penpeme'+`penotro')/(`pens_pam'+`pens_imss'+`pens_issste'+`pens_pemex'+`pens_otro') "}"


	** 5.8 Put excel **
	if "$export" != "" {
		if `aniope' == 2014 {
			local col "I"
		}
		if `aniope' == 2016 {
			local col "J"
		}
		if `aniope' == 2018 {
			local col "K"
		}
		if `aniope' == 2020 {
			local col "L"
		}
		if `aniope' == 2022 {
			local col "M"
		}
		if `aniope' == 2024 {
			local col "N"
		}
		putexcel set "$export/Deciles.xlsx", modify sheet("Pensiones")
		putexcel `col'17 = `=scalar(pam)', nformat(number_sep)
		putexcel `col'18 = `=scalar(penimss)', nformat(number_sep)
		putexcel `col'19 = `=scalar(penisss)', nformat(number_sep)
		putexcel `col'20 = `=scalar(penpeme)', nformat(number_sep)
		putexcel `col'21 = `=scalar(penotro)', nformat(number_sep)
		putexcel `col'22 = `=scalar(pensiones)', nformat(number_sep)
	}

	** 5.9 Asignación per cápita en la base de datos de individuos **
	*noisily tabstat Pension Pensión_AM [fw=factor], stat(sum) f(%20.0fc)





	*****************
	**# 6 Energía ***
	*****************
	replace Energía = 0

	capture drop pob
	g pob = 1
	tabstat pob [fw=factor], stat(sum) f(%20.0fc) save
	tempname Energia
	matrix `Energia' = r(StatTotal)


	** 6.1 Pemex **
	capture confirm scalar gaspemex
	if _rc == 0 {
		local gaspemex = gaspemex*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 3 & divSIM != 5 & capitulo != 9, by(ramo) anio(`aniope') min(0) nographs
		local gaspemex = r(Pemex)
		scalar gaspemex = `gaspemex'/`Energia'[1,1]
		restore
	}
	scalar gaspemexPIB = `gaspemex'/`PIB'*100
	replace Energía = Energía + scalar(gaspemex)


	** 6.2 CFE **
	capture confirm scalar gascfe
	if _rc == 0 {
		local gascfe = gascfe*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 3 & divSIM != 5 & capitulo != 9, by(ramo) anio(`aniope') min(0) nographs
		local gascfe = r(CFE)
		scalar gascfe = `gascfe'/`Energia'[1,1]
		restore
	}
	scalar gascfePIB = `gascfe'/`PIB'*100
	replace Energía = Energía + scalar(gascfe)


	** 6.3 SENER y otros **
	capture confirm scalar gassener
	if _rc == 0 {
		local gassener = gassener*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 3 & divSIM != 5 & capitulo != 9, by(ramo) anio(`aniope') min(0) nographs
		local gassener = r(Gasto_neto)-r(CFE)-r(Pemex)
		scalar gassener = `gassener'/`Energia'[1,1]
		restore
	}
	scalar gassenerPIB = `gassener'/`PIB'*100
	replace Energía = Energía + scalar(gassener)


	** 6.4 Inversión en energía **
	capture confirm scalar gasinverf
	if _rc == 0 {
		local gasinverf = gasinverf*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 3 & divSIM == 5 & capitulo != 9, by(ramo) anio(`aniope') min(0) nographs
		local gasinverf = r(Gasto_neto)
		scalar gasinverf = `gasinverf'/`Energia'[1,1]
		restore
	}
	scalar gasinverfPIB = `gasinverf'/`PIB'*100
	replace Energía = Energía + scalar(gasinverf)


	** 6.5 Cost de la deuda (energía) **
	capture confirm scalar gascosdeue
	if _rc == 0 {
		local gascosdeue = gascosdeue*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP == 3 & capitulo == 9, by(ramo) anio(`aniope') min(0) nographs
		local gascosdeue = r(Gasto_neto)
		scalar gascosdeue = `gascosdeue'/`Energia'[1,1]
		restore
	}
	scalar gascosdeuePIB = `gascosdeue'/`PIB'*100
	replace Energía = Energía + scalar(gascosdeue)

	scalar gasenergiaPIB = gaspemexPIB+gascfePIB+gassenerPIB+gasinverfPIB+gascosdeuePIB
	scalar gasenergia = (gaspemexPIB+gascfePIB+gassenerPIB+gasinverfPIB+gascosdeuePIB)/100*`PIB'/`Energia'[1,1]


	** 6.6 Resultados **
	noisily di _newline(2) in g "{bf: D. Energía CIEP}"
	noisily di _newline in g "{bf:  Gasto por organismo" ///
		_col(33) %15s in g "Poblacion" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  CFE" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gascfePIB) ///
		_col(60) %15.0fc in y scalar(gascfe)
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gaspemexPIB) ///
		_col(60) %15.0fc in y scalar(gaspemex)
	noisily di in g "  SENER y otros" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gassenerPIB) ///
		_col(60) %15.0fc in y scalar(gassener)
	noisily di 
	noisily di in g "  Inversión en energía" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gasinverfPIB) ///
		_col(60) %15.0fc in y scalar(gasinverf)
	noisily di in g "  Costo de la deuda (energía)" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gascosdeuePIB) ///
		_col(60) %15.0fc in y scalar(gascosdeue)
	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gastos público total" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y gasenergiaPIB ///
		_col(60) %15.0fc in y gasenergia "}"





	*****************************
	**# 7 Resto de los gastos ***
	*****************************
	capture drop discap* mayores_depe primi* cuidados*
	replace Otras_inversiones = 0

	** Personas en discapacidad **
	g discap = 0
	capture replace discap = 0 if disc_camin == "3" | disc_camin == "4" ///
		| disc_ver == "3" | disc_ver == "4" | disc_brazo == "3" | disc_brazo == "4" ///
		| disc_apren == "3" | disc_apren == "4" | disc_oir == "3" | disc_oir == "4" ///
		| disc_vest == "3" | disc_vest == "4" | disc_habla == "3" | disc_habla == "4" ///
		| disc_acti == "3" | disc_acti == "4"
	capture replace discap = 1 if disc_camin == "1" | disc_camin == "2" ///
		| disc_ver == "1" | disc_ver == "2" | disc_brazo == "1" | disc_brazo == "2" ///
		| disc_apren == "1" | disc_apren == "2" | disc_oir == "1" | disc_oir == "2" ///
		| disc_vest == "1" | disc_vest == "2" | disc_habla == "1" | disc_habla == "2" ///
		| disc_acti == "1" | disc_acti == "2"


	** Adultos mayores con dependencia ** 
	g mayores_depe = edad >= 65 & discap == 1


	** Primera infancia con y sin discapacidad **
	g primi = edad < 6 & discap == 0
	g primi_discap = edad < 6 & discap == 1
	g discap_2 = discap == 1 & edad < 65


	** Población potencial cuidados **
	g cuidados_pot = (primi == 1 | discap_2 == 1 | mayores_depe == 1)
	tabstat cuidados_pot [fw=factor], stat(sum) f(%20.0fc) save
	tempname Resto
	matrix `Resto' = r(StatTotal)


	** Primera infancia de madres trabajadoras **
	g primi2 = edad < 4 | edad < 6 & discap == 1
	tabstat primi2 [fw=factor], stat(sum) f(%20.0fc) save
	tempname MADRES
	matrix `MADRES' = r(StatTotal)


	** 7.1 Gasto federalizado **
	capture confirm scalar gasfeder
	if _rc == 0 {
		local gasfeder = gasfeder*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope', by(divCIEP) anio(`aniope') min(0) nographs
		local gasfeder = r(Part_y_otras_Apor)
		scalar gasfeder = `gasfeder'/`Energia'[1,1]
		restore
	}
	scalar gasfederPIB = `gasfeder'/`PIB'*100


	** 7.2 Costo financiero de la deuda **
	capture confirm scalar gascosto
	if _rc == 0 {
		local gascosto = gascosto*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope', by(divCIEP) anio(`aniope') min(0) nographs
		local gascosto = r(Costo_de_la_deuda)
		scalar gascosto = `gascosto'/`Energia'[1,1]
		restore
	}
	scalar gascostoPIB = `gascosto'/`PIB'*100


	** 7.3 Gasto en otras inversiones **
	capture confirm scalar gasinfra
	if _rc == 0 {
		local gasinfra = gasinfra*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divCIEP != 3, by(divCIEP) anio(`aniope') min(0) nographs
		local gasinfra = r(Otras_inversiones)
		scalar gasinfra = `gasinfra'/`Energia'[1,1]
		restore
	}
	scalar gasinfraPIB = `gasinfra'/`PIB'*100
	replace Otras_inversiones = scalar(gasinfra)


	** 7.4 Gastos en cuidados **
	capture confirm scalar gascuidados
	if _rc == 0 {
		local gascuidados = gascuidados*`Resto'[1,1]
	}
	else {
		if `aniope' <= 2023 {
			local FAM_cuidados = .65
		}
		if `aniope' >= 2024 {
			local FAM_cuidados = .81
		}
		preserve
		PEF if anio == `aniope' & divSIM == 2 & divCIEP != 2 & divCIEP != 9, by(desc_pp) anio(`aniope') min(0) nographs
		local FAM_gastocuidados = r(FAM_Asistencia_Social)*(1-`FAM_cuidados')
		local gasmadres = r(Programa_de_Apoyo_para_el_Biene)
		if `gasmadres' == . {
			local gasmadres = 0
		}

		local gascuidados = r(Gasto_neto) - `FAM_gastocuidados' - `gasmadres'
		scalar gascuidados = `gascuidados'/`Resto'[1,1]
		restore
	}
	scalar gascuidadosPIB = `gascuidados'/`PIB'*100


	** 7.5 Apoyo a madres trabajadoras (cuidados) **
	capture confirm scalar gasmadres
	if _rc == 0 {
		local gasmadres = gasmadres*`MADRES'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope' & divSIM == 2 & divCIEP != 2 & divCIEP != 9, by(desc_pp) anio(`aniope') min(0) nographs
		local gasmadres = r(Programa_de_Apoyo_para_el_Biene)
		if `gasmadres' == . {
			local gasmadres = 0
		}
		scalar gasmadres = `gasmadres'/`MADRES'[1,1]
		restore
	}
	scalar gasmadresPIB = `gasmadres'/`PIB'*100


	** 7.6 Otros gastos **
	capture confirm scalar gasotros
	if _rc == 0 {
		local gasotros = gasotros*`Energia'[1,1]
	}
	else {
		preserve
		PEF if anio == `aniope', by(divCIEP) anio(`aniope') min(0) nographs
		local gasotros = r(Otros_gastos)+r(Cuotas_ISSSTE)-`gascuidados'-`gasmadres'
		scalar gasotros = `gasotros'/`Energia'[1,1]
		restore
	}
	scalar gasotrosPIB = `gasotros'/`PIB'*100
	scalar otrosgasPIB = gasfederPIB+gascostoPIB+gasinfraPIB+gasotrosPIB
	scalar otrosgas = otrosgasPIB/100*`PIB'/`Energia'[1,1]

	* Resultados *
	noisily di _newline(2) in g "{bf: E. Otros gastos CIEP}"
	noisily di _newline in g "{bf:  Gasto por concepto" ///
		_col(33) %15s in g "Poblacion" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Otras inversiones" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gasinfraPIB) ///
		_col(60) %15.0fc in y gasinfra
	noisily di in g "  Resto de los gastos" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gasotrosPIB) ///
		_col(60) %15.0fc in y gasotros
	noisily di
	noisily di in g "  Part y otras Aport" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gasfederPIB) ///
		_col(60) %15.0fc in y gasfeder
	noisily di in g "  Costo de la deuda (gobierno)" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y scalar(gascostoPIB) ///
		_col(60) %15.0fc in y gascosto
	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gasto público total" ///
		_col(33) %15.0fc in y `Energia'[1,1] ///
		_col(50) %7.3fc in y otrosgasPIB ///
		_col(60) %15.0fc in y otrosgas "}"

	*capture drop Inversión
	*Distribucion Inversión, relativo(infra_entidad) macro(`gasinfra')
	*tabstat Otros Energía Inversión [fw=factor], stat(sum) f(%20.0fc)



	****************************/
	**# 8 Ingreso b{c a'}sico ***
	*****************************
	replace IngBasico = 0

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
		local bititle = "Ingreso Básico (18 <)"
	}
	else if ingbasico18 == 1 & ingbasico65 == 0 {
		tabstat factor if edad < 65, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Ingreso Básico (< 65)"
	}
	else if ingbasico18 == 0 & ingbasico65 == 0 {
		tabstat factor if edad < 65 & edad >= 18, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Ingreso Básico (18 y 65)"
	}
	else {
		tabstat factor, stat(sum) f(%20.0fc) save
		tempname pobIngBas
		matrix `pobIngBas' = r(StatTotal)
		local bititle = "Ingreso Básico Universal"
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
	
	scalar transfPIB = gasmadresPIB+IngBasPIB+gascuidadosPIB
	scalar transf = transfPIB/100*`PIB'/`pobIngBas'[1,1]

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

	* Resultados *
	noisily di _newline(2) in g "{bf: F. Transferencias}" 
	noisily di _newline in g "{bf:  Gasto por concepto" ///
		_col(33) %15s in g "Población" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  `bititle'" ///
		_col(33) %15.0fc in y `pobIngBas'[1,1] ///
		_col(50) %7.3fc in y IngBasPIB ///
		_col(60) %15.0fc in y IngBas
	noisily di in g "  Apoyo a madres trabajadoras" ///
		_col(33) %15.0fc in y `MADRES'[1,1] ///
		_col(50) %7.3fc in y scalar(gasmadresPIB) ///
		_col(60) %15.0fc in y scalar(gasmadres)
	noisily di in g "  Gasto en cuidados" ///
		_col(33) %15.0fc in y `Resto'[1,1] ///
		_col(50) %7.3fc in y scalar(gascuidadosPIB) ///
		_col(60) %15.0fc in y gascuidados

	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gasto público total" "}" ///
		_col(33) %15.0fc in y `pobIngBas'[1,1] ///
		_col(50) %7.3fc in y scalar(transfPIB) ///
		_col(60) %15.0fc in y scalar(transf)

	replace IngBasico = IngBasico + scalar(gasmadres) if primi2 == 1
	replace IngBasico = IngBasico + scalar(gascuidados) if cuidados_pot == 1




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
	drop asis_esc tipoesc nivel inst_* ing_jubila jubilado disc*
	drop ISRAS ISRPF CUOTAS ISRPM OTROSK /*FMP PEMEX CFE IMSS ISSSTE*/ IVA IEPSNP IEPSP ISAN IMPORT

	capture drop __*
	capture mkdir `"`c(sysdir_personal)'/users/"'
	capture mkdir `"`c(sysdir_personal)'/users/$id/"'
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_personal)'/users/$id/gastos.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/users/$id/gastos.dta"', replace	
	}





	***********
	*** END ***
	***********
	timer off 9
	timer list 9
	noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
}
end
