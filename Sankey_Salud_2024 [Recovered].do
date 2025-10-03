********************** SANKEY SALUD ****************************
*********************** julio 2025 *****************************
****************************************************************


clear
set more off

*******************************************************************************/
*Establecer directorio de trabajo:
*cap global directorio "C:\Users\agarc\CIEP Dropbox\Judith Mendez\EquipoCIEP\Salud_CIEP\5. BD salud"
cap global directorio "/Users/judysenyacen/CIEP Dropbox/Judith Mendez/EquipoCIEP/CIEP_Salud/5. BD salud"

use "${directorio}/ENIGH/ENIGH_stata/concentrado_hogar_poblacion_6.dta", clear 

*Renombrar seguro popular a insabi /// YA NO EXISTE EN 2024
*cap rename segpop pop_insabi 
  
*Convertir variables string a númerica 
destring inst_1 inst_2 inst_3 inst_4 inst_5 inst_6 inst_7 inst_8 inst_9 atemed ///
		 prob_anio prob_mes aten_sal prob_sal servmed_1 servmed_2 ///
		 servmed_3 servmed_4 servmed_5 servmed_6 servmed_7 servmed_8 ///
		 servmed_9 servmed_10 servmed_11 servmed_11, replace
cap destring servmed_12, replace 

*Población afiliada al seguro popular // YA NO EXISTE EN 2024
*gen insabi = pop_insabi if (pop_insabi == 1) 

*Genero una variable para cada uno de los subsistemas 
gen imss =	1       if (inst_1 == 1) 
gen issste = 1      if (inst_2 ==2 ) 
gen isssteest = 1  	if (inst_3 == 3) 
gen pemex = 1  		if (inst_4 == 4) 
gen bienestar = 1  	if (inst_5 == 5)
gen fed_est = 1  	if (inst_6 == 6)
gen sgm = 1  		if (inst_7 == 7)
gen otro = 1  		if (inst_8 == 8) 
gen ninguno = 1  	if (inst_9 == 9)


*Personas no afiliadas a ningún subsistema 
gen ninguno = 1 	if (atemed == 2) 
gen enigh = 2024

gen necesidad = .
*Necesidad de atención (necesidad actual) 
cap replace necesidad = 1  if ((prob_anio == 2024 | prob_anio == 2023 | (prob_anio == 2022 & prob_mes == 12)))
tempfile concentrado_2024
save `concentrado_2024'


*************************************
*********Afiliados a IMSS************
*************************************
use `concentrado_2024'
keep if imss == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format imss necesidad bus_aten atencion_reci  %12.0fc

rename imss afiliacion
gen subsistema = "IMSS"
order subsistema, b(afiliacion)
tempfile inst_1
save `inst_1'

*************************************
*********Afiliados a ISSSTE**********
*************************************
use `concentrado_2024'
keep if issste == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format issste necesidad bus_aten atencion_reci %12.0fc

rename issste afiliacion
gen subsistema = "ISSSTE"
order subsistema, b(afiliacion)
tempfile inst_2
save `inst_2'

*************************************
*****Afiliados a ISSSTE estatal******
*************************************
use `concentrado_2024'
keep if isssteest == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format isssteest necesidad bus_aten atencion_reci %12.0fc

rename isssteest afiliacion
gen subsistema = "ISSSTE Estatal"
order subsistema, b(afiliacion)
tempfile inst_3
save `inst_3'

*************************************
*********Afiliados a Pemex***********
*************************************
use `concentrado_2024'
keep if pemex == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format pemex necesidad bus_aten atencion_reci %12.0fc

rename pemex afiliacion
gen subsistema = "Pemex"
order subsistema, b(afiliacion)
tempfile inst_4
save `inst_4'

*********************************************
*********Afiliados a IMSS-Bienestar**********
*********************************************
use `concentrado_2024'
keep if bienestar == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)

**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format bienestar necesidad bus_aten atencion_reci %12.0fc
	   
rename bienestar afiliacion
gen subsistema = "IMSS - Bienestar"
order subsistema, b(afiliacion)
tempfile inst_5
save `inst_5'

*********************************************
************ Federal o Estatal **************
*********************************************
use `concentrado_2024'
keep if fed_est == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format fed_est necesidad bus_aten atencion_reci %12.0fc
	   
