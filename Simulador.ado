*! version 2.0.0  CIEP 03oct2026
*! Simulador — perfil, incidencia, ciclo de vida y proyección de una variable per cápita,
*! con bootstrap por diseño muestral (UPM dentro de estrato) en Mata.
*
* NOTA METODOLÓGICA (bootstrap, v2.0)
* -----------------------------------
* Qué calcula por réplica: el total (REC), contribuyentes (FOR), población (POB) y
* per cápita del hombre de 40 años; el perfil por edad y sexo (PERF); la incidencia
* por decil de hogares (INCI); el ciclo de vida sexo×edad×decil (CICLO) y la
* proyección demográfica del total (REC, con las poblaciones de CONAPO). Son sumas
* ponderadas por grupo: en Mata cada réplica cuesta milisegundos. Hasta v1.x cada
* réplica corría PERF/INCI/CICLO/REC como programas con preserve/collapse/restore
* sobre la base completa (~4 s por réplica en una base de 217 variables; B=100 ×
* 20 variables ≈ 2-3 h). Los cinco archivos de salida conservan su esquema porque
* los leen Perfiles.ado, FiscalGap.ado y CuentasGeneracionales.ado.
*
* Unidad de remuestreo (cluster()): la ENIGH muestrea viviendas en UPM dentro de
* estratos de diseño (upm, est_dis en concentrado.dta). Default `cluster(upm)`:
* dentro de cada estrato se sortean con reemplazo tantas UPM como tiene, y el peso
* de cada persona se multiplica por las veces que salió su UPM (es lo que hace
* `bsample, strata(est_dis) cluster(upm)`). Si la base no trae upm/est_dis se
* traen de raw/ENIGH/<anio>/concentrado.dta; si tampoco existe, se cae a
* `cluster(hogar)`. `cluster(persona)` es lo que hacía v1.x (`bsample _N`):
* remuestrear individuos ignora que las personas de un hogar van juntas y
* subestima la varianza.
*
* Inferencia: el estimador puntual es el de la MUESTRA COMPLETA (pesos originales;
* réplica 0, que no se guarda en los archivos); el error estándar es la desviación
* estándar de las B réplicas; el IC 95% se reporta normal (±1.96·EE) y percentil
* (2.5, 97.5). Hasta v1.x el puntual era la media de las réplicas y el "IC" salía
* de `ci means` sobre ellas: eso es el intervalo de la MEDIA de las réplicas
* (ancho ∝ sd/√B), que se encoge con B y tiende a cero —subestimaba el intervalo
* por un factor √B (3.2× con B=10, 10× con B=100).
*
* Con bootstrap(1) no hay remuestreo: una sola pasada con los pesos originales, y
* los archivos salen idénticos a los de v1.x (test dorado). Es el modo del sitio
* en producción. legacy corre el bloque v1.x completo (lento) para comparaciones.

