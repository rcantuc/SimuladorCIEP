********************************************
****                                    ****
**** ARMONIZACION ENIGH 2020 + LIF, PEF ****
****    INFORMACION DE HOGARES          ****
****                                    ****
********************************************
if "`1'" == "" {
	local 1 = 2022
}

if "$pais" != "" {
	exit
}




**********************
*** 1. Macros: PEF ***
**********************
PEF, anio(`1') by(desc_funcion) min(0) nographs
local Cuotas_ISSSTE = r(Cuotas_ISSSTE)

PEF if transf_gf == 0 & ramo != -1 & (substr(string(objeto),1,2) == "45" ///
	| substr(string(objeto),1,2) == "47" | desc_pp == 779), anio(`1') by(ramo) min(0) nographs
local SSFederacion = r(Aportaciones_a_Seguridad_Social) + `Cuotas_ISSSTE'

PEF if divGA == 3, anio(`1') by(desc_subfuncion) min(0) nographs
local Basica = r(Educaci_c_o__n_B_c_a__sica)
local Media = r(Educaci_c_o__n_Media_Superior)
local Superior = r(Educaci_c_o__n_Superior)
local Adultos = r(Educaci_c_o__n_para_Adultos)
local Posgrado = r(Posgrado)

PEF, anio(`1') by(divGA) min(0) nographs
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)
local PenBienestar = r(Pensi_c_o__n_Bienestar)

PEF if capitulo == 6 & divGA != 3 & divGA != 7, anio(`1') by(entidad) min(0) nographs
local Aguas = r(Aguascalientes)
local BajaN = r(Baja_California)
local BajaS = r(Baja_California_Sur)
local Campe = r(Campeche)
local Coahu = r(Coahuila)
local Colim = r(Colima)
local Chiap = r(Chiapas)
local Chihu = r(Chihuahua)
local Ciuda = r(Ciudad_de_M_c_e__xico)
local Duran = r(Durango)
local Guana = r(Guanajuato)
local Guerr = r(Guerrero)
local Hidal = r(Hidalgo)
local Jalis = r(Jalisco)
local Estad = r(Estado_de_M_c_e__xico)
local Micho = r(Michoac_c_a__n)
local Morel = r(Morelos)
local Nayar = r(Nayarit)
local Nuevo = r(Nuevo_Le_c_o__n)
local Oaxac = r(Oaxaca)
local Puebl = r(Puebla)
local Quere = r(Quer_c_e__taro)
local Quint = r(Quintana_Roo)
local SanLu = r(San_Luis_Potos_c_i__)
local Sinal = r(Sinaloa)
local Sonor = r(Sonora)
local Tabas = r(Tabasco)
local Tamau = r(Tamaulipas)
local Tlaxc = r(Tlaxcala)
local Verac = r(Veracruz)
local Yucat = r(Yucat_c_a__n)
local Zacat = r(Zacatecas)
local InfraT = r(StatTotal)



**********************
*** 2. Macros: LIF ***
**********************
LIF, anio(`1') nographs min(0)
local ISRSalarios = r(ISR_Asa_)
local ISRFisicas = r(ISR_PF)
local ISRMorales = r(ISR_PM)
local CuotasIMSS = r(Cuotas_IMSS)
local IEPSTOT = r(IEPS)
local IVATOT = r(IVA)
local IMSSpropio = r(IMSS)-`CuotasIMSS'
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP__Der__petroleros)
local Deuda = r(Deuda)
local Mejoras = r(Contribuciones_de_mejoras)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)
local Importaciones = r(Importaciones)
local ISAN = r(ISAN)

LIF, anio(`1') by(divGA) nographs min(0)
local alingreso = r(Impuestos_al_ingreso)-`ISRMorales'
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Ingresos_de_capital)+`ISRMorales'

LIF, anio(`1') nographs min(0) by(serie)
local IEPSAlcohol = r(XNA0203)
local IEPSTabaco = r(XNA0125)


**********************
*** 3. Macros: PIB ***
**********************
use if anio == `1' | anio == 2020 using "`c(sysdir_site)'/users/$pais/$id/PIB.dta", clear
local lambda = lambda[1]
local deflator = deflator[1]


***************************
*** 4. Ajuste Poblacion *** 
***************************
use if anio == `1' using `"`c(sysdir_site)'/SIM/Poblaciontot.dta"', clear
local ajustepob = poblacion



**********************************
*** 4. Variables Simulador.ado ***
**********************************
use "`c(sysdir_site)'/SIM/2020/households.dta", clear

tabstat factor, stat(sum) f(%20.0fc) save
tempname pobenigh
matrix `pobenigh' = r(StatTotal)
replace factor = round(factor*`ajustepob'/`pobenigh'[1,1],1)

