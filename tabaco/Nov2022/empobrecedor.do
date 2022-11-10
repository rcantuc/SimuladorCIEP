clear
version 15
set mem 1000m
set more off



capture log close

cd "D:\Dropbox (CIEP)\Bloomberg Tabaco\2021\STATA"

log using "./empobrecedor.smcl", replace 
use Datos.dta

gen exptotal = gasto_mon*4 //gasto monetario del hogar al año
gen exptobac = tabaco*4 //gasto anual en tabaco del hogar
gen exphealth = salud*4 //gasto anual en salud del hogar
gen expfood = (alimentos-tabaco)*4 //gasto anual en alimentos del hogar
gen expeducn = educacion*4 //gasto anual en educacion del hogar
gen exphousing = vivienda*4 //gasto anual en vivienda del hogar. Incluye renta, predial, agua y electricidad
gen expcloths = vesti_calz*4 //gasto anual en vestimenta y calzado del hogar.
gen expentertmnt = (esparci+paq_turist)*4 //gasto anual en esparcimiento del hogar
gen exptransport = (publico+foraneo+mantenim)*4 //gasto anual en transportacion del hogar. Incluye publico, foraneo, mantenimiento de carros
gen expdurable = adqui_vehi*4 //gasto anual del hogar en bienes duraderos. Incluye solo compra de vehiculos.
gen expother = (limpieza+comunica+personales+transf_gas)*4 //otros gastos anuales del hogar. Incuye limpieza, comonicaciones, gastos personales y ttransferencias como regalos.
gen hsize = tot_integ // Tamaño del hogar
gen meanedu = promedioestudio //promedio de años de estudio en el hogar
gen maxedu = estudiomaximo // años maximos de estudio de alguien del hogar
gen sgroup = est_socio // variable que representa estrato socioeconomico de 1 a 4 en donde 1 es bajo
gen asexratio = hombres/mujeres //ratio de hombres a mujeres en el hogar. Es total, no es posible identificar cuantos menores son hombre o mujer.
gen hweight = factor //es el factor de expansion
gen npl = 19043.52

*following loop generate per capita expendituers and label them
foreach X in total tobac health{
gen pce`X'=exp`X'/hsize
label var pce`X' "percapita expenditure of `X'"
}
*SAF is Smoking (tobacco use) attributable fraction estimated externally
scalar SAF=0.54
replace pcehealth=pcehealth*SAF
*If SAF for SHS exposure is available, instead multiply the pcehealth
*variable with the sum of both SAFs

ren pcetotal pce //gasto total per capita
gen pcet=pce-pcetobac // gasto total per capita sin contar tabaco
label var pcet "pce-expenditure on tobacco"
gen pceh=pcet-pcehealth //gasto total per capita sin contar el gasto total en tabaco y en gastos medidcos relacionados al tabaco
label var pceh "pct-tobacco attributable health care exp."
gen pcehh=pce-pcehealth //gasto total per capita sin contar el gasto total en gastos medidcos relacionados al tabaco
gen pweight=hweight*hsize
*generating an indicator variable for poverty
gen povdum = 0
replace povdum = 1 if pce <= npl
proportion povdum [fw = pweight]
*the following user written module also gives identical result for HCR
*along with other poverty measures. To use this, first apply the following
*command without the star.
*ssc install povdeco, replace
povdeco pce [fw=pweight], varpline(npl)
*Code for computing changes in HCR and number of poor in one shot
local subtr pce pcet pcehh pceh
local nvar: word count `subtr'
matrix M = J(`nvar', 2, .)
forvalues i = 1/`nvar' {
local X: word `i' of `subtr'
qui gen ind = (`X'<=npl)
qui sum ind [fw=pweight]
matrix M[`i', 1] = r(mean)
matrix M[`i', 2] = r(sum)
drop ind
} 
matrix rownames M = `subtr'
matrix colnames M = HCR Poor
*the following lists the results with special formating options
matlist M, cspec(& %12s | %5.4f & %9.0f &) rspec(--&&&-)
log close