program define Simulador, rclass
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
quietly {
	timer on 7
	syntax varname [if] [fweight/], ///
		[BOOTstrap(int 1) ///
		NOGraphs NOOutput REboot Noisily ///
		BANDwidth(int 5) ///
		MACro(string) ///
		POBlacion(string) FOLIO(string) ///
		NOKernel POBGraph ANIOVP(int -1) ANIOPE(int -1) TITLE(string) TEXTBOOK ///
		CLuster(string) SEed(int 1111) LEGacy]





	*******************
	*** 0. Defaults ***
	*******************
	if `aniovp' == -1 {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}
	if `aniope' == -1 {
		local aniope = `aniovp'
	}
	local base = "ENIGH `=anioenigh'"


	** 0.1 Macros: PIB **
	preserve
	PIBDeflactor, anio(`aniovp') nographs nooutput
	tempfile PIBBASE
	save `PIBBASE'

	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniope' {
			local PIB = pibY[`k']
			local deflator = deflator[`k']
			continue, break
		}
	}
	restore


	** 0.2 Macros: Poblacion **
	if "`poblacion'" == "" {
		local poblacion = "poblacion"
	}


	** 0.3 Texto introductorio **
	if "`notitle'" == "" {
		local title : variable label `varlist'
	}
	local nombre `"`=subinstr("`varlist'","_","",.)'"'
	noisily di _newline(2) in g "  {bf:Variable label: " in y "`title'}"
	noisily di in g "  {bf:Variable name: " in y "`varlist'}"
	if "`if'" != "" {
		noisily di in g "  {bf:If: " in y `"`if'}"'
	}
	else {
		noisily di in g "  {bf:If: " in y "Sin restricci{c o'}n. Todas las observaciones utilizadas.}"	
	}
	noisily di in g "  {bf:Bootstraps: " in y `bootstrap' "}" _newline


	** Variable en valor presente **
	replace `varlist' = `varlist'/`deflator'

	capture confirm variable ingbrutotot
	tempvar ingreso
	if _rc != 0 {
		g double `ingreso' = `varlist'
		local rellabel "[Sin variable de ingreso total]"
		label var `ingreso' "[Sin variable de ingreso total]"
	}
	else {
		g double `ingreso' = ingbrutotot
		local rellabel : variable label ingbrutotot
		label var `ingreso' "`rellabel'"
	}
	replace `ingreso' = `ingreso'/`deflator'

	tempfile original
	save `original', replace



	************************
	*** 1. Archivos POST ***
	************************
	capture confirm file `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'REC.dta"'
	if "`reboot'" == "reboot" | _rc != 0 {


		capture mkdir `"${SIMROOT}/users/"'
		capture mkdir `"${SIMROOT}/users/$id/"'
		capture mkdir `"${SIMROOT}/users/$id/graphs/"'
		capture mkdir `"${SIMROOT}/users/$id/bootstraps/"'
		capture mkdir `"${SIMROOT}/users/$id/bootstraps/`bootstrap'"'
		local dirboot `"${SIMROOT}/users/$id/bootstraps/`bootstrap'"'

		if "`legacy'" == "legacy" {
			*** Bloque v1.x: PERF/INCI/CICLO/REC con preserve/collapse por réplica (lento; comparaciones) ***
			******************************
			** 1.1 Variables de control **
			tempvar cont boot
			g double `cont' = 1
			g `boot' = .


			******************
			** 1.2 Archivos **
			capture mkdir `"${SIMROOT}/users/"'
			capture mkdir `"${SIMROOT}/users/$id/"'
			capture mkdir `"${SIMROOT}/users/$id/graphs/"'
			capture mkdir `"${SIMROOT}/users/$id/bootstraps/"'
			capture mkdir `"${SIMROOT}/users/$id/bootstraps/`bootstrap'"'


			** Per c{c a'}pita **
			postfile PC double(estimacion contribuyentes poblacion montopc edad40) ///
				using `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PC"', replace


			** Perfiles **
			postfile PERF edad double(perfil1 perfil2 contribuyentes1 contribuyentes2 ///
				estimacion1 estimacion2 pobcont1 pobcont2 poblacion1 poblacion2) ///
				using `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PERF"', replace


			** Incidencia por hogares **
			postfile INCI decil double(xhogar distribucion incidencia hogares) ///
				using `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'INCI"', replace


			** Ciclo de vida **
			postfile CICLO bootstrap sexo edad decil double(poblacion `varlist') ///
				using `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'CICLO"', replace


			** Proyecciones **
			postfile REC str30 (modulo) int (bootstrap anio aniobase) ///
				double (estimacion contribuyentes poblacion montopc ///
				contribuyentes_Hom contribuyentes_Muj ///
				contribuyentes_0_24 contribuyentes_25_49 ///
				contribuyentes_50_74 contribuyentes_75_mas) ///
				using `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'REC"', replace



			*******************
			** 1.3 Bootstrap **
			set seed 1111
			forvalues k = 1(1)`bootstrap' {
				if `bootstrap' != 1 {
					noisily di in y . _cont
					bsample _N, w(`boot')
				}
				else {
					replace `boot' = 1
				}

				** 1.3.1. Monto per capita **
				** Recaudacion **
				tempname REC
				capture tabstat `varlist' [`weight' = `exp'*`boot'] `if', stat(sum) f(%20.2fc) save
				if _rc == 0 {
					matrix `REC' = r(StatTotal)
				}
				else {
					matrix `REC' = J(1,1,0)
				}

				** Recaudacion, Edad 40, Hombres **
				tempname REC40
				if "`if'" != "" {
					local if40 = "`if' & edad == 40 & sexo == 1"
				}
				else {
					local if40 = "if edad == 40 & sexo == 1"
				}
				capture tabstat `varlist' [`weight' = `exp'*`boot'] `if40', stat(sum) f(%20.2fc) save
				if _rc == 0 {
					matrix `REC40' = r(StatTotal)
				}
				else {
					matrix `REC40' = J(1,1,0)
				}

				** Contribuyentes **
				tempname FOR
				capture tabstat `cont' [`weight' = `exp'*`boot'] `if', stat(sum) f(%12.0fc) save
				if _rc == 0 {
					matrix `FOR' = r(StatTotal)
				}
				else {
					matrix `FOR' = J(1,1,0)
				}

				** Poblacion **
				tempname POB
				capture tabstat `cont' [`weight' = `exp'*`boot'], stat(sum) f(%12.0fc) save
				if _rc == 0 {
					matrix `POB' = r(StatTotal)
				}
				else {
					matrix `POB' = J(1,1,0)
				}

				** Poblacion, Edad 40, Hombres **
				tempname POB40
				capture tabstat `cont' [`weight' = `exp'*`boot'] `if40', stat(sum) f(%12.0fc) save
				if _rc == 0 {
					matrix `POB40' = r(StatTotal)
				}
				else {
					matrix `POB40' = J(1,1,0)
				}

				** Monto per capita promedio **
				if `FOR'[1,1] != 0 {
					local montopc = `REC'[1,1]/`FOR'[1,1]
				}
				else {
					local montopc = 0
				}

				** Mata: PC **
				local edad40 = `REC40'[1,1]/`POB40'[1,1]
				if `edad40' == . | `edad40' == 0 {
					local pc = `montopc'
				}
				else {
					local pc = `edad40'
				}
				mata: PC = `pc'

				* Desplegar estadisticos *
				`noisily' di in y "  montopc (`aniobase')"
				`noisily' di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]
				`noisily' di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `POB'[1,1]
				`noisily' di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %25.0fc `FOR'[1,1]
				`noisily' di in g "  Per c{c a'}pita (contr./benef.):" _column(40) in y %25.0fc `montopc'
				`noisily' di in g "  Edad 40 (poblaci{c o'}n):" _column(40) in y %25.0fc `edad40'

				* Guardar resultados POST *
				post PC (`REC'[1,1]) (`FOR'[1,1]) (`POB'[1,1]) (`montopc') (`REC40'[1,1]/`POB40'[1,1])


				*** 1.3.2. Perfiles ***
				`noisily' PERF `varlist' `if' [`weight' = `exp'*`boot'], montopc(`pc') post


				*** 1.3.3. Incidencia por hogar **/
				tempvar decil
				capture confirm variable decil
				if _rc != 0 {
					noisily di _newline in g "{bf:  No hay variable: " in y "decil" in g ". Se cre{c o'} con: " in y "`varlist'" in g ".}"
					xtile `decil' = `varlist' [`weight' = `exp'*`boot'], n(10)
				}
				else {
					g `decil' = decil
				}

				preserve
				`noisily' INCI `varlist' `if' [`weight' = `exp'*`boot'], folio(folioviv foliohog) n(`decil') relativo(`ingreso') post
				restore


				*** 1.3.4. Ciclo de Vida ***/
				`noisily' CICLO `varlist' `if' [`weight' = `exp'*`boot'], post boot(`k') decil(`decil')


				*** 1.3.5. Proyecciones ***
				`noisily' REC `varlist', post pob(`poblacion') boot(`k') aniobase(`aniope') title(`title')
			}


			***********************
			*** 1.4. Post close ***
			postclose PC
			postclose PERF
			postclose INCI
			postclose CICLO
			postclose REC
		}
		else {
			***********************************************
			** 1.A Motor Mata: una extracción, B réplicas **
			***********************************************
			tempvar cond hhid cluid estid sexon decilv
			g byte `cond' = 0
			replace `cond' = 1 `if'
			egen long `hhid' = group(folioviv foliohog)

			* sexo numérico (en algunas bases es str1)
			capture confirm string variable sexo
			if _rc == 0 {
				g byte `sexon' = real(sexo)
			}
			else {
				g byte `sexon' = sexo
			}

			* Unidad de remuestreo: upm (default) dentro de est_dis; hogar; persona
			if "`cluster'" == "" local cluster upm
			if "`cluster'" == "upm" {
				capture confirm variable upm est_dis
				if _rc != 0 {
					capture confirm file `"${SIMROOT}/raw/ENIGH/`=anioenigh'/concentrado.dta"'
					if _rc == 0 {
						merge m:1 (folioviv foliohog) using `"${SIMROOT}/raw/ENIGH/`=anioenigh'/concentrado.dta"', ///
							nogen keepusing(upm est_dis) keep(master match)
					}
				}
				capture confirm variable upm est_dis
				if _rc != 0 {
					noisily di in g "  {bf:cluster(upm)}: la base no trae upm/est_dis ni hay concentrado.dta; se remuestrea por {bf:hogar}."
					local cluster hogar
				}
			}
			if "`cluster'" == "upm" {
				egen long `cluid' = group(upm)
				egen long `estid' = group(est_dis)
				qui summ `cluid'
				replace `cluid' = r(max) + `hhid' if `cluid' == .		// hogares sin UPM: su propio cluster
				qui summ `estid'
				replace `estid' = r(max) + 1 if `estid' == .
				qui summ `estid'
				local clutext "UPM dentro de estrato (`=string(r(max))' estratos)"
			}
			else if "`cluster'" == "hogar" {
				g long `cluid' = `hhid'
				g byte `estid' = 1
				local clutext "hogares"
			}
			else if "`cluster'" == "persona" {
				g long `cluid' = _n
				g byte `estid' = 1
				local clutext "personas (como v1.x)"
			}
			else {
				noisily di as err "Simulador: cluster() debe ser upm, hogar o persona"
				exit 198
			}
			if `bootstrap' > 1 noisily di in g "  {bf:Remuestreo: " in y "`clutext'" in g ". Semilla: " in y "`seed'" in g ".}"

			* Deciles: la variable decil si existe; si no, xtile ponderado por réplica (en Mata)
			capture confirm variable decil
			if _rc == 0 {
				g `decilv' = decil
				local decilvar `decilv'
			}
			else {
				noisily di _newline in g "{bf:  No hay variable: " in y "decil" in g ". Se cre{c o'} con: " in y "`varlist'" in g " (xtile ponderado, por r{c e'}plica).}"
				local decilvar ""
			}

			* Poblaciones proyectadas (una sola vez): matrices edad × año, hombres y mujeres
			tempname HOM MUJ
			preserve
			use if entidad == "Nacional" using `"${SIMROOT}/master/$pais/Poblacion.dta"', clear
			sort anio
			local anio0 = anio in 1
			keep `poblacion' edad sexo anio
			reshape wide `poblacion', i(edad sexo) j(anio)
			mkmat `poblacion'* if sexo == 1, matrix(`HOM')
			mkmat `poblacion'* if sexo == 2, matrix(`MUJ')
			restore

			* Réplicas en Mata
			if `bootstrap' != 1 noisily di in y "  bootstrap: " _cont
			mata: simboot_run("`varlist'", "`exp'", "edad", "`sexon'", "`cond'", "`hhid'", "`cluid'", "`estid'", ///
				"`decilvar'", "`ingreso'", `bootstrap', `seed', "`HOM'", "`MUJ'", `anio0', `aniope')
			if `bootstrap' != 1 noisily di

			* Estimadores puntuales (réplica 0) para las secciones 2 y 4
			tempname REC
			matrix `REC' = J(1,1,SIM_PC0[1,1])

			* Escribir los cinco archivos con el esquema de los postfile de v1.x
			preserve
			clear
			mata: simboot_write("PC")
			save `"`dirboot'/`varlist'PC"', replace
			clear
			mata: simboot_write("PERF")
			save `"`dirboot'/`varlist'PERF"', replace
			clear
			mata: simboot_write("INCI")
			save `"`dirboot'/`varlist'INCI"', replace
			clear
			mata: simboot_write("CICLO")
			rename y `varlist'
			save `"`dirboot'/`varlist'CICLO"', replace
			clear
			mata: simboot_write("REC")
			replace modulo = "`title'"
			save `"`dirboot'/`varlist'REC"', replace
			clear
			mata: simboot_write("PT")
			save `"`dirboot'/`varlist'PT"', replace
			restore
			mata: simboot_clear()
		}
	}

	if "`clutext'" == "" local clutext "`cluster'"
	* Puntuales: si el loop no corrió (archivos existentes), del archivo PT; si no existe, media de réplicas
	capture confirm matrix SIM_PC0
	if _rc != 0 {
		capture confirm file `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PT.dta"'
		if _rc == 0 {
			preserve
			use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PT.dta"', clear
			mkmat estimacion contribuyentes poblacion montopc edad40 in 1, matrix(SIM_PC0)
			mkmat decil xhogar distribucion incidencia hogares if decil < ., matrix(SIM_INCI0)
			restore
		}
	}
	capture confirm matrix SIM_PC0
	local haypt = (_rc == 0)
	capture confirm matrix `REC'
	if _rc != 0 {
		tempname REC
		if `haypt' matrix `REC' = J(1,1,SIM_PC0[1,1])
	}


	noisily di _newline in y "  Simulador.ado" in g " (post-bootstraps)"


	**************************
	*** 2 Monto per capita ***
	**************************
	use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PC"', clear


	***********************************
	*** 2.1. Intervalo de confianza ***
	* simci: puntual = muestra completa (réplica 0); EE = sd de las réplicas; IC normal
	* y percentil. Con bootstrap(1) no hay EE (un solo valor).
	if `bootstrap' > 1 {
		noisily di _newline in g "  Estimadores puntuales con la muestra completa; EE e IC 95% (percentil) bootstrap: B = `bootstrap', remuestreo por `clutext'."
		noisily di in g "  (EE: +/- 1.96·EE relativo al puntual.)"
	}
	else {
		noisily di _newline in g "  Estimadores con la muestra completa (B = 1: sin error est{c a'}ndar; use bootstrap(#) para IC)."
	}
	if `haypt' local pt0 point(`=SIM_PC0[1,1]')
	noisily simci estimacion, `pt0' label("Monto:") fmt(%20.0fc)
	return scalar monto = r(mean)
	return scalar monto_se = r(se)


	*******************************
	*** 2.2 Resultados globales ***
	local RECT = r(mean)/`PIB'*100
	escalar pctpib `varlist'GPIB = `RECT'

	if `haypt' local pt0 point(`=SIM_PC0[1,2]')
	noisily simci contribuyentes, `pt0' label("Contribuyentes/Beneficiarios:") fmt(%20.0fc)
	local POBCONTT = r(mean)*`bootstrap'

	if `haypt' local pt0 point(`=SIM_PC0[1,3]')
	noisily simci poblacion, `pt0' label("Poblaci{c o'}n potencial:") fmt(%20.0fc)

	if `haypt' local pt0 point(`=SIM_PC0[1,4]')
	noisily simci montopc, `pt0' label("Per c{c a'}pita:") fmt(%20.0fc)
	return scalar montopc = r(mean)
	return scalar montopc_se = r(se)

	if `haypt' local pt0 point(`=SIM_PC0[1,5]')
	noisily simci edad40, `pt0' label("Edad 40:") fmt(%20.0fc)
	local edad40_boot = r(mean)

	* Y label *
	if `edad40_boot' == . | `edad40_boot' == 0 {
		local ylabelpc = "Promedio"
		*local ylabelpc = "Average"
	}
	else {
		local ylabelpc = "hombre de 40 a{c n~}os"
		*local ylabelpc = "40-year-old male"
	}


	******************
	*** 3 Perfiles ***
	******************
	use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PERF"', clear


	*************************
	** 3.1 Texto bootstrap **
	if `bootstrap' > 1 {
		local boottext " Bootstraps: `bootstrap'."
	}


	***********************************
	** 3.2 Variables de los perfiles **
	if "$pais" != "" {
		local pais = ". ${pais}."
	}
	else {
		local pais = ""
	}

	/* Sin kernel *
	if "`nokernel'" == "nokernel" & "$nographs" != "nographs" & "`nographs'" != "nographs" {

		twoway line perfil1 edad, ///
			name(PerfilH`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalente) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")

		twoway line perfil2 edad, ///
			name(PerfilM`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalente) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")

		twoway line contribuyentes1 edad, ///
			name(ContH`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")

		twoway line contribuyentes2 edad, ///
			name(ContM`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
	}

	* Con kernel *
	else if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		lpoly perfil1 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(2) ///
			name(PerfilH`varlist', replace) generate(perfilH) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalent) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph

		lpoly perfil2 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(2) ///
			name(PerfilM`varlist', replace) generate(perfilM) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalent) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph

		lpoly contribuyentes1 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(2) ///
			name(ContH`varlist', replace) generate(contH) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph

		lpoly contribuyentes2 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(2) ///
			name(ContM`varlist', replace) generate(contM) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph
	}

	if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		graph save PerfilH`varlist' `"${SIMROOT}/users/$id/graphs/PerfilH`varlist'"', replace
		graph save PerfilM`varlist' `"${SIMROOT}/users/$id/graphs/PerfilM`varlist'"', replace
		graph save ContH`varlist' `"${SIMROOT}/users/$id/graphs/ContH`varlist'"', replace
		graph save ContH`varlist' `"${SIMROOT}/users/$id/graphs/ContH`varlist'"', replace
	}


	**********************/
	*** 4. Incidencia *****
	***********************
	use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'INCI"', clear
	format xhogar %15.1fc
	format distribucion %6.1fc
	format incidencia %6.1fc

	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nac"
	label values decil deciles


	**********************
	*** 4.1. Por hogar ***
	levelsof decil, local(deciles)
	noisily di _newline in g "  Decil" _column(20) %20s "Por hogar"
	local j = 2
	foreach k of local deciles {
		local pt0
		if `haypt' local pt0 point(`=SIM_INCI0[`k',2]')
		noisily simci xhogar if decil == `k', `pt0' label("`: label deciles `k''") col(20) fmt(%20.0fc)
		local decil2 : label deciles `k'
		* pesos por hogar: familia micro del catalogo (mxnpc %10.0fc) *
		escalar mxnpc `varlist'`decil2' = r(mean)

		if "$output" == "output" {
			local incd = `"`incd' `=string(`varlist'`decil2',"%10.0f")',"'
		}
	}
	


	*************************
	*** 4.2. Distribucion ***
	noisily di _newline in g "  Decil" _column(20) %20s "Distribuci{c o'}n"
	foreach k of local deciles {
		local pt0
		if `haypt' local pt0 point(`=SIM_INCI0[`k',3]')
		noisily simci distribucion if decil == `k', `pt0' label("`: label deciles `k''") col(20) fmt(%20.1fc)
		local decil2 : label deciles `k'
		escalar pct dis`varlist'`decil2' = r(mean)

		if "$output" == "output" {
			local incd2 = "`incd2' `=string(`=dis`varlist'`decil2'',"%10.1f")',"
		}
	}
	



	***********************
	*** 4.3. Incidencia ***
	noisily di _newline in g "  Decil" _column(20) %20s "Incidencia (% `rellabel')"
	foreach k of local deciles {
		local pt0
		if `haypt' local pt0 point(`=SIM_INCI0[`k',4]')
		noisily simci incidencia if decil == `k', `pt0' label("`: label deciles `k''") col(20) fmt(%20.1fc)
		if r(mean) == . {
			continue
		}
		local decil2 : label deciles `k'
		escalar pct inc`varlist'`decil2' = r(mean)

		if "$output" == "output" {
			local incd3 = "`incd3' `=string(`=inc`varlist'`decil2'',"%10.1f")',"
		}
	}


	if "$output" != "" & "`nooutput'" == "" {
		local lengthINCD = strlen("`incd'")
		local lengthINCD2 = strlen("`incd2'")
		local lengthINCD3 = strlen("`incd3'")
		capture log on output
		noisily di in w "INCD: [`=substr("`incd'",1,`=`lengthINCD'-1')']"
		noisily di in w "INCD2: [`=substr("`incd2'",1,`=`lengthINCD2'-1')']"
		noisily di in w "INCD3: [`=substr("`incd3'",1,`=`lengthINCD3'-1')']"
		capture log off output
	}



	***********************/
	*** 5. CICLO DE VIDA ***
	************************
	use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'CICLO"', clear

	* Labels *
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nac"
	label values decil deciles

	//label define sexo 1 "Hombres" 2 "Mujeres"
	label define sexo 1 "Men" 2 "Women"
	label values sexo sexo



	***********************************
	*** 5.1 Piramide de la variable ***
	poblaciongini `varlist', title("`title'") nombre(`nombre') ///
		boottext(`boottext') rect(`RECT') base(`base') graphs id($id) pib(`PIB') `nooutput' `nographs'



	**********************
	*** 6. RECAUDACION ***
	**********************
	use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'REC"', clear
	capture confirm matrix `REC'
	if _rc != 0 {
		* sin puntual disponible (archivos previos a v2.0): total como media de las réplicas del PC
		tempname REC
		preserve
		use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PC"', clear
		qui summ estimacion
		matrix `REC' = J(1,1,r(mean))
		restore
	}
	if `bootstrap' > 1 & "`legacy'" != "legacy" {
		* Cada réplica se ancla a SU total muestral (PC.estimacion, misma fila que bootstrap)
		tempvar base ajuste pcest
		preserve
		use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'PC"', clear
		keep estimacion
		rename estimacion `pcest'
		gen int bootstrap = _n
		tempfile pcb
		save `pcb'
		restore
		merge m:1 bootstrap using `pcb', nogen keep(master match)
		gen double `base' = estimacion if anio == aniobase
		bys bootstrap (anio): egen double `ajuste' = max(`base')
		replace estimacion = estimacion*`pcest'/`ajuste'
		drop `pcest'
	}
	else {
		forvalues k=1(1)`=_N' {
			if anio[`k'] == aniobase[`k'] {
				local ajuste = `REC'[1,1]/estimacion[`k']
				continue, break
			}
		}
		replace estimacion = estimacion*`ajuste'
	}
	save `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'REC"', replace

	
	ProyGraph `varlist' "`title'" `aniope' `bootstrap' `nographs'

	******************************
	*** 7. Gráficas combinadas ***
	/******************************
	if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		graph combine `=substr("`varlist'",1,10)'_dec `varlist'Proj, ///
			name(`=substr("`varlist'",1,10)'_`aniope'S, replace) ///
			title("{bf:`title'}") ///
			subtitle(" Per cápita (MXN `aniovp') y proyección demográfica (billones MXN `aniovp')", margin(bottom)) ///
			///subtitle(" Age profile (PPP `aniovp') and demographic projection (% GDP)", margin(bottom)) ///
			///title("`title' {bf:profile}") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/`base', INEGI/BIE, CONAPO y SHCP.") ///
			///note(`"Nota: Porcentajes entre par{c e'}ntesis representan la concentraci{c o'}n en cada grupo."') ///
			///caption("{bf:Source}: Prepared by CIEP, using data from `base'.") ///
			///note(`"{bf:Note}: Percentages in parentheses show the concentration in each group."')

		graph export `"${SIMROOT}/users/$id/graphs/`varlist'_`aniope'S.png"', replace name(`=substr("`varlist'",1,10)'_`aniope'S)

		*capture window manage close graph `=substr("`varlist'",1,10)'_dec
		capture window manage close graph `varlist'Proj
	}


	************/
	*** Final ***
	*************
	use `original', clear
	capture matrix drop SIM_PC0 SIM_INCI0

	timer off 7
	timer list 7
	noisily di _newline in g "  {bf:`title' time}: " in y round(`=r(t7)/r(nt7)',.1) in g " segs."
}
end



