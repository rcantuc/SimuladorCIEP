********************************
***                          ***
***    1. CRECIMIENTO PIB    ***
***                          ***
********************************

* 2021-2027 *
global pib2021 = 6.3                                           // CGPE 2022: 6.3
global pib2022 = 4.1                                           // CGPE 2022: 4.1
global pib2023 = 3.4                                           // Supuesto: 2.5
global pib2024 = 2.8                                           // Supuesto: 2.5
global pib2025 = 2.5                                           // Supuesto: 2.5
global pib2026 = 2.5                                           // Supuesto: 2.5
global pib2027 = 2.5                                           // Supuesto: 2.5

* 2026-2030 *
forvalues k=2028(1)2030 {
	global pib`k' = $pib2027                               // SUPUESTO DE LARGO PLAZO
}

/* 2031-2050 *
forvalues k=2031(1)2050 {
	global pib`k' = $pib2027                               // SUPUESTO DE LARGO PLAZO
}

* OTROS */
global inf2021 = 5.7                                           // CGPE 2022: 5.7
global inf2022 = 3.4                                           // CGPE 2022: 3.4
global inf2023 = 3.0                                           // CGPE 2022: 3.0
global inf2024 = 3.0                                           // CGPE 2022: 3.0
global inf2025 = 3.0                                           // CGPE 2022: 3.0
global inf2026 = 3.0                                           // CGPE 2022: 3.0
global inf2027 = 3.0                                           // CGPE 2022: 3.0

global def2021 = 6.2295                                        // CGPE 2022: 6.2
global def2022 = 3.7080                                        // CGPE 2022: 3.7
global def2023 = 3.5000                                        // CGPE 2022: 3.5
global def2024 = 3.5000                                        // CGPE 2022: 3.5
global def2025 = 3.5000                                        // CGPE 2022: 3.5
global def2026 = 3.5000                                        // CGPE 2022: 3.5
global def2027 = 3.5000                                        // CGPE 2022: 3.5

global tasaEfectiva = 5.7425                                  // Tasa de inter{c e'}s EFECTIVA
global tipoDeCambio = 20.200                                  // Tipo de cambio
global depreciacion = 0.2000                                  // Depreciaci{c o'}n

scalar aniovp = 2022
scalar foliohogar = "folioviv foliohog"                        // Folio del hogar
scalar anioend = 2030


*log using /Users/ricardo/Desktop/`=aniovp'.smcl, replace



*********************************/
***                            ***
***    2. PARTE III: GASTOS    ***
***                            ***
**********************************
scalar basica      =   24402 //    Educaci{c o'}n b{c a'}sica
scalar medsup      =   24039 //    Educaci{c o'}n media superior
scalar superi      =   36559 //    Educaci{c o'}n superior
scalar posgra      =   57996 //    Posgrado
scalar eduadu      =  119929 //    Educaci{c o'}n para adultos
scalar otrose      =    1752 //    Otros gastos educativos

scalar ssa         =     928 //    SSalud
scalar prospe      =    2013 //    IMSS-Prospera
scalar segpop      =    3131 //    Seguro Popular
scalar imss        =    4681 //    IMSS (salud)
scalar issste      =    4697 //    ISSSTE (salud)
scalar pemex       =   41686 //    Pemex (salud) + ISSFAM (salud)

scalar bienestar   =   24810 //    Pensi{c o'}n Bienestar
scalar penims      =  134743 //    Pensi{c o'}n IMSS
scalar peniss      =  225979 //    Pensi{c o'}n ISSSTE
scalar penotr      = 1470558 //    Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

scalar servpers    =    3638 //    Servicios personales
scalar matesumi    =    1849 //    Materiales y suministros
scalar gastgene    =    2044 //    Gastos generales
scalar substran    =    1865 //    Subsidios y transferencias
scalar bienmueb    =     288 //    Bienes muebles e inmuebles
scalar obrapubl    =    4065 //    Obras p{c u'}blicas
scalar invefina    =    1208 //    Inversi{c o'}n financiera
scalar partapor    =   10018 //    Participaciones y aportaciones
scalar costodeu    =    6412 //    Costo de la deuda

scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no





**********************************/
***                             ***
***    3. PARTE II: INGRESOS    ***
***                             ***
***********************************
scalar ISRAS   = 3.364 //    ISR (asalariados): 3.453
scalar ISRPF   = 0.218 //    ISR (personas f{c i'}sicas): 0.441
scalar CuotasT = 1.446 //    Cuotas (IMSS): 1.515

scalar IVA     = 4.263 //    IVA: 3.885
scalar ISAN    = 0.043 //    ISAN: 0.030
scalar IEPS    = 1.774 //    IEPS (no petrolero + petrolero): 2.027
scalar Importa = 0.256 //    Importaciones: 0.245

scalar ISRPM   = 3.699 //    ISR (personas morales): 3.710
scalar FMP     = 1.303 //    Fondo Mexicano del Petr{c o'}leo: 1.362
scalar OYE     = 4.233 //    Organismos y empresas (IMSS + ISSSTE + Pemex + CFE): 4.274
scalar OtrosC  = 1.078 //    Productos, derechos, aprovechamientos, contribuciones: 1.070





*****************************************************/
***                                                ***
***       3.1. Impuesto Sobre la Renta (ISR)       ***
***                                                ***
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
matrix DED = (5,		15,			45.10, 			22.69)

*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,		17.72)

* Modulo ISR *
if "`cambioisr'" == "1" {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}

* Modulo IVA *
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}

***       FIN: SIMULADOR ISR       ***
**************************************





*********************************************************
***                                                   ***
***       3.2. Impuesto al Valor Agregado (IVA)       ***
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
*************************************
