*************************
****                 ****
**** UpdatePEF.do    ****
**** De .xlsx a .dta ****
****                 ****
*************************



*************************
***                   ***
*** 1. BASES DE DATOS ***
***                   ***
*************************
local archivos: dir "`c(sysdir_site)'/bases/PEFs/$pais" files "*.xlsx"			// Busca todos los archivos .xlsx en /bases/PEFs/
*local archivos `""CuotasISSSTE.xlsx" "CP 2020.xlsx""'

foreach k of local archivos {													// Loop para todos los archivos .csv

	* 1.1 Importar el archivo `k'.xlsx (Cuenta Pública) *
	noisily di in g "Importando: " in y "`k'"
	import excel "`c(sysdir_site)'/bases/PEFs/$pais/`k'", clear firstrow case(lower)

	* 1.2 Limpiar observaciones *
	capture drop if ciclo == ""
	capture drop if ciclo == .
	capture rename ciclo anio

	* 1.3 Limpiar nombres *
	capture rename ejercicio ejercido
	foreach j of varlist _all {
		if `"`=substr("`j'",1,3)'"' == "id_" {
			local newname = `"`=substr("`j'",4,.)'"'
			capture rename `j' `newname'
			if _rc != 0 {
				rename `newname' desc_`newname'
				rename `j' `newname'				
			}
			local j = "`newname'"
		}
		if `"`=substr("`j'",1,6)'"' == "monto_" {
			local newname = `"`=substr("`j'",7,.)'"'
			rename `j' `newname'	
			local j = "`newname'"
		}
		if "`j'" == "objeto_del_gasto" | "`j'" == "concepto" {
			rename `j' objeto
			local j = "objeto"
		}
		if "`j'" == "desc_objeto_del_gasto" | "`j'" == "desc_concepto" {
			rename `j' desc_objeto
			local j = "desc_objeto"
		}
		if "`j'" == "desc_gpo_funcional" {
			rename `j' desc_finalidad
			local j = "desc_finalidad"
		}
		if "`j'" == "gpo_funcional" {
			rename `j' finalidad
			local j = "finalidad"
		}
		if "`j'" == "ff" {
			rename `j' fuente
			local j = "fuente"
		}
		if "`j'" == "desc_ff" {
			rename `j' desc_fuente
			local j = "desc_fuente"
		}
		if "`j'" == "desc_entidad_federativa" {
			rename `j' desc_entidad
			local j = "desc_entidad"
		}
		if "`j'" == "entidad_federativa" {
			capture rename `j' entidad
		}
	}

	* 1.4 Limpiar valores *
	capture drop v*
	foreach j of varlist _all {
		tostring `j', replace													// Primero, que todos sean strings (facilidad)
		capture confirm string variable `k'										// Segundo, comprobar que la variable sea string (no siempre el tostring funciona)
		if _rc == 0 {															// Tercero, si es string, quitar espacios y caracteres especiales
			replace `j' = trim(`j')
			replace `j' = subinstr(`j',`"""',"",.)
			replace `j' = subinstr(`j',"  "," ",.)
			replace `j' = subinstr(`j',"Ê"," ",.)								// <--Algunas CPs tienen este caracter "raro".
			replace `j' = subinstr(`j',"Â","",.)
			replace `j' = subinstr(`j'," "," ",.)
			replace `j' = subinstr(`j'," "," ",.)
			format `j' %30s
		}
		destring `j', replace													// Cuarto, hacer numéricas las variables posibles
	}

	* Quinto, asegurar que las variables de gasto sean numéricas. 
	foreach j in aprobado modificado devengado pagado adefas ejercido proyecto {
		capture destring `j', replace ignore(",") 								// Ignorar las comas
		if _rc == 0 {
			format `j' %20.0fc
		}
	}
	capture tostring ramo, replace

	* 1.5 Save *
	tempfile `=strtoname("`k'")'												// strtoname convierte el texto en Stata var_type_name
	save ``=strtoname("`k'")''
}

