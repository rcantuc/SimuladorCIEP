***********************************************************
*** Infografia 2 - distribucion a entidades federativas ***
***********************************************************
*cd "C:\Users\CIEPmx\Dropbox (CIEP)\Bloomberg Tabaco\2020\Simulador impuestos tabaco"
*cd "/Users/ricardo/Dropbox (CIEP)/EquipoCIEP/A. BackUp/Bloomberg Tabaco/2020/Simulador impuestos tabaco"
*cd "C:\Users\maaci\Dropbox (CIEP)\Bloomberg Tabaco\2020\Simulador impuestos tabaco"
cd "{{ruta}}" 



****************************
*** INICIO del simulador ***
****************************
use "entidadesnov2021.dta", clear

**Estatus quo**
**8% directo*
gen recaudacion=42649.9
gen directo8=recaudacion*0.08

*\el 92% restante de IEPS a tabaco se distribuye según los porcentajes de la LCF; en la nota metodolófica se ponen los porcentajes sobre el total de IEPS a tabaco*/
gen ieps92=recaudacion*0.92

gen fgp=ieps92*0.2
gen fgp2=recaudacion*0.184
gen litoral=ieps92*0.00136
gen litoral2=recaudacion*0.001256
gen ffm=ieps92*0.01
gen ffr=ieps92*0.0125

rename entidad entidad_federativa
rename cve_ent id_entidad_federativa

*Esto es 2021 (hasta septiembre)

*Distribucion estatal del FGP*
gen fgp_estatal=fgp*0.0108602684779 if id_entidad_federativa==1  
replace fgp_estatal=fgp*0.0301303714739 if id_entidad_federativa==2
replace fgp_estatal=fgp*0.0055255210595 if id_entidad_federativa==3
replace fgp_estatal=fgp*0.0084898174369 if id_entidad_federativa==4
replace fgp_estatal=fgp*0.0242362198179 if id_entidad_federativa==5
replace fgp_estatal=fgp*0.0064133063869 if id_entidad_federativa==6
replace fgp_estatal=fgp*0.0427163764276 if id_entidad_federativa==7
replace fgp_estatal=fgp*0.0296537414288 if id_entidad_federativa==8
replace fgp_estatal=fgp*0.1038642049140 if id_entidad_federativa==9
replace fgp_estatal=fgp*0.0136329774539 if id_entidad_federativa==10
replace fgp_estatal=fgp*0.0436030111497 if id_entidad_federativa==11
replace fgp_estatal=fgp*0.0241818603304 if id_entidad_federativa==12
replace fgp_estatal=fgp*0.0197035348735 if id_entidad_federativa==13
replace fgp_estatal=fgp*0.0674556372979 if id_entidad_federativa==14
replace fgp_estatal=fgp*0.1376895102596 if id_entidad_federativa==15
replace fgp_estatal=fgp*0.0333879478738 if id_entidad_federativa==16
replace fgp_estatal=fgp*0.0144557645626 if id_entidad_federativa==17
replace fgp_estatal=fgp*0.0093527378689 if id_entidad_federativa==18
replace fgp_estatal=fgp*0.0495077432135 if id_entidad_federativa==19
replace fgp_estatal=fgp*0.0257109259569 if id_entidad_federativa==20
replace fgp_estatal=fgp*0.0452849832291 if id_entidad_federativa==21
replace fgp_estatal=fgp*0.0176842204242 if id_entidad_federativa==22
replace fgp_estatal=fgp*0.0132639052363 if id_entidad_federativa==23
replace fgp_estatal=fgp*0.0198079266090 if id_entidad_federativa==24
replace fgp_estatal=fgp*0.0242673406932 if id_entidad_federativa==25
replace fgp_estatal=fgp*0.0233525019150 if id_entidad_federativa==26
replace fgp_estatal=fgp*0.0276742272401 if id_entidad_federativa==27
replace fgp_estatal=fgp*0.0278935704952 if id_entidad_federativa==28
replace fgp_estatal=fgp*0.0101691726741 if id_entidad_federativa==29
replace fgp_estatal=fgp*0.0617334030213 if id_entidad_federativa==30
replace fgp_estatal=fgp*0.0165338620446 if id_entidad_federativa==31
replace fgp_estatal=fgp*0.0117634081537 if id_entidad_federativa==32
replace fgp_estatal=fgp if id_entidad_federativa==33


