program define SHRFSP
quietly {

	syntax [, Graphs Update ID(string)]




	************************
	*** 1. BASE DE DATOS ***
	************************
	PIBDeflactor
	tempfile PIB
	save `PIB'

	capture confirm existence $anioVP
	if _rc != 0 {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}
	else {
		local aniovp = $anioVP
	}
	
	capture use "`c(sysdir_site)'../basesCIEP/SIM/SHRFSP.dta", clear
	local rc = _rc
	syntax [if/] [, ANIO(int `aniovp' ) Graphs Update Base ID(string) ///
		MINimum(real 1)]


	** Base LIF **
	if `rc' != 0 | "`update'" == "update" {
		noisily run "`c(sysdir_site)'/UpdateSHRFSP.do" `update'
	}

	noisily di _newline(5) in g "{bf:SISTEMA FISCAL: " in y "DEUDA `anio'" "}"




	**************
	*** 2. PIB ***
	**************
	merge 1:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator productivity var_pibY) update replace //keep(matched)
	foreach k of varlist rfsp* shrfsp* {
		g `k'PIB = `k'/pibY*100
	}
	format *PIB %7.3fc


	****************
	*** 3. Graph ***
	****************	
	if "$graphs" == "on" | "`graphs'" == "graphs" {
		graph bar (sum) shrfspInternoPIB shrfspExternoPIB if anio <= $anioVP & anio >= 2000, ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Saldo hist{c o'}rico de RFSP}") ///
			/// subtitle("Observados y estimados") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(6) rows(1) label(1 "Interno") label(2 "Externo")) ///
			name(shrfsp, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
	}

exit

	*replace rfspBalance = recaudacion - gastopagado + nopresupuestario if anio == `aniovp'
	*replace rfspBalancePIB = rfspBalance/pibY*100 if anio == `aniovp'

	*replace rfsp = rfspPIDIREGAS + rfspIPAB + rfspFONADIN + rfspDeudores ///
		+ rfspBanca + rfspAdecuaciones + rfspBalance if anio == `aniovp'
	*replace rfspPIB = rfsp/pibY*100 if anio == `aniovp'


	******************************
	** Ingresos presupuestarios **
	LIF, id(`id')																					// (+) Ingresos
	drop if divCIEP == 6																			// Quitar deuda
	
	encode modulo, g(modulos)
	collapse (sum) recaudacion, by(anio modulo*)

	levelsof modulo if modulo2 == 1, local(modulos)
	foreach k of local modulos {
		capture confirm file "`=c(sysdir_personal)'/users/bootstraps/1/`k'REC.dta"
		if _rc == 0 {
			joinby (anio modulo) using "`=c(sysdir_personal)'/users/bootstraps/1/`k'REC.dta", unmatched(both) update
			drop _merge
		}
	}


	* Fill the blanks *
	forvalues j=1(1)`=_N' {
		foreach k of varlist modulo modulos {
			capture confirm numeric variable `k'
			if _rc == 0 {
				if `k'[`j'] != . {
					quietly replace `k' = `k'[`j'] if `k' == . & modulo == modulo[`j']
				}
			}
			else {
				if `k'[`j'] != "" {
					quietly replace `k' = `k'[`j'] if `k' == "" & modulo == modulo[`j']		
				}
			}
		}
	}

	tsset modulos anio
	tsfill, full

	capture confirm variable estimacion
	if _rc != 0 {
		g estimacion = .
	}
	format estimacion %20.0fc

	tsfill, full
	merge m:1 (anio) using `PIB', nogen
	tsfill, full
	merge m:1 (anio) using `PIB', nogen update replace


	* Proyecciones *
	sort modulos anio
	replace recaudacion = L.recaudacion* ///
		(1+var_pibY/100)*indiceY/L.indiceY*estimacion/L.estimacion ///
		if estimacion != . & recaudacion == .

	replace recaudacion = L.recaudacion* ///
		(1+var_pibY/100)*indiceY/L.indiceY ///
		if estimacion == . & recaudacion == .

	collapse (sum) recaudacion, by(anio)

	tempfile ingresos
	save `ingresos'


	*******************************
	** Gasto neto presupuestario **
	PEF if neto == 0 & ramo != 28 & ramo != 33 & desc_funcion != 24, id(`id')	// (-) Gastos
	encode modulo, g(modulos)
	replace gasto = -gasto if desc_funcion == -1											// Restar cuotas al ISSSTE
	collapse (sum) gasto if neto == 0, by(anio modulo modulos)						// Quitar aportaciones a la SS

	levelsof modulo, local(modulos)
	foreach k of local modulos {
		capture confirm file "`=c(sysdir_personal)'/users/bootstraps/1/`k'REC.dta"
		if _rc == 0 {
			joinby (anio modulo) using "`=c(sysdir_personal)'/users/bootstraps/1/`k'REC.dta", unmatched(both) update
			drop _merge
		}
	}


	* Fill the blanks *
	forvalues j=1(1)`=_N' {
		foreach k of varlist modulo modulos {
			capture confirm numeric variable `k'
			if _rc == 0 {
				if `k'[`j'] != . {
					quietly replace `k' = `k'[`j'] if `k' == . & modulo == modulo[`j']
				}
			}
			else {
				if `k'[`j'] != "" {
					quietly replace `k' = `k'[`j'] if `k' == "" & modulo == modulo[`j']		
				}
			}
		}
	}

	tsset modulos anio
	tsfill, full

	capture confirm variable estimacion
	if _rc != 0 {
		g estimacion = .
	}
	format estimacion %20.0fc

	tsfill, full
	merge m:1 (anio) using `PIB', nogen
	tsfill, full
	merge m:1 (anio) using `PIB', nogen update replace


	* Proyecciones *
	sort modulos anio
	replace gasto = L.gasto* ///
		(1+var_pibY/100)*indice/L.indice*estimacion/L.estimacion ///
		if anio > `aniovp' & estimacion != . & gasto == .

	replace gasto = L.gasto* ///
		(1+var_pibY/100)*indice/L.indice ///
		if anio > `aniovp' & estimacion == . & gasto == .

	collapse (sum) gasto, by(anio)

	tempfile gastos
	save `gastos'


	************************************
	** Participaciones y aportaciones **
	PEF if ramo == 28, id(`id')																// Participaciones
	collapse (sum) gasto, by(anio)
	merge 1:1 (anio) using `ingresos', nogen update replace
	tsset anio

	rename gasto participaciones
	g propPart = participaciones/recaudacion*100
	replace propPart = L.propPart if propPart == .
	replace participaciones = recaudacion*propPart/100 if participaciones == .
	
	tempfile participaciones
	save `participaciones'


	PEF if ramo == 33, id(`id')																// Aportaciones
	collapse (sum) gasto, by(anio)
	merge 1:1 (anio) using `ingresos', nogen update replace
	tsset anio

	rename gasto aportaciones
	g propApor = aportaciones/recaudacion*100
	replace propApor = L.propApor if propApor == .
	replace aportaciones = recaudacion*propApor/100 if aportaciones == .

	tempfile aportaciones
	save `aportaciones'


	use `gastos', clear
	merge 1:1 (anio) using `participaciones', nogen
	merge 1:1 (anio) using `aportaciones', nogen

	replace gasto = gasto + participaciones + aportaciones

	save `gasto', replace


	***********************
	** Costo de la deuda **
	PEF if desc_funcion == 24, id(`id')														// Costo de la deuda
	collapse (sum) gasto, by(anio)

	merge 1:1 (anio) using "`=c(sysdir_personal)'/bases/SIM/SHRFSP.dta", nogen
	merge 1:1 (anio) using `ingresos', nogen
	tsset anio
	
	rename gasto costoDeuda
	g propCosto = costoDeuda/L.shrfsp*100
	replace propCosto = L.propCosto if propCosto == .

	tempfile costoDeuda
	save `costoDeuda'


	******************************************
	** Union SHRFSP + Ingresos-Gastos + PIB **
	use `PIB', clear
	merge 1:m (anio) using `ingresos', nogen
	merge 1:m (anio) using `gastos', nogen
	merge 1:m (anio) using `costoDeuda', nogen
	merge 1:m (anio) using "`=c(sysdir_personal)'/bases/SIM/SHRFSP.dta", nogen
	tsset anio




	**********************
	*** 2 PROYECCIONES ***
	**********************

	* Diferimientos *
	replace diferimientos = L.diferimientos*(1+var_pibY/100)*indice/L.indice if anio > `aniovp'

	* Tipo de cambio *
	replace tipoDeCambio = L.tipoDeCambio*(1+${depreMXN}/100) if anio >= `aniovp'

	* Deuda interna y externa *
	tempvar externo interno
	g double `externo' = shrfspExterno if anio == `aniovp'-1
	g double `interno' = shrfspInterno if anio == `aniovp'-1
	egen double propExterno = mean(`externo'/(`externo'+`interno'))

	* RFSP Otros. Supuesto: se promedian los ultimos 5 anios *
	egen rfspOtrosProy = mean(rfspOtros/deflator) if anio >= 2013 & rfspOtros != .
	replace rfspOtrosProy = L.rfspOtrosProy*(1+var_pibY/100)*indice/L.indice if rfspOtrosProy == .
	format rfspOtrosProy %20.0fc

	* Ajuste. Supuesto: la diferencia entre lo prespuestario y los RFSP se mantiene constantes *
	g double dif_rfsp = rfsp - (recaudacion - (gasto - diferimientos)) - rfspOtros
	egen dif_rfspProy = mean(dif_rfsp/deflator) if anio >= 2013 & anio < 2017 & dif_rfsp != .
	replace dif_rfspProy = L.dif_rfspProy*(1+var_pibY/100)*indice/L.indice if dif_rfspProy == .
	format dif* %20.0fc

	* RFSP simulado *
	g double rfspSIM = recaudacion - (gasto - diferimientos) + rfspOtros + dif_rfsp
	format rfspSIM %20.0fc

	* SHRFSP externo USD *
	g double shrfspExternoUSD = shrfspExterno/tipoDeCambio
	format shrfsp* %20.0fc


	*************************
	** Balance tradicional **
	g double balanceTradicional = .
	format balanceTradicional %20.0fc

	g double cambioUSD1 = .
	g double cambioUSD2 = .
	g double cambioMXN = .
	format cambio* %20.0fc

	forvalues k=`aniovp'(1)2030 {
		replace balanceTradicional = recaudacion - (gasto - diferimientos) if anio == `k'			// (=) Balance Tradicional

		* Simulador *
		replace rfspSIM = balanceTradicional + rfspOtrosProy + dif_rfspProy if anio == `k'

		replace shrfspExternoUSD = L.shrfspExternoUSD - rfspSIM*propExterno/tipoDeCambio if anio == `k'
		replace shrfspInterno = L.shrfspInterno - rfspSIM*(1-propExterno) if anio == `k'

		* Cambios *
		replace cambioUSD1 = L.shrfspExternoUSD*D.tipoDeCambio if anio == `k'
		replace cambioUSD2 = D.shrfspExternoUSD*tipoDeCambio if anio == `k'
		replace cambioMXN = D.shrfspInterno if anio == `k'

		* SHRFSP *
		replace shrfsp = L.shrfsp + cambioUSD1 + cambioUSD2 + cambioMXN if anio == `k'
		
		* Costo deuda *
		if `k' <= 2029 {
			replace costoDeuda = propCosto/100*L.shrfsp if anio == `k'+1
			replace gasto = gasto + costoDeuda if anio == `k'+1
		}
	}


	** Final **
	replace shrfspExterno = shrfspExternoUSD*tipoDeCambio if shrfspExterno == .
	g double shrfsp_pib = shrfsp/pibY*100
	label var shrfsp_pib "SHRFSP"
	g double shrfspExterno_pib = shrfspExterno/pibY*100
	label var shrfspExterno_pib "SHRFSP Externo"
	g double shrfspInterno_pib = shrfspInterno/pibY*100
	label var shrfspInterno_pib "SHRFSP Interno"
	g double rfspSIM_pib = rfspSIM/pibY*100
	format *_pib %7.3fc


	** Validaci${o}n **
	g double cambio_tot = cambioUSD1 + cambioUSD2 + cambioMXN
	format cambio_tot %20.0fc

	noisily list anio shrfsp_pib shrfspInterno_pib shrfspExterno_pib if anio >= 2012, sep(30)




	****************
	*** 4 Graphs ***
	****************
	if "$graphs" == "on" | "`graphs'" == "graphs" {
		g shrfsp_pib1 = shrfsp_pib if anio > 2017
		g shrfsp_pib2 = shrfsp_pib if anio <= 2017
		graph bar (sum) shrfsp_pib1 shrfsp_pib2 if anio >= 2012, over(anio) ///
			title("Saldo hist${o}rico de requerimientos financieros del sector p${u}blico") ///
			caption("Fuente: Elaborado por el CIEP, utilizando el Simulador Fiscal $simuladorCIEP. Fecha: `c(current_date)', `c(current_time)'.") ///
			ytitle(% PIB) stack yscale(range(0(10)90)) ///
			ylabel(, labsize(small) labgap(small)) ///
			blabel(bar, format(%7.1fc)) ///
			legend(label(1 "Proyecci${o}n") label(2 "Observado")) ///
			name(SHRFSP, replace)

		gr_edit .plotregion1.barlabels[1].Delete
		gr_edit .plotregion1.barlabels[3].Delete
		gr_edit .plotregion1.barlabels[5].Delete
		gr_edit .plotregion1.barlabels[7].Delete
		gr_edit .plotregion1.barlabels[9].Delete
		gr_edit .plotregion1.barlabels[11].Delete

		gr_edit .plotregion1.barlabels[14].Delete
		gr_edit .plotregion1.barlabels[16].Delete
		gr_edit .plotregion1.barlabels[18].Delete
		gr_edit .plotregion1.barlabels[20].Delete
		gr_edit .plotregion1.barlabels[22].Delete
		gr_edit .plotregion1.barlabels[24].Delete
		gr_edit .plotregion1.barlabels[26].Delete
		gr_edit .plotregion1.barlabels[28].Delete
		gr_edit .plotregion1.barlabels[30].Delete
		gr_edit .plotregion1.barlabels[32].Delete
		gr_edit .plotregion1.barlabels[34].Delete
		gr_edit .plotregion1.barlabels[36].Delete
		gr_edit .plotregion1.barlabels[38].Delete
		
		graph export "`=c(sysdir_personal)'/users/`id'/SHRFSP.eps", name(SHRFSP) replace
		*graph export "`=c(sysdir_personal)'/users/`id'/SHRFSP.png", name(SHRFSP) replace
	}
}
end
