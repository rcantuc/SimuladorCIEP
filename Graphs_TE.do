****
**** Gráfica histórica de las tasas efectivas
****
postfile TE double(anio ISRAS ISRPF CUOTAS IngLab 				/// Impuestos al trabajo
	ISRPM OTROSK IngCap 							/// Impuestos al capital
	IVA ISAN IEPSNP IEPSP IMPORT Consumo 					/// Impuestos al consumo
	FMP PEMEX CFE IMSS ISSSTE IngCapPub) 					/// Organismos y empresas públicas
	using `"`c(sysdir_site)'/03_temp/TE.dta"', replace

capture scalar drop ISRASTE ISRPFTE CUOTASTE ISRPMTE OTROSKTE FMPTE ///
	PEMEXTE CFETE IMSSTE ISSSTETE IVATE ISANTE IEPSNPTE IEPSPTE IMPORTTE
forvalues anio = 2001(1)`=anioPE' {
	noisily TasasEfectivas, anio(`anio')
	post TE (`anio') (`=real(ISRASTE)') (`=real(ISRPFTE)') (`=real(CUOTASTE)') (`=real(YlImpTE)') ///
		(`=real(ISRPMTE)') (`=real(OTROSKTE)') (`=real(IngKPrivadoTotTE)') ///
		(`=real(IVATE)') (`=real(ISANTE)') (`=real(IEPSNPTE)') (`=real(IEPSPTE)') (`=real(IMPORTTE)') (`=real(ingconsumoTE)') ///
		(`=real(FMPTE)') (`=real(PEMEXTE)') (`=real(CFETE)') (`=real(IMSSTE)') (`=real(ISSSTETE)') (`=real(IngKPublicosTotTE)')
}
postclose TE

* Abrir el archivo temporal con tasas efectivas
use "`c(sysdir_site)'/03_temp/TE.dta", clear

* Gráfica: Tasas efectivas por tipo de ingreso
twoway (connected IngLab anio) ///
	(connected IngCap anio) ///
	(connected Consumo anio) ///
	(connected IngCapPub anio), ///
	title("{bf:Recaudación por tipo de recurso}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(2)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "Impuestos al trabajo") ///
	label(2 "Impuestos al capital") ///
	label(3 "Impuestos al consumo") ///
	label(4 "Organismos y empresas") rows(1)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE, replace)

graph export "$export/TE.png", replace

* Calcular estadísticos para ISR asalariados
tabstat ISRAS if anio == `=anioPE' | anio == `=anioPE-25', by(anio) save
tempname ISRAS
matrix `ISRAS' = r(Stat1) \ r(Stat2)

* Gráfica: Tasas efectivas por impuestos al trabajo
twoway (connected ISRAS anio) ///
	(connected ISRPF anio) ///
	(connected CUOTAS anio), ///
	title("{bf:Impuestos al trabajo}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(2)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "ISR asalariados") ///
	label(2 "ISR personas f{c i'}sicas") ///
	label(3 "Cuotas IMSS") rows(1)) ///
	text(10 `=anioPE-25' ///
	"De `=anioPE-25' a `=anioPE', la tasa efectiva" ///
	"del {bf:ISR a asalariados}" ///
	"creció {bf:`=string(`ISRAS'[2,1]-`ISRAS'[1,1],"%5.1fc")' puntos} porcentuales.", ///
	place(3) justification(left)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Trabajo, replace)

graph export "$export/TE_Trabajo.png", replace


* Calcular estadísticos para ISR personas morales
tabstat ISRPM if anio == `=anioPE' | anio == `=anioPE-25', by(anio) save
tempname ISRPM
matrix `ISRPM' = r(Stat1) \ r(Stat2)

* Gráfica: Tasas efectivas por impuestos al capital
twoway (connected ISRPM anio) ///
	(connected OTROSK anio), ///
	title("{bf:Impuestos al capital}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(2)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "ISR personas morales") ///
	label(2 "Otros ingresos") rows(1)) ///
	text(7 `=anioPE-25' ///
	"De `=anioPE-25' a `=anioPE', la tasa efectiva" ///
	"del {bf:ISR a personas morales}" ///
	"creció {bf:`=string(`ISRPM'[2,1]-`ISRPM'[1,1],"%5.1fc")' puntos} porcentuales.", ///
	place(3) justification(left)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Capital, replace)

graph export "$export/TE_Capital.png", replace


* Gráfica: Tasas efectivas por impuestos al consumo
twoway (connected IVA anio) ///
	(connected ISAN anio) ///
	(connected IEPSNP anio) ///
	(connected IEPSP anio) ///
	(connected IMPORT anio), ///
	title("{bf:Impuestos al consumo}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(2)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "IVA") ///
	label(2 "ISAN") ///
	label(3 "IEPS (no petrolero)") ///
	label(4 "IEPS (petrolero)") ///
	label(5 "Importaciones") rows(1)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Consumo, replace)

graph export "$export/TE_Consumo.png", replace


* Gráfica: Tasas efectivas de organismos y empresas públicas
tabstat FMP, stat(min max) save
tempname FMP
matrix `FMP' = r(StatTotal)
twoway (connected FMP anio) ///
	(connected PEMEX anio) ///
	(connected CFE anio) ///
	(connected IMSS anio) ///
	(connected ISSSTE anio), ///
	title("{bf:Participación de organismos y empresas}") ///
	xtitle("") ytitle("Tasa efectiva (%)") ///
	xlabel(`=anioPE-25'(2)`=anioPE') ///
	yscale(range(0)) ///
	legend(label(1 "Derechos petroleros") ///
	label(2 "Pemex") ///
	label(3 "CFE") ///
	label(4 "IMSS") ///
	label(5 "ISSSTE") rows(1)) ///
	text(3 `=anioPE-10' ///
	"De `=anioPE-25' a `=anioPE', la tasa efectiva" ///
	"de los {bf:derechos petroleros}" ///
	"perdió {bf:`=string(`FMP'[2,1]-`FMP'[1,1],"%5.1fc")' puntos} porcentuales.", ///
	place(5) justification(left)) ///
	caption("{bf:Fuente}: Elaborado por el CIEP con información de la SHCP `=anioPE' e INEGI, BIE.") ///
	name(TE_Organismos, replace)

graph export "$export/TE_Organismos.png", replace
