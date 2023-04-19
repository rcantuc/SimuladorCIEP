***********************
***    1. SET UP    ***
***********************
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)

global id = "`c(username)'"

capture mkdir `"`c(sysdir_personal)'/SIM/"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$id/"'

global paqueteEconomico "Pre-CGPE 2024"
tokenize $paqueteEconomico
scalar anioPE = `2'
if `2' >= 2020 {
	scalar enighanio = 2020
}
if `2' >= 2018 & `2' < 2020 {
	scalar enighanio = 2018
}
if `2' >= 2016 & `2' < 2018 {
	scalar enighanio = 2016
}

global entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nacional"

if "$output" != "" {
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



************************************************
***    3. CRECIMIENTO Y DEFLACTOR DEL PIB    ***
************************************************
global pib2023 = 2.6 //     Pre-CGPE 2024 (punto medio)
global pib2024 = 2.3 //     Pre-CGPE 2024 (punto medio)
global pib2025 = 2.4 //     CGPE 2023 (página 134)
global pib2026 = 2.4 //     CGPE 2023 (página 134)
global pib2027 = 2.4 //     CGPE 2023 (página 134)
global pib2028 = 2.4 //     CGPE 2023 (página 134)
global pib2029 = $pib2028
global pib2030 = $pib2029

global def2023 = 5.2 //     CGPE 2023 (página 134)
global def2024 = 4.792 //   CGPE 2023 (página 134)
global def2025 = 3.49807 // CGPE 2023 (página 134)
global def2026 = 3.49211 // CGPE 2023 (página 134)
global def2027 = 3.51530 // CGPE 2023 (página 134)
global def2028 = 3.50150 // CGPE 2023 (página 134)
global def2029 = $def2028
global def2030 = $def2029



******************************
***    4. DEUDA PÚBLICA    ***
/******************************
scalar shrfsp2023 = 49.9
scalar shrfspInterno2023 = 34.7
scalar shrfspExterno2023 = 14.6
scalar rfsp2023 = 4.1
scalar rfspBalance2023 = -3.6
scalar rfspPIDIREGAS2023 = -0.1
scalar rfspIPAB2023 = -0.1
scalar rfspFONADIN2023 = 0.0
scalar rfspDeudores2023 = 0.0
scalar rfspBanca2023 = 0.0
scalar rfspAdecuaciones2023 = -0.2
scalar balprimario2023 = -0.2
scalar tipoDeCambio2023 = 20.6
scalar costodeudaInterno2023 = 3.4
scalar costodeudaExterno2023 = 3.4

*global tasaEfectiva = 6.005578 // Tasa de inter{c e'}s EFECTIVA




**********************/
***    5. GASTOS    ***
***********************
if "$update" == "update" {
	noisily GastoPC, anio(`=anioPE')
}
else {
	scalar basica      =   26537 //    Educación b{c a'}sica
	scalar medsup      =   26439 //    Educación media superior
	scalar superi      =   39157 //    Educación superior
	scalar posgra      =   64239 //    Posgrado
	scalar eduadu      =   37573 //    Educación para adultos
	scalar otrose      =    3802 //    Otros gastos educativos

	scalar ssa         =     600 //    SSalud
	scalar imssbien    =    4163 //    IMSS-Bienestar
	scalar imss        =    8141 //    IMSS (salud)
	scalar issste      =   10992 //    ISSSTE (salud)
	scalar pemex       =   30858 //    Pemex (salud)
	scalar issfam      =   22721 //    ISSFAM (salud)

	scalar pam         =   29239 //    Pensión Bienestar
	scalar penimss     =  169241 //    Pensión IMSS
	scalar penisss     =  249560 //    Pensión ISSSTE
	scalar penpeme     =  671899 //    Pensión Pemex
	scalar penotro     = 2797302 //    Pensión CFE, LFC, ISSFAM, Ferronales

	scalar gascfe      =    2958 //    Gasto en CFE
	scalar gaspemex    =    4466 //*.30470771 //    Gasto en Pemex
	scalar gassener    =    1128 //    Gasto en SENER
	scalar gasinfra    =    4315 //    Gasto en Inversión
	scalar gascosto    =    8543 //    Gasto en Costo de la deuda
	scalar gasfeder    =    9925 //    Participaciones y Otras aportaciones
	scalar gasotros    =    6377 //    Otros gastos

	scalar IngBas      =       0 //    Ingreso b{c a'}sico
	scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
	scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no
}



************************/
***    6. INGRESOS    ***
*************************
if "$update" == "update" {
	noisily TasasEfectivas, anio(`=aniovp')
}
else {
	scalar ISRAS   = 3.773 //100*scalar(pibY) *(1+ 3.782*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (asalariados): 3.696
	scalar ISRPF   = 0.245 //100*scalar(pibY) *(1+ 1.199*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas f{c i'}sicas): 0.240
	scalar CUOTAS  = 1.531 //100*scalar(pibY) *(1+ 2.197*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Cuotas (IMSS): 1.499

	scalar ISRPM   = 4.149 //100*scalar(pibY) *(1+ 4.664*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas morales): 4.064
	scalar OTROSK  = 1.070 //100*scalar(pibY) *(1+-3.269*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Productos, derechos, aprovech.: 1.049

	scalar IVA     = 4.615 //100*scalar(pibY) *(1+ 2.498*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IVA: 4.520
	scalar ISAN    = 0.050 //100*scalar(pibY) *(1+ 3.565*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISAN: 0.049
	scalar IEPSNP  = 0.676 //100*scalar(pibY) *(1+ 0.362*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IEPS (no petrolero): 0.887
	scalar IEPSP   = 0.905 // IEPS (petrolero): 0.662
	scalar IMPORT  = 0.320 //100*scalar(pibY) *(1+ 5.303*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Importaciones: 0.313

	scalar FMP     = 1.586 //100*scalar(pibY) *(1+-7.718*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Fondo Mexicano del Petróleo: 1.553

	scalar IMSS    = 0.093 //100*scalar(pibY) *(1+-2.685*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (IMSS): 0.091
	scalar ISSSTE  = 0.162 //100*scalar(pibY) *(1+-3.058*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (ISSSTE): 0.159
	scalar PEMEX   = 2.687 //100*scalar(pibY) *(1+ 1.379*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (Pemex): 2.632
	scalar CFE     = 1.297 //100*scalar(pibY) *(1+-3.024*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (CFE): 1.271
 }
scalar depletionrate = 0.08*0


******************************************************
***       6.1. Impuesto Sobre la Renta (ISR)       ***
******************************************************
*             Inferior		Superior	CF		Tasa
matrix ISR =  (0.01,		7735.00,	0.0,		1.92	\    /// 1
              7735.01,		65651.07,	148.51,		6.40	\    /// 2
              65651.08,		115375.90,	3855.14,	10.88	\    /// 3
              115375.91,	134119.41,	9265.20,	16.00	\    /// 4
              134119.42,	160577.65,	12264.16,	17.92	\    /// 5
              160577.66,	323862.00,	17005.47,	21.36	\    /// 6
              323862.01,	510451.00,	51883.01,	23.52	\    /// 7
              510451.01,	974535.03,	95768.74,	30.00	\    /// 8
              974535.04,	1299380.04,	234993.95,	32.00	\    /// 9
              1299380.05,	3898140.12,	338944.34,	34.00	\    /// 10
              3898140.13,	1E+14,		1222522.76,	35.00)	     //  11

*             Inferior		Superior	Subsidio
matrix	SE =  (0.01,		21227.52,	4884.24		\    /// 1
              21227.53,		23744.40,	4881.96		\    /// 2
              23744.41,		31840.56,	4879.44		\    /// 3
              31840.57,		41674.08,	4879.44		\    /// 4
              41674.09,		42454.44,	4713.24		\    /// 5
              42454.45,		53353.80,	4589.52		\    /// 6
              53353.81,		56606.16,	4250.76		\    /// 7
              56606.17,		64025.04,	3898.44		\    /// 8
              64025.05,		74696.04,	3535.56		\    /// 9
              74696.05,		85366.80,	3042.48		\    /// 10
              85366.81,		88587.96,	2611.32		\    /// 11
              88587.97, 	1E+14,		0)		     	//  12

*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,				15,					46.78, 				9.43)

*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,		21.45)
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

