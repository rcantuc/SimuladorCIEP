****
**** SIMULADOR FISCAL CIEP (9 de mayo de 2025)
**** Manual: ReadMe.md
**** Autor: Ricardo Cantú Calderón
**** Email: ricardocantu@ciep.mx
****


  
***
**# 0. SET UP
***
clear all
macro drop _all
capture log close _all
timer on 1

** Directorios de trabajo (uno por computadora)
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	//global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {					// Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	//global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set SITE "/SIM/OUT/7/"
}

** Parámetros iniciales
scalar aniovp = 2025								// ANIO VALOR PRESENTE
scalar anioPE = 2025								// ANIO PAQUETE ECONÓMICO
scalar anioenigh = 2022								// ANIO ENIGH

global id = "ciepmx"								// ID USUARIO
global paqueteEconomico "CGPE 2025"						// POLÍTICA FISCAL

** Opciones
global nographs "nographs"							// SUPRIMIR GRAFICAS
//global update "update"							// UPDATE BASES DE DATOS
//global output "output"							// ARCHIVO DE SALIDA (WEB)
//global textbook "textbook"							// SCALAR TO LATEX

if "$output" != "" {
	capture mkdir "`c(sysdir_site)'/users/$id"
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



***
**# 1. DEMOGRAFÍA
***

** 1.1 Pirámide demográfica 
//foreach entidad of global entidadesL {
	forvalues anio = `=anioPE'(1)`=anioPE' {
		//noisily Poblacion if entidad == "`entidad'", anioi(`anio') aniofinal(`=`=anioPE'+25') $textbook
	}
//}



**/
**# 2. ECONOMÍA
***
global pib2025 = 1.5								// CRECIMIENTO ANUAL PIB
global pib2026 = 2.1								// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5
global pib2030 = 2.5
global pib2031 = 2.5

global def2025 = 4.4								// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.0								// <-- AGREGAR O QUITAR AÑOS
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5
global def2030 = 3.5
global def2031 = 3.5

global inf2025 = 3.5								// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.0								// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0
global inf2031 = 3.0


** 2.1 Producto Interno Bruto
//noisily PIBDeflactor, aniovp(`=aniovp') geodef(1993) geopib(1993) $update $textbook


** 2.2 Sistema de Cuentas Nacionales
//noisily SCN, anio(`=aniovp') $update $textbook



**/
**# 3. SISTEMA FISCAL
***

