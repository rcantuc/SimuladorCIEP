***************************************************************
***                                                         ***
**# 1 Cuentas macroeconómicas (SCN, PIB, Balanza Comercial) ***
***                                                         ***
***************************************************************
clear all
macro drop _all
local aniovp = 2024

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


** PIBDeflactor **
local anio = 2022
local pibY = 29452832077000					// PIB `anio'



************************
** ENIGH: concentrado **
use "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/concentrado.dta", clear
replace salud = salud*4 					// Anualizar el gasto trimestral

** Display **
noisily tabstat salud [fw=factor], stat(sum) f(%20.0fc) save
noisily di _newline(2) in g "{bf: A. Gasto en cuidados de la salud: " in y "ENIGH `anio'}"
noisily di _newline in g _col(5) "Gasto en " in y "concentrado" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1] in g " MXN"
noisily di in g _col(5) "Gasto en " in y "concentrado" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,1]/`pibY'*100 in g " % PIB"
noisily di in g _dup(80) "-"

tempfile concentrado
save "`concentrado'"



***************************
** ENIGH: gasto en salud **
use if substr(clave,1,1) == "J" using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/gastohogar.dta", clear
tempfile hogar
save "`hogar'"

use if substr(clave,1,1) == "J" using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/gastospersona.dta", clear
tempfile individuo
save "`individuo'"


* Append *
use "`hogar'", clear
append using "`individuo'"
merge m:1 (folioviv foliohog) using "`concentrado'", nogen keepus(factor)
replace gasto_tri = gasto_tri*4			// Anualizar el gasto trimestral
replace gas_nm_tri = gas_nm_tri*4		// Anualizar el gasto no monetario trimestral


* Gasto por conceptos *
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

g medicamentos_mon = gasto_tri if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"
g medicamentos_nm = gas_nm_tri if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"
egen medicamentos = rsum(medicamentos_mon medicamentos_nm)
replace concepto_salud = "Medicamentos y aparatos" if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"

g peso_mon = gasto_tri if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"
g peso_nm = gas_nm_tri if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"
egen peso = rsum(peso_mon peso_nm)
replace concepto_salud = "Alternativa, peso y sin receta" if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"

g hospitalizacion_mon = gasto_tri if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"
g hospitalizacion_nm = gas_nm_tri if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"
egen hospitalizacion = rsum(hospitalizacion_mon hospitalizacion_nm)
replace concepto_salud = "Hospitalización" if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"

g sinreceta_mon = gasto_tri if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"
g sinreceta_nm = gas_nm_tri if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"
egen sinreceta = rsum(sinreceta_mon sinreceta_nm)
replace concepto_salud = "Alternativa, peso y sin receta" if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"

g alternativa_mon = gasto_tri if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"
g alternativa_nm = gas_nm_tri if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"
egen alternativa = rsum(alternativa_mon alternativa_nm)
replace concepto_salud = "Alternativa, peso y sin receta" if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"

g aparatos_mon = gasto_tri if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"
g aparatos_nm = gas_nm_tri if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"
egen aparatos = rsum(aparatos_mon aparatos_nm)
replace concepto_salud = "Medicamentos y aparatos" if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"

g seguro_mon = gasto_tri if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"
g seguro_nm = gas_nm_tri if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"
egen seguro = rsum(seguro_mon seguro_nm)
replace concepto_salud = "Seguro" if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"

egen salud_mon = rsum(parto_mon embarazo_mon servicios_mon medicamentos_mon peso_mon hospitalizacion_mon sinreceta_mon alternativa_mon aparatos_mon seguro_mon)
label var salud_mon "Monetario"

egen salud_nm = rsum(parto_nm embarazo_nm servicios_nm medicamentos_nm peso_nm hospitalizacion_nm sinreceta_nm alternativa_nm aparatos_nm seguro_nm)
label var salud_nm "No monetario"

egen salud = rsum(salud_mon salud_nm)
label var salud "Total"


** Display **
tabstat salud_mon salud_nm [fw=factor], stat(sum) f(%20.0fc) save
noisily di _newline in g _col(5) "Gasto " in y "monetario" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1] in g " MXN"
noisily di in g _col(5) "Gasto " in y "monetario" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,1]/`pibY'*100 in g " % PIB"

noisily di _newline in g _col(5) "Gasto " in y "no monetario" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,2] in g " MXN"
noisily di in g _col(5) "Gasto " in y "no monetario" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,2]/`pibY'*100 in g " % PIB"
noisily di in g _dup(80) "-"


