program define DatosAbiertos, return
quietly {

	capture use "`c(sysdir_personal)'/bases/SHCP/Datos Abiertos/DatosAbiertos`c(os)'.dta", clear
	if _rc != 0 {
		run "`c(sysdir_personal)'/bases/SHCP/Datos Abiertos/DatosAbiertos.do"
	}

	syntax anything [if/] [, Graphs Restore PIBVP(real -999) PIBVF(real -999) UPDATE]

	if "`restore'" == "restore" {
		preserve
	}
	
	if "`update'" == "update" {
		run "`c(sysdir_personal)'/bases/INEGI/BIE/SCN/PIB/PIB.do"
		run "`c(sysdir_personal)'/bases/INEGI/BIE/SCN/Deflactor/Deflactor.do"
		run "`c(sysdir_personal)'/bases/SHCP/Datos Abiertos/DatosAbiertos.do"
	}




	****************************
	*** 1 Base de datos SHCP ***
	****************************
	use if clave_de_concepto == "`anything'" & anio >= 1993 using "`c(sysdir_personal)'/bases/SHCP/Datos Abiertos/DatosAbiertos`c(os)'.dta", clear
	if `=_N' == 0 {
		noisily di in r "No se encontr${o} la serie {bf:`anything'}."
		return scalar error = 2000
		exit
	}

	if "`if'" != "" {
		keep if `if'
	}

	* Informacion de la serie *
	*acentos nombre
	noisily di in g "Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."	




	**************************
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		sort anio mes
		collapse (sum) monto (last) mes if monto != ., by(anio nombre clave_de_concepto)
		*replace monto = monto*12/mes if mes < 12
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
	return local ultimoMex = `ultmes'
	tsset anio

	if `pibvf' != -999 {
		tsappend, add(1)
		local clave = clave_de_concepto[1]
		replace clave_de_concepto = "`clave'" in -1
		local nombre = nombre[1]
		replace nombre = "`nombre'" in -1
	}

	preserve
	PIBDeflactor, nographs
	tempfile PIB
	save `PIB'
	restore

	merge m:1 (anio) using `PIB.dta', nogen keep(matched) keepus(pibY)			

	if `pibvp' != -999 {
		replace monto = `pibvp'/100*pibY if mes < 12
	}

	if `pibvf' != -999 {
		replace monto = `pibvf'/100*pibY in -1

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
			local textsize ", size(medium)"
		}
		if `length' > 90 {
			local textsize ", size(small)"
		}
		if `length' > 120 {
			local textsize ", size(vsmall)"
		}
		twoway (connected monto_pib anio) /*if monto != 0*/, ///
			title({bf:`=nombre[1]'}`textsize') ///
			subtitle(Montos observados) ///
			b1title(`"{bf:Estimado `=anio[_N]'{superscript:*}:} `=string(monto[_N]/1000000,"%20.1fc")' millones de MXN"', size(small)) ///
			ytitle(% PIB) xtitle("") ///
			/*xlabel(2007(1)2018)*/ ///
			ylabel(0(10)10) ///
			text(`text1',size(medsmall)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci${o}n de la SHCP, Datos Abiertos y del INEGI, BIE.}") ///
			note("{bf:${U}ltimo dato:} `ultanio'm`ultmes'.") ///
			name(H`anything', replace)
	}
	noisily list, separator(30) string(30)
	
	if "`restore'" == "restore" {
		restore
	}
}
end
