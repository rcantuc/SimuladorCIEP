***********************
***    1. SET UP    ***
***********************
if "`c(username)'" != "ciepmx" & "`c(username)'" != "ricardo" {
	global id = "`c(username)'"
}
capture mkdir `"`c(sysdir_personal)'/SIM/"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$id/"'

if "$output" != "" {
	quietly log using `"`c(sysdir_personal)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



************************************************
***    2. CRECIMIENTO Y DEFLACTOR DEL PIB    ***
************************************************
global pib2023 = 3.1766 //     CGPE 2024 (punto medio)
global pib2024 = 2.6189 //     CGPE 2024 (punto medio)
global pib2025 = 2.5097 //     CGPE 2024 (página 121)
global pib2026 = 2.4779 //     CGPE 2024 (página 121)
global pib2027 = 2.5 //     CGPE 2024 (página 121)
global pib2028 = 2.5 //     CGPE 2024 (página 121)
global pib2029 = 2.5002 //     CGPE 2024 (página 121)

global def2023 = 5.0 //     CGPE 2024 (página 121)
global def2024 = 4.8 //     CGPE 2024 (página 121)
global def2025 = 3.5 //     CGPE 2024 (página 121)
global def2026 = 3.5 //     CGPE 2024 (página 121)
global def2027 = 3.5 //     CGPE 2024 (página 121)
global def2028 = 3.5 //     CGPE 2024 (página 121)
global def2029 = 3.5 //     CGPE 2024 (página 121)



******************************
***    3. DEUDA PÚBLICA    ***
******************************
scalar shrfsp2023 = 46.5
scalar shrfspInterno2023 = 34.7
scalar shrfspExterno2023 = 11.8
scalar rfsp2023 = 3.9
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
scalar rfsp2024 = 5.4
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
scalar rfsp2025 = 2.6
scalar rfspPIDIREGAS2025 = -0.1
scalar rfspIPAB2025 = -0.1
scalar rfspFONADIN2025 = 0.0
scalar rfspDeudores2025 = 0.0
scalar rfspBanca2025 = 0.0
scalar rfspAdecuaciones2025 = -0.2
scalar rfspBalance2025 = -2.1
scalar tipoDeCambio2025 = 17.9
scalar balprimario2025 = -0.9
scalar costodeudaInterno2025 = 3.7
scalar costodeudaExterno2025 = 3.7

scalar shrfsp2026 = 49.4
scalar shrfspInterno2026 = 38.0
scalar shrfspExterno2026 = 10.9
scalar rfsp2026 = 2.7
scalar rfspPIDIREGAS2026 = -0.1
scalar rfspIPAB2026 = -0.1
scalar rfspFONADIN2026 = 0.0
scalar rfspDeudores2026 = 0.0
scalar rfspBanca2026 = 0.0
scalar rfspAdecuaciones2026 = -0.3
scalar rfspBalance2026 = -2.2
scalar tipoDeCambio2026 = 18.1
scalar balprimario2026 = -0.5
scalar costodeudaInterno2026 = 3.7
scalar costodeudaExterno2026 = 3.7

scalar shrfsp2027 = 48.8
scalar shrfspInterno2027 = 38.3
scalar shrfspExterno2027 = 10.6
scalar rfsp2027 = 2.7
scalar rfspPIDIREGAS2027 = -0.1
scalar rfspIPAB2027 = -0.1
scalar rfspFONADIN2027 = 0.0
scalar rfspDeudores2027 = 0.1
scalar rfspBanca2027 = 0.0
scalar rfspAdecuaciones2027 = -0.4
scalar rfspBalance2027 = -2.2
scalar tipoDeCambio2027 = 18.2
scalar balprimario2027 = -0.3
scalar costodeudaInterno2027 = 3.7
scalar costodeudaExterno2027 = 3.7

scalar shrfsp2028 = 48.8
scalar shrfspInterno2028 = 38.6
scalar shrfspExterno2028 = 10.3
scalar rfsp2028 = 2.7
scalar rfspPIDIREGAS2028 = -0.1
scalar rfspIPAB2028 = -0.1
scalar rfspFONADIN2028 = 0.1
scalar rfspDeudores2028 = 0.0
scalar rfspBanca2028 = 0.0
scalar rfspAdecuaciones2028 = -0.3
scalar rfspBalance2028 = -2.2
scalar tipoDeCambio2028 = 18.4
scalar balprimario2028 = -0.3
scalar costodeudaInterno2028 = 3.7
scalar costodeudaExterno2028 = 3.7

scalar shrfsp2029 = 48.8
scalar shrfspInterno2029 = 38.9
scalar shrfspExterno2029 = 10.0
scalar rfsp2029 = 2.7
scalar rfspPIDIREGAS2029 = -0.1
scalar rfspIPAB2029 = -0.1
scalar rfspFONADIN2029 = 0.0
scalar rfspDeudores2029 = 0.0
scalar rfspBanca2029 = 0.0
scalar rfspAdecuaciones2029 = -0.3
scalar rfspBalance2029 = -2.2
scalar tipoDeCambio2029 = 18.6
scalar balprimario2029 = -0.3
scalar costodeudaInterno2029 = 3.7
scalar costodeudaExterno2029 = 3.7


exit

************************/
***    3. INGRESOS    ***
*************************
scalar ISRAS   = 3.778 //100*scalar(pibY) *(1+ 3.782*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (asalariados)
scalar ISRPF   = 0.245 //100*scalar(pibY) *(1+ 1.199*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas f{c i'}sicas)
scalar CUOTAS  = 1.533 //100*scalar(pibY) *(1+ 2.197*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Cuotas (IMSS)

scalar FMP     = 1.586 //100*scalar(pibY) *(1+-7.718*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Fondo Mexicano del Petróleo
scalar PEMEX   = 2.690 //100*scalar(pibY) *(1+ 1.379*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (Pemex)
scalar CFE     = 1.299 //100*scalar(pibY) *(1+-3.024*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (CFE)
scalar IMSS    = 0.093 //100*scalar(pibY) *(1+-2.685*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (IMSS)
scalar ISSSTE  = 0.163 //100*scalar(pibY) *(1+-3.058*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (ISSSTE)

scalar ISRPM   = 4.154 //100*scalar(pibY) *(1+ 4.664*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas morales)
scalar OTROSK  = 1.072 //100*scalar(pibY) *(1+-3.269*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Productos, derechos, aprovech.

scalar IVA     = 4.620 //100*scalar(pibY) *(1+ 2.498*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IVA
scalar ISAN    = 0.050 //100*scalar(pibY) *(1+ 3.565*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISAN
scalar IEPSNP  = 0.676 //100*scalar(pibY) *(1+ 0.362*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IEPS (no petrolero)
scalar IEPSP   = 0.906 // IEPS (petrolero): 0.662
scalar IMPORT  = 0.320 //100*scalar(pibY) *(1+ 5.303*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Importaciones



**********************/
***    4. GASTOS    ***
***********************

** Educación **
scalar iniciaA     =     389 //    Inicial
scalar iniciaB     =     156 //    Comunitaria (CONAFE)

scalar basica      =   25962 //    Educación b{c a'}sica
scalar medsup      =   27556 //    Educación media superior
scalar superi      =   38085 //    Educación superior
scalar posgra      =   62801 //    Posgrado
scalar eduadu      =   37679 //    Educación para adultos
scalar otrose      =    1523 //    Otros gastos educativos

scalar invere      =     800 //    Inversión en educación

scalar cultur      =     150 //    Cultura, deportes y recreación
scalar invest      =     383 //    Ciencia y tecnología


** Salud **
scalar salinf      =     56 //    Atención a NNA

scalar ssa         =     599 //    SSalud
scalar imssbien    =    4324 //    IMSS-Bienestar
scalar imss        =    7749 //    IMSS (salud)
scalar issste      =   10385 //    ISSSTE (salud)
scalar pemex       =   30583 //    Pemex (salud)
scalar issfam      =   18012 //    ISSFAM (salud)

scalar invers      =     237 //    Inversión en salud


** Pensiones **
scalar pam         =   29057 //    Pensión Bienestar
scalar penimss     =  246921 //    Pensión IMSS
scalar penisss     =  336547 //    Pensión ISSSTE
scalar penpeme     =  841446 //    Pensión Pemex
scalar penotro     = 3503173 //    Pensión CFE, LFC, ISSFAM, Ferronales


** Energía **
scalar gascfe      =    2556 //    Gasto en CFE
scalar gaspemex    =    1126 //    Gasto en Pemex
scalar gassener    =     615 //    Gasto en SENER

scalar gasinverf   =    4404 //    Gasto en inversión (energía)

scalar gascosdeue  =    1426 //    Gasto en costo de la deuda (energía)


** Otros gastos **
scalar gasinfra    =    4390 //    Gasto en Otras Inversiones
scalar gascuidados =     224 //    Gasto en cuidados
scalar gasotros    =    4225 //    Otros gastos
scalar gasfeder    =   10097 //    Participaciones y Otras aportaciones
scalar gascosto    =    7265 //    Gasto en Costo de la deuda


** Transferencas **
scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no

scalar gasmadres   =     462 //    Apoyo a madres trabajadoras










*global tasaEfectiva = 6.005578 // Tasa de inter{c e'}s EFECTIVA







*********************************************************************/
***       6.1. ISR_Mod.do (Salarios + PF + PM + Cuotas IMSS)       ***
/**********************************************************************
* Anexo 8 de la Resolución Miscelánea Fiscal para 2023 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2023 (página 782) *
*             INFERIOR		SUPERIOR	CF		TASA
matrix ISR =  (0.01,		8952.49,	0.0,		1.92	\    /// 1
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
              7382.33 +.01, 	1E+12,		0)		     //  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,		15,			46.78, 			9.43)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,		21.45)

* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
*                  PATRONES	TRABAJADORES	GOBIERNO FEDERAL
matrix CSS_IMSS = (5.42,	0.44,		3.21	\   /// Enfermedad y maternidad, asegurados (Tgmasg*)
		   1.05,	0.37,		0.08	\   /// Enfermedad y maternidad, pensionados (Tgmpen*)
		   1.75,	0.63,		0.13	\   /// Invalidez y vida (Tinvyvida*)
		   1.83,	0.00,		0.00	\   /// Riesgos de trabajo (Triesgo*)
		   1.00,	0.00,		0.00	\   /// Guarderias y prestaciones sociales (Tguard*)
		   5.15,	1.12,		1.49	\   /// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
		   0.00,	0.00,		6.55)	//  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

* Informe Financiero Actuarial ISSSTE 2021 *
*                    PATRONES	TRABAJADORES	GOBIERNO FEDERAL
matrix CSS_ISSSTE = (7.375	2.750		391.0	\   /// Seguro de salud, trabajadores en activo y familiares (Tfondomed* / TCuotaSocISSTEF)
		     0.720	0.625		0.000	\   /// Seguro de salud, pensionados y familiares (Tpensjub*)
		     0.750	0.000		0.000	\   /// Riesgo de trabajo
		     0.625	0.625		0.000	\   /// Invalidez y vida
		     0.500	0.500		0.000	\   /// Servicios sociales y culturales
		     6.125	2+3.175		5.500	\   /// Retiro, cesantia en edad avanzada y vejez
		     0.000	5.000		0.000)	    //  Vivienda
***       FIN: SIMULADOR ISR       ***
**************************************



*********************************************************
***       6.2. Impuesto al Valor Agregado (IVA)       ***
*********************************************************
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
***       FIN: SIMULADOR IVA       ***
*************************************/





/** 3.1 CGPE 2023 ** 

* Costo financiero *
replace costodeudaInterno = 3.4/100*porInterno*pibY if anio == 2023
replace costodeudaExterno = 3.4/100*porExterno*pibY if anio == 2023
replace costodeudaInterno = 3.2/100*porInterno*pibY if anio == 2024
replace costodeudaExterno = 3.2/100*porExterno*pibY if anio == 2024
replace costodeudaInterno = 3.2/100*porInterno*pibY if anio == 2025
replace costodeudaExterno = 3.2/100*porExterno*pibY if anio == 2025
replace costodeudaInterno = 2.9/100*porInterno*pibY if anio == 2026
replace costodeudaExterno = 2.9/100*porExterno*pibY if anio == 2026
replace costodeudaInterno = 2.8/100*porInterno*pibY if anio == 2027
replace costodeudaExterno = 2.8/100*porExterno*pibY if anio == 2027
replace costodeudaInterno = 2.7/100*porInterno*pibY if anio == 2028
replace costodeudaExterno = 2.7/100*porExterno*pibY if anio == 2028

replace balprimario = 1.0 if anio == 2024
replace balprimario = 1.0 if anio == 2025
replace balprimario = 0.7 if anio == 2026
replace balprimario = 0.6 if anio == 2027
replace balprimario = 0.5 if anio == 2028
*/



****************************
***    2.4.5. DISPLAY    ***
****************************
noisily di _newline(10) in g _dup(23) "*" ///
	_newline in y " Simulador Fiscal CIEP" ///
	_newline in g _dup(23) "*" ///
	_newline in g "  A{c N~}O:  " in y "`=aniovp'" ///
	_newline in g "  USER: " in y "$id" ///
	_newline in g "  D{c I'}A:  " in y "`c(current_date)'" ///
	_newline in g "  HORA: " in y "`c(current_time)'" ///
	_newline in g _dup(23) "*"
