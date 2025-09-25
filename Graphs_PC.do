**** 
**** Generación histórica del gasto per cápita
****
postfile GastoPC double(anio iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
	ssa imssbien imss issste pemex issfam invers ///
	pam penimss penisss penpeme penotro ///
	gascfe gaspemex gassener gasinverf gascosdeue ///
	gasinfra gasotros gasfeder gascosto ///
	IngBas gasmadres gascuidados) ///
	using `"`c(sysdir_site)'/03_temp/GastoPC.dta"', replace

capture scalar drop iniciaAPC basicaPC medsupPC superiPC posgraPC eduaduPC otrosePC inverePC culturPC investPC ///
	ssaPC imssbienPC imssPC issstePC pemexPC issfamPC inversPC ///
	pamPC penimssPC penisssPC penpemePC penotroPC ///
	gascfePC gaspemexPC gassenerPC gasinverfPC gascosdeuePC ///
	gasinfraPC gasotrosPC gasfederPC gascostoPC ///
	IngBasPC gasmadresPC gascuidadosPC

forvalues anio = 2013(1)`=anioPE' {
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


* Abrir el archivo temporal con gasto per cápita
use "`c(sysdir_site)'/03_temp/GastoPC.dta", clear
		
* Gráfica: Gasto per cápita en educación
twoway connected iniciaA basica medsup superi posgra eduadu otrose invere cultur anio, ///
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
	rows(2)) ///
	name(GastoPC_Educacion, replace)

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
	label(7 "Inversión en salud")) ///
	name(GastoPC_Salud, replace)

* Gráfica: Gasto per cápita en pensiones
twoway connected pam penimss penisss penpeme penotro anio, ///
	title("{bf:Gasto per cápita en pensiones}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Pensión Bienestar") ///
	label(2 "Pensión IMSS") ///
	label(3 "Pensión ISSSTE") ///
	label(4 "Pensión Pemex") ///
	label(5 "Pensión CFE, LFC, ISSFAM, Ferronales")) ///
	name(GastoPC_Pensiones, replace)

* Gráfica: Gasto per cápita en energía
twoway connected gascfe gaspemex gassener gasinverf gascosdeue anio, ///
	title("{bf:Gasto per cápita en energía}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Gasto en CFE") ///
	label(2 "Gasto en Pemex") ///
	label(3 "Gasto en SENER") ///
	label(4 "Gasto en inversión (energía)") ///
	label(5 "Gasto en costo de la deuda (energía)")) ///
	name(GastoPC_Energia, replace)

* Gráfica: Gasto per cápita en otros gastos
twoway connected gasinfra gasotros gasfeder gascosto anio, ///
	title("{bf:Gasto per cápita en otros gastos}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Gasto en Otras inversiones") ///
	label(2 "Otros gastos") ///
	label(3 "Participaciones y Otras aportaciones") ///
	label(4 "Gasto en Costo de la deuda")) ///
	name(GastoPC_Otros, replace)

* Gráfica: Gasto per cápita en transferencias
twoway connected IngBas gasmadres gascuidados anio, ///
	title("{bf:Gasto per cápita en transferencias}") ///
	xtitle("") ytitle("MXN `=aniovp'") ///
	xlabel(2013(2)`=anioPE') ///
	yscale(range(0)) ///
	ylabel(, format(%9.0fc)) ///
	legend(label(1 "Ingreso básico") ///
	label(2 "Apoyo a madres trabajadoras") ///
	label(3 "Gasto en cuidados")) ///
	name(GastoPC_Transferencias, replace)
