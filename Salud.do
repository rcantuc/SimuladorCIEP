***************************************************************
***                                                         ***
**# 1 Cuentas macroeconómicas (SCN, PIB, Balanza Comercial) ***
***                                                         ***
***************************************************************
clear all
macro drop _all
local aniovp = 2022
local anioini = 2022
local aniofin = 2022
global id = "`c(username)'"												// IDENTIFICADOR DEL USUARIO

if "`c(username)'" == "ricardo" ///									// iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
if "`c(username)'" == "ciepmx" ///									// Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
cd `"`c(sysdir_personal)'"'
//global export "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/2023_J&J/Rumbo a 2024/I. Entregable 1. PE 2024/1. Investigacion/LaTex/images/"



******************************************
***                                    ***
*** 1. Jansen & Jansen: Gasto por ramo ***
***                                    ***
/******************************************
* Figura 3.2 *
PEF if divCIEP == 9, by(ramo) min(0) rows(2) anio(`aniovp') ///
	title("Gasto público en salud") subtitle("Distribución por ramo")
graph export "$export/sns_ramos.png", as(png) name("gastosramo") replace

* Figura 3.3 *
PEF if divCIEP == 9, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Gasto público en salud") subtitle("Distribución por capítulo de gasto")
graph export "$export/sns_capgasto.png", as(png) name("gastoscapitulo") replace

* Figuras 3.4 *
PEF if divCIEP == 9 & ramo == 50, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Instituto Mexicano del Seguro Social (IMSS)") subtitle("Gasto público en salud")
graph export "$export/sns_imss.png", as(png) name("gastoscapitulo") replace

* Figuras 3.5 *
PEF if divCIEP == 9 & ramo == 51, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Instituto de Seguridad y Servicios Sociales de los Trabajadores del Estado (ISSSTE)") subtitle("Gasto público en salud")
graph export "$export/sns_issste.png", as(png) name("gastoscapitulo") replace

* Figuras 3.6 *
PEF if divCIEP == 9 & ramo == 52, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Petróleos Mexicanos (PEMEX)") subtitle("Gasto público en salud")
graph export "$export/sns_pemex.png", as(png) name("gastoscapitulo") replace

* Figuras 3.7 *
PEF if divCIEP == 9 & ramo == 13, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Secretaría de Marina (SEMAR)") subtitle("Gasto público en salud")
graph export "$export/sns_semar.png", as(png) name("gastoscapitulo") replace

* Figuras 3.8 *
PEF if divCIEP == 9 & ramo == 7, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Secretaría de la Defensa Nacional (SEDENA)") subtitle("Gasto público en salud")
graph export "$export/sns_sedena.png", as(png) name("gastoscapitulo") replace

* Figuras 3.9 *
PEF if divCIEP == 9 & ramo == 12, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Secretaría de Salud (SSA)") subtitle("Gasto público en salud")
graph export "$export/sns_ssa.png", as(png) name("gastoscapitulo") replace

* Figuras 3.10 *
PEF if divCIEP == 9 & ramo == 33, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Aportaciones a Entidades Federativas y Municipios (FASSA)") subtitle("Gasto público en salud")
graph export "$export/sns_fassa.png", as(png) name("gastoscapitulo") replace

* Figuras 3.11 *
PEF if divCIEP == 9 & ramo == 47, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("IMSS-Bienestar (OPD)") subtitle("Gasto público en salud")
graph export "$export/sns_imssbienestar2.png", as(png) name("gastoscapitulo") replace

* Figuras 3.12 *
PEF if divCIEP == 9 & ramo == 19, by(capitulo) min(0) rows(2) anio(`aniovp') ///
	title("Aportaciones a la Seguridad Social") subtitle("Gasto público en salud")
graph export "$export/sns_r19.png", as(png) name("gastoscapitulo") replace


* Figuras xxx *
PIBDeflactor, aniovp(`aniovp') nographs nooutput
tempfile pib
save "`pib'"

PEF if divCIEP == 9 & ramo == 12, base
collapse (sum) gasto* if anio == 2023, by(capitulo desc_ur anio)
merge m:1 anio using "`pib'", nogen

graph bar (sum) gasto, over(capitulo) over(desc_ur) stack asyvars percentage


*********************************/
***                            ***
*** 2. AMIF: Gasto de bolsillo ***
***                            ***
/**********************************
forvalues anio=`anioini'(2)`aniofin' {

	** 2.1 PIBDeflactor **
	PIBDeflactor, aniovp(`aniovp') nographs nooutput
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local pibY = pibY[`k']
			local deflator = deflator[`k']
		}
	}


	** 2.2 ENIGH: concentrado **
	use "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/concentrado.dta", clear
	replace salud = salud*4/`deflator' 					// Anualizar el gasto trimestral

	* 2.2.1 Display *
	tabstat salud [fw=factor], stat(sum) f(%20.0fc) save
	noisily di _newline(2) in g "{bf: A. Gasto en cuidados de la salud: " in y "ENIGH `anio'}"
	noisily di _newline in g _col(5) "Gasto en " in y "concentrado" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto en " in y "concentrado" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,1]/`pibY'*100 in g " % PIB `anio'"
	noisily di in g _dup(80) "-"

	tempfile concentrado
	save "`concentrado'"


	** 2.3 ENIGH: gasto en salud **
	use if substr(clave,1,1) == "J" using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/gastohogar.dta", clear
	tempfile hogar
	save "`hogar'"

	use if substr(clave,1,1) == "J" using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/gastospersona.dta", clear
	tempfile individuo
	save "`individuo'"

	* 2.3.1 Append *
	use "`hogar'", clear
	append using "`individuo'"
	merge m:1 (folioviv foliohog) using "`concentrado'", nogen keepus(factor)
	capture rename factor_hog factor
	*merge m:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/perfiles`anio'.dta", nogen keepus(edad sexo decil formal)

	replace gasto_tri = gasto_tri*4/`deflator'			// Anualizar el gasto trimestral
	replace gas_nm_tri = gas_nm_tri*4/`deflator'		// Anualizar el gasto no monetario trimestral

	* 2.3.2 Gasto por conceptos *
	g concepto_salud = ""

	g parto_mon = gasto_tri if substr(clave,2,3) >= "001" & substr(clave,2,3) <= "006"
	g parto_nm = gas_nm_tri if substr(clave,2,3) >= "001" & substr(clave,2,3) <= "006"
	egen parto = rsum(parto_mon parto_nm)
	replace concepto_salud = "Parto y embarazo" if substr(clave,2,3) >= "001" & substr(clave,2,3) <= "006"

	g embarazo_mon = gasto_tri if substr(clave,2,3) >= "007" & substr(clave,2,3) <= "015"
	g embarazo_nm = gas_nm_tri if substr(clave,2,3) >= "007" & substr(clave,2,3) <= "015"
	egen embarazo = rsum(embarazo_mon embarazo_nm)
	replace concepto_salud = "Parto y embarazo" if substr(clave,2,3) >= "007" & substr(clave,2,3) <= "015"

	g servicios_mon = gasto_tri if substr(clave,2,3) >= "016" & substr(clave,2,3) <= "019"
	g servicios_nm = gas_nm_tri if substr(clave,2,3) >= "016" & substr(clave,2,3) <= "019"
	egen servicios = rsum(servicios_mon servicios_nm)
	replace concepto_salud = "Consultas" if substr(clave,2,3) >= "016" & substr(clave,2,3) <= "019"

	g medicina_mon = gasto_tri if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"
	g medicina_nm = gas_nm_tri if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"
	egen medicina = rsum(medicina_mon medicina_nm)
	replace concepto_salud = "Medicinas y aparatos" if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"

	g peso_mon = gasto_tri if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"
	g peso_nm = gas_nm_tri if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"
	egen peso = rsum(peso_mon peso_nm)
	replace concepto_salud = "Sin receta" if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"

	g hospital_mon = gasto_tri if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"
	g hospital_nm = gas_nm_tri if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"
	egen hospitalizacion = rsum(hospital_mon hospital_nm)
	replace concepto_salud = "Hospitalización" if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"

	g sinrece_mon = gasto_tri if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"
	g sinrece_nm = gas_nm_tri if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"
	egen sinreceta = rsum(sinrece_mon sinrece_nm)
	replace concepto_salud = "Sin receta" if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"

	g alter_mon = gasto_tri if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"
	g alter_nm = gas_nm_tri if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"
	egen alternativa = rsum(alter_mon alter_nm)
	replace concepto_salud = "Sin receta" if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"

	g aparatos_mon = gasto_tri if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"
	g aparatos_nm = gas_nm_tri if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"
	egen aparatos = rsum(aparatos_mon aparatos_nm)
	replace concepto_salud = "Medicinas y aparatos" if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"

	g seguro_mon = gasto_tri if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"
	g seguro_nm = gas_nm_tri if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"
	egen seguro = rsum(seguro_mon seguro_nm)
	replace concepto_salud = "Seguro" if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"

	egen salud_mon = rsum(parto_mon embarazo_mon servicios_mon medicina_mon peso_mon hospital_mon sinrece_mon alter_mon aparatos_mon seguro_mon)
	label var salud_mon "Monetario"
	
	egen salud_nm = rsum(parto_nm embarazo_nm servicios_nm medicina_nm peso_nm hospital_nm sinrece_nm alter_nm aparatos_nm seguro_nm)
	label var salud_nm "No monetario"
	
	egen salud = rsum(salud_mon salud_nm)
	label var salud "Total"

	* 2.3.3 Display *
	tabstat salud_mon salud_nm [fw=factor] if numren == "", stat(sum) f(%20.0fc) save
	noisily di _newline in g _col(5) "{bf:Información de los hogares}"
	noisily di in g _col(5) "Gasto " in y "monetario" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto " in y "monetario" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,1]/`pibY'*100 in g " % PIB `anio'"

	noisily di _newline in g _col(5) "Gasto " in y "no monetario" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,2] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto " in y "no monetario" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,2]/`pibY'*100 in g " % PIB `anio'"

	noisily di _newline in g _col(5) "Gasto " in y "total" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1]+r(StatTotal)[1,2] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto " in y "total" in g ": " _col(40) in y %20.2fc (r(StatTotal)[1,1]+r(StatTotal)[1,2])/`pibY'*100 in g " % PIB `anio'"
	noisily di in g _dup(80) "-"

	tabstat salud_mon salud_nm [fw=factor] if numren != "", stat(sum) f(%20.0fc) save
	noisily di _newline in g _col(5) "{bf:Información de los individuos}"
	noisily di in g _col(5) "Gasto " in y "monetario" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto " in y "monetario" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,1]/`pibY'*100 in g " % PIB `anio'"

	noisily di _newline in g _col(5) "Gasto " in y "no monetario" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,2] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto " in y "no monetario" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,2]/`pibY'*100 in g " % PIB `anio'"

	noisily di _newline in g _col(5) "Gasto " in y "total" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1]+r(StatTotal)[1,2] in g "   MXN `aniovp'"
	noisily di in g _col(5) "Gasto " in y "total" in g ": " _col(40) in y %20.2fc (r(StatTotal)[1,1]+r(StatTotal)[1,2])/`pibY'*100 in g " % PIB `anio'"
	noisily di in g _dup(80) "-"

	g anio = `anio'
	tempfile salud`anio'
	save `salud`anio''
}

* 2.3.4 Append *
forvalues anio=`anioini'(2)`aniofin' {
	if "`first'" == "" {
		use `salud`anio'', clear
		local first = "first"
	}
	else {
		append using `salud`anio''
	}
}


* 2.3.5 Gráficas *
graph bar (mean) salud_mon salud_nm [fw=factor], over(anio) ///
	stack asyvars ///
	title("{bf:Gasto de los hogares en salud}") ///
	subtitle("Distribución por tipo de gasto") ///
	blabel(bar, format(%9.0fc)) ///
	legend(label(1 "Monetario") label(2 "No monetario")) ///
	name(saludHogar, replace)

graph bar (mean) salud_mon [fw=factor], over(concepto_salud, sort(1) descending) over(anio) ///
	stack asyvars ///
	title("{bf:Gasto monetario de los hogares en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	blabel(bar, format(%9.0fc)) ///
	legend(rows(2)) ///
	name(saludHogar2, replace)

graph bar (mean) salud_nm [fw=factor], over(concepto_salud, sort(1) descending) over(anio) ///
	stack asyvars ///
	title("{bf:Gasto no monetario de los hogares en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	blabel(bar, format(%9.0fc)) ///
	legend(rows(2)) ///
	name(saludHogar3, replace)


* 2.3.6 Gasto total en salud *
forvalues anio=`aniofin'(2)`aniofin' {
	use `salud`anio'', clear

	preserve
	egen salud_hog = rsum(salud_mon salud_nm)
	collapse (sum) salud (max) factor anio if numren == "", by(folioviv foliohog concepto_salud)
	drop if concepto_salud == ""
	replace concepto_salud = strtoname(concepto_salud)

	reshape wide salud_hog, i(folioviv foliohog) j(concepto_salud) string
	egen salud_hog = rsum(salud_hog*)

	tempfile hogares
	save "`hogares'"

	restore
	egen salud_ind = rsum(salud_mon salud_nm)
	collapse (sum) salud_ind (max) factor anio if numren != "", by(folioviv foliohog numren concepto_salud)
	drop if concepto_salud == ""
	replace concepto_salud = strtoname(concepto_salud)

	reshape wide salud_ind, i(folioviv foliohog numren) j(concepto_salud) string
	egen salud_ind = rsum(salud_ind*)

	tempfile individuos
	save "`individuos'"


	use (folioviv foliohog numren edad sexo decil formal factor ingbrutotot) using "`c(sysdir_personal)'/SIM/perfiles`anio'.dta", clear
	egen integrantes = count(edad), by(folioviv foliohog)
	merge 1:1 (folioviv foliohog numren) using "`individuos'", nogen update replace
	merge m:1 (folioviv foliohog) using "`hogares'", nogen update replace



	*************************************************************
	** Proceso iterativo para obtener el perfil de los hogares **
	/*Iterative method. This approach is an alternative to standard regression approaches. The
	method works by initially allocating health expenditure equally to each household member.
	The per capita profile is tabulated determining average consumption at each age. The per
	capita profile is then used as a revised equivalence scale, providing the shares to allocate health
	expenditure to household members, thus producing a new per capita profile. The procedure
	is repeated each time using the newly generated profile to allocate household expenditure.
	Under some conditions, this approach will converge to the actual underlying profile. The
	robustness of this method has not been fully established, however. An attractive feature of
	this method is that negative values will not be generated.*/

	* Primera asignación *
	foreach var in salud /*parto embarazo servicios medicina peso hospital sinrece alter aparatos seguro*/ {

		*egen `var'_hog = rsum(`var'_mon_hog `var'_nm_hog)
		*egen `var'_ind = rsum(`var'_mon_ind `var'_nm_ind)

		replace `var'_hog = 0 if `var'_hog == .
		replace `var'_ind = 0 if `var'_ind == .

		g `var'_pc = `var'_hog/integrantes
		label var `var'_pc "Gasto total en `var'"

		* Iteraciones *
		noisily di _newline in y "`var': " _continue
		local salto = 3
		forvalues iter=1(1)10 {
			noisily di in w "`iter' " _cont
			forvalues edades=0(1)109 {
				forvalues sexos=1(1)2 {
					capture tabstat `var'_pc [fw=factor] if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == `sexos', stat(mean) f(%20.0fc) save
					if _rc != 0 {
						local valor = 0
					}
					else {
						local valor = r(StatTotal)[1,1]
					}
					replace `var'_pc = `valor' if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == `sexos'
				}
			}
			egen equivalencia = sum(`var'_pc), by(folioviv foliohog)
			replace `var'_pc = `var'_hog*`var'_pc/equivalencia
			drop equivalencia
		}
		replace `var'_pc = `var'_pc + `var'_ind

		g `var'_sss = `var'_pc if formal == 0
		label var `var'_sss "Gasto total en `var' (sin seguridad social)"
		noisily Simulador `var'_sss [fw=factor], reboot aniope(`anio') aniovp(`anio')

		g `var'_css = `var'_pc if formal != 0 
		label var `var'_css "Gasto total en `var' (con seguridad social)"
		noisily Simulador `var'_css [fw=factor], reboot aniope(`anio') aniovp(`anio')
	}

	tempfile gastopc`anio'
	save `gastopc`anio''
}


* 2.3.5 Gráficas *
graph bar (mean) salud_hog* [fw=factor], over(anio) ///
	stack asyvars ///
	title("{bf:Gasto de los hogares en salud}") ///
	subtitle("Distribución por tipo de gasto") ///
	blabel(bar, format(%9.0fc)) ///
	legend(label(1 "Monetario") label(2 "No monetario")) ///
	name(saludPC, replace)

graph bar (mean) salud_pc [fw=factor], over(concepto_salud, sort(1) descending) over(anio) ///
	stack asyvars ///
	title("{bf:Gasto monetario de los hogares en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	blabel(bar, format(%9.0fc)) ///
	legend(rows(2)) ///
	name(saludPC2, replace)





***************************************/
***                                  ***
**# 3. Banco Mundial - Salud Pública ***
***                                  ***
****************************************
PIBDeflactor, aniovp(2024) nographs nooutput
local PIB = scalar(pibY)
scalar anioenigh = 2022
local aniope = 2024
scalar aniovp = 2024
use "`c(sysdir_personal)'/SIM/perfiles`aniope'.dta", clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta", nogen keepus(asis_esc tipoesc nivel inst_* ing_jubila jubilado ing_PAM) 
capture drop __*
tabstat factor, stat(sum) f(%20.0fc) save
tempname pobenigh
matrix `pobenigh' = r(StatTotal)

replace Salud = 0

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
g benef_imssbien = 1 // inst_5 == "5"
if `aniope' == 2014 {
	g benef_otros = inst_5 == "5"
}
else {
	g benef_otros = inst_6 == "6"
}
replace benef_imssbien = 0 if benef_imss == 1 | benef_issste == 1 | benef_pemex == 1 | benef_issfam == 1 | benef_otros == 1

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

