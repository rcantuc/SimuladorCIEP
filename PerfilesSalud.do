clear all
global export "`c(sysdir_personal)'/SIM/2022/"


* Base de datos *
use "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/2022/gastospersona.dta", clear
merge m:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/SIM/2022/households.dta", nogen keep(matched)


* Micro-gastos *
egen partoyembarazo = rsum(gasto_tri gas_nm_tri) if (clave >= "J001" & clave <= "J006") ///
	| (clave >= "J007" & clave <= "J015")
egen consultas = rsum(gasto_tri gas_nm_tri) if clave >= "J016" & clave <= "J019"
egen medicinas = rsum(gasto_tri gas_nm_tri) if (clave >= "J020" & clave <= "J035") ///
	| (clave >= "J044" & clave <= "J061") | (clave >= "P065" & clave <= "069")
egen controlpeso = rsum(gasto_tri gas_nm_tri) if clave >= "J036" & clave <= "J038"
egen hospital = rsum(gasto_tri gas_nm_tri) if clave >= "J039" & clave <= "J043"
egen alternativa = rsum(gasto_tri gas_nm_tri) if clave >= "J062" & clave <= "J064"
egen seguro = rsum(gasto_tri gas_nm_tri) if clave >= "J070" & clave <= "J072"


* Collapse por individuo *
collapse (sum) partoyembarazo-seguro ingbrutotot (max) factor decil formal escol, by(folioviv foliohog numren sexo edad)


* Macro-gastos
egen salud = rsum(partoyembarazo-seguro)
label var salud "gasto de bolsillo en salud"
replace salud = salud*4
Simulador salud [w=factor], anio(2022) reboot


* Guardar *
save "`c(sysdir_personal)'/SIM/2022/PerfilesSalud.dta", replace



********************
** Gasto en salud **
clear programs
global export "`c(sysdir_personal)'/SIM/Salud/"
PEF if divCIEP == 9, by(capitulo) rows(2) min(.1)
PEF if divCIEP == 9, by(ramo) rows(2) min(.1)

PEF if divCIEP == 9, base
levelsof ramo, local(ramo)
foreach k of local ramo {
	PEF if divCIEP == 9 & ramo == `k', by(capitulo) min(0) rows(2)
}


PEF if divCIEP == 9, by(desc_ur) rows(2) min(.1)
PEF if divCIEP == 9, by(desc_funcion) rows(1) min(.01)
PEF if divCIEP == 9, by(desc_subfuncion) rows(1) min(.1)
PEF if divCIEP == 9, by(desc_ai) rows(3) min(.1)
PEF if divCIEP == 9, by(desc_modalidad) rows(2) min(.1)
PEF if divCIEP == 9, by(desc_pp) rows(3) min(.1)
PEF if divCIEP == 9, by(desc_objeto) rows(3) min(.1)




** Incidencia Salud **
forvalues aniope = 2024(-1)2020 {
	scalar drop _all
	noisily GastoPC, aniope(`aniope')
}
