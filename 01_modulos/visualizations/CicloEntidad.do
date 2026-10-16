*********************************
*** CICLO DE VIDA DE UNA ENTIDAD ***
*********************************
* CicloEntidad.do — v1.0 (2026-10-11). Datos de la gráfica "La carga fiscal por edades" del
* sitio nacional (Simulador.ado §5.1 poblaciongini → graphpiramide → familias APORTHIV, APORTHVIIX,
* APORTHX, APORTMIV, APORTMVIIX, APORTMX de output.txt), FILTRADOS a una entidad federativa.
* Unificación, no invención: la definición es la del nacional y aquí no se rediseña.
*
* Llamada (SIM.do §8.2, solo dentro de if "$entidad" != ""):
*   run CicloEntidad.do <anioPE> "<entidad>"
* Con el global vacío SIM.do no llega a esta línea: cero efecto en la corrida nacional.
*
* DEFINICIÓN HEREDADA (SIM.do §7.1–7.3; Simulador.ado):
*   neto   = AportacionesNetas = ImpuestosAportaciones − Transferencias, por persona, [fw=factor]
*   aporta = ImpuestosAportaciones = ISRPM + ISRAS + ISRPF + CUOTAS + IVA + IEPSNP + IEPSP + ISAN + IMPORT
*            (variables *_Sim; NO entran FMP_Sim ni OTROSK_Sim)
*   recibe = Transferencias = Pensiones (ya con Pensión_AM, §7.2) + IngBasico + Educacion + Salud
*            + OtrasInversiones (NO entran OtrosGastos ni Energia)
*   celda  = quinquenio de edad (0-4, 5-9, …, 105-109, 110+) × sexo × grupo de deciles NACIONALES
*            (Deciles I-V, VI-IX, X), como graphpiramide (grupo_edad 1..23 y over 1..3)
*   unidad nacional = porcentaje del TOTAL NACIONAL de aportaciones netas: Σ de las 132 celdas
*            = 100 (graphpiramide: POR = neto/Σneto*100; output.txt lo escribe con %8.3f, del
*            quinquenio más alto al más bajo, un vector por sexo × grupo)
*   valor presente: Simulador.ado divide la variable por el deflactor de anioPE respecto a anioVP
*            ANTES de guardar aportaciones.dta (la variable ya viene en pesos de anioVP; con
*            anioVP = anioPE el deflactor es 1). aporta y recibe se deflactan aquí con el mismo
*            cociente para que neto = aporta − recibe se cumpla también cuando anioVP != anioPE.
*
* SALIDA: users/$id/<ABREV>/ciclo-vida.json (JSON plano, no script FusionCharts), con:
*   totales (entidad y nacional), parámetros, procedencia y, por celda quinquenio × sexo:
*     n      personas de la MUESTRA de la entidad en la celda (sin ponderar)
*     pob    población expandida (Σ factor)
*     aporta, recibe, neto   pesos de anioVP (Σ variable × factor)
*     pct    % del neto total de la ENTIDAD (Σ celdas = 100)
*     pct_nac % del neto total NACIONAL (Σ de las 32 entidades, celda a celda = APORT* del output.txt)
*     top1_aporta, top1_recibe  % del aporta (del recibe) de la celda que pone UNA sola persona
*     sello  1 si n < 100 o top1_* > 25 %: regla P5 de SankeySF.do; la celda se DECLARA
*            delgada o concentrada, no se suaviza
*     grupos desglose por grupo de deciles (mismos campos, sin top1)
*   La rejilla es completa (23 quinquenios × 2 sexos × grupos): las celdas sin muestra van con
*   n = 0 y ceros, nunca se omiten (sin huecos silenciosos).
*
* Series: grupos de deciles NACIONALES I-V / VI-IX / X, como el nacional (local grupos = "decil";
* el código conserva "quintil" = quintil ESTATAL y "ninguno" = una sola serie por si se decide
* cambiar). Sellos: n < 100 personas por celda quinquenio × sexo, top1 > 25 %.
* FLAGs abiertos (CHANGELOG Unreleased): definición de n, nombre del archivo.