replace shrfsp = 49.4/100*pibY if anio == 2024
replace shrfspInterno = 35.2/100*pibY if anio == 2024
replace shrfspExterno = 14.2/100*pibY if anio == 2024
replace rfsp = 2.7/100*pibY if anio == 2024
replace rfspBalance = -2.2/100*pibY if anio == 2024
replace rfspPIDIREGAS = -0.1/100*pibY if anio == 2024
replace rfspIPAB = -0.1/100*pibY if anio == 2024
replace rfspFONADIN = 0.0/100*pibY if anio == 2024
replace rfspDeudores = 0.0/100*pibY if anio == 2024
replace rfspBanca = 0.0/100*pibY if anio == 2024
replace rfspAdecuacion = -0.3/100*pibY if anio == 2024
replace tipoDeCambio = 20.7 if anio == 2024

replace shrfsp = 49.4/100*pibY if anio == 2025
replace shrfspInterno = 35.5/100*pibY if anio == 2025
replace shrfspExterno = 13.8/100*pibY if anio == 2025
replace rfsp = 2.7/100*pibY if anio == 2025
replace rfspBalance = -2.2/100*pibY if anio == 2025
replace rfspPIDIREGAS = -0.1/100*pibY if anio == 2025
replace rfspIPAB = -0.1/100*pibY if anio == 2025
replace rfspFONADIN = 0.0/100*pibY if anio == 2025
replace rfspDeudores = 0.0/100*pibY if anio == 2025
replace rfspBanca = 0.0/100*pibY if anio == 2025
replace rfspAdecuacion = -0.3/100*pibY if anio == 2025
replace tipoDeCambio = 20.8 if anio == 2025