*Distribucion estatal del Litoral*
gen litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==1
replace litoral_estatal=litoral*0.043001624502717 if id_entidad_federativa==2
replace litoral_estatal=litoral*0.000084427221866 if id_entidad_federativa==3
replace litoral_estatal=litoral*0.003259715744176 if id_entidad_federativa==4
replace litoral_estatal=litoral*0.028011289200802 if id_entidad_federativa==5
replace litoral_estatal=litoral*0.028951910086041 if id_entidad_federativa==6
replace litoral_estatal=litoral*0.001258873884630 if id_entidad_federativa==7
replace litoral_estatal=litoral*0.043467365558627 if id_entidad_federativa==8
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==9
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==10
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==11
replace litoral_estatal=litoral*0.000917737455820 if id_entidad_federativa==12
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==13
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==14
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==15
replace litoral_estatal=litoral*0.055536976314099 if id_entidad_federativa==16
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==17
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==18
replace litoral_estatal=litoral*0.015328689036630 if id_entidad_federativa==19
replace litoral_estatal=litoral*0.000291085877325 if id_entidad_federativa==20
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==21
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==22
replace litoral_estatal=litoral*0.005055641437910 if id_entidad_federativa==23
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==24
replace litoral_estatal=litoral*0.002147460652938 if id_entidad_federativa==25
replace litoral_estatal=litoral*0.051528971759930 if id_entidad_federativa==26
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==27
replace litoral_estatal=litoral*0.667522195769034 if id_entidad_federativa==28
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==29
replace litoral_estatal=litoral*0.048007178755180 if id_entidad_federativa==30
replace litoral_estatal=litoral*0.005628856742274 if id_entidad_federativa==31
replace litoral_estatal=litoral*0.00000000000000 if id_entidad_federativa==32
replace litoral_estatal=litoral==33


*Distribucion estatal del FFM*
gen ffm_estatal=ffm*0.01950565475793 if id_entidad_federativa==1
replace ffm_estatal=ffm*0.01908190989233 if id_entidad_federativa==2
replace ffm_estatal=ffm*0.00628689405933 if id_entidad_federativa==3
replace ffm_estatal=ffm*0.01050841116019 if id_entidad_federativa==4
replace ffm_estatal=ffm*0.01941865404792 if id_entidad_federativa==5
replace ffm_estatal=ffm*0.00980436232423 if id_entidad_federativa==6
replace ffm_estatal=ffm*0.02779987358740 if id_entidad_federativa==7
replace ffm_estatal=ffm*0.02872091140547 if id_entidad_federativa==8
replace ffm_estatal=ffm*0.11207463293053 if id_entidad_federativa==9
replace ffm_estatal=ffm*0.02078256937364 if id_entidad_federativa==10
replace ffm_estatal=ffm*0.04618981555202 if id_entidad_federativa==11
replace ffm_estatal=ffm*0.01923723871497 if id_entidad_federativa==12
replace ffm_estatal=ffm*0.03701193665991 if id_entidad_federativa==13
replace ffm_estatal=ffm*0.05815176828085 if id_entidad_federativa==14
replace ffm_estatal=ffm*0.10021433138929 if id_entidad_federativa==15
replace ffm_estatal=ffm*0.04269331614236 if id_entidad_federativa==16
replace ffm_estatal=ffm*0.01791428355230 if id_entidad_federativa==17
replace ffm_estatal=ffm*0.01509623787745 if id_entidad_federativa==18
replace ffm_estatal=ffm*0.03423174075237 if id_entidad_federativa==19
replace ffm_estatal=ffm*0.04330924000463 if id_entidad_federativa==20
replace ffm_estatal=ffm*0.04640698712102 if id_entidad_federativa==21
replace ffm_estatal=ffm*0.02116262959395 if id_entidad_federativa==22
replace ffm_estatal=ffm*0.01413629660427 if id_entidad_federativa==23
replace ffm_estatal=ffm*0.02434437178342 if id_entidad_federativa==24
replace ffm_estatal=ffm*0.02328475092162 if id_entidad_federativa==25
replace ffm_estatal=ffm*0.01550267762818 if id_entidad_federativa==26
replace ffm_estatal=ffm*0.02300943770446 if id_entidad_federativa==27
replace ffm_estatal=ffm*0.02730253235544 if id_entidad_federativa==28
replace ffm_estatal=ffm*0.01381675288253 if id_entidad_federativa==29
replace ffm_estatal=ffm*0.04721098565383 if id_entidad_federativa==30
replace ffm_estatal=ffm*0.02828320710884 if id_entidad_federativa==31
replace ffm_estatal=ffm*0.02750558817734 if id_entidad_federativa==32
replace ffm_estatal=ffm if id_entidad_federativa==33


