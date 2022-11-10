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
use "entidades.dta", clear

**Estatus quo**
**8% directo*
gen recaudacion=43705.9
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

*Distribucion estatal del FGP*
gen fgp_estatal=fgp*0.01076700029421730 if id_entidad_federativa==1
replace fgp_estatal=fgp*0.02890362131279060 if id_entidad_federativa==2
replace fgp_estatal=fgp*0.00740375604940551 if id_entidad_federativa==3
replace fgp_estatal=fgp*0.00837832096340734 if id_entidad_federativa==4
replace fgp_estatal=fgp*0.02350999364323120 if id_entidad_federativa==5
replace fgp_estatal=fgp*0.00636076800450475 if id_entidad_federativa==6
replace fgp_estatal=fgp*0.04230341065910850 if id_entidad_federativa==7
replace fgp_estatal=fgp*0.02955653933839560 if id_entidad_federativa==8
replace fgp_estatal=fgp*0.10314190836810100 if id_entidad_federativa==9
replace fgp_estatal=fgp*0.01324445518637260 if id_entidad_federativa==10
replace fgp_estatal=fgp*0.04198226448945720 if id_entidad_federativa==11
replace fgp_estatal=fgp*0.02518884547081950 if id_entidad_federativa==12
replace fgp_estatal=fgp*0.02042857476461370 if id_entidad_federativa==13
replace fgp_estatal=fgp*0.06688859221478890 if id_entidad_federativa==14
replace fgp_estatal=fgp*0.14357488251325900 if id_entidad_federativa==15
replace fgp_estatal=fgp*0.03122111279191700 if id_entidad_federativa==16
replace fgp_estatal=fgp*0.01388514019737930 if id_entidad_federativa==17
replace fgp_estatal=fgp*0.00935683864908112 if id_entidad_federativa==18
replace fgp_estatal=fgp*0.04704980125914350 if id_entidad_federativa==19
replace fgp_estatal=fgp*0.02916836089855590 if id_entidad_federativa==20
replace fgp_estatal=fgp*0.04287489448393210 if id_entidad_federativa==21
replace fgp_estatal=fgp*0.01669610598847810 if id_entidad_federativa==22
replace fgp_estatal=fgp*0.01317916768256060 if id_entidad_federativa==23
replace fgp_estatal=fgp*0.02013510303644500 if id_entidad_federativa==24
replace fgp_estatal=fgp*0.02413755573559770 if id_entidad_federativa==25
replace fgp_estatal=fgp*0.02406961264570650 if id_entidad_federativa==26
replace fgp_estatal=fgp*0.02712651599981280 if id_entidad_federativa==27
replace fgp_estatal=fgp*0.02847677387713900 if id_entidad_federativa==28
replace fgp_estatal=fgp*0.01045199857524940 if id_entidad_federativa==29
replace fgp_estatal=fgp*0.06248883226966220 if id_entidad_federativa==30
replace fgp_estatal=fgp*0.01641016357067100 if id_entidad_federativa==31
replace fgp_estatal=fgp*0.01163908906619660 if id_entidad_federativa==32
replace fgp_estatal=fgp if id_entidad_federativa==33


*Distribucion estatal del Litoral*
gen litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==1
replace litoral_estatal=litoral*0.040245890915715800 if id_entidad_federativa==2
replace litoral_estatal=litoral*0.000111271021064617 if id_entidad_federativa==3
replace litoral_estatal=litoral*0.003428195206685180 if id_entidad_federativa==4
replace litoral_estatal=litoral*0.023513535560319200 if id_entidad_federativa==5
replace litoral_estatal=litoral*0.029938458044567200 if id_entidad_federativa==6
replace litoral_estatal=litoral*0.001405057614494860 if id_entidad_federativa==7
replace litoral_estatal=litoral*0.044940112509589800 if id_entidad_federativa==8
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==9
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==10
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==11
replace litoral_estatal=litoral*0.001081755701649820 if id_entidad_federativa==12
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==13
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==14
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==15
replace litoral_estatal=litoral*0.054121272164285200 if id_entidad_federativa==16
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==17
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==18
replace litoral_estatal=litoral*0.014897016519773000 if id_entidad_federativa==19
replace litoral_estatal=litoral*0.000293143787221326 if id_entidad_federativa==20
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==21
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==22
replace litoral_estatal=litoral*0.005683390787146700 if id_entidad_federativa==23
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==24
replace litoral_estatal=litoral*0.002182050445238640 if id_entidad_federativa==25
replace litoral_estatal=litoral*0.053128318430014900 if id_entidad_federativa==26
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==27
replace litoral_estatal=litoral*0.674924391626463000 if id_entidad_federativa==28
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==29
replace litoral_estatal=litoral*0.043815292157395400 if id_entidad_federativa==30
replace litoral_estatal=litoral*0.006290847508374810 if id_entidad_federativa==31
replace litoral_estatal=litoral*0.000000000000000000 if id_entidad_federativa==32
replace litoral_estatal=litoral==33


