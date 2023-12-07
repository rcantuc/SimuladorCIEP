******************************************************************
****                                                          ****
**** A.2. MACRO + MICRO HARMONIZATION: HOUSEHOLD EXPENDITURES ****
****                                                          ****
******************************************************************



*********************
***               ***
***  0. Defaults  ***
***               ***
*********************
timer on 15
if "`1'" == "" {
	local enighanio = 2022
}
else {
	if `1' >= 2022 {
		local enighanio = 2022
	}
	if `1' >= 2020 & `1' < 2022 {
		local enighanio = 2020
	}
	if `1' >= 2018 & `1' < 2020 {
		local enighanio = 2018
	}
	if `1' >= 2016 & `1' < 2018 {
		local enighanio = 2016
	}
	if `1' >= 2014 & `1' < 2016 {
		local enighanio = 2014
	}
	if `1' >= 2012 & `1' < 2014 {
		local enighanio = 2012
	}
}


** 0.1 Otros Parametros **
if `enighanio' >= 2014 {
	local tasagener = 16
	local tasafront = 16
	local altimir = "yes"
}
if `enighanio' == 2012 {
	local tasagener = 16
	local tasafront = 11
	local altimir = "yes"
}


** 0.2 Directorios y log files **
capture mkdir "`c(sysdir_personal)'/SIM/`enighanio'/"
capture log close expenditures
log using "`c(sysdir_personal)'/SIM/`enighanio'/expenditures.smcl", replace name(expenditures)


** 0.3 Texto introductorio **
noisily di _newline(2) in g _dup(20) "." "{bf:  Gastos de los hogares " in y "ENIGH `enighanio'" "  }" in g _dup(20) "."





**********************************
***                            ***
***  1. DATOS MACROECONóMICOS  ***
***                            ***
**********************************