*Distribucion estatal del FFR*
gen ffr_estatal=ffr*0.0098052082235 if id_entidad_federativa==1
replace ffr_estatal=ffr*0.0286275748489 if id_entidad_federativa==2
replace ffr_estatal=ffr*0.0062979375912 if id_entidad_federativa==3
replace ffr_estatal=ffr*0.0062767586488 if id_entidad_federativa==4
replace ffr_estatal=ffr*0.0192265494589 if id_entidad_federativa==5
replace ffr_estatal=ffr*0.0051004677111 if id_entidad_federativa==6
replace ffr_estatal=ffr*0.0349707584762 if id_entidad_federativa==7
replace ffr_estatal=ffr*0.0363084083725 if id_entidad_federativa==8
replace ffr_estatal=ffr*0.0879487930587 if id_entidad_federativa==9
replace ffr_estatal=ffr*0.0120969385382 if id_entidad_federativa==10
replace ffr_estatal=ffr*0.0540243533386 if id_entidad_federativa==11
replace ffr_estatal=ffr*0.0171926170772 if id_entidad_federativa==12
replace ffr_estatal=ffr*0.0152633165089 if id_entidad_federativa==13
replace ffr_estatal=ffr*0.0550401699374 if id_entidad_federativa==14
replace ffr_estatal=ffr*0.1249440049435 if id_entidad_federativa==15
replace ffr_estatal=ffr*0.0243595363739 if id_entidad_federativa==16
replace ffr_estatal=ffr*0.0107656089178 if id_entidad_federativa==17
replace ffr_estatal=ffr*0.0075899664588 if id_entidad_federativa==18
replace ffr_estatal=ffr*0.0400557098545 if id_entidad_federativa==19
replace ffr_estatal=ffr*0.0240108421094 if id_entidad_federativa==20
replace ffr_estatal=ffr*0.0368214767704 if id_entidad_federativa==21
replace ffr_estatal=ffr*0.0223940411119 if id_entidad_federativa==22
replace ffr_estatal=ffr*0.0132564987659 if id_entidad_federativa==23
replace ffr_estatal=ffr*0.0236283468608 if id_entidad_federativa==24
replace ffr_estatal=ffr*0.0091952168100 if id_entidad_federativa==25
replace ffr_estatal=ffr*0.1087299039935 if id_entidad_federativa==26
replace ffr_estatal=ffr*0.0542901456466 if id_entidad_federativa==27
replace ffr_estatal=ffr*0.0215725529839 if id_entidad_federativa==28
replace ffr_estatal=ffr*0.0081430156113 if id_entidad_federativa==29
replace ffr_estatal=ffr*0.0428264738570 if id_entidad_federativa==30
replace ffr_estatal=ffr*0.0298892485459 if id_entidad_federativa==31
replace ffr_estatal=ffr*0.0093475585950 if id_entidad_federativa==32
replace ffr_estatal=ffr if id_entidad_federativa==33


*Distribucion estatal del 8% directo*
gen directo_estatal=directo8*0.012104292388 if id_entidad_federativa==1
replace directo_estatal=directo8*0.042914792412 if id_entidad_federativa==2
replace directo_estatal=directo8*0.009270759785 if id_entidad_federativa==3
replace directo_estatal=directo8*0.001529880461 if id_entidad_federativa==4
replace directo_estatal=directo8*0.029898751643 if id_entidad_federativa==5
replace directo_estatal=directo8*0.007467562150 if id_entidad_federativa==6
replace directo_estatal=directo8*0.004897770229 if id_entidad_federativa==7
replace directo_estatal=directo8*0.039554534824 if id_entidad_federativa==8
replace directo_estatal=directo8*0.105933955544 if id_entidad_federativa==9
replace directo_estatal=directo8*0.011845280245 if id_entidad_federativa==10
replace directo_estatal=directo8*0.047521792281 if id_entidad_federativa==11
replace directo_estatal=directo8*0.008855409955 if id_entidad_federativa==12
replace directo_estatal=directo8*0.011463179788 if id_entidad_federativa==13
replace directo_estatal=directo8*0.091152781162 if id_entidad_federativa==14
replace directo_estatal=directo8*0.192320884199 if id_entidad_federativa==15
replace directo_estatal=directo8*0.038942446170 if id_entidad_federativa==16
replace directo_estatal=directo8*0.010109285048 if id_entidad_federativa==17
replace directo_estatal=directo8*0.007260619492 if id_entidad_federativa==18
replace directo_estatal=directo8*0.077967071831 if id_entidad_federativa==19
replace directo_estatal=directo8*0.006837155683 if id_entidad_federativa==20
replace directo_estatal=directo8*0.033123962293 if id_entidad_federativa==21
replace directo_estatal=directo8*0.030881369973 if id_entidad_federativa==22
replace directo_estatal=directo8*0.006992526032 if id_entidad_federativa==23
replace directo_estatal=directo8*0.019337253835 if id_entidad_federativa==24
replace directo_estatal=directo8*0.021163875231 if id_entidad_federativa==25
replace directo_estatal=directo8*0.026511967574 if id_entidad_federativa==26
replace directo_estatal=directo8*0.015312512588 if id_entidad_federativa==27
replace directo_estatal=directo8*0.029449883803 if id_entidad_federativa==28
replace directo_estatal=directo8*0.005811102515 if id_entidad_federativa==29
replace directo_estatal=directo8*0.026278447525 if id_entidad_federativa==30
replace directo_estatal=directo8*0.018922385407 if id_entidad_federativa==31
replace directo_estatal=directo8*0.008366507934 if id_entidad_federativa==32
replace directo_estatal=directo8 if id_entidad_federativa==33


