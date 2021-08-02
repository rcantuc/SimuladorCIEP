**********************************************************
***                  ACTUALIZACIÓN                     ***
***   1) abrir archivos .iqy en Excel de Windows       ***
***   2) guardar y reemplazar .xls dentro de           ***
***      ./TemplateCIEP/basesCIEP/INEGI/SCN/           ***
***   3) correr PIBDeflactor[.ado] con opción "update" ***
**********************************************************

**** Inflacion ****
program define Inflacion, return
quietly {
	version 13.1
	timer on 12

	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	
	syntax [, ANIOvp(int `aniovp') GEO(int 20) FIN(int 2050) NOGraphs UPDATE DIScount(real 3) ///
		OUTPUT]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Inflacion " in y `aniovp' "   }" in g _dup(20) "."



	***********************
	*** 0 Base de datos ***
	***********************
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/inflacion.dta"', clear
	if _rc != 0 | "`update'" == "update" {
		run `"`c(sysdir_personal)'/Inflacion`=subinstr("${pais}"," ","",.)'.do"'
		use `"`c(sysdir_site)'../basesCIEP/SIM/inflacion.dta"', clear
	}

	collapse (last) inflacion (last) mes, by(anio)
	replace inflacion = inflacion/100
	
	local anio_first = anio[1]
	local anio_last = anio[_N]
	local mes_last = mes[_N]

	if `geo' == -1 {
		local geo = `anio_last' - `anio_first'
	}



	*******************
	*** 1 Deflactor ***
	*******************
	* Time series operators: L = lag *
	tsset anio
	tsappend, add(`=`fin'-`anio_last'')

	g double var_inflY = (inflacion/L.inflacion-1)*100
	label var var_inflY "Anual"

	g double var_inflG = ((inflacion/L`=`geo''.inflacion)^(1/`geo')-1)*100
	label var var_inflG "Promedio geom{c e'}trico (`geo' a{c n~}os)"


	***********************************************
	** 1.1 Imputar Par{c a'}metros ex{c o'}genos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	local exo_count = 0
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${inf`k'}
		if _rc == 0 {
			replace var_inflY = ${inf`k'} if anio == `k' & mes != 12
			local exceptI "`exceptI'`k' (${inf`k'}%), "
			local ++exo_count
		}
		else {
			replace var_inflY = L.var_inflG if anio == `k' & mes != 12
		}
		replace inflacion = L.inflacion*(1+var_inflY/100) if anio == `k' & mes != 12
		replace var_inflG = ((inflacion/L`=`geo''.inflacion)^(1/`geo')-1)*100 if anio == `k' & mes != 12
	}

	* Valor presente *
	if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
			continue, break
		}
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio_last' {
			local obslast = `k'
			continue, break
		}
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == 1993 {
			local obsini = `k'
			continue, break
		}
	}

	g double deflatorpp = inflacion/inflacion[`obsvp']
	label var deflatorpp "Poder adquisitivo"


	if "`nographs'" != "nographs" {

		* Graph type *
		if `exo_count'-1 <= 0 {
			local graphtype "bar"
		}
		else {
			local graphtype "area"
		}

		twoway (area deflatorpp anio if (anio < `anio_last' & anio >= 1993) | (anio == `anio_last' & mes == 12)) ///
			(area deflatorpp anio if anio >= `anio_last' & anio >= anio[`obslast'+`exo_count']) ///
			(`graphtype' deflatorpp anio if anio < anio[`obslast'+`exo_count'] & anio >= `anio_last', lwidth(none)), ///
			///title("{bf:{c I'}ndice} nacional de precios al consumidor") ///
			subtitle(${pais}) ///
			xlabel(1995(5)`=round(anio[_N],5)') ///
			ytitle("`aniovp' = 1.000") xtitle("") yline(0) ///
			ylabel(0(1)4, format("%3.0f")) ///
			///text(`crec_deflactor', place(c)) ///
			legend(label(1 "Reportado") label(2 "Proyectado") label(3 "Estimado") order(1 3 2)) ///
			///caption("{it:Fuente: Elaborado con el Simulador Fiscal CIEP v5 e informaci{c o'}n del INEGI, BIE.}") ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last' mes `mes_last'.") ///
			name(inflacionH, replace)
			
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/inflacionH.png", replace name(inflacionH)
		}

		* Texto sobre lineas *
		forvalues k=1(3)`=_N' {
			if var_inflY[`k'] != . & anio[`k'] >= 1993 {
				local crec_infl `"`crec_infl' `=var_inflY[`k']' `=anio[`k']' "`=string(var_inflY[`k'],"%5.1fc")'" "'
			}
		}
		twoway (connected var_inflY anio if (anio < `anio_last' & anio >= 1993) | (anio == `anio_last' & mes == 12)) ///
			(connected var_inflY anio if anio >= `anio_last' & anio >= anio[`obslast'+`exo_count']) ///
			(connected var_inflY anio if anio < anio[`obslast'+`exo_count'] & anio >= `anio_last', lwidth(none)), ///
			///title({bf:Crecimientos} del {c i'}ndice nacional de precios al consumidor) subtitle(${pais}) ///
			subtitle(${pais}) ///
			xlabel(1995(5)`=round(anio[_N],5)') ///
			ylabel(, format(%3.0f)) ///
			ytitle("Variaci{c o'}n (%)") xtitle("") yline(0, lcolor(black)) ///
			text(`crec_infl') ///
			legend(label(1 "Reportado") label(2 "Proyectado") label(3 "Estimado") order(1 3 2)) ///
			///caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5 e informaci{c o'}n del INEGI, BIE.") ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last' mes `mes_last'.") ///
			name(var_inflYH, replace)
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/var_inflYH.png", replace name(var_inflYH)
		}

	}
	
	scalar inflacionLP = string(deflatorpp[_N],"%5.1f")
	scalar inflacionINI = string(deflatorpp[`obsini']*100,"%5.1f")

	timer off 12
	timer list 12
	noisily di _newline in g "Tiempo: " in y round(`=r(t12)/r(nt12)',.1) in g " segs."
}
end
