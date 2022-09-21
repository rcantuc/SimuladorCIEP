******************************************
****                                  ****
**** A.2. MACRO + MICRO HARMONIZATION ****
****                                  ****
******************************************
if "`1'" == "" {
	clear all
	local enighanio = 2020
}
if "`1'" >= "2020"  {
	local enighanio = 2020
}

** 0.1 Otros Parametros **
if `enighanio' >= 2014 {
	local enigh = "ENIGH"
	local tasagener = 16
	local tasafront = 16
	local altimir = "yes"
}
if `enighanio' == 2012 {
	local enigh = "ENIGH"
	local tasagener = 16
	local tasafront = 11
	local altimir = "yes"
}
timer on 15

capture mkdir "`c(sysdir_site)'/SIM/`enighanio'/"
capture log close expenditures
log using "`c(sysdir_site)'/SIM/`enighanio'/expenditures.smcl", replace name(expenditures)


** 0.2 Texto introductorio **
noisily di _newline(2) in g _dup(20) "." "{bf:  Gastos de los hogares " in y "`enigh' `enighanio'" "  }" in g _dup(20) "."





******************************************
*** 1. DATOS MACROECONóMICOS (MA) ***
******************************************
** MA.1. Sistema de Cuentas Nacionales **
noisily SCN, anio(`enighanio') nographs
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
noisily LIF, anio(`enighanio') by(divCIEP) nographs
local IVA = r(IVA)
local IEPS = r(IEPS__no_petrolero_)
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





******************************************
*** 2. DATOS MICROECONóMICOS (MI) ***
******************************************
capture confirm file "`c(sysdir_site)'/SIM/`enighanio'/preconsumption.dta"
if _rc != 0 {
*if _rc == 0 {

	** MI.1. Base de datos de gastos de los hogares **
	use "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/gastospersona.dta", clear
	append using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/gastohogar.dta"
	append using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/gastotarjetas.dta"
	append using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/erogaciones.dta"

	** MI.2. Variables sociodemograficas **
	merge m:1 (folioviv foliohog numren) using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/poblacion.dta", keepus(tipoesc sexo edad) nogen
	merge m:1 (folioviv) using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/vivienda.dta", keepus(ubica_geo tenencia) nogen
	merge m:1 (folioviv foliohog) using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/concentrado.dta", nogen keepus(factor tot_integ)
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
	merge m:1 (clave) using "`c(sysdir_site)'/bases/INEGI/`enigh'/`enighanio'/clave_iva.dta", ///
		nogen keepus(descripcion *2018 clase_de_actividad*) keep(matched master)
	encode iva2018, gen(tiva)
	compress
	tempfile pre_iva
	save `pre_iva'

	use "`c(sysdir_site)'/bases/INEGI/Censo Economico/2019/censo_eco.dta", clear
	/* a218a: Participación de la prestación de servicios profesionales, científicos y 
	técnicos en el total de ingresos por suministro de bienes y servicios: Porcentaje 
	de los ingresos a valor de venta que obtuvo la unidad económica por la prestación 
	de servicios profesionales, científicos y técnicos a terceros, en el total de los 
	ingresos que tuvo la unidad económica en 2018. Resulta de dividir el total de los 
	ingresos por la prestación de servicios profesionales, científicos y técnicos, entre 
	el total de ingresos por suministro de bienes y servicios, multiplicado por 100.*/
	/* a201a: Valor agregado censal bruto a producción bruta total : Porcentaje del 
	valor de la producción que se añade durante el proceso de trabajo por la actividad 
	creadora y de transformación realizada por el personal ocupado, el capital y la 
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
		use "`c(sysdir_site)'/bases/INEGI/Censo Economico/2019/censo_eco.dta", clear
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
		13 "Funcionamiento de transporte" ///
		14 "Servicios de transporte" ///
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
	replace numren = "01" if clave >= "M007" & clave <= "M009"			// Adquisicion de vehiculos (jefe del hogar)

	** MI.16. Sexo **
	destring sexo, replace
	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo

	** MI.17. Guardar pre-base **
	capture drop __*
	compress
	sort folioviv foliohog numren clave

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_site)'/SIM/`enighanio'/preconsumption.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/SIM/`enighanio'/preconsumption.dta", replace
	}
}




********************************
*** 3. Precio, IVA, IEPS (P) ***
********************************
use "`c(sysdir_site)'/SIM/`enighanio'/preconsumption.dta", clear
replace informal = lugar_comp == "01" | lugar_comp == "02" | lugar_comp == "03" | lugar_comp == "17"	// Informalidad



** P.1 Cantidad anual **
replace cantidad = cantidad*365 if frecuencia == "1"
replace cantidad = cantidad*52 if frecuencia == "2"
replace cantidad = cantidad*12 if frecuencia == "3"
replace cantidad = cantidad*4 if frecuencia == "4" | frecuencia == "5" | frecuencia == "6"	// Supuesto
replace cantidad = cantidad*52 if tipoieps != . & (frecuencia == "0" | frecuencia == "")	// Alcohol
replace cantidad = 52 if cantidad == .

replace cantidad = gasto/13.98*52 if clave == "F007"
replace cantidad = gasto/14.81*52 if clave == "F008"
replace cantidad = gasto/14.63*52 if clave == "F009"

** P.2 Cálculo de precios **
g double precio = gasto_anual/cantidad

** P.3 Cálculo del IVA **
g double IVA = precio*(`tasagener'/100)/(1+(`tasagener'/100))*cantidad*proporcion if tiva == 1		// Exento
replace IVA = precio*(`tasagener'/100)/(1+(`tasagener'/100))*cantidad if tiva == 2                  // General gravado
replace IVA = 0 if informal == 1 | tiva == 3 														// Tasa cero

** P.4 Cálculo del IEPS **
replace porcentaje_ieps = 0 if porcentaje_ieps == .
*g double precio_p = ((precio - IVA)*proporcion - cuota_ieps2018)/(1 + porcentaje_ieps2018/100) if tipoieps != .
g double IEPS = ((gasto_anual)/(1+(`tasagener'/100))-cuota_ieps2018*cantidad)*proporcion*porcentaje_ieps2018/100/(1 + porcentaje_ieps2018/100) + cuota_ieps2018*cantidad if tipoieps != .
replace IEPS = gasto_anual*.63 if tipoieps == 12
*g double IEPS = ((precio-IVA)*proporcion*(1 + porcentaje_ieps2018/100) + cuota_ieps2018) if tipoieps != .
replace IEPS = 0 if informal == 1

tabstat precio [aw=factor], by(tipoieps) f(%20.0fc)
replace tipoieps = 13 if tipoieps == 1 | tipoieps == 2 | tipoieps == 3
tabstat IEPS cantidad [aw=factor], by(tipoieps) stat(sum) f(%20.0fc)





****************************************/
*** 4. Deducciones personales del ISR ***
*****************************************
local smdf = 88.36
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
if `c(version)' > 13.1 {
	saveold "`c(sysdir_site)'/SIM/`enighanio'/deducciones.dta", replace version(13)
}
else {
	save "`c(sysdir_site)'/SIM/`enighanio'/deducciones.dta", replace
}
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

local j = 1
foreach k in Food NBev ABev Toba Clot Foot Hous Wate Elec Furn Heal Vehi Oper Tran Comm Recr Educ Rest Misc {
	tempname gasto_anual`k'
	g `gasto_anual`k'' = gasto_anual if categ == `j'
	Gini `gasto_anual`k'', hogar(folioviv foliohog) individuo(numren) factor(factor)
	local gini_GA`k' = r(gini_`gasto_anual`k'')
	scalar giniGA`k' = string(`gini_GA`k'',"%5.3f")
	local ++j
}

Gini gasto_anual, hogar(folioviv foliohog) individuo(numren) factor(factor)
local gini_gasto_anual = r(gini_gasto_anual)
scalar gini_gasto_anual = string(`gini_gasto_anual',"%5.3f")
Gini IVA, hogar(folioviv foliohog) individuo(numren) factor(factor)
local gini_IVA = r(gini_IVA)
scalar gini_IVA = string(`gini_IVA',"%5.3f")
Gini IEPS, hogar(folioviv foliohog) individuo(numren) factor(factor)
local gini_IEPS = r(gini_IEPS)
scalar gini_IEPS = string(`gini_IEPS',"%5.3f")


noisily di _newline in g "{bf: A. Gasto inicial" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "SCN" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di in g "  (+) Alimentos " ///
	_col(44) in y "(" %5.3fc `gini_GAFood' ")" ///
	_col(57) in y %7.3fc `M1'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Food'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M1'[1,1]/`Food'-1)*100 "%"
noisily di in g "  (+) Bebidas no alcohólicas " ///
	_col(44) in y "(" %5.3fc `gini_GANBev' ")" ///
	_col(57) in y %7.3fc `M2'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `NBev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M2'[1,1]/`NBev'-1)*100 "%"
noisily di in g "  (+) Bebidas alcohólicas " ///
	_col(44) in y "(" %5.3fc `gini_GAABev' ")" ///
	_col(57) in y %7.3fc `M3'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `ABev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M3'[1,1]/`ABev'-1)*100 "%"
noisily di in g "  (+) Tabaco " ///
	_col(44) in y "(" %5.3fc `gini_GAToba' ")" ///
	_col(57) in y %7.3fc `M4'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Toba'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M4'[1,1]/`Toba'-1)*100 "%"
noisily di in g "  (+) Prendas de vestir " ///
	_col(44) in y "(" %5.3fc `gini_GAClot' ")" ///
	_col(57) in y %7.3fc `M5'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Clot'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M5'[1,1]/`Clot'-1)*100 "%"
noisily di in g "  (+) Calzado " ///
	_col(44) in y "(" %5.3fc `gini_GAFoot' ")" ///
	_col(57) in y %7.3fc `M6'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Foot'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M6'[1,1]/`Foot'-1)*100 "%"
