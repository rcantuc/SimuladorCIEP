*! PIBDeflactorNL.do  v1.0.0 — actividad económica y precios de Nuevo León: Simulador Fiscal NL (capa NL-0.2.0)
*
* QUÉ ES ESTO
*   El equivalente NL del segundo comando de SIM.do (PIBDeflactor): PIBE nominal
*   y real, deflactor implícito, crecimiento real (PIBE anual como ancla +
*   nowcast ITAEE), inflación (INPC Nuevo León) y comparativos nacionales con
*   las mismas transformaciones, más una proyección corta hasta el año de
*   política con los criterios del PIBDeflactor nacional. Exporta JSON + HTML
*   autocontenido para Consejo Nuevo León.
*
* GUARDIA DE FRONTERA (no negociable): este driver es un SIDECAR MACRO —
*   contexto, nowcast y deflactación de entregables NL. NO recalibra ni
*   reescala la base micro: no toca TasasEfectivasMicro.ado, ni los factores
*   Altimir, ni introduce reajuste alguno contra el PIBE. La calibración
*   vigente es nacional con brechas declaradas (F0, agosto); el reajuste
*   biproporcional es una fase futura explícita, no un efecto colateral de
*   este archivo.
*
* FUENTES (todas del canal INEGI; cero números a mano)
*   BIE, vía nl-assets/nl-bie.do (_NLbie: misma vía pública que AccesoBIE,
*   filtrando el área geográfica — ver ahí por qué el motor no puede):
*     750453 PIBE valores corrientes (millones MXN), áreas 19 y 00
*     746097 PIBE valores constantes 2018 (millones MXN 2018), áreas 19 y 00
*     753357 PIBE índice de precios implícitos 2018=100 (compuerta), 19 y 00
*     741180 ITAEE serie original, índice 2018=100, con petróleo, 19 y 00
*     741927 ITAEE serie desestacionalizada, índice 2018=100, 19 y 00
*   INPC nacional vía AccesoBIE del motor (910392, mensual).
*   INPC Nuevo León vía _NLinpc (programa INPC de INEGI, estructura
*     112001700070 "por entidad federativa", serie 902690, base 2Q jul 2018,
*     Actualización de Canasta y Ponderadores 2024): el INPC estatal NO está
*     en el BIE.
*
* CRITERIOS HEREDADOS DE PIBDeflactor.ado (motor)
*   - Anual: índice de precios = promedio de trimestres (aquí el deflactor
*     PIBE ya es anual: nominal/real); INPC del año = diciembre (dic/dic);
*     además se reporta el promedio anual.
*   - Deflactor: índice con base en el año de valor presente (aniovp = 1).
*   - Proyección: si existe un exógeno para el año se usa; si no, el promedio
*     geométrico del crecimiento desde el inicio de la serie (geopib/geodef =
*     anioinicial, el default del motor). El año observado parcial se
*     sustituye por el exógeno cuando existe. Nominal = real x deflactor.
*     Para NL no hay exógeno CGPE estatal: el exógeno es el NOWCAST ITAEE para
*     los años con dato trimestral (empalme declarado) y después el promedio
*     geométrico. El mismo criterio se aplica al comparativo nacional de este
*     driver (el motor, en SIM.do, usa los $pib/$def/$inf del CGPE).
*
* SALIDAS (generadas, gitignored): users/$id/nodos/actividad-nl.json,
*   users/$id/nodos/actividad-nl.html, users/$id/nodos/actividad-nl.log.
*   Caché de descargas: raw/temp/AccesoBIE/nl_*.csv + .meta (vintage).
*
* USO:  do "${SIMROOT}/01_modulos/PIBDeflactorNL.do"
*   global nlbie_offline 1  -> reutiliza la caché sin descargar (desarrollo).
* OJO: destruye los datos en memoria.

version 17										// candado: misma interpretación en Stata 17 (Mac) y 19.5 (runner Windows)

*** 0 RAÍZ, LOG, IDENTIDAD ***
SIMroot
local site `"${SIMROOT}"'
if "$id" == "" global id = "`c(username)'"
capture mkdir `"`site'/users"'
capture mkdir `"`site'/users/$id"'
capture mkdir `"`site'/users/$id/nodos"'
local q = char(34)
local off = cond("$nlbie_offline" == "1", "offline", "")

capture confirm scalar aniovp
if _rc == 0 local anioref = scalar(aniovp)
else local anioref = year(date("$S_DATE", "DMY"))
capture confirm scalar anioPE
if _rc == 0 local aniope = scalar(anioPE)
else local aniope = `anioref'
local aniomax = max(`anioref', `aniope')

* Procedencia: log PROPIO y con nombre (coexiste con el log de batch o con el de
* otro driver de la capa); se cierra al final. Sin él no hay exportación válida. *
capture log close nlact
quietly log using `"`site'/users/$id/nodos/actividad-nl.log"', replace text name(nlact)
capture quietly log query nlact
if `"`r(filename)'"' == "" {
	di as err "PIBDeflactorNL: no pudo abrirse el log de procedencia; sin procedencia no hay exportación válida."
	exit 459
}
local logfile "actividad-nl.log"

run `"`site'/01_modulos/nl-assets/nl-identidad.do"'
_NLidentidad, modulo("Actividad económica y precios")
local nl_producto `"`r(producto)'"'
local nl_titulo `"`r(titulo)'"'
local nl_subtitulo `"`r(subtitulo)'"'
local nl_vmotor `"`r(version_motor)'"'
local nl_vnl `"`r(version_nl)'"'

