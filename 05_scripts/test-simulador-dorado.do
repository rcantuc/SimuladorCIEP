* test-simulador-dorado.do — ¿El motor Mata de Simulador.ado (v2.0) reproduce los cinco
* archivos del bloque v1.x (PERF/INCI/CICLO/REC con preserve/collapse por réplica)?
*
* Corre Simulador con bootstrap(1) dos veces sobre la misma base y variable: con la
* opción `legacy` (bloque v1.x) y con el motor Mata, en carpetas de usuario distintas,
* y compara variable por variable los archivos PC, PERF, INCI, CICLO y REC: mismo número
* de filas, mismo patrón de missing y diferencia relativa máxima (las sumas en Mata y
* en collapse/tabstat difieren en el último bit: ~1e-14). "DORADO OK" si todo pasa con
* tolerancia 1e-10. Con bootstrap(1) ambos caminos usan los pesos originales, así que
* la comparación es exacta salvo redondeo; con B>1 la secuencia aleatoria de bsample no
* es reproducible desde Mata y solo tiene sentido comparar distribuciones.
*
* Uso (desde la raíz del repo; ~15 s):
*   /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do 05_scripts/test-simulador-dorado.do [base.dta] [variable] [anio]
*   defaults: master/2024/consumption_categ_pc.dta  gas_pc_Alim  2024

clear all
set more off
set linesize 200
if "$SIMROOT" == "" global SIMROOT "`c(pwd)'"
sysdir set SITE "${SIMROOT}/"
adopath ++ SITE
local base = cond("`1'" == "", "${SIMROOT}/master/2024/consumption_categ_pc.dta", "`1'")
local var  = cond("`2'" == "", "gas_pc_Alim", "`2'")
local anio = cond("`3'" == "", "2024", "`3'")
global nographs "nographs"
scalar anioenigh = `anio'

use "`base'", clear
capture confirm string variable sexo
if !_rc destring sexo, replace

global id dorado_legacy
preserve
timer on 1
Simulador `var' if `var' != 0 [fw=factor], aniope(`anio') aniovp(`anio') reboot nographs bootstrap(1) legacy
timer off 1
restore

global id dorado_mata
preserve
timer on 2
Simulador `var' if `var' != 0 [fw=factor], aniope(`anio') aniovp(`anio') reboot nographs bootstrap(1)
timer off 2
restore
qui timer list
di as text _n "Tiempos (B=1): legacy " as result %6.1f r(t1) as text " s | Mata " as result %6.1f r(t2) as text " s"

local fallas = 0
foreach f in PC PERF INCI CICLO REC {
	use "${SIMROOT}/users/dorado_mata/bootstraps/1/`var'`f'.dta", clear
	local Nm = _N
	rename * *_m
	gen long _i = _n
	tempfile m
	qui save `m'
	use "${SIMROOT}/users/dorado_legacy/bootstraps/1/`var'`f'.dta", clear
	local Nl = _N
	gen long _i = _n
	qui merge 1:1 _i using `m', nogen
	local worst = 0
	local wvar
	local nmissd = 0
	qui ds *_m
	foreach v in `r(varlist)' {
		local b = substr("`v'", 1, length("`v'")-2)
		capture confirm numeric variable `b'
		if _rc {
			qui count if `v' != `b'
			if r(N) > 0 local ++nmissd
			continue
		}
		qui count if (`b' < .) != (`v' < .)
		local nmissd = `nmissd' + r(N)
		qui gen double _rd = abs(`v' - `b')/max(abs(`b'), 1e-300) if `b' < . & `v' < .
		qui summ _rd
		if r(N) > 0 & r(max) > `worst' {
			local worst = r(max)
			local wvar `b'
		}
		drop _rd
	}
	local ok = (`Nm' == `Nl') & (`nmissd' == 0) & (`worst' < 1e-10)
	if !`ok' local ++fallas
	if `ok' di as text %-6s "`f'" " filas legacy/Mata = `Nl'/`Nm' | missing distintos = `nmissd' | max dif. relativa = " as result %9.2e `worst' as text " (`wvar') " as result "OK"
	else di as text %-6s "`f'" " filas legacy/Mata = `Nl'/`Nm' | missing distintos = `nmissd' | max dif. relativa = " as result %9.2e `worst' as text " (`wvar') " as error "FALLA"
}
di _newline
if `fallas' == 0 di as result "DORADO OK: el motor Mata de Simulador reproduce el bloque v1.x (B = 1) en los cinco archivos."
else di as error "DORADO FALLÓ en `fallas' archivo(s): revisar arriba."
