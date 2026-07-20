*! version 8.0 CIEP 03jul2026
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
	syntax [anything] [, ANIOVP(int `aniovp') ANIOpe(int `aniope') EXCEL]
	tokenize `anything'
	local word_count = wordcount("`anything'")

	if  "`anything'" == "" local word_count = 1
	
	// 0.6 Muestra una cadena formateada
	noisily di _newline(2) in g _dup(20) "." "{bf:   GASTO per cápita " in y `aniope' "   }" in g _dup(20) "."	



	******************************************
	***                                    ***
	**# Sección 1: Cuentas macroeconómicas ***
	***                                    ***
	******************************************
	// Ejecuta el comando PIBDeflactor para el año especificado por aniovp, suprimiendo la salida gráfica y otros tipos de salida
	PIBDeflactor, aniovp(`aniovp') nographs nooutput
	keep if anio == `aniope'
	local PIB = pibY[1]
	local deflator = deflator[1]



	*****************************************
	***                                   ***
	**# Sección 2: Información de hogares ***
	***                                   ***
	*****************************************
	// Asigna el año de ENIGH correspondiente al año de referencia
	if `aniope' >= 2024 local anioenigh = 2024
	else if `aniope' >= 2022 & `aniope' < 2024 local anioenigh = 2022
	else if `aniope' >= 2020 & `aniope' < 2022 local anioenigh = 2020
	else if `aniope' >= 2018 & `aniope' < 2020 local anioenigh = 2018
	else if `aniope' >= 2016 & `aniope' < 2018 local anioenigh = 2016
	else if `aniope' >= 2013 & `aniope' < 2016 local anioenigh = 2014
	else if `aniope' >= 2012 & `aniope' < 2013 local anioenigh = 2012
	else if `aniope' >= 2010 & `aniope' < 2012 local anioenigh = 2010
	else if `aniope' >= 2008 & `aniope' < 2010 local anioenigh = 2008

	// Carga la base de datos de ENIGH correspondiente al año de referencia
	capture use "`c(sysdir_site)'/master/perfiles`aniope'.dta", clear	
	if _rc != 0 {
		noisily di _newline in g "Creando base: " in y "/master/perfiles`aniope'.dta" ///
			in g " con " in y "ENIGH " `anioenigh'
		noisily run `"`c(sysdir_site)'/01_modules/profiles/PerfilesSim.do"' `aniope'
	}
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/master/`anioenigh'/households.dta", ///
		nogen keepus(asis_esc tipoesc nivel inst_* ing_jubila jubilado ing_PAM formal) update
	capture drop __*

	// Calcula la suma de los factores de ponderación de la base de datos de ENIGH
	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobenigh
	matrix `pobenigh' = r(StatTotal)

	** 2.1 Alumnos y beneficiarios **
	capture drop alum_*
	if `anioenigh' >= 2024 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "09")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "10" & nivel <= "12")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & (nivel >= "13" & nivel <= "14")
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 15
	}

	if `anioenigh' < 2024 & `anioenigh' >= 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "09")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "10" & nivel <= "12")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "13"
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 15
	}

	if `anioenigh' < 2016 {
		g alum_basica = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "03") & edad <= 15
		g alum_medsup = asis_esc == "1" & tipoesc == "1" & (nivel >= "04" & nivel <= "06")
		g alum_superi = asis_esc == "1" & tipoesc == "1" & (nivel >= "07" & nivel <= "08")
		g alum_posgra = asis_esc == "1" & tipoesc == "1" & nivel == "09"
		g alum_adulto = asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "03") & edad > 15
	}
	g alum_totales = alum_basica != 0 | alum_medsup != 0 | alum_superi != 0 | alum_posgra != 0 | alum_adulto != 0
	g alum_priminf = edad < 3

	tabstat alum_basica alum_medsup alum_superi alum_posgra alum_adulto alum_totales alum_priminf [fw=factor], stat(sum) f(%20.0fc) save
	tempname Educacion
	matrix `Educacion' = r(StatTotal)

	** 2.2 Asegurados y beneficiarios **
	egen gas_tot_SaluT = sum(gas_pc_SaluT), by(folioviv foliohog)
	g gas_prom_SaluT = gas_pc_SaluT/gas_tot_SaluT
	replace gas_prom_SaluT = 0 if gas_prom_SaluT == .
	
	capture drop benef_*
	g benef_ssa = gas_prom_SaluT
	
	g benef_imss = gas_prom_SaluT if inst_1 == "1"
	replace benef_imss = 0 if benef_imss == .
	
	g benef_issste = gas_prom_SaluT if inst_2 == "2"
	replace benef_issste = 0 if benef_issste == .
	
	g benef_isssteEst = gas_prom_SaluT if inst_3 == "3"
	replace benef_isssteEst = 0 if benef_isssteEst == .
	
	g benef_pemex = gas_prom_SaluT if inst_4 == "4"
	replace benef_pemex = 0 if benef_pemex == .
	* TODO(Ricardo): ancla administrativa 602513/1169476 = derechohabientes
	* Pemex / total inst_4 (Pemex+Defensa+Marina) para partir la afiliación
	* ENIGH. FALTA documentar fuente y corte (¿anuario estadístico
	* Pemex/ISSFAM, año?) antes de recalibrar. La misma ancla parte el
	* conteo de personas en 4.5.1/4.6.1.
	replace benef_pemex = benef_pemex*602513/1169476
	
	g benef_issfam = gas_prom_SaluT if inst_4 == "4"
	replace benef_issfam = 0 if benef_issfam == .
	replace benef_issfam = benef_issfam - benef_pemex

	capture confirm variable inst_6	
	if _rc != 0 {
		g benef_otros = gas_prom_SaluT if inst_5 == "5"
		replace benef_otros = 0 if benef_otros == .
	}
	else {
		g benef_otros = gas_prom_SaluT if inst_6 == "6"
		replace benef_otros = 0 if benef_otros == .
	}
	g benef_imssbien = gas_prom_SaluT // inst_5 == "5"
	replace benef_imssbien = 0 if benef_imss != 0 | benef_issste != 0 | benef_pemex != 0 | benef_issfam != 0 | benef_otros != 0

	g benef_invers = gas_prom_SaluT

	tabstat benef_ssa benef_imss benef_issste benef_pemex benef_issfam benef_otros benef_imssbien ///
		[fw=factor], stat(sum) f(%20.0fc) save
	tempname Salud
	matrix `Salud' = r(StatTotal)

	** 2.2.1 Derechohabientes (personas) — v8.2.0 **
	* Conteos de PERSONAS para display/PC/web (los benef_* de arriba son
	* participaciones del gasto en salud del hogar y quedan SOLO como pesos
	* de incidencia). El factor de perfiles ya está proyectado a la población
	* CONAPO del año PE (reescalado ENIGH→CONAPO calculado en la corrida,
	* no hardcodeado). La doble afiliación declarada (~0.7%) se cuenta en
	* AMBAS instituciones, como en los registros administrativos.
	* TODO(Ricardo): inst_3 (ISSSTE estatal, ~2.0M personas) queda DENTRO del
	* residuo IMSS-Bienestar por continuidad metodológica — candidato de
	* refinamiento registrado en bitácora (v8.2.0).
	g der_imss = inst_1 == "1"
	g der_issste = inst_2 == "2"
	g der_pemdef = inst_4 == "4"
	capture confirm variable inst_6
	if _rc != 0 {
		g der_otros = inst_5 == "5"
	}
	else {
		g der_otros = inst_6 == "6"
	}
	g der_imssbien = der_imss == 0 & der_issste == 0 & der_pemdef == 0 & der_otros == 0

	tabstat der_imss der_issste der_pemdef der_otros der_imssbien ///
		[fw=factor], stat(sum) f(%20.0fc) save
	tempname SaludPer
	matrix `SaludPer' = r(StatTotal)
	drop der_imss der_issste der_pemdef der_otros der_imssbien

	** 2.3 Pensionados **
	capture drop pens_*
	g pens_pam = /*ing_PAM != 0 &*/ edad >= 65
	g pens_imss = ing_jubila != 0 & formal == 1 & jubilado == 1
	g pens_issste = ing_jubila != 0 & formal == 2 & jubilado == 1
	g pens_pemex = ing_jubila != 0 & formal == 3 & jubilado == 1
	* TODO(Ricardo): ancla administrativa 110000/181290 = pensionados Pemex /
	* total pensionados con formal==3. FALTA documentar fuente y corte antes
	* de recalibrar.
		replace pens_pemex = pens_pemex*110000/181290
	g pens_otro = ing_jubila != 0 & formal == 3 & jubilado == 1
		replace pens_otro = pens_otro - pens_pemex

	tabstat pens_pam pens_imss pens_issste pens_pemex pens_otro [fw=factor], stat(sum) f(%20.0fc) save
	tempname Pension
	matrix `Pension' = r(StatTotal)

	local pens_pam = `Pension'[1,1]
	local pens_imss = `Pension'[1,2]
	local pens_issste = `Pension'[1,3]
	local pens_pemex = `Pension'[1,4]
	local pens_otro = `Pension'[1,5]

	** 2.4 Personas en discapacidad **
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


	** 2.5 Adultos mayores con dependencia ** 
	g mayores_depe = edad >= 65 & discap == 1

	** 2.6 Primera infancia con y sin discapacidad **
	g primi = edad < 6 & discap == 0
	g primi_discap = edad < 6 & discap == 1
	g discap_2 = discap == 1 & edad < 65
	
	** 2.7 Primera infancia de madres trabajadoras **
	g primi2 = edad < 4 | (edad < 6 & discap == 1)
	tabstat primi2 [fw=factor], stat(sum) f(%20.0fc) save
	tempname MADRES
	matrix `MADRES' = r(StatTotal)

	** 2.8 Población potencial cuidados **
	g cuidados_pot = (primi == 1 | discap_2 == 1 | mayores_depe == 1 | primi_discap == 1)
	tabstat cuidados_pot [fw=factor], stat(sum) f(%20.0fc) save
	tempname Resto
	matrix `Resto' = r(StatTotal)

	** 2.9 Población total **
	capture drop pob
	g pob = 1
	tabstat pob [fw=factor], stat(sum) f(%20.0fc) save
	tempname Energia
	matrix `Energia' = r(StatTotal)


	*******************
	***             ***
	**# 3 Educación ***
	***             ***
	*******************
	forvalues tok = 1(1)`word_count' {
		if "``tok''" == "educacion" | "`1'" == "" {

			** 3.1 Primera infancia y cuidados **
			capture confirm scalar iniciaA
			if _rc == 0 {
				local iniciaA = scalar(iniciaA)/100*`PIB'
				local iniciaB = 0
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM == "Cuidados", anio(`aniope') by(desc_pp) min(0) nographs
				local iniciaA = r(expansion_de_la_educaci)
				if `iniciaA' == . {
					local iniciaA = 0
				}
				local iniciaB = r(educacion_inicial_y_ba)
				if `iniciaB' == . {
					local iniciaB = 0
				}
				restore
			}

			** 3.1.1 Scalars **
			escalar mxnpc iniciaAPC = ((`iniciaA' + `iniciaB')/`Educacion'[1,7])/`deflator'
			escalar pctpib iniciaAPIB = (`iniciaA' + `iniciaB')/`PIB'*100
			escalar mxnpc iniciaAPob = `Educacion'[1,7]

			** 3.1.2 Asignación de gasto en variable **
			capture drop Educacion
			g Educacion = scalar(iniciaAPC)*alum_priminf


			** 3.2 Básica **
			capture confirm scalar basica
			if _rc == 0 {
				local basica = scalar(basica)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM != "Inversión" & divSIM != "Cuidados", anio(`aniope') by(desc_subfuncion) min(0) rows(3) nographs
				local basica = r(educacion_basica)
				restore
			}

			** 3.2.1 Scalars **
			escalar mxnpc basicaPC = ((`basica')/`Educacion'[1,1])/`deflator'
			escalar pctpib basicaPIB = (`basica')/`PIB'*100
			escalar mxnpc basicaPob = `Educacion'[1,1]

			** 3.2.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(basicaPC)*alum_basica


			** 3.3 Media superior **
			capture confirm scalar medsup
			if _rc == 0 {
				local medsup = scalar(medsup)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM != "Inversión" & divSIM != "Cuidados", anio(`aniope') by(desc_subfuncion) min(0) nographs
				local medsup = r(educacion_media_superio)
				restore
			}

			** 3.3.1 Scalars **
			escalar mxnpc medsupPC = ((`medsup')/`Educacion'[1,2])/`deflator'
			escalar pctpib medsupPIB = (`medsup')/`PIB'*100
			escalar mxnpc medsupPob = `Educacion'[1,2]

			** 3.3.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(medsupPC)*alum_medsup


			** 3.4 Superior **
			capture confirm scalar superi
			if _rc == 0 {
				local superi = scalar(superi)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM != "Inversión" & divSIM != "Cuidados", anio(`aniope') by(desc_subfuncion) min(0) nographs
				local superi = r(educacion_superior)
				restore
			}

			** 3.4.1 Scalars **
			escalar mxnpc superiPC = ((`superi')/`Educacion'[1,3])/`deflator'
			escalar pctpib superiPIB = (`superi')/`PIB'*100
			escalar mxnpc superiPob = `Educacion'[1,3]

			** 3.4.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(superiPC)*alum_superi


			** 3.5 Posgrado **
			capture confirm scalar posgra
			if _rc == 0 {
				local posgra = scalar(posgra)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM != "Inversión" & divSIM != "Cuidados", anio(`aniope') by(desc_subfuncion) min(0) nographs
				local posgra = r(posgrado)
				restore
			}

			** 3.5.1 Scalars **
			escalar mxnpc posgraPC = ((`posgra')/`Educacion'[1,4])/`deflator'
			escalar pctpib posgraPIB = (`posgra')/`PIB'*100
			escalar mxnpc posgraPob = `Educacion'[1,4]

			** 3.5.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(posgraPC)*alum_posgra


			** 3.6 Educación para adultos **
			capture confirm scalar eduadu
			if _rc == 0 {
				local eduadu = scalar(eduadu)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM != "Inversión" & divSIM != "Cuidados", anio(`aniope') by(desc_subfuncion) min(0) nographs
				local eduadu = r(educacion_para_adultos)
				restore
			}

			** 3.6.1 Scalars **
			escalar mxnpc eduaduPC = ((`eduadu')/`Educacion'[1,6])/`deflator'
			escalar pctpib eduaduPIB = (`eduadu')/`PIB'*100
			escalar mxnpc eduaduPob = `Educacion'[1,6]

			** 3.6.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(eduaduPC)*alum_adulto


			** 3.7 Inversión educativa **
			capture confirm scalar invere
			if _rc == 0 {
				local invere = scalar(invere)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM == "Inversión" & divSIM != "Cuidados", anio(`aniope') by(divCIEP) min(0) nographs
				local invere = r(Gasto_neto)
				restore
			}

			** 3.7.1 Scalars **
			escalar mxnpc inverePC = ((`invere')/`Educacion'[1,6])/`deflator'
			escalar pctpib inverePIB = (`invere')/`PIB'*100
			escalar mxnpc inverePob = `Educacion'[1,6]

			** 3.7.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(inverePC) if alum_totales > 0


			** 3.8 Otros gastos educativos **
			capture confirm scalar otrose
			if _rc == 0 {
				local cultur = scalar(cultur)/100*`PIB'
				local invest = scalar(invest)/100*`PIB'
				local otrose = scalar(otrose)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Educación" & divSIM != "Inversión" & divSIM != "Cuidados", anio(`aniope') by(desc_subfuncion) min(0) nographs
				local otrose = r(otros_servicios_educativ) + r(funcion_publica)
				local cultur = r(cultura) + r(deporte_y_recreacion)
				local invest = r(desarrollo_tecnologico) + r(investigacion_cientifi) + r(servicios_cientificos_y)
				restore
			}

			** 3.8.1 Scalars **
			escalar mxnpc otrosePC = ((`otrose')/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5]))/`deflator'
			escalar pctpib otrosePIB = (`otrose')/`PIB'*100
			escalar mxnpc otrosePob = `Educacion'[1,6]

			escalar mxnpc culturPC = ((`cultur')/`pobenigh'[1,1])/`deflator'
			escalar pctpib culturPIB = (`cultur')/`PIB'*100
			escalar mxnpc culturPob = `pobenigh'[1,1]

			escalar mxnpc investPC = ((`invest')/`pobenigh'[1,1])/`deflator'
			escalar pctpib investPIB = (`invest')/`PIB'*100
			escalar mxnpc investPob = `pobenigh'[1,1]


			** 3.8.2 Asignación de gasto en variable **
			replace Educacion = Educacion + scalar(otrosePC) if alum_basica+alum_medsup+alum_superi+alum_posgra+alum_adulto > 0
			replace Educacion = Educacion + scalar(culturPC)
			replace Educacion = Educacion + scalar(investPC)


			** 3.9 Total Educación **
			escalar pctpib educacPIB = scalar(basicaPIB) + scalar(medsupPIB) + scalar(superiPIB) + scalar(posgraPIB) + scalar(eduaduPIB) + scalar(otrosePIB) + scalar(inverePIB) + scalar(iniciaAPIB)
			escalar mxnpc educacPC = (scalar(educacPIB)/100*`PIB'/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]+`Educacion'[1,5]))/`deflator'
			escalar mxnpc educacPob = `Educacion'[1,6]

			escalar pctpib EducacPIB = scalar(basicaPIB) + scalar(medsupPIB) + scalar(superiPIB) + scalar(posgraPIB) + scalar(eduaduPIB) + scalar(otrosePIB) + scalar(inverePIB) + scalar(iniciaAPIB) + scalar(culturPIB) + scalar(investPIB)
			escalar mxnpc EducacPC = (scalar(EducacPIB)/100*`PIB'/`pobenigh'[1,1])/`deflator'
			escalar mxnpc EducacPob = `pobenigh'[1,1]


			** 3.10 Resultados **
			noisily di _newline(2) in g "{bf: A. Educaci{c o'}n CIEP}"
			noisily di _newline in g "{bf:  Gasto por nivel" ///
				_col(32) %15.0fc in g "Alumnos" ///
				_col(49) %7.3f "% PIB" ///
				_col(59) %10s in g "PC (MXN `aniovp')" "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  Inicial y comunitaria" ///
				_col(32) %15.0fc in y scalar(iniciaAPob) ///
				_col(49) %7.3f in y scalar(iniciaAPIB) ///
				_col(57) %15.0fc in y scalar(iniciaAPC)
			noisily di
			noisily di in g "  B{c a'}sica" ///
				_col(32) %15.0fc in y scalar(basicaPob) ///
				_col(49) %7.3f in y scalar(basicaPIB) ///
				_col(57) %15.0fc in y scalar(basicaPC)
			noisily di in g "  Media superior" ///
				_col(32) %15.0fc in y scalar(medsupPob) ///
				_col(49) %7.3f in y scalar(medsupPIB) ///
				_col(57) %15.0fc in y scalar(medsupPC)
			noisily di in g "  Superior" ///
				_col(32) %15.0fc in y scalar(superiPob) ///
				_col(49) %7.3f in y scalar(superiPIB) ///
				_col(57) %15.0fc in y scalar(superiPC)
			noisily di in g "  Posgrado" ///
				_col(32) %15.0fc in y scalar(posgraPob) ///
				_col(49) %7.3f in y scalar(posgraPIB) ///
				_col(57) %15.0fc in y scalar(posgraPC)
			noisily di in g "  Para adultos" ///
				_col(32) %15.0fc in y scalar(eduaduPob) ///
				_col(49) %7.3f in y scalar(eduaduPIB) ///
				_col(57) %15.0fc in y scalar(eduaduPC)
			noisily di in g "  Otros gastos educativos" ///
				_col(32) %15.0fc in y scalar(educacPob) ///
				_col(49) %7.3f in y scalar(otrosePIB) ///
				_col(57) %15.0fc in y scalar(otrosePC)
			noisily di
			noisily di in g "  Inversión en educación" ///
				_col(32) %15.0fc in y scalar(educacPob) ///
				_col(49) %7.3f in y scalar(inverePIB) ///
				_col(57) %15.0fc in y scalar(inverePC)
			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gasto p{c u'}blico en educación" ///
				_col(32) %15.0fc in y scalar(educacPob) ///
				_col(49) %7.3f in y scalar(educacPIB) ///
				_col(57) %15.0fc in y scalar(educacPC) "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  Cultura y deportes" ///
				_col(32) %15.0fc in y scalar(culturPob) ///
				_col(49) %7.3f in y scalar(culturPIB) ///
				_col(57) %15.0fc in y scalar(culturPC)
			noisily di in g "  Ciencia y tecnología" ///
				_col(32) %15.0fc in y scalar(investPob) ///
				_col(49) %7.3f in y scalar(investPIB) ///
				_col(57) %15.0fc in y scalar(investPC)
			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gasto público total" ///
				_col(32) %15.0fc in y scalar(EducacPob) ///
				_col(49) %7.3f in y scalar(EducacPIB) ///
				_col(57) %15.0fc in y scalar(EducacPC) "}"


			** 3.11 Put excel **
			if "`excel'" == "excel" {
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

			** 3.12 Asignación per cápita en la base de datos de individuos **
			*noisily tabstat Educacion [fw=factor], stat(sum) f(%20.0fc)
		}


		**************/
		***         ***
		**# 4 Salud ***
		***         ***
		***************

		if "``tok''" == "salud" | "`1'" == "" {

			** 4.1 IMSS-Bienestar **
			capture confirm scalar imssbien
			if _rc == 0 {
				local imssbien = scalar(imssbien)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(desc_pp) min(0) nographs
				local imssbien0 = r(programa_imss_bienestar)
				if `imssbien0' == . {
					local imssbien0 = r(programa_imss_prospera)
				}
				if `imssbien0' == . {
					local imssbien0 = r(programa_imss_oportunida)
				}
				if `imssbien0' == . {
					PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión" & ramo == 56, anio(`aniope') by(ramo) min(0) nographs
					local imssbien0 = r(Gasto_neto)
				}
				if `imssbien0' == . {
					local imssbien0 = 0
				}
				local segpop0 = r(seguro_popular)
				if `segpop0' == . {
					local segpop0 = r(atencion_a_la_salud_y_m)
				}
				if `segpop0' == . {
					local segpop0 = 0
				}

				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión" & ramo == 12, anio(`aniope') by(desc_pp) min(0) nographs
				local atencINSABI = r(atencion_a_la_salud)
				if `atencINSABI' == . {
					local atencINSABI = r(prestacion_de_servicios)
				}
				if `atencINSABI' == . {
					local atencINSABI = 0
				}
				
				local fortaINSABI = r(fortalecimiento_a_la_ate)
				if `fortaINSABI' == . {
					local fortaINSABI = 0
				}

				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(ramo) min(0) nographs
				local fassa = r(fassa)
				if `fassa' == . {
					local fassa = r(aportaciones_federales_p)
				}
				local nosec = r(no_sectorizadas)
				if `nosec' == . {
					local nosec = r(entidades_no_sectorizada)
				}
				if `nosec' == . {
					local nosec = 0
				}
				local saludbienestar = r(bienestar)
				if `saludbienestar' == . {
					local saludbienestar = 0
				}
				local imssbien = `imssbien0'+`fassa'+`fortaINSABI'+`atencINSABI'+`nosec'+`saludbienestar'
				restore
			}

			* 4.1.1 Scalars *
			* v8.2.0: Pob/PC sobre PERSONAS (residuo sin seguridad social);
			* el cociente hogares-equivalentes queda como tempname scalar
			* *PCinc (double exacto, NO local: un local stringifica y mueve
			* el último bit de la incidencia) SOLO para la imputación de
			* incidencia — benef_* intactos. Se dropea tras su único uso
			* para no contaminar scalarlatex.
			escalar mxnpc imssbienPC = ((`imssbien')/`SaludPer'[1,5])/`deflator'
			escalar pctpib imssbienPIB = (`imssbien')/`PIB'*100
			escalar mxnpc imssbienPob = `SaludPer'[1,5]
			tempname imssbienPCinc
			scalar `imssbienPCinc' = ((`imssbien')/`Salud'[1,7])/`deflator'

			* 4.1.2 Asignación de gasto en variable *
			tempvar gas_pc_imssbien
			g `gas_pc_imssbien' = gas_pc_Salu if benef_imssbien != 0
			replace `gas_pc_imssbien' = 0 if `gas_pc_imssbien' == .
			Distribucion imssbien, relativo(`gas_pc_imssbien') macro(`imssbien')
			replace imssbien = 0 if imssbien == .

			capture drop Salud
			egen equivalenciasSalu = sum(gas_pc_Salu), by(folioviv foliohog)
			egen tot_integ = count(factor), by(folioviv foliohog)
			g Salud = scalar(`imssbienPCinc')*benef_imssbien
			scalar drop `imssbienPCinc'


			** 4.2 Secretaría de Salud **
			capture confirm scalar ssa
			if _rc == 0 {
				local ssa = scalar(ssa)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(desc_pp) min(0) nographs
				local incorpo = r(regimen_de_incorporaci)
				if `incorpo' == . {
					local incorpo = 0
				}
				local adeusal = r(adeudos_con_el_imss_e_is)
				if `adeusal' == . {
					local adeusal = 0
				}
				local caneros = r(seguridad_social_canero)
				if `caneros' == . {
					local caneros = 0
				}

				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(ramo) min(0) nographs
				local ssa = r(salud)+`incorpo'+`adeusal'+`caneros'-`fortaINSABI'-`atencINSABI'
				restore
			}

			* 4.2.1 Scalars *
			* v8.2.0: SSa sobre población total (CONAPO del año PE, coherente
			* con Energía/Cultura); incidencia con hogares-equivalentes.
			escalar mxnpc ssaPC = (`ssa'/`pobenigh'[1,1])/`deflator'
			escalar pctpib ssaPIB = (`ssa')/`PIB'*100
			escalar mxnpc ssaPob = `pobenigh'[1,1]
			tempname ssaPCinc
			scalar `ssaPCinc' = (`ssa'/`Salud'[1,1])/`deflator'

			* 4.2.2 Asignación de gasto en variable *
			tempvar gas_pc_ssa
			g `gas_pc_ssa' = gas_pc_Salu if benef_ssa != 0
			replace `gas_pc_ssa' = 0 if `gas_pc_ssa' == .
			Distribucion ssa, relativo(`gas_pc_ssa') macro(`ssa')
			replace ssa = 0 if ssa == .
			replace Salud = Salud + scalar(`ssaPCinc')*benef_ssa
			scalar drop `ssaPCinc'


			** 4.3 IMSS (salud) **
			capture confirm scalar imss
			if _rc == 0 {
				local imss = scalar(imss)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(ramo) min(0) nographs
				local imss = r(instituto_mexicano_del_s)
				restore
			}

			* 4.3.1 Scalars *
			escalar mxnpc imssPC = (`imss'/`SaludPer'[1,1])/`deflator'
			escalar pctpib imssPIB = (`imss')/`PIB'*100
			escalar mxnpc imssPob = `SaludPer'[1,1]
			tempname imssPCinc
			scalar `imssPCinc' = (`imss'/`Salud'[1,2])/`deflator'

			* 4.3.2 Asignación de gasto en variable *	
			tempvar gas_pc_imss
			g `gas_pc_imss' = gas_pc_Salu if benef_imss != 0
			replace `gas_pc_imss' = 0 if `gas_pc_imss' == .
			Distribucion imss, relativo(`gas_pc_imss') macro(`imss')
			replace imss = 0 if imss == .
			replace Salud = Salud + scalar(`imssPCinc')*benef_imss
			scalar drop `imssPCinc'


			** 4.4 ISSSTE Federal (salud) **
			capture confirm scalar issste
			if _rc == 0 {
				local issste = scalar(issste)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(ramo) min(0) nographs
				local issste = r(instituto_de_seguridad_y)
				restore
			}

			* 4.4.1 Scalars *
			escalar mxnpc issstePC = (`issste'/`SaludPer'[1,2])/`deflator'
			escalar pctpib issstePIB = (`issste')/`PIB'*100
			escalar mxnpc issstePob = `SaludPer'[1,2]
			tempname issstePCinc
			scalar `issstePCinc' = (`issste'/`Salud'[1,3])/`deflator'

			* 4.4.2 Asignación de gasto en variable *	
			tempvar gas_pc_issste
			g `gas_pc_issste' = gas_pc_Salu if benef_issste != 0
			replace `gas_pc_issste' = 0 if `gas_pc_issste' == .
			Distribucion issste, relativo(`gas_pc_issste') macro(`issste')
			replace issste = 0 if issste == .
			replace Salud = Salud + scalar(`issstePCinc')*benef_issste
			scalar drop `issstePCinc'


			** 4.5 Pemex (salud) **
			capture confirm scalar pemex
			if _rc == 0 {
				local pemex = scalar(pemex)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(ramo) min(0) nographs
				local pemex = r(petroleos_mexicanos)
				restore
			}

			* 4.5.1 Scalars *
			* Ancla administrativa 602513/1169476: ver TODO en 2.2 (benef_pemex).
			local pemexPer = `SaludPer'[1,3]*602513/1169476
			escalar mxnpc pemexPC = (`pemex'/`pemexPer')/`deflator'
			escalar pctpib pemexPIB = (`pemex')/`PIB'*100
			escalar mxnpc pemexPob = `pemexPer'
			tempname pemexPCinc
			scalar `pemexPCinc' = (`pemex'/`Salud'[1,4])/`deflator'

			* 4.5.2 Asignación de gasto en variable *	
			tempvar gas_pc_pemex
			g `gas_pc_pemex' = gas_pc_Salu if benef_pemex != 0
			replace `gas_pc_pemex' = 0 if `gas_pc_pemex' == .
			Distribucion pemex, relativo(`gas_pc_pemex') macro(`pemex')
			replace pemex = 0 if pemex == .
			replace Salud = Salud + scalar(`pemexPCinc')*benef_pemex
			scalar drop `pemexPCinc'

			
			** 4.6 ISSFAM (salud) **
			capture confirm scalar issfam
			if _rc == 0 {
				local issfam = scalar(issfam)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM != "Inversión", anio(`aniope') by(ramo) min(0) nographs
				local issfam = r(defensa_nacional) + r(marina)
				restore
			}

			* 4.6.1 Scalars *
			local issfamPer = `SaludPer'[1,3] - `pemexPer'
			escalar mxnpc issfamPC = (`issfam'/`issfamPer')/`deflator'
			escalar pctpib issfamPIB = (`issfam')/`PIB'*100
			escalar mxnpc issfamPob = `issfamPer'
			tempname issfamPCinc
			scalar `issfamPCinc' = (`issfam'/`Salud'[1,5])/`deflator'

			* 4.6.2 Asignación de gasto en variable *	
			tempvar gas_pc_issfam
			g `gas_pc_issfam' = gas_pc_Salu if benef_issfam != 0
			replace `gas_pc_issfam' = 0 if `gas_pc_issfam' == .
			Distribucion issfam, relativo(`gas_pc_issfam') macro(`issfam')
			replace issfam = 0 if issfam == .

			replace Salud = Salud + scalar(`issfamPCinc')*benef_issfam
			scalar drop `issfamPCinc'


			** 4.7 Inversión en salud **
			capture confirm scalar invers
			if _rc == 0 {
				local invers = scalar(invers)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Salud" & divSIM == "Inversión", anio(`aniope') by(divCIEP) min(0) nographs
				local invers = r(Gasto_neto)
				restore
			}

			* 4.7.1 Scalars *
			escalar mxnpc inversPC = (`invers'/`pobenigh'[1,1])/`deflator'
			escalar pctpib inversPIB = (`invers')/`PIB'*100
			escalar mxnpc inversPob = `pobenigh'[1,1]
			tempname inversPCinc
			scalar `inversPCinc' = (`invers'/`Salud'[1,1])/`deflator'

			* 4.7.2 Asignación de gasto en variable *
			tempvar gas_pc_invers
			g `gas_pc_invers' = gas_pc_Salu if benef_invers != 0
			replace `gas_pc_invers' = 0 if `gas_pc_invers' == .
			Distribucion invers, relativo(`gas_pc_invers') macro(`invers')
			replace invers = 0 if invers == .
			replace Salud = Salud + scalar(`inversPCinc')*benef_invers
			scalar drop `inversPCinc'


			** 4.8 Total SALUD **
			escalar pctpib saludPIB = scalar(ssaPIB)+scalar(imssbienPIB)+scalar(imssPIB)+scalar(issstePIB)+scalar(pemexPIB)+scalar(issfamPIB)+scalar(inversPIB)
			escalar mxnpc saludPC = (scalar(saludPIB)/100*`PIB'/`pobenigh'[1,1])/`deflator'
			escalar mxnpc saludPob = `pobenigh'[1,1]


			** 4.9 Resultados **
			noisily di _newline(2) in g "{bf: B. Salud CIEP}"
			noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
				_col(32) %15.0fc in g "Derechohabientes" ///
				_col(49) %7.3f "% PIB" ///
				_col(59) %10s in g "PC (MXN `aniovp')" "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  SSa" ///
				_col(32) %15.0fc in y scalar(ssaPob) ///
				_col(49) %7.3f in y scalar(ssaPIB) ///
				_col(57) %15.0fc in y scalar(ssaPC)
			noisily di in g "  IMSS-Bienestar" ///
				_col(32) %15.0fc in y scalar(imssbienPob) ///
				_col(49) %7.3f in y scalar(imssbienPIB) ///
				_col(57) %15.0fc in y scalar(imssbienPC)
			noisily di in g "  IMSS" ///
				_col(32) %15.0fc in y scalar(imssPob) ///
				_col(49) %7.3f in y scalar(imssPIB) ///
				_col(57) %15.0fc in y scalar(imssPC)
			noisily di in g "  ISSSTE" ///
				_col(32) %15.0fc in y scalar(issstePob) ///
				_col(49) %7.3f in y scalar(issstePIB) ///
				_col(57) %15.0fc in y scalar(issstePC)
			noisily di in g "  Pemex" ///
				_col(32) %15.0fc in y scalar(pemexPob) ///
				_col(49) %7.3f in y scalar(pemexPIB) ///
				_col(57) %15.0fc in y scalar(pemexPC)
			noisily di in g "  ISSFAM" ///
				_col(32) %15.0fc in y scalar(issfamPob) ///
				_col(49) %7.3f in y scalar(issfamPIB) ///
				_col(57) %15.0fc in y scalar(issfamPC)
			noisily di
			noisily di in g "  Inversión en salud" ///
				_col(32) %15.0fc in y scalar(inversPob) ///
				_col(49) %7.3f in y scalar(inversPIB) ///
				_col(57) %15.0fc in y scalar(inversPC)
			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gasto público total" ///
				_col(32) %15.0fc in y scalar(saludPob) ///
				_col(49) %7.3f in y scalar(saludPIB) ///
				_col(57) %15.0fc in y scalar(saludPC) "}"


			** 4.10 Put excel **
			if "`excel'" == "excel" {
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
				putexcel set "$export/Deciles.xlsx", modify sheet("Salud")
				putexcel `col'17 = `=scalar(ssa)+scalar(imssbien)', nformat(number_sep)
				putexcel `col'18 = `=scalar(imss)', nformat(number_sep)
				putexcel `col'19 = `=scalar(issste)', nformat(number_sep)
				putexcel `col'20 = `=scalar(pemex)', nformat(number_sep)
				putexcel `col'21 = `=scalar(issfam)', nformat(number_sep)
				putexcel `col'22 = `=scalar(invers)', nformat(number_sep)
				putexcel `col'23 = `=scalar(salud)', nformat(number_sep)
			}

			** 4.11 Asignación per cápita en la base de datos de individuos **
			*noisily tabstat Salud [fw=factor], stat(sum) f(%20.0fc)
		}


		******************/
		**# 5 Pensiones ***
		*******************

		if "``tok''" == "pensiones" | "`1'" == "" {

			** 5.1 Pensión para adultos mayores **
			capture confirm scalar pam
			if _rc == 0 {
				local pam = scalar(pam)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Pensión AM", anio(`aniope') by(divCIEP) min(0) nographs
				local pam = r(Pension_AM)
				restore
			}

			** 5.1.1 Scalars **
			escalar mxnpc pamPC = (`pam'/`pens_pam')/`deflator'
			escalar pctpib pamPIB = (`pam')/`PIB'*100
			escalar mxnpc pamPob = `pens_pam'

			** 5.1.2 Asignación de gasto en variable **
			g Pensión_AM = scalar(pamPC)*pens_pam


			** 5.2 Pensiones IMSS **
			capture confirm scalar penimss
			if _rc == 0 {
				local penimss = scalar(penimss)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Pensiones", anio(`aniope') by(ramo) min(0) nographs
				local penimss = r(instituto_mexicano_del_s)
				restore
			}

			** 5.2.1 Scalars **
			escalar mxnpc penimssPC = (`penimss'/`pens_imss')/`deflator'
			escalar pctpib penimssPIB = (`penimss')/`PIB'*100
			escalar mxnpc penimssPob = `pens_imss'

			** 5.2.2 Asignación de gasto en variable **
			capture drop Pensiones
			g Pensiones = scalar(penimssPC)*pens_imss


			** 5.3 Pensiones ISSSTE **
			capture confirm scalar penisss
			if _rc == 0 {
				local penisss = scalar(penisss)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Pensiones", anio(`aniope') by(ramo) min(0) nographs
				local penisss = r(instituto_de_seguridad_y)
				restore
			}

			** 5.3.1 Scalars **
			escalar mxnpc penisssPC = (`penisss'/`pens_issste')/`deflator'
			escalar pctpib penisssPIB = (`penisss')/`PIB'*100
			escalar mxnpc penisssPob = `pens_issste'

			** 5.3.2 Asignación de gasto en variable **
			replace Pensiones = Pensiones + scalar(penisssPC)*pens_issste


			** 5.4 Pensiones Pemex **
			capture confirm scalar penpeme
			if _rc == 0 {
				local penpeme = scalar(penpeme)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Pensiones", anio(`aniope') by(ramo) min(0) nographs
				local penpeme = r(petroleos_mexicanos)
				restore
			}

			** 5.4.1 Scalars **
			escalar mxnpc penpemePC = (`penpeme'/`pens_pemex')/`deflator'
			escalar pctpib penpemePIB = (`penpeme')/`PIB'*100
			escalar mxnpc penpemePob = `pens_pemex'

			** 5.4.2 Asignación de gasto en variable **
			replace Pensiones = Pensiones + scalar(penpemePC)*pens_pemex


			** 5.5 Pensiones CFE, LFC, Ferronales, ISSFAM **
			capture confirm scalar penotro
			if _rc == 0 {
				local penotro = scalar(penotro)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Pensiones", anio(`aniope') by(ramo) min(0) nographs
				local penotro = r(aportaciones_a_seguridad)+r(comision_federal_de_ele)
				restore
			}

			** 5.5.1 Scalars **
			escalar mxnpc penotroPC = (`penotro'/`pens_otro')/`deflator'
			escalar pctpib penotroPIB = (`penotro')/`PIB'*100
			escalar mxnpc penotroPob = `pens_otro'

			** 5.5.2 Asignación de gasto en variable **
			replace Pensiones = Pensiones + scalar(penotroPC)*pens_otro

			escalar pctpib pensionPIB = scalar(pamPIB)+scalar(penimssPIB)+scalar(penisssPIB)+scalar(penpemePIB)+scalar(penotroPIB)
			escalar mxnpc pensionPob = scalar(pamPob)+scalar(penimssPob)+scalar(penisssPob)+scalar(penpemePob)+scalar(penotroPob)
			escalar mxnpc pensionPC = (scalar(pensionPIB)/100*`PIB')/scalar(pensionPob)


			** 5.6 Resultados **
			noisily di _newline(2) in g "{bf: C. Pensiones CIEP}"
			noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
				_col(32) %15.0fc in g "Pensionados" ///
				_col(49) %7.3f "% PIB" ///
				_col(59) %10s in g "PC (MXN `aniovp')" "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  Pensi{c o'}n Adultos Mayores" ///
				_col(32) %15.0fc in y scalar(pamPob) ///
				_col(49) %7.3f in y scalar(pamPIB) ///
				_col(57) %15.0fc in y scalar(pamPC)
			noisily di in g "  IMSS" ///
				_col(32) %15.0fc in y scalar(penimssPob) ///
				_col(49) %7.3f in y scalar(penimssPIB) ///
				_col(57) %15.0fc in y scalar(penimssPC)
			noisily di in g "  ISSSTE" ///
				_col(32) %15.0fc in y scalar(penisssPob) ///
				_col(49) %7.3f in y scalar(penisssPIB) ///
				_col(57) %15.0fc in y scalar(penisssPC)
			noisily di in g "  Pemex" ///
				_col(32) %15.0fc in y scalar(penpemePob) ///
				_col(49) %7.3f in y scalar(penpemePIB) ///
				_col(57) %15.0fc in y scalar(penpemePC)
			noisily di in g "  CFE, LFC, Ferro, ISSFAM" ///
				_col(32) %15.0fc in y scalar(penotroPob) ///
				_col(49) %7.3f in y scalar(penotroPIB) ///
				_col(57) %15.0fc in y scalar(penotroPC)
			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gasto público total" ///
				_col(32) %15.0fc in y scalar(pensionPob) ///
				_col(49) %7.3f in y scalar(pensionPIB) ///
				_col(57) %15.0fc in y scalar(pensionPC) "}"


			** 5.7 Put excel **/
			if "`excel'" == "excel" {
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
				putexcel `col'17 = `=scalar(pamPC)', nformat(number_sep)
				putexcel `col'18 = `=scalar(penimssPC)', nformat(number_sep)
				putexcel `col'19 = `=scalar(penisssPC)', nformat(number_sep)
				putexcel `col'20 = `=scalar(penpemePC)', nformat(number_sep)
				putexcel `col'21 = `=scalar(penotroPC)', nformat(number_sep)
				putexcel `col'22 = `=scalar(pensionPC)', nformat(number_sep)
			}

			** 5.8 Asignación per cápita en la base de datos de individuos **
			*noisily tabstat Pension Pensión_AM [fw=factor], stat(sum) f(%20.0fc)
		}




		*****************
		**# 6 Energía ***
		*****************
		if "``tok''" == "energia" | "`1'" == "" {
			capture drop pob
			g pob = 1
			tabstat pob [fw=factor], stat(sum) f(%20.0fc) save
			tempname Energia
			matrix `Energia' = r(StatTotal)


			** 6.1 CFE **
			capture confirm scalar gascfe
			if _rc == 0 {
				local gascfe = scalar(gascfe)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Energía" & divSIM != "Inversión" & divSIM != "Costo de la deuda", by(ramo) anio(`aniope') min(0) nographs
				local gascfe = r(comision_federal_de_ele)
				restore
			}
			escalar mxnpc gascfePC = (`gascfe'/`Energia'[1,1])/`deflator'
			escalar pctpib gascfePIB = `gascfe'/`PIB'*100
			escalar mxnpc gascfePob = `Energia'[1,1]
			
			capture drop Energia
			g Energia = scalar(gascfePC)


			** 6.2 Pemex **
			capture confirm scalar gaspemex
			if _rc == 0 {
				local gaspemex = scalar(gaspemex)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Energía" & divSIM != "Inversión" & capitulo != 9, by(ramo) anio(`aniope') min(0) nographs
				local gaspemex = r(petroleos_mexicanos)
				restore
			}
			escalar mxnpc gaspemexPC = (`gaspemex'/`Energia'[1,1])/`deflator'
			escalar pctpib gaspemexPIB = `gaspemex'/`PIB'*100
			escalar mxnpc gaspemexPob = `Energia'[1,1]
			replace Energia = Energia + scalar(gaspemexPC)


			** 6.3 SENER y otros **
			capture confirm scalar gassener
			if _rc == 0 {
				local gassener = scalar(gassener)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Energía" & divSIM != "Inversión" & divSIM != "Costo de la deuda", by(ramo) anio(`aniope') min(0) nographs
				local gassener = r(Gasto_neto)-r(comision_federal_de_ele)-r(petroleos_mexicanos)
				restore
			}
			escalar mxnpc gassenerPC = (`gassener'/`Energia'[1,1])/`deflator'
			escalar pctpib gassenerPIB = `gassener'/`PIB'*100
			escalar mxnpc gassenerPob = `Energia'[1,1]
			replace Energia = Energia + scalar(gassenerPC)


			** 6.4 Inversión en energía **
			capture confirm scalar gasinverf
			if _rc == 0 {
				local gasinverf = scalar(gasinverf)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Energía" & divSIM == "Inversión" & divSIM != "Costo de la deuda", by(ramo) anio(`aniope') min(0) nographs
				local gasinverf = r(Gasto_neto)
				restore
			}
			escalar mxnpc gasinverfPC = (`gasinverf'/`Energia'[1,1])/`deflator'
			escalar pctpib gasinverfPIB = `gasinverf'/`PIB'*100
			escalar mxnpc gasinverfPob = `Energia'[1,1]
			replace Energia = Energia + scalar(gasinverfPC)


			** 6.5 Cost de la deuda (energía) **
			capture confirm scalar gascosdeue
			if _rc == 0 {
				local gascosdeue = scalar(gascosdeue)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP == "Energía" & divSIM == "Costo de la deuda", by(ramo) anio(`aniope') min(0) nographs
				local gascosdeue = r(Gasto_neto)
				restore
			}
			escalar mxnpc gascosdeuePC = (`gascosdeue'/`Energia'[1,1])/`deflator'
			escalar pctpib gascosdeuePIB = `gascosdeue'/`PIB'*100
			escalar mxnpc gascosdeuePob = `Energia'[1,1]
			replace Energia = Energia + scalar(gascosdeuePC)

			escalar pctpib gasenergiaPIB = scalar(gaspemexPIB)+scalar(gascfePIB)+scalar(gassenerPIB)+scalar(gasinverfPIB)+scalar(gascosdeuePIB)
			escalar mxnpc gasenergiaPC = scalar(gaspemexPC)+scalar(gascfePC)+scalar(gassenerPC)+scalar(gasinverfPC)+scalar(gascosdeuePC)
			escalar mxnpc gasenergiaPob = `Energia'[1,1]


			** 6.6 Resultados **
			noisily di _newline(2) in g "{bf: D. Energía CIEP}"
			noisily di _newline in g "{bf:  Gasto por organismo" ///
				_col(32) %15.0fc in g "Poblacion" ///
				_col(49) %7.3f "% PIB" ///
				_col(59) %10s in g "PC (MXN `aniovp')" "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  CFE" ///
				_col(32) %15.0fc in y scalar(gascfePob) ///
				_col(49) %7.3f in y scalar(gascfePIB) ///
				_col(57) %15.0fc in y scalar(gascfePC)
			noisily di in g "  Pemex" ///
				_col(32) %15.0fc in y scalar(gaspemexPob) ///
				_col(49) %7.3f in y scalar(gaspemexPIB) ///
				_col(57) %15.0fc in y scalar(gaspemexPC)
			noisily di in g "  SENER y otros" ///
				_col(32) %15.0fc in y scalar(gassenerPob) ///
				_col(49) %7.3f in y scalar(gassenerPIB) ///
				_col(57) %15.0fc in y scalar(gassenerPC)
			noisily di 
			noisily di in g "  Inversión en energía" ///
				_col(32) %15.0fc in y scalar(gasinverfPob) ///
				_col(49) %7.3f in y scalar(gasinverfPIB) ///
				_col(57) %15.0fc in y scalar(gasinverfPC)
			noisily di in g "  Costo de la deuda (energía)" ///
				_col(32) %15.0fc in y scalar(gascosdeuePob) ///
				_col(49) %7.3f in y scalar(gascosdeuePIB) ///
				_col(57) %15.0fc in y scalar(gascosdeuePC)
			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gastos público total" ///
				_col(32) %15.0fc in y scalar(gasenergiaPob) ///
				_col(49) %7.3f in y scalar(gasenergiaPIB) ///
				_col(57) %15.0fc in y scalar(gasenergiaPC) "}"

		}


		****************************/
		**# 7 Resto de los gastos ***
		*****************************
		if "``tok''" == "resto" | "`1'" == "" {

			** 7.1 Gasto federalizado **
			capture confirm scalar gasfeder
			if _rc == 0 {
				local gasfeder = scalar(gasfeder)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope', by(divCIEP) anio(`aniope') min(0) nographs
				local gasfeder = r(Federalizado)
				restore
			}
			escalar mxnpc gasfederPC = (`gasfeder'/`Energia'[1,1])/`deflator'
			escalar pctpib gasfederPIB = `gasfeder'/`PIB'*100
			escalar mxnpc gasfederPob = `Energia'[1,1]
			
			capture drop Federalizado
			Distribucion Federalizado, relativo(infra_entidad) macro(`gasfeder')
			replace Federalizado = 0 if Federalizado == .
			
			g OtrosGastosT = Federalizado


			** 7.2 Costo financiero de la deuda **
			capture confirm scalar gascosto
			if _rc == 0 {
				local gascosto = scalar(gascosto)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope', by(divCIEP) anio(`aniope') min(0) nographs
				local gascosto = r(Costo_de_la_deuda)
				restore
			}
			escalar mxnpc gascostoPC = (`gascosto'/`Energia'[1,1])/`deflator'
			escalar pctpib gascostoPIB = `gascosto'/`PIB'*100
			escalar mxnpc gascostoPob = `Energia'[1,1]
			replace OtrosGastosT = OtrosGastosT + scalar(gascostoPC)


			** 7.3 Gasto en otras inversiones **
			capture confirm scalar gasinfra
			if _rc == 0 {
				local gasinfra = scalar(gasinfra)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divCIEP != "Energía", by(divCIEP) anio(`aniope') min(0) nographs
				local gasinfra = r(Otras_inversiones)
				restore
			}
			escalar mxnpc gasinfraPC = (`gasinfra'/`Energia'[1,1])/`deflator'
			escalar pctpib gasinfraPIB = `gasinfra'/`PIB'*100
			escalar mxnpc gasinfraPob = `Energia'[1,1]
			replace OtrosGastosT = OtrosGastosT + scalar(gasinfraPC)
			
			capture drop OtrasInversiones
			Distribucion OtrasInversiones, relativo(infra_entidad) macro(`gasinfra')
			replace OtrasInversiones = 0 if OtrasInversiones == .
			replace OtrosGastosT = OtrosGastosT + OtrasInversiones
			

			** 8.1 Gastos en cuidados **
			capture confirm scalar gascuidados
			if _rc == 0 {
				local gascuidados = scalar(gascuidados)/100*`PIB'
			}
			else {
				if `aniope' <= 2023 {
					local FAM_cuidados = .65
				}
				if `aniope' >= 2024 {
					local FAM_cuidados = .81
				}
				preserve
				PEF if anio == `aniope' & divSIM == "Cuidados" & divCIEP != "Educación" & divCIEP != "Salud", by(desc_pp) anio(`aniope') min(0) nographs
				local FAM_gastocuidados = r(fam_asistencia_social)*(1-`FAM_cuidados')
				local gasmadres = r(programa_de_apoyo_para_e)
				if `gasmadres' == . {
					local gasmadres = 0
				}

				local gascuidados = r(Gasto_neto) - `FAM_gastocuidados' - `gasmadres'
				restore
			}
			escalar mxnpc gascuidadosPC = (`gascuidados'/`Resto'[1,1])/`deflator'
			escalar pctpib gascuidadosPIB = `gascuidados'/`PIB'*100
			escalar mxnpc gascuidadosPob = `Resto'[1,1]

			** 7.6 Otros gastos **
			capture confirm scalar gasotros
			if _rc == 0 {
				local gasotros = scalar(gasotros)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope', by(divCIEP) anio(`aniope') min(0) nographs
				local gasotros = r(Otros_gastos)+r(Cuotas_ISSSTE)-`gascuidados'-`gasmadres'
				restore
			}
			escalar mxnpc gasotrosPC = (`gasotros'/`Energia'[1,1])/`deflator'
			escalar pctpib gasotrosPIB = `gasotros'/`PIB'*100
			escalar mxnpc gasotrosPob = `Energia'[1,1]
			replace OtrosGastosT = OtrosGastosT + scalar(gasotrosPC)
			replace OtrosGastos = scalar(gasotrosPC)

			escalar pctpib otrosgasPIB = scalar(gasfederPIB)+scalar(gascostoPIB)+scalar(gasinfraPIB)+scalar(gasotrosPIB)
			escalar mxnpc otrosgasPC = scalar(gasfederPC)+scalar(gascostoPC)+scalar(gasinfraPC)+scalar(gasotrosPC)
			escalar mxnpc otrosgasPob = `Energia'[1,1]

			* Resultados *
			noisily di _newline(2) in g "{bf: E. Otros gastos CIEP}"
			noisily di _newline in g "{bf:  Gasto por concepto" ///
				_col(32) %15.0fc in g "Poblacion" ///
				_col(49) %7.3f "% PIB" ///
				_col(59) %10s in g "PC (MXN `aniovp')" "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  Otras inversiones" ///
				_col(32) %15.0fc in y scalar(gasinfraPob) ///
				_col(49) %7.3f in y scalar(gasinfraPIB) ///
				_col(57) %15.0fc in y scalar(gasinfraPC)
			noisily di in g "  Resto de los gastos" ///
				_col(32) %15.0fc in y scalar(gasotrosPob) ///
				_col(49) %7.3f in y scalar(gasotrosPIB) ///
				_col(57) %15.0fc in y scalar(gasotrosPC)
			noisily di
			noisily di in g "  Part y otras Aport" ///
				_col(32) %15.0fc in y scalar(gasfederPob) ///
				_col(49) %7.3f in y scalar(gasfederPIB) ///
				_col(57) %15.0fc in y scalar(gasfederPC)
			noisily di in g "  Costo de la deuda (gobierno)" ///
				_col(32) %15.0fc in y scalar(gascostoPob) ///
				_col(49) %7.3f in y scalar(gascostoPIB) ///
				_col(57) %15.0fc in y scalar(gascostoPC)
			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gasto público total" ///
				_col(32) %15.0fc in y scalar(otrosgasPob) ///
				_col(49) %7.3f in y scalar(otrosgasPIB) ///
				_col(57) %15.0fc in y scalar(otrosgasPC) "}"

			*capture drop Inversión
			*Distribucion Inversión, relativo(infra_entidad) macro(`gasinfra')
			*tabstat Otros Energía Inversión [fw=factor], stat(sum) f(%20.0fc)
		}


		****************************/
		**# 8 Ingreso b{c a'}sico ***
		*****************************
		if "``tok''" == "transferencias" | "`1'" == "" {

			** 8.1 Gastos en cuidados **
			capture confirm scalar gascuidados
			if _rc == 0 {
				local gascuidados = scalar(gascuidados)/100*`PIB'
			}
			else {
				if `aniope' <= 2023 {
					local FAM_cuidados = .65
				}
				if `aniope' >= 2024 {
					local FAM_cuidados = .81
				}
				preserve
				PEF if anio == `aniope' & divSIM == "Cuidados" & divCIEP != "Educación" & divCIEP != "Salud", by(desc_pp) anio(`aniope') min(0) nographs
				local FAM_gastocuidados = r(fam_asistencia_social)*(1-`FAM_cuidados')
				local gasmadres = r(programa_de_apoyo_para_e)
				if `gasmadres' == . {
					local gasmadres = 0
				}

				local gascuidados = r(Gasto_neto) - `FAM_gastocuidados' - `gasmadres'
				restore
			}
			escalar mxnpc gascuidadosPC = (`gascuidados'/`Resto'[1,1])/`deflator'
			escalar pctpib gascuidadosPIB = `gascuidados'/`PIB'*100
			escalar mxnpc gascuidadosPob = `Resto'[1,1]

			** 8.2 Apoyo a madres trabajadoras (cuidados) **
			capture confirm scalar gasmadres
			if _rc == 0 {
				local gasmadres = scalar(gasmadres)/100*`PIB'
			}
			else {
				preserve
				PEF if anio == `aniope' & divSIM == "Cuidados" & divCIEP != "Educación" & divCIEP != "Salud", by(desc_pp) anio(`aniope') min(0) nographs
				local gasmadres = r(programa_de_apoyo_para_e)
				if `gasmadres' == . {
					local gasmadres = 0
				}
				restore
			}
			escalar mxnpc gasmadresPC = (`gasmadres'/`MADRES'[1,1])/`deflator'
			escalar pctpib gasmadresPIB = `gasmadres'/`PIB'*100
			escalar mxnpc gasmadresPob = `MADRES'[1,1]

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
				local IngBas = scalar(IngBas)/100*`PIB'
			}
			else {
				local IngBas = 0
			}
			escalar mxnpc IngBasPC = (`IngBas'/`pobIngBas'[1,1])/`deflator'
			escalar pctpib IngBasPIB = `IngBas'/`PIB'*100
			escalar mxnpc IngBasPob = `pobIngBas'[1,1]
			
			escalar pctpib transfPIB = scalar(IngBasPIB)+scalar(gasmadresPIB)+scalar(gascuidadosPIB)
			escalar mxnpc transfPC = scalar(IngBasPC)+scalar(gasmadresPC)+scalar(gascuidadosPC)
			escalar mxnpc transfPob = `pobIngBas'[1,1]

			capture drop IngBasico
			g IngBasico = 0
			if ingbasico18 == 0 & ingbasico65 == 1 {
				replace IngBasico = scalar(IngBasPC) if edad >= 18
			}
			else if ingbasico18 == 1 & ingbasico65 == 0 {
				replace IngBasico = scalar(IngBasPC) if edad < 65
			}
			else if ingbasico18 == 0 & ingbasico65 == 0 {
				replace IngBasico = scalar(IngBasPC) if edad >= 18 & edad < 65
			}
			else { 
				replace IngBasico = scalar(IngBasPC)
			}

			* Resultados *
			noisily di _newline(2) in g "{bf: F. Transferencias}" 
			noisily di _newline in g "{bf:  Gasto por concepto" ///
				_col(32) %15.0fc in g "Población" ///
				_col(49) %7.3f "% PIB" ///
				_col(59) %10s in g "PC (MXN `aniovp')" "}"
			noisily di in g _dup(71) "-"
			noisily di in g "  `bititle'" ///
				_col(32) %15.0fc in y scalar(IngBasPob) ///
				_col(49) %7.3f in y scalar(IngBasPIB) ///
				_col(57) %15.0fc in y scalar(IngBasPC)
			noisily di in g "  Apoyo a madres trabajadoras" ///
				_col(32) %15.0fc in y scalar(gasmadresPob) ///
				_col(49) %7.3f in y scalar(gasmadresPIB) ///
				_col(57) %15.0fc in y scalar(gasmadresPC)
			noisily di in g "  Gasto en cuidados" ///
				_col(32) %15.0fc in y scalar(gascuidadosPob) ///
				_col(49) %7.3f in y scalar(gascuidadosPIB) ///
				_col(57) %15.0fc in y scalar(gascuidadosPC)

			noisily di in g _dup(71) "-"
			noisily di in g "  {bf:Gasto público total" "}" ///
				_col(32) %15.0fc in y scalar(transfPob) ///
				_col(49) %7.3f in y scalar(transfPIB) ///
				_col(57) %15.0fc in y scalar(transfPC)

			replace IngBasico = IngBasico + scalar(gasmadresPC) if primi2 == 1
			replace IngBasico = IngBasico + scalar(gascuidadosPC) if cuidados_pot == 1
		}
	}



	*****************************/
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
	capture mkdir `"`c(sysdir_site)'/users/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/"'
	save `"`c(sysdir_site)'/users/$id/gastos.dta"', replace	


	if "$textbook" == "textbook" {
		noisily scalarlatex, log(gastopc) alt(gpc)
	}


	***********
	*** END ***
	***********
	timer off 9
	timer list 9
	noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
}
end