timer on 12
local anio = `1'
local entidad : subinstr local 2 `"""' "", all		// el argumento de un do-file llega con sus comillas
local entidad = trim(`"`entidad'"')
if `"`entidad'"' == "" {
	di as err "CicloEntidad: falta la entidad. SIM.do §8.2 lo llama solo con global entidad definido."
	exit 198
}
SIMentidad `"`entidad'"'
local enombre `"`r(nombre)'"'
local eclave "`r(clave)'"
local eabrev "`r(abrev)'"
local sello_n = 100
local sello_top1 = 25
local grupos "decil"

quietly {
	***********************************************************
	*** 1 Deflactor anioVP → anioPE (como Simulador.ado §0.1) ***
	PIBDeflactor, anio(`=aniovp') nographs nooutput
	local deflator = .
	local pibY = .
	forvalues k = 1(1)`=_N' {
		if anio[`k'] == `anio' {
			local deflator = deflator[`k']
			local pibY = pibY[`k']
			continue, break
		}
	}
	if `deflator' == . {
		noisily di as err "CicloEntidad: PIBDeflactor no trae el año `anio'."
		exit 198
	}


	*******************************************************
	*** 2 Base: la misma del nacional (aportaciones.dta) ***
	use folioviv foliohog factor sexo edad decil ingbrutotot ///
		AportacionesNetas ImpuestosAportaciones Transferencias ///
		using `"${SIMROOT}/users/$id/aportaciones.dta"', clear

	capture confirm string variable sexo
	if _rc == 0 {
		g byte sexon = real(sexo)
	}
	else {
		g byte sexon = sexo
	}
	g double w_neto = AportacionesNetas*factor						// ya en pesos de anioVP (Simulador.ado)
	g double w_ap = ImpuestosAportaciones/`deflator'*factor
	g double w_re = Transferencias/`deflator'*factor

	* Totales nacionales (base completa, sin filtrar) *
	summarize w_neto, meanonly
	local netonac = r(sum)
	summarize factor, meanonly
	local pobnac = r(sum)
	local nnac = _N

	* Quinquenio: grupo_edad 1..23 de graphpiramide (edad 110+ = 23) *
	g byte q = min(floor(edad/5), 22) + 1
	local qlabs ""
	forvalues k = 1/22 {
		local qlabs `"`qlabs' `k' "`=(`k'-1)*5'-`=(`k'-1)*5+4'""'
	}
	label define q `qlabs' 23 "110+"
	label values q q

	* Grupos (series apiladas de la gráfica) *
	if "`grupos'" == "decil" {
		g byte grp = cond(decil <= 5, 1, cond(decil < 10, 2, 3))
		label define grp 1 "Deciles I-V" 2 "VI-IX" 3 "X"
		local ngrp = 3
		local grptit "Deciles nacionales de ingreso (los del motor, como el nacional)"
	}
	if "`grupos'" == "ninguno" {
		g byte grp = 1
		label define grp 1 "Total"
		local ngrp = 1
		local grptit "Sin desglose"
	}


	******************************
	*** 3 Filtro a la entidad ***
	keep if substr(folioviv, 1, 2) == "`eclave'"
	if _N == 0 {
		noisily di as err "CicloEntidad: la ENIGH no trae observaciones de `enombre' (clave `eclave')."
		exit 2000
	}
	if "`grupos'" == "quintil" {
		* re-ranking ESTATAL con el criterio de SankeySF.do (_SFentidad, P2 = Households.do §12) *
		tempvar toti ingh ingpc wh
		egen `toti' = count(edad), by(folioviv foliohog)
		egen double `ingh' = total(ingbrutotot), by(folioviv foliohog)
		g double `ingpc' = `ingh'/`toti'
		g double `wh' = factor/`toti'
		xtile grp = `ingpc' [pw=`wh'], n(5)
		label define grp 1 "Quintil I" 2 "II" 3 "III" 4 "IV" 5 "V"
		local ngrp = 5
		local grptit "Quintiles estatales de ingreso (re-ranking dentro de la entidad, regla P2)"
	}
	label values grp grp

	summarize w_neto, meanonly
	local netoent = r(sum)
	summarize w_ap, meanonly
	local apent = r(sum)
	summarize w_re, meanonly
	local reent = r(sum)
	summarize factor, meanonly
	local pobent = r(sum)
	local nent = _N
	count if AportacionesNetas == 0
	local nceros = r(N)


	*************************************************
	*** 4 Celdas quinquenio × sexo × grupo (rejilla completa) ***
	g byte one = 1
	* concentración por celda quinquenio × sexo (regla P5 de SankeySF.do): % del flujo de la celda que
	* aporta UNA sola persona, en el lado aporta y en el lado recibe (el neto es signado: no se usa) *
	tempvar mxap mxre sap sre
	egen double `mxap' = max(w_ap), by(sexon q)
	egen double `mxre' = max(w_re), by(sexon q)
	egen double `sap' = total(w_ap), by(sexon q)
	egen double `sre' = total(w_re), by(sexon q)
	g double top1_ap = cond(`sap' != 0, `mxap'/`sap'*100, 0)
	g double top1_re = cond(`sre' != 0, `mxre'/`sre'*100, 0)
	collapse (sum) n=one pob=factor ap=w_ap re=w_re neto=w_neto (max) top1_ap top1_re, by(sexon q grp)
	tempfile celdas
	save `celdas'

	clear
	set obs `=23*2*`ngrp''
	g byte sexon = 1 + mod(_n-1, 2)
	g byte q = 1 + mod(floor((_n-1)/2), 23)
	g byte grp = 1 + floor((_n-1)/46)
	merge 1:1 sexon q grp using `celdas', nogen keep(master match)
	foreach v in n pob ap re neto top1_ap top1_re {
		replace `v' = 0 if `v' == .
	}
	label values q q
	label values grp grp
	label define sexon 1 "Hombres" 2 "Mujeres"
	label values sexon sexon
	g double pct = cond(`netoent' != 0, neto/`netoent'*100, .)
	g double pct_nac = cond(`netonac' != 0, neto/`netonac'*100, .)
	egen long n_celda = total(n), by(sexon q)
	egen double pob_celda = total(pob), by(sexon q)
	egen double ap_celda = total(ap), by(sexon q)
	egen double re_celda = total(re), by(sexon q)
	egen double neto_celda = total(neto), by(sexon q)
	egen double top1ap_celda = max(top1_ap), by(sexon q)		// top1_* es constante dentro de la celda (se calculó antes del collapse)
	egen double top1re_celda = max(top1_re), by(sexon q)
	g byte sello = (n_celda < `sello_n') | (top1ap_celda > `sello_top1') | (top1re_celda > `sello_top1')
	sort sexon q grp

	count if sello & grp == 1
	local nsellos = r(N)
	count if n_celda == 0 & grp == 1
	local nvacias = r(N)


	********************
	*** 5 JSON ***
	local dest `"${SIMROOT}/users/$id/`eabrev'"'
	capture mkdir `"`dest'"'
	local json `"`dest'/ciclo-vida.json"'
	local f2 "%20.2f"
	local f6 "%14.6f"
	local f0 "%14.0f"
	local fd "%12.8f"
	local fecha : di %tdCCYY-NN-DD date("$S_DATE", "DMY")
	local fecha = trim("`fecha'")
	local hora "$S_TIME"
	local enombrej : subinstr local enombre `"""' "" , all

	tempname fh
	file open `fh' using `"`json'"', write replace text
	file write `fh' `"{"esquema":"ciclo-vida/v1","entidad":{"nombre":"`enombrej'","clave":"`eclave'","abrev":"`eabrev'"},"' _n
	file write `fh' `""anio_politica":`anio',"anio_vp":`=aniovp',"paquete":"$paqueteEconomico","anio_enigh":`=anioenigh',"' _n
	file write `fh' `""definicion":{"grafica":"La carga fiscal por edades (Simulador.ado graphpiramide; output.txt APORTHIV, APORTHVIIX, APORTHX, APORTMIV, APORTMVIIX, APORTMX)","' _n
	file write `fh' `""neto":"AportacionesNetas = ImpuestosAportaciones - Transferencias, por persona, ponderado por factor (SIM.do 7.3)","' _n
	file write `fh' `""aporta":"ImpuestosAportaciones = ISRPM_Sim + ISRAS_Sim + ISRPF_Sim + CUOTAS_Sim + IVA_Sim + IEPSNP_Sim + IEPSP_Sim + ISAN_Sim + IMPORT_Sim (SIM.do 7.1; sin FMP ni OTROSK)","' _n
	file write `fh' `""recibe":"Transferencias = Pensiones (con Pension_AM) + IngBasico + Educacion + Salud + OtrasInversiones (SIM.do 7.2; sin OtrosGastos ni Energia)","' _n
	file write `fh' `""celda":"quinquenio de edad (grupo_edad 1..23: 0-4 ... 105-109, 110+) x sexo x grupo","' _n
	file write `fh' `""unidad_nacional":"pct_nac = % del total nacional de aportaciones netas; la suma de las 32 entidades celda a celda reproduce APORT* del output.txt (alli con %8.3f, del quinquenio mas alto al mas bajo)","' _n
	file write `fh' `""unidad_entidad":"pct = % del total de aportaciones netas de la entidad (suma de celdas = 100); pesos = pesos de anio_vp","' _n
	file write `fh' `""orden_nacional":"descendente (105-109 ... 0-4); aqui ascendente","' _n
	file write `fh' `""deflactor":`=trim(string(`deflator', "`fd'"))',"nota_deflactor":"AportacionesNetas ya viene dividida por este deflactor en aportaciones.dta (Simulador.ado); aporta y recibe se dividen aqui"},"' _n
	file write `fh' `""parametros":{"entidad_ciclo_grupos":"`grupos'","sello_n":`sello_n',"sello_top1":`sello_top1',"regla_sello":"por celda quinquenio x sexo: n (personas de la muestra de la entidad) < sello_n, o una sola persona aporta mas de sello_top1 % del aporta o del recibe de la celda (regla P5 de SankeySF.do)"},"' _n
	file write `fh' `""grupos":{"titulo":"`grptit'","etiquetas":["'
	forvalues g = 1/`ngrp' {
		local gl : label grp `g'
		file write `fh' `"`=cond(`g' > 1, ",", "")'"`gl'""'
	}
	file write `fh' `"]},"' _n
	file write `fh' `""quinquenios":["'
	forvalues k = 1/23 {
		local ql : label q `k'
		file write `fh' `"`=cond(`k' > 1, ",", "")'"`ql'""'
	}
	file write `fh' `"],"' _n
	file write `fh' `""totales":{"entidad":{"n":`nent',"n_neto_cero":`nceros',"pob":`=trim(string(`pobent', "`f0'"))',"aporta":`=trim(string(`apent', "`f2'"))',"recibe":`=trim(string(`reent', "`f2'"))',"neto":`=trim(string(`netoent', "`f2'"))',"celdas_con_sello":`nsellos',"celdas_vacias":`nvacias'},"' _n
	file write `fh' `""nacional":{"n":`nnac',"pob":`=trim(string(`pobnac', "`f0'"))',"neto":`=trim(string(`netonac', "`f2'"))',"pibY":`=trim(string(`pibY', "`f2'"))',"share_pob":`=trim(string(`pobent'/`pobnac', "`fd'"))',"share_neto":`=trim(string(cond(`netonac' != 0, `netoent'/`netonac', .), "`fd'"))'}},"' _n
	file write `fh' `""celdas":["' _n
	local first = 1
	forvalues s = 1/2 {
		local sl : label sexon `s'
		forvalues k = 1/23 {
			local ql : label q `k'
			summarize n_celda if sexon == `s' & q == `k', meanonly
			local nc = r(mean)
			summarize pob_celda if sexon == `s' & q == `k', meanonly
			local pc = r(mean)
			summarize ap_celda if sexon == `s' & q == `k', meanonly
			local ac = r(mean)
			summarize re_celda if sexon == `s' & q == `k', meanonly
			local rc = r(mean)
			summarize neto_celda if sexon == `s' & q == `k', meanonly
			local xc = r(mean)
			summarize sello if sexon == `s' & q == `k', meanonly
			local sc = r(mean)
			summarize top1ap_celda if sexon == `s' & q == `k', meanonly
			local t1a = r(mean)
			summarize top1re_celda if sexon == `s' & q == `k', meanonly
			local t1r = r(mean)
			local pctc = cond(`netoent' != 0, `xc'/`netoent'*100, .)
			local pctn = cond(`netonac' != 0, `xc'/`netonac'*100, .)
			file write `fh' `"`=cond(`first', "", ",")'{"sexo":"`sl'","s":`s',"g":`k',"quinquenio":"`ql'","n":`=trim(string(`nc', "`f0'"))',"pob":`=trim(string(`pc', "`f0'"))',"aporta":`=trim(string(`ac', "`f2'"))',"recibe":`=trim(string(`rc', "`f2'"))',"neto":`=trim(string(`xc', "`f2'"))',"pct":`=trim(string(`pctc', "`f6'"))',"pct_nac":`=trim(string(`pctn', "`f6'"))',"top1_aporta":`=trim(string(`t1a', "`f6'"))',"top1_recibe":`=trim(string(`t1r', "`f6'"))',"sello":`=trim(string(`sc', "%1.0f"))',"grupos":["'
			local first = 0
			forvalues g = 1/`ngrp' {
				local gl : label grp `g'
				local i = (`s'-1)*23*`ngrp' + (`k'-1)*`ngrp' + `g'		// orden tras merge/sort: sexon q grp
				file write `fh' `"`=cond(`g' > 1, ",", "")'{"grupo":"`gl'","n":`=trim(string(n[`i'], "`f0'"))',"pob":`=trim(string(pob[`i'], "`f0'"))',"aporta":`=trim(string(ap[`i'], "`f2'"))',"recibe":`=trim(string(re[`i'], "`f2'"))',"neto":`=trim(string(neto[`i'], "`f2'"))',"pct":`=trim(string(pct[`i'], "`f6'"))',"pct_nac":`=trim(string(pct_nac[`i'], "`f6'"))'}"'
			}
			file write `fh' `"]}"' _n
		}
	}
	file write `fh' `"],"' _n
	file write `fh' `""procedencia":{"modulo":"01_modulos/visualizations/CicloEntidad.do v1.0","base":"users/$id/aportaciones.dta (la misma del nacional)","generado_el":"`fecha' `hora'","stata":"`c(stata_version)' `c(edition_real)'","definicion_de":"Simulador.ado graphpiramide (nacional); filtro substr(folioviv,1,2) == clave INEGI, como SankeySF.do (PR #20)"}}"' _n
	file close `fh'
}

timer off 12
noisily di _newline in g "  Ciclo de vida de entidad: " in y "`enombre'" in g " (`eabrev', clave `eclave') {c -} muestra " in y %9.0fc `nent' in g " personas, poblaci{c o'}n ENIGH " in y %12.0fc `pobent' in g " (" in y %5.2f `pobent'/`pobnac'*100 in g " % del nacional); neto " in y %14.1fc `netoent'/1e6 in g " mdp (" in y %5.2f `netoent'/`netonac'*100 in g " % del neto nacional " in y %14.1fc `netonac'/1e6 in g " mdp); grupos: " in y "`grupos'" in g "; celdas quinquenio x sexo con sello n<`sello_n': " in y "`nsellos' de 46" in g ", vac{c i'}as: " in y "`nvacias'" in g ". JSON en " in y "users/$id/`eabrev'/ciclo-vida.json"
