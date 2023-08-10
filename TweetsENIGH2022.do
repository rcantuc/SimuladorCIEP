************************
***                  ***
***    ENIGH 2022    ***
***      tweets      ***
***                  ***
************************
noisily run "`c(sysdir_personal)'/profile.do"



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
adopath ++PERSONAL
global export "/home/ciepmx/CIEP Dropbox/ENIGH2022 - MWE/Conciliación con SCN"



**************************/
***                     ***
***    2. HOUSEHOLDS    ***
***                     ***
***************************
*noisily run "`c(sysdir_personal)'/Expenditure.do" 2020
*noisily scalarlatex, logname(Expenditure2020)

noisily run `"`c(sysdir_personal)'/Households.do"' 2022
noisily scalarlatex, logname(Households2022)
noisily run `"`c(sysdir_personal)'/Households.do"' 2020
noisily scalarlatex, logname(Households2020) altname(B)





/*****************************
** Deciles corrientes INEGI **
preserve
egen double ing_decil_hog = mean(corriente), by(folioviv foliohog)
g double ing_decil_pc = ing_decil_hog/`tot_integ'

*xtile decil = ing_decil_pc [pw=factor], n(10)
xtile decil = ing_decil_hog [pw=factor/`tot_integ'], n(10)
xtile quintil = ing_decil_pc [pw=factor], n(5)
xtile percentil = ing_decil_pc [pw=factor], n(100)

replace ing_decil_hog = ing_decil_hog/`deflator'
*replace ing_decil_hog = 0 if ing_decil_hog < 0
Gini ing_decil_hog, hogar(folioviv foliohog) factor(factor)
local giniingdecilpc = r(gini_ing_decil_hog)
scalar giniingdecilpc = `giniingdecilpc'

collapse (mean) ing_decil_hog (max) factor decil, by(folioviv foliohog)
noisily tabstat ing_decil_hog [fw=factor], by(decil) stat(min mean max) format(%20.0fc) save
local j = 1
foreach k in I II III IV V VI VII VIII IX X {
	scalar ingcordecmin`k' = r(Stat`j')[1,1]
	scalar ingcordecpro`k' = r(Stat`j')[2,1]
	scalar ingcordecmax`k' = r(Stat`j')[3,1]
	scalar asisingcordecpro`k' = r(Stat`j')[2,1]
	local ++j
}
scalar ingcordecminNacional = r(StatTotal)[1,1]
scalar ingcordecproNacional = r(StatTotal)[2,1]
scalar ingcordecmaxNacional = r(StatTotal)[3,1]
scalar asisingcordecproNacional = r(StatTotal)[2,1]
restore



*****************************
** Deciles brutos SIMULADOR **
egen double ing_decil_hog = sum(ingbrutotot), by(folioviv foliohog)
g double ing_decil_pc = ing_decil_hog/`tot_integ'

*xtile decil = ing_decil_pc [pw=factor], n(10)
xtile decil = ing_decil_hog [pw=factor/`tot_integ'], n(10)
xtile quintil = ing_decil_pc [pw=factor], n(5)
xtile percentil = ing_decil_pc [pw=factor], n(100)

replace ing_decil_hog = ing_decil_hog/`deflator'
*replace ing_decil_hog = 0 if ing_decil_hog < 0
Gini ing_decil_hog, hogar(folioviv foliohog) factor(factor)
local giniingbrutotot = r(gini_ing_decil_hog)
scalar giniingbrutotot = `giniingbrutotot'

preserve
collapse (mean) ing_decil_hog (max) factor decil, by(folioviv foliohog)
replace ing_decil_hog = ing_decil_hog/4
noisily tabstat ing_decil_hog [fw=factor], by(decil) stat(min mean max) format(%20.0fc) save
local j = 1
foreach k in I II III IV V VI VII VIII IX X {
	scalar ingbrutodecmin`k' = r(Stat`j')[1,1]
	scalar ingbrutodecpro`k' = r(Stat`j')[2,1]
	scalar ingbrutodecmax`k' = r(Stat`j')[3,1]
	scalar asisingbrutodecpro`k' = r(Stat`j')[2,1]
	local ++j
}
scalar ingbrutodecminNacional = r(StatTotal)[1,1]
scalar ingbrutodecproNacional = r(StatTotal)[2,1]
scalar ingbrutodecmaxNacional = r(StatTotal)[3,1]
scalar asisingbrutodecproNacional = r(StatTotal)[2,1]
restore