noisily Simulador ing_subor [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini ing_subor, hogar(folioviv foliohog) individuo(numren) factor(factor)
exit

**************************************
** (+) Impuestos al ingreso laboral **

** (+) ISR Asalariados **
Distribucion ISRAS, relativo(ISR__asalariados) macro(`ISRSalarios')
label var ISRAS "ISR (Salarios)"
noisily Simulador ISRAS [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini ISRAS, hogar(folioviv foliohog) individuo(numren) factor(factor)

** (+) ISR Personas Físicas **
Distribucion ISRPF, relativo(ISR__PF) macro(`ISRFisicas')
label var ISRPF "ISR (personas f{c i'}sicas)"
noisily Simulador ISRPF [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini ISRPF, hogar(folioviv foliohog) individuo(numren) factor(factor)

** (+) Cuotas obrero-patronal IMSS **
Distribucion CuotasSS if formal == 1, relativo(cuotasTP) macro(`=`CuotasIMSS'')
label var CuotasSS "cuotas IMSS"
noisily Simulador CuotasSS [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini CuotasSS, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) Impuestos laborales **
egen laboral = rsum(ISRAS ISRPF CuotasSS)
replace laboral = 0 if laboral == .

Distribucion Laboral, relativo(laboral) macro(`=`ISRSalarios'+`ISRFisicas'')
label var Laboral "los impuestos al ingreso laboral"
noisily Simulador Laboral [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini Laboral, hogar(folioviv foliohog) individuo(numren) factor(factor)



****************************************
** (+) Impuestos e ingresos de capital **

** (+) ISR Personas Morales **
Distribucion ISRPM, relativo(ISR__PM) macro(`ISRMorales')
label var ISRPM "ISR (personas morales)"
noisily Simulador ISRPM [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini ISRPM, hogar(folioviv foliohog) individuo(numren) factor(factor)

** (+) Otros de capital **
Distribucion OtrosC, relativo(ISR__PM) macro(`=`otrosing'+`ISRMorales'')
label var OtrosC "los ingresos de capital"
noisily Gini OtrosC, hogar(folioviv foliohog) individuo(numren) factor(factor)




*****************************
** (+) Impuestos al consumo **

** (+) IEPS **
Distribucion IEPS, relativo(TOTIEPS) macro(`IEPSTOT')
label var IEPS "IEPS (total)"
noisily Simulador IEPS [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini IEPS, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) IEPS Alcohol **
Distribucion IEPSAlcohol, relativo(IEPS3) macro(`IEPSAlcohol')
label var IEPSAlcohol "IEPS (alcohol)"
noisily Gini IEPSAlcohol, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) IEPS Tabaco **
Distribucion IEPSTabaco, relativo(IEPS4) macro(`IEPSTabaco')
label var IEPSTabaco "IEPS (tabaco)"

noisily Gini IEPSTabaco if IEPSTabaco != 0, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) ISAN **
Distribucion ISANTOT, relativo(ISAN) macro(`ISAN')
label var ISANTOT "ISAN"
noisily Simulador ISANTOT [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini ISANTOT, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) IVA **
Distribucion IVA, relativo(TOTIVA) macro(`IVATOT')
label var IVA "IVA"
noisily Simulador IVA [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini IVA, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) Importaciones **
Distribucion IMPORT, relativo(Importaciones) macro(`Importaciones')
label var IMPORT "Importaciones"
noisily Simulador IMPORT [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini IMPORT, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (+) TOTAL **
egen consumo = rsum(IVA ISANTOT IEPS IMPORT)
replace consumo = 0 if consumo == .

Distribucion Consumo, relativo(consumo) macro(`alconsumo')
label var Consumo "los impuestos al consumo"


** (+) Petroleo **
g pob = 1
Distribucion Petroleo, relativo(pob) macro(`FMP')
label var Petroleo "ingresos petroleros"
noisily Gini Petroleo, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (=) Impuestos y aportaciones **
egen ImpuestosAportaciones = rsum(ISRAS ISRPF ISRPM CuotasSS IVA IEPS ISANTOT IMPORT)
label var ImpuestosAportaciones "impuestos y aportaciones"
noisily Simulador ImpuestosAportaciones [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Gini ImpuestosAportaciones, hogar(folioviv foliohog) individuo(numren) factor(factor)


** (=) Ingresos Publicos **
egen IngresosPublicos = rsum(Laboral Consumo OtrosC)
label var IngresosPublicos "ingresos p{c u'}blicos"
noisily Gini IngresosPublicos, hogar(folioviv foliohog) individuo(numren) factor(factor)








exit













** (-) Pensiones **
g ing_jubila_pub = ing_jubila if (formal == 1 | formal == 2 | formal == 3) & ing_jubila != 0
replace ing_jubila_pub = 0 if ing_jubila_pub == .
Distribucion Pension, relativo(ing_jubila_pub) macro(`Pensiones')
label var Pension "pensiones"

** (-) Pension Bienestar **
tabstat factor if edad >= 65, stat(sum) f(%20.0fc) save
matrix POBLACION68 = r(StatTotal)

g PenBienestar = `PenBienestar'/POBLACION68[1,1] if edad >= 65
replace PenBienestar = 0 if PenBienestar == .
label var PenBienestar "pensi{c o'}n Bienestar"

** (-) Educacion **
tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18, stat(sum) f(%15.0fc) save
matrix BasAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10"), stat(sum) f(%15.0fc) save
matrix MedAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12"), stat(sum) f(%15.0fc) save
matrix SupAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & nivel == "13", stat(sum) f(%15.0fc) save
matrix PosAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18, stat(sum) f(%15.0fc) save
matrix AduAlum = r(StatTotal)

g educacion = `Basica'/BasAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18
replace educacion = `Media'/MedAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
replace educacion = `Superior'/SupAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
replace educacion = `Posgrado'/PosAlum[1,1] if asis_esc == "1" & tipoesc == "1" & nivel == "13"
replace educacion = `Adultos'/AduAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18
replace educacion = 0 if educacion == .

Distribucion Educacion, relativo(educacion) macro(`Educacion')
label var Educacion "educaci{c o'}n"

** (-) Salud **
tempvar benef_imss
g `benef_imss' = inst_1 == "1"
egen benef_imss = max(`benef_imss'), by(folioviv foliohog)

tempvar benef_issste benef_isssteest
g `benef_issste' = inst_2 == "2"
egen benef_issste = max(`benef_issste'), by(folioviv foliohog)

g benef_pemex = inst_4 == "4"

g benef_isssteest = inst_3 == "3"

tempvar benef_imssprospera
g `benef_imssprospera' = inst_5 == "5" | inst_3 == "3" // Incluye ISSSTE Estatal
egen benef_imssprospera = max(`benef_imssprospera'), by(folioviv foliohog)

tempvar benef_otro
capture g `benef_otro' = inst_6 == "6"
if _rc != 0 {
	g `benef_otro' = 0
}
egen benef_otro = max(`benef_otro'), by(folioviv foliohog)

tempvar benef_seg_pop
g `benef_seg_pop' = pop_insabi == "1" | (benef_imss == 0 & benef_issste == 0 & benef_pemex == 0)
egen benef_seg_pop = max(`benef_seg_pop'), by(folioviv foliohog)

g benef_ssa = 1

tabstat benef_imss benef_issste benef_pemex benef_imssprospera benef_seg_pop ///
	benef_ssa benef_isssteest benef_otro [fw=factor], stat(sum) f(%15.0fc) save
tempname MSalud
matrix `MSalud' = r(StatTotal)

tabstat factor, stat(sum) f(%20.0fc) save
tempname pobtot
matrix `pobtot' = r(StatTotal)

preserve
PEF if divGA == 7, anio(`1') by(desc_pp) min(0) nographs
local segpop0 = r(Seguro_Popular)
if `segpop0' == . {
	local segpop0 = r(Atenci_c_o__n_a_la_Salud_y_Medi)
}
local caneros = r(Seguridad_Social_Ca_c_n__eros)
local incorpo = r(R_c_e__gimen_de_Incorporaci_c_o)
local adeusal = r(Adeudos_con_el_IMSS_e_ISSSTE_y_)

PEF if divGA == 7, anio(`1') by(ramo) min(0) nographs
local fassa = r(Aportaciones_Federales_para_Ent) //+ r(Aportaciones_Federales_para_EntC)






PEF if divGA == 7 /*& desc_ur == 1238*/, anio(`1') by(desc_pp) min(0) nographs		// <--- HAY QUE ARREGLARLO!!!!!
local fortaINSABI = r(Fortalecimiento_a_la_atenci_c_o) //+r(Fortalecimiento_a_la_atenci_c_oC)
local atencINSABI = r(Atenci_c_o__n_a_la_Salud) //+r(Atenci_c_o__n_a_la_SaludC)







local segpop = `segpop0'+`fassa'+`fortaINSABI'+`atencINSABI'
restore

preserve
PEF if divGA == 7, anio(`1') by(ramo) min(0) nographs
local ssa = r(Salud)-`segpop0'+`caneros'+`incorpo'+`adeusal'-`fortaINSABI'-`atencINSABI'  //+r(SaludC)
restore

preserve
PEF if divGA == 7, anio(`1') by(ramo) min(0) nographs
local imss = r(Instituto_Mexicano_del_Seguro_S)
restore

preserve
PEF if divGA == 7, anio(`1') by(ramo) min(0) nographs
local issste = r(Instituto_de_Seguridad_y_Servic)
restore

preserve
PEF if divGA == 7, anio(`1') by(desc_pp) min(0) nographs
local prospe = r(Programa_IMSS_BIENESTAR)
restore

preserve
PEF if divGA == 7 & modalidad == "E" & pp == 13 & ramo == 52, anio(`1') by(ramo) min(0) nographs
local pemex = r(Petr_c_o__leos_Mexicanos)

PEF if divGA == 7, anio(`1') by(ramo) min(0) nographs
local pemex = `pemex' + r(Defensa_Nacional) + r(Marina)
restore

g salud = 0
replace salud = salud + `segpop'/(`MSalud'[1,5]+`MSalud'[1,7]) if benef_seg_pop == 1 | benef_isssteest == 1
replace salud = salud + `imss'/`MSalud'[1,1] if benef_imss == 1
replace salud = salud + `issste'/`MSalud'[1,2] if benef_issste == 1
replace salud = salud + `prospe'/`MSalud'[1,4] if benef_imssprospera == 1
replace salud = salud + `pemex'/`MSalud'[1,3] if benef_pemex == 1
replace salud = salud + `ssa'/`pobtot'[1,1] if benef_ssa == 1

* Defunciones *
replace salud = 1.963106 if edad == 0
replace salud = .1351139 if edad == 1
replace salud = .0710421 if edad == 2
replace salud = .0499305 if edad == 3
replace salud = .0435635 if edad == 4
replace salud = .0406816 if edad == 5
replace salud = .0377997 if edad == 6
replace salud = .0366604 if edad == 7
replace salud = .0367274 if edad == 8
replace salud = .0380008 if edad == 9
replace salud = .0408157 if edad == 10
replace salud = .0454401 if edad == 11
replace salud = .0518741 if edad == 12
replace salud = .06119 if edad == 13
replace salud = .0719133 if edad == 14
replace salud = .0845803 if edad == 15
replace salud = .0985876 if edad == 16
replace salud = .1129301 if edad == 17
replace salud = .1279427 if edad == 18
replace salud = .1428213 if edad == 19
replace salud = .1573648 if edad == 20
replace salud = .1705009 if edad == 21
replace salud = .183637 if edad == 22
replace salud = .1950976 if edad == 23
replace salud = .2048156 if edad == 24
replace salud = .21259 if edad == 25
replace salud = .2184208 if edad == 26
replace salud = .2221069 if edad == 27
replace salud = .2247208 if edad == 28
replace salud = .2269995 if edad == 29
replace salud = .2280048 if edad == 30
replace salud = .2303505 if edad == 31
replace salud = .231825 if edad == 32
replace salud = .2343047 if edad == 33
replace salud = .2374547 if edad == 34
replace salud = .2412079 if edad == 35
replace salud = .2464355 if edad == 36
replace salud = .2534057 if edad == 37
replace salud = .2617162 if edad == 38
replace salud = .2727747 if edad == 39
replace salud = .2861118 if edad == 40
replace salud = .3017277 if edad == 41
replace salud = .3197563 if edad == 42
replace salud = .3391923 if edad == 43
replace salud = .3592315 if edad == 44
replace salud = .3803431 if edad == 45
replace salud = .4013206 if edad == 46
replace salud = .421963 if edad == 47
replace salud = .4438788 if edad == 48
replace salud = .4657276 if edad == 49
replace salud = .489654 if edad == 50
replace salud = .5133794 if edad == 51
replace salud = .5393164 if edad == 52
replace salud = .567063 if edad == 53
replace salud = .5955469 if edad == 54
replace salud = .6245669 if edad == 55
replace salud = .6546592 if edad == 56
replace salud = .6843494 if edad == 57
replace salud = .7137045 if edad == 58
replace salud = .740915 if edad == 59
replace salud = .7671201 if edad == 60
replace salud = .7916497 if edad == 61
replace salud = .815107 if edad == 62
replace salud = .837492 if edad == 63
replace salud = .8573301 if edad == 64
replace salud = .8764981 if edad == 65
replace salud = .8941916 if edad == 66
replace salud = .9090032 if edad == 67
replace salud = .9293775 if edad == 68
replace salud = .9522986 if edad == 69
replace salud = .9701261 if edad == 70
replace salud = .9868143 if edad == 71
replace salud = 1.002765 if edad == 72
replace salud = 1.016505 if edad == 73
replace salud = 1.02944 if edad == 74
replace salud = 1.03842 if edad == 75
replace salud = 1.047937 if edad == 76
replace salud = 1.053567 if edad == 77
replace salud = 1.053165 if edad == 78
replace salud = 1.046731 if edad == 79
replace salud = 1.037013 if edad == 80
replace salud = 1.023408 if edad == 81
replace salud = 1.005111 if edad == 82
replace salud = .9829941 if edad == 83
replace salud = .9557837 if edad == 84
replace salud = .9243509 if edad == 85
replace salud = .8868863 if edad == 86
replace salud = .844127 if edad == 87
replace salud = .7932582 if edad == 88
replace salud = .7351512 if edad == 89
replace salud = .6751676 if edad == 90
replace salud = .612168 if edad == 91
replace salud = .54756 if edad == 92
replace salud = .4848955 if edad == 93
replace salud = .4216949 if edad == 94
replace salud = .3601028 if edad == 95
replace salud = .3007894 if edad == 96
replace salud = .2456312 if edad == 97
replace salud = .1952316 if edad == 98
replace salud = .151333 if edad == 99
replace salud = .1138013 if edad == 100
replace salud = .0828377 if edad == 101
replace salud = .0587102 if edad == 102
replace salud = .0397433 if edad == 103
replace salud = .0259371 if edad == 104
replace salud = .0162861 if edad == 105
replace salud = .0092489 if edad == 106
replace salud = .0049595 if edad == 107
replace salud = .0004021 if edad == 108
replace salud = .0030159 if edad >= 109

Distribucion Salud, relativo(salud) macro(`Salud')
label var Salud "salud"

** (-) Otros gastos **
Distribucion OtrosGas, relativo(factor_cola) macro(`OtrosGas')
label var OtrosGas "otros gastos"

** (-) Ingreso B{c a'}sico **
g IngBasico = 0.1
label var IngBasico "ingreso b{c a'}sico"

** (*) Infraestructura **
g entidad = substr(folio,1,2)
destring entidad, replace
local j = 1
foreach k in Aguas BajaN BajaS Campe Coahu Colim Chiap Chihu Ciuda Duran Guana ///
	Guerr Hidal Jalis Estad Micho Morel Nayar Nuevo Oaxac Puebl Quere Quint ///
	SanLu Sinal Sonor Tabas Tamau Tlaxc Verac Yucat Zacat {

	tempvar factor_`k'
	g `factor_`k'' = factor_cola if entidad == `j'
	Distribucion Infra_`k', relativo(`factor_`k'') macro(``k'')
	local ++j
}
egen Infra = rsum(Infra_*)
label var Infra "infraestructura"




******************
*** 6. ENGLISH ***
/******************
label var Laboral "Labor-based income tax"
label var CuotasSS "Social Security"
label var Consumo "Consumption tax"
label var OtrosC "Capital income"
label var Pension "Pensions"
label var PenBienestar "Bienestar pension"
label var Educacion "Education"
label var Salud "Health"
label var OtrosGas "Other expenditures"
label var IngBasico "Basic universal income"





***********/
*** SAVE ***
************
compress
capture drop __* 
capture drop *_accum
save "`c(sysdir_site)'/SIM/2020/households`1'.dta", replace







*******************/
*** 7. SIMULADOR ***
********************
use "`c(sysdir_site)'/SIM/2020/households`1'.dta", clear





exit
noisily Simulador Consumo [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador OtrosC [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador IEPSAlcohol [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador IEPSTabaco [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador Petroleo [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador Pension [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador PenBienestar if edad >= 65 [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador Educacion [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador Salud [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput //poblacion(defunciones)
noisily Simulador OtrosGas [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador IngBasico [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador Infra [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput
noisily Simulador ing_bruto_tpm [fw=factor], base("ENIGH 2020") boot(1) reboot nooutput
noisily Simulador IngresosPublicos [fw=factor], base("ENIGH 2020") boot(1) reboot anio(`1') nooutput

noisily Simulador ingbrutotot [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs nooutput
noisily Simulador TOTgastoanual [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs nooutput
noisily Simulador Yl [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs nooutput
noisily Simulador Yk [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs nooutput

replace Yk = Yk + gasto_anualDepreciacion - (ing_cap_imss + ing_cap_issste + ing_cap_cfe + ///
	ing_cap_pemex + ing_cap_fmp + ing_cap_mejoras + ing_cap_derechos + ///
	ing_cap_productos + ing_cap_aprovecha + ///
	ing_cap_otrostrib + ing_cap_otrasempr)

noisily Simulador Ciclodevida [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs nooutput
noisily Simulador Ahorro [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs nooutput






****************/
*** 8. SANKEY ***
*****************
if `c(version)' > 13.1 {
	foreach k in grupoedad decil escol sexo {
		noisily run "`c(sysdir_site)'/Sankey.do" `k' `1'
	}
}