noisily di in g "  (+) Vivienda " ///
	_col(44) in y "(" %5.3fc `gini_GAHous' ")" ///
	_col(57) in y %7.3fc `M7'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Hous'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M7'[1,1]/`Hous'-1)*100 "%"
noisily di in g "  (+) Agua " ///
	_col(44) in y "(" %5.3fc `gini_GAWate' ")" ///
	_col(57) in y %7.3fc `M8'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Wate'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M8'[1,1]/`Wate'-1)*100 "%"
noisily di in g "  (+) Electricidad " ///
	_col(44) in y "(" %5.3fc `gini_GAElec' ")" ///
	_col(57) in y %7.3fc `M9'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Elec'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M9'[1,1]/`Elec'-1)*100 "%"
noisily di in g "  (+) Artículos para el hogar " ///
	_col(44) in y "(" %5.3fc `gini_GAFurn' ")" ///
	_col(57) in y %7.3fc `M10'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Furn'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M10'[1,1]/`Furn'-1)*100 "%"
noisily di in g "  (+) Salud " ///
	_col(44) in y "(" %5.3fc `gini_GAHeal' ")" ///
	_col(57) in y %7.3fc `M11'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Heal'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M11'[1,1]/`Heal'-1)*100 "%"
noisily di in g "  (+) Aquisición de vehículos " ///
	_col(44) in y "(" %5.3fc `gini_GAVehi' ")" ///
	_col(57) in y %7.3fc `M12'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Vehi'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M12'[1,1]/`Vehi'-1)*100 "%"
