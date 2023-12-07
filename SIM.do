***********************************
***                             ***
**#    SIMULADOR FISCAL CIEP    ***
***        ver: SIM.md          ***
***                             ***
***********************************
noisily run "`c(sysdir_personal)'/profile.do"                                   // PERFIL DE USUARIO


***************************************************
**  0.1 DIRECTORIO(S) DE TRABAJO (programación)  **
** Versión del simulador **
if "`c(username)'" == "ricardo" ///                                             // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///                       // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
cd `"`c(sysdir_personal)'"'


*****************************
**  0.2 Opciones globales  **
** Comentar o descomentar según sea el caso. **
//global id = "`c(username)'"                                                   // IDENTIFICADOR DEL USUARIO
//global export "`c(sysdir_personal)'../../Sostenibilidad 2024/images"          // DIRECTORIO DE IMÁGENES
//global nographs "nographs"                                                    // SUPRIMIR GRAFICAS
//global textbook "textbook"                                                    // GRÁFICOS FORMATO LaTeX
//global output "output"                                                        // OUTPUTS (WEB)
//global update "update"                                                        // UPDATE BASES DE DATOS

**  Rutas de archivos  **
capture mkdir `"`c(sysdir_personal)'/SIM/"'
capture mkdir `"`c(sysdir_personal)'/SIM/graphs"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$id/"'

**  Archivo output.txt (web)  **
if "$output" != "" {
	quietly log using `"`c(sysdir_personal)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}





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
//forvalues anio = 2016(1)`=anioPE' {                                            // <-- Año(s) de interés
	//foreach entidad of global entidadesL {                                     // <-- Nacional o para todas las entidades
		//noisily Poblacion if entidad == "`entidad'", anio(`=anioPE') $update
	//}
//}


******************
** 1.2 Economía **
** Fuente: CGPE 2024 (página 121)
** 1.2.1 Parámetros: Crecimiento anual del Producto Interno Bruto **
global pib2023 = 3.1766
global pib2024 = 2.6189
global pib2025 = 2.5097
global pib2026 = 2.4779
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5002

** 1.2.2 Parámetros: Crecimiento anual del índice de precios implícitos **
global def2023 = 5.0
global def2024 = 4.8
global def2025 = 3.5
global def2026 = 3.5
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5

** 1.2.3 Parámetros: Crecimiento anual del índice nacional de precios al consumidor **
global inf2023 = 5.7
global inf2024 = 4.5
global inf2025 = 3.4
global inf2026 = 3.0
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0

** 1.2.4 Proyecciones: PIB, Deflactor e Inflación **/
** Inputs: PIB, índice de precios implícitos, inpc, población y población ocupada.
** Outputs: Base de datos con su deflactor y productividad laboral para todos los años.
** Fuente: INEGI, BIE. Ver archivo "UpdatePIBDeflactor.do".
//noisily PIBDeflactor, geodef(2005) geopib(2005) $update

** 1.2.5 Proyecciones: Sistema de Cuentas Nacionales **
** Inputs: PIB, índice de precios implícitos, inpc, población y población ocupada.
** Outputs: Base de datos con las cuentas macroeconómicas para todos los años.
** Fuente: INEGI, BIE. Ver archivo "UpdatePIBDeflactor.do".
//noisily SCN, //$update


************************
** 1.3 Sistema fiscal **
** 1.3.1 Ley de Ingresos de la Federación **
** Inputs: LIFs + Estadísticas Oportunas. Archivo: LIFs.xlsx.
** Outputs: Bases de datos con ingresos, gastos y deuda para todos los años.
** Fuentes. SHCP, Estadísticas Oportunas. Ver archivos "UpdateLIF.do".
//noisily LIF, by(divPE) rows(1) min(0) anio(`=anioPE') $update desde(2018)