* Sexto, loop para unir los archivos ya limpios y en formato Stata *
local j = 0
foreach k of local archivos {
*foreach k in "CP 2019" {														// <-- Dejar para hacer pruebas
	noisily di in g "Appending: " in y "`k'"
	if `j' == 0 {
		use ``=strtoname("`k'")'', clear
		local ++j
	}
	else {
		append using ``=strtoname("`k'")'', force
	}
}
compress																		// <-- Para hacer "más eficiente" la base (menor tamaño).





**********************************/
***                             ***
*** 2. HOMOLOGACION DE TÉRMINOS ***
***                             ***
***********************************

** 2.1 Finalidad **
replace desc_finalidad = "Otras" if finalidad == 4
capture labmask finalidad, values(desc_finalidad)
if _rc == 199 {
	net install labutil.pkg
	labmask finalidad, values(desc_finalidad)
}
drop desc_finalidad

** 2.2 Ramo **
replace ramo = "50" if ramo == "GYR"
replace ramo = "51" if ramo == "GYN"
replace ramo = "52" if ramo == "TZZ" | ur == "TZZ"
replace ramo = "53" if ramo == "TOQ" | ur == "TOQ"
destring ramo, replace

replace desc_ramo = "Oficina de la Presidencia de la República" if ramo == 2
replace desc_ramo = "Agricultura y Desarrollo Rural" if ramo == 8
replace desc_ramo = "Desarrollo Agrario, Territorial y Urbano" if ramo == 15
replace desc_ramo = "Bienestar" if ramo == 20
replace desc_ramo = "Instituto Nacional Electoral" if ramo == 22
replace desc_ramo = "Tribunal Federal de Justicia Administrativa" if ramo == 32
replace desc_ramo = "Seguridad y Protección Ciudadana" if ramo == 36
replace desc_ramo = "Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales" if ramo == 44
replace desc_ramo = "Petróleos Mexicanos" if ramo == 52
replace desc_ramo = "Comisión Federal de Electricidad" if ramo == 53
replace desc_ramo = "Comisión Federal de Electricidad" if ramo == 53
replace desc_ramo = "Infraestructura, Comunicaciones y Transportes" if ramo == 9

labmask ramo, values(desc_ramo)
drop desc_ramo

** 2.3 Descripción Entidad Federativa **
replace desc_entidad = trim(desc_entidad)
replace entidad = 34 if entidad == .
replace desc_entidad = "Aguascalientes" if entidad == 1
replace desc_entidad = "Baja California" if entidad == 2
replace desc_entidad = "Baja California Sur" if entidad == 3
replace desc_entidad = "Campeche" if entidad == 4
replace desc_entidad = "Coahuila" if entidad == 5
replace desc_entidad = "Colima" if entidad == 6
replace desc_entidad = "Chiapas" if entidad == 7
replace desc_entidad = "Chihuahua" if entidad == 8
replace desc_entidad = "Ciudad de México" if entidad == 9
replace desc_entidad = "Durango" if entidad == 10
replace desc_entidad = "Guanajuato" if entidad == 11
replace desc_entidad = "Guerrero" if entidad == 12
replace desc_entidad = "Hidalgo" if entidad == 13
replace desc_entidad = "Jalisco" if entidad == 14
replace desc_entidad = "Estado de México" if entidad == 15
replace desc_entidad = "Michoacán" if entidad == 16
replace desc_entidad = "Morelos" if entidad == 17
replace desc_entidad = "Nayarit" if entidad == 18
replace desc_entidad = "Nuevo León" if entidad == 19
replace desc_entidad = "Oaxaca" if entidad == 20
replace desc_entidad = "Puebla" if entidad == 21
replace desc_entidad = "Querétaro" if entidad == 22
replace desc_entidad = "Quintana Roo" if entidad == 23
replace desc_entidad = "San Luis Potosí" if entidad == 24
replace desc_entidad = "Sinaloa" if entidad == 25
replace desc_entidad = "Sonora" if entidad == 26
replace desc_entidad = "Tabasco" if entidad == 27
replace desc_entidad = "Tamaulipas" if entidad == 28
replace desc_entidad = "Tlaxcala" if entidad == 29
replace desc_entidad = "Veracruz" if entidad == 30
replace desc_entidad = "Yucatán" if entidad == 31
replace desc_entidad = "Zacatecas" if entidad == 32
replace desc_entidad = "En El Extranjero" if entidad == 33
replace desc_entidad = "No Distribuible Geográficamente" if entidad == 34
labmask entidad, values(desc_entidad)
drop desc_entidad