noisily di in g "  (+) Funcionamiento de transporte " ///
	_col(44) in y "(" %5.3fc `gini_GAOper' ")" ///
	_col(57) in y %7.3fc `M13'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Oper'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M13'[1,1]/`Oper'-1)*100 "%"
noisily di in g "  (+) Servicios de transporte " ///
	_col(44) in y "(" %5.3fc `gini_GATran' ")" ///
	_col(57) in y %7.3fc `M14'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Tran'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M14'[1,1]/`Tran'-1)*100 "%"
noisily di in g "  (+) Comunicaciones " ///
	_col(44) in y "(" %5.3fc `gini_GAComm' ")" ///
	_col(57) in y %7.3fc `M15'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Comm'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M15'[1,1]/`Comm'-1)*100 "%"
noisily di in g "  (+) Recreación y cultura " ///
	_col(44) in y "(" %5.3fc `gini_GARecr' ")" ///
	_col(57) in y %7.3fc `M16'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Recr'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M16'[1,1]/`Recr'-1)*100 "%"
noisily di in g "  (+) Educación " ///
	_col(44) in y "(" %5.3fc `gini_GAEduc' ")" ///
	_col(57) in y %7.3fc `M17'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Educ'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M17'[1,1]/`Educ'-1)*100 "%"
