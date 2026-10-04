*! version 8.0 CIEP 03jul2026
program define DatosAbiertos, return
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
quietly {

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "${SIMROOT}/master/DatosAbiertos.dta", clear
	if _rc != 0 {
		noisily UpdateDatosAbiertos, zipfile
	}
	capture use "${SIMROOT}/master/Deflactor.dta", clear
	if _rc != 0 {
		noisily UpdateDeflactor
	}

	** 0.2 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)	
	}

	** 0.3 Sintaxis del comando **
	syntax [anything] [if] [,  PIBVP(real -999) PIBVF(real -999) DESDE(real 2008) ///
		UPDATE NOGraphs REVERSE PROYeccion ZIPFILE CSVFILE LOCal]



	***********************
	*** 1 Base de datos ***
	***********************
	if "`update'" == "update" | "`local'" == "local" {
		noisily UpdateDatosAbiertos, `update' `zipfile' `csvfile' `local'
		noisily UpdateDeflactor
	}
	
	PIBDeflactor, nographs
	
	use if clave_de_concepto == "`anything'" using "${SIMROOT}/master/DatosAbiertos.dta", clear
	*drop in -1
	merge 1:1 (anio mes) using "${SIMROOT}/master/Deflactor.dta", nogen keep(matched)
	merge m:1 (anio) using "${SIMROOT}/master/Poblaciontot.dta", nogen keep(matched)
	merge m:1 (anio trimestre) using "${SIMROOT}/master/PIBDeflactor.dta", nogen

	** Limpiar **
	tsset aniomes
	drop if aniomes == .
	order inpc, last
	local currency = currency[1]
	foreach k of varlist inpc {
		capture confirm numeric variable `k'
		if _rc == 0 {
			replace `k' = L.`k' if `k' == .
		}
	}
	
	*g lambda = (1+scalar(llambda)/100)^(anio-`aniovp')
	*replace poblacion = poblacion*lambda

	if "`anything'" == "" {
		use "${SIMROOT}/master/DatosAbiertos.dta", clear
		exit
	}
	if `=_N' == 0 {
		noisily di in r "No se encontr{c o'} la serie {bf:`anything'}."
		exit
	}
	if "`reverse'" == "reverse" {
		replace monto = -monto
	}
	tsset aniomes
	sort aniomes
	local last_anio = anio[_N]
	local last_mes = mes[_N]

	* Acentos *
	replace nombre = "Saldo histórico de los RFSP" if nombre == "Saldo hist?rico de los RFSP"
	replace nombre = "Saldo histórico de los RFSP internos" if nombre == "Saldo hist?rico de los RFSP internos"
	replace nombre = "Saldo histórico de los RFSP externos" if nombre == "Saldo hist?rico de los RFSP externos"
	replace nombre = "Requerimientos financieros del sector público" if nombre == "Requerimientos financieros del sector p¿¿blico federal (I+II)"
	replace nombre = "Requerimientos financieros del sector público" if nombre == "Requerimientos financieros del sector p??blico federal (I+II)"


	*********************************
	** 1.1 Informacion de la serie **
	noisily di _newline in g " Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."
	
	if "`if'" != "" {
		keep `if'
	}
	
	tempvar deflactormes deflactoracum deflactor
	g `deflactoracum' = inpc if mes <= mes[_N]
	egen deflactoracum = mean(`deflactoracum'), by(anio)
	replace deflactoracum = deflactoracum/deflactoracum[_N]

	g `deflactormes' = inpc if mes == mes[_N]
	egen deflactormes = mean(`deflactormes'), by(anio)
	replace deflactormes = deflactormes/deflactormes[_N]
	
	g deflactor = inpc/inpc[_N]

	tempvar crecreal
	g montomill = monto/1000000
	format montomill %20.0fc

	g monto_pc = monto/poblacion/deflactor
	format monto_pc %10.0fc

	egen pibY = mean(pibQ), by(anio)
	g monto_pib = monto/pibY*100
	format monto_pib %7.1fc

	g `crecreal' = (montomill/L12.montomill-1)*100

	label define mes 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" ///
		7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
	label values mes mes
	local mesname : label mes `=mes[_N]'
	local mesnameant : label mes `=mes[`=_N-1']'

	if tipo_de_informacion == "Flujo" {
		tabstat montomill deflactoracum deflactormes if mes == `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%10.3fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Mes " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1]/`meshoy'[1,3] in g " millones `currency'"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1]/`mesant'[1,3] in g " millones `currency' `aniovp'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc ((`meshoy'[1,1]/`meshoy'[1,3])/(`mesant'[1,1]/`mesant'[1,3])-1)*100 in g " %"

		tabstat montomill if mes <= `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%10.3fc) save
		tempname meshoyacum mesantacum
		matrix `meshoyacum' = r(Stat2)
		matrix `mesantacum' = r(Stat1)

		noisily di _newline(2) in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoyacum'[1,1]/`meshoy'[1,2] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesantacum'[1,1] in g " millones `currency'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesantacum'[1,1]/`mesant'[1,2] in g " millones `currency' `aniovp'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc ((`meshoyacum'[1,1]/`meshoy'[1,2])/(`mesantacum'[1,1]/`mesant'[1,2])-1)*100 in g " %"
	}

	replace montomill = montomill/deflactor

	if tipo_de_informacion == "Saldo" {
		tabstat montomill if ((anio == `last_anio'-1 & mes == 12) | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline(2) in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "Diciembre `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat montomill if ((anio == `last_anio'-1 & mes == `last_mes') | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"
	}

	tempvar finishedY finishedYY
	g `finishedY' = mes == 12
	egen `finishedYY' = max(`finishedY'), by(anio)

	tempvar montoanual propmensual
	egen `montoanual' = sum(monto) if `finishedYY' == 1 & anio >= `desde', by(anio)
	g propmensual = monto/`montoanual' if `finishedYY' == 1 & anio >= `desde'
	egen acum_prom = mean(propmensual), by(mes)


	****************************
	*** 2 Proyeccion mensual ***
	****************************
	if "`nographs'" != "nographs" & tipo_de_informacion == "Flujo" {

		** 2.1 Título de la gráfica **
		local length = length("`=nombre[1]'")
		if `length' > 60 {
			*local textsize ", size(medium)"
		}
		if `length' > 90 {
			*local textsize ", size(large)"
		}
		if `length' > 110 {
			*local textsize ", size(large)"
		}

		* Fuente *
		if "$export" == "" {
			local graphtitle `""{bf:`=nombre[1]'}"`textsize'"'
			local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP."
		}
		else {
			local graphfuente ""
		}

		** 2.2 Gráfica por mes calendario **
		local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"
		tokenize "`meses'"
		tabstat acum_prom if `finishedYY' == 1, stat(mean) by(mes) f(%20.3fc) save
		forvalues k=1(1)12 {
			label define mes `k' "``k'' (`=string(r(Stat`k')[1,1]*100,"%7.1fc")'%)", modify
			local ++k
		}

		graph bar (sum) monto_pib if monto_pib != . & anio >= `desde', over(mes) over(anio) stack asyvar ///
			legend(rows(2) size(medium)) ///
			name(M`anything', replace) blabel(none) ///
			ytitle("% PIB") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title(`graphtitle') ///
			ylabel(, format(%15.0fc)) ///
			note("Las cifras entre paréntesis representan la distribución promedio mensual desde `desde'.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/M`anything'.png", replace name(M`anything')
		}


		** 2.3 Gráfica por mes **
		graph bar (sum) montomill if mes == `=mes[_N]' & anio >= `desde', over(anio) ///
			name(`mesname'`anything', replace) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(" `mesname', millones de `=currency[1]' `aniovp'", margin(bottom)) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(none, format(%15.0fc)) ///
			blabel(bar, format(%10.0fc) color(white) size(small) orient(vertical)) ///
			legend(off) ///
			///yline(0, lcolor(black) lpattern(dash)) ///
			///note("{c U'}ltimo dato: `last_anio'm`last_mes'.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`mesname'`anything'.png", replace name(`mesname'`anything')
		}


		** 2.4 Gráfica acumulado **
		preserve
		collapse (sum) montomill if mes <= `=mes[_N]', by(nombre currency anio)
		tsset anio

		tabstat montomill, stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		graph bar (sum) montomill if anio >= `desde', over(anio) ///
			name(Acum`mesname'`anything', replace) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(`"Acumulado a `=lower("`mesname'")'"', margin(bottom)) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(none, format(%15.0fc)) ///
			yscale(range(0)) ///
			blabel(bar, format(%10.0fc) color(white) size(small) orient(vertical)) ///
			legend(off) ///
			caption("`graphfuente'") ///

		restore
	}



	*************************/
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		
		collapse (sum) monto* acum_prom (lastnm) mes poblacion pibY deflactor Poblacion* if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)

		if "`proyeccion'" == "proyeccion" {
			replace monto = monto/acum_prom if mes < 12
			replace monto_pib = monto/pibY*100 if mes < 12
			replace monto_pc = monto/poblacion/deflactor if mes < 12
			replace montomill = monto/1000000/deflactor if mes < 12
		}

		local textografica `"{bf:Promedio a `mesname'}: `=string(acum_prom[_N]*100,"%5.1fc")'% del total anual."'
		local palabra "Proyectado"
	}
	else if tipo_de_informacion == "Saldo" {
		tempvar maxmes
		egen `maxmes' = max(mes), by(anio)
		sort anio mes
		collapse (last) monto* mes poblacion pibY deflactor if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
		g acum_prom = 1
	}
	*tsset aniomes

	** 2.1 Cifra oficial para el año en curso (% del PIB) **
	if `pibvp' != -999 {
		replace monto = `pibvp'*pibY/100 if anio == `aniovp'
		replace monto_pib = `pibvp' if anio == `aniovp'
		replace montomill = monto/1000000/deflactor if anio == `aniovp'
		replace monto_pc = monto/poblacion/deflactor if anio == `aniovp'
	}

	local prianio = anio in 1
	local ultanio = anio in -1
	local ultmes = mes in -1
	return local ultimoAnio = `ultanio'
	return local ultimoMes = `ultmes'

	** 2.2 Estimación oficial para el año siguiente (% del PIB) **
	local ultgraf = `ultanio'
	if `pibvf' != -999 {
		set obs `=_N+1'
		replace anio = `aniovp'+1 in -1
		replace monto_pib = `pibvf' in -1
		replace nombre = nombre[1] in -1
		replace clave_de_concepto = clave_de_concepto[1] in -1
		replace unidad_de_medida = unidad_de_medida[1] in -1
		sort anio
		local ultgraf = max(`ultanio', `aniovp'+1)
	}

	** 2.1. Grafica **
	if "`nographs'" != "nographs" {

		if "$export" == "" {
			local graphtitle "{bf:`=nombre[1]'}"
		}
		else {
			local graphtitle ""
		}

		tabstat montomill monto_pc monto_pib, by(anio) stat(min max) save
		return list
		tempname rango
		matrix `rango' = r(StatTotal)

		/*twoway (bar montomill anio if inrange(anio, 2001, 2006), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if inrange(anio, 2007, 2012), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if inrange(anio, 2013, 2018), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if inrange(anio, 2019, 2024), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if anio > 2024, ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(connected monto_pc anio if anio > 2000 & anio <= 2006, ///
					yaxis(2) pstyle(p1) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2006 & anio <= 2012, ///	
					yaxis(2) pstyle(p2) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2012 & anio <= 2018, ///
					yaxis(2) pstyle(p3) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2018 & anio <= 2024, ///
					yaxis(2) pstyle(p4) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2024, ///
					yaxis(2) pstyle(p5) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			if anio > 2000, ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y por persona", margin(bottom)) ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			xlabel(`=`prianio'+1'(1)`ultanio') ///
			ylabel(none, format(%15.0fc)) ///
			yscale(range(0 `=`rango'[2,1]*1.75')) ///
			ylabel(none, axis(2) format(%7.0fc) noticks) ///
			yscale(range(0 `=`rango'[1,2]-1.75*(`rango'[2,2]-`rango'[1,2])') noline axis(2)) ///
			legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
			text(`text1', yaxis(2) color(white) size(large)) ///
			caption("`graphfuente'") ///
			note("{c U'}ltimo dato: `ultanio'm`ultmes'.") ///
			name(`anything'PC, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`anything'PC.png", replace name(`anything'PC)
		}*/


		twoway (bar montomill anio if anio < `ultanio' & anio >= `desde', ///
				mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if anio >= `ultanio', ///
				mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(connected monto_pib anio if anio < `ultanio' & anio >= `desde', ///
				yaxis(2) pstyle(p1) mlabel(monto_pib) mlabpos(12) mlabcolor("111 111 111") mlabsize(medium) lpattern(dot) msize(large)) ///
			(connected monto_pib anio if anio >= `ultanio', ///
				yaxis(2) pstyle(p2) mlabel(monto_pib) mlabpos(12) mlabcolor("111 111 111") mlabsize(medium) lpattern(dot) msize(large)), ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y como % del PIB", margin(bottom)) ///
			///b1title(`"`textografica'"') ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			///xlabel(`prianio' `=round(`prianio',5)'(5)`ultanio') ///
			xlabel(`desde'(1)`ultgraf') ///
			ylabel(, format(%15.0fc)) ///
			yscale(range(0 `=`rango'[2,1]*1.75')) ///
			ylabel(none, axis(2) format(%7.0fc) noticks) ///
			yscale(range(0 `=`rango'[1,3]-1.75*(`rango'[2,3]-`rango'[1,3])') noline axis(2)) ///
			legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
			text(`text1', yaxis(2) color(white) size(large)) ///
			caption("`graphfuente'") ///
			note("{c U'}ltimo dato: `ultanio'm`ultmes'.") ///
			name(`anything'PIB, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`anything'PIB.png", replace name(`anything'PIB)
		}
	}
	noisily list anio mes acum_prom monto monto_pib monto_pc, separator(30) string(30)
}
end


program define UpdateDatosAbiertos, return
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)

	syntax [, UPDATE ZIPFILE CSVFILE LOCal]

	** Modo de obtención de los datos (ver _DAdescarga):
	**   descarga -> zip con reintento -> csv directo -> archivos locales (default con update/zipfile)
	**   csv      -> csv directo -> archivos locales (opción csvfile)
	**   local    -> usa raw/temp/ sin conexión a internet (opción local)
	if "`local'" == "local" {
		local modo "local"
	}
	else if "`csvfile'" == "csvfile" {
		local modo "csv"
	}
	else {
		local modo "descarga"
	}

	************************
	*** 1. Base de datos ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	local mesvp = substr(`"`=trim("`fecha'")'"',6,2)

	** mkdir no es recursivo: hay que crear el árbol nivel por nivel **
	** (una instalación fresca no trae ni el directorio site/) **
	capture mkdir "${SIMROOT}"
	capture mkdir "${SIMROOT}/raw/"
	capture mkdir "${SIMROOT}/raw/temp/"
	capture mkdir "${SIMROOT}/raw/temp/Datos Abiertos/"
	capture use "${SIMROOT}/master/DatosAbiertos.dta", clear
	if (_rc == 0 & "`update'" != "update" & "`local'" != "local") {	
		sort anio mes
		return local ultanio = anio[_N]
		return local ultmes = mes[_N]
		if (`aniovp' == anio[_N] & `mesvp'-2 <= mes[_N]) | (`aniovp'+1 == anio[_N] & `mesvp'-2 < 0) {
			noisily di _newline in g "Datos Abiertos: " in y "base actualizada." in g " {c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
			return local updated = "yes"
			exit
		}
	}
	noisily di _newline in g "Datos Abiertos: " in y "ACTUALIZANDO. Favor de esperar... (5 min. aprox.)"
	*noisily di in g "{c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."

	*****************************************
	** 1.1 Ingreso, gasto y financiamiento **
	_DAdescarga, nombre(ingreso_gasto_finan) modo(`modo') encoding(utf-8)
	tempfile ing
	save "`ing'"
	
	_DAdescarga, nombre(ingreso_gasto_finan_hist) modo(`modo') encoding(utf-8)
	tempfile ingH
	save "`ingH'"

	***************
	** 1.2 Deuda **
	_DAdescarga, nombre(deuda_publica) modo(`modo') encoding(utf-8)
	tempfile deuda
	save "`deuda'"

	_DAdescarga, nombre(deuda_publica_hist) modo(`modo') encoding(utf-8)
	tempfile deudaH
	save "`deudaH'"

	****************
	** 1.3 SHRFSP **
	_DAdescarga, nombre(shrfsp_deuda_amplia_actual) modo(`modo') encoding(utf-8)
	tempfile shrf
	save "`shrf'"

	_DAdescarga, nombre(shrfsp_deuda_amplia_antes_2014) modo(`modo') encoding(utf-8)
	tempfile shrfH
	save "`shrfH'"

	**************
	** 1.4 RFSP **
	_DAdescarga, nombre(rfsp) modo(`modo') encoding(utf-8)
	tempfile rf
	save "`rf'"

	_DAdescarga, nombre(rfsp_metodologia_anterior) modo(`modo') encoding(utf-8)
	tempfile rfH
	save "`rfH'"

	*************************************************
	** 1.5 Transferencias a Entidades y Municipios **
	_DAdescarga, nombre(transferencias_entidades_fed) modo(`modo') encoding(utf-8)
	tempfile gf
	save "`gf'"

	_DAdescarga, nombre(transferencias_entidades_fed_hist) modo(`modo') encoding(utf-8)
	tempfile gfH
	save "`gfH'"
	
	***********************************************************
	/** 1.6 Asignación y ejecución del presupuesto de egresos **
	_DAdescarga, nombre(asignacion_ejecucion_2025) modo(`modo')
	tempfile asignacion2025
	save "`asignacion2025'"
 

	_DAdescarga, nombre(asignacion_ejecucion_2024) modo(`modo')
	tempfile asignacion2024
	save "`asignacion2024'"

	_DAdescarga, nombre(asignacion_ejecucion_2023) modo(`modo')
	tempfile asignacion2023
	save "`asignacion2023'"

	_DAdescarga, nombre(asignacion_ejecucion_2022) modo(`modo')
	tempfile asignacion2022
	save "`asignacion2022'"

	_DAdescarga, nombre(asignacion_ejecucion_2021) modo(`modo')
	tempfile asignacion2021
	save "`asignacion2021'"

	_DAdescarga, nombre(asignacion_ejecucion_2020) modo(`modo')
	tempfile asignacion2020
	save "`asignacion2020'"

	_DAdescarga, nombre(asignacion_ejecucion_2019) modo(`modo')
	tempfile asignacion2019
	save "`asignacion2019'"

	_DAdescarga, nombre(asignacion_ejecucion_2018) modo(`modo')
	tempfile asignacion2018
	save "`asignacion2018'"

	_DAdescarga, nombre(asignacion_ejecucion_2017) modo(`modo')
	tempfile asignacion2017
	save "`asignacion2017'"

	_DAdescarga, nombre(asignacion_ejecucion_2016) modo(`modo')
	tempfile asignacion2016
	save "`asignacion2016'"

	_DAdescarga, nombre(asignacion_ejecucion_2015) modo(`modo')
	tempfile asignacion2015
	save "`asignacion2015'"

	_DAdescarga, nombre(asignacion_ejecucion_2014) modo(`modo')
	tempfile asignacion2014
	save "`asignacion2014'"

	_DAdescarga, nombre(asignacion_ejecucion_2013) modo(`modo')
	tempfile asignacion2013
	save "`asignacion2013'"

	_DAdescarga, nombre(asignacion_ejecucion_2012) modo(`modo')
	tempfile asignacion2012
	save "`asignacion2012'"

	_DAdescarga, nombre(asignacion_ejecucion_2011) modo(`modo')
	tempfile asignacion2011
	save "`asignacion2011'"

	_DAdescarga, nombre(asignacion_ejecucion_2010) modo(`modo')
	tempfile asignacion2010
	save "`asignacion2010'"

	_DAdescarga, nombre(asignacion_ejecucion_2009) modo(`modo')
	tempfile asignacion2009
	save "`asignacion2009'"

	_DAdescarga, nombre(asignacion_ejecucion_2008) modo(`modo')
	tempfile asignacion2008
	save "`asignacion2008'"

	_DAdescarga, nombre(asignacion_ejecucion_2007) modo(`modo')
	tempfile asignacion2007
	save "`asignacion2007'"

	_DAdescarga, nombre(asignacion_ejecucion_2006) modo(`modo')
	tempfile asignacion2006
	save "`asignacion2006'"

	_DAdescarga, nombre(asignacion_ejecucion_2005) modo(`modo')
	tempfile asignacion2005
	save "`asignacion2005'"

	_DAdescarga, nombre(asignacion_ejecucion_2004) modo(`modo')
	tempfile asignacion2004
	save "`asignacion2004'"

	_DAdescarga, nombre(asignacion_ejecucion_2003) modo(`modo')
	tempfile asignacion2003
	save "`asignacion2003'"



	*************/
	** 2 Append **
	**************/
	** Cada append pasa por _DAappend: si falla, reporta QUÉ base fue y qué **
	** variables tienen tipo distinto (string vs numérica) respecto al master. **
	use `ing', clear
	_DAappend using "`ingH'", nombre(ingreso_gasto_finan_hist)
	_DAappend using "`deuda'", nombre(deuda_publica)
	_DAappend using "`deudaH'", nombre(deuda_publica_hist)
	_DAappend using "`shrf'", nombre(shrfsp_deuda_amplia_actual)
	_DAappend using "`shrfH'", nombre(shrfsp_deuda_amplia_antes_2014)
	_DAappend using "`rf'", nombre(rfsp)
	_DAappend using "`rfH'", nombre(rfsp_metodologia_anterior)
	_DAappend using "`gf'", nombre(transferencias_entidades_fed)
	_DAappend using "`gfH'", nombre(transferencias_entidades_fed_hist)
	forvalues y = 2025(-1)2004 {
		*_DAappend using "`asignacion`y''", nombre(asignacion_ejecucion_`y')
	}
	*_DAappend using "`asignacion2003'", nombre(asignacion_ejecucion_2003)



	****************
	*** 3 Limpia ***
	****************
	rename ciclo anio

	replace mes = "1" if mes == "Enero"
	replace mes = "2" if mes == "Febrero"
	replace mes = "3" if mes == "Marzo"
	replace mes = "4" if mes == "Abril"
	replace mes = "5" if mes == "Mayo"
	replace mes = "6" if mes == "Junio"
	replace mes = "7" if mes == "Julio"
	replace mes = "8" if mes == "Agosto"
	replace mes = "9" if mes == "Septiembre"
	replace mes = "10" if mes == "Octubre"
	replace mes = "11" if mes == "Noviembre"
	replace mes = "12" if mes == "Diciembre"
	destring mes, replace

	g trimestre = 1 if mes >= 1 & mes <= 3
	replace trimestre = 2 if mes >= 4 & mes <= 6
	replace trimestre = 3 if mes >= 7 & mes <= 9
	replace trimestre = 4 if mes >= 10 & mes <= 12

	replace monto = monto*1000 if unidad_de_medida == "Miles de Pesos"
	replace monto = monto*1000 if unidad_de_medida == "Miles de Dólares" | unidad_de_medida == "Miles de D?lares"
	format monto %20.0fc

	replace unidad_de_medida = "Pesos" if unidad_de_medida == "Miles de Pesos"
	replace unidad_de_medida = "Dólares" if unidad_de_medida == "Miles de Dólares" | unidad_de_medida == "Miles de D?lares"

	format nombre %30s

	g aniotrimestre = yq(anio,trimestre)
	format aniotrimestre %tq

	g aniomes = ym(anio,mes)
	format aniomes %tm

	label var anio "a{c n~}o"
	label var monto "Monto nominal (pesos)"	
	
	collapse (mean) monto, by(anio* mes trimestre nombre clave_de_concepto tipo_de_informacion unidad_de_medida)

	tempfile datosabiertos
	save "`datosabiertos'"



	****************
	*** 4 Extras ***
	****************

	***************************************************
	** 4.1 ISR fisicas, morales, asalariados y otros **
	ensure_asset "ISRInformesTrimestrales.xlsx"
	import excel "${SIMROOT}/raw/ISRInformesTrimestrales.xlsx", ///
		clear sheet("TipoDeContribuyente") firstrow case(lower)
	tsset anio trimestre
	drop total

	forvalues t = 4(-1)2 {
		foreach k of varlist pm-aux {
			replace `k' = `k' - L.`k' if trimestre == `t'
		}
	}
	tempfile isrinftrim
	save "`isrinftrim'"

	use if clave_de_concepto == "XNA0120" using "`datosabiertos'", clear
	collapse (mean) monto, by(anio* mes trimestre nombre clave_de_concepto)
	merge m:1 (anio trimestre) using "`isrinftrim'", nogen

	tempvar prop_m prop_f prop_s
	g `prop_m' = (pm+aux)/(pm+pfae+pfsae+ret_ss_pm+ret_ss_pf+aux)
	g `prop_f' = (pfae+pfsae)/(pm+pfae+pfsae+ret_ss_pm+ret_ss_pf+aux)
	g `prop_s' = (ret_ss_pm+ret_ss_pf)/(pm+pfae+pfsae+ret_ss_pm+ret_ss_pf+aux)

	noisily tabstat `prop_m' `prop_f' `prop_s', save
	tempname PROP
	matrix `PROP' = r(StatTotal)

	g double monto_m = monto*`prop_m'
	g double monto_f = monto*`prop_f'
	g double monto_s = monto*`prop_s'

	replace monto_m = monto*`PROP'[1,1] if pm == .
	replace monto_f = monto*`PROP'[1,2] if pm == .
	replace monto_s = monto*`PROP'[1,3] if pm == .

	egen double monto_pf = rsum(monto_s monto_f)

	format monto* %20.0fc
	format nombre %30s
	keep anio* mes monto_* trimestre nombre
	reshape long monto, i(anio* mes trimestre nombre) j(clave_de_concepto) string

	replace nombre = nombre+" (Morales)" if clave_de_concepto == "_m"
	replace nombre = nombre+" (F{c i'}sicas)" if clave_de_concepto == "_f"
	replace nombre = nombre+" (Salarios)" if clave_de_concepto == "_s"
	replace nombre = nombre+" (F{c i'}sicas + Salarios)" if clave_de_concepto == "_pf"

	replace clave_de_concepto = "XNA0120"+clave_de_concepto

	g tipo_de_informacion = "Flujo"
	drop if mes == .

	tempfile isr
	save "`isr'"



	***************************************
	** 4.2 ISR morales sin ISR petrolero **
	use if clave_de_concepto == "XOA0825" using `datosabiertos', clear
	rename monto monto_isrpet
	tempfile isrpet
	save "`isrpet'"

	use if clave == "XNA0120_m" using `isr', clear
	merge 1:1 (anio mes) using `isrpet', nogen

	replace monto_isrpet = 0 if monto_isrpet == .
	replace monto = monto - monto_isrpet
	drop monto_isrpet

	replace clave_de_concepto = "XNA0120_nopet"
	replace nombre = "Impuesto Sobre la Renta (Morales, no petroleros)"

	tempfile isrpmnopet
	save "`isrpmnopet'"


	***********************************
	** 4.3 Derechos petroleros y FMP **
	use if clave_de_concepto == "XOA0806" | clave_de_concepto == "XAB2123" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g nombre = "Derechos a los hidrocarburos // FMP"
	g clave_de_concepto = "FMP_Derechos"
	g tipo_de_informacion = "Flujo"

	tempfile fmp
	save "`fmp'"


	*************************************************
	** 4.4 Deficit Empresas Productivas del Estado **
	use if clave_de_concepto == "XAA1210" | clave_de_concepto == "XOA0101" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	replace monto = -monto
	g clave_de_concepto = "deficit_epe"
	g nombre = "Balance presupuestario de las Empresas Productivas del Estado"
	g tipo_de_informacion = "Flujo"

	tempfile deficit_epe
	save "`deficit_epe'"


	**********************************************************
	** 4.5 Deficit Organismos y empresas de control directo **
	use if clave_de_concepto == "XKE0000" | clave_de_concepto == "XOA0105" ///
		| clave_de_concepto == "XOA0106" | clave_de_concepto == "XOA0103" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	replace monto = -monto
	g clave_de_concepto = "deficit_oye"
	g nombre = "Balance presupuestario de los organismos y empresas de control directo"
	g tipo_de_informacion = "Flujo"

	tempfile deficit_oye
	save "`deficit_oye'"


	***************************************************
	** 4.6 Diferencias con fuentes de financiamiento **
	use if clave_de_concepto == "XOA0108" using `datosabiertos', clear

	replace monto = -monto
	replace clave_de_concepto = "XOA0108_2"
	replace tipo_de_informacion = "Flujo"

	tempfile diferencias
	save "`diferencias'"


	****************************
	** 4.7 Gasto federalizado **
	use if clave_de_concepto == "XAC2800" | clave_de_concepto == "XAC3300" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g clave_de_concepto = "XACGF00"
	g nombre = "Gasto Federalizado"
	g tipo_de_informacion = "Flujo"

	tempfile gastofed
	save "`gastofed'"


	************************
	** 4.7 Otros ingresos **
	use if clave_de_concepto == "XBB24" | clave_de_concepto == "XNA0151" ///
		| clave_de_concepto == "XNA0152" | clave_de_concepto == "XNA0153" ///
		| clave_de_concepto == "XOA0111" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g clave_de_concepto = "OtrosIngresosC"
	g nombre = "Aprov, Der, Prod, otros"
	g tipo_de_informacion = "Flujo"

	tempfile otrosingresos
	save "`otrosingresos'"



	*****************
	*** 5 Guardar ***
	*****************
	use "`datosabiertos'", clear
	append using "`isr'"
	append using "`fmp'"
	append using "`isrpmnopet'"
	append using "`deficit_epe'"
	append using "`deficit_oye'"
	append using "`diferencias'"
	append using "`gastofed'"
	append using "`otrosingresos'"

	*drop if monto == .
	*drop tema subtema sector ambito base unidad periodo* frecuencia
	replace nombre = subinstr(nombre,"  "," ",.)
	replace nombre = trim(nombre)
	compress

	capture mkdir "${SIMROOT}/master/"
	save "${SIMROOT}/master/DatosAbiertos.dta", replace

	noisily di in g "{c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
end


**************************************
**** Base de datos: Deflactor.dta ****
**************************************
program define UpdateDeflactor
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
quietly {
	noisily di in g "  Updating Deflactor.dta..." _newline

	** 1. Importar variables de interés desde el BIE **
	noisily AccesoBIE 910392, nombres(inpc)

	** 2 Label variables **
	label var inpc "Índice Nacional de Precios al Consumidor"

	** 3 Dar formato a variables **
	format inpc %8.3f

	** 2.5 Guardar **
	order anio inpc
	compress
	noisily di in g "  Último anio: " in y anio[_N]
	noisily di in g "  Último mes: " in y mes[_N]

	capture mkdir "${SIMROOT}/master/"
	save "${SIMROOT}/master/Deflactor.dta", replace
}
end


*************************************************************
**** Descarga con respaldos de una base de Datos Abiertos ****
*************************************************************
* Obtiene una base (nombre, sin extensión) del portal de Datos Abiertos de la
* SHCP y la deja cargada en memoria, según el modo:
*   descarga -> zip (2 intentos, por errores transitorios de conexión),
*               si falla -> csv directo, si falla -> archivos locales
*   csv      -> csv directo, si falla -> archivos locales
*   local    -> archivos ya descargados en raw/temp/, sin internet
* Si tampoco hay archivo local, el error se ve aquí, en su origen.
program define _DAdescarga

	syntax , NOMbre(string) MODO(string) [ENCoding(string)]

	local url "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf"
	local dir "${SIMROOT}/raw/temp/Datos Abiertos"
	local enc ""
	if "`encoding'" != "" {
		local enc "encoding(`encoding')"
	}

	** mkdir no es recursivo: crea el árbol nivel por nivel antes de usarlo **
	capture mkdir "${SIMROOT}"
	capture mkdir "${SIMROOT}/raw/"
	capture mkdir "${SIMROOT}/raw/temp/"
	capture mkdir "`dir'"

	local exito = 0

	** 1. Zip: más eficiente; 2 intentos por errores transitorios de conexión **
	** La descarga va con copy (funciona con URLs en cualquier versión de   **
	** Stata; unzipfile con URL directa no es portable entre versiones).    **
	if "`modo'" == "descarga" {
		forvalues intento = 1/2 {
			if `exito' == 0 {
				quietly cd "`dir'"
				capture copy "`url'/`nombre'.zip" "`dir'/`nombre'.zip", replace
				local rc = _rc
				if `rc' == 0 {
					capture unzipfile "`dir'/`nombre'.zip", replace
					local rc = _rc
					capture erase "`dir'/`nombre'.zip"
				}
				if `rc' == 0 {
					capture import delimited "`dir'/`nombre'.csv", clear `enc'
					local rc = _rc
				}
				if `rc' == 0 {
					local exito = 1
				}
				if `exito' == 0 & `intento' == 1 {
					noisily di in g "Datos Abiertos: fall{c o'} el zip de " in y "`nombre'" in g " (error `rc'). Reintentando..."
					sleep 2000
				}
			}
		}
		if `exito' == 0 {
			noisily di in g "Datos Abiertos: el zip de " in y "`nombre'" in g " fall{c o'} dos veces (error `rc'). Intentando csv directo..."
		}
	}

	** 2. Csv directo: respaldo del zip, o vía principal con la opción csvfile **
	if "`modo'" != "local" & `exito' == 0 {
		capture copy "`url'/`nombre'.csv" "`dir'/`nombre'.csv", replace
		local rc = _rc
		if `rc' == 0 {
			capture import delimited "`dir'/`nombre'.csv", clear `enc'
			local rc = _rc
		}
		if `rc' == 0 {
			local exito = 1
		}
		else {
			noisily di in g "Datos Abiertos: el csv de " in y "`nombre'" in g " tambi{c e'}n fall{c o'} (error `rc'). Usando archivos locales de raw/temp/."
		}
	}

	** 3. Archivos locales: sin internet (modo local) o último respaldo **
	if `exito' == 0 {
		import delimited "`dir'/`nombre'.csv", clear `enc'
	}

	** 4. Filas corruptas: los csv de la SHCP traen ocasionalmente registros    **
	** truncados ("tor Público,Sector Público Federal,...,0") o dos registros   **
	** pegados en una línea (15 ó 19 campos en vez de 16). Efectos: CICLO se   **
	** vuelve string (rompe el append) o, si alguna fila trae más campos que el **
	** encabezado, import delimited descarta el encabezado e importa v1..v19.   **
	** En ese caso se reimporta forzando el encabezado (varnames(1)).           **
	capture confirm variable ciclo
	if _rc != 0 {
		import delimited "`dir'/`nombre'.csv", clear `enc' varnames(1)
	}
	_DAlimpiafilas, nombre(`nombre')

	** Descarga exitosa: refresca el respaldo local ya limpio **
	if `exito' == 1 {
		save "`dir'/`nombre'.dta", replace
	}
end


*************************************************************
**** Elimina filas corruptas de un csv de Datos Abiertos  ****
*************************************************************
* Espera en memoria el resultado de import delimited (con encabezado). Valida
* la estructura de cada fila y elimina las que no la cumplen, reportando cuántas:
*   - columnas sobrantes sin nombre (v16, v17, ...): contenido = fila pegada.
*   - CICLO año de 4 dígitos; MES nombre de mes; TIPO_DE_INFORMACION no vacío;
*     PERIODO_FINAL con formato AAAA-MM; MONTO numérico (o vacío).
* Con eso CICLO y MONTO quedan numéricos y el append entre bases es consistente.
* Sirve para los dos layouts de la SHCP (eopf de 16 columnas y asignación de 15).
program define _DAlimpiafilas

	syntax , NOMbre(string)

	capture confirm variable ciclo
	if _rc != 0 {
		noisily di as err "Datos Abiertos: `nombre' no tiene la columna CICLO; revisar el csv en raw/temp/Datos Abiertos/."
		error 459
	}

	tempvar bad
	quietly g byte `bad' = 0

	** 4.2 Columnas sobrantes (v16, v17, ...) = filas con registros pegados **
	** (asignacion_ejecucion trae un v16 legítimo pero siempre vacío)        **
	foreach v of varlist _all {
		if regexm("`v'", "^v[0-9]+$") {
			capture confirm string variable `v'
			if _rc == 0 {
				quietly replace `bad' = 1 if trim(`v') != ""
			}
			else {
				quietly replace `bad' = 1 if `v' != .
			}
			drop `v'
		}
	}

	** 4.3 CICLO: año de 4 dígitos **
	capture confirm string variable ciclo
	if _rc == 0 {
		quietly replace `bad' = 1 if !regexm(trim(ciclo), "^[0-9][0-9][0-9][0-9]$")
		quietly replace ciclo = "" if `bad' == 1
		quietly destring ciclo, replace
	}

	** 4.4 MES: nombre de mes. TIPO_DE_INFORMACION: no vacío (además de Flujo y **
	**     Saldo, deuda_publica trae Disposición, Amortización, etc.)           **
	capture confirm string variable mes
	if _rc == 0 {
		quietly replace `bad' = 1 if !inlist(trim(mes), "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio") ///
			& !inlist(trim(mes), "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
	}
	capture confirm string variable tipo_de_informacion
	if _rc == 0 {
		quietly replace `bad' = 1 if trim(tipo_de_informacion) == ""
	}

	** 4.4b PERIODO_FINAL: AAAA-MM (detecta filas con campos corridos) **
	capture confirm string variable periodo_final
	if _rc == 0 {
		quietly replace `bad' = 1 if !regexm(trim(periodo_final), "^[0-9][0-9][0-9][0-9]-[0-9][0-9]$")
	}

	** 4.5 MONTO: numérico o vacío **
	capture confirm string variable monto
	if _rc == 0 {
		tempvar m
		quietly g double `m' = real(subinstr(trim(monto), ",", "", .))
		quietly replace `bad' = 1 if `m' == . & trim(monto) != ""
		drop monto
		rename `m' monto
	}

	** 4.6 Reporte y eliminación **
	quietly count if `bad' == 1
	local nbad = r(N)
	if `nbad' > 0 {
		noisily di in g "Datos Abiertos: " in y "`nombre'" in g " trae " in y "`nbad'" in g " fila(s) corrupta(s) (truncadas o pegadas); se eliminan."
		quietly drop if `bad' == 1
	}
	drop `bad'
end


*************************************************************
**** Append con diagnóstico y reparación de tipos           ****
*************************************************************
* Hace `append using` y, si falla, reporta el nombre de la base de Datos
* Abiertos y las variables cuyo tipo (string vs numérica) no coincide con el
* master en memoria. Después intenta repararlo:
*   - el lado string se intenta destring (quitando comas, espacios, $ y %);
*     el caso típico es una numérica leída como string por comas/comillas.
*   - si no se puede convertir a número (contenido genuinamente no numérico),
*     el lado numérico se pasa a string para no perder información.
* Reintenta el append con el archivo reparado. Si aun así falla, aborta con
* el código de error original, ya con el nombre de la base en pantalla.
program define _DAappend

	syntax using/, NOMbre(string)

	capture append using "`using'"
	local rc = _rc
	if `rc' == 0 {
		exit
	}

	noisily di as err _newline "Datos Abiertos: fall{c o'} el append de la base {bf:`nombre'} (error r(`rc'))."

	** 1. Tipos del master en memoria **
	local vmaster
	foreach v of varlist _all {
		local vmaster `vmaster' `v'
		local tm_`v' : type `v'
	}

	** 2. Diagnóstico: variables comunes con tipo string/numérica distinto **
	local fix_using		// string en la base, numérica en master -> destring en la base
	local fix_master	// string en master, numérica en la base -> destring en master
	preserve
	use "`using'", clear
	foreach v of varlist _all {
		if `: list v in vmaster' {
			local tu : type `v'
			local tm `tm_`v''
			local strm = substr("`tm'",1,3) == "str"
			local stru = substr("`tu'",1,3) == "str"
			if `strm' != `stru' {
				noisily di as err "  variable {bf:`v'}: en master es " in y "`tm'" as err ", en `nombre' es " in y "`tu'"
				if `stru' local fix_using `fix_using' `v'
				else      local fix_master `fix_master' `v'
			}
		}
	}

	if "`fix_using'`fix_master'" == "" {
		restore
		noisily di as err "  No hay conflicto string/num{c e'}rica en variables comunes; revisar el csv de " in y "`nombre'" as err " en raw/temp/Datos Abiertos/."
		error `rc'
	}

	** 3. Reparación en la base: destring de las string; si no se puede, se **
	**    anota para pasar a string la contraparte del master.              **
	local tostr_master
	foreach v of local fix_using {
		capture quietly destring `v', replace ignore(", $%")
		if substr("`: type `v''",1,3) == "str" {
			noisily di as err "    {bf:`v'}: no se pudo convertir a num{c e'}rica en `nombre' (contenido no num{c e'}rico); master pasa a string."
			local tostr_master `tostr_master' `v'
		}
		else {
			noisily di in g "    {bf:`v'}: destring en `nombre' " in y "OK" in g "."
		}
	}
	tempfile fixed
	quietly save "`fixed'"
	restore

	** 4. Reparación en el master: destring de las string; si no se puede, **
	**    la contraparte de la base pasa a string.                           **
	local tostr_using
	foreach v of local fix_master {
		capture quietly destring `v', replace ignore(", $%")
		if substr("`: type `v''",1,3) == "str" {
			noisily di as err "    {bf:`v'}: no se pudo convertir a num{c e'}rica en master (contenido no num{c e'}rico); `nombre' pasa a string."
			local tostr_using `tostr_using' `v'
		}
		else {
			noisily di in g "    {bf:`v'}: destring en master " in y "OK" in g "."
		}
	}
	foreach v of local tostr_master {
		quietly tostring `v', replace force
	}
	if "`tostr_using'" != "" {
		preserve
		use "`fixed'", clear
		foreach v of local tostr_using {
			quietly tostring `v', replace force
		}
		quietly save "`fixed'", replace
		restore
	}

	** 5. Reintento **
	capture append using "`fixed'"
	local rc2 = _rc
	if `rc2' == 0 {
		noisily di in g "  Base {bf:`nombre'} reparada y anexada. " as err "Revisar el csv en raw/temp/Datos Abiertos/ para corregir el origen."
		exit
	}
	noisily di as err "  La reparaci{c o'}n autom{c a'}tica no fue suficiente para `nombre' (error r(`rc2'))."
	error `rc2'
end
