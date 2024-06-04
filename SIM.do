***********************************
***                             ***
**#    SIMULADOR FISCAL CIEP    ***
***        ver: SIM.md          ***
***                             ***
***********************************
noisily run "`c(sysdir_personal)'/profile.do"                           // PERFIL DE USUARIO


*****************************
**  0.1 Opciones globales  **
** Agregar o modificar según sea necesario. **
global id = "ciepmx"                                                // IDENTIFICADOR DEL USUARIO
//global export "`c(sysdir_personal)'/SIM/graphs"                     // DIRECTORIO DE IMÁGENES
//global nographs "nographs"                                          // SUPRIMIR GRAFICAS
//global update "update"                                            // UPDATE BASES DE DATOS
//global output "output"                                            // ARCHIVO DE SALIDA (WEB)



****************************
** 0.2 Rutas de archivos  **
** Agregar o modificar según sea necesario. **
if "`c(username)'" == "ricardo" ///                                 // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///      // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else ///                                                            // Web
	sysdir set PERSONAL "/SIM/OUT/6/"







***************************
***                     ***
**#    1. MARCO MACRO   ***
***                     ***
***************************

*******************
** 1.1 Población **
** Parámetros: anio(s) de interés, entidad federativa.
** Outputs: población por edad, sexo y entidad federativa para todos los años.
** Outputs: gráfico de la pirámide y transición demográfica para el año de interés.
** Fuente: CONAPO 2023. Ver archivo "UpdatePoblacion.do".
//forvalues anio = 1950(1)`=anioPE' {                              // <-- Año(s) de interés
	//foreach entidad of global entidadesL {                            // <-- Nacional o para todas las entidades
		//noisily Poblacion if entidad == "`entidad'", anio(`=anioPE') aniofinal(2050) //$update   // Last updated: 9 de febrero de 2024
	//}
//}


******************
** 1.2 Economía **
** 1.2.1 Parámetros: Crecimiento anual del Producto Interno Bruto **
global pib2024 = 3.051 //2.591
global pib2025 = 2.5007
global pib2026 = 2.4779
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5002

** 1.2.2 Parámetros: Crecimiento anual del índice de precios implícitos **
global def2024 = 5.0 //4.1
global def2025 = 3.9
global def2026 = 3.5
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5

** 1.2.3 Parámetros: Crecimiento anual del índice nacional de precios al consumidor **
global inf2024 = 3.8
global inf2025 = 3.3
global inf2026 = 3.0
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0

* 1.2.4 Proyecciones: PIB, Deflactor e Inflación */
* Inputs: PIB, índice de precios implícitos, inpc, población y población ocupada.
* Outputs: Base de datos con su deflactor y productividad laboral para todos los años.
* Fuente: INEGI, BIE. Ver archivo "UpdatePIBDeflactor.do".
//noisily PIBDeflactor, geodef(2005) geopib(2005) $update aniovp(`=aniovp')

* 1.2.5 Proyecciones: Sistema de Cuentas Nacionales *
* Inputs: PIB, índice de precios implícitos, inpc, población y población ocupada.
* Outputs: Base de datos con las cuentas macroeconómicas para todos los años.
* Fuente: INEGI, BIE. Ver archivo "UpdatePIBDeflactor.do".
//noisily SCN, //$update


