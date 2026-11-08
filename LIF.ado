*! version 8.1 CIEP 12sep2026
program define LIF, return
quietly {
	capture mkdir `"${SIMROOT}/users/"'
	capture mkdir `"${SIMROOT}/users/$id/"'
	capture mkdir `"${SIMROOT}/users/$id/graphs/"'
	timer on 4

	** 0.1 Anio valor presente **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	** 0.2 Base LIF **
	capture confirm file "${SIMROOT}/master/LIF.dta"
	if _rc != 0 {
		noisily UpdateLIF
	}



	***************
	*** 1 SYNTAX **
	***************
	use in 1 using "${SIMROOT}/master/LIF.dta", clear
	syntax [if] [, ANIO(int `aniovp' ) BY(varname) ///
		UPDATE NOGraphs Base ///
		MINimum(real 0.5) DESDE(int -1) ///
		EOFP PROYeccion ///
		ROWS(int 1) COLS(int 5) ///
		TITle(string)]

	noisily _log modulo "LIF  ·  ingresos presupuestarios `anio', por `by'" ref("runbook §9")

	* 1.1 Valor año mínimo *
	* desde() debe ser < anio(): si viene igual o mayor (p.ej. Graphs_TE.do corre
	* TasasEfectivas 2001..anioPE y esta llama LIF con desde(2013)), el collapse
	* de las graficas vaciaba el anio y tabstat tronaba con r(2000), y la tabla B
	* dividiria entre nyears = 0 (2026-09-12). Se recae en el default. *
	if `desde' == -1 | `desde' >= `anio' {
		local desde = `anio'-10
	}

	* 1.2 Títulos y fuentes *
	if "`title'" == "" {
		local graphtitle "{bf:Ingresos presupuestarios}"
		local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
	}
	else {
		local graphtitle "{bf:`title'}"
		local graphfuente ""
	}

	** 1.3 Base RAW **
	if "`base'" == "base" {
		use `if' using "${SIMROOT}/master/LIF.dta", clear
		exit
	}

	** 1.4 Valor default `by' **
	if "`by'" == "" {
		local by = "divPE"
	}



	****************
	*** 2. DATOS ***
	****************

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput `update'
	local currency = currency[1]
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local pibYR`anio' = pibYR[`k']
		}
		if anio[`k'] == `desde' {
			local pibYR`desde' = pibYR[`k']
		}
	}
	tempfile PIB
	save `PIB'

	** 2.2 Datos Abiertos **
	capture confirm file "${SIMROOT}/master/DatosAbiertos.dta"
	if _rc != 0 | "`update'" == "update" {
		DatosAbiertos //, update
		local updated = r(updated)
		local ultanio = r(ultanio)
		local ultmes = r(ultmes)
	}
	else {
		local updated = "yes" // r(updated)
	}


	** 2.3 Update LIF **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily UpdateLIF `update'
	}



	***************
	*** 3 Merge ***
	***************
	use "${SIMROOT}/master/LIF.dta", clear
	*drop if nombre == ""
	sort anio mes
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflatorpp lambda var_pibY Poblacion) update replace keep(matched)
	local aniofirst = anio[1]
	local aniolast = anio[_N]

	** 3.1 Utilizar LIF o ILIF **
	if "`proyeccion'" == "proyeccion" {
		replace recaudacion = monto/acum_prom if mes < 12 & divLIF != 10
	}
	if "`eofp'" == "eofp" {
		replace recaudacion = monto if mes < 12
	}
	replace recaudacion = ILIF if mes == .

	** 3.2 Valores como % del PIB **
	foreach k of varlist recaudacion monto LIF ILIF {
		g double `k'PIB = `k'/pibY*100
	}
	g double recaudacionR = recaudacion/deflatorpp
	g double recaudacionPC = recaudacion/Poblacion					// per capita: `currency' por persona (Poblacion de PIBDeflactor)
	egen double recaudacionTOT = sum(recaudacion), by(anio)
	format *PIB %10.3fc
	format recaudacionR recaudacionTOT %20.0fc
	format recaudacionPC %10.0fc



	******************
	*** 4 RESUMIDO ***
	******************
	capture keep `if'
	*keep if anio >= `desde'-1
	tempvar resumido recaudacionPIB
	g resumido = `by'

	capture label copy `by' label
	if _rc != 0 {
		label copy num`by' label
	}
	label values resumido label

	egen `recaudacionPIB' = max(recaudacionPIB) /*if anio >= 2010*/, by(`by')
	replace resumido = 999 if abs(`recaudacionPIB') < `minimum' //| recaudacionPIB == . | recaudacionPIB == 0 //& divCIEP != 15 
	label define label 999 `"Otros (< `=string(`minimum',"%5.1fc")'% PIB)"', add modify

	* Especiales *
	capture replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	capture replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	capture replace nombre = subinstr(nombre,"/","_",.)
	

	*******************************************************************
	** 4. Display: UNA agregacion por anio; el `if' manda en todo.   **
	**    A. Nivel `anio' (MXN, % PIB, % Tot, MXN per capita)
	**    B. Crecimiento `desde'-`anio' (dif % PIB, %G real, elasticidad)
	**    Sin division "resumido" quemada: si el usuario pide solo la
	**    deuda (if divLIF == 10) o la excluye, el comando obedece. Los
	**    totales sin deuda se derivan de la MISMA muestra y solo se
	**    despliegan cuando difieren del total.                          **
	*******************************************************************

	** 4.1 Agregados por `by': anio de referencia y anio base **
	capture tabstat recaudacion recaudacionPIB recaudacionR recaudacionPC if anio == `anio', by(`by') stat(sum) f(%20.0fc) save
	if _rc != 0 {
		noisily _log aviso, tipo(IMPORTANTE) texto("LIF: no hay información para el año `anio'") rojo
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)
	local ngrp = 0
	local k = 1
	while "`=r(name`k')'" != "." {
		local ++ngrp
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local rname`k' `"`=r(name`k')'"'
		local ++k
	}

	* Anio base (desde): matrices indexadas por NOMBRE, no por posicion —
	* una familia puede existir en un anio y no en el otro.
	local haspre = 0
	capture tabstat recaudacionR recaudacionPIB if anio == `desde', by(`by') stat(sum) save
	if _rc == 0 & "`pibYR`desde''" != "" {
		local haspre = 1
		tempname pretot
		matrix `pretot' = r(StatTotal)
		local k = 1
		while "`=r(name`k')'" != "." {
			local key = strtoname(`"`=r(name`k')'"')
			tempname pre_`key'
			matrix `pre_`key'' = r(Stat`k')
			local ++k
		}
	}
	local nyears = `anio'-`desde'

	* Totales sin deuda (misma muestra, sin el `if' quemado): solo si la muestra
	* trae filas que NO son deuda. *
	local hassindeuda = 0
	local showsindeuda = 0
	local crecsd = .
	quietly count if anio == `anio' & divLIF != 10
	if r(N) > 0 {
		local hassindeuda = 1
		tempname sd sdpib sdr sdrpre sdpc
		quietly sum recaudacion if anio == `anio' & divLIF != 10
		scalar `sd' = r(sum)
		quietly sum recaudacionPC if anio == `anio' & divLIF != 10
		scalar `sdpc' = r(sum)
		quietly sum recaudacionPIB if anio == `anio' & divLIF != 10
		scalar `sdpib' = r(sum)
		quietly sum recaudacionR if anio == `anio' & divLIF != 10
		scalar `sdr' = r(sum)
		scalar `sdrpre' = .
		if `haspre' {
			quietly sum recaudacionR if anio == `desde' & divLIF != 10
			if r(N) > 0 scalar `sdrpre' = r(sum)
		}
		* La linea "sin deuda" se despliega solo si difiere del total (la
		* muestra incluye deuda); si el usuario ya la excluyo, seria la misma. *
		local showsindeuda = (abs(`mattot'[1,1] - `sd') > 0.5)
	}

	** 4.2 A. Nivel **
	noisily _log cuadro clear
	noisily _log cuadro col, titulo("Concepto") flex
	noisily _log cuadro col, titulo("`currency'") fmt(%13.3fc) escala(1e9)
	noisily _log cuadro col, titulo("% PIB") fmt(%7.3f)
	noisily _log cuadro col, titulo("% total") fmt(%7.1f)
	noisily _log cuadro col, titulo("Per cápita") fmt(%10.0fc)

	forvalues k = 1/`ngrp' {
		* Display text *
		if substr(`"`rname`k''"',1,31) ==`"'"'' {
			local disptext = substr(`"`rname`k''"',1,30)
		}
		else {
			local disptext = substr(`"`rname`k''"',1,31)
		}
		local name = strtoname(`"`disptext'"')
		local key = strtoname(`"`rname`k''"')

		* Crecimiento real anual (geometrico) desde `desde' *
		local crec = .
		if `haspre' & "`pre_`key''" != "" {
			if `pre_`key''[1,1] != . & `pre_`key''[1,1] != 0 & `mat`k''[1,3] != . {
				local crec = ((`mat`k''[1,3]/`pre_`key''[1,1])^(1/`nyears')-1)*100
			}
		}

		* Returns por grupo (mismo contrato que PEF): LIF REPORTA lo observado
		* en r(); NO escribe escalares globales por grupo. Con by(divSIM) los
		* nombres coinciden con los parametros de escenario del usuario
		* (ISRASPIB, IVAPIB, ...; SIM.do 4.1 / Web.Stata.do 3.1.1) y una segunda
		* corrida de LIF (FiscalGap, TasasEfectivas) los pisaba. Los totales
		* (Ingresos_totales*, Ingresos_sin_deuda*) no colisionan y siguen
		* globales para el libro. *
		return scalar `name' = `mat`k''[1,1]
		return scalar `name'PIB = `mat`k''[1,2]
		return scalar `name'Tot = `mat`k''[1,1]/`mattot'[1,1]*100
		return scalar `name'PC = `mat`k''[1,4]
		if `crec' != . {
			return scalar `name'C = `crec'
		}
		local `by' `"``by'' `name'"'

		noisily _log cuadro fila `"(+) `disptext'"' "`mat`k''[1,1]" "`mat`k''[1,2]" "`mat`k''[1,1]/`mattot'[1,1]*100" "`mat`k''[1,4]"
	}
	return local `by' `"``by''"'

	* Totales *
	local crectot = .
	if `haspre' {						// anidado: Stata evalua A & B completo, y sin anio base `pretot' no existe
		if `pretot'[1,1] != . & `pretot'[1,1] != 0 {
			local crectot = ((`mattot'[1,3]/`pretot'[1,1])^(1/`nyears')-1)*100
		}
	}
	noisily _log cuadro fila "(=) Ingresos totales" "`mattot'[1,1]" "`mattot'[1,2]" "100" "`mattot'[1,4]", sep negrita
	scalar Ingresos_totales = `mattot'[1,1]
	scalar Ingresos_totalesPIB = `mattot'[1,2]
	scalar Ingresos_totalesPC = `mattot'[1,4]
	return scalar Ingresos_totales = `mattot'[1,1]
	return scalar Ingresos_totalesPIB = `mattot'[1,2]
	return scalar Ingresos_totalesPC = `mattot'[1,4]
	if `crectot' != . {
		scalar Ingresos_totalesC = `crectot'
		return scalar Ingresos_totalesC = `crectot'
	}

	if `hassindeuda' {
		if `sdrpre' != . & `sdrpre' != 0 {
			local crecsd = ((`sdr'/`sdrpre')^(1/`nyears')-1)*100
		}
		scalar Ingresos_sin_deuda = `sd'
		scalar Ingresos_sin_deudaPIB = `sdpib'
		scalar Ingresos_sin_deudaPC = `sdpc'
		if `crecsd' != . {
			scalar Ingresos_sin_deudaC = `crecsd'
		}
		if `showsindeuda' {
			noisily _log cuadro fila "(=) Ingresos sin deuda" "`sd'" "`sdpib'" "`sd'/`mattot'[1,1]*100" "`sdpc'", negrita
		}
	}
	noisily _log cuadro print, titulo("A. Ingresos presupuestarios `anio' por `by'") unidad("`currency', miles de millones; per cápita en `currency'") ref("runbook §9")

	** 4.3 B. Crecimiento `desde'-`anio' (solo si hay anio base) **
	if `haspre' {
		local gpib = ((`pibYR`anio''/`pibYR`desde'')^(1/`nyears')-1)*100
		noisily _log cuadro clear
		noisily _log cuadro col, titulo("Concepto") flex
		noisily _log cuadro col, titulo("`desde' % PIB") fmt(%7.3f)
		noisily _log cuadro col, titulo("`anio' % PIB") fmt(%7.3f)
		noisily _log cuadro col, titulo("Dif pp") fmt(%7.3f)
		noisily _log cuadro col, titulo("Crec. real %") fmt(%7.3f)
		noisily _log cuadro col, titulo("Elasticidad") fmt(%7.3f)

		forvalues k = 1/`ngrp' {
			local key = strtoname(`"`rname`k''"')
			if "`pre_`key''" == "" continue
			if `pre_`key''[1,1] == . | `pre_`key''[1,1] == 0 | `mat`k''[1,3] == . continue
			if substr(`"`rname`k''"',1,25) == `"'"' {
				local disptext = substr(`"`rname`k''"',1,24)
			}
			else {
				local disptext = substr(`"`rname`k''"',1,25)
			}
			local g = ((`mat`k''[1,3]/`pre_`key''[1,1])^(1/`nyears')-1)*100
			local e = `g'/`gpib'
			scalar E`key' = `e'
			noisily _log cuadro fila `"(+) `disptext'"' "`pre_`key''[1,2]" "`mat`k''[1,2]" "`mat`k''[1,2]-`pre_`key''[1,2]" "`g'" "`e'"
		}

		noisily _log cuadro fila "(=) Ingresos totales" "`pretot'[1,2]" "`mattot'[1,2]" "`mattot'[1,2]-`pretot'[1,2]" "`crectot'" "`crectot'/`gpib'", sep negrita
		if `crectot' != . {
			escalar pctpib EIngresosTotales = `crectot'/`gpib'
		}
		if `showsindeuda' & `crecsd' != . {
			quietly sum recaudacionPIB if anio == `desde' & divLIF != 10
			noisily _log cuadro fila "(=) Ingresos sin deuda" "r(sum)" "`sdpib'" "`sdpib'-r(sum)" "`crecsd'" "`crecsd'/`gpib'", negrita
		}
		noisily _log cuadro nota "PIB real: `=strtrim(string(`gpib', "%5.3f"))' % anual (`desde'-`anio'); crecimiento real anual geométrico de cada concepto y elasticidad = crecimiento / crecimiento del PIB"
		noisily _log cuadro print, titulo("B. Crecimiento real `desde'-`anio' por concepto") unidad("% del PIB; % anual") ref("runbook §9")
	}


	******************
	* Returns Extras *
	capture tabstat recaudacion recaudacionPIB if anio == `anio' & nombre == "Ingreso de Finanzas Públicas Cuotas a la Seguridad Social (IMSS)", stat(sum) f(%20.1fc) save
	tempname cuotas
	matrix `cuotas' = r(StatTotal)
	escalar custom(%20.0fc) Cuotas_IMSS = `cuotas'[1,1]	// custom: pesos completos: el libro los cita en pesos, /1e6 cambiaria el significado

	capture tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP == 12, stat(sum) by(nombre) f(%20.1fc) save
	
	tempname ieps
	matrix `ieps'1 = r(Stat1)
	scalar Alcohol = `ieps'1[1,1]

	matrix `ieps'2 = r(Stat2)
	scalar AlimNoBa = `ieps'2[1,1]

	matrix `ieps'7 = r(Stat7)
	scalar Juegos = `ieps'7[1,1]
	
	matrix `ieps'6 = r(Stat6)
	scalar Cervezas = `ieps'6[1,1]
	
	matrix `ieps'9 = r(Stat9)
	scalar Tabacos = `ieps'9[1,1]
	
	matrix `ieps'10 = r(Stat10)
	scalar Telecom = `ieps'10[1,1]
	
	matrix `ieps'3 = r(Stat3)
	scalar Energiza = `ieps'3[1,1]

	matrix `ieps'4 = r(Stat4)
	scalar Saboriza = `ieps'4[1,1]

	matrix `ieps'5 = r(Stat5)
	scalar Fosiles = `ieps'5[1,1]



	*******************
	*** 5. Gráficos ***
	*++****++++++++++**
	if "`nographs'" != "nographs" & "$nographs" == "" {
		preserve

		* Normalizar valores a billones *
		*replace recaudacion=recaudacion/deflatorpp/1000000000000
		*replace monto=monto/deflatorpp/1000000000000
		*replace LIF=LIF/deflatorpp/1000000000000

		collapse (sum) recaudacion recaudacionR recaudacionPIB (max) recaudacionTOT pibY deflatorpp if anio >= `desde', by(anio resumido)
		levelsof resumido, local(lev_resumido)
		label values resumido label

		* Guard (2026-09-12): la grafica exige filas de `anio' con % PIB y grupo
		* validos; si no las hay (p.ej. `by' sin asignar en filas nuevas de la
		* ILIF, o pibY sin `anio'), se reporta el diagnostico y se omite la grafica
		* en vez de tronar con r(2000) dentro de tabstat. *
		quietly count if anio == `anio'
		local n_anio = r(N)
		quietly count if anio == `anio' & recaudacionPIB != . & resumido != .
		if r(N) == 0 {
			quietly count if anio == `anio' & resumido == .
			local n_sinby = r(N)
			quietly count if anio == `anio' & recaudacionPIB == .
			local n_sinpib = r(N)
			noisily _log aviso, tipo(Nota) texto("LIF: sin gráfica, `anio' no tiene filas graficables (filas `n_anio'; sin `by' `n_sinby'; sin % PIB `n_sinpib')") ref("runbook §9") rojo
		}
		else {

		* Ciclo para poner los paréntesis (% del total) en el legend *
		tabstat recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		local totlev = 0
		local inten = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')

			local legend`k' : label label `k'
			*local legend`k' = substr("`legend`k''",1,20)
			local legend = `"`legend' label(`totlev' "{bf:`legend`k''}")"'  
			//"(`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)"

			tempvar recaudacionPIB`k' connectedPIB`k' connectedTOT`k'
			egen `recaudacionPIB`k'' = sum(recaudacionPIB) if resumido >= `k', by(anio)
			replace `recaudacionPIB`k'' = 0 if `recaudacionPIB`k'' == .
			label var `recaudacionPIB`k'' "`legend`k''"

			egen `connectedTOT`k'' = sum(recaudacionR), by(anio)
			g `connectedPIB`k'' = recaudacionR/`connectedTOT`k''*100 if resumido == `k'
			format `recaudacionPIB`k'' `connectedPIB`k'' %7.1fc
			* pstyle(p1) finten(`=100-`inten'')
			local extras = `"`extras' (bar `recaudacionPIB`k'' anio if anio <= `anio' & resumido == `k', mlabpos(6) mlabcolor("111 111 111") barwidth(.8)) "'
			if `inten' <= .6 {
				local inten = `inten' + 20
			}
			else {
				local inten = `inten' + 10
			}
		}
		local legend `"`legend' label(`=`totlev'+1' "Recaudación total")"'
		
		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -recaudacion
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
				local order "`order' `=`ordervar'[`k']'"
			}
		}
		sort anio resumido

		tempvar recaudacionbar recaudacionline recaudacionby
		g `recaudacionbar' = recaudacionR
		replace `recaudacionbar' = 0 if `recaudacionbar' == .

		egen `recaudacionby' = sum(recaudacion), by(anio)
		g `recaudacionline' = `recaudacionby'/pibY*100
		format recaudacion* `recaudacionbar' `recaudacionline' `recaudacionby' %15.1fc
		label var `recaudacionline' "Como % del PIB"

		* Información agregada *
		egen recaudacionPIBTOT = sum(recaudacionPIB), by(anio)
		format recaudacionPIBTOT %7.1fc


		***********
		** Texto **
		* Máximo *
		tabstat recaudacionPIBTOT `recaudacionline', stat(max) by(anio) save
		tempname maxPIBTOT
		matrix `maxPIBTOT' = r(StatTotal)

		* Final *
		tabstat recaudacionPIBTOT if anio == `anio', stat(max) save by(anio)
		tempname finPIBTOT
		matrix `finPIBTOT' = r(StatTotal)

		* Inicial y cambios: solo si la muestra tiene el anio `desde' (con un
		* `if' acotado — p.ej. divCIEP == 8 — puede no existir). *
		local b1title ""
		capture tabstat recaudacionPIBTOT if anio == `desde', stat(max) save by(anio)
		if _rc == 0 {
			tempname iniPIBTOT
			matrix `iniPIBTOT' = r(StatTotal)
			if (`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]) > 0 {
				local cambio = "aumentó"
			}
			else {
				local cambio = "disminuyó"
			}
			local b1title `"De `desde' a `anio', la {bf:recaudación `cambio' `=string(abs(`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]),"%7.1fc")'} puntos porcentuales del PIB."'
		}

		graph bar recaudacionPIB if anio <= `anio', ///
			over(resumido, sort(1) descending) over(anio, gap(25)) ///
			stack asyvars blabel(bar, format(%7.1fc) size(medsmall)) outergap(0) ///
			name(ingresos`by'PIB, replace) ///
			title("`graphtitle'") ///
			ylabel(, format(%7.1fc) labsize(small)) ///
			ytitle("% PIB") ///
			blabel(bar, format(%5.1fc)) ///
			legend(on position(6) rows(`rows') cols(`cols') /*`legend' order(`order')*/ justification(left)) ///
			/// Added text 
			///text(`=recaudacionPIBTOT[1]' `=anio[1]' "{bf:% PIB}", placement(6)) ///
			///text(`=`recaudacionline'[1]' `=anio[1]' "{bf:% LIF}", placement(6) yaxis(2)) ///
			///caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de SHCP/EOFP, INEGI/BIE y $paqueteEconomico.") ///
			b1title(`"`b1title'"')

		/*grc1leg ///
		///graph combine ///
		ingresos`by'PIB ingresosMXN`by' , ///
			title("{bf:`graphtitle'}") ///
			name(ingresos`by', replace) xcommon */

		*capture window manage close graph ingresosMXN`by'
		*capture window manage close graph ingresos`by'PIB
	
		graph save ingresos`by'PIB "${SIMROOT}/users/$id/graphs/ingresos`by'PIB", replace
		if "$export" != "" {
			graph export "$export/ingresos`by'PIB.png", as(png) name("ingresos`by'PIB") replace
		}
		}
		*restore
	}



	***********
	*** END ***
	***********
	capture drop __*
	timer off 4
	timer list 4
	noisily _log tiempo, timer(4) texto("LIF")
}
end



*************************
****                 ****
**** UpdateLIF.do    ****
**** De .xlsx a .dta ****
****                 ****
*************************
program define UpdateLIF

	args update

	************************
	*** 1. BASE DE DATOS ***
	************************
	ensure_asset, dir(raw/LIFs)			// todo lo que el manifest declare bajo raw/LIFs/ (hoy LIFs.xlsx)
	import excel "${SIMROOT}/raw/LIFs/LIFs.xlsx", clear firstrow
	foreach k of varlist _all {
		capture confirm string variable `k'
		if _rc == 0 {
			if `k'[1] == "" {
				drop `k'
			}
		}
		else {
			if `k'[1] == . {
				drop `k'
			}
		}
	}
	drop if numdivLIF == .

	** Encode **
	foreach k of varlist div* {
		capture confirm variable num`k'
		if _rc == 0 {
			capture which labmask
			if _rc != 0 {
				net install http://fmwww.bc.edu/RePEc/bocode/l/labutil.pkg
			}
			labmask num`k', values(`k')
			drop `k'
			rename num`k' `k'
			continue
		}
		rename `k' `k's
		encode `k's, gen(`k')
		drop `k's
	}
	order div* concepto
	destring LIF*, replace
	reshape long LIF ILIF, i(div* concepto serie) j(anio)
	format div* LIF* ILIF* %20.0fc
	format concepto %30s



	*******************************
	*** 2. SHCP: Datos Abiertos ***
	*******************************
	preserve
	levelsof serie, local(serie)
	foreach k of local serie {
		if "`k'" != "NA" {
			noisily DatosAbiertos `k', nog zipfile

			rename clave_de_concepto serie
			keep anio serie nombre monto mes acum_prom

			tempfile `k'
			quietly save ``k''
		}
	}
	restore


	** 2.1.1 Append **
	collapse (sum) LIF ILIF, by(div* serie anio)
	foreach k of local serie {
		if "`k'" != "NA" {
			joinby (anio serie) using ``k'', unmatched(both) update
			drop _merge
		}
	}
	rename serie series
	encode series, generate(serie)
	drop series


	** 2.1.2 Fill the blanks **
	forvalues j=1(1)`=_N' {
		foreach k of varlist div* nombre serie {
			capture confirm numeric variable `k'
			if _rc == 0 {
				if `k'[`j'] != . {
					quietly replace `k' = `k'[`j'] if `k' == . & serie == serie[`j'] & serie[`j'] != .
				}
			}
			else {
				if `k'[`j'] != "" {
					quietly replace `k' = `k'[`j'] if `k' == "" & serie == serie[`j'] & serie[`j'] != .
				}
			}
		}
	}



	**************************************
	** Recaudacion observada y estimada **
	capture confirm variable monto
	if _rc == 0 {
		g recaudacion = monto if mes == 12									// Se reemplazan con lo observado
		g concepto = nombre
	}
	else {
		g monto = .
		g recaudacion = .
		g concepto = ""
	}

	replace recaudacion = LIF if mes != 12
	replace recaudacion = ILIF if recaudacion == . & LIF == . & ILIF != .			// De lo contrario, es ILIF
	format recaudacion %20.0fc

	capture order div* nombre serie anio LIF ILIF monto
	compress
	sort div* nombre serie anio
	capture mkdir "${SIMROOT}/master/"
	save "${SIMROOT}/master/LIF.dta", replace
end