*IEPS de tabaco total porestado. El total de IEPS a tabaco por estado da mÃ¡s en stata que en excel, creo que es por el nÃºmero de decimales usados en cad aprograma*
*Total de IEPs a tabaco en estatus quo*
gen iepst_estatal=fgp_estatal+litoral_estatal+ffm_estatal+ffr_estatal+directo_estatal

*distribucion porcuental deÃ± IEPS de tabaco estatal*
gen piepst_estatal=iepst_estatal/12497.96 

***********************************************************************************************************************
***Simulación***

**8% directo*
*gen recaudacion_1=59220.1
gen recaudacion_1=scalar(bb_strev_1)
gen directo8_1=recaudacion_1*0.08

*el 92% restante de IEPS a tabaco se distribuye segun los porcentajes de la LCF; en la nota metodologica se ponen los porcentajes sobre el total de IEPS a tabaco
gen ieps92_1=recaudacion_1*0.92

gen fgp_1=ieps92_1*0.2
gen fgp2_1=recaudacion_1*0.184
gen litoral_1=ieps92_1*0.00136
gen litoral2_1=recaudacion_1*0.001256
gen ffm_1=ieps92_1*0.01
gen ffr_1=ieps92_1*0.0125

*(esto es 2020 anual)

*Distribucion estatal del FGP*
gen fgp_estatal_1=fgp_1*0.0107585160227 if id_entidad_federativa==1
replace fgp_estatal_1=fgp_1*0.0288915444430 if id_entidad_federativa==2
replace fgp_estatal_1=fgp_1*0.0072419285142 if id_entidad_federativa==3
replace fgp_estatal_1=fgp_1*0.0085015660678 if id_entidad_federativa==4
replace fgp_estatal_1=fgp_1*0.0236526741849 if id_entidad_federativa==5
replace fgp_estatal_1=fgp_1*0.0064140545099 if id_entidad_federativa==6
replace fgp_estatal_1=fgp_1*0.0422198315717 if id_entidad_federativa==7
replace fgp_estatal_1=fgp_1*0.0296129175716 if id_entidad_federativa==8
replace fgp_estatal_1=fgp_1*0.1037259656181 if id_entidad_federativa==9
replace fgp_estatal_1=fgp_1*0.0132519395550 if id_entidad_federativa==10
replace fgp_estatal_1=fgp_1*0.0422268466233 if id_entidad_federativa==11
replace fgp_estatal_1=fgp_1*0.0249325028208 if id_entidad_federativa==12
replace fgp_estatal_1=fgp_1*0.0203928169811 if id_entidad_federativa==13
replace fgp_estatal_1=fgp_1*0.0666989893263 if id_entidad_federativa==14
replace fgp_estatal_1=fgp_1*0.1428315145577 if id_entidad_federativa==15
replace fgp_estatal_1=fgp_1*0.0314563331809 if id_entidad_federativa==16
replace fgp_estatal_1=fgp_1*0.0141110154385 if id_entidad_federativa==17
replace fgp_estatal_1=fgp_1*0.0094550425502 if id_entidad_federativa==18
replace fgp_estatal_1=fgp_1*0.0469641565274 if id_entidad_federativa==19
replace fgp_estatal_1=fgp_1*0.0284222651888 if id_entidad_federativa==20
replace fgp_estatal_1=fgp_1*0.0433078962108 if id_entidad_federativa==21
replace fgp_estatal_1=fgp_1*0.0166704410923 if id_entidad_federativa==22
replace fgp_estatal_1=fgp_1*0.0130890269528 if id_entidad_federativa==23
replace fgp_estatal_1=fgp_1*0.0200999406844 if id_entidad_federativa==24
replace fgp_estatal_1=fgp_1*0.0240638024133 if id_entidad_federativa==25
replace fgp_estatal_1=fgp_1*0.0241867453650 if id_entidad_federativa==26
replace fgp_estatal_1=fgp_1*0.0279043073574 if id_entidad_federativa==27
replace fgp_estatal_1=fgp_1*0.0284023695291 if id_entidad_federativa==28
replace fgp_estatal_1=fgp_1*0.0103162446320 if id_entidad_federativa==29
replace fgp_estatal_1=fgp_1*0.0621239174659 if id_entidad_federativa==30
replace fgp_estatal_1=fgp_1*0.0163565992380 if id_entidad_federativa==31
replace fgp_estatal_1=fgp_1*0.0117162878054 if id_entidad_federativa==32
replace fgp_estatal_1=fgp_1 if id_entidad_federativa==33


