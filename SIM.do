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
if "`c(username)'" == "ricardo" {                                               // Mac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" {                         // Linux ServidorCIEP
	sysdir set SITE "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "console" {                  // Linux ServidorCIEP (WEB)
	sysdir set SITE "/SIM/OUT/5/5.3/"
}



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"                 // EXPORTAR IMAGENES EN...
*global update "update"                                                         // UPDATE DATASETS/OUTPUTS
*global output "output"                                                         // IMPRIMIR OUTPUTS (WEB)
*global nographs "nographs"                                                      // SUPRIMIR GRAFICAS

scalar aniovp = 2023
scalar anioend = 2030
noisily run "`c(sysdir_site)'/PARAM.do"                                         // PARÁMETROS (PE 2023)


************************************
***                              ***
***    2. POBLACION + ECONOMÍA   ***
***                              ***
***********************************
*noisily Poblacion, aniofinal(`=scalar(anioend)') //$update
*noisily PIBDeflactor, $update geodef(2013) geopib(2013)
*noisily SCN, $update
*noisily Inflacion, $update

*noisily PEF, by(divPE) rows(2) min(0) $update
*noisily LIF, by(divSIM) rows(2) min(0) eofp $update
*noisily SHRFSP, $update





**************************/
***                     ***
***    3. HOUSEHOLDS    ***
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
***    4. SISTEMA FISCAL    ***
***                         ***
*******************************

** 4.1 Gasto per cápita **
noisily GastoPC


** 4.2 Módulos **
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


** 4.3 Integración **
noisily TasasEfectivas



*****************************/
***                        ***
***    5. CICLO DE VIDA    ***
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


** 5.2 CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=aniovp')


** 5.3 Sankey **
foreach k in /*grupoedad sexo decil rural*/ escol {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=aniovp'
}



********************************************/
***                                       ***
***    6. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
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