*Distribucion estatal del FFM*
gen ffm_estatal=ffm*0.0199020061320101 if id_entidad_federativa==1
replace ffm_estatal=ffm*0.0177461078497576 if id_entidad_federativa==2
replace ffm_estatal=ffm*0.0066265670426604 if id_entidad_federativa==3
replace ffm_estatal=ffm*0.0109634224326502 if id_entidad_federativa==4
replace ffm_estatal=ffm*0.0183360877440299 if id_entidad_federativa==5
replace ffm_estatal=ffm*0.0104012145756705 if id_entidad_federativa==6
replace ffm_estatal=ffm*0.0274203175391842 if id_entidad_federativa==7
replace ffm_estatal=ffm*0.0273990989389714 if id_entidad_federativa==8
replace ffm_estatal=ffm*0.1112047884788920 if id_entidad_federativa==9
replace ffm_estatal=ffm*0.0208916015821877 if id_entidad_federativa==10
replace ffm_estatal=ffm*0.0517029089298817 if id_entidad_federativa==11
replace ffm_estatal=ffm*0.0202831481587892 if id_entidad_federativa==12
replace ffm_estatal=ffm*0.0386825116636494 if id_entidad_federativa==13
replace ffm_estatal=ffm*0.0534683497237953 if id_entidad_federativa==14
replace ffm_estatal=ffm*0.0954687524102461 if id_entidad_federativa==15
replace ffm_estatal=ffm*0.0431271767988834 if id_entidad_federativa==16
replace ffm_estatal=ffm*0.0179031585748993 if id_entidad_federativa==17
replace ffm_estatal=ffm*0.0162338074296282 if id_entidad_federativa==18
replace ffm_estatal=ffm*0.0304651705598415 if id_entidad_federativa==19
replace ffm_estatal=ffm*0.0418560396166077 if id_entidad_federativa==20
replace ffm_estatal=ffm*0.0477616011088755 if id_entidad_federativa==21
replace ffm_estatal=ffm*0.0212312840684291 if id_entidad_federativa==22
replace ffm_estatal=ffm*0.0150564870222785 if id_entidad_federativa==23
replace ffm_estatal=ffm*0.0256012311365339 if id_entidad_federativa==24
replace ffm_estatal=ffm*0.0201527860242089 if id_entidad_federativa==25
replace ffm_estatal=ffm*0.0150732029156370 if id_entidad_federativa==26
replace ffm_estatal=ffm*0.0257030757866259 if id_entidad_federativa==27
replace ffm_estatal=ffm*0.0287710442558891 if id_entidad_federativa==28
replace ffm_estatal=ffm*0.0147376493580124 if id_entidad_federativa==29
replace ffm_estatal=ffm*0.0473185325846410 if id_entidad_federativa==30
replace ffm_estatal=ffm*0.0288763658564214 if id_entidad_federativa==31
replace ffm_estatal=ffm*0.0296345037002119 if id_entidad_federativa==32
replace ffm_estatal=ffm if id_entidad_federativa==33