************************
** 1.3 Sistema fiscal **
* 1.3.1 Ley de Ingresos de la Federación *
* Inputs: LIFs + Estadísticas Oportunas. Archivo: LIFs.xlsx.
* Outputs: Bases de datos con ingresos, gastos y deuda para todos los años.
* Fuentes. SHCP, Estadísticas Oportunas. Ver archivos "UpdateLIF.do".
noisily LIF if divPE == 3 | divPE == 9, by(divCIEP) rows(1) anio(`=anioPE') $update desde(2000) min(0) title(" ")
exit
* 1.3.2 Presupuesto de Egresos de la Federación **
* Inputs: Cuentas Públicas y PEF/PPEF (varios años). Archivos: CPXXXX.xlsx, PEFXXXX.xlsx o PPEFXXXX.xlsx.
* Outputs: Bases de datos con gastos ejercidos/aprobados/proyectados para todos los años.
* Fuentes. SHCP, Cuentas Públicas. Ver archivo "UpdatePEF.do".
//noisily PEF, by(divCIEP) rows(2) min(0) anio(`=anioPE') $update desde(2018)


***********************
** 1.4 Subnacionales **
* Inputs: ingresos, gastos y deuda de los gobiernos subnacionales.
* Outputs: Bases de datos con ingresos, gastos y deuda para todos los años y todas las entidades federativas.
//noisily run "Subnacional.do" //$update


***************************
** 1.5 Perfiles fiscales **
* Inputs: ENIGHs (diversos años).
* Outputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`anio'.dta".
forvalues anio = `=anioPE'(2)`=anioPE' {
	capture confirm file "`c(sysdir_personal)'/SIM/perfiles`anio'.dta"
	if _rc != 0 ///
		noisily do "PerfilesSim.do" `anio'
}



*********************************/
***                            ***
**#    2. MÓDULOS SIMULADOR    ***
***                            ***
**********************************

******************************
** 2.1 Parámetros: Ingresos **
scalar ISRAS       =   3.691*1.014 // *(1+ r(EISRAS)*(${pib2023}-${pib2023_0})/100)) 		// ISR (asalariados)
scalar ISRPF       =   0.234*1.014 // *(1+ r(EISRPF)*(${pib2023}-${pib2023_0})/100)) 		// ISR (personas f{c i'}sicas)
scalar CUOTAS      =   1.578 // *(1+ r(ECUOTAS)*(${pib2023}-${pib2023_0})/100)) 	// Cuotas (IMSS)

scalar FMP         =   0.894*1.1 // *(1+ r(EFMP)*(${pib2023}-${pib2023_0})/100)) 		// Fondo Mexicano del Petróleo
scalar PEMEX       =   2.194*1.1 // *(1+ r(EPEMEX)*(${pib2023}-${pib2023_0})/100)) 		// Organismos y empresas (Pemex)
scalar CFE         =   1.317 // *(1+ r(ECFE)*(${pib2023}-${pib2023_0})/100)) 		// Organismos y empresas (CFE)
scalar IMSS        =   0.125 // *(1+ r(EIMSS)*(${pib2023}-${pib2023_0})/100)) 		// Organismos y empresas (IMSS)
scalar ISSSTE      =   0.157 // *(1+ r(EISSSTE)*(${pib2023}-${pib2023_0})/100)) 	// Organismos y empresas (ISSSTE)

scalar ISRPM       =   4.063*1.014 // *(1+ r(EISRPM)*(${pib2023}-${pib2023_0})/100)) 		// ISR (personas morales)
scalar OTROSK      =   1.043 // *(1+ r(EOTROSK)*(${pib2023}-${pib2023_0})/100)) 	// Productos, derechos, aprovech.

scalar IVA         =   3.921*1.014 // *(1+ r(EIVA)*(${pib2023}-${pib2023_0})/100)) 		// IVA
scalar ISAN        =   0.057*1.014 // *(1+ r(EISAN)*(${pib2023}-${pib2023_0})/100)) 		// ISAN
scalar IEPSNP      =   0.683*1.014 // *(1+ r(EIEPSNP)*(${pib2023}-${pib2023_0})/100))		// IEPS (no petrolero)
scalar IEPSP       =   1.345*1.014 // IEPS (petrolero): 0.662
scalar IMPORT      =   0.301 // *(1+ r(EIMPORT)*(${pib2023}-${pib2023_0})/100))		// Importaciones

*******************************/
** 2.2 Parámetros: Educación **
scalar iniciaA     =     417 //    Inicial

scalar basica      =   28017 //    Educación b{c a'}sica
scalar medsup      =   27811 //    Educación media superior
scalar superi      =   39927 //    Educación superior
scalar posgra      =   65408 //    Posgrado
scalar eduadu      =   39492 //    Educación para adultos
scalar otrose      =    1737 //    Otros gastos educativos

scalar invere      =     827 //    Inversión en educación

scalar cultur      =     153 //    Cultura, deportes y recreación
scalar invest      =     393 //    Ciencia y tecnología

***************************
** 2.3 Parámetros: Salud **
scalar ssa         =      60 //    SSalud
scalar imssbien    =    5644 //    IMSS-Bienestar
scalar imss        =    8573 //    IMSS (salud)
scalar issste      =    9873 //    ISSSTE (salud)
scalar pemex       =   31176 //    Pemex (salud)
scalar issfam      =   20070 //    ISSFAM (salud)

scalar invers      =     255 //    Inversión en salud

*******************************
** 2.4 Parámetros: Pensiones **
scalar pam         =   38172 //    Pensión Bienestar
scalar penimss     =  279557 //    Pensión IMSS
scalar penisss     =  362409 //    Pensión ISSSTE
scalar penpeme     =  822902 //    Pensión Pemex
scalar penotro     = 3629857 //    Pensión CFE, LFC, ISSFAM, Ferronales

*****************************
** 2.5 Parámetros: Energía **
scalar gascfe      =    2884 //    Gasto en CFE
scalar gaspemex    =    1035 //    Gasto en Pemex
scalar gassener    =     638 //    Gasto en SENER

scalar gasinverf   =    3692 //    Gasto en inversión (energía)

scalar gascosdeue  =    1349 //    Gasto en costo de la deuda (energía)

**********************************
** 2.6 Parámetros: Otros gastos **
scalar gasinfra    =    4263 //    Gasto en Otras Inversiones
scalar gasotros    =    4750 //    Otros gastos
scalar gasfeder    =   10185 //    Participaciones y Otras aportaciones
scalar gascosto    =    8539*.9730 //    Gasto en Costo de la deuda

***********************************
** 2.7 Parámetros: Transferencas **
scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no

scalar gasmadres   =     472 //    Apoyo a madres trabajadoras
scalar gascuidados =    1722 //    Gasto en cuidados

************************/
** 2.8 Parámetros: ISR **
** Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
** Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalars ISRAS, ISRPF, ISRPM y CUOTAS.
* Anexo 8 de la Resolución Miscelánea Fiscal para 2024 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2024 a que se refieren los artículos 97 y 152 de la Ley del ISR
*             INFERIOR			SUPERIOR		CF			TASA
matrix ISR =  (0.01,			8952.49,		0.0,		1.92	\    /// 1
			8952.49    +.01,	75984.55,		171.88,		6.40	\    /// 2
			75984.55   +.01,	133536.07,		4461.94,	10.88	\    /// 3
			133536.07  +.01,	155229.80,		10723.55,	16.00	\    /// 4
			155229.80  +.01,	185852.57,		14194.54,	17.92	\    /// 5
			185852.57  +.01,	374837.88,		19682.13,	21.36	\    /// 6
			374837.88  +.01,	590795.99,		60049.40,	23.52	\    /// 7
			590795.99  +.01,	1127926.84,		110842.74,	30.00	\    /// 8
			1127926.84 +.01,	1503902.46,		271981.99,	32.00	\    /// 9
			1503902.46 +.01,	4511707.37,		392294.17,	34.00	\    /// 10
			4511707.37 +.01,	1E+12,			1414947.85,	35.00)	     //  11

* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR			SUPERIOR		SUBSIDIO
matrix	SE =  (0.01,			1768.96*12,		407.02*12		\    /// 1
			1768.96*12 +.01,	2653.38*12,		406.83*12		\    /// 2
			2653.38*12 +.01,	3472.84*12,		406.62*12		\    /// 3
			3472.84*12 +.01,	3537.87*12,		392.77*12		\    /// 4
			3537.87*12 +.01,	4446.15*12,		382.46*12		\    /// 5
			4446.15*12 +.01,	4717.18*12,		354.23*12		\    /// 6
			4717.18*12 +.01,	5335.42*12,		324.87*12		\    /// 7
			5335.42*12 +.01,	6224.67*12,		294.63*12		\    /// 8
			6224.67*12 +.01,	7113.90*12,		253.54*12		\    /// 9
			7113.90*12 +.01,	7382.33*12,		217.61*12		\    /// 10
			7382.33*12 +.01,	1E+12,			0)		 	     //  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,				15,					50.95, 				52.76)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			16.16)

***********************************
** 2.9 Parámetros: IMSS e ISSSTE **
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

if "`cambioisrpf'" == "" {
	noisily run "ISR_Mod.do"
	scalar ISRAS  = ISR_AS_Mod
	scalar ISRPF  = ISR_PF_Mod
	scalar ISRPM  = ISR_PM_Mod
	scalar CUOTAS = CUOTAS_Mod
}


**************************
** 2.10 Parámetros: IVA **
* Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
* Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalar IVA.
matrix IVAT = (16 \     ///  1  Tasa general 
	1+2  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
	2+1  \     ///  3  Alquiler, idem
	1+2  \     ///  4  Canasta basica, idem
	2+1  \     ///  5  Educacion, idem
	3  \     ///  6  Consumo fuera del hogar, idem
	3  \     ///  7  Mascotas, idem
	1+2  \     ///  8  Medicinas, idem
	1+2  \     ///  9  Toallas sanitarias, idem
	3  \     /// 10  Otros, idem
	2+1  \     /// 11  Transporte local, idem
	3  \     /// 12  Transporte foraneo, idem
	28.22)   //  13  Evasion e informalidad IVA, input[0-100]

if "`cambioiva'" == "1" {
	noisily run "IVA_Mod.do"
	noisily di "IVA Anterior: " _col(20) %7.3fc scalar(IVA) " % PIB"
	noisily di "IVA Nuevo: " _col(20) %7.3fc scalar(IVA_Mod) " % PIB"
	noisily di "Cambio: " _col(20) %7.3fc scalar(IVA_Mod) - scalar(IVA) " % PIB"
	noisily di "Porcentaje: " _col(20) %7.3fc (scalar(IVA_Mod) - scalar(IVA))/scalar(IVA)*100
	scalar IVA = IVA_Mod
}


***************************
** 2.11 Parámetros: IEPS **
* Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
* Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalar IEPS.
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
				0		,		10.7037		\ /// Combustibles: gas licuado de petróleo (promedio propano y butano)
				0		,		21.1956		\ /// Combustibles (petróleo)
				0		,		19.8607		\ /// Combustibles (diésel)
				0		,		43.4269		\ /// Combustibles (carbón)
				0		,		21.1956		\ /// Combustibles (combustible para calentar)
				0		,		6.1752		\ /// Gasolina: magna
				0		,		5.2146		\ /// Gasolina: premium
				0		,		6.7865		) // Gasolina: diésel


