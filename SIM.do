****
**** SIMULADOR FISCAL CIEP
****
**** Autor: Ricardo Cantú Calderón
**** Email: ricardocantu@ciep.mx
**** Fecha: 9 de mayo de 2025
**** Manual: ReadMe.md
****


  
***
**# 0. SET UP
***
clear all
macro drop _all
capture log close _all
set scheme ciepnew
timer on 1

** Directorios de trabajo (uno por computadora)
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	*global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {					// Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	*global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set SITE "/SIM/OUT/7/"
}
cd "`c(sysdir_site)'"

** Parámetros
global id = "ciepmx"								// ID USUARIO
scalar aniovp = 2026								// ANIO VALOR PRESENTE
scalar anioPE = 2025								// ANIO PAQUETE ECONÓMICO
scalar anioenigh = 2024								// ANIO ENIGH

** Opciones
//global nographs "nographs"							// SUPRIMIR GRAFICAS
//global update "update"							// UPDATE BASES DE DATOS
//global textbook "textbook"							// SCALAR TO LATEX

** Output (web)
//global output "output"							// ARCHIVO DE SALIDA (WEB)
if "$output" != "" {
	capture mkdir "`c(sysdir_site)'/users/$id"
	quietly log using `"`c(sysdir_site)'/users/$id/Expenditures.smcl"', replace name(SIM)
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



***
**# 1. DEMOGRAFÍA
/***
noisily Poblacion, anioi(`=aniovp') aniofinal(2050) $textbook $nographs



**/
**# 2. ECONOMÍA
***
global paqueteEconomico "CGPE 2026"						// POLÍTICA FISCAL

** 2.1 Producto Interno Bruto (inputs opcionales)
global pib2025 = 1.5								// CRECIMIENTO ANUAL PIB
global pib2026 = 2.1								// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5
global pib2030 = 2.5
global pib2031 = 2.5

** 2.2 Deflactor (inputs opcionales)
global def2025 = 4.4								// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.0								// <-- AGREGAR O QUITAR AÑOS
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5
global def2030 = 3.5
global def2031 = 3.5

** 2.3 Inflación (inputs opcionales)
global inf2025 = 3.5								// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.0								// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0
global inf2031 = 3.0

noisily PIBDeflactor if anio >= 2005, aniovp(`=aniovp') aniomax(2031) $textbook $update nographs

** 2.4 Sistema de Cuentas Nacionales (sin inputs)
noisily SCN, anio(`=aniovp') $textbook $update nographs



**/
**# 3. HOGARES: ARMONIZACIÓN MACRO-MICRO
/***
forvalues anio = `=anioenigh'(-2)`=anioenigh' {

	** 3.1 Encuesta Nacional de Ingresos y Gastos de los Hogares (Usos)
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/expenditures.dta"
	//if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/Expenditure.do" `anio'

	** 3.2 Encuesta Nacional de Ingresos y Gastos de los Hogares (Recursos)
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/households.dta"
	//if _rc != 0 | "$update" == "update" ///
		noisily run `"`c(sysdir_site)'/Households.do"' `anio'
}

** 3.3 Perfiles de la política económica actual (Paquete Económico)
forvalues anio = `=anioPE'(-2)`=anioPE' {
	capture confirm file "`c(sysdir_site)'/04_master/perfiles`anio'.dta"
	//if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/PerfilesSim.do" `anio'
}



**/
**# 4. SISTEMA FISCAL
***

** 4.1 Ley de Ingresos de la Federación
if "$nographs" != "nographs" {
	*do "`c(sysdir_site)'/Graphs_TE.do"
}	
noisily LIF if divLIF != 10, anio(`=anioPE') by(divOrigen) $update 		///
	title("Ingresos presupuestarios") 					/// Cambiar título de la gráfica
	desde(`=`=anioPE'-12') 							/// Año de inicio para el PROMEDIO
	min(0.5) 									/// Mínimo 0% del PIB (no negativos)
	rows(1)									//  Número de filas en la leyenda
rename divSIM divCODE
decode divCODE, g(divSIM) 
collapse (sum) recaudacion, by(anio divSIM) fast
save `"`c(sysdir_site)'/users/$id/LIF.dta"', replace	


/** 4.1.1 Parámetros: Ingresos **
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

** 4.1.2 Parámetros: ISR **/
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
matrix	SE =  (0.01,		1768.96*12,	407.02*12*0	\	/// 1
		1768.96*12+.01,	2653.38*12,	406.83*12*0	\	/// 2
		2653.38*12+.01,	3472.84*12,	406.62*12*0	\	/// 3
		3472.84*12+.01,	3537.87*12,	392.77*12*0	\	/// 4
		3537.87*12+.01,	4446.15*12,	382.46*12*0	\	/// 5
		4446.15*12+.01,	4717.18*12,	354.23*12*0	\	/// 6
		4717.18*12+.01,	5335.42*12,	324.87*12*0	\	/// 7
		5335.42*12+.01,	6224.67*12,	294.63*12*0	\	/// 8
		6224.67*12+.01,	7113.90*12,	253.54*12*0	\	/// 9
		7113.90*12+.01,	7382.33*12,	217.61*12*0	\	/// 10
		7382.33*12+.01,	1E+12,		0)			//  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,		15,			77.60, 			12.22)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			35.85)

** 4.1.3 Parámetros: IMSS e ISSSTE **
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

** 4.1.4 Parámetros: IVA **
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

** 4.1.5 Parámetros: IEPS **
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

** 4.1.6 Submódulo ISR (web) **
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
** 4.1.7 Submódulo IVA (web) **
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVAPIB = IVA_Mod						// NUEVA ESTIMACIÓN IVA
	scalar IVA = IVAPIB/100*scalar(pibY)
}

** 4.1.8 Tasas Efectivas **
noisily TasasEfectivas, anio(`=anioPE') //eofp



**/
** 4.2 Presupuesto de Egresos de la Federación **
/**
noisily PEF, anio(`=anioPE') by(divSIM) ///$update 				///
	title("Gasto presupuestario") 						/// Cambiar título
	desde(`=`=anioPE'-12') 							/// Año de inicio PROMEDIO
	min(0) 									/// Mínimo 0% del PIB (resumido)
	rows(2)									// Número de filas en la leyenda


** 4.2.1 Parámetros: Gasto **/
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

** 4.2.2 Gasto per cápita **/
noisily GastoPC educacion salud pensiones energia resto transferencias, aniope(`=anioPE') aniovp(`=aniovp')



**/
** 4.3 Saldo Histórico de Requerimientos Financieros del Sector Público **
**

/* SHRFSP: Total, Interno, Externo (como % del PIB)
*                2025  2026  2027  2028  2029  2030
matrix shrfsp = (52.3, 52.3, 52.3, 52.3, 52.3, 52.3)

* SHRFSP: Total, PIDIREGAS, IPAB, FONADIN, Deudores, Banca, Adecuaciones, Balance (como % del PIB)
matrix rfsp =  (3.9, 0.15, 0.10, 0.03, 0.01,-0.01, 0.44, 3.2 \ 			/// 2025
		3.2, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.7 \ 			/// 2026
		2.9, 0.10, 0.10, 0.00,-0.10, 0.00, 0.30, 2.4 \ 			/// 2027
		2.9, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.4 \ 			/// 2028
		2.9, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.4 \ 			/// 2029
		2.9, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.4) 			//  2030

* SHRFSP: Tipo de cambio (MXN/USD)
*                      2025, 2026, 2027, 2028, 2029, 2030
matrix tipoDeCambio = (18.2, 18.5, 18.7, 18.9, 19.1, 19.3)

* Balance primario (como % del PIB)
*                     2025, 2026, 2027, 2028, 2029, 2030
matrix balprimario = (-1.4, -0.6, -0.5, -0.4, -0.4, -0.4)

* Costo de la deuda (como % del PIB)
*                   2025, 2026, 2027, 2028, 2029, 2030
matrix costodeuda = (3.6,  3.8,  3.2,  2.8,  2.7,  2.7)

forvalues k = 2025(1)2030 {
	local j = `k' - 2025 + 1
	global shrfsp`k' = shrfsp[1,`j']
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
	global costodeuda`k' = costodeuda[1,`j']
}

* SHRFSP: comando */
set scheme ciepdeuda
*scalar tasaEfectiva = 6.801
noisily SHRFSP, anio(`=anioPE') ultanio(2008) $nographs $update $textbook



**/
** 4.4 Subnacionales
**
//noisily run "Subnacional.do" $update



**/
**# 6. CICLO DE VIDA
***
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS_Sim ISRPF_Sim ISRPM_Sim CUOTAS_Sim)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA_Sim)
save `"`c(sysdir_site)'/users/$id/aportaciones.dta"', replace
capture drop ImpuestosAportaciones


** 6.1 (+) Impuestos y aportaciones
egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)
label var AlTrabajo "Impuestos al trabajo"

egen AlCapital = rsum(ISRPM_Sim OTROSK)
label var AlCapital "Impuestos al capital"

egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)
label var AlConsumo "Impuestos al consumo"

egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim) // FMP_Sim OTROSK_Sim
label var ImpuestosAportaciones "Impuestos y contribuciones"


** 6.2 (-) Gastos
label var Pensión_AM "Pensión para adultos mayores"
label var Educación "Educación"

capture drop Transferencias
egen Transferencias = rsum(Pensiones Pensión_AM IngBasico Educación Salud) // Otras_inversiones
label var Transferencias "Transferencias públicas"


** 6.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"

foreach k of varlist /*AlTrabajo AlCapital AlConsumo ImpuestosAportaciones ///
	ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim ///
	Pensiones Pensión_AM IngBasico Educación Salud Transferencias*/ AportacionesNetas {
	*noisily Perfiles `k' [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
	noisily Simulador `k' [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)
}


** 6.4 (*) Cuentas generacionales
*noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



**/
**# 7. DEUDA + FISCAL GAP + REDISTRIBUCIÓN
***

** 7.1 Brecha fiscal
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2015) $nographs desde(`=anioPE-15') discount(10) //update


** 7.2 Sankey del sistema fiscal
foreach k in decil grupoedad sexo rural escol {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=anioPE'
}



***/
**** Touchdown!!!
****
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
if "$output" == "output" run "`c(sysdir_site)'/output.do"