*Distribucion estatal del Litoral*
gen litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==1
replace litoral_estatal_1=litoral_1*0.0402154146473 if id_entidad_federativa==2
replace litoral_estatal_1=litoral_1*0.0001113743751 if id_entidad_federativa==3
replace litoral_estatal_1=litoral_1*0.0034423949129 if id_entidad_federativa==4
replace litoral_estatal_1=litoral_1*0.0239809005672 if id_entidad_federativa==5
replace litoral_estatal_1=litoral_1*0.0300253973453 if id_entidad_federativa==6
replace litoral_estatal_1=litoral_1*0.0014155739280 if id_entidad_federativa==7
replace litoral_estatal_1=litoral_1*0.0448986362204 if id_entidad_federativa==8
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==9
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==10
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==11
replace litoral_estatal_1=litoral_1*0.0010798030780 if id_entidad_federativa==12
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==13
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==14
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==15
replace litoral_estatal_1=litoral_1*0.0544506489137 if id_entidad_federativa==16
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==17
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==18
replace litoral_estatal_1=litoral_1*0.0149441194887 if id_entidad_federativa==19
replace litoral_estatal_1=litoral_1*0.0003536135798 if id_entidad_federativa==20
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==21
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==22
replace litoral_estatal_1=litoral_1*0.0056875932768 if id_entidad_federativa==23
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==24
replace litoral_estatal_1=litoral_1*0.0021751152098 if id_entidad_federativa==25
replace litoral_estatal_1=litoral_1*0.0532707658697 if id_entidad_federativa==26
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==27
replace litoral_estatal_1=litoral_1*0.6738145939427 if id_entidad_federativa==28
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==29
replace litoral_estatal_1=litoral_1*0.0438410743368 if id_entidad_federativa==30
replace litoral_estatal_1=litoral_1*0.0062929803080 if id_entidad_federativa==31
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==32
replace litoral_estatal_1=litoral_1 if id_entidad_federativa==33


*Distribucion estatal del FFM*
gen ffm_estatal_1=ffm_1*0.020366820211 if id_entidad_federativa==1
replace ffm_estatal_1=ffm_1*0.017621186118 if id_entidad_federativa==2
replace ffm_estatal_1=ffm_1*0.006714345721 if id_entidad_federativa==3
replace ffm_estatal_1=ffm_1*0.011036980006 if id_entidad_federativa==4
replace ffm_estatal_1=ffm_1*0.018276569691 if id_entidad_federativa==5
replace ffm_estatal_1=ffm_1*0.010668957155 if id_entidad_federativa==6
replace ffm_estatal_1=ffm_1*0.026894905869 if id_entidad_federativa==7
replace ffm_estatal_1=ffm_1*0.027124017222 if id_entidad_federativa==8
replace ffm_estatal_1=ffm_1*0.113385333719 if id_entidad_federativa==9
replace ffm_estatal_1=ffm_1*0.021138729256 if id_entidad_federativa==10
replace ffm_estatal_1=ffm_1*0.047423655712 if id_entidad_federativa==11
replace ffm_estatal_1=ffm_1*0.019935993006 if id_entidad_federativa==12
replace ffm_estatal_1=ffm_1*0.039735949170 if id_entidad_federativa==13
replace ffm_estatal_1=ffm_1*0.052561080340 if id_entidad_federativa==14
replace ffm_estatal_1=ffm_1*0.092664738060 if id_entidad_federativa==15
replace ffm_estatal_1=ffm_1*0.043955145707 if id_entidad_federativa==16
replace ffm_estatal_1=ffm_1*0.018247890107 if id_entidad_federativa==17
replace ffm_estatal_1=ffm_1*0.016592740485 if id_entidad_federativa==18
replace ffm_estatal_1=ffm_1*0.029927875313 if id_entidad_federativa==19
replace ffm_estatal_1=ffm_1*0.043166417454 if id_entidad_federativa==20
replace ffm_estatal_1=ffm_1*0.048365835813 if id_entidad_federativa==21
replace ffm_estatal_1=ffm_1*0.021659889914 if id_entidad_federativa==22
replace ffm_estatal_1=ffm_1*0.015223325673 if id_entidad_federativa==23
replace ffm_estatal_1=ffm_1*0.025808338466 if id_entidad_federativa==24
replace ffm_estatal_1=ffm_1*0.020055812796 if id_entidad_federativa==25
replace ffm_estatal_1=ffm_1*0.014965880776 if id_entidad_federativa==26
replace ffm_estatal_1=ffm_1*0.025729930380 if id_entidad_federativa==27
replace ffm_estatal_1=ffm_1*0.028605520603 if id_entidad_federativa==28
replace ffm_estatal_1=ffm_1*0.015047735605 if id_entidad_federativa==29
replace ffm_estatal_1=ffm_1*0.047280786372 if id_entidad_federativa==30
replace ffm_estatal_1=ffm_1*0.029424611762 if id_entidad_federativa==31
replace ffm_estatal_1=ffm_1*0.030393001516 if id_entidad_federativa==32
replace ffm_estatal_1=ffm_1 if id_entidad_federativa==33


