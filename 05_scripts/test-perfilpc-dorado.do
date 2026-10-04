* test-perfilpc-dorado.do — ¿perfilpc (modo legacy) reproduce el bloque "Iteraciones"
* original de Expenditure.do v8.4.x? ¿Y cuánto cambia el método nuevo respecto a él?
*
* Carga una base master/<anio>/consumption_<categ>_pc.dta y, para cada variable:
*   (a) vuelve a correr el bloque original de Expenditure.do v8.4.x (líneas 781-808)
*       VERBATIM —220 tabstat + 440 replace por iteración, 25 iteraciones— partiendo
*       de `vars'hog`k';
*   (b) corre `perfilpc ..., legacy iter(25)` desde el mismo punto;
*   (c) corre `perfilpc` con el método vigente (6 cifras significativas, paro por
*       tolerancia).
* Compara (a) vs (b): deben coincidir a precisión de máquina ("DORADO OK"). Reporta
* (c) vs (a) como la magnitud del cambio metodológico (informativo, no es falla).
*
* Uso (desde la raíz del repo, tarda HORAS porque corre el bloque viejo):
*   /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do 05_scripts/test-perfilpc-dorado.do categ_ieps 2024
*   args: categ | categ_iva | categ_ieps   (default categ_ieps: 24 variables, ~3 h)
*         anio ENIGH                       (default 2024)

clear all
set more off
set linesize 200
local categ = cond("`1'" == "", "categ_ieps", "`1'")
local anio  = cond("`2'" == "", "2024", "`2'")
if "$SIMROOT" == "" global SIMROOT "`c(pwd)'"

use "${SIMROOT}/master/`anio'/consumption_`categ'_pc.dta", clear
sort folioviv foliohog numren
egen long _hhid = group(folioviv foliohog)

* Categorías presentes: toda variable gas_pc_<k>
unab pcs : gas_pc_*
local cats
foreach v of local pcs {
	local cats `cats' `=substr("`v'", 8, .)'
}
di as text "Base: consumption_`categ'_pc.dta (`anio')  N=" as result _N as text "  categorías: " as result "`cats'"

local fallas = 0
timer clear 1
foreach k of local cats {
	foreach vars in cant_ gas_ {
		capture confirm variable `vars'hog`k'
		if _rc continue
		capture confirm variable `vars'pc_`k'
		if _rc continue
		timer on 1
		qui gen double _pcO = `vars'hog`k'

		* ---- (a) bloque original, verbatim (solo cambia el nombre de la variable) ----
		local salto = 1
		forvalues iter=1(1)25 {
			forvalues edades=0(`salto')109 {
				forvalues sexos=1(1)2 {
					capture tabstat _pcO [fw=factor] ///
						if (edad >= `edades' & edad <= `edades'+`salto'-1) ///
						& sexo == "`sexos'" ///
						, stat(mean) f(%20.0fc) save
					if _rc != 0 {
						local valor = 0
					}
					else {
						local valor = r(StatTotal)[1,1]
					}
					qui replace _pcO = round(`valor',.01) ///
						if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == "`sexos'"
					qui replace _pcO = .01 ///
						if _pcO == 0
				}
			}
			capture drop _equiv
			qui egen _equiv = sum(_pcO), by(folioviv foliohog)
			qui replace _pcO = `vars'hog`k'*tot_integ*_pcO/_equiv
		}
		* --------------------------------------------------------------------------

		* (b) perfilpc legacy
		qui gen double _pcL = `vars'hog`k'
		qui perfilpc _pcL, hogar(`vars'hog`k') integrantes(tot_integ) factor(factor) hhid(_hhid) legacy iter(25)
		* (c) perfilpc vigente
		qui gen double _pcN = `vars'hog`k'
		qui perfilpc _pcN, hogar(`vars'hog`k') integrantes(tot_integ) factor(factor) hhid(_hhid)
		local itN = r(iter)

		qui gen double _dL = abs(_pcO - _pcL)
		qui summ _dL
		local mxL = r(max)
		qui gen double _dN = abs(_pcO - _pcN)
		qui summ _dN [fw=factor]
		local mxN = r(max)
		local meN = r(mean)
		qui summ _pcO [fw=factor]
		local sO = r(sum)
		local xbar = r(mean)
		timer off 1
		qui timer list 1
		di as text %-18s "`vars'pc_`k'" " legacy vs original: max|dif| = " as result %9.2e `mxL' ///
			as text " | nuevo vs original (`itN' iter.): media|dif| = " as result %8.1f `meN' as text " (" %5.1f `meN'/`xbar'*100 "% de x{c -}), max = " as result %10.1f `mxN' ///
			as text "  (" %6.0f r(t1) " s acum.)"
		if `mxL' >= 1e-6 local ++fallas
		drop _pcO _pcL _pcN _dL _dN _equiv
	}
}
di _newline
if `fallas' == 0 di as result "DORADO OK: perfilpc legacy reproduce el bloque original en todas las variables de `categ' (`anio')."
else di as error "DORADO FALLÓ en `fallas' variable(s): revisar arriba."