** 4.2.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(imssbien)*benef_imssbien


** 4.4 Secretaría de Salud **
capture confirm scalar ssa
if _rc == 0 {
	local ssa = scalar(ssa)*`benef_imssbien'
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
	scalar ssa = `ssa'/`benef_imssbien'
	restore
}

** 4.4.1 Scalars **
scalar ssaPIB = `ssa'/`PIB'*100

** 4.4.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(ssa)*benef_imssbien


** 4.5 IMSS (salud) **
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

** 4.5.1 Scalars **
scalar imssPIB = `imss'/`PIB'*100

** 4.5.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(imss)*benef_imss


** 4.6 ISSSTE Federal (salud) **
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

** 4.6.1 Scalars **
scalar issstePIB = `issste'/`PIB'*100

** 4.6.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(issste)*benef_issste


** 4.7 Pemex (salud) **
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

** 4.7.1 Scalars **
scalar pemexPIB = `pemex'/`PIB'*100

** 4.7.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(pemex)*benef_pemex


** 4.8 ISSFAM (salud) **
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

** 4.8.1 Scalars **
scalar issfamPIB = `issfam'/`PIB'*100

** 4.8.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(issfam)*benef_issfam


** 4.9 Inversión en salud **
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

** 4.9.1 Scalars **
scalar inversPIB = `invers'/`PIB'*100

