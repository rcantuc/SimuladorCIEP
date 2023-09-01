******************************
***                        ***
***    SIMULADOR FISCAL    ***
***                        ***
******************************
noisily run "`c(sysdir_personal)'/profile.do"
*global export "`c(sysdir_site)'../TextbookCIEP"
*global nographs "nographs"                                                     // SUPRIMIR GRAFICAS



*************************
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
* iMac Ricardo *
if "`c(username)'" == "ricardo" {
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
}
* Servidor CIEP *
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" {
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
}
adopath ++PERSONAL
noisily run "`c(sysdir_personal)'/parametros.do"






*****************************************************
***                                               ***
***    2. POBLACION + ECONOMÍA + SISTEMA FISCAL   ***
***                                               ***
/*****************************************************

** 2.1 Población **
*foreach estado of global entidadesL {
	*forvalues anio = 1950(1)2070 {
		noisily Poblacion /*if entidad == "`estado'"*/, //anio(`anio') //aniofinal(2030)
	*}
*}


** 2.2 Economía **
noisily PIBDeflactor, //geodef(2005) geopib(2005)
noisily SCN, //update 
noisily Inflacion, //update

noisily LIF, by(divPE) rows(1) min(0) //update desde(2018)
noisily PEF, by(divCIEP) rows(2) min(0) //update desde(2018)

noisily SHRFSP, //update


** 2.4 Subnacionales **
noisily run "`c(sysdir_personal)'/Subnacional.do" //update





**************************/
***                     ***
***    3. HOUSEHOLDS    ***
***                     ***
/***************************

** 3.1 Households information **
forvalues anio = `=anioenigh'(-2)`=anioenigh' {
	capture confirm file "`c(sysdir_personal)'/SIM/`=anioenigh'/expenditures.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_personal)'/Expenditure.do" `anio'
	}
	capture confirm file "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta"
	if _rc != 0 {
		noisily run `"`c(sysdir_personal)'/Households.do"' `anio'
	}
}


** 3.2 Sankey **
foreach k in grupoedad sexo decil rural escol {
	run "`c(sysdir_personal)'/Sankey.do" `k' `=anioenigh'
}


** 3.3 Fiscal profiles **
forvalues anio = `=anioPE'(-1)`=anioPE' {
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `anio'
}





***********************/
***                  ***
***    4. MÓDULOS    ***
***                  ***
************************

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

noisily TasasEfectivas, anio(`=aniovp') nog
noisily GastoPC, anio(`=anioPE')





*****************************/
***                        ***
***    5. CICLO DE VIDA    ***
***                        ***
/******************************
use "`c(sysdir_personal)'/SIM/households`=anioPE'.dta", clear


** (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRAS ISRPF CUOTAS ISRPM IVA IEPSNP IEPSP ISAN IMPORT) //OTROSK
label var ImpuestosAportaciones "impuestos y aportaciones"

** (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Pension Educación Salud IngBasico Pensión_Bienestar) //Inversión
label var Transferencias "transferencias públicas"

** (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH `=anioenigh'") reboot anio(`=anioPE') $nographs //boot(20)
*noisily Gini AportacionesNetas, hogar(folioviv foliohog) factor(factor)


** (*) CUENTA GENERACIONAL **
noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)


** (*) Sankey **
foreach k in grupoedad sexo decil rural escol {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}
save "`c(sysdir_personal)'/users/$id/households.dta", replace






********************************************/
***                                       ***
***    6. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily FiscalGap, end(2030) aniomin(2015) $nographs //update discount(7) desde(2018) //anio(`=aniovp')





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
*noisily scalarlatex, logname(tasasEfectivas)
*run "`c(sysdir_personal)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
