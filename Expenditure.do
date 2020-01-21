******************************************
****                                  ****
**** A.2. MACRO + MICRO HARMONIZATION ****
****                                  ****
******************************************
if "`1'" == "" {
	clear all
	local macroanio = 2018
}
else {
	local macroanio = `1'
}


** D.2. Otros Parametros **
if `macroanio' >= 2018 {
	local enigh = "ENIGH"
	local enighanio = 2018
	local tasagener = 16
	local tasafront = 16
	local altimir = "yes"
}
if `macroanio' == 2016 {
	local enigh = "ENIGH"
	local enighanio = 2016
	local tasagener = 16
	local tasafront = 16
	local altimir = "no"
}
if `macroanio' == 2015 {
	local enigh = "ENIGH"
	local enighanio = 2014
	local tasagener = 16
	local tasafront = 16
	local altimir = "no"
}
if `macroanio' == 2014 {
	local enigh = "ENIGH"
	local enighanio = 2014
	local tasagener = 16
	local tasafront = 16
	local altimir = "no"
}
if `macroanio' <= 2013 {
	local enigh = "ENIGH"
	local enighanio = 2012
	local tasagener = 16
	local tasafront = 11
	local altimir = "no"
}


** D.3. Texto introductorio **
noisily di _newline(5) in g "{bf:GASTO DE LOS HOGARES:" in y " `enigh' `enighanio'}"
local data "`c(sysdir_site)'../basesCIEP/INEGI/`enigh'/`enighanio'"





