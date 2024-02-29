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



*********************************/
***                            ***
*** 2. AMIF: Gasto de bolsillo ***
***                            ***
**********************************
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