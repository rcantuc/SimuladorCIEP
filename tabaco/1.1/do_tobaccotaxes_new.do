**Simulador cambios en impuestos al tabaco**

** DIRECTORIO DEL SIMULADOR A MODIFICAR **
** cd "C:\Users\maaci\Dropbox (CIEP)\Bloomberg Tabaco\2020\Simulador impuestos tabaco" **
** cd "/Users/ricardo/Dropbox (CIEP)/EquipoCIEP/A. BackUp/Bloomberg Tabaco/2020/Simulador impuestos tabaco"
** cd "/SIM/OUT/tabaco/1" 
cd "{{ruta}}" 



****************************
*** INICIO del simulador ***
****************************
use "tobaccotaxes.dta"

gen mktshare=0.537 if marca=="Malboro rojo"
replace mktshare=0.165 if marca=="Pall Mall"
replace mktshare=0.074 if marca=="Montana"
replace mktshare=0.073 if marca=="Delicados"
replace mktshare=0.051 if marca=="Benson"
replace mktshare=0.10 if marca=="Otros"
replace mktshare=1 if marca=="Cigarros"

gen sales=1381.3*mktshare
replace sales=1381.3 if marca=="Cigarros"

*gen price=63.6 if marca=="Malboro rojo"
*replace price=52.7 if marca=="Pall Mall"
*replace price=45.8 if marca=="Montana"
*replace price=49.1 if marca=="Delicados"
*replace price=62.1 if marca=="Benson"
*replace price=50.9 if marca=="Otros"



******************************
*** Parametros modificables **
******************************

** impuesto especi­fico **
** En 2020 0.49 pesos por cigarro. Cajetilla de 20= 9.8 **
*gen stax=.4944
*local stax_1=.683 					// <-- PARAMETRO 1 A MODIFICAR  
local stax_1={{ieps_pesos}} 				// <-- PARAMETRO 1 A MODIFICAR  
*gen stax_1=stax*20


** Ad valorem **
** En 2020 160% **
*gen advala=1.6
*gen advalb=`advala'/(1+`advala')
*local advala_1=1.6					// <-- PARAMETRO 2 A MODIFICAR 
local advala_1={{ieps_porcentaje}}/100			// <-- PARAMETRO 2 A MODIFICAR 
local advalb_1=advala/(1+advala)



********************************
** Parametros no modificables **
********************************

** IVA o VAT **
** En 2020 16% del precio total **
*gen vata=0.16
*gen vatb=vata/(1+vata)
*gen vat_1= vata/(1+vata)

** Elasticidad **
** Calculada por CIEP en 2019 **
*gen elasticidad=-0.4240
*gen elasticidad_1=elasticidad*(1.2)

** Margen **
** Se asume un margen de 15% sobre el precio menos iva **
gen margen=.1072
gen margenb=margen/(1+margen)



******************************
*** Calculo de estatus quo ***
******************************

***Paso uno**

***IVA promedio por cajetilla***
gen vatxpack=precio*vatb

***Margen del minorista**
gen minmargen=(precio-vatxpack)*margenb

***Impuesto específico por cajetilla**
gen stxpack=stax*20

***Ad Valorem por cajetilla**
gen avxpack=(precio-vatxpack-minmargen-stxpack)*advalb

***Precio de la industria***
gen pindustry=(precio-vatxpack-minmargen-stxpack-avxpack)
*gen pindustryfix=pindustry

**Cambio en el precio**
*gen preciob=vatxpack+minmargen+stxpack+avxpack+pindustryfix

***Paso dos (resultados)**

**Proporcion de impuesto sobre el precio**
gen taxshare=((vatxpack+stxpack+avxpack)/precio)*100

**Retail sales**
gen rsales=(sales*precio)

**ingreso por iva**
gen vatrev=(sales*vatxpack)
la var vatrev "Recaudación por IVA"

**ingreso al minorista**
gen minrev=(sales*minmargen)

**ingreso por impuesto específico**
gen strev=(sales*stxpack)
la var strev "Impuesto específico"

**ingreso por ad valorem**
gen advrev=(sales*avxpack)
la var advrev "Impuesto ad valorem"

**Ingresos de la industria**
gen indusrev=(sales*pindustry)



****************************
*** Calculo de escenario ***
****************************
gen pindustry_1=pindustry*1.035

***Ad Valorem por cajetilla**
gen avxpack_1=(pindustry_1)*`advala_1'

***Impuesto específico por cajetilla**
gen stxpack_1=`stax_1'*20

***Margen del minorista** Proporción fija respecto al precio mayorista
gen minmargen_1=(pindustry_1)*0.35675

***IVA promedio por cajetilla***
gen vatxpack_1=(pindustry_1+stxpack_1+avxpack_1+minmargen_1)*vata

**Cambio en el precio**
gen precio_1=vatxpack_1+minmargen_1+stxpack_1+avxpack_1+pindustry_1



******************
*** Resultados ***
******************

** Cambio en ventas **
gen sales_1=(sales*(((precio_1-precio)/precio)*elasticidad))+sales

** Proporcion de impuesto sobre el precio **
gen taxshare_1=((vatxpack_1+stxpack_1+avxpack_1)/precio_1)*100