** 3.1 Ley de Ingresos de la Federación
noisily LIF if divLIF != 10, anio(`=anioPE') by(divSIM) ///$update 		///
	title("Ingresos presupuestarios") 					/// Cambiar título
	desde(`=`=anioPE'-12') 							/// Año de inicio PROMEDIO
	min(0) 									/// Mínimo 0% del PIB (no negativo)
	rows(1)									//  Número de filas en la leyenda

rename divSIM divCODE
decode divCODE, g(divSIM) 
collapse (sum) recaudacion, by(anio divSIM) fast
save `"`c(sysdir_site)'/users/$id/LIF.dta"', replace	

//postfile TE double(anio ISRAS ISRPF CUOTAS IngLab 				/// Impuestos al trabajo
	//ISRPM OTROSK IngCap 							/// Impuestos al capital
	//IVA ISAN IEPSNP IEPSP IMPORT Consumo 					/// Impuestos al consumo
	//FMP PEMEX CFE IMSS ISSSTE IngCapPub) 					/// Organismos y empresas públicas
	//using `"`c(sysdir_site)'/03_temp/TE.dta"', replace
forvalues anio = `=anioPE'(1)`=anioPE' {

	** 3.1.1 Parámetros: Ingresos **
	if "$update" != "update" {
		scalar ISRASPIB  =   3.670 					// ISR (asalariados)
		scalar ISRPFPIB  =   0.233 					// ISR (personas f{c i'}sicas)
		scalar CUOTASPIB =   1.675  					// Cuotas (IMSS)

		scalar ISRPMPIB  =   4.039  					// ISR (personas morales)
		scalar OTROSKPIB =   1.287 					// Productos, derechos, aprovech.

		scalar FMPPIB    =   0.777  					// Fondo Mexicano del Petróleo
		scalar PEMEXPIB  =   2.391  					// Organismos y empresas (Pemex)
		scalar CFEPIB    =   1.497  					// Organismos y empresas (CFE)
		scalar IMSSPIB   =   0.118  					// Organismos y empresas (IMSS)
		scalar ISSSTEPIB =   0.161  					// Organismos y empresas (ISSSTE)

		scalar IVAPIB    =   4.064  					// IVA
		scalar ISANPIB   =   0.056  					// ISAN
		scalar IEPSNPPIB =   0.667  					// IEPS (resumido)
		scalar IEPSPPIB  =   1.315 					// IEPS (petrolero)
		scalar IMPORTPIB =   0.422  					// Importaciones
	}

	** 3.1.2 Parámetros: ISR **
	* Anexo 8 de la Resolución Miscelánea Fiscal para 2025 *
	* Tarifa para el cálculo del impuesto correspondiente al ejericio 2025 
	* a que se refieren los artículos 97 y 152 de la Ley del ISR
	* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
	*             INFERIOR		SUPERIOR	CF		TASA
	matrix ISR =  (0.01,		8952.49,	0.0,		1.92	\	/// 1
			8952.49+.01,	75984.55,	171.88,		6.40	\	/// 2
			75984.55+.01,	133536.07,	4461.94,	10.88	\	/// 3
			133536.07+.01,	155229.80,	10723.55,	16.00	\	/// 4
			155229.80+.01,	185852.57,	14194.54,	17.92	\	/// 5
			185852.57+.01,	374837.88,	19682.13,	21.36	\	/// 6
			374837.88+.01,	590795.99,	60049.40,	23.52	\	/// 7
			590795.99+.01,	1127926.84,	110842.74,	30.00	\	/// 8
			1127926.84+.01,	1503902.46,	271981.99,	32.00	\	/// 9
			1503902.46+.01,	4511707.37,	392294.17,	34.00	\	/// 10
			4511707.37+.01,	1E+12,		1414947.85,	35.00)		//  11

	*             INFERIOR		SUPERIOR	SUBSIDIO
	matrix	SE =  (0.01,		1768.96*12,	407.02*12	\	/// 1
			1768.96*12+.01,	2653.38*12,	406.83*12	\	/// 2
			2653.38*12+.01,	3472.84*12,	406.62*12	\	/// 3
			3472.84*12+.01,	3537.87*12,	392.77*12	\	/// 4
			3537.87*12+.01,	4446.15*12,	382.46*12	\	/// 5
			4446.15*12+.01,	4717.18*12,	354.23*12	\	/// 6
			4717.18*12+.01,	5335.42*12,	324.87*12	\	/// 7
			5335.42*12+.01,	6224.67*12,	294.63*12	\	/// 8
			6224.67*12+.01,	7113.90*12,	253.54*12	\	/// 9
			7113.90*12+.01,	7382.33*12,	217.61*12	\	/// 10
			7382.33*12+.01,	1E+12,		0)			//  11

	* Artículo 151, último párrafo (LISR) *
	*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
	matrix DED = (5,		15,			93.02, 			18.86)

	* Artículo 9, primer párrafo (LISR) * 
	*           Tasa ISR PM.	% Informalidad PM
	matrix PM = (30,			48.45)

	** 3.1.3 Parámetros: IMSS e ISSSTE **
	* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
	* Anexo A, Cuadro A.4 *
	matrix CSS_IMSS = ///
	///	PATRONES	TRABAJADORES		GOBIERNO FEDERAL
		(5.42,		0.44,			3.21	\	/// Enfermedad y maternidad, asegurados (Tgmasg*)
		1.05,		0.37,			0.08	\	/// Enfermedad y maternidad, pensionados (Tgmpen*)
		1.75,		0.63,			0.13	\	/// Invalidez y vida (Tinvyvida*)
		1.83,		0.00,			0.00	\	/// Riesgos de trabajo (Triesgo*)
		1.00,		0.00,			0.00	\	/// Guarderias y prestaciones sociales (Tguard*)
		5.15,		1.12,			1.49	\	/// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
		0.00,		0.00,			6.55)		//  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

	* Informe Financiero Actuarial ISSSTE 2021 *
	matrix CSS_ISSSTE = ///
	///	PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(7.375,		2.750,			391.0	\	/// Seguro de salud, trabajadores
		0.720,		0.625,			0.000	\	/// Seguro de salud, pensionados
		0.750,		0.000,			0.000	\	/// Riesgo de trabajo
		0.625,		0.625,			0.000	\	/// Invalidez y vida
		0.500,		0.500,			0.000	\	/// Servicios sociales y culturales
		6.125,		2+3.175,		5.500	\	/// Retiro, cesantia en edad avanzada y vejez
		0.000,		5.000,			0.000	\	/// Vivienda
		0.000,		0.000,			13.9)		//  Cuota social

	** 3.1.4 Parámetros: IVA **
	matrix IVAT = (16 \     ///  1  Tasa general 
		1  \     						///  2  Alimentos, 1: Tasa Cero, 2: Exento, 3: Gravado
		2  \     						///  3  Alquiler, idem
		1  \     						///  4  Canasta basica, idem
		2  \    						///  5  Educacion, idem
		3  \     						///  6  Consumo fuera del hogar, idem
		3  \     						///  7  Mascotas, idem
		1  \     						///  8  Medicinas, idem
		1  \     						///  9  Toallas sanitarias, idem
		3  \     						/// 10  Otros, idem
		2  \     						/// 11  Transporte local, idem
		3  \     						/// 12  Transporte foraneo, idem
		15.09)   						//  13  Evasion e informalidad IVA, input[0-100]

	** 3.1.5 Parámetros: IEPS **
	* Fuente: Ley del IEPS, Artículo 2.
	*		Ad valorem	Específico
	matrix IEPST = (26.5	,	0 		\		/// Cerveza y alcohol 14
			30.0	,	0 		\		/// Alcohol 14+ a 20
			53.0	,	0 		\		/// Alcohol 20+
			160.0	,	0.6166		\		/// Tabaco y cigarros
			30.0	,	0 		\		/// Juegos y sorteos
			3.0	,	0 		\		/// Telecomunicaciones
			25.0	,	0 		\		/// Bebidas energéticas
			0	,	1.5737		\		/// Bebidas saborizadas
			8.0	,	0 		\		/// Alto contenido calórico
			0	,	10.7037		\		/// Gas licuado de petróleo (propano y butano)
			0	,	21.1956		\		/// Combustibles (petróleo)
			0	,	19.8607		\		/// Combustibles (diésel)
			0	,	43.4269		\		/// Combustibles (carbón)
			0	,	21.1956		\		/// Combustibles (combustible para calentar)
			0	,	6.1752		\		/// Gasolina: magna
			0	,	5.2146		\		/// Gasolina: premium
			0	,	6.7865		)		// Gasolina: diésel

	** 3.1.6 Submódulo ISR (web) **/
	if "`cambioisrpf'" == "1" {
		noisily run "`c(sysdir_site)'/ISR_Mod.do"
		scalar ISRASPIB  = ISR_AS_Mod					// NUEVA ESTIMACIÓN ISR ASALARIADOS
		scalar ISRAS = ISRASPIB/100*scalar(pibY)
		scalar ISRPFPIB  = ISR_PF_Mod					// NUEVA ESTIMACIÓN ISR P. FÍSICAS
		scalar ISRPF = ISRPFPIB/100*scalar(pibY)
		scalar ISRPMPIB  = ISR_PM_Mod					// NUEVA ESTIMACIÓN ISR P. MORALES
		scalar ISRPM = ISRPMPIB/100*scalar(pibY)
		scalar CUOTASPIB = CUOTAS_Mod					// NUEVA ESTIMACIÓN CUOTAS IMSS
		scalar CUOTAS = CUOTASPIB/100*scalar(pibY)
	}
	** 3.1.7 Submódulo IVA (web) **
	if "`cambioiva'" == "1" {
		noisily run "`c(sysdir_site)'/IVA_Mod.do"
		scalar IVAPIB = IVA_Mod						// NUEVA ESTIMACIÓN IVA
		scalar IVA = IVAPIB/100*scalar(pibY)
	}

	** 3.1.8 Tasas Efectivas **/
	//capture scalar drop ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA ISAN IEPSNP IEPSP IMPORT
	//noisily TasasEfectivas, anio(`anio')
	//post TE (`anio') (`=ISRASPor') (`=ISRPFPor') (`=CUOTASPor') (`=YlImpPor') ///
		//(`=ISRPMPor') (`=OTROSKPor') (`=IngKPrivadoTotPor') ///
		//(`=IVAPor') (`=ISANPor') (`=IEPSNPPor') (`=IEPSPPor') (`=IMPORTPor') (`=ingconsumoPor') ///
		//(`=FMPPor') (`=PEMEXPor') (`=CFEPor') (`=IMSSPor') (`=ISSSTEPor') (`=IngKPublicosTotPor')
}
//postclose TE

