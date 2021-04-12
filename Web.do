clear all
macro drop _all
capture log close _all
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
noisily di _newline(50) _col(35) in w "Simulador Fiscal CIEP v5.0" _newline _col(43) in y "$pais"

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
global pib2021 =  5.3
global pib2022 =  3.6
global pib2023 =  2.5
global pib2024 =  2.5
global pib2025 =  2.5

* 2025+ *
global pib2026 =  $pib2025
global pib2027 =  $pib2025
global pib2028 =  $pib2025
global pib2029 =  $pib2025
global pib2030 =  $pib2025
** PARAMETROS SIMULADOR: PIB **
*******************************


** OTROS PARAMETROS **
global def2021 =  3.7393
global def2022 =  3.2820
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
** PARAMETROS SIMULADOR: INGRESOS **
***********************************/


*******************************
** PARAMETROS SIMULADOR: ISR **
*			Inferior	Superior	CF		Tasa
matrix	ISR	= (	0.01,		7735.00,	0.0,		1.92	\	/// 1
			7735.01,	65651.07,	148.51,		6.40	\	/// 2
			65651.08,	115375.90,	3855.14,	10.88	\	/// 3
			115375.91,	134119.41,	9265.20,	16.00	\	/// 4
			134119.42,	160577.65,	12264.16,	17.92	\	/// 5
			160577.66,	323862.00,	17005.47,	21.36	\	/// 6
			323862.01,	510451.00,	51883.01,	23.52	\	/// 7
			510451.01,	974535.03, 	95768.74,	30.00	\	/// 8
			974535.04,	1299380.04,	234993.95,	32.00	\	/// 9
			1299380.05,	3898140.12,	338944.34,	34.00	\	/// 10
			3898140.13,	1E+14, 		1222522.76,	35.00)		//  11

*			Inferior	Superior	Subsidio
matrix	SE	= (	0.00,		21227.52,	4884.24		\		/// 1
			21227.53,	23744.40,	4881.96		\		/// 2
			23744.41,	31840.56,	4881.96		\		/// 3
			31840.57,	41674.08,	4879.44		\		/// 4
			41674.09,	42454.44,	4713.24		\		/// 5
			42454.45,	53353.80,	4589.52		\		/// 6
			53353.81,	56606.16,	4250.76		\		/// 7
			56606.17,	64025.04,	3898.44		\		/// 8
			64025.05,	74696.04,	3535.56		\		/// 9
			74696.05,	85366.80,	3042.48		\		/// 10
			85366.81,	88587.96,	2611.32		\		/// 11
			88587.97, 	1E+14,		0)				//  12

*			SS.MM.		% ing. gr	Informalidad PF (%)
matrix DED	= (	5,		15, 		49.85)										// 65.36

*			Tasa ISR PM			Informalidad PM
matrix PM	= (	30,				35.95)										// 41.47

* Cambios ISR *
local cambioISR = 0
** PARAMETROS SIMULADOR: ISR **
*******************************


