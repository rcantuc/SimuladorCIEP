***************************************************************
***                                                         ***
**# 1 Cuentas macroeconómicas (SCN, PIB, Balanza Comercial) ***
***                                                         ***
***************************************************************
clear all
macro drop _all
local aniovp = 2024


if "`c(username)'" == "ricardo" ///                                             // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"

if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///                       // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
cd `"`c(sysdir_personal)'"'

global export "`c(sysdir_personal)'/SIM/2022/"


PEF, base
levelsof ramo if divCIEP == 9, local(ramos)
foreach k of local ramos {
	PEF if divCIEP == 9 & ramo == `k', by(capitulo) min(0) rows(2) anio(`aniovp')
}


postfile salud anio ssa benef_ssa imssbien benef_imssbien imss benef_imss issste benef_issste pemex benef_pemex issfam benef_issfam using "`c(sysdir_personal)'/SIM/salud.dta", replace
forvalues aniope=2020(1)2024 {


	PIBDeflactor, aniovp(`aniope') nographs nooutput
	keep if anio == `aniope'
	local PIB = pibY[1]


	PIBDeflactor, aniovp(`aniovp') nographs nooutput
	keep if anio == `aniope'
	local deflator = deflator[1]



	********************************
	***                          ***
	**# 2 Información de hogares ***
	***                          ***
	********************************
	if `aniope' >= 2022 scalar anioenigh = 2022
	else if `aniope' >= 2020 & `aniope' < 2022 scalar anioenigh = 2020
	else if `aniope' >= 2018 & `aniope' < 2020 scalar anioenigh = 2018
	else if `aniope' >= 2016 & `aniope' < 2018 scalar anioenigh = 2016

	capture use "`c(sysdir_personal)'/SIM/perfiles`aniope'.dta", clear
	if _rc != 0 {
		noisily di _newline in g "Creando base: " in y "/SIM/perfiles`aniope'.dta" ///
			in g " con " in y "ENIGH " scalar(anioenigh)
		noisily di in g "Tiempo aproximado de espera: " in y "10+ minutos"
		noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `aniope'
	}
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`=anioenigh'/poblacion.dta", nogen keepus(disc*)
	capture drop __*
	tabstat factor, stat(sum) f(%20.0fc) save
	tempname pobenigh
	matrix `pobenigh' = r(StatTotal)





	**************/
	***         ***
	**# 4 Salud ***
	***         ***
	***************

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
	g benef_otros = inst_6 == "6"
	g benef_imssbien = 1 // inst_5 == "5"
		replace benef_imssbien = 0 if inst_1 == "1" | inst_2 == "2" | inst_3 == "3" | inst_4 == "4" | inst_6 == "6"


	/** Ajuste con las estadisticas oficiales **
	tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
		benef_ssa /*benef_isssteest benef_otro*/ [fw=factor], stat(sum) f(%20.0fc) save
	tempname MSalud
	matrix `MSalud' = r(StatTotal)

	replace benef_imss = benef_imss*70519556/`MSalud'[1,1]
	replace benef_issste = benef_issste*13881797/`MSalud'[1,2]
	replace benef_pemex = benef_pemex*588049/`MSalud'[1,3]
	replace benef_imssprospera = benef_imssprospera*11768906/`MSalud'[1,4]
	replace benef_seg_pop = benef_seg_pop*68069755/`MSalud'[1,5]


	** Cifras finales de asegurados **/
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



	** 4.2 IMSS-Bienestar **
	preserve


	* 4.2.1 Salud por programa *
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(desc_pp) min(0) nographs
	
	* Seguro Popular *
	local segpop0 = r(Seguro_Popular)
	if `segpop0' == . {
		local segpop0 = r(Atención_a_la_Salud_y_Medicame)
	}
	if `segpop0' == . {
		local segpop0 = r(Atención_a_la_salud_y_medicame)
	}

	* IMSS-Bienestar *
	local imssbien0 = r(Programa_IMSS_BIENESTAR)
	if `imssbien0' == . {
		local imssbien0 = 0
	}


	* 4.2.2 Salud por programa (secretaría de salud) *
	PEF if anio == `aniope' & divCIEP == 9 & ramo == 12, anio(`aniope') by(desc_pp) min(0) nographs
	local atencINSABI = r(Atención_a_la_Salud)
	local fortaINSABI = r(Fortalecimiento_a_la_atención_)
	if `fortaINSABI' == . {
		local fortaINSABI = 0
	}


	* 4.2.3 Salud por ramo *
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(ramo) min(0) nographs
	local fassa = r(Aportaciones_Federales_para_Ent)

	local nosec = r(Entidades_no_Sectorizadas)
	if `nosec' == . {
		local nosec = 0
	}

	local imssbien = `segpop0'+`imssbien0'+`fassa'+`fortaINSABI'+`atencINSABI'+`nosec'
	scalar imssbien = `imssbien'/`benef_imssbien'
	restore

	scalar imssbienPIB = `imssbien'/`PIB'*100



	** 4.4 Secretaría de Salud **
	preserve
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(desc_pp) min(0) nographs
	local incorpo = r(Régimen_de_Incorporación)
	local adeusal = r(Adeudos_con_el_IMSS_e_ISSSTE_y_)
	if `adeusal' == . {
		local adeusal = 0
	}
	local caneros = r(Seguridad_Social_Cañeros)

	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(ramo) min(0) nographs	
	local ssa = r(Salud)+`incorpo'+`adeusal'+`caneros'-`segpop0'-`fortaINSABI'-`atencINSABI'
	scalar ssa = `ssa'/`benef_ssa'
	restore

	scalar ssaPIB = `ssa'/`PIB'*100


	** 4.5 IMSS (salud) **
	preserve
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(ramo) min(0) nographs
	local imss = r(Instituto_Mexicano_del_Seguro_S)

	local imss = `imss'
	scalar imss = `imss'/`benef_imss'
	restore

	scalar imssPIB = `imss'/`PIB'*100


	** 4.6 ISSSTE Federal (salud) **
	preserve
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(ramo) min(0) nographs
	local issste = r(Instituto_de_Seguridad_y_Servic)

	local issste = `issste'
	scalar issste = `issste'/`benef_issste'
	restore

	scalar issstePIB = `issste'/`PIB'*100


	** 4.7 Pemex (salud) **
	preserve
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(ramo) min(0) nographs
	local pemex = r(Petróleos_Mexicanos)
	scalar pemex = (`pemex')/`benef_pemex'
	restore

	scalar pemexPIB = `pemex'/`PIB'*100


	** 4.8 ISSFAM (salud) **
	preserve
	PEF if anio == `aniope' & divCIEP == 9, anio(`aniope') by(ramo) min(0) nographs
	local issfam = r(Defensa_Nacional) + r(Marina)
	scalar issfam = (`issfam')/`benef_issfam'
	restore

	scalar issfamPIB = `issfam'/`PIB'*100



	** 4.10 Total SALUD **
	scalar saludPIB = ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+issfamPIB
	scalar salud = saludPIB/100*`PIB'/`benef_ssa'


	** 4.11 Resultados **
	noisily di _newline(2) in g "{bf: B. Salud CIEP: " in y "`aniope'}"
	noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
		_col(33) %15s in g "Asegurados" ///
		_col(50) %7s "% PIB" ///
		_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
	noisily di in g _dup(80) "-"
	noisily di
	noisily di in g "  SSA" ///
		_col(33) %15.0fc in y `benef_ssa' ///
		_col(50) %7.3fc in y scalar(ssaPIB) ///
		_col(60) %15.0fc in y scalar(ssa)/`deflator'
	noisily di in g "  IMSS-Bienestar" ///
		_col(33) %15.0fc in y `benef_imssbien' ///
		_col(50) %7.3fc in y scalar(imssbienPIB) ///
		_col(60) %15.0fc in y scalar(imssbien)/`deflator'
	noisily di in g "  IMSS" ///
		_col(33) %15.0fc in y `benef_imss' ///
		_col(50) %7.3fc in y scalar(imssPIB) ///
		_col(60) %15.0fc in y scalar(imss)/`deflator'
	noisily di in g "  ISSSTE" ///
		_col(33) %15.0fc in y `benef_issste' ///
		_col(50) %7.3fc in y scalar(issstePIB) ///
		_col(60) %15.0fc in y scalar(issste)/`deflator'
	noisily di in g "  Pemex" ///
		_col(33) %15.0fc in y `benef_pemex' ///
		_col(50) %7.3fc in y scalar(pemexPIB) ///
		_col(60) %15.0fc in y scalar(pemex)/`deflator'
	noisily di in g "  ISSFAM" ///
		_col(33) %15.0fc in y `benef_issfam' ///
		_col(50) %7.3fc in y scalar(issfamPIB) ///
		_col(60) %15.0fc in y scalar(issfam)/`deflator'
	noisily di
	noisily di in g _dup(80) "-"
	noisily di in g "  {bf:Gasto público total" ///
		_col(33) %15.0fc in y `benef_ssa' ///
		_col(50) %7.3fc in y scalar(saludPIB) ///
		_col(60) %15.0fc in y scalar(salud)/`deflator' "}"


	** 4.12 Asignación per cápita en la base de datos de individuos **
	replace Salud = 0
	replace Salud = Salud + scalar(ssa)*benef_ssa
	replace Salud = Salud + scalar(imssbien)*benef_imssbien
	replace Salud = Salud + scalar(imss)*benef_imss
	replace Salud = Salud + scalar(issste)*benef_issste
	replace Salud = Salud + scalar(pemex)*benef_pemex
	replace Salud = Salud + scalar(issfam)*benef_issfam
	*noisily tabstat Salud [fw=factor], stat(sum) f(%20.0fc)

	post salud (`aniope') (ssa) (`benef_ssa') (imssbien) (`benef_imssbien') (imss) (`benef_imss') (issste) (`benef_issste') (pemex) (`benef_pemex') (issfam) (`benef_issfam')
}

postclose salud

use "`c(sysdir_personal)'/SIM/salud.dta", clear
format ssa imssbien imss issste pemex issfam %10.0fc
format benef_ssa benef_imssbien benef_imss benef_issste benef_pemex benef_issfam %15.0fc

twoway ///
	(connected ssa anio, mlabel(ssa) mlabpos(0) mlabcolor(black)) ///
	(connected imssbien anio, mlabel(imssbien) mlabpos(0) mlabcolor(black)) ///
	(connected imss anio, mlabel(imss) mlabpos(0) mlabcolor(black)) ///
	(connected issste anio, mlabel(issste) mlabpos(0) mlabcolor(black)) ///
	(connected pemex anio, mlabel(pemex) mlabpos(0) mlabcolor(black)) ///
	(connected issfam anio, mlabel(issfam) mlabpos(0) mlabcolor(black)), ///
	title("Gasto en salud por institución") ///
	ytitle("MXN 2024") ///
	xtitle("") ///
	legend(label(1 "SSA") label(2 "IMSS-Bienestar") label(3 "IMSS") label(4 "ISSSTE") label(5 "Pemex") label(6 "ISSFAM") rows(1)) ///
	name(grafsalud, replace)