** 2.4 Capítulo de gasto **
capture drop capitulo
g capitulo = substr(string(objeto),1,1) if objeto != -1
destring capitulo, replace
replace capitulo = -1 if ramo == -1

label define capitulo 1 "Servicios personales" 2 "Materiales y suministros" ///
	3 "Gastos generales" 4 "Subsidios y transferencias" ///
	5 "Bienes muebles e inmuebles" 6 "Obras públicas" 7 "Inversión financiera" ///
	8 "Participaciones y aportaciones" 9 "Deuda pública" -1 "Cuotas ISSSTE"
label values capitulo capitulo

** 2.5 Tipo de ramo **
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

label define tipos_ramo -1 "Cuotas al ISSSTE" 1 "Ramos autónomos" 2 "Ramos generales programables" ///
	3 "Entidades de control directo" 4 "Empresas Productivas del Estado" ///
	5 "Ramos administrativos" 7 "Gasto no programable de las empresas productivas del estado" ///
	6 "Gasto no programable del gobierno federal"
label values ramo_tipo tipos_ramo

** 2.6 Encode y agregar Cuotas ISSSTE **
foreach k of varlist desc_ur desc_funcion desc_subfuncion desc_ai desc_modalidad desc_pp ///
	desc_objeto desc_tipogasto /*desc_partida_generica*/ {

	rename `k' `k'2
	encode `k'2, g(`k')
	format %30.0fc `k'
	drop `k'2	

	replace `k' = -1 if `k' == .
	label define `k' -1 "Cuotas ISSSTE", add
}





*********************************
***                           ***
*** 3. ESTADÍSTICAS OPORTUNAS ***
***                           ***
*********************************

** 3.1 Función **
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

** 3.2 Ramo **
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

tempfile prePEF
save `prePEF'


* 3.3 Datos Abiertos: PEFEstOpor.dta *
levelsof serie_desc_funcion, local(serie)
foreach k of local serie {
	noisily DatosAbiertos `k', nog

	rename clave_de_concepto serie
	keep anio serie nombre monto mes acum_prom

	tempfile `k'
	quietly save ``k''
}


** 2.1.1 Append **
local j = 0
foreach k of local serie {
	if `j' == 0 {
		use ``k'', clear
		local ++j
	}
	else {
		append using ``k''
	}
}

rename serie series
encode series, generate(serie)
drop series

capture drop __*
compress
if `c(version)' > 13.1 {
	saveold "`c(sysdir_site)'/SIM/$pais/GastoEstOpor.dta", replace version(13)
}
else {
	save "`c(sysdir_site)'/SIM/$pais/GastoEstOpor.dta", replace
}





***************************************/
***                                  ***
*** 4. Modulos SIMULADOR FISCAL CIEP ***
***                                  ***
****************************************
use `prePEF', clear

* 4.1 Costo de la deuda *
g desc_divPE = "Costo de la deuda" if capitulo == 9 //& substr(string(objeto),1,2) != "91"
*replace desc_divPE = "Amortización" if capitulo == 9 & substr(string(objeto),1,2) == "91"

* 4.2 Pensiones *
levelsof desc_pp, local(levelsof)
local ifpp "("
foreach k of local levelsof {
	local label : label desc_pp `k'
	if `"`label'"' == "Pensión para Adultos Mayores" | ///
		`"`label'"' == "Pensión para el Bienestar de las Personas Adultas Mayores" | ///
		`"`label'"' == "Pensión para el Bienestar de las Personas con Discapacidad Permanente" {
		local ifpp `"`ifpp'desc_pp == `k' | "'
	}
}
local ifpp `"`=substr("`ifpp'",1,`=strlen("`ifpp'")-3')')"'
replace desc_divPE = "Pensiones" if desc_divPE == "" ///
	& (substr(string(objeto),1,2) == "45" | substr(string(objeto),1,2) == "47")	// Pensiones contributivas