*Distribucion estatal del FFR*
gen ffr_estatal=ffr*0.0090794726334591 if id_entidad_federativa==1
replace ffr_estatal=ffr*0.0283419120876812 if id_entidad_federativa==2
replace ffr_estatal=ffr*0.0057390832377983 if id_entidad_federativa==3
replace ffr_estatal=ffr*0.0061988711124025 if id_entidad_federativa==4
replace ffr_estatal=ffr*0.0197494002689587 if id_entidad_federativa==5
replace ffr_estatal=ffr*0.0049876485481483 if id_entidad_federativa==6
replace ffr_estatal=ffr*0.0346362674714879 if id_entidad_federativa==7
replace ffr_estatal=ffr*0.0285323441600882 if id_entidad_federativa==8
replace ffr_estatal=ffr*0.0868993391590992 if id_entidad_federativa==9
replace ffr_estatal=ffr*0.0127622878422367 if id_entidad_federativa==10
replace ffr_estatal=ffr*0.0497734183836176 if id_entidad_federativa==11
replace ffr_estatal=ffr*0.0172886175307079 if id_entidad_federativa==12
replace ffr_estatal=ffr*0.0150602488479604 if id_entidad_federativa==13
replace ffr_estatal=ffr*0.0533093460760292 if id_entidad_federativa==14
replace ffr_estatal=ffr*0.1181094869847260 if id_entidad_federativa==15
replace ffr_estatal=ffr*0.0238336182586507 if id_entidad_federativa==16
replace ffr_estatal=ffr*0.0106657662512522 if id_entidad_federativa==17
replace ffr_estatal=ffr*0.0079403923979941 if id_entidad_federativa==18
replace ffr_estatal=ffr*0.0374772503295340 if id_entidad_federativa==19
replace ffr_estatal=ffr*0.0211730446477350 if id_entidad_federativa==20
replace ffr_estatal=ffr*0.0353335323326975 if id_entidad_federativa==21
replace ffr_estatal=ffr*0.0165823512956907 if id_entidad_federativa==22
replace ffr_estatal=ffr*0.0128739683886724 if id_entidad_federativa==23
replace ffr_estatal=ffr*0.0229762141551709 if id_entidad_federativa==24
replace ffr_estatal=ffr*0.0504933045753131 if id_entidad_federativa==25
replace ffr_estatal=ffr*0.1020466573874740 if id_entidad_federativa==26
replace ffr_estatal=ffr*0.0523264581907622 if id_entidad_federativa==27
replace ffr_estatal=ffr*0.0224494501951703 if id_entidad_federativa==28
replace ffr_estatal=ffr*0.0121322243571944 if id_entidad_federativa==29
replace ffr_estatal=ffr*0.0433714345287250 if id_entidad_federativa==30
replace ffr_estatal=ffr*0.0289002853621128 if id_entidad_federativa==31
replace ffr_estatal=ffr*0.0089563030014504 if id_entidad_federativa==32
replace ffr_estatal=ffr if id_entidad_federativa==33


*Distribucion estatal del 8% directo*
gen directo_estatal=directo8*0.0122452324366864 if id_entidad_federativa==1
replace directo_estatal=directo8*0.0358961728360057 if id_entidad_federativa==2
replace directo_estatal=directo8*0.0077456654964782 if id_entidad_federativa==3
replace directo_estatal=directo8*0.0014658417262442 if id_entidad_federativa==4
replace directo_estatal=directo8*0.0280808403599009 if id_entidad_federativa==5
replace directo_estatal=directo8*0.0109350982186878 if id_entidad_federativa==6
replace directo_estatal=directo8*0.0049749550477096 if id_entidad_federativa==7
replace directo_estatal=directo8*0.0379864215623494 if id_entidad_federativa==8
replace directo_estatal=directo8*0.1352405869504410 if id_entidad_federativa==9
replace directo_estatal=directo8*0.0127148329038606 if id_entidad_federativa==10
replace directo_estatal=directo8*0.0458274942134046 if id_entidad_federativa==11
replace directo_estatal=directo8*0.0085081686304987 if id_entidad_federativa==12
replace directo_estatal=directo8*0.0106287276339990 if id_entidad_federativa==13
replace directo_estatal=directo8*0.0915216506397622 if id_entidad_federativa==14
replace directo_estatal=directo8*0.1685273736436770 if id_entidad_federativa==15
replace directo_estatal=directo8*0.0352124098169224 if id_entidad_federativa==16
replace directo_estatal=directo8*0.0099397251426972 if id_entidad_federativa==17
replace directo_estatal=directo8*0.0080461070714707 if id_entidad_federativa==18
replace directo_estatal=directo8*0.0744719498936904 if id_entidad_federativa==19
replace directo_estatal=directo8*0.0075144367738251 if id_entidad_federativa==20
replace directo_estatal=directo8*0.0323451605338800 if id_entidad_federativa==21
replace directo_estatal=directo8*0.0335054029248512 if id_entidad_federativa==22
replace directo_estatal=directo8*0.0097291695429373 if id_entidad_federativa==23
replace directo_estatal=directo8*0.0199132722195797 if id_entidad_federativa==24
replace directo_estatal=directo8*0.0194487885101588 if id_entidad_federativa==25
replace directo_estatal=directo8*0.0301645775606440 if id_entidad_federativa==26
replace directo_estatal=directo8*0.0142298729705228 if id_entidad_federativa==27
replace directo_estatal=directo8*0.0275762991128741 if id_entidad_federativa==28
replace directo_estatal=directo8*0.0052622550581433 if id_entidad_federativa==29
replace directo_estatal=directo8*0.0357962132930702 if id_entidad_federativa==30
replace directo_estatal=directo8*0.0142130754523216 if id_entidad_federativa==31
replace directo_estatal=directo8*0.0103322218227060 if id_entidad_federativa==32
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