** 1.3.2 Presupuesto de Egresos de la Federación **
** Inputs: Cuentas Públicas y PEF/PPEF (varios años). Archivos: CPXXXX.xlsx, PEFXXXX.xlsx o PPEFXXXX.xlsx.
** Outputs: Bases de datos con gastos ejercidos/aprobados/proyectados para todos los años.
** Fuentes. SHCP, Cuentas Públicas. Ver archivo "UpdatePEF.do".
//noisily PEF, by(divCIEP) rows(2) min(0) anio(`=anioPE') $update desde(2018)

** 1.3.3 Saldo Histórico de los Requerimientos Financieros del Sector Público **
** Inputs: LIFs + Estadísticas Oportunas. Archivo: SHRFSP.dta.
** Outputs: Base de datos con SHRFSP para todos los años.
** Fuentes. SHCP, Estadísticas Oportunas. Ver archivo "UpdateSHRFSP.do".
scalar tasaEfectiva = 6.7358

scalar shrfsp2023 = 46.5
scalar shrfspInterno2023 = 34.7
scalar shrfspExterno2023 = 11.8
scalar rfsp2023 = -3.9
scalar rfspPIDIREGAS2023 = 0.0
scalar rfspIPAB2023 = -0.1
scalar rfspFONADIN2023 = -0.2
scalar rfspDeudores2023 = 0.0
scalar rfspBanca2023 = 0.0
scalar rfspAdecuaciones2023 = -0.4
scalar rfspBalance2023 = -3.3
scalar tipoDeCambio2023 = 17.5
scalar balprimario2023 = -0.1
scalar costodeudaInterno2023 = 3.4
scalar costodeudaExterno2023 = 3.4

scalar shrfsp2024 = 48.8
scalar shrfspInterno2024 = 37.4
scalar shrfspExterno2024 = 11.4
scalar rfsp2024 = -5.4
scalar rfspPIDIREGAS2024 = -0.1
scalar rfspIPAB2024 = -0.1
scalar rfspFONADIN2024 = -0.1
scalar rfspDeudores2024 = 0.0
scalar rfspBanca2024 = 0.0
scalar rfspAdecuaciones2024 = -0.2
scalar rfspBalance2024 = -4.9
scalar tipoDeCambio2024 = 17.6
scalar balprimario2024 = 1.2
scalar costodeudaInterno2024 = 3.7
scalar costodeudaExterno2024 = 3.7

scalar shrfsp2025 = 48.8
scalar shrfspInterno2025 = 37.7
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
scalar costodeudaInterno2025 = 3.1
scalar costodeudaExterno2025 = 3.1

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
scalar rfspBalance2026 = -2.2
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

** 1.2.5 Proyecciones: Saldo Histórico de los Requerimientos Financieros del Sector Público **
//noisily SHRFSP, ultanio(2016) anio(`=anioPE') $update


***********************
** 1.4 Subnacionales **
** Inputs: ingresos, gastos y deuda de los gobiernos subnacionales.
** Outputs: Bases de datos con ingresos, gastos y deuda para todos los años y todas las entidades federativas.
//noisily run "`c(sysdir_personal)'/Subnacional.do" //$update


********************************
** 1.5 Households information **
** Inputs: ENIGH `=anioenigh'. 
** Outputs: Archivo "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta".
//noisily run `"`c(sysdir_personal)'/Expenditure.do"' `=anioPE'
//noisily run `"`c(sysdir_personal)'/Households.do"' `=anioPE'


****************
** 1.6 Sankey **
** Inputs: Archivo "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta".
** Outputs: Archivos .json en carpeta "/var/www/html/SankeyNTA/.
//foreach k in grupoedad sexo decil rural escol {
	//run "`c(sysdir_personal)'/Sankey.do" `k' `=anioenigh' SankeyNTA
//}


*********************************************
** 1.7 Perfiles: ENIGH + $paqueteEconomico **
** Inputs: Archivo "`c(sysdir_personal)'/SIM/`enighanio'/households.dta".
** Outputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta".
//noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `=anioPE' 