** Gráficas **
graph pie salud_mon salud_nm [fw=factor], ///
	title("{bf:Gasto de los hogares en salud}") ///
	subtitle("Distribución por tipo de gasto") ///
	plabel(_all percent, format(%9.1fc)) ///
	name(saludHogar, replace)

graph pie salud_mon [fw=factor], over(concepto_salud) ///
	title("{bf:Gasto monetario de los hogares en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	plabel(_all percent, format(%9.1fc)) ///
	legend(rows(2)) ///
	name(saludHogar2, replace)

graph pie salud_nm [fw=factor], over(concepto_salud) ///
	title("{bf:Gasto no monetario de los hogares en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	plabel(_all percent, format(%9.1fc)) ///
	legend(rows(2)) ///
	name(saludHogar3, replace)


collapse (sum) *_mon *_nm salud (max) factor, by(folioviv foliohog numren)
egen hog_seguro_mon = count(seguro_mon) if seguro_mon != 0, by(folioviv foliohog)
replace hog_seguro_mon = 0 if hog_seguro_mon == .
egen hog_seguro_nm = count(seguro_nm) if seguro_nm != 0, by(folioviv foliohog)
replace hog_seguro_nm = 0 if hog_seguro_nm == .

noisily tabstat hog_seguro_mon [fw=factor], stat(count) f(%20.0fc)
noisily tabstat hog_seguro_mon if hog_seguro_mon != 0 [fw=factor], stat(count) f(%20.0fc)
noisily tabstat hog_seguro_nm if hog_seguro_nm != 0 [fw=factor], stat(count) f(%20.0fc)





exit
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
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/perfiles`anio'.dta", nogen keepus(edad sexo escol formal decil factor)

egen salud_mon_hog = sum(salud_mon), by(folioviv foliohog)
egen salud_nm_hog = sum(salud_nm), by(folioviv foliohog)
egen salud_hog = sum(salud), by(folioviv foliohog)
drop if numren == ""

* Primera iteración *
egen integrantes = count(edad), by(folioviv foliohog)
g salud_mon_pc = salud_mon_hog/integrantes
label var salud_mon_pc "Gasto monetario en salud"

g salud_nm_pc = salud_nm_hog/integrantes
label var salud_nm_pc "Gasto no monetario en salud"

g salud_pc = salud_hog/integrantes
label var salud_pc "Gasto total en salud"

*lpoly salud_mon_pc edad, bwidth(5) ci kernel(gaussian) degree(2) ///
	name(Perfil1, replace) generate(salud_pc1) at(edad) noscatter ///
	title("{bf:Gasto en salud}") ///
	xtitle(edad) ///
	ytitle(per cápita) ///
	///ylabel(0(.5)1.5) ///
	subtitle(Perfil de los hogares) ///
	caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
	//nograph

forvalues edades=0(1)109 {
	//noisily di _newline in g _col(5) "Edad: " in y `edades' 
	capture tabstat salud_mon_pc salud_nm_pc salud_pc [fw=factor] if edad == `edades', stat(mean) f(%20.0fc) save
	if _rc != 0 {
		local valor_mon = 0
		local valor_nm = 0
		local valor = 0
	}
	else {
		local valor_mon = r(StatTotal)[1,1]
		local valor_nm = r(StatTotal)[1,2]
		local valor = r(StatTotal)[1,3]
	}
	replace salud_mon_pc = `valor_mon' if edad == `edades'
	replace salud_nm_pc = `valor_nm' if edad == `edades'
	replace salud_pc = `valor' if edad == `edades'
}

g salud_mon_pc0 = salud_mon_pc
label var salud_mon_pc0 "Gasto monetario en salud (distribución inicial)"

g salud_nm_pc0 = salud_nm_pc
label var salud_nm_pc0 "Gasto no monetario en salud (distribución inicial)"

g salud_pc0 = salud_pc
label var salud_pc0 "Gasto total en salud (distribución inicial)"

*noisily Simulador salud_mon_pc0 [fw=factor], base("ENIGH `anio'") reboot anio(`anio')
*noisily Simulador salud_nm_pc0 [fw=factor], base("ENIGH `anio'") reboot anio(`anio')
noisily Simulador salud_pc0 [fw=factor], base("ENIGH `anio'") reboot anio(`anio')


* Iteraciones *
forvalues iter=1(1)20 {
	egen equivalencia_mon = sum(salud_mon_pc), by(folioviv foliohog)
	egen equivalencia_nm = sum(salud_nm_pc), by(folioviv foliohog)
	egen equivalencia = sum(salud_pc), by(folioviv foliohog)
	replace salud_mon_pc = salud_mon_hog*salud_mon_pc/equivalencia_mon
	replace salud_nm_pc = salud_nm_hog*salud_nm_pc/equivalencia_nm
	replace salud_pc = salud_hog*salud_pc/equivalencia
	drop equivalencia*

	forvalues edades=0(1)109 {
		//noisily di _newline in g _col(5) "Edad: " in y `edades' 
		capture tabstat salud_mon_pc salud_nm_pc salud_pc [fw=factor] if edad == `edades', stat(mean) f(%20.0fc) save
		if _rc != 0 {
			local valor_mon = 0
			local valor_nm = 0
			local valor = 0
		}
		else {
			local valor_mon = r(StatTotal)[1,1]
			local valor_nm = r(StatTotal)[1,2]
			local valor = r(StatTotal)[1,3]
		}
		replace salud_mon_pc = `valor_mon' if edad == `edades'
		replace salud_nm_pc = `valor_nm' if edad == `edades'
		replace salud_pc = `valor' if edad == `edades'
	}

	*noisily Simulador salud_mon_pc [fw=factor], base("ENIGH `anio'") reboot anio(`anio')
	*noisily Simulador salud_nm_pc [fw=factor], base("ENIGH `anio'") reboot anio(`anio')
	noisily Simulador salud_pc [fw=factor], base("ENIGH `anio'") reboot anio(`anio')
}
exit



********************************
** ENIGH: gasto de individuos **
use if substr(clave,1,1) == "J" using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`anio'/gastospersona.dta", clear
replace gasto_tri = gasto_tri*4			// Anualizar el gasto trimestral
replace gas_nm_tri = gas_nm_tri*4		// Anualizar el gasto no monetario trimestral


* Conceptos *
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

g medicamentos_mon = gasto_tri if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"
g medicamentos_nm = gas_nm_tri if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"
egen medicamentos = rsum(medicamentos_mon medicamentos_nm)
replace concepto_salud = "Medicamentos y aparatos" if substr(clave,2,3) >= "020" & substr(clave,2,3) <= "035"

g peso_mon = gasto_tri if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"
g peso_nm = gas_nm_tri if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"
egen peso = rsum(peso_mon peso_nm)
replace concepto_salud = "Alternativa, peso y sin receta" if substr(clave,2,3) >= "036" & substr(clave,2,3) <= "038"

g hospitalizacion_mon = gasto_tri if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"
g hospitalizacion_nm = gas_nm_tri if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"
egen hospitalizacion = rsum(hospitalizacion_mon hospitalizacion_nm)
replace concepto_salud = "Hospitalización" if substr(clave,2,3) >= "039" & substr(clave,2,3) <= "043"

g sinreceta_mon = gasto_tri if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"
g sinreceta_nm = gas_nm_tri if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"
egen sinreceta = rsum(sinreceta_mon sinreceta_nm)
replace concepto_salud = "Alternativa, peso y sin receta" if substr(clave,2,3) >= "044" & substr(clave,2,3) <= "061"

g alternativa_mon = gasto_tri if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"
g alternativa_nm = gas_nm_tri if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"
egen alternativa = rsum(alternativa_mon alternativa_nm)
replace concepto_salud = "Alternativa, peso y sin receta" if substr(clave,2,3) >= "062" & substr(clave,2,3) <= "064"

g aparatos_mon = gasto_tri if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"
g aparatos_nm = gas_nm_tri if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"
egen aparatos = rsum(aparatos_mon aparatos_nm)
replace concepto_salud = "Medicamentos y aparatos" if substr(clave,2,3) >= "065" & substr(clave,2,3) <= "069"

g seguro_mon = gasto_tri if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"
g seguro_nm = gas_nm_tri if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"
egen seguro = rsum(seguro_mon seguro_nm)
replace concepto_salud = "Seguro" if substr(clave,2,3) >= "070" & substr(clave,2,3) <= "072"


* Agregado *
egen salud_mon = rsum(parto_mon embarazo_mon servicios_mon medicamentos_mon peso_mon hospitalizacion_mon sinreceta_mon alternativa_mon aparatos_mon seguro_mon)
label var salud_mon "Monetario"

egen salud_nm = rsum(parto_nm embarazo_nm servicios_nm medicamentos_nm peso_nm hospitalizacion_nm sinreceta_nm alternativa_nm aparatos_nm seguro_nm)
label var salud_nm "No monetario"

egen salud = rsum(salud_mon salud_nm)
label var salud "Total"

** Display **
tabstat salud_mon salud_nm [fw=factor], stat(sum) f(%20.0fc) save
noisily di _newline in g _col(5) "Gasto monetario en " in y "individuos" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,1] in g " MXN"
noisily di in g _col(5) "Gasto monetario en " in y "individuos" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,1]/`pibY'*100 in g " % PIB"

noisily di _newline in g _col(5) "Gasto no monetario en " in y "individuos" in g ": " _col(40) in y %20.0fc r(StatTotal)[1,2] in g " MXN"
noisily di in g _col(5) "Gasto no monetario en " in y "individuos" in g ": " _col(40) in y %20.2fc r(StatTotal)[1,2]/`pibY'*100 in g " % PIB"
noisily di in g _dup(80) "-"