*Distribucion estatal del FFR*
gen ffr_estatal_1=ffr_1*0.0089699059175 if id_entidad_federativa==1
replace ffr_estatal_1=ffr_1*0.0273992566191 if id_entidad_federativa==2
replace ffr_estatal_1=ffr_1*0.0055748703625 if id_entidad_federativa==3
replace ffr_estatal_1=ffr_1*0.0063399113233 if id_entidad_federativa==4
replace ffr_estatal_1=ffr_1*0.0194954387859 if id_entidad_federativa==5
replace ffr_estatal_1=ffr_1*0.0050338388978 if id_entidad_federativa==6
replace ffr_estatal_1=ffr_1*0.0343099525103 if id_entidad_federativa==7
replace ffr_estatal_1=ffr_1*0.0275721234972 if id_entidad_federativa==8
replace ffr_estatal_1=ffr_1*0.0886421455635 if id_entidad_federativa==9
replace ffr_estatal_1=ffr_1*0.0123529352941 if id_entidad_federativa==10
replace ffr_estatal_1=ffr_1*0.0487827413883 if id_entidad_federativa==11
replace ffr_estatal_1=ffr_1*0.0174457278136 if id_entidad_federativa==12
replace ffr_estatal_1=ffr_1*0.0150564141998 if id_entidad_federativa==13
replace ffr_estatal_1=ffr_1*0.0539845120412 if id_entidad_federativa==14
replace ffr_estatal_1=ffr_1*0.1179505468834 if id_entidad_federativa==15
replace ffr_estatal_1=ffr_1*0.0237005804637 if id_entidad_federativa==16
replace ffr_estatal_1=ffr_1*0.0106845573525 if id_entidad_federativa==17
replace ffr_estatal_1=ffr_1*0.0078427847292 if id_entidad_federativa==18
replace ffr_estatal_1=ffr_1*0.0365567265146 if id_entidad_federativa==19
replace ffr_estatal_1=ffr_1*0.0215942978713 if id_entidad_federativa==20
replace ffr_estatal_1=ffr_1*0.0357150774931 if id_entidad_federativa==21
replace ffr_estatal_1=ffr_1*0.0160950568269 if id_entidad_federativa==22
replace ffr_estatal_1=ffr_1*0.0121351732314 if id_entidad_federativa==23
replace ffr_estatal_1=ffr_1*0.0232565327141 if id_entidad_federativa==24
replace ffr_estatal_1=ffr_1*0.0479023167552 if id_entidad_federativa==25
replace ffr_estatal_1=ffr_1*0.1047037962203 if id_entidad_federativa==26
replace ffr_estatal_1=ffr_1*0.0556212491427 if id_entidad_federativa==27
replace ffr_estatal_1=ffr_1*0.0219597239720 if id_entidad_federativa==28
replace ffr_estatal_1=ffr_1*0.0110343759213 if id_entidad_federativa==29
replace ffr_estatal_1=ffr_1*0.0439822123193 if id_entidad_federativa==30
replace ffr_estatal_1=ffr_1*0.0294155548835 if id_entidad_federativa==31
replace ffr_estatal_1=ffr_1*0.0088896624918 if id_entidad_federativa==32
replace ffr_estatal_1=ffr_1 if id_entidad_federativa==33