replace desc_divPE = "Pensiones" if desc_divPE == "" & `ifpp'				// Pensión Bienestar

* 4.3 Educacion *
replace desc_divPE = "Educación" if desc_divPE == "" ///
	& (desc_funcion == 10 | ramo == 11 | ramo == 48 | ramo == 38)

* 4.4 Salud *
replace desc_divPE = "Salud" if desc_divPE == "" ///
	& (desc_funcion == 21 | ramo == 12)
replace desc_divPE = "Salud" if desc_divPE == "" ///
	& ramo == 50 & pp == 4 & funcion == 8
replace desc_divPE = "Salud" if desc_divPE == "" ///
	& ramo == 51 & pp == 15 & funcion == 8
replace desc_divPE = "Salud" if desc_divPE == "" ///
	& ramo == 52 & ai == 231

* 4.5 Federalizado *
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& (ramo == 28 | ramo == 33 | ramo == 25) 				// Part + Aport
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& partida_generica == 438													// Convenios y Subsidios
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& (objeto == 43801 | (objeto == 46101 & ramo == 23 & pp == 80))		// Convenios y Subsidios
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& (partida_generica == 461 & ramo == 23 & pp == 80) 			// FEIEF
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& (ramo == 23 & pp == 4) 						// FEIEF 2
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& (ramo == 23 & pp == 141) 						// FIES
replace desc_divPE = "Federalizado" if desc_divPE == "" ///
	& (pp == 13 & ramo == 12 & modalidad == "U") 				// INSABI

* 4.6 Energía *
replace desc_divPE = "Energía" if desc_divPE == "" & ///
	(ramo == 18 | ramo == 45 | ramo == 46 | ramo == 52 | ramo == 53)
replace desc_divPE = "Energía" if desc_divPE == "" & ///
	(ramo == 23 & desc_funcion == 7)

* 4.7 Infraestructura *
replace desc_divPE = "Inversión" if desc_divPE == "" ///
	& (desc_tipogasto == 4 | desc_tipogasto == 5 | desc_tipogasto == 6 | desc_tipogasto == 8)

* 4.8 Otros *
replace desc_divPE = "Otros" if desc_divPE == ""

* 4.9 Cuotas ISSSTE *
replace desc_divPE = "zCuotas ISSSTE" if ramo == -1
encode desc_divPE, generate(divPE)
replace desc_divPE = "Cuotas ISSSTE" if ramo == -1
replace divPE = -1 if ramo == -1
label define divPE -1 "Cuotas ISSSTE", add
label define divPE 9 "", modify




**************************
***                    ***
*** 5. NETEO DEL GASTO ***
***                    ***
**************************
capture g double gasto = ejercido
if _rc != 0 {
	capture g double gasto = devengado
}
if _rc != 0 {
	g double gasto = aprobado
}
replace gasto = aprobado if gasto == .

g byte transf_gf = (ramo == 19 & ur == "GYN") | (ramo == 19 & ur == "GYR")

** Cuotas ISSSTE **
foreach k of varlist gasto aprobado ejercido proyecto {
	tempvar `k' `k'Tot `k'cuotas `k'cuotasTot

	g ``k'' = `k' if ramo != -1 & transf_gf == 0 & (substr(string(objeto),1,1) == "1")	// Identificar salarios
	replace ``k'' = 0 if ``k'' == .
	egen ``k'Tot' = sum(``k''), by(anio)										// Salarios Totales por anio

	g ``k'cuotas' = `k' if ramo == -1											// Identificar cuotas
	egen ``k'cuotasTot' = sum(``k'cuotas'), by(anio)							// Cuotas Totales por anio

	g double `k'neto = `k' - ``k''/``k'Tot'*``k'cuotasTot'						// Netear de cuotas ISSSTE
	g double `k'CUOTAS = ``k''/``k'Tot'*``k'cuotasTot'							// Cuotas ISSSTE
}
format *CUOTAS *neto %20.0fc





****************/
***           ***
*** 6. SAVING ***
***           ***
*****************
capture order ejercido, last
capture order aprobado modificado devengado pagado, last
capture order proyecto, last
capture drop __*
compress
if `c(version)' > 13.1 {
	saveold "`c(sysdir_site)'/SIM/$pais/PEF.dta", replace version(13)
}
else {
	save "`c(sysdir_site)'/SIM/$pais/PEF.dta", replace
}
