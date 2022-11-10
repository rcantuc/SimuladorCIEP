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
gen recaudacion=46103.1
gen directo8=recaudacion*0.08

/*el 92% restante de IEPS a tabaco se distribuye según los porcentajes de la LCF; en la nota metodolófica se ponen los porcentajes sobre el total de IEPS a tabaco*/
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
gen fgp_estatal=fgp*0.010415092 if id_entidad_federativa==1
replace fgp_estatal=fgp*0.029213247 if id_entidad_federativa==2
replace fgp_estatal=fgp*0.006399679	if id_entidad_federativa==3
replace fgp_estatal=fgp*0.008198814	if id_entidad_federativa==4
replace fgp_estatal=fgp*0.023637259	if id_entidad_federativa==5
replace fgp_estatal=fgp*0.006296334	if id_entidad_federativa==6
replace fgp_estatal=fgp*0.041100072	if id_entidad_federativa==7
replace fgp_estatal=fgp*0.030198311	if id_entidad_federativa==8
replace fgp_estatal=fgp*0.097397447	if id_entidad_federativa==9
replace fgp_estatal=fgp*0.013487303	if id_entidad_federativa==10
replace fgp_estatal=fgp*0.043723592	if id_entidad_federativa==11
replace fgp_estatal=fgp*0.025445621	if id_entidad_federativa==12
replace fgp_estatal=fgp*0.020690465	if id_entidad_federativa==13
replace fgp_estatal=fgp*0.067150113	if id_entidad_federativa==14
replace fgp_estatal=fgp*0.146691278	if id_entidad_federativa==15
replace fgp_estatal=fgp*0.033221129	if id_entidad_federativa==16
replace fgp_estatal=fgp*0.014543924	if id_entidad_federativa==17
replace fgp_estatal=fgp*0.009653377	if id_entidad_federativa==18
replace fgp_estatal=fgp*0.046645771	if id_entidad_federativa==19
replace fgp_estatal=fgp*0.027515889	if id_entidad_federativa==20
replace fgp_estatal=fgp*0.045597904	if id_entidad_federativa==21
replace fgp_estatal=fgp*0.016501715	if id_entidad_federativa==22
replace fgp_estatal=fgp*0.013373973	if id_entidad_federativa==23
replace fgp_estatal=fgp*0.020425782	if id_entidad_federativa==24
replace fgp_estatal=fgp*0.024129168	if id_entidad_federativa==25
replace fgp_estatal=fgp*0.023966284	if id_entidad_federativa==26
replace fgp_estatal=fgp*0.024741582	if id_entidad_federativa==27
replace fgp_estatal=fgp*0.028714086	if id_entidad_federativa==28
replace fgp_estatal=fgp*0.010174306	if id_entidad_federativa==29
replace fgp_estatal=fgp*0.062439355	if id_entidad_federativa==30
replace fgp_estatal=fgp*0.016529602	if id_entidad_federativa==31
replace fgp_estatal=fgp*0.011781524	if id_entidad_federativa==32
replace fgp_estatal=fgp if id_entidad_federativa==33				