*Distribucion estatal del 8% directo*
gen directo_estatal_1=directo8_1*0.0122790258429 if id_entidad_federativa==1
replace directo_estatal_1=directo8_1*0.0379884172487 if id_entidad_federativa==2
replace directo_estatal_1=directo8_1*0.0081911713611 if id_entidad_federativa==3
replace directo_estatal_1=directo8_1*0.0015394301885 if id_entidad_federativa==4
replace directo_estatal_1=directo8_1*0.0287613150327 if id_entidad_federativa==5
replace directo_estatal_1=directo8_1*0.0093099381935 if id_entidad_federativa==6
replace directo_estatal_1=directo8_1*0.0048699176358 if id_entidad_federativa==7
replace directo_estatal_1=directo8_1*0.0387684500870 if id_entidad_federativa==8
replace directo_estatal_1=directo8_1*0.1233889328951 if id_entidad_federativa==9
replace directo_estatal_1=directo8_1*0.0125841579189 if id_entidad_federativa==10
replace directo_estatal_1=directo8_1*0.0465082165908 if id_entidad_federativa==11
replace directo_estatal_1=directo8_1*0.0085262093042 if id_entidad_federativa==12
replace directo_estatal_1=directo8_1*0.0107586181089 if id_entidad_federativa==13
replace directo_estatal_1=directo8_1*0.0925363494918 if id_entidad_federativa==14
replace directo_estatal_1=directo8_1*0.1774073437433 if id_entidad_federativa==15
replace directo_estatal_1=directo8_1*0.0358539976045 if id_entidad_federativa==16
replace directo_estatal_1=directo8_1*0.0099651804129 if id_entidad_federativa==17
replace directo_estatal_1=directo8_1*0.0078894779953 if id_entidad_federativa==18
replace directo_estatal_1=directo8_1*0.0761923595740 if id_entidad_federativa==19
replace directo_estatal_1=directo8_1*0.0072627022579 if id_entidad_federativa==20
replace directo_estatal_1=directo8_1*0.0326473914651 if id_entidad_federativa==21
replace directo_estatal_1=directo8_1*0.0322247841699 if id_entidad_federativa==22
replace directo_estatal_1=directo8_1*0.0089368282860 if id_entidad_federativa==23
replace directo_estatal_1=directo8_1*0.0202089620501 if id_entidad_federativa==24
replace directo_estatal_1=directo8_1*0.0201598080422 if id_entidad_federativa==25
replace directo_estatal_1=directo8_1*0.0288699338794 if id_entidad_federativa==26
replace directo_estatal_1=directo8_1*0.0146322594509 if id_entidad_federativa==27
replace directo_estatal_1=directo8_1*0.0284550072952 if id_entidad_federativa==28
replace directo_estatal_1=directo8_1*0.0053362308614 if id_entidad_federativa==29
replace directo_estatal_1=directo8_1*0.0322226244427 if id_entidad_federativa==30
replace directo_estatal_1=directo8_1*0.0160955149809 if id_entidad_federativa==31
replace directo_estatal_1=directo8_1*0.0096294435885 if id_entidad_federativa==32
replace directo_estatal_1=directo8_1 if id_entidad_federativa==33


*IEPS de tabaco total porestado. El total de IEPS a tabaco por estado da más en stata que en excel, creo que es por el número de decimales usados en cad aprograma*
*Total de IEPs a tabaco en estatus quo*
gen iepst_estatal_1=fgp_estatal_1+litoral_estatal_1+ffm_estatal_1+ffr_estatal_1+directo_estatal_1

*distribucion porcuental deñ IEPS de tabaco estatal*
gen piepst_estatal_1=iepst_estatal_1/16875.96 

******************************************************************************************
***************************DIFERENCIA ENTRE ESCENARIOS************************************
******************************************************************************************

gen diferencia=iepst_estatal_1-iepst_estatal

****Crecimeinto recursos a estados ieps tabaco**

gen crecimiento = (diferencia/iepst_estatal)



