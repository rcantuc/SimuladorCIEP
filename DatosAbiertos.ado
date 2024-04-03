program define DatosAbiertos, return
quietly {

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
	if _rc != 0 {
		UpdateDatosAbiertos
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

	syntax [anything] [if] [, NOGraphs PIBVP(real -999) PIBVF(real -999) UPDATE DESDE(real 1993) REVERSE]



	***********************
	*** 1 Base de datos ***
	***********************
	
	** 1.1 PIB + Deflactor **
	PIBDeflactor, nographs nooutput aniovp(`aniovp')
	replace Poblacion = Poblacion*lambda
	local currency = currency[1]
	tempfile PIB
	save "`PIB'"

	** 1.2 Datos Abiertos (Estadísticas Oportunas) **
	use if clave_de_concepto == "`anything'" using "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
	if "`anything'" == "" {
		use "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
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
	replace nombre = "Requerimientos financieros del sector público" if nombre == "Requerimientos financieros del sector p??blico federal (I+II)"


	*********************************
	** 1.1 Informacion de la serie **
	merge m:1 (anio) using "`PIB'", nogen keep(matched) //keepus(pibY deflator currency Poblacion*)
	noisily di _newline in g " Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."
	*keep if anio >= 2013 & anio <= `last_anio'
	
	if "`if'" != "" {
		keep `if'
	}

	tsset aniomes
	//tempvar dif_Poblacion dif2_Poblacion
	//g `dif_Poblacion' = D.Poblacion
	//egen `dif2_Poblacion' = max(`dif_Poblacion')
	//replace Poblacion = Poblacion + `dif2_Poblacion'*mes/12

	tempvar montomill crecreal
	g `montomill' = monto/1000000/deflator
	format `montomill' %20.0fc

	g monto_pc = monto/Poblacion/deflator
	format monto_pc %10.0fc

	g monto_pib = monto/pibY*100
	format monto_pib %7.1fc

	g `crecreal' = (`montomill'/L12.`montomill'-1)*100

	label define mes 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" 7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
	label values mes mes
	local mesname : label mes `=mes[_N]'
	local mesnameant : label mes `=mes[`=_N-1']'

	if tipo_de_informacion == "Flujo" {
		tabstat `montomill' if mes == `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Mes " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.1fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.1fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat `montomill' if mes <= `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.1fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.1fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"
	}
	if tipo_de_informacion == "Saldo" {
		tabstat `montomill' if ((anio == `last_anio'-1 & mes == 12) | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.1fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "Diciembre `=anio[_N]-1'" in g ": " _col(40) in y %20.1fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat `montomill' if ((anio == `last_anio'-1 & mes == 12) | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Acumulado " in y "`mesnameant' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " per cápita `currency' `aniovp'"
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
			*local textsize ", size(small)"
		}
		if `length' > 110 {
			*local textsize ", size(vsmall)"
		}

		* Fuente *
		if "$export" == "" {
			local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP."
		}
		else {
			local graphfuente ""
		}

		** 2.2 Gráfica por mes calendario **
		tabstat `montomill' /*if anio >= 2008*/, stat(sum) by(mes) f(%20.0fc) save
		graph bar (sum) `montomill', over(mes) over(anio) stack asyvar ///
			legend(rows(1) size(vsmall)) ///
			name(M`anything', replace) blabel(none) ///
			ytitle("") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(" por mes calendario, millones de `=currency[1]' `aniovp'", margin(bottom)) ///
			ylabel(, format(%15.0fc)) ///
			caption("`graphfuente'") ///


		** 2.3 Gráfica por mes **
		graph bar (sum) `montomill' if mes == `=mes[_N]' /*& anio >= 2008*/, over(anio) ///
			name(`mesname'`anything', replace) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(" `mesname', millones de `=currency[1]' `aniovp'", margin(bottom)) ///
			ytitle("") ///
			ylabel(none, format(%15.0fc)) ///
			blabel(, format(%10.0fc) position(outside) color("114 113 118") size(vsmall)) legend(off) ///
			yline(0, lcolor(black) lpattern(solid)) ///
			note("{c U'}ltimo dato: `last_anio'm`last_mes'.") ///
			caption("`graphfuente'") ///


		** 2.4 Gráfica acumulado **
		graph bar (sum) `montomill' if mes <= `=mes[_N]' /*& anio >= 2008*/, over(anio) ///
			name(Acum`mesname'`anything', replace) ///
			ytitle("") ///
			ylabel(none, format(%15.0fc)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(`"Acumulado a `=lower("`mesname'")', millones de `=currency[1]' `aniovp'"', margin(bottom)) ///
			blabel(, format(%10.0fc) position(outside) color("114 113 118") size(vsmall)) legend(off) ///
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
		collapse (sum) `montomill' monto* acum_prom (last) mes Poblacion pibY deflator if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
		*replace monto = monto/acum_prom if mes < 12
		local textografica `"{bf:Promedio a `mesname'}: `=string(acum_prom[_N]*100,"%5.1fc")'% del total anual."'
		local palabra "Proyectado"
	}
	else if tipo_de_informacion == "Saldo" {
		tempvar maxmes
		egen `maxmes' = max(mes), by(anio)
		*drop if mes < `maxmes'
		sort anio mes
		collapse (last) `montomill' monto* mes Poblacion pibY deflator if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
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

		tabstat `montomill' monto_pc monto_pib, by(anio) stat(min max) save
		return list
		tempname rango
		matrix `rango' = r(StatTotal)

		twoway (bar `montomill' anio if anio < `aniovp', ///
				mlabel(`montomill') mlabpos(7) mlabcolor(white) mlabsize(vsmall) msize(small) mlabangle(90)) ///
			(bar `montomill' anio if anio >= `aniovp', mlabel(`montomill') mlabpos(7) mlabcolor(white) mlabsize(vsmall) msize(small) mlabangle(90)) ///
			(connected monto_pc anio if anio < `aniovp', ///
				yaxis(2) pstyle(p1) mlabel(monto_pc) mlabpos(12) mlabcolor("114 113 118") mlabsize(vsmall) lpattern(dot) msize(small)) ///
			(connected monto_pc anio if anio >= `aniovp', ///
				yaxis(2) pstyle(p2) mlabel(monto_pc) mlabpos(12) mlabcolor("114 113 118") mlabsize(vsmall) lpattern(dot) msize(small)), ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y por persona", margin(bottom)) ///
			///b1title(`"`textografica'"', size(small)) ///
			///b2title(`"`textovp'"', size(small)) ///
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
			text(`text1', yaxis(2) color(white) size(vsmall)) ///
			caption("`graphfuente'") ///
			note("{c U'}ltimo dato: `ultanio'm`ultmes'.") ///
			name(`anything'PC, replace)


		twoway (bar `montomill' anio if anio < `aniovp', ///
				mlabel(`montomill') mlabpos(7) mlabcolor(white) mlabsize(vsmall) msize(small) mlabangle(90)) ///
			(bar `montomill' anio if anio >= `aniovp', mlabel(`montomill') mlabpos(7) mlabcolor(white) mlabsize(vsmall) msize(small) mlabangle(90)) ///
			(connected monto_pib anio if anio < `aniovp', ///
				yaxis(2) pstyle(p1) mlabel(monto_pib) mlabpos(12) mlabcolor("114 113 118") mlabsize(vsmall) lpattern(dot) msize(small)) ///
			(connected monto_pib anio if anio >= `aniovp', ///
				yaxis(2) pstyle(p2) mlabel(monto_pib) mlabpos(12) mlabcolor("114 113 118") mlabsize(vsmall) lpattern(dot) msize(small)), ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y como % del PIB", margin(bottom)) ///
			///b1title(`"`textografica'"', size(small)) ///
			///b2title(`"`textovp'"', size(small)) ///
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
			text(`text1', yaxis(2) color(white) size(vsmall)) ///
			caption("`graphfuente'") ///
			note("{c U'}ltimo dato: `ultanio'm`ultmes'.") ///
			name(`anything'PIB, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/H`anything'.png", replace name(H`anything')
		}
	}
	noisily list anio mes acum_prom monto monto_pib monto_pc, separator(30) string(30)
}
end
