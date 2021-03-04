**************************************************************
**** BASE DE DATOS: Transferencias a estados y municipios ****
**************************************************************
program define GastoFederalizado
quietly {



	************************
	*** 1. BASE DE DATOS ***
	************************
	capture use "`c(sysdir_site)'/bases/SIM/GastoFederalizado.dta", clear
	local rc = _rc
	syntax [if] [, ANIO(int $anioVP) Graphs Update Base ID(string) ///
		BY(varname) Datosabiertos Fast ROWS(int 4) COLS(int 4) ///
		MINimum(real 1)]

	if "`update'" == "update" | "`rc'" != "0" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.csv", clear
		tempfile gf
		save `gf'

		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed_hist.csv", clear
		tempfile gfH
		save `gfH'

		use `gf', clear
		append using `gfH'

		* Tiempo *
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

		* Anualizar informacion *
		sort anio mes
		local last_mes = mes[_N]
		replace monto = monto/`last_mes'*12 if mes < 12

		* Entidad *
		replace nombre = trim(nombre)
		split nombre, parse(":")
		rename nombre1 entidad 
		replace nombre2 = trim(nombre2)
		replace nombre2 = subinstr(nombre2,"  "," ",.)

		* Errores *
		replace entidad = "Michoac{c a'}n" if entidad == "Michoacan"
		
		* Acentos *
		foreach k of varlist _all {
			capture confirm string variable `k'
			if _rc == 0 {
				replace `k' = subinstr(`k',"á","{c a'}",.)
				replace `k' = subinstr(`k',"é","{c e'}",.)
				replace `k' = subinstr(`k',"í","{c i'}",.)
				replace `k' = subinstr(`k',"ó","{c o'}",.)
				replace `k' = subinstr(`k',"ú","{c u'}",.)
			}
		}

		* De miles MXN a pesos MXN *
		replace monto = monto*1000

		* Nombre corto *
		g pos1 = strpos(nombre,"(")
		g pos2 = strpos(nombre,")")
		g nombrecorto = substr(nombre,pos1+1,pos2-pos1-1)

		replace nombrecorto = "R28" if substr(clave_de_concepto,4,2) == "28"
		replace nombrecorto = "Convenios" if subtema == "Convenios"
		replace nombrecorto = "Subsidios" if subtema == "Subsidios"
		replace nombrecorto = "Seguro Popular" if nombre2 == "Recursos para Protección Social en Salud"
		drop if nombrecorto == "Incluye Ramos 33 y 25"

		drop sector-difusion pos*
		compress
		save "`c(sysdir_site)'/bases/SIM/GastoFederalizado.dta", replace
	}




	*****************
	*** 2. Limpia ***
	*****************
	use "`c(sysdir_site)'/bases/SIM/GastoFederalizado.dta", clear
	drop if entidad == "Total" | clave_de_concepto == "XAC2817" ///
		| nombre2 == "Convenios de Descentralizaci{c o'}n" ///
		| nombre2 == "Participaciones a Entidades Federativas y Municipios (R28)"
	sort anio mes
	local last_mes = mes[_N]
	local last_anio = anio[_N]




	**************
	*** 3. PIB ***
	**************
	preserve
	PIBDeflactor
	tempfile PIB
	save `PIB'
	restore




	*****************
	*** 4. Graphs ***
	*****************
	merge m:1 (anio) using `PIB', nogen keepus(pibY) update replace keep(matched)
	g double montoPIB = monto/pibY*100

	tempvar resumido nombre2tot
	g `resumido' = nombre2
	egen nombre2tot = sum(montoPIB), by(anio nombre2)
	replace `resumido' = "Otros (< `minimum'% PIB)" if (abs(nombre2tot) < `minimum' | nombre2tot == . | nombre2tot == 0)

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		graph bar (sum) montoPIB `if', ///
			over(`resumido') ///
			over(anio, label(labgap(vsmall))) ///
			stack asyvars ///
			title("{bf:Gasto federalizado pagado}") ///
			ytitle(% PIB) ylabel(, labsize(small)) ///
			legend(on position(6) rows(`rows') cols(`cols')) ///
			name(gastoFederalizado, replace) ///
			blabel(bar, format(%7.1fc)) ///
			caption("{it:Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP (Datos Abiertos y Paquetes Econ{c o'}micos).}")
	}
}
end
