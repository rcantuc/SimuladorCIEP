*capture confirm file "`c(sysdir_personal)'/SIM/SCN.dta"
*if _rc != 0 | "`update'" == "update" {

	noisily di in g "  Updating SCN.dta..." _newline


	** D.1. Cuenta de generaci{c o'}n del ingreso **
	run "`c(sysdir_personal)'/UpdateBIE.do" "724025 724014 724015 724016 724017 724018 724019 724020 724021 724022 724023 724024" "millones"
	
	* PIB *
	rename valoragregadobrutoproductointern PIB				// Producto Interno Bruto
	
	* Remuneraciones a asalariados *
	rename remuneracióndeasalariados RemSalSS				// Remuneraciones a asalariados (total)
	rename sueldosysalariosf1millonesdepeso RemSal				// Sueldos y salarios (con contribuciones imputadas)
	rename contribucionessocialesdelosemple SSEmpleadores			// Contribuciones a la seguridad social, efectivas

	* Impuesto sobre los productos, producci{c o'}n e importaciones *
	*rename Eg Imp								// Impuesto sobre los productos, producci{c o'}n e importaciones (total)
	rename impuestossobrelosproductos ImpProductos				// Impuestos sobre los productos
	*rename Gpb ImpNetProductos						// Impuestos sobre los productos netos
	rename impuestossobrelaproducciónylasim ImpProduccion			// Impuestos sobre la producci{c o'}n e importaciones
	
	* Subsidios *
	rename menossubsidiosf1millonesdepesosa Sub				// Subsidios (total)

	* Excedente bruto de operaci{c o'}n *
	rename excedentebrutodeoperaciãnf1millo ExBOp				// Excedente bruto de operaci{c o'}n (con mixto)
	tempfile generacion
	save `generacion'


	** D.2. Cuenta de ingreso nacional disponbile **
	run "`c(sysdir_personal)'/UpdateBIE.do" "500353 500354 500355 500356 500357 500358 500359 500360 500361 500362 500363 500364" "millones"
	
	* Consumo de capital fijo *
	rename consumodecapitalfijof1millonesde ConCapFij			// Consumo de capital fijo

	* Resto del mundo *
	rename valoragregadonetoproductointerno PIN				// Producto Interno Neto
	rename remuneracionesrecibidasf1millone ROWRemRecibidas	// ROW, Compensation of Employees, recibidas
	rename remuneracionespagadasf1millonesd ROWRemPagadas			// ROW, Compensation of Employees, pagadas
	rename rentasdelapropiedadrecibidasf1mi ROWPropRecibidas		// ROW, Ingresos a la propiedad, recibidas
	rename rentasdelapropiedadpagadasf1mill ROWPropPagadas		// ROW, Ingresos a la propiedad, pagadas
	rename transferenciascorrientesrecibida ROWTransRecibidas		// ROW, Transferencias corrientes, recibidas
	rename transferenciascorrientespagadasf ROWTransPagadas		// ROW, Transferencias corrientes, pagadas
	rename ingresodisponiblebrutof1millones IngNacDisp			// Ingreso nacional disponible

	
	tempfile disponible
	save `disponible'

	
	
	
	
exit
	

	** D.2. Cuenta por sectores institucionales **
	import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Cuentas por sectores institucionales.xlsx", clear
	LimpiaBIE s
	tempfile sectores
	save `sectores'

	** D.3. Cuenta de ingreso nacional disponbile **
	*import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/Cuenta del ingreso nacional disponible.xlsx", clear
	*LimpiaBIE d
	*tempfile disponible
	*save `disponible'

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
	*rename Mg PIB				// Producto Interno Bruto

	** V.3. Remuneraciones a asalariados **
	*rename Bg RemSalSS			// Remuneraciones a asalariados (total)
	*rename Cg RemSal			// Remuneraciones a asalariados (sin contribuciones efectivas, con contribuciones imputadas)
	*rename Dg SSEmpleadores		// Contribuciones a la seguridad social, efectivas

	** V.4. Impuesto sobre los productos, producci{c o'}n e importaciones **
	*rename Eg Imp				// Impuesto sobre los productos, producci{c o'}n e importaciones (total)
	*rename Fg ImpProductos		// Impuestos sobre los productos
	rename Gpb ImpNetProductos	// Impuestos sobre los productos netos
	*rename Jg ImpProduccion		// Impuestos sobre la producci{c o'}n e importaciones
	

	** V.5. Subsidios **
	*rename Kg Sub				// Subsidios (total)

	** V.6. Excedente bruto de operaci{c o'}n **
	*rename Lg ExBOp				// Excedente bruto de operaci{c o'}n (con mixto)
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
	*rename Dd ConCapFij			// Consumo de capital fijo

	** V.10. Resto del mundo **
	*rename Ed PIN				// Producto Interno Neto
	*rename Fd ROWRemRecibidas	// ROW, Compensation of Employees, recibidas
	*rename Gd ROWRemPagadas			// ROW, Compensation of Employees, pagadas
	*rename Hd ROWPropRecibidas		// ROW, Ingresos a la propiedad, recibidas
	*rename Id ROWPropPagadas		// ROW, Ingresos a la propiedad, pagadas
	*rename Jd ROWTransRecibidas		// ROW, Transferencias corrientes, recibidas
	*rename Kd ROWTransPagadas		// ROW, Transferencias corrientes, pagadas
	*rename Ld IngNacDisp			// Ingreso nacional disponible

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
	forvalues k = 2003(1)`=aniovp' {
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
	
	forvalues k = 2003(1)`=aniovp' {
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

	forvalues k = 2003(1)`=aniovp' {
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

	forvalues k = 2003(1)`=aniovp' {
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

	forvalues k = 2003(1)`=aniovp' {
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
*}
