******************************
***                        ***
***    SIMULADOR FISCAL    ***
***                        ***
******************************
clear all
macro drop _all
capture log close _all
timer on 1



**************************************
***                                ***
***    0. GITHUB (PROGRAMACION)    ***
***                                ***
**************************************
if "`c(os)'" == "MacOSX" & "`c(username)'" == "ricardo" {                       // Mac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(os)'" == "Unix" & "`c(username)'" == "ciepmx" {                          // Linux ServidorCIEP
	sysdir set SITE "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
global id "`c(username)'"

global output "outputcorto"                                                     // IMPRIMIR OUTPUTS (WEB)
global nographs "nographs"                                                     // SUPRIMIR GRAFICAS

noisily run "`c(sysdir_site)'/PARAM.do"                                         // PARÁMETROS PE 2023



******************************/
***                         ***
***    5. SISTEMA FISCAL    ***
***                         ***
*******************************
*noisily LIF, by(divSIM) rows(2) min(0) eofp `update'
noisily TasasEfectivas

*noisily PEF, by(divPE) rows(2) min(0) `update'
noisily GastoPC



***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