*\el 92% restante de IEPS a tabaco se distribuye segÃºn los porcentajes de la LCF; en la nota metodolÃ³fica se ponen los porcentajes sobre el total de IEPS a tabaco*/
gen ieps92_1=recaudacion_1*0.92

gen fgp_1=ieps92_1*0.2
gen fgp2_1=recaudacion_1*0.184
gen litoral_1=ieps92_1*0.00136
gen litoral2_1=recaudacion_1*0.001256
gen ffm_1=ieps92_1*0.01
gen ffr_1=ieps92_1*0.0125


*Distribucion estatal del FGP*
gen fgp_estatal_1=fgp_1*0.01076700029421730 if id_entidad_federativa==1
replace fgp_estatal_1=fgp_1*0.02890362131279060 if id_entidad_federativa==2
replace fgp_estatal_1=fgp_1*0.00740375604940551 if id_entidad_federativa==3
replace fgp_estatal_1=fgp_1*0.00837832096340734 if id_entidad_federativa==4
replace fgp_estatal_1=fgp_1*0.02350999364323120 if id_entidad_federativa==5
replace fgp_estatal_1=fgp_1*0.00636076800450475 if id_entidad_federativa==6
replace fgp_estatal_1=fgp_1*0.04230341065910850 if id_entidad_federativa==7
replace fgp_estatal_1=fgp_1*0.02955653933839560 if id_entidad_federativa==8
replace fgp_estatal_1=fgp_1*0.10314190836810100 if id_entidad_federativa==9
replace fgp_estatal_1=fgp_1*0.01324445518637260 if id_entidad_federativa==10
replace fgp_estatal_1=fgp_1*0.04198226448945720 if id_entidad_federativa==11
replace fgp_estatal_1=fgp_1*0.02518884547081950 if id_entidad_federativa==12
replace fgp_estatal_1=fgp_1*0.02042857476461370 if id_entidad_federativa==13
replace fgp_estatal_1=fgp_1*0.06688859221478890 if id_entidad_federativa==14
replace fgp_estatal_1=fgp_1*0.14357488251325900 if id_entidad_federativa==15
replace fgp_estatal_1=fgp_1*0.03122111279191700 if id_entidad_federativa==16
replace fgp_estatal_1=fgp_1*0.01388514019737930 if id_entidad_federativa==17
replace fgp_estatal_1=fgp_1*0.00935683864908112 if id_entidad_federativa==18
replace fgp_estatal_1=fgp_1*0.04704980125914350 if id_entidad_federativa==19
replace fgp_estatal_1=fgp_1*0.02916836089855590 if id_entidad_federativa==20
replace fgp_estatal_1=fgp_1*0.04287489448393210 if id_entidad_federativa==21
replace fgp_estatal_1=fgp_1*0.01669610598847810 if id_entidad_federativa==22
replace fgp_estatal_1=fgp_1*0.01317916768256060 if id_entidad_federativa==23
replace fgp_estatal_1=fgp_1*0.02013510303644500 if id_entidad_federativa==24
replace fgp_estatal_1=fgp_1*0.02413755573559770 if id_entidad_federativa==25
replace fgp_estatal_1=fgp_1*0.02406961264570650 if id_entidad_federativa==26
replace fgp_estatal_1=fgp_1*0.02712651599981280 if id_entidad_federativa==27
replace fgp_estatal_1=fgp_1*0.02847677387713900 if id_entidad_federativa==28
replace fgp_estatal_1=fgp_1*0.01045199857524940 if id_entidad_federativa==29
replace fgp_estatal_1=fgp_1*0.06248883226966220 if id_entidad_federativa==30
replace fgp_estatal_1=fgp_1*0.01641016357067100 if id_entidad_federativa==31
replace fgp_estatal_1=fgp_1*0.01163908906619660 if id_entidad_federativa==32
replace fgp_estatal_1=fgp_1 if id_entidad_federativa==33