*******************************************************************************************************************************
*******************************************************************************************************************************
*****comprobación de que da igual aplicando porcentajes sobre el 100% del ieps a tabaco o sobre el 92% del IESPS a tabaco******
*******************************************************************************************************************************
gen fgp_estatal2=fgp2*0.0107585160227 if id_entidad_federativa==1
replace fgp_estatal2=fgp2*0.0288915444430 if id_entidad_federativa==2
replace fgp_estatal2=fgp2*0.0072419285142 if id_entidad_federativa==3
replace fgp_estatal2=fgp2*0.0085015660678 if id_entidad_federativa==4
replace fgp_estatal2=fgp2*0.0236526741849 if id_entidad_federativa==5
replace fgp_estatal2=fgp2*0.0064140545099 if id_entidad_federativa==6
replace fgp_estatal2=fgp2*0.0422198315717 if id_entidad_federativa==7
replace fgp_estatal2=fgp2*0.0296129175716 if id_entidad_federativa==8
replace fgp_estatal2=fgp2*0.1037259656181 if id_entidad_federativa==9
replace fgp_estatal2=fgp2*0.0132519395550 if id_entidad_federativa==10
replace fgp_estatal2=fgp2*0.0422268466233 if id_entidad_federativa==11
replace fgp_estatal2=fgp2*0.0249325028208 if id_entidad_federativa==12
replace fgp_estatal2=fgp2*0.0203928169811 if id_entidad_federativa==13
replace fgp_estatal2=fgp2*0.0666989893263 if id_entidad_federativa==14
replace fgp_estatal2=fgp2*0.1428315145577 if id_entidad_federativa==15
replace fgp_estatal2=fgp2*0.0314563331809 if id_entidad_federativa==16
replace fgp_estatal2=fgp2*0.0141110154385 if id_entidad_federativa==17
replace fgp_estatal2=fgp2*0.0094550425502 if id_entidad_federativa==18
replace fgp_estatal2=fgp2*0.0469641565274 if id_entidad_federativa==19
replace fgp_estatal2=fgp2*0.0284222651888 if id_entidad_federativa==20
replace fgp_estatal2=fgp2*0.0433078962108 if id_entidad_federativa==21
replace fgp_estatal2=fgp2*0.0166704410923 if id_entidad_federativa==22
replace fgp_estatal2=fgp2*0.0130890269528 if id_entidad_federativa==23
replace fgp_estatal2=fgp2*0.0200999406844 if id_entidad_federativa==24
replace fgp_estatal2=fgp2*0.0240638024133 if id_entidad_federativa==25
replace fgp_estatal2=fgp2*0.0241867453650 if id_entidad_federativa==26
replace fgp_estatal2=fgp2*0.0279043073574 if id_entidad_federativa==27
replace fgp_estatal2=fgp2*0.0284023695291 if id_entidad_federativa==28
replace fgp_estatal2=fgp2*0.0103162446320 if id_entidad_federativa==29
replace fgp_estatal2=fgp2*0.0621239174659 if id_entidad_federativa==30
replace fgp_estatal2=fgp2*0.0163565992380 if id_entidad_federativa==31
replace fgp_estatal2=fgp2*0.0117162878054 if id_entidad_federativa==32

gen dif=fgp_estatal2-fgp_estatal
tab dif


gen litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==1
replace litoral_estatal2=litoral2*0.0402154146473 if id_entidad_federativa==2
replace litoral_estatal2=litoral2*0.0001113743751 if id_entidad_federativa==3
replace litoral_estatal2=litoral2*0.0034423949129 if id_entidad_federativa==4
replace litoral_estatal2=litoral2*0.0239809005672 if id_entidad_federativa==5
replace litoral_estatal2=litoral2*0.0300253973453 if id_entidad_federativa==6
replace litoral_estatal2=litoral2*0.0014155739280 if id_entidad_federativa==7
replace litoral_estatal2=litoral2*0.0448986362204 if id_entidad_federativa==8
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==9
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==10
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==11
replace litoral_estatal2=litoral2*0.0010798030780 if id_entidad_federativa==12
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==13
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==14
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==15
replace litoral_estatal2=litoral2*0.0544506489137 if id_entidad_federativa==16
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==17
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==18
replace litoral_estatal2=litoral2*0.0149441194887 if id_entidad_federativa==19
replace litoral_estatal2=litoral2*0.0003536135798 if id_entidad_federativa==20
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==21
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==22
replace litoral_estatal2=litoral2*0.0056875932768 if id_entidad_federativa==23
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==24
replace litoral_estatal2=litoral2*0.0021751152098 if id_entidad_federativa==25
replace litoral_estatal2=litoral2*0.0532707658697 if id_entidad_federativa==26
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==27
replace litoral_estatal2=litoral2*0.6738145939427 if id_entidad_federativa==28
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==29
replace litoral_estatal2=litoral2*0.0438410743368 if id_entidad_federativa==30
replace litoral_estatal2=litoral2*0.0062929803080 if id_entidad_federativa==31
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==32



gen dif_lit=litoral_estatal2-litoral_estatal
tab dif_lit



**************/
*** Outputs ***
***************
forvalues k=1(1)32 {
	scalar DIF`k' = diferencia[`k']
	scalar IEPS`k' = iepst_estatal_1[`k']
	scalar orig`k' = iepst_estatal_1[`k']/scalar(bb_strev_1)
	scalar dif`k' = diferencia[`k']/iepst_estatal_1[`k']
}
scalar crecimiento = crecimiento[_N]


noisily di _newline(3) in g "{bf:Tabaco} output de Entidades Federativas"
quietly log using "{{ruta}}/output.txt", name(scalar) replace text
*quietly log using "outputEstados.txt", name(scalar) replace text
noisily scalar list
quietly log close scalar
