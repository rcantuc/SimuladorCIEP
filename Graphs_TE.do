****
**** Gráfica histórica de las tasas efectivas
****
noisily LIF if divLIF != 10, anio(`=anioPE') by(divOrigen) $update 		///
	title("Ingresos presupuestarios") 					/// Cambiar título de la gráfica
	desde(2010) 							/// Año de inicio para el PROMEDIO
	min(0) 									/// Mínimo 0% del PIB (no negativos)
	rows(1)									//  Número de filas en la leyenda

postfile TE double(anio ISRAS ISRPF CUOTAS IngLab 				/// Impuestos al trabajo
	ISRPM OTROSK IngCap 							/// Impuestos al capital
	IVA ISAN IEPSNP IEPSP IMPORT Consumo 					/// Impuestos al consumo
	FMP PEMEX CFE IMSS ISSSTE IngCapPub) 					/// Organismos y empresas públicas
	using `"`c(sysdir_site)'/03_temp/TE.dta"', replace
	capture scalar drop ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA ISAN IEPSNP IEPSP IMPORT

forvalues anio = 2010(1)`=anioPE' {
	noisily TasasEfectivas, anio(`anio')
	post TE (`anio') (`=ISRASPor') (`=ISRPFPor') (`=CUOTASPor') (`=YlImpPor') ///
		(`=ISRPMPor') (`=OTROSKPor') (`=IngKPrivadoTotPor') ///
		(`=IVAPor') (`=ISANPor') (`=IEPSNPPor') (`=IEPSPPor') (`=IMPORTPor') (`=ingconsumoPor') ///
		(`=FMPPor') (`=PEMEXPor') (`=CFEPor') (`=IMSSPor') (`=ISSSTEPor') (`=IngKPublicosTotPor')
}
postclose TE

* Abrir el archivo temporal con tasas efectivas
use "`c(sysdir_site)'/03_temp/TE.dta", clear
	* Gráfica: Tasas efectivas por tipo de ingreso
twoway (connected IngLab anio) ///
	(connected IngCap anio, lcolor(%50) lpattern(solid)) ///
	(connected Consumo anio) ///
	(connected IngCapPub anio, lcolor(%50) lpattern(solid)), ///
	title("{bf:Tasas efectivas por tipos de ingreso}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(1)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "Impuestos al trabajo") ///
	label(2 "Impuestos al capital") ///
	label(3 "Impuestos al consumo") ///
	label(4 "Ingresos por organismos y empresas")) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE, replace)

	* Calcular estadísticos para ISR asalariados
tabstat ISRAS if anio == `=anioPE' | anio == `=anioPE-25', by(anio) save
tempname ISRAS
matrix `ISRAS' = r(Stat1) \ r(Stat2)
	* Gráfica: Tasas efectivas por impuestos al trabajo
twoway (connected ISRAS anio, lcolor(%50) lpattern(solid)) ///
	(connected ISRPF anio) ///
	(connected CUOTAS anio), ///
	title("{bf:Tasas efectivas por impuestos al trabajo}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(1)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "ISR asalariados") ///
	label(2 "ISR personas f{c i'}sicas") ///
	label(3 "Cuotas IMSS")) ///
	text(`=`ISRAS'[2,1]' `=anioPE-25' ///
	"De `=anioPE-25' a `=anioPE', la tasa efectiva" ///
	"del {bf:ISR a asalariados}" ///
	"creció {bf:`=string(`ISRAS'[2,1]-`ISRAS'[1,1],"%5.1fc")' puntos} porcentuales.", ///
	place(3) justification(left)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Trabajo, replace)

	* Calcular estadísticos para ISR personas morales
tabstat ISRPM if anio == `=anioPE' | anio == `=anioPE-25', by(anio) save
tempname ISRPM
matrix `ISRPM' = r(Stat1) \ r(Stat2)
	* Gráfica: Tasas efectivas por impuestos al capital
twoway (connected ISRPM anio, lcolor(%50) lpattern(solid)) ///
	(connected OTROSK anio), ///
	title("{bf:Tasas efectivas por impuestos al capital}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(1)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "ISR personas morales") ///
	label(2 "Otros ingresos")) ///
	text(`=`ISRAS'[2,1]' `=anioPE-25' ///
	"De `=anioPE-25' a `=anioPE', la tasa efectiva" ///
	"del {bf:ISR a personas morales}" ///
	"creció {bf:`=string(`ISRPM'[2,1]-`ISRPM'[1,1],"%5.1fc")' puntos} porcentuales.", ///
	place(3) justification(left)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Capital, replace)

	* Gráfica: Tasas efectivas por impuestos al consumo
