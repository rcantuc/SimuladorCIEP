** 2014 **
import excel "`c(sysdir_site)'../bases/INEGI/Censo_Economico/2014/gennce14_02_nac.xlsx", sheet("gennce14_02") clear

rename R produccinbrutatotalmilesdepesos
rename T valoragregadocensalbrutomilesdep

replace F = subinstr(F,"Clase ","",.)
drop if F == ""
drop in 1

destring F, generate(claseactividad) force
destring produccinbrutatotalmilesdepesos valoragregadocensalbrutomilesdep, replace

collapse (sum) produccinbrutatotalmilesdepesos valoragregadocensalbrutomilesdep, by(claseactividad)

save "`c(sysdir_site)'../bases/INEGI/Censo_Economico/2014/censo_eco.dta", replace


** 2008 **
insheet using "`c(sysdir_site)'../bases/INEGI/Censo_Economico/2008/censo_eco.csv", clear
keep claseactividad produccinbrutatotalmilesdepesos valoragregadocensalbrutomilesdep 

save "`c(sysdir_site)'../bases/INEGI/Censo_Economico/2008/censo_eco.dta", replace