/** 3.1.3 Gráfica de tasas efectivas
if "$nographs" != "nographs" {
	use "`c(sysdir_site)'/03_temp/TE.dta", clear
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

	tabstat ISRAS if anio == `=anioPE' | anio == `=anioPE-25', by(anio) save
	tempname ISRAS
	matrix `ISRAS' = r(Stat1) \ r(Stat2)
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

	tabstat ISRPM if anio == `=anioPE' | anio == `=anioPE-25', by(anio) save
	tempname ISRPM
	matrix `ISRPM' = r(Stat1) \ r(Stat2)
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
}


**/
** 3.2 Presupuesto de Egresos de la Federación **
**
//noisily PEF, anio(`=anioPE') by(divSIM) ///$update 				///
	//title("Gasto presupuestario") 						/// Cambiar título
	//desde(`=`=anioPE'-12') 							/// Año de inicio PROMEDIO
	//min(0) 									/// Mínimo 0% del PIB (resumido)
	//rows(2)									// Número de filas en la leyenda

//postfile GastoPC double(anio iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
	//ssa imssbien imss issste pemex issfam invers ///
	//pam penimss penisss penpeme penotro ///
	//gascfe gaspemex gassener gasinverf gascosdeue ///
	//gasinfra gasotros gasfeder gascosto ///
	//IngBas gasmadres gascuidados) ///
	//using `"`c(sysdir_site)'/03_temp/GastoPC.dta"', replace
