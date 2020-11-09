**********************************************
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



timer on 1
*global id = "PE2021"
global pais = "El Salvador"



***************************************/
*** Cap. 2. El sistema de la ciencia ***
***  Simulador v5: PIB + Deflactor   ***
****************************************
noisily run "`c(sysdir_personal)'/2PIBWeb.do"





******************************************/
*** Cap. 3. La economia antropocentrica ***
***        Simulador v5: Set up         ***
*******************************************
noisily Poblacion, //nographs //update
/*noisily run `"`c(sysdir_personal)'/Households`=subinstr("${pais}"," ","",.)'.do"' 2018

if "$pais" == "" {
	noisily run "`c(sysdir_personal)'/Expenditure.do" 2018 // 	<-- a calibrar!!!
	use "`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta", clear

	* ENIGH + SCN *
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
}





***************/
*** 3 GASTOS ***
****************
if "$pais" == "" {
	noisily run "`c(sysdir_personal)'/3GastosWeb.do" //			Parte III
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
}
else if "$pais" == "El Salvador" {
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear
}
Simulador Pension [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador Educacion [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador Salud [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador OtrosGas [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador PenBienestar if edad >= 68 [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador IngBasico [fw=factor], base("ENIGH 2018") boot(1) reboot graphs




*****************/
*** 4 INGRESOS ***
******************
if "$pais" == "" {
	* Ingresos: Datos Abiertos *
	DatosAbiertos XNA0120_s, g //						ISR salarios
	DatosAbiertos XNA0120_pf, g //						ISR PF
	DatosAbiertos XNA0120_m, g //						ISR PM
	DatosAbiertos XKF0114, g //						Cuotas IMSS
	DatosAbiertos XAB1120, g //						IVA
	DatosAbiertos XNA0141, g //						ISAN
	DatosAbiertos XAB1130, g //						IEPS
	DatosAbiertos XNA0136, g //						Importaciones
	DatosAbiertos FMP_Derechos, g //					FMP_Derechos
	DatosAbiertos XAB2110, g //						Ingresos propios Pemex
	DatosAbiertos XOA0115, g //						Ingresos propios CFE
	DatosAbiertos XKF0179, g //						Ingresos propios IMSS
	DatosAbiertos XOA0120, g //						Ingresos propios ISSSTE

	noisily run "`c(sysdir_personal)'/4IngresosWeb.do" //			Parte II
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
}
else if "$pais" == "El Salvador" {
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear
}
Simulador Laboral [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador Consumo [fw=factor], base("ENIGH 2018") boot(1) reboot graphs
Simulador OtrosC [fw=factor], base("ENIGH 2018") boot(1) reboot graphs




*****************************/
** 5 Cuentas Generacionales **
******************************
if "$pais" == "" {
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
}
else if "$pais" == "El Salvador" {
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear
}
noisily run "`c(sysdir_personal)'/5CGWeb.do" //					Parte IV





*****************/
** 6 Fiscal Gap **
******************
noisily run "`c(sysdir_personal)'/6FiscalGapWeb.do" //				Parte IV





*********************/
**** Touchdown!!! ****
**********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