noisily di in g "  (+) Restaurantes y hoteles" ///
	_col(44) in y "(" %5.3fc `gini_GARest' ")" ///
	_col(57) in y %7.3fc `M18'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Rest'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M18'[1,1]/`Rest'-1)*100 "%"
noisily di in g "  (+) Bienes y servicios diveresos " ///
	_col(44) in y "(" %5.3fc `gini_GAMisc' ")" ///
	_col(57) in y %7.3fc `M19'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Misc'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M19'[1,1]/`Misc'-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di in g "{bf:  (=) Total " ///
	_col(44) in y "(" %5.3fc `gini_gasto_anual' ")" ///
	_col(57) in y %7.3fc `MTot'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `ExpHog'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,1]/`ExpHog'-1)*100 "}" "%"
scalar GastoTotPIB = `MTot'[1,1]/`PIBSCN'*100


noisily di _newline in g "{bf: B. IVA" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Diff. %}"
noisily di in g "  Total " ///
	_col(44) in y "(" %5.3fc `gini_IVA' ")" ///
	_col(57) in y %7.3fc `MTot'[1,3]/`PIBSCN'*100 ///
	_col(66) %6.3fc `IVA'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,3]/`IVA'-1)*100 "%"


** IEPS **
noisily di _newline in g "{bf: C. IEPS" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
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
	Gini `ieps`k'', hogar(folioviv foliohog) individuo(numren) factor(factor)
	local gini_ieps`k' = r(gini_`ieps`k'')
	noisily di in g "  (+) `name`k''" ///
		_col(44) in y "(" %5.3fc `gini_ieps`k'' ")" ///
		_col(57) in y %7.3fc `ieps`k''[1,1]/`PIBSCN'*100 ///
		_col(66) in y %6.3fc `Ieps`k''/`PIBSCN'*100 ///
		_col(77) in y %6.1fc (`ieps`k''[1,1]/`Ieps`k''-1)*100 "%"
	local ++k
}

noisily di in g _dup(84) "-"
noisily di in g "  IEPS " ///
	_col(44) in y "(" %5.3fc `gini_IEPS' ")" ///
	_col(57) in y %7.3fc `MTot'[1,4]/`PIBSCN'*100 ///
	_col(66) %6.3fc `IEPS'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`MTot'[1,4]/`IEPS'-1)*100 "%"