*Distribucion estatal del Litoral*
gen	litoral_estatal=litoral*0 if id_entidad_federativa==1
replace	litoral_estatal=litoral*0.043180757 if id_entidad_federativa==2
replace	litoral_estatal=litoral*0.00008248 if id_entidad_federativa==3
replace	litoral_estatal=litoral*0.00324995 if id_entidad_federativa==4
replace	litoral_estatal=litoral*0.028225159 if id_entidad_federativa==5
replace	litoral_estatal=litoral*0.028892594 if id_entidad_federativa==6
replace	litoral_estatal=litoral*0.001250446 if id_entidad_federativa==7
replace	litoral_estatal=litoral*0.043336983 if id_entidad_federativa==8
replace	litoral_estatal=litoral*0 if id_entidad_federativa==9
replace	litoral_estatal=litoral*0 if id_entidad_federativa==10
replace	litoral_estatal=litoral*0 if id_entidad_federativa==11
replace	litoral_estatal=litoral*0.000905081 if id_entidad_federativa==12
replace	litoral_estatal=litoral*0 if id_entidad_federativa==13
replace	litoral_estatal=litoral*0 if id_entidad_federativa==14
replace	litoral_estatal=litoral*0 if id_entidad_federativa==15
replace	litoral_estatal=litoral*0.055702781 if id_entidad_federativa==16
replace	litoral_estatal=litoral*0 if id_entidad_federativa==17
replace	litoral_estatal=litoral*0 if id_entidad_federativa==18
replace	litoral_estatal=litoral*0.015366739 if id_entidad_federativa==19
replace	litoral_estatal=litoral*0.000667719 if id_entidad_federativa==20
replace	litoral_estatal=litoral*0 if id_entidad_federativa==21
replace	litoral_estatal=litoral*0 if id_entidad_federativa==22
replace	litoral_estatal=litoral*0.00500957 if id_entidad_federativa==23
replace	litoral_estatal=litoral*0 if id_entidad_federativa==24
replace	litoral_estatal=litoral*0.002142596 if id_entidad_federativa==25
replace	litoral_estatal=litoral*0.051439929 if id_entidad_federativa==26
replace	litoral_estatal=litoral*0 if id_entidad_federativa==27
replace	litoral_estatal=litoral*0.666664947 if id_entidad_federativa==28
replace	litoral_estatal=litoral*0 if id_entidad_federativa==29
replace	litoral_estatal=litoral*0.048302646 if id_entidad_federativa==30
replace	litoral_estatal=litoral*0.005579622 if id_entidad_federativa==31
replace	litoral_estatal=litoral*0 if id_entidad_federativa==32
replace	litoral_estatal=litoral==33				



*Distribucion estatal del FFM*
gen	ffm_estatal=ffm*0.016097587 if id_entidad_federativa==1
replace	ffm_estatal=ffm*0.020977931 if id_entidad_federativa==2
replace	ffm_estatal=ffm*0.005408319 if id_entidad_federativa==3
replace	ffm_estatal=ffm*0.009991479 if id_entidad_federativa==4
replace	ffm_estatal=ffm*0.021326273 if id_entidad_federativa==5
replace	ffm_estatal=ffm*0.007507657	if id_entidad_federativa==6
replace	ffm_estatal=ffm*0.031998725	if id_entidad_federativa==7
replace	ffm_estatal=ffm*0.033471639	if id_entidad_federativa==8
replace	ffm_estatal=ffm*0.103066903	if id_entidad_federativa==9
replace	ffm_estatal=ffm*0.019914436 if id_entidad_federativa==10
replace	ffm_estatal=ffm*0.053854938	if id_entidad_federativa==11
replace	ffm_estatal=ffm*0.021223116	if id_entidad_federativa==12
replace	ffm_estatal=ffm*0.028374063	if id_entidad_federativa==13
replace	ffm_estatal=ffm*0.070864761	if id_entidad_federativa==14
replace	ffm_estatal=ffm*0.124199603	if id_entidad_federativa==15
replace	ffm_estatal=ffm*0.03676094 if id_entidad_federativa==16
replace	ffm_estatal=ffm*0.015535293	if id_entidad_federativa==17
replace	ffm_estatal=ffm*0.011774939	if id_entidad_federativa==18
replace	ffm_estatal=ffm*0.042544251	if id_entidad_federativa==19
replace	ffm_estatal=ffm*0.03593734 if id_entidad_federativa==20
replace	ffm_estatal=ffm*0.041099658	if id_entidad_federativa==21
replace	ffm_estatal=ffm*0.018101939	if id_entidad_federativa==22
replace	ffm_estatal=ffm*0.012067467	if id_entidad_federativa==23
replace	ffm_estatal=ffm*0.022263471	if id_entidad_federativa==24
replace	ffm_estatal=ffm*0.028267595	if id_entidad_federativa==25
replace	ffm_estatal=ffm*0.016584538	if id_entidad_federativa==26
replace	ffm_estatal=ffm*0.020868328	if id_entidad_federativa==27
replace	ffm_estatal=ffm*0.026895047	if id_entidad_federativa==28
replace	ffm_estatal=ffm*0.01090285 if id_entidad_federativa==29
replace	ffm_estatal=ffm*0.047443441	if id_entidad_federativa==30
replace	ffm_estatal=ffm*0.024450218	if id_entidad_federativa==31
replace	ffm_estatal=ffm*0.020225253	if id_entidad_federativa==32
replace	ffm_estatal=ffm if id_entidad_federativa==33	



