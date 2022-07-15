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
if "`c(os)'" == "MacOSX" & "`c(username)'" == "ricardo" {                       // Computadora Mac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(os)'" == "Unix" & "`c(username)'" == "ciepmx" {                          // Computdora Linux ServidorCIEP
	sysdir set SITE "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}



************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
*global nographs "nographs"                                                      // SUPRIMIR GRAFICAS
local update "update"                                                          // UPDATE DATASETS
*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"                 // EXPORTAR IMAGENES EN...
*global output "output"                                                         // IMPRIMIR OUTPUTS (WEB)
*global pais = "Ecuador" // "El Salvador"
noisily run "`c(sysdir_site)'/PARAM${pais}.do"

*scalar aniovp = 2021

**************************
***                    ***
***    2. POBLACION    ***
***                    ***
/*************************
noisily Poblacion, `update'



*******************************/
***                          ***
***    3. CRECIMIENTO PIB    ***
***                          ***
********************************
noisily PIBDeflactor, save `update'


exit
noisily SCN, `update'


exit
noisily Inflacion, `update'



******************************/
***                         ***
***    4. SISTEMA FISCAL    ***
***                         ***
*******************************
noisily LIF, `update'                                                           //by(divGA)
noisily PEF, by(desc_funcion) rows(2) min(1) `update'			// <--- ¡¡CORREGIR 2021 Y 2022!!
noisily SHRFSP, `update'




**************************/
***                     ***
***    5. HOUSEHOLDS    ***
***                     ***
***************************
capture confirm file `"`c(sysdir_site)'/users/$pais/$id/ConsumoREC.dta"'
if _rc != 0 | "$export" != "" {
	*noisily run "`c(sysdir_site)'/Expenditure.do" `=aniovp'
	noisily run `"`c(sysdir_site)'/Households`=subinstr("${pais}"," ","",.)'.do"' `=aniovp'
	noisily run `"`c(sysdir_site)'/PerfilesSim.do"' `=aniovp'
}


timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
exit






*********************************/
***                            ***
***    5. PARTE III: GASTOS    ***
***                            ***
**********************************
`noisily' GastoPC, anio(`=aniovp')





**********************************/
***                             ***
***    6. PARTE II: INGRESOS    ***
***                             ***
***********************************
`noisily' TasasEfectivas, anio(`=aniovp')





****************************************/
***                                   ***
***    7. PARTE IV: REDISTRIBUCION    ***
***                                   ***
*****************************************
use `"`c(sysdir_site)'/users/$pais/$id/households.dta"', clear
capture replace Laboral = ISR__asalariados + ISR__PF + CuotasSS
capture drop AportacionesNetas

** 7.1 APORTACIONES NETAS **
g AportacionesNetas = Laboral + Consumo + ISR__PM + Petroleo ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=aniovp') folio("Identif_hog") $nographs
save `"`c(sysdir_site)'/users/$pais/$id/households.dta"', replace	


** 7.2 CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=aniovp')





************************************************/
***                                           ***
***    8. PARTE IV: DEUDA + REDISTRIBUCION    ***
***                                           ***
*************************************************

/** 8.1 SANKEY **
foreach k in decil sexo grupoedad escol {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=aniovp'
}

** 8.2 FISCAL GAP **/
noisily FiscalGap, anio(`=aniovp') end(`=anioend') aniomin(2015) $nographs `update'





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$output" == "output" {
	quietly log on output
	noisily di in w "ISRTASA: [`=string(ISR[1,4],"%10.2f")',`=string(ISR[2,4],"%10.2f")',`=string(ISR[3,4],"%10.2f")',`=string(ISR[4,4],"%10.2f")',`=string(ISR[5,4],"%10.2f")',`=string(ISR[6,4],"%10.2f")',`=string(ISR[7,4],"%10.2f")',`=string(ISR[8,4],"%10.2f")',`=string(ISR[9,4],"%10.2f")',`=string(ISR[10,4],"%10.2f")',`=string(ISR[11,4],"%10.2f")']"
	noisily di in w "ISRCUFI: [`=string(ISR[1,3],"%10.2f")',`=string(ISR[2,3],"%10.2f")',`=string(ISR[3,3],"%10.2f")',`=string(ISR[4,3],"%10.2f")',`=string(ISR[5,3],"%10.2f")',`=string(ISR[6,3],"%10.2f")',`=string(ISR[7,3],"%10.2f")',`=string(ISR[8,3],"%10.2f")',`=string(ISR[9,3],"%10.2f")',`=string(ISR[10,3],"%10.2f")',`=string(ISR[11,3],"%10.2f")']"
	noisily di in w "ISRSUBS: [`=string(SE[1,3],"%10.2f")',`=string(SE[2,3],"%10.2f")',`=string(SE[3,3],"%10.2f")',`=string(SE[4,3],"%10.2f")',`=string(SE[5,3],"%10.2f")',`=string(SE[6,3],"%10.2f")',`=string(SE[7,3],"%10.2f")',`=string(SE[8,3],"%10.2f")',`=string(SE[9,3],"%10.2f")',`=string(SE[10,3],"%10.2f")',`=string(SE[11,3],"%10.2f")',`=string(SE[12,3],"%10.2f")']"
	noisily di in w "ISRDEDU: [`=string(DED[1,1],"%10.2f")',`=string(DED[1,2],"%10.2f")',`=string(DED[1,3],"%10.2f")']"
	noisily di in w "ISRMORA: [`=string(PM[1,1],"%10.2f")',`=string(PM[1,2],"%10.2f")']"
	noisily di in w "IVA: [`=string(IVAT[1,1],"%10.2f")',`=string(IVAT[2,1],"%10.0f")',`=string(IVAT[3,1],"%10.0f")',`=string(IVAT[4,1],"%10.0f")',`=string(IVAT[5,1],"%10.0f")',`=string(IVAT[6,1],"%10.0f")',`=string(IVAT[7,1],"%10.0f")',`=string(IVAT[8,1],"%10.0f")',`=string(IVAT[9,1],"%10.0f")',`=string(IVAT[10,1],"%10.0f")',`=string(IVAT[11,1],"%10.0f")',`=string(IVAT[12,1],"%10.0f")',`=string(IVAT[13,1],"%10.2f")']"
	quietly log off output

	quietly log close output
	tempfile output1 output2 output3
	if "`=c(os)'" == "Windows" {
		filefilter "`c(sysdir_site)'/users/$pais/$id/output.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_site)'/users/$pais/$id/output.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' `output3', from("_") to(" ") replace
	filefilter `output3' "`c(sysdir_site)'/users/$pais/$id/output.txt", from(".,") to("0") replace
}
if "$export" != "" {
	noisily scalarlatex
}
