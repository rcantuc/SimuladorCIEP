program define UpdateDatosAbiertos, return

	syntax [, UPDATE LOCAL]
	


	************************
	*** 1. Base de datos ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	local mesvp = substr(`"`=trim("`fecha'")'"',6,2)

	capture use "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
	if _rc == 0 & "`update'" != "update" {	
		sort anio mes
		return local ultanio = anio[_N]
		return local ultmes = mes[_N]
		if (`aniovp' == anio[_N] & `mesvp'-2 <= mes[_N]) | (`aniovp'-1 == anio[_N] & `mesvp'-2 < 0) {
			noisily di _newline in g "Datos Abiertos: " in y "base actualizada." in g " {c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
			return local updated = "yes"
			exit
		}
	}
	noisily di _newline in g "Datos Abiertos: " in y "ACTUALIZANDO. Favor de esperar... (5 min. aprox.)"

	*****************************************
	** 1.1 Ingreso, gasto y financiamiento **
	if "`local'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan.csv", clear
	}
	else {
		import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/ingreso_gasto_finan.csv", clear
	}
	tempfile ing
	save "`ing'"

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan_hist.csv", clear
	import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/ingreso_gasto_finan_hist.csv", clear
	tempfile ingH
	save "`ingH'"


	***************
	** 1.2 Deuda **
	if "`local'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica.csv", clear
	}
	else {
		import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/deuda_publica.csv", clear
	}
	tempfile deuda
	save "`deuda'"

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica_hist.csv", clear
	import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/deuda_publica_hist.csv", clear
	tempfile deudaH
	save "`deudaH'"


	****************
	** 1.3 SHRFSP **
	if "`local'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_actual.csv", clear
	}
	else {
		import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/shrfsp_deuda_amplia_actual.csv", clear
	}
	tempfile shrf
	save "`shrf'"

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_antes_2014.csv", clear
	import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.csv", clear
	tempfile shrfH
	save "`shrfH'"


	**************
	** 1.4 RFSP **
	if "`local'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp.csv", clear
	}
	else {
		import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/rfsp.csv", clear
	}
	tempfile rf
	save "`rf'"

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp_metodologia_anterior.csv", clear
	import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/rfsp_metodologia_anterior.csv", clear
	tempfile rfH
	save "`rfH'"


	*************************************************
	** 1.5 Transferencias a Entidades y Municipios **
	if "`local'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.csv", clear
	}
	else {
		import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/transferencias_entidades_fed.csv", clear
	}
	tempfile gf
	save "`gf'"

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed_hist.csv", clear
	import delimited "`c(sysdir_site)'/bases/SHCP/Datos Abiertos/transferencias_entidades_fed_hist.csv", clear
	tempfile gfH
	save "`gfH'"




	**************
	** 2 Append **
	**************
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

	g pos = strpos(nombre,"?")
	egen minpos = min(pos), by(clave)
	forvalues k=1(1)`=_N' {
		
	}
xxx


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
	replace monto = monto*1000 if unidad_de_medida == "Miles de D{c o'}lares"
	format monto %20.0fc

	replace unidad_de_medida = "Pesos" if unidad_de_medida == "Miles de Pesos"
	replace unidad_de_medida = "D{c o'}lares" if unidad_de_medida == "Miles de D{c o'}lares"

	format nombre %30s

	g aniotrimestre = yq(anio,trimestre)
	format aniotrimestre %tq

	g aniomes = ym(anio,mes)
	format aniomes %tm

	label var anio "a{c n~}o"
	label var monto "Monto nominal (pesos)"	

	tempfile datosabiertos
	save "`datosabiertos'"





	****************
	*** 4 Extras ***
	****************


	***************************************************
	** 4.1 ISR fisicas, morales, asalariados y otros **
	import excel "`c(sysdir_site)'/bases/SHCP/Informes trimestrales/ISRInformesTrimestrales.xlsx", ///
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
		saveold "`c(sysdir_site)'/SIM/DatosAbiertos.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/SIM/DatosAbiertos.dta", replace
	}

	*noisily LIF, anio(`aniovp') update rows(2)
	*noisily SHRFSP, anio(`aniovp') update

end