*Distribucion estatal del FFR*
gen	ffr_estatal=ffr*0.01110333	if id_entidad_federativa==1
replace	ffr_estatal=ffr*0.02985734	if id_entidad_federativa==2
replace	ffr_estatal=ffr*0.00755154	if id_entidad_federativa==3
replace	ffr_estatal=ffr*0.00483538	if id_entidad_federativa==4
replace	ffr_estatal=ffr*0.01812321	if id_entidad_federativa==5
replace	ffr_estatal=ffr*0.00475466	if id_entidad_federativa==6
replace	ffr_estatal=ffr*0.02679803	if id_entidad_federativa==7
replace	ffr_estatal=ffr*0.06287215	if id_entidad_federativa==8
replace	ffr_estatal=ffr*0.07144742	if id_entidad_federativa==9
replace	ffr_estatal=ffr*0.01048534	if id_entidad_federativa==10
replace	ffr_estatal=ffr*0.06042430	if id_entidad_federativa==11
replace	ffr_estatal=ffr*0.01477110	if id_entidad_federativa==12
replace	ffr_estatal=ffr*0.01372552	if id_entidad_federativa==13
replace	ffr_estatal=ffr*0.05125473	if id_entidad_federativa==14
replace	ffr_estatal=ffr*0.13551573	if id_entidad_federativa==15
replace	ffr_estatal=ffr*0.02507843	if id_entidad_federativa==16
replace	ffr_estatal=ffr*0.00995844	if id_entidad_federativa==17
replace	ffr_estatal=ffr*0.00557749	if id_entidad_federativa==18
replace	ffr_estatal=ffr*0.05750479	if id_entidad_federativa==19
replace	ffr_estatal=ffr*0.02486404	if id_entidad_federativa==20
replace	ffr_estatal=ffr*0.03594476	if id_entidad_federativa==21
replace	ffr_estatal=ffr*0.03516703	if id_entidad_federativa==22
replace	ffr_estatal=ffr*0.01787220	if id_entidad_federativa==23
replace	ffr_estatal=ffr*0.02105565	if id_entidad_federativa==24
replace	ffr_estatal=ffr*0.04577002	if id_entidad_federativa==25
replace	ffr_estatal=ffr*0.07824077	if id_entidad_federativa==26
replace	ffr_estatal=ffr*0.02250123	if id_entidad_federativa==27
replace	ffr_estatal=ffr*0.02286466	if id_entidad_federativa==28
replace	ffr_estatal=ffr*0.00669038	if id_entidad_federativa==29
replace	ffr_estatal=ffr*0.03702698	if id_entidad_federativa==30
replace	ffr_estatal=ffr*0.02056064	if id_entidad_federativa==31
replace	ffr_estatal=ffr*0.00980269	if id_entidad_federativa==32
replace	ffr_estatal=ffr if id_entidad_federativa==33
	