** Gráfica **
graph pie salud_mon salud_nm [fw=factor], ///
	title("{bf:Gasto de los individuos en salud}") ///
	subtitle("Distribución por tipo de gasto") ///
	plabel(_all percent, format(%9.1fc)) ///
	name(saludIndividuos, replace)

graph pie salud_mon [fw=factor], over(concepto_salud) ///
	title("{bf:Gasto monetario de los individuos en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	plabel(_all percent, format(%9.1fc)) ///
	legend(rows(2)) ///
	name(saludIndividuos2, replace)

graph pie salud_nm [fw=factor], over(concepto_salud) ///
	title("{bf:Gasto no monetario de los individuos en salud}") ///
	subtitle("Distribución por concepto de gasto") ///
	plabel(_all percent, format(%9.1fc)) ///
	legend(rows(2)) ///
	name(saludIndividuos3, replace)


** Collpase **
collapse (sum) *_mon *_nm salud (max) factor, by(folioviv foliohog numren)
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/perfiles`anio'.dta", nogen keepus(edad sexo escol formal decil)


** Perfiles **
rename salud_mon salud_mon_ind
label var salud_mon_ind "Gasto monetario del individuo en salud"
noisily Simulador salud_mon_ind [fw=factor], base("ENIGH `anio'") reboot anio(`anio')