**Retail sales**
gen rsales_1=(sales_1*precio_1)

**ingreso por iva**
gen vatrev_1=(sales_1*vatxpack_1)

**ingreso al minorista**
gen minrev_1=(sales_1*minmargen_1)

**ingreso por impuesto específico**
gen strev_1=(sales_1*stxpack_1)
la var strev_1 "Impuesto específico (1)"

**ingreso por ad valorem**
gen advrev_1=(sales_1*avxpack_1)

la var advrev_1 "Impuesto ad valorem (1)"

**Ingresos de la industria**
gen indusrev_1=(sales_1*pindustry)

**cambio en precio*
gen deltaprecio=(precio_1-precio)/precio



****************
*** Graficas ***
/****************

** Recaudacion por IEPS a tabaco **
graph bar (asis) strev advrev if marca=="Cigarros", stack title(Estatus quo)
graph save Graph "Estatus.gph", replace


graph bar (asis) strev_1 advrev_1 if marca=="Cigarros", stack title(Escenario 1)
graph save Graph "E1.gph", replace
graph combine "Estatus.gph" "E1.gph" , title(Recaudación por IEPS a tabaco) ycommon

** Cambio en ventas **
graph bar (asis) sales sales_1 if marca=="Cigarros", title(Venta de cajetillas de cigarros) subtitle(Millones de cajetillas)



**********************************/
*** Distribucion de recaudacion ***
***********************************
gen cambiosales=((sales_1-sales)/sales)*100

**Estatus quo**
gen participa8=(strev+advrev)*0.08
gen participa23=((strev+advrev)-participa8)*0.2339
gen participaciones=participa8+participa23
gen asalud=(strev+advrev)-participaciones

**Escenario 1***
gen participa8_1=(strev_1+advrev_1)*0.08
gen participa23_1=((strev_1+advrev_1)-participa8_1)*0.2339
gen participaciones_1=participa8_1+participa23_1
gen asalud_1=(strev_1+advrev_1)-participaciones_1



**************/
*** Outputs ***
***************
capture scalar drop pibY pibVPINF pibINF lambda
scalar aa_stax_1 = `stax_1'
scalar ab_advalb_1 = `advalb_1'
scalar ba_strev = strev[_N] + advrev[_N]
scalar bb_strev_1 = strev_1[_N] + advrev_1[_N]
scalar ca_participaciones_1 = participaciones_1[_N]
scalar cb_asalud_1 = asalud_1[_N]
scalar da_sales = sales[_N]
scalar db_sales = sales_1[_N]
scalar ea_taxshare = taxshare[_N]
scalar eb_taxshare_1 = taxshare_1[_N]
scalar fa_precio = precio[_N]
scalar fb_precio_1 = precio_1[_N]



****************************************************************
*** Infografía 3 - Beneficios del aumento del IEPS al tabaco ***
****************************************************************
*gen deltaprecio=0.43
*local deltaprecio=0.43
*gen elasticidad=-0.424
*local elaticidad=-0.424

** Información de ENIGH 2010**
gen exp_tot=31912.74
la var exp_tot "Gasto total del hogar"
gen hh_smoke=.00534
la var hh_smoke "Proporción de hogares que reportan fumar"
gen exp_cig=.0020
la var exp_cig "Proporción de gasto en tabaco respecto al gasto total"
gen exp_salud=.0721
la var exp_salud "Proporción de gasto en salud respecto al gasto total"
gen ilwy=.0019
la var ilwy "Income loss: working years	%"
gen exp_tab_p=1077.857
la var exp_tab_p "Gasto en tabaco"


**Ganancias en ingresos: gasto en tabaco - %**
gen gi_gt=(((1+deltaprecio)*(1+elasticidad*deltaprecio)-1)*exp_cig)*-100

**Ganancias en ingresos: gasto en tabaco - $$**
gen gi_gt_p=(gi_gt*exp_tot)/100

**Ganancias en ingresos: gasto en salud - %**
gen gi_gs=(((1+elasticidad*deltaprecio)-1)*exp_salud)*-100

**Ganancias en ingresos: gasto en salud - $$**
gen gi_gs_p=(gi_gs*exp_tot)/100

**Ganancias en ingreso: dias de vida perdidos - %**
gen gi_yll=(((1+elasticidad*deltaprecio)-1)*ilwy)*-100

**Ganancias en ingreso: dias de vida perdidos - %**
gen gi_yll_p=(gi_yll*exp_tot)/100


****************/
*** Outputs 3 ***
*****************
capture scalar drop pibY pibVPINF pibINF lambda
scalar gi_gt = string(gi_gt_p[_N],"%10.1fc")
scalar gi_gs = string(gi_gs_p[_N],"%10.1fc")
scalar gi_yll = string(gi_yll_p[_N],"%10.1fc")

noisily di _newline(3) in g "{bf:Tabaco} output"
quietly log using "{{ruta}}/output.txt", name(scalar) replace text
*quietly log using "output.txt", name(scalar) replace text
noisily scalar list
quietly log close scalar


noisily run "ccr_entidades_new.do"


** exit, clear STATA **
** 5 valores de resultados **
** ejecutar con  /usr/local/stata15/stata-se -q do_tobaccotaxes.do **