*****************
*** 6 Altimir ***
*****************
scalar TTAlim = (`M1'[1,1]/`Food')^(-1)
scalar TTBebN = (`M2'[1,1]/`NBev')^(-1)
scalar TTBebA = (`M3'[1,1]/`ABev')^(-1)
scalar TTTaba = (`M4'[1,1]/`Toba')^(-1)
scalar TTVest = (`M5'[1,1]/`Clot')^(-1)
scalar TTCalz = (`M6'[1,1]/`Foot')^(-1)
scalar TTAlqu = (`M7'[1,1]/`Hous')^(-1)
scalar TTAgua = (`M8'[1,1]/`Wate')^(-1)
scalar TTElec = (`M9'[1,1]/`Elec')^(-1)
scalar TTHoga = (`M10'[1,1]/`Furn')^(-1)
scalar TTSalu = (`M11'[1,1]/`Heal')^(-1)
scalar TTVehi = (`M12'[1,1]/`Vehi')^(-1)
scalar TTFTra = (`M13'[1,1]/`Oper')^(-1)
scalar TTSTra = (`M14'[1,1]/`Tran')^(-1)
scalar TTComu = (`M15'[1,1]/`Comm')^(-1)
scalar TTRecr = (`M16'[1,1]/`Recr')^(-1)
scalar TTEduc = (`M17'[1,1]/`Educ')^(-1)
scalar TTRest = (`M18'[1,1]/`Rest')^(-1)
scalar TTDive = (`M19'[1,1]/`Misc')^(-1)

scalar TAlimPIB = `Food'/`PIBSCN'*100
scalar TBebNPIB = `NBev'/`PIBSCN'*100
scalar TBebAPIB = `ABev'/`PIBSCN'*100
scalar TTabaPIB = `Toba'/`PIBSCN'*100
scalar TVestPIB = `Clot'/`PIBSCN'*100
scalar TCalzPIB = `Foot'/`PIBSCN'*100
scalar TAlquPIB = `Hous'/`PIBSCN'*100
scalar TAguaPIB = `Wate'/`PIBSCN'*100
scalar TElecPIB = `Elec'/`PIBSCN'*100
scalar THogaPIB = `Furn'/`PIBSCN'*100
scalar TSaluPIB = `Heal'/`PIBSCN'*100
scalar TVehiPIB = `Vehi'/`PIBSCN'*100
scalar TFTraPIB = `Oper'/`PIBSCN'*100
scalar TSTraPIB = `Tran'/`PIBSCN'*100
scalar TComuPIB = `Comm'/`PIBSCN'*100
scalar TRecrPIB = `Recr'/`PIBSCN'*100
scalar TEducPIB = `Educ'/`PIBSCN'*100
scalar TRestPIB = `Rest'/`PIBSCN'*100
scalar TDivePIB = `Misc'/`PIBSCN'*100

scalar EAlimPIB = `M1'[1,1]/`PIBSCN'*100
scalar EBebNPIB = `M2'[1,1]/`PIBSCN'*100
scalar EBebAPIB = `M3'[1,1]/`PIBSCN'*100
scalar ETabaPIB = `M4'[1,1]/`PIBSCN'*100
scalar EVestPIB = `M5'[1,1]/`PIBSCN'*100
scalar ECalzPIB = `M6'[1,1]/`PIBSCN'*100
scalar EAlquPIB = `M7'[1,1]/`PIBSCN'*100
scalar EAguaPIB = `M8'[1,1]/`PIBSCN'*100
scalar EElecPIB = `M9'[1,1]/`PIBSCN'*100
scalar EHogaPIB = `M10'[1,1]/`PIBSCN'*100
scalar ESaluPIB = `M11'[1,1]/`PIBSCN'*100
scalar EVehiPIB = `M12'[1,1]/`PIBSCN'*100
scalar EFTraPIB = `M13'[1,1]/`PIBSCN'*100
scalar ESTraPIB = `M14'[1,1]/`PIBSCN'*100
scalar EComuPIB = `M15'[1,1]/`PIBSCN'*100
scalar ERecrPIB = `M16'[1,1]/`PIBSCN'*100
scalar EEducPIB = `M17'[1,1]/`PIBSCN'*100
scalar ERestPIB = `M18'[1,1]/`PIBSCN'*100
scalar EDivePIB = `M19'[1,1]/`PIBSCN'*100

di _newline in g "  IVA" in y " ANTES " in g "del factor de expansión."
tabstat IVA [fw=factor], stat(sum) by(tiva) f(%20.0fc)

if "`altimir'" == "yes" {
	local j = 0
	foreach k in Alim BebN BebA Taba Vest Calz Alqu Agua Elec Hoga ///
		Salu Vehi FTra STra Comu Recr Educ Rest Dive {
		local ++j
		replace gasto_anual = gasto_anual*scalar(TT`k') if categ == `j'
		replace precio = precio*scalar(TT`k') if categ == `j'
		replace IVA = IVA*scalar(TT`k') if categ == `j'
		replace IEPS = IEPS*scalar(TT`k') if categ == `j'
	}
	format IVA %10.2fc
	format IEPS %10.2fc
}

di _newline in g "  IVA" in y " DESPU{c E'}S " in g "del factor de expansión."
tabstat IVA [fw=factor], stat(sum) by(tiva) f(%20.0fc)

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
noisily di in g "  (+) Bebidas no alcohólicas " ///
	_col(44) in y %20.3fc `M2'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `NBev'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M2'[1,1]/`NBev'-1)*100
noisily di in g "  (+) Bebidas alcohólicas " ///
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
noisily di in g "  (+) Artículos para el hogar " ///
	_col(44) in y %20.3fc `M10'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Furn'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M10'[1,1]/`Furn'-1)*100
noisily di in g "  (+) Salud " ///
	_col(44) in y %20.3fc `M11'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Heal'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M11'[1,1]/`Heal'-1)*100
noisily di in g "  (+) Aquisición de vehículos " ///
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
noisily di in g "  (+) Recreación y cultura " ///
	_col(44) in y %20.3fc `M16'[1,1]/`PIBSCN'*100 ///
	_col(66) %6.3fc `Recr'/`PIBSCN'*100 ///
	_col(77) %6.1fc (`M16'[1,1]/`Recr'-1)*100
noisily di in g "  (+) Educación " ///
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

local k = 1
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

** Ajuste IVA y IEPS **
replace IVA = IVA*`IVA'/`MTot'[1,3]
replace IEPS = IEPS*`IEPS'/`MTot'[1,4]

** Scalar **
scalar EAlimPIB = `M1'[1,1]/`PIBSCN'*100
scalar EBebNPIB = `M2'[1,1]/`PIBSCN'*100
scalar EBebAPIB = `M3'[1,1]/`PIBSCN'*100
scalar ETabaPIB = `M4'[1,1]/`PIBSCN'*100
scalar EVestPIB = `M5'[1,1]/`PIBSCN'*100
scalar ECalzPIB = `M6'[1,1]/`PIBSCN'*100
scalar EAlquPIB = `M7'[1,1]/`PIBSCN'*100
scalar EAguaPIB = `M8'[1,1]/`PIBSCN'*100
scalar EElecPIB = `M9'[1,1]/`PIBSCN'*100
scalar EHogaPIB = `M10'[1,1]/`PIBSCN'*100
scalar ESaluPIB = `M11'[1,1]/`PIBSCN'*100
scalar EVehiPIB = `M12'[1,1]/`PIBSCN'*100
scalar EFTraPIB = `M13'[1,1]/`PIBSCN'*100
scalar ESTraPIB = `M14'[1,1]/`PIBSCN'*100
scalar EComuPIB = `M15'[1,1]/`PIBSCN'*100
scalar ERecrPIB = `M16'[1,1]/`PIBSCN'*100
scalar EEducPIB = `M17'[1,1]/`PIBSCN'*100
scalar ERestPIB = `M18'[1,1]/`PIBSCN'*100
scalar EDivePIB = `M19'[1,1]/`PIBSCN'*100

scalar GastoAnualHHSPIB = `MTot'[1,1]/`PIBSCN'*100





************************
*** 7 Gasto por edad ***
************************
replace categ_iva = "sin_iva" if categ_iva == ""
foreach categ of varlist categ categ_iva {
	preserve
	levelsof `categ', l(levelscateg)

	collapse (sum) gasto_anual IVA IEPS (max) factor sexo edad alfa tot_integ (mean) proporcion, by(folioviv foliohog numren `categ')
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
		if (`"`=substr("`k'",-1,1)'"' == "3" & `"`=substr("`k'",-2,1)'"' != "1") ///
			| (`"`=substr("`k'",-1,1)'"' == "4" & `"`=substr("`k'",-2,1)'"' != "1") {
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
	egen TOTgasto_anual = rsum(gasto_anual*)
	label var TOTgasto_anual "gasto total"
	
	Gini TOTgasto_anual, hogar(folioviv foliohog) individuo(numren) factor(factor)
	local gini_gasto_anual = r(gini_TOTgasto_anual)
	scalar giniGAGastoAnual = string(`gini_gasto_anual',"%5.3f")

	egen TOTIVA = rsum(IVA*)
	Gini TOTIVA, hogar(folioviv foliohog) individuo(numren) factor(factor)
	local gini_IVA = r(gini_TOTIVA)
	scalar giniIVA = string(`gini_IVA',"%5.3f")
	scalar IVAHHSPIB = `MTot'[1,3]/`PIBSCN'*100
	scalar IVASCNPIB = `IVA'/`PIBSCN'*100

	egen TOTIEPS = rsum(IEPS*)
	Gini TOTIEPS, hogar(folioviv foliohog) individuo(numren) factor(factor)
	local gini_IEPS = r(gini_TOTIEPS)
	scalar giniIEPS = string(`gini_IEPS',"%5.3f")
	scalar IEPSHHSPIB = `MTot'[1,4]/`PIBSCN'*100
	scalar IEPSSCNPIB = `IEPS'/`PIBSCN'*100


	***********
	*** END ***
	***********
	capture drop __*
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_site)'/SIM/`enighanio'/expenditure_`categ'.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/SIM/`enighanio'/expenditure_`categ'.dta", replace
	}
	restore
}



timer off 15
timer list 15
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t15)/r(nt15)',.1) in g " segs."
log close expenditures