*********************************/
***                            ***
**#    2. MÓDULOS SIMULADOR    ***
***                            ***
**********************************
** 2.1 Parámetros: ISR, IVA, IEPS, ISAN, Importaciones, etc. **
scalar ISRAS       =   3.643 // 100*scalar(pibY) *(1+ 3.782*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (asalariados)
scalar ISRPF       =   0.231 // 100*scalar(pibY) *(1+ 1.199*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas f{c i'}sicas)
scalar CUOTAS      =   1.557 // 100*scalar(pibY) *(1+ 2.197*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Cuotas (IMSS)

scalar ISRPM       =   4.010 // 100*scalar(pibY) *(1+ 4.664*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas morales)
scalar OTROSK      =   1.029 // 100*scalar(pibY) *(1+-3.269*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Productos, derechos, aprovech.

scalar FMP         =   0.882 // 100*scalar(pibY) *(1+-7.718*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Fondo Mexicano del Petróleo
scalar PEMEX       =   2.165 // 100*scalar(pibY) *(1+ 1.379*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (Pemex)
scalar CFE         =   1.300 // 100*scalar(pibY) *(1+-3.024*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (CFE)
scalar IMSS        =   0.123 // 100*scalar(pibY) *(1+-2.685*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (IMSS)
scalar ISSSTE      =   0.155 // 100*scalar(pibY) *(1+-3.058*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (ISSSTE)

scalar IVA         =   3.870 // 100*scalar(pibY) *(1+ 2.498*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IVA
scalar ISAN        =   0.057 // 100*scalar(pibY) *(1+ 3.565*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISAN
scalar IEPSNP      =   0.674 // 100*scalar(pibY) *(1+ 0.362*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IEPS (no petrolero)
scalar IEPSP       =   1.328 // IEPS (petrolero): 0.662
scalar IMPORT      =   0.297 // 100*scalar(pibY) *(1+ 5.303*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Importaciones


** 2.2 Educación **
scalar iniciaA     =     398 //    Inicial
scalar iniciaB     =     160 //    Comunitaria (CONAFE)

scalar basica      =   27429 //    Educación b{c a'}sica
scalar medsup      =   27811 //    Educación media superior
scalar superi      =   39927 //    Educación superior
scalar posgra      =   65408 //    Posgrado
scalar eduadu      =   39492 //    Educación para adultos
scalar otrose      =    1737 //    Otros gastos educativos

scalar invere      =     830 //    Inversión en educación

scalar cultur      =     153 //    Cultura, deportes y recreación
scalar invest      =     393 //    Ciencia y tecnología


** 2.3 Salud **
scalar salinf      =      69 //    Atención a NNA

scalar ssa         =      46 //    SSalud
scalar imssbien    =    5796 //    IMSS-Bienestar
scalar imss        =    8573 //    IMSS (salud)
scalar issste      =    9873 //    ISSSTE (salud)
scalar pemex       =   31176 //    Pemex (salud)
scalar issfam      =   20070 //    ISSFAM (salud)

scalar invers      =     255 //    Inversión en salud


** 2.4 Pensiones **
scalar pam         =   38172 //    Pensión Bienestar
scalar penimss     =  279557 //    Pensión IMSS
scalar penisss     =  362409 //    Pensión ISSSTE
scalar penpeme     =  822902 //    Pensión Pemex
scalar penotro     = 3629857 //    Pensión CFE, LFC, ISSFAM, Ferronales


** 2.5 Energía **
scalar gascfe      =    2884 //    Gasto en CFE
scalar gaspemex    =    1035 //    Gasto en Pemex
scalar gassener    =     638 //    Gasto en SENER

scalar gasinverf   =    3698 //    Gasto en inversión (energía)

scalar gascosdeue  =    1349 //    Gasto en costo de la deuda (energía)


** 2.6 Otros gastos **/
scalar gasinfra    =    4227 //    Gasto en Otras Inversiones
scalar gasotros    =    4840 //    Otros gastos
scalar gasfeder    =   10224 //    Participaciones y Otras aportaciones
scalar gascosto    =    8539 //    Gasto en Costo de la deuda


** 2.7 Transferencas **
scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no