*****************
*** Poblacion ***
*****************
program poblaciongini
	version 13.1
	syntax varname, NOMbre(string) PIB(real) ///
		[TITle(string) Rect(real 100) BOOTtext(string) BASE(string) Graphs ID(string) NOOutput NOGraphs]


	*************************
	*** 1. Variable total ***
	tabstat `varlist', stat(sum) save
	tempname GTOT
	matrix `GTOT' = r(StatTotal)


	******************
	*** 2. Deciles ***
	levelsof decil, local(deciles)
	foreach k of local deciles {
		tabstat `varlist' if decil == `k', stat(sum) save
		tempname GDEC
		matrix `GDEC' = r(StatTotal)
		local gdeclab`k' = `GDEC'[1,1]/`GTOT'[1,1]*100
	}

	* Labels *
	tempvar grupo
	g `grupo' = 1 if decil <= 5
	replace `grupo' = 2 if decil > 5 & decil < 10
	replace `grupo' = 3 if decil == 10

	tempname grupoval
	label define `grupoval' 1 `"{bf:I-V}: `=string(`gdeclab1'+`gdeclab2'+`gdeclab3'+`gdeclab4'+`gdeclab5',"%7.0fc")'%"' ///
		2 `"{bf:VI-IX}: `=string(`gdeclab6'+`gdeclab7'+`gdeclab8'+`gdeclab9',"%7.0fc")'%"' ///
		3 `"{bf:X}: `=string(`gdeclab10',"%7.0fc")'%"'
	label values `grupo' `grupoval'
	label var `grupo' "deciles"
	escalar pct `varlist'GIV = `gdeclab1'+`gdeclab2'+`gdeclab3'+`gdeclab4'+`gdeclab5'
	escalar pct `varlist'GVIIX = `gdeclab6'+`gdeclab7'+`gdeclab8'+`gdeclab9'
	escalar pct `varlist'GX = `gdeclab10'


	***************
	*** 3. Sexo ***
	levelsof sexo, local(sexo)
	foreach k of local sexo {
		tabstat `varlist' if sexo == `k', stat(sum) save
		tempname GSEX
		matrix `GSEX' = r(StatTotal)
		local gsexlab`k' = `GSEX'[1,1]/`GTOT'[1,1]*100
	}
	escalar pct `varlist'GH = `gsexlab1'
	escalar pct `varlist'GM = `gsexlab2'


	*********************************
	/*** 4. Educational attainment ***
	levelsof escol, local(escol)
	foreach k of local escol {
		tabstat `varlist' if escol == `k', stat(sum) save
		tempname GESC
		matrix `GESC' = r(StatTotal)
		local gesclab`k' = `GESC'[1,1]/`GTOT'[1,1]*100
	}

	* Labels *
	tempvar grupoesc
	g `grupoesc' = 1 if escol < 2
	replace `grupoesc' = 2 if escol == 2
	replace `grupoesc' = 3 if escol > 2 & escol != .

	tempname grupoescval
	label define `grupoescval' 1 `"{bf:B{c a'}sica o menos}: (`=string(`gesclab0'+`gesclab1',"%7.0fc")'%)"' ///
		2 `"{bf:Media superior}: (`=string(`gesclab2',"%7.0fc")'%)"' ///
		3 `"{bf:Superior o m{c a'}s}: (`=string(`gesclab3',"%7.0fc")'%)"'
	label values `grupoesc' `grupoescval'
	label var `grupoesc' "escolaridad"

	tempvar formalidad
	g `formalidad' = formal != 0
	
	tempname formalidadval
	label define `formalidadval' 1 "Con seguridad social" 0 "Sin seguridad social"
	label values `formalidad' `formalidadval'
	label var `formalidad' "formalidad"

	****************/
	*** 5. Graphs ***
	graphpiramide `varlist', over(`grupo') title("`title'") rect(`rect') ///
		men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
		boot(`boottext') base(`base') pib(`pib') `nooutput' `nographs'
end


**********************
*** Pyramid Graphs ***
**********************
program graphpiramide
	version 13.1

	syntax varname, Over(varname) Men(string) Women(string) PIB(real) ///
		[Title(string) BOOTtext(string) Rect(real 100) BASE(string) ID(string) NOOutput NOGraphs]

	* Title *
	local titleover : variable label `over'

	****************************
	*** 1. Valores agregados ***
	tempname TOT POR
	egen double `TOT' = sum(`varlist')
	g double `POR' = `varlist'/`TOT'*100 //`pib'*100
	//g double `POR' = `varlist'/poblacion

	* Max number *
	tempvar PORmax
	egen double `PORmax' = sum(`POR'), by(edad sexo)

	tabstat `PORmax', stat(max min) save
	tempname PORmaxval
	matrix `PORmaxval' = r(StatTotal)

	* By age *
	tempname AGEH AGEM
	capture tabstat `POR' if edad < 18 & sexo == 1, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEH' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEH' = [0,0,0]
	}
	capture tabstat `POR' if edad < 18 & sexo == 2, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEM' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEM' = [0,0,0]
	}

	tempname AGEH1 AGEM1
	capture tabstat `POR' if edad >= 18 & edad < 65 & sexo == 1, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEH1' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEH1' = [0,0,0]
	}
	capture tabstat `POR' if edad >= 18 & edad < 65 & sexo == 2, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEM1' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEM1' = [0,0,0]
	}

	tempname AGEH2 AGEM2
	capture tabstat `POR' if edad >= 65 & sexo == 1, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEH2' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEH2' = [0,0,0]
	}
	capture tabstat `POR' if edad >= 65 & sexo == 2, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEM2' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEM2' = [0,0,0]
	}


	*******************
	*** 2. GRAFICAS ***
	if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		* Edades *
		*local relabel `"1 "Edad 0""'
		forvalues k=0(1)120 {
			if `k' != 0 & `k' != 5 & `k' != 10 & `k' != 15 & `k' != 20 & `k' != 25 & `k' != 30 ///
				& `k' != 35 & `k' != 40 & `k' != 45 & `k' != 50 & `k' != 55 ///
				& `k' != 60 & `k' != 65 & `k' != 70 & `k' != 75 & `k' != 80 ///
				& `k' != 85 & `k' != 90 & `k' != 95 & `k' != 100 & `k' != 105 ///
				& `k' != 110 & `k' != 115 & `k' != 120 {
				local relabel `"`relabel' `=`k'+1' " " "'
			}
			else {
				local relabel `"`relabel' `=`k'+1' "`k'" "'
			}
		}

		* REC % del PIB * 
		*if "`rect'" != "100" {
			*local rect `"{bf: Tama{c n~}o}: `=string(`rect',"%6.3fc")' % PIB"'
			*local rect `"{bf: Size}: `=string(`rect',"%6.3fc")' % GDP"'
		*}
		*else {
			local rect ""
		*}

		* Boottext *
		if "`boottext'" != "" {
			local boottext " `boottext'"
		}

		local agehlab =`AGEH'[1,1]/(`AGEH'[1,1]+`AGEH1'[1,1]+`AGEH2'[1,1])*100
		local agehlab1 =`AGEH1'[1,1]/(`AGEH'[1,1]+`AGEH1'[1,1]+`AGEH2'[1,1])*100
		local agehlab2 =`AGEH2'[1,1]/(`AGEH'[1,1]+`AGEH1'[1,1]+`AGEH2'[1,1])*100
		graph hbar (sum) `POR' if sexo == 1, ///
			over(`over') over(edad, axis(noextend noline outergap(0) off) descending ///
			relabel(`relabel') ///
			label(labsize(vsmall) labcolor(white) labgap(0pt))) ///
			stack asyvars xalternate ///
			yscale(noextend noline range(2.5)) ///
			blabel(none, format(%5.1fc)) ///
			t2title({bf:Hombres}: `men'%, size(vlarge)) ///
			ytitle(%, size(vlarge)) ///
			///t2title({bf:Men} (`men'%), size(vlarge)) ///
			///ytitle(% GDP) ///
			ylabel(`=round(`PORmaxval'[2,1],.1)'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks) ///
			name(H`varlist', replace) ///
			legend(cols(4) pos(6) bmargin(zero) ///
			label(1 `"{bf:0-18}: `=string(`agehlab',"%7.0fc")' %"') ///
			label(2 `"{bf:19-65}: `=string(`agehlab1',"%7.0fc")' %"') ///
			label(3 `"{bf:65+}: `=string(`agehlab2',"%7.0fc")' %"') ///
			label(4 "") label(5 "") label(6 "") label(7 "") label(8 "") label(9 "") ///
			label(10 "") symxsize(0)) ///
			yreverse ///
			plotregion(margin(zero)) ///
			graphregion(margin(zero))

		graph hbar (sum) `POR' if sexo == 2, ///
			over(`over') over(edad, axis(noextend noline outergap(0)) descending ///
			relabel(`relabel') ///
			label(labsize(medlarge) labcolor("111 111 111"))) ///
			stack asyvars ///
			yscale(noextend noline range(2.5)) ///
			blabel(none, format(%5.1fc)) ///
			t2title({bf:Mujeres}: `women'%, size(vlarge)) ///
			ytitle(%, size(vlarge)) ///
			///t2title({bf:Women} (`women'%), size(vlarge)) ///
			///ytitle(% GDP) ///
			ylabel(`=round(`PORmaxval'[2,1],.1)'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks) ///
			name(M`varlist', replace) ///
			legend(cols(4) pos(5) bmargin(zero) size(vlarge) keygap(1) symxsize(3) textwidth(30) forcesize) ///
			plotregion(margin(zero)) ///
			graphregion(margin(zero))

		graph combine H`varlist' M`varlist', ///
			name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)', replace) ///
			ycommon xcommon ///
			title("{bf:`title'}")
			
		//graph export `"${SIMROOT}/users/$id/graphs/`varlist'_`titleover'.png"', ///
		capture graph export `"$export/`varlist'_`titleover'.png"', ///
				replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')
		capture window manage close graph H`varlist'
		capture window manage close graph M`varlist'
	}

	if "$output" != "" & "`nooutput'" != "nooutput" {
		g grupo_edad = 1
		replace grupo_edad = 2 if edad > 4
		replace grupo_edad = 3 if edad > 9
		replace grupo_edad = 4 if edad > 14
		replace grupo_edad = 5 if edad > 19
		replace grupo_edad = 6 if edad > 24
		replace grupo_edad = 7 if edad > 29
		replace grupo_edad = 8 if edad > 34
		replace grupo_edad = 9 if edad > 39
		replace grupo_edad = 10 if edad > 44
		replace grupo_edad = 11 if edad > 49
		replace grupo_edad = 12 if edad > 54
		replace grupo_edad = 13 if edad > 59
		replace grupo_edad = 14 if edad > 64
		replace grupo_edad = 15 if edad > 69
		replace grupo_edad = 16 if edad > 74
		replace grupo_edad = 17 if edad > 79
		replace grupo_edad = 18 if edad > 84
		replace grupo_edad = 19 if edad > 89
		replace grupo_edad = 20 if edad > 94
		replace grupo_edad = 21 if edad > 99
		replace grupo_edad = 22 if edad > 104
		replace grupo_edad = 23 if edad > 109

		label define grupo_edad 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-19" ///
			5 "20-24" 6 "25-29" 7 "30-34" 8 "35-39" 9 "40-44" 10 "45-49" ///
			11 "50-54" 12 "55-59" 13 "60-64" 14 "65-69" 15 "70-74" ///
			16 "75-79" 17 "80-84" 18 "85-89" 19 "90-94" 20 "95-99" ///
			21 "100-104" 22 "105-109" 23 "109+"
		label values grupo_edad grupo_edad
		
		g over = `over'
		label define over 1 "Deciles I-V" 2 "VI-IX" 3 "X"
		label values over over
		collapse (sum) porcentaje=`POR', by(sexo grupo_edad over)
		reshape wide porcentaje, i(sexo grupo_edad) j(over)
		reshape wide porcentaje*, i(sexo) j(grupo_edad)
		reshape long porcentaje1 porcentaje2 porcentaje3, i(sexo) j(grupo_edad)
		reshape long porcentaje, i(sexo grupo_edad) j(over)
		replace porcentaje = 0 if porcentaje == .

		forvalues k=`=_N'(-1)1 {
			if sexo[`k'] == 1 {
				if over[`k'] == 1 {
					local aportHIV = "`aportHIV' `=string(`=porcentaje[`k']',"%8.3f")',"
				}
				if over[`k'] == 2 {
					local aportHVIIX = "`aportHVIIX' `=string(`=porcentaje[`k']',"%8.3f")',"
				}
				if over[`k'] == 3 {
					local aportHX = "`aportHX' `=string(`=porcentaje[`k']',"%8.3f")',"			
				}
			}
			if sexo[`k'] == 2 {
				if over[`k'] == 1 {
					local aportMIV = "`aportMIV' `=string(`=porcentaje[`k']',"%8.3f")',"
				}
				if over[`k'] == 2 {
					local aportMVIIX = "`aportMVIIX' `=string(`=porcentaje[`k']',"%8.3f")',"
				}
				if over[`k'] == 3 {
					local aportMX = "`aportMX' `=string(`=porcentaje[`k']',"%8.3f")',"			
				}		
			}
		}
		quietly log on output
		local lengthHIV = strlen("`aportHIV'")
		noisily di in w "APORTHIV: [`=substr("`aportHIV'",1,`=`lengthHIV'-1')']"
		local lengthHVIIX = strlen("`aportHVIIX'")
		noisily di in w "APORTHVIIX: [`=substr("`aportHVIIX'",1,`=`lengthHVIIX'-1')']"
		local lengthHX = strlen("`aportHX'")
		noisily di in w "APORTHX: [`=substr("`aportHX'",1,`=`lengthHX'-1')']"
		local lengthMIV = strlen("`aportMIV'")
		noisily di in w "APORTMIV: [`=substr("`aportMIV'",1,`=`lengthMIV'-1')']"
		local lengthMVIIX = strlen("`aportMVIIX'")
		noisily di in w "APORTMVIIX: [`=substr("`aportMVIIX'",1,`=`lengthMVIIX'-1')']"
		local lengthMX = strlen("`aportMX'")
		noisily di in w "APORTMX: [`=substr("`aportMX'",1,`=`lengthMX'-1')']"
		quietly log off output
	}
end

program define ProyGraph
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)

	args varlist title aniope bootstrap nographs
	if "`bootstrap'" == "" local bootstrap 1

	PIBDeflactor, nographs nooutput aniomax(2070)
	tempfile PIB
	save `PIB'
	
	local currency = currency[1]
	local anio = r(aniovp)

	use `"${SIMROOT}/users/$id/bootstraps/`bootstrap'/`varlist'REC.dta"', clear
	if `bootstrap' > 1 {
		* proyección puntual: media de las réplicas por año (la réplica 0 no se guarda en el archivo)
		collapse (mean) estimacion contribuyentes poblacion montopc, by(anio aniobase)
	}
	merge 1:1 (anio) using `PIB', nogen
	
	replace estimacion = estimacion*lambda/1000000000000
	*replace estimacion = estimacion*lambda/pibYR*100
	format estimacion %7.3fc

	forvalues aniohoy = `aniope'(1)`aniope' {
	*forvalues aniohoy = 1990(1)2050 {
		tabstat estimacion /*if anio >= `aniope'*/, stat(max) save
		tempname MAX
		matrix `MAX' = r(StatTotal)
		forvalues k=1(1)`=_N' {
			if estimacion[`k'] == `MAX'[1,1] {
				local aniomax = anio[`k']
			}
			if anio[`k'] == `aniohoy' {
				local estimacionvp = estimacion[`k']
			}
		}

		if `estimacionvp' == . {
				local estimacionvp = 0
		}
		
		if `MAX'[1,1] == . {
			matrix `MAX' = J(1,1,0)
		}

		tabstat estimacion if anio == 2070, stat(max) save
		tempname LAST
		matrix `LAST' = r(StatTotal)


		if "$nographs" != "nographs" & "`nographs'" != "nographs" {
			twoway (connected estimacion anio, lpattern(dot) msize(small)) ///
				(connected estimacion anio if anio == `aniohoy', mlabel(estimacion) mlabposition(12) mlabcolor("111 111 111") mlabsize(medlarge)) ///
				(connected estimacion anio if anio == `aniomax', mlabel(estimacion) mlabposition(12) mlabcolor("111 111 111") mlabsize(medlarge)) ///
				if anio > 2020, ///
				ytitle("billones `currency' `=aniovp'") ///
				///ytitle("% PIB") ///
				///subtitle("{bf:Proyección} del perfil demográfico") ///
				///subtitle("Demographic projection (% GDP)") ///
				///yscale(range(0)) /*ylabel(0(1)4)*/ ///
				ylabel(#5, format(%5.2fc) labsize(small)) ///
				yscale(range(0)) ///
				xlabel(2020(10)`=anio[_N]' `aniohoy' `aniomax', labsize(small)) ///
				xtitle("") ///
				legend(off) ///
				xline(`aniohoy', lpattern(dot)) ///
				xline(`aniomax', lpattern(dot)) ///
				///yline(0, lpattern(solid) lcolor(black)) ///
				///text(`=`estimacionmax'*.05' `aniomax' "Este perfil, junto con" "las proyecciones demográficas," "obtiene un {bf:máximo en `aniomax'}.", size(vlarge) place(11) justification(right)) ///
				///text(`=`estimacionmax'*.05' `aniomax' "This age profile, along with" "CONAPO's demographic projections," "reaches a maximum in {bf:`aniomax'}.", size(vlarge) place(11) justification(right)) ///
				b1title(`"De `aniohoy' a `aniomax', el cambio sería de {bf:`=string((`MAX'[1,1]/`estimacionvp'-1)*100,"%5.2f")'%} real."', size(large)) ///
				///text(`=`estimacionvp'*0.25' `aniohoy' "From `aniohoy' to 2070,"  "its demand will" `"change in {bf:`=string((`LAST'[1,1]/`estimacionvp'-1)*100,"%5.2f")'%}."', size(vlarge) place(1) justification(left)) ///
				title("{bf:`title'}") subtitle("$pais") ///
				///caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
				name(`varlist'Proj, replace)

			if "$export" != "" {
				graph export "$export/`varlist'Proj.png", replace name(`varlist'Proj)
			}
		}
	}

	if "$output" != "" {
		forvalues k=1(5)`=_N' {
			if anio[`k'] >= 2010 {
				local out_proy = "`out_proy' `=string(estimacion[`k'],"%8.3f")',"
			}
		}
		local lengthproy = strlen("`out_proy'")
		log on output
		noisily di in w "PROY: [`=substr("`out_proy'",1,`=`lengthproy'-1')']"
		noisily di in w "PROYMAX: [`aniomax']"
		log off output
	}
