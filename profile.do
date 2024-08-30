*********************
***               ***
*** 1 Estilo CIEP ***
***		          ***
*********************
set scheme ciepnew
graph set window fontface "Ubuntu Light"
set more off, permanently
set type double, permanently
set charset latin1, permanently

* 1.1 Identificador del usuario *
global id = "`c(username)'"
*sysdir set PERSONAL "`c(sysdir_site)'"


* 1.2 Carpetas de trabajo *
capture mkdir "`c(sysdir_personal)'/SIM/"
capture mkdir "`c(sysdir_personal)'/users/"
capture mkdir "`c(sysdir_personal)'/users/$id/"



********************
***              ***
*** 2 PARÁMETROS ***
***		 ***
********************

** 2.1 Entidades Federativas **
global entidadesL `""Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"

** 2.2 Anio valor presente **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)
scalar aniovp = 2024

** 2.3 Política Fiscal **
global paqueteEconomico "Pre CGPE 2025"
scalar anioPE = 2024

** 2.4 Incidencia ENIGH **
if anioPE >= 2022 {
	scalar anioenigh = 2022
}
if anioPE >= 2020 & anioPE < 2022 {
	scalar anioenigh = 2020
}
if anioPE >= 2018 & anioPE < 2020 {
	scalar anioenigh = 2018
}
if anioPE >= 2016 & anioPE < 2018 {
	scalar anioenigh = 2016
}

** 2.5 Economía: Crecimiento anual del Producto Interno Bruto **
scalar pib2024 = 2.578
scalar pib2025 = 2.5007
scalar pib2026 = 2.5
scalar pib2027 = 2.5
scalar pib2028 = 2.5
scalar pib2029 = 2.5
forvalues k = 2030(1)2040 {
	scalar pib`k' = scalar(pib2029)
}

** 2.6 Economía: Deflactor del Producto Interno Bruto **
scalar def2024 = 4.1
scalar def2025 = 3.9
scalar def2026 = 3.5
scalar def2027 = 3.5
scalar def2028 = 3.5
scalar def2029 = 3.5
forvalues k = 2030(1)2040 {
	scalar def`k' = scalar(def2029)
}

** 2.7 Economía: Inflación **
scalar inf2024 = 3.8
scalar inf2025 = 3.3
scalar inf2026 = 3.0
scalar inf2027 = 3.0
scalar inf2028 = 3.0
scalar inf2029 = 3.0
forvalues k = 2030(1)2040 {
	scalar inf`k' = scalar(inf2029)
}

** 2.8 Deuda Pública **
scalar tasaEfectiva = 6.2166

scalar shrfsp2024 = 50.2
scalar shrfspInterno2024 = 38.8
scalar shrfspExterno2024 = 11.4
scalar rfsp2024 = -5.9
scalar rfspPIDIREGAS2024 = -0.1
scalar rfspIPAB2024 = -0.1
scalar rfspFONADIN2024 = -0.1
scalar rfspDeudores2024 = 0.0
scalar rfspBanca2024 = 0.1
scalar rfspAdecuaciones2024 = -0.6
scalar rfspBalance2024 = -5.0
scalar tipoDeCambio2024 = 17.6
scalar balprimario2024 = -1.2
scalar costodeudaInterno2024 = 3.6
scalar costodeudaExterno2024 = 3.6

scalar shrfsp2025 = 50.2
scalar shrfspInterno2025 = 39.0
scalar shrfspExterno2025 = 11.2
scalar rfsp2025 = -3.0
scalar rfspPIDIREGAS2025 = -0.1
scalar rfspIPAB2025 = -0.1
scalar rfspFONADIN2025 = 0.0
scalar rfspDeudores2025 = 0.0
scalar rfspBanca2025 = 0.0
scalar rfspAdecuaciones2025 = -0.3
scalar rfspBalance2025 = -2.5
scalar tipoDeCambio2025 = 17.9
scalar balprimario2025 = -0.9
scalar costodeudaInterno2025 = 3.4
scalar costodeudaExterno2025 = 3.4

scalar shrfsp2026 = 49.4
scalar shrfspInterno2026 = 38.0
scalar shrfspExterno2026 = 10.9
scalar rfsp2026 = -2.7
scalar rfspPIDIREGAS2026 = -0.1
scalar rfspIPAB2026 = -0.1
scalar rfspFONADIN2026 = 0.0
scalar rfspDeudores2026 = 0.0
scalar rfspBanca2026 = 0.0
scalar rfspAdecuaciones2026 = -0.3
scalar rfspBalance2026 = -2.5
scalar tipoDeCambio2026 = 18.1
scalar balprimario2026 = -0.5
scalar costodeudaInterno2026 = 2.7
scalar costodeudaExterno2026 = 2.7

