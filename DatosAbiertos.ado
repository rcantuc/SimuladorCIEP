program define DatosAbiertos, return
quietly {

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear
	if _rc != 0 {
		UpdateDatosAbiertos
	}
	capture use "`c(sysdir_personal)'/SIM/Deflactor.dta", clear
	if _rc != 0 {
		UpdateDeflactor
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
	syntax [anything] [if] [,  PIBVP(real -999) PIBVF(real -999) DESDE(real 1993) ///
		UPDATE NOGraphs REVERSE PROYeccion]



	***********************
	*** 1 Base de datos ***
	***********************
	if "`update'" == "update" {
		UpdateDatosAbiertos, update
		UpdateDeflactor
	}

	PIBDeflactor, nographs
	
	use if clave_de_concepto == "`anything'" using "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear
	merge 1:1 (anio mes) using "`c(sysdir_personal)'/SIM/Deflactor.dta", nogen keep(matched)
	merge m:1 (anio) using "`c(sysdir_personal)'/SIM/Poblaciontot.dta", nogen keep(matched)
	merge m:1 (anio trimestre) using "`c(sysdir_personal)'/SIM/PIBDeflactor.dta", nogen keep(matched)
	tsset aniomes

	local currency = currency[1]
	foreach k of varlist pibQ - crec_pibQR {
		capture confirm numeric variable `k'
		if _rc == 0 {
			replace `k' = L.`k' if `k' == .
		}
	}
	
	g lambda = (1+scalar(llambda)/100)^(anio-`aniovp')
	replace poblacion = poblacion*lambda

	if "`anything'" == "" {
		use "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear
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

	g monto_pib = monto/pibQ*100
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
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1]/`mesant'[1,3] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc ((`meshoy'[1,1]/`meshoy'[1,3])/(`mesant'[1,1]/`mesant'[1,3])-1)*100 in g " %"

		tabstat montomill if mes <= `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%10.3fc) save
		tempname meshoyacum mesantacum
		matrix `meshoyacum' = r(Stat2)
		matrix `mesantacum' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoyacum'[1,1]/`meshoy'[1,2] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesantacum'[1,1]/`mesant'[1,2] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc ((`meshoyacum'[1,1]/`meshoy'[1,2])/(`mesantacum'[1,1]/`mesant'[1,2])-1)*100 in g " %"
	}
	
	replace montomill = montomill/deflactor

	if tipo_de_informacion == "Saldo" {
		tabstat montomill if ((anio == `last_anio'-1 & mes == 12) | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "Diciembre `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat montomill if ((anio == `last_anio'-1 & mes == `last_mes') | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"
	}

	if "`reverse'" == "reverse" {
		replace monto = -monto
	}


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
		tabstat montomill /*if anio >= 2008*/, stat(sum) by(mes) f(%20.0fc) save
		forvalues k=1(1)12 {
			label define mes `k' "``k'' (`=string(r(Stat`k')[1,1]/r(StatTotal)[1,1]*100,"%7.1fc")'%)", modify
			local ++k
		}
		
		graph bar (sum) monto_pib, over(mes) over(anio) stack asyvar ///
			legend(rows(2) size(large)) ///
			name(M`anything', replace) blabel(none) ///
			ytitle("% PIB") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title(`graphtitle') ///
			ylabel(, format(%15.0fc)) ///
			note("Las cifras entre paréntesis representan la distribución promedio mensual desde 2008.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/M`anything'.png", replace name(M`anything')
		}


		** 2.3 Gráfica por mes **
		graph bar (sum) montomill if mes == `=mes[_N]' /*& anio >= 2008*/, over(anio) ///
			name(`mesname'`anything', replace) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(" `mesname', millones de `=currency[1]' `aniovp'", margin(bottom)) ///
			ytitle("") ///
			ylabel(none, format(%15.0fc)) ///
			blabel(, format(%10.0fc) color(white) size(small) orient(vertical)) ///
			legend(off) ///
			yline(0, lcolor(black) lpattern(solid)) ///
			note("{c U'}ltimo dato: `last_anio'm`last_mes'.") ///
			caption("`graphfuente'") ///


		** 2.4 Gráfica acumulado **
		graph bar (sum) montomill if mes <= `=mes[_N]' /*& anio >= 2008*/, over(anio) ///
			name(Acum`mesname'`anything', replace) ///
			ytitle("") ///
			ylabel(none, format(%15.0fc)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(`"Acumulado a `=lower("`mesname'")', millones de `=currency[1]' `aniovp'"', margin(bottom)) ///
			blabel(, format(%10.0fc) color(white) size(small) orient(vertical)) legend(off) ///
			yline(0, lcolor(black) lpattern(solid)) ///
			note("{c U'}ltimo dato: `last_anio'm`last_mes'.") ///
			caption("`graphfuente'")
	}



	*************************/
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		tempvar montoanual propmensual
		egen `montoanual' = sum(monto) if anio < `last_anio' & anio >= `desde', by(anio)
		g `propmensual' = monto/`montoanual' if anio < `last_anio' & anio >= `desde'
		egen acum_prom = mean(`propmensual'), by(mes)
		
		collapse (sum) monto* acum_prom (last) mes poblacion pibQ deflactor if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)

		if "`proyeccion'" == "proyeccion" {
			replace monto = monto/acum_prom if mes < 12
			replace monto_pib = monto/pibQ*100 if mes < 12
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
		collapse (last) monto* mes poblacion pibQ deflactor if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
		g acum_prom = 1
	}
	*tsset aniomes
	local prianio = anio in 1
	local ultanio = anio in -1
	local ultmes = mes in -1
	return local ultimoAnio = `ultanio'
	return local ultimoMes = `ultmes'

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

		twoway (bar montomill anio if anio < `aniovp', ///
				mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90)) ///
			(bar montomill anio if anio >= `aniovp', mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90)) ///
			(connected monto_pc anio if anio < `aniovp', ///
				yaxis(2) pstyle(p1) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio >= `aniovp', ///
				yaxis(2) pstyle(p2) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)), ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y por persona", margin(bottom)) ///
			///b1title(`"`textografica'"') ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			///xlabel(`prianio' `=round(`prianio',5)'(5)`ultanio') ///
			xlabel(`prianio'(1)`ultanio') ///
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
		}


		twoway (bar montomill anio if anio < `aniovp', ///
				mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90)) ///
			(bar montomill anio if anio >= `aniovp', mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90)) ///
			(connected monto_pib anio if anio < `aniovp', ///
				yaxis(2) pstyle(p1) mlabel(monto_pib) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pib anio if anio >= `aniovp', ///
				yaxis(2) pstyle(p2) mlabel(monto_pib) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)), ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y como % del PIB", margin(bottom)) ///
			///b1title(`"`textografica'"') ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			///xlabel(`prianio' `=round(`prianio',5)'(5)`ultanio') ///
			xlabel(`prianio'(1)`ultanio') ///
			ylabel(none, format(%15.0fc)) ///
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

	syntax [, UPDATE]

	************************
	*** 1. Base de datos ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	local mesvp = substr(`"`=trim("`fecha'")'"',6,2)

	capture use "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear
	if (_rc == 0 & "`update'" != "update") {	
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

	if "`c(console)'" == "console" {
		exit
	}

	*****************************************
	** 1.1 Ingreso, gasto y financiamiento **
	import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan.csv", clear
	*save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan.csv", replace
	*import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan.csv", clear
	tempfile ing
	save "`ing'"
	
	capture confirm file "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan_hist.csv"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan_hist.csv", clear
		save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan_hist.csv", replace
	}
	import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan_hist.csv", clear
	tempfile ingH
	save "`ingH'"

	***************
	** 1.2 Deuda **
	import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica.csv", clear
	*save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/deuda_publica.csv", replace
	*import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/deuda_publica.csv", clear
	tempfile deuda
	save "`deuda'"

	capture confirm file "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/deuda_publica_hist.csv"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica_hist.csv", clear
		save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/deuda_publica_hist.csv", replace
	}
	import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/deuda_publica_hist.csv", clear
	tempfile deudaH
	save "`deudaH'"

	****************
	** 1.3 SHRFSP **
	import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_actual.csv", clear
	*save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplia_actual.csv", replace
	*import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplia_actual.csv", clear
	tempfile shrf
	save "`shrf'"

	capture confirm file "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplshrfsp_deuda_amplia_antes_2014ia_actual_hist.csv"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_antes_2014.csv", clear
		save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.csv", replace
	}
	import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.csv", clear
	tempfile shrfH
	save "`shrfH'"

	**************
	** 1.4 RFSP **
	import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp.csv", clear
	*save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/rfsp.csv", replace
	*import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/rfsp.csv", clear
	tempfile rf
	save "`rf'"

	capture confirm file "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/rfsp_metodologia_anterior.csv"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp_metodologia_anterior.csv", clear
		save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/rfsp_metodologia_anterior.csv", replace
	}
	import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/rfsp_metodologia_anterior.csv", clear
	tempfile rfH
	save "`rfH'"

	*************************************************
	** 1.5 Transferencias a Entidades y Municipios **
	import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.csv", clear
	*save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/transferencias_entidades_fed.csv", replace
	*import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/transferencias_entidades_fed.csv", clear
	tempfile gf
	save "`gf'"

	import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed_hist.csv", clear
	*save "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/transferencias_entidades_fed_hist.csv", replace
	*import delimited "`c(sysdir_site)'../BasesCIEP/SHCP/Datos Abiertos/transferencias_entidades_fed_hist.csv", clear
	tempfile gfH
	save "`gfH'"



	**************
	** 2 Append **
	**************/
	use `ing', clear
	append using "`ingH'"
	append using "`deuda'"
	append using "`deudaH'"
	append using "`shrf'"
	append using "`shrfH'"
	append using "`rf'"
	append using "`rfH'"
	append using "`gf'"
	append using "`gfH'"



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
	import excel "`c(sysdir_site)'../BasesCIEP/LIFs/ISRInformesTrimestrales.xlsx", ///
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

	tempfile gastofed
	save "`gastofed'"



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

	*drop if monto == .
	*drop tema subtema sector ambito base unidad periodo* frecuencia
	replace nombre = subinstr(nombre,"  "," ",.)
	replace nombre = trim(nombre)
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", replace
	}

	noisily di in g "{c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
end


**************************************
**** Base de datos: Deflactor.dta ****
**************************************
program define UpdateDeflactor
	noisily di in g "  Updating Deflactor.dta..." _newline

	** 1. Importar variables de interés desde el BIE **
	run "`c(sysdir_personal)'/AccesoBIE.do" "628194" "inpc"

	** 2 Label variables **
	label var inpc "Índice Nacional de Precios al Consumidor"

	** 3 Dar formato a variables **
	format inpc %8.3f

	** 4 Time Series **
	split periodo, destring p("/") //ignore("r p")
	rename periodo1 anio
	label var anio "anio"
	rename periodo2 mes
	label var mes "mes"
	drop periodo

	** 2.5 Guardar **
	order anio inpc
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/Deflactor.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/Deflactor.dta", replace
	}
end