*Distribucion estatal del 8% directo*
gen	directo_estatal=directo8*0.02807156	 if id_entidad_federativa==1	
replace	directo_estatal=directo8*0.06404072	 if id_entidad_federativa==2	
replace	directo_estatal=directo8*0.01200361	 if id_entidad_federativa==3	
replace	directo_estatal=directo8*0.00243510	 if id_entidad_federativa==4	
replace	directo_estatal=directo8*0.03171649	 if id_entidad_federativa==5	
replace	directo_estatal=directo8*0.00738206	 if id_entidad_federativa==6	
replace	directo_estatal=directo8*0.01766601	 if id_entidad_federativa==7	
replace	directo_estatal=directo8*0.03482614	 if id_entidad_federativa==8	
replace	directo_estatal=directo8*0.10666915	 if id_entidad_federativa==9	
replace	directo_estatal=directo8*0.01712660	 if id_entidad_federativa==10	
replace	directo_estatal=directo8*0.04367969	 if id_entidad_federativa==11	
replace	directo_estatal=directo8*0.01753195	 if id_entidad_federativa==12	
replace	directo_estatal=directo8*0.01625186	 if id_entidad_federativa==13	
replace	directo_estatal=directo8*0.08185233	 if id_entidad_federativa==14	
replace	directo_estatal=directo8*0.11098220	 if id_entidad_federativa==15	
replace	directo_estatal=directo8*0.04223579	 if id_entidad_federativa==16	
replace	directo_estatal=directo8*0.01064599	 if id_entidad_federativa==17	
replace	directo_estatal=directo8*0.00816587	 if id_entidad_federativa==18	
replace	directo_estatal=directo8*0.07275221	 if id_entidad_federativa==19	
replace	directo_estatal=directo8*0.01994936	 if id_entidad_federativa==20	
replace	directo_estatal=directo8*0.04244868	 if id_entidad_federativa==21	
replace	directo_estatal=directo8*0.02161632	 if id_entidad_federativa==22	
replace	directo_estatal=directo8*0.02072792	 if id_entidad_federativa==23	
replace	directo_estatal=directo8*0.01644562	 if id_entidad_federativa==24	
replace	directo_estatal=directo8*0.02144071	 if id_entidad_federativa==25	
replace	directo_estatal=directo8*0.02341200	 if id_entidad_federativa==26	
replace	directo_estatal=directo8*0.01294440	 if id_entidad_federativa==27	
replace	directo_estatal=directo8*0.02508856	 if id_entidad_federativa==28	
replace	directo_estatal=directo8*0.00340861	 if id_entidad_federativa==29	
replace	directo_estatal=directo8*0.03954679	 if id_entidad_federativa==30	
replace	directo_estatal=directo8*0.01498226	 if id_entidad_federativa==31	
replace	directo_estatal=directo8*0.01195345	 if id_entidad_federativa==32	
replace	directo_estatal=directo8 if	id_entidad_federativa==33



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

/*el 92% restante de IEPS a tabaco se distribuye segÃºn los porcentajes de la LCF; en la nota metodolÃ³fica se ponen los porcentajes sobre el total de IEPS a tabaco*/
gen ieps92_1=recaudacion_1*0.92

gen fgp_1=ieps92_1*0.2
gen fgp2_1=recaudacion_1*0.184
gen litoral_1=ieps92_1*0.00136
gen litoral2_1=recaudacion_1*0.001256
gen ffm_1=ieps92_1*0.01
gen ffr_1=ieps92_1*0.0125

*Son los mismos coeficientes a Abril 2022

*Distribucion estatal del FGP*
gen fgp_estatal_1=fgp_1*0.010415092 if id_entidad_federativa==1
replace fgp_estatal_1=fgp_1*0.029213247 if id_entidad_federativa==2
replace fgp_estatal_1=fgp_1*0.006399679	if id_entidad_federativa==3
replace fgp_estatal_1=fgp_1*0.008198814	if id_entidad_federativa==4
replace fgp_estatal_1=fgp_1*0.023637259	if id_entidad_federativa==5
replace fgp_estatal_1=fgp_1*0.006296334	if id_entidad_federativa==6
replace fgp_estatal_1=fgp_1*0.041100072	if id_entidad_federativa==7
replace fgp_estatal_1=fgp_1*0.030198311	if id_entidad_federativa==8
replace fgp_estatal_1=fgp_1*0.097397447	if id_entidad_federativa==9
replace fgp_estatal_1=fgp_1*0.013487303	if id_entidad_federativa==10
replace fgp_estatal_1=fgp_1*0.043723592	if id_entidad_federativa==11
replace fgp_estatal_1=fgp_1*0.025445621	if id_entidad_federativa==12
replace fgp_estatal_1=fgp_1*0.020690465	if id_entidad_federativa==13
replace fgp_estatal_1=fgp_1*0.067150113	if id_entidad_federativa==14
replace fgp_estatal_1=fgp_1*0.146691278	if id_entidad_federativa==15
replace fgp_estatal_1=fgp_1*0.033221129	if id_entidad_federativa==16
replace fgp_estatal_1=fgp_1*0.014543924	if id_entidad_federativa==17
replace fgp_estatal_1=fgp_1*0.009653377	if id_entidad_federativa==18
replace fgp_estatal_1=fgp_1*0.046645771	if id_entidad_federativa==19
replace fgp_estatal_1=fgp_1*0.027515889	if id_entidad_federativa==20
replace fgp_estatal_1=fgp_1*0.045597904	if id_entidad_federativa==21
replace fgp_estatal_1=fgp_1*0.016501715	if id_entidad_federativa==22
replace fgp_estatal_1=fgp_1*0.013373973	if id_entidad_federativa==23
replace fgp_estatal_1=fgp_1*0.020425782	if id_entidad_federativa==24
replace fgp_estatal_1=fgp_1*0.024129168	if id_entidad_federativa==25
replace fgp_estatal_1=fgp_1*0.023966284	if id_entidad_federativa==26
replace fgp_estatal_1=fgp_1*0.024741582	if id_entidad_federativa==27
replace fgp_estatal_1=fgp_1*0.028714086	if id_entidad_federativa==28
replace fgp_estatal_1=fgp_1*0.010174306	if id_entidad_federativa==29
replace fgp_estatal_1=fgp_1*0.062439355	if id_entidad_federativa==30
replace fgp_estatal_1=fgp_1*0.016529602	if id_entidad_federativa==31
replace fgp_estatal_1=fgp_1*0.011781524	if id_entidad_federativa==32
replace fgp_estatal_1=fgp_1 if id_entidad_federativa==33		