run `"`site'/01_modulos/nl-assets/nl-bie.do"'
capture confirm file `"`site'/set_token.do"'
if _rc == 0 run `"`site'/set_token.do"'

* Número a JSON con precisión completa (espejo de _sjnum de scalarjson.ado) *
capture program drop _nlnum
program define _nlnum, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	local s = trim(string(`e', "%25.17g"))
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end

*** 1 DESCARGAS (vintage y checksum por serie) ***
noisily di _newline in g "{bf:1. Series INEGI}"
local fuentes ""
local kk = 0
foreach spec in "750453 19 pibeNnl" "750453 00 pibeNnac" "746097 19 pibeRnl" "746097 00 pibeRnac" ///
	"753357 19 defIdxnl" "753357 00 defIdxnac" "741180 19 itaeenl" "741927 19 itaeeSAnl" {
	tokenize `spec'
	_NLbie `1', area(`2') nombre(`3') `off'
	local ++kk
	local f`kk'_id "`1'"
	local f`kk'_area "`2'"
	local f`kk'_var "`3'"
	local f`kk'_titulo `"`r(titulo)'"'
	local f`kk'_fecha `"`r(fecha)'"'
	local f`kk'_ultimo `"`r(ultimo)'"'
	local f`kk'_chk = r(checksum)
	local f`kk'_n = r(n)
	local f`kk'_sello `"`r(sello)'"'
	local f`kk'_fuente "BIE"
	tempfile s`kk'
	quietly save `s`kk''
}
_NLinpc 902690, estructura(112001700070) nombre(inpcnl) `off'
local ++kk
local f`kk'_id "902690"
local f`kk'_area "19"
local f`kk'_var "inpcnl"
local f`kk'_titulo `"`r(titulo)'"'
local f`kk'_fecha `"`r(fecha)'"'
local f`kk'_ultimo `"`r(ultimo)'"'
local f`kk'_chk = r(checksum)
local f`kk'_n = r(n)
local f`kk'_sello ""
local f`kk'_fuente "INPC-INEGI"
local kinpcnl = `kk'
tempfile sinpcnl
quietly save `sinpcnl'