twoway (connected IVA anio) ///
	(connected ISAN anio) ///
	(connected IEPSNP anio, lcolor(%50) lpattern(solid)) ///
	(connected IEPSP anio, lcolor(%50) lpattern(solid)) ///
	(connected IMPORT anio), ///
	title("{bf:Tasas efectivas por impuestos al consumo}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(1)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "IVA") ///
	label(2 "ISAN") ///
	label(3 "IEPS (no petrolero)") ///
	label(4 "IEPS (petrolero)") ///
	label(5 "Importaciones")) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Consumo, replace)

	* Calcular estadísticos para organismos y empresas públicas
tabstat FMP, stat(min max) save
tempname FMP
matrix `FMP' = r(StatTotal)
twoway (connected FMP anio, lcolor(%50) lpattern(solid)) ///
	(connected PEMEX anio, lcolor(%50) lpattern(solid)) ///
	(connected CFE anio) ///
	(connected IMSS anio) ///
	(connected ISSSTE anio), ///
	title("{bf:Tasas efectivas por ingresos de organismos y empresas}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(1)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "Fondo Mexicano del Petróleo") ///
	label(2 "Pemex") ///
	label(3 "CFE") ///
	label(4 "IMSS") ///
	label(5 "ISSSTE")) ///
	text(`=`FMP'[2,1]' `=anioPE-10' ///
	"De `=anioPE-25' a `=anioPE', la tasa efectiva" ///
	"del {bf:Fondo Mexicano del Petróleo}" ///
	"perdió {bf:`=string(`FMP'[2,1]-`FMP'[1,1],"%5.1fc")' puntos} porcentuales.", ///
	place(5) justification(left)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Organismos, replace)


exit
* ==============================================
* Generación de archivo temporal con gasto per cápita
* ==============================================
postfile GastoPC double(anio iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
	ssa imssbien imss issste pemex issfam invers ///
	pam penimss penisss penpeme penotro ///
	gascfe gaspemex gassener gasinverf gascosdeue ///
	gasinfra gasotros gasfeder gascosto ///
	IngBas gasmadres gascuidados) ///
	using `"`c(sysdir_site)'/03_temp/GastoPC.dta"', replace
	capture scalar drop iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
		ssa imssbien imss issste pemex issfam invers ///
		pam penimss penisss penpeme penotro ///
		gascfe gaspemex gassener gasinverf gascosdeue ///
		gasinfra gasotros gasfeder gascosto ///
		IngBas gasmadres gascuidados
	noisily GastoPC, aniope(`anio') aniovp(`=aniovp')
	post GastoPC (`anio') (`=iniciaA') (`=basica') (`=medsup') (`=superi') ///
		(`=posgra') (`=eduadu') (`=otrose') (`=invere') (`=cultur') (`=invest') ///
		(`=ssa') (`=imssbien') (`=imss') (`=issste') (`=pemex') (`=issfam') (`=invers') ///
		(`=pam') (`=penimss') (`=penisss') (`=penpeme') (`=penotro') ///
		(`=gascfe') (`=gaspemex') (`=gassener') (`=gasinverf') (`=gascosdeue') ///
		(`=gasinfra') (`=gasotros') (`=gasfeder') (`=gascosto') ///
		(`=IngBas') (`=gasmadres') (`=gascuidados')
postclose GastoPC


* ==============================================
* 3.2.3 Gráficas de gastos per cápita
* ==============================================
if "$nographs" != "nographs" {
		* Abrir el archivo temporal con gasto per cápita
	use "`c(sysdir_site)'/03_temp/GastoPC.dta", clear
		* Gráfica: Gasto per cápita en educación
	twoway connected iniciaA basica medsup superi posgra eduadu otrose invere cultur anio, ///
		title("{bf:Gasto per cápita en educación}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
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
		xlabel(`=anioPE-10'(1)`=anioPE') ///
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
		xlabel(`=anioPE-10'(1)`=anioPE') ///
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
		xlabel(`=anioPE-10'(1)`=anioPE') ///
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
		xlabel(`=anioPE-10'(1)`=anioPE') ///
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
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		yscale(range(0)) ///
		ylabel(, format(%9.0fc)) ///
		legend(label(1 "Ingreso básico") ///
		label(2 "Apoyo a madres trabajadoras") ///
		label(3 "Gasto en cuidados")) ///
		name(GastoPC_Transferencias, replace)
}