forvalues anio = `=anioPE'(1)`=anioPE' {

	** 3.2.1 Parámetros: Gasto **
	if "$update" != "update" {
		scalar iniciaA     =     370  					// Inicial
		scalar basica      =   29529  					// Educación b{c a'}sica
		scalar medsup      =   28713  					// Educación media superior
		scalar superi      =   41404  					// Educación superior
		scalar posgra      =   66122  					// Posgrado
		scalar eduadu      =   40517  					// Educación para adultos
		scalar otrose      =    1720  					// Otros gastos educativos
		scalar invere      =     675  					// Inversión en educación
		scalar cultur      =     173  					// Cultura, deportes y recreación
		scalar invest      =     398  					// Ciencia y tecnología

		scalar ssa         =     276  					// SSalud
		scalar imssbien    =    3728  					// IMSS-Bienestar
		scalar imss        =    8923  					// IMSS (salud)
		scalar issste      =   11161  					// ISSSTE (salud)
		scalar pemex       =   29562  					// Pemex (salud)
		scalar issfam      =   18040  					// ISSFAM (salud)
		scalar invers      =     240  					// Inversión en salud

		scalar pam         =   39356  					// Pensión Bienestar
		scalar penimss     =  307742  					// Pensión IMSS
		scalar penisss     =  410655  					// Pensión ISSSTE
		scalar penpeme     =  923092  					// Pensión Pemex
		scalar penotro     = 3336107  					// Pensión CFE, LFC, ISSFAM, Ferronales

		scalar gascfe      =    3146  					// Gasto en CFE
		scalar gaspemex    =    1129  					// Gasto en Pemex
		scalar gassener    =     690  					// Gasto en SENER
		scalar gasinverf   =    3182  					// Gasto en inversión (energía)
		scalar gascosdeue  =    1397  					// Gasto en costo de la deuda (energía)

		scalar gasinfra    =    3966  					// Gasto en Otras Inversiones
		scalar gasotros    =    4233  					// Otros gastos
		scalar gasfeder    =   10720  					// Participaciones y Otras aportaciones
		scalar gascosto    =    9356  					// Gasto en Costo de la deuda

		scalar ingbasico18 =       1  					// 1: Incluye menores de 18 anios, 0: no
		scalar ingbasico65 =       1  					// 1: Incluye mayores de 65 anios, 0: no
		scalar IngBas      =       0  					// Ingreso b{c a'}sico
		scalar gasmadres   =     492  					// Apoyo a madres trabajadoras
		scalar gascuidados =    3339  					// Gasto en cuidados
	}

	** 3.2.2 Gasto per cápita **/
	//capture scalar drop iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
		//ssa imssbien imss issste pemex issfam invers ///
		//pam penimss penisss penpeme penotro ///
		//gascfe gaspemex gassener gasinverf gascosdeue ///
		//gasinfra gasotros gasfeder gascosto ///
		//IngBas gasmadres gascuidados
	//noisily GastoPC, aniope(`anio') aniovp(`=aniovp')
	//post GastoPC (`anio') (`=iniciaA') (`=basica') (`=medsup') (`=superi') ///
		//(`=posgra') (`=eduadu') (`=otrose') (`=invere') (`=cultur') (`=invest') ///
		//(`=ssa') (`=imssbien') (`=imss') (`=issste') (`=pemex') (`=issfam') (`=invers') ///
		//(`=pam') (`=penimss') (`=penisss') (`=penpeme') (`=penotro') ///
		//(`=gascfe') (`=gaspemex') (`=gassener') (`=gasinverf') (`=gascosdeue') ///
		//(`=gasinfra') (`=gasotros') (`=gasfeder') (`=gascosto') ///
		//(`=IngBas') (`=gasmadres') (`=gascuidados')
}
//postclose GastoPC

