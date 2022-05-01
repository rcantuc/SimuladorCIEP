/*******
* LIEs *
********
import excel "/Users/ricardo/Dropbox (CIEP)/Hewlett Subnacional/Base de datos/LIE/LIE.xlsx", sheet("Data") clear firstrow
levelsof desc_concepto, local(desc_concepto)
foreach k of local desc_concepto {
	bysort desc_entidad: tabstat monto if desc_concepto == "`k'", stat(sum) by(ciclo) format(%20.0fc)
}

local entidadesN `""Aguascalientes" "Baja California"	"Baja California Sur"	"Campeche"	"Coahuila de Zaragoza"	"Colima"	"Chiapas"	"Chihuahua"	"Ciudad de México"	"Durango"	"Guanajuato"	"Guerrero"	"Hidalgo"	"Jalisco"	"México"	"Michoacán de Ocampo"	"Morelos"	"Nayarit"	"Nuevo León"	"Oaxaca"	"Puebla"	"Querétaro"	"Quintana Roo"	"San Luis Potosí"	"Sinaloa"	"Sonora"	"Tabasco"	"Tamaulipas"	"Tlaxcala"	"Veracruz de Ignacio de la Llave"	"Yucatán"	"Zacatecas""'


****************/
* PIB Entidades *
*****************
local entidades "Aguas BC BCS Camp Coah Coli Chiap Chih CDMX Dura Guan Guer Hida Jali EdoMex Mich More Naya NL Oaxa Pueb Quer QRoo SLP Sina Sono Taba Tama Tlax Vera Yuca Zaca"
tokenize `entidades'

import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/PIB Entidades Federativas.xlsx", clear
LimpiaBIE

rename A anio
local j = 1
foreach k of varlist B-AG {
	rename `k' pibYEnt``j''
	local ++j
}
reshape long pibYEnt, i(anio) j(entidad) string

save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", replace



