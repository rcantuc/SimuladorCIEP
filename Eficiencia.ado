program Eficiencia, return
quietly {
	syntax [, Anio(int $anioVP) Update Graphs Noisily Fast ID(string) REBOOT]




	********************
	*** 1. Deflactor ***
	********************
	PIBDeflactor, anio(`anio')
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local deflactor = deflator in `k'
			continue, break
		}
	}




	****************************************
	*** 2. Sistema de cuentas nacionales ***
	****************************************
	`noisily' SCN, anio(`anio')
	local SNAasalariados = r(RemSalNTA) + r(SSEmpleadores) + r(SSImputada)
	local SNAmixto = r(MixLNTA) + r(MixKNNTA)
	local SNAmixtoL = r(MixLNTA)
	local SNAmixtoK = r(MixKNNTA)
	local SNAcapital = r(CapitalNTA)

	local SNAsociedades = r(ExNOpSoc)
	local SNAExNOpHog = r(ExNOpHog)
	local SNAExBOpHog = r(ExBOpHog)
	local SNAAlquiler = r(Alquileres)
	local SNAInmobiliarias = r(Inmobiliarias)

	local SNAvehiculos = r(Adquisicion_de_vehiculos)
	local SNAnoBasico = r(Hogares_e_ISFLSH) - r(Alimentos) - r(Bebidas_no_alcoholicas)
	local SNAconsumo = r(Hogares_e_ISFLSH)

	local SNAConGob = r(ConGob)
	local SNAComprasN = r(ComprasN)

	local PIB = r(PIB)




	****************
	*** 3. ENIGH ***
	****************
	if `anio' >= 2016 {
		local enigh = "ENIGH"
		local enighanio = 2016
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}

	if `anio' == 2015 {
		local enigh = "ENIGH"
		local enighanio = 2014
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}

	if `anio' == 2014 {
		local enigh = "ENIGH"
		local enighanio = 2014
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}

	if `anio' == 2013 {
		local enigh = "ENIGH"
		local enighanio = 2012
		local hogar = "folioviv foliohog"
		local factor = "factor_hog"
		local individuo = "numren"
	}


	** Base de datos **
	capture confirm file "`c(sysdir_site)'/bases/SIM/`enighanio'/income.dta"
	if _rc != 0 {
		run "`c(sysdir_site)'/Income.do" `enighanio'
	}

	capture confirm file "`c(sysdir_site)'/bases/SIM/`enighanio'/expenditure.dta"
	if _rc != 0 {
		run "`c(sysdir_site)'/Expenditure.do" `enighanio'
	}
	

	use "`c(sysdir_site)'/bases/SIM/`enighanio'/income.dta", clear
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/bases/SIM/`enighanio'/expenditure.dta", nogen
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/bases/INEGI/ENIGH/`enighanio'/poblacion.dta", nogen force

	if `enighanio' == 2016 {
		drop if folioviv == "1908164404"													// Outlier, 65 a${ni}os, hombre, ed. superior, decil X
	}
	tempfile enigh
	save `enigh'




	**********************************************
	*** 4. Ley de Ingresos de la Federaci${o}n ***
	**********************************************
	`noisily' LIF, anio(`anio') `update' `graphs' id(`id') `remake'



	*****************
	** 4.1 Valores **
	local recursos = r(divCIEP)
	foreach k of local recursos {
		local rec`=substr("`k'",1,7)' = r(`k')
	}



	***************
	** 4.2 ENIGH **
	use `enigh', clear


	** Impuestos a los ingresos **
	Asignacion ISR__asalariados `recISR__as' "rec" "1"								"ISR asalariados"
	Asignacion ISR__PF `recISR__PF' "rec" "1"											"ISR PF"
	Asignacion CuotasT `=`recCuotas_'*.236' "rec" "1"								"Cuotas IMSS Trabajador"
	Asignacion CuotasP `=`recCuotas_'*.764' "rec" "1"								"Cuotas IMSS Patr${o}n"


	** Impuestos al consumo **
	capture confirm scalar ivageneral
	if _rc != 0 {
		scalar ivageneral = 0
	}
	if ivageneral == 1 {
		replace IVA = gasto_anual
	}
	Asignacion IVA `recIVA' "rec" "2"												"IVA"
	Asignacion IEPS__n `recIEPS__n' "rec" "2"											"IEPS no petrolero"
	Asignacion IEPS__p `recIEPS__p' "rec" "2"											"IEPS petrolero"
	Asignacion ISAN `recISAN' "rec" "2"													"ISAN"
	Asignacion Importaciones `recImporta' "rec" "2"									"Importaciones"


	** Otros: Aprovechamientos, contribuciones, derechos, otros tributarios, productos **
	Asignacion Otros `=`recAprovec'+`recContrib'+`recDerecho'+`recOtros_t'+`recProduct'' "rec" "4" "Otros"


	** Organismos y empresas + FMP **
	Asignacion ISR__PM `recISR__PM' "rec" "3"											"ISR PM"

	Asignacion IMSSISSSTE `=`recIMSS'+`recISSSTE'+`recOtras_e'' "rec" "5"	"IMSS, ISSSTE, Otras"

	Asignacion Pemex `recPemex' "rec" "6"												"Pemex"
	Asignacion CFE_PF `=`recCFE'*.268' "rec" "6"										"CFE hogares"
	Asignacion CFE_PM `=`recCFE'*.732' "rec" "6"										"CFE industrias"

	Asignacion FMP `recFMP__De' "rec" "7"												"FMP, Derechos petroleros"



	****************
	** 4.3 Labels **
	****************
	label define resources ///
		1 "Impuestos ingreso" ///
		2 "Impuestos consumo" ///
		3 "Impuestos al capital" ///
		4 "Otros" ///
		5 "IMSS, ISSSTE (sin cuotas)" ///
		6 "Pemex, CFE" ///
		7 "FMP"

	** Guardar **
	save `enigh', replace

	
	if `anio' >= 2018 {
		local alquilerPF = 15615.5*1000000*(1+${pib2018}/100)*(1+${def2018}/100)
		local alquilerPM = 45490.0*1000000*(1+${pib2018}/100)*(1+${def2018}/100)
		local predial = 103283002528*(1+${pib2018}/100)*(1+${def2018}/100)*(1+2.8/100)*(1+3.6/100)
	}
	if `anio' >= 2017 {
		local alquilerPF = 15615.5*1000000
		local alquilerPM = 45490.0*1000000
		local predial = 103283002528*(1+2.8/100)*(1+3.6/100)
	}
	if `anio' >= 2016 {
		local alquilerPF = 10772.3*1000000
		local alquilerPM = 44234.8*1000000
		local predial = 103283002528
	}




	****************************************************/
	*** 5. Presupuesto de Egresos de la Federaci${o}n ***
	*****************************************************
	`noisily' PEF, anio(`anio') `update' `graphs' id(`id') `remake'
	
	local CuotasISSSTE = r(Cuotas_ISSSTE)



	*******************
	** 5.1 Pensiones **
	*******************
	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) == "45" | substr(string(objeto),1,2) == "47" | pp == 176) ///
		, anio(`anio') concepto(ramo) id(`id') fast
	`noisily' di in g "{bf:  Pensiones}"

	* Eficiencia *
	local penLFCFerronales = r(Aportaciones_a_Seguridad_Social)						// incluye ISSFAM
	local penIMSS = r(Instituto_Mexicano_del_Seguro_S)
	local penISSSTE = r(Instituto_de_Seguridad_y_Servic)
	local penPemex = r(Petr${o}leos_Mexicanos)
	local penCFE = r(Comisi${o}n_Federal_de_Electricida)
	local penPAM = r(Desarrollo_Social)

	* Sankey *
	local usoPension = r(Gasto_bruto)


	** ENIGH **
	use `enigh', clear
	if `anio' >= 2017 {
		local pensIMSS = 4080119 					// pilar 1 + pilar 2
		local pensISSSTE = 1118662					// pilar 1 + pilar 2
		local pensPemex = 93564
		local pensCFE = 47381
		local pensLFCFerronales = 78688					// incluye ISSFAM
		local pensPAM = 5405843
	}
	if `anio' == 2016 {
		local pensIMSS = 3903474 					// pilar 1 + pilar 2
		local pensISSSTE = 1067601					// pilar 1 + pilar 2
		local pensPemex = 90787
		local pensCFE = 45166
		local pensLFCFerronales = 79912					// incluye ISSFAM
		local pensPAM =  5454050
	}
	if `anio' == 2015 {
		local pensIMSS = 3734476 					// pilar 1 + pilar 2
		local pensISSSTE = 1018871					// pilar 1 + pilar 2
		local pensPemex = 88092
		local pensCFE = 43055
		local pensLFCFerronales = 81228					// incluye ISSFAM
		local pensPAM = 5701662 
	}
	if `anio' == 2014 {
		local pensIMSS = 3588964 					// pilar 1 + pilar 2
		local pensISSSTE = 962075					// pilar 1 + pilar 2
		local pensPemex = 87015
		local pensCFE = 42058
		local pensLFCFerronales = 81335					// incluye ISSFAM
		local pensPAM = 5487664
	}
	if `anio' == 2013 {
		local pensIMSS = 3423560 					// pilar 1 + pilar 2
		local pensISSSTE = 908596					// pilar 1 + pilar 2
		local pensPemex = 83054
		local pensCFE = 39519
		local pensLFCFerronales = 84015					// incluye ISSFAM
		local pensPAM = 4851025
	}

	g penIMSS = `penIMSS'/`pensIMSS' if inst_1 == "1" & ing_jubila != 0
	g penISSSTE = `penISSSTE'/`pensISSSTE' if inst_2 == "2" & ing_jubila != 0
	g penPemex = (`penPemex'+`penCFE'+`penLFCFerronales')/(`pensPemex'+`pensCFE'+`pensLFCFerronales') if inst_4 == "4" & ing_jubila != 0
	
	capture confirm scalar pamgeneral
	if _rc != 0 {
		scalar pamgeneral = 0
	}

	if pamgeneral == 0 {
		g penPAM = `penPAM'/`pensPAM' if ing_PAM != 0
	}

	if pamgeneral == 1 {
		/*preserve
		use if entidad == "Nacional" & anio == $anioVP & edad >= 65 using `"`c(sysdir_site)'/bases/SIM/Poblacion/poblacion`c(os)'.dta"', clear
		tabstat poblacion, stat(sum) f(%20.0fc) save
		tempname pob65
		matrix `pob65' = r(StatTotal)
		local pensPAM = `pob65'[1,1]
		restore*/

		g beta = 1 if edad >= 65
		replace beta = beta - .9*(75-edad)/10 if edad >= 65 & edad <= 75

		tabstat beta [aw=factor_hog], stat(sum) f(%20.0fc) save
		tempname beta
		matrix `beta' = r(StatTotal)
		local pensPAM = `beta'[1,1]

		g penPAM = `penPAM'/`pensPAM'*beta if edad >= 65
	}

	egen double Pension = rsum(penIMSS penISSSTE penPemex penPAM)
	
	*g double uso_Pension1 = Pension
	Asignacion Pension `usoPension' "uso" "1" "Pensiones"

	save `enigh', replace



	**********************
	** 5.2 Educaci${o}n **
	**********************
	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion == 10 ///
		, anio(`anio') concepto(desc_subfuncion) id(`id') fast
	`noisily' di in g "{bf:  Educaci${o}n}"

	* Eficiencia *
	local basica = r(Educaci${o}n_B${a}sica)
	local medsup = r(Educaci${o}n_Media_Superior)
	local superi = r(Educaci${o}n_Superior)
	local posgra = r(Posgrado)

	* Sankey *
	local usoEducaci = r(Gasto_bruto)


	** ENIGH **
	use `enigh', clear
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

	tabstat alum_basica alum_medsup alum_superi alum_posgra [fw=factor_hog], stat(sum) f(%15.0fc) save
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

	egen double Educaci = rsum(basica medsup superi posgra)
	Asignacion Educaci `usoEducaci' "uso" "2" "Educaci${o}n"
	save `enigh', replace



	***************
	** 5.3 Salud **
	***************
	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion == 21 ///
		& (pp == 38 | desc_pp == 1367) ///
		, anio(2018) concepto(desc_pp) id(`id') fast
	`noisily' di in g "{bf:  Salud: " in y "IMSS-Prospera y Seguro Popular}"

	* Eficiencia *
	local salPROSPERA = r(Programa_IMSS_PROSPERA)											// IMSS-Prospera
	if r(Programa_IMSS_PROSPERA) == . {
		local salPROSPERA = r(Programa_IMSS_Oportunidades)									// IMSS-Oportunidades
	}
	local salSegPop = r(Seguro_Popular)															// Seguro Popular


	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& modalidad == "E" & pp == 13 & ramo == 52, ///
		anio(`anio') concepto(ramo) id(`id') fast												// Salud - Pemex (no mover de lugar)
	`noisily' di in g "{bf:  Salud: " in y "Pemex (salud)}"

	* Eficiencia *
	local salPemex = r(Petr${o}leos_Mexicanos)


	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion == 21 ///
		& (pp != 38 & desc_pp != 1367) ///
		, anio(`anio') concepto(ramo) id(`id') fast
	`noisily' di in g "{bf:  Salud: " in y "Otros}"

	* Eficiencia *
	local salIMSS = r(Instituto_Mexicano_del_Seguro_S)										// IMSS
	local salISSSTE = r(Instituto_de_Seguridad_y_Servic)									// ISSSTE
	local salISSFAM = r(Defensa_Nacional)+r(Marina)											// ISSFAM
	local salFASSA = r(Aportaciones_Federales_para_Ent)									// FASSA
	local salSSA = r(Salud)																			// SSA, sin Seguro Popular

	* Sankey *
	local usoSalud = r(Gasto_bruto)+`salSegPop'+`salPROSPERA'+`salPemex'				// Uso, Salud


	** ENIGH **
	use `enigh', clear
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
		benef_ssa benef_isssteest benef_otro [fw=factor_hog], stat(sum) f(%15.0fc) save
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

	egen double Salud = rsum(imss issste pemex imssprospera seg_pop ssa)
	Asignacion Salud `usoSalud' "uso" "3" "Salud"

	save `enigh', replace
	
	save `"`c(sysdir_site)'/bases/SIM/RECUSO.dta"', replace



	*************
	** 5.4 OyE **
	*************
	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion != 21 ///
		& ramo >= 50 ///
		, anio(`anio')	concepto(ramo) id(`id') fast
	`noisily' di in g "{bf:  Organismos y empresas}" 

	* Eficiencia *
	local usoIMSS_resto = r(Instituto_Mexicano_del_Seguro_S)
	local usoISSSTE_resto = r(Instituto_de_Seguridad_y_Servic)
	local usoPemex_resto = r(Petr${o}leos_Mexicanos)-`salPemex'
	local usoCFE_resto = r(Comisi${o}n_Federal_de_Electricida)


	** ENIGH **
	use `enigh', clear
	egen double IMSSISSSTE_resto = rsum(imss issste)
	Asignacion IMSSISSSTE_resto `=`usoIMSS_resto'+`usoISSSTE_resto'' "uso" "6" "IMSS e ISSSTE"

	g double CFE_resto = 1/CFE
	Asignacion CFE_resto `usoCFE_resto' "uso" "7" "Comisi${o}n Federal de Electricidad"

	g double Pemex_resto = factor_hog
	Asignacion Pemex_resto `usoPemex_resto' "uso" "7" "Petr${o}leos Mexicanos"
	save `enigh', replace



	******************
	** 5.6 Gobierno **
	/******************
	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion != 21 ///
		& ramo < 50 ///
		& (finalidad == 1 | (substr(string(objeto),1,1) == "1" | substr(string(objeto),1,1) == "2" | substr(string(objeto),1,1) == "3")) ///
		, anio(`anio')	concepto(ramo) id(`id') fast
	`noisily' di in g "{bf:  Gobierno}" 

	local usoGobierno = r(Gasto_bruto)


	** ENIGH **
	use `enigh', clear
	g Gobierno = ing_subor if scian == 93
	Asignacion Gobierno `usoGobierno' "uso" "5" "Funci${o}n Gobierno"

	save `enigh', replace



	************************/
	** 5.5 Infraestructura **
	*************************
	`noisily' PEF if neto == 0 & ramo != -2  ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion != 21 ///
		& ramo < 50 ///
		/*& (finalidad != 1 & (substr(string(objeto),1,1) != "1" & substr(string(objeto),1,1) != "2" & substr(string(objeto),1,1) != "3"))*/ ///
		& (substr(string(objeto),1,1) == "5" | substr(string(objeto),1,1) == "6") ///
		, anio(`anio')	concepto(ramo) id(`id') fast
	`noisily' di in g "{bf:  Infraestructura}" 

	local usoInfraestructura = r(Gasto_bruto)


	** ENIGH **
	use `enigh', clear
	g Infraestructura = factor_hog
	Asignacion Infraestructura `usoInfraestructura' "uso" "4" "Infraestructura"

	save `enigh', replace



	***************
	** 5.7 Otros **
	***************
	`noisily' PEF if neto == 0 & ramo != -2 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion != 21 ///
		& ramo < 50 ///
		/*& (finalidad != 1 & (substr(string(objeto),1,1) != "1" & substr(string(objeto),1,1) != "2" & substr(string(objeto),1,1) != "3"))*/ ///
		& (substr(string(objeto),1,1) != "5" & substr(string(objeto),1,1) != "6") ///
		, anio(`anio') id(`id') fast
	`noisily' di in g "{bf:  Otros}" 

	local usos = r(resumido)
	foreach k of local usos {
		local uso`=substr("`k'",1,12)' = r(`k')
	}


	** ENIGH **
	use `enigh', clear
	foreach k of local usos {
		capture confirm variable uso_`=substr("`k'",1,12)'
		if _rc != 0 {
			if `"`=substr("`k'",1,12)'"' == "neto_Transfe" {
				g double `=substr("`k'",1,12)' = factor_hog
				Asignacion `=substr("`k'",1,12)' `uso`=substr("`k'",1,12)'' "uso" "8" "Transferencias a estados y municipios"
			}
			else if `"`=substr("`k'",1,12)'"' == "neto_Transac" {
				g double `=substr("`k'",1,12)' = factor_hog
				Asignacion `=substr("`k'",1,12)' `uso`=substr("`k'",1,12)'' "uso" "9" "Costo de la deuda"
			}
			else if `"`=substr("`k'",1,12)'"' != "neto_Transac" & `"`=substr("`k'",1,12)'"' != "neto_Transfe" {
				g double `=substr("`k'",1,12)' = factor_hog
				Asignacion `=substr("`k'",1,12)' `=`uso`=substr("`k'",1,12)''-`CuotasISSSTE'' "uso" "6" "Otros gastos"
			}
		}
	}

	save `enigh', replace
	
	

	***************************
	** 5.8 Ingreso b${a}sico **
	***************************
	if "`id'" != "" {
		`noisily' PEF if neto == 0 & ramo == -2 ///
			, anio(`anio') id(`id')
		local usoIngBasi = r(Gasto_bruto)
		`noisily' di in g "{bf:  Ingreso b${a}sico}" 

		
		** ENIGH **
		use `enigh', clear
		
		capture confirm scalar ingbasico18
		if _rc != 0 {
			scalar ingbasico18 = 1
		}
		
		capture confirm scalar ingbasico65
		if _rc != 0 {
			scalar ingbasico65 = 1
		}

		if ingbasico18 == 1 & ingbasico65 == 1 {
			g double IngBasi = factor_hog
		}
		if ingbasico18 == 0 & ingbasico65 == 1 {
			g double IngBasi = factor_hog if edad >= 18
		}
		if ingbasico18 == 1 & ingbasico65 == 0 {
			g double IngBasi = factor_hog if edad < 65
		}
		if ingbasico18 == 0 & ingbasico65 == 0 {
			g double IngBasi = factor_hog if edad < 65 & edad >= 18
		}

		Asignacion IngBasi `usoIngBasi' "uso" "0" "Ingreso b${a}sico"
	}



	*****************
	** 5.9  Labels **
	*****************
	label define uses ///
		1 "Pensiones" ///
		2 "Educacion" ///
		3 "Salud" ///
		4 "Infraestructura" ///
		5 "Gobierno" ///
		6 "_Otros" ///
		7 "_Pemex, CFE" ///
		8 "Transfs. subnacionales" ///
		9 "Costo de la deuda" ///
		0 "Ingreso b${a}sico"

	capture drop __*
	save "`c(sysdir_site)'/users/`id'/Sankey`anio'.dta", replace




	******************************/
	*** 6. Gr${a}fica LIF + PEF ***
	*******************************
	if ("$graphs" == "on" | "`graphs'" == "graphs") & "`fast'" == "" {
		graph combine ingresos gastos, cols(1) ///
			title("{bf:INGRESOS - GASTOS}", position(11)) ///
			subtitle("= (+) ahorro / (-) financiamiento", position(11)) ///
			caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.", position(11)) ///
			note("") ///
			name(ingresosGastos, replace)

		graph save ingresosGastos "`c(sysdir_site)'/users/`id'/IngresosGastos.gph", replace

		capture window manage close graph ingresos
		capture window manage close graph gastos
	}




	*******************************/
	*** 10. Resultados: Ingresos ***
	********************************
	noisily di _newline(5) in g "{bf:TASAS EFECTIVAS DEL SISTEMA FISCAL: " in y "INGRESOS `anio'}"

	noisily di _newline(2) in y "{bf: A. " in y "Impuestos al ingreso" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci${o}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Compensaci${o}n de asalariados" ///
		_col(44) %7.3fc in y `SNAasalariados'/`PIB'*100 ///
		_col(55) in g "ISR (salarios)" ///
		_col(88) %7.3fc in y (`recISR__as')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recISR__as')/`SNAasalariados'*100 " %"
	noisily di in g "  Ingreso mixto laboral" ///
		_col(44) %7.3fc in y `SNAmixtoL'/`PIB'*100 ///
		_col(55) in g "ISR (f${i}sicas)" ///
		_col(88) %7.3fc in y (`recISR__PF'-`alquilerPF')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recISR__PF'-`alquilerPF')/`SNAmixtoL'*100 " %"
	noisily di in g "  Compensaci${o}n de asalariados" ///
		_col(44) %7.3fc in y `SNAasalariados'/`PIB'*100 ///
		_col(55) in g "Cuotas IMSS" ///
		_col(88) %7.3fc in y (`recCuotas_')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recCuotas_')/`SNAasalariados'*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Asalariados y mixto laboral" ///
		_col(44) %7.3fc in y (`SNAmixtoL'+`SNAasalariados')/`PIB'*100 ///
		_col(55) in g "Impuestos al ingreso" ///
		_col(88) %7.3fc in y (`recISR__as'+`recCuotas_'+`recISR__PF'-`alquilerPF')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recISR__as'+`recCuotas_'+`recISR__PF'-`alquilerPF')/(`SNAmixtoL'+`SNAasalariados')*100 " %" "}"


	noisily di _newline(2) in y "{bf: B. " in y "Impuestos al consumo" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci${o}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Consumo hogares e ISFLSH (no b${a}sico)" ///
		_col(44) %7.3fc in y `SNAnoBasico'/`PIB'*100 ///
		_col(55) in g "IVA" ///
		_col(88) %7.3fc in y `recIVA'/`PIB'*100 ///
		_col(99) %7.1fc in y `recIVA'/`SNAnoBasico'*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y `SNAconsumo'/`PIB'*100 ///
		_col(55) in g "IEPS" ///
		_col(88) %7.3fc in y (`recIEPS__p'+`recIEPS__n')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recIEPS__p'+`recIEPS__n')/`SNAconsumo'*100 " %"
	noisily di in g "  Consumo hogares e ISFLSH" ///
		_col(44) %7.3fc in y `SNAconsumo'/`PIB'*100 ///
		_col(55) in g "Importaciones" ///
		_col(88) %7.3fc in y `recImporta'/`PIB'*100 ///
		_col(99) %7.1fc in y `recImporta'/`SNAconsumo'*100 " %"
	noisily di in g "  Compra de veh${i}culos" ///
		_col(44) %7.3fc in y `SNAvehiculos'/`PIB'*100 ///
		_col(55) in g "ISAN" ///
		_col(88) %7.3fc in y `recISAN'/`PIB'*100 ///
		_col(99) %7.1fc in y `recISAN'/`SNAvehiculos'*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "{bf:  Consumo final" ///
		_col(44) %7.3fc in y (`SNAconsumo')/`PIB'*100 ///
		_col(55) in g "Impuestos al consumo" ///
		_col(88) %7.3fc in y (`recIEPS__p'+`recIEPS__n'+`recIVA'+`recISAN'+`recImporta')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recIEPS__p'+`recIEPS__n'+`recIVA'+`recISAN'+`recImporta')/(`SNAconsumo')*100 " %" "}"


	noisily di _newline(2) in y "{bf: C. " in y "Impuestos e ingresos de capital" "}"
	noisily di _newline in g "{bf:  Cuentas Nacionales" ///
		_col(44) %7s in g "% PIB" ///
		_col(55) "Recaudaci${o}n" ///
		_col(88) %7s in g "% PIB" ///
		_col(99) in g "Tasa efectiva" "}"
	noisily di in g _dup(111) "-"
	noisily di in g "  Sociedades e ISFLSH" ///
		_col(44) %7.3fc in y (`SNAsociedades')/`PIB'*100 ///
		_col(55) in g "ISR (morales)" ///
		_col(88) %7.3fc in y (`recISR__PM'-`alquilerPM')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recISR__PM'-`alquilerPM')/(`SNAsociedades')*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (`SNAcapital'-`SNAExNOpHog')/`PIB'*100 ///
		_col(55) in g "FMP (petr${o}leo)" ///
		_col(88) %7.3fc in y (`recFMP__De')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recFMP__De')/(`SNAcapital'-`SNAExNOpHog')*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (`SNAcapital'-`SNAExNOpHog')/`PIB'*100 ///
		_col(55) in g "CFE, Pemex, IMSS, ISSSTE" ///
		_col(88) %7.3fc in y (`recCFE'+`recPemex'+`recIMSS'+`recISSSTE')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recCFE'+`recPemex'+`recIMSS'+`recISSSTE')/(`SNAcapital'-`SNAExNOpHog')*100 " %"
	noisily di in g "  Ingreso de capital (- alq. imp.)" ///
		_col(44) %7.3fc in y (`SNAcapital'-`SNAExNOpHog')/`PIB'*100 ///
		_col(55) in g "Productos, derechos, aprovech..." ///
		_col(88) %7.3fc in y (`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec'+`recContrib')/(`SNAcapital'-`SNAExNOpHog')*100 " %"
	noisily di in g "  Alquiler de bienes ra${i}ces (- alq. imp.)" ///
		_col(44) %7.3fc in y (`SNAAlquiler'-`SNAExBOpHog')/`PIB'*100 ///
		_col(55) in g "ISR (arrendamiento PF)" ///
		_col(88) %7.3fc in y (`alquilerPF')/`PIB'*100 ///
		_col(99) %7.1fc in y (`alquilerPF')/(`SNAAlquiler'-`SNAExBOpHog')*100 " %"
	noisily di in g "  Inmobiliarias de bienes ra${i}ces" ///
		_col(44) %7.3fc in y (`SNAInmobiliarias')/`PIB'*100 ///
		_col(55) in g "ISR (arrendamiento PM)" ///
		_col(88) %7.3fc in y (`alquilerPM')/`PIB'*100 ///
		_col(99) %7.1fc in y (`alquilerPM')/(`SNAInmobiliarias')*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "  Alquileres e inmobiliarias" ///
		_col(44) %7.3fc in y (`SNAAlquiler'+`SNAInmobiliarias')/`PIB'*100 ///
		_col(55) in g "Predial*" ///
		_col(88) %7.3fc in y `predial'/`PIB'*100 ///
		_col(99) %7.1fc in y `predial'/(`SNAAlquiler'+`SNAInmobiliarias')*100 " %"
	noisily di in g _dup(111) "-"
	noisily di in g "  {bf:Ingreso de capital y propiedad" ///
		_col(44) %7.3fc in y (`SNAcapital')/`PIB'*100 ///
		_col(55) in g "Impuestos e ingresos de capital" ///
		_col(88) %7.3fc in y (`recISR__PM'+`alquilerPF'+`recPemex'+`recCFE'+`recIMSS'+`recISSSTE'+`recFMP__De'+`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec')/`PIB'*100 ///
		_col(99) %7.1fc in y (`recISR__PM'+`alquilerPF'+`recPemex'+`recCFE'+`recIMSS'+`recISSSTE'+`recFMP__De'+`recOtros_t'+`recDerecho'+`recProduct'+`recAprovec')/(`SNAcapital')*100 " %" "}"


	noisily di in g "  ISR (arrendamiento): " _col(44) in y %20.0fc (`alquilerPF'+`alquilerPM')
	noisily di in g "  ISR PF (arrendamiento): " _col(44) in y %20.0fc (`alquilerPF')


	*****************************
	*** 11. Resultados: Gasto ***
	*****************************
	use if entidad == "Nacional" & anio == $anioVP using `"`c(sysdir_site)'/bases/SIM/Poblacion/poblacion`c(os)'.dta"', clear

	tabstat poblacion, stat(sum) f(%20.0fc) save
	tempname pob2018
	matrix `pob2018' = r(StatTotal)

	tabstat poblacion if edad >= 18, stat(sum) f(%20.0fc) save
	tempname pob201818
	matrix `pob201818' = r(StatTotal)

	tabstat poblacion if edad < 65, stat(sum) f(%20.0fc) save
	tempname pob201865
	matrix `pob201865' = r(StatTotal)
	
	tabstat poblacion if edad >= 18 & edad < 65, stat(sum) f(%20.0fc) save
	tempname pob20181865
	matrix `pob20181865' = r(StatTotal)

	
	noisily di _newline(5) in g "{bf:TASAS EFECTIVAS DEL SISTEMA FISCAL: " in y "GASTO `anio'}"

	noisily di _newline(2) in y "{bf: A. " in y "Educaci${o}n p${u}blica" "}"
	noisily di _newline in g "{bf:  Gasto por nivel" ///
		_col(33) %15s in g "Alumnos" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c${a}pita (MXN $anioVP)" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  B${a}sica" ///
		_col(33) %15.0fc in y `Educacion'[1,1] ///
		_col(50) %7.3fc in y `basica'/`PIB'*100 ///
		_col(60) %15.0fc in y `basica'/`Educacion'[1,1]/`deflactor'
	noisily di in g "  Media superior" ///
		_col(33) %15.0fc in y `Educacion'[1,2] ///
		_col(50) %7.3fc in y `medsup'/`PIB'*100 ///
		_col(60) %15.0fc in y `medsup'/`Educacion'[1,2]/`deflactor'
	noisily di in g "  Superior" ///
		_col(33) %15.0fc in y `Educacion'[1,3] ///
		_col(50) %7.3fc in y `superi'/`PIB'*100 ///
		_col(60) %15.0fc in y `superi'/`Educacion'[1,3]/`deflactor'
	noisily di in g "  Posgrado" ///
		_col(33) %15.0fc in y `Educacion'[1,4] ///
		_col(50) %7.3fc in y `posgra'/`PIB'*100 ///
		_col(60) %15.0fc in y `posgra'/`Educacion'[1,4]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Educaci${o}n" ///
		_col(33) %15.0fc in y (`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4]) ///
		_col(50) %7.3fc in y (`basica'+`medsup'+`superi'+`posgra')/`PIB'*100 ///
		_col(60) %15.0fc in y (`basica'+`medsup'+`superi'+`posgra')/(`Educacion'[1,1]+`Educacion'[1,2]+`Educacion'[1,3]+`Educacion'[1,4])/`deflactor'


	noisily di _newline(2) in y "{bf: B. " in y "Pensiones" "}"
	noisily di _newline in g "{bf:  Gasto por instituci${o}n" ///
		_col(33) %15s in g "Pensionados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c${a}pita (MXN $anioVP)" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  Pensi${o}n para adultos mayores" ///
		_col(33) %15.0fc in y `pensPAM' ///
		_col(50) %7.3fc in y `penPAM'/`PIB'*100 ///
		_col(60) %15.0fc in y `penPAM'/`pensPAM'/`deflactor'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `pensIMSS' ///
		_col(50) %7.3fc in y `penIMSS'/`PIB'*100 ///
		_col(60) %15.0fc in y `penIMSS'/`pensIMSS'/`deflactor'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `pensISSSTE' ///
		_col(50) %7.3fc in y `penISSSTE'/`PIB'*100 ///
		_col(60) %15.0fc in y `penISSSTE'/`pensISSSTE'/`deflactor'
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `pensPemex' ///
		_col(50) %7.3fc in y `penPemex'/`PIB'*100 ///
		_col(60) %15.0fc in y `penPemex'/`pensPemex'/`deflactor'
	noisily di in g "  CFE" ///
		_col(33) %15.0fc in y `pensCFE' ///
		_col(50) %7.3fc in y `penCFE'/`PIB'*100 ///
		_col(60) %15.0fc in y `penCFE'/`pensCFE'/`deflactor'
	noisily di in g "  LFC, Ferronales, ISSFAM" ///
		_col(33) %15.0fc in y `pensLFCFerronales' ///
		_col(50) %7.3fc in y `penLFCFerronales'/`PIB'*100 ///
		_col(60) %15.0fc in y `penLFCFerronales'/`pensLFCFerronales'/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Pensiones" ///
		_col(33) %15.0fc in y (`pensPAM'+`pensIMSS'+`pensISSSTE'+`pensPemex'+`pensCFE'+`pensLFCFerronales') ///
		_col(50) %7.3fc in y (`penPAM'+`penIMSS'+`penISSSTE'+`penPemex'+`penCFE'+`penLFCFerronales')/`PIB'*100 ///
		_col(60) %15.0fc in y (`penPAM'+`penIMSS'+`penISSSTE'+`penPemex'+`penCFE'+`penLFCFerronales')/(`pensPAM'+`pensIMSS'+`pensISSSTE'+`pensPemex'+`pensCFE'+`pensLFCFerronales')/`deflactor'


	noisily di _newline(2) in y "{bf: C. " in y "Salud" "}"
	noisily di _newline in g "{bf:  Gasto por instituci${o}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c${a}pita (MXN $anioVP)" "}"
	noisily di in g _dup(80) "-"
	noisily di in g "  SSA (sin afiliaci${o}n)" ///
		_col(33) %15.0fc in y `pob2018'[1,1] ///
		_col(50) %7.3fc in y `salSSA'/`PIB'*100 ///
		_col(60) %15.0fc in y `salSSA'/`pob2018'[1,1]/`deflactor'
	noisily di in g "  FASSA, Seguro Popular" ///
		_col(33) %15.0fc in y `Salud'[1,5]+`Salud'[1,7] ///
		_col(50) %7.3fc in y (`salFASSA'+`salSegPop')/`PIB'*100 ///
		_col(60) %15.0fc in y (`salFASSA'+`salSegPop')/(`Salud'[1,5]+`Salud'[1,7])/`deflactor'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `Salud'[1,1] ///
		_col(50) %7.3fc in y `salIMSS'/`PIB'*100 ///
		_col(60) %15.0fc in y `salIMSS'/`Salud'[1,1]/`deflactor'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `Salud'[1,2] ///
		_col(50) %7.3fc in y `salISSSTE'/`PIB'*100 ///
		_col(60) %15.0fc in y `salISSSTE'/`Salud'[1,2]/`deflactor'
	noisily di in g "  IMSS-Prospera" ///
		_col(33) %15.0fc in y `Salud'[1,4] ///
		_col(50) %7.3fc in y `salPROSPERA'/`PIB'*100 ///
		_col(60) %15.0fc in y `salPROSPERA'/`Salud'[1,4]/`deflactor'
	noisily di in g "  Pemex, ISSFAM" ///
		_col(33) %15.0fc in y `Salud'[1,3] ///
		_col(50) %7.3fc in y (`salPemex'+`salISSFAM')/`PIB'*100 ///
		_col(60) %15.0fc in y (`salPemex'+`salISSFAM')/`Salud'[1,3]/`deflactor'
	noisily di in g _dup(75) "-"
	noisily di in g "  Salud" ///
		_col(33) %15.0fc in y (`pob2018'[1,1]) ///
		_col(50) %7.3fc in y (`salSSA'+`salFASSA'+`salSegPop'+`salIMSS'+`salISSSTE'+`salPROSPERA'+`salPemex'+`salISSFAM')/`PIB'*100 ///
		_col(60) %15.0fc in y (`salSSA'+`salFASSA'+`salSegPop'+`salIMSS'+`salISSSTE'+`salPROSPERA'+`salPemex'+`salISSFAM')/(`pob2018'[1,1]+`Salud'[1,5]+`Salud'[1,7]+`Salud'[1,1]+`Salud'[1,2]+`Salud'[1,4]+`Salud'[1,3])/`deflactor'


	if "`id'" != "" {
		noisily di _newline(2) in y "{bf: D. " in y "Ingreso b${a}sico" "}"
		noisily di _newline in g "{bf:  Gasto" ///
			_col(33) %15s in g "Poblaci${o}n" ///
			_col(50) %7s "% PIB" ///
			_col(60) %10s in g "Per c${a}pita (MXN $anioVP)" "}"
		noisily di in g _dup(80) "-"
		noisily di in g "  General" ///
			_col(33) %15.0fc in y `pob2018'[1,1] ///
			_col(50) %7.3fc in y `usoIngBasi'/`PIB'*100 ///
			_col(60) %15.0fc in y `usoIngBasi'/`pob2018'[1,1]/`deflactor'
		noisily di in g "  Mayores de 18" ///
			_col(33) %15.0fc in y `pob201818'[1,1] ///
			_col(50) %7.3fc in y `usoIngBasi'/`PIB'*100 ///
			_col(60) %15.0fc in y `usoIngBasi'/`pob201818'[1,1]/`deflactor'
		noisily di in g "  Menores de 65" ///
			_col(33) %15.0fc in y `pob201865'[1,1] ///
			_col(50) %7.3fc in y `usoIngBasi'/`PIB'*100 ///
			_col(60) %15.0fc in y `usoIngBasi'/`pob201865'[1,1]/`deflactor'
		noisily di in g "  Entre 18 y 65" ///
			_col(33) %15.0fc in y `pob20181865'[1,1] ///
			_col(50) %7.3fc in y `usoIngBasi'/`PIB'*100 ///
			_col(60) %15.0fc in y `usoIngBasi'/`pob20181865'[1,1]/`deflactor'
	}


	noisily di _newline(2) in y "{bf: E. " in y "Gini's" "}"
	noisily di _newline in g "{bf:  Transferencias netas" ///
		_col(33) %15s in g "Gini" "}"
	noisily di in g _dup(48) "-"
	noisily di in g "  Total" ///
		_col(33) %15.3fc in y `gini_transfNetas'
	noisily di in g "  Formales" ///
		_col(33) %15.3fc in y `gini_transfFormal'
	noisily di in g "  Informales" ///
		_col(33) %15.3fc in y `gini_transfInformal'




	************/
	*** FINAL ***
	*************
}
end

program define Asignacion
	args var macro recuso account label

	tempvar `var'TOT
	egen double ``var'TOT' = sum(`var') if factor_hog != 0
	g double `recuso'_`var'`account' = `var'/``var'TOT'*`macro'/factor_hog if factor_hog != 0
	replace `recuso'_`var'`account' = 0 if `recuso'_`var'`account' == .
	label var `recuso'_`var'`account' `"`label'"'
end