scalar shrfsp2027 = 48.8
scalar shrfspInterno2027 = 38.3
scalar shrfspExterno2027 = 10.6
scalar rfsp2027 = -2.7
scalar rfspPIDIREGAS2027 = -0.1
scalar rfspIPAB2027 = -0.1
scalar rfspFONADIN2027 = 0.0
scalar rfspDeudores2027 = 0.1
scalar rfspBanca2027 = 0.0
scalar rfspAdecuaciones2027 = -0.4
scalar rfspBalance2027 = -2.2
scalar tipoDeCambio2027 = 18.2
scalar balprimario2027 = -0.3
scalar costodeudaInterno2027 = 2.5
scalar costodeudaExterno2027 = 2.5

scalar shrfsp2028 = 48.8
scalar shrfspInterno2028 = 38.6
scalar shrfspExterno2028 = 10.3
scalar rfsp2028 = -2.7
scalar rfspPIDIREGAS2028 = -0.1
scalar rfspIPAB2028 = -0.1
scalar rfspFONADIN2028 = 0.1
scalar rfspDeudores2028 = 0.0
scalar rfspBanca2028 = 0.0
scalar rfspAdecuaciones2028 = -0.3
scalar rfspBalance2028 = -2.2
scalar tipoDeCambio2028 = 18.4
scalar balprimario2028 = -0.3
scalar costodeudaInterno2028 = 2.5
scalar costodeudaExterno2028 = 2.5

scalar shrfsp2029 = 48.8
scalar shrfspInterno2029 = 38.9
scalar shrfspExterno2029 = 10.0
scalar rfsp2029 = -2.7
scalar rfspPIDIREGAS2029 = -0.1
scalar rfspIPAB2029 = -0.1
scalar rfspFONADIN2029 = 0.0
scalar rfspDeudores2029 = 0.0
scalar rfspBanca2029 = 0.0
scalar rfspAdecuaciones2029 = -0.3
scalar rfspBalance2029 = -2.2
scalar tipoDeCambio2029 = 18.6
scalar balprimario2029 = -0.3
scalar costodeudaInterno2029 = 2.5
scalar costodeudaExterno2029 = 2.5

scalar shrfsp2030 = 48.8
scalar shrfspInterno2030 = 38.9
scalar shrfspExterno2030 = 10.0
scalar rfsp2030 = -2.7
scalar rfspPIDIREGAS2030 = -0.1
scalar rfspIPAB2030 = -0.1
scalar rfspFONADIN2030 = 0.0
scalar rfspDeudores2030 = 0.0
scalar rfspBanca2030 = 0.0
scalar rfspAdecuaciones2030 = -0.3
scalar rfspBalance2030 = -2.2
scalar tipoDeCambio2030 = 18.6
scalar balprimario2030 = -0.3
scalar costodeudaInterno2030 = 2.5
scalar costodeudaExterno2030 = 2.5


** 2.9 Parámetros: PEF **
** 2.9.1 Parámetros: Educación **
scalar iniciaA     =     372 //    Inicial
scalar basica      =   28768 //    Educación b{c a'}sica
scalar medsup      =   28517 //    Educación media superior
scalar superi      =   40942 //    Educación superior
scalar posgra      =   67068 //    Posgrado
scalar eduadu      =   40494 //    Educación para adultos
scalar otrose      =    1781 //    Otros gastos educativos
scalar invere      =     848 //    Inversión en educación
scalar cultur      =     157 //    Cultura, deportes y recreación
scalar invest      =     403 //    Ciencia y tecnología

** 2.9.2 Parámetros: Salud **
scalar ssa         =      62 //    SSalud
scalar imssbien    =    5787 //    IMSS-Bienestar
scalar imss        =    8790 //    IMSS (salud)
scalar issste      =   10123 //    ISSSTE (salud)
scalar pemex       =   31969 //    Pemex (salud)
scalar issfam      =   20580 //    ISSFAM (salud)
scalar invers      =     261 //    Inversión en salud

