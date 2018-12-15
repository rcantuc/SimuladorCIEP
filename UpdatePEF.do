*****************************
**** BASE DE DATOS: PEFs ****
*****************************




************************
*** 1. BASE DE DATOS ***
************************
cd "`c(sysdir_personal)'../basesCIEP/SIM/"
forvalues k=2013(1)2017 {
	unzipfile "`c(sysdir_personal)'../basesCIEP/PEFs/CP `k'.csv.zip", replace
	import delimited "`c(sysdir_personal)'../basesCIEP/SIM/CP `k'.csv", clear

	drop if ciclo == .
	tostring ramo, replace
	destring aprobado ejercido, replace

	foreach j of varlist desc_* {
		replace `j' = trim(`j')
		replace `j' = subinstr(`j',`"""',"",.)
		replace `j' = subinstr(`j',"  "," ",.)
	}

	noisily tabstat aprobado ejercido, stat(sum) by(ciclo) f(%25.0fc)

	tempfile CP`k'
	save `CP`k''
}


***************
** PEF actual **
unzipfile "`c(sysdir_personal)'../basesCIEP/PEFs/PEF 2018.csv.zip", replace
import delimited "`c(sysdir_personal)'../basesCIEP/SIM/PEF 2018.csv", clear

drop if ciclo == .
tostring ramo, replace
destring aprobado, replace ignore(",")

foreach j of varlist desc_* {
	replace `j' = trim(`j')
	replace `j' = subinstr(`j',`"""',"",.)
	replace `j' = subinstr(`j',"  "," ",.)
}

noisily tabstat aprobado, stat(sum) by(ciclo) f(%25.0fc)

tempfile CPActual
save `CPActual'


******************
** PEF siguiente **
unzipfile "`c(sysdir_personal)'../basesCIEP/PEFs/PPEF 2019.csv.zip", replace
import delimited "`c(sysdir_personal)'../basesCIEP/SIM/PPEF 2019.csv", clear

drop if ciclo == .
tostring ramo, replace
destring proyecto, replace

foreach j of varlist desc_* {
	replace `j' = trim(`j')
	replace `j' = subinstr(`j',`"""',"",.)
	replace `j' = subinstr(`j',"  "," ",.)
}

noisily tabstat proyecto, stat(sum) by(ciclo) f(%25.0fc)

tempfile CPSiguiente
save `CPSiguiente'


***********
** Append **
use `CP2013', clear
forvalues k=2014(1)2017 {
	append using `CP`k'', force
}
append using `CPActual'
append using `CPSiguiente'
capture drop v*
order proyecto aprobado ejercido modificado devengado pagado, last
format proyecto aprobado ejercido modificado devengado pagado %20.0fc


*******************
** Cuotas ISSSTE **
destring proyecto aprobado ejercido, replace ignore(",")
g new = 0

set obs `=_N+1'
replace ciclo = 2013 in -1
replace aprobado = 41139800000 in -1
replace ejercido = 44835570079.16 in -1

set obs `=_N+1'
replace ciclo = 2014 in -1
replace aprobado = 42632320001 in -1
replace ejercido = 41679970244.42 in -1

set obs `=_N+1'
replace ciclo = 2015 in -1
replace aprobado = 44496476180 in -1
replace ejercido = 36157258395.67 in -1

set obs `=_N+1'
replace ciclo = 2016 in -1
replace aprobado = 74965214148 in -1
replace ejercido = 68642820898.42 in -1

set obs `=_N+1'
replace ciclo = 2017 in -1
replace aprobado = 91005191937 in -1
replace ejercido = 93110689450 in -1

set obs `=_N+1'
replace ciclo = 2018 in -1
replace proyecto = 99233509443 in -1
replace aprobado = 99233509443 in -1