scalar gasmadres   =     472 //    Apoyo a madres trabajadoras
scalar gascuidados =    1726 //    Gasto en cuidados


** 2.8 ISR **/
** Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
** Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalars ISRAS, ISRPF, ISRPM y CUOTAS.
* Anexo 8 de la Resolución Miscelánea Fiscal para 2023 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2023 (página 782) *
*             INFERIOR			SUPERIOR	CF		TASA
matrix ISR =  (0.01,			8952.49,	0.0,		1.92	\    /// 1
			8952.49    +.01,	75984.55,	171.88,		6.40	\    /// 2
			75984.55   +.01,	133536.07,	4461.94,	10.88	\    /// 3
			133536.07  +.01,	155229.80,	10723.55,	16.00	\    /// 4
			155229.80  +.01,	185852.57,	14194.54,	17.92	\    /// 5
			185852.57  +.01,	374837.88,	19682.13,	21.36	\    /// 6
			374837.88  +.01,	590795.99,	60049.40,	23.52	\    /// 7
			590795.99  +.01,	1127926.84,	110842.74,	30.00	\    /// 8
			1127926.84 +.01,	1503902.46,	271981.99,	32.00	\    /// 9
			1503902.46 +.01,	3511707.37,	392294.17,	34.00	\    /// 10
			3511707.37 +.01,	1E+12,		1414947.85,	35.00)	     //  11

* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR		SUPERIOR	SUBSIDIO
matrix	SE =  (0.01,		1768.96,	407.02		\    /// 1
			1768.96 +.01,	2653.38,	406.83		\    /// 2
			2653.38 +.01,	3472.84,	406.62		\    /// 3
			3472.84 +.01,	3537.87,	392.77		\    /// 4
			3537.87 +.01,	4446.15,	382.46		\    /// 5
			4446.15 +.01,	4717.18,	354.23		\    /// 6
			4717.18 +.01,	5335.42,	324.87		\    /// 7
			5335.42 +.01,	6224.67,	294.63		\    /// 8
			6224.67 +.01,	7113.90,	253.54		\    /// 9
			7113.90 +.01,	7382.33,	217.61		\    /// 10
			7382.33 +.01,   1E+12,		0)		 	     //  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,				15,					46.78, 				9.43)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			21.45)

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

if "`cambioisr'" == "1" {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
	scalar ISRAS  = ISR_AS_Mod
	scalar ISRPF  = ISR_PF_Mod
	scalar ISRPM  = ISR_PM_Mod
	scalar CUOTAS = CUOTAS_Mod
}


** 2.9 IVA **
** Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
** Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalar IVA.
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
			14.63)   //  13  Evasion e informalidad IVA, input[0-100]
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}


** 2.10 Integración de módulos ***
noisily TasasEfectivas, anio(`=anioPE') nog
noisily GastoPC, aniope(`=anioPE')





*****************************/
***                        ***
**#    3. CICLO DE VIDA    ***
***                        ***
******************************
** Inputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta".
** Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta".
capture use `"`c(sysdir_personal)'/users/$id/households.dta"', clear
if _rc != 0 {
	use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
}

** (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRAS ISRPF CUOTAS ISRPM IVA IEPSNP IEPSP ISAN IMPORT) //OTROSK
label var ImpuestosAportaciones "impuestos y aportaciones"

** (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Pension Educación Salud IngBasico Pensión_AM Inversión)
label var Transferencias "transferencias públicas"

** (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH `=anioenigh'") reboot anio(`=anioPE') $nographs //boot(20)
save "`c(sysdir_personal)'/users/$id/households.dta", replace


** (*) REDISTRIBUCIÓN **
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)


** (*) Sankey **
foreach k in decil grupoedad sexo rural /*escol*/ {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}





********************************************/
***                                       ***
**#    4. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
** Inputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta", SHRFSP, PEFs y LIFs.
** Outputs: Sostenibilidad de la deuda y brecha fiscal hasta 2030.
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
	run "`c(sysdir_personal)'/output.do"
}
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
