******************************
***                        ***
***    SIMULADOR FISCAL    ***
***                        ***
******************************
clear all
macro drop _all
capture log close _all
timer on 1



******************************************************
***                                                ***
***    0. DIRECTORIOS DE TRABAJO (PROGRAMACION)    ***
***                                                ***
******************************************************
if "`c(username)'" == "ciepmx" {                  // Linux ServidorCIEP (WEB)
	sysdir set SITE "/SIM/OUT/5/5.3/"
}



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"                 // EXPORTAR IMAGENES EN...
*global update "update"                                                         // UPDATE DATASETS/OUTPUTS
global output "output"                                                          // IMPRIMIR OUTPUTS (WEB)
global nographs "nographs"                                                      // SUPRIMIR GRAFICAS



*****************************************************
***                                               ***
***    2. DIRECTORIOS Y PARÁMETROS DEL USUARIO    ***
***                                               ***
*****************************************************
global id = "`c(username)'"                                                     // ID DEL USUARIO
capture mkdir `"`c(sysdir_site)'/SIM/"'
capture mkdir `"`c(sysdir_site)'/users/"'
capture mkdir `"`c(sysdir_site)'/users/$id/"'
if "$output" != "" {
	quietly log using `"`c(sysdir_site)'/users/$id/$output.txt"', replace text name(output)
	quietly log off output
}



**************************************************
***    2.1. CRECIMIENTO Y DEFLACTOR DEL PIB    ***
**************************************************
scalar aniovp = 2023
scalar anioend = 2030

global pib2022 = 2.4 //       CGPE 2023 (página 134)
global pib2023 = 2.9676 //    CGPE 2023 (página 134)
global pib2024 = 2.4 //       CGPE 2023 (página 134)
global pib2025 = 2.4 //       CGPE 2023 (página 134)
global pib2026 = 2.4 //       CGPE 2023 (página 134)
global pib2027 = 2.4 //       CGPE 2023 (página 134)
global pib2028 = 2.4 //       CGPE 2023 (página 134)

global def2022 = 8.00695 //    CGPE 2023 (página 134)
global def2023 = 4.95000 //    CGPE 2023 (página 134)
global def2024 = 3.46555 //    CGPE 2023 (página 134)
global def2025 = 3.49807 //    CGPE 2023 (página 134)
global def2026 = 3.49211 //    CGPE 2023 (página 134)
global def2027 = 3.51530 //    CGPE 2023 (página 134)
global def2028 = 3.50150 //    CGPE 2023 (página 134)

global tasaEfectiva = 6.6041 // Tasa de inter{c e'}s EFECTIVA
global tipoDeCambio = 20.4   // Tipo de cambio
global depreciacion = 0.2    // Depreciaci{c o'}n


********************************************************
***       2.3.1. Impuesto Sobre la Renta (ISR)       ***
********************************************************
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


***********************************************************
***       2.3.2. Impuesto al Valor Agregado (IVA)       ***
***********************************************************
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
               19.03)   //  13  Evasion e informalidad IVA, input[0-100]
***       FIN: SIMULADOR IVA       ***
*************************************/


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



**************************/
***                     ***
***    4. HOUSEHOLDS    ***
***                     ***
***************************
capture confirm file "`c(sysdir_site)'/SIM/2020/households.dta"
if _rc != 0 {
	noisily run "`c(sysdir_site)'/Expenditure.do" `=aniovp'
	noisily run `"`c(sysdir_site)'/Households.do"' `=aniovp'
}
capture confirm file "`c(sysdir_site)'/users/ciepmx/bootstraps/1/ConsumoREC.dta"
if _rc != 0 {
	noisily run `"`c(sysdir_site)'/PerfilesSim.do"' `=aniovp'
}



******************************/
***                         ***
***    5. SISTEMA FISCAL    ***
***                         ***
*******************************
noisily PEF, by(divPE) rows(2) min(0) $update
noisily GastoPC


** 5.1 Módulos **
if "`cambioisr'" == "1" {
	noisily run "`c(sysdir_site)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}


** 5.2 Integración **
noisily LIF, by(divSIM) rows(2) min(0) eofp $update
noisily TasasEfectivas





*****************************/
***                        ***
***    6. CICLO DE VIDA    ***
***                        ***
******************************
use `"`c(sysdir_site)'/users/$id/households.dta"', clear
capture drop AportacionesNetas
g AportacionesNetas = ISRASSIM + ISRPFSIM + CUOTASSIM + ISRPMSIM /// + OTROSKSIM ///
	+ IVASIM + IEPSNPSIM + IEPSPSIM + ISANSIM + IMPORTSIM + FMPSIM ///
	- Pension - Educacion - Salud - IngBasico - _Infra - PenBienestar
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=aniovp') folio("folioviv foliohog") $nographs
save "`c(sysdir_site)'/users/$id/households.dta", replace


** 6.2 CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=aniovp')


** 6.3 Sankey **
foreach k in /*grupoedad sexo decil rural*/ escol {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=aniovp'
}





********************************************/
***                                       ***
***    7. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily SHRFSP, $update
noisily FiscalGap, anio(`=aniovp') end(`=anioend') aniomin(2015) $nographs $update discount(7)





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