/** 3.2.3 Gráficas de gastos per cápitas 
if "$nographs" != "nographs" {
	use "`c(sysdir_site)'/03_temp/GastoPC.dta", clear
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

**/
** 3.3 Saldo Histórico de Requerimientos Financieros del Sector Público **
**

* SHRFSP: Total, Interno, Externo (como % del PIB)
matrix shrfsp = (51.4, 39.8, 11.6 \ 	/// 2025
		 51.4, 40.5, 10.9 \ 	/// 2026
		 51.4, 40.8, 10.6 \ 	/// 2027
		 51.4, 41.1, 10.3 \ 	/// 2028
		 51.4, 41.4, 10.0 \ 	/// 2029
		 51.4, 41.7, 9.7)	//  2030

* SHRFSP: Total, PIDIREGAS, IPAB, FONADIN, Deudores, Banca, Adecuaciones, Balance (como % del PIB)
matrix rfsp = 	(5.9, -0.02, 0.03, 0.04, 0.01, -0.01, 0.81, 5.0 \ 		/// 2025
		3.9, 0.15, 0.1, 0.03, 0.01, -0.01, 0.44, 3.2 \ 			/// 2026
		3.2, 0.1, 0.1, 0.0, 0.0, 0.0, 0.3, 2.7 \ 			/// 2027
		2.9, 0.1, 0.1, 0.0, -0.1, 0.0, 0.3, 2.4 \ 			/// 2028
		2.9, 0.1, 0.1, 0.0, 0.0, 0.0, 0.3, 2.4 \ 			/// 2029
		2.9, 0.1, 0.1, 0.0, 0.0, 0.0, 0.3, 2.4)				//  2030

* SHRFSP: Tipo de cambio (MXN/USD)
matrix tipoDeCambio = (18.2, 							/// 2025
		 18.5, 								/// 2026
		 18.7, 								/// 2027
		 18.9, 								/// 2028
		 19.1, 								/// 2029
		 19.3) 								//  2030

* Balance primario (como % del PIB)
matrix balprimario = (-1.4,							/// 2025
		-0.6,								/// 2026
		-0.5,								/// 2027
		-0.4,								/// 2028
		-0.4,								/// 2029
		-0.4)								//  2030
* Costo de la deuda (como % del PIB)
matrix costodeudaInterno = (3.6, /// 2025
		3.8, 								/// 2026
		3.2, 								/// 2027
		2.8, 								/// 2028
		2.7, 								/// 2029
		2.7) 								//  2030
