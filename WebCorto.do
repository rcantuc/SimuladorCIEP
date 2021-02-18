**************************************/
** PARAMETROS SIMULADOR: DIRECTORIOS **
if "`c(username)'" == "ricardo" {
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}
if "`c(username)'" == "ciepmx" {
	sysdir set PERSONAL "/SIM/OUT/5/5.0/"
}
** PARAMETROS SIMULADOR: DIRECTORIOS **
***************************************


************************************
** PARAMETROS SIMULADOR: OPCIONES **
global nographs "nographs"
global output "output"
** PARAMETROS SIMULADOR: OPCIONES **
************************************


****************************************/
** PARAMETROS SIMULADOR: IDENTIFICADOR **
global id = ""
** PARAMETROS SIMULADOR: IDENTIFICADOR **
*****************************************




************************/
***                   ***
***    0. ARRANQUE    ***
***                   ***
*************************
timer on 1
noisily di _newline(50) _col(35) in w "Simulador Fiscal CIEP v5.0" ///
	_newline _col(43) in y "$pais"


** DIRECTORIOS **
adopath ++ PERSONAL
cd "`c(sysdir_personal)'"
capture mkdir "`c(sysdir_personal)'/SIM/"
capture mkdir "`c(sysdir_personal)'/users/"
capture mkdir "`c(sysdir_personal)'/users/$id/"
capture mkdir "`c(sysdir_personal)'/users/$pais/"


** AÑO VALOR BASE **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local aniovp = substr(`"`=trim("`fecha'")'"',1,4)


** OUTPUT LOG FILE **
if "$output" == "output" {
	quietly log using "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt", replace text name(output)
	quietly log off output
}



************************************************************
***                                                      ***
***    1. SET-UP: Cap. 3. La economia antropocentrica    ***
***                                                      ***
************************************************************
capture confirm file `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC.dta"'
if _rc != 0 {

	** POBLACION **
	Poblacion, $nographs anio(`aniovp') update //tf(`=64.333315/2.2*2.07') //tm2044(18.9) tm4564(63.9) tm65(35.0) //aniofinal(2040) 

	** HOUSEHOLDS: INCOMES **
	local id = "$id"
	global id = ""
	noisily run `"`c(sysdir_personal)'/Households`=subinstr("${pais}"," ","",.)'.do"' 2018
	global id = "`id'"
}




*********************************************/
***                                        ***
***    2. Simulador v5: PIB + Deflactor    ***
***    Cap. 2. El sistema de la ciencia    ***
***                                        ***
**********************************************


*******************************
** PARAMETROS SIMULADOR: PIB **
global pib2020 = -8.0
global pib2021 =  4.6
global pib2022 =  2.6
global pib2023 =  2.5
global pib2024 =  2.5
global pib2025 =  2.5
** PARAMETROS SIMULADOR: PIB **
*******************************


** OTROS PARAMETROS **
global def2020 =  3.568
global def2021 =  3.425

global inf2020 =  3.5
global inf2021 =  3.0


** PIB + Deflactor **
noisily PIBDeflactor, anio(`aniovp') $nographs //geo(`geo') //discount(3.0)
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
}