*Distribucion estatal del Litoral*
gen	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==1
replace	litoral_estatal_1=litoral_1*0.043180757 if id_entidad_federativa==2
replace	litoral_estatal_1=litoral_1*0.00008248 if id_entidad_federativa==3
replace	litoral_estatal_1=litoral_1*0.00324995 if id_entidad_federativa==4
replace	litoral_estatal_1=litoral_1*0.028225159 if id_entidad_federativa==5
replace	litoral_estatal_1=litoral_1*0.028892594 if id_entidad_federativa==6
replace	litoral_estatal_1=litoral_1*0.001250446 if id_entidad_federativa==7
replace	litoral_estatal_1=litoral_1*0.043336983 if id_entidad_federativa==8
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==9
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==10
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==11
replace	litoral_estatal_1=litoral_1*0.000905081 if id_entidad_federativa==12
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==13
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==14
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==15
replace	litoral_estatal_1=litoral_1*0.055702781 if id_entidad_federativa==16
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==17
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==18
replace	litoral_estatal_1=litoral_1*0.015366739 if id_entidad_federativa==19
replace	litoral_estatal_1=litoral_1*0.000667719 if id_entidad_federativa==20
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==21
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==22
replace	litoral_estatal_1=litoral_1*0.00500957 if id_entidad_federativa==23
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==24
replace	litoral_estatal_1=litoral_1*0.002142596 if id_entidad_federativa==25
replace	litoral_estatal_1=litoral_1*0.051439929 if id_entidad_federativa==26
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==27
replace	litoral_estatal_1=litoral_1*0.666664947 if id_entidad_federativa==28
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==29
replace	litoral_estatal_1=litoral_1*0.048302646 if id_entidad_federativa==30
replace	litoral_estatal_1=litoral_1*0.005579622 if id_entidad_federativa==31
replace	litoral_estatal_1=litoral_1*0 if id_entidad_federativa==32
replace	litoral_estatal_1=litoral_1==33				