** 4.9.2 Asignación de gasto en variable **
replace Salud = Salud + scalar(invers)*benef_ssa


** 4.10 Total SALUD **
scalar saludPIB = ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+issfamPIB+inversPIB
scalar salud = saludPIB/100*`PIB'/`benef_ssa'


** 4.11 Resultados **
noisily di _newline(2) in g "{bf: B. Salud CIEP}"
noisily di _newline in g "{bf:  Gasto por instituci{c o'}n" ///
	_col(33) %15s in g "Asegurados" ///
	_col(50) %7s "% PIB" ///
	_col(60) %10s in g "Per c{c a'}pita (MXN `aniovp')" "}"
noisily di in g _dup(80) "-"
noisily di in g "  SSa" ///
	_col(33) %15.0fc in y `benef_imssbien' ///
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


** 4.12 Asignación per cápita en la base de datos de individuos **
g Salud0 = Salud
noisily Simulador Salud0 [fw=factor], reboot aniope(2022)
noisily Perfiles Salud0 [fw=factor], reboot aniope(2022) title("Gasto per cápita original")

* Iteraciones *
noisily di in y "Salud Pública: " _cont
local salto = 1
egen Saludhog = sum(Salud), by(folioviv foliohog)
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
noisily Simulador Salud [fw=factor], reboot aniope(2022)
noisily Perfiles Salud [fw=factor], reboot aniope(2022) title("Gasto per cápita (25 iteraciones)")
