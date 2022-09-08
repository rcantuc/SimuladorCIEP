*************************
***                   ***
***    1. USERNAME    ***
***                   ***
*************************
global id = "`c(username)'"                                                     // ID DEL USUARIO



*********************
***               ***
***    2. PAÍS    ***
***               ***
*********************
if "$pais" == "" {
	local pais = "M{c e'}xico"
}
else {
	local pais = "$pais"
}



****************************
***                      ***
***    3. DIRECTORIOS    ***
***                      ***
****************************
capture mkdir `"`c(sysdir_site)'/SIM/"'
capture mkdir `"`c(sysdir_site)'/users/"'
capture mkdir `"`c(sysdir_site)'/users/$pais/"'
capture mkdir `"`c(sysdir_site)'/users/$pais/$id/"'



********************************
***                          ***
***    4. CRECIMIENTO PIB    ***
***                          ***
********************************
global paqueteEconomico "PE 2023"
scalar aniovp = 2023
scalar anioend = 2030

global pib2022 = 2.4 //    CGPE 2023 (página 134)
global pib2023 = 3.0 //    CGPE 2023 (página 134)
global pib2024 = 2.4 //    CGPE 2023 (página 134)
global pib2025 = 2.4 //    CGPE 2023 (página 134)
global pib2026 = 2.4 //    CGPE 2023 (página 134)
global pib2027 = 2.4 //    CGPE 2023 (página 134)
global pib2028 = 2.4 //    CGPE 2023 (página 134)

global def2022 = 8.00695 //    CGPE 2023 (página 134)
global def2023 = 4.91697 //    CGPE 2023 (página 134)
global def2024 = 3.5 //    CGPE 2023 (página 134)
global def2025 = 3.5 //    CGPE 2023 (página 134)
global def2026 = 3.5 //    CGPE 2023 (página 134)
global def2027 = 3.5 //    CGPE 2023 (página 134)
global def2028 = 3.5 //    CGPE 2023 (página 134)
global def2029 = 3.5 //    CGPE 2023 (página 134)
global def2030 = 3.5 //    CGPE 2023 (página 134)

global inf2022 = 7.7 //    CGPE 2023 (página 134)
global inf2023 = 3.2 //    CGPE 2023 (página 134)
global inf2024 = 3.0 //    CGPE 2023 (página 134)
global inf2025 = 3.0 //    CGPE 2023 (página 134)
global inf2026 = 3.0 //    CGPE 2023 (página 134)
global inf2027 = 3.0 //    CGPE 2023 (página 134)


exit
************************/
***                   ***
***    5. INGRESOS    ***
***                   ***
*************************
scalar ISRAS   = 3.073 //    ISR (asalariados): 
scalar ISRPF   = 0.200 //    ISR (personas f{c i'}sicas): 
scalar CUOTAS  = 1.321 //    Cuotas (IMSS): 

scalar ISRPM   = 3.379 //    ISR (personas morales): 
scalar OTROSK  = 0.985 //    Productos, derechos, aprovechamientos, contribuciones: 

scalar IVA     = 3.893 //    IVA: 
scalar ISAN    = 0.039 //    ISAN: 
scalar IEPSP   = 0.600 //    IEPS (petrolero): 
scalar IEPSNP  = 1.020 //    IEPS (no petrolero): 
scalar IMPORT  = 0.234 //    Importaciones: 

scalar IMSS    = 0.101 //    Organismos y empresas (IMSS)
scalar ISSSTE  = 0.164 //    Organismos y empresas (ISSSTE)
scalar FMP     = 1.190 //    Fondo Mexicano del Petr{c o'}leo
scalar PEMEX   = 2.297 //    Organismos y empresas (Pemex)
scalar CFE     = 1.304 //    Organismos y empresas (CFE)



**********************/
***                 ***
***    6. GASTOS    ***
***                 ***
***********************
scalar basica      =   23925 //    Educaci{c o'}n b{c a'}sica
scalar medsup      =   23465 //    Educaci{c o'}n media superior
scalar superi      =   35716 //    Educaci{c o'}n superior
scalar posgra      =   56609 //    Posgrado
scalar eduadu      =   33747 //    Educaci{c o'}n para adultos
scalar otrose      =    3065 //    Otros gastos educativos

scalar ssa         =     680 //    SSalud
scalar imssbien    =    3574 //    IMSS-Bienestar
scalar imss        =    6882 //    IMSS (salud)
scalar issste      =    8994 //    ISSSTE (salud)
scalar pemex       =   23433 //    Pemex (salud) + ISSFAM (salud)*/

scalar bienestar   =   20984 //    Pensi{c o'}n Bienestar
scalar penims      =  143573 //    Pensi{c o'}n IMSS
scalar peniss      =  224115 //    Pensi{c o'}n ISSSTE
scalar penotr      = 1421385 //    Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

scalar gaspemex    =    4115 //    Servicios personales
scalar gascfe      =    2998 //    Materiales y suministros
scalar gassener    =    1054 //    Gastos generales
scalar gasfeder    =    9781 //    Subsidios y transferencias
scalar gascosto    =    6260 //    Bienes muebles e inmuebles
scalar gasinfra    =     884 //    Obras p{c u'}blicas
scalar gasotros    =    5196 //    Inversi{c o'}n financiera

scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no

*global tasaEfectiva = 5.7425                                   // Tasa de inter{c e'}s EFECTIVA
*global tipoDeCambio = 20.200                                   // Tipo de cambio
*global depreciacion = 0.2000                                   // Depreciaci{c o'}n


*****************************************************/
***                                                ***
***       6.1. Impuesto Sobre la Renta (ISR)       ***
***                                                ***
******************************************************
/*             Inferior		Superior	CF		Tasa
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
matrix DED = (5,		15,			45.10, 			22.69)

*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,		17.72)

* Modulo ISR *
if "`cambioisr'" == "1" {
	noisily run "`c(sysdir_site)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}

* Modulo IVA *
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}

***       FIN: SIMULADOR ISR       ***
**************************************





*********************************************************
***                                                   ***
***       6.2. Impuesto al Valor Agregado (IVA)       ***
***                                                   ***
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
               21.59)   //  13  Evasion e informalidad IVA, input[0-100]
***       FIN: SIMULADOR IVA       ***
*************************************/



************************
***                  ***
***    7. DISPLAY    ***
***                  ***
************************
noisily di _newline(10) in g _dup(23) "*" ///
	_newline in y " Simulador Fiscal CIEP" ///
	_newline in g _dup(23) "*" ///
	_newline in g "  A{c N~}O:  " in y "`=aniovp'" ///
	_newline in g "  USER: " in y "$id" ///
	_newline in g "  PA{c I'}S: " in y "`pais'" ///
	_newline in g _dup(23) "*"