** 1.1 Sistema de Cuentas Nacionales **
SCN, anio(`enighanio') nographs


** 1.2 SHCP: Datos Abiertos **
LIF, anio(`enighanio') by(divCIEP) nographs
local IVA = r(IVA)
local IEPS = r(IEPS__no_petrolero_)+r(IEPS__petrolero_)
local Ieps1 = r(Cervezas)
local Ieps2 = r(Tabacos)
local Ieps3 = r(Juegos)
local Ieps4 = r(Telecom)
local Ieps5 = r(Energiza)
local Ieps6 = r(Saboriza)
local Ieps7 = r(AlimNoBa)
local Ieps8 = r(Fosiles)
local Ieps9 = r(IEPS__petrolero_)
local Ieps10 = r(Alcohol)


** 1.3 Población **
Poblacion, anio(`enighanio') nographs





**********************************
***                            ***
***  2. DATOS MICROECONóMICOS  ***
***                            ***
**********************************
capture confirm file "`c(sysdir_personal)'/SIM/`enighanio'/preconsumption.dta"
*if _rc != 0 {
if _rc == 0 {

	** MI.1. Base de datos de gastos de los hogares **
	use "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/gastospersona.dta", clear
	append using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/gastohogar.dta"
	append using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/gastotarjetas.dta"
	append using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/erogaciones.dta"
	replace numren = "01" if clave >= "M007" & clave <= "M009"		// Adquisicion de vehiculos (jefe del hogar)

	** MI.2. Variables sociodemograficas **
	merge m:1 (folioviv foliohog numren) using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/poblacion.dta", keepus(tipoesc sexo edad) nogen update replace
	merge m:1 (folioviv foliohog) using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/concentrado.dta", nogen keepus(factor tot_integ) update replace
	merge m:1 (folioviv) using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/vivienda.dta", keepus(ubica_geo tenencia) nogen update replace
	capture rename factor_hog factor

	** MI.3. Quitar gastos "no necesarios" **
	// T916: gasto en regalos a personas ajenas al hogar, erogaciones financieras y de capital. 
	// N012: Pérdidas y robos de dinero
	drop if clave == "T916" | clave == "N012"

	** MI.4. Gasto anual **
	egen gasto_anual = rsum(gas_nm_tri gasto_tri)
	replace gasto_anual = gasto_anual*4
	format gasto_anual %10.2fc

	** MI.5. Gasto en educación *
	replace inscrip = 0 if inscrip == . & clave >= "E001" & clave <= "E007"
	replace colegia = 0 if colegia == . & clave >= "E001" & clave <= "E007"
	replace material = 0 if material == . & clave >= "E001" & clave <= "E007"
	replace gasto_anual = inscrip + colegia*12 + material if clave >= "E001" & clave <= "E007"

	** MI.6. Unión de claves de IVA y IEPS **
	merge m:1 (clave) using "`c(sysdir_site)'../BasesCIEP/INEGI/ENIGH/`enighanio'/clave_iva.dta", ///
		nogen keepus(descripcion *2018 clase_de_actividad*) keep(matched master)
	encode iva2018, gen(tiva)
	compress
	tempfile pre_iva
	save `pre_iva'

	use "`c(sysdir_site)'../BasesCIEP/INEGI/Censo Economico/2019/censo_eco.dta", clear
	/* a218a: Participación de la prestación de servicios profesionales, científicos y 
	técnicos en el total de ingresos por suministro de bienes y servicios: Porcentaje 
	de los ingresos a valor de venta que obtuvo la unidad económica por la prestación 
	de servicios profesionales, científicos y técnicos a terceros, en el total de los 
	ingresos que tuvo la unidad económica en 2018. Resulta de dividir el total de los 
	ingresos por la prestación de servicios profesionales, científicos y técnicos, entre 
	el total de ingresos por suministro de bienes y servicios, multiplicado por 100.*/
	/* a201a: Valor agregado censal bruto a producción bruta total : Porcentaje del 
	valor de la producción que se añade durante el proceso de trabajo por la actividad 
	creadora y de STransformación realizada por el personal ocupado, el capital y la 
	organización (factores de la producción), ejercida sobre los materiales que se 
	consumen en la realización de la actividad económica, respecto del valor de todos 
	los bienes y servicios producidos o comercializados por la unidad económica como 
	resultado del ejercicio de sus actividades.*/
	/* a111a: Producción bruta total (millones de pesos): Es el valor de todos los bienes 
	y servicios producidos o comercializados por la unidad económica como resultado del 
	ejercicio de sus actividades, comprendiendo el valor de los productos elaborados; el 
	margen bruto de comercialización; las obras ejecutadas; los ingresos por la prestación 
	de servicios, así como el alquiler de maquinaria y equipo, y otros bienes muebles e 
	inmuebles; el valor de los activos fijos producidos para uso propio, entre otros. 
	Incluye la variación de existencias de productos en proceso. Los bienes y servicios 
	se valoran a precios productor.*/
	tabstat a218a a201a [aw=a111a] if length(codigo) == 2, save by(codigo)
	tempname PR11 PR21 PR22 PR23 PR43 PR46 PR51 PR52 PR53 PR54 PR55 PR56 PR61 PR62 PR71 PR72 PR81 PR
	matrix `PR11' = r(Stat1)
	matrix `PR21' = r(Stat2)
	matrix `PR22' = r(Stat3)
	matrix `PR23' = r(Stat4)
	matrix `PR43' = r(Stat5)
	matrix `PR46' = r(Stat6)
	matrix `PR51' = r(Stat7)
	matrix `PR52' = r(Stat8)
	matrix `PR53' = r(Stat9)
	matrix `PR54' = r(Stat10)
	matrix `PR55' = r(Stat11)
	matrix `PR56' = r(Stat12)
	matrix `PR61' = r(Stat13)
	matrix `PR62' = r(Stat14)
	matrix `PR71' = r(Stat15)
	matrix `PR72' = r(Stat16)
	matrix `PR81' = r(Stat18)
	matrix `PR' = r(StatTotal)

	** MI.7. Unión de censo económico **
	forvalues k=1(1)6 {
		use "`c(sysdir_site)'../BasesCIEP/INEGI/Censo Economico/2019/censo_eco.dta", clear
		g num = length(codigo)
		drop if num != 6
		keep if id_estrato == .

		keep codigo a201a
		rename codigo clase_de_actividad`k'
		rename a201a valoragregado
		g proporcion = valoragregado/100
		
		merge 1:m (clase_de_actividad`k') using `pre_iva', nogen keep(matched using)
		compress
		save `pre_iva', replace
	}

	order folioviv-porcentaje_ieps2018 *1 *2 *3 *4 *5 *6
	/* Valor agregado diferente a servicios profesionales de la actividad económica */
	replace proporcion = (1-`PR11'[1,1]/100)*`PR11'[1,2]/100 if substr(clase_de_actividad1,1,2) == "11" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR21'[1,1]/100)*`PR21'[1,2]/100 if substr(clase_de_actividad1,1,2) == "21" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR22'[1,1]/100)*`PR22'[1,2]/100 if substr(clase_de_actividad1,1,2) == "22" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR23'[1,1]/100)*`PR23'[1,2]/100 if substr(clase_de_actividad1,1,2) == "23" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR43'[1,1]/100)*`PR43'[1,2]/100 if substr(clase_de_actividad1,1,2) == "43" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR46'[1,1]/100)*`PR46'[1,2]/100 if substr(clase_de_actividad1,1,2) == "46" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR51'[1,1]/100)*`PR51'[1,2]/100 if substr(clase_de_actividad1,1,2) == "51" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR52'[1,1]/100)*`PR52'[1,2]/100 if substr(clase_de_actividad1,1,2) == "52" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR53'[1,1]/100)*`PR53'[1,2]/100 if substr(clase_de_actividad1,1,2) == "53" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR54'[1,1]/100)*`PR54'[1,2]/100 if substr(clase_de_actividad1,1,2) == "54" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR55'[1,1]/100)*`PR55'[1,2]/100 if substr(clase_de_actividad1,1,2) == "55" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR56'[1,1]/100)*`PR56'[1,2]/100 if substr(clase_de_actividad1,1,2) == "56" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR61'[1,1]/100)*`PR61'[1,2]/100 if substr(clase_de_actividad1,1,2) == "61" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR62'[1,1]/100)*`PR62'[1,2]/100 if substr(clase_de_actividad1,1,2) == "62" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR71'[1,1]/100)*`PR71'[1,2]/100 if substr(clase_de_actividad1,1,2) == "71" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR72'[1,1]/100)*`PR72'[1,2]/100 if substr(clase_de_actividad1,1,2) == "72" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR81'[1,1]/100)*`PR81'[1,2]/100 if substr(clase_de_actividad1,1,2) == "81" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR'[1,1]/100)*`PR'[1,2]/100 if clase_de_actividad1 == "000000" | proporcion == . | proporcion < 0
	noisily di in g "Proporcion: " in y (1-`PR'[1,1]/100)*`PR'[1,2]/100*100 "%"

	** MI.9. Estado y ubicación geográfica ***
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

	** MI.10. Variables auxiliares **
	g letra = substr(clave,1,1)
	g letra2 = substr(clave,2,1)
	replace letra2 = "" if letra2 != "R" & letra2 != "B"

	g num = substr(clave,2,.) if letra2 != "R" & letra2 != "B"
	replace num = substr(clave,3,.) if letra2 == "R" | letra2 == "B"
	destring num, replace
	replace num = num - 900 if letra == "T" & (letra2 != "R" & letra2 != "B")

	*drop letra2 clase_de_actividad* produccion* valoragregado* agregado prod estado

	g publica = tipoesc == "1"
	g rentab = tenencia == "1" | tenencia == "3"

	** MI.11. SNA categorías **
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

	label define categ 1 "Alimentos" 2 "Bebidas no alcohólicas" ///
		3 "Bebidas alcohólicas" 4 "Tabaco" ///
		5 "Prendas de vestir" 6 "Calzado" 7 "Vivienda" 8 "Agua" 9 "Electricidad" ///
		10 "Artículos para el hogar" ///
		11 "Salud" 12 "Adquisición de vehículos" ///
		13 "Funcionamiento de Transporte" ///
		14 "Servicios de Transporte" ///
		15 "Comunicaciones" 16 "Recreación y cultura" 17 "Educación" ///
		18 "Restaurantes y hoteles" 19 "Bienes y servicios diversos"
	label values categ categ
	replace categ = 99 if categ == .	// Individuos

	** MI.12 IVA categorías **
	g categ_iva = "alim" if letra == "A" & iva2018 == "Tasa Cero"
	replace categ_iva = "fuera" if letra == "A" & ((num >= 198 & num <= 202) | (num >= 243 & num <= 247))
	replace categ_iva = "cb" if letra == "A" & (iva2018 == "Tasa Cero" ///
		& (num >= 1 & num <= 100) | num == 102 | (num >= 137 & num <= 143) | (num >= 107 & num <= 136) ///
		| (num >= 147 & num <= 172) | (num >= 173 & num <= 175))
	replace categ_iva = "mascotas" if (letra == "L" & (num == 029)) | (letra == "A" & (num == 213 | num == 214))
	replace categ_iva = "med" if letra == "J" & (iva2018 == "Tasa Cero" ///
		& (num == 9 | num == 10 | num == 14 | (num >= 20 & num <= 27) | num == 28 | num == 29 ///
		| num == 30 | num == 31 | num == 34 | (num >= 36 & num <= 38) | num == 42 | (num >= 44 & num <= 51) ///
		| num == 54 | (num >= 53 & num <= 56) | num == 64))
	replace categ_iva = "trans" if letra == "B"
	replace categ_iva = "transf" if (letra == "M" & num == 1) | (letra == "B" & num == 6)
	replace categ_iva = "educacion" if letra == "E" & ((num >= 1 & num <= 7) | num == 16 | num == 19) //& publica == 0
	replace categ_iva = "alquiler" if letra == "G" & ((num >= 1 & num <= 3) | (num >= 101 & num <= 106))
	replace categ_iva = "mujer" if letra == "D" & num == 15
	replace categ_iva = "otros" if categ_iva == "" & tiva != .

	** MI.13 IEPS categorías **
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

	** MI.14. Coeficientes de consumo por edades **
	g alfa = 1 if edad != .
	replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
	replace alfa = .4 if edad <= 4

	** MI.15. Supuestos **
	g informal = lugar_comp == "01" | lugar_comp == "02" | lugar_comp == "03" | lugar_comp == "17"	// Informalidad

	** MI.16. Sexo **
	destring sexo, replace
	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo

	** MI.17. Guardar pre-base **
	capture drop __*
	compress
	sort folioviv foliohog numren clave

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/`enighanio'/preconsumption.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/`enighanio'/preconsumption.dta", replace
	}
}





******************************
***                        ***
***  3. Precio, IVA, IEPS  ***
***                        ***
******************************
use "`c(sysdir_personal)'/SIM/`enighanio'/preconsumption.dta", clear
*drop if categ == 99
replace informal = lugar_comp == "01" | lugar_comp == "02" | lugar_comp == "03" | lugar_comp == "17"	// Informalidad
*sample 5

** 3.1 Cantidad anual **
replace cantidad = cantidad*365 if frecuencia == "1"
replace cantidad = cantidad*52 if frecuencia == "2"
replace cantidad = cantidad*12 if frecuencia == "3"
replace cantidad = cantidad*4 if frecuencia == "4" | frecuencia == "5" | frecuencia == "6"	// Supuesto
replace cantidad = cantidad*52 if tipoieps != . & (frecuencia == "0" | frecuencia == "")	// Alcohol
replace cantidad = 52 if cantidad == .

*replace cantidad = gasto/13.98*52 if clave == "F007"
*replace cantidad = gasto/14.81*52 if clave == "F008"
*replace cantidad = gasto/14.63*52 if clave == "F009"


** 3.2 Cálculo de precios **
g double precio = gasto_anual/cantidad


** 3.3 Cálculo del IVA **
g double IVA = precio*(`tasagener'/100)/(1+(`tasagener'/100))*cantidad*proporcion if tiva == 1		// Exento
replace IVA = precio*(`tasagener'/100)/(1+(`tasagener'/100))*cantidad if tiva == 2			// General gravado
replace IVA = 0 if informal == 1 | tiva == 3 														// Tasa cero


** 3.4 Cálculo del IEPS **
replace porcentaje_ieps = 0 if porcentaje_ieps == .
*g double precio_p = ((precio - IVA)*proporcion - cuota_ieps2018)/(1 + porcentaje_ieps2018/100) if tipoieps != .
g double IEPS = ((gasto_anual)/(1+(`tasagener'/100))-cuota_ieps2018*cantidad)*proporcion*porcentaje_ieps2018/100/(1 + porcentaje_ieps2018/100) + cuota_ieps2018*cantidad if tipoieps != .
replace IEPS = gasto_anual*.63 if tipoieps == 12
*g double IEPS = ((precio-IVA)*proporcion*(1 + porcentaje_ieps2018/100) + cuota_ieps2018) if tipoieps != .
replace IEPS = 0 if informal == 1

tabstat precio [aw=factor], by(tipoieps) f(%20.0fc)
replace tipoieps = 13 if tipoieps == 1 | tipoieps == 2 | tipoieps == 3
tabstat IEPS cantidad [aw=factor], by(tipoieps) stat(sum) f(%20.0fc)





******************************************/
***                                     ***
***  4. Deducciones personales del ISR  ***
***                                     ***
*******************************************
local smdf = 88.36
g deduc_STrans_escolar = gasto_anual if clave == "E013"
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
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/`enighanio'/deducciones.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/`enighanio'/deducciones.dta", replace
}
restore





**************************************/
***                                 ***
***  5. Original aggregated values  ***
***                                 ***
***************************************
Gini gasto_anual, hogar(folioviv foliohog) factor(factor)
local gini_gasto_anual = r(gini_gasto_anual)
scalar ginigastoanual = `gini_gasto_anual'

Gini IVA, hogar(folioviv foliohog) factor(factor)
local gini_IVA = r(gini_IVA)
scalar giniIVA = `gini_IVA'

Gini IEPS, hogar(folioviv foliohog) factor(factor)
local gini_IEPS = r(gini_IEPS)
scalar giniIEPS = string(`gini_IEPS',"%5.3f")

tabstat gasto_anual precio IVA IEPS [aw=factor], by(categ) stat(sum) f(%20.0fc) save
local j = 0
foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec Hoga Salu Vehi FTra STra Comu Recr Educ Rest Dive {
	local ++j
	tempname M`j'
	matrix `M`j'' = r(Stat`j')
	scalar E`k'PIB = `M`j''[1,1]/PIB*100
	scalar E`k'PC = `M`j''[1,1]/pobtotNac
}
tempname MTot
matrix `MTot' = r(StatTotal)

local j = 1
foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec Hoga Salu Vehi FTra STra Comu Recr Educ Rest Dive {
	tempname gasto_anual`k'
	g `gasto_anual`k'' = gasto_anual if categ == `j'
	Gini `gasto_anual`k'', hogar(folioviv foliohog) factor(factor)
	local gini`k' = r(gini_`gasto_anual`k'')
	scalar gini`k' = `gini`k''
	local ++j
}

noisily di _newline in g "{bf: A. Gasto inicial" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "ENIGH" ///
	_col(66) %7s "SCN" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di in g "  (+) Alimentos " ///
	_col(44) in y "(" %5.3fc `giniAlim' ")" ///
	_col(57) in y %7.3fc `M1'[1,1]/PIB*100 ///
	_col(66) %6.3fc Alim/PIB*100 ///
	_col(77) %6.1fc (`M1'[1,1]/Alim-1)*100 "%"
noisily di in g "  (+) Bebidas no alcohólicas " ///
	_col(44) in y "(" %5.3fc `giniBebN' ")" ///
	_col(57) in y %7.3fc `M2'[1,1]/PIB*100 ///
	_col(66) %6.3fc BebN/PIB*100 ///
	_col(77) %6.1fc (`M2'[1,1]/BebN-1)*100 "%"
noisily di in g "  (+) Bebidas alcohólicas " ///
	_col(44) in y "(" %5.3fc `giniBebA' ")" ///
	_col(57) in y %7.3fc `M3'[1,1]/PIB*100 ///
	_col(66) %6.3fc BebA/PIB*100 ///
	_col(77) %6.1fc (`M3'[1,1]/BebA-1)*100 "%"
noisily di in g "  (+) Tabaco " ///
	_col(44) in y "(" %5.3fc `giniTaba' ")" ///
	_col(57) in y %7.3fc `M4'[1,1]/PIB*100 ///
	_col(66) %6.3fc Taba/PIB*100 ///
	_col(77) %6.1fc (`M4'[1,1]/Taba-1)*100 "%"
noisily di in g "  (+) Prendas de vestir " ///
	_col(44) in y "(" %5.3fc `giniVest' ")" ///
	_col(57) in y %7.3fc `M5'[1,1]/PIB*100 ///
	_col(66) %6.3fc Vest/PIB*100 ///
	_col(77) %6.1fc (`M5'[1,1]/Vest-1)*100 "%"
noisily di in g "  (+) Calzado " ///
	_col(44) in y "(" %5.3fc `giniCalz' ")" ///
	_col(57) in y %7.3fc `M6'[1,1]/PIB*100 ///
	_col(66) %6.3fc Calz/PIB*100 ///
	_col(77) %6.1fc (`M6'[1,1]/Calz-1)*100 "%"
noisily di in g "  (+) Vivienda " ///
	_col(44) in y "(" %5.3fc `giniAlqu' ")" ///
	_col(57) in y %7.3fc `M7'[1,1]/PIB*100 ///
	_col(66) %6.3fc Alqu/PIB*100 ///
	_col(77) %6.1fc (`M7'[1,1]/Alqu-1)*100 "%"
noisily di in g "  (+) Agua " ///
	_col(44) in y "(" %5.3fc `giniAgua' ")" ///
	_col(57) in y %7.3fc `M8'[1,1]/PIB*100 ///
	_col(66) %6.3fc Agua/PIB*100 ///
	_col(77) %6.1fc (`M8'[1,1]/Agua-1)*100 "%"
noisily di in g "  (+) Electricidad " ///
	_col(44) in y "(" %5.3fc `giniElec' ")" ///
	_col(57) in y %7.3fc `M9'[1,1]/PIB*100 ///
	_col(66) %6.3fc Elec/PIB*100 ///
	_col(77) %6.1fc (`M9'[1,1]/Elec-1)*100 "%"
noisily di in g "  (+) Artículos para el hogar " ///
	_col(44) in y "(" %5.3fc `giniHoga' ")" ///
	_col(57) in y %7.3fc `M10'[1,1]/PIB*100 ///
	_col(66) %6.3fc Hoga/PIB*100 ///
	_col(77) %6.1fc (`M10'[1,1]/Hoga-1)*100 "%"
noisily di in g "  (+) Salud " ///
	_col(44) in y "(" %5.3fc `giniSalu' ")" ///
	_col(57) in y %7.3fc `M11'[1,1]/PIB*100 ///
	_col(66) %6.3fc Salu/PIB*100 ///
	_col(77) %6.1fc (`M11'[1,1]/Salu-1)*100 "%"
noisily di in g "  (+) Aquisición de vehículos " ///
	_col(44) in y "(" %5.3fc `giniVehi' ")" ///
	_col(57) in y %7.3fc `M12'[1,1]/PIB*100 ///
	_col(66) %6.3fc Vehi/PIB*100 ///
	_col(77) %6.1fc (`M12'[1,1]/Vehi-1)*100 "%"
noisily di in g "  (+) Funcionamiento de STransporte " ///
	_col(44) in y "(" %5.3fc `giniFTra' ")" ///
	_col(57) in y %7.3fc `M13'[1,1]/PIB*100 ///
	_col(66) %6.3fc FTra/PIB*100 ///
	_col(77) %6.1fc (`M13'[1,1]/FTra-1)*100 "%"
noisily di in g "  (+) Servicios de STransporte " ///
	_col(44) in y "(" %5.3fc `giniSTra' ")" ///
	_col(57) in y %7.3fc `M14'[1,1]/PIB*100 ///
	_col(66) %6.3fc STra/PIB*100 ///
	_col(77) %6.1fc (`M14'[1,1]/STra-1)*100 "%"
noisily di in g "  (+) Comunicaciones " ///
	_col(44) in y "(" %5.3fc `giniComu' ")" ///
	_col(57) in y %7.3fc `M15'[1,1]/PIB*100 ///
	_col(66) %6.3fc Comu/PIB*100 ///
	_col(77) %6.1fc (`M15'[1,1]/Comu-1)*100 "%"
noisily di in g "  (+) Recreación y cultura " ///
	_col(44) in y "(" %5.3fc `giniRecr' ")" ///
	_col(57) in y %7.3fc `M16'[1,1]/PIB*100 ///
	_col(66) %6.3fc Recr/PIB*100 ///
	_col(77) %6.1fc (`M16'[1,1]/Recr-1)*100 "%"
noisily di in g "  (+) Educación " ///
	_col(44) in y "(" %5.3fc `giniEduc' ")" ///
	_col(57) in y %7.3fc `M17'[1,1]/PIB*100 ///
	_col(66) %6.3fc Educ/PIB*100 ///
	_col(77) %6.1fc (`M17'[1,1]/Educ-1)*100 "%"
noisily di in g "  (+) Restaurantes y hoteles" ///
	_col(44) in y "(" %5.3fc `giniRest' ")" ///
	_col(57) in y %7.3fc `M18'[1,1]/PIB*100 ///
	_col(66) %6.3fc Rest/PIB*100 ///
	_col(77) %6.1fc (`M18'[1,1]/Rest-1)*100 "%"
noisily di in g "  (+) Bienes y servicios diveresos " ///
	_col(44) in y "(" %5.3fc `giniDive' ")" ///
	_col(57) in y %7.3fc `M19'[1,1]/PIB*100 ///
	_col(66) %6.3fc Dive/PIB*100 ///
	_col(77) %6.1fc (`M19'[1,1]/Dive-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di in g "{bf:  (=) Total " ///
	_col(44) in y "(" %5.3fc `gini_gasto_anual' ")" ///
	_col(57) in y %7.3fc `MTot'[1,1]/PIB*100 ///
	_col(66) %6.3fc ConHog/PIB*100 ///
	_col(77) %6.1fc (`MTot'[1,1]/ConHog-1)*100 "}" "%"

noisily di _newline in g "{bf: B. IVA" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "ENIGH" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"
noisily di in g "  Total " ///
	_col(44) in y "(" %5.3fc `gini_IVA' ")" ///
	_col(57) in y %7.3fc `MTot'[1,3]/PIB*100 ///
	_col(66) %6.3fc `IVA'/PIB*100 ///
	_col(77) %6.1fc (`MTot'[1,3]/`IVA'-1)*100 "%"

scalar GastoTotPIB = `MTot'[1,1]/PIB*100
scalar GastoTotHHPC = `MTot'[1,1]/pobtotNac
scalar DifGastoTot = (`MTot'[1,1]/ConHog-1)*100
scalar TTGastoTot = (`MTot'[1,1]/ConHog)^(-1)



*********
** IVA **
di _newline in g "  IVA" in y " ANTES " in g "del factor de expansión."
tabstat IVA [fw=factor], stat(sum) by(tiva) f(%20.0fc)
scalar IVAHHSPIB = `MTot'[1,3]/PIB*100
scalar IVASCNPIB = `IVA'/PIB*100



**********
** IEPS **
noisily di _newline in g "{bf: C. IEPS" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "ENIGH" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"

tabstat IEPS [aw=factor], by(tipoieps) stat(sum) f(%20.0fc) save
tempname iepstot
matrix `iepstot' = r(StatTotal)
scalar IEPSHHSPIB = `MTot'[1,4]/PIB*100
scalar IEPSSCNPIB = `IEPS'/PIB*100

local k = 1
while "`=r(name`k')'" != "." {
	tempname ieps`k'
	matrix `ieps`k'' = r(Stat`k')
	local name`k' = "`=r(name`k')'"
	local ++k
}

local k = 1
while "`name`k''" != "" {
	g `ieps`k'' = IEPS if tipoieps == `k'
	Gini `ieps`k'', hogar(folioviv foliohog) factor(factor)
	local gini_ieps`k' = r(gini_`ieps`k'')
	noisily di in g "  (+) `name`k''" ///
		_col(44) in y "(" %5.3fc `gini_ieps`k'' ")" ///
		_col(57) in y %7.3fc `ieps`k''[1,1]/PIB*100 ///
		_col(66) in y %6.3fc `Ieps`k''/PIB*100 ///
		_col(77) in y %6.1fc (`ieps`k''[1,1]/`Ieps`k''-1)*100 "%"
	local ++k
}

noisily di in g _dup(84) "-"
noisily di in g "  IEPS " ///
	_col(44) in y "(" %5.3fc `gini_IEPS' ")" ///
	_col(57) in y %7.3fc `MTot'[1,4]/PIB*100 ///
	_col(66) %6.3fc `IEPS'/PIB*100 ///
	_col(77) %6.1fc (`MTot'[1,4]/`IEPS'-1)*100 "%"





*******************
***             ***
*** 6. Altimir  ***
***             ***
*******************
if "`altimir'" == "yes" {
	local j = 0
	foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec Hoga Salu Vehi FTra STra Comu Recr Educ Rest Dive {
		local ++j
		scalar TT`k' = (`M`j''[1,1]/`k')^(-1)
		scalar Dif`k' = ((`M`j''[1,1]/`k')-1)*100
		replace gasto_anual = gasto_anual*scalar(TT`k') if categ == `j'
		replace precio = precio*scalar(TT`k') if categ == `j'
		replace IVA = IVA*scalar(TT`k') if categ == `j'
		replace IEPS = IEPS*scalar(TT`k') if categ == `j'
	}
	format IVA %10.2fc
	format IEPS %10.2fc

	di _newline in g "  IVA" in y " DESPU{c E'}S " in g "del factor de expansión."
	tabstat IVA [fw=factor], stat(sum) by(tiva) f(%20.0fc)

	tabstat gasto_anual precio IVA IEPS [aw=factor], by(categ) stat(sum) f(%20.0fc) save
	local j = 0
	foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec Hoga Salu Vehi FTra STra Comu Recr Educ Rest Dive {
		local ++j
		tempname M`j'
		matrix `M`j'' = r(Stat`j')
		scalar EE`k'PIB = `M`j''[1,1]/PIB*100
	}
	tempname MTot
	matrix `MTot' = r(StatTotal)


	* Display *
	noisily di _newline in g "{bf: D. Gasto ajustado" ///
		_col(44) in g %20s "ENIGH" ///
		_col(66) %6s "Macro" in g ///
		_col(77) %6s  "Diff. %}"
	noisily di in g "  (+) Alimentos " ///
		_col(44) in y %20.3fc `M1'[1,1]/PIB*100 ///
		_col(66) %6.3fc Alim/PIB*100 ///
		_col(77) %6.1fc (`M1'[1,1]/Alim-1)*100
	noisily di in g "  (+) Bebidas no alcohólicas " ///
		_col(44) in y %20.3fc `M2'[1,1]/PIB*100 ///
		_col(66) %6.3fc BebN/PIB*100 ///
		_col(77) %6.1fc (`M2'[1,1]/BebN-1)*100
	noisily di in g "  (+) Bebidas alcohólicas " ///
		_col(44) in y %20.3fc `M3'[1,1]/PIB*100 ///
		_col(66) %6.3fc BebA/PIB*100 ///
		_col(77) %6.1fc (`M3'[1,1]/BebA-1)*100
	noisily di in g "  (+) Tabaco " ///
		_col(44) in y %20.3fc `M4'[1,1]/PIB*100 ///
		_col(66) %6.3fc Taba/PIB*100 ///
		_col(77) %6.1fc (`M4'[1,1]/Taba-1)*100
	noisily di in g "  (+) Prendas de vestir " ///
		_col(44) in y %20.3fc `M5'[1,1]/PIB*100 ///
		_col(66) %6.3fc Vest/PIB*100 ///
		_col(77) %6.1fc (`M5'[1,1]/Vest-1)*100
	noisily di in g "  (+) Calzado " ///
		_col(44) in y %20.3fc `M6'[1,1]/PIB*100 ///
		_col(66) %6.3fc Calz/PIB*100 ///
		_col(77) %6.1fc (`M6'[1,1]/Calz-1)*100
	noisily di in g "  (+) Vivienda " ///
		_col(44) in y %20.3fc `M7'[1,1]/PIB*100 ///
		_col(66) %6.3fc Alqu/PIB*100 ///
		_col(77) %6.1fc (`M7'[1,1]/Alqu-1)*100
	noisily di in g "  (+) Agua " ///
		_col(44) in y %20.3fc `M8'[1,1]/PIB*100 ///
		_col(66) %6.3fc Agua/PIB*100 ///
		_col(77) %6.1fc (`M8'[1,1]/Agua-1)*100
	noisily di in g "  (+) Electricidad " ///
		_col(44) in y %20.3fc `M9'[1,1]/PIB*100 ///
		_col(66) %6.3fc Elec/PIB*100 ///
		_col(77) %6.1fc (`M9'[1,1]/Elec-1)*100
	noisily di in g "  (+) Artículos para el hogar " ///
		_col(44) in y %20.3fc `M10'[1,1]/PIB*100 ///
		_col(66) %6.3fc Hoga/PIB*100 ///
		_col(77) %6.1fc (`M10'[1,1]/Hoga-1)*100
	noisily di in g "  (+) Salud " ///
		_col(44) in y %20.3fc `M11'[1,1]/PIB*100 ///
		_col(66) %6.3fc Salu/PIB*100 ///
		_col(77) %6.1fc (`M11'[1,1]/Salu-1)*100
	noisily di in g "  (+) Aquisición de vehículos " ///
		_col(44) in y %20.3fc `M12'[1,1]/PIB*100 ///
		_col(66) %6.3fc Vehi/PIB*100 ///
		_col(77) %6.1fc (`M12'[1,1]/Vehi-1)*100
	noisily di in g "  (+) Funcionamiento de STransporte " ///
		_col(44) in y %20.3fc `M13'[1,1]/PIB*100 ///
		_col(66) %6.3fc FTra/PIB*100 ///
		_col(77) %6.1fc (`M13'[1,1]/FTra-1)*100
	noisily di in g "  (+) Servicios de STransporte " ///
		_col(44) in y %20.3fc `M14'[1,1]/PIB*100 ///
		_col(66) %6.3fc STra/PIB*100 ///
		_col(77) %6.1fc (`M14'[1,1]/STra-1)*100
	noisily di in g "  (+) Comunicaciones " ///
		_col(44) in y %20.3fc `M15'[1,1]/PIB*100 ///
		_col(66) %6.3fc Comu/PIB*100 ///
		_col(77) %6.1fc (`M15'[1,1]/Comu-1)*100
	noisily di in g "  (+) Recreación y cultura " ///
		_col(44) in y %20.3fc `M16'[1,1]/PIB*100 ///
		_col(66) %6.3fc Recr/PIB*100 ///
		_col(77) %6.1fc (`M16'[1,1]/Recr-1)*100
	noisily di in g "  (+) Educación " ///
		_col(44) in y %20.3fc `M17'[1,1]/PIB*100 ///
		_col(66) %6.3fc Educ/PIB*100 ///
		_col(77) %6.1fc (`M17'[1,1]/Educ-1)*100
	noisily di in g "  (+) Restaurantes y hoteles" ///
		_col(44) in y %20.3fc `M18'[1,1]/PIB*100 ///
		_col(66) %6.3fc Rest/PIB*100 ///
		_col(77) %6.1fc (`M18'[1,1]/Rest-1)*100
	noisily di in g "  (+) Bienes y servicios diveresos " ///
		_col(44) in y %20.3fc `M19'[1,1]/PIB*100 ///
		_col(66) %6.3fc Dive/PIB*100 ///
		_col(77) %6.1fc (`M19'[1,1]/Dive-1)*100
	noisily di in g _dup(84) "-"
	noisily di in g "  (=) Total Consumo " ///
		_col(44) in y %20.3fc `MTot'[1,1]/PIB*100 ///
		_col(66) %6.3fc ConHog/PIB*100 ///
		_col(77) %6.1fc (`MTot'[1,1]/ConHog-1)*100

	noisily di _newline in g "{bf: E. IVA ajustado" ///
		_col(44) in g %20s "ENIGH" ///
		_col(66) %6s "Macro" in g ///
		_col(77) %6s  "Diff. %}"
	noisily di in g "  Total " ///
		_col(44) in y %20.3fc `MTot'[1,3]/PIB*100 ///
		_col(66) %6.3fc `IVA'/PIB*100 ///
		_col(77) %6.1fc (`MTot'[1,3]/`IVA'-1)*100



	*******************
	** IEPS ajustado **
	noisily di _newline in g "{bf: F. IEPS ajustado" ///
		_col(44) in g %20s "ENIGH" ///
		_col(66) %6s "Macro" in g ///
		_col(77) %6s  "Diff. %}"

	tabstat IEPS [aw=factor], by(tipoieps) stat(sum) f(%20.0fc) save
	tempname iepstot
	matrix `iepstot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname ieps`k'
		matrix `ieps`k'' = r(Stat`k')
		local name`k' = "`=r(name`k')'"
		local ++k
	}

	local k = 1
	while "`name`k''" != "" {
		g `ieps`k'' = IEPS if tipoieps == `k'
		local gini_ieps`k' = r(gini_`ieps`k'')
		noisily di in g "  (+) `name`k''" ///
			_col(57) in y %7.3fc `ieps`k''[1,1]/PIB*100 ///
			_col(66) in y %6.3fc `Ieps`k''/PIB*100 ///
			_col(77) in y %6.1fc (`ieps`k''[1,1]/`Ieps`k''-1)*100 "%"
		local ++k
	}

	noisily di in g _dup(84) "-"
	noisily di in g "  IEPS " ///
		_col(57) in y %7.3fc `MTot'[1,4]/PIB*100 ///
		_col(66) %6.3fc `IEPS'/PIB*100 ///
		_col(77) %6.1fc (`MTot'[1,4]/`IEPS'-1)*100 "%"


	** Ajuste IVA y IEPS **
	replace IVA = IVA*`IVA'/`MTot'[1,3]
	replace IEPS = IEPS*`IEPS'/`MTot'[1,4]
}
replace categ_iva = "sin_iva" if categ_iva == ""
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/SIM/`enighanio'/expenditures.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/SIM/`enighanio'/expenditures.dta", replace
}





***************************
***                     ***
***  7. Gasto por edad  ***
***                     ***
***************************
foreach categ of varlist categ categ_iva {
	preserve
	levelsof `categ', l(levelscateg)

	collapse (sum) gasto_anual IVA IEPS (max) tot_integ sexo edad alfa (mean) proporcion, by(folioviv foliohog numren `categ')
	capture reshape wide gasto_anual IVA IEPS proporcion, i(folioviv foliohog numren) j(`categ') string
	if _rc != 0 {
		reshape wide gasto_anual IVA IEPS proporcion, i(folioviv foliohog numren) j(`categ')
	}

	** 7.1 Distribucion **
	foreach k of varlist gasto_anual* IVA* IEPS* {
		tempvar temp`k'
		g double `temp`k'' = `k' if numren == ""
		egen double T`k' = sum(`temp`k''), by(folioviv foliohog)
	}

	foreach categlevel of local levelscateg {
		egen prop_exen`categlevel' = mean(proporcion`categlevel')
	}

	foreach k of varlist gasto_anual* IVA* IEPS* {
		tempvar alfatot`k'
		if (`"`=substr("`k'",-1,1)'"' == "3" & `"`=substr("`k'",-1,1)'"' == "l") ///
			| (`"`=substr("`k'",-1,1)'"' == "4" & `"`=substr("`k'",-1,1)'"' == "l") {
			egen `alfatot`k'' = sum(alfa) if edad >= 18, by(folioviv foliohog)
			replace `k' = 0 if `k' == .
			replace `k' = `k' + T`k'*alfa/`alfatot`k'' if edad >= 18
		}
		else {
			egen `alfatot`k'' = sum(alfa), by(folioviv foliohog)
			replace `k' = 0 if `k' == .
			replace `k' = `k' + T`k'*alfa/`alfatot`k''
		}
	}
	drop if numren == ""
	drop T*
	capture drop *sin_iva proporcion*

	** 7.2 Totales **
	egen gastoanualTOT = rsum(gasto_anual*)
	egen IVATOT = rsum(IVA*)
	egen IEPSTOT = rsum(IEPS*)



	***********
	*** END ***
	***********
	capture drop __*
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/`enighanio'/expenditure_`categ'.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/`enighanio'/expenditure_`categ'.dta", replace
	}
	restore
}
timer off 15
timer list 15
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t15)/r(nt15)',.1) in g " segs."
log close expenditures
