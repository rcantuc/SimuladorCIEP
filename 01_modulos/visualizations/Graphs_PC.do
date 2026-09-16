**** 
**** Generación histórica del gasto per cápita
****
* GastoPC usa los parametros de ESCENARIO (iniciaA, basica, ..., gascuidados:
* % del PIB) si existen en memoria — SIM.do 5.1 los define justo antes de este
* do-file — y entonces los 15 anios saldrian con el gasto de anioPE. Aqui se
* quiere lo OBSERVADO de cada PEF: se apartan, se borran antes de cada anio y
* se restauran al final (mismo patron que Graphs_TE.do). *
local escenario iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
	ssa imssbien imss issste pemex issfam invers ///
	pam penimss penisss penpeme penotro ///
	gascfe gaspemex gassener gasinverf gascosdeue ///
	gasinfra gasotros gasfeder gascosto ///
	IngBas gasmadres gascuidados
foreach k of local escenario {
	capture local `k'_esc = scalar(`k')
}

postfile GastoPC double(anio iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
	ssa imssbien imss issste pemex issfam invers ///
	pam penimss penisss penpeme penotro ///
	gascfe gaspemex gassener gasinverf gascosdeue ///
	gasinfra gasotros gasfeder gascosto ///
	IngBas gasmadres gascuidados) ///
	using `"`c(sysdir_site)'/raw/temp/GastoPC.dta"', replace

capture scalar drop iniciaAPC basicaPC medsupPC superiPC posgraPC eduaduPC otrosePC inverePC culturPC investPC ///
	ssaPC imssbienPC imssPC issstePC pemexPC issfamPC inversPC ///
	pamPC penimssPC penisssPC penpemePC penotroPC ///
	gascfePC gaspemexPC gassenerPC gasinverfPC gascosdeuePC ///
	gasinfraPC gasotrosPC gasfederPC gascostoPC ///
	IngBasPC gasmadresPC gascuidadosPC

forvalues anio = 2013(1)`=anioPE' {
	foreach k of local escenario {
		capture scalar drop `k'
	}
	noisily GastoPC, aniope(`anio') aniovp(`=aniovp')
	post GastoPC (`anio') (`=iniciaAPC') (`=basicaPC') (`=medsupPC') (`=superiPC') ///
		(`=posgraPC') (`=eduaduPC') (`=otrosePC') (`=inverePC') (`=culturPC') (`=investPC') ///
		(`=ssaPC') (`=imssbienPC') (`=imssPC') (`=issstePC') (`=pemexPC') (`=issfamPC') (`=inversPC') ///
		(`=pamPC') (`=penimssPC') (`=penisssPC') (`=penpemePC') (`=penotroPC') ///
		(`=gascfePC') (`=gaspemexPC') (`=gassenerPC') (`=gasinverfPC') (`=gascosdeuePC') ///
		(`=gasinfraPC') (`=gasotrosPC') (`=gasfederPC') (`=gascostoPC') ///
		(`=IngBasPC') (`=gasmadresPC') (`=gascuidadosPC')
}
postclose GastoPC

* Restaurar el escenario del usuario (si lo habia) *
foreach k of local escenario {
	capture scalar drop `k'
	if "``k'_esc'" != "" {
		escalar pctpib `k' = ``k'_esc'
	}
}


* Abrir el archivo temporal con gasto per cápita
use "`c(sysdir_site)'/raw/temp/GastoPC.dta", clear
		
* Gráfica: Gasto per cápita en educación
twoway connected iniciaA basica medsup superi posgra eduadu otrose invere cultur invest anio, ///
	title("{bf:Gasto per cápita en educación}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Inicial") ///
	label(2 "Básica") ///
	label(3 "Media superior") ///
	label(4 "Superior") ///
	label(5 "Posgrado") ///
	label(6 "Para adultos") ///
	label(7 "Otros gastos") ///
	label(8 "Inversión") ///
	label(9 "Cultura, deportes y recreación") ///
	label(10 "Ciencia y tecnología") ///
	rows(3)) ///
	name(GastoPC_Educacion, replace)

graph export "`c(sysdir_site)'/users/$id/graphs/GastoPC_Educacion.png", replace


* Gráfica: Gasto per cápita en salud
twoway connected ssa imssbien imss issste pemex issfam invers anio, ///
	title("{bf:Gasto per cápita en salud}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "SSa") ///
	label(2 "IMSS-Bienestar") ///
	label(3 "IMSS (salud)") ///
	label(4 "ISSSTE (salud)") ///
	label(5 "Pemex (salud)") ///
	label(6 "ISSFAM (salud)") ///
	label(7 "Inversión en salud") rows(2)) ///
	name(GastoPC_Salud, replace)
	
graph export "`c(sysdir_site)'/users/$id/graphs/GastoPC_Salud.png", replace


* Gráfica: Gasto per cápita en pensiones
twoway connected pam penimss penisss penpeme penotro anio, ///
	title("{bf:Gasto per cápita en pensiones}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Pensión Bienestar") ///
	label(2 "IMSS") ///
	label(3 "ISSSTE") ///
	label(4 "Pemex") ///
	label(5 "CFE, LFC, ISSFAM, Ferronales") rows(1)) ///
	name(GastoPC_Pensiones, replace)

graph export "`c(sysdir_site)'/users/$id/graphs/GastoPC_Pensiones.png", replace

* Gráfica: Gasto per cápita en energía
twoway connected gascfe gaspemex gassener gasinverf gascosdeue anio, ///
	title("{bf:Gasto per cápita en energía}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "CFE") ///
	label(2 "Pemex") ///
	label(3 "SENER") ///
	label(4 "Inversión (energía)") ///
	label(5 "Costo de la deuda (energía)") rows(2)) ///
	name(GastoPC_Energia, replace)

graph export "`c(sysdir_site)'/users/$id/graphs/GastoPC_Energia.png", replace

* Gráfica: Gasto per cápita en otros gastos
twoway connected gasinfra gasotros gasfeder gascosto anio, ///
	title("{bf:Gasto per cápita en otros gastos}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Otras inversiones") ///
	label(2 "Otros gastos") ///
	label(3 "Participaciones y Otras Aportaciones") ///
	label(4 "Costo de la deuda") rows(2)) ///
	name(GastoPC_Otros, replace)

graph export "`c(sysdir_site)'/users/$id/graphs/GastoPC_Otros.png", replace

* Gráfica: Gasto per cápita en transferencias
twoway connected IngBas gasmadres gascuidados anio, ///
	title("{bf:Gasto per cápita en transferencias}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Ingreso básico") ///
	label(2 "Apoyo a madres trabajadoras") ///
	label(3 "Gasto en cuidados") rows(1)) ///
	name(GastoPC_Transferencias, replace)

graph export "`c(sysdir_site)'/users/$id/graphs/GastoPC_Transferencias.png", replace