set obs `=_N+1'
replace ciclo = 2019 in -1
replace proyecto = 99233509443 in -1
replace aprobado = 99233509443 in -1

foreach k of varlist ramo-cartera {
	capture confirm numeric variable `k'
	if _rc == 0 {
		replace `k' = -1 if new == .
	}
	else {
		replace `k' = "Cuotas ISSSTE" if new == .
	}
}
drop new
*save "`c(sysdir_site)'/bases/SIM/prePEF.dta", replace




**********************/
*** 2. HOMOLOGACION ***
***********************
*use "`c(sysdir_site)'/bases/SIM/prePEF.dta", clear
foreach k of varlist _all {
	di in w ".", _cont
	capture confirm string variable `k'
	if _rc == 0 {
		quietly replace `k' = trim(`k')
	}
}


** Anio **
rename ciclo anio


** Neto **
g byte neto = (ramo == "19" & ur == "GYN") | (ramo == "19" & ur == "GYR")


** Ramo **
replace ramo = "50" if ramo == "GYR"
replace ramo = "51" if ramo == "GYN"
replace ramo = "52" if ramo == "TZZ" | ur == "TZZ"
replace ramo = "53" if ramo == "TOQ" | ur == "TOQ"
replace ramo = "-1" if ramo == "Cuotas ISSSTE"
destring ramo, replace

replace desc_ramo = "Oficina de la Presidencia de la Rep{c u'}blica" if ramo == 2
replace desc_ramo = "Instituto Nacional Electoral" if ramo == 22
replace desc_ramo = "Tribunal Federal de Justicia Administrativa" if ramo == 32
replace desc_ramo = "Instituto Nacional de Transparencia, Acceso a la Informaci{c o'}n y Protecci{c o'}n de Datos Personales" if ramo == 44

replace desc_ramo = "Petr{c o'}leos Mexicanos" if ramo == 52
replace desc_ramo = "Comisi{c o'}n Federal de Electricidad" if ramo == 53

labmask ramo, values(desc_ramo)
drop desc_ramo


