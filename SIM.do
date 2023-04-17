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
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" {                         // Linux ServidorCIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
}
adopath ++ PERSONAL
global export "`c(sysdir_personal)'../../LINGO/Pemex post-petróleo/images/"
*global export "`c(sysdir_personal)'../../EU/LaTeX/images/"



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
global paqueteEconomico = "CGPE 2023"
noisily run "`c(sysdir_personal)'/PARAM.do"                                     // PARÁMETROS (CGPE 2023)
*global output "output"                                                         // IMPRIMIR OUTPUTS (WEB)
*global update "update"                                                         // UPDATE DATASETS/OUTPUTS
*global nographs "nographs"                                                     // SUPRIMIR GRAFICAS



*****************************************************
***                                               ***
***    2. POBLACION + ECONOMÍA + SISTEMA FISCAL   ***
***                                               ***
*****************************************************
** 2.1 Demografía **
*forvalues aniopiramide=1950(1)2050 {
	*foreach entidad of global entidadesL {
		noisily Poblacion /*if entidad == "`entidad'"*/, aniofinal(2050) $update //anio(`aniopiramide')
	*}
*}


** 2.2 Economía **
noisily PIBDeflactor, geodef(2005) geopib(2005) $update
noisily Inflacion, $update


** 2.3 Sistema fiscal **
noisily LIF, by(divPE) rows(1) min(0) $update
noisily SCN, $update
noisily TasasEfectivas
noisily PEF, by(divPE) rows(2) min(0) $update 
noisily SHRFSP, $update





**************************/
***                     ***
***    3. HOUSEHOLDS    ***
***                     ***
***************************

** 3.1 Households information **
capture confirm file "`c(sysdir_personal)'/SIM/`=enighanio'/households.dta"
if _rc != 0 {
	noisily run "`c(sysdir_personal)'/Expenditure.do" `=anioPE'
	noisily run `"`c(sysdir_personal)'/Households.do"' `=anioPE'
}

** 3.2 Households fiscal information **
capture confirm file "`c(sysdir_personal)'/SIM/households`=anioPE'.dta"
if _rc != 0 | "$update" == "update" {
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `=anioPE'
}



******************************/
***                         ***
***    4. SISTEMA FISCAL    ***
***                         ***
*******************************

** 4.1 GASTOS: per cápita **
noisily GastoPC //, anio(`=anioPE')

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
noisily TasasEfectivas //, anio(`=anioPE')



*****************************/
***                        ***
***    5. CICLO DE VIDA    ***
***                        ***
******************************
use `"`c(sysdir_personal)'/users/$id/households.dta"', clear
capture drop AportacionesNetas
g AportacionesNetas = ISRAS + ISRPF + CUOTAS + ISRPM + OTROSK ///
	+ IVA + IEPSNP + IEPSP + ISAN + IMPORT + FMP ///
	- Pension - Educación - Salud - IngBasico - Inversión - Pensión_Bienestar
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=anioPE') folio("folioviv foliohog") $nographs //boot(20)
save "`c(sysdir_personal)'/users/$id/households.dta", replace



** 5.2 CUENTA GENERACIONAL **
noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



** 5.3 Sankey **
foreach k in grupoedad sexo decil rural escol {
*	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}





********************************************/
***                                       ***
***    6. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
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
