*****************************************************
****    SECTION FOR PROGRAMMING PURPOSES ONLY    ****
****         MUST BE COMMENTED OTHERWISE         ****
/*****************************************************
clear all
macro drop _all
capture log close _all
if "`c(os)'" == "MacOSX" {
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
}
if "`c(os)'" == "Unix" {
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
}


**************************************/
** PARAMETROS SIMULADOR: DIRECTORIOS **
*sysdir set PERSONAL "/SIM/OUT/5/5.0/"
** PARAMETROS SIMULADOR: DIRECTORIOS **
***************************************


************************************
** PARAMETROS SIMULADOR: OPCIONES **
*global pais = "El Salvador"			// Comentar o "" (vacío) para Mexico
global nographs "nographs"
global output "output"
** PARAMETROS SIMULADOR: OPCIONES **
************************************


****************************************/
** PARAMETROS SIMULADOR: IDENTIFICADOR **
if "$pais" == "" {
	global id = "PE2021"
}
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
	quietly log using "`c(sysdir_personal)'/users/$pais/$id/output.txt", replace text name(output)
	quietly log off output
}



************************************************************
***                                                      ***
***    1. SET-UP: Cap. 3. La economia antropocentrica    ***
***                                                      ***
/************************************************************
Poblacion, $nographs update //tf(`=64.333315/2.2*2.07') //tm2044(18.9) tm4564(63.9) tm65(35.0) //aniofinal(2040) //anio(`aniovp')

capture confirm file `"`c(sysdir_personal)'/SIM/$pais/2018//householdss.dta"'
if _rc != 0 {


	** HOUSEHOLDS: INCOMES **
	noisily run `"`c(sysdir_personal)'/Households`=subinstr("${pais}"," ","",.)'.do"' 2018
	if "$pais" == "" & "$export" != "" {


		** HOUSEHOLDS: EXPENDITURES **
		*noisily run "`c(sysdir_personal)'/Expenditure.do" 2018


		** Sankey **
		if "`c(os)'" != "Unix" {
			foreach k in grupoedad decil escol sexo {
				noisily run "`c(sysdir_personal)'/SankeyCC.do" `k' 2018
				noisily run "`c(sysdir_personal)'/Sankey.do" `k' 2018
			}
		}


		** Datos Abiertos **
		DatosAbiertos XNA0120_s, g //		ISR salarios
		DatosAbiertos XNA0120_f, g //		ISR PF
		DatosAbiertos XNA0120_m, g //		ISR PM
		DatosAbiertos XKF0114, g //		Cuotas IMSS
		DatosAbiertos XAB1120, g //		IVA
		DatosAbiertos XNA0141, g //		ISAN
		DatosAbiertos XAB1130, g //		IEPS
		DatosAbiertos XNA0136, g //		Importaciones
		DatosAbiertos FMP_Derechos, g //	FMP_Derechos
		DatosAbiertos XAB2110, g //		Ingresos propios Pemex
		DatosAbiertos XOA0115, g //		Ingresos propios CFE
		DatosAbiertos XKF0179, g //		Ingresos propios IMSS
		DatosAbiertos XOA0120, g //		Ingresos propios ISSSTE
	}
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

if "$pais" == "El Salvador" {
	global pib2020 = -7.200
	global pib2021 =  4.600
	global def2020 =  0.383
	global def2021 =  0.512
}


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
scalar basica = 21422 //		Educaci{c o'}n b{c a'}sica
scalar medsup = 21152 //		Educaci{c o'}n media superior
scalar superi = 38283 //		Educaci{c o'}n superior
scalar posgra = 45996 //		Posgrado
scalar eduadu = 19538 //		Educaci{c o'}n para adultos
scalar otrose =  1483 //		Otros gastos educativos

* Salud *
scalar ssa    =   522 //		SSalud
scalar prospe =  1081 //		IMSS-Prospera
scalar segpop =  2417 //		Seguro Popular
scalar imss   =  6414 //		IMSS (salud)
scalar issste =  8628 //		ISSSTE (salud)
scalar pemex  = 24288 //		Pemex (salud) + ISSFAM (salud)

* Pensiones *
scalar bienestar =   18356 //		Pensi{c o'}n Bienestar
scalar penims    =  135259 //		Pensi{c o'}n IMSS
scalar peniss    =  227486 //		Pensi{c o'}n ISSSTE
scalar penotr    = 1408633 //		Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

* Ingreso b{c a'}sico *
scalar IngBas      = 0 //		Ingreso b{c a'}sico
scalar ingbasico18 = 1 //		1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 = 1 //		1: Incluye mayores de 65 anios, 0: no

* Otros gastos *
scalar servpers = 3395 //		Servicios personales
scalar matesumi = 1700 //		Materiales y suministros
scalar gastgene = 1794 //		Gastos generales
scalar substran = 1906 //		Subsidios y transferencias
scalar bienmueb =  302 //		Bienes muebles e inmuebles
scalar obrapubl = 3352 //		Obras p{c u'}blicas
scalar invefina =  787 //		Inversi{c o'}n financiera
scalar partapor = 9029 //		Participaciones y aportaciones
scalar costodeu = 5888 //		Costo de la deuda
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
scalar ISRAS   = 3.428 //		ISR (asalariados)
scalar ISRPF   = 0.438 //		ISR (personas f{c i'}sicas)
scalar CuotasT = 1.515 //		Cuotas (IMSS)

* Al consumo *
scalar IVA     = 3.885 //		IVA
scalar ISAN    = 0.030 //		ISAN
scalar IEPS    = 2.027 //		IEPS (no petrolero + petrolero)
scalar Importa = 0.245 //		Importaciones

* Al capital *
scalar ISRPM   = 3.710 //		ISR (personas morales)
scalar FMP     = 1.362 //		Fondo Mexicano del Petr{c o'}leo
scalar OYE     = 4.274 //		Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
scalar OtrosC  = 1.070 //		Productos, derechos, aprovechamientos, contribuciones
** PARAMETROS SIMULADOR: INGRESOS **
***********************************/