*Distribucion estatal del Litoral*
gen litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==1
replace litoral_estatal_1=litoral_1*0.040245890915715800 if id_entidad_federativa==2
replace litoral_estatal_1=litoral_1*0.000111271021064617 if id_entidad_federativa==3
replace litoral_estatal_1=litoral_1*0.003428195206685180 if id_entidad_federativa==4
replace litoral_estatal_1=litoral_1*0.023513535560319200 if id_entidad_federativa==5
replace litoral_estatal_1=litoral_1*0.029938458044567200 if id_entidad_federativa==6
replace litoral_estatal_1=litoral_1*0.001405057614494860 if id_entidad_federativa==7
replace litoral_estatal_1=litoral_1*0.044940112509589800 if id_entidad_federativa==8
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==9
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==10
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==11
replace litoral_estatal_1=litoral_1*0.001081755701649820 if id_entidad_federativa==12
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==13
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==14
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==15
replace litoral_estatal_1=litoral_1*0.054121272164285200 if id_entidad_federativa==16
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==17
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==18
replace litoral_estatal_1=litoral_1*0.014897016519773000 if id_entidad_federativa==19
replace litoral_estatal_1=litoral_1*0.000293143787221326 if id_entidad_federativa==20
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==21
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==22
replace litoral_estatal_1=litoral_1*0.005683390787146700 if id_entidad_federativa==23
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==24
replace litoral_estatal_1=litoral_1*0.002182050445238640 if id_entidad_federativa==25
replace litoral_estatal_1=litoral_1*0.053128318430014900 if id_entidad_federativa==26
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==27
replace litoral_estatal_1=litoral_1*0.674924391626463000 if id_entidad_federativa==28
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==29
replace litoral_estatal_1=litoral_1*0.043815292157395400 if id_entidad_federativa==30
replace litoral_estatal_1=litoral_1*0.006290847508374810 if id_entidad_federativa==31
replace litoral_estatal_1=litoral_1*0.000000000000000000 if id_entidad_federativa==32
replace litoral_estatal_1=litoral_1 if id_entidad_federativa==33


*Distribucion estatal del FFM*
gen ffm_estatal_1=ffm_1*0.0199020061320101 if id_entidad_federativa==1
replace ffm_estatal_1=ffm_1*0.0177461078497576 if id_entidad_federativa==2
replace ffm_estatal_1=ffm_1*0.0066265670426604 if id_entidad_federativa==3
replace ffm_estatal_1=ffm_1*0.0109634224326502 if id_entidad_federativa==4
replace ffm_estatal_1=ffm_1*0.0183360877440299 if id_entidad_federativa==5
replace ffm_estatal_1=ffm_1*0.0104012145756705 if id_entidad_federativa==6
replace ffm_estatal_1=ffm_1*0.0274203175391842 if id_entidad_federativa==7
replace ffm_estatal_1=ffm_1*0.0273990989389714 if id_entidad_federativa==8
replace ffm_estatal_1=ffm_1*0.1112047884788920 if id_entidad_federativa==9
replace ffm_estatal_1=ffm_1*0.0208916015821877 if id_entidad_federativa==10
replace ffm_estatal_1=ffm_1*0.0517029089298817 if id_entidad_federativa==11
replace ffm_estatal_1=ffm_1*0.0202831481587892 if id_entidad_federativa==12
replace ffm_estatal_1=ffm_1*0.0386825116636494 if id_entidad_federativa==13
replace ffm_estatal_1=ffm_1*0.0534683497237953 if id_entidad_federativa==14
replace ffm_estatal_1=ffm_1*0.0954687524102461 if id_entidad_federativa==15
replace ffm_estatal_1=ffm_1*0.0431271767988834 if id_entidad_federativa==16
replace ffm_estatal_1=ffm_1*0.0179031585748993 if id_entidad_federativa==17
replace ffm_estatal_1=ffm_1*0.0162338074296282 if id_entidad_federativa==18
replace ffm_estatal_1=ffm_1*0.0304651705598415 if id_entidad_federativa==19
replace ffm_estatal_1=ffm_1*0.0418560396166077 if id_entidad_federativa==20
replace ffm_estatal_1=ffm_1*0.0477616011088755 if id_entidad_federativa==21
replace ffm_estatal_1=ffm_1*0.0212312840684291 if id_entidad_federativa==22
replace ffm_estatal_1=ffm_1*0.0150564870222785 if id_entidad_federativa==23
replace ffm_estatal_1=ffm_1*0.0256012311365339 if id_entidad_federativa==24
replace ffm_estatal_1=ffm_1*0.0201527860242089 if id_entidad_federativa==25
replace ffm_estatal_1=ffm_1*0.0150732029156370 if id_entidad_federativa==26
replace ffm_estatal_1=ffm_1*0.0257030757866259 if id_entidad_federativa==27
replace ffm_estatal_1=ffm_1*0.0287710442558891 if id_entidad_federativa==28
replace ffm_estatal_1=ffm_1*0.0147376493580124 if id_entidad_federativa==29
replace ffm_estatal_1=ffm_1*0.0473185325846410 if id_entidad_federativa==30
replace ffm_estatal_1=ffm_1*0.0288763658564214 if id_entidad_federativa==31
replace ffm_estatal_1=ffm_1*0.0296345037002119 if id_entidad_federativa==32
replace ffm_estatal_1=ffm_1 if id_entidad_federativa==33