rename fed_est afiliacion
gen subsistema = "Público federal o estatal"
order subsistema, b(afiliacion)
tempfile inst_6
save `inst_6'


*********************************************
******************* SGM *********************
*********************************************
use `concentrado_2024'
keep if sgm == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format sgm necesidad bus_aten atencion_reci %12.0fc
	   
rename sgm afiliacion
gen subsistema = "SGM"
order subsistema, b(afiliacion)
tempfile inst_7
save `inst_7'


*********************************************
******************* Otro ********************
*********************************************
use `concentrado_2024'
keep if otro == 1 

*Personas que declararon tener una necesidad de atención y buscaron atencióm
gen bus_aten = 1 if prob_sal == 1 & necesidad == 1 

*Personas que recibieron atención
gen atencion_reci = 1 if aten_sal == 1 & bus_aten == 1

*Donde recibio atención
gen centros_ssa =	1           if (servmed_1 == 1) 
gen hospital_ssa = 1            if (servmed_2 == 2) 
gen atencion_imss = 1  	        if (servmed_3 == 3) 
gen atencion_bienestar = 1  	if (servmed_4 == 4) 
gen atencion_issste = 1  		if (servmed_5 == 5) 
gen atencion_estatal = 1        if (servmed_6 == 6)
gen atencion_otra_pub = 1  		if (servmed_7 == 7)
gen atencion_privada = 1  		if (servmed_8 == 8) 
gen atencion_farmacias = 1  	if (servmed_9 == 9) 
gen atencion_curandero = 1  	if (servmed_10 == 10)
gen atencion_otro = 1  		    if (servmed_11 == 11)


**Obtener datos por decil de ingresos
*collapse (sum) imss necesidad bus_aten atencion_reci atencion_pub [fw=factor] 

format otro necesidad bus_aten atencion_reci %12.0fc
	   
rename otro afiliacion
gen subsistema = "Otro"
order subsistema, b(afiliacion)
tempfile inst_8
save `inst_8'



use `inst_1'
forval i = 2 / 9 {
append using `inst_`i''
}
gen enigh = 2024
tempfile enigh_2024
save `enigh_2024'
}

** ¡¡Cambiar el año en el archivo que se va a guardar!! **
*Guardar datos 
saveold "${directorio}/ENIGH/Outcomes/sankey_salud2024.dta", replace 


use "${directorio}/ENIGH/Outcomes/sankey_salud2024.dta", clear. /// AJUSTAR

** Reemplazar los missing values en las variables que usaremos **
replace necesidad = 0 if necesidad == .
replace bus_aten = 0 if bus_aten == .
replace centros_ssa = 0 if centros_ssa == .
replace hospital_ssa = 0 if hospital_ssa == .
replace atencion_imss = 0 if atencion_imss == .
replace atencion_bienestar = 0 if atencion_bienestar == .
replace atencion_issste = 0 if atencion_issste == .
replace atencion_estatal = 0 if atencion_estatal == .
replace atencion_otra_pub = 0 if atencion_otra_pub == .
replace atencion_privada = 0 if atencion_privada == .
replace atencion_farmacias = 0 if atencion_farmacias == .
replace atencion_curandero = o if atencion_curandero == .
replace atencion_otro = 0 if atencion_otro == .

** Hay que crear 1 sola variable de dónde se especifique lugar de atención**
*------------------------------------------------------------
* 1. Crear variable que indique el primer lugar de atención
*------------------------------------------------------------

gen str20 primer_lugar = ""

foreach var in centros_ssa hospital_ssa atencion_imss atencion_bienestar atencion_issste ///
                atencion_estatal atencion_otra_pub atencion_privada atencion_farmacias ///
                atencion_curandero atencion_otro {
    replace primer_lugar = "`var'" if `var' == 1 & primer_lugar == ""
}

*------------------------------------------------------------
* 2. Contar cuántos lugares distintos visitó la persona
*------------------------------------------------------------

egen contar_lugares = rowtotal(centros_ssa hospital_ssa atencion_imss atencion_bienestar ///
                               atencion_issste atencion_estatal atencion_otra_pub atencion_privada ///
                               atencion_farmacias atencion_curandero atencion_otro)

*------------------------------------------------------------
* 3. Clasificar si fue a uno, dos o más lugares
*------------------------------------------------------------

