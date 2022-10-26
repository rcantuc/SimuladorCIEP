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
global output "output"                                                          // IMPRIMIR OUTPUTS (WEB)
global nographs "nographs"                                                      // SUPRIMIR GRAFICAS
noisily run "`c(sysdir_site)'/PARAM.do".                                       // PARÁMETROS (PE 2023)





****************************************
***                                  ***
***    2. DIRECTORIOS DEL USUARIO    ***
***                                  ***
****************************************
capture mkdir `"`c(sysdir_site)'/SIM/"'
capture mkdir `"`c(sysdir_site)'/users/"'
capture mkdir `"`c(sysdir_site)'/users/$id/"'
if "$output" == "output" {
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}





************************************
***                              ***
***    3. POBLACION + ECONOMÍA   ***
***                              ***
***********************************
noisily Poblacion, aniofinal(`=scalar(anioend)') //$update
noisily PIBDeflactor, $update geodef(2013) geopib(2013)
noisily SCN, $update
*noisily Inflacion, $update





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
*noisily PEF, by(divPE) rows(2) min(0) $update
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
*noisily LIF, by(divSIM) rows(2) min(0) eofp $update
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
	- Pension - Educacion - Salud - IngBasico - _Infra
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=aniovp') folio("folioviv foliohog") $nographs
save "`c(sysdir_site)'/users/$id/households.dta", replace


** 6.2 CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=aniovp')


** 6.3 Sankey **
foreach k in /*grupoedad sexo decil*/ escol rural {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=aniovp'
}





********************************************
***                                       ***
***    7. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
*noisily SHRFSP, $update
noisily FiscalGap, anio(`=aniovp') end(`=anioend') aniomin(2015) $nographs $update





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
