*!*******************************************
*!***                                    ****
*!***    Sistema de Cuentas Nacionales   ****
*!***    BIE/INEGI                       ****
*!***    Autor: Ricardo                  ****
*!***    Fecha: 17/Oct/22                ****
*!***                                    ****
*!*******************************************
program define SCN, return
quietly {
	timer on 3

	capture mkdir `"`c(sysdir_personal)'/SIM/"'
	capture mkdir `"`c(sysdir_personal)'/SIM/graphs/"'

	** 0.2 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)	
	}

	capture use in 1 using "`c(sysdir_personal)'/SIM/SCN.dta", clear
	syntax [if] [, ANIO(int `aniovp') NOGraphs UPDATE]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Econom{c i'}a:" in y " SCN `anio'   }" in g _dup(20) "." _newline



	*****************************************************
	*** 1. Databases (D) and variable definitions (V) ***
	*****************************************************
	capture confirm file "`c(sysdir_personal)'/SIM/SCN.dta"
	if _rc != 0 | "`update'" == "update" {

		noisily di in g "  Updating SCN.dta..." _newline

		** D.1. Cuenta de generaci{c o'}n del ingreso **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Cuenta de generacion del ingreso.xlsx", clear
		LimpiaBIE g
		tempfile generacion
		save `generacion'

		** D.2. Cuenta por sectores institucionales **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Cuentas por sectores institucionales.xlsx", clear
		LimpiaBIE s
		tempfile sectores
		save `sectores'

		** D.3. Cuenta de ingreso nacional disponbile **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Cuenta del ingreso nacional disponible.xlsx", clear
		LimpiaBIE d
		tempfile disponible
		save `disponible'

		** D.4. Cuenta de consumo **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Consumo de los hogares.xlsx", clear
		LimpiaBIE c
		tempfile consumo
		save `consumo'

		** D.5. Cuenta de consumo privado **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Gasto de consumo privado.xlsx", clear
		LimpiaBIE gc
		tempfile gasto
		save `gasto'

		** D.6. Cuenta de consumo de gobierno **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Gasto de consumo de gobierno general.xlsx", clear
		LimpiaBIE cg
		tempfile gobierno
		save `gobierno'

		** D.7. PIB actividad economica **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/PIB actividad economica.xlsx", clear
		LimpiaBIE ae
		tempfile actividad
		save `actividad'

		** D.8. Cuenta de consumo privado por actividad economica **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Gasto de consumo privado por actividad economica.xlsx", clear
		LimpiaBIE cp
		tempfile consumoprivado
		save `consumoprivado'

		** D.9. Cuenta de produccion **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Produccion bruta.xlsx", clear
		LimpiaBIE pb
		tempfile produccion
		save `produccion'

		** D.9. Cuenta de produccion **
		import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/sector externo.xlsx", clear
		LimpiaBIE ex
		tempfile sectorexterno
		save `sectorexterno'

		** Merge bases **
		use `generacion', clear
		merge 1:1 (A) using `sectores', nogen
		merge 1:1 (A) using `disponible', nogen
		merge 1:1 (A) using `consumo', nogen
		merge 1:1 (A) using `gasto', nogen
		merge 1:1 (A) using `gobierno', nogen
		merge 1:1 (A) using `actividad', nogen
		merge 1:1 (A) using `consumoprivado', nogen
		merge 1:1 (A) using `produccion', nogen
		merge 1:1 (A) using `sectorexterno', nogen


		*******************************
		** 1.2. Rename variables (V) **
		** V.1. Anio **
		rename A anio				// Anio
		tsset anio

		** V.2. PIB **
		rename Mg PIB				// Producto Interno Bruto

		** V.3. Remuneraciones a asalariados **
		rename Bg RemSalSS			// Remuneraciones a asalariados (total)
		rename Cg RemSal			// Remuneraciones a asalariados (sin contribuciones efectivas, con contribuciones imputadas)
		rename Dg SSEmpleadores		// Contribuciones a la seguridad social, efectivas

		** V.4. Impuesto sobre los productos, producci{c o'}n e importaciones **
		rename Eg Imp				// Impuesto sobre los productos, producci{c o'}n e importaciones (total)
		rename Fg ImpProductos		// Impuestos sobre los productos
		rename Gpb ImpNetProductos	// Impuestos sobre los productos netos
		rename Jg ImpProduccion		// Impuestos sobre la producci{c o'}n e importaciones
		

		** V.5. Subsidios **
		rename Kg Sub				// Subsidios (total)

		** V.6. Excedente bruto de operaci{c o'}n **
		rename Lg ExBOp				// Excedente bruto de operaci{c o'}n (con mixto)
		rename Us ExBOpSinMix		// Excedente bruto de operaci{c o'}n (sin mixto)

		** V.7. Excedente bruto de operaci{c o'}n, por sectores institucionales ** 
		rename Vs ExBOpNoFin		// Excedente bruto de operaci{c o'}n sociedades no financieras
		rename Ws ExBOpFin			// Excedente bruto de operaci{c o'}n sociedades financieras
		rename Zs ExBOpISFLSH		// Excedente bruto de operaci{c o'}n ISFLSH
		rename Ys ExBOpHog			// Excedente bruto de operaci{c o'}n de los hogares
		rename Xs ExBOpGob			// Excedente bruto de operaci{c o'}n del gobierno

		** V.8. Excedente neto de operaci{c o'}n, por sectores institucionales ** 
		rename ABs ExNOpNoFin		// Excedente neto de operaci{c o'}n sociedades no financieras
		rename ACs ExNOpFin			// Excedente neto de operaci{c o'}n sociedades financieras
		rename AFs ExNOpISFLSH		// Excedente neto de operaci{c o'}n ISFLSH
		rename AEs ExNOpHog			// Excedente neto de operaci{c o'}n de los hogares (owner-occupied)
		rename ADs ExNOpGob			// Excedente neto de operaci{c o'}n del gobierno

		** V.9. Consumo de capital fijo **
		rename Dd ConCapFij			// Consumo de capital fijo

		** V.10. Resto del mundo **
		rename Ed PIN				// Producto Interno Neto
		rename Fd ROWRemRecibidas	// ROW, Compensation of Employees, recibidas
		rename Gd ROWRemPagadas			// ROW, Compensation of Employees, pagadas
		rename Hd ROWPropRecibidas		// ROW, Ingresos a la propiedad, recibidas
		rename Id ROWPropPagadas		// ROW, Ingresos a la propiedad, pagadas
		rename Jd ROWTransRecibidas		// ROW, Transferencias corrientes, recibidas
		rename Kd ROWTransPagadas		// ROW, Transferencias corrientes, pagadas
		rename Ld IngNacDisp			// Ingreso nacional disponible

		** V.11. Consumo, usos **
		rename AMs AhorroB			// Ahorro bruto
		rename Bc ConHog			// Consumo de los hogares
		rename Hgc ComprasN			// Compras netas en el extranjero
		rename Bcg ConGob			// Consumo del gobierno general
		rename AGs IngDisp			// Ingreso disponible
		rename HWae Alquileres			// Alquileres sin intermediaci{c o'}n de bienes ra{c i'}ces
		rename HXae Inmobiliarias 		// Inmobiliarias y corredores de bienes ra{c i'}ces
		rename Mc Alojamiento			// Alquieres efectivos de alojamiento de los hogares

		** V.12. Actividades econ{c o'}micas **
		rename IFae ServProf			// Servicios profesionales, cient{c i'}ficos y t{c e'}cnicos
		rename JNae ConsMedi 			// Consultorios m{c e'}dicos
		rename JOae ConsDent			// Consultorios dentales
		rename JPae ConsOtro			// Consultorios otros
		rename JSae EnfeDomi			// Enfermeras a domicilio

		** V.13. Consumo de consumo privado **
		rename Ccp SaludH			// Consumo de los hogares por servicios de salud
		rename Bcp ServProfH			// Consumo de los hogares por servicios profesionales

		** V.14. Ingreso mixto **
		g double IngMixto = .
		label var IngMixto "Ingreso mixto"
		format IngMixto %20.0fc

		* Importa los datos para cada año, si hay un error, el loop termina *
		forvalues k = 2003(1)`aniovp' {
			preserve
			capture import excel using "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Tabulados/Base 2013/`k'-E_43_186_`k'.xlsx", sheet("`k'-E") cellrange(BD63:BD63) clear
			if _rc == 0 {
				local IngMixto = BD in 1
				restore
				replace IngMixto = `IngMixto'*1000000 if anio == `k'
			}
			if _rc != 0 {
				restore
				continue, break
			}
		}

		** V.15. Cuotas a la seguridad social imputada **
		g double SSImputada = .
		label var SSImputada "Contribuciones sociales imputadas"
		format SSImputada %20.0fc
		
		forvalues k = 2003(1)`aniovp' {
			preserve
			capture import excel using "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Tabulados/Base 2013/`k'-E_43_186_`k'.xlsx", sheet("`k'-E") cellrange(BD44:BD44) clear
			if _rc == 0 {
				local SSImputada = BD in 1
				restore
				replace SSImputada = `SSImputada'*1000000 if anio == `k'
			}
			if _rc != 0 {
				restore
				continue, break
			}
		}

		** V.16. Subsidios a los productos, producci{c o'}n e importaciones **
		g double SubProductos = .
		format SubProductos %20.0fc
		label var SubProductos "Subsidios a los productos"

		forvalues k = 2003(1)`aniovp' {
			preserve
			capture import excel using "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Tabulados/Base 2013/`k'-E_43_186_`k'.xlsx", sheet("`k'-E") cellrange(BD57:BD57) clear
			if _rc == 0 {
				local SubProductos = BD in 1
				restore
				replace SubProductos = `SubProductos'*1000000 if anio == `k'
			}
			if _rc != 0 {
				restore
				continue, break
			}
		}

		g double SubProduccion = .
		format SubProduccion %20.0fc
		label var SubProduccion "Subsidios a la producci{c o'}n e importaciones"

		forvalues k = 2003(1)`aniovp' {
			preserve
			capture import excel using "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Tabulados/Base 2013/`k'-E_43_186_`k'.xlsx", sheet("`k'-E") cellrange(BD61:BD61) clear
			if _rc == 0 {
				local SubProduccion = BD in 1
				restore
				replace SubProduccion = `SubProduccion'*1000000 if anio == `k'
			}
			if _rc != 0 {
				restore
				continue, break
			}
		}

		** V.17. Depreciaci{c o'}n del ingreso mixto **
		g double DepMix = .
		format DepMix %20.0fc
		label var DepMix "Depreciaci{c o'}n del ingreso mixto"

		forvalues k = 2003(1)`aniovp' {
			preserve
			capture import excel using "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Tabulados/Base 2013/`k'-E_43_186_`k'.xlsx", sheet("`k'-E") cellrange(BD65:BD65) clear
			if _rc == 0 {
				local DepMix = BD in 1
				restore
				replace DepMix = `DepMix'*1000000 if anio == `k'
			}
			if _rc != 0 {
				restore
				continue, break
			}
		}
		foreach k of varlist _all {
			local label : var label `k'
			local label = substr("`label'",1,31)
			label var `k' "`label'"
		}
		merge 1:1 (anio) using "`c(sysdir_personal)'/SIM/Poblaciontot.dta", nogen keep(matched)
		if `c(version)' > 13.1 {
			saveold "`c(sysdir_personal)'/SIM/SCN.dta", replace version(13)
		}
		else {
			save "`c(sysdir_personal)'/SIM/SCN.dta", replace		
		}
	}

	** D.8. PIBDeflactor **
	*capture use "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", clear
	PIBDeflactor, anio(`anio') nographs nooutput
	local anio_exo = r(anio_exo)
	local except = r(except)
	local exceptI = r(exceptI)

	if "`except'" != "." {
		local except `"{bf:Excepto}: `=substr("`except'",1,`=strlen("`except'")-2')'. "'
	}
	else {
		local except ""
	}

	if "`exceptI'" != "." {
		local exceptI `"{bf:Excepto deflactor}: `=substr("`exceptI'",1,`=strlen("`exceptI'")-2')'. "'
	}
	else {
		local exceptI ""
	}
	local geo = r(geo)

	tempfile basepib
	save `basepib'



	**************************
	** 1.1. Merge databases **
	use "`c(sysdir_personal)'/SIM/SCN.dta", clear
	local anio_last = anio[_N]
	merge 1:1 (anio) using `basepib', nogen
	tsset anio
	capture keep `if'



	******************************
	** 1.2. Forecast & Pastcast **
	order indiceY-lambda, last

	* guarda el {c u'}ltimo año para el que hay un valor de PIB *
	forvalues k = `=_N'(-1)1 {
		if RemSalSS[`k'] != . {
			local latest = anio[`k']
			continue, break
		}
	}

	/* Calcula los valores futuros de las variables a partir de la {c u'}ltima 
	observaci{c o'}n y los valores anteriores de 2002 a 1993 (utiliza la tasa de 
	crecimiento del PIB en t{c e'}rminos nominales */
	foreach k of varlist RemSalSS-DepMix {
		replace `k' = L.`k'*pibYR/L.pibYR*indiceY/L.indiceY if `k' == .
		forvalues j = 2002(-1)1993 {
			replace `k' = F.`k'*L.pibYR/pibYR*L.indiceY/indiceY if anio == `j'
		}
	}

	* Ajuste SCN vs. PIB trimestral *
	forvalues k = `=_N'(-1)1 {
		local pibAjuste`=anio[`k']' = pibY[`k']/PIB[`k']
		foreach j of varlist RemSalSS-DepMix {
			replace `j' = `j'*`pibAjuste`=anio[`k']'' if anio == anio[`k']
		}
	}
	noisily di in g " Ajuste SCN vs. PIB trimestral (" in y `anio' in g "): " in y %5.3fc (`pibAjuste`anio''-1)*100 " %"

	

	*******************************/
	** 1.3. Construir cuentas (C) **

	** C.1. Ingreso mixto **
	g double MixN = IngMixto - DepMix
	format MixN %20.0fc
	label var MixN "Ingreso mixto neto"
	
	g double MixL = MixN*2/3 //						<-- NTA metodolog{c i'}a
	format MixL %20.0fc
	label var MixL "Ingreso mixto (laboral)"

	g double MixK = MixN*1/3 + DepMix //					<-- NTA metodolog{c i'}­a
	format MixK %20.0fc
	label var MixK "Ingreso mixto (capital)"

	g double MixKN = MixK - DepMix
	format MixKN %20.0fc
	label var MixKN "Ingreso mixto neto (capital)"

	** C.2. Depreciation **
	g double DepNoFin = ExBOpNoFin - ExNOpNoFin
	g double DepFin = ExBOpFin - ExNOpFin
	g double DepISFLSH = ExBOpISFLSH - ExNOpISFLSH
	g double DepHog = ExBOpHog - ExNOpHog
	g double DepGob = ExBOpGob - ExNOpGob
	
	** C.9. Resto del Mundo **
	g double ROW = ROWRemRecibidas + ROWTransRecibidas + ROWPropRecibidas - ROWTransPagadas - ROWPropPagadas
	format ROW %20.0fc
	label var ROW "Resto del mundo"

	** C.3. Ingreso de capital neto **	// <--- Hay un error en la base de SCN!
	g double ExNOpSoc = ExBOpNoFin - DepNoFin + ExBOpFin - DepFin + ExBOpISFLSH - DepISFLSH + ROW
	format ExNOpSoc %20.0fc
	label var ExNOpSoc "Sociedades e ISFLSH"

	replace ExNOpSoc = PIN - RemSalSS - MixN - (ImpNetProductos) - ///
		(ImpProduccion + SubProduccion) - ExNOpHog

	** C.4 Ingreso de capital **
	g double CapInc = ExBOp - MixL - ConCapFij //- ROW
	format CapInc %20.0fc
	label var CapInc "Ingreso de capital"

	g double Capital = ExNOpSoc + ExNOpHog + ExNOpGob + MixKN
	format Capital %20.0fc
	label var Capital "Ingreso de capital"

	g double AhorroN = IngNacDisp - ConHog - ConGob - ComprasN
	format AhorroN %20.0fc

	drop if RemSalSS == .

	** C.5. Impuestos Netos **
	*g double ImpNetProductos = ImpProductos + SubProductos
	format ImpNetProductos %20.0fc
	label var ImpNetProductos "Impuestos netos a los productos"

	g double ImpNetProduccion = ImpProduccion + SubProduccion
	format ImpNetProduccion %20.0fc
	label var ImpNetProduccion "Impuestos netos a la producci{c o'}n e importaciones"

	g double ImpNetProduccionL = ImpNetProduccion*(RemSal + SSEmpleadores + SSImputada + MixL)/(RemSal + SSEmpleadores + SSImputada + MixL + MixKN + ExNOpSoc + ExNOpHog)
	format ImpNetProduccionL %20.0fc
	label var ImpNetProduccion "Impuestos netos a la producci{c o'}n e importaciones (laboral)"

	g double ImpNetProduccionK = ImpNetProduccion*(MixKN + ExNOpSoc + ExNOpHog)/(RemSal + SSEmpleadores + SSImputada + MixL + MixKN + ExNOpSoc + ExNOpHog)
	format ImpNetProduccionK %20.0fc
	label var ImpNetProduccionK "Impuestos netos a la producci{c o'}n e importaciones (capital)"

	g double ImpNet = Imp - Sub
	format ImpNet %20.0fc
	label var ImpNet "Impuestos sobre los productos, producci{c o'}n e importaciones"	

	* Ajustes Remuneraciones a asalariados y Seguridad Social *
	replace RemSal = RemSal - SSImputada

	** Validaci{c o'}n **
	g double PIBval = RemSalSS + IngMixto + ExBOpSinMix + ImpNetProductos + ImpNetProduccion
	format PIBval %20.0fc
	label var PIBval "PIB (validaci{c o'}n)"

	** C.6. ROW, Compensation of Employees, pagadas **
	*replace ROWRemPagadas = PIN + ConCapFij + ROWRemRecibidas + ROWPropRecibidas ///
		- ROWPropPagadas + ROWTransRecibidas - ROWTransPagadas - PIBval

	g double ROWRem = ROWRemRecibidas // - ROWRemPagadas
	format ROWRem %20.0fc
	label var ROWRem "Remuneraci{c o'}n de asalariados"

	g double ROWTrans = ROWTransRecibidas - ROWTransPagadas
	format ROWTrans %20.0fc
	label var ROWTrans "Transferencias corrientes"

	g double ROWProp = ROWPropRecibidas - ROWPropPagadas
	format ROWProp %20.0fc
	label var ROWProp "Ingresos a la propiedad"

	** C.11. Ingreso laboral bruto **
	g double Yl = RemSal + MixL + SSImputada + SSEmpleadores + ImpNetProduccionL
	format Yl %20.0fc
	label var Yl "Ingreso laboral"

	* Ingresos de capital con impuestos *
	g double CapIncImp = Capital + ImpNetProduccionK + ImpNetProductos
	format CapIncImp %20.0fc
	label var CapIncImp "Ingreso de capital (netos con impuestos)"



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

	** R.2. Display **
	* Generaci{c o'}n de la producci{c o'}n **
	noisily di _newline in g "{bf: A. Cuenta: " in y "de producci{c o'}n (bruta)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Producci{c o'}n bruta" ///
		_col(44) in y %20.0fc Cpb[`obs'] ///
		_col(66) in y %7.3fc Cpb[`obs']/PIB[`obs']*100
	noisily di in g "  (-) Consumo intermedio" ///
		_col(44) in y %20.0fc Npb[`obs'] ///
		_col(66) in y %7.3fc Npb[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Valor agregado" ///
		_col(44) in y %20.0fc (Cpb[`obs']-Npb[`obs']) ///
		_col(66) in y %7.3fc (Cpb[`obs']-Npb[`obs'])/PIB[`obs']*100 "}"
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc (ImpNetProductos[`obs']) ///
		_col(66) in y %7.3fc (ImpNetProductos[`obs'])/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Bruto" ///
		_col(44) in y %20.0fc (PIB[`obs']) ///
		_col(66) in y %7.3fc (PIB[`obs'])/PIB[`obs']*100 "}"


		
	* Returns *
	scalar ProdBruta = Cpb[`obs']
	scalar ProdBrutaPIB = Cpb[`obs']/PIB[`obs']*100
	
	scalar ConsInter = Npb[`obs']
	scalar ConsInterPIB = Npb[`obs']/PIB[`obs']*100
	
	scalar ValoAgreg = (Cpb[`obs']-Npb[`obs'])
	scalar ValoAgregPIB = (Cpb[`obs']-Npb[`obs'])/PIB[`obs']*100
	
	scalar ImpuProdu = ImpNetProductos[`obs']
	scalar ImpuProduPIB = ImpNetProductos[`obs']/PIB[`obs']*100


	* Generaci{c o'}n de ingresos *
	noisily di _newline in g "{bf: B.1. Cuenta: " in y "distribuc{c o'}n del ingreso" in g ///
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
		_col(44) in y %20.0fc ImpNetProduccionL[`obs']  ///
		_col(66) in y %7.3fc ImpNetProduccionL[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingresos laborales" ///
		_col(44) in y %20.0fc Yl[`obs'] ///
		_col(66) in y %7.3fc Yl[`obs']/PIB[`obs']*100 "}"

	noisily di in g "  (+) Ingresos de capital (neto + imp.)" ///
		_col(44) in y %20.0fc CapIncImp[`obs'] ///
		_col(66) in y %7.3fc CapIncImp[`obs'] /PIB[`obs']*100

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

	** R.4. Returns ***
	scalar RemSal = RemSal[`obs']
	scalar RemSalPIB = RemSal[`obs']/PIB[`obs']*100

	scalar SSocial = SSEmpleadores[`obs'] + SSImputada[`obs']
	scalar SSocialPIB = (SSEmpleadores[`obs'] + SSImputada[`obs'])/PIB[`obs']*100

	scalar MixL = MixL[`obs']
	scalar MixLPIB = MixL[`obs']/PIB[`obs']*100

	scalar ImpNetProduccionL = ImpNetProduccionL[`obs']
	scalar ImpNetProduccionLPIB = ImpNetProduccionL[`obs']/PIB[`obs']*100

	scalar Yl = Yl[`obs']
	scalar YlPIB = Yl[`obs']/PIB[`obs']*100
	scalar CapIncImp = CapIncImp[`obs']
	scalar CapIncImpPIB = CapIncImp[`obs']/PIB[`obs']*100

	scalar PIN = PIN[`obs']
	scalar PINPIB = PIN[`obs']/PIB[`obs']*100
	scalar ConCapFij = ConCapFij[`obs']
	scalar ConCapFijPIB = ConCapFij[`obs']/PIB[`obs']*100

	scalar PIB = PIB[`obs']
	scalar PIPIB = PIB[`obs']/PIB[`obs']*100
	
	g geoPIB = (((PIB/deflator)/(L5.PIB/L5.deflator))^(1/5)-1)*100
	scalar crecpibpGEO = geoPIB[`obs']
	scalar crecpibfGEO = geoPIB[`=`obs'+5']

	scalar SSEmpleadores = SSEmpleadores[`obs']
	scalar SSEmpleadoresPIB = SSEmpleadores[`obs']/PIB[`obs']*100
	
	scalar SSImputada = SSImputada[`obs']
	scalar SSImputadaPIB = SSImputada[`obs']/PIB[`obs']*100


	* Cuenta de capital *
	noisily di _newline in g "{bf: B.2. Cuenta: " in y "de los ingresos de capital" in g ///
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
	noisily di in g "{bf:  (=) Ingresos de capital (neto) " ///
		_col(44) in y %20.0fc Capital[`obs'] ///
		_col(66) in y %7.3fc Capital[`obs']/PIB[`obs']*100 "}"
	noisily di in g _dup(72) "-"
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc ImpNetProductos[`obs'] ///
		_col(66) in y %7.3fc ImpNetProductos[`obs'] /PIB[`obs']*100
	noisily di in g "  (+) Impuestos a la producci{c o'}n (capital)" ///
		_col(44) in y %20.0fc ImpNetProduccionK[`obs']  ///
		_col(66) in y %7.3fc ImpNetProduccionK[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingresos de capital (neto + imp.) " ///
		_col(44) in y %20.0fc CapIncImp[`obs'] ///
		_col(66) in y %7.3fc CapIncImp[`obs']/PIB[`obs']*100 "}"

	* Returns *
	scalar ExNOpSoc = ExNOpSoc[`obs']
	scalar ExNOpSocPIB = ExNOpSoc[`obs']/PIB[`obs']*100

	scalar MixK = MixK[`obs']
	scalar MixKPIB = MixK[`obs']/PIB[`obs']*100	
	
	scalar MixKN = MixKN[`obs']
	scalar MixKNPIB = MixKN[`obs']/PIB[`obs']*100

	scalar ExNOpHog = ExNOpHog[`obs']
	scalar ExNOpHogPIB = ExNOpHog[`obs']/PIB[`obs']*100

	scalar ExNOpGob = ExNOpGob[`obs']
	scalar ExNOpGobPIB = ExNOpGob[`obs']/PIB[`obs']*100

	scalar Capital = Capital[`obs']
	scalar CapitalPIB = Capital[`obs']/PIB[`obs']*100

	scalar ImpNetProductos = ImpNetProductos[`obs']
	scalar ImpNetProductosPIB = ImpNetProductos[`obs']/PIB[`obs']*100

	scalar ImpNetProduccionK = ImpNetProduccionK[`obs']
	scalar ImpNetProduccionKPIB = ImpNetProduccionK[`obs']/PIB[`obs']*100

	** R.3. Graph **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar Laboral Capital Depreciacion
		g `Laboral' = (Yl)/deflator/1000000000000
		label var `Laboral' "Ingresos laborales"
		g `Capital' = (CapIncImp + Yl)/deflator/1000000000000
		label var `Capital' "Ingresos de capital"
		g `Depreciacion' = (ConCapFij + CapIncImp + Yl)/deflator/1000000000000
		label var `Depreciacion' "Depreciaci{c o'}n"
		format `Depreciacion' %7.0fc
		
		if `anio_exo'-`latest' == 1 {
			local graphtype "bar"
		}
		else {
			local graphtype "bar"
		}

		if "$export" == "" {
			local graphtitle = "{bf:Distribuci{c o'}n} del ingreso"
			local graphfuente = "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle = ""
			local graphfuente = ""
		}

		tabstat `Depreciacion', stat(max) save
		tempname DEPMAX
		matrix `DEPMAX' = r(StatTotal)

		twoway (bar `Depreciacion' anio if anio <= `anio_last', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`Depreciacion') mlabpos(12) mlabcolor(black) mlabsize(large)) ///
			(bar `Capital' anio if anio <= `anio_last', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `Laboral' anio if anio <= `anio_last', pstyle(p3) lwidth(none) barwidth(.75)) ///
			(`graphtype' `Depreciacion' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`Depreciacion') mlabpos(12) mlabcolor(black) mlabsize(large) fintensity(50)) ///
			(`graphtype' `Capital' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p2) lwidth(none) barwidth(.75) fintensity(50)) ///
			(`graphtype' `Laboral' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p3) lwidth(none) barwidth(.75) fintensity(50)) ///
			(bar `Depreciacion' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p1) lwidth(none) barwidth(.75)) ///
			(bar `Capital' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `Laboral' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p3) lwidth(none) barwidth(.75)), ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			legend(cols(3) order(1 2 3) region(margin(zero))) ///
			xtitle("") ///
			text(`=`Depreciacion'[1]*0' `=`latest'+1' "{bf:$paqueteEconomico}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			text(`=`Depreciacion'[1]*0' `=anio[1]' "{bf:billones MXN `anio'}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			///text(`=`Depreciacion'[1]*.05' `=anio[_N]-7.5' "{bf:Proyecci{c o'}n CIEP}", place(ne) color(white)) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `anio') ///
			ylabel(none, format(%20.0fc)) ///
			ytitle("") ///
			yscale(range(0)) xscale(range(1993)) ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last'.") ///
			name(gdp_generacion, replace)

		graph save gdp_generacion "`c(sysdir_personal)'/SIM/graphs/gdp_generacion", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/gdp_generacion.png", replace name(gdp_generacion)
		}
	}

	** R.5 Display (de la producci{c o'}n al ingreso) ***
	noisily di _newline in g "{bf: C. Cuenta: " in y "distribuci{c o'}n secundaria del ing" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "{bf:  (+) Producto Interno Bruto" ///
		_col(44) in y %20.0fc PIB[`obs'] ///
		_col(66) in y %7.3fc PIB[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (-) Consumo de capital fijo" ///
		_col(44) in y %20.0fc ConCapFij[`obs'] ///
		_col(66) in y %7.3fc ConCapFij[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Neto" ///
		_col(44) in y %20.0fc PIN[`obs'] ///
		_col(66) in y %7.3fc PIN[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Remuneraci{c o'}n a asalaraidos (ROW)" ///
		_col(44) in y %20.0fc ROWRem[`obs'] ///
		_col(66) in y %7.3fc ROWRem[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ingresos a la propiedad (ROW)" ///
		_col(44) in y %20.0fc ROWProp[`obs'] ///
		_col(66) in y %7.3fc ROWProp[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Transferencias corrientes (ROW)" ///
		_col(44) in y %20.0fc ROWTrans[`obs'] ///
		_col(66) in y %7.3fc ROWTrans[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso nacional disponible" ///
		_col(44) in y %20.0fc IngNacDisp[`obs'] ///
		_col(66) in y %7.3fc IngNacDisp[`obs']/PIB[`obs']*100 "}"

	* Returns *
	scalar ROWRem = ROWRem[`obs']
	scalar ROWRemPIB = ROWRem[`obs']/PIB[`obs']*100

	scalar ROWProp = ROWProp[`obs']
	scalar ROWPropPIB = ROWProp[`obs']/PIB[`obs']*100

	scalar ROWTrans = ROWTrans[`obs']
	scalar ROWTransPIB = ROWTrans[`obs']/PIB[`obs']*100
	
	scalar ROW = ROW[`obs']
	scalar ROWPIB = ROW[`obs']/PIB[`obs']*100

	scalar IngNacDisp = IngNacDisp[`obs']
	scalar IngNacDispPIB = IngNacDisp[`obs']/PIB[`obs']*100

	* R.6 Consumo *
	noisily di _newline in g "{bf: D. Cuenta: " in y "utilizaci{c o'}n del ingreso disp" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Consumo de hogares e ISFLSH" ///
		_col(44) in y %20.0fc ConHog[`obs'] ///
		_col(66) in y %7.3fc ConHog[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Consumo de gobierno" ///
		_col(44) in y %20.0fc ConGob[`obs'] ///
		_col(66) in y %7.3fc ConGob[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Compras netas" ///
		_col(44) in y %20.0fc ComprasN[`obs'] ///
		_col(66) in y %7.3fc ComprasN[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ahorro neto" ///
		_col(44) in y %20.0fc AhorroN[`obs'] ///
		_col(66) in y %7.3fc AhorroN[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso disponible" ///
		_col(44) in y %20.0fc IngNacDisp[`obs'] ///
		_col(66) in y %7.3fc IngNacDisp[`obs']/PIB[`obs']*100 "}"

	* Returns *
	scalar ConHog = ConHog[`obs']
	scalar ConHogPIB = ConHog[`obs']/PIB[`obs']*100

	scalar ConGob = ConGob[`obs']
	scalar ConGobPIB = ConGob[`obs']/PIB[`obs']*100

	scalar ComprasN = ComprasN[`obs']
	scalar ComprasNPIB = ComprasN[`obs']/PIB[`obs']*100

	scalar AhorroN = AhorroN[`obs']
	scalar AhorroNPIB = AhorroN[`obs']/PIB[`obs']*100
	scalar AhorroNPC = AhorroN[`obs']/poblacion[`obs']

	** R.3. Graph **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar ConHog ConGob ComprasN AhorroN
		g `ComprasN' = (ComprasN)/deflator/1000000000000
		label var `ComprasN' "Compras netas"
		g `ConHog' = (ConHog + ComprasN)/deflator/1000000000000
		label var `ConHog' "Consumo de hogares"
		g `ConGob' = (ConGob + ConHog + ComprasN)/deflator/1000000000000
		label var `ConGob' "Consumo de gobierno"
		g `AhorroN' = (AhorroN + ConGob + ConHog + ComprasN)/deflator/1000000000000
		label var `AhorroN' "Ahorro neto"
		format `AhorroN' %7.0fc

		if "$export" == "" {
			local graphtitle = "{bf:Utilizaci{c o'}n} del ingreso disponible"
			local graphfuente = "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle = ""
			local graphfuente = ""
		}
		
		twoway (bar `AhorroN' anio if anio <= `anio_last', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`AhorroN') mlabpos(12) mlabcolor(black) mlabsize(large)) ///
			(bar `ConGob' anio if anio <= `anio_last', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `ConHog' anio if anio <= `anio_last', pstyle(p3) lwidth(none) barwidth(.75)) ///
			(bar `ComprasN' anio if anio <= `anio_last', pstyle(p4) lwidth(none) barwidth(.75)) ///
			(`graphtype' `AhorroN' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`AhorroN') mlabpos(12) mlabcolor(black) mlabsize(large) fintensity(50)) ///
			(`graphtype' `ConGob' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p2) lwidth(none) barwidth(.75) fintensity(50)) ///
			(`graphtype' `ConHog' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p3) lwidth(none) barwidth(.75) fintensity(50)) ///
			(`graphtype' `ComprasN' anio if anio <= `anio_exo' & anio > `anio_last', pstyle(p4) lwidth(none) barwidth(.75) fintensity(50)) ///
			(bar `AhorroN' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p1) lwidth(none)) ///
			(bar `ConGob' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p2) lwidth(none)) ///
			(bar `ConHog' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p3) lwidth(none)) ///
			(bar `ComprasN' anio if anio > `anio_last' & anio > `anio_exo', pstyle(p4) lwidth(none)), ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			legend(cols(4) order(1 2 3 4) region(margin(zero))) ///
			xtitle("") ///
			text(`=`AhorroN'[1]*0' `=`latest'+1' "{bf:$paqueteEconomico}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			text(`=`AhorroN'[1]*0' `=anio[1]' "{bf:billones MXN `anio'}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			///text(`=`AhorroN'[1]*0' `=anio[_N]-7.5' "{bf:Proyecci{c o'}n CIEP}", place(ne) color(white)) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `anio') ///
			ylabel(none, format(%20.0fc)) ///
			ytitle("") ///
			yscale(range(0)) xscale(range(1993)) ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last'.") ///
			name(gdp_utilizacion, replace)

		graph save gdp_utilizacion "`c(sysdir_personal)'/SIM/graphs/gdp_utilizacion", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/gdp_utilizacion.png", replace name(gdp_utilizacion)
		}

		/* Estructura económca *
		tempvar FFFG OTRAE TOTAE HUae
		egen `TOTAE' = rsum(Eae ADae AKae APae BDae FFae FGae FHae HFae HUae GOae ServProf IQae IRae JCae JLae KIae KUae LDae LTae)
		egen `FFFG' = rsum(FFae FGae)
		egen `HUae' = rsum(HUae)
		egen `OTRAE' = rsum(GOae ServProf IQae IRae JCae JLae KIae KUae LDae LTae)

		foreach k of varlist Eae ADae AKae APae BDae `FFFG' FHae HFae `HUae' `OTRAE' {
			tempvar `k'
			g ``k'' = `k'/`TOTAE'*100
		}

		graph hbar `Eae' `ADae' `AKae' `APae' `BDae' ///
			``FFFG'' `FHae' ``HUae'' `HFae' ``OTRAE'' ///
			if anio >= 2010 & anio <= `anio_last', over(anio) stack ///
			blabel(bar, format(%7.1fc)) ///
			legend(rows(2) label(1 "Agricultura") label(2 "Minería") label(3 "Energía eléctrica") ///
			label(4 "Construcción") label(5 "Manufactura") label(6 "Comercio") label(7 "Transportes") ///
			label(8 "Servicios inmobiliarios") label(9 "Servicios financieros") label(10 "Otros servicios")) ///
			title("{bf:Estructura} econ{c o'}mica") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last'.") ///
			name(estructuraEco, replace)

		g EAgricultura = `Eae'
		g EMineria = `ADae'
		g EEnergiaElectrica = `AKae'
		g EConstruccion = `APae'
		g EManufactura = `BDae'
		g EComercio = ``FFFG''
		g ETransportes = `FHae'
		g EInmobiliarios = `HUae'
		g EFinancieros = `HFae'
		g EOtros = ``OTRAE''


		* Sector económico *
		tempvar primario secundario terciario
		egen `primario' = rsum(Eae)
		egen `secundario' = rsum(ADae AKae APae BDae)
		egen `terciario' = rsum(FFae FGae FHae HFae HUae GOae ServProf IQae IRae JCae JLae KIae KUae LDae LTae)

		foreach k of varlist `primario' `secundario' `terciario' {
			tempvar `k'
			replace `k' = `k'/deflator
			g ``k'' = (`k'/L.`k'-1)*100
		}

		forvalues k=1(1)`=_N' {
			if `TOTPIB'[`k'] != . & anio[`k'] >= 2010 & anio[`k'] <= `anio' {
				local text `"`text' `=``primario''[`k']' `=anio[`k']' "{bf:`=string(``primario''[`k'],"%7.1fc")'}""'
				local text `"`text' `=``secundario''[`k']' `=anio[`k']' "{bf:`=string(``secundario''[`k'],"%7.1fc")'}""'
				local text `"`text' `=``terciario''[`k']' `=anio[`k']' "{bf:`=string(``terciario''[`k'],"%7.1fc")'}""'
			}
		}

		twoway (connect ``primario'' anio, msize(large) mlwidth(vvthick)) ///
			(connect ``secundario'' anio, msize(large) mlwidth(vvthick)) ///
			(connect ``terciario'' anio, msize(large) mlwidth(vvthick)) ///
			if anio >= 2010 & anio <= `anio_last', ///
			legend(label(1 "Primario") label(2 "Secundario") label(3 "Terciario")) ///
			title("{bf:Crecimiento} por sector econ{c o'}mico") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last'.") ///
			xlabel(2010(1)`anio_last') ///
			ytitle(Crecimiento anual (%)) ///
			text(`text', color(white) size(vsmall)) ///
			xtitle("") name(primsecter, replace)
		
		g CPrimario = ``primario''
		g CSecundario = ``secundario''
		g CTerciario = ``terciario''

		
		* Exportaciones e importaciones *
		tempvar export import 
		egen `export' = rsum(Tpb)
		egen `import' = rsum(Jpb)

		foreach k of varlist `export' `import' {
			tempvar `k'
			replace `k' = `k'/deflator
			g ``k'' = (`k'/L.`k'-1)*100
		}

		forvalues k=1(1)`=_N' {
			if `TOTPIB'[`k'] != . & anio[`k'] >= 2010 & anio[`k'] <= 2020 {
				local texto `"`texto' `=``export''[`k']' `=anio[`k']' "{bf:`=string(``export''[`k'],"%7.1fc")'}""'
				local texto `"`texto' `=``import''[`k']' `=anio[`k']' "{bf:`=string(``import''[`k'],"%7.1fc")'}""'
			}
		}

		twoway (connect ``export'' anio, msize(large) mlwidth(vvthick)) ///
			(connect ``import'' anio, msize(large) mlwidth(vvthick)) ///
			if anio >= 2010 & anio <= `anio_last', ///
			legend(label(1 "Exportaciones") label(2 "Importaciones")) ///
			title("Crecimiento del sector {bf:externo}") ///
			xlabel(2010(1)`anio_last') ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last'.") ///
			ytitle(Crecimiento anual (%)) ///
			text(`texto', color(white) size(vsmall)) ///
			xtitle("") name(impexp, replace)

		g CExport = ``export''
		g CImport = ``import''


		* Exportaciones por actividad económica *
		foreach k of varlist Cex Dex Eex Gex {
			tempvar `k'
			replace `k' = `k'/deflator
			g ``k'' = (`k'/L.`k'-1)*100
		}

		forvalues k=1(1)`=_N' {
			if ``Cex''[`k'] != . & anio[`k'] >= 2010 & anio[`k'] <= 2020 {
				local texta `"`texta' `=`Cex'[`k']' `=anio[`k']' "{bf:`=string(`Cex'[`k'],"%7.1fc")'}""'
				local texta `"`texta' `=`Dex'[`k']' `=anio[`k']' "{bf:`=string(`Dex'[`k'],"%7.1fc")'}""'
				local texta `"`texta' `=`Eex'[`k']' `=anio[`k']' "{bf:`=string(`Eex'[`k'],"%7.1fc")'}""'
				local texta `"`texta' `=`Gex'[`k']' `=anio[`k']' "{bf:`=string(`Gex'[`k'],"%7.1fc")'}""'
			}
		}

		twoway (connect `Cex' anio, msize(large) mlwidth(vvthick)) ///
			(connect `Dex' anio, msize(large) mlwidth(vvthick)) ///
			(connect `Eex' anio, msize(large) mlwidth(vvthick)) ///
			(connect `Gex' anio, msize(large) mlwidth(vvthick)) ///
			if anio >= 2010 & anio <= `anio_last',  ///
			xlabel(2010(1)`anio_last') ///
			legend(rows(1) label(1 "Agricultura") label(2 "Minería") label(3 "Energía eléctrica") ///
			label(4 "Manufactura")) ///
			title("{bf:Exportaciones} por actividad econ{c o'}mica") ///
			text(`texta', color(white) size(vsmall)) ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:{c U'}ltimo dato reportado}: `anio_last'.") ///
			xtitle("") ytitle(Crecimiento anual (%)) ///
			name(sectorext, replace)

		g ExAgricultura = `Cex'
		g ExMineria = `Dex'
		g ExElectrica = `Eex'
		g ExManufactura = `Gex'
		*********/

	}
	

	* Cuenta de consumo *
	noisily di _newline in g "{bf: E. Cuenta: " in y "consumo (hogares e ISFLSH)" in g ///
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
	noisily di in g "  (+) Alquiler efec. y cons. de la vivienda" ///
		_col(44) in y %20.0fc Alojamiento[`obs']+Nc[`obs'] ///
		_col(66) in y %7.3fc (Alojamiento[`obs']+Nc[`obs'])/PIB[`obs']*100
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

	* Returns *
	scalar Alim = Dc[`obs']
	scalar AlimPIB = Dc[`obs']/PIB[`obs']*100

	scalar BebN = Ec[`obs']
	scalar BebNPIB = Ec[`obs']/PIB[`obs']*100

	scalar BebA = Gc[`obs']
	scalar BebAPIB = Gc[`obs']/PIB[`obs']*100

	scalar Taba = Hc[`obs']
	scalar TabaPIB = Hc[`obs']/PIB[`obs']*100

	scalar Vest = Jc[`obs']
	scalar VestPIB = Jc[`obs']/PIB[`obs']*100

	scalar Calz = Kc[`obs']
	scalar CalzPIB = Kc[`obs']/PIB[`obs']*100

	scalar Alqu = Alojamiento[`obs']+Nc[`obs']
	scalar AlquPIB = (Alojamiento[`obs']+Nc[`obs'])/PIB[`obs']*100

	scalar Agua = Oc[`obs']
	scalar AguaPIB = Oc[`obs']/PIB[`obs']*100

	scalar Elec = Pc[`obs']
	scalar ElecPIB = Pc[`obs']/PIB[`obs']*100

	scalar Hoga = Qc[`obs']
	scalar HogaPIB = Qc[`obs']/PIB[`obs']*100

	scalar Salu = Xc[`obs']
	scalar SaluPIB = Xc[`obs']/PIB[`obs']*100

	scalar Vehi = ACc[`obs']
	scalar VehiPIB = ACc[`obs']/PIB[`obs']*100

	scalar FTra = ADc[`obs']
	scalar FTraPIB = ADc[`obs']/PIB[`obs']*100

	scalar STra = AEc[`obs']
	scalar STraPIB = AEc[`obs']/PIB[`obs']*100

	scalar Comu = AFc[`obs']
	scalar ComuPIB = AFc[`obs']/PIB[`obs']*100

	scalar Recr = AJc[`obs']
	scalar RecrPIB = AJc[`obs']/PIB[`obs']*100

	scalar Educ = AQc[`obs']
	scalar EducPIB = AQc[`obs']/PIB[`obs']*100

	scalar Rest = AWc[`obs']
	scalar RestPIB = AWc[`obs']/PIB[`obs']*100

	scalar Dive = AZc[`obs']
	scalar DivePIB = AZc[`obs']/PIB[`obs']*100

	scalar ServProf = ServProf[`obs']
	scalar ConsMedi = ConsMedi[`obs']
	scalar ConsDent = ConsDent[`obs']
	scalar ConsOtro = ConsOtro[`obs']
	scalar EnfeDomi = EnfeDomi[`obs']

	scalar SaludH = SaludH[`obs']
	scalar ServProfH = ServProfH[`obs']

	scalar Alquileres = Alquileres[`obs']
	scalar Inmobiliarias = Inmobiliarias[`obs']
	scalar ExBOpHog = ExBOpHog[`obs']
	scalar Alojamiento = Alojamiento[`obs']

	noisily di _newline in g "{bf: F. Cuenta: " in y "consumo (gobierno)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Agricultura, cr{c i'}a, etc." ///
		_col(44) in y %20.0fc Ccg[`obs'] ///
		_col(66) in y %7.3fc Ccg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Miner{c i'}a" ///
		_col(44) in y %20.0fc Dcg[`obs'] ///
		_col(66) in y %7.3fc Dcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Generaci{c o'}n, ... energ{c i'}a el{c e'}ctrica" ///
		_col(44) in y %20.0fc Ecg[`obs'] ///
		_col(66) in y %7.3fc Ecg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Construcci{c o'}n" ///
		_col(44) in y %20.0fc Fcg[`obs'] ///
		_col(66) in y %7.3fc Fcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Industrias manufactureras" ///
		_col(44) in y %20.0fc Gcg[`obs'] ///
		_col(66) in y %7.3fc Gcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comercio al por mayor" ///
		_col(44) in y %20.0fc Hcg[`obs'] ///
		_col(66) in y %7.3fc Hcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comercio al por menor" ///
		_col(44) in y %20.0fc Icg[`obs'] ///
		_col(66) in y %7.3fc Icg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Transportes, correos y almacen..." ///
		_col(44) in y %20.0fc Jcg[`obs'] ///
		_col(66) in y %7.3fc Jcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Informaci{c o'}n en medios masivos" ///
		_col(44) in y %20.0fc Kcg[`obs'] ///
		_col(66) in y %7.3fc Kcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios financieros y de seguridad" ///
		_col(44) in y %20.0fc Lcg[`obs'] ///
		_col(66) in y %7.3fc Lcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios inmobiliarios..." ///
		_col(44) in y %20.0fc Mcg[`obs'] ///
		_col(66) in y %7.3fc Mcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios profesionales..." ///
		_col(44) in y %20.0fc Ncg[`obs'] ///
		_col(66) in y %7.3fc Ncg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Direcci{c o'}n de corporativos y empresas" ///
		_col(44) in y %20.0fc Ocg[`obs'] ///
		_col(66) in y %7.3fc Ocg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de apoyo a los negocios..." ///
		_col(44) in y %20.0fc Pcg[`obs'] ///
		_col(66) in y %7.3fc Pcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios educativos" ///
		_col(44) in y %20.0fc Qcg[`obs'] ///
		_col(66) in y %7.3fc Qcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de salud y de asistencia..." ///
		_col(44) in y %20.0fc Rcg[`obs'] ///
		_col(66) in y %7.3fc Rcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de espar. culturales..." ///
		_col(44) in y %20.0fc Scg[`obs'] ///
		_col(66) in y %7.3fc Scg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de alojamiento temporal..." ///
		_col(44) in y %20.0fc Tcg[`obs'] ///
		_col(66) in y %7.3fc Tcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Otros servicios excepto gobierno" ///
		_col(44) in y %20.0fc Ucg[`obs'] ///
		_col(66) in y %7.3fc Ucg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Actividades de gobierno..." ///
		_col(44) in y %20.0fc Vcg[`obs'] ///
		_col(66) in y %7.3fc Vcg[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Compras en el exterior por residentes" ///
		_col(44) in y %20.0fc Wcg[`obs'] ///
		_col(66) in y %7.3fc Wcg[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Consumo (gobierno)" ///
		_col(44) in y %20.0fc ConGob[`obs'] ///
		_col(66) in y %7.3fc ConGob[`obs']/PIB[`obs']*100 "}"		

	* Returns *
	scalar AgriGob = Ccg[`obs']
	scalar AgriGobPIB = Ccg[`obs']/PIB[`obs']*100

	scalar MineGob = Dcg[`obs']
	scalar MineGobPIB = Dcg[`obs']/PIB[`obs']*100

	scalar ElecGob = Ecg[`obs']
	scalar ElecGobPIB = Ecg[`obs']/PIB[`obs']*100

	scalar ConsGob = Fcg[`obs']
	scalar ConsGobPIB = Fcg[`obs']/PIB[`obs']*100

	scalar ManuGob = Gcg[`obs']
	scalar ManuGobPIB = Gcg[`obs']/PIB[`obs']*100

	scalar ComMGob = Hcg[`obs']
	scalar ComMGobPIB = Hcg[`obs']/PIB[`obs']*100

	scalar CommGob = Icg[`obs']
	scalar CommGobPIB = Icg[`obs']/PIB[`obs']*100

	scalar TranGob = Jcg[`obs']
	scalar TranGobPIB = Jcg[`obs']/PIB[`obs']*100

	scalar MediGob = Kcg[`obs']
	scalar MediGobPIB = Kcg[`obs']/PIB[`obs']*100

	scalar SerFGob = Lcg[`obs']
	scalar SerFGobPIB = Lcg[`obs']/PIB[`obs']*100

	scalar SerIGob = Mcg[`obs']
	scalar SerIGobPIB = Mcg[`obs']/PIB[`obs']*100

	scalar SerPGob = Ncg[`obs']
	scalar SerPGobPIB = Ncg[`obs']/PIB[`obs']*100

	scalar DireGob = Ocg[`obs']
	scalar DireGobPIB = Ocg[`obs']/PIB[`obs']*100

	scalar SerNGob = Pcg[`obs']
	scalar SerNGobPIB = Pcg[`obs']/PIB[`obs']*100

	scalar SerEGob = Qcg[`obs']
	scalar SerEGobPIB = Qcg[`obs']/PIB[`obs']*100

	scalar SaluGob = Rcg[`obs']
	scalar SaluGobPIB = Rcg[`obs']/PIB[`obs']*100

	scalar CultGob = Scg[`obs']
	scalar CultGobPIB = Scg[`obs']/PIB[`obs']*100

	scalar AlojGob = Tcg[`obs']
	scalar AlojGobPIB = Tcg[`obs']/PIB[`obs']*100

	scalar OtroGob = Ucg[`obs']
	scalar OtroGobPIB = Ucg[`obs']/PIB[`obs']*100

	scalar GobiGob = Vcg[`obs']
	scalar GobiGobPIB = Vcg[`obs']/PIB[`obs']*100

	scalar CompGob = Wcg[`obs']
	scalar CompGobPIB = Wcg[`obs']/PIB[`obs']*100

	noisily di _newline in g "{bf: G. Cuenta: " in y "actividad econ{c o'}mica" in g ///
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
	noisily di in g "  (+) Informaci{c o'}n en medios masivos" ///
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
	noisily di in g "  (+) Direcci{c o'}n de corporativos y empresas" ///
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

	timer off 3
	timer list 3
	noisily di _newline in g "Tiempo: " in y round(`=r(t3)/r(nt3)',.1) in g " segs."
}
end