*Distribucion estatal del FFM*
gen	ffm_estatal_1=ffm_1*0.016097587 if id_entidad_federativa==1
replace	ffm_estatal_1=ffm_1*0.020977931 if id_entidad_federativa==2
replace	ffm_estatal_1=ffm_1*0.005408319 if id_entidad_federativa==3
replace	ffm_estatal_1=ffm_1*0.009991479 if id_entidad_federativa==4
replace	ffm_estatal_1=ffm_1*0.021326273 if id_entidad_federativa==5
replace	ffm_estatal_1=ffm_1*0.007507657	if id_entidad_federativa==6
replace	ffm_estatal_1=ffm_1*0.031998725	if id_entidad_federativa==7
replace	ffm_estatal_1=ffm_1*0.033471639	if id_entidad_federativa==8
replace	ffm_estatal_1=ffm_1*0.103066903	if id_entidad_federativa==9
replace	ffm_estatal_1=ffm_1*0.019914436 if id_entidad_federativa==10
replace	ffm_estatal_1=ffm_1*0.053854938	if id_entidad_federativa==11
replace	ffm_estatal_1=ffm_1*0.021223116	if id_entidad_federativa==12
replace	ffm_estatal_1=ffm_1*0.028374063	if id_entidad_federativa==13
replace	ffm_estatal_1=ffm_1*0.070864761	if id_entidad_federativa==14
replace	ffm_estatal_1=ffm_1*0.124199603	if id_entidad_federativa==15
replace	ffm_estatal_1=ffm_1*0.03676094 if id_entidad_federativa==16
replace	ffm_estatal_1=ffm_1*0.015535293	if id_entidad_federativa==17
replace	ffm_estatal_1=ffm_1*0.011774939	if id_entidad_federativa==18
replace	ffm_estatal_1=ffm_1*0.042544251	if id_entidad_federativa==19
replace	ffm_estatal_1=ffm_1*0.03593734 if id_entidad_federativa==20
replace	ffm_estatal_1=ffm_1*0.041099658	if id_entidad_federativa==21
replace	ffm_estatal_1=ffm_1*0.018101939	if id_entidad_federativa==22
replace	ffm_estatal_1=ffm_1*0.012067467	if id_entidad_federativa==23
replace	ffm_estatal_1=ffm_1*0.022263471	if id_entidad_federativa==24
replace	ffm_estatal_1=ffm_1*0.028267595	if id_entidad_federativa==25
replace	ffm_estatal_1=ffm_1*0.016584538	if id_entidad_federativa==26
replace	ffm_estatal_1=ffm_1*0.020868328	if id_entidad_federativa==27
replace	ffm_estatal_1=ffm_1*0.026895047	if id_entidad_federativa==28
replace	ffm_estatal_1=ffm_1*0.01090285 if id_entidad_federativa==29
replace	ffm_estatal_1=ffm_1*0.047443441	if id_entidad_federativa==30
replace	ffm_estatal_1=ffm_1*0.024450218	if id_entidad_federativa==31
replace	ffm_estatal_1=ffm_1*0.020225253	if id_entidad_federativa==32
replace	ffm_estatal_1=ffm_1 if id_entidad_federativa==33


*Distribucion estatal del FFR*
gen	ffr_estatal_1=ffr_1*0.01110333	if id_entidad_federativa==1
replace	ffr_estatal_1=ffr_1*0.02985734	if id_entidad_federativa==2
replace	ffr_estatal_1=ffr_1*0.00755154	if id_entidad_federativa==3
replace	ffr_estatal_1=ffr_1*0.00483538	if id_entidad_federativa==4
replace	ffr_estatal_1=ffr_1*0.01812321	if id_entidad_federativa==5
replace	ffr_estatal_1=ffr_1*0.00475466	if id_entidad_federativa==6
replace	ffr_estatal_1=ffr_1*0.02679803	if id_entidad_federativa==7
replace	ffr_estatal_1=ffr_1*0.06287215	if id_entidad_federativa==8
replace	ffr_estatal_1=ffr_1*0.07144742	if id_entidad_federativa==9
replace	ffr_estatal_1=ffr_1*0.01048534	if id_entidad_federativa==10
replace	ffr_estatal_1=ffr_1*0.06042430	if id_entidad_federativa==11
replace	ffr_estatal_1=ffr_1*0.01477110	if id_entidad_federativa==12
replace	ffr_estatal_1=ffr_1*0.01372552	if id_entidad_federativa==13
replace	ffr_estatal_1=ffr_1*0.05125473	if id_entidad_federativa==14
replace	ffr_estatal_1=ffr_1*0.13551573	if id_entidad_federativa==15
replace	ffr_estatal_1=ffr_1*0.02507843	if id_entidad_federativa==16
replace	ffr_estatal_1=ffr_1*0.00995844	if id_entidad_federativa==17
replace	ffr_estatal_1=ffr_1*0.00557749	if id_entidad_federativa==18
replace	ffr_estatal_1=ffr_1*0.05750479	if id_entidad_federativa==19
replace	ffr_estatal_1=ffr_1*0.02486404	if id_entidad_federativa==20
replace	ffr_estatal_1=ffr_1*0.03594476	if id_entidad_federativa==21
replace	ffr_estatal_1=ffr_1*0.03516703	if id_entidad_federativa==22
replace	ffr_estatal_1=ffr_1*0.01787220	if id_entidad_federativa==23
replace	ffr_estatal_1=ffr_1*0.02105565	if id_entidad_federativa==24
replace	ffr_estatal_1=ffr_1*0.04577002	if id_entidad_federativa==25
replace	ffr_estatal_1=ffr_1*0.07824077	if id_entidad_federativa==26
replace	ffr_estatal_1=ffr_1*0.02250123	if id_entidad_federativa==27
replace	ffr_estatal_1=ffr_1*0.02286466	if id_entidad_federativa==28
replace	ffr_estatal_1=ffr_1*0.00669038	if id_entidad_federativa==29
replace	ffr_estatal_1=ffr_1*0.03702698	if id_entidad_federativa==30
replace	ffr_estatal_1=ffr_1*0.02056064	if id_entidad_federativa==31
replace	ffr_estatal_1=ffr_1*0.00980269	if id_entidad_federativa==32
replace	ffr_estatal_1=ffr_1 if id_entidad_federativa==33


