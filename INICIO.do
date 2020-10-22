*********************************************
****    FOR PROGRAMMING PURPOSES ONLY    ****
**** SECTION MUST BE COMMENTED OTHERWISE ****
/*********************************************
clear all
macro drop _all
capture log close _all

noisily di _newline(20) in g _col(35) "8) " in w "8) " in y "8) " in g "8)"

if "`c(os)'" == "Unix" {
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/home/ciepmx/Dropbox (CIEP)/Textbook/images/"
}
if "`c(os)'" == "MacOSX" {
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
}
adopath ++ PERSONAL





************************************/
***     1 ECONOMIA Y CUENTAS      ***
*** Simulador v5: PIB + Deflactor ***
*************************************
timer on 1
global id = "PE2021"

noisily run "`c(sysdir_personal)'/2PIBWeb.do" //		Cap. 2. Sistema: PIBDeflactor.ado + SCN.ado





*******************************/
*** 2 POBLACION: ENIGH 2018  ***
***   Simulador v5: Set up   ***
/********************************
noisily Poblacion, //nographs //update
noisily run "`c(sysdir_personal)'/Expenditure.do" 2018 // 	<-- a calibrar!!!
noisily run "`c(sysdir_personal)'/Households.do" 2018 //	Cap. 3. Agentes economicos

use "`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta", clear
Simulador ingbrutotot [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador TOTgasto_anual [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador Yl [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador Yk [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador Ahorro [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador Ciclodevida [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs


* Sankey *
foreach k in grupo_edad decil escol sexo {
	use "`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta", clear
	noisily run "`c(sysdir_personal)'/Sankey.do" `k' 2018
}





***************/
*** 3 GASTOS ***
****************
noisily run "`c(sysdir_personal)'/3GastosWeb.do" //			Parte III


/*Simulador Pension [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador PenBienestar if edad >= 68 [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador Educacion [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador Salud [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador OtrosGas [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador IngBasico [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs




*****************/
*** 4 INGRESOS ***
******************
noisily run "`c(sysdir_personal)'/4IngresosWeb.do" //			Parte II

/*Simulador Laboral [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador Consumo [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs
Simulador OtrosC [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs




*****************************/
** 5 Cuentas Generacionales **
******************************
noisily run "`c(sysdir_personal)'/5CGWeb.do" //				Parte IV





*****************/
** 6 Fiscal Gap **
******************
noisily run "`c(sysdir_personal)'/6FiscalGapWeb.do" //			Parte IV





*********************/
**** Touchdown!!! ****
**********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