** 2.9.3 Parámetros: Pensiones **
scalar pam         =   39142 //    Pensión Bienestar
scalar penimss     =  286655 //    Pensión IMSS
scalar penisss     =  371619 //    Pensión ISSSTE
scalar penpeme     =  843855 //    Pensión Pemex
scalar penotro     = 3722282 //    Pensión CFE, LFC, ISSFAM, Ferronales

** 2.9.4 Parámetros: Energía **
scalar gascfe      =    2957 //    Gasto en CFE
scalar gaspemex    =    1061 //    Gasto en Pemex
scalar gassener    =     654 //    Gasto en SENER
scalar gasinverf   =    3786 //    Gasto en inversión (energía)
scalar gascosdeue  =    1384 //    Gasto en costo de la deuda (energía)

** 2.9.5 Parámetros: Otros gastos **
scalar gasinfra    =    4371 //    Gasto en Otras Inversiones
scalar gasotros    =    4877 //    Otros gastos
scalar gasfeder    =   10444 //    Participaciones y Otras aportaciones
scalar gascosto    =    8756 //    Gasto en Costo de la deuda

** 2.9.6 Parámetros: Transferencas **
scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no
scalar gasmadres   =     489 //    Apoyo a madres trabajadoras
scalar gascuidados =    3174 //    Gasto en cuidados

** 2.10 Parámetros: Ingresos **
scalar ISRAS       =   3.798 //    ISR (asalariados)
scalar ISRPF       =   0.241 //    ISR (personas f{c i'}sicas)
scalar CUOTAS      =   1.624 //    Cuotas (IMSS)

scalar ISRPM       =   4.181 //    ISR (personas morales)
scalar OTROSK      =   1.073 //    Productos, derechos, aprovech.

scalar FMP         =   0.920 //    Fondo Mexicano del Petróleo
scalar PEMEX       =   2.258 //    Organismos y empresas (Pemex)
scalar CFE         =   1.356 //    Organismos y empresas (CFE)
scalar IMSS        =   0.128 //    Organismos y empresas (IMSS)
scalar ISSSTE      =   0.162 //    Organismos y empresas (ISSSTE)

scalar IVA         =   4.036 //    IVA
scalar ISAN        =   0.059 //    ISAN
scalar IEPSNP      =   0.703 //    IEPS (no petrolero)
scalar IEPSP       =   1.384 //    IEPS (petrolero)
scalar IMPORT      =   0.309 //    Importaciones

** 2.11 Parámetros: ISR **
* Anexo 8 de la Resolución Miscelánea Fiscal para 2024 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2024 a que se refieren los artículos 97 y 152 de la Ley del ISR
* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR			SUPERIOR		CF		TASA
matrix ISR =  (0.01,			8952.49,		0.0,		1.92	\    /// 1
		8952.49+.01,		75984.55,		171.88,		6.40	\    /// 2
		75984.55+.01,		133536.07,		4461.94,	10.88	\    /// 3
		133536.07+.01,		155229.80,		10723.55,	16.00	\    /// 4
		155229.80+.01,		185852.57,		14194.54,	17.92	\    /// 5
		185852.57+.01,		374837.88,		19682.13,	21.36	\    /// 6
		374837.88+.01,		590795.99,		60049.40,	23.52	\    /// 7
		590795.99+.01,		1127926.84,		110842.74,	30.00	\    /// 8
		1127926.84+.01,		1503902.46,		271981.99,	32.00	\    /// 9
		1503902.46+.01,		4511707.37,		392294.17,	34.00	\    /// 10
		4511707.37+.01,		1E+12,			1414947.85,	35.00)	     //  11

*             INFERIOR			SUPERIOR		SUBSIDIO
matrix	SE =  (0.01,			1768.96*12,		407.02*12		\    /// 1
		1768.96*12+.01,		2653.38*12,		406.83*12		\    /// 2
		2653.38*12+.01,		3472.84*12,		406.62*12		\    /// 3
		3472.84*12+.01,		3537.87*12,		392.77*12		\    /// 4
		3537.87*12+.01,		4446.15*12,		382.46*12		\    /// 5
		4446.15*12+.01,		4717.18*12,		354.23*12		\    /// 6
		4717.18*12+.01,		5335.42*12,		324.87*12		\    /// 7
		5335.42*12+.01,		6224.67*12,		294.63*12		\    /// 8
		6224.67*12+.01,		7113.90*12,		253.54*12		\    /// 9
		7113.90*12+.01,		7382.33*12,		217.61*12		\    /// 10
		7382.33*12+.01,		1E+12,			0)		 	     //  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,		15,			87.30, 			25.02)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			30.55)

