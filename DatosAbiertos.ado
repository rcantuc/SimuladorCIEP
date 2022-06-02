program define DatosAbiertos, return
quietly {

	syntax anything [if] [, NOGraphs PIBVP(real -999) PIBVF(real -999) UPDATE DESDE(real 1993) MES]

	if "`c(username)'" == "ricardo" | "`c(username)'" == "ciepmx" {
		UpdateDatosAbiertos
	}



	****************************
	*** 1 Base de datos SHCP ***
	****************************
	PIBDeflactor, nographs nooutput
	local aniovp = r(aniovp)
	local currency = currency[1]
	tempfile PIB
	save "`PIB'"

	capture use if clave_de_concepto == "`anything'" using "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear
	if _rc != 0 {
		UpdateDatosAbiertos
		use if clave_de_concepto == "`anything'" using "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear
	}

	*drop if monto == 0 | monto == .
	*drop if anio < 2003

	if `=_N' == 0 {
		noisily di in r "No se encontr{c o'} la serie {bf:`anything'}."
		return scalar error = 2000
		exit
	}



	*********************************
	** 1.1 Informacion de la serie **
	noisily di _newline in g " Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."
	tsset aniomes
	sort aniomes
	local last_anio = anio[_N]
	local last_mes = mes[_N]
	merge m:1 (anio) using "`PIB'", nogen keep(matched) keepus(pibY deflator currency)
	keep if anio >= 2013 & anio <= `last_anio'

	tempvar montomill
	g `montomill' = monto/1000000/deflator

	label define mes 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" 7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
	label values mes mes
	local mesname : label mes `=mes[_N]'

	if tipo_de_informacion == "Flujo" {
		tabstat `montomill' if mes == `=mes[_N]' & (anio == `=anio[_N]'. | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Mes " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat `montomill' if mes <= `=mes[_N]' & (anio == `=anio[_N]'. | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
	}
	if tipo_de_informacion == "Saldo" {
		tabstat `montomill' if mes == `=mes[_N]' & (anio == `=anio[_N]'. | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
	}
	tempname meshoy mesant
	matrix `meshoy' = r(Stat2)
	matrix `mesant' = r(Stat1)

	noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " millones `currency'"
	noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency' `aniovp'"
	noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"



	****************************
	*** 2 Proyeccion mensual ***
	****************************
	if "`nographs'" != "nographs" & tipo_de_informacion == "Flujo" {
		local length = length("`=nombre[1]'")
		if `length' > 60 {
			local textsize ", size(medium)"
		}
		if `length' > 90 {
			local textsize ", size(vsmall)"
		}
		if `length' > 110 {
			local textsize ", size(vvsmall)"
		}

		tabstat `montomill' `if', stat(sum) by(mes) f(%20.0fc) save
		local j = 100/12/2
		forvalues k=1(1)12 {
			tempname monto`k'
			matrix `monto`k'' = r(Stat`k')
			*local valorserie `"`valorserie' `=`monto`k''[1,1]*0' `j' "{bf:`=string(`monto`k''[1,1],"%5.1fc")'}""'
			local j = `j' + 100/12
		}

		graph bar (sum) `montomill' `if', over(anio) over(mes) stack asyvar ///
			legend(rows(2)) name(M`anything', replace) blabel(none) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			text(`valorserie', color(black) place(n)) ///
			subtitle("por mes calendario") ylabel(, format(%10.1fc)) ///
			note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas).")

		preserve
		collapse (sum) `montomill', by(aniotrimestre anio trimestre nombre currency)
		forvalues k=1(1)`=_N' {
			local relab `" `relab' `k' "`=trimestre[`k']'" "'
			if anio[`k'] == `aniovp' & trimestre[`k'] == trimestre[_N] {
				local montoTrimActual = `montomill'[`k']
			}
			if anio[`k'] == `aniovp'-1 & trimestre[`k'] == trimestre[_N] {
				local montoTrimAnteri = `montomill'[`k']
			}
		}
		graph bar (sum) `montomill' `if', over(anio) ///
			over(aniotrimestre, relabel(`relab') axis(on)) ///
			stack asyvar ///
			legend(rows(2)) name(T`anything', replace) blabel(none) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			text(`valorserie', color(black) place(n)) ///
			subtitle("por trimestre") ylabel(, format(%10.1fc)) ///
			b1title(`" `=string((`montoTrimActual'/`montoTrimAnteri'-1)*100,"%10.1fc")' "') ///
			note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas).")
		restore

		graph bar (sum) `montomill' if mes == `=mes[_N]' /*& anio >= 2012*/, over(anio) asyvar ///
			name(`mesname'`anything', replace) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(, format(%10.1fc)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			yline(0, lcolor(black) lpattern(solid)) ///
			subtitle("`mesname'") blabel(name) legend(off) ///
			note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas)")
	}
	
	if "`mes'" == "mes" {
		exit
	}
	

	*************************/
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		tempvar montoanual propmensual
		egen `montoanual' = sum(monto) if anio < `last_anio' & anio >= `desde', by(anio)
		g `propmensual' = monto/`montoanual' if anio < `last_anio' & anio >= `desde'
		egen acum_prom = mean(`propmensual'), by(mes)

		collapse (sum) monto acum_prom (last) mes if monto != ., by(anio nombre clave_de_concepto)
		*replace monto = monto/acum_prom if mes < 12 //& acum_prom > 0 & acum_prom < 1
		*local textografica `"{bf:Promedio a `mesname'}: `=string(acum_prom[_N]*100,"%5.1fc")'% del total anual."'
		local palabra "Proyectado"
	}
	else if tipo_de_informacion == "Saldo" {
		tempvar maxmes
		egen `maxmes' = max(mes), by(anio)
		drop if mes < `maxmes'
		sort anio mes
		collapse (last) monto mes if monto != ., by(anio nombre clave_de_concepto)
		g acum_prom = 1
	}
	tsset anio
	local prianio = anio in 1
	local ultanio = anio in -1
	local ultmes = mes in -1
	return local ultimoAnio = `ultanio'
	return local ultimoMes = `ultmes'

	if `pibvf' != -999 {
		tsappend, add(1)
		local clave = clave_de_concepto[1]
		replace clave_de_concepto = "`clave'" in -1
		local nombre = nombre[1]
		replace nombre = "`nombre'" in -1
	}

	if `pibvp' != -999 {
		if `aniovp' == `last_anio'+1 {
			tsappend, add(1)
		}
		local clave = clave_de_concepto[1]
		replace clave_de_concepto = "`clave'" in -1
		local nombre = nombre[1]
		replace nombre = "`nombre'" in -1
	}

	merge m:1 (anio) using `PIB', nogen keep(matched) keepus(pibY deflator)			

	if `pibvp' != -999 {
		replace monto = `pibvp'/100*pibY if mes < 12 | mes == .
		local palabra "Estimado"
	}

	if `pibvf' != -999 {
		local textovp `"{superscript:*}{bf:`=anio[_N-1]':} `=string(monto[_N-1]/1000000,"%20.1fc")' millones de MXN"'
		replace monto = `pibvf'/100*pibY in -1
		local palabra "Estimado"
	}

	g double monto_pib = monto/pibY*100
	format monto_pib %7.3fc
	label var monto_pib "Observado (SHCP)"


	** 2.1. Grafica **
	if "`nographs'" != "nographs" {
		*drop if anio < 2007
		local serie_anio = anio[_N]
		local serie_monto = monto[_N]
		forvalues k = 1(1)`=_N' {
			if monto_pib[`k'] != . & monto_pib[`k'] != 0 {
				if mes[`k'] != 12 {
					local text1 = `"`text1' `=monto_pib[`k']' `=anio[`k']' "{bf:`=string(monto_pib[`k'],"%5.1fc")'{superscript:*}}" "'
				}
				else {
					local text1 = `"`text1' `=monto_pib[`k']' `=anio[`k']' "{bf:`=string(monto_pib[`k'],"%5.1fc")'}" "'
				}
			}
			if anio[`k'] == 2003 {
				if "`anything'" == "FMP_Derechos" | "`anything'" == "OtrosIngresosC" {
					local scalarname = subinstr("`anything'","_","",.)
				}
				else if substr("`anything'",-1,1) == "s" | substr("`anything'",-1,1) == "f" | substr("`anything'",-1,1) == "m" {
					local numone = substr("`anything'",4,1)
					local numtwo = substr("`anything'",5,1)
					local numthr = substr("`anything'",6,1)
					local numfou = substr("`anything'",7,1)
					local scalarname = substr("`anything'",1,3) + char(`=65+`numone'') + char(`=65+`numtwo'') + char(`=65+`numthr'') + char(`=65+`numfou'') + substr("`anything'",-1,1)

				}
				else {
					local scalarname = substr("`anything'",1,3) + substr("`anything'",4,1) + substr("`anything'",5,1) + substr("`anything'",6,1) + substr("`anything'",7,1)
				}
				scalar dif`scalarname'PIB = monto_pib[_N] - monto_pib[`k']
				scalar `scalarname'GEO = ((monto[_N]/(monto[`k']/deflator[`k']))^(1/(anio[_N]-anio[`k']))-1)*100
			}
		}

		* Grafica *
		tempvar monto
		g `monto' = monto/1000000000/deflator
		twoway (area `monto' anio if anio < `aniovp') ///
			(bar `monto' anio if anio >= `aniovp') ///
			(connected monto_pib anio if anio < `aniovp', yaxis(2) msize(large) mlwidth(vvthick) pstyle(p1)) ///
			(connected monto_pib anio if anio >= `aniovp', yaxis(2) msize(large) mlwidth(vvthick) pstyle(p2)), ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			/*subtitle(Montos observados)*/ ///
			b1title(`"`textografica'"', size(small)) ///
			///b2title(`"`textovp'"', size(small)) ///
			ytitle(millones MXN `aniovp') ///
			ytitle(% PIB, axis(2)) xtitle("") ///
			///xlabel(`prianio' `=round(`prianio',5)'(5)`ultanio') ///
			xlabel(`prianio'(1)`ultanio') ///
			ylabel(, format(%10.0fc)) yscale(range(0)) ///
			ylabel(, axis(2) format(%5.1fc) noticks) ///
			yscale(range(0) noline axis(2)) ///
			legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
			text(`text1', yaxis(2) color(white) size(tiny)) ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas).") ///
			note("{bf:{c U'}ltimo dato:} `ultanio'm`ultmes'.") ///
			name(H`anything', replace)
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`anything'.png", replace name(H`anything')
		}
	}
	noisily list anio monto acum_prom mes monto_pib, separator(30) string(30)
}
end