* Comparativo nacional trimestral: el BIE no publica un total nacional del
* ITAEE (las tablas 741180/741927 son solo estatales). Se usa el PIB trimestral
* real del motor (734407 nominal / 735143 índice implícito, AccesoBIE),
* normalizado a 2018 = 100 para compararlo con el ITAEE en el mismo eje.
* La serie desestacionalizada nacional queda vacía y se declara. *
noisily AccesoBIE 734407 735143, nombres(pibQ indiceQ)
quietly {
	keep anio trimestre pibQ indiceQ
	drop if pibQ == . | indiceQ == .
	g double pibQR = pibQ/indiceQ
	summarize pibQR if anio == 2018, meanonly
	g double itaeenac = pibQR/r(mean)*100
	g double itaeeSAnac = .
	keep anio trimestre itaeenac itaeeSAnac
	sort anio trimestre
	local ++kk
	local f`kk'_id "734407+735143"
	local f`kk'_area "00"
	local f`kk'_var "itaeenac"
	local f`kk'_titulo "PIB trimestral nacional real = PIB corriente (734407) / índice de precios implícitos (735143), normalizado 2018 = 100 (AccesoBIE del motor); comparativo del ITAEE"
	local f`kk'_fecha `"`c(current_date)' `c(current_time)'"'
	local f`kk'_ultimo = string(anio[_N]) + "/" + string(trimestre[_N], "%02.0f")
	checksum `"`site'/raw/temp/AccesoBIE/734407.csv"'
	local f`kk'_chk = r(checksum)
	local f`kk'_n = _N
	local f`kk'_sello ""
	local f`kk'_fuente "BIE (AccesoBIE)"
	tempfile sitaeenac
	save `sitaeenac'
}

* INPC nacional: comando del motor (vía pública si no hay token) *
noisily AccesoBIE 910392, nombres(inpcnac)
quietly {
	keep anio mes inpcnac
	sort anio mes
	local ++kk
	local f`kk'_id "910392"
	local f`kk'_area "00"
	local f`kk'_var "inpcnac"
	local f`kk'_titulo "Índice Nacional de Precios al Consumidor, índice general mensual, base 2Q jul 2018 (AccesoBIE del motor)"
	local f`kk'_fecha `"`c(current_date)' `c(current_time)'"'
	local f`kk'_ultimo = string(anio[_N]) + "/" + string(mes[_N], "%02.0f")
	checksum `"`site'/raw/temp/AccesoBIE/910392.csv"'
	local f`kk'_chk = r(checksum)
	local f`kk'_n = _N
	local f`kk'_sello ""
	local f`kk'_fuente "BIE (AccesoBIE)"
	local kinpcnac = `kk'
	tempfile sinpcnac
	save `sinpcnac'
}
local nfuentes = `kk'

*** 2 ANUAL: PIBE nominal, real, deflactor implícito ***
noisily di _newline in g "{bf:2. PIBE anual}"
quietly {
	use `s1', clear
	forvalues k = 2/6 {
		merge 1:1 anio using `s`k'', nogen
	}
	drop if pibeNnl == . & pibeRnl == .
	rename sellopibeNnl selloPIBEnl
	rename sellopibeNnac selloPIBEnac
	drop sellopibeR* sellodefIdx*
	sort anio
	tsset anio
	foreach g in nl nac {
		g double defl`g' = pibeN`g'/pibeR`g'*100
		label var defl`g' "Deflactor implícito PIBE (2018=100)"
		g double crecPIBE`g' = (pibeR`g'/L.pibeR`g' - 1)*100
		g double varDefl`g' = (defl`g'/L.defl`g' - 1)*100
	}
	g double partPIBEnl = pibeNnl/pibeNnac*100
	* Compuerta 1: el deflactor implícito reproduce el índice de precios del BIE *
	count if reldif(deflnl, defIdxnl) > 1e-6 | reldif(deflnac, defIdxnac) > 1e-6
	if r(N) > 0 {
		noisily di as err "PIBDeflactorNL: nominal/real no reproduce el índice de precios implícitos del BIE en `r(N)' años. No se exporta."
		exit 459
	}
	noisily di in g "  Compuerta deflactor: " in y "PASÓ" in g " (nominal/real = índice BIE 753357, reldif < 1e-6, `=_N' años)."
	* Rejilla completa *
	summarize anio, meanonly
	local pibe0 = r(min)
	local pibe1 = r(max)
	count
	if r(N) != `pibe1' - `pibe0' + 1 {
		noisily di as err "PIBDeflactorNL: años faltantes en la serie PIBE (`pibe0'-`pibe1', `r(N)' obs). No se exporta."
		exit 459
	}
	count if pibeNnl == . | pibeRnl == . | pibeNnac == . | pibeRnac == .
	if r(N) > 0 {
		noisily di as err "PIBDeflactorNL: huecos en PIBE nominal/real. No se exporta."
		exit 459
	}
	g byte tipo = 1							// 1 observado, 2 nowcast ITAEE, 3 proyección geométrica
	tempfile A
	save `A'
}

* Compuerta 2: cifra de control del BIE — PIBE nacional vs PIB del motor (master/PIBDeflactor.dta) *
quietly {
	capture confirm file `"`site'/master/PIBDeflactor.dta"'
	local motor_ok = (_rc == 0)
	local ctrl_txt "sin master/PIBDeflactor.dta en esta máquina: compuerta de control no evaluada"
	if `motor_ok' {
		use anio trimestre pibQ inpc using `"`site'/master/PIBDeflactor.dta"', clear
		collapse (mean) pibQ (count) ntrim = pibQ (last) inpcMotor = inpc, by(anio)
		keep if ntrim == 4
		rename pibQ pibMotor
		tempfile M
		save `M'
		use `A', clear
		merge 1:1 anio using `M', keep(match) nogen
		g double difCtrl = reldif(pibeNnac*1e6, pibMotor)
		summarize difCtrl, meanonly
		local ctrl_max = r(max)
		summarize anio, meanonly
		local ctrl_a0 = r(min)
		local ctrl_a1 = r(max)
		if `ctrl_max' > 0.01 {
			noisily di as err "PIBDeflactorNL: PIBE nacional del BIE difiere del PIB del motor más de 1% (máx `=string(`ctrl_max'*100,"%5.2f")'% en `ctrl_a0'-`ctrl_a1'). No se exporta."
			exit 459
		}
		local ctrl_txt "PIBE nacional corriente (BIE 750453/00) vs PIB anual del motor (promedio de pibQ, master/PIBDeflactor.dta): reldif máx `=string(`ctrl_max'*100,"%5.3f")'% en `ctrl_a0'-`ctrl_a1' (tolerancia 1%)"
		noisily di in g "  Compuerta de control PIB: " in y "PASÓ" in g " (`ctrl_txt')."
	}
	else {
		noisily di in g "  Compuerta de control PIB: " in y "no evaluada" in g " (`ctrl_txt')."
	}
}

*** 3 TRIMESTRAL: ITAEE (original y desestacionalizado) ***
noisily di _newline in g "{bf:3. ITAEE trimestral}"
quietly {
	use `s7', clear
	merge 1:1 anio trimestre using `s8', nogen
	merge 1:1 anio trimestre using `sitaeenac', nogen
	drop if itaeenl == .
	rename selloitaeenl selloITAEEnl
	drop selloitaeeSAnl
	g aniotrim = yq(anio, trimestre)
	format aniotrim %tq
	tsset aniotrim
	count if aniotrim != L.aniotrim + 1 & _n > 1
	if r(N) > 0 {
		noisily di as err "PIBDeflactorNL: huecos en la rejilla trimestral del ITAEE. No se exporta."
		exit 459
	}
	foreach g in nl nac {
		g double yoyITAEE`g' = (itaee`g'/L4.itaee`g' - 1)*100
		g double qoqITAEESA`g' = (itaeeSA`g'/L.itaeeSA`g' - 1)*100
		g double yoyITAEESA`g' = (itaeeSA`g'/L4.itaeeSA`g' - 1)*100
		g double itaeeL4`g' = L4.itaee`g'
	}
	local itaee_a1 = anio[_N]
	local itaee_t1 = trimestre[_N]
	tempfile Q
	save `Q'
	* Nowcast anual: promedio de los trimestres disponibles del año vs los mismos trimestres del año anterior *
	collapse (sum) itaeenl itaeenac itaeeL4nl itaeeL4nac (count) ntrim = itaeenl, by(anio)
	g double nowITAEEnl = (itaeenl/itaeeL4nl - 1)*100 if itaeeL4nl > 0
	g double nowITAEEnac = (itaeenac/itaeeL4nac - 1)*100 if itaeeL4nac > 0
	keep anio ntrim nowITAEEnl nowITAEEnac
	tempfile QA
	save `QA'
}