*Distribucion estatal del FFR*
gen ffr_estatal_1=ffr_1*0.0090794726334591 if id_entidad_federativa==1
replace ffr_estatal_1=ffr_1*0.0283419120876812 if id_entidad_federativa==2
replace ffr_estatal_1=ffr_1*0.0057390832377983 if id_entidad_federativa==3
replace ffr_estatal_1=ffr_1*0.0061988711124025 if id_entidad_federativa==4
replace ffr_estatal_1=ffr_1*0.0197494002689587 if id_entidad_federativa==5
replace ffr_estatal_1=ffr_1*0.0049876485481483 if id_entidad_federativa==6
replace ffr_estatal_1=ffr_1*0.0346362674714879 if id_entidad_federativa==7
replace ffr_estatal_1=ffr_1*0.0285323441600882 if id_entidad_federativa==8
replace ffr_estatal_1=ffr_1*0.0868993391590992 if id_entidad_federativa==9
replace ffr_estatal_1=ffr_1*0.0127622878422367 if id_entidad_federativa==10
replace ffr_estatal_1=ffr_1*0.0497734183836176 if id_entidad_federativa==11
replace ffr_estatal_1=ffr_1*0.0172886175307079 if id_entidad_federativa==12
replace ffr_estatal_1=ffr_1*0.0150602488479604 if id_entidad_federativa==13
replace ffr_estatal_1=ffr_1*0.0533093460760292 if id_entidad_federativa==14
replace ffr_estatal_1=ffr_1*0.1181094869847260 if id_entidad_federativa==15
replace ffr_estatal_1=ffr_1*0.0238336182586507 if id_entidad_federativa==16
replace ffr_estatal_1=ffr_1*0.0106657662512522 if id_entidad_federativa==17
replace ffr_estatal_1=ffr_1*0.0079403923979941 if id_entidad_federativa==18
replace ffr_estatal_1=ffr_1*0.0374772503295340 if id_entidad_federativa==19
replace ffr_estatal_1=ffr_1*0.0211730446477350 if id_entidad_federativa==20
replace ffr_estatal_1=ffr_1*0.0353335323326975 if id_entidad_federativa==21
replace ffr_estatal_1=ffr_1*0.0165823512956907 if id_entidad_federativa==22
replace ffr_estatal_1=ffr_1*0.0128739683886724 if id_entidad_federativa==23
replace ffr_estatal_1=ffr_1*0.0229762141551709 if id_entidad_federativa==24
replace ffr_estatal_1=ffr_1*0.0504933045753131 if id_entidad_federativa==25
replace ffr_estatal_1=ffr_1*0.1020466573874740 if id_entidad_federativa==26
replace ffr_estatal_1=ffr_1*0.0523264581907622 if id_entidad_federativa==27
replace ffr_estatal_1=ffr_1*0.0224494501951703 if id_entidad_federativa==28
replace ffr_estatal_1=ffr_1*0.0121322243571944 if id_entidad_federativa==29
replace ffr_estatal_1=ffr_1*0.0433714345287250 if id_entidad_federativa==30
replace ffr_estatal_1=ffr_1*0.0289002853621128 if id_entidad_federativa==31
replace ffr_estatal_1=ffr_1*0.0089563030014504 if id_entidad_federativa==32
replace ffr_estatal_1=ffr_1 if id_entidad_federativa==33