matrix costodeudaExterno = (3.6, ///
		3.8, 								/// 2025
		3.2, 								/// 2026
		2.8, 								/// 2027
		2.7, 								/// 2028
		2.7) 								//  2030

forvalues k = 2025(1)2030 {
	local j = `k' - 2025 + 1
	global shrfsp`k' = shrfsp[`j', 1]
	global shrfspInterno`k' = shrfsp[`j', 2]
	global shrfspExterno`k' = shrfsp[`j', 3]
	global rfsp`k' = rfsp[`j', 1]
	global rfspPIDIREGAS`k' = rfsp[`j', 2]
	global rfspIPAB`k' = rfsp[`j', 3]
	global rfspFONADIN`k' = rfsp[`j', 4]
	global rfspDeudores`k' = rfsp[`j', 5]
	global rfspBanca`k' = rfsp[`j', 6]
	global rfspAdecuaciones`k' = rfsp[`j', 7]
	global rfspBalance`k' = rfsp[`j', 8]
	global tipoDeCambio`k' = tipoDeCambio[`j',1]
	global balprimario`k' = balprimario[`j',1]
	global costodeudaInterno`k' = costodeudaInterno[`j',1]
	global costodeudaExterno`k' = costodeudaExterno[`j',1]
}

** 3.3.2 SHRFSP **/
scalar tasaEfectiva = 6.801
noisily SHRFSP, anio(`=anioPE') ultanio(2008) $nographs $update $textbook


**/
**# 4. HOGARES: ARMONIZACIÓN MACRO-MICRO
***
forvalues anio = `=anioPE'(-1)`=anioPE' {

	** 4.1 Encuesta Nacional de Ingresos y Gastos de los Hogares (Usos)
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/expenditures.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/Expenditure.do" `anio'


	** 4.2 Encuesta Nacional de Ingresos y Gastos de los Hogares (Recursos)
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/households.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run `"`c(sysdir_site)'/Households.do"' `anio'


	** 4.3 Perfiles de la política económica actual
	noisily di _newline in y "PerfilesSim `anio'"
	capture confirm file "`c(sysdir_site)'/04_master/perfiles`anio'.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/PerfilesSim.do" `anio'
}



** 5.4 Subnacionales
//noisily run "Subnacional.do" $update



**/
**# 6. CICLO DE VIDA
***
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA)
save `"`c(sysdir_site)'/users/$id/aportaciones.dta"', replace


** 6.1 (+) Impuestos y aportaciones
//egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)
//label var AlTrabajo "Impuestos al trabajo"
//noisily Perfiles AlTrabajo [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador AlTrabajo [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

//egen AlCapital = rsum(ISRPM_Sim OTROSK)
//label var AlCapital "Impuestos al capital"
//noisily Perfiles AlCapital [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador AlCapital [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

//egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)
//label var AlConsumo "Impuestos al consumo"
//noisily Perfiles AlConsumo [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador AlConsumo [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim) // FMP OTROSK
label var ImpuestosAportaciones "Impuestos y contribuciones"
//noisily Perfiles ImpuestosAportaciones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador ImpuestosAportaciones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)


** 6.2 (-) Gastos
//noisily Perfiles Pensiones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador Pensiones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

//label var Pensión_AM "Pensión para adultos mayores"
//noisily Perfiles Pensión_AM [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador Pensión_AM [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

//noisily Perfiles IngBasico [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador IngBasico [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

//label var Educación "Educación"
//noisily Perfiles Educación [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador Educación [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

//noisily Perfiles Salud [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador Salud [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

capture drop Transferencias
egen Transferencias = rsum(Pensiones Pensión_AM IngBasico Educación Salud) // Otras_inversiones
label var Transferencias "Transferencias públicas"
//noisily Perfiles Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)


** 6.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"
noisily Perfiles AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)


** 6.4 (*) Cuentas generacionales
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



**/
**# 7. DEUDA + FISCAL GAP + REDISTRIBUCIÓN
***

** 7.1 Brecha fiscal
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2015) $nographs desde(`=anioPE-15') discount(10) //update


** 7.2 Sankey del sistema fiscal
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=anioPE'
}



***/
**** Touchdown!!!
****
if "$output" == "output" ///
	run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
