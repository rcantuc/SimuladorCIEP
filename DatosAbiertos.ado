program define DatosAbiertos, return
quietly {

	syntax anything [if/] [, Graphs Restore PIBVP(real -999) PIBVF(real -999) UPDATE DESDE(real 1993)]

	if "`restore'" == "restore" {
		preserve
	}

	PIBDeflactor, nographs
	tempfile PIB
	save `PIB'

	capture confirm file "`c(sysdir_personal)'../basesCIEP/SIM/DatosAbiertos.dta"
	if _rc != 0 | "`update'" == "update" {
		run "`c(sysdir_site)'/UpdateDatosAbiertos.do"
	}




	****************************
	*** 1 Base de datos SHCP ***
	****************************
	use if clave_de_concepto == "`anything'" using "`c(sysdir_personal)'../basesCIEP/SIM/DatosAbiertos.dta", clear
	if `=_N' == 0 {
		noisily di in r "No se encontr{c o'} la serie {bf:`anything'}."
		return scalar error = 2000
		exit
	}

	if "`if'" != "" {
		keep if `if'
	}

	* Informacion de la serie *
	noisily di _newline(2) in g "Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."	




	**************************
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		sort anio mes

		local last_anio = anio[_N]
		local alst_mes = mes[_N]

		tempvar montoanual propmensual
		egen `montoanual' = sum(monto) if anio < `last_anio' & anio >= `desde', by(anio)
		g `propmensual' = monto/`montoanual' if anio < `last_anio' & anio >= `desde'
		egen acum_prom = mean(`propmensual'), by(mes)

		collapse (sum) monto acum_prom (last) mes if monto != ., by(anio nombre clave_de_concepto)
		replace monto = monto/acum_prom if mes < 12 & acum_prom > 0 & acum_prom < 1

		local palabra "Proyectado"
	}
	else if tipo_de_informacion == "Saldo" {
		tempvar maxmes
		egen `maxmes' = max(mes), by(anio)
		drop if mes < `maxmes'
		sort anio mes
		collapse (last) monto mes if monto != ., by(anio nombre clave_de_concepto)
	}
	local ultanio = anio in -1
	local ultmes = mes in -1
	return local ultimoAnio = `ultanio'
	return local ultimoMes = `ultmes'
	tsset anio

	if `pibvf' != -999 {
		tsappend, add(1)
		local clave = clave_de_concepto[1]
		replace clave_de_concepto = "`clave'" in -1
		local nombre = nombre[1]
		replace nombre = "`nombre'" in -1
	}

	merge m:1 (anio) using `PIB', nogen keep(matched) keepus(pibY)			

	if `pibvp' != -999 {
		replace monto = `pibvp'/100*pibY if mes < 12
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
	if "$graphs" == "on" | "`graphs'" == "graphs" {
		*drop if anio < 2007
		local serie_anio = anio[_N]
		local serie_monto = monto[_N]
		forvalues k = 1(1)`=_N' {
			if monto_pib[`k'] != . & monto_pib[`k'] != 0 {
				if mes[`k'] != 12 {
					local text1 = `"`text1' `=monto_pib[`k']' `=anio[`k']' "`=string(monto_pib[`k'],"%5.1fc")'{superscript:*}" "'
				}
				else {
					local text1 = `"`text1' `=monto_pib[`k']' `=anio[`k']' "`=string(monto_pib[`k'],"%5.1fc")'" "'
				}
			}
		}

		* Grafica *
		local length = length("`=nombre[1]'")
		if `length' > 60 {
			local textsize ", size(large)"
		}
		if `length' > 90 {
			local textsize ", size(medium)"
		}
		if `length' > 120 {
			local textsize ", size(small)"
		}
		twoway (connected monto_pib anio if anio < `ultanio') ///
			(connected monto_pib anio if anio >= `ultanio'), ///
			title({bf:`=nombre[1]'}`textsize') ///
			subtitle(Montos observados) ///
			b1title(`"{bf:`=anio[_N]':} `=string(monto[_N]/1000000,"%20.1fc")' millones de MXN"', size(small)) ///
			b2title(`"`textovp'"', size(small)) ///
			ytitle(% PIB) xtitle("") ///
			xlabel(1993(2)2019) ///
			ylabel(, format(%4.1fc)) yscale(range(0)) ///
			legend(label(1 "Observado") label(2 "Estimado")) ///
			text(`text1', size(small)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP, Datos Abiertos y del INEGI, BIE.}") ///
			note("{bf:{c U'}ltimo dato:} `ultanio'm`ultmes'.") ///
			name(H`anything', replace)
	}
	noisily list, separator(30) string(30)
	
	if "`restore'" == "restore" {
		restore
	}
}
end