rename salud_nm salud_nm_ind
label var salud_nm_ind "Gasto no monetario del individuo en salud"
noisily Simulador salud_nm_ind [fw=factor], base("ENIGH `anio'") reboot anio(`anio')














exit

postfile salud anio ssa benef_ssa imssbien benef_imssbien imss benef_imss issste benef_issste pemex benef_pemex issfam benef_issfam using "`c(sysdir_personal)'/SIM/salud.dta", replace
forvalues aniope=`anio'(1)2024 {


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
	if `aniope' >= `anio' scalar anioenigh = `anio'
	else if `aniope' >= `anio' & `aniope' < `anio' scalar anioenigh = `anio'
	else if `aniope' >= `anio' & `aniope' < `anio' scalar anioenigh = `anio'
	else if `aniope' >= 2016 & `aniope' < `anio' scalar anioenigh = 2016

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

g sinss = ssa+imssbien
format sinss %15.0fc

g benef_sinss = benef_ssa+benef_imssbien
format benef_sinss %15.0fc

twoway ///
	(connected sinss anio, mlabel(sinss) mlabpos(0) mlabcolor(black)) ///
	(connected imss anio, mlabel(imss) mlabpos(0) mlabcolor(black)) ///
	(connected issste anio, mlabel(issste) mlabpos(0) mlabcolor(black)) ///
	(connected pemex anio, mlabel(pemex) mlabpos(0) mlabcolor(black)) ///
	(connected issfam anio, mlabel(issfam) mlabpos(0) mlabcolor(black)), ///
	title("Gasto en salud por institución") ///
	ytitle("MXN 2024") ///
	xtitle("") ///
	legend(label(1 "Sin Seguridad Social") label(2 "IMSS") label(3 "ISSSTE") label(4 "Pemex") label(5 "ISSFAM") rows(1)) ///
	name(grafsalud, replace)
