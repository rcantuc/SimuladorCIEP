program define FiscalGap
quietly {

	timer on 11
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax [, NOGraphs Anio(int `=aniovp') Update END(int 2100) ///
		ANIOMIN(int 2000) DIScount(real 5) DESDE(int `=`=aniovp'-1')]
	noisily di _newline(2) in g "{bf: FISCAL GAP:" in y " $pais `anio' }"

	escalar anio aniodesde = `desde'
	escalar anio anioend = `end'

	*************
	***       ***
	**# 1 PIB ***
	***       ***
	*************
	* Horizonte unico: end() gobierna PIB, SHRFSP y la matriz fiscal. Antes cada
	* frame tenia el suyo (PIB aniovp+5, SHRFSP anio+5) y el ultimo anio salia
	* huerfano (2026-09-12). *
	PIBDeflactor, anio(`=aniovp') geopib(`desde') geodef(`desde') aniomax(`end') nographs nooutput
	replace Poblacion = Poblacion*lambda
	replace Poblacion0 = Poblacion0*lambda
	keep if anio <= `end'
	local currency = currency[1]
	local llambda = scalar(llambda)
	tempfile PIB
	save `PIB'



	****************
	***          ***
	**# 2 SHRFSP ***
	***          ***
	****************
	noisily SHRFSP, anio(`=`anio'-1') aniomax(`end') nographs $textbook //update
	tempfile shrfsp
	save `shrfsp'



	********************
	***              ***
	**# 3 HOUSEHOLDS ***
	***              ***
	********************
	use "`c(sysdir_site)'/users/$id/ingresos.dta", clear
	merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen update
	capture drop _*

	foreach k in Educacion Pensiones Pensión_AM Salud OtrosGastos IngBasico OtrasInversiones Federalizado Energia {
		tabstat `k' [fw=factor], stat(sum) f(%20.0fc) save
		local k = subinstr("`k'","á","a",.)
		local k = subinstr("`k'","é","e",.)
		local k = subinstr("`k'","í","i",.)
		local k = subinstr("`k'","ó","o",.)
		local k = subinstr("`k'","ú","u",.)
		
		if "`k'" == "OtrasInversiones" {
			local k "Otras_inversiones"
		}
	
		if "`k'" == "OtrosGastos" {
			local k "Otros_gastos"
		}
		
		tempname HH`k'
		matrix `HH`k'' = r(StatTotal)
	}



	******************************
	***                        ***
	**# 4 Fiscal Gap: Ingresos ***
	***                        ***
	******************************
	noisily di _newline in g "  INGRESOS " in y "`desde'-`anio'"

	** 4.1 Información histórica de los ingresos **
	LIF if divLIF != 10 | divCIEP == 8, anio(`anio') nographs by(divSIM) min(0) desde(`desde') //eofp //ilif

	* Dos espacios de nombres, separados a proposito:
	*  - OBSERVADO (LIF `anio'): r(`k'PIB) y r(`k'C), capturados aqui en locals
	*    antes de que otro comando r-class los borre;
	*  - ESCENARIO (usuario): escalares `k'PIB de SIM.do 4.1 / Web.Stata.do.
	* LIF ya no escribe escalares globales por grupo, asi que correrla aqui NO
	* pisa lo que el usuario definio antes. Ancla de 4.2: escenario si existe,
	* si no el observado — FiscalGap sigue siendo autocontenido. *
	foreach k in CFE CUOTAS FMP IEPSNP IEPSP IMPORT IMSS ISAN ISRAS ISRPF ISRPM ISSSTE IVA OTROSK PEMEX {
		local `k'C = r(`k'C)
		local `k'LIF = r(`k'PIB)
	}
	collapse (sum) recaudacion, by(anio divSIM) fast
	decode divSIM, g(divSIMstr)
	drop divSIM
	rename divSIMstr divSIM
	replace divSIM = strtoname(divSIM)
	preserve

	** 4.2 Proyección futura de los ingresos **
	foreach k in CFE CUOTAS FMP IEPSNP IEPSP IMPORT IMSS ISAN ISRAS ISRPF ISRPM ISSSTE IVA OTROSK PEMEX {
		use `"`c(sysdir_site)'/users/ricardo/bootstraps/1/`k'REC.dta"', clear
		collapse estimacion contribuyentes, by(anio modulo aniobase)
		tsset anio
		
		g divSIM = "`k'"
		
		* Calcular tasa de crecimiento demográfico (contribuyentes) *
		g crecimiento_demo = (contribuyentes/L.contribuyentes - 1) * 100
		
		* Calcular promedio de crecimiento demográfico histórico *
		tabstat crecimiento_demo if anio <= `anio' & anio >= `anio'-5 & crecimiento_demo != ., stat(mean) save
		local tasa_demo = r(StatTotal)[1,1]
		
		* Separar tendencia de largo plazo en componentes *
		* Tendencia total = ``k'C'
		* Componente demográfico = `tasa_demo'
		* Componente no demográfico (per cápita) = ``k'C' - `tasa_demo'
		local tendencia = ``k'C' - `tasa_demo'
		if `tendencia' > 5 {
			local tendencia = 5
		}
		if `tendencia' < -5 {
			local tendencia = -5
		}
		
		escalar pct tt`=strtoname("`k'")' = ``k'C'
		escalar pct td`=strtoname("`k'")' = `tasa_demo'
		escalar pct tn`=strtoname("`k'")' = `tendencia'

		* Ancla `anio': parametro de escenario del usuario si existe, si no el
		* observado de LIF (r(`k'PIB), capturado en 4.1). *
		capture confirm scalar `k'PIB
		if _rc == 0 {
			local ancla = scalar(`k'PIB)	// INVARIANTE (v8.1.0): los `k'PIB son params de interfaz NUMÉRICOS — Web.Stata.do los declara sin comillas y ambos flujos (local vía escalar, web vía template) entregan numérico; un placeholder sin sustituir truena en sintaxis, visible — NO reintroducir real() ni comillas
		}
		else {
			local ancla = ``k'LIF'
		}

		* Nueva fórmula SIN doble contabilización *
		replace estimacion = (`ancla'/100*scalar(pibY)) if anio == `anio'
		replace estimacion = L.estimacion * 									///
			(contribuyentes/L.contribuyentes) *									/// Cambio demográfico PURO (contribuyentes)
			(1+`tendencia'/100)													/// Tendencia
			if anio > `anio'
		
		tempfile `k'
		save ``k''
	}

	restore
	g modulo = ""
	foreach k in CFE CUOTAS FMP IEPSNP IEPSP IMPORT IMSS ISAN ISRAS ISRPF ISRPM ISSSTE IVA OTROSK PEMEX {
		merge 1:1 (anio divSIM) using ``k'', nogen update replace
	}
	format estimacion %20.0fc

	** 4.3 Actualizaciones **
	collapse (sum) recaudacion estimacionRecaudacion=estimacion if anio <= `end', by(anio divSIM) fast
	merge m:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda Poblacion*) update replace keep(matched)

	replace estimacionRecaudacion = estimacionRecaudacion*deflator
	replace recaudacion = 0 if recaudacion == .
	replace estimacionRecaudacion = 0 if estimacionRecaudacion == .

	* Diferimiento de pagos (LIF divCIEP 8, etiqueta DEUDA en divSIM): la SHCP
	* NO lo cuenta como ingreso — lo resta al gasto devengado para llegar al
	* gasto neto PAGADO. Sale de los ingresos y viaja como serie propia. *
	g diferimientos = recaudacion if divSIM == "DEUDA"
	replace diferimientos = 0 if diferimientos == .
	replace recaudacion = 0 if divSIM == "DEUDA"
	replace estimacionRecaudacion = 0 if divSIM == "DEUDA"
	format estimacion* diferimientos %20.0fc

	g recaudacion_pib = recaudacion/pibY*100 				
	g estimacionRecaudacion_pib = estimacionRecaudacion/pibY*100 

	** 4.3b Display: LIF vs simulacion en `anio', y trayectoria proyectada **
	* La estimacion de `anio' es el ancla de 4.2 (parametro `k'PIB x PIB): igual a
	* la LIF si no se simulo nada, distinta si el usuario movio parametros. Las
	* tasas son las de 4.2: total (LIF `desde'-`anio'), demografica (contribuyentes)
	* y economica (residuo, acotado a +-5). *
	noisily di _newline in g "{bf: A. Ingresos `anio': LIF vs simulaci{c o'}n}" ///
		_newline ///
		_col(12) in g %13s "LIF" ///
		_col(27) %13s "Simulaci{c o'}n" ///
		_col(42) %6s "Dif %" ///
		_col(50) %7s "% PIB" ///
		_col(59) %6s "Total" ///
		_col(66) %6s "Demog" ///
		_col(73) %6s "Econ"
	noisily di in g _col(12) %13s "mill. `currency'" _col(27) %13s "mill. `currency'" _col(59) %6s "tasa %" _col(66) %6s "tasa %" _col(73) %6s "tasa %"
	tempname tLIF tSIM
	scalar `tLIF' = 0
	scalar `tSIM' = 0
	levelsof divSIM if anio == `anio' & divSIM != "DEUDA", local(divs) clean
	foreach k of local divs {
		sum recaudacion if anio == `anio' & divSIM == "`k'", meanonly
		local lif = r(sum)
		sum estimacionRecaudacion if anio == `anio' & divSIM == "`k'", meanonly
		local sim = r(sum)
		sum estimacionRecaudacion_pib if anio == `anio' & divSIM == "`k'", meanonly
		local simpib = r(sum)
		scalar `tLIF' = `tLIF' + `lif'
		scalar `tSIM' = `tSIM' + `sim'
		local dif = .
		if `lif' != 0 {
			local dif = (`sim'/`lif'-1)*100
		}
		foreach t in tt td tn {
			local `t' = .
			capture local `t' = scalar(`t'`k')
		}
		noisily di in g "  `k'" ///
			_col(12) in y %13.0fc `lif'/1e6 ///
			_col(27) in y %13.0fc `sim'/1e6 ///
			_col(42) in y %6.1fc `dif' ///
			_col(50) in y %7.3fc `simpib' ///
			_col(59) in y %6.2f `tt' ///
			_col(66) in y %6.2f `td' ///
			_col(73) in y %6.2f `tn'
	}
	sum estimacionRecaudacion_pib if anio == `anio', meanonly
	local totpib = r(sum)
	noisily di in g _dup(79) "-"
	noisily di in g "{bf:  (=) Total" ///
		_col(12) in y %13.0fc `tLIF'/1e6 ///
		_col(27) in y %13.0fc `tSIM'/1e6 ///
		_col(42) in y %6.1fc (`tSIM'/`tLIF'-1)*100 ///
		_col(50) in y %7.3fc `totpib' "}"
	noisily di in g "  Dif % = simulaci{c o'}n vs LIF. Econ acotada a +-5 (5.00 o -5.00 = tope activo)."
	sum diferimientos if anio == `anio', meanonly
	if r(sum) != 0 {
		noisily di in g "  Memo: diferimiento de pagos (LIF divCIEP 8) " in y %12.0fc r(sum)/1e6 in g " mill. — no es ingreso; se resta al gasto pagado (5.9b)."
	}
	escalar custom(%20.0fc) IngresosLIF`anio' = `tLIF'
	escalar custom(%20.0fc) IngresosSim`anio' = `tSIM'
	escalar pct IngresosSimDif`anio' = (`tSIM'/`tLIF'-1)*100

	* Trayectoria anual de ingresos: se construye aqui (matriz Proy_ingresos,
	* 1 x anios) pero se DESPLIEGA en 5.9b como fila de Proy_fiscal, junto con
	* gasto, costo de la deuda, RFSP y SHRFSP — una sola tabla, sin repetir. *
	local nanios = `end'-`anio'+1
	matrix Proy_ingresos = J(1, `nanios', .)
	local colnames ""
	local j = 0
	forvalues y = `anio'/`end' {
		local ++j
		local colnames "`colnames' a`y'"
		sum estimacionRecaudacion_pib if anio == `y', meanonly
		if r(N) > 0 {
			matrix Proy_ingresos[1,`j'] = r(sum)
		}
	}
	matrix colnames Proy_ingresos = `colnames'
	matrix rownames Proy_ingresos = Ingresos

	g divGraph = "Impuestos laborales" if divSIM == "CUOTAS" | divSIM == "ISRAS" | divSIM == "ISRPF"
	replace divGraph = "Impuestos al consumo" if divSIM == "IEPSNP" | divSIM == "IEPSP" | divSIM == "IVA" | divSIM == "ISAN" | divSIM == "IMPORT"
	replace divGraph = "Impuestos al capital" if divSIM == "ISRPM" | divSIM == "OTROSK" | divSIM == "FMP"
	replace divGraph = "Organismos y empresas" if divSIM == "CFE" | divSIM == "IMSS" | divSIM == "ISSSTE" | divSIM == "PEMEX"


	****************
	** 4.4 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		//noisily tabstat recaudacion_pib estimacionRecaudacion_pib if anio >= `aniomin', stat(sum) by(anio) save
		graph bar (sum) recaudacion_pib if anio < `anio' & anio >= `aniomin', ///
			bargap(20) ///
			over(divGraph) ///
			over(anio, gap(0)) ///
			ytitle("% PIB") ///
			stack asyvar ///
			text(`text', size(vsmall)) ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_ingresos1) ///
			title(Observado)

		graph bar (sum) estimacionRecaudacion_pib if anio >= `anio', ///
			bargap(20) ///
			over(divGraph) ///
			over(anio, gap(0)) ///
			ytitle("") ylabel(, labcolor(white)) ///
			stack asyvar ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_ingresos2) ///
			title(Proyectado)

		capture which grc1leg2
		if _rc != 0 {
			net install "http://fmwww.bc.edu/RePEc/bocode/g/grc1leg2.pkg"
		}
		//grc1leg2 Proy_ingresos1 Proy_ingresos2, ycommon ///
		graph combine Proy_ingresos1 Proy_ingresos2, ycommon ///
			///title({bf:Ingresos p{c u'}blicos}) ///
			///caption("`graphfuente'") ///
			name(Proy_ingresos, replace)

		capture window manage close graph Proy_ingresos1
		capture window manage close graph Proy_ingresos2

		if "$export" != "" {
			graph export `"$export/Proy_ingresos.png"', replace name(Proy_ingresos)
		}
	}


	*****************
	** 4.5 Outputs **
	if "$output" != "" {
		preserve
		collapse (sum) recaudacion_pib estimacionRecaudacion_pib if anio <= `end', by(anio divGraph) fast
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				if divGraph[`k'] == "Impuestos laborales" {
					local proy_laborales = "`proy_laborales' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al consumo" {
					local proy_consumo  = "`proy_consumo' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al capital" {
					local proy_capital  = "`proy_capital' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Organismos y empresas" {
					local proy_organismos  = "`proy_organismos' `=string(`=recaudacion_pib[`k']',"%10.1f")',"
				}
			}
			if anio[`k'] >= `anio' & anio[`k'] <= `end' {
				if divGraph[`k'] == "Impuestos laborales" {
					local proy_laborales = "`proy_laborales' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al consumo" {
					local proy_consumo  = "`proy_consumo' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Impuestos al capital" {
					local proy_capital  = "`proy_capital' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
				if divGraph[`k'] == "Organismos y empresas" {
					local proy_organismos  = "`proy_organismos' `=string(`=estimacionRecaudacion_pib[`k']',"%10.1f")',"
				}
			}
		}
		local length_laborales = strlen("`proy_laborales'")
		local length_consumo = strlen("`proy_consumo'")
		local length_capital = strlen("`proy_capital'")
		local length_organismos = strlen("`proy_organismos'")
		capture log on output
		noisily di in w "PROYLABOR: [`=substr("`proy_laborales'",1,`=`length_laborales'-1')']"
		noisily di in w "PROYCONSU: [`=substr("`proy_consumo'",1,`=`length_consumo'-1')']"
		noisily di in w "PROYCAPIT: [`=substr("`proy_capital'",1,`=`length_capital'-1')']"
		noisily di in w "PROYORGAN: [`=substr("`proy_organismos'",1,`=`length_organismos'-1')']"
		capture log off output
		restore
	}


	********************/
	** 4.6 Serie anual de ingresos (sin VP/infinito: retirados 2026-09-12; la
	**     reestructura de la proyeccion de largo plazo va por partes y el
	**     balance/inequidad en VP de las secciones 6-7 quedan desactivados
	**     hasta que la trayectoria anual este validada) **
	collapse (sum) recaudacion* estimacionRecaudacion* diferimientos (last) pibY deflator, by(anio) fast

	* Save *
	tempfile baseingresos
	save `baseingresos'





	****************************
	***                      ***
	**# 5 Fiscal Gap: Gastos ***
	***                      ***
	****************************
	noisily di _newline in g "  GASTOS " in y "`desde'-`anio'"

	*********************************************
	** 5.1 Información histórica de los gastos **
	PEF if transf_gf == 0, anio(`anio') by(divCIEP) nographs desde(`desde')
	local divCIEP "`=r(divCIEP)' IngBasico"
	*replace gasto = -gasto if resumido2 == "Cuotas ISSSTE"

	local divCIEP = subinstr("`divCIEP'","á","a",.)
	local divCIEP = subinstr("`divCIEP'","é","e",.)
	local divCIEP = subinstr("`divCIEP'","í","i",.)
	local divCIEP = subinstr("`divCIEP'","ó","o",.)
	local divCIEP = subinstr("`divCIEP'","ú","u",.)
	foreach k of local divCIEP {
		local `k' = r(`k')
		local `k'C = r(`k'C)
	}
	decode resumido, g(divCIEP)
	replace divCIEP = strtoname(divCIEP)
	replace divCIEP = subinstr(divCIEP,"á","a",.)
	replace divCIEP = subinstr(divCIEP,"é","e",.)
	replace divCIEP = subinstr(divCIEP,"í","i",.)
	replace divCIEP = subinstr(divCIEP,"ó","o",.)
	replace divCIEP = subinstr(divCIEP,"ú","u",.)

	****************************************/
	** 5.2 Proyección futura de los gastos **
	g modulo = ""
	foreach k of local divCIEP {
	//foreach k in Pensiones {
		if `"`=strtoname("`k'")'"' != "Costo_de_la_deuda" {
			preserve
			use `"`c(sysdir_site)'/users/ricardo/bootstraps/1/`=strtoname("`k'")'REC.dta"', clear
			collapse estimacion contribuyentes, by(anio modulo aniobase)
			tsset anio
			
			* Calcular tasa de crecimiento demográfico (contribuyentes/beneficiarios) *
			g crecimiento_demo = (contribuyentes/L.contribuyentes - 1) * 100
			
			* Calcular promedio de crecimiento demográfico histórico *
			tabstat crecimiento_demo if anio <= `anio' & anio >= `anio'-5 & crecimiento_demo != ., stat(mean) save
			local tasa_demo = r(StatTotal)[1,1]
			
			* Separar tendencia de largo plazo en componentes *
			* Tendencia total = ``=strtoname("`k'")'C'
			* Componente demográfico = `tasa_demo'
			* Componente no demográfico = ``=strtoname("`k'")'C' - `tasa_demo'
			local tendencia = ``=strtoname("`k'")'C' - `tasa_demo'
			if `tendencia' > 5 {
				local tendencia = 5
			}
			if `tendencia' < -5 {
				local tendencia = -5
			}


			escalar pct tt`=subinstr(strtoname("`k'"),"_","",.)' = ``=strtoname("`k'")'C'
			escalar pct td`=subinstr(strtoname("`k'"),"_","",.)' = `tasa_demo'
			escalar pct tn`=subinstr(strtoname("`k'"),"_","",.)' = `tendencia'
			
			* Nueva fórmula SIN doble contabilización *
			replace estimacion = `HH`=strtoname("`k'")''[1,1] if anio == `anio'	// Gasto total del año base (GastoPC.ado)
			replace estimacion = L.estimacion * 								///
				(contribuyentes/L.contribuyentes) *     						/// Cambio demográfico PURO
				(1+`tendencia'/100)   											/// Tendencia 
				if anio > `anio'

			g divCIEP = `"`=strtoname("`k'")'"'

			tempfile `k'
			save ``k''

			restore
			merge 1:1 (anio divCIEP) using ``k'', nogen update replace
		}
	}


	*************************
	** 5.3 Actualizaciones **
	collapse (sum) gasto estimacionGasto=estimacion if anio <= `end', by(anio divCIEP) fast
	merge m:1 (anio) using `PIB', nogen keepus(indiceY pibY* deflator lambda currency Poblacion*) keep(matched) update

	* Construccion de estimacionGasto (nominal), en este orden:
	*  (1) lo SIMULADO por hogares (5.2) viene a precios de `anio' -> x deflator;
	*  (2) las partidas MACRO ya son nominales y se ponen DESPUES (antes, cuotas
	*      proyectadas como % PIB se inflaban dos veces — 2026-09-12). *
	replace estimacionGasto = estimacionGasto*deflator
	* Cuotas ISSSTE: partida macro (negativa) que NO se simula por hogares. En
	* `anio' = PEF; despues, constante como % del PIB de `anio' (supuesto
	* declarado). PerfilesSim/GastoPC ya NO las netan dentro de Otros gastos
	* (2026-09-12) — antes se restaban dos veces. *
	replace estimacionGasto = gasto if divCIEP == "Cuotas_ISSSTE" & anio <= `anio'
	sum gasto if divCIEP == "Cuotas_ISSSTE" & anio == `anio', meanonly
	local cuo_anio = r(sum)
	sum pibY if divCIEP == "Cuotas_ISSSTE" & anio == `anio', meanonly
	local cuo_pib = cond(r(N) > 0 & r(sum) != 0, `cuo_anio'/r(sum), 0)
	replace estimacionGasto = `cuo_pib'*pibY if divCIEP == "Cuotas_ISSSTE" & anio > `anio'
	* Costo de la deuda: no se simula por hogares; en `anio' el ancla es el PEF
	* (5.9 lo proyecta con la tasa efectiva a partir de `anio'+1). *
	replace estimacionGasto = gasto if divCIEP == "Costo_de_la_deuda"
	g estimacionCostoPEF = gasto if divCIEP == "Costo_de_la_deuda"
	replace estimacionCostoPEF = 0 if estimacionCostoPEF == .
	replace gasto = 0 if gasto == .
	replace estimacionGasto = 0 if estimacionGasto == .

	g gasto_pib = gasto/pibY*100
	g estimacionGasto_pib = estimacionGasto/pibY*100

	** 5.3b Display: PEF vs simulacion en `anio' **
	* La estimacion de `anio' es el ancla de 5.2: el gasto micro-simulado de los
	* hogares (GastoPC/perfiles, matriz HH<k>); igual al PEF solo si la
	* armonizacion macro-micro cierra. Cuotas_ISSSTE no se simula (= PEF) y el
	* costo de la deuda se proyecta en 5.9 con la tasa efectiva, no aqui. *
	noisily di _newline in g "{bf: A. Gasto `anio': PEF vs simulaci{c o'}n}" ///
		_newline ///
		_col(17) in g %12s "PEF" ///
		_col(30) %12s "Simulaci{c o'}n" ///
		_col(43) %6s "Dif %" ///
		_col(50) %6s "% PIB" ///
		_col(57) %5s "Total" ///
		_col(63) %5s "Demog" ///
		_col(69) %5s "Econ"
	noisily di in g _col(17) %12s "mill. `currency'" _col(30) %12s "mill. `currency'" _col(57) %5s "tasa" _col(63) %5s "tasa" _col(69) %5s "tasa"
	tempname tPEF tSIM
	scalar `tPEF' = 0
	scalar `tSIM' = 0
	* Conciliacion de categorias (solo display; los datos no cambian):
	*   Sim "Otros gastos" = Otros_gastos + IngBasico ("Transferencias": cuidados, madres,
	*   ingreso basico — GastoPC las separa de Otros gastos; el PEF las clasifica dentro).
	* IngBasico no se lista como fila; el total si la incluye. Cuotas ISSSTE es fila
	* propia (negativa), igual que en el PEF. *
	levelsof divCIEP if anio == `anio' & divCIEP != "IngBasico", local(divs) clean
	foreach k of local divs {
		sum gasto if anio == `anio' & divCIEP == "`k'", meanonly
		local pef = r(sum)
		sum estimacionGasto if anio == `anio' & divCIEP == "`k'", meanonly
		local sim = r(sum)
		sum estimacionGasto_pib if anio == `anio' & divCIEP == "`k'", meanonly
		local simpib = r(sum)
		local rot = subinstr("`k'","_"," ",.)
		if "`k'" == "Cuotas_ISSSTE" local rot "Cuotas ISSSTE (-)"
		if "`k'" == "Otros_gastos" {
			sum estimacionGasto if anio == `anio' & divCIEP == "IngBasico", meanonly
			local sim = `sim' + r(sum)
			sum estimacionGasto_pib if anio == `anio' & divCIEP == "IngBasico", meanonly
			local simpib = `simpib' + r(sum)
			local rot "Otros gastos*"
		}
		scalar `tPEF' = `tPEF' + `pef'
		scalar `tSIM' = `tSIM' + `sim'
		local dif = .
		if `pef' != 0 {
			local dif = (`sim'/`pef'-1)*100
		}
		local kk = subinstr("`k'","_","",.)
		foreach t in tt td tn {
			local `t' = .
			capture local `t' = scalar(`t'`kk')
		}
		noisily di in g "  " %-14s substr("`rot'",1,14) ///
			_col(17) in y %12.0fc `pef'/1e6 ///
			_col(30) in y %12.0fc `sim'/1e6 ///
			_col(43) in y %6.1fc `dif' ///
			_col(50) in y %6.3fc `simpib' ///
			_col(57) in y %5.2f `tt' ///
			_col(63) in y %5.2f `td' ///
			_col(69) in y %5.2f `tn'
	}
	sum estimacionGasto_pib if anio == `anio', meanonly
	local totpib = r(sum)
	noisily di in g _dup(74) "-"
	noisily di in g "{bf:  (=) Total" ///
		_col(17) in y %12.0fc `tPEF'/1e6 ///
		_col(30) in y %12.0fc `tSIM'/1e6 ///
		_col(43) in y %6.1fc (`tSIM'/`tPEF'-1)*100 ///
		_col(50) in y %6.3fc `totpib' "}"
	noisily di in g "  Dif % = simulaci{c o'}n (hogares) vs PEF. Econ acotada a +-5 (+-5.00 = tope activo)."
	noisily di in g "  Costo de la deuda = PEF (no se simula por hogares; se proyecta en 5.9)."
	sum estimacionGasto if anio == `anio' & divCIEP == "IngBasico", meanonly
	noisily di in g "  * Otros gastos simulados incluyen Transferencias (cuidados/madres/IB, var. IngBasico: " in y %8.0fc r(sum)/1e6 in g " mill.),"
	noisily di in g "    que GastoPC separa y el PEF clasifica dentro de Otros gastos. Cuotas ISSSTE = PEF (macro, no se simula)."
	escalar custom(%20.0fc) GastoPEF`anio' = `tPEF'
	escalar custom(%20.0fc) GastoSim`anio' = `tSIM'
	escalar pct GastoSimDif`anio' = (`tSIM'/`tPEF'-1)*100

	g divSIM = subinstr(divCIEP,"_"," ",.)
	replace divSIM = "Otros gastos" if divSIM == "IngBasico" | divSIM == "Federalizado" | divSIM == "Cuotas ISSSTE"
	replace divSIM = "Pensiones" if divSIM == "Pension AM"
	replace divSIM = "Educación" if divSIM == "Educacion"
	replace divSIM = "Energía" if divSIM == "Energia"


	****************
	** 5.4 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		//noisily tabstat gasto_pib estimacionGasto if anio >= `aniomin', stat(sum) by(anio) save
		graph bar (sum) gasto_pib if anio < `anio' & anio >= `aniomin' & divSIM != "Costo de la deuda", ///
			over(divSIM) ///
			over(anio, gap(0)) ///
			ytitle("% PIB") ///
			stack asyvar ///
			text(`text', size(vsmall)) ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_gastos1) ///
			title(Observado)

		graph bar (sum) estimacionGasto_pib if anio >= `anio' & divSIM != "Costo de la deuda", ///
			over(divSIM) ///
			over(anio, gap(0)) ///
			ytitle("") ylabel(none) ///
			stack asyvar ///
			blabel(, format(%5.1fc)) ///
			legend(rows(1) `legend') ///
			name(Proy_gastos2) ///
			title(Proyectado)

		//grc1leg2 Proy_gastos1 Proy_gastos2, ycommon ///
		graph combine Proy_gastos1 Proy_gastos2, ycommon ///
			///title({bf:Gasto p{c u'}blico primario}) ///
			subtitle($pais) ///
			///caption("`graphfuente'") ///
			name(Proy_gastos, replace)

		capture window manage close graph Proy_gastos1
		capture window manage close graph Proy_gastos2

		if "$export" != "" {
			graph export `"$export/Proy_gastos.png"', replace name(Proy_gastos)
		}

	}


	****************
	** 5.5 Output **
	if "$output" != "" {
		preserve
		*noisily levelsof divSIM, local(divSIM)
		collapse (sum) gasto_pib estimacionGasto_pib if anio <= `end', by(anio divSIM) fast
		forvalues k=1(1)`=_N' {
			if anio[`k'] >= 2013 & anio[`k'] < `anio' {
				if divSIM[`k'] == "Educación" {
					local proy_educacion = "`proy_educacion' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Pensiones" {
					local proy_pensiones = "`proy_pensiones' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Salud" {
					local proy_salud = "`proy_salud' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otros gastos" {
					local proy_otros = "`proy_otros' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Energía" {
					local proy_energia = "`proy_energia' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otras inversiones" {
					local proy_inversiones = "`proy_inversiones' `=string(`=gasto_pib[`k']',"%10.1f")',"
				}
			}
			if anio[`k'] >= `anio' & anio[`k'] <= `end' {
				if divSIM[`k'] == "Educación" {
					local proy_educacion = "`proy_educacion' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Pensiones" {
					local proy_pensiones = "`proy_pensiones' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Salud" {
					local proy_salud = "`proy_salud' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otros gastos" {
					local proy_otros = "`proy_otros' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Energía" {
					local proy_energia = "`proy_energia' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
				if divSIM[`k'] == "Otras inversiones" {
					local proy_inversiones = "`proy_inversiones' `=string(`=estimacionGasto_pib[`k']',"%10.1f")',"
				}
			}
		}
		local length_educacion = strlen("`proy_educacion'")
		local length_pensiones = strlen("`proy_pensiones'")
		local length_salud = strlen("`proy_salud'")
		local length_otros = strlen("`proy_otros'")
		local length_energia = strlen("`proy_energia'")
		local length_inversiones = strlen("`proy_inversiones'")
		capture log on output
		noisily di in w "PROYEDUCA: [`=substr("`proy_educacion'",1,`=`length_educacion'-1')']"
		noisily di in w "PROYPENSI: [`=substr("`proy_pensiones'",1,`=`length_pensiones'-1')']"
		noisily di in w "PROYSALUD: [`=substr("`proy_salud'",1,`=`length_salud'-1')']"
		noisily di in w "PROYOTROS: [`=substr("`proy_otros'",1,`=`length_otros'-1')']"
		noisily di in w "PROYENERG: [`=substr("`proy_energia'",1,`=`length_energia'-1')']"
		noisily di in w "PROYINVER: [`=substr("`proy_inversiones'",1,`=`length_inversiones'-1')']"
		capture log off output
		restore
	}


	***************************
	** 5.6 Costo de la deuda **
	collapse (sum) gasto* estimacion* (max) pibY deflator lambda Poblacion* if anio <= `end', by(anio) fast
	merge 1:1 (anio) using `shrfsp', nogen keep(matched) keepus(shrfsp* rfsp* /*nopresupuestario*/ tipoDeCambio tasaEfectiva costodeuda*)
	* keep(master match): los ingresos no pueden reintroducir anios que el frame
	* de deuda (SHRFSP) no cubre — una fila con ingresos y sin gasto/poblacion
	* salia como gasto 0 y RFSP 0 en el ultimo anio (2026-09-12). El horizonte
	* efectivo es el MINIMO de PIB, SHRFSP y bootstraps; se reporta en 5.9b. *
	merge 1:1 (anio) using `baseingresos', nogen keep(master match)
	tsset anio

	* Actualización de la deuda *
	g gastoCosto_de_la_deuda = costodeudaInterno + costodeudaExterno
	g estimacionCosto_de_la_deuda = gastoCosto_de_la_deuda if gastoCosto_de_la_deuda != .
	* En `anio' el costo financiero es el del PEF (ya dentro de estimacionGasto
	* via 5.3); las iteraciones de 5.9 arrancan en `anio'+1. *
	replace estimacionCosto_de_la_deuda = estimacionCostoPEF if anio == `anio' & estimacionCostoPEF > 0
	* Diferimiento de pagos: observado hasta `anio'; despues, proporcional al
	* gasto neto devengado con la razon de `anio' (supuesto declarado). *
	sum diferimientos if anio == `anio', meanonly
	local dif_anio = r(sum)
	sum estimacionGasto if anio == `anio', meanonly
	local difratio = cond(r(sum) > 0, `dif_anio'/r(sum), 0)
	* Diferimiento de `anio' como % del PIB, para la ecuacion del sitio:
	* output.do lo resta en GASTOS[40] (gasto neto PAGADO = devengado -
	* diferimientos), de modo que INGRESOS - GASTOS cierre con el balance
	* presupuestario de 5.9b y no con el devengado. 0 si la LIF no lo trae. *
	sum pibY if anio == `anio', meanonly
	escalar pctpib difpagosPIB = cond(r(sum) > 0, `dif_anio'/r(sum)*100, 0)
	format estimacion* gasto* %20.0fc

	* Reemplazar tasaEfectiva con la media artimética desde el año `desde' *
	replace tasaEfectiva = gastoCosto_de_la_deuda/L.shrfsp*100
	tabstat tasaEfectiva if anio <= `anio' & anio >= `anio'-5, save
	tempname tasaEfectiva_ari
	matrix `tasaEfectiva_ari' = r(StatTotal)
	replace tasaEfectiva = r(StatTotal)[1,1] if anio >= `anio'
	local tasaEfectiva = r(StatTotal)[1,1]

	* Scalar Costo_de_la_deuda (gascosto) *
	capture confirm scalar gascosto
	if _rc == 0 {
		* gascosto es % del PIB (SIM.do 5.1 / GastoPC 7.2 / GASTOS[34] del sitio),
		* NO per capita: antes se multiplicaba por Poblacion y el costo de `anio'
		* salia ~0 (PROYCOSTO 2027 = 0.0; fila Costo_financiero de 5.9b). v8.3.0 *
		replace estimacionCosto_de_la_deuda = scalar(gascosto)/100*pibY if anio == `anio'
		replace gastoCosto_de_la_deuda = estimacionCosto_de_la_deuda if anio == `anio'

		* Reestimar la tasa efectiva para el año `anio' *
		replace tasaEfectiva = `tasaEfectiva' if anio >= `anio'
		replace gastoCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio >= `anio'
	}

	* Reemplazar tasasEfectivas con el escalar tasasEfectiva *
	capture confirm scalar tasaEfectiva
	if _rc == 0 {
		replace tasaEfectiva = scalar(tasaEfectiva) if anio >= `anio'
		replace gastoCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio >= `anio'
	}
	else {
		scalar tasaEfectiva = `tasaEfectiva'		
	}
	format %20.0fc *Costo_de_la_deuda


	**********************/
	** 5.7 Tipo de cambio *
	g depreciacion = tipoDeCambio-L.tipoDeCambio

	* Reemplazar depreciacion por el último valor observado para los años futuros *
	tabstat depreciacion if anio >= `anio'-5 & anio <= `anio', stat(mean) f(%20.3fc) save
	replace depreciacion = r(StatTotal)[1,1] if depreciacion == .

	* SHRFSP externo en USD *
	*g shrfspExternoUSD = shrfspExterno/tipoDeCambio
	replace tipoDeCambio = L.tipoDeCambio + L.depreciacion if anio >= `anio' & tipoDeCambio == .
	replace shrfspExternoUSD = shrfspExterno/tipoDeCambio

	g efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)
	g difshrfsp = shrfsp - L.shrfsp - efectoTipoDeCambio - rfsp if anio >= 2009
	format shrfspExternoUSD efectoTipoDeCambio difshrfsp %20.0fc

	* Efecto acumulado del tipo de cambio y los rfsp *
	tabstat efectoTipoDeCambio rfsp difshrfsp if anio >= 2009, stat(sum) f(%20.0fc) save
	tempname ACT
	matrix `ACT' = r(StatTotal)


	*********************************
	** 5.8 Saldo final de la deuda **
	forvalues k=`=_N'(-1)1 {
		if shrfsp[`k'] != . & "`lastfound'" != "yes" {
			local obslast = `k'
			local lastfound = "yes"
		}
		if anio[`k'] == 2009 & "`lastfound'" == "yes" {
			local obsfirs = `k'
		}
		if anio[`k'] == `desde' {
			local obsdesde = `k'
		}
	}
	if "`lastfound'" == "yes" & "`obsfirs'" == "" {
		local obsfirs = 1
	}
	local shrfspobslast = shrfsp[`obslast']/pibY[`obslast']*100

	* Actualizacion de los saldos *
	if (`ACT'[1,1]+`ACT'[1,2]) != 0 {
		local actualizacion_geo = (((shrfsp[`obslast']-shrfsp[`obsfirs'])/(`ACT'[1,1]+`ACT'[1,2]))^(1/(`obslast'-`obsfirs'))-1)*100
	}
	else {
		local actualizacion_geo = 0
		noisily di in r "      {bf:WARNING}: Denominador cero en actualización geométrica. Usando 0%."
	}
	g actualizacion = `actualizacion_geo'

	* Otros rfsp (% del PIB) *
	foreach k of varlist rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones {
		replace `k'_pib = L.`k'_pib if `k'_pib == .
		replace `k' = `k'_pib/100*pibY if `k' == . //deflator
	}


	**********************************************************
	** 5.9 Iteraciones para el costo financiero de la deuda **
	* Arranque: `anio'+1 — el motor proyecta costo, gasto, RFSP y SHRFSP desde el
	* anio siguiente y SOBREESCRIBE lo que el CGPE (exogenos de SIM.do via SHRFSP)
	* traiga para esos anios; `anio' se respeta como ancla exogena. Si el ancla
	* no existe (maquina sin exogenos), arranca en `anio'. Regla anterior ("primer
	* anio sin shrfsp") no corria NUNCA cuando el CGPE cubria todo el horizonte
	* (2026-09-12: costo y primario en "." de 2028 en adelante). *
	local kstart = `anio'+1
	forvalues k = 1/`=_N' {
		if anio[`k'] == `anio' & shrfsp[`k'] == . local kstart = `anio'
	}
	forvalues k = `kstart'(1)`=anio[_N]' {

		* Costo de la deuda (solo > `anio': en `anio' el costo es el del PEF y ya
		* esta dentro de estimacionGasto; los diferimientos de `anio' son los de la LIF) *
		if `k' > `anio' {
			replace estimacionCosto_de_la_deuda = tasaEfectiva/100*L.shrfsp if anio == `k'
			replace estimacionGasto = estimacionGasto + estimacionCosto_de_la_deuda if anio == `k'
			replace diferimientos = `difratio'*estimacionGasto if anio == `k'
		}

		* RFSP: balance presupuestario = ingresos - gasto neto PAGADO (devengado - diferimientos) *
		replace rfspBalance = -estimacionRecaudacion + (estimacionGasto - diferimientos) if anio == `k'
		replace rfsp = (rfspBalance /*+ rfspPIDIREGAS + rfspIPAB + rfspFONADIN + ///
			rfspDeudores + rfspBanca*/ + rfspAdecuaciones) if anio == `k'

		* SHRFSP *
		replace shrfspExternoUSD = L.shrfspExterno/L.tipoDeCambio if anio == `k'
		replace efectoTipoDeCambio = shrfspExternoUSD*(tipoDeCambio-L.tipoDeCambio)

		replace shrfspExterno = L.shrfspExterno*(1+`actualizacion_geo'/100) + efectoTipoDeCambio ///
			+ rfsp*L.shrfspExterno/L.shrfsp if anio == `k'
		replace shrfspInterno = L.shrfspInterno*(1+`actualizacion_geo'/100) ///
			+ rfsp*L.shrfspInterno/L.shrfsp if anio == `k'

		replace shrfsp = shrfspExterno + shrfspInterno if anio == `k'
	}

	replace shrfsp_pib = shrfsp/pibY*100 //if anio >= `anio'
	replace estimacionGasto_pib = estimacionGasto/pibY*100 //if anio >= `anio'

	replace rfsp_pib = rfsp/pibY*100

	replace rfspOtros = rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores + rfspBanca + rfspAdecuaciones
	replace rfspOtros_pib = rfspOtros/pibY*100
	format *_pib %7.1fc

	g shrfspPC = shrfsp/Poblacion/deflator
	g shrfspPC_mil = shrfspPC/1000
	format shrfspPC* %10.0fc

	** 5.9b Estimacion de las finanzas publicas, `anio'-`end' **
	* La aritmetica, fila por fila (signos SHCP: negativo = deficit):
	*   (+) Ingresos presupuestarios          ing   [LIF sin deuda ni diferimientos]
	*   (-) Gasto neto devengado              gas   [PEF: primario + costo financiero]
	*        Gasto primario                   gas - cos
	*        Costo financiero                 cos
	*   (+) Diferimiento de pagos             dif   [LIF divCIEP 8; > anio: razon dif/gas de anio]
	*   (=) Gasto neto pagado                 gas - dif
	*   (=) Balance presupuestario            ing - (gas - dif)
	*   (+) Req. financieros extrapresup.     -(rfsp - rfspBalance)  [lo que el motor suma al RFSP]
	*   (=) RFSP                              balance + req. extrapresup.
	*        Superavit economico primario     balance + cos
	*   SHRFSP                                shr
	* Todo se calcula desde los componentes, asi que las sumas cierran por
	* construccion. Si en `anio' el balance del motor difiere del rfspBalance
	* exogeno (CGPE via SHRFSP), se reporta la brecha como memo. *
	local nanios = `end'-`anio'+1
	local filas Ingresos_presup Gasto_devengado Gasto_primario Costo_financiero Diferimientos Gasto_pagado Balance_presup Req_extrapresup RFSP Superavit_prim SHRFSP
	local nf : word count `filas'
	matrix Proy_finanzas = J(`nf', `nanios', .)
	matrix Proy_fiscal   = J(`nf', `nanios', .)
	local colnames ""
	local j = 0
	local brecha_anio = .
	forvalues y = `anio'/`end' {
		local ++j
		local colnames "`colnames' a`y'"
		sum pibY if anio == `y', meanonly
		if r(N) == 0 continue
		local pib = r(sum)
		tempname v
		foreach f in ing gas cos dif rfb rfs shr {
			scalar `v'`f' = .
		}
		sum estimacionRecaudacion if anio == `y', meanonly
		if r(N) > 0 scalar `v'ing = r(sum)
		sum estimacionGasto if anio == `y', meanonly
		if r(N) > 0 scalar `v'gas = r(sum)
		sum estimacionCosto_de_la_deuda if anio == `y', meanonly
		if r(N) > 0 scalar `v'cos = r(sum)
		sum diferimientos if anio == `y', meanonly
		if r(N) > 0 scalar `v'dif = r(sum)
		sum rfspBalance if anio == `y', meanonly
		if r(N) > 0 scalar `v'rfb = r(sum)
		sum rfsp if anio == `y', meanonly
		if r(N) > 0 scalar `v'rfs = r(sum)
		sum shrfsp if anio == `y', meanonly
		if r(N) > 0 scalar `v'shr = r(sum)

		tempname bal req
		scalar `bal' = `v'ing - (`v'gas - `v'dif)
		scalar `req' = -(`v'rfs - `v'rfb)
		if `y' == `anio' & `v'rfb != . {
			local brecha_anio = `bal' - (-`v'rfb)
		}
		matrix Proy_finanzas[1,`j']  = `v'ing
		matrix Proy_finanzas[2,`j']  = `v'gas
		matrix Proy_finanzas[3,`j']  = `v'gas - `v'cos
		matrix Proy_finanzas[4,`j']  = `v'cos
		matrix Proy_finanzas[5,`j']  = `v'dif
		matrix Proy_finanzas[6,`j']  = `v'gas - `v'dif
		matrix Proy_finanzas[7,`j']  = `bal'
		matrix Proy_finanzas[8,`j']  = `req'
		matrix Proy_finanzas[9,`j']  = `bal' + `req'
		matrix Proy_finanzas[10,`j'] = `bal' + `v'cos
		matrix Proy_finanzas[11,`j'] = `v'shr
		forvalues r = 1/`nf' {
			matrix Proy_fiscal[`r',`j'] = Proy_finanzas[`r',`j']/`pib'*100
			matrix Proy_finanzas[`r',`j'] = Proy_finanzas[`r',`j']/1e6
		}
	}
	matrix colnames Proy_finanzas = `colnames'
	matrix colnames Proy_fiscal   = `colnames'
	matrix rownames Proy_finanzas = `filas'
	matrix rownames Proy_fiscal   = `filas'

	local rotulos `" "(+) Ingresos presupuestarios" "(-) Gasto neto devengado" "      Gasto primario" "      Costo financiero" "(+) Diferimiento de pagos" "(=) Gasto neto pagado" "(=) Balance presupuestario" "(+) Req. fin. extrapresup." "(=) RFSP" "      Superavit econ. primario" "SHRFSP" "'
	noisily di _newline in g "{bf: B. Estimaci{c o'}n de las finanzas p{c u'}blicas `anio'-`end'}"
	noisily di in g "  Millones de `currency' (signos SHCP: negativo = d{c e'}ficit)"
	noisily _fg_matdisplay Proy_finanzas, cols(`nanios') fmt(%12.0fc) rotulos(`rotulos')
	noisily di _newline in g "  % del PIB"
	noisily _fg_matdisplay Proy_fiscal, cols(`nanios') fmt(%8.2f) rotulos(`rotulos')
	noisily di in g "  Balance = Ingresos - Gasto pagado; Gasto pagado = Devengado - Diferimientos; RFSP = Balance + Req. extrapresup.; Super{c a'}vit primario = Balance + Costo financiero."
	noisily di in g "  Diferimientos > `anio': razon diferimientos/gasto devengado de `anio' (" in y %5.2f `difratio'*100 in g " %)."
	if `brecha_anio' != . & abs(`brecha_anio') > 1 {
		noisily di in g "  Memo `anio': balance del motor vs rfspBalance ex{c o'}geno (CGPE/SHRFSP): brecha " in y %12.0fc `brecha_anio'/1e6 in g " mill."
	}
	if anio[_N] < `end' {
		noisily di in g "  Horizonte efectivo: " in y anio[_N] in g " (end(`end') rebasa la proyecci{c o'}n disponible; columnas posteriores en .)."
	}

	****************
	** 5.10 Graphs **
	if "`nographs'" != "nographs" & "$nographs" != "nographs" {
		if "$export" == "" {
			local graphtitle "{bf:RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar rfsp_pib anio if anio < `anio' & anio >= `desde', barwidth(.75)) ///
			(bar rfsp_pib anio if anio >= `anio' & anio <= `end', barwidth(.75) ///
				pstyle(p1) lcolor(none) fintensity(50)) ///
			(bar rfspOtros_pib anio if anio < `anio' & anio >= `desde', barwidth(.75)) ///
			(bar rfspOtros_pib anio if anio >= `anio' & anio <= `end', barwidth(.75) ///
				pstyle(p3) lcolor(none) fintensity(50)) ///
			(connected rfsp_pib anio if anio >= `desde' & anio <= `end', ///
				mlabel(rfsp_pib) mlabposition(12) mlabcolor(black) pstyle(p2) ///
				lpattern(dot) msize(small) mlabsize(small)) ///
			if rfsp_pib != ., ///
			title(`graphtitle') subtitle($pais) ///
			caption("`graphfuente'") ///
			ytitle("% PIB") ///
			xtitle("") ///
			xlabel(`desde'(1)`end', noticks) ///
			legend(on order(1 3) label(1 "RFSP presupuestario") label(3 "Otros RFSP")) ///
			text(0 `desde' "{bf:Observado}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			text(0 `=`anio'+3' "{bf:Proyección CIEP}", ///
				yaxis(1) size(medium) place(1) justification(right) bcolor(white) box) ///
			name(Proy_rfsp, replace)
			
		if "$export" != "" {
			graph export `"$export/Proy_rfsp.png"', replace name(Proy_rfsp)
		}


		* Saldo de la deuda combinada *
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected shrfsp_pib anio if anio < `anio', ///
				mlabel(shrfsp_pib) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge)) ///
			(connected shrfsp_pib anio if anio >= `anio', ///
				mlabel(shrfsp_pib) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge)) ///			
			(bar shrfspPC_mil anio if anio < `anio', ///
				mlabel(shrfspPC_mil) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge) yaxis(2) pstyle(p1) barwidth(.75)) ///
			(bar shrfspPC_mil anio if anio >= `anio', ///
				mlabel(shrfspPC_mil) mlabpos(12) mlabcolor(black) mlabgap(0) mlabsize(medlarge) yaxis(2) pstyle(p2) barwidth(.75)) ///
			if anio >= `aniomin', ///
			///title("`graphtitle'") ///
			///subtitle("Indicadores de la deuda") ///
			///caption("`graphfuente'") ///
			xtitle("") ///
			yscale(range(-50)) ///
			yscale(range(0 250) axis(2) lwidth(none)) ///
			ylabel(none, axis(2) noticks) ///
			ylabel(none, axis(1) noticks) ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xlabel(`aniomin'(1)`end') ///
			legend(off label(1 "Como % del PIB") label(2 "Por persona ajustada")) ///
			text(`=shrfsp_pib[`obsdesde']*.925' `=anio[`obsdesde']' "{bf:Como % del PIB}", ///
				place(5) color("111 111 111") size(medsmall)) ///
			text(0 `=anio[`obsdesde']' "{bf:Por persona (miles `currency' `=aniovp')}", ///
				place(1) color(black) size(medsmall) yaxis(2) bcolor(white) box) ///
			text(0 `=`anio'+3' "{bf:Proyección CIEP}", ///
				place(1) color(black) size(medsmall) yaxis(2) bcolor(white) box) ///
			name(Proy_combinado, replace)

		if "$export" != "" {
			graph export `"$export/Proy_combinado.png"', replace name(Proy_combinado)
		}
	}


	*****************
	** 5.11 Outputs **
	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio' & anio[`k'] >= 2013 {
				local proy_costo = "`proy_costo' `=string(`=gastoCosto_de_la_deuda[`k']/pibY[`k']*100',"%10.1fc")',"
			}
			if anio[`k'] >= `anio' & anio[`k'] <= `end' {
				local proy_costo = "`proy_costo' `=string(`=estimacionCosto_de_la_deuda[`k']/pibY[`k']*100',"%10.1fc")',"
			}
		}
		local length_costo = strlen("`proy_costo'")
		capture log on output
		noisily di in w "PROYCOSTO: [`=substr("`proy_costo'",1,`=`length_costo'-1')']"
		capture log off output
	}


	*********************
	** 5.12 (VP/infinito de gastos retirados 2026-09-12, misma decision que 4.6;
	**       la trayectoria anual vive en Proy_fiscal) **

	* Save *
	*rename estimacion estimaciongastos
	tempfile basegastos
	save `basegastos'


	* Saldo de la deuda *
	tabstat shrfsp deflator shrfsp_pib if anio == `anio', stat(sum) f(%20.0fc) save
	tempname shrfsp
	matrix `shrfsp' = r(StatTotal)



	*****************************
	***                       ***
	**# 7 Fiscal Gap: Balance ***
	***                       ***
	****************************
	if "`estimacionINF'" == "" {
		noisily di in g "  " _dup(61) "-"
		noisily di in g "  Balance en VP: desactivado (ingresos VP retirados en 4.6; pendiente de la reestructura)."
	}
	else {
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Balance futuro en VP:" ///
		in y _col(35) %25.0fc `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	

	noisily di in g "  (+) Deuda (" in y `=`anio'' in g "):" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Finan. wealth futuro en VP:" ///
		in y _col(35) %25.0fc -`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1] ///
		in g " `currency'"	
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Wealth/Ingresos futuros:" ///
		in y _col(35) %25.1fc -(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`estimacionINF'+`estimacionVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (=) Wealth/Gastos futuros:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`gastoINF'+`gastoVP'[1,1])*100 ///
		in g " %"	
	noisily di in g "  (=) Wealth/PIB futuro:" ///
		in y _col(35) %25.1fc (-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/scalar(pibVPINF)*100 ///
		in g " %"
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (=) Deuda (" in y `end' in g ") :" ///
		in y _col(35) %25.0fc shrfsp_pib[_N] ///
		in g " % PIB"
	scalar shrfspgeneINI = string(`shrfsp'[1,3],"%5.1fc")
	scalar shrfspgeneFIN = string(shrfsp_pib[_N],"%5.1fc")
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Tasa Efectiva Promedio: " in y _col(35) %25.4fc scalar(tasaEfectiva) in g " %"
	noisily di in g "  (*) Discount rate:" in y _col(35) %25.4fc `discount' in g " %"
	noisily di in g "  (*) Actualización deuda:" in y _col(35) %25.4fc `actualizacion_geo' in g " %"
	}





	****************************************/
	*** 6 Fiscal Gap: Cuenta Generacional ***
	*****************************************
	local endef = anio[_N]					// horizonte efectivo (puede ser < end; ver 5.9b)
	tabstat Poblacion0 Poblacion if (anio == `anio' | anio == `endef'), stat(sum) save f(%20.0fc) by(anio)
	tempname poblacionACT poblacionEND
	matrix `poblacionACT' = r(Stat1)
	matrix `poblacionEND' = r(Stat2)


	******************
	** Poblacion VP **
	g poblacionVP = Poblacion0/(1+`discount'/100)^(anio-`anio')
	format poblacionVP %20.0fc

	tabstat poblacionVP if anio > `anio', stat(sum) f(%20.0fc) save
	tempname poblacionVP
	matrix `poblacionVP' = r(StatTotal)

	* Calcular tasa de crecimiento poblacional (robusto) *
	count if anio > `anio'
	local obs_futuras_pob = r(N)
	local periodo_LR_pob = min(10, `obs_futuras_pob')
	if `periodo_LR_pob' < 2 {
		local periodo_LR_pob = 2
	}
	
	if Poblacion0[_N-`periodo_LR_pob'] > 0 & Poblacion0[_N] > 0 {
		local grow_rate_LR_pob = (((Poblacion0[_N]/deflator[_N])/(Poblacion0[_N-`periodo_LR_pob']/deflator[_N-`periodo_LR_pob']))^(1/`periodo_LR_pob')-1)*100
	}
	else {
		local grow_rate_LR_pob = 1.0
		noisily di in r "      {bf:WARNING}: Usando tasa de crecimiento por defecto (`grow_rate_LR_pob'%) para población"
	}

	* Validar que grow_rate < discount para perpetuidad *
	if `grow_rate_LR_pob' >= `discount' {
		noisily di in r "      {bf:ERROR}: Tasa crecimiento población (`grow_rate_LR_pob'%) >= tasa de descuento (`discount'%)"
		noisily di in r "      Ajustando tasa de crecimiento a `=`discount'-0.5'%"
		local grow_rate_LR_pob = `discount' - 0.5
	}
	local poblacionINF = poblacionVP[_N]/(1-((1+`grow_rate_LR_pob'/100)/(1+`discount'/100)))

	noisily di _newline(2) in g "{bf: INEQUIDAD INTERGENERACIONAL:" in y " $pais `anio' }"
	*noisily di in g "  (*) Poblaci{c o'}n futura VP: " in y _col(35) %25.0fc `poblacionVP'[1,1] in g " personas"
	*noisily di in g "  (*) Poblaci{c o'}n futura INF: " in y _col(35) %25.0fc `poblacionINF' in g " personas"
	*noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaciones " in y "`anio'" in g ":" in y _col(35) %25.0fc (`shrfsp'[1,1]/`shrfsp'[1,2])/(`poblacionACT'[1,2]) in g " `currency' por persona"
	noisily di in g "  (*) Deuda generaciones " in y "`endef'" in g ":" in y _col(35) %25.0fc (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2]) in g " `currency' por persona"
	local deudagenlast = (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2])
	scalar deudageneINI = string((`shrfsp'[1,1]/`shrfsp'[1,2])/(`poblacionACT'[1,2]),"%10.1fc")
	scalar deudageneFIN = string((shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2]),"%10.1fc")

	* Inequidad intergeneracional (requiere ingresos VP; ver 4.6) *
	if "`estimacionINF'" != "" {
	noisily di in g "  " _dup(61) "-"
	noisily di in g "  (*) Deuda generaci{c o'}n futura:" ///
		in y _col(35) %25.0fc -(-`shrfsp'[1,1] + `estimacionINF' + `estimacionVP'[1,1] - `gastoINF' - `gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF') ///
		in g " `currency' por persona"
	local deudageninf = -(-`shrfsp'[1,1] + `estimacionINF' + `estimacionVP'[1,1] - `gastoINF' - `gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF')
	noisily di in g "  (*) Inequidad intergeneracional:" ///
		in y _col(35) %25.0fc (`deudageninf'/`deudagenlast'-1)*100 ///
		in g " %"
	capture confirm matrix GA
	if _rc == 0 {
		noisily di in g "  (*) Inequidad GA:" ///
			in y _col(35) %25.0fc ((-(-`shrfsp'[1,1] + `estimacionINF'+`estimacionVP'[1,1] - `gastoINF'-`gastoVP'[1,1])/(`poblacionVP'[1,1]+`poblacionINF'))/GA[1,3]-1)*100 ///
			in g " %"
	}
	}


	** Output **
	if "$output" != "" {
		forvalues k=1(1)`=_N' {
			if anio[`k'] < `anio' & anio[`k'] >= 2013 {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' null,"
			}
			if anio[`k'] == `anio' {
				local proy_shrfsp = "`proy_shrfsp' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(`shrfspobslast',"%10.3f")',"
				*local proy_shrfsp = "`proy_shrfsp' `=string(51.000,"%10.3f")',"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
			}
			if anio[`k'] > `anio' & anio[`k'] <= `end' {
				local proy_shrfsp = "`proy_shrfsp' null,"
				local proy_shrfsp2 = "`proy_shrfsp2' `=string(`=shrfsp_pib[`k']',"%10.3f")',"
			}
		}
		local length_shrfsp = strlen("`proy_shrfsp'")
		local length_shrfsp2 = strlen("`proy_shrfsp2'")
		capture log on output
		noisily di in w "PROYSHRFSP1: [`=substr("`proy_shrfsp'",1,`=`length_shrfsp'-1')']"
		noisily di in w "PROYSHRFSP2: [`=substr("`proy_shrfsp2'",1,`=`length_shrfsp2'-1')']"	
		noisily di in w "PROYSHRFSP3: [" ///
			%10.0f (`shrfsp'[1,1]/`shrfsp'[1,2])/(`poblacionACT'[1,2]) "," ///
			%10.0f (shrfsp[_N]/deflator[_N])/(`poblacionEND'[1,2]) ///
			"]"
		noisily di in w "ANIOBASE: [`anio']"
		noisily di in w "ANIOEND: [`end']"
		quietly log off output
	}

	if "$textbook" == "textbook" {
		noisily scalarlatex, log(fiscalgap) alt(gap)
	}

	************************/
	**** Touchdown!!! :) ****
	*************************
	timer off 11
	timer list 11
	noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t11)/r(nt11)',.1) in g " segs  " _dup(20) "."
}
end


* Despliega una matriz (filas x anios) en bloques de `cols' columnas: encabezado
* con los anios (colnames a<anio>) y una linea por fila, para caber en 80 chars. *
program define _fg_matdisplay
	syntax name(name=mat), [COLS(int 8) FMT(string) ROTulos(string asis)]
	if "`fmt'" == "" local fmt "%8.2f"
	local w = 8
	if regexm("`fmt'","%([0-9]+)") local w = real(regexs(1))
	local nc = colsof(`mat')
	local nr = rowsof(`mat')
	local cn : colnames `mat'
	local rn : rownames `mat'
	local j = 1
	while `j' <= `nc' {
		local jmax = min(`j'+`cols'-1, `nc')
		local hdr ""
		forvalues c = `j'/`jmax' {
			local y : word `c' of `cn'
			local hdr `"`hdr' `: di %`w's subinstr("`y'","a","",1)'"'
		}
		local lw = cond(`"`rotulos'"' != "", 30, 16)
		noisily di in g _col(`=`lw'+3') `"`hdr'"'
		forvalues r = 1/`nr' {
			local val ""
			forvalues c = `j'/`jmax' {
				local val `"`val' `: di `fmt' `mat'[`r',`c']'"'
			}
			if `"`rotulos'"' != "" {
				local lab : word `r' of `rotulos'
			}
			else {
				local lab : word `r' of `rn'
				local lab = subinstr("`lab'","_"," ",.)
			}
			noisily di in g "  " %-`lw's `"`lab'"' in y `"`val'"'
		}
		local j = `jmax'+1
	}
end