** MODULO ISR **
if `cambioISR' != 0 {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
}
capture confirm scalar ISR_AS_Mod
if _rc == 0 {
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}


** OUTPUT **/
if "$output" == "output" {
	quietly log on output
	noisily di in w "ISRTASA: [`=string(ISR[1,4],"%10.2f")',`=string(ISR[2,4],"%10.2f")',`=string(ISR[3,4],"%10.2f")',`=string(ISR[4,4],"%10.2f")',`=string(ISR[5,4],"%10.2f")',`=string(ISR[6,4],"%10.2f")',`=string(ISR[7,4],"%10.2f")',`=string(ISR[8,4],"%10.2f")',`=string(ISR[9,4],"%10.2f")',`=string(ISR[10,4],"%10.2f")',`=string(ISR[11,4],"%10.2f")']"
	noisily di in w "ISRCUFI: [`=string(ISR[1,3],"%10.2f")',`=string(ISR[2,3],"%10.2f")',`=string(ISR[3,3],"%10.2f")',`=string(ISR[4,3],"%10.2f")',`=string(ISR[5,3],"%10.2f")',`=string(ISR[6,3],"%10.2f")',`=string(ISR[7,3],"%10.2f")',`=string(ISR[8,3],"%10.2f")',`=string(ISR[9,3],"%10.2f")',`=string(ISR[10,3],"%10.2f")',`=string(ISR[11,3],"%10.2f")']"
	noisily di in w "ISRSUBS: [`=string(SE[1,3],"%10.2f")',`=string(SE[2,3],"%10.2f")',`=string(SE[3,3],"%10.2f")',`=string(SE[4,3],"%10.2f")',`=string(SE[5,3],"%10.2f")',`=string(SE[6,3],"%10.2f")',`=string(SE[7,3],"%10.2f")',`=string(SE[8,3],"%10.2f")',`=string(SE[9,3],"%10.2f")',`=string(SE[10,3],"%10.2f")',`=string(SE[11,3],"%10.2f")',`=string(SE[12,3],"%10.2f")']"
	noisily di in w "ISRDEDU: [`=string(DED[1,1],"%10.2f")',`=string(DED[1,2],"%10.2f")',`=string(DED[1,3],"%10.2f")']"
	noisily di in w "ISRMORA: [`=string(PM[1,1],"%10.2f")',`=string(PM[1,2],"%10.2f")']"
	quietly log off output
}


*******************************
** PARAMETROS SIMULADOR: IVA **
matrix IVAT = (	16	\	///  1  Tasa general 
		1	\	///  2  Alimentos, 1: Tasa Cero, 2: Exento, 3: Gravado
		2	\	///  3  Alquiler, idem
		1	\	///  4  Canasta basica, idem
		2	\	///  5  Educacion, idem
		3	\	///  6  Consumo fuera del hogar, idem
		3	\	///  7  Mascotas, idem
		1	\	///  8  Medicinas, idem
		3	\	///  9  Otros, idem
		2	\	/// 10  Transporte local, idem
		3	\	/// 11  Transporte foraneo, idem
		39.19	)	//  12  Evasion e informalidad IVA, idem
	
* Cambios IVA *
local cambioIVA = 0
** PARAMETROS SIMULADOR: IVA **
*******************************


** MODULO IVA **
if `cambioIVA' != 0 {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
}
capture confirm scalar IVA_Mod
if _rc == 0 {
	scalar IVA = IVA_Mod
}


** OUTPUT **/
if "$output" == "output" {
	quietly log on output
	noisily di in w "IVA: [`=string(IVAT[1,1],"%10.2f")',`=string(IVAT[2,1],"%10.0f")',`=string(IVAT[3,1],"%10.0f")',`=string(IVAT[4,1],"%10.0f")',`=string(IVAT[5,1],"%10.0f")',`=string(IVAT[6,1],"%10.0f")',`=string(IVAT[7,1],"%10.0f")',`=string(IVAT[8,1],"%10.0f")',`=string(IVAT[9,1],"%10.0f")',`=string(IVAT[10,1],"%10.0f")',`=string(IVAT[11,1],"%10.0f")',`=string(IVAT[12,1],"%10.2f")']"
	quietly log off output
}


** TASAS EFECTIVAS **
noisily TasasEfectivas, anio(`aniovp') `nographs'




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
*noisily CuentasGeneracionales AportacionesNetas, anio(`aniovp') //boot(250) //	<-- OPTIONAL!!! Toma mucho tiempo.


** GRAFICA PROYECCION **
use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
merge 1:1 (anio) using `"`c(sysdir_personal)'/users/$pais/$id/PIB.dta"', nogen
replace estimacion = estimacion/1000000000000

tabstat estimacion if anio >= `aniovp', stat(max) save
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
		ytitle("billones de MXN `aniovp'") ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(#4, format(%20.1fc) labsize(small)) ///
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
foreach k in escol decil sexo grupoedad {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `aniovp'
}


** FISCAL GAP **
noisily FiscalGap, anio(`aniovp') $nographs end(2030) //boot(250) //update


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
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' "`c(sysdir_personal)'/users/$pais/$id/output.txt", from(".,") to("0") replace
}



***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