replace shrfsp = 49.4/100*pibY if anio == 2026
replace shrfspInterno = 35.9/100*pibY if anio == 2026
replace shrfspExterno = 13.5/100*pibY if anio == 2026
replace rfsp = 2.7/100*pibY if anio == 2026
replace rfspBalance = -2.2/100*pibY if anio == 2026
replace rfspPIDIREGAS = -0.1/100*pibY if anio == 2026
replace rfspIPAB = -0.1/100*pibY if anio == 2026
replace rfspFONADIN = 0.0/100*pibY if anio == 2026
replace rfspDeudores = 0.0/100*pibY if anio == 2026
replace rfspBanca = 0.0/100*pibY if anio == 2026
replace rfspAdecuacion = -0.3/100*pibY if anio == 2026
replace tipoDeCambio = 21.0 if anio == 2026

replace shrfsp = 49.4/100*pibY if anio == 2027
replace shrfspInterno = 36.3/100*pibY if anio == 2027
replace shrfspExterno = 13.1/100*pibY if anio == 2027
replace rfsp = 2.7/100*pibY if anio == 2027
replace rfspBalance = -2.2/100*pibY if anio == 2027
replace rfspPIDIREGAS = -0.1/100*pibY if anio == 2027
replace rfspIPAB = -0.1/100*pibY if anio == 2027
replace rfspFONADIN = 0.0/100*pibY if anio == 2027
replace rfspDeudores = 0.1/100*pibY if anio == 2027
replace rfspBanca = 0.0/100*pibY if anio == 2027
replace rfspAdecuacion = -0.4/100*pibY if anio == 2027
replace tipoDeCambio = 21.3 if anio == 2027

replace shrfsp = 49.4/100*pibY if anio == 2028
replace shrfspInterno = 36.6/100*pibY if anio == 2028
replace shrfspExterno = 12.7/100*pibY if anio == 2028
replace rfsp = 2.7/100*pibY if anio == 2028
replace rfspBalance = -2.2/100*pibY if anio == 2028
replace rfspPIDIREGAS = -0.1/100*pibY if anio == 2028
replace rfspIPAB = -0.1/100*pibY if anio == 2028
replace rfspFONADIN = 0.0/100*pibY if anio == 2028
replace rfspDeudores = 0.0/100*pibY if anio == 2028
replace rfspBanca = 0.0/100*pibY if anio == 2028
replace rfspAdecuacion = -0.3/100*pibY if anio == 2028
replace tipoDeCambio = 21.5 if anio == 2028

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
