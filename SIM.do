******************************
***                        ***
***    SIMULADOR FISCAL    ***
***                        ***
******************************
noisily run "`c(sysdir_personal)'/profile.do"
adopath ++PERSONAL



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
* iMac Ricardo *
if "`c(username)'" == "ricardo" ///
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"

* Servidor CIEP *
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"

*noisily run "`c(sysdir_site)'/PARAM.do"
*global update "update"                                                         // UPDATE DATASETS/OUTPUTS
*global nographs "nographs"                                                     // SUPRIMIR GRAFICAS
global export "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/ENIGH2022/images"



*****************************************************
***                                               ***
***    2. POBLACION + ECONOMÍA + SISTEMA FISCAL   ***
***                                               ***
/*****************************************************

** 2.1 Población **
*forvalues anio=1950(1)2050 {
	noisily Poblacion, $update //anio(`anio') //aniofinal(2030)
*}


** 2.2 Economía **
noisily PIBDeflactor, //geodef(2005) geopib(2005) $update
noisily SCN, $update
noisily Inflacion, $update


** 2.3 Sistema fiscal **
UpdateDatosAbiertos, $update
noisily LIF, by(divPE) rows(1) min(0) $update
noisily TasasEfectivas

noisily PEF, by(divPE) rows(2) min(0) $update 
noisily GastoPC

noisily SHRFSP, $update


** 2.4 Subnacionales **
noisily run "`c(sysdir_personal)'/Subnacional.do" $update



**************************/
***                     ***
***    3. HOUSEHOLDS    ***
***                     ***
***************************

** 3.1 Households information **
capture confirm file "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta"
*if _rc != 0 {
	*noisily run "`c(sysdir_personal)'/Expenditure.do" 2020
	*noisily scalarlatex, logname(Expenditure2020) altname(B)

	noisily run `"`c(sysdir_personal)'/Households.do"' 2018
	noisily scalarlatex, logname(Households2018) altname(B)
	noisily run `"`c(sysdir_personal)'/Households.do"' 2020
	noisily scalarlatex, logname(Households2020)
*}
exit
** 3.2 Households fiscal information **
capture confirm file "`c(sysdir_personal)'/SIM/households`=aniovp'.dta"
*if _rc != 0 | "$update" == "update" {
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `=aniovp'
*}


exit
******************************/
***                         ***
***    4. SISTEMA FISCAL    ***
***                         ***
/*******************************


** 4.2 INGRESOS: Módulos **
if "`cambioisr'" == "1" {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}
noisily TasasEfectivas, anio(`=aniovp')



*****************************/
***                        ***
***    5. CICLO DE VIDA    ***
***                        ***
/******************************
use `"`c(sysdir_personal)'/users/$id/households.dta"', clear
capture drop AportacionesNetas
g AportacionesNetas = ISRAS + ISRPF + CUOTAS + ISRPM + OTROSK ///
	+ IVA + IEPSNP + IEPSP + ISAN + IMPORT + FMP ///
	- Pension - Educación - Salud - IngBasico - Inversión - Pensión_Bienestar
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=anioPE') folio("folioviv foliohog") $nographs //boot(20)
save "`c(sysdir_personal)'/users/$id/households.dta", replace



** 5.2 CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



** 5.3 Sankey **
foreach k in grupoedad sexo decil rural escol {
*	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}





********************************************/
***                                       ***
***    6. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
/*********************************************
noisily FiscalGap, end(2030) aniomin(2015) $nographs $update discount(7) //anio(`=aniovp')





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$export" != "" {
	noisily scalarlatex, logname(tasasEfectivas)
}
*run "`c(sysdir_personal)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