*** 4 MENSUAL: INPC NL y nacional ***
noisily di _newline in g "{bf:4. INPC mensual}"
quietly {
	use `sinpcnl', clear
	merge 1:1 anio mes using `sinpcnac', nogen
	drop if inpcnl == . & inpcnac == .
	g aniomes = ym(anio, mes)
	format aniomes %tm
	tsset aniomes
	count if aniomes != L.aniomes + 1 & _n > 1
	if r(N) > 0 {
		noisily di as err "PIBDeflactorNL: huecos en la rejilla mensual del INPC. No se exporta."
		exit 459
	}
	foreach g in nl nac {
		g double yoyINPC`g' = (inpc`g'/L12.inpc`g' - 1)*100
	}
	summarize aniomes if inpcnl != ., meanonly
	local inpc_m1 = r(max)
	local inpc_a1 = year(dofm(`inpc_m1'))
	local inpc_mes1 = month(dofm(`inpc_m1'))
	summarize aniomes if inpcnl != . & inpcnac != ., meanonly
	local inpc_m0 = r(min)
	tempfile Mm
	save `Mm'
	* Compuerta 3: INPC nacional del BIE ≈ INPC del motor (último mes de cada trimestre en master/PIBDeflactor.dta) *
	if `motor_ok' {
		use anio trimestre inpc using `"`site'/master/PIBDeflactor.dta"', clear
		keep if inpc != .
		g mes = trimestre*3
		rename inpc inpcMotor
		merge 1:1 anio mes using `Mm', keep(match) nogen keepusing(inpcnac)
		g double d = reldif(inpcMotor, inpcnac)
		summarize d, meanonly
		local inpc_ctrl = r(max)
		local inpc_ctrl_n = r(N)
		if `inpc_ctrl' > 1e-3 {
			noisily di as err "PIBDeflactorNL: INPC nacional del BIE difiere del INPC del motor (reldif máx `inpc_ctrl', tolerancia 1e-3). No se exporta."
			exit 459
		}
		local inpc_ctrl_txt "INPC nacional BIE 910392 vs master/PIBDeflactor.dta (fin de trimestre): reldif máx `=string(`inpc_ctrl',"%9.2e")' en `inpc_ctrl_n' trimestres (tolerancia 1e-3)"
		noisily di in g "  Compuerta INPC vs motor: " in y "PASÓ" in g " (`inpc_ctrl_txt')."
	}
	else {
		local inpc_ctrl_txt "sin master/PIBDeflactor.dta: no evaluada"
	}
	* Anual: promedio (años completos) y dic/dic *
	use `Mm', clear
	g double dicnl = inpcnl if mes == 12
	g double dicnac = inpcnac if mes == 12
	collapse (mean) inpcPromnl = inpcnl inpcPromnac = inpcnac (max) dicnl dicnac (count) nmesnl = inpcnl nmesnac = inpcnac ///
		(last) yoyUltnl = yoyINPCnl yoyUltnac = yoyINPCnac mesUlt = mes, by(anio)
	replace inpcPromnl = . if nmesnl < 12
	replace inpcPromnac = . if nmesnac < 12
	tsset anio
	foreach g in nl nac {
		g double inflProm`g' = (inpcProm`g'/L.inpcProm`g' - 1)*100
		g double inflDD`g' = (dic`g'/L.dic`g' - 1)*100
	}
	keep anio inpcPromnl inpcPromnac dicnl dicnac inflPromnl inflPromnac inflDDnl inflDDnac yoyUltnl yoyUltnac mesUlt nmesnl
	tempfile MA
	save `MA'
	summarize anio if inflDDnl != ., meanonly
	local dd_a0 = r(min)
	local dd_a1 = r(max)
}

