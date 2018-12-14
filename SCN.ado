***************************************
**** Sistema de Cuentas Nacionales ****
***************************************
program define SCN, return
quietly {

	syntax [, ANIO(int $anioVP) Graphs]
	noisily di _newline(5) in g "{bf:INFORMACI{c O'}N ECON{c O'}MICA:" in y " SCN " `anio' "}"





	*****************************************************
	*** 1. Databases (D) and variable definitions (V) ***
	*****************************************************
	** D.1. Cuenta de generaci{c o'}n del ingreso **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/Cuenta de Generacion del Ingreso.xlsx", clear
	LimpiaBIE g
	tempfile generacion
	save `generacion'


	** D.2. Cuenta por sectores institucionales **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/Cuentas por Sectores Institucionales.xlsx", clear
	LimpiaBIE s
	tempfile sectores
	save `sectores'


	** D.3. Cuenta de ingreso nacional disponbile **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/Cuenta del ingreso nacional disponible.xlsx", clear
	LimpiaBIE d
	tempfile disponible
	save `disponible'


	** D.4. Cuenta de consumo **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/Consumo de los hogares.xlsx", clear
	LimpiaBIE c
	tempfile consumo
	save `consumo'


	** D.5. Cuenta de consumo privado **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/Gasto de consumo privado.xlsx", clear
	LimpiaBIE gc
	tempfile gasto
	save `gasto'


	** D.6. Cuenta de consumo de gobierno **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/Gasto de consumo de gobierno general.xlsx", clear
	LimpiaBIE cg
	tempfile gobierno
	save `gobierno'


	** D.7. PIB actividad economica **
	import excel "`c(sysdir_personal)'../basesCIEP/INEGI/SCN/Cuentas/PIB actividad economica.xlsx", clear
	LimpiaBIE ae
	tempfile actividad
	save `actividad'


	** D.8. PIBDeflactor **
	PIBDeflactor
	rename anio A
	tempfile basepib
	save `basepib'



	**************************
	** 1.1. Merge databases **
	use `generacion', clear
	merge 1:1 (A) using `sectores', nogen
	merge 1:1 (A) using `disponible', nogen
	merge 1:1 (A) using `consumo', nogen
	merge 1:1 (A) using `gasto', nogen
	merge 1:1 (A) using `gobierno', nogen
	merge 1:1 (A) using `actividad', nogen
	merge 1:1 (A) using `basepib', nogen



	*******************************
	** 1.2. Rename variables (V) **
	** V.1. Anio **
	rename A anio							// Anio
	tsset anio


	** V.2. PIB **
	rename Hs PIB							// Producto Interno Bruto


	** V.3. Remuneraciones a asalariados **
	rename Bg RemSalSS						// Remuneraciones a asalariados (total)
	rename Cg RemSal						// Remuneraciones a asalariados (sin contribuciones, con contribuciones imputadas)
	rename Dg SSEmpleadores						// Contribuciones a la seguridad social, efectivas


	** V.4. Impuesto sobre los productos, producci{c o'}n e importaciones **
	rename Eg Imp							// Impuesto sobre los productos, producci{c o'}n e importaciones (total)
	rename Fg ImpProductos						// Impuestos sobre los productos
	rename Jg ImpProduccion						// Impuestos sobre la producci{c o'}n e importaciones


	** V.5. Subsidios **
	rename Kg Sub							// Subsidios (total)


	** V.6. Excedente bruto de operaci{c o'}n **
	rename Lg ExBOp							// Excedente bruto de operaci{c o'}n (con mixto)
	rename Us ExBOpSinMix						// Excedente bruto de operaci{c o'}n (sin mixto)


	** V.7. Excedente bruto de operaci{c o'}n, por sectores institucionales ** 
	rename Vs ExBOpNoFin						// Excedente bruto de operaci{c o'}n sociedades no financieras
	rename Ws ExBOpFin						// Excedente bruto de operaci{c o'}n sociedades financieras
	rename Zs ExBOpISFLSH						// Excedente bruto de operaci{c o'}n ISFLSH
	rename Ys ExBOpHog						// Excedente bruto de operaci{c o'}n de los hogares
	rename Xs ExBOpGob						// Excedente bruto de operaci{c o'}n del gobierno


	** V.8. Excedente neto de operaci{c o'}n, por sectores institucionales ** 
	rename ABs ExNOpNoFin						// Excedente neto de operaci{c o'}n sociedades no financieras
	rename ACs ExNOpFin						// Excedente neto de operaci{c o'}n sociedades financieras
	rename AFs ExNOpISFLSH						// Excedente neto de operaci{c o'}n ISFLSH
	rename AEs ExNOpHog						// Excedente neto de operaci{c o'}n de los hogares (owner-occupied)
	rename ADs ExNOpGob						// Excedente neto de operaci{c o'}n del gobierno


	** V.9. Consumo de capital fijo **
	rename Dd ConCapFij						// Consumo de capital fijo


	** V.10. Resto del mundo **
	rename Ed PIN							// Producto Interno Neto
	rename Fd ROWRemRecibidas					// ROW, Compensation of Employees, recibidas
	rename Gd ROWRemPagadas						// ROW, Compensation of Employees, pagadas
	rename Hd ROWPropRecibidas					// ROW, Ingresos a la propiedad, recibidas
	rename Id ROWPropPagadas					// ROW, Ingresos a la propiedad, pagadas
	rename Jd ROWTransRecibidas					// ROW, Transferencias corrientes, recibidas
	rename Kd ROWTransPagadas					// ROW, Transferencias corrientes, pagadas


	** V.11. Consumo, usos **
	rename Ld IngNacDisp						// Ingreso nacional disponible
	rename AMs AhorroB						// Ahorro bruto
	rename Bc ConHog						// Consumo de los hogares
	rename Hgc ComprasN						// Compras netas en el extranjero
	rename Bcg ConGob						// Consumo del gobierno general
	rename AGs IngDisp						// Ingreso disponible
	rename HWae Alquileres						// Alquileres sin intermediaci{c o'}n de bienes ra{c i'}ces
	rename HXae Inmobiliarias 					// Inmobiliarias y corredores de bienes ra{c i'}ces
	rename Mc Alojamiento						// Alquieres efectivos de alojamiento de los hogares


	** V.12. Ingreso mixto **
	rename IFae ServProf						// Servicios profesionales, cient{c i'}ficos y t{c e'}cnicos
	rename JNae ConsMedi 						// Consultorios m{c e'}dicos
	rename JOae ConsDent						// Consultorios dentales
	rename JPae ConsOtro						// Consultorios otros
	rename JSae EnfeDomi						// Enfermeras a domicilio



	********************************
	** 1.3. Construir cuentas (C) **
	** C.1. Ingreso mixto **
	g double IngMixto = ExBOp - ExBOpSinMix
	format IngMixto %20.0fc
	label var IngMixto "Ingreso mixto"


	** C.2. Subsidios a los productos, producci{c o'}n e importaciones **
	g double SubProductos = Sub*(-25654.178/-27143.521) if anio == 2003	// Tabulados 2003
	replace SubProductos = Sub*(-31715.148/-33451.335) if anio == 2004	// Tabulados 2004
	replace SubProductos = Sub*(-30435.676/-32400.514) if anio == 2005	// Tabulados 2005
	replace SubProductos = Sub*(-82570.179/-85389.438) if anio == 2006	// Tabulados 2006
	replace SubProductos = Sub*(-86967.492/-90284.464) if anio == 2007	// Tabulados 2007
	replace SubProductos = Sub*(-274075.031/-278027.853) if anio == 2008	// Tabulados 2008
	replace SubProductos = Sub*(-47382.555/-51691.429) if anio == 2009	// Tabulados 2009
	replace SubProductos = Sub*(-120461.693/-124207.239) if anio == 2010	// Tabulados 2010
	replace SubProductos = Sub*(-202175.591/-206734.761) if anio == 2011	// Tabulados 2011
	replace SubProductos = Sub*(-281083.533/-285812.359) if anio == 2012	// Tabulados 2012
	replace SubProductos = Sub*(-173251.387/-178770.61) if anio == 2013	// Tabulados 2013
	replace SubProductos = Sub*(-109267.213/-114961.944) if anio == 2014	// Tabulados 2014
	replace SubProductos = Sub*(-73102.575/-78600.072) if anio == 2015	// Tabulados 2015
	replace SubProductos = Sub*(-40134.053/-47092.044) if anio >= 2016	// Tabulados 2016
	format SubProductos %20.0fc
	label var SubProductos "Subsidios a los productos"

	g double SubProduccion = Sub*(-1489.343/-27143.521) if anio == 2003	// Tabulados 2003
	replace SubProduccion = Sub*(-1736.187/-33451.335) if anio == 2004	// Tabulados 2004
	replace SubProduccion = Sub*(-1964.838/-32400.514) if anio == 2005	// Tabulados 2005
	replace SubProduccion = Sub*(-2819.259/-85389.438) if anio == 2006	// Tabulados 2006
	replace SubProduccion = Sub*(-3316.972/-90284.464) if anio == 2007	// Tabulados 2007
	replace SubProduccion = Sub*(-3952.822/-278027.853) if anio == 2008	// Tabulados 2008
	replace SubProduccion = Sub*(-4308.874/-51691.429) if anio == 2009	// Tabulados 2009
	replace SubProduccion = Sub*(-3745.546/-124207.239) if anio == 2010	// Tabulados 2010
	replace SubProduccion = Sub*(-4559.170/-206734.761) if anio == 2011	// Tabulados 2011
	replace SubProduccion = Sub*(-4728.826/-285812.359) if anio == 2012	// Tabulados 2012
	replace SubProduccion = Sub*(-5519.223/-178770.610) if anio == 2013	// Tabulados 2013
	replace SubProduccion = Sub*(-5694.731/-114961.944) if anio == 2014	// Tabulados 2014
	replace SubProduccion = Sub*(-5497.497/-78600.072) if anio == 2015	// Tabulados 2015
	replace SubProduccion = Sub*(-6957.991/-47092.044) if anio >= 2016	// Tabulados 2016
	format SubProduccion %20.0fc
	label var SubProduccion "Subsidios a la producci{c o'}n e importaciones"


	** C.3. Cuotas a la seguridad social imputada **
	g double SSImputada = 101684.61*1000000 if anio == 2003		// Tabulados 2003
	replace SSImputada = 102797.394*1000000 if anio == 2004		// Tabulados 2004
	replace SSImputada = 99644.504*1000000 if anio == 2005		// Tabulados 2005
	replace SSImputada = 105875.63*1000000 if anio == 2006		// Tabulados 2006
	replace SSImputada = 111062.193*1000000 if anio == 2007		// Tabulados 2007
	replace SSImputada = 114525.964*1000000 if anio == 2008		// Tabulados 2008
	replace SSImputada = 127092.721*1000000 if anio == 2009		// Tabulados 2009
	replace SSImputada = 122322.355*1000000 if anio == 2010		// Tabulados 2010
	replace SSImputada = 134972.515*1000000 if anio == 2011		// Tabulados 2011
	replace SSImputada = 141005.634*1000000 if anio == 2012		// Tabulados 2012
	replace SSImputada = 138455.819*1000000 if anio == 2013		// Tabulados 2013
	replace SSImputada = 141844.904*1000000 if anio == 2014		// Tabulados 2014
	replace SSImputada = 148685.916*1000000 if anio == 2015		// Tabulados 2015
	replace SSImputada = 161032.88*1000000 if anio >= 2016		// Tabulados 2016
	format SSImputada %20.0fc
	label var SSImputada "Contribuciones sociales imputadas"


	** C.4. Depreciaci{c o'}n del ingreso mixto **
	g double DepMix = (83680.639*1000000) if anio == 2003		// Tabulados 2003
	replace DepMix = (94406.627*1000000) if anio == 2004		// Tabulados 2004
	replace DepMix = (101888.33*1000000) if anio == 2005		// Tabulados 2005
	replace DepMix = (112698.23*1000000) if anio == 2006		// Tabulados 2006
	replace DepMix = (122478.52*1000000) if anio == 2007		// Tabulados 2007
	replace DepMix = (137107.287*1000000) if anio == 2008		// Tabulados 2008
	replace DepMix = (145711.922*1000000) if anio == 2009		// Tabulados 2009
	replace DepMix = (156368.145*1000000) if anio == 2010		// Tabulados 2010
	replace DepMix = (170548.474*1000000) if anio == 2011		// Tabulados 2011
	replace DepMix = (183954.287*1000000) if anio == 2012		// Tabulados 2012
	replace DepMix = (191575.471*1000000) if anio == 2013		// Tabulados 2013
	replace DepMix = (197510.467*1000000) if anio == 2014		// Tabulados 2014
	replace DepMix = (217922.3*1000000) if anio == 2015		// Tabulados 2015
	replace DepMix = (245925.726*1000000) if anio >= 2016		// Tabulados 2016
	format DepMix %20.0fc
	label var DepMix "Depreciaci{c o'}n del ingreso mixto"



	******************************
	** 1.4. Forecast & Pastcast **
	order indiceY-productivity, last
	foreach k of varlist RemSalSS-DepMix {
		replace `k' = L.`k'*(1+var_pibY/100)*indiceY/L.indiceY if `k' == .
		forvalues j = 2002(-1)1993 {
			replace `k' = F.`k'/(1+var_pibY/100)/(indiceY/L.indiceY) if anio == `j'
		}
	}


	** C.5. Impuestos Netos **
	g double ImpNetProductos = ImpProductos - SubProductos
	format ImpNetProductos %20.0fc
	label var ImpNetProductos "Impuestos netos a los productos"

	g double ImpNetProduccion = ImpProduccion - SubProduccion
	format ImpNetProduccion %20.0fc
	label var ImpNetProduccion "Impuestos netos a la producci{c o'}n e importaciones"

	g double ImpNet = Imp - Sub
	format ImpNet %20.0fc
	label var ImpNet "Impuestos sobre los productos, producci{c o'}n e importaciones"

	** Ajustes Remuneraciones a asalariados y Seguridad Social **
	replace RemSal = RemSal - SSImputada

	** Validaci{c o'}n **
	g double PIBval = RemSalSS + IngMixto + ExBOpSinMix + ImpNetProductos + ImpNetProduccion
	format PIBval %20.0fc
	label var PIBval "PIB (validaci{c o'}n)"


	** C.6. ROW, Compensation of Employees, pagadas **
	replace ROWRemPagadas = PIN + ConCapFij + ROWRemRecibidas + ROWPropRecibidas ///
		- ROWPropPagadas + ROWTransRecibidas - ROWTransPagadas - PIBval
	g double ROWRem = ROWRemRecibidas - ROWRemPagadas
	format ROWRem %20.0fc
	label var ROWRem "Remuneraci{c o'}n de asalariados"


	** C.7. Ingreso mixto (laboral) **
	g double MixL = IngMixto*2/3
	format MixL %20.0fc
	label var MixL "Ingreso mixto (laboral)"


	** C.8. Ingreso mixto (capital) **
	g double MixK = IngMixto*1/3
	format MixK %20.0fc
	label var MixK "Ingreso mixto (capital)"


	** C.9. Resto del Mundo **
	g double ROW = ROWPropPagadas - ROWPropRecibidas


	** C.10. Ingreso de capital **
	g double CapInc = ExBOpSinMix + MixK - ConCapFij //- ROW
	format CapInc %20.0fc
	label var CapInc "Ingreso de capital"



	****************************
	** 1.5. NTA: Adding taxes **
	g double RemSalNTA = RemSal + ImpNetProduccion*RemSal/(RemSal + MixL + CapInc)
	g double MixLNTA = MixL + ImpNetProduccion*MixL/(RemSal + MixL + CapInc)
	g double CapIncNTA = CapInc + ImpNetProduccion*CapInc/(RemSal + MixL + CapInc)



	** C.11. Ingreso laboral bruto **
	g double Yl = RemSalNTA + MixLNTA + SSImputada + SSEmpleadores
	format Yl %20.0fc
	label var Yl "Ingreso laboral"



	** C.12. Depreciation **
	g double DepNoFin = ExBOpNoFin - ExNOpNoFin
	g double DepFin = ExBOpFin - ExNOpFin
	g double DepISFLSH = ExBOpISFLSH - ExNOpISFLSH
	g double DepHog = ExBOpHog - ExNOpHog
	g double DepGob = ExBOpGob - ExNOpGob



	****************************
	** 1.6. NTA: Adding Taxes **
	g double ExBOpSoc = ExBOpISFLSH + ExBOpNoFin + ExBOpFin + MixK

	g double ExBOpNoFinNTA = ExBOpNoFin ///
		+ ImpNetProductos*ExBOpNoFin/ExBOpSoc ///
		+ ImpNetProduccion*ExBOpNoFin/ExBOpSoc*CapInc/(RemSal + MixL + CapInc) 
	g double ExBOpFinNTA = ExBOpFin ///
		+ ImpNetProductos*ExBOpFin/ExBOpSoc ///
		+ ImpNetProduccion*ExBOpFin/ExBOpSoc*CapInc/(RemSal + MixL + CapInc)
	g double ExBOpISFLSHNTA = ExBOpISFLSH ///
		+ ImpNetProductos*ExBOpISFLSH/ExBOpSoc ///
		+ ImpNetProduccion*ExBOpISFLSH/ExBOpSoc*CapInc/(RemSal + MixL + CapInc)
	g double MixKNTA = MixK ///
		+ ImpNetProductos*MixK/ExBOpSoc ///
		+ ImpNetProduccion*MixK/ExBOpSoc*CapInc/(RemSal + MixL + CapInc)

	g double ExBOpSocNTA = ExBOpNoFinNTA + ExBOpFinNTA + ExBOpISFLSHNTA + MixKNTA
	label var ExBOpSocNTA "Sociedades e ISFLSH (NTA)"



	** C.13. Ingreso de capita neto **
	g double ExNOpSoc = ExBOpNoFin - DepNoFin + ExBOpFin - DepFin + ExBOpISFLSH - DepISFLSH - ROW
	format ExNOpSoc %20.0fc
	label var ExNOpSoc "Sociedades e ISFLSH"

	g double ExNOpSocNTA = ExBOpNoFinNTA - DepNoFin + ExBOpFinNTA - DepFin + ExBOpISFLSHNTA - DepISFLSH - ROW
	format ExNOpSocNTA %20.0fc
	label var ExNOpSocNTA "Sociedades e ISFLSH (NTA)"

	g double MixKN = MixK - DepMix
	format MixKN %20.0fc
	label var MixKN "Ingreso mixto neto (capital)"

	g double MixKNNTA = MixKNTA - DepMix
	format MixKNNTA %20.0fc
	label var MixKNNTA "Ingreso mixto neto (capital) (NTA)"



	****************************
	** 1.7. Final adjustments **
	g double Capital = ExNOpSoc + ExNOpHog + ExNOpGob + MixKN
	format Capital %20.0fc
	label var Capital "Ingreso de capital"

	g double CapitalNTA = ExNOpSocNTA + ExNOpHog + ExNOpGob + MixKNNTA
	format CapitalNTA %20.0fc
	label var CapitalNTA "Ingreso de capital (NTA)"

	replace IngMixto = MixK + MixL

	g double IngNac = Yl + CapitalNTA
	format IngNac %20.0fc
	label var IngNac "Ingreso nacional"

	g double ROWTrans = IngNacDisp - IngNac - ROWRem
	format ROWTrans %20.0fc

	g double AhorroN = AhorroB - ConCapFij
	format AhorroN %20.0fc

	g double CGob = IngNacDisp - ConHog - AhorroN - ComprasN
	format CGob %20.0fc

	g double DifGob = CGob - ConGob
	format DifGob %20.0fc

	drop if RemSalSS == .





	*************************
	*** 2. Resultados (R) ***
	*************************
	** R.1. Observacion **
	forvalues k = 1(1)`=_N' {
		if anio[`k'] == `anio' {
			local obs = `k'
			continue, break
		}
	}



	** R.2. Display (ingresos) **
	noisily di _newline in g "{bf: A. Cuenta: " in y "generaci{c o'}n del ingreso" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Remuneraci{c o'}n de asalariados" ///
		_col(44) in y %20.0fc RemSal[`obs'] ///
		_col(66) in y %7.3fc RemSal[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Contribuciones sociales" ///
		_col(44) in y %20.0fc SSEmpleadores[`obs']+SSImputada[`obs'] ///
		_col(66) in y %7.3fc (SSEmpleadores[`obs']+SSImputada[`obs'])/PIB[`obs']*100
	noisily di in g "  (+) Ingreso mixto (laboral)" ///
		_col(44) in y %20.0fc MixL[`obs']  ///
		_col(66) in y %7.3fc MixL[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Impuestos a la producci{c o'}n (laboral)" ///
		_col(44) in y %20.0fc ImpNetProduccion[`obs']*(RemSal[`obs'] + MixL[`obs'])/(RemSal[`obs'] + MixL[`obs'] + CapInc[`obs'])  ///
		_col(66) in y %7.3fc ImpNetProduccion[`obs']*(RemSal[`obs'] + MixL[`obs'])/(RemSal[`obs'] + MixL[`obs'] + CapInc[`obs'])/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso laboral" ///
		_col(44) in y %20.0fc Yl[`obs'] ///
		_col(66) in y %7.3fc Yl[`obs']/PIB[`obs']*100 "}"

	noisily di in g "  (+) Ingreso de capital (neto)" ///
		_col(44) in y %20.0fc Capital[`obs'] ///
		_col(66) in y %7.3fc Capital[`obs'] /PIB[`obs']*100
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc ImpNetProductos[`obs'] ///
		_col(66) in y %7.3fc ImpNetProductos[`obs'] /PIB[`obs']*100
	noisily di in g "  (+) Impuestos a la producci{c o'}n (capital)" ///
		_col(44) in y %20.0fc ImpNetProduccion[`obs']*CapInc[`obs']/(RemSal[`obs'] + MixL[`obs'] + CapInc[`obs']) ///
		_col(66) in y %7.3fc ImpNetProduccion[`obs']*CapInc[`obs']/(RemSal[`obs'] + MixL[`obs'] + CapInc[`obs'])/PIB[`obs']*100

	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso nacional" ///
		_col(44) in y %20.0fc IngNac[`obs'] ///
		_col(66) in y %7.3fc IngNac[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Ingreso a la propiedad (ROW)" ///
		_col(44) in y %20.0fc ROW[`obs'] ///
		_col(66) in y %7.3fc ROW[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Neto" ///
		_col(44) in y %20.0fc PIN[`obs'] ///
		_col(66) in y %7.3fc PIN[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Consumo de capital fijo" ///
		_col(44) in y %20.0fc ConCapFij[`obs'] ///
		_col(66) in y %7.3fc ConCapFij[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Bruto" ///
		_col(44) in y %20.0fc PIB[`obs'] ///
		_col(66) in y %7.3fc PIB[`obs']/PIB[`obs']*100 "}"


	noisily di _newline in g "{bf: B. Cuenta: " in y "capital (neto)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Sociedades e ISFLSH" ///
		_col(44) in y %20.0fc ExNOpSoc[`obs'] ///
		_col(66) in y %7.3fc ExNOpSoc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ingreso mixto (capital)" ///
		_col(44) in y %20.0fc MixKN[`obs'] ///
		_col(66) in y %7.3fc MixKN[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Alquiler imputado" ///
		_col(44) in y %20.0fc ExNOpHog[`obs'] ///
		_col(66) in y %7.3fc ExNOpHog[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Gobierno" ///
		_col(44) in y %20.0fc ExNOpGob[`obs'] ///
		_col(66) in y %7.3fc ExNOpGob[`obs']
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso de capital (neto): " ///
		_col(44) in y %20.0fc Capital[`obs'] ///
		_col(66) in y %7.3fc Capital[`obs']/PIB[`obs']*100 "}"

	g double PIBval2 = RemSalSS + MixL + ExNOpSoc + MixKN + ExNOpGob + ExNOpHog + ConCapFij + ROW
	format PIBval2 %20.0fc



	** R.3. Returns ***
	return scalar RemSal = RemSal[`obs']
	return scalar SSEmpleadores = SSEmpleadores[`obs']
	return scalar MixL = MixL[`obs']
	return scalar SSImputada = SSImputada[`obs']
	
	return scalar Yl = Yl[`obs']
	return scalar Capital = Capital[`obs']
	
	return scalar IngNac = IngNac[`obs']
	return scalar ConCapFij = ConCapFij[`obs']
	return scalar ROW = ROW[`obs']
	
	return scalar PIB = PIB[`obs']
	
	return scalar ExNOpSoc = ExNOpSoc[`obs']
	return scalar MixKN = MixKN[`obs']
	return scalar ExNOpGob = ExNOpGob[`obs']
	return scalar ExNOpHog = ExNOpHog[`obs']

	return scalar ExBOpHog = ExBOpHog[`obs']

	return scalar MixK = MixK[`obs']
	
	return scalar ExNOpSocNTA = ExNOpSocNTA[`obs']
	
	return scalar RemSalNTA = RemSalNTA[`obs']
	return scalar MixLNTA = MixLNTA[`obs']
	
	return scalar CapitalNTA = CapitalNTA[`obs']
	
	return scalar MixKNNTA = MixKNNTA[`obs']
	
	return scalar ServProf = ServProf[`obs']
	return scalar ConsMedi = ConsMedi[`obs']
	return scalar ConsDent = ConsDent[`obs']
	return scalar ConsOtro = ConsOtro[`obs']
	return scalar EnfeDomi = EnfeDomi[`obs']

	return scalar Alojamiento = Alojamiento[`obs']



	** R.4. Graph **
	if "$graphs" == "on" | "`graphs'" == "graphs" {
		tempvar Rem RemImpMix RemImpMixEx RemImpMixExRow RemImpMixExRowCon
		g `Rem' = (RemSalNTA + SSEmpleadores + SSImputada)/1000000
		label var `Rem' "Remuneraci{c o'}n de asalariados"
		g `RemImpMix' = (RemSalNTA + SSEmpleadores + SSImputada + MixLNTA + MixKNTA)/1000000
		label var `RemImpMix' "Ingreso mixto"
		g `RemImpMixEx' = (RemSalNTA + SSEmpleadores + SSImputada + MixLNTA + CapitalNTA)/1000000
		label var `RemImpMixEx' "Excedente bruto de operaci{c o'}n"
		g `RemImpMixExRow' = (RemSalNTA + SSEmpleadores + SSImputada + MixLNTA + CapitalNTA + ROW)/1000000
		label var `RemImpMixExRow' "Resto del mundo"
		g `RemImpMixExRowCon' = (RemSalNTA + SSEmpleadores + SSImputada + MixLNTA + CapitalNTA + ROW + ConCapFij)/1000000
		label var `RemImpMixExRowCon' "Consumo de capital fijo"

		twoway area `RemImpMixExRowCon' `RemImpMixExRow' `RemImpMixEx' `RemImpMix' `Rem' anio if anio <= `anio', ///
			title("{bf:Producto Interno Bruto}") ///
			subtitle(Cuenta de Generaci{c o'}n del Ingreso) ///			
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n del INEGI, BIE.}") ///
			note("{bf:Notas:} Impuestos netos de subsidios. Excedente bruto de operaci{c o'}n sin ingreso mixto.") ///
			xtitle("") ///
			ylabel(, format(%20.0fc)) ytitle(millones MXN, height(8)) ///
			name(gdp, replace)
		

		tempvar RemPIB MixPIB ExBOpSinMixPIB RowPIB ConFijPIB
		g `RemPIB' = (RemSalNTA + SSEmpleadores + SSImputada)/PIB*100
		label var `RemPIB' "Remuneraci{c o'}n de asalariados"
		g `MixPIB' = (MixLNTA + MixKNNTA)/PIB*100
		label var `MixPIB' "Ingreso mixto"
		g `ExBOpSinMixPIB' = (CapitalNTA - MixKNNTA)/PIB*100
		label var `ExBOpSinMixPIB' "Excedente bruto de operaci{c o'}n"
		g `RowPIB' = ROW/PIB*100
		label var `RowPIB' "Resto del mundo"
		g `ConFijPIB' = ConCapFij/PIB*100
		label var `ConFijPIB' "Consumo de capital fijo"
		
		graph bar `ConFijPIB' `RowPIB' `ExBOpSinMixPIB' `MixPIB' `RemPIB' if anio <= `anio', ///
			over(anio) stack asyvars ///
			title("{bf:Producto Interno Bruto}") ///
			subtitle(Cuenta de Generaci{c o'}n del Ingreso) ///
			ytitle(% PIB) ///
			note("{bf:Notas:} Impuestos netos de subsidios. Excedente bruto de operaci{c o'}n sin ingreso mixto.") ///
			legend( ///
			label(5 "Remuneraci{c o'}n de asalariados") ///
			label(2 "Resto del mundo") ///
			label(4 "Ingreso mixto") ///
			label(3 "Excedente bruto de operaci{c o'}n") ///
			label(1 "Consumo de capital fijo") ) ///
			blabel(bar, format(%7.1fc)) ///
			name(gdpbar, replace)
	}



	** R.5 Display (consumo) ***
	noisily di _newline in g "{bf: C. Cuenta: " in y "consumo (recursos)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Ingreso nacional" ///
		_col(44) in y %20.0fc IngNac[`obs'] ///
		_col(66) in y %7.3fc IngNac[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Remuneraci{c o'}n a asalaraidos (ROW)" ///
		_col(44) in y %20.0fc ROWRem[`obs'] ///
		_col(66) in y %7.3fc ROWRem[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Transferencias corrientes (ROW)" ///
		_col(44) in y %20.0fc ROWTrans[`obs'] ///
		_col(66) in y %7.3fc ROWTrans[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso nacional disponible" ///
		_col(44) in y %20.0fc IngNacDisp[`obs'] ///
		_col(66) in y %7.3fc IngNacDisp[`obs']/PIB[`obs']*100 "}"

	noisily di _newline in g "{bf: D. Cuenta: " in y "consumo (usos, sect. inst.)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Hogares e ISFLSH" ///
		_col(44) in y %20.0fc ConHog[`obs'] ///
		_col(66) in y %7.3fc ConHog[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Gobierno" ///
		_col(44) in y %20.0fc ConGob[`obs'] ///
		_col(66) in y %7.3fc ConGob[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Consumo fuera del pa{c i'}s" ///
		_col(44) in y %20.0fc ComprasN[`obs'] ///
		_col(66) in y %7.3fc ComprasN[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ahorro neto" ///
		_col(44) in y %20.0fc AhorroN[`obs'] ///
		_col(66) in y %7.3fc AhorroN[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso disponible" ///
		_col(44) in y %20.0fc IngDisp[`obs'] ///
		_col(66) in y %7.3fc IngDisp[`obs']/PIB[`obs']*100 "}"

	noisily di _newline in g "{bf: E. Cuenta: " in y "consumo (usos)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Alimentos" ///
		_col(44) in y %20.0fc Dc[`obs'] ///
		_col(66) in y %7.3fc Dc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Bebidas no alcoh{c o'}licas" ///
		_col(44) in y %20.0fc Ec[`obs'] ///
		_col(66) in y %7.3fc Ec[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Bebidas alcoh{c o'}licas" ///
		_col(44) in y %20.0fc Gc[`obs'] ///
		_col(66) in y %7.3fc Gc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Tabaco" ///
		_col(44) in y %20.0fc Hc[`obs'] ///
		_col(66) in y %7.3fc Hc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Prendas de vestir" ///
		_col(44) in y %20.0fc Jc[`obs'] ///
		_col(66) in y %7.3fc Jc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Calzado" ///
		_col(44) in y %20.0fc Kc[`obs'] ///
		_col(66) in y %7.3fc Kc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Vivienda" ///
		_col(44) in y %20.0fc Mc[`obs']+Nc[`obs'] ///
		_col(66) in y %7.3fc (Mc[`obs']+Nc[`obs'])/PIB[`obs']*100
	noisily di in g "  (+) Agua y servicios diversos" ///
		_col(44) in y %20.0fc Oc[`obs'] ///
		_col(66) in y %7.3fc Oc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Electricidad, gas, otros combustibles" ///
		_col(44) in y %20.0fc Pc[`obs'] ///
		_col(66) in y %7.3fc Pc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Art{c i'}culos para el hogar" ///
		_col(44) in y %20.0fc Qc[`obs'] ///
		_col(66) in y %7.3fc Qc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Salud" ///
		_col(44) in y %20.0fc Xc[`obs'] ///
		_col(66) in y %7.3fc Xc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Adquisici{c o'}n de veh{c i'}culos" ///
		_col(44) in y %20.0fc ACc[`obs'] ///
		_col(66) in y %7.3fc ACc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Funcionamiento de transporte" ///
		_col(44) in y %20.0fc ADc[`obs'] ///
		_col(66) in y %7.3fc ADc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de transporte" ///
		_col(44) in y %20.0fc AEc[`obs'] ///
		_col(66) in y %7.3fc AEc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comunicaciones" ///
		_col(44) in y %20.0fc AFc[`obs'] ///
		_col(66) in y %7.3fc AFc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Recreaci{c o'}n y cultura" ///
		_col(44) in y %20.0fc AJc[`obs'] ///
		_col(66) in y %7.3fc AJc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Educaci{c o'}n" ///
		_col(44) in y %20.0fc AQc[`obs'] ///
		_col(66) in y %7.3fc AQc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Restaurantes y hoteles" ///
		_col(44) in y %20.0fc AWc[`obs'] ///
		_col(66) in y %7.3fc AWc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Bienes y servicios diversos" ///
		_col(44) in y %20.0fc AZc[`obs'] ///
		_col(66) in y %7.3fc AZc[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Hogares e ISFLSH" ///
		_col(44) in y %20.0fc ConHog[`obs'] ///
		_col(66) in y %7.3fc ConHog[`obs']/PIB[`obs']*100 "}"

	noisily di _newline in g "{bf: F. Cuenta: " in y "Actividad Econ{c o'}mica" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Agricultura, cr{c i'}a, etc." ///
		_col(44) in y %20.0fc Eae[`obs'] ///
		_col(66) in y %7.3fc Eae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Miner{c i'}a" ///
		_col(44) in y %20.0fc ADae[`obs'] ///
		_col(66) in y %7.3fc ADae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Generaci{c o'}n, ... energ{c i'}a el{c e'}ctrica" ///
		_col(44) in y %20.0fc AKae[`obs'] ///
		_col(66) in y %7.3fc AKae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Construcci{c o'}n" ///
		_col(44) in y %20.0fc APae[`obs'] ///
		_col(66) in y %7.3fc APae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Industrias manufactureras" ///
		_col(44) in y %20.0fc BDae[`obs'] ///
		_col(66) in y %7.3fc BDae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comercio al por mayor" ///
		_col(44) in y %20.0fc FFae[`obs'] ///
		_col(66) in y %7.3fc FFae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comercio al por menor" ///
		_col(44) in y %20.0fc FGae[`obs'] ///
		_col(66) in y %7.3fc FGae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Transportes, correos y almacen..." ///
		_col(44) in y %20.0fc FHae[`obs'] ///
		_col(66) in y %7.3fc FHae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Información en medios masivos" ///
		_col(44) in y %20.0fc GOae[`obs'] ///
		_col(66) in y %7.3fc GOae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios financieros y de seguridad" ///
		_col(44) in y %20.0fc HFae[`obs'] ///
		_col(66) in y %7.3fc HFae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios inmobiliarios..." ///
		_col(44) in y %20.0fc HUae[`obs'] ///
		_col(66) in y %7.3fc HUae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios profesionales..." ///
		_col(44) in y %20.0fc ServProf[`obs'] ///
		_col(66) in y %7.3fc ServProf[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Dirección de corporativos y empresas" ///
		_col(44) in y %20.0fc IQae[`obs'] ///
		_col(66) in y %7.3fc IQae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de apoyo a los negocios..." ///
		_col(44) in y %20.0fc IRae[`obs'] ///
		_col(66) in y %7.3fc IRae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios educativos" ///
		_col(44) in y %20.0fc JCae[`obs'] ///
		_col(66) in y %7.3fc JCae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de salud y de asistencia..." ///
		_col(44) in y %20.0fc JLae[`obs'] ///
		_col(66) in y %7.3fc JLae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de espar. culturales..." ///
		_col(44) in y %20.0fc KIae[`obs'] ///
		_col(66) in y %7.3fc KIae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de alojamiento temporal..." ///
		_col(44) in y %20.0fc KUae[`obs'] ///
		_col(66) in y %7.3fc KUae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Otros servicios excepto gobierno" ///
		_col(44) in y %20.0fc LDae[`obs'] ///
		_col(66) in y %7.3fc LDae[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Actividades de gobierno..." ///
		_col(44) in y %20.0fc LTae[`obs'] ///
		_col(66) in y %7.3fc LTae[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Valor Agregado Bruto" ///
		_col(44) in y %20.0fc Dae[`obs'] ///
		_col(66) in y %7.3fc Dae[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc ImpNetProductos[`obs'] ///
		_col(66) in y %7.3fc ImpNetProductos[`obs'] /PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Bruto" ///
		_col(44) in y %20.0fc PIB[`obs'] ///
		_col(66) in y %7.3fc PIB[`obs']/PIB[`obs']*100 "}"



	** R.6. Return (consumo) **
	return scalar ROWRem = ROWRem[`obs']
	return scalar ROWTrans = ROWTrans[`obs']
	return scalar Hogares_e_ISFLSH = ConHog[`obs']

	return scalar Alimentos = Dc[`obs']
	return scalar Bebidas_no_alcoholicas = Ec[`obs']
	return scalar Bebidas_alcoholicas = Gc[`obs']
	return scalar Tabaco = Hc[`obs']
	return scalar Prendas_de_vestir = Jc[`obs']
	return scalar Calzado = Kc[`obs']
	return scalar Vivienda = Mc[`obs']+Oc[`obs']
	return scalar Agua = Pc[`obs']
	return scalar Electricidad = Qc[`obs']
	return scalar Articulos_para_el_hogar = Rc[`obs']
	return scalar Salud = Yc[`obs']
	return scalar Adquisicion_de_vehiculos = ADc[`obs']
	return scalar Funcionamiento_de_transporte = AEc[`obs']
	return scalar Servicios_de_transporte = AFc[`obs']
	return scalar Comunicaciones = AGc[`obs']
	return scalar Recreacion_y_cultura = AKc[`obs']
	return scalar Educacion = ARc[`obs']
	return scalar Restaurantes_y_hoteles = AXc[`obs']
	return scalar Bienes_y_servicios_diversos = BAc[`obs']
	
	return scalar Alquileres = Alquileres[`obs']
	return scalar Inmobiliarias = Inmobiliarias[`obs']
	return scalar ConGob = ConGob[`obs']
	return scalar ComprasN = ComprasN[`obs']
}
end