** 2.12 Parámetros: IMSS e ISSSTE **
* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
matrix CSS_IMSS = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(5.42,		0.44,			3.21	\   /// Enfermedad y maternidad, asegurados (Tgmasg*)
		1.05,		0.37,			0.08	\   /// Enfermedad y maternidad, pensionados (Tgmpen*)
		1.75,		0.63,			0.13	\   /// Invalidez y vida (Tinvyvida*)
		1.83,		0.00,			0.00	\   /// Riesgos de trabajo (Triesgo*)
		1.00,		0.00,			0.00	\   /// Guarderias y prestaciones sociales (Tguard*)
		5.15,		1.12,			1.49	\   /// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
		0.00,		0.00,			6.55)	    //  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

* Informe Financiero Actuarial ISSSTE 2021 *
matrix CSS_ISSSTE = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(7.375,		2.750,			391.0	\   /// Seguro de salud, trabajadores en activo y familiares (Tfondomed* / TCuotaSocISSTEF)
		0.720,		0.625,			0.000	\   /// Seguro de salud, pensionados y familiares (Tpensjub*)
		0.750,		0.000,			0.000	\   /// Riesgo de trabajo
		0.625,		0.625,			0.000	\   /// Invalidez y vida
		0.500,		0.500,			0.000	\   /// Servicios sociales y culturales
		6.125,		2+3.175,		5.500	\   /// Retiro, cesantia en edad avanzada y vejez
		0.000,		5.000,			0.000	\   /// Vivienda
		0.000,		0.000,			13.9)		//  Cuota social

** 2.13 Parámetros: IVA **
matrix IVAT = (16 \     ///  1  Tasa general 
	1  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
	2  \     ///  3  Alquiler, idem
	1  \     ///  4  Canasta basica, idem
	2  \     ///  5  Educacion, idem
	3  \     ///  6  Consumo fuera del hogar, idem
	3  \     ///  7  Mascotas, idem
	1  \     ///  8  Medicinas, idem
	1  \     ///  9  Toallas sanitarias, idem
	3  \     /// 10  Otros, idem
	2  \     /// 11  Transporte local, idem
	3  \     /// 12  Transporte foraneo, idem
	7.77)   //  13  Evasion e informalidad IVA, input[0-100]

** 2.14 Parámetros: IEPS **
* Fuente: Ley del IEPS, Artículo 2.
*              Ad valorem		Específico
matrix IEPST = (26.5	,		0 			\ /// Cerveza y alcohol 14
				30.0	,		0 			\ /// Alcohol 14+ a 20
				53.0	,		0 			\ /// Alcohol 20+
				160.0	,		0.6166		\ /// Tabaco y cigarros
				30.0	,		0 			\ /// Juegos y sorteos
				3.0		,		0 			\ /// Telecomunicaciones
				25.0	,		0 			\ /// Bebidas energéticas
				0		,		1.5737		\ /// Bebidas saborizadas
				8.0		,		0 			\ /// Alto contenido calórico
				0		,		10.7037		\ /// Gas licuado de petróleo (propano y butano)
				0		,		21.1956		\ /// Combustibles (petróleo)
				0		,		19.8607		\ /// Combustibles (diésel)
				0		,		43.4269		\ /// Combustibles (carbón)
				0		,		21.1956		\ /// Combustibles (combustible para calentar)
				0		,		6.1752		\ /// Gasolina: magna
				0		,		5.2146		\ /// Gasolina: premium
				0		,		6.7865		) // Gasolina: diésel



********************
***              ***
*** 3 BIENVENIDA ***
***		         ***
********************
noisily di in w _newline(50) "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline(2) in g `"{bf:{stata `"projmanager "`c(sysdir_personal)'/simulador.stpr""': Simulador Fiscal CIEP}}"'
noisily di in g " Información Económica:  " _col(30) in y "$paqueteEconomico" ///
	_newline in g " Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g " Año de ENIGH:  " _col(30) in y "`=anioenigh'" ///
	_newline in g " User: " _col(30) in y "$id" ///
	_newline(2) " CLICK para ejecutar los comandos o usar la siguiente sintaxis: "

noisily di _newline `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre}"] [, ANIOinicial(int) ANIOFINal(int) NOGraphs]"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs]"'
noisily di `" {stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs]"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs]"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs]"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES]"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)]"'