*******************************/
* Participaciones y sus fondos *
********************************
local entidades "Agua BC BCS Camp Coah Col Chia Chih CDMX Dur Gua Gue Hid Jal EdoMex Mich Mor Nay NL Oax Pue Que QRoo SLP Sin Son Tab Tam Tlax Ver Yuc Zac"
tokenize `entidades'

local series28 `""" A B C D E F G H I J K L M"'
foreach gastofed in 28 {
	foreach fondo of local series`gastofed' {
		local serie "XAC`gastofed'`fondo'"

		local j = 1
		forvalues k=1(1)32 {
			DatosAbiertos `serie'`=string(`k',"%02.0f")', nographs
			if r(error) != 2000 {
				* Limpiar base intermedia *
				split nombre, gen(entidad) parse(":")
				drop nombre
				rename entidad2 concepto
				g entidad = "``j''"
			}

			* Guardar base intermedia *
			tempfile `serie'`=string(`k',"%02.0f")'
			save ``serie'`=string(`k',"%02.0f")''
			local ++j
		}

		use ``serie'01'
		forvalues k=2(1)32 {
			append using ``serie'`=string(`k',"%02.0f")''
		}

		merge 1:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
		replace entidad1 = "Estado de M{c e'}xico" if entidad1 == "M?xico" | entidad1 == "México"
		replace entidad1 = "Michoac{c a'}n" if entidad1 == "Michoac?n" | entidad1 == "Michoacán"
		replace entidad1 = "Nuevo Le{c o'}n" if entidad1 == "Nuevo Le?n" | entidad1 == "Nuevo León"
		replace entidad1 = "Quer{c e'}taro" if entidad1 == "Quer?taro" | entidad1 == "Querétaro"
		replace entidad1 = "San Luis Potos{c i'}" if entidad1 == "San Luis Potos?" | entidad1 == "San Luis Potosí"
		replace entidad1 = "Yucat{c a'}n" if entidad1 == "Yucat?n" | entidad1 == "Yucatán"

		* Graficas *
		g monto_pibE = monto/pibYEnt*100
		tempvar rank
		egen `rank' = rank(monto_pibE) if anio == 2020, field
		egen rank = mean(`rank'), by(entidad)

		replace entidad = entidad + " (" + string(rank) + ")"

		local length = length("`=concepto[1]'")
		if `length' > 60 {
			local textsize ", size(medium)"
		}
		if `length' > 90 {
			local textsize ", size(vsmall)"
		}
		if `length' > 110 {
			local textsize ", size(tiny)"
		}

		graph bar monto_pibE if monto_pibE != ., over(entidad) over(anio) ///
			stack asyvar ///
			title({bf:`=concepto[1]'}`textsize') ///
			subtitle(Por entidad federativa) ///
			ytitle("% PIB Estatal") ///
			ylabel(, format(%5.1fc)) ///
			blabel(bar, format(%5.1fc)) ///
			legend(rows(3)) ///
			name(`serie', replace)

		graph bar monto_pibE if monto_pibE != . & rank >= 1 & rank <= 10, over(entidad, sort(rank)) over(anio) ///
			stack asyvar ///
			title({bf:`=concepto[1]'}`textsize') ///
			subtitle(Por entidad federativa) ///
			ytitle("% PIB Estatal") ///
			ylabel(, format(%5.1fc)) ///
			blabel(bar, format(%5.1fc)) ///
			legend(rows(1)) ///
			name(`serie'1, replace)

		tabstat rank, stat(max) save
		if r(StatTotal)[1,1] > 10 {
			graph bar monto_pibE if monto_pibE != . & rank >= 11 & rank <= 20, over(entidad, sort(rank)) over(anio) ///
				stack asyvar ///
				title({bf:`=concepto[1]'}`textsize') ///
				subtitle(Por entidad federativa) ///
				ytitle("% PIB Estatal") ///
				ylabel(, format(%5.1fc)) ///
				blabel(bar, format(%5.1fc)) ///
				legend(rows(1)) ///
				name(`serie'2, replace)
		}

		tabstat rank, stat(max) save
		if r(StatTotal)[1,1] > 20 {
			graph bar monto_pibE if monto_pibE != . & rank >= 21, over(entidad, sort(rank)) over(anio) ///
				stack asyvar ///
				title({bf:`=concepto[1]'}`textsize') ///
				subtitle(Por entidad federativa) ///
				ytitle("% PIB Estatal") ///
				ylabel(, format(%5.1fc)) ///
				blabel(bar, format(%5.1fc)) ///
				legend(rows(1)) ///
				name(`serie'3, replace)
		}
	}
}


****************************/
* Aportaciones y sus fondos *
*****************************
local entidades "Aguas BC BCS Camp Coah Col Chia Chih CDMX Dur Gua Gue Hid Jal EdoMex Mich Mor Nay NL Oax Pue Que QRoo SLP Sin Son Tab Tam Tlax Ver Yuc Zac"
tokenize `entidades'

foreach fondo in "" A B C D E F G H I J K L M N O {
	local serie "XAC33`fondo'"

	local j = 1
	forvalues k=1(1)32 {
		DatosAbiertos `serie'`=string(`k',"%02.0f")', nographs
		if r(error) != 2000 {
			* Limpiar base intermedia *
			split nombre, gen(entidad) parse(":")
			drop nombre
			rename entidad2 concepto
			g entidad = "``j''"
		}

		* Guardar base intermedia *
		tempfile `serie'`=string(`k',"%02.0f")'
		save ``serie'`=string(`k',"%02.0f")''
		local ++j
	}

	use ``serie'01'
	forvalues k=2(1)32 {
		append using ``serie'`=string(`k',"%02.0f")''
	}

	merge 1:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
	replace entidad1 = "Estado de M{c e'}xico" if entidad1 == "M?xico" | entidad1 == "México"
	replace entidad1 = "Michoac{c a'}n" if entidad1 == "Michoac?n" | entidad1 == "Michoacán"
	replace entidad1 = "Nuevo Le{c o'}n" if entidad1 == "Nuevo Le?n" | entidad1 == "Nuevo León"
	replace entidad1 = "Quer{c e'}taro" if entidad1 == "Quer?taro" | entidad1 == "Querétaro"
	replace entidad1 = "San Luis Potos{c i'}" if entidad1 == "San Luis Potos?" | entidad1 == "San Luis Potosí"
	replace entidad1 = "Yucat{c a'}n" if entidad1 == "Yucat?n" | entidad1 == "Yucatán"

	* Graficas *
	g monto_pibE = monto/pibYEnt*100
	tempvar rank
	egen `rank' = rank(monto_pibE) if anio == 2020, field
	egen rank = mean(`rank'), by(entidad)

	replace entidad = entidad + " (" + string(rank) + ")"

	local length = length("`=concepto[1]'")
	if `length' > 60 {
		local textsize ", size(medium)"
	}
	if `length' > 90 {
		local textsize ", size(vsmall)"
	}
	if `length' > 110 {
		local textsize ", size(tiny)"
	}

	graph bar monto_pibE if monto_pibE != ., over(entidad) over(anio) ///
		stack asyvar ///
		title({bf:`=concepto[1]'}`textsize') ///
		subtitle(Por entidad federativa) ///
		ytitle("% PIB Estatal") ///
		ylabel(, format(%5.1fc)) ///
		blabel(bar, format(%5.1fc)) ///
		legend(rows(3)) ///
		name(`serie', replace)

	graph bar monto_pibE if monto_pibE != . & rank >= 1 & rank <= 10, over(entidad, sort(rank)) over(anio) ///
		stack asyvar ///
		title({bf:`=concepto[1]'}`textsize') ///
		subtitle(Por entidad federativa) ///
		ytitle("% PIB Estatal") ///
		ylabel(, format(%5.1fc)) ///
		blabel(bar, format(%5.1fc)) ///
		legend(rows(1)) ///
		name(`serie'1, replace)

	tabstat rank, stat(max) save
	if r(StatTotal)[1,1] > 10 {
		graph bar monto_pibE if monto_pibE != . & rank >= 11 & rank <= 20, over(entidad, sort(rank)) over(anio) ///
			stack asyvar ///
			title({bf:`=concepto[1]'}`textsize') ///
			subtitle(Por entidad federativa) ///
			ytitle("% PIB Estatal") ///
			ylabel(, format(%5.1fc)) ///
			blabel(bar, format(%5.1fc)) ///
			legend(rows(1)) ///
			name(`serie'2, replace)
	}

	tabstat rank, stat(max) save
	if r(StatTotal)[1,1] > 20 {
		graph bar monto_pibE if monto_pibE != . & rank >= 21, over(entidad, sort(rank)) over(anio) ///
			stack asyvar ///
			title({bf:`=concepto[1]'}`textsize') ///
			subtitle(Por entidad federativa) ///
			ytitle("% PIB Estatal") ///
			ylabel(, format(%5.1fc)) ///
			blabel(bar, format(%5.1fc)) ///
			legend(rows(1)) ///
			name(`serie'3, replace)
	}
}