** Descripci{c o'}n Unidad Responsable **
rename desc_ur desc_ur2
encode desc_ur2 if desc_ur2 != "Cuotas ISSSTE", g(desc_ur)
replace desc_ur = -1 if desc_ur == .
label define desc_ur -1 "Cuotas ISSSTE", add
drop desc_ur2


** Descripci{c o'}n Finalidad **
labmask finalidad, values(desc_finalidad)
drop desc_finalidad


** Descripci{c o'}n Funcion **
rename desc_funcion desc_funcion2
encode desc_funcion2 if desc_funcion2 != "Cuotas ISSSTE", g(desc_funcion)
replace desc_funcion = -1 if desc_funcion == .
label define desc_funcion -1 "Cuotas ISSSTE", add
drop desc_funcion2


** Descripci{c o'}n Subfuncion **
rename desc_subfuncion desc_subfuncion2
encode desc_subfuncion2 if desc_subfuncion2 != "Cuotas ISSSTE", g(desc_subfuncion)
replace desc_subfuncion = -1 if desc_subfuncion == .
label define desc_subfuncion -1 "Cuotas ISSSTE", add
drop desc_subfuncion2


** Descripci{c o'}n Actividad Institucional **
rename desc_ai desc_ai2
encode desc_ai2 if desc_ai2 != "Cuotas ISSSTE", g(desc_ai)
replace desc_ai = -1 if desc_ai == .
label define desc_ai -1 "Cuotas ISSSTE", add
drop desc_ai2


** Descripci{c o'}n Modalidad **
rename desc_modalidad desc_modalidad2
encode desc_modalidad2 if desc_modalidad2 != "Cuotas ISSSTE", g(desc_modalidad)
replace desc_modalidad = -1 if desc_modalidad == .
label define desc_modalidad -1 "Cuotas ISSSTE", add
drop desc_modalidad2


** Descripci{c o'}n Programa Presupuestario **
rename desc_pp desc_pp2
encode desc_pp2 if desc_pp2 != "Cuotas ISSSTE", g(desc_pp)
replace desc_pp = -1 if desc_pp == .
label define desc_pp -1 "Cuotas ISSSTE", add
drop desc_pp2


** Descripci{c o'}n Objeto **
rename desc_objeto desc_objeto2
encode desc_objeto2 if desc_objeto2 != "Cuotas ISSSTE", g(desc_objeto)
replace desc_objeto = -1 if desc_objeto == .
label define desc_objeto -1 "Cuotas ISSSTE", add
drop desc_objeto2


** Descripci{c o'}n Tipo de Gasto **
rename desc_tipogasto desc_tipogasto2
encode desc_tipogasto2 if desc_tipogasto2 != "Cuotas ISSSTE", g(desc_tipogasto)
replace desc_tipogasto = -1 if desc_tipogasto == .
label define desc_tipogasto -1 "Cuotas ISSSTE", add
drop desc_tipogasto2


** Descripci{c o'}n Fuente **
labmask fuente, values(desc_fuente)
drop desc_fuente


** Descripci{c o'}n Entidad Federativa **
replace desc_entidad = trim(desc_entidad)
replace desc_entidad = "Ciudad de M{c e'}xico" if entidad == 9
labmask entidad, values(desc_entidad)
drop desc_entidad


** Cap{c i'}tulo **
drop capitulo
g capitulo = substr(string(objeto),1,1) if objeto != -1
destring capitulo, replace
replace capitulo = -1 if ramo == -1

label define capitulo 1 "Servicios personales" 2 "Materiales y suministros" ///
	3 "Gastos generales" 4 "Subsidios y transferencias" ///
	5 "Bienes muebles e inmuebles" 6 "Obras p{c u'}blicas" 7 "Inversi{c o'}n financiera" ///
	8 "Participaciones y aportaciones" 9 "Deuda p{c u'}blica" -1 "Cuotas ISSSTE"
label values capitulo capitulo



*******************************
*** 3. SHCP: Datos Abiertos ***
*******************************

** Funcion **
g serie_desc_funcion = "XKG0116" if desc_funcion == -1
replace serie_desc_funcion = "XAC23" if desc_funcion == 1
replace serie_desc_funcion = "XOA0424" if desc_funcion == 2
replace serie_desc_funcion = "XOA0423" if desc_funcion == 3
replace serie_desc_funcion = "XOA0410" if desc_funcion == 4
replace serie_desc_funcion = "XOA0412" if desc_funcion == 5
replace serie_desc_funcion = "XOA0430" if desc_funcion == 6
replace serie_desc_funcion = "XOA0425" if desc_funcion == 7
replace serie_desc_funcion = "XOA0428" if desc_funcion == 8
replace serie_desc_funcion = "XOA0408" if desc_funcion == 9
replace serie_desc_funcion = "XOA0419" if desc_funcion == 10
replace serie_desc_funcion = "XOA0407" if desc_funcion == 11
replace serie_desc_funcion = "XOA0402" if desc_funcion == 12
replace serie_desc_funcion = "XOA0426" if desc_funcion == 13
replace serie_desc_funcion = "XOA0431" if desc_funcion == 14
replace serie_desc_funcion = "XOA0421" if desc_funcion == 15
replace serie_desc_funcion = "XOA0413" if desc_funcion == 16
replace serie_desc_funcion = "XOA0415" if desc_funcion == 17
replace serie_desc_funcion = "XOA0420" if desc_funcion == 18
replace serie_desc_funcion = "XOA0418" if desc_funcion == 19
replace serie_desc_funcion = "XOA0409" if desc_funcion == 20
replace serie_desc_funcion = "XOA0417" if desc_funcion == 21
replace serie_desc_funcion = "XAC2120" if desc_funcion == 22
replace serie_desc_funcion = "XOA0411" if desc_funcion == 23
replace serie_desc_funcion = "XAC21" if desc_funcion == 24
replace serie_desc_funcion = "XAC2800" if desc_funcion == 25
replace serie_desc_funcion = "XOA0427" if desc_funcion == 26
replace serie_desc_funcion = "XOA0429" if desc_funcion == 27
replace serie_desc_funcion = "XOA0416" if desc_funcion == 28

levelsof serie_desc_funcion, l(serie_desc_funcion)
rename serie_desc_funcion series
encode series, generate(serie_desc_funcion)
drop series


** Ramo **
g serie_ramo = "XKG0116" if ramo == -1
replace serie_ramo = "XDB54" if ramo ==1
replace serie_ramo = "XAC4210" if ramo == 2
replace serie_ramo = "XDB55" if ramo == 3
replace serie_ramo = "XAC4220" if ramo == 4
replace serie_ramo = "XAC4230" if ramo == 5
replace serie_ramo = "XAC4240" if ramo == 6
replace serie_ramo = "XAC4250" if ramo == 7
replace serie_ramo = "XAC4260" if ramo == 8
replace serie_ramo = "XAC4270" if ramo == 9
replace serie_ramo = "XAC4280" if ramo == 10
replace serie_ramo = "XAC4290" if ramo == 11
replace serie_ramo = "XAC4211" if ramo == 12
replace serie_ramo = "XAC4212" if ramo == 13
replace serie_ramo = "XAC4213" if ramo == 14
replace serie_ramo = "XAC4214" if ramo == 15
replace serie_ramo = "XAC4215" if ramo == 16
replace serie_ramo = "XAC4216" if ramo == 17
replace serie_ramo = "XAC4217" if ramo == 18
replace serie_ramo = "XAC4218" if ramo == 19
replace serie_ramo = "XAC4219" if ramo == 20
replace serie_ramo = "XAC4310" if ramo == 21
replace serie_ramo = "XDB56" if ramo == 22
replace serie_ramo = "XAC4320" if ramo == 23
replace serie_ramo = "XAC21" if ramo == 24
replace serie_ramo = "XAC4330" if ramo == 25
replace serie_ramo = "XAC4350" if ramo == 27
replace serie_ramo = "XAC22" if ramo == 28
replace serie_ramo = "XAC23" if ramo == 30
replace serie_ramo = "XAC4370" if ramo == 31
replace serie_ramo = "XAC4380" if ramo == 32
replace serie_ramo = "XAC4390" if ramo == 33
replace serie_ramo = "XAC2120" if ramo == 34
replace serie_ramo = "XDB57" if ramo == 35
replace serie_ramo = "XAC44" if ramo == 36
replace serie_ramo = "XAC4410" if ramo == 37
replace serie_ramo = "XAC4420" if ramo == 38
replace serie_ramo = "XDB40" if ramo == 40
replace serie_ramo = "XDB51" if ramo == 41
replace serie_ramo = "XDB52" if ramo == 42
replace serie_ramo = "XDB53" if ramo == 43
replace serie_ramo = "XDB58" if ramo == 44
replace serie_ramo = "XOA0832" if ramo == 45 | (ur == "C00" & ramo == 18)
replace serie_ramo = "XOA0833" if ramo == 46 | (ur == "D00" & ramo == 18)
replace serie_ramo = "XOA1013" if ramo == 47
replace serie_ramo = "XOA1019" if ramo == 48
replace serie_ramo = "XOA0145" if ramo == 50
replace serie_ramo = "XOA0146" if ramo == 51
replace serie_ramo = "XKC0131" if ramo == 52
replace serie_ramo = "XOA0141" if ramo == 53

levelsof serie_ramo, l(serie_ramo)
rename serie_ramo series
encode series, generate(serie_ramo)
drop series




*******************************
*** 3. SHCP: Datos Abiertos ***
*******************************
preserve
foreach k in `serie_desc_funcion' `serie_ramo' XAC5210 {
	noisily DatosAbiertos `k'

	rename clave_de_concepto serie
	keep anio serie nombre monto mes

	quietly save "`c(sysdir_personal)'../basesCIEP/SIM/`k'.dta", replace
}
restore




******************
*** 4. Modulos ***
/******************
g modulo = "uso_Pension" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) == "45" | substr(string(objeto),1,2) == "47" | pp == 176)

replace modulo = "uso_Educaci" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion == 10

replace modulo = "uso_Salud" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion == 21

replace modulo = "uso_Salud" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& (modalidad == "E" & pp == 13 & ramo == 52)




***************/
*** 5. Gasto ***
****************
g double gasto = ejercido if anio <= 2017
replace gasto = aprobado if anio == 2018
replace gasto = proyecto if anio == 2019

** Cuotas ISSSTE **
foreach k of varlist gasto aprobado ejercido proyecto {
	tempvar `k' `k'Tot `k'cuotas `k'cuotasTot

	g ``k'' = `k' if ramo != -1 & neto == 0 & (substr(string(objeto),1,1) == "1")
	replace ``k'' = 0 if ``k'' == .
	egen ``k'Tot' = sum(``k''), by(anio)

	g ``k'cuotas' = `k' if ramo == -1
	egen ``k'cuotasTot' = sum(``k'cuotas'), by(anio)

	g double `k'neto = `k' - ``k''/``k'Tot'*``k'cuotasTot'
	format `k'* %20.0fc

	g double `k'CUOTAS = ``k''/``k'Tot'*``k'cuotasTot'
	format `k'CUOTAS %20.0fc
}




*****************
*** Tipo Ramo ***
*****************
gen ramo_tipo = .
replace ramo_tipo = -1 if ramo == -1
replace ramo_tipo = 1 if ramo == 1 | ramo == 3 | ramo == 22 | ramo == 32 | ramo == 35 ///
	| ramo == 40 | ramo == 41 | ramo == 42 | ramo == 43 | ramo == 44
replace ramo_tipo = 2 if ramo == 19 | ramo == 23 | ramo == 25  | ramo == 33
replace ramo_tipo = 3 if ramo == 50 | ramo == 51
replace ramo_tipo = 4 if (ramo == 52 | ramo == 53) & capitulo != 9
replace ramo_tipo = 5 if ramo == 2 | ramo == 4 | ramo == 5 | ramo == 6  | ramo == 7  ///
	| ramo == 8  | ramo == 9 | ramo == 10 | ramo == 11  | ramo == 12  | ramo == 13  ///
	| ramo == 14 | ramo == 15 | ramo == 16  | ramo == 17  | ramo == 18  | ramo == 20 ///
	| ramo == 21 | ramo == 27  | ramo == 31  | ramo == 36  | ramo == 37 | ramo == 38 ///
	| ramo == 45  | ramo == 46 | ramo == 47  | ramo == 48
replace ramo_tipo = 6 if ramo == 24 | ramo == 28 | ramo == 30 | ramo == 34 
replace ramo_tipo = 7 if (ramo == 52 | ramo == 53) & (capitulo == 9)

label define tipos_ramo -1 "Cuotas al ISSSTE" 1 "Ramos aut{c o'}nomos" 2 "Ramos generales programables" ///
	3 "Entidades de control directo" 4 "Empresas Productivas del Estado" ///
	5 "Ramos administrativos" 7 "Gasto no programable de las empresas productivas del estado" ///
	6 "Gasto no programable del gobierno federal"
label values ramo_tipo tipos_ramo


***************
** 6. Saving **
***************
format %20.0fc ejercido aprobado proyecto
capture drop __*
order ramo* desc_ur finalidad desc_funcion desc_subfuncion desc_ai desc_modalidad ///
	desc_pp desc_objeto desc_tipogasto fuente entidad serie* ///
	proyecto aprobado ejercido 
format %30.0fc ramo desc_ur finalidad desc_funcion desc_subfuncion desc_ai desc_modalidad ///
	desc_pp desc_objeto desc_tipogasto fuente entidad serie*
format %20.0fc proyecto aprobado ejercido
compress
save "`c(sysdir_personal)'../basesCIEP/SIM/PEF.dta", replace
