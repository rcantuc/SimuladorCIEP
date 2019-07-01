*****************************
**** BASE DE DATOS: PEFs ****
*****************************




************************
*** 1. BASE DE DATOS ***
************************
local archivos_csv: dir "`c(sysdir_site)'../basesCIEP/PEFs" files "*.csv"	// Busca todos los archivos .csv en /basesCIEP/PEFs/

* Loop para todos los archivos .csv *
foreach k of local archivos_csv {

	* Importar archivo de la Cuenta Publicas*
	import delimited "`c(sysdir_site)'../basesCIEP/PEFs/`k'", clear

	* Limpiar *
	capture drop v*
	drop if ciclo == .
	tostring _all, replace
	foreach j of varlist desc_* {
		replace `j' = trim(`j')
		replace `j' = subinstr(`j',`"""',"",.)
		replace `j' = subinstr(`j',"  "," ",.)
		replace `j' = subinstr(`j',"Ê"," ",.)				// Algunas bases tienen este caracter "raro".
	}

	foreach j in aprobado modificado devengado pagado adefas ejercido proyecto {
		capture destring `j', replace ignore("," "- ") 			// Ignorar coma y este otro caracter "raro".
	}

	* Save *
	tempfile `=strtoname("`k'")'						// strtoname convierte el texto en Stata var_type_name
	save ``=strtoname("`k'")''
}

** Cuotas ISSSTE **
import excel "`c(sysdir_site)'../basesCIEP/PEFs/CuotasISSSTE.xlsx", clear firstrow
tostring _all, replace
tempfile cuotasissste
save `cuotasissste'

* Loop para unir los archivos (limpios y en Stata) *
local j = 1
foreach k of local archivos_csv {
	if `j' == 1 {
		use ``=strtoname("`k'")'', clear
		local ++j
	}
	else {
		append using ``=strtoname("`k'")''
	}
}
append using `cuotasissste'

* Ordenar *
foreach k of varlist _all {
	di in w ".", _cont
	capture confirm string variable `k'
	if _rc == 0 {
		replace `k' = trim(`k')
	}
}
format aprobado ejercido modificado devengado pagado %20.0fc
capture format proyecto %20.0fc
destring _all, replace
compress




**********************/
*** 2. HOMOLOGACION ***
***********************

** Anio **
rename ciclo anio
destring anio, replace


** Transferencias del gobierno federal **
g byte transf_gf = (ramo == "19" & ur == "GYN") | (ramo == "19" & ur == "GYR")


** Finalidad **
replace desc_finalidad = "Otras" if finalidad == 4
labmask finalidad, values(desc_finalidad)
drop desc_finalidad


** Ramo **
replace ramo = "50" if ramo == "GYR"
replace ramo = "51" if ramo == "GYN"
replace ramo = "52" if ramo == "TZZ" | ur == "TZZ"
replace ramo = "53" if ramo == "TOQ" | ur == "TOQ"
destring ramo, replace

replace desc_ramo = "Oficina de la Presidencia de la Rep{c u'}blica" if ramo == 2
replace desc_ramo = "Agricultura y Desarrollo Rural" if ramo == 8
replace desc_ramo = "Desarrollo Agrario, Territorial y Urbano" if ramo == 15
replace desc_ramo = "Bienestar" if ramo == 20
replace desc_ramo = "Instituto Nacional Electoral" if ramo == 22
replace desc_ramo = "Tribunal Federal de Justicia Administrativa" if ramo == 32
replace desc_ramo = "Instituto Nacional de Transparencia, Acceso a la Informaci{c o'}n y Protecci{c o'}n de Datos Personales" if ramo == 44
replace desc_ramo = "Petr{c o'}leos Mexicanos" if ramo == 52
replace desc_ramo = "Comisi{c o'}n Federal de Electricidad" if ramo == 53

labmask ramo, values(desc_ramo)
drop desc_ramo


* Encode y agregar Cuotas ISSSTE *
foreach k of varlist desc_ur desc_funcion desc_subfuncion desc_ai desc_modalidad desc_pp ///
	desc_objeto desc_tipogasto {

	rename `k' `k'2
	encode `k'2, g(`k')

	replace `k' = -1 if `k' == .
	label define `k' -1 "Cuotas ISSSTE", add

	drop `k'2	
}


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


** Tipo de ramo **
g ramo_tipo = .
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




*************************
*** 4. Datos Abiertos ***
/*************************

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

preserve
foreach k in `serie_desc_funcion' `serie_ramo' XAC5210 {
	noisily DatosAbiertos `k', g

	rename clave_de_concepto serie
	keep anio serie nombre monto mes

	*quietly save "`c(sysdir_personal)'../basesCIEP/SIM/`k'.dta", replace
}
restore




*****************/
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




********************/
*** 5. Gasto Neto ***
*********************
g double gasto = ejercido if ejercido != .
replace gasto = aprobado if aprobado != . & gasto == .

** Cuotas ISSSTE **
foreach k of varlist gasto aprobado ejercido {
	tempvar `k' `k'Tot `k'cuotas `k'cuotasTot

	g ``k'' = `k' if ramo != -1 & transf_gf == 0 & (substr(string(objeto),1,1) == "1")	// Identificar salarios
	replace ``k'' = 0 if ``k'' == .
	egen ``k'Tot' = sum(``k''), by(anio)					// Salarios Totales por anio

	g ``k'cuotas' = `k' if ramo == -1					// Identificar cuotas
	egen ``k'cuotasTot' = sum(``k'cuotas'), by(anio)			// Cuotas Totales por anio

	g double `k'neto = `k' - ``k''/``k'Tot'*``k'cuotasTot'			// Netear de cuotas ISSSTE
	g double `k'CUOTAS = ``k''/``k'Tot'*``k'cuotasTot'			// Cuotas ISSSTE
}
format *CUOTAS *neto %20.0fc




***************
** 6. Saving **
***************
capture drop __*
drop cartera modalidad

order aprobado ejercido modificado devengado pagado, last
capture order proyecto, last

order ramo* desc_ur finalidad desc_funcion desc_subfuncion desc_ai desc_modalidad ///
	desc_pp desc_objeto desc_tipogasto fuente entidad

format %30.0fc ramo desc_ur finalidad desc_funcion desc_subfuncion desc_ai desc_modalidad ///
	desc_pp desc_objeto desc_tipogasto fuente entidad
	

compress
save "`c(sysdir_site)'../basesCIEP/SIM/PEF.dta", replace