****************************************
*** 1. DATOS MACROECON{c o'}MICOS (MA) ***
****************************************


** MA.1. Sistema de Cuentas Nacionales **
noisily SCN, anio(`macroanio')

local PIBSCN = scalar(PIB)

local Food = scalar(Alim)
local NBev = scalar(BebN)
local ABev = scalar(BebA)
local Toba = scalar(Taba)
local Clot = scalar(Vest)
local Foot = scalar(Calz)
local Hous = scalar(Alqu)
local Wate = scalar(Agua)
local Elec = scalar(Elec)
local Furn = scalar(Hoga)
local Heal = scalar(Salu)
local Vehi = scalar(Vehi)
local Oper = scalar(FTra)
local Tran = scalar(STra)
local Comm = scalar(Comu)
local Recr = scalar(Recr)
local Educ = scalar(Educ)
local Rest = scalar(Rest)
local Misc = scalar(Dive)
local ExpHog = scalar(ConHog)


** MA.2. SHCP: Datos Abiertos **
noisily LIF, anio(`macroanio')

local IVA = r(IVA)
local IEPS = r(IEPS__no_petrolero_)
local Ieps4 = r(Impuesto_especi_as_refrescantes)
local Ieps5 = r(Impuesto_especi_abacos_labrados)
local Ieps6 = r(Impuesto_especi_uegos_y_sorteos)
local Ieps7 = r(Impuesto_especi_ecomunicaciones)
local Ieps8 = r(Impuesto_especi__energetizantes)
local Ieps9 = r(Impuesto_especi_das_saborizadas)
local Ieps10 = r(Impuesto_especi_sidad_calórica)
local Ieps11 = r(Impuesto_especi_stibles_fosiles)
local Ieps12 = r(IEPS__petrolero_)
local Ieps13 = r(Impuesto_especi_cios_de_Alcohol)




****************************************
*** 2. DATOS MICROECON{c o'}MICOS (MI) ***
****************************************
capture confirm file "`data'/preconsumption.dta"
if _rc != 0 {


	** MI.1. Factor de expansion (cola derecha) **
	use "`data'/concentrado.dta", clear
	collapse (mean) factor, by(folioviv foliohog)
	tempfile factor
	save `factor'


	** MI.2. Base de datos de gastos de los hogares **
	use "`data'/gastospersona.dta", clear
	append using "`data'/gastohogar.dta"
	append using "`data'/gastotarjetas.dta"
	append using "`data'/erogaciones.dta"


	** MI.3. Variables sociodemograficas **
	merge m:1 (folioviv foliohog numren) using "`data'/poblacion.dta", keepus(tipoesc sexo edad) nogen
	merge m:1 (folioviv) using "`data'/vivienda.dta", keepus(ubica_geo tenencia factor) nogen
	merge m:1 (folioviv foliohog) using `factor', nogen keepus(factor)


	** MI.4. Quitar gastos no necesarios **
	// T916: gasto en regalso a personas ajenas al hogar, erogaciones financieras y de capital. 
	// N012: Pérdidas y robos de dinero
	drop if clave == "T916" | clave == "N012" //| substr(clave,1,1) == "Q"


	** MI.5. Gasto anual **
	egen gasto_anual = rsum(gas_nm_tri gasto_tri)
	replace gasto_anual = gasto_anual*4
	format gasto_anual %10.2fc


	** MI.6. Gasto en educaci{c o'}n *
	replace inscrip = 0 if inscrip == . & clave >= "E001" & clave <= "E007"
	replace colegia = 0 if colegia == . & clave >= "E001" & clave <= "E007"
	replace material = 0 if material == . & clave >= "E001" & clave <= "E007"
	replace gasto_anual = inscrip + colegia*12 + material if clave >= "E001" & clave <= "E007"


	** MI.7. Uni{c o'}n de claves de IVA y IEPS **
	merge m:1 (clave) using "`c(sysdir_site)'../basesCIEP/INEGI/ENIGH/2014/clave_iva.dta", ///
		nogen keepus(descripcion *2014 clase_de_actividad*) keep(matched master)
	encode iva2014, gen(tiva)
	tempfile pre_iva
	save `pre_iva'


	** MI.8. Uni{c o'}n de censo econ{c o'}mico **
	forvalues k=1(1)6 {
		use "`c(sysdir_site)'../basesCIEP/INEGI/Censo Economico/2014/censo_eco.dta", clear

		rename claseactividad clase_de_actividad`k'
		rename produccin produccion`k'
		rename valoragregado valoragregado`k'

		merge 1:m (clase_de_actividad`k') using `pre_iva', nogen keep(matched using)
		save `pre_iva', replace
	}
	order folioviv-porcentaje_ieps2014 *1 *2 *3 *4 *5 *6


	** MI.9. Ponderador del IVA (exentos) **
	egen agregado = rmean(valoragregado1 valoragregado2 valoragregado3 valoragregado4 valoragregado5 valoragregado6)
	egen prod = rmean(produccion1 produccion2 produccion3 produccion4 produccion5 produccion6)

	g double proporcion = agregado/prod

	tabstat proporcion [aw=factor], save
	tempname PR
	matrix `PR' = r(StatTotal)

	replace proporcion = `PR'[1,1] if clase_de_actividad1 == "000000"


	** MI.10. Estado y ubicaci{c o'}n geogr{c a'}fica ***
	g estado = substr(folioviv,1,2)
	replace ubica_geo = substr(ubica_geo,1,5)
	destring ubica_geo estado, replace

	* Frontera norte *
	g front = estado==2 | estado==3 ///
		| ubica_geo==05002 | ubica_geo==05012 | ubica_geo==05013 | ubica_geo==05014 ///
		| ubica_geo==05022 | ubica_geo==05023 | ubica_geo==05025 | ubica_geo==05038 ///
		| ubica_geo==08005 | ubica_geo==08015 | ubica_geo==08028 | ubica_geo==08035 ///
		| ubica_geo==08037 | ubica_geo==08042 | ubica_geo==08052 | ubica_geo==08053 ///
		| ubica_geo==19005 | ubica_geo==26002 | ubica_geo==26004 | ubica_geo==26017 ///
		| ubica_geo==26019 | ubica_geo==26027 | ubica_geo==26035 | ubica_geo==26039 ///
		| ubica_geo==26043 | ubica_geo==26048 | ubica_geo==26055 | ubica_geo==26059 ///
		| ubica_geo==26060 | ubica_geo==26070 | ubica_geo==28007 | ubica_geo==28014 ///
		| ubica_geo==28015 | ubica_geo==28022 | ubica_geo==28024 | ubica_geo==28025 ///
		| ubica_geo==28027 | ubica_geo==28032 | ubica_geo==28033 | ubica_geo==28040 ///
	/* Frontera sur */ ///
		| estado== 23      | ubica_geo==04010 | ubica_geo==04011 | ubica_geo==07006 ///
		| ubica_geo==07010 | ubica_geo==07015 | ubica_geo==07019 ///
		| ubica_geo==07034 | ubica_geo==07035 | ubica_geo==07036 | ubica_geo==07041 ///
		| ubica_geo==07053 | ubica_geo==07055 | ubica_geo==07057 ///
		| ubica_geo==07059 | ubica_geo==07052 | ubica_geo==07070 | ubica_geo==07087 ///
		| ubica_geo==07089 | ubica_geo==07099 | ubica_geo==07102 ///
		| ubica_geo==07105 | ubica_geo==07114 | ubica_geo==07115 | ubica_geo==07116 ///
		| ubica_geo==20079 | ubica_geo==27001 | ubica_geo==27017


	** MI.11. Variables auxiliares **
	g letra = substr(clave,1,1)
	g letra2 = substr(clave,2,1)
	replace letra2 = "" if letra2 != "R" & letra2 != "B"

	g num = substr(clave,2,.) if letra2 != "R" & letra2 != "B"
	replace num = substr(clave,3,.) if letra2 == "R" | letra2 == "B"
	destring num, replace
	replace num = num - 900 if letra == "T" & (letra2 != "R" & letra2 != "B")

	drop letra2 clase_de_actividad* produccion* valoragregado* agregado prod estado

	g publica = tipoesc == "1"
	g rentab = tenencia == "1" | tenencia == "3"


	** MI.12. SNA categor{c i'}as **
	g categ = 1 if letra == "A" & num <= 214
	replace categ = 1 if letra == "T" & num == 1

	replace categ = 2 if letra == "A" & num >= 215 & num <= 222

	replace categ = 3 if letra == "A" & num >= 223 & num <= 238

	replace categ = 4 if letra == "A" & num >= 239 & num <= 241

	replace categ = 5 if letra == "H" & num <= 83
	replace categ = 5 if letra == "T" & num == 9

	replace categ = 6 if letra == "H" & num >= 84 & num <= 122

	replace categ = 7 if letra == "G" & num <= 4
	replace categ = 7 if letra == "G" & num >= 101
	replace categ = 7 if letra == "R" & num >= 3 & num <= 4

	replace categ = 8 if letra == "R" & num == 2

	replace categ = 9 if letra == "R" & num == 1

	replace categ = 10 if letra == "G" & num >= 5 & num <= 16
	replace categ = 10 if letra == "R" & num == 13
	replace categ = 10 if letra == "K"
	replace categ = 10 if letra == "T" & num == 7
	replace categ = 10 if letra == "T" & num == 12

	replace categ = 11 if letra == "J"
	replace categ = 11 if letra == "T" & num == 11

	replace categ = 12 if letra == "M" & num >= 7 & num <= 9

	replace categ = 13 if letra == "F" & num >= 7
	replace categ = 13 if letra == "R" & num == 12

	replace categ = 14 if letra == "B"
	replace categ = 14 if letra == "M" & num <= 6
	replace categ = 14 if letra == "T" & num == 2
	replace categ = 14 if letra == "T" & num == 14

	replace categ = 15 if letra == "F" & num <= 6
	replace categ = 15 if letra == "R" & num >= 5 & num <= 11
	replace categ = 15 if letra == "T" & num == 6

	replace categ = 16 if letra == "E" & num >= 8
	replace categ = 16 if letra == "L" & num <= 26
	replace categ = 16 if letra == "T" & num == 5
	replace categ = 16 if letra == "T" & num == 13

	replace categ = 17 if letra == "E" & num <= 7

	replace categ = 18 if letra == "A" & num >= 242 & num <= 247
	replace categ = 18 if letra == "N" & num >= 3 & num <= 5

	replace categ = 19 if letra == "C"
	replace categ = 19 if letra == "D"
	replace categ = 19 if letra == "H" & num >= 123
	replace categ = 19 if letra == "I"
	replace categ = 19 if letra == "L" & num >= 27
	replace categ = 19 if letra == "M" & num >= 10 & num <= 18
	replace categ = 19 if letra == "N" & num <= 2
	replace categ = 19 if letra == "N" & num >= 6
	replace categ = 19 if letra == "T" & num == 3
	replace categ = 19 if letra == "T" & num == 4
	replace categ = 19 if letra == "T" & num == 8
	replace categ = 19 if letra == "T" & num == 10
	replace categ = 19 if letra == "T" & num == 15

	label define categ 1 "Alimentos" 2 "Bebidas no alcoh{c o'}licas" 3 "Bebidas alcoh{c o'}licas" 4 "Tabaco" ///
		5 "Prendas de vestir" 6 "Calzado" 7 "Vivienda" 8 "Agua" 9 "Electricidad" ///
		10 "Art{c i'}culos para el hogar" ///
		11 "Salud" 12 "Adquisici{c o'}n de veh{c i'}culos" 13 "Funcionamiento de transporte" ///
		14 "Servicios de transporte" ///
		15 "Comunicaciones" 16 "Recreaci{c o'}n y cultura" 17 "Educaci{c o'}n" 18 "Restaurantes y hoteles" ///
		19 "Bienes y servicios diversos"
	label values categ categ
	replace categ = 99 if categ == .	// Individuos


	** MI.13 IVA categor{c i'}as **
	g categ_iva = "alim" if letra == "A" & iva2014 == "Tasa Cero"
	replace categ_iva = "fuera" if letra == "A" & ((num >= 198 & num <= 202) | (num >= 243 & num <= 247))
	replace categ_iva = "cb" if letra == "A" & (iva2014 == "Tasa Cero" ///
		& (num >= 1 & num <= 100) | num == 102 | (num >= 137 & num <= 143) | (num >= 107 & num <= 136) ///
		| (num >= 147 & num <= 172) | (num >= 173 & num <= 175))
	replace categ_iva = "mascotas" if (letra == "L" & (num == 029)) | (letra == "A" & (num == 213 | num == 214))
	replace categ_iva = "med" if letra == "J" & (iva2014 == "Tasa Cero" ///
		& (num == 9 | num == 10 | num == 14 | (num >= 20 & num <= 27) | num == 28 | num == 29 ///
		| num == 30 | num == 31 | num == 34 | (num >= 36 & num <= 38) | num == 42 | (num >= 44 & num <= 51) ///
		| num == 54 | (num >= 53 & num <= 56) | num == 64))
	replace categ_iva = "trans" if letra == "B"
	replace categ_iva = "transf" if (letra == "M" & num == 1) | (letra == "B" & num == 6)
	replace categ_iva = "educacion" if letra == "E" & ((num >= 1 & num <= 7) | num == 16 | num == 19) //& publica == 0
	replace categ_iva = "alquiler" if letra == "G" & ((num >= 1 & num <= 3) | (num >= 101 & num <= 106))
	replace categ_iva = "otros" if categ_iva == "" & tiva != .


	** MI.14 IEPS categor{c i'}as **
	g tipoieps = 1 if (letra == "A" & (num == 222 | num == 226 | num == 228 | num == 231 | num == 232 | num == 234 | num == 238))
	replace tipoieps = 2 if (letra == "A" & num == 227)
	replace tipoieps = 3 if (letra == "A" & (num == 223 | num == 225 | num == 229 | num == 230 | num == 233 | num == 235 | num == 236))
	replace tipoieps = 4 if (letra == "A" & num == 224)
	replace tipoieps = 5 if (letra == "A" & (num >= 239 & num <= 241))
	replace tipoieps = 6 if (letra == "E" & num == 031)
	replace tipoieps = 7 if (letra == "F" & (num >= 1 & num <= 3)) ///
		| (letra == "K" & num == 3) | (letra == "R" & ((num >= 5 & num <= 7) | (num >= 9 & num <= 11)))
	replace tipoieps = 8 if (letra == "A" & num == 221)
	replace tipoieps = 9 if (letra == "A" & (num == 219 | num == 220))
	replace tipoieps = 10 if (letra == "A" & (num == 106 | (num >= 180 & num <= 182) | (num >= 205 & num <= 209)))
	replace tipoieps = 11 if (letra == "G" & (num >= 9 & num <= 11))
	replace tipoieps = 12 if (letra == "F" & (num >= 7 & num <= 9))

	label define tipoieps 1 "Alcohol 14" 2 "Alcohol 20" 3 "Alcohol 20+" 4 "Cervezas" 5 "Tabaco" ///
		6 "Juegos y sorteos" 7 "Telecomunicaciones" 8 "Bebidas energeticas" 9 "Bebidas saborizadas" ///
		10 "Comida chatarra" 11 "Combustibles fosiles" 12 "Gasolinas" 13 "Alcohol (total)"
	label values tipoieps tipoieps


	** MI.15. Coeficientes de consumo por edades **
	g alfa = 1 if edad != .
	replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
	replace alfa = .4 if edad <= 4


	** MI.16. Supuestos **
	g informal = lugar_comp == "02" | lugar_comp == "03" | lugar_comp == "17"	// Informalidad
	*replace numren = "01" if clave >= "M007" & clave <= "M009"			// Adquisicion de vehiculos (jefe del hogar)


	** MI.17. Guardar pre-base **
	capture drop __*
	save "`data'/preconsumption.dta", replace
}




********************************
*** 3. Precio, IVA, IEPS (P) ***
********************************
use "`data'/preconsumption.dta", clear


** P.1 Cantidad **
replace cantidad = cantidad*365 if frecuencia == "1"
replace cantidad = cantidad*52 if frecuencia == "2"
replace cantidad = cantidad*12 if frecuencia == "3"
replace cantidad = cantidad*4 if frecuencia == "4" | frecuencia == "5" | frecuencia == "6"	// Supuesto
replace cantidad = cantidad*52 if tipoieps != . & (frecuencia == "0" | frecuencia == "")	// Alcohol
replace cantidad = 4 if cantidad == .

replace cantidad = gasto/13.98*52 if clave == "F007"
replace cantidad = gasto/14.81*52 if clave == "F008"
replace cantidad = gasto/14.63*52 if clave == "F009"


** P.2 C{c a'}lculo de precios **
replace porcentaje_ieps = 0 if porcentaje_ieps == .
g double precio = gasto_anual ///
	/((1+`tasagener'/100)*(1+porcentaje_ieps2014/100)*cantidad) ///
	if tiva == 2 & fron == 0 ///
	& tipoieps != 9 & tipoieps != 5						// Gravados
replace precio = gasto_anual ///
	/((1+`tasagener'/100)*(1-proporcion)*(1+porcentaje_ieps2014/100)*cantidad) ///
	if tiva == 1 & fron == 0 ///
	& tipoieps != 9 & tipoieps != 5						// Exentos

replace precio = gasto_anual ///
	/((1+`tasafront'/100)*(1+porcentaje_ieps2014/100)*cantidad) ///
	if tiva == 2 & fron == 1 ///
	& tipoieps != 9 & tipoieps != 5						// Gravados frontera
replace precio = gasto_anual ///
	/((1+`tasafront'/100)*(1-proporcion)*(1+porcentaje_ieps2014/100)*cantidad) ///
	if tiva == 1 & fron == 1 ///
	& tipoieps != 9 & tipoieps != 5						// Exentos frontera

replace precio = gasto_anual/cantidad if tiva == 3				// Tasa cero


** P.3 C{c a'}lculo del IVA **
g double IVA = gasto_anual - precio*(1+porcentaje_ieps2014/100)*cantidad ///
	if informal == 0 & tiva == 2						// IVA general
replace IVA = gasto_anual - precio*(1+porcentaje_ieps2014/100)*(1-proporcion)*cantidad ///
	if informal == 0 & tiva == 1						// IVA exento
replace IVA = 0 if informal == 1 | tiva == 3					// IVA tasa cero
format IVA %10.2fc

noisily tabstat IVA [aw=factor], by(tiva) stat(sum) f(%20.0fc)


** P.4 C{c a'}lculo del IEPS **
g double IEPS = precio*porcentaje_ieps2014/100*cantidad				// Alcohol
replace IEPS = IEPS + cantidad*1000/.75*cuota_ieps2014 if tipoieps == 5		// Tabaco
replace IEPS = cantidad*cuota_ieps2014 if tipoieps == 9				// Refrescos
replace IEPS = 0 if (IEPS == . & gasto_anual != 0) //| informal == 1
format IEPS %10.2fc

noisily tabstat precio [aw=factor], by(tipoieps) f(%20.0fc)
replace tipoieps = 13 if tipoieps == 1 | tipoieps == 2 | tipoieps == 3
noisily tabstat IEPS cantidad [aw=factor], by(tipoieps) stat(sum) f(%20.0fc)



** Sankey **
g double IEPS__p = factor if clave == "F007" | clave == "F008" | clave == "F009"
g double IEPS__n = IEPS if clave != "F007" & clave != "F008" & clave != "F009"
g double CFE = gasto_anual if categ == 9
g double Importaciones = gasto_anual if lugar_comp == "08"
g double ISAN = gasto_anual if categ == 12
g double CB = gasto_anual if categ_iva == "cb"





****************************************/
*** 4. Deducciones personales del ISR ***
*****************************************
local smdf = 73.04
g deduc_trans_escolar = gasto_anual if clave == "E013"
g deduc_honor_medicos = gasto_anual if (clave >= "J001" & clave <= "J003") ///
	| (clave >= "J007" & clave <= "J008") | (clave >= "J011" & clave <= "J012") ///
	| (clave >= "J016" & clave <= "J019") | (clave >= "J039" & clave <= "J041")
g deduc_segur_medicos = gasto_anual if clave == "J071"
g deduc_gasto_funerar = min(gasto_anual,`smdf'*365) if clave == "N002"
g deduc_gasto_donativ = gasto_anual if clave == "N014"
g deduc_gasto_colegi1 = min(gasto_anual,14200) if clave == "E001"
g deduc_gasto_colegi2 = min(gasto_anual,12900) if clave == "E002"
g deduc_gasto_colegi3 = min(gasto_anual,19900) if clave == "E003"
g deduc_gasto_colegi4 = min(gasto_anual,17100) if clave == "E007"
g deduc_gasto_colegi5 = min(gasto_anual,24500) if clave == "E004"



preserve
collapse (sum) deduc_*, by(folioviv foliohog)
g proyecto = "2"
g numren = "01"
egen deduc_isr = rsum(deduc_*)
save "`c(sysdir_site)'../basesCIEP/SIM/`enighanio'/deducciones.dta", replace
restore






************************************/
*** 5. Original aggregated values ***
*************************************
tabstat gasto_anual precio IVA IEPS [aw=factor], by(categ) stat(sum) f(%20.0fc) save
forvalues k=1(1)19 {
	tempname M`k'
	matrix `M`k'' = r(Stat`k')
}
tempname MTot
matrix `MTot' = r(StatTotal)

noisily di _newline in g "{bf: A. Gasto inicial" ///
	_col(44) in g %20s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"
noisily di in g "  (+) Alimentos " ///
	_col(44) in y %20.3fc `M1'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Food'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M1'[1,1]/`Food'-1)*100 "%"
noisily di in g "  (+) Bebidas no alcoh{c o'}licas " ///
	_col(44) in y %20.3fc `M2'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `NBev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M2'[1,1]/`NBev'-1)*100 "%"
noisily di in g "  (+) Bebidas alcoh{c o'}licas " ///
	_col(44) in y %20.3fc `M3'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `ABev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M3'[1,1]/`ABev'-1)*100 "%"
noisily di in g "  (+) Tabaco " ///
	_col(44) in y %20.3fc `M4'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Toba'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M4'[1,1]/`Toba'-1)*100 "%"
noisily di in g "  (+) Prendas de vestir " ///
	_col(44) in y %20.3fc `M5'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Clot'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M5'[1,1]/`Clot'-1)*100 "%"
noisily di in g "  (+) Calzado " ///
	_col(44) in y %20.3fc `M6'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Foot'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M6'[1,1]/`Foot'-1)*100 "%"
noisily di in g "  (+) Vivienda " ///
	_col(44) in y %20.3fc `M7'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Hous'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M7'[1,1]/`Hous'-1)*100 "%"
noisily di in g "  (+) Agua " ///
	_col(44) in y %20.3fc `M8'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Wate'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M8'[1,1]/`Wate'-1)*100 "%"
noisily di in g "  (+) Electricidad " ///
	_col(44) in y %20.3fc `M9'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Elec'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M9'[1,1]/`Elec'-1)*100 "%"
noisily di in g "  (+) Art{c i'}culos para el hogar " ///
	_col(44) in y %20.3fc `M10'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Furn'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M10'[1,1]/`Furn'-1)*100 "%"
noisily di in g "  (+) Salud " ///
	_col(44) in y %20.3fc `M11'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Heal'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M11'[1,1]/`Heal'-1)*100 "%"
noisily di in g "  (+) Aquisici{c o'}n de veh{c i'}culos " ///
	_col(44) in y %20.3fc `M12'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Vehi'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M12'[1,1]/`Vehi'-1)*100 "%"
noisily di in g "  (+) Funcionamiento de transporte " ///
	_col(44) in y %20.3fc `M13'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Oper'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M13'[1,1]/`Oper'-1)*100 "%"
noisily di in g "  (+) Servicios de transporte " ///
	_col(44) in y %20.3fc `M14'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Tran'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M14'[1,1]/`Tran'-1)*100 "%"
noisily di in g "  (+) Comunicaciones " ///
	_col(44) in y %20.3fc `M15'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Comm'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M15'[1,1]/`Comm'-1)*100 "%"
noisily di in g "  (+) Recreaci{c o'}n y cultura " ///
	_col(44) in y %20.3fc `M16'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Recr'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M16'[1,1]/`Recr'-1)*100 "%"
noisily di in g "  (+) Educaci{c o'}n " ///
	_col(44) in y %20.3fc `M17'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Educ'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M17'[1,1]/`Educ'-1)*100 "%"
noisily di in g "  (+) Restaurantes y hoteles" ///
	_col(44) in y %20.3fc `M18'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Rest'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M18'[1,1]/`Rest'-1)*100 "%"
noisily di in g "  (+) Bienes y servicios diveresos " ///
	_col(44) in y %20.3fc `M19'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Misc'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M19'[1,1]/`Misc'-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di in g "{bf:  (=) Total " ///
	_col(44) in y %20.3fc `MTot'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `ExpHog'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,1]/`ExpHog'-1)*100 "}" "%"

noisily di _newline in g "{bf: B. IVA" ///
	_col(44) in g %20s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"
noisily di in g "  Total " ///
	_col(44) in y %20.3fc `MTot'[1,3]/`PIBSCN'*100 ///
	_col(66) %6.3fc `IVA'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,3]/`IVA'-1)*100 "%"
	

** IEPS **
noisily di _newline in g "{bf: C. IEPS" ///
	_col(44) in g %20s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"

tabstat IEPS [aw=factor], by(tipoieps) stat(sum) f(%20.0fc) save
tempname iepstot
matrix `iepstot' = r(StatTotal)

local k = 4
while "`=r(name`k')'" != "." {
	tempname ieps`k'
	matrix `ieps`k'' = r(Stat`k')

	noisily di in g "  (+) `=r(name`k')'" ///
		_col(44) in y %20.3fc `ieps`k''[1,1]/`PIBSCN'*100 ///
		_col(66) in y %6.3fc `Ieps`k''/`PIBSCN'*100 ///
		_col(77) in y %6.1fc (`ieps`k''[1,1]/`Ieps`k''-1)*100 "%"
	local ++k
}

noisily di in g _dup(84) "-"
noisily di in g "  IEPS " ///
	_col(44) in y %20.3fc `MTot'[1,4]/`PIBSCN'*100 ///
	_col(66) %6.3fc `IEPS'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,4]/`IEPS'-1)*100 "%"




*****************
*** 6 Altimir ***
*****************
local TFood = (`M1'[1,1]/`Food')^(-1)
local TNBev = (`M2'[1,1]/`NBev')^(-1)
local TABev = (`M3'[1,1]/`ABev')^(-1)
local TToba = (`M4'[1,1]/`Toba')^(-1)
local TClot = (`M5'[1,1]/`Clot')^(-1)
local TFoot = (`M6'[1,1]/`Foot')^(-1)
local THous = (`M7'[1,1]/`Hous')^(-1)
local TWate = (`M8'[1,1]/`Wate')^(-1)
local TElec = (`M9'[1,1]/`Elec')^(-1)
local TFurn = (`M10'[1,1]/`Furn')^(-1)
local THeal = (`M11'[1,1]/`Heal')^(-1)
local TVehi = (`M12'[1,1]/`Vehi')^(-1)
local TOper = (`M13'[1,1]/`Oper')^(-1)
local TTran = (`M14'[1,1]/`Tran')^(-1)
local TComm = (`M15'[1,1]/`Comm')^(-1)
local TRecr = (`M16'[1,1]/`Recr')^(-1)
local TEduc = (`M17'[1,1]/`Educ')^(-1)
local TRest = (`M18'[1,1]/`Rest')^(-1)
local TMisc = (`M19'[1,1]/`Misc')^(-1)

if "`altimir'" == "yes" {
	local j = 0
	foreach k in Food NBev ABev Toba Clot Foot Hous Wate Elec Furn Heal Vehi Oper ///
		Tran Comm Recr Educ Rest Misc {
		local ++j
		replace gasto_anual = gasto_anual*`T`k'' if categ == `j'
		replace precio = precio*`T`k'' if categ == `j'
		replace IVA = IVA*`T`k'' if categ == `j'
		replace IEPS = IEPS*`T`k'' if categ == `j'
		replace CB = CB*`T`k'' if categ == `j'
	}
}

tabstat gasto_anual precio IVA IEPS [aw=factor], by(categ) stat(sum) f(%20.0fc) save
forvalues k=1(1)19 {
	tempname M`k'
	matrix `M`k'' = r(Stat`k')
}
tempname MTot
matrix `MTot' = r(StatTotal)


* Display *
noisily di _newline in g "{bf: D. Gasto ajustado" ///
	_col(44) in g %20s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"
noisily di in g "  (+) Alimentos " ///
	_col(44) in y %20.3fc `M1'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Food'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M1'[1,1]/`Food'-1)*100
noisily di in g "  (+) Bebidas no alcoh{c o'}licas " ///
	_col(44) in y %20.3fc `M2'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `NBev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M2'[1,1]/`NBev'-1)*100
noisily di in g "  (+) Bebidas alcoh{c o'}licas " ///
	_col(44) in y %20.3fc `M3'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `ABev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M3'[1,1]/`ABev'-1)*100
noisily di in g "  (+) Tabaco " ///
	_col(44) in y %20.3fc `M4'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Toba'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M4'[1,1]/`Toba'-1)*100
noisily di in g "  (+) Prendas de vestir " ///
	_col(44) in y %20.3fc `M5'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Clot'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M5'[1,1]/`Clot'-1)*100
noisily di in g "  (+) Calzado " ///
	_col(44) in y %20.3fc `M6'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Foot'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M6'[1,1]/`Foot'-1)*100
noisily di in g "  (+) Vivienda " ///
	_col(44) in y %20.3fc `M7'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Hous'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M7'[1,1]/`Hous'-1)*100
noisily di in g "  (+) Agua " ///
	_col(44) in y %20.3fc `M8'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Wate'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M8'[1,1]/`Wate'-1)*100
noisily di in g "  (+) Electricidad " ///
	_col(44) in y %20.3fc `M9'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Elec'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M9'[1,1]/`Elec'-1)*100
noisily di in g "  (+) Art{c i'}culos para el hogar " ///
	_col(44) in y %20.3fc `M10'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Furn'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M10'[1,1]/`Furn'-1)*100
noisily di in g "  (+) Salud " ///
	_col(44) in y %20.3fc `M11'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Heal'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M11'[1,1]/`Heal'-1)*100
noisily di in g "  (+) Aquisici{c o'}n de veh{c i'}culos " ///
	_col(44) in y %20.3fc `M12'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Vehi'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M12'[1,1]/`Vehi'-1)*100
noisily di in g "  (+) Funcionamiento de transporte " ///
	_col(44) in y %20.3fc `M13'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Oper'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M13'[1,1]/`Oper'-1)*100
noisily di in g "  (+) Servicios de transporte " ///
	_col(44) in y %20.3fc `M14'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Tran'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M14'[1,1]/`Tran'-1)*100
noisily di in g "  (+) Comunicaciones " ///
	_col(44) in y %20.3fc `M15'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Comm'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M15'[1,1]/`Comm'-1)*100
noisily di in g "  (+) Recreaci{c o'}n y cultura " ///
	_col(44) in y %20.3fc `M16'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Recr'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M16'[1,1]/`Recr'-1)*100
noisily di in g "  (+) Educaci{c o'}n " ///
	_col(44) in y %20.3fc `M17'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Educ'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M17'[1,1]/`Educ'-1)*100
noisily di in g "  (+) Restaurantes y hoteles" ///
	_col(44) in y %20.3fc `M18'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Rest'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M18'[1,1]/`Rest'-1)*100
noisily di in g "  (+) Bienes y servicios diveresos " ///
	_col(44) in y %20.3fc `M19'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Misc'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M19'[1,1]/`Misc'-1)*100
noisily di in g _dup(84) "-"
noisily di in g "  (=) Total Consumo " ///
	_col(44) in y %20.3fc `MTot'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `ExpHog'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,1]/`ExpHog'-1)*100


noisily di _newline in g "{bf: E. IVA ajustado" ///
	_col(44) in g %20s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"
noisily di in g "  Total " ///
	_col(44) in y %20.3fc `MTot'[1,3]/`PIBSCN'*100 ///
	_col(66) %6.3fc `IVA'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,3]/`IVA'-1)*100


noisily di _newline in g "{bf: F. IEPS ajustado" ///
	_col(44) in g %20s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"

tabstat IEPS [aw=factor], by(tipoieps) stat(sum) f(%20.0fc) save
tempname iepstot
matrix `iepstot' = r(StatTotal)

local k = 4
while "`=r(name`k')'" != "." {
	tempname ieps`k'
	matrix `ieps`k'' = r(Stat`k')

	noisily di in g "  (+) `=r(name`k')'" ///
		_col(44) in y %20.3fc `ieps`k''[1,1]/`PIBSCN'*100 ///
		_col(66) in y %6.3fc `Ieps`k''/`PIBSCN'*100 ///
		_col(77) in y %6.1fc (`ieps`k''[1,1]/`Ieps`k''-1)*100 "%"
	local ++k
}

noisily di in g _dup(84) "-"
noisily di in g "  IEPS " ///
	_col(44) in y %20.3fc `MTot'[1,4]/`PIBSCN'*100 ///
	_col(66) %6.3fc `IEPS'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,4]/`IEPS'-1)*100 "%"




************************
*** 7 Gasto por edad ***
************************
collapse (sum) gasto_anual IVA IEPS__p IEPS__n ISAN CFE Importaciones CB (max) factor if edad != ., by(folioviv foliohog numren sexo edad alfa categ)
reshape wide gasto_anual IVA IEPS__p IEPS__n ISAN CFE Importaciones CB, i(folioviv foliohog numren sexo edad alfa) j(categ)

egen double gasto_anual = rsum(gasto_anual*)
egen double IVA = rsum(IVA*)
egen double IEPS__petrolero_ = rsum(IEPS__p*)
egen double IEPS__no_petrolero_ = rsum(IEPS__n*)
egen double ISAN = rsum(ISAN*)
egen double CFE = rsum(CFE*)
egen double Importaciones = rsum(Importaciones*)

egen double Food = rsum(*1)
drop *1 *2 *3 *4 *5 *6 *7 *8 *9 *10 *11 *12 *13 *14 *15 *16 *17 *18 *19 *99



**********************
** 7.2 Distribucion **
foreach k of varlist gasto_anual IVA IEPS__p IEPS__n ISAN CFE Importaciones {
	replace `k' = 0 if `k' == .
	tempvar temp0`k' temp`k'
	g double `temp0`k'' = `k' if numren == ""
	egen double `temp`k'' = sum(`temp0`k''), by(folioviv foliohog)
}
drop if numren == ""

tempvar alfatot
egen `alfatot' = sum(alfa), by(folioviv foliohog)
foreach k of varlist gasto_anual IVA IEPS__p IEPS__n ISAN CFE Importaciones {
	replace `k' = `k' + `temp`k''*alfa/`alfatot'
}


** Sankey **
g CFE_PF = CFE
label var CFE_PF "CFE (hogares)"

g CFE_PM = CFE
label var CFE_PM "CFE (empresas)"

capture drop __*
compress
save "`c(sysdir_site)'../basesCIEP/SIM/`enighanio'/expenditure.dta", replace
