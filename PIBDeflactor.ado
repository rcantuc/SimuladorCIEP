*! version 8.2 CIEP 16oct2026
*!*******************************************
*!***                                    ****
*!***    PIB, deflactor e inflación      ****
*!***    Fuente: BIE/INEGI               ****
*!***    Autor: Ricardo                  ****
*!***    Version: 8.2                    ****
*!***    Última actualización: 16oct2026 ****
*!***                                    ****
*!*******************************************
*
* ENTIDAD FEDERATIVA (v8.2): PIBDeflactor if entidad == "Nuevo León" [, ...]
*   Misma convención que Poblacion (SIM.do §0.5 arma `ifentidad'). La base
*   nacional no trae variable entidad: el if se consume aquí, se resuelve con
*   SIMentidad (clave INEGI, abreviatura) y se usa master/PIBDeflactor<abrev>.dta
*   (p. ej. PIBDeflactorNL.dta), que UpdatePIBDeflactor construye con:
*     PIBE corriente 750453 e índice de precios implícitos 753357 (BIE, área cc;
*       anuales, replicados en 4 trimestres: el promedio anual es el PIBE),
*     población ocupada/desocupada ENOE 6200093954/6200093973 (BISE vía API,
*       área cc; trimestrales, 15 años y más),
*     INPC de la entidad (programa INPC de INEGI, estructura 112001700070;
*       no está en el BIE),
*     población y edades laborales CONAPO de la entidad (Poblacion.dta).
*   Gráficas, escalares (escalar) y la base llevan la abreviatura como sufijo
*   (pibNL.png, pibYNL, ...); la base nacional master/PIBDeflactor.dta no se toca.
*   Los exógenos $pib/$def/$inf (CGPE) se aplican igual que en el nacional.
program define PIBDeflactor, return
quietly {
	timer on 3

	capture mkdir `"${SIMROOT}/master/"'
	capture mkdir `"${SIMROOT}/users/"'
	capture mkdir `"${SIMROOT}/users/$id/"'
	capture mkdir `"${SIMROOT}/users/$id/graphs/"'

	** 0.1 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)	
	}



	*******************
	**# 1. Sintaxis ***
	*******************
	** 1.1 Entidad federativa: if entidad == "Nombre" (ver encabezado). Se extrae
	** ANTES de syntax porque syntax valida el if contra los datos en memoria y
	** la base de PIBDeflactor no tiene variable entidad. **
	local entidad ""
	local ent ""
	local clave "00"
	if ustrregexm(`"`0'"', `"^\s*if\s+entidad\s*==\s*"([^"]+)"\s*(,.*)?$"') {
		local entidad = ustrregexs(1)
		local 0 = ustrregexs(2)
		SIMentidad "`entidad'"
		local entidad `"`r(nombre)'"'
		local clave "`r(clave)'"
		local ent "`r(abrev)'"
	}
	local base "${SIMROOT}/master/PIBDeflactor`ent'.dta"

	syntax [if] [, ANIOvp(int `aniovp') NOGraphs UPDATE ///
		GEOPIB(int -1) GEODEF(int -1) DIScount(real 5) ANIOMAX(int `=`aniovp'+5') ///
		NOOutput TEXTbook]

	** 1.2 Revisa si se puede usar la base de datos **
	capture confirm file "`base'"
	if _rc != 0 {
		UpdatePIBDeflactor, entidad(`"`entidad'"') clave(`clave') abrev(`ent')
	}

	** 1.3 Si la opción "update" es llamada, se ejecuta el do-file UpdatePIBDeflactor.do **
	if "`update'" == "update" {
		noisily UpdatePIBDeflactor, `nographs' entidad(`"`entidad'"') clave(`clave') abrev(`ent')
	}



	************************
	**# 2 Bases de datos ***
	************************
	use `if' using "`base'", clear
	tsset aniotrimestre
	keep if anio <= `aniomax'
	
	** 2.1 Obtiene el año inicial y final de la base **
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
		}
		if pibQ[`k'] != . & "`anioi'" != "found" {
			local anioinicial = anio[`k']
			local anioi "found"
		}
		if pibQ[`k'] == . & "`anioi'" == "found" {
			local aniofinal = anio[`=`k'-1']
			local trim_last = trimestre[`=`k'-1']
			scalar trimlast = trimestre[`=`k'-1']
			local obsfinal = `k'-1
			continue, break
		}
	}
	* Si aniomax (default aniovp+5) queda antes del ultimo trimestre publicado, ninguna
	* fila del rango tiene pibQ faltante y el bucle no define aniofinal/obsfinal
	* ("pibQ not found" al correr con aniovp <= ultimo observado - 5, p. ej. SCN anio(2016)
	* para armonizar una ENIGH historica). El ultimo observado es entonces la ultima
	* fila del rango. Con aniovp >= 2024 este bloque no se ejecuta (v8.7.1). *
	if "`obsfinal'" == "" {
		local aniofinal = anio[_N]
		local trim_last = trimestre[_N]
		scalar trimlast = trimestre[_N]
		local obsfinal = _N
	}

	
	** 2.2 Display inicial **
	if "`entidad'" == "" {
		noisily di _newline(2) in g _dup(20) "." "{bf:   PIB + Deflactor:" in y " `aniovp'   }" in g _dup(20) "." _newline
	}
	else {
		noisily di _newline(2) in g _dup(20) "." "{bf:   PIB + Deflactor:" in y " `aniovp' | `entidad'   }" in g _dup(20) "." _newline
		noisily di in g " PIBE anual (BIE 750453/753357, {c a'}rea `clave'), ocupados ENOE (BISE 6200093954)"
		noisily di in g " INPC `ent' (INEGI), poblaci{c o'}n CONAPO `ent'."
	}
	noisily di in g " PIB " in y "`aniofinal'q`trim_last'" ///
		_col(33) %20.0fc pibQ[`obsfinal'] in g " `=currency' ({c u'}ltimo reportado)"
	sort anio trimestre

	capture confirm variable var_itaee
	local itaeev = cond(_rc == 0, "var_itaee", "")
	collapse (mean) indiceY=indiceQ pibY=pibQ pibYR=pibQR WorkingAge Poblacion* `itaeev' ///
		(last) inpc trimestre, by(anio currency)
	tsset anio


	** 2.3 Locales para los cálculos geométricos **
	if `geodef' < `anioinicial' {
		local geodef = `anioinicial'
	}
	local difdef = `aniofinal'-`geodef'

	if `geopib' < `anioinicial' {
		local geopib = `anioinicial'
	}
	local difpib = `aniofinal'-`geopib'
	scalar aniogeo = `geopib'
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `geodef' {
			local obsDEF = `k'
		}
		if anio[`k'] == `geopib' {
			local obsPIB = `k'
		}
	}

	g pibPO = pibYR/PoblacionOcupada
	label var pibPO "Productividad laboral"
	format pibPO %10.0fc
	
	g double var_indiceY = (indiceY/L.indiceY-1)*100
	label var var_indiceY "Crecimiento anual del índice de precios"

	g double var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100
	label var var_indiceG "Promedio geométrico (`difdef' años)"
	
	g double var_inflY = (inpc/L.inpc-1)*100
	label var var_inflY "Anual"

	g double var_inflG = ((inpc/L`=`difdef''.inpc)^(1/`difdef')-1)*100
	label var var_inflG "Promedio geométrico (`difdef' años)"

	** 2.4 Merge datasets **
	if `aniovp' < `=`anioinicial'' | `aniovp' > anio[_N] {
		noisily di in r "A{c n~}o para valor presente (`aniovp') inferior a `=`anioinicial'' o superior a `aniofinal'."
		exit
	}
	drop if anio < `anioinicial'
	tsset anio



	*******************
	**# 3 Deflactor ***
	*******************
	label var indiceY "Índice de Precios Implícitos"
	format indiceY %7.1fc

	** 3.1 Imputar Parámetros exógenos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	local exo_def = 0
	local anio_def = `aniovp'
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k' //& trimestre != 4
			local exceptI "`exceptI'${def`k'}% (`k'), "
			local anio_def = `k'
			local ++exo_def
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k' & var_indiceY == . //& trimestre != 4
			replace var_indiceY = L.var_indiceY if anio == `k' & var_indiceY == . & L.var_indiceG == . //& trimestre != 4
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k' //& trimestre != 4
		replace var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100 if anio == `k' & anio > `aniofinal'
	}
	if "`exceptI'" != "" {
		local exceptI "`=substr("`exceptI'",1,`=strlen("`exceptI'")-2')'"
	}

	local exo_count = 0
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm existence ${inf`k'}
		if _rc == 0 {
			replace var_inflY = ${inf`k'} if anio == `k' //& trimestre != 4
			local exceptI "`exceptI'`k' (${inf`k'}%), "
			local ++exo_count
		}
		else {
			replace var_inflY = L.var_inflG if anio == `k' & var_inflY == . //& trimestre != 4
			replace var_inflY = L.var_inflY if anio == `k' & var_inflY == . & L.var_inflG == . //& trimestre != 4
		}
		replace inpc = L.inpc*(1+var_inflY/100) if anio == `k' //& trimestre != 4
		replace var_inflG = ((inpc/L`=`difdef''.inpc)^(1/`difdef')-1)*100 if anio == `k' & anio > `aniofinal'
	}
	
	** 3.2 Valor presente **
	if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}

	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
		}
		if anio[`k'] == `=`aniofinal'' {
			local obslast = `k'
		}
		if anio[`k'] == `geodef' {
			local obsDEF = `k'
		}
		if anio[`k'] == `geopib' {
			local obsPIB = `k'
		}
	}

	g double deflator = indiceY/indiceY[`obsvp']
	label var deflator "Deflactor"
	return scalar deflator = deflator[`obsvp']

	g double deflatorpp = inpc/inpc[`obsvp']
	label var deflatorpp "Poder adquisitivo"
	return scalar deflatorpp = deflatorpp[`obsvp']



	*************
	**# 4 PIB ***
	*************
	replace pibYR = pibY/deflator
	label var pibYR "PIB Real (`=anio[`obsvp']')"
	format pibYR* %25.0fc

	g var_pibY = (pibYR/L.pibYR-1)*100
	label var var_pibY "Anual"
	format var_pibY %7.1fc

	g double var_pibG = ((pibYR/L`=`difpib''.pibYR)^(1/(`difpib'))-1)*100
	label var var_pibG "Geometric mean (`difpib' years)"
	format var_pibG %7.1fc

	** 4.1 Imputar Parámetros exógenos **
	replace currency = currency[`obslast']
	local anio_exo = `aniofinal'
	local exo_count = 0
	* Último año con exógeno: los años SIN exógeno anteriores a él (hueco entre
	* el último observado y el primer $pib, p. ej. PIBE estatal hasta 2024 con
	* $pib desde 2026) reciben nivel con la tasa imputada; si no, la cadena
	* L.pibYR se rompe y todo lo posterior queda missing. Los años posteriores
	* al último exógeno se proyectan en §5 (edades laborales x lambda). *
	local anio_exo_max = `aniofinal'
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm existence ${pib`k'}
		if _rc == 0 local anio_exo_max = `k'
	}
	forvalues k=`aniofinal'(1)`=anio[_N]' {
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k' //& trimestre != 4
			local except "`except'${pib`k'}% (`k'); "
			local anio_exo = `k'
			local ++exo_count

			replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k' //& trimestre != 4
			replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' //& trimestre != 4
		}
		else {
			* Sin exógeno: (1) nowcast ITAEE si la base lo trae y hay dato del año
			* (entidades); (2) promedio geométrico; (3) última tasa observada. *
			if "`itaeev'" != "" & `k' > `aniofinal' {
				summarize var_itaee if anio == `k', meanonly
				if r(N) > 0 {
					replace var_pibY = var_itaee if anio == `k'
					local exceptT "`exceptT'`=string(r(mean), "%5.2f")'% (`k'); "
				}
			}
			replace var_pibY = L.var_pibG if anio == `k' & var_pibY == . //& trimestre != 4
			replace var_pibY = L.var_pibY if anio == `k' & var_pibY == . & L.var_pibG == . //& trimestre != 4
			if `k' < `anio_exo_max' {
				replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' & pibYR == .
				replace pibY = pibYR*deflator if anio == `k' & pibY == .
			}
		}
	}

	if "`except'" != "" {
		local except "`=substr("`except'",1,`=strlen("`except'")-2')'"
	}
	if "`exceptT'" != "" {
		local exceptT "`=substr("`exceptT'",1,`=strlen("`exceptT'")-2')'"
		noisily di in g " Nowcast ITAEE (crecimiento real, mismos trimestres): " in y "`exceptT'"
	}

	** 4.2 Lambda (productividad) **
	g OutputPerWorker = pibYR/WorkingAge
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio_exo' {
			local obs_exo = `k'
		}
		if anio[`k'] == `anio_def' {
			local obs_def = `k'
		}
	}
	return scalar anio_exo = `anio_exo'

	scalar llambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100
	scalar LLambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[1])^(1/(`obs_exo'))-1)*100
	capture confirm existence $lambda
	if _rc == 0 {
		scalar llambda = $lambda
	}
	g lambda = (1+scalar(llambda)/100)^(anio-`aniovp')



	**********************
	*** 5 Proyecciones ***
	**********************
	* Proyección de crecimiento PIB *
	replace pibYR = `=pibYR[`obs_exo']'/`=WorkingAge[`obs_exo']'*WorkingAge*(1+scalar(llambda)/100)^(anio-`anio_exo') if pibYR == .
	replace pibY = pibYR*deflator if pibY == .

	* Crecimientos *
	replace var_pibG = ((pibYR/L`=`difpib''.pibYR)^(1/(`difpib'))-1)*100
	replace var_pibY = (pibYR/L.pibYR-1)*100

	g double pibYVP = pibYR/(1+`discount'/100)^(anio-`=anio[`obsvp']')
	format pibYVP %20.0fc

	replace OutputPerWorker = pibYR/WorkingAge if OutputPerWorker == .

	g PIBPob = pibYR/Poblacion/1000
	format PIBPob %20.0fc
	escalar mxnpc pibYPC`ent' = PIBPob[`obsvp']*1000



	*****************
	** 6 Simulador **
	*****************
	noisily di in g " PIB " in y anio[`obslast'] in g " per c{c a'}pita " in y _col(43) %10.0fc pibY[`obslast']/Poblacion[`obslast'] in g " `=currency[`obslast']'"
	noisily di in g " PIB " in y anio[`obslast'] in g " per c{c a'}pita (edades laborales) " in y _col(43) %10.0fc OutputPerWorker[`obslast'] in g " `=currency[`obslast']' (16-65 a{c n~}os)"

	local crecimientoProm = ((pibYR[`obsvp']/pibYR[`obsPIB'])^(1/(`obsvp'-`obsPIB'))-1)*100
	escalar pct crecimientoProm`ent' = `crecimientoProm'

	local crecimientoPobProm = ((PIBPob[`obsvp']/PIBPob[`obsPIB'])^(1/(`obsvp'-`obsPIB'))-1)*100
	escalar pct crecimientoPobProm`ent' = `crecimientoPobProm'

	local deflactorProm = ((deflator[`obsvp']/deflator[`obsDEF'])^(1/(`obsvp'-`obsDEF'))-1)*100
	escalar pct deflactorProm`ent' = `deflactorProm'

	* Base del promedio de inflación: geodef, salvo que el INPC empiece después
	* (el INPC por entidad federativa existe desde jul-2018; el nacional desde
	* 1980): se toma el primer año con INPC observado. *
	local obsINF = `obsDEF'
	while inpc[`obsINF'] == . & `obsINF' < `obsvp' {
		local ++obsINF
	}
	local geoinf = anio[`obsINF']
	local inflacionProm = ((inpc[`obsvp']/inpc[`obsINF'])^(1/(`obsvp'-`obsINF'))-1)*100
	escalar pct inflacionProm`ent' = `inflacionProm'

	noisily di _newline in g " Crecimiento promedio " in y anio[`obsPIB'] "-" anio[`obs_exo'] _col(43) %10.4f ((pibYR[`obs_exo']/pibYR[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100 in g " %" 
	noisily di in g " Crecimiento productividad " in y anio[`obsPIB'] "-" anio[`obs_exo'] _col(43) %10.4f scalar(llambda) in g " % (working age)" 
	*noisily di in g " Lambda por trabajador " in y anio[1] "-" anio[`obs_exo'] _col(35) %10.4f scalar(LLambda) in g " %" 
	
	escalar pct llambda`ent' = ((OutputPerWorker[`obs_exo']/OutputPerWorker[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	*scalar pibINF = pibYR[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')/((`discount'/100)-`grow_rate_LR'+((`discount'/100)*`grow_rate_LR'))
	scalar pibINF = pibYR[_N] /*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')*/ /(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat pibYVP if anio >= `aniovp', stat(sum) f(%20.0fc) save
	tempname pibYVP
	matrix `pibYVP' = r(StatTotal)

	scalar pibVPINF = `pibYVP'[1,1] + pibINF
	escalar mxn pibY`ent' = pibY[`obsvp']
	scalar pibVECES = round((pibYR[`obsvp']/pibYR[`obsPIB']),.1)
	scalar pibLP = round((pibYR[_N]/pibYR[`obsvp']-1)*100,.1)
	
	scalar pibVECESPC = round((PIBPob[`obsvp']/PIBPob[`obsPIB']),.1)
	scalar pibLPPC = round((PIBPob[_N]/PIBPob[`obsvp']-1)*100,.1)

	escalar pct deflactorLP`ent' = (deflator[`obs_exo']/deflator[`obsvp'] - 1)*100
	escalar pct deflactorVECES`ent' = round((deflator[`obsvp']/deflator[`obsDEF']),.1)
	scalar anioLP = anio[_N]

	escalar pct inflacionLP`ent' = (deflatorpp[`obs_exo']/deflatorpp[`obsvp'] - 1)*100
	escalar pct inflacionVECES`ent' = round((deflatorpp[`obsvp']/deflatorpp[`obsINF']),.1)

	scalar anioPWI = anio[`obsPIB']
	scalar anioPWF = anio[`obs_exo']
	escalar mxnpc outputPWI`ent' = OutputPerWorker[`obsPIB']
	escalar mxnpc outputPW`ent' = OutputPerWorker[`obsvp']
	escalar pct outputPWVECES`ent' = round(((OutputPerWorker[`obsvp']/OutputPerWorker[`obsPIB']-1)*100),.1)
	scalar lambdaNW = ((pibYR[`obs_exo']/pibYR[`=`obs_exo'-`difpib''])^(1/(`difpib'))-1)*100
	scalar LambdaNW = ((pibYR[`obs_exo']/pibYR[1])^(1/(`obs_exo'))-1)*100

	di _newline in g " PIB " in y "al infinito" in y _col(22) %23.0fc `pibYVP'[1,1] + pibINF in g " `=currency[`obsvp']'"
	di in g " Tasa de descuento: " in y _col(25) %20.1fc `discount' in g " %"
	di in g " Crec. al infinito: " in y _col(25) %20.1fc var_pibY[_N] in g " %"
	di in g " Defl. al infinito: " in y _col(25) %20.1fc var_indiceY[_N] in g " %"

	g var_PO = (pibPO/L.pibPO-1)*100
	format var_PO %7.1fc

	****************
	** 7 Gráficas **
	****************

	if "`nographs'" != "nographs" & "$nographs" == "" {
		
		local tent = cond("`entidad'" == "", "", ": `entidad'")

		** 7.1 Gráficas iniciales ***
		* Títulos y fuentes *
		if "$textbook" == "" {
			local graphtitle "{bf:Productividad laboral`tent'}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Una entidad se mide en pocos billones/millones: un decimal en las etiquetas. *
		local fmtg = cond("`ent'" == "", "%7.0fc", "%7.1fc")
		tempvar gpibYR gPO gPO2
		g `gpibYR' = pibYR/1000000000000
		format `gpibYR' `fmtg'

		g `gPO' = PoblacionOcupada/1000000
		format `gPO' `fmtg'

		g `gPO2' = pibPO/1000
		format `gPO2' %7.0fc

		tabstat `gPO2' if anio == `aniofinal', f(%7.1fc) stat(mean) save
		tempname meanPO2
		matrix `meanPO2' = r(StatTotal)

		tabstat `gPO2' if anio == 2005, f(%7.1fc) stat(mean) save
		tempname meanPO3
		matrix `meanPO3' = r(StatTotal)

		local crecpo2 = `meanPO2'[1,1]
		local crecpo3 = `meanPO3'[1,1]

		* Rangos de los tres ejes: fijos para el nacional (calibrados a mano);
		* para una entidad se escalan a sus datos con las mismas proporciones. *
		local rango1 "0 75"
		local rango2 "40 95"
		local rango3 "450 675"
		if "`ent'" != "" {
			summarize `gpibYR' if pibPO != ., meanonly
			local rango1 "0 `=r(max)*2.1'"
			summarize `gPO' if pibPO != ., meanonly
			local rango2 "`=r(min)*.95' `=r(max)*1.6'"
			summarize `gPO2' if pibPO != ., meanonly
			local rango3 "`=r(min)*.8' `=r(max)*1.05'"
		}

		twoway (bar `gpibYR' anio, ///
			mlabel(`gpibYR') mlabposition(12) mlabcolor("111 111 111") mlabgap(0pt) mlabsize(medium) ///
				lcolor(none) yaxis(1) barwidth(.75) pstyle(p2)) ///
			(bar `gPO' anio, mlabel(`gPO') mlabposition(12) mlabcolor("111 111 111") mlabgap(0pt) ///
				lcolor(none) mlabsize(medium) yaxis(2) barwidth(.33) pstyle(p1)) ///
			(connected `gPO2' anio, yaxis(3) mlabel(`gPO2') mlabposition(12) mlabcolor("111 111 111") mlabgap(0pt) ///
				mlabsize(medium) pstyle(p3)) ///)
			if pibPO != ., ///
			title(`graphtitle') ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			ytitle("", axis(3)) ///
			xtitle("") ///
			tlabel(2005(1)`=cond(`trim_last' == 4, `aniofinal', `aniofinal'-1)', labsize(medium)) ///
			ylabel(none, format(%20.0fc) axis(1)) ///
			ylabel(none, format(%20.0fc) axis(2)) ///
			ylabel(none, format(%20.0fc) axis(3)) ///
			yscale(range(`rango1') axis(1)) ///
			yscale(range(`rango2') axis(2)) ///
			yscale(range(`rango3') axis(3)) ///
			legend(on label(1 "PIB (billones `=currency' `aniovp')") ///
			label(2 "Población Ocupada (millones)") ///
			label(3 "Productividad (miles `=currency' `aniovp')") size(medlarge))	///
			///yline(`crecpo2', axis(3)) ///
			///text(`=`crecpo2'-10' 2005 `"Dif. 2005 - `aniofinal': {bf:`=string(`crecpo2'-`crecpo3',"%7.0fc")'}"', ///
			///justification(left) place(5) color("111 111 111") size(medlarge) yaxis(3)) ///
			caption("`graphfuente'") ///
			name(Productividad`aniofinal'`ent', replace)

		capture mkdir "${SIMROOT}/users/"
		capture mkdir "${SIMROOT}/users/$id/"
		capture mkdir "${SIMROOT}/users/$id/graphs/"
		
		if "$export" != "" {
			graph export "$export/Productividad`aniofinal'`ent'.png", replace name(Productividad`aniofinal'`ent')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/Productividad`aniofinal'`ent'.png", replace name(Productividad`aniofinal'`ent')
		}

		** 7.2 Gráficas finales **/
		if "`if'" != "" {
			keep `if'
			local aniomax = anio[_N]
			local anioinicial = anio[1]
		}

		************************************
		*** 1. Crecimiento del Deflactor ***
		************************************
		
		* Títulos y fuentes *
		if "$textbook" == "" {
			local graphtitle "{bf:Índice de precios implícitos`tent'}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local defl_ini = deflator[`k']
			}
			if anio[`k'] == `aniovp' {
				local defl_vp = deflator[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local indi_ini = var_indiceY[`k']
			}
			if anio[`k'] == `aniomax' {
				local defl_fin = deflator[`k']
				local indi_fin = var_indiceY[`k']
			}
		}
		format deflator %7.1fc
		format var_indiceY %7.1fc
		twoway /// Bar
			(bar deflator anio if (anio < `aniofinal' & anio >= `geodef') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(2) mlabel(deflator) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(bar deflator anio if anio <= `aniofinal'+`exo_def'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(2) mlabel(deflator) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(bar deflator anio if anio > `aniofinal'+`exo_def'-1 & anio <= `aniomax', ///
				yaxis(2) mlabel(deflator) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			/// Connected
			(connected var_indiceY anio if (anio < `aniofinal' & anio >= `geodef') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(1) mlabel(var_indiceY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p1) lstyle(p1) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected var_indiceY anio if anio <= `aniofinal'+`exo_def'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(1) mlabel(var_indiceY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p2) lstyle(p2) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected var_indiceY anio if anio > `aniofinal'+`exo_def'-1 & anio <= `aniomax', ///
				yaxis(1) mlabel(var_indiceY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p3) lstyle(p3) lpattern(dot) msize(small) mlabsize(medium)) ///
			, ///
			title("`graphtitle'") ///
			xlabel(`=round(`geodef',5)'(1)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) yscale(range(0 3.5) axis(2) noline) ///
			ylabel(none, format(%3.0f) axis(1) noticks) yscale(range(0) axis(1) noline) ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			b1title(`"1 MXN de `anioinicial' = {bf:`=string(1/deflator[1],"%6.2fc")'} MXN en `aniovp'"', size(vlarge)) ///
			legend(off label(1 "INEGI, SCN 2018") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			caption("`graphfuente'") ///
			///note("{bf:Nota}: La proyección representa el promedio geométrico móvil de los últimos `difdef' años.") ///
			name(deflactor`ent', replace) ///
			/// Added text
			text(0 `=`aniofinal'-1.5' "{bf:Índice `aniovp' = 1.0}", ///
				yaxis(2) size(medsmall) place(11) justification(right) bcolor(white) box) ///
			text(0 `=`aniofinal'+2.5' "{bf:$paqueteEconomico}", ///
				yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(0 `=`aniofinal'+`exo_def'+2.5' "{bf:  Proyección}", ///
				yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			yline(`deflactorProm', axis(1)) ///
			text(`deflactorProm' `=`geodef'' "{bf:Crec. prom.}" ///
				`"{bf:`geodef'-`aniofinal': `=string(`deflactorProm',"%5.1fc")'%}"', ///
				justification(left) place(5) color("111 111 111") size(medlarge))

		if "$export" != "" {
			graph export "$export/deflactor`ent'.png", replace name(deflactor`ent')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/deflactor`ent'.png", replace name(deflactor`ent')
		}



		******************************
		*** 2. Crecimiento del PIB ***
		******************************
		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000000000
		format `pibYRmil' `fmtg'

		* Títulos y fuentes *
		if "$textbook" == "" {
			local graphtitle "{bf:Producto Interno Bruto`tent'}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local pib_ini = `pibYRmil'[`k']
				local varpibYini = var_pibY[`k']
				if `varpibYini' == . {
					local varpibYini = var_pibY[`k'+1]
				}
			}
			if anio[`k'] == `aniovp' {
				local pib_vp = `pibYRmil'[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local crec_ini = var_pibY[`k']
			}
			if anio[`k'] == `aniomax' {
				local pib_fin = `pibYRmil'[`k']
				local crec_fin = var_pibY[`k']
			}
		}
		format var_pibY %7.1fc

		tabstat `pibYRmil' var_pibY, by(anio) f(%7.1fc) stat(min max) save
		tempname pibYRmil2
		matrix `pibYRmil2' = r(StatTotal)
		
		twoway ///
			(bar `pibYRmil' anio if (anio < `aniofinal' & anio >= `geopib') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(2) mlabel(`pibYRmil') mlabpos(12) mlabcolor("111 111 111") /// 
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(bar `pibYRmil' anio if anio <= `aniofinal'+`exo_def'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(2) mlabel(`pibYRmil') mlabpos(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(bar `pibYRmil' anio if anio > `aniofinal'+`exo_def'-1 & anio <= `aniomax', ///
				yaxis(2) mlabel(`pibYRmil') mlabpos(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(connected var_pibY anio if (anio < `aniofinal' & anio >= `geopib') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(1) mlabel(var_pibY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p1) lstyle(p1) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected var_pibY anio if anio <= `aniofinal'+`exo_def'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(1) mlabel(var_pibY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p2) lstyle(p2) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected var_pibY anio if anio > `aniofinal'+`exo_def'-1 & anio <= `aniomax', ///
				yaxis(1) mlabel(var_pibY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p3) lstyle(p3) lpattern(dot) msize(small) mlabsize(medium)) ///
			, ///
			title("`graphtitle'") ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`=round(`geopib',5)'(1)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) ///
			ylabel(none, format(%3.0f) axis(1) noticks) ///
			yscale(range(0 `=`pibYRmil2'[1,2]*3') axis(1) noline) ///
			yscale(range(0 `=`pibYRmil2'[2,1]*2') axis(2) noline) ///
			legend(off label(1 "INEGI, SCN 2018") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			caption("`graphfuente'") ///
			///note("{bf:Nota}: La proyección representa el promedio geométrico móvil de los últimos `difpib' años.") ///
			name(pib`ent', replace) ///
			/// Added text
			yline(`crecimientoProm', axis(1)) ///
			text(0 `=`aniofinal'-1.5' "{bf:billones MXN `aniovp'}", ///
				yaxis(2) size(medsmall) place(11) justification(right) bcolor(white) box) ///
			text(0 `=`aniofinal'+2.5' "{bf:$paqueteEconomico}",  ///
				yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(0 `=`aniofinal'+`exo_def'+2.5' "{bf:  Proyección}", ///
				yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(`=`crecimientoProm'-.75' `=`geopib'' "{bf:Crec. prom.}" ///
				`"{bf:`geopib'-`aniofinal': `=string(`crecimientoProm',"%5.1fc")'%}"', ///
				justification(left) place(5) color("111 111 111") size(medlarge)) ///

		if "$export" != "" {
			graph export "$export/pib`ent'.png", replace name(pib`ent')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/pib`ent'.png", replace name(pib`ent')
		}



		**************************
		*** 3. PIB por persona ***
		**************************
		g var_pibPob = (PIBPob/L.PIBPob-1)*100
		format var_pibPob %7.1fc

		* Títulos y fuentes *
		if "$textbook" == "" {
			local graphtitle "{bf:Producto Interno Bruto por persona`tent'}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/CONAPO."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local pib_ini = PIBPob[`k']
			}
			if anio[`k'] == `aniovp' {
				local pib_vp = PIBPob[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local crec_ini = var_pibPob[`k']
			}
			if anio[`k'] == `aniomax' {
				local pib_fin = PIBPob[`k']
				local crec_fin = var_pibPob[`k']
			}
		}

		tabstat PIBPob var_pibPob, by(anio) f(%7.1fc) stat(min max) save
		tempname pibPob
		matrix `pibPob' = r(StatTotal)

		//tabstat PIBPob var_pibPob if anio < `aniofinal'+`exo_def' & anio > `aniofinal', by(anio) f(%7.1fc) stat(min max) save
		//tempname pibPob2
		//matrix `pibPob2' = r(StatTotal)

		* Rangos: fijos para el nacional; para una entidad, proporcionales a sus
		* datos (barras en el tramo inferior, línea de crecimiento arriba). *
		local rangopc1 "0 -40"
		local rangopc2 "0 500"
		if "`ent'" != "" {
			summarize PIBPob if anio >= `geopib' & anio <= `aniomax', meanonly
			local rangopc2 "0 `=r(max)*1.9'"
			summarize var_pibPob if anio >= `geopib' & anio <= `aniomax', meanonly
			local rangopc1 "`=-4*max(abs(r(min)), abs(r(max)))' `=r(max)*1.3'"
		}

		tempname pibPob3
		capture tabstat PIBPob var_pibPob if anio >= `aniofinal'+`exo_def', by(anio) f(%7.1fc) stat(min max) save
		if _rc == 0 {
			matrix `pibPob3' = r(StatTotal)
		}
		else {
			matrix `pibPob3' = J(1,1,0)
		}

		twoway /// Bar
			(bar PIBPob anio if (anio < `aniofinal' & anio >= `geopib') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(2) mlabel(PIBPob) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(small)) ///
			(bar PIBPob anio if anio <= `aniofinal'+`exo_count'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(2) mlabel(PIBPob) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(small)) ///
			(bar PIBPob anio if anio > `aniofinal'+`exo_count'-1 & anio <= `aniomax', ///
				yaxis(2) mlabel(PIBPob) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(small)) ///
			/// Connected
			(connected var_pibPob anio if (anio < `aniofinal' & anio >= `geopib') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(1) mlabel(var_pibPob) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p1) lstyle(p1) lpattern(dot) msize(small) mlabsize(medsmall)) ///
			(connected var_pibPob anio if anio <= `aniofinal'+`exo_count'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(1) mlabel(var_pibPob) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p2) lstyle(p2) lpattern(dot) msize(small) mlabsize(medsmall)) ///
			(connected var_pibPob anio if anio > `aniofinal'+`exo_count'-1 & anio <= `aniomax', ///
				yaxis(1) mlabel(var_pibPob) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p3) lstyle(p3) lpattern(dot) msize(small) mlabsize(medsmall)) ///
			, ///
			title("`graphtitle'") ///
			///subtitle("    Nivel de producto per cápita (miles MXN `aniovp') y crecimiento anual (%)", margin(bottom)) ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`=round(`geopib',5)'(1)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) ///
			ylabel(none, format(%3.0f) axis(1) noticks) ///
			yscale(range(`rangopc1') axis(1) noline) ///
			yscale(range(`rangopc2') axis(2) noline) ///
			legend(off label(1 "Observado") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			///note("{bf:Nota}: La proyección representa el promedio geométrico móvil de los últimos `difpib' años.") ///
			caption("`graphfuente'") ///
			name(pib_pc`ent', replace) ///
			/// Added text
			yline(`crecimientoProm', axis(1)) ///
			text(0 `=`aniofinal'-1.5' "{bf:miles MXN `aniovp' per cápita}", yaxis(2) size(medsmall) place(11) justification(right) bcolor(white) box) ///
			text(0 `=`aniofinal'+2.5' "{bf:$paqueteEconomico}",  yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(0 `=`aniofinal'+`exo_def'+2.5' "{bf:  Proyección}", yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(`=`crecimientoPobProm'-6' `=`geopib'' "{bf:Crec. prom.}" "{bf:`geopib'-`aniofinal': `=string(`crecimientoPobProm',"%5.1fc")'%}", justification(left) place(5) color("111 111 111") size(medlarge)) ///

		if "$export" != "" {
			graph export "$export/pib_pc`ent'.png", replace name(pib_pc`ent')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/pib_pc`ent'.png", replace name(pib_pc`ent')
		}



		**************************
		*** 4. Inflación anual ***
		**************************

		* Títulos y fuentes *
		if "$textbook" == "" {
			local graphtitle = cond("`entidad'" == "", "{bf:Índice nacional de precios al consumidor}", "{bf:Índice de precios al consumidor`tent'}")
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/SHCP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Especificaciones *
		forvalues k=1(1)`=_N' {
			if anio[`k'] == `anioinicial' {
				local defl_ini = deflatorpp[`k']
			}
			if anio[`k'] == `aniovp' {
				local defl_vp = deflatorpp[`k']
				local infl_vp = var_inflY[`k']
			}
			if anio[`k'] == `aniofinal'+`exo_def'-1 {
				local infl_ini = var_inflY[`k']
			}
			if anio[`k'] == `aniomax' {
				local defl_fin = deflatorpp[`k']
				local infl_fin = var_inflY[`k']
			}
		}

		* Eje x: desde geodef (redondeado a 5) como las demás gráficas, salvo que el
		* INPC empiece después (entidades: jul-2018). *
		local xinf = cond(`geoinf' > round(`geodef',5), `geoinf', round(`geodef',5))
		local xmin = max(`geoinf', `geodef')

		tabstat deflatorpp var_inflY, by(anio) f(%7.1fc) stat(min max) save
		tempname deflatorpp
		matrix `deflatorpp' = r(StatTotal)

		//tabstat deflatorpp var_inflY if anio < `aniofinal'+`exo_def' & anio > `aniofinal', by(anio) f(%7.1fc) stat(min max) save
		//tempname deflatorpp2
		//matrix `deflatorpp2' = r(StatTotal) 

		tempname deflatorpp3
		capture tabstat deflatorpp var_inflY if anio >= `aniofinal'+`exo_def', by(anio) f(%7.1fc) stat(min max) save
		if _rc == 0 {
			matrix `deflatorpp3' = r(StatTotal)
		}
		else {
			matrix `deflatorpp3' = J(1,1,0)
		}

		format deflatorpp %7.1fc
		format var_inflY %7.1fc
		twoway ///
			(bar deflatorpp anio if (anio < `aniofinal' & anio >= `xmin') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(2) mlabel(deflatorpp) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(bar deflatorpp anio if anio <= `aniofinal'+`exo_def'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(2) mlabel(deflatorpp) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			(bar deflatorpp anio if anio > `aniofinal'+`exo_def'-1 & anio <= `aniomax', ///
				yaxis(2) mlabel(deflatorpp) mlabposition(12) mlabcolor("111 111 111") ///
				mlabgap(0pt) barwidth(.75) mlabsize(medium)) ///
			/// Connected
			(connected var_inflY anio if (anio < `aniofinal' & anio >= `xmin') ///
				| (anio == `aniofinal' & trimestre == 4), ///
				yaxis(1) mlabel(var_inflY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p1) lstyle(p1) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected var_inflY anio if anio <= `aniofinal'+`exo_def'-1 & anio > `aniofinal' ///
				| (anio == `aniofinal' & trimestre < 4), ///
				yaxis(1) mlabel(var_inflY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p2) lstyle(p2) lpattern(dot) msize(small) mlabsize(medium)) ///
			(connected var_inflY anio if anio > `aniofinal'+`exo_def'-1 & anio <= `aniomax', ///
				yaxis(1) mlabel(var_inflY) mlabpos(12) mlabcolor("111 111 111") ///
				mstyle(p3) lstyle(p3) lpattern(dot) msize(small) mlabsize(medium)) ///
			, ///
			title("`graphtitle'") ///
			xtitle("") ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`xinf'(1)`aniomax') ///
			ylabel(none, format(%3.0f) axis(2) noticks) ///
			ylabel(none, format(%3.0f) axis(1) noticks) ///
			yscale(range(0 3.5) axis(2) noline) ///
			yscale(range(0 -5) axis(1) noline) ///
			legend(off label(1 "INEGI, SCN 2018") label(2 "$paqueteEconomico") label(3 "Proyección") order(1 2 3)) ///
			///note("{bf:Nota}: La proyección representa el promedio geométrico móvil de los últimos `difdef' años.") ///
			caption("`graphfuente'") ///
			name(inflacion`ent', replace) ///
			/// Added text
			text(0 `=`aniofinal'-1.5' "{bf:Índice `aniovp' = 1.0}", ///
				yaxis(2) size(medsmall) place(11) justification(right) bcolor(white) box) ///
			text(0 `=`aniofinal'+2.5' "{bf:$paqueteEconomico}",  ///
				yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			text(0 `=`aniofinal'+`exo_def'+2.5' "{bf:  Proyección}", ///
				yaxis(2) size(medsmall) place(12) justification(left) bcolor(white) box) ///
			yline(`inflacionProm', axis(1)) ///
			text(`=`inflacionProm'-cond("`ent'" == "", .75, 3.5)' `=`xinf'' "{bf:Crec. prom.}" `"{bf:`geoinf'-`aniofinal': `=string(`inflacionProm',"%5.1fc")'%}"', justification(left) place(5) color("111 111 111") size(medlarge))

		if "$export" != "" {
			graph export "$export/inflacion`ent'.png", replace name(inflacion`ent')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/inflacion`ent'.png", replace name(inflacion`ent')
		}
	}
	return local except "`except'"
	return local exceptI "`exceptI'"
	return local exceptT "`exceptT'"
	return scalar geo = `difpib'
	return scalar discount = `discount'
	return scalar aniovp = `aniovp'



	***************
	*** 4 Texto ***
	***************
	noisily di _newline in g _col(10) "Crec." ///
	    _col(20) "PIB Nominal" ///
	    _col(42) "Inf." ///
	    _col(50) "Def. INPC" ///
	    _col(66) "Precios" ///
	    _col(75) "Deflactor"
	forvalues k=`=`obsvp'-10'(1)`=`obsvp'+10' {
	    if anio[`k'] < `aniofinal' | (anio[`k'] == `aniofinal' & trimestre[`k'] == 4) {
		if "`reportado'" == "" {
		    local reportado = "done"
		}
		noisily di in g " `=anio[`k']' " _col(7) %6.1fc in y var_pibY[`k'] " %" ///
		    _col(18) %20.0fc pibY[`k'] ///
		    _col(35) %8.1fc in y var_inflY[`k'] " %" ///
		    _col(45) %14.10fc deflatorpp[`k'] ///
		    _col(55) %8.1fc var_indiceY[`k'] " %" ///
		    _col(75) %12.10fc deflator[`k']
	    }
	    if anio[`k'] <= anio[`obs_exo'] & (anio[`k'] > `aniofinal' | (anio[`k'] == `aniofinal' & trimestre[`k'] < 4)) {
		if "`estimado'" == "" {
		    noisily di _col(20) in g "Estimado $paqueteEconomico"
		    local estimado = "done"
		}
		noisily di in g "{bf: `=anio[`k']' " _col(7) %6.1fc in y var_pibY[`k'] " %" ///
		    _col(18) %20.0fc pibY[`k'] ///
		    _col(35) %8.1fc in y var_inflY[`k'] " %" ///
		    _col(45) %14.10fc deflatorpp[`k'] ///
		    _col(55) %8.1fc var_indiceY[`k'] " %" ///
		    _col(75) %12.10fc deflator[`k'] "}"
	    }
	    /*if (anio[`k'] > `aniofinal') & anio[`k'] > anio[`obs_exo'] {
		if "`proyectado'" == "" {
		    noisily di in g _col(20) "Proyecciones"
		    local proyectado = "done"
		}
		noisily di in g " `=anio[`k']' " _col(7) %6.1fc in y var_pibY[`k'] " %" ///
		    _col(18) %20.0fc pibY[`k'] ///
		    _col(35) %8.1fc in y var_inflY[`k'] " %" ///
		    _col(45) %14.10fc deflatorpp[`k'] ///
		    _col(55) %8.1fc var_indiceY[`k'] " %" ///
		    _col(75) %12.10fc deflator[`k']
	    }*/
	}
	scalar aniolast = `aniofinal'

	if "`textbook'" == "textbook" {
		capture which scalarlatex
		if _rc {
			noisily di in g "Nota: la opcion textbook (scalarlatex) es solo-repo; no viaja al endpoint publico."
		}
		else {
			noisily scalarlatex, log(pibdeflactor) alt(pib)
		}
	}
	
	timer off 3
	timer list 3
	noisily di _newline in g "Tiempo: " in y round(`=r(t3)/r(nt3)',.01) in g " segs."
}
end



*****************************************
**** Base de datos: PIBDeflactor.dta ****
*****************************************
program define UpdatePIBDeflactor
	syntax [, NOGraphs ENTidad(string) CLAve(string) ABRev(string)]
	if "`clave'" == "" local clave "00"
	noisily di in g "  Updating PIBDeflactor`abrev'.dta..." _newline

	**************
	***        ***
	**# 1. PIB ***
	***        ***
	**************

	** 1.1. Importar variables de interés desde el BIE **
	if "`entidad'" == "" {
		AccesoBIE 734407 735143 446562 446565 446566, nombres(pibQ indiceQ PoblacionENOE PoblacionOcupada PoblacionDesocupada)
	}
	else {
		* Entidad: el PIBE es ANUAL (BIE, área cc). Se replica en los 4 trimestres
		* para conservar la estructura trimestral de la base: el PIB trimestral
		* nacional viene anualizado, así que el promedio anual (collapse mean en
		* PIBDeflactor §2.2) devuelve el PIBE tal cual. La población ocupada ENOE
		* por entidad vive en el BISE (API oficial, requiere token). *
		AccesoBIE 750453 753357, nombres(pibQ indiceQ) area(`clave')
		keep anio pibQ indiceQ
		expand 4
		bysort anio: g trimestre = _n
		tempfile pibe
		save `pibe'
		AccesoBIE 6200093954 6200093973, nombres(PoblacionOcupada PoblacionDesocupada) area(`clave')
		keep anio trimestre PoblacionOcupada PoblacionDesocupada
		merge 1:1 anio trimestre using `pibe', nogen
		g periodo = string(anio) + "/" + string(trimestre, "%02.0f")
		save `pibe', replace

		* ITAEE (índice de volumen físico 2018=100, serie original, total de la
		* actividad): nowcast del crecimiento real en los años posteriores al último
		* PIBE sin exógeno $pib (PIBDeflactor §4.1). El BIE lo publica en dos
		* indicadores: 741177 (23 entidades sin petróleo) y 741180 "con petróleo"
		* (las 9 petroleras). var_itaee = crecimiento anual (%) comparando los
		* trimestres disponibles del año con los MISMOS trimestres del anterior. *
		capture AccesoBIE 741177, nombres(itaeeQ) area(`clave')
		if _rc capture AccesoBIE 741180, nombres(itaeeQ) area(`clave')
		if _rc == 0 {
			keep anio trimestre itaeeQ
			sort anio trimestre
			g double itaeeL4 = itaeeQ[_n-4] if anio[_n-4] == anio - 1 & trimestre[_n-4] == trimestre
			g byte ambos = itaeeQ != . & itaeeL4 != .
			bysort anio: egen double s1 = total(cond(ambos, itaeeQ, 0))
			bysort anio: egen double s0 = total(cond(ambos, itaeeL4, 0))
			g double var_itaee = (s1/s0 - 1)*100 if s0 > 0
			label var var_itaee "Crecimiento anual ITAEE, mismos trimestres (%)"
			format var_itaee %7.2fc
			keep anio trimestre var_itaee
			merge 1:1 anio trimestre using `pibe', nogen
		}
		else {
			noisily di in y "  ITAEE no disponible para el {c a'}rea `clave'; sin nowcast."
			use `pibe', clear
		}
	}

	** 1.2 Label variables **
	label var pibQ "Producto Interno Bruto (trimestral)"
	label var indiceQ "Índice de precios implícitos (trimestral)"
	capture label var PoblacionENOE "Población ENOE"
	label var PoblacionOcupada "Población Ocupada (ENOE)"
	label var PoblacionDesocupada "Población Desocupada (ENOE)"

	** 1.3 Dar formato a variables **
	replace pibQ = pibQ*1000000
	format indice* %8.3f
	format pib %20.0fc
	format Poblacion* %12.0fc

	/** 1.4 Time Series **
	split periodo, destring p("/") //ignore("r p")
	rename periodo1 anio
	label var anio "anio"
	rename periodo2 trimestre
	label var trimestre "trimestre"

	** 1.5 Guardar **/
	order anio trimestre pibQ
	compress
	tempfile PIB
	save `PIB'



	***************
	***         ***
	**# 2. INPC ***
	***         ***
	***************
	** 2.1. Importar variables de interés desde el BIE **
	if "`entidad'" == "" {
		AccesoBIE 910392, nombres(inpc)
		label var inpc "Índice Nacional de Precios al Consumidor"
	}
	else {
		* El INPC por entidad NO está en el BIE (910392 solo trae el área 00):
		* se lee del programa INPC de INEGI (ver AccesoINPCEntidad). *
		AccesoINPCEntidad `clave', nombre(inpc)
		label var inpc "Índice de Precios al Consumidor: `entidad'"
	}

	** 2.2 Label variables **

	** 2.3 Dar formato a variables **
	format inpc %8.3f

	/** 2.4 Time Series **
	split periodo, destring p("/") //ignore("r p")
	rename periodo1 anio
	label var anio "anio"
	rename periodo2 mes
	label var mes "mes"*/

	g trimestre = 1 if mes <= 3
	replace trimestre = 2 if mes > 3 & mes <= 6
	replace trimestre = 3 if mes > 6 & mes <= 9
	replace trimestre = 4 if mes > 9
	
	** 5.3 Crecimiento anual real **
	g aniomes = ym(anio,mes)
	tsset aniomes
	g crec_infl = (inpc/L12.inpc-1)*100
	format crec_infl %10.3fc

	collapse (last) inpc, by(anio trimestre)

	** 2.5 Guardar **
	order anio trimestre inpc
	compress
	tempfile inpc
	save `inpc'



	********************
	***              ***
	**# 3. Poblacion ***
	***              ***
	********************

	** 3.1 Población (CONAPO) **
	local entpob = cond("`entidad'" == "", "Nacional", "`entidad'")
	capture use `"${SIMROOT}/master/$pais/Poblacion.dta"', clear
	if _rc != 0 {
		Poblacion, nographs
		use `"${SIMROOT}/master/$pais/Poblacion.dta"', clear
	}
	collapse (sum) Poblacion=poblacion if entidad == "`entpob'", by(anio)
	format Poblacion %20.0fc
	tempfile Poblacion
	save "`Poblacion'"

	** 3.2 Working Ages (CONAPO) **
	use `"${SIMROOT}/master/$pais/Poblacion.dta"', clear
	collapse (sum) WorkingAge=poblacion if edad >= 15 & edad <= 65 & entidad == "`entpob'", by(anio)
	format WorkingAge %15.0fc
	tempfile WorkingAge
	save "`WorkingAge'"

	** 3.3 Recién nacidos (CONAPO) **
	use `"${SIMROOT}/master/$pais/Poblacion.dta"', clear
	collapse (sum) Poblacion0=poblacion if edad == 0 & entidad == "`entpob'", by(anio)
	format Poblacion0 %15.0fc
	tempfile Poblacion0
	save "`Poblacion0'"



	***************
	***         ***
	**# 4 Unión ***
	***         ***
	***************
	use `PIB', clear
		local ultanio = anio[_N]
		local ulttrim = trimestre[_N]
	merge m:1 (anio) using "`Poblacion'", nogen //keep(matched)
	merge m:1 (anio) using "`WorkingAge'", nogen //keep(matched)
	merge m:1 (anio) using "`Poblacion0'", nogen //keep(matched)
		replace trimestre = 1 if trimestre == .
	merge 1:1 (anio trimestre) using "`inpc'", nogen //keep(matched)

	** 4.1 Moneda **
	g currency = "MXN"

	** 4.2 Anio + Trimestre **
	g aniotrimestre = yq(anio,trimestre)
	format aniotrimestre %tq
	label var aniotrimestre "YearQuarter"
	tsset aniotrimestre



	******************************
	***                        ***
	**# 5 Variables de interés ***
	***                        ***
	******************************
	forvalues k=`=_N'(-1)1 {
		if indiceQ[`k'] != . {
			local obsvp = `k'
			local trim_last = trim[`k']
			local aniofinal = anio[`k']
			continue, break
		}
	}
	tempvar deflator
	g double `deflator' = indiceQ/indiceQ[`obsvp']


	** 5.1 PIB Real **
	g pibQR = pibQ/`deflator'

	** 5.2 PIB por población ocupada **
	g pibPO = pibQR/PoblacionOcupada
	format pibPO %20.0fc

	** 5.3 Crecimiento anual real **
	g crec_pibQR = (pibQR/L4.pibQR-1)*100
	format crec_pibQR %10.1fc

	** 5.4 Guardar base de datos **
	format pib* %25.0fc
	capture drop __*
	sort aniotrimestre
	save "${SIMROOT}/master/PIBDeflactor`abrev'.dta", replace
end



*********************************************************
**** INPC por entidad federativa (programa INPC INEGI) ***
*********************************************************
* AccesoINPCEntidad cc, NOMbre(var)
*   Deja en memoria anio mes <var> (mensual) con el índice general del INPC de
*   la entidad cc (01-32), base 2Q jul 2018, Actualización de Canasta y
*   Ponderadores 2024. El INPC estatal no está en el BIE: se exporta en CSV del
*   programa INPC de INEGI (app/indicesdeprecios, estructura 112001700070 "por
*   entidad federativa"). Las 32 series del índice general van en bloques de 430
*   (una por cada nivel de la canasta): serie = 894950 + (cc-1)*430, verificado
*   contra el título de la exportación para las 32 entidades (16oct2026); el
*   título descargado se vuelve a verificar aquí y se aborta si no coincide.
*   Caché por sesión en raw/temp/AccesoBIE/inpc_<cc>.csv (+ .meta), misma
*   carpeta y disciplina (escritura atómica) que AccesoBIE.
program define AccesoINPCEntidad
	syntax anything(name=clave) , NOMbre(name)
	local clave : di %02.0f `clave'
	local serie = 894950 + (`clave' - 1)*430
	capture mkdir "${SIMROOT}/raw/"
	capture mkdir "${SIMROOT}/raw/temp/"
	capture mkdir "${SIMROOT}/raw/temp/AccesoBIE/"
	local csv "${SIMROOT}/raw/temp/AccesoBIE/inpc_`clave'.csv"
	global INEGI_INPC_ERR ""
	python: inegi_inpc_entidad("`clave'", "`serie'", r"""`csv'""")
	if "$INEGI_INPC_ERR" != "" {
		noisily display as error "AccesoINPCEntidad: $INEGI_INPC_ERR"
		global INEGI_INPC_ERR ""
		exit 459
	}
	import delimited "`csv'", clear varnames(1) encoding(utf-8)
	rename valor `nombre'
	noisily display as text "  INPC entidad " as result "`clave'" as text " | Variable: " as result "`nombre'" as text " | serie `serie' (INEGI/INPC, estructura 112001700070): `=_N' meses, {c u'}ltimo `=anio[_N]'/`=string(mes[_N], "%02.0f")'"
end


python:
import os
import re
import requests
from sfi import Macro

INPC_URL = 'https://www.inegi.org.mx/app/indicesdeprecios/Exportacion.aspx?INPtipoExporta=CSV'
INPC_ESTRUCTURA = '112001700070'
INPC_MESES = {'Ene': 1, 'Feb': 2, 'Mar': 3, 'Abr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Ago': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dic': 12}


def inegi_inpc_entidad(clave, serie, csv_path):
    """Exporta el índice general mensual del INPC de la entidad `clave` desde
    el programa INPC de INEGI y lo cachea en csv_path (anio,mes,valor) + .meta.
    Verifica que el título de la serie sea el índice general de la entidad
    pedida; cualquier falla deja el último caché bueno intacto y publica el
    error en INEGI_INPC_ERR."""
    meta_path = csv_path[:-4] + '.meta'
    if Macro.getGlobal(f'INEGI_INPC_{clave}') == '1' and os.path.exists(csv_path):
        return
    form = {'idEstructura': INPC_ESTRUCTURA, '_formato': 'CSV', '_anioI': '1969', '_anioF': '2099',
            '_meta': '0', '_tipo': 'Niveles', '_info': 'Indices', '_orient': 'vertical', 'esquema': '',
            'cvEstructura': INPC_ESTRUCTURA, 'pf': 'inp', 'cuadro': INPC_ESTRUCTURA, '_series': f'c|{serie},'}
    try:
        response = requests.post(INPC_URL, data=form, timeout=120)
        response.raise_for_status()
        texto = response.content.decode('windows-1252', 'replace')
        if '<html' in texto[:300].lower():
            raise ValueError('la exportación devolvió HTML en lugar de CSV (formato inesperado)')
        titulo, fecha, filas = '', '', []
        for line in texto.splitlines():
            cells = [c.strip().strip('"') for c in line.split('","')]
            if len(cells) >= 2 and cells[0] == 'Título':
                titulo = cells[1]
            fm = re.search(r'Fecha de consulta:\s*([0-9/]+\s+[0-9:]+)', line)
            if fm:
                fecha = fm.group(1)
            mm = re.match(r'^([A-Z][a-z][a-z])\s+(\d{4})$', cells[0]) if cells else None
            if mm and len(cells) >= 2 and mm.group(1) in INPC_MESES:
                valor = cells[1].replace(',', '').strip()
                if valor not in ('', 'ND', 'N/E', '-'):
                    filas.append((int(mm.group(2)), INPC_MESES[mm.group(1)], float(valor)))
        esperado = rf'por entidad federativa, {clave} [^,]+, .ndice de precios al consumidor, por objeto del gasto, .ndice general$'
        if not re.search(esperado, titulo):
            raise ValueError(f'la serie {serie} no es el índice general de la entidad {clave}: "{titulo}"')
        if not filas:
            raise ValueError(f'la serie {serie} no trae observaciones')
        filas.sort()
        tmp = csv_path + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write('anio,mes,valor\n')
            for anio, mes, valor in filas:
                f.write(f'{anio},{mes},{valor!r}\n')
        os.replace(tmp, csv_path)
        with open(meta_path, 'w', encoding='utf-8') as f:
            f.write(f'titulo={titulo}\nfecha_consulta={fecha}\nserie={serie}\nestructura={INPC_ESTRUCTURA}\n')
            f.write(f'ultimo={filas[-1][0]}/{filas[-1][1]:02d}\nn={len(filas)}\nurl={INPC_URL}\n')
        Macro.setGlobal(f'INEGI_INPC_{clave}', '1')
        print(f'  Fuente: INEGI, programa INPC (exportación CSV); consulta {fecha}')
        print(f'  Indicador: {titulo}')
    except Exception as e:
        Macro.setGlobal('INEGI_INPC_ERR', f'INPC entidad {clave} (serie {serie}): {e}; se conserva el último caché.')
end