*Distribucion estatal del 8% directo*
gen	directo_estatal_1=directo8_1*0.02807156	 if id_entidad_federativa==1	
replace	directo_estatal_1=directo8_1*0.06404072	 if id_entidad_federativa==2	
replace	directo_estatal_1=directo8_1*0.01200361	 if id_entidad_federativa==3	
replace	directo_estatal_1=directo8_1*0.00243510	 if id_entidad_federativa==4	
replace	directo_estatal_1=directo8_1*0.03171649	 if id_entidad_federativa==5	
replace	directo_estatal_1=directo8_1*0.00738206	 if id_entidad_federativa==6	
replace	directo_estatal_1=directo8_1*0.01766601	 if id_entidad_federativa==7	
replace	directo_estatal_1=directo8_1*0.03482614	 if id_entidad_federativa==8	
replace	directo_estatal_1=directo8_1*0.10666915	 if id_entidad_federativa==9	
replace	directo_estatal_1=directo8_1*0.01712660	 if id_entidad_federativa==10	
replace	directo_estatal_1=directo8_1*0.04367969	 if id_entidad_federativa==11	
replace	directo_estatal_1=directo8_1*0.01753195	 if id_entidad_federativa==12	
replace	directo_estatal_1=directo8_1*0.01625186	 if id_entidad_federativa==13	
replace	directo_estatal_1=directo8_1*0.08185233	 if id_entidad_federativa==14	
replace	directo_estatal_1=directo8_1*0.11098220	 if id_entidad_federativa==15	
replace	directo_estatal_1=directo8_1*0.04223579	 if id_entidad_federativa==16	
replace	directo_estatal_1=directo8_1*0.01064599	 if id_entidad_federativa==17	
replace	directo_estatal_1=directo8_1*0.00816587	 if id_entidad_federativa==18	
replace	directo_estatal_1=directo8_1*0.07275221	 if id_entidad_federativa==19	
replace	directo_estatal_1=directo8_1*0.01994936	 if id_entidad_federativa==20	
replace	directo_estatal_1=directo8_1*0.04244868	 if id_entidad_federativa==21	
replace	directo_estatal_1=directo8_1*0.02161632	 if id_entidad_federativa==22	
replace	directo_estatal_1=directo8_1*0.02072792	 if id_entidad_federativa==23	
replace	directo_estatal_1=directo8_1*0.01644562	 if id_entidad_federativa==24	
replace	directo_estatal_1=directo8_1*0.02144071	 if id_entidad_federativa==25	
replace	directo_estatal_1=directo8_1*0.02341200	 if id_entidad_federativa==26	
replace	directo_estatal_1=directo8_1*0.01294440	 if id_entidad_federativa==27	
replace	directo_estatal_1=directo8_1*0.02508856	 if id_entidad_federativa==28	
replace	directo_estatal_1=directo8_1*0.00340861	 if id_entidad_federativa==29	
replace	directo_estatal_1=directo8_1*0.03954679	 if id_entidad_federativa==30	
replace	directo_estatal_1=directo8_1*0.01498226	 if id_entidad_federativa==31	
replace	directo_estatal_1=directo8_1*0.01195345	 if id_entidad_federativa==32	
replace	directo_estatal_1=directo8_1 if	id_entidad_federativa==33


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
/*

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

*/



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