*** 5 PANEL ANUAL + PROYECCIÓN (criterios del motor) ***
noisily di _newline in g "{bf:5. Panel anual y proyección a `aniope'}"
quietly {
	use `A', clear
	* Extiende la rejilla hasta aniomax *
	local nadd = `aniomax' - `pibe1'
	if `nadd' > 0 {
		local N0 = _N
		set obs `=_N + `nadd''
		replace anio = `pibe1' + (_n - `N0') if anio == .
		replace tipo = 3 if anio > `pibe1'
	}
	tsset anio
	merge 1:1 anio using `QA', nogen
	merge 1:1 anio using `MA', nogen
	keep if anio >= `pibe0' & anio <= `aniomax'
	sort anio

	* Promedios geométricos (ventana completa observada = default geopib/geodef del motor) *
	foreach g in nl nac {
		local geoC`g' = ((pibeR`g'[`=`pibe1'-`pibe0'+1']/pibeR`g'[1])^(1/(`pibe1'-`pibe0')) - 1)*100
		local geoD`g' = ((defl`g'[`=`pibe1'-`pibe0'+1']/defl`g'[1])^(1/(`pibe1'-`pibe0')) - 1)*100
		summarize dic`g' if anio == `dd_a0' - 1, meanonly
		local d0 = r(mean)
		summarize dic`g' if anio == `dd_a1', meanonly
		local geoI`g' = ((r(mean)/`d0')^(1/(`dd_a1' - `dd_a0' + 1)) - 1)*100
	}

	* Proyección año por año: nowcast ITAEE si hay trimestres; si no, geométrico *
	g str24 tipoCrec = "observado" if tipo == 1
	g str24 tipoDefl = "observado" if tipo == 1
	g str24 tipoInfl = "observado" if inflDDnl != .
	forvalues a = `=`pibe1'+1'/`aniomax' {
		foreach g in nl nac {
			summarize nowITAEE`g' if anio == `a', meanonly
			if r(N) > 0 & r(mean) != . {
				replace crecPIBE`g' = nowITAEE`g' if anio == `a'
				replace tipoCrec = "nowcast ITAEE" if anio == `a'
				replace tipo = 2 if anio == `a' & "`g'" == "nl"
			}
			else {
				replace crecPIBE`g' = `geoC`g'' if anio == `a'
				replace tipoCrec = "proyección geométrica" if anio == `a'
			}
			replace varDefl`g' = `geoD`g'' if anio == `a'
			replace tipoDefl = "proyección geométrica" if anio == `a'
			replace pibeR`g' = L.pibeR`g'*(1 + crecPIBE`g'/100) if anio == `a'
			replace defl`g' = L.defl`g'*(1 + varDefl`g'/100) if anio == `a'
			replace pibeN`g' = pibeR`g'*defl`g'/100 if anio == `a'
		}
		replace partPIBEnl = pibeNnl/pibeNnac*100 if anio == `a'
	}
	forvalues a = `=`dd_a1'+1'/`aniomax' {
		foreach g in nl nac {
			replace inflDD`g' = `geoI`g'' if anio == `a'
			replace dic`g' = L.dic`g'*(1 + inflDD`g'/100) if anio == `a'
		}
		replace tipoInfl = "proyección geométrica" if anio == `a'
	}
	* Deflactor base aniovp = 1 (criterio del motor) y poder adquisitivo *
	foreach g in nl nac {
		summarize defl`g' if anio == `anioref', meanonly
		g double deflator`g' = defl`g'/r(mean)
		summarize dic`g' if anio == `anioref', meanonly
		g double deflatorpp`g' = dic`g'/r(mean)
	}
	g double difCrec = crecPIBEnl - crecPIBEnac
	g double difDefl = varDeflnl - varDeflnac
	g double difInflDD = inflDDnl - inflDDnac
	g double difInflProm = inflPromnl - inflPromnac
	tempfile P
	save `P'
}

*** 6 ESCALARES DEL CANAL ***
quietly {
	use `P', clear
	escalar anio anioPIBEult = `pibe1'
	escalar anio anioPE = `aniope'
	escalar anio anioVP = `anioref'
	foreach g in nl nac {
		local G = cond("`g'" == "nl", "nl", "nac")
		local G2 = cond("`g'" == "nl", "NL", "Nac")
		summarize crecPIBE`g' if anio == `pibe1', meanonly
		escalar pct crecPIBE`G' = r(mean)
		summarize varDefl`g' if anio == `pibe1', meanonly
		escalar pct defPIBE`G' = r(mean)
		summarize pibeN`g' if anio == `pibe1', meanonly
		escalar mxn pibeN`G' = r(mean)*1e6
		summarize pibeR`g' if anio == `pibe1', meanonly
		escalar mxn pibeR`G' = r(mean)*1e6
		summarize crecPIBE`g' if anio == `aniope', meanonly
		escalar pct crecPIBE`G'PE = r(mean)
		summarize varDefl`g' if anio == `aniope', meanonly
		escalar pct defPIBE`G'PE = r(mean)
		summarize inflDD`g' if anio == `aniope', meanonly
		escalar pct inflacion`G2'ddPE = r(mean)
		summarize inflDD`g' if anio == `dd_a1', meanonly
		escalar pct inflacion`G2'dd = r(mean)
		summarize inflProm`g' if anio == `dd_a1', meanonly
		escalar pct inflacion`G2'prom = r(mean)
		summarize deflator`g' if anio == `pibe1', meanonly
		escalar custom(%8.4f) deflatorPIBE`G' = r(mean)
		escalar pct crecPIBE`G'geo = `geoC`g''
		escalar pct defPIBE`G'geo = `geoD`g''
		escalar pct inflacion`G2'geo = `geoI`g''
	}
	summarize partPIBEnl if anio == `pibe1', meanonly
	escalar pct partPIBEnl = r(mean)
	escalar pct difCrecPIBEnl = scalar(crecPIBEnl) - scalar(crecPIBEnac)
	escalar pct difDefPIBEnl = scalar(defPIBEnl) - scalar(defPIBEnac)
	escalar pct difInflacionNLdd = scalar(inflacionNLdd) - scalar(inflacionNacdd)
	escalar anio anioInflDDult = `dd_a1'
	* Nowcast anual del año en curso (último año con ITAEE) *
	summarize nowITAEEnl if anio == `itaee_a1', meanonly
	escalar pct nowITAEEnl = r(mean)
	summarize nowITAEEnac if anio == `itaee_a1', meanonly
	escalar pct nowITAEEnac = r(mean)
	summarize ntrim if anio == `itaee_a1', meanonly
	escalar custom(%1.0f) nowITAEEtrim = r(mean)
	escalar anio anioITAEEult = `itaee_a1'
	escalar custom(%1.0f) trimITAEEult = `itaee_t1'

	use `Q', clear
	foreach g in nl nac {
		local G = cond("`g'" == "nl", "nl", "nac")
		escalar pct crecITAEE`G' = yoyITAEE`g'[_N]
		escalar pct crecITAEEsaQ`G' = qoqITAEESA`g'[_N]
		escalar pct crecITAEEsaY`G' = yoyITAEESA`g'[_N]
	}
	escalar pct difCrecITAEEnl = scalar(crecITAEEnl) - scalar(crecITAEEnac)

	use `Mm', clear
	escalar anio anioINPCult = `inpc_a1'
	escalar custom(%2.0f) mesINPCult = `inpc_mes1'
	summarize yoyINPCnl if aniomes == `inpc_m1', meanonly
	escalar pct inflacionNLvig = r(mean)
	summarize yoyINPCnac if aniomes == `inpc_m1', meanonly
	escalar pct inflacionNacvig = r(mean)
	escalar pct difInflacionNLvig = scalar(inflacionNLvig) - scalar(inflacionNacvig)
	summarize inpcnl if aniomes == `inpc_m1', meanonly
	escalar custom(%9.3f) inpcNLult = r(mean)
	summarize inpcnac if aniomes == `inpc_m1', meanonly
	escalar custom(%9.3f) inpcNacult = r(mean)
}

noisily di _newline in g "  PIBE `pibe1': NL " in y %5.2f scalar(crecPIBEnl) in g " % real (nacional " in y %5.2f scalar(crecPIBEnac) in g " %); deflactor NL " in y %5.2f scalar(defPIBEnl) in g " %; participación NL " in y %5.2f scalar(partPIBEnl) in g " %"
noisily di in g "  ITAEE `itaee_a1'T`itaee_t1': NL " in y %5.2f scalar(crecITAEEnl) in g " % a/a (nacional " in y %5.2f scalar(crecITAEEnac) in g " %); nowcast anual `itaee_a1' NL " in y %5.2f scalar(nowITAEEnl) in g " % (" %1.0f scalar(nowITAEEtrim) " trim.)"
noisily di in g "  INPC `inpc_a1'/`inpc_mes1': inflación NL " in y %5.2f scalar(inflacionNLvig) in g " % a/a (nacional " in y %5.2f scalar(inflacionNacvig) in g " %); dic/dic `dd_a1' NL " in y %5.2f scalar(inflacionNLdd) in g " %"
noisily di in g "  Proyección `aniope' (NL): crecimiento " in y %5.2f scalar(crecPIBEnlPE) in g " %, deflactor " in y %5.2f scalar(defPIBEnlPE) in g " %, inflación dic/dic " in y %5.2f scalar(inflacionNLddPE) in g " %"

*** 7 JSON ***
noisily di _newline in g "{bf:7. JSON}"
local json `"`site'/users/$id/nodos/actividad-nl.json"'
local sello = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
tempname fh
file open `fh' using `"`json'"', write replace text
file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'nl.actividad/v1`q',"' _n
file write `fh' `"  `q'producto`q': `q'`nl_producto'`q',"' _n
file write `fh' `"  `q'titulo`q': `q'`nl_titulo'`q',"' _n
file write `fh' `"  `q'subtitulo`q': `q'`nl_subtitulo'`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
file write `fh' `"  `q'anio_politica`q': `aniope',"' _n
file write `fh' `"  `q'procedencia`q': {"' _n
file write `fh' `"    `q'version_motor`q': `q'`nl_vmotor'`q',"' _n
file write `fh' `"    `q'version_capa_nl`q': `q'`nl_vnl'`q',"' _n
file write `fh' `"    `q'driver`q': `q'01_modulos/PIBDeflactorNL.do v1.0.0`q',"' _n
file write `fh' `"    `q'log`q': `q'`logfile'`q',"' _n
file write `fh' `"    `q'generado_en`q': `q'`sello'`q',"' _n
file write `fh' `"    `q'frontera`q': `q'sidecar macro: contexto, nowcast y deflactación de entregables NL; no recalibra la base micro ni introduce reajuste contra el PIBE`q',"' _n
file write `fh' `"    `q'compuertas`q': {"' _n
file write `fh' `"      `q'deflactor_implicito`q': `q'nominal/real reproduce el índice de precios implícitos del BIE (753357) en todos los años, reldif < 1e-6`q',"' _n
file write `fh' `"      `q'control_pib`q': `q'`ctrl_txt'`q',"' _n
file write `fh' `"      `q'inpc_vs_motor`q': `q'`inpc_ctrl_txt'`q',"' _n
file write `fh' `"      `q'rejillas`q': `q'anual PIBE, trimestral ITAEE y mensual INPC sin huecos (tsset verificado)`q'"' _n
file write `fh' "    }," _n
file write `fh' `"    `q'criterios_motor`q': `q'PIBDeflactor.ado: INPC anual = diciembre (dic/dic); deflactor base aniovp = 1; proyección = exógeno si existe, si no promedio geométrico desde el inicio de la serie (geopib/geodef = anioinicial); nominal = real x deflactor`q',"' _n
file write `fh' `"    `q'supuestos_proyeccion`q': {"' _n
file write `fh' `"      `q'crecimiento`q': `q'años con ITAEE: nowcast = promedio de los trimestres disponibles vs mismos trimestres del año anterior (serie original); años sin dato: promedio geométrico del PIBE real `pibe0'-`pibe1' (NL `=string(`geoCnl',"%5.2f")' %, nacional `=string(`geoCnac',"%5.2f")' %)`q',"' _n
file write `fh' `"      `q'deflactor`q': `q'promedio geométrico del deflactor implícito `pibe0'-`pibe1' (NL `=string(`geoDnl',"%5.2f")' %, nacional `=string(`geoDnac',"%5.2f")' %)`q',"' _n
file write `fh' `"      `q'inflacion`q': `q'dic/dic: promedio geométrico `dd_a0'-`dd_a1' (NL `=string(`geoInl',"%5.2f")' %, nacional `=string(`geoInac',"%5.2f")' %); el año en curso se reporta con el último mes observado (a/a), no se proyecta`q',"' _n
file write `fh' `"      `q'sin_exogeno_estatal`q': `q'no existe CGPE estatal; el comparativo nacional de este driver usa el mismo criterio (el motor, en SIM.do, usa los globales pib/def/inf del CGPE)`q'"' _n
file write `fh' "    }," _n
file write `fh' `"    `q'series`q': ["' _n
forvalues k = 1/`nfuentes' {
	local tt `"`f`k'_titulo'"'
	local tt = subinstr(`"`tt'"', char(34), "'", .)
	local tt = subinstr(`"`tt'"', char(92), "/", .)
	file write `fh' `"      {`q'id`q': `q'`f`k'_id'`q', `q'area`q': `q'`f`k'_area'`q', `q'variable`q': `q'`f`k'_var'`q', `q'fuente`q': `q'`f`k'_fuente'`q', `q'titulo`q': `q'`tt'`q', `q'consulta`q': `q'`f`k'_fecha'`q', `q'ultimo`q': `q'`f`k'_ultimo'`q', `q'sello_ultimo`q': `q'`f`k'_sello'`q', `q'n`q': `f`k'_n', `q'checksum`q': `f`k'_chk'}`=cond(`k' < `nfuentes', ",", "")'"' _n
}
file write `fh' "    ]" _n
file write `fh' "  }," _n
file write `fh' `"  `q'definiciones`q': {"' _n
file write `fh' `"    `q'pibe`q': `q'PIBE a precios de mercado, millones de pesos corrientes y millones de pesos de 2018 (INEGI, SCNM base 2018)`q',"' _n
file write `fh' `"    `q'deflactor`q': `q'índice de precios implícitos del PIBE = nominal/real x 100 (2018 = 100): mide precios de la PRODUCCIÓN estatal, no del consumo`q',"' _n
file write `fh' `"    `q'itaee`q': `q'índice de volumen físico 2018 = 100; serie original (variación anual) y desestacionalizada (variación trimestral); es un adelanto preliminar del PIBE. Comparativo nacional = PIB trimestral real (734407/735143) normalizado 2018 = 100; el BIE no publica total nacional del ITAEE ni, por tanto, su serie desestacionalizada aquí`q',"' _n
file write `fh' `"    `q'inpc`q': `q'INPC base 2Q jul 2018 = 100; NL por entidad federativa (programa INPC de INEGI); inflación anual = promedio anual y dic/dic; vigente = último mes a/a: mide precios del CONSUMO`q',"' _n
file write `fh' `"    `q'tipo`q': {`q'observado`q': `q'dato publicado por INEGI`q', `q'nowcast ITAEE`q': `q'preliminar: estimado con los trimestres disponibles del ITAEE`q', `q'proyección geométrica`q': `q'supuesto de la capa NL con el criterio del motor`q'},"' _n
file write `fh' `"    `q'sellos_inegi`q': `q'sello de revisión de INEGI por observación tal como viene del BIE: p = cifra preliminar, r = cifra revisada (p1, r1, ...); vacío = definitiva`q'"' _n
file write `fh' "  }," _n
file write `fh' `"  `q'presentacion`q': {"' _n
file write `fh' `"    `q'criterio_proyeccion`q': `q'sin exógenos CGPE estatales: la proyección NL usa el nowcast ITAEE donde hay trimestres y después el promedio geométrico del motor (PIBDeflactor.ado, geopib/geodef = anioinicial); el comparativo nacional de este endpoint sigue el mismo criterio`q',"' _n
file write `fh' `"    `q'frontera`q': `q'sidecar macro: contexto, nowcast y deflactación de entregables NL; no recalibra la base micro`q',"' _n
file write `fh' `"    `q'lectura_sellos`q': `q'PIBE con sello r1 = cifra revisada sujeta a nueva revisión; ITAEE con sello p1 = preliminar`q'"' _n
file write `fh' "  }," _n

** 7.1 Cifras (escalares vivos) **
file write `fh' `"  `q'cifras`q': {"' _n
local lista anioPIBEult anioPE anioVP anioITAEEult trimITAEEult nowITAEEtrim anioINPCult mesINPCult anioInflDDult ///
	crecPIBEnl crecPIBEnac difCrecPIBEnl defPIBEnl defPIBEnac difDefPIBEnl pibeNnl pibeRnl pibeNnac pibeRnac partPIBEnl ///
	deflatorPIBEnl deflatorPIBEnac crecPIBEnlgeo crecPIBEnacgeo defPIBEnlgeo defPIBEnacgeo inflacionNLgeo inflacionNacgeo ///
	crecPIBEnlPE crecPIBEnacPE defPIBEnlPE defPIBEnacPE inflacionNLddPE inflacionNacddPE ///
	nowITAEEnl nowITAEEnac crecITAEEnl crecITAEEnac difCrecITAEEnl crecITAEEsaQnl crecITAEEsaQnac crecITAEEsaYnl crecITAEEsaYnac ///
	inflacionNLvig inflacionNacvig difInflacionNLvig inflacionNLdd inflacionNacdd difInflacionNLdd inflacionNLprom inflacionNacprom inpcNLult inpcNacult
local n : word count `lista'
local j = 0
foreach s of local lista {
	local ++j
	_nlnum "scalar(`s')"
	file write `fh' `"    `q'`s'`q': `r(n)',"' _n
}
* Sellos de revisión INEGI del último dato (texto: no son escalares numéricos) *
local kP = 1
local kI = 7
file write `fh' `"    `q'selloPIBEult`q': `q'`f`kP'_sello'`q',"' _n
file write `fh' `"    `q'selloITAEEult`q': `q'`f`kI'_sello'`q'"' _n
file write `fh' "  }," _n

** 7.2 Series: anual **
quietly use `P', clear
file write `fh' `"  `q'anual`q': ["' _n
local vars pibeNnl pibeRnl deflnl crecPIBEnl varDeflnl deflatornl pibeNnac pibeRnac deflnac crecPIBEnac varDeflnac deflatornac partPIBEnl difCrec difDefl nowITAEEnl nowITAEEnac ntrim inpcPromnl inpcPromnac dicnl dicnac inflPromnl inflPromnac inflDDnl inflDDnac difInflDD difInflProm
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'tipoCrec`q': `q'`=tipoCrec[`i']'`q', `q'tipoDefl`q': `q'`=tipoDefl[`i']'`q', `q'tipoInfl`q': `q'`=cond(tipoInfl[`i']=="", "sin dato", tipoInfl[`i'])'`q', `q'selloPIBEnl`q': `q'`=selloPIBEnl[`i']'`q', `q'selloPIBEnac`q': `q'`=selloPIBEnac[`i']'`q'"'
	foreach v of local vars {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

** 7.3 Series: trimestral ITAEE **
quietly use `Q', clear
file write `fh' `"  `q'trimestral`q': ["' _n
local vars itaeenl itaeenac itaeeSAnl itaeeSAnac yoyITAEEnl yoyITAEEnac qoqITAEESAnl qoqITAEESAnac yoyITAEESAnl yoyITAEESAnac
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'trimestre`q': `=trimestre[`i']', `q'selloITAEEnl`q': `q'`=selloITAEEnl[`i']'`q'"'
	foreach v of local vars {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]," _n