*********************************/
** 2.12 Integración de módulos ***
noisily TasasEfectivas, anio(`=anioPE')
exit
noisily GastoPC, aniope(`=anioPE') aniovp(`=aniovp')



*****************************/
***                        ***
**#    3. CICLO DE VIDA    ***
***                        ***
******************************
use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "users/$id/gastos.dta", nogen
*capture merge 1:1 (folioviv foliohog numren) using "users/$id/isr_mod.dta", nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
*capture merge 1:1 (folioviv foliohog numren) using "users/$id/iva_mod.dta", nogen replace update keepus(IVA)

**************************************
** 3.1 (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(IVA FMP ISRAS ISRPF CUOTAS ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT) //
label var ImpuestosAportaciones "impuestos y aportaciones"

**************************************
** 3.2 (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Educación Pensiones Educación Salud IngBasico Pensión_AM Otras_inversiones) // 
label var Transferencias "transferencias públicas"

********************************
** 3.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Aportaciones netas"
noisily Perfiles AportacionesNetas [fw=factor], reboot aniovp(2024) aniope(`=anioPE') $nographs //boot(10)

************************************
** 3.4 (*) Cuentas generacionales **
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)

***************************************
** 3.5 (*) Sankey del sistema fiscal **
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "SankeySF.do" `k' `=anioPE'
}



********************************************/
***                                       ***
**#    4. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************

** 4.1 Saldo Histórico de los Requerimientos Financieros del Sector Público **
* Inputs: LIFs + Estadísticas Oportunas. Archivo: SHRFSP.dta.
* Outputs: Base de datos con SHRFSP para todos los años.
* Fuentes. SHCP, Estadísticas Oportunas. Ver archivo "UpdateSHRFSP.do".
scalar tasaEfectiva = 6.3858

scalar shrfsp2024 = 50.2
scalar shrfspInterno2024 = 38.8
scalar shrfspExterno2024 = 11.4
scalar rfsp2024 = -5.9
scalar rfspPIDIREGAS2024 = -0.1
scalar rfspIPAB2024 = -0.1
scalar rfspFONADIN2024 = -0.1
scalar rfspDeudores2024 = 0.0
scalar rfspBanca2024 = -0.1
scalar rfspAdecuaciones2024 = -0.6
scalar rfspBalance2024 = -5.0
scalar tipoDeCambio2024 = 17.6
scalar balprimario2024 = 1.2
scalar costodeudaInterno2024 = 3.6
scalar costodeudaExterno2024 = 3.6

scalar shrfsp2025 = 50.2
scalar shrfspInterno2025 = 39.0
scalar shrfspExterno2025 = 11.2
scalar rfsp2025 = -2.6
scalar rfspPIDIREGAS2025 = -0.1
scalar rfspIPAB2025 = -0.1
scalar rfspFONADIN2025 = 0.0
scalar rfspDeudores2025 = 0.0
scalar rfspBanca2025 = 0.0
scalar rfspAdecuaciones2025 = -0.2
scalar rfspBalance2025 = -2.1
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

** 4.2 Proyecciones: Saldo Histórico de los Requerimientos Financieros del Sector Público **/
//noisily SHRFSP, ultanio(2001) anio(`=anioPE') $update

** 4.3 Sostenibilidad de la deuda y brecha fiscal **
* Inputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta", SHRFSP, PEFs y LIFs.
* Outputs: Sostenibilidad de la deuda y brecha fiscal hasta 2030.
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2016) $nographs desde(2016) discount(10) //update //anio(`=aniovp')



***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$textbook" == "textbook" {
	noisily scalarlatex, logname(tasasEfectivas)
}
if "$output" == "output" {
	run "output.do"
}
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
