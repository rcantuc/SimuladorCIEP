***************************************
**** FOR PROGRAMMING PURPOSES ONLY ****
****   COMMENT SECTION OTHERWISE   ****
***************************************
clear all
macro drop _all
capture log close _all

timer on 1
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




********************************
*** 1 POBLACION: ENIGH 2018  ***
***   Simulador v5: Set up   ***
/********************************
noisily Poblacion, //nographs //update
noisily run "`c(sysdir_personal)'/Expenditure.do" 2018 //						<-- a calibrar
noisily run "`c(sysdir_personal)'/Households.do" 2018 //				Cap. 3. Agentes economicos
foreach k in grupo_edad sexo decil escol {
	use "`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta", clear
	noisily run "`c(sysdir_personal)'/Sankey.do" `k' 2018
}




***************************/
*** 2 ECONOMIA Y CUENTAS ***
****************************
noisily run "`c(sysdir_personal)'/2PIBWeb.do" //nographs //						Cap. 2. Sistema: Desempeño + SCN




****************
*** 3 GASTOS ***
****************
noisily run "`c(sysdir_personal)'/3GastosWeb.do" //						Parte III




******************
*** 4 INGRESOS ***
******************
noisily run "`c(sysdir_personal)'/4IngresosWeb.do" //					Parte II




*****************************/
** 5 Cuentas Generacionales **
******************************
noisily run "`c(sysdir_personal)'/5CGWeb.do" //							Parte IV




*********************/
**** Touchdown!!! ****
**********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
