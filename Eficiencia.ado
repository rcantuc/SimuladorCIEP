program Eficiencia, return
quietly {
	syntax [, Anio(int $aniovp) Update Graphs Noisily Fast ID(string) REBOOT]




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

	*************
	** 5.4 OyE **
	*************
	`noisily' PEF if transf_gf == 0 & ramo != -2  ///
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
	`noisily' PEF if transf_gf == 0 & ramo != -2  ///
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
	`noisily' PEF if transf_gf == 0 & ramo != -2  ///
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
	`noisily' PEF if transf_gf == 0 & ramo != -2 ///
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
