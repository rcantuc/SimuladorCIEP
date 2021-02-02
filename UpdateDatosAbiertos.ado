program define UpdateDatosAbiertos, return

	syntax [, UPDATE]
	


	************************
	*** 1. Base de datos ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	local mesvp = substr(`"`=trim("`fecha'")'"',6,2)

	capture use "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", clear

	if (_rc == 0 | _rc == 610) & "`update'" != "update" {	
		sort anio mes
		return local ultanio = anio[_N]
		return local ultmes = mes[_N]

		if (`aniovp' == anio[_N] & `mesvp' <= mes[_N]+2) | (`aniovp' == anio[_N]+1 & mes[_N] > 10) {
			noisily di _newline in g "Datos Abiertos: " in y "base actualizada." in g " {c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
			return local updated = "yes"
			exit
		}
	}
	noisily di _newline in g "Datos Abiertos: " in y "ACTUALIZANDO. Favor de esperar. Descargando bases de SHCP (10 mins. aprox.)."


	*****************************************
	** 1.1 Ingreso, gasto y financiamiento **
	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan.csv", clear
	tempfile ing
	save `ing'

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan_hist.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/ingreso_gasto_finan_hist.csv", clear
	tempfile ingH
	save `ingH'


	***************
	** 1.2 Deuda **
	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/deuda_publica.csv", clear
	tempfile deuda
	save `deuda'

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica_hist.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/deuda_publica_hist.csv", clear
	tempfile deudaH
	save `deudaH'


	****************
	** 1.3 SHRFSP **
	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_actual.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplia_actual.csv", clear
	tempfile shrf
	save `shrf'

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_antes_2014.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.csv", clear
	tempfile shrfH
	save `shrfH'


	**************
	** 1.4 RFSP **
	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/rfsp.csv", clear
	tempfile rf
	save `rf'

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp_metodologia_anterior.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/rfsp_metodologia_anterior.csv", clear
	tempfile rfH
	save `rfH'


	*************************************************
	** 1.5 Transferencias a Entidades y Municipios **
	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/transferencias_entidades_fed.csv", clear
	tempfile gf
	save `gf'

	*import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed_hist.csv", clear
	import delimited "`c(sysdir_site)'../basesCIEP/SHCP/Datos Abiertos/transferencias_entidades_fed_hist.csv", clear
	tempfile gfH
	save `gfH'




	**************
	** 2 Append **
	**************
	use `ing', clear
	append using `ingH'
	append using `deuda'
	append using `deudaH'
	append using `shrf'
	append using `shrfH'
	append using `rf'
	append using `rfH'
	append using `gf'
	append using `gfH'




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
	save `datosabiertos'





	****************
	*** 4 Extras ***
	****************


	***************************************************
	** 4.1 ISR fisicas, morales, asalariados y otros **
	use if clave_de_concepto == "XNA0120" using `datosabiertos', clear


	* 2002 *
	g double monto_m = monto*33428.0/81991.8 if anio == 2002 & trimestre == 1
	g double monto_f = monto*2628.8/81991.8 if anio == 2002 & trimestre == 1
	g double monto_s = monto*42623.3/81991.8 if anio == 2002 & trimestre == 1
	g double monto_r = monto*3311.7/81991.8 if anio == 2002 & trimestre == 1

	replace monto_m = monto*(68200.9-33428.0)/(169643.0-81991.8) if anio == 2002 & trimestre == 2
	replace monto_f = monto*(13660.9-2628.8)/(169643.0-81991.8) if anio == 2002 & trimestre == 2
	replace monto_s = monto*(82117.1-42623.3)/(169643.0-81991.8) if anio == 2002 & trimestre == 2
	replace monto_r = monto*(5664.1-3311.7)/(169643.0-81991.8) if anio == 2002 & trimestre == 2

	replace monto_m = monto*(95702.0-68200.9)/(240155.3-169643.0) if anio == 2002 & trimestre == 3
	replace monto_f = monto*(20212.1-13660.9)/(240155.3-169643.0) if anio == 2002 & trimestre == 3
	replace monto_s = monto*(115603.4-82117.1)/(240155.3-169643.0) if anio == 2002 & trimestre == 3
	replace monto_r = monto*(8637.8-5664.1)/(240155.3-169643.0) if anio == 2002 & trimestre == 3

	replace monto_m = monto*(121282.1-95702.0)/(308608.5-240155.3) if anio == 2002 & trimestre == 4
	replace monto_f = monto*(23690.1-20212.1)/(308608.5-240155.3) if anio == 2002 & trimestre == 4
	replace monto_s = monto*(152478.8-115603.4)/(308608.5-240155.3) if anio == 2002 & trimestre == 4
	replace monto_r = monto*(11157.5-8637.8)/(308608.5-240155.3) if anio == 2002 & trimestre == 4

	* 2003 *
	replace monto_m = monto*38994.2/94043.7 if anio == 2003 & trimestre == 1
	replace monto_f = monto*4487.5/94043.7 if anio == 2003 & trimestre == 1
	replace monto_s = monto*47581.2/94043.7 if anio == 2003 & trimestre == 1
	replace monto_r = monto*2980.8/94043.7 if anio == 2003 & trimestre == 1

	replace monto_m = monto*(70416.1-38994.2)/(176670.2-94043.7) if anio == 2003 & trimestre == 2
	replace monto_f = monto*(9859.1-4487.5)/(176670.2-94043.7) if anio == 2003 & trimestre == 2
	replace monto_s = monto*(91021.1-47581.2)/(176670.2-94043.7) if anio == 2003 & trimestre == 2
	replace monto_r = monto*(5373.9-2980.8)/(176670.2-94043.7) if anio == 2003 & trimestre == 2

	replace monto_m = monto*(95332.4-70416.1)/(250110.6-176670.2) if anio == 2003 & trimestre == 3
	replace monto_f = monto*(13905.6-9859.1)/(250110.6-176670.2) if anio == 2003 & trimestre == 3
	replace monto_s = monto*(133105.7-91021.1)/(250110.6-176670.2) if anio == 2003 & trimestre == 3
	replace monto_r = monto*(7766.9-5373.9)/(250110.6-176670.2) if anio == 2003 & trimestre == 3

	replace monto_m = monto*(122422.9-95332.4)/(322421.6-250110.6) if anio == 2003 & trimestre == 4
	replace monto_f = monto*(17870.1-13905.6)/(322421.6-250110.6) if anio == 2003 & trimestre == 4
	replace monto_s = monto*(172327.7-133105.7)/(322421.6-250110.6) if anio == 2003 & trimestre == 4
	replace monto_r = monto*(9800.9-7766.9)/(322421.6-250110.6) if anio == 2003 & trimestre == 4

	* 2004 *
	replace monto_m = monto*37554.2/102895.9 if anio == 2004 & trimestre == 1
	replace monto_f = monto*4635.9/102895.9 if anio == 2004 & trimestre == 1
	replace monto_s = monto*57248.5/102895.9 if anio == 2004 & trimestre == 1
	replace monto_r = monto*3457.3/102895.9 if anio == 2004 & trimestre == 1

	replace monto_m = monto*(66207.4-37554.2)/(187579.7-102895.9) if anio == 2004 & trimestre == 2
	replace monto_f = monto*(11019.6-4635.9)/(187579.7-102895.9) if anio == 2004 & trimestre == 2
	replace monto_s = monto*(104566.2-57248.5)/(187579.7-102895.9) if anio == 2004 & trimestre == 2
	replace monto_r = monto*(5786.5-3457.3)/(187579.7-102895.9) if anio == 2004 & trimestre == 2

	replace monto_m = monto*(103624.0-66207.4)/(257281.1-187579.7) if anio == 2004 & trimestre == 3
	replace monto_f = monto*(14920.1-11019.6)/(257281.1-187579.7) if anio == 2004 & trimestre == 3
	replace monto_s = monto*(130466.7-104566.2)/(257281.1-187579.7) if anio == 2004 & trimestre == 3
	replace monto_r = monto*(8270.3-5786.5)/(257281.1-187579.7) if anio == 2004 & trimestre == 3

	replace monto_m = monto*(118325.3-103624.0)/(329945.2-257281.1) if anio == 2004 & trimestre == 4
	replace monto_f = monto*(18442.9-14920.1)/(329945.2-257281.1) if anio == 2004 & trimestre == 4
	replace monto_s = monto*(181695.3-130466.7)/(329945.2-257281.1) if anio == 2004 & trimestre == 4
	replace monto_r = monto*(11481.7-8270.3)/(329945.2-257281.1) if anio == 2004 & trimestre == 4

	* 2005 *
	replace monto_m = monto*46071.0/104935.8 if anio == 2005 & trimestre == 1
	replace monto_f = monto*2539.9/104935.8 if anio == 2005 & trimestre == 1
	replace monto_s = monto*51496.9/104935.8 if anio == 2005 & trimestre == 1
	replace monto_r = monto*4828.0/104935.8 if anio == 2005 & trimestre == 1

	replace monto_m = monto*(85823.1-46071.0)/(205536.8-104935.8) if anio == 2005 & trimestre == 2
	replace monto_f = monto*(7262.8-2539.9)/(205536.8-104935.8) if anio == 2005 & trimestre == 2
	replace monto_s = monto*(104688.1-51496.9)/(205536.8-104935.8) if anio == 2005 & trimestre == 2
	replace monto_r = monto*(7762.8-4828.0)/(205536.8-104935.8) if anio == 2005 & trimestre == 2

	replace monto_m = monto*(102688.0-85823.1)/(286464.4-205536.8) if anio == 2005 & trimestre == 3
	replace monto_f = monto*(9738.7-7262.8)/(286464.4-205536.8) if anio == 2005 & trimestre == 3
	replace monto_s = monto*(143846.1-104688.1)/(286464.4-205536.8) if anio == 2005 & trimestre == 3
	replace monto_r = monto*(10847.9+19343.7-7762.8)/(286464.4-205536.8) if anio == 2005 & trimestre == 3

	replace monto_m = monto*(135840.4-102688.0)/(372107.2-286464.4) if anio == 2005 & trimestre == 4
	replace monto_f = monto*(12017.5-9738.7)/(372107.2-286464.4) if anio == 2005 & trimestre == 4
	replace monto_s = monto*(183851.1-143846.1)/(372107.2-286464.4) if anio == 2005 & trimestre == 4
	replace monto_r = monto*(14619.1+25779.1-(10847.9+19343.7))/(372107.2-286464.4) if anio == 2005 & trimestre == 4

	* 2006 *
	replace monto_m = monto*46735.9/114316.7 if anio == 2006 & trimestre == 1
	replace monto_f = monto*2671.1/114316.7 if anio == 2006 & trimestre == 1
	replace monto_s = monto*51501.7/114316.7 if anio == 2006 & trimestre == 1
	replace monto_r = monto*6076.3/114316.7 if anio == 2006 & trimestre == 1
	g double monto_o = monto*7331.7/114316.7 if anio == 2006 & trimestre == 1

	replace monto_m = monto*(100804.3-46735.9)/(238121.0-114316.7) if anio == 2006 & trimestre == 2
	replace monto_f = monto*(9524.9-2671.1)/(238121.0-114316.7) if anio == 2006 & trimestre == 2
	replace monto_s = monto*(101905.5-51501.7)/(238121.0-114316.7) if anio == 2006 & trimestre == 2
	replace monto_r = monto*(11206.8-6076.3)/(238121.0-114316.7) if anio == 2006 & trimestre == 2
	replace monto_o = monto*(14679.5-7331.7)/(238121.0-114316.7) if anio == 2006 & trimestre == 2

	replace monto_m = monto*(139046.2-100804.3)/(346155.9-238121.0) if anio == 2006 & trimestre == 3
	replace monto_f = monto*(12349.1-9524.9)/(346155.9-238121.0) if anio == 2006 & trimestre == 3
	replace monto_s = monto*(157648.9-101905.5)/(346155.9-238121.0) if anio == 2006 & trimestre == 3
	replace monto_r = monto*(15086.1-11206.8)/(346155.9-238121.0) if anio == 2006 & trimestre == 3
	replace monto_o = monto*(22025.6-14679.5)/(346155.9-238121.0) if anio == 2006 & trimestre == 3

	replace monto_m = monto*(171437.1-139046.2)/(439264.3-346155.9) if anio == 2006 & trimestre == 4
	replace monto_f = monto*(14979.1-12349.1)/(439264.3-346155.9) if anio == 2006 & trimestre == 4
	replace monto_s = monto*(204069.8-157648.9)/(439264.3-346155.9) if anio == 2006 & trimestre == 4
	replace monto_r = monto*(19254.6-15086.1)/(439264.3-346155.9) if anio == 2006 & trimestre == 4
	replace monto_o = monto*(29523.7-22025.6)/(439264.3-346155.9) if anio == 2006 & trimestre == 4

	* 2007 *
	replace monto_m = monto*53201.1/130683.7 if anio == 2007 & trimestre == 1
	replace monto_f = monto*2878.4/130683.7 if anio == 2007 & trimestre == 1
	replace monto_s = monto*60122.2/130683.7 if anio == 2007 & trimestre == 1
	replace monto_r = monto*6318.2/130683.7 if anio == 2007 & trimestre == 1
	replace monto_o = monto*8163.8/130683.7 if anio == 2007 & trimestre == 1

	replace monto_m = monto*(120091.4-53201.1)/(276967.5-130683.7) if anio == 2007 & trimestre == 2
	replace monto_f = monto*(9134.1-2878.4)/(276967.5-130683.7) if anio == 2007 & trimestre == 2
	replace monto_s = monto*(120870.3-60122.2)/(276967.5-130683.7) if anio == 2007 & trimestre == 2
	replace monto_r = monto*(10229.0-6318.2)/(276967.5-130683.7) if anio == 2007 & trimestre == 2
	replace monto_o = monto*(16642.7-8163.8)/(276967.5-130683.7) if anio == 2007 & trimestre == 2

	replace monto_m = monto*(164451.3-120091.4)/(388183.9-276967.5) if anio == 2007 & trimestre == 3
	replace monto_f = monto*(12163.2-9134.1)/(388183.9-276967.5) if anio == 2007 & trimestre == 3
	replace monto_s = monto*(171257.9-120870.3)/(388183.9-276967.5) if anio == 2007 & trimestre == 3
	replace monto_r = monto*(14904.0-10229.0)/(388183.9-276967.5) if anio == 2007 & trimestre == 3
	replace monto_o = monto*(25407.5-16642.7)/(388183.9-276967.5) if anio == 2007 & trimestre == 3

	replace monto_m = monto*(217790.4-164451.3)/(511259.4-388183.9) if anio == 2007 & trimestre == 4
	replace monto_f = monto*(15097.9-12163.2)/(511259.4-388183.9) if anio == 2007 & trimestre == 4
	replace monto_s = monto*(223840.5-171257.9)/(511259.4-388183.9) if anio == 2007 & trimestre == 4
	replace monto_r = monto*(19792.1-14904.0)/(511259.4-388183.9) if anio == 2007 & trimestre == 4
	replace monto_o = monto*(34738.5-25407.5)/(511259.4-388183.9) if anio == 2007 & trimestre == 4

	* 2008 *
	replace monto_m = monto*68455.8/160195.4 if anio == 2008 & trimestre == 1
	replace monto_f = monto*3318.2/160195.4 if anio == 2008 & trimestre == 1
	replace monto_s = monto*71308.7/160195.4 if anio == 2008 & trimestre == 1
	replace monto_r = monto*6561.4/160195.4 if anio == 2008 & trimestre == 1
	replace monto_o = monto*10551.3/160195.4 if anio == 2008 & trimestre == 1

	replace monto_m = monto*(117629.6-68455.8)/(308704.6-160195.4) if anio == 2008 & trimestre == 2
	replace monto_f = monto*(10466.2-3318.2)/(308704.6-160195.4) if anio == 2008 & trimestre == 2
	replace monto_s = monto*(148777.2-71308.7)/(308704.6-160195.4) if anio == 2008 & trimestre == 2
	replace monto_r = monto*(10561.7-6561.4)/(308704.6-160195.4) if anio == 2008 & trimestre == 2
	replace monto_o = monto*(21269.9-10551.3)/(308704.6-160195.4) if anio == 2008 & trimestre == 2

	replace monto_m = monto*(158435.6-117629.6)/(428612.8-308704.6) if anio == 2008 & trimestre == 3
	replace monto_f = monto*(13571.4-10466.2)/(428612.8-308704.6) if anio == 2008 & trimestre == 3
	replace monto_s = monto*(210288.7-148777.2)/(428612.8-308704.6) if anio == 2008 & trimestre == 3
	replace monto_r = monto*(14777.2-10561.7)/(428612.8-308704.6) if anio == 2008 & trimestre == 3
	replace monto_o = monto*(31539.9-21269.9)/(428612.8-308704.6) if anio == 2008 & trimestre == 3

	replace monto_m = monto*(214610.9-158435.6)/(560816.0-428612.8) if anio == 2008 & trimestre == 4
	replace monto_f = monto*(16311.8-13571.4)/(560816.0-428612.8) if anio == 2008 & trimestre == 4
	replace monto_s = monto*(268958.1-210288.7)/(560816.0-428612.8) if anio == 2008 & trimestre == 4
	replace monto_r = monto*(19150.0-14777.2)/(560816.0-428612.8) if anio == 2008 & trimestre == 4
	replace monto_o = monto*(41785.2-31539.9)/(560816.0-428612.8) if anio == 2008 & trimestre == 4

	* 2009 *
	replace monto_m = monto*53219.8/150613.8 if anio == 2009 & trimestre == 1
	replace monto_f = monto*3071.4/150613.8 if anio == 2009 & trimestre == 1
	replace monto_s = monto*76052.3/150613.8 if anio == 2009 & trimestre == 1
	replace monto_r = monto*7198.3/150613.8 if anio == 2009 & trimestre == 1
	replace monto_o = monto*11072.0/150613.8 if anio == 2009 & trimestre == 1

	replace monto_m = monto*(96538.0-53219.8)/(279366.7-150613.8) if anio == 2009 & trimestre == 2
	replace monto_f = monto*(9814.5-3071.4)/(279366.7-150613.8) if anio == 2009 & trimestre == 2
	replace monto_s = monto*(139517.2-76052.3)/(279366.7-150613.8) if anio == 2009 & trimestre == 2
	replace monto_r = monto*(11890.3-7198.3)/(279366.7-150613.8) if anio == 2009 & trimestre == 2
	replace monto_o = monto*(21606.7-11072.0)/(279366.7-150613.8) if anio == 2009 & trimestre == 2

	replace monto_m = monto*(140211.6-96538.0)/(402070.2-279366.7) if anio == 2009 & trimestre == 3
	replace monto_f = monto*(12929.3-9814.5)/(402070.2-279366.7) if anio == 2009 & trimestre == 3
	replace monto_s = monto*(200243.1-139517.2)/(402070.2-279366.7) if anio == 2009 & trimestre == 3
	replace monto_r = monto*(16904.3-11890.3)/(402070.2-279366.7) if anio == 2009 & trimestre == 3
	replace monto_o = monto*(31781.9-21606.7)/(402070.2-279366.7) if anio == 2009 & trimestre == 3

	replace monto_m = monto*(191685.3-140211.6)/(536668.8-402070.2) if anio == 2009 & trimestre == 4
	replace monto_f = monto*(15633.1-12929.3)/(536668.8-402070.2) if anio == 2009 & trimestre == 4
	replace monto_s = monto*(264596.6-200243.1)/(536668.8-402070.2) if anio == 2009 & trimestre == 4
	replace monto_r = monto*(22521.4-16904.3)/(536668.8-402070.2) if anio == 2009 & trimestre == 4
	replace monto_o = monto*(42232.4-31781.9)/(536668.8-402070.2) if anio == 2009 & trimestre == 4

	* 2010 *
	replace monto_m = monto*68714.2/173938.7 if anio == 2010 & trimestre == 1
	replace monto_f = monto*3158.6/173938.7 if anio == 2010 & trimestre == 1
	replace monto_s = monto*81088.7/173938.7 if anio == 2010 & trimestre == 1
	replace monto_r = monto*10912.3/173938.7 if anio == 2010 & trimestre == 1
	replace monto_o = monto*10064.9/173938.7 if anio == 2010 & trimestre == 1

	replace monto_m = monto*(125882.9-68714.2)/(326052.2-173938.7) if anio == 2010 & trimestre == 2
	replace monto_f = monto*(8908.7-3158.6)/(326052.2-173938.7) if anio == 2010 & trimestre == 2
	replace monto_s = monto*(155934.1-81088.7)/(326052.2-173938.7) if anio == 2010 & trimestre == 2
	replace monto_r = monto*(15744.8-10912.3)/(326052.2-173938.7) if anio == 2010 & trimestre == 2
	replace monto_o = monto*(19581.7-10064.9)/(326052.2-173938.7) if anio == 2010 & trimestre == 2

	replace monto_m = monto*(184109.5-125882.9)/(470823.6-326052.2) if anio == 2010 & trimestre == 3
	replace monto_f = monto*(12213.1-8908.7)/(470823.6-326052.2) if anio == 2010 & trimestre == 3
	replace monto_s = monto*(224142.1-155934.1)/(470823.6-326052.2) if anio == 2010 & trimestre == 3
	replace monto_r = monto*(21368.3-15744.8)/(470823.6-326052.2) if anio == 2010 & trimestre == 3
	replace monto_o = monto*(28990.6-19581.7)/(470823.6-326052.2) if anio == 2010 & trimestre == 3

	replace monto_m = monto*(246745.0-184109.5)/(627165.0-470823.6) if anio == 2010 & trimestre == 4
	replace monto_f = monto*(15324.2-12213.1)/(627165.0-470823.6) if anio == 2010 & trimestre == 4
	replace monto_s = monto*(298148.7-224142.1)/(627165.0-470823.6) if anio == 2010 & trimestre == 4
	replace monto_r = monto*(27070.6-21368.3)/(627165.0-470823.6) if anio == 2010 & trimestre == 4
	replace monto_o = monto*(39876.5-28990.6)/(627165.0-470823.6) if anio == 2010 & trimestre == 4

	* 2011 *
	replace monto_m = monto*81748.4/195758.9 if anio == 2011 & trimestre == 1
	replace monto_f = monto*3392.2/195758.9 if anio == 2011 & trimestre == 1
	replace monto_s = monto*93230.8/195758.9 if anio == 2011 & trimestre == 1
	replace monto_r = monto*7220.1/195758.9 if anio == 2011 & trimestre == 1
	replace monto_o = monto*10167.4/195758.9 if anio == 2011 & trimestre == 1

	replace monto_m = monto*(149571.2-81748.4)/(369125.2-195758.9) if anio == 2011 & trimestre == 2
	replace monto_f = monto*(9279.9-3392.2)/(369125.2-195758.9) if anio == 2011 & trimestre == 2
	replace monto_s = monto*(176950.5-93230.8)/(369125.2-195758.9) if anio == 2011 & trimestre == 2
	replace monto_r = monto*(12453.0-7220.1)/(369125.2-195758.9) if anio == 2011 & trimestre == 2
	replace monto_o = monto*(20870.6-10167.4)/(369125.2-195758.9) if anio == 2011 & trimestre == 2

	replace monto_m = monto*(221960.1-149571.2)/(539001.3-369125.2) if anio == 2011 & trimestre == 3
	replace monto_f = monto*(12844.7-9279.9)/(539001.3-369125.2) if anio == 2011 & trimestre == 3
	replace monto_s = monto*(255280.2-176950.5)/(539001.3-369125.2) if anio == 2011 & trimestre == 3
	replace monto_r = monto*(17757.0-12453.0)/(539001.3-369125.2) if anio == 2011 & trimestre == 3
	replace monto_o = monto*(31159.3-20870.6)/(539001.3-369125.2) if anio == 2011 & trimestre == 3

	replace monto_m = monto*(303175.8-221960.1)/(721835.5-539001.3) if anio == 2011 & trimestre == 4
	replace monto_f = monto*(16301.7-12844.7)/(721835.5-539001.3) if anio == 2011 & trimestre == 4
	replace monto_s = monto*(336084.0-255280.2)/(721835.5-539001.3) if anio == 2011 & trimestre == 4
	replace monto_r = monto*(24308.9-17757.0)/(721835.5-539001.3) if anio == 2011 & trimestre == 4
	replace monto_o = monto*(41965.1-31159.3)/(721835.5-539001.3) if anio == 2011 & trimestre == 4

	* 2012 *
	replace monto_m = monto*88937.2/217945.7 if anio == 2012 & trimestre == 1
	replace monto_f = monto*4199.4/217945.7 if anio == 2012 & trimestre == 1
	replace monto_s = monto*104976.1/217945.7 if anio == 2012 & trimestre == 1
	replace monto_r = monto*7990.9/217945.7 if anio == 2012 & trimestre == 1
	replace monto_o = monto*11842.1/217945.7 if anio == 2012 & trimestre == 1

	replace monto_m = monto*(152638.4-88937.2)/(401402.1-217945.7) if anio == 2012 & trimestre == 2
	replace monto_f = monto*(11516.3-4199.4)/(401402.1-217945.7) if anio == 2012 & trimestre == 2
	replace monto_s = monto*(199817.9-104976.1)/(401402.1-217945.7) if anio == 2012 & trimestre == 2
	replace monto_r = monto*(14160.8-7990.9)/(401402.1-217945.7) if anio == 2012 & trimestre == 2
	replace monto_o = monto*(23268.7-11842.1)/(401402.1-217945.7) if anio == 2012 & trimestre == 2

	replace monto_m = monto*(217550.0-152638.4)/(576417.6-401402.1) if anio == 2012 & trimestre == 3
	replace monto_f = monto*(15675.8-11516.3)/(576417.6-401402.1) if anio == 2012 & trimestre == 3
	replace monto_s = monto*(288274.1-199817.9)/(576417.6-401402.1) if anio == 2012 & trimestre == 3
	replace monto_r = monto*(20268.6-14160.8)/(576417.6-401402.1) if anio == 2012 & trimestre == 3
	replace monto_o = monto*(34649.1-23268.7)/(576417.6-401402.1) if anio == 2012 & trimestre == 3

	replace monto_m = monto*(288360.3-217550.0)/(760106.2-576417.6) if anio == 2012 & trimestre == 4
	replace monto_f = monto*(20038.1-15675.8)/(760106.2-576417.6) if anio == 2012 & trimestre == 4
	replace monto_s = monto*(377663.2-288274.1)/(760106.2-576417.6) if anio == 2012 & trimestre == 4
	replace monto_r = monto*(28154.0-20268.6)/(760106.2-576417.6) if anio == 2012 & trimestre == 4
	replace monto_o = monto*(45890.6-34649.1)/(760106.2-576417.6) if anio == 2012 & trimestre == 4

	* 2013 *
	replace monto_m = monto*89739.0/223862.6 if anio == 2013 & trimestre == 1
	replace monto_f = monto*4539.4/223862.6 if anio == 2013 & trimestre == 1
	replace monto_s = monto*108492.2/223862.6 if anio == 2013 & trimestre == 1
	replace monto_r = monto*8620.5/223862.6 if anio == 2013 & trimestre == 1
	replace monto_o = monto*12471.5/223862.6 if anio == 2013 & trimestre == 1

	replace monto_m = monto*(212295.6-89739.0)/(477589.3-223862.6) if anio == 2013 & trimestre == 2
	replace monto_f = monto*(12089.8-4539.4)/(477589.3-223862.6) if anio == 2013 & trimestre == 2
	replace monto_s = monto*(211380.5-108492.2)/(477589.3-223862.6) if anio == 2013 & trimestre == 2
	replace monto_r = monto*(15526.4-8620.5)/(477589.3-223862.6) if anio == 2013 & trimestre == 2
	replace monto_o = monto*(26297.0-12471.5)/(477589.3-223862.6) if anio == 2013 & trimestre == 2

	replace monto_m = monto*(301821.4-212295.6)/(693391.3-477589.3) if anio == 2013 & trimestre == 3
	replace monto_f = monto*(16755.0-12089.8)/(693391.3-477589.3) if anio == 2013 & trimestre == 3
	replace monto_s = monto*(305644.8-211380.5)/(693391.3-477589.3) if anio == 2013 & trimestre == 3
	replace monto_r = monto*(21914.9-15526.4)/(693391.3-477589.3) if anio == 2013 & trimestre == 3
	replace monto_o = monto*(47255.2-26297.0)/(693391.3-477589.3) if anio == 2013 & trimestre == 3

	replace monto_m = monto*(392199.4-301821.4)/(906839.2-693391.3) if anio == 2013 & trimestre == 4
	replace monto_f = monto*(21569.0-16755.0)/(906839.2-693391.3) if anio == 2013 & trimestre == 4
	replace monto_s = monto*(404051.9-305644.8)/(906839.2-693391.3) if anio == 2013 & trimestre == 4
	replace monto_r = monto*(28604.3-21914.9)/(906839.2-693391.3) if anio == 2013 & trimestre == 4
	replace monto_o = monto*(60414.6-47255.2)/(906839.2-693391.3) if anio == 2013 & trimestre == 4

	* 2014 *
	replace monto_m = monto*105490.1/273966.0 if anio == 2014 & trimestre == 1
	replace monto_f = monto*5007.0/273966.0 if anio == 2014 & trimestre == 1
	replace monto_s = monto*126893.5/273966.0 if anio == 2014 & trimestre == 1
	replace monto_r = monto*9759.6/273966.0 if anio == 2014 & trimestre == 1
	replace monto_o = monto*26815.8/273966.0 if anio == 2014 & trimestre == 1

	replace monto_m = monto*(237734.6-(105490.1+26815.8))/(526178.3-273966.0) if anio == 2014 & trimestre == 2
	replace monto_f = monto*(28511.0-5007.0)/(526178.3-273966.0) if anio == 2014 & trimestre == 2
	replace monto_s = monto*(244042.8-126893.5)/(526178.3-273966.0) if anio == 2014 & trimestre == 2
	replace monto_r = monto*(15889.9-9759.6)/(526178.3-273966.0) if anio == 2014 & trimestre == 2

	replace monto_m = monto*(335506.5-237734.6)/(747361.5-526178.3) if anio == 2014 & trimestre == 3
	replace monto_f = monto*(34467.4-28511.0)/(747361.5-526178.3) if anio == 2014 & trimestre == 3
	replace monto_s = monto*(353354.7-244042.8)/(747361.5-526178.3) if anio == 2014 & trimestre == 3
	replace monto_r = monto*(24032.9-15889.9)/(747361.5-526178.3) if anio == 2014 & trimestre == 3

	replace monto_m = monto*(441317.2-335506.5)/(986601.6-747361.5) if anio == 2014 & trimestre == 4
	replace monto_f = monto*(40975.6-34467.4)/(986601.6-747361.5) if anio == 2014 & trimestre == 4
	replace monto_s = monto*(473232.7-353354.7)/(986601.6-747361.5) if anio == 2014 & trimestre == 4
	replace monto_r = monto*(31076.1-24032.9)/(986601.6-747361.5) if anio == 2014 & trimestre == 4

	* 2015 *
	replace monto_m = monto*203941.3/378244.7 if anio == 2015 & trimestre == 1
	replace monto_f = monto*6924.3/378244.7 if anio == 2015 & trimestre == 1
	replace monto_s = monto*155094.5/378244.7 if anio == 2015 & trimestre == 1
	replace monto_r = monto*12284.6/378244.7 if anio == 2015 & trimestre == 1

	replace monto_m = monto*(340098.5-203941.3)/(670528.1-378244.7) if anio == 2015 & trimestre == 2
	replace monto_f = monto*(14620.4-6924.3)/(670528.1-378244.7) if anio == 2015 & trimestre == 2
	replace monto_s = monto*(296363.8-155094.5)/(670528.1-378244.7) if anio == 2015 & trimestre == 2
	replace monto_r = monto*(19445.5-12284.6)/(670528.1-378244.7) if anio == 2015 & trimestre == 2

	replace monto_m = monto*(472567.8-340098.5)/(949276.6-670528.1) if anio == 2015 & trimestre == 3
	replace monto_f = monto*(21799.7-14620.4)/(949276.6-670528.1) if anio == 2015 & trimestre == 3
	replace monto_s = monto*(426377.2-296363.8)/(949276.6-670528.1) if anio == 2015 & trimestre == 3
	replace monto_r = monto*(28532.0-19445.5)/(949276.6-670528.1) if anio == 2015 & trimestre == 3

	replace monto_m = monto*(592443.0-472567.8)/(1238095.6-949276.6) if anio == 2015 & trimestre == 4
	replace monto_f = monto*(28836.3-21799.7)/(1238095.6-949276.6) if anio == 2015 & trimestre == 4
	replace monto_s = monto*(580547.7-426377.28)/(1238095.6-949276.6) if anio == 2015 & trimestre == 4
	replace monto_r = monto*(36268.6-28532.0)/(1238095.6-949276.6) if anio == 2015 & trimestre == 4

	* 2016 *
	replace monto_m = monto*233536.7/419068.3 if anio == 2016 & trimestre == 1
	replace monto_f = monto*9102.2/419068.3 if anio == 2016 & trimestre == 1
	replace monto_s = monto*163798.8/419068.3 if anio == 2016 & trimestre == 1
	replace monto_r = monto*12630.6/419068.3 if anio == 2016 & trimestre == 1

	replace monto_m = monto*(397342.7-233536.7)/(767211.9-419068.3) if anio == 2016 & trimestre == 2
	replace monto_f = monto*(23564.5-9102.2)/(767211.9-419068.3) if anio == 2016 & trimestre == 2
	replace monto_s = monto*(325114.8-163798.8)/(767211.9-419068.3) if anio == 2016 & trimestre == 2
	replace monto_r = monto*(21189.9-12630.6)/(767211.9-419068.3) if anio == 2016 & trimestre == 2

	replace monto_m = monto*(538142.9-397342.7)/(1071556.1-767211.9) if anio == 2016 & trimestre == 3
	replace monto_f = monto*(31956.0-23564.5)/(1071556.1-767211.9) if anio == 2016 & trimestre == 3
	replace monto_s = monto*(470383.1-325114.8)/(1071556.1-767211.9) if anio == 2016 & trimestre == 3
	replace monto_r = monto*(31074.0-21189.9)/(1071556.1-767211.9) if anio == 2016 & trimestre == 3

	replace monto_m = monto*(700924.6-538142.9)/(1426920.2-1071556.1) if anio == 2016 & trimestre == 4
	replace monto_f = monto*(40934.6-31956.0)/(1426920.2-1071556.1) if anio == 2016 & trimestre == 4
	replace monto_s = monto*(640849.3-470383.1)/(1426920.2-1071556.1) if anio == 2016 & trimestre == 4
	replace monto_r = monto*(44211.6-31074.0)/(1426920.2-1071556.1) if anio == 2016 & trimestre == 4

	* 2017 *
	replace monto_m = monto*215989.1/420336.9 if anio == 2017 & trimestre == 1
	replace monto_f = monto*10299.6/420336.9 if anio == 2017 & trimestre == 1
	replace monto_s = monto*180211.4/420336.9 if anio == 2017 & trimestre == 1
	replace monto_r = monto*13836.8/420336.9 if anio == 2017 & trimestre == 1

	replace monto_m = monto*(431455.5-215989.1)/(832841.8-420336.9) if anio == 2017 & trimestre == 2
	replace monto_f = monto*(22626.2-10299.6)/(832841.8-420336.9) if anio == 2017 & trimestre == 2
	replace monto_s = monto*(353956.7-180211.4)/(832841.8-420336.9) if anio == 2017 & trimestre == 2
	replace monto_r = monto*(24803.4-13836.8)/(832841.8-420336.9) if anio == 2017 & trimestre == 2

	replace monto_m = monto*(596580.8-431455.5)/(1186009.3-832841.8) if anio == 2017 & trimestre == 3
	replace monto_f = monto*(39249.3-22626.2)/(1186009.3-832841.8) if anio == 2017 & trimestre == 3
	replace monto_s = monto*(514684.0-353956.7)/(1186009.3-832841.8) if anio == 2017 & trimestre == 3
	replace monto_r = monto*(35495.2-24803.4)/(1186009.3-832841.8) if anio == 2017 & trimestre == 3

	replace monto_m = monto*(769193.2-596580.8)/(1569230.0-1186009.3) if anio == 2017 & trimestre == 4
	replace monto_f = monto*(52230.9-39249.3)/(1569230.0-1186009.3) if anio == 2017 & trimestre == 4
	replace monto_s = monto*(701878.5-514684.0)/(1569230.0-1186009.3) if anio == 2017 & trimestre == 4
	replace monto_r = monto*(45927.5-35495.2)/(1569230.0-1186009.3) if anio == 2017 & trimestre == 4

	* 2018 *
	replace monto_m = monto*217499.5/437681.4 if anio == 2018 & trimestre == 1
	replace monto_f = monto*11524.0/437681.4 if anio == 2018 & trimestre == 1
	replace monto_s = monto*194651.6/437681.4 if anio == 2018 & trimestre == 1
	replace monto_r = monto*14006.4/437681.4 if anio == 2018 & trimestre == 1

	replace monto_m = monto*(444511.9-217499.5)/(877421.3-437681.4) if anio == 2018 & trimestre == 2
	replace monto_f = monto*(23648.2-11524.0)/(877421.3-437681.4) if anio == 2018 & trimestre == 2
	replace monto_s = monto*(382732.0-194651.6)/(877421.3-437681.4) if anio == 2018 & trimestre == 2
	replace monto_r = monto*(26529.3-14006.4)/(877421.3-437681.4) if anio == 2018 & trimestre == 2

	replace monto_m = monto*(627129.8-444511.9)/(1257525.4-877421.3) if anio == 2018 & trimestre == 3
	replace monto_f = monto*(33176.6-23648.2)/(1257525.4-877421.3) if anio == 2018 & trimestre == 3
	replace monto_s = monto*(558673.2-382732.0)/(1257525.4-877421.3) if anio == 2018 & trimestre == 3
	replace monto_r = monto*(38545.9-26529.3)/(1257525.4-877421.3) if anio == 2018 & trimestre == 3

	replace monto_m = monto*(809833.5-627129.8)/(1664949.1-1257525.4) if anio == 2018 & trimestre == 4
	replace monto_f = monto*(43683.5-33176.6)/(1664949.1-1257525.4) if anio == 2018 & trimestre == 4
	replace monto_s = monto*(760552.9-558673.2)/(1664949.1-1257525.4) if anio == 2018 & trimestre == 4
	replace monto_r = monto*(50879.3-38545.9)/(1664949.1-1257525.4) if anio == 2018 & trimestre == 4

	* 2019+ *
	replace monto_m = monto*(809833.5-627129.8)/(1664949.1-1257525.4) if anio > 2018
	replace monto_f = monto*(43683.5-33176.6)/(1664949.1-1257525.4) if anio > 2018
	replace monto_s = monto*(760552.9-558673.2)/(1664949.1-1257525.4) if anio > 2018
	replace monto_r = monto*(50879.3-38545.9)/(1664949.1-1257525.4) if anio > 2018

	
	/* 2019+ *
	forvalues k=2019(1)`aniovp' {
		forvalues j=1(1)4 {

			if `j' == 1 {
				local trimt = "it"
			}
			if `j' == 2 {
				local trimt = "iit"
			}
			if `j' == 3 {
				local trimt = "iiit"
			}
			if `j' == 4 {
				local trimt = "ivt"
			}

			preserve
			capture import excel "https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/congreso/infotrim/`k'/`trimt'/04afp/itanfp02_`k'0`j'.xlsx", ///
				sheet("I.II RecGobFed a) ISR") cellrange(B18:C22) clear
			if _rc == 0 {
				local t`k'`j' = C in 1
				local m`k'`j' = C in 2
				local f`k'`j' = C in 3
				local r`k'`j' = C in 4
				local s`k'`j' = C in 5
			}
			restore

			if _rc == 0 {
				if `j' > 1 {
					replace monto_m = monto*(`m`k'`j''-`m`k'`=`j'-1'')/(`t`k'`j''-`t`k'`=`j'-1'') if anio >= `k' & trimestre >= `j'
					replace monto_f = monto*(`f`k'`j''-`f`k'`=`j'-1'')/(`t`k'`j''-`t`k'`=`j'-1'') if anio >= `k' & trimestre >= `j'
					replace monto_r = monto*(`r`k'`j''-`r`k'`=`j'-1'')/(`t`k'`j''-`t`k'`=`j'-1'') if anio >= `k' & trimestre >= `j'
					replace monto_s = monto*(`s`k'`j''-`s`k'`=`j'-1'')/(`t`k'`j''-`t`k'`=`j'-1'') if anio >= `k' & trimestre >= `j'
				}
				else {
					replace monto_m = monto*(`m`k'`j'')/(`t`k'`j'') if anio >= `k' & trimestre >= `j'
					replace monto_f = monto*(`f`k'`j'')/(`t`k'`j'') if anio >= `k' & trimestre >= `j'
					replace monto_r = monto*(`r`k'`j'')/(`t`k'`j'') if anio >= `k' & trimestre >= `j'
					replace monto_s = monto*(`s`k'`j'')/(`t`k'`j'') if anio >= `k' & trimestre >= `j'
				}
			}
		}
	}*/

	* Modulo isr.ado *
	egen double monto_pf = rsum(monto_s monto_f)
	egen double monto_otros = rsum(monto_o monto_r)
	egen double monto_t = rsum(monto_m monto_f monto_s monto_r monto_o)
	egen double monto_PF = rsum(monto_s monto_f monto_o monto_r)

	format monto* %20.0fc
	format nombre %30s
	keep anio* mes monto_* trimestre nombre
	reshape long monto, i(anio* mes trimestre nombre) j(clave_de_concepto) string

	replace nombre = nombre+" (Morales)" if clave_de_concepto == "_m"
	replace nombre = nombre+" (F{c i'}sicas)" if clave_de_concepto == "_f"
	replace nombre = nombre+" (Salarios)" if clave_de_concepto == "_s"
	replace nombre = nombre+" (Ret. Extranjero)" if clave_de_concepto == "_r"
	replace nombre = nombre+" (Otros)" if clave_de_concepto == "_o"
	replace nombre = nombre+" (F{c i'}sicas + Salarios)" if clave_de_concepto == "_pf"
	replace nombre = nombre+" (Otros + Retenciones Extranjero)" if clave_de_concepto == "_otros"

	replace clave_de_concepto = "XNA0120"+clave_de_concepto

	g tipo_de_informacion = "Flujo"

	tempfile isr
	save `isr'



	***************************************
	** 4.2 ISR morales sin ISR petrolero **
	use if clave_de_concepto == "XOA0825" using `datosabiertos', clear
	rename monto monto_isrpet
	tempfile isrpet
	save `isrpet'

	use if clave == "XNA0120_m" using `isr', clear
	merge 1:1 (anio mes) using `isrpet', nogen

	replace monto_isrpet = 0 if monto_isrpet == .
	replace monto = monto - monto_isrpet
	drop monto_isrpet

	replace clave_de_concepto = "XNA0120_nopet"
	replace nombre = "Impuesto Sobre la Renta (Morales, no petroleros)"

	tempfile isrpmnopet
	save `isrpmnopet'


	***********************************
	** 4.3 Derechos petroleros y FMP **
	use if clave_de_concepto == "XOA0806" | clave_de_concepto == "XAB2123" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g nombre = "Derechos a los hidrocarburos // FMP"
	g clave_de_concepto = "FMP_Derechos"
	g tipo_de_informacion = "Flujo"

	tempfile fmp
	save `fmp'


	*************************************************
	** 4.4 Deficit Empresas Productivas del Estado **
	use if clave_de_concepto == "XAA1210" | clave_de_concepto == "XOA0101" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	replace monto = -monto
	g clave_de_concepto = "deficit_epe"
	g nombre = "Balance presupuestario de las Empresas Productivas del Estado"
	g tipo_de_informacion = "Flujo"

	tempfile deficit_epe
	save `deficit_epe'


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
	save `deficit_oye'


	***************************************************
	** 4.6 Diferencias con fuentes de financiamiento **
	use if clave_de_concepto == "XOA0108" using `datosabiertos', clear

	replace monto = -monto
	replace clave_de_concepto = "XOA0108_2"
	replace tipo_de_informacion = "Flujo"

	tempfile diferencias
	save `diferencias'


	****************************
	** 4.7 Gasto federalizado **
	use if clave_de_concepto == "XAC2800" | clave_de_concepto == "XAC3300" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g clave_de_concepto = "XACGF00"
	g nombre = "Gasto Federalizado"
	g tipo_de_informacion = "Flujo"

	tempfile gastofed
	save `gastofed'




	*****************
	*** 5 Guardar ***
	*****************
	use `datosabiertos', clear
	append using `isr'
	append using `fmp'
	append using `isrpmnopet'
	append using `deficit_epe'
	append using `deficit_oye'
	append using `diferencias'
	append using `gastofed'

	*drop if monto == .
	*drop tema subtema sector ambito base unidad periodo* frecuencia
	replace nombre = subinstr(nombre,"  "," ",.)
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/DatosAbiertos.dta", replace	
	}
	noisily LIF, update
	noisily SHRFSP, update

end
