


*******************
*Bases clave
*******************
PIBDeflactor
collapse deflatorpp pibYR, by (anio)
keep if anio>2017 & anio<2027
sort anio

tempfile Deflator
save"`Deflator'"



*************************GASTO MEDIO AMBIENTE********************
*Medio Ambiente*
PEF, base
keep if ramo==16

gen nueva_etiqueta_ur = ""

local valores =" 100 109 111	112	 113 114 115	116	119	121	122	123	124	125	126	127	128	130	131	132	133	134	135	136	137	138	139	140	141	142	143	144	145	146	147	148	 149 150	151	152	400	410	411	413	414	415 416 417 418 500	510	511	512	513	600	610	611	612	614 615 616 617 618	700	710	711	712	713	714	715	g00	rje	rjj"
replace nueva_etiqueta_ur = "Otros" if strpos("`valores'", ur)

local valores2 = "b00"
replace nueva_etiqueta_ur = "CONAGUA" if strpos("`valores2'", ur) 

local valores3 = "e00"
replace nueva_etiqueta_ur = "PROFEPA" if strpos("`valores3'", ur) 

local valores4 = "f00"
replace nueva_etiqueta_ur = "CONANP" if strpos("`valores4'", ur) 

local valores6 = "rhq"
replace nueva_etiqueta_ur = "CONAFOR" if strpos("`valores6'", ur) 


collapse (sum) gasto, by( anio nueva_etiqueta_ur)


********************
*****Unimos bases***
********************

merge  m:m anio using "`Deflator'"
drop _merge


****Preparamos variables***
gen gastoreal = ((gasto/deflatorpp)/1e6)

keep if anio>2017 & anio<2027

graph bar (sum) gastoreal, over(nueva_etiqueta_ur) stack asyvar over(anio) ///
ylabel(, format(%15.0fc) noticks) ///
ytitle("Millones MXN 2026", axis(1)) ///
legend(label (1 "CONAFOR") label (2 "CONAGUA") label (3 "CONANP") label (4 "Otros") label (5 "PROFEPA")) ///
blabel(, format(%20.0fc) position(center)  color("111 111 111")  size(medium)) ///
legend (cols(5)) name(medio, replace)
		   
graph export "C:\\Users\\Admin\\CIEP Dropbox\\UniversoCIEP\\PaquetesEconómicosCIEP\\Paquete Económico 2026\\4. Documento CIEP\\images\\medio.png", as(png) name(medio) replace 

graph bar (sum) gastoreal, over(nueva_etiqueta_ur) stack asyvar over(anio) ///
title("{bf:Gasto de SEMARNAT}") ///
ylabel(, format(%15.0fc) noticks) ///
ytitle("Millones MXN 2026", axis(1)) ///
legend(label (1 "CONAFOR") label (2 "CONAGUA") label (3 "CONANP") label (4 "Otros") label (5 "PROFEPA")) ///
blabel(, format(%20.0fc) position(center)  color("blak")  size(medium)) ///
legend (cols(5)) ///
caption("Fuente: Elaborado por el CIEP con información de la SHCP.")








***************************
***************************
****** Gasto por UR********
***************************
***************************

*******************
*Bases clave
*******************
LIF, nograph

* Deflator, PIB y recaudacionTOT
keep pibY deflatorpp recaudacionTOT anio
collapse (mean) pibY  deflator recaudacionTOT, by( anio )

tempfile Deflator
save"`Deflator'"



*************************GASTO MEDIO AMBIENTE********************
*Medio Ambiente*
PEF, base
keep if ramo==16

gen nueva_etiqueta_ur = ""

local valores =" 100 109 111	112	 113 114 115	116	119	121	122	123	124	125	126	127	128	130	131	132	133	134	135	136	137	138	139	140	141	142	143	144	145	146	147	148	 149 150	151	152	400	410	411	413	414	415 416 417 418 500	510	511	512	513	600	610	611	612	614 615 616 617 618	700	710	711	712	713	714	715	g00	rje	rjj"
replace nueva_etiqueta_ur = "Otros" if strpos("`valores'", ur)

local valores2 = "b00"
replace nueva_etiqueta_ur = "CONAGUA" if strpos("`valores2'", ur) 

local valores3 = "e00"
replace nueva_etiqueta_ur = "PROFEPA" if strpos("`valores3'", ur) 

local valores4 = "f00"
replace nueva_etiqueta_ur = "CONANP" if strpos("`valores4'", ur) 

local valores6 = "rhq"
replace nueva_etiqueta_ur = "CONAFOR" if strpos("`valores6'", ur) 


collapse (sum) gasto, by( anio nueva_etiqueta_ur capitulo)

********************
*****Unimos bases***
********************

merge  m:m anio using "`Deflator'"
drop _merge


****Preparamos variables***
gen gastoreal = ((gasto/deflatorpp)/1e6)


*keep if nueva_etiqueta_ur=="CONAFOR"
*keep if nueva_etiqueta_ur=="CONAGUA"
keep if nueva_etiqueta_ur=="CONANP"
*keep if nueva_etiqueta_ur=="Otros"
*keep if nueva_etiqueta_ur=="PROFEPA"


graph bar (sum) gastoreal, over( capitulo) stack asyvar over(anio) ///
/// title("{bf:Gasto en energía}") ///
ylabel(none, format(%15.0fc) noticks) ///
ytitle("", axis(1)) ///
blabel(NONE, format(%20.0fc) position(center)  color("black")  size(medium)) ///
legend (cols(7)) ///
caption("Fuente: Elaborado por el CIEP con información de la SHCP.")




graph bar (sum) gastoreal, over( capitulo) stack asyvar over(anio) ///
/// title("{bf:Gasto en energía}") ///
ylabel(none, format(%15.0fc) noticks) ///
ytitle("", axis(1)) ///
blabel(bar, format(%20.0fc) position(center)  color("black")  size(medium)) ///
legend (cols(3)) ///
caption("Fuente: Elaborado por el CIEP con información de la SHCP.")


