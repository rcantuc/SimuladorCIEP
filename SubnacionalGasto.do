*************************/
*** 1. Infraestructura ***
**************************

* 1.1 Infraestructura federal *
PEF if divCIEP == 5, by(entidad) min(0) nog
decode resumido, g(entidadL)
tempfile Infraestructura
save `Infraestructura'


* 1.2 Pensiones federal *
PEF if divCIEP == 7 | divCIEP == 8, by(entidad) min(0) nog
decode resumido, g(entidadL)
tempfile Pensiones
save `Pensiones'


* 1.3 Gasto federal *
PEF if divCIEP == 1, by(entidad) min(0) nog
decode resumido, g(entidadL)
tempfile CostoDeuda
save `CostoDeuda'


* 1.4 Seguridad federal *
PEF if desc_funcion == 5 | desc_funcion == 11 | desc_funcion == 23, by(entidad) min(0) nog
decode resumido, g(entidadL)
tempfile Seguridad
save `Seguridad'


* 1.5 Salud federal *
PEF if divCIEP == 9, by(entidad) min(0) nog
decode resumido, g(entidadL)
tempfile Salud
save `Salud'


* 1.6 Educación federal *
PEF if divCIEP == 2, by(entidad) min(0) nog
decode resumido, g(entidadL)
tempfile Educación
save `Educación'


* 1.7 Gastos estatales *
use "`c(sysdir_personal)'/SIM/EstadosBaseINEGI.dta", clear
rename entidad1 entidadL
rename valor monto


* 1.8 Homolgar y simplificar información *
g conceptograph = "Infraestructura" if concepto == "Obra pública en bienes de dominio público" | concepto == "Obra pública en bienes propios"
replace conceptograph = "Pensiones" if concepto == "Pensiones y jubilaciones"
replace conceptograph = "CostoDeuda" if capitulo == "Deuda pública"
replace conceptograph = "Seguridad" if partida == "Seguridad pública" | partida == "Seguridad pública y tránsito" ///
	| partida == "Servicios de protección y seguridad" | partida == "Secretaría de Seguridad Pública"
replace conceptograph = "Salud" if subpartida == "Instituciones y programas de salud" | subpartida == "Servicios de Salud Pública de la Ciudad de México"
replace conceptograph = "Educación" if subpartida == "Educación básica" | subpartida == "Educación media superior" ///
	| subpartida == "Educación superior" | subpartida == "Educación pública" ///
	///| subpartida == "Arrendamiento de mobiliario y equipo de administración, educacional y recreativo" ///
	///| subpartida == "Convenio para la infraestructura educativa" ///
	///| subpartida == "Desarrollo y fomento educativo" ///
	///| subpartida == "Diversos programas para el sector educativo" ///
	| subpartida == "FA para Educación Tecnológica y Adultos" ///
	| subpartida == "FA para Nómina Educativa y Gasto Operativo" | subpartida == "Fideicomiso Educación Garantizada" ///
	///| subpartida == "Instalación, reparación y mantenimiento de mobiliario y equipo de administración, educacional y recreativo" ///
	///| subpartida == "Instituciones y programas de educación" ///
	///| subpartida == "Instituto Local de la Infraestructura Física Educativa de la Ciudad de México" ///
	///| subpartida == "Instituto de Educación Media Superior de la Ciudad de México" ///
	///| subpartida == "Otro mobiliario y equipo educacional y recreativo" ///
	| subpartida == "Para educación" ///
	///| subpartida == "Refacciones y accesorios menores de mobiliario y equipo de administración, educacional y recreativo" ///
	| subpartida == "Secretaría de Educación" | subpartida == "Secretaría de educación, cultura y deporte"
	
tempfile baseloop
save `baseloop'

levelsof conceptograph, l(conceptoloop)
foreach conceptloop of local conceptoloop {
*foreach conceptloop in Seguridad {

	use `baseloop', clear
	keep if conceptograph == "`conceptloop'" | capitulo == "Impuestos"
	replace conceptograph = "Impuestos" if capitulo == "Impuestos" // Variable completa en años y entidades para llenar missings
	replace monto = 0 if conceptograph == "Impuestos" // Lo hacemos cero para que desaparezca

	if "`conceptloop'" == "Salud" | "`conceptloop'" == "Seguridad" {
		use "`c(sysdir_personal)'/SIM/GastoEstatal`conceptloop'.dta", clear
	}

	collapse (sum) monto (max) poblacion deflator pibYEnt if conceptograph != "", by(entidadL anio)
	replace entidadL = strtoname(entidadL) // Quitar espacios
	reshape wide monto poblacion deflator pibYEnt, i(anio) j(entidadL) string
	reshape long
	replace entidadL =subinstr(entidadL,"_"," ",.) // Agregar espacios

	g conceptograph = "Estatal"
	*merge 1:1 (entidadL anio) using ``conceptloop'', nogen
	replace conceptograph = "Federal" if conceptograph == ""

	* 1.2 Resultados *
	encode conceptograph, g(concept) label(concept)
	collapse (sum) monto /*gasto*/ (max) poblacion deflator pibYEnt, by(entidad anio concept)
	reshape wide monto, i(anio entidad) j(concept)
	reshape long

	* 1.3 Gráfica *
	local aniolast = anio[_N]
	g montograph = monto/poblacion/deflator
	*g montograph = monto/pibYEnt*100
	replace montograph = 0 if montograph == .
	*g montograph2 = gasto/pibYEnt*100
	*replace montograph2 = 0 if montograph2 == .

	tokenize `"$entidadesL"'
	local j = 1
	foreach k of global entidadesC {
		noisily di _newline(2) in g "Entidad: " in y "``j'' `conceptloop'"
		local ifentidad ""
		if "`k'" != "Nac" {
			local ifentidad `"if entidad == "``j''""'
		}

		capture noisily tabstat monto `ifentidad', stat(sum) by(anio) f(%20.0fc) save
		if _rc == 0 {
			graph bar (mean) montograph /*montograph2*/ `ifentidad' [pw=poblacion], ///
				over(anio) ///
				///asyvars stack ///
				title({bf:Gasto estatal en `conceptloop'}) ///
				subtitle(``j'') ///
				///ytitle("% PIB estatal") ///
				ytitle("por residente (MXN `=aniovp')") ///
				///ylabel(0(500)4500, format(%7.0fc)) ///
				blabel(bar, format(%10.0fc)) ///
				legend(rows(1) label(1 "Estatal (INEGI Finanzas Estatales)") /*label(2 "Federal (PEF por disbribución geográfica)")*/) ///
				name(`=strtoname("`conceptloop'_`k'")', replace)
			
			if "$export" != "" {
				graph export  `"$export/`=strtoname("`conceptloop'_`k'")'.png"', as(png) replace name(`=strtoname("`conceptloop'_`k'")')
			}
		}
		local ++j
	}
}