*******************************
** PARAMETROS SIMULADOR: ISR **
*			Inferior	Superior	CF		Tasa
matrix	ISR	= (	0.00,		5952.84,	0.0,		1.92	\	/// 1
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
matrix	SE	= (	0.00,		21227.52,	4884.24		\		/// 1
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


** GRAFICA PROYECCION **
if "$nographs" != "nographs" & "$pais" == "" {
	use `"`c(sysdir_personal)'/SIM/2018//households.dta"', clear
	noisily Simulador ImpuestosAportaciones if ImpuestosAportaciones != 0 [fw=factor], ///
		base("ENIGH 2018") boot(1) reboot nographs anio(2020)

	use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/ImpuestosAportacionesREC.dta"', clear
	merge 1:1 (anio) using `"`c(sysdir_personal)'/users/$pais/$id/PIB.dta"', nogen
	replace estimacion = estimacion/pibYR*100

	tabstat estimacion, stat(max) save
	tempname MAX
	matrix `MAX' = r(StatTotal)
	forvalues k=1(1)`=_N' {
		if estimacion[`k'] == `MAX'[1,1] {
			local aniomax = anio[`k']
		}
		if anio[`k'] == `aniovp' {
			local estimacionvp = estimacion[`k']
		}
	}

	twoway (connected estimacion anio) (connected estimacion anio if anio == `aniovp') if anio > 1990, ///
		ytitle("% PIB") ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(0(5)15, format(%20.1fc) labsize(small)) ///
		xlabel(1990(10)2050, labsize(small) labgap(2)) ///
		xtitle("") ///
		legend(off) ///
		text(`=`MAX'[1,1]' `aniomax' "{bf:M{c a'}ximo:} `aniomax'", place(w)) ///
		text(`estimacionvp' `aniovp' "{bf:Paquete Econ{c o'}mico} `aniovp'", place(e)) ///
		///title("{bf:Proyecciones} de los impuestos y aportaciones") subtitle("$pais") ///
		///caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5.") ///
		name(ImpuestosAportacionesProj, replace)

	capture confirm existence $export
	if _rc == 0 {
		graph export "$export/ImpuestosAportacionesProj.png", replace name(ImpuestosAportacionesProj)
	}
}





****************************************/
***                                   ***
***    5. PARTE IV: REDISTRIBUCION    ***
***                                   ***
*****************************************
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
capture g AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
if _rc != 0 {
	replace AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
}
label var AportacionesNetas "de las aportaciones netas"
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** REDISTRIBUCION **
noisily Simulador AportacionesNetas if AportacionesNetas != 0 [fw=factor], ///
	base("ENIGH 2018") boot(1) reboot nographs anio(2020)


** CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`anio') //boot(250) //	<-- OPTIONAL!!! Toma mucho tiempo.


** GRAFICA PROYECCION **
use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
merge 1:1 (anio) using `"`c(sysdir_personal)'/users/$pais/$id/PIB.dta"', nogen
replace estimacion = estimacion/pibYR*100

tabstat estimacion, stat(max) save
tempname MAX
matrix `MAX' = r(StatTotal)
forvalues k=1(1)`=_N' {
	if estimacion[`k'] == `MAX'[1,1] {
		local aniomax = anio[`k']
	}
	if anio[`k'] == `aniovp' {
		local estimacionvp = estimacion[`k']
	}
}

if "$nographs" != "nographs" {
	twoway (connected estimacion anio) (connected estimacion anio if anio == `aniovp') if anio > 1990, ///
		ytitle("% PIB") ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(0(1)5, format(%20.1fc) labsize(small)) ///
		xlabel(1990(10)2050, labsize(small) labgap(2)) ///
		xtitle("") ///
		legend(off) ///
		text(`=`MAX'[1,1]' `aniomax' "{bf:M{c a'}ximo:} `aniomax'", place(w)) ///
		text(`estimacionvp' `aniovp' "{bf:Paquete Econ{c o'}mico} `aniovp'", place(e)) ///
		///title("{bf:Proyecciones} de las aportaciones netas") subtitle("$pais") ///
		///caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5.") ///
		name(AportacionesNetasProj, replace)

	capture confirm existence $export
	if _rc == 0 {
		graph export "$export/AportacionesNetasProj.png", replace name(AportacionesNetasProj)
	}
}


** OUTPUT **
if "$output" == "output" {
	forvalues k=1(5)`=_N' {
		if anio[`k'] >= 2010 {
			local out_proy = "`out_proy' `=string(estimacion[`k'],"%8.3f")',"
		}
	}

	local lengthproy = strlen("`out_proy'")
	quietly log on output
	noisily di in w "PROY: [`=substr("`out_proy'",1,`=`lengthproy'-1')']"
	noisily di in w "PROYMAX: [`aniomax']"
	quietly log off output
}




*******************************/
***                          ***
***    6. PARTE IV: DEUDA    ***
***                          ***
********************************


** SANKEY **
if "$pais" == "" {
	foreach k in escol decil /*sexo grupo_edad*/ {
		noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `aniovp'
	}
}


** FISCAL GAP **
noisily FiscalGap, anio(`aniovp') $nographs end(2050) //boot(250) //update


** OUTPUT **
if "$output" == "output" {
	quietly log close output
	tempfile output1 output2 output3
	if "`=c(os)'" == "Windows" {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/output.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/output.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	*filefilter `output1' `output2', from(" ") to("") replace
	*filefilter `output2' `output3', from("_") to(" ") replace
	*filefilter `output3' "`c(sysdir_personal)'/users/$pais/$id/output.txt", from(".,") to("0") replace
	filefilter `output1' "`c(sysdir_personal)'/users/$pais/$id/output.txt", from(".,") to("0") replace
}



***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