*Distribucion estatal del 8% directo*
gen directo_estatal_1=directo8_1*0.0122452324366864 if id_entidad_federativa==1
replace directo_estatal_1=directo8_1*0.0358961728360057 if id_entidad_federativa==2
replace directo_estatal_1=directo8_1*0.0077456654964782 if id_entidad_federativa==3
replace directo_estatal_1=directo8_1*0.0014658417262442 if id_entidad_federativa==4
replace directo_estatal_1=directo8_1*0.0280808403599009 if id_entidad_federativa==5
replace directo_estatal_1=directo8_1*0.0109350982186878 if id_entidad_federativa==6
replace directo_estatal_1=directo8_1*0.0049749550477096 if id_entidad_federativa==7
replace directo_estatal_1=directo8_1*0.0379864215623494 if id_entidad_federativa==8
replace directo_estatal_1=directo8_1*0.1352405869504410 if id_entidad_federativa==9
replace directo_estatal_1=directo8_1*0.0127148329038606 if id_entidad_federativa==10
replace directo_estatal_1=directo8_1*0.0458274942134046 if id_entidad_federativa==11
replace directo_estatal_1=directo8_1*0.0085081686304987 if id_entidad_federativa==12
replace directo_estatal_1=directo8_1*0.0106287276339990 if id_entidad_federativa==13
replace directo_estatal_1=directo8_1*0.0915216506397622 if id_entidad_federativa==14
replace directo_estatal_1=directo8_1*0.1685273736436770 if id_entidad_federativa==15
replace directo_estatal_1=directo8_1*0.0352124098169224 if id_entidad_federativa==16
replace directo_estatal_1=directo8_1*0.0099397251426972 if id_entidad_federativa==17
replace directo_estatal_1=directo8_1*0.0080461070714707 if id_entidad_federativa==18
replace directo_estatal_1=directo8_1*0.0744719498936904 if id_entidad_federativa==19
replace directo_estatal_1=directo8_1*0.0075144367738251 if id_entidad_federativa==20
replace directo_estatal_1=directo8_1*0.0323451605338800 if id_entidad_federativa==21
replace directo_estatal_1=directo8_1*0.0335054029248512 if id_entidad_federativa==22
replace directo_estatal_1=directo8_1*0.0097291695429373 if id_entidad_federativa==23
replace directo_estatal_1=directo8_1*0.0199132722195797 if id_entidad_federativa==24
replace directo_estatal_1=directo8_1*0.0194487885101588 if id_entidad_federativa==25
replace directo_estatal_1=directo8_1*0.0301645775606440 if id_entidad_federativa==26
replace directo_estatal_1=directo8_1*0.0142298729705228 if id_entidad_federativa==27
replace directo_estatal_1=directo8_1*0.0275762991128741 if id_entidad_federativa==28
replace directo_estatal_1=directo8_1*0.0052622550581433 if id_entidad_federativa==29
replace directo_estatal_1=directo8_1*0.0357962132930702 if id_entidad_federativa==30
replace directo_estatal_1=directo8_1*0.0142130754523216 if id_entidad_federativa==31
replace directo_estatal_1=directo8_1*0.0103322218227060 if id_entidad_federativa==32
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
gen fgp_estatal2=fgp2*0.01076700029421730 if id_entidad_federativa==1
replace fgp_estatal2=fgp2*0.02890362131279060 if id_entidad_federativa==2
replace fgp_estatal2=fgp2*0.00740375604940551 if id_entidad_federativa==3
replace fgp_estatal2=fgp2*0.00837832096340734 if id_entidad_federativa==4
replace fgp_estatal2=fgp2*0.02350999364323120 if id_entidad_federativa==5
replace fgp_estatal2=fgp2*0.00636076800450475 if id_entidad_federativa==6
replace fgp_estatal2=fgp2*0.04230341065910850 if id_entidad_federativa==7
replace fgp_estatal2=fgp2*0.02955653933839560 if id_entidad_federativa==8
replace fgp_estatal2=fgp2*0.10314190836810100 if id_entidad_federativa==9
replace fgp_estatal2=fgp2*0.01324445518637260 if id_entidad_federativa==10
replace fgp_estatal2=fgp2*0.04198226448945720 if id_entidad_federativa==11
replace fgp_estatal2=fgp2*0.02518884547081950 if id_entidad_federativa==12
replace fgp_estatal2=fgp2*0.02042857476461370 if id_entidad_federativa==13
replace fgp_estatal2=fgp2*0.06688859221478890 if id_entidad_federativa==14
replace fgp_estatal2=fgp2*0.14357488251325900 if id_entidad_federativa==15
replace fgp_estatal2=fgp2*0.03122111279191700 if id_entidad_federativa==16
replace fgp_estatal2=fgp2*0.01388514019737930 if id_entidad_federativa==17
replace fgp_estatal2=fgp2*0.00935683864908112 if id_entidad_federativa==18
replace fgp_estatal2=fgp2*0.04704980125914350 if id_entidad_federativa==19
replace fgp_estatal2=fgp2*0.02916836089855590 if id_entidad_federativa==20
replace fgp_estatal2=fgp2*0.04287489448393210 if id_entidad_federativa==21
replace fgp_estatal2=fgp2*0.01669610598847810 if id_entidad_federativa==22
replace fgp_estatal2=fgp2*0.01317916768256060 if id_entidad_federativa==23
replace fgp_estatal2=fgp2*0.02013510303644500 if id_entidad_federativa==24
replace fgp_estatal2=fgp2*0.02413755573559770 if id_entidad_federativa==25
replace fgp_estatal2=fgp2*0.02406961264570650 if id_entidad_federativa==26
replace fgp_estatal2=fgp2*0.02712651599981280 if id_entidad_federativa==27
replace fgp_estatal2=fgp2*0.02847677387713900 if id_entidad_federativa==28
replace fgp_estatal2=fgp2*0.01045199857524940 if id_entidad_federativa==29
replace fgp_estatal2=fgp2*0.06248883226966220 if id_entidad_federativa==30
replace fgp_estatal2=fgp2*0.01641016357067100 if id_entidad_federativa==31
replace fgp_estatal2=fgp2*0.01163908906619660 if id_entidad_federativa==32