** 7.4 Series: mensual INPC (desde que existe el INPC NL) **
quietly {
	use `Mm', clear
	keep if aniomes >= `inpc_m0' - 12
}
file write `fh' `"  `q'mensual`q': ["' _n
local vars inpcnl inpcnac yoyINPCnl yoyINPCnac
forvalues i = 1/`=_N' {
	file write `fh' `"    {`q'anio`q': `=anio[`i']', `q'mes`q': `=mes[`i']'"'
	foreach v of local vars {
		_nlnum "`v'[`i']"
		file write `fh' `", `q'`v'`q': `r(n)'"'
	}
	file write `fh' "}`=cond(`i' < _N, ",", "")'" _n
}
file write `fh' "  ]" _n
file write `fh' "}" _n
file close `fh'

*** 8 HTML AUTOCONTENIDO ***
local tpl `"`site'/01_modulos/nl-assets/actividad-nl.html"'
local html `"`site'/users/$id/nodos/actividad-nl.html"'
capture confirm file `"`tpl'"'
if _rc {
	di as err "PIBDeflactorNL: falta la plantilla 01_modulos/nl-assets/actividad-nl.html."
	exit 601
}
run `"`site'/01_modulos/nl-assets/nl-html.do"'
local js `"`site'/01_modulos/nl-assets/nl-datos.js"'
capture confirm file `"`js'"'
if _rc {
	di as err "PIBDeflactorNL: falta el componente 01_modulos/nl-assets/nl-datos.js."
	exit 601
}
mata: nlhtml_inject(st_local("tpl"), st_local("json"), st_local("js"), st_local("html"), "/*__NLACT_DATA__*/")
if r(hits_data) != 1 | r(hits_js) != 1 {
	di as err "PIBDeflactorNL: la plantilla debe tener exactamente una marca /*__NLACT_DATA__*/ y una /*__NL_DATOS_JS__*/ (encontradas: `r(hits_data)' y `r(hits_js)')."
	exit 459
}

*** 9 RESUMEN ***
quietly checksum `"`html'"'
local kb = string(r(filelen)/1024, "%9.0fc")
noisily di _newline in g "{bf:PIBDeflactorNL: listo.}"
noisily di in g "  JSON: " in y `"`json'"'
noisily di in g "  HTML: " in y `"`html'"' in g " (`kb' KB)"
noisily di in g "  `nl_titulo' — `nl_subtitulo' · capa `nl_vnl' · PIBE hasta `pibe1' · ITAEE `itaee_a1'T`itaee_t1' · INPC `inpc_a1'/`inpc_mes1'"
quietly log close nlact