gen total_lugares = .
replace total_lugares = 1 if contar_lugares == 1
replace total_lugares = 2 if contar_lugares == 2
replace total_lugares = 3 if contar_lugares >= 3

label define tipo 1 "Solo un lugar" 2 "Dos lugares" 3 "Tres o más"
label values total_lugares tipo

*------------------------------------------------------------
* 4. Crear versión numérica de primer_lugar con etiquetas legibles
*------------------------------------------------------------

gen id_lugar = .

replace id_lugar = 1 if primer_lugar == "centros_ssa"
replace id_lugar = 2 if primer_lugar == "hospital_ssa"
replace id_lugar = 3 if primer_lugar == "atencion_imss"
replace id_lugar = 4 if primer_lugar == "atencion_bienestar"
replace id_lugar = 5 if primer_lugar == "atencion_issste"
replace id_lugar = 6 if primer_lugar == "atencion_estatal"
replace id_lugar = 7 if primer_lugar == "atencion_otra_pub"
replace id_lugar = 8 if primer_lugar == "atencion_privada"
replace id_lugar = 9 if primer_lugar == "atencion_farmacias"
replace id_lugar = 10 if primer_lugar == "atencion_curandero"
replace id_lugar = 11 if primer_lugar == "atencion_otro"

label define lugar 1 "Centros SSA" 2 "Hospital SSA" 3 "IMSS" 4 "Bienestar" 5 "ISSSTE" ///
                   6 "Estatal" 7 "Otra Pública" 8 "Privado" 9 "Farmacias" 10 "Curandero" 11 "Otro"
label values id_lugar lugar

*------------------------------------------------------------
* Tablas rápidas de verificación
*------------------------------------------------------------

tab id_lugar
tab total_lugares


saveold "${directorio}/ENIGH/Outcomes/sankey_salud2024.dta", replace // CAMBIAR NOMBRE PARA CADA AÑO
				   
***********************  EJES para SANKEY ************************

****** EJE 1 **********
*use "/Users/judysenyacen/CIEP Dropbox/Judith Mendez/EquipoCIEP/CIEP_Salud/5. BD salud/ENIGH/Outcomes/sankey_salud2024.dta", clear // CAMBIAR NOMBRE PARA CADA AÑO

use "${directorio}/ENIGH/Outcomes/sankey_salud2024.dta", clear

collapse (sum) factor, by (subsistema necesidad)
encode subsistema, generate (from)
rename necesidad to 
rename factor profile
format profile %12.0fc
label define to 1 "Necesitó" 0 "No necesitó"
label values to to
tempfile eje1
save `eje1'


****** EJE 2 **********
*use "/Users/judysenyacen/CIEP Dropbox/Judith Mendez/EquipoCIEP/CIEP_Salud/5. BD salud/ENIGH/Outcomes/sankey_salud2022.dta", clear // CAMBIAR NOMBRE PARA CADA AÑO

use "${directorio}/ENIGH/Outcomes/sankey_salud2024.dta", clear


collapse (sum) factor, by (necesidad bus_aten)
rename necesidad from
label define from 1 "Necesitó" 0 "No necesitó"
label values from from
rename bus_aten to 
rename factor profile
format profile %12.0fc
label define to 1 "Buscó atención" 0 "No buscó atención"
label values to to
tempfile eje2
save `eje2'


****** EJE 3 **********
*use "/Users/judysenyacen/CIEP Dropbox/Judith Mendez/EquipoCIEP/CIEP_Salud/5. BD salud/ENIGH/Outcomes/sankey_salud2022.dta", clear // CAMBIAR NOMBRE PARA CADA AÑO

use "${directorio}/ENIGH/Outcomes/sankey_salud2024.dta", clear

collapse (sum) factor, by (bus_aten id_lugar)
rename bus_aten from
label define from 1 "Buscó atención" 0 "No buscó atención"
label values from from
rename id_lugar to 
rename factor profile
format profile %12.0fc
label define to 1 "Centros SSA" 2 "Hospital SSA" 3 "IMSS" 4 "Bienestar" 5 "ISSSTE" ///
                   6 "Estatal" 7 "PEMEX" 8 "Privado" 9 "Farmacias" 10 "Curandero" 11 "Otro"
label values to to
tempfile eje3
save `eje3'


************
** Sankey **
noisily SankeySumSim, anio(2024) name(salud2024) a(`eje1') // b(`eje2') //c(`eje3') d(`eje4') 

