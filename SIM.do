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
*global export "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/EU/LaTeX/images/"
global export "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/EU/LaTeX/images/"



*****************************************************
***                                               ***
***    2. POBLACION + ECONOMÍA + SISTEMA FISCAL   ***
***                                               ***
*****************************************************

** 2.1 Demografía **
use `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
levelsof entidad, local(entidad)
*forvalues k=1950(1)2050 {
	foreach j of local entidad {
		noisily Poblacion if entidad == "`j'", aniofinal(2050) $update //anio(`k')
	}
*}
exit
** 2.2 Economía **
noisily PIBDeflactor, geodef(2005) geopib(2005) $update
noisily SCN, $update
noisily Inflacion, $update

** 2.3 Sistema fiscal **
noisily LIF, by(divPE) rows(1) min(0) $update
noisily PEF, by(divCIEP) rows(2) min(0) $update
noisily SHRFSP, $update

exit

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
/*******************************

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
/******************************
use `"`c(sysdir_personal)'/users/$id/households.dta"', clear
capture drop AportacionesNetas
g AportacionesNetas = ISRAS + ISRPF + CUOTAS + ISRPM + OTROSK ///
	+ IVA + IEPSNP + IEPSP + ISAN + IMPORT + FMP ///
	- Pension - Educacion - Salud - IngBasico - Infra - PenBienestar
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=anioPE') folio("folioviv foliohog") $nographs //boot(20)
save "`c(sysdir_personal)'/users/$id/households.dta", replace



** 5.2 CUENTA GENERACIONAL **
noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



** 5.3 Sankey **
foreach k in grupoedad sexo decil rural escol {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}





********************************************/
***                                       ***
***    6. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily FiscalGap, anio(`=aniovp') end(2030) aniomin(2015) $nographs $update discount(7)





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
*run "`c(sysdir_personal)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