end


***************************************************************
*** simci: puntual + EE bootstrap + IC (normal y percentil) ***
***************************************************************
* Sobre la base de réplicas (una fila por réplica). point() es el estimador de la
* muestra completa; si no se da, se usa la media de las réplicas (v1.x). Con una
* sola fila no hay EE. Imprime en el formato de v1.x: valor y "+/- x%" (= 1.96·EE
* relativo). Devuelve r(mean) r(se) r(lb) r(ub) (percentil 2.5 y 97.5) r(B).
program define simci, rclass
	syntax varname [if], [POINT(real -1e300) LABel(string) COL(integer 40) FMT(string)]
	if "`fmt'" == "" local fmt %20.0fc
	qui summ `varlist' `if', detail
	local B = r(N)
	local mean = cond(`point' == -1e300, r(mean), `point')
	if `B' > 1 {
		local se = r(sd)
		_pctile `varlist' `if', p(2.5 97.5)
		local lb = r(r1)
		local ub = r(r2)
		noisily di in g "  `label'" _column(`col') in y `fmt' `mean' ///
			in g "  EE: " in y "+/-" %7.2fc cond(`mean' != 0, 1.96*`se'/abs(`mean')*100, .) "%" ///
			in g "  IC95 pct: [" in y `fmt' `lb' in g "," in y `fmt' `ub' in g "]"
	}
	else {
		local se = .
		local lb = .
		local ub = .
		noisily di in g "  `label'" _column(`col') in y `fmt' `mean' in g "  (B = 1: sin EE)"
	}
	return scalar mean = `mean'
	return scalar se   = `se'
	return scalar lb   = `lb'
	return scalar ub   = `ub'
	return scalar B    = `B'
end


mata:
mata set matastrict on

// ---------------------------------------------------------------------------
// Deciles ponderados con la definición de pctile/xtile de Stata (fweights):
// cumulado W_i; para P = p·W: si existe W_i == P, q = (x_i + x_{i+1})/2; si no,
// q = x_i con W_{i-1} < P < W_i. Categoría xtile: 1 + #{q_j < x}.
// Recibe y ya ordenada (ys) y el orden (o) para no re-ordenar en cada réplica.
// ---------------------------------------------------------------------------
real colvector simboot_wxtile(real colvector ys, real colvector o, real colvector w, real scalar n)
{
	real colvector ws, cw, q, d, res
	real scalar W, j, P, i, N
	N  = rows(ys)
	ws = w[o]
	cw = runningsum(ws)
	W  = cw[N]
	q  = J(n-1, 1, .)
	d  = J(N, 1, 1)
	if (W <= 0) return(d)
	i  = 1
	for (j = 1; j < n; j++) {
		P = j*W/n
		while (cw[i] < P) i++
		q[j] = (cw[i] == P & i < N) ? (ys[i] + ys[i+1])/2 : ys[i]
	}
	for (j = 1; j < n; j++) d = d :+ (ys :> q[j])
	// devolver en el orden original
	res = J(N, 1, .)
	res[o] = d
	return(res)
}

// Suma de v por grupo g (enteros 1..G) → vector G×1, y conteo de obs con w>0 por grupo
real matrix simboot_gsum(real colvector v, real colvector g, real scalar G)
{
	real colvector o, gs, s
	real matrix info
	s = J(G, 1, 0)
	o = order(g, 1)
	gs = g[o]
	info = panelsetup(gs, 1)
	s[gs[info[., 1]]] = panelsum(v[o], info)
	return(s)
}

void simboot_run(string scalar yv,   string scalar wv,    string scalar edadv, string scalar sexov,
                 string scalar condv, string scalar hhv,  string scalar cluv,  string scalar estv,
                 string scalar decv,  string scalar relv,
                 real scalar B, real scalar seed, string scalar HOMm, string scalar MUJm,
                 real scalar anio0, real scalar aniobase)
{
	external real matrix SIMBOOT_PC, SIMBOOT_PERF, SIMBOOT_INCI, SIMBOOT_CICLO, SIMBOOT_REC, SIMBOOT_PT
	real colvector y, w, edad, sexo, cond, hh, clu, est, dec0, rel, wb, mult, miembros, hog
	real colvector oy, ys, d, e40, valid, edadc, cellPS, pPS, gPS, wbs, ycs, oD, dD, o2, key, keyu
	real colvector yD, condD, hogD, relD, wbD, y2, wb2, key2
	real colvector recC, forC, pobC, nC, perfil1, perfil2, pcont1, pcont2, cnt
	real colvector uh_est, uh_clu, draws, dC, ccnt, csum, cpres
	real matrix infoD, info2
	real matrix HOM, MUJ, infoPS, infoH, uh, infoC, PERFIL, CONTBEN, R
	real rowvector RECp, CONTp, CONTh, CONTm, C0, C25, C50, C75, POBp
	real scalar n, b, REC, FOR, POB, REC40, POB40, montopc, edad40, pc, T, U, H, h, j, k, u
	real scalar Ytot, Htot, Rtot, row, last, k2, nd
	real colvector Yd, Hd, Rd, Nd, dd
	real matrix PCm, PERFm, INCIm, CICLOm, RECm, INCI0
	real rowvector PC0

	y    = st_data(., yv)
	w    = editmissing(st_data(., wv), 0)
	edad = st_data(., edadv)
	sexo = st_data(., sexov)
	cond = st_data(., condv)
	hh   = st_data(., hhv)
	clu  = st_data(., cluv)
	est  = st_data(., estv)
	rel  = editmissing(st_data(., relv), 0)
	dec0 = (decv == "" ? J(rows(y), 1, .) : st_data(., decv))
	n    = rows(y)
	HOM  = st_matrix(HOMm)
	MUJ  = st_matrix(MUJm)
	T    = cols(HOM)
	last = rows(MUJ)
	y    = editmissing(y, 0)

	// Estructuras fijas
	//  PERF: celdas (sexo, edad capada a 109), 1..220
	valid  = (edad :< .) :& ((sexo :== 1) :| (sexo :== 2))
	edadc  = editmissing(edad, 0)
	edadc  = edadc :+ (edadc :> 109) :* (109 :- edadc)
	cellPS = valid :* ((sexo :- 1) :* 110 :+ edadc :+ 1)
	cellPS = cellPS :+ (cellPS :== 0) :* 221          // 221 = fuera del barrido
	pPS    = order(cellPS, 1)                          // orden fijo: se calcula una vez
	infoPS = panelsetup(cellPS[pPS], 1)
	gPS    = cellPS[pPS][infoPS[., 1]]
	//  INCI: tamaño del hogar (personas con peso no missing en la base)
	miembros = simboot_gsum(J(n, 1, 1), hh, max(hh))[hh]
	hog      = cond :/ miembros
	//  deciles: orden de y una sola vez. En ese orden los deciles de xtile son bloques
	//  contiguos: INCI no necesita ordenar por réplica. Si decil es variable fija, su orden se calcula una vez.
	oy = order(y, 1)
	ys = y[oy]
	oD = (decv == "" ? oy : order(dec0, 1))
	//  CICLO: orden fijo por (sexo, edad, y) sobre las obs con cond. Dentro de cada celda
	//  (sexo, edad) el decil de xtile es monótono en y, así que la clave (sexo, edad, decil)
	//  queda ordenada sin volver a ordenar por réplica. Con decil fijo, orden por (sexo, edad, decil).
	o2 = selectindex((cond :== 1) :& (sexo :< .) :& (edad :< .))
	if (rows(o2)) o2 = o2[order((sexo[o2], edad[o2], (decv == "" ? y[o2] : editmissing(dec0[o2], 99))), (1, 2, 3))]
	//  constantes ya permutadas (por réplica solo se permutan los pesos)
	yD = y[oD]; condD = cond[oD]; hogD = hog[oD]; relD = rel[oD]
	y2 = (rows(o2) ? y[o2] : J(0, 1, .))
	key2 = (rows(o2) ? (sexo[o2] :* 1e6) :+ (edad[o2] :* 100) : J(0, 1, .))
	//  edad 40 hombres
	e40 = (edad :== 40) :& (sexo :== 1) :& cond
	//  clusters por estrato: filas únicas (estrato, cluster)
	uh     = uniqrows((est, clu))
	uh_est = uh[., 1]
	uh_clu = uh[., 2]
	infoH  = panelsetup(uh_est, 1)
	H      = rows(infoH)
	U      = max(clu)

	rseed(seed)
	PCm   = J(B, 5, .)
	PERFm = J(B*110, 11, .)
	INCIm = J(0, 5, .)
	CICLOm = J(0, 6, .)
	RECm  = J(B*T, 13, .)
	PC0   = J(1, 5, .)
	INCI0 = J(0, 5, .)

	for (b = (B == 1 ? 1 : 0); b <= B; b++) {
		// ---- pesos de la réplica: 0 = originales (puntual); b>=1 = clusters sorteados con reemplazo dentro de estrato ----
		if (b == 0 | B == 1) mult = J(U, 1, 1)
		else {
			mult = J(U, 1, 0)
			for (h = 1; h <= H; h++) {
				k = infoH[h, 2] - infoH[h, 1] + 1
				draws = ceil(k :* runiform(k, 1))
				for (j = 1; j <= k; j++) {
					u = uh_clu[infoH[h, 1] + draws[j] - 1]
					mult[u] = mult[u] + 1
				}
			}
		}
		wb = w :* mult[clu]

		// ---- 1.3.1 totales ----
		REC   = sum(wb :* y :* cond)
		FOR   = sum(wb :* cond)
		POB   = sum(wb)
		REC40 = sum(wb :* y :* e40)
		POB40 = sum(wb :* e40)
		montopc = (FOR != 0 ? REC/FOR : 0)
		edad40  = (POB40 != 0 ? REC40/POB40 : .)
		pc      = (edad40 == . | edad40 == 0 ? montopc : edad40)

		// ---- 1.3.2 PERF: por (sexo, edad) ----
		wbs  = wb[pPS]
		ycs  = (y :* cond)[pPS]
		recC = J(221, 1, 0); forC = J(221, 1, 0); pobC = J(221, 1, 0); nC = J(221, 1, 0)
		recC[gPS] = panelsum(wbs :* ycs, infoPS)
		forC[gPS] = panelsum(wbs :* cond[pPS], infoPS)
		pobC[gPS] = panelsum(wbs, infoPS)
		nC[gPS]   = panelsum(wbs :> 0, infoPS)
		recC = recC[|1 \ 220|]; forC = forC[|1 \ 220|]; pobC = pobC[|1 \ 220|]; nC = nC[|1 \ 220|]
		// celdas sin observaciones (con peso > 0): missing, como en el collapse
		if (any(nC :== 0)) {
			recC[selectindex(nC :== 0)] = J(sum(nC :== 0), 1, .)
			forC[selectindex(nC :== 0)] = J(sum(nC :== 0), 1, .)
			pobC[selectindex(nC :== 0)] = J(sum(nC :== 0), 1, .)
		}
		perfil1 = editmissing(recC[|1 \ 110|]   :/ forC[|1 \ 110|]   :/ pc, 0)
		perfil2 = editmissing(recC[|111 \ 220|] :/ forC[|111 \ 220|] :/ pc, 0)
		pcont1  = editmissing(forC[|1 \ 110|]   :/ pobC[|1 \ 110|]   :* 100, 0)
		pcont2  = editmissing(forC[|111 \ 220|] :/ pobC[|111 \ 220|] :* 100, 0)
		pcont1  = pcont1 :+ ((pobC[|1 \ 110|]   :== 0) :| (pobC[|1 \ 110|]   :>= .)) :* (100 :- pcont1)
		pcont2  = pcont2 :+ ((pobC[|111 \ 220|] :== 0) :| (pobC[|111 \ 220|] :>= .)) :* (100 :- pcont2)
		PERFIL  = (perfil1, perfil2)
		CONTBEN = (pcont1, pcont2)

		// ---- deciles ----
		d = (decv == "" ? simboot_wxtile(ys, oy, wb, 10) : dec0)

		// ---- 1.3.3 INCI: por decil (presentes) + total ---- (bloques contiguos en el orden oD)
		nd  = 10
		Yd = J(nd, 1, 0); Hd = J(nd, 1, 0); Rd = J(nd, 1, 0); Nd = J(nd, 1, 0)
		dD = d[oD]
		wbD = wb[oD]
		infoD = panelsetup(dD, 1)
		dd = dD[infoD[., 1]]                      // valor del decil de cada bloque
		cpres = selectindex(dd :< .)              // bloques con decil no missing
		if (rows(cpres)) {
			Nd[dd[cpres]] = panelsum(wbD :> 0, infoD)[cpres]
			Yd[dd[cpres]] = panelsum(wbD :* yD :* condD, infoD)[cpres]
			Hd[dd[cpres]] = panelsum(wbD :* hogD, infoD)[cpres]
			Rd[dd[cpres]] = panelsum(wbD :* relD, infoD)[cpres]
		}
		Ytot = sum(Yd); Htot = sum(Hd); Rtot = sum(Rd)
		R = J(0, 5, .)
		for (k2 = 1; k2 <= nd; k2++) {
			if (Nd[k2] == 0) continue
			R = R \ (k2, (Hd[k2] != 0 ? Yd[k2]/Hd[k2] : 0), (Ytot != 0 ? Yd[k2]/Ytot*100 : 0), (Rd[k2] != 0 ? Yd[k2]/Rd[k2]*100 : .), Hd[k2])
		}
		R = R \ (rows(R) + 1, (Htot != 0 ? Ytot/Htot : 0), (Ytot != 0 ? 100 : 0), (Rtot != 0 ? Ytot/Rtot*100 : .), Htot)

		// ---- 1.3.5 REC: proyección demográfica ----
		RECp  = pc :* ((PERFIL[., 1]' :* CONTBEN[., 1]' :/ 100) * HOM + (PERFIL[., 2]' :* CONTBEN[., 2]' :/ 100) * MUJ)
		CONTp = (CONTBEN[., 1]' :/ 100) * HOM + (CONTBEN[., 2]' :/ 100) * MUJ
		CONTh = (CONTBEN[., 1]' :/ 100) * HOM
		CONTm = (CONTBEN[., 2]' :/ 100) * MUJ
		C0  = colsum(HOM[|1, 1 \ 25, .|]  :* PERFIL[|1, 1 \ 25, 1|]  :* CONTBEN[|1, 1 \ 25, 1|]  :/ 100) + colsum(MUJ[|1, 1 \ 25, .|]  :* PERFIL[|1, 2 \ 25, 2|]  :* CONTBEN[|1, 2 \ 25, 2|]  :/ 100)
		C25 = colsum(HOM[|26, 1 \ 50, .|] :* PERFIL[|26, 1 \ 50, 1|] :* CONTBEN[|26, 1 \ 50, 1|] :/ 100) + colsum(MUJ[|26, 1 \ 50, .|] :* PERFIL[|26, 2 \ 50, 2|] :* CONTBEN[|26, 2 \ 50, 2|] :/ 100)
		C50 = colsum(HOM[|51, 1 \ 75, .|] :* PERFIL[|51, 1 \ 75, 1|] :* CONTBEN[|51, 1 \ 75, 1|] :/ 100) + colsum(MUJ[|51, 1 \ 75, .|] :* PERFIL[|51, 2 \ 75, 2|] :* CONTBEN[|51, 2 \ 75, 2|] :/ 100)
		C75 = colsum(HOM[|76, 1 \ ., .|]  :* PERFIL[|76, 1 \ last, 1|] :* CONTBEN[|76, 1 \ last, 1|] :/ 100) + colsum(MUJ[|76, 1 \ ., .|] :* PERFIL[|76, 2 \ last, 2|] :* CONTBEN[|76, 2 \ last, 2|] :/ 100)
		POBp = colsum(HOM) + colsum(MUJ)

		if (b == 0 & B > 1) {
			PC0   = (REC, FOR, POB, montopc, (POB40 != 0 ? REC40/POB40 : .))
			INCI0 = R
			continue
		}
		row = (B == 1 ? 1 : b)
		if (B == 1) {
			PC0   = (REC, FOR, POB, montopc, (POB40 != 0 ? REC40/POB40 : .))
			INCI0 = R
		}
		PCm[row, .] = (REC, FOR, POB, montopc, (POB40 != 0 ? REC40/POB40 : .))
		PERFm[|(row-1)*110+1, 1 \ row*110, 11|] = ((0::109), perfil1, perfil2, pcont1, pcont2,
			recC[|1 \ 110|], recC[|111 \ 220|], forC[|1 \ 110|], forC[|111 \ 220|], pobC[|1 \ 110|], pobC[|111 \ 220|])
		INCIm = INCIm \ R

		// ---- 1.3.4 CICLO: por (sexo, edad, decil) sobre obs con cond y peso > 0 ----
		if (rows(o2)) {
			key   = key2 :+ editmissing(d[o2], 99)        // ya ordenada (ver arriba)
			wb2   = wb[o2]
			info2 = panelsetup(key, 1)
			keyu  = key[info2[., 1]]
			cpres = selectindex(panelsum(wb2 :> 0, info2) :> 0)   // celdas con alguna obs de peso > 0
			if (rows(cpres)) {
				keyu  = keyu[cpres]
				csum  = panelsum(wb2 :* y2, info2)[cpres]
				ccnt  = panelsum(wb2, info2)[cpres]
				dC = mod(keyu, 100)
				if (any(dC :== 99)) dC[selectindex(dC :== 99)] = J(sum(dC :== 99), 1, .)
				CICLOm = CICLOm \ (J(rows(keyu), 1, row), floor(keyu :/ 1e6), floor(mod(keyu, 1e6) :/ 100), dC, ccnt, csum)
			}
		}

		// ---- REC a filas ----
		RECm[|(row-1)*T+1, 1 \ row*T, 13|] = (J(T, 1, row), (anio0 :+ (0::T-1)), J(T, 1, aniobase),
			RECp', CONTp', POBp', J(T, 1, pc), CONTh', CONTm', C0', C25', C50', C75')
	}

	SIMBOOT_PC    = PCm
	SIMBOOT_PERF  = PERFm
	SIMBOOT_INCI  = INCIm
	SIMBOOT_CICLO = CICLOm
	SIMBOOT_REC   = RECm
	// Puntuales: fila 1 PC0 (5 cols) seguida de INCI0 (decil xhogar distribucion incidencia hogares)
	SIMBOOT_PT    = (PC0, J(1, 5, .)) \ (J(rows(INCI0), 5, .), INCI0)
	st_matrix("SIM_PC0", PC0)
	st_matrix("SIM_INCI0", INCI0)
}

// Escribe en el dataset (vacío) en memoria uno de los resultados, con los tipos de los postfile v1.x
void simboot_write(string scalar which)
{
	external real matrix SIMBOOT_PC, SIMBOOT_PERF, SIMBOOT_INCI, SIMBOOT_CICLO, SIMBOOT_REC, SIMBOOT_PT
	real matrix M
	string rowvector names, types
	real scalar i

	if (which == "PC") {
		M = SIMBOOT_PC
		names = ("estimacion", "contribuyentes", "poblacion", "montopc", "edad40")
		types = J(1, 5, "double")
	}
	else if (which == "PERF") {
		M = SIMBOOT_PERF
		names = ("edad", "perfil1", "perfil2", "contribuyentes1", "contribuyentes2", "estimacion1", "estimacion2", "pobcont1", "pobcont2", "poblacion1", "poblacion2")
		types = ("float", J(1, 10, "double"))
	}
	else if (which == "INCI") {
		M = SIMBOOT_INCI
		names = ("decil", "xhogar", "distribucion", "incidencia", "hogares")
		types = ("float", J(1, 4, "double"))
	}
	else if (which == "CICLO") {
		M = SIMBOOT_CICLO
		names = ("bootstrap", "sexo", "edad", "decil", "poblacion", "y")
		types = (J(1, 4, "float"), "double", "double")
	}
	else if (which == "REC") {
		M = SIMBOOT_REC
		names = ("bootstrap", "anio", "aniobase", "estimacion", "contribuyentes", "poblacion", "montopc",
		         "contribuyentes_Hom", "contribuyentes_Muj", "contribuyentes_0_24", "contribuyentes_25_49", "contribuyentes_50_74", "contribuyentes_75_mas")
		types = (J(1, 3, "int"), J(1, 10, "double"))
	}
	else if (which == "PT") {
		M = SIMBOOT_PT
		names = ("estimacion", "contribuyentes", "poblacion", "montopc", "edad40", "decil", "xhogar", "distribucion", "incidencia", "hogares")
		types = J(1, 10, "double")
	}
	else _error("simboot_write: resultado desconocido")

	st_addobs(rows(M))
	if (which == "REC") (void) st_addvar("str30", "modulo")
	for (i = 1; i <= cols(M); i++) (void) st_addvar(types[i], names[i])
	st_store(., names, M)
}

void simboot_clear()
{
	external real matrix SIMBOOT_PC, SIMBOOT_PERF, SIMBOOT_INCI, SIMBOOT_CICLO, SIMBOOT_REC, SIMBOOT_PT
	SIMBOOT_PC = SIMBOOT_PERF = SIMBOOT_INCI = SIMBOOT_CICLO = SIMBOOT_REC = SIMBOOT_PT = J(0, 0, .)
}
end