gen dif=fgp_estatal2-fgp_estatal
tab dif


gen litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==1
replace litoral_estatal2=litoral2*0.040245890915715800 if id_entidad_federativa==2
replace litoral_estatal2=litoral2*0.000111271021064617 if id_entidad_federativa==3
replace litoral_estatal2=litoral2*0.003428195206685180 if id_entidad_federativa==4
replace litoral_estatal2=litoral2*0.023513535560319200 if id_entidad_federativa==5
replace litoral_estatal2=litoral2*0.029938458044567200 if id_entidad_federativa==6
replace litoral_estatal2=litoral2*0.001405057614494860 if id_entidad_federativa==7
replace litoral_estatal2=litoral2*0.044940112509589800 if id_entidad_federativa==8
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==9
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==10
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==11
replace litoral_estatal2=litoral2*0.001081755701649820 if id_entidad_federativa==12
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==13
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==14
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==15
replace litoral_estatal2=litoral2*0.054121272164285200 if id_entidad_federativa==16
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==17
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==18
replace litoral_estatal2=litoral2*0.014897016519773000 if id_entidad_federativa==19
replace litoral_estatal2=litoral2*0.000293143787221326 if id_entidad_federativa==20
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==21
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==22
replace litoral_estatal2=litoral2*0.005683390787146700 if id_entidad_federativa==23
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==24
replace litoral_estatal2=litoral2*0.002182050445238640 if id_entidad_federativa==25
replace litoral_estatal2=litoral2*0.053128318430014900 if id_entidad_federativa==26
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==27
replace litoral_estatal2=litoral2*0.674924391626463000 if id_entidad_federativa==28
replace litoral_estatal2=litoral2*0.000000000000000000 if id_entidad_federativa==29
replace litoral_estatal2=litoral2*0.043815292157395400 if id_entidad_federativa==30
replace litoral_estatal2=litoral2*0.006290847508374810 if id_entidad_federativa==31
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