** SCN + Inflacion **
if "$pais" == "" & "$export" != "" {
	noisily Inflacion, anio(`aniovp') $nographs //update
	noisily SCN, anio(`aniovp') $nographs //update
}




*********************************/
***                            ***
***    3. PARTE III: GASTOS    ***
***                            ***
**********************************


**********************************
** PARAMETROS SIMULADOR: GASTOS **
* Educacion *
scalar basica = 21325 //		Educaci{c o'}n b{c a'}sica
scalar medsup = 21056 //		Educaci{c o'}n media superior
scalar superi = 38111 //		Educaci{c o'}n superior
scalar posgra = 45788 //		Posgrado
scalar eduadu = 19451 //		Educaci{c o'}n para adultos
scalar otrose =  1476 //		Otros gastos educativos

* Salud *
scalar ssa    =   519 //		SSalud
scalar prospe =  1081 //		IMSS-Prospera
scalar segpop =  2406 //		Seguro Popular
scalar imss   =  6385 //		IMSS (salud)
scalar issste =  8589 //		ISSSTE (salud)
scalar pemex  = 24178 //		Pemex (salud) + ISSFAM (salud)

* Pensiones *
scalar bienestar =   18273 //	Pensi{c o'}n Bienestar
scalar penims    =  134649 //	Pensi{c o'}n IMSS
scalar peniss    =  226463 //	Pensi{c o'}n ISSSTE
scalar penotr    = 1402288 //	Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

* Ingreso b{c a'}sico *
scalar IngBas      = 0 //		Ingreso b{c a'}sico
scalar ingbasico18 = 1 //		1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 = 1 //		1: Incluye mayores de 65 anios, 0: no

* Otros gastos *
scalar servpers = 3380 //		Servicios personales
scalar matesumi = 1692 //		Materiales y suministros
scalar gastgene = 1786 //		Gastos generales
scalar substran = 1897 //		Subsidios y transferencias
scalar bienmueb =  300 //		Bienes muebles e inmuebles
scalar obrapubl = 3337 //		Obras p{c u'}blicas
scalar invefina =  784 //		Inversi{c o'}n financiera
scalar partapor = 8988 //		Participaciones y aportaciones
scalar costodeu = 5862 //		Costo de la deuda
** PARAMETROS SIMULADOR: GASTOS **
*********************************/


** Gastos per capita **
noisily GastoPC, anio(`aniovp') `nographs'




**********************************/
***                             ***
***    4. PARTE II: INGRESOS    ***
***                             ***
***********************************


************************************
** PARAMETROS SIMULADOR: INGRESOS **
** Al ingreso **
scalar ISRAS   = 22.018*15.6/100 	//		ISR (asalariados): 3.428
scalar ISRPF   = 13.211*3.3/100 	//		ISR (personas f{c i'}sicas): 0.438
scalar CuotasT = 26.454*5.7/100		//		Cuotas (IMSS): 1.515

* Al consumo *
scalar IVA     = 47.277*8.2/100 	//		IVA: 3.885
scalar ISAN    =  2.913*1.0/100 	//		ISAN: 0.030
scalar IEPS    = 66.041*3.1/100 	//		IEPS (no petrolero + petrolero): 2.027
scalar Importa = 31.060*0.8/100 	//		Importaciones: 0.245

* Al capital *
scalar ISRPM   = 25.438*14.6/100 	//		ISR (personas morales): 3.710
scalar FMP     = 38.125*3.6/100 	//		Fondo Mexicano del Petr{c o'}leo: 1.362
scalar OYE     = 38.125*11.2/100 	//		Organismos y empresas (IMSS + ISSSTE + Pemex + CFE): 4.274
scalar OtrosC  = 38.125*2.8/100		//		Productos, derechos, aprovechamientos, contribuciones: 1.070
** PARAMETROS SIMULADOR: INGRESOS **
***********************************/


*******************************
** PARAMETROS SIMULADOR: ISR **
*			Inferior	Superior	CF		Tasa
matrix	ISR	= (0.00,	5952.84,	0.0,		1.92	\	/// 1
			5952.85,	50524.92,	114.24,		6.40	\	/// 2
			50524.93,	88793.04,	2966.76,	10.88	\	/// 3
			88793.05,	103218.00,	7130.88,	16.00	\	/// 4
			103218.01,	123580.20,	9438.60,	17.92	\	/// 5
			123580.21,	249243.48,	13087.44,	21.36	\	/// 6
			249243.49,	392841.96,	39929.04,	23.52	\	/// 7
			392841.97,	750000.00, 	73703.40,	30.00	\	/// 8
			750000.01,	1000000.00,	180850.82,	32.00	\	/// 9
			1000000.01,	3000000.00,	260850.81,	34.00	\	/// 10
			3000000.01,	1E+14, 		940850.81,	35.00)		//  11

*			Inferior	Superior	Subsidio
matrix	SE	= (0.00,	21227.52,	4884.24		\		/// 1
			21227.53,	23744.40,	4881.96		\		/// 2
			23744.41,	31840.56,	4318.08		\		/// 3
			31840.57,	41674.08,	4123.20		\		/// 4
			41674.09,	42454.44,	3723.48		\		/// 5
			42454.45,	53353.80,	3581.28		\		/// 6
			53353.81,	56606.16,	4250.76		\		/// 7
			56606.17,	64025.04,	3898.44		\		/// 8
			64025.05,	74696.04,	3535.56		\		/// 9
			74696.05,	85366.80,	3042.48		\		/// 10
			85366.81,	88587.96,	2611.32		\		/// 11
			88587.97, 	1E+14,		0)				//  12

*			SS.MM.	% ingreso gravable
matrix	DED	= (	5,	15)

*			Tasa ISR PM	Evasion PM	Evasion PF
matrix PM	= (	30,		20.10,		96.07)
** PARAMETROS SIMULADOR: ISR **
*******************************


** MODULO ISR **
*noisily run "`c(sysdir_personal)'/ISR_Mod.do"
capture confirm scalar ISR_AS_Mod
if _rc == 0 {
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}


*******************************
** PARAMETROS SIMULADOR: ISR **
matrix IVA = (	16	\	///  1  Tasa general 
		1	\	///  2  Alimentos, 1: Tasa Cero, 2: Exento, 3: Gravado
		2	\	///  3  Alquiler, idem
		1	\	///  4  Canasta basica, idem
		1	\	///  5  Educacion, idem
		3	\	///  6  Consumo fuera del hogar, idem
		3	\	///  7  Mascotas, idem
		1	\	///  8  Medicinas, idem
		3	\	///  9  Otros, idem
		2	\	/// 10  Transporte local, idem
		2	\	/// 11  Transporte foraneo, idem
		52.37	)	//  12  Evasion e informalidad IVA, idem
** PARAMETROS SIMULADOR: IVA **
*******************************


*noisily run "`c(sysdir_personal)'/IVA_Mod.do"
capture confirm scalar IVA_Mod
if _rc == 0 {
	scalar IVA = IVA_Mod
}


** TASAS EFECTIVAS **
noisily TasasEfectivas, anio(`aniovp') `nographs'




** OUTPUT **
if "$output" == "output" {
	quietly log close output
	tempfile output1 output2 output3
	if "`=c(os)'" == "Windows" {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt", from(".,") to("0") replace
}




***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
