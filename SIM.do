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
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" {                         // Linux ServidorCIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
adopath ++ PERSONAL



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
*global output "output"                                                         // IMPRIMIR OUTPUTS (WEB)
*global update "update"                                                         // UPDATE DATASETS/OUTPUTS
*global nographs "nographs"                                                     // SUPRIMIR GRAFICAS
global export "`c(sysdir_personal)'/../../../LINGO/Pemex post-petróleo/images/" // EXPORTAR IMAGENES EN...
noisily run "`c(sysdir_personal)'/PARAM.do"                                     // PARÁMETROS (PE 2023)



************************************
***                              ***
***    2. POBLACION + ECONOMÍA   ***
***                              ***
************************************
*noisily Poblacion, aniofinal(`=scalar(anioend)') $update
*noisily PIBDeflactor, geodef(2005) geopib(2005) $update
*noisily SCN, $update
*noisily Inflacion, $update

*noisily LIF, by(divPE) rows(1) min(0) eofp $update
*noisily LIF if (divPE == 2) & divCIEP != 2, by(divCIEP) rows(1) min(0) eofp
*noisily PEF, by(divPE) rows(2) min(0) $update
*noisily PEF if ramo == 52, by(divPE) rows(1) min(0)
*noisily SHRFSP, $update




**************************/
***                     ***
***    3. HOUSEHOLDS    ***
***                     ***
/***************************
capture confirm file "`c(sysdir_personal)'/SIM/2020/households.dta"
if _rc != 0 {
	noisily run "`c(sysdir_personal)'/Expenditure.do" `=aniovp'
	noisily run `"`c(sysdir_personal)'/Households.do"' `=aniovp'
}



******************************/
***                         ***
***    4. SISTEMA FISCAL    ***
***                         ***
*******************************

** 4.1 Perfiles fiscales **
capture confirm file "`c(sysdir_personal)'/SIM/2020/households`=aniovp'.dta"
if _rc != 0 | "$update" == "update" {
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `=aniovp'
}


** 4.2 GASTOS: per cápita **
*noisily GastoPC, anio(`=aniovp')


** 4.3 INGRESOS: Módulos **
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


** 4.4 INGRESOS: Tasas Efectivas **
*noisily TasasEfectivas, anio(`=aniovp')





*****************************/
***                        ***
***    5. CICLO DE VIDA    ***
***                        ***
/******************************
use `"`c(sysdir_personal)'/users/$id/households.dta"', clear
capture drop AportacionesNetas
g AportacionesNetas = ISRASSIM + ISRPFSIM + CUOTASSIM + ISRPMSIM /// + OTROSKSIM ///
	+ IVASIM + IEPSNPSIM + IEPSPSIM + ISANSIM + IMPORTSIM + FMPSIM ///
	- Pension - Educacion - Salud - IngBasico - _Infra - PenBienestar
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=aniovp') folio("folioviv foliohog") $nographs //boot(20)
save "`c(sysdir_personal)'/users/$id/households.dta", replace


/** 5.2 CUENTA GENERACIONAL **
noisily CuentasGeneracionales AportacionesNetas, anio(`=aniovp')


** 5.3 Sankey **/
if "$output" == "output" {
	foreach k in /*grupoedad sexo decil rural*/ escol {
		noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
	}
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
*run "`c(sysdir_personal)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
